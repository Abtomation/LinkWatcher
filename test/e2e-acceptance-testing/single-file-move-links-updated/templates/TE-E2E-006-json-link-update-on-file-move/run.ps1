# run.ps1 — Scripted action for TE-E2E-006 (JSON link update on file move)
# Moves src/utils.js to moved/utils.js to trigger JSON reference updates.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-006" -Workflow "single-file-move-links-updated"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# LinkWatcher lifecycle is owned by this run.ps1 (Run-E2EAcceptanceTest.ps1 v2.0 is project-agnostic).
. (Join-Path $PSScriptRoot "../../../_lib/lw-e2e-helpers.ps1")

$lw = Start-WorkspaceLinkWatcher -WorkspacePath $WorkspacePath
try {
    $projectPath = Join-Path $WorkspacePath "project"
    $movedDir = Join-Path $projectPath "moved"
    $source = Join-Path $projectPath "src/utils.js"
    $destination = Join-Path $movedDir "utils.js"

    New-Item -ItemType Directory -Path $movedDir -Force | Out-Null
    Move-Item -Path $source -Destination $destination

    # Allow LinkWatcher to detect the change and update references before verification.
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
