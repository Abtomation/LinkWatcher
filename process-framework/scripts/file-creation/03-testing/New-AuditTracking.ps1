# New-AuditTracking.ps1
# Creates a new test audit tracking state file for a multi-session audit round
# Auto-populates inventory from test-tracking.md

<#
.SYNOPSIS
    Creates a new test audit tracking state file for a multi-session audit round.

.DESCRIPTION
    This PowerShell script generates audit tracking state files by:
    - Generating a unique state ID (PF-STA-XXX) automatically
    - Creating the file in test/state-tracking/audit/
    - Auto-populating the test file inventory from test-tracking.md
    - Optionally filtering to specific features
    - Updating the ID tracker in the central ID registry

    Used by the Test Audit task (PF-TSK-030) to scope and track
    multi-session audit rounds.

.PARAMETER RoundNumber
    The audit round number (e.g., 1, 2, 3). Used in the document title
    and filename.

.PARAMETER Description
    Optional description of the audit round's focus or scope.

.PARAMETER FeatureFilter
    Optional comma-separated list of feature IDs to include (e.g., "0.1.1,2.1.1").
    If omitted, all test files with auditable status are included.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor.

.EXAMPLE
    .\New-AuditTracking.ps1 -RoundNumber 1

    Creates audit-tracking-1.md with all auditable test files.

.EXAMPLE
    .\New-AuditTracking.ps1 -RoundNumber 2 -FeatureFilter "0.1.1,2.1.1" -Description "Foundation and parser re-audit"

.NOTES
    Script Type: Document Creation Script
    Created: 2026-04-03
    For: Test Audit task (PF-TSK-030)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [int]$RoundNumber,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [string]$FeatureFilter = "",

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

$today = Get-Date -Format "yyyy-MM-dd"
$projectRoot = Get-ProjectRoot

# --- Parse test-tracking.md to build inventory ---
$testTrackingPath = Join-Path $projectRoot "test/state-tracking/permanent/test-tracking.md"
if (-not (Test-Path $testTrackingPath)) {
    Write-ProjectError -Message "test-tracking.md not found at: $testTrackingPath" -ExitCode 1
}

$trackingContent = Get-Content $testTrackingPath -Raw

# Parse feature filter into array
$featureFilterList = @()
if ($FeatureFilter -ne "") {
    $featureFilterList = $FeatureFilter -split "," | ForEach-Object { $_.Trim() }
}

# Auditable statuses — test files that are candidates for audit
$auditableStatuses = @(
    "Tests Implemented",
    "Tests Approved",
    "Tests Approved with Dependencies",
    "Needs Update"
)

# Parse all test tables from test-tracking.md using shared table helpers
# Start from "## 0." to skip Status Legend and Coverage Summary tables
$allTestRows = ConvertFrom-MarkdownTable -Content $trackingContent -Section "## 0." -AllTables -ResolveLinkColumn @("Test File/Case")

# Filter to auditable automated test files
$inventoryRows = @()
$rowNumber = 0

foreach ($row in $allTestRows) {
    # Skip non-automated tests
    if ($row.'Test Type' -ne "Automated") { continue }

    # Skip infrastructure entries (Feature ID is em-dash variants)
    $featureId = $row.'Feature ID'
    if ($featureId -eq [string][char]0x2014 -or $featureId -eq "---" -or $featureId -eq "--") { continue }

    # Apply feature filter if specified
    if ($featureFilterList.Count -gt 0 -and $featureId -notin $featureFilterList) { continue }

    # Check if status is auditable
    $statusCell = $row.'Status'
    $isAuditable = $false
    foreach ($status in $auditableStatuses) {
        if ($statusCell -match [regex]::Escape($status)) {
            $isAuditable = $true
            break
        }
    }
    if (-not $isAuditable) { continue }

    # Test file name already resolved from markdown link by ResolveLinkColumn
    $testFileName = $row.'Test File/Case'

    # Determine display status (strip emoji prefix)
    $displayStatus = $statusCell -replace '^[^\w]*', ''

    $rowNumber++
    $inventoryRows += ConvertTo-MarkdownTableRow -Cells @("$rowNumber", $featureId, $testFileName, $displayStatus, "Pending", "—", "—", "—")
}

if ($inventoryRows.Count -eq 0) {
    Write-ProjectError -Message "No auditable test files found in test-tracking.md matching the specified criteria." -ExitCode 1
}

$inventoryContent = $inventoryRows -join "`n"
$totalCount = $inventoryRows.Count

# Prepare scope description
$scopeDescription = if ($Description -ne "") { $Description } elseif ($FeatureFilter -ne "") { "Features: $FeatureFilter" } else { "Full test suite audit" }

# Prepare custom replacements
$customReplacements = @{
    "[Round N]"              = "Round $RoundNumber"
    "[DATE]"                 = $today
    "[SCOPE_DESCRIPTION]"    = $scopeDescription
    "[INVENTORY_PLACEHOLDER]" = $inventoryContent
    "[TOTAL]"                = "$totalCount"
    "[YYYY-MM-DD]"           = $today
    "[Describe first validation session]" = $scopeDescription
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "audit_round" = "$RoundNumber"
}

$customFileName = "audit-tracking-$RoundNumber.md"

try {
    $documentId = New-StandardProjectDocument `
        -TemplatePath "process-framework/templates/03-testing/audit-tracking-template.md" `
        -IdPrefix "PF-STA" `
        -IdDescription "Audit tracking state for Round $RoundNumber" `
        -DocumentName "Audit Tracking Round $RoundNumber" `
        -OutputDirectory "test/state-tracking/audit" `
        -Replacements $customReplacements `
        -AdditionalMetadataFields $additionalMetadataFields `
        -FileNamePattern $customFileName `
        -OpenInEditor:$OpenInEditor

    $details = @(
        "Round: $RoundNumber",
        "Location: test/state-tracking/audit/$customFileName",
        "Test files in scope: $totalCount"
    )

    if ($Description -ne "") {
        $details += "Description: $Description"
    }

    if ($FeatureFilter -ne "") {
        $details += "Feature filter: $FeatureFilter"
    }

    $details += @(
        "",
        "TEMPLATE CREATED - CUSTOMIZATION REQUIRED",
        "",
        "Review the auto-populated inventory for accuracy.",
        "Plan the session sequence (group by feature for efficient context loading).",
        "Mark files as 'Skipped' if they should be excluded from this round."
    )

    Write-ProjectSuccess -Message "Created audit tracking with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create audit tracking: $($_.Exception.Message)" -ExitCode 1
}
