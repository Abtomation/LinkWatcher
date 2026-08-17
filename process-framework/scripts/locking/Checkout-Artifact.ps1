<#
.SYNOPSIS
    Checks out one guarded artifact for editing — creates its lock row in the artifact-locks
    store, erroring on a fresh collision (naming holder and age) and autonomously taking over
    a lock idle past the TTL, with the takeover logged (PF-PRO-061).

.DESCRIPTION
    Micro-lock discipline (Task Execution Protocol Phase B): check out immediately before
    directly editing a guarded file; release directly after that file's edits are done
    (Release-ArtifactLock.ps1, which commits the file's changes before unlocking). A session
    holds at most one lock at a time — a second checkout by the same session errors until the
    first lock is released.

    Session identity comes from CLAUDE_CODE_SESSION_ID (present in Claude Code tool
    subprocesses). Without it (e.g. a human terminal), the one-lock-per-session cap cannot be
    enforced mechanically and is skipped with a warning; path-level mutual exclusion is
    unaffected.

    With locking disabled in doc/project-config.json (or the block absent), the script warns
    and exits 0 — a no-op, so shared instructions degrade gracefully in non-adopting projects.

.PARAMETER Path
    The file to check out — absolute, cwd-relative, or repo-root-relative. One file per
    checkout. The file need not exist yet (locking a to-be-created artifact is allowed).

.PARAMETER Holder
    Free-text holder label: the running task plus context (e.g. "PF-TSK-009 PF-IMP-1234").

.NOTES
    Errors are raised as terminating errors (not bare exit codes) so they survive the
    `&` call operator (script-development quick reference, exit-N-through-& footgun).
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
    [Parameter(Mandatory)][ValidateLength(3, 200)][string]$Holder
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'LockStore.psm1') -Force

$projectRoot = Resolve-LockingProjectRoot
$config = Get-LockingConfig -ProjectRoot $projectRoot

if (-not $config.Enabled) {
    Write-Warning "Artifact locking is disabled in this workspace (doc/project-config.json locking block absent or enabled=false) — checkout is a no-op."
    exit 0
}

$rel = ConvertTo-RepoRelativePath -ProjectRoot $projectRoot -Path $Path
if (-not (Test-GuardedPath -RelativePath $rel -GuardedPaths $config.GuardedPaths)) {
    Write-Warning "'$rel' is not under a guarded path — no lock needed (guarded: $($config.GuardedPaths -join ', '))."
    exit 0
}

$sessionId = $env:CLAUDE_CODE_SESSION_ID
if (-not $sessionId) {
    Write-Warning "CLAUDE_CODE_SESSION_ID not set — the one-lock-per-session cap cannot be enforced for this checkout."
}

if (-not $PSCmdlet.ShouldProcess($rel, "Check out artifact lock (holder: $Holder)")) { exit 0 }

$ttl = $config.TtlMinutes
Invoke-LockStoreTransaction -StorePath $config.StorePath -Body {
    param($locks)

    $kept = @()
    foreach ($lock in @($locks)) {
        $isTarget = ($lock.path.ToLowerInvariant() -eq $rel.ToLowerInvariant())
        if ($isTarget) {
            $age = Get-LockAgeMinutes -Lock $lock
            if ($age -le $ttl) {
                throw "'$rel' is checked out by '$($lock.holder)' (session $($lock.sessionId); last activity $age min ago, TTL $ttl min). Edit something else or retry shortly; a FRESH foreign lock is only force-released via Remove-ArtifactLock.ps1 with human approval."
            }
            Write-Warning "TAKEOVER: expired lock on '$rel' released autonomously — was held by '$($lock.holder)' (session $($lock.sessionId)), idle $age min > TTL $ttl min."
            continue   # drop the expired row
        }
        if ($sessionId -and $lock.sessionId -eq $sessionId) {
            $age = Get-LockAgeMinutes -Lock $lock
            if ($age -le $ttl) {
                throw "This session already holds a lock on '$($lock.path)' (one lock per session) — release it first via Release-ArtifactLock.ps1."
            }
            # own expired residue: drop it rather than blocking ourselves
            Write-Warning "Own expired lock on '$($lock.path)' dropped (idle $age min > TTL $ttl min)."
            continue
        }
        $kept += $lock
    }

    $kept += New-LockRecord -RelativePath $rel -Holder $Holder -SessionId $sessionId
    return @{ Locks = $kept }
} | Out-Null

Write-Host "[OK] Checked out '$rel' (holder: $Holder). Release with Release-ArtifactLock.ps1 directly after the file's edits are done." -ForegroundColor Green
exit 0
