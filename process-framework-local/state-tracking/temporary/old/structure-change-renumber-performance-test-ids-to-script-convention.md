---
id: PF-STA-099
type: Document
category: General
version: 1.0
created: 2026-04-29
updated: 2026-04-29
change_name: renumber-performance-test-ids-to-script-convention
---

# Structure Change State: Renumber Performance Test IDs to Script Convention

> **Status**: COMPLETED 2026-04-29 — ready for archive to `process-framework-local/state-tracking/temporary/old/`.

## Structure Change Overview
- **Change Name**: Renumber Performance Test IDs to Script Convention
- **Change Type**: Content Update (Mechanical Rename Variant of PF-TSK-014)
- **Scope**: Split duplicate BM-002 into BM-002/BM-007/BM-008; rename PH-MEM to PH-007 and PH-CPU to PH-008; bump `nextAvailable` counters in TE-id-registry.json
- **Completed**: 2026-04-29 (single session)

## Content Changes

### Change Description

The performance test tracking file had three rows sharing `BM-002` (DB add/lookup/update — duplicate IDs) and two non-numeric IDs `PH-MEM`/`PH-CPU` that bypassed the sequential numbering convention enforced by [New-PerformanceTestEntry.ps1](/process-framework/scripts/file-creation/03-testing/New-PerformanceTestEntry.ps1). The migration was originally done by hand from `test-tracking.md` on 2026-04-09 without going through the script. This change reconciles existing IDs to the script's auto-assignment convention (sequential numeric per prefix).

### Affected Files

| File | Change | Status |
|------|--------|--------|
| [test/state-tracking/permanent/performance-test-tracking.md](/test/state-tracking/permanent/performance-test-tracking.md) | Split BM-002 (×3 rows) → BM-002/BM-007/BM-008; PH-MEM→PH-007, PH-CPU→PH-008 | DONE |
| [test/state-tracking/audit/audit-tracking-performance-1.md](/test/state-tracking/audit/audit-tracking-performance-1.md) | Inventory rows + session planning text | DONE |
| [test/audits/performance/audit-report-2-1-1-test-benchmark.md](/test/audits/performance/audit-report-2-1-1-test-benchmark.md) | Replace BM-002 Adds/Lookups/Updates with BM-002/BM-007/BM-008; update bare BM-002 umbrella references | DONE |
| [test/audits/performance/audit-report-0-1-1-test-large-projects.md](/test/audits/performance/audit-report-0-1-1-test-large-projects.md) | Replace PH-MEM/PH-CPU references throughout (TE-TAR-070, active audit) | DONE |
| [test/automated/performance/test_benchmark.py](/test/automated/performance/test_benchmark.py) | File-level + method-level docstrings | DONE |
| [test/automated/performance/test_large_projects.py](/test/automated/performance/test_large_projects.py) | File-level docstring (added PH-006/PH-007/PH-008 entries) | DONE |
| [test/TE-id-registry.json](/test/TE-id-registry.json) | `BM.nextAvailable: 7→9`, `PH.nextAvailable: 7→9` | DONE |
| [doc/state-tracking/permanent/technical-debt-tracking.md](/doc/state-tracking/permanent/technical-debt-tracking.md) | TD215, TD216, TD236, TD237 description columns annotated with new IDs | DONE |

### Non-File Updates

| Component | Change | Status |
|-----------|--------|--------|
| [process-framework/scripts/test/performance_db.py](/process-framework/scripts/test/performance_db.py) | TOLERANCES dict keys: `BM-002-add`→`BM-002`, `BM-002-lookup`→`BM-007`, `BM-002-update`→`BM-008` | DONE |
| `test/state-tracking/permanent/performance-results.db` (SQLite) | `UPDATE results SET test_id` for the 3 BM-002-* rows; baseline history preserved | DONE |

## Frozen Historical Files (intentionally NOT updated)

- `test/audits/performance/old/audit-report-2-1-1-test-benchmark-2026-04-20.md` — archived prior audit
- `doc/refactoring/plans/archive/tighten-bm-002-bm-006-tolerances-add-warmups-switch-to-perf.md` — archived plan
- `doc/refactoring/plans/archive/remove-pytest-mark-slow-from-bm-003-initial-scan-benchmark.md` — archived plan
- `process-framework-local/feedback/feedback-forms/*` and `archive/*` — frozen session records
- `process-framework-local/state-tracking/temporary/old/*` — historical
- `process-framework-local/proposals/old/performance-testing-framework.md` — historical proposal

## Final ID Mapping

| Old | New | Notes |
|-----|-----|-------|
| BM-002 (DB add row) | BM-002 | unchanged |
| BM-002 (DB lookup row) | BM-007 | new |
| BM-002 (DB update row) | BM-008 | new |
| BM-002-add (DB key) | BM-002 | DB row migrated |
| BM-002-lookup (DB key) | BM-007 | DB row migrated |
| BM-002-update (DB key) | BM-008 | DB row migrated |
| PH-MEM | PH-007 | renamed |
| PH-CPU | PH-008 | renamed |

## Validation

- [x] Grep sweep — no live references to PH-MEM, PH-CPU, BM-002-add, BM-002-lookup, or BM-002-update remain in non-archived files
- [x] `Validate-StateTracking.ps1` — 4 errors total, all pre-existing (6.1.1 broken link, git-commit-and-push-map missing field, SourceRoot 'linkwatcher' missing, 3.1.1 test status aggregation mismatch); none introduced by this rename
- [x] Performance results DB — 17 distinct test_ids before, 17 after, no row count change

## Follow-up

- **TD245** added to [technical-debt-tracking.md](/doc/state-tracking/permanent/technical-debt-tracking.md): framework-shared performance docs (`performance-testing-guide.md`, `performance-baseline-capture-task.md`, `performance_db.py` TOLERANCES) reference project-specific test IDs as concrete examples — should be replaced with generic placeholders or moved to project-side config. Discovered during this task.

## Completion Criteria

- [x] All content changes applied
- [x] Validation confirms no stale patterns remain
- [x] Tech debt logged for framework-shareable concerns (TD245)
- [x] Feedback form completed
