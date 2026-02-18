# New-TechnicalDebtAssessment.ps1
# Creates a new Technical Debt Assessment with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Technical Debt Assessment document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Technical Debt Assessment documents by:
    - Generating a unique document ID (PF-TDA-XXX)
    - Creating a properly formatted assessment document
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for systematic technical debt evaluation

.PARAMETER AssessmentName
    Name/title of the technical debt assessment (e.g., "Q4 2025 Codebase Assessment")

.PARAMETER Scope
    Scope of the assessment (e.g., "Full Codebase", "Authentication Module", "UI Components")

.PARAMETER AssessmentType
    Type of assessment being conducted (e.g., "Scheduled", "Pre-Release", "Post-Feature")

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    ../../../../../../assessments/New-TechnicalDebtAssessment.ps1 -AssessmentName "Q4 2025 Codebase Assessment" -Scope "Full Codebase" -AssessmentType "Scheduled"

.EXAMPLE
    ../../../../../../assessments/New-TechnicalDebtAssessment.ps1 -AssessmentName "Pre-Release Debt Review" -Scope "Core Features" -AssessmentType "Pre-Release" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Script Metadata:
    - Script Type: Document Creation Script
    - Created: 2025-07-24
    - For: Creating Technical Debt Assessment documents
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$AssessmentName,

    [Parameter(Mandatory=$false)]
    [string]$Scope = "Full Codebase",

    [Parameter(Mandatory=$false)]
    [string]$AssessmentType = "Scheduled",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "assessment_scope" = ConvertTo-KebabCase -InputString $Scope
    "assessment_type" = ConvertTo-KebabCase -InputString $AssessmentType
}

# Prepare custom replacements
$customReplacements = @{
    "[Assessment Name]" = $AssessmentName
    "[Assessment Scope]" = $Scope
    "[Assessment Type]" = $AssessmentType
    "[Assessment Date]" = Get-Date -Format "yyyy-MM-dd"
    "[Assessor]" = "AI Agent & Human Partner"
}

# Create the document using standardized process
try {
    $documentId = New-StandardProjectDocument -TemplatePath "../../assessments/../../../assessments/doc/process-framework/templates/templates/technical-debt-assessment-template.md" -IdPrefix "PF-TDA" -IdDescription "Technical Debt Assessment: $AssessmentName" -DocumentName $AssessmentName -DirectoryType "assessments" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Assessment Name: $AssessmentName",
        "Scope: $Scope",
        "Type: $AssessmentType"
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
            "   doc/process-framework/guides/guides/assessment-criteria-guide.md",
            "🎯 FOCUS AREAS: 'Technical Debt Assessment Process' section",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content."
        )
    }

    Write-ProjectSuccess -Message "Created Technical Debt Assessment with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Technical Debt Assessment: $($_.Exception.Message)" -ExitCode 1
}
