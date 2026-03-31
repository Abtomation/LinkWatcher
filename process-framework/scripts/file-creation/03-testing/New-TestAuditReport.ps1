# New-TestAuditReport.ps1
# Creates a new Test Audit Report with an automatically assigned ID
# Uses the central ID registry system and standardized document creation
# Updates test-tracking.md: appends audit report link in Notes column for the target test file
# SC-007: Uses file path as test file identifier (not TE-TST/PD-TST IDs)

<#
.SYNOPSIS
    Creates a new Test Audit Report document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Test Audit Report documents by:
    - Generating a unique document ID (TE-TAR-XXX)
    - Creating a properly formatted audit report file
    - Updating the ID tracker in the central ID registry
    - Updating test-tracking.md: appends audit report link in Notes column for the target test file
    - Providing a complete template for test quality assessment

.PARAMETER FeatureId
    The feature ID being audited (e.g., "0.2.3", "1.1.2")

.PARAMETER TestFilePath
    Relative path to the test file being audited (e.g., "test/automated/unit/test_service.py")

.PARAMETER AuditorName
    Name of the auditor conducting the assessment (default: "AI Agent")

.PARAMETER Lightweight
    If specified, uses the lightweight template for Tests Approved outcomes.
    Only use when ALL six evaluation criteria pass with no findings to report.
    Any other audit status (Approved with Dependencies, Needs Update, Tests Incomplete) must use the full template.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-TestAuditReport.ps1 -FeatureId "0.2.3" -TestFilePath "test/automated/unit/test_service.py" -AuditorName "AI Agent"

.EXAMPLE
    .\New-TestAuditReport.ps1 -FeatureId "1.1.2" -TestFilePath "test/automated/integration/test_auth.py" -AuditorName "QA Engineer" -OpenInEditor

.EXAMPLE
    .\New-TestAuditReport.ps1 -FeatureId "0.1.1" -TestFilePath "test/automated/unit/test_service.py" -Lightweight

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
    - Updated: 2026-03-27 (IMP-231: fix filename mismatch + Notes column; IMP-240: lightweight template variant)
    - For: Creating Test Audit Report documents from templates
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureId,

    [Parameter(Mandatory = $true)]
    [string]$TestFilePath,

    [Parameter(Mandatory = $false)]
    [string]$AuditorName = "AI Agent",

    [Parameter(Mandatory = $false)]
    [switch]$Lightweight,

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

# Determine feature category based on feature ID
$featureCategory = switch -Regex ($FeatureId) {
    '^0\.' { "foundation" }
    '^1\.' { "authentication" }
    '^[2-9]\.' { "core-features" }
    default { "foundation" }
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

    $templateFile = if ($Lightweight) { "test-audit-report-lightweight-template.md" } else { "test-audit-report-template.md" }
    $documentId = New-StandardProjectDocument -TemplatePath "process-framework/templates/03-testing/$templateFile" -IdPrefix "TE-TAR" -IdDescription "Test Audit Report for Feature $FeatureId" -DocumentName $docName -DirectoryType $featureCategory -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # --- State file updates ---
    $projectRoot = Get-ProjectRoot
    $stateUpdates = @()

    # 1. Update test-tracking.md: link audit report for the test file (SC-007: match by file path, not ID)
    $testTrackingPath = Join-Path $projectRoot "test/state-tracking/permanent/test-tracking.md"
    if (Test-Path $testTrackingPath) {
        $trackingContent = Get-Content $testTrackingPath -Raw -Encoding UTF8

        # Build relative path from test-tracking.md to the audit report
        # Use kebab-case to match the actual filename created by New-StandardProjectDocument
        $auditFileName = "$(ConvertTo-KebabCase -InputString $docName).md"
        $auditRelativePath = "../../audits/$featureCategory/$auditFileName"
        $auditLink = "[$documentId]($auditRelativePath)"

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

    # Provide success details
    $variantLabel = if ($Lightweight) { "Lightweight" } else { "Standard" }
    $details = @(
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
./New-TestAuditReport.ps1 -FeatureId "0.2.3" -TestFilePath "test/automated/unit/test_service.py" -AuditorName "Test Auditor"

# Cleanup
Remove-Item "../../audits/foundation/audit-report-0-2-3-test_service.md" -Force
#>
