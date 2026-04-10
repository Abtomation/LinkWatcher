# run.ps1 — Scripted action for TE-E2E-003 (PowerShell script file move)
# Moves move-target-2.ps1 into a moved/ subdirectory to trigger PowerShell parser
# reference updates across 11 occurrences.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-003" -Group "powershell-parser-patterns"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"
$movedDir = Join-Path $projectPath "moved"
$source = Join-Path $projectPath "move-target-2.ps1"
$destination = Join-Path $movedDir "move-target-2.ps1"

New-Item -ItemType Directory -Path $movedDir -Force | Out-Null
Move-Item -Path $source -Destination $destination
