# run.ps1 — Scripted action for TE-E2E-019 (move file dry run no changes)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-019" -Group "dry-run-mode"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# Create the archive directory
New-Item -ItemType Directory "$WorkspacePath/project/archive" -Force | Out-Null

# Move the target file — this is a real OS operation; LinkWatcher should
# detect it but NOT update links because it is running in --dry-run mode
Move-Item "$WorkspacePath/project/docs/api-guide.md" "$WorkspacePath/project/archive/api-guide.md"
