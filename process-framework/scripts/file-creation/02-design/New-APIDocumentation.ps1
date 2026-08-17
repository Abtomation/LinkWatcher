# New-APIDocumentation.ps1
# Creates a new API Documentation document from template
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new user-facing API documentation document.

.DESCRIPTION
    This PowerShell script generates API documentation documents by:
    - Generating a unique document ID (PD-API-XXX) automatically
    - Creating the file in doc/technical/api/documentation/
    - Populating API name, version, and audience
    - Updating the ID tracker in the central ID registry

    Used by the API Design task (PF-TSK-020) to create developer-facing
    API documentation that complements API specifications and data models.

.PARAMETER APIName
    Name of the API being documented (e.g., "Link Validation API", "User Management API")

.PARAMETER APIVersion
    Version of the API this documentation covers. Defaults to "v1".

.PARAMETER TargetAudience
    Primary audience for the documentation. Defaults to "Developers".

.PARAMETER Description
    Optional brief description of what the API provides.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor.

.EXAMPLE
    New-APIDocumentation.ps1 -APIName "Link Validation API"

    Creates link-validation-api.md in doc/technical/api/documentation/

.EXAMPLE
    New-APIDocumentation.ps1 -APIName "User Management API" -APIVersion "v2" -TargetAudience "Partners" -Description "User lifecycle management endpoints"

.NOTES
    Script Type: Document Creation Script
    Created: 2026-04-02
    For: API Design task (PF-TSK-020)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$APIName,

    [Parameter(Mandatory = $false)]
    [string]$APIVersion = "v1",

    [Parameter(Mandatory = $false)]
    [string]$TargetAudience = "Developers",

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Init, soak opt-in, the New-StandardProjectDocument call, try/catch, and the error report are
# owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This script keeps only
# its param block (above), the API-documentation-specific data, and the success report.

# Prepare custom replacements
$customReplacements = @{
    "[API Name]"                          = $APIName
    "API Documentation Template Template" = "$APIName - Developer Documentation"
    "[API version]"                       = $APIVersion
    "[Current API version]"               = $APIVersion
    "[Target audience - developers, integrators, etc.]" = $TargetAudience
    "[Primary audience - developers, partners, internal teams]" = $TargetAudience
}

if ($Description -ne "") {
    $customReplacements["[Brief description of what this API provides]"] = $Description
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "api_version"     = $APIVersion
    "target_audience" = $TargetAudience
    description       = "API documentation for $APIName (v$APIVersion)"
}

$documentId = New-FrameworkDocument `
    -TemplatePath (Join-Path (Get-ProcessFrameworkPath) "templates/02-design/api-documentation-template.md") `
    -IdPrefix "PD-API" `
    -IdDescription "API Documentation: $APIName" `
    -DocumentName $APIName `
    -DirectoryType "documentation" `
    -Replacements $customReplacements `
    -Metadata $additionalMetadataFields `
    -Label "API documentation" `
    -OpenInEditor:$OpenInEditor

$details = @(
    "API Name: $APIName",
    "API Version: $APIVersion",
    "Target Audience: $TargetAudience"
)

if ($Description -ne "") {
    $details += "Description: $Description"
}

$details += "Customization required — apply the api-design craft skill (.claude/skills/api-design/), activated by the API Design task's Check Recommended Skills step"

Write-ProjectSuccess -Message "Created API documentation with ID: $documentId" -Details $details
