# run.ps1 — Scripted action for TE-E2E-005 (YAML link update on file move)
# Moves data/settings.conf to moved/settings.conf to trigger YAML reference updates.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-005" -Workflow "single-file-move-links-updated"

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
    $source = Join-Path $projectPath "data/settings.conf"
    $destination = Join-Path $movedDir "settings.conf"

    New-Item -ItemType Directory -Path $movedDir -Force | Out-Null
    Move-Item -Path $source -Destination $destination

    # Allow LinkWatcher to detect the change and update references before verification.
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
