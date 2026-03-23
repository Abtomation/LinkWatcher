# run.ps1 — Scripted action for TE-E2E-008 (file create and move)
# Creates docs/report.md, waits for LinkWatcher to scan it, then moves it to archive/report.md.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-008" -Group "runtime-dynamic-operations"

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

# Step 3: Move the file to archive/
$archiveDir = Join-Path $projectPath "archive"
New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
Move-Item -Path (Join-Path $docsDir "report.md") -Destination (Join-Path $archiveDir "report.md")
