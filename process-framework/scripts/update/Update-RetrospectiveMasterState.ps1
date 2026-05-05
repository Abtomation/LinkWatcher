#!/usr/bin/env pwsh

<#
.SYNOPSIS
Atomically updates a feature's status column in the Retrospective Master State file

.DESCRIPTION
This script provides atomic updates to the Feature Inventory table in a retrospective
master state file, designed for safe use by parallel AI sessions during onboarding tasks.

Updates the following:
1. Feature Inventory table — sets the target column to the specified status emoji
2. Feature Progress Overview table — recalculates counters from actual inventory data
3. Frontmatter updated date

Column-to-Phase mapping for counter recalculation:
- Phase 1 (Discovery & Assignment) → "Impl State" column
- Phase 2 (Analysis) → "Analyzed" column
- Phase 3 (Assessment & Documentation) → "Assessed" column

.PARAMETER StateFile
Path to the retrospective master state file. Can be absolute or relative to project root.

.PARAMETER FeatureId
The feature ID to update (e.g., "0.1.0", "1.3.0")

.PARAMETER Column
The Feature Inventory column to update. Common values: "Impl State", "Analyzed",
"Assessed", "FDD", "TDD", "Test Spec", "ADR"

.PARAMETER Status
The new status. Valid values: NotStarted, InProgress, Complete, NA

.PARAMETER Notes
Optional text to append to the Notes column for this feature.

.EXAMPLE
# Claim a feature for analysis (parallel session start)
Update-RetrospectiveMasterState.ps1 -StateFile "doc/state-tracking/temporary/retrospective-master-state.md" -FeatureId "1.1.0" -Column "Analyzed" -Status "InProgress"

.EXAMPLE
# Mark analysis complete (parallel session end)
Update-RetrospectiveMasterState.ps1 -StateFile "doc/state-tracking/temporary/retrospective-master-state.md" -FeatureId "1.1.0" -Column "Analyzed" -Status "Complete"

.EXAMPLE
# Mark a documentation column as N/A
Update-RetrospectiveMasterState.ps1 -StateFile "doc/state-tracking/temporary/retrospective-master-state.md" -FeatureId "1.1.0" -Column "FDD" -Status "NA"

.NOTES
This script is designed for parallel-safe coordination during:
- Codebase Feature Analysis (PF-TSK-065) — "Analyzed" column
- Retrospective Documentation Creation (PF-TSK-066) — "Assessed", "FDD", "TDD", etc.

Output behavior: Default output is one summary line per invocation (the outcome,
e.g. "1.1.0 'Analyzed' → Done"). WARN and ERROR messages always pass through.
Pass -Verbose to restore the full play-by-play log.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$StateFile,

    [Parameter(Mandatory = $true)]
    [string]$FeatureId,

    [Parameter(Mandatory = $true)]
    [string]$Column,

    [Parameter(Mandatory = $true)]
    [ValidateSet("NotStarted", "InProgress", "Complete", "NA")]
    [string]$Status,

    [Parameter(Mandatory = $false)]
    [string]$Notes
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
# Temporarily silence $VerbosePreference around the import so -Verbose callers see
# only this script's own Write-Verbose output, not the helper module's internal chatter.
$prevVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
$VerbosePreference = $prevVerbosePreference

# Soak verification (PF-PRO-028 v2.0 Pattern A; caller-aware no-arg form)
Register-SoakScript
$soakInSoak = Test-ScriptInSoak

# Configuration
$ProjectRoot = Get-ProjectRoot
$CurrentDate = Get-Date -Format "yyyy-MM-dd"
$ScriptName = "Update-RetrospectiveMasterState.ps1"

# Status emoji mapping
$StatusEmoji = @{
    "NotStarted" = [char]::ConvertFromUtf32(0x2B1C)      # ⬜
    "InProgress" = [char]::ConvertFromUtf32(0x1F7E1)     # 🟡
    "Complete"   = [char]::ConvertFromUtf32(0x2705)       # ✅
    "NA"         = "N/A"
}

# Phase-to-column mapping for Progress Overview counter recalculation
$PhaseColumnMap = @{
    "Phase 1: Discovery & Assignment"      = "Impl State"
    "Phase 2: Analysis"                    = "Analyzed"
    "Phase 3: Assessment & Documentation"  = "Assessed"
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
    # Resolve state file path
    if (-not [System.IO.Path]::IsPathRooted($StateFile)) {
        $script:StateFile = Join-Path -Path $ProjectRoot -ChildPath $StateFile
    }

    if (-not (Test-Path $StateFile)) {
        Write-Log "State file not found: $StateFile" -Level "ERROR"
        return $false
    }

    Write-Log "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

function Update-ProgressOverviewCounters {
    <#
    .SYNOPSIS
    Recalculates the Feature Progress Overview table from actual Feature Inventory data
    #>
    param([string]$Content)

    # Parse all Feature Inventory tables
    $rows = ConvertFrom-MarkdownTable -Content $Content -Section "## Feature Inventory" -AllTables

    if ($rows.Count -eq 0) {
        Write-Log "No feature rows found in Feature Inventory" -Level "WARN"
        return $Content
    }

    # Count statuses per phase
    foreach ($phaseName in $PhaseColumnMap.Keys) {
        $columnName = $PhaseColumnMap[$phaseName]

        # Check if column exists in parsed data
        if (-not ($rows[0].PSObject.Properties.Name -contains $columnName)) {
            Write-Log "Column '$columnName' not found in Feature Inventory — skipping $phaseName counters" -Level "WARN"
            continue
        }

        $notStarted = 0
        $inProgress = 0
        $complete = 0

        foreach ($row in $rows) {
            $cellValue = $row.$columnName
            if ($cellValue -match '✅') { $complete++ }
            elseif ($cellValue -match '🟡') { $inProgress++ }
            elseif ($cellValue -match 'N/A') { <# skip N/A features #> }
            else { $notStarted++ }
        }

        $total = $notStarted + $inProgress + $complete

        # Update the Progress Overview table row for this phase
        # Match the row by phase name and replace the counter values
        $phasePattern = [regex]::Escape($phaseName)
        $rowPattern = "(\|\s*$phasePattern\s*\|)\s*\d+\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*\d+\s*\|"
        $replacement = "`${1} $notStarted | $inProgress | $complete | $total |"

        if ($Content -match $rowPattern) {
            $Content = $Content -replace $rowPattern, $replacement
            Write-Log "Updated $phaseName counters: NotStarted=$notStarted, InProgress=$inProgress, Complete=$complete" -Level "SUCCESS"
        }
        else {
            Write-Log "Could not find Progress Overview row for '$phaseName'" -Level "WARN"
        }
    }

    return $Content
}

function Update-FrontmatterDate {
    param([string]$Content)
    $result = $Content -replace '(?m)(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate
    return $result
}

# --- Main ---

function Main {
    Write-Log "Starting Retrospective Master State Update - $ScriptName"
    Write-Log "State File: $StateFile"
    Write-Log "Feature: $FeatureId | Column: $Column | Status: $Status"

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    if (-not $PSCmdlet.ShouldProcess($StateFile, "Update $FeatureId '$Column' to $Status")) {
        return
    }

    # Single read-modify-write cycle
    $content = Get-Content $StateFile -Raw

    # Step 1: Update the Feature Inventory cell
    $statusValue = $StatusEmoji[$Status]
    $updateParams = @{
        Content      = $content
        FeatureId    = $FeatureId
        MatchColumn  = "Feature ID"
        StatusColumn = $Column
        Status       = $statusValue
    }
    if ($Notes) {
        $updateParams["Notes"] = $Notes
    }

    $content = Update-MarkdownTable @updateParams

    if ($null -eq $content) {
        Write-Log "Failed to update Feature Inventory for $FeatureId" -Level "ERROR"
        exit 1
    }

    Write-Log "Updated $FeatureId '$Column' to $statusValue" -Level "SUCCESS"

    # Step 2: Recalculate Progress Overview counters
    $content = Update-ProgressOverviewCounters -Content $content

    # Step 3: Update frontmatter date
    $content = Update-FrontmatterDate -Content $content

    # Single write
    Set-Content -Path $StateFile -Value $content -NoNewline

    Write-SummaryLine "$FeatureId '$Column' → $statusValue"
}

# Execute main function with soak-verification wrapper (PF-PRO-028 v2.0)
try {
    Main
    if ($soakInSoak) { Confirm-SoakInvocation -Outcome success }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -Outcome failure -Notes $soakErrMsg
    }
    Write-ProjectError -Message "Retrospective master state update failed: $($_.Exception.Message)" -ExitCode 1
}
