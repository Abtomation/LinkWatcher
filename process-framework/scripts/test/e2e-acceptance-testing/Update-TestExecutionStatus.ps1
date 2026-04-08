#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Updates E2E acceptance test execution status in e2e-test-tracking.md and feature-tracking.md.

.DESCRIPTION
    After executing E2E acceptance tests, this script updates tracking files with results.
    Reads from e2e-test-tracking.md (split from test-tracking.md per PF-IMP-210).
    Can mark individual E2E test cases, entire groups, or all tests for a feature.
    Updates feature-tracking.md Test Status for all features listed in the entry's Feature IDs column.
    Updates Workflow Milestone Tracking row status based on aggregate test results.

.PARAMETER FeatureId
    Optional: Mark all E2E entries where Feature IDs column contains this feature.

.PARAMETER Group
    Optional: Mark a specific test group by name (matches group name in Test File/Case column).

.PARAMETER TestCase
    Optional: Mark a specific test case by ID (e.g., "TE-E2E-001").

.PARAMETER Status
    New status. Options: "Passed", "Failed", "Needs Re-execution".
    Maps to emoji statuses in e2e-test-tracking.md.

.PARAMETER Reason
    Optional: Why the status changed (e.g., "Bug fix PD-BUG-028", "Release validation").

.PARAMETER ProjectRoot
    Optional: Project root path. Auto-detected if not specified.

.EXAMPLE
    Update-TestExecutionStatus.ps1 -Group "powershell-regex-preservation" -Status "Passed"

.EXAMPLE
    Update-TestExecutionStatus.ps1 -FeatureId "1.1.1" -Status "Needs Re-execution" -Reason "Bug fix PD-BUG-032"

.EXAMPLE
    Update-TestExecutionStatus.ps1 -TestCase "TE-E2E-001" -Status "Failed" -Reason "Link not updated after rename"

.NOTES
    Created: 2026-03-15
    Updated: 2026-03-31
    Version: 2.2
    Task: E2E Acceptance Test Execution (PF-TSK-070)
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$FeatureId = "",

    [Parameter(Mandatory=$false)]
    [string]$Group = "",

    [Parameter(Mandatory=$false)]
    [string]$TestCase = "",

    [Parameter(Mandatory=$true)]
    [ValidateSet("Passed", "Failed", "Needs Re-execution")]
    [string]$Status,

    [Parameter(Mandatory=$false)]
    [string]$Reason = "",

    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = ""
)

# Import Common-ScriptHelpers for standardized utilities
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "../../../scripts/Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers: $($_.Exception.Message)"
    exit 1
}

# Validate at least one selector is provided
if (-not $FeatureId -and -not $Group -and -not $TestCase) {
    Write-ProjectError -Message "At least one of -FeatureId, -Group, or -TestCase must be specified." -ExitCode 1
}

# Resolve project root
if (-not $ProjectRoot) {
    $ProjectRoot = Get-ProjectRoot
    if (-not $ProjectRoot) {
        Write-ProjectError -Message "Could not auto-detect project root. Use -ProjectRoot parameter." -ExitCode 1
    }
}

# Map status to emoji
$statusMap = @{
    "Passed" = "✅ Passed"
    "Failed" = "🔴 Failed"
    "Needs Re-execution" = "🔄 Needs Re-execution"
}
$emojiStatus = $statusMap[$Status]
$timestamp = Get-Date -Format "yyyy-MM-dd"

$testTrackingPath = Join-Path $ProjectRoot "test/state-tracking/permanent/e2e-test-tracking.md"
$featureTrackingPath = Join-Path $ProjectRoot "doc/state-tracking/permanent/feature-tracking.md"

if (-not (Test-Path $testTrackingPath)) {
    Write-ProjectError -Message "E2E test tracking file not found: $testTrackingPath" -ExitCode 1
}

# Read e2e-test-tracking.md
$content = Get-Content $testTrackingPath -Raw -Encoding UTF8
$lines = $content -split '\r?\n'
$updatedLines = @()
$matchCount = 0
$inE2eSection = $false
$affectedFeatureIds = @()
$affectedWorkflows = @()

foreach ($line in $lines) {
    # Track when we enter/leave the E2E Acceptance Tests section
    if ($line -match '^## E2E (Acceptance Tests|Test Cases)') {
        $inE2eSection = $true
    }
    # Leave E2E section when hitting another ## section (but not ### subsections)
    if ($inE2eSection -and $line -match '^## [^#]' -and $line -notmatch '^## E2E (Acceptance Tests|Test Cases)') {
        $inE2eSection = $false
    }

    # Only match within the E2E section
    if ($inE2eSection -and $line -match '^\|') {
        $cells = Split-MarkdownTableRow $line

        # E2E Test Cases table columns:
        # 0: Test ID | 1: Workflow | 2: Feature IDs | 3: Test Type | 4: Test File/Case | 5: Status | 6: Last Executed | 7: Last Updated | 8: Notes
        if ($cells.Count -ge 6 -and $cells[0] -match '^TE-E2[EG]-\d+') {
            $testId = $cells[0]
            $workflowCol = $cells[1]
            $featureIdsCol = $cells[2]

            $isMatch = $false

            # Match by test case ID
            if ($TestCase -and $testId -eq $TestCase) {
                $isMatch = $true
            }

            # Match by group name (check Test File/Case column for group name)
            if ($Group -and $line -match [regex]::Escape($Group)) {
                $isMatch = $true
            }

            # Match by feature ID (check if Feature IDs column contains the target feature)
            if ($FeatureId -and $featureIdsCol -match [regex]::Escape($FeatureId)) {
                $isMatch = $true
            }

            if ($isMatch) {
                # Update Status (index 5), Last Executed (index 6), Last Updated (index 7)
                $cells[5] = $emojiStatus
                $cells[6] = $timestamp
                $cells[7] = $timestamp
                if ($Reason -and $cells.Count -ge 9) {
                    # For individual test case updates, always overwrite notes.
                    # For group/feature updates, only fill in empty notes to preserve case-level notes.
                    if ($TestCase -or -not $cells[8].Trim()) {
                        $cells[8] = $Reason
                    }
                }

                $line = ConvertTo-MarkdownTableRow -Cells $cells
                $matchCount++

                # Collect affected feature IDs for feature-tracking update
                $entryFeatureIds = $featureIdsCol -split ',' | ForEach-Object { $_.Trim() }
                foreach ($fId in $entryFeatureIds) {
                    if ($fId -and $affectedFeatureIds -notcontains $fId) {
                        $affectedFeatureIds += $fId
                    }
                }

                # Collect affected workflows for milestone update
                if ($workflowCol -and $workflowCol -ne "—" -and $affectedWorkflows -notcontains $workflowCol) {
                    $affectedWorkflows += $workflowCol
                }
            }
        }
    }

    $updatedLines += $line
}

if ($matchCount -eq 0) {
    Write-Warning "No matching entries found in e2e-test-tracking.md."
    Write-Warning "Selectors: FeatureId='$FeatureId', Group='$Group', TestCase='$TestCase'"
} else {
    # --- Update Workflow Milestone Tracking rows ---
    # Update milestone status based on execution results for each affected workflow
    if ($affectedWorkflows.Count -gt 0) {
        $finalLines = @()
        $inMilestoneSection = $false
        foreach ($line in $updatedLines) {
            # Track when we enter the Workflow Milestone Tracking section
            if ($line -match '^## Workflow Milestone Tracking') {
                $inMilestoneSection = $true
            }
            # Leave milestone section when hitting another ## section
            if ($inMilestoneSection -and $line -match '^## [^#]' -and $line -notmatch '^## Workflow Milestone Tracking') {
                $inMilestoneSection = $false
            }

            if ($inMilestoneSection -and $line -match '^\|') {
                foreach ($wf in $affectedWorkflows) {
                    if ($line -match [regex]::Escape($wf)) {
                        $cells = Split-MarkdownTableRow $line
                        # Milestone table columns: 0:Workflow | 1:Description | 2:Required Features | 3:Features Ready | 4:E2E Spec | 5:E2E Cases | 6:Status
                        if ($cells.Count -ge 7 -and $cells[0] -match '^WF-\d+') {
                            $milestoneStatus = switch ($Status) {
                                "Passed" { "✅ Covered" }
                                "Failed" { "🔴 Failing" }
                                "Needs Re-execution" { "🔄 Re-execution Needed" }
                            }
                            $cells[6] = $milestoneStatus
                            $line = ConvertTo-MarkdownTableRow -Cells $cells
                        }
                        break
                    }
                }
            }
            $finalLines += $line
        }
        $updatedLines = $finalLines
    }

    if ($PSCmdlet.ShouldProcess($testTrackingPath, "Update $matchCount test tracking entries to '$emojiStatus'")) {
        $updatedContent = ($updatedLines -join "`n") -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $timestamp"
        Set-Content $testTrackingPath $updatedContent -Encoding UTF8
        Write-ProjectSuccess -Message "Updated $matchCount entries in e2e-test-tracking.md -> $emojiStatus"
        if ($affectedWorkflows.Count -gt 0) {
            Write-ProjectSuccess -Message "Updated milestone status for workflows: $($affectedWorkflows -join ', ')"
        }
    }
}

# Update feature-tracking.md Test Status for all affected features
if ($affectedFeatureIds.Count -gt 0) {
    $featureStatus = switch ($Status) {
        "Passed" { "✅ All Passing" }
        "Failed" { "🔴 Some Failing" }
        "Needs Re-execution" { "🔄 Re-testing Needed" }
    }

    if (Test-Path $featureTrackingPath) {
        $ftContent = Get-Content $featureTrackingPath -Raw -Encoding UTF8
        $ftLines = $ftContent -split '\r?\n'
        $ftUpdatedLines = @()
        $ftUpdateCount = 0

        foreach ($ftLine in $ftLines) {
            $lineUpdated = $false
            if ($ftLine -match '^\|') {
                foreach ($targetFId in $affectedFeatureIds) {
                    if ($ftLine -match [regex]::Escape($targetFId) -and -not $lineUpdated) {
                        $ftCells = Split-MarkdownTableRow $ftLine
                        for ($i = 0; $i -lt $ftCells.Count; $i++) {
                            if ($ftCells[$i] -match '(No Tests|No Test Required|Specs Created|In Progress|All Passing|Some Failing|Automated Only|Re-testing Needed|Tests Approved)') {
                                $ftCells[$i] = $featureStatus
                                $lineUpdated = $true
                                $ftUpdateCount++
                                break
                            }
                        }
                        if ($lineUpdated) {
                            $ftLine = ConvertTo-MarkdownTableRow -Cells $ftCells
                        }
                    }
                }
            }
            $ftUpdatedLines += $ftLine
        }

        if ($ftUpdateCount -gt 0) {
            if ($PSCmdlet.ShouldProcess($featureTrackingPath, "Update Test Status for $ftUpdateCount features")) {
                $ftUpdatedContent = ($ftUpdatedLines -join "`n") -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $timestamp"
                Set-Content $featureTrackingPath $ftUpdatedContent -Encoding UTF8
                Write-ProjectSuccess -Message "Updated feature-tracking.md: $($affectedFeatureIds -join ', ') -> $featureStatus"
            }
        }
    }
}

# Update workflow tracking (E2E Status column derives from test execution results)
$workflowScript = Join-Path $ProjectRoot "process-framework/scripts/update/Update-WorkflowTracking.ps1"
if (Test-Path $workflowScript) {
    Write-Host ""
    Write-Host "Updating workflow tracking..." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess("user-workflow-tracking.md", "Update workflow statuses")) {
        & $workflowScript -ProjectRoot $ProjectRoot
    } else {
        & $workflowScript -ProjectRoot $ProjectRoot -WhatIf
    }
}

# Summary
Write-Host ""
Write-Host "Execution Status Update:" -ForegroundColor Cyan
Write-Host "  Status: $emojiStatus" -ForegroundColor Cyan
Write-Host "  Entries updated: $matchCount" -ForegroundColor Cyan
Write-Host "  Features affected: $($affectedFeatureIds -join ', ')" -ForegroundColor Cyan
Write-Host "  Workflows affected: $($affectedWorkflows -join ', ')" -ForegroundColor Cyan
if ($Reason) {
    Write-Host "  Reason: $Reason" -ForegroundColor Cyan
}
