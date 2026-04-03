# New-ValidationTracking.ps1
# Creates a new validation tracking state file for a validation round
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new validation tracking state file for a validation round.

.DESCRIPTION
    This PowerShell script generates validation tracking state files by:
    - Generating a unique state ID (PF-STA-XXX) automatically
    - Creating the file in doc/state-tracking/validation/
    - Populating round number and creation date
    - Updating the ID tracker in the central ID registry

    Used by the Validation Preparation task (PF-TSK-077) to create the
    tracking file that coordinates all validation sessions in a round.

.PARAMETER RoundNumber
    The validation round number (e.g., 1, 2, 3). Used in the document title
    and filename.

.PARAMETER Description
    Optional description of the validation round's focus or scope.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor.

.EXAMPLE
    .\New-ValidationTracking.ps1 -RoundNumber 4

    Creates validation-tracking-4.md in doc/state-tracking/validation/

.EXAMPLE
    .\New-ValidationTracking.ps1 -RoundNumber 4 -Description "Post-enhancement re-validation"

.NOTES
    Script Type: Document Creation Script
    Created: 2026-04-02
    For: Validation Preparation task (PF-TSK-077)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [int]$RoundNumber,

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

# Perform standard initialization
Invoke-StandardScriptInitialization

$today = Get-Date -Format "yyyy-MM-dd"

# Prepare custom replacements
$customReplacements = @{
    "[Round N]" = "Round $RoundNumber"
    "[YYYY-MM-DD]" = $today
}

if ($Description -ne "") {
    $customReplacements["[Describe first validation session]"] = $Description
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "validation_round" = "$RoundNumber"
}

$customFileName = "validation-tracking-$RoundNumber.md"

try {
    $documentId = New-StandardProjectDocument `
        -TemplatePath "process-framework/templates/05-validation/validation-tracking-template.md" `
        -IdPrefix "PF-STA" `
        -IdDescription "Validation tracking state for Round $RoundNumber" `
        -DocumentName "Validation Tracking Round $RoundNumber" `
        -OutputDirectory "doc/state-tracking/validation" `
        -Replacements $customReplacements `
        -AdditionalMetadataFields $additionalMetadataFields `
        -FileNamePattern $customFileName `
        -OpenInEditor:$OpenInEditor

    $details = @(
        "Round: $RoundNumber",
        "Location: doc/state-tracking/validation/$customFileName"
    )

    if ($Description -ne "") {
        $details += "Description: $Description"
    }

    $details += @(
        "",
        "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - CUSTOMIZATION REQUIRED 🚨🚨🚨",
        "",
        "⚠️  Fill in the Feature Scope table with features to validate.",
        "⚠️  Update the Validation Progress Matrix dimensions based on feature profiles.",
        "⚠️  Plan the validation session sequence.",
        "",
        "📖 REFERENCE:",
        "process-framework/guides/05-validation/feature-validation-guide.md",
        "🎯 FOCUS: Dimension Catalog and feature Dimension Profiles"
    )

    Write-ProjectSuccess -Message "Created validation tracking with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create validation tracking: $($_.Exception.Message)" -ExitCode 1
}
