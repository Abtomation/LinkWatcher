#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Updates manual test execution status in test-tracking.md and feature-tracking.md.

.DESCRIPTION
    After executing manual tests, this script updates tracking files with results.
    Can mark individual test cases, entire groups, or all tests for a feature.

.PARAMETER FeatureId
    Optional: Mark all manual test groups/cases for a feature.

.PARAMETER Group
    Optional: Mark a specific test group by name.

.PARAMETER TestCase
    Optional: Mark a specific test case by ID (e.g., "MT-001").

.PARAMETER Status
    New status. Options: "Passed", "Failed", "Needs Re-execution".
    Maps to emoji statuses in test-tracking.md.

.PARAMETER Reason
    Optional: Why the status changed (e.g., "Bug fix PD-BUG-028", "Release validation").

.PARAMETER ProjectRoot
    Optional: Project root path. Auto-detected if not specified.

.EXAMPLE
    .\Update-TestExecutionStatus.ps1 -Group "basic-file-operations" -Status "Passed"

.EXAMPLE
    .\Update-TestExecutionStatus.ps1 -FeatureId "1.1.1" -Status "Needs Re-execution" -Reason "Bug fix PD-BUG-032"

.EXAMPLE
    .\Update-TestExecutionStatus.ps1 -TestCase "MT-001" -Status "Failed" -Reason "Link not updated after rename"

.NOTES
    Created: 2026-03-15
    Version: 1.0
    Task: Manual Test Execution (PF-TSK-070)
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$FeatureId = "",

    [Parameter(Mandatory=$false)]
    [string]$Group = "",

    [Parameter(Mandatory=$false)]
    [string]$TestCase = "",

    [Parameter(Mandatory=$true)]
    [ValidateSet("Passed", "Failed", "Needs Re-execution")]
    [string]$Status,

    [Parameter(Mandatory=$false)]
    [string]$Reason = "",

    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = ""
)

# Validate at least one selector is provided
if (-not $FeatureId -and -not $Group -and -not $TestCase) {
    Write-Error "At least one of -FeatureId, -Group, or -TestCase must be specified."
    exit 1
}

# Resolve project root
if (-not $ProjectRoot) {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir ".git"))) {
        $searchDir = Split-Path $searchDir -Parent
    }
    if (-not $searchDir) {
        Write-Error "Could not auto-detect project root. Use -ProjectRoot parameter."
        exit 1
    }
    $ProjectRoot = $searchDir
}

# Map status to emoji
$statusMap = @{
    "Passed" = "✅ Passed"
    "Failed" = "🔴 Failed"
    "Needs Re-execution" = "🔄 Needs Re-execution"
}
$emojiStatus = $statusMap[$Status]
$timestamp = Get-Date -Format "yyyy-MM-dd"

$testTrackingPath = Join-Path $ProjectRoot "doc/process-framework/state-tracking/permanent/test-tracking.md"
$featureTrackingPath = Join-Path $ProjectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md"

if (-not (Test-Path $testTrackingPath)) {
    Write-Error "Test tracking file not found: $testTrackingPath"
    exit 1
}

# Read test-tracking.md
$content = Get-Content $testTrackingPath -Raw -Encoding UTF8
$lines = $content -split '\r?\n'
$updatedLines = @()
$matchCount = 0

foreach ($line in $lines) {
    # Check if this is a table row matching our criteria
    if ($line -match '^\|') {
        $cells = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

        if ($cells.Count -ge 6) {
            $testId = $cells[0]
            $featureCol = $cells[1]
            $testType = $cells[2]

            $isMatch = $false

            # Match by test case ID
            if ($TestCase -and $testId -eq $TestCase) {
                $isMatch = $true
            }

            # Match by group (check if testId matches MT-GRP pattern and test type is "Manual Group")
            if ($Group -and $testType -match 'Manual' -and $line -match [regex]::Escape($Group)) {
                $isMatch = $true
            }

            # Match by feature ID (all manual entries for that feature)
            if ($FeatureId -and $featureCol -eq $FeatureId -and $testType -match 'Manual') {
                $isMatch = $true
            }

            if ($isMatch) {
                # Update the status column (index 4) and Last Executed column (index 6)
                # Table format: | Test ID | Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
                $cells[4] = $emojiStatus
                $cells[6] = $timestamp
                $cells[7] = $timestamp
                if ($Reason) {
                    $cells[8] = $Reason
                }

                $line = "| " + ($cells -join " | ") + " |"
                $matchCount++
            }
        }
    }

    $updatedLines += $line
}

if ($matchCount -eq 0) {
    Write-Warning "No matching entries found in test-tracking.md."
    Write-Warning "Selectors: FeatureId='$FeatureId', Group='$Group', TestCase='$TestCase'"
} else {
    if ($PSCmdlet.ShouldProcess($testTrackingPath, "Update $matchCount test tracking entries to '$emojiStatus'")) {
        # Update metadata timestamp
        $updatedContent = ($updatedLines -join "`n") -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $timestamp"
        Set-Content $testTrackingPath $updatedContent -Encoding UTF8
        Write-Host "  ✅ Updated $matchCount entries in test-tracking.md → $emojiStatus" -ForegroundColor Green
    }
}

# Update feature-tracking.md Test Status if applicable
if ($FeatureId -or $Group) {
    # Determine the feature-level status based on individual test results
    $featureStatus = switch ($Status) {
        "Passed" { "✅ All Passing" }
        "Failed" { "🔴 Some Failing" }
        "Needs Re-execution" { "🔄 Re-testing Needed" }
    }

    if (Test-Path $featureTrackingPath) {
        $ftContent = Get-Content $featureTrackingPath -Raw -Encoding UTF8

        # Find the feature row and update Test Status
        $targetFeature = if ($FeatureId) { $FeatureId } else { "" }

        if ($targetFeature) {
            # Simple regex replacement for the Test Status cell in the matching feature row
            $ftLines = $ftContent -split '\r?\n'
            $ftUpdatedLines = @()
            $ftUpdated = $false

            foreach ($ftLine in $ftLines) {
                if ($ftLine -match '^\|' -and $ftLine -match [regex]::Escape($targetFeature)) {
                    $ftCells = $ftLine -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

                    # Find Test Status column — look for columns with emoji test statuses
                    for ($i = 0; $i -lt $ftCells.Count; $i++) {
                        if ($ftCells[$i] -match '(⬜|🚫|📋|🟡|✅|🔴|🔧|🔄)') {
                            # Check if this looks like a Test Status cell
                            if ($ftCells[$i] -match '(No Tests|No Test Required|Specs Created|In Progress|All Passing|Some Failing|Automated Only|Re-testing Needed)') {
                                $ftCells[$i] = $featureStatus
                                $ftUpdated = $true
                                break
                            }
                        }
                    }

                    if ($ftUpdated) {
                        $ftLine = "| " + ($ftCells -join " | ") + " |"
                    }
                }
                $ftUpdatedLines += $ftLine
            }

            if ($ftUpdated) {
                if ($PSCmdlet.ShouldProcess($featureTrackingPath, "Update feature $targetFeature Test Status to '$featureStatus'")) {
                    $ftUpdatedContent = ($ftUpdatedLines -join "`n") -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $timestamp"
                    Set-Content $featureTrackingPath $ftUpdatedContent -Encoding UTF8
                    Write-Host "  ✅ Updated feature-tracking.md: $targetFeature → $featureStatus" -ForegroundColor Green
                }
            }
        }
    }
}

# Summary
Write-Host ""
Write-Host "Execution Status Update:" -ForegroundColor Cyan
Write-Host "  Status: $emojiStatus" -ForegroundColor Cyan
Write-Host "  Entries updated: $matchCount" -ForegroundColor Cyan
if ($Reason) {
    Write-Host "  Reason: $Reason" -ForegroundColor Cyan
}
