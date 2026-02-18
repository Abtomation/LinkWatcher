#Requires -Version 5.1

<#
.SYNOPSIS
    Creates a new foundational codebase validation report from template.

.DESCRIPTION
    This script generates a new validation report for foundational features using the
    standardized validation report template. It automatically assigns IDs, creates the
    report in the appropriate subdirectory, and updates the validation tracking file.

.PARAMETER ValidationType
    The type of validation being performed. Must be one of:
    - ArchitecturalConsistency
    - CodeQuality
    - IntegrationDependencies
    - DocumentationAlignment
    - ExtensibilityMaintainability
    - AIAgentContinuity

.PARAMETER FeatureIds
    Comma-separated list of feature IDs to validate (e.g., "0.2.1,0.2.2,0.2.3")

.PARAMETER BatchNumber
    Optional batch number for organizing reports (default: 1)

.PARAMETER SessionNumber
    Optional session number for this validation type (default: 1)

.EXAMPLE
    ../../../../../../validation/New-ValidationReport.ps1 -ValidationType "ArchitecturalConsistency" -FeatureIds "0.2.1,0.2.2,0.2.3"

    Creates an architectural consistency validation report for features 0.2.1-0.2.3

.EXAMPLE
    ../../../../../../validation/New-ValidationReport.ps1 -ValidationType "CodeQuality" -FeatureIds "0.2.4,0.2.5" -BatchNumber 2 -SessionNumber 2

    Creates a code quality validation report for features 0.2.4-0.2.5 in batch 2, session 2

.NOTES
    Author: AI Framework Extension
    Version: 1.0
    Created: 2025-08-15

    This script is part of the Foundational Codebase Validation Framework.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("ArchitecturalConsistency", "CodeQuality", "IntegrationDependencies",
        "DocumentationAlignment", "ExtensibilityMaintainability", "AIAgentContinuity")]
    [string]$ValidationType,

    [Parameter(Mandatory = $true)]
    [string]$FeatureIds,

    [Parameter(Mandatory = $false)]
    [int]$BatchNumber = 1,

    [Parameter(Mandatory = $false)]
    [int]$SessionNumber = 1
)

# Configuration
$ErrorActionPreference = "Stop"

# Get script directory for relative path resolution
$ScriptDirectory = if ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}

# Resolve paths relative to script location
$TemplateFile = Join-Path $ScriptDirectory "../../templates/templates/validation-report-template.md"
$TrackingFile = Join-Path $ScriptDirectory "../../state-tracking/temporary/foundational-validation-tracking.md"
$IdRegistryFile = Join-Path $ScriptDirectory "../../../id-registry.json"

# Import Common-ScriptHelpers for enhanced tracking functionality
try {
    # Get the script directory - handle both direct execution and dot-sourcing
    if ($MyInvocation.MyCommand.Path) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    else {
        $scriptDir = $PWD.Path
    }

    # Calculate path to Common-ScriptHelpers from scripts/file-creation directory
    # scripts/file-creation -> scripts -> process-framework
    $scriptsDir = Split-Path -Parent $scriptDir
    $processFrameworkDir = Split-Path -Parent $scriptsDir

    $helpersPath = Join-Path $scriptsDir "Common-ScriptHelpers.psm1"

    if (Test-Path $helpersPath) {
        Import-Module $helpersPath -Force
        $useEnhancedTracking = $true
        Write-Verbose "Enhanced tracking functionality available"
    }
    else {
        $useEnhancedTracking = $false
        Write-Verbose "Enhanced tracking not available, using legacy method"
    }
}
catch {
    $useEnhancedTracking = $false
    Write-Verbose "Failed to load enhanced tracking: $($_.Exception.Message)"
}

# Validation type mappings
$ValidationTypeMap = @{
    "ArchitecturalConsistency"     = @{
        "Directory"   = "architectural-consistency"
        "DisplayName" = "Architectural Consistency"
        "ShortName"   = "architectural-consistency"
    }
    "CodeQuality"                  = @{
        "Directory"   = "code-quality"
        "DisplayName" = "Code Quality & Standards"
        "ShortName"   = "code-quality"
    }
    "IntegrationDependencies"      = @{
        "Directory"   = "integration-dependencies"
        "DisplayName" = "Integration & Dependencies"
        "ShortName"   = "integration-dependencies"
    }
    "DocumentationAlignment"       = @{
        "Directory"   = "documentation-alignment"
        "DisplayName" = "Documentation Alignment"
        "ShortName"   = "documentation-alignment"
    }
    "ExtensibilityMaintainability" = @{
        "Directory"   = "extensibility-maintainability"
        "DisplayName" = "Extensibility & Maintainability"
        "ShortName"   = "extensibility-maintainability"
    }
    "AIAgentContinuity"            = @{
        "Directory"   = "ai-agent-continuity"
        "DisplayName" = "AI Agent Continuity"
        "ShortName"   = "ai-agent-continuity"
    }
}

function Get-NextValidationId {
    <#
    .SYNOPSIS
        Gets the next available PF-VAL ID from the registry
    #>
    try {
        # Use absolute path resolution - navigate from script location to doc directory
        $scriptDir = if ($MyInvocation.MyCommand.Path) {
            Split-Path -Parent $MyInvocation.MyCommand.Path
        }
        else {
            $PSScriptRoot
        }

        if (-not $scriptDir) {
            # Fallback: use current directory and navigate up
            $scriptDir = Split-Path -Parent (Get-Location).Path
        }

        $scriptsDir = Split-Path -Parent $scriptDir
        $processFrameworkDir = Split-Path -Parent $scriptsDir
        $docDir = Split-Path -Parent $processFrameworkDir
        $absoluteIdRegistryPath = Join-Path $docDir "id-registry.json"

        if (-not (Test-Path $absoluteIdRegistryPath)) {
            throw "ID registry not found at: $absoluteIdRegistryPath"
        }

        $idRegistry = Get-Content $absoluteIdRegistryPath -Raw | ConvertFrom-Json
        $currentId = $idRegistry.prefixes."PF-VAL".nextAvailable

        # Update the registry
        $idRegistry.prefixes."PF-VAL".nextAvailable = $currentId + 1
        $idRegistry | ConvertTo-Json -Depth 10 | Set-Content $absoluteIdRegistryPath

        return "PF-VAL-{0:D3}" -f $currentId
    }
    catch {
        Write-Error "Failed to get next validation ID: $_"
        throw
    }
}

function New-ValidationReportFromTemplate {
    <#
    .SYNOPSIS
        Creates a new validation report from the template
    #>
    param(
        [string]$ValidationId,
        [string]$OutputPath,
        [hashtable]$ValidationConfig,
        [string[]]$Features
    )

    try {
        # Read template
        if (-not (Test-Path $TemplateFile)) {
            throw "Template file not found: $TemplateFile"
        }

        $templateContent = Get-Content $TemplateFile -Raw

        # Extract the document template section
        $documentTemplateStart = $templateContent.IndexOf("```markdown")
        $documentTemplateEnd = $templateContent.IndexOf("``", $documentTemplateStart + 11)

        if ($documentTemplateStart -eq -1 -or $documentTemplateEnd -eq -1) {
            throw 'Could not find document template section in template file'
        }

        $documentTemplate = $templateContent.Substring($documentTemplateStart + 11, $documentTemplateEnd - $documentTemplateStart - 11).Trim()

        # Replace placeholders
        $currentDate = Get-Date -Format 'yyyy-MM-dd'
        $featureRange = ($Features | Sort-Object) -join '-'
        $featureList = $Features -join ', '

        $reportContent = $documentTemplate
        $reportContent = $reportContent -replace '\[PF-VAL-XXX - will be assigned from ID registry\]', $ValidationId
        $reportContent = $reportContent -replace '\[YYYY-MM-DD\]', $currentDate
        $reportContent = $reportContent -replace '\[validation-type\]', $ValidationConfig.ShortName
        $reportContent = $reportContent -replace '\[Validation Type\]', $ValidationConfig.DisplayName
        $reportContent = $reportContent -replace '\[Validation Type Name\]', $ValidationConfig.DisplayName
        $reportContent = $reportContent -replace '\[Feature Range\]', $featureRange
        $reportContent = $reportContent -replace '\[List of features, e\.g\., 0\.2\.1, 0\.2\.2, 0\.2\.3\]', $featureList
        $reportContent = $reportContent -replace '\[e\.g\., "0\.2\.1, 0\.2\.2, 0\.2\.3"\]', ('"' + $featureList + '"')
        $reportContent = $reportContent -replace '\[Session number for this validation type\]', $SessionNumber.ToString()
        $reportContent = $reportContent -replace '\[Date\]', $currentDate

        # Write the report
        Set-Content -Path $OutputPath -Value $reportContent -Encoding UTF8

        Write-Host "✅ Created validation report: $OutputPath" -ForegroundColor Green
        Write-Host "   ID: $ValidationId" -ForegroundColor Gray
        Write-Host "   Type: $($ValidationConfig.DisplayName)" -ForegroundColor Gray
        Write-Host "   Features: $featureList" -ForegroundColor Gray

    }
    catch {
        Write-Error "Failed to create validation report: $_"
        throw
    }
}

function Update-ValidationTracking {
    <#
    .SYNOPSIS
        Updates the validation tracking file with the new report
    #>
    param(
        [string]$ValidationId,
        [string]$ValidationType,
        [string[]]$Features,
        [string]$ReportPath
    )

    try {
        if (-not (Test-Path $TrackingFile)) {
            Write-Warning "Validation tracking file not found: $TrackingFile"
            Write-Warning "Please manually update the tracking file with the new report information."
            return
        }

        Write-Host "📊 Validation tracking file found. Manual update required:" -ForegroundColor Yellow
        Write-Host "   File: $TrackingFile" -ForegroundColor Gray
        Write-Host "   Report ID: $ValidationId" -ForegroundColor Gray
        Write-Host "   Validation Type: $ValidationType" -ForegroundColor Gray
        Write-Host "   Features: $($Features -join ', ')" -ForegroundColor Gray
        Write-Host "   Report Path: $ReportPath" -ForegroundColor Gray

    }
    catch {
        Write-Warning "Could not update validation tracking: $_"
    }
}

# Main execution
try {
    Write-Host "🔍 Creating Foundational Codebase Validation Report..." -ForegroundColor Cyan
    Write-Host ""

    # Validate inputs
    $validationConfig = $ValidationTypeMap[$ValidationType]
    $features = $FeatureIds -split ',' | ForEach-Object { $_.Trim() }

    Write-Host "📋 Validation Configuration:" -ForegroundColor White
    Write-Host "   Type: $($validationConfig.DisplayName)" -ForegroundColor Gray
    Write-Host "   Features: $($features -join ', ')" -ForegroundColor Gray
    Write-Host "   Batch: $BatchNumber" -ForegroundColor Gray
    Write-Host "   Session: $SessionNumber" -ForegroundColor Gray
    Write-Host ""

    # Get next validation ID
    Write-Host "🆔 Assigning validation ID..." -ForegroundColor White
    $validationId = Get-NextValidationId
    Write-Host "   Assigned ID: $validationId" -ForegroundColor Green
    Write-Host ""

    # Create output path
    $featureRange = ($features | Sort-Object) -join "-"
    $fileName = "$validationId-$($validationConfig.ShortName)-features-$featureRange.md"
    $outputDir = Join-Path $ScriptDirectory "../../validation/reports/$($validationConfig.Directory)"
    $outputPath = Join-Path $outputDir $fileName

    # Ensure output directory exists
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    Write-Host "📁 Output Configuration:" -ForegroundColor White
    Write-Host "   Directory: $outputDir" -ForegroundColor Gray
    Write-Host "   Filename: $fileName" -ForegroundColor Gray
    Write-Host "   Full Path: $outputPath" -ForegroundColor Gray
    Write-Host ""

    # Create the validation report
    Write-Host "📝 Generating validation report..." -ForegroundColor White
    New-ValidationReportFromTemplate -ValidationId $validationId -OutputPath $outputPath -ValidationConfig $validationConfig -Features $features
    Write-Host ""

    # Update tracking
    Write-Host "📊 Updating validation tracking..." -ForegroundColor White
    if ($useEnhancedTracking) {
        try {
            $trackingMetadata = @{
                "validation_type" = $validationConfig.DisplayName
                "features"        = ($features -join ', ')
                "batch_number"    = $BatchNumber
                "session_number"  = $SessionNumber
            }

            Update-DocumentTrackingFiles -DocumentId $validationId -DocumentType "ValidationReport" -DocumentPath $outputPath -Metadata $trackingMetadata
        }
        catch {
            Write-Warning "Enhanced tracking failed, falling back to legacy method: $($_.Exception.Message)"
            Update-ValidationTracking -ValidationId $validationId -ValidationType $ValidationType -Features $features -ReportPath $outputPath
        }
    }
    else {
        Update-ValidationTracking -ValidationId $validationId -ValidationType $ValidationType -Features $features -ReportPath $outputPath
    }
    Write-Host ""

    Write-Host "🎉 Validation report created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. Open the report file: $outputPath" -ForegroundColor Gray
    Write-Host "   2. Customize validation criteria based on validation type" -ForegroundColor Gray
    Write-Host "   3. Conduct the validation and fill in findings" -ForegroundColor Gray
    Write-Host "   4. Update the validation tracking file manually" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📖 Reference:" -ForegroundColor Yellow
    Write-Host "   Template: $TemplateFile" -ForegroundColor Gray
    Write-Host "   Tracking: $TrackingFile" -ForegroundColor Gray

}
catch {
    Write-Error "❌ Failed to create validation report: $_"
    exit 1
}
