#!/usr/bin/env pwsh

<#
.SYNOPSIS
Test suite for the Update-FeatureTrackingStatus function with table parsing

.DESCRIPTION
Tests the complete Update-FeatureTrackingStatus function to ensure it correctly
parses and updates the feature-tracking.md file with various scenarios.
#>

[CmdletBinding()]
param()

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

function Test-DryRunFunctionality {
    Write-Host "`n=== Testing Dry Run Functionality ===" -ForegroundColor Cyan

    try {
        # Test dry run with existing feature
        $result = Update-FeatureTrackingStatus -FeatureId "0.1.2" -Status "🧪 Testing Dry Run" -StatusColumn "Status" -DryRun

        $hasDryRunInfo = $result.FeatureId -eq "0.1.2" -and $result.Status -eq "🧪 Testing Dry Run"
        Write-TestResult -TestName "Dry run returns correct info" -Passed $hasDryRunInfo

        # Verify file wasn't actually changed by checking if backup exists
        $backupFiles = Get-ChildItem "doc\process-framework\state-tracking\permanent\feature-tracking.md.backup.*" -ErrorAction SilentlyContinue
        $noBackupCreated = $backupFiles.Count -eq 0 -or (Get-Date) - $backupFiles[-1].LastWriteTime -gt [TimeSpan]::FromMinutes(1)
        Write-TestResult -TestName "Dry run doesn't modify file" -Passed $noBackupCreated

    } catch {
        Write-TestResult -TestName "Dry run functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-RealUpdateFunctionality {
    Write-Host "`n=== Testing Real Update Functionality ===" -ForegroundColor Cyan

    try {
        # Get original content to verify changes
        $originalContent = Get-Content "doc\process-framework\state-tracking\permanent\feature-tracking.md" -Raw

        # Test real update with multiple columns
        $additionalUpdates = @{
            "Test Status" = "🧪 Automated Test"
        }

        $result = Update-FeatureTrackingStatus -FeatureId "0.1.2" -Status "🧪 Testing Real Update" -StatusColumn "Status" -AdditionalUpdates $additionalUpdates -Notes "Automated test update"

        $hasCorrectResult = $result.FeatureId -eq "0.1.2" -and $result.Status -eq "🧪 Testing Real Update"
        Write-TestResult -TestName "Real update returns correct info" -Passed $hasCorrectResult

        # Verify backup was created
        $backupFiles = Get-ChildItem "doc\process-framework\state-tracking\permanent\feature-tracking.md.backup.*" -ErrorAction SilentlyContinue
        $backupCreated = $backupFiles.Count -gt 0 -and (Get-Date) - $backupFiles[-1].LastWriteTime -lt [TimeSpan]::FromMinutes(1)
        Write-TestResult -TestName "Backup created on real update" -Passed $backupCreated

        # Verify file was actually updated
        $updatedContent = Get-Content "doc\process-framework\state-tracking\permanent\feature-tracking.md" -Raw
        $fileWasUpdated = $updatedContent -ne $originalContent
        Write-TestResult -TestName "File content was modified" -Passed $fileWasUpdated

        # Verify specific updates were applied
        $statusUpdated = $updatedContent -match '0\.1\.2.*🧪 Testing Real Update'
        Write-TestResult -TestName "Status column updated correctly" -Passed $statusUpdated

        $testStatusUpdated = $updatedContent -match '0\.1\.2.*🧪 Automated Test'
        Write-TestResult -TestName "Additional column updated correctly" -Passed $testStatusUpdated

        $notesUpdated = $updatedContent -match 'Automated test update'
        Write-TestResult -TestName "Notes appended correctly" -Passed $notesUpdated

        # Restore original status for next tests
        Update-FeatureTrackingStatus -FeatureId "0.1.2" -Status "🟢 Completed" -StatusColumn "Status" -AdditionalUpdates @{"Test Status" = "⬜ No Tests"} | Out-Null

    } catch {
        Write-TestResult -TestName "Real update functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-ErrorHandling {
    Write-Host "`n=== Testing Error Handling ===" -ForegroundColor Cyan

    try {
        # Test with non-existent feature ID
        $result = Update-FeatureTrackingStatus -FeatureId "99.99.99" -Status "🧪 Testing" -StatusColumn "Status" -DryRun -WarningAction SilentlyContinue

        $handlesNonExistentId = $result.FeatureId -eq "99.99.99"  # Should still return the info even if not found
        Write-TestResult -TestName "Handles non-existent feature ID gracefully" -Passed $handlesNonExistentId

    } catch {
        Write-TestResult -TestName "Error handling for non-existent ID" -Passed $false -Message $_.Exception.Message
    }

    try {
        # Test with invalid column name
        $result = Update-FeatureTrackingStatus -FeatureId "0.1.1" -Status "🧪 Testing" -StatusColumn "NonExistentColumn" -DryRun -WarningAction SilentlyContinue

        $handlesInvalidColumn = $result.StatusColumn -eq "NonExistentColumn"
        Write-TestResult -TestName "Handles invalid column name gracefully" -Passed $handlesInvalidColumn

    } catch {
        Write-TestResult -TestName "Error handling for invalid column" -Passed $false -Message $_.Exception.Message
    }
}

function Test-ArchitectureTableSupport {
    Write-Host "`n=== Testing Architecture Table Support ===" -ForegroundColor Cyan

    try {
        # Test updating an architecture feature (0.X.X)
        $result = Update-FeatureTrackingStatus -FeatureId "0.1.1" -Status "🧪 Testing Architecture" -StatusColumn "Status" -AdditionalUpdates @{"ADR" = "Test-ADR"} -DryRun

        $supportsArchFeatures = $result.FeatureId -eq "0.1.1" -and $result.AdditionalUpdates.ContainsKey("ADR")
        Write-TestResult -TestName "Supports architecture table features" -Passed $supportsArchFeatures

    } catch {
        Write-TestResult -TestName "Architecture table support" -Passed $false -Message $_.Exception.Message
    }
}

function Test-StandardTableSupport {
    Write-Host "`n=== Testing Standard Table Support ===" -ForegroundColor Cyan

    try {
        # Test updating a standard feature (non-0.X.X)
        $result = Update-FeatureTrackingStatus -FeatureId "1.1.1" -Status "🧪 Testing Standard" -StatusColumn "Status" -AdditionalUpdates @{"FDD" = "Test-FDD-Link"} -DryRun

        $supportsStandardFeatures = $result.FeatureId -eq "1.1.1" -and $result.AdditionalUpdates.ContainsKey("FDD")
        Write-TestResult -TestName "Supports standard table features" -Passed $supportsStandardFeatures

    } catch {
        Write-TestResult -TestName "Standard table support" -Passed $false -Message $_.Exception.Message
    }
}

# Run all tests
Write-Host "🧪 Starting Feature Tracking Update Tests" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

Test-DryRunFunctionality
Test-RealUpdateFunctionality
Test-ErrorHandling
Test-ArchitectureTableSupport
Test-StandardTableSupport

# Summary
Write-Host "`n" + "=" * 50 -ForegroundColor Magenta
Write-Host "🏁 Test Summary" -ForegroundColor Magenta
Write-Host "✅ Tests Passed: $script:TestsPassed" -ForegroundColor Green
Write-Host "❌ Tests Failed: $script:TestsFailed" -ForegroundColor Red
Write-Host "📊 Total Tests: $($script:TestsPassed + $script:TestsFailed)" -ForegroundColor Cyan

if ($script:TestsFailed -eq 0) {
    Write-Host "`n🎉 All tests passed! The table parsing implementation is working correctly." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  Some tests failed. Review the results above." -ForegroundColor Yellow
    exit 1
}
