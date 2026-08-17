#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Updates E2E acceptance test execution status in e2e-test-tracking.md and feature-tracking.md.

.DESCRIPTION
    After executing E2E acceptance tests, this script updates tracking files with results.
    Reads from e2e-test-tracking.md (split from test-tracking.md per PF-IMP-210).
    Can mark individual E2E test cases, entire workflows, or all tests for a feature.
    When multiple selectors are specified, all must match (AND logic), enabling
    per-case filtering within a workflow (e.g., -Workflow + -TestCase updates only that case).
    Updates feature-tracking.md Test Status for all features listed in the entry's Feature IDs column.
    Updates Workflow Milestone Tracking row status based on aggregate test results.

.PARAMETER FeatureId
    Optional: Mark all E2E entries where Feature IDs column contains this feature.

.PARAMETER Workflow
    Optional: Mark all entries for a specific workflow (matches the Workflow column —
    WF-NNN or workflow slug — in e2e-test-tracking.md).

.PARAMETER TestCase
    Optional: Mark a specific test case by ID (e.g., "TE-E2E-001"), or several at once as a
    comma/semicolon-delimited list (e.g., "TE-E2E-001,TE-E2E-005"). Every listed case receives the
    same -Status and -Reason in a single tracking-file write — so a suite run's failures can be
    annotated in one invocation instead of N. A delimited string (not a [string[]]) is used so the
    list survives `pwsh -File` invocation, which would otherwise collapse an array to one element.

.PARAMETER Status
    New status. Options: "Passed", "Failed", "Needs Re-execution".
    Maps to emoji statuses in e2e-test-tracking.md.

.PARAMETER Reason
    Optional: Why the status changed (e.g., "Bug fix PD-BUG-028", "Release validation").

.PARAMETER ProjectRoot
    Optional: Project root path. Auto-detected if not specified.

.EXAMPLE
    Update-TestExecutionStatus.ps1 -Workflow "WF-001" -Status "Passed"

.EXAMPLE
    Update-TestExecutionStatus.ps1 -FeatureId "1.1.1" -Status "Needs Re-execution" -Reason "Bug fix PD-BUG-032"

.EXAMPLE
    Update-TestExecutionStatus.ps1 -TestCase "TE-E2E-001" -Status "Failed" -Reason "Link not updated after rename"

.EXAMPLE
    Update-TestExecutionStatus.ps1 -Workflow "WF-001" -TestCase "TE-E2E-005" -Status "Failed" -Reason "Case 5 failed, others passed"

.EXAMPLE
    Update-TestExecutionStatus.ps1 -TestCase "TE-E2E-001,TE-E2E-005,TE-E2E-009" -Status "Failed" -Reason "PD-BUG-142"
    # Annotate several failed cases with one bug ID in a single tracking write (PF-IMP-1230).

.NOTES
    Created: 2026-03-15
    Updated: 2026-05-14 (PF-IMP-871 Phase 3c2 — `-Group` renamed to `-Workflow`; matches against
                        the Workflow column (index 1) instead of the whole line for cleaner semantics)
    Updated: 2026-06-17 (PF-IMP-1229 — feature-tracking update: anchor the row match to the Feature ID
                        column (was matching the ID anywhere in the row, corrupting features whose
                        Dependencies cell held the ID), and recompute each feature's Test Status by
                        aggregating across all its E2E case entries (was last-write-wins / order-dependent))
    Updated: 2026-06-24 (PF-IMP-1230 — -TestCase accepts a comma/semicolon-delimited list so a suite
                        run's failed cases can be marked with one -Status/-Reason in a single tracking
                        write, instead of N invocations; mirrors the -AlsoMoveIds batch pattern (PF-IMP-982))
    Updated: 2026-06-25 (PF-IMP-1285 — split multi-ID Workflow cells (a shared group tagged "WF-001, WF-002")
                        into individual IDs at collection so the affected-workflows summary no longer doubles,
                        and anchor the milestone-row match to the Workflow column (col 0) instead of a
                        whole-line regex match, mirroring the PF-IMP-1229 anchored-match fix)
    Version: 2.9
    Task: E2E Acceptance Test Execution (PF-TSK-070), PF-IMP-871, PF-IMP-1229, PF-IMP-1230, PF-IMP-1285
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$FeatureId = "",

    [Parameter(Mandatory=$false)]
    [string]$Workflow = "",

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

# Parse -TestCase into a list (PF-IMP-1230). Accepts a single ID ("TE-E2E-001") or a delimited list
# ("TE-E2E-001,TE-E2E-005") so a suite run's failed cases can be annotated with one -Status/-Reason in
# a single read-modify-write instead of N invocations. A comma/semicolon-delimited string is split here
# rather than declaring [string[]] because array parameters do not survive `pwsh -File` invocation (the
# whole list arrives as one literal element); mirrors the -AlsoMoveIds batch pattern in
# Update-ProcessImprovement.ps1 (PF-IMP-982). $hasTestCaseSelector replaces the prior `$TestCase`
# truthiness checks so list semantics flow through the match, notes, and group-rollup logic.
$testCaseList = @($TestCase -split '[,;]' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$hasTestCaseSelector = $testCaseList.Count -gt 0

# Validate at least one selector is provided
if (-not $FeatureId -and -not $Workflow -and -not $hasTestCaseSelector) {
    Write-ProjectError -Message "At least one of -FeatureId, -Workflow, or -TestCase must be specified." -ExitCode 1
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
        # 0: Test ID | 1: Workflow | 2: Feature IDs | 3: Test Type | 4: Test File/Case | 5: Status | 6: Last Executed | 7: Last Updated | 8: Audit Status | 9: Audit Report | 10: Notes
        if ($cells.Count -ge 6 -and $cells[0] -match '^TE-E2[EG]-\d+') {
            $testId = $cells[0]
            $workflowCol = $cells[1]
            $featureIdsCol = $cells[2]

            # AND logic: all specified selectors must match
            # -TestCase may carry several IDs (PF-IMP-1230) — match if this row's ID is any of them.
            $matchTestCase = (-not $hasTestCaseSelector) -or ($testId -in $testCaseList)
            # -Workflow matches against the Workflow column (index 1) specifically — cleaner
            # semantics than the prior whole-line match used by the legacy -Group selector
            # (PF-IMP-871 Phase 3c2).
            $matchWorkflow = (-not $Workflow) -or ($workflowCol -match [regex]::Escape($Workflow))
            $matchFeature = (-not $FeatureId) -or ($featureIdsCol -match [regex]::Escape($FeatureId))
            $isMatch = $matchTestCase -and $matchWorkflow -and $matchFeature

            if ($isMatch) {
                # Update Status (index 5), Last Executed (index 6), Last Updated (index 7)
                $cells[5] = $emojiStatus
                $cells[6] = $timestamp
                $cells[7] = $timestamp
                # Notes column management (index 10):
                # - Passed without -Reason: clear stale notes (e.g., old failure reasons)
                # - Passed with -Reason: set the explicit reason (overrides default clear)
                # - Failed/Re-execution with -Reason: set the reason
                # - Failed/Re-execution without -Reason: leave notes unchanged
                if ($cells.Count -ge 11) {
                    if ($Status -eq "Passed" -and -not $Reason) {
                        # Clear stale notes on pass (PF-IMP-533)
                        if ($hasTestCaseSelector -or -not $cells[10].Trim()) {
                            $cells[10] = ""
                        }
                    } elseif ($Reason) {
                        # For explicit test-case updates (one or a -TestCase list, PF-IMP-1230), always
                        # overwrite notes. For group/feature updates, only fill in empty notes to
                        # preserve case-level notes.
                        if ($hasTestCaseSelector -or -not $cells[10].Trim()) {
                            $cells[10] = $Reason
                        }
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

                # Collect affected workflows for milestone update. A Workflow cell may carry several
                # comma-separated IDs (a shared group tagged for multiple workflows, e.g. "WF-001, WF-002");
                # split so each ID is deduplicated and matched to its own milestone row (PF-IMP-1285).
                foreach ($wfId in ($workflowCol -split ',' | ForEach-Object { $_.Trim() })) {
                    if ($wfId -and $wfId -ne "—" -and $affectedWorkflows -notcontains $wfId) {
                        $affectedWorkflows += $wfId
                    }
                }
            }
        }
    }

    $updatedLines += $line
}

# --- Group status rollup when updating individual test cases ---
# When -TestCase is used (one or a list, PF-IMP-1230), aggregate child case statuses to update each
# affected parent group row.
if ($hasTestCaseSelector -and $matchCount -gt 0) {
    # Build group -> case status map from the E2E section
    $currentGroupIdx = -1
    $groupCaseStatuses = @{}  # groupLineIndex -> @(caseStatuses)
    $groupLineIndices = @()

    for ($i = 0; $i -lt $updatedLines.Count; $i++) {
        $uLine = $updatedLines[$i]
        if ($uLine -match '^\|') {
            $uCells = Split-MarkdownTableRow $uLine
            if ($uCells.Count -ge 6 -and $uCells[0] -match '^TE-E2[EG]-\d+') {
                $testType = $uCells[3].Trim()
                if ($testType -eq 'E2E Group') {
                    $currentGroupIdx = $i
                    $groupLineIndices += $i
                    if (-not $groupCaseStatuses.ContainsKey($i)) {
                        $groupCaseStatuses[$i] = @()
                    }
                } elseif ($testType -eq 'E2E Case' -and $currentGroupIdx -ge 0) {
                    $groupCaseStatuses[$currentGroupIdx] += $uCells[5].Trim()
                }
            }
        }
    }

    # Update group rows where at least one child was the matched test case
    $groupRollupCount = 0
    foreach ($gIdx in $groupLineIndices) {
        $caseStatuses = $groupCaseStatuses[$gIdx]
        if ($caseStatuses.Count -eq 0) { continue }

        # Check if any child case of this group was the one we just updated
        $groupHasUpdatedCase = $false
        for ($j = $gIdx + 1; $j -lt $updatedLines.Count; $j++) {
            $checkLine = $updatedLines[$j]
            if ($checkLine -match '^\|') {
                $checkCells = Split-MarkdownTableRow $checkLine
                if ($checkCells.Count -ge 6 -and $checkCells[0] -match '^TE-E2[EG]-\d+') {
                    if ($checkCells[3].Trim() -eq 'E2E Group') { break }
                    if ($checkCells[0].Trim() -in $testCaseList) {
                        $groupHasUpdatedCase = $true
                        break
                    }
                }
            }
        }
        if (-not $groupHasUpdatedCase) { continue }

        # Determine aggregate status
        $hasFailed = $caseStatuses | Where-Object { $_ -match 'Failed' }
        $allPassed = ($caseStatuses | Where-Object { $_ -match 'Passed' }).Count -eq $caseStatuses.Count

        if ($allPassed) {
            $aggregateStatus = "✅ Passed"
        } elseif ($hasFailed) {
            $aggregateStatus = "🔴 Failed"
        } else {
            $aggregateStatus = "🔄 Needs Re-execution"
        }

        $gCells = Split-MarkdownTableRow $updatedLines[$gIdx]
        $oldGroupStatus = $gCells[5].Trim()
        if ($oldGroupStatus -ne $aggregateStatus) {
            $gCells[5] = $aggregateStatus
            $gCells[6] = $timestamp
            $gCells[7] = $timestamp
            $updatedLines[$gIdx] = ConvertTo-MarkdownTableRow -Cells $gCells
            $groupRollupCount++

            # Collect group's features and workflows for downstream updates
            $gFeatureIds = $gCells[2] -split ',' | ForEach-Object { $_.Trim() }
            foreach ($fId in $gFeatureIds) {
                if ($fId -and $affectedFeatureIds -notcontains $fId) {
                    $affectedFeatureIds += $fId
                }
            }
            # Split multi-ID workflow cells here too (PF-IMP-1285), matching the main-loop collection above.
            foreach ($wfId in ($gCells[1] -split ',' | ForEach-Object { $_.Trim() })) {
                if ($wfId -and $wfId -ne "—" -and $affectedWorkflows -notcontains $wfId) {
                    $affectedWorkflows += $wfId
                }
            }
        }
    }

    if ($groupRollupCount -gt 0) {
        Write-Host "  Group rollup: updated $groupRollupCount group(s) based on aggregated case statuses" -ForegroundColor Yellow
    }
}

if ($matchCount -eq 0) {
    Write-Warning "No matching entries found in e2e-test-tracking.md."
    Write-Warning "Selectors: FeatureId='$FeatureId', Workflow='$Workflow', TestCase='$TestCase'"
} else {
    # --- Update Workflow Milestone Tracking rows ---
    # Update milestone status based on execution results for each affected workflow.
    # Tracks $milestoneRowsUpdated so the success message reflects actual writes vs. silent no-op
    # (the table is empty until PF-TSK-086 Performance & E2E Test Scoping creates milestone rows).
    $milestoneRowsUpdated = 0
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
                $cells = Split-MarkdownTableRow $line
                # Milestone table columns: 0:Workflow | 1:Description | 2:Required Features | 3:Features Ready | 4:E2E Spec | 5:E2E Cases | 6:Status
                # Anchor to the Workflow column (col 0) — an affected ID could otherwise substring-match
                # another row's Description/Required-Features cell (cf. the PF-IMP-1229 anchored-match fix
                # for feature-tracking above). $affectedWorkflows holds individual IDs (multi-ID cells
                # split at collection, PF-IMP-1285).
                if ($cells -and $cells.Count -ge 7 -and $cells[0] -match '^WF-\d+' -and $affectedWorkflows -contains $cells[0]) {
                    $milestoneStatus = switch ($Status) {
                        "Passed" { "✅ Covered" }
                        "Failed" { "🔴 Failing" }
                        "Needs Re-execution" { "🔄 Re-execution Needed" }
                    }
                    $cells[6] = $milestoneStatus
                    $line = ConvertTo-MarkdownTableRow -Cells $cells
                    $milestoneRowsUpdated++
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
            if ($milestoneRowsUpdated -gt 0) {
                Write-ProjectSuccess -Message "Updated milestone status for workflows: $($affectedWorkflows -join ', ')"
            } else {
                Write-Host "  Workflow Milestone Tracking: no rows for affected workflows ($($affectedWorkflows -join ', ')) — create via PF-TSK-086 to enable milestone tracking" -ForegroundColor Yellow
            }
        }
    }
}

# Update feature-tracking.md Test Status for all affected features.
# PF-IMP-1229 fix for two defects in this block:
#   (1) Unanchored match — the old code matched the feature ID anywhere in the row, so stamping
#       feature 2.1.1 also rewrote feature 6.1.1 when 6.1.1's Dependencies cell contained "2.1.1".
#       Now the row is selected by an EXACT match on the Feature ID column (index 0).
#   (2) Last-write-wins — the old code stamped the single -Status value, making the final feature
#       Test Status execution-order-dependent. Now each feature's status is RECOMPUTED by aggregating
#       across all of its E2E case entries (mirrors the group-rollup rule above).
if ($affectedFeatureIds.Count -gt 0) {
    # Fallback mapping when a feature has no leaf E2E case entries to aggregate (e.g. carried only on
    # a group row) — preserves the prior single-status behavior for that edge case.
    $featureStatusFromArg = switch ($Status) {
        "Passed" { "✅ All Passing" }
        "Failed" { "🔴 Some Failing" }
        "Needs Re-execution" { "🔄 Re-testing Needed" }
    }

    # Feature IDs appear bare ("2.1.1") in the E2E Feature IDs column but as a markdown link
    # ("[2.1.1](path)") in the feature-tracking ID column. Normalize to the bare ID so the anchored
    # match below works across both forms (PF-IMP-1229: real projects link the feature-tracking ID;
    # an exact match on the raw cell would silently skip every linked row).
    $toBareFid = {
        param($raw)
        $v = "$raw".Trim()
        if ($v -match '^\[([^\]]+)\]') { $v = $matches[1].Trim() }
        $v
    }
    $affectedBare = @{}
    foreach ($a in $affectedFeatureIds) { $affectedBare[(& $toBareFid $a)] = $true }

    # (2) Recompute: for each affected feature, aggregate the post-update statuses of all its E2E
    # *case* entries (E2E Group rows are excluded to avoid double-counting their children). Same rule
    # as the group rollup: all Passed -> All Passing; any Failed -> Some Failing; otherwise -> Re-testing Needed.
    $featureAggregateStatus = @{}
    foreach ($bareFid in $affectedBare.Keys) {
        $caseStatuses = @()
        $inE2eAgg = $false
        foreach ($aggLine in $updatedLines) {
            if ($aggLine -match '^## E2E (Acceptance Tests|Test Cases)') { $inE2eAgg = $true; continue }
            if ($inE2eAgg -and $aggLine -match '^## [^#]' -and $aggLine -notmatch '^## E2E (Acceptance Tests|Test Cases)') { $inE2eAgg = $false }
            if (-not $inE2eAgg -or $aggLine -notmatch '^\|') { continue }
            $aggCells = Split-MarkdownTableRow $aggLine
            if ($aggCells.Count -lt 6 -or $aggCells[0] -notmatch '^TE-E2[EG]-\d+') { continue }
            if ($aggCells[3].Trim() -eq 'E2E Group') { continue }   # leaf cases only
            $aggFeatureIds = $aggCells[2] -split ',' | ForEach-Object { & $toBareFid $_ }
            if ($aggFeatureIds -contains $bareFid) {
                $caseStatuses += $aggCells[5].Trim()
            }
        }

        if ($caseStatuses.Count -eq 0) {
            $featureAggregateStatus[$bareFid] = $featureStatusFromArg
            continue
        }

        $hasFailed = @($caseStatuses | Where-Object { $_ -match 'Failed' }).Count -gt 0
        $allPassed = @($caseStatuses | Where-Object { $_ -match 'Passed' }).Count -eq $caseStatuses.Count
        if ($allPassed) {
            $featureAggregateStatus[$bareFid] = "✅ All Passing"
        } elseif ($hasFailed) {
            $featureAggregateStatus[$bareFid] = "🔴 Some Failing"
        } else {
            $featureAggregateStatus[$bareFid] = "🔄 Re-testing Needed"
        }
    }

    if (Test-Path $featureTrackingPath) {
        $ftContent = Get-Content $featureTrackingPath -Raw -Encoding UTF8
        $ftLines = $ftContent -split '\r?\n'
        $ftUpdatedLines = @()
        $ftUpdateCount = 0
        $ftWrittenStatuses = @()

        foreach ($ftLine in $ftLines) {
            if ($ftLine -match '^\|') {
                $ftCells = Split-MarkdownTableRow $ftLine
                # (1) Anchored match: the main feature table is
                # | 0:ID | 1:Feature | 2:Status | 3:Priority | 4:Doc Tier | 5:Test Status | 6:Dependencies | 7:Notes |.
                # Require Count -ge 8 (skips the 5-column Archived Features table) and an EXACT match on the
                # Feature ID column (col 0), normalized to its bare form so a linked "[6.1.1](path)" ID matches
                # while a feature ID merely appearing in another row's Dependencies cell does not. Then write
                # the Test Status column (col 5) by position.
                if ($ftCells.Count -ge 8) {
                    $rowFeatureId = & $toBareFid $ftCells[0]
                    if ($affectedBare.ContainsKey($rowFeatureId)) {
                        $newStatus = $featureAggregateStatus[$rowFeatureId]
                        if ($newStatus -and $ftCells[5].Trim() -ne $newStatus) {
                            $ftCells[5] = $newStatus
                            $ftLine = ConvertTo-MarkdownTableRow -Cells $ftCells
                            $ftUpdateCount++
                            $ftWrittenStatuses += "$rowFeatureId -> $newStatus"
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
                Write-ProjectSuccess -Message "Updated feature-tracking.md Test Status: $($ftWrittenStatuses -join '; ')"
            }
        }
    }
}

# Update workflow tracking (E2E Status column derives from test execution results)
$workflowScript = Join-Path (Get-ProcessFrameworkPath) "scripts/update/Update-WorkflowTracking.ps1"
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
