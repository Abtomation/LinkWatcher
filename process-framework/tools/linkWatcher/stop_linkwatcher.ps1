<#
.SYNOPSIS
    Stops this project's LinkWatcher daemon(s) with a verified post-condition —
    instances are detected by process command line + project root (not the lock
    file, whose PID can be stale), stopped, confirmed gone, and the lock file
    cleaned up.

.DESCRIPTION
    Counterpart to start_linkwatcher_background.ps1 (PF-IMP-1682). The lock file
    is only a hint: it can name a dead PID (self-perpetuating stale lock) or, on
    Store-Python venvs, name the real interpreter while the process a caller
    knows about is the redirector shim. A lock-PID-only stop can therefore
    signal a dead — or, after PID reuse, an unrelated — process while real
    daemons keep running. This script instead scans running processes for
    main.py bound to THIS project root (the same detection the start script's
    singleton backstop uses), stops every match, re-scans until none survive,
    and only then removes the lock file.

    Process model note (Store-Python venvs): a healthy daemon shows as TWO
    processes — the venv redirector shim and its child, the real interpreter.
    Both match the scan and both are stopped; the settle loop absorbs the
    shim's teardown lag after its child dies.

    Exit codes (set by `exit N`, programmatically detectable via $LASTEXITCODE):
      0 — no instance was running, or all instances stopped and verified gone
      1 — invalid project root, or stop incomplete (surviving PIDs reported)
#>

# Reuse the sibling's helpers (Find-ProjectConfigPath,
# Test-LinkWatcherAlreadyRunning). Its dot-source guard makes this define
# functions only — no daemon is spawned.
$stopScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
. (Join-Path $stopScriptDir 'start_linkwatcher_background.ps1')

function Invoke-LinkWatcherStop {
    # Testable core: scan for this project's instances, stop them, and re-scan
    # with bounded settle retries until none remain. $GetPids / $StopPid are
    # injectable so the loop is unit-testable without real processes;
    # $SettleDelayMs 0 makes tests instant.
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [scriptblock]$GetPids = { param($root) Test-LinkWatcherAlreadyRunning -ProjectRoot $root },
        [scriptblock]$StopPid = { param($p) Stop-Process -Id $p -Force -ErrorAction SilentlyContinue },
        [int]$SettleRetries = 4,
        [int]$SettleDelayMs = 500
    )

    $initial = @(& $GetPids $ProjectRoot)
    if ($initial.Count -eq 0) {
        return [pscustomobject]@{ StoppedPids = @(); RemainingPids = @() }
    }

    foreach ($p in $initial) { & $StopPid $p }

    # Settle loop: the Store-venv shim exits on its own shortly after its child
    # is killed — give teardown time before judging the stop, and re-kill any
    # process the first pass missed.
    $remaining = @()
    for ($i = 0; $i -lt $SettleRetries; $i++) {
        if ($SettleDelayMs -gt 0) { Start-Sleep -Milliseconds $SettleDelayMs }
        $remaining = @(& $GetPids $ProjectRoot)
        if ($remaining.Count -eq 0) { break }
        foreach ($p in $remaining) { & $StopPid $p }
    }

    return [pscustomobject]@{ StoppedPids = $initial; RemainingPids = $remaining }
}

# When dot-sourced (e.g. by Pester), define functions only and skip the body.
if ($MyInvocation.InvocationName -eq '.') { return }

$configPath = Find-ProjectConfigPath -StartPath $stopScriptDir
if (-not $configPath) {
    Write-Host "Error: project-config.json (with non-null project_id) not found walking up from: $stopScriptDir" -ForegroundColor Red
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$projectRoot = $config.project.root_directory
if (-not $projectRoot -or -not (Test-Path $projectRoot)) {
    Write-Host "Error: Invalid project root in project-config.json: $projectRoot" -ForegroundColor Red
    exit 1
}

$lockFile = Join-Path $projectRoot ".linkwatcher.lock"
$result = Invoke-LinkWatcherStop -ProjectRoot $projectRoot

if ($result.StoppedPids.Count -eq 0) {
    Write-Host "No LinkWatcher instance running for $projectRoot." -ForegroundColor Yellow
    if (Test-Path $lockFile) {
        Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
        Write-Host "Removed stale lock file (no owner was running)." -ForegroundColor DarkYellow
    }
    exit 0
}

if ($result.RemainingPids.Count -gt 0) {
    Write-Host "WARNING: LinkWatcher stop INCOMPLETE for $projectRoot — still running: $($result.RemainingPids -join ', ')" -ForegroundColor Red
    Write-Host "Resolve manually before relying on LinkWatcher being stopped." -ForegroundColor Red
    exit 1
}

if (Test-Path $lockFile) {
    Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
}
Write-Host "LinkWatcher stopped for $projectRoot (PID(s): $($result.StoppedPids -join ', ')); verified no instance remains." -ForegroundColor Green
exit 0
