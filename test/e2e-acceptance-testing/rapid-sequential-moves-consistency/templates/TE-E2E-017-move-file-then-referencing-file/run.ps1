# run.ps1 — Scripted action for TE-E2E-017 (move file then referencing file)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-017" -Workflow "rapid-sequential-moves-consistency"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# LinkWatcher lifecycle is owned by this run.ps1 (Run-E2EAcceptanceTest.ps1 v2.0 is project-agnostic).
. (Join-Path $PSScriptRoot "../../../_lib/lw-e2e-helpers.ps1")

$lw = Start-WorkspaceLinkWatcher -WorkspacePath $WorkspacePath
try {
    # Step 1: Move the referenced file (settings.md) to archive/
    New-Item -ItemType Directory -Path "$WorkspacePath/project/archive" -Force | Out-Null
    Move-Item "$WorkspacePath/project/config/settings.md" "$WorkspacePath/project/archive/settings.md"

    # Brief delay to simulate rapid but not simultaneous moves
    Start-Sleep -Milliseconds 500

    # Step 2: Move the referencing file (readme.md) to guides/
    New-Item -ItemType Directory -Path "$WorkspacePath/project/guides" -Force | Out-Null
    Move-Item "$WorkspacePath/project/docs/readme.md" "$WorkspacePath/project/guides/readme.md"

    # Allow LinkWatcher to detect the change and update references before verification.
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
