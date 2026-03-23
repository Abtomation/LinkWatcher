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
    How the bug was discovered (Test Audit, Code Review, User Report, etc.)

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

.EXAMPLE
    .\New-BugReport.ps1 -Title "Login fails with special characters" -Description "Users cannot login when password contains special characters" -DiscoveredBy "Test Audit" -Severity "High" -Component "Authentication"

.EXAMPLE
    .\New-BugReport.ps1 -Title "Memory leak in user service" -Description "Memory usage increases over time" -DiscoveredBy "Code Review" -Severity "Critical" -Component "Performance" -Environment "Production"

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
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [ValidateLength(10, 500)]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [ValidateSet("TestAudit", "Testing", "E2ETesting", "CodeReview", "UserReport", "Monitoring", "Development", "FeatureImplementation", "Refactoring")]
    [string]$DiscoveredBy,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Critical", "High", "Medium", "Low")]
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
    [string]$RelatedFeature = ""
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
Invoke-StandardScriptInitialization

# Get current date in YYYY-MM-DD format
$currentDate = Get-Date -Format "yyyy-MM-dd"

# Path to bug tracking file - use project root for reliable path resolution
$ProjectRoot = Get-ProjectRoot
$BugTrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/process-framework/state-tracking/permanent/bug-tracking.md"

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

# Map severity to priority code
$PriorityCode = switch ($Severity) {
    "Critical" { "P1" }
    "High"     { "P2" }
    "Medium"   { "P3" }
    "Low"      { "P4" }
}

# Build Notes field: Source first, then component/environment, then optional details
$NotesParts = @("Source: $DiscoveredBy", "Environment: $Environment", "Component: $Component")
if ($ReproductionSteps -ne "") { $NotesParts += "Repro: $ReproductionSteps" }
if ($ExpectedBehavior -ne "") { $NotesParts += "Expected: $ExpectedBehavior" }
if ($ActualBehavior -ne "") { $NotesParts += "Actual: $ActualBehavior" }
if ($Evidence -ne "") { $NotesParts += "Evidence: $Evidence" }
$NotesField = $NotesParts -join "; "

# Related feature field
$RelatedFeatureField = if ($RelatedFeature -ne "") { $RelatedFeature } else { "N/A" }

# Create table row — 9-column format: ID | Title | Status | Priority | Scope | Reported | Description | Related Feature | Notes
$TableRow = "| $BugId | $Title | 🆕 Reported | $PriorityCode | | $currentDate | $Description | $RelatedFeatureField | $NotesField |"

# Find the appropriate table and replace the "No bugs" message
$NobugsPattern = switch ($Severity) {
    "Critical" { "\| _No critical bugs currently reported_ \|" }
    "High" { "\| _No high priority bugs currently active_ \|" }
    "Medium" { "\| _No medium priority bugs currently reported_ \|" }
    "Low" { "\| _No low priority bugs currently reported_ \|" }
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
# Active statuses: 🆕 Reported, 🔍 Triaged, 🟡 In Progress, 🧪 Fixed, 🔄 Reopened
$ClosedSectionIndex = $UpdatedContent.IndexOf("## Closed Bugs")
$ActiveSection = if ($ClosedSectionIndex -gt 0) { $UpdatedContent.Substring(0, $ClosedSectionIndex) } else { $UpdatedContent }

$ActiveCount = ([regex]::Matches($ActiveSection, '\| PD-BUG-\d+')).Count
$UpdatedContent = [regex]::Replace($UpdatedContent, '(\*\*Total Active Bugs\*\*: )\d+', "`${1}$ActiveCount")

# Update priority-specific counts - count all active bug rows by priority code
$CriticalCount = ([regex]::Matches($ActiveSection, '\| PD-BUG-\d+.*\| P1 \|')).Count
$HighCount = ([regex]::Matches($ActiveSection, '\| PD-BUG-\d+.*\| P2 \|')).Count
$MediumCount = ([regex]::Matches($ActiveSection, '\| PD-BUG-\d+.*\| P3 \|')).Count
$LowCount = ([regex]::Matches($ActiveSection, '\| PD-BUG-\d+.*\| P4 \|')).Count

$UpdatedContent = [regex]::Replace($UpdatedContent, '(\*\*Critical \(P1\)\*\*: )\d+', "`${1}$CriticalCount")
$UpdatedContent = [regex]::Replace($UpdatedContent, '(\*\*High \(P2\)\*\*: )\d+', "`${1}$HighCount")
$UpdatedContent = [regex]::Replace($UpdatedContent, '(\*\*Medium \(P3\)\*\*: )\d+', "`${1}$MediumCount")
$UpdatedContent = [regex]::Replace($UpdatedContent, '(\*\*Low \(P4\)\*\*: )\d+', "`${1}$LowCount")

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
    Write-Host "  1. Run Bug Triage task to evaluate and prioritize this bug" -ForegroundColor White
    Write-Host "  2. Bug will be assigned priority and severity during triage" -ForegroundColor White
    Write-Host "  3. After triage, bug can be assigned for fixing" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Tip: Use 'Bug Triage' task to process all reported bugs" -ForegroundColor Cyan
}
catch {
    Write-ProjectError -Message "Failed to create bug report: $($_.Exception.Message)" -ExitCode 1
}
