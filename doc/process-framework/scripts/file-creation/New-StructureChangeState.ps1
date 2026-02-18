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
    [ValidateSet("Template Update", "Directory Reorganization", "Metadata Structure", "Documentation Architecture")]
    [string]$ChangeType = "Template Update",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Calculate expected completion (14 days from now as default for structure changes)
$expectedCompletion = (Get-Date).AddDays(14).ToString("yyyy-MM-dd")

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "change_name" = ConvertTo-KebabCase -InputString $ChangeName
}

# Prepare custom replacements
$customReplacements = @{
    "[Change Name]"                                                                            = $ChangeName
    "[Template Update/Directory Reorganization/Metadata Structure/Documentation Architecture]" = $ChangeType
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
    $stateId = New-StandardProjectDocument -TemplatePath "doc/process-framework/templates/templates/structure-change-state-template.md" -IdPrefix "PF-STA" -IdDescription "Structure change state for: ${ChangeName}" -DocumentName $ChangeName -OutputDirectory "doc/process-framework/state-tracking/temporary" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $customFileName -OpenInEditor:$OpenInEditor

    $details = @(
        "",
        "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - EXTENSIVE CUSTOMIZATION REQUIRED 🚨🚨🚨",
        "",
        "⚠️  IMPORTANT: This script creates ONLY a structural template/framework.",
        "⚠️  The generated file is NOT a functional document until extensively customized.",
        "⚠️  AI agents MUST follow the referenced guide to properly customize the content.",
        "",
        "📖 MANDATORY CUSTOMIZATION GUIDE:",
        "   doc/process-framework/tasks/support/structure-change-task.md",
        "",
        "📖 MANDATORY CUSTOMIZATION GUIDE:",
        "   doc/process-framework/tasks/support/structure-change-task.md",
        "🎯 FOCUS AREAS: Process section and mandatory steps",
        "",
        "⚠️  CRITICAL: Create structure change proposal BEFORE making any changes:",
        "   Use: doc/process-framework/templates/templates/structure-change-proposal-template.md",
        "🚫 DO NOT use the generated file without proper customization!",
        "✅ The template provides structure - YOU provide the meaningful content."
    )

    Write-ProjectSuccess -Message "Created structure change state file with ID: $stateId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create structure change state file: $($_.Exception.Message)" -ExitCode 1
}
