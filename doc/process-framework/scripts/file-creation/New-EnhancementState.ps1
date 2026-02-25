# New-EnhancementState.ps1
# Creates a new Enhancement State Tracking file for tracking enhancement work on existing features
# Uses the central ID registry system and standardized document creation
# Produced by Feature Request Evaluation (PF-TSK-067), consumed by Feature Enhancement (PF-TSK-068)

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetFeature,

    [Parameter(Mandatory = $true)]
    [string]$EnhancementName,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "target_feature"    = $TargetFeature
    "enhancement_name"  = ConvertTo-KebabCase -InputString $EnhancementName
}

# Prepare custom replacements
$customReplacements = @{
    "[Enhancement Name]"    = $EnhancementName
    "[Feature ID]"          = $TargetFeature
}

# Add description if provided
if ($Description -ne "") {
    $customReplacements["[Brief description of what is being enhanced]"] = $Description
}

# Create the document using standardized process with custom filename pattern
$kebabName = ConvertTo-KebabCase -InputString $EnhancementName
$customFileName = "enhancement-$kebabName.md"

# Build absolute template path
$projectRoot = Get-ProjectRoot
$processFrameworkDir = Join-Path $projectRoot "doc\process-framework"
$templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\templates\enhancement-state-tracking-template-template.md"

try {
    $idDesc = "Enhancement state tracking for ${TargetFeature}: ${EnhancementName}"
    $stateId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-STA" -IdDescription $idDesc -DocumentName $EnhancementName -OutputDirectory "doc/process-framework/state-tracking/temporary" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $customFileName -OpenInEditor:$OpenInEditor

    $details = @(
        "",
        "   Target Feature: $TargetFeature",
        "   Enhancement: $EnhancementName",
        "",
        "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - EXTENSIVE CUSTOMIZATION REQUIRED 🚨🚨🚨",
        "",
        "⚠️  IMPORTANT: This script creates ONLY a structural template/framework.",
        "⚠️  The generated file is NOT a functional document until extensively customized.",
        "⚠️  AI agents MUST follow the referenced guide to properly customize the content.",
        "",
        "📖 MANDATORY CUSTOMIZATION GUIDE:",
        "   doc/process-framework/guides/guides/enhancement-state-tracking-customization-guide.md",
        "🎯 FOCUS AREAS: Scope assessment, documentation inventory, workflow block evaluation (mark each as applicable/not applicable)",
        "",
        "🚫 DO NOT use the generated file without proper customization!",
        "✅ The template provides structure - YOU provide the meaningful content."
    )

    Write-ProjectSuccess -Message "Created enhancement state tracking file with ID: $stateId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create enhancement state tracking file: $($_.Exception.Message)" -ExitCode 1
}
