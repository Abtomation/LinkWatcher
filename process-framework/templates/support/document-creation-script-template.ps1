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
    - Updated: 2026-06-15 (PF-PRO-043 Option 2 — models the New-FrameworkDocument wrapper pattern)
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
# STANDARD PATTERN: All file-creation scripts are in process-framework/scripts/file-creation/
# Common-ScriptHelpers.psm1 is one level up at process-framework/scripts/
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# PF-PRO-043 Option 2: standard init, soak opt-in, the New-StandardProjectDocument call, the
# try/catch, and the create-failure error path are all owned by New-FrameworkDocument. This
# script keeps only its param block (above), the per-type data below, and its own success report.
# (New-FrameworkDocument lives in Common-ScriptHelpers/DocumentManagement.psm1 and is exported
# through the umbrella imported above — no extra import needed.)

# Prepare additional metadata fields (customize as needed).
# Build conditionally so empty optional fields are OMITTED (keeps frontmatter clean).
$additionalMetadataFields = @{
    "[METADATA_FIELD_1]" = $PRIMARY_PARAMETER
}
if ($SECONDARY_PARAMETER -ne "") { $additionalMetadataFields["[METADATA_FIELD_2]"] = $SECONDARY_PARAMETER }

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

# Success-report detail lines (per-type content — the script owns its own report).
$details = @("[DETAIL_1]: $PRIMARY_PARAMETER")
if ($SECONDARY_PARAMETER -ne "") { $details += "[DETAIL_2]: $SECONDARY_PARAMETER" }
if ($OPTIONAL_PARAMETER -ne "")  { $details += "[OPTIONAL_DETAIL]: $OPTIONAL_PARAMETER" }
# Next-step hint when not opening in editor. Keep it terse — a single-line pointer to the
# customization guide (PF-IMP-584/700); multi-line emoji banners train agents to skim past
# real warnings. Pattern: "Customization required — see [path/to/guide.md]".
if (-not $OpenInEditor) { $details += "[NEXT_STEPS_SECTION]" }

# Create via the shared wrapper. Use -DirectoryType for ID-registry-based directory resolution
# (recommended), OR -OutputDirectory "[EXPLICIT_PATH]" for a custom path. -Label sets the noun
# in the failure message ("Failed to create [DOCUMENT_TYPE]: ...").
$documentId = New-FrameworkDocument `
    -TemplatePath (Join-Path (Get-ProcessFrameworkPath) "templates/[SUBFOLDER]/[TEMPLATE_NAME].md") `
    -IdPrefix "[ID_PREFIX]" -IdDescription "[DESCRIPTION_PATTERN]" -DocumentName $PRIMARY_PARAMETER `
    -DirectoryType "[DIRECTORY_TYPE]" `
    -Replacements $customReplacements -Metadata $additionalMetadataFields `
    -Label "[DOCUMENT_TYPE]" -OpenInEditor:$OpenInEditor

# TIER-3 ONLY: if this type has bespoke post-creation tracking writes (documentation-map append,
# state-file row, custom tracking-table surgery), do them HERE, inline, using $documentId — the
# wrapper returns it for exactly this. When a write needs the created file's PATH, add -PassThru
# to the call above and read Id/Path/RelativePath off the returned object instead — never
# re-derive the filename from the document name (PF-IMP-1678). See New-ArchitectureDecision.ps1
# for the canonical pattern.
# [OPTIONAL_POST_CREATION_TRACKING]

Write-ProjectSuccess -Message "Created [DOCUMENT_TYPE] with ID: $documentId" -Details $details

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
