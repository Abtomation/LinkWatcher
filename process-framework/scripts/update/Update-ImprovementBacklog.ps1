#!/usr/bin/env pwsh

# Update-ImprovementBacklog.ps1
# Automates Improvement Backlog row operations (add / promote / remove / expiry sweep)
# in the central improvement-backlog.md (PF-IMP-1882).

<#
.SYNOPSIS
    Automates Improvement Backlog operations — adds a below-materiality-bar candidate with a
    computed counter, promotes a matched row into the IMP tracker's Intake, removes a row, or
    runs the per-source-task expiry sweep (PF-IMP-1882).

.DESCRIPTION
    Script support for the Tools Review (PF-TSK-010) materiality-bar procedure over the central
    improvement-backlog.md (PF-STA-056).

    -Add (default set): appends a candidate row. The Counter is computed, not supplied — the
    highest existing Counter among rows with the same Source Task (0 if none) plus
    -FormsEvaluated (how many of that task's feedback forms this cycle evaluated). Rows filed
    by the SAME cycle (same Source + Source Task) share one odometer reading: when such a row
    already exists, the new row reuses its Counter instead of re-adding -FormsEvaluated —
    otherwise a cycle backlogging several candidates would inflate the counter once per row
    and the expiry sweep would fire early. The BKL-NNN id is minted as the highest id in the
    file plus one (ids are never reused; gaps from promotion/expiry are expected). The row is
    built header-driven and verified against the table header after the write.

    -Promote: files a fresh IMP into the central tracker's Intake via New-ProcessImprovement.ps1
    (Description taken from the backlog row; Notes carrying [BACKLOG-PROMOTED BKL-NNN], the
    first report's source and counter, the second report's source, and the row's own notes),
    then deletes the backlog row. Filing happens before deletion, so a failed filing leaves the
    row in place.

    -Remove: deletes a row without filing (e.g. a candidate withdrawn by the owner).

    -ExpireSweep: for one Source Task, computes the current high-water counter (highest existing
    Counter for that task, plus -FormsEvaluated when this session appended no rows for it) and
    deletes every row of that task whose Counter sits 100 or more behind it.

    Updates the following file:
    - process-framework-central/state-tracking/permanent/improvement-backlog.md (resolved via
      Get-CentralFrameworkPath; override with -BacklogPath for tests/direct callers)

.PARAMETER Description
    (Add) The candidate's description. 10-500 characters — New-ProcessImprovement's cap, so a
    later promotion can pass it through unchanged.

.PARAMETER SourceTask
    (Add, ExpireSweep) The task id the originating feedback forms were about (e.g. PF-TSK-009).
    Keys the counter computation and the expiry sweep.

.PARAMETER Source
    (Add) The Tools Review cycle backlogging the candidate. (Promote) The second report's source.

.PARAMETER AffectedArtifact
    (Add) The file/script/task the suggestion targets — the match-check and filter key.

.PARAMETER FormsEvaluated
    (Add) Number of the Source Task's forms this cycle evaluated — added to the task's highest
    existing Counter to produce the new row's Counter. Applied once per cycle: further -Add
    calls with the same Source + Source Task reuse the first row's Counter. (ExpireSweep)
    Optional: pass it when the session appended no rows for the task so the high-water still
    advances; omit it (0) when rows were appended this session, whose Counter already carries
    it.

.PARAMETER Project
    (Add) Originating project cell. Defaults to the filing workspace's own identity derived
    from doc/project-config.json — "<project_id> (<project.name>)" — never a literal, so the
    default survives identity switches (PF-PRO-068 P-13).

.PARAMETER Notes
    (Add) Row notes. (Promote) Extra context appended to the promoted IMP's Notes.

.PARAMETER Promote
    Selects the promote operation (requires -BklId and -Source).

.PARAMETER Remove
    Selects the remove operation (requires -BklId).

.PARAMETER ExpireSweep
    Selects the expiry sweep (requires -SourceTask).

.PARAMETER BklId
    (Promote, Remove) The backlog row id, e.g. "BKL-007".

.PARAMETER SourceLink
    (Promote) Optional -SourceLink passed through to New-ProcessImprovement.ps1.

.PARAMETER Reason
    (Remove) Optional reason, echoed in the summary line for the session record.

.PARAMETER BacklogPath
    Optional explicit path to improvement-backlog.md, bypassing central resolution (for tests
    and direct callers).

.PARAMETER TrackingFile
    (Promote) Optional -TrackingFile passthrough to New-ProcessImprovement.ps1 (for tests).

.EXAMPLE
    Update-ImprovementBacklog.ps1 -Description "Consider a caption on the X table" -SourceTask "PF-TSK-009" -Source "Tools Review 2026-07-29" -AffectedArtifact "some-guide.md" -FormsEvaluated 30 -Confirm:$false

.EXAMPLE
    Update-ImprovementBacklog.ps1 -Promote -BklId "BKL-003" -Source "Tools Review 2026-08-02" -Confirm:$false

.EXAMPLE
    Update-ImprovementBacklog.ps1 -ExpireSweep -SourceTask "PF-TSK-009" -Confirm:$false

.NOTES
    Part of the framework feedback chain; integrates with Tools Review (PF-TSK-010) and the
    Improvement Backlog state file (PF-STA-056). Introduced by PF-IMP-1882.
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Add')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Add')]
    [ValidateLength(10, 500)]
    [string]$Description,

    [Parameter(Mandatory = $true, ParameterSetName = 'Add')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Expire')]
    [ValidatePattern('^[A-Z]{2,4}-TSK-\d+$')]
    [string]$SourceTask,

    [Parameter(Mandatory = $true, ParameterSetName = 'Add')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Promote')]
    [ValidateLength(3, 200)]
    [string]$Source,

    [Parameter(Mandatory = $true, ParameterSetName = 'Add')]
    [ValidateLength(3, 200)]
    [string]$AffectedArtifact,

    [Parameter(Mandatory = $true, ParameterSetName = 'Add')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Expire')]
    [ValidateRange(0, 100000)]
    [int]$FormsEvaluated = 0,

    [Parameter(ParameterSetName = 'Add')]
    [ValidateLength(3, 100)]
    [string]$Project,

    [Parameter(ParameterSetName = 'Add')]
    [Parameter(ParameterSetName = 'Promote')]
    [string]$Notes,

    [Parameter(Mandatory = $true, ParameterSetName = 'Promote')]
    [switch]$Promote,

    [Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
    [switch]$Remove,

    [Parameter(Mandatory = $true, ParameterSetName = 'Expire')]
    [switch]$ExpireSweep,

    [Parameter(Mandatory = $true, ParameterSetName = 'Promote')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
    [ValidatePattern('^BKL-\d+$')]
    [string]$BklId,

    [Parameter(ParameterSetName = 'Promote')]
    [string]$SourceLink,

    [Parameter(ParameterSetName = 'Remove')]
    [string]$Reason,

    [string]$BacklogPath,

    [Parameter(ParameterSetName = 'Promote')]
    [string]$TrackingFile
)

# --- Module import (robust path resolution) ---
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath '../Common-ScriptHelpers.psm1'
try {
    $resolvedModule = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedModule -Force
}
catch {
    Write-Error "Failed to import Common-ScriptHelpers: $($_.Exception.Message)"
    exit 1
}

# --- Configuration / resolution ---
$SectionHeading = '## Backlog'
$ExpiryWindow = 100

# (Add) default for -Project: the filing workspace's own identity, derived from config —
# never a literal, so the default survives identity switches (PF-PRO-068 P-13; pre-switch
# output is byte-identical: PRJ-000 (appdev) then, FWK-APP (appdev) now).
if ($PSCmdlet.ParameterSetName -eq 'Add' -and -not $Project) {
    try {
        $ownCfg = Get-ProjectConfig
        $ownName = if ($ownCfg.project -and $ownCfg.project.name) { " ($($ownCfg.project.name))" } else { "" }
        $Project = if ($ownCfg.project_id) { "$($ownCfg.project_id)$ownName" } else { 'unknown' }
    }
    catch { $Project = 'unknown' }
}

if (-not $BacklogPath) {
    $central = Get-CentralFrameworkPath
    $BacklogPath = Join-Path -Path $central -ChildPath 'state-tracking/permanent/improvement-backlog.md'
}
if (-not (Test-Path -LiteralPath $BacklogPath)) {
    Write-Error "Improvement Backlog not found: $BacklogPath"
    exit 1
}

# --- Helper functions ---

function Get-CounterValue {
    # Parses a row's Counter cell to an int; non-numeric cells count as 0.
    param($Row)
    $c = 0
    [void][int]::TryParse([string]$Row.Counter, [ref]$c)
    return $c
}

function Get-TaskMaxCounter {
    # Highest Counter among rows with the given Source Task (0 if none).
    param([object[]]$Rows, [string]$Task)
    $max = 0
    foreach ($r in @($Rows | Where-Object { $_.'Source Task' -eq $Task })) {
        $c = Get-CounterValue -Row $r
        if ($c -gt $max) { $max = $c }
    }
    return $max
}

function Remove-BacklogRowLines {
    # Returns $Lines minus the table rows whose first cell is one of $Ids.
    # Throws unless each id matches exactly one line — a 0-match delete is a silent no-op and a
    # multi-match delete would take out more than intended.
    param([string[]]$Lines, [string[]]$Ids)
    $out = [System.Collections.Generic.List[string]]::new()
    $hitCounts = @{}
    foreach ($id in $Ids) { $hitCounts[$id] = 0 }
    foreach ($line in $Lines) {
        $isTarget = $false
        foreach ($id in $Ids) {
            if ($line -match ('^\|\s*' + [regex]::Escape($id) + '\s*\|')) {
                $hitCounts[$id]++
                $isTarget = $true
                break
            }
        }
        if (-not $isTarget) { $out.Add($line) }
    }
    foreach ($id in $Ids) {
        if ($hitCounts[$id] -ne 1) {
            throw "Expected exactly one table row for $id, found $($hitCounts[$id]) — no rows were removed."
        }
    }
    return , $out.ToArray()
}

function Get-BacklogTableInsertIndex {
    # Index in $Lines AFTER which a new row should be inserted: the last consecutive table line
    # (header, separator, or row) following the section heading. Throws if the table is missing.
    param([string[]]$Lines, [string]$Heading)
    $headingIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].Trim() -eq $Heading) { $headingIdx = $i; break }
    }
    if ($headingIdx -lt 0) { throw "Section heading '$Heading' not found in the backlog file." }
    $tableStart = -1
    for ($i = $headingIdx + 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\|') { $tableStart = $i; break }
        if ($Lines[$i] -match '^#{1,2}\s') { break }
    }
    if ($tableStart -lt 0) { throw "No table found under '$Heading'." }
    $last = $tableStart
    for ($i = $tableStart; $i -lt $Lines.Count -and $Lines[$i] -match '^\|'; $i++) { $last = $i }
    return $last
}

# --- Main ---

$content = Get-Content -LiteralPath $BacklogPath -Raw -Encoding UTF8
$lines = $content -split "\r?\n"
$rows = @(ConvertFrom-MarkdownTable -Content $content -Section $SectionHeading)

switch ($PSCmdlet.ParameterSetName) {

    'Add' {
        $maxId = 0
        foreach ($r in $rows) {
            if ([string]$r.'BKL-ID' -match '^BKL-(\d+)$') {
                $n = [int]$Matches[1]
                if ($n -gt $maxId) { $maxId = $n }
            }
        }
        $newId = 'BKL-{0:D3}' -f ($maxId + 1)
        # Same-cycle rows (same Source + Source Task) share one odometer reading — reuse their
        # Counter instead of re-adding -FormsEvaluated once per candidate.
        $sameCycleRows = @($rows | Where-Object { $_.'Source Task' -eq $SourceTask -and $_.Source -eq $Source })
        if ($sameCycleRows.Count -gt 0) {
            $counter = Get-TaskMaxCounter -Rows $sameCycleRows -Task $SourceTask
            Write-ProjectLog "Same-cycle row(s) already filed for $SourceTask by '$Source' — reusing Counter $counter"
        }
        else {
            $counter = (Get-TaskMaxCounter -Rows $rows -Task $SourceTask) + $FormsEvaluated
        }

        $valueMap = @{
            'BKL-ID'            = $newId
            'Source'            = $Source
            'Source Task'       = $SourceTask
            'Project'           = $Project
            'Description'       = $Description
            'Affected Artifact' = $AffectedArtifact
            'Counter'           = $counter
            'Filed'             = (Get-Date -Format 'yyyy-MM-dd')
        }
        if ($Notes) { $valueMap['Notes'] = $Notes }
        $rowLine = New-HeaderDrivenTableRow -Content $content -SectionHeading $SectionHeading -ValueMap $valueMap
        $insertAfter = Get-BacklogTableInsertIndex -Lines $lines -Heading $SectionHeading

        Write-ProjectLog "Minted $newId; Counter = task max + $FormsEvaluated = $counter"
        if ($PSCmdlet.ShouldProcess($BacklogPath, "Add $newId ($SourceTask, Counter $counter)")) {
            $newLines = @($lines[0..$insertAfter]) + @($rowLine) + @(
                if ($insertAfter + 1 -lt $lines.Count) { $lines[($insertAfter + 1)..($lines.Count - 1)] })
            Set-Content -LiteralPath $BacklogPath -Value ($newLines -join "`n") -Encoding UTF8 -NoNewline
            Assert-TableRowInFile -Path $BacklogPath -Pattern ('\|\s*' + [regex]::Escape($newId) + '\s*\|') -Context "backlog row $newId"
            Write-ProjectSummary "Added $newId (Source Task $SourceTask, Counter $counter)"
            Write-Output $newId
        }
    }

    'Promote' {
        $row = $rows | Where-Object { $_.'BKL-ID' -eq $BklId } | Select-Object -First 1
        if (-not $row) {
            Write-Error "No backlog row found for $BklId"
            exit 1
        }
        $promotedNotes = "[BACKLOG-PROMOTED $BklId] First report: $($row.Source) (Counter $(Get-CounterValue -Row $row), Source Task $($row.'Source Task'), Affected Artifact $($row.'Affected Artifact')). Second report: $Source."
        if ($row.Notes -and [string]$row.Notes -notin @('—', '-', '')) { $promotedNotes += " Row notes: $($row.Notes)" }
        if ($Notes) { $promotedNotes += " $Notes" }

        $newImpScript = Join-Path -Path $scriptDir -ChildPath '../file-creation/support/New-ProcessImprovement.ps1'
        if ($PSCmdlet.ShouldProcess($BacklogPath, "Promote $BklId to Intake (New-ProcessImprovement) and delete the row")) {
            $impArgs = @{
                Source      = $Source
                Description = [string]$row.Description
                Notes       = $promotedNotes
                Confirm     = $false
                ErrorAction = 'Stop'
            }
            if ($SourceLink) { $impArgs.SourceLink = $SourceLink }
            if ($TrackingFile) { $impArgs.TrackingFile = $TrackingFile }
            try {
                $impOutput = & $newImpScript @impArgs
            }
            catch {
                Write-Error "Promotion filing failed — backlog row $BklId left in place: $($_.Exception.Message)"
                exit 1
            }
            $newImpId = @($impOutput | Where-Object { $_ -match '^PF-IMP-\d+$' })[-1]
            if (-not $newImpId) {
                Write-Error "New-ProcessImprovement produced no IMP id — backlog row $BklId left in place; verify the Intake write before retrying."
                exit 1
            }
            $newLines = Remove-BacklogRowLines -Lines $lines -Ids @($BklId)
            Set-Content -LiteralPath $BacklogPath -Value ($newLines -join "`n") -Encoding UTF8 -NoNewline
            Write-ProjectSummary "Promoted $BklId -> $newImpId (Intake row filed, backlog row deleted)"
            Write-Output $newImpId
        }
    }

    'Remove' {
        $row = $rows | Where-Object { $_.'BKL-ID' -eq $BklId } | Select-Object -First 1
        if (-not $row) {
            Write-Error "No backlog row found for $BklId"
            exit 1
        }
        $reasonSuffix = if ($Reason) { " — $Reason" } else { '' }
        if ($PSCmdlet.ShouldProcess($BacklogPath, "Remove $BklId$reasonSuffix")) {
            $newLines = Remove-BacklogRowLines -Lines $lines -Ids @($BklId)
            Set-Content -LiteralPath $BacklogPath -Value ($newLines -join "`n") -Encoding UTF8 -NoNewline
            Write-ProjectSummary "Removed $BklId$reasonSuffix"
        }
    }

    'Expire' {
        $taskRows = @($rows | Where-Object { $_.'Source Task' -eq $SourceTask })
        if ($taskRows.Count -eq 0) {
            Write-ProjectSummary "No backlog rows for $SourceTask — nothing to expire"
            break
        }
        $highWater = (Get-TaskMaxCounter -Rows $rows -Task $SourceTask) + $FormsEvaluated
        $expired = @($taskRows | Where-Object { ($highWater - (Get-CounterValue -Row $_)) -ge $ExpiryWindow })
        if ($expired.Count -eq 0) {
            Write-ProjectSummary "No rows expired for $SourceTask (high-water $highWater, window $ExpiryWindow)"
            break
        }
        $expiredIds = @($expired | ForEach-Object { [string]$_.'BKL-ID' })
        if ($PSCmdlet.ShouldProcess($BacklogPath, "Expire $($expiredIds.Count) row(s) for ${SourceTask}: $($expiredIds -join ', ')")) {
            $newLines = Remove-BacklogRowLines -Lines $lines -Ids $expiredIds
            Set-Content -LiteralPath $BacklogPath -Value ($newLines -join "`n") -Encoding UTF8 -NoNewline
            Write-ProjectSummary "Expired $($expiredIds.Count) row(s) for $SourceTask (high-water $highWater): $($expiredIds -join ', ')"
        }
    }
}
