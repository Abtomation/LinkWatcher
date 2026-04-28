# New-FeatureRequest.ps1
# Adds a new feature request to the Feature Request Tracking state file
# Uses the central ID registry system for auto-assigned PD-FRQ IDs

<#
.SYNOPSIS
    Adds a new feature request to feature-request-tracking.md with an auto-assigned ID.

.DESCRIPTION
    This PowerShell script creates new feature request entries by:
    - Generating a unique request ID (PD-FRQ-###) via the central ID registry
    - Adding a row to the "Active Feature Requests" table
    - Adding an Update History entry
    - Updating the frontmatter date

    Feature requests are product-level change requests (new features or enhancements
    to existing features). Process framework improvements belong in
    process-improvement-tracking.md instead.

.PARAMETER Source
    Display text for the source of this request (e.g., "Tools Review 2026-03-26", "User request")

.PARAMETER SourceLink
    Optional markdown link target for the source. When provided, the Source column renders as [Source](SourceLink).

.PARAMETER Description
    What is being requested (10-500 chars; for table-row brevity, compress longer drafts and move detailed context to -Notes).

.PARAMETER Priority
    Priority level: HIGH, MEDIUM, or LOW

.PARAMETER Notes
    Additional context or details (optional)

.PARAMETER UpdatedBy
    Who created the entry (default: "AI Agent (PF-TSK-010)")

.EXAMPLE
    .\New-FeatureRequest.ps1 -Source "Tools Review 2026-03-26" -SourceLink "../../feedback/reviews/tools-review-20260326.md" -Description "Add HTML comment filtering to link validator" -Priority "HIGH"

.EXAMPLE
    .\New-FeatureRequest.ps1 -Source "User request" -Description "Add TOML file support" -Priority "MEDIUM" -Notes "Requested for config files"

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Adds entry to "Active Feature Requests" table
    - The Feature and Classification columns are left empty — they are filled by
      Feature Request Evaluation (PF-TSK-067) via Update-FeatureRequest.ps1
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateLength(3, 200)]
    [string]$Source,

    [Parameter(Mandatory = $false)]
    [string]$SourceLink = "",

    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if ($_.Length -lt 10) {
            throw "Description is too short ($($_.Length) chars; minimum 10). Provide a more substantive description."
        }
        if ($_.Length -gt 500) {
            $over = $_.Length - 500
            throw "Description is too long ($($_.Length) chars; maximum 500, $over over). For table-row brevity, compress the description and move detailed context to -Notes."
        }
        $true
    })]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [ValidateSet("HIGH", "MEDIUM", "LOW")]
    [string]$Priority,

    [Parameter(Mandatory = $false)]
    [string]$Notes = "",

    [Parameter(Mandatory = $false)]
    [string]$UpdatedBy = "AI Agent (PF-TSK-010)"
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
Invoke-StandardScriptInitialization

# Configuration
$ProjectRoot = Get-ProjectRoot
$TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/feature-request-tracking.md"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

if (-not (Test-Path $TrackingFile)) {
    Write-ProjectError -Message "Tracking file not found: $TrackingFile" -ExitCode 1
}

# Early WhatIf check — exit before consuming an ID from the registry
if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Add new feature request '$Description'")) {
    return
}

# Generate unique request ID using the central registry
$RequestId = New-ProjectId -Prefix "PD-FRQ" -Description "Feature Request: $Description"

Write-Host "Adding feature request: $RequestId" -ForegroundColor Yellow
Write-Host "Description: $Description" -ForegroundColor Cyan

# Build the Source column
$SourceColumn = if ($SourceLink -ne "") {
    "[$Source]($SourceLink)"
} else {
    $Source
}

# Build the table row — 8-column format: ID | Source | Description | Feature | Classification | Status | Last Updated | Notes
$TableRow = "| $RequestId | $SourceColumn | $Description | — | — | 📥 Submitted | $CurrentDate | $Notes |"

# Read current content
$Content = Get-Content -Path $TrackingFile -Raw -Encoding UTF8

# Find insertion point: after the last data row in "Active Feature Requests" table
$lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

$insertAfterIndex = -1
$inActiveSection = $false
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^## Active Feature Requests") { $inActiveSection = $true }
    if ($inActiveSection) {
        # Match any FRQ row
        if ($lines[$i] -match "^\|\s*PD-FRQ-\d+") { $insertAfterIndex = $i }
        # Stop at the next section
        if ($lines[$i] -match "^## " -and $lines[$i] -notmatch "^## Active Feature") { break }
    }
}

# If no data rows found, insert after the table header separator
if ($insertAfterIndex -eq -1) {
    $inActiveSection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Active Feature Requests") { $inActiveSection = $true }
        if ($inActiveSection -and $lines[$i] -match "^\|\s*-") {
            $insertAfterIndex = $i
            break
        }
    }
}

if ($insertAfterIndex -eq -1) {
    Write-ProjectError -Message "Could not find insertion point in Active Feature Requests table" -ExitCode 1
}

$lines.Insert($insertAfterIndex + 1, $TableRow)
Write-Host "Inserted $RequestId into Active Feature Requests table" -ForegroundColor Green

# Add Update History entry
$HistoryNote = "Added $RequestId`: $Description"
$historyInsertIndex = -1
$inHistorySection = $false
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^## Update History") { $inHistorySection = $true }
    if ($inHistorySection -and $lines[$i] -match "^\|[^-]" -and $lines[$i] -notmatch "^\|\s*Date") {
        $historyInsertIndex = $i
    }
}

# If no data rows in history, insert after the separator
if ($historyInsertIndex -eq -1) {
    $inHistorySection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Update History") { $inHistorySection = $true }
        if ($inHistorySection -and $lines[$i] -match "^\|\s*-") {
            $historyInsertIndex = $i
            break
        }
    }
}

if ($historyInsertIndex -ne -1) {
    $historyRow = "| $CurrentDate | $HistoryNote | $UpdatedBy |"
    $lines.Insert($historyInsertIndex + 1, $historyRow)
    Write-Host "Added Update History entry" -ForegroundColor Green
}

# Update frontmatter date
$updatedContent = ($lines -join "`r`n")
$updatedContent = $updatedContent -replace '(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate

try {
    Set-Content -Path $TrackingFile -Value $updatedContent -NoNewline -Encoding UTF8

    $details = @(
        "ID: $RequestId",
        "Source: $Source",
        "Priority: $Priority",
        "Status: Submitted"
    )

    if ($Notes -ne "") {
        $details += "Notes: $Notes"
    }

    Write-ProjectSuccess -Message "Created feature request: $RequestId" -Details $details

    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  - Use Feature Request Evaluation (PF-TSK-067) to classify this request" -ForegroundColor White
    Write-Host "  - Use Update-FeatureRequest.ps1 to update status after classification" -ForegroundColor White
}
catch {
    Write-ProjectError -Message "Failed to create feature request entry: $($_.Exception.Message)" -ExitCode 1
}
