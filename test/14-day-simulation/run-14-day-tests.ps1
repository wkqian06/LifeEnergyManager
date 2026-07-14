param(
  [string]$RunId = ('run-' + (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')),
  [switch]$UpdateCanonicalEvidence
)

$ErrorActionPreference = 'Stop'
$testRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $testRoot)

Import-Module (Join-Path $repositoryRoot 'templates\wallpaper_renderer.psm1') -Force
Import-Module (Join-Path $testRoot 'simulation_helpers.psm1') -Force

$result = Invoke-LemFourteenDaySimulation `
  -ScenarioPath (Join-Path $testRoot 'scenarios.json') `
  -BlindScoringScenarioPath (Join-Path $testRoot 'blind-scoring-scenarios.json') `
  -SelfScoringScenarioPath (Join-Path $testRoot 'self-scoring-scenarios.json') `
  -TemplatePath (Join-Path $repositoryRoot 'templates\daily_workbench_template.html') `
  -TestRoot $testRoot `
  -ResultsRoot (Join-Path $testRoot "results\$RunId") `
  -RepositoryOutputsPath (Join-Path $repositoryRoot 'outputs') `
  -NodeVerifierPath (Join-Path $testRoot 'verify-generated-workbenches.js') `
  -SummaryBuilderPath (Join-Path $testRoot 'build-summary-zh.js') `
  -OracleModulePath (Join-Path $testRoot 'simulation_oracles.psm1') `
  -UpdateCanonicalEvidence:$UpdateCanonicalEvidence

$artifactDays = @($result.days | Where-Object artifactExpected).Count
Write-Output "PASS: 14/14 days; $artifactDays artifact days; summary: $(Join-Path $testRoot "results\$RunId\SUMMARY.md")"
