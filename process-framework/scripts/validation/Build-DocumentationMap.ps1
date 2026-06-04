<#
.SYNOPSIS
    Generates PF-documentation-map.md from per-artifact .SYNOPSIS/frontmatter descriptions; also checks for drift and reports artifacts missing a source description (PF-PRO-037).

.DESCRIPTION
    Inverts the documentation-map dependency: instead of hand-maintaining
    PF-documentation-map.md, this script renders it from each artifact's own
    one-line description at its source:

      - PowerShell (.ps1/.psm1) -> comment-based help .SYNOPSIS (first line)
      - Python (.py)            -> module docstring (first line)
      - Markdown (.md)          -> 'description:' frontmatter field
      - JSON (.json)            -> metadata.description (or top-level description)

    The on-disk map becomes a generated, DO-NOT-EDIT projection. Drift and
    orphans become impossible by construction. Mirrors the regenerate-from-disk
    pattern New-TestInfrastructure.ps1 uses for test/audits/README.md.

    Self-auditing: an artifact with no extractable description is still indexed,
    rendered with a missing-description marker, and listed by -ReportMissing.

    Modes:
      (default)      Write PF-documentation-map.md.
      -Check         Regenerate to memory, diff against on-disk; exit 1 on drift.
                     Replaces Validate-DocumentationMap.ps1 (PF-IMP-836).
      -ReportMissing List every artifact lacking a source description; exit 1 if any.

.PARAMETER ProjectRoot
    Repo root. Auto-detected from this script's location if omitted.

.PARAMETER FrameworkRoot
    Root of the framework tree being indexed. Defaults to
    <ProjectRoot>/blueprint/process-framework.

.PARAMETER MapPath
    Path to the documentation map. Defaults to <FrameworkRoot>/PF-documentation-map.md.

.PARAMETER Check
    Regenerate to memory and compare against the on-disk map. Exit 1 on drift.

.PARAMETER ReportMissing
    Print artifacts with no extractable source description. Exit 1 if any exist.

.NOTES
    Exit codes:
        0 = success (generated / in sync / no missing descriptions)
        1 = drift detected (-Check) or missing descriptions found (-ReportMissing)
        2 = script error (missing paths)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ProjectRoot,
    [string]$FrameworkRoot,
    [string]$MapPath,
    [switch]$Check,
    [switch]$ReportMissing
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
$indexableExtensions = @('.md', '.ps1', '.psm1', '.py', '.json', '.template')
$exemptNames = @(
    'README.md',
    'PF-documentation-map.md',
    '.gitkeep',
    '.framework-version',
    '.framework-version-previous'
)
# Subtrees indexed (recursively), in render order. Root-level files are indexed separately.
$indexedSubdirs = @('tasks', 'templates', 'guides', 'visualization', 'infrastructure', 'scripts', 'tools')
$missingMarker = '⚠️ _(no description — add to .SYNOPSIS/frontmatter)_'

# ---------------------------------------------------------------------------
# Description extractors (one-liner from each artifact's own source)
# ---------------------------------------------------------------------------
function Get-SynopsisDescription {
    param([string]$Path)
    $lines = Get-Content -Path $Path -ErrorAction SilentlyContinue
    if (-not $lines) { return $null }
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '\.SYNOPSIS\s*$') {
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                $l = $lines[$j]
                if ($l -match '^\s*\.[A-Za-z]+\s*$') { break }   # next help directive
                if ($l -match '#>') { break }                     # end of comment block
                $t = ($l -replace '^\s*#?\s*', '').Trim()
                if ($t) { return $t }
            }
            break
        }
    }
    return $null
}

function Get-PyDocstringDescription {
    param([string]$Path)
    $raw = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { return $null }
    $m = [regex]::Match($raw, '(?s)^\s*(?:[ruRU]{0,2})("""|'''''')(.*?)\1')
    if ($m.Success) {
        foreach ($line in ($m.Groups[2].Value -split "`n")) {
            $t = $line.Trim()
            if ($t) { return $t }
        }
    }
    return $null
}

function Get-FrontmatterDescription {
    param([string]$Path)
    $lines = Get-Content -Path $Path -ErrorAction SilentlyContinue
    if (-not $lines -or $lines.Count -eq 0) { return $null }
    if ($lines[0].Trim() -ne '---') { return $null }
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { break }   # end of frontmatter
        if ($lines[$i] -match '^\s*description:\s*(.+?)\s*$') {
            return ($matches[1].Trim().Trim('"').Trim("'"))
        }
    }
    return $null
}

function Get-JsonDescription {
    param([string]$Path)
    try {
        $obj = Get-Content -Path $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    } catch { return $null }
    if ($obj.PSObject.Properties.Name -contains 'metadata' -and $obj.metadata.PSObject.Properties.Name -contains 'description') {
        return [string]$obj.metadata.description
    }
    if ($obj.PSObject.Properties.Name -contains 'description') {
        return [string]$obj.description
    }
    return $null
}

function Get-ArtifactDescription {
    param([System.IO.FileInfo]$File)
    switch ($File.Extension.ToLower()) {
        '.ps1'      { return Get-SynopsisDescription -Path $File.FullName }
        '.psm1'     { return Get-SynopsisDescription -Path $File.FullName }
        '.py'       { return Get-PyDocstringDescription -Path $File.FullName }
        '.md'       { return Get-FrontmatterDescription -Path $File.FullName }
        '.template' { return Get-FrontmatterDescription -Path $File.FullName }
        '.json'     { return Get-JsonDescription -Path $File.FullName }
        default     { return $null }
    }
}

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
if (-not $ProjectRoot) {
    # scripts/validation -> scripts -> process-framework -> blueprint -> appdev
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
}
if (-not $FrameworkRoot) {
    $FrameworkRoot = Join-Path $ProjectRoot 'blueprint/process-framework'
}
if (-not $MapPath) {
    $MapPath = Join-Path $FrameworkRoot 'PF-documentation-map.md'
}
if (-not (Test-Path $FrameworkRoot)) {
    Write-Host "[ERROR] FrameworkRoot not found: $FrameworkRoot" -ForegroundColor Red
    exit 2
}
$frameworkRootFull = (Resolve-Path $FrameworkRoot).Path

# ---------------------------------------------------------------------------
# Collect indexable files
# ---------------------------------------------------------------------------
function Test-Indexable {
    param([System.IO.FileInfo]$File)
    if ($exemptNames -contains $File.Name) { return $false }
    if ($indexableExtensions -notcontains $File.Extension.ToLower()) { return $false }
    return $true
}

$entries = [System.Collections.Generic.List[object]]::new()

function Add-Entry {
    param([System.IO.FileInfo]$File)
    $rel = $File.FullName.Substring($frameworkRootFull.Length + 1) -replace '\\', '/'
    $desc = Get-ArtifactDescription -File $File
    $dir = ($rel -replace '/[^/]+$', '')
    if ($dir -eq $rel) { $dir = '.' }   # root-level file
    $entries.Add([pscustomobject]@{
        Rel     = $rel
        Dir     = $dir
        Name    = $File.Name
        Desc    = $desc
        Missing = [string]::IsNullOrWhiteSpace($desc)
    })
}

# Root-level files
Get-ChildItem -Path $frameworkRootFull -File -ErrorAction SilentlyContinue | ForEach-Object {
    if (Test-Indexable -File $_) { Add-Entry -File $_ }
}
# Subtrees
foreach ($subdir in $indexedSubdirs) {
    $dir = Join-Path $frameworkRootFull $subdir
    if (-not (Test-Path $dir)) { continue }
    Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        if (Test-Indexable -File $_) { Add-Entry -File $_ }
    }
}

# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------
function Build-MapContent {
    $sb = [System.Collections.Generic.List[string]]::new()
    $sb.Add('<!-- AUTO-GENERATED FILE — DO NOT EDIT MANUALLY -->')
    $sb.Add('<!-- Regenerate with: blueprint/process-framework/scripts/validation/Build-DocumentationMap.ps1 -->')
    $sb.Add('')
    $sb.Add('# Process Framework Documentation Map')
    $sb.Add('')
    $sb.Add('This index of every framework artifact is **generated** from each artifact''s own one-line')
    $sb.Add('description — `.SYNOPSIS` for scripts, the `description:` frontmatter field for markdown.')
    $sb.Add('Do not edit this file by hand: run `scripts/validation/Build-DocumentationMap.ps1` to regenerate it,')
    $sb.Add('and `Build-DocumentationMap.ps1 -Check` to verify it is in sync. Entries marked')
    $sb.Add('"' + $missingMarker + '" need a description added at the artifact''s source.')
    $sb.Add('')

    # Group by directory; sort directories then files.
    $byDir = $entries | Group-Object Dir | Sort-Object {
        if ($_.Name -eq '.') { '' } else { $_.Name }   # root first
    }
    foreach ($grp in $byDir) {
        $heading = if ($grp.Name -eq '.') { 'process-framework/ (root)' } else { $grp.Name }
        $sb.Add("## $heading")
        $sb.Add('')
        foreach ($e in ($grp.Group | Sort-Object Name)) {
            $descText = if ($e.Missing) { $missingMarker } else { $e.Desc }
            $sb.Add("- [$($e.Name)]($($e.Rel)) — $descText")
        }
        $sb.Add('')
    }
    return ($sb -join "`n").TrimEnd() + "`n"
}

$generated = Build-MapContent

# ---------------------------------------------------------------------------
# Mode dispatch
# ---------------------------------------------------------------------------
$missing = $entries | Where-Object { $_.Missing } | Sort-Object Rel

if ($ReportMissing) {
    if ($missing.Count -eq 0) {
        Write-Host "[PASS] All $($entries.Count) indexed artifacts have a source description." -ForegroundColor Green
        exit 0
    }
    Write-Host "[REPORT] $($missing.Count) of $($entries.Count) indexed artifacts have no source description:" -ForegroundColor Yellow
    foreach ($m in $missing) { Write-Host "    $($m.Rel)" -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "  Add a .SYNOPSIS (scripts) or 'description:' frontmatter (markdown) to each." -ForegroundColor Gray
    exit 1
}

if ($Check) {
    $onDisk = if (Test-Path $MapPath) { Get-Content -Path $MapPath -Raw -Encoding UTF8 } else { '' }
    $normGen  = ($generated -replace "`r`n", "`n").TrimEnd()
    $normDisk = ($onDisk    -replace "`r`n", "`n").TrimEnd()
    if ($normGen -eq $normDisk) {
        Write-Host "[PASS] Documentation map in sync — $($entries.Count) artifacts indexed." -ForegroundColor Green
        exit 0
    }
    Write-Host "[FAIL] Documentation map is out of date — regenerate with Build-DocumentationMap.ps1." -ForegroundColor Red
    if ($missing.Count -gt 0) {
        Write-Host "       ($($missing.Count) artifacts also lack a source description — see -ReportMissing.)" -ForegroundColor Yellow
    }
    exit 1
}

# Default: generate
if ($PSCmdlet.ShouldProcess($MapPath, "Write generated documentation map ($($entries.Count) artifacts)")) {
    [System.IO.File]::WriteAllText($MapPath, $generated, [System.Text.UTF8Encoding]::new($false))
    Write-Host "[OK] Generated $MapPath — $($entries.Count) artifacts indexed, $($missing.Count) missing a description." -ForegroundColor Green
}
exit 0
