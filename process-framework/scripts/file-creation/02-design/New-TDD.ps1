# New-TDD.ps1
# Creates a Technical Design Document for a feature using the tier-appropriate template.
#
# Refactored 2026-05-08 (PF-PRO-002 Phase 2 / option B): orchestration delegated
# to Invoke-DesignArtifactCreation in Common-ScriptHelpers/DesignArtifactCreation.psm1.

<#
.SYNOPSIS
    Creates a Technical Design Document at the tier-appropriate complexity.

.DESCRIPTION
    Generates a TDD document file (PD-TDD-XXX) using the t1/t2/t3 template,
    appends an entry to PD-documentation-map.md, updates master Status (no
    per-feature artifact column writes per PF-PRO-002), and inserts/updates
    the TDD row in the feature state file's §4 ▸ Design Documentation table.

.PARAMETER FeatureId
    Feature ID (e.g., "1.2.3").

.PARAMETER FeatureName
    Feature human-readable name.

.PARAMETER Tier
    Complexity tier: 1 (Planning), 2 (Lightweight TDD), or 3 (Full TDD).
    Picks the matching template and appends `-tN` to the filename.

.PARAMETER OpenInEditor
    Open the created TDD in the default editor.

.PARAMETER DryRun
    Preview the entire pipeline without performing any writes.
    Equivalent to -WhatIf (PF-IMP-785).

.EXAMPLE
    .\New-TDD.ps1 -FeatureId "1.2.3" -FeatureName "User Authentication" -Tier 2
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$true)] [string]$FeatureId,
    [Parameter(Mandatory=$true)] [string]$FeatureName,
    [Parameter(Mandatory=$true)] [ValidateSet("1", "2", "3")] [string]$Tier,
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
$templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/02-design/tdd-t$Tier-template.md"
if (-not (Test-Path $templatePath)) {
    Write-ProjectError -Message "Template for Tier $Tier not found at $templatePath" -ExitCode 1
}

$safeFeatureName = ConvertTo-KebabCase -InputString $FeatureName
$safeFeatureId = $FeatureId -replace '\.', '-'
$customFileName = "tdd-$safeFeatureId-$safeFeatureName-t$Tier.md"
$tddRelativePath = "doc/technical/architecture/design-docs/tdd/$customFileName"

$customReplacements = @{
    '[Feature Name]' = $FeatureName
    '[FEATURE_ID]'   = $FeatureId
}
$additionalMetadataFields = @{
    "feature_id" = $FeatureId
    "tier"       = $Tier
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
        DocMapSectionHeader        = "### ``technical/tdd/`` — Technical Design Documents (TDDs)"
        DocMapEntryFormatter       = { param($id) "- [TDD: $FeatureName ($id)](technical/tdd/$customFileName) - $FeatureId Tier $Tier — $($tierNames[$Tier])" }
        NewMasterStatus            = "🧪 Needs Test Spec"
        MasterStatusNotesFormatter = { param($id) "TDD created: $id ($(Get-ProjectTimestamp -Format 'Date'))" }
        ArtifactRelativePath       = $tddRelativePath
        OpenInEditor               = $OpenInEditor
        DryRun                     = $DryRun
        CallerCmdlet               = $PSCmdlet
    }
    $result = Invoke-DesignArtifactCreation @invokeArgs

    # ---- Display ----
    $details = @(
        "Feature: $FeatureId - $FeatureName",
        "Tier: $($tierNames[$Tier])",
        "",
        "The document includes an AI Agent Session Handoff Notes section for maintaining context between development sessions."
    )
    if (-not $OpenInEditor) {
        $details += @(
            "",
            "🚨 MANDATORY NEXT STEP: TDD Creation Guide Review Required",
            "   You MUST consult the TDD Creation Guide before proceeding.",
            "",
            "📖 REQUIRED READING:",
            "process-framework/guides/02-design/tdd-creation-guide.md",
            "   Focus on: 'Step-by-Step Instructions' and 'Quality Assurance' sections",
            "",
            "⚠️  The created file is only a structural framework - it requires extensive",
            "   customization following the guide's instructions to become functional."
        )
    }
    if ($result.DocMapUpdated)    { $details += "Documentation Map: Updated (PD-documentation-map.md)" }
    if ($result.StateFileResult)  {
        $sf = $result.StateFileResult
        $details += "State file §4 Documentation Inventory: $($sf.Action) at line $($sf.LineNumber)"
    }

    Write-ProjectSuccess -Message "Created $($tierNames[$Tier]) with ID: $($result.DocumentId)" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create TDD: $($_.Exception.Message)" -ExitCode 1
}
