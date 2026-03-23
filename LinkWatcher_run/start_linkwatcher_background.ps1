# LinkWatcher Background Starter for this project
#
# Usage:
#   .\start_linkwatcher_background.ps1                        # Normal: watch project root from project-config.json
#   .\start_linkwatcher_background.ps1 -ProjectRoot "C:\path" # Custom: watch a specific directory (e.g., E2E test workspace)
#   .\start_linkwatcher_background.ps1 -ProjectRoot "C:\path" -DryRun  # Custom + dry-run mode

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = "",

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

if (-not $ProjectRoot) {
    # Resolve project root from project-config.json
    $configPath = Join-Path $scriptDir "..\doc\process-framework\project-config.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "Error: project-config.json not found at: $configPath" -ForegroundColor Red
        return
    }

    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $ProjectRoot = $config.project.root_directory

    if (-not $ProjectRoot -or -not (Test-Path $ProjectRoot)) {
        Write-Host "Error: Invalid project root in project-config.json: $ProjectRoot" -ForegroundColor Red
        return
    }
} elseif (-not (Test-Path $ProjectRoot)) {
    Write-Host "Error: Specified project root does not exist: $ProjectRoot" -ForegroundColor Red
    return
}

$projectRoot = $ProjectRoot

# Check if LinkWatcher is already running for THIS project via lock file
$lockFile = Join-Path $projectRoot ".linkwatcher.lock"
if (Test-Path $lockFile) {
    try {
        $lockPid = [int](Get-Content $lockFile -Raw).Trim()
        $lockProcess = Get-Process -Id $lockPid -ErrorAction SilentlyContinue
        if ($lockProcess) {
            Write-Host "LinkWatcher is already running for $projectRoot (PID: $lockPid)" -ForegroundColor Yellow
            Write-Host "Not starting a new instance." -ForegroundColor Yellow
            return
        } else {
            Write-Host "Stale lock file found (PID $lockPid no longer running), will be overridden." -ForegroundColor DarkYellow
        }
    } catch {
        Write-Host "Invalid lock file, will be overridden." -ForegroundColor DarkYellow
    }
}

$modeLabel = if ($DryRun) { " (dry-run)" } else { "" }
Write-Host "Starting LinkWatcher${modeLabel} in background for $projectRoot..." -ForegroundColor Cyan

# Start LinkWatcher with explicit project root and logging
# Custom roots (e.g., E2E test workspaces) get logs in their own directory
$isCustomRoot = ($PSBoundParameters.ContainsKey('ProjectRoot') -and $PSBoundParameters['ProjectRoot'] -ne "")
if ($isCustomRoot) {
    $logFile = Join-Path $projectRoot "linkwatcher-e2e.log"
    $stdoutLog = Join-Path $projectRoot "lw-stdout.txt"
    $stderrLog = Join-Path $projectRoot "lw-stderr.txt"
} else {
    $logFile = Join-Path $scriptDir "LinkWatcherLog.txt"
    $stdoutLog = Join-Path $scriptDir "LinkWatcherStdout.txt"
    $stderrLog = Join-Path $scriptDir "LinkWatcherError.txt"
}
$arguments = "C:\Users\ronny\bin\main.py --project-root `"$projectRoot`" --log-file `"$logFile`" --debug"
if ($DryRun) {
    $arguments += " --dry-run"
}

$process = Start-Process -FilePath "python" -ArgumentList $arguments -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog

if ($process) {
    # Write PID to lock file immediately so subsequent launches see it
    # (main.py also writes the lock, but there's a race window between
    # Start-Process returning and main.py's acquire_lock running)
    $lockFile = Join-Path $projectRoot ".linkwatcher.lock"
    Set-Content -Path $lockFile -Value $process.Id -NoNewline
    Write-Host "LinkWatcher started successfully in background (PID: $($process.Id))" -ForegroundColor Green
    Write-Host "  Project root: $projectRoot" -ForegroundColor Green
    Write-Host "  Log file: $logFile" -ForegroundColor Green
} else {
    Write-Host "Failed to start LinkWatcher" -ForegroundColor Red
}
