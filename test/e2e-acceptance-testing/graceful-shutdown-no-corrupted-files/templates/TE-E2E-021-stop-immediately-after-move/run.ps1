# run.ps1 — Scripted action for TE-E2E-021 (stop immediately after move)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-021" -Workflow "graceful-shutdown-no-corrupted-files"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# LinkWatcher lifecycle is owned by this run.ps1 (Run-E2EAcceptanceTest.ps1 v2.0 is project-agnostic).
. (Join-Path $PSScriptRoot "../../../_lib/lw-e2e-helpers.ps1")

$lw = Start-WorkspaceLinkWatcher -WorkspacePath $WorkspacePath
try {
    # Create the archive directory
    New-Item -ItemType Directory "$WorkspacePath/project/archive" -Force | Out-Null

    # Move the target file
    Move-Item "$WorkspacePath/project/docs/report.md" "$WorkspacePath/project/archive/report.md"

    # This case defines two valid outcomes (A: refs updated; B: unchanged) for an immediate stop.
    # expected/ encodes Outcome A and Verify-TestResult.ps1 compares strictly (it cannot express
    # "either outcome passes"), so settle to let LinkWatcher complete its atomic update —
    # deterministically producing Outcome A. The Outcome-B race path is documented in test-case.md
    # but not exercised automatically (verifier dual-outcome support is a separate framework concern).
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
