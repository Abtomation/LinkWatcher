# New-TestFile.ps1
# Creates a new test file with an automatically assigned ID
# Uses the central ID registry system and standardized document creation
# Reads project-config.json to determine language and select appropriate template

<#
.SYNOPSIS
    Creates a new test file with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates test files by:
    - Reading project-config.json to determine the project's primary language
    - Selecting the appropriate language-specific template
    - Generating a unique document ID (PD-TST-XXX)
    - Creating a properly formatted test file
    - Updating the ID tracker in the central ID registry
    - Automatically updating test implementation tracking (when FeatureId provided)
    - Updating test-registry.yaml with implementation progress

.PARAMETER TestName
    The name of the test (e.g., "UserAuthentication", "PaymentProcessing")

.PARAMETER TestType
    The type of test to create. Valid values depend on the project's primary language:
    - Python: Unit, Integration, Parser, Performance
    - Dart: Unit, Integration, Widget, E2E
    If not specified or invalid for the language, defaults to Unit.

.PARAMETER ComponentName
    The name of the component being tested (optional)

.PARAMETER FeatureId
    The feature ID this test is associated with (for automation integration)

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.PARAMETER DryRun
    If specified, shows what would be updated without making changes

.EXAMPLE
    .\New-TestFile.ps1 -TestName "UserAuthentication" -TestType "Unit"

.EXAMPLE
    .\New-TestFile.ps1 -TestName "ParserFramework" -TestType "Parser" -FeatureId "2.1.1" -OpenInEditor

.EXAMPLE
    .\New-TestFile.ps1 -TestName "UserAuthentication" -TestType "Unit" -FeatureId "1.2.3" -DryRun

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - Reads project-config.json for language-aware template selection
    - When FeatureId is provided, automatically updates test implementation tracking
    - Integrates with Process Framework automation infrastructure
    - Supports dry run mode for safe testing

    Template Metadata:
    - Script Type: Document Creation Script
    - Created: 2025-07-13
    - Updated: 2026-02-20 (tech-agnostic genericization)
    - For: Creating test files from language-specific templates
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$TestName,

    [Parameter(Mandatory=$true)]
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
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
try {
    Invoke-StandardScriptInitialization
} catch {
    Write-Warning "Standard initialization not available, proceeding with basic setup"
    $ErrorActionPreference = "Stop"
}

# Get project root
$projectRoot = Get-ProjectRoot

# --- Language Detection via project-config.json ---
$projectConfigPath = Join-Path $projectRoot "doc/process-framework/project-config.json"
$language = "Dart" # Default fallback for backward compatibility

if (Test-Path $projectConfigPath) {
    try {
        $projectConfig = Get-Content $projectConfigPath -Raw | ConvertFrom-Json
        $language = $projectConfig.project_metadata.primary_language
        $testsDir = $projectConfig.paths.tests
        Write-Host "📋 Detected project language: $language (from project-config.json)" -ForegroundColor Cyan
    } catch {
        Write-Warning "Could not parse project-config.json, defaulting to Dart"
    }
} else {
    Write-Warning "project-config.json not found at $projectConfigPath, defaulting to Dart"
}

# --- Language-specific configuration ---
$languageConfig = switch ($language.ToLower()) {
    "python" {
        @{
            ValidTestTypes = @("Unit", "Integration", "Parser", "Performance")
            TemplateName = "test-file-template.py"
            FilePrefix = "test_"
            FileSuffix = ""
            FileExtension = ".py"
            TestsRoot = if ($testsDir) { $testsDir } else { "tests" }
            DirectoryMap = @{
                "unit" = "unit"
                "integration" = "integration"
                "parser" = "parsers"
                "performance" = "performance"
            }
        }
    }
    "dart" {
        @{
            ValidTestTypes = @("Unit", "Integration", "Widget", "E2E")
            TemplateName = "test-file-template.dart"
            FilePrefix = ""
            FileSuffix = "_test"
            FileExtension = ".dart"
            TestsRoot = if ($testsDir) { $testsDir } else { "test" }
            DirectoryMap = @{
                "unit" = "unit"
                "integration" = "integration"
                "widget" = "widget"
                "e2e" = "../integration_test"
            }
        }
    }
    default {
        Write-Warning "Unsupported language '$language', using Python defaults"
        @{
            ValidTestTypes = @("Unit", "Integration")
            TemplateName = "test-file-template.py"
            FilePrefix = "test_"
            FileSuffix = ""
            FileExtension = ".py"
            TestsRoot = if ($testsDir) { $testsDir } else { "tests" }
            DirectoryMap = @{
                "unit" = "unit"
                "integration" = "integration"
            }
        }
    }
}

# Validate TestType against language-specific valid types
if ($TestType -notin $languageConfig.ValidTestTypes) {
    $validList = $languageConfig.ValidTestTypes -join ', '
    Write-Error "Invalid TestType '$TestType' for $language projects. Valid types: $validList"
    exit 1
}

# Determine output directory based on test type and language
$testTypeDir = $languageConfig.DirectoryMap[$TestType.ToLower()]
if (-not $testTypeDir) { $testTypeDir = "unit" }
$outputDirectory = Join-Path $projectRoot (Join-Path $languageConfig.TestsRoot $testTypeDir)

# Generate test file name based on language conventions
$sanitizedName = $TestName.ToLower() -replace '\s+', '_'
$testFileName = "$($languageConfig.FilePrefix)$sanitizedName$($languageConfig.FileSuffix)$($languageConfig.FileExtension)"

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "test_name" = $TestName
    "test_type" = $TestType
    "component_name" = if ($ComponentName -ne "") { $ComponentName } else { $TestName }
    "language" = $language
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
    "[TEST_FILE_NAME]" = $sanitizedName
    "[CREATED_DATE]" = Get-Date -Format "yyyy-MM-dd"
    "[UPDATED_DATE]" = Get-Date -Format "yyyy-MM-dd"
}

# Create the document using standardized process
try {
    $templatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/$($languageConfig.TemplateName)"

    if (-not (Test-Path $templatePath)) {
        Write-Error "Template not found: $templatePath. Please create the $($languageConfig.TemplateName) template first."
        exit 1
    }

    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PD-TST" -IdDescription "test_file" -DocumentName $TestName -OutputDirectory $outputDirectory -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Test Name: $TestName",
        "Test Type: $TestType",
        "Language: $language",
        "File Name: $testFileName",
        "Output Directory: $outputDirectory"
    )

    # Add conditional details
    if ($ComponentName -ne "") {
        $details += "Component: $ComponentName"
    }

    # Add next steps if not opening in editor
    if (-not $OpenInEditor) {
        $runCommand = switch ($language.ToLower()) {
            "python" { "pytest $outputDirectory/$testFileName" }
            "dart" { "flutter test $outputDirectory/$testFileName" }
            default { "Run the test file using your test runner" }
        }

        $details += @(
            "",
            "Next steps:",
            "1. Implement the test cases based on the Test Specification",
            "2. Add necessary imports and dependencies",
            "3. Run the test to verify: $runCommand"
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

                # Prepare relative paths for registry and tracking
                $relativePath = "$($languageConfig.TestsRoot)/$testTypeDir/$testFileName"
                $trackingRelativePath = "../../../$relativePath"

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

                    Write-Host "DRY RUN: Would add entry to test-registry.yaml" -ForegroundColor Yellow
                    Write-Host "  Feature ID: $FeatureId" -ForegroundColor Cyan
                    Write-Host "  File Path: $relativePath" -ForegroundColor Cyan
                    Write-Host "  Test Type: $TestType" -ForegroundColor Cyan
                } else {
                    # Add entry to test registry
                    $specPath = if ($TestSpecification -ne "") { $TestSpecification } else { $null }
                    $description = "$TestType tests for $($additionalUpdates['Component Name']) component - created via New-TestFile.ps1"

                    $registryTestId = Add-TestRegistryEntry -FeatureId $FeatureId -FileName $testFileName -FilePath $relativePath -TestType $TestType -ComponentName $($additionalUpdates['Component Name']) -SpecificationPath $specPath -Description $description -DryRun:$DryRun

                    # Update test implementation tracking
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
                Write-Host "  - Update test-registry.yaml with new test file entry" -ForegroundColor Cyan
            }
        }
        catch {
            Write-Warning "Failed to update test implementation tracking automatically: $($_.Exception.Message)"
            Write-Host "Manual Update Required:" -ForegroundColor Yellow
            Write-Host "  - Update feature $FeatureId test status to '🟡 Implementation In Progress'" -ForegroundColor Cyan
        }
    }
}
catch {
    Write-ProjectError -Message "Failed to create test file: $($_.Exception.Message)" -ExitCode 1
}
