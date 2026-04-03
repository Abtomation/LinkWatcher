# New-Handbook.ps1
# Creates a new user handbook with an automatically assigned PD-UGD ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new user handbook document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates user handbook documents by:
    - Generating a unique document ID (PD-UGD-XXX)
    - Creating a properly formatted handbook file in doc/user/handbooks/
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for user-facing documentation

.PARAMETER HandbookName
    The display name for the handbook (e.g., "Multi-Project Setup", "File Type Quick Fix")

.PARAMETER Description
    A brief description of what the handbook covers

.PARAMETER Category
    Optional category for the handbook. Valid values: setup, usage, troubleshooting, configuration, reference.
    Defaults to "usage".

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-Handbook.ps1 -HandbookName "Multi-Project Setup" -Description "Guide for using LinkWatcher across multiple projects"

.EXAMPLE
    .\New-Handbook.ps1 -HandbookName "File Type Quick Fix" -Description "Quick solutions for file type monitoring" -Category "troubleshooting"

.EXAMPLE
    .\New-Handbook.ps1 -HandbookName "Custom Parsers" -Description "How to add custom file parsers" -Category "configuration" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates files in doc/user/handbooks/
    - Uses PD-UGD prefix from PD-id-registry.json
    - Template: process-framework/templates/07-deployment/handbook-template.md (PF-TEM-065)
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [ValidateLength(3, 100)]
    [string]$HandbookName,

    [Parameter(Mandatory=$true)]
    [ValidateLength(10, 500)]
    [string]$Description,

    [Parameter(Mandatory=$false)]
    [ValidateSet("setup", "usage", "troubleshooting", "configuration", "reference")]
    [string]$Category = "usage",

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

# Prepare additional metadata fields for frontmatter
$additionalMetadataFields = @{
    "handbook_name"     = $HandbookName
    "handbook_category" = $Category
}

# Prepare custom replacements matching template placeholders
$customReplacements = @{
    "[Handbook Name]" = $HandbookName
    "[Category]"      = $Category
}

# Create the document using standardized process
try {
    $projectRoot = Get-ProjectRoot
    $templatePath = Join-Path $projectRoot "process-framework/templates/07-deployment/handbook-template.md"

    $documentId = New-StandardProjectDocument `
        -TemplatePath $templatePath `
        -IdPrefix "PD-UGD" `
        -IdDescription "User Handbook: $HandbookName" `
        -DocumentName $HandbookName `
        -DirectoryType "handbooks" `
        -Replacements $customReplacements `
        -AdditionalMetadataFields $additionalMetadataFields `
        -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Handbook: $HandbookName",
        "Category: $Category",
        "Description: $Description"
    )

    if (-not $OpenInEditor) {
        $details += @(
            "",
            "Next steps:",
            "1. Open the generated file and customize all placeholder sections",
            "2. Remove any sections not applicable to this handbook",
            "3. Add code examples, configuration snippets, and troubleshooting entries",
            "4. Update README.md documentation table if this handbook should be listed there"
        )
    }

    Write-ProjectSuccess -Message "Created user handbook with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create user handbook: $($_.Exception.Message)" -ExitCode 1
}
