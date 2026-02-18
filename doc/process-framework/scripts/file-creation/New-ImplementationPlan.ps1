# New-ImplementationPlan.ps1
# Creates a new Implementation Plan document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Implementation Plan document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Implementation Plan documents by:
    - Generating a unique document ID (PD-IMP-XXX)
    - Creating a properly formatted implementation plan file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for planning feature implementation

.PARAMETER FeatureName
    Name of the feature being implemented (used for file naming and document title)

.PARAMETER Description
    Brief description of the feature (optional, used in metadata)

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-ImplementationPlan.ps1 -FeatureName "user-authentication" -Description "User authentication and authorization system"

.EXAMPLE
    .\New-ImplementationPlan.ps1 -FeatureName "booking-system" -Description "Escape room booking and reservation" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Script Metadata:
    - Script Type: Document Creation Script
    - Created: 2025-10-30
    - For: Creating implementation plan documents for features
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureName,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers with robust path resolution
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "..\..\modules\Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
}
catch {
    Write-Error "Failed to import Common-ScriptHelpers module from: $modulePath"
    Write-Error "Please ensure the script is run from the correct directory or the module path is correct."
    exit 1
}

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_name" = $FeatureName
    "status"       = "Planning"
}

# Prepare custom replacements
$customReplacements = @{
    "[Feature Name]"        = $FeatureName
    "[Feature Description]" = if ($Description -ne "") { $Description } else { "Description of feature" }
    "[Date]"                = Get-Date -Format "yyyy-MM-dd"
    "[Author]"              = "AI Agent & Human Partner"
}

# Create the document using standardized process
try {
    # Check if implementation plan template exists
    $templatePath = "doc/process-framework/templates/templates/implementation-plan-template.md"

    if (-not (Test-Path $templatePath)) {
        Write-Warning "Implementation plan template not found at: $templatePath"
        Write-Warning "Please create the template using New-Template.ps1 before using this script."
        Write-Error "Template file required: implementation-plan-template.md"
        exit 1
    }

    $documentId = New-StandardProjectDocument `
        -TemplatePath $templatePath `
        -IdPrefix "PD-IMP" `
        -IdDescription "$FeatureName implementation plan" `
        -DocumentName "$FeatureName-implementation-plan" `
        -DirectoryType "implementation-plans" `
        -Replacements $customReplacements `
        -AdditionalMetadataFields $additionalMetadataFields `
        -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Feature: $FeatureName",
        "Location: doc/product-docs/technical/implementation-plans/$FeatureName-implementation-plan.md"
    )

    if ($Description -ne "") {
        $details += "Description: $Description"
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
            "   doc/process-framework/guides/guides/implementation-plan-customization-guide.md",
            "🎯 FOCUS AREAS: Component breakdown, task sequencing, dependency mapping",
            "",
            "🎯 What you need to do:",
            "   • Define feature components and architecture integration",
            "   • Break down implementation into sequenced tasks",
            "   • Map dependencies between tasks",
            "   • Add effort estimates and timeline",
            "   • Document integration points",
            "   • Define testing strategy per component",
            "   • Identify risks and mitigation strategies",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content."
        )
    }

    Write-ProjectSuccess -Message "Created Implementation Plan with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Implementation Plan: $($_.Exception.Message)" -ExitCode 1
}

<#
.NOTES
TESTING CHECKLIST:
Before considering this script complete, test the following:

1. MODULE IMPORT TEST:
   - Run the script from its intended directory
   - Verify Common-ScriptHelpers module loads without errors
   - Test with both PowerShell ISE and PowerShell terminal

2. BASIC FUNCTIONALITY TEST:
   - Create a test document with minimal parameters
   - Verify the document is created in the correct location
   - Check that the ID is assigned correctly and incremented

3. TEMPLATE REPLACEMENT TEST:
   - Open the created document
   - Verify all [Placeholder] values are replaced correctly
   - Check that no template placeholders remain unreplaced

4. METADATA TEST:
   - Verify the document metadata section is populated correctly
   - Check that custom metadata fields are included
   - Ensure metadata format matches expected structure

5. ERROR HANDLING TEST:
   - Test with invalid parameters
   - Test when template file doesn't exist
   - Test when output directory doesn't exist
   - Verify error messages are helpful

6. NEXT STEPS OUTPUT TEST:
   - Run script without -OpenInEditor flag
   - Verify next steps display correctly
   - Check that guide references appear as expected
   - Test with -OpenInEditor flag to ensure next steps are skipped

7. CLEANUP TEST:
   - Remove test documents after verification
   - Ensure no temporary files are left behind

EXAMPLE TEST COMMANDS:
# Basic test
.\New-ImplementationPlan.ps1 -FeatureName "test-feature" -Description "Test creation"

# Verify created document
Get-Content "doc/product-docs/technical/implementation-plans/test-feature-implementation-plan.md" | Select-Object -First 20

# Cleanup
Remove-Item "doc/product-docs/technical/implementation-plans/test-feature-implementation-plan.md" -Force
#>
