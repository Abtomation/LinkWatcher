#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates implementation-status transitions in feature-tracking.md (implementation tasks), including the derived workflow-tracking refresh.

.DESCRIPTION
Writes the feature's Status cell in doc/state-tracking/permanent/feature-tracking.md (with an
optional Notes append) and then refreshes user-workflow-tracking.md's derived Impl Status column
via Update-WorkflowTracking.ps1.

Aligned with the post-PF-PRO-002 feature-tracking schema (PF-IMP-1384): the master tracking file
carries only ID / Feature / Status / Priority / Doc Tier / Test Status / Dependencies / Notes.
Implementation metadata (start/completion dates, pull requests, design deviations, new
components/dependencies) belongs in the per-feature implementation state file, and the
test-tracking Status column is owned by Test Audit (PF-TSK-030) — this script writes neither.

After the write, a read-after-write assertion verifies the feature's row actually carries the new
Status; if the row is missing or the write was skipped (e.g. future schema drift), the script
throws instead of reporting success.

.PARAMETER FeatureId
The feature ID to update (e.g., "1.2.3")

.PARAMETER Status
The implementation status: "🟡 In Progress", "👀 Needs Review", "🔄 Needs Enhancement", or "🟢 Completed"

.PARAMETER Notes
Text appended to the feature's Notes cell (optional)

.EXAMPLE
Update-FeatureImplementationState.ps1 -FeatureId "1.2.3" -Status "🟡 In Progress"

.EXAMPLE
Update-FeatureImplementationState.ps1 -FeatureId "1.2.3" -Status "🟢 Completed" -Notes "Implementation completed 2026-07-13; PR #123"

.EXAMPLE
Update-FeatureImplementationState.ps1 -FeatureId "1.2.3" -Status "🔄 Needs Enhancement" -WhatIf

.NOTES
History: v1.0 (2025-08-23, IMP-067) targeted the pre-PF-PRO-002 schema (a retired status column
plus metadata columns), called the backup helper with a retired multi-file signature, and
hardcoded audit-owned test-tracking Status writes. v2.0 (2026-07-13, PF-IMP-1384) is this
schema-true redesign.

Version: 2.0
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("🟡 In Progress", "👀 Needs Review", "🔄 Needs Enhancement", "🟢 Completed")]
    [string]$Status,

    [Parameter(Mandatory = $false)]
    [string]$Notes
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
    "Assert-TableRowInFile",
    "Get-ProjectRoot"
)

if (-not $dependencyCheck.AllDependenciesMet) {
    Write-Error "Required dependencies not met. Please ensure Common-ScriptHelpers.psm1 is properly loaded."
    exit 1
}

# Main execution
try {
    Write-ProjectLog -Message "Feature: $FeatureId | Status -> $Status"

    # ShouldProcess returning $false (under -WhatIf) drives the preview path and
    # passes -DryRun:$true to the helpers.
    $DryRun = -not $PSCmdlet.ShouldProcess("$FeatureId implementation state", "Update")

    if ($DryRun) {
        Write-Host "WHATIF PREVIEW MODE - No changes will be made" -ForegroundColor Yellow
    }

    $projectRoot = Get-ProjectRoot

    $null = Update-FeatureTrackingStatus -FeatureId $FeatureId -Status $Status -StatusColumn "Status" -Notes $Notes -DryRun:$DryRun

    # Update workflow tracking (Impl Status column derives from feature statuses)
    $workflowScript = Join-Path $PSScriptRoot "Update-WorkflowTracking.ps1"
    if (Test-Path $workflowScript) {
        Write-ProjectLog -Message "Updating workflow tracking (derived Impl Status)"
        if ($DryRun) {
            & $workflowScript -ProjectRoot $projectRoot -WhatIf
        } else {
            & $workflowScript -ProjectRoot $projectRoot
        }
    }

    if (-not $DryRun) {
        # Read-after-write verification (PF-PRO-077 / PF-IMP-2126), placed AFTER the chained
        # workflow refresh rather than before it: the chain is this run's last write, and an
        # assertion ahead of it could fail the run with feature-tracking updated and the derived
        # workflow tracker left stale — a half-updated state the after-the-last-write rule exists
        # to rule out. Assert-TableRowInFile, not Assert-LineInFile: the shared helper returns no
        # found/not-found signal and writes the file even when no row matched, so "the row exists,
        # is header-width, and carries the value just written" is the only detector of a
        # reports-success-writes-nothing run. One call per written value; -Notes is APPENDED to
        # the Notes cell, so it is matched as a suffix of its cell and only when supplied.
        $featureTrackingPath = Join-Path $projectRoot "doc/state-tracking/permanent/feature-tracking.md"
        $rowIdentity = "^\|\s*\[?" + [regex]::Escape($FeatureId) + "\b(?:\]\([^)]*\))?\s*\|"
        $statusPattern = $rowIdentity + "(?:[^|]*\|)*\s*" + [regex]::Escape($Status) + "\s*\|"
        Assert-TableRowInFile -Path $featureTrackingPath -Pattern $statusPattern -Context "implementation Status flip for $FeatureId → '$Status' in $featureTrackingPath"
        if ($Notes) {
            $notePattern = $rowIdentity + ".*" + [regex]::Escape($Notes) + "\s*\|"
            Assert-TableRowInFile -Path $featureTrackingPath -Pattern $notePattern -Context "implementation Notes append for $FeatureId in $featureTrackingPath"
        }
    }

    if ($DryRun) {
        Write-ProjectSummary -Message "WHATIF preview complete for ${FeatureId}: Status -> $Status (no changes made)" -Level "WARN"
    }
    else {
        Write-ProjectSummary -Message "Implementation status recorded: $FeatureId -> $Status"
    }
}
catch {
    Write-ProjectError -Message "Feature implementation state update failed: $($_.Exception.Message)" -ExitCode 1
}
