# New-E2EMilestoneEntry.ps1
# Adds a new workflow milestone entry to e2e-test-tracking.md Workflow Milestone Tracking table
# References an existing WF-xxx ID from user-workflow-tracking.md

<#
.SYNOPSIS
    Adds a new workflow milestone entry to e2e-test-tracking.md.

.DESCRIPTION
    This PowerShell script creates new milestone entries by:
    - Validating that the workflow ID exists in user-workflow-tracking.md
    - Reading the workflow's description and required features from the tracking file
    - Adding a row to the Workflow Milestone Tracking table in e2e-test-tracking.md
    - Used by the Performance & E2E Test Scoping task (PF-TSK-086) when a workflow
      becomes E2E-ready

.PARAMETER WorkflowId
    An existing workflow ID from user-workflow-tracking.md (e.g., "WF-009")

.PARAMETER SpecRef
    Optional link to the E2E test specification. Defaults to "—" (to be created).

.PARAMETER Status
    Initial status (default: "⬜ Not Created"). Use "📋 Case Created" if a test case already exists.

.EXAMPLE
    New-E2EMilestoneEntry.ps1 -WorkflowId "WF-009"

.EXAMPLE
    New-E2EMilestoneEntry.ps1 -WorkflowId "WF-006" -SpecRef "[PF-TSP-044](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md)" -WhatIf

.NOTES
    - Does NOT generate a new ID — references an existing WF-xxx from user-workflow-tracking.md
    - Validates the workflow ID exists before adding
    - Reads description and required features from user-workflow-tracking.md
    - Counts features at 🔎 Needs Test Scoping or 🟢 Completed to derive "Features Ready"
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern("^WF-\d{3}$")]
    [string]$WorkflowId,

    [Parameter(Mandatory = $false)]
    [string]$SpecRef = "—",

    [Parameter(Mandatory = $false)]
    [ValidateSet("⬜ Not Created", "📋 Case Created")]
    [string]$Status = "⬜ Not Created"
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
$WorkflowFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/user-workflow-tracking.md"
$E2ETrackingFile = Join-Path -Path $ProjectRoot -ChildPath "test/state-tracking/permanent/e2e-test-tracking.md"
$FeatureTrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/feature-tracking.md"

foreach ($p in @($WorkflowFile, $E2ETrackingFile, $FeatureTrackingFile)) {
    if (-not (Test-Path $p)) {
        Write-ProjectError -Message "Required file not found: $p" -ExitCode 1
    }
}

# --- Step 1: Validate workflow exists and read its data ---
$wfContent = Get-Content -Path $WorkflowFile -Raw -Encoding UTF8
$wfLines = $wfContent -split '\r?\n'

$workflowDescription = ""
$requiredFeatures = ""
$workflowFound = $false

foreach ($line in $wfLines) {
    if ($line -match "^\|\s*$WorkflowId\s*\|") {
        $workflowFound = $true
        $cells = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        if ($cells.Count -ge 4) {
            $workflowDescription = $cells[1]  # Workflow column
            $requiredFeatures = $cells[3]      # Required Features column
        }
        break
    }
}

if (-not $workflowFound) {
    Write-ProjectError -Message "Workflow '$WorkflowId' not found in user-workflow-tracking.md. Add it first using New-WorkflowEntry.ps1." -ExitCode 1
}

Write-Host "Adding E2E milestone entry for: $WorkflowId" -ForegroundColor Yellow
Write-Host "Workflow: $workflowDescription" -ForegroundColor Cyan
Write-Host "Required Features: $requiredFeatures" -ForegroundColor Cyan

# --- Step 2: Count ready features from feature-tracking.md ---
$ftContent = Get-Content -Path $FeatureTrackingFile -Raw -Encoding UTF8
$ftLines = $ftContent -split '\r?\n'

$featureIds = $requiredFeatures -split ',\s*' | ForEach-Object { $_.Trim() }
$readyCount = 0

foreach ($fId in $featureIds) {
    foreach ($line in $ftLines) {
        if ($line -match "^\|\s*\[$fId\]") {
            # Check if status is 🟢 Completed or 🔎 Needs Test Scoping (both = code complete)
            if ($line -match '🟢|🔎') { $readyCount++ }
            break
        }
    }
}

$featuresReady = "$readyCount/$($featureIds.Count)"
Write-Host "Features Ready: $featuresReady" -ForegroundColor Cyan

# --- Step 3: Check for duplicate ---
$e2eContent = Get-Content -Path $E2ETrackingFile -Raw -Encoding UTF8
$e2eLines = [System.Collections.ArrayList]@($e2eContent -split "\r?\n")

foreach ($line in $e2eLines) {
    if ($line -match "^\|\s*$WorkflowId\s*\|" -and $line -match "Workflow Milestone|Features Ready") {
        # Probably in milestone table — but let's check more carefully
    }
}

# Check in the Workflow Milestone Tracking section specifically
$inMilestoneSection = $false
foreach ($line in $e2eLines) {
    if ($line -match "## Workflow Milestone Tracking") { $inMilestoneSection = $true; continue }
    if ($inMilestoneSection -and $line -match "^## ") { break }
    if ($inMilestoneSection -and $line -match "^\|\s*$WorkflowId\s*\|") {
        Write-ProjectError -Message "Workflow '$WorkflowId' already exists in Workflow Milestone Tracking table" -ExitCode 1
    }
}

if (-not $PSCmdlet.ShouldProcess($E2ETrackingFile, "Add E2E milestone entry for '${WorkflowId}: $workflowDescription'")) {
    return
}

# --- Step 4: Build and insert the table row ---
# Columns: Workflow | Description | Required Features | Features Ready | E2E Spec | E2E Cases | Status
$tableRow = "| $WorkflowId | $workflowDescription | $requiredFeatures | $featuresReady | $SpecRef | — | $Status |"

# Find insertion point: after the last WF-xxx row in the Workflow Milestone Tracking section
$insertAfterIndex = -1
$inMilestoneSection = $false

for ($i = 0; $i -lt $e2eLines.Count; $i++) {
    if ($e2eLines[$i] -match "## Workflow Milestone Tracking") { $inMilestoneSection = $true; continue }
    if ($inMilestoneSection) {
        if ($e2eLines[$i] -match "^\|\s*WF-\d{3}\b") { $insertAfterIndex = $i }
        if ($e2eLines[$i] -match "^## " -and $e2eLines[$i] -notmatch "## Workflow Milestone") { break }
    }
}

# If no data rows, insert after the separator
if ($insertAfterIndex -eq -1) {
    $inMilestoneSection = $false
    for ($i = 0; $i -lt $e2eLines.Count; $i++) {
        if ($e2eLines[$i] -match "## Workflow Milestone Tracking") { $inMilestoneSection = $true; continue }
        if ($inMilestoneSection -and $e2eLines[$i] -match "^\|\s*-") {
            $insertAfterIndex = $i
            break
        }
    }
}

if ($insertAfterIndex -eq -1) {
    Write-ProjectError -Message "Could not find insertion point in Workflow Milestone Tracking table" -ExitCode 1
}

$e2eLines.Insert($insertAfterIndex + 1, $tableRow)
Write-Host "Inserted $WorkflowId into Workflow Milestone Tracking table" -ForegroundColor Green

# Write updated content
$updatedContent = $e2eLines -join "`r`n"
Set-Content -Path $E2ETrackingFile -Value $updatedContent -NoNewline -Encoding UTF8

# --- Output ---
$details = @(
    "Workflow: $WorkflowId — $workflowDescription",
    "Required Features: $requiredFeatures",
    "Features Ready: $featuresReady",
    "Status: $Status"
)

Write-ProjectSuccess -Message "Created E2E milestone entry for: $WorkflowId" -Details $details

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  - Create E2E test specification for this workflow (PF-TSK-012 with -CrossCutting)" -ForegroundColor White
Write-Host "  - Create E2E test cases (PF-TSK-069) once specification exists" -ForegroundColor White
Write-Host "  - Run Update-WorkflowTracking.ps1 to sync statuses" -ForegroundColor White
