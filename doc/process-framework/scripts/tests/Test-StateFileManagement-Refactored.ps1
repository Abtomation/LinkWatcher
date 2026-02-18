#!/usr/bin/env pwsh

<#
.SYNOPSIS
Test suite for the refactored StateFileManagement.psm1 module

.DESCRIPTION
Tests the refactored StateFileManagement module to ensure backward compatibility
is maintained after extracting TableOperations and FileOperations modules.

.NOTES
Created: 2025-08-30
Purpose: Support Code Refactoring Task (PF-TSK-022)
Refactoring Plan: PF-REF-014
#>

[CmdletBinding()]
param()

# Set up test environment
$ErrorActionPreference = 'Stop'
# Import Common-ScriptHelpers to get project root
Import-Module (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "Common-ScriptHelpers.psm1") -Force
Set-Location (Get-ProjectRoot)

# Import the refactored module
Import-Module ".\doc\process-framework\scripts\Common-ScriptHelpers\StateFileManagement-Refactored.psm1" -Force

# Test counters
$script:TestsPassed = 0
$script:TestsFailed = 0

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )

    if ($Passed) {
        Write-Host "✅ PASS: $TestName" -ForegroundColor Green
        $script:TestsPassed++
    } else {
        Write-Host "❌ FAIL: $TestName" -ForegroundColor Red
        if ($Message) { Write-Host "   Message: $Message" -ForegroundColor Yellow }
        $script:TestsFailed++
    }
}

function Test-BackwardCompatibilityFunctions {
    Write-Host "`n=== Testing Backward Compatibility Functions ===" -ForegroundColor Cyan

    try {
        # Test that all expected functions are still available
        $moduleInfo = Get-Module -Name "StateFileManagement-Refactored"
        $exportedFunctions = $moduleInfo.ExportedFunctions.Keys

        $expectedFunctions = @(
            'Update-MarkdownTable',
            'Update-MarkdownTableWithAppend',
            'Get-RelevantTrackingFiles',
            'Get-StateFileBackup',
            'Get-TrackingFilesByFeatureType',
            'Update-MultipleTrackingFiles',
            'Update-FeatureTrackingStatus',
            'Update-FeatureTrackingStatusWithAppend',
            'Update-DocumentTrackingFiles',
            'Update-TestImplementationStatus',
            'Add-TestRegistryEntry'
        )

        $allFunctionsAvailable = $true
        foreach ($func in $expectedFunctions) {
            if ($func -notin $exportedFunctions) {
                Write-TestResult -TestName "Function $func is available in refactored module" -Passed $false
                $allFunctionsAvailable = $false
            } else {
                Write-TestResult -TestName "Function $func is available in refactored module" -Passed $true
            }
        }

        $correctFunctionCount = $exportedFunctions.Count -ge $expectedFunctions.Count
        Write-TestResult -TestName "Refactored module exports at least $($expectedFunctions.Count) functions" -Passed $correctFunctionCount

    } catch {
        Write-TestResult -TestName "Backward compatibility function availability" -Passed $false -Message $_.Exception.Message
    }
}

function Test-ExtractedFunctionsBehavior {
    Write-Host "`n=== Testing Extracted Functions Behavior ===" -ForegroundColor Cyan

    try {
        # Test Update-MarkdownTable (from TableOperations.psm1)
        $testContent = @"
| Feature ID | Status | Notes |
|------------|--------|-------|
| 1.1.1 | 🟡 In Progress | Test feature |
"@

        $result = Update-MarkdownTable -Content $testContent -FeatureId "1.1.1" -StatusColumn "Status" -Status "🟢 Complete" -Notes "Updated via refactored module"

        $tableUpdateWorks = $result -match '1\.1\.1.*🟢 Complete.*Updated via refactored module'
        Write-TestResult -TestName "Update-MarkdownTable works through refactored module" -Passed $tableUpdateWorks

        # Test Get-RelevantTrackingFiles (from FileOperations.psm1)
        $trackingFiles = Get-RelevantTrackingFiles -DocumentType "TestSpecification" -DocumentId "PF-TSP-001"
        $trackingFilesWork = $trackingFiles.Count -gt 0
        Write-TestResult -TestName "Get-RelevantTrackingFiles works through refactored module" -Passed $trackingFilesWork

        # Test Get-TrackingFilesByFeatureType (new function from FileOperations.psm1)
        $featureFiles = Get-TrackingFilesByFeatureType -FeatureId "1.1.1"
        $featureFilesWork = $featureFiles.Count -gt 0
        Write-TestResult -TestName "Get-TrackingFilesByFeatureType works through refactored module" -Passed $featureFilesWork

    } catch {
        Write-TestResult -TestName "Extracted functions behavior through refactored module" -Passed $false -Message $_.Exception.Message
    }
}

function Test-TemporaryFunctionsBehavior {
    Write-Host "`n=== Testing Temporary Functions Behavior ===" -ForegroundColor Cyan

    try {
        # Test Update-FeatureTrackingStatus (temporary implementation)
        $result = Update-FeatureTrackingStatus -FeatureId "1.1.1" -Status "🧪 Test" -StatusColumn "Status" -DryRun
        $featureTrackingWorks = $result -ne $null
        Write-TestResult -TestName "Update-FeatureTrackingStatus temporary implementation works" -Passed $featureTrackingWorks

        # Test Update-DocumentTrackingFiles (temporary implementation)
        $metadata = @{ "test" = "value" }
        $result2 = Update-DocumentTrackingFiles -DocumentId "TEST-001" -DocumentType "TestSpecification" -DocumentPath "/test/path" -Metadata $metadata -DryRun
        $documentTrackingWorks = $result2.DocumentId -eq "TEST-001"
        Write-TestResult -TestName "Update-DocumentTrackingFiles temporary implementation works" -Passed $documentTrackingWorks

        # Test Add-TestRegistryEntry (temporary implementation)
        $result3 = Add-TestRegistryEntry -TestFileId "TEST-001" -TestFilePath "/test/path" -ComponentName "TestComponent" -TestType "Unit" -DryRun
        $testRegistryWorks = $result3.TestFileId -eq "TEST-001"
        Write-TestResult -TestName "Add-TestRegistryEntry temporary implementation works" -Passed $testRegistryWorks

    } catch {
        Write-TestResult -TestName "Temporary functions behavior" -Passed $false -Message $_.Exception.Message
    }
}

function Test-ModuleArchitecture {
    Write-Host "`n=== Testing Module Architecture ===" -ForegroundColor Cyan

    try {
        # Test that sub-modules are loaded
        $tableOpsModule = Get-Module -Name "TableOperations"
        $tableOpsLoaded = $tableOpsModule -ne $null
        Write-TestResult -TestName "TableOperations sub-module is loaded" -Passed $tableOpsLoaded

        $fileOpsModule = Get-Module -Name "FileOperations"
        $fileOpsLoaded = $fileOpsModule -ne $null
        Write-TestResult -TestName "FileOperations sub-module is loaded" -Passed $fileOpsLoaded

        # Test that functions from sub-modules work
        if ($tableOpsLoaded) {
            $tableOpsFunctions = $tableOpsModule.ExportedFunctions.Keys
            $hasTableFunctions = "Update-MarkdownTable" -in $tableOpsFunctions
            Write-TestResult -TestName "TableOperations exports expected functions" -Passed $hasTableFunctions
        }

        if ($fileOpsLoaded) {
            $fileOpsFunctions = $fileOpsModule.ExportedFunctions.Keys
            $hasFileFunctions = "Get-RelevantTrackingFiles" -in $fileOpsFunctions
            Write-TestResult -TestName "FileOperations exports expected functions" -Passed $hasFileFunctions
        }

    } catch {
        Write-TestResult -TestName "Module architecture validation" -Passed $false -Message $_.Exception.Message
    }
}

function Test-ComplexScenarios {
    Write-Host "`n=== Testing Complex Integration Scenarios ===" -ForegroundColor Cyan

    try {
        # Test that Update-MultipleTrackingFiles can use extracted functions
        $trackingFiles = @(
            @{
                Path = "doc\process-framework\state-tracking\permanent\feature-tracking.md"
                Type = "Feature"
                Required = $true
            }
        )

        if (Test-Path $trackingFiles[0].Path) {
            $result = Update-MultipleTrackingFiles -TrackingFiles $trackingFiles -FeatureId "0.1.2" -StatusColumn "Status" -Status "🧪 Integration Test" -DryRun
            $integrationWorks = $result[0].Success -eq $true
            Write-TestResult -TestName "Update-MultipleTrackingFiles integrates with extracted functions" -Passed $integrationWorks
        } else {
            Write-TestResult -TestName "Update-MultipleTrackingFiles integration test" -Passed $false -Message "Test file not found"
        }

        # Test mixed function usage (extracted + temporary)
        $trackingFiles2 = Get-RelevantTrackingFiles -DocumentType "ValidationReport" -DocumentId "PF-VLD-001"
        $featureResult = Update-FeatureTrackingStatus -FeatureId "1.1.1" -Status "🧪 Mixed Test" -StatusColumn "Status" -DryRun

        $mixedUsageWorks = ($trackingFiles2.Count -gt 0) -and ($featureResult -ne $null)
        Write-TestResult -TestName "Mixed usage of extracted and temporary functions works" -Passed $mixedUsageWorks

    } catch {
        Write-TestResult -TestName "Complex integration scenarios" -Passed $false -Message $_.Exception.Message
    }
}

# Run all tests
Write-Host "🧪 Starting StateFileManagement Refactored Module Tests" -ForegroundColor Magenta
Write-Host "=" * 60 -ForegroundColor Magenta

Test-BackwardCompatibilityFunctions
Test-ExtractedFunctionsBehavior
Test-TemporaryFunctionsBehavior
Test-ModuleArchitecture
Test-ComplexScenarios

# Summary
Write-Host "`n" + "=" * 60 -ForegroundColor Magenta
Write-Host "🏁 StateFileManagement Refactored Module Test Summary" -ForegroundColor Magenta
Write-Host "✅ Tests Passed: $script:TestsPassed" -ForegroundColor Green
Write-Host "❌ Tests Failed: $script:TestsFailed" -ForegroundColor Red
Write-Host "📊 Total Tests: $($script:TestsPassed + $script:TestsFailed)" -ForegroundColor Cyan

if ($script:TestsFailed -eq 0) {
    Write-Host "`n🎉 All tests passed! StateFileManagement refactoring Phase 2 successful." -ForegroundColor Green
    Write-Host "✅ Backward compatibility maintained" -ForegroundColor Green
    Write-Host "✅ TableOperations.psm1 integration working" -ForegroundColor Green
    Write-Host "✅ FileOperations.psm1 integration working" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  Some tests failed. Review the results above." -ForegroundColor Yellow
    exit 1
}
