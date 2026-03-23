# run.ps1 — Scripted action for TE-E2E-007 (Python import update on file move)
# Moves utils/helpers.py to core/helpers.py to trigger Python import and path reference updates.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-007" -Group "yaml-json-python-parser-scenarios"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"
$coreDir = Join-Path $projectPath "core"
$source = Join-Path $projectPath "utils/helpers.py"
$destination = Join-Path $coreDir "helpers.py"

New-Item -ItemType Directory -Path $coreDir -Force | Out-Null
Move-Item -Path $source -Destination $destination
