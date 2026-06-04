# run.ps1 — Scripted action for TE-E2E-022 (read only referencing file)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-022" -Workflow "graceful-shutdown-no-corrupted-files"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# LinkWatcher lifecycle is owned by this run.ps1 (Run-E2EAcceptanceTest.ps1 v2.0 is project-agnostic).
. (Join-Path $PSScriptRoot "../../../_lib/lw-e2e-helpers.ps1")

$lw = Start-WorkspaceLinkWatcher -WorkspacePath $WorkspacePath
try {
    # Make readme.md read-only BEFORE the move so LinkWatcher cannot write to it
    Set-ItemProperty "$WorkspacePath/project/docs/readme.md" -Name IsReadOnly -Value $true

    # Create the reference directory
    New-Item -ItemType Directory "$WorkspacePath/project/reference" -Force | Out-Null

    # Move the target file — LinkWatcher should update guide.md but fail on readme.md
    Move-Item "$WorkspacePath/project/data/schema.md" "$WorkspacePath/project/reference/schema.md"

    # Allow LinkWatcher to detect the change and update references before verification.
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
