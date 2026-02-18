# TestTracking.psm1
# Test tracking operations and registry management
# Extracted from StateFileManagement.psm1 as part of module decomposition
#
# VERSION 1.0 - EXTRACTED MODULE
# This module contains test-specific tracking operations

<#
.SYNOPSIS
Test tracking operations and registry management for PowerShell scripts

.DESCRIPTION
This module provides specialized functionality for test tracking:
- Updating test implementation status in tracking files
- Adding test registry entries to test-registry.yaml
- Managing test file metadata and cross-references

This is a focused module extracted from StateFileManagement.psm1 to improve
maintainability and reduce complexity.

.NOTES
Version: 1.0 (Extracted Module)
Created: 2025-08-30
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
        "Test File" = "[PD-TST-001](test/unit/example_test.dart)"
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

        # Update test-implementation-tracking.md
        $testTrackingPath = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/test-implementation-tracking.md"
        if (Test-Path $testTrackingPath) {
            try {
                if ($DryRun) {
                    Write-Host "DRY RUN: Would update test-implementation-tracking.md" -ForegroundColor Yellow
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
                    $updatedContent = Update-MarkdownTable -Content $content -FeatureId $FeatureId -StatusColumn "Implementation Status" -Status $Status -AdditionalUpdates $AdditionalUpdates -Notes $Notes

                    # Update metadata timestamp
                    $updatedContent = $updatedContent -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $timestamp"

                    # Save updated content
                    Set-Content $testTrackingPath $updatedContent -Encoding UTF8
                    Write-Verbose "Updated test-implementation-tracking.md"
                }

                $results += @{
                    File = "test-implementation-tracking.md"
                    Success = $true
                    Message = "Updated test implementation status"
                }
            } catch {
                $results += @{
                    File = "test-implementation-tracking.md"
                    Success = $false
                    Message = "Failed to update: $($_.Exception.Message)"
                }
                Write-Warning "Failed to update test-implementation-tracking.md: $($_.Exception.Message)"
            }
        } else {
            Write-Warning "Test implementation tracking file not found: $testTrackingPath"
            $results += @{
                File = "test-implementation-tracking.md"
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

function Add-TestRegistryEntry {
    <#
    .SYNOPSIS
    Adds a new test file entry to test-registry.yaml

    .DESCRIPTION
    Creates a new test file entry in the test-registry.yaml file with proper formatting and metadata.
    Automatically generates the next available PD-TST ID and inserts the entry in the correct location.

    .PARAMETER FeatureId
    The feature ID this test belongs to (e.g., "0.2.5", "1.1.1")

    .PARAMETER FileName
    The test file name (e.g., "example_test.dart")

    .PARAMETER FilePath
    The relative path to the test file from project root (e.g., "test/unit/example_test.dart")

    .PARAMETER TestType
    The type of test (Unit, Widget, Integration, E2E)

    .PARAMETER ComponentName
    The name of the component being tested

    .PARAMETER SpecificationPath
    Optional path to the test specification file

    .PARAMETER Description
    Description of what the test covers

    .PARAMETER DryRun
    If specified, shows what would be added without making changes

    .EXAMPLE
    Add-TestRegistryEntry -FeatureId "0.2.5" -FileName "logger_test.dart" -FilePath "test/unit/logger_test.dart" -TestType "Unit" -ComponentName "Logger" -Description "Unit tests for Logger service"

    .RETURNS
    Returns the generated PD-TST ID if successful, null if failed
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$FileName,

        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [string]$TestType,

        [Parameter(Mandatory=$true)]
        [string]$ComponentName,

        [Parameter(Mandatory=$false)]
        [string]$SpecificationPath = $null,

        [Parameter(Mandatory=$false)]
        [string]$Description = "",

        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )

    try {
        $projectRoot = Get-ProjectRoot
        $testRegistryPath = Join-Path $projectRoot "test/test-registry.yaml"
        $timestamp = Get-ProjectTimestamp -Format "Date"

        if (-not (Test-Path $testRegistryPath)) {
            throw "Test registry file not found: $testRegistryPath"
        }

        # Read current content
        $content = Get-Content $testRegistryPath -Raw -Encoding UTF8
        $lines = $content -split '\r?\n'

        # Find the highest existing PD-TST ID to generate the next one
        $maxId = 0
        foreach ($line in $lines) {
            # Look for both formats: "- id: PD-TST-001" and "PD-TST-001:"
            if ($line -match 'PD-TST-(\d+)[:)]?') {
                $currentId = [int]$matches[1]
                if ($currentId -gt $maxId) {
                    $maxId = $currentId
                }
            }
        }

        $nextId = $maxId + 1
        $testFileId = "PD-TST-{0:D3}" -f $nextId

        # Create the new YAML entry
        $yamlEntry = @"
  $testFileId`:
    feature_id: "$FeatureId"
    file_name: "$FileName"
    file_path: "$FilePath"
    test_type: "$TestType"
    component_name: "$ComponentName"
    description: "$Description"
    created_date: "$timestamp"
    status: "Created"
"@

        if ($SpecificationPath) {
            $yamlEntry += "`n    specification_path: `"$SpecificationPath`""
        }

        if ($DryRun) {
            Write-Host "DRY RUN: Would add new entry to test-registry.yaml" -ForegroundColor Yellow
            Write-Host "  Test File ID: $testFileId" -ForegroundColor Cyan
            Write-Host "  Feature ID: $FeatureId" -ForegroundColor Cyan
            Write-Host "  File Path: $FilePath" -ForegroundColor Cyan
            Write-Host "  Test Type: $TestType" -ForegroundColor Cyan
            Write-Host "  Component: $ComponentName" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "YAML Entry:" -ForegroundColor Yellow
            Write-Host $yamlEntry -ForegroundColor Cyan
            return $testFileId
        }

        # Create backup
        $backupPath = Get-StateFileBackup -FilePath $testRegistryPath
        Write-Verbose "Created backup: $backupPath"

        # Find the appropriate location to insert the new entry
        # Insert at the end of the test_files section
        $updatedLines = @()
        $inTestFilesSection = $false
        $insertIndex = -1

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]

            if ($line -match '^test_files:') {
                $inTestFilesSection = $true
                $updatedLines += $line
                continue
            }

            # If we're in the test_files section and encounter a non-indented line, we've reached the end
            if ($inTestFilesSection -and $line -match '^[a-zA-Z]' -and -not ($line -match '^\s')) {
                $insertIndex = $i
                break
            }

            $updatedLines += $line
        }

        # Insert the new entry
        if ($insertIndex -eq -1) {
            # Add at the end of the file
            $updatedLines += $yamlEntry -split '\r?\n'
        } else {
            # Insert before the next section
            $updatedLines += $yamlEntry -split '\r?\n'
            $updatedLines += $lines[$insertIndex..($lines.Count-1)]
        }

        # Write back to file
        $updatedContent = $updatedLines -join "`n"
        Set-Content $testRegistryPath $updatedContent -Encoding UTF8

        Write-Verbose "Added new test registry entry: $testFileId for feature $FeatureId"
        return $testFileId

    } catch {
        Write-Error "Failed to add test registry entry: $($_.Exception.Message)"
        return $null
    }
}

function Get-TestTrackingSectionTitle {
    <#
    .SYNOPSIS
    Determines the appropriate section title for a feature ID in test-implementation-tracking.md
    #>
    param([string]$FeatureId)

    # Parse feature ID to determine section
    if ($FeatureId -match '^99\.') {
        return "Test Features (Development & Testing)"
    } elseif ($FeatureId -match '^0\.') {
        return "System Architecture & Foundation Tests"
    } elseif ($FeatureId -match '^1\.') {
        return "User Authentication & Registration Tests"
    } else {
        return "Other Tests"
    }
}

function Get-TestTrackingSectionNumber {
    <#
    .SYNOPSIS
    Determines the appropriate section number for a feature ID in test-implementation-tracking.md
    #>
    param([string]$FeatureId)

    # Parse feature ID to determine section number
    if ($FeatureId -match '^99\.') {
        return "99"
    } elseif ($FeatureId -match '^0\.') {
        return "0"
    } elseif ($FeatureId -match '^1\.') {
        return "1"
    } else {
        return "12"  # Default "Other" section
    }
}

function Ensure-TestTrackingSection {
    <#
    .SYNOPSIS
    Ensures that the required section exists in test-implementation-tracking.md

    .PARAMETER Content
    The current content of the test-implementation-tracking.md file

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

    $sectionNumber = Get-TestTrackingSectionNumber -FeatureId $FeatureId
    $sectionTitle = Get-TestTrackingSectionTitle -FeatureId $FeatureId
    $sectionHeader = "## $sectionNumber. $sectionTitle"

    # Check if section already exists
    if ($Content -match [regex]::Escape($sectionHeader)) {
        Write-Verbose "Section already exists: $sectionHeader"
        return $Content
    }

    Write-Verbose "Creating missing section: $sectionHeader"

    # Create the section content
    $sectionContent = @"
$sectionHeader

| Test File ID | Feature ID | Test File | Implementation Status | Test Cases Count | Last Updated | Notes |
|--------------|------------|-----------|----------------------|------------------|--------------|-------|
| *No test files created yet* | | | | | | |

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
    Adds a new test implementation entry to the test-implementation-tracking.md file

    .PARAMETER Content
    The current content of the test-implementation-tracking.md file

    .PARAMETER TestFileId
    The test file ID (e.g., PD-TST-087)

    .PARAMETER FeatureId
    The feature ID (e.g., 99.1.2)

    .PARAMETER TestFilePath
    The path to the test file

    .PARAMETER Status
    The implementation status

    .PARAMETER TestCasesCount
    Number of test cases (optional)

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
        [string]$TestFileId,

        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$TestFilePath,

        [Parameter(Mandatory=$true)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [string]$TestCasesCount = "",

        [Parameter(Mandatory=$false)]
        [string]$Notes = ""
    )

    $timestamp = Get-ProjectTimestamp -Format "Date"
    $sectionNumber = Get-TestTrackingSectionNumber -FeatureId $FeatureId
    $sectionTitle = Get-TestTrackingSectionTitle -FeatureId $FeatureId
    $sectionHeader = "## $sectionNumber. $sectionTitle"

    # Create the test file link - extract filename from path for display
    $fileName = Split-Path $TestFilePath -Leaf
    $testFileLink = "[$fileName]($TestFilePath)"

    # Create the new table row
    $newRow = "| $TestFileId | $FeatureId | $testFileLink | $Status | $TestCasesCount | $timestamp | $Notes |"

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
        Write-Verbose "Added test entry $TestFileId to section $sectionHeader"
    }

    return $updatedLines -join "`n"
}

function Update-TestImplementationStatusEnhanced {
    <#
    .SYNOPSIS
    Enhanced version of Update-TestImplementationStatus that handles missing sections and entries

    .PARAMETER FeatureId
    The feature ID to update

    .PARAMETER TestFileId
    The test file ID (e.g., PD-TST-087)

    .PARAMETER TestFilePath
    The path to the test file

    .PARAMETER Status
    The new test implementation status

    .PARAMETER TestCasesCount
    Number of test cases (optional)

    .PARAMETER Notes
    Additional notes (optional)

    .PARAMETER DryRun
    If specified, shows what would be updated without making changes

    .EXAMPLE
    Update-TestImplementationStatusEnhanced -FeatureId "99.1.2" -TestFileId "PD-TST-087" -TestFilePath "test/unit/example_test.dart" -Status "🟡 Implementation In Progress"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$TestFileId,

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

        # Update test-implementation-tracking.md
        $testTrackingPath = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/test-implementation-tracking.md"
        if (Test-Path $testTrackingPath) {
            try {
                if ($DryRun) {
                    Write-Host "DRY RUN: Would update test-implementation-tracking.md (enhanced)" -ForegroundColor Yellow
                    Write-Host "  Feature ID: $FeatureId" -ForegroundColor Cyan
                    Write-Host "  Test File ID: $TestFileId" -ForegroundColor Cyan
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

                    # Add the test implementation entry
                    $updatedContent = Add-TestImplementationEntry -Content $contentWithSection -TestFileId $TestFileId -FeatureId $FeatureId -TestFilePath $TestFilePath -Status $Status -TestCasesCount $TestCasesCount -Notes $Notes

                    # Update metadata timestamp
                    $updatedContent = $updatedContent -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $timestamp"

                    # Save updated content
                    Set-Content $testTrackingPath $updatedContent -Encoding UTF8
                    Write-Verbose "Updated test-implementation-tracking.md with enhanced functionality"
                }

                return @{
                    Success = $true
                    Message = "Updated test implementation tracking (enhanced)"
                }
            } catch {
                Write-Warning "Failed to update test-implementation-tracking.md: $($_.Exception.Message)"
                return @{
                    Success = $false
                    Message = "Failed to update: $($_.Exception.Message)"
                }
            }
        } else {
            Write-Warning "Test implementation tracking file not found: $testTrackingPath"
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
    'Add-TestRegistryEntry',
    'Get-TestTrackingSectionTitle',
    'Get-TestTrackingSectionNumber',
    'Ensure-TestTrackingSection',
    'Add-TestImplementationEntry',
    'Update-TestImplementationStatusEnhanced'
)

Write-Verbose "TestTracking module loaded with 7 functions"
