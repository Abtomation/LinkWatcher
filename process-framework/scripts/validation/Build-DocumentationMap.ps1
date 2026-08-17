<#
.SYNOPSIS
    Generates the PF / PD / TE / SC documentation map (selected by -Tree) from each artifact's own .SYNOPSIS / docstring / doc-comment / frontmatter description; also checks for drift and reports artifacts missing a source description (PF-PRO-037 / PF-PRO-050 / PF-PRO-064 / PF-IMP-1955).

.DESCRIPTION
    Inverts the documentation-map dependency: instead of hand-maintaining
    PF-documentation-map.md, this script renders it from each artifact's own
    one-line description at its source:

      - PowerShell (.ps1)       -> comment-based help .SYNOPSIS (first line)
      - PowerShell (.psm1)      -> module-level .SYNOPSIS before the first function
                                   (a function's .SYNOPSIS is ignored, PF-IMP-988)
      - Python (.py)            -> module docstring (first line)
      - Markdown (.md)          -> 'description:' frontmatter field
      - JSON (.json)            -> metadata.description (or top-level description)
      - Pack-declared languages -> leading doc-comment block, driven by the doc_extraction
                                   spec in languages-config/{lang}/{lang}-config.json
                                   (e.g. Dart '///'; PF-IMP-1955 — a new language joins by
                                   declaring its markers, with no edit to this script)

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

.PARAMETER Tree
    Which documentation map to generate (PF-PRO-050): PF (default) = the process
    framework map; PD = the product map under the sibling doc/ tree; TE = the test
    map under the sibling test/ tree; SC = the Source Code Documentation Map under
    the configured source tree (PF-PRO-064 O-1, widened by PF-IMP-1955). Default PF
    reproduces the original behavior byte-for-byte. The trees share the same description
    extractors; they differ only in the indexed subtrees/extensions, the exempt map name,
    and the rendered title/heading/regenerate-hint.

    SC differs from the other three in three ways, each forced by what a source tree is:
    its root is CONFIGURED (paths.source_code) rather than a fixed sibling, its indexed
    subtrees are discovered rather than enumerated, and it is OPTIONAL — an unconfigured,
    absent or artifact-free source tree is a normal state that exits 0 without writing a
    map, not an error. It indexes ALL source the extractors cover (owner decision
    PF-IMP-1955 D1): markdown/template frontmatter, PowerShell .SYNOPSIS, Python
    docstrings, plus every extension a language pack declares via doc_extraction
    (e.g. Dart '///'). Source without a doc comment renders the missing-description
    marker — that marker is the warn surface (D2); nothing blocks. Test code is not
    indexed here — the TE map owns it (D4, PF-PRO-050). Per-project opt-outs come from
    project-config.json's documentation_map block (src_exclude_dirs, src_extra_extensions);
    .json is deliberately NOT indexed by default (data without a description convention) —
    a project can opt it in via src_extra_extensions.

.PARAMETER FrameworkRoot
    Root of the framework (process-framework) tree. For PD/TE the indexed tree is
    resolved as a sibling of this (../doc, ../test); for SC it is read from
    ../doc/project-config.json's paths.source_code. Auto-detected from this script's
    own location if omitted (it lives at <FrameworkRoot>/scripts/validation/), so the
    default is correct in both the appdev (blueprint/process-framework) and
    rolled-out-project (process-framework) layouts.

.PARAMETER MapPath
    Path to the documentation map. Defaults to <FrameworkRoot>/PF-documentation-map.md.

.PARAMETER Check
    Regenerate to memory and compare against the on-disk map. Exit 1 on drift. The FAIL output
    lists the differing lines (PF-IMP-1720); each map line carries its own artifact link, so
    the listing names the source artifacts directly — enough to attribute drift to your own
    edit versus a parallel session's without re-deriving it by hand.

.PARAMETER DriftLineLimit
    Maximum differing lines shown in -Check output (default 12). Raise it when the map drifted
    broadly and the truncated listing hides the relevant line.

.PARAMETER ReportMissing
    Print artifacts with no extractable source description. Exit 1 if any exist.

.NOTES
    Exit codes:
        0 = success (generated / in sync / no missing descriptions), or an optional tree
            (-Tree SC) that is unconfigured, absent, or holds no indexable artifact
        1 = drift detected (-Check) or missing descriptions found (-ReportMissing)
        2 = script error (missing paths)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('PF', 'PD', 'TE', 'SC')]
    [string]$Tree = 'PF',
    [string]$FrameworkRoot,
    [string]$MapPath,
    [switch]$Check,
    [switch]$ReportMissing,
    [ValidateRange(1, 1000)]
    [int]$DriftLineLimit = 12
)

$ErrorActionPreference = 'Stop'

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
# Per-tree configuration (PF-PRO-050)
# ---------------------------------------------------------------------------
# One generator, four trees. -Tree PF (default) reproduces the original PF
# behavior byte-for-byte; PD/TE add the product (doc/) and test (test/) trees,
# which sit as siblings of process-framework/ in both the appdev (blueprint/) and
# rolled-out-project layouts. Each tree differs only in: its root location, its
# own map file (exempt from indexing), the indexed subtrees/extensions, and the
# rendered title/heading/regenerate-hint. The description extractors are shared.
#
# SC (PF-PRO-064 O-1, widened to the full source tree by PF-IMP-1955) adds the source
# tree. It carries three extra config keys because a source tree is not a fixed sibling
# like doc/ and test/:
#   RootConfigKey  — resolve the root from ../doc/project-config.json instead of a
#                    literal path. Measured across the registered projects, the value
#                    is 'src/linkwatcher', 'src' and 'lib' — no literal is correct.
#   DiscoverSubdirs— index every directory found under the root, rather than a curated
#                    list. A source tree's layout is per-feature and unknowable here.
#   OptionalTree   — unconfigured / absent / artifact-free is a NORMAL state (exit 0,
#                    no map written). The blueprint template ships paths.source_code
#                    empty and a registered project may declare a directory it has not
#                    created yet, so the other trees' "missing root is fatal" rule would
#                    turn a fresh workspace's pre-commit gate red for no defect.
$treeConfigs = @{
    PF = @{
        MapName     = 'PF-documentation-map.md'
        RootSubdir  = '.'   # tree root == framework root
        Subdirs     = @('tasks', 'templates', 'guides', 'visualization', 'infrastructure', 'scripts', 'tools')
        Extensions  = @('.md', '.ps1', '.psm1', '.py', '.json', '.template')
        HeaderTitle = 'Process Framework Documentation Map'
        RootHeading = 'process-framework/ (root)'
        IntroNoun   = 'every framework artifact'
        BannerCmd   = 'process-framework/scripts/validation/Build-DocumentationMap.ps1'
        RegenCmd    = 'scripts/validation/Build-DocumentationMap.ps1'
        CheckCmd    = 'Build-DocumentationMap.ps1 -Check'
    }
    PD = @{
        MapName     = 'PD-documentation-map.md'
        RootSubdir  = '..\doc'
        Subdirs     = @('ci-cd', 'documentation-tiers', 'founding', 'functional-design', 'refactoring', 'state-tracking', 'technical', 'user', 'validation')
        Extensions  = @('.md', '.json', '.template')
        # doc/founding/inputs/ holds RAW human founding material (briefs, PDFs, transcripts) that the
        # framework deliberately does not own: no IDs, no frontmatter, no descriptions (PF-PRO-058).
        # Indexing it would flag every input as "missing a description" forever. The founding/ docs
        # that ARE artifacts — product-concept.md, feature-landscape.md — sit above it and stay indexed.
        ExcludeDirNames = @('inputs')
        HeaderTitle = 'Product Documentation Map'
        RootHeading = 'doc/ (root)'
        IntroNoun   = 'every product documentation artifact'
        BannerCmd   = 'process-framework/scripts/validation/Build-DocumentationMap.ps1 -Tree PD'
        RegenCmd    = 'scripts/validation/Build-DocumentationMap.ps1 -Tree PD'
        CheckCmd    = 'Build-DocumentationMap.ps1 -Tree PD -Check'
    }
    TE = @{
        MapName     = 'TE-documentation-map.md'
        RootSubdir  = '..\test'
        # Documentation only — test CODE under automated/ is intentionally NOT indexed (PF-PRO-050 design decision).
        Subdirs     = @('specifications', 'audits', 'e2e-acceptance-testing', 'state-tracking')
        Extensions  = @('.md', '.json')
        # E2E fixture-data subtrees (per case: sandboxed project copies, expected snapshots;
        # per workflow: runtime workspace, captured results) are test data, not docs — pruned
        # from indexing (PF-IMP-1332). The test-case.md / master-test-*.md docs that sit ABOVE
        # these dirs (under <workflow>/templates/) are retained. Without this, a populated
        # project's e2e tree swamps the map (PRJ-001: 1111 fixture files vs 42 real E2E docs).
        ExcludeDirNames = @('expected', 'project', 'workspace', 'results')
        HeaderTitle = 'Test Documentation Map'
        RootHeading = 'test/ (root)'
        IntroNoun   = 'every test documentation artifact'
        BannerCmd   = 'process-framework/scripts/validation/Build-DocumentationMap.ps1 -Tree TE'
        RegenCmd    = 'scripts/validation/Build-DocumentationMap.ps1 -Tree TE'
        CheckCmd    = 'Build-DocumentationMap.ps1 -Tree TE -Check'
    }
    SC = @{
        MapName       = 'SC-documentation-map.md'
        RootConfigKey = 'source_code'   # ../doc/project-config.json -> paths.source_code
        DiscoverSubdirs = $true
        OptionalTree  = $true
        Subdirs       = @()             # filled by discovery once the root resolves
        # ALL source the extractors cover (PF-IMP-1955 D1): docs plus code. This base set is
        # widened at runtime by language-pack doc_extraction declarations (e.g. .dart) and by
        # the project's documentation_map.src_extra_extensions. '.json' is deliberately NOT
        # in the base set — source-tree JSON is data without a description convention, so
        # indexing it would flag every config file forever; opt in via src_extra_extensions.
        # Source lacking a doc comment renders the missing-description marker — the warn
        # surface (D2). Promotion criterion (D2, recorded at PF-IMP-1955): '-Tree SC -Check'
        # joins the project pre-commit gate set at the PF-PRO-064 Phase 4 checkpoint, once
        # every registered project's SC map generates with zero missing descriptions (i.e.
        # the PRJ-002 docstring-backfill migration has drained).
        Extensions    = @('.md', '.template', '.ps1', '.psm1', '.py')
        # Dependency and build caches routinely contain thousands of vendored files that are
        # not this project's artifacts. Discovery walks whatever is on disk, so these are
        # pruned by name rather than by an authored subtree list. This framework-wide
        # invariant set is extended per project by documentation_map.src_exclude_dirs.
        ExcludeDirNames = @('__pycache__', 'node_modules', '.venv', 'venv', '.dart_tool', 'build', 'dist', '.mypy_cache', '.pytest_cache')
        HeaderTitle = 'Source Code Documentation Map'
        RootHeading = 'source root'
        IntroNoun   = 'every source artifact'
        DescSourceNote = 'description — `description:` frontmatter for markdown, `.SYNOPSIS` for PowerShell, the module docstring for Python, and the doc-comment its language pack declares (`languages-config/`) for other source files.'
        BannerCmd   = 'process-framework/scripts/validation/Build-DocumentationMap.ps1 -Tree SC'
        RegenCmd    = 'scripts/validation/Build-DocumentationMap.ps1 -Tree SC'
        CheckCmd    = 'Build-DocumentationMap.ps1 -Tree SC -Check'
    }
}
$cfg = $treeConfigs[$Tree]
$indexableExtensions = $cfg.Extensions
# 'archive' and 'old' subtrees are excluded from EVERY tree (PF-IMP-1376): they hold superseded
# docs (completed-IMP archives, retired FDDs/TDDs/proposals, prior-version state) the curated map
# never enumerated, which swamp a populated project's PD/TE map with dead history. A tree's own
# ExcludeDirNames (e.g. TE's E2E fixture dirs, PF-IMP-1332) extends this framework-wide set.
$excludeDirNames = @('archive', 'old') + $(if ($cfg.ContainsKey('ExcludeDirNames')) { $cfg.ExcludeDirNames } else { @() })
# Each tree exempts its own generated map (plus the framework-wide non-artifacts).
# artifact-locks.json: the gitignored Artifact Checkout Locking store (PF-PRO-061) under
# doc/state-tracking/ — machine state, not a documentation artifact.
$exemptNames = @('README.md', $cfg.MapName, '.gitkeep', '.framework-version', '.framework-version-previous', 'artifact-locks.json')
# Subtrees indexed (recursively), in render order. Root-level files are indexed separately.
$indexedSubdirs = $cfg.Subdirs
$missingMarker = '⚠️ _(no description — add to .SYNOPSIS/frontmatter)_'

# ---------------------------------------------------------------------------
# Description extractors (one-liner from each artifact's own source)
# ---------------------------------------------------------------------------
# Get-SynopsisDescription / Get-PyDocstringDescription are shared with
# Build-TaskMetadata.ps1 via DescriptionExtraction.psm1 (imported above, PF-IMP-1311).

function Get-FrontmatterDescription {
    param([string]$Path)
    # @() forces an array: a single-line file makes Get-Content return a scalar string, so the
    # positional $lines[0] would index a [char] and $lines[0].Trim() throws (the documented
    # single-match scalar-unwrap footgun — PF-IMP-1331).
    $lines = @(Get-Content -Path $Path -ErrorAction SilentlyContinue)
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
    $ext = $File.Extension.ToLower()
    switch ($ext) {
        '.ps1'      { return Get-SynopsisDescription -Path $File.FullName }
        '.psm1'     { return Get-SynopsisDescription -Path $File.FullName -ModuleLevel }
        '.py'       { return Get-PyDocstringDescription -Path $File.FullName }
        '.md'       { return Get-FrontmatterDescription -Path $File.FullName }
        '.template' { return Get-FrontmatterDescription -Path $File.FullName }
        '.json'     { return Get-JsonDescription -Path $File.FullName }
        default     {
            # Pack-declared extensions (PF-IMP-1955): a language pack's doc_extraction spec
            # drives the generic marker engine — populated by the loader below, before any
            # file is collected.
            if ($script:PackExtractors -and $script:PackExtractors.ContainsKey($ext)) {
                return Get-MarkerDocDescription -Path $File.FullName -Spec $script:PackExtractors[$ext]
            }
            return $null
        }
    }
}

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
if (-not $FrameworkRoot) {
    # This script lives at <FrameworkRoot>/scripts/validation/ in BOTH the appdev
    # (blueprint/process-framework) and rolled-out-project (process-framework) layouts,
    # so derive the framework root from the script's own location — not a layout-specific
    # suffix off a repo root. Matches sibling Build-TaskMetadata.ps1 (PF-IMP-1206).
    $FrameworkRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}
if (-not (Test-Path $FrameworkRoot)) {
    Write-Host "[ERROR] FrameworkRoot not found: $FrameworkRoot" -ForegroundColor Red
    exit 2
}
$frameworkRootFull = (Resolve-Path $FrameworkRoot).Path

# The tree being indexed: PF == the framework root; PD/TE == the sibling doc/ or test/
# tree; SC == the source tree named by ../doc/project-config.json's paths.source_code.
$projectRootFull = Split-Path -Parent $frameworkRootFull
$docMapConfig = $null
if ($cfg.ContainsKey('RootConfigKey')) {
    $configPath = Join-Path $projectRootFull 'doc\project-config.json'
    $configuredRoot = $null
    if (Test-Path $configPath) {
        try {
            $projectConfig = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if ($projectConfig.PSObject.Properties.Name -contains 'paths') {
                $configuredRoot = [string]$projectConfig.paths.($cfg.RootConfigKey)
            }
            # Per-project opt-outs (PF-IMP-1955 D1): optional documentation_map block —
            # src_exclude_dirs extends the in-script invariant prune set; src_extra_extensions
            # extends the indexable set. Absent block == in-script defaults, so no existing
            # project needs a config change for the SC tree to work.
            if ($projectConfig.PSObject.Properties.Name -contains 'documentation_map') {
                $docMapConfig = $projectConfig.documentation_map
            }
        } catch {
            Write-Host "[ERROR] Could not read paths.$($cfg.RootConfigKey) from ${configPath}: $($_.Exception.Message)" -ForegroundColor Red
            exit 2
        }
    }
    if ([string]::IsNullOrWhiteSpace($configuredRoot)) {
        # Not a defect: the blueprint template ships this key empty, and a workspace with no
        # source tree declared has no instruction artifacts to index.
        Write-Host "[SKIP] $Tree tree not configured — paths.$($cfg.RootConfigKey) is empty or absent. Nothing to index." -ForegroundColor Gray
        exit 0
    }
    $treeRoot = Join-Path $projectRootFull $configuredRoot
} elseif ($cfg.RootSubdir -eq '.') {
    $treeRoot = $frameworkRootFull
} else {
    $treeRoot = Join-Path $frameworkRootFull $cfg.RootSubdir
}
if (-not (Test-Path $treeRoot)) {
    if ($cfg.ContainsKey('OptionalTree') -and $cfg.OptionalTree) {
        # A declared-but-not-yet-created source directory is a normal state in a workspace
        # that has not started shipping source (verified live: one registered project declares
        # 'lib' and has no lib/). Exiting 2 here would redden its pre-commit gate for no defect.
        Write-Host "[SKIP] $Tree tree root does not exist: $treeRoot. Nothing to index." -ForegroundColor Gray
        exit 0
    }
    Write-Host "[ERROR] $Tree tree root not found: $treeRoot" -ForegroundColor Red
    exit 2
}
$treeRootFull = (Resolve-Path $treeRoot).Path

# ---------------------------------------------------------------------------
# Language-pack doc-extraction specs (PF-IMP-1955)
# ---------------------------------------------------------------------------
# Each language pack may declare how its source files carry a one-line doc comment
# (doc_extraction: engine + markers). The union across all shipped packs is taken
# language-blind — a .dart file in a Python project's tree still extracts. A malformed
# pack, or one declaring an engine this script version does not know, warns and is
# skipped rather than failing map generation. Migrating the bespoke Python/PowerShell
# extractors onto pack declarations is sequenced on the Dart path proving out
# (follow-up filed from PF-IMP-1955).
$script:PackExtractors = @{}
$langConfigDir = Join-Path $frameworkRootFull 'languages-config'
if (Test-Path $langConfigDir) {
    $packFiles = Get-ChildItem -Path $langConfigDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Get-ChildItem -Path $_.FullName -Filter '*-config.json' -File -ErrorAction SilentlyContinue
    }
    foreach ($packFile in $packFiles) {
        try {
            $pack = Get-Content -Path $packFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        } catch {
            Write-Host "[WARN] Skipping malformed language config $($packFile.FullName): $($_.Exception.Message)" -ForegroundColor Yellow
            continue
        }
        if ($pack.PSObject.Properties.Name -notcontains 'doc_extraction') { continue }
        $spec = $pack.doc_extraction
        if ([string]$spec.engine -ne 'line-marker') {
            Write-Host "[WARN] $($packFile.Name): unknown doc_extraction engine '$($spec.engine)' — pack skipped (engines this script knows: line-marker)." -ForegroundColor Yellow
            continue
        }
        foreach ($packExt in @($spec.extensions)) {
            $e = ([string]$packExt).ToLower()
            if ($e -and -not $script:PackExtractors.ContainsKey($e)) { $script:PackExtractors[$e] = $spec }
        }
    }
}

# SC-only runtime widening: pack-declared extensions and the project's documentation_map
# opt-outs land here, after the invariants and before discovery/collection use either set.
if ($Tree -eq 'SC') {
    if ($docMapConfig) {
        $excludeDirNames = @($excludeDirNames) + @($docMapConfig.src_exclude_dirs | Where-Object { $_ })
        $indexableExtensions = @($indexableExtensions) + @($docMapConfig.src_extra_extensions |
            Where-Object { $_ } | ForEach-Object { ([string]$_).ToLower() })
    }
    $indexableExtensions = @($indexableExtensions + $script:PackExtractors.Keys | Select-Object -Unique)
}

# A source tree's internal layout is per-feature and cannot be enumerated here, so SC
# discovers its indexed subtrees instead of carrying an authored list. Pruned directories
# are dropped at the top level too, not only mid-walk.
if ($cfg.ContainsKey('DiscoverSubdirs') -and $cfg.DiscoverSubdirs) {
    $indexedSubdirs = @(
        Get-ChildItem -Path $treeRootFull -Directory -ErrorAction SilentlyContinue |
            Where-Object { $excludeDirNames -notcontains $_.Name } |
            Select-Object -ExpandProperty Name
    )
}

if (-not $MapPath) {
    $MapPath = Join-Path $treeRootFull $cfg.MapName
}

# ---------------------------------------------------------------------------
# Collect indexable files
# ---------------------------------------------------------------------------
function Test-Indexable {
    param([System.IO.FileInfo]$File)
    if ($exemptNames -contains $File.Name) { return $false }
    if ($indexableExtensions -notcontains $File.Extension.ToLower()) { return $false }
    return $true
}

# Prune files that live under a fixture-data subtree (per-tree $excludeDirNames). Matches any
# directory segment of the file's path relative to the tree root, so a fixture dir at any depth
# (e.g. <workflow>/templates/<case>/project/ or <workflow>/workspace/) is excluded while docs
# sitting above it are kept. Root-level files have an empty relative dir and are never excluded.
function Test-ExcludedPath {
    param([System.IO.FileInfo]$File)
    if ($excludeDirNames.Count -eq 0) { return $false }
    $relDir = $File.DirectoryName.Substring($treeRootFull.Length).Trim('\', '/')
    if ([string]::IsNullOrEmpty($relDir)) { return $false }
    foreach ($seg in ($relDir -split '[\\/]')) {
        if ($excludeDirNames -contains $seg) { return $true }
    }
    return $false
}

$entries = [System.Collections.Generic.List[object]]::new()

function Add-Entry {
    param([System.IO.FileInfo]$File)
    $rel = $File.FullName.Substring($treeRootFull.Length + 1) -replace '\\', '/'
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
Get-ChildItem -Path $treeRootFull -File -ErrorAction SilentlyContinue | ForEach-Object {
    if (Test-Indexable -File $_) { Add-Entry -File $_ }
}
# Subtrees
foreach ($subdir in $indexedSubdirs) {
    $dir = Join-Path $treeRootFull $subdir
    if (-not (Test-Path $dir)) { continue }
    Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        if ((Test-Indexable -File $_) -and -not (Test-ExcludedPath -File $_)) { Add-Entry -File $_ }
    }
}

# An optional tree that holds no indexable artifact writes no map at all, rather than a
# map with a header and no entries: a workspace whose source tree is pure code has nothing
# to index, and a stub map in every such project is noise that also has to stay in sync.
# The map file therefore appears only where instruction artifacts actually exist. A map left
# behind after its last artifact went away IS drift, and is reported as such.
if ($entries.Count -eq 0 -and $cfg.ContainsKey('OptionalTree') -and $cfg.OptionalTree) {
    $staleMapExists = Test-Path $MapPath
    if ($ReportMissing) {
        Write-Host "[PASS] No $Tree artifacts indexed — nothing can lack a description." -ForegroundColor Green
        exit 0
    }
    if ($Check) {
        if (-not $staleMapExists) {
            Write-Host "[PASS] $Tree map in sync — 0 artifacts indexed, no map expected." -ForegroundColor Green
            exit 0
        }
        Write-Host "[FAIL] $MapPath exists but the $Tree tree holds no indexable artifacts — delete the stale map." -ForegroundColor Red
        exit 1
    }
    if ($staleMapExists) {
        Write-Host "[WARN] $MapPath is stale — the $Tree tree holds no indexable artifacts. Delete it." -ForegroundColor Yellow
    } else {
        Write-Host "[OK] No $Tree artifacts to index — no map written." -ForegroundColor Green
    }
    exit 0
}

# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------
function Build-MapContent {
    $sb = [System.Collections.Generic.List[string]]::new()
    $sb.Add('<!-- AUTO-GENERATED FILE — DO NOT EDIT MANUALLY -->')
    $sb.Add('<!-- Regenerate with: ' + $cfg.BannerCmd + ' -->')
    $sb.Add('')
    $sb.Add('# ' + $cfg.HeaderTitle)
    $sb.Add('')
    $sb.Add('This index of ' + $cfg.IntroNoun + ' is **generated** from each artifact''s own one-line')
    # A tree that indexes only some of the extractors must not tell its readers to use the others.
    # PF/PD/TE keep the original sentence byte-for-byte via the fallback.
    $sb.Add($(if ($cfg.ContainsKey('DescSourceNote')) { $cfg.DescSourceNote }
              else { 'description — `.SYNOPSIS` for scripts, the `description:` frontmatter field for markdown.' }))
    $sb.Add('Do not edit this file by hand: run `' + $cfg.RegenCmd + '` to regenerate it,')
    $sb.Add('and `' + $cfg.CheckCmd + '` to verify it is in sync. Entries marked')
    $sb.Add('"' + $missingMarker + '" need a description added at the artifact''s source.')
    $sb.Add('')

    # Group by directory; sort directories then files.
    $byDir = $entries | Group-Object Dir | Sort-Object {
        if ($_.Name -eq '.') { '' } else { $_.Name }   # root first
    }
    foreach ($grp in $byDir) {
        $heading = if ($grp.Name -eq '.') { $cfg.RootHeading } else { $grp.Name }
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
    Write-Host "  Add a .SYNOPSIS (scripts), a module docstring / doc-comment (source files), or 'description:' frontmatter (markdown) to each." -ForegroundColor Gray
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

    # PF-IMP-1720: report WHAT differs, not just that something does. Each map line is an
    # artifact entry carrying its own link, so the listing names the drifting sources directly
    # — the attribution that gates the regenerate-vs-defer decision under parallel sessions.
    # Compare-Object (not a positional walk) so an added or removed artifact shifts the tail
    # without reporting every later line as drifted.
    $diffs = @(Compare-Object -ReferenceObject ($normDisk -split "`n") -DifferenceObject ($normGen -split "`n") |
        Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.InputObject) })
    $shown = 0
    foreach ($d in $diffs) {
        if ($shown -ge $DriftLineLimit) { break }
        $marker = if ($d.SideIndicator -eq '=>') { '[+]' } else { '[-]' }
        $text = [string]$d.InputObject
        $snippet = if ($text.Length -gt 160) { $text.Substring(0, 160) + '…' } else { $text }
        Write-Host "    $marker $snippet" -ForegroundColor Gray
        $shown++
    }
    if ($diffs.Count -gt $shown) {
        Write-Host "    …and $($diffs.Count - $shown) more differing lines (-DriftLineLimit to widen)" -ForegroundColor Gray
    }
    Write-Host "    ([-] = on disk now, [+] = what regeneration would write)" -ForegroundColor Gray

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
