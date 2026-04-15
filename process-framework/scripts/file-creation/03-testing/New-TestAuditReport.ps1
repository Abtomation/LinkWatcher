# New-TestAuditReport.ps1
# Creates a new Test Audit Report with an automatically assigned ID
# Uses the central ID registry system and standardized document creation
# Supports three test types: Automated (default), Performance, E2E
# Updates the appropriate tracking file with audit report link
# SC-007: Uses file path as test file identifier (not TE-TST/PD-TST IDs)

<#
.SYNOPSIS
    Creates a new Test Audit Report document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Test Audit Report documents by:
    - Generating a unique document ID (TE-TAR-XXX)
    - Creating a properly formatted audit report file using the type-specific template
    - Updating the ID tracker in the central ID registry
    - Updating the appropriate tracking file:
      - Automated: test-tracking.md (Notes column)
      - Performance: performance-test-tracking.md (Audit Status + Audit Report columns)
      - E2E: e2e-test-tracking.md (Audit Status + Audit Report columns)
    - Providing a complete template for test quality assessment

.PARAMETER FeatureId
    The feature ID being audited (e.g., "0.2.3", "1.1.2")

.PARAMETER TestFilePath
    Relative path to the test file being audited (e.g., "test/automated/unit/test_service.py")

.PARAMETER AuditorName
    Name of the auditor conducting the assessment (default: "AI Agent")

.PARAMETER TestType
    The type of test being audited. Determines template and tracking file routing.
    - "Automated" (default): Unit/integration tests → test-tracking.md, 6 criteria
    - "Performance": Performance benchmarks/scale tests → performance-test-tracking.md, 4 criteria
    - "E2E": E2E acceptance tests → e2e-test-tracking.md, 5 criteria

.PARAMETER Lightweight
    If specified, uses the lightweight template for Tests Approved outcomes.
    Only applies to Automated test type (Performance and E2E have no lightweight variant).
    Only use when ALL evaluation criteria pass with no findings to report.

.PARAMETER Force
    If specified, overwrites an existing audit report file instead of blocking.
    Use this for re-audits where the previous report should be replaced.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    New-TestAuditReport.ps1 -FeatureId "0.2.3" -TestFilePath "test/automated/unit/test_service.py" -AuditorName "AI Agent"

.EXAMPLE
    New-TestAuditReport.ps1 -TestType Performance -FeatureId "2.1.1" -TestFilePath "test/automated/performance/test_benchmark.py" -AuditorName "AI Agent"

.EXAMPLE
    New-TestAuditReport.ps1 -TestType E2E -FeatureId "1.1.1" -TestFilePath "test/e2e-acceptance-testing/templates/powershell-regex-preservation/TE-E2E-001-regex-preserved-on-file-move/test-case.md"

.EXAMPLE
    New-TestAuditReport.ps1 -FeatureId "0.1.1" -TestFilePath "test/automated/unit/test_service.py" -Lightweight

.EXAMPLE
    New-TestAuditReport.ps1 -FeatureId "0.2.3" -TestFilePath "test/automated/unit/test_service.py" -Force
    # Re-audit: overwrites the existing report for this feature/test file combination

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - Determines feature category automatically based on feature ID
    - SC-007: Uses file path as identifier (not PD-TST/TE-TST IDs)

    Script Metadata:
    - Script Type: Document Creation Script
    - Created: 2025-08-07
    - Updated: 2026-04-13 (IMP-495: add -TestType param for Performance/E2E audit support with type-specific templates and tracking file routing)
    - For: Creating Test Audit Report documents from templates
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Automated", "Performance", "E2E")]
    [string]$TestType = "Automated",

    [Parameter(Mandatory = $true)]
    [string]$FeatureId,

    [Parameter(Mandatory = $true)]
    [string]$TestFilePath,

    [Parameter(Mandatory = $false)]
    [string]$AuditorName = "AI Agent",

    [Parameter(Mandatory = $false)]
    [switch]$Lightweight,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
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

# Validate -Lightweight is only used with Automated test type
if ($Lightweight -and $TestType -ne "Automated") {
    Write-ProjectError -Message "-Lightweight is only supported for Automated test type (not $TestType)" -ExitCode 1
}

# Determine output directory and feature category based on TestType
$featureCategory = switch ($TestType) {
    "Performance" { "performance" }
    "E2E" { "e2e" }
    default {
        # Automated: route by feature ID prefix
        switch -Regex ($FeatureId) {
            '^0\.' { "foundation" }
            '^1\.' { "authentication" }
            '^[2-9]\.' { "core-features" }
            default { "foundation" }
        }
    }
}

# Derive a short name from the test file path for document naming
$testFileName = Split-Path $TestFilePath -Leaf
$testFileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($testFileName)

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_id"     = $FeatureId
    "test_file_path" = $TestFilePath
    "auditor"        = $AuditorName
    "audit_date"     = Get-Date -Format "yyyy-MM-dd"
}

# Prepare custom replacements for template
$customReplacements = @{
    "[Feature ID]"       = $FeatureId
    "[Test File ID]"     = $testFileName
    "[Auditor Name]"     = $AuditorName
    "[Audit Date]"       = Get-Date -Format "yyyy-MM-dd"
    "[Feature Category]" = $featureCategory.ToUpper()
}

# Create the document using standardized process
try {
    $kebabFeatureId = ($FeatureId -replace '\.', '-')
    $docName = "audit-report-$kebabFeatureId-$testFileBaseName"

    if (-not $PSCmdlet.ShouldProcess($docName, "Create test audit report")) {
        return
    }

    $templateFile = switch ($TestType) {
        "Performance" { "performance-test-audit-report-template.md" }
        "E2E" { "e2e-test-audit-report-template.md" }
        default { if ($Lightweight) { "test-audit-report-lightweight-template.md" } else { "test-audit-report-template.md" } }
    }
    $conflictAction = if ($Force) { "Overwrite" } else { "Error" }
    $documentId = New-StandardProjectDocument -TemplatePath "process-framework/templates/03-testing/$templateFile" -IdPrefix "TE-TAR" -IdDescription "Test Audit Report for Feature $FeatureId" -DocumentName $docName -DirectoryType $featureCategory -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -ConflictAction $conflictAction -OpenInEditor:$OpenInEditor

    # --- State file updates ---
    $projectRoot = Get-ProjectRoot
    $stateUpdates = @()

    # Build the audit report link (relative from tracking file to audit report)
    $auditFileName = "$(ConvertTo-KebabCase -InputString $docName).md"

    # Route state file updates based on TestType
    if ($TestType -eq "Automated") {
        # --- Automated: Update test-tracking.md Notes column (SC-007: match by file path, not ID) ---
        $testTrackingPath = Join-Path $projectRoot "test/state-tracking/permanent/test-tracking.md"
        $auditRelativePath = "../../audits/$featureCategory/$auditFileName"
        $auditLink = "[$documentId]($auditRelativePath)"

        if (Test-Path $testTrackingPath) {
            $trackingContent = Get-Content $testTrackingPath -Raw -Encoding UTF8

            # Find the row matching the test file name and append audit link to Notes column
            # Uses header-based column lookup (same pattern as Update-MarkdownTable) for safety
            $lines = $trackingContent -split '\r?\n'
            $updatedLines = @()
            $rowUpdated = $false
            $columnIndices = @{}

            foreach ($line in $lines) {
                # Parse table headers to find column indices by name
                if (-not $rowUpdated -and $line -match '^\|.*\|$' -and $columnIndices.Count -eq 0 -and $line -notmatch '^\|[-\s:]+\|$') {
                    $rawHeaders = $line -split '\|'
                    if ($rawHeaders.Count -gt 2) { $rawHeaders = $rawHeaders[1..($rawHeaders.Count-2)] }
                    $headers = $rawHeaders | ForEach-Object { $_.Trim() }
                    for ($j = 0; $j -lt $headers.Count; $j++) {
                        if ($headers[$j] -ne '') { $columnIndices[$headers[$j]] = $j }
                    }
                    # Reset on each new table header (test-tracking has multiple tables)
                    if (-not $columnIndices.ContainsKey("Test File/Case") -or -not $columnIndices.ContainsKey("Notes")) {
                        $columnIndices = @{}
                    }
                }
                # Reset column indices when leaving a table (new section)
                elseif ($line -match '^#' -and $columnIndices.Count -gt 0) {
                    $columnIndices = @{}
                }

                if (-not $rowUpdated -and $columnIndices.Count -gt 0 -and $line -match "^\|.*$([regex]::Escape($testFileName)).*\|") {
                    $rawCols = $line -split '\|'
                    if ($rawCols.Count -gt 2) { $rawCols = $rawCols[1..($rawCols.Count-2)] }
                    $cols = $rawCols | ForEach-Object { $_.Trim() }

                    # Validate column exists and append audit link to Notes
                    $notesIdx = $columnIndices["Notes"]
                    if ($notesIdx -lt $cols.Count) {
                        $existingNotes = $cols[$notesIdx]
                        if ($existingNotes -and $existingNotes -ne "-" -and $existingNotes -ne "") {
                            $cols[$notesIdx] = "$existingNotes; Audit: $auditLink"
                        } else {
                            $cols[$notesIdx] = "Audit: $auditLink"
                        }
                        $line = "| " + ($cols -join " | ") + " |"
                        $rowUpdated = $true
                    }
                }
                $updatedLines += $line
            }

            if ($rowUpdated) {
                $updatedContent = $updatedLines -join "`n"
                if ($PSCmdlet.ShouldProcess($testTrackingPath, "Update test-tracking.md: append audit report link in Notes for $testFileName")) {
                    Set-Content $testTrackingPath $updatedContent -Encoding UTF8
                    $stateUpdates += "test-tracking.md: $testFileName Notes ← $documentId"
                }
            } else {
                Write-Warning "Could not find $testFileName in test-tracking.md (or table missing Test File/Case / Notes columns) — manual update needed"
            }
        } else {
            Write-Warning "Test tracking file not found: $testTrackingPath"
        }
    }
    else {
        # --- Performance / E2E: Update Audit Status and Audit Report columns in dedicated tracking file ---
        $trackingRelPath = switch ($TestType) {
            "Performance" { "test/state-tracking/permanent/performance-test-tracking.md" }
            "E2E" { "test/state-tracking/permanent/e2e-test-tracking.md" }
        }
        $trackingFilePath = Join-Path $projectRoot $trackingRelPath
        $auditRelativePath = "../../audits/$featureCategory/$auditFileName"
        $auditLink = "[$documentId]($auditRelativePath)"

        if (Test-Path $trackingFilePath) {
            $trackingContent = Get-Content $trackingFilePath -Raw -Encoding UTF8

            # Find the row matching the test file name and update Audit Status + Audit Report columns
            $lines = $trackingContent -split '\r?\n'
            $updatedLines = @()
            $rowUpdated = $false
            $columnIndices = @{}

            foreach ($line in $lines) {
                # Parse table headers to find column indices by name
                if (-not $rowUpdated -and $line -match '^\|.*\|$' -and $columnIndices.Count -eq 0 -and $line -notmatch '^\|[-\s:]+\|$') {
                    $rawHeaders = $line -split '\|'
                    if ($rawHeaders.Count -gt 2) { $rawHeaders = $rawHeaders[1..($rawHeaders.Count-2)] }
                    $headers = $rawHeaders | ForEach-Object { $_.Trim() }
                    for ($j = 0; $j -lt $headers.Count; $j++) {
                        if ($headers[$j] -ne '') { $columnIndices[$headers[$j]] = $j }
                    }
                    # Require both audit columns exist in this table
                    if (-not $columnIndices.ContainsKey("Audit Status") -or -not $columnIndices.ContainsKey("Audit Report")) {
                        $columnIndices = @{}
                    }
                }
                # Reset column indices when leaving a table (new section)
                elseif ($line -match '^#' -and $columnIndices.Count -gt 0) {
                    $columnIndices = @{}
                }

                if (-not $rowUpdated -and $columnIndices.Count -gt 0 -and $line -match "^\|.*$([regex]::Escape($testFileName)).*\|") {
                    $rawCols = $line -split '\|'
                    if ($rawCols.Count -gt 2) { $rawCols = $rawCols[1..($rawCols.Count-2)] }
                    $cols = $rawCols | ForEach-Object { $_.Trim() }

                    # Update Audit Status to "🔍 Audit In Progress" and Audit Report to the link
                    $auditStatusIdx = $columnIndices["Audit Status"]
                    $auditReportIdx = $columnIndices["Audit Report"]
                    if ($auditStatusIdx -lt $cols.Count -and $auditReportIdx -lt $cols.Count) {
                        $cols[$auditStatusIdx] = "🔍 Audit In Progress"
                        $cols[$auditReportIdx] = $auditLink
                        $line = "| " + ($cols -join " | ") + " |"
                        $rowUpdated = $true
                    }
                }
                $updatedLines += $line
            }

            if ($rowUpdated) {
                $updatedContent = $updatedLines -join "`n"
                $trackingFileName = Split-Path $trackingFilePath -Leaf
                if ($PSCmdlet.ShouldProcess($trackingFilePath, "Update $trackingFileName: set Audit Status/Report for $testFileName")) {
                    Set-Content $trackingFilePath $updatedContent -Encoding UTF8
                    $stateUpdates += "$trackingFileName`: $testFileName Audit ← $documentId"
                }
            } else {
                $trackingFileName = Split-Path $trackingFilePath -Leaf
                Write-Warning "Could not find $testFileName in $trackingFileName (or table missing Audit Status / Audit Report columns) — manual update needed"
            }
        } else {
            Write-Warning "Tracking file not found: $trackingFilePath"
        }
    }

    # Provide success details
    $variantLabel = switch ($TestType) {
        "Performance" { "Performance (4 criteria)" }
        "E2E" { "E2E (5 criteria)" }
        default { if ($Lightweight) { "Automated Lightweight" } else { "Automated Standard (6 criteria)" } }
    }
    $details = @(
        "Test Type: $TestType",
        "Feature ID: $FeatureId",
        "Test File: $TestFilePath",
        "Auditor: $AuditorName",
        "Category: $featureCategory",
        "Template: $variantLabel"
    )
    if ($stateUpdates.Count -gt 0) {
        $details += ""
        $details += "📊 State file updates:"
        foreach ($update in $stateUpdates) {
            $details += "  - $update"
        }
    }

    # Add next steps if not opening in editor
    if (-not $OpenInEditor) {
        $details += @(
            "",
            "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - EXTENSIVE CUSTOMIZATION REQUIRED 🚨🚨🚨",
            "",
            "⚠️  IMPORTANT: This script creates ONLY a structural template/framework.",
            "⚠️  The generated file is NOT a functional audit report until extensively customized.",
            "⚠️  AI agents MUST follow the Test Audit task process to properly complete the audit.",
            "",
            "📖 MANDATORY PROCESS REFERENCE:",
            "process-framework/tasks/03-testing/test-audit-task.md",
            "🎯 FOCUS AREAS: 'Process' section with six evaluation criteria",
            "",
            "🎯 What you need to complete:",
            "   • Conduct systematic audit against all six quality criteria",
            "   • Document specific findings and recommendations",
            "   • Make clear audit decision (Tests Approved or Needs Update)",
            "   • Update test implementation tracking with audit results",
            "",
            "🚫 DO NOT use the generated file without proper audit completion!",
            "✅ The template provides structure - YOU provide the audit analysis."
        )
    }

    # Auto-append entry to TE-documentation-map.md under the correct audits section
    if ($documentId -or $WhatIfPreference) {
        $teDocMapPath = Join-Path -Path (Get-ProjectRoot) -ChildPath "test/TE-documentation-map.md"
        $sectionHeader = "### ``audits/$featureCategory/``"
        $auditFileName = "$docName.md"
        $relativePath = "audits/$featureCategory/$auditFileName"
        $entryLine = "- [Audit: $FeatureId ($documentId)]($relativePath) - Test quality assessment"

        $updated = Add-DocumentationMapEntry -DocMapPath $teDocMapPath -SectionHeader $sectionHeader -EntryLine $entryLine -CallerCmdlet $PSCmdlet
        if ($updated) {
            $details += "Documentation Map: Updated (TE-documentation-map.md)"
        }
    }

    Write-ProjectSuccess -Message "Created Test Audit Report with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Test Audit Report: $($_.Exception.Message)" -ExitCode 1
}

<#
.NOTES
TESTING CHECKLIST:
Before considering this script complete, test the following:

1. MODULE IMPORT TEST:
   - Run the script from its intended directory
   - Verify Common-ScriptHelpers module loads without errors
   - Test with both PowerShell ISE and PowerShell terminal

2. BASIC FUNCTIONALITY TEST:
   - Create a test audit report with minimal parameters
   - Verify the document is created in the correct feature category directory
   - Check that the ID is assigned correctly and incremented

3. TEMPLATE REPLACEMENT TEST:
   - Open the created document
   - Verify all [Placeholder] values are replaced correctly
   - Check that no template placeholders remain unreplaced

4. FEATURE CATEGORY TEST:
   - Test with feature ID "0.2.3" (should go to foundation/)
   - Test with feature ID "1.1.2" (should go to authentication/)
   - Test with feature ID "2.1.1" (should go to core-features/)

5. METADATA TEST:
   - Verify the document metadata section is populated correctly
   - Check that custom metadata fields are included
   - Ensure metadata format matches expected structure

6. ERROR HANDLING TEST:
   - Test with invalid parameters
   - Test when template file doesn't exist
   - Test when output directory doesn't exist
   - Verify error messages are helpful

EXAMPLE TEST COMMANDS:
# Basic test (SC-007: uses file path)
New-TestAuditReport.ps1 -FeatureId "0.2.3" -TestFilePath "test/automated/unit/test_service.py" -AuditorName "Test Auditor"

# Cleanup
Remove-Item "../../audits/foundation/audit-report-0-2-3-test_service.md" -Force
#>
