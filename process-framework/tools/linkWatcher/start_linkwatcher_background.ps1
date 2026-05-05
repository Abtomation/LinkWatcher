# LinkWatcher Background Starter
#
# Agnostic across projects: resolves project root from doc/project-config.json
# (script lives at process-framework/tools/linkWatcher/, three levels above doc/),
# auto-detects the global LinkWatcher install dir, and writes runtime artifacts
# under process-framework-local/tools/linkWatcher/.

# Resolve project root from project-config.json
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$configPath = Join-Path $scriptDir "..\..\..\doc\project-config.json"

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
#
# Resolver order:
#   1. $env:LINKWATCHER_INSTALL_DIR (explicit override for non-standard installs)
#   2. ~/bin, ~/tools, ~/scripts, ~/.local/bin, ~/LinkWatcher (auto-detect)
# A directory qualifies if both main.py and the dedicated venv Python exist.
function Resolve-LinkWatcherInstall {
    $venvRel = ".linkwatcher-venv\Scripts\python.exe"
    $candidates = @()
    if ($env:LINKWATCHER_INSTALL_DIR) { $candidates += $env:LINKWATCHER_INSTALL_DIR }
    $candidates += @(
        (Join-Path $HOME "bin"),
        (Join-Path $HOME "tools"),
        (Join-Path $HOME "scripts"),
        (Join-Path $HOME ".local\bin"),
        (Join-Path $HOME "LinkWatcher")
    )
    foreach ($dir in $candidates) {
        if ((Test-Path (Join-Path $dir "main.py")) -and (Test-Path (Join-Path $dir $venvRel))) {
            return $dir
        }
    }
    return $null
}

$lwInstallDir = Resolve-LinkWatcherInstall
if (-not $lwInstallDir) {
    Write-Host "Error: LinkWatcher installation not found." -ForegroundColor Red
    Write-Host "Searched: `$env:LINKWATCHER_INSTALL_DIR, ~/bin, ~/tools, ~/scripts, ~/.local/bin, ~/LinkWatcher" -ForegroundColor Red
    Write-Host "Each location must contain main.py and .linkwatcher-venv\Scripts\python.exe" -ForegroundColor Red
    Write-Host "Run the global installer first:" -ForegroundColor Yellow
    Write-Host "  python deployment/install_global.py" -ForegroundColor Yellow
    return
}

$lwMainPy = Join-Path $lwInstallDir "main.py"
$lwVenvPython = Join-Path $lwInstallDir ".linkwatcher-venv\Scripts\python.exe"

# Auto-create per-project .linkwatcher-ignore skeleton if missing
# (replaces the bootstrap that setup_project.py used to do)
$lwLocalDir = Join-Path $projectRoot "process-framework-local\tools\linkWatcher"
$lwIgnoreFile = Join-Path $lwLocalDir ".linkwatcher-ignore"
if (-not (Test-Path $lwIgnoreFile)) {
    if (-not (Test-Path $lwLocalDir)) {
        New-Item -ItemType Directory -Path $lwLocalDir -Force | Out-Null
    }
    @'
# .linkwatcher-ignore — Per-file validation suppression rules
#
# Format:  source_glob -> target_substring
# A broken link is suppressed when the source file matches the glob AND
# the link target contains the substring.
#
# Use sparingly — every rule here is a potential blind spot.
# Prefer fixing the actual link over adding a rule.
'@ | Set-Content -Path $lwIgnoreFile -Encoding UTF8
}

# Start LinkWatcher with explicit project root and logging
$logsDir = Join-Path $projectRoot "process-framework-local\tools\linkWatcher\logs"
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
