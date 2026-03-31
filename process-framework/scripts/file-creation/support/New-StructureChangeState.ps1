# New-StructureChangeState.ps1
# Creates a new structure change state tracking file
# Uses the central ID registry system and standardized document creation

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ChangeName,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Template Update", "Directory Reorganization", "Metadata Structure", "Documentation Architecture", "Rename", "Content Update")]
    [string]$ChangeType = "Template Update",

    [Parameter(Mandatory = $false)]
    [switch]$FromProposal,

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

# Calculate expected completion (14 days from now as default for structure changes)
$expectedCompletion = (Get-Date).AddDays(14).ToString("yyyy-MM-dd")

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "change_name" = ConvertTo-KebabCase -InputString $ChangeName
}

# Validate -FromProposal is not used with Rename or Content Update (they already have lightweight templates)
if ($FromProposal -and ($ChangeType -eq "Rename" -or $ChangeType -eq "Content Update")) {
    Write-ProjectError -Message "-FromProposal cannot be used with ChangeType '$ChangeType' (it already has a lightweight template)" -ExitCode 1
}

# Select template based on ChangeType and -FromProposal
if ($ChangeType -eq "Rename") {
    $templatePath = "process-framework/templates/support/structure-change-state-rename-template.md"
} elseif ($ChangeType -eq "Content Update") {
    $templatePath = "process-framework/templates/support/structure-change-state-content-update-template.md"
} elseif ($FromProposal) {
    $templatePath = "process-framework/templates/support/structure-change-state-from-proposal-template.md"
} else {
    $templatePath = "process-framework/templates/support/structure-change-state-template.md"
}

# Prepare custom replacements
$customReplacements = @{
    "[Change Name]"                                                                            = $ChangeName
    "[Template Update/Directory Reorganization/Metadata Structure/Documentation Architecture/Content Update]" = $ChangeType
    "[YYYY-MM-DD]"                                                                             = $expectedCompletion
}

# Add description if provided
if ($Description -ne "") {
    $customReplacements["[Brief description of what's being changed]"] = $Description
}

# Create the document using standardized process with custom filename pattern
$kebabName = ConvertTo-KebabCase -InputString $ChangeName
$customFileName = "structure-change-$kebabName.md"

try {
    $stateId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-STA" -IdDescription "Structure change state for: ${ChangeName}" -DocumentName $ChangeName -OutputDirectory "process-framework/state-tracking/temporary" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $customFileName -OpenInEditor:$OpenInEditor

    if ($FromProposal) {
        $details = @(
            "",
            "📋 LIGHTWEIGHT STATE FILE (from proposal)",
            "",
            "✅ This state file tracks execution progress only.",
            "✅ See the linked proposal document for rationale, affected files, and migration strategy.",
            "",
            "⚠️  CUSTOMIZE the phase checklists to match your proposal's phases.",
            "⚠️  CROSS-CHECK: Verify every file in the proposal's affected files table",
            "   appears in at least one phase checklist.",
            "",
            "📖 TASK GUIDE: process-framework/tasks/support/structure-change-task.md"
        )
    } else {
        $details = @(
            "",
            "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - EXTENSIVE CUSTOMIZATION REQUIRED 🚨🚨🚨",
            "",
            "⚠️  IMPORTANT: This script creates ONLY a structural template/framework.",
            "⚠️  The generated file is NOT a functional document until extensively customized.",
            "⚠️  AI agents MUST follow the referenced guide to properly customize the content.",
            "",
            "📖 MANDATORY CUSTOMIZATION GUIDE:",
            "process-framework/tasks/support/structure-change-task.md",
            "🎯 FOCUS AREAS: Process section and mandatory steps",
            "",
            "⚠️  CRITICAL: Create structure change proposal BEFORE making any changes:",
            "   Use: process-framework/templates/support/structure-change-proposal-template.md",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content."
        )
    }

    Write-ProjectSuccess -Message "Created structure change state file with ID: $stateId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create structure change state file: $($_.Exception.Message)" -ExitCode 1
}
