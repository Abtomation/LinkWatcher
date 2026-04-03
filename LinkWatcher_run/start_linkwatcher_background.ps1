# LinkWatcher Background Starter for this project

# Resolve project root from project-config.json
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$configPath = Join-Path $scriptDir "..\doc\project-config.json"

if (-not (Test-Path $configPath)) {
    Write-Host "Error: project-config.json not found at: $configPath" -ForegroundColor Red
    return
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$projectRoot = $config.project.root_directory

if (-not $projectRoot -or -not (Test-Path $projectRoot)) {
    Write-Host "Error: Invalid project root in project-config.json: $projectRoot" -ForegroundColor Red
    return
}

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

Write-Host "Starting LinkWatcher in background for $projectRoot..." -ForegroundColor Cyan

# Start LinkWatcher with explicit project root and logging
$logFile = Join-Path $scriptDir "LinkWatcherLog_20260331-072913_20260331-074026_20260331-203808_20260401-110504_20260402-102805_20260403-115312.txt"
$stdoutLog = Join-Path $scriptDir "LinkWatcherStdout.txt"
$stderrLog = Join-Path $scriptDir "LinkWatcherError.txt"
$arguments = "C:\Users\ronny\bin\main.py --project-root `"$projectRoot`" --log-file `"$logFile`" --debug"

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
