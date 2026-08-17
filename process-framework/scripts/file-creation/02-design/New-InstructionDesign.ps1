# New-InstructionDesign.ps1
# Creates a new Instruction Design Document with an automatically assigned ID.
#
# Created 2026-08-04 for PF-PRO-064 / PF-IMP-1947 work item WI-3 (Instruction
# Medium, sub-concept 1 of the Framework Portfolio Architecture). Sibling of
# New-UIDesign.ps1 — orchestration is delegated to Invoke-DesignArtifactCreation
# in Common-ScriptHelpers/DesignArtifactCreation.psm1.

<#
.SYNOPSIS
    Creates a new Instruction Design Document (PD-IND-XXX).

.DESCRIPTION
    Generates the fourth design dimension's artifact — the design document for a
    feature whose deliverable includes instruction artifacts an agent executes.
    Carries a description: frontmatter line rendered by the generated PD map,
    advances the master Status, and inserts a row into the feature state file's
    §4 Documentation Inventory.

    Refuses to run in a project whose PD ID registry has no PD-IND prefix — the
    registration reaches an already-registered project only via a Framework
    Rollout Mode C migration, which may not have drained yet.

.PARAMETER FeatureId
.PARAMETER FeatureName
.PARAMETER Description
.PARAMETER OpenInEditor
.PARAMETER DryRun
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]  [string]$FeatureId,
    [Parameter(Mandatory = $true)]  [string]$FeatureName,
    [Parameter(Mandatory = $false)] [string]$Description = "",
    [Parameter(Mandatory = $false)] [switch]$OpenInEditor,
    [Parameter(Mandatory = $false)] [switch]$DryRun
)

# Walk-up Common-ScriptHelpers import
$dir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

Invoke-StandardScriptInitialization
Register-SoakScript

# ---- Preflight: PD-IND must be registered in THIS project's PD registry ----
# PD-IND ships in blueprint/doc/PD-id-registry.json, which Push-FrameworkUpdate.ps1
# does NOT mirror (it mirrors only blueprint/process-framework/ plus the per-skill
# .claude/skills/ tree). An already-registered project therefore receives the prefix
# only when its Mode C pending-migration entry drains (PF-PRO-064 WI-4, on the
# PRJ-001 MIG-011 pattern).
#
# Allocation is already safe without this guard — New-NextId throws
# "Prefix 'PD-IND' not found in ID registry" rather than allocating from a missing
# pool, verified by probe 2026-08-04. What this preflight adds is an ACTIONABLE
# message and a failure that happens before any assessment read or tracking write,
# rather than a generic registry throw partway through the pipeline.
Import-Module (Join-Path $dir "IdRegistry.psm1") -Force
try {
    [void](Get-PrefixInfo -Prefix "PD-IND")
}
catch {
    Write-ProjectError -Message ("PD-IND is not registered in this project's PD ID registry, so no Instruction Design document can be created here.`n" +
        "   Cause: the PD-IND prefix is bootstrap-seeded content — it reaches an already-registered project only through a Framework Rollout (PF-TSK-088) Mode C migration.`n" +
        "   Fix:   drain this project's pending PD-IND registry migration (process-framework-central/per-project-migrations/<PRJ-NNN>/pending-migrations.md), then re-run.`n" +
        "   Registry error: $($_.Exception.Message)") -ExitCode 1
}

# ---- Per-type composition ----
$featureIdForFilename = $FeatureId.Replace('.', '-')
$featureNameForFilename = ConvertTo-FeatureSlug -Name $FeatureName -Convention 'kebab-case'
$customFileName = "instruction-design-$featureIdForFilename-$featureNameForFilename.md"
$instructionRelativePath = "doc/technical/design/instruction/features/$customFileName"
$templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/02-design/instruction-design-template.md"

$customReplacements = @{
    "[Feature ID]"          = $FeatureId
    "[Feature Name]"        = $FeatureName
    "[Feature Description]" = if ($Description -ne "") { $Description } else { "Instruction design specification for $FeatureName" }
    "[Date]"                = Get-Date -Format "yyyy-MM-dd"
    "[Author]"              = "AI Agent & Human Partner"
}
$additionalMetadataFields = @{
    "feature_id"   = $FeatureId
    "feature_name" = $FeatureName
    description    = "Instruction Design Document for $FeatureName ($FeatureId)"
}

# Compute next master Status. Instruction Design is the fourth design gate
# (PF-PRO-064), ordered last in Get-NextStatusAfterDesignArtifact's chain so a
# mixed feature's instruction design is authored with its code designs in hand.
# After this artifact exists the feature advances past the gate (→ "📝 Needs TDD"
# / "🔧 Needs Impl Plan", or back to an earlier gate still outstanding).
$nextStatus = Get-NextStatusAfterDesignArtifact -FeatureId $FeatureId -CurrentArtifact 'InstructionDesign'

# ---- Delegate orchestration ----
try {
    $invokeArgs = @{
        ArtifactType               = "Instruction Design"
        IdPrefix                   = "PD-IND"
        IdDescription              = "instruction-design-$featureIdForFilename-$featureNameForFilename"
        TemplatePath               = $templatePath
        FileNamePattern            = $customFileName
        DocumentName               = $FeatureName
        DirectoryType              = "features"
        FeatureId                  = $FeatureId
        FeatureName                = $FeatureName
        Replacements               = $customReplacements
        AdditionalMetadataFields   = $additionalMetadataFields
        NewMasterStatus            = $nextStatus
        MasterStatusNotesFormatter = { param($id) "Instruction Design created: $id ($(Get-ProjectTimestamp -Format 'Date'))" }
        ArtifactRelativePath       = $instructionRelativePath
        OpenInEditor               = $OpenInEditor
        DryRun                     = $DryRun
    }
    $result = Invoke-DesignArtifactCreation @invokeArgs

    # ---- Display ----
    $details = @(
        "Feature ID: $FeatureId",
        "Feature Name: $FeatureName",
        "",
        "📜 REQUIRED: THE ARTIFACT INVENTORY MUST BE FILLED",
        "   Section 2 names every planned instruction artifact with its KIND and a one-line justification.",
        "   Kind is a field, never a template fork — this template is kind-agnostic by invariant (PF-PRO-064).",
        "   Shipped instructions are source: they live under paths.source_code and carry no document ID.",
        ""
    )
    if ($Description -ne "") { $details += "Description: $Description" }
    if (-not $OpenInEditor)  { $details += "Customization required — see the Instruction Design task definition (tasks/02-design/instruction-design-task.md)" }
    if ($result.StateFileResult) {
        $sf = $result.StateFileResult
        $details += "State file §4 Documentation Inventory: $($sf.Action) at line $($sf.LineNumber)"
    }

    Write-ProjectSuccess -Message "Created Instruction Design Document with ID: $($result.DocumentId)" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Instruction Design Document: $($_.Exception.Message)" -ExitCode 1
}
