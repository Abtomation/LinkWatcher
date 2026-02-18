# [SCRIPT_NAME].ps1
# Creates a new [DOCUMENT_TYPE] with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new [DOCUMENT_TYPE] document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates [DOCUMENT_TYPE] documents by:
    - Generating a unique document ID ([ID_PREFIX]-XXX)
    - Creating a properly formatted document file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for [DOCUMENT_PURPOSE]

.PARAMETER [PRIMARY_PARAMETER]
    [Description of the primary parameter - typically name or title]

.PARAMETER [SECONDARY_PARAMETER]
    [Description of secondary parameter - typically description or type]

.PARAMETER [OPTIONAL_PARAMETER]
    [Description of optional parameter]

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\[SCRIPT_NAME].ps1 -[PRIMARY_PARAMETER] "[Example Value]" -[SECONDARY_PARAMETER] "[Example Value]"

.EXAMPLE
    .\[SCRIPT_NAME].ps1 -[PRIMARY_PARAMETER] "[Example Value]" -[SECONDARY_PARAMETER] "[Example Value]" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Template Metadata:
    - Template ID: PF-TEM-020
    - Template Type: Document Creation Script
    - Created: 2025-07-08
    - For: Creating PowerShell scripts that generate documents from templates
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$PRIMARY_PARAMETER,

    [Parameter(Mandatory=$false)]
    [string]$SECONDARY_PARAMETER = "",

    [Parameter(Mandatory=$false)]
    [string]$OPTIONAL_PARAMETER = "",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

# Import the common helpers
# STANDARD PATTERN: All file-creation scripts are in doc/process-framework/scripts/file-creation/
# Common-ScriptHelpers.psm1 is one level up at doc/process-framework/scripts/
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields (customize as needed)
$additionalMetadataFields = @{
    "[METADATA_FIELD_1]" = $PRIMARY_PARAMETER
    "[METADATA_FIELD_2]" = $SECONDARY_PARAMETER
}

# Prepare custom replacements (customize based on template needs)
# IMPORTANT: Use exact bracket notation like "[Placeholder Name]" - do NOT escape brackets
# The replacement keys must match exactly what appears in your template file
$customReplacements = @{
    "[TEMPLATE_PLACEHOLDER_1]" = $PRIMARY_PARAMETER
    "[TEMPLATE_PLACEHOLDER_2]" = if ($SECONDARY_PARAMETER -ne "") { $SECONDARY_PARAMETER } else { "[DEFAULT_VALUE]" }
    "[TEMPLATE_PLACEHOLDER_3]" = $OPTIONAL_PARAMETER
}

# Example replacements for common patterns:
# "[Feature Name]" = $FeatureName
# "[Description]" = if ($Description -ne "") { $Description } else { "Default description" }
# "[Date]" = Get-Date -Format "yyyy-MM-dd"
# "[Author]" = "AI Agent & Human Partner"
# "[NEXT_STEPS_SECTION]" = "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - EXTENSIVE CUSTOMIZATION REQUIRED 🚨🚨🚨`n`n⚠️  IMPORTANT: This script creates ONLY a structural template/framework.`n⚠️  The generated file is NOT a functional document until extensively customized.`n⚠️  AI agents MUST follow the referenced guide to properly customize the content.`n`n📖 MANDATORY CUSTOMIZATION GUIDE:`n   [path/to/guide.md]`n🎯 FOCUS AREAS: '[Specific Section]' section`n`n🚫 DO NOT use the generated file without proper customization!`n✅ The template provides structure - YOU provide the meaningful content."

# NEXT STEPS CUSTOMIZATION GUIDE:
# Replace [NEXT_STEPS_SECTION] with one of these patterns:
#
# Pattern 1: Mandatory Guide Reference (for complex processes)
# "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - EXTENSIVE CUSTOMIZATION REQUIRED 🚨🚨🚨`n`n⚠️  IMPORTANT: This script creates ONLY a structural template/framework.`n⚠️  The generated file is NOT a functional document until extensively customized.`n⚠️  AI agents MUST follow the referenced guide to properly customize the content.`n`n📖 MANDATORY CUSTOMIZATION GUIDE:`n   [path/to/guide.md]`n🎯 FOCUS AREAS: '[Specific Section]' section`n`n🎯 What the guide will teach you:`n   • [Key Learning Point 1]`n   • [Key Learning Point 2]`n`n🚫 DO NOT use the generated file without proper customization!`n✅ The template provides structure - YOU provide the meaningful content."
#
# Pattern 2: Simple Next Steps (for straightforward processes)
# "Next steps:`n1. [NEXT_STEP_1]`n2. [NEXT_STEP_2]`n3. [NEXT_STEP_3]"
#
# Pattern 3: No Next Steps (when opening in editor or self-explanatory)
# "" (empty string)

# Create the document using standardized process
try {
    # Get project root for dynamic path resolution
    $projectRoot = Get-ProjectRoot
    $templatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/[TEMPLATE_NAME].md"

    # Use DirectoryType for ID registry-based directory resolution (recommended)
    # Alternative: Use -OutputDirectory "[EXPLICIT_PATH]" for custom directory paths
    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "[ID_PREFIX]" -IdDescription "[DESCRIPTION_PATTERN]" -DocumentName $PRIMARY_PARAMETER -DirectoryType "[DIRECTORY_TYPE]" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Optional: Update related documentation (customize as needed)
    # Example: Update documentation maps, README files, etc.
    # [OPTIONAL_DOCUMENTATION_UPDATES]

    # Provide success details
    $details = @(
        "[DETAIL_1]: $PRIMARY_PARAMETER",
        "[DETAIL_2]: $SECONDARY_PARAMETER"
    )

    # Add conditional details
    if ($OPTIONAL_PARAMETER -ne "") {
        $details += "[OPTIONAL_DETAIL]: $OPTIONAL_PARAMETER"
    }

    # Add next steps if not opening in editor
    if (-not $OpenInEditor) {
        $details += @(
            "",
            "[NEXT_STEPS_SECTION]"
        )
    }

    Write-ProjectSuccess -Message "Created [DOCUMENT_TYPE] with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create [DOCUMENT_TYPE]: $($_.Exception.Message)" -ExitCode 1
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
   - Verify [NEXT_STEPS_SECTION] replacement displays correctly
   - Check that guide references or next steps appear as expected
   - Test with -OpenInEditor flag to ensure next steps are skipped

7. CLEANUP TEST:
   - Remove test documents after verification
   - Ensure no temporary files are left behind

EXAMPLE TEST COMMANDS:
# Basic test
./[SCRIPT_NAME].ps1 -[PRIMARY_PARAMETER] "Test [DOCUMENT_TYPE]" -[SECONDARY_PARAMETER] "Test" -Description "Test creation"

# Verify created document
Get-Content "[OUTPUT_PATH]/test-[document-type].md" | Select-Object -First 20

# Cleanup
Remove-Item "[OUTPUT_PATH]/test-[document-type].md" -Force
#>
