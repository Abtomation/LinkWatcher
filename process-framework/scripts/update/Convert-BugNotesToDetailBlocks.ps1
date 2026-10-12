# Convert-BugNotesToDetailBlocks.ps1
# One-time migration: split accreted bug-tracking Notes cells into per-bug Bug Details blocks

<#
.SYNOPSIS
    Converts legacy bug-tracking Notes cells into per-bug Bug Details blocks, emitting a new file.

.DESCRIPTION
    The one-time migration for PF-IMP-2184 / PF-PRO-073. Before that change, every bug's
    lifecycle prose accumulated in the Notes table cell. A markdown table row must occupy
    exactly one line, so the cell had no upper bound — measured at 51,854 characters
    (~8,000 words) in APP-001, where 84% of a 725 KB archive was Notes cells. This script
    moves that prose into a '## Bug Details' block per bug and leaves the cell holding a
    capped summary plus a '[details](#pd-bug-nnn)' pointer.

    SAFETY MODEL — the reason this is a script rather than a hand migration at 150+ rows:

      * It NEVER writes the input file. It reads -Path and emits -OutputPath (default:
        the input name with a .converted.md suffix). Swapping the converted file into place
        is a separate, inspectable step with a diff in front of it.
      * A character-level RECONCILIATION GATE runs before anything is written: the
        alphanumeric stream of every original Notes cell must appear, intact and in order,
        in that bug's generated block. On any mismatch the script writes NOTHING and exits
        non-zero, naming the rows that failed. This is the assurance a hand migration
        cannot offer — spot-checking a few of 150 rows proves nothing about the rest.
      * It is IDEMPOTENT. A row whose cell already carries a pointer is left untouched,
        so it is safe to re-run, and safe against rows the writers already self-healed
        (Update-BugStatus.ps1 rescues an unmigrated cell on first touch).

    Run it against a COPY first and diff the result. Both the live tracker and the archive are
    valid inputs; they share one schema and one block convention. The Notes cell is located from
    the file's own table header rather than a fixed index, so a tracker that has already received
    the Origin column (PF-PRO-078) converts correctly instead of reading Origin as Notes.

.PARAMETER Path
    The bug-tracking file to convert (live tracker or archive). Never modified.

.PARAMETER OutputPath
    Where to write the converted content. Defaults to the input path with '.converted.md'
    substituted for '.md'. Refuses to overwrite an existing file unless -Force is passed,
    and refuses to equal -Path under any circumstances.

.PARAMETER Force
    Allow overwriting an existing -OutputPath. Never permits writing over -Path.

.PARAMETER SummaryLength
    Notes-cell cap, matching the writers' $BugNotesCellCap. Default 200.

.EXAMPLE
    Convert-BugNotesToDetailBlocks.ps1 -Path doc/state-tracking/permanent/archive/bug-tracking-archive.md -WhatIf

.EXAMPLE
    Convert-BugNotesToDetailBlocks.ps1 -Path doc/state-tracking/permanent/bug-tracking.md -OutputPath /tmp/converted.md

.NOTES
    - One-time migration tool, applied per project by Framework Rollout Mode C.
    - Emits a per-row conversion report; the reconciliation gate is not optional.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if (-not (Test-Path $_)) { throw "Input file not found: $_" }
        $true
    })]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [ValidateRange(80, 1000)]
    [int]$SummaryLength = 200
)

# Import the common helpers (robust upward search — the script must run from any cwd)
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
if (-not $dir) {
    Write-Error "Failed to locate Common-ScriptHelpers.psm1 above $PSScriptRoot"
    exit 1
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

Invoke-StandardScriptInitialization

$BugDetailsHeading = '## Bug Details'

# The closed label set both writers emit. Splitting is restricted to these: arbitrary prose
# routinely contains other '; word: ' sequences, and treating those as labels would shred a
# sentence into fake entries. Anything unrecognized stays inside the current segment, and the
# reconciliation gate below is what proves nothing was lost either way.
$KnownLabels = @(
    'Source', 'Environment', 'Component', 'Repro', 'Expected', 'Actual', 'Evidence',
    'Triage', 'Fix', 'Root Cause', 'Tests Added', 'PR', 'Verification',
    'Reopen Reason', 'Rejected', 'Updated'
)

function Get-AlnumStream {
    # The reconciliation currency. Conversion deliberately changes punctuation and whitespace
    # (adding '- **' / '**: ', unescaping pipes, collapsing runs), so comparing raw text would
    # report false losses. Letters and digits are exactly what must survive untouched.
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    return ([regex]::Replace($Text, '[^A-Za-z0-9]', ''))
}

function Split-LegacyNotes {
    # Splits a legacy cell into ordered @{ Label; Value } segments on the known-label grammar.
    param([string]$Cell)

    $escaped = ($KnownLabels | ForEach-Object { [regex]::Escape($_) }) -join '|'
    # Unescape table-escaped pipes: the prose is leaving the table, so it no longer needs them.
    $text = $Cell -replace '\\\|', '|'

    $pattern = "(?=(?:^|;\s*)(?:$escaped)\s*:\s)"
    $parts = [regex]::Split($text, $pattern) | Where-Object { $_ -and $_.Trim() -ne '' }

    $segments = @()
    foreach ($part in $parts) {
        $p = $part.Trim().TrimStart(';').Trim()
        $m = [regex]::Match($p, "^($escaped)\s*:\s*(.*)$", 'Singleline')
        if ($m.Success) {
            $segments += @{ Label = $m.Groups[1].Value; Value = ($m.Groups[2].Value -replace '\s+', ' ').Trim() }
        }
        elseif ($p -ne '') {
            # Prose that carries no recognized label — preserved verbatim rather than dropped.
            $segments += @{ Label = $null; Value = ($p -replace '\s+', ' ').Trim() }
        }
    }
    return , $segments
}

function Format-NotesCell {
    param([string]$BugId, [string]$Summary, [int]$Cap)
    $pointer = "[details](#$($BugId.ToLower()))"
    $budget = $Cap - $pointer.Length - 1
    $clean = ($Summary -replace '\s+', ' ').Trim()
    if ($clean.Length -gt $budget) {
        $clean = $clean.Substring(0, [Math]::Max(0, $budget - 1)).TrimEnd() + [char]0x2026
    }
    if ([string]::IsNullOrWhiteSpace($clean)) { return $pointer }
    return "$clean $pointer"
}

# ---------------------------------------------------------------------------

if (-not $OutputPath) {
    $OutputPath = [regex]::Replace($Path, '\.md$', '.converted.md')
    if ($OutputPath -eq $Path) { $OutputPath = "$Path.converted.md" }
}

$resolvedIn = (Resolve-Path $Path).Path
$resolvedOutParent = Split-Path -Parent $OutputPath
if (-not $resolvedOutParent) { $resolvedOutParent = '.' }
$resolvedOut = Join-Path (Resolve-Path $resolvedOutParent).Path (Split-Path -Leaf $OutputPath)

# The safety property that makes this script preferable to a hand migration: it structurally
# cannot damage the source. Enforced, not merely intended.
if ($resolvedOut -eq $resolvedIn) {
    Write-ProjectError -Message "OutputPath resolves to the input file. This script never writes its input." -ExitCode 1
}
if ((Test-Path $resolvedOut) -and -not $Force) {
    Write-ProjectError -Message "OutputPath already exists: $resolvedOut. Pass -Force to overwrite." -ExitCode 1
}

$content = Get-Content -Path $resolvedIn -Raw -Encoding UTF8
$lines = [System.Collections.ArrayList]@($content -split "\r?\n")

$rowPattern = '^\|\s*(PD-BUG-\d+|BUG-\d+)\s*\|'
$converted = 0
$skipped = 0
$failures = @()
$blocks = [System.Collections.Specialized.OrderedDictionary]::new()

# Notes is located by header, not at a fixed index (PF-PRO-078): the Origin column sits between
# Dims and Notes, so index 10 is Origin in a migrated tracker and converting against it would
# move the wrong cell into the block and cap the wrong one. Tracked per row width, because the
# live file and the archive can be mid-migration at different widths.
$notesIndexByWidth = @{}
foreach ($line in $lines) {
    if ($line -notmatch '(?i)^\s*\|\s*ID\s*\|') { continue }
    $hdr = @($line.Trim().Trim('|') -split '(?<!\\)\|') | ForEach-Object { $_.Trim() }
    $idx = [array]::IndexOf($hdr, 'Notes')
    if ($idx -ge 0 -and -not $notesIndexByWidth.ContainsKey($hdr.Count)) { $notesIndexByWidth[$hdr.Count] = $idx }
}

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -notmatch $rowPattern) { continue }

    $cells = @($lines[$i].Trim().Trim('|') -split '(?<!\\)\|') | ForEach-Object { $_.Trim() }
    if ($cells.Count -lt 11) { continue }

    # Fall back to the last cell only when no header names Notes: every schema this script has
    # ever seen ends with it, so a headerless fixture still converts rather than silently skipping.
    $notesIdx = if ($notesIndexByWidth.ContainsKey($cells.Count)) { $notesIndexByWidth[$cells.Count] } else { $cells.Count - 1 }

    $bugId = $cells[0]
    $notes = $cells[$notesIdx]

    if ($notes -match '\[details\]\(#') {
        # Already converted — by a previous run, or by the writers self-healing this row.
        $skipped++
        continue
    }

    $segments = Split-LegacyNotes -Cell $notes
    $bullets = @()
    foreach ($seg in $segments) {
        if ($seg.Label) { $bullets += "- **$($seg.Label)**: $($seg.Value)" }
        else { $bullets += "- $($seg.Value)" }
    }
    if ($bullets.Count -eq 0) { $bullets = @('- _No recorded notes._') }

    # RECONCILIATION — per row, before anything is written anywhere.
    # An empty source cell is vacuously reconciled: there is no content to preserve, and the
    # block carries the '_No recorded notes._' placeholder, whose text is by definition absent
    # from the original. Comparing those two streams would fail every empty row (it did, on the
    # first run against APP-001 — the gate caught it before writing, which is its whole point).
    $originalStream = Get-AlnumStream ($notes -replace '\\\|', '|')
    $blockStream = if ($originalStream -eq '') { '' } else { Get-AlnumStream ($bullets -join ' ') }
    if ($originalStream -ne $blockStream) {
        $failures += [PSCustomObject]@{
            BugId    = $bugId
            Original = $originalStream.Length
            Block    = $blockStream.Length
        }
        continue
    }

    $lastSeg = if ($segments.Count -gt 0) { $segments[-1] } else { $null }
    $summary = if ($lastSeg -and $lastSeg.Label) { "$($lastSeg.Label): $($lastSeg.Value)" }
               elseif ($lastSeg) { $lastSeg.Value }
               else { 'No recorded notes' }

    $cells[$notesIdx] = Format-NotesCell -BugId $bugId -Summary $summary -Cap $SummaryLength
    $lines[$i] = '| ' + ($cells -join ' | ') + ' |'
    $blocks[$bugId] = $bullets
    $converted++
}

if ($failures.Count -gt 0) {
    Write-ProjectLog "Reconciliation FAILED for $($failures.Count) row(s) — nothing was written:" -Level "ERROR"
    foreach ($f in $failures) {
        Write-ProjectLog "  $($f.BugId): original $($f.Original) alphanumeric chars vs block $($f.Block)" -Level "ERROR"
    }
    Write-ProjectError -Message "Aborted before writing. No content is lost: the input file is untouched." -ExitCode 1
}

if ($converted -eq 0) {
    Write-ProjectLog "No unconverted bug rows found ($skipped already carry a pointer) — nothing to do." -Level "WARN"
    Write-ProjectSummary "$([System.IO.Path]::GetFileName($resolvedIn)): 0 converted, $skipped already converted"
    exit 0
}

# Place the blocks. Section placement mirrors the shipped templates: after '## Bug Statistics'
# where that exists, so detail prose stays below the region the writers scan for active-bug
# counts; otherwise at end of file (the archive has no statistics block).
$sectionIdx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq $BugDetailsHeading) { $sectionIdx = $i; break }
}
if ($sectionIdx -lt 0) {
    $statsIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s+Bug Statistics\s*$') { $statsIdx = $i; break }
    }
    $createAt = $lines.Count
    if ($statsIdx -ge 0) {
        for ($j = $statsIdx + 1; $j -lt $lines.Count; $j++) {
            if ($lines[$j] -match '^##\s' -or $lines[$j].Trim() -match '^(-{3,}|\*{3,}|_{3,})$') { $createAt = $j; break }
        }
        while ($createAt -gt $statsIdx + 1 -and [string]::IsNullOrWhiteSpace($lines[$createAt - 1])) { $createAt-- }
    }
    else {
        while ($createAt -gt 0 -and [string]::IsNullOrWhiteSpace($lines[$createAt - 1])) { $createAt-- }
    }
    $lines.InsertRange($createAt, [string[]]@('', $BugDetailsHeading))
    $sectionIdx = $createAt + 1
}

$insertAt = $lines.Count
for ($j = $sectionIdx + 1; $j -lt $lines.Count; $j++) {
    if ($lines[$j] -match '^##\s' -or $lines[$j].Trim() -match '^(-{3,}|\*{3,}|_{3,})$') { $insertAt = $j; break }
}
while ($insertAt -gt $sectionIdx + 1 -and [string]::IsNullOrWhiteSpace($lines[$insertAt - 1])) { $insertAt-- }

$emit = [System.Collections.Generic.List[string]]::new()
foreach ($bugId in $blocks.Keys) {
    $emit.Add('')
    $emit.Add("### $bugId")
    $emit.Add('')
    foreach ($b in $blocks[$bugId]) { $emit.Add($b) }
}
$lines.InsertRange($insertAt, [string[]]$emit)

# Drop the decorative empty-section placeholder now that blocks exist.
for ($i = $sectionIdx; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq '_No active bugs currently._') { $lines.RemoveAt($i); break }
}

$result = ($lines -join "`r`n")

if ($PSCmdlet.ShouldProcess($resolvedOut, "Write converted bug-tracking content ($converted row(s))")) {
    Set-Content -Path $resolvedOut -Value $result -NoNewline -Encoding UTF8

    # Post-write verification: every converted row must have exactly one block, and the input
    # must be byte-identical to what we read (proving the "never writes its input" property
    # rather than asserting it).
    $written = Get-Content -Path $resolvedOut -Raw -Encoding UTF8
    foreach ($bugId in $blocks.Keys) {
        $n = ([regex]::Matches($written, "(?m)^###\s+$([regex]::Escape($bugId))\s*$")).Count
        if ($n -ne 1) {
            Write-ProjectError -Message "Verification failed: $bugId has $n blocks in the output (expected 1)" -ExitCode 1
        }
    }
    if ((Get-Content -Path $resolvedIn -Raw -Encoding UTF8) -ne $content) {
        Write-ProjectError -Message "Verification failed: the input file changed during the run" -ExitCode 1
    }

    Write-ProjectLog "Converted $converted row(s); $skipped already carried a pointer" -Level "SUCCESS"
    Write-ProjectSummary "$([System.IO.Path]::GetFileName($resolvedIn)) -> $([System.IO.Path]::GetFileName($resolvedOut)): $converted converted, $skipped skipped. Input untouched; diff before swapping."
}
