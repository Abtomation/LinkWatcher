#!/usr/bin/env pwsh

<#
.SYNOPSIS
Atomically updates validation tracking state files after a validation session.

.DESCRIPTION
Updates a validation tracking file in a single atomic read-modify-write cycle,
eliminating the manual Read-Edit-Write cycle that caused concurrent access issues
during parallel validation sessions (IMP-449).

Updates three sections of the tracking file:
1. Feature-by-Feature Progress — marks features as validated with date and report link
2. Overall Progress — recalculates Items Validated and Reports Generated counters
3. Validation Reports Registry — adds report entry to the dimension section

Also recalculates per-feature Overall Status and updates frontmatter date.

.PARAMETER TrackingFile
Path to the validation tracking state file (e.g., doc/state-tracking/validation/validation-tracking-4.md).
Can be absolute or relative to the project root.

.PARAMETER Dimension
The validation dimension being reported.

.PARAMETER FeatureIds
Array of feature IDs covered by this validation report.

.PARAMETER ReportId
The validation report ID (e.g., "PD-VAL-083").

.PARAMETER ReportPath
Path to the validation report file, relative to project root with leading slash
(e.g., "/doc/validation/reports/architectural-consistency/PD-VAL-083-report.md").

.PARAMETER Score
Dimension score string (e.g., "2.88/3.0"). Optional.

.PARAMETER ReportStatus
Report pass/fail status. Defaults to "PASS".

.PARAMETER Issues
Issue summary string (e.g., "0 High, 1 Medium, 3 Low"). Optional.

.PARAMETER Actions
Action summary for the registry table. Optional.

.PARAMETER Date
Validation date in YYYY-MM-DD format. Defaults to today.

.EXAMPLE
Update-ValidationReportState.ps1 -TrackingFile "doc/state-tracking/validation/validation-tracking-4.md" `
    -Dimension "Architectural Consistency" -FeatureIds @("0.1.1","0.1.2","0.1.3","1.1.1") `
    -ReportId "PD-VAL-083" -ReportPath "/doc/validation/reports/architectural-consistency/PD-VAL-083-report.md" `
    -Score "2.88/3.0" -Issues "0 High, 0 Medium, 3 Low" -Actions "No immediate actions required"

.EXAMPLE
# Preview changes without modifying the file
Update-ValidationReportState.ps1 -TrackingFile "doc/state-tracking/validation/validation-tracking-4.md" `
    -Dimension "Code Quality & Standards" -FeatureIds @("2.1.1","2.2.1","3.1.1","6.1.1") `
    -ReportId "PD-VAL-084" -ReportPath "/doc/validation/reports/code-quality/PD-VAL-084-report.md" `
    -WhatIf

.NOTES
Version: 2.0
Created: 2025-08-23
Rewritten: 2026-04-10
Addresses: IMP-449 (Concurrent access during parallel validation sessions)
Pattern: Single read-modify-write cycle following Update-ProcessImprovement.ps1
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$TrackingFile,

    [Parameter(Mandatory)]
    [ValidateSet(
        "Architectural Consistency",
        "Code Quality & Standards",
        "Integration & Dependencies",
        "Documentation Alignment",
        "Extensibility & Maintainability",
        "AI Agent Continuity",
        "Security & Data Protection",
        "Performance & Scalability",
        "Observability",
        "Accessibility / UX Compliance",
        "Data Integrity"
    )]
    [string]$Dimension,

    [Parameter(Mandatory)]
    [string[]]$FeatureIds,

    [Parameter(Mandatory)]
    [string]$ReportId,

    [Parameter(Mandatory)]
    [string]$ReportPath,

    [string]$Score,
    [string]$ReportStatus = "PASS",
    [string]$Issues,
    [string]$Actions,
    [string]$Date
)

# --- Module import ---
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$dir = $scriptDir
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
if ($dir) {
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
}

# --- Configuration ---
$ScriptName = "Update-ValidationReportState.ps1"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"
$CurrentTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

if (-not $Date) { $Date = $CurrentDate }

# Resolve tracking file path
if (Get-Command Get-ProjectRoot -ErrorAction SilentlyContinue) {
    $ProjectRoot = Get-ProjectRoot
} else {
    $ProjectRoot = (Get-Location).Path
}

if ([System.IO.Path]::IsPathRooted($TrackingFile)) {
    $ResolvedTrackingFile = $TrackingFile
} else {
    $ResolvedTrackingFile = Join-Path $ProjectRoot $TrackingFile
}

# Dimension-to-column-header mapping
$DimensionColumnHeaders = @{
    "Architectural Consistency"       = "Arch"
    "Code Quality & Standards"        = "Quality"
    "Integration & Dependencies"      = "Integration"
    "Documentation Alignment"         = "Docs"
    "Extensibility & Maintainability" = "Extensibility"
    "AI Agent Continuity"             = "AI Continuity"
    "Security & Data Protection"      = "Security"
    "Performance & Scalability"       = "Performance"
    "Observability"                   = "Observability"
    "Accessibility / UX Compliance"   = "Accessibility"
    "Data Integrity"                  = "Data Integrity"
}

# --- Logging ---
function Write-Log {
    param([string]$Level, [string]$Message)
    $color = switch ($Level) {
        "INFO"    { "Cyan" }
        "SUCCESS" { "Green" }
        "WARN"    { "Yellow" }
        "ERROR"   { "Red" }
        default   { "White" }
    }
    Write-Host "[$CurrentTimestamp] [$Level] $Message" -ForegroundColor $color
}

# --- Prerequisites ---
function Test-Prerequisites {
    if (-not (Test-Path $ResolvedTrackingFile)) {
        Write-Log "ERROR" "Tracking file not found: $ResolvedTrackingFile"
        return $false
    }
    return $true
}

# --- Transformation Functions ---
# Each takes a lines array and returns a modified lines array.

function Update-FeatureByFeatureCells {
    param([string[]]$Lines)

    $columnHeader = $DimensionColumnHeaders[$Dimension]
    $cellValue = "[$Date]($ReportPath)"

    # Find the Feature-by-Feature table header
    $headerIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\|\s*Feature\s*\|' -and $Lines[$i] -match 'Overall') {
            $headerIdx = $i
            break
        }
    }

    if ($headerIdx -eq -1) {
        Write-Log "WARN" "Could not find Feature-by-Feature Progress table"
        return $Lines
    }

    # Parse column headers to find target column index
    $headers = $Lines[$headerIdx] -split '\|' | ForEach-Object { $_.Trim() }
    # After split: [0]="" [1]="Feature" [2]="Arch" ... [N]="Overall" [N+1]=""
    $columnIdx = -1
    for ($c = 0; $c -lt $headers.Count; $c++) {
        if ($headers[$c] -eq $columnHeader) {
            $columnIdx = $c
            break
        }
    }

    if ($columnIdx -eq -1) {
        Write-Log "WARN" "Could not find column '$columnHeader' in Feature-by-Feature table"
        return $Lines
    }

    # Update feature rows (start after header + separator)
    for ($i = $headerIdx + 2; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        if ($line -notmatch '^\|') { break }

        $cells = $line -split '\|'
        $featureCell = $cells[1].Trim()

        $matched = $false
        foreach ($fid in $FeatureIds) {
            if ($featureCell -match [regex]::Escape($fid)) {
                $matched = $true
                break
            }
        }

        if ($matched -and $columnIdx -lt $cells.Count) {
            $currentValue = $cells[$columnIdx].Trim()

            if ($currentValue -match '^\u2b33|^\u23f3|Pending|In Progress') {
                # Cell is pending or in progress — update it
                $cells[$columnIdx] = " $cellValue "
                $Lines[$i] = $cells -join '|'
                Write-Log "SUCCESS" "Updated: $featureCell [$columnHeader] -> $cellValue"
            } elseif ($currentValue -eq 'N/A') {
                Write-Log "INFO" "Skipped: $featureCell [$columnHeader] is N/A"
            } else {
                Write-Log "INFO" "Skipped: $featureCell [$columnHeader] already set: $currentValue"
            }
        }
    }

    return $Lines
}

function Update-OverallProgress {
    param([string[]]$Lines)

    $columnHeader = $DimensionColumnHeaders[$Dimension]

    # First, gather validated counts from Feature-by-Feature table
    $fbfHeaderIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\|\s*Feature\s*\|' -and $Lines[$i] -match 'Overall') {
            $fbfHeaderIdx = $i
            break
        }
    }

    if ($fbfHeaderIdx -eq -1) { return $Lines }

    # Find column index in Feature-by-Feature table
    $fbfHeaders = $Lines[$fbfHeaderIdx] -split '\|' | ForEach-Object { $_.Trim() }
    $fbfColumnIdx = -1
    for ($c = 0; $c -lt $fbfHeaders.Count; $c++) {
        if ($fbfHeaders[$c] -eq $columnHeader) {
            $fbfColumnIdx = $c
            break
        }
    }

    if ($fbfColumnIdx -eq -1) { return $Lines }

    # Count validated and total applicable from Feature-by-Feature column
    $totalApplicable = 0
    $totalValidated = 0
    for ($i = $fbfHeaderIdx + 2; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -notmatch '^\|') { break }
        $cells = $Lines[$i] -split '\|'
        if ($fbfColumnIdx -lt $cells.Count) {
            $cellValue = $cells[$fbfColumnIdx].Trim()
            if ($cellValue -ne 'N/A' -and $cellValue -ne '') {
                $totalApplicable++
                # A cell is "validated" if it contains a date link [YYYY-MM-DD](...)
                if ($cellValue -match '^\[?\d{4}-\d{2}-\d{2}') {
                    $totalValidated++
                }
            }
        }
    }

    # Find the Overall Progress table and update the dimension row
    $progressHeaderIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\|\s*Validation Type\s*\|') {
            $progressHeaderIdx = $i
            break
        }
    }

    if ($progressHeaderIdx -eq -1) {
        Write-Log "WARN" "Could not find Overall Progress table"
        return $Lines
    }

    # Find the row matching this dimension (handles number prefix like "1. Architectural Consistency")
    $dimPattern = [regex]::Escape($Dimension)
    for ($i = $progressHeaderIdx + 2; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -notmatch '^\|') { break }

        if ($Lines[$i] -match $dimPattern) {
            $cells = $Lines[$i] -split '\|'
            # Expected columns: [0]="" [1]=DimensionName [2]=ItemsValidated [3]=ReportsGenerated [4]=Status [5]=NextSession [6]=""

            # Update Items Validated
            $cells[2] = " $totalValidated/$totalApplicable "

            # Update Reports Generated (increment only if report is new — check registry)
            $escapedId = [regex]::Escape($ReportId)
            $reportAlreadyExists = ($Lines | Where-Object { $_ -match $escapedId }).Count -gt 0
            $currentReports = 0
            if ($cells[3].Trim() -match '^\d+$') {
                $currentReports = [int]$cells[3].Trim()
            }
            if (-not $reportAlreadyExists) {
                $cells[3] = " $($currentReports + 1) "
            } else {
                $cells[3] = " $currentReports "
            }

            # Update Status
            if ($totalValidated -ge $totalApplicable) {
                $cells[4] = " COMPLETED "
                $cells[5] = " — "
            } else {
                $cells[4] = " IN_PROGRESS "
            }

            $Lines[$i] = $cells -join '|'
            $finalReports = if (-not $reportAlreadyExists) { $currentReports + 1 } else { $currentReports }
            Write-Log "SUCCESS" "Overall Progress: $Dimension -> $totalValidated/$totalApplicable validated, $finalReports reports"
            break
        }
    }

    return $Lines
}

function Add-RegistryEntry {
    param([string[]]$Lines)

    # Check if report already exists in registry (idempotent)
    $escapedId = [regex]::Escape($ReportId)
    foreach ($line in $Lines) {
        if ($line -match $escapedId) {
            Write-Log "INFO" "Registry entry for $ReportId already exists — skipping"
            return $Lines
        }
    }

    # Find the registry section for this dimension
    $dimPattern = [regex]::Escape($Dimension)
    $sectionIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match "^###\s+\d*\.?\s*$dimPattern\s+Validation Reports") {
            $sectionIdx = $i
            break
        }
    }

    if ($sectionIdx -eq -1) {
        Write-Log "WARN" "Could not find registry section for '$Dimension Validation Reports'"
        return $Lines
    }

    # Find the table under this section header
    $tableHeaderIdx = -1
    for ($i = $sectionIdx + 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\|\s*Report ID\s*\|') {
            $tableHeaderIdx = $i
            break
        }
        if ($Lines[$i] -match '^###') { break }  # Hit next section
    }

    if ($tableHeaderIdx -eq -1) {
        Write-Log "WARN" "Could not find registry table under '$Dimension Validation Reports'"
        return $Lines
    }

    # Find the insertion point — after the last data row (or after separator if empty)
    $insertIdx = $tableHeaderIdx + 2  # After header + separator
    for ($i = $tableHeaderIdx + 2; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\|') {
            $insertIdx = $i + 1  # After this data row
        } else {
            break
        }
    }

    # Build the new row
    $featureList = $FeatureIds -join ', '
    $scoreVal = if ($Score) { $Score } else { "—" }
    $issuesVal = if ($Issues) { $Issues } else { "—" }
    $actionsVal = if ($Actions) { $Actions } else { "—" }
    $newRow = "| [$ReportId]($ReportPath) | $featureList | $Date | $scoreVal | $ReportStatus | $issuesVal | $actionsVal |"

    # Insert the new row
    $result = [System.Collections.ArrayList]::new($Lines)
    $result.Insert($insertIdx, $newRow)
    Write-Log "SUCCESS" "Added registry entry: $ReportId ($featureList)"

    return $result.ToArray()
}

function Update-FeatureOverallStatus {
    param([string[]]$Lines)

    # Find the Feature-by-Feature table
    $headerIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\|\s*Feature\s*\|' -and $Lines[$i] -match 'Overall') {
            $headerIdx = $i
            break
        }
    }

    if ($headerIdx -eq -1) { return $Lines }

    $headers = $Lines[$headerIdx] -split '\|' | ForEach-Object { $_.Trim() }

    # Find the Overall column index
    $overallIdx = -1
    for ($c = 0; $c -lt $headers.Count; $c++) {
        if ($headers[$c] -eq 'Overall') {
            $overallIdx = $c
            break
        }
    }

    if ($overallIdx -eq -1) { return $Lines }

    # For each feature row, check if this feature was in our update set
    for ($i = $headerIdx + 2; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -notmatch '^\|') { break }

        $cells = $Lines[$i] -split '\|'
        $featureCell = $cells[1].Trim()

        $isTargetFeature = $false
        foreach ($fid in $FeatureIds) {
            if ($featureCell -match [regex]::Escape($fid)) {
                $isTargetFeature = $true
                break
            }
        }

        if (-not $isTargetFeature) { continue }

        # Check all dimension cells (columns 2 through overallIdx-1)
        $allDone = $true
        $anyFailed = $false
        for ($c = 2; $c -lt $overallIdx; $c++) {
            if ($c -ge $cells.Count) { continue }
            $val = $cells[$c].Trim()
            if ($val -eq 'N/A' -or $val -eq '') { continue }
            if ($val -match '^\[?\d{4}-\d{2}-\d{2}') {
                # Validated
            } elseif ($val -match 'Failed') {
                $anyFailed = $true
                $allDone = $false
            } else {
                $allDone = $false
            }
        }

        $newStatus = if ($anyFailed) { "ISSUES_FOUND" }
                     elseif ($allDone) { "VALIDATED" }
                     else { "IN_PROGRESS" }

        $currentStatus = $cells[$overallIdx].Trim()
        if ($currentStatus -ne $newStatus) {
            $cells[$overallIdx] = " $newStatus "
            $Lines[$i] = $cells -join '|'
            Write-Log "SUCCESS" "Feature $featureCell Overall: $currentStatus -> $newStatus"
        }
    }

    return $Lines
}

function Update-FrontmatterDate {
    param([string[]]$Lines)

    for ($i = 0; $i -lt [Math]::Min(20, $Lines.Count); $i++) {
        if ($Lines[$i] -match '^updated:\s*\d{4}-\d{2}-\d{2}') {
            $Lines[$i] = "updated: $CurrentDate"
            Write-Log "SUCCESS" "Updated frontmatter date to $CurrentDate"
            break
        }
    }

    return $Lines
}

# --- Main ---

Write-Log "INFO" "Starting Validation Report State Update — $ScriptName"
Write-Log "INFO" "Tracking file: $ResolvedTrackingFile"
Write-Log "INFO" "Dimension: $Dimension"
Write-Log "INFO" "Features: $($FeatureIds -join ', ')"
Write-Log "INFO" "Report: $ReportId"

if (-not (Test-Prerequisites)) {
    exit 1
}

# Single read
$lines = Get-Content $ResolvedTrackingFile -Encoding UTF8

# Chain transformations
$lines = Update-FeatureByFeatureCells -Lines $lines
$lines = Update-OverallProgress -Lines $lines
$lines = Add-RegistryEntry -Lines $lines
$lines = Update-FeatureOverallStatus -Lines $lines
$lines = Update-FrontmatterDate -Lines $lines

# Single write
if ($PSCmdlet.ShouldProcess($ResolvedTrackingFile, "Update validation tracking for $Dimension ($ReportId)")) {
    $lines | Set-Content $ResolvedTrackingFile -Encoding UTF8
    Write-Log "SUCCESS" "Validation tracking updated successfully"
    Write-Log "INFO" "Updated file: $ResolvedTrackingFile"
} else {
    Write-Log "INFO" "WhatIf mode — no changes written"
}
