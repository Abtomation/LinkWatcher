#!/usr/bin/env pwsh

<#
.SYNOPSIS
Updates a feature request in the Feature Request Tracking state file — a lifecycle transition, or a notes-only annotation of an open request.

.DESCRIPTION
This script automates feature request lifecycle transitions in feature-request-tracking.md.

Used by Feature Request Evaluation (PF-TSK-067) to classify and close requests, and
can also be used to defer, reject, or annotate requests.

Supports four operation modes:
1. Completion: Sets Classification and Feature columns, moves row from Active to Completed
   section, updates summary count, adds Update History entry, updates frontmatter date
2. Rejection: Marks the row's disposition (Classification = "❌ Rejected"), moves it from the
   Active table to the collapsed archive section, and recounts (PF-IMP-1220) — keeps terminal
   rejections out of the active intake view
3. Status-only update: Changes Status column in place (Deferred — postponed, may be reactivated)
4. Notes-only annotation (-AppendNotes, PF-IMP-1441): Appends to the Notes column of a request
   still in the Active table, leaving Status untouched. Use case: recording research or triage
   findings on a request before it is classified. Appends (never overwrites) and is idempotent —
   re-running with the same text is a no-op. Sibling precedent: Update-TechDebt.ps1 -EditNotes,
   which replaces rather than appends; this script appends, matching its own -Notes semantics.

For enhancements, also updates feature-tracking.md to set the target feature's status
to "Needs Enhancement" with a link to the Enhancement State Tracking File.

.PARAMETER RequestId
The feature request ID to update (e.g., "PD-FRQ-001")

.PARAMETER Classification
The classification result: "NewFeature" or "Enhancement"

.PARAMETER FeatureId
The target feature ID (e.g., "6.1.1" for enhancements, or "2.1.2" for new features)

.PARAMETER NewStatus
The new status. Valid values: Completed, Deferred, Rejected

.PARAMETER Notes
Additional notes to add to the Notes column (e.g., Enhancement State File link)

.PARAMETER AppendNotes
Text to append to the Notes column of a request still in the Active table, with no status
change (NotesEdit mode — mutually exclusive with -NewStatus). The existing Notes value is
appended to, not overwritten, and the append is idempotent: re-running with text already
present in the cell leaves the file untouched.

.PARAMETER FeatureName
Name of the new feature (new feature classification only). When provided with -Classification
"NewFeature", the script invokes New-FeatureImplementationState.ps1 to create the feature
state file and link it in feature-tracking.md.

.PARAMETER EnhancementStateFile
Path or link to the Enhancement State Tracking File (enhancement classification only).
When provided, feature-tracking.md is updated to set the target feature to "Needs Enhancement"
with a link to this file.

.PARAMETER UpdatedBy
Who performed the update (default: "AI Agent (PF-TSK-067)")

.EXAMPLE
# Classify as enhancement and complete
Update-FeatureRequest.ps1 -RequestId "PD-FRQ-001" -Classification "Enhancement" -FeatureId "6.1.1" -NewStatus "Completed" -EnhancementStateFile "Enhancement State File: [PF-STA-066](../temporary/enhancement-6-1-1-comment-filtering.md)" -Notes "Enhancement State File created"

.EXAMPLE
# Classify as new feature and complete (also creates feature state file)
Update-FeatureRequest.ps1 -RequestId "PD-FRQ-003" -Classification "NewFeature" -FeatureId "2.1.2" -FeatureName "TOML File Support" -NewStatus "Completed" -Notes "Added as feature 2.1.2 in feature-tracking.md"

.PARAMETER TrackingFile
Overrides the path to feature-request-tracking.md. Defaults to the project's
state-tracking/permanent/feature-request-tracking.md via Resolve-DocPath.

.PARAMETER FeatureTrackingFile
Overrides the path to feature-tracking.md, written when an accepted request becomes a feature.
Defaults to the project's state-tracking/permanent/feature-tracking.md via Resolve-DocPath.

.EXAMPLE
# Defer a request
Update-FeatureRequest.ps1 -RequestId "PD-FRQ-002" -NewStatus "Deferred" -Notes "Postponed until v3.0"

.EXAMPLE
# Reject a request
Update-FeatureRequest.ps1 -RequestId "PD-FRQ-004" -NewStatus "Rejected" -Notes "Out of scope for this project"

.EXAMPLE
# Annotate a still-open request with research findings (no status change)
Update-FeatureRequest.ps1 -RequestId "PD-FRQ-005" -AppendNotes "Spike found the parser already exposes a hook — see PD-TEC-001"

.NOTES
This script integrates with:
- Feature Request Evaluation (PF-TSK-067) — primary consumer
- Feature Tracking (feature-tracking.md) — updated for enhancement classifications
- Feature Enhancement (PF-TSK-068) — downstream consumer of enhancement state files

Output behavior: Default output is one summary line per invocation (the outcome,
e.g. "PD-FRQ-001 → Completed (Enhancement: 6.1.1)"), plus one extra line per
side-effect (feature state file creation). WARN and ERROR messages always pass
through. Pass -Verbose to restore the full play-by-play log for debugging.
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Lifecycle')]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^PD-FRQ-\d+$')]
    [string]$RequestId,

    [Parameter(Mandatory = $false, ParameterSetName = 'Lifecycle')]
    [ValidateSet("NewFeature", "Enhancement")]
    [string]$Classification,

    [Parameter(Mandatory = $false, ParameterSetName = 'Lifecycle')]
    [string]$FeatureId,

    [Parameter(Mandatory = $true, ParameterSetName = 'Lifecycle')]
    [ValidateSet("Completed", "Deferred", "Rejected")]
    [string]$NewStatus,

    [Parameter(Mandatory = $false, ParameterSetName = 'Lifecycle')]
    [string]$FeatureName = "",

    [Parameter(Mandatory = $false, ParameterSetName = 'Lifecycle')]
    [string]$Notes = "",

    [Parameter(Mandatory = $false, ParameterSetName = 'Lifecycle')]
    [string]$EnhancementStateFile = "",

    # --- NotesEdit parameter set (PF-IMP-1441) ---
    [Parameter(Mandatory = $true, ParameterSetName = 'NotesEdit')]
    [ValidateNotNullOrEmpty()]
    [string]$AppendNotes,

    [Parameter(Mandatory = $false)]
    [string]$UpdatedBy = "AI Agent (PF-TSK-067)",

    [Parameter(Mandatory = $false)]
    [string]$TrackingFile = "",

    [Parameter(Mandatory = $false)]
    [string]$FeatureTrackingFile = ""
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
# Temporarily silence $VerbosePreference around the import so -Verbose callers see
# only this script's own Write-Verbose output, not the helper module's internal chatter.
$prevVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
$VerbosePreference = $prevVerbosePreference

# Soak verification (PF-PRO-028 v2.0 Pattern A; caller-aware no-arg form)
Register-SoakScript
$soakInSoak = Test-ScriptInSoak

# Configuration
# project_id-aware path routing via Resolve-DocPath (PF-IMP-871 Session 3, 2026-05-14):
# fixes latent bug where these paths hardcoded `doc/...` and would break in appdev (PRJ-000),
# where doc template material lives at blueprint/doc/...
# Caller-supplied -TrackingFile / -FeatureTrackingFile override the resolved defaults
# (sandbox test entry point).
if (-not $TrackingFile) {
    $TrackingFile = Resolve-DocPath -Subpath "state-tracking/permanent/feature-request-tracking.md"
}
if (-not $FeatureTrackingFile) {
    $FeatureTrackingFile = Resolve-DocPath -Subpath "state-tracking/permanent/feature-tracking.md"
}
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

function Test-Prerequisites {
    Write-ProjectLog "Checking prerequisites..."

    if (-not (Test-Path $TrackingFile)) {
        Write-ProjectLog "Feature request tracking file not found: $TrackingFile" -Level "ERROR"
        return $false
    }

    # Validate required parameters for completion
    if ($NewStatus -eq "Completed") {
        if (-not $Classification) {
            Write-ProjectLog "Classification is required when completing a feature request" -Level "ERROR"
            return $false
        }
        if (-not $FeatureId) {
            Write-ProjectLog "FeatureId is required when completing a feature request" -Level "ERROR"
            return $false
        }
    }

    # Validate enhancement-specific parameters
    if ($Classification -eq "Enhancement" -and $EnhancementStateFile -and -not (Test-Path $FeatureTrackingFile)) {
        Write-ProjectLog "Feature tracking file not found: $FeatureTrackingFile" -Level "ERROR"
        return $false
    }

    Write-ProjectLog "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

# --- Content-transformation functions ---

function Join-RequestNote {
    # Append $New to an existing Notes-column value with a normalized separator, so a prior
    # value that already ends in '.' does not produce a '..' double period (PF-IMP-1046).
    # Empty or placeholder ('—') existing values are replaced outright (no leading separator).
    param([string]$Existing, [string]$New)
    if ($Existing -and $Existing -ne "—") {
        return "$($Existing.TrimEnd('.', ' ')). $New"
    }
    return $New
}

function Update-RequestRow {
    param(
        [string]$Content,
        [string]$RequestId,
        [string]$Classification,
        [string]$FeatureId,
        [string]$Notes
    )

    # Find the request row in the Active table (column-aware lookup)
    $rows = ConvertFrom-MarkdownTable -Content $Content -Section "## Active Feature Requests" -IncludeRawLine
    $row = $rows | Where-Object { $_.ID -eq $RequestId } | Select-Object -First 1

    if (-not $row) {
        Write-ProjectLog "Feature request not found in Active table: $RequestId" -Level "ERROR"
        return $null
    }

    $currentEntry = $row._RawLine
    Write-ProjectLog "Found feature request entry for $RequestId"

    # Parse columns: | ID | Source | Description | Feature | Classification | Status | Last Updated | Notes |
    $columns = Split-MarkdownTableRow -Line $currentEntry

    # Update columns
    if ($Classification) {
        $classLabel = if ($Classification -eq "NewFeature") { "New Feature" } else { "Enhancement" }
        $columns[4] = $classLabel
    }
    if ($FeatureId) {
        $columns[3] = $FeatureId
    }
    if ($Notes) {
        $columns[7] = Join-RequestNote -Existing $columns[7] -New $Notes
    }

    $updatedEntry = "| " + ($columns -join " | ") + " |"
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-ProjectLog "Updated $RequestId columns" -Level "SUCCESS"
    return $result
}

function Add-RequestNote {
    # NotesEdit mode (PF-IMP-1441): appends to the Notes column of a request still in the Active
    # table, leaving Status alone. Returns @{ Content; Changed } — Changed is $false when the text
    # is already present (idempotent no-op), $null on failure.
    param(
        [string]$Content,
        [string]$RequestId,
        [string]$Note
    )

    $rows = ConvertFrom-MarkdownTable -Content $Content -Section "## Active Feature Requests" -IncludeRawLine
    $row = $rows | Where-Object { $_.ID -eq $RequestId } | Select-Object -First 1

    if (-not $row) {
        Write-ProjectLog "Feature request not found in the Active table: $RequestId (notes can only be appended to an open request)" -Level "ERROR"
        return $null
    }

    $currentEntry = $row._RawLine
    $columns = Split-MarkdownTableRow -Line $currentEntry

    # Resolve the target columns by header NAME, not by fixed index — a table that gains a column
    # would otherwise silently write the note into the wrong cell (the PF-IMP-006 lesson from
    # Update-TechDebt.ps1 -EditNotes). ConvertFrom-MarkdownTable already names each row property
    # after its column, in column order, so the parsed row doubles as the header map.
    $headers = @($row.PSObject.Properties.Name | Where-Object { $_ -notlike '_*' })
    $notesIdx = [Array]::IndexOf($headers, 'Notes')
    if ($notesIdx -lt 0) {
        Write-ProjectLog "Active Feature Requests table has no 'Notes' column" -Level "ERROR"
        return $null
    }

    if ($columns[$notesIdx] -like "*$Note*") {
        Write-ProjectLog "Notes for $RequestId already contain this text — nothing to append" -Level "WARN"
        return [pscustomobject]@{ Content = $Content; Changed = $false }
    }

    $columns[$notesIdx] = Join-RequestNote -Existing $columns[$notesIdx] -New $Note

    $updatedIdx = [Array]::IndexOf($headers, 'Last Updated')
    if ($updatedIdx -ge 0) { $columns[$updatedIdx] = $CurrentDate }

    $updatedEntry = "| " + ($columns -join " | ") + " |"
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-ProjectLog "Appended notes to $RequestId" -Level "SUCCESS"
    return [pscustomobject]@{ Content = $result; Changed = $true }
}

function Move-ToCompletedSection {
    param(
        [string]$Content,
        [string]$RequestId
    )

    # Source table: | ID | Source | Description | Feature | Classification | Status | Last Updated | Notes |
    # Dest table:   | ID | Source | Description | Feature | Classification | Completed Date | Notes |
    $columnMapping = [ordered]@{
        "ID"             = "ID"
        "Source"         = "Source"
        "Description"    = "Description"
        "Feature"        = "Feature"
        "Classification" = "Classification"
        "Completed Date" = "Completed Date"
        "Notes"          = "Notes"
    }
    $additionalColumns = [ordered]@{
        "Completed Date" = $CurrentDate
    }

    $result = Move-MarkdownTableRow `
        -Content $Content `
        -RowIdPattern ([regex]::Escape($RequestId)) `
        -SourceSection "## Active Feature Requests" `
        -DestinationSection "## Completed Requests" `
        -ColumnMapping $columnMapping `
        -AdditionalColumns $additionalColumns

    if ($null -eq $result.Content) {
        Write-ProjectLog "Failed to move $RequestId to Completed section" -Level "ERROR"
        return $null
    }

    Write-ProjectLog "Moved $RequestId to Completed Requests section" -Level "SUCCESS"
    return $result.Content
}

function Update-SummaryCount {
    param([string]$Content)

    $count = 0
    $inCompletedSection = $false
    foreach ($line in ($Content -split "\r?\n")) {
        if ($line -match "^## Completed Requests") { $inCompletedSection = $true }
        if ($inCompletedSection -and $line -match "^\s*</details>") { break }
        if ($inCompletedSection -and $line -match "^\|\s*PD-FRQ-\d+") { $count++ }
    }

    $result = $Content -replace '(?<=Show completed requests \()\d+(?= items?\))', $count.ToString()

    Write-ProjectLog "Updated completed summary count to $count items" -Level "SUCCESS"
    return $result
}

function Update-HistorySummaryCount {
    param([string]$Content)

    $count = 0
    $inHistorySection = $false
    foreach ($line in ($Content -split "\r?\n")) {
        if ($line -match "^## Update History") { $inHistorySection = $true }
        if ($inHistorySection -and $line -match "^\s*</details>") { break }
        if ($inHistorySection -and $line -match "^\|\s*\d{4}-") { $count++ }
    }

    $result = $Content -replace '(?<=Show update history \()\d+(?= entries?\))', $count.ToString()

    Write-ProjectLog "Updated history summary count to $count entries" -Level "SUCCESS"
    return $result
}

function Add-UpdateHistoryEntry {
    param(
        [string]$Content,
        [string]$HistoryNote,
        [string]$UpdatedBy
    )

    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    $insertAfterIndex = -1
    $inHistorySection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Update History") { $inHistorySection = $true }
        if ($inHistorySection -and $lines[$i] -match "^\|[^-]" -and $lines[$i] -notmatch "^\|\s*Date") {
            $insertAfterIndex = $i
        }
    }

    if ($insertAfterIndex -eq -1) {
        $inHistorySection = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^## Update History") { $inHistorySection = $true }
            if ($inHistorySection -and $lines[$i] -match "^\|\s*-") {
                $insertAfterIndex = $i
                break
            }
        }
    }

    if ($insertAfterIndex -eq -1) {
        Write-ProjectLog "Could not find Update History table" -Level "ERROR"
        return $null
    }

    $historyRow = "| $CurrentDate | $HistoryNote | $UpdatedBy |"
    $lines.Insert($insertAfterIndex + 1, $historyRow)

    Write-ProjectLog "Added Update History entry" -Level "SUCCESS"
    return ($lines -join "`r`n")
}

function Update-FeatureTrackingForEnhancement {
    param(
        [string]$FeatureId,
        [string]$EnhancementStateFile
    )

    Write-ProjectLog "Updating feature-tracking.md for enhancement of feature $FeatureId..."

    $ftContent = Get-Content $FeatureTrackingFile -Raw

    # Find the feature row and update Status column to "🔄 Needs Enhancement"
    # The feature ID might be wrapped in a link: [6.1.1](path)
    $featurePattern = "\|[^\n]*(?:\[$([regex]::Escape($FeatureId))\]|$([regex]::Escape($FeatureId)))[^\n]*\|"
    $ftMatch = [regex]::Match($ftContent, $featurePattern)

    if (-not $ftMatch.Success) {
        Write-ProjectLog "Feature $FeatureId not found in feature-tracking.md" -Level "WARN"
        Write-ProjectLog "You will need to manually update feature-tracking.md" -Level "WARN"
        return
    }

    # Use Update-MarkdownTable to set status
    $ftContent = Update-MarkdownTable `
        -Content $ftContent `
        -FeatureId $FeatureId `
        -StatusColumn "Status" `
        -Status "🔄 Needs Enhancement" `
        -Notes $EnhancementStateFile

    if ($ftContent) {
        # Update frontmatter date
        $ftContent = Update-FrontmatterDate -Content $ftContent -CurrentDate $CurrentDate

        # PF-IMP-801: recompute Progress Summary — Status flip from any value to 🔄 Needs
        # Enhancement shifts the Implementation Status Overview breakdown.
        $ftContent = Update-FeatureTrackingSummary -Content $ftContent

        Set-Content -Path $FeatureTrackingFile -Value $ftContent -NoNewline
        Write-ProjectLog "Updated feature $FeatureId to 'Needs Enhancement' in feature-tracking.md" -Level "SUCCESS"
    } else {
        Write-ProjectLog "Failed to update feature-tracking.md — update manually" -Level "WARN"
    }
}

# --- Main ---

function Main {
    $isNotesEdit = $PSCmdlet.ParameterSetName -eq 'NotesEdit'

    Write-ProjectLog "Starting Feature Request Update"
    Write-ProjectLog "Request ID: $RequestId"
    if ($isNotesEdit) { Write-ProjectLog "Mode: notes-only append (no status change)" }
    else { Write-ProjectLog "New Status: $NewStatus" }
    if ($Classification) { Write-ProjectLog "Classification: $Classification" }
    if ($FeatureId) { Write-ProjectLog "Feature ID: $FeatureId" }

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    $intent = if ($isNotesEdit) { "Append notes to $RequestId" } else { "Update $RequestId to $NewStatus" }
    if (-not $PSCmdlet.ShouldProcess($TrackingFile, $intent)) {
        return
    }

    # Single read-modify-write cycle for feature-request-tracking.md
    $content = Get-Content $TrackingFile -Raw

    if ($isNotesEdit) {
        $edit = Add-RequestNote -Content $content -RequestId $RequestId -Note $AppendNotes
        if ($null -eq $edit) { exit 1 }

        if (-not $edit.Changed) {
            Write-ProjectSummary "$RequestId → notes unchanged (text already present)"
            return
        }

        $content = $edit.Content
        $content = Add-UpdateHistoryEntry -Content $content -HistoryNote "Annotated $RequestId`: $AppendNotes" -UpdatedBy $UpdatedBy
        if ($null -eq $content) { exit 1 }
        $content = Update-HistorySummaryCount -Content $content
        $content = Update-FrontmatterDate -Content $content

        Set-Content -Path $TrackingFile -Value $content -NoNewline
        Write-ProjectLog "Feature request tracking file updated successfully" -Level "SUCCESS"
        Write-ProjectSummary "$RequestId → notes appended"
        return
    }

    # Map CLI parameter values to emoji display values for the tracking file
    $StatusDisplayMap = @{
        "Completed" = "✅ Completed"
        "Deferred"  = "⏸️ Deferred"
        "Rejected"  = "❌ Rejected"
    }
    $DisplayStatus = $StatusDisplayMap[$NewStatus]

    $isCompletion = $NewStatus -eq "Completed"
    $isDeferReject = $NewStatus -in @("Deferred", "Rejected")

    if ($isCompletion) {
        # Step 1: Update Classification, Feature, and Notes columns
        $content = Update-RequestRow -Content $content -RequestId $RequestId -Classification $Classification -FeatureId $FeatureId -Notes $Notes
        if ($null -eq $content) { exit 1 }

        # Step 2: Move row from Active to Completed
        $content = Move-ToCompletedSection -Content $content -RequestId $RequestId
        if ($null -eq $content) { exit 1 }

        # Step 3: Update summary count
        $content = Update-SummaryCount -Content $content
    }
    elseif ($isDeferReject) {
        # Column-aware lookup of the Active row (shared by both the Deferred and Rejected paths).
        $rows = ConvertFrom-MarkdownTable -Content $content -Section "## Active Feature Requests" -IncludeRawLine
        $row = $rows | Where-Object { $_.ID -eq $RequestId } | Select-Object -First 1

        if (-not $row) {
            Write-ProjectLog "Feature request not found in Active table: $RequestId" -Level "ERROR"
            exit 1
        }

        $currentEntry = $row._RawLine
        $columns = Split-MarkdownTableRow -Line $currentEntry

        if ($NewStatus -eq "Rejected") {
            # Rejected requests are terminal: move them out of the Active intake view into the
            # collapsed archive so rejections don't accumulate in the active queue (PF-IMP-1220).
            # The archive table has no Status column, so the disposition rides in the
            # Classification column ("❌ Rejected") and the rejection date in Completed Date.
            $columns[4] = $DisplayStatus   # "❌ Rejected" → Classification column (carried by the move)
            if ($Notes) {
                $columns[7] = Join-RequestNote -Existing $columns[7] -New $Notes
            }
            $updatedEntry = "| " + ($columns -join " | ") + " |"
            $content = $content.Replace($currentEntry, $updatedEntry)

            # Move Active → Completed Requests (carries Classification; adds Completed Date), then
            # recount the collapsed section.
            $content = Move-ToCompletedSection -Content $content -RequestId $RequestId
            if ($null -eq $content) { exit 1 }
            $content = Update-SummaryCount -Content $content
            Write-ProjectLog "Moved $RequestId to the collapsed archive as $DisplayStatus" -Level "SUCCESS"
        }
        else {
            # Deferred requests stay in the Active table (postponed; may be reactivated later) —
            # update Status / Last Updated / Notes in place.
            $columns[5] = $DisplayStatus
            $columns[6] = $CurrentDate
            if ($Notes) {
                $columns[7] = Join-RequestNote -Existing $columns[7] -New $Notes
            }
            $updatedEntry = "| " + ($columns -join " | ") + " |"
            $content = $content.Replace($currentEntry, $updatedEntry)
            Write-ProjectLog "Updated $RequestId status to $DisplayStatus" -Level "SUCCESS"
        }
    }

    # Step 4: Add Update History entry
    $classLabel = if ($Classification -eq "NewFeature") { "New Feature" } elseif ($Classification -eq "Enhancement") { "Enhancement" } else { "" }
    $historyNote = switch ($NewStatus) {
        "Completed" { "Classified $RequestId as $classLabel (feature $FeatureId) — $DisplayStatus" }
        "Deferred"  { "Deferred $RequestId`: $Notes" }
        "Rejected"  { "Rejected $RequestId`: $Notes" }
    }

    $content = Add-UpdateHistoryEntry -Content $content -HistoryNote $historyNote -UpdatedBy $UpdatedBy
    if ($null -eq $content) { exit 1 }

    # Step 5: Update history summary count
    $content = Update-HistorySummaryCount -Content $content

    # Step 6: Update frontmatter date
    $content = Update-FrontmatterDate -Content $content

    # Single write
    Set-Content -Path $TrackingFile -Value $content -NoNewline

    Write-ProjectLog "Feature request tracking file updated successfully" -Level "SUCCESS"

    # Step 7: For enhancements, also update feature-tracking.md
    if ($isCompletion -and $Classification -eq "Enhancement" -and $EnhancementStateFile) {
        Update-FeatureTrackingForEnhancement -FeatureId $FeatureId -EnhancementStateFile $EnhancementStateFile
    }

    # Step 8: For new features, create feature implementation state file
    $stateFileCreated = $false
    if ($isCompletion -and $Classification -eq "NewFeature" -and $FeatureName) {
        $stateScript = Join-Path -Path (Get-ProcessFrameworkPath) -ChildPath "scripts/file-creation/04-implementation/New-FeatureImplementationState.ps1"
        if (Test-Path $stateScript) {
            Write-ProjectLog "Creating feature implementation state file for $FeatureId ($FeatureName)..."
            try {
                & $stateScript -FeatureName $FeatureName -FeatureId $FeatureId -Description $Notes -Confirm:$false
                Write-ProjectLog "Feature implementation state file created and linked in feature-tracking.md" -Level "SUCCESS"
                $stateFileCreated = $true
            }
            catch {
                Write-ProjectLog "Failed to create feature state file: $($_.Exception.Message)" -Level "WARN"
                Write-ProjectLog "Create it manually using New-FeatureImplementationState.ps1" -Level "WARN"
            }
        } else {
            Write-ProjectLog "New-FeatureImplementationState.ps1 not found at: $stateScript" -Level "WARN"
            Write-ProjectLog "Create the feature state file manually" -Level "WARN"
        }
    }

    # Summary line
    $summaryParts = @("$RequestId → $NewStatus")
    if ($Classification -and $FeatureId) {
        $featureSuffix = if ($FeatureName) { "$FeatureId — $FeatureName" } else { "$FeatureId" }
        $summaryParts += "(${classLabel}: $featureSuffix)"
    } elseif ($FeatureId) {
        $summaryParts += "(feature $FeatureId)"
    }
    Write-ProjectSummary ($summaryParts -join ' ')
    if ($stateFileCreated) {
        Write-ProjectSummary "Created feature state file for $FeatureId"
    }
}

# Execute main function with soak-verification wrapper (PF-PRO-028 v2.0)
try {
    Main
    if ($soakInSoak) { Confirm-SoakInvocation -Outcome success }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -Outcome failure -Notes $soakErrMsg
    }
    Write-ProjectError -Message "Feature request update failed: $($_.Exception.Message)" -ExitCode 1
}
