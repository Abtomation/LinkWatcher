<#
.SYNOPSIS
Creates a new Bug Fix State Tracking file for a multi-session complex bug fix.

.DESCRIPTION
Uses the central ID registry system and standardized document creation.
Produced and consumed by Bug Fixing task (PF-TSK-007) for Large-effort bugs.

.PARAMETER BugId
ID of the bug being fixed (e.g. "PD-BUG-042"). Stamped into the bug_id frontmatter field and the
document body.

.PARAMETER BugTitle
Title of the bug. Drives the document title and the kebab-case filename.

.PARAMETER Severity
Bug severity. Valid values: "Critical", "High", "Medium" (default), "Low". Stamped into
frontmatter and the body severity row.

.PARAMETER AffectedFeature
Feature ID the bug affects (e.g. "1.2.3"). Omitted leaves the template's placeholder.

.PARAMETER EstimatedSessions
Expected number of sessions the fix will span. Defaults to 2; this template is for Large-effort
bugs, so values below 2 are unusual.

.PARAMETER Dims
Development dimension abbreviations relevant to the fix (e.g. "SE DI"). Valid abbreviations:
AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI — see the Development Dimensions Guide.

.PARAMETER OpenInEditor
Opens the created state file in the configured editor after creation.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$BugId,

    [Parameter(Mandatory = $true)]
    [string]$BugTitle,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Critical", "High", "Medium", "Low")]
    [string]$Severity = "Medium",

    [Parameter(Mandatory = $false)]
    [string]$AffectedFeature = "",

    [Parameter(Mandatory = $false)]
    [int]$EstimatedSessions = 2,

    [Parameter(Mandatory = $false)]
    [string]$Dims = "",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Init, soak opt-in, the New-StandardProjectDocument call, try/catch, and the error report are
# owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This script keeps only
# its param block (above), the bug-fix-state-specific data, and the success report.

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "bug_id"   = $BugId
    "bug_name" = ConvertTo-KebabCase -InputString $BugTitle
    "severity" = $Severity
}

# Prepare custom replacements
$currentDate = Get-Date -Format "yyyy-MM-dd"
$customReplacements = @{
    "[Bug ID]"                              = $BugId
    "[Bug Title]"                           = $BugTitle
    "[Critical / High / Medium / Low]"      = $Severity
    "[2 / 3+]"                              = "$EstimatedSessions"
    "[YYYY-MM-DD]"                          = $currentDate
}

# Add affected feature if provided
if ($AffectedFeature -ne "") {
    $customReplacements["[Feature ID] — [Feature Name]"] = $AffectedFeature
}

# Add affected dimensions if provided
if ($Dims -ne "") {
    $additionalMetadataFields["affected_dimensions"] = $Dims
}

# Create the document using standardized process with custom filename pattern
$kebabBugId = $BugId.ToLower().Replace(" ", "-")
$customFileName = "bug-fix-state-$kebabBugId.md"

# Build absolute template path (Phase 5.5: configurable via paths.process_framework)
$processFrameworkDir = Get-ProcessFrameworkPath
$templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates/06-maintenance/bug-fix-state-tracking-template.md"

$idDesc = "Bug fix state tracking for ${BugId}: ${BugTitle}"
$stContext = Get-StateTrackingContext
$outputDir = "$($stContext.StateTrackingRelative)/temporary"
$stateId = New-FrameworkDocument -TemplatePath $templatePath -IdPrefix "PF-STA" -IdDescription $idDesc -DocumentName $BugTitle -OutputDirectory $outputDir -Replacements $customReplacements -Metadata $additionalMetadataFields -FileNamePattern $customFileName -Label "bug fix state tracking file" -OpenInEditor:$OpenInEditor

$details = @(
    "",
    "   Bug: $BugId — $BugTitle",
    "   Severity: $Severity",
    "   Estimated Sessions: $EstimatedSessions",
    "Customization required — see Bug Fixing task (PF-TSK-007). Populate as you progress:",
    "  1. Root Cause Analysis (after Step 9 investigation)",
    "  2. Fix Approach (before Step 10 implementation)",
    "  3. Implementation Progress (during Step 11)",
    "  4. Validation Status (after Step 13 testing)",
    "  5. Session Log (end of each session — Step 17)"
)

Write-ProjectSuccess -Message "Created bug fix state tracking file with ID: $stateId" -Details $details
