---
id: PF-PRO-012
type: Document
category: Proposal
version: 1.0
created: 2026-03-25
updated: 2026-03-25
---

# Structure Change Proposal: Marker-Based Test Infrastructure

## Overview

Replace the hand-maintained `test-registry.yaml` (60 entries, ~15 fields each) with pytest markers as the single source of truth for test metadata. Eliminate TE-TST-XXX IDs in favour of file paths as stable identifiers. Create a lightweight Python query script (`test_query.py`) that reads markers via AST to answer structured questions about the test suite.

**Structure Change ID:** SC-007
**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-03-25
**Target Implementation Date:** TBD
**Origin:** PF-IMP-207 (Framework Evaluation PF-EVR-001, findings U-1, S-1, S-3)

## Current Structure

Three coupled artifacts maintain test metadata:

```
test/
├── test-registry.yaml              # 60 entries, 15 fields each (hand-maintained)
│   ├── id: TE-TST-XXX              #   Assigned by Add-TestRegistryEntry
│   ├── featureId, priority, crossCuttingFeatures  #   DUPLICATED in pytest markers (since IMP-206)
│   ├── testCasesCount               #   Drifts — no auto-update mechanism
│   ├── componentName, description   #   Human-curated, useful for reporting
│   ├── specificationPath, tddPath   #   Traceability links
│   └── tier, created, updated       #   Metadata
│
├── state-tracking/permanent/
│   └── test-tracking.md             # Status tracking, keyed by TE-TST-XXX IDs
│
└── automated/                       # 31 test files with pytestmark (IMP-206):
    └── **/*.py                      #   pytest.mark.feature(), priority(), cross_cutting()
```

**Supporting infrastructure:**
- `TestTracking.psm1` — `Add-TestRegistryEntry` writes YAML entries; `Update-TestImplementationStatusEnhanced` updates test-tracking.md using TE-TST-XXX IDs
- `New-TestFile.ps1` — creates test file + registry entry + test-tracking.md row
- `Validate-TestTracking.ps1` — validates registry ↔ tracking ↔ disk consistency
- `TE-id-registry.json` — manages TE-TST counter (`nextAvailable: 133`)

**TE-TST-XXX ID consumers:**

| Consumer | Usage | Count |
|----------|-------|-------|
| `test-tracking.md` | Primary key (column 1) | ~60 rows |
| `test-registry.yaml` | ID field per entry | 60 entries |
| Audit reports | In filename and metadata | 7 files |
| `TE-id-registry.json` | Counter for TE-TST prefix | 1 entry |
| `TestTracking.psm1` | Generates and passes IDs | 4 functions |
| `New-TestFile.ps1` | Creates entry with ID | 1 script |
| `Validate-TestTracking.ps1` | Validates ID consistency | 1 script |
| Test specifications | Reference in body text | 2 files |

### Problems

1. **Dual source of truth**: Since IMP-206, `featureId`, `priority`, and `crossCuttingFeatures` exist in both markers (code) and registry (YAML). Any update requires changing two places.
2. **testCasesCount drift**: No mechanism to keep counts accurate — they drift silently as tests are added/removed.
3. **Hand-maintenance at scale**: Every new test file requires manual YAML editing (15 fields) plus `Add-TestRegistryEntry` call. The registry scales linearly with test count.
4. **TE-TST-XXX indirection**: File paths are the real identifiers (that's how pytest, developers, and LinkWatcher work). The ID layer adds indirection without adding value — file paths are already stable, and LinkWatcher handles renames.
5. **Human-curated fields provide limited value**: `componentName` and `description` duplicate what's already in the test file's docstring or class names. `specificationPath` and `tddPath` could be markers.

## Proposed Structure

```
test/
├── automated/                       # 31 test files — THE source of truth
│   └── **/*.py                      #   pytestmark: feature, priority, cross_cutting, specification
│
├── state-tracking/permanent/
│   └── test-tracking.md             # Status tracking, keyed by FILE PATH (not ID)
│
└── (test-registry.yaml REMOVED)     # No longer needed
```

**New markers** added to test files:
```python
pytestmark = [
    pytest.mark.feature("0.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),                    # NEW — explicit, not inferred from directory
    pytest.mark.cross_cutting(["1.1.1", "0.1.2"]),
    pytest.mark.specification("test/specifications/feature-specs/test-spec-0-1-1-core-architecture.md"),  # NEW
]
```

Valid `test_type` values: `unit`, `integration`, `parser`, `performance`, `e2e`

**New tool: `test_query.py`** (in `doc/process-framework/scripts/test/`):

```bash
# What tests cover feature 2.1.1?
python doc/process-framework/scripts/test/test_query.py --feature 2.1.1

# All unit tests
python doc/process-framework/scripts/test/test_query.py --type unit

# Test count per feature
python doc/process-framework/scripts/test/test_query.py --summary

# Full dump for validation or migration
python doc/process-framework/scripts/test/test_query.py --dump --format yaml

# Single file metadata
python doc/process-framework/scripts/test/test_query.py --file test/automated/unit/test_service.py
```

Implementation: Pure AST parsing — reads `pytestmark` assignments + counts test functions/classes. No imports, no test environment needed.

**test-tracking.md migration** — before and after:

```markdown
# BEFORE (ID-keyed):
| Test ID    | Feature ID | Test Type | Test File/Case                          | Status              | ...
|------------|------------|-----------|----------------------------------------|---------------------|----
| TE-TST-102 | 0.1.1      | Automated | `[test_service.py](../../automated/...)` | ✅ Tests Implemented | ...

# AFTER (path-keyed):
| Feature ID | Test Type | Test File                                         | Status              | ...
|------------|-----------|---------------------------------------------------|---------------------|----
| 0.1.1      | Automated | `[test_service.py](../../automated/unit/test_service.py)` | ✅ Tests Implemented | ...
```

The Test ID column is removed. Feature ID becomes the first column. File path (as markdown link) is the unique identifier.

## Rationale

### Benefits

- **Single source of truth**: Markers in code are authoritative. No synchronization required between code and YAML.
- **testCasesCount always accurate**: `test_query.py` counts via AST on every invocation — no drift possible.
- **Zero maintenance for existing tests**: No YAML to update when test counts change.
- **Simpler new-test workflow**: `New-TestFile.ps1` writes markers into the Python file (which it already generates from a template) and adds a row to test-tracking.md. No registry CRUD needed.
- **File path = natural identifier**: Matches how pytest, grep, developers, and LinkWatcher already work. No ID indirection.
- **AI agent efficiency**: `test_query.py --feature X.Y.Z` returns focused data without loading a 600-line YAML file or 400-line tracking file.
- **Scalability**: Adding 100 more test files requires zero infrastructure changes — markers are self-documenting.
- **Language portability**: See [Language Portability](#language-portability) — the framework skeleton is language-agnostic; only the metadata carrier, AST parser, and marker registration change per language.

### Challenges

- **Migration effort**: test-tracking.md has ~60 rows that need primary key migration (TE-TST-XXX → file path). PowerShell script can automate this using the existing registry as a mapping source.
- **Audit report references**: 7 audit report filenames contain TE-TST-XXX (e.g., `audit-report-0-1-1-pd-tst-102.md`). These are historical artifacts — recommend leaving filenames unchanged (IDs become vestigial but harmless) and updating only the internal cross-references.
- **E2E test entries**: The registry also contains E2E group/case entries (`TE-E2G-*`, `TE-E2E-*`) which don't have pytest markers. These need a separate solution — likely handled by IMP-210 (E2E tracking split).
- **Lost human-curated fields**: `componentName` and `description` from the registry will no longer have a home. Assessment: these duplicate information available from test file docstrings and are not referenced by any script or automation. Low-value loss.
- **Validate-TestTracking.ps1 rewrite**: Validation logic shifts from registry-based to marker-based. Moderate effort but cleaner result.

## Affected Files

### Scripts (modify)

| File | Change |
|------|--------|
| `doc/process-framework/scripts/Common-ScriptHelpers/TestTracking.psm1` | Replace `Add-TestRegistryEntry` with marker-writing function; update `Update-TestImplementationStatusEnhanced` to use file path instead of TE-TST-XXX |
| `doc/process-framework/scripts/file-creation/03-testing/New-TestFile.ps1` | Remove registry entry creation; ensure template includes `specification` marker placeholder |
| `doc/process-framework/scripts/validation/Validate-TestTracking.ps1` | Rewrite to validate markers (via `test_query.py --dump`) against test-tracking.md |
| `doc/process-framework/scripts/validation/Validate-StateTracking.ps1` | Update TestTracking surface to call new validation logic |
| `doc/process-framework/scripts/file-creation/03-testing/New-TestAuditReport.ps1` | Update TestFileId parameter to accept file path |
| `doc/process-framework/scripts/update/Update-TestFileAuditState.ps1` | Update to use file path as identifier |
| `doc/process-framework/scripts/update/Update-TestAuditState.ps1` | Update to use file path as identifier |

### Scripts (new)

| File | Purpose |
|------|---------|
| `doc/process-framework/scripts/test/test_query.py` | AST-based marker reader + test counter + structured output (replaces registry as query interface) |

### State/Tracking Files (modify)

| File | Change |
|------|--------|
| `test/state-tracking/permanent/test-tracking.md` | Migrate primary key from TE-TST-XXX to file path; remove Test ID column |
| `test/TE-id-registry.json` | Remove TE-TST prefix (retain TE-E2G, TE-E2E, TE-TSP, TE-TAR, TE-STA) |

### Test Files (modify)

| File | Change |
|------|--------|
| 31 test files in `test/automated/` | Add `pytest.mark.specification(...)` marker where a spec exists |
| `pyproject.toml` | Register `specification` marker |

### Documentation (modify)

| File | Change |
|------|--------|
| `doc/process-framework/guides/03-testing/test-infrastructure-guide.md` | Rewrite registry section → marker-based approach |
| `doc/process-framework/guides/03-testing/integration-and-testing-usage-guide.md` | Update test-registry.yaml references |
| `doc/process-framework/guides/03-testing/test-file-creation-guide.md` | Update new-test workflow (markers, no registry) |
| `doc/process-framework/guides/03-testing/test-audit-usage-guide.md` | Update audit report ↔ test file linking |
| `doc/process-framework/infrastructure/process-framework-task-registry.md` | Update file operations for affected tasks |
| `doc/process-framework/documentation-map.md` | Remove test-registry.yaml reference; add test_query.py |
| `doc/process-framework/scripts/AUTOMATION-USAGE-GUIDE.md` | Update test tooling section |
| `README.md` | Update testing section if it references registry |
| `CLAUDE.md` | No change expected (doesn't reference registry directly) |
| ~10 task definitions that reference test-registry.yaml | Update references to point to markers / test_query.py |
| ~5 context maps in `03-testing/` | Update component diagrams |

### Files to Archive/Remove

| File | Action |
|------|--------|
| `test/test-registry.yaml` | Archive to `test/archive/` then delete |

### Files to Leave Unchanged

| File | Reason |
|------|--------|
| 7 audit report files with TE-TST in filename | Historical artifacts — renaming provides no value and breaks git history |
| 2 test specification files referencing TE-TST | Body text references can remain as historical context |

## Migration Strategy

### Phase 1: Add New Markers (safe, additive)

- Register `test_type` and `specification` markers in `pyproject.toml`
- Add `pytest.mark.test_type(...)` to all 31 test files (value derived from current directory: `unit/` → `"unit"`, `integration/` → `"integration"`, `parsers/` → `"parser"`, `performance/` → `"performance"`)
- Add `pytest.mark.specification(...)` to the ~20 test files that have a `specificationPath` in the current registry
- Verify: `pytest --collect-only --strict-markers` passes

**Checkpoint**: Markers complete. No existing infrastructure affected.

### Phase 2: Create test_query.py (new tool, no removals)

- Implement AST-based marker reader + test function counter
- Support `--feature`, `--summary`, `--dump --format yaml|json`, `--file` modes
- Validate output against current test-registry.yaml to confirm parity
- Document in test-infrastructure-guide.md

**Checkpoint**: Query tool works. Registry still exists as fallback.

### Phase 3: Migrate test-tracking.md Primary Key

- Write a one-time migration script that:
  1. Reads current test-tracking.md
  2. Maps TE-TST-XXX → file path using existing registry as lookup
  3. Removes Test ID column, reorders columns (Feature ID first)
  4. Writes updated test-tracking.md
- Pilot on a copy, diff against original to verify correctness
- Apply to actual file after approval

**Checkpoint**: test-tracking.md uses file paths. TE-TST-XXX IDs no longer needed for tracking.

### Phase 4: Update Scripts

- `TestTracking.psm1`: Replace `Add-TestRegistryEntry` with a function that writes markers into a Python file; update `Update-TestImplementationStatusEnhanced` to accept file path
- `New-TestFile.ps1`: Remove registry creation call; template already includes marker placeholders — ensure `specification` placeholder is added
- `New-TestAuditReport.ps1`: Accept file path instead of TestFileId
- `Validate-TestTracking.ps1`: Rewrite to validate `test_query.py --dump` output against test-tracking.md

**Checkpoint**: All scripts work without the registry. Registry still exists on disk but is unused.

### Phase 5: Update Documentation

- Update ~10 task definitions, 5 guides, 5 context maps, task registry, documentation map
- Bulk operation: grep for `test-registry.yaml` and `TE-TST` across all docs; update or annotate each reference

**Checkpoint**: All documentation reflects the new approach.

### Phase 6: Retire test-registry.yaml

- Archive `test/test-registry.yaml` to `test/archive/test-registry-archived-2026-XX-XX.yaml`
- Remove `TE-TST` prefix from `test/TE-id-registry.json`
- Run `Validate-StateTracking.ps1` to confirm 0 errors
- Delete the archived copy after one session of successful operation (or keep for historical reference)

### Phase 7: E2E Entry Decision (depends on IMP-210)

- E2E group/case entries (`TE-E2G-*`, `TE-E2E-*`) in the registry don't have pytest markers
- If IMP-210 (E2E tracking split) is implemented, E2E entries move to their own tracking file
- If not, E2E entries need a minimal registry or their own marker/metadata approach
- This phase is deferred until IMP-210 status is resolved

## Task Modifications

### New-TestFile.ps1 Workflow (PF-TSK-053, PF-TSK-078, PF-TSK-051)

**Changes needed:**
- `New-TestFile.ps1` no longer calls `Add-TestRegistryEntry`
- Instead writes markers directly into the generated Python file (template already has `pytestmark` block)
- Adds `specification` marker if a spec path is provided
- Calls `Update-TestImplementationStatusEnhanced` with file path instead of TE-TST ID

**Rationale:** The registry entry creation step is the hand-maintenance this change eliminates.

### Test Audit Task (PF-TSK-030)

**Changes needed:**
- `New-TestAuditReport.ps1` `-TestFileId` parameter changes to `-TestFilePath`
- Audit report metadata references file path instead of TE-TST ID
- test-tracking.md audit link column updated to reference by path

**Rationale:** Audit reports need to link to test files; the link mechanism changes from ID to path.

### Validate-TestTracking.ps1 (used by PF-TSK-053, PF-TSK-014, and various checklists)

**Changes needed:**
- Registry validation surface removed
- New validation: markers (via `test_query.py --dump`) ↔ test-tracking.md consistency
- Checks: every file in test-tracking.md exists on disk; every test file on disk has a tracking entry; feature IDs match; test counts match
- Warning (non-blocking): `test_type` marker doesn't match directory convention (e.g., file in `unit/` but marked `integration`) — marker is authoritative but mismatch is worth surfacing

**Rationale:** Validation must shift from registry-centric to marker-centric.

## Handover Interfaces

| From Task | To Task | Interface | Change |
|-----------|---------|-----------|--------|
| PF-TSK-053 (Integration & Testing) | PF-TSK-030 (Test Audit) | Test file identifier in test-tracking.md | Modified: TE-TST-XXX → file path |
| PF-TSK-078 (Core Logic Impl) | PF-TSK-053 (Integration & Testing) | New-TestFile.ps1 output | Modified: no registry entry, markers in file |
| PF-TSK-030 (Test Audit) | test-tracking.md | Audit report link in tracking row | Modified: keyed by path |

### Additional Tasks to Review

- **Test Specification Creation (PF-TSK-016)** — references test-registry.yaml in context requirements
- **E2E Acceptance Test Case Creation (PF-TSK-069)** — creates TE-E2E entries in registry (Phase 7 dependency)
- **Release & Deployment (PF-TSK-007)** — may reference registry in release checklist
- **Bug Fixing (PF-TSK-041)** — references test-registry.yaml for regression test lookup
- **Foundation Feature Implementation (PF-TSK-022)** — references registry in test creation workflow

## Testing Approach

### Test Cases

1. **Marker parity**: `test_query.py --dump --format yaml` output matches all marker-derived fields from current registry for all 31 test files
2. **Test count accuracy**: AST-counted test methods match `pytest --collect-only -q` counts per file
3. **Specification marker**: All files with `specificationPath` in current registry have matching `specification` marker
4. **test-tracking.md migration**: Migrated file has same number of rows, all file paths resolve, no data loss in non-ID columns
5. **New-TestFile.ps1**: Creates a test file with correct markers and a test-tracking.md row (no registry involvement)
6. **Validate-TestTracking.ps1**: Detects intentionally introduced inconsistencies (missing tracking entry, wrong feature ID, stale test count)
7. **End-to-end**: Create new test file → run test_query.py → verify it appears → run validation → 0 errors

### Success Criteria

- `Validate-StateTracking.ps1` reports 0 errors after full migration
- `test_query.py --summary` produces correct feature → test count mapping
- No script references `test-registry.yaml` or `TE-TST-XXX` (verified by grep)
- `pytest --collect-only --strict-markers` passes (all markers registered)
- Documentation grep for `test-registry.yaml` returns 0 hits outside of archive/historical files

## Rollback Plan

### Trigger Conditions

- `test_query.py` AST parsing fails on a valid test file format
- test-tracking.md migration loses data that cannot be recovered from git
- A downstream script depends on TE-TST-XXX IDs in a way not identified in this proposal

### Rollback Steps

1. `test-registry.yaml` remains in git history — restore with `git show HEAD~N:test/test-registry.yaml`
2. test-tracking.md can be restored from git history similarly
3. Script changes are isolated to well-defined functions — revert specific commits
4. Markers added in Phase 1 are harmless and can remain even if later phases are rolled back

**Risk assessment**: LOW. Each phase is independently reversible. The registry remains on disk through Phase 5, providing a fallback throughout the migration.

## Metrics

### Implementation Metrics

- Files modified per phase (target: Phase 1 ≤ 33, Phase 2 = 1 new file, Phase 3 ≤ 3, Phase 4 ≤ 7, Phase 5 ≤ 25, Phase 6 ≤ 3)
- Validation errors after each phase (target: 0)
- Grep hits for `test-registry.yaml` after Phase 6 (target: 0 outside archive)

### Success Metrics

- Time to add a new test file to the tracking system (target: same or less than current)
- `test_query.py` response time for `--feature` query (target: < 2 seconds)
- testCasesCount accuracy (target: 100% — no drift by definition)

## Language Portability

The marker-based approach separates the **framework skeleton** (language-agnostic) from **language-specific implementation details**. Adopting a new language requires implementing three components; everything else stays unchanged.

### Framework Skeleton (same across all languages)

```
test/
├── automated/                          # Source of truth (markers in code)
│   └── **/*.{py,dart,ts,...}           #   Language-specific metadata annotations
│
├── state-tracking/permanent/
│   └── test-tracking.md                # Status tracking, keyed by file path
│
├── specifications/                     # Test specs (language-agnostic markdown)
│
└── scripts/test/
    └── test_query.{py,dart,...}        # AST-based query tool
```

**Unchanged across languages:**
- `test-tracking.md` structure and workflow
- `Validate-TestTracking.ps1` validation logic (consumes `test_query` output)
- `New-TestFile.ps1` orchestration (calls language-specific template + `test_query`)
- All task definitions, guides, context maps, documentation map entries
- Required marker fields: `feature`, `priority`, `test_type`, `specification`, `cross_cutting`
- `test_query` CLI contract: `--feature`, `--type`, `--summary`, `--dump --format yaml|json`, `--file`

### Language-Specific Components (3 things to implement)

| Component | What changes | Python | Dart | TypeScript |
|-----------|-------------|--------|------|------------|
| **Metadata carrier** | How markers are expressed in code | `pytestmark = [pytest.mark.feature("0.1.1")]` | `@TestMetadata(feature: '0.1.1')` + `@Tags(['feature_0_1_1'])` | `/** @feature 0.1.1 */` or custom decorator |
| **AST parser** | How `test_query` reads markers | `ast` module (stdlib) | `package:analyzer` | TypeScript compiler API |
| **Marker registration** | Where the test framework learns about markers | `pyproject.toml` `[tool.pytest.ini_options]` | `dart_test.yaml` | `jest.config.ts` / `vitest.config.ts` |

### Dart Example

Dart requires a two-layer approach because `@Tags` only accepts flat string identifiers (no key-value pairs):

**Custom annotation** (structured data for `test_query`):
```dart
// lib/testing/test_metadata.dart
class TestMetadata {
  final String feature;
  final String priority;
  final String? specification;
  final List<String> crossCutting;
  const TestMetadata({
    required this.feature,
    required this.priority,
    this.specification,
    this.crossCutting = const [],
  });
}
```

**Test file** (both layers):
```dart
@TestMetadata(
  feature: '0.1.1',
  priority: 'Critical',
  specification: 'test/specifications/feature-specs/test-spec-0-1-1.md',
  crossCutting: ['1.1.1', '0.1.2'],
)
@Tags(['feature_0_1_1', 'critical'])
library;

import 'package:test/test.dart';
import 'package:my_app/testing/test_metadata.dart';
```

The `@Tags` layer is optional but enables `dart test -t feature_0_1_1` CLI filtering and IDE integration. The `@TestMetadata` layer is the source of truth that `test_query.dart` reads.

### Portability Principle

The determining factor for language adoption is: **does the language's test framework support some form of per-file metadata that an AST parser can read?** All major languages satisfy this:

| Language | Metadata mechanism | AST tooling |
|----------|-------------------|-------------|
| Python | `pytestmark` module-level list | `ast` (stdlib) |
| Dart | `@Annotation` on `library` directive | `package:analyzer` |
| TypeScript | JSDoc tags or decorators | TypeScript compiler API |
| Java | `@Tag` (JUnit 5) | `com.github.javaparser` |
| Go | Build tags + structured comments | `go/ast` (stdlib) |
| Rust | `#[cfg(test)]` attributes + doc comments | `syn` crate |

## Approval

**Approved By:** _________________
**Date:** 2026-03-25

**Comments:**

