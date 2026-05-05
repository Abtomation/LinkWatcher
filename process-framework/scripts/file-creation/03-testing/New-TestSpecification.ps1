# New-TestSpecification.ps1
# Creates a new Test Specification with an automatically assigned ID
# Uses the central ID registry system and standardized document creation
# Supports both feature-specific and cross-cutting test specifications

<#
.SYNOPSIS
    Creates a new Test Specification document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Test Specification documents by:
    - Generating a unique document ID (PF-TSP-XXX)
    - Creating a properly formatted test specification file
    - Updating the ID tracker in the central ID registry
    - Updating feature tracking with test specification link and status
    - Providing a complete template for test specification creation from TDDs
    Supports two modes:
    - Feature-specific (default): Creates a single-feature test spec in feature-specs/
    - Cross-cutting (-CrossCutting): Creates a multi-feature test spec in cross-cutting-specs/

    Note: This script creates the specification document and updates feature tracking.
    SC-007: test-registry.yaml entry creation removed — cross-cutting relationships
    are tracked via pytest markers in test files.
    Test implementation tracking files are updated separately during the Test Implementation Task.

.PARAMETER FeatureId
    The feature ID that this test specification is for (e.g., "1.2.3").
    Used in feature-specific mode. In cross-cutting mode, this is the primary feature.

.PARAMETER FeatureName
    The name of the feature or cross-cutting scenario being specified for testing

.PARAMETER TddPath
    Path to the Technical Design Document that this test specification is based on

.PARAMETER CrossCutting
    Switch to create a cross-cutting test specification covering multiple features.
    When set, uses the cross-cutting template and outputs to cross-cutting-specs/.

.PARAMETER FeatureIds
    Comma-separated list of all feature IDs covered by this cross-cutting spec.
    Required when -CrossCutting is set. Example: "0.1.1,1.1.2,2.2.1"
    The first ID is treated as the primary feature for tracking purposes.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    New-TestSpecification.ps1 -FeatureId "1.2.3" -FeatureName "user-authentication" -TddPath "doc/technical/architecture/design-docs/tdd/tdd-user-auth.md"

.EXAMPLE
    New-TestSpecification.ps1 -CrossCutting -FeatureIds "0.1.1,1.1.2,2.2.1" -FeatureName "file-movement-pipeline" -TddPath ""

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Template Metadata:
    - Template ID: PF-TEM-020 (based on document creation script template)
    - Template Type: Document Creation Script
    - Created: 2025-07-13
    - Updated: 2026-02-20 (added cross-cutting support)
    - For: Creating test specification documents from TDDs
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$FeatureId,

    [Parameter(Mandatory=$true)]
    [string]$FeatureName,

    [Parameter(Mandatory=$false)]
    [string]$TddPath = "",

    [Parameter(Mandatory=$false)]
    [switch]$CrossCutting,

    [Parameter(Mandatory=$false)]
    [string]$FeatureIds = "",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
try {
    Invoke-StandardScriptInitialization
} catch {
    Write-Warning "Standard initialization not available, proceeding with basic setup"
    $ErrorActionPreference = "Stop"
}

# Get project root
$projectRoot = Get-ProjectRoot

# --- Validate parameters based on mode ---
if ($CrossCutting) {
    if ([string]::IsNullOrWhiteSpace($FeatureIds)) {
        Write-Error "The -FeatureIds parameter is required when using -CrossCutting. Provide comma-separated feature IDs (e.g., '0.1.1,1.1.2,2.2.1')."
        exit 1
    }
    # Parse feature IDs
    $featureIdArray = $FeatureIds -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    if ($featureIdArray.Count -lt 2) {
        Write-Error "Cross-cutting specifications require at least 2 feature IDs. Got: $($featureIdArray.Count)"
        exit 1
    }
    # Use the first feature ID as primary if FeatureId not explicitly set
    if ([string]::IsNullOrWhiteSpace($FeatureId)) {
        $FeatureId = $featureIdArray[0]
    }
    Write-Host "📋 Cross-cutting mode: $($featureIdArray.Count) features ($($featureIdArray -join ', '))" -ForegroundColor Cyan
} else {
    if ([string]::IsNullOrWhiteSpace($FeatureId)) {
        Write-Error "The -FeatureId parameter is required for feature-specific specifications."
        exit 1
    }
    $featureIdArray = @($FeatureId)
}


# Soak verification opt-in (PF-PRO-028 v2.0 Pattern B; helper-routed armoring via DocumentManagement.psm1).
# Caller-aware no-arg form: helper resolves this script's path via Get-PSCallStack.
# Idempotent — silently no-ops if already registered.
Register-SoakScript

# --- Select template and output directory based on mode ---
if ($CrossCutting) {
    $templatePath = Join-Path $projectRoot "process-framework/templates/03-testing/cross-cutting-test-specification-template.md"
    $outputDirectory = Join-Path $projectRoot "test/specifications/cross-cutting-specs"
    $documentName = "cross-cutting-spec-$FeatureName"
} else {
    $templatePath = Join-Path $projectRoot "process-framework/templates/03-testing/test-specification-template.md"
    $outputDirectory = Join-Path $projectRoot "test/specifications/feature-specs"
    $documentName = "test-spec-$FeatureId-$FeatureName"
}

# Verify template exists
if (-not (Test-Path $templatePath)) {
    Write-Error "Template not found: $templatePath"
    exit 1
}

# --- Prepare metadata and replacements ---
if ($CrossCutting) {
    $featureIdsYaml = ($featureIdArray | ForEach-Object { "`"$_`"" }) -join ', '
    $additionalMetadataFields = @{
        "feature_ids" = "[$featureIdsYaml]"
        "test_name" = $FeatureName
        "test_type" = "cross-cutting"
    }
    $customReplacements = @{
        "[FEATURE-ID-1, FEATURE-ID-2, ...]" = $featureIdArray -join ', '
        "[FEATURE-ID-1]" = $featureIdArray[0]
        "[FEATURE-ID]" = $featureIdArray -join ', '
        "[TEST-NAME]" = $FeatureName
        "[CREATION-DATE]" = (Get-Date -Format "yyyy-MM-dd")
    }
} else {
    $additionalMetadataFields = @{
        "feature_id" = $FeatureId
        "feature_name" = $FeatureName
        "tdd_path" = $TddPath
    }
    $customReplacements = @{
        "[FEATURE-ID]" = $FeatureId
        "[FEATURE-NAME]" = $FeatureName
        "[TDD-PATH]" = if ($TddPath -ne "") { $TddPath } else { "[Path to Technical Design Document]" }
        "[CREATION-DATE]" = (Get-Date -Format "yyyy-MM-dd")
    }
}

# --- Create the document ---
try {
    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "TE-TSP" -IdDescription "test-spec-$FeatureName" -DocumentName $documentName -OutputDirectory $outputDirectory -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # --- Update feature tracking ---
    try {
        $kebabName = ConvertTo-KebabCase -InputString $documentName
        $actualFileName = "$kebabName.md"
        $documentPath = Join-Path $outputDirectory $actualFileName

        $trackingMetadata = @{
            "feature_id" = $FeatureId
            "feature_name" = $FeatureName
            "tdd_path" = $TddPath
        }

        Write-Host "📊 Updating feature tracking..." -ForegroundColor Cyan
        Update-DocumentTrackingFiles -DocumentId $documentId -DocumentType "TestSpecification" -DocumentPath $documentPath -Metadata $trackingMetadata
    }
    catch {
        Write-Warning "Failed to update feature tracking files: $($_.Exception.Message)"
        Write-Host "📋 Manual feature tracking updates may be required" -ForegroundColor Yellow
    }

    # --- (Removed) test-registry.yaml entry for cross-cutting specs ---
    # SC-007: test-registry.yaml has been retired. Cross-cutting relationships are tracked
    # via pytest `cross_cutting` markers in test files and `specification` markers linking
    # to spec documents. No registry write needed.

    # --- Provide success details ---
    $details = @(
        "Specification ID: $documentId",
        "Feature Name: $FeatureName"
    )

    if ($CrossCutting) {
        $details += "Mode: Cross-cutting"
        $details += "Features: $($featureIdArray -join ', ')"
        $details += "Output: $outputDirectory"
    } else {
        $details += "Feature ID: $FeatureId"
    }

    if ($TddPath -ne "") {
        $details += "TDD Path: $TddPath"
    }

    if (-not $OpenInEditor) {
        $details += "Customization required — see process-framework/guides/03-testing/test-specification-creation-guide.md"
    }

    # Auto-append entry to TE-documentation-map.md under the correct Test Specifications section
    if ($documentId -or $WhatIfPreference) {
        $teDocMapPath = Join-Path -Path (Get-ProjectRoot) -ChildPath "test/TE-documentation-map.md"
        $kebabDocName = ConvertTo-KebabCase -InputString $documentName
        if ($CrossCutting) {
            $sectionHeader = "### ``specifications/cross-cutting-specs/``"
            $relativePath = "specifications/cross-cutting-specs/$kebabDocName.md"
            $entryLine = "- [Cross-Cutting Test Spec: $FeatureName ($documentId)]($relativePath) - Cross-cutting — $FeatureName"
        }
        else {
            $sectionHeader = "### ``specifications/feature-specs/``"
            $relativePath = "specifications/feature-specs/$kebabDocName.md"
            $entryLine = "- [Test Spec: $FeatureName ($documentId)]($relativePath) - $FeatureId — $FeatureName"
        }

        $updated = Add-DocumentationMapEntry -DocMapPath $teDocMapPath -SectionHeader $sectionHeader -EntryLine $entryLine -CallerCmdlet $PSCmdlet
        if ($updated) {
            $details += "Documentation Map: Updated (TE-documentation-map.md)"
        }
    }

    Write-ProjectSuccess -Message "Created Test Specification with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Test Specification: $($_.Exception.Message)" -ExitCode 1
}
