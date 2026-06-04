# New-TempTaskState.ps1
# Creates a new temporary state tracking file for task creation or process improvement workflows
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
Creates a new temporary state tracking file for multi-session task creation, process improvement, framework extension, framework evaluation, blueprint sync, refactoring, or retrospective documentation workflows.

.DESCRIPTION
Creates a temporary state file from one of seven template variants. The destination directory
is resolved at runtime via Get-StateTrackingContext (project_id-aware routing):
  - For appdev (project_id == "PRJ-000"): process-framework-central/state-tracking/temporary/
  - For projects (project_id != "PRJ-000"): doc/state-tracking/temporary/
Uses the central PF-id-registry to assign a PF-STA ID (also project_id-aware via IdRegistry's
Resolve-LocalRegistryPath helper). Files are intended to be moved to temporary/old/ when the
work cycle completes.

.PARAMETER TaskName
Human-readable name for the task / improvement / extension. Used as the document title and converted to kebab-case for the filename.

.PARAMETER Variant
Which template variant to instantiate. Allowed values:
  - TaskCreation              (default) — new task creation (5-phase roadmap)
  - ProcessImprovement        — process improvement work (PF-TSK-009)
  - FrameworkExtension        — multi-artifact framework extensions (PF-TSK-026)
  - FrameworkEvaluation       — multi-session framework evaluations (PF-TSK-079; dimension analysis + findings log)
  - BlueprintSync             — framework-blueprint-sync sessions (PF-TSK-087)
  - Refactoring               — code refactoring (PF-TSK-022 Standard Path; ≥5 items or 3+ sessions)
  - RetrospectiveDocumentation — per-feature Phase 3 documentation creation (PF-TSK-066; Tier 2/3 multi-session)

.PARAMETER Description
Optional one-line description that replaces the placeholder in the template.

.PARAMETER OpenInEditor
Open the created file in the default editor after creation.

.EXAMPLE
.\New-TempTaskState.ps1 -TaskName "Refactor Bug Triage Flow" -Variant ProcessImprovement -Description "Simplify Step 3 routing"

.EXAMPLE
.\New-TempTaskState.ps1 -TaskName "PF-PRO-028 v2.0 Rollout" -Variant FrameworkExtension

.EXAMPLE
.\New-TempTaskState.ps1 -TaskName "TD004 Service Layer Refactor" -Variant Refactoring -Description "Extract repository access from UI; resolve TD004"

.EXAMPLE
.\New-TempTaskState.ps1 -TaskName "PF-TSK-066 Phase 3 — 2.1.2 Company Details" -Variant RetrospectiveDocumentation

.EXAMPLE
.\New-TempTaskState.ps1 -TaskName "Onboarding Process Evaluation" -Variant FrameworkEvaluation -Description "Full seven-dimension evaluation of PF-TSK-059/064/065/066"
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,

    [Parameter(Mandatory = $false)]
    [ValidateSet("TaskCreation", "ProcessImprovement", "FrameworkExtension", "FrameworkEvaluation", "BlueprintSync", "Refactoring", "RetrospectiveDocumentation")]
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
$processFrameworkDir = Get-ProcessFrameworkPath  # Phase 5.5: configurable via paths.process_framework

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
} elseif ($Variant -eq "FrameworkEvaluation") {
    # --- Framework Evaluation variant ---
    $templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\support\temp-framework-evaluation-state-template.md"
    $customFileName = "temp-framework-evaluation-$kebabName.md"
    $idDescription = "Temporary framework evaluation state: ${TaskName}"

    $customReplacements = @{
        "[Task Name]" = $TaskName
    }

    if ($Description -ne "") {
        $customReplacements["[Brief description of the evaluation scope]"] = $Description
    }

    $successDetails = @(
        "",
        "✅ Framework evaluation state file created.",
        "",
        "📖 CONSUMER TASK: process-framework/tasks/support/framework-evaluation.md (PF-TSK-079)",
        "🎯 FOCUS: Fill in Evaluation Overview, the Artifacts in Scope table (Step 4), Dimension Progress (Step 5), Findings Log (Steps 7-8), and the Session Plan.",
        "",
        "💡 This template is pre-structured for multi-session framework evaluations —",
        "   artifact inventory, per-dimension progress across the seven dimensions, findings log with routing, and session tracking."
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
} elseif ($Variant -eq "Refactoring") {
    # --- Refactoring variant ---
    $templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\support\temp-refactoring-state-template.md"
    $customFileName = "temp-refactoring-$kebabName.md"
    $idDescription = "Temporary refactoring state: ${TaskName}"

    $customReplacements = @{
        "[Task Name]" = $TaskName
    }

    $successDetails = @(
        "",
        "✅ Refactoring state file created.",
        "",
        "📖 CONSUMER TASK: process-framework/tasks/06-maintenance/code-refactoring-standard-path.md (PF-TSK-022)",
        "🎯 FOCUS: Fill in Refactoring Overview, capture the Test Baseline (Step 5 — MANDATORY before any code changes), then work through Phase 0 → A → B → C → D.",
        "",
        "💡 This template is pre-structured for multi-session refactorings —",
        "   includes test-baseline anchor, phase-by-phase checklists, bug-discovery log,",
        "   and the 3-phase state-file-update closure (per Standard Path Step 22)."
    )
} elseif ($Variant -eq "RetrospectiveDocumentation") {
    # --- Retrospective Documentation variant ---
    $templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\support\temp-retrospective-documentation-state-template.md"
    $customFileName = "temp-retrospective-documentation-$kebabName.md"
    $idDescription = "Temporary retrospective documentation state: ${TaskName}"

    $customReplacements = @{}

    $successDetails = @(
        "",
        "✅ Retrospective documentation state file created.",
        "",
        "📖 CONSUMER TASK: process-framework/tasks/00-setup/retrospective-documentation-creation.md (PF-TSK-066 Phase 3)",
        "🎯 FOCUS: Fill in Feature Overview, Required Phase 3 Deliverables table, Per-Feature Closure Updates table, and Session Plan.",
        "",
        "💡 This template scopes a single feature's Phase 3 cycle when work spans multiple sessions —",
        "   typical for Tier 2/3 features where Test Spec / QAR / user-doc audit are deferred to Session 2."
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
    $stContext = Get-StateTrackingContext
    $outputDir = "$($stContext.StateTrackingRelative)/temporary"
    $tempId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-STA" -IdDescription $idDescription -DocumentName $TaskName -OutputDirectory $outputDir -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $customFileName -OpenInEditor:$OpenInEditor

    Write-ProjectSuccess -Message "Created temporary state file with ID: $tempId (Variant: $Variant)" -Details $successDetails
}
catch {
    Write-ProjectError -Message "Failed to create temporary state file: $($_.Exception.Message)" -ExitCode 1
}
