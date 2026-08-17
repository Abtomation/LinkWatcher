# New-Exploration.ps1
# Adds a new technical exploration item to the Technical Exploration Tracking state file
# Uses the central ID registry system for auto-assigned PD-EXP IDs

<#
.SYNOPSIS
    Adds a new technical exploration item to technical-exploration-tracking.md with an auto-assigned ID.

.DESCRIPTION
    This PowerShell script files exploration spikes — bounded research investigations that must
    resolve before dependent design or implementation can proceed — by:
    - Generating a unique exploration ID (PD-EXP-###) via the central ID registry
    - Adding a row to the "Active Explorations" table at status 📥 Queued
    - Adding an Update History entry
    - Updating the frontmatter date

    An exploration is an open question to answer before building. Deferred rework from a
    shortcut already taken is technical debt (New-DebtItem.ps1 / technical-debt-tracking.md),
    not an exploration. Framework research belongs in central process-improvement tracking.

    The filed row is consumed by the Technical Exploration task (PF-TSK-093), which executes
    the spike and resolves the row via Update-Exploration.ps1.

.PARAMETER Source
    Display text for the producer of this item (e.g., "Feature Discovery PF-TSK-013", "User request")

.PARAMETER SourceLink
    Optional markdown link target for the source. When provided, the Source column renders as [Source](SourceLink).

.PARAMETER Description
    The research question to answer (10-500 chars; state it so that "answered" is unambiguous —
    compress longer drafts and move detailed context to -Notes).

.PARAMETER Priority
    Priority level: HIGH, MEDIUM, or LOW — driven by how soon the dependent work starts.

.PARAMETER RelatedFeature
    Feature ID this exploration blocks (optional). Omit for a pre-feature or cross-cutting spike.

.PARAMETER Notes
    Additional context, acceptance criteria, or details (optional)

.PARAMETER UpdatedBy
    Who created the entry (default: "AI Agent (PF-TSK-013)")

.PARAMETER TrackingFile
    Override for the tracking file path. Defaults to the project's
    doc/state-tracking/permanent/technical-exploration-tracking.md (resolved via Resolve-DocPath,
    so it routes correctly in appdev too). Primarily a sandbox/test entry point.

.EXAMPLE
    New-Exploration.ps1 -Source "Feature Discovery PF-TSK-013" -Description "Which booking engine meets our reservation requirements?" -Priority "HIGH"

.EXAMPLE
    New-Exploration.ps1 -Source "Feature Request Evaluation" -Description "Confirm Mollie supports split payments for marketplace flows" -Priority "MEDIUM" -RelatedFeature "3.2.1" -Notes "Blocks the payments design chain"

.NOTES
    - Automatically updates the central ID registry with new ID assignments
    - Adds the entry to the "Active Explorations" table at 📥 Queued
    - The Findings Doc column is left empty — it is filled by the Technical Exploration task
      (PF-TSK-093) via Update-Exploration.ps1 once research produces a PD-TEC document
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateLength(3, 200)]
    [string]$Source,

    [Parameter(Mandatory = $false)]
    [string]$SourceLink = "",

    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if ($_.Length -lt 10) {
            throw "Description is too short ($($_.Length) chars; minimum 10). State the research question so that 'answered' is unambiguous."
        }
        if ($_.Length -gt 500) {
            $over = $_.Length - 500
            throw "Description is too long ($($_.Length) chars; maximum 500, $over over). For table-row brevity, compress the question and move detailed context to -Notes."
        }
        $true
    })]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [ValidateSet("HIGH", "MEDIUM", "LOW")]
    [string]$Priority,

    [Parameter(Mandatory = $false)]
    [string]$RelatedFeature = "",

    [Parameter(Mandatory = $false)]
    [string]$Notes = "",

    [Parameter(Mandatory = $false)]
    [string]$UpdatedBy = "AI Agent (PF-TSK-013)",

    [Parameter(Mandatory = $false)]
    [string]$TrackingFile = ""
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
Invoke-StandardScriptInitialization

# MSYS path-mangling guard for user-provided -SourceLink (PF-IMP-767). On Windows + bash,
# leading-slash paths are silently rewritten to "C:/Program Files/Git/..." before PowerShell
# sees them — landing mangled values in the tracking file. Helper no-ops on empty input.
if (Test-MSYSPathMangled -Path $SourceLink -ParameterName 'SourceLink') {
    exit 1
}

# Soak verification (PF-PRO-028 v2.0 Pattern A; caller-aware no-arg form)
Register-SoakScript
$soakInSoak = Test-ScriptInSoak

# Soak-verification wrapper begins (PF-PRO-028 v2.0)
try {

# Configuration
# project_id-aware path routing via Resolve-DocPath (PF-IMP-871): a hardcoded `doc/...` breaks in
# appdev (PRJ-000), where doc template material lives at blueprint/doc/... A caller-supplied
# -TrackingFile overrides the resolved default (sandbox test entry point).
if (-not $TrackingFile) {
    $TrackingFile = Resolve-DocPath -Subpath "state-tracking/permanent/technical-exploration-tracking.md"
}
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

if (-not (Test-Path $TrackingFile)) {
    Write-ProjectError -Message "Tracking file not found: $TrackingFile" -ExitCode 1
}

# Early WhatIf check — exit before consuming an ID from the registry
if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Add new technical exploration '$Description'")) {
    return
}

# Generate unique exploration ID using the central registry
$ExplorationId = New-ProjectId -Prefix "PD-EXP" -Description "Technical Exploration: $Description"

Write-Host "Adding technical exploration: $ExplorationId" -ForegroundColor Yellow
Write-Host "Question: $Description" -ForegroundColor Cyan

# Build the Source column
$SourceColumn = if ($SourceLink -ne "") {
    "[$Source]($SourceLink)"
} else {
    $Source
}

# Em-dash placeholder for the columns this script does not fill
$FeatureColumn = if ($RelatedFeature -ne "") { $RelatedFeature } else { "—" }

# Read current content
$Content = Get-Content -Path $TrackingFile -Raw -Encoding UTF8

# Build the table row — header-driven (PF-IMP-1599): cells are ordered by the live table's own
# header, so a column added to the tracker lands as "—" in the correct position instead of
# silently shifting every following cell. Findings Doc takes the default — it is filled by the
# Technical Exploration task (PF-TSK-093) via Update-Exploration.ps1.
$TableRow = New-HeaderDrivenTableRow -Content $Content -SectionHeading '## Active Explorations' -ValueMap @{
    'ID'              = $ExplorationId
    'Source'          = $SourceColumn
    'Description'     = $Description
    'Related Feature' = $FeatureColumn
    'Priority'        = $Priority
    'Status'          = '📥 Queued'
    'Last Updated'    = $CurrentDate
    'Notes'           = $Notes
}

# Find insertion point: after the last data row in the "Active Explorations" table
$lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

$insertAfterIndex = -1
$inActiveSection = $false
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^## Active Explorations") { $inActiveSection = $true }
    if ($inActiveSection) {
        # Match any EXP row
        if ($lines[$i] -match "^\|\s*PD-EXP-\d+") { $insertAfterIndex = $i }
        # Stop at the next section
        if ($lines[$i] -match "^## " -and $lines[$i] -notmatch "^## Active Explorations") { break }
    }
}

# If no data rows found, insert after the table header separator
if ($insertAfterIndex -eq -1) {
    $inActiveSection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Active Explorations") { $inActiveSection = $true }
        if ($inActiveSection -and $lines[$i] -match "^\|\s*-") {
            $insertAfterIndex = $i
            break
        }
    }
}

if ($insertAfterIndex -eq -1) {
    Write-ProjectError -Message "Could not find insertion point in Active Explorations table" -ExitCode 1
}

$lines.Insert($insertAfterIndex + 1, $TableRow)
Write-Host "Inserted $ExplorationId into Active Explorations table" -ForegroundColor Green

# Add Update History entry
$HistoryNote = "Added $ExplorationId`: $Description"
$historyInsertIndex = -1
$inHistorySection = $false
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^## Update History") { $inHistorySection = $true }
    if ($inHistorySection -and $lines[$i] -match "^\|[^-]" -and $lines[$i] -notmatch "^\|\s*Date") {
        $historyInsertIndex = $i
    }
}

# If no data rows in history, insert after the separator
if ($historyInsertIndex -eq -1) {
    $inHistorySection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Update History") { $inHistorySection = $true }
        if ($inHistorySection -and $lines[$i] -match "^\|\s*-") {
            $historyInsertIndex = $i
            break
        }
    }
}

if ($historyInsertIndex -ne -1) {
    $historyRow = "| $CurrentDate | $HistoryNote | $UpdatedBy |"
    $lines.Insert($historyInsertIndex + 1, $historyRow)
    Write-Host "Added Update History entry" -ForegroundColor Green
}

# Update frontmatter date via the shared helper — it carries the (?m) multiline modifier the
# hand-rolled form omits. Without (?m), `^` anchors to start-of-STRING, so the pattern can never
# match an `updated:` line that is not the document's first line (i.e. always) and the write is a
# silent no-op.
$updatedContent = ($lines -join "`r`n")
$updatedContent = Update-FrontmatterDate -Content $updatedContent -CurrentDate $CurrentDate

try {
    Set-Content -Path $TrackingFile -Value $updatedContent -NoNewline -Encoding UTF8

    # Verify deterministic post-condition: row was inserted and matches the table schema (PF-PRO-028 v2.0 / PF-IMP-1563)
    Assert-TableRowInFile -Path $TrackingFile -Pattern "\| $ExplorationId \|" -Context "technical exploration row for $ExplorationId in $TrackingFile"

    $details = @(
        "ID: $ExplorationId",
        "Source: $Source",
        "Priority: $Priority",
        "Status: 📥 Queued"
    )

    if ($RelatedFeature -ne "") {
        $details += "Related Feature: $RelatedFeature"
    }

    if ($Notes -ne "") {
        $details += "Notes: $Notes"
    }

    Write-ProjectSuccess -Message "Created technical exploration: $ExplorationId" -Details $details

    Write-Verbose "Next Steps: Use Technical Exploration (PF-TSK-093) to execute this spike"
    Write-Verbose "Next Steps: Use Update-Exploration.ps1 to advance status and link the findings document"
}
catch {
    Write-ProjectError -Message "Failed to create technical exploration entry: $($_.Exception.Message)" -ExitCode 1
}

    # Soak: success outcome (PF-PRO-028 v2.0)
    if ($soakInSoak) { Confirm-SoakInvocation -Outcome success }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -Outcome failure -Notes $soakErrMsg
    }
    Write-ProjectError -Message "Technical exploration creation failed: $($_.Exception.Message)" -ExitCode 1
}
