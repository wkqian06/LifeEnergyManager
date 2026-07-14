Set-StrictMode -Version Latest

function Assert-LemOracleCondition {
  param(
    [Parameter(Mandatory=$true)][bool]$Condition,
    [Parameter(Mandatory=$true)][string]$Message
  )

  if (-not $Condition) { throw $Message }
}

function Get-LemPlanRevisionExitCommand {
  return (-join @([char]0x9000, [char]0x51FA, [char]0x8BA1, [char]0x5212, [char]0x4FEE, [char]0x6B63))
}

function Get-LemClosingGoalId {
  param([Parameter(Mandatory=$true)]$Day)

  if ($Day.closingGoalId) { return [string]$Day.closingGoalId }
  if ($Day.alertGoalId) { return [string]$Day.alertGoalId }
  return 'PH-DISSERTATION'
}

function Get-LemConfirmationState {
  param([Parameter(Mandatory=$true)]$Day)

  $highImpact = [int]$Day.confirmationsRequired -eq 3
  $validReplies = @{}
  $seenReplyIds = @{}
  $factsHash = $null
  $changeSetHash = $null
  $factsResetCount = 0
  $changeSetResetCount = 0
  $userExitCommand = $null
  $terminalExited = $false
  $expectedStage = if ($highImpact) { 'facts' } else { 'single' }
  $lastEventAt = $null
  foreach ($event in @($Day.confirmationEvents)) {
    Assert-LemOracleCondition (-not $terminalExited) `
      "Day $($Day.dayIndex): confirmation events are forbidden after user exit"
    $eventAt = [datetimeoffset]::ParseExact([string]$event.at, 'yyyy-MM-ddTHH:mm:sszzz', [System.Globalization.CultureInfo]::InvariantCulture)
    Assert-LemOracleCondition ($null -eq $lastEventAt -or $eventAt -gt $lastEventAt) `
      "Day $($Day.dayIndex): confirmation event timestamps must be strictly increasing"
    $lastEventAt = $eventAt
    switch ([string]$event.type) {
      'facts_changed' {
        $validReplies = @{}
        $factsHash = [string]$event.factsHash
        $changeSetHash = [string]$event.changeSetHash
        Assert-LemOracleCondition (-not [string]::IsNullOrWhiteSpace($factsHash) -and -not [string]::IsNullOrWhiteSpace($changeSetHash)) `
          "Day $($Day.dayIndex): reset facts and change-set hashes must be non-empty"
        $factsResetCount += 1
        $expectedStage = 'facts'
      }
      'change_set_changed' {
        Assert-LemOracleCondition ($validReplies.ContainsKey('facts')) `
          "Day $($Day.dayIndex): change set changed before facts were confirmed"
        $validReplies.Remove('change_set')
        $validReplies.Remove('consequences')
        $factsHash = [string]$event.factsHash
        $changeSetHash = [string]$event.changeSetHash
        Assert-LemOracleCondition (-not [string]::IsNullOrWhiteSpace($factsHash) -and -not [string]::IsNullOrWhiteSpace($changeSetHash)) `
          "Day $($Day.dayIndex): changed facts and change-set hashes must be non-empty"
        $changeSetResetCount += 1
        $expectedStage = 'change_set'
      }
      'user_exit' {
        $userExitCommand = [string]$event.command
        Assert-LemOracleCondition ($userExitCommand -eq (Get-LemPlanRevisionExitCommand)) `
          "Day $($Day.dayIndex): user exit command must be exact"
        $validReplies = @{}
        $factsHash = $null
        $changeSetHash = $null
        $expectedStage = 'exited'
        $terminalExited = $true
      }
      'reply' {
        $replyId = [string]$event.replyId
        Assert-LemOracleCondition (-not [string]::IsNullOrWhiteSpace($replyId) -and -not $seenReplyIds.ContainsKey($replyId)) `
          "Day $($Day.dayIndex): confirmation reply IDs must be non-empty and unique"
        $seenReplyIds[$replyId] = $true
        if ($highImpact) {
          $stage = [string]$event.stage
          Assert-LemOracleCondition (@('facts', 'change_set', 'consequences') -contains $stage) `
            "Day $($Day.dayIndex): invalid high-impact confirmation stage $stage"
          Assert-LemOracleCondition ($stage -eq $expectedStage) `
            "Day $($Day.dayIndex): expected confirmation stage $expectedStage, received $stage"
          if ($stage -eq 'facts') {
            $factsHash = [string]$event.factsHash
            $changeSetHash = [string]$event.changeSetHash
            Assert-LemOracleCondition (-not [string]::IsNullOrWhiteSpace($factsHash) -and -not [string]::IsNullOrWhiteSpace($changeSetHash)) `
              "Day $($Day.dayIndex): facts and change-set hashes must be non-empty"
            $expectedStage = 'change_set'
          } else {
            Assert-LemOracleCondition ([string]$event.factsHash -eq $factsHash -and [string]$event.changeSetHash -eq $changeSetHash) `
              "Day $($Day.dayIndex): confirmation reply used stale facts or change set"
            if ($stage -eq 'change_set') { $expectedStage = 'consequences' }
            if ($stage -eq 'consequences') { $expectedStage = 'complete' }
          }
          $validReplies[$stage] = $replyId
        } else {
          $validReplies[$replyId] = $replyId
        }
      }
      default { throw "Day $($Day.dayIndex): unknown confirmation event type $($event.type)" }
    }
  }
  $actualCount = $validReplies.Count
  return [ordered]@{
    actualConfirmationCount = $actualCount
    complete = -not $terminalExited -and $actualCount -ge [int]$Day.confirmationsRequired
    factsResetCount = $factsResetCount
    changeSetResetCount = $changeSetResetCount
    validReplyIds = @($validReplies.Values | Sort-Object)
    userExitCommand = $userExitCommand
    expectedStage = $expectedStage
  }
}

function Assert-LemConfirmationNegativeCases {
  [CmdletBinding()]
  param()

  $baseEvents = @(
    [pscustomobject]@{ type='reply'; replyId='R1'; stage='facts'; factsHash='F1'; changeSetHash='C1'; at='2026-07-14T08:00:00-04:00' },
    [pscustomobject]@{ type='reply'; replyId='R2'; stage='change_set'; factsHash='F1'; changeSetHash='C1'; at='2026-07-14T08:01:00-04:00' },
    [pscustomobject]@{ type='reply'; replyId='R3'; stage='consequences'; factsHash='F1'; changeSetHash='C1'; at='2026-07-14T08:02:00-04:00' }
  )
  $cases = [ordered]@{
    out_of_order = @($baseEvents[0], $baseEvents[2], $baseEvents[1])
    duplicate_reply_id = @($baseEvents[0], [pscustomobject]@{ type='reply'; replyId='R1'; stage='change_set'; factsHash='F1'; changeSetHash='C1'; at='2026-07-14T08:01:00-04:00' })
    stale_hash = @($baseEvents[0], [pscustomobject]@{ type='reply'; replyId='R2'; stage='change_set'; factsHash='F0'; changeSetHash='C0'; at='2026-07-14T08:01:00-04:00' })
    same_timestamp = @($baseEvents[0], [pscustomobject]@{ type='reply'; replyId='R2'; stage='change_set'; factsHash='F1'; changeSetHash='C1'; at='2026-07-14T08:00:00-04:00' })
    stale_after_reset = @(
      $baseEvents[0],
      [pscustomobject]@{ type='facts_changed'; factsHash='F2'; changeSetHash='C2'; at='2026-07-14T08:01:00-04:00' },
      [pscustomobject]@{ type='reply'; replyId='R2'; stage='change_set'; factsHash='F1'; changeSetHash='C1'; at='2026-07-14T08:02:00-04:00' }
    )
    exit_then_reply = @(
      $baseEvents[0],
      [pscustomobject]@{ type='user_exit'; command=(Get-LemPlanRevisionExitCommand); at='2026-07-14T08:01:00-04:00' },
      [pscustomobject]@{ type='reply'; replyId='R2'; stage='change_set'; factsHash='F1'; changeSetHash='C1'; at='2026-07-14T08:02:00-04:00' }
    )
    empty_hashes = @(
      [pscustomobject]@{ type='reply'; replyId='R1'; stage='facts'; factsHash=''; changeSetHash=''; at='2026-07-14T08:00:00-04:00' },
      [pscustomobject]@{ type='reply'; replyId='R2'; stage='change_set'; factsHash=''; changeSetHash=''; at='2026-07-14T08:01:00-04:00' },
      [pscustomobject]@{ type='reply'; replyId='R3'; stage='consequences'; factsHash=''; changeSetHash=''; at='2026-07-14T08:02:00-04:00' }
    )
  }
  foreach ($caseName in $cases.Keys) {
    $rejected = $false
    try {
      Get-LemConfirmationState -Day ([pscustomobject]@{ dayIndex=99; confirmationsRequired=3; confirmationEvents=@($cases[$caseName]) }) | Out-Null
    } catch { $rejected = $true }
    Assert-LemOracleCondition $rejected "Negative confirmation case was accepted: $caseName"
  }
}

function Get-LemWeightedMedian {
  param(
    [Parameter(Mandatory=$true)][array]$Values,
    [Parameter(Mandatory=$true)][array]$Weights
  )

  Assert-LemOracleCondition ($Values.Count -gt 0 -and $Values.Count -eq $Weights.Count) `
    'Weighted median requires equally sized, non-empty values and weights'
  $samples = for ($index = 0; $index -lt $Values.Count; $index++) {
    [pscustomobject]@{ value=[double]$Values[$index]; weight=[double]$Weights[$index] }
  }
  $samples = @($samples | Sort-Object value)
  $threshold = (@($samples | Measure-Object weight -Sum).Sum) / 2
  $cumulativeWeight = 0.0
  foreach ($sample in $samples) {
    $cumulativeWeight += $sample.weight
    if ($cumulativeWeight -ge $threshold) { return [int]$sample.value }
  }
  throw 'Weighted median could not be calculated'
}

function Assert-LemWeightedMedianSelfTest {
  [CmdletBinding()]
  param()

  $values = @(0, 0, 0, 0, 0, 0, 0, 0, 100, 100, 100, 100, 100, 100, 100)
  $weights = @(1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2)
  $weightedMedian = Get-LemWeightedMedian -Values $values -Weights $weights
  Assert-LemOracleCondition ($weightedMedian -eq 100 -and $values[7] -eq 0) `
    'Recent-seven weighting did not change the older-sample ordinary median'
}

function Assert-LemScoreValue {
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)]$Value,
    [Parameter(Mandatory=$true)][int]$DayIndex
  )

  $number = [int]$Value
  Assert-LemOracleCondition ($number -ge 0 -and $number -le 100) `
    "Day $DayIndex`: $Name must be within 0-100"
}

function New-LemScoreHistoryRow {
  param([Parameter(Mandatory=$true)][string]$Date)

  return [pscustomobject][ordered]@{
    date = $Date
    focusMinutes = $null
    remainingSelf = $null
    remainingBlind = $null
    remainingCalibrated = $null
    predDriveSelf = $null
    predDriveBlind = $null
    predDriveCalibrated = $null
    actualDrive = $null
    planningAdjustment = $null
  }
}

function New-LemSimulatedBlindEvidence {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true)]$Day)

  $score = $Day.blindScoreSimulation
  if (-not [bool]$score.expected) {
    Assert-LemOracleCondition (-not [string]::IsNullOrWhiteSpace([string]$score.reason)) `
      "Day $($Day.dayIndex): a skipped score requires a reason"
    return [ordered]@{
      expected = $false
      reason = [string]$score.reason
      source = 'evidence-only blind fixture'
    }
  }

  foreach ($name in @('remainingBlind', 'predDriveBlind', 'actualDrive')) {
    Assert-LemScoreValue -Name $name -Value $score.$name -DayIndex ([int]$Day.dayIndex)
  }
  Assert-LemOracleCondition (@('low', 'medium', 'high') -contains [string]$score.agentEnergyConfidence) `
    "Day $($Day.dayIndex): invalid agent energy confidence"

  return [ordered]@{
    expected = $true
    generatedBeforeSelfFixtureLoad = $true
    selfScoresVisible = $false
    remainingBlind = [int]$score.remainingBlind
    predDriveBlind = [int]$score.predDriveBlind
    actualDrive = [int]$score.actualDrive
    agentEnergyConfidence = [string]$score.agentEnergyConfidence
    agentEnergySummary = [string]$score.agentEnergySummary
    evidence = [string]$score.evidence
    inference = [string]$score.inference
  }
}

function Get-LemCalibratedScore {
  param(
    [Parameter(Mandatory=$true)][int]$Blind,
    [Parameter(Mandatory=$true)][int]$Self
  )

  $selfWeight = if ([Math]::Abs($Blind - $Self) -ge 30) { 0.75 } else { 0.5 }
  return [int][Math]::Round(($Self * $selfWeight) + ($Blind * (1 - $selfWeight)), 0, [MidpointRounding]::AwayFromZero)
}

function Get-LemPlanningAdjustment {
  param(
    [Parameter(Mandatory=$true)][int]$RemainingCalibrated,
    [Parameter(Mandatory=$true)][int]$ActualDrive
  )

  if ($RemainingCalibrated -lt 35 -or $ActualDrive -lt 50) {
    return [ordered]@{ focusMode='Recovery'; targetCapMinutes=90; text='Use recovery intensity and preserve only the protected action.' }
  }
  if ($RemainingCalibrated -lt 50 -or $ActualDrive -lt 60) {
    return [ordered]@{ focusMode='Reduced'; targetCapMinutes=120; text='Use a reduced baseline and do not add compensation work.' }
  }
  return [ordered]@{ focusMode='Standard'; targetCapMinutes=$null; text='Keep a standard baseline; protect the first critical action.' }
}

function Complete-LemSimulatedScoringEvidence {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]$Day,
    [Parameter(Mandatory=$true)]$BlindEvidence,
    [Parameter(Mandatory=$true)][string]$BlindResultHash,
    [Parameter(Mandatory=$true)]$SelfScore,
    [Parameter(Mandatory=$true)][AllowEmptyCollection()][array]$PriorScoreHistory
  )

  Assert-LemOracleCondition ([bool]$SelfScore.expected -eq [bool]$BlindEvidence.expected) `
    "Day $($Day.dayIndex): blind and self scoring expectations differ"
  if (-not [bool]$BlindEvidence.expected) {
    return [ordered]@{
      expected = $false
      reason = [string]$BlindEvidence.reason
      blindResultHashBeforeSelf = $BlindResultHash
      blindResultHashAfterCalibration = $BlindResultHash
      stages = @()
    }
  }
  foreach ($name in @('remainingSelf', 'predDriveSelf')) {
    Assert-LemScoreValue -Name $name -Value $SelfScore.$name -DayIndex ([int]$Day.dayIndex)
    Assert-LemOracleCondition (([int]$SelfScore.$name % 5) -eq 0) `
      "Day $($Day.dayIndex): simulated user $name must follow the workbench 5-point step"
  }

  $remainingCalibrated = Get-LemCalibratedScore -Blind ([int]$BlindEvidence.remainingBlind) -Self ([int]$SelfScore.remainingSelf)
  $predDriveCalibrated = Get-LemCalibratedScore -Blind ([int]$BlindEvidence.predDriveBlind) -Self ([int]$SelfScore.predDriveSelf)
  $adjustment = Get-LemPlanningAdjustment -RemainingCalibrated $remainingCalibrated -ActualDrive ([int]$BlindEvidence.actualDrive)

  $priorTarget = @($PriorScoreHistory | Where-Object { [string]$_.date -eq [string]$Day.date } | Select-Object -First 1)
  $priorPrediction = if ($priorTarget.Count -eq 1 -and $null -ne $priorTarget[0].predDriveCalibrated) {
    [int]$priorTarget[0].predDriveCalibrated
  } else { $null }
  $actualVsPriorGap = if ($null -ne $priorPrediction) { [int]$BlindEvidence.actualDrive - $priorPrediction } else { $null }
  $blindSelfGap = [Math]::Abs([int]$BlindEvidence.predDriveBlind - [int]$SelfScore.predDriveSelf)
  $targetDate = ([datetime]::ParseExact([string]$Day.date, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)).AddDays(1).ToString('yyyy-MM-dd')

  return [ordered]@{
    expected = $true
    model = 'blind-self-calibrated'
    stages = @(
      [ordered]@{ order=1; name='blind_pass_persisted'; selfScoresVisible=$false; blindResultHash=$BlindResultHash },
      [ordered]@{ order=2; name='self_fixture_loaded'; selfScoresVisible=$true; blindResultHash=$BlindResultHash },
      [ordered]@{ order=3; name='calibration'; selfScoresVisible=$true; blindResultHash=$BlindResultHash }
    )
    blindResultHashBeforeSelf = $BlindResultHash
    blindResultHashAfterCalibration = $BlindResultHash
    blindPass = $BlindEvidence
    selfScores = [ordered]@{
      remainingSelf = [int]$SelfScore.remainingSelf
      remainingNote = [string]$SelfScore.remainingNote
      predDriveSelf = [int]$SelfScore.predDriveSelf
      predDriveNote = [string]$SelfScore.predDriveNote
      simulatedBy = 'test agent acting as user'
    }
    calibrated = [ordered]@{
      remainingCalibrated = $remainingCalibrated
      predDriveCalibrated = $predDriveCalibrated
      actualDrive = [int]$BlindEvidence.actualDrive
      agentEnergyConfidence = [string]$BlindEvidence.agentEnergyConfidence
      agentEnergySummary = [string]$BlindEvidence.agentEnergySummary
      planningAdjustment = [string]$adjustment.text
      nextFocusMode = [string]$adjustment.focusMode
      nextTargetCapMinutes = $adjustment.targetCapMinutes
    }
    predictionTargetDate = $targetDate
    priorPredDriveCalibrated = $priorPrediction
    actualVsPriorPredictionGap = $actualVsPriorGap
    blindVsSelfPredictionGap = $blindSelfGap
    divergenceFlag = $blindSelfGap -ge 30
  }
}

function Get-LemScorePlanningDecision {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]$Day,
    [Parameter(Mandatory=$true)]$PriorState
  )

  $baseTarget = if ([string]$Day.runMode -eq 'manual_catchup') { 120 } else { [int]$Day.plannedCriticalMinutes }
  $currentPredictionRows = @($PriorState.scoreHistory | Where-Object {
    [string]$_.date -eq [string]$Day.date -and $null -ne $_.predDriveCalibrated
  } | Select-Object -First 1)
  $observations = @($PriorState.scoreHistory | Where-Object {
    [string]$_.date -lt [string]$Day.date -and $null -ne $_.remainingCalibrated -and $null -ne $_.actualDrive
  } | Sort-Object date | Select-Object -Last 1)
  if ($observations.Count -eq 0) {
    return [ordered]@{
      applied = $false
      focusMode = 'Standard'
      targetMinutes = $baseTarget
      observationDate = $null
      remainingCalibrated = $null
      actualDrive = $null
      predictionTargetDate = $(if ($currentPredictionRows.Count) { [string]$currentPredictionRows[0].date } else { $null })
      predDriveCalibrated = $(if ($currentPredictionRows.Count) { [int]$currentPredictionRows[0].predDriveCalibrated } else { $null })
    }
  }
  $latest = $observations[0]
  $adjustment = Get-LemPlanningAdjustment -RemainingCalibrated ([int]$latest.remainingCalibrated) -ActualDrive ([int]$latest.actualDrive)
  $target = if ($null -eq $adjustment.targetCapMinutes) { $baseTarget } else { [Math]::Min($baseTarget, [int]$adjustment.targetCapMinutes) }
  return [ordered]@{
    applied = $true
    focusMode = [string]$adjustment.focusMode
    targetMinutes = [int]$target
    observationDate = [string]$latest.date
    remainingCalibrated = [int]$latest.remainingCalibrated
    actualDrive = [int]$latest.actualDrive
    planningAdjustment = [string]$adjustment.text
    predictionTargetDate = $(if ($currentPredictionRows.Count) { [string]$currentPredictionRows[0].date } else { $null })
    predDriveCalibrated = $(if ($currentPredictionRows.Count) { [int]$currentPredictionRows[0].predDriveCalibrated } else { $null })
  }
}

function New-LemInitialSimulationState {
  [CmdletBinding()]
  param()

  $registry = @(
    [ordered]@{ goalId='PH-DISSERTATION'; level='phase'; status='active'; originalDeadline='2026-07-22'; currentDeadline='2026-07-22'; deadlineType='hard'; exitCriterion='Reviewable dissertation phase output'; successorGoalId=$null },
    [ordered]@{ goalId='MO-2026-07'; level='month'; status='active'; originalDeadline='2026-07-24'; currentDeadline='2026-07-24'; deadlineType='soft'; exitCriterion='July chapter gate is reviewable'; successorGoalId=$null },
    [ordered]@{ goalId='WK-2026-07-13'; level='week'; status='active'; originalDeadline='2026-07-18'; currentDeadline='2026-07-18'; deadlineType='soft'; exitCriterion='Weekly reviewable output is closed'; successorGoalId=$null },
    [ordered]@{ goalId='MS-LEGACY-EXIT'; level='micro-sprint'; status='active'; originalDeadline='2026-07-22'; currentDeadline='2026-07-22'; deadlineType='soft'; exitCriterion='Legacy micro-sprint has terminal evidence'; successorGoalId=$null },
    [ordered]@{ goalId='MS-ANALYSIS'; level='micro-sprint'; status='active'; originalDeadline='2026-07-24'; currentDeadline='2026-07-24'; deadlineType='soft'; exitCriterion='Three analysis outputs reviewed'; successorGoalId=$null },
    [ordered]@{ goalId='CM-LEGACY'; level='commitment'; status='active'; originalDeadline='2026-07-27'; currentDeadline='2026-07-27'; deadlineType='soft'; exitCriterion='Commitment is completed or explicitly dropped'; successorGoalId=$null }
  )
  return [ordered]@{
    date = $null
    snapshot = 'initial'
    authoritativeRevision = 'PR-20260714-0'
    planSurfaces = [ordered]@{}
    registry = $registry
    activeGoalIds = @($registry | ForEach-Object { $_.goalId })
    closureLog = @()
    history = @()
    scoreHistory = @()
    revisionHistory = @()
    goalDebtMinutes = 0
    correction = [ordered]@{}
    guard = [ordered]@{}
    capacity = [ordered]@{}
    commitments = [ordered]@{}
    artifacts = [ordered]@{}
    transaction = [ordered]@{}
  }
}

function Get-LemDerivedGuardDecision {
  param(
    [Parameter(Mandatory=$true)]$Day,
    [Parameter(Mandatory=$true)]$PriorState,
    [Parameter(Mandatory=$true)]$Transaction
  )

  $projectedDebt = [int]$PriorState.goalDebtMinutes + [int]$Day.debtDeltaMinutes - [int]$Day.debtCompletedMinutes
  $revisionCount = @($PriorState.revisionHistory).Count
  $closingGoalId = Get-LemClosingGoalId -Day $Day
  $closingGoal = @($PriorState.registry | Where-Object { [string]$_.goalId -eq $closingGoalId -and [string]$_.status -eq 'active' } | Select-Object -First 1)
  $closureRequired = $false
  if ($Day.closingGoalId -and -not $Day.terminalOutcome -and $closingGoal.Count -eq 1) {
    $closureRequired = [datetime]::ParseExact([string]$closingGoal[0].currentDeadline, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture) -le `
      [datetime]::ParseExact([string]$Day.date, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
  }

  $hardProposalBlocked = $false
  $proposalDeadlineTypeMismatch = $false
  $hasPlanChangeProposal = $Day.PSObject.Properties.Name -contains 'planChangeProposal' -and $null -ne $Day.planChangeProposal
  if ($hasPlanChangeProposal) {
    $proposal = $Day.planChangeProposal
    $proposalGoal = @($PriorState.registry | Where-Object { [string]$_.goalId -eq [string]$proposal.goalId -and [string]$_.status -eq 'active' } | Select-Object -First 1)
    Assert-LemOracleCondition ($proposalGoal.Count -eq 1 -and [string]$proposalGoal[0].currentDeadline -eq [string]$proposal.currentDeadline) `
      "Day $($Day.dayIndex): hard-deadline proposal did not reference the active baseline"
    $authoritativeDeadlineType = [string]$proposalGoal[0].deadlineType
    Assert-LemOracleCondition (@('hard', 'soft') -contains $authoritativeDeadlineType) `
      "Day $($Day.dayIndex): authoritative goal is missing a valid deadline type"
    if ($proposal.PSObject.Properties.Name -contains 'deadlineType') {
      $proposalDeadlineTypeMismatch = [string]$proposal.deadlineType -ne $authoritativeDeadlineType
    }
    $movesLater = [datetime]::ParseExact([string]$proposal.proposedDeadline, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture) -gt `
      [datetime]::ParseExact([string]$proposal.currentDeadline, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
    $hardProposalBlocked = $authoritativeDeadlineType -eq 'hard' -and $movesLater -and -not $proposal.evidence
  }

  $driftDetected = $projectedDebt -ge 180 -and [string]$Day.feasibility -eq 'red' -and $revisionCount -ge 3
  if ($closureRequired) {
    $proposalStatus = 'closure_required'
    $guardStatus = 'closure_required'
  } elseif ($hardProposalBlocked -or [bool]$Day.postArtifactInput) {
    $proposalStatus = 'blocked'
    $guardStatus = $(if ([bool]$Day.postArtifactInput) { 'pass' } else { 'warning' })
  } elseif ($driftDetected) {
    $proposalStatus = 'rebaseline_required'
    $guardStatus = $(if ([bool]$Transaction.committed -and [string]$Day.workflow -ne 'sunday_review') { 'warning' } else { 'rebaseline_required' })
  } elseif ([string]$Day.terminalOutcome -eq 'completed' -and [string]$Day.feasibility -eq 'green') {
    $proposalStatus = 'pass'
    $guardStatus = 'pass'
  } elseif (@('approaching', 'critical', 'due') -contains [string]$Day.proximity -or @('yellow', 'red') -contains [string]$Day.feasibility) {
    $proposalStatus = 'warning'
    $guardStatus = 'warning'
  } else {
    $proposalStatus = 'pass'
    $guardStatus = 'pass'
  }
  return [ordered]@{
    status = $guardStatus
    proposalStatus = $proposalStatus
    hardDeadlineViolation = $hardProposalBlocked
    proposalDeadlineTypeMismatch = $proposalDeadlineTypeMismatch
    renegotiationRequired = $hardProposalBlocked
    driftDetected = $driftDetected
    projectedGoalDebtMinutes = $projectedDebt
    priorRevisionCount = $revisionCount
  }
}

function Assert-LemHardDeadlineAuthorityNegativeCase {
  [CmdletBinding()]
  param()

  $priorState = New-LemInitialSimulationState
  $spoofedSoftProposal = [pscustomobject]@{
    dayIndex = 98
    date = '2026-07-14'
    dayLabel = 'normal'
    workflow = 'morning_evening'
    closingGoalId = $null
    alertGoalId = 'PH-DISSERTATION'
    terminalOutcome = $null
    debtDeltaMinutes = 0
    debtCompletedMinutes = 0
    feasibility = 'green'
    proximity = 'normal'
    postArtifactInput = $false
    planChangeProposal = [pscustomobject]@{
      goalId = 'PH-DISSERTATION'
      currentDeadline = '2026-07-22'
      proposedDeadline = '2026-07-30'
      deadlineType = 'soft'
      evidence = $null
    }
  }
  $decision = Get-LemDerivedGuardDecision -Day $spoofedSoftProposal -PriorState $priorState -Transaction ([pscustomobject]@{ committed=$false })
  Assert-LemOracleCondition ($decision.hardDeadlineViolation -and $decision.proposalStatus -eq 'blocked' -and $decision.proposalDeadlineTypeMismatch) `
    'A proposal-spoofed soft type bypassed the authoritative hard-deadline guard'
}

function Copy-LemState {
  param([Parameter(Mandatory=$true)]$State)

  return ($State | ConvertTo-Json -Depth 20 | ConvertFrom-Json)
}

function Get-LemCapacityState {
  param(
    [Parameter(Mandatory=$true)]$Day,
    [Parameter(Mandatory=$true)][AllowEmptyCollection()][array]$History
  )

  $comparable = @($History | Where-Object {
    [bool]$_.includedInNormalHistory
  } | Sort-Object @{ Expression = { [datetime]::ParseExact([string]$_.date, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture) } })
  if ($comparable.Count -gt 28) { $comparable = @($comparable | Select-Object -Last 28) }
  $sampleMinutes = @($comparable | ForEach-Object { [int]$_.actualCriticalMinutes })
  $sampleWeights = for ($index = 0; $index -lt $sampleMinutes.Count; $index++) {
    if ($index -ge $sampleMinutes.Count - 7) { 2 } else { 1 }
  }
  if ($sampleMinutes.Count -ge 7) {
    $expectedMinutes = Get-LemWeightedMedian -Values $sampleMinutes -Weights @($sampleWeights)
    $confidence = 'high'
    $algorithm = 'weighted_median'
  } else {
    $expectedMinutes = 180
    $confidence = 'low'
    $algorithm = 'minimum_focused_time_fallback'
  }
  $specialDay = @('manual_catchup', 'recovery', 'travel', 'illness', 'sunday_review', 'closure_blocked') -contains [string]$Day.dayLabel
  return [ordered]@{
    comparableDays = $sampleMinutes.Count
    confidence = $confidence
    algorithm = $algorithm
    expectedMinutes = $expectedMinutes
    safeMinutes = [Math]::Round($expectedMinutes * 0.8)
    includedInNormalHistory = -not $specialDay
    sampleMinutes = $sampleMinutes
    sampleWeights = @($sampleWeights)
  }
}

function New-LemSimulationStateTransition {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]$Day,
    [Parameter(Mandatory=$true)]$PriorState,
    [Parameter(Mandatory=$true)]$Transaction,
    [Parameter(Mandatory=$true)]$ArtifactEvidence,
    [Parameter(Mandatory=$true)]$ConfirmationState,
    [Parameter(Mandatory=$true)]$ScoringEvidence
  )

  $confirmation = $ConfirmationState
  $capacity = Get-LemCapacityState -Day $Day -History @($PriorState.history)
  $guardDecision = Get-LemDerivedGuardDecision -Day $Day -PriorState $PriorState -Transaction $Transaction
  Assert-LemOracleCondition ([string]$guardDecision.status -eq [string]$Day.guardStatus -and [string]$guardDecision.proposalStatus -eq [string]$Day.proposalGuardStatus) `
    "Day $($Day.dayIndex): derived Guard decision differs from fixture"
  Assert-LemOracleCondition ($capacity.comparableDays -eq [int]$Day.comparableDaysBefore) `
    "Day $($Day.dayIndex): derived comparable-day count differs from fixture"
  Assert-LemOracleCondition ($capacity.expectedMinutes -eq [int]$Day.expectedCapacityMinutes -and $capacity.safeMinutes -eq [int]$Day.safeCapacityMinutes) `
    "Day $($Day.dayIndex): derived capacity differs from fixture"

  $before = Copy-LemState -State $PriorState
  $before.date = [string]$Day.date
  $before.snapshot = 'before'
  $before.planSurfaces = $Transaction.beforeRevisions
  $before.correction = [ordered]@{ entered=$false; explicitlyExited=$false; userExited=$false; factsResetCount=0; changeSetResetCount=0; actualConfirmationCount=0; rolledBack=$false; proposalDiscarded=$false; userExitCommand=$null }
  $before.guard = [ordered]@{ status=$guardDecision.status; proposalStatus=$guardDecision.proposalStatus; hardDeadlineViolation=$guardDecision.hardDeadlineViolation; proposalDeadlineTypeMismatch=$guardDecision.proposalDeadlineTypeMismatch; renegotiationRequired=$guardDecision.renegotiationRequired; deadlineMoved=$false; driftDetected=$guardDecision.driftDetected; projectedGoalDebtMinutes=$guardDecision.projectedGoalDebtMinutes; priorRevisionCount=$guardDecision.priorRevisionCount }
  $before.capacity = $capacity
  $before.commitments = [ordered]@{ plannedMinutes=$(switch ([int]$Day.dayIndex) { 3 { 60 } 4 { 120 } default { 40 } }); capMinutes=90 }
  $before.commitments.withinCap = $before.commitments.plannedMinutes -le $before.commitments.capMinutes
  $before.artifacts = [ordered]@{ expected=[bool]$Day.artifactExpected; generationCount=0; regenerationCount=0; locked=$false; postArtifactInput=$false; unplannedMinutes=0 }
  $before.transaction = $Transaction

  $after = Copy-LemState -State $before
  $after.snapshot = 'after'
  $after.authoritativeRevision = [string]$Transaction.authoritativeRevisionAfter
  $after.planSurfaces = $Transaction.afterRevisions
  $after.correction = [ordered]@{
    entered = [string]$Day.correctionState -match '^(entered_|write_failed_)'
    explicitlyExited = [string]$Day.correctionState -eq 'entered_exited'
    userExited = [string]$Day.correctionState -eq 'entered_user_exit'
    factsResetCount = [int]$confirmation.factsResetCount
    changeSetResetCount = [int]$confirmation.changeSetResetCount
    actualConfirmationCount = [int]$confirmation.actualConfirmationCount
    rolledBack = [bool]$Transaction.rolledBack
    proposalDiscarded = [string]$Day.correctionState -eq 'entered_user_exit' -and [int]$Transaction.writeAttemptCount -eq 0
    userExitCommand = $confirmation.userExitCommand
  }
  $after.artifacts = $ArtifactEvidence
  $after.goalDebtMinutes = [int]$PriorState.goalDebtMinutes + [int]$Day.debtDeltaMinutes - [int]$Day.debtCompletedMinutes
  Assert-LemOracleCondition ($after.goalDebtMinutes -eq [int]$Day.goalDebtMinutes) `
    "Day $($Day.dayIndex): goal debt was not derived from prior debt and displacement"

  if ([bool]$Transaction.committed -and $Day.alertGoalId) {
    $targetGoal = @($after.registry | Where-Object { [string]$_.goalId -eq [string]$Day.alertGoalId } | Select-Object -First 1)
    if ($targetGoal.Count -eq 1 -and $Day.alertDeadline) { $targetGoal[0].currentDeadline = [string]$Day.alertDeadline }
  }
  $closingGoalId = Get-LemClosingGoalId -Day $Day
  if ($Day.terminalOutcome) {
    $closingGoal = @($after.registry | Where-Object { [string]$_.goalId -eq $closingGoalId } | Select-Object -First 1)
    Assert-LemOracleCondition ($closingGoal.Count -eq 1 -and [string]$closingGoal[0].status -eq 'active') `
      "Day $($Day.dayIndex): closing goal was not active in the prior registry"
    $deadlineBeforeClosure = [string]$closingGoal[0].currentDeadline
    $closingGoal[0].status = [string]$Day.terminalOutcome
    $closingGoal[0].successorGoalId = $Day.successorGoalId
    $after.closureLog = @($after.closureLog) + [ordered]@{
      goalId = $closingGoalId
      endedAt = "$($Day.date)T20:00:00-04:00"
      terminalOutcome = [string]$Day.terminalOutcome
      evidence = $Day.closureEvidence
      reason = $Day.closureReason
      remainingDisposition = $Day.remainingDisposition
      successorGoalId = $Day.successorGoalId
      originalDeadline = [string]$closingGoal[0].originalDeadline
      currentDeadline = $deadlineBeforeClosure
    }
    if ($Day.successorGoalId) {
      Assert-LemOracleCondition (@($after.registry | Where-Object { [string]$_.goalId -eq [string]$Day.successorGoalId }).Count -eq 0) `
        "Day $($Day.dayIndex): successor Goal ID already exists"
      $after.registry = @($after.registry) + [ordered]@{
        goalId = [string]$Day.successorGoalId
        level = $(if ($Day.alertGoalLevel) { [string]$Day.alertGoalLevel } else { [string]$closingGoal[0].level })
        status = 'active'
        originalDeadline = [string]$Day.alertDeadline
        currentDeadline = [string]$Day.alertDeadline
        deadlineType = [string]$closingGoal[0].deadlineType
        exitCriterion = "Complete the remaining work transferred from $closingGoalId"
        successorGoalId = $null
      }
    }
  }
  $after.activeGoalIds = @($after.registry | Where-Object status -eq 'active' | ForEach-Object { [string]$_.goalId })
  $after.history = @($PriorState.history) + [ordered]@{
    date = [string]$Day.date
    label = [string]$Day.dayLabel
    actualCriticalMinutes = [int]$Day.actualCriticalMinutes
    includedInNormalHistory = [bool]$capacity.includedInNormalHistory
  }
  $after.scoreHistory = @($PriorState.scoreHistory | ForEach-Object { Copy-LemState -State $_ })
  if ([bool]$ScoringEvidence.expected) {
    $todayRows = @($after.scoreHistory | Where-Object { [string]$_.date -eq [string]$Day.date })
    if ($todayRows.Count -eq 0) {
      $after.scoreHistory += New-LemScoreHistoryRow -Date ([string]$Day.date)
      $todayRows = @($after.scoreHistory | Where-Object { [string]$_.date -eq [string]$Day.date })
    }
    $today = $todayRows[0]
    $today.focusMinutes = [int]$Day.actualCriticalMinutes
    $today.remainingSelf = [int]$ScoringEvidence.selfScores.remainingSelf
    $today.remainingBlind = [int]$ScoringEvidence.blindPass.remainingBlind
    $today.remainingCalibrated = [int]$ScoringEvidence.calibrated.remainingCalibrated
    $today.actualDrive = [int]$ScoringEvidence.blindPass.actualDrive
    $today.planningAdjustment = [string]$ScoringEvidence.calibrated.planningAdjustment

    $targetRows = @($after.scoreHistory | Where-Object { [string]$_.date -eq [string]$ScoringEvidence.predictionTargetDate })
    if ($targetRows.Count -eq 0) {
      $after.scoreHistory += New-LemScoreHistoryRow -Date ([string]$ScoringEvidence.predictionTargetDate)
      $targetRows = @($after.scoreHistory | Where-Object { [string]$_.date -eq [string]$ScoringEvidence.predictionTargetDate })
    }
    $target = $targetRows[0]
    $target.predDriveSelf = [int]$ScoringEvidence.selfScores.predDriveSelf
    $target.predDriveBlind = [int]$ScoringEvidence.blindPass.predDriveBlind
    $target.predDriveCalibrated = [int]$ScoringEvidence.calibrated.predDriveCalibrated
    $after.scoreHistory = @($after.scoreHistory | Sort-Object date)
  }
  $after.revisionHistory = @($PriorState.revisionHistory)
  if ([bool]$Transaction.committed -and [string]$Day.revisionBefore -ne [string]$Day.revisionAfter) {
    $after.revisionHistory += [ordered]@{ revisionId=[string]$Day.revisionAfter; date=[string]$Day.date; kind=[string]$Day.revisionKind; affectedLevels=@($Day.affectedLevels) }
  }
  $after.guard.deadlineMoved = if ($Day.terminalOutcome) {
    $closed = @($after.closureLog | Where-Object { [string]$_.goalId -eq $closingGoalId } | Select-Object -Last 1)
    $closed.Count -eq 1 -and [string]$closed[0].originalDeadline -ne [string]$closed[0].currentDeadline
  } else { $false }
  return [ordered]@{ before=$before; after=$after; confirmation=$confirmation }
}

function New-LemOracleCheck {
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][bool]$Condition,
    [Parameter(Mandatory=$true)][string]$Evidence
  )

  Assert-LemOracleCondition $Condition "Oracle failed: $Name ($Evidence)"
  return [ordered]@{ name=$Name; status='pass'; evidence=$Evidence }
}

function Test-LemAllSurfacesMatch {
  param([Parameter(Mandatory=$true)]$State)

  return @($State.planSurfaces.Values | Where-Object { [string]$_ -ne [string]$State.authoritativeRevision }).Count -eq 0
}

function Test-LemClosureEntry {
  param(
    [Parameter(Mandatory=$true)]$State,
    [Parameter(Mandatory=$true)][string]$GoalId,
    [Parameter(Mandatory=$true)][string]$Outcome
  )

  return @($State.closureLog | Where-Object { [string]$_.goalId -eq $GoalId -and [string]$_.terminalOutcome -eq $Outcome }).Count -eq 1
}

function Invoke-LemScenarioOracle {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]$Day,
    [Parameter(Mandatory=$true)]$BeforeState,
    [Parameter(Mandatory=$true)]$AfterState,
    $Plan,
    $WallpaperConfig,
    [Parameter(Mandatory=$true)]$ScoringEvidence
  )

  $checks = @()
  $closingGoalId = Get-LemClosingGoalId -Day $Day
  if (@($AfterState.transaction.attemptedSurfaces).Count -gt 0) {
    Assert-LemOracleCondition ([string]@($AfterState.transaction.attemptedSurfaces)[-1] -eq 'tracker') `
      "Day $($Day.dayIndex): tracker was not the final transaction commit surface"
  }
  if ([bool]$Day.artifactExpected) {
    Assert-LemOracleCondition ($AfterState.artifacts.lockCreatedBeforeFirstArtifact -and $AfterState.artifacts.midGenerationBlocked) `
      "Day $($Day.dayIndex): correction gate remained open after HTML generation started"
  }
  switch ([int]$Day.dayIndex) {
    1 {
      $checks += New-LemOracleCheck 'no correction mode' (-not $AfterState.correction.entered) 'correction.entered=false'
      $checks += New-LemOracleCheck 'low-confidence fallback' ($AfterState.capacity.algorithm -eq 'minimum_focused_time_fallback' -and $AfterState.capacity.confidence -eq 'low' -and $AfterState.capacity.expectedMinutes -eq 180) 'fallback=180 min, low'
      $sameRevision = $Plan -and $WallpaperConfig -and $Plan.planRevisionId -eq $WallpaperConfig.planRevisionId -and $Plan.planRevisionId -eq $AfterState.authoritativeRevision -and (Test-LemAllSurfacesMatch $AfterState)
      $checks += New-LemOracleCheck 'artifacts share revision' $sameRevision "revision=$($AfterState.authoritativeRevision)"
    }
    2 {
      $checks += New-LemOracleCheck 'inline classification' ($Day.revisionKind -eq 'inline' -and -not $AfterState.correction.entered) 'inline without correction mode'
      $checks += New-LemOracleCheck 'one final-plan confirmation' ($AfterState.correction.actualConfirmationCount -eq 1) 'actual confirmations=1'
      $checks += New-LemOracleCheck 'no correction-mode banner' (-not $AfterState.correction.entered) 'correction.entered=false'
    }
    3 {
      $checks += New-LemOracleCheck 'manual catch-up compression' ($Plan.focusMode -eq 'Manual catch-up' -and $Plan.focusTargetMinutes -eq 120) 'focus target compressed to 120 min'
      $checks += New-LemOracleCheck 'commitment stays within cap' ($AfterState.commitments.withinCap -and $AfterState.commitments.plannedMinutes -le $AfterState.commitments.capMinutes) '60/90 commitment minutes'
      $checks += New-LemOracleCheck 'catch-up day excluded from normal history' (-not $AfterState.capacity.includedInNormalHistory) 'manual_catchup excluded'
    }
    4 {
      $checks += New-LemOracleCheck 'correction mode entered' $AfterState.correction.entered 'correction.entered=true'
      $checks += New-LemOracleCheck 'single dedicated confirmation' ($AfterState.correction.actualConfirmationCount -eq 1) 'actual confirmations=1'
      $failurePoints = @($AfterState.transaction.failureTrials | ForEach-Object { [int]$_.failurePoint })
      $allTrialsRestored = @($AfterState.transaction.failureTrials | Where-Object { -not [bool]$_.hashesRestored }).Count -eq 0
      $checks += New-LemOracleCheck 'rollback keeps prior revision' ($AfterState.correction.rolledBack -and $AfterState.transaction.hashesUnchanged -and $failurePoints -contains 2 -and $failurePoints -contains 4 -and $allTrialsRestored -and $AfterState.authoritativeRevision -eq $BeforeState.authoritativeRevision) 'failure before tracker and at tracker both restored every surface hash'
      $checks += New-LemOracleCheck 'artifacts blocked' ($AfterState.artifacts.generationCount -eq 0 -and -not $AfterState.artifacts.expected) 'generation count=0'
    }
    5 {
      $checks += New-LemOracleCheck 'three independent replies' ($AfterState.correction.actualConfirmationCount -eq 3 -and $AfterState.correction.changeSetResetCount -eq 1) 'three valid replies after change-set reset'
      $checks += New-LemOracleCheck 'month file shares revision' ($AfterState.planSurfaces.month -eq $AfterState.authoritativeRevision -and (Test-LemAllSurfacesMatch $AfterState)) "month=$($AfterState.authoritativeRevision)"
      $checks += New-LemOracleCheck 'goal debt preserved' ($AfterState.goalDebtMinutes -ge $BeforeState.goalDebtMinutes -and $AfterState.goalDebtMinutes -gt 0) "$($BeforeState.goalDebtMinutes) -> $($AfterState.goalDebtMinutes) min"
      $checks += New-LemOracleCheck 'correction mode explicitly exited' $AfterState.correction.explicitlyExited 'explicitlyExited=true'
    }
    6 {
      $checks += New-LemOracleCheck 'cumulative drift detected' ($AfterState.guard.driftDetected -and $AfterState.guard.projectedGoalDebtMinutes -ge 180 -and $AfterState.guard.priorRevisionCount -ge 3 -and $Day.revisionKind -eq 'rebaseline') "derived from debt=$($AfterState.guard.projectedGoalDebtMinutes), revisions=$($AfterState.guard.priorRevisionCount), feasibility=$($Day.feasibility)"
      $checks += New-LemOracleCheck 'goal debt not cleared' ($AfterState.goalDebtMinutes -gt 0) "$($AfterState.goalDebtMinutes) min"
      $checks += New-LemOracleCheck 'travel/Sunday excluded from normal capacity' (-not $AfterState.capacity.includedInNormalHistory) 'travel/Sunday excluded'
      $checks += New-LemOracleCheck 'no Sunday artifacts' ($AfterState.artifacts.generationCount -eq 0) 'generation count=0'
    }
    7 {
      $checks += New-LemOracleCheck 'facts reset handled' ($AfterState.correction.factsResetCount -eq 1 -and $AfterState.correction.actualConfirmationCount -eq 3) 'facts reset cleared stale reply and three new replies completed'
      $checks += New-LemOracleCheck 'old phase closed superseded' (Test-LemClosureEntry $AfterState $closingGoalId 'superseded') "$closingGoalId closure logged"
      $successor = @($AfterState.registry | Where-Object { [string]$_.goalId -eq [string]$Day.successorGoalId } | Select-Object -First 1)
      $successorValid = $successor.Count -eq 1 -and @($AfterState.activeGoalIds) -contains [string]$Day.successorGoalId -and -not [string]::IsNullOrWhiteSpace([string]$successor[0].exitCriterion) -and [string]$successor[0].currentDeadline -eq [string]$Day.alertDeadline
      $checks += New-LemOracleCheck 'successor Goal ID created' $successorValid "successor=$($Day.successorGoalId), dated with exit criterion"
      $checks += New-LemOracleCheck 'three replies separate' ($AfterState.correction.actualConfirmationCount -eq 3) 'three unique structured reply IDs survived reset'
      $checks += New-LemOracleCheck 'new revision ordinal is one' ([string]$AfterState.authoritativeRevision -match '-1$') "revision=$($AfterState.authoritativeRevision)"
    }
    8 {
      $expectedExitCommand = -join @([char]0x9000, [char]0x51FA, [char]0x8BA1, [char]0x5212, [char]0x4FEE, [char]0x6B63)
      $beforeHardGoal = @($BeforeState.registry | Where-Object { [string]$_.goalId -eq [string]$Day.alertGoalId } | Select-Object -First 1)
      $afterHardGoal = @($AfterState.registry | Where-Object { [string]$_.goalId -eq [string]$Day.alertGoalId } | Select-Object -First 1)
      $hardDeadlineUnchanged = $beforeHardGoal.Count -eq 1 -and $afterHardGoal.Count -eq 1 -and [string]$beforeHardGoal[0].currentDeadline -eq [string]$afterHardGoal[0].currentDeadline
      $proposalMovesLater = [datetime]::ParseExact([string]$Day.planChangeProposal.proposedDeadline, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture) -gt [datetime]::ParseExact([string]$Day.planChangeProposal.currentDeadline, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
      $checks += New-LemOracleCheck 'hard deadline move rejected' ($proposalMovesLater -and [string]$afterHardGoal[0].deadlineType -eq 'hard' -and $AfterState.guard.hardDeadlineViolation -and $AfterState.guard.proposalStatus -eq 'blocked' -and $hardDeadlineUnchanged -and $AfterState.transaction.hashesUnchanged) "authoritative hard deadline; proposed $($Day.planChangeProposal.proposedDeadline) blocked; deadline and all surface hashes remained $($afterHardGoal[0].currentDeadline)"
      $checks += New-LemOracleCheck 'renegotiation required' $AfterState.guard.renegotiationRequired 'renegotiationRequired=true'
      $exitWasExact = [string]$AfterState.correction.userExitCommand -ceq $expectedExitCommand
      $checks += New-LemOracleCheck 'user exit writes zero changes' ($exitWasExact -and $AfterState.correction.proposalDiscarded -and $AfterState.transaction.writeAttemptCount -eq 0 -and $AfterState.authoritativeRevision -eq $BeforeState.authoritativeRevision) 'exact UTF-8 exit command; zero writes'
      $checks += New-LemOracleCheck 'illness day excluded from normal capacity' (-not $AfterState.capacity.includedInNormalHistory) 'illness excluded'
    }
    9 {
      $checks += New-LemOracleCheck 'normal planning blocked' ($AfterState.guard.status -eq 'closure_required' -and -not $AfterState.artifacts.expected) 'closure_required'
      $checks += New-LemOracleCheck 'no artifacts' ($AfterState.artifacts.generationCount -eq 0) 'generation count=0'
      $beforeDueGoal = @($BeforeState.registry | Where-Object { [string]$_.goalId -eq $closingGoalId } | Select-Object -First 1)
      $afterDueGoal = @($AfterState.registry | Where-Object { [string]$_.goalId -eq $closingGoalId } | Select-Object -First 1)
      $dueDeadlineUnchanged = $beforeDueGoal.Count -eq 1 -and $afterDueGoal.Count -eq 1 -and [string]$beforeDueGoal[0].currentDeadline -eq [string]$afterDueGoal[0].currentDeadline
      $checks += New-LemOracleCheck 'old deadline not moved' $dueDeadlineUnchanged "deadline remained $($afterDueGoal[0].currentDeadline)"
      $checks += New-LemOracleCheck 'no silent default terminal outcome' (-not $Day.terminalOutcome -and @($AfterState.closureLog | Where-Object { [string]$_.goalId -eq $closingGoalId }).Count -eq 0) 'no closure entry created'
    }
    10 {
      $entry = @($AfterState.closureLog | Where-Object { [string]$_.goalId -eq $closingGoalId })[-1]
      $checks += New-LemOracleCheck 'completed requires evidence' ($entry -and -not [string]::IsNullOrWhiteSpace([string]$entry.evidence)) 'evidence stored'
      $checks += New-LemOracleCheck 'closure log retained' (Test-LemClosureEntry $AfterState $closingGoalId 'completed') "$closingGoalId closure retained"
      $checks += New-LemOracleCheck 'closed goal removed from active table' (-not (@($AfterState.activeGoalIds) -contains $closingGoalId)) "$closingGoalId inactive"
      $checks += New-LemOracleCheck 'mainline resumes' ($AfterState.guard.status -eq 'pass' -and $AfterState.artifacts.generationCount -eq 1) 'guard pass and artifacts generated'
    }
    11 {
      $entry = @($AfterState.closureLog | Where-Object { [string]$_.goalId -eq $closingGoalId })[-1]
      $checks += New-LemOracleCheck 'partial outcome records evidence' ($entry -and -not [string]::IsNullOrWhiteSpace([string]$entry.evidence)) 'partial evidence stored'
      $checks += New-LemOracleCheck 'remaining work disposition present' (-not [string]::IsNullOrWhiteSpace([string]$entry.remainingDisposition)) 'remaining disposition stored'
      $partialSuccessor = @($AfterState.registry | Where-Object { [string]$_.goalId -eq [string]$entry.successorGoalId } | Select-Object -First 1)
      $partialSuccessorValid = $partialSuccessor.Count -eq 1 -and @($AfterState.activeGoalIds) -contains [string]$entry.successorGoalId -and -not [string]::IsNullOrWhiteSpace([string]$partialSuccessor[0].exitCriterion) -and [string]$partialSuccessor[0].currentDeadline -eq [string]$Day.alertDeadline
      $checks += New-LemOracleCheck 'successor Goal ID present' $partialSuccessorValid "successor=$($entry.successorGoalId), dated with exit criterion"
      $checks += New-LemOracleCheck 'old goal date unchanged' ([string]$entry.originalDeadline -eq [string]$entry.currentDeadline) "old deadline remained $($entry.currentDeadline)"
    }
    12 {
      $entry = @($AfterState.closureLog | Where-Object { [string]$_.goalId -eq $closingGoalId })[-1]
      $checks += New-LemOracleCheck 'missed reason recorded' (-not [string]::IsNullOrWhiteSpace([string]$entry.reason)) 'missed reason stored'
      $checks += New-LemOracleCheck 'remaining work disposition recorded' (-not [string]::IsNullOrWhiteSpace([string]$entry.remainingDisposition)) 'remaining disposition stored'
      $checks += New-LemOracleCheck 'old week remains terminal' (Test-LemClosureEntry $AfterState $closingGoalId 'missed') "$closingGoalId is missed"
      $checks += New-LemOracleCheck 'low-confidence fallback still used before seventh comparable day' ($AfterState.capacity.comparableDays -eq 6 -and $AfterState.capacity.confidence -eq 'low' -and $AfterState.capacity.algorithm -eq 'minimum_focused_time_fallback') '6 comparable days'
    }
    13 {
      $checks += New-LemOracleCheck 'seven comparable days switch confidence high' ($AfterState.capacity.comparableDays -eq 7 -and $AfterState.capacity.confidence -eq 'high') '7 comparable days'
      $weightedMedian = Get-LemWeightedMedian -Values @($AfterState.capacity.sampleMinutes) -Weights @($AfterState.capacity.sampleWeights)
      $specialMinutesExcluded = -not (@($AfterState.capacity.sampleMinutes) -contains 105) -and -not (@($AfterState.capacity.sampleMinutes) -contains 75) -and -not (@($AfterState.capacity.sampleMinutes) -contains 60)
      $checks += New-LemOracleCheck 'weighted-median expected capacity used' ($AfterState.capacity.algorithm -eq 'weighted_median' -and $AfterState.capacity.expectedMinutes -eq $weightedMedian -and $specialMinutesExcluded) "28-day filtered history; special labels excluded; weighted median=$weightedMedian min"
      $supersededEntry = @($AfterState.closureLog | Where-Object { [string]$_.goalId -eq $closingGoalId } | Select-Object -Last 1)
      $phaseSuccessor = @($AfterState.registry | Where-Object { [string]$_.goalId -eq [string]$Day.successorGoalId } | Select-Object -First 1)
      $hasSuccessor = $supersededEntry.Count -eq 1 -and [string]$supersededEntry[0].terminalOutcome -eq 'superseded' -and [string]$supersededEntry[0].successorGoalId -eq [string]$Day.successorGoalId -and $phaseSuccessor.Count -eq 1 -and @($AfterState.activeGoalIds) -contains [string]$Day.successorGoalId -and -not [string]::IsNullOrWhiteSpace([string]$phaseSuccessor[0].exitCriterion) -and [string]$phaseSuccessor[0].currentDeadline -eq [string]$Day.alertDeadline
      $checks += New-LemOracleCheck 'superseded requires successor' $hasSuccessor "successor=$($Day.successorGoalId) active"
      $checks += New-LemOracleCheck 'three replies applied' ($AfterState.correction.actualConfirmationCount -eq 3) 'actual confirmations=3'
      $checks += New-LemOracleCheck 'no Sunday artifacts' ($AfterState.artifacts.generationCount -eq 0) 'generation count=0'
    }
    14 {
      $entry = @($AfterState.closureLog | Where-Object { [string]$_.goalId -eq $closingGoalId })[-1]
      $reasonAndDisposition = $entry -and -not [string]::IsNullOrWhiteSpace([string]$entry.reason) -and -not [string]::IsNullOrWhiteSpace([string]$entry.remainingDisposition)
      $checks += New-LemOracleCheck 'dropped reason and disposition recorded' $reasonAndDisposition 'reason and remaining disposition stored'
      $checks += New-LemOracleCheck 'artifact lock prevents revision' ($AfterState.artifacts.locked -and $AfterState.artifacts.blockedMutationAttempts -ge 2 -and $AfterState.artifacts.planSurfaceHashesUnchanged -and $AfterState.authoritativeRevision -eq $BeforeState.authoritativeRevision) 'mid-generation and post-generation mutation attempts blocked; plan hashes unchanged'
      $checks += New-LemOracleCheck 'late work recorded as unplanned' ($AfterState.artifacts.postArtifactInput -and $AfterState.artifacts.unplannedMinutes -eq 45) '45 unplanned min'
      $checks += New-LemOracleCheck 'no artifact regeneration' ($AfterState.artifacts.generationCount -eq 1 -and $AfterState.artifacts.regenerationCount -eq 0 -and $AfterState.artifacts.hashesUnchangedAfterBlockedAttempt) 'one generation, zero regeneration, HTML/PNG hashes unchanged'
      $checks += New-LemOracleCheck 'high-confidence capacity retained' ($AfterState.capacity.confidence -eq 'high' -and $AfterState.capacity.expectedMinutes -eq 195) 'high, 195 min'
    }
    default { throw "No scenario oracle for day $($Day.dayIndex)" }
  }

  $expectedNames = @($Day.expectedChecks | ForEach-Object { [string]$_ })
  $actualNames = @($checks | ForEach-Object { [string]$_.name })
  Assert-LemOracleCondition (($expectedNames -join "`n") -eq ($actualNames -join "`n")) `
    "Day $($Day.dayIndex): scenario expectedChecks and executable oracles diverged"
  if ([bool]$ScoringEvidence.expected) {
    $stageOrder = @($ScoringEvidence.stages | ForEach-Object { [int]$_.order }) -join ','
    $stageHashes = @($ScoringEvidence.stages | ForEach-Object { [string]$_.blindResultHash } | Select-Object -Unique)
    $blindIsolation = $stageOrder -eq '1,2,3' -and -not [bool]$ScoringEvidence.stages[0].selfScoresVisible -and $stageHashes.Count -eq 1 -and [string]$stageHashes[0] -eq [string]$ScoringEvidence.blindResultHashBeforeSelf -and [string]$ScoringEvidence.blindResultHashBeforeSelf -eq [string]$ScoringEvidence.blindResultHashAfterCalibration
    $checks += New-LemOracleCheck 'scoring blind pass precedes self-score calibration' $blindIsolation "persisted blind hash=$($ScoringEvidence.blindResultHashBeforeSelf) stayed immutable"
    $historyToday = @($AfterState.scoreHistory | Where-Object { [string]$_.date -eq [string]$Day.date } | Select-Object -First 1)
    $scoreStored = $historyToday.Count -eq 1 -and [int]$historyToday[0].remainingSelf -eq [int]$ScoringEvidence.selfScores.remainingSelf -and [int]$historyToday[0].actualDrive -eq [int]$ScoringEvidence.blindPass.actualDrive
    $checks += New-LemOracleCheck 'simulated self and agent scores stored' $scoreStored "self=$($ScoringEvidence.selfScores.remainingSelf); actual=$($ScoringEvidence.blindPass.actualDrive)"
  } else {
    $checks += New-LemOracleCheck 'scoring skip is explicit' (-not [string]::IsNullOrWhiteSpace([string]$ScoringEvidence.reason)) ([string]$ScoringEvidence.reason)
  }
  if ([bool]$Day.artifactExpected) {
    $expectedDecision = Get-LemScorePlanningDecision -Day $Day -PriorState $BeforeState
    $decisionMatches = $Plan -and [int]$Plan.focusTargetMinutes -eq [int]$expectedDecision.targetMinutes -and [string]$Plan.scoringInput.observationDate -eq [string]$expectedDecision.observationDate -and [string]$Plan.scoringInput.predictionTargetDate -eq [string]$expectedDecision.predictionTargetDate -and [string]$Plan.scoringInput.predDriveCalibrated -eq [string]$expectedDecision.predDriveCalibrated
    $checks += New-LemOracleCheck 'score feedback changes or confirms next plan' $decisionMatches "mode=$($Plan.focusMode); target=$($Plan.focusTargetMinutes); observation=$($Plan.scoringInput.observationDate); prediction target=$($Plan.scoringInput.predictionTargetDate)"
  }
  return $checks
}

Export-ModuleMember -Function Assert-LemConfirmationNegativeCases, Assert-LemHardDeadlineAuthorityNegativeCase, Assert-LemWeightedMedianSelfTest, Get-LemConfirmationState, Get-LemDerivedGuardDecision, New-LemInitialSimulationState, New-LemSimulatedBlindEvidence, Complete-LemSimulatedScoringEvidence, Get-LemScorePlanningDecision, New-LemSimulationStateTransition, Invoke-LemScenarioOracle
