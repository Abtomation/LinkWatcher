# run.ps1 — Scripted action for TE-E2E-002 (PowerShell markdown file move)
# Moves move-target.md into a moved/ subdirectory to trigger PowerShell parser
# reference updates across 20 occurrences in 10 pattern types.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-002" -Group "powershell-parser-patterns"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"
$movedDir = Join-Path $projectPath "moved"
$source = Join-Path $projectPath "move-target.md"
$destination = Join-Path $movedDir "move-target.md"

New-Item -ItemType Directory -Path $movedDir -Force | Out-Null
Move-Item -Path $source -Destination $destination
