# run.ps1 — Scripted action for TE-E2E-016 (two files moved rapidly)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-016" -Workflow "rapid-sequential-moves-consistency"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# LinkWatcher lifecycle is owned by this run.ps1 (Run-E2EAcceptanceTest.ps1 v2.0 is project-agnostic).
. (Join-Path $PSScriptRoot "../../../_lib/lw-e2e-helpers.ps1")

$lw = Start-WorkspaceLinkWatcher -WorkspacePath $WorkspacePath
try {
    # Create the destination directory
    New-Item -ItemType Directory -Path "$WorkspacePath/project/src" -Force | Out-Null

    # Move both files rapidly with only 200ms gap
    Move-Item "$WorkspacePath/project/lib/utils.md" "$WorkspacePath/project/src/utils.md"
    Start-Sleep -Milliseconds 200
    Move-Item "$WorkspacePath/project/lib/helpers.md" "$WorkspacePath/project/src/helpers.md"

    # Allow LinkWatcher to detect the change and update references before verification.
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
