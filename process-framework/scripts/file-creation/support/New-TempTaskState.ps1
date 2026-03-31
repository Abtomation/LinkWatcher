# New-TempTaskState.ps1
# Creates a new temporary state tracking file for task creation or process improvement workflows
# Uses the central ID registry system and standardized document creation

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Discrete", "Cyclical", "Continuous", "Support")]
    [string]$TaskType,

    [Parameter(Mandatory = $false)]
    [ValidateSet("TaskCreation", "ProcessImprovement")]
    [string]$Variant = "TaskCreation",

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

# Validate: TaskCreation variant requires TaskType
if ($Variant -eq "TaskCreation" -and -not $TaskType) {
    Write-ProjectError -Message "-TaskType is required when using -Variant TaskCreation (the default). Use -Variant ProcessImprovement for process improvement state files." -ExitCode 1
    return
}

$kebabName = ConvertTo-KebabCase -InputString $TaskName
$projectRoot = Get-ProjectRoot
$processFrameworkDir = Join-Path $projectRoot "process-framework"

# Prepare additional metadata fields (shared)
$additionalMetadataFields = @{
    "task_name" = $kebabName
}

if ($Variant -eq "ProcessImprovement") {
    # --- Process Improvement variant ---
    $templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\support\temp-process-improvement-state-template.md"
    $customFileName = "temp-process-improvement-$kebabName.md"
    $idDescription = "Temporary process improvement state: ${TaskName}"

    $customReplacements = @{
        "[Task Name]" = $TaskName
    }

    if ($Description -ne "") {
        $customReplacements["[Brief description of what will change]"] = $Description
    }

    $successDetails = @(
        "",
        "✅ Process improvement state file created.",
        "",
        "📖 CUSTOMIZATION GUIDE:",
        "process-framework/guides/support/temp-state-tracking-customization-guide.md",
        "🎯 FOCUS: Fill in Improvement Overview, Affected Components, and phase checklists.",
        "",
        "💡 This template is pre-structured for process improvement workflows —",
        "   less customization needed compared to the generic task creation template."
    )
} else {
    # --- Task Creation variant (original behavior) ---
    $templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\support\temp-task-creation-state-template.md"
    $customFileName = "temp-task-creation-$kebabName.md"
    $idDescription = "Temporary task state for $TaskType task: ${TaskName}"

    $expectedCompletion = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")

    $customReplacements = @{
        "[Task Name]"                                 = $TaskName
        "[Discrete/Cyclical/Continuous]"              = $TaskType
        "- **Expected Completion**: [YYYY-MM-DD]"     = "- **Expected Completion**: $expectedCompletion"
    }

    if ($Description -ne "") {
        $customReplacements["Brief task description"] = $Description
    }

    $successDetails = @(
        "",
        "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - EXTENSIVE CUSTOMIZATION REQUIRED 🚨🚨🚨",
        "",
        "⚠️  IMPORTANT: This script creates ONLY a structural template/framework.",
        "⚠️  The generated file is NOT a functional document until extensively customized.",
        "⚠️  AI agents MUST follow the referenced guide to properly customize the content.",
        "",
        "📖 MANDATORY CUSTOMIZATION GUIDE:",
        "process-framework/guides/support/temp-state-tracking-customization-guide.md",
        "🎯 FOCUS AREAS: 'Temporary State Management' section",
        "",
        "🚫 DO NOT use the generated file without proper customization!",
        "✅ The template provides structure - YOU provide the meaningful content."
    )
}

try {
    $tempId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-STA" -IdDescription $idDescription -DocumentName $TaskName -OutputDirectory "process-framework/state-tracking/temporary" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $customFileName -OpenInEditor:$OpenInEditor

    Write-ProjectSuccess -Message "Created temporary state file with ID: $tempId (Variant: $Variant)" -Details $successDetails
}
catch {
    Write-ProjectError -Message "Failed to create temporary state file: $($_.Exception.Message)" -ExitCode 1
}
