---
id: PF-PRO-011
type: Document
category: General
version: 1.0
created: 2026-03-23
updated: 2026-03-23
---

# Structure Change Proposal: Split ID Registry Into Framework And Product Registries

## Overview

Split the single `doc/id-registry.json` into **three** separate registry files — one for the process framework, one for product documentation, and one for test artifacts — so that the process framework directory can be copied wholesale into other projects without carrying project-specific ID state. Additionally, **rename and reassign prefixes** to align with the domain they actually belong to, and **add missing metadata** to files that lack it.

**Structure Change ID:** SC-008
**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-03-23
**Target Implementation Date:** TBD (after approval)

## Current Structure

A single `doc/id-registry.json` at the doc root contains **all 41 prefixes** — process framework (`PF-*`), product documentation (`PD-*`), artifact (`ART-*`), and test (`TE-*`) prefixes mixed together. Every script resolves this file via `IdRegistry.psm1 → Get-IdRegistryPath`, which navigates from `$PSScriptRoot` to `doc/id-registry.json`.

```
doc/
├── id-registry.json          ← single file, 41 prefixes, ~527 lines
├── process-framework/
│   └── scripts/
│       └── IdRegistry.psm1   ← Get-IdRegistryPath → ../../../doc/id-registry.json
└── product-docs/
```

### Current Problems

Several prefixes are misplaced — their domain doesn't match the registry category they'd belong to:

| Current Prefix | Current Category | Actual Domain | Issue |
|---|---|---|---|
| PF-STA | Process Framework | Mixed | Most files are product-specific (bug tracking, feature tracking) but process-improvement-tracking.md is genuinely PF |
| PF-TSP | Process Framework | Test artifacts | Test specifications live under `test/` |
| PF-TAR | Process Framework | Test artifacts | Test audit reports live under `test/` |
| PF-VAL | Process Framework | Product validation | Validation reports live under `doc/product-docs/validation/` |
| PF-REF | Process Framework | Product refactoring | Refactoring plans live under `doc/product-docs/refactoring/` |
| PF-TDA/TDI/TDM | Process Framework | Product tech debt | Tech debt items are project-specific |
| ART-ASS | Artifact | Product assessments | Assessment artifacts live under `doc/product-docs/` |
| ART-FEE | Artifact | Process framework | Feedback forms live under `doc/process-framework/feedback/` |
| ART-REV | Artifact | Process framework | Review artifacts live under `doc/process-framework/feedback/` |
| PD-GDE | Product Documentation | Process framework | Points to `doc/process-framework/guides` — wrong domain |
| PD-USR | Product Documentation | — | Only 1 file, no IDs found — unused prefix |
| PD-TST | Product Documentation | Test artifacts | Test files belong in the test registry |
| PF-FEA | Process Framework | Product state | Feature implementation states are product-specific, not framework |
| PF-MTH | Process Framework | — | Methodologies directory was removed — orphaned prefix |
| PD-UGD | Product Documentation | Product docs | 2 handbook files lack YAML frontmatter metadata entirely |

## Proposed Structure

**Three** separate registry files, each in its own domain directory, with **named files**:

```
doc/
├── process-framework/
│   ├── PF-id-registry.json   ← process framework prefixes (PF-*)
│   └── scripts/
│       └── IdRegistry.psm1   ← hardcoded prefix→registry mapping
├── product-docs/
│   └── PD-id-registry.json   ← product documentation prefixes (PD-*)
test/
└── TE-id-registry.json       ← test artifact prefixes (TE-*)
```

### Prefix Renames and Reassignments

The following prefixes are renamed to match their actual domain:

| Old Prefix | New Prefix | New Registry | Reason | Files Affected |
|---|---|---|---|---|
| PF-STA (product files) | **PD-STA** | PD | Product-specific state files (bug tracking, feature tracking, etc.) | 27 files |
| PF-STA (process-improvement-tracking) | **PF-STA** _(stays)_ | PF | process-improvement-tracking.md is genuinely process framework | 1 file |
| PF-STA (test-tracking) | **TE-STA** | TE | test-tracking.md moves to `test/` directory | 1 file |
| PF-ASS | _(integrated into PF-DOC)_ | PF | Only 1 file (README), merge into PF-DOC | 1 file |
| PF-FEA | **PD-FIS** | PD | Feature implementation states are product-specific | 51 files |
| PF-TSP | **TE-TSP** | TE | Test specifications live under `test/` | 10 files |
| PF-TAR | **TE-TAR** | TE | Test audit reports live under `test/` | 7 files (in `test/audits/`) |
| PF-VAL | **PD-VAL** | PD | Validation reports are product-specific | 12 files |
| PF-REF | **PD-REF** | PD | Refactoring plans are product-specific | 55 files |
| PF-TDA | **PD-TDA** | PD | Tech debt assessments are product-specific | 0 files (prefix unused so far) |
| PF-TDI | **PD-TDI** | PD | Tech debt items are product-specific | 0 files (prefix unused so far) |
| PF-TDM | **PD-TDM** | PD | Tech debt matrices are product-specific | 0 files (prefix unused so far) |
| ART-ASS | **PD-ASS** | PD | Assessment artifacts are product-specific (existing PD-ASS is orphaned — 0 files, directory deleted) | ~53 files |
| ART-FEE | **PF-FEE** | PF | Feedback forms are process framework artifacts (feedback README will be removed — no collision) | ~434 files |
| ART-REV | **PF-REV** | PF | Review artifacts are process framework artifacts | 14 files |
| PD-TST | **TE-TST** | TE | Test files belong in test registry | referenced in test-registry.yaml |
| PD-GDE | _(removed)_ | — | Points to PF directory — wrong domain; 1 file (PD-GDE-001 = development-guide.md) can use existing PF-GDE | 1 file |
| PD-USR | _(removed)_ | — | Unused prefix — no files found with PD-USR IDs | 0 files |
| PF-MTH | _(removed)_ | — | Methodologies directory was removed — orphaned prefix | 0 files |

#### Collision Resolution

| New Prefix | Colliding Entry | Resolution |
|---|---|---|
| **PD-ASS** (from ART-ASS) | PD-ASS (Assets, nextAvailable: 3) | **No collision**: Existing PD-ASS is orphaned — 0 files found, `doc/product-docs/technical/assets/` directory deleted. Simply replace the prefix entry with ART-ASS data, keeping ART-ASS counter at 201. |
| **PF-FEE** (from ART-FEE) | PF-FEE (Feedback, nextAvailable: 2) | **No collision**: The 1 existing PF-FEE file is the feedback README (`doc/process-framework/feedback/README.md`) — this file will be removed. ART-FEE takes over PF-FEE cleanly, keeping counter at 435. |

#### Missing Metadata

| Prefix | Files | Issue | Action |
|---|---|---|---|
| PD-UGD | `doc/product-docs/user/handbooks/file-type-quick-fix.md`, `doc/product-docs/user/handbooks/troubleshooting-file-types.md` | No YAML frontmatter metadata | Add `id: PD-UGD-001` / `PD-UGD-002` metadata to each file |

### Final Prefix Assignment

**PF-id-registry.json** (`doc/process-framework/`) — Process Framework:

| Prefix | Description | Notes |
|---|---|---|
| PF-TSK | Tasks | Unchanged |
| PF-GDE | Guides | Unchanged (absorbs PD-GDE-001) |
| PF-TEM | Templates | Unchanged |
| PF-DOC | Documentation | Absorbs PF-ASS (tier assessments README) |
| PF-MAI | Main/Index | Unchanged |
| PF-VIS | Visualization | Unchanged |
| PF-PRO | Proposals | Unchanged |
| PF-FEE | Feedback Artifacts | Renamed from ART-FEE (old PF-FEE README removed) |
| PF-STA | State Tracking (framework only) | Retains only process-improvement-tracking.md |
| PF-IMP | Improvement Opportunities | Unchanged |
| PF-REV | Review Artifacts | Renamed from ART-REV |

**PD-id-registry.json** (`doc/product-docs/`) — Product Documentation:

| Prefix | Description | Notes |
|---|---|---|
| PD-DOC | Documentation | Unchanged |
| PD-ASS | Assessment Artifacts | Renamed from ART-ASS (old PD-ASS orphaned — 0 files) |
| PD-DES | System-wide Design | Unchanged |
| PD-UIX | UI/UX Design | Unchanged |
| PD-ARC | Architecture | Unchanged |
| PD-TDD | Technical Design Documents | Unchanged |
| PD-FDD | Functional Design Documents | Unchanged |
| PD-ADR | Architecture Decision Records | Unchanged |
| PD-AIA | Architecture Impact Assessments | Unchanged |
| PD-IMP | Implementation | Unchanged |
| PD-TEC | Technical | Unchanged |
| PD-API | API Specifications | Unchanged |
| PD-CIC | CI-CD | Unchanged |
| PD-UGD | User Guides | Unchanged (add missing metadata to 2 files) |
| PD-FEA | Features | Unchanged |
| PD-FAQ | FAQ | Unchanged |
| PD-SCH | Database Schema Design | Unchanged |
| PD-MIG | Database Migration Scripts | Unchanged |
| PD-ERD | Entity Relationship Diagrams | Unchanged |
| PD-BUG | Bug Reports | Unchanged |
| PD-STA | State Tracking (product) | Renamed from PF-STA (product-specific state files only) |
| PD-FIS | Feature Implementation States | Renamed from PF-FEA |
| PD-VAL | Validation Reports | Renamed from PF-VAL |
| PD-REF | Refactoring Plans | Renamed from PF-REF |
| PD-TDA | Technical Debt Assessments | Renamed from PF-TDA |
| PD-TDI | Technical Debt Items | Renamed from PF-TDI |
| PD-TDM | Technical Debt Matrices | Renamed from PF-TDM |

**TE-id-registry.json** (`test/`) — Test Artifacts:

| Prefix | Description | Notes |
|---|---|---|
| TE-E2G | E2E Test Groups | Unchanged |
| TE-E2E | E2E Test Cases | Unchanged |
| TE-TSP | Test Specifications | Renamed from PF-TSP |
| TE-TAR | Test Audit Reports | Renamed from PF-TAR |
| TE-TST | Test Files | Renamed from PD-TST |
| TE-STA | Test State Tracking | Split from PF-STA (test-tracking.md moves to `test/`) |

**Removed prefixes**: PF-ASS (→ PF-DOC), PF-MTH (directory removed), PF-FEA (→ PD-FIS), PD-GDE (→ PF-GDE), PD-USR (unused), old PD-ASS (orphaned)

### IdRegistry.psm1 Approach

**Hardcoded prefix-to-registry mapping.** `Get-IdRegistryPath` uses a static lookup table:

```powershell
function Get-IdRegistryPath {
    param([string]$Prefix)

    $processFrameworkDir = Split-Path -Parent $PSScriptRoot
    $docDir = Split-Path -Parent $processFrameworkDir
    $projectRoot = Split-Path -Parent $docDir

    # Hardcoded mapping: prefix pattern → registry file
    $registryMap = @{
        'PF-' = Join-Path $processFrameworkDir "PF-id-registry.json"
        'PD-' = Join-Path $docDir "product-docs/PD-id-registry.json"
        'TE-' = Join-Path $projectRoot "test/TE-id-registry.json"
    }

    if ($Prefix) {
        $prefixKey = ($Prefix -split '-')[0] + '-'
        if ($registryMap.ContainsKey($prefixKey)) {
            return $registryMap[$prefixKey]
        }
    }

    # Default: process framework registry
    return $registryMap['PF-']
}
```

All downstream functions (`Get-IdRegistry`, `New-NextId`, `Update-NextAvailableCounter`, etc.) already receive a prefix — they just need to pass it through to `Get-IdRegistryPath`. This is a minimal-impact change to the module API.

## Rationale

### Benefits

- **Framework portability**: The `doc/process-framework/` directory becomes self-contained — it can be copied to another project without carrying project-specific product IDs and counters
- **Clean domain separation**: Process framework IDs (how we work), product IDs (what we build), and test IDs (how we verify) each live in their own domain directory
- **Correct prefix alignment**: Prefixes like PF-VAL, PF-REF, PF-TSP were incorrectly categorized as "process framework" when they track product-specific artifacts — this fix eliminates ongoing confusion
- **Reduced merge conflicts**: When syncing framework improvements across projects, the product and test registries are untouched
- **Clearer ownership**: Each registry is in the directory of the domain it serves
- **Eliminates dead prefixes**: PD-GDE (wrong domain), PD-USR (unused) are cleaned up

### Challenges

- **Large metadata update scope**: ~668 files need `id:` frontmatter prefix changes (bulk of this is ART-FEE → PF-FEE with ~434 feedback forms)
- **Script updates**: ~10+ scripts hardcode `doc/id-registry.json` path — all need updating
- **Validation script updates**: `validate-id-registry.ps1`, `Validate-StateTracking.ps1`, and `Validate-TestTracking.ps1` need to scan all three registries
- **IdRegistry.psm1 refactor**: Core module needs prefix-aware path resolution with hardcoded mapping
- **Cross-references**: Documentation, task definitions, and guides that mention old prefix names (e.g., "PF-VAL-035") need updating
- **CLAUDE.md reference**: The `doc/id-registry.json` reference in CLAUDE.md needs updating to describe all three registries

## Affected Files

### Core Module (must change)

| File | Change |
|------|--------|
| `doc/process-framework/scripts/IdRegistry.psm1` | Add hardcoded prefix→registry mapping to `Get-IdRegistryPath` and propagate prefix through all functions |

### Validation Scripts (must change)

| File | Change |
|------|--------|
| `doc/process-framework/scripts/validation/validate-id-registry.ps1` | Scan all three registry files |
| `doc/process-framework/scripts/validation/Validate-StateTracking.ps1` | Update hardcoded `doc/id-registry.json` path |
| `doc/process-framework/scripts/validation/Validate-TestTracking.ps1` | Update hardcoded `doc/id-registry.json` path |

### File Creation Scripts (must change)

| File | Change |
|------|--------|
| All scripts in `doc/process-framework/scripts/file-creation/` | Update to pass prefix through to `Get-IdRegistryPath` or update hardcoded paths |
| `doc/process-framework/scripts/file-creation/03-testing/New-TestSpecification.ps1` | Also update prefix from PF-TSP to TE-TSP |
| `doc/process-framework/scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1` | Already uses TE-* prefix — update path only |
| `doc/process-framework/scripts/file-creation/05-validation/New-ValidationReport.ps1` | Also update prefix from PF-VAL to PD-VAL |

### Files Requiring Metadata Updates (prefix renames)

| Scope | Old Prefix → New | File Count | Action |
|-------|-------------------|------------|--------|
| State tracking (product) | PF-STA → PD-STA | 27 files | Update `id:` frontmatter in each file |
| State tracking (test) | PF-STA → TE-STA | 1 file | Update `id:` frontmatter (test-tracking.md) |
| Feature implementation states | PF-FEA → PD-FIS | 51 files | Update `id:` frontmatter |
| Validation reports | PF-VAL → PD-VAL | 12 files | Update `id:` frontmatter |
| Refactoring plans | PF-REF → PD-REF | 55 files | Update `id:` frontmatter |
| Test specifications | PF-TSP → TE-TSP | 10 files | Update `id:` frontmatter |
| Test audit reports | PF-TAR → TE-TAR | 7 files | Update `id:` frontmatter |
| Assessment artifacts | ART-ASS → PD-ASS | ~53 files | Update `id:` frontmatter |
| Feedback artifacts | ART-FEE → PF-FEE | ~434 files | Update `id:` frontmatter |
| Review artifacts | ART-REV → PF-REV | 14 files | Update `id:` frontmatter |
| User guide handbooks | PD-UGD (missing) | 2 files | Add YAML frontmatter with PD-UGD IDs |
| Tier assessments | PF-ASS → PF-DOC | 1 file | Update `id:` frontmatter |
| Development guide | PD-GDE → PF-GDE | 1 file | Update `id:` frontmatter |
| **Total** | | **~668 files** | |

### Documentation (must change)

| File | Change |
|------|--------|
| `CLAUDE.md` | Update `doc/id-registry.json` reference to describe all three registry files |
| `doc/process-framework/documentation-map.md` | Update all references to renamed prefixes (PF-VAL-035 → PD-VAL-035, PF-TSP-035 → TE-TSP-035, etc.) |

### Task Definitions (review for context references)

Multiple task definitions reference `id-registry.json` in their Context Requirements sections. These links need updating:
- 11 validation tasks (PF-TSK-031 through PF-TSK-077)
- Bug fixing task (PF-TSK-022)
- Test specification creation task (PF-TSK-016)
- E2E acceptance test execution task (PF-TSK-070)
- FDD creation task
- New task creation process (PF-TSK-001)
- Framework extension task
- Project initiation task

### Files to Remove

| File | Action |
|------|--------|
| `doc/process-framework/feedback/README.md` | Remove (PF-FEE-000) — eliminates PF-FEE collision |

### Files to Move

| File | From | To | Reason |
|------|------|----|--------|
| `doc/id-registry.json` | `doc/` | `doc/process-framework/PF-id-registry.json` | Becomes PF registry; LinkWatcher updates references |
| `doc/process-framework/state-tracking/permanent/test-tracking.md` | `doc/process-framework/` | `test/test-tracking.md` | Test state tracking belongs in test directory |

## Migration Strategy

### Phase 1: Create Registry Files by Moving and Splitting

1. **Move** `doc/id-registry.json` → `doc/process-framework/PF-id-registry.json` (LinkWatcher updates references automatically)
2. Clean PF-id-registry.json: keep only PF-* prefixes, apply renames (ART-FEE → PF-FEE, ART-REV → PF-REV, PF-ASS → PF-DOC, absorb PD-GDE into PF-GDE), remove PF-MTH, PF-FEA (→ PD-FIS), and all PD-*/ART-*/TE-* prefixes. Split PF-STA: keep only process-improvement-tracking.md entry.
3. **Create** `doc/product-docs/PD-id-registry.json` with PD-* prefixes (including renames: PF-STA product files → PD-STA, PF-VAL → PD-VAL, PF-REF → PD-REF, PF-TDA/TDI/TDM → PD-*, ART-ASS → PD-ASS, PF-FEA → PD-FIS; remove PD-GDE, PD-USR, orphaned old PD-ASS)
4. **Create** `test/TE-id-registry.json` with TE-* prefixes (TE-E2G, TE-E2E, PF-TSP → TE-TSP, PF-TAR → TE-TAR, PD-TST → TE-TST, PF-STA test-tracking → TE-STA)
5. Remove feedback README (`doc/process-framework/feedback/README.md`) — eliminates PF-FEE collision
6. Each file retains the same `metadata` block structure with updated description and name
7. Verify total prefix count across all three registries

### Phase 2: Update IdRegistry.psm1

1. Implement hardcoded prefix→registry mapping in `Get-IdRegistryPath`
2. Update `Get-IdRegistry` to accept and pass prefix
3. Update `Update-NextAvailableCounter`, `New-NextId`, `Get-NextAvailableId`, `Get-PrefixInfo`, `Get-PrefixDirectories` etc.
4. Test module with PF-*, PD-*, and TE-* prefixes

### Phase 3: Update Scripts with Hardcoded Paths and Prefixes

1. Update each script that uses `Join-Path $ProjectRoot "doc/id-registry.json"` to use the module's `Get-IdRegistryPath`
2. Update scripts that reference renamed prefixes (e.g., `New-TestSpecification.ps1` must use TE-TSP, `New-ValidationReport.ps1` must use PD-VAL)
3. Update validation scripts to scan all three registry files

### Phase 4: Bulk Metadata Update in Files

1. For each prefix rename, update the `id:` field in all affected file frontmatter
2. Use PowerShell scripting to bulk-update (e.g., `(Get-Content $file) -replace '^id: PF-STA-', 'id: PD-STA-'`)
3. Add missing YAML frontmatter to PD-UGD handbook files
4. Renumber collision files (2 PD-ASS files, 1 PF-FEE file)

### Phase 5: Update Documentation References

1. Update CLAUDE.md to describe all three registry files
2. Update documentation-map.md with renamed prefix IDs
3. Update task definitions that reference `doc/id-registry.json` in Context Requirements
4. Update any cross-references that mention old prefix IDs (e.g., PF-VAL-035 → PD-VAL-035 in documentation-map.md)
5. LinkWatcher handles markdown link path changes automatically

### Phase 6: Cleanup and Validation

1. Verify `doc/id-registry.json` no longer exists (was moved in Phase 1)
2. Run `validate-id-registry.ps1` against all three registries — zero errors
3. Run `Validate-StateTracking.ps1` — zero errors across all surfaces
4. Run `Validate-TestTracking.ps1` — zero errors
5. Test document creation with at least one prefix from each registry (PF-*, PD-*, TE-*)
6. Grep for any remaining references to old `doc/id-registry.json` path

## Testing Approach

### Test Cases

1. **Module test**: `New-NextId -Prefix "PF-TSK"` reads from `PF-id-registry.json` and increments correctly
2. **Module test**: `New-NextId -Prefix "PD-TDD"` reads from `PD-id-registry.json` and increments correctly
3. **Module test**: `New-NextId -Prefix "TE-TSP"` reads from `TE-id-registry.json` and increments correctly
4. **Validation test**: `validate-id-registry.ps1` scans all three registries and reports zero errors
5. **Validation test**: `Validate-StateTracking.ps1` Surface 5 (ID counters) passes with all three registries
6. **Creation test**: Run `New-FeedbackForm.ps1` — creates file with PF-FEE prefix (not ART-FEE), updates PF-id-registry.json
7. **Creation test**: Run a PD-* creation script — creates file, updates PD-id-registry.json
8. **Creation test**: Run `New-TestSpecification.ps1` — creates file with TE-TSP prefix, updates TE-id-registry.json
9. **Metadata test**: Grep for old prefixes (ART-ASS, ART-FEE, ART-REV, PF-STA, PF-TSP, PF-TAR, PF-VAL, PF-REF, PF-TDA, PF-TDI, PF-TDM, PD-TST) in file frontmatter — zero hits
10. **No orphan test**: Verify `doc/id-registry.json` no longer exists after migration

### Success Criteria

- All prefixes accessible from their respective registry files
- All validation scripts pass with zero errors
- All file creation scripts create documents and update the correct registry
- No script references the old `doc/id-registry.json` path
- No file frontmatter uses old/removed prefixes
- `doc/process-framework/` is self-contained for framework IDs (can be copied to another project)
- `test/` contains its own TE-id-registry.json for test-domain IDs

## Rollback Plan

### Trigger Conditions

- Multiple scripts fail after migration and fixes are non-trivial
- Unforeseen dependencies on single-file registry structure

### Rollback Steps

1. Recreate `doc/id-registry.json` by merging all three registry files (reverse prefix renames)
2. Revert `IdRegistry.psm1` to single-path implementation
3. Revert hardcoded paths in scripts
4. Revert file metadata prefix changes (bulk replace back)
5. Keep the split registry files in place until rollback is confirmed working

> **Note**: The metadata prefix renames (Phase 4) are the hardest to rollback due to ~617 files. Consider completing Phases 1-3 and validating before starting Phase 4.

## Resources Required

### Personnel

- AI Agent — 3-4 sessions:
  - Session 1: Phases 1-2 (registry creation + IdRegistry.psm1 refactor)
  - Session 2: Phase 3 (script updates)
  - Session 3: Phase 4 (bulk metadata updates — may need sub-sessions for large batches)
  - Session 4: Phases 5-6 (documentation + cleanup + validation)
- Human Partner — review at each checkpoint

### Tools

- `IdRegistry.psm1` — core module to refactor
- `validate-id-registry.ps1` — verify split correctness
- `Validate-StateTracking.ps1` — verify counter integrity
- `Validate-TestTracking.ps1` — verify test tracking integrity
- PowerShell bulk replace scripts (ad-hoc for Phase 4)
- LinkWatcher — handle documentation cross-reference updates

## Metrics

### Implementation Metrics

- All prefixes split correctly across 3 registries (11 PF + 27 PD + 6 TE = 44; minus 6 removed = net 38 active from original 41)
- Zero validation errors after migration
- Zero hardcoded references to old `doc/id-registry.json` path
- Zero file frontmatter references to old/removed prefixes

### User Experience Metrics

- No change to script invocation syntax (scripts still accept same parameters)
- Framework portability: `doc/process-framework/` can be copied to a new project and `IdRegistry.psm1` functions work for PF-* prefixes without modification
- Test portability: `test/` has its own registry for test-domain artifacts

## Approval

**Approved By:** _________________
**Date:** 2026-03-23

**Comments:**
