# run.ps1 — Scripted action for TE-E2E-005 (YAML link update on file move)
# Moves data/settings.conf to moved/settings.conf to trigger YAML reference updates.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-005" -Group "yaml-json-python-parser-scenarios"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"
$movedDir = Join-Path $projectPath "moved"
$source = Join-Path $projectPath "data/settings.conf"
$destination = Join-Path $movedDir "settings.conf"

New-Item -ItemType Directory -Path $movedDir -Force | Out-Null
Move-Item -Path $source -Destination $destination
