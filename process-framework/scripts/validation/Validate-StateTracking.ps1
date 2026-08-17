#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Master state validation script — validates that state tracking entries match actual files on disk.
.DESCRIPTION
    Checks consistency across 17 validation surfaces:
    1. (retired — PF-IMP-1299) Feature Tracking links — broken-link detection delegated to LinkWatcher --validate (run_linkwatcher_validate.ps1), wired into the task finalization gates
    2. Feature implementation state files — STRUCTURAL checks only (PF-IMP-1299): the Documentation/Code/Dependencies inventory sections are present and non-empty (matched by title, so the full and Tier 1 templates both work), and the features dir is present/non-empty. Broken-link detection within those sections is delegated to LinkWatcher --validate.
    3. (retired — PF-IMP-1299) Test Tracking links — broken-link detection delegated to LinkWatcher --validate
    4. Cross-reference consistency — feature IDs in test-registry.yaml vs feature-tracking.md
    5. ID counter health — nextAvailable counters vs actual max IDs
    6. Feature Dependencies — regenerate feature-dependencies.md if stale
    7. Dimension Consistency — dimension profile presence and valid abbreviations (Tier 1 lightweight files skipped — they have no Dimension Profile by design)
    8. Workflow Tracking — workflow-feature mapping consistency and status accuracy
    9. (retired — PF-IMP-1210) Task Registry — superseded by Build-TaskMetadata.ps1 -Check (PF-PRO-042)
    10. Metadata Schema — YAML frontmatter conformance against domain-config.json schemas
    11. (retired) Context Map Orphans — removed with the context-map ecosystem. The number is
        left vacant rather than renumbered so later surfaces keep their long-standing IDs, which
        are cited across tests, IMP history, and the inline `# Surface NN` section headers below.
        Consequence: a `# Surface NN` header is that stable historical ID and intentionally does
        NOT equal the surface's positional index in the $CanonicalSurfaces name list (which has no
        gap). -Surface has no ValidateSet — unknown names are caught by a runtime "no surfaces
        matched" guard, not at parameter binding.
    12. (retired — PF-IMP-1210) AI Tasks Consistency — superseded by Build-TaskMetadata.ps1 -Check (PF-PRO-042)
    13. Master State Consistency — phase checkboxes, progress counters, and doc summary vs Feature Inventory
    14. Source Layout — compare source-code-layout.md directory tree against actual source directories
    15. Test Status Aggregation — cross-check feature-tracking Test Status against aggregated test-tracking statuses (PF-IMP-573)
    16. Audit Mirror Invariant — every test dir has a corresponding audit dir under the Phase 3a path-transform rule (PF-IMP-871 Phase 4a)
    17. Category Alignment — feature-tracking.md categories/subgroups vs `test/automated/unit/<N>-<slug>/` dirs (PF-IMP-871 Phase 4a)
    18. Workflow Alignment — user-workflow-tracking.md WF-NNN rows vs `test/e2e-acceptance-testing/<slug>/templates/` dirs (PF-IMP-871 Phase 4a)
    19. Variant Pair Consistency — per-file frontmatter variant_group/variant_siblings symmetry and sibling existence (PF-IMP-837)
    20. Feature Request Tracking — intra-tracker markdown link existence in feature-request-tracking.md (PF-IMP-1212; broken links → WARNING, warn-first)
    21. Architecture Tracking — intra-tracker markdown link existence in architecture-tracking.md (PF-IMP-1212)
    22. Technical Debt Tracking — intra-tracker markdown link existence in technical-debt-tracking.md (PF-IMP-1212)
    23. Bug Tracking — intra-tracker markdown link existence in bug-tracking.md (PF-IMP-1212)
    24. Process Improvement Tracking (central) — reachability + table-structure check of the central process-improvement-tracking.md (PF-IMP-1212; links not validated — they are appdev-relative)
    25. Blueprint Central References — blueprint/**/*.md markdown links into process-framework-central/ checked against the real central tree (PF-IMP-1589; appdev layout only, N/A in rolled-out projects; broken links → WARNING, warn-first). These links are rolled-layout-relative navigational hints (PF-IMP-1097) that resolve nowhere on disk, so LinkWatcher can neither update nor validate them — this surface is their only detector.
    26. Technical Exploration Tracking — intra-tracker markdown link existence in technical-exploration-tracking.md (PF-IMP-1584; PF-EVR-029 F-4), closing the tracker's gap vs its sibling intake queues (Surfaces 20–23) so a resolved exploration row with a rotted Findings Doc link is detected post-resolve
    27. Task ID References — PF-TSK-NNN ids cited in authored framework prose (tasks/, guides/, templates/, .claude/skills/) checked against the task files' own ids (PF-IMP-1677; appdev layout only; warn-first). Two checks: phantom ids (cited but assigned to no task) and name-vs-id mismatches ("Bug Triage (PF-TSK-024)" where the named task declares a different id) — the second catches wrong-but-live ids that a membership check passes

    Created as IMP-028 from Tools Review 2026-02-21.
.PARAMETER ProjectRoot
    Path to the project root directory. Defaults to auto-detection from script location.
.PARAMETER Surface
    Which validation surfaces to run. Accepts one or more of:
    "StateFiles", "CrossRef", "IdCounters", "FeatureDeps", "DimensionConsistency", "WorkflowTracking", "MetadataSchema", "MasterStateConsistency", "SourceLayout", "TestStatusAggregation", "AuditMirror", "CategoryAlignment", "WorkflowAlignment", "VariantPairConsistency", "FeatureRequestTracking", "ArchitectureTracking", "TechDebtTracking", "BugTracking", "ProcessImprovementTracking", "BlueprintCentralRefs", "ExplorationTracking", "TaskIdRefs", "All" (FeatureTracking / TestTracking retired — PF-IMP-1299, delegated to LinkWatcher --validate)
    Default: "All"
.PARAMETER Detailed
    Show every checked link, not just failures. Also reveals schema-detail-only warnings
    (e.g., "Unknown field" findings in Surface 10) that are suppressed by default because
    they reflect schema-template drift rather than actionable issues.
    See process-framework/guides/support/schema-audit-procedure-guide.md for the
    reconciliation workflow that consumes -Detailed Surface 10 output.
.PARAMETER FixCounters
    Auto-fix nextAvailable counters in ID registries (Surface 5 only).
.PARAMETER SaveBaseline
    Save this run's ERROR findings as a baseline JSON for later delta comparison.
    The file is auto-named (vst-baseline-<project>-<timestamp>-<PID>.json — unique per
    session, so parallel sessions never collide) and written to a WORKSPACE-SCOPED
    directory, $env:TEMP\vst-baselines-<project>-<root-hash>\ (PF-IMP-1984); the path is
    printed at the end of the run — read it from there rather than composing it. Save a
    baseline BEFORE starting a scoped change, then re-run with -Baseline <path> afterward
    to prove the change introduced no NEW errors. Each save prunes baselines older than 3
    days (the validator owns cleanup — no manual deletion needed); the prune is confined
    to this workspace's own directory. Exit-code semantics of the save run are
    unchanged (a debt-carrying project still exits 1; callers saving a baseline
    typically ignore it).
.PARAMETER Baseline
    Path to a baseline JSON previously written by -SaveBaseline. After the run, compares
    current errors against the baseline and reports NEW / pre-existing / resolved.
    Exit code becomes delta-based: 1 only if NEW errors exist — pre-existing debt no
    longer fails the run. Warns if the baseline was saved for a different project root
    or surface selection. The baseline file is kept (fix-and-recompare is allowed);
    the 3-day prune handles cleanup.
.PARAMETER Json
    Write a machine-readable JSON summary of the run (counts, per-surface coverage,
    error fingerprints, baseline delta, and the exit code) so programmatic / CI consumers
    do not have to scrape the colored host text. Without -JsonPath the file is auto-named
    (vst-summary-<project>-<timestamp>-<PID>.json) under the workspace-scoped
    $env:TEMP\vst-summaries-<project>-<root-hash>\ (PF-IMP-1984) and its path is printed at
    the end. The human-facing host output and exit codes are unchanged.
.PARAMETER JsonPath
    Explicit destination for the -Json summary (implies -Json). Use this in CI to pin the
    summary to a known location, e.g. -JsonPath validation-summary.json.
.EXAMPLE
    ../Validate-StateTracking.ps1
.EXAMPLE
    ../Validate-StateTracking.ps1 -Surface StateFiles,IdCounters
.EXAMPLE
    ../Validate-StateTracking.ps1 -Detailed
.EXAMPLE
    ../Validate-StateTracking.ps1 -Surface IdCounters -FixCounters
.EXAMPLE
    ../Validate-StateTracking.ps1 -JsonPath validation-summary.json
    # machine-readable summary for a CI gate; exit code still reflects pass/fail
.EXAMPLE
    ../Validate-StateTracking.ps1 -SaveBaseline
    # ... make the scoped change, then prove no NEW errors, passing the path the save run
    # PRINTED (the directory is workspace-scoped, so do not compose it by hand):
    ../Validate-StateTracking.ps1 -Baseline $env:TEMP\vst-baselines-<project>-<root-hash>\vst-baseline-<project>-<timestamp>-<PID>.json
#>

param(
    [string]$ProjectRoot = "",
    [string[]]$Surface = @("All"),
    [switch]$Detailed,
    [switch]$FixCounters,
    [switch]$SaveBaseline,
    [string]$Baseline = "",
    [switch]$Json,
    [string]$JsonPath = ""
)

# --- Locate + import Common-ScriptHelpers umbrella ---
# Imported unconditionally because surfaces 16/17/18 (PF-IMP-871 Phase 4a) consume
# Naming module functions (New-FeatureDirSlug, ConvertTo-FeatureSlug). Prior to
# Phase 4a, the import was conditional on $ProjectRoot being blank — callers passing
# -ProjectRoot explicitly silently skipped module load and got empty results from
# the new surfaces (no error, just zero expected entries → spurious orphan warnings).
$helperDir = $PSScriptRoot
while ($helperDir -and !(Test-Path (Join-Path $helperDir "Common-ScriptHelpers.psm1"))) {
    $helperDir = Split-Path -Parent $helperDir
}
if ($helperDir) {
    Import-Module (Join-Path $helperDir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
}

# --- Resolve project root (auto-detect when not supplied) ---
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Get-ProjectRoot
}

# Normalize to an absolute path before any path math runs (PF-IMP-1956). Several surfaces derive
# a repo-relative path with $file.FullName.Substring($root.Length) — FullName is always absolute,
# so a relative -ProjectRoot ("blueprint") makes the offsets disagree by the length of the absolute
# prefix: every derived path is silently sliced mid-token ("...\FrameworkBuilder\..." →
# "rameworkBuilder\...") and surfaces report fabricated findings instead of failing loudly.
# Resolved against $PWD rather than via Resolve-Path, deliberately: the root need not exist —
# callers pass a non-existent root to exercise the empty-project context — and .NET's
# CurrentDirectory does not track PowerShell's location, so the base is passed explicitly.
# DirectoryInfo drops any trailing separator (keeping it at a drive root) so the Substring
# offsets stay exact. Get-ProjectRoot already returns absolute, so auto-detect is a no-op.
$ProjectRoot = ([System.IO.DirectoryInfo]::new(
    [System.IO.Path]::GetFullPath($ProjectRoot, $PWD.Path))).FullName

# --- Globals ---
$totalChecks = 0
$errorCount = 0
$warningCount = 0
$passCount = 0
$detailOnlyHiddenCount = 0  # Warnings counted but display-suppressed unless -Detailed
$errorFingerprints = [System.Collections.Generic.List[string]]::new()  # "Surface|Context|Message" per ERROR, for -SaveBaseline / -Baseline
$surfaceRecorded = [ordered]@{}  # PF-IMP-1209: Add-CheckResult call count per Surface, for an honest per-surface coverage report (X-1) — distinguishes "recorded nothing" from a clean pass
$surfaceExamined = [ordered]@{}  # PF-IMP-1209 remainder: instances each surface actually examined — the faithful denominator (distinct from $surfaceRecorded's Add-CheckResult call count)
$projectId = ""                  # captured from project-config.json below; identity/provenance only — absent-target severity is driven by $script:workspaceRole (declared role, PF-PRO-067), not by this id
# PF-IMP-1214: summary fields read by Complete-Run at every terminal exit. Initialized here
# so the JSON summary is well-formed even on early exits (e.g. the no-surface-match guard)
# before the tail computes the real values.
$selectedSurfaces = @()
$silentSurfaces   = @()
$newErrors        = $null
$jsonBaseline     = $null

# Normalize -Surface: split any comma-joined elements into separate items, trim, drop empties.
# Handles `pwsh.exe -File -Surface a,b,c` invocation where PowerShell passes the comma-joined
# value as a single string rather than an array — without this, $Surface -contains "X" returns
# false for every X, total checks = 0, and the script silently exits 0 with "All checks passed!"
# (a CI false positive). The "no surfaces matched" guard below also catches typos / unknown names.
$Surface = @($Surface | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })

$runAll = $Surface -contains "All"

# PF-IMP-1209: canonical surface names (same set as the -Surface gates / .PARAMETER list),
# in display order. The summary's per-surface coverage report walks this to show which selected
# surfaces recorded no findings — so "checked nothing" is distinguishable from "found no problems".
# Note (PF-IMP-1170): the inline `# Surface NN` section headers use stable historical numbers with
# a gap at 11 (retired Context Map Orphans), so a header's NN is NOT this list's positional index.
$CanonicalSurfaces = @(
    # FeatureTracking / TestTracking retired (PF-IMP-1299) — broken-link detection delegated to
    # LinkWatcher --validate. StateFiles retained for its structural inventory checks.
    'StateFiles', 'CrossRef', 'IdCounters', 'FeatureDeps',
    'DimensionConsistency', 'WorkflowTracking', 'MetadataSchema',
    'MasterStateConsistency', 'SourceLayout', 'TestStatusAggregation',
    'AuditMirror', 'CategoryAlignment', 'WorkflowAlignment', 'VariantPairConsistency',
    # PF-IMP-1212 / PF-PRO-049: surfaces for the previously-uncovered permanent trackers
    # (4 project-local + the central IMP tracker). TaskRegistry / AiTasksConsistency removed
    # (PF-IMP-1210 — superseded by Build-TaskMetadata.ps1 -Check).
    'FeatureRequestTracking', 'ArchitectureTracking', 'TechDebtTracking', 'BugTracking',
    'ProcessImprovementTracking',
    # PF-IMP-1589: blueprint→central reference-rot detector (appdev layout only)
    'BlueprintCentralRefs',
    # PF-IMP-1584 (PF-EVR-029 F-4): exploration tracker joins its sibling intake queues
    'ExplorationTracking',
    # PF-IMP-1677: task ids cited in authored framework prose (appdev layout only)
    'TaskIdRefs'
)

# --- Load project config (project_id drives the project-type-aware absent-target severity) ---
# (The language-config / test-file-extension load was removed with Surface 3 — PF-IMP-1299.)
$projectConfigPath = Join-Path $ProjectRoot "doc/project-config.json"
if (Test-Path $projectConfigPath) {
    try {
        $projCfg = Get-Content $projectConfigPath -Raw | ConvertFrom-Json
        $script:projectId = "$($projCfg.project_id)"   # $script:-qualified deliberately (PF-PRO-067 hardening rider) — read as $script:projectId inside functions
    } catch {
        Write-Warning "Could not load project config — project_id stays empty"
    }
}
# Declared workspace role (PF-PRO-067 Contract 4) — drives the absent-product-tracker severity
# ("do I have a product?" role question). Resolved once here via the shared helper.
$script:workspaceRole = Get-WorkspaceRole -ProjectRoot $ProjectRoot

# --- Helper: Resolve a markdown-relative path to an absolute path ---
function Resolve-MarkdownLink {
    param(
        [string]$LinkPath,
        [string]$SourceFileDir
    )

    # Skip anchors-only links, external URLs, and empty
    if ([string]::IsNullOrWhiteSpace($LinkPath)) { return $null }
    if ($LinkPath -match '^https?://') { return $null }
    if ($LinkPath -match '^#') { return $null }
    if ($LinkPath -match '^mailto:') { return $null }

    # Skip obviously non-file links (no slash/backslash and no file extension)
    if ($LinkPath -notmatch '[/\\]' -and $LinkPath -notmatch '\.\w{1,5}$') { return $null }

    # Strip anchor fragment
    $cleanPath = ($LinkPath -split '#')[0]
    if ([string]::IsNullOrWhiteSpace($cleanPath)) { return $null }

    # Project-root-relative paths use a single leading '/' or '\' (not UNC '//' or '\\').
    # Convention is used in feature-tracking.md, state files, README.md, CLAUDE.md, and
    # is honored by LinkWatcher + VS Code. On Windows, Join-Path treats '/foo' as
    # drive-rooted (C:\foo), so anchor to $script:ProjectRoot explicitly. (PF-IMP-764)
    if ($cleanPath -match '^[/\\][^/\\]') {
        $combined = Join-Path $script:ProjectRoot ($cleanPath.Substring(1))
    } else {
        $combined = Join-Path $SourceFileDir $cleanPath
    }
    try {
        $resolved = [System.IO.Path]::GetFullPath($combined)
        return $resolved
    } catch {
        return $null
    }
}

# --- Helper: Extract all markdown links from a line ---
function Get-MarkdownLinks {
    param([string]$Line)

    $links = @()
    $regex = [regex]'\[([^\]]*)\]\(([^)]+)\)'
    $matchCollection = $regex.Matches($Line)
    foreach ($m in $matchCollection) {
        # CommonMark allows <URL> wrapping for URLs containing spaces; strip the brackets.
        $path = $m.Groups[2].Value
        if ($path.StartsWith('<') -and $path.EndsWith('>')) {
            $path = $path.Substring(1, $path.Length - 2)
        }
        $links += [PSCustomObject]@{
            Text = $m.Groups[1].Value
            Path = $path
        }
    }
    return $links
}

# --- Helper: Find similar filenames for suggestions ---
function Find-SimilarFile {
    param(
        [string]$ExpectedPath
    )

    $dir = [System.IO.Path]::GetDirectoryName($ExpectedPath)
    $name = [System.IO.Path]::GetFileName($ExpectedPath)
    if (-not (Test-Path $dir)) { return $null }

    # Look for files with similar names in the same directory
    $candidates = Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -ne $name
    }

    # Simple similarity: share a common prefix of 5+ chars
    $prefix = if ($name.Length -ge 5) { $name.Substring(0, 5) } else { $name }
    $match = $candidates | Where-Object { $_.Name.StartsWith($prefix) } | Select-Object -First 1
    if ($match -and $match.Name) {
        return $match.Name
    }
    return ""
}

# --- Helper: Record check result ---
# -DetailOnly: For WARNING level, count toward warningCount but suppress display unless -Detailed is set.
# Used for warning classes that reflect schema/data drift rather than actionable issues, where the
# default-mode display-noise drowns real signal. The summary still reports the count and notes how
# many were hidden, so the noise is acknowledged rather than silently discarded.
function Add-CheckResult {
    param(
        [string]$Level,  # "ERROR", "WARNING", "OK"
        [string]$Surface,
        [string]$Context,
        [string]$Message,
        [switch]$DetailOnly
    )

    $script:totalChecks++
    # PF-IMP-1209: per-surface coverage tally. Keyed by the Surface arg every call already passes;
    # lets the summary distinguish a surface that recorded nothing from one that found no problems.
    if (-not [string]::IsNullOrEmpty($Surface)) {
        if (-not $script:surfaceRecorded.Contains($Surface)) { $script:surfaceRecorded[$Surface] = 0 }
        $script:surfaceRecorded[$Surface]++
    }
    switch ($Level) {
        "ERROR"   {
            $script:errorCount++
            $script:errorFingerprints.Add("$Surface|$Context|$Message")
            Write-Host "    $([char]0x274C) $Context : $Message" -ForegroundColor Red
        }
        "WARNING" {
            $script:warningCount++
            if ($DetailOnly -and -not $Detailed) {
                $script:detailOnlyHiddenCount++
            } else {
                Write-Host "    $([char]0x26A0)  $Context : $Message" -ForegroundColor Yellow
            }
        }
        "OK"      { $script:passCount++; if ($Detailed) { Write-Host "    $([char]0x2705) $Context : $Message" -ForegroundColor Green } }
    }
}

# --- Helper: record the faithful instance count a surface examined (PF-IMP-1209 remainder) ---
# Distinct from $surfaceRecorded (Add-CheckResult call count). A surface that walks N instances
# but only records findings on problems would look "silent" by call-count alone; the examined-N
# denominator makes "examined N, found nothing" distinguishable from "examined nothing".
function Set-SurfaceExamined {
    param([string]$Surface, [int]$Count)
    if (-not [string]::IsNullOrEmpty($Surface)) { $script:surfaceExamined[$Surface] = $Count }
}

# --- Helper: standardized absent / empty target finding (PF-IMP-1209 remainder, one convention) ---
# Every surface whose target file/dir is missing, or which examines 0 instances, routes through
# here so the outcome is a first-class finding (never silent, never a clean OK-pass) carrying a
# uniform "examined 0 instances" message and recording examined=0. Severity is the caller's call:
#   - ERROR for a required target (feature-tracking, state-files dir, domain-config, registries),
#     and for a secondary product tracker absent in a real product project — a setup defect that
#     must gate (a WARNING risks being ignored).
#   - WARNING for a present-but-empty target, a conditional/onboarding-only target, or a product
#     tracker absent in appdev (PRJ-000), where product state is legitimately N/A.
function Add-AbsentTargetResult {
    param(
        [ValidateSet("ERROR", "WARNING")][string]$Level,
        [string]$Surface,
        [string]$Context,
        [string]$Reason   # e.g. "feature-tracking.md not found", "directory exists but holds 0 state files"
    )
    $script:surfaceExamined[$Surface] = 0
    Add-CheckResult $Level $Surface $Context "$Reason — surface examined 0 instances (coverage gap, not a clean pass)"
}

# --- Helper: workspace-scoped temp directory for the validator's side files (PF-IMP-1984) ---
# Baselines and JSON summaries live under $env:TEMP. The directory used to be shared by every
# workspace that ran this validator ("vst-baselines" / "vst-summaries"), which is harmless for
# writes — each file is already auto-named per project + timestamp + PID — but NOT for the
# retention prune below: that prunes by AGE across the whole directory, so a second workspace
# running this validator deletes the first workspace's baselines. Scoping the directory to the
# resolved project root makes the prune structurally incapable of reaching another workspace's
# files, rather than relying on filenames it never inspects. The short root hash disambiguates
# two checkouts that share a leaf directory name.
function Get-ValidatorTempDir {
    param(
        [Parameter(Mandatory)][ValidateSet('vst-baselines', 'vst-summaries')][string]$Kind,
        [Parameter(Mandatory)][string]$Root
    )
    $normalized = "$Root".TrimEnd('\', '/').ToLowerInvariant()
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = (($sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($normalized))) |
            ForEach-Object { $_.ToString('x2') }) -join ''
    } finally { $sha256.Dispose() }
    $leaf = (Split-Path $Root -Leaf) -replace '[^\w\-]', '-'
    Join-Path ([System.IO.Path]::GetTempPath()) ("{0}-{1}-{2}" -f $Kind, $leaf, $hash.Substring(0, 8))
}

# --- Helper: emit optional JSON summary, then exit (PF-IMP-1214) ---
# Centralizes every terminal exit so a machine-readable summary can be written at each
# verdict path (final / baseline-delta / no-surface-match). Without -Json/-JsonPath this
# is a transparent `exit $ExitCode` — host output and exit semantics are unchanged.
function Complete-Run {
    param([int]$ExitCode)

    if ($Json -or -not [string]::IsNullOrWhiteSpace($JsonPath)) {
        $summary = [ordered]@{
            schema         = 1
            generated      = (Get-Date -Format 'o')
            projectRoot    = "$ProjectRoot"
            surfaces       = @($Surface)
            exitCode       = $ExitCode
            totalChecks    = $script:totalChecks
            errors         = $script:errorCount
            warnings       = $script:warningCount
            warningsHidden = $script:detailOnlyHiddenCount
            passed         = $script:passCount
            coverage       = [ordered]@{
                selected   = @($script:selectedSurfaces)
                silent     = @($script:silentSurfaces)
                examined   = $script:surfaceExamined
                perSurface = $script:surfaceRecorded
            }
            errorFingerprints = @($script:errorFingerprints)
            baseline       = $script:jsonBaseline
        }
        $jsonText = $summary | ConvertTo-Json -Depth 6

        $target = $JsonPath
        if ([string]::IsNullOrWhiteSpace($target)) {
            $jsonDir = Get-ValidatorTempDir -Kind 'vst-summaries' -Root $ProjectRoot
            New-Item -ItemType Directory -Path $jsonDir -Force | Out-Null
            $projectName = (Split-Path $ProjectRoot -Leaf) -replace '[^\w\-]', '-'
            $target = Join-Path $jsonDir ("vst-summary-{0}-{1}-{2}.json" -f $projectName, (Get-Date -Format 'yyyyMMdd-HHmmss'), $PID)
        }
        try {
            $jsonText | Set-Content -Path $target -Encoding UTF8
            Write-Host ""
            Write-Host "  JSON summary written: $target" -ForegroundColor Cyan
        } catch {
            Write-Host ""
            Write-Host "  Could not write JSON summary to '$target': $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    exit $ExitCode
}

# =========================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  State Tracking Validation Report" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Project Root: $ProjectRoot" -ForegroundColor Gray
Write-Host ""

# =========================================================================
# SURFACE 1: Feature Tracking — RETIRED (PF-IMP-1299)
# Broken-link detection for feature-tracking.md is delegated to LinkWatcher --validate
# (run_linkwatcher_validate.ps1), wired into the task finalization gates (structure-change /
# retrospective-documentation / framework-rollout Mode C). 'FeatureTracking' was removed from
# $CanonicalSurfaces and the -Surface list; the number is left vacant (not renumbered), per the
# Surface 11 convention above. (Surfaces 4 and 8 still load feature-tracking.md independently.)
# =========================================================================

# =========================================================================
# SURFACE 2: Feature State Files
# =========================================================================
if ($runAll -or $Surface -contains "StateFiles") {
    Write-Host "[2/5] Feature State Files" -ForegroundColor Cyan

    $stateDir = Join-Path $ProjectRoot "doc/state-tracking/features"
    if (-not (Test-Path $stateDir)) {
        # Role-aware severity per the Add-AbsentTargetResult policy: product state is
        # legitimately N/A in a non-project workspace (PF-IMP-1957; role-based per PF-PRO-067).
        $absentLevel = if ($script:workspaceRole -ne 'project') { "WARNING" } else { "ERROR" }
        Add-AbsentTargetResult $absentLevel "StateFiles" "features" "feature state-files directory not found ($stateDir)"
    } else {
        $stateFiles = Get-ChildItem -Path $stateDir -Filter "*-implementation-state.md" -File
        Set-SurfaceExamined "StateFiles" (@($stateFiles).Count)
        Write-Host "  Found $($stateFiles.Count) state files" -ForegroundColor Gray

        # PF-IMP-1209 (A-1/A-2): an existing dir with zero state files used to record nothing — a
        # silent false-green. Worse, on a single-surface run totalChecks stayed 0 and misfired the
        # "No surfaces matched" guard, reporting a valid empty surface as an unknown surface name.
        # Emit the standardized empty-instance WARNING so the surface visibly examined 0 instances.
        if (@($stateFiles).Count -eq 0) {
            Add-AbsentTargetResult "WARNING" "StateFiles" $stateDir "directory exists but holds 0 feature state files"
        }

        foreach ($sf in $stateFiles) {
            $sfDir = $sf.DirectoryName
            $sfContent = Get-Content $sf.FullName -Encoding UTF8
            $sfName = $sf.Name
            $linksInFile = 0
            $inSection = ""

            foreach ($line in $sfContent) {
                # Track which section we're in. Match by section TITLE, not number, so the
                # lightweight (Tier 1) template's shifted numbering — Documentation Inventory §3,
                # Code Inventory §4, Dependencies §5 — is handled identically to the full
                # template's §4/§5/§6. Keying on numbers made Tier 1 files match no section and
                # emit a false "No links found" warning (PF-IMP-954).
                if ($line -match '^## \d+\. Documentation Inventory') { $inSection = "DocInventory" }
                elseif ($line -match '^## \d+\. Code Inventory') { $inSection = "CodeInventory" }
                elseif ($line -match '^## \d+\. Dependencies') { $inSection = "Dependencies" }
                elseif ($line -match '^## \d') { $inSection = "" }

                # Only the three link-bearing inventory sections feed the structural check
                if ($inSection -notin @("DocInventory", "CodeInventory", "Dependencies")) { continue }

                # Skip non-table rows
                if ($line -notmatch '^\|') { continue }
                # Skip header separator rows
                if ($line -match '^\|\s*-') { continue }

                # STRUCTURAL check only (PF-IMP-1299): count resolvable file links present so the
                # "inventory section has no links" warning below still fires. Whether each link
                # RESOLVES on disk is delegated to LinkWatcher --validate (run_linkwatcher_validate.ps1),
                # wired into the task finalization gates — no Test-Path here.
                $links = Get-MarkdownLinks -Line $line
                foreach ($link in $links) {
                    $resolved = Resolve-MarkdownLink -LinkPath $link.Path -SourceFileDir $sfDir
                    if ($null -eq $resolved) { continue }
                    $linksInFile++
                }
            }

            if ($linksInFile -eq 0) {
                Write-Host "    $([char]0x26A0)  $sfName : No links found in the Documentation/Code/Dependencies inventory sections" -ForegroundColor Yellow
                $script:warningCount++
                $script:totalChecks++
            } elseif ($Detailed) {
                Write-Host "    $([char]0x2705) $sfName : $linksInFile inventory link(s) present (existence checked by LinkWatcher --validate)" -ForegroundColor Green
            }
        }
    }
    Write-Host ""
}

# =========================================================================
# SURFACE 3: Test Tracking — RETIRED (PF-IMP-1299)
# Broken-link detection for test-tracking.md test-file references is delegated to LinkWatcher
# --validate (run_linkwatcher_validate.ps1), wired into the task finalization gates. 'TestTracking'
# was removed from $CanonicalSurfaces and the -Surface list; the number is left vacant (not
# renumbered), per the Surface 11 convention above.
# =========================================================================

# =========================================================================
# SURFACE 4: Cross-Reference Consistency
# =========================================================================
if ($runAll -or $Surface -contains "CrossRef") {
    Write-Host "[4/5] Cross-Reference Consistency" -ForegroundColor Cyan

    # Load known feature IDs from feature-tracking.md
    $ftPath = Join-Path $ProjectRoot "doc/state-tracking/permanent/feature-tracking.md"
    $knownFeatureIds = @()
    if (Test-Path $ftPath) {
        $ftContent = Get-Content $ftPath -Encoding UTF8
        foreach ($line in $ftContent) {
            if ($line -match '^\|\s*\[(\d+\.\d+\.\d+)\]') {
                $knownFeatureIds += $matches[1]
            }
        }
    }

    if ($knownFeatureIds.Count -eq 0) {
        Add-CheckResult "WARNING" "CrossRef" "feature-tracking.md" "No feature IDs found — cannot cross-reference"
    } else {
        Write-Host "  Known features: $($knownFeatureIds -join ', ')" -ForegroundColor Gray

        # Check test-registry.yaml feature IDs
        $registryPath = Join-Path $ProjectRoot "test/test-registry.yaml"
        if (Test-Path $registryPath) {
            $registryLines = Get-Content $registryPath -Encoding UTF8
            $registryFeatureIds = @()
            $crossCuttingIds = @()

            foreach ($line in $registryLines) {
                $trimmed = $line.Trim()
                if ($trimmed -match 'featureId:\s*"([^"]+)"') {
                    $fid = $matches[1]
                    if ($fid -notin $registryFeatureIds) {
                        $registryFeatureIds += $fid
                    }
                }
                if ($trimmed -match 'crossCuttingFeatures:') {
                    $ccMatches = [regex]::Matches($trimmed, '[\d]+\.[\d]+\.[\d]+')
                    foreach ($ccm in $ccMatches) {
                        if ($ccm.Value -notin $crossCuttingIds) {
                            $crossCuttingIds += $ccm.Value
                        }
                    }
                }
            }

            # Check primary feature IDs
            $invalidPrimary = @()
            foreach ($fid in $registryFeatureIds) {
                if ($fid -notin $knownFeatureIds) {
                    $invalidPrimary += $fid
                    Add-CheckResult "WARNING" "CrossRef" "test-registry.yaml" "Feature ID '$fid'../ not in feature-tracking.md"
                }
            }
            if ($invalidPrimary.Count -eq 0) {
                Add-CheckResult "OK" "CrossRef" "Primary feature IDs" "All $($registryFeatureIds.Count) feature IDs match"
            }

            # Check cross-cutting feature IDs
            $invalidCC = @()
            foreach ($ccId in $crossCuttingIds) {
                if ($ccId -notin $knownFeatureIds) {
                    $invalidCC += $ccId
                    Add-CheckResult "WARNING" "CrossRef" "test-registry.yaml" "Cross-cutting feature ID '$ccId'../ not in feature-tracking.md"
                }
            }
            if ($invalidCC.Count -eq 0 -and $crossCuttingIds.Count -gt 0) {
                Add-CheckResult "OK" "CrossRef" "Cross-cutting IDs" "All $($crossCuttingIds.Count) cross-cutting feature IDs match"
            }
        } else {
            Add-CheckResult "WARNING" "CrossRef" "test-registry.yaml" "File not found — skipping cross-reference checks"
        }
    }
    Write-Host ""
}

# =========================================================================
# SURFACE 5: ID Counter Health
# =========================================================================
if ($runAll -or $Surface -contains "IdCounters") {
    Write-Host "[5/5] ID Counter Health" -ForegroundColor Cyan

    # Face fix (PF-PRO-068, owner-decided 2026-08-09): Surface 5 validates counters against the
    # WRITE face — the registry mints increment and the tree their artifacts land in
    # (paths.blueprint at a producer role, the operative tree at a leaf). On the consumer key a
    # post-cutover -FixCounters would write nextAvailable into the received projection while
    # mints increment the producer registry — a counter/file split through the validation door.
    $pfFrameworkWritePath = if ($script:workspaceRole -in @('framework', 'framework-builder')) {
        Get-BlueprintPath -ProjectRoot $ProjectRoot
    } else {
        Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot
    }

    # Load all three ID registries
    $registryMap = @{
        'PF' = @{ Path = (Join-Path $pfFrameworkWritePath "PF-id-registry.json"); Registry = $null; Fixed = 0 }
        'PD' = @{ Path = (Join-Path $ProjectRoot "doc/PD-id-registry.json"); Registry = $null; Fixed = 0 }
        'TE' = @{ Path = (Join-Path $ProjectRoot "test/TE-id-registry.json"); Registry = $null; Fixed = 0 }
    }
    $allLoaded = $true
    foreach ($key in $registryMap.Keys) {
        $regPath = $registryMap[$key].Path
        if (Test-Path $regPath) {
            $registryMap[$key].Registry = Get-Content $regPath -Raw -Encoding UTF8 | ConvertFrom-Json
        } else {
            Add-CheckResult "ERROR" "IdCounters" "$key-id-registry.json" "File not found: $regPath"
            $allLoaded = $false
        }
    }

    if ($allLoaded) {
        # PF-IMP-1213: enumerate EVERY counter-bearing prefix across the three registries
        # rather than a hardcoded subset of 6. Counter health is file-validatable only for
        # prefixes whose documents carry an `id: <PREFIX>-NNN` frontmatter line in a directory;
        # table-row ID pools (e.g. PD-BUG, PD-FRQ, WF — IDs live as rows in a tracking table,
        # not per-file) have no file instances to scan and are reported as "not file-validated"
        # rather than faked as a green pass (the PF-IMP-1209 coverage-honesty principle applied
        # to Surface 5).
        #
        # Scan base differs by registry: PF prefix dirs are framework-relative
        # ("process-framework/..."), so they resolve under the PARENT of the framework path
        # (works in both the appdev blueprint layout and a rolled-out project, because every
        # face tree's leaf directory is literally named "process-framework"); PD/TE dirs are
        # project-relative. Write face, same as the registry file above — the counters and the
        # artifacts they count must come from the same tree. The `id:` match is anchored to the
        # start of a line (frontmatter), so table cells and inline references like
        # "...some-id: PD-BUG-001..." don't false-match.
        $pfBase = Split-Path $pfFrameworkWritePath -Parent

        $validatedPrefixCount = 0
        $uncheckedPrefixes = [System.Collections.Generic.List[string]]::new()

        foreach ($regKey in @('PF', 'PD', 'TE')) {
            $idRegistry = $registryMap[$regKey].Registry
            if (-not $idRegistry -or -not $idRegistry.prefixes) { continue }
            $scanBase = if ($regKey -eq 'PF') { $pfBase } else { $ProjectRoot }

            foreach ($prefixProp in $idRegistry.prefixes.PSObject.Properties) {
                $prefix = $prefixProp.Name
                $registryEntry = $prefixProp.Value
                if ($null -eq $registryEntry.nextAvailable) { continue }
                $nextAvailable = [int]$registryEntry.nextAvailable

                # Resolve the prefix's directories (every dir key except the "default" pointer,
                # whose value is a key name, not a path); keep existing ones; drop any nested
                # under another so a parent dir (e.g. PF-TSK's tasks/ over its phase subdirs) is
                # scanned once.
                $dirPaths = @()
                if ($registryEntry.directories) {
                    foreach ($dprop in $registryEntry.directories.PSObject.Properties) {
                        if ($dprop.Name -eq 'default') { continue }
                        $abs = Join-Path $scanBase $dprop.Value
                        if (Test-Path $abs) { $dirPaths += (Resolve-Path $abs).Path }
                    }
                }
                $topPaths = @()
                foreach ($p in (@($dirPaths | Sort-Object -Unique) | Sort-Object { $_.Length })) {
                    $sep = [System.IO.Path]::DirectorySeparatorChar
                    if (-not ($topPaths | Where-Object { $p.StartsWith("$_$sep", [System.StringComparison]::OrdinalIgnoreCase) })) {
                        $topPaths += $p
                    }
                }

                # Scan for the max `id:` frontmatter number across the prefix's directories.
                $maxId = 0
                $found = $false
                foreach ($dir in $topPaths) {
                    $files = Get-ChildItem -Path $dir -Filter "*.md" -File -Recurse -ErrorAction SilentlyContinue
                    foreach ($file in $files) {
                        $content = Get-Content $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                        if ($content -and $content -match "(?m)^id:\s*$([regex]::Escape($prefix))-(\d+)") {
                            $found = $true
                            $num = [int]$matches[1]
                            if ($num -gt $maxId) { $maxId = $num }
                        }
                    }
                }

                if (-not $found) {
                    # No file-based instances: counter not file-validatable (table-row pool or
                    # empty dir). Recorded honestly below, not as a green "no files" OK.
                    $uncheckedPrefixes.Add($prefix)
                    continue
                }

                $validatedPrefixCount++
                $expectedNext = $maxId + 1
                if ($nextAvailable -eq $expectedNext) {
                    Add-CheckResult "OK" "IdCounters" $prefix "nextAvailable=$nextAvailable, maxUsed=$prefix-$maxId"
                } elseif ($nextAvailable -lt $expectedNext) {
                    Add-CheckResult "ERROR" "IdCounters" $prefix "nextAvailable=$nextAvailable but max ID is $prefix-$maxId (would cause collision! expected: $expectedNext)"
                    if ($FixCounters) {
                        $registryEntry.nextAvailable = $expectedNext
                        $registryMap[$regKey].Fixed++
                        Write-Host "      Fixed: nextAvailable set to $expectedNext" -ForegroundColor Magenta
                    }
                } else {
                    # nextAvailable > expectedNext — gap exists, just a warning
                    Add-CheckResult "WARNING" "IdCounters" $prefix "nextAvailable=$nextAvailable but max ID is $prefix-$maxId (gap of $($nextAvailable - $expectedNext))"
                }
            }
        }

        # Honest Surface-5 coverage line (PF-IMP-1213 / the PF-IMP-1209 principle): state how many
        # counters were actually validated against files and which prefixes had no file-based
        # instances, so a green Surface 5 is not misread as "all counters are healthy".
        Add-CheckResult "OK" "IdCounters" "Coverage" "Validated $validatedPrefixCount file-based prefix counter(s); $($uncheckedPrefixes.Count) prefix(es) have no file-based instances (table-row pools or empty dirs), not counter-validated: $($uncheckedPrefixes -join ', ')"

        if ($FixCounters) {
            foreach ($key in $registryMap.Keys) {
                if ($registryMap[$key].Fixed -gt 0) {
                    $registryMap[$key].Registry | ConvertTo-Json -Depth 10 | Set-Content $registryMap[$key].Path -Encoding UTF8
                    Write-Host "  Fixed $($registryMap[$key].Fixed) counter(s) in $key-id-registry.json" -ForegroundColor Magenta
                }
            }
        }
    }
    Write-Host ""
}

# =========================================================================
# Surface 6: Feature Dependencies freshness
# =========================================================================
if ($runAll -or $Surface -contains "FeatureDeps") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 6: Feature Dependencies" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $depsFile = Join-Path $ProjectRoot "doc/technical/architecture/feature-dependencies.md"
    $updateScript = Join-Path (Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot) "scripts/update/Update-FeatureDependencies.ps1"

    if (-not (Test-Path $updateScript)) {
        Add-CheckResult "WARNING" "FeatureDeps" "Script" "Update-FeatureDependencies.ps1 not found"
    } else {
        # Check if any state file is newer than the generated dependencies file
        $needsRegeneration = $false
        if (-not (Test-Path $depsFile)) {
            $needsRegeneration = $true
        } else {
            $depsLastWrite = (Get-Item $depsFile).LastWriteTime
            $stateDir = Join-Path $ProjectRoot "doc/state-tracking/features"
            $newerFiles = Get-ChildItem -Path $stateDir -Filter "*-implementation-state.md" |
                Where-Object { $_.LastWriteTime -gt $depsLastWrite }
            if ($newerFiles.Count -gt 0) {
                $needsRegeneration = $true
            }
        }

        if ($needsRegeneration) {
            Write-Host "  Feature state files are newer than feature-dependencies.md — regenerating..." -ForegroundColor Yellow
            & $updateScript -Confirm:$false
            Add-CheckResult "OK" "FeatureDeps" "Regenerated" "feature-dependencies.md updated from state files"
        } else {
            Add-CheckResult "OK" "FeatureDeps" "UpToDate" "feature-dependencies.md is current"
        }
    }
    Write-Host ""
}

# =========================================================================
# Surface 7: Dimension Consistency
# =========================================================================
if ($runAll -or $Surface -contains "DimensionConsistency") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 7: Dimension Consistency" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $validDimensions = @("AC", "CQ", "ID", "DA", "EM", "SE", "PE", "OB", "UX", "DI")
    $stateDir = Join-Path $ProjectRoot "doc/state-tracking/features"

    if (Test-Path $stateDir) {
        $stateFiles = Get-ChildItem -Path $stateDir -Filter "*-implementation-state.md" -File
        $filesWithProfile = 0
        $filesWithoutProfile = 0
        $filesSkippedLightweight = 0

        foreach ($file in $stateFiles) {
            $content = Get-Content $file.FullName -Raw

            # Tier 1 (lightweight) state files have no Dimension Profile section by design —
            # their §7 is Quality Assessment. Skip them; flagging would be a false positive
            # (PF-IMP-954). The lightweight header marker is the discriminator, so a genuinely
            # incomplete full file (missing its profile) is still caught below.
            if ($content -match '\*\*Lightweight variant\*\*') {
                $filesSkippedLightweight++
                continue
            }

            # Check if Dimension Profile section exists
            if ($content -match "## \d+\. Dimension Profile") {
                $filesWithProfile++

                # Extract dimension abbreviations used and validate them
                $dimMatches = [regex]::Matches($content, '\(([A-Z]{2})\)')
                $usedDims = @()
                foreach ($m in $dimMatches) {
                    $abbr = $m.Groups[1].Value
                    if ($usedDims -notcontains $abbr) { $usedDims += $abbr }
                }

                foreach ($abbr in $usedDims) {
                    if ($validDimensions -notcontains $abbr) {
                        Add-CheckResult "ERROR" "DimensionConsistency" $file.Name "Invalid dimension abbreviation: $abbr"
                    }
                }

                # Check that importance values are valid
                $importanceMatches = [regex]::Matches($content, '(?<=\| [^|]+ \| )(Critical|Relevant|N/A)(?= \|)')
                if ($importanceMatches.Count -eq 0 -and $content -notmatch 'none evaluated') {
                    Add-CheckResult "WARNING" "DimensionConsistency" $file.Name "Dimension Profile section exists but no importance values found"
                }

                Add-CheckResult "OK" "DimensionConsistency" $file.Name "Dimension Profile present with $($usedDims.Count) dimensions"
            } else {
                $filesWithoutProfile++
                Add-CheckResult "WARNING" "DimensionConsistency" $file.Name "Missing Dimension Profile section (Section 7)"
            }
        }

        Set-SurfaceExamined "DimensionConsistency" (@($stateFiles).Count)
        Write-Host "  Feature state files: $($stateFiles.Count) total, $filesWithProfile with profiles, $filesWithoutProfile without, $filesSkippedLightweight Tier 1 (skipped)" -ForegroundColor Gray
    } else {
        Add-CheckResult "WARNING" "DimensionConsistency" "Directory" "Feature state directory not found: $stateDir"
    }
    Write-Host ""
}

# =========================================================================
# Surface 8: Workflow Tracking Consistency
# =========================================================================
if ($runAll -or $Surface -contains "WorkflowTracking") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 8: Workflow Tracking" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $wfPath = Join-Path $ProjectRoot "doc/state-tracking/permanent/user-workflow-tracking.md"

    if (-not (Test-Path $wfPath)) {
        Add-CheckResult "WARNING" "WorkflowTracking" "user-workflow-tracking.md" "File not found — workflow tracking not set up"
    } else {
        # Parse workflow tracking file for WF-IDs and Required Features
        $wfContent = Get-Content $wfPath -Encoding UTF8
        $workflowIds = @()
        $workflowFeatures = @{}  # WF-ID → list of feature IDs

        foreach ($line in $wfContent) {
            if ($line -match '^\|\s*(WF-\d+)') {
                $wfId = $matches[1]
                $workflowIds += $wfId
                $cells = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                # Required Features is typically the 4th column (index 3)
                if ($cells.Count -ge 4) {
                    $reqFeatures = $cells[3] -split ',\s*' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                    $workflowFeatures[$wfId] = $reqFeatures
                }
            }
        }

        Set-SurfaceExamined "WorkflowTracking" (@($workflowIds).Count)
        Write-Host "  Found $($workflowIds.Count) workflows" -ForegroundColor Gray

        # Load known feature IDs from feature-tracking.md
        $ftPath2 = Join-Path $ProjectRoot "doc/state-tracking/permanent/feature-tracking.md"
        $knownFeatures2 = @()
        if (Test-Path $ftPath2) {
            $ftContent2 = Get-Content $ftPath2 -Encoding UTF8
            foreach ($line in $ftContent2) {
                if ($line -match '^\|\s*\[(\d+\.\d+\.\d+)\]') {
                    $knownFeatures2 += $matches[1]
                }
            }
        }

        # Check 1: All Required Features reference valid feature IDs
        foreach ($wfId in $workflowIds) {
            if ($workflowFeatures.ContainsKey($wfId)) {
                foreach ($fId in $workflowFeatures[$wfId]) {
                    if ($fId -match '^\d+\.\d+\.\d+$') {
                        if ($knownFeatures2 -contains $fId) {
                            Add-CheckResult "OK" "WorkflowTracking" "$wfId/$fId" "Required feature exists in feature tracking"
                        } else {
                            Add-CheckResult "ERROR" "WorkflowTracking" "$wfId/$fId" "Required feature '$fId' not found in feature-tracking.md"
                        }
                    }
                }
            }
        }

        # Check 2: Feature state files' workflows: metadata references valid WF-IDs
        $stateDir2 = Join-Path $ProjectRoot "doc/state-tracking/features"
        if (Test-Path $stateDir2) {
            $stateFiles2 = Get-ChildItem -Path $stateDir2 -Filter "*-implementation-state.md" -File
            foreach ($sf in $stateFiles2) {
                $sfContent = Get-Content $sf.FullName -Raw -Encoding UTF8
                # Extract feature ID from filename (e.g., 0.1.1-core-architecture-implementation-state.md)
                $featureIdFromName = ""
                if ($sf.Name -match '^(\d+\.\d+\.\d+)') {
                    $featureIdFromName = $matches[1]
                }

                # Find workflows: metadata — supports both YAML list format and inline format
                # YAML list: "workflows:\n  - WF-001\n  - WF-002"
                # Inline: "workflows: [WF-001, WF-002]"
                $wfList = @()
                if ($sfContent -match 'workflows:\s*\[([^\]]*)\]') {
                    # Inline format
                    $wfList = $matches[1] -split ',\s*' | ForEach-Object { $_.Trim().Trim('"').Trim("'") } | Where-Object { $_ -ne '' }
                } elseif ($sfContent -match 'workflows:') {
                    # YAML list format — extract all "  - WF-XXX" lines after "workflows:"
                    $wfMatches = [regex]::Matches($sfContent, '(?<=workflows:[\s\S]*?)- (WF-\d+)')
                    foreach ($m in $wfMatches) {
                        $wfList += $m.Groups[1].Value
                    }
                }

                if ($wfList.Count -gt 0) {
                    foreach ($wf in $wfList) {
                        if ($workflowIds -contains $wf) {
                            Add-CheckResult "OK" "WorkflowTracking" "$($sf.Name)/$wf" "Workflow reference valid"
                        } else {
                            Add-CheckResult "ERROR" "WorkflowTracking" "$($sf.Name)/$wf" "Workflow '$wf' not found in user-workflow-tracking.md"
                        }
                    }

                    # Check 3: Cross-reference — if feature lists WF-ID, does that workflow list this feature?
                    foreach ($wf in $wfList) {
                        if ($workflowFeatures.ContainsKey($wf) -and $featureIdFromName) {
                            if ($workflowFeatures[$wf] -contains $featureIdFromName) {
                                Add-CheckResult "OK" "WorkflowTracking" "$($sf.Name)/$wf" "Cross-reference valid (feature listed in workflow)"
                            } else {
                                Add-CheckResult "WARNING" "WorkflowTracking" "$($sf.Name)/$wf" "Feature $featureIdFromName claims workflow $wf but is not listed in that workflow's Required Features"
                            }
                        }
                    }
                }
                # Note: missing workflows: field is not an error — it may be an older state file
            }
        }
    }
    Write-Host ""
}

# =========================================================================
# Surfaces 9 (Task Registry) and 12 (AI Tasks Consistency) RETIRED — PF-IMP-1210 / PF-PRO-049.
# Task-registry / ai-tasks consistency is owned by the authoritative regeneration-diff gate
# `Build-TaskMetadata.ps1 -Check` (PF-PRO-042), which renders ai-tasks.md + the task registry
# from task frontmatter and is wired into .pre-commit-config.yaml. The retired surfaces only
# substring-checked ID presence and could disagree with -Check on malformed entries. Their
# historical numbers (9, 12) are left as gaps, like retired Surface 11.
# =========================================================================

# =========================================================================
# Surface 10: Metadata Schema Conformance
# =========================================================================
if ($runAll -or $Surface -contains "MetadataSchema") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 10: Metadata Schema" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $domainCfgPath = Join-Path (Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot) "domain-config.json"
    if (-not (Test-Path $domainCfgPath)) {
        Add-CheckResult "WARNING" "MetadataSchema" "domain-config.json" "File not found — metadata schema validation skipped"
    } else {
        $domainCfg = Get-Content $domainCfgPath -Raw | ConvertFrom-Json
        $schemas = $domainCfg.artifact_metadata_schemas

        if (-not $schemas) {
            Add-CheckResult "WARNING" "MetadataSchema" "domain-config.json" "No artifact_metadata_schemas section found"
        } else {
            # Map artifact types to directory globs (relative to the process-framework root)
            $artifactDirs = @{
                "task"        = @{ dir = "tasks"; recurse = $true }
                "template"    = @{ dir = "templates"; recurse = $true }
                "guide"       = @{ dir = "guides"; recurse = $true }
            }

            $totalFiles = 0
            $conformingFiles = 0
            $violationFiles = 0
            $fwDirMS = Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot
            # Per-(artifact_type, field) accumulator feeding the reconciliation summary below.
            $unknownFieldIndex = @{}

            foreach ($artifactType in $artifactDirs.Keys) {
                $schema = $schemas.$artifactType
                if (-not $schema) {
                    Add-CheckResult "WARNING" "MetadataSchema" $artifactType "No schema defined in domain-config.json"
                    continue
                }

                $searchDir = Join-Path $fwDirMS $artifactDirs[$artifactType].dir
                if (-not (Test-Path $searchDir)) { continue }

                $mdFiles = Get-ChildItem -Path $searchDir -Filter "*.md" -Recurse -File | Where-Object {
                    # Exclude README files — they are not artifacts with standard metadata.
                    # Exclude *-path.md sub-path elaboration docs — they are subordinate to a
                    # parent task (e.g., code-refactoring-{lightweight,standard}-path.md under
                    # PF-TSK-022) and inherit its frontmatter; giving them their own id: would
                    # falsely catalogue them as standalone tasks. See PF-IMP-005.
                    $_.Name -ne "README.md" -and $_.Name -notlike "*-path.md"
                }

                foreach ($file in $mdFiles) {
                    $totalFiles++
                    $content = Get-Content $file.FullName -Raw -Encoding UTF8
                    $relPath = $file.FullName.Substring($ProjectRoot.Length + 1) -replace '\\', '/'

                    # Extract YAML frontmatter
                    if ($content -notmatch '^---\s*\r?\n([\s\S]*?)\r?\n---') {
                        Add-CheckResult "WARNING" "MetadataSchema" $relPath "No YAML frontmatter found"
                        $violationFiles++
                        continue
                    }

                    $frontmatter = $Matches[1]
                    # Parse frontmatter into hashtable (simple key: value parsing)
                    $fields = @{}
                    foreach ($line in ($frontmatter -split '\r?\n')) {
                        if ($line -match '^(\w[\w_]*):\s*(.*)$') {
                            $fields[$Matches[1]] = $Matches[2].Trim()
                        }
                    }

                    $fileHasViolation = $false

                    # Check required fields
                    foreach ($reqField in $schema.required) {
                        if (-not $fields.ContainsKey($reqField)) {
                            Add-CheckResult "ERROR" "MetadataSchema" $relPath "Missing required field: $reqField"
                            $fileHasViolation = $true
                        }
                    }

                    # Check field values (only for fields that exist)
                    if ($schema.field_values) {
                        # Check id pattern
                        if ($schema.field_values.id_pattern -and $fields.ContainsKey("id")) {
                            $idVal = $fields["id"]
                            # Skip template placeholder IDs (contain [ or X)
                            if ($idVal -notmatch '\[' -and $idVal -notmatch 'XXX') {
                                if ($idVal -notmatch $schema.field_values.id_pattern) {
                                    Add-CheckResult "ERROR" "MetadataSchema" $relPath "ID '$idVal' does not match pattern $($schema.field_values.id_pattern)"
                                    $fileHasViolation = $true
                                }
                            }
                        }

                        # Check type value
                        if ($schema.field_values.type -and $fields.ContainsKey("type")) {
                            $typeVal = $fields["type"]
                            $allowedTypes = @($schema.field_values.type)
                            if ($typeVal -notin $allowedTypes) {
                                Add-CheckResult "ERROR" "MetadataSchema" $relPath "type '$typeVal' not in allowed values: $($allowedTypes -join ', ')"
                                $fileHasViolation = $true
                            }
                        }

                        # Check category value
                        if ($schema.field_values.category -and $fields.ContainsKey("category")) {
                            $catVal = $fields["category"]
                            $allowedCats = @($schema.field_values.category)
                            if ($catVal -notin $allowedCats) {
                                Add-CheckResult "ERROR" "MetadataSchema" $relPath "category '$catVal' not in allowed values: $($allowedCats -join ', ')"
                                $fileHasViolation = $true
                            }
                        }
                    }

                    # Check for unknown fields (not in required or optional).
                    # Marked -DetailOnly: in default mode this class is dominated by legitimate
                    # template-subtype fields (schema-template drift) rather than typos. Surfaced
                    # via -Detailed for targeted schema audits. See PF-IMP-646.
                    # Reconciliation procedure: process-framework/guides/support/schema-audit-procedure-guide.md (PF-IMP-690).
                    $knownFields = @($schema.required) + @($schema.optional)
                    foreach ($fieldName in $fields.Keys) {
                        if ($fieldName -notin $knownFields) {
                            Add-CheckResult "WARNING" "MetadataSchema" $relPath "Unknown field: $fieldName (not in schema for $artifactType)" -DetailOnly
                            $fileHasViolation = $true
                            # Collect the Declare/Fix evidence for the reconciliation summary below:
                            # which variant_group family each carrying file belongs to, and how many
                            # carriers declare no family at all.
                            $ufKey = "$artifactType|$fieldName"
                            if (-not $unknownFieldIndex.ContainsKey($ufKey)) {
                                $unknownFieldIndex[$ufKey] = [pscustomobject]@{
                                    ArtifactType  = $artifactType
                                    Field         = $fieldName
                                    Count         = 0
                                    NoFamilyCount = 0
                                    Families      = [System.Collections.Generic.List[string]]::new()
                                }
                            }
                            $ufEntry = $unknownFieldIndex[$ufKey]
                            $ufEntry.Count++
                            $ufVg = $fields['variant_group']
                            if ($ufVg) {
                                if ($ufVg -notin $ufEntry.Families) { $ufEntry.Families.Add($ufVg) }
                            } else {
                                $ufEntry.NoFamilyCount++
                            }
                        }
                    }

                    # Body-frontmatter axis check (templates only). A template that authors the
                    # CREATED document's frontmatter in its BODY (a second --- block below the
                    # header — payload copied verbatim by a hand-rolling creation script) must emit
                    # type:/category: matching its own creates_document_type/_category declaration.
                    # The header-only parse above never sees those body blocks, so a contradiction
                    # (e.g. header declares "Product Documentation" but the payload emits
                    # "Process Framework") ships to every document created from the template. Two
                    # incidents drove this: the E2E templates (PF-IMP-1525) and validation-report
                    # (PF-IMP-1698). Placeholder values (containing '[') are skipped.
                    if ($artifactType -eq 'template' -and
                        ($fields.ContainsKey('creates_document_type') -or $fields.ContainsKey('creates_document_category'))) {
                        $declType = $fields['creates_document_type']
                        $declCat  = $fields['creates_document_category']
                        $allLines = $content -split '\r?\n'
                        $fenceIdx = @(for ($li = 0; $li -lt $allLines.Count; $li++) { if ($allLines[$li] -match '^---[ \t]*$') { $li } })
                        # Skip the header block (its first two fences), then greedily pair the rest.
                        $fptr = if ($fenceIdx.Count -ge 2) { 2 } else { $fenceIdx.Count }
                        while ($fptr -lt $fenceIdx.Count - 1) {
                            $a = $fenceIdx[$fptr]; $b = $fenceIdx[$fptr + 1]
                            if ($b - $a -le 1) { $fptr += 1; continue }   # empty block (adjacent fences / stray rules)
                            $blockLines = $allLines[($a + 1)..($b - 1)]
                            $kv       = @($blockLines | Where-Object { $_ -match '^[A-Za-z_][A-Za-z0-9_]*:\s' })
                            $nonblank = @($blockLines | Where-Object { $_.Trim() -ne '' })
                            # Frontmatter-shaped block = majority key:value lines (a horizontal-rule
                            # pair with prose between fails this and advances by one, keeping alignment).
                            if ($nonblank.Count -gt 0 -and $kv.Count -ge [Math]::Max(2, $nonblank.Count * 0.6)) {
                                $bodyType = $null; $bodyCat = $null
                                foreach ($bl in $blockLines) {
                                    if ($bl -match '^type:\s*(.+?)\s*$')        { $bodyType = $Matches[1] }
                                    elseif ($bl -match '^category:\s*(.+?)\s*$') { $bodyCat  = $Matches[1] }
                                }
                                if ($declType -and $bodyType -and $bodyType -notmatch '\[' -and $bodyType -ne $declType) {
                                    Add-CheckResult "ERROR" "MetadataSchema" $relPath "Emitted body 'type: $bodyType' contradicts declared creates_document_type '$declType'"
                                    $fileHasViolation = $true
                                }
                                if ($declCat -and $bodyCat -and $bodyCat -notmatch '\[' -and $bodyCat -ne $declCat) {
                                    Add-CheckResult "ERROR" "MetadataSchema" $relPath "Emitted body 'category: $bodyCat' contradicts declared creates_document_category '$declCat'"
                                    $fileHasViolation = $true
                                }
                                $fptr += 2
                            } else {
                                $fptr += 1
                            }
                        }
                    }

                    if ($fileHasViolation) {
                        $violationFiles++
                    } else {
                        $conformingFiles++
                        Add-CheckResult "OK" "MetadataSchema" $relPath "Conforms to $artifactType schema"
                    }
                }
            }

            Set-SurfaceExamined "MetadataSchema" $totalFiles
            Write-Host "  Scanned $totalFiles files: $conformingFiles conforming, $violationFiles with violations" -ForegroundColor Gray

            # Unknown-field reconciliation summary (PF-IMP-1750). Each (artifact_type, field) pair
            # is one Declare-vs-Fix decision, and occurrence count is only a weak proxy for it:
            # residue left behind by an incomplete fleet-wide removal reads as a consistent
            # multi-file cluster and so argues Declare by count while being a Fix (guide_title sat
            # in 5 guides with no emitter, retired fleet-wide months earlier). The deciding signals
            # are structural — the variant_group family the carrying files belong to, and whether a
            # creation script emits the field — so they are computed here instead of being
            # reconstructed by hand per cluster. Detail-gated: the per-file findings above are
            # -DetailOnly, so this rides the same -Detailed run the schema-audit procedure runs.
            if ($Detailed -and $unknownFieldIndex.Count -gt 0) {
                # Emitter index: a creation script emits a field when it names it as a quoted
                # literal ($meta["field"] = ...) or a bare hashtable key (@{ field = ... }).
                # Whole-line comments are dropped first so a field merely discussed in a comment
                # does not read as an emitter — that false positive would argue Declare for exactly
                # the residue this summary exists to catch. Trailing comments are left intact
                # (stripping them would truncate strings containing '#').
                $emitterMap = @{}
                $creationDirMS = Join-Path $fwDirMS 'scripts/file-creation'
                if (Test-Path $creationDirMS) {
                    $ufFields = @($unknownFieldIndex.Values | Select-Object -ExpandProperty Field -Unique)
                    foreach ($csFile in (Get-ChildItem -Path $creationDirMS -Filter '*.ps1' -Recurse -File)) {
                        $csCode = (Get-Content $csFile.FullName | Where-Object { $_ -notmatch '^\s*#' }) -join "`n"
                        foreach ($ufField in $ufFields) {
                            $ufEsc = [regex]::Escape($ufField)
                            $quotedPat = '([''"])' + $ufEsc + '\1'
                            $keyPat    = '(?m)^\s*' + $ufEsc + '\s*='
                            if ($csCode -match $quotedPat -or $csCode -match $keyPat) {
                                if (-not $emitterMap.ContainsKey($ufField)) {
                                    $emitterMap[$ufField] = [System.Collections.Generic.List[string]]::new()
                                }
                                if ($csFile.Name -notin $emitterMap[$ufField]) { $emitterMap[$ufField].Add($csFile.Name) }
                            }
                        }
                    }
                }

                Write-Host "  Unknown-field reconciliation (Declare/Fix evidence - see schema-audit-procedure-guide.md):" -ForegroundColor Gray
                foreach ($ufKeySorted in ($unknownFieldIndex.Keys | Sort-Object)) {
                    $e = $unknownFieldIndex[$ufKeySorted]
                    $famText = if ($e.Families.Count -gt 0) { $e.Families -join ', ' } else { '-' }
                    $emitText = if ($emitterMap.ContainsKey($e.Field)) { $emitterMap[$e.Field] -join ', ' } else { '-' }
                    $verdict =
                        if ($emitText -ne '-') { 'Declare (script emits it)' }
                        elseif ($e.Families.Count -eq 1 -and $e.NoFamilyCount -eq 0) { 'Declare (coheres with one family)' }
                        elseif ($e.Families.Count -eq 0) { 'Fix (no emitter, no family - residue candidate)' }
                        else { 'review (carriers disagree - mixed or multi-family)' }
                    Write-Host ("    {0,-8} {1,-26} {2,3} file(s)  family: {3}  emitter: {4}  -> {5}" -f `
                        $e.ArtifactType, $e.Field, $e.Count, $famText, $emitText, $verdict) -ForegroundColor Gray
                }
            }
        }
    }
    Write-Host ""
}

# Surface 12 (AI Tasks Consistency) RETIRED — PF-IMP-1210 / PF-PRO-049. See the Surface 9/12
# retirement note above; both are superseded by `Build-TaskMetadata.ps1 -Check`.

# =========================================================================
# Surface 13: Master State Consistency (IMP-004)
# =========================================================================
if ($runAll -or $Surface -contains "MasterStateConsistency") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 13: Master State Consistency" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # Find retrospective master state files in temporary and archived directories
    $masterStateFiles = @()
    $tempDir = Join-Path $ProjectRoot "doc/state-tracking/temporary"
    $archivedDir = Join-Path $ProjectRoot "doc/state-tracking/temporary/archived"
    foreach ($dir in @($tempDir, $archivedDir)) {
        if (Test-Path $dir) {
            $found = Get-ChildItem -Path $dir -Filter "retrospective-master-state*.md" -File -ErrorAction SilentlyContinue
            if ($found) { $masterStateFiles += $found }
        }
    }

    if ($masterStateFiles.Count -eq 0) {
        # PF-IMP-1209 (A-1/A-2): "examined nothing" must not read as a clean OK pass. Standardize the
        # empty-instance case to WARNING (matching Surfaces 2 and 10) so the absence is visible.
        Add-CheckResult "WARNING" "MasterStateConsistency" "Search" "No retrospective master state files found — surface examined 0 instances (coverage gap, not a clean pass)"
    } else {
        foreach ($msFile in $masterStateFiles) {
            $msName = $msFile.Name
            $msLines = Get-Content $msFile.FullName -Encoding UTF8
            Write-Host "  Validating: $msName" -ForegroundColor Gray

            # --- Parse Feature Inventory tables ---
            # Collect status per column across all category tables
            $inInventory = $false
            $inventoryHeaders = @()
            $featureRows = @()

            for ($i = 0; $i -lt $msLines.Count; $i++) {
                $line = $msLines[$i]

                # Detect Feature Inventory section
                if ($line -match '^## Feature Inventory') {
                    $inInventory = $true
                    continue
                }
                # Stop at next top-level section
                if ($inInventory -and $line -match '^## [^F]') {
                    $inInventory = $false
                    continue
                }
                if (-not $inInventory) { continue }

                # Detect category table headers
                if ($line -match '^\|\s*Feature ID\s*\|') {
                    # Parse header columns
                    $inventoryHeaders = ($line -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                    continue
                }
                # Skip separator rows
                if ($line -match '^\|\s*[-:]+\s*\|') { continue }
                # Skip non-table lines
                if ($line -notmatch '^\|') { continue }

                # Parse data row
                $cells = ($line -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                if ($cells.Count -ge 2 -and $cells[0] -match '^\d+\.\d+\.\d+') {
                    $row = @{}
                    for ($c = 0; $c -lt [Math]::Min($cells.Count, $inventoryHeaders.Count); $c++) {
                        $row[$inventoryHeaders[$c]] = $cells[$c]
                    }
                    $featureRows += $row
                }
            }

            if ($featureRows.Count -eq 0) {
                Add-CheckResult "WARNING" "MasterStateConsistency" $msName "No feature rows found in Feature Inventory"
                continue
            }

            $totalFeatures = $featureRows.Count
            Set-SurfaceExamined "MasterStateConsistency" $totalFeatures
            Write-Host "  Found $totalFeatures features in inventory" -ForegroundColor Gray

            # --- Helper: count statuses in a column ---
            function Get-StatusCounts {
                param([string]$ColumnName)
                $complete = 0; $inProgress = 0; $notStarted = 0; $na = 0
                foreach ($row in $featureRows) {
                    $val = $row[$ColumnName]
                    if ($null -eq $val -or $val -eq '') { $notStarted++; continue }
                    if ($val -match 'N/A') { $na++; continue }
                    if ($val -match '✅') { $complete++ }
                    elseif ($val -match '🟡') { $inProgress++ }
                    elseif ($val -match '⬜') { $notStarted++ }
                    else { $complete++ }  # Assume non-emoji non-NA content means done (e.g. tier text)
                }
                return @{ Complete = $complete; InProgress = $inProgress; NotStarted = $notStarted; NA = $na }
            }

            # --- Validate Phase Completion Checkboxes ---
            # Phase 1 = Impl State column all ✅
            # Phase 2 = Analyzed column all ✅
            # Phase 3 = Assessed column all ✅
            $phaseColumnMap = @{
                1 = "Impl State"
                2 = "Analyzed"
                3 = "Assessed"
            }

            foreach ($phase in 1..3) {
                $colName = $phaseColumnMap[$phase]
                $counts = Get-StatusCounts -ColumnName $colName

                $allComplete = ($counts.Complete -eq ($totalFeatures - $counts.NA)) -and $counts.NotStarted -eq 0 -and $counts.InProgress -eq 0

                # Find the checkbox line for this phase
                $checkboxLine = $msLines | Where-Object { $_ -match "Phase $phase" -and $_ -match '^\s*-\s*\[' } | Select-Object -First 1
                if ($null -eq $checkboxLine) { continue }

                $isChecked = $checkboxLine -match '^\s*-\s*\[x\]'

                if ($allComplete -and -not $isChecked) {
                    Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/Phase $phase checkbox" "All $($counts.Complete) features complete in '$colName' but checkbox is unchecked"
                } elseif (-not $allComplete -and $isChecked) {
                    Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/Phase $phase checkbox" "Checkbox is checked but inventory shows $($counts.NotStarted) not started, $($counts.InProgress) in progress"
                } else {
                    Add-CheckResult "OK" "MasterStateConsistency" "$msName/Phase $phase checkbox" "Checkbox matches inventory ($($counts.Complete) complete)"
                }
            }

            # Phase 4 — check if status header says COMPLETE
            $phase4Line = $msLines | Where-Object { $_ -match 'Phase 4' -and $_ -match '^\s*-\s*\[' } | Select-Object -First 1
            if ($null -ne $phase4Line) {
                $p4Checked = $phase4Line -match '^\s*-\s*\[x\]'
                $statusLine = $msLines | Where-Object { $_ -match '^\*\*Status\*\*:' } | Select-Object -First 1
                $isComplete = $statusLine -match 'COMPLETE'
                if ($p4Checked -and -not $isComplete) {
                    Add-CheckResult "WARNING" "MasterStateConsistency" "$msName/Phase 4 checkbox" "Checked but Status header does not say COMPLETE"
                } elseif (-not $p4Checked -and $isComplete) {
                    Add-CheckResult "WARNING" "MasterStateConsistency" "$msName/Phase 4 checkbox" "Status says COMPLETE but Phase 4 checkbox unchecked"
                } else {
                    Add-CheckResult "OK" "MasterStateConsistency" "$msName/Phase 4 checkbox" "Consistent with Status header"
                }
            }

            # --- Validate Feature Progress Overview counters ---
            $progressTableLines = @()
            $inProgressTable = $false
            foreach ($line in $msLines) {
                if ($line -match '^\|\s*Phase\s*\|.*Not Started') { $inProgressTable = $true }
                if ($inProgressTable) {
                    if ($line -match '^\|') {
                        $progressTableLines += $line
                    } elseif ($progressTableLines.Count -gt 0) {
                        break
                    }
                }
            }

            $phaseProgressMap = @{
                "Phase 1" = "Impl State"
                "Phase 2" = "Analyzed"
                "Phase 3" = "Assessed"
            }

            foreach ($pLine in $progressTableLines) {
                # Skip header and separator
                if ($pLine -match 'Not Started' -or $pLine -match '^\|\s*[-:]+') { continue }

                $pCells = ($pLine -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                if ($pCells.Count -lt 4) { continue }

                $phaseName = $pCells[0] -replace '^\s*Phase\s+\d+:\s*', '' -replace '\s*$', ''
                $statedNotStarted = [int]($pCells[1] -replace '[^\d]', '')
                $statedInProgress = [int]($pCells[2] -replace '[^\d]', '')
                $statedComplete = [int]($pCells[3] -replace '[^\d]', '')

                # Determine which phase this is
                $matchedCol = $null
                foreach ($key in $phaseProgressMap.Keys) {
                    if ($pCells[0] -match $key.Replace("Phase ", "Phase\s+")) {
                        $matchedCol = $phaseProgressMap[$key]
                        break
                    }
                }
                if ($null -eq $matchedCol) { continue }

                $actual = Get-StatusCounts -ColumnName $matchedCol
                $actualApplicable = $totalFeatures - $actual.NA

                $mismatch = $false
                $details = @()
                if ($statedNotStarted -ne $actual.NotStarted) {
                    $mismatch = $true
                    $details += "NotStarted: stated=$statedNotStarted actual=$($actual.NotStarted)"
                }
                if ($statedInProgress -ne $actual.InProgress) {
                    $mismatch = $true
                    $details += "InProgress: stated=$statedInProgress actual=$($actual.InProgress)"
                }
                if ($statedComplete -ne $actual.Complete) {
                    $mismatch = $true
                    $details += "Complete: stated=$statedComplete actual=$($actual.Complete)"
                }

                if ($mismatch) {
                    Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/Progress/$matchedCol" "Counter mismatch: $($details -join ', ')"
                } else {
                    Add-CheckResult "OK" "MasterStateConsistency" "$msName/Progress/$matchedCol" "Counters match ($statedComplete complete, $statedNotStarted not started, $statedInProgress in progress)"
                }
            }

            # --- Validate Documentation Requirements Summary ---
            # Validates feature count and per-column "features needing" counts.
            # Note: ADR counts in the summary may exceed inventory ✅ count because
            # a single feature can have multiple ADRs (e.g., ✅ with "3/3" in summary).
            # We validate the "needed" denominator (features requiring that doc type)
            # against the inventory's non-N/A count for FDD, TDD, Test Spec.
            $docSummaryLines = @()
            $inDocSummary = $false
            foreach ($line in $msLines) {
                if ($line -match '^\|\s*Tier\s*\|.*Feature Count') { $inDocSummary = $true }
                if ($inDocSummary) {
                    if ($line -match '^\|') {
                        $docSummaryLines += $line
                    } elseif ($docSummaryLines.Count -gt 0) {
                        break
                    }
                }
            }

            # Count features needing each doc type from inventory (non-N/A entries)
            $docColumns = @("FDD", "TDD", "Test Spec")
            $actualDocCounts = @{}
            foreach ($col in $docColumns) {
                $counts = Get-StatusCounts -ColumnName $col
                $actualDocCounts[$col] = @{
                    Created = $counts.Complete
                    Needed = $counts.Complete + $counts.InProgress + $counts.NotStarted
                }
            }

            # Parse the Total row from Documentation Requirements Summary
            $totalRow = $docSummaryLines | Where-Object { $_ -match '\*\*Total\*\*' } | Select-Object -First 1
            if ($null -ne $totalRow) {
                $totalCells = ($totalRow -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                # Header: Tier | Feature Count | Impl State | FDD Needed | TDD Needed | Test Spec | ADR | Total Docs Needed | Docs Created

                # Check feature count
                $statedFeatureCount = $totalCells[1] -replace '[^\d]', ''
                if ($statedFeatureCount -and [int]$statedFeatureCount -ne $totalFeatures) {
                    Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/DocSummary/FeatureCount" "Stated $statedFeatureCount features but inventory has $totalFeatures"
                } else {
                    Add-CheckResult "OK" "MasterStateConsistency" "$msName/DocSummary/FeatureCount" "Feature count matches ($totalFeatures)"
                }

                # Per-column validation: FDD (index 3), TDD (index 4), Test Spec (index 5)
                # These columns use "x/y" format where y = features needing, x = features with docs created
                $colIndexMap = @{ "FDD" = 3; "TDD" = 4; "Test Spec" = 5 }
                foreach ($col in $docColumns) {
                    $idx = $colIndexMap[$col]
                    if ($totalCells.Count -le $idx) { continue }
                    $cellVal = $totalCells[$idx]

                    # Parse "x/y" or "**x/y**" format
                    if ($cellVal -match '(\d+)\s*/\s*(\d+)') {
                        $statedCreated = [int]$matches[1]
                        $statedNeeded = [int]$matches[2]
                        $actualNeeded = $actualDocCounts[$col].Needed
                        $actualCreated = $actualDocCounts[$col].Created

                        $mismatch = $false
                        $details = @()
                        if ($statedNeeded -ne $actualNeeded) {
                            $mismatch = $true
                            $details += "needed: stated=$statedNeeded actual=$actualNeeded"
                        }
                        if ($statedCreated -ne $actualCreated) {
                            $mismatch = $true
                            $details += "created: stated=$statedCreated actual=$actualCreated"
                        }

                        if ($mismatch) {
                            Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/DocSummary/$col" "Mismatch: $($details -join ', ')"
                        } else {
                            Add-CheckResult "OK" "MasterStateConsistency" "$msName/DocSummary/$col" "$col counts match ($statedCreated/$statedNeeded)"
                        }
                    }
                }

                # Impl State column (index 2) — validate "x/y" against inventory
                if ($totalCells.Count -gt 2) {
                    $implCell = $totalCells[2]
                    if ($implCell -match '(\d+)\s*/\s*(\d+)') {
                        $statedImplCreated = [int]$matches[1]
                        $statedImplNeeded = [int]$matches[2]
                        $implCounts = Get-StatusCounts -ColumnName "Impl State"
                        if ($statedImplNeeded -ne $totalFeatures) {
                            Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/DocSummary/ImplState" "Stated $statedImplNeeded needed but inventory has $totalFeatures features"
                        } elseif ($statedImplCreated -ne $implCounts.Complete) {
                            Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/DocSummary/ImplState" "Stated $statedImplCreated created but inventory shows $($implCounts.Complete) complete"
                        } else {
                            Add-CheckResult "OK" "MasterStateConsistency" "$msName/DocSummary/ImplState" "Impl State counts match ($statedImplCreated/$statedImplNeeded)"
                        }
                    }
                }
            } elseif ($docSummaryLines.Count -gt 0) {
                Add-CheckResult "WARNING" "MasterStateConsistency" "$msName/DocSummary" "Documentation Requirements Summary found but no Total row"
            }
        }
    }
    Write-Host ""
}

# =========================================================================
# Surface 14: Source Layout — compare layout doc directory tree vs actual source dirs
# =========================================================================
if ($runAll -or $Surface -contains "SourceLayout") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 14: Source Layout" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $layoutDocPath = Join-Path $ProjectRoot "doc/technical/architecture/source-code-layout.md"

    if (-not (Test-Path $layoutDocPath)) {
        Add-CheckResult "OK" "SourceLayout" "Search" "No source-code-layout.md found — nothing to validate"
    } else {
        # Read project-config.json for source root
        $sourceCodePath = $null
        if (Test-Path $projectConfigPath) {
            try {
                $pcfg = Get-Content $projectConfigPath -Raw | ConvertFrom-Json
                $sourceCodePath = $pcfg.paths.source_code
            } catch {}
        }

        if ([string]::IsNullOrWhiteSpace($sourceCodePath) -or $sourceCodePath -eq ".") {
            Add-CheckResult "WARNING" "SourceLayout" "project-config.json" "paths.source_code is not set or is '.'"
        } else {
            $sourceRootAbs = Join-Path $ProjectRoot $sourceCodePath

            if (-not (Test-Path $sourceRootAbs)) {
                Add-CheckResult "ERROR" "SourceLayout" "SourceRoot" "Source root '$sourceCodePath' does not exist on disk but source-code-layout.md exists"
            } else {
                # Parse directory tree from layout doc — extract directory names from the code block
                $layoutContent = Get-Content $layoutDocPath -Raw
                $docDirs = @()

                if ($layoutContent -match '(?s)## Directory Tree.*?```\s*\n[^\n]+/\n([\s\S]*?)```') {
                    $treeBlock = $Matches[1]
                    # Extract top-level directories (2 spaces indent = direct child of source root)
                    foreach ($line in ($treeBlock -split "`n")) {
                        if ($line -match '^  ([a-zA-Z0-9_\-]+)/$') {
                            $docDirs += $Matches[1]
                        }
                    }
                }

                # Get actual directories on disk
                $actualDirs = @()
                if (Test-Path $sourceRootAbs) {
                    # Skip runtime/cache artifacts — shared exclusion via the canonical
                    # Get-NonFeatureTestDir helper so this source-tree filter cannot diverge
                    # from the test-tree surfaces / New-TestInfrastructure.ps1 (PF-IMP-1152).
                    $runtimeCacheDirs = Get-NonFeatureTestDir -Scope RuntimeCache
                    $actualDirs = Get-ChildItem -Path $sourceRootAbs -Directory |
                        Where-Object { $runtimeCacheDirs -notcontains $_.Name } |
                        ForEach-Object { $_.Name }
                }

                if ($docDirs.Count -eq 0 -and $actualDirs.Count -eq 0) {
                    Add-CheckResult "OK" "SourceLayout" "DirTree" "Both layout doc and disk are empty"
                } elseif ($docDirs.Count -eq 0) {
                    Add-CheckResult "WARNING" "SourceLayout" "DirTree" "No directory tree found in layout doc but $($actualDirs.Count) directories exist on disk — run New-SourceStructure.ps1 -Update"
                } else {
                    # Compare: directories in doc but not on disk
                    $missingOnDisk = $docDirs | Where-Object { $_ -notin $actualDirs }
                    foreach ($d in $missingOnDisk) {
                        Add-CheckResult "ERROR" "SourceLayout" "DirTree/$d" "Listed in layout doc but missing from disk"
                    }

                    # Compare: directories on disk but not in doc
                    $missingInDoc = $actualDirs | Where-Object { $_ -notin $docDirs }
                    foreach ($d in $missingInDoc) {
                        Add-CheckResult "ERROR" "SourceLayout" "DirTree/$d" "Exists on disk but not in layout doc — run New-SourceStructure.ps1 -Update"
                    }

                    # All matching
                    $matching = $docDirs | Where-Object { $_ -in $actualDirs }
                    foreach ($d in $matching) {
                        Add-CheckResult "OK" "SourceLayout" "DirTree/$d" "Consistent between doc and disk"
                    }
                }

                # Check naming convention compliance
                if (Test-Path $projectConfigPath) {
                    try {
                        $lang = $pcfg.testing.language.ToLower()
                        $lcPath = Join-Path (Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot) "languages-config/$lang/$lang-config.json"
                        if (Test-Path $lcPath) {
                            $lc = Get-Content $lcPath -Raw | ConvertFrom-Json
                            $namingConvention = $lc.directoryStructure.directoryNaming
                            if ($namingConvention) {
                                foreach ($d in $actualDirs) {
                                    $valid = switch ($namingConvention) {
                                        "snake_case" { $d -cmatch '^[a-z][a-z0-9_]*$' }
                                        "kebab-case" { $d -cmatch '^[a-z][a-z0-9\-]*$' }
                                        "PascalCase" { $d -cmatch '^[A-Z][a-zA-Z0-9]*$' }
                                        default { $true }
                                    }
                                    if (-not $valid) {
                                        Add-CheckResult "WARNING" "SourceLayout" "Naming/$d" "Directory '$d' does not match $namingConvention convention"
                                    } else {
                                        Add-CheckResult "OK" "SourceLayout" "Naming/$d" "Matches $namingConvention convention"
                                    }
                                }
                            }
                        }
                    } catch {
                        # Naming check is best-effort
                    }
                }
            }
        }
    }
    Write-Host ""
}

# =========================================================================
# Surface 15: Test Status Aggregation Consistency
# =========================================================================
# Cross-checks per-feature aggregated test statuses from test-tracking.md
# against the Test Status column in feature-tracking.md. Catches split-brain
# states (e.g. 0.1.2 on 2026-04-17 had test-tracking ✅ Audit Approved but
# feature-tracking 🔄 Tests Need Update for ~2 weeks).
#
# Mirrors aggregation logic from Update-TestFileAuditState.ps1 (~lines 595-612).
# 🔴 Needs Fix rows in test-tracking (emitted by Run-Tests.python.ps1 when pytest
# reports failures/errors — distinct from this aggregator's own "🔴 Audit Failed"
# rows) also aggregate to "🔴 Some Failing"; PF-IMP-765 aligned the updater to
# treat both as failing too.
#
# Post-SC-027: both writers and legend use the unified feature-tracking.md
# legend vocabulary, so comparison is direct string equality (no canonical-
# group mapping needed).
# =========================================================================
if ($runAll -or $Surface -contains "TestStatusAggregation") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 15: Test Status Aggregation Consistency" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $ttPath = Join-Path $ProjectRoot "test/state-tracking/permanent/test-tracking.md"
    $ftPath = Join-Path $ProjectRoot "doc/state-tracking/permanent/feature-tracking.md"

    if (-not (Test-Path $ttPath)) {
        Add-CheckResult "ERROR" "TestStatusAggregation" "test-tracking.md" "File not found: $ttPath"
    } elseif (-not (Test-Path $ftPath)) {
        # feature-tracking.md is a product tracker: absent in a non-project workspace it rates
        # the WARNING branch of the Add-AbsentTargetResult policy (PF-IMP-1957; role-based per
        # PF-PRO-067); test-tracking.md above stays ERROR everywhere — a test tree without its
        # tracker is a defect in any workspace.
        $absentLevel = if ($script:workspaceRole -ne 'project') { "WARNING" } else { "ERROR" }
        Add-AbsentTargetResult $absentLevel "TestStatusAggregation" "feature-tracking.md" "feature-tracking.md not found ($ftPath)"
    } else {
        # Valid feature-tracking.md Test Status legend values (SC-027 unified legend)
        $validStatuses = @(
            '⬜ No Tests',
            '🚫 No Test Required',
            '📋 Specs Created',
            '🟡 In Progress',
            '🔍 Audit In Progress',
            '🟡 Tests Partially Approved',
            '✅ All Passing',
            '🔴 Some Failing',
            '🔧 Automated Only',
            '🔄 Re-testing Needed'
        )

        # Normalize a status string by collapsing whitespace, for robust comparison
        function Get-NormalizedStatus {
            param([string]$Status)
            return ($Status -replace '\s+', ' ').Trim()
        }

        # Extract the leading symbol token (everything up to first whitespace).
        # Cells often contain just the emoji (e.g. '⬜') rather than the full
        # canonical form ('⬜ No Tests') because the legend table renders symbol
        # and status name in separate columns. PF-IMP-038.
        function Get-StatusSymbol {
            param([string]$Status)
            $norm = Get-NormalizedStatus $Status
            if ($norm -match '^(\S+)') { return $Matches[1] }
            return $norm
        }

        # Status equality that tolerates bare-symbol cells. Full-text on both
        # sides → strict comparison (preserves PF-IMP-037-style detection of
        # 🟡 In Progress vs 🟡 Tests Partially Approved). If either side is a
        # bare symbol → compare on symbol only.
        function Test-StatusMatch {
            param([string]$Actual, [string]$Expected)
            $a = Get-NormalizedStatus $Actual
            $e = Get-NormalizedStatus $Expected
            if ($a -eq $e) { return $true }
            $aSym = Get-StatusSymbol $a
            $eSym = Get-StatusSymbol $e
            if ($a -eq $aSym -or $e -eq $eSym) { return $aSym -eq $eSym }
            return $false
        }

        $validSymbols = @($validStatuses | ForEach-Object { Get-StatusSymbol $_ } | Select-Object -Unique)

        # Aggregate test-tracking statuses for one feature into a single
        # feature-tracking legend value (emits SC-027 vocabulary). Mirrors
        # Update-TestFileAuditState.ps1 with the 🔴 Needs Fix extension noted above.
        function Get-AggregatedTestStatus {
            param([string[]]$Statuses)
            if ($null -eq $Statuses -or $Statuses.Count -eq 0) { return "⬜ No Tests" }
            if (@($Statuses | Where-Object { $_ -match '🔴\s*(Audit\s*Failed|Needs\s*Fix)' }).Count -gt 0) { return "🔴 Some Failing" }
            if (@($Statuses | Where-Object { $_ -match '🔄\s*Needs\s*Update' }).Count -gt 0)               { return "🔄 Re-testing Needed" }
            if (@($Statuses | Where-Object { $_ -match '🔍\s*Audit\s*In\s*Progress' }).Count -gt 0)        { return "🔍 Audit In Progress" }
            # All entries are 📝 Needs Implementation (specs created, no impl started) → 📋 Specs Created.
            # PF-IMP-037: test-tracking 📝 Needs Implementation == feature-tracking 📋 Specs Created semantically.
            $needsImpl = @($Statuses | Where-Object { $_ -match '📝\s*Needs\s*Implementation' })
            if ($needsImpl.Count -eq $Statuses.Count) { return "📋 Specs Created" }
            $approved = @($Statuses | Where-Object { $_ -match '^✅\s*Audit\s*Approved' })
            if ($approved.Count -eq 0)                  { return "🟡 In Progress" }
            if ($approved.Count -eq $Statuses.Count)    { return "✅ All Passing" }
            return "🟡 Tests Partially Approved"
        }

        # --- Step 1: Build per-feature test-status map from test-tracking.md ---
        $testStatusByFeature = @{}
        $ttLines = Get-Content $ttPath -Encoding UTF8
        foreach ($line in $ttLines) {
            if ($line -notmatch '^\|') { continue }
            $cols = $line -split '\|' | ForEach-Object { $_.Trim() }
            # 8-col format: | "" | Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
            if ($cols.Count -lt 6) { continue }
            $featureId = $cols[1]
            # Skip header, separator, and infrastructure rows (Feature ID = "—" or "Feature ID")
            if ($featureId -notmatch '^\d+\.\d+\.\d+$') { continue }
            $status = $cols[4]
            if (-not $testStatusByFeature.ContainsKey($featureId)) {
                $testStatusByFeature[$featureId] = @()
            }
            $testStatusByFeature[$featureId] += $status
        }

        # --- Step 2: Walk feature-tracking.md feature rows and compare ---
        # Test Status column index is resolved by HEADER NAME, not hardcoded
        # position — schema-resilient against PF-PRO-002 column drops (the
        # post-Phase-3 schema is 8 cols; pre-Phase-3 was 11). The most recent
        # header row above each data row defines the column map for that row.
        $ftLines = Get-Content $ftPath -Encoding UTF8
        $checked = 0
        $testStatusIdx = -1
        foreach ($line in $ftLines) {
            # Update the Test Status column index whenever we hit a category-table
            # header row. Header pattern: "| ID | Feature | Status | ... |"
            if ($line -match '^\|\s*ID\s*\|') {
                $headerCols = $line -split '\|' | ForEach-Object { $_.Trim() }
                $testStatusIdx = -1
                for ($k = 0; $k -lt $headerCols.Count; $k++) {
                    if ($headerCols[$k] -eq 'Test Status') { $testStatusIdx = $k; break }
                }
                continue
            }
            # Feature rows: | [X.X.X](path) | Feature | Status | Priority | Doc Tier | Test Status | Dependencies | Notes |
            # (post-Phase-3 schema; was 11 cols pre-Phase-3 with FDD/TDD/Test Spec inserted)
            if ($line -notmatch '^\|\s*\[\d+\.\d+\.\d+\]') { continue }
            $cols = $line -split '\|' | ForEach-Object { $_.Trim() }
            # Skip rows where we haven't yet seen a header (defensive)
            if ($testStatusIdx -lt 0) { continue }
            if ($cols.Count -le $testStatusIdx) { continue }
            if ($cols[1] -notmatch '\[(\d+\.\d+\.\d+)\]') { continue }
            $featureId = $Matches[1]
            $actualStatus = $cols[$testStatusIdx]
            # Skip archived rows (empty Test Status)
            if ([string]::IsNullOrWhiteSpace($actualStatus) -or $actualStatus -eq '—') { continue }

            $actualNorm = Get-NormalizedStatus $actualStatus
            $actualSymbol = Get-StatusSymbol $actualNorm

            # Skip manually-designated 🚫 No Test Required (exempt from aggregation check)
            if (Test-StatusMatch $actualNorm '🚫 No Test Required') {
                Add-CheckResult "OK" "TestStatusAggregation" $featureId "Manually marked 🚫 No Test Required (skipped)"
                continue
            }

            $featureStatuses = if ($testStatusByFeature.ContainsKey($featureId)) { $testStatusByFeature[$featureId] } else { @() }
            $expectedStatus = Get-AggregatedTestStatus -Statuses $featureStatuses
            $expectedNorm = Get-NormalizedStatus $expectedStatus

            $checked++

            # Unknown actual status is a warning (hand-typed value not in legend).
            # Accept either the canonical full form ('⬜ No Tests') or the bare
            # symbol ('⬜') since cells in feature-tracking.md commonly use either.
            if ($actualNorm -notin $validStatuses -and $actualSymbol -notin $validSymbols) {
                Add-CheckResult "WARNING" "TestStatusAggregation" $featureId "Test Status '$actualStatus' not in legend — review for typo or update SC-027 legend"
                continue
            }

            # 🔧 Automated Only actual is consistent with ✅ All Passing expected (manual flag intent)
            if ((Test-StatusMatch $actualNorm '🔧 Automated Only') -and (Test-StatusMatch $expectedNorm '✅ All Passing')) {
                Add-CheckResult "OK" "TestStatusAggregation" $featureId "🔧 Automated Only consistent with all-passing aggregate"
                continue
            }

            # Orphan claim: feature claims ✅ All Passing but no test-tracking rows exist
            if ((Test-StatusMatch $actualNorm '✅ All Passing') -and $featureStatuses.Count -eq 0) {
                Add-CheckResult "ERROR" "TestStatusAggregation" $featureId "Feature claims '$actualStatus' but test-tracking.md has no entries for this feature"
                continue
            }

            if (-not (Test-StatusMatch $actualNorm $expectedNorm)) {
                $statusSummary = if ($featureStatuses.Count -gt 0) {
                    ($featureStatuses | Group-Object | ForEach-Object { "$($_.Name) (x$($_.Count))" }) -join ", "
                } else { "no test entries" }
                Add-CheckResult "ERROR" "TestStatusAggregation" $featureId "Mismatch — feature-tracking shows '$actualStatus' but test-tracking aggregates to '$expectedStatus'. Underlying: $statusSummary"
            } else {
                Add-CheckResult "OK" "TestStatusAggregation" $featureId "Test status consistent ($actualNorm)"
            }
        }

        Set-SurfaceExamined "TestStatusAggregation" $checked
        Write-Host "  Checked $checked feature(s)" -ForegroundColor Gray
    }
    Write-Host ""
}

# =========================================================================
# Surfaces 16/17/18 — Test & Audit Infrastructure Invariants (PF-IMP-871 Phase 4a)
# =========================================================================
# Three related surfaces that enforce the test/audit tree's structural contract:
#
#   - Surface 16 (AuditMirror)       : every test dir has a corresponding audit dir
#                                      (and vice versa) under the path-transform rule
#                                      established in PF-IMP-871 Phase 3a.
#   - Surface 17 (CategoryAlignment) : every level-1 category and level-2 subgroup in
#                                      feature-tracking.md has a matching unit-test
#                                      dir under `test/automated/unit/`.
#   - Surface 18 (WorkflowAlignment) : every WF-NNN row in user-workflow-tracking.md
#                                      has a matching e2e dir under
#                                      `test/e2e-acceptance-testing/`.
#
# All three share the same project_id-aware test-root resolution (PRJ-000 → blueprint/
# test/; otherwise → test/) and the same feature-tracking / workflow-tracking parsers
# (defined inline below; logic adapted from New-TestInfrastructure.ps1 Phase 3a/3c1).
# =========================================================================

# --- Shared helper: resolve test_root and tracking-file paths from project-config.json ---
function Get-TestAuditContext {
    param([string]$ProjectRoot)

    $projectConfigPath = Join-Path $ProjectRoot "doc/project-config.json"
    $projectId = ""
    $testsRel  = "test"
    $docRel    = "doc"
    if (Test-Path $projectConfigPath) {
        try {
            $cfg = Get-Content $projectConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json
            if ($cfg.PSObject.Properties.Name -contains 'project_id') {
                $projectId = $cfg.project_id
            }
            if ($cfg.paths) {
                if ($cfg.paths.tests)              { $testsRel = $cfg.paths.tests }
                if ($cfg.paths.documentation_root) { $docRel   = $cfg.paths.documentation_root }
            }
        } catch {
            Write-Verbose "Could not parse project-config.json: $($_.Exception.Message)"
        }
    }

    # Refactored 2026-05-17 (Framework Self-Testing PF-PRO-035, Phase 3a-continuation) — replaced
    # PRJ-000 → blueprint/* hardcoding with config-driven lookup (paths.tests + paths.documentation_root).
    # See Resolve-DocPath in Common-ScriptHelpers/Core.psm1 for the parallel refactor.
    $testRoot = Join-Path $ProjectRoot $testsRel
    $ftPath   = Join-Path $ProjectRoot (Join-Path $docRel "state-tracking/permanent/feature-tracking.md")
    $wfPath   = Join-Path $ProjectRoot (Join-Path $docRel "state-tracking/permanent/user-workflow-tracking.md")

    return [PSCustomObject]@{
        ProjectId            = $projectId
        TestRoot             = $testRoot
        FeatureTrackingPath  = $ftPath
        WorkflowTrackingPath = $wfPath
    }
}

# --- Shared parser: feature-tracking.md categories (adapted from New-TestInfrastructure.ps1 Phase 3a) ---
function Get-ParsedFeatureCategories {
    param([string]$Path)
    if ([string]::IsNullOrEmpty($Path) -or -not (Test-Path $Path)) { return @() }
    $content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content)) { return @() }
    $lines = $content -split "`r?`n"

    $startIdx = -1; $endIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## Feature Categories\s*$') { $startIdx = $i }
        elseif ($lines[$i] -match '^## Archived Features\s*$' -and $startIdx -ge 0) { $endIdx = $i; break }
    }
    if ($startIdx -lt 0) { return @() }
    if ($endIdx -lt 0) { $endIdx = $lines.Count }

    $results = @(); $inCategory = $false; $currentCatId = $null
    for ($i = $startIdx; $i -lt $endIdx; $i++) {
        $line = $lines[$i]
        if (-not $inCategory) {
            if ($line -match '^<details>\s*$') {
                $nextLine = if ($i + 1 -lt $lines.Count) { $lines[$i + 1] } else { '' }
                if ($nextLine -match '^<summary><strong>(\d+)\.\s+(.+?)</strong></summary>\s*$') {
                    $currentCatId = $matches[1]
                    $results += [PSCustomObject]@{ Id = $currentCatId; Name = $matches[2]; Level = 1; ParentId = "" }
                    $inCategory = $true
                }
            }
        } else {
            if ($line -match '^</details>\s*$') {
                $inCategory = $false; $currentCatId = $null
            } elseif ($line -match '^### (\d+)\.(\d+)\s+(.+?)\s*$') {
                if ($matches[1] -eq $currentCatId) {
                    $results += [PSCustomObject]@{
                        Id = "$($matches[1]).$($matches[2])"; Name = $matches[3]; Level = 2; ParentId = $currentCatId
                    }
                }
            }
        }
    }
    return $results
}

# --- Shared parser: user-workflow-tracking.md WF-NNN rows (adapted from New-TestInfrastructure.ps1 Phase 3c1) ---
function Get-ParsedWorkflows {
    param([string]$Path)
    if ([string]::IsNullOrEmpty($Path) -or -not (Test-Path $Path)) { return @() }
    $content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content)) { return @() }
    $lines = $content -split "`r?`n"

    $startIdx = -1; $endIdx = $lines.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## Workflows\s*$') { $startIdx = $i }
        elseif ($startIdx -ge 0 -and $lines[$i] -match '^## ' -and $lines[$i] -notmatch '^## Workflows\s*$') {
            $endIdx = $i; break
        }
    }
    if ($startIdx -lt 0) { return @() }

    $results = @()
    for ($i = $startIdx; $i -lt $endIdx; $i++) {
        if ($lines[$i] -match '^\|\s*(WF-\d+)\s*\|\s*(.+?)\s*\|') {
            $results += [PSCustomObject]@{ Id = $matches[1]; Name = $matches[2] }
        }
    }
    return $results
}

# =========================================================================
# Shared test-tree exclusion (PF-IMP-979, consolidated PF-IMP-1152)
# =========================================================================
# Directory names under test/ that are infrastructure, committed data, or
# framework self-tests — NOT feature-organized test code — and are therefore
# exempt from BOTH the Surface 16 audit-mirror requirement and the Surface 17
# category-alignment requirement.
# Sourced from the shared Get-NonFeatureTestDir helper (Common-ScriptHelpers/
# Core.psm1) so Surfaces 14/16/17 and New-TestInfrastructure.ps1 cannot silently
# diverge the way Surface 17 did after PF-IMP-956 only patched Surface 16.
#   - Runtime/cache artifacts: pytest caches, VCS / dependency / venv dirs
#   - Data-only support dirs:  committed test data (fixtures) with no audit mirror
#   - Self-test trees:         framework/ (appdev framework self-tests; PF-IMP-1190)
# =========================================================================
$script:NonFeatureTestDirs = Get-NonFeatureTestDir -Scope TestTree

# =========================================================================
# Surface 16: Audit Mirror Invariant
# =========================================================================
# Enforces the path-transform rule from PF-IMP-871 Phase 3a:
#   - test/automated/<path>/                            ↔ test/audits/<path>/
#   - test/e2e-acceptance-testing/<workflow>/templates/ ↔ test/audits/e2e/<workflow>/
# `bug-validation/` is explicitly exempt (no audit mirror by design — manual
# reproduction harnesses, not part of the auditable test suite).
# =========================================================================
if ($runAll -or $Surface -contains "AuditMirror") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 16: Audit Mirror Invariant" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $ctx = Get-TestAuditContext -ProjectRoot $ProjectRoot
    $testRoot = $ctx.TestRoot
    $automatedRoot = Join-Path $testRoot "automated"
    $auditsRoot    = Join-Path $testRoot "audits"
    $e2eRoot       = Join-Path $testRoot "e2e-acceptance-testing"

    if (-not (Test-Path $testRoot)) {
        Add-CheckResult "WARNING" "AuditMirror" "TestRoot" "Test root not found at $testRoot — skipping"
    } else {
        $checked = 0; $issues = 0

        # Non-feature dirs (runtime/cache artifacts + committed data-only support dirs like
        # fixtures/) are not part of the auditable test tree — skip them in the recursive walks
        # below so they don't read as "missing audit mirror" (16a) or orphan/unknown-subtree
        # dirs (16c). Uses the shared $script:NonFeatureTestDirs list (PF-IMP-956, PF-IMP-979).

        # --- 16a: automated/ ↔ audits/ subtree (every automated dir has an audit mirror) ---
        if (Test-Path $automatedRoot) {
            $autoSubdirs = Get-ChildItem -Path $automatedRoot -Directory -Recurse -ErrorAction SilentlyContinue
            foreach ($d in $autoSubdirs) {
                $rel = $d.FullName.Substring($automatedRoot.Length).TrimStart('\','/')
                # Skip non-feature dirs (runtime/cache + data-only) anywhere in the path (PF-IMP-956, PF-IMP-979)
                if (($rel -split '[\\/]').Where({ $script:NonFeatureTestDirs -contains $_ }).Count -gt 0) { continue }
                # Skip bug-validation tree if it accidentally still exists under automated/
                # (Phase 3d moved it to test/ top-level; presence here would be stale)
                if ($rel -match '^bug-validation([\\/]|$)') { continue }
                $expectedAuditDir = Join-Path (Join-Path $auditsRoot "") $rel
                $checked++
                if (-not (Test-Path $expectedAuditDir)) {
                    $issues++
                    Add-CheckResult "ERROR" "AuditMirror" "automated/$rel" "Missing audit mirror at audits/$rel"
                } else {
                    Add-CheckResult "OK" "AuditMirror" "automated/$rel" "Audit mirror present"
                }
            }
        }

        # --- 16b: e2e-acceptance-testing/<wf>/templates/ ↔ audits/e2e/<wf>/ ---
        if (Test-Path $e2eRoot) {
            $wfDirs = Get-ChildItem -Path $e2eRoot -Directory -ErrorAction SilentlyContinue
            foreach ($wf in $wfDirs) {
                $tmpl = Join-Path $wf.FullName "templates"
                if (-not (Test-Path $tmpl)) { continue }
                $expectedAuditDir = Join-Path (Join-Path $auditsRoot "e2e") $wf.Name
                $checked++
                if (-not (Test-Path $expectedAuditDir)) {
                    $issues++
                    Add-CheckResult "ERROR" "AuditMirror" "e2e-acceptance-testing/$($wf.Name)" "Missing audit mirror at audits/e2e/$($wf.Name)"
                } else {
                    Add-CheckResult "OK" "AuditMirror" "e2e-acceptance-testing/$($wf.Name)" "Audit mirror present"
                }
            }
        }

        # --- 16c: reverse — every audits/ subtree dir traces back to a source dir ---
        # Catches orphan audit dirs left behind after a feature/workflow is renamed/removed.
        if (Test-Path $auditsRoot) {
            $auditSubdirs = Get-ChildItem -Path $auditsRoot -Directory -Recurse -ErrorAction SilentlyContinue
            foreach ($d in $auditSubdirs) {
                $rel = $d.FullName.Substring($auditsRoot.Length).TrimStart('\','/')
                # Skip non-feature dirs (runtime/cache + data-only) anywhere in the path (PF-IMP-956, PF-IMP-979)
                if (($rel -split '[\\/]').Where({ $script:NonFeatureTestDirs -contains $_ }).Count -gt 0) { continue }

                # Determine expected source location based on top-level audit subtree.
                # Known subtrees = the canonical unit/performance, e2e (special mapping), plus any
                # further test category actually present under automated/ (language/project
                # quickCategories, e.g. dart's widget) — symmetric with the 16a forward walk,
                # which demands a mirror for whatever exists under automated/ (PF-IMP-1387).
                $topSegment = ($rel -split '[\\/]', 2)[0]
                $rest = if ($rel -match '[\\/]') { ($rel -split '[\\/]', 2)[1] } else { "" }

                $expectedSource = $null
                if ($topSegment -eq 'e2e') {
                    # audits/e2e/<wf>/ traces back to e2e-acceptance-testing/<wf>/templates/
                    # Only check at depth 1; deeper levels (audit reports per test case) are fine.
                    if ($rest -and -not ($rest -match '[\\/]')) {
                        $expectedSource = Join-Path (Join-Path $e2eRoot $rest) "templates"
                    }
                } elseif ($topSegment -in @('unit', 'performance') -or (Test-Path (Join-Path $automatedRoot $topSegment))) {
                    $expectedSource = Join-Path (Join-Path $automatedRoot $topSegment) $rest
                } else {
                    # Unknown top-level audit subtree (no automated/ counterpart, e.g. legacy
                    # foundation/authentication/core-features leftovers)
                    # → warn, don't error: useful early-warning for stale leftovers.
                    $checked++
                    Add-CheckResult "WARNING" "AuditMirror" "audits/$rel" "Audit dir under unknown top-level subtree '$topSegment' (no matching test category under automated/, and not e2e)"
                    continue
                }

                if ($null -ne $expectedSource) {
                    $checked++
                    if (-not (Test-Path $expectedSource)) {
                        $issues++
                        $expectedRel = $expectedSource.Substring($testRoot.Length).TrimStart('\','/')
                        Add-CheckResult "ERROR" "AuditMirror" "audits/$rel" "Orphan audit dir — no source at $expectedRel"
                    } else {
                        Add-CheckResult "OK" "AuditMirror" "audits/$rel" "Source dir present"
                    }
                }
            }
        }

        Set-SurfaceExamined "AuditMirror" $checked
        Write-Host "  Checked $checked mirror pair(s), $issues issue(s)" -ForegroundColor Gray
    }
    Write-Host ""
}

# =========================================================================
# Surface 17: Category Alignment
# =========================================================================
# Enforces alignment between feature-tracking.md feature-category structure
# and the on-disk `test/automated/unit/<N>-<slug>/[<N.X>-<slug>/]` layout
# scaffolded by New-TestInfrastructure.ps1 -Update Section A (Phase 3a).
# =========================================================================
if ($runAll -or $Surface -contains "CategoryAlignment") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 17: Category Alignment" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $ctx = Get-TestAuditContext -ProjectRoot $ProjectRoot
    $unitRoot = Join-Path $ctx.TestRoot "automated/unit"

    if (-not (Test-Path $ctx.FeatureTrackingPath)) {
        Add-CheckResult "WARNING" "CategoryAlignment" "FeatureTracking" "feature-tracking.md not found at $($ctx.FeatureTrackingPath) — skipping"
    } elseif (-not (Test-Path $unitRoot)) {
        Add-CheckResult "WARNING" "CategoryAlignment" "UnitRoot" "Unit test root not found at $unitRoot — skipping"
    } else {
        $cats = Get-ParsedFeatureCategories -Path $ctx.FeatureTrackingPath

        # Build expected dir name per category/subgroup using New-FeatureDirSlug from Naming module
        $expectedTopByName = @{}    # "<N>-<slug>" → category Id
        $expectedSubByParent = @{}  # parentId → @("<N.X>-<slug>", ...)

        foreach ($c in $cats) {
            $slug = $null
            try { $slug = New-FeatureDirSlug -Id $c.Id -Name $c.Name } catch { $slug = $null }
            if ([string]::IsNullOrEmpty($slug)) { continue }

            if ($c.Level -eq 1) {
                $expectedTopByName[$slug] = $c.Id
            } elseif ($c.Level -eq 2) {
                if (-not $expectedSubByParent.ContainsKey($c.ParentId)) {
                    $expectedSubByParent[$c.ParentId] = @()
                }
                $expectedSubByParent[$c.ParentId] += $slug
            }
        }

        # 17a: each expected level-1 dir exists
        foreach ($slug in $expectedTopByName.Keys) {
            $expectedPath = Join-Path $unitRoot $slug
            if (-not (Test-Path $expectedPath)) {
                Add-CheckResult "ERROR" "CategoryAlignment" "unit/$slug" "Expected category dir missing (category $($expectedTopByName[$slug]))"
            } else {
                Add-CheckResult "OK" "CategoryAlignment" "unit/$slug" "Category dir present"
            }
        }

        # 17b: each expected level-2 subgroup dir exists under its parent
        # Need to re-map parent Id → parent slug to build the expected path
        $parentIdToSlug = @{}
        foreach ($slug in $expectedTopByName.Keys) { $parentIdToSlug[$expectedTopByName[$slug]] = $slug }

        foreach ($parentId in $expectedSubByParent.Keys) {
            if (-not $parentIdToSlug.ContainsKey($parentId)) { continue }
            $parentSlug = $parentIdToSlug[$parentId]
            foreach ($subSlug in $expectedSubByParent[$parentId]) {
                $expectedPath = Join-Path (Join-Path $unitRoot $parentSlug) $subSlug
                if (-not (Test-Path $expectedPath)) {
                    Add-CheckResult "ERROR" "CategoryAlignment" "unit/$parentSlug/$subSlug" "Expected subgroup dir missing"
                } else {
                    Add-CheckResult "OK" "CategoryAlignment" "unit/$parentSlug/$subSlug" "Subgroup dir present"
                }
            }
        }

        # 17c: reverse — every dir under unit/ traces back to a category/subgroup.
        # Skip non-feature dirs (runtime/cache + data-only) so they don't read as orphans (PF-IMP-979).
        $topDirs = Get-ChildItem -Path $unitRoot -Directory -ErrorAction SilentlyContinue
        foreach ($t in $topDirs) {
            if ($t.Name -in $script:NonFeatureTestDirs) { continue }
            if (-not $expectedTopByName.ContainsKey($t.Name)) {
                Add-CheckResult "WARNING" "CategoryAlignment" "unit/$($t.Name)" "Orphan unit dir — no matching category in feature-tracking.md (rename/remove?)"
            } else {
                $parentSlug = $t.Name
                $parentId = $expectedTopByName[$parentSlug]
                $subDirs = Get-ChildItem -Path $t.FullName -Directory -ErrorAction SilentlyContinue
                $expectedSubs = if ($expectedSubByParent.ContainsKey($parentId)) { $expectedSubByParent[$parentId] } else { @() }
                foreach ($s in $subDirs) {
                    if ($s.Name -in $script:NonFeatureTestDirs) { continue }
                    if ($s.Name -notin $expectedSubs) {
                        Add-CheckResult "WARNING" "CategoryAlignment" "unit/$parentSlug/$($s.Name)" "Orphan subgroup dir — no matching subgroup under category $parentId"
                    }
                }
            }
        }

        Set-SurfaceExamined "CategoryAlignment" (@($cats).Count)
        Write-Host "  Checked $($cats.Count) tracked category/subgroup entries" -ForegroundColor Gray
    }
    Write-Host ""
}

# =========================================================================
# Surface 18: Workflow Alignment
# =========================================================================
# Enforces alignment between user-workflow-tracking.md WF-NNN rows and the
# on-disk `test/e2e-acceptance-testing/<workflow-slug>/templates/` layout
# scaffolded by New-TestInfrastructure.ps1 -Update Section C (Phase 3c1).
# =========================================================================
if ($runAll -or $Surface -contains "WorkflowAlignment") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 18: Workflow Alignment" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $ctx = Get-TestAuditContext -ProjectRoot $ProjectRoot
    $e2eRoot = Join-Path $ctx.TestRoot "e2e-acceptance-testing"

    if (-not (Test-Path $ctx.WorkflowTrackingPath)) {
        Add-CheckResult "WARNING" "WorkflowAlignment" "WorkflowTracking" "user-workflow-tracking.md not found at $($ctx.WorkflowTrackingPath) — skipping"
    } elseif (-not (Test-Path $e2eRoot)) {
        Add-CheckResult "WARNING" "WorkflowAlignment" "E2ERoot" "E2E root not found at $e2eRoot — skipping"
    } else {
        $workflows = Get-ParsedWorkflows -Path $ctx.WorkflowTrackingPath

        # Build expected slug set
        $expectedSlugs = @{}
        foreach ($w in $workflows) {
            $slug = $null
            try { $slug = ConvertTo-FeatureSlug -Name $w.Name -Convention 'kebab-case' } catch { $slug = $null }
            if (-not [string]::IsNullOrEmpty($slug)) { $expectedSlugs[$slug] = $w.Id }
        }

        # 18a: each expected workflow dir exists with a templates/ subdir
        foreach ($slug in $expectedSlugs.Keys) {
            $expectedPath = Join-Path (Join-Path $e2eRoot $slug) "templates"
            if (-not (Test-Path $expectedPath)) {
                Add-CheckResult "ERROR" "WorkflowAlignment" "e2e-acceptance-testing/$slug" "Expected workflow dir missing templates/ (workflow $($expectedSlugs[$slug]))"
            } else {
                Add-CheckResult "OK" "WorkflowAlignment" "e2e-acceptance-testing/$slug" "Workflow dir present"
            }
        }

        # 18b: reverse — every top-level dir under e2e-acceptance-testing/ traces to a WF entry.
        # Skip files (e.g., .gitignore) and dirs without a templates/ subdir (likely stale leftovers).
        $topDirs = Get-ChildItem -Path $e2eRoot -Directory -ErrorAction SilentlyContinue
        foreach ($t in $topDirs) {
            $hasTemplates = Test-Path (Join-Path $t.FullName "templates")
            if (-not $hasTemplates) { continue }  # Not a workflow dir; skip
            if (-not $expectedSlugs.ContainsKey($t.Name)) {
                Add-CheckResult "WARNING" "WorkflowAlignment" "e2e-acceptance-testing/$($t.Name)" "Orphan workflow dir — no matching WF-NNN in user-workflow-tracking.md"
            }
        }

        Set-SurfaceExamined "WorkflowAlignment" (@($workflows).Count)
        Write-Host "  Checked $($workflows.Count) tracked workflow(s)" -ForegroundColor Gray
    }
    Write-Host ""
}

# =========================================================================
# Surface 19: Variant Pair Consistency
# =========================================================================
# Scans process-framework .md files for variant_group / variant_siblings
# frontmatter and enforces sibling existence + symmetry (PF-IMP-837).
# =========================================================================
if ($runAll -or $Surface -contains "VariantPairConsistency") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 19: Variant Pair Consistency" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $pfDir = Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot

    # Phase 1: scan all .md files under process-framework/ for variant frontmatter
    $variantFiles = @{}  # relPath → @{ Group; Siblings (list of filenames); FullPath; Dir }
    $mdFiles = Get-ChildItem -Path $pfDir -Filter "*.md" -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/](scripts|tools|visualization|infrastructure)[\\/]' }

    foreach ($f in $mdFiles) {
        $raw = Get-Content $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not $raw) { continue }
        if ($raw -notmatch '^---\s*\r?\n([\s\S]*?)\r?\n---') { continue }
        $fm = $Matches[1]
        if ($fm -notmatch 'variant_group:') { continue }

        $group = $null
        $siblings = @()
        $inSiblings = $false
        foreach ($line in ($fm -split '\r?\n')) {
            if ($line -match '^\s*variant_group:\s*(.+)$') {
                $group = $Matches[1].Trim().Trim('"').Trim("'")
                $inSiblings = $false
            } elseif ($line -match '^\s*variant_siblings:\s*$') {
                $inSiblings = $true
            } elseif ($line -match '^\s*variant_siblings:\s*\[(.+)\]') {
                $siblings = $Matches[1] -split '\s*,\s*' | ForEach-Object { $_.Trim().Trim('"').Trim("'") }
                $inSiblings = $false
            } elseif ($inSiblings -and $line -match '^\s+-\s+(.+)$') {
                $siblings += $Matches[1].Trim().Trim('"').Trim("'")
            } elseif ($inSiblings -and $line -notmatch '^\s+-') {
                $inSiblings = $false
            }
        }

        if ($group) {
            $relPath = $f.FullName.Substring($ProjectRoot.Length + 1) -replace '\\', '/'
            $variantFiles[$relPath] = @{
                Group    = $group
                Siblings = $siblings
                FullPath = $f.FullName
                Dir      = $f.DirectoryName
            }
        }
    }

    if ($variantFiles.Count -eq 0) {
        Add-CheckResult "WARNING" "VariantPairConsistency" "scan" "No files with variant_group frontmatter found under $(Split-Path $pfDir -Leaf)/"
    } else {
        # Build reverse lookup: fullPath → relPath for symmetry checks
        $fullToRel = @{}
        foreach ($rp in $variantFiles.Keys) { $fullToRel[$variantFiles[$rp].FullPath] = $rp }

        foreach ($relPath in $variantFiles.Keys) {
            $entry = $variantFiles[$relPath]

            # 19a: each declared sibling exists
            foreach ($sib in $entry.Siblings) {
                $sibFull = Join-Path $entry.Dir $sib
                if (-not (Test-Path $sibFull)) {
                    Add-CheckResult "ERROR" "VariantPairConsistency" $relPath "Sibling not found: $sib"
                    continue
                }

                # 19b: sibling lists this file back (symmetry)
                $sibFullResolved = (Resolve-Path $sibFull -ErrorAction SilentlyContinue).Path
                $sibRel = if ($sibFullResolved) { $fullToRel[$sibFullResolved] } else { $null }
                if (-not $sibRel -or -not $variantFiles.ContainsKey($sibRel)) {
                    Add-CheckResult "ERROR" "VariantPairConsistency" $relPath "Sibling $sib exists but has no variant_group frontmatter"
                    continue
                }

                $sibEntry = $variantFiles[$sibRel]
                $myFilename = Split-Path $relPath -Leaf
                if ($sibEntry.Siblings -notcontains $myFilename) {
                    Add-CheckResult "ERROR" "VariantPairConsistency" $relPath "Asymmetric: lists $sib as sibling but $sib does not list $myFilename back"
                } else {
                    Add-CheckResult "OK" "VariantPairConsistency" $relPath "Sibling ${sib}: exists + symmetric"
                }

                # 19c: sibling agrees on variant_group
                if ($sibEntry.Group -ne $entry.Group) {
                    Add-CheckResult "ERROR" "VariantPairConsistency" $relPath "Group mismatch: this=$($entry.Group), $sib=$($sibEntry.Group)"
                }
            }
        }

        # Count distinct groups
        $groups = $variantFiles.Values | ForEach-Object { $_.Group } | Select-Object -Unique
        Set-SurfaceExamined "VariantPairConsistency" (@($variantFiles).Count)
        Write-Host "  Checked $($variantFiles.Count) variant files across $($groups.Count) group(s)" -ForegroundColor Gray
    }
    Write-Host ""
}

# =========================================================================
# Surfaces 20–24: Permanent-tracker coverage (PF-IMP-1212 / PF-PRO-049).
# The "master state" validator previously had no surface for 4 of the permanent project
# trackers (feature-request, architecture, technical-debt, bug-tracking) or for the central
# IMP tracker (PF-EVR-026 finding C-2). These surfaces close that gap. Per PF-PRO-049 decision A
# the 4 project-local surfaces validate intra-tracker markdown link existence — the defect class
# CrossRef (Surface 4, ID cross-ref) and IdCounters (Surface 5, counter health) do NOT cover —
# reusing the same Get-MarkdownLinks / Resolve-MarkdownLink / Find-SimilarFile helpers as
# Surfaces 1–3. Broken links are reported as WARNING, not ERROR: this is a warn-first rollout
# (newly-covered trackers carry pre-existing link debt in some trees, e.g. appdev's leftover
# mirror), promotable to ERROR after soak — mirroring the PF-IMP-1211 warn→block gate staging.
# Absent target → the standardized PF-IMP-1209 "examined 0 instances" WARNING.
# =========================================================================
function Invoke-TrackerLinkSurface {
    param(
        [string]$SurfaceName,
        [string]$TrackerPath,
        [string]$DisplayLabel
    )
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $DisplayLabel" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    if (-not (Test-Path $TrackerPath)) {
        # PF-IMP-1209 remainder + PF-PRO-049 decision A: an absent product tracker is a setup defect
        # that must gate in a leaf product project (ERROR), but is legitimately N/A in a non-project
        # workspace (a framework workspace has no product features/bugs by design) → WARNING.
        # Severity by declared role — the "do I have a product?" role question (PF-PRO-067 Contract 4).
        $absentLevel = if ($script:workspaceRole -ne 'project') { "WARNING" } else { "ERROR" }
        Add-AbsentTargetResult $absentLevel $SurfaceName ([System.IO.Path]::GetFileName($TrackerPath)) "tracker not found ($TrackerPath)"
        Write-Host ""
        return
    }

    Set-SurfaceExamined $SurfaceName 1   # tracker present = 1 instance examined (links are sub-checks)
    $trackerDir = [System.IO.Path]::GetDirectoryName($TrackerPath)
    $lines = Get-Content $TrackerPath -Encoding UTF8
    $linkCount = 0
    $brokenCount = 0
    foreach ($line in $lines) {
        $links = Get-MarkdownLinks -Line $line
        foreach ($link in $links) {
            $resolved = Resolve-MarkdownLink -LinkPath $link.Path -SourceFileDir $trackerDir
            if ($null -eq $resolved) { continue }
            $linkCount++
            $ctx = if ($link.Text) { $link.Text } else { $link.Path }
            if (Test-Path $resolved) {
                Add-CheckResult "OK" $SurfaceName $ctx "Link valid"
            } else {
                $brokenCount++
                $suggestion = Find-SimilarFile -ExpectedPath $resolved
                $msg = "Link broken: $($link.Path)"
                if ($suggestion -and $suggestion.Length -gt 0) { $msg += " (did you mean: $suggestion?)" }
                Add-CheckResult "WARNING" $SurfaceName $ctx $msg
            }
        }
    }
    if ($linkCount -eq 0) {
        # Present but no file links — record the visit so the surface is not "silent" (PF-IMP-1209).
        Add-CheckResult "OK" $SurfaceName ([System.IO.Path]::GetFileName($TrackerPath)) "Tracker present; no file links to validate"
    }
    Write-Host "  Checked $linkCount link(s), $brokenCount broken" -ForegroundColor Gray
    Write-Host ""
}

if ($runAll -or $Surface -contains "FeatureRequestTracking") {
    Invoke-TrackerLinkSurface -SurfaceName "FeatureRequestTracking" `
        -TrackerPath (Join-Path $ProjectRoot "doc/state-tracking/permanent/feature-request-tracking.md") `
        -DisplayLabel "Surface 20: Feature Request Tracking"
}

if ($runAll -or $Surface -contains "ArchitectureTracking") {
    Invoke-TrackerLinkSurface -SurfaceName "ArchitectureTracking" `
        -TrackerPath (Join-Path $ProjectRoot "doc/state-tracking/permanent/architecture-tracking.md") `
        -DisplayLabel "Surface 21: Architecture Tracking"
}

if ($runAll -or $Surface -contains "TechDebtTracking") {
    Invoke-TrackerLinkSurface -SurfaceName "TechDebtTracking" `
        -TrackerPath (Join-Path $ProjectRoot "doc/state-tracking/permanent/technical-debt-tracking.md") `
        -DisplayLabel "Surface 22: Technical Debt Tracking"
}

if ($runAll -or $Surface -contains "BugTracking") {
    Invoke-TrackerLinkSurface -SurfaceName "BugTracking" `
        -TrackerPath (Join-Path $ProjectRoot "doc/state-tracking/permanent/bug-tracking.md") `
        -DisplayLabel "Surface 23: Bug Tracking"
}

# Surface 24: central IMP tracker — reachability + structural check only. Its markdown links are
# authored relative to appdev's tree (where central is local); resolving them from an arbitrary
# project's ProjectRoot would mis-resolve, so link existence is intentionally NOT validated here
# (that stays an appdev-side concern). Resolved via the central pointer (Get-CentralFrameworkPath,
# which throws on an unresolvable pointer — caught and downgraded to a coverage WARNING).
if ($runAll -or $Surface -contains "ProcessImprovementTracking") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 24: Process Improvement Tracking (central)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    $impPath = $null
    try {
        $centralRoot = Get-CentralFrameworkPath
        if ($centralRoot) { $impPath = Join-Path $centralRoot "state-tracking/permanent/process-improvement-tracking.md" }
    } catch {
        $impPath = $null
    }

    if (-not $impPath -or -not (Test-Path $impPath)) {
        # Conditional target: the central tracker resolves via .framework-central-pointer, which only
        # exists after a Push reaches the project — a not-yet-reached project legitimately can't resolve
        # it, so this stays WARNING rather than ERROR.
        Add-AbsentTargetResult "WARNING" "ProcessImprovementTracking" "process-improvement-tracking.md" "central IMP tracker not resolved/found (pointer absent → project not yet reached by a Push)"
    } else {
        Set-SurfaceExamined "ProcessImprovementTracking" 1
        $impContent = Get-Content $impPath -Raw -Encoding UTF8
        if ($impContent -match '(?m)^\|.*\|') {
            Add-CheckResult "OK" "ProcessImprovementTracking" "process-improvement-tracking.md" "Central IMP tracker reachable and contains a table"
        } else {
            Add-CheckResult "WARNING" "ProcessImprovementTracking" "process-improvement-tracking.md" "Central IMP tracker reachable but no markdown table found"
        }
    }
    Write-Host ""
}

# =========================================================================
# Surface 25: Blueprint Central References (PF-IMP-1589) — appdev layout only.
# Links from blueprint/**/*.md into process-framework-central/ are rolled-layout-relative
# navigational hints (PF-IMP-1097): they resolve to a nonexistent path in EVERY layout
# (appdev and rolled-out projects alike), so LinkWatcher can neither update them when a
# central artifact moves nor validate them (the .linkwatcher-ignore suppression rule hides
# them from --validate by design). Until this surface, only a manual grep caught the rot —
# it recurred at extension closures (PF-IMP-1171: 3 dead refs; 2026-07-16: 6 more).
# Check: take each markdown link whose target contains "process-framework-central/", strip
# the relative prefix and any anchor, and assert the "process-framework-central/<rest>" tail
# exists under the real central tree at the project root. Broken links → WARNING (warn-first,
# like Surfaces 20–23). Outside the appdev layout (no blueprint/ + process-framework-central/
# pair at the root) the surface records an explicit N/A-by-design OK — a project not having
# a blueprint tree is the healthy state, not a coverage gap.
# =========================================================================
if ($runAll -or $Surface -contains "BlueprintCentralRefs") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 25: Blueprint Central References" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    $bcrBlueprintDir = Join-Path $ProjectRoot "blueprint"
    $bcrCentralDir   = Join-Path $ProjectRoot "process-framework-central"
    if (-not ((Test-Path $bcrBlueprintDir) -and (Test-Path $bcrCentralDir))) {
        # Not the framework-management workspace — nothing to examine BY DESIGN (unlike an
        # absent product tracker, this is not a setup defect in any project). Examined=1:
        # the layout question itself was checked (mirrors the "tracker present; no file
        # links" convention of the tracker link surfaces).
        Set-SurfaceExamined "BlueprintCentralRefs" 1
        Add-CheckResult "OK" "BlueprintCentralRefs" "blueprint/" "No blueprint/ + process-framework-central/ pair at this root — blueprint-to-central references exist only in the framework-management workspace (appdev); nothing to examine"
        Write-Host "  Not the appdev layout - surface N/A by design" -ForegroundColor Gray
        Write-Host ""
    } else {
        $bcrMarker = 'process-framework-central/'
        $bcrLinkCount = 0
        $bcrBrokenCount = 0
        foreach ($bcrFile in (Get-ChildItem -Path $bcrBlueprintDir -Recurse -Filter *.md -File)) {
            $bcrRel = ([System.IO.Path]::GetRelativePath($ProjectRoot, $bcrFile.FullName)) -replace '\\', '/'
            $bcrLineNo = 0
            foreach ($bcrLine in [System.IO.File]::ReadLines($bcrFile.FullName)) {
                $bcrLineNo++
                if ($bcrLine.IndexOf($bcrMarker) -lt 0) { continue }
                foreach ($bcrLink in (Get-MarkdownLinks -Line $bcrLine)) {
                    $bcrIdx = $bcrLink.Path.IndexOf($bcrMarker)
                    if ($bcrIdx -lt 0) { continue }
                    $bcrLinkCount++
                    # Strip anchor, then keep only the central-relative tail — the relative
                    # prefix is a layout fiction and must not participate in resolution.
                    $bcrTail = (($bcrLink.Path -split '#')[0])
                    $bcrTail = $bcrTail.Substring($bcrTail.IndexOf($bcrMarker) + $bcrMarker.Length)
                    $bcrTarget = if ([string]::IsNullOrWhiteSpace($bcrTail)) { $bcrCentralDir } else { Join-Path $bcrCentralDir $bcrTail }
                    $bcrContext = "$bcrRel`:$bcrLineNo"
                    if (Test-Path $bcrTarget) {
                        Add-CheckResult "OK" "BlueprintCentralRefs" $bcrContext "Central link target exists: process-framework-central/$bcrTail"
                    } else {
                        $bcrBrokenCount++
                        $bcrSuggestion = Find-SimilarFile -ExpectedPath ([System.IO.Path]::GetFullPath($bcrTarget))
                        $bcrMsg = "Central link target missing: process-framework-central/$bcrTail (link: $($bcrLink.Path))"
                        if ($bcrSuggestion -and $bcrSuggestion.Length -gt 0) { $bcrMsg += " (did you mean: $bcrSuggestion?)" }
                        Add-CheckResult "WARNING" "BlueprintCentralRefs" $bcrContext $bcrMsg
                    }
                }
            }
        }
        Set-SurfaceExamined "BlueprintCentralRefs" $bcrLinkCount
        if ($bcrLinkCount -eq 0) {
            # Appdev layout but zero blueprint→central links — implausible (89 at introduction),
            # so surface it as an examined-0 coverage gap rather than a clean pass.
            Add-AbsentTargetResult "WARNING" "BlueprintCentralRefs" "blueprint/" "appdev layout present but no blueprint-to-central markdown links found"
        }
        Write-Host "  Checked $bcrLinkCount central link(s), $bcrBrokenCount broken" -ForegroundColor Gray
        Write-Host ""
    }
}

# Surface 26: Technical Exploration Tracking (PF-IMP-1584; PF-EVR-029 F-4) — the exploration
# tracker copied feature-request-tracking as its pattern model in every respect except this
# surface. Update-Exploration.ps1 guards Findings Doc presence at RESOLVE time only; this
# closes the post-resolve gap (a rotted findings link is a dead end for the downstream task).
# Same helper + warn-first semantics as its sibling intake queues (Surfaces 20–23).
if ($runAll -or $Surface -contains "ExplorationTracking") {
    Invoke-TrackerLinkSurface -SurfaceName "ExplorationTracking" `
        -TrackerPath (Join-Path $ProjectRoot "doc/state-tracking/permanent/technical-exploration-tracking.md") `
        -DisplayLabel "Surface 26: Technical Exploration Tracking"
}

# =========================================================================
# Surface 27: Task ID References (PF-IMP-1677) — appdev layout only. Task ids in authored
# framework prose are hand-typed free text with no coupling to the task files that own them,
# and the metadata generator's -Check validates projections, not prose — so wrong ids ship
# silently (a 9-site phantom gate id survived 2026-04..07; 7 wrong-but-live ids survived a
# dedicated sweep; 3 more found at this surface's introduction). Two checks over the authored
# directories (tasks/, guides/, templates/, .claude/skills/ — the generated projections and
# the registry's deliberate tombstone entries are outside this set):
#   (a) membership — a cited PF-TSK-NNN assigned to no task file (phantom id);
#   (b) name-vs-id — a "Name (PF-TSK-NNN)" pair whose Name normalizes to a known task's own
#       title while the cited id differs (wrong-but-live id, which check (a) passes). The
#       lookup is precision-first: a name matching no task title is simply not checked, so
#       legitimate loose pairings ("Improvements (PF-TSK-009)", artifact→owning-task refs)
#       never flag.
# Both warn-first WARNING, promotable after soak. Authored prose exists only in the
# framework-management workspace (appdev); projects get the moved-upstream N/A OK.
# =========================================================================
if ($runAll -or $Surface -contains "TaskIdRefs") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 27: Task ID References" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    $tirFrameworkRoot = Join-Path $ProjectRoot "blueprint/process-framework"
    if (-not (Test-Path (Join-Path $tirFrameworkRoot "tasks"))) {
        # Not the framework-management workspace — authored task prose is edited (and thus
        # fixable) only in appdev, so there is nothing actionable to examine here by design.
        Set-SurfaceExamined "TaskIdRefs" 1
        Add-CheckResult "OK" "TaskIdRefs" "blueprint/process-framework/tasks/" "No authored framework tree at this root — task-id prose references are checked in the framework-management workspace (appdev); nothing to examine"
        Write-Host "  Not the appdev layout - surface N/A by design" -ForegroundColor Gray
        Write-Host ""
    } else {
        function Get-TirNormalizedTaskName {
            param([string]$Name)
            $n = $Name.Trim().ToLowerInvariant() -replace '\s+', ' '
            $n = $n -replace '^the\s+', ''
            while ($n -match '\s(task|process)$') { $n = $n -replace '\s(task|process)$', '' }
            return $n
        }

        # id -> title map from the task files' own frontmatter + H1; title -> id reverse map
        # for the name-vs-id check (a normalized-title collision would make the reverse lookup
        # ambiguous, so colliding names are dropped from it).
        $tirIdMap = @{}
        $tirNameMap = @{}
        $tirCollisions = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($tirTaskFile in (Get-ChildItem (Join-Path $tirFrameworkRoot "tasks") -Recurse -Filter *.md -File)) {
            $tirId = $null; $tirTitle = $null
            foreach ($tirLine in [System.IO.File]::ReadLines($tirTaskFile.FullName)) {
                if (-not $tirId -and $tirLine -match '^id:\s*([A-Z]{2,4}-TSK-\d+)') { $tirId = $Matches[1] }
                if (-not $tirTitle -and $tirLine -match '^#\s+(.+)$') { $tirTitle = $Matches[1].Trim() }
                if ($tirId -and $tirTitle) { break }
            }
            if (-not $tirId) { continue }
            $tirIdMap[$tirId] = $tirTitle
            if ($tirTitle) {
                $tirNorm = Get-TirNormalizedTaskName $tirTitle
                if ($tirNameMap.ContainsKey($tirNorm)) { [void]$tirCollisions.Add($tirNorm) }
                else { $tirNameMap[$tirNorm] = $tirId }
            }
        }
        foreach ($tirC in $tirCollisions) { $tirNameMap.Remove($tirC) }

        # Authored prose set: the three authored framework dirs + the framework craft skills.
        $tirScanDirs = @(
            (Join-Path $tirFrameworkRoot "tasks"),
            (Join-Path $tirFrameworkRoot "guides"),
            (Join-Path $tirFrameworkRoot "templates"),
            (Join-Path $ProjectRoot "blueprint/.claude/skills")
        ) | Where-Object { Test-Path $_ }

        $tirTokenRe = [regex]'[A-Z]{2,4}-TSK-\d{3}'
        $tirPairRe  = [regex]'([A-Z][A-Za-z0-9&/() .-]{2,60}?)(?:\*\*)?\s*\(([A-Z]{2,4}-TSK-\d{3})\)'
        $tirTokenCount = 0
        $tirPhantomCount = 0
        $tirMismatchCount = 0
        foreach ($tirDir in $tirScanDirs) {
            foreach ($tirFile in (Get-ChildItem $tirDir -Recurse -Filter *.md -File)) {
                $tirRel = ([System.IO.Path]::GetRelativePath($ProjectRoot, $tirFile.FullName)) -replace '\\', '/'
                $tirLineNo = 0
                foreach ($tirLine in [System.IO.File]::ReadLines($tirFile.FullName)) {
                    $tirLineNo++
                    if ($tirLine.IndexOf('-TSK-') -lt 0) { continue }
                    foreach ($tirM in $tirTokenRe.Matches($tirLine)) {
                        $tirTokenCount++
                        if (-not $tirIdMap.ContainsKey($tirM.Value)) {
                            $tirPhantomCount++
                            Add-CheckResult "WARNING" "TaskIdRefs" "$tirRel`:$tirLineNo" "Phantom task id $($tirM.Value): assigned to no task file"
                        }
                    }
                    foreach ($tirP in $tirPairRe.Matches($tirLine)) {
                        $tirCitedId = $tirP.Groups[2].Value
                        $tirNorm = Get-TirNormalizedTaskName $tirP.Groups[1].Value
                        # The name capture is left-greedy and may swallow leading sentence text
                        # ("Escalate friction via Bug Triage"), so resolve by longest known-title
                        # SUFFIX, with an exact match preferred. A phrase ending in no known
                        # title is simply not checked (precision-first).
                        $tirExpectedId = $null
                        if ($tirNameMap.ContainsKey($tirNorm)) {
                            $tirExpectedId = $tirNameMap[$tirNorm]
                        } else {
                            $tirBestKey = $null
                            foreach ($tirK in $tirNameMap.Keys) {
                                if ($tirNorm.EndsWith(" $tirK") -and ($null -eq $tirBestKey -or $tirK.Length -gt $tirBestKey.Length)) { $tirBestKey = $tirK }
                            }
                            if ($tirBestKey) { $tirExpectedId = $tirNameMap[$tirBestKey] }
                        }
                        if ($tirExpectedId -and $tirExpectedId -ne $tirCitedId) {
                            $tirMismatchCount++
                            $tirActual = if ($tirIdMap.ContainsKey($tirCitedId)) { $tirIdMap[$tirCitedId] } else { "no task" }
                            Add-CheckResult "WARNING" "TaskIdRefs" "$tirRel`:$tirLineNo" "Task name/id mismatch: '$($tirIdMap[$tirExpectedId])' declares $tirExpectedId but is cited as $tirCitedId (= $tirActual)"
                        }
                    }
                }
            }
        }
        Set-SurfaceExamined "TaskIdRefs" $tirTokenCount
        if ($tirTokenCount -eq 0) {
            Add-AbsentTargetResult "WARNING" "TaskIdRefs" "blueprint/process-framework/" "authored framework tree present but no task-id (*-TSK) references found"
        } elseif ($tirPhantomCount -eq 0 -and $tirMismatchCount -eq 0) {
            Add-CheckResult "OK" "TaskIdRefs" "authored framework prose" "All $tirTokenCount task-id references resolve ($($tirIdMap.Count) known task ids)"
        }
        Write-Host "  Checked $tirTokenCount task-id reference(s): $tirPhantomCount phantom, $tirMismatchCount name/id mismatch" -ForegroundColor Gray
        Write-Host ""
    }
}

# =========================================================================
# Summary
# =========================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Total checks: $totalChecks" -ForegroundColor Gray
Write-Host "  Passed:       $passCount" -ForegroundColor $(if ($passCount -gt 0) { "Green" } else { "Gray" })
Write-Host "  Errors:       $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Red" })
$warningsLabel = if ($detailOnlyHiddenCount -gt 0) { "$warningCount ($detailOnlyHiddenCount hidden — use -Detailed to view)" } else { "$warningCount" }
Write-Host "  Warnings:     $warningsLabel" -ForegroundColor $(if ($warningCount -eq 0) { "Green" } else { "Yellow" })

# Guard: -Surface was set but matched no surface (typo / unknown name / comma-quoting issue).
# Without this, totalChecks=0 falls through to "All checks passed!" → CI false positive.
if ($totalChecks -eq 0 -and -not $runAll) {
    Write-Host ""
    Write-Host "  No surfaces matched -Surface argument(s): $($Surface -join ', ')" -ForegroundColor Red
    Write-Host "  Check spelling, or use -Surface All. Valid surface names are listed in the script's .DESCRIPTION." -ForegroundColor Red
    Complete-Run -ExitCode 1
}

# =========================================================================
# Per-surface coverage report (PF-IMP-1209: X-1 / A-1).
# Makes "this surface recorded nothing" visible instead of folding it into a blanket
# "All checks passed!". $silentSurfaces also qualifies the final green verdict below.
# =========================================================================
$selectedSurfaces = if ($runAll) { $CanonicalSurfaces } else { @($CanonicalSurfaces | Where-Object { $Surface -contains $_ }) }
# PF-IMP-1209 remainder: "examined N" is the faithful coverage denominator. A surface is "silent"
# (a coverage gap) only when it examined 0 instances — NOT merely when it recorded 0 findings
# (examined N>0, recorded 0 = a clean pass). Surfaces not yet instrumented with Set-SurfaceExamined
# fall back to their Add-CheckResult call count.
$silentSurfaces = @($selectedSurfaces | Where-Object {
    $e = if ($surfaceExamined.Contains($_)) { [int]$surfaceExamined[$_] }
         elseif ($surfaceRecorded.Contains($_)) { [int]$surfaceRecorded[$_] }
         else { 0 }
    $e -eq 0
})
if ($Detailed -and $selectedSurfaces.Count -gt 0) {
    Write-Host ""
    Write-Host "  Per-surface coverage (examined / recorded):" -ForegroundColor Gray
    foreach ($s in $selectedSurfaces) {
        $e = if ($surfaceExamined.Contains($s)) { [int]$surfaceExamined[$s] }
             elseif ($surfaceRecorded.Contains($s)) { [int]$surfaceRecorded[$s] }
             else { 0 }
        $r = if ($surfaceRecorded.Contains($s)) { [int]$surfaceRecorded[$s] } else { 0 }
        $color = if ($e -eq 0) { "DarkYellow" } else { "Gray" }
        Write-Host ("    {0,-26} examined {1,4}, recorded {2,4}" -f $s, $e, $r) -ForegroundColor $color
    }
}
if ($silentSurfaces.Count -gt 0) {
    Write-Host ""
    Write-Host "  Coverage note: $($silentSurfaces.Count) of $($selectedSurfaces.Count) selected surface(s) examined 0 instances: $($silentSurfaces -join ', ')" -ForegroundColor DarkYellow
    Write-Host "  (examined-nothing is a coverage gap, not a clean pass — verify these had targets to check; use -Detailed for full per-surface counts)" -ForegroundColor DarkYellow
}

# =========================================================================
# Baseline compare (-Baseline): delta this run's errors against a saved baseline.
# Exit code becomes delta-based — 1 only on NEW errors (pre-existing debt passes).
# =========================================================================
$newErrors = $null
if (-not [string]::IsNullOrWhiteSpace($Baseline)) {
    if (-not (Test-Path $Baseline)) {
        Write-Host ""
        Write-Host "  Baseline file not found: $Baseline" -ForegroundColor Red
        exit 1
    }
    try {
        $baselineData = Get-Content $Baseline -Raw | ConvertFrom-Json
    } catch {
        Write-Host ""
        Write-Host "  Baseline file is not valid JSON: $Baseline" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "  Baseline comparison ($(Split-Path $Baseline -Leaf), saved $($baselineData.saved))" -ForegroundColor Cyan

    $normCurrentRoot  = "$ProjectRoot".TrimEnd('\', '/')
    $normBaselineRoot = "$($baselineData.projectRoot)".TrimEnd('\', '/')
    if ($normBaselineRoot -ne $normCurrentRoot) {
        Write-Host "  $([char]0x26A0)  Baseline was saved for a different project root ($normBaselineRoot) - comparison may be meaningless" -ForegroundColor Yellow
    }
    $baselineSurfaces = (@($baselineData.surfaces) | Sort-Object) -join ','
    $currentSurfaces  = (@($Surface) | Sort-Object) -join ','
    if ($baselineSurfaces -ne $currentSurfaces) {
        Write-Host "  $([char]0x26A0)  Baseline surface selection ($baselineSurfaces) differs from this run ($currentSurfaces) - delta may be incomplete" -ForegroundColor Yellow
    }

    $baselineSet = [System.Collections.Generic.HashSet[string]]::new([string[]]@($baselineData.errors | Where-Object { $_ }))
    $currentSet  = [System.Collections.Generic.HashSet[string]]::new([string[]]$errorFingerprints)
    $newErrors   = @($errorFingerprints | Where-Object { -not $baselineSet.Contains($_) } | Select-Object -Unique)
    $resolved    = @($baselineSet | Where-Object { -not $currentSet.Contains($_) })
    $preExisting = $currentSet.Count - $newErrors.Count

    # PF-IMP-1214: capture the baseline delta for the optional JSON summary.
    $script:jsonBaseline = [ordered]@{
        file          = (Split-Path $Baseline -Leaf)
        newErrors     = @($newErrors)
        newErrorCount = @($newErrors).Count
        preExisting   = $preExisting
        resolved      = @($resolved).Count
    }

    Write-Host "  New errors:          $($newErrors.Count)" -ForegroundColor $(if ($newErrors.Count -eq 0) { "Green" } else { "Red" })
    Write-Host "  Pre-existing errors: $preExisting" -ForegroundColor Gray
    Write-Host "  Resolved errors:     $($resolved.Count)" -ForegroundColor $(if ($resolved.Count -gt 0) { "Green" } else { "Gray" })
    foreach ($fp in $newErrors) {
        Write-Host "    $([char]0x274C) NEW: $fp" -ForegroundColor Red
    }
}

# =========================================================================
# Baseline save (-SaveBaseline): write this run's error fingerprints for a later
# -Baseline comparison. Auto-named per session (timestamp + PID) so parallel sessions
# never collide; 3-day retention prune keeps the dir self-cleaning.
# =========================================================================
if ($SaveBaseline) {
    $baselineDir = Get-ValidatorTempDir -Kind 'vst-baselines' -Root $ProjectRoot
    New-Item -ItemType Directory -Path $baselineDir -Force | Out-Null

    # Retention: the validator owns cleanup — prune baselines older than 3 days on every save.
    # Safe to prune by age alone only because the directory is workspace-scoped (PF-IMP-1984);
    # in the former shared directory this deleted other workspaces' baselines.
    Get-ChildItem -Path $baselineDir -Filter "vst-baseline-*.json" -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) } |
        Remove-Item -Force -ErrorAction SilentlyContinue

    $projectName  = (Split-Path $ProjectRoot -Leaf) -replace '[^\w\-]', '-'
    $baselineFile = Join-Path $baselineDir ("vst-baseline-{0}-{1}-{2}.json" -f $projectName, (Get-Date -Format 'yyyyMMdd-HHmmss'), $PID)
    [ordered]@{
        schema      = 1
        saved       = (Get-Date -Format 'o')
        projectRoot = "$ProjectRoot"
        surfaces    = @($Surface)
        errorCount  = $errorCount
        errors      = @($errorFingerprints)
    } | ConvertTo-Json -Depth 4 | Set-Content -Path $baselineFile -Encoding UTF8

    Write-Host ""
    Write-Host "  Baseline saved: $baselineFile" -ForegroundColor Cyan
    Write-Host "  Compare after your change with: -Baseline `"$baselineFile`"" -ForegroundColor Gray
}

# Delta-based exit when -Baseline was supplied: only NEW errors fail the run.
if ($null -ne $newErrors) {
    if ($newErrors.Count -eq 0) {
        Write-Host ""
        Write-Host "  No new errors vs baseline." -ForegroundColor Green
        Complete-Run -ExitCode 0
    } else {
        Write-Host ""
        Write-Host "  Validation failed: $($newErrors.Count) new error(s) vs baseline." -ForegroundColor Red
        Complete-Run -ExitCode 1
    }
}

if ($errorCount -eq 0 -and $warningCount -eq 0) {
    Write-Host ""
    if (@($silentSurfaces).Count -gt 0) {
        Write-Host "  No errors or warnings — but $(@($silentSurfaces).Count) selected surface(s) recorded no findings (see coverage note above)." -ForegroundColor Green
    } else {
        Write-Host "  All checks passed!" -ForegroundColor Green
    }
    Complete-Run -ExitCode 0
} elseif ($errorCount -eq 0) {
    Write-Host ""
    Write-Host "  Passed with warnings." -ForegroundColor Yellow
    Complete-Run -ExitCode 0
} else {
    Write-Host ""
    Write-Host "  Validation failed." -ForegroundColor Red
    Complete-Run -ExitCode 1
}
