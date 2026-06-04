#!/usr/bin/env pwsh

<#
.SYNOPSIS
Computes and writes the Quality Assessment classification in a feature implementation state file (PF-TSK-065 Step 9).

.DESCRIPTION
This script automates the scoring + classification step of PF-TSK-065 Step 9
(Codebase Feature Analysis — Evaluate Implementation Quality). The agent fills
in the 5 dimension scores in Section "Quality Assessment" of the feature
implementation state file; this script computes Code Maturity + Test Maturity
and deterministically applies the classification rule, removing two recurring
LLM error patterns:

  1. Threshold misreads (using 1.5 instead of the spec's 2.0)
  2. Arithmetic transcription typos

The classification rule is the dual-score PF-TSK-065 spec (PF-IMP-019/032
resolution, 2026-05-08):

  - **Code Maturity** = avg of Structural clarity, Error handling,
    Data integrity, Maintainability (4 dimensions; Test coverage excluded)
  - **Test Maturity** = Test coverage score alone

  - Code Maturity >= 2.0 → As-Built
  - Code Maturity <  2.0 → Target-State

  Test Maturity does NOT affect classification; it is reported separately to
  drive a per-feature test-plan-urgency signal during downstream work.

The script:
  - Locates the "## N. Quality Assessment" section by regex (section number varies)
  - Parses the dimension scores table (5 rows: Structural clarity, Error handling,
    Data integrity, Test coverage, Maintainability)
  - Validates that all 5 scores are integers in 0-3
  - Computes Code Maturity (4-dim avg) and Test Maturity (TC alone) to 1 decimal
  - Applies the Code Maturity >= 2.0 threshold for the classification
  - Writes back the **Classification**, **Code Maturity**, and **Test Maturity** lines
  - Backward-compatible: a single legacy **Average Score** line in pre-PF-IMP-019/032
    state files is rewritten to the dual lines on first run (idempotent thereafter)

.PARAMETER StateFile
Path to a feature implementation state file (relative to project root or absolute).
Example: "doc/state-tracking/features/1.1.4-Reporting-implementation-state.md"

.PARAMETER WhatIf
Show the computed classification and the proposed file changes without writing.

.EXAMPLE
# Compute and write classification for one feature
.\Update-QualityClassification.ps1 -StateFile "doc/state-tracking/features/1.1.4-Reporting-implementation-state.md"

.EXAMPLE
# Preview without writing
.\Update-QualityClassification.ps1 -StateFile "doc/state-tracking/features/1.1.4-Reporting-implementation-state.md" -WhatIf

.NOTES
Resolves PF-IMP-033 (auto-classify) and PF-IMP-019/032 (dual-score model).
Created: 2026-05-07
Updated: 2026-05-08 (dual-score: Code Maturity drives classification; Test Maturity reported separately)
Version: 2.0
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$StateFile
)

# Import the common helpers (for Get-ProjectRoot)
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
$prevVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
$VerbosePreference = $prevVerbosePreference

# Soak verification (PF-PRO-028 v2.0 Pattern A)
Register-SoakScript
$soakInSoak = Test-ScriptInSoak

$ProjectRoot = Get-ProjectRoot

# Resolve StateFile to absolute path
if ([System.IO.Path]::IsPathRooted($StateFile)) {
    $resolvedPath = $StateFile
} else {
    $resolvedPath = Join-Path -Path $ProjectRoot -ChildPath $StateFile
}

if (-not (Test-Path $resolvedPath)) {
    Write-Host "[ERROR] State file not found: $resolvedPath" -ForegroundColor Red
    exit 1
}

# Read content (preserve original line endings via -Raw + manual split)
$content = Get-Content $resolvedPath -Raw
$lines = $content -split '\r?\n'

# --- Locate the "## N. Quality Assessment" section ---
$sectionStart = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^## \d+\.\s+Quality Assessment\s*$') {
        $sectionStart = $i
        break
    }
}
if ($sectionStart -lt 0) {
    Write-Host "[ERROR] Section '## N. Quality Assessment' not found in $resolvedPath" -ForegroundColor Red
    exit 1
}

# Find section end (next ## heading)
$sectionEnd = $lines.Count - 1
for ($i = $sectionStart + 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^## \S') {
        $sectionEnd = $i - 1
        break
    }
}

# --- Locate the dimension scores table ---
# Header row pattern: "| Dimension | Score (0-3) | Notes |"
$tableHeaderIdx = -1
for ($i = $sectionStart + 1; $i -le $sectionEnd; $i++) {
    if ($lines[$i] -match '^\|\s*Dimension\s*\|\s*Score\s*\(0-3\)\s*\|\s*Notes\s*\|') {
        $tableHeaderIdx = $i
        break
    }
}
if ($tableHeaderIdx -lt 0) {
    Write-Host "[ERROR] Quality Assessment dimension table not found (expected header: '| Dimension | Score (0-3) | Notes |')" -ForegroundColor Red
    exit 1
}

# Skip header + separator
$dataStartIdx = $tableHeaderIdx + 2

# Expected dimension names (must appear in this order; spec: PF-TSK-065 Step 9)
$expectedDimensions = @(
    'Structural clarity',
    'Error handling',
    'Data integrity',
    'Test coverage',
    'Maintainability'
)

# Parse 5 dimension rows
$scores = @()
$dataLines = @()
$rowIdx = $dataStartIdx
for ($d = 0; $d -lt $expectedDimensions.Count; $d++) {
    if ($rowIdx -gt $sectionEnd) {
        Write-Host "[ERROR] Reached end of section before parsing all 5 dimension rows (parsed $d, expected 5)" -ForegroundColor Red
        exit 1
    }
    $row = Split-MarkdownTableRow -Line $lines[$rowIdx]
    if (-not $row -or $row.Count -lt 3) {
        Write-Host "[ERROR] Expected dimension row at line $($rowIdx + 1) but found: '$($lines[$rowIdx])'" -ForegroundColor Red
        exit 1
    }
    $dim = $row[0]
    $scoreCell = $row[1]

    if ($dim -ne $expectedDimensions[$d]) {
        Write-Host "[ERROR] Dimension order mismatch at line $($rowIdx + 1): expected '$($expectedDimensions[$d])', found '$dim'" -ForegroundColor Red
        exit 1
    }

    # Score not yet filled in (template placeholder) — exit cleanly, not an error
    if ($scoreCell -match '^\[0-3\]$' -or [string]::IsNullOrWhiteSpace($scoreCell)) {
        Write-Host "[INFO] Scores not yet entered for '$dim' (line $($rowIdx + 1)). Fill in dimension scores before running this script." -ForegroundColor Yellow
        exit 0
    }

    # Score must be an integer 0-3
    if ($scoreCell -notmatch '^[0-3]$') {
        Write-Host "[ERROR] Invalid score '$scoreCell' for '$dim' at line $($rowIdx + 1). Expected integer 0-3." -ForegroundColor Red
        exit 1
    }

    $scores += [int]$scoreCell
    $dataLines += $rowIdx
    $rowIdx++
}

# --- Compute Code Maturity, Test Maturity, classification ---
# Dimension index in $scores: 0=SC, 1=EH, 2=DI, 3=TC, 4=Maint
$codeDimScores  = @($scores[0], $scores[1], $scores[2], $scores[4])
$codeSum        = ($codeDimScores | Measure-Object -Sum).Sum
$codeMaturity   = [math]::Round($codeSum / $codeDimScores.Count, 1)
$testMaturity   = $scores[3]
$classification = if ($codeMaturity -ge 2.0) { 'As-Built' } else { 'Target-State' }

# --- Locate Classification + Code Maturity + Test Maturity + (legacy) Average Score lines ---
# Within the section, before the table.
$classificationLineIdx = -1
$codeMaturityLineIdx   = -1
$testMaturityLineIdx   = -1
$legacyAverageLineIdx  = -1
for ($i = $sectionStart + 1; $i -lt $tableHeaderIdx; $i++) {
    if ($lines[$i] -match '^\*\*Classification\*\*:')       { $classificationLineIdx = $i }
    if ($lines[$i] -match '^\*\*Code Maturity\*\*:')        { $codeMaturityLineIdx = $i }
    if ($lines[$i] -match '^\*\*Test Maturity\*\*:')        { $testMaturityLineIdx = $i }
    if ($lines[$i] -match '^\*\*Average Score\*\*:')        { $legacyAverageLineIdx = $i }
}
if ($classificationLineIdx -lt 0) {
    Write-Host "[ERROR] '**Classification**:' line not found in Quality Assessment section" -ForegroundColor Red
    exit 1
}

# --- Build new lines ---
$newClassificationLine = "**Classification**: $classification"
$newCodeMaturityLine   = "**Code Maturity**: $codeMaturity / 3.0  *(avg of Structural clarity, Error handling, Data integrity, Maintainability)*"
$newTestMaturityLine   = "**Test Maturity**: $testMaturity / 3.0  *(Test coverage alone)*"

$changes = @()
$migrationFromLegacy = ($legacyAverageLineIdx -ge 0 -and $codeMaturityLineIdx -lt 0)

if ($lines[$classificationLineIdx] -ne $newClassificationLine) {
    $changes += "  Line $($classificationLineIdx + 1): '$($lines[$classificationLineIdx])' → '$newClassificationLine'"
}

if ($migrationFromLegacy) {
    # First run on a pre-PF-IMP-019/032 file: rewrite the single Average Score line into the two new lines.
    $changes += "  Line $($legacyAverageLineIdx + 1): rewriting legacy '**Average Score**' line as dual Code/Test Maturity lines"
} else {
    if ($codeMaturityLineIdx -ge 0) {
        if ($lines[$codeMaturityLineIdx] -ne $newCodeMaturityLine) {
            $changes += "  Line $($codeMaturityLineIdx + 1): '$($lines[$codeMaturityLineIdx])' → '$newCodeMaturityLine'"
        }
    } else {
        $changes += "  Insert '**Code Maturity**' line after '**Classification**'"
    }
    if ($testMaturityLineIdx -ge 0) {
        if ($lines[$testMaturityLineIdx] -ne $newTestMaturityLine) {
            $changes += "  Line $($testMaturityLineIdx + 1): '$($lines[$testMaturityLineIdx])' → '$newTestMaturityLine'"
        }
    } else {
        $changes += "  Insert '**Test Maturity**' line after '**Code Maturity**'"
    }
}

# --- Output: scores summary ---
$scoresStr = ($scores -join ', ')
Write-Host "Feature state file: $resolvedPath"
Write-Host "Dimension scores  : [$scoresStr]  (SC, EH, DI, TC, Maint)"
Write-Host "Code Maturity     : ($($codeDimScores -join ' + ')) / 4 = $codeMaturity"
Write-Host "Test Maturity     : $testMaturity"
Write-Host "Threshold         : Code Maturity >= 2.0 → As-Built; < 2.0 → Target-State"
Write-Host "Classification    : $classification" -ForegroundColor Green

if ($changes.Count -eq 0) {
    Write-Host "[INFO] File already matches computed values — no changes needed." -ForegroundColor Cyan
    exit 0
}

Write-Host ""
Write-Host "Proposed changes:"
foreach ($c in $changes) { Write-Host $c }

try {
    if ($PSCmdlet.ShouldProcess($resolvedPath, "Update Classification, Code Maturity, Test Maturity")) {
        $lines[$classificationLineIdx] = $newClassificationLine

        if ($migrationFromLegacy) {
            # Replace single legacy Average Score line with the two new lines (preserve in-place)
            $newLines = @()
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($i -eq $legacyAverageLineIdx) {
                    $newLines += $newCodeMaturityLine
                    $newLines += $newTestMaturityLine
                } else {
                    $newLines += $lines[$i]
                }
            }
            $lines = $newLines
        } else {
            if ($codeMaturityLineIdx -ge 0) {
                $lines[$codeMaturityLineIdx] = $newCodeMaturityLine
            }
            if ($testMaturityLineIdx -ge 0) {
                $lines[$testMaturityLineIdx] = $newTestMaturityLine
            }
            # Insert any missing lines immediately after Classification (rare; only if file was hand-edited)
            if ($codeMaturityLineIdx -lt 0 -or $testMaturityLineIdx -lt 0) {
                $newLines = @()
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    $newLines += $lines[$i]
                    if ($i -eq $classificationLineIdx) {
                        if ($codeMaturityLineIdx -lt 0) { $newLines += $newCodeMaturityLine }
                        if ($testMaturityLineIdx -lt 0) { $newLines += $newTestMaturityLine }
                    }
                }
                $lines = $newLines
            }
        }
        # Preserve trailing newline behaviour: rejoin with `n; if original ended with newline, ensure output does too
        $newContent = $lines -join "`n"
        if ($content.EndsWith("`n") -and -not $newContent.EndsWith("`n")) {
            $newContent += "`n"
        }
        Set-Content -Path $resolvedPath -Value $newContent -NoNewline -Encoding UTF8
        Write-Host ""
        Write-Host "[SUCCESS] Updated Classification, Code Maturity, and Test Maturity." -ForegroundColor Green
    }
    if ($soakInSoak) { Confirm-SoakInvocation -Outcome success }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -Outcome failure -Notes $soakErrMsg
    }
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
