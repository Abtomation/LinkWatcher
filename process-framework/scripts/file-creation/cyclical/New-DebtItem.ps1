# New-DebtItem.ps1
# Creates a new Technical Debt Item record with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Technical Debt Item record with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Technical Debt Item records by:
    - Generating a unique document ID (PD-TDI-XXX)
    - Creating a properly formatted debt item record
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for documenting individual debt items

.PARAMETER ItemTitle
    Title/name of the technical debt item (e.g., "Outdated Authentication Library", "Duplicated Validation Logic")

.PARAMETER Dim
    Development dimension of the debt item. Must be one of the 11 canonical dimension codes:
    AC (Architectural Consistency), CQ (Code Quality), ID (Integration Dependencies),
    DA (Documentation Alignment), EM (Extensibility & Maintainability), SE (Security & Data Protection),
    PE (Performance & Scalability), OB (Observability), UX (Accessibility / UX Compliance),
    DI (Data Integrity), TST (Testing). Run `Update-TechDebt.ps1 -ListDims` to see the list.

.PARAMETER Priority
    Initial priority assessment (e.g., "High", "Medium", "Low", "Critical")

.PARAMETER Location
    Location/component where the debt exists (e.g., "lib/auth/", "UI Components", "Database Layer")

.PARAMETER AssessmentId
    ID of the assessment that identified this debt item (e.g., "PD-TDA-001"). Optional for manually identified items.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    New-DebtItem.ps1 -ItemTitle "Outdated Authentication Library" -Dim "SE" -Priority "High" -Location "lib/auth"

.EXAMPLE
    New-DebtItem.ps1 -ItemTitle "Duplicated Validation Logic" -Dim "CQ" -Priority "Medium" -Location "UI Components" -OpenInEditor

.EXAMPLE
    New-DebtItem.ps1 -ItemTitle "Missing Error Handling" -Dim "CQ" -Priority "High" -Location "lib/services" -AssessmentId "PD-TDA-001"

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Script Metadata:
    - Script Type: Document Creation Script
    - Created: 2025-07-24
    - For: Creating Technical Debt Item records
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ItemTitle,

    [Parameter(Mandatory = $false)]
    [ValidateSet("AC","CQ","ID","DA","EM","SE","PE","OB","UX","DI","TST")]
    [string]$Dim = "CQ",

    [Parameter(Mandatory = $false)]
    [string]$Priority = "Medium",

    [Parameter(Mandatory = $false)]
    [string]$Location = "TBD",

    [Parameter(Mandatory = $false)]
    [string]$AssessmentId = "",

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
# its param block (above), the debt-item-specific data, and the success report.

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "debt_dim"      = $Dim
    "debt_priority" = ConvertTo-KebabCase -InputString $Priority
    "debt_location" = ConvertTo-KebabCase -InputString $Location
}

# Prepare custom replacements
$customReplacements = @{
    "[Debt Item Title]"                         = $ItemTitle
    "[Dimension]"                               = $Dim
    "[Initial Priority]"                        = $Priority
    "[Location/Component]"                      = $Location
    "[Identification Date]"                     = Get-Date -Format "yyyy-MM-dd"
    "[Identified By]"                           = "AI Agent & Human Partner"
    "[Assessment ID that identified this item]" = if ($AssessmentId) { $AssessmentId } else { "Manual identification - no assessment" }
}

# Create the document using standardized process
$templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/cyclical/debt-item-template.md"
$documentId = New-FrameworkDocument -TemplatePath $templatePath -IdPrefix "PD-TDI" -IdDescription "Technical Debt Item: $ItemTitle" -DocumentName $ItemTitle -DirectoryType "debt-items" -Replacements $customReplacements -Metadata $additionalMetadataFields -Label "Technical Debt Item" -OpenInEditor:$OpenInEditor

# Provide success details
$details = @(
    "Item Title: $ItemTitle",
    "Dimension: $Dim",
    "Priority: $Priority",
    "Location: $Location",
    "",
    "🤖 AUTOMATION AVAILABLE:",
    "To automatically add this item to technical-debt-tracking.md, run:",
    "process-framework/scripts/update/Update-TechDebt.ps1 -Add -Description '$ItemTitle' -Dims '$Dim' -Location '$Location' -Priority '$Priority' -EstimatedEffort '[SPECIFY_EFFORT]' -DebtItemId '$documentId' -AssessmentId '$AssessmentId' -Confirm:`$false",
    "",
    "Manual steps (if not using automation):",
    "1. Complete the debt item details using the provided template",
    "2. Assess impact and effort required for remediation",
    "3. Link to related assessment using the assessment ID",
    "4. Update technical-debt-tracking.md with this item"
)

# Add next steps if not opening in editor
if (-not $OpenInEditor) {
    $details += @(
        "Customization required — apply the technical-debt-assessment craft skill (.claude/skills/technical-debt-assessment/references/debt-item-creation.md)",
        "",
        "To edit the debt item:",
        "code `"$(Join-Path $PWD.Path "doc/technical-debt/debt-items")/$documentId-*.md`""
    )
}

Write-ProjectSuccess -Message "Created Technical Debt Item with ID: $documentId" -Details $details
