# run.ps1 — Scripted action for TE-E2E-033 (directory move virtual root links)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-033" -Workflow "override-folder-move-virtual-root-links-updated"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# LinkWatcher lifecycle is owned by this run.ps1 (Run-E2EAcceptanceTest.ps1 v2.0 is project-agnostic).
. (Join-Path $PSScriptRoot "../../../_lib/lw-e2e-helpers.ps1")

$lw = Start-WorkspaceLinkWatcher -WorkspacePath $WorkspacePath -ExtraArgs @('--config', (Join-Path $WorkspacePath 'project/config.yaml'))
try {
    # Rename a directory inside the override folder (restructure case).
    # blueprint/index.md's virtual-root links /doc/guide.md and /doc/data/reference.md
    # should be rewritten to /doc-renamed/...; outside-note.md must stay untouched.
    Move-Item "$WorkspacePath/project/blueprint/doc" "$WorkspacePath/project/blueprint/doc-renamed"

    # Allow LinkWatcher's directory-move detector to correlate the per-file
    # delete+create events and update references before verification.
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
