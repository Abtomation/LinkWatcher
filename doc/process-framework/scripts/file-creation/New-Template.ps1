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
    The directory where the template should be saved (defaults to templates directory)

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    # From PowerShell (from project root)
    & '.\doc\process-framework\scripts\file-creation\New-Template.ps1' -TemplateName 'Feature Request' -TemplateDescription 'Template for creating feature requests' -DocumentPrefix 'PF-REQ' -DocumentCategory 'Request'

.EXAMPLE
    # From PowerShell with editor opening
    & '.\doc\process-framework\scripts\file-creation\New-Template.ps1' -TemplateName "Architecture Overview" -TemplateDescription "Template for architecture documentation" -DocumentPrefix "PD-ARC" -DocumentCategory "Architecture" -OpenInEditor

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
    [string]$OutputDirectory = "doc\process-framework\templates\templates",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Environment]::SetEnvironmentVariable('POWERSHELL_FILE_ENCODING', 'UTF8')
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Get current date in YYYY-MM-DD format
$currentDate = Get-Date -Format "yyyy-MM-dd"

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "template_for"              = $DocumentCategory
    "creates_document_type"     = "Process Framework"
    "creates_document_category" = $DocumentCategory
    "creates_document_prefix"   = $DocumentPrefix
    "creates_document_version"  = "1.0"
    "usage_context"             = "Process Framework - $DocumentCategory Creation"
    "description"               = $TemplateDescription
}

# Prepare custom replacements
$customReplacements = @{
    "[Template Name]"                                                                                                                                                    = $TemplateName
    "[Brief description of what this template is for and when it should be used. Explain the type of document this template will generate and its role in the project.]" = $TemplateDescription
    "[Document type - e.g., Process Framework, Product Documentation]"                                                                                                   = "Process Framework"
    "[Specific category - e.g., Task, Guide, Reference]"                                                                                                                 = $DocumentCategory
    "[Required Section 1]"                                                                                                                                               = "Overview"
    "[Description of what should go in this section]"                                                                                                                    = "Provide a concise overview of the $DocumentCategory being documented."
    "[Required Section 2]"                                                                                                                                               = "Content"
    "[Description of what should go in this section and when it should be included]"                                                                                     = "The main content of the $DocumentCategory document."
    "[Optional Section 1]"                                                                                                                                               = "Additional Information"
    "[Optional Section 2]"                                                                                                                                               = "References"
    "**Last Updated:** 2025-07-15"                                                                                                                                       = "**Last Updated:** $currentDate"
}

# Create the template using standardized process
try {
    $templateId = New-StandardProjectDocument -TemplatePath "doc\process-framework\templates\templates\template-base-template.md" -IdPrefix "PF-TEM" -IdDescription "$TemplateName template" -DocumentName "$($TemplateName.ToLower().Replace(' ', '-'))-template" -OutputDirectory $OutputDirectory -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Template Name: $TemplateName",
        "Template Description: $TemplateDescription",
        "Document Prefix: $DocumentPrefix",
        "Document Category: $DocumentCategory",
        "",
        "Template saved to: $OutputDirectory\$($TemplateName.ToLower().Replace(' ', '-'))-template.md"
    )

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
            "   doc\process-framework\guides\guides\template-development-guide.md",
            "🎯 FOCUS AREAS: 'Template Customization Standards' section",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content."
        )
    }

    Write-ProjectSuccess -Message "Created template with ID: $templateId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create template: $($_.Exception.Message)" -ExitCode 1
}
