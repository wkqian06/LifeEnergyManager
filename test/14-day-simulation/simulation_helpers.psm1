Set-StrictMode -Version Latest

function Assert-LemSimulationCondition {
  param(
    [Parameter(Mandatory=$true)][bool]$Condition,
    [Parameter(Mandatory=$true)][string]$Message
  )

  if (-not $Condition) { throw $Message }
}

function Write-LemSimulationText {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Content
  )

  [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function ConvertTo-LemSimulationJson {
  param([Parameter(Mandatory=$true)]$Value)

  return ($Value | ConvertTo-Json -Depth 20)
}

function Get-LemRelativePath {
  param(
    [Parameter(Mandatory=$true)][string]$BasePath,
    [Parameter(Mandatory=$true)][string]$Path
  )

  $normalizedBase = [System.IO.Path]::GetFullPath($BasePath).TrimEnd('\') + '\'
  $normalizedPath = [System.IO.Path]::GetFullPath($Path)
  Assert-LemSimulationCondition ($normalizedPath.StartsWith($normalizedBase, [System.StringComparison]::OrdinalIgnoreCase)) `
    "Path escaped the expected test root: $normalizedPath"
  return $normalizedPath.Substring($normalizedBase.Length).Replace('\', '/')
}

function Get-LemDirectoryFingerprint {
  param([Parameter(Mandatory=$true)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) { return '<absent>' }
  $root = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
  $records = foreach ($file in Get-ChildItem -LiteralPath $root -File -Recurse | Sort-Object FullName) {
    $relative = $file.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/')
    "$relative|$($file.Length)|$((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash)"
  }
  $payload = [System.Text.Encoding]::UTF8.GetBytes(($records -join "`n"))
  $sha256 = [System.Security.Cryptography.SHA256]::Create()
  try { return ([System.BitConverter]::ToString($sha256.ComputeHash($payload))).Replace('-', '') }
  finally { $sha256.Dispose() }
}

function Assert-LemTerminalOutcome {
  param([Parameter(Mandatory=$true)]$Day)

  if (-not $Day.terminalOutcome) { return }
  Assert-LemSimulationCondition (@('completed', 'partially_completed', 'missed', 'superseded', 'dropped') -contains [string]$Day.terminalOutcome) `
    "Day $($Day.dayIndex): unknown terminal outcome $($Day.terminalOutcome)"
  switch ([string]$Day.terminalOutcome) {
    'completed' {
      Assert-LemSimulationCondition (-not [string]::IsNullOrWhiteSpace([string]$Day.closureEvidence)) `
        "Day $($Day.dayIndex): completed requires evidence"
    }
    'partially_completed' {
      Assert-LemSimulationCondition (-not [string]::IsNullOrWhiteSpace([string]$Day.closureEvidence)) `
        "Day $($Day.dayIndex): partially_completed requires evidence"
      Assert-LemSimulationCondition (-not [string]::IsNullOrWhiteSpace([string]$Day.remainingDisposition)) `
        "Day $($Day.dayIndex): partially_completed requires a remaining-work disposition"
      Assert-LemSimulationCondition (-not [string]::IsNullOrWhiteSpace([string]$Day.successorGoalId)) `
        "Day $($Day.dayIndex): partially_completed requires a successor"
    }
    'missed' {
      Assert-LemSimulationCondition (-not [string]::IsNullOrWhiteSpace([string]$Day.closureReason)) `
        "Day $($Day.dayIndex): missed requires a reason"
      Assert-LemSimulationCondition (-not [string]::IsNullOrWhiteSpace([string]$Day.remainingDisposition)) `
        "Day $($Day.dayIndex): missed requires a remaining-work disposition"
    }
    'superseded' {
      Assert-LemSimulationCondition (-not [string]::IsNullOrWhiteSpace([string]$Day.successorGoalId)) `
        "Day $($Day.dayIndex): superseded requires a successor"
    }
    'dropped' {
      Assert-LemSimulationCondition (-not [string]::IsNullOrWhiteSpace([string]$Day.closureReason)) `
        "Day $($Day.dayIndex): dropped requires a reason"
      Assert-LemSimulationCondition (-not [string]::IsNullOrWhiteSpace([string]$Day.remainingDisposition)) `
        "Day $($Day.dayIndex): dropped requires a remaining-work disposition"
    }
  }
}

function Assert-LemDayDefinition {
  param([Parameter(Mandatory=$true)]$Day)

  $prefix = "Day $($Day.dayIndex)"
  Assert-LemSimulationCondition ($Day.PSObject.Properties.Name -contains 'blindScoreSimulation') `
    "$prefix`: scoring simulation input is missing"
  $scoreExpected = [string]$Day.workflow -eq 'morning_evening'
  Assert-LemSimulationCondition ([bool]$Day.blindScoreSimulation.expected -eq $scoreExpected) `
    "$prefix`: scoring expectation must match availability of an evening workbench report"
  $expectedConfidence = if ([int]$Day.comparableDaysBefore -ge 7) { 'high' } else { 'low' }
  Assert-LemSimulationCondition ([string]$Day.confidence -eq $expectedConfidence) `
    "$prefix`: confidence must be $expectedConfidence for $($Day.comparableDaysBefore) comparable days"
  Assert-LemSimulationCondition ([int]$Day.safeCapacityMinutes -eq [Math]::Round([double]$Day.expectedCapacityMinutes * 0.8)) `
    "$prefix`: safe capacity must equal 80 percent of expected capacity"
  Assert-LemSimulationCondition ([double]$Day.estimateFactor -ge 1.0 -and [double]$Day.estimateFactor -le 2.0) `
    "$prefix`: estimate factor is outside the 1.0-2.0 boundary"

  $expectedFeasibility = if ([double]$Day.coverage -ge 1.25) { 'green' } elseif ([double]$Day.coverage -ge 1.05) { 'yellow' } else { 'red' }
  Assert-LemSimulationCondition ([string]$Day.feasibility -eq $expectedFeasibility) `
    "$prefix`: feasibility $($Day.feasibility) does not match coverage $($Day.coverage)"

  if ([string]$Day.revisionKind -eq 'rebaseline') {
    Assert-LemSimulationCondition ([int]$Day.confirmationsRequired -eq 3) "$prefix`: rebaseline requires three confirmations"
  }
  if ([string]$Day.correctionState -eq 'entered_exited' -and
      (@('month', 'phase') -contains [string]$Day.alertGoalLevel -or [string]$Day.revisionKind -eq 'rebaseline')) {
    Assert-LemSimulationCondition ([int]$Day.confirmationsRequired -eq 3) `
      "$prefix`: applied month, phase, or rebaseline change requires three confirmations"
    Assert-LemSimulationCondition (@($Day.confirmationTrace).Count -ge 3) `
      "$prefix`: applied high-impact change lacks three separate confirmation records"
  }
  if (@('entered_user_exit', 'write_failed_rollback') -contains [string]$Day.correctionState) {
    Assert-LemSimulationCondition ([string]$Day.revisionBefore -eq [string]$Day.revisionAfter) `
      "$prefix`: exit or rollback must preserve the prior revision"
  }
  if ([string]$Day.correctionState -eq 'write_failed_rollback') {
    Assert-LemSimulationCondition (-not [bool]$Day.artifactExpected) "$prefix`: rollback must block artifacts"
  }
  if ([bool]$Day.hardDeadlineViolation) {
    Assert-LemSimulationCondition ([string]$Day.proposalGuardStatus -eq 'blocked') `
      "$prefix`: unsupported hard-deadline movement must be blocked"
    Assert-LemSimulationCondition ([string]$Day.revisionBefore -eq [string]$Day.revisionAfter) `
      "$prefix`: blocked hard-deadline movement changed the revision"
  }
  if ([string]$Day.guardStatus -eq 'closure_required' -and -not $Day.terminalOutcome) {
    Assert-LemSimulationCondition (-not [bool]$Day.artifactExpected) `
      "$prefix`: closure_required without a decision must block artifacts"
  }
  if ([bool]$Day.postArtifactInput) {
    Assert-LemSimulationCondition ([int]$Day.unplannedMinutes -gt 0) `
      "$prefix`: post-artifact input must be recorded as unplanned minutes"
    Assert-LemSimulationCondition ([string]$Day.revisionBefore -eq [string]$Day.revisionAfter) `
      "$prefix`: post-artifact input must not revise the plan"
  }
  if ([string]$Day.workflow -eq 'sunday_review') {
    Assert-LemSimulationCondition (-not [bool]$Day.artifactExpected) `
      "$prefix`: Sunday audit must not emit daily artifacts"
  }
  Assert-LemTerminalOutcome -Day $Day
}

function Assert-LemFourteenDayDefinition {
  param([Parameter(Mandatory=$true)]$Definition)

  $days = @($Definition.days)
  Assert-LemSimulationCondition ($days.Count -eq 14) 'The simulation must contain exactly 14 days'
  $startDate = [datetime]::ParseExact([string]$Definition.startDate, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
  $dates = @{}
  for ($index = 0; $index -lt $days.Count; $index++) {
    $day = $days[$index]
    Assert-LemSimulationCondition ([int]$day.dayIndex -eq $index + 1) "Scenario index mismatch at position $($index + 1)"
    $expectedDate = $startDate.AddDays($index).ToString('yyyy-MM-dd')
    Assert-LemSimulationCondition ([string]$day.date -eq $expectedDate) "Day $($day.dayIndex): expected date $expectedDate"
    Assert-LemSimulationCondition (-not $dates.ContainsKey([string]$day.date)) "Duplicate simulation date: $($day.date)"
    if ($index -gt 0) {
      Assert-LemSimulationCondition ([string]$day.revisionBefore -eq [string]$days[$index - 1].revisionAfter) `
        "Day $($day.dayIndex): revisionBefore does not continue the prior day"
    }
    $dates[[string]$day.date] = $true
    Assert-LemDayDefinition -Day $day
  }
  $terminalOutcomes = @($days | Where-Object terminalOutcome | ForEach-Object { [string]$_.terminalOutcome } | Sort-Object -Unique)
  foreach ($requiredOutcome in @('completed', 'partially_completed', 'missed', 'superseded', 'dropped')) {
    Assert-LemSimulationCondition ($terminalOutcomes -contains $requiredOutcome) "Missing terminal outcome scenario: $requiredOutcome"
  }
}

function New-LemGoalAlerts {
  param([Parameter(Mandatory=$true)]$Day)

  if (-not $Day.alertGoalId -or [string]$Day.proximity -eq 'normal') { return @() }
  $historyStart = ([datetime]::ParseExact([string]$Day.date, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)).AddDays(-27).ToString('yyyy-MM-dd')
  $primary = [ordered]@{
    goalId = [string]$Day.alertGoalId
    title = [string]$Day.alertTitle
    level = [string]$Day.alertGoalLevel
    deadline = [string]$Day.alertDeadline
    deadlineType = $(if ([bool]$Day.hardDeadlineViolation) { 'hard' } else { 'soft' })
    originalDeadline = [string]$Day.alertDeadline
    currentDeadline = [string]$Day.alertDeadline
    proximity = [string]$Day.proximity
    feasibility = [string]$Day.feasibility
    correctedRemainingMinutes = [int]$Day.correctedRemainingMinutes
    safeCapacityMinutes = [int]$Day.safeCapacityMinutes
    coverage = [double]$Day.coverage
    confidence = [string]$Day.confidence
    historyWindow = "$historyStart to $($Day.date)"
    comparableDays = [int]$Day.comparableDaysBefore
    historyLabels = @("normal comparable: $($Day.comparableDaysBefore)", 'special labels excluded from normal capacity')
    latestSafeStart = [string]$Day.date
    estimateFactor = [double]$Day.estimateFactor
    requiredToday = [string]$Day.requiredToday
    explanation = "Coverage $($Day.coverage); guard $($Day.proposalGuardStatus); goal debt $($Day.goalDebtMinutes) min."
  }
  $alerts = @($primary)
  if (@(5, 7) -contains [int]$Day.dayIndex) {
    $alerts += [ordered]@{
      goalId = 'WK-2026-07-20'
      title = 'Protect the linked weekly output'
      level = 'week'
      deadline = '2026-07-27'
      deadlineType = 'soft'
      originalDeadline = '2026-07-27'
      currentDeadline = '2026-07-27'
      proximity = 'approaching'
      feasibility = 'yellow'
      correctedRemainingMinutes = 240
      safeCapacityMinutes = [int]$Day.safeCapacityMinutes
      coverage = 1.10
      confidence = [string]$Day.confidence
      historyWindow = "$historyStart to $($Day.date)"
      comparableDays = [int]$Day.comparableDaysBefore
      historyLabels = @('linked weekly target')
      latestSafeStart = [string]$Day.date
      estimateFactor = [double]$Day.estimateFactor
      requiredToday = 'Preserve one linked reviewable output'
      explanation = 'The higher-level correction reduces weekly buffer.'
    }
  }
  return $alerts
}

function New-LemSimulationPlanData {
  param(
    [Parameter(Mandatory=$true)]$Day,
    [Parameter(Mandatory=$true)]$PriorState
  )

  $alerts = @(New-LemGoalAlerts -Day $Day)
  $changedToday = [string]$Day.revisionBefore -ne [string]$Day.revisionAfter
  $affectedLevels = @($Day.affectedLevels)
  $scoreDecision = Get-LemScorePlanningDecision -Day $Day -PriorState $PriorState
  $focusMinutes = [int]$scoreDecision.targetMinutes
  $baselineTitle = if ([string]$Day.runMode -eq 'manual_catchup') { 'Save one critical-path result' } else { 'Complete the protected result' }
  $planningSummary = "Planning calibration: $($Day.comparableDaysBefore) comparable day(s); expected $($Day.expectedCapacityMinutes) min; safe $($Day.safeCapacityMinutes) min; estimate factor $($Day.estimateFactor); confidence $($Day.confidence)."
  $focusMode = if ([string]$Day.runMode -eq 'manual_catchup') {
    'Manual catch-up'
  } elseif ([string]$Day.dayLabel -eq 'illness') {
    'Reduced illness day'
  } else { [string]$scoreDecision.focusMode }

  return [ordered]@{
    date = [string]$Day.date
    planRevisionId = [string]$Day.revisionAfter
    focusMode = $focusMode
    taskFocusType = 'Deliverable / closure'
    taskFocusColor = 'blue'
    timeCombination = $(if ([string]$Day.runMode -eq 'manual_catchup') { '2 H compressed baseline' } elseif ($focusMinutes -le 90) { '90 min protected recovery baseline' } elseif ($focusMinutes -le 120) { '2 H reduced baseline' } else { '3 H Baseline + 1 H Stretch' })
    focusTargetMinutes = $focusMinutes
    statusSummaryHtml = "Guard: $($Day.guardStatus). Feasibility: $($Day.feasibility)."
    todayAdviceHtml = [string]$Day.requiredToday
    antiDistractionTipHtml = 'Do not add work unless it explicitly replaces a confirmed task.'
    todaySuggestionHtml = 'Start with the critical-path task and save reviewable evidence.'
    goalAlerts = $alerts
    revisionSummary = [ordered]@{
      revisionId = [string]$Day.revisionAfter
      changedToday = $changedToday
      affectedLevels = $affectedLevels
      before = "Authoritative revision $($Day.revisionBefore)."
      after = "Authoritative revision $($Day.revisionAfter)."
      cumulativeDelayDays = $(if ([int]$Day.goalDebtMinutes -gt 0) { [Math]::Ceiling([int]$Day.goalDebtMinutes / [int]$Day.safeCapacityMinutes) } else { 0 })
      goalDebtMinutes = [int]$Day.goalDebtMinutes
      feasibility = [string]$Day.feasibility
      status = $(if ([string]$Day.correctionState -eq 'entered_exited') { 'confirmed and exited' } elseif ([string]$Day.correctionState -eq 'locked_after_artifact') { 'artifact locked' } else { 'unchanged' })
    }
    stack = @(
      [ordered]@{ kind='phase'; label='Phase'; value='18 / 40'; percent=45; note='Dissertation phase' },
      [ordered]@{ kind='month'; label='Month'; value='10 / 20'; percent=50; note='July outputs' },
      [ordered]@{ kind='week'; label='Week'; value='3 / 5'; percent=60; note='Protected outputs' },
      [ordered]@{ kind='sprint'; label='Sprint'; value='4 / 6'; percent=67; note='Analysis gate' },
      [ordered]@{ kind='commitment'; label='Commitment'; value='1 / 3'; percent=33; note='Inside cap' }
    )
    commitments = @(
      [ordered]@{ id='cm1'; goalId='CM-CO-REVIEW'; criticalPath=$false; title='Capped co-review'; minutes=20; desc='Review one bounded section after the baseline.'; color='orange' }
    )
    baseline = @(
      [ordered]@{ id='b1'; goalId=$(if ($Day.alertGoalId) { [string]$Day.alertGoalId } else { 'PH-DISSERTATION-V3' }); criticalPath=$true; title=$baselineTitle; minutes=$focusMinutes; desc='Save the result, parameters, and interpretation as evidence.'; color='green' },
      [ordered]@{ id='b2'; goalId='MO-2026-07'; criticalPath=$true; title='Write the result note'; minutes=45; desc='Turn the saved result into a concise manuscript note.'; color='blue' }
    )
    stretch = @(
      [ordered]@{ id='s1'; goalId='WK-2026-07-20'; criticalPath=$false; title='Prepare the next stub'; minutes=45; desc='Prepare only the next graduation-critical input.'; color='gray' }
    )
    planningCalibration = [ordered]@{
      summary = $planningSummary
      confidence = [string]$Day.confidence
      weeklyOutputCompletionRate = '5/8 (62.5%)'
    }
    scoringInput = $scoreDecision
    history = @($PriorState.scoreHistory | Where-Object {
      [string]$_.date -le [string]$Day.date
    } | Sort-Object date | Select-Object -Last 7)
  }
}

function New-LemSimulationWallpaperConfig {
  param(
    [Parameter(Mandatory=$true)]$Day,
    [Parameter(Mandatory=$true)]$Plan,
    [Parameter(Mandatory=$true)][string]$OutputPath
  )

  $config = [ordered]@{
    date = [string]$Day.date
    subtitle = "14-day simulation | Day $($Day.dayIndex) | $($Day.dayLabel)"
    focusType = [string]$Plan.taskFocusType
    focusColor = [string]$Plan.taskFocusColor
    timeMix = [string]$Plan.timeCombination
    baseline = @($Plan.baseline | ForEach-Object { [ordered]@{ title=$_.title; minutes=$_.minutes; desc=$_.desc; color=$_.color } })
    stretch = @($Plan.stretch | ForEach-Object { [ordered]@{ title=$_.title; minutes=$_.minutes; desc=$_.desc; color=$_.color } })
    progress = @(
      [ordered]@{ kind='week'; label='Week'; value='3 / 5'; percent=60; note='Protected outputs' },
      [ordered]@{ kind='sprint'; label='Sprint'; value='4 / 6'; percent=67; note='Analysis gate' },
      [ordered]@{ kind='commitment'; label='Commitment'; value='1 / 3'; percent=33; note='Inside cap' },
      [ordered]@{ kind='month'; label='Month'; value='10 / 20'; percent=50; note='July outputs' },
      [ordered]@{ kind='phase'; label='Phase'; value='18 / 40'; percent=45; note='Dissertation phase' }
    )
    status = "Guard $($Day.guardStatus); feasibility $($Day.feasibility); confidence $($Day.confidence)."
    advice = [string]$Day.requiredToday
    tip = 'Log late work; do not silently revise a locked plan.'
    planRevisionId = [string]$Day.revisionAfter
    outPath = $OutputPath
  }
  if ([string]$Day.runMode -eq 'manual_catchup') {
    $config.baselineTitle = 'Compressed baseline'
    $config.stretchTitle = 'Only if time remains'
  }
  if (@($Plan.goalAlerts).Count -gt 0) {
    $primary = @($Plan.goalAlerts)[0]
    $config.goalAlert = [ordered]@{
      goalId = [string]$primary.goalId
      goalLevel = [string]$primary.level
      level = [string]$primary.proximity
      title = [string]$primary.title
      deadline = [string]$primary.deadline
      remaining = "$($primary.correctedRemainingMinutes) min"
      requiredToday = [string]$primary.requiredToday
      additionalCount = [Math]::Max(0, @($Plan.goalAlerts).Count - 1)
    }
  }
  return ($config | ConvertTo-Json -Depth 10 | ConvertFrom-Json)
}

function Get-LemFileHashOrAbsent {
  param([Parameter(Mandatory=$true)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) { return '<absent>' }
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-LemSurfaceRevisions {
  param(
    [Parameter(Mandatory=$true)][string]$SurfaceRoot,
    [Parameter(Mandatory=$true)][array]$SurfaceNames
  )

  $revisions = [ordered]@{}
  foreach ($surfaceName in $SurfaceNames) {
    $surfacePath = Join-Path $SurfaceRoot "$surfaceName.json"
    $surface = Get-Content -LiteralPath $surfacePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $revisions[$surfaceName] = [string]$surface.planRevisionId
  }
  return $revisions
}

function Invoke-LemSimulatedPlanTransaction {
  param(
    [Parameter(Mandatory=$true)]$Day,
    [Parameter(Mandatory=$true)][string]$SurfaceRoot,
    [Parameter(Mandatory=$true)]$ConfirmationState
  )

  $surfaceNames = @('tracker', 'phase', 'month', 'week')
  if (-not (Test-Path -LiteralPath $SurfaceRoot)) { New-Item -ItemType Directory -Path $SurfaceRoot | Out-Null }
  foreach ($surfaceName in $surfaceNames) {
    $surfacePath = Join-Path $SurfaceRoot "$surfaceName.json"
    if (-not (Test-Path -LiteralPath $surfacePath)) {
      $initialSurface = [ordered]@{ surface=$surfaceName; planRevisionId=[string]$Day.revisionBefore; lastTransaction='initial' }
      Write-LemSimulationText -Path $surfacePath -Content (ConvertTo-LemSimulationJson -Value $initialSurface)
    }
  }

  $beforeRevisions = Get-LemSurfaceRevisions -SurfaceRoot $SurfaceRoot -SurfaceNames $surfaceNames
  foreach ($surfaceName in $surfaceNames) {
    Assert-LemSimulationCondition ([string]$beforeRevisions[$surfaceName] -eq [string]$Day.revisionBefore) `
      "Day $($Day.dayIndex): runtime $surfaceName revision does not match revisionBefore"
  }
  $beforeContent = [ordered]@{}
  $beforeHashes = [ordered]@{}
  foreach ($surfaceName in $surfaceNames) {
    $surfacePath = Join-Path $SurfaceRoot "$surfaceName.json"
    $beforeContent[$surfaceName] = [System.IO.File]::ReadAllText($surfacePath, [System.Text.Encoding]::UTF8)
    $beforeHashes[$surfaceName] = Get-LemFileHashOrAbsent -Path $surfacePath
  }

  $revisionChanged = [string]$Day.revisionBefore -ne [string]$Day.revisionAfter
  $attemptedRevision = if ([string]$Day.correctionState -eq 'write_failed_rollback') {
    "PR-$(([string]$Day.date).Replace('-', ''))-1"
  } else { [string]$Day.revisionAfter }
  $contentSurfaces = @($Day.transactionFiles | ForEach-Object { [string]$_ })
  $writeOrder = if ($revisionChanged -or [string]$Day.correctionState -eq 'write_failed_rollback') {
    @($contentSurfaces | Where-Object { $_ -ne 'tracker' }) + @($surfaceNames | Where-Object { $_ -ne 'tracker' -and $contentSurfaces -notcontains $_ }) + @('tracker')
  } else { $contentSurfaces }
  $writeOrder = @($writeOrder | Select-Object -Unique)
  if ($writeOrder.Count -gt 0 -and [int]$Day.confirmationsRequired -gt 0) {
    Assert-LemSimulationCondition ([bool]$ConfirmationState.complete) `
      "Day $($Day.dayIndex): plan transaction attempted before required confirmations completed"
  }
  if ($writeOrder.Count -gt 0) {
    Assert-LemSimulationCondition ([string]::IsNullOrWhiteSpace([string]$ConfirmationState.userExitCommand)) `
      "Day $($Day.dayIndex): plan transaction attempted after user exited correction mode"
  }
  $writeAttemptCount = 0
  $rolledBack = $false
  $failureMessage = $null
  $failureTrials = @()
  $writeSurface = {
    param([string]$SurfaceName)
    $surfacePath = Join-Path $SurfaceRoot "$SurfaceName.json"
    $surfaceData = [ordered]@{
      surface = $SurfaceName
      planRevisionId = $attemptedRevision
      lastTransaction = [string]$Day.date
      contentChanged = $contentSurfaces -contains $SurfaceName
    }
    Write-LemSimulationText -Path $surfacePath -Content (ConvertTo-LemSimulationJson -Value $surfaceData)
  }
  if ([string]$Day.correctionState -eq 'write_failed_rollback') {
    $failurePoints = @(@([int]$Day.injectWriteFailureAt, [int]$writeOrder.Count) | Select-Object -Unique)
    foreach ($failurePoint in $failurePoints) {
      $trialAttempts = 0
      $failedSurface = $null
      try {
        foreach ($surfaceName in $writeOrder) {
          Assert-LemSimulationCondition ($surfaceNames -contains $surfaceName) "Day $($Day.dayIndex): unknown transaction surface $surfaceName"
          $trialAttempts += 1
          $writeAttemptCount += 1
          & $writeSurface $surfaceName
          if ($trialAttempts -eq [int]$failurePoint) {
            $failedSurface = $surfaceName
            throw "SIMULATED_WRITE_FAILURE:$surfaceName"
          }
        }
        throw "Day $($Day.dayIndex): configured failure point $failurePoint was not reached"
      } catch {
        if (-not $_.Exception.Message.StartsWith('SIMULATED_WRITE_FAILURE:')) { throw }
        foreach ($surfaceName in $surfaceNames) {
          Write-LemSimulationText -Path (Join-Path $SurfaceRoot "$surfaceName.json") -Content ([string]$beforeContent[$surfaceName])
        }
        $trialHashesRestored = -not @($surfaceNames | Where-Object {
          (Get-LemFileHashOrAbsent -Path (Join-Path $SurfaceRoot "$_.json")) -ne [string]$beforeHashes[$_]
        }).Count
        Assert-LemSimulationCondition $trialHashesRestored "Day $($Day.dayIndex): rollback trial $failurePoint did not restore every surface"
        $failureTrials += [ordered]@{ failurePoint=[int]$failurePoint; failedSurface=$failedSurface; attempts=$trialAttempts; hashesRestored=$trialHashesRestored }
      }
    }
    $rolledBack = $true
    $failureMessage = @($failureTrials | ForEach-Object { "SIMULATED_WRITE_FAILURE:$($_.failedSurface)" }) -join '; '
  } else {
    foreach ($surfaceName in $writeOrder) {
      Assert-LemSimulationCondition ($surfaceNames -contains $surfaceName) "Day $($Day.dayIndex): unknown transaction surface $surfaceName"
      $writeAttemptCount += 1
      & $writeSurface $surfaceName
    }
  }

  $afterRevisions = Get-LemSurfaceRevisions -SurfaceRoot $SurfaceRoot -SurfaceNames $surfaceNames
  $afterHashes = [ordered]@{}
  foreach ($surfaceName in $surfaceNames) {
    $afterHashes[$surfaceName] = Get-LemFileHashOrAbsent -Path (Join-Path $SurfaceRoot "$surfaceName.json")
  }
  $hashesUnchanged = -not @($surfaceNames | Where-Object { [string]$beforeHashes[$_] -ne [string]$afterHashes[$_] }).Count
  if ($rolledBack) {
    Assert-LemSimulationCondition $hashesUnchanged "Day $($Day.dayIndex): rollback did not restore all plan-surface hashes"
  }
  foreach ($surfaceName in $surfaceNames) {
    Assert-LemSimulationCondition ([string]$afterRevisions[$surfaceName] -eq [string]$Day.revisionAfter) `
      "Day $($Day.dayIndex): runtime $surfaceName revision does not match revisionAfter"
  }
  return [ordered]@{
    authoritativeRevisionBefore = [string]$Day.revisionBefore
    authoritativeRevisionAfter = [string]$afterRevisions.tracker
    beforeRevisions = $beforeRevisions
    afterRevisions = $afterRevisions
    beforeHashes = $beforeHashes
    afterHashes = $afterHashes
    contentChangedSurfaces = $contentSurfaces
    attemptedSurfaces = $writeOrder
    attemptedRevision = $attemptedRevision
    writeAttemptCount = $writeAttemptCount
    injectedFailureAt = @($failureTrials | ForEach-Object { $_.failurePoint })
    failureTrials = $failureTrials
    rolledBack = $rolledBack
    hashesUnchanged = $hashesUnchanged
    committed = $writeOrder.Count -gt 0 -and -not $rolledBack
    failureMessage = $failureMessage
  }
}

function Start-LemArtifactGenerationLock {
  param(
    [Parameter(Mandatory=$true)]$Day,
    [Parameter(Mandatory=$true)][string]$DayDirectory
  )

  $lockPath = Join-Path $DayDirectory 'artifact.lock'
  Assert-LemSimulationCondition (-not (Test-Path -LiteralPath $lockPath)) "Day $($Day.dayIndex): artifact lock already existed before generation"
  Write-LemSimulationText -Path $lockPath -Content "status=generating; revision=$($Day.revisionAfter); createdBefore=html,png"
  return $lockPath
}

function Invoke-LemArtifactMutationAttempt {
  param(
    [Parameter(Mandatory=$true)]$Day,
    [Parameter(Mandatory=$true)][string]$LockPath,
    [Parameter(Mandatory=$true)][string]$HtmlPath,
    [Parameter(Mandatory=$true)][string]$WallpaperPath,
    [Parameter(Mandatory=$true)][string]$SurfaceRoot,
    [Parameter(Mandatory=$true)][string]$Stage
  )

  $htmlHashBefore = Get-LemFileHashOrAbsent -Path $HtmlPath
  $wallpaperHashBefore = Get-LemFileHashOrAbsent -Path $WallpaperPath
  $surfaceFingerprintBefore = Get-LemDirectoryFingerprint -Path $SurfaceRoot
  $blocked = Test-Path -LiteralPath $LockPath
  if (-not $blocked) {
    Write-LemSimulationText -Path $HtmlPath -Content "unauthorized revision $($Day.revisionAfter)"
    [System.IO.File]::WriteAllBytes($WallpaperPath, [byte[]](1, 2, 3, 4))
    Write-LemSimulationText -Path (Join-Path $SurfaceRoot 'tracker.json') -Content '{"planRevisionId":"UNAUTHORIZED"}'
  }
  $htmlHashAfter = Get-LemFileHashOrAbsent -Path $HtmlPath
  $wallpaperHashAfter = Get-LemFileHashOrAbsent -Path $WallpaperPath
  $surfaceFingerprintAfter = Get-LemDirectoryFingerprint -Path $SurfaceRoot
  return [ordered]@{
    stage = $Stage
    blocked = $blocked
    reason = $(if ($blocked) { 'artifact_generation_lock_active' } else { 'mutation_executed' })
    htmlHashUnchanged = $htmlHashBefore -eq $htmlHashAfter
    wallpaperHashUnchanged = $wallpaperHashBefore -eq $wallpaperHashAfter
    planSurfaceHashesUnchanged = $surfaceFingerprintBefore -eq $surfaceFingerprintAfter
  }
}

function Get-LemArtifactEvidence {
  param(
    [Parameter(Mandatory=$true)]$Day,
    [Parameter(Mandatory=$true)][string]$DayDirectory,
    [AllowNull()][string]$HtmlPath,
    [AllowNull()][string]$WallpaperPath,
    [AllowNull()][string]$LockPath,
    $MidGenerationAttempt,
    $PostGenerationAttempt
  )

  if (-not [bool]$Day.artifactExpected) {
    Assert-LemSimulationCondition ([string]::IsNullOrWhiteSpace($HtmlPath) -and [string]::IsNullOrWhiteSpace($WallpaperPath)) `
      "Day $($Day.dayIndex): blocked day received artifact paths"
    return [ordered]@{ expected=$false; generationCount=0; regenerationCount=0; locked=$false; blockedMutationAttempts=0; midGenerationBlocked=$false; hashesUnchangedAfterBlockedAttempt=$true; planSurfaceHashesUnchanged=$true; postArtifactInput=$false; unplannedMinutes=0 }
  }

  Assert-LemSimulationCondition (Test-Path -LiteralPath $HtmlPath) "Day $($Day.dayIndex): workbench is missing after generation"
  Assert-LemSimulationCondition (Test-Path -LiteralPath $WallpaperPath) "Day $($Day.dayIndex): wallpaper is missing after generation"
  Assert-LemSimulationCondition (Test-Path -LiteralPath $LockPath) "Day $($Day.dayIndex): artifact lock is missing"
  $lockCreatedBeforeHtml = (Get-Item -LiteralPath $LockPath).CreationTimeUtc -le (Get-Item -LiteralPath $HtmlPath).LastWriteTimeUtc
  $attempts = @($MidGenerationAttempt)
  if ($null -ne $PostGenerationAttempt) { $attempts += $PostGenerationAttempt }
  $allAttemptsBlocked = @($attempts | Where-Object { -not [bool]$_.blocked }).Count -eq 0
  $allHashesUnchanged = @($attempts | Where-Object { -not [bool]$_.htmlHashUnchanged -or -not [bool]$_.wallpaperHashUnchanged }).Count -eq 0
  $allPlanHashesUnchanged = @($attempts | Where-Object { -not [bool]$_.planSurfaceHashesUnchanged }).Count -eq 0
  Assert-LemSimulationCondition ($lockCreatedBeforeHtml -and $allAttemptsBlocked -and $allHashesUnchanged -and $allPlanHashesUnchanged) `
    "Day $($Day.dayIndex): artifact lock timing or mutation rejection failed"
  return [ordered]@{
    expected = $true
    generationCount = 1
    regenerationCount = 0
    locked = Test-Path -LiteralPath $lockPath
    lockCreatedBeforeFirstArtifact = $lockCreatedBeforeHtml
    blockedMutationAttempts = $attempts.Count
    midGenerationBlocked = [bool]$MidGenerationAttempt.blocked
    hashesUnchangedAfterBlockedAttempt = $allHashesUnchanged
    planSurfaceHashesUnchanged = $allPlanHashesUnchanged
    htmlHash = Get-LemFileHashOrAbsent -Path $HtmlPath
    wallpaperHash = Get-LemFileHashOrAbsent -Path $WallpaperPath
    postArtifactInput = [bool]$Day.postArtifactInput
    unplannedMinutes = [int]$Day.unplannedMinutes
  }
}

function Invoke-LemArtifactMutationApiSelfTest {
  param([Parameter(Mandatory=$true)][string]$ResultsRoot)

  $selfTestRoot = Join-Path $ResultsRoot 'self-tests\unlocked-artifact-mutation'
  $surfaceRoot = Join-Path $selfTestRoot 'plan-surfaces'
  New-Item -ItemType Directory -Path $surfaceRoot | Out-Null
  $htmlPath = Join-Path $selfTestRoot 'workbench.html'
  $wallpaperPath = Join-Path $selfTestRoot 'wallpaper.png'
  $lockPath = Join-Path $selfTestRoot 'artifact.lock'
  Write-LemSimulationText -Path $htmlPath -Content 'authorized html'
  [System.IO.File]::WriteAllBytes($wallpaperPath, [byte[]](9, 9, 9, 9))
  Write-LemSimulationText -Path (Join-Path $surfaceRoot 'tracker.json') -Content '{"planRevisionId":"AUTHORIZED"}'
  $attempt = Invoke-LemArtifactMutationAttempt `
    -Day ([pscustomobject]@{ dayIndex=97; revisionAfter='PR-SELF-TEST' }) `
    -LockPath $lockPath `
    -HtmlPath $htmlPath `
    -WallpaperPath $wallpaperPath `
    -SurfaceRoot $surfaceRoot `
    -Stage 'unlocked_negative_control'
  Assert-LemSimulationCondition (-not [bool]$attempt.blocked -and -not [bool]$attempt.htmlHashUnchanged -and -not [bool]$attempt.wallpaperHashUnchanged -and -not [bool]$attempt.planSurfaceHashesUnchanged) `
    'Unlocked artifact mutation negative control did not mutate every protected surface'
  return $attempt
}

function New-LemDayReportMarkdown {
  param(
    [Parameter(Mandatory=$true)]$Day,
    [Parameter(Mandatory=$true)]$DayResult
  )

  $terminal = if ($Day.terminalOutcome) { [string]$Day.terminalOutcome } else { '-' }
  $artifact = if ([bool]$Day.artifactExpected) { 'generated and verified' } else { "not generated ($($Day.artifactBlockReason))" }
  $scoring = if ([bool]$DayResult.scoring.expected) {
    "self $($DayResult.scoring.selfScores.remainingSelf)/$($DayResult.scoring.selfScores.predDriveSelf); blind $($DayResult.scoring.blindPass.remainingBlind)/$($DayResult.scoring.blindPass.predDriveBlind); actual $($DayResult.scoring.blindPass.actualDrive); calibrated $($DayResult.scoring.calibrated.remainingCalibrated)/$($DayResult.scoring.calibrated.predDriveCalibrated)"
  } else { "not scored: $($DayResult.scoring.reason)" }
  $checkLines = @($DayResult.checks | ForEach-Object { "- PASS: $($_.name): $($_.evidence)" }) -join "`n"
  return @"
# Day $($Day.dayIndex): $($Day.date)

- Scenario: $($Day.scenario)
- Workflow: $($Day.workflow) / $($Day.dayLabel)
- Guard: $($Day.guardStatus) (proposal: $($Day.proposalGuardStatus))
- Revision: $($Day.revisionBefore) -> $($Day.revisionAfter)
- Correction: $($Day.correctionState); confirmations required: $($Day.confirmationsRequired); actual valid replies: $($DayResult.actualConfirmationCount)
- Capacity: expected $($Day.expectedCapacityMinutes) min; safe $($Day.safeCapacityMinutes) min; coverage $($Day.coverage); confidence $($Day.confidence)
- Goal debt: $($Day.goalDebtMinutes) min
- Terminal outcome: $terminal
- Artifact result: $artifact
- Critical path: planned $($Day.plannedCriticalMinutes) min; actual $($Day.actualCriticalMinutes) min
- Unplanned work: $($Day.unplannedMinutes) min
- Daily scoring: $scoring

## Checks

$checkLines
"@
}

function Invoke-LemFourteenDaySimulation {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$ScenarioPath,
    [Parameter(Mandatory=$true)][string]$BlindScoringScenarioPath,
    [Parameter(Mandatory=$true)][string]$SelfScoringScenarioPath,
    [Parameter(Mandatory=$true)][string]$TemplatePath,
    [Parameter(Mandatory=$true)][string]$TestRoot,
    [Parameter(Mandatory=$true)][string]$ResultsRoot,
    [Parameter(Mandatory=$true)][string]$RepositoryOutputsPath,
    [Parameter(Mandatory=$true)][string]$NodeVerifierPath,
    [Parameter(Mandatory=$true)][string]$SummaryBuilderPath,
    [Parameter(Mandatory=$true)][string]$OracleModulePath,
    [switch]$UpdateCanonicalEvidence
  )

  $normalizedTestRoot = [System.IO.Path]::GetFullPath($TestRoot).TrimEnd('\') + '\'
  $normalizedResultsRoot = [System.IO.Path]::GetFullPath($ResultsRoot)
  Assert-LemSimulationCondition ($normalizedResultsRoot.StartsWith($normalizedTestRoot, [System.StringComparison]::OrdinalIgnoreCase)) `
    "ResultsRoot must stay inside TestRoot: $normalizedResultsRoot"
  Assert-LemSimulationCondition (-not (Test-Path -LiteralPath $normalizedResultsRoot)) `
    "Results root already exists; use a fresh run folder: $normalizedResultsRoot"
  Assert-LemSimulationCondition (Test-Path -LiteralPath $ScenarioPath) "Missing scenario definition: $ScenarioPath"
  Assert-LemSimulationCondition (Test-Path -LiteralPath $BlindScoringScenarioPath) "Missing blind scoring scenario definition: $BlindScoringScenarioPath"
  Assert-LemSimulationCondition (Test-Path -LiteralPath $SelfScoringScenarioPath) "Missing self scoring scenario definition: $SelfScoringScenarioPath"
  Assert-LemSimulationCondition (Test-Path -LiteralPath $TemplatePath) "Missing workbench template: $TemplatePath"
  Assert-LemSimulationCondition (Test-Path -LiteralPath $NodeVerifierPath) "Missing Node verifier: $NodeVerifierPath"
  Assert-LemSimulationCondition (Test-Path -LiteralPath $SummaryBuilderPath) "Missing summary builder: $SummaryBuilderPath"
  Assert-LemSimulationCondition (Test-Path -LiteralPath $OracleModulePath) "Missing oracle module: $OracleModulePath"
  Import-Module $OracleModulePath -Force
  Assert-LemConfirmationNegativeCases
  Assert-LemHardDeadlineAuthorityNegativeCase
  Assert-LemWeightedMedianSelfTest

  $definition = Get-Content -LiteralPath $ScenarioPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $blindScoringDefinition = Get-Content -LiteralPath $BlindScoringScenarioPath -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-LemSimulationCondition ([string]$blindScoringDefinition.model -eq 'evidence-only-blind-pass') `
    'Blind scoring simulation must use the evidence-only model'
  Assert-LemSimulationCondition (@($blindScoringDefinition.days).Count -eq 14) `
    'Blind scoring simulation must contain exactly 14 day records'
  foreach ($day in @($definition.days)) {
    $scoreMatches = @($blindScoringDefinition.days | Where-Object { [int]$_.dayIndex -eq [int]$day.dayIndex })
    Assert-LemSimulationCondition ($scoreMatches.Count -eq 1) `
      "Day $($day.dayIndex): expected exactly one blind scoring fixture"
    $day | Add-Member -NotePropertyName blindScoreSimulation -NotePropertyValue $scoreMatches[0]
  }
  Assert-LemFourteenDayDefinition -Definition $definition
  $template = Get-Content -LiteralPath $TemplatePath -Raw -Encoding UTF8
  Assert-LemSimulationCondition ($template.Contains('{{PLAN_JSON}}')) 'Workbench template is missing the PLAN_JSON placeholder'

  $outputsBefore = Get-LemDirectoryFingerprint -Path $RepositoryOutputsPath
  New-Item -ItemType Directory -Path $normalizedResultsRoot | Out-Null
  $artifactMutationSelfTest = Invoke-LemArtifactMutationApiSelfTest -ResultsRoot $normalizedResultsRoot
  $dayResults = @()
  $currentState = New-LemInitialSimulationState
  $surfaceRoot = Join-Path $normalizedResultsRoot 'runtime\plan-surfaces'
  foreach ($day in @($definition.days)) {
    $dayDirectory = Join-Path $normalizedResultsRoot ("day-{0:d2}-{1}" -f [int]$day.dayIndex, [string]$day.date)
    New-Item -ItemType Directory -Path $dayDirectory | Out-Null
    $generatedFiles = @()
    $confirmationState = Get-LemConfirmationState -Day $day
    $needsPreTransactionGate = `
      ($day.PSObject.Properties.Name -contains 'planChangeProposal' -and $null -ne $day.planChangeProposal) -or `
      ($day.closingGoalId -and -not $day.terminalOutcome)
    if ($needsPreTransactionGate) {
      $preTransactionGuard = Get-LemDerivedGuardDecision -Day $day -PriorState $currentState -Transaction ([pscustomobject]@{ committed=$false })
      if (@('blocked', 'closure_required') -contains [string]$preTransactionGuard.proposalStatus) {
        Assert-LemSimulationCondition (@($day.transactionFiles).Count -eq 0 -and [string]$day.revisionBefore -eq [string]$day.revisionAfter) `
          "Day $($day.dayIndex): blocked Guard proposal reached the plan transaction"
      }
    }
    $transaction = Invoke-LemSimulatedPlanTransaction -Day $day -SurfaceRoot $surfaceRoot -ConfirmationState $confirmationState
    $plan = $null
    $wallpaperConfig = $null
    $htmlPath = $null
    $wallpaperPath = $null
    $artifactLockPath = $null
    $midGenerationAttempt = $null
    $postGenerationAttempt = $null

    if ([bool]$day.artifactExpected) {
      $plan = New-LemSimulationPlanData -Day $day -PriorState $currentState
      $planJson = ConvertTo-LemSimulationJson -Value $plan
      $planPath = Join-Path $dayDirectory 'plan.json'
      Write-LemSimulationText -Path $planPath -Content $planJson
      $generatedFiles += Get-LemRelativePath -BasePath $TestRoot -Path $planPath

      $htmlPath = Join-Path $dayDirectory 'workbench.html'
      $wallpaperPath = Join-Path $dayDirectory 'wallpaper.png'
      $artifactLockPath = Start-LemArtifactGenerationLock -Day $day -DayDirectory $dayDirectory
      Write-LemSimulationText -Path $htmlPath -Content $template.Replace('{{PLAN_JSON}}', $planJson)
      $generatedFiles += Get-LemRelativePath -BasePath $TestRoot -Path $htmlPath
      $midGenerationAttempt = Invoke-LemArtifactMutationAttempt -Day $day -LockPath $artifactLockPath -HtmlPath $htmlPath -WallpaperPath $wallpaperPath -SurfaceRoot $surfaceRoot -Stage 'html_started_png_not_started'

      $wallpaperConfig = New-LemSimulationWallpaperConfig -Day $day -Plan $plan -OutputPath $wallpaperPath
      $wallpaperConfigPath = Join-Path $dayDirectory 'wallpaper-config.json'
      $wallpaperConfigEvidence = $wallpaperConfig | ConvertTo-Json -Depth 20 | ConvertFrom-Json
      $wallpaperConfigEvidence.outPath = Get-LemRelativePath -BasePath $TestRoot -Path $wallpaperPath
      Write-LemSimulationText -Path $wallpaperConfigPath -Content (ConvertTo-LemSimulationJson -Value $wallpaperConfigEvidence)
      $generatedFiles += Get-LemRelativePath -BasePath $TestRoot -Path $wallpaperConfigPath
      Invoke-LifeEnergyWallpaperRender -Config $wallpaperConfig | Out-Null
      Assert-LemSimulationCondition (Test-Path -LiteralPath $wallpaperPath) "Day $($day.dayIndex): wallpaper was not generated"
      $image = [System.Drawing.Image]::FromFile($wallpaperPath)
      try {
        Assert-LemSimulationCondition ($image.Width -eq 2560 -and $image.Height -eq 1440) `
          "Day $($day.dayIndex): wallpaper dimensions are $($image.Width)x$($image.Height)"
      } finally { $image.Dispose() }
      $generatedFiles += Get-LemRelativePath -BasePath $TestRoot -Path $wallpaperPath
      if ([bool]$day.postArtifactInput) {
        $postGenerationAttempt = Invoke-LemArtifactMutationAttempt -Day $day -LockPath $artifactLockPath -HtmlPath $htmlPath -WallpaperPath $wallpaperPath -SurfaceRoot $surfaceRoot -Stage 'post_generation_input'
      }

      Assert-LemSimulationCondition ([string]$plan.planRevisionId -eq [string]$wallpaperConfig.planRevisionId) `
        "Day $($day.dayIndex): plan and wallpaper revision mismatch"
      if (@($plan.goalAlerts).Count -gt 0) {
        $primary = @($plan.goalAlerts)[0]
        Assert-LemSimulationCondition ([string]$primary.goalId -eq [string]$wallpaperConfig.goalAlert.goalId) `
          "Day $($day.dayIndex): plan and wallpaper Goal ID mismatch"
        Assert-LemSimulationCondition ([string]$primary.level -eq [string]$wallpaperConfig.goalAlert.goalLevel) `
          "Day $($day.dayIndex): plan and wallpaper goal level mismatch"
        Assert-LemSimulationCondition ([string]$primary.deadline -eq [string]$wallpaperConfig.goalAlert.deadline) `
          "Day $($day.dayIndex): plan and wallpaper deadline mismatch"
        Assert-LemSimulationCondition ([string]$primary.proximity -eq [string]$wallpaperConfig.goalAlert.level) `
          "Day $($day.dayIndex): plan and wallpaper risk mismatch"
        Assert-LemSimulationCondition ([string]$primary.requiredToday -eq [string]$wallpaperConfig.goalAlert.requiredToday) `
          "Day $($day.dayIndex): plan and wallpaper required action mismatch"
      } else {
        Assert-LemSimulationCondition (-not ($wallpaperConfig.PSObject.Properties.Name -contains 'goalAlert')) `
          "Day $($day.dayIndex): wallpaper emitted an alert that is absent from the plan"
      }
    }

    $artifactEvidence = Get-LemArtifactEvidence -Day $day -DayDirectory $dayDirectory -HtmlPath $htmlPath -WallpaperPath $wallpaperPath -LockPath $artifactLockPath -MidGenerationAttempt $midGenerationAttempt -PostGenerationAttempt $postGenerationAttempt
    $blindEvidence = New-LemSimulatedBlindEvidence -Day $day
    $blindEvidencePath = Join-Path $dayDirectory 'scoring-blind.json'
    Write-LemSimulationText -Path $blindEvidencePath -Content (ConvertTo-LemSimulationJson -Value $blindEvidence)
    $blindHashBeforeSelf = Get-LemFileHashOrAbsent -Path $blindEvidencePath
    $selfScoringDefinition = Get-Content -LiteralPath $SelfScoringScenarioPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-LemSimulationCondition ([string]$selfScoringDefinition.model -eq 'simulated-user-self-scores' -and @($selfScoringDefinition.days).Count -eq 14) `
      'Self-score fixture must use the simulated-user model and contain 14 days'
    $selfMatches = @($selfScoringDefinition.days | Where-Object { [int]$_.dayIndex -eq [int]$day.dayIndex })
    Assert-LemSimulationCondition ($selfMatches.Count -eq 1) "Day $($day.dayIndex): expected exactly one self-score fixture"
    $scoringEvidence = Complete-LemSimulatedScoringEvidence -Day $day -BlindEvidence $blindEvidence -BlindResultHash $blindHashBeforeSelf -SelfScore $selfMatches[0] -PriorScoreHistory @($currentState.scoreHistory)
    Assert-LemSimulationCondition ((Get-LemFileHashOrAbsent -Path $blindEvidencePath) -eq $blindHashBeforeSelf) `
      "Day $($day.dayIndex): persisted blind result changed after self-score load or calibration"
    $transition = New-LemSimulationStateTransition -Day $day -PriorState $currentState -Transaction $transaction -ArtifactEvidence $artifactEvidence -ConfirmationState $confirmationState -ScoringEvidence $scoringEvidence
    $beforeState = $transition.before
    $afterState = $transition.after
    $beforeStatePath = Join-Path $dayDirectory 'state-before.json'
    $afterStatePath = Join-Path $dayDirectory 'state-after.json'
    $transactionPath = Join-Path $dayDirectory 'transaction.json'
    $artifactEvidencePath = Join-Path $dayDirectory 'artifact-evidence.json'
    $scoringEvidencePath = Join-Path $dayDirectory 'scoring-evidence.json'
    Write-LemSimulationText -Path $beforeStatePath -Content (ConvertTo-LemSimulationJson -Value $beforeState)
    Write-LemSimulationText -Path $afterStatePath -Content (ConvertTo-LemSimulationJson -Value $afterState)
    Write-LemSimulationText -Path $transactionPath -Content (ConvertTo-LemSimulationJson -Value $transaction)
    Write-LemSimulationText -Path $artifactEvidencePath -Content (ConvertTo-LemSimulationJson -Value $artifactEvidence)
    Write-LemSimulationText -Path $scoringEvidencePath -Content (ConvertTo-LemSimulationJson -Value $scoringEvidence)
    $generatedFiles += Get-LemRelativePath -BasePath $TestRoot -Path $beforeStatePath
    $generatedFiles += Get-LemRelativePath -BasePath $TestRoot -Path $afterStatePath
    $generatedFiles += Get-LemRelativePath -BasePath $TestRoot -Path $transactionPath
    $generatedFiles += Get-LemRelativePath -BasePath $TestRoot -Path $artifactEvidencePath
    $generatedFiles += Get-LemRelativePath -BasePath $TestRoot -Path $blindEvidencePath
    $generatedFiles += Get-LemRelativePath -BasePath $TestRoot -Path $scoringEvidencePath
    $checks = @(Invoke-LemScenarioOracle -Day $day -BeforeState $beforeState -AfterState $afterState -Plan $plan -WallpaperConfig $wallpaperConfig -ScoringEvidence $scoringEvidence)

    $dayResult = [ordered]@{
      dayIndex = [int]$day.dayIndex
      date = [string]$day.date
      dayLabel = [string]$day.dayLabel
      scenario = [string]$day.scenario
      workflow = [string]$day.workflow
      revisionKind = [string]$day.revisionKind
      correctionState = [string]$day.correctionState
      confirmationsRequired = [int]$day.confirmationsRequired
      actualConfirmationCount = [int]$transition.confirmation.actualConfirmationCount
      guardStatus = [string]$day.guardStatus
      proposalGuardStatus = [string]$day.proposalGuardStatus
      feasibility = [string]$day.feasibility
      confidence = [string]$day.confidence
      comparableDaysBefore = [int]$day.comparableDaysBefore
      revisionBefore = [string]$day.revisionBefore
      revisionAfter = [string]$day.revisionAfter
      terminalOutcome = $day.terminalOutcome
      artifactExpected = [bool]$day.artifactExpected
      postArtifactInput = [bool]$day.postArtifactInput
      unplannedMinutes = [int]$day.unplannedMinutes
      scoring = $scoringEvidence
      planFocusMode = $(if ($plan) { [string]$plan.focusMode } else { $null })
      planFocusTargetMinutes = $(if ($plan) { [int]$plan.focusTargetMinutes } else { $null })
      scoreFeedbackApplied = $(if ($plan) { [bool]$plan.scoringInput.applied } else { $false })
      scoreObservationDate = $(if ($plan) { $plan.scoringInput.observationDate } else { $null })
      scorePredictionTargetDate = $(if ($plan) { $plan.scoringInput.predictionTargetDate } else { $null })
      generatedFiles = $generatedFiles
      checks = $checks
      status = 'pass'
    }
    $dayResultPath = Join-Path $dayDirectory 'result.json'
    Write-LemSimulationText -Path $dayResultPath -Content (ConvertTo-LemSimulationJson -Value $dayResult)
    Write-LemSimulationText -Path (Join-Path $dayDirectory 'day-report.md') -Content (New-LemDayReportMarkdown -Day $day -DayResult $dayResult)
    $dayResults += $dayResult
    $currentState = $afterState
  }

  $nodeOutput = & node $NodeVerifierPath $normalizedResultsRoot 2>&1
  Assert-LemSimulationCondition ($LASTEXITCODE -eq 0) "Node workbench verification failed: $($nodeOutput -join ' ')"
  $nodeVerification = ($nodeOutput -join "`n") | ConvertFrom-Json
  Assert-LemSimulationCondition ([int]$nodeVerification.totalDays -eq 14) 'Node verifier did not inspect all 14 days'
  Assert-LemSimulationCondition ([int]$nodeVerification.scoredDays -eq 10) 'Node verifier did not exercise all ten evening self-score forms'

  $outputsAfter = Get-LemDirectoryFingerprint -Path $RepositoryOutputsPath
  Assert-LemSimulationCondition ($outputsBefore -eq $outputsAfter) 'The real outputs directory changed during the isolated test'
  $runResult = [ordered]@{
    simulationName = [string]$definition.simulationName
    startDate = [string]$definition.startDate
    endDate = [string]$definition.days[-1].date
    timezone = [string]$definition.timezone
    status = 'pass'
    outputsFingerprintBefore = $outputsBefore
    outputsFingerprintAfter = $outputsAfter
    nodeVerification = $nodeVerification
    selfTests = [ordered]@{
      unlockedArtifactMutation = $artifactMutationSelfTest
      confirmationNegativeCases = 'pass'
      hardDeadlineAuthoritySpoof = 'pass'
      weightedMedianRecentSeven = 'pass'
    }
    days = $dayResults
  }
  $runResultPath = Join-Path $normalizedResultsRoot 'RESULTS.json'
  Write-LemSimulationText -Path $runResultPath -Content (ConvertTo-LemSimulationJson -Value $runResult)
  $runSummaryPath = Join-Path $normalizedResultsRoot 'SUMMARY.md'
  $canonicalSummaryPath = $runSummaryPath
  if ($UpdateCanonicalEvidence) {
    Write-LemSimulationText -Path (Join-Path $TestRoot 'RESULTS.json') -Content (ConvertTo-LemSimulationJson -Value $runResult)
    $canonicalSummaryPath = Join-Path $TestRoot 'SUMMARY.md'
  }
  $summaryOutput = & node $SummaryBuilderPath $runResultPath $runSummaryPath $canonicalSummaryPath 2>&1
  Assert-LemSimulationCondition ($LASTEXITCODE -eq 0) "Summary generation failed: $($summaryOutput -join ' ')"
  return $runResult
}

Export-ModuleMember -Function Invoke-LemFourteenDaySimulation
