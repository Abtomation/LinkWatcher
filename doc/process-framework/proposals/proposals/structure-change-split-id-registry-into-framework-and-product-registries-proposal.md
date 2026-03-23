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

Split the single `doc/id-registry.json` into two separate registry files — one for the process framework and one for product documentation — so that the process framework directory can be copied wholesale into other projects without carrying project-specific ID state.

**Structure Change ID:** SC-008
**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-03-23
**Target Implementation Date:** TBD (after approval)

## Current Structure

A single `doc/id-registry.json` at the doc root contains **all 41 prefixes** — both process framework prefixes (`PF-*`, `ART-*`, `TE-*`) and product documentation prefixes (`PD-*`). Every script resolves this file via `IdRegistry.psm1 → Get-IdRegistryPath`, which navigates from `$PSScriptRoot` to `doc/id-registry.json`.

```
doc/
├── id-registry.json          ← single file, 41 prefixes, ~527 lines
├── process-framework/
│   └── scripts/
│       └── IdRegistry.psm1   ← Get-IdRegistryPath → ../../../doc/id-registry.json
└── product-docs/
```

## Proposed Structure

Two separate registry files, each in its own domain directory:

```
doc/
├── process-framework/
│   ├── id-registry.json      ← 24 prefixes (PF-*, ART-*, TE-*)
│   └── scripts/
│       └── IdRegistry.psm1   ← updated: resolves registry by prefix
└── product-docs/
    └── id-registry.json      ← 17 prefixes (PD-*)
```

### Prefix Assignment

**Process Framework registry** (`doc/process-framework/id-registry.json`) — 24 prefixes:

| Prefix | Description |
|--------|-------------|
| PF-TSK | Tasks |
| PF-GDE | Guides |
| PF-TEM | Templates |
| PF-MTH | Methodologies |
| PF-STA | State Tracking |
| PF-DOC | Documentation |
| PF-MAI | Main/Index |
| PF-VIS | Visualization |
| PF-PRO | Proposals |
| PF-FEE | Feedback |
| PF-FEA | Feature Implementation States |
| PF-IMP | Improvement Opportunities |
| PF-ASS | Tier Assessments |
| PF-TSP | Test Specifications |
| PF-TAR | Test Audit Reports |
| PF-VAL | Validation Reports |
| PF-REF | Refactoring Plans |
| PF-TDA | Technical Debt Assessments |
| PF-TDI | Technical Debt Items |
| PF-TDM | Technical Debt Matrices |
| ART-ASS | Assessment Artifacts |
| ART-FEE | Feedback Artifacts |
| ART-REV | Review Artifacts |
| TE-E2G | E2E Test Groups |
| TE-E2E | E2E Test Cases |

**Product Documentation registry** (`doc/product-docs/id-registry.json`) — 17 prefixes:

| Prefix | Description |
|--------|-------------|
| PD-DOC | Documentation |
| PD-ASS | Assets |
| PD-DES | System-wide Design |
| PD-UIX | UI/UX Design |
| PD-ARC | Architecture |
| PD-TDD | Technical Design Documents |
| PD-FDD | Functional Design Documents |
| PD-ADR | Architecture Decision Records |
| PD-AIA | Architecture Impact Assessments |
| PD-IMP | Implementation |
| PD-TEC | Technical |
| PD-API | API Specifications |
| PD-CIC | CI-CD |
| PD-GDE | Guides |
| PD-USR | User |
| PD-UGD | User Guides |
| PD-FEA | Features |
| PD-FAQ | FAQ |
| PD-SCH | Database Schema Design |
| PD-MIG | Database Migration Scripts |
| PD-ERD | Entity Relationship Diagrams |
| PD-TST | Test Files |
| PD-BUG | Bug Reports |

### IdRegistry.psm1 Approach

**Recommended: Prefix-based registry resolution.** `Get-IdRegistryPath` gains an optional `-Prefix` parameter:

```powershell
function Get-IdRegistryPath {
    param([string]$Prefix)

    $processFrameworkDir = Split-Path -Parent $PSScriptRoot
    $docDir = Split-Path -Parent $processFrameworkDir

    if ($Prefix -and $Prefix -match '^PD-') {
        return Join-Path $docDir "product-docs/id-registry.json"
    }
    return Join-Path $processFrameworkDir "id-registry.json"
}
```

All downstream functions (`Get-IdRegistry`, `New-NextId`, `Update-NextAvailableCounter`, etc.) already receive a prefix — they just need to pass it through to `Get-IdRegistryPath`. This is a minimal-impact change to the module API.

## Rationale

### Benefits

- **Framework portability**: The `doc/process-framework/` directory becomes self-contained — it can be copied to another project without carrying project-specific product IDs and counters
- **Clean domain separation**: Process framework IDs (how we work) are separated from product IDs (what we build), matching the existing documentation separation principle
- **Reduced merge conflicts**: When syncing framework improvements across projects, the product registry is untouched
- **Clearer ownership**: Each registry is in the directory of the domain it serves

### Challenges

- **Script updates**: ~10 scripts hardcode `doc/id-registry.json` path — all need updating
- **Validation script updates**: `validate-id-registry.ps1`, `Validate-StateTracking.ps1`, and `Validate-TestTracking.ps1` need to scan both registries
- **IdRegistry.psm1 refactor**: Core module needs prefix-aware path resolution
- **CLAUDE.md reference**: The `doc/id-registry.json` reference in CLAUDE.md needs updating
- **Backward compatibility during transition**: The old `doc/id-registry.json` must be removed to avoid confusion

## Affected Files

### Core Module (must change)

| File | Change |
|------|--------|
| `doc/process-framework/scripts/IdRegistry.psm1` | Add prefix-based registry resolution to `Get-IdRegistryPath` and propagate prefix through all functions |

### Validation Scripts (must change)

| File | Change |
|------|--------|
| `doc/process-framework/scripts/validation/validate-id-registry.ps1` | Scan both registry files |
| `doc/process-framework/scripts/validation/Validate-StateTracking.ps1` | Update hardcoded `doc/id-registry.json` path (line 434) |
| `doc/process-framework/scripts/validation/Validate-TestTracking.ps1` | Update hardcoded `doc/id-registry.json` path (line 202) |

### File Creation Scripts (must change)

| File | Change |
|------|--------|
| `doc/process-framework/scripts/file-creation/03-testing/New-TestSpecification.ps1` | Update hardcoded path (line 256) |
| `doc/process-framework/scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1` | Update hardcoded path (line 142) |
| `doc/process-framework/scripts/file-creation/04-implementation/New-FeatureImplementationState.ps1` | Update hardcoded path |
| `doc/process-framework/scripts/file-creation/05-validation/New-ValidationReport.ps1` | Update hardcoded paths (lines 108, 166) |
| `doc/process-framework/scripts/file-creation/02-design/New-APIDataModel.ps1` | Update reference |

### Documentation (must change)

| File | Change |
|------|--------|
| `CLAUDE.md` | Update `doc/id-registry.json` reference to describe both registry files |

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
| `doc/id-registry.json` | Delete after split is complete and all scripts verified |

## Migration Strategy

### Phase 1: Create New Registry Files

1. Create `doc/process-framework/id-registry.json` with PF-*, ART-*, TE-* prefixes extracted from current registry
2. Create `doc/product-docs/id-registry.json` with PD-* prefixes extracted from current registry
3. Both files retain the same `metadata` block structure with updated description
4. Verify combined prefix count equals original (41 prefixes total)

### Phase 2: Update IdRegistry.psm1

1. Add `-Prefix` parameter to `Get-IdRegistryPath`
2. Update `Get-IdRegistry` to accept and pass prefix
3. Update `Update-NextAvailableCounter` to accept and use prefix for path resolution
4. Update `New-NextId`, `Get-NextAvailableId`, `Get-PrefixInfo`, `Get-PrefixDirectories`, etc.
5. Test module with both PF-* and PD-* prefixes

### Phase 3: Update Scripts with Hardcoded Paths

1. Update each script listed in Affected Files that uses `Join-Path $ProjectRoot "doc/id-registry.json"`
2. For scripts that already know their prefix context, pass prefix to the IdRegistry module
3. For scripts that directly read the file (bypassing IdRegistry.psm1), update to use the correct path based on the prefix they're working with

### Phase 4: Update Documentation References

1. Update CLAUDE.md to describe both registry files
2. Update task definitions that reference `doc/id-registry.json` in Context Requirements
3. Update documentation-map.md if needed

### Phase 5: Cleanup

1. Remove `doc/id-registry.json`
2. Run all validation scripts to verify zero errors
3. Test document creation with at least one PF-* and one PD-* prefix

## Testing Approach

### Test Cases

1. **Module test**: `New-NextId -Prefix "PF-TSK"` reads from `doc/process-framework/id-registry.json` and increments correctly
2. **Module test**: `New-NextId -Prefix "PD-TDD"` reads from `doc/product-docs/id-registry.json` and increments correctly
3. **Validation test**: `validate-id-registry.ps1` scans both registries and reports zero errors
4. **Validation test**: `Validate-StateTracking.ps1` Surface 5 (ID counters) passes with both registries
5. **Creation test**: Run `New-FeedbackForm.ps1` (PF-* prefix) — creates file, updates correct registry
6. **Creation test**: Run a PD-* creation script — creates file, updates correct registry
7. **No orphan test**: Verify `doc/id-registry.json` no longer exists after migration

### Success Criteria

- All 41 prefixes are accessible from their respective registry files
- All validation scripts pass with zero errors
- All file creation scripts create documents and update the correct registry
- No script references the old `doc/id-registry.json` path
- `doc/process-framework/` is self-contained for framework IDs (can be copied to another project)

## Rollback Plan

### Trigger Conditions

- Multiple scripts fail after migration and fixes are non-trivial
- Unforeseen dependencies on single-file registry structure

### Rollback Steps

1. Recreate `doc/id-registry.json` by merging both registry files
2. Revert `IdRegistry.psm1` to single-path implementation
3. Revert hardcoded paths in scripts
4. Keep the split registry files in place (they don't conflict) until rollback is confirmed working

## Resources Required

### Personnel

- AI Agent — 2-3 sessions (Phase 1-2 in one session, Phase 3-5 in subsequent sessions)
- Human Partner — review at each checkpoint

### Tools

- `IdRegistry.psm1` — core module to refactor
- `validate-id-registry.ps1` — verify split correctness
- `Validate-StateTracking.ps1` — verify counter integrity
- LinkWatcher — handle documentation cross-reference updates

## Metrics

### Implementation Metrics

- All 41 prefixes split correctly (24 PF + 17 PD)
- Zero validation errors after migration
- Zero hardcoded references to old `doc/id-registry.json` path

### User Experience Metrics

- No change to script invocation syntax (scripts still accept same parameters)
- Framework portability: `doc/process-framework/` can be copied to a new project and `IdRegistry.psm1` functions work for PF-* prefixes without modification

## Approval

**Approved By:** _________________
**Date:** 2026-03-23

**Comments:**
