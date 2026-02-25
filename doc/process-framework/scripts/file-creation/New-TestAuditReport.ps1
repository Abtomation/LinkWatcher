# New-TestAuditReport.ps1
# Creates a new Test Audit Report with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Test Audit Report document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Test Audit Report documents by:
    - Generating a unique document ID (PF-TAR-XXX)
    - Creating a properly formatted audit report file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for test quality assessment

.PARAMETER FeatureId
    The feature ID being audited (e.g., "0.2.3", "1.1.2")

.PARAMETER TestFileId
    The test file ID being audited (e.g., "PD-TST-001")

.PARAMETER AuditorName
    Name of the auditor conducting the assessment (default: "AI Agent")

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-TestAuditReport.ps1 -FeatureId "0.2.3" -TestFileId "PD-TST-001" -AuditorName "AI Agent"

.EXAMPLE
    .\New-TestAuditReport.ps1 -FeatureId "1.1.2" -TestFileId "PD-TST-015" -AuditorName "QA Engineer" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - Determines feature category automatically based on feature ID

    Script Metadata:
    - Script Type: Document Creation Script
    - Created: 2025-08-07
    - For: Creating Test Audit Report documents from templates
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureId,

    [Parameter(Mandatory = $true)]
    [string]$TestFileId,

    [Parameter(Mandatory = $false)]
    [string]$AuditorName = "AI Agent",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Determine feature category based on feature ID
$featureCategory = switch -Regex ($FeatureId) {
    '^0\.' { "foundation" }
    '^1\.' { "authentication" }
    '^[2-9]\.' { "core-features" }
    default { "foundation" }
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_id"   = $FeatureId
    "test_file_id" = $TestFileId
    "auditor"      = $AuditorName
    "audit_date"   = Get-Date -Format "yyyy-MM-dd"
}

# Prepare custom replacements for template
$customReplacements = @{
    "[Feature ID]"       = $FeatureId
    "[Test File ID]"     = $TestFileId
    "[Auditor Name]"     = $AuditorName
    "[Audit Date]"       = Get-Date -Format "yyyy-MM-dd"
    "[Feature Category]" = $featureCategory.ToUpper()
}

# Create the document using standardized process
try {
    # Use DirectoryType for ID registry-based directory resolution
    $documentId = New-StandardProjectDocument -TemplatePath "doc/process-framework/templates/templates/test-audit-report-template.md" -IdPrefix "PF-TAR" -IdDescription "Test Audit Report for Feature $FeatureId" -DocumentName "audit-report-$FeatureId-$TestFileId" -DirectoryType $featureCategory -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Feature ID: $FeatureId",
        "Test File ID: $TestFileId",
        "Auditor: $AuditorName",
        "Category: $featureCategory"
    )

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
            "   doc/process-framework/tasks/03-testing/test-audit-task.md",
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
# Basic test
./New-TestAuditReport.ps1 -FeatureId "0.2.3" -TestFileId "PD-TST-001" -AuditorName "Test Auditor"

# Verify created document
Get-Content "../../test-audits/../../test-audits/../../../../test-audits/doc/process-framework/test-audits/foundation/audit-report-0.2.3-PD-TST-001.md" | Select-Object -First 20

# Cleanup
Remove-Item "../../test-audits/../../test-audits/../../../../test-audits/doc/process-framework/test-audits/foundation/audit-report-0.2.3-PD-TST-001.md" -Force
#>
