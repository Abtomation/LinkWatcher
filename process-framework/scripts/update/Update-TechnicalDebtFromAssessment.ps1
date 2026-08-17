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
The assessment ID (e.g., "PD-TDA-001") to process debt items from

.PARAMETER AssessmentDirectory
Directory containing the assessment and debt item files. Defaults to <project-root>/doc/technical-debt
(resolved via Get-ProjectRoot); pass an explicit path to scan a fixture or non-default tree.

.PARAMETER Force
If specified, processes items even if they appear to already be in the registry

.EXAMPLE
# Process all debt items from assessment PD-TDA-001
../Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PD-TDA-001"

.EXAMPLE
# Preview (no writes) what would be processed
../Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PD-TDA-001" -WhatIf

.EXAMPLE
# Force processing even if items appear to be already added
../Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PD-TDA-001" -Force

.NOTES
This script is part of the Technical Debt Assessment automation system and integrates with:
- Technical Debt Assessment Task (PF-TSK-023)
- New-TechnicalDebtAssessment.ps1
- New-DebtItem.ps1
- Update-TechDebt.ps1

The script makes the Technical Debt Assessment Task fully automated by eliminating
the manual step of updating the technical debt tracking registry.

Output behavior: Default output is one summary line per invocation (the outcome,
e.g. "PD-TDA-001 → 7 items added (0 failed)"). WARN and ERROR messages always
pass through. Pass -Verbose to restore the full play-by-play log for debugging.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$AssessmentId,

    [Parameter(Mandatory = $false)]
    [string]$AssessmentDirectory = "",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Configuration
$ScriptName = "Update-TechnicalDebtFromAssessment.ps1"
$UpdateScript = $null  # resolved after module import (needs Get-ProcessFrameworkPath)

# Import the common helpers with walk-up path resolution
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$dir = $scriptDir
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
try {
    # Temporarily silence $VerbosePreference around the import so -Verbose callers see
    # only this script's own Write-Verbose output, not the helper module's internal chatter.
    $prevVerbosePreference = $VerbosePreference
    $VerbosePreference = 'SilentlyContinue'
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
    $VerbosePreference = $prevVerbosePreference
}
catch {
    Write-Error "Failed to import Common-ScriptHelpers module. Searched up from: $scriptDir"
    exit 1
}

# Resolve paths against the project root (cwd-independent). Debt items live under
# doc/technical-debt/ per the PD-TDI / PD-TDA registry entries; the -AssessmentDirectory
# override lets callers (and tests) point at a fixture tree instead.
if ([string]::IsNullOrWhiteSpace($AssessmentDirectory)) {
    $AssessmentDirectory = Join-Path (Get-ProjectRoot) "doc/technical-debt"
}
$UpdateScript = Join-Path (Get-ProcessFrameworkPath) "scripts/update/Update-TechDebt.ps1"

function Test-Prerequisites {
    Write-ProjectLog "Checking prerequisites..."

    if (-not (Test-Path $AssessmentDirectory)) {
        Write-ProjectLog "Assessment directory not found: $AssessmentDirectory" -Level "ERROR"
        return $false
    }

    if (-not (Test-Path $UpdateScript)) {
        Write-ProjectLog "Update script not found: $UpdateScript" -Level "ERROR"
        return $false
    }

    Write-ProjectLog "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

function Find-AssessmentDebtItems {
    param([string]$AssessmentId)

    Write-ProjectLog "Searching for debt items from assessment: $AssessmentId"

    # Look for debt item files that reference this assessment
    $debtItemsDir = Join-Path -Path $AssessmentDirectory -ChildPath "debt-items"

    if (-not (Test-Path $debtItemsDir)) {
        Write-ProjectLog "Debt items directory not found: $debtItemsDir" -Level "WARN"
        return @()
    }

    $debtItems = @()
    $debtItemFiles = Get-ChildItem -Path $debtItemsDir -Filter "*.md" -ErrorAction SilentlyContinue

    foreach ($file in $debtItemFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue

        # Check if this debt item references our assessment
        if ($content -match $AssessmentId -or $file.Name -match "^PD-TDI-\d+") {
            # Extract debt item metadata
            $debtItem = ConvertFrom-DebtItemFile -FilePath $file.FullName -Content $content
            if ($debtItem) {
                $debtItems += $debtItem
            }
        }
    }

    Write-ProjectLog "Found $($debtItems.Count) debt items for assessment $AssessmentId"
    return $debtItems
}

function ConvertFrom-DebtItemFile {
    param(
        [string]$FilePath,
        [string]$Content
    )

    try {
        # Extract debt item ID from filename (PD-TDI-XXX)
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $debtItemIdMatch = [regex]::Match($fileName, 'PD-TDI-\d+')
        if (-not $debtItemIdMatch.Success) {
            Write-ProjectLog "Could not extract debt item ID from filename: $fileName" -Level "WARN"
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
        $titleMatch = [regex]::Match($fileName, 'PD-TDI-\d+-(.+)')
        if ($titleMatch.Success) {
            $debtItem.Title = $titleMatch.Groups[1].Value -replace '-', ' '
        }

        # Extract metadata from content — aligned with current debt-item-template.md structure.
        # Strategy: frontmatter for structured fields (dim/priority/location); Item Overview bullets as fallback;
        # Problem Statement paragraph for description; Total Estimated Effort bullet for effort.

        # Parse frontmatter block first
        if ($Content -match '(?ms)^---\s*\r?\n(.*?)^---') {
            $frontmatter = $matches[1]
            if ($frontmatter -match '(?m)^debt_dim:\s*([^\r\n]+)')      { $debtItem.Dim      = $matches[1].Trim() }
            if ($frontmatter -match '(?m)^debt_priority:\s*([^\r\n]+)') { $debtItem.Priority = $matches[1].Trim() }
            if ($frontmatter -match '(?m)^debt_location:\s*([^\r\n]+)') { $debtItem.Location = $matches[1].Trim() }
        }

        # Item Overview bullets — richer source, also used as fallback for frontmatter placeholders
        if ($Content -match '(?m)^-\s*\*\*Dimension\*\*:\s*([^\r\n]+)') {
            $bulletDim = $matches[1].Trim()
            if (-not $debtItem.Dim -or $debtItem.Dim -like '`[*`]*') { $debtItem.Dim = $bulletDim }
        }
        if ($Content -match '(?m)^-\s*\*\*Priority\*\*:\s*([^\r\n]+)') {
            $bulletPriority = $matches[1].Trim()
            if (-not $debtItem.Priority -or $debtItem.Priority -like '`[*`]*') { $debtItem.Priority = $bulletPriority }
        }
        if ($Content -match '(?m)^-\s*\*\*Location/Component\*\*:\s*([^\r\n]+)') {
            $bulletLocation = $matches[1].Trim()
            if (-not $debtItem.Location -or $debtItem.Location -like '`[*`]*') { $debtItem.Location = $bulletLocation }
        }

        # Description: first non-blank line under ### Problem Statement
        if ($Content -match '(?s)### Problem Statement\s*\r?\n\s*([^\r\n]+)') {
            $debtItem.Description = $matches[1].Trim()
        }

        # Estimated Effort: summary value from "Total Estimated Effort" bullet under ### Estimated Effort
        if ($Content -match '(?m)^-\s*\*\*Total Estimated Effort\*\*:\s*([^\r\n]+)') {
            $debtItem.EstimatedEffort = $matches[1].Trim()
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
        Write-ProjectLog "Error parsing debt item file $FilePath`: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Invoke-DebtItemProcessing {
    param(
        [hashtable]$DebtItem,
        [string]$AssessmentId,
        [bool]$DryRun,
        [bool]$Force
    )

    $debtItemId = $DebtItem.DebtItemId
    $title = $DebtItem.Title

    Write-ProjectLog "Processing debt item: $debtItemId - $title"

    # Check if already added (unless Force is specified)
    if ($DebtItem.AlreadyAdded -and -not $Force) {
        Write-ProjectLog "Debt item $debtItemId already marked as added to registry (use -Force to override)" -Level "WARN"
        return $false
    }

    # Validate required fields
    $missingFields = @()
    if (-not $DebtItem.Description -or $DebtItem.Description -eq '') { $missingFields += 'Description' }
    if (-not $DebtItem.Dim -or $DebtItem.Dim -eq '') { $missingFields += 'Dim' }
    if (-not $DebtItem.Location -or $DebtItem.Location -eq '') { $missingFields += 'Location' }
    if (-not $DebtItem.Priority -or $DebtItem.Priority -eq '') { $missingFields += 'Priority' }
    if (-not $DebtItem.EstimatedEffort -or $DebtItem.EstimatedEffort -eq '') { $missingFields += 'EstimatedEffort' }

    if ($missingFields.Count -gt 0) {
        Write-ProjectLog "Debt item $debtItemId is missing required fields: $($missingFields -join ', ')" -Level "ERROR"
        return $false
    }

    if ($DryRun) {
        Write-ProjectLog "[DRY RUN] Would add debt item to registry:" -Level "INFO"
        Write-ProjectLog "  Description: $($DebtItem.Description)" -Level "INFO"
        Write-ProjectLog "  Dim: $($DebtItem.Dim)" -Level "INFO"
        Write-ProjectLog "  Location: $($DebtItem.Location)" -Level "INFO"
        Write-ProjectLog "  Priority: $($DebtItem.Priority)" -Level "INFO"
        Write-ProjectLog "  Estimated Effort: $($DebtItem.EstimatedEffort)" -Level "INFO"
        return $true
    }

    # Build the command to add the debt item
    $addCommand = @(
        $UpdateScript,
        "-Add",
        "-Description", "`"$($DebtItem.Description)`"",
        "-Dims", "`"$($DebtItem.Dim)`"",
        "-Location", "`"$($DebtItem.Location)`"",
        "-Priority", "`"$($DebtItem.Priority)`"",
        "-EstimatedEffort", "`"$($DebtItem.EstimatedEffort)`"",
        "-AssessmentId", "`"$AssessmentId`"",
        "-DebtItemId", "`"$debtItemId`"",
        "-Confirm:`$false"
    )

    try {
        Write-ProjectLog "Executing: $($addCommand -join ' ')"
        $null = & $addCommand[0] $addCommand[1..($addCommand.Length - 1)]

        if ($LASTEXITCODE -eq 0) {
            Write-ProjectLog "Successfully added debt item $debtItemId to registry" -Level "SUCCESS"
            return $true
        }
        else {
            Write-ProjectLog "Failed to add debt item $debtItemId to registry (exit code: $LASTEXITCODE)" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-ProjectLog "Error executing update command for $debtItemId`: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Main {
    Write-ProjectLog "Starting Technical Debt Assessment Integration - $ScriptName"
    Write-ProjectLog "Assessment ID: $AssessmentId"
    Write-ProjectLog "Assessment Directory: $AssessmentDirectory"

    if ($DryRun) {
        Write-ProjectLog "WHATIF PREVIEW MODE - No changes will be made" -Level "WARN"
    }

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    # Find all debt items for this assessment
    $debtItems = Find-AssessmentDebtItems -AssessmentId $AssessmentId

    if ($debtItems.Count -eq 0) {
        Write-ProjectLog "No debt items found for assessment $AssessmentId" -Level "WARN"
        exit 0
    }

    Write-ProjectLog "Processing $($debtItems.Count) debt items..."

    $successCount = 0
    $failureCount = 0

    foreach ($debtItem in $debtItems) {
        if (Invoke-DebtItemProcessing -DebtItem $debtItem -AssessmentId $AssessmentId -DryRun $DryRun -Force $Force) {
            $successCount++
        }
        else {
            $failureCount++
        }
    }

    $dryNote = if ($DryRun) { " (WhatIf preview — no changes written)" } else { "" }
    if ($failureCount -gt 0) {
        Write-ProjectSummary "$AssessmentId → $successCount items added, $failureCount failed$dryNote" -Level "ERROR"
    } else {
        Write-ProjectSummary "$AssessmentId → $successCount items added$dryNote"
    }

    exit $(if ($failureCount -gt 0) { 1 } else { 0 })
}

# -DryRun replaced by standard -WhatIf (SupportsShouldProcess): ShouldProcess returning
# $false (under -WhatIf) drives the existing dry-run preview path in Main.
$DryRun = -not $PSCmdlet.ShouldProcess($AssessmentId, "Integrate technical-debt items into the tracking registry")

# Execute main function
Main
