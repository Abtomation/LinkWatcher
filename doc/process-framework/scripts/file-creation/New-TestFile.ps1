# ../../../../test/../../../../test/New-TestFile.ps1
# Creates a new test file with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new test file with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates test files by:
    - Generating a unique document ID (PD-TST-XXX)
    - Creating a properly formatted test file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for test implementation
    - Automatically updating test implementation tracking (when FeatureId provided)
    - Updating ../../../../test/../../../../test/../../../../test/../../../../test/test-registry.yaml with implementation progress

.PARAMETER TestName
    The name of the test (e.g., "UserAuthentication", "PaymentProcessing")

.PARAMETER TestType
    The type of test to create (Unit, Integration, Widget, E2E)

.PARAMETER ComponentName
    The name of the component being tested (optional)

.PARAMETER FeatureId
    The feature ID this test is associated with (for automation integration)

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.PARAMETER DryRun
    If specified, shows what would be updated without making changes

.EXAMPLE
    .\../../../../test/../../../../test/New-TestFile.ps1 -TestName "UserAuthentication" -TestType "Unit"

.EXAMPLE
    .\../../../../test/../../../../test/New-TestFile.ps1 -TestName "LoginScreen" -TestType "Widget" -ComponentName "LoginScreen" -OpenInEditor

.EXAMPLE
    .\../../../../test/../../../../test/New-TestFile.ps1 -TestName "UserAuthentication" -TestType "Unit" -FeatureId "1.2.3" -DryRun

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - When FeatureId is provided, automatically updates test implementation tracking
    - Integrates with Process Framework automation infrastructure
    - Supports dry run mode for safe testing

    Template Metadata:
    - Script Type: Document Creation Script
    - Created: 2025-07-13
    - For: Creating test files from templates
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$TestName,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Unit", "Integration", "Widget", "E2E")]
    [string]$TestType,

    [Parameter(Mandatory=$false)]
    [string]$ComponentName = "",

    [Parameter(Mandatory=$false)]
    [string]$FeatureId = "",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Import the common helpers
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$helpersPath = Join-Path $projectRoot "../../../../test/doc/process-framework/scripts/Common-ScriptHelpers.psm1"

if (Test-Path $helpersPath) {
    Import-Module $helpersPath -Force
} else {
    Write-Error "Cannot find common helpers at: $helpersPath"
    exit 1
}

# Perform standard initialization
Invoke-StandardScriptInitialization

# Determine output directory based on test type
$outputDirectory = switch ($TestType.ToLower()) {
    "unit" { Join-Path $projectRoot "test\unit" }
    "integration" { Join-Path $projectRoot "test\integration" }
    "widget" { Join-Path $projectRoot "test\widget" }
    "e2e" { Join-Path $projectRoot "integration_test" }
    default { Join-Path $projectRoot "test\unit" }
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "test_name" = $TestName
    "test_type" = $TestType
    "component_name" = if ($ComponentName -ne "") { $ComponentName } else { $TestName }
}

# Add feature ID if provided
if ($FeatureId -ne "") {
    $additionalMetadataFields["feature_id"] = $FeatureId
}

# Prepare custom replacements for template
$customReplacements = @{
    "[TEST_NAME]" = $TestName
    "[TEST_TYPE]" = $TestType
    "[COMPONENT_NAME]" = if ($ComponentName -ne "") { $ComponentName } else { $TestName }
    "[TEST_FILE_NAME]" = $TestName.ToLower() -replace '\s+', '_'
}

# Add standard date replacements
$customReplacements["[CREATED_DATE]"] = Get-Date -Format "yyyy-MM-dd"
$customReplacements["[UPDATED_DATE]"] = Get-Date -Format "yyyy-MM-dd"

# Create the document using standardized process
try {
    $templatePath = Join-Path $projectRoot "../../../../test/doc/process-framework/templates/templates/test-file-template.dart"
    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PD-TST" -IdDescription "test_file" -DocumentName $TestName -OutputDirectory $outputDirectory -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Test Name: $TestName",
        "Test Type: $TestType",
        "Output Directory: $outputDirectory"
    )

    # Add conditional details
    if ($ComponentName -ne "") {
        $details += "Component: $ComponentName"
    }

    # Add next steps if not opening in editor
    if (-not $OpenInEditor) {
        $details += @(
            "",
            "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - EXTENSIVE CUSTOMIZATION REQUIRED 🚨🚨🚨",
            "",
            "⚠️  IMPORTANT: This script creates ONLY a structural template/framework.",
            "⚠️  The generated file is NOT a functional document until extensively customized.",
            "⚠️  AI agents MUST follow the referenced guide to properly customize the content.",
            "",
            "📖 MANDATORY CUSTOMIZATION GUIDE:",
            "   doc/process-framework/guides/guides/test-file-creation-guide.md",
            "🎯 FOCUS AREAS: 'Step-by-Step Instructions' and 'Quality Assurance' sections",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content.",
            "",
            "Next steps:",
            "1. Implement the test cases based on the Test Specification",
            "2. Add necessary imports and dependencies",
            "3. Run the test to verify it works: flutter test $($outputDirectory)\$($TestName.ToLower() -replace '\s+', '_')_test.dart"
        )
    }

    Write-ProjectSuccess -Message "Created test file with ID: $documentId" -Details $details

    # Automation Integration: Update test implementation tracking if FeatureId provided
    if ($FeatureId -ne "") {
        try {
            # Check if automation functions are available
            $automationFunctions = @(
                "Update-TestImplementationStatus",
                "Update-TestImplementationStatusEnhanced",
                "Add-TestRegistryEntry"
            )

            $missingFunctions = $automationFunctions | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }

            if ($missingFunctions.Count -eq 0) {
                Write-Host "`n🔄 Updating test implementation tracking..." -ForegroundColor Cyan

                # Prepare test file path for registry updates
                $testFileName = "$($TestName.ToLower() -replace '\s+', '_')_test.dart"
                $relativePath = switch ($TestType.ToLower()) {
                    "unit" { "test/unit/$testFileName" }
                    "integration" { "test/integration/$testFileName" }
                    "widget" { "test/widget/$testFileName" }
                    "e2e" { "integration_test/$testFileName" }
                    default { "test/unit/$testFileName" }
                }

                # Prepare relative path for test implementation tracking (from tracking file location)
                $trackingRelativePath = switch ($TestType.ToLower()) {
                    "unit" { "../../../test/unit/$testFileName" }
                    "integration" { "../../../test/integration/$testFileName" }
                    "widget" { "../../../test/widget/$testFileName" }
                    "e2e" { "../../../integration_test/$testFileName" }
                    default { "../../../test/unit/$testFileName" }
                }

                # Prepare additional updates for test implementation tracking
                $additionalUpdates = @{
                    "Test File" = "[$testFileName]($trackingRelativePath)"
                    "Test File ID" = $documentId
                    "Test Type" = $TestType
                    "Component Name" = if ($ComponentName -ne "") { $ComponentName } else { $TestName }
                }

                # Add notes about test file creation
                $automationNotes = "Test file created: $documentId ($(Get-ProjectTimestamp -Format 'Date')) - $TestType test for $($additionalUpdates['Component Name'])"

                if ($DryRun) {
                    Write-Host "DRY RUN: Would update test implementation tracking for $FeatureId" -ForegroundColor Yellow
                    Write-Host "  Status: 📝 Specification Created → 🟡 Implementation In Progress" -ForegroundColor Cyan
                    Write-Host "  Test File: [$testFileName]($trackingRelativePath)" -ForegroundColor Cyan
                    Write-Host "  Test Type: $TestType" -ForegroundColor Cyan
                    Write-Host "  Component: $($additionalUpdates['Component Name'])" -ForegroundColor Cyan
                    Write-Host "  Notes: $automationNotes" -ForegroundColor Cyan

                    # Show what would be added to test registry
                    Write-Host "DRY RUN: Would add entry to ../../../../test/../../../../test/../../../../test/../../../../test/test-registry.yaml" -ForegroundColor Yellow
                    Write-Host "  Feature ID: $FeatureId" -ForegroundColor Cyan
                    Write-Host "  File Path: $relativePath" -ForegroundColor Cyan
                    Write-Host "  Test Type: $TestType" -ForegroundColor Cyan
                    Write-Host "  Component: $($additionalUpdates['Component Name'])" -ForegroundColor Cyan
                } else {
                    # Add entry to test registry first to get the test ID
                    $specPath = if ($TestSpecification -ne "") { $TestSpecification } else { $null }
                    $description = "$TestType tests for $($additionalUpdates['Component Name']) component - created via ../../../../test/../../../../test/New-TestFile.ps1"

                    $registryTestId = Add-TestRegistryEntry -FeatureId $FeatureId -FileName $testFileName -FilePath $relativePath -TestType $TestType -ComponentName $($additionalUpdates['Component Name']) -SpecificationPath $specPath -Description $description -DryRun:$DryRun

                    # Update test implementation tracking with enhanced functionality
                    if ($registryTestId) {
                        $updateResult = Update-TestImplementationStatusEnhanced -FeatureId $FeatureId -TestFileId $registryTestId -TestFilePath $trackingRelativePath -Status "🟡 Implementation In Progress" -DryRun:$DryRun
                    } else {
                        Write-Warning "Could not get test registry ID, falling back to basic update"
                        $updateResult = Update-TestImplementationStatus -FeatureId $FeatureId -Status "🟡 Implementation In Progress" -AdditionalUpdates $additionalUpdates -DryRun:$DryRun
                    }

                    Write-Host "  ✅ Test implementation tracking updated successfully" -ForegroundColor Green
                    Write-Host "  🟡 Status: 📝 Specification Created → 🟡 Implementation In Progress" -ForegroundColor Green
                    Write-Host "  🔗 Test file linked in tracking" -ForegroundColor Green
                    Write-Host "  📝 Test registry entry created: $registryTestId" -ForegroundColor Green
                }
            } else {
                Write-Host "`n⚠️  Automation functions not available:" -ForegroundColor Yellow
                Write-Host "Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Yellow
                Write-Host "Manual Update Required:" -ForegroundColor Yellow
                Write-Host "  - Update feature $FeatureId test status to '🟡 Implementation In Progress'" -ForegroundColor Cyan
                Write-Host "  - Add test file link: [$testFileName]($trackingRelativePath)" -ForegroundColor Cyan
                Write-Host "  - Update ../../../../test/../../../../test/../../../../test/../../../../test/test-registry.yaml with new test file entry" -ForegroundColor Cyan
            }
        }
        catch {
            Write-Warning "Failed to update test implementation tracking automatically: $($_.Exception.Message)"
            Write-Host "Manual Update Required:" -ForegroundColor Yellow
            Write-Host "  - Update feature $FeatureId test status to '🟡 Implementation In Progress'" -ForegroundColor Cyan
            Write-Host "  - Add test file: [$testFileName]($trackingRelativePath)" -ForegroundColor Cyan
            Write-Host "  - Update ../../../../test/../../../../test/../../../../test/../../../../test/test-registry.yaml with test file details" -ForegroundColor Cyan
        }
    }
}
catch {
    Write-ProjectError -Message "Failed to create test file: $($_.Exception.Message)" -ExitCode 1
}
