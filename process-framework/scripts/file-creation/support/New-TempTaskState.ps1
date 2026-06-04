# New-TempTaskState.ps1
# Creates a new temporary state tracking file for task creation or process improvement workflows
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
Creates a new temporary state tracking file for multi-session task creation, process improvement, or framework extension workflows.

.DESCRIPTION
Creates a temporary state file in process-framework-local/state-tracking/temporary/ from one of three template variants. Uses the central PF-id-registry to assign a PF-STA ID. Files are intended to be moved to temporary/old/ when the work cycle completes.

.PARAMETER TaskName
Human-readable name for the task / improvement / extension. Used as the document title and converted to kebab-case for the filename.

.PARAMETER Variant
Which template variant to instantiate. Allowed values:
  - TaskCreation       (default) — new task creation (5-phase roadmap)
  - ProcessImprovement — process improvement work
  - FrameworkExtension — multi-artifact framework extensions

.PARAMETER Description
Optional one-line description that replaces the placeholder in the template.

.PARAMETER OpenInEditor
Open the created file in the default editor after creation.

.EXAMPLE
.\New-TempTaskState.ps1 -TaskName "Refactor Bug Triage Flow" -Variant ProcessImprovement -Description "Simplify Step 3 routing"

.EXAMPLE
.\New-TempTaskState.ps1 -TaskName "PF-PRO-028 v2.0 Rollout" -Variant FrameworkExtension
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,

    [Parameter(Mandatory = $false)]
    [ValidateSet("TaskCreation", "ProcessImprovement", "FrameworkExtension", "BlueprintSync")]
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


# Soak verification opt-in (PF-PRO-028 v2.0 Pattern B; helper-routed armoring via DocumentManagement.psm1).
# Caller-aware no-arg form: helper resolves this script's path via Get-PSCallStack.
# Idempotent — silently no-ops if already registered.
Register-SoakScript

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
} elseif ($Variant -eq "FrameworkExtension") {
    # --- Framework Extension variant ---
    $templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\support\temp-framework-extension-state-template.md"
    $customFileName = "temp-framework-extension-$kebabName.md"
    $idDescription = "Temporary framework extension state: ${TaskName}"

    $customReplacements = @{
        "[Task Name]" = $TaskName
    }

    if ($Description -ne "") {
        $customReplacements["[Brief description of what will change]"] = $Description
    }

    $successDetails = @(
        "",
        "✅ Framework extension state file created.",
        "",
        "📖 CUSTOMIZATION GUIDE:",
        "process-framework/guides/support/temp-state-tracking-customization-guide.md",
        "🎯 FOCUS: Fill in Extension Overview, Artifact Tracking table, Task Impact table, and phase checklists.",
        "",
        "💡 This template is pre-structured for multi-artifact framework extensions —",
        "   includes artifact tracking, task impact analysis, and multi-phase implementation."
    )
} elseif ($Variant -eq "BlueprintSync") {
    # --- Blueprint Sync variant ---
    $templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\support\temp-blueprint-sync-state-template.md"
    $customFileName = "temp-blueprint-sync-$kebabName.md"
    $idDescription = "Temporary blueprint sync state: ${TaskName}"

    $customReplacements = @{}

    $successDetails = @(
        "",
        "✅ Blueprint sync state file created.",
        "",
        "📖 CONSUMER TASK: process-framework/tasks/support/framework-blueprint-sync-task.md (PF-TSK-087)",
        "🎯 FOCUS: Fill in Session Parameters, Per-Item Classification & Selection table, Notes on Specific Items, and Session Log.",
        "",
        "💡 This template is pre-structured for blueprint sync sessions —",
        "   per-directory rules, per-item classification, durable backlog/log refs."
    )
} else {
    # --- Task Creation variant (original behavior) ---
    $templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\support\temp-task-creation-state-template.md"
    $customFileName = "temp-task-creation-$kebabName.md"
    $idDescription = "Temporary task state: ${TaskName}"

    $customReplacements = @{
        "[Task Name]"                                 = $TaskName
    }

    if ($Description -ne "") {
        $customReplacements["Brief task description"] = $Description
    }

    $successDetails = @(
        "Customization required — see process-framework/guides/support/temp-state-tracking-customization-guide.md"
    )
}

try {
    $tempId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-STA" -IdDescription $idDescription -DocumentName $TaskName -OutputDirectory "process-framework-local/state-tracking/temporary" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $customFileName -OpenInEditor:$OpenInEditor

    Write-ProjectSuccess -Message "Created temporary state file with ID: $tempId (Variant: $Variant)" -Details $successDetails
}
catch {
    Write-ProjectError -Message "Failed to create temporary state file: $($_.Exception.Message)" -ExitCode 1
}
