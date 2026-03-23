# run.ps1 — Scripted action for TE-E2E-011 (directory create and rename)
# Creates utils/ directory with helper.py and config.yaml, waits for LinkWatcher to scan,
# then renames the directory to tools/.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-011" -Group "runtime-dynamic-operations"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"

# Step 1: Create the target directory with files
$utilsDir = Join-Path $projectPath "utils"
New-Item -ItemType Directory -Path $utilsDir -Force | Out-Null

$helperContent = "# helper.py — utility functions`n`ndef greet(name):`n    return f`"Hello, {name}!`"`n"
Set-Content (Join-Path $utilsDir "helper.py") $helperContent -Encoding UTF8

$configContent = "project:`n  name: test-project`n  version: 1.0`n"
Set-Content (Join-Path $utilsDir "config.yaml") $configContent -Encoding UTF8

# Step 2: Wait for LinkWatcher to detect and index the new files
Start-Sleep -Seconds 5

# Step 3: Rename the directory in place (same parent, different name)
Rename-Item -Path $utilsDir -NewName "tools"
