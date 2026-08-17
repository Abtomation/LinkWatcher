# New-TDD.ps1
# Creates a Technical Design Document for a feature using the tier-appropriate template.
#
# Refactored 2026-05-08 (PF-PRO-002 Phase 2 / option B): orchestration delegated
# to Invoke-DesignArtifactCreation in Common-ScriptHelpers/DesignArtifactCreation.psm1.

<#
.SYNOPSIS
    Creates the terminal design document for a feature — tier-appropriate for code, instruction-shaped for a pure-instruction feature.

.DESCRIPTION
    Generates a TDD document file (PD-TDD-XXX), carrying a description: frontmatter
    line (rendered by the generated PD map), updates master Status (no per-feature
    artifact column writes per PF-PRO-002), and inserts/updates the TDD row in the
    feature state file's §4 ▸ Design Documentation table.

    Template selection forks on two independent axes (PF-PRO-064): TIER (-Tier picks
    t1/t2/t3 for a code feature) and MEDIUM (-Medium instruction picks the
    tier-agnostic instruction terminal instead). A mixed feature keeps the code TDD,
    whose Instruction Design Reference section carries its instruction half.

.PARAMETER FeatureId
    Feature ID (e.g., "1.2.3").

.PARAMETER FeatureName
    Feature human-readable name.

.PARAMETER Tier
    Complexity tier: 1 (Planning), 2 (Lightweight TDD), or 3 (Full TDD).
    Picks the matching template and appends `-tN` to the filename.
    Under -Medium instruction the tier no longer selects the template (the
    instruction terminal is tier-agnostic) but still classifies the feature and
    is still carried in the filename.

.PARAMETER Medium
    The feature's implementation medium, from its tier assessment / state file
    (PF-PRO-064). Selects the shape of the terminal design document:
      code        (default) - the tier-appropriate code TDD, unchanged
      mixed                 - the tier-appropriate code TDD, whose Instruction
                              Design Reference section points at the PD-IND
      instruction           - the tier-agnostic instruction terminal template
    A pure-instruction feature must never receive the Models/Services/Repositories
    structure of the code TDD; that is the defect this parameter exists to prevent.
    Medium is declared, never inferred: pass what the feature declares.

.PARAMETER OpenInEditor
    Open the created TDD in the default editor.

.PARAMETER DryRun
    Preview the entire pipeline without performing any writes.
    Equivalent to -WhatIf (PF-IMP-785).

.EXAMPLE
    New-TDD.ps1 -FeatureId "1.2.3" -FeatureName "User Authentication" -Tier 2

.EXAMPLE
    # Pure-instruction feature: tier-agnostic instruction terminal instead of the code TDD
    New-TDD.ps1 -FeatureId "2.1.1" -FeatureName "Application Triage" -Tier 2 -Medium instruction
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$true)] [string]$FeatureId,
    [Parameter(Mandatory=$true)] [string]$FeatureName,
    [Parameter(Mandatory=$true)] [ValidateSet("1", "2", "3")] [string]$Tier,
    [Parameter(Mandatory=$false)] [ValidateSet("code", "instruction", "mixed")] [string]$Medium = "code",
    [switch]$OpenInEditor,
    [Parameter(Mandatory=$false)] [switch]$DryRun
)

# Walk-up Common-ScriptHelpers import
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

Invoke-StandardScriptInitialization
Register-SoakScript

# ---- Per-type composition: tier-driven template + filename ----
$tierNames = @{
    "1" = "Tier 1 (Planning Document)"
    "2" = "Tier 2 (Lightweight TDD)"
    "3" = "Tier 3 (Full TDD)"
}
# Medium-aware terminal template selection (PF-PRO-064 / PF-IMP-1947, WI-5).
# The tdd-* family forks on two independent axes: TIER (how much design depth a code
# feature warrants) and MEDIUM (what the deliverable is made of). Only a PURE-instruction
# feature switches axis — a mixed feature keeps the code TDD, whose Instruction Design
# Reference section carries its instruction half. Without this, a pure-instruction feature
# reached "📝 Needs TDD" (every design gate in the router is a pass-through) and was handed
# a Models/Services/Repositories template with nothing to report the mismatch.
$templateName = if ($Medium -eq 'instruction') { 'tdd-instruction-template.md' } else { "tdd-t$Tier-template.md" }
$templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/02-design/$templateName"
if (-not (Test-Path $templatePath)) {
    $what = if ($Medium -eq 'instruction') { "Instruction-medium terminal template" } else { "Template for Tier $Tier" }
    Write-ProjectError -Message "$what not found at $templatePath" -ExitCode 1
}

$safeFeatureName = ConvertTo-KebabCase -InputString $FeatureName
$safeFeatureId = $FeatureId -replace '\.', '-'
$customFileName = "tdd-$safeFeatureId-$safeFeatureName-t$Tier.md"
$tddRelativePath = "doc/technical/architecture/design-docs/tdd/$customFileName"

$customReplacements = @{
    '[Feature Name]' = $FeatureName
    '[FEATURE_ID]'   = $FeatureId
}
# The description records the document's own SHAPE (which terminal template produced it),
# not a per-artifact medium declaration — medium is declared at exactly two levels
# (workspace config, feature assessment/state file) and artifacts inherit it (PF-PRO-064
# invariant). No `medium` metadata field is stamped here, deliberately.
$shapeNote = if ($Medium -eq 'instruction') { "instruction terminal, Tier $Tier" } else { "Tier $Tier" }
$additionalMetadataFields = @{
    "feature_id" = $FeatureId
    "tier"       = $Tier
    description  = "Technical Design Document ($shapeNote) for $FeatureName ($FeatureId)"
}

# ---- Delegate orchestration ----
try {
    $invokeArgs = @{
        ArtifactType               = "TDD"
        IdPrefix                   = "PD-TDD"
        IdDescription              = "TDD Tier $Tier for feature ${FeatureId}: ${FeatureName}"
        TemplatePath               = $templatePath
        FileNamePattern            = $customFileName
        DocumentName               = $FeatureName
        OutputDirectory            = "doc/technical/architecture/design-docs/tdd"
        FeatureId                  = $FeatureId
        FeatureName                = $FeatureName
        Replacements               = $customReplacements
        AdditionalMetadataFields   = $additionalMetadataFields
        NewMasterStatus            = "🧪 Needs Test Spec"
        MasterStatusNotesFormatter = { param($id) "TDD created: $id ($(Get-ProjectTimestamp -Format 'Date'))" }
        ArtifactRelativePath       = $tddRelativePath
        OpenInEditor               = $OpenInEditor
        DryRun                     = $DryRun
    }
    $result = Invoke-DesignArtifactCreation @invokeArgs

    # ---- Display ----
    $details = @(
        "Feature: $FeatureId - $FeatureName",
        "Tier: $($tierNames[$Tier])",
        "Medium: $Medium  (template: $templateName)",
        "",
        "The document includes an AI Agent Session Handoff Notes section for maintaining context between development sessions."
    )
    if ($Medium -eq 'instruction') {
        $details += @(
            "",
            "📜 Instruction terminal: this document is tier-agnostic — scale it by marking",
            "   sections N/A with a reason, never by forking a per-tier instruction template.",
            "   Its Instruction Design Reference (§5.2) must point at the feature's PD-IND."
        )
    }
    elseif ($Medium -eq 'mixed') {
        $details += @(
            "",
            "📜 Mixed medium: this is the CODE TDD by design. Fill its Instruction Design",
            "   Reference section so the terminal document integrates both dimensions."
        )
    }
    if (-not $OpenInEditor) {
        $details += @(
            "",
            "Customization required — apply the tdd-creation craft skill (.claude/skills/tdd-creation/),",
            "activated by the TDD Creation task's Check Recommended Skills step.",
            "",
            "⚠️  The created file is only a structural framework - it requires extensive",
            "   customization guided by the craft skill to become functional."
        )
    }
    if ($result.StateFileResult)  {
        $sf = $result.StateFileResult
        $details += "State file §4 Documentation Inventory: $($sf.Action) at line $($sf.LineNumber)"
    }

    Write-ProjectSuccess -Message "Created $($tierNames[$Tier]) with ID: $($result.DocumentId)" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create TDD: $($_.Exception.Message)" -ExitCode 1
}
