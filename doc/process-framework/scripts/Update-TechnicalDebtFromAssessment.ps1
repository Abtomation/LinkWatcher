#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates the integration of technical debt items from assessments into the Technical Debt Tracking registry

.DESCRIPTION
This script automates the process of moving technical debt items from assessment documents
into the permanent technical debt tracking registry. It processes all debt items from a
specific assessment and updates the tracking file with proper bidirectional linking.

This script bridges the gap between Technical Debt Assessment creation and registry integration,
making the Technical Debt Assessment Task fully automated.

.PARAMETER AssessmentId
The assessment ID (e.g., "PF-TDA-001") to process debt items from

.PARAMETER AssessmentDirectory
Directory containing the assessment and debt item files (defaults to doc/process-framework/assessments/technical-debt/)

.PARAMETER DryRun
If specified, shows what would be done without making actual changes

.PARAMETER Force
If specified, processes items even if they appear to already be in the registry

.EXAMPLE
# Process all debt items from assessment PF-TDA-001
.\Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PF-TDA-001"

.EXAMPLE
# Dry run to see what would be processed
.\Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PF-TDA-001" -DryRun

.EXAMPLE
# Force processing even if items appear to be already added
.\Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PF-TDA-001" -Force

.NOTES
This script is part of the Technical Debt Assessment automation system and integrates with:
- Technical Debt Assessment Task (PF-TSK-023)
- New-TechnicalDebtAssessment.ps1
- New-DebtItem.ps1
- Update-TechnicalDebtTracking.ps1

The script makes the Technical Debt Assessment Task fully automated by eliminating
the manual step of updating the technical debt tracking registry.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$AssessmentId,

    [Parameter(Mandatory = $false)]
    [string]$AssessmentDirectory = "doc/process-framework/assessments/technical-debt/",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Configuration
$ScriptName = "Update-TechnicalDebtFromAssessment.ps1"
$UpdateScript = "doc/process-framework/scripts/Update-TechnicalDebtTracking.ps1"

# Import the common helpers with robust path resolution
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
}
catch {
    Write-Error "Failed to import Common-ScriptHelpers module from: $modulePath"
    Write-Error "Please ensure the script is run from the correct directory or the module path is correct."
    exit 1
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "White" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."

    if (-not (Test-Path $AssessmentDirectory)) {
        Write-Log "Assessment directory not found: $AssessmentDirectory" -Level "ERROR"
        return $false
    }

    if (-not (Test-Path $UpdateScript)) {
        Write-Log "Update script not found: $UpdateScript" -Level "ERROR"
        return $false
    }

    Write-Log "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

function Find-AssessmentDebtItems {
    param([string]$AssessmentId)

    Write-Log "Searching for debt items from assessment: $AssessmentId"

    # Look for debt item files that reference this assessment
    $debtItemsDir = Join-Path -Path $AssessmentDirectory -ChildPath "debt-items"

    if (-not (Test-Path $debtItemsDir)) {
        Write-Log "Debt items directory not found: $debtItemsDir" -Level "WARN"
        return @()
    }

    $debtItems = @()
    $debtItemFiles = Get-ChildItem -Path $debtItemsDir -Filter "*.md" -ErrorAction SilentlyContinue

    foreach ($file in $debtItemFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue

        # Check if this debt item references our assessment
        if ($content -match $AssessmentId -or $file.Name -match "PF-TDI-\d+") {
            # Extract debt item metadata
            $debtItem = Parse-DebtItemFile -FilePath $file.FullName -Content $content
            if ($debtItem) {
                $debtItems += $debtItem
            }
        }
    }

    Write-Log "Found $($debtItems.Count) debt items for assessment $AssessmentId"
    return $debtItems
}

function Parse-DebtItemFile {
    param(
        [string]$FilePath,
        [string]$Content
    )

    try {
        # Extract debt item ID from filename (PF-TDI-XXX)
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $debtItemIdMatch = [regex]::Match($fileName, 'PF-TDI-\d+')
        if (-not $debtItemIdMatch.Success) {
            Write-Log "Could not extract debt item ID from filename: $fileName" -Level "WARN"
            return $null
        }
        $debtItemId = $debtItemIdMatch.Value

        # Parse metadata and content
        $debtItem = @{
            DebtItemId = $debtItemId
            FilePath   = $FilePath
            FileName   = $fileName
        }

        # Extract title from filename (after the ID)
        $titleMatch = [regex]::Match($fileName, 'PF-TDI-\d+-(.+)')
        if ($titleMatch.Success) {
            $debtItem.Title = $titleMatch.Groups[1].Value -replace '-', ' '
        }

        # Extract metadata from content
        if ($Content -match '(?s)## Debt Item Details.*?### Category\s*([^\r\n]+)') {
            $debtItem.Category = $matches[1].Trim()
        }

        if ($Content -match '(?s)### Location/Component\s*([^\r\n]+)') {
            $debtItem.Location = $matches[1].Trim()
        }

        if ($Content -match '(?s)### Priority Assessment\s*([^\r\n]+)') {
            $debtItem.Priority = $matches[1].Trim()
        }

        if ($Content -match '(?s)### Estimated Effort\s*([^\r\n]+)') {
            $debtItem.EstimatedEffort = $matches[1].Trim()
        }

        if ($Content -match '(?s)### Description\s*([^\r\n]+)') {
            $debtItem.Description = $matches[1].Trim()
        }

        # Check registry integration status
        $debtItem.AlreadyAdded = $Content -match 'Registry Status:\s*Added'

        if ($Content -match 'Registry ID:\s*([^\r\n]+)') {
            $registryId = $matches[1].Trim()
            if ($registryId -ne 'TBD' -and $registryId -ne '') {
                $debtItem.RegistryId = $registryId
            }
        }

        return $debtItem
    }
    catch {
        Write-Log "Error parsing debt item file $FilePath`: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Process-DebtItem {
    param(
        [hashtable]$DebtItem,
        [string]$AssessmentId,
        [bool]$DryRun,
        [bool]$Force
    )

    $debtItemId = $DebtItem.DebtItemId
    $title = $DebtItem.Title

    Write-Log "Processing debt item: $debtItemId - $title"

    # Check if already added (unless Force is specified)
    if ($DebtItem.AlreadyAdded -and -not $Force) {
        Write-Log "Debt item $debtItemId already marked as added to registry (use -Force to override)" -Level "WARN"
        return $false
    }

    # Validate required fields
    $missingFields = @()
    if (-not $DebtItem.Description -or $DebtItem.Description -eq '') { $missingFields += 'Description' }
    if (-not $DebtItem.Category -or $DebtItem.Category -eq '') { $missingFields += 'Category' }
    if (-not $DebtItem.Location -or $DebtItem.Location -eq '') { $missingFields += 'Location' }
    if (-not $DebtItem.Priority -or $DebtItem.Priority -eq '') { $missingFields += 'Priority' }
    if (-not $DebtItem.EstimatedEffort -or $DebtItem.EstimatedEffort -eq '') { $missingFields += 'EstimatedEffort' }

    if ($missingFields.Count -gt 0) {
        Write-Log "Debt item $debtItemId is missing required fields: $($missingFields -join ', ')" -Level "ERROR"
        return $false
    }

    if ($DryRun) {
        Write-Log "[DRY RUN] Would add debt item to registry:" -Level "INFO"
        Write-Log "  Description: $($DebtItem.Description)" -Level "INFO"
        Write-Log "  Category: $($DebtItem.Category)" -Level "INFO"
        Write-Log "  Location: $($DebtItem.Location)" -Level "INFO"
        Write-Log "  Priority: $($DebtItem.Priority)" -Level "INFO"
        Write-Log "  Estimated Effort: $($DebtItem.EstimatedEffort)" -Level "INFO"
        return $true
    }

    # Build the command to add the debt item
    $addCommand = @(
        $UpdateScript,
        "-Operation", "Add",
        "-Description", "`"$($DebtItem.Description)`"",
        "-Category", "`"$($DebtItem.Category)`"",
        "-Location", "`"$($DebtItem.Location)`"",
        "-Priority", "`"$($DebtItem.Priority)`"",
        "-EstimatedEffort", "`"$($DebtItem.EstimatedEffort)`"",
        "-AssessmentId", "`"$AssessmentId`"",
        "-DebtItemId", "`"$debtItemId`""
    )

    try {
        Write-Log "Executing: $($addCommand -join ' ')"
        $result = & $addCommand[0] $addCommand[1..($addCommand.Length - 1)]

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully added debt item $debtItemId to registry" -Level "SUCCESS"
            return $true
        }
        else {
            Write-Log "Failed to add debt item $debtItemId to registry (exit code: $LASTEXITCODE)" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Error executing update command for $debtItemId`: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Main {
    Write-Log "Starting Technical Debt Assessment Integration - $ScriptName"
    Write-Log "Assessment ID: $AssessmentId"
    Write-Log "Assessment Directory: $AssessmentDirectory"

    if ($DryRun) {
        Write-Log "DRY RUN MODE - No changes will be made" -Level "WARN"
    }

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    # Find all debt items for this assessment
    $debtItems = Find-AssessmentDebtItems -AssessmentId $AssessmentId

    if ($debtItems.Count -eq 0) {
        Write-Log "No debt items found for assessment $AssessmentId" -Level "WARN"
        exit 0
    }

    Write-Log "Processing $($debtItems.Count) debt items..."

    $successCount = 0
    $failureCount = 0

    foreach ($debtItem in $debtItems) {
        if (Process-DebtItem -DebtItem $debtItem -AssessmentId $AssessmentId -DryRun $DryRun -Force $Force) {
            $successCount++
        }
        else {
            $failureCount++
        }
    }

    Write-Log "Processing complete:" -Level "SUCCESS"
    Write-Log "  Successfully processed: $successCount items" -Level "SUCCESS"
    Write-Log "  Failed to process: $failureCount items" -Level $(if ($failureCount -gt 0) { "ERROR" } else { "SUCCESS" })

    if (-not $DryRun) {
        Write-Log "Technical debt tracking registry has been updated" -Level "SUCCESS"
        Write-Log "All debt items from assessment $AssessmentId have been integrated" -Level "SUCCESS"
    }

    exit $(if ($failureCount -gt 0) { 1 } else { 0 })
}

# Execute main function
Main
