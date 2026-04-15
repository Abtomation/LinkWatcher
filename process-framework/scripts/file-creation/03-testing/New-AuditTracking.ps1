# New-AuditTracking.ps1
# Creates a new test audit tracking state file for a multi-session audit round
# Auto-populates inventory from the appropriate tracking file based on -TestType

<#
.SYNOPSIS
    Creates a new test audit tracking state file for a multi-session audit round.

.DESCRIPTION
    This PowerShell script generates audit tracking state files by:
    - Generating a unique state ID (PF-STA-XXX) automatically
    - Creating the file in test/state-tracking/audit/
    - Auto-populating the inventory from the appropriate tracking file:
      - Automated (default): test-tracking.md
      - Performance: performance-test-tracking.md
      - E2E: e2e-test-tracking.md
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
    New-AuditTracking.ps1 -RoundNumber 1

    Creates audit-tracking-1.md with all auditable test files.

.EXAMPLE
    New-AuditTracking.ps1 -RoundNumber 2 -FeatureFilter "0.1.1,2.1.1" -Description "Foundation and parser re-audit"

.NOTES
    Script Type: Document Creation Script
    Created: 2026-04-03
    For: Test Audit task (PF-TSK-030)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Automated", "Performance", "E2E")]
    [string]$TestType = "Automated",

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

# --- Parse the appropriate tracking file to build inventory ---
$trackingRelPath = switch ($TestType) {
    "Performance" { "test/state-tracking/permanent/performance-test-tracking.md" }
    "E2E" { "test/state-tracking/permanent/e2e-test-tracking.md" }
    default { "test/state-tracking/permanent/test-tracking.md" }
}
$trackingFilePath = Join-Path $projectRoot $trackingRelPath
$trackingFileName = Split-Path $trackingFilePath -Leaf

if (-not (Test-Path $trackingFilePath)) {
    Write-ProjectError -Message "$trackingFileName not found at: $trackingFilePath" -ExitCode 1
}

$trackingContent = Get-Content $trackingFilePath -Raw

# Parse feature filter into array
$featureFilterList = @()
if ($FeatureFilter -ne "") {
    $featureFilterList = $FeatureFilter -split "," | ForEach-Object { $_.Trim() }
}

$inventoryRows = @()
$rowNumber = 0

if ($TestType -eq "Performance") {
    # --- Performance: parse performance-test-tracking.md ---
    $auditableStatuses = @("Created", "Baselined", "Stale")

    # Parse all level tables (they all share the same column structure)
    $allPerfRows = ConvertFrom-MarkdownTable -Content $trackingContent -Section "## Test Inventory" -AllTables -ResolveLinkColumn @("Test File")

    foreach ($row in $allPerfRows) {
        $testId = $row.'Test ID'
        if (-not $testId -or $testId -notmatch '^(BM|PH)-') { continue }

        # Apply feature filter on Related Features column
        if ($featureFilterList.Count -gt 0) {
            $relatedFeatures = $row.'Related Features' -split ',' | ForEach-Object { $_.Trim() }
            $matchesFilter = $false
            foreach ($f in $featureFilterList) {
                if ($f -in $relatedFeatures) { $matchesFilter = $true; break }
            }
            if (-not $matchesFilter) { continue }
        }

        # Check if status is auditable (skip ⬜ Specified — no implementation yet)
        $statusCell = $row.'Status'
        $isAuditable = $false
        foreach ($status in $auditableStatuses) {
            if ($statusCell -match [regex]::Escape($status)) { $isAuditable = $true; break }
        }
        if (-not $isAuditable) { continue }

        # Skip already-audited entries (Audit Status is not "—")
        $auditStatus = $row.'Audit Status'
        if ($auditStatus -and $auditStatus -ne '—' -and $auditStatus -match 'Approved') { continue }

        $operation = $row.'Operation'
        $displayStatus = $statusCell -replace '^[^\w]*', ''

        $rowNumber++
        $inventoryRows += ConvertTo-MarkdownTableRow -Cells @("$rowNumber", $testId, $operation, $displayStatus, "Pending", "—", "—", "—")
    }
}
elseif ($TestType -eq "E2E") {
    # --- E2E: parse e2e-test-tracking.md ---
    $auditableStatuses = @("Case Created", "Passed", "Failed", "Needs Re-execution")

    # Parse the E2E Test Cases table
    $allE2eRows = ConvertFrom-MarkdownTable -Content $trackingContent -Section "## E2E Test Cases" -AllTables -ResolveLinkColumn @("Test File/Case")

    foreach ($row in $allE2eRows) {
        $testId = $row.'Test ID'
        if (-not $testId -or $testId -notmatch '^TE-E2[EG]-') { continue }

        # Apply feature filter on Feature IDs column
        if ($featureFilterList.Count -gt 0) {
            $featureIds = $row.'Feature IDs' -split ',' | ForEach-Object { $_.Trim() }
            $matchesFilter = $false
            foreach ($f in $featureFilterList) {
                if ($f -in $featureIds) { $matchesFilter = $true; break }
            }
            if (-not $matchesFilter) { continue }
        }

        # Check if status is auditable
        $statusCell = $row.'Status'
        $isAuditable = $false
        foreach ($status in $auditableStatuses) {
            if ($statusCell -match [regex]::Escape($status)) { $isAuditable = $true; break }
        }
        if (-not $isAuditable) { continue }

        # Skip already-audited entries
        $auditStatus = $row.'Audit Status'
        if ($auditStatus -and $auditStatus -ne '—' -and $auditStatus -match 'Approved') { continue }

        $testFile = $row.'Test File/Case'
        $displayStatus = $statusCell -replace '^[^\w]*', ''

        $rowNumber++
        $inventoryRows += ConvertTo-MarkdownTableRow -Cells @("$rowNumber", $testId, $testFile, $displayStatus, "Pending", "—", "—", "—")
    }
}
else {
    # --- Automated: existing behavior — parse test-tracking.md ---
    $auditableStatuses = @(
        "Tests Implemented",
        "Tests Approved",
        "Tests Approved with Dependencies",
        "Needs Update"
    )

    # Parse all test tables from test-tracking.md using shared table helpers
    # Start from "## 0." to skip Status Legend and Coverage Summary tables
    $allTestRows = ConvertFrom-MarkdownTable -Content $trackingContent -Section "## 0." -AllTables -ResolveLinkColumn @("Test File/Case")

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
}

if ($inventoryRows.Count -eq 0) {
    Write-ProjectError -Message "No auditable test files found in $trackingFileName matching the specified criteria." -ExitCode 1
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

$typeSuffix = switch ($TestType) { "Performance" { "-performance" }; "E2E" { "-e2e" }; default { "" } }
$customFileName = "audit-tracking$typeSuffix-$RoundNumber.md"

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
