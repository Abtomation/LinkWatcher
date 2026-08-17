<#
.SYNOPSIS
    Warn-first pre-commit / CI guard against unfilled TODO placeholders in open Pending Migration Entries (PF-IMP-1943).

.DESCRIPTION
    New-PendingMigration.ps1 scaffolds entry prose as `<!-- TODO -->` placeholders by design
    (Direct mode is scaffold-now-fill-later), and the fill obligation lives only in prose
    (Structure Change Step 14.5). Nothing between authoring and apply time verified it was
    met: in PRJ-003's first Mode C drain, 3 of 25 entries reached the applying session with
    TODO markers still in Migration Steps, Expected Outcome and Rollback Implications
    (PF-FEE-1760) — and Expected Outcome doubles as the entry's validation, so its absence
    removes the only objective completion criterion; the operator infers the acceptance
    criteria, and a wrong inference is recorded as a resolved migration against an unverified
    change. When this guard was filed the same class stood at 16 live markers across the
    PRJ-001 and PRJ-002 open ledgers.

    The failure is SILENT at the point it happens — the authoring session ends believing the
    entry complete, and the omission surfaces weeks later in another project's cwd — which is
    why the fix is a detector rather than more prose (PF-PRO-059 two-strikes). The filing-time
    TODO report inside New-PendingMigration.ps1 (same IMP) covers the authoring moment; this
    guard is the ship-time backstop covering every route into a ledger (direct scaffold,
    batch, hand-edit, amend).

    Scans every project's OPEN ledger (per-project-migrations/<PRJ-NNN>/pending-migrations.md)
    for TODO markers, naming the entry each marker sits in. Archives are not scanned — a
    drained entry's markers are terminal history. In a rolled-out project no central tree is
    committed, so the guard exits 0 without scanning.

    Wired into .pre-commit-config.yaml as the `pending-migration-todos` hook.

.PARAMETER CentralRoot
    Path to the process-framework-central tree. Defaults to $env:FRAMEWORK_CENTRAL_OVERRIDE
    when set, else this workspace's own process-framework-central found by walking up from the
    script's location.

.PARAMETER Blocking
    Exit non-zero when findings exist. Default is warn-first (report, exit 0), matching the
    staged promotion the other fleet gates follow (PF-IMP-1211).

.NOTES
    Exit codes:
        0 = no TODO markers in any open ledger (or no central tree here), or findings in warn-first mode
        1 = findings, and -Blocking was passed
#>

[CmdletBinding()]
param(
    [string]$CentralRoot,
    [switch]$Blocking
)

$ErrorActionPreference = 'Continue'

# --- resolve the central tree: parameter > override env var > walk-up discovery ---

if (-not $CentralRoot) {
    if ($env:FRAMEWORK_CENTRAL_OVERRIDE) {
        $CentralRoot = $env:FRAMEWORK_CENTRAL_OVERRIDE
    }
    else {
        $dir = $PSScriptRoot
        while ($dir) {
            $candidate = Join-Path -Path $dir -ChildPath 'process-framework-central'
            if (Test-Path -LiteralPath $candidate) { $CentralRoot = $candidate; break }
            $dir = Split-Path -Parent $dir
        }
    }
}
if (-not $CentralRoot -or -not (Test-Path -LiteralPath $CentralRoot)) {
    exit 0   # no central tree here (rolled-out project) — nothing to check
}

$migrationsRoot = Join-Path -Path $CentralRoot -ChildPath 'per-project-migrations'
if (-not (Test-Path -LiteralPath $migrationsRoot)) { exit 0 }

# --- scan each open ledger; resolved blocks relocate to archive/ (PF-IMP-983), so every ---
# --- marker found here sits in an entry that has not yet drained                        ---

$findings = @()
foreach ($projectDir in @(Get-ChildItem -LiteralPath $migrationsRoot -Directory)) {
    $ledger = Join-Path -Path $projectDir.FullName -ChildPath 'pending-migrations.md'
    if (-not (Test-Path -LiteralPath $ledger)) { continue }

    # Count markers per entry so the report names where the fill work sits.
    $entries = [ordered]@{}
    $current = '(file preamble)'
    foreach ($line in @(Get-Content -LiteralPath $ledger -ErrorAction SilentlyContinue)) {
        if ($line -match '^###\s+(MIG-\d+)\s*:') { $current = $Matches[1]; continue }
        if ($line -match '<!--\s*TODO') {
            if (-not $entries.Contains($current)) { $entries[$current] = 0 }
            $entries[$current]++
        }
    }

    if ($entries.Count -gt 0) {
        $findings += [pscustomobject]@{
            Project = $projectDir.Name
            Ledger  = $ledger
            Detail  = (@($entries.GetEnumerator() | ForEach-Object { "$($_.Key) ($($_.Value))" }) -join ', ')
        }
    }
}

if ($findings.Count -eq 0) { exit 0 }

Write-Host ""
Write-Host "WARNING: unfilled TODO placeholders in open pending-migration entries" -ForegroundColor Yellow
Write-Host ""
foreach ($f in $findings) {
    Write-Host ("  {0}: {1}" -f $f.Project, $f.Detail) -ForegroundColor Yellow
    Write-Host ("      {0}" -f $f.Ledger) -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "An entry that ships with TODO markers reaches its Framework Rollout Mode C applying" -ForegroundColor Yellow
Write-Host "session as written - an unfilled Expected Outcome removes the entry's only objective" -ForegroundColor Yellow
Write-Host "completion criterion, so the operator must infer the acceptance criteria (the" -ForegroundColor Yellow
Write-Host "PRJ-003 first-drain incident, PF-IMP-1943)." -ForegroundColor Yellow
Write-Host ""
Write-Host "Fill the named sections while the authoring context is fresh; next time, batch mode" -ForegroundColor DarkGray
Write-Host "(New-PendingMigration.ps1 -BatchFile) accepts the prose up-front." -ForegroundColor DarkGray
Write-Host ""

if ($Blocking) { exit 1 }
exit 0
