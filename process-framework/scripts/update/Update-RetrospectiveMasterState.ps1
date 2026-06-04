#!/usr/bin/env pwsh

<#
.SYNOPSIS
Atomically updates a retrospective master state file — Feature Inventory rows, Unassigned Files batch flips, or Coverage Metrics recalculation

.DESCRIPTION
This script provides atomic updates to a retrospective master state file, designed
for safe use by parallel AI sessions during onboarding tasks. Three parameter sets:

FeatureInventory (default — existing behavior):
1. Feature Inventory table — sets a row's column to the specified status emoji
2. Feature Progress Overview table — recalculates counters from actual inventory data
3. Frontmatter updated date

MarkProcessed (PF-IMP-759):
1. Unassigned Files table — flips the Status column ⬜→✅ for the listed file paths
   in a single atomic read-modify-write (replaces N sequential Edit calls per session)
2. Coverage Metrics bullets — recalculates Files Assigned / Unassigned / Coverage %
3. Frontmatter updated date

RecalculateMetrics (PF-IMP-759):
1. Coverage Metrics bullets — recalculates from Unassigned Files Status counts
   (no flipping; intended to fix drift if Coverage Metrics was hand-edited)
2. Frontmatter updated date

Column-to-Phase mapping for Feature Progress Overview counter recalculation:
- Phase 1 (Discovery & Assignment) → "Impl State" column
- Phase 2 (Analysis) → "Analyzed" column
- Phase 3 (Assessment & Documentation) → "Assessed" column

.PARAMETER StateFile
Path to the retrospective master state file. Can be absolute or relative to project root.

.PARAMETER FeatureId
[FeatureInventory] The feature ID to update (e.g., "0.1.0", "1.3.0")

.PARAMETER Column
[FeatureInventory] The Feature Inventory column to update. Common values: "Impl State",
"Analyzed", "Assessed", "FDD", "TDD", "Test Spec", "ADR"

.PARAMETER Status
[FeatureInventory] The new status. Valid values: NotStarted, InProgress, Complete, NA

.PARAMETER Notes
[FeatureInventory] Optional text to append to the Notes column for this feature.

.PARAMETER FilePaths
[MarkProcessed] One or more file paths to mark as processed in the Unassigned Files table.
Path matching is tolerant of markdown link format ([text](path)), backticks (`path`),
and bare paths. A leading "/" is normalized away on both sides for comparison.

.PARAMETER RecalculateMetrics
[RecalculateMetrics] Switch — only recalculate Coverage Metrics bullets from current
Unassigned Files Status counts. No table flips.

.EXAMPLE
# Claim a feature for analysis (parallel session start)
Update-RetrospectiveMasterState.ps1 -StateFile "doc/state-tracking/temporary/retrospective-master-state.md" -FeatureId "1.1.0" -Column "Analyzed" -Status "InProgress"

.EXAMPLE
# Mark a documentation column as N/A
Update-RetrospectiveMasterState.ps1 -StateFile "doc/state-tracking/temporary/retrospective-master-state.md" -FeatureId "1.1.0" -Column "FDD" -Status "NA"

.EXAMPLE
# Bulk-flip 23 files to ✅ in Unassigned Files (PF-TSK-064 Phase 2 session end)
Update-RetrospectiveMasterState.ps1 -StateFile "doc/state-tracking/temporary/retrospective-master-state.md" -FilePaths @("src/foo.py","src/bar.py","ui/baz.py")

.EXAMPLE
# Repair Coverage Metrics drift without flipping any rows
Update-RetrospectiveMasterState.ps1 -StateFile "doc/state-tracking/temporary/retrospective-master-state.md" -RecalculateMetrics

.NOTES
This script is designed for parallel-safe coordination during:
- Codebase Feature Discovery (PF-TSK-064) — "Impl State" column + Unassigned Files (MarkProcessed mode)
- Codebase Feature Analysis (PF-TSK-065) — "Analyzed" column
- Retrospective Documentation Creation (PF-TSK-066) — "Assessed", "FDD", "TDD", etc.

Output behavior: Default output is one summary line per invocation (the outcome,
e.g. "1.1.0 'Analyzed' → Done", or "MarkProcessed: 23 flipped, 0 already done, 0 not found").
WARN and ERROR messages always pass through. Pass -Verbose to restore the full
play-by-play log.
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'FeatureInventory')]
param(
    [Parameter(Mandatory = $true)]
    [string]$StateFile,

    [Parameter(Mandatory = $true, ParameterSetName = 'FeatureInventory')]
    [string]$FeatureId,

    [Parameter(Mandatory = $true, ParameterSetName = 'FeatureInventory')]
    [string]$Column,

    [Parameter(Mandatory = $true, ParameterSetName = 'FeatureInventory')]
    [ValidateSet("NotStarted", "InProgress", "Complete", "NA")]
    [string]$Status,

    [Parameter(Mandatory = $false, ParameterSetName = 'FeatureInventory')]
    [string]$Notes,

    [Parameter(Mandatory = $true, ParameterSetName = 'MarkProcessed')]
    [string[]]$FilePaths,

    [Parameter(Mandatory = $true, ParameterSetName = 'RecalculateMetrics')]
    [switch]$RecalculateMetrics
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

function Get-NormalizedFilePath {
    # Normalize a file-path cell or user-supplied path for comparison: extract URL from
    # markdown links, strip backticks, drop a leading "/", lowercase the drive letter
    # if Windows-absolute. Preserves path separators as-is (no slash/backslash flip).
    param([string]$Value)

    if (-not $Value) { return "" }
    $v = $Value.Trim()

    # Markdown link [text](url) → url
    if ($v -match '^\[[^\]]*\]\(([^)]+)\)') { $v = $matches[1].Trim() }
    # Backticked `path` → path
    if ($v -match '^`([^`]+)`$') { $v = $matches[1].Trim() }
    # Strip a single leading slash (common in absolute-from-repo links)
    if ($v.StartsWith("/")) { $v = $v.Substring(1) }

    return $v
}

function Update-UnassignedFileStatus {
    <#
    .SYNOPSIS
    Section-scoped flip of Status column ⬜→✅ for listed file paths in the
    Unassigned Files table. Returns @{ Content; Flipped; AlreadyDone; NotFound }.
    #>
    param(
        [string]$Content,
        [string[]]$FilePaths
    )

    # Normalize user-supplied paths for matching
    $wantedSet = @{}
    foreach ($p in $FilePaths) {
        $norm = Get-NormalizedFilePath $p
        if ($norm) { $wantedSet[$norm] = $true }
    }

    $lines = $Content -split "`r?`n"
    $output = New-Object System.Collections.Generic.List[string]
    $inSection = $false
    $inTable = $false
    $headers = @()
    $colIndices = @{}
    $pathColIdx = -1
    $statusColIdx = -1
    $flipped = 0
    $alreadyDone = 0
    $matched = @{}

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Section boundaries
        if ($line -match '^##\s+Unassigned Files\s*$') {
            $inSection = $true
            $output.Add($line) | Out-Null
            continue
        }
        if ($inSection -and $line -match '^##\s' -and $line -notmatch '^##\s+Unassigned Files') {
            $inSection = $false
            $inTable = $false
        }

        if ($inSection -and -not $inTable -and $line -match '^\|.*\|$') {
            # Header row
            $inTable = $true
            $headers = Split-MarkdownTableRow $line
            $colIndices = @{}
            for ($j = 0; $j -lt $headers.Count; $j++) {
                if ($headers[$j]) { $colIndices[$headers[$j]] = $j }
            }
            if (-not $colIndices.ContainsKey('File Path')) {
                Write-Log "Unassigned Files table missing 'File Path' column" -Level "WARN"
            }
            if (-not $colIndices.ContainsKey('Status')) {
                Write-Log "Unassigned Files table missing 'Status' column" -Level "WARN"
            }
            $pathColIdx = if ($colIndices.ContainsKey('File Path')) { $colIndices['File Path'] } else { -1 }
            $statusColIdx = if ($colIndices.ContainsKey('Status')) { $colIndices['Status'] } else { -1 }
            $output.Add($line) | Out-Null
            continue
        }

        if ($inTable -and $line -match '^\|[-\s:]+\|$') {
            # Separator row
            $output.Add($line) | Out-Null
            continue
        }

        if ($inTable -and $line -match '^\|.*\|$') {
            $columns = Split-MarkdownTableRow $line
            if ($pathColIdx -ge 0 -and $pathColIdx -lt $columns.Count) {
                $cellPath = Get-NormalizedFilePath $columns[$pathColIdx]
                if ($wantedSet.ContainsKey($cellPath)) {
                    $matched[$cellPath] = $true
                    if ($statusColIdx -ge 0 -and $statusColIdx -lt $columns.Count) {
                        if ($columns[$statusColIdx] -match '✅') {
                            $alreadyDone++
                        }
                        else {
                            $columns[$statusColIdx] = '✅'
                            $flipped++
                        }
                    }
                    $output.Add((ConvertTo-MarkdownTableRow -Cells $columns)) | Out-Null
                    continue
                }
            }
            $output.Add($line) | Out-Null
            continue
        }

        if ($inTable -and $line -notmatch '^\|.*\|$') {
            $inTable = $false
        }

        $output.Add($line) | Out-Null
    }

    $notFound = @()
    foreach ($k in $wantedSet.Keys) {
        if (-not $matched.ContainsKey($k)) { $notFound += $k }
    }

    return @{
        Content     = ($output -join "`n")
        Flipped     = $flipped
        AlreadyDone = $alreadyDone
        NotFound    = $notFound
    }
}

function Get-UnassignedFileCounts {
    # Walk Unassigned Files table, return @{ Assigned; Unassigned } from Status column.
    param([string]$Content)

    $lines = $Content -split "`r?`n"
    $inSection = $false
    $inTable = $false
    $statusColIdx = -1
    $assigned = 0
    $unassigned = 0

    foreach ($line in $lines) {
        if ($line -match '^##\s+Unassigned Files\s*$') { $inSection = $true; continue }
        if ($inSection -and $line -match '^##\s' -and $line -notmatch '^##\s+Unassigned Files') {
            break
        }
        if ($inSection -and -not $inTable -and $line -match '^\|.*\|$') {
            $inTable = $true
            $headers = Split-MarkdownTableRow $line
            for ($j = 0; $j -lt $headers.Count; $j++) {
                if ($headers[$j] -eq 'Status') { $statusColIdx = $j; break }
            }
            continue
        }
        if ($inTable -and $line -match '^\|[-\s:]+\|$') { continue }
        if ($inTable -and $line -match '^\|.*\|$') {
            $cols = Split-MarkdownTableRow $line
            if ($statusColIdx -ge 0 -and $statusColIdx -lt $cols.Count) {
                if ($cols[$statusColIdx] -match '✅') { $assigned++ }
                elseif ($cols[$statusColIdx] -match '⬜') { $unassigned++ }
            }
            continue
        }
        if ($inTable -and $line -notmatch '^\|.*\|$') { $inTable = $false }
    }

    return @{ Assigned = $assigned; Unassigned = $unassigned }
}

function Update-CoverageMetrics {
    <#
    .SYNOPSIS
    Recalculates Coverage Metrics bullets from Unassigned Files Status counts.
    "Total Project Source Files" is preserved (population-level count set at
    master-state creation; not derived from the table).
    #>
    param([string]$Content)

    $counts = Get-UnassignedFileCounts -Content $Content
    $assigned = $counts.Assigned
    $unassigned = $counts.Unassigned

    # Read the existing Total (preserve)
    $total = 0
    if ($Content -match '(?m)^\s*-\s+\*\*Total Project Source Files\*\*:\s*(\d+)') {
        $total = [int]$matches[1]
    }
    else {
        Write-Log "Could not parse Total Project Source Files from Coverage Metrics — skipping Coverage % recalc" -Level "WARN"
    }

    $coveragePct = if ($total -gt 0) { [math]::Round(($assigned / $total) * 100, 1) } else { 0 }

    # Update bullets — anchored regexes that preserve any trailing parenthetical commentary
    $Content = $Content -replace '(?m)^(\s*-\s+\*\*Files Assigned to Features\*\*:\s*)\S+(.*)$', "`${1}$assigned`$2"
    $Content = $Content -replace '(?m)^(\s*-\s+\*\*Unassigned Files\*\*:\s*)\S+(.*)$', "`${1}$unassigned`$2"
    if ($total -gt 0) {
        $Content = $Content -replace '(?m)^(\s*-\s+\*\*Coverage\*\*:\s*)\S+(.*)$', "`${1}$coveragePct%`$2"
    }

    Write-Log "Coverage Metrics recalculated: Assigned=$assigned, Unassigned=$unassigned, Coverage=$coveragePct%" -Level "SUCCESS"
    return $Content
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

# --- Main ---

function Main {
    Write-Log "Starting Retrospective Master State Update - $ScriptName"
    Write-Log "State File: $StateFile"
    Write-Log "Parameter Set: $($PSCmdlet.ParameterSetName)"

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    $action = switch ($PSCmdlet.ParameterSetName) {
        'FeatureInventory'     { "Update $FeatureId '$Column' to $Status" }
        'MarkProcessed'        { "Mark $($FilePaths.Count) file(s) processed in Unassigned Files" }
        'RecalculateMetrics'   { "Recalculate Coverage Metrics" }
    }

    if (-not $PSCmdlet.ShouldProcess($StateFile, $action)) {
        return
    }

    # Single read
    $content = Get-Content $StateFile -Raw

    switch ($PSCmdlet.ParameterSetName) {
        'FeatureInventory' {
            # Step 1: Update the Feature Inventory cell
            $statusValue = $StatusEmoji[$Status]
            $updateParams = @{
                Content      = $content
                FeatureId    = $FeatureId
                MatchColumn  = "Feature ID"
                StatusColumn = $Column
                Status       = $statusValue
            }
            if ($Notes) { $updateParams["Notes"] = $Notes }

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

            Set-Content -Path $StateFile -Value $content -NoNewline
            Write-SummaryLine "$FeatureId '$Column' → $statusValue"
        }

        'MarkProcessed' {
            $result = Update-UnassignedFileStatus -Content $content -FilePaths $FilePaths
            $content = $result.Content

            if ($result.NotFound.Count -gt 0) {
                Write-Log "Paths not found in Unassigned Files table: $($result.NotFound -join '; ')" -Level "WARN"
            }

            # Recalculate Coverage Metrics + frontmatter
            $content = Update-CoverageMetrics -Content $content
            $content = Update-FrontmatterDate -Content $content

            Set-Content -Path $StateFile -Value $content -NoNewline

            $summary = "MarkProcessed: $($result.Flipped) flipped, $($result.AlreadyDone) already done, $($result.NotFound.Count) not found"
            $level = if ($result.NotFound.Count -gt 0) { "WARN" } else { "SUCCESS" }
            Write-SummaryLine $summary -Level $level
        }

        'RecalculateMetrics' {
            $content = Update-CoverageMetrics -Content $content
            $content = Update-FrontmatterDate -Content $content
            Set-Content -Path $StateFile -Value $content -NoNewline

            $counts = Get-UnassignedFileCounts -Content $content
            Write-SummaryLine "Recalculated: Assigned=$($counts.Assigned), Unassigned=$($counts.Unassigned)"
        }
    }
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
