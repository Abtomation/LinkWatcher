# run.ps1 — Scripted action for TE-E2E-012 (file operations during startup)
# Stops LinkWatcher, creates a new file with references, restarts LinkWatcher,
# then immediately moves a referenced file to test startup race condition handling.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-012" -Group "startup-operations"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"

# Step 1: Find the project root by navigating up to .git
# Uses .git instead of .linkwatcher.lock because the orchestrator creates
# a workspace-scoped .linkwatcher.lock that would be found first (PD-BUG-047).
$searchDir = (Resolve-Path $WorkspacePath).Path
while ($searchDir -and -not (Test-Path (Join-Path $searchDir ".git"))) {
    $searchDir = Split-Path -Parent $searchDir
}
if (-not $searchDir) {
    throw "Could not find project root (.git) from $WorkspacePath"
}
$projectRoot = $searchDir

# Step 2: Stop any running LinkWatcher (workspace-scoped or project-scoped)
$lockFiles = @(
    (Join-Path $WorkspacePath ".linkwatcher.lock"),
    (Join-Path $projectRoot ".linkwatcher.lock")
)
foreach ($lockFile in $lockFiles) {
    if (Test-Path $lockFile) {
        try {
            $lwPid = [int](Get-Content $lockFile -Raw).Trim()
            $lwProc = Get-Process -Id $lwPid -ErrorAction SilentlyContinue
            if ($lwProc) {
                Stop-Process -Id $lwPid -Force
                Start-Sleep -Milliseconds 500
                Write-Host "Stopped LinkWatcher (PID: $lwPid)"
            }
        } catch {
            Write-Host "Warning: Could not read lock file $lockFile" -ForegroundColor Yellow
        }
        Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
    }
}

# Step 3: Create a new markdown file that references the existing settings/config.yaml
$docsDir = Join-Path $projectPath "docs"
New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
$guideContent = "# Guide`n`nSee [Config](../settings/config.yaml) for settings.`n"
Set-Content (Join-Path $docsDir "guide.md") $guideContent -Encoding UTF8

# Step 4: Restart LinkWatcher scoped to project/ subdirectory
# Start LW directly with python main.py (not start_linkwatcher_background.ps1,
# which ignores -ProjectRoot and always uses project-config.json root — PD-BUG-053).
# Scope to $projectPath (not $WorkspacePath) to avoid scanning expected/ directory.
$mainPy = Join-Path $projectRoot "main.py"
$logFile = Join-Path $WorkspacePath "linkwatcher-e2e.log"
$lwArgs = "`"$mainPy`" --project-root `"$projectPath`" --log-file `"$logFile`" --debug"
$lwProcess = Start-Process -FilePath "python" -ArgumentList $lwArgs -WorkingDirectory $projectPath -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $WorkspacePath "lw-stdout.txt") -RedirectStandardError (Join-Path $WorkspacePath "lw-stderr.txt")
Write-Host "Started LinkWatcher scoped to project (PID: $($lwProcess.Id))"

# Step 5: Wait for LW to start scanning before moving the file.
# Start-Process has higher startup latency than bash background processes.
# Poll the log file for scan_starting to confirm the observer is active
# and the scan is in progress before triggering the move (PD-BUG-053).
$maxWait = 15
$elapsed = 0
while ($elapsed -lt $maxWait) {
    Start-Sleep -Seconds 1
    $elapsed++
    if (Test-Path $logFile) {
        $logContent = Get-Content $logFile -Tail 20 -ErrorAction SilentlyContinue
        if ($logContent -match 'initial_scan_starting|scan_progress') {
            Write-Host "LW scan started after ${elapsed}s — moving file now"
            break
        }
    }
}
if ($elapsed -ge $maxWait) {
    Write-Host "Warning: scan start not detected after ${maxWait}s — moving file anyway" -ForegroundColor Yellow
}

# Step 6: Move the target file while LW is still starting/scanning
$sourceFile = Join-Path $projectPath "settings/config.yaml"
$destDir = Join-Path $projectPath "config"
New-Item -ItemType Directory -Path $destDir -Force | Out-Null
Move-Item -Path $sourceFile -Destination (Join-Path $destDir "config.yaml")
