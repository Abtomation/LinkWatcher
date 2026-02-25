# New-FrameworkExtensionConcept.ps1
# Creates a new Framework Extension Concept document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Framework Extension Concept document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Framework Extension Concept documents by:
    - Generating a unique document ID (PF-PRO-XXX)
    - Creating a properly formatted concept document file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for framework extension planning

.PARAMETER ExtensionName
    The name of the framework extension (e.g., "Architecture Framework", "Testing Framework")

.PARAMETER ExtensionDescription
    Brief description of what the extension will provide

.PARAMETER ExtensionScope
    The scope of the extension (e.g., "Multi-component", "Single-domain", "Cross-cutting")

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    ../../../../../../../../proposals/New-FrameworkExtensionConcept.ps1 -ExtensionName "Architecture Framework" -ExtensionDescription "Comprehensive architecture design and review framework"

.EXAMPLE
    ../../../../../../../../proposals/New-FrameworkExtensionConcept.ps1 -ExtensionName "Testing Framework" -ExtensionDescription "Automated testing infrastructure and processes" -ExtensionScope "Multi-component" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Template Metadata:
    - Template ID: PF-TEM-020
    - Template Type: Document Creation Script
    - Created: 2025-07-28
    - For: Creating PowerShell scripts that generate framework extension concept documents
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$ExtensionName,

    [Parameter(Mandatory=$false)]
    [string]$ExtensionDescription = "",

    [Parameter(Mandatory=$false)]
    [string]$ExtensionScope = "",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "extension_name" = $ExtensionName
    "extension_description" = $ExtensionDescription
    "extension_scope" = $ExtensionScope
}

# Prepare custom replacements
# IMPORTANT: Use exact bracket notation like "[Placeholder Name]" - do NOT escape brackets
# The replacement keys must match exactly what appears in your template file
$customReplacements = @{
    "[Extension Name]" = $ExtensionName
    "[Extension Description]" = if ($ExtensionDescription -ne "") { $ExtensionDescription } else { "Framework extension to be defined" }
    "[Extension Scope]" = if ($ExtensionScope -ne "") { $ExtensionScope } else { "Multi-component" }
    "[Created Date]" = Get-Date -Format "yyyy-MM-dd"
    "[Author]" = "AI Agent & Human Partner"
}

# Create the document using standardized process
try {
    # Use DirectoryType for ID registry-based directory resolution
    $documentId = New-StandardProjectDocument -TemplatePath "doc/process-framework/templates/templates/framework-extension-concept-template.md" -IdPrefix "PF-PRO" -IdDescription "Framework Extension Concept: ${ExtensionName}" -DocumentName $ExtensionName -DirectoryType "main" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Extension Name: $ExtensionName",
        "Extension Description: $ExtensionDescription"
    )

    # Add conditional details
    if ($ExtensionScope -ne "") {
        $details += "Extension Scope: $ExtensionScope"
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
            "   doc/process-framework/guides/guides/framework-extension-task-usage-guide.md",
            "🎯 FOCUS AREAS: 'Concept Development & Approval' section",
            "",
            "🎯 What the guide will teach you:",
            "   • How to develop comprehensive extension concepts",
            "   • Workflow definition and artifact dependency mapping",
            "   • State tracking integration strategies",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content."
        )
    }

    Write-ProjectSuccess -Message "Created Framework Extension Concept with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Framework Extension Concept: $($_.Exception.Message)" -ExitCode 1
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
   - Create a test concept with minimal parameters
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
   - Verify next steps replacement displays correctly
   - Check that guide references appear as expected
   - Test with -OpenInEditor flag to ensure next steps are skipped

7. CLEANUP TEST:
   - Remove test documents after verification
   - Ensure no temporary files are left behind

EXAMPLE TEST COMMANDS:
# Basic test
../../../../../../../../proposals/New-FrameworkExtensionConcept.ps1 -ExtensionName "Test Framework" -ExtensionDescription "Test extension" -ExtensionScope "Test"

# Verify created document
Get-Content "../../../../../../proposals/doc/process-framework/proposals/test-framework-concept.md" | Select-Object -First 20

# Cleanup
Remove-Item "../../../../../../proposals/doc/process-framework/proposals/test-framework-concept.md" -Force
#>
