<#
.SYNOPSIS
Shared one-line description extractors for the documentation-map and task-metadata generators.

.DESCRIPTION
Single home for the per-artifact description extractors that Build-DocumentationMap.ps1
and Build-TaskMetadata.ps1 used to each carry a private near-identical copy of
(PF-IMP-1311 / constituents PF-IMP-1278 + PF-IMP-1301). Pure string functions — no
project context, no I/O encoding side effects — so the generators import this sub-module
directly rather than through the Common-ScriptHelpers umbrella.

  - Get-SynopsisDescription   — first .SYNOPSIS paragraph of a .ps1/.psm1 (PF-IMP-1272 join).
                                -ModuleLevel ignores a function-level .SYNOPSIS (PF-IMP-988).
  - Get-PyDocstringDescription — first paragraph of a .py module docstring, tolerant of a
                                leading shebang / coding-comment / blank-line header.
  - Get-MarkerDocDescription  — generic doc-comment extractor driven by a language pack's
                                doc_extraction spec (PF-IMP-1955): line-marker (///) and
                                block (/** */) forms, doc block must precede the first code
                                line. New languages declare their convention in
                                languages-config/{lang}/{lang}-config.json instead of adding
                                a bespoke function here.
#>

function Get-SynopsisDescription {
    # -ModuleLevel (for .psm1, PF-IMP-988): only a .SYNOPSIS appearing *before* the first
    # `function` describes the whole module. A function-level .SYNOPSIS is ignored (returns
    # $null -> the missing-description marker) so a multi-function module is never undersold
    # by one function's help line. Without the switch (e.g. .ps1) the first .SYNOPSIS wins.
    param([string]$Path, [switch]$ModuleLevel)
    # @() forces an array so the positional $lines[$i] reads below stay safe on a single-line
    # file (Get-Content returns a scalar string there — the scalar-unwrap footgun, PF-IMP-1331).
    $lines = @(Get-Content -Path $Path -ErrorAction SilentlyContinue)
    if (-not $lines) { return $null }
    $sawFunction = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($ModuleLevel -and $lines[$i] -match '^\s*function\s') { $sawFunction = $true }
        if ($lines[$i] -match '\.SYNOPSIS\s*$') {
            if ($ModuleLevel -and $sawFunction) { return $null }  # function-level synopsis != module description
            # Join the contiguous non-blank lines of the first .SYNOPSIS paragraph so a
            # description wrapped across lines is not truncated mid-sentence (PF-IMP-1272).
            $para = [System.Collections.Generic.List[string]]::new()
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                $l = $lines[$j]
                if ($l -match '^\s*\.[A-Za-z]+\s*$') { break }   # next help directive
                if ($l -match '#>') { break }                     # end of comment block
                $t = ($l -replace '^\s*#?\s*', '').Trim()
                if ($t) { $para.Add($t) }
                elseif ($para.Count -gt 0) { break }              # blank line ends the first paragraph
            }
            if ($para.Count -gt 0) { return ($para -join ' ') }
            break
        }
    }
    return $null
}

function Get-PyDocstringDescription {
    param([string]$Path)
    $raw = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { return $null }
    # The module docstring is the first *statement*, but it may be preceded by a shebang
    # (`#!/usr/bin/env python3`), an encoding/comment line, or blank lines — those leading
    # comment/blank lines are skipped so a shebang-led module is not falsely flagged
    # 'no description' (PF-IMP-1301). A triple-quoted string that follows real code is still
    # rejected (not a module docstring).
    $m = [regex]::Match($raw, '(?s)^(?:[^\S\n]*(?:#[^\n]*)?\n)*[^\S\n]*(?:[ruRU]{0,2})("""|'''''')(.*?)\1')
    if ($m.Success) {
        # Join the first paragraph of the docstring so a wrapped description is not
        # truncated mid-sentence (PF-IMP-1272).
        $para = [System.Collections.Generic.List[string]]::new()
        foreach ($line in ($m.Groups[2].Value -split "`n")) {
            $t = $line.Trim()
            if ($t) { $para.Add($t) }
            elseif ($para.Count -gt 0) { break }
        }
        if ($para.Count -gt 0) { return ($para -join ' ') }
    }
    return $null
}

function Get-MarkerDocDescription {
    param(
        [string]$Path,
        [Parameter(Mandatory)][object]$Spec
    )
    # Generic doc-comment extractor driven by a language pack's doc_extraction spec
    # (PF-IMP-1955). Spec fields: line_marker (e.g. '///'), optional block_start/block_end
    # (e.g. '/**' / '*/'), optional ignore_prefixes (non-doc comment prefixes such as '//'
    # or a '#!' shebang, skipped when scanning for the doc block). Rules mirror the sibling
    # extractors: the doc block must precede the first code line — a doc comment deeper in
    # the file is not a module description — and only the first paragraph is joined
    # (PF-IMP-1272). Doc markers are tested BEFORE ignore_prefixes: '///' also starts with
    # the '//' ignore prefix, so the order is load-bearing.
    $lines = @(Get-Content -Path $Path -ErrorAction SilentlyContinue)
    if (-not $lines) { return $null }
    $lineMarker = [string]$Spec.line_marker
    $blockStart = [string]$Spec.block_start
    $blockEnd   = [string]$Spec.block_end
    $ignore     = @($Spec.ignore_prefixes | Where-Object { $_ })
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $t = $lines[$i].Trim()
        if (-not $t) { continue }   # leading blank line
        if ($lineMarker -and $t.StartsWith($lineMarker)) {
            # Contiguous line-marker block; a blank doc line ends the first paragraph.
            $para = [System.Collections.Generic.List[string]]::new()
            for ($j = $i; $j -lt $lines.Count; $j++) {
                $lt = $lines[$j].Trim()
                if (-not $lt.StartsWith($lineMarker)) { break }
                $content = $lt.Substring($lineMarker.Length).Trim()
                if ($content) { $para.Add($content) }
                elseif ($para.Count -gt 0) { break }
            }
            if ($para.Count -gt 0) { return ($para -join ' ') }
            return $null
        }
        if ($blockStart -and $t.StartsWith($blockStart)) {
            # Block doc comment: collect until block_end; strip leading '*' decoration.
            $para = [System.Collections.Generic.List[string]]::new()
            for ($j = $i; $j -lt $lines.Count; $j++) {
                $seg = if ($j -eq $i) { $t.Substring($blockStart.Length) } else { $lines[$j] }
                $endIdx = if ($blockEnd) { $seg.IndexOf($blockEnd) } else { -1 }
                if ($endIdx -ge 0) { $seg = $seg.Substring(0, $endIdx) }
                $content = ($seg -replace '^\s*\*+\s?', '').Trim()
                if ($content) { $para.Add($content) }
                elseif ($para.Count -gt 0) { break }
                if ($endIdx -ge 0) { break }
            }
            if ($para.Count -gt 0) { return ($para -join ' ') }
            return $null
        }
        if (@($ignore | Where-Object { $t.StartsWith([string]$_) }).Count -gt 0) { continue }
        return $null   # first code line reached with no doc block found
    }
    return $null
}

Export-ModuleMember -Function Get-SynopsisDescription, Get-PyDocstringDescription, Get-MarkerDocDescription
