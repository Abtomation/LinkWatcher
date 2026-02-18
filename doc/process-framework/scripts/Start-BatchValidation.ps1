#!/usr/bin/env pwsh

<#
.SYNOPSIS
Processes multiple features for validation in batch operations

.DESCRIPTION
This script enables efficient batch processing of validation tasks across multiple features,
addressing the need for consistent validation criteria application and bulk status updates.

Supports all validation types:
- Architectural Consistency Validation (PF-TSK-031)
- Code Quality & Standards Validation (PF-TSK-032)
- Integration & Dependencies Validation (PF-TSK-033)
- Documentation Alignment Validation (PF-TSK-034)
- Extensibility & Maintainability Validation (PF-TSK-035)
- AI Agent Continuity Validation (PF-TSK-036)

.PARAMETER ValidationType
The type of validation to perform:
- "Architectural" (PF-TSK-031)
- "CodeQuality" (PF-TSK-032)
- "Integration" (PF-TSK-033)
- "Documentation" (PF-TSK-034)
- "Extensibility" (PF-TSK-035)
- "AIAgent" (PF-TSK-036)

.PARAMETER FeatureIds
Array of feature IDs to validate (e.g., @("0.2.1", "0.2.2", "0.2.3"))

.PARAMETER ValidatorName
Name of the person conducting the validation

.PARAMETER BatchSize
Number of features to process in each batch (default: 3)

.PARAMETER ValidationCriteria
Path to validation criteria file (optional - uses default criteria)

.PARAMETER OutputDirectory
Directory to store validation reports (optional - uses default location)

.PARAMETER DryRun
If specified, shows what would be processed without making changes

.PARAMETER ContinueOnError
If specified, continues processing remaining features if one fails

.EXAMPLE
.\Start-BatchValidation.ps1 -ValidationType "Architectural" -FeatureIds @("0.2.1", "0.2.2", "0.2.3") -ValidatorName "AI Agent"

.EXAMPLE
.\Start-BatchValidation.ps1 -ValidationType "CodeQuality" -FeatureIds @("0.2.4", "0.2.5") -ValidatorName "AI Agent" -BatchSize 2 -DryRun

.EXAMPLE
.\Start-BatchValidation.ps1 -ValidationType "Integration" -FeatureIds @("0.2.6", "0.2.7", "0.2.8", "0.2.9") -ValidatorName "AI Agent" -ContinueOnError

.NOTES
Version: 1.0
Created: 2025-08-23
Part of: Process Framework Automation Phase 3A
Addresses: IMP-058 (Validation task automation enhancement)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Architectural", "CodeQuality", "Integration", "Documentation", "Extensibility", "AIAgent")]
    [string]$ValidationType,

    [Parameter(Mandatory = $true)]
    [string[]]$FeatureIds,

    [Parameter(Mandatory = $true)]
    [string]$ValidatorName,

    [Parameter(Mandatory = $false)]
    [int]$BatchSize = 3,

    [Parameter(Mandatory = $false)]
    [string]$ValidationCriteria,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$ContinueOnError
)

# Import required modules
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$scriptDir\Common-ScriptHelpers.psm1" -Force

# Initialize script with dependency validation
if (-not (Test-ScriptDependencies -RequiredModules @("Common-ScriptHelpers"))) {
    Write-Error "Required dependencies not met. Please ensure Common-ScriptHelpers.psm1 is properly loaded."
    exit 1
}

# Get project root and set default paths
$projectRoot = Get-ProjectRoot
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $projectRoot "doc\process-framework\validation\reports"
}

# Ensure output directory exists
if (-not $DryRun -and -not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

# Map validation types to task IDs
$validationTaskMap = @{
    "Architectural" = @{ TaskId = "PF-TSK-031"; TaskNumber = "031"; Name = "Architectural Consistency Validation" }
    "CodeQuality" = @{ TaskId = "PF-TSK-032"; TaskNumber = "032"; Name = "Code Quality & Standards Validation" }
    "Integration" = @{ TaskId = "PF-TSK-033"; TaskNumber = "033"; Name = "Integration & Dependencies Validation" }
    "Documentation" = @{ TaskId = "PF-TSK-034"; TaskNumber = "034"; Name = "Documentation Alignment Validation" }
    "Extensibility" = @{ TaskId = "PF-TSK-035"; TaskNumber = "035"; Name = "Extensibility & Maintainability Validation" }
    "AIAgent" = @{ TaskId = "PF-TSK-036"; TaskNumber = "036"; Name = "AI Agent Continuity Validation" }
}

$taskInfo = $validationTaskMap[$ValidationType]
$batchId = "BATCH-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "🚀 Starting Batch Validation Process" -ForegroundColor Green
Write-Host "   Validation Type: $($taskInfo.Name)" -ForegroundColor Cyan
Write-Host "   Task ID: $($taskInfo.TaskId)" -ForegroundColor Cyan
Write-Host "   Features to Process: $($FeatureIds.Count)" -ForegroundColor Cyan
Write-Host "   Batch Size: $BatchSize" -ForegroundColor Cyan
Write-Host "   Validator: $ValidatorName" -ForegroundColor Cyan
Write-Host "   Batch ID: $batchId" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "   🔍 DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
}

# Create batch tracking
$batchResults = @{
    BatchId = $batchId
    ValidationType = $ValidationType
    TaskInfo = $taskInfo
    ValidatorName = $ValidatorName
    StartTime = Get-Date
    TotalFeatures = $FeatureIds.Count
    ProcessedFeatures = @()
    FailedFeatures = @()
    ValidationReports = @()
    Summary = @{}
}

# Split features into batches
$batches = @()
for ($i = 0; $i -lt $FeatureIds.Count; $i += $BatchSize) {
    $end = [Math]::Min($i + $BatchSize - 1, $FeatureIds.Count - 1)
    $batches += ,@($FeatureIds[$i..$end])
}

Write-Host "📦 Processing $($batches.Count) batches..." -ForegroundColor Blue

try {
    foreach ($batchIndex in 0..($batches.Count - 1)) {
        $currentBatch = $batches[$batchIndex]
        $batchNumber = $batchIndex + 1

        Write-Host "🔄 Processing Batch $batchNumber/$($batches.Count) ($($currentBatch.Count) features)..." -ForegroundColor Blue

        foreach ($featureId in $currentBatch) {
            Write-Host "   📋 Processing Feature: $featureId" -ForegroundColor Cyan

            try {
                # Generate validation ID
                $validationId = "VAL-$($taskInfo.TaskNumber)-$(Get-Date -Format 'yyyyMMdd')-$($featureId.Replace('.', ''))"

                if ($DryRun) {
                    Write-Host "      🔍 DRY RUN - Would create validation: $validationId" -ForegroundColor Yellow
                    $batchResults.ProcessedFeatures += @{
                        FeatureId = $featureId
                        ValidationId = $validationId
                        Status = "DRY_RUN"
                        ProcessedAt = Get-Date
                    }
                } else {
                    # Create validation report
                    $reportResult = New-ValidationReport -ValidationType $ValidationType -FeatureId $featureId -ValidationId $validationId -ValidatorName $ValidatorName -OutputDirectory $OutputDirectory

                    if ($reportResult.Success) {
                        # Update state files
                        $updateParams = @{
                            ValidationId = $validationId
                            ValidationStatus = "Validation In Progress"
                            ValidatorName = $ValidatorName
                            FeatureId = $featureId
                            ReportPath = $reportResult.ReportPath
                        }

                        & "$scriptDir\Update-ValidationReportState.ps1" @updateParams

                        $batchResults.ProcessedFeatures += @{
                            FeatureId = $featureId
                            ValidationId = $validationId
                            Status = "CREATED"
                            ReportPath = $reportResult.ReportPath
                            ProcessedAt = Get-Date
                        }

                        $batchResults.ValidationReports += $reportResult.ReportPath

                        Write-Host "      ✅ Created: $validationId" -ForegroundColor Green
                    } else {
                        throw "Failed to create validation report: $($reportResult.Error)"
                    }
                }

            } catch {
                $errorMsg = "Failed to process feature $featureId`: $($_.Exception.Message)"
                Write-Warning "      ❌ $errorMsg"

                $batchResults.FailedFeatures += @{
                    FeatureId = $featureId
                    Error = $errorMsg
                    FailedAt = Get-Date
                }

                if (-not $ContinueOnError) {
                    throw "Batch processing stopped due to error in feature $featureId"
                }
            }
        }

        # Brief pause between batches to avoid overwhelming the system
        if ($batchIndex -lt ($batches.Count - 1)) {
            Start-Sleep -Seconds 1
        }
    }

    # Generate batch summary
    $batchResults.EndTime = Get-Date
    $batchResults.Duration = $batchResults.EndTime - $batchResults.StartTime
    $batchResults.Summary = @{
        TotalFeatures = $batchResults.TotalFeatures
        ProcessedSuccessfully = $batchResults.ProcessedFeatures.Count
        Failed = $batchResults.FailedFeatures.Count
        SuccessRate = [Math]::Round(($batchResults.ProcessedFeatures.Count / $batchResults.TotalFeatures) * 100, 2)
        Duration = $batchResults.Duration.ToString("hh\:mm\:ss")
    }

    # Save batch results
    if (-not $DryRun) {
        $batchResultsPath = Join-Path $OutputDirectory "batch-results-$batchId.json"
        $batchResults | ConvertTo-Json -Depth 10 | Set-Content -Path $batchResultsPath -Encoding UTF8
        Write-Host "📊 Batch results saved: $batchResultsPath" -ForegroundColor Blue
    }

    # Display summary
    Write-Host "🎉 Batch Validation Completed!" -ForegroundColor Green
    Write-Host "   📊 Summary:" -ForegroundColor Cyan
    Write-Host "      Total Features: $($batchResults.Summary.TotalFeatures)" -ForegroundColor Gray
    Write-Host "      Processed Successfully: $($batchResults.Summary.ProcessedSuccessfully)" -ForegroundColor Gray
    Write-Host "      Failed: $($batchResults.Summary.Failed)" -ForegroundColor Gray
    Write-Host "      Success Rate: $($batchResults.Summary.SuccessRate)%" -ForegroundColor Gray
    Write-Host "      Duration: $($batchResults.Summary.Duration)" -ForegroundColor Gray

    if ($batchResults.FailedFeatures.Count -gt 0) {
        Write-Host "   ⚠️ Failed Features:" -ForegroundColor Yellow
        foreach ($failed in $batchResults.FailedFeatures) {
            Write-Host "      - $($failed.FeatureId): $($failed.Error)" -ForegroundColor Red
        }
    }

    if (-not $DryRun -and $batchResults.ValidationReports.Count -gt 0) {
        Write-Host "   📄 Generated Reports:" -ForegroundColor Cyan
        foreach ($report in $batchResults.ValidationReports) {
            Write-Host "      - $report" -ForegroundColor Gray
        }
    }

} catch {
    Write-Error "❌ Batch validation failed: $($_.Exception.Message)"

    # Save partial results if any processing was done
    if (-not $DryRun -and ($batchResults.ProcessedFeatures.Count -gt 0 -or $batchResults.FailedFeatures.Count -gt 0)) {
        $batchResults.EndTime = Get-Date
        $batchResults.Duration = $batchResults.EndTime - $batchResults.StartTime
        $batchResults.Status = "FAILED"

        $batchResultsPath = Join-Path $OutputDirectory "batch-results-$batchId-FAILED.json"
        $batchResults | ConvertTo-Json -Depth 10 | Set-Content -Path $batchResultsPath -Encoding UTF8
        Write-Host "📊 Partial batch results saved: $batchResultsPath" -ForegroundColor Yellow
    }

    exit 1
}

# Helper function to create validation reports
function New-ValidationReport {
    param(
        [string]$ValidationType,
        [string]$FeatureId,
        [string]$ValidationId,
        [string]$ValidatorName,
        [string]$OutputDirectory
    )

    try {
        # Check if New-ValidationReport.ps1 script exists
        $validationScriptPath = Join-Path $projectRoot "file-creation\New-ValidationReport.ps1"

        if (Test-Path $validationScriptPath) {
            # Use existing validation script
            $result = & $validationScriptPath -ValidationType $ValidationType -FeatureId $FeatureId -ValidationId $ValidationId -ValidatorName $ValidatorName -OutputDirectory $OutputDirectory
            return @{ Success = $true; ReportPath = $result.ReportPath }
        } else {
            # Create basic validation report template
            $reportFileName = "$ValidationId-validation-report.md"
            $reportPath = Join-Path $OutputDirectory $reportFileName

            $reportContent = @"
---
id: $ValidationId
type: Validation Report
validation_type: $ValidationType
feature_id: $FeatureId
validator: $ValidatorName
created: $(Get-Date -Format 'yyyy-MM-dd')
status: In Progress
---

# $ValidationType Validation Report - Feature $FeatureId

## Validation Overview
**Validation ID**: $ValidationId
**Feature ID**: $FeatureId
**Validation Type**: $ValidationType
**Validator**: $ValidatorName
**Date**: $(Get-Date -Format 'yyyy-MM-dd')
**Status**: In Progress

## Validation Criteria
<!-- Add specific validation criteria here -->

## Findings
<!-- Add validation findings here -->

## Recommendations
<!-- Add recommendations here -->

## Conclusion
<!-- Add conclusion here -->

---
**Generated by**: Batch Validation Process
**Batch ID**: $batchId
"@

            Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8
            return @{ Success = $true; ReportPath = $reportPath }
        }

    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}
