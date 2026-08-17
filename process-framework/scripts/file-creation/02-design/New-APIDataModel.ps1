# New-APIDataModel.ps1
# Creates a new API Data Model document (PD-API-NNN) carrying a description:
# frontmatter line (rendered by the generated PD map) and inserting a row into the
# feature state file's §4 Documentation Inventory. Orchestration is delegated to
# Invoke-DesignArtifactCreation in Common-ScriptHelpers/DesignArtifactCreation.psm1.

<#
.SYNOPSIS
    Creates a new API Data Model document (PD-API-XXX).

.PARAMETER ModelName
    Name of the data model (e.g. "User Profile", "Authentication Request").

.PARAMETER ModelDescription
    Brief description of what this model represents.

.PARAMETER ApiVersion
    API version. Default: "v1".

.PARAMETER RelatedEndpoints
    Comma-separated list of API endpoints that use this model.

.PARAMETER FeatureId
    Optional feature ID for state-file linkage.

.PARAMETER OpenInEditor
.PARAMETER DryRun
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory=$true)]  [string]$ModelName,
    [Parameter(Mandatory=$true)]  [string]$ModelDescription,
    [Parameter(Mandatory=$false)] [string]$ApiVersion = "v1",
    [Parameter(Mandatory=$false)] [string]$RelatedEndpoints = "",
    [Parameter(Mandatory=$false)] [string]$FeatureId = "",
    [Parameter(Mandatory=$false)] [switch]$OpenInEditor,
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

# ---- Per-type composition ----
$additionalMetadataFields = @{
    "api_version"       = $ApiVersion
    "related_endpoints" = $RelatedEndpoints
}
if ($FeatureId -ne "") { $additionalMetadataFields["feature_id"] = $FeatureId }
$additionalMetadataFields["description"] = "API data model: $ModelName ($ApiVersion)"

$customReplacements = @{
    "[Data Model Name]"                                       = $ModelName
    "[Brief description of what this data model represents]"  = $ModelDescription
    "[When and where this data model is used]"                = if ($RelatedEndpoints -ne "") { "Used in API endpoints: $RelatedEndpoints" } else { "Data model for $ModelName" }
    "[API version this model applies to]"                     = $ApiVersion
    "[List of related API endpoints]"                         = $RelatedEndpoints
    "[CREATION_DATE]"                                         = Get-Date -Format "yyyy-MM-dd"
}

$modelSlug = ConvertTo-FeatureSlug -Name $ModelName -Convention 'kebab-case'
$customFileName = "$modelSlug-data-model.md"
$modelRelativePath = "doc/technical/api/models/$customFileName"

$templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/02-design/api-data-model-template.md"

# ---- Delegate orchestration ----
try {
    $invokeArgs = @{
        ArtifactType               = "API Data Model"
        IdPrefix                   = "PD-API"
        IdDescription              = "API Data Model for $ModelName"
        TemplatePath               = $templatePath
        FileNamePattern            = $customFileName
        DocumentName               = $ModelName
        DirectoryType              = "models"
        FeatureName                = $ModelName
        Replacements               = $customReplacements
        AdditionalMetadataFields   = $additionalMetadataFields
        OpenInEditor               = $OpenInEditor
        DryRun                     = $DryRun
    }
    if ($FeatureId -ne "") {
        $invokeArgs['FeatureId']                  = $FeatureId
        $invokeArgs['ArtifactRelativePath']       = $modelRelativePath
        # No master Status transition — data models don't drive status changes
        # (only API specs / DB schemas / UI designs do). The §4 row still gets inserted.
        $invokeArgs['MasterStatusNotesFormatter'] = { param($id) "API data model created: $id ($(Get-ProjectTimestamp -Format 'Date')) - $ApiVersion data model for $ModelName" }
    }
    $result = Invoke-DesignArtifactCreation @invokeArgs

    # ---- Display ----
    $details = @(
        "Model Name: $ModelName",
        "API Version: $ApiVersion"
    )
    if ($ModelDescription -ne "") { $details += "Description: $ModelDescription" }
    if ($RelatedEndpoints -ne "") { $details += "Related Endpoints: $RelatedEndpoints" }
    if (-not $OpenInEditor) {
        $details += @(
            "Customization required — apply the api-design craft skill (.claude/skills/api-design/, references/api-data-model.md), activated by the API Design task's Check Recommended Skills step",
            "",
            "Next steps:",
            "1. Define the core data structure and field definitions",
            "2. Specify validation rules and data constraints",
            "3. Add realistic examples for request/response data",
            "4. Document relationships with other data models",
            "5. Link to related API specification documents"
        )
    }
    if ($result.StateFileResult) {
        $sf = $result.StateFileResult
        $details += "State file §4 Documentation Inventory: $($sf.Action) at line $($sf.LineNumber)"
    }

    Write-ProjectSuccess -Message "Created API Data Model with ID: $($result.DocumentId)" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create API Data Model: $($_.Exception.Message)" -ExitCode 1
}
