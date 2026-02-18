#!/usr/bin/env pwsh

<#
.SYNOPSIS
Comprehensive test suite for StateFileManagement.psm1 module

.DESCRIPTION
Tests all functions in the StateFileManagement module to ensure correct behavior
before and during refactoring. This test suite serves as a regression test
to ensure no functionality is broken during the module decomposition.

.NOTES
Created: 2025-08-30
Purpose: Support Code Refactoring Task (PF-TSK-022)
Refactoring Plan: PF-REF-014
#>

[CmdletBinding()]
param(
    [switch]$SkipFileModification
)

# Set up test environment
$ErrorActionPreference = 'Stop'
# Import Common-ScriptHelpers to get project root
Import-Module (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "Common-ScriptHelpers.psm1") -Force
Set-Location (Get-ProjectRoot)

# Import the module
Import-Module ".\doc\process-framework\scripts\Common-ScriptHelpers.psm1" -Force

# Test counters
$script:TestsPassed = 0
$script:TestsFailed = 0
$script:TestsSkipped = 0

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = "",
        [bool]$Skipped = $false
    )

    if ($Skipped) {
        Write-Host "⏭️  SKIP: $TestName" -ForegroundColor Yellow
        $script:TestsSkipped++
    } elseif ($Passed) {
        Write-Host "✅ PASS: $TestName" -ForegroundColor Green
        $script:TestsPassed++
    } else {
        Write-Host "❌ FAIL: $TestName" -ForegroundColor Red
        if ($Message) { Write-Host "   Message: $Message" -ForegroundColor Yellow }
        $script:TestsFailed++
    }
}

function Test-UpdateMarkdownTable {
    Write-Host "`n=== Testing Update-MarkdownTable Function ===" -ForegroundColor Cyan

    try {
        # Test basic table update functionality
        $testContent = @"
# Test Document

| Feature ID | Status | Notes |
|------------|--------|-------|
| 1.1.1 | 🟡 In Progress | Test feature |
| 1.1.2 | 🟢 Complete | Another feature |

Some other content.
"@

        $result = Update-MarkdownTable -Content $testContent -FeatureId "1.1.1" -StatusColumn "Status" -Status "🟢 Complete" -Notes "Updated via test"

        $statusUpdated = $result -match '1\.1\.1.*🟢 Complete.*Updated via test'
        Write-TestResult -TestName "Basic table update functionality" -Passed $statusUpdated

        # Test with non-existent feature ID
        $result2 = Update-MarkdownTable -Content $testContent -FeatureId "9.9.9" -StatusColumn "Status" -Status "🟢 Complete"
        $originalContentPreserved = $result2 -eq $testContent
        Write-TestResult -TestName "Handles non-existent feature ID gracefully" -Passed $originalContentPreserved

    } catch {
        Write-TestResult -TestName "Update-MarkdownTable basic functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-UpdateMarkdownTableWithAppend {
    Write-Host "`n=== Testing Update-MarkdownTableWithAppend Function ===" -ForegroundColor Cyan

    try {
        $testContent = @"
| Feature ID | Status | Notes |
|------------|--------|-------|
| 1.1.1 | 🟡 In Progress | Original notes |
"@

        $result = Update-MarkdownTableWithAppend -Content $testContent -FeatureId "1.1.1" -StatusColumn "Status" -Status "🟢 Complete" -Notes "Appended notes"

        $notesAppended = $result -match '1\.1\.1.*🟢 Complete.*Original notes; Appended notes'
        Write-TestResult -TestName "Notes appending functionality" -Passed $notesAppended

    } catch {
        Write-TestResult -TestName "Update-MarkdownTableWithAppend functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-GetRelevantTrackingFiles {
    Write-Host "`n=== Testing Get-RelevantTrackingFiles Function ===" -ForegroundColor Cyan

    try {
        # Test with TestSpecification document type
        $testSpecFiles = Get-RelevantTrackingFiles -DocumentType "TestSpecification" -DocumentId "PF-TSP-001"
        $hasTestSpecFiles = $testSpecFiles.Count -gt 0
        Write-TestResult -TestName "Returns files for TestSpecification documents" -Passed $hasTestSpecFiles

        # Test with ValidationReport document type
        $validationFiles = Get-RelevantTrackingFiles -DocumentType "ValidationReport" -DocumentId "PF-VLD-001"
        $hasValidationFiles = $validationFiles.Count -gt 0
        Write-TestResult -TestName "Returns files for ValidationReport documents" -Passed $hasValidationFiles

        # Verify different file sets for different document types
        $testSpecString = ($testSpecFiles | Sort-Object) -join ","
        $validationString = ($validationFiles | Sort-Object) -join ","
        $differentFileSets = $testSpecString -ne $validationString
        Write-TestResult -TestName "Different document types return different file sets" -Passed $differentFileSets

    } catch {
        Write-TestResult -TestName "Get-RelevantTrackingFiles functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-GetStateFileBackup {
    Write-Host "`n=== Testing Get-StateFileBackup Function ===" -ForegroundColor Cyan

    try {
        $testFile = "doc\process-framework\state-tracking\permanent\feature-tracking.md"

        if (Test-Path $testFile) {
            $backupPath = Get-StateFileBackup -FilePath $testFile
            $backupPathValid = $backupPath -like "*feature-tracking-backup-*"
            Write-TestResult -TestName "Generates valid backup path format" -Passed $backupPathValid

            # Test that backup path includes timestamp
            $hasTimestamp = $backupPath -match '\d{8}-\d{6}'
            Write-TestResult -TestName "Backup path includes timestamp" -Passed $hasTimestamp

            # Clean up the backup file (with retry for file locks)
            if (Test-Path $backupPath) {
                try {
                    Start-Sleep -Milliseconds 100  # Brief pause for file handles to release
                    Remove-Item $backupPath -Force -ErrorAction SilentlyContinue
                } catch {
                    # Ignore cleanup errors in tests
                }
            }
        } else {
            Write-TestResult -TestName "Get-StateFileBackup tests" -Skipped $true
        }

    } catch {
        Write-TestResult -TestName "Get-StateFileBackup functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-UpdateFeatureTrackingStatus {
    Write-Host "`n=== Testing Update-FeatureTrackingStatus Function ===" -ForegroundColor Cyan

    if ($SkipFileModification) {
        Write-TestResult -TestName "Update-FeatureTrackingStatus tests" -Skipped $true
        return
    }

    try {
        # Test dry run functionality
        $dryRunResult = Update-FeatureTrackingStatus -FeatureId "0.1.2" -Status "🧪 Test Status" -StatusColumn "Status" -DryRun

        $dryRunWorking = $dryRunResult.FeatureId -eq "0.1.2" -and $dryRunResult.Status -eq "🧪 Test Status"
        Write-TestResult -TestName "Dry run returns correct information" -Passed $dryRunWorking

        # Test with additional updates
        $additionalUpdates = @{"Test Status" = "🧪 Testing"}
        $result = Update-FeatureTrackingStatus -FeatureId "0.1.2" -Status "🧪 Updated" -StatusColumn "Status" -AdditionalUpdates $additionalUpdates -DryRun

        $additionalUpdatesWork = $result.AdditionalUpdates.ContainsKey("Test Status")
        Write-TestResult -TestName "Additional updates parameter works" -Passed $additionalUpdatesWork

    } catch {
        Write-TestResult -TestName "Update-FeatureTrackingStatus functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-UpdateFeatureTrackingStatusWithAppend {
    Write-Host "`n=== Testing Update-FeatureTrackingStatusWithAppend Function ===" -ForegroundColor Cyan

    if ($SkipFileModification) {
        Write-TestResult -TestName "Update-FeatureTrackingStatusWithAppend tests" -Skipped $true
        return
    }

    try {
        $result = Update-FeatureTrackingStatusWithAppend -FeatureId "0.1.2" -Status "🧪 Test" -StatusColumn "Status" -Notes "Test notes" -DryRun

        $appendFunctionWorks = $result.FeatureId -eq "0.1.2" -and $result.Notes -eq "Test notes"
        Write-TestResult -TestName "Append function returns correct information" -Passed $appendFunctionWorks

    } catch {
        Write-TestResult -TestName "Update-FeatureTrackingStatusWithAppend functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-UpdateMultipleTrackingFiles {
    Write-Host "`n=== Testing Update-MultipleTrackingFiles Function ===" -ForegroundColor Cyan

    if ($SkipFileModification) {
        Write-TestResult -TestName "Update-MultipleTrackingFiles tests" -Skipped $true
        return
    }

    try {
        $updates = @{
            "Status" = "🧪 Batch Test"
            "Test Status" = "🧪 Testing"
        }

        $result = Update-MultipleTrackingFiles -FeatureId "0.1.2" -Updates $updates -DryRun

        $batchUpdateWorks = $result.FeatureId -eq "0.1.2"
        Write-TestResult -TestName "Batch update function works" -Passed $batchUpdateWorks

    } catch {
        Write-TestResult -TestName "Update-MultipleTrackingFiles functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-UpdateDocumentTrackingFiles {
    Write-Host "`n=== Testing Update-DocumentTrackingFiles Function ===" -ForegroundColor Cyan

    if ($SkipFileModification) {
        Write-TestResult -TestName "Update-DocumentTrackingFiles tests" -Skipped $true
        return
    }

    try {
        $metadata = @{
            "document_type" = "TestDocument"
            "feature_id" = "99.1.1"
        }

        # Test dry run
        $result = Update-DocumentTrackingFiles -DocumentId "TEST-001" -DocumentType "TestDocument" -DocumentPath "/test/path" -Metadata $metadata -DryRun

        $documentTrackingWorks = $result -ne $null
        Write-TestResult -TestName "Document tracking function executes" -Passed $documentTrackingWorks

    } catch {
        Write-TestResult -TestName "Update-DocumentTrackingFiles functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-UpdateTestImplementationStatus {
    Write-Host "`n=== Testing Update-TestImplementationStatus Function ===" -ForegroundColor Cyan

    if ($SkipFileModification) {
        Write-TestResult -TestName "Update-TestImplementationStatus tests" -Skipped $true
        return
    }

    try {
        $result = Update-TestImplementationStatus -TestFileId "TEST-001" -Status "🧪 Testing" -DryRun

        $testStatusUpdateWorks = $result -ne $null
        Write-TestResult -TestName "Test status update function executes" -Passed $testStatusUpdateWorks

    } catch {
        Write-TestResult -TestName "Update-TestImplementationStatus functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-AddTestRegistryEntry {
    Write-Host "`n=== Testing Add-TestRegistryEntry Function ===" -ForegroundColor Cyan

    if ($SkipFileModification) {
        Write-TestResult -TestName "Add-TestRegistryEntry tests" -Skipped $true
        return
    }

    try {
        $result = Add-TestRegistryEntry -TestFileId "TEST-001" -TestFilePath "/test/path" -ComponentName "TestComponent" -TestType "Unit" -DryRun

        $addTestEntryWorks = $result -ne $null
        Write-TestResult -TestName "Add test registry entry function executes" -Passed $addTestEntryWorks

    } catch {
        Write-TestResult -TestName "Add-TestRegistryEntry functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-ModuleExports {
    Write-Host "`n=== Testing Module Export Completeness ===" -ForegroundColor Cyan

    try {
        $moduleInfo = Get-Module -Name "Common-ScriptHelpers"
        $exportedFunctions = $moduleInfo.ExportedFunctions.Keys

        # Expected StateFileManagement functions
        $expectedFunctions = @(
            'Update-MarkdownTable',
            'Update-MultipleTrackingFiles',
            'Get-RelevantTrackingFiles',
            'Get-StateFileBackup',
            'Update-FeatureTrackingStatus',
            'Update-FeatureTrackingStatusWithAppend',
            'Update-MarkdownTableWithAppend',
            'Update-DocumentTrackingFiles',
            'Update-TestImplementationStatus',
            'Add-TestRegistryEntry'
        )

        $allFunctionsExported = $true
        foreach ($func in $expectedFunctions) {
            if ($func -notin $exportedFunctions) {
                Write-TestResult -TestName "Function $func is exported" -Passed $false
                $allFunctionsExported = $false
            }
        }

        if ($allFunctionsExported) {
            Write-TestResult -TestName "All expected functions are exported" -Passed $true
        }

        Write-TestResult -TestName "Module exports $($exportedFunctions.Count) total functions" -Passed ($exportedFunctions.Count -gt 0)

    } catch {
        Write-TestResult -TestName "Module export completeness" -Passed $false -Message $_.Exception.Message
    }
}

# Run all tests
Write-Host "🧪 Starting StateFileManagement Module Comprehensive Tests" -ForegroundColor Magenta
Write-Host "=" * 60 -ForegroundColor Magenta

if ($SkipFileModification) {
    Write-Host "⚠️  File modification tests will be skipped" -ForegroundColor Yellow
}

Test-UpdateMarkdownTable
Test-UpdateMarkdownTableWithAppend
Test-GetRelevantTrackingFiles
Test-GetStateFileBackup
Test-UpdateFeatureTrackingStatus
Test-UpdateFeatureTrackingStatusWithAppend
Test-UpdateMultipleTrackingFiles
Test-UpdateDocumentTrackingFiles
Test-UpdateTestImplementationStatus
Test-AddTestRegistryEntry
Test-ModuleExports

# Summary
Write-Host "`n" + "=" * 60 -ForegroundColor Magenta
Write-Host "🏁 StateFileManagement Test Summary" -ForegroundColor Magenta
Write-Host "✅ Tests Passed: $script:TestsPassed" -ForegroundColor Green
Write-Host "❌ Tests Failed: $script:TestsFailed" -ForegroundColor Red
Write-Host "⏭️  Tests Skipped: $script:TestsSkipped" -ForegroundColor Yellow
Write-Host "📊 Total Tests: $($script:TestsPassed + $script:TestsFailed + $script:TestsSkipped)" -ForegroundColor Cyan

if ($script:TestsFailed -eq 0) {
    Write-Host "`n🎉 All tests passed! StateFileManagement module is ready for refactoring." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  Some tests failed. Review the results above before proceeding with refactoring." -ForegroundColor Yellow
    exit 1
}
