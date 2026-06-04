# LinkWatcher Background Starter
#
# Agnostic across projects: resolves project root from doc/project-config.json
# (script lives at process-framework/tools/linkWatcher/, three levels above doc/),
# auto-detects the global LinkWatcher install dir, and writes runtime artifacts
# (logs + .linkwatcher-ignore) under <project>/logs/linkwatcher/. The flat single-
# directory layout (no nested logs/ subdir) is the post-Phase-5 home; replaces
# the legacy process-framework-local/tools/linkWatcher/ location.
#
# Testing notes (handle-inheritance gotcha for subprocess callers):
#
# This script spawns the LinkWatcher daemon via `Start-Process -PassThru
# -WindowStyle Hidden -RedirectStandardOutput <stdoutLog>`. On Windows, the
# child python.exe inherits inheritable handles from this script's process —
# including our parent's stdout if we were invoked via `pwsh.exe -File ... |
# Out-String` or any other pipe-capturing pattern. The daemon then holds that
# stdout handle for its entire lifetime, which blocks the parent pipe from
# ever closing. Subprocess callers that capture our output via pipe will hang
# indefinitely.
#
# Test authors invoking this script from a parent pwsh.exe must capture our
# stdout via file redirection + bounded WaitForExit, not via pipes. The pattern
# locked in TE-E2E-009 (test/e2e-acceptance-testing/linkwatcher-startup/):
#
#   $tempOut = [System.IO.Path]::GetTempFileName()
#   $tempErr = [System.IO.Path]::GetTempFileName()
#   $p = Start-Process pwsh.exe `
#       -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$startScript) `
#       -WindowStyle Hidden -PassThru `
#       -RedirectStandardOutput $tempOut -RedirectStandardError $tempErr
#   if (-not $p.WaitForExit(8000)) { Stop-Process -Id $p.Id -Force }
#   $output = (Get-Content $tempOut -Raw) + (Get-Content $tempErr -Raw)
#
# Exit codes (set by `exit N`, programmatically detectable via $LASTEXITCODE):
#   0 — daemon started OR already running for this project (idempotent success)
#   1 — config missing / invalid project root / install missing / daemon crashed

param(
    [switch]$DebugLogging  # PF-IMP-967: opt-in verbose daemon logging (--debug); off by default
)

# Resolve project root from project-config.json by walking up from the script
# location. The walk-up correctly skips the blueprint template config at
# appdev/blueprint/doc/project-config.json (project_id: null) and lands on
# appdev/doc/project-config.json (project_id: "PRJ-000") in appdev. In rolled-out
# projects the walk finds the project's own config on first match. Mirrors the
# pattern in IdRegistry.psm1::Resolve-ProjectRootForRegistry, which solves the
# identical problem from the registry-loading side.
function Find-ProjectConfigPath {
    param([string]$StartPath)
    $current = $StartPath
    $maxDepth = 10
    for ($i = 0; $i -lt $maxDepth; $i++) {
        $candidate = Join-Path $current "doc\project-config.json"
        if (Test-Path $candidate) {
            try {
                $check = Get-Content $candidate -Raw | ConvertFrom-Json
                if ($check.project_id) { return $candidate }
            } catch {
                # Unparseable — keep walking (treat as no project_id)
            }
        }
        $parent = Split-Path -Parent $current
        if ($parent -eq $current) { break }
        $current = $parent
    }
    return $null
}

function Get-LinkWatcherArguments {
    # PF-IMP-967: build the daemon argument string. --debug is opt-in (it used to be
    # hardcoded), so the default session-start path no longer floods and rapidly
    # rotates the log — the condition that fed the multi-instance rotation storm.
    param(
        [Parameter(Mandatory)][string]$MainPy,
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$LogFile,
        [switch]$DebugLogging
    )
    $argStr = "$MainPy --project-root `"$ProjectRoot`" --log-file `"$LogFile`""
    if ($DebugLogging) { $argStr += " --debug" }
    return $argStr
}

function Test-LinkWatcherAlreadyRunning {
    # PF-IMP-967: robust singleton guard. The lock-file check can miss an instance
    # that started but never reached main.py's lock acquisition (e.g. stuck in the
    # PD-BUG-099 logging/rotation loop). Scan running processes for any daemon
    # already bound to THIS project root. Returns the matching PIDs (@() if none).
    param([Parameter(Mandatory)][string]$ProjectRoot)
    try {
        $procs = Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
            $_.CommandLine -and $_.CommandLine -like '*main.py*' -and $_.CommandLine.Contains($ProjectRoot)
        }
        return @($procs | ForEach-Object { $_.ProcessId })
    } catch {
        # Process enumeration failed — do not block startup.
        return @()
    }
}

# PF-IMP-967: when dot-sourced (e.g. by Pester), define functions only and skip the
# startup body so tests can exercise the helpers without spawning a daemon.
if ($MyInvocation.InvocationName -eq '.') { return }

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$configPath = Find-ProjectConfigPath -StartPath $scriptDir

if (-not $configPath) {
    Write-Host "Error: project-config.json (with non-null project_id) not found walking up from: $scriptDir" -ForegroundColor Red
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$projectRoot = $config.project.root_directory

if (-not $projectRoot -or -not (Test-Path $projectRoot)) {
    Write-Host "Error: Invalid project root in project-config.json: $projectRoot" -ForegroundColor Red
    exit 1
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
            exit 0
        } else {
            Write-Host "Stale lock file found (PID $lockPid no longer running), will be overridden." -ForegroundColor DarkYellow
        }
    } catch {
        Write-Host "Invalid lock file, will be overridden." -ForegroundColor DarkYellow
    }
}

# PF-IMP-967: process-based singleton backstop. The lock-file check above is
# defeated when a prior instance stalled before writing its lock (PD-BUG-099),
# which is how three daemons accumulated. Refuse to start a duplicate.
$runningPids = Test-LinkWatcherAlreadyRunning -ProjectRoot $projectRoot
if ($runningPids.Count -gt 0) {
    Write-Host "LinkWatcher is already running for $projectRoot (PID(s): $($runningPids -join ', '))." -ForegroundColor Yellow
    Write-Host "Not starting a duplicate instance." -ForegroundColor Yellow
    exit 0
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
    exit 1
}

$lwMainPy = Join-Path $lwInstallDir "main.py"
$lwVenvPython = Join-Path $lwInstallDir ".linkwatcher-venv\Scripts\python.exe"

# Auto-create per-project .linkwatcher-ignore skeleton if missing
# (replaces the bootstrap that setup_project.py used to do)
$lwLocalDir = Join-Path $projectRoot "logs\linkwatcher"
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
# Logs co-locate with .linkwatcher-ignore in the flat logs/linkwatcher/ layout
# (no inner logs/ subdir per Phase 5 flatten decision).
$logsDir = $lwLocalDir
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}
$logFile = Join-Path $logsDir "LinkWatcherLog.txt"
$stdoutLog = Join-Path $logsDir "LinkWatcherStdout.txt"
$stderrLog = Join-Path $logsDir "LinkWatcherError.txt"
$arguments = Get-LinkWatcherArguments -MainPy $lwMainPy -ProjectRoot $projectRoot -LogFile $logFile -DebugLogging:$DebugLogging

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
        exit 1
    }

    Write-Host "LinkWatcher started successfully in background (PID: $($process.Id))" -ForegroundColor Green
    Write-Host "  Project root: $projectRoot" -ForegroundColor Green
    Write-Host "  Log file: $logFile" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Failed to start LinkWatcher" -ForegroundColor Red
    exit 1
}
