# New-WorkflowEntry.ps1
# Adds a new user workflow entry to user-workflow-tracking.md
# Auto-assigns WF-xxx IDs via the central ID registry (PD-id-registry.json)

<#
.SYNOPSIS
    Adds a new user workflow to user-workflow-tracking.md with an auto-assigned WF-xxx ID.

.DESCRIPTION
    This PowerShell script creates new workflow entries by:
    - Generating a unique workflow ID (WF-###) via the central ID registry
    - Adding a row to the Workflows table
    - Adding a details section for the new workflow
    - Used by the Performance & E2E Test Scoping task (PF-TSK-086) when discovering
      untracked cross-feature interactions

.PARAMETER Workflow
    Short name for the workflow (e.g., "Single file move → links updated")

.PARAMETER UserAction
    What the user does to trigger this workflow (e.g., "Move/rename a file (VS Code, File Explorer, git)")

.PARAMETER RequiredFeatures
    Comma-separated feature IDs required for this workflow (e.g., "1.1.1, 2.1.1, 2.2.1")

.PARAMETER Priority
    Priority level: P1, P2, P3, or P4

.PARAMETER Description
    One-paragraph description for the Workflow Details section

.PARAMETER ImplStatus
    Implementation status (default: "Pending"). Examples: "All Implemented", "Pending: 0.1.1"

.EXAMPLE
    New-WorkflowEntry.ps1 -Workflow "Config reload → hot swap" -UserAction "Edit config while LinkWatcher runs" -RequiredFeatures "0.1.3, 0.1.1" -Priority "P3" -Description "User edits the configuration file while LinkWatcher is running. The system detects the change and reloads configuration without restart."

.EXAMPLE
    New-WorkflowEntry.ps1 -Workflow "Validation → broken link report" -UserAction "Run python main.py --validate" -RequiredFeatures "0.1.1, 2.1.1, 6.1.1" -Priority "P2" -Description "User runs validation mode to scan the workspace for broken file references." -WhatIf

.NOTES
    - Workflow IDs are auto-assigned via the central ID registry (PD-id-registry.json, WF prefix)
    - New entries are created with E2E Status "Not Tested" and Integration Doc "—"
    - A details section is appended before the closing </details> of the last workflow
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateLength(5, 200)]
    [string]$Workflow,

    [Parameter(Mandatory = $true)]
    [ValidateLength(5, 300)]
    [string]$UserAction,

    [Parameter(Mandatory = $true)]
    [ValidateLength(1, 100)]
    [string]$RequiredFeatures,

    [Parameter(Mandatory = $true)]
    [ValidateSet("P1", "P2", "P3", "P4")]
    [string]$Priority,

    [Parameter(Mandatory = $true)]
    [ValidateLength(10, 1000)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [string]$ImplStatus = "Pending"
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
Invoke-StandardScriptInitialization

# Configuration
$ProjectRoot = Get-ProjectRoot
$TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/user-workflow-tracking.md"

if (-not (Test-Path $TrackingFile)) {
    Write-ProjectError -Message "Tracking file not found: $TrackingFile" -ExitCode 1
}

# --- Step 1: Auto-assign workflow ID via the central ID registry ---
$workflowId = New-ProjectId -Prefix "WF" -Description "Workflow: $Workflow"

Write-Host "Adding workflow entry: $workflowId" -ForegroundColor Yellow
Write-Host "Workflow: $Workflow" -ForegroundColor Cyan
Write-Host "Required Features: $RequiredFeatures" -ForegroundColor Cyan

if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Add workflow entry '${workflowId}: $Workflow'")) {
    return
}

# Read current content
$Content = Get-Content -Path $TrackingFile -Raw -Encoding UTF8
$lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

# --- Step 2: Build and insert the table row ---
# Columns: ID | Workflow | User Action | Required Features | Priority | Impl Status | E2E Status | Integration Doc
$tableRow = "| $workflowId | $Workflow | $UserAction | $RequiredFeatures | $Priority | $ImplStatus | Not Tested | — |"

# Find insertion point: after the last WF-xxx data row in the Workflows table
$insertAfterIndex = -1
$inWorkflowsSection = $false

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^## Workflows") { $inWorkflowsSection = $true; continue }
    if ($inWorkflowsSection) {
        if ($lines[$i] -match "^\|\s*WF-\d{3}\b") { $insertAfterIndex = $i }
        if ($lines[$i] -match "^## " -and $lines[$i] -notmatch "^## Workflows") { break }
    }
}

# If no data rows, insert after the separator
if ($insertAfterIndex -eq -1) {
    $inWorkflowsSection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Workflows") { $inWorkflowsSection = $true; continue }
        if ($inWorkflowsSection -and $lines[$i] -match "^\|\s*-") {
            $insertAfterIndex = $i
            break
        }
    }
}

if ($insertAfterIndex -eq -1) {
    Write-ProjectError -Message "Could not find insertion point in Workflows table" -ExitCode 1
}

$lines.Insert($insertAfterIndex + 1, $tableRow)
Write-Host "Inserted $workflowId into Workflows table" -ForegroundColor Green

# --- Step 3: Add a details section before the closing of Workflow Details ---
# Find the last </details> in the Workflow Details section
$lastDetailsCloseIndex = -1
$inDetailsSection = $false

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^## Workflow Details") { $inDetailsSection = $true; continue }
    if ($inDetailsSection) {
        if ($lines[$i] -match "^\s*</details>") { $lastDetailsCloseIndex = $i }
        if ($lines[$i] -match "^## " -and $lines[$i] -notmatch "^## Workflow Details") { break }
    }
}

if ($lastDetailsCloseIndex -ne -1) {
    # Insert after the last </details>
    $detailsBlock = @(
        "",
        "<details>",
        "<summary><strong>${workflowId}: $($Workflow -replace ' →.*', '')</strong></summary>",
        "",
        $Description,
        "</details>"
    )
    $insertIdx = $lastDetailsCloseIndex + 1
    for ($j = 0; $j -lt $detailsBlock.Count; $j++) {
        $lines.Insert($insertIdx + $j, $detailsBlock[$j])
    }
    Write-Host "Added Workflow Details section for $workflowId" -ForegroundColor Green
} else {
    Write-Host "WARNING: Could not find Workflow Details section — details block not added" -ForegroundColor Yellow
}

# --- Step 4: Update frontmatter date ---
$updatedContent = ($lines -join "`r`n")
$CurrentDate = Get-Date -Format "yyyy-MM-dd"
$updatedContent = $updatedContent -replace '(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate

Set-Content -Path $TrackingFile -Value $updatedContent -NoNewline -Encoding UTF8

# --- Output ---
$details = @(
    "Workflow ID: $workflowId",
    "Workflow: $Workflow",
    "User Action: $UserAction",
    "Required Features: $RequiredFeatures",
    "Priority: $Priority",
    "Impl Status: $ImplStatus"
)

Write-ProjectSuccess -Message "Created workflow entry: $workflowId" -Details $details

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  - Evaluate E2E milestone readiness for this workflow" -ForegroundColor White
Write-Host "  - If E2E-ready, use New-E2EMilestoneEntry.ps1 to add to e2e-test-tracking.md" -ForegroundColor White
