# run.ps1 — Scripted action for TE-E2E-015 (startup custom config excludes)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-015" -Group "startup-operations"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# Create the archive directory
New-Item -ItemType Directory -Path "$WorkspacePath/project/archive" -Force | Out-Null

# Move guide.md from docs/ to archive/
Move-Item "$WorkspacePath/project/docs/guide.md" "$WorkspacePath/project/archive/guide.md"
