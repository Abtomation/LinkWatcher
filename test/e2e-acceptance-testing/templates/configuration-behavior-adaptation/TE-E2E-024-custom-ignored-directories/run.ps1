# run.ps1 — Scripted action for TE-E2E-024 (custom ignored directories)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-024" -Group "configuration-behavior-adaptation"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# Create destination directory
New-Item -ItemType Directory "$WorkspacePath/project/moved" -Force | Out-Null

# Move the target file — LinkWatcher should update refs in docs/readme.md
# but NOT in archive/index.md (because archive/ is in ignored_directories)
Move-Item "$WorkspacePath/project/docs/api-guide.md" "$WorkspacePath/project/moved/api-guide.md"
