# New-FrameworkExtensionConcept.ps1
# Creates a new Framework Extension Concept document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Framework Extension Concept document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Framework Extension Concept documents by:
    - Generating a unique document ID (PF-PRO-XXX)
    - Selecting a type-specific template (Creation, Modification, or Hybrid)
    - Creating a properly formatted concept document file
    - Updating the ID tracker in the central ID registry
    - Providing a focused template for framework extension planning

.PARAMETER ExtensionName
    The name of the framework extension (e.g., "Architecture Framework", "Testing Framework")

.PARAMETER ExtensionDescription
    Brief description of what the extension will provide

.PARAMETER ExtensionScope
    The scope of the extension (e.g., "Multi-component", "Single-domain", "Cross-cutting")

.PARAMETER Type
    The extension type, which selects the appropriate template:
    - Creation: Extension adds entirely new artifacts (tasks, templates, guides, scripts)
    - Modification: Extension modifies existing artifacts (adds steps to tasks, updates templates)
    - Hybrid: Extension both creates new artifacts and modifies existing ones

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    New-FrameworkExtensionConcept.ps1 -ExtensionName "Architecture Framework" -ExtensionDescription "Comprehensive architecture design and review framework" -Type Creation

.EXAMPLE
    New-FrameworkExtensionConcept.ps1 -ExtensionName "Testing Framework" -ExtensionDescription "Automated testing infrastructure and processes" -Type Modification -ExtensionScope "Multi-component" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - Template selection: Creation and Modification use dedicated templates; Hybrid uses the full template

    Template Metadata:
    - Template ID: PF-TEM-020
    - Template Type: Document Creation Script
    - Created: 2025-07-28
    - Updated: 2026-04-14
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

    [Parameter(Mandatory=$true)]
    [ValidateSet("Creation", "Modification", "Hybrid")]
    [string]$Type,

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization


# Soak verification opt-in (PF-PRO-028 v2.0 Pattern B; helper-routed armoring via DocumentManagement.psm1).
# Caller-aware no-arg form: helper resolves this script's path via Get-PSCallStack.
# Idempotent — silently no-ops if already registered.
Register-SoakScript

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
    "[Creation / Modification / Hybrid]" = $Type
}

# Select template based on extension type
$templatePath = switch ($Type) {
    "Creation"     { "process-framework/templates/support/framework-extension-concept-creation-template.md" }
    "Modification" { "process-framework/templates/support/framework-extension-concept-modification-template.md" }
    "Hybrid"       { "process-framework/templates/support/framework-extension-concept-template.md" }
}

Write-Verbose "Extension type: $Type — using template: $templatePath"

# Create the document using standardized process
try {
    # Use DirectoryType for ID registry-based directory resolution
    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-PRO" -IdDescription "Framework Extension Concept: ${ExtensionName}" -DocumentName $ExtensionName -DirectoryType "main" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

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
        $details += "Customization required — see process-framework/guides/support/framework-extension-customization-guide.md"
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
Get-Content "../../../../../../proposals/process-framework-local/proposals/test-framework-concept.md" | Select-Object -First 20

# Cleanup
Remove-Item "../../../../../../proposals/process-framework-local/proposals/test-framework-concept.md" -Force
#>
