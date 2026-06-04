# run.ps1 — Scripted action for TE-E2E-001 (Regex preserved on file move)
# Moves scripts/update/Update-Tracking.ps1 into a sub/ subdirectory to trigger
# relative path updates while preserving regex patterns unchanged.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-001" -Workflow "single-file-move-links-updated"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# LinkWatcher lifecycle is owned by this run.ps1 (Run-E2EAcceptanceTest.ps1 v2.0 is project-agnostic).
. (Join-Path $PSScriptRoot "../../../_lib/lw-e2e-helpers.ps1")

$lw = Start-WorkspaceLinkWatcher -WorkspacePath $WorkspacePath
try {
    $projectPath = Join-Path $WorkspacePath "project"
    $subDir = Join-Path $projectPath "scripts/update/sub"
    $source = Join-Path $projectPath "scripts/update/Update-Tracking.ps1"
    $destination = Join-Path $subDir "Update-Tracking.ps1"

    New-Item -ItemType Directory -Path $subDir -Force | Out-Null
    Move-Item -Path $source -Destination $destination

    # Allow LinkWatcher to detect the change and update references before verification.
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
