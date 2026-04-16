# New-TestFile.ps1
# Creates a new test file with an automatically assigned ID
# Uses the central ID registry system and standardized document creation
# Reads project-config.json to determine language and select appropriate template
# SC-007: Writes pytest markers as single source of truth (no test-registry.yaml)

<#
.SYNOPSIS
    Creates a new test file with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates test files by:
    - Reading project-config.json to determine the project's primary language
    - Selecting the appropriate language-specific template
    - Generating a unique document ID (TE-TST-XXX)
    - Creating a properly formatted test file with pytest markers
    - Updating the ID tracker in the central ID registry
    - Writing pytest markers (feature, priority, test_type, specification) into the file
    - Automatically updating test implementation tracking (when FeatureId provided)

.PARAMETER TestName
    The name of the test (e.g., "UserAuthentication", "PaymentProcessing")

.PARAMETER TestType
    The type of test to create. Valid values are discovered dynamically by scanning
    subdirectories of the test directory (same logic as Run-Tests.ps1).
    Use any subdirectory name (e.g., Unit, Integration, Parser, Performance).

.PARAMETER ComponentName
    The name of the component being tested (optional)

.PARAMETER FeatureId
    The feature ID this test is associated with (for automation integration)

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.PARAMETER DryRun
    If specified, shows what would be updated without making changes

.EXAMPLE
    New-TestFile.ps1 -TestName "UserAuthentication" -TestType "Unit"

.EXAMPLE
    New-TestFile.ps1 -TestName "ParserFramework" -TestType "Parser" -FeatureId "2.1.1" -OpenInEditor

.EXAMPLE
    New-TestFile.ps1 -TestName "UserAuthentication" -TestType "Unit" -FeatureId "1.2.3" -DryRun

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - Reads project-config.json + languages-config/{language}/{language}-config.json for language-aware behavior
    - When FeatureId is provided, automatically updates test implementation tracking
    - Integrates with Process Framework automation infrastructure
    - Supports dry run mode for safe testing

    Template Metadata:
    - Script Type: Document Creation Script
    - Created: 2025-07-13
    - Updated: 2026-03-27 (IMP-244: PD-TST → TE-TST after SC-008 registry split; IMP-139: language-agnostic via languages-config)
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
    [ValidateSet("Critical", "Standard", "Extended")]
    [string]$Priority = "Standard",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

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
$projectConfigPath = Join-Path $projectRoot "doc/project-config.json"
$language = "Dart" # Default fallback for backward compatibility

if (Test-Path $projectConfigPath) {
    try {
        $projectConfig = Get-Content $projectConfigPath -Raw | ConvertFrom-Json
        $language = $projectConfig.project_metadata.primary_language
        $testsDir = $projectConfig.paths.tests
        $testAutomatedDir = $projectConfig.testing.testDirectory
        Write-Host "📋 Detected project language: $language (from project-config.json)" -ForegroundColor Cyan
    } catch {
        Write-Warning "Could not parse project-config.json, defaulting to Dart"
    }
} else {
    Write-Warning "project-config.json not found at $projectConfigPath, defaulting to Dart"
}

# --- Language configuration from languages-config/{language}/{language}-config.json ---
$langConfigPath = Join-Path $projectRoot "process-framework/languages-config/$($language.ToLower())/$($language.ToLower())-config.json"
if (-not (Test-Path $langConfigPath)) {
    Write-Error "Language config not found: $langConfigPath. Create it from languages-config/ template."
    exit 1
}

try {
    $langConfig = Get-Content $langConfigPath -Raw | ConvertFrom-Json
    Write-Host "📋 Loaded language config: $langConfigPath" -ForegroundColor Cyan
} catch {
    Write-Error "Could not parse language config: $($_.Exception.Message)"
    exit 1
}

$testingConfig = $langConfig.testing
$testsRoot = if ($testsDir) { $testsDir } else { "test" }
$testScanRoot = if ($testAutomatedDir) { $testAutomatedDir } else { $testsRoot }
$fileExtension = $testingConfig.testFileExtension
$namePattern = $testingConfig.testFileNamePattern

if (-not $fileExtension -or -not $namePattern) {
    Write-Error "Language config missing required fields: testFileExtension, testFileNamePattern"
    exit 1
}

# --- Discover valid test types by scanning test subdirectories (same logic as Run-Tests.ps1) ---
$testPath = Join-Path $projectRoot $testScanRoot
$excludedDirs = @('__pycache__', '.pytest_cache', 'fixtures', 'helpers', 'utils', 'conftest', 'node_modules', '.dart_tool', 'build')
$validTestTypes = @()

if (Test-Path $testPath) {
    $validTestTypes = Get-ChildItem -Path $testPath -Directory |
        Where-Object { $_.Name -notin $excludedDirs -and -not $_.Name.StartsWith('.') } |
        ForEach-Object { $_.Name }
}

if ($validTestTypes.Count -eq 0) {
    Write-Error "No test type directories found in $testPath"
    exit 1
}

# Validate TestType against discovered directories (case-insensitive)
$matchedDir = $validTestTypes | Where-Object { $_ -eq $TestType.ToLower() }
if (-not $matchedDir) {
    $validList = $validTestTypes -join ', '
    Write-Error "Invalid TestType '$TestType' for $language projects. Available directories: $validList"
    exit 1
}

# Determine output directory
$testTypeDir = $matchedDir
$outputDirectory = Join-Path $projectRoot (Join-Path $testScanRoot $testTypeDir)

# Generate test file name from pattern
$sanitizedName = $TestName.ToLower() -replace '[\s\-]+', '_'
$testFileName = $namePattern.Replace('{name}', $sanitizedName) + $fileExtension

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

# Prepare custom replacements for template (includes pytest marker placeholders — SC-007)
$customReplacements = @{
    "[TEST_NAME]" = $TestName
    "[TEST_TYPE]" = $TestType
    "[COMPONENT_NAME]" = if ($ComponentName -ne "") { $ComponentName } else { $TestName }
    "[TEST_FILE_NAME]" = $sanitizedName
    "[CREATED_DATE]" = Get-Date -Format "yyyy-MM-dd"
    "[UPDATED_DATE]" = Get-Date -Format "yyyy-MM-dd"
    "[FEATURE_ID]" = if ($FeatureId -ne "") { $FeatureId } else { "TODO" }
    "[PRIORITY]" = $Priority
    "[TEST_TYPE_MARKER]" = $testTypeDir.ToLower()
}

# Create the document using standardized process
try {
    $templateName = "test-file-template$fileExtension.template"
    $templatePath = Join-Path $projectRoot "process-framework/templates/03-testing/$templateName"

    if (-not (Test-Path $templatePath)) {
        Write-Error "Template not found: $templatePath. Please create the $templateName template first."
        exit 1
    }

    if (-not $PSCmdlet.ShouldProcess("$outputDirectory/$testFileName", "Create test file")) {
        return
    }

    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "TE-TST" -IdDescription "test_file" -DocumentName $TestName -OutputDirectory $outputDirectory -FileNamePattern $testFileName -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

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
        $baseCommand = $testingConfig.baseCommand
        $runCommand = if ($baseCommand) { "$baseCommand $outputDirectory/$testFileName" } else { "Run the test file using your test runner" }

        $details += @(
            "",
            "Next steps:",
            "1. Implement the test cases based on the Test Specification",
            "2. Add necessary imports and dependencies",
            "3. Run the test to verify: $runCommand"
        )
    }

    Write-ProjectSuccess -Message "Created test file with ID: $documentId" -Details $details

    # Automation Integration: Write pytest markers and update tracking (SC-007)
    if ($FeatureId -ne "") {
        try {
            # Check if automation functions are available
            $automationFunctions = @(
                "Update-TestImplementationStatus",
                "Update-TestImplementationStatusEnhanced",
                "Add-PytestMarkers"
            )

            $missingFunctions = $automationFunctions | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }

            if ($missingFunctions.Count -eq 0) {
                Write-Host "`n🔄 Updating pytest markers and test tracking..." -ForegroundColor Cyan

                # Prepare relative paths for tracking
                $relativePath = "$testsRoot/$testTypeDir/$testFileName"
                $trackingRelativePath = "../../automated/$testTypeDir/$testFileName"

                # Write pytest markers into the created test file (SC-007: markers are source of truth)
                $testFileFullPath = Join-Path $outputDirectory $testFileName
                $specPath = if ($TestSpecification -ne "") { $TestSpecification } else { $null }

                if ($DryRun) {
                    Write-Host "DRY RUN: Would write pytest markers for $FeatureId" -ForegroundColor Yellow
                    Write-Host "  Feature ID: $FeatureId" -ForegroundColor Cyan
                    Write-Host "  Test Type: $($testTypeDir.ToLower())" -ForegroundColor Cyan
                    Write-Host "  Priority: $Priority" -ForegroundColor Cyan
                    Write-Host "  Test File: [$testFileName]($trackingRelativePath)" -ForegroundColor Cyan

                    if ($testTypeDir.ToLower() -eq "performance") {
                        Write-Host "DRY RUN: Would skip test-tracking.md (performance tests use performance-test-tracking.md)" -ForegroundColor Yellow
                    } else {
                        Write-Host "DRY RUN: Would update test-tracking.md for $FeatureId" -ForegroundColor Yellow
                    }
                } else {
                    # Write markers into the test file
                    Add-PytestMarkers -FilePath $testFileFullPath -FeatureId $FeatureId -TestType $testTypeDir.ToLower() -Priority $Priority -SpecificationPath $specPath
                    Write-Host "  ✅ Pytest markers written to test file" -ForegroundColor Green

                    if ($testTypeDir.ToLower() -eq "performance") {
                        # Performance tests are tracked in performance-test-tracking.md (cross-cutting, Test ID based)
                        # not in feature-based test-tracking.md
                        Write-Host "  ℹ️  Performance test — skipping test-tracking.md update" -ForegroundColor Cyan
                        Write-Host "  📋 Manual update required: add entry to performance-test-tracking.md" -ForegroundColor Yellow
                        Write-Host "  📖 See: test/state-tracking/permanent/performance-test-tracking.md" -ForegroundColor Yellow
                    } else {
                        # Update test implementation tracking (file path as identifier — SC-007)
                        $updateResult = Update-TestImplementationStatusEnhanced -FeatureId $FeatureId -TestFilePath $trackingRelativePath -Status "🟡 Implementation In Progress" -DryRun:$DryRun

                        Write-Host "  ✅ Test implementation tracking updated" -ForegroundColor Green
                        Write-Host "  🟡 Status: 📝 Needs Implementation → 🟡 Implementation In Progress" -ForegroundColor Green
                        Write-Host "  🔗 Test file linked in tracking" -ForegroundColor Green
                    }
                }
            } else {
                Write-Host "`n⚠️  Automation functions not available:" -ForegroundColor Yellow
                Write-Host "Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Yellow
                Write-Host "Manual Update Required:" -ForegroundColor Yellow
                Write-Host "  - Update feature $FeatureId test status to '🟡 Implementation In Progress'" -ForegroundColor Cyan
                Write-Host "  - Add test file link: [$testFileName]($trackingRelativePath)" -ForegroundColor Cyan
            }
        }
        catch {
            Write-Warning "Failed to update test tracking automatically: $($_.Exception.Message)"
            Write-Host "Manual Update Required:" -ForegroundColor Yellow
            Write-Host "  - Update feature $FeatureId test status to '🟡 Implementation In Progress'" -ForegroundColor Cyan
        }
    }
}
catch {
    Write-ProjectError -Message "Failed to create test file: $($_.Exception.Message)" -ExitCode 1
}
