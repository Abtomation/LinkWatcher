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
    - For cross-cutting specs: adding a placeholder entry to test-registry.yaml

    Supports two modes:
    - Feature-specific (default): Creates a single-feature test spec in feature-specs/
    - Cross-cutting (-CrossCutting): Creates a multi-feature test spec in cross-cutting-specs/

    Note: This script creates the specification document and updates feature tracking.
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
    .\New-TestSpecification.ps1 -FeatureId "1.2.3" -FeatureName "user-authentication" -TddPath "doc/product-docs/technical/architecture/design-docs/tdd/tdd-user-auth.md"

.EXAMPLE
    .\New-TestSpecification.ps1 -CrossCutting -FeatureIds "0.1.1,1.1.2,2.2.1" -FeatureName "file-movement-pipeline" -TddPath ""

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - Cross-cutting mode adds a placeholder entry to test-registry.yaml

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
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

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

# --- Select template and output directory based on mode ---
if ($CrossCutting) {
    $templatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/cross-cutting-test-specification-template.md"
    $outputDirectory = Join-Path $projectRoot "test/specifications/cross-cutting-specs"
    $documentName = "cross-cutting-spec-$FeatureName"
} else {
    $templatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/test-specification-template.md"
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
    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-TSP" -IdDescription "test-spec-$FeatureName" -DocumentName $documentName -OutputDirectory $outputDirectory -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

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

    # --- Add test-registry.yaml entry for cross-cutting specs ---
    if ($CrossCutting) {
        try {
            Write-Host "`n🔄 Adding cross-cutting entry to test-registry.yaml..." -ForegroundColor Cyan
            $testRegistryPath = Join-Path $projectRoot "test/test-registry.yaml"

            if (Test-Path $testRegistryPath) {
                $registryContent = Get-Content $testRegistryPath -Raw -Encoding UTF8

                # Find the highest PD-TST ID in the registry
                $maxId = 0
                $idMatches = [regex]::Matches($registryContent, 'PD-TST-(\d+)')
                foreach ($match in $idMatches) {
                    $currentId = [int]$match.Groups[1].Value
                    if ($currentId -gt $maxId) { $maxId = $currentId }
                }
                $nextTestId = $maxId + 1
                $testFileId = "PD-TST-{0:D3}" -f $nextTestId

                # Build the cross-cutting features YAML array
                $crossCuttingYaml = ($featureIdArray | ForEach-Object { "`"$_`"" }) -join ', '

                # Build the relative spec path from test/ directory
                $relativeSpecPath = "specifications/cross-cutting-specs/$actualFileName"

                # Build the YAML entry in our list format
                $timestamp = Get-Date -Format "yyyy-MM-dd"
                $yamlEntry = @"

  # Cross-cutting specification: $FeatureName
  - id: $testFileId
    featureId: "$FeatureId"
    fileName: $actualFileName
    filePath: $relativeSpecPath
    testType: cross-cutting
    componentName: $FeatureName
    specificationPath: $relativeSpecPath
    description: "Cross-cutting test specification covering features: $($featureIdArray -join ', ')"
    created: $timestamp
    updated: $timestamp
    status: "📝 Specification Created"
    testCasesCount: 0
    tier:
    tddPath: $TddPath
    crossCuttingFeatures: [$crossCuttingYaml]
"@

                # Append the entry to the end of the file
                $registryContent = $registryContent.TrimEnd() + "`n" + $yamlEntry + "`n"
                Set-Content $testRegistryPath $registryContent -Encoding UTF8 -NoNewline

                # Update id-registry.json PD-TST nextAvailable
                try {
                    $idRegistryPath = Join-Path $projectRoot "doc/id-registry.json"
                    $idRegistry = Get-Content $idRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
                    $newNext = $nextTestId + 1
                    $idRegistry.prefixes.'PD-TST'.nextAvailable = $newNext
                    $idRegistry | ConvertTo-Json -Depth 10 | Set-Content $idRegistryPath -Encoding UTF8
                    Write-Host "  📝 Updated id-registry.json PD-TST nextAvailable to $newNext" -ForegroundColor Green
                }
                catch {
                    Write-Warning "Failed to update id-registry.json: $($_.Exception.Message)"
                    Write-Host "  Manual update required: PD-TST nextAvailable should be $($nextTestId + 1)" -ForegroundColor Yellow
                }

                Write-Host "  ✅ Registry entry created: $testFileId (cross-cutting)" -ForegroundColor Green
                Write-Host "  📋 Features: $($featureIdArray -join ', ')" -ForegroundColor Green
                Write-Host "  📝 Status: Specification Created (pending test implementation)" -ForegroundColor Green
            } else {
                Write-Warning "test-registry.yaml not found at $testRegistryPath — skipping registry entry"
            }
        }
        catch {
            Write-Warning "Failed to add test-registry entry: $($_.Exception.Message)"
            Write-Host "Manual registry update required for cross-cutting spec" -ForegroundColor Yellow
        }
    }

    # --- Provide success details ---
    $details = @(
        "Specification ID: $documentId",
        "Feature Name: $FeatureName"
    )

    if ($CrossCutting) {
        $details += "Mode: Cross-cutting"
        $details += "Features: $($featureIdArray -join ', ')"
        $details += "Output: $outputDirectory"
        if ($testFileId) {
            $details += "Registry Entry: $testFileId"
        }
    } else {
        $details += "Feature ID: $FeatureId"
    }

    if ($TddPath -ne "") {
        $details += "TDD Path: $TddPath"
    }

    if (-not $OpenInEditor) {
        $details += @(
            "",
            "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - EXTENSIVE CUSTOMIZATION REQUIRED 🚨🚨🚨",
            "",
            "⚠️  IMPORTANT: This script creates ONLY a structural template/framework.",
            "⚠️  The generated file is NOT a functional document until extensively customized.",
            "⚠️  AI agents MUST follow the referenced guide to properly customize the content.",
            "",
            "📖 MANDATORY CUSTOMIZATION GUIDE:",
            "   doc/process-framework/guides/guides/test-specification-creation-guide.md",
            "🎯 FOCUS AREAS: 'Step-by-Step Instructions' and 'Quality Assurance' sections",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content.",
            ""
        )
    }

    Write-ProjectSuccess -Message "Created Test Specification with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Test Specification: $($_.Exception.Message)" -ExitCode 1
}
