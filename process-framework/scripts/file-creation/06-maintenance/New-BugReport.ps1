# New-BugReport.ps1
# Creates a new bug report with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new bug report with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates bug reports by:
    - Generating a unique bug ID (BUG-XXX)
    - Adding the bug to the appropriate priority table in bug-tracking.md
    - Updating bug statistics automatically
    - Providing a complete template for bug tracking

.PARAMETER Title
    The title/summary of the bug

.PARAMETER Description
    Detailed description of the bug

.PARAMETER DiscoveredBy
    How the bug was discovered (TestAudit, CodeReview, UserReport, Testing, E2ETesting, Monitoring, Development, FeatureImplementation, Refactoring)

.PARAMETER Severity
    Bug severity level (Critical, High, Medium, Low)

.PARAMETER Component
    The component/area where the bug was found

.PARAMETER ReproductionSteps
    Steps to reproduce the bug (optional)

.PARAMETER ExpectedBehavior
    What should happen (optional)

.PARAMETER ActualBehavior
    What actually happens (optional)

.PARAMETER Environment
    Environment where bug was found (Development, Testing, Production)

.PARAMETER Evidence
    Evidence or logs related to the bug (optional)

.PARAMETER RelatedFeature
    Related feature ID if applicable (optional)

.PARAMETER PreTriaged
    When set, creates the bug directly in 🔍 Needs Fix status instead of 🆕 Needs Triage.
    Use when the reporter already has complete root cause analysis and scope.
    Requires -Scope to be specified.

.PARAMETER Scope
    Bug scope description (e.g., "Single file", "Multi-module"). Required when -PreTriaged is set.

.EXAMPLE
    New-BugReport.ps1 -Title "Login fails with special characters" -Description "Users cannot login when password contains special characters" -DiscoveredBy "TestAudit" -Severity "High" -Component "Authentication"

.EXAMPLE
    New-BugReport.ps1 -Title "Memory leak in user service" -Description "Memory usage increases over time" -DiscoveredBy "CodeReview" -Severity "Critical" -Component "Performance" -Environment "Production"

.EXAMPLE
    New-BugReport.ps1 -Title "Parser skips backtick paths" -Description "Markdown parser ignores backtick-delimited paths" -DiscoveredBy "CodeReview" -Severity "Medium" -Component "Parsers" -PreTriaged -Scope "Single parser module" -RelatedFeature "2.1.1"

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Adds bugs to appropriate priority tables based on severity
    - Updates statistics automatically
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateLength(5, 100)]
    [Alias("BugTitle")]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [ValidateLength(10, 500)]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [ValidateSet("TestAudit", "Testing", "E2ETesting", "CodeReview", "UserReport", "Monitoring", "Development", "FeatureImplementation", "Refactoring")]
    [string]$DiscoveredBy,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Critical", "High", "Medium", "Low")]
    [Alias("Priority")]
    [string]$Severity,

    [Parameter(Mandatory = $true)]
    [ValidateLength(3, 50)]
    [string]$Component,

    [Parameter(Mandatory = $false)]
    [string]$ReproductionSteps = "",

    [Parameter(Mandatory = $false)]
    [string]$ExpectedBehavior = "",

    [Parameter(Mandatory = $false)]
    [string]$ActualBehavior = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Development", "Testing", "Staging", "Production")]
    [string]$Environment = "Development",

    [Parameter(Mandatory = $false)]
    [string]$Evidence = "",

    [Parameter(Mandatory = $false)]
    [Alias("AffectedFeature")]
    [string]$RelatedFeature = "",

    [Parameter(Mandatory = $false)]
    [string]$Dims = "",

    [Parameter(Mandatory = $false)]
    [string]$Workflows = "",

    [Parameter(Mandatory = $false)]
    [switch]$PreTriaged,

    [Parameter(Mandatory = $false)]
    [string]$Scope = ""
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
Invoke-StandardScriptInitialization

# Validate -PreTriaged requires -Scope
if ($PreTriaged -and -not $Scope) {
    Write-ProjectError -Message "-PreTriaged requires -Scope to be specified." -ExitCode 1
}

# Get current date in YYYY-MM-DD format
$currentDate = Get-Date -Format "yyyy-MM-dd"

# Path to bug tracking file - use project root for reliable path resolution
$ProjectRoot = Get-ProjectRoot
$BugTrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/bug-tracking.md"

if (-not (Test-Path $BugTrackingFile)) {
    Write-ProjectError -Message "Bug tracking file not found: $BugTrackingFile" -ExitCode 1
}

# Read current content
$Content = Get-Content -Path $BugTrackingFile -Raw -Encoding UTF8

# Early WhatIf check — exit before consuming an ID from the registry
if (-not $PSCmdlet.ShouldProcess($BugTrackingFile, "Add new bug report '$Title'")) {
    return
}

# Generate unique bug ID using the central registry
$BugId = New-ProjectId -Prefix "PD-BUG" -Description "Bug report: $Title"

Write-Host "🐛 Creating bug report: $BugId" -ForegroundColor Yellow
Write-Host "📝 Title: $Title" -ForegroundColor Cyan

# Determine which table to add the bug to based on severity
$TableSection = switch ($Severity) {
    "Critical" { "### Critical Bugs" }
    "High" { "### High Priority Bugs" }
    "Medium" { "### Medium Priority Bugs" }
    "Low" { "### Low Priority Bugs" }
}

# Priority uses text format (Critical/High/Medium/Low) — same as technical-debt-tracking
$PriorityText = $Severity

# Build Notes field: Source first, then component/environment, then optional details
$NotesParts = @("Source: $DiscoveredBy", "Environment: $Environment", "Component: $Component")
if ($ReproductionSteps -ne "") { $NotesParts += "Repro: $ReproductionSteps" }
if ($ExpectedBehavior -ne "") { $NotesParts += "Expected: $ExpectedBehavior" }
if ($ActualBehavior -ne "") { $NotesParts += "Actual: $ActualBehavior" }
if ($Evidence -ne "") { $NotesParts += "Evidence: $Evidence" }
$NotesField = $NotesParts -join "; "

# Escape pipe characters in user-supplied text to prevent markdown table corruption
$Title = $Title -replace '\|', '\|'
$Description = $Description -replace '\|', '\|'
$NotesField = $NotesField -replace '\|', '\|'

# Related feature field
$RelatedFeatureField = if ($RelatedFeature -ne "") { $RelatedFeature } else { "N/A" }

# Workflows field
$WorkflowsField = if ($Workflows -ne "") { $Workflows } else { "" }

# Dims field
$DimsField = if ($Dims -ne "") { $Dims } else { "" }

# Determine status and scope based on -PreTriaged
$BugStatus = if ($PreTriaged) { "🔍 Needs Fix" } else { "🆕 Needs Triage" }
$ScopeField = if ($Scope -ne "") { $Scope -replace '\|', '\|' } else { "" }

# Create table row — 11-column format: ID | Title | Status | Priority | Scope | Reported | Description | Related Feature | Workflows | Dims | Notes
$TableRow = "| $BugId | $Title | $BugStatus | $PriorityText | $ScopeField | $currentDate | $Description | $RelatedFeatureField | $WorkflowsField | $DimsField | $NotesField |"

# Find the appropriate table and replace the "No bugs" message
$NobugsPattern = switch ($Severity) {
    "Critical" { "\| _No critical bugs currently active_ \|" }
    "High" { "\| _No high priority bugs currently active_ \|" }
    "Medium" { "\| _No medium priority bugs currently active_ \|" }
    "Low" { "\| _No low priority bugs currently active_ \|" }
}

# Replace the "no bugs" message with the new bug entry
$UpdatedContent = $Content -replace $NobugsPattern, $TableRow

# If the pattern wasn't found (table already has bugs), add to the end of the table
if ($UpdatedContent -eq $Content) {
    # Find the specific section and add the bug after the last existing bug row
    $SectionPattern = "($TableSection.*?)(?=^#{2,3}\s|\z)"
    $SectionMatch = [regex]::Match($UpdatedContent, $SectionPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)

    if ($SectionMatch.Success) {
        $SectionContent = $SectionMatch.Groups[1].Value

        # Find the last table row in this section (line that starts with | and contains bug data)
        $TableRowPattern = "(\| PD-BUG-\d+.*\|)(?=\s*$)"
        $TableRowMatches = [regex]::Matches($SectionContent, $TableRowPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)

        if ($TableRowMatches.Count -gt 0) {
            # Get the last table row
            $LastRowMatch = $TableRowMatches[$TableRowMatches.Count - 1]
            $InsertPosition = $SectionMatch.Index + $LastRowMatch.Index + $LastRowMatch.Length
            $UpdatedContent = $UpdatedContent.Substring(0, $InsertPosition) + "`n$TableRow" + $UpdatedContent.Substring($InsertPosition)
        }
        else {
            # No PD-BUG rows found — insert after the table header separator (| --- | ... |)
            $HeaderSepPattern = "(\| -+\s*(?:\| -+\s*)+\|)"
            $HeaderSepMatches = [regex]::Matches($SectionContent, $HeaderSepPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
            if ($HeaderSepMatches.Count -gt 0) {
                $SepMatch = $HeaderSepMatches[0]
                $InsertPosition = $SectionMatch.Index + $SepMatch.Index + $SepMatch.Length
                $UpdatedContent = $UpdatedContent.Substring(0, $InsertPosition) + "`n$TableRow" + $UpdatedContent.Substring($InsertPosition)
            }
        }
    }
}

# Update statistics - count all active bug rows (everything before "## Closed Bugs" section)
# Active statuses: 🆕 Needs Triage, 🔍 Needs Fix, 🟡 In Progress, 👀 Needs Review, 🔄 Reopened
$ClosedSectionIndex = $UpdatedContent.IndexOf("## Closed Bugs")
$ActiveSection = if ($ClosedSectionIndex -gt 0) { $UpdatedContent.Substring(0, $ClosedSectionIndex) } else { $UpdatedContent }

$ActiveCount = ([regex]::Matches($ActiveSection, '\| PD-BUG-\d+')).Count
$UpdatedContent = [regex]::Replace($UpdatedContent, '(\*\*Total Active Bugs\*\*: )\d+', "`${1}$ActiveCount")

# Update priority-specific counts - count all active bug rows by priority code
$CriticalCount = ([regex]::Matches($ActiveSection, '\| PD-BUG-\d+.*\| Critical \|')).Count
$HighCount = ([regex]::Matches($ActiveSection, '\| PD-BUG-\d+.*\| High \|')).Count
$MediumCount = ([regex]::Matches($ActiveSection, '\| PD-BUG-\d+.*\| Medium \|')).Count
$LowCount = ([regex]::Matches($ActiveSection, '\| PD-BUG-\d+.*\| Low \|')).Count

$UpdatedContent = [regex]::Replace($UpdatedContent, '(\*\*Critical\*\*: )\d+', "`${1}$CriticalCount")
$UpdatedContent = [regex]::Replace($UpdatedContent, '(\*\*High\*\*: )\d+', "`${1}$HighCount")
$UpdatedContent = [regex]::Replace($UpdatedContent, '(\*\*Medium\*\*: )\d+', "`${1}$MediumCount")
$UpdatedContent = [regex]::Replace($UpdatedContent, '(\*\*Low\*\*: )\d+', "`${1}$LowCount")

# Update source analysis based on DiscoveredBy parameter
$SourceMap = @{
    "TestAudit"             = "Test Audit"
    "Testing"               = "Testing"
    "E2ETesting"            = "E2E Testing"
    "CodeReview"            = "Code Review"
    "FeatureImplementation" = "Development"
    "Development"           = "Development"
    "UserReport"            = "User Reports"
    "Monitoring"            = "Monitoring"
    "Refactoring"           = "Code Refactoring"
}

$SourceCategory = $SourceMap[$DiscoveredBy]
if ($SourceCategory) {
    $CurrentSourceCount = [regex]::Match($UpdatedContent, "\*\*$SourceCategory\*\*: (\d+)").Groups[1].Value
    $NewSourceCount = [int]$CurrentSourceCount + 1
    $UpdatedContent = [regex]::Replace($UpdatedContent, "(\*\*$SourceCategory\*\*: )\d+", "`${1}$NewSourceCount")
}

try {
    # Write updated content
    Set-Content -Path $BugTrackingFile -Value $UpdatedContent -NoNewline -Encoding UTF8

    $details = @(
        "Severity: $Severity",
        "Component: $Component",
        "Discovered By: $DiscoveredBy",
        "Environment: $Environment"
    )

    if ($RelatedFeature -ne "") {
        $details += "Related Feature: $RelatedFeature"
    }

    Write-ProjectSuccess -Message "Created bug report with ID: $BugId" -Details $details

    Write-Host ""
    Write-Host "🔄 Next Steps:" -ForegroundColor Yellow
    if ($PreTriaged) {
        Write-Host "  1. Bug created in Triaged status — skip triage, proceed to Bug Fixing task" -ForegroundColor White
        Write-Host "  2. Use Update-BugStatus.ps1 to transition to In Progress when work begins" -ForegroundColor White
        Write-Host ""
        Write-Host "💡 Tip: Use 'Bug Fixing' task (PF-TSK-007) to fix this bug" -ForegroundColor Cyan
    } else {
        Write-Host "  1. Run Bug Triage task to evaluate and prioritize this bug" -ForegroundColor White
        Write-Host "  2. Bug will be assigned priority and severity during triage" -ForegroundColor White
        Write-Host "  3. After triage, bug can be assigned for fixing" -ForegroundColor White
        Write-Host ""
        Write-Host "💡 Tip: Use 'Bug Triage' task to process all reported bugs" -ForegroundColor Cyan
    }
}
catch {
    Write-ProjectError -Message "Failed to create bug report: $($_.Exception.Message)" -ExitCode 1
}
