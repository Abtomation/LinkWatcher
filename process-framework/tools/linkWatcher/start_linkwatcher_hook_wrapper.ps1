# LinkWatcher SessionStart Hook Wrapper
#
# Why a wrapper instead of invoking start_linkwatcher_background.ps1 directly
# from .claude/settings.json:
#
# The LinkWatcher daemon (python.exe) inherits inheritable stdout/stderr
# handles from its parent. When invoked from any pipe-capturing context
# (such as a Claude Code SessionStart hook, which captures the hook command's
# stdout for additionalContext injection), the daemon keeps the pipe's
# write-end open for its lifetime — the calling pipe never sees EOF and the
# session-start blocks indefinitely. The sibling start_linkwatcher_background.ps1
# script's header (lines 10-32) documents this constraint and reference-implements
# the isolation pattern adopted here.
#
# This wrapper applies the TE-E2E-009 locked-in pattern:
#   - Start-Process with explicit -RedirectStandardOutput / -RedirectStandardError
#     to dedicated temp files (daemon inherits the temp-file handles, not the
#     hook's capture pipe).
#   - WaitForExit(8000) bound — if the startup script genuinely hangs, kill it
#     so the hook doesn't block session start.
#   - Emit only the last few lines of combined output so the agent sees the
#     success banner or error context (full daemon logs live in
#     <project>/logs/linkwatcher/).
#
# Exit code: always 0. LinkWatcher startup failures must not block session start.
# The output line carries the diagnostic for the agent to surface to the human.

$ErrorActionPreference = 'Stop'

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
