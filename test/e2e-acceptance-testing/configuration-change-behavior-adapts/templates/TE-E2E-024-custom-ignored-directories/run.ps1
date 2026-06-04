# run.ps1 — Scripted action for TE-E2E-024 (custom ignored directories)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-024" -Workflow "configuration-change-behavior-adapts"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# LinkWatcher lifecycle is owned by this run.ps1 (Run-E2EAcceptanceTest.ps1 v2.0 is project-agnostic).
. (Join-Path $PSScriptRoot "../../../_lib/lw-e2e-helpers.ps1")

$lw = Start-WorkspaceLinkWatcher -WorkspacePath $WorkspacePath -ExtraArgs @('--config', (Join-Path $WorkspacePath 'project/config.yaml'))
try {
    # Create destination directory
    New-Item -ItemType Directory "$WorkspacePath/project/moved" -Force | Out-Null

    # Move the target file — LinkWatcher should update refs in docs/readme.md
    # but NOT in archive/index.md (because archive/ is in ignored_directories)
    Move-Item "$WorkspacePath/project/docs/api-guide.md" "$WorkspacePath/project/moved/api-guide.md"

    # Allow LinkWatcher to detect the change and update references before verification.
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
