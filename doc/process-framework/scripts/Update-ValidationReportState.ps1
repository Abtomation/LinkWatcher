#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates state file updates for Validation Tasks (PF-TSK-031, 032, 033, 034)

.DESCRIPTION
This script automates the manual state file updates required by validation tasks,
addressing the critical bottleneck identified in the Process Improvement Tracking (IMP-058).

All 4 validation task feedback forms identified manual tracking file updates as the primary
efficiency bottleneck despite excellent tool performance (4-5/5 ratings).

Updates the following files:
- state-tracking/temporary/foundational-validation-tracking.md
- doc/process-framework/documentation-map.md
- doc/process-framework/state-tracking/permanent/feature-tracking.md (cross-references)

.PARAMETER ValidationId
The validation ID to update (e.g., "VAL-031-001", "VAL-032-002")

.PARAMETER ValidationStatus
The validation status:
- "Validation In Progress"
- "Validation Completed"
- "Needs Revision"
- "Validation Failed"

.PARAMETER ValidatorName
Name of the person conducting the validation

.PARAMETER ValidationFindings
Array of key validation findings or issues identified

.PARAMETER ValidationScore
Overall validation score (1-10 scale, optional)

.PARAMETER ValidationDate
Date when validation was completed (optional - uses current date if not specified)

.PARAMETER ReportPath
Path to the generated validation report (optional)

.PARAMETER FeatureId
Associated feature ID for cross-reference updates (optional)

.PARAMETER ValidationNotes
Additional notes about the validation process (optional)

.PARAMETER DryRun
If specified, shows what would be updated without making changes

.EXAMPLE
.\Update-ValidationReportState.ps1 -ValidationId "VAL-031-001" -ValidationStatus "Validation In Progress" -ValidatorName "AI Agent"

.EXAMPLE
.\Update-ValidationReportState.ps1 -ValidationId "VAL-031-001" -ValidationStatus "Validation Completed" -ValidatorName "AI Agent" -ValidationScore 8 -ValidationFindings @("Minor pattern inconsistencies", "Good overall architecture")

.EXAMPLE
.\Update-ValidationReportState.ps1 -ValidationId "VAL-032-002" -ValidationStatus "Needs Revision" -ValidatorName "AI Agent" -ValidationFindings @("Code quality issues found", "Documentation gaps") -DryRun

.NOTES
Version: 1.0
Created: 2025-08-23
Part of: Process Framework Automation Phase 3A
Addresses: IMP-058 (Validation task automation enhancement)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ValidationId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Validation In Progress", "Validation Completed", "Needs Revision", "Validation Failed")]
    [string]$ValidationStatus,

    [Parameter(Mandatory = $true)]
    [string]$ValidatorName,

    [Parameter(Mandatory = $false)]
    [string[]]$ValidationFindings = @(),

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$ValidationScore,

    [Parameter(Mandatory = $false)]
    [string]$ValidationDate,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath,

    [Parameter(Mandatory = $false)]
    [string]$FeatureId,

    [Parameter(Mandatory = $false)]
    [string]$ValidationNotes,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Architectural Consistency", "Code Quality & Standards", "Integration & Dependencies", "Documentation Alignment", "Extensibility & Maintainability", "AI Agent Continuity")]
    [string]$ValidationType,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Import required modules
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$scriptDir\Common-ScriptHelpers.psm1" -Force

# Verify that required functions are available
$requiredFunctions = @("Get-ProjectRoot", "Update-DocumentTrackingFiles")
$missingFunctions = @()
foreach ($func in $requiredFunctions) {
    if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
        $missingFunctions += $func
    }
}

if ($missingFunctions.Count -gt 0) {
    Write-Warning "Missing functions: $($missingFunctions -join ', ')"
    Write-Host "Continuing with basic functionality..." -ForegroundColor Yellow
}

# Set default values
if (-not $ValidationDate) {
    $ValidationDate = Get-Date -Format "yyyy-MM-dd"
}

# Get project root and define file paths
$projectRoot = Get-ProjectRoot
$validationTrackingPath = Join-Path $projectRoot "doc\process-framework\state-tracking\temporary\foundational-validation-tracking.md"
$documentationMapPath = Join-Path $projectRoot "doc\process-framework\documentation-map.md"
$featureTrackingPath = Join-Path $projectRoot "doc\process-framework\state-tracking\permanent\feature-tracking.md"

Write-Host "🚀 Starting Validation Report State Update" -ForegroundColor Green
Write-Host "   Validation ID: $ValidationId" -ForegroundColor Cyan
Write-Host "   Status: $ValidationStatus" -ForegroundColor Cyan
Write-Host "   Validator: $ValidatorName" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "   🔍 DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
}

# Create backup before making changes
if (-not $DryRun) {
    Write-Host "📦 Creating backups..." -ForegroundColor Blue
    $backupInfo = Get-StateFileBackup -FilePaths @($validationTrackingPath, $documentationMapPath, $featureTrackingPath) -BackupPrefix "ValidationReportState-$ValidationId"
    Write-Host "   Backups created: $($backupInfo.BackupDirectory)" -ForegroundColor Green
}

# Prepare update data
$updateData = @{
    ValidationId       = $ValidationId
    Status             = $ValidationStatus
    ValidatorName      = $ValidatorName
    ValidationDate     = $ValidationDate
    ValidationFindings = $ValidationFindings
    ValidationScore    = $ValidationScore
    ReportPath         = $ReportPath
    ValidationNotes    = $ValidationNotes
}

# Define files to update using enhanced tracking system
$trackingFiles = @()

# Always update validation tracking
if (Test-Path $validationTrackingPath) {
    $trackingFiles += @{
        Path     = $validationTrackingPath
        Type     = "ValidationTracking"
        Required = $true
    }
}

# Always update documentation map
if (Test-Path $documentationMapPath) {
    $trackingFiles += @{
        Path     = $documentationMapPath
        Type     = "DocumentationMap"
        Required = $false
    }
}

# Add feature tracking if FeatureId is provided
if ($FeatureId -and (Test-Path $featureTrackingPath)) {
    $trackingFiles += @{
        Path     = $featureTrackingPath
        Type     = "Feature"
        Required = $false
    }
    $updateData.FeatureId = $FeatureId
}

try {
    if ($DryRun) {
        Write-Host "🔍 DRY RUN - Would update the following files:" -ForegroundColor Yellow
        foreach ($file in $trackingFiles) {
            Write-Host "   📄 $($file.Path)" -ForegroundColor Cyan
            Write-Host "      Type: $($file.Type)" -ForegroundColor Gray
        }

        Write-Host "🔍 DRY RUN - Update data:" -ForegroundColor Yellow
        $updateData.GetEnumerator() | ForEach-Object {
            if ($_.Value -and $_.Value -ne "") {
                Write-Host "   $($_.Key): $($_.Value)" -ForegroundColor Gray
            }
        }
    }
    else {
        # Use enhanced tracking system to update files
        Write-Host "📝 Updating tracking files..." -ForegroundColor Blue

        # Determine validation type
        $actualValidationType = if ($ValidationType) {
            $ValidationType
        }
        else {
            # Try to detect from ValidationId or ReportPath
            $detectedType = "Unknown"
            if ($ValidationId -match "architectural-consistency" -or $ReportPath -match "architectural-consistency") {
                $detectedType = "Architectural Consistency"
            }
            elseif ($ValidationId -match "code-quality" -or $ReportPath -match "code-quality") {
                $detectedType = "Code Quality & Standards"
            }
            elseif ($ValidationId -match "integration-dependencies" -or $ReportPath -match "integration-dependencies") {
                $detectedType = "Integration & Dependencies"
            }
            elseif ($ValidationId -match "documentation-alignment" -or $ReportPath -match "documentation-alignment") {
                $detectedType = "Documentation Alignment"
            }
            elseif ($ValidationId -match "extensibility-maintainability" -or $ReportPath -match "extensibility-maintainability") {
                $detectedType = "Extensibility & Maintainability"
            }
            elseif ($ValidationId -match "ai-agent-continuity" -or $ReportPath -match "ai-agent-continuity") {
                $detectedType = "AI Agent Continuity"
            }
            $detectedType
        }

        # Prepare metadata for enhanced tracking
        $metadata = @{
            validation_type = $actualValidationType
            features        = if ($FeatureId) { $FeatureId } else { "N/A" }
            validator       = $ValidatorName
            score           = $ValidationScore
            status          = $ValidationStatus
            findings        = if ($ValidationFindings) { $ValidationFindings -join "; " } else { "N/A" }
            notes           = $ValidationNotes
        }

        # Update tracking files using enhanced system
        $documentPath = if ($ReportPath) { $ReportPath } else { "validation-update" }
        Update-DocumentTrackingFiles -DocumentId $ValidationId -DocumentType "ValidationReport" -DocumentPath $documentPath -Metadata $metadata

        Write-Host "✅ Tracking files updated successfully" -ForegroundColor Green
    }

    Write-Host "🎉 Validation Report State Update completed successfully!" -ForegroundColor Green

}
catch {
    Write-Error "❌ Error updating validation report state: $($_.Exception.Message)"

    if (-not $DryRun -and $backupInfo) {
        Write-Host "🔄 Attempting to restore from backup..." -ForegroundColor Yellow
        # Restore logic would go here if needed
    }

    exit 1
}

# Helper functions for specific file updates
function Update-ValidationTrackingFile {
    param(
        [string]$FilePath,
        [hashtable]$UpdateData
    )

    if (-not (Test-Path $FilePath)) {
        Write-Warning "Validation tracking file not found: $FilePath"
        return
    }

    $content = Get-Content $FilePath -Raw

    # Extract validation type from ValidationId (e.g., VAL-031-001 -> 031 -> Architectural Consistency)
    $validationType = Get-ValidationTypeFromId -ValidationId $UpdateData.ValidationId

    # Update the validation progress matrix
    $progressPattern = "(\| $validationType \| )(\d+/\d+)( \| )(\d+)( \| )([A-Z_]+)( \| )([^|]+)( \|)"

    if ($content -match $progressPattern) {
        $currentValidated = [int]($matches[2].Split('/')[0])
        $totalItems = [int]($matches[2].Split('/')[1])
        $currentReports = [int]$matches[4]

        # Update counts based on status
        if ($UpdateData.Status -eq "Validation Completed") {
            $newValidated = $currentValidated + 1
            $newReports = $currentReports + 1
            $newStatus = "IN_PROGRESS"
        }
        elseif ($UpdateData.Status -eq "Validation In Progress") {
            $newValidated = $currentValidated
            $newReports = $currentReports
            $newStatus = "IN_PROGRESS"
        }
        else {
            $newValidated = $currentValidated
            $newReports = $currentReports
            $newStatus = "NEEDS_REVISION"
        }

        $replacement = "$($matches[1])$newValidated/$totalItems$($matches[3])$newReports$($matches[5])$newStatus$($matches[7])$($UpdateData.ValidationDate)$($matches[9])"
        $content = $content -replace $progressPattern, $replacement
    }

    # Add detailed validation entry if not exists
    $detailsSection = "## Detailed Validation Results"
    if ($content -notmatch [regex]::Escape($detailsSection)) {
        $content += "`n`n$detailsSection`n`n"
    }

    # Add validation entry
    $validationEntry = @"

### $($UpdateData.ValidationId) - $validationType
**Status**: $($UpdateData.Status)
**Validator**: $($UpdateData.ValidatorName)
**Date**: $($UpdateData.ValidationDate)
"@

    if ($UpdateData.ValidationScore) {
        $validationEntry += "`n**Score**: $($UpdateData.ValidationScore)/10  "
    }

    if ($UpdateData.ValidationFindings -and $UpdateData.ValidationFindings.Count -gt 0) {
        $validationEntry += "`n**Key Findings**:  "
        foreach ($finding in $UpdateData.ValidationFindings) {
            $validationEntry += "`n- $finding"
        }
    }

    if ($UpdateData.ReportPath) {
        $validationEntry += "`n**Report**: [$($UpdateData.ValidationId) Report]($($UpdateData.ReportPath))  "
    }

    if ($UpdateData.ValidationNotes) {
        $validationEntry += "`n**Notes**: $($UpdateData.ValidationNotes)  "
    }

    $content += $validationEntry

    Set-Content -Path $FilePath -Value $content -Encoding UTF8
}

function Update-DocumentationMapFile {
    param(
        [string]$FilePath,
        [hashtable]$UpdateData
    )

    if (-not (Test-Path $FilePath)) {
        Write-Warning "Documentation map file not found: $FilePath"
        return
    }

    # Add validation report to documentation map if ReportPath is provided
    if ($UpdateData.ReportPath) {
        $content = Get-Content $FilePath -Raw

        # Find validation reports section or create it
        $validationSection = "## Validation Reports"
        if ($content -notmatch [regex]::Escape($validationSection)) {
            $content += "`n`n$validationSection`n`n"
        }

        # Add report entry
        $reportEntry = "- [$($UpdateData.ValidationId)](../$($UpdateData.ReportPath)) - $($UpdateData.Status) ($($UpdateData.ValidationDate))"

        # Check if entry already exists
        if ($content -notmatch [regex]::Escape($UpdateData.ValidationId)) {
            $content += "`n$reportEntry"
            Set-Content -Path $FilePath -Value $content -Encoding UTF8
        }
    }
}

function Update-FeatureTrackingCrossReference {
    param(
        [string]$FilePath,
        [hashtable]$UpdateData
    )

    if (-not (Test-Path $FilePath) -or -not $UpdateData.FeatureId) {
        return
    }

    # Update feature tracking with validation cross-reference
    $content = Get-Content $FilePath -Raw

    # Find the feature entry and add validation reference
    $featurePattern = "(\| $($UpdateData.FeatureId) \|[^|]+\|[^|]+\|[^|]+\|[^|]+\|)([^|]*?)(\|)"

    if ($content -match $featurePattern) {
        $currentValidations = $matches[2].Trim()
        $validationRef = "[$($UpdateData.ValidationId)]"

        if ($currentValidations -eq "" -or $currentValidations -eq "-") {
            $newValidations = $validationRef
        }
        elseif ($currentValidations -notmatch [regex]::Escape($UpdateData.ValidationId)) {
            $newValidations = "$currentValidations, $validationRef"
        }
        else {
            $newValidations = $currentValidations
        }

        $replacement = "$($matches[1])$newValidations$($matches[3])"
        $content = $content -replace $featurePattern, $replacement

        Set-Content -Path $FilePath -Value $content -Encoding UTF8
    }
}

function Get-ValidationTypeFromId {
    param([string]$ValidationId)

    # Extract task number from ValidationId (e.g., VAL-031-001 -> 031)
    if ($ValidationId -match "VAL-(\d{3})-\d+") {
        $taskNumber = $matches[1]

        switch ($taskNumber) {
            "031" { return "Architectural Consistency" }
            "032" { return "Code Quality & Standards" }
            "033" { return "Integration & Dependencies" }
            "034" { return "Documentation Alignment" }
            "035" { return "Extensibility & Maintainability" }
            "036" { return "AI Agent Continuity" }
            default { return "Unknown Validation Type" }
        }
    }

    return "Unknown Validation Type"
}
