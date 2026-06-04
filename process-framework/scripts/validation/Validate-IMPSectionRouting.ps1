<#
.SYNOPSIS
    Static cross-check: every -MoveToSection ValidateSet member in Update-ProcessImprovement.ps1
    has a matching destination branch in Build-ColumnMappingForMove (PF-IMP-859).

.DESCRIPTION
    Update-ProcessImprovement.ps1 has two independent declarations that must stay
    in sync:

      (a) The -MoveToSection ValidateSet at the parameter declaration, which
          enumerates accepted destination short-names.
      (b) The Build-ColumnMappingForMove function's destination branches, which
          define the column-schema transformation per destination.

    When these drift — e.g., a new destination is added to (a) without a matching
    branch in (b) — moves to the new destination silently fall through to a
    no-mapping default and the row lands without the expected column schema. This
    is the PF-IMP-852 defect class: -NewStatus Rejected routed to Section 6
    because no transition path targeted Section 7 from non-cluster sources.

    Same drift risk applies to Get-IMPCurrentSection's source-section enumeration
    versus Move-IMPBetweenSections's source handling — checked symmetrically.

    Intended use: run during code review or as a pre-commit hook against
    Update-ProcessImprovement.ps1 edits.

.PARAMETER ScriptPath
    Path to Update-ProcessImprovement.ps1. Defaults to the canonical blueprint
    location relative to this validator.

.NOTES
    Exit codes:
        0 = ValidateSet ↔ Build-ColumnMappingForMove are in sync
        1 = at least one ValidateSet member has no destination branch
        2 = malformed script (couldn't extract ValidateSet or Build-ColumnMappingForMove)
#>

[CmdletBinding()]
param(
    [string]$ScriptPath
)

$ErrorActionPreference = 'Stop'

if (-not $ScriptPath) {
    $ScriptPath = Join-Path $PSScriptRoot '..\update\Update-ProcessImprovement.ps1'
}

if (-not (Test-Path $ScriptPath)) {
    Write-Host "[ERROR] Script not found: $ScriptPath" -ForegroundColor Red
    exit 2
}

$source = Get-Content -Path $ScriptPath -Raw

# --- Extract -MoveToSection ValidateSet members ---
# Anchors on the ValidateSet immediately preceding [string]$MoveToSection to avoid
# matching unrelated ValidateSets in the same script.
$moveToSectionMatch = [regex]::Match(
    $source,
    '(?ms)\[ValidateSet\(([^\)]+)\)\]\s*\r?\n\s*\[string\]\$MoveToSection'
)
if (-not $moveToSectionMatch.Success) {
    Write-Host "[ERROR] Could not extract -MoveToSection ValidateSet from $ScriptPath" -ForegroundColor Red
    exit 2
}
$moveToSectionMembers = [regex]::Matches($moveToSectionMatch.Groups[1].Value, '"([^"]+)"') |
    ForEach-Object { $_.Groups[1].Value }

# --- Extract Build-ColumnMappingForMove destination-branch coverage ---
$buildFnMatch = [regex]::Match(
    $source,
    '(?ms)^function Build-ColumnMappingForMove \{.*?(?=^function )'
)
if (-not $buildFnMatch.Success) {
    Write-Host "[ERROR] Could not locate Build-ColumnMappingForMove function body in $ScriptPath" -ForegroundColor Red
    exit 2
}
$buildFnBody = $buildFnMatch.Value

# Collect every short-name appearing in $DestShortName -in @(...) lists OR
# in $DestShortName -eq "X" comparisons inside the function body.
$inListMatches = [regex]::Matches($buildFnBody, '\$DestShortName -in @\(([^\)]+)\)')
$inListMembers = foreach ($m in $inListMatches) {
    [regex]::Matches($m.Groups[1].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
}
$eqMembers = [regex]::Matches($buildFnBody, '\$DestShortName -eq "([^"]+)"') |
    ForEach-Object { $_.Groups[1].Value }

$coveredDestinations = @($inListMembers + $eqMembers) | Sort-Object -Unique

# --- Reconcile ---
$missing = @()
foreach ($member in $moveToSectionMembers) {
    if ($coveredDestinations -notcontains $member) {
        $missing += $member
    }
}

if ($missing.Count -gt 0) {
    Write-Host "[FAIL] Section-routing reachability drift detected in $ScriptPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "  -MoveToSection ValidateSet members  : $($moveToSectionMembers -join ', ')"
    Write-Host "  Build-ColumnMappingForMove covers   : $($coveredDestinations -join ', ')"
    Write-Host "  Missing destination branch(es)      : $($missing -join ', ')" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Add the missing branch(es) to Build-ColumnMappingForMove with the"
    Write-Host "  destination's column schema, or remove the unsupported destination"
    Write-Host "  from the -MoveToSection ValidateSet. See PF-IMP-852 for an example"
    Write-Host "  of the silent-fall-through defect this guard prevents."
    exit 1
}

Write-Host "[PASS] Section-routing reachability — every -MoveToSection member ($($moveToSectionMembers -join ', ')) has a Build-ColumnMappingForMove branch." -ForegroundColor Green
exit 0
