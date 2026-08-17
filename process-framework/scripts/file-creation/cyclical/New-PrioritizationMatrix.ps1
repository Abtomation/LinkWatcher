# New-PrioritizationMatrix.ps1
# Creates a new Technical Debt Prioritization Matrix from template
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Technical Debt Prioritization Matrix document.

.DESCRIPTION
    This PowerShell script generates prioritization matrix documents by:
    - Generating a unique document ID (PD-TDM-XXX) automatically
    - Creating a properly formatted matrix document from template
    - Populating assessment reference, date, and item count
    - Updating the ID tracker in the central ID registry

    Used by the Technical Debt Assessment task (PF-TSK-023)'s prioritization step to create
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
    [string]$AssessmentId = "[PD-TDA-XXX]",

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

# Init, soak opt-in, the New-StandardProjectDocument call, try/catch, and the error report are
# owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This script keeps only
# its param block (above), the matrix-specific data, and the success report.

$today = Get-Date -Format "yyyy-MM-dd"

# Prepare custom replacements
$customReplacements = @{
    "[Matrix Name]"               = $MatrixName
    "[Matrix Date]"               = $today
    "[PD-TDA-XXX]"                = $AssessmentId
    "[Number of debt items]"      = if ($ItemCount -gt 0) { "$ItemCount" } else { "[Number of debt items]" }
    "[Assessor]"                  = "AI Agent & Human Partner"
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "assessment_reference" = $AssessmentId
}

$documentId = New-FrameworkDocument `
    -TemplatePath (Join-Path (Get-ProcessFrameworkPath) "templates/cyclical/prioritization-matrix-template.md") `
    -IdPrefix "PD-TDM" `
    -IdDescription "Prioritization Matrix: $MatrixName" `
    -DocumentName $MatrixName `
    -OutputDirectory "doc/technical-debt/matrices" `
    -Replacements $customReplacements `
    -Metadata $additionalMetadataFields `
    -Label "prioritization matrix" `
    -OpenInEditor:$OpenInEditor

$details = @(
    "Matrix Name: $MatrixName",
    "Assessment Reference: $AssessmentId"
)

if ($ItemCount -gt 0) {
    $details += "Items to Prioritize: $ItemCount"
}

$details += "Customization required — apply the technical-debt-assessment craft skill (.claude/skills/technical-debt-assessment/references/prioritization.md)"

Write-ProjectSuccess -Message "Created prioritization matrix with ID: $documentId" -Details $details
