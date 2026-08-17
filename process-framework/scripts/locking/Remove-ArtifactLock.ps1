<#
.SYNOPSIS
    Force-releases an artifact lock the caller does not hold — the human-approved manual
    override for a wedged FRESH foreign lock; prints the lock's evidence (holder, age, the
    path's git status) before acting (PF-PRO-061).

.DESCRIPTION
    Not the routine path: expired locks are taken over automatically at the next checkout,
    and a session releases its own lock via Release-ArtifactLock.ps1 (which commits first).
    This script exists for the rare wedged case — a fresh lock whose holder is known-dead —
    and requires explicit human approval, recorded in -ApprovedBy.

    Note the residue hazard it prints: a force-released lock's path may carry the dead
    session's uncommitted changes; the evidence output records that state so the residue
    stays attributable.

.PARAMETER Path
    The locked file — absolute, cwd-relative, or repo-root-relative.

.PARAMETER ApprovedBy
    Human-approval provenance (who approved, e.g. "ronny 2026-07-29"). Mandatory — this
    script must never run without an explicit human decision (Standing Orders: fresh foreign
    locks are human-gated).
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
    [Parameter(Mandatory)][ValidateLength(3, 200)][string]$ApprovedBy
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'LockStore.psm1') -Force

$projectRoot = Resolve-LockingProjectRoot
$config = Get-LockingConfig -ProjectRoot $projectRoot

if (-not $config.Enabled) {
    Write-Warning 'Artifact locking is disabled in this workspace — nothing to remove.'
    exit 0
}

$rel = ConvertTo-RepoRelativePath -ProjectRoot $projectRoot -Path $Path

$lock = Invoke-LockStoreTransaction -StorePath $config.StorePath -Body {
    param($locks)
    $hit = @($locks | Where-Object { $_.path.ToLowerInvariant() -eq $rel.ToLowerInvariant() })
    return @{ Result = $(if ($hit.Count -gt 0) { $hit[0] } else { $null }) }
}
if ($null -eq $lock) {
    Write-Warning "'$rel' is not locked — nothing to remove."
    exit 0
}

# Evidence printout BEFORE acting — the human verifies against reality, never the record alone.
$age = Get-LockAgeMinutes -Lock $lock
$gitState = ((& git -C $projectRoot status --porcelain -- $rel 2>&1) -join "`n").Trim()
if ([string]::IsNullOrWhiteSpace($gitState)) { $gitState = '(clean — no uncommitted changes)' }
Write-Host '=== Lock evidence ===' -ForegroundColor Yellow
Write-Host "  Path:          $rel"
Write-Host "  Holder:        $($lock.holder)"
Write-Host "  Session:       $($lock.sessionId)"
Write-Host "  Idle:          $age min (TTL $($config.TtlMinutes) min — $(if ($age -gt $config.TtlMinutes) { 'EXPIRED; a normal checkout would take this over automatically' } else { 'FRESH: confirm the holder is genuinely dead before proceeding' }))"
Write-Host "  Git status:    $gitState"
Write-Host "  Approved by:   $ApprovedBy"

if (-not $PSCmdlet.ShouldProcess($rel, "Force-release lock held by '$($lock.holder)' (approved by $ApprovedBy)")) { exit 0 }

Invoke-LockStoreTransaction -StorePath $config.StorePath -Body {
    param($locks)
    $kept = @($locks | Where-Object { $_.path.ToLowerInvariant() -ne $rel.ToLowerInvariant() })
    return @{ Locks = $kept }
} | Out-Null

Write-Warning "FORCE-RELEASE: lock on '$rel' (holder '$($lock.holder)', session $($lock.sessionId), idle $age min) removed with human approval: $ApprovedBy. Uncommitted state at release: $gitState"
exit 0
