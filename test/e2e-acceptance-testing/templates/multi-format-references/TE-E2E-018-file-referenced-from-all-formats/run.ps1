# run.ps1 — Scripted action for TE-E2E-018 (file referenced from all formats)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-018" -Group "multi-format-references"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# Create the destination directory
New-Item -ItemType Directory -Path "$WorkspacePath/project/reference" -Force | Out-Null

# Move schema.md from data/ to reference/
Move-Item "$WorkspacePath/project/data/schema.md" "$WorkspacePath/project/reference/schema.md"
