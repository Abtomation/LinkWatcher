# run.ps1 — Scripted action for TE-E2E-014 (directory move internal refs)
# Creates components/ directory with index.md, overview.md, and utils.md
# (containing internal sibling references), waits for LinkWatcher to scan,
# then moves the directory to modules/.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-014" -Group "runtime-dynamic-operations"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"

# Step 1: Create the directory with internally-referencing files
$componentsDir = Join-Path $projectPath "components"
New-Item -ItemType Directory -Path $componentsDir -Force | Out-Null

$indexContent = "# Component Index`n`n[Overview](overview.md) provides a high-level summary.`n`n[Utils](utils.md) contains shared utilities.`n"
Set-Content (Join-Path $componentsDir "index.md") $indexContent -Encoding UTF8

$overviewContent = "# Component Overview`n`n[Back to Index](index.md) for the full component list.`n`nThis document describes the component architecture.`n"
Set-Content (Join-Path $componentsDir "overview.md") $overviewContent -Encoding UTF8

$utilsContent = "# Shared Utilities`n`nCommon helper functions used across components.`n"
Set-Content (Join-Path $componentsDir "utils.md") $utilsContent -Encoding UTF8

# Step 2: Wait for LinkWatcher to detect and index the new files
Start-Sleep -Seconds 5

# Step 3: Move the directory from components/ to modules/
$modulesDir = Join-Path $projectPath "modules"
Move-Item -Path $componentsDir -Destination $modulesDir
