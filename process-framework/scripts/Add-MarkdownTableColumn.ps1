<#
.SYNOPSIS
Inserts a column into markdown table(s) — section-scoped, header-driven, with a per-row value map — leaving every other cell untouched.

.DESCRIPTION
Rewrites the header, separator and every data row of each targeted table so the new column lands
at the requested position (-AfterColumn / -BeforeColumn, else last). Targets are the first table
under each -Section heading; without -Section, every table in the file that carries the anchor
column (every table when no anchor is named).

v2.0 (PF-IMP-2248 / PF-PRO-072 Phase 3) replaced the feature-table-only v1: cells are parsed and
re-emitted with the shared table helpers (TableOperations.psm1), so an escaped pipe (\|) inside a
cell survives unchanged and a literal pipe in a supplied value is escaped; every row's shape is
asserted against its header BEFORE anything is written (a malformed row refuses the whole file —
nothing is written); the file's line-ending convention is preserved; no other cell is touched (a
Last Updated column is deliberately not bumped — a schema change is not a row change).

Per-row values: -ValueMap (hashtable) or -ValueMapPath (a JSON object) keyed by the row's
-KeyColumn cell (default: the first column, link display text resolved). Rows without an entry
receive -DefaultValue. Every map key must match a row in a targeted table — a stale key is an
error and nothing is written, unless -AllowUnmatchedKeys downgrades it to a warning.

Idempotent: a targeted table that already carries the column is skipped (reported), or refused
with -FailIfExists. Use -WhatIf for a no-write preview; git is the recovery path for tracked files
(-BackupPath writes a copy first when a file is not under version control).

.PARAMETER FilePath
Path to the markdown file to modify.

.PARAMETER ColumnName
Header text of the column to insert.

.PARAMETER AfterColumn
Insert the new column immediately after this existing column. Mutually exclusive with -BeforeColumn.

.PARAMETER BeforeColumn
Insert the new column immediately before this existing column (e.g. 'Notes'). Mutually exclusive
with -AfterColumn.

.PARAMETER DefaultValue
Cell value for rows the value map does not name. Defaults to an empty cell; trackers use '—'.

.PARAMETER Section
One or more exact heading lines (e.g. '## Section 1 — Intake'). The first table under each is
targeted; a heading with no table is an error. Without -Section, every table is a candidate.
Under `pwsh -File` an array cannot be passed as several tokens (the extras bind positionally
elsewhere — which is why positional binding is disabled here), so join several headings with
';' in ONE token: -Section '## Section 1 — Intake;## Section 2 — Improvements'.

.PARAMETER ValueMap
Hashtable of row key -> cell value.

.PARAMETER ValueMapPath
Path to a JSON object of row key -> cell value. Combined with -ValueMap when both are given
(-ValueMap wins on a duplicate key).

.PARAMETER KeyColumn
Header of the column whose cell identifies a row for the value map. Defaults to the first column.

.PARAMETER AllowUnmatchedKeys
Downgrade "map key matches no row" from an error (nothing written) to a warning.

.PARAMETER FailIfExists
Exit 1 when a targeted table already carries -ColumnName (default: skip that table and report).

.PARAMETER BackupPath
Optional path to copy the original file to before writing.

.EXAMPLE
Add-MarkdownTableColumn.ps1 -FilePath process-improvement-tracking.md -ColumnName Artifacts -BeforeColumn Notes -DefaultValue '—' `
    -Section '## Section 1 — Intake','## Section 2 — Improvements' -ValueMapPath artifacts.json -WhatIf

.NOTES
    OWNERSHIP: FWK-FB (FrameworkBuilder) - canonical at FrameworkBuilder; anywhere else a received copy. Edit only at the owning workspace. An agent may only modify files its workspace owns.
    Version: 2.0 (2026-08-31, PF-PRO-072 Phase 3)
#>

[CmdletBinding(SupportsShouldProcess, PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $true)]
    [string]$ColumnName,

    [Parameter(Mandatory = $false)]
    [string]$AfterColumn = "",

    [Parameter(Mandatory = $false)]
    [string]$BeforeColumn = "",

    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [string]$DefaultValue = "",

    [Parameter(Mandatory = $false)]
    [string[]]$Section,

    [Parameter(Mandatory = $false)]
    [hashtable]$ValueMap,

    [Parameter(Mandatory = $false)]
    [string]$ValueMapPath,

    [Parameter(Mandatory = $false)]
    [string]$KeyColumn = "",

    [Parameter(Mandatory = $false)]
    [switch]$AllowUnmatchedKeys,

    [Parameter(Mandatory = $false)]
    [switch]$FailIfExists,

    [Parameter(Mandatory = $false)]
    [string]$BackupPath
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Common-ScriptHelpers/TableOperations.psm1') -Force -Verbose:$false

function Write-Fail {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
    exit 1
}

# --- Argument validation -----------------------------------------------------------------
if (-not (Test-Path -LiteralPath $FilePath)) { Write-Fail "File not found: $FilePath" }
if ($AfterColumn -and $BeforeColumn) { Write-Fail "-AfterColumn and -BeforeColumn are mutually exclusive." }
if ($ColumnName -match '[\r\n|]') { Write-Fail "-ColumnName must be a single line without a literal pipe." }
if ($DefaultValue -match '[\r\n]') { Write-Fail "-DefaultValue must be a single line." }

# Merge the value map: file first, then the inline hashtable (inline wins).
$map = @{}
if ($ValueMapPath) {
    if (-not (Test-Path -LiteralPath $ValueMapPath)) { Write-Fail "Value map file not found: $ValueMapPath" }
    $json = Get-Content -LiteralPath $ValueMapPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($p in $json.PSObject.Properties) { $map[$p.Name] = [string]$p.Value }
}
if ($ValueMap) { foreach ($k in $ValueMap.Keys) { $map[[string]$k] = [string]$ValueMap[$k] } }
foreach ($k in @($map.Keys)) {
    if ($map[$k] -match '[\r\n]') { Write-Fail "Value map entry '$k' contains a line break; a cell is a single line." }
}

# --- Read, preserving the file's conventions ---------------------------------------------
$raw = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8
if ($null -eq $raw) { $raw = "" }
$newline = if ($raw -match "`r`n") { "`r`n" } else { "`n" }
$lines = [System.Collections.Generic.List[string]]@($raw -split "`r?`n")
$separatorPattern = '^\s*\|[\s\-:|]+\|\s*$'

# --- Locate every table: header index, separator index, data-row indices ----------------
function Get-TableAt {
    # Scans forward from $Start for the first table; returns $null when none begins before $Stop.
    param([int]$Start, [int]$Stop)
    for ($i = $Start; $i -lt $Stop; $i++) {
        $line = $lines[$i]
        if ($line -match $separatorPattern) { continue }
        $cells = Split-MarkdownTableRow -Line $line.Trim()
        if ($null -eq $cells) { continue }
        if (($i + 1) -ge $lines.Count -or $lines[$i + 1] -notmatch $separatorPattern) { continue }   # a lone pipe line is not a header
        $rows = [System.Collections.Generic.List[int]]::new()
        for ($j = $i + 2; $j -lt $lines.Count; $j++) {
            $l = $lines[$j]
            if ([string]::IsNullOrWhiteSpace($l) -or $l -notmatch '^\s*\|') { break }
            if ($l -match $separatorPattern) { break }
            $rows.Add($j)
        }
        return [pscustomobject]@{ HeaderIdx = $i; SepIdx = $i + 1; RowIdx = $rows; Headers = @($cells) }
    }
    return $null
}

$tables = [System.Collections.Generic.List[object]]::new()
if ($Section) {
    # ';'-joined headings in one token (the pwsh -File array limitation, see .PARAMETER Section).
    $Section = @($Section | ForEach-Object { $_ -split ';' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    foreach ($heading in $Section) {
        $hIdx = -1
        for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i].TrimEnd() -eq $heading.TrimEnd()) { $hIdx = $i; break } }
        if ($hIdx -lt 0) { Write-Fail "Section heading not found: '$heading'" }
        $level = if ($heading -match '^(#{1,6})\s') { $matches[1].Length } else { 2 }
        $end = $lines.Count
        for ($i = $hIdx + 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^#{1,$level}\s") { $end = $i; break }
        }
        $t = Get-TableAt -Start ($hIdx + 1) -Stop $end
        if ($null -eq $t) { Write-Fail "No table found under section '$heading'." }
        $t | Add-Member -NotePropertyName Label -NotePropertyValue $heading
        $tables.Add($t)
    }
} else {
    $pos = 0
    while ($pos -lt $lines.Count) {
        $t = Get-TableAt -Start $pos -Stop $lines.Count
        if ($null -eq $t) { break }
        $t | Add-Member -NotePropertyName Label -NotePropertyValue "table at line $($t.HeaderIdx + 1)"
        if (-not $AfterColumn -and -not $BeforeColumn) { $tables.Add($t) }
        else {
            $anchor = if ($AfterColumn) { $AfterColumn } else { $BeforeColumn }
            if ($t.Headers -contains $anchor) { $tables.Add($t) }
            else { Write-Host "⏭️  $($t.Label): no '$anchor' column — skipped" -ForegroundColor Gray }
        }
        $pos = if ($t.RowIdx.Count -gt 0) { $t.RowIdx[$t.RowIdx.Count - 1] + 1 } else { $t.SepIdx + 1 }
    }
    if ($tables.Count -eq 0) { Write-Fail "No table found in $FilePath (with the requested anchor column, if any)." }
}

# --- Plan every edit before touching a line (all-or-nothing) ----------------------------
$edits = @{}          # line index -> new text
$matchedKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$tablesModified = 0
$rowsUpdated = 0
$mapHits = 0

foreach ($t in $tables) {
    $headers = @($t.Headers)
    if ($headers -contains $ColumnName) {
        if ($FailIfExists) { Write-Fail "$($t.Label) already carries column '$ColumnName'." }
        Write-Host "⏭️  $($t.Label): already has '$ColumnName' — skipped" -ForegroundColor Gray
        continue
    }

    $insertAt = $headers.Count
    if ($AfterColumn) {
        $idx = [Array]::IndexOf($headers, $AfterColumn)
        if ($idx -lt 0) { Write-Fail "$($t.Label): anchor column '$AfterColumn' not found (headers: $($headers -join ', '))." }
        $insertAt = $idx + 1
    } elseif ($BeforeColumn) {
        $idx = [Array]::IndexOf($headers, $BeforeColumn)
        if ($idx -lt 0) { Write-Fail "$($t.Label): anchor column '$BeforeColumn' not found (headers: $($headers -join ', '))." }
        $insertAt = $idx
    }
    $keyIdx = 0
    if ($KeyColumn) {
        $keyIdx = [Array]::IndexOf($headers, $KeyColumn)
        if ($keyIdx -lt 0) { Write-Fail "$($t.Label): key column '$KeyColumn' not found (headers: $($headers -join ', '))." }
    }

    # Header and separator
    $newHeaders = [System.Collections.Generic.List[string]]@($headers); $newHeaders.Insert($insertAt, $ColumnName)
    $edits[$t.HeaderIdx] = ConvertTo-MarkdownTableRow -Cells ([string[]]$newHeaders)
    $sepCells = @(Split-MarkdownTableRow -Line $lines[$t.SepIdx].Trim())
    $sepNew = [System.Collections.Generic.List[string]]@($sepCells); $sepNew.Insert($insertAt, ('-' * [Math]::Max(3, $ColumnName.Length)))
    $edits[$t.SepIdx] = '|' + (($sepNew | ForEach-Object { $_ }) -join '|') + '|'

    # Data rows — shape-asserted first; a malformed row refuses the whole file.
    foreach ($r in $t.RowIdx) {
        $line = $lines[$r]
        $cells = Split-MarkdownTableRow -Line $line.Trim()
        if ($null -eq $cells) { Write-Fail "$($t.Label): line $($r + 1) is not a well-formed table row (missing closing '|'?). Nothing was written." }
        try { Assert-TableRowShape -Cells $cells -Headers $headers -Context "$($t.Label) line $($r + 1)" }
        catch { Write-Fail "$($_.Exception.Message)`nNothing was written." }

        $key = (Get-MarkdownLinkText ([string]$cells[$keyIdx])).Trim()
        $value = $DefaultValue
        if ($map.ContainsKey($key)) { $value = $map[$key]; $mapHits++; [void]$matchedKeys.Add($key) }
        $newCells = [System.Collections.Generic.List[string]]@($cells); $newCells.Insert($insertAt, $value)
        $edits[$r] = ConvertTo-MarkdownTableRow -Cells ([string[]]$newCells)
        $rowsUpdated++
    }
    $tablesModified++
    Write-Host "📊 $($t.Label): '$ColumnName' at position $insertAt, $($t.RowIdx.Count) row(s)" -ForegroundColor Cyan
}

$unmatched = @($map.Keys | Where-Object { -not $matchedKeys.Contains($_) } | Sort-Object)
if ($unmatched.Count -gt 0) {
    $msg = "$($unmatched.Count) value-map key(s) matched no row in the targeted table(s): $($unmatched -join ', ')"
    if ($AllowUnmatchedKeys) { Write-Warning $msg } else { Write-Fail "$msg`nNothing was written (pass -AllowUnmatchedKeys to proceed)." }
}

Write-Host ""
Write-Host "📊 Summary: $tablesModified table(s) modified, $rowsUpdated row(s) updated, $mapHits value-map hit(s), default '$DefaultValue' elsewhere" -ForegroundColor Cyan

if ($tablesModified -eq 0) {
    Write-Host "Nothing to do." -ForegroundColor Yellow
    exit 0
}

if (-not $PSCmdlet.ShouldProcess($FilePath, "Add column '$ColumnName' to $tablesModified table(s)")) {
    Write-Host "🔍 -WhatIf preview - No changes made to file" -ForegroundColor Yellow
    exit 0
}

if ($BackupPath) {
    Copy-Item -LiteralPath $FilePath -Destination $BackupPath -Force
    Write-Host "✅ Backup written: $BackupPath" -ForegroundColor Green
}

foreach ($idx in $edits.Keys) { $lines[$idx] = $edits[$idx] }
Set-Content -LiteralPath $FilePath -Value ($lines -join $newline) -NoNewline -Encoding UTF8
Write-Host "✅ File updated: $FilePath" -ForegroundColor Green
