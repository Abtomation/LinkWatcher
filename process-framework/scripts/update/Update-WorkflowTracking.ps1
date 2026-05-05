#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Updates Impl Status and E2E Status columns in user-workflow-tracking.md.

.DESCRIPTION
    Derives workflow-level status from feature-tracking.md and e2e-test-tracking.md.

    For each workflow row in user-workflow-tracking.md:
    - Impl Status: "All Implemented" if ALL required features have 🟢 Completed status,
      otherwise lists the non-completed feature IDs.
    - E2E Status: Derived from the Workflow Milestone Tracking section of e2e-test-tracking.md.
      Falls back to "Not Tested" if no milestone entry exists.

    Designed to be called by Update-FeatureImplementationState.ps1 and
    Update-TestExecutionStatus.ps1 after they update their respective tracking files.

.PARAMETER ProjectRoot
    Optional: Project root path. Auto-detected from .git marker if not specified.

.EXAMPLE
    Update-WorkflowTracking.ps1

.EXAMPLE
    Update-WorkflowTracking.ps1 -WhatIf

.NOTES
    Created: 2026-03-31
    Version: 1.0
    Source: PF-IMP-258 (Workflow-Level Framework Layer)
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = ""
)

# Import Common-ScriptHelpers (added by PF-IMP-728 Session 2 to enable soak verification)
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Soak verification (PF-PRO-028 v2.0 Pattern A; caller-aware no-arg form)
Register-SoakScript
$soakInSoak = Test-ScriptInSoak

# Soak-verification wrapper begins (PF-PRO-028 v2.0)
try {


# Resolve project root
if (-not $ProjectRoot) {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir ".git"))) {
        $searchDir = Split-Path $searchDir -Parent
    }
    if (-not $searchDir) {
        Write-Error "Could not auto-detect project root. Use -ProjectRoot parameter."
        exit 1
    }
    $ProjectRoot = $searchDir
}

$workflowPath = Join-Path $ProjectRoot "doc/state-tracking/permanent/user-workflow-tracking.md"
$featureTrackingPath = Join-Path $ProjectRoot "doc/state-tracking/permanent/feature-tracking.md"
$e2eTrackingPath = Join-Path $ProjectRoot "test/state-tracking/permanent/e2e-test-tracking.md"

foreach ($p in @($workflowPath, $featureTrackingPath)) {
    if (-not (Test-Path $p)) {
        Write-Error "Required file not found: $p"
        exit 1
    }
}

$timestamp = Get-Date -Format "yyyy-MM-dd"

# --- Step 1: Parse feature-tracking.md to get feature statuses ---
$ftContent = Get-Content $featureTrackingPath -Raw -Encoding UTF8
$ftLines = $ftContent -split '\r?\n'
$featureStatuses = @{}

foreach ($line in $ftLines) {
    # Match feature rows: | [X.Y.Z](path) | Name | Status | ...
    if ($line -match '^\|\s*\[(\d+\.\d+\.\d+)\]') {
        $fId = $matches[1]
        $cells = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        if ($cells.Count -ge 3) {
            $statusCell = $cells[2]  # Status is 3rd column (0-indexed: ID, Feature, Status)
            # A feature is "implemented" if it passed code review: 🟢 Completed OR 🔎 Needs Test Scoping
            $isCompleted = $statusCell -match '🟢|🔎'
            $featureStatuses[$fId] = @{
                Status = $statusCell
                IsCompleted = $isCompleted
            }
        }
    }
}

Write-Host "Parsed $($featureStatuses.Count) features from feature-tracking.md" -ForegroundColor Gray

# --- Step 2: Parse e2e-test-tracking.md for workflow milestone status ---
$workflowE2eStatus = @{}

if (Test-Path $e2eTrackingPath) {
    $e2eContent = Get-Content $e2eTrackingPath -Raw -Encoding UTF8
    $e2eLines = $e2eContent -split '\r?\n'
    $inMilestoneSection = $false

    foreach ($line in $e2eLines) {
        if ($line -match '## Workflow Milestone Tracking') {
            $inMilestoneSection = $true
            continue
        }
        if ($inMilestoneSection -and $line -match '^## ') {
            $inMilestoneSection = $false
            continue
        }
        if ($inMilestoneSection -and $line -match '^\|\s*(WF-\d+)') {
            $wfId = $matches[1]
            $cells = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
            # Find the E2E Status column — typically column index 4 or 5
            # Look for emoji patterns indicating test status
            foreach ($cell in $cells) {
                if ($cell -match '(✅|🔴|🔄|Not Tested|Covered|Partial)') {
                    $workflowE2eStatus[$wfId] = $cell
                    break
                }
            }
        }
    }
}

Write-Host "Parsed $($workflowE2eStatus.Count) workflow E2E statuses from e2e-test-tracking.md" -ForegroundColor Gray

# --- Step 3: Parse and update user-workflow-tracking.md ---
$wfContent = Get-Content $workflowPath -Raw -Encoding UTF8
$wfLines = $wfContent -split '\r?\n'
$updatedLines = @()
$updateCount = 0
$inWorkflowTable = $false
$headerParsed = $false
$implStatusIdx = -1
$e2eStatusIdx = -1
$reqFeaturesIdx = -1

foreach ($line in $wfLines) {
    # Detect the Workflows table header
    if (-not $inWorkflowTable -and $line -match '^\|\s*ID\s*\|') {
        $inWorkflowTable = $true
        # Parse column indices
        $headerCells = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        for ($i = 0; $i -lt $headerCells.Count; $i++) {
            if ($headerCells[$i] -match 'Required Features') { $reqFeaturesIdx = $i }
            if ($headerCells[$i] -match 'Impl Status') { $implStatusIdx = $i }
            if ($headerCells[$i] -match 'E2E Status') { $e2eStatusIdx = $i }
        }
        $updatedLines += $line
        continue
    }

    # Skip separator row
    if ($inWorkflowTable -and -not $headerParsed -and $line -match '^\|[\s\-\|]+$') {
        $headerParsed = $true
        $updatedLines += $line
        continue
    }

    # End of table
    if ($inWorkflowTable -and $headerParsed -and $line -notmatch '^\|') {
        $inWorkflowTable = $false
    }

    # Process workflow data rows
    if ($inWorkflowTable -and $headerParsed -and $line -match '^\|\s*(WF-\d+)') {
        $wfId = $matches[1]
        $cells = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

        if ($reqFeaturesIdx -ge 0 -and $reqFeaturesIdx -lt $cells.Count) {
            # Parse required features: "1.1.1, 2.1.1, 2.2.1"
            $reqFeatures = $cells[$reqFeaturesIdx] -split ',\s*' | ForEach-Object { $_.Trim() }

            # Derive Impl Status
            $notCompleted = @()
            foreach ($f in $reqFeatures) {
                if ($featureStatuses.ContainsKey($f)) {
                    if (-not $featureStatuses[$f].IsCompleted) {
                        $notCompleted += $f
                    }
                } else {
                    $notCompleted += "$f (unknown)"
                }
            }

            $newImplStatus = if ($notCompleted.Count -eq 0) {
                "All Implemented"
            } else {
                "Pending: $($notCompleted -join ', ')"
            }

            # Derive E2E Status from milestone tracking or preserve existing
            $newE2eStatus = if ($workflowE2eStatus.ContainsKey($wfId)) {
                $workflowE2eStatus[$wfId]
            } else {
                # Preserve existing value if no milestone entry found
                if ($e2eStatusIdx -ge 0 -and $e2eStatusIdx -lt $cells.Count) {
                    $cells[$e2eStatusIdx]
                } else {
                    "Not Tested"
                }
            }

            # Update cells
            $changed = $false
            if ($implStatusIdx -ge 0 -and $implStatusIdx -lt $cells.Count) {
                if ($cells[$implStatusIdx] -ne $newImplStatus) {
                    $cells[$implStatusIdx] = $newImplStatus
                    $changed = $true
                }
            }
            if ($e2eStatusIdx -ge 0 -and $e2eStatusIdx -lt $cells.Count) {
                if ($cells[$e2eStatusIdx] -ne $newE2eStatus) {
                    $cells[$e2eStatusIdx] = $newE2eStatus
                    $changed = $true
                }
            }

            if ($changed) {
                $line = "| " + ($cells -join " | ") + " |"
                $updateCount++
                Write-Host "  $wfId : Impl=$newImplStatus, E2E=$newE2eStatus" -ForegroundColor Yellow
            }
        }
    }

    $updatedLines += $line
}

# Write updated content
if ($updateCount -gt 0) {
    if ($PSCmdlet.ShouldProcess($workflowPath, "Update $updateCount workflow status rows")) {
        $updatedContent = ($updatedLines -join "`n") -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $timestamp"
        Set-Content $workflowPath $updatedContent -Encoding UTF8
        Write-Host ""
        Write-Host "✅ Updated $updateCount workflow(s) in user-workflow-tracking.md" -ForegroundColor Green
    }
} else {
    Write-Host ""
    Write-Host "No workflow status changes needed." -ForegroundColor Gray
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
    Write-Error "Workflow tracking update failed: $($_.Exception.Message)"
    exit 1
}
