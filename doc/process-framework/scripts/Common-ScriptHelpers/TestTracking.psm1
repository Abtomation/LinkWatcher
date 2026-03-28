# TestTracking.psm1
# Test tracking operations and marker management
# Extracted from StateFileManagement.psm1 as part of module decomposition
#
# VERSION 2.0 - MARKER-BASED (SC-007)
# This module contains test-specific tracking operations.
# As of SC-007, test metadata is stored as pytest markers in test files
# (single source of truth) rather than in test-registry.yaml.

<#
.SYNOPSIS
Test tracking operations and pytest marker management for PowerShell scripts

.DESCRIPTION
This module provides specialized functionality for test tracking:
- Updating test implementation status in tracking files
- Writing pytest markers into test files (feature, priority, test_type, specification)
- Managing test file metadata via markers as single source of truth

This is a focused module extracted from StateFileManagement.psm1 to improve
maintainability and reduce complexity.

.NOTES
Version: 2.0 (Marker-Based — SC-007)
Created: 2025-08-30
Updated: 2026-03-26
Extracted From: StateFileManagement.psm1
Dependencies: Get-ProjectRoot, Get-ProjectTimestamp, Update-MarkdownTable
#>

# Configure UTF-8 encoding for consistent Unicode support
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'

function Update-TestImplementationStatus {
    <#
    .SYNOPSIS
    Updates test implementation tracking files for a specific feature

    .PARAMETER FeatureId
    The feature ID to update

    .PARAMETER Status
    The new test implementation status

    .PARAMETER AdditionalUpdates
    Hashtable of additional column updates (column name -> value)

    .PARAMETER Notes
    Additional notes to append

    .PARAMETER DryRun
    If specified, shows what would be updated without making changes

    .EXAMPLE
    $additionalUpdates = @{
        "Test File" = "[TE-TST-001](test/unit/example_test)"
        "Test Cases Count" = "15"
    }
    Update-TestImplementationStatus -FeatureId "1.2.3" -Status "🟡 Implementation In Progress" -AdditionalUpdates $additionalUpdates
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalUpdates = @{},

        [Parameter(Mandatory=$false)]
        [string]$Notes,

        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )

    try {
        $projectRoot = Get-ProjectRoot
        $timestamp = Get-ProjectTimestamp -Format "Date"
        $results = @()

        Write-Verbose "Updating test implementation status for feature: $FeatureId"

        # Update test-tracking.md
        $testTrackingPath = Join-Path $projectRoot "test/state-tracking/permanent/test-tracking.md"
        if (Test-Path $testTrackingPath) {
            try {
                if ($DryRun) {
                    Write-Host "DRY RUN: Would update test-tracking.md" -ForegroundColor Yellow
                    Write-Host "  Feature ID: $FeatureId" -ForegroundColor Cyan
                    Write-Host "  Status: $Status" -ForegroundColor Cyan
                    if ($AdditionalUpdates.Count -gt 0) {
                        Write-Host "  Additional Updates:" -ForegroundColor Cyan
                        foreach ($key in $AdditionalUpdates.Keys) {
                            Write-Host "    $key = $($AdditionalUpdates[$key])" -ForegroundColor Cyan
                        }
                    }
                } else {
                    # Create backup
                    $backupPath = Get-StateFileBackup -FilePath $testTrackingPath
                    Write-Verbose "Created backup: $backupPath"

                    # Read current content
                    $content = Get-Content $testTrackingPath -Raw -Encoding UTF8

                    # Update the table using the extracted function
                    $updatedContent = Update-MarkdownTable -Content $content -FeatureId $FeatureId -StatusColumn "Status" -Status $Status -AdditionalUpdates $AdditionalUpdates -Notes $Notes

                    # Update metadata timestamp
                    $updatedContent = $updatedContent -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $timestamp"

                    # Save updated content
                    Set-Content $testTrackingPath $updatedContent -Encoding UTF8
                    Write-Verbose "Updated test-tracking.md"
                }

                $results += @{
                    File = "test-tracking.md"
                    Success = $true
                    Message = "Updated test implementation status"
                }
            } catch {
                $results += @{
                    File = "test-tracking.md"
                    Success = $false
                    Message = "Failed to update: $($_.Exception.Message)"
                }
                Write-Warning "Failed to update test-tracking.md: $($_.Exception.Message)"
            }
        } else {
            Write-Warning "Test tracking file not found: $testTrackingPath"
            $results += @{
                File = "test-tracking.md"
                Success = $false
                Message = "File not found"
            }
        }

        # Summary
        if ($DryRun) {
            Write-Host ""
            Write-Host "DRY RUN SUMMARY:" -ForegroundColor Yellow
            foreach ($result in $results) {
                $status = if ($result.Success) { "✅" } else { "❌" }
                Write-Host "  $status $($result.File): $($result.Message)" -ForegroundColor Cyan
            }
        } else {
            $successCount = ($results | Where-Object { $_.Success }).Count
            $totalCount = $results.Count
            Write-Verbose "📊 Test tracking files updated: $successCount/$totalCount successful"

            foreach ($result in $results) {
                if (-not $result.Success) {
                    Write-Warning "❌ $($result.File): $($result.Message)"
                }
            }
        }

        return $results
    }
    catch {
        Write-Error "Failed to update test implementation status: $($_.Exception.Message)"
        throw
    }
}

function Add-PytestMarkers {
    <#
    .SYNOPSIS
    Writes pytest markers into a Python test file

    .DESCRIPTION
    Updates the pytestmark list in a Python test file with feature, priority, test_type,
    and optionally specification markers. These markers serve as the single source of truth
    for test metadata (SC-007).

    .PARAMETER FilePath
    Absolute path to the Python test file

    .PARAMETER FeatureId
    The feature ID this test belongs to (e.g., "0.2.5", "1.1.1")

    .PARAMETER TestType
    The test type marker value (e.g., "unit", "integration", "parser", "performance")

    .PARAMETER Priority
    Test priority: Critical, Standard, or Extended (default: Standard)

    .PARAMETER SpecificationPath
    Optional relative path to the test specification file

    .PARAMETER DryRun
    If specified, shows what would be changed without making changes

    .EXAMPLE
    Add-PytestMarkers -FilePath "C:\project\test\unit\test_service.py" -FeatureId "0.1.1" -TestType "unit" -Priority "Critical"

    .EXAMPLE
    Add-PytestMarkers -FilePath "C:\project\test\unit\test_service.py" -FeatureId "0.1.1" -TestType "unit" -SpecificationPath "test/specifications/feature-specs/test-spec-0-1-1.md"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$TestType,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Critical", "Standard", "Extended")]
        [string]$Priority = "Standard",

        [Parameter(Mandatory=$false)]
        [string]$SpecificationPath = $null,

        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )

    try {
        if (-not (Test-Path $FilePath)) {
            throw "Test file not found: $FilePath"
        }

        $content = Get-Content $FilePath -Raw -Encoding UTF8

        # Replace template placeholders in pytestmark block
        $updated = $content
        $updated = $updated -replace '\[FEATURE_ID\]', $FeatureId
        $updated = $updated -replace '\[PRIORITY\]', $Priority
        $updated = $updated -replace '\[TEST_TYPE_MARKER\]', $TestType.ToLower()

        # If specification path provided, uncomment and set the specification marker
        if ($SpecificationPath) {
            $updated = $updated -replace '    # TODO\(dev\): Uncomment and set specification path if a test spec exists\r?\n    # pytest\.mark\.specification\("test/specifications/feature-specs/\.\.\."\),', "    pytest.mark.specification(`"$SpecificationPath`"),"
        }

        if ($DryRun) {
            Write-Host "DRY RUN: Would update pytest markers in $FilePath" -ForegroundColor Yellow
            Write-Host "  Feature ID: $FeatureId" -ForegroundColor Cyan
            Write-Host "  Test Type: $TestType" -ForegroundColor Cyan
            Write-Host "  Priority: $Priority" -ForegroundColor Cyan
            if ($SpecificationPath) {
                Write-Host "  Specification: $SpecificationPath" -ForegroundColor Cyan
            }
            return
        }

        Set-Content $FilePath $updated -Encoding UTF8
        Write-Verbose "Updated pytest markers in $FilePath"

    } catch {
        Write-Error "Failed to update pytest markers: $($_.Exception.Message)"
    }
}

function Get-TestTrackingSectionHeader {
    <#
    .SYNOPSIS
    Finds the actual section header in test-tracking.md content that matches a feature ID.
    Matches by the leading number in "## N. Title" against the feature ID's major version.

    .PARAMETER Content
    The content of test-tracking.md

    .PARAMETER FeatureId
    The feature ID (e.g., "1.1.1", "2.2.1")

    .RETURNS
    The full section header string (e.g., "## 1. File Watching & Detection"), or $null if not found
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$FeatureId
    )

    # Extract major version number from feature ID (e.g., "1" from "1.1.1", "0" from "0.1.2")
    $majorVersion = ($FeatureId -split '\.')[0]

    # Find the matching section header in the content
    $pattern = "^## $majorVersion\. .+"
    $match = [regex]::Match($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)

    if ($match.Success) {
        return $match.Value.Trim()
    }

    return $null
}

function Get-TestTrackingSectionTitle {
    <#
    .SYNOPSIS
    Determines the appropriate section title for a feature ID in test-tracking.md.
    Reads from test-tracking.md on disk to get the actual section title.
    Falls back to a generated title if the file cannot be read.
    #>
    param([string]$FeatureId)

    # Try to read the actual section header from test-tracking.md
    try {
        $projectRoot = Get-ProjectRoot
        $trackingPath = Join-Path $projectRoot "test/state-tracking/permanent/test-tracking.md"
        if (Test-Path $trackingPath) {
            $content = Get-Content $trackingPath -Raw -Encoding UTF8
            $header = Get-TestTrackingSectionHeader -Content $content -FeatureId $FeatureId
            if ($header -and $header -match '^## \d+\.\s+(.+)$') {
                return $matches[1]
            }
        }
    } catch {
        Write-Verbose "Could not read test-tracking.md for section title: $($_.Exception.Message)"
    }

    # Fallback: generate from major version
    $majorVersion = ($FeatureId -split '\.')[0]
    return "Feature Group $majorVersion"
}

function Get-TestTrackingSectionNumber {
    <#
    .SYNOPSIS
    Determines the appropriate section number for a feature ID in test-tracking.md.
    Extracts the major version from the feature ID.
    #>
    param([string]$FeatureId)

    return ($FeatureId -split '\.')[0]
}

function Ensure-TestTrackingSection {
    <#
    .SYNOPSIS
    Ensures that the required section exists in test-tracking.md

    .PARAMETER Content
    The current content of the test-tracking.md file

    .PARAMETER FeatureId
    The feature ID to determine which section is needed

    .RETURNS
    Updated content with the section created if it was missing
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$FeatureId
    )

    # First check if a matching section already exists in the content
    $existingHeader = Get-TestTrackingSectionHeader -Content $Content -FeatureId $FeatureId
    if ($existingHeader) {
        Write-Verbose "Section already exists: $existingHeader"
        return $Content
    }

    # Section doesn't exist — construct a new one
    $sectionNumber = Get-TestTrackingSectionNumber -FeatureId $FeatureId
    $sectionTitle = Get-TestTrackingSectionTitle -FeatureId $FeatureId
    $sectionHeader = "## $sectionNumber. $sectionTitle"

    # Double-check with exact match (shouldn't reach here, but safety)
    if ($Content -match [regex]::Escape($sectionHeader)) {
        Write-Verbose "Section already exists: $sectionHeader"
        return $Content
    }

    Write-Verbose "Creating missing section: $sectionHeader"

    # Create the section content (8-column format, file path as identifier — SC-007)
    $sectionContent = @"
$sectionHeader

| Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
|------------|-----------|----------------|--------|------------------|---------------|--------------|-------|
| *No test files created yet* | | | | | | | |

"@

    $lines = $Content -split '\r?\n'
    $updatedLines = @()
    $inserted = $false

    # Find the right place to insert the section
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Insert before "Process Instructions" section or at the end
        # Look for the --- separator that comes before Process Instructions
        if ($line -match '^---$') {
            # Check if this is followed by Process Instructions (with possible empty line in between)
            $nextNonEmptyIndex = $i + 1
            while ($nextNonEmptyIndex -lt $lines.Count -and $lines[$nextNonEmptyIndex] -match '^\s*$') {
                $nextNonEmptyIndex++
            }

            if ($nextNonEmptyIndex -lt $lines.Count -and $lines[$nextNonEmptyIndex] -match '^## Process Instructions') {
                $updatedLines += $sectionContent -split '\r?\n'
                $updatedLines += $line
                $inserted = $true
            } else {
                $updatedLines += $line
            }
        } else {
            $updatedLines += $line
        }
    }

    # If we didn't find the Process Instructions section, add at the end
    if (-not $inserted) {
        $updatedLines += ""
        $updatedLines += $sectionContent -split '\r?\n'
    }

    return $updatedLines -join "`n"
}

function Add-TestImplementationEntry {
    <#
    .SYNOPSIS
    Adds a new test implementation entry to the test-tracking.md file

    .PARAMETER Content
    The current content of the test-tracking.md file

    .PARAMETER FeatureId
    The feature ID (e.g., 99.1.2)

    .PARAMETER TestFilePath
    The path to the test file (used as unique identifier and display link)

    .PARAMETER Status
    The implementation status

    .PARAMETER TestType
    The test type: "Automated", "E2E Group", or "E2E Case" (default: "Automated")

    .PARAMETER TestCasesCount
    Number of test cases (optional)

    .PARAMETER LastExecuted
    Date of last test execution (optional, defaults to "—")

    .PARAMETER Notes
    Additional notes (optional)

    .RETURNS
    Updated content with the new test entry added
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$TestFilePath,

        [Parameter(Mandatory=$true)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Automated", "E2E Group", "E2E Case")]
        [string]$TestType = "Automated",

        [Parameter(Mandatory=$false)]
        [string]$TestCasesCount = "",

        [Parameter(Mandatory=$false)]
        [string]$LastExecuted = "",

        [Parameter(Mandatory=$false)]
        [string]$Notes = ""
    )

    $timestamp = Get-ProjectTimestamp -Format "Date"
    $sectionHeader = Get-TestTrackingSectionHeader -Content $Content -FeatureId $FeatureId
    if (-not $sectionHeader) {
        # Fallback: construct from helpers (may trigger Ensure-TestTrackingSection to create it)
        $sectionNumber = Get-TestTrackingSectionNumber -FeatureId $FeatureId
        $sectionTitle = Get-TestTrackingSectionTitle -FeatureId $FeatureId
        $sectionHeader = "## $sectionNumber. $sectionTitle"
    }

    # Default LastExecuted based on test type
    if (-not $LastExecuted) {
        $LastExecuted = "—"
    }

    # Create the test file link - extract filename from path for display
    $fileName = Split-Path $TestFilePath -Leaf
    $testFileLink = "[$fileName]($TestFilePath)"

    # Create the new table row (8 columns: Feature ID, Test Type, Test File/Case, Status, Test Cases Count, Last Executed, Last Updated, Notes — SC-007)
    $newRow = "| $FeatureId | $TestType | $testFileLink | $Status | $TestCasesCount | $LastExecuted | $timestamp | $Notes |"

    $lines = $Content -split '\r?\n'
    $updatedLines = @()
    $inTargetSection = $false
    $inTable = $false
    $entryAdded = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Check if we're entering the target section
        if ($line -match [regex]::Escape($sectionHeader)) {
            $inTargetSection = $true
            $updatedLines += $line
            continue
        }

        # Check if we're leaving the current section
        if ($inTargetSection -and $line -match '^## \d+\.' -and $line -notmatch [regex]::Escape($sectionHeader)) {
            $inTargetSection = $false
            $inTable = $false
        }

        # If we're in the target section and find a table
        if ($inTargetSection -and $line -match '^\|.*\|$') {
            if (-not $inTable) {
                $inTable = $true
                $updatedLines += $line
                continue
            }

            # Skip separator line
            if ($line -match '^\|[-\s:]+\|$') {
                $updatedLines += $line
                continue
            }

            # Check if this is the placeholder row
            if ($line -match '\*No test files created yet\*') {
                # Replace placeholder with our new entry
                $updatedLines += $newRow
                $entryAdded = $true
                continue
            } else {
                # This is a real entry, add our new entry at the end of the table if not already added
                $updatedLines += $line
                continue
            }
        }

        # If we're leaving the table in our target section and haven't added the entry yet
        if ($inTargetSection -and $inTable -and $line -notmatch '^\|.*\|$' -and -not $entryAdded) {
            # Add the new row before leaving the table
            $updatedLines += $newRow
            $entryAdded = $true
            $inTable = $false
        }

        # If we're leaving the target section and haven't added the entry
        if ($inTargetSection -and -not $inTable -and $line -match '^## \d+\.' -and -not $entryAdded) {
            # This shouldn't happen if the section has a proper table, but handle it
            Write-Warning "Could not find table in section $sectionHeader to add entry"
        }

        $updatedLines += $line
    }

    if (-not $entryAdded) {
        Write-Warning "Failed to add test entry to section $sectionHeader"
    } else {
        Write-Verbose "Added test entry for $TestFilePath to section $sectionHeader"
    }

    return $updatedLines -join "`n"
}

function Update-TestImplementationStatusEnhanced {
    <#
    .SYNOPSIS
    Enhanced version of Update-TestImplementationStatus that handles missing sections and entries

    .PARAMETER FeatureId
    The feature ID to update

    .PARAMETER TestFilePath
    The path to the test file (used as unique identifier — SC-007)

    .PARAMETER Status
    The new test implementation status

    .PARAMETER TestCasesCount
    Number of test cases (optional)

    .PARAMETER Notes
    Additional notes (optional)

    .PARAMETER DryRun
    If specified, shows what would be updated without making changes

    .EXAMPLE
    Update-TestImplementationStatusEnhanced -FeatureId "0.1.1" -TestFilePath "../../automated/unit/test_service.py" -Status "🟡 Implementation In Progress"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$TestFilePath,

        [Parameter(Mandatory=$true)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [string]$TestCasesCount = "",

        [Parameter(Mandatory=$false)]
        [string]$Notes = "",

        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )

    try {
        $projectRoot = Get-ProjectRoot
        $timestamp = Get-ProjectTimestamp -Format "Date"

        Write-Verbose "Updating test implementation status (enhanced) for feature: $FeatureId"

        # Update test-tracking.md
        $testTrackingPath = Join-Path $projectRoot "test/state-tracking/permanent/test-tracking.md"
        if (Test-Path $testTrackingPath) {
            try {
                if ($DryRun) {
                    Write-Host "DRY RUN: Would update test-tracking.md (enhanced)" -ForegroundColor Yellow
                    Write-Host "  Feature ID: $FeatureId" -ForegroundColor Cyan
                    Write-Host "  Test File Path: $TestFilePath" -ForegroundColor Cyan
                    Write-Host "  Status: $Status" -ForegroundColor Cyan
                    if ($TestCasesCount) { Write-Host "  Test Cases: $TestCasesCount" -ForegroundColor Cyan }
                    if ($Notes) { Write-Host "  Notes: $Notes" -ForegroundColor Cyan }
                } else {
                    # Create backup
                    $backupPath = Get-StateFileBackup -FilePath $testTrackingPath
                    Write-Verbose "Created backup: $backupPath"

                    # Read current content
                    $content = Get-Content $testTrackingPath -Raw -Encoding UTF8

                    # Ensure the required section exists
                    $contentWithSection = Ensure-TestTrackingSection -Content $content -FeatureId $FeatureId

                    # Add the test implementation entry (file path as identifier — SC-007)
                    $updatedContent = Add-TestImplementationEntry -Content $contentWithSection -FeatureId $FeatureId -TestFilePath $TestFilePath -Status $Status -TestCasesCount $TestCasesCount -Notes $Notes

                    # Update metadata timestamp
                    $updatedContent = $updatedContent -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $timestamp"

                    # Save updated content
                    Set-Content $testTrackingPath $updatedContent -Encoding UTF8
                    Write-Verbose "Updated test-tracking.md with enhanced functionality"
                }

                return @{
                    Success = $true
                    Message = "Updated test implementation tracking (enhanced)"
                }
            } catch {
                Write-Warning "Failed to update test-tracking.md: $($_.Exception.Message)"
                return @{
                    Success = $false
                    Message = "Failed to update: $($_.Exception.Message)"
                }
            }
        } else {
            Write-Warning "Test tracking file not found: $testTrackingPath"
            return @{
                Success = $false
                Message = "File not found"
            }
        }

    }
    catch {
        Write-Error "Failed to update test implementation status (enhanced): $($_.Exception.Message)"
        throw
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Update-TestImplementationStatus',
    'Add-PytestMarkers',
    'Get-TestTrackingSectionTitle',
    'Get-TestTrackingSectionNumber',
    'Ensure-TestTrackingSection',
    'Add-TestImplementationEntry',
    'Update-TestImplementationStatusEnhanced'
)

Write-Verbose "TestTracking module loaded with 7 functions (SC-007: marker-based)"
