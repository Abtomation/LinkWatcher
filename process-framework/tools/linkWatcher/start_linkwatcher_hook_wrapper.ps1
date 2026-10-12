<#
.SYNOPSIS
    Starts LinkWatcher from a SessionStart hook without letting the daemon's
    inherited stdout handle block the hook's capture pipe.

.DESCRIPTION
    Why a wrapper instead of invoking start_linkwatcher_background.ps1 directly
    from .claude/settings.json:

    The LinkWatcher daemon (python.exe) inherits inheritable stdout/stderr
    handles from its parent. When invoked from any pipe-capturing context
    (such as a Claude Code SessionStart hook, which captures the hook command's
    stdout for additionalContext injection), the daemon keeps the pipe's
    write-end open for its lifetime — the calling pipe never sees EOF and the
    session-start blocks indefinitely. The sibling start_linkwatcher_background.ps1
    script's .NOTES block ("Testing notes") documents this constraint and
    reference-implements the isolation pattern adopted here.

    This wrapper applies the TE-E2E-009 locked-in pattern:
      - Start-Process with explicit -RedirectStandardOutput / -RedirectStandardError
        to dedicated temp files (daemon inherits the temp-file handles, not the
        hook's capture pipe).
      - WaitForExit(8000) bound — if the startup script genuinely hangs, kill it
        so the hook doesn't block session start.
      - Emit only the last few lines of combined output so the agent sees the
        success banner or error context (full daemon logs live in
        <project>/logs/linkwatcher/).

    Control Panel auto-open (PF-IMP-2032, TDD PD-TDD-033 section 4.5):
    this wrapper is the only thing that runs unconditionally at session start —
    start_linkwatcher_background.ps1 returns early when a daemon is already
    running, so a launch placed there would never fire in the steady state, which
    is exactly the case the panel's surface-the-incumbent handshake serves.
    The launch is therefore made here, on every exit path, and is opt-in per
    project (see Invoke-ControlPanelAutoOpen).

.NOTES
    OWNERSHIP: FWK-FB (FrameworkBuilder) - canonical at FrameworkBuilder; anywhere else a received copy. Edit only at the owning workspace. An agent may only modify files its workspace owns.
    Exit code: always 0. LinkWatcher startup failures must not block session start.
    The output line carries the diagnostic for the agent to surface to the human.
#>

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Control Panel auto-open helpers (PF-IMP-2032)
# ---------------------------------------------------------------------------
# Opt-in per project via doc/project-config.json → integration.linkwatcher_control_panel_auto_open.
# Absent or false means no launch, so this substrate change ships inert to every
# workspace that did not ask for the panel. Repeat launches are safe by
# construction: the panel's port-file handshake surfaces the running instance
# rather than opening a second window (TDD PD-TDD-033 section 4.4/4.5).

function Test-ControlPanelAutoOpenEnabled {
    [CmdletBinding()]
    param([string]$ProjectConfigPath)

    if ([string]::IsNullOrWhiteSpace($ProjectConfigPath) -or -not (Test-Path $ProjectConfigPath)) { return $false }
    try {
        $cfg = Get-Content $ProjectConfigPath -Raw | ConvertFrom-Json
        return [bool]$cfg.integration.linkwatcher_control_panel_auto_open
    }
    catch { return $false }
}

function Get-ControlPanelLaunchSpec {
    [CmdletBinding()]
    param([string]$InstallDir, [string]$ProjectRoot)

    if ([string]::IsNullOrWhiteSpace($InstallDir) -or [string]::IsNullOrWhiteSpace($ProjectRoot)) { return $null }
    $pythonw = Join-Path $InstallDir '.linkwatcher-venv\Scripts\pythonw.exe'
    $panel = Join-Path $InstallDir 'control_panel.py'
    # The panel is not in the global install until the next LinkWatcher release.
    # Returning $null keeps that a silent no-op instead of a session-start error.
    if (-not (Test-Path $pythonw) -or -not (Test-Path $panel)) { return $null }

    [pscustomobject]@{
        Exe       = $pythonw
        Arguments = @($panel, '--project-root', $ProjectRoot)
    }
}

function Invoke-ControlPanelAutoOpen {
    [CmdletBinding()]
    param([string]$StartPath)

    # Never throws and never waits. This runs on every wrapper exit path, and the
    # wrapper's contract is that nothing it does can block or fail session start.
    try {
        $sibling = Join-Path $StartPath 'start_linkwatcher_background.ps1'
        if (-not (Test-Path $sibling)) { return }
        . $sibling   # dot-source guard defines helpers only; no daemon is spawned

        $cfgPath = Find-ProjectConfigPath -StartPath $StartPath
        if (-not (Test-ControlPanelAutoOpenEnabled -ProjectConfigPath $cfgPath)) { return }

        $projectRoot = (Get-Content $cfgPath -Raw | ConvertFrom-Json).project.root_directory
        $spec = Get-ControlPanelLaunchSpec -InstallDir (Resolve-LinkWatcherInstall) -ProjectRoot $projectRoot
        if (-not $spec) { return }

        # Same handle-isolation rule as the daemon launch below, and for the same
        # reason: the panel is a long-lived GUI process, so if it inherits the
        # hook's capture pipe it holds the write-end open for its whole lifetime
        # and session start never sees EOF. Redirect to the project's own log dir
        # (not temp files this script deletes — the panel outlives this process).
        $logDir = Join-Path $projectRoot 'logs\linkwatcher'
        if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
        Start-Process -FilePath $spec.Exe -ArgumentList $spec.Arguments `
            -WindowStyle Hidden `
            -RedirectStandardOutput (Join-Path $logDir 'control-panel-hook.out') `
            -RedirectStandardError (Join-Path $logDir 'control-panel-hook.err') | Out-Null
    }
    catch { }
}

# When dot-sourced (e.g. by Pester), define functions only and skip the startup
# body so tests can exercise the helpers without spawning anything.
if ($MyInvocation.InvocationName -eq '.') { return }

try {

$startScript = Join-Path $PSScriptRoot 'start_linkwatcher_background.ps1'
if (-not (Test-Path $startScript)) {
    Write-Output "LinkWatcher hook: sibling start_linkwatcher_background.ps1 not found at $startScript"
    exit 0
}

$tempOut = [System.IO.Path]::GetTempFileName()
$tempErr = [System.IO.Path]::GetTempFileName()
try {
    $p = Start-Process pwsh.exe `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $startScript) `
        -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput $tempOut -RedirectStandardError $tempErr
    if (-not $p.WaitForExit(8000)) {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        Write-Output "LinkWatcher hook: TIMEOUT after 8s (startup script killed; check logs/linkwatcher/)"
        exit 0
    }
    $stdoutContent = if (Test-Path $tempOut) { Get-Content $tempOut -Raw } else { '' }
    $stderrContent = if (Test-Path $tempErr) { Get-Content $tempErr -Raw } else { '' }
    $combined = ($stdoutContent + $stderrContent).TrimEnd()
    if ($combined) {
        $combined -split "`r?`n" | Where-Object { $_.Trim() -ne '' } | Select-Object -Last 5
    }
    else {
        Write-Output "LinkWatcher hook: no output (exit code $($p.ExitCode))"
    }
}
finally {
    Remove-Item $tempOut, $tempErr -Force -ErrorAction SilentlyContinue
}

}
finally {
    # Every exit path: the early return above, the 8s timeout, normal completion,
    # and any unexpected terminating error. `finally` runs on `exit N` in a script,
    # which is what makes one call site cover all of them.
    Invoke-ControlPanelAutoOpen -StartPath $PSScriptRoot
}
