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

.PARAMETER Metric
The metric name for multi-metric tests (e.g., "scan", "move"). Required when
the test has multiple metric rows; omit for single-metric tests (Metric = "—").

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
# Update a multi-metric test (specify -Metric to disambiguate the row)
Update-PerformanceTracking.ps1 -TestId "PH-001" -Metric "scan" -NewStatus "Baselined" -LastResult "9.30s"

.EXAMPLE
# Dry-run to preview changes
Update-PerformanceTracking.ps1 -TestId "BM-001" -NewStatus "Baselined" -LastResult "148.0 files/sec" -WhatIf

.NOTES
This script is part of the Performance Testing automation system and integrates with:
- Performance & E2E Test Scoping (PF-TSK-086) — creates ⬜ Needs Creation entries via New-PerformanceTestEntry.ps1
- Performance Test Creation (PF-TSK-084) — transitions ⬜ → 📋
- Performance Baseline Capture (PF-TSK-085) — transitions 📋 → ✅, refreshes results

Output behavior: Default output is one summary line per invocation (the outcome,
e.g. "BM-001 → Baselined"). WARN and ERROR messages always pass through.
Pass -Verbose to restore the full play-by-play log for debugging.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(BM|PH)-(\d{3}|[A-Z]+)$')]
    [string]$TestId,

    [Parameter(Mandatory = $false)]
    [string]$Metric,

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
#   [1]  = Metric         (metric name for multi-metric tests, "—" otherwise)
#   [2]  = Operation      (description)
#   [3]  = Related Features
#   [4]  = Status         (emoji + text)
#   [5]  = Baseline       (measurement with units)
#   [6]  = Tolerance      (threshold)
#   [7]  = Last Result    (most recent measurement)
#   [8]  = Last Run       (date YYYY-MM-DD)
#   [9]  = Test File      (markdown link or —)
#   [10] = Audit Status   (emoji + text or —)
#   [11] = Audit Report   (markdown link or —)
#   [12] = Spec Ref       (specification reference or —)

# Valid status transitions: from → [allowed targets]
$ValidTransitions = @{
    "NeedsCreation"   = @("NeedsBaseline")
    "NeedsBaseline"   = @("Baselined")
    "Baselined"       = @("Baselined", "NeedsRebaseline")
    "NeedsRebaseline" = @("Baselined")
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

function Resolve-TestRow {
    # Returns the matching row object, or $null if no match / ambiguous match.
    # When -Metric is specified, requires exact (Test ID, Metric) match.
    # When -Metric is omitted, requires exactly one row with the given Test ID
    # (i.e., a single-metric test); errors with "Test has multiple metrics" if
    # there are multiple matching rows.
    param(
        [array]$Rows,
        [string]$TestId,
        [string]$Metric
    )

    $candidates = @($Rows | Where-Object { $_.'Test ID' -eq $TestId })
    if ($candidates.Count -eq 0) {
        Write-Log "Test entry not found: $TestId" -Level "ERROR"
        return $null
    }

    if ($Metric) {
        $exact = $candidates | Where-Object { $_.Metric -eq $Metric } | Select-Object -First 1
        if (-not $exact) {
            $available = ($candidates | ForEach-Object { $_.Metric } | Where-Object { $_ }) -join ', '
            Write-Log "Test entry not found: $TestId [Metric=$Metric]. Available metrics: $available" -Level "ERROR"
            return $null
        }
        return $exact
    }

    if ($candidates.Count -gt 1) {
        $available = ($candidates | ForEach-Object { $_.Metric } | Where-Object { $_ }) -join ', '
        Write-Log "Test $TestId has multiple metric rows ($available); specify -Metric to disambiguate" -Level "ERROR"
        return $null
    }

    return $candidates[0]
}

function Update-TestEntryContent {
    param(
        [string]$Content,
        [string]$TestId,
        [string]$Metric,
        [string]$NewStatus,
        [hashtable]$UpdateData
    )

    # Find test entry row across all level subsections (column-aware lookup).
    $rows = ConvertFrom-MarkdownTable -Content $Content -Section "## Test Inventory" -AllTables -IncludeRawLine
    $row = Resolve-TestRow -Rows $rows -TestId $TestId -Metric $Metric
    if (-not $row) {
        return $null
    }

    $rowLabel = if ($row.Metric -and $row.Metric -ne '—') { "$TestId [$($row.Metric)]" } else { $TestId }
    Write-Log "Found test entry for $rowLabel"
    $currentEntry = $row._RawLine

    # Parse using Split-MarkdownTableRow
    $columns = Split-MarkdownTableRow -Line $currentEntry
    if ($null -eq $columns -or $columns.Count -lt 11) {
        Write-Log "Failed to parse table row for $rowLabel (expected 12 columns, got $($columns.Count))" -Level "ERROR"
        return $null
    }

    # Determine current status and validate transition
    $currentStatus = Get-CurrentStatus -StatusCell $columns[4]
    if ($null -eq $currentStatus) {
        Write-Log "Could not determine current status from cell: '$($columns[4])'" -Level "ERROR"
        return $null
    }

    $allowedTargets = $ValidTransitions[$currentStatus]
    if ($NewStatus -notin $allowedTargets) {
        Write-Log "Invalid transition: $currentStatus → $NewStatus. Allowed: $($allowedTargets -join ', ')" -Level "ERROR"
        return $null
    }

    Write-Log "Status transition: $($StatusEmojis[$currentStatus]) $($StatusDisplay[$currentStatus]) → $($StatusEmojis[$NewStatus]) $($StatusDisplay[$NewStatus])"

    # Update status column
    $columns[4] = "$($StatusEmojis[$NewStatus]) $($StatusDisplay[$NewStatus])"

    # Update optional columns
    if ($UpdateData.TestFile)   { $columns[9] = $UpdateData.TestFile }
    if ($UpdateData.Baseline)   { $columns[5] = $UpdateData.Baseline }
    if ($UpdateData.LastResult) { $columns[7] = $UpdateData.LastResult }
    if ($UpdateData.Tolerance)  { $columns[6] = $UpdateData.Tolerance }
    if ($UpdateData.SpecRef)    { $columns[12] = $UpdateData.SpecRef }

    # LastRun: use provided date or default to today
    $columns[8] = $UpdateData.LastRun

    # Reconstruct row using ConvertTo-MarkdownTableRow
    $updatedEntry = ConvertTo-MarkdownTableRow -Cells $columns
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-Log "Updated ${rowLabel}: $($StatusEmojis[$NewStatus]) $($StatusDisplay[$NewStatus])" -Level "SUCCESS"
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
    # Multi-metric tests have one row per metric but should count as one test in
    # the Summary. Track which (level, test_id) pairs we've already counted.
    $seen = @{}
    foreach ($line in ($Content -split "\r?\n")) {
        # Detect level section headers
        foreach ($header in $levelMap.Keys) {
            if ($line -match [regex]::Escape($header)) {
                $currentLevel = $levelMap[$header]
            }
        }

        # Stop at Summary section
        if ($line -match "^## Summary") { break }

        # Count data rows (deduplicated by Test ID within each level)
        if ($currentLevel -and $line -match "^\|\s*((BM|PH)-(\d{3}|[A-Z]+))\s*\|") {
            $rowTestId = $matches[1]
            $key = "$currentLevel/$rowTestId"
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true
            $counts[$currentLevel].Total++
            # Parse Status column (column 5 post Metric-column addition) explicitly:
            # matching the whole line would conflate the Lifecycle Status with
            # the Audit Status column, which also uses ✅ (for "✅ Audit Approved").
            $cells = $line -split '\|'
            $statusCell = if ($cells.Count -gt 5) { $cells[5].Trim() } else { '' }
            if ($statusCell -match "✅") { $counts[$currentLevel].Baselined++ }
            elseif ($statusCell -match "📋") { $counts[$currentLevel].NeedsBaseline++ }
            elseif ($statusCell -match "⬜") { $counts[$currentLevel].NeedsCreation++ }
            elseif ($statusCell -match "⚠️") { $counts[$currentLevel].NeedsRebaseline++ }
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

    # Locate Summary section to scope replacements (prevents collateral damage
    # to inventory table headers that also contain the literal "Operation").
    $summaryStart = $Content.IndexOf("## Summary")
    if ($summaryStart -lt 0) {
        Write-Log "Summary section not found in tracking file — skipping summary update" -Level "WARN"
        return $Content
    }
    $nextHeader = [regex]::Match($Content.Substring($summaryStart + 1), "(?m)^##\s")
    $summaryEnd = if ($nextHeader.Success) { $summaryStart + 1 + $nextHeader.Index } else { $Content.Length }
    $preamble = $Content.Substring(0, $summaryStart)
    $summary  = $Content.Substring($summaryStart, $summaryEnd - $summaryStart)
    $postamble = $Content.Substring($summaryEnd)

    # Replace each summary row (within Summary section only)
    $levelOrder = @("Component", "Operation", "Scale", "Resource")
    foreach ($level in $levelOrder) {
        $c = $counts[$level]
        $oldPattern = "\|\s*$level\s*\|[^\r\n]*"
        $newRow = "| $level | $($c.Total) | $($c.Baselined) | $($c.NeedsBaseline) | $($c.NeedsCreation) | $($c.NeedsRebaseline) |"
        $summary = [regex]::Replace($summary, $oldPattern, $newRow)
    }

    # Replace total row (bold formatting; safe but kept inside scope for consistency)
    $t = $totalCounts
    $oldTotalPattern = "\|\s*\*\*Total\*\*\s*\|[^\r\n]*"
    $newTotalRow = "| **Total** | **$($t.Total)** | **$($t.Baselined)** | **$($t.NeedsBaseline)** | **$($t.NeedsCreation)** | **$($t.NeedsRebaseline)** |"
    $summary = [regex]::Replace($summary, $oldTotalPattern, $newTotalRow)

    $Content = $preamble + $summary + $postamble

    Write-Log "Updated Summary table: $($t.Total) total ($($t.Baselined) baselined, $($t.NeedsBaseline) needs baseline, $($t.NeedsCreation) needs creation, $($t.NeedsRebaseline) needs re-baseline)" -Level "SUCCESS"
    return $Content
}

function Main {
    Write-Log "Starting Performance Tracking Update - $ScriptName"
    Write-Log "Test ID: $TestId"
    if ($Metric) { Write-Log "Metric: $Metric" }
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
            # Read current status to check if Baseline is required (column-aware lookup)
            $tempContent = Get-Content $TrackingFile -Raw
            $tempRows = ConvertFrom-MarkdownTable -Content $tempContent -Section "## Test Inventory" -AllTables -IncludeRawLine
            $tempRow = Resolve-TestRow -Rows $tempRows -TestId $TestId -Metric $Metric
            if ($tempRow) {
                $tempColumns = Split-MarkdownTableRow -Line $tempRow._RawLine
                $currentStatus = Get-CurrentStatus -StatusCell $tempColumns[4]
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
    $content = Update-TestEntryContent -Content $content -TestId $TestId -Metric $Metric -NewStatus $NewStatus -UpdateData $updateData
    if ($null -eq $content) {
        Write-Log "Performance tracking update failed" -Level "ERROR"
        exit 1
    }

    # Step 2: Recalculate summary table
    $content = Update-SummaryTableContent -Content $content

    # Single write — guarded by ShouldProcess so -WhatIf skips only the file write
    $rowLabel = if ($Metric) { "$TestId [$Metric]" } else { $TestId }
    if ($PSCmdlet.ShouldProcess($TrackingFile, "Update $rowLabel to $NewStatus")) {
        Set-Content -Path $TrackingFile -Value $content -NoNewline
        Write-SummaryLine "$rowLabel → $NewStatus"
    } else {
        Write-Log "Dry-run complete — no file changes written" -Level "INFO"
    }
    exit 0
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
    Write-ProjectError -Message "Performance tracking update failed: $($_.Exception.Message)" -ExitCode 1
}
