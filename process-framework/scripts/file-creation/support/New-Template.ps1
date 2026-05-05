#requires -version 5.0

<#
.SYNOPSIS
    Creates a new template document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates template documents by:
    - Generating a unique document ID (PF-TEM-XXX)
    - Creating a properly formatted template file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template structure for document creation

.PARAMETER TemplateName
    The name of the template (e.g., "Task", "Guide", "API Reference")

.PARAMETER TemplateDescription
    Brief description of what the template is for

.PARAMETER DocumentPrefix
    The document prefix that will be used for documents created from this template (e.g., "PF-TSK", "PF-GDE")

.PARAMETER DocumentCategory
    The category of documents that will be created from this template (e.g., "Task", "Guide", "Reference")

.PARAMETER OutputDirectory
    The subdirectory under process-framework/templates/ where the template should be saved (e.g., "03-testing", "support"). Short names are auto-prefixed with process-framework/templates/. Defaults to process-framework/templates/.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    # From PowerShell (from project root)
    & 'process-framework/scripts/file-creation/New-Template.ps1' -TemplateName 'Feature Request' -TemplateDescription 'Template for creating feature requests' -DocumentPrefix 'PF-REQ' -DocumentCategory 'Request'

.EXAMPLE
    # From PowerShell with editor opening
    & 'process-framework/scripts/file-creation/New-Template.ps1' -TemplateName "Architecture Overview" -TemplateDescription "Template for architecture documentation" -DocumentPrefix "PD-ARC" -DocumentCategory "Architecture" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Template Metadata:
    - Template ID: PF-TEM-024
    - Template Type: Document Creation Script
    - Created: 2025-07-15
    - For: Creating template documents
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TemplateName,

    [Parameter(Mandatory = $true)]
    [string]$TemplateDescription,

    [Parameter(Mandatory = $true)]
    [string]$DocumentPrefix,

    [Parameter(Mandatory = $true)]
    [string]$DocumentCategory,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "process-framework/templates",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Environment]::SetEnvironmentVariable('POWERSHELL_FILE_ENCODING', 'UTF8')
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'

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

# Get current date in YYYY-MM-DD format
$currentDate = Get-Date -Format "yyyy-MM-dd"

# Infer document type from prefix using domain-config.json
$domainConfig = Get-DomainConfig
$prefixFamily = ($DocumentPrefix -split '-')[0]
$documentType = if ($domainConfig.document_type_prefixes.$prefixFamily) {
    $domainConfig.document_type_prefixes.$prefixFamily
} else {
    "Process Framework"
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "template_for"              = $DocumentCategory
    "creates_document_type"     = $documentType
    "creates_document_category" = $DocumentCategory
    "creates_document_prefix"   = $DocumentPrefix
    "creates_document_version"  = "1.0"
    "usage_context"             = "$documentType - $DocumentCategory Creation"
    "description"               = $TemplateDescription
}

# Prepare custom replacements
$customReplacements = @{
    "[Template Name]"                                                                                                                                                    = $TemplateName
    "[Brief description of what this template is for and when it should be used. Explain the type of document this template will generate and its role in the project.]" = $TemplateDescription
    "[Document type - e.g., Process Framework, Product Documentation]"                                                                                                   = $documentType
    "[Specific category - e.g., Task, Guide, Reference]"                                                                                                                 = $DocumentCategory
    "[Required Section 1]"                                                                                                                                               = "Overview"
    "[Description of what should go in this section]"                                                                                                                    = "Provide a concise overview of the $DocumentCategory being documented."
    "[Required Section 2]"                                                                                                                                               = "Content"
    "[Description of what should go in this section and when it should be included]"                                                                                     = "The main content of the $DocumentCategory document."
    "[Optional Section 1]"                                                                                                                                               = "Additional Information"
    "[Optional Section 2]"                                                                                                                                               = "References"
    "**Last Updated:** 2025-07-15"                                                                                                                                       = "**Last Updated:** $currentDate"
}

# IMP-439: Normalize OutputDirectory to be relative to process-framework/templates/
$templateBase = "process-framework/templates"
if ($OutputDirectory -and -not $OutputDirectory.StartsWith($templateBase)) {
    $OutputDirectory = "$templateBase/$OutputDirectory"
}

# Create the template using standardized process
try {
    # IMP-407: Auto-append "-template" suffix with double-suffix guard
    $templateDocName = $TemplateName.ToLower().Replace(' ', '-')
    if ($templateDocName -notmatch '-template$') { $templateDocName = "$templateDocName-template" }
    $templateId = New-StandardProjectDocument -TemplatePath "process-framework/templates/support/template-base-template.md" -IdPrefix "PF-TEM" -IdDescription "$TemplateName template" -DocumentName $templateDocName -OutputDirectory $OutputDirectory -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Template Name: $TemplateName",
        "Template Description: $TemplateDescription",
        "Document Prefix: $DocumentPrefix",
        "Document Category: $DocumentCategory",
        "",
        "Template saved to: $OutputDirectory\$templateDocName.md"
    )

    # Add next steps if not opening in editor
    if (-not $OpenInEditor) {
        $details += "Customization required — see process-framework/guides/support/template-development-guide.md"
    }

    # Auto-append entry to PF-documentation-map.md under the correct Templates section
    if ($templateId -or $WhatIfPreference) {
        $projectRoot = Get-ProjectRoot
        $docMapPath = Join-Path -Path $projectRoot -ChildPath "process-framework/PF-documentation-map.md"

        # Extract subdirectory from OutputDirectory (last path segment)
        $subDir = Split-Path -Leaf $OutputDirectory

        # Derive section header from subdirectory
        if ($subDir -match '^(\d{2})-(.+)$') {
            $num = $Matches[1]
            $name = (Get-Culture).TextInfo.ToTitleCase($Matches[2])
            $sectionHeader = "#### $num - $name Templates"
        }
        else {
            $name = (Get-Culture).TextInfo.ToTitleCase($subDir)
            $sectionHeader = "#### $name Templates"
        }

        # IMP-407: Reuse guarded name from above
        $fileName = "$templateDocName.md"
        $relativePath = "templates/$subDir/$fileName"
        $entryLine = "- [Template: $TemplateName]($relativePath) - $TemplateDescription"

        $updated = Add-DocumentationMapEntry -DocMapPath $docMapPath -SectionHeader $sectionHeader -EntryLine $entryLine -CallerCmdlet $PSCmdlet
        if ($updated) {
            $details += "Documentation Map: Updated (section: $sectionHeader)"
        }
    }

    Write-ProjectSuccess -Message "Created template with ID: $templateId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create template: $($_.Exception.Message)" -ExitCode 1
}
