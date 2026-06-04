<#
.SYNOPSIS
Cross-feature query for design artifacts recorded in feature state files.

.DESCRIPTION
Walks doc/state-tracking/features/*-implementation-state.md, parses each file's
"### Design Documentation" table, and emits a flat row set:
  FeatureId | Document | Type | Status | Location | LastUpdated

This script answers cross-feature questions that pre-2026-05-07 were served by
master columns in feature-tracking.md (FDD / TDD / Test Spec / ...). Those
columns are dropped per PF-PRO-002 — per-feature design artifacts now live
exclusively in state files' §4 Documentation Inventory.

.PARAMETER Feature
Filter to a feature ID. Wildcard match (PowerShell -like). Default: all.

.PARAMETER Type
Filter by artifact identity. Wildcard match, case-insensitive. Matches against
BOTH the Document cell and the Type cell — necessary because the project's
state files have heterogeneous prose in Type ("Functional Design Document"
vs. "FDD") while the Document cell consistently carries the PD-XXX-NNN ID
pattern. Examples: "*FDD*" finds rows with PD-FDD-NNN OR "FDD" in Type;
"*Schema*" finds PD-SCH-NNN OR "Schema" in Type.

.PARAMETER Status
Filter by the artifact Status cell. Wildcard match. Examples: "*Created*",
"*Needs*".

.PARAMETER Format
Output format: Table (default), Json, Csv.

.PARAMETER ProjectRoot
Optional override; defaults to Get-ProjectRoot.

.EXAMPLE
.\Get-FeatureDesignArtifacts.ps1
# All design artifacts across all features

.EXAMPLE
.\Get-FeatureDesignArtifacts.ps1 -Type "*FDD*"
# Which features have an FDD?

.EXAMPLE
.\Get-FeatureDesignArtifacts.ps1 -Feature 1.1.3 -Format Json
# JSON dump for one feature

.EXAMPLE
.\Get-FeatureDesignArtifacts.ps1 -Format Csv > artifacts.csv
# Bulk export for spreadsheet review

.NOTES
Script ID: PF-PRO-002 Phase 1 helper (cross-feature query parity replacement
for the dropped FDD/TDD/Test Spec master columns). Created 2026-05-07.
#>

[CmdletBinding()]
param(
    [string]$Feature = "*",
    [string]$Type = "*",
    [string]$Status = "*",
    [ValidateSet("Table", "Json", "Csv")]
    [string]$Format = "Table",
    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'

# Imports — Common-ScriptHelpers/Core for Get-ProjectRoot, TableOperations for
# the section-scoped table parser. Pure read-only operation; no module side effects.
$scriptDir = $PSScriptRoot
Import-Module (Join-Path $scriptDir "Common-ScriptHelpers/Core.psm1") -Force
Import-Module (Join-Path $scriptDir "Common-ScriptHelpers/TableOperations.psm1") -Force

if (-not $ProjectRoot) { $ProjectRoot = Get-ProjectRoot }
$featuresDir = Join-Path $ProjectRoot "doc/state-tracking/features"
if (-not (Test-Path $featuresDir)) {
    Write-Error "Features directory not found: $featuresDir"
    exit 1
}

$rows = New-Object System.Collections.Generic.List[object]
$featureIdRegex = '^([0-9]+\.[0-9]+\.[0-9]+)-.*-implementation-state\.md$'
$stateFiles = Get-ChildItem -Path $featuresDir -Filter "*-implementation-state.md" -File `
    | Where-Object { $_.Name -match $featureIdRegex }

foreach ($f in $stateFiles) {
    [void]($f.Name -match $featureIdRegex)
    $featureId = $Matches[1]
    if ($featureId -notlike $Feature) { continue }

    $content = Get-Content -Path $f.FullName -Raw
    $tableRows = ConvertFrom-MarkdownTable `
        -Content $content `
        -Section "### Design Documentation" `
        -WarningAction SilentlyContinue

    foreach ($r in $tableRows) {
        $row = [PSCustomObject]@{
            FeatureId   = $featureId
            Document    = $r.Document
            Type        = $r.Type
            Status      = $r.Status
            Location    = $r.Location
            LastUpdated = $r.'Last Updated'
        }
        if ($Type -ne "*") {
            # Match against Document cell OR Type cell — Document carries the
            # canonical PD-XXX-NNN identity; Type carries heterogeneous prose.
            $typeMatch = ($row.Type -like $Type) -or ($row.Document -like $Type)
            if (-not $typeMatch) { continue }
        }
        if ($Status -ne "*" -and $row.Status -notlike $Status) { continue }
        $rows.Add($row) | Out-Null
    }
}

switch ($Format) {
    "Table" {
        if ($rows.Count -eq 0) {
            Write-Host "No artifacts match the filter (Feature=$Feature, Type=$Type, Status=$Status)." -ForegroundColor Yellow
            exit 0
        }
        $rows | Format-Table -AutoSize -Wrap
        $featureCount = ($rows | Select-Object -ExpandProperty FeatureId -Unique).Count
        Write-Host "`n$($rows.Count) artifact(s) across $featureCount feature(s)." -ForegroundColor Cyan
    }
    "Json" {
        $rows | ConvertTo-Json -Depth 4
    }
    "Csv" {
        $rows | ConvertTo-Csv -NoTypeInformation
    }
}
