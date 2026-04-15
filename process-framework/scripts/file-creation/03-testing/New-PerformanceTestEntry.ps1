# New-PerformanceTestEntry.ps1
# Adds a new performance test entry to performance-test-tracking.md
# Auto-assigns test IDs (BM-xxx for Level 1/2, PH-xxx for Level 3/4)

<#
.SYNOPSIS
    Adds a new performance test entry to performance-test-tracking.md with an auto-assigned test ID.

.DESCRIPTION
    This PowerShell script creates new performance test entries by:
    - Auto-assigning the next available test ID (BM-xxx or PH-xxx based on level)
    - Inserting a row into the correct level section with status "⬜ Specified"
    - Updating the Summary table counts
    - Used by the Performance & E2E Test Scoping task (PF-TSK-086)

.PARAMETER Level
    Performance test level (1-4):
    1 = Component Benchmarks, 2 = Operation Benchmarks,
    3 = Scale Tests, 4 = Resource Bounds

.PARAMETER Operation
    Description of the operation being tested (e.g., "Parser throughput (100 mixed-format files)")

.PARAMETER RelatedFeatures
    Comma-separated feature IDs (e.g., "2.1.1" or "0.1.1, 2.1.1")

.PARAMETER Tolerance
    Acceptance threshold (e.g., ">50 files/sec", "<10s", "<100MB increase")

.PARAMETER Rationale
    Why this test is needed — which decision matrix question was triggered.
    Stored as a comment in the Spec Ref column for traceability.

.PARAMETER SpecRef
    Optional link to a test specification (e.g., "PF-TSP-039"). Defaults to rationale text.

.EXAMPLE
    New-PerformanceTestEntry.ps1 -Level 1 -Operation "YAML parser throughput (50 files)" -RelatedFeatures "2.1.1" -Tolerance ">30 files/sec" -Rationale "Feature modifies YAML parser hot path"

.EXAMPLE
    New-PerformanceTestEntry.ps1 -Level 3 -Operation "1000-file scan with new filter" -RelatedFeatures "0.1.1, 1.1.1" -Tolerance "<30s" -Rationale "Feature changes scaling characteristics of file filter" -WhatIf

.NOTES
    - Test IDs are auto-assigned via the central ID registry (TE-id-registry.json)
    - BM-xxx prefix for Levels 1-2 (benchmarks), PH-xxx for Levels 3-4 (scale/resource)
    - New entries are created with status "⬜ Specified" — Baseline, Last Result, Last Run, Test File, Audit Status, and Audit Report are set to "—"
    - The Summary table is automatically updated with new counts
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(1, 2, 3, 4)]
    [int]$Level,

    [Parameter(Mandatory = $true)]
    [ValidateLength(5, 300)]
    [string]$Operation,

    [Parameter(Mandatory = $true)]
    [ValidateLength(1, 100)]
    [string]$RelatedFeatures,

    [Parameter(Mandatory = $true)]
    [ValidateLength(3, 200)]
    [string]$Tolerance,

    [Parameter(Mandatory = $true)]
    [ValidateLength(10, 500)]
    [string]$Rationale,

    [Parameter(Mandatory = $false)]
    [string]$SpecRef = ""
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
Invoke-StandardScriptInitialization

# Configuration
$ProjectRoot = Get-ProjectRoot
$TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "test/state-tracking/permanent/performance-test-tracking.md"

if (-not (Test-Path $TrackingFile)) {
    Write-ProjectError -Message "Tracking file not found: $TrackingFile" -ExitCode 1
}

# Map level to section heading and ID prefix
$LevelConfig = @{
    1 = @{ Section = "### Component Benchmarks (Level 1)"; Prefix = "BM"; SummaryLabel = "Component" }
    2 = @{ Section = "### Operation Benchmarks (Level 2)"; Prefix = "BM"; SummaryLabel = "Operation" }
    3 = @{ Section = "### Scale Tests (Level 3)"; Prefix = "PH"; SummaryLabel = "Scale" }
    4 = @{ Section = "### Resource Bounds (Level 4)"; Prefix = "PH"; SummaryLabel = "Resource" }
}

$config = $LevelConfig[$Level]
$idPrefix = $config.Prefix

# Read current content
$Content = Get-Content -Path $TrackingFile -Raw -Encoding UTF8
$lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

# --- Step 1: Auto-assign test ID via the central ID registry ---
$testId = New-ProjectId -Prefix $idPrefix -Description "Performance test: $Operation"

Write-Host "Adding performance test entry: $testId (Level $Level)" -ForegroundColor Yellow
Write-Host "Operation: $Operation" -ForegroundColor Cyan
Write-Host "Related Features: $RelatedFeatures" -ForegroundColor Cyan
Write-Host "Tolerance: $Tolerance" -ForegroundColor Cyan

# --- Step 2: Build the table row ---
# Columns: Test ID | Operation | Related Features | Status | Baseline | Tolerance | Last Result | Last Run | Test File | Audit Status | Audit Report | Spec Ref
$specRefValue = if ($SpecRef -ne "") { $SpecRef } else { $Rationale }
$tableRow = "| $testId | $Operation | $RelatedFeatures | ⬜ Specified | — | $Tolerance | — | — | — | — | — | $specRefValue |"

# --- Step 3: Find the correct section and insert after the last data row ---
if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Add performance test entry '$testId' to Level $Level section")) {
    return
}

$sectionHeading = $config.Section
$insertAfterIndex = -1
$inTargetSection = $false

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match [regex]::Escape($sectionHeading)) {
        $inTargetSection = $true
        continue
    }
    if ($inTargetSection) {
        # Match data rows (start with | and contain a test ID or other data)
        if ($lines[$i] -match "^\|\s*(BM|PH)-\d{3}\b") {
            $insertAfterIndex = $i
        }
        # Stop at next section heading
        if ($lines[$i] -match "^###\s" -and $lines[$i] -notmatch [regex]::Escape($sectionHeading)) {
            break
        }
        if ($lines[$i] -match "^## ") {
            break
        }
    }
}

# If no data rows found in section, insert after the table header separator
if ($insertAfterIndex -eq -1) {
    $inTargetSection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match [regex]::Escape($sectionHeading)) {
            $inTargetSection = $true
            continue
        }
        if ($inTargetSection -and $lines[$i] -match "^\|\s*-") {
            $insertAfterIndex = $i
            break
        }
    }
}

if ($insertAfterIndex -eq -1) {
    Write-ProjectError -Message "Could not find insertion point in section '$sectionHeading'" -ExitCode 1
}

$lines.Insert($insertAfterIndex + 1, $tableRow)
Write-Host "Inserted $testId into $sectionHeading" -ForegroundColor Green

# --- Step 4: Update the Summary table ---
# Find the summary row for this level and increment Total and ⬜ Specified counts
$summaryLabel = $config.SummaryLabel
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^\|\s*$summaryLabel\s*\|") {
        # Parse the summary row: | Level | Total | ✅ Baselined | 📋 Created | ⬜ Specified | ⚠️ Stale |
        $cells = $lines[$i] -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        if ($cells.Count -ge 6) {
            $total = [int]$cells[1] + 1
            $specified = [int]$cells[4] + 1
            $lines[$i] = "| $summaryLabel | $total | $($cells[2]) | $($cells[3]) | $specified | $($cells[5]) |"
            Write-Host "Updated Summary: $summaryLabel Total=$total, Specified=$specified" -ForegroundColor Green
        }
        break
    }
}

# Update the Total row in summary
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^\|\s*\*\*Total\*\*") {
        $cells = $lines[$i] -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        if ($cells.Count -ge 6) {
            # Strip bold markers for arithmetic
            $totalVal = [int]($cells[1] -replace '\*', '') + 1
            $specVal = [int]($cells[4] -replace '\*', '') + 1
            $lines[$i] = "| **Total** | **$totalVal** | **$($cells[2] -replace '\*', '')** | **$($cells[3] -replace '\*', '')** | **$specVal** | **$($cells[5] -replace '\*', '')** |"
            Write-Host "Updated Summary: Total=$totalVal" -ForegroundColor Green
        }
        break
    }
}

# Write the updated content
$updatedContent = $lines -join "`r`n"
Set-Content -Path $TrackingFile -Value $updatedContent -NoNewline -Encoding UTF8

# --- Output ---
$details = @(
    "Test ID: $testId",
    "Level: $Level ($($config.SummaryLabel))",
    "Operation: $Operation",
    "Related Features: $RelatedFeatures",
    "Tolerance: $Tolerance",
    "Rationale: $Rationale"
)

Write-ProjectSuccess -Message "Created performance test entry: $testId" -Details $details

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  - Use Performance Test Creation task (PF-TSK-084) to implement this test" -ForegroundColor White
Write-Host "  - Use Performance Baseline Capture task (PF-TSK-085) to record initial baseline" -ForegroundColor White
