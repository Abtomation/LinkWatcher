# New-FDD.ps1
# Creates a new Functional Design Document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation
#
# Refactored 2026-05-08 (PF-PRO-002 Phase 2 / option B): orchestration delegated
# to Invoke-DesignArtifactCreation in Common-ScriptHelpers/DesignArtifactCreation.psm1.
# This wrapper now owns only what's per-type: param parsing, slug/filename
# composition, and next-master-Status computation (via Get-NextStatusAfterDesignArtifact).

<#
.SYNOPSIS
    Creates a new Functional Design Document (FDD) with an automatically assigned ID.

.DESCRIPTION
    Generates an FDD document file (PD-FDD-XXX) carrying a description: frontmatter
    line (rendered by the generated PD map), updates master Status (no per-feature
    artifact column writes per PF-PRO-002), and inserts/updates the corresponding row
    in the feature state file's §4 ▸ Design Documentation table.

.PARAMETER FeatureId
    The Feature ID from feature tracking (e.g., "1.1.1", "2.3.4")

.PARAMETER FeatureName
    The name of the feature for which the FDD is being created

.PARAMETER Description
    Optional description of the feature's purpose and scope

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.PARAMETER DryRun
    Preview the entire pipeline (doc creation, docmap append, master Status
    update, state-file §4 row) without performing any writes. Equivalent to
    -WhatIf — either flag short-circuits all side effects (PF-IMP-785).

.PARAMETER Retrospective
    Generate the FDD from the as-built retrospective sibling template
    (fdd-retrospective-template.md) instead of the forward-planning template.
    Use when documenting an already-implemented feature (e.g. during onboarding
    via the Retrospective Documentation Creation task). PF-PRO-003 pilot.

.EXAMPLE
    New-FDD.ps1 -FeatureId "1.1.1" -FeatureName "User Registration"

.EXAMPLE
    New-FDD.ps1 -FeatureId "1.1.2" -FeatureName "Customer Management" -Retrospective

.EXAMPLE
    New-FDD.ps1 -FeatureId "1.2.3" -FeatureName "Payment Processing" -Description "Stripe integration" -DryRun
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureId,

    [Parameter(Mandatory=$true)]
    [string]$FeatureName,

    [Parameter(Mandatory=$false)]
    [string]$Description = "",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$Retrospective
)

# Import the common helpers with walk-up path resolution
$dir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
try {
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers module. Searched up from: $PSScriptRoot"
    exit 1
}

Invoke-StandardScriptInitialization

# Soak verification opt-in (PF-PRO-028 v2.0 Pattern B; helper-routed armoring via DocumentManagement.psm1).
Register-SoakScript

# ---- Per-type composition: filename, template, replacements, metadata ----
$featureIdForFilename = $FeatureId.Replace('.', '-')
$featureNameForFilename = ConvertTo-FeatureSlug -Name $FeatureName -Convention 'kebab-case'
$customFileName = "fdd-$featureIdForFilename-$featureNameForFilename.md"
$fddRelativePath = "doc/functional-design/fdds/$customFileName"
# Retrospective documentation (PF-PRO-003 pilot): -Retrospective selects the as-built
# sibling template (forward-planning scaffolding stripped/reframed) instead of the forward one.
$templateFile = if ($Retrospective) { "fdd-retrospective-template.md" } else { "fdd-template.md" }
$templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/02-design/$templateFile"

$customReplacements = @{
    "[Feature Name]" = $FeatureName
    "[Feature Description]" = if ($Description -ne "") { $Description } else { "Functional specification for $FeatureName" }
    "[Date]" = Get-Date -Format "yyyy-MM-dd"
    "[Author]" = "AI Agent & Human Partner"
}

$additionalMetadataFields = @{
    "feature_id" = $FeatureId
    "feature_name" = $FeatureName
    description = "Functional Design Document for $FeatureName ($FeatureId)"
}

# Compute next master Status from the feature's tier assessment (PF-IMP-766).
# Branches to "🗄️ Needs DB Design" / "🔌 Needs API Design" if those designs are
# still required, else falls through to "📝 Needs TDD" (Tier 2+) or
# "🔧 Needs Impl Plan" (Tier 1).
$nextStatus = Get-NextStatusAfterDesignArtifact -FeatureId $FeatureId -CurrentArtifact 'FDD'

# ---- Delegate the rest to the shared core ----
# Per-type closures inlined into the splat — they capture $FeatureName,
# $customFileName, etc. from this scope and are invoked by the core after
# $documentId is assigned.

try {
    $invokeArgs = @{
        ArtifactType               = "FDD"
        IdPrefix                   = "PD-FDD"
        IdDescription              = "fdd-$featureIdForFilename-$featureNameForFilename"
        TemplatePath               = $templatePath
        FileNamePattern            = $customFileName
        DocumentName               = $FeatureName
        DirectoryType              = "fdds"
        FeatureId                  = $FeatureId
        FeatureName                = $FeatureName
        Replacements               = $customReplacements
        AdditionalMetadataFields   = $additionalMetadataFields
        NewMasterStatus            = $nextStatus
        MasterStatusNotesFormatter = { param($id) "FDD created: $id ($(Get-ProjectTimestamp -Format 'Date'))" }
        ArtifactRelativePath       = $fddRelativePath
        OpenInEditor               = $OpenInEditor
        DryRun                     = $DryRun
    }
    $result = Invoke-DesignArtifactCreation @invokeArgs

    # Replace the placeholder MasterStatusNotes after we have the real ID.
    # (Notes were already written in the core; this is a no-op for now —
    # the caller's MasterStatusNotes is informational. Future: thread the ID
    # through into Notes via formatter, like docmap.)

    # ---- Display ----
    $details = @(
        "Feature ID: $FeatureId",
        "Feature Name: $FeatureName"
    )
    if ($Description -ne "") { $details += "Description: $Description" }
    if (-not $OpenInEditor)   { $details += "Customization required — apply the fdd-creation craft skill (.claude/skills/fdd-creation/), activated by the FDD Creation task's Check Recommended Skills step" }
    if ($result.StateFileResult) {
        $sf = $result.StateFileResult
        $details += "State file §4 Documentation Inventory: $($sf.Action) at line $($sf.LineNumber)"
    }

    Write-ProjectSuccess -Message "Created Functional Design Document with ID: $($result.DocumentId)" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Functional Design Document: $($_.Exception.Message)" -ExitCode 1
}
