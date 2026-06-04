# Update-PendingMigration.ps1
# Atomic resolve-helper for a single Pending Migration Entry in a project's per-project ledger
# (appdev/process-framework-central/per-project-migrations/<PRJ-NNN>/pending-migrations.md).
# Flips one MIG-NNN's Status in BOTH places it lives — the Summary-table row and the per-entry
# "| Field | Value |" block — in one write, so the two sites can never drift (PF-IMP-932).

<#
.SYNOPSIS
    Resolves (or skips) a single Pending Migration Entry, updating the Summary-table row and the per-entry section atomically so their Status fields cannot drift.

.DESCRIPTION
    Sibling of New-PendingMigration.ps1 (PF-IMP-931). Where that script SCAFFOLDS a migration
    entry, this one CLOSES it. A pending-migrations.md ledger records each migration's Status in
    two places:

      1. The Summary table row:   | MIG-NNN | Title | Status | Source FW Version | Backward-compatible | Resolved |
      2. The per-entry section:   ### MIG-NNN: ...  →  | **Status** | Open | (+ optional **Resolved** / **Resolved By** rows)

    Framework Rollout Mode C (PF-TSK-088) applies a migration to a project, then must mark it
    Resolved in BOTH sites. Done by hand, the two can drift (summary says Resolved, per-entry
    still Open, or vice versa). This helper performs the dual-write in a single read-modify-write,
    eliminating drift at the root (the rejected alternative — a Validate-StateTracking "pending vs
    applied" count check — had no independent machine-readable "applied" signal to compare against;
    PF-IMP-932 decision 2026-05-29).

    For -NewStatus Resolved the helper also stamps the per-entry **Resolved** (date) and
    **Resolved By** rows (inserting them after **Created** when absent — script-scaffolded Open
    entries don't carry them) and writes the Resolved date into the Summary row's Resolved column.
    For -NewStatus Skipped it flips only the Status fields (Skipped entries carry no resolution date
    per the Pending Migration Entry Template, PF-TEM-079).

    Drift repair: if the two Status sites already disagree when the helper runs, it WARNs and sets
    BOTH to the requested status — so an existing drift is corrected rather than perpetuated. If
    both sites already hold the requested status, the helper reports an idempotent no-op and writes
    nothing.

.PARAMETER Project
    The target project ID whose ledger holds the entry (e.g., PRJ-002).

.PARAMETER MigrationId
    The migration entry ID to resolve (e.g., MIG-018). Per-project scoped.

.PARAMETER NewStatus
    Resolved (default) or Skipped — the terminal status to set in both sites. Open is the initial
    status written by New-PendingMigration.ps1 and is not a valid target here.

.PARAMETER ResolvedBy
    The "Resolved By" attribution recorded in the per-entry section (e.g.,
    "PRJ-002 Mode C 2026-06-02 (TimeTrackingV2)"). Required when -NewStatus is Resolved; ignored
    for Skipped.

.PARAMETER ResolvedDate
    The resolution date (YYYY-MM-DD) stamped into the Summary Resolved column and the per-entry
    **Resolved** row. Defaults to today. Override to back-date an entry applied earlier.

.PARAMETER LedgerFile
    Escape hatch: full path to the pending-migrations.md ledger. Defaults to the central path
    resolved via Get-CentralFrameworkPath
    (<central>/per-project-migrations/<Project>/pending-migrations.md). Override only for tests or
    non-default layouts.

.EXAMPLE
    # Mark a migration Resolved after Mode C applied it (the common case):
    Update-PendingMigration.ps1 -Project PRJ-002 -MigrationId MIG-018 -ResolvedBy "PRJ-002 Mode C 2026-06-02 (TimeTrackingV2)"

.EXAMPLE
    # Mark a migration Skipped (not applicable to this project):
    Update-PendingMigration.ps1 -Project PRJ-002 -MigrationId MIG-018 -NewStatus Skipped

.NOTES
    - Consumed by Framework Rollout Mode C (PF-TSK-088) as the prescribed resolve step.
    - Soak-verified (PF-PRO-028): newly created/hash-changed; accrues soak over real invocations.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^PRJ-[A-Z]*\d+$')]
    [string]$Project,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^MIG-\d+$')]
    [string]$MigrationId,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Resolved", "Skipped")]
    [string]$NewStatus = "Resolved",

    [Parameter(Mandatory = $false)]
    [string]$ResolvedBy,

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$ResolvedDate,

    [Parameter(Mandatory = $false)]
    [string]$LedgerFile
)

# --- Import common helpers (walk up to Common-ScriptHelpers.psm1) ---
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
Invoke-StandardScriptInitialization

# Soak verification (PF-PRO-028; normalized ScriptId per PF-PRO-032)
$soakScriptId = "scripts/update/Update-PendingMigration.ps1"
$soakInSoak   = Test-ScriptInSoak -ScriptId $soakScriptId -ScriptPath $PSCommandPath

if (-not $ResolvedDate) { $ResolvedDate = Get-Date -Format "yyyy-MM-dd" }
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

# ---------------------------------------------------------------------------
# Helpers (declared before use — PowerShell does not hoist script functions)
# ---------------------------------------------------------------------------

function Get-LedgerPath {
    param([string]$ProjectId, [string]$Override)
    if ($Override) { return $Override }
    $central = Get-CentralFrameworkPath
    return Join-Path -Path $central -ChildPath "per-project-migrations/$ProjectId/pending-migrations.md"
}

function Get-SummaryRowIndex {
    # Returns the absolute line index of the MIG-NNN data row inside the '## Summary' table,
    # or -1 if not found. Scans only between '## Summary' and the next '## ' heading.
    param([System.Collections.Generic.List[string]]$Lines, [string]$MigId)
    $inSummary = $false
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^##\s+Summary\b') { $inSummary = $true; continue }
        if ($inSummary) {
            if ($Lines[$i] -match '^##\s') { break }
            if ($Lines[$i] -match ('^\|\s*' + [regex]::Escape($MigId) + '\s*\|')) { return $i }
        }
    }
    return -1
}

function Get-EntryBounds {
    # Returns @{ Start; End } absolute line indices for the '### MIG-NNN: ...' entry section.
    # Start = heading line; End = exclusive (first line of the next ### / ## section, or count).
    # Returns $null if the heading is not found.
    param([System.Collections.Generic.List[string]]$Lines, [string]$MigId)
    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match ('^###\s+' + [regex]::Escape($MigId) + '\b')) { $start = $i; break }
    }
    if ($start -eq -1) { return $null }
    $end = $Lines.Count
    for ($i = $start + 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^###\s' -or $Lines[$i] -match '^##\s') { $end = $i; break }
    }
    return @{ Start = $start; End = $end }
}

function Find-FieldRow {
    # Returns the absolute index of the '| **<Field>** | ... |' row within [Start,End), or -1.
    param([System.Collections.Generic.List[string]]$Lines, [int]$Start, [int]$End, [string]$Field)
    for ($i = $Start; $i -lt $End; $i++) {
        if ($Lines[$i] -match ('^\|\s*\*\*' + [regex]::Escape($Field) + '\*\*\s*\|')) { return $i }
    }
    return -1
}

function Get-FieldValue {
    # Extracts the trimmed value cell from a '| **Field** | value |' row.
    param([string]$Line)
    $cells = Split-MarkdownTableRow $Line
    if ($cells -and $cells.Count -ge 2) { return $cells[1].Trim() }
    return ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    if ($NewStatus -eq "Resolved" -and -not $ResolvedBy) {
        Write-ProjectError -Message "-ResolvedBy is required when -NewStatus is Resolved (e.g. 'PRJ-002 Mode C $CurrentDate (<name>)')." -ExitCode 1
    }

    $ledgerPath = Get-LedgerPath -ProjectId $Project -Override $LedgerFile
    if (-not (Test-Path $ledgerPath)) {
        Write-ProjectError -Message "Ledger not found for ${Project}: $ledgerPath — register the project (Register-Project.ps1) or create its pending-migrations.md first." -ExitCode 1
    }

    $content = Get-Content -Path $ledgerPath -Raw -Encoding UTF8
    $lines = [System.Collections.Generic.List[string]]@($content -split "\r?\n")

    # --- Locate both Status sites ---
    $summaryIdx = Get-SummaryRowIndex -Lines $lines -MigId $MigrationId
    if ($summaryIdx -eq -1) {
        Write-ProjectError -Message "$MigrationId has no Summary-table row in $ledgerPath." -ExitCode 1
    }
    $summaryCells = Split-MarkdownTableRow $lines[$summaryIdx]
    if ($null -eq $summaryCells -or $summaryCells.Count -ne 6) {
        $n = if ($null -eq $summaryCells) { 0 } else { $summaryCells.Count }
        Write-ProjectError -Message "Malformed Summary row for $MigrationId in $ledgerPath`: expected 6 columns (ID | Title | Status | Source FW Version | Backward-compatible | Resolved), found $n." -ExitCode 1
    }

    $bounds = Get-EntryBounds -Lines $lines -MigId $MigrationId
    if ($null -eq $bounds) {
        Write-ProjectError -Message "$MigrationId has a Summary row but no '### ${MigrationId}:' entry section in $ledgerPath." -ExitCode 1
    }
    $statusIdx = Find-FieldRow -Lines $lines -Start $bounds.Start -End $bounds.End -Field "Status"
    $createdIdx = Find-FieldRow -Lines $lines -Start $bounds.Start -End $bounds.End -Field "Created"
    if ($statusIdx -eq -1) {
        Write-ProjectError -Message "$MigrationId entry section has no '| **Status** | ... |' row in $ledgerPath." -ExitCode 1
    }
    if ($createdIdx -eq -1) {
        Write-ProjectError -Message "$MigrationId entry section has no '| **Created** | ... |' row (needed as the insertion anchor for Resolved/Resolved By)." -ExitCode 1
    }

    $summaryStatus = $summaryCells[2].Trim()
    $entryStatus   = Get-FieldValue -Line $lines[$statusIdx]

    # --- Drift + idempotency reporting ---
    if ($summaryStatus -ne $entryStatus) {
        Write-Warning "$MigrationId drift detected — Summary Status='$summaryStatus' but per-entry Status='$entryStatus'. Repairing both to '$NewStatus'."
    }
    if ($summaryStatus -eq $NewStatus -and $entryStatus -eq $NewStatus) {
        Write-Warning "$MigrationId is already '$NewStatus' in both sites — no changes written (idempotent)."
        if ($soakInSoak) { Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success }
        return
    }

    if (-not $PSCmdlet.ShouldProcess($ledgerPath, "Set $MigrationId -> $NewStatus")) {
        return
    }

    # --- 1. Summary row: Status (idx 2) + Resolved (idx 5) ---
    $summaryCells[2] = $NewStatus
    if ($NewStatus -eq "Resolved") { $summaryCells[5] = $ResolvedDate }
    $lines[$summaryIdx] = ConvertTo-MarkdownTableRow -Cells $summaryCells

    # --- 2. Per-entry section: Status field, plus Resolved / Resolved By rows on Resolve ---
    # Re-derive bounds is unnecessary (Status/Created indices are above any rows we touch).
    $lines[$statusIdx] = "| **Status** | $NewStatus |"

    if ($NewStatus -eq "Resolved") {
        # Normalize: remove any existing **Resolved** / **Resolved By** rows, then insert fresh
        # ones immediately after **Created**. Both rows live below **Created**, so removing them
        # never shifts $createdIdx. Remove the higher index first.
        $resolvedByIdx = Find-FieldRow -Lines $lines -Start $bounds.Start -End $bounds.End -Field "Resolved By"
        $resolvedIdx   = Find-FieldRow -Lines $lines -Start $bounds.Start -End $bounds.End -Field "Resolved"
        $toRemove = @($resolvedByIdx, $resolvedIdx | Where-Object { $_ -ge 0 } | Sort-Object -Descending)
        foreach ($idx in $toRemove) { $lines.RemoveAt($idx) }

        $resolvedByValue = $ResolvedBy -replace '(?<!\\)\|', '\|'
        # Insert in reverse so the final order is: Created, Resolved, Resolved By.
        $lines.Insert($createdIdx + 1, "| **Resolved By** | $resolvedByValue |")
        $lines.Insert($createdIdx + 1, "| **Resolved** | $ResolvedDate |")
    }

    # --- Bump frontmatter updated date ---
    $updatedContent = ($lines -join "`r`n")
    $updatedContent = $updatedContent -replace '(?m)(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate

    # Retry-on-IOException absorbs LinkWatcher contention (PF-IMP-718)
    Invoke-FileWriteWithRetry -Context (Split-Path $ledgerPath -Leaf) -ScriptBlock {
        Set-Content -Path $ledgerPath -Value $updatedContent -NoNewline -Encoding UTF8
    }

    if (-not $WhatIfPreference) {
        $rowPattern = "\|\s*" + [regex]::Escape($MigrationId) + "\s*\|.*\|\s*" + [regex]::Escape($NewStatus) + "\s*\|"
        Assert-LineInFile -Path $ledgerPath -Pattern $rowPattern -Context "summary row for $MigrationId set to $NewStatus in $Project ledger"
    }

    Write-Host "  $Project $MigrationId -> $NewStatus" -ForegroundColor Green
    if ($soakInSoak) { Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome failure -Notes $soakErrMsg
    }
    Write-ProjectError -Message "Failed to update migration entry: $($_.Exception.Message)" -ExitCode 1
}
