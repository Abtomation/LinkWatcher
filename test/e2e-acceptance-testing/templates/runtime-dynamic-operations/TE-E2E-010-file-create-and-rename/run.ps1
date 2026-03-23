# run.ps1 — Scripted action for TE-E2E-010 (file create and rename)
# Creates docs/report.md, waits for LinkWatcher to scan it, then renames it to docs/summary.md.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-010" -Group "runtime-dynamic-operations"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"

# Step 1: Create the target file
$docsDir = Join-Path $projectPath "docs"
New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
$reportContent = "# Report`n`nThis is the report.`n"
Set-Content (Join-Path $docsDir "report.md") $reportContent -Encoding UTF8

# Step 2: Wait for LinkWatcher to detect and index the new file
Start-Sleep -Seconds 5

# Step 3: Rename the file in place (same directory, different name)
Rename-Item -Path (Join-Path $docsDir "report.md") -NewName "summary.md"
