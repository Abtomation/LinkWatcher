# New-Task.ps1
# Creates a new task document with an automatically assigned ID

<#
.SYNOPSIS
Creates a new task definition document with an automatically assigned task ID from the workspace's declared artifact family (PF-TSK at appdev, FB-TSK at FB — PF-PRO-068 P-12a).

.DESCRIPTION
Generates a new task definition file from the task template under
process-framework/tasks/<workflow-phase>/, seeds the PF-PRO-042 task-metadata
frontmatter (use_when, complexity/frequency, automation, description), then
regenerates the task-metadata projections so the new task appears in ai-tasks.md,
both infrastructure registries, and the tasks/README catalog.

The task file's frontmatter + authored sections are the single source of truth
(PF-IMP-1134): this script no longer hand-inserts rows into ai-tasks.md, the
registries, or tasks/README — those are generated views produced by
Build-TaskMetadata.ps1. (PF-documentation-map.md is generated separately by
Build-DocumentationMap.ps1, as for every other New-* script.)

The script seeds only the scalar routing fields. The nested list/map fields
(triggers, scripts, trigger_status, output_status, next_tasks) and the body
sections (File Operations, the Next Tasks transition subsections) are documented
in the template's schema comment and filled during customization — re-run
Build-TaskMetadata.ps1 afterward to refresh the projections.

.PARAMETER TaskName
Human-readable name for the task. Used as the document title and converted to
kebab-case for the filename.

.PARAMETER Description
Optional 1-2 sentence description of the task's purpose. Becomes the `description:`
frontmatter (drives PF-documentation-map.md) and, absent -UseWhen, the initial
Use When routing text.

.PARAMETER WorkflowPhase
Which workflow phase the task belongs to. Determines the subdirectory under
process-framework/tasks/ and the per-category metadata rules. The valid values are the
workspace's own task-pool directory types as declared in its ID registry (PF-PRO-068 E2:
level differences are data, never hardcoded lists) — at appdev the ten domain phases
(00-setup … 07-deployment, support, cyclical), at FB only 'support'. Omitted, the phase
falls back to the registry's declared default ('01-planning' at appdev, 'support' at FB).
An undeclared phase is refused naming the declared set.

.PARAMETER Complexity
Task complexity for the Complexity column (simple|medium|complex; default medium).
Omitted for support tasks (their table has no Complexity column).

.PARAMETER Automation
Automation status (full|semi|partial|manual; default manual — new tasks start
manual until their scripts are wired during customization).

.PARAMETER UseWhen
Explicit Use When routing text. Defaults to -Description, or a placeholder.

.PARAMETER Frequency
Frequency text for cyclical tasks (renders the Frequency column; default "As needed").
Ignored for non-cyclical phases.

.PARAMETER OpenInEditor
Open the created file in the default editor after creation.

.EXAMPLE
New-Task.ps1 -TaskName "Database Migration Review" -WorkflowPhase "06-maintenance" -Complexity medium -Description "Review pending DB migrations before deployment"

.EXAMPLE
New-Task.ps1 -TaskName "Cache Warmup" -WorkflowPhase "cyclical" -Frequency "Before each release"
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    # No static ValidateSet: the valid phases are per-workspace registry data (PF-PRO-068 E2) —
    # a hardcoded ten-member set threw at FB on the default invocation and 9 of 10 phases.
    # Validated in-body against the task pool's declared directory types; '' = registry default.
    [Parameter(Mandatory = $false)]
    [string]$WorkflowPhase = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("simple", "medium", "complex")]
    [string]$Complexity = "medium",

    [Parameter(Mandatory = $false)]
    [ValidateSet("full", "semi", "partial", "manual")]
    [string]$Automation = "manual",

    [Parameter(Mandatory = $false)]
    [string]$UseWhen = "",

    [Parameter(Mandatory = $false)]
    [string]$Frequency = "",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers + the ID registry module (Get-PrefixDirectories / Get-PrefixInfo
# for the registry-driven phase validation below — IdRegistry is a sibling top-level module,
# not re-exported by the umbrella).
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
Import-Module (Join-Path $dir "IdRegistry.psm1") -Force

# Init, soak opt-in, the New-StandardProjectDocument call, and the create-failure error path are
# owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This Tier-3 script keeps
# its data, its bespoke post-creation task-metadata regeneration, and its own output — inline.

# Metadata values are passed raw — the shared frontmatter writer makes every string metadata
# value YAML-safe itself (ConvertTo-YamlSafeScalar, PF-IMP-1413; caller-side pre-quoting
# removed per PF-IMP-1524).

# Title + purpose replacements applied to the template body
$purposeText = if ($Description -ne "") { $Description } else { "Task for $TaskName" }
$customReplacements = @{
    "# [Task Name]"                                                                       = "# $TaskName"
    "[1-2 sentences explaining the task's purpose and importance in the overall process]" = $purposeText
}

# Initial Use When routing text (human refines during customization)
$useWhenText = if ($UseWhen -ne "") { $UseWhen } elseif ($Description -ne "") { $Description } else { "When working on $TaskName" }

# P-12a (PF-PRO-068): the shipped-pool family is the workspace's declared artifact_prefix
# ('PF' at appdev, 'FB' at FB). Resolved, never hardcoded — a leaf role throws here by
# contract (task creation is a support task; leaves author no shipped framework artifacts).
$artifactFamily = Get-ArtifactPrefix

# Registry-driven workflow phases (PF-PRO-068 E2 FB live-break fix): the valid phases are the
# workspace's own task-pool directory types as declared in its ID registry — never a hardcoded
# list (the former static ValidateSet threw at FB on the default invocation and 9 of 10
# phases). 'main' (the tasks/ catalog root) and the 'default' alias are bookkeeping keys, not
# phases. No -WorkflowPhase → the registry's declared default ('01-planning' at appdev,
# 'support' at FB). Runs before any side effect, so an undeclared phase refuses cleanly.
$taskPrefix = "$artifactFamily-TSK"
$declaredPhases = @(Get-PrefixDirectories -Prefix $taskPrefix -ListTypes | Where-Object { $_ -ne 'main' })
if ($WorkflowPhase -eq "") {
    $WorkflowPhase = (Get-PrefixInfo -Prefix $taskPrefix).directories.default
    if (-not $WorkflowPhase) {
        throw "The $taskPrefix registry entry declares no 'default' directory type — pass -WorkflowPhase explicitly. Declared phases: $($declaredPhases -join ', ')."
    }
} elseif ($WorkflowPhase -notin $declaredPhases) {
    throw "WorkflowPhase '$WorkflowPhase' is not declared for $taskPrefix in this workspace's ID registry. Declared phases: $($declaredPhases -join ', ')."
}

# Scalar task-metadata frontmatter fields (PF-PRO-042). Nested list/map fields are left
# to customization per the template schema comment. Per-category rules: support omits
# complexity; cyclical uses frequency instead.
$metadataFields = @{
    domain      = "agnostic"
    description = $purposeText
    use_when    = $useWhenText
    automation  = $Automation
}
if ($WorkflowPhase -eq "cyclical") {
    $freqText = if ($Frequency -ne "") { $Frequency } else { "As needed" }
    $metadataFields["frequency"] = $freqText
} elseif ($WorkflowPhase -ne "support") {
    $metadataFields["complexity"] = $Complexity
}

# Build absolute template path (config-driven; honors paths.process_framework in project-config.json)
$processFrameworkDir = Get-ProcessFrameworkPath
$templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\support\task-template.md"

try {
    # IMP-407: Auto-append "-task" suffix with double-suffix guard
    $taskDocName = $TaskName
    if ($taskDocName -notmatch '(?i)[-\s]task$') {
        $taskDocName = "$taskDocName-task"
    }
    # IMP-438: Compute kebab filename once for the created-path resolution below
    $kebabFileName = ConvertTo-KebabCase -InputString $taskDocName

    # $artifactFamily resolved above (with the registry-driven phase validation).
    $taskId = New-FrameworkDocument -TemplatePath $templatePath -IdPrefix "$artifactFamily-TSK" `
        -IdDescription "$WorkflowPhase task: ${TaskName}" -DocumentName $taskDocName `
        -DirectoryType $WorkflowPhase -Replacements $customReplacements `
        -Metadata $metadataFields -Label "task" -OpenInEditor:$OpenInEditor

    Write-Verbose "Created task with ID: $taskId"

    # Regenerate the task-metadata projections from the new task's frontmatter.
    # Replaces the former hand-rolled insertion into ai-tasks.md / registries / README,
    # which are now generated views (PF-IMP-1134). Run as a child process: the generator
    # calls `exit`, which would otherwise terminate this script. -WhatIf skips both the
    # creation above and this regeneration (nothing was created to project).
    $generator = Join-Path -Path $processFrameworkDir -ChildPath "scripts/validation/Build-TaskMetadata.ps1"
    if ($PSCmdlet.ShouldProcess("ai-tasks.md, both infrastructure registries, tasks/README", "Regenerate task-metadata projections")) {
        if (Test-Path $generator) {
            & pwsh.exe -NoProfile -ExecutionPolicy Bypass -File $generator -FrameworkRoot $processFrameworkDir
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Build-TaskMetadata.ps1 exited $LASTEXITCODE. Review the new task's frontmatter (YAML validity / required fields) and regenerate manually: Build-TaskMetadata.ps1"
            } else {
                Write-Verbose "Task-metadata projections regenerated."
            }
        } else {
            Write-Warning "Build-TaskMetadata.ps1 not found at $generator. Regenerate the task-metadata projections manually."
        }
    }

    # Display next steps guidance (real creation only; -WhatIf short-circuits $taskId to $null)
    if ($taskId) {
        Write-Host ""
        Write-Host "Created task '$TaskName' ($taskId) at tasks/$WorkflowPhase/$kebabFileName.md" -ForegroundColor Green
        Write-Host ""
        Write-Host "MANDATORY NEXT STEP: apply the task-creation craft skill" -ForegroundColor Red
        Write-Host "   You MUST apply the task-creation craft skill before customizing." -ForegroundColor Yellow
        Write-Host "   .claude/skills/task-creation/SKILL.md (the two-phase model)" -ForegroundColor White
        Write-Host ""
        Write-Host "The new task is a STARTING POINT. During customization, fill in (per the" -ForegroundColor Yellow
        Write-Host "template's TASK METADATA SCHEMA comment): the nested frontmatter fields" -ForegroundColor Yellow
        Write-Host "(triggers, scripts, trigger_status, output_status, next_tasks) and the body" -ForegroundColor Yellow
        Write-Host "sections (File Operations, the Next Tasks transition subsections). Then re-run:" -ForegroundColor Yellow
        Write-Host "   Build-TaskMetadata.ps1   (refreshes ai-tasks.md / registries / README)" -ForegroundColor White
        Write-Host "   Build-DocumentationMap.ps1   (refreshes PF-documentation-map.md)" -ForegroundColor White
        Write-Host ""
    }
}
catch {
    Write-ProjectError -Message "Failed to create task: $($_.Exception.Message)" -ExitCode 1
}
