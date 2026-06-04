# New-APISpecification.ps1
# Creates a new API Specification document with an automatically assigned ID.
#
# Refactored 2026-05-08 (PF-PRO-002 Phase 2 / option B): orchestration delegated
# to Invoke-DesignArtifactCreation. The legacy "append with bullet separator"
# logic for the master `API Design` column is dropped — each API specification
# now becomes its own row in the feature state file's §4 Documentation
# Inventory, keyed on PD-API-NNN.

<#
.SYNOPSIS
    Creates a new API Specification document (PD-API-XXX).

.PARAMETER APIName
    Name of the API being specified.

.PARAMETER APIDescription
    Brief description of the API's purpose.

.PARAMETER APIType
    Type of API (REST, GraphQL, gRPC, Service Interface). Default: REST.

    Drives template selection:
      - "Service Interface"           → api-specification-service-interface-template.md (PF-TEM-078)
                                        Use for subprocess invocations, COM/in-process integrations,
                                        file-system contracts, and library contracts where the
                                        REST endpoint/auth/status-code model is structurally wrong.
      - "REST" / "GraphQL" / "gRPC" / anything else
                                      → api-specification-template.md (PF-TEM-021)
                                        REST is the canonical use; GraphQL and gRPC silently
                                        fall through to the REST template until dedicated variants ship.

.PARAMETER FeatureId
    Optional feature ID to link the spec to. When provided, the filename is
    formatted as `api-{feature-id}-{api-name}.md` and a §4 row is inserted
    into the feature's state file. When empty, only the doc + docmap are touched.

.PARAMETER OpenInEditor
.PARAMETER DryRun
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]  [string]$APIName,
    [Parameter(Mandatory = $false)] [string]$APIDescription = "",
    [Parameter(Mandatory = $false)] [string]$APIType = "REST",
    [Parameter(Mandatory = $false)] [string]$FeatureId = "",
    [Parameter(Mandatory = $false)] [switch]$OpenInEditor,
    [Parameter(Mandatory = $false)] [switch]$DryRun
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
    "api_name" = $APIName
    "api_type" = $APIType
}
if ($FeatureId -ne "") { $additionalMetadataFields["feature_id"] = $FeatureId }

$customReplacements = @{
    "[API_NAME]"        = $APIName
    "[API_DESCRIPTION]" = if ($APIDescription -ne "") { $APIDescription } else { "API specification for $APIName" }
    "[API_TYPE]"        = $APIType
    "[CREATION_DATE]"   = Get-Date -Format "yyyy-MM-dd"
}

# Filename: when FeatureId is provided, prefix with feature id; otherwise let
# New-StandardProjectDocument compose from the document name.
$apiSlug = ConvertTo-FeatureSlug -Name $APIName -Convention 'kebab-case'
$customFileName = if ($FeatureId -ne "") { "api-$FeatureId-$apiSlug.md" } else { "$apiSlug.md" }
$specRelativePath = "doc/technical/api/specifications/$customFileName"

# Dispatch template path on -APIType (PF-PRO-004 / PF-IMP-016)
$templateFile = switch ($APIType) {
    'Service Interface' { 'api-specification-service-interface-template.md' }
    default             { 'api-specification-template.md' }
}
$templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/02-design/$templateFile"

# ---- Next master Status (only when FeatureId provided) ----
# Reads design requirements from the feature's tier assessment (PF-IMP-766).
# Branches to "🗄️ Needs DB Design" if DB design is still required, else falls
# through to "📝 Needs TDD" (Tier 2+) or "🔧 Needs Impl Plan" (Tier 1).
$nextStatus = ""
if ($FeatureId -ne "") {
    $nextStatus = Get-NextStatusAfterDesignArtifact -FeatureId $FeatureId -CurrentArtifact 'APISpecification'
}

# ---- Delegate orchestration ----
try {
    $invokeArgs = @{
        ArtifactType               = "API Specification"
        IdPrefix                   = "PD-API"
        IdDescription              = "API Specification for $APIName"
        TemplatePath               = $templatePath
        FileNamePattern            = $customFileName
        DocumentName               = $APIName
        DirectoryType              = "specifications"
        FeatureName                = $APIName
        Replacements               = $customReplacements
        AdditionalMetadataFields   = $additionalMetadataFields
        DocMapSectionHeader        = "### ``technical/api/specifications/``"
        DocMapEntryFormatter       = { param($id) "- [API Spec: $APIName ($id)](technical/api/specifications/$customFileName) - $APIType API for $APIName" }
        OpenInEditor               = $OpenInEditor
        DryRun                     = $DryRun
        CallerCmdlet               = $PSCmdlet
    }
    if ($FeatureId -ne "") {
        $invokeArgs['FeatureId']                  = $FeatureId
        $invokeArgs['ArtifactRelativePath']       = $specRelativePath
        $invokeArgs['NewMasterStatus']            = $nextStatus
        $invokeArgs['MasterStatusNotesFormatter'] = { param($id) "API specification created: $id ($(Get-ProjectTimestamp -Format 'Date')) - $APIType API for $APIName" }
    }
    $result = Invoke-DesignArtifactCreation @invokeArgs

    # ---- Display ----
    $details = @(
        "API Name: $APIName",
        "API Type: $APIType"
    )
    if ($APIDescription -ne "") { $details += "Description: $APIDescription" }
    if (-not $OpenInEditor) {
        $details += @(
            "Customization required — see process-framework/guides/02-design/api-specification-creation-guide.md",
            "",
            "Next steps:",
            "1. Complete the API specification with endpoint definitions",
            "2. Define request/response schemas and data models",
            "3. Specify error handling patterns and status codes",
            "4. Document authentication and authorization requirements",
            "5. Create API documentation for consumers"
        )
    }
    if ($result.DocMapUpdated)   { $details += "Documentation Map: Updated (PD-documentation-map.md)" }
    if ($result.StateFileResult) {
        $sf = $result.StateFileResult
        $details += "State file §4 Documentation Inventory: $($sf.Action) at line $($sf.LineNumber)"
    }

    Write-ProjectSuccess -Message "Created API Specification with ID: $($result.DocumentId)" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create API Specification: $($_.Exception.Message)" -ExitCode 1
}
