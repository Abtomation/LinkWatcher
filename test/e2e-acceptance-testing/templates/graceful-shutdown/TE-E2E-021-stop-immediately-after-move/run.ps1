# run.ps1 — Scripted action for TE-E2E-021 (stop immediately after move)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-021" -Group "graceful-shutdown"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# Create the archive directory
New-Item -ItemType Directory "$WorkspacePath/project/archive" -Force | Out-Null

# Move the target file
Move-Item "$WorkspacePath/project/docs/report.md" "$WorkspacePath/project/archive/report.md"

# Brief pause — the test orchestrator should send the stop signal immediately after
Start-Sleep -Milliseconds 100
