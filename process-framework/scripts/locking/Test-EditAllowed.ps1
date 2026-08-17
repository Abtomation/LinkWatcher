<#
.SYNOPSIS
    PreToolUse enforcement hook for Artifact Checkout Locking (PF-PRO-061) — reads the tool
    call from stdin, allows edits to unguarded paths instantly, blocks a guarded-path edit
    that has no fresh lock held by the calling session, and refreshes the lock's
    last-activity timestamp on every allowed edit.

.DESCRIPTION
    Wired in .claude/settings.json as a PreToolUse hook with an Edit/Write matcher. Contract:
      exit 0            -> allow the tool call
      exit 2 + stderr   -> BLOCK the tool call; stderr becomes the agent-visible reason

    Decision table for a guarded path (locking enabled):
      no lock                     -> block ("not checked out")
      lock expired (> TTL idle)   -> block ("expired — check out again"; checkout takes over)
      fresh lock, other session   -> block (names the holder)
      fresh lock, this session    -> allow + refresh lastActivity (keeps TTL activity-based)
      fresh lock, session unknown -> allow on lock presence (no identity to compare)

    With locking disabled (or the config block absent) the hook is a transparent allow —
    projects that never adopted locking pay nothing.

    Kept dependency-light on purpose: imports only LockStore.psm1 (never the
    Common-ScriptHelpers umbrella) because this runs on every Edit/Write tool call.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Deny {
    param([string]$Reason)
    [Console]::Error.WriteLine($Reason)
    exit 2
}

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
    $payload = $raw | ConvertFrom-Json -ErrorAction Stop

    $toolName = if ($payload.PSObject.Properties.Name -contains 'tool_name') { [string]$payload.tool_name } else { '' }
    if ($toolName -notin @('Edit', 'Write', 'MultiEdit', 'NotebookEdit')) { exit 0 }

    $toolInput = if ($payload.PSObject.Properties.Name -contains 'tool_input') { $payload.tool_input } else { $null }
    if ($null -eq $toolInput) { exit 0 }
    $filePath = $null
    foreach ($key in 'file_path', 'notebook_path') {
        if ($toolInput.PSObject.Properties.Name -contains $key -and $toolInput.$key) { $filePath = [string]$toolInput.$key; break }
    }
    if (-not $filePath) { exit 0 }

    Import-Module (Join-Path $PSScriptRoot 'LockStore.psm1') -Force

    $startDir = if ($payload.PSObject.Properties.Name -contains 'cwd' -and $payload.cwd) { [string]$payload.cwd } else { (Get-Location).Path }
    $projectRoot = $null
    try { $projectRoot = Resolve-LockingProjectRoot -StartDir $startDir } catch { exit 0 }   # outside any workspace -> not ours to guard

    $config = Get-LockingConfig -ProjectRoot $projectRoot
    if (-not $config.Enabled) { exit 0 }

    $rel = $null
    try { $rel = ConvertTo-RepoRelativePath -ProjectRoot $projectRoot -Path $filePath } catch { exit 0 }   # outside the root -> unguarded
    if (-not (Test-GuardedPath -RelativePath $rel -GuardedPaths $config.GuardedPaths)) { exit 0 }

    $hookSessionId = if ($payload.PSObject.Properties.Name -contains 'session_id') { [string]$payload.session_id } else { $null }
    $ttl = $config.TtlMinutes

    $verdict = Invoke-LockStoreTransaction -StorePath $config.StorePath -Body {
        param($locks)
        $updated = @()
        $decision = $null
        foreach ($lock in @($locks)) {
            if ($lock.path.ToLowerInvariant() -eq $rel.ToLowerInvariant()) {
                $age = Get-LockAgeMinutes -Lock $lock
                if ($age -gt $ttl) {
                    $decision = "EXPIRED: the lock on '$rel' (holder '$($lock.holder)') has been idle $age min (TTL $ttl) — check it out again with Checkout-Artifact.ps1 (takeover is automatic for expired locks)."
                    $updated += $lock
                } elseif ($hookSessionId -and $lock.sessionId -and $lock.sessionId -ne $hookSessionId) {
                    $decision = "LOCKED: '$rel' is checked out by '$($lock.holder)' (session $($lock.sessionId), last activity $age min ago). Edit something else or retry shortly; a fresh foreign lock is only force-released via Remove-ArtifactLock.ps1 with human approval."
                    $updated += $lock
                } else {
                    $lock.lastActivity = (Get-Date).ToUniversalTime().ToString('o')
                    $decision = 'ALLOW'
                    $updated += $lock
                }
            } else {
                $updated += $lock
            }
        }
        if ($null -eq $decision) {
            $decision = "NOT CHECKED OUT: '$rel' is a guarded artifact — check it out first: Checkout-Artifact.ps1 -Path '$rel' -Holder '<task + context>' (Task Execution Protocol Phase B; release directly after the file's edits are done)."
        }
        return @{ Locks = $updated; Result = $decision }
    }

    if ($verdict -eq 'ALLOW') { exit 0 }
    Deny $verdict
} catch {
    # Fail-open with a visible warning: a broken hook must not freeze all editing.
    [Console]::Error.WriteLine("Test-EditAllowed hook error (allowing edit): $($_.Exception.Message)")
    exit 0
}
