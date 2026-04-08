# New-PrioritizationMatrix.ps1
# Creates a new Technical Debt Prioritization Matrix from template
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Technical Debt Prioritization Matrix document.

.DESCRIPTION
    This PowerShell script generates prioritization matrix documents by:
    - Generating a unique document ID (PD-TDA-XXX) automatically
    - Creating a properly formatted matrix document from template
    - Populating assessment reference, date, and item count
    - Updating the ID tracker in the central ID registry

    Used by the Technical Debt Assessment task (PF-TSK-023) Step 8 to create
    the impact vs. effort prioritization matrix for identified debt items.

.PARAMETER MatrixName
    Name/title of the prioritization matrix (e.g., "Q1 2026 Debt Prioritization")

.PARAMETER AssessmentId
    The PD-TDA-XXX ID of the source assessment. Links the matrix to its assessment.

.PARAMETER ItemCount
    Number of debt items being prioritized. Optional, defaults to placeholder.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor.

.EXAMPLE
    New-PrioritizationMatrix.ps1 -MatrixName "Q1 2026 Debt Prioritization" -AssessmentId "PD-TDA-001"

.EXAMPLE
    New-PrioritizationMatrix.ps1 -MatrixName "Pre-Release Prioritization" -AssessmentId "PD-TDA-002" -ItemCount 12

.NOTES
    Script Type: Document Creation Script
    Created: 2026-04-02
    For: Technical Debt Assessment task (PF-TSK-023)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$MatrixName,

    [Parameter(Mandatory = $false)]
    [string]$AssessmentId = "[PF-TDA-XXX]",

    [Parameter(Mandatory = $false)]
    [int]$ItemCount = 0,

    [Parameter(Mandatory = $false)]
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

$today = Get-Date -Format "yyyy-MM-dd"

# Prepare custom replacements
$customReplacements = @{
    "[Matrix Name]"               = $MatrixName
    "[Matrix Date]"               = $today
    "[PF-TDA-XXX]"                = $AssessmentId
    "[Number of debt items]"      = if ($ItemCount -gt 0) { "$ItemCount" } else { "[Number of debt items]" }
    "[Assessor]"                  = "AI Agent & Human Partner"
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "assessment_reference" = $AssessmentId
}

try {
    $documentId = New-StandardProjectDocument `
        -TemplatePath "process-framework/templates/cyclical/prioritization-matrix-template.md" `
        -IdPrefix "PD-TDA" `
        -IdDescription "Prioritization Matrix: $MatrixName" `
        -DocumentName $MatrixName `
        -OutputDirectory "doc/technical-debt/matrices" `
        -Replacements $customReplacements `
        -AdditionalMetadataFields $additionalMetadataFields `
        -OpenInEditor:$OpenInEditor

    $details = @(
        "Matrix Name: $MatrixName",
        "Assessment Reference: $AssessmentId"
    )

    if ($ItemCount -gt 0) {
        $details += "Items to Prioritize: $ItemCount"
    }

    $details += @(
        "",
        "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - CUSTOMIZATION REQUIRED 🚨🚨🚨",
        "",
        "⚠️  Populate the Priority Quadrant tables with debt items from the assessment.",
        "⚠️  Complete the Priority Summary and Implementation Roadmap sections.",
        "⚠️  Review Risk Analysis and Dependencies.",
        "",
        "📖 REFERENCE:",
        "process-framework/guides/cyclical/prioritization-guide.md",
        "🎯 FOCUS: Impact vs. Effort analysis methodology"
    )

    Write-ProjectSuccess -Message "Created prioritization matrix with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create prioritization matrix: $($_.Exception.Message)" -ExitCode 1
}
