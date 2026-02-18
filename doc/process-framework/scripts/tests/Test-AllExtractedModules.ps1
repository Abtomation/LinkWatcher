#!/usr/bin/env pwsh

<#
.SYNOPSIS
Comprehensive test suite for all extracted modules from StateFileManagement refactoring

.DESCRIPTION
Tests all extracted modules (TableOperations, FileOperations, FeatureTracking,
DocumentTracking, TestTracking) and the refactored StateFileManagement module
to ensure the complete refactoring maintains functionality and backward compatibility.

.NOTES
Created: 2025-08-30
Purpose: Support Code Refactoring Task (PF-TSK-022)
Refactoring Plan: PF-REF-014
Phase: Phase 3 Complete Testing
#>

[CmdletBinding()]
param()

# Set up test environment
$ErrorActionPreference = 'Stop'
# Import Common-ScriptHelpers to get project root
Import-Module (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "Common-ScriptHelpers.psm1") -Force
Set-Location (Get-ProjectRoot)

# Import required dependencies first
Import-Module ".\doc\process-framework\scripts\Common-ScriptHelpers\Core.psm1" -Force
Import-Module ".\doc\process-framework\scripts\Common-ScriptHelpers\OutputFormatting.psm1" -Force

# Import all extracted modules
$ExtractedModules = @(
    "TableOperations.psm1",
    "FileOperations.psm1",
    "FeatureTracking.psm1",
    "DocumentTracking.psm1",
    "TestTracking.psm1"
)

foreach ($module in $ExtractedModules) {
    $modulePath = ".\doc\process-framework\scripts\Common-ScriptHelpers\$module"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
        Write-Host "✅ Loaded: $module" -ForegroundColor Green
    } else {
        Write-Host "❌ Missing: $module" -ForegroundColor Red
    }
}

# Import the refactored main module
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

function Test-ModuleLoading {
    Write-Host "`n=== Testing Module Loading ===" -ForegroundColor Cyan

    try {
        # Test that all modules are loaded
        $loadedModules = Get-Module | Where-Object { $_.Name -in @("TableOperations", "FileOperations", "FeatureTracking", "DocumentTracking", "TestTracking", "StateFileManagement-Refactored") }

        $expectedModules = @("TableOperations", "FileOperations", "FeatureTracking", "DocumentTracking", "TestTracking", "StateFileManagement-Refactored")

        foreach ($expectedModule in $expectedModules) {
            $moduleLoaded = $expectedModule -in $loadedModules.Name
            Write-TestResult -TestName "$expectedModule module is loaded" -Passed $moduleLoaded
        }

        # Test total module count
        $correctModuleCount = $loadedModules.Count -eq 6
        Write-TestResult -TestName "All 6 modules loaded successfully" -Passed $correctModuleCount

    } catch {
        Write-TestResult -TestName "Module loading test" -Passed $false -Message $_.Exception.Message
    }
}

function Test-FunctionAvailability {
    Write-Host "`n=== Testing Function Availability ===" -ForegroundColor Cyan

    try {
        # Expected functions from each module
        $expectedFunctions = @{
            "TableOperations" = @("Update-MarkdownTable", "Update-MarkdownTableWithAppend")
            "FileOperations" = @("Get-RelevantTrackingFiles", "Get-StateFileBackup", "Get-TrackingFilesByFeatureType")
            "FeatureTracking" = @("Update-FeatureTrackingStatus", "Update-FeatureTrackingStatusWithAppend", "Update-MultipleTrackingFiles")
            "DocumentTracking" = @("Update-DocumentTrackingFiles")
            "TestTracking" = @("Update-TestImplementationStatus", "Add-TestRegistryEntry", "Get-TestTrackingSectionTitle", "Get-TestTrackingSectionNumber")
        }

        foreach ($moduleName in $expectedFunctions.Keys) {
            $module = Get-Module -Name $moduleName
            if ($module) {
                $exportedFunctions = $module.ExportedFunctions.Keys

                foreach ($expectedFunction in $expectedFunctions[$moduleName]) {
                    $functionAvailable = $expectedFunction -in $exportedFunctions
                    Write-TestResult -TestName "$expectedFunction available in $moduleName" -Passed $functionAvailable
                }
            } else {
                Write-TestResult -TestName "$moduleName module availability check" -Passed $false -Message "Module not loaded"
            }
        }

    } catch {
        Write-TestResult -TestName "Function availability test" -Passed $false -Message $_.Exception.Message
    }
}

function Test-BackwardCompatibility {
    Write-Host "`n=== Testing Backward Compatibility ===" -ForegroundColor Cyan

    try {
        # Test that all original functions are still available through the refactored module
        $refactoredModule = Get-Module -Name "StateFileManagement-Refactored"
        $exportedFunctions = $refactoredModule.ExportedFunctions.Keys

        $originalFunctions = @(
            "Update-MarkdownTable",
            "Update-MarkdownTableWithAppend",
            "Get-RelevantTrackingFiles",
            "Get-StateFileBackup",
            "Get-TrackingFilesByFeatureType",
            "Update-FeatureTrackingStatus",
            "Update-FeatureTrackingStatusWithAppend",
            "Update-MultipleTrackingFiles",
            "Update-DocumentTrackingFiles",
            "Update-TestImplementationStatus",
            "Add-TestRegistryEntry"
        )

        foreach ($function in $originalFunctions) {
            $functionAvailable = $function -in $exportedFunctions
            Write-TestResult -TestName "$function available in refactored module" -Passed $functionAvailable
        }

        $correctFunctionCount = $exportedFunctions.Count -ge $originalFunctions.Count
        Write-TestResult -TestName "Refactored module exports at least $($originalFunctions.Count) functions" -Passed $correctFunctionCount

    } catch {
        Write-TestResult -TestName "Backward compatibility test" -Passed $false -Message $_.Exception.Message
    }
}

function Test-FunctionalityIntegration {
    Write-Host "`n=== Testing Functionality Integration ===" -ForegroundColor Cyan

    try {
        # Test TableOperations functionality
        $testContent = @"
| Feature ID | Status | Notes |
|------------|--------|-------|
| 1.1.1 | 🟡 In Progress | Test feature |
"@

        $result = Update-MarkdownTable -Content $testContent -FeatureId "1.1.1" -StatusColumn "Status" -Status "🟢 Complete" -Notes "Integration test"
        $tableUpdateWorks = $result -match '1\.1\.1.*🟢 Complete.*Integration test'
        Write-TestResult -TestName "TableOperations integration works" -Passed $tableUpdateWorks

        # Test FileOperations functionality
        $trackingFiles = Get-RelevantTrackingFiles -DocumentType "TestSpecification" -DocumentId "PF-TSP-001"
        $fileOpsWorks = $trackingFiles.Count -gt 0
        Write-TestResult -TestName "FileOperations integration works" -Passed $fileOpsWorks

        # Test FeatureTracking functionality (dry run)
        $featureResult = Update-FeatureTrackingStatus -FeatureId "1.1.1" -Status "🧪 Integration Test" -StatusColumn "Status" -DryRun
        $featureTrackingWorks = $featureResult.FeatureId -eq "1.1.1"
        Write-TestResult -TestName "FeatureTracking integration works" -Passed $featureTrackingWorks

        # Test DocumentTracking functionality (dry run)
        $metadata = @{ "feature_id" = "1.1.1"; "feature_name" = "test-feature" }
        $docResult = Update-DocumentTrackingFiles -DocumentId "TEST-001" -DocumentType "TestSpecification" -DocumentPath "/test/path" -Metadata $metadata -DryRun
        $docTrackingWorks = $docResult.Count -gt 0
        Write-TestResult -TestName "DocumentTracking integration works" -Passed $docTrackingWorks

        # Test TestTracking functionality (dry run)
        $testResult = Update-TestImplementationStatus -FeatureId "1.1.1" -Status "🧪 Integration Test" -DryRun
        $testTrackingWorks = $testResult.Count -gt 0
        Write-TestResult -TestName "TestTracking integration works" -Passed $testTrackingWorks

    } catch {
        Write-TestResult -TestName "Functionality integration test" -Passed $false -Message $_.Exception.Message
    }
}

function Test-CrossModuleDependencies {
    Write-Host "`n=== Testing Cross-Module Dependencies ===" -ForegroundColor Cyan

    try {
        # Test that FeatureTracking can use TableOperations functions
        $trackingFiles = @(
            @{
                Path = "doc\process-framework\state-tracking\permanent\feature-tracking.md"
                Type = "Feature"
                Required = $true
            }
        )

        if (Test-Path $trackingFiles[0].Path) {
            $result = Update-MultipleTrackingFiles -TrackingFiles $trackingFiles -FeatureId "0.1.2" -StatusColumn "Status" -Status "🧪 Cross-Module Test" -DryRun
            $crossModuleWorks = $result[0].Success -eq $true
            Write-TestResult -TestName "Cross-module dependencies work (FeatureTracking → TableOperations)" -Passed $crossModuleWorks
        } else {
            Write-TestResult -TestName "Cross-module dependencies test" -Passed $false -Message "Test file not found"
        }

        # Test that DocumentTracking can use FeatureTracking functions
        $metadata = @{ "feature_id" = "1.1.1"; "feature_name" = "test-feature" }
        $docResult = Update-DocumentTrackingFiles -DocumentId "TEST-002" -DocumentType "TestSpecification" -DocumentPath "/test/path2" -Metadata $metadata -DryRun
        $docCrossModuleWorks = $docResult.Count -gt 0
        Write-TestResult -TestName "Cross-module dependencies work (DocumentTracking → FeatureTracking)" -Passed $docCrossModuleWorks

    } catch {
        Write-TestResult -TestName "Cross-module dependencies test" -Passed $false -Message $_.Exception.Message
    }
}

function Test-ArchitectureValidation {
    Write-Host "`n=== Testing Architecture Validation ===" -ForegroundColor Cyan

    try {
        # Test module sizes (should be smaller than original)
        $moduleFiles = @(
            "TableOperations.psm1",
            "FileOperations.psm1",
            "FeatureTracking.psm1",
            "DocumentTracking.psm1",
            "TestTracking.psm1"
        )

        $totalLines = 0
        foreach ($moduleFile in $moduleFiles) {
            $modulePath = ".\doc\process-framework\scripts\Common-ScriptHelpers\$moduleFile"
            if (Test-Path $modulePath) {
                $lines = (Get-Content $modulePath).Count
                $totalLines += $lines

                $reasonableSize = $lines -lt 500  # Each module should be under 500 lines
                Write-TestResult -TestName "$moduleFile is reasonably sized ($lines lines)" -Passed $reasonableSize
            }
        }

        # Test that total extracted code is reasonable
        $totalReasonable = $totalLines -lt 2500  # Total should be manageable
        Write-TestResult -TestName "Total extracted code is reasonable ($totalLines lines)" -Passed $totalReasonable

        # Test that refactored module is smaller than original
        $refactoredPath = ".\doc\process-framework\scripts\Common-ScriptHelpers\StateFileManagement-Refactored.psm1"
        if (Test-Path $refactoredPath) {
            $refactoredLines = (Get-Content $refactoredPath).Count
            $refactoredSmaller = $refactoredLines -lt 500  # Refactored should be much smaller
            Write-TestResult -TestName "Refactored module is smaller ($refactoredLines lines)" -Passed $refactoredSmaller
        }

    } catch {
        Write-TestResult -TestName "Architecture validation test" -Passed $false -Message $_.Exception.Message
    }
}

# Run all tests
Write-Host "🧪 Starting Comprehensive Extracted Modules Test Suite" -ForegroundColor Magenta
Write-Host "=" * 65 -ForegroundColor Magenta

Test-ModuleLoading
Test-FunctionAvailability
Test-BackwardCompatibility
Test-FunctionalityIntegration
Test-CrossModuleDependencies
Test-ArchitectureValidation

# Summary
Write-Host "`n" + "=" * 65 -ForegroundColor Magenta
Write-Host "🏁 Comprehensive Test Suite Summary" -ForegroundColor Magenta
Write-Host "✅ Tests Passed: $script:TestsPassed" -ForegroundColor Green
Write-Host "❌ Tests Failed: $script:TestsFailed" -ForegroundColor Red
Write-Host "📊 Total Tests: $($script:TestsPassed + $script:TestsFailed)" -ForegroundColor Cyan

if ($script:TestsFailed -eq 0) {
    Write-Host "`n🎉 ALL TESTS PASSED! StateFileManagement refactoring Phase 3 COMPLETE!" -ForegroundColor Green
    Write-Host "✅ All 5 modules extracted successfully" -ForegroundColor Green
    Write-Host "✅ Backward compatibility maintained" -ForegroundColor Green
    Write-Host "✅ Cross-module dependencies working" -ForegroundColor Green
    Write-Host "✅ Architecture goals achieved" -ForegroundColor Green
    Write-Host "`n🚀 Refactoring Task (PF-TSK-022) SUCCESSFULLY COMPLETED!" -ForegroundColor Magenta
    exit 0
} else {
    Write-Host "`n⚠️  Some tests failed. Review the results above." -ForegroundColor Yellow
    $successRate = [math]::Round(($script:TestsPassed / ($script:TestsPassed + $script:TestsFailed)) * 100, 1)
    Write-Host "📈 Success Rate: $successRate%" -ForegroundColor Cyan
    exit 1
}
