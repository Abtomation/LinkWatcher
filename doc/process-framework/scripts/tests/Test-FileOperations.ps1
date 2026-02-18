#!/usr/bin/env pwsh

<#
.SYNOPSIS
Test suite for the extracted FileOperations.psm1 module

.DESCRIPTION
Tests the FileOperations module functions to ensure they work correctly
after extraction from StateFileManagement.psm1. This validates the
refactoring process maintains all functionality.

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

# Import required dependencies first
Import-Module ".\doc\process-framework\scripts\Common-ScriptHelpers\Core.psm1" -Force
Import-Module ".\doc\process-framework\scripts\Common-ScriptHelpers\OutputFormatting.psm1" -Force

# Import the extracted module
Import-Module ".\doc\process-framework\scripts\Common-ScriptHelpers\FileOperations.psm1" -Force

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

function Test-GetRelevantTrackingFilesExtracted {
    Write-Host "`n=== Testing Extracted Get-RelevantTrackingFiles Function ===" -ForegroundColor Cyan

    try {
        # Test with TestSpecification document type
        $testSpecFiles = Get-RelevantTrackingFiles -DocumentType "TestSpecification" -DocumentId "PF-TSP-001"
        $hasTestSpecFiles = $testSpecFiles.Count -gt 0
        Write-TestResult -TestName "Returns files for TestSpecification documents" -Passed $hasTestSpecFiles

        # Test with ValidationReport document type
        $validationFiles = Get-RelevantTrackingFiles -DocumentType "ValidationReport" -DocumentId "PF-VLD-001"
        $hasValidationFiles = $validationFiles.Count -gt 0
        Write-TestResult -TestName "Returns files for ValidationReport documents" -Passed $hasValidationFiles

        # Test with FeatureImplementation document type
        $featureFiles = Get-RelevantTrackingFiles -DocumentType "FeatureImplementation" -DocumentId "PF-FTR-001"
        $hasFeatureFiles = $featureFiles.Count -gt 0
        Write-TestResult -TestName "Returns files for FeatureImplementation documents" -Passed $hasFeatureFiles

        # Test with new document types added in extracted module
        $codeReviewFiles = Get-RelevantTrackingFiles -DocumentType "CodeReview" -DocumentId "PF-CR-001"
        $hasCodeReviewFiles = $codeReviewFiles.Count -gt 0
        Write-TestResult -TestName "Returns files for CodeReview documents (new in extracted module)" -Passed $hasCodeReviewFiles

        # Verify different file sets for different document types
        $testSpecString = ($testSpecFiles | ForEach-Object { $_.Path }) -join ","
        $validationString = ($validationFiles | ForEach-Object { $_.Path }) -join ","
        $differentFileSets = $testSpecString -ne $validationString
        Write-TestResult -TestName "Different document types return different file sets" -Passed $differentFileSets

        # Test with unknown document type
        $unknownFiles = Get-RelevantTrackingFiles -DocumentType "UnknownType" -DocumentId "TEST-001"
        $handlesUnknownType = $unknownFiles.Count -eq 0
        Write-TestResult -TestName "Handles unknown document types gracefully" -Passed $handlesUnknownType

    } catch {
        Write-TestResult -TestName "Get-RelevantTrackingFiles extracted functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-GetStateFileBackupExtracted {
    Write-Host "`n=== Testing Extracted Get-StateFileBackup Function ===" -ForegroundColor Cyan

    try {
        $testFile = "doc\process-framework\state-tracking\permanent\feature-tracking.md"

        if (Test-Path $testFile) {
            $backupPath = Get-StateFileBackup -FilePath $testFile
            $backupPathValid = $backupPath -like "*feature-tracking-backup-*"
            Write-TestResult -TestName "Generates valid backup path format in extracted module" -Passed $backupPathValid

            # Test that backup path includes timestamp
            $hasTimestamp = $backupPath -match '\d{8}-\d{6}'
            Write-TestResult -TestName "Backup path includes timestamp in extracted module" -Passed $hasTimestamp

            # Test that backup file was actually created
            $backupExists = Test-Path $backupPath
            Write-TestResult -TestName "Backup file was actually created" -Passed $backupExists

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
            Write-TestResult -TestName "Get-StateFileBackup extracted tests" -Passed $false -Message "Test file not found: $testFile"
        }

    } catch {
        Write-TestResult -TestName "Get-StateFileBackup extracted functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-GetTrackingFilesByFeatureTypeExtracted {
    Write-Host "`n=== Testing New Get-TrackingFilesByFeatureType Function ===" -ForegroundColor Cyan

    try {
        # Test with architecture feature (0.x.x)
        $archFiles = Get-TrackingFilesByFeatureType -FeatureId "0.1.1"
        $hasArchFiles = $archFiles.Count -gt 0
        Write-TestResult -TestName "Returns files for architecture features (0.x.x)" -Passed $hasArchFiles

        # Test with standard feature (1.x.x)
        $standardFiles = Get-TrackingFilesByFeatureType -FeatureId "1.1.1"
        $hasStandardFiles = $standardFiles.Count -gt 0
        Write-TestResult -TestName "Returns files for standard features (1.x.x)" -Passed $hasStandardFiles

        # Verify architecture features have correct section
        $archSection = $archFiles[0].Section -eq "Architecture"
        Write-TestResult -TestName "Architecture features have correct section metadata" -Passed $archSection

        # Verify standard features have correct section
        $standardSection = $standardFiles[0].Section -eq "Standard"
        Write-TestResult -TestName "Standard features have correct section metadata" -Passed $standardSection

        # Test with different architecture feature
        $archFiles2 = Get-TrackingFilesByFeatureType -FeatureId "0.2.5"
        $archPattern = $archFiles2[0].Type -eq "ArchitectureFeature"
        Write-TestResult -TestName "Different architecture features return correct type" -Passed $archPattern

    } catch {
        Write-TestResult -TestName "Get-TrackingFilesByFeatureType functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-ModuleExportsExtracted {
    Write-Host "`n=== Testing Extracted FileOperations Module Exports ===" -ForegroundColor Cyan

    try {
        $moduleInfo = Get-Module -Name "FileOperations"
        $exportedFunctions = $moduleInfo.ExportedFunctions.Keys

        # Expected functions
        $expectedFunctions = @(
            'Get-RelevantTrackingFiles',
            'Get-StateFileBackup',
            'Get-TrackingFilesByFeatureType'
        )

        $allFunctionsExported = $true
        foreach ($func in $expectedFunctions) {
            if ($func -notin $exportedFunctions) {
                Write-TestResult -TestName "Function $func is exported from extracted module" -Passed $false
                $allFunctionsExported = $false
            } else {
                Write-TestResult -TestName "Function $func is exported from extracted module" -Passed $true
            }
        }

        $correctFunctionCount = $exportedFunctions.Count -eq 3
        Write-TestResult -TestName "Extracted module exports exactly 3 functions" -Passed $correctFunctionCount

    } catch {
        Write-TestResult -TestName "FileOperations extracted module export completeness" -Passed $false -Message $_.Exception.Message
    }
}

function Test-BackupDirectoryFunctionality {
    Write-Host "`n=== Testing Backup Directory Functionality ===" -ForegroundColor Cyan

    try {
        $testFile = "doc\process-framework\state-tracking\permanent\feature-tracking.md"
        $backupDir = "temp-backup-test"

        if (Test-Path $testFile) {
            # Create temporary backup directory
            if (-not (Test-Path $backupDir)) {
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            }

            $backupPath = Get-StateFileBackup -FilePath $testFile -BackupDirectory $backupDir
            $backupInCorrectDir = $backupPath -like "*$backupDir*"
            Write-TestResult -TestName "Backup created in specified directory" -Passed $backupInCorrectDir

            $backupExists = Test-Path $backupPath
            Write-TestResult -TestName "Backup file exists in custom directory" -Passed $backupExists

            # Clean up
            if (Test-Path $backupPath) {
                Remove-Item $backupPath -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path $backupDir) {
                Remove-Item $backupDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-TestResult -TestName "Backup directory functionality tests" -Passed $false -Message "Test file not found: $testFile"
        }

    } catch {
        Write-TestResult -TestName "Backup directory functionality" -Passed $false -Message $_.Exception.Message
    }
}

# Run all tests
Write-Host "🧪 Starting FileOperations Extracted Module Tests" -ForegroundColor Magenta
Write-Host "=" * 55 -ForegroundColor Magenta

Test-GetRelevantTrackingFilesExtracted
Test-GetStateFileBackupExtracted
Test-GetTrackingFilesByFeatureTypeExtracted
Test-ModuleExportsExtracted
Test-BackupDirectoryFunctionality

# Summary
Write-Host "`n" + "=" * 55 -ForegroundColor Magenta
Write-Host "🏁 FileOperations Extracted Module Test Summary" -ForegroundColor Magenta
Write-Host "✅ Tests Passed: $script:TestsPassed" -ForegroundColor Green
Write-Host "❌ Tests Failed: $script:TestsFailed" -ForegroundColor Red
Write-Host "📊 Total Tests: $($script:TestsPassed + $script:TestsFailed)" -ForegroundColor Cyan

if ($script:TestsFailed -eq 0) {
    Write-Host "`n🎉 All tests passed! FileOperations module extraction successful." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  Some tests failed. Review the results above." -ForegroundColor Yellow
    exit 1
}
