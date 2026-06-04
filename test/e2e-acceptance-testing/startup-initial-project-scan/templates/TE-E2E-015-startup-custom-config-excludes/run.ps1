# run.ps1 — Scripted action for TE-E2E-015 (startup custom config excludes)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-015" -Workflow "startup-initial-project-scan"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# LinkWatcher lifecycle is owned by this run.ps1 (Run-E2EAcceptanceTest.ps1 v2.0 is project-agnostic).
. (Join-Path $PSScriptRoot "../../../_lib/lw-e2e-helpers.ps1")

$lw = Start-WorkspaceLinkWatcher -WorkspacePath $WorkspacePath -ExtraArgs @('--config', (Join-Path $WorkspacePath 'project/config.yaml'))
try {
    # Create the archive directory
    New-Item -ItemType Directory -Path "$WorkspacePath/project/archive" -Force | Out-Null

    # Move guide.md from docs/ to archive/
    Move-Item "$WorkspacePath/project/docs/guide.md" "$WorkspacePath/project/archive/guide.md"

    # Allow LinkWatcher to detect the change and update references before verification.
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
