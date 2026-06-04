# run.ps1 — Scripted action for TE-E2E-007 (Python import update on file move)
# Moves utils/helpers.py to core/helpers.py to trigger Python import and path reference updates.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-007" -Workflow "single-file-move-links-updated"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# LinkWatcher lifecycle is owned by this run.ps1 (Run-E2EAcceptanceTest.ps1 v2.0 is project-agnostic).
. (Join-Path $PSScriptRoot "../../../_lib/lw-e2e-helpers.ps1")

$lw = Start-WorkspaceLinkWatcher -WorkspacePath $WorkspacePath
try {
    $projectPath = Join-Path $WorkspacePath "project"
    $coreDir = Join-Path $projectPath "core"
    $source = Join-Path $projectPath "utils/helpers.py"
    $destination = Join-Path $coreDir "helpers.py"

    New-Item -ItemType Directory -Path $coreDir -Force | Out-Null
    Move-Item -Path $source -Destination $destination

    # Allow LinkWatcher to detect the change and update references before verification.
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
