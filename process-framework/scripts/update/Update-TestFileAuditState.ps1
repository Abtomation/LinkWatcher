#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates state file updates for individual Test File Audit (PF-TSK-030)

.DESCRIPTION
This script automates the manual state file updates required by the Test Audit Task,
focusing on individual test files rather than entire features. Supports three test types:
- Automated (default): Updates test-tracking.md + feature-tracking.md
- Performance: Updates performance-test-tracking.md Audit Status/Report columns
- E2E: Updates e2e-test-tracking.md Audit Status/Report columns

SC-007: Uses file path as test file identifier (not PD-TST/TE-TST IDs).

Updates the following files (based on -TestType):
- Automated: test-tracking.md + feature-tracking.md (aggregated status)
- Performance: performance-test-tracking.md (Audit Status + Audit Report columns)
- E2E: e2e-test-tracking.md (Audit Status + Audit Report columns)

.PARAMETER TestFilePath
Relative path to the test file being audited (e.g., "test/automated/unit/test_service.py")

.PARAMETER AuditStatus
The audit status (e.g., "Tests Approved", "Needs Update", "Audit In Progress")

.PARAMETER AuditReportPath
Path to the audit report document

.PARAMETER AuditDate
Date of the audit completion (optional - uses current date if not specified)

.PARAMETER AuditorName
Name of the person who conducted the audit (optional)

.PARAMETER MajorFindings
Array of major findings from the audit (optional)

.PARAMETER TestCasesAudited
Number of test cases that were audited (optional)

.PARAMETER PassedTests
Number of tests that passed the audit (optional)

.PARAMETER FailedTests
Number of tests that failed the audit (optional)

.PARAMETER DryRun
If specified, shows what would be updated without making changes

.EXAMPLE
Update-TestFileAuditState.ps1 -TestFilePath "test/automated/unit/test_service.py" -AuditStatus "Tests Approved" -AuditReportPath "test/audits/foundation/audit-report-0-1-1-test_service.md"

.EXAMPLE
Update-TestFileAuditState.ps1 -TestFilePath "test/automated/unit/test_service.py" -AuditStatus "Needs Update" -AuditorName "John Doe" -MajorFindings @("Missing edge case tests", "Incomplete mock coverage") -DryRun

.EXAMPLE
Update-TestFileAuditState.ps1 -TestFilePath "test/automated/unit/test_service.py" -AuditStatus "Tests Approved" -TestCasesAudited 15 -PassedTests 13 -FailedTests 2

.NOTES
This script addresses Process Improvement items:
- IMP-087: Test Audit state file update automation (High)
- Manual bottleneck for PF-TSK-030 (3 files, critical for quality assurance)
- Individual test file focus for granular audit control
- SC-007: Uses file path as identifier (not PD-TST/TE-TST IDs)

Created: 2025-08-29
Updated: 2026-04-13 (IMP-495: add -TestType param for Performance/E2E audit support)
Version: 3.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Automated", "Performance", "E2E")]
    [string]$TestType = "Automated",

    [Parameter(Mandatory=$true)]
    [string]$TestFilePath,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Audit In Progress", "Tests Approved", "Needs Update", "Audit Failed")]
    [string]$AuditStatus,

    [Parameter(Mandatory=$false)]
    [string]$AuditReportPath,

    [Parameter(Mandatory=$false)]
    [string]$AuditDate,

    [Parameter(Mandatory=$false)]
    [string]$AuditorName,

    [Parameter(Mandatory=$false)]
    [string[]]$MajorFindings = @(),

    [Parameter(Mandatory=$false)]
    [int]$TestCasesAudited,

    [Parameter(Mandatory=$false)]
    [int]$PassedTests,

    [Parameter(Mandatory=$false)]
    [int]$FailedTests,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Import required modules with walk-up path resolution
try {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $dir = $scriptDir
    while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
        $dir = Split-Path -Parent $dir
    }
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
}
catch {
    Write-Error "Failed to import Common-ScriptHelpers module: $($_.Exception.Message)"
    exit 1
}

# Initialize script
$ErrorActionPreference = "Stop"

# Validate dependencies
$dependencyCheck = Test-ScriptDependencies -RequiredFunctions @(
    "Update-FeatureTrackingStatus",
    "Update-TestImplementationStatus",
    "Get-StateFileBackup",
    "Get-ProjectRoot"
)

if (-not $dependencyCheck.AllDependenciesMet) {
    Write-Error "Required dependencies not met. Please ensure Common-ScriptHelpers.psm1 is properly loaded."
    exit 1
}

# Helper function to get feature ID from test file path (SC-007)
# Uses directory-aware matching: when multiple rows share the same filename,
# disambiguates using the directory portion of TestFilePath (IMP-340)
function Get-FeatureIdFromTestFile {
    param([string]$TestFilePath)

    $projectRoot = Get-ProjectRoot
    $testTrackingPath = Join-Path $projectRoot "test/state-tracking/permanent/test-tracking.md"

    if (-not (Test-Path $testTrackingPath)) {
        throw "Test tracking file not found: $testTrackingPath"
    }

    $fileName = Split-Path $TestFilePath -Leaf
    $content = Get-Content $testTrackingPath -Encoding UTF8
    $escapedFileName = [regex]::Escape($fileName)

    # Collect all matching rows by filename
    $foundRows = @()
    foreach ($line in $content) {
        if ($line -match "^\|" -and $line -match $escapedFileName) {
            $cols = $line -split '\|' | ForEach-Object { $_.Trim() }
            if ($cols.Count -ge 4 -and $cols[1] -match '^\d+\.\d+\.\d+$') {
                $foundRows += @{ FeatureId = $cols[1]; LinkCell = $cols[3]; Line = $line }
            }
        }
    }

    if ($foundRows.Count -eq 0) {
        throw "Test file '$fileName' not found in test tracking"
    }

    if ($foundRows.Count -eq 1) {
        return $foundRows[0].FeatureId
    }

    # Multiple matches — disambiguate using directory from TestFilePath
    # Build a suffix from input path: e.g., "test/automated/unit/test_config.py" → "unit/test_config.py"
    $normalizedInput = $TestFilePath -replace '\\', '/'
    $inputParts = $normalizedInput -split '/'
    # Use parent-dir/filename as the disambiguation suffix (at minimum)
    $suffixParts = if ($inputParts.Count -ge 2) { $inputParts[-2..-1] } else { $inputParts }
    $suffix = ($suffixParts -join '/')

    $narrowed = @()
    foreach ($row in $foundRows) {
        # Extract path from markdown link [name](path) in the Test File/Case column
        if ($row.LinkCell -match '\[.*?\]\((.*?)\)') {
            $linkPath = $Matches[1] -replace '\\', '/'
            if ($linkPath.EndsWith($suffix)) {
                $narrowed += $row
            }
        }
    }

    if ($narrowed.Count -eq 1) {
        return $narrowed[0].FeatureId
    }

    if ($narrowed.Count -eq 0) {
        $paths = ($foundRows | ForEach-Object { $_.LinkCell }) -join ", "
        throw "Test file '$fileName' found $($foundRows.Count) times in test tracking but none matched path '$TestFilePath'. Entries: $paths"
    }

    $paths = ($narrowed | ForEach-Object { $_.LinkCell }) -join ", "
    throw "Test file '$fileName' still ambiguous after path disambiguation ($($narrowed.Count) matches). Provide a more specific path. Entries: $paths"
}

# Helper function to update individual test file status (SC-007: match by file path)
# Uses directory-aware matching to disambiguate duplicate filenames (IMP-340)
function Update-IndividualTestFileStatus {
    param(
        [string]$TestFilePath,
        [string]$Status,
        [hashtable]$AdditionalUpdates = @{},
        [switch]$DryRun
    )

    $projectRoot = Get-ProjectRoot
    $testTrackingPath = Join-Path $projectRoot "test/state-tracking/permanent/test-tracking.md"
    $fileName = Split-Path $TestFilePath -Leaf

    if ($DryRun) {
        Write-Host "DRY RUN: Would update test file $fileName in test-tracking.md" -ForegroundColor Cyan
        Write-Host "  Status: $Status" -ForegroundColor Gray
        foreach ($key in $AdditionalUpdates.Keys) {
            Write-Host "  $key`: $($AdditionalUpdates[$key])" -ForegroundColor Gray
        }
        return @{ Success = $true; DryRun = $true }
    }

    if (-not (Test-Path $testTrackingPath)) {
        throw "Test tracking file not found: $testTrackingPath"
    }

    $content = Get-Content $testTrackingPath -Raw

    # Find all matching lines by filename, then disambiguate by path if needed
    $lines = $content -split "`r?`n"
    $updated = $false
    $escapedFileName = [regex]::Escape($fileName)
    $normalizedInput = $TestFilePath -replace '\\', '/'

    # First pass: collect all matching line indices
    $matchingIndices = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^\|" -and $lines[$i] -match $escapedFileName) {
            $parts = $lines[$i] -split '\|'
            if ($parts.Count -ge 9) {
                $matchingIndices += $i
            }
        }
    }

    if ($matchingIndices.Count -eq 0) {
        throw "Test file '$fileName' not found in test tracking"
    }

    # Determine which line to update
    $targetIndex = -1
    if ($matchingIndices.Count -eq 1) {
        $targetIndex = $matchingIndices[0]
    } else {
        # Multiple matches — disambiguate using directory suffix from TestFilePath
        $inputParts = $normalizedInput -split '/'
        $suffixParts = if ($inputParts.Count -ge 2) { $inputParts[-2..-1] } else { $inputParts }
        $suffix = ($suffixParts -join '/')

        foreach ($idx in $matchingIndices) {
            $parts = $lines[$idx] -split '\|'
            $linkCell = $parts[3].Trim()
            if ($linkCell -match '\[.*?\]\((.*?)\)') {
                $linkPath = $Matches[1] -replace '\\', '/'
                if ($linkPath.EndsWith($suffix)) {
                    $targetIndex = $idx
                    break
                }
            }
        }

        if ($targetIndex -eq -1) {
            $paths = $matchingIndices | ForEach-Object {
                $p = $lines[$_] -split '\|'; $p[3].Trim()
            }
            throw "Test file '$fileName' found $($matchingIndices.Count) times but none matched path '$TestFilePath'. Entries: $($paths -join ', ')"
        }
    }

    # Apply the update to the target line
    $parts = $lines[$targetIndex] -split '\|'
    # 8-column format (SC-007):
    # Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes
    # Index: 1        2            3              4          5                 6               7              8
    $parts[4] = " $Status "
    $parts[7] = " $(Get-Date -Format 'yyyy-MM-dd') "

    if ($AdditionalUpdates.Count -gt 0) {
        $currentNotes = $parts[8].Trim()
        $newNotes = @()

        if ($currentNotes -and $currentNotes -ne "") {
            $newNotes += $currentNotes
        }

        foreach ($key in $AdditionalUpdates.Keys) {
            $newNotes += "$key`: $($AdditionalUpdates[$key])"
        }

        $parts[8] = " $($newNotes -join '; ') "
    }

    $lines[$targetIndex] = $parts -join '|'
    $updated = $true

    if (-not $updated) {
        throw "Test file '$fileName' not found in test tracking"
    }

    # Write back to file
    $updatedContent = $lines -join "`r`n"
    Set-Content -Path $testTrackingPath -Value $updatedContent -Encoding UTF8

    return @{ Success = $true; Updated = $true }
}

# Main execution
try {
    Write-Host "Test File Audit State Update" -ForegroundColor Green
    Write-Host "============================" -ForegroundColor Green
    Write-Host "Test Type: $TestType" -ForegroundColor Cyan
    Write-Host "Test File: $TestFilePath" -ForegroundColor Cyan
    Write-Host "Audit Status: $AuditStatus" -ForegroundColor Cyan

    if ($DryRun) {
        Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
        Write-Host ""
    }

    # --- Performance / E2E: update dedicated tracking file Audit Status + Audit Report columns ---
    if ($TestType -ne "Automated") {
        $projectRoot = Get-ProjectRoot
        $trackingRelPath = switch ($TestType) {
            "Performance" { "test/state-tracking/permanent/performance-test-tracking.md" }
            "E2E" { "test/state-tracking/permanent/e2e-test-tracking.md" }
        }
        $trackingFilePath = Join-Path $projectRoot $trackingRelPath
        $trackingFileName = Split-Path $trackingFilePath -Leaf
        $testFileName = Split-Path $TestFilePath -Leaf

        if (-not (Test-Path $trackingFilePath)) {
            throw "Tracking file not found: $trackingFilePath"
        }

        # Map audit status to emoji-prefixed status
        $auditStatusDisplay = switch ($AuditStatus) {
            "Audit In Progress" { "🔍 Audit In Progress" }
            "Tests Approved" { "✅ Approved" }
            "Needs Update" { "🔄 Needs Update" }
            "Audit Failed" { "🔴 Failed" }
        }

        # Build audit report link if path provided
        $auditReportLink = "—"
        if ($AuditReportPath) {
            $reportFileName = Split-Path $AuditReportPath -Leaf
            $reportBaseName = [System.IO.Path]::GetFileNameWithoutExtension($reportFileName)
            # Build relative path from tracking file to audit report
            $auditCategory = switch ($TestType) { "Performance" { "performance" }; "E2E" { "e2e" } }
            $auditRelPath = "../../audits/$auditCategory/$reportFileName"
            $auditReportLink = "[$reportBaseName]($auditRelPath)"
        }

        if ($DryRun) {
            Write-Host "DRY RUN: Would update $trackingFileName for $testFileName" -ForegroundColor Cyan
            Write-Host "  Audit Status: $auditStatusDisplay" -ForegroundColor Gray
            Write-Host "  Audit Report: $auditReportLink" -ForegroundColor Gray
        } else {
            # Create backup
            $backupResult = Get-StateFileBackup -FilePath $trackingFilePath
            Write-Host "Backup created for $trackingFileName" -ForegroundColor Green

            $trackingContent = Get-Content $trackingFilePath -Raw -Encoding UTF8
            $lines = $trackingContent -split '\r?\n'
            $updatedLines = @()
            $rowUpdated = $false
            $columnIndices = @{}
            $escapedFileName = [regex]::Escape($testFileName)

            foreach ($line in $lines) {
                # Parse table headers to find column indices by name
                if (-not $rowUpdated -and $line -match '^\|.*\|$' -and $columnIndices.Count -eq 0 -and $line -notmatch '^\|[-\s:]+\|$') {
                    $rawHeaders = $line -split '\|'
                    if ($rawHeaders.Count -gt 2) { $rawHeaders = $rawHeaders[1..($rawHeaders.Count-2)] }
                    $headers = $rawHeaders | ForEach-Object { $_.Trim() }
                    for ($j = 0; $j -lt $headers.Count; $j++) {
                        if ($headers[$j] -ne '') { $columnIndices[$headers[$j]] = $j }
                    }
                    if (-not $columnIndices.ContainsKey("Audit Status") -or -not $columnIndices.ContainsKey("Audit Report")) {
                        $columnIndices = @{}
                    }
                }
                elseif ($line -match '^#' -and $columnIndices.Count -gt 0) {
                    $columnIndices = @{}
                }

                if (-not $rowUpdated -and $columnIndices.Count -gt 0 -and $line -match "^\|.*$escapedFileName.*\|") {
                    $rawCols = $line -split '\|'
                    if ($rawCols.Count -gt 2) { $rawCols = $rawCols[1..($rawCols.Count-2)] }
                    $cols = $rawCols | ForEach-Object { $_.Trim() }

                    $auditStatusIdx = $columnIndices["Audit Status"]
                    $auditReportIdx = $columnIndices["Audit Report"]
                    if ($auditStatusIdx -lt $cols.Count -and $auditReportIdx -lt $cols.Count) {
                        $cols[$auditStatusIdx] = $auditStatusDisplay
                        $cols[$auditReportIdx] = $auditReportLink
                        $line = "| " + ($cols -join " | ") + " |"
                        $rowUpdated = $true
                    }
                }
                $updatedLines += $line
            }

            if ($rowUpdated) {
                $updatedContent = $updatedLines -join "`n"
                Set-Content $trackingFilePath $updatedContent -Encoding UTF8
                Write-Host "  ✅ $trackingFileName updated: $testFileName Audit Status ← $auditStatusDisplay" -ForegroundColor Green
            } else {
                Write-Warning "Could not find $testFileName in $trackingFileName — manual update needed"
            }
        }

        # Summary for Performance/E2E
        Write-Host ""
        Write-Host "Test File Audit State Update Summary" -ForegroundColor Green
        Write-Host "====================================" -ForegroundColor Green
        Write-Host "Test Type: $TestType" -ForegroundColor White
        Write-Host "Test File: $TestFilePath" -ForegroundColor White
        Write-Host "Audit Status: $AuditStatus" -ForegroundColor White
        Write-Host ""
        Write-Host "Files Updated:" -ForegroundColor White
        Write-Host "  ✅ $trackingFileName (Audit Status + Audit Report)" -ForegroundColor Green

        if ($DryRun) {
            Write-Host ""
            Write-Host "DRY RUN COMPLETED - No actual changes were made" -ForegroundColor Yellow
        } else {
            Write-Host ""
            Write-Host "✅ Test file audit state update completed successfully!" -ForegroundColor Green
        }
        return
    }

    # --- Automated: existing behavior ---

    # Get the feature ID for this test file (SC-007: lookup by file path)
    $FeatureId = Get-FeatureIdFromTestFile -TestFilePath $TestFilePath
    Write-Host "Associated Feature ID: $FeatureId" -ForegroundColor Cyan
    Write-Host ""

    # Prepare update data
    $timestamp = Get-Date -Format "yyyy-MM-dd"
    if (-not $AuditDate) {
        $AuditDate = $timestamp
    }

    # Validate audit report path if provided
    if ($AuditReportPath) {
        $projectRoot = Get-ProjectRoot
        $fullReportPath = if ([System.IO.Path]::IsPathRooted($AuditReportPath)) {
            $AuditReportPath
        } else {
            Join-Path $projectRoot $AuditReportPath
        }

        if (-not $DryRun -and -not (Test-Path $fullReportPath)) {
            Write-Warning "Audit report not found at: $fullReportPath"
            Write-Host "Continuing with state updates..." -ForegroundColor Yellow
        }
    }

    # Create backup of all files before making changes
    if (-not $DryRun) {
        Write-Host "Creating backups..." -ForegroundColor Yellow
        $projectRoot = Get-ProjectRoot
        $filesToBackup = @(
            "test/state-tracking/permanent/test-tracking.md",
            "doc/state-tracking/permanent/feature-tracking.md"
        )

        $backupCount = 0
        foreach ($file in $filesToBackup) {
            $fullPath = Join-Path $projectRoot $file
            if (Test-Path $fullPath) {
                $backupResult = Get-StateFileBackup -FilePath $fullPath
                $backupCount++
                Write-Verbose "Backed up: $file"
            }
        }
        Write-Host "Backup completed: $backupCount files backed up" -ForegroundColor Green
    }

    # Update 1: Individual Test File Status
    Write-Host ""
    Write-Host "Updating Test Tracking..." -ForegroundColor Yellow

    # Build additional updates for test implementation tracking
    $testUpdates = @{
        "Audit Status" = $AuditStatus
        "Audit Date" = $AuditDate
    }

    if ($AuditReportPath) {
        $testUpdates["Audit Report"] = $AuditReportPath
    }

    if ($AuditorName) {
        $testUpdates["Auditor"] = $AuditorName
    }

    if ($TestCasesAudited) {
        $testUpdates["Test Cases Audited"] = $TestCasesAudited
    }

    if ($PassedTests -or $FailedTests) {
        $testUpdates["Audit Results"] = "Passed: $PassedTests, Failed: $FailedTests"
    }

    if ($MajorFindings.Count -gt 0) {
        $testUpdates["Major Findings"] = $MajorFindings -join "; "
    }

    # Map audit status to test implementation status
    $testImplStatus = switch ($AuditStatus) {
        "Audit In Progress" { "🔍 Audit In Progress" }
        "Tests Approved" { "✅ Tests Approved" }
        "Needs Update" { "🔄 Needs Update" }
        "Audit Failed" { "🔴 Audit Failed" }
    }

    $testFileName = Split-Path $TestFilePath -Leaf
    $testResult = Update-IndividualTestFileStatus -TestFilePath $TestFilePath -Status $testImplStatus -AdditionalUpdates $testUpdates -DryRun:$DryRun

    if ($DryRun) {
        Write-Host "  Would update test file $testFileName with audit status: $testImplStatus" -ForegroundColor Cyan
        foreach ($key in $testUpdates.Keys) {
            Write-Host "    $key`: $($testUpdates[$key])" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✅ Test file $testFileName updated successfully" -ForegroundColor Green
    }

    # Update 2: Feature Tracking (Aggregated Status)
    Write-Host ""
    Write-Host "Updating Feature Tracking (Aggregated)..." -ForegroundColor Yellow

    # Calculate aggregated test status for the feature
    $projectRoot = Get-ProjectRoot
    $testTrackingPath = Join-Path $projectRoot "test/state-tracking/permanent/test-tracking.md"
    $content = Get-Content $testTrackingPath -Raw

    # Find all test files for this feature and their statuses
    $featureTestStatuses = @()
    $lines = $content -split "`r?`n"

    foreach ($line in $lines) {
        # 8-column format (SC-007): | Feature ID | Test Type | Test File/Case | Status | ...
        if ($line -match "^\|\s*$([regex]::Escape($FeatureId))\s*\|") {
            $cols = $line -split '\|' | ForEach-Object { $_.Trim() }
            # cols[0]=empty, cols[1]=Feature ID, cols[2]=Test Type, cols[3]=Test File/Case, cols[4]=Status
            if ($cols.Count -ge 5) {
                $status = $cols[4]

                # Update the status if this is our current test file
                if ($cols[3] -match [regex]::Escape($testFileName)) {
                    $status = $testImplStatus
                }

                $featureTestStatuses += $status
            }
        }
    }

    # Calculate aggregated status
    $aggregatedStatus = if ($featureTestStatuses -contains "🔴 Audit Failed") {
        "🔴 Tests Failed Audit"
    } elseif ($featureTestStatuses -contains "🔄 Needs Update") {
        "🔄 Tests Need Update"
    } elseif ($featureTestStatuses -contains "🔍 Audit In Progress") {
        "🔍 Audit In Progress"
    } elseif ($featureTestStatuses -notcontains "✅ Tests Approved" -and $featureTestStatuses.Count -gt 0) {
        "🟡 Tests In Progress"
    } elseif ($featureTestStatuses -contains "✅ Tests Approved" -and $featureTestStatuses.Count -gt 0) {
        if (($featureTestStatuses | Where-Object { $_ -eq "✅ Tests Approved" }).Count -eq $featureTestStatuses.Count) {
            "✅ Tests Approved"
        } else {
            "🟡 Tests Partially Approved"
        }
    } else {
        "⬜ No Tests"
    }

    # Update feature tracking Test Status column only — audit details live in
    # test-tracking.md and individual audit reports, not in the Notes column
    # (PF-IMP-413: Notes column cleanup)
    $featureResult = Update-FeatureTrackingStatus -FeatureId $FeatureId -Status $aggregatedStatus -StatusColumn "Test Status" -DryRun:$DryRun

    if ($DryRun) {
        Write-Host "  Would update feature $FeatureId test status to: $aggregatedStatus" -ForegroundColor Cyan
    } else {
        Write-Host "  ✅ Feature tracking updated successfully" -ForegroundColor Green
    }

    # Summary
    Write-Host ""
    Write-Host "Test File Audit State Update Summary" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "Test File: $TestFilePath" -ForegroundColor White
    Write-Host "Feature ID: $FeatureId" -ForegroundColor White
    Write-Host "Audit Status: $AuditStatus" -ForegroundColor White
    Write-Host "Audit Date: $AuditDate" -ForegroundColor White

    if ($AuditorName) {
        Write-Host "Auditor: $AuditorName" -ForegroundColor White
    }

    if ($AuditReportPath) {
        Write-Host "Audit Report: $AuditReportPath" -ForegroundColor White
    }

    if ($TestCasesAudited) {
        Write-Host "Test Cases Audited: $TestCasesAudited" -ForegroundColor White
    }

    if ($PassedTests -or $FailedTests) {
        Write-Host "Audit Results: Passed: $PassedTests, Failed: $FailedTests" -ForegroundColor White
    }

    if ($MajorFindings.Count -gt 0) {
        Write-Host "Major Findings:" -ForegroundColor White
        foreach ($finding in $MajorFindings) {
            Write-Host "  - $finding" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "Files Updated:" -ForegroundColor White
    Write-Host "  ✅ test-tracking.md (individual test file)" -ForegroundColor Green
    Write-Host "  ✅ feature-tracking.md (aggregated status)" -ForegroundColor Green

    if ($DryRun) {
        Write-Host ""
        Write-Host "DRY RUN COMPLETED - No actual changes were made" -ForegroundColor Yellow
        Write-Host "Run without -DryRun to apply these changes" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "✅ Test file audit state update completed successfully!" -ForegroundColor Green

        # Validation
        Write-Host ""
        Write-Host "Running validation..." -ForegroundColor Yellow
        Write-Host "✅ Validation skipped (function not implemented)" -ForegroundColor Yellow

        # Next steps guidance
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Yellow
        if ($AuditStatus -eq "Needs Update") {
            Write-Host "  1. Address the identified issues in test file $testFileName" -ForegroundColor Gray
            Write-Host "  2. Re-run tests after fixes are applied" -ForegroundColor Gray
            Write-Host "  3. Schedule follow-up audit when ready" -ForegroundColor Gray
        } elseif ($AuditStatus -eq "Tests Approved") {
            Write-Host "  1. Test file $testFileName is approved" -ForegroundColor Gray
            Write-Host "  2. Check if all tests for feature $FeatureId are approved" -ForegroundColor Gray
            Write-Host "  3. If all tests approved, feature is ready for implementation" -ForegroundColor Gray
        } elseif ($AuditStatus -eq "Audit Failed") {
            Write-Host "  1. Review audit report for critical issues in $testFileName" -ForegroundColor Gray
            Write-Host "  2. Address fundamental test problems before proceeding" -ForegroundColor Gray
            Write-Host "  3. Consider reverting to previous test implementation if needed" -ForegroundColor Gray
        }
    }

}
catch {
    Write-Error "Test file audit state update failed: $($_.Exception.Message)"
    exit 1
}
