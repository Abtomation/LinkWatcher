#!/usr/bin/env pwsh

<#
.SYNOPSIS
Interactive menu system for Process Framework automation scripts

.DESCRIPTION
This script provides an interactive menu interface for selecting and executing
Process Framework automation scripts. It simplifies script discovery and execution
by providing a user-friendly interface with guided parameter input.

Features:
- Interactive script selection menu
- Guided parameter input with validation
- Dry-run mode support for all operations
- Recent operations history
- Quick access to common workflows
- Help and documentation integration

.PARAMETER QuickMode
If specified, shows only the most commonly used scripts

.PARAMETER ShowAdvanced
If specified, includes advanced and batch processing scripts

.PARAMETER DryRun
If specified, all selected operations will run in dry-run mode

.EXAMPLE
.\Start-AutomationMenu.ps1

.EXAMPLE
.\Start-AutomationMenu.ps1 -QuickMode

.EXAMPLE
.\Start-AutomationMenu.ps1 -ShowAdvanced -DryRun

.NOTES
Version: 1.0
Created: 2025-08-23
Part of: Process Framework Automation Phase 3B
Addresses: User Experience Enhancement and Workflow Integration
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$QuickMode,

    [Parameter(Mandatory = $false)]
    [switch]$ShowAdvanced,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Import required modules
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$scriptDir\Common-ScriptHelpers.psm1" -Force

# Initialize script
Write-Host "🎯 Process Framework Automation Menu" -ForegroundColor Green
Write-Host "   Interactive Script Selection and Execution" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "   🔍 DRY RUN MODE - All operations will be simulated" -ForegroundColor Yellow
}
Write-Host ""

# Define available scripts with metadata
$availableScripts = @{
    "1" = @{
        Name = "Update-FeatureImplementationState.ps1"
        Description = "Update feature implementation status and tracking"
        Category = "Feature Management"
        Complexity = "Basic"
        CommonParams = @("FeatureId", "ImplementationStatus", "DeveloperName")
        UseCases = @("Feature completion", "Status updates", "Implementation tracking")
    }
    "2" = @{
        Name = "Update-TestAuditState.ps1"
        Description = "Update test audit status and results"
        Category = "Testing"
        Complexity = "Basic"
        CommonParams = @("FeatureId", "AuditStatus", "AuditorName")
        UseCases = @("Test audits", "Quality assurance", "Test validation")
    }
    "3" = @{
        Name = "Update-CodeReviewState.ps1"
        Description = "Update code review status and feedback"
        Category = "Code Quality"
        Complexity = "Basic"
        CommonParams = @("FeatureId", "ReviewStatus", "ReviewerName")
        UseCases = @("Code reviews", "Quality checks", "Peer reviews")
    }
    "4" = @{
        Name = "Update-ValidationReportState.ps1"
        Description = "Update validation task status and findings"
        Category = "Validation"
        Complexity = "Intermediate"
        CommonParams = @("ValidationId", "ValidationStatus", "ValidatorName")
        UseCases = @("Validation tasks", "Quality validation", "Compliance checks")
    }
    "5" = @{
        Name = "Start-BatchValidation.ps1"
        Description = "Process multiple features for validation in batches"
        Category = "Batch Processing"
        Complexity = "Advanced"
        CommonParams = @("ValidationType", "FeatureIds", "ValidatorName")
        UseCases = @("Bulk validation", "Sprint validation", "Release validation")
    }
    "6" = @{
        Name = "Start-BatchAudit.ps1"
        Description = "Process multiple test files for audit in batches"
        Category = "Batch Processing"
        Complexity = "Advanced"
        CommonParams = @("FeatureIds", "AuditorName", "FeatureCategory")
        UseCases = @("Bulk audits", "Category audits", "Sprint audits")
    }
    "7" = @{
        Name = "Update-BatchFeatureStatus.ps1"
        Description = "Update multiple features simultaneously across tracking files"
        Category = "Batch Processing"
        Complexity = "Advanced"
        CommonParams = @("FeatureIds", "Status", "UpdateType")
        UseCases = @("Sprint completion", "Milestone updates", "Release preparation")
    }
}

# Filter scripts based on mode
$scriptsToShow = $availableScripts.Clone()

if ($QuickMode) {
    # Show only most common scripts
    $scriptsToShow = @{}
    @("1", "2", "3", "4") | ForEach-Object {
        $scriptsToShow[$_] = $availableScripts[$_]
    }
}

if (-not $ShowAdvanced) {
    # Hide advanced scripts unless explicitly requested
    $scriptsToShow = $scriptsToShow.GetEnumerator() | Where-Object { $_.Value.Complexity -ne "Advanced" } | ForEach-Object -Begin { $h = @{} } -Process { $h[$_.Key] = $_.Value } -End { $h }
}

# Display menu
function Show-ScriptMenu {
    param($Scripts)

    Write-Host "📋 Available Automation Scripts:" -ForegroundColor Cyan
    Write-Host ""

    foreach ($key in ($Scripts.Keys | Sort-Object)) {
        $script = $Scripts[$key]
        $complexityColor = switch ($script.Complexity) {
            "Basic" { "Green" }
            "Intermediate" { "Yellow" }
            "Advanced" { "Red" }
        }

        Write-Host "  [$key] " -NoNewline -ForegroundColor White
        Write-Host "$($script.Name)" -NoNewline -ForegroundColor $complexityColor
        Write-Host " [$($script.Category)]" -ForegroundColor Gray
        Write-Host "      $($script.Description)" -ForegroundColor Gray
        Write-Host ""
    }

    Write-Host "📚 Additional Options:" -ForegroundColor Cyan
    Write-Host "  [h] Show help and usage examples" -ForegroundColor White
    Write-Host "  [r] Show recent operations" -ForegroundColor White
    Write-Host "  [w] Show common workflows" -ForegroundColor White
    Write-Host "  [q] Quit" -ForegroundColor White
    Write-Host ""
}

# Show common workflows
function Show-CommonWorkflows {
    Write-Host "🔄 Common Automation Workflows:" -ForegroundColor Green
    Write-Host ""

    Write-Host "1. Feature Implementation Workflow:" -ForegroundColor Yellow
    Write-Host "   • Start: Update-FeatureImplementationState.ps1 (In Progress)" -ForegroundColor Gray
    Write-Host "   • Review: Update-CodeReviewState.ps1 (Completed)" -ForegroundColor Gray
    Write-Host "   • Test: Update-TestAuditState.ps1 (Tests Approved)" -ForegroundColor Gray
    Write-Host "   • Complete: Update-FeatureImplementationState.ps1 (Completed)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "2. Validation Workflow:" -ForegroundColor Yellow
    Write-Host "   • Individual: Update-ValidationReportState.ps1" -ForegroundColor Gray
    Write-Host "   • Batch: Start-BatchValidation.ps1" -ForegroundColor Gray
    Write-Host ""

    Write-Host "3. Sprint Completion Workflow:" -ForegroundColor Yellow
    Write-Host "   • Audit: Start-BatchAudit.ps1 (by category)" -ForegroundColor Gray
    Write-Host "   • Status: Update-BatchFeatureStatus.ps1 (Sprint completion)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "4. Release Preparation Workflow:" -ForegroundColor Yellow
    Write-Host "   • Validation: Start-BatchValidation.ps1 (all types)" -ForegroundColor Gray
    Write-Host "   • Final Status: Update-BatchFeatureStatus.ps1 (Release)" -ForegroundColor Gray
    Write-Host ""
}

# Get parameter input with validation
function Get-ParameterInput {
    param(
        [string]$ParameterName,
        [string]$Description,
        [string[]]$ValidValues = @(),
        [bool]$Required = $true
    )

    do {
        if ($ValidValues.Count -gt 0) {
            Write-Host "  $ParameterName ($Description)" -ForegroundColor Cyan
            Write-Host "    Valid values: $($ValidValues -join ', ')" -ForegroundColor Gray
        } else {
            Write-Host "  $ParameterName ($Description)" -ForegroundColor Cyan
        }

        $value = Read-Host "    Enter value"

        if ([string]::IsNullOrWhiteSpace($value) -and $Required) {
            Write-Host "    ❌ This parameter is required" -ForegroundColor Red
            continue
        }

        if ($ValidValues.Count -gt 0 -and $value -notin $ValidValues -and -not [string]::IsNullOrWhiteSpace($value)) {
            Write-Host "    ❌ Invalid value. Must be one of: $($ValidValues -join ', ')" -ForegroundColor Red
            continue
        }

        return $value
    } while ($true)
}

# Execute selected script
function Invoke-SelectedScript {
    param(
        [string]$ScriptKey,
        [hashtable]$Scripts
    )

    $script = $Scripts[$ScriptKey]
    $scriptPath = Join-Path $scriptDir $script.Name

    if (-not (Test-Path $scriptPath)) {
        Write-Host "❌ Script not found: $scriptPath" -ForegroundColor Red
        return
    }

    Write-Host "🚀 Executing: $($script.Name)" -ForegroundColor Green
    Write-Host "   Description: $($script.Description)" -ForegroundColor Gray
    Write-Host ""

    # Get common parameters based on script type
    $params = @{}

    switch ($script.Name) {
        "Update-FeatureImplementationState.ps1" {
            $params.FeatureId = Get-ParameterInput -ParameterName "FeatureId" -Description "Feature identifier (e.g., 1.2.1)"
            $params.ImplementationStatus = Get-ParameterInput -ParameterName "ImplementationStatus" -Description "Implementation status" -ValidValues @("🟡 In Progress", "🔄 Needs Revision", "🟢 Completed", "🔴 Blocked", "⏸️ On Hold")
            $params.DeveloperName = Get-ParameterInput -ParameterName "DeveloperName" -Description "Developer name"
        }
        "Update-TestAuditState.ps1" {
            $params.FeatureId = Get-ParameterInput -ParameterName "FeatureId" -Description "Feature identifier (e.g., 1.2.1)"
            $params.AuditStatus = Get-ParameterInput -ParameterName "AuditStatus" -Description "Audit status" -ValidValues @("Audit In Progress", "Tests Approved", "Tests Need Revision", "Tests Failed")
            $params.AuditorName = Get-ParameterInput -ParameterName "AuditorName" -Description "Auditor name"
        }
        "Update-CodeReviewState.ps1" {
            $params.FeatureId = Get-ParameterInput -ParameterName "FeatureId" -Description "Feature identifier (e.g., 1.2.1)"
            $params.ReviewStatus = Get-ParameterInput -ParameterName "ReviewStatus" -Description "Review status" -ValidValues @("In Progress", "Completed", "Needs Revision", "Approved")
            $params.ReviewerName = Get-ParameterInput -ParameterName "ReviewerName" -Description "Reviewer name"
        }
        "Update-ValidationReportState.ps1" {
            $params.ValidationId = Get-ParameterInput -ParameterName "ValidationId" -Description "Validation identifier (e.g., VAL-031-001)"
            $params.ValidationStatus = Get-ParameterInput -ParameterName "ValidationStatus" -Description "Validation status" -ValidValues @("Validation In Progress", "Validation Completed", "Needs Revision", "Validation Failed")
            $params.ValidatorName = Get-ParameterInput -ParameterName "ValidatorName" -Description "Validator name"
        }
        "Start-BatchValidation.ps1" {
            $params.ValidationType = Get-ParameterInput -ParameterName "ValidationType" -Description "Validation type" -ValidValues @("Architectural", "CodeQuality", "Integration", "Documentation", "Extensibility", "AIAgent")
            $featureIdsInput = Get-ParameterInput -ParameterName "FeatureIds" -Description "Feature IDs (comma-separated, e.g., 1.2.1,1.2.2,1.2.3)"
            $params.FeatureIds = $featureIdsInput -split ',' | ForEach-Object { $_.Trim() }
            $params.ValidatorName = Get-ParameterInput -ParameterName "ValidatorName" -Description "Validator name"
        }
        "Start-BatchAudit.ps1" {
            $featureIdsInput = Get-ParameterInput -ParameterName "FeatureIds" -Description "Feature IDs (comma-separated, e.g., 1.2.1,1.2.2,1.2.3)"
            $params.FeatureIds = $featureIdsInput -split ',' | ForEach-Object { $_.Trim() }
            $params.AuditorName = Get-ParameterInput -ParameterName "AuditorName" -Description "Auditor name"
            $params.FeatureCategory = Get-ParameterInput -ParameterName "FeatureCategory" -Description "Feature category" -ValidValues @("Authentication", "UI", "API", "Data", "Integration", "Foundation")
        }
        "Update-BatchFeatureStatus.ps1" {
            $featureIdsInput = Get-ParameterInput -ParameterName "FeatureIds" -Description "Feature IDs (comma-separated, e.g., 1.2.1,1.2.2,1.2.3)"
            $params.FeatureIds = $featureIdsInput -split ',' | ForEach-Object { $_.Trim() }
            $params.Status = Get-ParameterInput -ParameterName "Status" -Description "New status" -ValidValues @("🟡 In Progress", "🔄 Needs Revision", "🟢 Completed", "🔴 Blocked", "⏸️ On Hold")
            $params.UpdateType = Get-ParameterInput -ParameterName "UpdateType" -Description "Update type" -ValidValues @("StatusOnly", "Milestone", "Sprint", "Release", "Full")
        }
    }

    # Add DryRun if specified
    if ($DryRun) {
        $params.DryRun = $true
    }

    # Confirm execution
    Write-Host "📋 Execution Summary:" -ForegroundColor Yellow
    Write-Host "   Script: $($script.Name)" -ForegroundColor Gray
    Write-Host "   Parameters:" -ForegroundColor Gray
    foreach ($key in $params.Keys) {
        if ($key -eq "FeatureIds" -and $params[$key] -is [array]) {
            Write-Host "     $key = @($($params[$key] -join ', '))" -ForegroundColor Gray
        } else {
            Write-Host "     $key = $($params[$key])" -ForegroundColor Gray
        }
    }
    if ($DryRun) {
        Write-Host "   🔍 DRY RUN MODE" -ForegroundColor Yellow
    }
    Write-Host ""

    $confirm = Read-Host "Execute this script? (y/N)"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        try {
            Write-Host "🔄 Executing script..." -ForegroundColor Blue
            & $scriptPath @params
            Write-Host "✅ Script execution completed!" -ForegroundColor Green
        } catch {
            Write-Host "❌ Script execution failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Execution cancelled" -ForegroundColor Yellow
    }
}

# Main menu loop
do {
    Show-ScriptMenu -Scripts $scriptsToShow

    $selection = Read-Host "Select an option"

    switch ($selection.ToLower()) {
        'h' {
            Write-Host "📚 Help and Usage Examples:" -ForegroundColor Green
            Write-Host ""
            Write-Host "This interactive menu helps you execute Process Framework automation scripts" -ForegroundColor Gray
            Write-Host "with guided parameter input and validation." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Features:" -ForegroundColor Yellow
            Write-Host "• Interactive script selection" -ForegroundColor Gray
            Write-Host "• Guided parameter input with validation" -ForegroundColor Gray
            Write-Host "• Dry-run mode support (use -DryRun parameter)" -ForegroundColor Gray
            Write-Host "• Common workflow examples" -ForegroundColor Gray
            Write-Host ""
            Write-Host "For detailed script documentation, see:" -ForegroundColor Yellow
            Write-Host "doc/process-framework/scripts/AUTOMATION-USAGE-GUIDE.md" -ForegroundColor Gray
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
        'r' {
            Write-Host "📊 Recent Operations:" -ForegroundColor Green
            Write-Host "   (Feature not yet implemented - coming in future version)" -ForegroundColor Gray
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
        'w' {
            Show-CommonWorkflows
            Read-Host "Press Enter to continue"
        }
        'q' {
            Write-Host "👋 Goodbye!" -ForegroundColor Green
            exit 0
        }
        default {
            if ($scriptsToShow.ContainsKey($selection)) {
                Invoke-SelectedScript -ScriptKey $selection -Scripts $scriptsToShow
                Write-Host ""
                Read-Host "Press Enter to continue"
            } else {
                Write-Host "❌ Invalid selection. Please try again." -ForegroundColor Red
                Write-Host ""
            }
        }
    }

    Clear-Host
    Write-Host "🎯 Process Framework Automation Menu" -ForegroundColor Green
    Write-Host "   Interactive Script Selection and Execution" -ForegroundColor Cyan
    if ($DryRun) {
        Write-Host "   🔍 DRY RUN MODE - All operations will be simulated" -ForegroundColor Yellow
    }
    Write-Host ""

} while ($true)
