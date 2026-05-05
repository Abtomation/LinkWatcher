# New-BugFixState.ps1
# Creates a new Bug Fix State Tracking file for tracking multi-session complex bug fixes
# Uses the central ID registry system and standardized document creation
# Produced and consumed by Bug Fixing task (PF-TSK-007) for Large-effort bugs

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

# Perform standard initialization
Invoke-StandardScriptInitialization


# Soak verification opt-in (PF-PRO-028 v2.0 Pattern B; helper-routed armoring via DocumentManagement.psm1).
# Caller-aware no-arg form: helper resolves this script's path via Get-PSCallStack.
# Idempotent — silently no-ops if already registered.
Register-SoakScript

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

# Build absolute template path
$projectRoot = Get-ProjectRoot
$processFrameworkDir = Join-Path $projectRoot "process-framework"
$templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates\06-maintenance\bug-fix-state-tracking-template.md"

try {
    $idDesc = "Bug fix state tracking for ${BugId}: ${BugTitle}"
    $stateId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-STA" -IdDescription $idDesc -DocumentName $BugTitle -OutputDirectory "doc/state-tracking/temporary" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $customFileName -OpenInEditor:$OpenInEditor

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
}
catch {
    Write-ProjectError -Message "Failed to create bug fix state tracking file: $($_.Exception.Message)" -ExitCode 1
}
