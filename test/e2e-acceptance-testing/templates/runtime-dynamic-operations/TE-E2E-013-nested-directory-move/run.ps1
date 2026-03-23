# run.ps1 — Scripted action for TE-E2E-013 (nested directory move)
# Creates modules/ directory with nested subdirectories core/ and plugins/,
# waits for LinkWatcher to scan, then moves the entire directory to lib/.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-013" -Group "runtime-dynamic-operations"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"

# Step 1: Create the nested directory structure with files
$coreDir = Join-Path $projectPath "modules" "core"
$pluginsDir = Join-Path $projectPath "modules" "plugins"
New-Item -ItemType Directory -Path $coreDir -Force | Out-Null
New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null

$engineContent = "# engine.py — core processing logic`n`ndef process(data):`n    return data.strip().upper()`n"
Set-Content (Join-Path $coreDir "engine.py") $engineContent -Encoding UTF8

$configContent = "project:`n  name: test-project`n  version: 2.0`n  debug: false`n"
Set-Content (Join-Path $coreDir "config.yaml") $configContent -Encoding UTF8

$authContent = "# auth.py — authentication plugin`n`ndef authenticate(user, password):`n    return user == `"admin`"`n"
Set-Content (Join-Path $pluginsDir "auth.py") $authContent -Encoding UTF8

# Step 2: Wait for LinkWatcher to detect and index the new files
Start-Sleep -Seconds 5

# Step 3: Move the entire modules/ directory to lib/
$modulesDir = Join-Path $projectPath "modules"
$libDir = Join-Path $projectPath "lib"
Move-Item -Path $modulesDir -Destination $libDir
