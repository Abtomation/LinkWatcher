<#
.SYNOPSIS
    [DEPRECATED 2026-05-11] Detect blueprint pollution: occurrences of a source-project name in a target tree.

.DESCRIPTION
    *** DEPRECATED 2026-05-11 ***
    This script's sole consumer was PF-TSK-087 framework-blueprint-sync Step 11,
    which is deprecated as of 2026-05-11 (Centralized Framework Management
    extension, Phase 10). The replacement workflow — PF-TSK-088 Framework
    Rollout (Push/Restore model in appdev/process-framework-central/scripts/) —
    flows appdev -> projects only and has no reverse-sync step that could
    introduce project-name pollution into a blueprint. The script remains
    in-tree for historical reference but is not invoked by any active task.
    *** END DEPRECATION NOTE ***

    Automates the manual grep called for in PF-TSK-087 (framework-blueprint-sync)
    Step 11. After a project -> blueprint sync, scans the blueprint for any mention
    of the source project's name. Blueprints are meant to be project-neutral; any
    mention left behind will pollute every future project bootstrapped from the
    blueprint.

    Match is case-insensitive substring (exact-string only — no derived tokens,
    no snake_case / kebab-case variants). If a project name needs broader
    detection, run the script multiple times.

.PARAMETER ProjectName
    The source project's name to scan for (e.g. "LinkWatcher", "TimeTrackingV2").

.PARAMETER Path
    Root directory to scan. Defaults to current directory.

.PARAMETER ReportOnly
    Print findings but exit 0 even if violations exist. Useful for dry runs.

.NOTES
    Exit codes:
        0 = no violations (or -ReportOnly)
        1 = violations found

    Hard-coded exclusions (not configurable):
      - .git/, __pycache__/, node_modules/, .venv/, venv/  (tooling)
      - ratings.db, ratings.db.bak-*                        (protected binaries — PF-TSK-087)
      - sync-log.md, sync-backlog.md                        (legitimate audit trail)
      - The script's own file                               (matches its own param docs)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [switch]$ReportOnly
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Path -PathType Container)) {
    Write-Host "ERROR: Path not found or not a directory: $Path" -ForegroundColor Red
    exit 1
}

$TextExtensions = @(
    '.md', '.json', '.yaml', '.yml', '.ps1', '.psm1', '.py',
    '.txt', '.js', '.ts', '.tsx', '.html', '.xml', '.csv',
    '.toml', '.ini', '.sh', '.bat', '.dart'
)

$ExcludeDirs  = @('.git', '__pycache__', 'node_modules', '.venv', 'venv')
$ExcludeFiles = @('sync-log.md', 'sync-backlog.md')
$ExcludeGlobs = @('ratings.db', 'ratings.db.bak-*')

$selfFullPath = (Resolve-Path $PSCommandPath).Path
$resolvedRoot = (Resolve-Path $Path).Path

Write-Host ""
Write-Host "Scanning $resolvedRoot for occurrences of '$ProjectName' ..." -ForegroundColor Cyan
Write-Host ""

$candidates = Get-ChildItem -Path $resolvedRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $relPath = $_.FullName.Substring($resolvedRoot.Length).TrimStart('\', '/')
    $segments = $relPath -split '[\\/]'

    foreach ($seg in $segments) {
        if ($ExcludeDirs -contains $seg) { return $false }
    }
    if ($ExcludeFiles -contains $_.Name) { return $false }
    foreach ($glob in $ExcludeGlobs) {
        if ($_.Name -like $glob) { return $false }
    }
    if ($_.FullName -eq $selfFullPath) { return $false }
    if ($_.Extension -notin $TextExtensions) { return $false }
    return $true
}

$violations = @()
$pattern = [regex]::Escape($ProjectName)

foreach ($file in $candidates) {
    $relPath = $file.FullName.Substring($resolvedRoot.Length).TrimStart('\', '/').Replace('\', '/')
    try {
        $content = Get-Content -LiteralPath $file.FullName -ErrorAction Stop
    } catch {
        continue
    }
    $lineNum = 0
    foreach ($line in $content) {
        $lineNum++
        if ($line -imatch $pattern) {
            $violations += [pscustomobject]@{
                File  = $relPath
                Line  = $lineNum
                Match = $line.Trim()
            }
        }
    }
}

if ($violations.Count -eq 0) {
    Write-Host "OK: 0 occurrences of '$ProjectName' found." -ForegroundColor Green
    Write-Host "    Scanned $($candidates.Count) text files." -ForegroundColor DarkGray
    exit 0
}

$grouped = $violations | Group-Object File | Sort-Object Name

Write-Host "FOUND $($violations.Count) occurrence(s) of '$ProjectName' across $($grouped.Count) file(s):" -ForegroundColor Yellow
Write-Host ""
foreach ($g in $grouped) {
    Write-Host $g.Name -ForegroundColor Cyan
    foreach ($v in $g.Group) {
        $excerpt = if ($v.Match.Length -gt 120) { $v.Match.Substring(0, 117) + '...' } else { $v.Match }
        Write-Host ("  L{0}: {1}" -f $v.Line, $excerpt) -ForegroundColor DarkGray
    }
    Write-Host ""
}

Write-Host "Resolve these references in the blueprint before completing the sync." -ForegroundColor Yellow
Write-Host "If a mention is legitimate (e.g. a new audit-trail file like sync-log.md)," -ForegroundColor DarkGray
Write-Host "extend `$ExcludeFiles in $selfFullPath." -ForegroundColor DarkGray
Write-Host ""

if ($ReportOnly) {
    Write-Host "[-ReportOnly: exit 0 despite $($violations.Count) findings]" -ForegroundColor DarkGray
    exit 0
}

exit 1
