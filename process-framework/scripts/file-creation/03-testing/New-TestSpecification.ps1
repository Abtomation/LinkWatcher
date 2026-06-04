# New-TestSpecification.ps1
# Creates a new Test Specification (feature-specific or cross-cutting) with an
# automatically assigned ID.
#
# Refactored 2026-05-08 (PF-PRO-002 Phase 2 / option B): orchestration delegated
# to Invoke-DesignArtifactCreation. Notable per-type config: writes to the
# *test* documentation map (TE-documentation-map.md) and updates the *Test Status*
# master column rather than the main Status column.

<#
.SYNOPSIS
    Creates a new Test Specification (TE-TSP-XXX), feature-specific or cross-cutting.

.PARAMETER FeatureId
    Feature ID for feature-specific specs. In cross-cutting mode, this is
    auto-derived from -FeatureIds (the first ID is the primary feature for
    state-file linkage).

.PARAMETER FeatureName
    Feature or cross-cutting scenario name.

.PARAMETER TddPath
    Path to the TDD this spec is based on (feature-specific mode).

    ⚠️ Windows + bash MSYS path-mangling hazard:
    Paths starting with a leading slash (/doc/...) are silently rewritten by MSYS
    to absolute Git-installation paths (e.g., "C:/Program Files/Git/doc/...") before
    PowerShell sees them. ALWAYS use a relative path WITHOUT a leading slash:
      ✅ "doc/technical/architecture/design-docs/tdd/tdd-x-y-z.md"
      ❌ "/doc/technical/architecture/design-docs/tdd/tdd-x-y-z.md"     (MSYS mangles this)
    The script detects the mangled prefix at runtime and rejects, but using the
    relative form from the start avoids the failed call.

.PARAMETER CrossCutting
    Switch to create a cross-cutting spec covering multiple features. Uses
    the cross-cutting template and writes to test/specifications/cross-cutting-specs/.

.PARAMETER FeatureIds
    Comma-separated feature IDs covered by a cross-cutting spec (≥2 required).

.PARAMETER OpenInEditor
.PARAMETER DryRun
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)] [string]$FeatureId,
    [Parameter(Mandatory=$true)]  [string]$FeatureName,
    [Parameter(Mandatory=$false)] [string]$TddPath = "",
    [Parameter(Mandatory=$false)] [switch]$CrossCutting,
    [Parameter(Mandatory=$false)] [string]$FeatureIds = "",
    [Parameter(Mandatory=$false)] [switch]$OpenInEditor,
    [Parameter(Mandatory=$false)] [switch]$DryRun
)

# Walk-up Common-ScriptHelpers import
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# MSYS path-mangling guard routed through Common-ScriptHelpers (PF-IMP-767 helper extraction;
# original inline guard PF-IMP-015 mirrored Update-TechDebt.ps1 -PlanLink). Git Bash silently
# rewrites leading-slash paths (/doc/...) to "C:/Program Files/Git/..." before PowerShell
# receives them. Detect and reject so users fix the call site rather than landing the mangled
# value in spec metadata.
if (Test-MSYSPathMangled -Path $TddPath -ParameterName 'TddPath') {
    exit 1
}

try { Invoke-StandardScriptInitialization } catch { $ErrorActionPreference = "Stop" }
Register-SoakScript

# ---- Mode validation + primary FeatureId resolution ----
if ($CrossCutting) {
    if ([string]::IsNullOrWhiteSpace($FeatureIds)) {
        Write-Error "The -FeatureIds parameter is required when using -CrossCutting."
        exit 1
    }
    $featureIdArray = $FeatureIds -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    if ($featureIdArray.Count -lt 2) {
        Write-Error "Cross-cutting specifications require at least 2 feature IDs. Got: $($featureIdArray.Count)"
        exit 1
    }
    if ([string]::IsNullOrWhiteSpace($FeatureId)) { $FeatureId = $featureIdArray[0] }
    Write-Host "📋 Cross-cutting mode: $($featureIdArray.Count) features ($($featureIdArray -join ', '))" -ForegroundColor Cyan
} else {
    if ([string]::IsNullOrWhiteSpace($FeatureId)) {
        Write-Error "The -FeatureId parameter is required for feature-specific specifications."
        exit 1
    }
    $featureIdArray = @($FeatureId)
}

# ---- Per-mode: template, output dir, doc-map section, replacements, file slug ----
if ($CrossCutting) {
    $templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/03-testing/cross-cutting-test-specification-template.md"
    $outputDirectory = "test/specifications/cross-cutting-specs"
    $documentName = "cross-cutting-spec-$FeatureName"
    $docMapSection = "### ``specifications/cross-cutting-specs/``"
    $featureIdsYaml = ($featureIdArray | ForEach-Object { "`"$_`"" }) -join ', '
    $additionalMetadataFields = @{
        "feature_ids" = "[$featureIdsYaml]"
        "test_name"   = $FeatureName
        "test_type"   = "cross-cutting"
    }
    $customReplacements = @{
        "[FEATURE-ID-1, FEATURE-ID-2, ...]" = $featureIdArray -join ', '
        "[FEATURE-ID-1]"                    = $featureIdArray[0]
        "[FEATURE-ID]"                      = $featureIdArray -join ', '
        "[TEST-NAME]"                       = $FeatureName
        "[CREATION-DATE]"                   = (Get-Date -Format "yyyy-MM-dd")
    }
} else {
    $templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/03-testing/test-specification-template.md"
    $outputDirectory = "test/specifications/feature-specs"
    $documentName = "test-spec-$FeatureId-$FeatureName"
    $docMapSection = "### ``specifications/feature-specs/``"
    $additionalMetadataFields = @{
        "feature_id"   = $FeatureId
        "feature_name" = $FeatureName
        "tdd_path"     = $TddPath
    }
    $customReplacements = @{
        "[FEATURE-ID]"    = $FeatureId
        "[FEATURE-NAME]"  = $FeatureName
        "[TDD-PATH]"      = if ($TddPath -ne "") { $TddPath } else { "[Path to Technical Design Document]" }
        "[CREATION-DATE]" = (Get-Date -Format "yyyy-MM-dd")
    }
}

if (-not (Test-Path $templatePath)) {
    Write-Error "Template not found: $templatePath"
    exit 1
}

$kebabDocName = ConvertTo-KebabCase -InputString $documentName
$customFileName = "$kebabDocName.md"
$specRelativePath = "$outputDirectory/$customFileName"

# ---- Delegate orchestration ----
# Test Spec retargets to "Test Status" master column (not "Status") and
# writes to TE-documentation-map.md (not PD-).
try {
    $invokeArgs = @{
        ArtifactType               = "Test Specification"
        IdPrefix                   = "TE-TSP"
        IdDescription              = "test-spec-$FeatureName"
        TemplatePath               = $templatePath
        FileNamePattern            = $customFileName
        DocumentName               = $documentName
        OutputDirectory            = $outputDirectory
        FeatureId                  = $FeatureId
        FeatureName                = $FeatureName
        Replacements               = $customReplacements
        AdditionalMetadataFields   = $additionalMetadataFields
        DocMapPath                 = "test/TE-documentation-map.md"
        DocMapSectionHeader        = $docMapSection
        DocMapEntryFormatter       = if ($CrossCutting) {
            { param($id) "- [Cross-Cutting Test Spec: $FeatureName ($id)]($specRelativePath) - Cross-cutting — $FeatureName" }
        } else {
            { param($id) "- [Test Spec: $FeatureName ($id)]($specRelativePath) - $FeatureId — $FeatureName" }
        }
        NewMasterStatus            = "📋 Specs Created"
        MasterStatusColumn         = "Test Status"
        MasterStatusNotesFormatter = { param($id) "Test specification created: $id ($(Get-ProjectTimestamp -Format 'Date'))" }
        ArtifactRelativePath       = $specRelativePath
        OpenInEditor               = $OpenInEditor
        DryRun                     = $DryRun
        CallerCmdlet               = $PSCmdlet
    }
    $result = Invoke-DesignArtifactCreation @invokeArgs

    # ---- Display ----
    $details = @(
        "Specification ID: $($result.DocumentId)",
        "Feature Name: $FeatureName"
    )
    if ($CrossCutting) {
        $details += "Mode: Cross-cutting"
        $details += "Features: $($featureIdArray -join ', ')"
        $details += "Output: $outputDirectory"
    } else {
        $details += "Feature ID: $FeatureId"
    }
    if ($TddPath -ne "") { $details += "TDD Path: $TddPath" }
    if (-not $OpenInEditor) {
        $details += "Customization required — see process-framework/guides/03-testing/test-specification-creation-guide.md"
    }
    if ($result.DocMapUpdated)   { $details += "Documentation Map: Updated (TE-documentation-map.md)" }
    if ($result.StateFileResult) {
        $sf = $result.StateFileResult
        $details += "State file §4 Documentation Inventory: $($sf.Action) at line $($sf.LineNumber)"
    }

    Write-ProjectSuccess -Message "Created Test Specification with ID: $($result.DocumentId)" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Test Specification: $($_.Exception.Message)" -ExitCode 1
}
