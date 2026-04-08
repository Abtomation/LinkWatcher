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
    New-ProcessImprovement.ps1 -Source "Tools Review 2026-03-02" -SourceLink "../../feedback/reviews/tools-review-20260302.md" -Description "Add validation to script X" -Priority "MEDIUM"

.EXAMPLE
    New-ProcessImprovement.ps1 -Source "User feedback" -Description "Simplify feedback form process" -Priority "HIGH" -Notes "Reported in session on 2026-03-02"

.EXAMPLE
    New-ProcessImprovement.ps1 -Source "Tools Review 2026-03-02" -SourceLink "../../feedback/reviews/tools-review-20260302.md" -Description "Fix broken path in script" -Priority "LOW" -Notes "Clarity scored 3" -WhatIf

.EXAMPLE
    New-ProcessImprovement.ps1 -BatchFile "improvements.json"
    # Where improvements.json contains:
    # [
    #   { "Source": "Tools Review 2026-04-06", "SourceLink": "../../feedback/reviews/review.md", "Description": "Add batch mode", "Priority": "LOW" },
    #   { "Source": "User feedback", "Description": "Fix path issue", "Priority": "HIGH", "Notes": "Urgent" }
    # ]

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Adds entry to "Current Improvement Opportunities" table
    - Note: existing entries use IMP-### format; new entries use PF-IMP-### format
    - Batch mode: pass a JSON file with an array of improvement objects to register multiple items at once
#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "Single")]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [ValidateLength(3, 200)]
    [string]$Source,

    [Parameter(Mandatory = $false, ParameterSetName = "Single")]
    [string]$SourceLink = "",

    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [ValidateLength(10, 500)]
    [string]$Description,

    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [ValidateSet("HIGH", "MEDIUM", "LOW")]
    [string]$Priority,

    [Parameter(Mandatory = $false, ParameterSetName = "Single")]
    [string]$Notes = "",

    [Parameter(Mandatory = $false, ParameterSetName = "Single")]
    [ValidateSet("Identified", "Prioritized")]
    [string]$Status = "Identified",

    [Parameter(Mandatory = $true, ParameterSetName = "Batch")]
    [ValidateScript({ Test-Path $_ })]
    [string]$BatchFile,

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
$TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "process-framework-local/state-tracking/permanent/process-improvement-tracking.md"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

if (-not (Test-Path $TrackingFile)) {
    Write-ProjectError -Message "Tracking file not found: $TrackingFile" -ExitCode 1
}

# --- Core logic: add a single improvement to the tracking file ---
function Add-SingleImprovement {
    param(
        [string]$ItemSource,
        [string]$ItemSourceLink,
        [string]$ItemDescription,
        [string]$ItemPriority,
        [string]$ItemNotes,
        [string]$ItemStatus,
        [string]$ItemUpdatedBy
    )

    # Generate unique improvement ID using the central registry
    $ImprovementId = New-ProjectId -Prefix "PF-IMP" -Description "Improvement: $ItemDescription"

    Write-Host "Adding improvement opportunity: $ImprovementId" -ForegroundColor Yellow
    Write-Host "Description: $ItemDescription" -ForegroundColor Cyan

    # Build the Source column
    $SourceColumn = if ($ItemSourceLink -ne "") {
        "[$ItemSource]($ItemSourceLink)"
    } else {
        $ItemSource
    }

    # Build the table row — 7-column format: ID | Source | Description | Priority | Status | Last Updated | Notes
    $TableRow = "| $ImprovementId | $SourceColumn | $ItemDescription | $ItemPriority | $ItemStatus | $CurrentDate | $ItemNotes |"

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
        Write-ProjectError -Message "Could not find insertion point in Current Improvement Opportunities table"
        return $null
    }

    $lines.Insert($insertAfterIndex + 1, $TableRow)
    Write-Host "Inserted $ImprovementId into Current Improvement Opportunities table" -ForegroundColor Green

    # Add Update History entry
    $HistoryNote = "Added $ImprovementId`: $ItemDescription"
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
        $historyRow = "| $CurrentDate | $HistoryNote | $ItemUpdatedBy |"
        $lines.Insert($historyInsertIndex + 1, $historyRow)
        Write-Host "Added Update History entry" -ForegroundColor Green
    }

    # Update frontmatter date
    $updatedContent = ($lines -join "`r`n")
    $updatedContent = $updatedContent -replace '(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate

    Set-Content -Path $TrackingFile -Value $updatedContent -NoNewline -Encoding UTF8

    return @{
        Id = $ImprovementId
        Source = $ItemSource
        Priority = $ItemPriority
        Status = $ItemStatus
        Notes = $ItemNotes
    }
}

# --- Dispatch: Batch vs Single mode ---
if ($PSCmdlet.ParameterSetName -eq "Batch") {
    # Batch mode: read JSON array from file
    try {
        $jsonContent = Get-Content -Path $BatchFile -Raw -Encoding UTF8
        $items = $jsonContent | ConvertFrom-Json
    }
    catch {
        Write-ProjectError -Message "Failed to parse batch file '$BatchFile': $($_.Exception.Message)" -ExitCode 1
    }

    if ($items -isnot [System.Array]) {
        Write-ProjectError -Message "Batch file must contain a JSON array of improvement objects" -ExitCode 1
    }

    Write-Host "Batch mode: processing $($items.Count) improvements from $BatchFile" -ForegroundColor Magenta

    # Validate all items before consuming any IDs
    $validPriorities = @("HIGH", "MEDIUM", "LOW")
    $validStatuses = @("Identified", "Prioritized")
    for ($idx = 0; $idx -lt $items.Count; $idx++) {
        $item = $items[$idx]
        $errors = @()
        if (-not $item.Source) { $errors += "missing Source" }
        if (-not $item.Description) { $errors += "missing Description" }
        if (-not $item.Priority) { $errors += "missing Priority" }
        elseif ($item.Priority -notin $validPriorities) { $errors += "invalid Priority '$($item.Priority)' (must be HIGH, MEDIUM, or LOW)" }
        if ($item.Status -and $item.Status -notin $validStatuses) { $errors += "invalid Status '$($item.Status)' (must be Identified or Prioritized)" }
        if ($errors.Count -gt 0) {
            Write-ProjectError -Message "Item [$idx]: $($errors -join '; ')" -ExitCode 1
        }
    }

    if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Add $($items.Count) improvement opportunities from batch file")) {
        return
    }

    $created = @()
    foreach ($item in $items) {
        $result = Add-SingleImprovement `
            -ItemSource $item.Source `
            -ItemSourceLink $(if ($item.SourceLink) { $item.SourceLink } else { "" }) `
            -ItemDescription $item.Description `
            -ItemPriority $item.Priority `
            -ItemNotes $(if ($item.Notes) { $item.Notes } else { "" }) `
            -ItemStatus $(if ($item.Status) { $item.Status } else { "Identified" }) `
            -ItemUpdatedBy $UpdatedBy

        if ($result) {
            $created += $result
            Write-Host ""
        }
    }

    Write-Host "========================================" -ForegroundColor Magenta
    Write-ProjectSuccess -Message "Batch complete: $($created.Count)/$($items.Count) improvements created" -Details ($created | ForEach-Object { "$($_.Id): $($_.Priority)" })

} else {
    # Single mode: original behavior
    if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Add new improvement opportunity '$Description'")) {
        return
    }

    try {
        $result = Add-SingleImprovement `
            -ItemSource $Source `
            -ItemSourceLink $SourceLink `
            -ItemDescription $Description `
            -ItemPriority $Priority `
            -ItemNotes $Notes `
            -ItemStatus $Status `
            -ItemUpdatedBy $UpdatedBy

        if ($result) {
            $details = @(
                "ID: $($result.Id)",
                "Source: $Source",
                "Priority: $Priority",
                "Status: $Status"
            )
            if ($Notes -ne "") { $details += "Notes: $Notes" }

            Write-ProjectSuccess -Message "Created improvement opportunity: $($result.Id)" -Details $details

            Write-Host ""
            Write-Host "Next Steps:" -ForegroundColor Yellow
            Write-Host "  - Use Process Improvement task (PF-TSK-009) to implement this improvement" -ForegroundColor White
            Write-Host "  - Use Update-ProcessImprovement.ps1 to change status later" -ForegroundColor White
        }
    }
    catch {
        Write-ProjectError -Message "Failed to create improvement entry: $($_.Exception.Message)" -ExitCode 1
    }
}
