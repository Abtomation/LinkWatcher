# New-TempTaskState.ps1
# Creates a new temporary task creation state tracking file
# Uses the central ID registry system and standardized document creation

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Discrete", "Cyclical", "Continuous", "Support")]
    [string]$TaskType,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Calculate expected completion (30 days from now as default)
$expectedCompletion = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "task_name" = ConvertTo-KebabCase -InputString $TaskName
}

# Prepare custom replacements
$customReplacements = @{
    "[Task Name]"                                 = $TaskName
    "[Discrete/Cyclical/Continuous]"              = $TaskType
    "- **Expected Completion**: [YYYY-MM-DD]"     = "- **Expected Completion**: $expectedCompletion"
}

# Add description if provided
if ($Description -ne "") {
    $customReplacements["Brief task description"] = $Description
}

# Create the document using standardized process with custom filename pattern
$kebabName = ConvertTo-KebabCase -InputString $TaskName
$customFileName = "temp-task-creation-$kebabName.md"

# Build absolute template path
$projectRoot = Get-ProjectRoot
$processFrameworkDir = Join-Path $projectRoot "doc\process-framework"
$templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\templates\temp-task-creation-state-template.md"

try {
    $tempId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-STA" -IdDescription "Temporary task state for $TaskType task: ${TaskName}" -DocumentName $TaskName -OutputDirectory "doc/process-framework/state-tracking/temporary" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $customFileName -OpenInEditor:$OpenInEditor

    $details = @(
        "",
        "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - EXTENSIVE CUSTOMIZATION REQUIRED 🚨🚨🚨",
        "",
        "⚠️  IMPORTANT: This script creates ONLY a structural template/framework.",
        "⚠️  The generated file is NOT a functional document until extensively customized.",
        "⚠️  AI agents MUST follow the referenced guide to properly customize the content.",
        "",
        "📖 MANDATORY CUSTOMIZATION GUIDE:",
        "   doc/process-framework/guides/guides/temp-task-state-creation-guide.md",
        "🎯 FOCUS AREAS: 'Temporary State Management' section",
        "",
        "🚫 DO NOT use the generated file without proper customization!",
        "✅ The template provides structure - YOU provide the meaningful content."
    )

    Write-ProjectSuccess -Message "Created temporary task state file with ID: $tempId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create temporary task state file: $($_.Exception.Message)" -ExitCode 1
}
