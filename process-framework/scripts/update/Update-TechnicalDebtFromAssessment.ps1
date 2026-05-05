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
Directory containing the assessment and debt item files (defaults to process-framework/assessments/technical-debt/)

.PARAMETER DryRun
If specified, shows what would be done without making actual changes

.PARAMETER Force
If specified, processes items even if they appear to already be in the registry

.EXAMPLE
# Process all debt items from assessment PF-TDA-001
../Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PF-TDA-001"

.EXAMPLE
# Dry run to see what would be processed
../Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PF-TDA-001" -DryRun

.EXAMPLE
# Force processing even if items appear to be already added
../Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PF-TDA-001" -Force

.NOTES
This script is part of the Technical Debt Assessment automation system and integrates with:
- Technical Debt Assessment Task (PF-TSK-023)
- New-TechnicalDebtAssessment.ps1
- New-DebtItem.ps1
- Update-TechDebt.ps1

The script makes the Technical Debt Assessment Task fully automated by eliminating
the manual step of updating the technical debt tracking registry.

Output behavior: Default output is one summary line per invocation (the outcome,
e.g. "PF-TDA-001 → 7 items added (0 failed)"). WARN and ERROR messages always
pass through. Pass -Verbose to restore the full play-by-play log for debugging.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$AssessmentId,

    [Parameter(Mandatory = $false)]
    [string]$AssessmentDirectory = "../process-framework/assessments/technical-debt",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Configuration
$ScriptName = "../Update-TechnicalDebtFromAssessment.ps1"
$UpdateScript = "../process-framework/scripts/update/Update-TechDebt.ps1"

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

function Write-Log {
    # Default-quiet logger. INFO/SUCCESS go to Write-Verbose (visible only with -Verbose).
    # WARN/ERROR are always emitted to host. The single per-invocation summary line
    # is emitted directly via Write-SummaryLine, bypassing this gate.
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    switch ($Level) {
        "ERROR"   { Write-Host $line -ForegroundColor Red }
        "WARN"    { Write-Host $line -ForegroundColor Yellow }
        default   { Write-Verbose $line }
    }
}

function Write-SummaryLine {
    # One-line visible outcome per invocation. Bypasses Write-Log's default-quiet gate.
    param([string]$Message, [string]$Level = "SUCCESS")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR"   { "Red" }
        "WARN"    { "Yellow" }
        default   { "Green" }
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
        if ($content -match $AssessmentId -or $file.Name -match "^PF-TDI-\d+") {
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
    if (-not $DebtItem.Dim -or $DebtItem.Dim -eq '') { $missingFields += 'Dim' }
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
        Write-Log "  Dim: $($DebtItem.Dim)" -Level "INFO"
        Write-Log "  Location: $($DebtItem.Location)" -Level "INFO"
        Write-Log "  Priority: $($DebtItem.Priority)" -Level "INFO"
        Write-Log "  Estimated Effort: $($DebtItem.EstimatedEffort)" -Level "INFO"
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

    $dryNote = if ($DryRun) { " (DRY RUN — no changes written)" } else { "" }
    if ($failureCount -gt 0) {
        Write-SummaryLine "$AssessmentId → $successCount items added, $failureCount failed$dryNote" -Level "ERROR"
    } else {
        Write-SummaryLine "$AssessmentId → $successCount items added$dryNote"
    }

    exit $(if ($failureCount -gt 0) { 1 } else { 0 })
}

# Execute main function
Main
