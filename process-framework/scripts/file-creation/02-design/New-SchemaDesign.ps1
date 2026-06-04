# New-SchemaDesign.ps1
# Creates a new Database Schema Design document with an automatically assigned ID.
#
# Refactored 2026-05-08 (PF-PRO-002 Phase 2 / option B): orchestration delegated
# to Invoke-DesignArtifactCreation in Common-ScriptHelpers/DesignArtifactCreation.psm1.

<#
.SYNOPSIS
    Creates a new Database Schema Design document (PD-SCH-XXX).

.DESCRIPTION
    Generates a Schema Design document, appends to PD-documentation-map.md,
    and (when -FeatureId is provided) updates master Status and inserts a row
    into the feature state file's §4 ▸ Design Documentation table.

.PARAMETER FeatureName
    Feature requiring schema changes.

.PARAMETER SchemaType
    Type of schema change: New, Modification, or Optimization.

.PARAMETER Description
    Optional free-text description.

.PARAMETER FeatureId
    Optional feature ID — when provided, master Status + state-file §4 row are
    updated; when empty, only the doc + docmap are touched.

.PARAMETER OpenInEditor
    Open the created document in the default editor.

.PARAMETER DryRun
    Preview the entire pipeline without performing any writes.
    Equivalent to -WhatIf (PF-IMP-785).
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]  [string]$FeatureName,
    [Parameter(Mandatory = $true)]  [ValidateSet("New", "Modification", "Optimization")] [string]$SchemaType,
    [Parameter(Mandatory = $false)] [string]$Description = "",
    [Parameter(Mandatory = $false)] [string]$FeatureId = "",
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
$additionalMetadataFields = @{
    "feature_name" = ConvertTo-KebabCase -InputString $FeatureName
    "schema_type"  = $SchemaType.ToLower()
}
if ($FeatureId -ne "") { $additionalMetadataFields["feature_id"] = $FeatureId }

$customReplacements = @{
    "[Feature Name]" = $FeatureName
    "[Schema Type]"  = $SchemaType
    "[Description]"  = if ($Description -ne "") { $Description } else { "Schema design for $FeatureName feature" }
}

$documentName = if ($FeatureId -ne "") { "$FeatureId-$FeatureName" } else { $FeatureName }
$schemaSlug = ConvertTo-FeatureSlug -Name $documentName -Convention 'kebab-case'
$customFileName = "$schemaSlug.md"
$schemaRelativePath = "doc/technical/database/schemas/$customFileName"

$templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/02-design/schema-design-template.md"

# ---- Compute next master Status (only when FeatureId given) ----
# Reads design requirements from the feature's tier assessment (PF-IMP-766).
# Branches to "🔌 Needs API Design" if API design is still required, else falls
# through to "📝 Needs TDD" (Tier 2+) or "🔧 Needs Impl Plan" (Tier 1).
$nextStatus = ""
if ($FeatureId -ne "") {
    $nextStatus = Get-NextStatusAfterDesignArtifact -FeatureId $FeatureId -CurrentArtifact 'SchemaDesign'
}

# ---- Delegate orchestration ----
try {
    $invokeArgs = @{
        ArtifactType               = "Schema Design"
        IdPrefix                   = "PD-SCH"
        IdDescription              = "Schema design for $SchemaType changes in ${FeatureName}"
        TemplatePath               = $templatePath
        FileNamePattern            = $customFileName
        DocumentName               = $documentName
        DirectoryType              = "schemas"
        FeatureName                = $FeatureName
        Replacements               = $customReplacements
        AdditionalMetadataFields   = $additionalMetadataFields
        DocMapSectionHeader        = "### ``technical/database/schemas/``"
        DocMapEntryFormatter       = { param($id) "- [Schema: $FeatureName ($id)](technical/database/schemas/$customFileName) - $SchemaType schema for $FeatureName" }
        OpenInEditor               = $OpenInEditor
        DryRun                     = $DryRun
        CallerCmdlet               = $PSCmdlet
    }
    if ($FeatureId -ne "") {
        $invokeArgs['FeatureId']                  = $FeatureId
        $invokeArgs['ArtifactRelativePath']       = $schemaRelativePath
        $invokeArgs['NewMasterStatus']            = $nextStatus
        $invokeArgs['MasterStatusNotesFormatter'] = { param($id) "Database schema design created: $id ($(Get-ProjectTimestamp -Format 'Date')) - $SchemaType schema for $FeatureName" }
    }
    $result = Invoke-DesignArtifactCreation @invokeArgs

    # ---- Display ----
    $details = @(
        "Feature: $FeatureName",
        "Schema Type: $SchemaType"
    )
    if ($Description -ne "") { $details += "Description: $Description" }
    if (-not $OpenInEditor) {
        $details += "Customization required — see process-framework/guides/02-design/schema-design-creation-guide.md"
    }
    if ($result.DocMapUpdated)   { $details += "Documentation Map: Updated (PD-documentation-map.md)" }
    if ($result.StateFileResult) {
        $sf = $result.StateFileResult
        $details += "State file §4 Documentation Inventory: $($sf.Action) at line $($sf.LineNumber)"
    }

    Write-ProjectSuccess -Message "Created Database Schema Design with ID: $($result.DocumentId)" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Database Schema Design: $($_.Exception.Message)" -ExitCode 1
}
