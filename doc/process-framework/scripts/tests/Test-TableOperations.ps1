#!/usr/bin/env pwsh

<#
.SYNOPSIS
Test suite for the extracted TableOperations.psm1 module

.DESCRIPTION
Tests the TableOperations module functions to ensure they work correctly
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

# Import the extracted module directly
Import-Module ".\doc\process-framework\scripts\Common-ScriptHelpers\TableOperations.psm1" -Force

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

function Test-UpdateMarkdownTableExtracted {
    Write-Host "`n=== Testing Extracted Update-MarkdownTable Function ===" -ForegroundColor Cyan

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

        $result = Update-MarkdownTable -Content $testContent -FeatureId "1.1.1" -StatusColumn "Status" -Status "🟢 Complete" -Notes "Updated via extracted module test"

        $statusUpdated = $result -match '1\.1\.1.*🟢 Complete.*Updated via extracted module test'
        Write-TestResult -TestName "Basic table update in extracted module" -Passed $statusUpdated

        # Test with additional updates
        $additionalUpdates = @{"Notes" = "Replaced notes"}
        $result2 = Update-MarkdownTable -Content $testContent -FeatureId "1.1.2" -StatusColumn "Status" -Status "🔴 Failed" -AdditionalUpdates $additionalUpdates

        $additionalUpdatesWork = $result2 -match '1\.1\.2.*🔴 Failed.*Replaced notes'
        Write-TestResult -TestName "Additional updates parameter works in extracted module" -Passed $additionalUpdatesWork

        # Test with non-existent feature ID
        $result3 = Update-MarkdownTable -Content $testContent -FeatureId "9.9.9" -StatusColumn "Status" -Status "🟢 Complete"
        $originalContentPreserved = $result3 -eq $testContent
        Write-TestResult -TestName "Handles non-existent feature ID gracefully" -Passed $originalContentPreserved

    } catch {
        Write-TestResult -TestName "Update-MarkdownTable extracted functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-UpdateMarkdownTableWithAppendExtracted {
    Write-Host "`n=== Testing Extracted Update-MarkdownTableWithAppend Function ===" -ForegroundColor Cyan

    try {
        $testContent = @"
| Feature ID | Status | API Design | Notes |
|------------|--------|------------|-------|
| 1.1.1 | 🟡 In Progress | [Initial](link1) | Original notes |
"@

        # Test basic append functionality
        $result = Update-MarkdownTableWithAppend -Content $testContent -FeatureId "1.1.1" -StatusColumn "Status" -Status "🟢 Complete" -Notes "Appended notes"

        $notesAppended = $result -match '1\.1\.1.*🟢 Complete.*Original notes; Appended notes'
        Write-TestResult -TestName "Notes appending in extracted module" -Passed $notesAppended

        # Test append updates functionality
        $appendUpdates = @{"API Design" = "[Additional](link2)"}
        $result2 = Update-MarkdownTableWithAppend -Content $testContent -FeatureId "1.1.1" -StatusColumn "Status" -Status "🟢 Complete" -AppendUpdates $appendUpdates

        $appendUpdatesWork = $result2 -match '1\.1\.1.*\[Initial\]\(link1\) • \[Additional\]\(link2\)'
        Write-TestResult -TestName "Append updates with bullet separator" -Passed $appendUpdatesWork

        # Test mixed updates (replace + append)
        $additionalUpdates = @{"Status" = "🔵 Review"}
        $appendUpdates2 = @{"API Design" = "[Review](link3)"}
        $result3 = Update-MarkdownTableWithAppend -Content $testContent -FeatureId "1.1.1" -AdditionalUpdates $additionalUpdates -AppendUpdates $appendUpdates2 -Notes "Mixed update test"

        $mixedUpdatesWork = ($result3 -match '1\.1\.1.*🔵 Review') -and ($result3 -match '\[Initial\]\(link1\) • \[Review\]\(link3\)') -and ($result3 -match 'Original notes; Mixed update test')
        Write-TestResult -TestName "Mixed replace and append updates" -Passed $mixedUpdatesWork

    } catch {
        Write-TestResult -TestName "Update-MarkdownTableWithAppend extracted functionality" -Passed $false -Message $_.Exception.Message
    }
}

function Test-ModuleExportsExtracted {
    Write-Host "`n=== Testing Extracted Module Exports ===" -ForegroundColor Cyan

    try {
        $moduleInfo = Get-Module -Name "TableOperations"
        $exportedFunctions = $moduleInfo.ExportedFunctions.Keys

        # Expected functions
        $expectedFunctions = @(
            'Update-MarkdownTable',
            'Update-MarkdownTableWithAppend'
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

        $correctFunctionCount = $exportedFunctions.Count -eq 2
        Write-TestResult -TestName "Extracted module exports exactly 2 functions" -Passed $correctFunctionCount

    } catch {
        Write-TestResult -TestName "Extracted module export completeness" -Passed $false -Message $_.Exception.Message
    }
}

function Test-ComplexTableScenarios {
    Write-Host "`n=== Testing Complex Table Scenarios ===" -ForegroundColor Cyan

    try {
        # Test with empty cells and special characters
        $complexContent = @"
# Complex Table Test

| Feature ID | Status | Priority | API Design | Test Status | Notes |
|------------|--------|----------|------------|-------------|-------|
| 1.1.1 | 🟡 In Progress | High | - | ⬜ No Tests | Initial feature |
| 1.1.2 |  | Medium | [Design](link) |  |  |
| 1.1.3 | 🟢 Complete | Low | [API](api) | ✅ Tested | Done |

More content here.
"@

        # Test updating row with empty cells
        $result = Update-MarkdownTable -Content $complexContent -FeatureId "1.1.2" -StatusColumn "Status" -Status "🔵 Review" -Notes "Added status"

        $emptyRowUpdated = $result -match '1\.1\.2.*🔵 Review.*Added status'
        Write-TestResult -TestName "Updates row with empty cells correctly" -Passed $emptyRowUpdated

        # Test preserving existing content in other columns
        $preservesContent = $result -match '1\.1\.2.*Medium.*\[Design\]\(link\)'
        Write-TestResult -TestName "Preserves existing content in other columns" -Passed $preservesContent

        # Test with special characters and emojis
        $specialUpdates = @{"Test Status" = "🧪 Testing"; "Priority" = "🔥 Critical"}
        $result2 = Update-MarkdownTable -Content $complexContent -FeatureId "1.1.1" -StatusColumn "Status" -Status "🚀 Deploying" -AdditionalUpdates $specialUpdates

        $specialCharsWork = ($result2 -match '1\.1\.1.*🚀 Deploying.*🔥 Critical.*🧪 Testing')
        Write-TestResult -TestName "Handles special characters and emojis correctly" -Passed $specialCharsWork

    } catch {
        Write-TestResult -TestName "Complex table scenarios" -Passed $false -Message $_.Exception.Message
    }
}

# Run all tests
Write-Host "🧪 Starting TableOperations Extracted Module Tests" -ForegroundColor Magenta
Write-Host "=" * 55 -ForegroundColor Magenta

Test-UpdateMarkdownTableExtracted
Test-UpdateMarkdownTableWithAppendExtracted
Test-ModuleExportsExtracted
Test-ComplexTableScenarios

# Summary
Write-Host "`n" + "=" * 55 -ForegroundColor Magenta
Write-Host "🏁 TableOperations Extracted Module Test Summary" -ForegroundColor Magenta
Write-Host "✅ Tests Passed: $script:TestsPassed" -ForegroundColor Green
Write-Host "❌ Tests Failed: $script:TestsFailed" -ForegroundColor Red
Write-Host "📊 Total Tests: $($script:TestsPassed + $script:TestsFailed)" -ForegroundColor Cyan

if ($script:TestsFailed -eq 0) {
    Write-Host "`n🎉 All tests passed! TableOperations module extraction successful." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  Some tests failed. Review the results above." -ForegroundColor Yellow
    exit 1
}
