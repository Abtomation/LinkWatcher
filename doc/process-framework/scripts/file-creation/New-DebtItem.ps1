# New-DebtItem.ps1
# Creates a new Technical Debt Item record with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Technical Debt Item record with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Technical Debt Item records by:
    - Generating a unique document ID (PF-TDI-XXX)
    - Creating a properly formatted debt item record
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for documenting individual debt items

.PARAMETER ItemTitle
    Title/name of the technical debt item (e.g., "Outdated Authentication Library", "Duplicated Validation Logic")

.PARAMETER Category
    Category of the debt item (e.g., "Code Quality", "Security", "Performance", "Architecture", "Documentation")

.PARAMETER Priority
    Initial priority assessment (e.g., "High", "Medium", "Low", "Critical")

.PARAMETER Location
    Location/component where the debt exists (e.g., "lib/auth/", "UI Components", "Database Layer")

.PARAMETER AssessmentId
    ID of the assessment that identified this debt item (e.g., "PF-TDA-001"). Optional for manually identified items.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    ../../../../../../../../../../../assessments/New-DebtItem.ps1 -ItemTitle "Outdated Authentication Library" -Category "Security" -Priority "High" -Location "lib/auth/"

.EXAMPLE
    ../../../../../../../../../../../assessments/New-DebtItem.ps1 -ItemTitle "Duplicated Validation Logic" -Category "Code Quality" -Priority "Medium" -Location "UI Components" -OpenInEditor

.EXAMPLE
    ../../../../../../../../../../../assessments/New-DebtItem.ps1 -ItemTitle "Missing Error Handling" -Category "Code Quality" -Priority "High" -Location "lib/services/" -AssessmentId "PF-TDA-001"

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
    [string]$Category = "Code Quality",

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
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "debt_category" = ConvertTo-KebabCase -InputString $Category
    "debt_priority" = ConvertTo-KebabCase -InputString $Priority
    "debt_location" = ConvertTo-KebabCase -InputString $Location
}

# Prepare custom replacements
$customReplacements = @{
    "[Debt Item Title]"                         = $ItemTitle
    "[Debt Category]"                           = $Category
    "[Initial Priority]"                        = $Priority
    "[Location/Component]"                      = $Location
    "[Identification Date]"                     = Get-Date -Format "yyyy-MM-dd"
    "[Identified By]"                           = "AI Agent & Human Partner"
    "[Assessment ID that identified this item]" = if ($AssessmentId) { $AssessmentId } else { "Manual identification - no assessment" }
}

# Create the document using standardized process
try {
    $projectRoot = Get-ProjectRoot
    $templatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/debt-item-template.md"
    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-TDI" -IdDescription "Technical Debt Item: $ItemTitle" -DocumentName $ItemTitle -DirectoryType "debt-items" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Item Title: $ItemTitle",
        "Category: $Category",
        "Priority: $Priority",
        "Location: $Location",
        "",
        "🤖 AUTOMATION AVAILABLE:",
        "To automatically add this item to technical-debt-tracking.md, run:",
        ".\doc\process-framework\scripts\Update-TechnicalDebtTracking.ps1 -Operation 'Add' -Description '$ItemTitle' -Category '$Category' -Location '$Location' -Priority '$Priority' -EstimatedEffort '[SPECIFY_EFFORT]' -DebtItemId '$documentId' -AssessmentId '$AssessmentId'",
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
            "",
            "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - EXTENSIVE CUSTOMIZATION REQUIRED 🚨🚨🚨",
            "",
            "⚠️  IMPORTANT: This script creates ONLY a structural template/framework.",
            "⚠️  The generated file is NOT a functional document until extensively customized.",
            "⚠️  AI agents MUST follow the referenced guide to properly customize the content.",
            "",
            "📖 MANDATORY CUSTOMIZATION GUIDE:",
            "   doc/process-framework/guides/guides/debt-item-creation-guide.md",
            "🎯 FOCUS AREAS: 'Step-by-Step Instructions' and 'Quality Assurance' sections",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content.",
            "",
            "To edit the debt item:",
            "code `"$(Join-Path $PWD.Path "doc/process-framework/assessments/technical-debt/debt-items")/$documentId-*.md`""
        )
    }

    Write-ProjectSuccess -Message "Created Technical Debt Item with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Technical Debt Item: $($_.Exception.Message)" -ExitCode 1
}
