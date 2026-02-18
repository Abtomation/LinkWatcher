# New-TestSpecification.ps1
# Creates a new Test Specification with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Test Specification document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Test Specification documents by:
    - Generating a unique document ID (PF-TSP-XXX)
    - Creating a properly formatted test specification file
    - Updating the ID tracker in the central ID registry
    - Updating feature tracking with test specification link and status
    - Providing a complete template for test specification creation from TDDs

    Note: This script creates the specification document and updates feature tracking.
    Test implementation tracking files are updated separately during the Test Implementation Task.

.PARAMETER FeatureId
    The feature ID that this test specification is for (e.g., "1.2.3" or "AUTH-001")

.PARAMETER FeatureName
    The name of the feature being specified for testing

.PARAMETER TddPath
    Path to the Technical Design Document that this test specification is based on

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-TestSpecification.ps1 -FeatureId "1.2.3" -FeatureName "user-authentication" -TddPath "../../../../../../test/specifications/doc/product-docs/technical/design/tdd-user-authentication.md"

.EXAMPLE
    .\New-TestSpecification.ps1 -FeatureId "AUTH-001" -FeatureName "login-flow" -TddPath "../../../../../../test/specifications/doc/product-docs/technical/design/tdd-login-flow.md" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Template Metadata:
    - Template ID: PF-TEM-020 (based on document creation script template)
    - Template Type: Document Creation Script
    - Created: 2025-07-13
    - For: Creating test specification documents from TDDs
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureId,

    [Parameter(Mandatory=$true)]
    [string]$FeatureName,

    [Parameter(Mandatory=$false)]
    [string]$TddPath = "",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
try {
    Invoke-StandardScriptInitialization
} catch {
    Write-Warning "Standard initialization not available, proceeding with basic setup"
    # Basic fallback initialization
    $ErrorActionPreference = "Stop"
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_id" = $FeatureId
    "feature_name" = $FeatureName
    "tdd_path" = $TddPath
}

# Prepare custom replacements for the template
$customReplacements = @{
    "[FEATURE-ID]" = $FeatureId
    "[FEATURE-NAME]" = $FeatureName
    "[TDD-PATH]" = if ($TddPath -ne "") { $TddPath } else { "[Path to Technical Design Document]" }
    "[CREATION-DATE]" = (Get-Date -Format "yyyy-MM-dd")
}

# Create the document using standardized process
try {
    $templatePath = Join-Path $projectRoot "../../../../../../test/specifications/doc/process-framework/templates/templates/test-specification-template.md"
    $outputDirectory = Join-Path $projectRoot "test\specifications\feature-specs"
    $documentName = "test-spec-$FeatureId-$FeatureName"

    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-TSP" -IdDescription "test-spec-$FeatureId-$FeatureName" -DocumentName $documentName -OutputDirectory $outputDirectory -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Update feature tracking files automatically
    try {
        # Get the actual filename that was created (kebab-case conversion)
        $kebabName = ConvertTo-KebabCase -InputString $documentName
        $actualFileName = "$kebabName.md"
        $documentPath = Join-Path $outputDirectory $actualFileName

        $trackingMetadata = @{
            "feature_id" = $FeatureId
            "feature_name" = $FeatureName
            "tdd_path" = $TddPath
        }

        Write-Host "📊 Updating feature tracking..." -ForegroundColor Cyan
        Update-DocumentTrackingFiles -DocumentId $documentId -DocumentType "TestSpecification" -DocumentPath $documentPath -Metadata $trackingMetadata
    }
    catch {
        Write-Warning "Failed to update feature tracking files: $($_.Exception.Message)"
        Write-Host "📋 Manual feature tracking updates may be required" -ForegroundColor Yellow
    }

    # Provide success details
    $details = @(
        "Feature ID: $FeatureId",
        "Feature Name: $FeatureName"
    )

    # Add conditional details
    if ($TddPath -ne "") {
        $details += "TDD Path: $TddPath"
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
            "   doc/process-framework/guides/guides/test-specification-creation-guide.md",
            "🎯 FOCUS AREAS: 'Step-by-Step Instructions' and 'Quality Assurance' sections",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content.",
            ""
        )
    }

    Write-ProjectSuccess -Message "Created Test Specification with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Test Specification: $($_.Exception.Message)" -ExitCode 1
}
