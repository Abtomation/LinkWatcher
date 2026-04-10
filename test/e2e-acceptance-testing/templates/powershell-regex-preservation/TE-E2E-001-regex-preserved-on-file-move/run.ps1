# run.ps1 — Scripted action for TE-E2E-001 (Regex preserved on file move)
# Moves scripts/update/Update-Tracking.ps1 into a sub/ subdirectory to trigger
# relative path updates while preserving regex patterns unchanged.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-001" -Group "powershell-regex-preservation"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"
$subDir = Join-Path $projectPath "scripts/update/sub"
$source = Join-Path $projectPath "scripts/update/Update-Tracking.ps1"
$destination = Join-Path $subDir "Update-Tracking.ps1"

New-Item -ItemType Directory -Path $subDir -Force | Out-Null
Move-Item -Path $source -Destination $destination
