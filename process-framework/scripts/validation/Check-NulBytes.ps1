<#
.SYNOPSIS
    Pre-commit guard against NUL-byte corruption in tracked text files (PF-IMP-1616).

.DESCRIPTION
    Scans every git-tracked file with a text extension for NUL bytes (0x00), which
    never legitimately appear in the framework's text artifacts. Grep-family tools
    silently classify NUL-containing files as binary and skip them, so this class of
    corruption is invisible to content searches — it must be looked for deliberately.

    Scope is the full tracked tree (git ls-files), independent of any beliefs about
    which directories matter: the PF-IMP-1472 incident fixed a 65,536-NUL payload in
    blueprint/doc/README.md and concluded from a blueprint-scoped scan that nothing
    else was affected, while the identical payload sat in appdev's own doc/README.md
    for four more days.

    Wired into .pre-commit-config.yaml as the `no-nul-bytes` hook.

.NOTES
    Exit codes:
        0 = no NUL bytes in any tracked text file (or not a git repo)
        1 = at least one tracked text file contains a NUL byte

    A legitimately non-UTF-8 text file (e.g. UTF-16, whose encoding embeds 0x00
    bytes) can be exempted via the Allowlist; none exist today.
#>

$ErrorActionPreference = 'Continue'

# Repo-root-relative paths exactly as git ls-files prints them (forward slashes).
$Allowlist = @()

# Extensions treated as text (mirrors the LinkWatcher monitored-type family).
$TextExtensions = @(
    '.md', '.json', '.ps1', '.psm1', '.py', '.yaml', '.yml', '.txt', '.csv',
    '.xml', '.html', '.js', '.ts', '.tsx', '.bat', '.toml', '.dart'
)

$trackedFiles = & git ls-files 2>$null
if ($LASTEXITCODE -ne 0 -or -not $trackedFiles) {
    exit 0
}

$violations = @()

foreach ($file in $trackedFiles) {
    $ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
    if ($TextExtensions -notcontains $ext) { continue }
    if ($Allowlist -contains $file) { continue }
    # Tracked but absent from the working tree (staged deletion) — nothing to scan.
    if (-not (Test-Path -LiteralPath $file)) { continue }

    try {
        $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $file).Path)
    } catch {
        Write-Host ("  WARN: could not read {0}: {1}" -f $file, $_.Exception.Message) -ForegroundColor Yellow
        continue
    }

    $idx = [System.Array]::IndexOf($bytes, [byte]0)
    if ($idx -ge 0) {
        $violations += [pscustomobject]@{
            File        = $file
            FirstOffset = $idx
            FileBytes   = $bytes.Length
        }
    }
}

if ($violations.Count -eq 0) {
    exit 0
}

Write-Host ""
Write-Host "ERROR: NUL-byte corruption detected in tracked text files" -ForegroundColor Red
Write-Host ""
foreach ($v in $violations) {
    Write-Host ("  {0}: first NUL at byte offset {1} (file size {2} bytes)" -f $v.File, $v.FirstOffset, $v.FileBytes) -ForegroundColor Red
}
Write-Host ""
Write-Host "A NUL byte (0x00) never legitimately appears in the framework's text files." -ForegroundColor Yellow
Write-Host "It indicates binary corruption (e.g. a NUL-padded write) that grep-family" -ForegroundColor Yellow
Write-Host "tools cannot see - they classify the file as binary and silently skip it." -ForegroundColor Yellow
Write-Host ""
Write-Host "See PF-IMP-1472 for the original incident (a 65,536-NUL payload that survived" -ForegroundColor Yellow
Write-Host "a scoped scan because it sat in a tree the scan skipped)." -ForegroundColor Yellow
Write-Host ""
Write-Host "For a legitimately NUL-containing text file (e.g. UTF-16 encoding), add the" -ForegroundColor DarkGray
Write-Host "repo-relative path to the Allowlist in process-framework/scripts/validation/Check-NulBytes.ps1." -ForegroundColor DarkGray
Write-Host ""

exit 1
