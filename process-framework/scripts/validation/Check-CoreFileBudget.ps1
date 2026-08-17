<#
.SYNOPSIS
    Warn-first pre-commit / CI guard against unbounded growth of core framework files — task definitions and guides — against per-file word budgets (PF-IMP-1938).

.DESCRIPTION
    Core task and guide files accrete. Every individual improvement to a task adds a defensible
    handful of words; nothing measures the aggregate, so growth is invisible until readers
    complain that a step has become too dense to follow. The class recurred three times in two
    days on one file (PF-FEE-1723, PF-FEE-1725, PF-FEE-1749, all reporting Process Improvement
    Steps 2 and 10 as "content is right, packaging is the strain"), and the two repairs the
    reports asked for had ALREADY shipped on those exact steps days earlier:

      - PF-IMP-1571 relocated the Step 10 by-edit-kind matrix to the reference companion.
      - PF-IMP-1778 relocated the Step 2 by-shape sentences to the reference companion.

    Both sit inside a monotonic climb: process-improvement-task.md went from 2,427 words
    (2026-05-28, just after its reference-companion split) to 5,464 (2026-07-30) — of the 16
    commits in the final two weeks, 14 were additive and the median IMP touch was +29 words.
    Relocation is an instance fix; the accretion refills the space faster than relocations
    empty it. This script is the class-kill: it makes the aggregate visible at the moment a
    change crosses the line, rather than after three feedback forms.

    The failure being detected is SILENT — no agent can know from inside a session that the
    file it just edited has grown 36% in a fortnight — which is why the fix is a detector and
    not another prose rule (PF-PRO-059 two-strikes).

    Budgets live in core-file-budgets.json beside this script, keyed by framework-relative
    path so the same file works in appdev (blueprint/process-framework/) and in a rolled-out
    project (process-framework/). Raising a budget is deliberate: appdev's Standing Orders
    already name "raising any size budget" as an owner-escalation door, so an over-budget
    warning resolves either by compressing the file or by an owner-approved budget bump —
    never silently.

    Guides are budgeted alongside tasks on purpose: the reference companion is the usual
    relocation target, so leaving it unbudgeted would let growth move there unmeasured.

    Word count is every whitespace-separated token in the raw file, frontmatter and code
    blocks included — a single non-gameable number rather than a prose-only estimate.

    Wired into .pre-commit-config.yaml as the `core-file-budget` hook.

.PARAMETER BudgetFile
    Path to the budget JSON. Defaults to core-file-budgets.json beside this script.

.PARAMETER Init
    Add an entry for every scanned file that has no budget yet, set to its current word count
    plus -HeadroomPercent. Existing budgets are never modified — raising one stays a
    deliberate, owner-approved edit.

.PARAMETER HeadroomPercent
    Headroom added above current size when -Init seeds a new budget. Default 5.

.PARAMETER Blocking
    Exit non-zero when findings exist. Default is warn-first (report, exit 0), matching the
    staged promotion the other fleet gates follow (PF-IMP-1211).

.NOTES
    Exit codes:
        0 = within budget, or findings reported in warn-first mode (or no budget file yet)
        1 = findings, and -Blocking was passed
#>

[CmdletBinding()]
param(
    [string]$BudgetFile,
    [switch]$Init,
    [int]$HeadroomPercent = 5,
    [switch]$Blocking
)

$ErrorActionPreference = 'Continue'

# Framework subtrees whose files carry budgets. Both live under the framework root, so the
# same relative keys resolve in appdev and in a rolled-out project.
$ScanTrees = @('tasks', 'guides')

# Generated projections carry no authored budget — their size is a function of their source.
$ExcludedNames = @('README.md')

# --- functions first: PowerShell does not hoist script-level definitions ---

function Measure-FileWord {
    param([string]$Path)
    $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($raw)) { return 0 }
    return @($raw -split '\s+' | Where-Object { $_ -ne '' }).Count
}

function Get-SectionWeight {
    # Words per '##'/'###' section, so an over-budget report can name where the bulk sits.
    param([string]$Path)

    $sections = @()
    $heading = $null
    $words = 0
    foreach ($line in @(Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue)) {
        if ($line -match '^#{2,3}\s+(.+)$') {
            if ($null -ne $heading) {
                $sections += [pscustomobject]@{ Heading = $heading; Words = $words }
            }
            $heading = $Matches[1].Trim()
            $words = 0
        }
        elseif ($null -ne $heading) {
            $words += @($line -split '\s+' | Where-Object { $_ -ne '' }).Count
        }
    }
    if ($null -ne $heading) {
        $sections += [pscustomobject]@{ Heading = $heading; Words = $words }
    }
    return $sections   # callers wrap in @(), which re-collects and handles the 1-section case
}

function Get-ScannedFile {
    # Framework-relative paths (forward slashes) of every budgetable core file.
    param([string]$Root)

    $found = @()
    foreach ($tree in $ScanTrees) {
        $treePath = Join-Path -Path $Root -ChildPath $tree
        if (-not (Test-Path -LiteralPath $treePath)) { continue }
        foreach ($item in @(Get-ChildItem -LiteralPath $treePath -Filter '*.md' -Recurse -File -ErrorAction SilentlyContinue)) {
            if ($ExcludedNames -contains $item.Name) { continue }
            $relative = $item.FullName.Substring($Root.Length).TrimStart('\', '/') -replace '\\', '/'
            $found += $relative
        }
    }
    return ($found | Sort-Object)   # callers wrap in @(), which re-collects and handles the 1-file case
}

# --- resolve the framework root: this script lives at <framework>/scripts/validation/ ---

$frameworkRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '../..')).Path
if (-not $BudgetFile) {
    $BudgetFile = Join-Path -Path $PSScriptRoot -ChildPath 'core-file-budgets.json'
}

$scanned = @(Get-ScannedFile -Root $frameworkRoot)
if ($scanned.Count -eq 0) { exit 0 }   # no core tree here — nothing to check

# --- load budgets ---

$budgets = @{}
$metadata = $null
if (Test-Path -LiteralPath $BudgetFile) {
    try {
        $parsed = Get-Content -LiteralPath $BudgetFile -Raw | ConvertFrom-Json
        $metadata = $parsed.metadata
        if ($parsed.budgets) {
            foreach ($property in $parsed.budgets.PSObject.Properties) {
                $budgets[$property.Name] = $property.Value
            }
        }
    }
    catch {
        Write-Host "ERROR: could not parse $BudgetFile - $($_.Exception.Message)" -ForegroundColor Red
        if ($Blocking) { exit 1 }
        exit 0
    }
}
elseif (-not $Init) {
    Write-Host "No budget file at $BudgetFile - seed one with: Check-CoreFileBudget.ps1 -Init" -ForegroundColor DarkGray
    exit 0
}

# --- -Init: seed only the files that have no budget yet; never touch an existing one ---

if ($Init) {
    $added = @()
    $today = (Get-Date).ToString('yyyy-MM-dd')
    foreach ($relative in $scanned) {
        if ($budgets.ContainsKey($relative)) { continue }
        $current = Measure-FileWord -Path (Join-Path -Path $frameworkRoot -ChildPath $relative)
        $budget = [int][math]::Ceiling($current * (1 + ($HeadroomPercent / 100.0)))
        $budgets[$relative] = [pscustomobject]@{ words = $budget; set = $today }
        $added += [pscustomobject]@{ Path = $relative; Current = $current; Budget = $budget }
    }

    if (-not $metadata) {
        $metadata = [pscustomobject]@{
            description    = 'Per-file word budgets for core framework files (task definitions and guides), enforced warn-first by Check-CoreFileBudget.ps1 (PF-IMP-1938).'
            policy         = 'Raising a budget is an owner-escalation door under the workspace Standing Orders. Resolve an over-budget warning by compressing the file, or by a deliberate owner-approved bump recorded here - never silently.'
            counting       = 'Whitespace-separated tokens of the raw file, frontmatter and code blocks included.'
            created        = $today
        }
    }
    $metadata | Add-Member -NotePropertyName 'updated' -NotePropertyValue $today -Force

    $ordered = [ordered]@{}
    foreach ($key in ($budgets.Keys | Sort-Object)) { $ordered[$key] = $budgets[$key] }
    $payload = [ordered]@{ metadata = $metadata; budgets = $ordered }
    $payload | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $BudgetFile -Encoding UTF8

    if ($added.Count -eq 0) {
        Write-Host "All $($scanned.Count) core file(s) already budgeted - nothing seeded." -ForegroundColor Green
    }
    else {
        Write-Host "Seeded $($added.Count) budget(s) at current size +$HeadroomPercent% headroom:" -ForegroundColor Green
        foreach ($item in ($added | Sort-Object -Property Current -Descending)) {
            Write-Host ("    {0,6} -> {1,6}   {2}" -f $item.Current, $item.Budget, $item.Path) -ForegroundColor DarkGray
        }
    }
    Write-Host ""
}

# --- measure against budget ---

$over = @()
$unbudgeted = @()
foreach ($relative in $scanned) {
    if (-not $budgets.ContainsKey($relative)) {
        $unbudgeted += $relative
        continue
    }
    $budget = [int]$budgets[$relative].words
    if ($budget -le 0) { continue }
    $current = Measure-FileWord -Path (Join-Path -Path $frameworkRoot -ChildPath $relative)
    if ($current -gt $budget) {
        $over += [pscustomobject]@{
            Path    = $relative
            Budget  = $budget
            Current = $current
            Over    = $current - $budget
            Percent = [math]::Round((($current - $budget) / [double]$budget) * 100, 1)
            Set     = $budgets[$relative].set
        }
    }
}

if ($over.Count -eq 0) {
    if ($unbudgeted.Count -gt 0) {
        Write-Host ("Core file budgets: OK ({0} budgeted, {1} not yet budgeted - seed with -Init)" -f ($scanned.Count - $unbudgeted.Count), $unbudgeted.Count) -ForegroundColor DarkGray
    }
    exit 0
}

Write-Host ""
Write-Host "WARNING: core framework files are over their size budget" -ForegroundColor Yellow
Write-Host ""

foreach ($item in ($over | Sort-Object -Property Over -Descending)) {
    Write-Host ("  {0}" -f $item.Path) -ForegroundColor Yellow
    Write-Host ("      budget {0} (set {1})   now {2}   over by {3} (+{4}%)" -f $item.Budget, $item.Set, $item.Current, $item.Over, $item.Percent) -ForegroundColor Yellow

    $top = @(Get-SectionWeight -Path (Join-Path -Path $frameworkRoot -ChildPath $item.Path) |
        Sort-Object -Property Words -Descending | Select-Object -First 3)
    if ($top.Count -gt 0) {
        $summary = ($top | ForEach-Object { "{0} ({1}w)" -f $_.Heading, $_.Words }) -join ', '
        Write-Host ("      bulk sits in: {0}" -f $summary) -ForegroundColor DarkGray
    }
    Write-Host ""
}

if ($unbudgeted.Count -gt 0) {
    Write-Host ("  ({0} scanned file(s) carry no budget yet - seed with -Init)" -f $unbudgeted.Count) -ForegroundColor DarkGray
    Write-Host ""
}

Write-Host "Every improvement to a core file adds a defensible handful of words; nothing else" -ForegroundColor Yellow
Write-Host "measures the aggregate, so density complaints arrive only after readers stumble." -ForegroundColor Yellow
Write-Host "Resolve by compressing the file, or by an owner-approved budget bump in" -ForegroundColor Yellow
Write-Host "process-framework/scripts/validation/core-file-budgets.json - raising a budget is an" -ForegroundColor Yellow
Write-Host "escalation door under the workspace Standing Orders, never a silent edit." -ForegroundColor Yellow
Write-Host ""
Write-Host "Prior instance fixes that did not hold: PF-IMP-1571 and PF-IMP-1778 both relocated" -ForegroundColor DarkGray
Write-Host "content out of process-improvement-task.md; it grew 36% in the fortnight around them." -ForegroundColor DarkGray
Write-Host ""

if ($Blocking) { exit 1 }
exit 0
