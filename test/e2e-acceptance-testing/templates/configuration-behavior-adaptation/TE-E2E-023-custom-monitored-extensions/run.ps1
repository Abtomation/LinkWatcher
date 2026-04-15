# run.ps1 — Scripted action for TE-E2E-023 (custom monitored extensions)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-023" -Group "configuration-behavior-adaptation"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# Create the archive directory
New-Item -ItemType Directory "$WorkspacePath/project/archive" -Force | Out-Null

# Move the target file — LinkWatcher should update refs in .md files
# but NOT in .yaml files (because .yaml is not in monitored_extensions)
Move-Item "$WorkspacePath/project/docs/api-guide.md" "$WorkspacePath/project/archive/api-guide.md"
