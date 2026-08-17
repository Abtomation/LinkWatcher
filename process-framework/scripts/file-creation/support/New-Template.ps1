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
    The subdirectory under process-framework/templates/ where the template should be saved. Required. Must be one of the 10 known template subdirs: 00-setup, 01-planning, 02-design, 03-testing, 04-implementation, 05-validation, 06-maintenance, 07-deployment, cyclical, support.

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

    [Parameter(Mandatory = $true)]
    [ValidateSet('00-setup','01-planning','02-design','03-testing','04-implementation','05-validation','06-maintenance','07-deployment','cyclical','support')]
    [string]$OutputDirectory,

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

# Init, soak opt-in, the New-StandardProjectDocument call, try/catch, and the error report are
# owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This script keeps only
# its param block (above), the template-specific data, and the success report.

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

# IMP-407: Auto-append "-template" suffix with double-suffix guard.
# Slug via the canonical helper from Common-ScriptHelpers/Naming.psm1 (PF-IMP-008).
$templateDocName = ConvertTo-FeatureSlug -Name $TemplateName -Convention 'kebab-case'
if ($templateDocName -notmatch '-template$') { $templateDocName = "$templateDocName-template" }

# P-12a (PF-PRO-068): the shipped-pool family comes from the workspace's declared
# artifact_prefix ('PF' at appdev, 'FB' at FB); a leaf role throws by contract.
$artifactFamily = Get-ArtifactPrefix

# Normalized onto the standard creation path (P-12a rider, owner-directed): the write target
# resolves through the registry chain — the TEM pool's "main" directory type
# ("process-framework/templates") plus -Subdirectory — the IMP-568 shape New-Guide uses.
# This retires the interim call-site Get-BlueprintPath retarget (Session 7) and the absolute
# -OutputDirectory that bypassed registry resolution. Producer-face correctness of
# registry-resolved writes after the Session F cutover is owned by the registry-resolution
# face decision (option (iii), owner-decided 2026-08-09), which fixes ALL -DirectoryType
# mint sites in one place rather than per call site.
# The template READ deliberately stays on Get-ProcessFrameworkPath: the base template is code
# this session runs against, not something it ships.
# PF-documentation-map.md is generated from each artifact's `description:` frontmatter
# by Build-DocumentationMap.ps1 (PF-PRO-037) — no per-creation append needed.
$templateResult = New-FrameworkDocument `
    -TemplatePath (Join-Path (Get-ProcessFrameworkPath) "templates/support/template-base-template.md") `
    -IdPrefix "$artifactFamily-TEM" -IdDescription "$TemplateName template" -DocumentName $templateDocName `
    -DirectoryType "main" -Subdirectory $OutputDirectory `
    -Replacements $customReplacements -Metadata $additionalMetadataFields `
    -Label "template" -OpenInEditor:$OpenInEditor -PassThru
$templateId = $templateResult.Id

# Provide success details
$details = @(
    "Template Name: $TemplateName",
    "Template Description: $TemplateDescription",
    "Document Prefix: $DocumentPrefix",
    "Document Category: $DocumentCategory",
    "",
    "Template saved to: $($templateResult.Path)"
)

# Add next steps if not opening in editor
if (-not $OpenInEditor) {
    $details += "Customization required — see .claude/skills/template-development/SKILL.md"
}

Write-ProjectSuccess -Message "Created template with ID: $templateId" -Details $details
