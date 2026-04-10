# Generate-ValidationSummary.ps1
# Generates consolidated validation summaries from multiple validation reports
# Creates strategic overview for decision-making and progress tracking

<#
.SYNOPSIS
    Generates consolidated validation summaries from multiple validation reports.

.DESCRIPTION
    This PowerShell script creates consolidated validation summaries by:
    - Aggregating data from validation reports for a specific round
    - Calculating overall codebase health scores on a 3.0 scale
    - Identifying critical issues and improvement priorities from report content
    - Creating actionable improvement roadmaps based on actual findings
    - Generating executive summaries for stakeholder communication

.PARAMETER OutputPath
    Path where the consolidated summary report will be created

.PARAMETER IncludeDetails
    Include detailed findings and recommendations in the summary

.PARAMETER ValidationTypes
    Comma-separated list of validation types to include (default: all types)

.PARAMETER FeatureFilter
    Comma-separated list of specific features to include (default: all features)

.PARAMETER SummaryType
    Type of summary to generate: Executive, Detailed, or Technical

.PARAMETER Round
    Validation round number to summarize. If omitted, auto-detects the latest round from
    doc/state-tracking/validation/ directory.

.PARAMETER OpenInEditor
    If specified, opens the created summary in the default editor

.EXAMPLE
    Generate-ValidationSummary.ps1 -IncludeDetails
    Generates a detailed summary for the latest round at the default location

.EXAMPLE
    Generate-ValidationSummary.ps1 -Round 4 -IncludeDetails
    Generates a detailed summary specifically for Round 4

.EXAMPLE
    Generate-ValidationSummary.ps1 -OutputPath "executive-summary.md" -SummaryType "Executive" -ValidationTypes "Architectural,CodeQuality"
    Generates an executive summary for specific validation types at a custom path

.NOTES
    - Requires read access to validation reports and tracking files
    - Parses the validation tracking file to identify which reports belong to the round
    - Uses 3.0 scoring scale consistent with validation reports
    - Counts issues by parsing severity columns from report tables
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeDetails,

    [Parameter(Mandatory = $false)]
    [string]$ValidationTypes = "Architectural,CodeQuality,Integration,Documentation,Extensibility,AIContinuity,Security,Performance,Observability,DataIntegrity",

    [Parameter(Mandatory = $false)]
    [string]$FeatureFilter = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Executive", "Detailed", "Technical")]
    [string]$SummaryType = "Detailed",

    [Parameter(Mandatory = $false)]
    [int]$Round = 0,

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers for Get-ProjectRoot (walk up to find module)
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
$helpersPath = Join-Path $dir "Common-ScriptHelpers.psm1"
if (Test-Path $helpersPath) {
    Import-Module $helpersPath -Force
} else {
    Write-Error "Common-ScriptHelpers.psm1 not found by walking up from: $PSScriptRoot"
    exit 1
}

# Configuration - use project-root-relative paths for reliability
$ProjectRoot = Get-ProjectRoot
$ValidationTrackingDir = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/validation"
$ReportsBasePath = Join-Path -Path $ProjectRoot -ChildPath "doc/validation/reports"
$DefaultOutputDir = Join-Path -Path $ProjectRoot -ChildPath "doc/validation/reports"
if (-not $OutputPath) {
    $OutputPath = Join-Path $DefaultOutputDir "consolidated-validation-report.md"
}

$ValidationTypeMap = @{
    "Architectural"  = "architectural-consistency"
    "CodeQuality"    = "code-quality"
    "Integration"    = "integration-dependencies"
    "Documentation"  = "documentation-alignment"
    "Extensibility"  = "extensibility-maintainability"
    "AIContinuity"   = "ai-agent-continuity"
    "Security"       = "security-data-protection"
    "Performance"    = "performance-scalability"
    "Observability"  = "observability"
    "DataIntegrity"  = "data-integrity"
}

$ValidationTypeDisplayNames = @{
    "Architectural"  = "Architectural Consistency"
    "CodeQuality"    = "Code Quality & Standards"
    "Integration"    = "Integration & Dependencies"
    "Documentation"  = "Documentation Alignment"
    "Extensibility"  = "Extensibility & Maintainability"
    "AIContinuity"   = "AI Agent Continuity"
    "Security"       = "Security & Data Protection"
    "Performance"    = "Performance & Scalability"
    "Observability"  = "Observability"
    "DataIntegrity"  = "Data Integrity"
}

# --- Auto-detect or validate round ---
function Find-TrackingFile {
    param([int]$RoundNumber)

    if ($RoundNumber -gt 0) {
        # Explicit round: check main dir first, then archive
        $mainPath = Join-Path $ValidationTrackingDir "validation-tracking-$RoundNumber.md"
        $archivePath = Join-Path $ValidationTrackingDir "archive/validation-tracking-$RoundNumber.md"
        if (Test-Path $mainPath) { return $mainPath }
        if (Test-Path $archivePath) { return $archivePath }
        return $null
    }

    # Auto-detect: find highest-numbered tracking file
    $trackingFiles = @()
    foreach ($dir in @($ValidationTrackingDir, (Join-Path $ValidationTrackingDir "archive"))) {
        if (Test-Path $dir) {
            $trackingFiles += Get-ChildItem $dir -Filter "validation-tracking-*.md" | ForEach-Object {
                if ($_.BaseName -match "validation-tracking-(\d+)$") {
                    [PSCustomObject]@{ Path = $_.FullName; Round = [int]$Matches[1] }
                }
            }
        }
    }
    if ($trackingFiles.Count -eq 0) { return $null }
    $latest = $trackingFiles | Sort-Object -Property Round -Descending | Select-Object -First 1
    return $latest.Path
}

# --- Extract report IDs from tracking file ---
function Get-RoundReportIds {
    param([string]$TrackingContent)

    $reportIds = @()
    # Match report IDs in the Validation Reports Registry tables: | [PD-VAL-XXX](path) |
    $matches = [regex]::Matches($TrackingContent, "\[PD-VAL-(\d+)\]\(/doc/validation/reports/")
    foreach ($m in $matches) {
        $id = "PD-VAL-$($m.Groups[1].Value)"
        if ($reportIds -notcontains $id) {
            $reportIds += $id
        }
    }
    return $reportIds
}

# --- Extract issue counts from tracking file ---
function Get-TrackingIssues {
    param([string]$TrackingContent)

    $issues = @{ High = @(); Medium = @(); Low = @() }

    # Parse High Priority Issues table: | ID | feature(s) | type | High | description | status |
    $highMatches = [regex]::Matches($TrackingContent, "\|\s*(R\d+-\S+)\s*\|[^|]+\|[^|]+\|\s*High\s*\|\s*([^|]+)\|")
    foreach ($m in $highMatches) {
        $issues.High += @{ Id = $m.Groups[1].Value; Description = $m.Groups[2].Value.Trim() }
    }

    # Parse Medium Priority Issues table: | ID | feature(s) | type | Medium | description | status |
    $mediumMatches = [regex]::Matches($TrackingContent, "\|\s*(R\d+-\S+)\s*\|[^|]+\|[^|]+\|\s*Medium\s*\|\s*([^|]+)\|")
    foreach ($m in $mediumMatches) {
        $issues.Medium += @{ Id = $m.Groups[1].Value; Description = $m.Groups[2].Value.Trim() }
    }

    return $issues
}

# --- Parse score from report content (3.0 scale) ---
function Get-ReportScore {
    param([string]$Content)

    # Try **Overall Score**: X.XX/3.0
    if ($Content -match "\*\*Overall Score\*\*:\s*(\d+\.?\d*)/3\.0") {
        return [decimal]$Matches[1]
    }
    # Try plain Overall Score: X.XX/3.0
    if ($Content -match "Overall Score[:\s]+(\d+\.?\d*)/3\.0") {
        return [decimal]$Matches[1]
    }
    return -1
}

# --- Count issues by severity from report content ---
function Get-ReportIssueCounts {
    param([string]$Content)

    $counts = @{ High = 0; Medium = 0; Low = 0 }

    # Count table rows with severity columns: | High | or | Medium | or | Low |
    $counts.High = ([regex]::Matches($Content, "\|\s*High\s*\|")).Count
    $counts.Medium = ([regex]::Matches($Content, "\|\s*Medium\s*\|")).Count
    $counts.Low = ([regex]::Matches($Content, "\|\s*Low\s*\|")).Count

    return $counts
}

# --- Extract per-feature scores from a single report ---
# Supports two table formats:
#   Format A (row-per-feature): | Feature | criteria... | Average/Overall |
#   Format B (column-per-feature): | Criterion | X.Y.Z | X.Y.Z | ... | Average |
#     with a **Feature Average** or **Dimension Average** row at the bottom
function Get-PerFeatureScoresFromReport {
    param([string]$Content)

    $scores = @{}  # feature_id -> average_score
    $lines = $Content -split "`n"

    # --- Try Format A first: row-per-feature tables ---
    # Look for tables with "| Feature |" header and "Average" or "Overall" last column
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\|\s*Feature\s*\|' -and $line -match '(Average|Overall)\s*\|') {
            $headers = $line -split '\|' | ForEach-Object { $_.Trim() }
            # Find the Average/Overall column index (last meaningful column)
            $avgColIdx = -1
            for ($c = $headers.Count - 1; $c -ge 0; $c--) {
                if ($headers[$c] -match '^(Average|Overall)$') {
                    $avgColIdx = $c
                    break
                }
            }
            if ($avgColIdx -eq -1) { continue }

            # Skip separator row
            $j = $i + 1
            if ($j -lt $lines.Count -and $lines[$j] -match '^\|\s*[-:]+') { $j++ }

            # Parse data rows
            while ($j -lt $lines.Count -and $lines[$j] -match '^\|') {
                $cells = $lines[$j] -split '\|' | ForEach-Object { $_.Trim() }
                $featureCell = if ($cells.Count -gt 1) { $cells[1] } else { "" }

                # Skip summary rows (bold **Average**, **Batch Average**, etc.)
                if ($featureCell -match '^\*\*') { $j++; continue }

                if ($featureCell -match '^(\d+\.\d+\.\d+)') {
                    $featureId = $Matches[1]
                    $avgCell = if ($avgColIdx -lt $cells.Count) { $cells[$avgColIdx] } else { "" }
                    if ($avgCell -match '(\d+\.?\d*)') {
                        $scores[$featureId] = [decimal]$Matches[1]
                    }
                }
                $j++
            }

            if ($scores.Count -gt 0) { return $scores }
        }
    }

    # --- Try Format B: column-per-feature tables ---
    # Look for tables with "| Criterion |" header where other columns are feature IDs
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\|\s*Criterion\s*\|' -and $line -match '\d+\.\d+\.\d+') {
            $headers = $line -split '\|' | ForEach-Object { $_.Trim() }

            # Extract feature IDs from column headers
            $featureColumns = @{}  # column_index -> feature_id
            for ($c = 0; $c -lt $headers.Count; $c++) {
                if ($headers[$c] -match '^(\d+\.\d+\.\d+)') {
                    $featureColumns[$c] = $Matches[1]
                }
            }
            if ($featureColumns.Count -eq 0) { continue }

            # Find the **Feature Average** or **Dimension Average** row
            $j = $i + 1
            while ($j -lt $lines.Count -and $lines[$j] -match '^\|') {
                if ($lines[$j] -match '\*\*(Feature|Dimension|Batch)\s*Average\*\*') {
                    $cells = $lines[$j] -split '\|' | ForEach-Object { $_.Trim() }
                    foreach ($colIdx in $featureColumns.Keys) {
                        $fid = $featureColumns[$colIdx]
                        $cell = if ($colIdx -lt $cells.Count) { $cells[$colIdx] } else { "" }
                        # Remove bold markers
                        $cell = $cell -replace '\*\*', ''
                        if ($cell -match '(\d+\.?\d*)') {
                            $scores[$fid] = [decimal]$Matches[1]
                        }
                    }
                    break
                }
                $j++
            }

            if ($scores.Count -gt 0) { return $scores }
        }
    }

    return $scores
}

# --- Parse feature names from tracking file's Feature Scope table ---
function Get-FeatureNamesFromTracking {
    param([string]$TrackingContent)

    $names = @{}  # feature_id -> feature_name
    $lines = $TrackingContent -split "`n"
    $inTable = $false

    foreach ($line in $lines) {
        if ($line -match '^\|\s*Feature ID\s*\|\s*Feature Name') {
            $inTable = $true
            continue
        }
        if ($inTable) {
            if ($line -match '^\|\s*[-:]+') { continue }
            if ($line -match '^\|') {
                $cells = $line -split '\|' | ForEach-Object { $_.Trim() }
                $idCell = if ($cells.Count -gt 1) { $cells[1] } else { "" }
                $nameCell = if ($cells.Count -gt 2) { $cells[2] } else { "" }
                if ($idCell -match '^\d+\.\d+\.\d+$' -and $nameCell) {
                    $names[$idCell] = $nameCell
                }
            } else {
                break
            }
        }
    }

    return $names
}

# --- Build Feature Quality Rankings table and update tracking file ---
function Update-FeatureQualityRankings {
    param(
        [hashtable]$SummaryData,
        [string]$TrackingFilePath,
        [string]$TrackingContent,
        [string]$ReportsBasePath,
        [hashtable]$ValidationTypeMap,
        [hashtable]$ValidationTypeDisplayNames,
        [string[]]$RoundReportIds
    )

    # Collect per-feature per-dimension scores
    # Structure: $featureScores[featureId][dimensionKey] = score
    $featureScores = @{}

    foreach ($dimKey in $SummaryData.ValidationTypes.Keys) {
        if (-not $ValidationTypeMap.ContainsKey($dimKey)) { continue }

        $reportsDir = Join-Path $ReportsBasePath $ValidationTypeMap[$dimKey]
        if (-not (Test-Path $reportsDir)) { continue }

        $roundReports = Get-ChildItem $reportsDir -Filter "*.md" | Where-Object {
            foreach ($id in $RoundReportIds) {
                if ($_.Name.StartsWith($id)) { return $true }
            }
            return $false
        }

        foreach ($report in $roundReports) {
            $content = Get-Content $report.FullName -Raw
            $perFeature = Get-PerFeatureScoresFromReport -Content $content

            foreach ($fid in $perFeature.Keys) {
                if (-not $featureScores.ContainsKey($fid)) {
                    $featureScores[$fid] = @{}
                }
                $featureScores[$fid][$dimKey] = $perFeature[$fid]
            }
        }
    }

    if ($featureScores.Count -eq 0) {
        Write-Host "   No per-feature scores found — skipping Feature Quality Rankings" -ForegroundColor Yellow
        return
    }

    # Get feature names from tracking file
    $featureNames = Get-FeatureNamesFromTracking -TrackingContent $TrackingContent

    # Short display names for dimensions (matching manual Round 4 style)
    $dimShortNames = @{
        "Architectural"  = "Arch"
        "CodeQuality"    = "Code Quality"
        "Integration"    = "Integration"
        "Documentation"  = "Docs"
        "Extensibility"  = "Extensibility"
        "AIContinuity"   = "AI Continuity"
        "Security"       = "Security"
        "Performance"    = "Performance"
        "Observability"  = "Observability"
        "Accessibility"  = "Accessibility"
        "DataIntegrity"  = "Data Integrity"
    }

    # Calculate overall average and find strengths/weaknesses per feature
    $rankings = @()
    foreach ($fid in $featureScores.Keys) {
        $dimScores = $featureScores[$fid]
        $allScores = $dimScores.Values | ForEach-Object { [decimal]$_ }
        $avg = ($allScores | Measure-Object -Average).Average

        # Find top strengths (highest-scoring dimensions, top 3)
        $sorted = $dimScores.GetEnumerator() | Sort-Object -Property Value -Descending
        $sortedAsc = $dimScores.GetEnumerator() | Sort-Object -Property Value

        $strengths = $sorted | Select-Object -First 3 | ForEach-Object {
            $shortName = if ($dimShortNames.ContainsKey($_.Key)) { $dimShortNames[$_.Key] } else { $_.Key }
            "$shortName ($($_.Value.ToString("F2")))"
        }

        # Find weaknesses (lowest-scoring dimensions, bottom 1-2 that are below average)
        $weakest = $sortedAsc | Select-Object -First 1
        $weakThreshold = [decimal]$weakest.Value + 0.15
        $weaknesses = $sortedAsc | Where-Object { [decimal]$_.Value -le $weakThreshold } | ForEach-Object {
            $shortName = if ($dimShortNames.ContainsKey($_.Key)) { $dimShortNames[$_.Key] } else { $_.Key }
            "$shortName ($($_.Value.ToString("F2")))"
        }

        $displayName = if ($featureNames.ContainsKey($fid)) { "$fid $($featureNames[$fid])" } else { $fid }

        $rankings += [PSCustomObject]@{
            FeatureId   = $fid
            DisplayName = $displayName
            Average     = $avg
            Strengths   = ($strengths -join ", ")
            Weaknesses  = ($weaknesses -join ", ")
        }
    }

    # Sort by average descending
    $rankings = $rankings | Sort-Object -Property Average -Descending

    # Build table rows
    $tableRows = @()
    $rank = 1
    foreach ($r in $rankings) {
        $tableRows += "| $rank | $($r.DisplayName) | $($r.Average.ToString("F2"))/3.0 | $($r.Strengths) | $($r.Weaknesses) |"
        $rank++
    }

    # Update the tracking file: replace the empty/existing Feature Quality Rankings table
    $lines = (Get-Content $TrackingFilePath -Encoding UTF8)
    $headerIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^###\s+Feature Quality Rankings') {
            $headerIdx = $i
            break
        }
    }

    if ($headerIdx -eq -1) {
        Write-Host "   Could not find '### Feature Quality Rankings' section in tracking file — skipping" -ForegroundColor Yellow
        return
    }

    # Find the table header row (| Rank | Feature | ...)
    $tableHeaderIdx = -1
    for ($i = $headerIdx + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\|\s*Rank\s*\|') {
            $tableHeaderIdx = $i
            break
        }
        if ($lines[$i] -match '^##[^#]') { break }  # Hit next section
    }

    if ($tableHeaderIdx -eq -1) {
        Write-Host "   Could not find Feature Quality Rankings table header — skipping" -ForegroundColor Yellow
        return
    }

    # Find extent of existing table (header + separator + any data rows)
    $tableEndIdx = $tableHeaderIdx + 2  # After header + separator
    for ($i = $tableHeaderIdx + 2; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\|') {
            $tableEndIdx = $i + 1
        } else {
            break
        }
    }

    # Replace: keep header + separator, replace data rows
    $result = [System.Collections.ArrayList]::new()
    # Lines before the data rows (header + separator)
    for ($i = 0; $i -lt ($tableHeaderIdx + 2); $i++) {
        [void]$result.Add($lines[$i])
    }
    # Insert new data rows
    foreach ($row in $tableRows) {
        [void]$result.Add($row)
    }
    # Lines after old table
    for ($i = $tableEndIdx; $i -lt $lines.Count; $i++) {
        [void]$result.Add($lines[$i])
    }

    $result.ToArray() | Set-Content $TrackingFilePath -Encoding UTF8
    Write-Host "   Updated Feature Quality Rankings in tracking file ($($rankings.Count) features ranked)" -ForegroundColor Green
}

# --- Main execution ---

# Parse parameters
$SelectedValidationTypes = $ValidationTypes -split "," | ForEach-Object { $_.Trim() }
$SelectedFeatures = if ($FeatureFilter) { $FeatureFilter -split "," | ForEach-Object { $_.Trim() } } else { @() }

# Find tracking file
$TrackingFilePath = Find-TrackingFile -RoundNumber $Round
if (-not $TrackingFilePath) {
    Write-Error "No validation tracking file found$(if ($Round -gt 0) { " for Round $Round" } else { '' }). Check doc/state-tracking/validation/"
    exit 1
}

# Extract round number from path
$detectedRound = 0
if ($TrackingFilePath -match "validation-tracking-(\d+)\.md") {
    $detectedRound = [int]$Matches[1]
}

Write-Host "Generating validation summary..." -ForegroundColor Cyan
Write-Host "   Round: $detectedRound" -ForegroundColor Gray
Write-Host "   Tracking File: $TrackingFilePath" -ForegroundColor Gray
Write-Host "   Output Path: $OutputPath" -ForegroundColor Gray
Write-Host "   Summary Type: $SummaryType" -ForegroundColor Gray
Write-Host "   Validation Types: $($SelectedValidationTypes -join ', ')" -ForegroundColor Gray
if ($SelectedFeatures.Count -gt 0) {
    Write-Host "   Feature Filter: $($SelectedFeatures -join ', ')" -ForegroundColor Gray
}

try {
    # Read tracking file
    $TrackingContent = Get-Content $TrackingFilePath -Raw
    Write-Host "   Reading validation tracking data..." -ForegroundColor Gray

    # Get report IDs for this round
    $RoundReportIds = Get-RoundReportIds -TrackingContent $TrackingContent
    Write-Host "   Found $($RoundReportIds.Count) report IDs for Round $detectedRound" -ForegroundColor Gray

    # Get issue summary from tracking file
    $TrackingIssues = Get-TrackingIssues -TrackingContent $TrackingContent

    # Initialize summary data
    $SummaryData = @{
        GenerationDate  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Round           = $detectedRound
        ValidationTypes = @{}
        OverallStats    = @{
            TotalReports = 0
            TotalScore   = 0.0
            HighIssues   = $TrackingIssues.High.Count
            MediumIssues = $TrackingIssues.Medium.Count
        }
    }

    # Collect data from validation reports, filtered to this round
    foreach ($ValidationType in $SelectedValidationTypes) {
        if (-not $ValidationTypeMap.ContainsKey($ValidationType)) { continue }

        $ReportsDir = Join-Path $ReportsBasePath $ValidationTypeMap[$ValidationType]
        if (-not (Test-Path $ReportsDir)) { continue }

        # Get all reports in this directory, filter to round's report IDs
        $AllReports = Get-ChildItem $ReportsDir -Filter "*.md" | Where-Object {
            foreach ($id in $RoundReportIds) {
                if ($_.Name.StartsWith($id)) { return $true }
            }
            return $false
        }

        Write-Host "   Processing $($AllReports.Count) Round $detectedRound reports for $ValidationType..." -ForegroundColor Gray

        $typeData = @{
            ReportCount  = $AllReports.Count
            Reports      = @()
            AverageScore = 0.0
            TotalHigh    = 0
            TotalMedium  = 0
            TotalLow     = 0
        }

        foreach ($Report in $AllReports) {
            $ReportContent = Get-Content $Report.FullName -Raw

            $score = Get-ReportScore -Content $ReportContent
            $issueCounts = Get-ReportIssueCounts -Content $ReportContent

            # Parse features from filename
            $features = @()
            if ($Report.Name -match "features-(.+)\.md$") {
                $features = $Matches[1] -split "-" | Where-Object { $_ -match "^\d+\.\d+\.\d+$" }
            }

            # Apply feature filter if specified
            if ($SelectedFeatures.Count -gt 0) {
                $hasMatch = $false
                foreach ($f in $features) {
                    if ($SelectedFeatures -contains $f) { $hasMatch = $true; break }
                }
                if (-not $hasMatch) { continue }
            }

            $reportInfo = @{
                FileName = $Report.Name
                Features = $features
                Score    = if ($score -ge 0) { $score } else { 0.0 }
                High     = $issueCounts.High
                Medium   = $issueCounts.Medium
                Low      = $issueCounts.Low
            }

            $typeData.Reports += $reportInfo
            $typeData.TotalHigh += $issueCounts.High
            $typeData.TotalMedium += $issueCounts.Medium
            $typeData.TotalLow += $issueCounts.Low
        }

        # Calculate average score
        $validScores = $typeData.Reports | Where-Object { $_.Score -gt 0 } | ForEach-Object { $_.Score }
        if ($validScores.Count -gt 0) {
            $typeData.AverageScore = ($validScores | Measure-Object -Average).Average
        }

        $SummaryData.ValidationTypes[$ValidationType] = $typeData
        $SummaryData.OverallStats.TotalReports += $typeData.Reports.Count

        if ($validScores.Count -gt 0) {
            $SummaryData.OverallStats.TotalScore += ($validScores | Measure-Object -Sum).Sum
        }
    }

    # Calculate overall average
    $allScores = $SummaryData.ValidationTypes.Values | ForEach-Object { $_.Reports } | Where-Object { $_.Score -gt 0 } | ForEach-Object { $_.Score }
    $overallAverage = if ($allScores.Count -gt 0) { ($allScores | Measure-Object -Average).Average } else { 0.0 }

    # Determine quality gate status
    $qualityGateStatus = if ($overallAverage -ge 2.5) { "PASSED" }
                         elseif ($overallAverage -ge 2.0) { "CONDITIONAL" }
                         else { "FAILED" }

    $qualityGateIcon = if ($qualityGateStatus -eq "PASSED") { "PASSED" }
                       elseif ($qualityGateStatus -eq "CONDITIONAL") { "CONDITIONAL" }
                       else { "FAILED" }

    $qualityGateDescription = if ($qualityGateStatus -eq "PASSED") { "Codebase meets production readiness criteria" }
                              elseif ($qualityGateStatus -eq "CONDITIONAL") { "Codebase functional but needs targeted improvements" }
                              else { "Codebase requires significant refactoring before production use" }

    # --- Generate summary content ---
    $SummaryContent = @"
---
id: PD-VAL-SUMMARY-R$detectedRound-$(Get-Date -Format "yyyyMMdd")
type: Process Framework
category: Validation Summary
version: 1.0
created: $(Get-Date -Format "yyyy-MM-dd")
round: $detectedRound
summary_type: $SummaryType
validation_types: $($SelectedValidationTypes -join ',')
---
# Feature Validation Summary - Round $detectedRound

## Executive Summary

**Generated**: $($SummaryData.GenerationDate)
**Validation Round**: $detectedRound
**Summary Type**: $SummaryType
**Validation Scope**: $($SelectedValidationTypes.Count) dimensions, $($SummaryData.OverallStats.TotalReports) reports

### Key Metrics

| Metric | Value |
|--------|-------|
| Overall Average Score | $($overallAverage.ToString("F2"))/3.0 |
| Reports Analyzed | $($SummaryData.OverallStats.TotalReports) |
| High Priority Issues | $($SummaryData.OverallStats.HighIssues) |
| Medium Priority Issues | $($SummaryData.OverallStats.MediumIssues) |
| Quality Gate | **$qualityGateIcon** |

### Quality Gate Assessment

**$qualityGateStatus**: $qualityGateDescription

## Validation Dimension Scores

| Dimension | Reports | Avg Score | High | Medium | Low | Status |
|-----------|---------|-----------|------|--------|-----|--------|
"@

    foreach ($ValidationType in $SelectedValidationTypes) {
        if (-not $SummaryData.ValidationTypes.ContainsKey($ValidationType)) { continue }
        $td = $SummaryData.ValidationTypes[$ValidationType]
        $displayName = $ValidationTypeDisplayNames[$ValidationType]
        $status = if ($td.AverageScore -ge 2.75) { "Excellent" }
                  elseif ($td.AverageScore -ge 2.50) { "Good" }
                  elseif ($td.AverageScore -ge 2.00) { "Adequate" }
                  elseif ($td.Reports.Count -eq 0) { "No Data" }
                  else { "Needs Improvement" }
        $scoreStr = if ($td.Reports.Count -gt 0 -and $td.AverageScore -gt 0) { "$($td.AverageScore.ToString("F2"))/3.0" } else { "N/A" }
        $SummaryContent += "| $displayName | $($td.Reports.Count) | $scoreStr | $($td.TotalHigh) | $($td.TotalMedium) | $($td.TotalLow) | $status |`n"
    }

    # Detailed findings section
    if ($IncludeDetails) {
        $SummaryContent += @"

## High Priority Issues

"@
        if ($TrackingIssues.High.Count -gt 0) {
            foreach ($issue in $TrackingIssues.High) {
                $SummaryContent += "- **$($issue.Id)**: $($issue.Description)`n"
            }
        } else {
            $SummaryContent += "No high priority issues identified in Round $detectedRound.`n"
        }

        $SummaryContent += @"

## Medium Priority Issues

"@
        if ($TrackingIssues.Medium.Count -gt 0) {
            foreach ($issue in $TrackingIssues.Medium) {
                $SummaryContent += "- **$($issue.Id)**: $($issue.Description)`n"
            }
        } else {
            $SummaryContent += "No medium priority issues identified in Round $detectedRound.`n"
        }

        $SummaryContent += @"

## Dimension Analysis

"@
        foreach ($ValidationType in $SelectedValidationTypes) {
            if (-not $SummaryData.ValidationTypes.ContainsKey($ValidationType)) { continue }
            $td = $SummaryData.ValidationTypes[$ValidationType]
            if ($td.Reports.Count -eq 0) { continue }

            $displayName = $ValidationTypeDisplayNames[$ValidationType]
            $SummaryContent += "### $displayName`n`n"

            foreach ($rpt in $td.Reports) {
                $featStr = $rpt.Features -join ", "
                $SummaryContent += "- **$($rpt.FileName)** (Features: $featStr) - Score: $($rpt.Score.ToString("F2"))/3.0 | $($rpt.High)H, $($rpt.Medium)M, $($rpt.Low)L`n"
            }
            $SummaryContent += "`n"
        }
    }

    # Relative path to tracking file from output location
    $trackingRelPath = if ($TrackingFilePath -match "validation-tracking-\d+\.md") {
        $TrackingFilePath.Replace($ProjectRoot, "").Replace("\", "/").TrimStart("/")
    } else { "doc/state-tracking/validation/validation-tracking-$detectedRound.md" }

    $SummaryContent += @"

## Related Resources

- [Validation Tracking - Round $detectedRound](/$trackingRelPath) - Detailed validation progress and issue tracking
- [Feature Validation Guide](/process-framework/guides/05-validation/feature-validation-guide.md) - Complete validation process guide
- [Validation Reports](/doc/validation/reports) - Individual validation reports by type

---

*This summary was automatically generated by Generate-ValidationSummary.ps1 on $($SummaryData.GenerationDate)*
"@

    # Write summary to file
    if ($PSCmdlet.ShouldProcess($OutputPath, "Write validation summary")) {
        $SummaryContent | Set-Content $OutputPath -Encoding UTF8
    }

    # Update Feature Quality Rankings in tracking file
    if ($PSCmdlet.ShouldProcess($TrackingFilePath, "Update Feature Quality Rankings")) {
        Update-FeatureQualityRankings `
            -SummaryData $SummaryData `
            -TrackingFilePath $TrackingFilePath `
            -TrackingContent $TrackingContent `
            -ReportsBasePath $ReportsBasePath `
            -ValidationTypeMap $ValidationTypeMap `
            -ValidationTypeDisplayNames $ValidationTypeDisplayNames `
            -RoundReportIds $RoundReportIds
    }

    Write-Host "Validation summary generated successfully!" -ForegroundColor Green
    Write-Host "   Summary file: $OutputPath" -ForegroundColor Gray
    Write-Host "   Round: $detectedRound" -ForegroundColor Gray
    Write-Host "   Reports analyzed: $($SummaryData.OverallStats.TotalReports)" -ForegroundColor Gray
    Write-Host "   Overall score: $($overallAverage.ToString("F2"))/3.0" -ForegroundColor Gray
    Write-Host "   Issues: $($SummaryData.OverallStats.HighIssues) High, $($SummaryData.OverallStats.MediumIssues) Medium" -ForegroundColor Gray

    if ($SummaryData.OverallStats.HighIssues -gt 0) {
        Write-Host "   High priority issues found - review recommended" -ForegroundColor Yellow
    }

    if ($OpenInEditor) {
        Write-Host "Opening summary in editor..." -ForegroundColor Cyan
        Start-Process $OutputPath
    }
}
catch {
    Write-Error "Failed to generate validation summary: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}
