<#
.SYNOPSIS
    Pre-commit guard against .git/objects/<hex>/<sha> literal corruption (PF-IMP-615).

.DESCRIPTION
    Scans staged files for the literal pattern .git/objects/<2-hex>/<38-hex>, which
    should never appear in tracked project files (it's a git loose-object path used
    only inside .git/ internals). The pattern indicates a path-resolution bug that
    returned a git-objects path and then propagated through a bulk find/replace.

    Original incident: PF-IMP-590 (2026-04-28) — a bulk-update commit on 2026-04-03
    corrupted 16 files; framework tooling silently degraded for 3 weeks before
    detection. PF-IMP-196 (2026-03-25) had patched one occurrence individually
    without recognizing the broader pattern.

    Wired into .pre-commit-config.yaml as the `no-git-objects-literal` hook.

.NOTES
    Exit codes:
        0 = no violations (or no staged files)
        1 = at least one staged file contains the corruption pattern

    The 3 forensic-record files in the Allowlist legitimately reference the literal
    as evidence trail (per PF-IMP-590: "intentionally left unmodified to preserve
    evidence"). They are skipped to avoid false positives.
#>

$ErrorActionPreference = 'Continue'

$Allowlist = @(
    'process-framework-local/state-tracking/permanent/process-improvement-tracking.md',
    'doc/state-tracking/permanent/bug-tracking.md',
    'process-framework-local/state-tracking/temporary/old/structure-change-test-directory-consolidation.md'
)

$Pattern = '\.git/objects/[0-9a-f]{2}/[0-9a-f]{38}'

$stagedFiles = & git diff --cached --name-only --diff-filter=ACMR 2>$null
if ($LASTEXITCODE -ne 0 -or -not $stagedFiles) {
    exit 0
}

$violations = @()

foreach ($file in $stagedFiles) {
    if ($Allowlist -contains $file) { continue }

    $stagedContent = & git show ":$file" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $stagedContent) { continue }

    $lineNum = 0
    foreach ($line in ($stagedContent -split "`r?`n")) {
        $lineNum++
        if ($line -match $Pattern) {
            $violations += [pscustomobject]@{
                File  = $file
                Line  = $lineNum
                Match = $Matches[0]
            }
        }
    }
}

if ($violations.Count -eq 0) {
    exit 0
}

Write-Host ""
Write-Host "ERROR: .git/objects/ literal corruption detected in staged files" -ForegroundColor Red
Write-Host ""
foreach ($v in $violations) {
    Write-Host ("  {0}:{1}: {2}" -f $v.File, $v.Line, $v.Match) -ForegroundColor Red
}
Write-Host ""
Write-Host "This pattern (.git/objects/<2-hex>/<38-hex>) is a git loose-object path" -ForegroundColor Yellow
Write-Host "and must never appear in tracked project files. It usually indicates a" -ForegroundColor Yellow
Write-Host "path-resolution bug that returned a git-objects path which then propagated" -ForegroundColor Yellow
Write-Host "through a bulk find/replace operation." -ForegroundColor Yellow
Write-Host ""
Write-Host "See PF-IMP-590 for the original incident (16 files, 3-week silent degradation)." -ForegroundColor Yellow
Write-Host ""
Write-Host "To bypass this hook for a legitimate forensic edit, add the file path to the" -ForegroundColor DarkGray
Write-Host "Allowlist in process-framework/scripts/validation/Check-GitObjectsLiteral.ps1." -ForegroundColor DarkGray
Write-Host ""

exit 1
