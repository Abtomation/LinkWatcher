# New-E2EScenarioGap.ps1
# Adds a Discovered Scenario Gaps row to e2e-test-tracking.md
# References an existing WF-xxx ID from user-workflow-tracking.md

<#
.SYNOPSIS
    Adds a discovered scenario gap to e2e-test-tracking.md.

.DESCRIPTION
    Records a scenario no E2E case exercises — inside a covered workflow, or in one with no E2E
    coverage yet — the discovery neither existing table can hold. The milestone table expresses only
    workflow-level absence, and case rows are written when a case is created, so a placeholder
    case row would collide with the real row later.

    This script:
    - Validates that the workflow ID exists in user-workflow-tracking.md
    - Allocates the next GAP-NNN from the Discovered Scenario Gaps table itself (highest + 1).
      Gap IDs are FILE-LOCAL: no ID-registry allocation, no test-registry.yaml entry — a gap is
      a piece of missing work, not an artifact. This is the same allocation shape the per-project
      migration ledgers use for MIG-NNN.
    - Inserts the row at status '⬜ Not Created'

    The row is cleared by New-E2EAcceptanceTestCase.ps1 -ResolvesGap when the covering case is
    created, which sets Status to '✅ Covered' and writes the case ID into Resolved By.

    Typical caller: Bug Fixing (PF-TSK-007), whose E2E follow-through step files a discovered gap here
    instead of leaving it in a checkpoint note that dies with the session.

.PARAMETER Workflow
    An existing workflow ID from user-workflow-tracking.md (e.g., "WF-001") — the workflow
    the missing scenario belongs to.

.PARAMETER Scenario
    What is not exercised, concrete enough to build a fixture from: what is authored, what
    action is taken, and what must hold afterwards. This is the cell a later PF-TSK-069 session
    works from, so a vague scenario makes the row unusable (min 20 chars).

.PARAMETER Source
    Where the gap was discovered — a bug ID (e.g. "PD-BUG-126"), an audit report ID, or the
    session that found it.

.PARAMETER Notes
    Optional extra context appended to the Scenario cell after an em-dash separator.

.EXAMPLE
    New-E2EScenarioGap.ps1 -Workflow "WF-001" -Scenario "Escape-bearing structured-data value: one target authored four ways in one file (doubled backslash, escaped forward slash, unicode escape, plain), moved once; all four follow the move and the rewritten file still parses" -Source "PD-BUG-126"

.EXAMPLE
    New-E2EScenarioGap.ps1 -Workflow "WF-010" -Scenario "Control Panel stop action while a probe is live" -Source "TE-TAR-095" -WhatIf

.NOTES
    - Does NOT generate a registry ID — GAP-NNN is local to the tracking file
    - Validates the workflow ID exists before adding
    - Prints a note (never fails) when the workflow has no Workflow Milestone Tracking row: the
      normal case for a workflow with no E2E coverage yet, where the gap records the scenario
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern("^WF-\d+$")]
    [string]$Workflow,

    [Parameter(Mandatory = $true)]
    [ValidateLength(20, 1000)]
    [string]$Scenario,

    [Parameter(Mandatory = $true)]
    [ValidateLength(2, 200)]
    [string]$Source,

    [Parameter(Mandatory = $false)]
    [ValidateLength(0, 500)]
    [string]$Notes = ""
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
Invoke-StandardScriptInitialization

# Soak verification (PF-PRO-028 v2.0 Pattern A; caller-aware no-arg form)
Register-SoakScript
$soakInSoak = Test-ScriptInSoak

# Soak-verification wrapper begins (PF-PRO-028 v2.0)
try {

# Configuration
$WorkflowFile    = Resolve-TrackingFilePath -File "user-workflow-tracking.md"
$E2ETrackingFile = Resolve-TrackingFilePath -File "e2e-test-tracking.md"

foreach ($p in @($WorkflowFile, $E2ETrackingFile)) {
    if (-not (Test-Path $p)) {
        Write-ProjectError -Message "Required file not found: $p" -ExitCode 1
    }
}

# --- Step 1: Validate the workflow exists ---
$wfContent = Get-Content -Path $WorkflowFile -Raw -Encoding UTF8
$workflowFound = $false

foreach ($line in ($wfContent -split '\r?\n')) {
    if ($line -match "^\|\s*$Workflow\s*\|") { $workflowFound = $true; break }
}

if (-not $workflowFound) {
    Write-ProjectError -Message "Workflow '$Workflow' not found in user-workflow-tracking.md. Add it first using New-WorkflowEntry.ps1." -ExitCode 1
}

$e2eContent = Get-Content -Path $E2ETrackingFile -Raw -Encoding UTF8
$e2eLines = [System.Collections.ArrayList]@($e2eContent -split "\r?\n")

# The gaps section must exist — a tracker predating this table cannot take a gap row, and
# silently appending one elsewhere would put it where no reader looks.
if ($e2eContent -notmatch '(?m)^## Discovered Scenario Gaps\s*$') {
    Write-ProjectError -Message "No '## Discovered Scenario Gaps' section in $E2ETrackingFile. This tracker predates scenario-gap tracking — apply the pending migration that adds the section before filing a gap." -ExitCode 1
}

# --- Step 2: Allocate the next GAP-NNN from the gaps table itself ---
# File-local allocation (highest + 1), the MIG-NNN ledger shape. Scoped to the gaps section so
# a 'GAP-' string appearing in some other row's prose cannot inflate the counter.
$inGapSection = $false
$highest = 0

foreach ($line in $e2eLines) {
    if ($line -match '^## Discovered Scenario Gaps') { $inGapSection = $true; continue }
    if ($inGapSection -and $line -match '^## ') { break }
    if ($inGapSection -and $line -match '^\|\s*GAP-(\d+)\s*\|') {
        $n = [int]$Matches[1]
        if ($n -gt $highest) { $highest = $n }
    }
}

$gapId = "GAP-{0:D3}" -f ($highest + 1)

# --- Step 3: Advisory milestone check (never fatal) ---
$inMilestoneSection = $false
$milestoneFound = $false

foreach ($line in $e2eLines) {
    if ($line -match '^## Workflow Milestone Tracking') { $inMilestoneSection = $true; continue }
    if ($inMilestoneSection -and $line -match '^## ') { break }
    if ($inMilestoneSection -and $line -match "^\|\s*$Workflow\s*\|") { $milestoneFound = $true; break }
}

if (-not $milestoneFound) {
    Write-Host "Note: $Workflow has no Workflow Milestone Tracking row — expected when the workflow has no E2E coverage yet; otherwise check the workflow ID." -ForegroundColor Gray
}

Write-Host "Filing scenario gap for: $Workflow" -ForegroundColor Yellow
Write-Host "Gap ID: $gapId" -ForegroundColor Cyan
Write-Host "Source: $Source" -ForegroundColor Cyan

if (-not $PSCmdlet.ShouldProcess($E2ETrackingFile, "Add scenario gap '$gapId' for $Workflow")) {
    return
}

# --- Step 4: Build and insert the row ---
# Header-driven (PF-IMP-1599): cells are ordered by the live table's own header, so a column
# added to the gaps table lands as the default in the correct position instead of silently
# shifting every following cell. Resolved By takes the default — an open gap has no case yet.
$scenarioCell = if ($Notes) { "$Scenario — $Notes" } else { $Scenario }

$tableRow = New-HeaderDrivenTableRow -Content $e2eContent -SectionHeading '## Discovered Scenario Gaps' -ValueMap @{
    'Gap ID'   = $gapId
    'Workflow' = $Workflow
    'Scenario' = $scenarioCell
    'Source'   = $Source
    'Status'   = '⬜ Not Created'
    'Filed'    = (Get-Date -Format 'yyyy-MM-dd')
}

# Insertion point: after the last GAP row in the section, else after the header separator
$insertAfterIndex = -1
$inGapSection = $false

for ($i = 0; $i -lt $e2eLines.Count; $i++) {
    if ($e2eLines[$i] -match '^## Discovered Scenario Gaps') { $inGapSection = $true; continue }
    if ($inGapSection) {
        if ($e2eLines[$i] -match '^\|\s*GAP-\d+\b') { $insertAfterIndex = $i }
        if ($e2eLines[$i] -match '^## ') { break }
    }
}

if ($insertAfterIndex -eq -1) {
    $inGapSection = $false
    for ($i = 0; $i -lt $e2eLines.Count; $i++) {
        if ($e2eLines[$i] -match '^## Discovered Scenario Gaps') { $inGapSection = $true; continue }
        if ($inGapSection -and $e2eLines[$i] -match '^\|[\s\-:|]+\|\s*$') {
            $insertAfterIndex = $i
            break
        }
        if ($inGapSection -and $e2eLines[$i] -match '^## ') { break }
    }
}

if ($insertAfterIndex -eq -1) {
    Write-ProjectError -Message "Could not find an insertion point in the Discovered Scenario Gaps table" -ExitCode 1
}

$e2eLines.Insert($insertAfterIndex + 1, $tableRow)

# Write updated content
$updatedContent = $e2eLines -join "`r`n"
Set-Content -Path $E2ETrackingFile -Value $updatedContent -NoNewline -Encoding UTF8

# Verify deterministic post-condition: row was inserted and matches the table schema
# (PF-PRO-028 v2.0 / PF-IMP-1563 — the assert also catches cell-count drift against the header)
Assert-TableRowInFile -Path $E2ETrackingFile -Pattern "\| $gapId \|" -Context "scenario gap row for $gapId in $E2ETrackingFile"

# --- Output ---
$details = @(
    "Gap: $gapId — $Workflow",
    "Scenario: $scenarioCell",
    "Source: $Source",
    "Status: ⬜ Not Created"
)

Write-ProjectSuccess -Message "Filed scenario gap: $gapId" -Details $details

Write-Verbose "Next Steps: Create the covering case with New-E2EAcceptanceTestCase.ps1 -ResolvesGap $gapId (PF-TSK-069)"

    # Soak: success outcome (PF-PRO-028 v2.0)
    if ($soakInSoak) { Confirm-SoakInvocation -Outcome success }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -Outcome failure -Notes $soakErrMsg
    }
    Write-ProjectError -Message "Scenario gap filing failed: $($_.Exception.Message)" -ExitCode 1
}
