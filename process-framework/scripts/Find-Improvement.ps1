<#
.SYNOPSIS
    Searches the central Process Improvement tracker, its Completed/Rejected archive, and the
    Improvement Backlog for rows matching a keyword, printing each match with its current
    disposition and a readable context snippet; an exact-ID lookup renders the full row with
    its outbound cross-references resolved.

.DESCRIPTION
    Dedup / reconciliation helper for the framework feedback chain — PF-TSK-010 Tools Review's
    IMP-filing step, PF-TSK-089 IMP Triage, and PF-TSK-009's problem-verification step all mandate an "is this already tracked?"
    search across both the live tracker's open sections and the Completed/Rejected archive. The
    archive's Notes/Description cells are long enough that line-oriented grep returns truncated /
    "omitted" output, defeating that search.

    This script resolves the central tracker + archive via Get-CentralFrameworkPath (works from any
    cwd), scans their markdown table rows schema-agnostically (any row whose first cell is an IMP id,
    so it handles the two files' differing column layouts), and prints every row whose cells contain
    the keyword as: the IMP id, its section, its project, the row's disposition, and a windowed
    snippet around the match — so the match is always readable regardless of cell length.

    LEVEL SEMANTICS (PF-PRO-068 WI-5). By default the search covers **this workspace's own
    central** — the queue this workspace triages and implements from. In a federated portfolio
    that is deliberately not the whole picture: a finding about a shared substrate artifact is
    escalated to its owning workspace, so it leaves this tracker and lives in the owner's. A
    default-scope search that returns nothing therefore does not mean "not tracked anywhere".

    -Portfolio widens the search to the CHAIN ROOT's central as well, which is where the
    portfolio-global pools (PF-IMP / PF-PRO / PF-FEE / PF-REV / PF-EVR) mint from and where
    escalated rows accumulate. Root-level matches are labeled with the owning workspace's ID
    (e.g. "FWK-FB:tracker") so the level of every hit is visible at a glance. Use it for the
    duplicate checks that must not miss an escalated row — PF-TSK-010's IMP filing, PF-TSK-089's
    reconciliation check, PF-TSK-009's problem verification. When this workspace IS the chain
    root, -Portfolio adds nothing and says so rather than scanning the same files twice.

    Each match line carries the row's disposition, resolved by column name from its own table
    (PF-IMP-1829): the Status cell for live rows; "Completed <date> (<task>)" or
    "Rejected <date>: <reason>" for archived ones — a "Superseded by <id>" rejection is resolved
    one hop to the absorbing row's own state, plus that row's [CONSTITUENT <this-id>: ...]
    disposition marker when it carries one. A row whose Notes hold constituent / do-not-re-file
    markers is tagged, so a Completed umbrella is never mistaken for "everything in it shipped".

    When the keyword is itself an IMP/BKL id (e.g. PF-IMP-1570), the row that *is* that id is
    rendered in full instead of snippeted: its Description, the remaining metadata cells its table
    carries (Priority / Status / Resp Task / dates), the UNTRUNCATED Notes cell, and one resolved
    "ref:" line per outbound IMP/BKL cross-reference showing that id's current section and state
    (PF-IMP-1757 / PF-IMP-1814). These are exactly the fields the PF-TSK-009 claim protocol and the
    PF-TSK-089 pointer reconciliation read, so an id lookup needs no follow-up grep of the tracking
    files. Rows that merely cross-reference the id keep the usual windowed snippet.

    The central Improvement Backlog (improvement-backlog.md — below-materiality-bar candidates
    with BKL-NNN ids, PF-IMP-1882) is scanned alongside the live tracker in the Open and All
    scopes, labeled 'backlog' in the output; where the file does not exist the scan skips it
    silently (older central layouts predate it).

    Read-only: it never writes any of the files.

.PARAMETER Keyword
    The text to search for. Case-insensitive substring by default; a regular-expression pattern when
    -Regex is set. A bare IMP/BKL id triggers the full-row render for the row it names.

.PARAMETER Scope
    Which files to search: Open (the live tracker's Intake / Improvements / Extensions / Structural
    Changes / Active Pilots sections, plus the Improvement Backlog), Archive (the Completed /
    Rejected archive), or All (default — everything). Supersession targets and cross-references
    resolve against the scanned scope only, so All gives the most complete resolution.

.PARAMETER Portfolio
    Also scan the chain root's central tracker / archive / backlog, in addition to this
    workspace's own (PF-PRO-068 WI-5). Root-level matches are labeled with the root workspace's
    ID. Cross-references and supersession targets resolve across both levels, so a bare
    PF-IMP-NNNN in a local row resolves even when the row it names was escalated upward. Ignored
    with a notice when this workspace is itself the chain root, and refused when explicit
    -TrackerPath / -ArchivePath / -BacklogPath overrides are in play (those name one level's
    files, so mixing them with a second level would be ambiguous).

.PARAMETER Regex
    Treat -Keyword as a regular expression instead of a literal substring.

.PARAMETER Context
    Number of characters to show on each side of the match in the snippet (default 90).

.PARAMETER MaxMatches
    Print at most this many matches, then report how many were suppressed. 0 (the default) prints
    every match. Use it to keep a broad keyword (hundreds of hits) readable in-terminal.

.PARAMETER TrackerPath
    Optional explicit path to the live tracker file, bypassing central resolution (for tests and
    direct callers).

.PARAMETER ArchivePath
    Optional explicit path to the archive file, bypassing central resolution (for tests and direct
    callers).

.PARAMETER BacklogPath
    Optional explicit path to the Improvement Backlog file, bypassing central resolution (for tests
    and direct callers).

.EXAMPLE
    Find-Improvement.ps1 -Keyword "feedback_db"
    # Lists every open / Completed / Rejected IMP whose row mentions feedback_db, with context
    # and each row's disposition.

.EXAMPLE
    Find-Improvement.ps1 -Keyword "PF-IMP-1570"
    # Renders PF-IMP-1570's full row (metadata, untruncated Notes, resolved cross-references);
    # rows that cross-reference it print as usual snippets.

.EXAMPLE
    Find-Improvement.ps1 -Keyword "soak" -Scope Archive
    # Searches only the Completed / Rejected archive.

.EXAMPLE
    Find-Improvement.ps1 -Keyword "linkwatcher" -MaxMatches 25
    # Prints the first 25 of a broad keyword's matches and reports how many more exist.

.EXAMPLE
    Find-Improvement.ps1 -Keyword "soak resolution" -Portfolio
    # Searches this workspace's central AND the chain root's, so a row escalated to its owning
    # workspace still surfaces. Root matches are labeled with the root's workspace ID.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Keyword,

    [ValidateSet('Open', 'Archive', 'All')]
    [string]$Scope = 'All',

    [switch]$Regex,

    [switch]$Portfolio,

    [int]$Context = 90,

    [ValidateRange(0, [int]::MaxValue)]
    [int]$MaxMatches = 0,

    [string]$TrackerPath,

    [string]$ArchivePath,

    [string]$BacklogPath
)

function ConvertTo-CanonicalImpId {
    # Normalizes an IMP/BKL id to its canonical bare form for index lookups: strips any row
    # suffix ("PF-IMP-833 (b)" -> "PF-IMP-833") and adds the PF- prefix that historical
    # "IMP-NNN" rows omit, so both forms resolve to the same key.
    param([string]$Id)
    if ($Id -match '(?:PF-)?(?:IMP|BKL)-\d+') {
        $bare = $Matches[0]
        if ($bare -notmatch '^(PF-|BKL-)') { $bare = "PF-$bare" }
        return $bare
    }
    return $Id.Trim()
}

function Get-CellByHeader {
    # Returns the first non-empty cell whose header matches $HeaderPattern (regex), or $null when
    # the row's table has no such column or the cell is blank.
    param([string[]]$Cells, [string[]]$HeaderCells, [string]$HeaderPattern)
    if (-not $HeaderCells) { return $null }
    for ($i = 0; $i -lt $HeaderCells.Count -and $i -lt $Cells.Count; $i++) {
        if ($HeaderCells[$i] -match $HeaderPattern) {
            if (-not [string]::IsNullOrWhiteSpace($Cells[$i])) { return $Cells[$i] }
            return $null
        }
    }
    return $null
}

function Get-MatchSnippet {
    # Returns a windowed, ellipsized snippet of $Text centered on the first match of $Pattern.
    param([string]$Text, [string]$Pattern, [int]$Window)
    $m = [regex]::Match($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $m.Success) { return $Text }
    $start = [Math]::Max(0, $m.Index - $Window)
    $len = [Math]::Min($Text.Length - $start, $m.Length + (2 * $Window))
    $snippet = $Text.Substring($start, $len).Trim()
    # ASCII marker (not U+2026) so the snippet renders identically in non-UTF-8 consoles, which
    # best-fit-map the ellipsis glyph to '.' on capture (PF-IMP-1083 transcoding class).
    $prefix = if ($start -gt 0) { '...' } else { '' }
    $suffix = if (($start + $len) -lt $Text.Length) { '...' } else { '' }
    return "$prefix$snippet$suffix"
}

function Get-RowDescription {
    # Returns the row's Description cell, truncated — used when a non-id-shaped keyword matched
    # only the row's id cell, where a snippet of the id would carry no information. The column is
    # resolved by NAME from the table's header row ('Pilot Description' in Active Pilots also
    # matches); falls back to the row's longest non-id cell when a table carries no Description.
    param([string[]]$Cells, [string[]]$HeaderCells, [string]$IdCell, [int]$Window)
    $desc = Get-CellByHeader -Cells $Cells -HeaderCells $HeaderCells -HeaderPattern 'Description\s*$'
    if ([string]::IsNullOrWhiteSpace($desc)) {
        $desc = @($Cells | Where-Object { $_ -and $_ -ne $IdCell } | Sort-Object { $_.Length } -Descending)[0]
    }
    if ([string]::IsNullOrWhiteSpace($desc)) { return $IdCell }
    $limit = 2 * $Window
    if ($desc.Length -gt $limit) { return $desc.Substring(0, $limit).Trim() + '...' }
    return $desc
}

function Get-RowTerminalState {
    # One-line state of a row from its own cells — rejection, completion, or live Status —
    # used for the row's own disposition and to resolve a supersession target / cross-reference
    # without recursing further (one hop only).
    param($Row)
    $reason = Get-CellByHeader -Cells $Row.Cells -HeaderCells $Row.HeaderCells -HeaderPattern '^Rejection Reason$'
    if ($reason) {
        $head = if ($reason.Length -gt 80) { $reason.Substring(0, 80).Trim() + '...' } else { $reason }
        $date = Get-CellByHeader -Cells $Row.Cells -HeaderCells $Row.HeaderCells -HeaderPattern '^Rejection Date$'
        if ($date) { return "Rejected ${date}: $head" }
        return "Rejected: $head"
    }
    $resolved = Get-CellByHeader -Cells $Row.Cells -HeaderCells $Row.HeaderCells -HeaderPattern '^Resolution Date$'
    if ($resolved) {
        $task = Get-CellByHeader -Cells $Row.Cells -HeaderCells $Row.HeaderCells -HeaderPattern '^Implementing Task$'
        if ($task) { return "Completed $resolved ($task)" }
        return "Completed $resolved"
    }
    $status = Get-CellByHeader -Cells $Row.Cells -HeaderCells $Row.HeaderCells -HeaderPattern '^Status$'
    if ($status) { return "Status: $status" }
    return $null
}

function Get-RowDisposition {
    # Builds the header-line disposition for a matched row (PF-IMP-1829): its own terminal
    # state / live Status, with a "Superseded by <id>" rejection resolved one hop to the
    # absorbing row's state — plus that row's [CONSTITUENT <this-id>: ...] marker, which is the
    # superseded ask's real outcome per the constituent-disposition convention.
    param($Row, [hashtable]$Index)
    $extra = @()
    $reason = Get-CellByHeader -Cells $Row.Cells -HeaderCells $Row.HeaderCells -HeaderPattern '^Rejection Reason$'
    if ($reason -and $reason -match '^Superseded by\s+((?:PF-)?(?:IMP|BKL)-\d+)') {
        $targetId = ConvertTo-CanonicalImpId -Id $Matches[1]
        $target = $Index[$targetId]
        if ($target) {
            $targetState = Get-RowTerminalState -Row $target
            $state = if ($targetState) { "Superseded by $targetId -> $targetState" } else { "Superseded by $targetId" }
            $markerPattern = '\[CONSTITUENT\s+' + [regex]::Escape($Row.BareId) + '\s*:\s*([^\]]+)\]'
            $m = [regex]::Match(($target.Cells -join ' '), $markerPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($m.Success) { $extra += "constituent disposition at ${targetId}: $($m.Groups[1].Value.Trim())" }
        }
        else {
            $state = "Superseded by $targetId (not in scanned files)"
        }
    }
    else {
        $state = Get-RowTerminalState -Row $Row
    }
    $suffix = if ($state) { "  -- $state" } else { '' }
    return [pscustomobject]@{ Suffix = $suffix; ExtraLines = $extra }
}

function Get-FullRowLines {
    # Renders the row a typed id names in full (PF-IMP-1757): Description, the remaining
    # metadata cells its table carries, the untruncated Notes cell, and every outbound IMP/BKL
    # cross-reference resolved to its current section and state (PF-IMP-1814) — the fields the
    # PF-TSK-009 claim protocol and PF-TSK-089 pointer reconciliation read, so an id lookup
    # needs no follow-up grep of the tracking files.
    param($Row, [hashtable]$Index)
    $lines = [System.Collections.Generic.List[string]]::new()
    $desc = Get-CellByHeader -Cells $Row.Cells -HeaderCells $Row.HeaderCells -HeaderPattern 'Description\s*$'
    if (-not $desc) {
        $desc = @($Row.Cells | Where-Object { $_ -and $_ -ne $Row.Id } | Sort-Object { $_.Length } -Descending)[0]
    }
    if ($desc) { $lines.Add("Description: $desc") }
    if ($Row.HeaderCells) {
        # Source/Concept are link cells the protocol readers don't consume; ID/Project already
        # sit on the header line, Description/Notes get their own lines.
        $skip = @('ID', 'BKL-ID', 'Description', 'Pilot Description', 'Notes', 'Project', 'Source', 'Concept')
        $pairs = @()
        for ($i = 0; $i -lt $Row.HeaderCells.Count -and $i -lt $Row.Cells.Count; $i++) {
            $h = $Row.HeaderCells[$i]
            if ([string]::IsNullOrWhiteSpace($h) -or $skip -contains $h) { continue }
            if ([string]::IsNullOrWhiteSpace($Row.Cells[$i])) { continue }
            $pairs += "${h}: $($Row.Cells[$i])"
        }
        if ($pairs.Count -gt 0) { $lines.Add($pairs -join ' | ') }
    }
    $notes = Get-CellByHeader -Cells $Row.Cells -HeaderCells $Row.HeaderCells -HeaderPattern '^Notes$'
    if ($notes) { $lines.Add("Notes: $notes") }
    $refIds = [System.Collections.Generic.List[string]]::new()
    foreach ($m in [regex]::Matches(($Row.Cells -join ' '), '(?:PF-)?(?:IMP|BKL)-\d+')) {
        $rid = ConvertTo-CanonicalImpId -Id $m.Value
        if ($rid -ne $Row.BareId -and -not $refIds.Contains($rid)) { [void]$refIds.Add($rid) }
    }
    foreach ($rid in $refIds) {
        $target = $Index[$rid]
        if ($target) {
            $state = Get-RowTerminalState -Row $target
            $loc = "$($target.FileLabel): $($target.Section)"
            if ($state) { $lines.Add("ref: $rid -> [$loc] $state") }
            else { $lines.Add("ref: $rid -> [$loc]") }
        }
        else {
            $lines.Add("ref: $rid -> not found in scanned files")
        }
    }
    # Plain return (pipeline-enumerated) — the caller foreach-iterates the lines; an empty list
    # unwraps to nothing, which foreach handles as zero iterations.
    return $lines
}

function Search-TrackingFile {
    # Scans one IMP/backlog tracking file, returning a row object per table entry with its cells,
    # header, and match state. ALL id-rows return (not only matches) so the caller can resolve
    # supersession targets and cross-references against the full scanned population.
    param([string]$Path, [string]$FileLabel, [string]$Pattern, [switch]$SkipSilentlyIfMissing)
    if (-not (Test-Path $Path)) {
        if ($SkipSilentlyIfMissing) { Write-Verbose "Find-Improvement: optional file not found, skipping: $Path" }
        else { Write-Warning "Find-Improvement: file not found, skipping: $Path" }
        return @()
    }
    $results = [System.Collections.Generic.List[object]]::new()
    $currentSection = '(top)'
    $headerCells = $null
    foreach ($line in (Get-Content -Path $Path -Encoding UTF8)) {
        if ($line -match '^##\s+(.+?)\s*$') { $currentSection = $Matches[1]; $headerCells = $null; continue }
        if ($line -notmatch '^\s*\|') { continue }
        $cells = @(($line -split '(?<!\\)\|') | ForEach-Object { $_.Trim() })
        $idCell = $cells | Where-Object { $_ -match '^((PF-)?IMP|BKL)-\d+' } | Select-Object -First 1
        if (-not $idCell) {
            # A table's header row (first cell 'ID' / 'BKL-ID') supplies the column names for this table.
            if ($cells -contains 'ID' -or $cells -contains 'BKL-ID') { $headerCells = $cells }
            continue
        }
        $matchingCells = @($cells | Where-Object { $_ -match $Pattern })
        $results.Add([pscustomobject]@{
                Id          = $idCell
                BareId      = ConvertTo-CanonicalImpId -Id $idCell
                Section     = $currentSection
                FileLabel   = $FileLabel
                Project     = $cells | Where-Object { $_ -match '^(?:[A-Z]{2,4}-[A-Z]*\d+|FWK-[A-Z]{2,4}\b)' } | Select-Object -First 1
                Cells       = $cells
                HeaderCells = $headerCells
                IsMatch     = ($matchingCells.Count -gt 0)
                MatchCell   = ($matchingCells | Where-Object { $_ -ne $idCell } | Select-Object -First 1)
            })
    }
    # Plain return (pipeline-enumerated) — the AddRange(@(...)) call sites collect the elements;
    # a ,-wrapped return would arrive as ONE element holding the whole List.
    return $results
}

# Resolve the central tracker + archive + backlog unless explicit paths were supplied (tests / direct callers).
$explicitPaths = ($TrackerPath -or $ArchivePath -or $BacklogPath)
if (-not $TrackerPath -or -not $ArchivePath -or -not $BacklogPath) {
    $coreModule = Join-Path -Path $PSScriptRoot -ChildPath 'Common-ScriptHelpers/Core.psm1'
    Import-Module $coreModule -Force -ErrorAction Stop
    $central = Get-CentralFrameworkPath
    $permanent = Join-Path -Path $central -ChildPath 'state-tracking/permanent'
    if (-not $TrackerPath) { $TrackerPath = Join-Path -Path $permanent -ChildPath 'process-improvement-tracking.md' }
    if (-not $ArchivePath) { $ArchivePath = Join-Path -Path $permanent -ChildPath 'archive/process-improvement-tracking-archive.md' }
    if (-not $BacklogPath) { $BacklogPath = Join-Path -Path $permanent -ChildPath 'improvement-backlog.md' }
}

# -Portfolio (PF-PRO-068 WI-5): add the chain root's three files as a SECOND level to scan.
# Escalated rows leave this workspace's tracker for their owner's, so an own-level-only search
# genuinely cannot see them — this is the switch that closes that blind spot for duplicate checks.
$rootTrackerPath = $null; $rootArchivePath = $null; $rootBacklogPath = $null; $rootLabelPrefix = ''
if ($Portfolio) {
    if ($explicitPaths) {
        Write-Error "-Portfolio cannot be combined with explicit -TrackerPath / -ArchivePath / -BacklogPath: those name one level's files, so the second level would be ambiguous. Drop the overrides, or drive the two levels with the FRAMEWORK_CENTRAL_OVERRIDE / FRAMEWORK_ROOT_CENTRAL_OVERRIDE test axes."
        return
    }
    $rootCentral = Get-RootCentralFrameworkPath
    if ((ConvertTo-CanonicalWorkspacePath -Path $rootCentral) -ieq (ConvertTo-CanonicalWorkspacePath -Path $central)) {
        Write-Output "(-Portfolio: this workspace is the chain root — its central IS the portfolio root, so the default scope already covers everything.)"
    }
    else {
        $rootPermanent = Join-Path -Path $rootCentral -ChildPath 'state-tracking/permanent'
        $rootTrackerPath = Join-Path -Path $rootPermanent -ChildPath 'process-improvement-tracking.md'
        $rootArchivePath = Join-Path -Path $rootPermanent -ChildPath 'archive/process-improvement-tracking-archive.md'
        $rootBacklogPath = Join-Path -Path $rootPermanent -ChildPath 'improvement-backlog.md'
        # Label root hits by the owning workspace's declared ID, so the level of every match is
        # visible without cross-referencing paths. Falls back to a generic 'root' label when the
        # root's config is unreadable — a missing label must not abort the search.
        $rootLabelPrefix = 'root'
        try {
            $rootConfig = Get-Content -Path (Join-Path -Path (Split-Path -Parent $rootCentral) -ChildPath 'doc/project-config.json') -Raw | ConvertFrom-Json
            if ($rootConfig.project_id) { $rootLabelPrefix = $rootConfig.project_id }
        } catch {
            Write-Verbose "Find-Improvement: could not read the chain root's project_id; labeling root matches 'root'."
        }
        $rootLabelPrefix = "${rootLabelPrefix}:"
    }
}

$pattern = if ($Regex) { $Keyword } else { [regex]::Escape($Keyword) }

# An id-shaped keyword (a bare IMP/BKL id) triggers the full-row render for the row it names
# (PF-IMP-1757); regex keywords keep plain snippet semantics.
$exactId = $null
if (-not $Regex -and $Keyword -match '^\s*((?:PF-)?(?:IMP|BKL)-\d+)\s*$') {
    $exactId = ConvertTo-CanonicalImpId -Id $Matches[1]
}

$rows = [System.Collections.Generic.List[object]]::new()
if ($Scope -in @('Open', 'All')) {
    $rows.AddRange([object[]]@(Search-TrackingFile -Path $TrackerPath -FileLabel 'tracker' -Pattern $pattern))
    $rows.AddRange([object[]]@(Search-TrackingFile -Path $BacklogPath -FileLabel 'backlog' -Pattern $pattern -SkipSilentlyIfMissing))
    if ($rootTrackerPath) {
        # The root's files are scanned with -SkipSilentlyIfMissing: a chain root that has not yet
        # been seeded (the pre-federation state, and every fresh sandbox) is not an error here.
        $rows.AddRange([object[]]@(Search-TrackingFile -Path $rootTrackerPath -FileLabel "${rootLabelPrefix}tracker" -Pattern $pattern -SkipSilentlyIfMissing))
        $rows.AddRange([object[]]@(Search-TrackingFile -Path $rootBacklogPath -FileLabel "${rootLabelPrefix}backlog" -Pattern $pattern -SkipSilentlyIfMissing))
    }
}
if ($Scope -in @('Archive', 'All')) {
    $rows.AddRange([object[]]@(Search-TrackingFile -Path $ArchivePath -FileLabel 'archive' -Pattern $pattern))
    if ($rootArchivePath) {
        $rows.AddRange([object[]]@(Search-TrackingFile -Path $rootArchivePath -FileLabel "${rootLabelPrefix}archive" -Pattern $pattern -SkipSilentlyIfMissing))
    }
}

# Index of every scanned row by canonical id — supersession targets and cross-references
# resolve against this, whether or not those rows matched the keyword themselves.
$index = @{}
foreach ($row in $rows) {
    if (-not $index.ContainsKey($row.BareId)) { $index[$row.BareId] = $row }
}

$all = @($rows | Where-Object { $_.IsMatch })
$scopeLabel = if ($rootTrackerPath) { "$Scope, portfolio" } else { $Scope }

if ($all.Count -eq 0) {
    Write-Output "No improvements matched '$Keyword' (scope: $scopeLabel)."
    # An own-level miss is not portfolio-wide evidence: escalated rows live in the owner's
    # tracker. Say so, rather than letting a caller read silence as "not tracked anywhere" —
    # but only where a level above this one actually exists, or the hint is noise pointing at
    # nothing (which is every workspace's state until the federation cutover).
    if (-not $Portfolio -and -not $explicitPaths) {
        $hasParentLevel = $false
        try {
            $hasParentLevel = (ConvertTo-CanonicalWorkspacePath -Path (Get-RootCentralFrameworkPath)) -ine (ConvertTo-CanonicalWorkspacePath -Path $central)
        } catch {
            Write-Verbose "Find-Improvement: chain-root resolution failed while deciding whether to show the -Portfolio hint; suppressing it."
        }
        if ($hasParentLevel) {
            Write-Output "(Own-workspace scope only. Rows escalated to an owning workspace live in ITS tracker — re-run with -Portfolio before concluding this is untracked.)"
        }
    }
    return
}

$capped = ($MaxMatches -gt 0 -and $all.Count -gt $MaxMatches)
$shown = if ($capped) { $all | Select-Object -First $MaxMatches } else { $all }

foreach ($r in $shown) {
    $isIdRow = ($exactId -and $r.BareId -eq $exactId)
    $disp = Get-RowDisposition -Row $r -Index $index
    $suffix = $disp.Suffix
    # Umbrella tag (PF-IMP-1829): a Completed suffix alone reads as "everything shipped" while
    # Notes may carry per-constituent do-not-re-file markers. The full-row render shows the
    # Notes anyway, so the tag decorates snippet renders only.
    if (-not $isIdRow -and (($r.Cells -join ' ') -match '\[CONSTITUENT\s|\[DEAD PREMISE')) {
        $suffix += ' [constituent/do-not-re-file markers in Notes]'
    }
    $proj = if ($r.Project) { "  ($($r.Project))" } else { '' }
    Write-Output "$($r.Id)  [$($r.FileLabel): $($r.Section)]$proj$suffix"
    foreach ($x in $disp.ExtraLines) { Write-Output "    $x" }
    if ($isIdRow) {
        foreach ($l in (Get-FullRowLines -Row $r -Index $index)) { Write-Output "    $l" }
    }
    elseif ($r.MatchCell) {
        Write-Output "    $(Get-MatchSnippet -Text $r.MatchCell -Pattern $pattern -Window $Context)"
    }
    else {
        # A non-id-shaped keyword that matched only the id cell — render the Description.
        Write-Output "    $(Get-RowDescription -Cells $r.Cells -HeaderCells $r.HeaderCells -IdCell $r.Id -Window $Context)"
    }
}
Write-Output ""
if ($capped) {
    Write-Output "Showing $MaxMatches of $($all.Count) improvement(s) matched '$Keyword' (scope: $scopeLabel) - narrow the keyword, use -Scope, or raise -MaxMatches for the rest."
}
else {
    Write-Output "$($all.Count) improvement(s) matched '$Keyword' (scope: $scopeLabel)."
}
