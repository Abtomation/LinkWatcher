<#
.SYNOPSIS
Generates the task-metadata projections — ai-tasks.md task tables, process-framework-task-registry.md, task-transition-registry.md, and the tasks/README catalog — from task-file frontmatter and authored sections; -Check drift gate; -ReportMissing schema-conformance report (PF-IMP-1134 / PF-PRO-042).

.DESCRIPTION
Inverts the task-metadata dependency (sibling of Build-DocumentationMap.ps1): task
definition files under tasks/** are the single source of truth — frontmatter fields
(complexity, use_when, triggers, frequency, automation, scripts, trigger_status,
output_status, next_tasks) plus two authored body sections (File Operations, and the
transition subsections inside Next Tasks). This script renders every downstream
overview from that source:

  1. ai-tasks.md            — per-category task tables inside BEGIN/END GENERATED
                              marked regions (hand-written prose untouched)
  2. process-framework-task-registry.md
                            — fully generated at its current path: automation status
                              summary, task catalog (with FILE OPERATIONS tables and
                              TRIGGER & OUTPUT blocks), State File Trigger Index, and
                              script inventory (from .SYNOPSIS lines + reverse index
                              of task `scripts:` references). Named HAND-WRITTEN
                              regions (head, analysis-notes, catalog-tombstones,
                              trigger-chain-diagrams) are preserved verbatim.
  3. task-transition-registry.md
                            — fully generated: per-task "Transitioning FROM" sections
                              aggregated from each task file's transition subsections.
                              HAND-WRITTEN regions (head, non-task-entries, tail)
                              preserved verbatim.
  4. tasks/README.md        — catalog tables inside a BEGIN/END GENERATED region

A task file is "routed" iff its frontmatter carries `use_when`. Files under tasks/**
without it (READMEs, path companions, deprecated tasks) are excluded by design.

Frontmatter path values (scripts, next_tasks[].task) and links embedded in use_when /
File Operations / transition content are task-file-relative (LinkWatcher-maintained);
this script rebases them to each projection's directory at render time.

Modes:
  (default)      Rewrite the four projection targets in place (ShouldProcess-guarded).
  -Check         Regenerate to memory, diff against disk; exit 1 on drift.
  -ReportMissing List routed task files missing required fields/sections; exit 1 if any.
  -OutputDir D   Write the four rendered files into directory D instead of in place
                 (cutover preview — real targets are still read for HAND-WRITTEN regions).

.PARAMETER FrameworkRoot
Root of the process-framework tree. Auto-detected from this script's location.

.PARAMETER Check
Regenerate to memory and compare against the on-disk projections. Exit 1 on drift. The FAIL
output names, per drifted projection, the source task file(s) whose rendered metadata differs
and the differing lines themselves (PF-IMP-1720) — so drift is attributable to your own edit
versus a parallel session's without an mtime scan of the tasks tree.

.PARAMETER DriftLineLimit
Maximum differing lines shown per drifted projection in -Check output (default 12). Raise it
when a projection drifted broadly and the truncated listing hides the relevant line.

.PARAMETER ReportMissing
Report routed task files lacking required metadata. Exit 1 if any.

.PARAMETER OutputDir
Preview directory: rendered projections are written here (flat, original file names)
instead of overwriting the real targets.

.NOTES
Exit codes:
    0 = success (generated / in sync / nothing missing)
    1 = drift detected (-Check) or missing metadata (-ReportMissing)
    2 = script error (missing module, targets, markers, or HAND-WRITTEN regions)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$FrameworkRoot,
    [switch]$Check,
    [switch]$ReportMissing,
    [string]$OutputDir,
    [ValidateRange(1, 1000)]
    [int]$DriftLineLimit = 12
)

$ErrorActionPreference = 'Stop'

try {
    Import-Module powershell-yaml -ErrorAction Stop
} catch {
    Write-Host "[ERROR] powershell-yaml module is required (Install-Module powershell-yaml -Scope CurrentUser): $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}

# Shared description extractors (PF-IMP-1311) — imported directly (not via the
# Common-ScriptHelpers umbrella, whose import sets console/UTF-8 encoding defaults).
$descExtractionModule = Join-Path $PSScriptRoot '..\Common-ScriptHelpers\DescriptionExtraction.psm1'
try {
    Import-Module $descExtractionModule -Force -ErrorAction Stop
} catch {
    Write-Host "[ERROR] Failed to import DescriptionExtraction module ($descExtractionModule): $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}

# ---------------------------------------------------------------------------
# Path helpers (same conventions as the retired Bootstrap-TaskMetadata.ps1 one-shot, inverse direction; PF-PRO-068 Session B disposal)
# ---------------------------------------------------------------------------
function ConvertTo-NormalizedRelPath {
    # Collapse ./ and ../ segments of a forward-slash relative path.
    param([string]$Path)
    $parts = ($Path -replace '\\', '/') -split '/'
    $stack = [System.Collections.Generic.List[string]]::new()
    foreach ($p in $parts) {
        if ($p -eq '' -or $p -eq '.') { continue }
        if ($p -eq '..') {
            if ($stack.Count -gt 0 -and $stack[$stack.Count - 1] -ne '..') { $stack.RemoveAt($stack.Count - 1) }
            else { $stack.Add('..') }
        } else { $stack.Add($p) }
    }
    return ($stack -join '/')
}

function Resolve-FromDir {
    # Resolve a relative link against a pf-root-relative directory -> pf-root-relative path.
    param([string]$Dir, [string]$Rel)
    if ($Dir) { return ConvertTo-NormalizedRelPath "$Dir/$Rel" }
    return ConvertTo-NormalizedRelPath $Rel
}

function Get-RelativePathBetween {
    # Relative path from pf-root-relative dir $FromDir to pf-root-relative file $Target.
    param([string]$FromDir, [string]$Target)
    # @() around the whole if: a single-segment dir would otherwise unwrap to a
    # scalar string and [$i] would index a character (quick-reference footgun).
    $fromParts = @(if ($FromDir) { $FromDir -split '/' })
    $toParts   = @($Target -split '/')
    $i = 0
    while ($i -lt $fromParts.Count -and $i -lt ($toParts.Count - 1) -and $fromParts[$i] -eq $toParts[$i]) { $i++ }
    $ups = @('..') * ($fromParts.Count - $i)
    $rest = $toParts[$i..($toParts.Count - 1)]
    return (@($ups) + @($rest)) -join '/'
}

function Update-RelativeLinks {
    # Rewrite markdown link targets in $Text authored relative to $FromDir so they
    # resolve from $ToDir instead. Skips URLs, anchors, and absolute paths.
    param([string]$Text, [string]$FromDir, [string]$ToDir)
    return [regex]::Replace($Text, '\]\(([^)#\s]+)(#[^)\s]*)?\)', {
        param($m)
        $target = $m.Groups[1].Value
        $anchor = $m.Groups[2].Value
        if ($target -match '^(https?:|mailto:|/)') { return $m.Value }
        $abs = Resolve-FromDir -Dir $FromDir -Rel $target
        $new = Get-RelativePathBetween -FromDir $ToDir -Target $abs
        return "]($new$anchor)"
    })
}

# ---------------------------------------------------------------------------
# Description extractors: Get-SynopsisDescription / Get-PyDocstringDescription are
# shared with Build-DocumentationMap.ps1 via DescriptionExtraction.psm1 (imported
# above, PF-IMP-1311). This script's script-inventory only scans .ps1/.py, so it
# never passes -ModuleLevel — behavior is unchanged by the consolidation.

# ---------------------------------------------------------------------------
# Marked-region helpers
# ---------------------------------------------------------------------------
function Get-HandWrittenRegion {
    # Inner content of a named HAND-WRITTEN region, or $null when absent.
    param([string]$Content, [string]$Name)
    $m = [regex]::Match($Content, "(?s)<!-- BEGIN HAND-WRITTEN: $([regex]::Escape($Name)) -->(.*?)<!-- END HAND-WRITTEN: $([regex]::Escape($Name)) -->")
    if (-not $m.Success) { return $null }
    return $m.Groups[1].Value.Trim("`r", "`n")
}

function Set-GeneratedRegion {
    # Replace the inner content of a named GENERATED region. Returns updated content;
    # records the name in $MissingList when the marker pair is absent.
    param(
        [string]$Content,
        [string]$Name,
        [string]$Body,
        [string]$NL,
        [System.Collections.Generic.List[string]]$MissingList
    )
    $pattern = "(?s)(<!-- BEGIN GENERATED: $([regex]::Escape($Name)) -->).*?(<!-- END GENERATED: $([regex]::Escape($Name)) -->)"
    if ($Content -notmatch $pattern) {
        $MissingList.Add($Name)
        return $Content
    }
    return [regex]::Replace($Content, $pattern, {
        param($m)
        $m.Groups[1].Value + $NL + $Body + $NL + $m.Groups[2].Value
    })
}

function Add-HandWrittenBlock {
    # Append a HAND-WRITTEN region (markers + preserved content) to a line list.
    param([System.Collections.Generic.List[string]]$Lines, [string]$Name, [string]$Body)
    $Lines.Add("<!-- BEGIN HAND-WRITTEN: $Name -->")
    foreach ($l in ($Body -replace "`r`n", "`n") -split "`n") { $Lines.Add($l) }
    $Lines.Add("<!-- END HAND-WRITTEN: $Name -->")
}

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
if (-not $FrameworkRoot) {
    $FrameworkRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
}
if (-not (Test-Path $FrameworkRoot)) {
    Write-Host "[ERROR] FrameworkRoot not found: $FrameworkRoot" -ForegroundColor Red
    exit 2
}
$pfRoot = (Resolve-Path $FrameworkRoot).Path

$targets = [ordered]@{
    AiTasks    = Join-Path $pfRoot 'ai-tasks.md'
    Readme     = Join-Path $pfRoot 'tasks/README.md'
    Registry   = Join-Path $pfRoot 'infrastructure/process-framework-task-registry.md'
    Transition = Join-Path $pfRoot 'infrastructure/task-transition-registry.md'
}
foreach ($t in $targets.GetEnumerator()) {
    if (-not (Test-Path $t.Value)) {
        Write-Host "[ERROR] Projection target not found: $($t.Value)" -ForegroundColor Red
        exit 2
    }
}

$autoGenHeader = @(
    '<!-- GENERATED FILE (Build-TaskMetadata.ps1, PF-PRO-042) — edit task files under tasks/**, then regenerate. -->'
    '<!-- Hand-edits are allowed ONLY inside BEGIN/END HAND-WRITTEN regions; everything else is overwritten. -->'
)

# ---------------------------------------------------------------------------
# Category metadata (fixed render order)
# ---------------------------------------------------------------------------
$categoryOrder = @('00-setup', '01-planning', '02-design', '03-testing', '04-implementation', '05-validation', '06-maintenance', '07-deployment', 'cyclical', 'support')
$categoryInfo = @{
    '00-setup'          = @{ Heading = '00 - Setup Tasks';          Kind = 'standard' }
    '01-planning'       = @{ Heading = '01 - Planning Tasks';       Kind = 'standard' }
    '02-design'         = @{ Heading = '02 - Design Tasks';         Kind = 'standard' }
    '03-testing'        = @{ Heading = '03 - Testing Tasks';        Kind = 'standard' }
    '04-implementation' = @{ Heading = '04 - Implementation Tasks'; Kind = 'standard' }
    '05-validation'     = @{ Heading = '05 - Validation Tasks';     Kind = 'standard' }
    '06-maintenance'    = @{ Heading = '06 - Maintenance Tasks';    Kind = 'standard' }
    '07-deployment'     = @{ Heading = '07 - Deployment Tasks';     Kind = 'standard' }
    'cyclical'          = @{ Heading = 'Cyclical Tasks';            Kind = 'cyclical' }
    'support'           = @{ Heading = 'Support Tasks';             Kind = 'support' }
}
$complexityDisplay = @{ simple = '🟢 Simple'; medium = '🟡 Medium'; complex = '🔴 Complex' }
$automationLabel = [ordered]@{
    full    = '✅ **Fully Automated**'
    semi    = '🔄 **Semi-Automated**'
    partial = '🔄 **Partially Automated**'
    manual  = '🔧 **Manual**'
}
$automationBucketHeading = @{
    full    = '### ✅ Fully Automated Tasks'
    semi    = '### 🔄 Semi-Automated Tasks'
    partial = '### 🔄 Partially Automated Tasks'
    manual  = '### 🔧 Manual Tasks'
}

# ---------------------------------------------------------------------------
# Parse task files
# ---------------------------------------------------------------------------
$tasks = [System.Collections.Generic.List[object]]::new()
$nonRouted = [System.Collections.Generic.List[string]]::new()
$parseErrors = [System.Collections.Generic.List[string]]::new()

foreach ($f in (Get-ChildItem (Join-Path $pfRoot 'tasks') -Recurse -Filter '*.md' -File | Sort-Object FullName)) {
    $rel = ConvertTo-NormalizedRelPath ($f.FullName.Substring($pfRoot.Length + 1))
    $raw = Get-Content $f.FullName -Raw -Encoding UTF8
    $fmMatch = [regex]::Match($raw, "(?ms)\A---\r?\n(.*?)^---\s*$")
    if (-not $fmMatch.Success) { $nonRouted.Add($rel); continue }
    try {
        $fm = ConvertFrom-Yaml $fmMatch.Groups[1].Value
    } catch {
        $parseErrors.Add("${rel}: frontmatter YAML parse failed — $($_.Exception.Message)")
        continue
    }
    if (-not ($fm -is [System.Collections.IDictionary]) -or -not $fm.Contains('use_when') -or [string]::IsNullOrWhiteSpace([string]$fm['use_when'])) {
        $nonRouted.Add($rel)
        continue
    }

    $titleMatch = [regex]::Match($raw, '(?m)^# (.+)$')
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { $f.BaseName }

    $category = ($rel -split '/')[1]
    if ($categoryOrder -notcontains $category) {
        $parseErrors.Add("${rel}: unknown task category directory '$category'")
        continue
    }

    $fileOps = ''
    $foMatch = [regex]::Match($raw, '(?ms)^## File Operations\s*?$(.*?)(?=^## |\z)')
    if ($foMatch.Success) { $fileOps = $foMatch.Groups[1].Value.Trim("`r", "`n") }

    $transition = ''
    $ntMatch = [regex]::Match($raw, '(?ms)^## Next Tasks\s*?$(.*?)(?=^## |\z)')
    if ($ntMatch.Success) {
        $ntBody = $ntMatch.Groups[1].Value
        $trStart = [regex]::Match($ntBody, '(?m)^(?:<!-- merged from |### )')
        if ($trStart.Success) {
            $transition = $ntBody.Substring($trStart.Index).Trim("`r", "`n")
        }
    }

    $tasks.Add([pscustomobject]@{
        Rel        = $rel
        RelDir     = ((Split-Path $rel -Parent) -replace '\\', '/')
        Category   = $category
        Title      = $title
        Id         = [string]$fm['id']
        Fm         = $fm
        FileOps    = $fileOps
        Transition = $transition
    })
}

if ($parseErrors.Count) {
    Write-Host "[ERROR] Task file parse failures:" -ForegroundColor Red
    foreach ($e in $parseErrors) { Write-Host "    $e" -ForegroundColor Red }
    exit 2
}

# PF-IMP-1720: lookups for -Check drift attribution. A projection line names its source task
# either by its `tasks/...md` path (rebased per projection, so only the tail is stable) or by
# its title in a transition heading — index both once rather than re-scanning $tasks per line.
$script:DriftOutsideKey = '(outside any per-task region)'
$script:TaskRelByTail = @{}
$script:TaskRelByTitle = @{}
foreach ($t in $tasks) {
    $segments = $t.Rel -split '/'
    $tail = ($segments[-2..-1]) -join '/'     # <category>/<file>.md — unique across the tree
    if (-not $script:TaskRelByTail.ContainsKey($tail)) { $script:TaskRelByTail[$tail] = $t.Rel }
    if (-not $script:TaskRelByTitle.ContainsKey($t.Title)) { $script:TaskRelByTitle[$t.Title] = $t.Rel }
}

function Get-CategoryTasks {
    param([string]$Category)
    return @($tasks | Where-Object { $_.Category -eq $Category } | Sort-Object Title)
}

function Format-StatusEntry {
    # trigger_status / output_status entry -> display text
    param($Entry)
    if ($Entry -is [System.Collections.IDictionary] -and $Entry.Contains('file')) {
        $text = '`' + $Entry['file'] + '` → `' + $Entry['status'] + '`'
        if ($Entry.Contains('condition') -and -not [string]::IsNullOrWhiteSpace([string]$Entry['condition'])) {
            $text += " _($($Entry['condition']))_"
        }
        return $text
    }
    if ($Entry -is [System.Collections.IDictionary] -and $Entry.Contains('raw')) { return [string]$Entry['raw'] }
    return [string]$Entry
}

# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------
function Build-AiTasksTable {
    param([string]$Category)
    $rows = Get-CategoryTasks -Category $Category
    $kind = $categoryInfo[$Category].Kind
    $lines = [System.Collections.Generic.List[string]]::new()
    switch ($kind) {
        'cyclical' {
            $lines.Add('| Task | Trigger | Frequency | Link |')
            $lines.Add('| ---- | ------- | --------- | ---- |')
            foreach ($t in $rows) {
                $useWhen = Update-RelativeLinks -Text ([string]$t.Fm['use_when']) -FromDir $t.RelDir -ToDir ''
                $freq = if ($t.Fm.ContainsKey('frequency')) { [string]$t.Fm['frequency'] } else { '' }
                $lines.Add("| **$($t.Title)** | $useWhen | $freq | [→ Definition]($($t.Rel)) |")
            }
        }
        'support' {
            $lines.Add('| Task | Use When | Link |')
            $lines.Add('| ---- | -------- | ---- |')
            foreach ($t in $rows) {
                $useWhen = Update-RelativeLinks -Text ([string]$t.Fm['use_when']) -FromDir $t.RelDir -ToDir ''
                $lines.Add("| **$($t.Title)** | $useWhen | [→ Definition]($($t.Rel)) |")
            }
        }
        default {
            $lines.Add('| Task | Use When | Complexity | Link |')
            $lines.Add('| ---- | -------- | ---------- | ---- |')
            foreach ($t in $rows) {
                $useWhen = Update-RelativeLinks -Text ([string]$t.Fm['use_when']) -FromDir $t.RelDir -ToDir ''
                $cx = if ($t.Fm.ContainsKey('complexity')) { $complexityDisplay[[string]$t.Fm['complexity']] } else { '' }
                $lines.Add("| **$($t.Title)** | $useWhen | $cx | [→ Definition]($($t.Rel)) |")
            }
        }
    }
    return ($lines -join "`n")
}

function Build-ReadmeCatalog {
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($cat in $categoryOrder) {
        $rows = Get-CategoryTasks -Category $cat
        if (-not $rows.Count) { continue }
        $lines.Add("### $($categoryInfo[$cat].Heading)")
        $lines.Add('')
        $lines.Add('| Task | Description |')
        $lines.Add('| ---- | ----------- |')
        foreach ($t in $rows) {
            $desc = if ($t.Fm.ContainsKey('description')) { ([string]$t.Fm['description']).Trim() } else { '' }
            $desc = Update-RelativeLinks -Text $desc -FromDir $t.RelDir -ToDir 'tasks'
            $linkRel = Get-RelativePathBetween -FromDir 'tasks' -Target $t.Rel
            $lines.Add("| [$($t.Title)]($linkRel) | $desc |")
        }
        $lines.Add('')
    }
    while ($lines.Count -and $lines[$lines.Count - 1] -eq '') { $lines.RemoveAt($lines.Count - 1) }
    return ($lines -join "`n")
}

function Build-CatalogEntry {
    param($Task)
    $lines = [System.Collections.Generic.List[string]]::new()
    $entryLink = Get-RelativePathBetween -FromDir 'infrastructure' -Target $Task.Rel
    $lines.Add("#### **$($Task.Title)** ([$($Task.Id)]($entryLink))")
    $lines.Add('')
    $auto = if ($Task.Fm.ContainsKey('automation')) { [string]$Task.Fm['automation'] } else { '' }
    if ($auto -and $automationLabel.Contains($auto)) {
        $lines.Add("**🔧 Process Type:** $($automationLabel[$auto])")
        $lines.Add('')
    }
    if ($Task.Fm.ContainsKey('scripts') -and $Task.Fm['scripts']) {
        $scriptLinks = foreach ($s in @($Task.Fm['scripts'])) {
            $abs = Resolve-FromDir -Dir $Task.RelDir -Rel ([string]$s)
            $rebased = Get-RelativePathBetween -FromDir 'infrastructure' -Target $abs
            $name = ($abs -split '/')[-1]
            "[``$name``]($rebased)"
        }
        $lines.Add("**Scripts:** $($scriptLinks -join ', ')")
        $lines.Add('')
    }
    if ($Task.FileOps) {
        $lines.Add('**📁 FILE OPERATIONS**')
        $lines.Add('')
        $rebasedOps = Update-RelativeLinks -Text $Task.FileOps -FromDir $Task.RelDir -ToDir 'infrastructure'
        foreach ($l in ($rebasedOps -replace "`r`n", "`n") -split "`n") { $lines.Add($l) }
        $lines.Add('')
    }
    $hasTrig = $Task.Fm.ContainsKey('trigger_status') -and $Task.Fm['trigger_status']
    $hasOut  = $Task.Fm.ContainsKey('output_status') -and $Task.Fm['output_status']
    if ($hasTrig -or $hasOut) {
        $lines.Add('**🔗 TRIGGER & OUTPUT**')
        $lines.Add('')
        if ($hasTrig) { foreach ($e in @($Task.Fm['trigger_status'])) { $lines.Add("- **Trigger:** $(Format-StatusEntry $e)") } }
        if ($hasOut)  { foreach ($e in @($Task.Fm['output_status']))  { $lines.Add("- **Output:** $(Format-StatusEntry $e)") } }
        $lines.Add('')
    }
    while ($lines.Count -and $lines[$lines.Count - 1] -eq '') { $lines.RemoveAt($lines.Count - 1) }
    return ($lines -join "`n")
}

function Build-AutomationSummary {
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($bucket in $automationLabel.Keys) {
        $bucketTasks = @($tasks | Where-Object {
            $_.Fm.ContainsKey('automation') -and [string]$_.Fm['automation'] -eq $bucket
        } | Sort-Object Title)
        if (-not $bucketTasks.Count) { continue }
        $lines.Add($automationBucketHeading[$bucket])
        $lines.Add('')
        foreach ($t in $bucketTasks) {
            $link = Get-RelativePathBetween -FromDir 'infrastructure' -Target $t.Rel
            $lines.Add("- **$($t.Title)** ([$($t.Id)]($link))")
        }
        $lines.Add('')
    }
    while ($lines.Count -and $lines[$lines.Count - 1] -eq '') { $lines.RemoveAt($lines.Count - 1) }
    return ($lines -join "`n")
}

function Build-TriggerIndex {
    $structured = [System.Collections.Generic.List[object]]::new()
    $unstructured = [System.Collections.Generic.List[string]]::new()
    foreach ($t in ($tasks | Sort-Object Id)) {
        if (-not ($t.Fm.ContainsKey('trigger_status') -and $t.Fm['trigger_status'])) { continue }
        $link = Get-RelativePathBetween -FromDir 'infrastructure' -Target $t.Rel
        foreach ($e in @($t.Fm['trigger_status'])) {
            if ($e -is [System.Collections.IDictionary] -and $e.Contains('file')) {
                $structured.Add([pscustomobject]@{ File = [string]$e['file']; Status = [string]$e['status']; Id = $t.Id; Title = $t.Title; Link = $link })
            } elseif ($e -is [System.Collections.IDictionary] -and $e.Contains('raw')) {
                $rawText = [string]$e['raw']
                if ($rawText -ne '_(user request)_') {
                    $unstructured.Add("- $rawText — [$($t.Id)]($link) $($t.Title)")
                }
            }
        }
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('Which status in which file triggers which task.')
    $lines.Add('')
    $lines.Add('| State File | Status Value | Triggers Task |')
    $lines.Add('|------------|-------------|---------------|')
    foreach ($row in ($structured | Sort-Object File, Status, Id)) {
        $lines.Add('| `' + $row.File + '` | `' + $row.Status + '` | [' + $row.Id + '](' + $row.Link + ') ' + $row.Title + ' |')
    }
    if ($unstructured.Count) {
        $lines.Add('')
        $lines.Add('Unstructured triggers (no single state-file status):')
        $lines.Add('')
        foreach ($u in $unstructured) { $lines.Add($u) }
    }
    return ($lines -join "`n")
}

function Build-ScriptInventory {
    $groupHeading = [ordered]@{
        'file-creation' = '### File Creation Scripts'
        'update'        = '### State Update Scripts'
        'validation'    = '### Validation Scripts'
        'test'          = '### Testing Scripts'
        'other'         = '### Orchestration & Utility Scripts'
    }
    # Reverse index: pf-root-relative script path -> [task ids]
    $usedBy = @{}
    foreach ($t in $tasks) {
        if (-not ($t.Fm.ContainsKey('scripts') -and $t.Fm['scripts'])) { continue }
        foreach ($s in @($t.Fm['scripts'])) {
            $abs = Resolve-FromDir -Dir $t.RelDir -Rel ([string]$s)
            if (-not $usedBy.ContainsKey($abs)) { $usedBy[$abs] = [System.Collections.Generic.List[string]]::new() }
            if ($usedBy[$abs] -notcontains $t.Id) { $usedBy[$abs].Add($t.Id) }
        }
    }
    $scriptsDir = Join-Path $pfRoot 'scripts'
    $files = @(Get-ChildItem $scriptsDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        @('.ps1', '.py') -contains $_.Extension.ToLower() -and
        $_.FullName -notmatch '[/]Common-ScriptHelpers[/]'
    })
    $entries = foreach ($f in $files) {
        $rel = ConvertTo-NormalizedRelPath ($f.FullName.Substring($pfRoot.Length + 1))   # scripts/...
        $loc = ($rel -replace '^scripts/', '') -replace '/[^/]+$', ''
        if ($loc -eq ($rel -replace '^scripts/', '')) { $loc = '.' } else { $loc += '/' }
        $groupKey = if ($loc -eq '.') { 'other' } else { ($loc -split '/')[0] }
        if (-not $groupHeading.Contains($groupKey)) { $groupKey = 'other' }
        $purpose = if ($f.Extension -eq '.py') { Get-PyDocstringDescription -Path $f.FullName } else { Get-SynopsisDescription -Path $f.FullName }
        if ([string]::IsNullOrWhiteSpace($purpose)) { $purpose = '⚠️ _(no description — add to .SYNOPSIS/docstring)_' }
        $ub = if ($usedBy.ContainsKey($rel)) { (@($usedBy[$rel]) | Sort-Object) -join ', ' } else { '—' }
        [pscustomobject]@{ Group = $groupKey; Name = $f.Name; Loc = $loc; UsedBy = $ub; Purpose = $purpose }
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('Generated from script `.SYNOPSIS`/docstring lines and the reverse index of task-file `scripts:` references. `Common-ScriptHelpers` sub-modules are catalogued in the [documentation map](../PF-documentation-map.md).')
    $lines.Add('')
    foreach ($g in $groupHeading.Keys) {
        $groupEntries = @($entries | Where-Object { $_.Group -eq $g } | Sort-Object Loc, Name)
        if (-not $groupEntries.Count) { continue }
        $lines.Add($groupHeading[$g])
        $lines.Add('')
        $lines.Add('| Script | Location | Used By Task(s) | Purpose |')
        $lines.Add('|--------|----------|------------------|---------|')
        foreach ($e in $groupEntries) {
            $lines.Add('| `' + $e.Name + '` | `' + $e.Loc + '` | ' + $e.UsedBy + ' | ' + $e.Purpose + ' |')
        }
        $lines.Add('')
    }
    while ($lines.Count -and $lines[$lines.Count - 1] -eq '') { $lines.RemoveAt($lines.Count - 1) }
    return ($lines -join "`n")
}

function Build-TransitionSection {
    param($Task)
    $body = $Task.Transition -replace "`r`n", "`n"
    $outLines = [System.Collections.Generic.List[string]]::new()
    $skipNextBlank = $false
    foreach ($l in ($body -split "`n")) {
        if ($skipNextBlank -and $l.Trim() -eq '') { $skipNextBlank = $false; continue }
        $skipNextBlank = $false
        if ($l -match '^### Transition Procedure\s*$') { $skipNextBlank = $true; continue }
        if ($l -match '^### (Prerequisites for Transition|Next Task Selection|Preparation for Next Task)\s*$') {
            $outLines.Add("**$($Matches[1]):**")
            continue
        }
        if ($l -match '^### (.+)$') {
            $outLines.Add("**$($Matches[1].Trim()):**")
            continue
        }
        $outLines.Add($l)
    }
    $text = ($outLines -join "`n").Trim("`n")
    $text = Update-RelativeLinks -Text $text -FromDir $Task.RelDir -ToDir 'infrastructure'
    $idSuffix = if ($Task.Id) { " ($($Task.Id))" } else { '' }
    return "### Transitioning FROM $($Task.Title)$idSuffix`n`n$text"
}

function Get-FrontmatterBlock {
    param([string]$Content)
    # CRLF-tolerant closing fence (PF-IMP-1154): in multiline mode `$` matches before `\n`,
    # leaving the `\r` of a CRLF line unconsumed by `[ \t]*`; the trailing `\r?` absorbs it so
    # CRLF registries (Windows editors / git autocrlf / LinkWatcher) match as well as LF ones.
    $m = [regex]::Match($Content, "(?ms)\A---\r?\n.*?^---[ \t]*\r?$")
    if (-not $m.Success) { return $null }
    return $m.Value -replace "`r`n", "`n"
}

function Build-RegistryContent {
    param([string]$ExistingRaw, [System.Collections.Generic.List[string]]$MissingRegions)
    $fmBlock = Get-FrontmatterBlock -Content $ExistingRaw
    if (-not $fmBlock) { $MissingRegions.Add('frontmatter'); return $null }
    $hw = @{}
    foreach ($name in @('head', 'analysis-notes', 'catalog-tombstones', 'trigger-chain-diagrams')) {
        $hw[$name] = Get-HandWrittenRegion -Content $ExistingRaw -Name $name
        if ($null -eq $hw[$name]) { $MissingRegions.Add($name) }
    }
    if ($MissingRegions.Count) { return $null }

    $outL = [System.Collections.Generic.List[string]]::new()
    foreach ($l in ($fmBlock -split "`n")) { $outL.Add($l) }
    $outL.Add('')
    foreach ($l in $autoGenHeader) { $outL.Add($l) }
    $outL.Add('')
    Add-HandWrittenBlock -Lines $outL -Name 'head' -Body $hw['head']
    $outL.Add('')
    $outL.Add('## 🎯 Automation Status Summary')
    $outL.Add('')
    foreach ($l in ((Build-AutomationSummary) -split "`n")) { $outL.Add($l) }
    $outL.Add('')
    Add-HandWrittenBlock -Lines $outL -Name 'analysis-notes' -Body $hw['analysis-notes']
    $outL.Add('')
    $outL.Add('## Task Catalog')
    $outL.Add('')
    foreach ($cat in $categoryOrder) {
        $catTasks = Get-CategoryTasks -Category $cat
        if (-not $catTasks.Count) { continue }
        $outL.Add("### **$($categoryInfo[$cat].Heading)**")
        $outL.Add('')
        foreach ($t in $catTasks) {
            foreach ($l in ((Build-CatalogEntry -Task $t) -split "`n")) { $outL.Add($l) }
            $outL.Add('')
        }
    }
    Add-HandWrittenBlock -Lines $outL -Name 'catalog-tombstones' -Body $hw['catalog-tombstones']
    $outL.Add('')
    $outL.Add('## State File Trigger Index')
    $outL.Add('')
    foreach ($l in ((Build-TriggerIndex) -split "`n")) { $outL.Add($l) }
    $outL.Add('')
    Add-HandWrittenBlock -Lines $outL -Name 'trigger-chain-diagrams' -Body $hw['trigger-chain-diagrams']
    $outL.Add('')
    $outL.Add('## Script Inventory')
    $outL.Add('')
    foreach ($l in ((Build-ScriptInventory) -split "`n")) { $outL.Add($l) }
    return (($outL -join "`n").TrimEnd() + "`n")
}

function Build-TransitionRegistryContent {
    param([string]$ExistingRaw, [System.Collections.Generic.List[string]]$MissingRegions)
    $fmBlock = Get-FrontmatterBlock -Content $ExistingRaw
    if (-not $fmBlock) { $MissingRegions.Add('frontmatter'); return $null }
    $hw = @{}
    foreach ($name in @('head', 'non-task-entries', 'tail')) {
        $hw[$name] = Get-HandWrittenRegion -Content $ExistingRaw -Name $name
        if ($null -eq $hw[$name]) { $MissingRegions.Add($name) }
    }
    if ($MissingRegions.Count) { return $null }

    $outL = [System.Collections.Generic.List[string]]::new()
    foreach ($l in ($fmBlock -split "`n")) { $outL.Add($l) }
    $outL.Add('')
    foreach ($l in $autoGenHeader) { $outL.Add($l) }
    $outL.Add('')
    Add-HandWrittenBlock -Lines $outL -Name 'head' -Body $hw['head']
    $outL.Add('')
    $outL.Add('## Detailed Transition Procedures')
    $outL.Add('')
    foreach ($cat in $categoryOrder) {
        foreach ($t in (Get-CategoryTasks -Category $cat)) {
            if (-not $t.Transition) { continue }
            foreach ($l in ((Build-TransitionSection -Task $t) -split "`n")) { $outL.Add($l) }
            $outL.Add('')
        }
    }
    Add-HandWrittenBlock -Lines $outL -Name 'non-task-entries' -Body $hw['non-task-entries']
    $outL.Add('')
    Add-HandWrittenBlock -Lines $outL -Name 'tail' -Body $hw['tail']
    return (($outL -join "`n").TrimEnd() + "`n")
}

function Build-AiTasksContent {
    param([string]$ExistingRaw, [System.Collections.Generic.List[string]]$MissingRegions)
    $nl = if ($ExistingRaw -match "`r`n") { "`r`n" } else { "`n" }
    $content = $ExistingRaw
    foreach ($cat in $categoryOrder) {
        if (-not (Get-CategoryTasks -Category $cat).Count) { continue }
        $body = (Build-AiTasksTable -Category $cat) -replace "`n", $nl
        $content = Set-GeneratedRegion -Content $content -Name "task-table:$cat" -Body $body -NL $nl -MissingList $MissingRegions
    }
    return $content
}

function Build-ReadmeContent {
    param([string]$ExistingRaw, [System.Collections.Generic.List[string]]$MissingRegions)
    $nl = if ($ExistingRaw -match "`r`n") { "`r`n" } else { "`n" }
    $body = (Build-ReadmeCatalog) -replace "`n", $nl
    return (Set-GeneratedRegion -Content $ExistingRaw -Name 'task-catalog' -Body $body -NL $nl -MissingList $MissingRegions)
}

# ---------------------------------------------------------------------------
# -ReportMissing mode
# ---------------------------------------------------------------------------
if ($ReportMissing) {
    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($t in ($tasks | Sort-Object Rel)) {
        $kind = $categoryInfo[$t.Category].Kind
        if (-not $t.Id) { $missing.Add("$($t.Rel): missing 'id'") }
        if (-not ($t.Fm.ContainsKey('automation') -and $automationLabel.Contains([string]$t.Fm['automation']))) {
            $missing.Add("$($t.Rel): missing or invalid 'automation' (full|semi|partial|manual)")
        }
        if ($kind -eq 'standard' -and -not ($t.Fm.ContainsKey('complexity') -and $complexityDisplay.ContainsKey([string]$t.Fm['complexity']))) {
            $missing.Add("$($t.Rel): missing or invalid 'complexity' (simple|medium|complex)")
        }
        if ($kind -eq 'cyclical' -and -not $t.Fm.ContainsKey('frequency')) {
            $missing.Add("$($t.Rel): missing 'frequency' (required for cyclical tasks)")
        }
        if (-not $t.FileOps) { $missing.Add("$($t.Rel): missing '## File Operations' section") }
        if (-not $t.Transition) { $missing.Add("$($t.Rel): missing transition subsections in '## Next Tasks'") }
    }
    if ($nonRouted.Count) {
        Write-Host "[INFO] Non-routed files under tasks/ (no 'use_when' — excluded by design):" -ForegroundColor Gray
        foreach ($n in ($nonRouted | Sort-Object)) { Write-Host "    $n" -ForegroundColor Gray }
        Write-Host ''
    }
    if (-not $missing.Count) {
        Write-Host "[PASS] All $($tasks.Count) routed task files carry the required metadata." -ForegroundColor Green
        exit 0
    }
    Write-Host "[REPORT] $($missing.Count) gaps across routed task files:" -ForegroundColor Yellow
    foreach ($m in $missing) { Write-Host "    $m" -ForegroundColor Yellow }
    exit 1
}

# ---------------------------------------------------------------------------
# Render all four projections
# ---------------------------------------------------------------------------
$rendered = [ordered]@{}
$regionErrors = [System.Collections.Generic.List[string]]::new()

$raws = @{}
foreach ($key in $targets.Keys) { $raws[$key] = Get-Content $targets[$key] -Raw -Encoding UTF8 }

$missAi = [System.Collections.Generic.List[string]]::new()
$rendered['AiTasks'] = Build-AiTasksContent -ExistingRaw $raws['AiTasks'] -MissingRegions $missAi
foreach ($m in $missAi) { $regionErrors.Add("ai-tasks.md: missing marker pair '<!-- BEGIN/END GENERATED: $m -->'") }

$missReadme = [System.Collections.Generic.List[string]]::new()
$rendered['Readme'] = Build-ReadmeContent -ExistingRaw $raws['Readme'] -MissingRegions $missReadme
foreach ($m in $missReadme) { $regionErrors.Add("tasks/README.md: missing marker pair '<!-- BEGIN/END GENERATED: $m -->'") }

$missReg = [System.Collections.Generic.List[string]]::new()
$rendered['Registry'] = Build-RegistryContent -ExistingRaw $raws['Registry'] -MissingRegions $missReg
foreach ($m in $missReg) { $regionErrors.Add("process-framework-task-registry.md: missing HAND-WRITTEN region '$m'") }

$missTr = [System.Collections.Generic.List[string]]::new()
$rendered['Transition'] = Build-TransitionRegistryContent -ExistingRaw $raws['Transition'] -MissingRegions $missTr
foreach ($m in $missTr) { $regionErrors.Add("task-transition-registry.md: missing HAND-WRITTEN region '$m'") }

if ($regionErrors.Count) {
    Write-Host "[ERROR] Required markers/regions are missing — seed them before generating:" -ForegroundColor Red
    foreach ($e in $regionErrors) { Write-Host "    $e" -ForegroundColor Red }
    exit 2
}

# ---------------------------------------------------------------------------
# Mode dispatch
# ---------------------------------------------------------------------------
function Compare-Normalized {
    param([string]$A, [string]$B)
    return (($A -replace "`r`n", "`n").TrimEnd() -eq ($B -replace "`r`n", "`n").TrimEnd())
}

function Get-AnchorTaskRel {
    # PF-IMP-1720: if this line OPENS a per-task region, return that task's Rel, else $null.
    # Every per-task region opens with an anchor carrying the task's identity — a link to its
    # task file (ai-tasks rows, README rows, registry catalog headings) or a
    # `### Transitioning FROM <Title>` heading (transition registry). Body lines inside a
    # region carry no identity of their own (a File Operations row is just a table row); the
    # caller assigns them to the region they fall in.
    param([string]$Line)

    # Only the four shapes that OPEN a per-task region count as anchors. Matching any task
    # link would mis-attribute: a File Operations row inside one task's section routinely
    # links to other task files, and the nearest link is then the wrong owner.
    # Link tails are matched as <category>/<file>.md rather than a leading 'tasks/', because
    # each projection rebases task links to its own directory (ai-tasks.md renders
    # 'tasks/06-.../x.md' where tasks/README.md renders '06-.../x.md' for the same task).
    $linkAnchors = @(
        '\[→ Definition\]\([^)]*?([A-Za-z0-9._\-]+/[A-Za-z0-9._\-]+\.md)\)'          # ai-tasks table row
        '^\|\s*\[[^\]]+\]\([^)]*?([A-Za-z0-9._\-]+/[A-Za-z0-9._\-]+\.md)\)\s*\|'     # tasks/README catalog row
        '^#### \*\*.+?\*\* \(\[[A-Z]{2,4}-TSK-\d+\]\([^)]*?([A-Za-z0-9._\-]+/[A-Za-z0-9._\-]+\.md)\)\)'  # registry catalog entry
    )

    foreach ($pattern in $linkAnchors) {
        $m = [regex]::Match($Line, $pattern)
        if ($m.Success) {
            $tail = ConvertTo-NormalizedRelPath $m.Groups[1].Value
            if ($script:TaskRelByTail.ContainsKey($tail)) { return $script:TaskRelByTail[$tail] }
        }
    }

    $trMatch = [regex]::Match($Line, '^### Transitioning FROM (.+?)(?:\s+\([A-Z]{2,4}-TSK-\d+\))?\s*$')
    if ($trMatch.Success) {
        $title = $trMatch.Groups[1].Value.Trim()
        if ($script:TaskRelByTitle.ContainsKey($title)) { return $script:TaskRelByTitle[$title] }
    }

    return $null
}

function Split-ProjectionRegion {
    # PF-IMP-1720: bucket a projection's lines into per-task regions, keyed by task Rel.
    # Lines before the first anchor (and any that follow a non-task section) stay in the
    # OUTSIDE bucket — script inventory, automation summary, hand-written regions.
    param([string[]]$Lines)

    $regions = @{}
    $current = $script:DriftOutsideKey
    $regions[$current] = [System.Collections.Generic.List[string]]::new()

    foreach ($line in $Lines) {
        # A per-task region ends at the next h1-h3 section heading. Without this the trailing
        # non-task sections (Script Inventory, State File Trigger Index) would be absorbed into
        # whichever task's catalog entry happened to render last, and every edit to them would
        # be blamed on that task. Task anchors are h4 (`#### **Title** (…)`) or the explicit
        # `### Transitioning FROM` heading, so neither is caught by the reset.
        if ($line -match '^#{1,3}\s' -and $line -notmatch '^### Transitioning FROM ') {
            $current = $script:DriftOutsideKey
        }

        $rel = Get-AnchorTaskRel -Line $line
        if ($rel) {
            $current = $rel
            if (-not $regions.ContainsKey($current)) { $regions[$current] = [System.Collections.Generic.List[string]]::new() }
        }
        $regions[$current].Add($line)
    }
    return $regions
}

function Get-ProjectionDrift {
    # PF-IMP-1720: the gate holds both the rendered and the on-disk content at the moment it
    # fails, so it can report WHAT differs and WHICH task files produced the difference —
    # previously both were discarded and the caller re-derived them by hand (an mtime scan of
    # the tasks tree, or a copy-regenerate-diff cycle). That attribution gates the
    # regenerate-vs-defer decision the Task Execution Protocol prescribes under parallel
    # sessions. Compare-Object (not a positional walk) so an inserted or removed task shifts
    # the tail without reporting every later line as drifted.
    param([string]$Rendered, [string]$OnDisk)

    $renderedLines = ($Rendered -replace "`r`n", "`n").TrimEnd() -split "`n"
    $diskLines     = ($OnDisk   -replace "`r`n", "`n").TrimEnd() -split "`n"

    $renderedRegions = Split-ProjectionRegion -Lines $renderedLines
    $diskRegions     = Split-ProjectionRegion -Lines $diskLines

    # Compare per region, never per line: the same body line (a shared File Operations row,
    # say) occurs verbatim in several tasks' sections, so a whole-file line diff cannot say
    # WHICH occurrence moved and attributes the change to every task that carries that row.
    $keys = [System.Collections.Generic.HashSet[string]]::new([string[]]$renderedRegions.Keys)
    [void]$keys.UnionWith([string[]]$diskRegions.Keys)

    $changes = [System.Collections.Generic.List[pscustomobject]]::new()
    $sources = [System.Collections.Generic.List[string]]::new()
    $unattributed = $false

    foreach ($key in ($keys | Sort-Object)) {
        # Assign before the branch: an empty array RETURNED from an if/else unwraps to $null
        # on the way out, and Compare-Object refuses a null operand — which is exactly the
        # added/removed-task case (one side has no region at all).
        $r = @()
        $d = @()
        if ($renderedRegions.ContainsKey($key)) { $r = @($renderedRegions[$key]) }
        if ($diskRegions.ContainsKey($key))     { $d = @($diskRegions[$key]) }
        if (($r -join "`n") -eq ($d -join "`n")) { continue }

        if ($key -eq $script:DriftOutsideKey) { $unattributed = $true }
        elseif (-not $sources.Contains($key)) { $sources.Add($key) }

        foreach ($diff in (Compare-Object -ReferenceObject $d -DifferenceObject $r)) {
            $text = [string]$diff.InputObject
            if ([string]::IsNullOrWhiteSpace($text)) { continue }   # blank-line count drift carries no signal
            $changes.Add([pscustomobject]@{
                Marker = if ($diff.SideIndicator -eq '=>') { '[+]' } else { '[-]' }
                Text   = $text
            })
        }
    }

    return [pscustomobject]@{
        Changes      = $changes
        Sources      = ($sources | Sort-Object)
        Unattributed = $unattributed
    }
}

if ($Check) {
    $drift = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $targets.Keys) {
        if (-not (Compare-Normalized -A $rendered[$key] -B $raws[$key])) { $drift.Add($key) }
    }
    if (-not $drift.Count) {
        Write-Host "[PASS] Task-metadata projections in sync — $($tasks.Count) routed tasks." -ForegroundColor Green
        exit 0
    }
    Write-Host "[FAIL] Task-metadata projections out of date — regenerate with Build-TaskMetadata.ps1:" -ForegroundColor Red
    foreach ($key in $drift) {
        Write-Host "    $($targets[$key])" -ForegroundColor Red
        $detail = Get-ProjectionDrift -Rendered $rendered[$key] -OnDisk $raws[$key]

        $srcParts = @($detail.Sources)
        if ($detail.Unattributed) {
            $srcParts += 'content outside any per-task region (script inventory / automation summary / hand-written)'
        }
        Write-Host "      sources: $($srcParts -join ', ')" -ForegroundColor Yellow

        $shown = 0
        foreach ($c in $detail.Changes) {
            if ($shown -ge $DriftLineLimit) { break }
            $snippet = if ($c.Text.Length -gt 160) { $c.Text.Substring(0, 160) + '…' } else { $c.Text }
            Write-Host "      $($c.Marker) $snippet" -ForegroundColor Gray
            $shown++
        }
        if ($detail.Changes.Count -gt $shown) {
            Write-Host "      …and $($detail.Changes.Count - $shown) more differing lines (-DriftLineLimit to widen)" -ForegroundColor Gray
        }
    }
    Write-Host "    ([-] = on disk now, [+] = what regeneration would write)" -ForegroundColor Gray
    exit 1
}

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

if ($OutputDir) {
    if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
    foreach ($key in $targets.Keys) {
        $outPath = Join-Path $OutputDir ([System.IO.Path]::GetFileName($targets[$key]))
        if ($PSCmdlet.ShouldProcess($outPath, 'Write rendered projection (preview)')) {
            [System.IO.File]::WriteAllText($outPath, $rendered[$key], $utf8NoBom)
        }
    }
    Write-Host "[OK] Preview written to $OutputDir — $($tasks.Count) routed tasks rendered." -ForegroundColor Green
    exit 0
}

$written = 0
foreach ($key in $targets.Keys) {
    if (Compare-Normalized -A $rendered[$key] -B $raws[$key]) { continue }
    if ($PSCmdlet.ShouldProcess($targets[$key], 'Write generated task-metadata projection')) {
        [System.IO.File]::WriteAllText($targets[$key], $rendered[$key], $utf8NoBom)
        $written++
    }
}
Write-Host "[OK] $($tasks.Count) routed tasks rendered — $written of $($targets.Count) projection files updated." -ForegroundColor Green
exit 0
