#!/usr/bin/env pwsh

<#
.SYNOPSIS
Records a code review verdict (PF-TSK-005) in feature-tracking.md: flips the feature's Status to the legend value for the verdict and appends a review note to its Notes cell.

.DESCRIPTION
Redesigned against the post-PF-PRO-002 feature-tracking schema (PF-IMP-1384 / PF-IMP-1470).
The master tracking file carries only ID / Feature / Status / Priority / Doc Tier / Test Status /
Dependencies / Notes, so this script writes exactly two cells on the feature's row:

- Status — mapped from the review verdict per the PF-TSK-086 status model:
    Completed, Approved with Comments  ->  🔎 Needs Test Scoping
    Needs Enhancement, Rejected        ->  🔄 Needs Enhancement
- Notes — appends "Code review <date>: <verdict>[ — <findings summary>][ (review doc: <path>)]"

Detailed review metadata (reviewer, findings, quality scores) belongs in the review document and
the per-feature implementation state file, and the test-tracking Status column is owned by Test
Audit (PF-TSK-030) — this script writes neither.

After the write, a read-after-write assertion verifies the feature's row actually carries the new
Status; if the row is missing or the write was skipped (e.g. future schema drift), the script
throws instead of reporting success.

.PARAMETER FeatureId
The feature ID whose review verdict is being recorded (e.g., "1.2.3")

.PARAMETER ReviewStatus
The review verdict: "Completed", "Approved with Comments", "Needs Enhancement", or "Rejected"

.PARAMETER ReviewDate
Date of the review for the Notes entry (optional — defaults to today)

.PARAMETER ReviewDocumentPath
Path to the review document, recorded in the Notes entry (optional)

.PARAMETER FindingsSummary
One-line findings summary for the Notes entry (optional). Full findings belong in the review
document / per-feature state file.

.EXAMPLE
Update-CodeReviewState.ps1 -FeatureId "1.2.3" -ReviewStatus "Completed"

.EXAMPLE
Update-CodeReviewState.ps1 -FeatureId "1.2.3" -ReviewStatus "Needs Enhancement" -FindingsSummary "Missing error handling in parser" -WhatIf

.EXAMPLE
Update-CodeReviewState.ps1 -FeatureId "1.2.3" -ReviewStatus "Approved with Comments" -ReviewDocumentPath "doc/reviews/review-1.2.3.md"

.NOTES
History: v1.0 (2025-08-23) targeted the pre-PF-PRO-002 schema (Code Review / Review Date /
Reviewer / Review Findings columns) and a retired multi-file backup-helper signature; both were
removed underneath it, leaving every write silently skipped behind a success banner.
v2.0 (2026-07-13, PF-IMP-1384 + PF-IMP-1470) is this schema-true redesign.

Version: 2.0
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureId,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Completed", "Approved with Comments", "Needs Enhancement", "Rejected")]
    [string]$ReviewStatus,

    [Parameter(Mandatory=$false)]
    [string]$ReviewDate,

    [Parameter(Mandatory=$false)]
    [string]$ReviewDocumentPath,

    [Parameter(Mandatory=$false)]
    [string]$FindingsSummary
)

# Import required modules with walk-up path resolution
try {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $dir = $scriptDir
    while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
        $dir = Split-Path -Parent $dir
    }
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
}
catch {
    Write-Error "Failed to import Common-ScriptHelpers module: $($_.Exception.Message)"
    exit 1
}

# Initialize script
$ErrorActionPreference = "Stop"

# Validate dependencies
$dependencyCheck = Test-ScriptDependencies -RequiredFunctions @(
    "Update-FeatureTrackingStatus",
    "Assert-LineInFile",
    "Get-ProjectRoot"
)

if (-not $dependencyCheck.AllDependenciesMet) {
    Write-Error "Required dependencies not met. Please ensure Common-ScriptHelpers.psm1 is properly loaded."
    exit 1
}

# Main execution
try {
    if (-not $ReviewDate) {
        $ReviewDate = Get-Date -Format "yyyy-MM-dd"
    }

    # Verdict -> Status legend value (PF-TSK-086 status model; PF-IMP-1470)
    $newStatus = switch ($ReviewStatus) {
        "Completed"              { "🔎 Needs Test Scoping" }
        "Approved with Comments" { "🔎 Needs Test Scoping" }
        "Needs Enhancement"      { "🔄 Needs Enhancement" }
        "Rejected"               { "🔄 Needs Enhancement" }
    }

    # Review note appended to the feature's Notes cell
    $reviewNote = "Code review ${ReviewDate}: ${ReviewStatus}"
    if ($FindingsSummary) {
        $reviewNote += " — $FindingsSummary"
    }
    if ($ReviewDocumentPath) {
        $reviewNote += " (review doc: $ReviewDocumentPath)"
    }

    Write-ProjectLog -Message "Feature: $FeatureId | Verdict: $ReviewStatus | Status -> $newStatus"

    # ShouldProcess returning $false (under -WhatIf) drives the preview path and
    # passes -DryRun:$true to the helper.
    $DryRun = -not $PSCmdlet.ShouldProcess("$FeatureId code review state", "Update")

    if ($DryRun) {
        Write-Host "WHATIF PREVIEW MODE - No changes will be made" -ForegroundColor Yellow
    }

    $null = Update-FeatureTrackingStatus -FeatureId $FeatureId -Status $newStatus -StatusColumn "Status" -Notes $reviewNote -DryRun:$DryRun

    if ($DryRun) {
        Write-ProjectSummary -Message "WHATIF preview complete for ${FeatureId}: Status -> $newStatus (no changes made)" -Level "WARN"
    }
    else {
        # Read-after-write verification: the feature's row must now carry the new Status.
        # Throws on a missing row or a silently skipped write (e.g. schema drift).
        $featureTrackingPath = Join-Path (Get-ProjectRoot) "doc/state-tracking/permanent/feature-tracking.md"
        $idEsc = [regex]::Escape($FeatureId)
        $statusEsc = [regex]::Escape($newStatus)
        Assert-LineInFile -Path $featureTrackingPath -Pattern "(?m)^\|\s*\[?$idEsc(\]\([^)]*\))?\s*\|[^\r\n]*\|\s*$statusEsc\s*\|" -Context "code-review Status flip for $FeatureId"
        Assert-LineInFile -Path $featureTrackingPath -Pattern $reviewNote -Literal -Context "code-review Notes append for $FeatureId"

        Write-ProjectSummary -Message "Code review verdict recorded: $FeatureId -> $newStatus"
    }
}
catch {
    Write-ProjectError -Message "Code review state update failed: $($_.Exception.Message)" -ExitCode 1
}
