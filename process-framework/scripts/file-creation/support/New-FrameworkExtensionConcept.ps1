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

.PARAMETER Minimal
    Selects a slim concept template for small-scope creation extensions (single artifact).
    When set, -Type defaults to "Creation" if not specified. Mutually exclusive with
    -Type Modification and -Type Hybrid.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    New-FrameworkExtensionConcept.ps1 -ExtensionName "Architecture Framework" -ExtensionDescription "Comprehensive architecture design and review framework" -Type Creation

.EXAMPLE
    New-FrameworkExtensionConcept.ps1 -ExtensionName "Testing Framework" -ExtensionDescription "Automated testing infrastructure and processes" -Type Modification -ExtensionScope "Multi-component" -OpenInEditor

.EXAMPLE
    New-FrameworkExtensionConcept.ps1 -ExtensionName "Service Interface API Spec" -ExtensionDescription "Template variant for non-network API contracts" -Minimal

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - Template selection: Creation and Modification use dedicated templates; Hybrid uses the full template; -Minimal uses the slim creation template

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

    [Parameter(Mandatory=$false)]
    [ValidateSet("Creation", "Modification", "Hybrid")]
    [string]$Type,

    [Parameter(Mandatory=$false)]
    [switch]$Minimal,

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

# -Minimal validation: mutually exclusive with Modification/Hybrid; defaults Type to Creation
if ($Minimal) {
    if ($Type -and $Type -ne "Creation") {
        throw "-Minimal is only valid with -Type Creation (or omitting -Type). Got -Type $Type."
    }
    if (-not $Type) { $Type = "Creation" }
}
if (-not $Minimal -and -not $Type) {
    throw "-Type is required when -Minimal is not specified. Use -Type Creation|Modification|Hybrid."
}

# Phase 7 (2026-05-11): write to appdev/process-framework-central/proposals/ regardless of cwd;
# stamp project_id in frontmatter.
$projectId = $null
try {
    $cfg = Get-ProjectConfig
    if ($cfg.project_id) { $projectId = $cfg.project_id }
} catch {
    Write-Verbose "New-FrameworkExtensionConcept: could not read doc/project-config.json; project_id will be null."
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "extension_name"        = $ExtensionName
    "extension_description" = $ExtensionDescription
    "extension_scope"       = $ExtensionScope
    "project_id"            = $(if ($projectId) { $projectId } else { "null" })
}
if ($Minimal) {
    $additionalMetadataFields["mode"] = "minimal"
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

# Select template based on extension type. Phase 7: template paths resolved via configurable
# paths.process_framework (Get-ProcessFrameworkPath) so the same script works in both the
# appdev blueprint layout and rolled-out projects.
$processFrameworkDir = Get-ProcessFrameworkPath
$modeLabel = if ($Minimal) { "Minimal" } else { $Type }
$templatePath = if ($Minimal) {
    Join-Path -Path $processFrameworkDir -ChildPath "templates/support/framework-extension-concept-minimal-template.md"
} else {
    switch ($Type) {
        "Creation"     { Join-Path -Path $processFrameworkDir -ChildPath "templates/support/framework-extension-concept-creation-template.md" }
        "Modification" { Join-Path -Path $processFrameworkDir -ChildPath "templates/support/framework-extension-concept-modification-template.md" }
        "Hybrid"       { Join-Path -Path $processFrameworkDir -ChildPath "templates/support/framework-extension-concept-template.md" }
    }
}

Write-Verbose "Extension mode: $modeLabel — using template: $templatePath"

# Phase 7: write target is appdev central proposals/ (resolved via Get-CentralFrameworkPath
# from any cwd). PRJ-ID prefix on the filename per Phase 7.5 Open-content convention.
$outputDir = Join-Path -Path (Get-CentralFrameworkPath) -ChildPath "proposals"
$prjPrefix = if ($projectId) { "${projectId}_" } else { "" }
$kebabName = ConvertTo-KebabCase -InputString $ExtensionName
$customFileName = "${prjPrefix}${kebabName}.md"

# Create the document using standardized process
try {
    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-PRO" -IdDescription "Framework Extension Concept: ${ExtensionName}" -DocumentName $ExtensionName -OutputDirectory $outputDir -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $customFileName -OpenInEditor:$OpenInEditor

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
Get-Content "../../../../../../process-framework-central/proposals/test-framework-concept.md" | Select-Object -First 20

# Cleanup
Remove-Item "../../../../../../process-framework-central/proposals/test-framework-concept.md" -Force
#>
