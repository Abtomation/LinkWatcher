<#
.SYNOPSIS
    Lists active artifact locks with holder, age, and an EXPIRED flag for locks idle past the
    TTL; -Summary prints a single low-noise line for the SessionStart hook (PF-PRO-061).

.PARAMETER Summary
    One-line output for hook use: silent when the store is empty or locking is disabled,
    otherwise "Artifact locks: N active (M expired) — <paths>".
#>
[CmdletBinding()]
param(
    [switch]$Summary
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'LockStore.psm1') -Force

$projectRoot = Resolve-LockingProjectRoot
$config = Get-LockingConfig -ProjectRoot $projectRoot

if (-not $config.Enabled) {
    if (-not $Summary) { Write-Host '[INFO] Artifact locking is disabled in this workspace.' -ForegroundColor Gray }
    exit 0
}

$locks = @()
if (Test-Path $config.StorePath) {
    $locks = Invoke-LockStoreTransaction -StorePath $config.StorePath -Body {
        param($current)
        return @{ Result = @($current) }
    }
}
$locks = @($locks)

if ($locks.Count -eq 0) {
    if (-not $Summary) { Write-Host '[INFO] No active artifact locks.' -ForegroundColor Gray }
    exit 0
}

$rows = @()
foreach ($lock in $locks) {
    $age = Get-LockAgeMinutes -Lock $lock
    $rows += [pscustomobject]@{
        Path       = $lock.path
        Holder     = $lock.holder
        SessionId  = $lock.sessionId
        AgeMinutes = $age
        Expired    = ($age -gt $config.TtlMinutes)
    }
}

if ($Summary) {
    $expiredCount = @($rows | Where-Object { $_.Expired }).Count
    $names = ($rows | ForEach-Object { $_.Path }) -join ', '
    Write-Host "Artifact locks: $($rows.Count) active ($expiredCount expired, TTL $($config.TtlMinutes) min) — $names"
    exit 0
}

$rows | Sort-Object AgeMinutes -Descending | Format-Table Path, Holder, AgeMinutes, Expired, SessionId -AutoSize | Out-String -Width 200 | Write-Host
Write-Host "TTL: $($config.TtlMinutes) min. Expired locks are taken over automatically at the next checkout; a FRESH foreign lock is only released via Remove-ArtifactLock.ps1 with human approval." -ForegroundColor Gray
exit 0
