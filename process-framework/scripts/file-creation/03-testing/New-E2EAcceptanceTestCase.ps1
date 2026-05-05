# New-E2EAcceptanceTestCase.ps1
# Creates a new E2E acceptance test case directory structure with an automatically assigned E2E-NNN ID
# Creates test-case.md from template, project/ and expected/ subdirectories
# Optionally creates run.ps1 skeleton for scripted (automatable) test cases
# Updates master test file's "If Failed" table, e2e-test-tracking.md, and feature-tracking.md

<#
.SYNOPSIS
    Creates a new E2E acceptance test case with an automatically assigned E2E-NNN ID.

.DESCRIPTION
    This PowerShell script generates E2E acceptance test case directory structures by:
    - Generating a unique test case ID (E2E-NNN) from the central ID registry
    - Creating the directory E2E-NNN-[name]/ with project/ and expected/ subdirectories
    - Copying and customizing test-case.md from the E2E acceptance test case template
    - Optionally creating a run.ps1 skeleton for scripted (automatable) test cases
    - Adding the test case to the group's master test "If Failed" table
    - Adding a new entry to e2e-test-tracking.md
    - Updating feature-tracking.md Test Status via Update-FeatureTrackingStatus

.PARAMETER TestCaseName
    Short descriptive name for the test case (used in directory name, e.g., "single-file-rename")

.PARAMETER GroupName
    Name of the test group this case belongs to (e.g., "basic-file-operations").
    Must match an existing group directory under test/e2e-acceptance-testing/templates/.

.PARAMETER FeatureId
    The feature ID this test case validates (e.g., "1.1.1")

.PARAMETER FeatureName
    Human-readable feature name (e.g., "File System Monitoring")

.PARAMETER Priority
    Test case priority: P0, P1, P2, or P3 (default: P1)

.PARAMETER Source
    What triggered this test case creation (e.g., "Test Spec PF-TSP-038", "Bug Report PD-BUG-025")

.PARAMETER Description
    Brief description of what the test case validates

.PARAMETER NewGroup
    Switch to create a new test group directory and master test file.
    When set, creates the group directory and a master test from template.

.PARAMETER Scripted
    Switch to create a scripted (automatable) test case.
    When set, creates a run.ps1 skeleton in the test case directory and sets
    executionMode to "scripted" in test-case.md. The run.ps1 script contains
    only the test action; setup and verification are handled by existing scripts.
    Can be executed by AI agent via Run-E2EAcceptanceTest.ps1 or by human manually.

.PARAMETER OpenInEditor
    If specified, opens the created test-case.md in the default editor

.EXAMPLE
    New-E2EAcceptanceTestCase.ps1 -TestCaseName "single-file-rename" -GroupName "basic-file-operations" -FeatureId "1.1.1" -FeatureName "File System Monitoring" -Source "Test Spec PF-TSP-038" -Description "Verify single file rename updates all references"

.EXAMPLE
    New-E2EAcceptanceTestCase.ps1 -TestCaseName "single-file-rename" -GroupName "basic-file-operations" -FeatureId "1.1.1" -FeatureName "File System Monitoring" -NewGroup -Source "Test Spec PF-TSP-038" -Description "Verify single file rename updates all references"

.EXAMPLE
    New-E2EAcceptanceTestCase.ps1 -TestCaseName "move-readme-to-archive" -GroupName "basic-file-operations" -FeatureId "1.1.1" -FeatureName "File System Monitoring" -Scripted -Source "Test Spec PF-TSP-038" -Description "Move readme.md and verify link updates"

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new E2E ID assignments
    - Creates the test group directory if -NewGroup is specified
    - Updates master test, e2e-test-tracking.md, and feature-tracking.md automatically
    - The test-case.md, project/, and expected/ contents must be customized after creation
    - When -Scripted is used, run.ps1 skeleton is also created and must be customized
    - Scripted test cases can be executed via Run-E2EAcceptanceTest.ps1 (Setup → run.ps1 → wait → Verify)

    Created: 2026-03-15
    Updated: 2026-03-18
    Version: 1.1
    Task: E2E Acceptance Test Case Creation (PF-TSK-069)
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$TestCaseName,

    [Parameter(Mandatory=$true)]
    [string]$GroupName,

    [Parameter(Mandatory=$true)]
    [string]$FeatureIds,

    [Parameter(Mandatory=$true)]
    [string]$FeatureName,

    [Parameter(Mandatory=$false)]
    [string]$Workflow = "",

    [Parameter(Mandatory=$false)]
    [ValidateSet("P0", "P1", "P2", "P3")]
    [string]$Priority = "P1",

    [Parameter(Mandatory=$false)]
    [string]$Source = "",

    [Parameter(Mandatory=$false)]
    [string]$Description = "",

    [Parameter(Mandatory=$false)]
    [switch]$NewGroup,

    [Parameter(Mandatory=$false)]
    [switch]$Scripted,

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Soak verification (PF-PRO-028 v2.0 Pattern A; caller-aware no-arg form)
Register-SoakScript
$soakInSoak = Test-ScriptInSoak

try {
    $projectRoot = Get-ProjectRoot
    $timestamp = Get-ProjectTimestamp -Format "Date"

    # --- 0. Parse FeatureIds (comma-separated string → array) ---
    $featureIdArray = $FeatureIds -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    $primaryFeatureId = $featureIdArray[0]
    $featureIdsDisplay = $featureIdArray -join ', '
    $featureIdsYaml = '["' + ($featureIdArray -join '", "') + '"]'

    Write-Verbose "Feature IDs: $featureIdsDisplay (primary: $primaryFeatureId)"
    if ($Workflow) { Write-Verbose "Workflow: $Workflow" }

    # --- 1. Assign TE-E2E ID from registry ---
    $idRegistryPath = Join-Path $projectRoot "test/TE-id-registry.json"
    $idRegistry = Get-Content $idRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json

    $e2ePrefix = $idRegistry.prefixes.'TE-E2E'
    $e2eId = "TE-E2E-{0:D3}" -f $e2ePrefix.nextAvailable

    # Increment the counter
    $e2ePrefix.nextAvailable = $e2ePrefix.nextAvailable + 1
    if ($PSCmdlet.ShouldProcess($idRegistryPath, "Update TE-E2E ID counter")) {
        $idRegistry | ConvertTo-Json -Depth 10 | Set-Content $idRegistryPath -Encoding UTF8
    }

    Write-Verbose "Assigned test case ID: $e2eId"

    # --- 2. Resolve paths ---
    $e2eTestingRoot = Join-Path $projectRoot "test/e2e-acceptance-testing/templates"
    $groupDir = Join-Path $e2eTestingRoot $GroupName
    $testCaseDir = Join-Path $groupDir "$e2eId-$TestCaseName"
    $projectDir = Join-Path $testCaseDir "project"
    $expectedDir = Join-Path $testCaseDir "expected"
    $testCaseFile = Join-Path $testCaseDir "test-case.md"
    $masterTestFile = Join-Path $groupDir "master-test-$GroupName.md"

    # --- 3. Create group directory if -NewGroup ---
    if ($NewGroup) {
        if (Test-Path $groupDir) {
            Write-Warning "Group directory already exists: $groupDir"
        } else {
            if ($PSCmdlet.ShouldProcess($groupDir, "Create group directory")) {
                New-Item -ItemType Directory -Path $groupDir -Force | Out-Null
                Write-Verbose "Created group directory: $groupDir"
            }
        }

        # Assign TE-E2G ID
        $grpPrefix = $idRegistry.prefixes.'TE-E2G'
        $grpId = "TE-E2G-{0:D3}" -f $grpPrefix.nextAvailable
        $grpPrefix.nextAvailable = $grpPrefix.nextAvailable + 1
        if ($PSCmdlet.ShouldProcess($idRegistryPath, "Update TE-E2G ID counter")) {
            $idRegistry | ConvertTo-Json -Depth 10 | Set-Content $idRegistryPath -Encoding UTF8
        }

        Write-Verbose "Assigned group ID: $grpId"

        # Create master test from template
        $masterTemplatePath = Join-Path $projectRoot "process-framework/templates/03-testing/e2e-acceptance-master-test-template.md"
        if (Test-Path $masterTemplatePath) {
            $masterContent = Get-Content $masterTemplatePath -Raw -Encoding UTF8

            # Extract template content (everything after the frontmatter and instruction comments)
            # Find the line "<!-- TEMPLATE STARTS BELOW THIS LINE -->" and take everything after it
            $templateMarker = "<!-- TEMPLATE STARTS BELOW THIS LINE -->"
            $markerIndex = $masterContent.IndexOf($templateMarker)
            if ($markerIndex -ge 0) {
                $masterContent = $masterContent.Substring($markerIndex + $templateMarker.Length).TrimStart()
            }

            # Remove remaining instruction comments
            $masterContent = $masterContent -replace '<!-- Copy everything below into.*?-->\s*', ''

            # Apply replacements
            $masterContent = $masterContent -replace '\[GROUP-NAME\]', $GroupName
            $masterContent = $masterContent -replace '\[GROUP-ID\]', $grpId
            $masterContent = $masterContent -replace '\[FEATURE-ID\]', $featureIdsDisplay
            $masterContent = $masterContent -replace '\[FEATURE-NAME\]', $FeatureName
            $masterContent = $masterContent -replace '\[NUMBER\]', "0"
            $masterContent = $masterContent -replace '\[YYYY-MM-DD\]', $timestamp
            $masterContent = $masterContent -replace '\[X minutes\]', "[ESTIMATED DURATION]"

            if ($PSCmdlet.ShouldProcess($masterTestFile, "Create master test file")) {
                Set-Content $masterTestFile $masterContent -Encoding UTF8
                Write-Verbose "Created master test: $masterTestFile"
            }
        } else {
            Write-Warning "Master test template not found: $masterTemplatePath"
        }
    }

    # Verify group directory exists (skip check in WhatIf mode since creation was simulated)
    if (-not $WhatIfPreference -and -not (Test-Path $groupDir)) {
        throw "Group directory does not exist: $groupDir. Use -NewGroup to create it."
    }

    # Resolve group ID for existing groups (read from master test YAML frontmatter)
    $grpIdForRegistry = "—"
    if ($NewGroup) {
        $grpIdForRegistry = $grpId
    } elseif (Test-Path $masterTestFile) {
        $masterLines = Get-Content $masterTestFile -Encoding UTF8
        foreach ($mLine in $masterLines) {
            if ($mLine -match '^id:\s*(TE-E2G-\d+)') {
                $grpIdForRegistry = $matches[1]
                break
            }
        }
    }

    # --- 4. Create test case directory structure ---
    if ($PSCmdlet.ShouldProcess($testCaseDir, "Create test case directory structure")) {
        New-Item -ItemType Directory -Path $testCaseDir -Force | Out-Null
        New-Item -ItemType Directory -Path $projectDir -Force | Out-Null
        New-Item -ItemType Directory -Path $expectedDir -Force | Out-Null

        # Add .gitkeep to empty directories so git tracks them
        Set-Content (Join-Path $projectDir ".gitkeep") "" -Encoding UTF8
        Set-Content (Join-Path $expectedDir ".gitkeep") "" -Encoding UTF8

        Write-Verbose "Created directory structure: $testCaseDir"

        # Create run.ps1 skeleton for scripted tests
        if ($Scripted) {
            $runScriptPath = Join-Path $testCaseDir "run.ps1"
            $runScriptContent = @"
# run.ps1 — Scripted action for $e2eId ($($TestCaseName -replace '-', ' '))
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "$e2eId" -Group "$GroupName"

param(
    [Parameter(Mandatory=`$true)]
    [string]`$WorkspacePath
)

# TODO: Replace with the actual test action
# Example: Move-Item "`$WorkspacePath/project/docs/readme.md" "`$WorkspacePath/project/archive/readme.md"
Write-Warning "run.ps1 is a skeleton — replace this with the actual test action"
"@
            Set-Content $runScriptPath $runScriptContent -Encoding UTF8
            Write-Verbose "Created run.ps1 skeleton: $runScriptPath"
        }
    }

    # --- 5. Create test-case.md from template ---
    $testCaseTemplatePath = Join-Path $projectRoot "process-framework/templates/03-testing/e2e-acceptance-test-case-template.md"
    if (Test-Path $testCaseTemplatePath) {
        $testCaseContent = Get-Content $testCaseTemplatePath -Raw -Encoding UTF8

        # Extract template content after the marker
        $templateMarker = "<!-- TEMPLATE STARTS BELOW THIS LINE -->"
        $markerIndex = $testCaseContent.IndexOf($templateMarker)
        if ($markerIndex -ge 0) {
            $testCaseContent = $testCaseContent.Substring($markerIndex + $templateMarker.Length).TrimStart()
        }

        # Remove copy instruction comment
        $testCaseContent = $testCaseContent -replace '<!-- Copy everything below into.*?-->\s*', ''

        # Apply replacements
        $testCaseContent = $testCaseContent -replace '\[E2E-NNN\]', $e2eId
        $testCaseContent = $testCaseContent -replace '\[TE-E2E-NNN\]', $e2eId
        $testCaseContent = $testCaseContent -replace '\[TITLE\]', ($TestCaseName -replace '-', ' ')
        $testCaseContent = $testCaseContent -replace '\[GROUP-NAME\]', $GroupName
        $testCaseContent = $testCaseContent -replace '\[GROUP-ID\]', $grpIdForRegistry
        $testCaseContent = $testCaseContent -replace '\[FEATURE-IDS-YAML\]', $featureIdsYaml
        $testCaseContent = $testCaseContent -replace '\[FEATURE-ID\]', $featureIdsDisplay
        $testCaseContent = $testCaseContent -replace '\[FEATURE-NAME\]', $FeatureName
        $testCaseContent = $testCaseContent -replace '\[WF-NNN\]', $(if ($Workflow) { $Workflow } else { "[WF-NNN]" })
        $testCaseContent = $testCaseContent -replace '\[P0 / P1 / P2 / P3\]', $Priority
        $testCaseContent = $testCaseContent -replace '\[YYYY-MM-DD\]', $timestamp
        if ($Source) {
            $testCaseContent = $testCaseContent -replace '\[Test Spec / Bug Report / Refactoring Plan\] — \[SOURCE-ID\]', $Source
        }

        # Set execution mode and handle Scripted Action section
        if ($Scripted) {
            $testCaseContent = $testCaseContent -replace '\[manual / scripted\]', 'scripted'
        } else {
            $testCaseContent = $testCaseContent -replace '\[manual / scripted\]', 'manual'
            # Remove the entire Scripted Action section for manual tests
            $testCaseContent = $testCaseContent -replace '(?s)## Scripted Action\r?\n.*?(?=## Expected Results)', ''
        }

        if ($PSCmdlet.ShouldProcess($testCaseFile, "Create test-case.md")) {
            Set-Content $testCaseFile $testCaseContent -Encoding UTF8
            Write-Verbose "Created test-case.md: $testCaseFile"
        }
    } else {
        throw "Test case template not found: $testCaseTemplatePath"
    }

    # --- 6. Update master test "If Failed" table ---
    if (Test-Path $masterTestFile) {
        $masterContent = Get-Content $masterTestFile -Raw -Encoding UTF8
        $testCaseRelPath = "$e2eId-$TestCaseName/test-case.md"
        $displayDescription = if ($Description) { $Description } else { ($TestCaseName -replace '-', ' ') }
        $newRow = "| $e2eId | [$testCaseRelPath]($testCaseRelPath) | $displayDescription |"

        # Find the "If Failed" table and add the row
        $lines = $masterContent -split '\r?\n'
        $updatedLines = @()
        $inFailedSection = $false
        $inTable = $false
        $rowAdded = $false

        foreach ($line in $lines) {
            # Detect "## If Failed" section
            if ($line -match '^## If Failed') {
                $inFailedSection = $true
                $updatedLines += $line
                continue
            }

            # Detect leaving the section
            if ($inFailedSection -and $line -match '^## ' -and $line -notmatch '^## If Failed') {
                $inFailedSection = $false
                $inTable = $false
            }

            # Detect table rows in the If Failed section
            if ($inFailedSection -and $line -match '^\|.*\|$') {
                $inTable = $true
                # Check for placeholder rows
                if ($line -match '\[E2E-001\].*\[Brief description\]' -or $line -match '\[E2E-002\].*\[Brief description\]' -or $line -match '\[E2E-003\].*\[Brief description\]') {
                    if (-not $rowAdded) {
                        $updatedLines += $newRow
                        $rowAdded = $true
                    }
                    continue  # Skip placeholder row
                }
                $updatedLines += $line
                continue
            }

            # If we just left the table without adding the row
            if ($inFailedSection -and $inTable -and $line -notmatch '^\|.*\|$' -and -not $rowAdded) {
                $updatedLines += $newRow
                $rowAdded = $true
                $inTable = $false
            }

            $updatedLines += $line
        }

        # Update the "Test Cases Covered" count in metadata
        $currentCount = [regex]::Match(($updatedLines -join "`n"), 'Test Cases Covered \| (\d+)').Groups[1].Value
        if ($currentCount) {
            $newCount = [int]$currentCount + 1
            $updatedLines = $updatedLines | ForEach-Object {
                $_ -replace "Test Cases Covered \| $currentCount", "Test Cases Covered | $newCount"
            }
        }

        if ($PSCmdlet.ShouldProcess($masterTestFile, "Update master test If Failed table")) {
            Set-Content $masterTestFile ($updatedLines -join "`n") -Encoding UTF8
            Write-Verbose "Updated master test: $masterTestFile"

            # Verify deterministic post-condition: test case row was added (PF-PRO-028 v2.0)
            Assert-LineInFile -Path $masterTestFile -Pattern "\| $e2eId \|" -Context "test case row for $e2eId in $masterTestFile"
        }
    } else {
        Write-Warning "Master test file not found: $masterTestFile. Skipping master test update."
    }

    # --- 7. Update e2e-test-tracking.md ---
    $testTrackingPath = Join-Path $projectRoot "test/state-tracking/permanent/e2e-test-tracking.md"
    if (Test-Path $testTrackingPath) {
        $trackingContent = Get-Content $testTrackingPath -Raw -Encoding UTF8

        # Build relative path from e2e-test-tracking.md to the test case
        $testCaseRelativePath = "../../../../test/e2e-acceptance-testing/templates/$GroupName/$e2eId-$TestCaseName/test-case.md"
        $trackingNotes = if ($Description) { $Description } else { ($TestCaseName -replace '-', ' ') }
        $workflowCol = if ($Workflow) { $Workflow } else { "—" }
        $testCaseLink = "[$e2eId-$TestCaseName]($testCaseRelativePath)"

        # Build the new row for the dedicated E2E Test Cases table
        # Columns: Test ID | Workflow | Feature IDs | Test Type | Test File/Case | Status | Last Executed | Last Updated | Audit Status | Audit Report | Notes
        $newRow = "| $e2eId | $workflowCol | $featureIdsDisplay | E2E Case | $testCaseLink | 📋 Needs Execution | — | $timestamp | — | — | $trackingNotes |"

        # Build TE-E2G group row if -NewGroup (inserted before the test case row)
        $newGroupRow = $null
        if ($NewGroup) {
            $masterTestRelativePath = "../../../../test/e2e-acceptance-testing/templates/$GroupName/master-test-$GroupName.md"
            $masterTestLink = "[master-test-$GroupName.md]($masterTestRelativePath)"
            $groupNotes = ($GroupName -replace '-', ' ')
            $newGroupRow = "| $grpIdForRegistry | $workflowCol | $featureIdsDisplay | E2E Group | $masterTestLink | 📋 Needs Execution | — | $timestamp | — | — | $groupNotes |"
        }

        # Find the E2E Test Cases table and append the row(s) before the --- separator
        $lines = $trackingContent -split '\r?\n'
        $updatedLines = @()
        $inE2eSection = $false
        $inE2eTable = $false
        $rowAdded = $false

        foreach ($line in $lines) {
            if ($line -match '^## E2E Test Cases') {
                $inE2eSection = $true
            }

            # Detect end of E2E section (next ## or ---)
            if ($inE2eSection -and $inE2eTable -and ($line -match '^---$' -or ($line -match '^## ' -and $line -notmatch '^### '))) {
                if (-not $rowAdded) {
                    if ($newGroupRow) { $updatedLines += $newGroupRow }
                    $updatedLines += $newRow
                    $rowAdded = $true
                }
                $inE2eSection = $false
                $inE2eTable = $false
            }

            # Detect table start in E2E section
            if ($inE2eSection -and $line -match '^\|.*Test ID.*\|') {
                $inE2eTable = $true
            }

            # Detect end of table rows (empty line after table)
            if ($inE2eSection -and $inE2eTable -and $line -match '^\s*$' -and -not $rowAdded) {
                if ($newGroupRow) { $updatedLines += $newGroupRow }
                $updatedLines += $newRow
                $rowAdded = $true
                $inE2eTable = $false
            }

            $updatedLines += $line
        }

        if (-not $rowAdded) {
            Write-Warning "Could not find E2E Test Cases table in e2e-test-tracking.md"
        }

        $updatedContent = $updatedLines -join "`n"

        # --- 7b. Update Workflow Milestone Tracking table (if -NewGroup and -Workflow) ---
        if ($NewGroup -and $Workflow) {
            $milestoneLines = $updatedContent -split '\r?\n'
            $milestoneUpdated = @()
            $milestoneFound = $false

            foreach ($mLine in $milestoneLines) {
                if (-not $milestoneFound -and $mLine -match "^\|.*$([regex]::Escape($Workflow)).*\|") {
                    # Parse the row columns and append the group ID to the E2E Cases column (index 5)
                    $cols = Split-MarkdownTableRow $mLine
                    if ($cols -and $cols.Count -ge 7) {
                        $e2eCasesCol = $cols[5]
                        if ($e2eCasesCol -eq '—' -or $e2eCasesCol -eq '' -or $e2eCasesCol -eq '-') {
                            $cols[5] = $grpIdForRegistry
                        } else {
                            $cols[5] = "$e2eCasesCol, $grpIdForRegistry"
                        }
                        # Update status to "📋 Cases Created" if currently at an earlier stage
                        if ($cols[6] -match '⏳|—') {
                            $cols[6] = '📋 Cases Created'
                        }
                        # Rebuild the row
                        $mLine = ConvertTo-MarkdownTableRow -Cells $cols
                        $milestoneFound = $true
                        Write-Verbose "Updated Workflow Milestone Tracking: $Workflow += $grpIdForRegistry"
                    }
                }
                $milestoneUpdated += $mLine
            }

            if (-not $milestoneFound) {
                Write-Warning "Workflow $Workflow not found in Workflow Milestone Tracking table"
            }

            $updatedContent = $milestoneUpdated -join "`n"
        }

        if ($PSCmdlet.ShouldProcess($testTrackingPath, "Add E2E test entry to e2e-test-tracking.md")) {
            Set-Content $testTrackingPath $updatedContent -Encoding UTF8
            Write-Verbose "Updated e2e-test-tracking.md with $e2eId"

            # Verify deterministic post-condition: test case row was added (PF-PRO-028 v2.0)
            Assert-LineInFile -Path $testTrackingPath -Pattern "\| $e2eId \|" -Context "E2E test row for $e2eId in $testTrackingPath"
        }
    } else {
        Write-Warning "Test tracking file not found: $testTrackingPath"
    }

    # --- 8. (Removed) test-registry.yaml entry ---
    # SC-007: E2E entries are tracked in e2e-test-tracking.md (IMP-210).
    # test-registry.yaml has been retired. No registry write needed.

    # --- 9. Update feature-tracking.md Test Status (all features) ---
    $featureTrackingPath = Join-Path $projectRoot "doc/state-tracking/permanent/feature-tracking.md"
    if (Test-Path $featureTrackingPath) {
        foreach ($fId in $featureIdArray) {
            try {
                Update-FeatureTrackingStatus `
                    -FeatureId $fId `
                    -Status "🟡 In Progress" `
                    -StatusColumn "Test Status"
                Write-Verbose "Updated feature-tracking.md Test Status for $fId"
            } catch {
                Write-Warning "Could not update feature-tracking.md for $fId`: $($_.Exception.Message)"
            }
        }
    }

    # --- Success output ---
    $details = @(
        "Test Case ID: $e2eId",
        "Directory: test/e2e-acceptance-testing/templates/$GroupName/$e2eId-$TestCaseName/",
        "Features: $featureIdsDisplay — $FeatureName",
        "Workflow: $(if ($Workflow) { $Workflow } else { '(not specified)' })",
        "Priority: $Priority"
    )
    if ($NewGroup) {
        $details += "Group ID: $grpId (new group created)"
        $details += "Master Test: master-test-$GroupName.md"
    }
    $details += @(
        "Execution Mode: $(if ($Scripted) { 'scripted' } else { 'manual' })",
        "",
        "Files created:",
        "  - test-case.md (from template — customize steps, expected results, fixtures)",
        "  - project/ (add pristine test fixtures here)",
        "  - expected/ (add post-test expected file state here)"
    )
    if ($Scripted) {
        $details += "  - run.ps1 (skeleton — replace TODO with actual test action)"
    }
    $details += @(
        "",
        "State tracking updated:",
        "  - e2e-test-tracking.md: $e2eId entry added"
    )
    if ($NewGroup) {
        $details += "  - e2e-test-tracking.md: $grpIdForRegistry group entry added (E2E Test Cases table)"
        if ($Workflow) {
            $details += "  - e2e-test-tracking.md: Workflow Milestone Tracking updated ($Workflow += $grpIdForRegistry)"
        }
    }
    $details += @(
        "  - feature-tracking.md: Test Status updated for $featureIdsDisplay",
        "  - master-test-$GroupName.md: If Failed table updated"
    )

    if (-not $OpenInEditor) {
        $details += @(
            "",
            "🚨 NEXT STEPS: Customize test-case.md with exact steps, preconditions,",
            "   expected results, and populate project/ and expected/ with test fixtures.",
            "See: process-framework/guides/03-testing/e2e-acceptance-test-case-customization-guide.md"
        )
    }

    Write-ProjectSuccess -Message "Created E2E acceptance test case $e2eId" -Details $details

    if ($OpenInEditor) {
        Invoke-Item $testCaseFile
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
    Write-ProjectError -Message "Failed to create E2E acceptance test case: $($_.Exception.Message)" -ExitCode 1
}
