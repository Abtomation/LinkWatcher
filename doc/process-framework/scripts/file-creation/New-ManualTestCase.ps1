# New-ManualTestCase.ps1
# Creates a new manual test case directory structure with an automatically assigned MT-NNN ID
# Creates test-case.md from template, project/ and expected/ subdirectories
# Updates master test file's "If Failed" table, test-tracking.md, and feature-tracking.md

<#
.SYNOPSIS
    Creates a new manual test case with an automatically assigned MT-NNN ID.

.DESCRIPTION
    This PowerShell script generates manual test case directory structures by:
    - Generating a unique test case ID (MT-NNN) from the central ID registry
    - Creating the directory MT-NNN-[name]/ with project/ and expected/ subdirectories
    - Copying and customizing test-case.md from the manual test case template
    - Adding the test case to the group's master test "If Failed" table
    - Adding a new entry to test-tracking.md via Add-TestImplementationEntry
    - Updating feature-tracking.md Test Status via Update-FeatureTrackingStatus

.PARAMETER TestCaseName
    Short descriptive name for the test case (used in directory name, e.g., "single-file-rename")

.PARAMETER GroupName
    Name of the test group this case belongs to (e.g., "basic-file-operations").
    Must match an existing group directory under test/manual-testing/templates/.

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

.PARAMETER OpenInEditor
    If specified, opens the created test-case.md in the default editor

.EXAMPLE
    .\New-ManualTestCase.ps1 -TestCaseName "single-file-rename" -GroupName "basic-file-operations" -FeatureId "1.1.1" -FeatureName "File System Monitoring" -Source "Test Spec PF-TSP-038" -Description "Verify single file rename updates all references"

.EXAMPLE
    .\New-ManualTestCase.ps1 -TestCaseName "single-file-rename" -GroupName "basic-file-operations" -FeatureId "1.1.1" -FeatureName "File System Monitoring" -NewGroup -Source "Test Spec PF-TSP-038" -Description "Verify single file rename updates all references"

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new MT ID assignments
    - Creates the test group directory if -NewGroup is specified
    - Updates master test, test-tracking.md, and feature-tracking.md automatically
    - The test-case.md, project/, and expected/ contents must be customized after creation

    Created: 2026-03-15
    Version: 1.0
    Task: Manual Test Case Creation (PF-TSK-069)
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$TestCaseName,

    [Parameter(Mandatory=$true)]
    [string]$GroupName,

    [Parameter(Mandatory=$true)]
    [string]$FeatureId,

    [Parameter(Mandatory=$true)]
    [string]$FeatureName,

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
    [switch]$OpenInEditor
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

try {
    $projectRoot = Get-ProjectRoot
    $timestamp = Get-ProjectTimestamp -Format "Date"

    # --- 1. Assign MT ID from registry ---
    $idRegistryPath = Join-Path $projectRoot "doc/id-registry.json"
    $idRegistry = Get-Content $idRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json

    $mtPrefix = $idRegistry.prefixes.MT
    $mtId = "MT-{0:D3}" -f $mtPrefix.nextAvailable

    # Increment the counter
    $mtPrefix.nextAvailable = $mtPrefix.nextAvailable + 1
    if ($PSCmdlet.ShouldProcess($idRegistryPath, "Update MT ID counter")) {
        $idRegistry | ConvertTo-Json -Depth 10 | Set-Content $idRegistryPath -Encoding UTF8
    }

    Write-Verbose "Assigned test case ID: $mtId"

    # --- 2. Resolve paths ---
    $manualTestingRoot = Join-Path $projectRoot "test/manual-testing/templates"
    $groupDir = Join-Path $manualTestingRoot $GroupName
    $testCaseDir = Join-Path $groupDir "$mtId-$TestCaseName"
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

        # Assign MT-GRP ID
        $grpPrefix = $idRegistry.prefixes.'MT-GRP'
        $grpId = "MT-GRP-{0:D2}" -f $grpPrefix.nextAvailable
        $grpPrefix.nextAvailable = $grpPrefix.nextAvailable + 1
        if ($PSCmdlet.ShouldProcess($idRegistryPath, "Update MT-GRP ID counter")) {
            $idRegistry | ConvertTo-Json -Depth 10 | Set-Content $idRegistryPath -Encoding UTF8
        }

        Write-Verbose "Assigned group ID: $grpId"

        # Create master test from template
        $masterTemplatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/manual-master-test-template.md"
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
            $masterContent = $masterContent -replace '\[FEATURE-ID\]', $FeatureId
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

    # --- 4. Create test case directory structure ---
    if ($PSCmdlet.ShouldProcess($testCaseDir, "Create test case directory structure")) {
        New-Item -ItemType Directory -Path $testCaseDir -Force | Out-Null
        New-Item -ItemType Directory -Path $projectDir -Force | Out-Null
        New-Item -ItemType Directory -Path $expectedDir -Force | Out-Null

        # Add .gitkeep to empty directories so git tracks them
        Set-Content (Join-Path $projectDir ".gitkeep") "" -Encoding UTF8
        Set-Content (Join-Path $expectedDir ".gitkeep") "" -Encoding UTF8

        Write-Verbose "Created directory structure: $testCaseDir"
    }

    # --- 5. Create test-case.md from template ---
    $testCaseTemplatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/manual-test-case-template.md"
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
        $testCaseContent = $testCaseContent -replace '\[MT-NNN\]', $mtId
        $testCaseContent = $testCaseContent -replace '\[TITLE\]', ($TestCaseName -replace '-', ' ')
        $testCaseContent = $testCaseContent -replace '\[GROUP-NAME\]', $GroupName
        $testCaseContent = $testCaseContent -replace '\[FEATURE-ID\]', $FeatureId
        $testCaseContent = $testCaseContent -replace '\[FEATURE-NAME\]', $FeatureName
        $testCaseContent = $testCaseContent -replace '\[P0 / P1 / P2 / P3\]', $Priority
        $testCaseContent = $testCaseContent -replace '\[YYYY-MM-DD\]', $timestamp
        if ($Source) {
            $testCaseContent = $testCaseContent -replace '\[Test Spec / Bug Report / Refactoring Plan\] — \[SOURCE-ID\]', $Source
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
        $testCaseRelPath = "$mtId-$TestCaseName/test-case.md"
        $displayDescription = if ($Description) { $Description } else { ($TestCaseName -replace '-', ' ') }
        $newRow = "| $mtId | [$testCaseRelPath]($testCaseRelPath) | $displayDescription |"

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
                if ($line -match '\[MT-001\].*\[Brief description\]' -or $line -match '\[MT-002\].*\[Brief description\]' -or $line -match '\[MT-003\].*\[Brief description\]') {
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
        }
    } else {
        Write-Warning "Master test file not found: $masterTestFile. Skipping master test update."
    }

    # --- 7. Update test-tracking.md ---
    $testTrackingPath = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/test-tracking.md"
    if (Test-Path $testTrackingPath) {
        $trackingContent = Get-Content $testTrackingPath -Raw -Encoding UTF8

        # Build relative path from test-tracking.md to the test case
        $testCaseRelativePath = "../../../../test/manual-testing/templates/$GroupName/$mtId-$TestCaseName/test-case.md"
        $trackingNotes = if ($Description) { $Description } else { ($TestCaseName -replace '-', ' ') }

        $updatedContent = Add-TestImplementationEntry `
            -Content $trackingContent `
            -TestFileId $mtId `
            -FeatureId $FeatureId `
            -TestFilePath $testCaseRelativePath `
            -Status "📋 Case Created" `
            -TestType "Manual Case" `
            -TestCasesCount "" `
            -LastExecuted "—" `
            -Notes $trackingNotes

        if ($PSCmdlet.ShouldProcess($testTrackingPath, "Add manual test entry to test-tracking.md")) {
            Set-Content $testTrackingPath $updatedContent -Encoding UTF8
            Write-Verbose "Updated test-tracking.md with $mtId"
        }
    } else {
        Write-Warning "Test tracking file not found: $testTrackingPath"
    }

    # --- 8. Update feature-tracking.md Test Status ---
    $featureTrackingPath = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md"
    if (Test-Path $featureTrackingPath) {
        # Update Test Status — if it was "🔧 Automated Only", change to the appropriate status
        try {
            Update-FeatureTrackingStatus `
                -FeatureId $FeatureId `
                -Status "🟡 In Progress" `
                -StatusColumn "Test Status"
            Write-Verbose "Updated feature-tracking.md Test Status for $FeatureId"
        } catch {
            Write-Warning "Could not update feature-tracking.md: $($_.Exception.Message)"
        }
    }

    # --- Success output ---
    $details = @(
        "Test Case ID: $mtId",
        "Directory: test/manual-testing/templates/$GroupName/$mtId-$TestCaseName/",
        "Feature: $FeatureId — $FeatureName",
        "Priority: $Priority"
    )
    if ($NewGroup) {
        $details += "Group ID: $grpId (new group created)"
        $details += "Master Test: master-test-$GroupName.md"
    }
    $details += @(
        "",
        "Files created:",
        "  - test-case.md (from template — customize steps, expected results, fixtures)",
        "  - project/ (add pristine test fixtures here)",
        "  - expected/ (add post-test expected file state here)",
        "",
        "State tracking updated:",
        "  - test-tracking.md: $mtId entry added",
        "  - feature-tracking.md: Test Status updated",
        "  - master-test-$GroupName.md: If Failed table updated"
    )

    if (-not $OpenInEditor) {
        $details += @(
            "",
            "🚨 NEXT STEPS: Customize test-case.md with exact steps, preconditions,",
            "   expected results, and populate project/ and expected/ with test fixtures.",
            "See: doc/process-framework/guides/guides/03-testing/manual-test-case-customization-guide.md"
        )
    }

    Write-ProjectSuccess -Message "Created manual test case $mtId" -Details $details

    if ($OpenInEditor) {
        Invoke-Item $testCaseFile
    }
}
catch {
    Write-ProjectError -Message "Failed to create manual test case: $($_.Exception.Message)" -ExitCode 1
}
