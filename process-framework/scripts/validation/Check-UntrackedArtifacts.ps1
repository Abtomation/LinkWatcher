<#
.SYNOPSIS
    Warn-first pre-commit / CI guard against framework artifacts that are invisible to git (PF-IMP-1771).

.DESCRIPTION
    A file that should be in version control but is not survives locally and vanishes on a
    fresh clone: it is absent from every rollout tag and from the backup remote, and nothing
    in a normal session reveals it — tests over it run green and the tree looks clean. The
    class has recurred three times in two distinct mechanisms:

      - PF-IMP-1489: an over-broad '.claude/' ignore pattern swallowed the entire craft-skill
        corpus (23 skills + settings.json).
      - PF-IMP-1578: the same pattern left the root .claude/settings.json — the load-bearing
        SessionStart hooks — ignored.
      - PF-IMP-1771: four *.Tests.ps1 files under test/automated/ were simply never added.

    Each was repaired as an instance; none left behind anything that would catch the next one.
    This script is that detector, and it needs two passes because the two mechanisms present
    differently to git:

      Pass A — NEVER ADDED: files git reports as untracked ('??'). Because new artifacts are
      created constantly and this workspace commits in batches, recency is not evidence of a
      problem; age is. Only artifacts untracked for longer than -MaxUntrackedAgeDays are
      reported, which separates work in progress from work abandoned. (Measured 2026-07-28:
      16 untracked artifacts, all created that day, versus the PF-IMP-1771 files that had sat
      untracked for weeks.)

      Pass B — SILENTLY IGNORED: files a .gitignore rule excludes ('!!'). These never appear
      as untracked at all — git considers them settled — so Pass A cannot see them. No age
      filter applies: an ignored framework artifact is wrong the moment it exists.

    Both passes are restricted to the trees that must survive a clone and to source/doc
    extensions, so ordinary ignore targets (logs, caches, virtualenvs) never match.

    Wired into .pre-commit-config.yaml as the `no-untracked-artifacts` hook.

.PARAMETER MaxUntrackedAgeDays
    Age in days beyond which an untracked artifact is reported by Pass A. Default 7.

.PARAMETER Blocking
    Exit non-zero when findings exist. Default is warn-first (report, exit 0), matching the
    staged promotion the other fleet gates follow (PF-IMP-1211).

.NOTES
    Exit codes:
        0 = no findings, or findings reported in warn-first mode (or not a git repo)
        1 = findings, and -Blocking was passed
#>

[CmdletBinding()]
param(
    [int]$MaxUntrackedAgeDays = 7,
    [switch]$Blocking
)

$ErrorActionPreference = 'Continue'

# Trees whose contents must survive a fresh clone.
$ScanTrees = @('blueprint/', 'test/', 'doc/', 'process-framework-central/', 'tools/')

# Extensions that are always authored artifacts, never build output or machine-local state.
$ArtifactExtensions = @('.ps1', '.psm1', '.py', '.md', '.json', '.yaml', '.yml')

# Repo-root-relative paths (forward slashes) exempt from either pass — e.g. a genuinely
# machine-local file that legitimately lives inside a scanned tree.
$Allowlist = @(
    'blueprint/.claude/settings.local.json',
    # Artifact Checkout Locking store (PF-PRO-061): gitignored machine state inside an
    # artifact tree by design — same repo-relative path in appdev and project layouts.
    'doc/state-tracking/artifact-locks.json'
)

# Pass B only: whole subtrees that are ignored BY DESIGN and would otherwise dominate the
# report. E2E acceptance tests build a throwaway sandbox per test case under
# <test-group>/workspace/, ignored via test/e2e-acceptance-testing/.gitignore — scratch by
# construction, and 20 of them exist mid-run on a normal day.
$IgnoredExclusionPatterns = @(
    '^test/e2e-acceptance-testing/[^/]+/workspace/'
)

function Select-Artifact {
    # Keeps only paths inside a scanned tree, carrying an artifact extension, not allowlisted.
    param([string[]]$Paths)

    $kept = @()
    foreach ($path in $Paths) {
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        if ($Allowlist -contains $path) { continue }
        if (-not ($ScanTrees | Where-Object { $path.StartsWith($_) })) { continue }
        $ext = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
        if ($ArtifactExtensions -notcontains $ext) { continue }
        $kept += $path
    }
    return $kept
}

function Get-StatusPath {
    # git status --porcelain prefixes each line with a 2-char code plus a space, and quotes
    # paths containing spaces or non-ASCII characters.
    param([string[]]$Lines, [string]$Marker)

    $paths = @()
    foreach ($line in $Lines) {
        if ($line -notmatch "^$([regex]::Escape($Marker)) ") { continue }
        $paths += $line.Substring(3).Trim().Trim('"')
    }
    return $paths
}

$statusLines = @(& git status --porcelain --untracked-files=all 2>$null)
if ($LASTEXITCODE -ne 0) { exit 0 }   # not a git repo — nothing to check

# --- Pass A: never added, and old enough to look abandoned rather than in progress ---
$cutoff = (Get-Date).AddDays(-$MaxUntrackedAgeDays)
$staleUntracked = @()
foreach ($path in (Select-Artifact -Paths (Get-StatusPath -Lines $statusLines -Marker '??'))) {
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $lastWrite = (Get-Item -LiteralPath $path).LastWriteTime
    if ($lastWrite -lt $cutoff) {
        $staleUntracked += [pscustomobject]@{
            Path    = $path
            AgeDays = [int]((Get-Date) - $lastWrite).TotalDays
        }
    }
}

# --- Pass B: silently ignored (invisible to Pass A; no age filter) ---
# Traditional --ignored (with -uall) lists the individual ignored FILES; --ignored=matching
# reports the directory that matched the pattern instead, which no extension filter can see.
$ignoredLines = @(& git status --porcelain --ignored --untracked-files=all 2>$null)
$ignoredArtifacts = @(Select-Artifact -Paths (Get-StatusPath -Lines $ignoredLines -Marker '!!') |
    Where-Object { $path = $_; -not ($IgnoredExclusionPatterns | Where-Object { $path -match $_ }) })

if ($staleUntracked.Count -eq 0 -and $ignoredArtifacts.Count -eq 0) { exit 0 }

Write-Host ""
Write-Host "WARNING: framework artifacts are invisible to git" -ForegroundColor Yellow
Write-Host ""

if ($staleUntracked.Count -gt 0) {
    Write-Host ("  Untracked for more than {0} day(s) — never added:" -f $MaxUntrackedAgeDays) -ForegroundColor Yellow
    foreach ($item in ($staleUntracked | Sort-Object -Property AgeDays -Descending)) {
        Write-Host ("    {0,4}d  {1}" -f $item.AgeDays, $item.Path) -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($ignoredArtifacts.Count -gt 0) {
    Write-Host "  Excluded by a .gitignore rule — an artifact tree should never be ignored:" -ForegroundColor Red
    foreach ($path in $ignoredArtifacts) {
        Write-Host ("    {0}" -f $path) -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "  Check which rule matches:  git check-ignore -v <path>" -ForegroundColor DarkGray
    Write-Host ""
}

Write-Host "These files exist locally but not in the repository: they are absent from every" -ForegroundColor Yellow
Write-Host "rollout tag and from the backup remote, and a fresh clone would not have them." -ForegroundColor Yellow
Write-Host "Commit them, or exempt a genuinely local file via the Allowlist in" -ForegroundColor Yellow
Write-Host "process-framework/scripts/validation/Check-UntrackedArtifacts.ps1." -ForegroundColor Yellow
Write-Host ""
Write-Host "Prior incidents of this class: PF-IMP-1489 (craft-skill corpus ignored)," -ForegroundColor DarkGray
Write-Host "PF-IMP-1578 (SessionStart hooks ignored), PF-IMP-1771 (four test files never added)." -ForegroundColor DarkGray
Write-Host ""

if ($Blocking) { exit 1 }
exit 0
