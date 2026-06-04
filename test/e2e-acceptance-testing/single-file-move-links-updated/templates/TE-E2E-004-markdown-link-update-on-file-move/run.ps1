# run.ps1 — Scripted action for TE-E2E-004 (Markdown link update on file move)
# Moves test_project/docs/readme.md to test_project/archive/readme.md to trigger
# markdown reference updates across MP-001, LR-001, and other referencing files.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-004" -Workflow "single-file-move-links-updated"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# LinkWatcher lifecycle is owned by this run.ps1 (Run-E2EAcceptanceTest.ps1 v2.0 is project-agnostic).
. (Join-Path $PSScriptRoot "../../../_lib/lw-e2e-helpers.ps1")

$lw = Start-WorkspaceLinkWatcher -WorkspacePath $WorkspacePath
try {
    $projectPath = Join-Path $WorkspacePath "project"
    $archiveDir = Join-Path $projectPath "test_project/archive"
    $source = Join-Path $projectPath "test_project/docs/readme.md"
    $destination = Join-Path $archiveDir "readme.md"

    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    Move-Item -Path $source -Destination $destination

    # Allow LinkWatcher to detect the move and update references before verification.
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
