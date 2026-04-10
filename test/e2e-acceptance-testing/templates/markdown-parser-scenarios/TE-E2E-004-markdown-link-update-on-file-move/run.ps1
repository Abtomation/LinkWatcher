# run.ps1 — Scripted action for TE-E2E-004 (Markdown link update on file move)
# Moves test_project/docs/readme.md to test_project/archive/readme.md to trigger
# markdown reference updates across MP-001, LR-001, and other referencing files.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-004" -Group "markdown-parser-scenarios"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"
$archiveDir = Join-Path $projectPath "test_project/archive"
$source = Join-Path $projectPath "test_project/docs/readme.md"
$destination = Join-Path $archiveDir "readme.md"

New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
Move-Item -Path $source -Destination $destination
