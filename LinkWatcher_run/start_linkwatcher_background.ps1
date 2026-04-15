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

# Resolve LinkWatcher installation directory and dedicated venv Python
# PD-BUG-077: Never use bare 'python' — it may resolve to a project .venv
# that lacks LinkWatcher dependencies, causing silent startup failure.
$lwInstallDir = "C:\\Users\\ronny\\bin"
$lwMainPy = Join-Path $lwInstallDir "main.py"
$lwVenvPython = Join-Path $lwInstallDir ".linkwatcher-venv\\Scripts\\python.exe"

if (-not (Test-Path $lwVenvPython)) {
    Write-Host "Error: LinkWatcher dedicated venv not found at: $lwVenvPython" -ForegroundColor Red
    Write-Host "Run the global installer first:" -ForegroundColor Red
    Write-Host "  python deployment/install_global.py" -ForegroundColor Yellow
    return
}

# Start LinkWatcher with explicit project root and logging
$logsDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}
$logFile = Join-Path $logsDir "LinkWatcherLog.txt"
$stdoutLog = Join-Path $logsDir "LinkWatcherStdout.txt"
$stderrLog = Join-Path $logsDir "LinkWatcherError.txt"
$arguments = "$lwMainPy --project-root `"$projectRoot`" --log-file `"$logFile`" --debug"

$process = Start-Process -FilePath $lwVenvPython -ArgumentList $arguments -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog

if ($process) {
    # Let main.py handle its own lock file acquisition.
    # Previously this script wrote the lock file early, but that causes a
    # race condition: main.py sees its own PID in the lock, thinks another
    # instance is running, and exits.

    # PD-BUG-077: Verify the process survives initialization.
    # The old script reported success immediately, but the process could
    # crash on import before doing any work.
    Start-Sleep -Seconds 2
    $process.Refresh()
    if ($process.HasExited) {
        $exitCode = $process.ExitCode
        Write-Host "Error: LinkWatcher process exited immediately (exit code: $exitCode)" -ForegroundColor Red
        if (Test-Path $stderrLog) {
            $stderr = Get-Content $stderrLog -Raw
            if ($stderr) {
                Write-Host "Stderr output:" -ForegroundColor Red
                Write-Host $stderr -ForegroundColor DarkRed
            }
        }
        # Clean up lock file if main.py wrote one before crashing
        $crashLockFile = Join-Path $projectRoot ".linkwatcher.lock"
        if (Test-Path $crashLockFile) { Remove-Item $crashLockFile -Force }
        return
    }

    Write-Host "LinkWatcher started successfully in background (PID: $($process.Id))" -ForegroundColor Green
    Write-Host "  Project root: $projectRoot" -ForegroundColor Green
    Write-Host "  Log file: $logFile" -ForegroundColor Green
} else {
    Write-Host "Failed to start LinkWatcher" -ForegroundColor Red
}
