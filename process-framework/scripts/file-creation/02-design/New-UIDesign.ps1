# New-UIDesign.ps1
# Creates a new UI/UX Design Document with an automatically assigned ID.
#
# Refactored 2026-05-08 (PF-PRO-002 Phase 2 / option B): orchestration delegated
# to Invoke-DesignArtifactCreation in Common-ScriptHelpers/DesignArtifactCreation.psm1.

<#
.SYNOPSIS
    Creates a new UI/UX Design Document (PD-UIX-XXX).

.DESCRIPTION
    Generates a UI Design document (carrying a description: frontmatter line rendered
    by the generated PD map), updates master Status, and inserts a row into the
    feature state file's §4 Documentation Inventory.

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

# ---- Per-type composition ----
$featureIdForFilename = $FeatureId.Replace('.', '-')
$featureNameForFilename = ConvertTo-FeatureSlug -Name $FeatureName -Convention 'kebab-case'
$customFileName = "ui-design-$featureIdForFilename-$featureNameForFilename.md"
$uiRelativePath = "doc/technical/design/ui-ux/features/$customFileName"
$templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/02-design/ui-design-template.md"

$customReplacements = @{
    "[Feature ID]"          = $FeatureId
    "[Feature Name]"        = $FeatureName
    "[Feature Description]" = if ($Description -ne "") { $Description } else { "UI/UX design specification for $FeatureName" }
    "[Date]"                = Get-Date -Format "yyyy-MM-dd"
    "[Author]"              = "AI Agent & Human Partner"
}
$additionalMetadataFields = @{
    "feature_id"   = $FeatureId
    "feature_name" = $FeatureName
    description    = "UI/UX Design Document for $FeatureName ($FeatureId)"
}

# Compute next master Status. UI Design is now a workflow gate (PF-IMP-1352):
# after the UI design is created, advance to the next remaining design gate
# (→ DB/API if somehow still pending, → "📜 Needs Instruction Design" when the
# assessment flags the fourth dimension — the normal case for a Mixed-medium
# feature, PF-PRO-064 — else "📝 Needs TDD" / "🔧 Needs Impl Plan").
# Replaces the former terminal "🎨 UI Design Created" milestone (retired in the
# same change). The creation itself is still recorded in the Notes column below.
$nextStatus = Get-NextStatusAfterDesignArtifact -FeatureId $FeatureId -CurrentArtifact 'UIDesign'

# ---- Delegate orchestration ----
try {
    $invokeArgs = @{
        ArtifactType               = "UI Design"
        IdPrefix                   = "PD-UIX"
        IdDescription              = "ui-design-$featureIdForFilename-$featureNameForFilename"
        TemplatePath               = $templatePath
        FileNamePattern            = $customFileName
        DocumentName               = $FeatureName
        DirectoryType              = "features"
        FeatureId                  = $FeatureId
        FeatureName                = $FeatureName
        Replacements               = $customReplacements
        AdditionalMetadataFields   = $additionalMetadataFields
        NewMasterStatus            = $nextStatus
        MasterStatusNotesFormatter = { param($id) "UI Design created: $id ($(Get-ProjectTimestamp -Format 'Date'))" }
        ArtifactRelativePath       = $uiRelativePath
        OpenInEditor               = $OpenInEditor
        DryRun                     = $DryRun
    }
    $result = Invoke-DesignArtifactCreation @invokeArgs

    # ---- Display ----
    $details = @(
        "Feature ID: $FeatureId",
        "Feature Name: $FeatureName",
        "",
        "🎨 CRITICAL: DESIGN GUIDELINES MUST BE CONSULTED",
        "   📖 Design Guidelines: doc/technical/design/ui-ux/design-system/design-guidelines.md (PD-UIX-001)",
        "   ⚠️  All UI Design work MUST follow the established design system patterns",
        ""
    )
    if ($Description -ne "") { $details += "Description: $Description" }
    if (-not $OpenInEditor)  { $details += "Customization required — apply the ui-design craft skill (.claude/skills/ui-design/), activated by the UI Design task's Check Recommended Skills step" }
    if ($result.StateFileResult) {
        $sf = $result.StateFileResult
        $details += "State file §4 Documentation Inventory: $($sf.Action) at line $($sf.LineNumber)"
    }

    Write-ProjectSuccess -Message "Created UI/UX Design Document with ID: $($result.DocumentId)" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create UI/UX Design Document: $($_.Exception.Message)" -ExitCode 1
}
