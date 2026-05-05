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

    Field length constraints (validated at runtime): -Source 3-200 chars,
    -Description 10-500 chars, -Notes 0-2000 chars. If a Description draft
    exceeds 500 chars, compress it for table-row brevity and move detail to -Notes.

.PARAMETER Source
    Display text for the source of this improvement (e.g., "Tools Review 2026-03-02", "User feedback")

.PARAMETER SourceLink
    Optional markdown link target for the source. When provided, the Source column renders as [Source](SourceLink).

.PARAMETER Description
    What needs to be improved (10-500 chars; for table-row brevity, compress longer drafts and move detailed context to -Notes).

.PARAMETER Priority
    Priority level: HIGH, MEDIUM, or LOW

.PARAMETER Notes
    Additional context or details (optional, 0-2000 chars; for longer detail, link to a separate document)

.PARAMETER Status
    Initial status (default: "NeedsPrioritization"). Valid: NeedsPrioritization, NeedsImplementation

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

.EXAMPLE
    # Pilot mode: register a Framework Extension pilot in the Active Pilots section.
    New-ProcessImprovement.ps1 -AsPilot `
        -SourceConcept "PF-PRO-028" -OriginatingTask "PF-TSK-026" `
        -Adopters "New-IntegrationNarrative.ps1, New-Handbook.ps1" `
        -SuccessCriteria "All adopter soak counters reach 0" `
        -DecisionTrigger "PF-IMP-685" `
        -Notes "Retroactive registration of script-self-verification pilot"

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Adds entry to "Current Improvement Opportunities" table (Single/Batch) or "Active Pilots" table (-AsPilot)
    - Note: existing entries use IMP-### format; new entries use PF-IMP-### format
    - **Field length constraints** (both Single and Batch modes): Source 3-200 chars, Description 10-500 chars, Notes 0-2000 chars. If your draft Description exceeds 500 chars, compress it for table-row brevity and move detailed context to -Notes; if Notes itself exceeds 2000 chars, link to a separate document instead of inlining.
    - Batch mode: pass a JSON file with an array of improvement objects to register multiple items at once. Same length constraints apply; the entire batch aborts on the first item with errors before any IDs are consumed.
    - Pilot mode (-AsPilot): pilots use the same PF-IMP-NNN ID pool as regular improvements; the row goes to the "Active Pilots" section instead of "Current Improvement Opportunities". Initial status is always "Active". Use Update-ProcessImprovement.ps1 -NewStatus Resolved -Impact <HIGH|MEDIUM|LOW> to close a pilot (archives the linked concept doc and moves the pilot row to Completed Improvements — PF-IMP-729). See PF-PRO-030 for the pilot lifecycle design.
#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "Single")]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [ValidateLength(3, 200)]
    [string]$Source,

    [Parameter(Mandatory = $false, ParameterSetName = "Single")]
    [string]$SourceLink = "",

    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
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

    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [ValidateSet("HIGH", "MEDIUM", "LOW")]
    [string]$Priority,

    [Parameter(Mandatory = $false, ParameterSetName = "Single")]
    [ValidateScript({
            if ($_.Length -gt 2000) {
                $over = $_.Length - 2000
                throw "Notes is too long ($($_.Length) chars; maximum 2000, $over over). Trim the notes or link to a separate document for detailed context."
            }
            $true
        })]
    [string]$Notes = "",

    [Parameter(Mandatory = $false, ParameterSetName = "Single")]
    [ValidateSet("NeedsPrioritization", "NeedsImplementation")]
    [string]$Status = "NeedsPrioritization",

    [Parameter(Mandatory = $true, ParameterSetName = "Batch")]
    [ValidateScript({ Test-Path $_ })]
    [string]$BatchFile,

    # --- Pilot mode (PF-PRO-030 — Framework Extension Pilot Tracking) ---
    [Parameter(Mandatory = $true, ParameterSetName = "Pilot")]
    [switch]$AsPilot,

    [Parameter(Mandatory = $true, ParameterSetName = "Pilot")]
    [ValidatePattern('^PF-PRO-\d+$')]
    [string]$SourceConcept,

    [Parameter(Mandatory = $true, ParameterSetName = "Pilot")]
    [ValidatePattern('^PF-TSK-\d+$')]
    [string]$OriginatingTask,

    [Parameter(Mandatory = $true, ParameterSetName = "Pilot")]
    [ValidateLength(3, 500)]
    [string]$Adopters,

    [Parameter(Mandatory = $true, ParameterSetName = "Pilot")]
    [ValidateLength(10, 500)]
    [string]$SuccessCriteria,

    [Parameter(Mandatory = $true, ParameterSetName = "Pilot")]
    [ValidateLength(3, 200)]
    [string]$DecisionTrigger,

    [Parameter(Mandatory = $false, ParameterSetName = "Pilot")]
    [ValidateScript({
            if ($_.Length -gt 2000) {
                $over = $_.Length - 2000
                throw "Notes is too long ($($_.Length) chars; maximum 2000, $over over)."
            }
            $true
        })]
    [string]$PilotNotes = "",

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

# Soak verification (PF-PRO-028 — see process-framework/state-tracking/permanent/script-soak-tracking.md)
$soakScriptId = "process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1"
$soakInSoak   = Test-ScriptInSoak -ScriptId $soakScriptId -ScriptPath $PSCommandPath

# Configuration
$ProjectRoot = Get-ProjectRoot
$TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "process-framework-local/state-tracking/permanent/process-improvement-tracking.md"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

if (-not (Test-Path $TrackingFile)) {
    Write-ProjectError -Message "Tracking file not found: $TrackingFile" -ExitCode 1
}

# Display name mapping (ValidateSet value → human-readable status text in tracking file)
$StatusDisplayNames = @{
    "NeedsPrioritization" = "Needs Prioritization"
    "NeedsImplementation" = "Needs Implementation"
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

    # Auto-escape unescaped pipes for markdown table cell safety (PF-IMP-725).
    # Update-ProcessImprovement.ps1 enforces this with a malformed-row error;
    # escaping on intake avoids the fix-before-claim recovery detour. Negative
    # lookbehind preserves any pipes already escaped as \|; HTML-entity escapes
    # (&#124;) are unaffected since they contain no literal |.
    $ItemDescription = $ItemDescription -replace '(?<!\\)\|', '\|'
    $ItemNotes = $ItemNotes -replace '(?<!\\)\|', '\|'

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
    $displayStatus = $StatusDisplayNames[$ItemStatus]
    $TableRow = "| $ImprovementId | $SourceColumn | $ItemDescription | $ItemPriority | $displayStatus | $CurrentDate | $ItemNotes |"

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

    # Retry-on-IOException absorbs LinkWatcher contention (PF-IMP-718)
    Invoke-FileWriteWithRetry -Context (Split-Path $TrackingFile -Leaf) -ScriptBlock {
        Set-Content -Path $TrackingFile -Value $updatedContent -NoNewline -Encoding UTF8
    }

    # Read-after-write verification: confirm the new IMP row landed in Current Improvement Opportunities
    if (-not $WhatIfPreference) {
        $rowPattern = "\|\s*" + [regex]::Escape($ImprovementId) + "\s*\|"
        Assert-LineInFile -Path $TrackingFile -Pattern $rowPattern -Context "tracking row for $ImprovementId in Current Improvement Opportunities"
    }

    return @{
        Id = $ImprovementId
        Source = $ItemSource
        Priority = $ItemPriority
        Status = $ItemStatus
        Notes = $ItemNotes
    }
}

# --- Core logic: add a pilot row to Active Pilots section (PF-PRO-030) ---
function Add-SinglePilot {
    param(
        [string]$ItemSourceConcept,
        [string]$ItemOriginatingTask,
        [string]$ItemAdopters,
        [string]$ItemSuccessCriteria,
        [string]$ItemDecisionTrigger,
        [string]$ItemNotes,
        [string]$ItemUpdatedBy
    )

    # Generate unique pilot ID using the central registry — same PF-IMP pool as regular improvements
    $PilotId = New-ProjectId -Prefix "PF-IMP" -Description "Pilot: $ItemSourceConcept ($ItemOriginatingTask)"

    Write-Host "Adding pilot: $PilotId" -ForegroundColor Yellow
    Write-Host "Source concept: $ItemSourceConcept" -ForegroundColor Cyan
    Write-Host "Originating task: $ItemOriginatingTask" -ForegroundColor Cyan

    # Source column: "PF-PRO-NNN / PF-TSK-NNN" plain text
    $SourceColumn = "$ItemSourceConcept / $ItemOriginatingTask"

    # Build the table row — 8-column pilot schema:
    # | ID | Source | Started | Adopters | Success Criteria | Decision Trigger | Status | Notes |
    $TableRow = "| $PilotId | $SourceColumn | $CurrentDate | $ItemAdopters | $ItemSuccessCriteria | $ItemDecisionTrigger | Active | $ItemNotes |"

    # Read current content
    $Content = Get-Content -Path $TrackingFile -Raw -Encoding UTF8
    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # Find insertion point in the Active Pilots section
    $insertAfterIndex = -1
    $inActivePilotsSection = $false
    $sectionFound = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Active Pilots") {
            $inActivePilotsSection = $true
            $sectionFound = $true
        }
        if ($inActivePilotsSection) {
            # Match any IMP row in the section
            if ($lines[$i] -match "^\|\s*(IMP|PF-IMP)-\d+") { $insertAfterIndex = $i }
            # Stop at the next section
            if ($lines[$i] -match "^## " -and $lines[$i] -notmatch "^## Active Pilots") { break }
        }
    }

    if (-not $sectionFound) {
        Write-ProjectError -Message "Active Pilots section not found in $TrackingFile. Add the section before registering pilots (see PF-PRO-030)." -ExitCode 1
    }

    # If no data rows yet, insert after the table header separator
    if ($insertAfterIndex -eq -1) {
        $inActivePilotsSection = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^## Active Pilots") { $inActivePilotsSection = $true }
            if ($inActivePilotsSection -and $lines[$i] -match "^\|\s*-") {
                $insertAfterIndex = $i
                break
            }
        }
    }

    if ($insertAfterIndex -eq -1) {
        Write-ProjectError -Message "Could not find insertion point in Active Pilots table (header separator missing)."
        return $null
    }

    $lines.Insert($insertAfterIndex + 1, $TableRow)
    Write-Host "Inserted $PilotId into Active Pilots table" -ForegroundColor Green

    # Add Update History entry
    $HistoryNote = "Registered pilot $PilotId for $ItemSourceConcept ($ItemOriginatingTask)"
    $historyInsertIndex = -1
    $inHistorySection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Update History") { $inHistorySection = $true }
        if ($inHistorySection -and $lines[$i] -match "^\|[^-]" -and $lines[$i] -notmatch "^\|\s*Date") {
            $historyInsertIndex = $i
        }
    }

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

    # Retry-on-IOException absorbs LinkWatcher contention (PF-IMP-718)
    Invoke-FileWriteWithRetry -Context (Split-Path $TrackingFile -Leaf) -ScriptBlock {
        Set-Content -Path $TrackingFile -Value $updatedContent -NoNewline -Encoding UTF8
    }

    # Read-after-write verification
    if (-not $WhatIfPreference) {
        $rowPattern = "\|\s*" + [regex]::Escape($PilotId) + "\s*\|"
        Assert-LineInFile -Path $TrackingFile -Pattern $rowPattern -Context "pilot row for $PilotId in Active Pilots"
    }

    return @{
        Id = $PilotId
        SourceConcept = $ItemSourceConcept
        OriginatingTask = $ItemOriginatingTask
        Status = "Active"
    }
}

# --- Dispatch: Pilot vs Batch vs Single mode ---
if ($PSCmdlet.ParameterSetName -eq "Pilot") {
    if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Register pilot for $SourceConcept ($OriginatingTask) in Active Pilots")) {
        return
    }

    try {
        $result = Add-SinglePilot `
            -ItemSourceConcept $SourceConcept `
            -ItemOriginatingTask $OriginatingTask `
            -ItemAdopters $Adopters `
            -ItemSuccessCriteria $SuccessCriteria `
            -ItemDecisionTrigger $DecisionTrigger `
            -ItemNotes $PilotNotes `
            -ItemUpdatedBy $UpdatedBy

        if ($result) {
            $details = @(
                "ID: $($result.Id)",
                "Source: $SourceConcept / $OriginatingTask",
                "Adopters: $Adopters",
                "Decision Trigger: $DecisionTrigger",
                "Status: Active"
            )
            if ($PilotNotes -ne "") { $details += "Notes: $PilotNotes" }

            Write-ProjectSuccess -Message "Registered pilot: $($result.Id)" -Details $details

            Write-Verbose "Next Steps: Pilot is in 'Active' status; resolve via Update-ProcessImprovement.ps1 -NewStatus Resolved when the decision trigger fires"
            Write-Verbose "Next Steps: Concept doc archive will be triggered automatically on Resolved"

            if ($soakInSoak) {
                Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
            }
        }
    }
    catch {
        if ($soakInSoak) {
            $soakErrMsg = $_.Exception.Message
            if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
            Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome failure -Notes $soakErrMsg
        }
        Write-ProjectError -Message "Failed to register pilot: $($_.Exception.Message)" -ExitCode 1
    }

} elseif ($PSCmdlet.ParameterSetName -eq "Batch") {
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
    $validStatuses = @("NeedsPrioritization", "NeedsImplementation")
    for ($idx = 0; $idx -lt $items.Count; $idx++) {
        $item = $items[$idx]
        $errors = @()
        if (-not $item.Source) { $errors += "missing Source" }
        elseif ($item.Source.Length -lt 3) { $errors += "Source is too short ($($item.Source.Length) chars; minimum 3)" }
        elseif ($item.Source.Length -gt 200) {
            $over = $item.Source.Length - 200
            $errors += "Source is too long ($($item.Source.Length) chars; maximum 200, $over over) — shorten the source label"
        }
        if (-not $item.Description) { $errors += "missing Description" }
        elseif ($item.Description.Length -lt 10) { $errors += "Description is too short ($($item.Description.Length) chars; minimum 10) — provide a more substantive description" }
        elseif ($item.Description.Length -gt 500) {
            $over = $item.Description.Length - 500
            $errors += "Description is too long ($($item.Description.Length) chars; maximum 500, $over over) — for table-row brevity, compress the description and move detailed context to the Notes field"
        }
        if ($item.Notes -and $item.Notes.Length -gt 2000) {
            $over = $item.Notes.Length - 2000
            $errors += "Notes is too long ($($item.Notes.Length) chars; maximum 2000, $over over) — trim the notes or link to a separate document for detailed context"
        }
        if (-not $item.Priority) { $errors += "missing Priority" }
        elseif ($item.Priority -notin $validPriorities) { $errors += "invalid Priority '$($item.Priority)' (must be HIGH, MEDIUM, or LOW)" }
        if ($item.Status -and $item.Status -notin $validStatuses) { $errors += "invalid Status '$($item.Status)' (must be NeedsPrioritization or NeedsImplementation)" }
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
            -ItemStatus $(if ($item.Status) { $item.Status } else { "NeedsPrioritization" }) `
            -ItemUpdatedBy $UpdatedBy

        if ($result) {
            $created += $result
            Write-Host ""
        }
    }

    Write-Host "========================================" -ForegroundColor Magenta
    Write-ProjectSuccess -Message "Batch complete: $($created.Count)/$($items.Count) improvements created" -Details ($created | ForEach-Object { "$($_.Id): $($_.Priority)" })

    if ($soakInSoak) {
        Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
    }

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

            Write-Verbose "Next Steps: Use Process Improvement task (PF-TSK-009) to implement this improvement"
            Write-Verbose "Next Steps: Use Update-ProcessImprovement.ps1 to change status later"

            if ($soakInSoak) {
                Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
            }
        }
    }
    catch {
        if ($soakInSoak) {
            $soakErrMsg = $_.Exception.Message
            if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
            Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome failure -Notes $soakErrMsg
        }
        Write-ProjectError -Message "Failed to create improvement entry: $($_.Exception.Message)" -ExitCode 1
    }
}
