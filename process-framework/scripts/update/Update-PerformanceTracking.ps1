#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates status transitions and column updates in performance-test-tracking.md

.DESCRIPTION
This script automates performance test lifecycle management in the
test/state-tracking/permanent/performance-test-tracking.md state file.

Updates the following file:
- test/state-tracking/permanent/performance-test-tracking.md

Supports the complete performance test lifecycle:
- ⬜ Needs Creation → 📋 Needs Baseline (Performance Test Creation — PF-TSK-084)
- 📋 Needs Baseline → ✅ Baselined (Performance Baseline Capture — PF-TSK-085)
- ✅ Baselined → ⚠️ Needs Re-baseline (Baseline Capture — stale detection)
- ⚠️ Needs Re-baseline → ✅ Baselined (Baseline Capture — re-baseline)
- ✅ Baselined → ✅ Baselined (Baseline Capture — refresh results without status change)

After each row update, the Summary table is automatically recalculated.

.PARAMETER TestId
The test ID to update (e.g., "BM-001", "PH-003")

.PARAMETER NewStatus
The new lifecycle status for the test. Valid values:
- "NeedsBaseline" (📋) — test code implemented, requires -TestFile
- "Baselined" (✅) — baseline captured, requires -Baseline
- "NeedsRebaseline" (⚠️) — baseline stale, needs re-capture

.PARAMETER TestFile
Path to the test file (relative to project root, with markdown link format).
Required when transitioning to Created.
Example: "[test_benchmark.py](/test/automated/performance/test_benchmark.py)"

.PARAMETER Baseline
Baseline measurement value with units.
Required when transitioning to Baselined (from Created or Stale).
Example: "144.0 files/sec", "2.06s (48.6 files/sec)"

.PARAMETER LastResult
Most recent measured value. Updated alongside status changes.
Example: "144.0 files/sec"

.PARAMETER LastRun
Date of last test run (YYYY-MM-DD format). Defaults to today if omitted.

.PARAMETER Tolerance
Update the tolerance threshold. Optional.
Example: ">50 files/sec", "<10s"

.PARAMETER SpecRef
Update the specification reference. Optional.
Example: "TE-TSP-039"

.EXAMPLE
# Mark a test as implemented (Needs Creation → Needs Baseline)
Update-PerformanceTracking.ps1 -TestId "BM-007" -NewStatus "NeedsBaseline" -TestFile "[test_new.py](/test/automated/performance/test_new.py)"

.EXAMPLE
# Capture initial baseline (Needs Baseline → Baselined)
Update-PerformanceTracking.ps1 -TestId "BM-007" -NewStatus "Baselined" -Baseline "120.0 files/sec" -LastResult "120.0 files/sec"

.EXAMPLE
# Refresh baseline results without status change
Update-PerformanceTracking.ps1 -TestId "BM-001" -NewStatus "Baselined" -LastResult "148.0 files/sec"

.EXAMPLE
# Mark test as stale
Update-PerformanceTracking.ps1 -TestId "BM-001" -NewStatus "NeedsRebaseline"

.EXAMPLE
# Re-baseline a stale test
Update-PerformanceTracking.ps1 -TestId "BM-001" -NewStatus "Baselined" -Baseline "148.0 files/sec" -LastResult "148.0 files/sec"

.EXAMPLE
# Dry-run to preview changes
Update-PerformanceTracking.ps1 -TestId "BM-001" -NewStatus "Baselined" -LastResult "148.0 files/sec" -WhatIf

.NOTES
This script is part of the Performance Testing automation system and integrates with:
- Performance & E2E Test Scoping (PF-TSK-086) — creates ⬜ Needs Creation entries via New-PerformanceTestEntry.ps1
- Performance Test Creation (PF-TSK-084) — transitions ⬜ → 📋
- Performance Baseline Capture (PF-TSK-085) — transitions 📋 → ✅, refreshes results
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(BM|PH)-(\d{3}|[A-Z]+)$')]
    [string]$TestId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("NeedsBaseline", "Baselined", "NeedsRebaseline")]
    [string]$NewStatus,

    [Parameter(Mandatory = $false)]
    [string]$TestFile,

    [Parameter(Mandatory = $false)]
    [string]$Baseline,

    [Parameter(Mandatory = $false)]
    [string]$LastResult,

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$LastRun,

    [Parameter(Mandatory = $false)]
    [string]$Tolerance,

    [Parameter(Mandatory = $false)]
    [string]$SpecRef
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Configuration
$ProjectRoot = Get-ProjectRoot
$TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "test/state-tracking/permanent/performance-test-tracking.md"
$ScriptName = "Update-PerformanceTracking.ps1"

# Status emoji mapping
$StatusEmojis = @{
    "NeedsCreation"   = "⬜"
    "NeedsBaseline"   = "📋"
    "Baselined"       = "✅"
    "NeedsRebaseline" = "⚠️"
}

# Status display names (for data cell text)
$StatusDisplay = @{
    "NeedsCreation"   = "Needs Creation"
    "NeedsBaseline"   = "Needs Baseline"
    "Baselined"       = "Baselined"
    "NeedsRebaseline" = "Needs Re-baseline"
}

# Column index mapping for performance-test-tracking.md table rows
# After Split-MarkdownTableRow:
#   [0]  = Test ID        (e.g., BM-001)
#   [1]  = Operation      (description)
#   [2]  = Related Features
#   [3]  = Status         (emoji + text)
#   [4]  = Baseline       (measurement with units)
#   [5]  = Tolerance      (threshold)
#   [6]  = Last Result    (most recent measurement)
#   [7]  = Last Run       (date YYYY-MM-DD)
#   [8]  = Test File      (markdown link or —)
#   [9]  = Audit Status   (emoji + text or —)
#   [10] = Audit Report   (markdown link or —)
#   [11] = Spec Ref       (specification reference or —)

# Valid status transitions: from → [allowed targets]
$ValidTransitions = @{
    "NeedsCreation"   = @("NeedsBaseline")
    "NeedsBaseline"   = @("Baselined")
    "Baselined"       = @("Baselined", "NeedsRebaseline")
    "NeedsRebaseline" = @("Baselined")
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            "ERROR"   { "Red" }
            "WARN"    { "Yellow" }
            "SUCCESS" { "Green" }
            default   { "White" }
        }
    )
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."

    if (-not (Test-Path $TrackingFile)) {
        Write-Log "Performance test tracking file not found: $TrackingFile" -Level "ERROR"
        return $false
    }

    Write-Log "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

function Get-CurrentStatus {
    param([string]$StatusCell)
    foreach ($key in $StatusEmojis.Keys) {
        if ($StatusCell -match [regex]::Escape($StatusEmojis[$key])) {
            return $key
        }
    }
    return $null
}

function Update-TestEntryContent {
    param(
        [string]$Content,
        [string]$TestId,
        [string]$NewStatus,
        [hashtable]$UpdateData
    )

    # Find test entry row
    $testPattern = "\|\s*$([regex]::Escape($TestId))\s*\|[^\r\n]*"
    $match = [regex]::Match($Content, $testPattern)

    if (-not $match.Success) {
        Write-Log "Test entry not found: $TestId" -Level "ERROR"
        return $null
    }

    Write-Log "Found test entry for $TestId"
    $currentEntry = $match.Value

    # Parse using Split-MarkdownTableRow
    $columns = Split-MarkdownTableRow -Line $currentEntry
    if ($null -eq $columns -or $columns.Count -lt 10) {
        Write-Log "Failed to parse table row for $TestId (expected 10 columns, got $($columns.Count))" -Level "ERROR"
        return $null
    }

    # Determine current status and validate transition
    $currentStatus = Get-CurrentStatus -StatusCell $columns[3]
    if ($null -eq $currentStatus) {
        Write-Log "Could not determine current status from cell: '$($columns[3])'" -Level "ERROR"
        return $null
    }

    $allowedTargets = $ValidTransitions[$currentStatus]
    if ($NewStatus -notin $allowedTargets) {
        Write-Log "Invalid transition: $currentStatus → $NewStatus. Allowed: $($allowedTargets -join ', ')" -Level "ERROR"
        return $null
    }

    Write-Log "Status transition: $($StatusEmojis[$currentStatus]) $($StatusDisplay[$currentStatus]) → $($StatusEmojis[$NewStatus]) $($StatusDisplay[$NewStatus])"

    # Update status column
    $columns[3] = "$($StatusEmojis[$NewStatus]) $($StatusDisplay[$NewStatus])"

    # Update optional columns
    if ($UpdateData.TestFile)  { $columns[8] = $UpdateData.TestFile }
    if ($UpdateData.Baseline)  { $columns[4] = $UpdateData.Baseline }
    if ($UpdateData.LastResult) { $columns[6] = $UpdateData.LastResult }
    if ($UpdateData.Tolerance) { $columns[5] = $UpdateData.Tolerance }
    if ($UpdateData.SpecRef)   { $columns[11] = $UpdateData.SpecRef }

    # LastRun: use provided date or default to today
    $columns[7] = $UpdateData.LastRun

    # Reconstruct row using ConvertTo-MarkdownTableRow
    $updatedEntry = ConvertTo-MarkdownTableRow -Cells $columns
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-Log "Updated ${TestId}: $($StatusEmojis[$NewStatus]) $($StatusDisplay[$NewStatus])" -Level "SUCCESS"
    return $result
}

function Update-SummaryTableContent {
    param([string]$Content)

    # Count tests per level and status by scanning inventory sections
    $levelMap = @{
        "Component Benchmarks (Level 1)" = "Component"
        "Operation Benchmarks (Level 2)" = "Operation"
        "Scale Tests (Level 3)"          = "Scale"
        "Resource Bounds (Level 4)"      = "Resource"
    }

    $counts = @{}
    foreach ($level in $levelMap.Values) {
        $counts[$level] = @{ Total = 0; Baselined = 0; NeedsBaseline = 0; NeedsCreation = 0; NeedsRebaseline = 0 }
    }

    $currentLevel = ""
    foreach ($line in ($Content -split "\r?\n")) {
        # Detect level section headers
        foreach ($header in $levelMap.Keys) {
            if ($line -match [regex]::Escape($header)) {
                $currentLevel = $levelMap[$header]
            }
        }

        # Stop at Summary section
        if ($line -match "^## Summary") { break }

        # Count data rows
        if ($currentLevel -and $line -match "^\|\s*(BM|PH)-") {
            $counts[$currentLevel].Total++
            if ($line -match "✅") { $counts[$currentLevel].Baselined++ }
            elseif ($line -match "📋") { $counts[$currentLevel].NeedsBaseline++ }
            elseif ($line -match "⬜") { $counts[$currentLevel].NeedsCreation++ }
            elseif ($line -match "⚠️") { $counts[$currentLevel].NeedsRebaseline++ }
        }
    }

    # Calculate totals
    $totalCounts = @{ Total = 0; Baselined = 0; NeedsBaseline = 0; NeedsCreation = 0; NeedsRebaseline = 0 }
    $statusKeys = @("Total", "Baselined", "NeedsBaseline", "NeedsCreation", "NeedsRebaseline")
    foreach ($level in @("Component", "Operation", "Scale", "Resource")) {
        foreach ($status in $statusKeys) {
            $totalCounts[$status] += $counts[$level][$status]
        }
    }

    # Replace each summary row
    $levelOrder = @("Component", "Operation", "Scale", "Resource")
    foreach ($level in $levelOrder) {
        $c = $counts[$level]
        $oldPattern = "\|\s*$level\s*\|[^\r\n]*"
        $newRow = "| $level | $($c.Total) | $($c.Baselined) | $($c.NeedsBaseline) | $($c.NeedsCreation) | $($c.NeedsRebaseline) |"
        $Content = [regex]::Replace($Content, $oldPattern, $newRow)
    }

    # Replace total row (bold formatting)
    $t = $totalCounts
    $oldTotalPattern = "\|\s*\*\*Total\*\*\s*\|[^\r\n]*"
    $newTotalRow = "| **Total** | **$($t.Total)** | **$($t.Baselined)** | **$($t.NeedsBaseline)** | **$($t.NeedsCreation)** | **$($t.NeedsRebaseline)** |"
    $Content = [regex]::Replace($Content, $oldTotalPattern, $newTotalRow)

    Write-Log "Updated Summary table: $($t.Total) total ($($t.Baselined) baselined, $($t.NeedsBaseline) needs baseline, $($t.NeedsCreation) needs creation, $($t.NeedsRebaseline) needs re-baseline)" -Level "SUCCESS"
    return $Content
}

function Main {
    Write-Log "Starting Performance Tracking Update - $ScriptName"
    Write-Log "Test ID: $TestId"
    Write-Log "New Status: $NewStatus"

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    # Validate required parameters for specific transitions
    switch ($NewStatus) {
        "NeedsBaseline" {
            if (-not $TestFile) {
                Write-Log "TestFile is required when transitioning to NeedsBaseline status" -Level "ERROR"
                exit 1
            }
        }
        "Baselined" {
            # Read current status to check if Baseline is required
            $tempContent = Get-Content $TrackingFile -Raw
            $testPattern = "\|\s*$([regex]::Escape($TestId))\s*\|[^\r\n]*"
            $testMatch = [regex]::Match($tempContent, $testPattern)
            if ($testMatch.Success) {
                $tempColumns = Split-MarkdownTableRow -Line $testMatch.Value
                $currentStatus = Get-CurrentStatus -StatusCell $tempColumns[3]
                # Baseline is required when transitioning FROM NeedsBaseline or NeedsRebaseline
                if ($currentStatus -in @("NeedsBaseline", "NeedsRebaseline") -and -not $Baseline) {
                    Write-Log "Baseline is required when transitioning from $($StatusDisplay[$currentStatus]) to Baselined" -Level "ERROR"
                    exit 1
                }
                # When refreshing (Baselined → Baselined), LastResult is required
                if ($currentStatus -eq "Baselined" -and -not $LastResult) {
                    Write-Log "LastResult is required when refreshing a Baselined test" -Level "ERROR"
                    exit 1
                }
            }
        }
    }

    # Default LastRun to today
    if (-not $LastRun) {
        $LastRun = Get-Date -Format "yyyy-MM-dd"
    }

    # Prepare update data
    $updateData = @{
        LastRun = $LastRun
    }
    if ($TestFile)   { $updateData.TestFile = $TestFile }
    if ($Baseline)   { $updateData.Baseline = $Baseline }
    if ($LastResult)  { $updateData.LastResult = $LastResult }
    if ($Tolerance)  { $updateData.Tolerance = $Tolerance }
    if ($SpecRef)    { $updateData.SpecRef = $SpecRef }

    # Single read-modify-write cycle
    $content = Get-Content $TrackingFile -Raw

    # Step 1: Update the test entry row
    $content = Update-TestEntryContent -Content $content -TestId $TestId -NewStatus $NewStatus -UpdateData $updateData
    if ($null -eq $content) {
        Write-Log "Performance tracking update failed" -Level "ERROR"
        exit 1
    }

    # Step 2: Recalculate summary table
    $content = Update-SummaryTableContent -Content $content

    # Single write — guarded by ShouldProcess so -WhatIf skips only the file write
    if ($PSCmdlet.ShouldProcess($TrackingFile, "Update $TestId to $NewStatus")) {
        Set-Content -Path $TrackingFile -Value $content -NoNewline
        Write-Log "Performance tracking update completed successfully" -Level "SUCCESS"
        Write-Log "Updated file: $TrackingFile"
    } else {
        Write-Log "Dry-run complete — no file changes written" -Level "INFO"
    }
    exit 0
}

# Execute main function
Main
