#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Workspace-scoped LinkWatcher lifecycle helpers for E2E acceptance test run.ps1 scripts.

.DESCRIPTION
    Run-E2EAcceptanceTest.ps1 v2.0 (PF-IMP-878) is project-agnostic and no longer manages
    LinkWatcher. LinkWatcher-dependent test cases start/stop their own instance through these
    helpers. The instance is scoped to the test's <workspace>/project directory and is tracked
    by PID, so Stop-WorkspaceLinkWatcher terminates ONLY the instance this helper started —
    never the repository's own LinkWatcher daemon.

    Pattern derived from the proven TE-E2E-012 run.ps1 (debugged via PD-BUG-047 / PD-BUG-053):
      - LW is started with `python main.py --project-root <workspace>/project` directly, NOT via
        start_linkwatcher_background.ps1 (which ignores -ProjectRoot and uses the repo root —
        PD-BUG-053).
      - Scope is <workspace>/project (not the whole workspace) so the expected/ reference tree is
        never scanned.

    ⚠️  REPO DAEMON: These helpers do NOT touch the repository's global LinkWatcher daemon. When the
    suite is run on a machine where a repo-scoped LinkWatcher is watching test/e2e-acceptance-testing/,
    stop that daemon for the duration of the run (controlled stop via .linkwatcher.lock) — otherwise a
    second watcher races on the workspace and corrupts fixtures.

    Source: MIG-018 (PF-IMP-878) Mode C migration for PRJ-001.
#>

function Get-E2EProjectRoot {
    # Walk up from the workspace to the repo root (the dir containing .git + main.py).
    param([Parameter(Mandatory = $true)][string]$WorkspacePath)
    $dir = (Resolve-Path $WorkspacePath).Path
    while ($dir -and -not (Test-Path (Join-Path $dir ".git"))) {
        $dir = Split-Path -Parent $dir
    }
    if (-not $dir) { throw "Could not find project root (.git) from $WorkspacePath" }
    return $dir
}

function Start-WorkspaceLinkWatcher {
    # Start a LinkWatcher instance scoped to <workspace>/project and wait for its initial scan
    # to begin. Returns a handle ({ Process; Pid; LogFile; ProjectPath }) for Stop/Wait.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$WorkspacePath,
        [string[]]$ExtraArgs = @(),
        [int]$ScanTimeoutSeconds = 15
    )
    $projectPath = Join-Path $WorkspacePath "project"
    $projectRoot = Get-E2EProjectRoot -WorkspacePath $WorkspacePath
    $mainPy = Join-Path $projectRoot "main.py"
    $logFile = Join-Path $WorkspacePath "linkwatcher-e2e.log"

    # Clear a stale workspace-scoped lock from a prior aborted run.
    $wsLock = Join-Path $WorkspacePath ".linkwatcher.lock"
    if (Test-Path $wsLock) { Remove-Item $wsLock -Force -ErrorAction SilentlyContinue }

    $argList = @("`"$mainPy`"", "--project-root", "`"$projectPath`"", "--log-file", "`"$logFile`"", "--debug") + $ExtraArgs
    $proc = Start-Process -FilePath "python" -ArgumentList $argList -WorkingDirectory $projectPath `
        -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $WorkspacePath "lw-stdout.txt") `
        -RedirectStandardError (Join-Path $WorkspacePath "lw-stderr.txt")

    # Wait for the observer to begin its initial scan before returning, so the caller's
    # subsequent file operations are actually observed.
    $elapsed = 0
    while ($elapsed -lt $ScanTimeoutSeconds) {
        Start-Sleep -Seconds 1; $elapsed++
        if (Test-Path $logFile) {
            $tail = Get-Content $logFile -Tail 30 -ErrorAction SilentlyContinue
            if ($tail -match 'initial_scan_starting|scan_progress|initial_scan_complete|monitoring_started|observer_started') {
                break
            }
        }
    }
    if ($elapsed -ge $ScanTimeoutSeconds) {
        Write-Host "Warning: LinkWatcher scan start not detected after ${ScanTimeoutSeconds}s — continuing anyway" -ForegroundColor Yellow
    }
    Write-Host "Started workspace LinkWatcher (PID: $($proc.Id), scope: $projectPath)"
    return [pscustomobject]@{ Process = $proc; Pid = $proc.Id; LogFile = $logFile; ProjectPath = $projectPath }
}

function Wait-LinkWatcherSettle {
    # Give LinkWatcher time to detect a move and update references. Default exceeds the
    # delete+create move-correlation window (move_detect_delay, default 10s).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Handle,
        [int]$Seconds = 12
    )
    Start-Sleep -Seconds $Seconds
}

function Stop-WorkspaceLinkWatcher {
    # Terminate ONLY the instance this helper started (tracked by PID). Never touches the
    # repo's own daemon.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Handle,
        [int]$GraceMilliseconds = 500
    )
    if (-not $Handle) { return }
    $procId = $Handle.Pid
    $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
    if ($p) {
        Stop-Process -Id $procId -Force
        Start-Sleep -Milliseconds $GraceMilliseconds
        Write-Host "Stopped workspace LinkWatcher (PID: $procId)"
    }
    $wsLock = Join-Path (Split-Path -Parent $Handle.ProjectPath) ".linkwatcher.lock"
    if (Test-Path $wsLock) { Remove-Item $wsLock -Force -ErrorAction SilentlyContinue }
}
