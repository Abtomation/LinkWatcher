# run.ps1 — Scripted action for TE-E2E-020 (stop during idle)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-020" -Group "graceful-shutdown"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# No file operations — this test verifies clean shutdown from idle state.
# Wait for LinkWatcher to settle into idle (initial scan complete, no pending events).
# The stop signal is sent by the test orchestrator after this script returns.
Start-Sleep -Seconds 5
