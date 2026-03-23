# run.ps1 — Scripted action for TE-E2E-006 (JSON link update on file move)
# Moves src/utils.js to moved/utils.js to trigger JSON reference updates.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-006" -Group "yaml-json-python-parser-scenarios"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"
$movedDir = Join-Path $projectPath "moved"
$source = Join-Path $projectPath "src/utils.js"
$destination = Join-Path $movedDir "utils.js"

New-Item -ItemType Directory -Path $movedDir -Force | Out-Null
Move-Item -Path $source -Destination $destination
