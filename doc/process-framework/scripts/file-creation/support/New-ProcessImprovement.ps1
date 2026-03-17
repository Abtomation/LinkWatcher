# New-ProcessImprovement.ps1
# Adds a new improvement opportunity to the Process Improvement Tracking state file
# Uses the central ID registry system for auto-assigned PF-IMP IDs

<#
.SYNOPSIS
    Adds a new improvement opportunity to process-improvement-tracking.md with an auto-assigned ID.

.DESCRIPTION
    This PowerShell script creates new improvement entries by:
    - Generating a unique improvement ID (PF-IMP-###) via the central ID registry
    - Adding a row to the "Current Improvement Opportunities" table
    - Adding an Update History entry
    - Updating the frontmatter date

.PARAMETER Source
    Display text for the source of this improvement (e.g., "Tools Review 2026-03-02", "User feedback")

.PARAMETER SourceLink
    Optional markdown link target for the source. When provided, the Source column renders as [Source](SourceLink).

.PARAMETER Description
    What needs to be improved

.PARAMETER Priority
    Priority level: HIGH, MEDIUM, or LOW

.PARAMETER Notes
    Additional context or details (optional)

.PARAMETER Status
    Initial status (default: "Identified"). Valid: Identified, Prioritized

.PARAMETER UpdatedBy
    Who created the entry (default: "AI Agent (PF-TSK-010)")

.EXAMPLE
    .\New-ProcessImprovement.ps1 -Source "Tools Review 2026-03-02" -SourceLink "../../feedback/reviews/tools-review-20260302.md" -Description "Add validation to script X" -Priority "MEDIUM"

.EXAMPLE
    .\New-ProcessImprovement.ps1 -Source "User feedback" -Description "Simplify feedback form process" -Priority "HIGH" -Notes "Reported in session on 2026-03-02"

.EXAMPLE
    .\New-ProcessImprovement.ps1 -Source "Tools Review 2026-03-02" -SourceLink "../../feedback/reviews/tools-review-20260302.md" -Description "Fix broken path in script" -Priority "LOW" -Notes "Clarity scored 3" -WhatIf

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Adds entry to "Current Improvement Opportunities" table
    - Note: existing entries use IMP-### format; new entries use PF-IMP-### format
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateLength(3, 200)]
    [string]$Source,

    [Parameter(Mandatory = $false)]
    [string]$SourceLink = "",

    [Parameter(Mandatory = $true)]
    [ValidateLength(10, 500)]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [ValidateSet("HIGH", "MEDIUM", "LOW")]
    [string]$Priority,

    [Parameter(Mandatory = $false)]
    [string]$Notes = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Identified", "Prioritized")]
    [string]$Status = "Identified",

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
$TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/process-framework/state-tracking/permanent/process-improvement-tracking.md"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

if (-not (Test-Path $TrackingFile)) {
    Write-ProjectError -Message "Tracking file not found: $TrackingFile" -ExitCode 1
}

# Early WhatIf check — exit before consuming an ID from the registry
if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Add new improvement opportunity '$Description'")) {
    return
}

# Generate unique improvement ID using the central registry
$ImprovementId = New-ProjectId -Prefix "PF-IMP" -Description "Improvement: $Description"

Write-Host "Adding improvement opportunity: $ImprovementId" -ForegroundColor Yellow
Write-Host "Description: $Description" -ForegroundColor Cyan

# Build the Source column
$SourceColumn = if ($SourceLink -ne "") {
    "[$Source]($SourceLink)"
} else {
    $Source
}

# Build the table row — 7-column format: ID | Source | Description | Priority | Status | Last Updated | Notes
$TableRow = "| $ImprovementId | $SourceColumn | $Description | $Priority | $Status | $CurrentDate | $Notes |"

# Read current content
$Content = Get-Content -Path $TrackingFile -Raw -Encoding UTF8

# Find insertion point: after the last data row in "Current Improvement Opportunities" table
$lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

$insertAfterIndex = -1
$inCurrentSection = $false
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^## Current Improvement Opportunities") { $inCurrentSection = $true }
    if ($inCurrentSection) {
        # Match any IMP row (old IMP-### or new PF-IMP-### format)
        if ($lines[$i] -match "^\|\s*(IMP|PF-IMP)-\d+") { $insertAfterIndex = $i }
        # Stop at the next section
        if ($lines[$i] -match "^## " -and $lines[$i] -notmatch "^## Current Improvement") { break }
    }
}

# If no data rows found, insert after the table header separator
if ($insertAfterIndex -eq -1) {
    $inCurrentSection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Current Improvement Opportunities") { $inCurrentSection = $true }
        if ($inCurrentSection -and $lines[$i] -match "^\|\s*-") {
            $insertAfterIndex = $i
            break
        }
    }
}

if ($insertAfterIndex -eq -1) {
    Write-ProjectError -Message "Could not find insertion point in Current Improvement Opportunities table" -ExitCode 1
}

$lines.Insert($insertAfterIndex + 1, $TableRow)
Write-Host "Inserted $ImprovementId into Current Improvement Opportunities table" -ForegroundColor Green

# Add Update History entry
$HistoryNote = "Added $ImprovementId`: $Description"
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
        "ID: $ImprovementId",
        "Source: $Source",
        "Priority: $Priority",
        "Status: $Status"
    )

    if ($Notes -ne "") {
        $details += "Notes: $Notes"
    }

    Write-ProjectSuccess -Message "Created improvement opportunity: $ImprovementId" -Details $details

    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  - Use Process Improvement task (PF-TSK-009) to implement this improvement" -ForegroundColor White
    Write-Host "  - Use Update-ProcessImprovement.ps1 to change status later" -ForegroundColor White
}
catch {
    Write-ProjectError -Message "Failed to create improvement entry: $($_.Exception.Message)" -ExitCode 1
}
