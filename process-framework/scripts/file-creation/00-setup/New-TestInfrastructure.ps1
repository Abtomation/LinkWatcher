# New-TestInfrastructure.ps1
# Dual-mode script for test/audit directory infrastructure:
#   -Scaffold : initial language-specific bootstrap on top of a blueprint-copied test/ tree (existing behavior)
#   -Update   : feature-tracking + workflow-tracking-driven scaffolding of variable test/audit subdirs
#               (PF-IMP-871 / PF-PRO-034 — Test and Audit Infrastructure Reorganization, Phase 2b skeleton)

<#
.SYNOPSIS
    Dual-mode infrastructure script for test/audit directories.

.DESCRIPTION
    The script operates in one of two mutually exclusive modes:

    -Scaffold (default, back-compat with existing Project Initiation step 11):
        Applies the language-specific layer (fixtures, package markers, E2E .gitignore) on top of a
        blueprint-copied test/ tree. Idempotently ensures structural directories exist for projects
        not initialized from the blueprint. Tracking files and the TE-id-registry are NOT created
        here — those come from the blueprint copy.

        Note (2026-05-14, PF-IMP-871): the hardcoded auto-add of "integration" to TestCategories was
        removed because `test/automated/integration/` is no longer part of the framework's test layout.

    -Update (added 2026-05-14, PF-IMP-871 / PF-PRO-034 Phase 2b — skeleton only):
        Reads feature-tracking.md (categories + subgroups) and user-workflow-tracking.md (workflows)
        and idempotently scaffolds the VARIABLE parts of the test tree:
            test/automated/unit/<N>-<slug>/             + test/audits/unit/<N>-<slug>/
            test/e2e-acceptance-testing/<workflow>/...  + test/audits/e2e/<workflow>/
        Fixed parts (test-type buckets, perf levels 1-4, top-level e2e/bug-validation/audits) are
        BLUEPRINT-PROVIDED via .gitkeep markers — this mode does not recreate them.

        Phase status:
          - Phase 3a (unit feature-category scaffolding): complete (2026-05-14)
          - Phase 3b (performance 4-level fixed-bone recovery): complete (2026-05-14) — Section B
              loop IS the canonical implementation; no parser needed (levels are framework-fixed,
              not project-driven)
          - Phase 3c1 (e2e workflow scaffolding): complete (2026-05-14) — Get-WorkflowsFromTracking
              parses WF-NNN rows from user-workflow-tracking.md; Section C scaffolds per-workflow
              templates/workspace/results subdirs (templates gets .gitkeep; workspace/results are
              gitignored runtime dirs) and the audits/e2e/<slug>/ mirror
          - Phase 3d (bug-validation top-level relocation): complete (2026-05-14) — Section D
              eager-recovery for the framework-fixed `test/bug-validation/.gitkeep` (moved from
              `test/automated/bug-validation/` in Phase 2b); Scaffold mode also seeds the dir for
              non-blueprint-bootstrapped projects
          - Phase 4a (regeneration of derived artifacts): complete (2026-05-15) — Section E
              regenerates `TE-id-registry.json` (TE-TAR.directories + TE-TST.directories from
              filesystem) and `audits/README.md` (minimal generated index with GENERATED FILE
              banner + dir-tree snapshot). Both writes idempotent — registry written only on
              change, README compared modulo timestamp line

    Mirrors the dual-mode shape of New-SourceStructure.ps1 (-Scaffold/-Update precedent, PF-PRO-002).

.PARAMETER Language
    (Scaffold mode, required) Project language matching a subdir under
    process-framework/languages-config/. Examples: "python", "javascript", "dart".

.PARAMETER TestCategories
    (Scaffold mode, optional) Override default test categories. If omitted, uses quickCategories
    from project-config.json. "unit" is auto-prepended if missing. Integration is NOT auto-added.

.PARAMETER ProjectName
    (Scaffold mode, optional) Override project name. Default: project.name from project-config.json.

.PARAMETER Update
    (Update mode, required to select Update mode) Switch that selects the feature-tracking-driven
    scaffolding mode.

.PARAMETER FeatureTrackingFile
    (Update mode, optional) Override the auto-detected feature-tracking.md path. Used by
    synthetic-fixture tests.

.PARAMETER WorkflowTrackingFile
    (Update mode, optional) Override the auto-detected user-workflow-tracking.md path. Used by
    synthetic-fixture tests.

.PARAMETER WhatIf
    Standard ShouldProcess support — show what would change without acting.

.PARAMETER Confirm
    Standard ShouldProcess support — prompt before each action.

.EXAMPLE
    .\New-TestInfrastructure.ps1 -Language "python"

.EXAMPLE
    .\New-TestInfrastructure.ps1 -Language "python" -TestCategories @("unit", "api")

.EXAMPLE
    .\New-TestInfrastructure.ps1 -Update

.NOTES
    - Requires doc/project-config.json (run Project Initiation first)
    - Update mode also requires feature-tracking.md (and optionally user-workflow-tracking.md)
    - Safe to re-run: idempotent in both modes
    - Used during Project Initiation (PF-TSK-059) Step 11 (Scaffold)
    - Chained from Update-FeatureCategory.ps1 + New-FeatureImplementationState.ps1 + New-WorkflowEntry.ps1 (Update; Phases 3a/3c1 wiring)

    Script Type: Test Infrastructure Scaffolding (dual-mode)
    Created: 2026-03-26 (Scaffold)
    Updated: 2026-05-14 (Update mode skeleton — PF-IMP-871 Phase 2b)
    Updated: 2026-05-14 (Phase 3a — unit feature-category parser + nested scaffolding)
    Updated: 2026-05-14 (Phase 3b — confirmed Section B fulfils perf 4-level scaffolding;
                         documentation/comment closeout only, no functional change)
    Updated: 2026-05-14 (Phase 3c1 — Get-WorkflowsFromTracking parser implemented;
                         Section C scaffolds per-workflow e2e subdirs + audit mirror)
    Updated: 2026-05-14 (Phase 3d — Section D eager-recovers `test/bug-validation/.gitkeep`;
                         Scaffold mode also seeds the dir for non-blueprint projects)
    Updated: 2026-05-15 (Phase 4a — Section E regenerates TE-id-registry.json
                         TE-TAR.directories + TE-TST.directories + audits/README.md)
#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Scaffold')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Scaffold')]
    [string]$Language,

    [Parameter(Mandatory = $false, ParameterSetName = 'Scaffold')]
    [string[]]$TestCategories,

    [Parameter(Mandatory = $false, ParameterSetName = 'Scaffold')]
    [string]$ProjectName,

    [Parameter(Mandatory = $true, ParameterSetName = 'Update')]
    [switch]$Update,

    [Parameter(Mandatory = $false, ParameterSetName = 'Update')]
    [string]$FeatureTrackingFile = "",

    [Parameter(Mandatory = $false, ParameterSetName = 'Update')]
    [string]$WorkflowTrackingFile = "",

    [Parameter(Mandatory = $false, ParameterSetName = 'Update')]
    [string]$TestRoot = ""
)

# --- Module Import ---
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
if ($dir) {
    $prevVerbosePreference = $VerbosePreference
    $VerbosePreference = 'SilentlyContinue'
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
    $VerbosePreference = $prevVerbosePreference
} else {
    Write-Error "Could not find Common-ScriptHelpers.psm1"
    exit 1
}

# Naming module (Update mode uses New-FeatureDirSlug)
$namingModule = Join-Path $dir "Common-ScriptHelpers/Naming.psm1"
if (Test-Path $namingModule) {
    Import-Module $namingModule -Force -Verbose:$false
}

# --- Standard Initialization ---
try {
    Invoke-StandardScriptInitialization
} catch {
    Write-Warning "Standard initialization not available, proceeding with basic setup"
    $ErrorActionPreference = "Stop"
}

# --- Get Project Root ---
$projectRoot = Get-ProjectRoot

# =========================================================================
# Update-mode skeleton parsing helpers (Phase 2b stubs — Phases 3a/3c1 implement)
# Declared early so the Update branch below can call them.
# =========================================================================

function Get-FeatureCategoriesFromTracking {
    <#
    .SYNOPSIS
        Parses feature-tracking.md and returns level-1 categories + level-2 subgroups
        with parent-child linkage for nested directory scaffolding.

    .DESCRIPTION
        Returns an array of [PSCustomObject]@{ Id; Name; Level; ParentId } where:
          - Level=1 entries are top-level categories from `<details><summary><strong>N. Name</strong></summary>` blocks
              (Id="N", ParentId="" )
          - Level=2 entries are subgroups under those categories from `### N.X Name` headings
              (Id="N.X", ParentId="N")

        Level-3 feature rows are NOT returned — those live inside subgroup tables and are
        file-granularity rather than directory-granularity in the new test-tree scheme.

        Parser is adapted from Update-FeatureCategory.ps1 lines 191-230 (same regex anchors
        and category/subgroup detection logic).

    .PARAMETER Path
        Path to feature-tracking.md. Returns @() if path is empty / file does not exist
        / `## Feature Categories` section is missing.

    .NOTES
        Implementation: PF-IMP-871 / PF-PRO-034 Phase 3a (2026-05-14).
    #>
    param([string]$Path)

    if ([string]::IsNullOrEmpty($Path) -or -not (Test-Path $Path)) {
        return @()
    }

    $content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content)) {
        return @()
    }
    $lines = $content -split "`r?`n"

    # Locate the `## Feature Categories` section boundaries
    $startIdx = -1
    $endIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## Feature Categories\s*$') {
            $startIdx = $i
        } elseif ($lines[$i] -match '^## Archived Features\s*$' -and $startIdx -ge 0) {
            $endIdx = $i
            break
        }
    }
    if ($startIdx -lt 0) { return @() }
    # If `## Archived Features` is absent, scan to end of file
    if ($endIdx -lt 0) { $endIdx = $lines.Count }

    $results = @()
    $inCategory = $false
    $currentCatId = $null
    $currentCatName = $null

    for ($i = $startIdx; $i -lt $endIdx; $i++) {
        $line = $lines[$i]
        if (-not $inCategory) {
            if ($line -match '^<details>\s*$') {
                $nextLine = if ($i + 1 -lt $lines.Count) { $lines[$i + 1] } else { '' }
                if ($nextLine -match '^<summary><strong>(\d+)\.\s+(.+?)</strong></summary>\s*$') {
                    $currentCatId = $matches[1]
                    $currentCatName = $matches[2]
                    $results += [PSCustomObject]@{
                        Id       = $currentCatId
                        Name     = $currentCatName
                        Level    = 1
                        ParentId = ""
                    }
                    $inCategory = $true
                }
            }
        } else {
            if ($line -match '^</details>\s*$') {
                $inCategory = $false
                $currentCatId = $null
                $currentCatName = $null
            } elseif ($line -match '^### (\d+)\.(\d+)\s+(.+?)\s*$') {
                $subCatNum = $matches[1]
                $subNum = $matches[2]
                $subName = $matches[3]
                # Only record subgroups under the currently-open category (defensive — ID consistency)
                if ($subCatNum -eq $currentCatId) {
                    $results += [PSCustomObject]@{
                        Id       = "$subCatNum.$subNum"
                        Name     = $subName
                        Level    = 2
                        ParentId = $currentCatId
                    }
                }
            }
        }
    }

    return $results
}

function Get-WorkflowsFromTracking {
    <#
    .SYNOPSIS
        Parses user-workflow-tracking.md and returns one entry per WF-NNN row in the Workflows table.

    .DESCRIPTION
        Returns an array of [PSCustomObject]@{ Id; Name } where:
          - Id   = "WF-NNN" (from column 1 of the Workflows table)
          - Name = the workflow name from column 2 (e.g. "Single file move → links updated")

        Anchors on the `## Workflows` heading and stops at the next `## ` heading. Rows are
        identified by the pattern `^\|\s*(WF-\d+)\s*\|\s*(.+?)\s*\|`. Header and separator
        rows are skipped because they don't start with `| WF-`.

        Workflow names commonly contain `→` and other non-alphanumeric characters; slug
        derivation happens in the caller via `ConvertTo-FeatureSlug -Convention kebab-case`.

    .PARAMETER Path
        Path to user-workflow-tracking.md. Returns @() if the path is empty, the file does
        not exist, or no WF-NNN rows are present.

    .NOTES
        Implementation: PF-IMP-871 / PF-PRO-034 Phase 3c1 (2026-05-14). Parser only — Section C
        consumes the result.
    #>
    param([string]$Path)

    if ([string]::IsNullOrEmpty($Path) -or -not (Test-Path $Path)) {
        return @()
    }

    $content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content)) {
        return @()
    }
    $lines = $content -split "`r?`n"

    # Locate the `## Workflows` section boundary
    $startIdx = -1
    $endIdx = $lines.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## Workflows\s*$') {
            $startIdx = $i
        } elseif ($startIdx -ge 0 -and $lines[$i] -match '^## ' -and $lines[$i] -notmatch '^## Workflows\s*$') {
            $endIdx = $i
            break
        }
    }
    if ($startIdx -lt 0) { return @() }

    $results = @()
    for ($i = $startIdx; $i -lt $endIdx; $i++) {
        if ($lines[$i] -match '^\|\s*(WF-\d+)\s*\|\s*(.+?)\s*\|') {
            $results += [PSCustomObject]@{
                Id   = $matches[1]
                Name = $matches[2]
            }
        }
    }
    return $results
}

# =========================================================================
# UPDATE MODE (PF-IMP-871 Phase 2b skeleton)
# =========================================================================
if ($PSCmdlet.ParameterSetName -eq 'Update') {

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  New-TestInfrastructure.ps1 -Update" -ForegroundColor Cyan
    Write-Host "  Mode: feature-tracking + workflow-tracking-driven scaffolding" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # Soak verification (PF-PRO-028 v2.0 Pattern A; caller-aware no-arg form)
    Register-SoakScript
    $soakInSoak = Test-ScriptInSoak

    try {
        # --- Resolve config-driven test root ---
        # Reads paths.tests from project-config.json (default "test"). For appdev (PRJ-000), Phase 3a
        # of the Framework Self-Testing extension set paths.tests = "test" so appdev's own framework-
        # self-test tree at appdev/test/ is the target. Scripts that explicitly need the blueprint
        # test template should hardcode "blueprint/test/..." rather than going through this resolver.
        # Refactored 2026-05-17 (Framework Self-Testing PF-PRO-035, Phase 3a-continuation) — replaced
        # the PRJ-000 → blueprint/test/ hardcoding with config-driven lookup. See Resolve-DocPath
        # docstring for the parallel rationale.
        if ([string]::IsNullOrEmpty($TestRoot)) {
            $projectConfigPath = Join-Path $projectRoot "doc/project-config.json"
            $testsPath = "test"
            if (Test-Path $projectConfigPath) {
                $cfg = Get-Content $projectConfigPath -Raw | ConvertFrom-Json
                if ($cfg.paths -and $cfg.paths.tests) {
                    $testsPath = $cfg.paths.tests
                }
            }
            $TestRoot = Join-Path $projectRoot $testsPath
        }
        Write-Host "  Test root: $TestRoot" -ForegroundColor Gray

        # --- Resolve tracking file paths ---
        if ([string]::IsNullOrEmpty($FeatureTrackingFile)) {
            try {
                $FeatureTrackingFile = Resolve-DocPath -Subpath "state-tracking/permanent/feature-tracking.md"
            } catch {
                Write-Verbose "Resolve-DocPath failed for feature-tracking.md: $($_.Exception.Message)"
                $FeatureTrackingFile = ""
            }
        }
        if ([string]::IsNullOrEmpty($WorkflowTrackingFile)) {
            try {
                $WorkflowTrackingFile = Resolve-DocPath -Subpath "state-tracking/permanent/user-workflow-tracking.md"
            } catch {
                Write-Verbose "Resolve-DocPath failed for user-workflow-tracking.md: $($_.Exception.Message)"
                $WorkflowTrackingFile = ""
            }
        }
        Write-Host "  Feature tracking: $FeatureTrackingFile" -ForegroundColor Gray
        Write-Host "  Workflow tracking: $WorkflowTrackingFile" -ForegroundColor Gray
        Write-Host ""

        $changesCount = 0

        # =====================================================================
        # Section A: Unit feature-category scaffolding (PF-IMP-871 Phase 3a)
        # =====================================================================
        # Layout (option C nested, per user decision 2026-05-14):
        #   - Level-1 category "1. Customer Management" → `unit/1-customer-management/`
        #   - Level-2 subgroup  "1.2 Customer Read"     → `unit/1-customer-management/1-2-customer-read/`
        #   - Same nested structure mirrored under `audits/unit/`.
        # Subgroup dirs use the full ID-prefix slug ("1-2-customer-read"), keeping the
        # leaf-name globally unambiguous regardless of nesting depth.
        # =====================================================================
        Write-Host "Section A: Unit feature-category scaffolding..." -ForegroundColor Yellow

        $categories = Get-FeatureCategoriesFromTracking -Path $FeatureTrackingFile

        if ($categories.Count -eq 0) {
            Write-Host "  No categories found" -ForegroundColor DarkGray
        } else {
            # Pre-compute parent slugs so level-2 entries can resolve their parent dir name
            $parentSlugMap = @{}
            foreach ($cat in ($categories | Where-Object { $_.Level -eq 1 })) {
                $parentSlugMap[$cat.Id] = New-FeatureDirSlug -Id $cat.Id -Name $cat.Name
            }

            foreach ($cat in $categories) {
                $slug = New-FeatureDirSlug -Id $cat.Id -Name $cat.Name
                if ($cat.Level -eq 1) {
                    $relUnit  = "automated/unit/$slug"
                    $relAudit = "audits/unit/$slug"
                } elseif ($cat.Level -eq 2) {
                    $parentSlug = $parentSlugMap[$cat.ParentId]
                    if ([string]::IsNullOrEmpty($parentSlug)) {
                        Write-Host "  [SKIP] Subgroup $($cat.Id) '$($cat.Name)' has no parent slug; parent category $($cat.ParentId) not parsed" -ForegroundColor Yellow
                        continue
                    }
                    $relUnit  = "automated/unit/$parentSlug/$slug"
                    $relAudit = "audits/unit/$parentSlug/$slug"
                } else {
                    continue
                }

                $unitDir  = Join-Path $TestRoot $relUnit
                $auditDir = Join-Path $TestRoot $relAudit
                foreach ($d in @($unitDir, $auditDir)) {
                    if (-not (Test-Path $d)) {
                        if ($PSCmdlet.ShouldProcess($d, "Create unit dir for L$($cat.Level) '$($cat.Name)' ($($cat.Id))")) {
                            New-Item -ItemType Directory -Path $d -Force | Out-Null
                            New-Item -ItemType File -Path (Join-Path $d ".gitkeep") -Force | Out-Null
                            Write-Host "  [CREATED] $d" -ForegroundColor Green
                            $changesCount++
                        }
                    } else {
                        Write-Host "  [EXISTS] $d" -ForegroundColor DarkGray
                    }
                }
            }
        }
        Write-Host ""

        # =====================================================================
        # Section B: Performance 4-level scaffolding (PF-IMP-871 Phase 3b — complete)
        # =====================================================================
        # The 4-level perf taxonomy is framework-fixed (Component / Operation / Scale / Resource —
        # see guides/03-testing/performance-testing-guide.md). Blueprint provides the dirs with
        # `.gitkeep` markers; this loop is the recovery path that recreates them if deleted.
        # No parser is needed — the level list IS the canonical implementation.
        # =====================================================================
        Write-Host "Section B: Performance 4-level scaffolding (blueprint-provided fixed bones)..." -ForegroundColor Yellow
        $perfLevels = @('level1-component', 'level2-operation', 'level3-scale', 'level4-resource')
        foreach ($lvl in $perfLevels) {
            foreach ($side in @('automated', 'audits')) {
                $perfDir = Join-Path $TestRoot "$side/performance/$lvl"
                if (-not (Test-Path $perfDir)) {
                    if ($PSCmdlet.ShouldProcess($perfDir, "Create perf level dir")) {
                        New-Item -ItemType Directory -Path $perfDir -Force | Out-Null
                        New-Item -ItemType File -Path (Join-Path $perfDir ".gitkeep") -Force | Out-Null
                        Write-Host "  [CREATED] $perfDir (recovered missing fixed-bone)" -ForegroundColor Yellow
                        $changesCount++
                    }
                }
            }
        }
        Write-Host ""

        # =====================================================================
        # Section C: E2E workflow scaffolding (PF-IMP-871 Phase 3c1 — complete)
        # =====================================================================
        # Per-workflow layout (driven by user-workflow-tracking.md WF-NNN rows):
        #   test/e2e-acceptance-testing/<workflow-slug>/templates/.gitkeep   (git-tracked)
        #   test/e2e-acceptance-testing/<workflow-slug>/workspace/           (gitignored runtime)
        #   test/e2e-acceptance-testing/<workflow-slug>/results/             (gitignored runtime)
        #   test/audits/e2e/<workflow-slug>/.gitkeep                         (audit mirror)
        #
        # .gitkeep is ONLY in templates/ and the audit dir — workspace/ and results/ are
        # gitignored by test/e2e-acceptance-testing/.gitignore, so a .gitkeep there would
        # be ignored too. The dirs still get created for runtime convenience (Setup-/Verify-
        # scripts append into them).
        # =====================================================================
        Write-Host "Section C: E2E workflow scaffolding..." -ForegroundColor Yellow

        $workflows = Get-WorkflowsFromTracking -Path $WorkflowTrackingFile

        if ($workflows.Count -eq 0) {
            Write-Host "  No workflows found" -ForegroundColor DarkGray
        } else {
            foreach ($wf in $workflows) {
                $slug = ConvertTo-FeatureSlug -Name $wf.Name -Convention kebab-case
                if ([string]::IsNullOrEmpty($slug)) {
                    Write-Host "  [SKIP] Workflow $($wf.Id) '$($wf.Name)' produces empty slug" -ForegroundColor Yellow
                    continue
                }
                $e2eBase = Join-Path $TestRoot "e2e-acceptance-testing/$slug"
                $auditE2eDir = Join-Path $TestRoot "audits/e2e/$slug"

                # Subdir scaffolding — templates/ gets .gitkeep, workspace/results are gitignored runtime
                $subdirSpec = @(
                    @{ Name = 'templates'; GitKeep = $true },
                    @{ Name = 'workspace'; GitKeep = $false },
                    @{ Name = 'results';   GitKeep = $false }
                )
                foreach ($spec in $subdirSpec) {
                    $d = Join-Path $e2eBase $spec.Name
                    if (-not (Test-Path $d)) {
                        if ($PSCmdlet.ShouldProcess($d, "Create e2e workflow subdir '$($spec.Name)' for $($wf.Id)")) {
                            New-Item -ItemType Directory -Path $d -Force | Out-Null
                            if ($spec.GitKeep) {
                                New-Item -ItemType File -Path (Join-Path $d ".gitkeep") -Force | Out-Null
                            }
                            Write-Host "  [CREATED] $d" -ForegroundColor Green
                            $changesCount++
                        }
                    } else {
                        Write-Host "  [EXISTS] $d" -ForegroundColor DarkGray
                    }
                }

                # Audit mirror
                if (-not (Test-Path $auditE2eDir)) {
                    if ($PSCmdlet.ShouldProcess($auditE2eDir, "Create audit e2e dir for $($wf.Id)")) {
                        New-Item -ItemType Directory -Path $auditE2eDir -Force | Out-Null
                        New-Item -ItemType File -Path (Join-Path $auditE2eDir ".gitkeep") -Force | Out-Null
                        Write-Host "  [CREATED] $auditE2eDir" -ForegroundColor Green
                        $changesCount++
                    }
                } else {
                    Write-Host "  [EXISTS] $auditE2eDir" -ForegroundColor DarkGray
                }
            }
        }
        Write-Host ""

        # =====================================================================
        # Section D: Bug-validation top-level scaffolding (PF-IMP-871 Phase 3d — complete)
        # =====================================================================
        # `test/bug-validation/` is a framework-fixed bone (relocated from `test/automated/
        # bug-validation/` in Phase 2b). The blueprint provides the dir with a `.gitkeep`
        # marker; this is the recovery path that recreates it if deleted. No parser is needed
        # — there is exactly one dir, and it is not project-driven (every project gets the
        # same flat dir; per-bug subdirs are not part of this scaffolding contract).
        # =====================================================================
        Write-Host "Section D: Bug-validation scaffolding (blueprint-provided fixed bone)..." -ForegroundColor Yellow
        $bugValidationDir = Join-Path $TestRoot "bug-validation"
        if (-not (Test-Path $bugValidationDir)) {
            if ($PSCmdlet.ShouldProcess($bugValidationDir, "Create bug-validation dir")) {
                New-Item -ItemType Directory -Path $bugValidationDir -Force | Out-Null
                New-Item -ItemType File -Path (Join-Path $bugValidationDir ".gitkeep") -Force | Out-Null
                Write-Host "  [CREATED] $bugValidationDir (recovered missing fixed-bone)" -ForegroundColor Yellow
                $changesCount++
            }
        } else {
            Write-Host "  [EXISTS] $bugValidationDir" -ForegroundColor DarkGray
        }
        Write-Host ""

        # =====================================================================
        # Section E: Regeneration of derived artifacts (PF-IMP-871 Phase 4a — Step 30)
        # =====================================================================
        # After the variable scaffolding (Sections A/C) and fixed-bone recovery (Sections B/D)
        # finish, regenerate two derivatives from the filesystem state:
        #
        #   1. TE-id-registry.json — `TE-TAR.directories` and `TE-TST.directories` maps
        #      become generated content derived from the actual top-level dirs under
        #      `audits/` and `automated/`. Phase 3a's path-transform routing in
        #      New-TestAuditReport.ps1 made the old hardcoded category keys
        #      (foundation/authentication/core-features for TE-TAR; integration/parsers
        #      for TE-TST) vestigial; this regen drops them.
        #
        #   2. audits/README.md — minimal generated index with a GENERATED FILE banner
        #      and a snapshot of the current audit dir tree. Provides a stable entry
        #      point for readers without becoming a stale manual-edit liability.
        #
        # Both writes are idempotent: TE-id-registry.json is rewritten only when the
        # computed maps differ from current content; audits/README.md is always
        # refreshed (the timestamp would change anyway).
        # =====================================================================
        Write-Host "Section E: Regenerate TE-id-registry.json + audits/README.md..." -ForegroundColor Yellow

        # --- 1. Compute fresh directory maps from filesystem ---
        $autoRoot = Join-Path $TestRoot "automated"
        $auditRoot = Join-Path $TestRoot "audits"
        $auditDirs = @()
        $autoDirs = @()
        if (Test-Path $auditRoot) {
            $auditDirs = Get-ChildItem -Path $auditRoot -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { $_.Name } | Sort-Object
        }
        if (Test-Path $autoRoot) {
            $autoDirs = Get-ChildItem -Path $autoRoot -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { $_.Name } | Sort-Object
        }

        # Build ordered hashtable so the JSON output is deterministic
        $newTarDirs = [ordered]@{}
        foreach ($d in $auditDirs) { $newTarDirs[$d] = "test/audits/$d" }
        $newTarDirs['main'] = "test/audits"
        # Default key: prefer 'unit' if present, else first audit dir, else 'main'
        if ($auditDirs -contains 'unit') {
            $newTarDirs['default'] = 'unit'
        } elseif ($auditDirs.Count -gt 0) {
            $newTarDirs['default'] = $auditDirs[0]
        } else {
            $newTarDirs['default'] = 'main'
        }

        $newTstDirs = [ordered]@{}
        foreach ($d in $autoDirs) { $newTstDirs[$d] = "test/automated/$d" }
        if ($autoDirs -contains 'unit') {
            $newTstDirs['default'] = 'unit'
        } elseif ($autoDirs.Count -gt 0) {
            $newTstDirs['default'] = $autoDirs[0]
        } else {
            $newTstDirs['default'] = 'unit'
        }

        # --- 2. Update TE-id-registry.json if changed ---
        $registryPath = Join-Path $TestRoot "TE-id-registry.json"
        if (Test-Path $registryPath) {
            $registryRaw = Get-Content -Path $registryPath -Raw -Encoding UTF8
            $registry = $registryRaw | ConvertFrom-Json

            # Capture before-state for comparison
            $beforeJson = ($registry | ConvertTo-Json -Depth 10)

            # Replace TE-TAR.directories
            if ($registry.prefixes.PSObject.Properties.Name -contains 'TE-TAR') {
                $registry.prefixes.'TE-TAR'.directories = [PSCustomObject]$newTarDirs
            }
            # Replace TE-TST.directories
            if ($registry.prefixes.PSObject.Properties.Name -contains 'TE-TST') {
                $registry.prefixes.'TE-TST'.directories = [PSCustomObject]$newTstDirs
            }

            $afterJson = ($registry | ConvertTo-Json -Depth 10)
            if ($beforeJson -ne $afterJson) {
                if ($PSCmdlet.ShouldProcess($registryPath, "Regenerate TE-TAR.directories + TE-TST.directories")) {
                    $registry.metadata.updated = (Get-Date -Format 'yyyy-MM-dd')
                    # ConvertTo-Json on PowerShell 7+ produces 2-space indent by default,
                    # which already matches the existing TE-id-registry.json convention —
                    # no post-processing needed.
                    $out = $registry | ConvertTo-Json -Depth 10
                    Set-Content -Path $registryPath -Value $out -Encoding UTF8
                    Write-Host "  [UPDATED] $registryPath (TE-TAR.directories + TE-TST.directories regenerated)" -ForegroundColor Yellow
                    $changesCount++
                }
            } else {
                Write-Host "  [UNCHANGED] $registryPath (directory maps already current)" -ForegroundColor DarkGray
            }
        } else {
            Write-Host "  [SKIP] TE-id-registry.json not found at $registryPath" -ForegroundColor DarkGray
        }

        # --- 3. Regenerate audits/README.md ---
        if (Test-Path $auditRoot) {
            $readmePath = Join-Path $auditRoot "README.md"

            # Build directory tree snapshot (depth-3 sufficient for current shape)
            $treeLines = @("audits/")
            $topDirs = Get-ChildItem -Path $auditRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name
            for ($t = 0; $t -lt $topDirs.Count; $t++) {
                $isLastTop = ($t -eq $topDirs.Count - 1)
                $topMark = if ($isLastTop) { "└──" } else { "├──" }
                $topInnerPrefix = if ($isLastTop) { "    " } else { "│   " }
                $treeLines += "$topMark $($topDirs[$t].Name)/"

                $midDirs = Get-ChildItem -Path $topDirs[$t].FullName -Directory -ErrorAction SilentlyContinue | Sort-Object Name
                for ($m = 0; $m -lt $midDirs.Count; $m++) {
                    $isLastMid = ($m -eq $midDirs.Count - 1)
                    $midMark = if ($isLastMid) { "└──" } else { "├──" }
                    $midInnerPrefix = if ($isLastMid) { "    " } else { "│   " }
                    $treeLines += "$topInnerPrefix$midMark $($midDirs[$m].Name)/"

                    $leafDirs = Get-ChildItem -Path $midDirs[$m].FullName -Directory -ErrorAction SilentlyContinue | Sort-Object Name
                    for ($l = 0; $l -lt $leafDirs.Count; $l++) {
                        $isLastLeaf = ($l -eq $leafDirs.Count - 1)
                        $leafMark = if ($isLastLeaf) { "└──" } else { "├──" }
                        $treeLines += "$topInnerPrefix$midInnerPrefix$leafMark $($leafDirs[$l].Name)/"
                    }
                }
            }
            $treeBlock = $treeLines -join "`n"
            $generatedTs = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

            # Use single-quoted here-string (no variable interpolation, no backtick escaping)
            # and token-substitute via -replace afterwards. Markdown code-fences and backticks
            # render through unchanged.
            $readmeTemplate = @'
<!-- AUTO-GENERATED FILE — DO NOT EDIT MANUALLY -->
<!-- Source of truth: filesystem (test/audits/) -->
<!-- Regenerated by: process-framework/scripts/file-creation/00-setup/New-TestInfrastructure.ps1 -Update -->
<!-- Last regenerated: {{GENERATED_TS}} -->

# Test Audits Directory

Test audit reports for the project. Audit location mirrors test subject location:
the path of an audit dir is derived from the path of the audited test via pure path
transformation (`test/automated/<path>/` → `test/audits/<path>/`,
`test/e2e-acceptance-testing/<workflow>/` → `test/audits/e2e/<workflow>/`).

## Directory Structure (current snapshot)

```
{{TREE_BLOCK}}
```

## How Audits Get Placed

Audit reports are created by [New-TestAuditReport.ps1](../../process-framework/scripts/file-creation/03-testing/New-TestAuditReport.ps1).

- **Automated tests** (unit): audit path = test path with `automated/` → `audits/`
  segment swap. No feature-ID prefix switch (PF-IMP-871 Phase 3a refactor).
- **Performance tests**: audit reports go under `audits/performance/level{N}-*/`,
  mirroring the 4-level breakdown of `automated/performance/`.
- **E2E acceptance tests**: audit reports go under `audits/e2e/<workflow-slug>/`,
  mirroring the per-workflow layout of `e2e-acceptance-testing/`.

## Related Documentation

- [Test Audit Task (PF-TSK-030)](../../process-framework/tasks/03-testing/test-audit-task.md)
- [Test Tracking](../state-tracking/permanent/test-tracking.md)
- [New-TestAuditReport.ps1](../../process-framework/scripts/file-creation/03-testing/New-TestAuditReport.ps1)
- [Validate-AuditReport.ps1](../../process-framework/scripts/validation/Validate-AuditReport.ps1)
- Validate-StateTracking.ps1 Surfaces 16/17/18 — audit mirror invariant + category alignment + workflow alignment (PF-IMP-871 Phase 4a)

## File Naming Convention

```
audit-report-[FEATURE_ID]-[TEST_FILE_NAME].md
```

## ID Registry Integration

- **Prefix**: `TE-TAR`
- **Registry**: `test/TE-id-registry.json` — the `TE-TAR.directories` map is auto-regenerated
  from the filesystem by `New-TestInfrastructure.ps1 -Update` Section E.

## Archival of Prior Audits

Re-audits overwrite the existing report (`New-TestAuditReport.ps1 -Force`). Prior versions
are preserved by **git history**, not by an `old/` subdirectory.
'@

            $readmeContent = $readmeTemplate.Replace('{{GENERATED_TS}}', $generatedTs).Replace('{{TREE_BLOCK}}', $treeBlock)

            $existingContent = if (Test-Path $readmePath) { Get-Content -Path $readmePath -Raw -Encoding UTF8 } else { '' }
            # Compare ignoring the "Last regenerated" line (timestamp churn)
            $strippedNew = ($readmeContent -split "`n" | Where-Object { $_ -notmatch '<!-- Last regenerated:' }) -join "`n"
            $strippedOld = ($existingContent -split "`n" | Where-Object { $_ -notmatch '<!-- Last regenerated:' }) -join "`n"

            if ($strippedNew -ne $strippedOld) {
                if ($PSCmdlet.ShouldProcess($readmePath, "Regenerate audits/README.md")) {
                    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8 -NoNewline
                    Write-Host "  [UPDATED] $readmePath (regenerated from filesystem)" -ForegroundColor Yellow
                    $changesCount++
                }
            } else {
                Write-Host "  [UNCHANGED] $readmePath (content already current)" -ForegroundColor DarkGray
            }
        } else {
            Write-Host "  [SKIP] audits/ dir does not exist at $auditRoot" -ForegroundColor DarkGray
        }
        Write-Host ""

        # --- Summary ---
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  Update Complete" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  Categories processed: $($categories.Count)" -ForegroundColor White
        Write-Host "  Workflows processed: $($workflows.Count)" -ForegroundColor White
        Write-Host "  Changes: $changesCount" -ForegroundColor White

        # Soak: success outcome
        if ($soakInSoak) { Confirm-SoakInvocation -Outcome success }
        exit 0
    }
    catch {
        if ($soakInSoak) {
            $soakErrMsg = $_.Exception.Message
            if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
            Confirm-SoakInvocation -Outcome failure -Notes $soakErrMsg
        }
        Write-Error "New-TestInfrastructure -Update failed: $($_.Exception.Message)"
        exit 1
    }
}

# =========================================================================
# SCAFFOLD MODE (existing behavior; minor edit — removed integration auto-add)
# =========================================================================

# --- Load project-config.json ---
$projectConfigPath = Join-Path $projectRoot "doc/project-config.json"
if (-not (Test-Path $projectConfigPath)) {
    Write-Error "project-config.json not found at $projectConfigPath. Run Project Initiation (PF-TSK-059) first."
    exit 1
}

$projectConfig = Get-Content $projectConfigPath -Raw | ConvertFrom-Json
$resolvedProjectName = if ($ProjectName) { $ProjectName } else { $projectConfig.project.name }
$testDir = if ($projectConfig.testing -and $projectConfig.testing.testDirectory) {
    $projectConfig.testing.testDirectory
} else {
    "test/automated"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  New-TestInfrastructure.ps1" -ForegroundColor Cyan
Write-Host "  Project: $resolvedProjectName" -ForegroundColor Cyan
Write-Host "  Language: $Language" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Load language config ---
$langConfigPath = Join-Path (Get-ProcessFrameworkPath) "languages-config/$($Language.ToLower())/$($Language.ToLower())-config.json"
if (-not (Test-Path $langConfigPath)) {
    Write-Error "Language config not found: $langConfigPath. Create it from the language config template first."
    exit 1
}

$langConfig = Get-Content $langConfigPath -Raw | ConvertFrom-Json
Write-Host "Loaded language config: $langConfigPath" -ForegroundColor Cyan

# --- Determine test categories ---
# NOTE (PF-IMP-871, 2026-05-14): the hardcoded auto-add of "integration" was removed —
# `test/automated/integration/` is no longer part of the framework's test layout. "unit"
# is still auto-prepended because it's the canonical default test category and the only
# fixed bone the blueprint guarantees under `test/automated/`.
if (-not $TestCategories) {
    $TestCategories = @()
    if ($projectConfig.testing -and $projectConfig.testing.quickCategories) {
        $TestCategories = @($projectConfig.testing.quickCategories)
    }
    # Ensure "unit" is always included
    if ($TestCategories -notcontains "unit") {
        $TestCategories = @("unit") + $TestCategories
    }
}

Write-Host "Test categories: $($TestCategories -join ', ')" -ForegroundColor Cyan
Write-Host ""

# --- Helper: Create directory if it doesn't exist ---
function New-DirectoryIfNeeded {
    param([string]$Path, [string]$Description)
    $fullPath = Join-Path $projectRoot $Path
    if (Test-Path $fullPath) {
        Write-Host "  [EXISTS] $Path" -ForegroundColor DarkGray
    } elseif ($PSCmdlet.ShouldProcess($Path, "Create directory: $Description")) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  [CREATED] $Path" -ForegroundColor Green
        $script:scaffoldChangesCount++
    }
}

# --- Helper: Create file from template if it doesn't exist ---
function New-FileFromTemplate {
    param(
        [string]$TargetPath,
        [string]$TemplatePath,
        [string]$Description,
        [hashtable]$Replacements = @{}
    )
    $fullTarget = Join-Path $projectRoot $TargetPath
    if (Test-Path $fullTarget) {
        Write-Host "  [EXISTS] $TargetPath" -ForegroundColor DarkGray
        return
    }

    if ($PSCmdlet.ShouldProcess($TargetPath, "Create file: $Description")) {
        $fullTemplate = Join-Path $projectRoot $TemplatePath
        if (-not (Test-Path $fullTemplate)) {
            Write-Warning "Template not found: $TemplatePath — creating minimal placeholder"
            $content = "# $Description`n`nCreated by New-TestInfrastructure.ps1"
        } else {
            $content = Get-Content $fullTemplate -Raw -Encoding UTF8
        }

        foreach ($key in $Replacements.Keys) {
            $content = $content.Replace($key, $Replacements[$key])
        }

        # Ensure parent directory exists
        $parentDir = Split-Path $fullTarget -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        Set-Content -Path $fullTarget -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  [CREATED] $TargetPath" -ForegroundColor Green
        $script:scaffoldChangesCount++
    }
}

# --- Helper: Create empty file if it doesn't exist ---
function New-EmptyFileIfNeeded {
    param([string]$Path, [string]$Description, [string]$Content = "")
    $fullPath = Join-Path $projectRoot $Path
    if (Test-Path $fullPath) {
        Write-Host "  [EXISTS] $Path" -ForegroundColor DarkGray
    } elseif ($PSCmdlet.ShouldProcess($Path, "Create file: $Description")) {
        $parentDir = Split-Path $fullPath -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        Set-Content -Path $fullPath -Value $Content -Encoding UTF8 -NoNewline
        Write-Host "  [CREATED] $Path" -ForegroundColor Green
        $script:scaffoldChangesCount++
    }
}

$date = Get-Date -Format "yyyy-MM-dd"
$templateReplacements = @{
    "[DATE]" = $date
    "[PROJECT_NAME]" = $resolvedProjectName
}

# PF-IMP-958: tally newly-created dirs/files so the Scaffold summary reports an aggregate
# count (matching the -Update summary's "Changes" line and New-SourceStructure's summary).
$script:scaffoldChangesCount = 0

# ============================================================
# Step 1: Create test directory structure
# ============================================================
Write-Host "Step 1: Creating test directory structure..." -ForegroundColor Yellow

# Core test directories
New-DirectoryIfNeeded -Path "$testDir" -Description "Automated test root"
foreach ($category in $TestCategories) {
    New-DirectoryIfNeeded -Path "$testDir/$category" -Description "Test category: $category"
}
New-DirectoryIfNeeded -Path "$testDir/fixtures" -Description "Static test data files"

# Specification directories
New-DirectoryIfNeeded -Path "test/specifications/feature-specs" -Description "Feature test specifications"
New-DirectoryIfNeeded -Path "test/specifications/cross-cutting-specs" -Description "Cross-cutting test specifications"

# E2E acceptance testing directories
New-DirectoryIfNeeded -Path "test/e2e-acceptance-testing/templates" -Description "E2E test case templates"
New-DirectoryIfNeeded -Path "test/e2e-acceptance-testing/workspace" -Description "E2E working copies (gitignored)"
New-DirectoryIfNeeded -Path "test/e2e-acceptance-testing/results" -Description "E2E execution logs (gitignored)"

# Audit directory
New-DirectoryIfNeeded -Path "test/audits" -Description "Test audit reports"

# Bug-validation directory (top-level since PF-IMP-871 Phase 2b — moved from test/automated/bug-validation/)
New-DirectoryIfNeeded -Path "test/bug-validation" -Description "Bug regression validation scripts"

# State tracking directory
New-DirectoryIfNeeded -Path "test/state-tracking/permanent" -Description "Test state tracking"

Write-Host ""

# ============================================================
# Step 2: Verify tracking files exist (blueprint provides them)
# ============================================================
Write-Host "Step 2: Verifying tracking files exist..." -ForegroundColor Yellow

$expectedTrackingFiles = @(
    @{ Path = (Resolve-TrackingFilePath -File "test-tracking.md");             Label = "test-tracking.md" },
    @{ Path = (Resolve-TrackingFilePath -File "e2e-test-tracking.md");         Label = "e2e-test-tracking.md" },
    @{ Path = (Resolve-TrackingFilePath -File "performance-test-tracking.md"); Label = "performance-test-tracking.md" },
    @{ Path = (Join-Path $projectRoot "test/TE-id-registry.json");             Label = "test/TE-id-registry.json" }
)
$missingTrackingFiles = @()
foreach ($trackingFile in $expectedTrackingFiles) {
    if (-not (Test-Path $trackingFile.Path)) {
        $missingTrackingFiles += $trackingFile.Label
    } else {
        Write-Host "  [EXISTS] $($trackingFile.Label)" -ForegroundColor DarkGray
    }
}
if ($missingTrackingFiles.Count -gt 0) {
    Write-Warning ""
    Write-Warning "The following tracking files are missing:"
    foreach ($f in $missingTrackingFiles) { Write-Warning "  - $f" }
    Write-Warning "These files are provided by the FrameworkBuilder blueprint copy and are no longer"
    Write-Warning "created by this script. Copy them from the blueprint or restore from version"
    Write-Warning "control before continuing."
}

Write-Host ""

# ============================================================
# Step 3: Create language-specific files
# ============================================================
Write-Host "Step 3: Creating language-specific files..." -ForegroundColor Yellow

# Create shared fixture/setup files from language config
if ($langConfig.testing.testSetup -and $langConfig.testing.testSetup.configFiles) {
    foreach ($configFile in $langConfig.testing.testSetup.configFiles) {
        # Check if a template exists in the language config directory
        $fileName = Split-Path $configFile -Leaf
        $templateInLangDir = Join-Path (Get-ProcessFrameworkPath) "languages-config/$($Language.ToLower())/$fileName.template"

        if (Test-Path $templateInLangDir) {
            New-FileFromTemplate `
                -TargetPath $configFile `
                -TemplatePath $templateInLangDir `
                -Description "Shared test fixture: $fileName" `
                -Replacements $templateReplacements
        } else {
            # Create a minimal placeholder
            $comment = switch ($Language.ToLower()) {
                "python" { "# Shared test fixtures for $resolvedProjectName`n# Add pytest fixtures here`n" }
                "javascript" { "// Shared test setup for $resolvedProjectName`n// Add Jest setup here`n" }
                "dart" { "// Shared test helpers for $resolvedProjectName`n" }
                default { "# Shared test setup for $resolvedProjectName`n" }
            }
            New-EmptyFileIfNeeded -Path $configFile -Description "Shared test fixture: $fileName" -Content $comment
        }
    }
}

# Create package marker files where needed (e.g., __init__.py for Python)
if ($langConfig.testing.testFileExclusions -and $langConfig.testing.testFileExclusions -contains "__init__.py") {
    # Python needs __init__.py in test directories
    $initContent = "# Test package marker`n"
    New-EmptyFileIfNeeded -Path "$testDir/__init__.py" -Description "Package marker (test root)" -Content $initContent
    foreach ($category in $TestCategories) {
        New-EmptyFileIfNeeded -Path "$testDir/$category/__init__.py" -Description "Package marker ($category)" -Content $initContent
    }
}

Write-Host ""

# ============================================================
# Step 4: Create .gitignore for E2E directories
# ============================================================
Write-Host "Step 4: Creating .gitignore for E2E directories..." -ForegroundColor Yellow

$gitignoreContent = @"
# E2E acceptance testing - generated at runtime
workspace/
results/
"@

New-EmptyFileIfNeeded -Path "test/e2e-acceptance-testing/.gitignore" -Description "E2E gitignore" -Content $gitignoreContent

Write-Host ""

# ============================================================
# Summary
# ============================================================
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Test Infrastructure Setup Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Changes: $script:scaffoldChangesCount (new directories/files created)" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Create/verify native test runner config (e.g., pytest.ini for Python)" -ForegroundColor White
Write-Host "  2. Install test dependencies (e.g., pip install pytest pytest-cov)" -ForegroundColor White
Write-Host "  3. Verify: Run-Tests.ps1 -ListCategories" -ForegroundColor White
Write-Host "  4. Verify: Run-Tests.ps1 -Quick" -ForegroundColor White
Write-Host ""
