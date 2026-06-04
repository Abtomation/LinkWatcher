---
title: "Temp State — MIG-005 Test/Audit Tree Reorganization (PRJ-001)"
type: Temporary task state (Framework Rollout PF-TSK-088 Mode C — MIG-005)
created: 2026-06-04
updated: 2026-06-04
owning_task: PF-TSK-088 (Framework Rollout, Mode C)
migration: MIG-005 (supersedes MIG-002)
status: Complete
---

# MIG-005 Test/Audit Tree Reorganization — Execution State

## Purpose

Apply the PF-IMP-871 Phase 3a/3b/4a test-infra layout to PRJ-001 (LinkWatcher), as prescribed by
`appdev/blueprint/test/`. This is **Option 3** (full local reorg of *both* source and audit trees),
chosen by the human partner after the audit-only MIG-005 was found to presuppose a source-tree reorg
that never happened on PRJ-001. Scope is broader than the ledger entry as written.

## Decisions (human-approved 2026-06-04)

1. **Config fix**: `doc/project-config.json` `paths.tests` `test/automated` → `test` (was the root cause of
   `New-TestInfrastructure -Update` doubling paths to `test/automated/automated/...`). ✅ DONE.
2. **Import mode**: added `--import-mode=importlib` to `pyproject.toml` addopts (nested dirs start with
   digits + contain hyphens → invalid Python package names under default prepend mode; importlib also
   tolerates the two distinct `test_config.py`). ✅ DONE. Re-baseline under importlib = identical result.
3. **Fold `integration/` + `parsers/` into `unit/<category>/`** by `feature` marker (appdev/blueprint have
   no `integration`/`parsers` dirs). `quickCategories` will drop `parsers`.
4. **Performance**: `test_benchmark.py` → `level2-operation/` for now; **TD created** to split BM
   component(L1)/operation(L2) later. `test_large_projects.py` → `level3-scale/`.
5. **Run full suite before + after** as regression gate.

## Test baseline (regression gate)

- Pre-move, prepend mode: **839 passed, 3 skipped, 4 deselected, 4 xfailed** (`-m "not slow"`), exit 0.
- Pre-move, importlib mode (current layout): **identical** → import-mode change is behavior-neutral.

## Target leaf dirs

| Key | Source dir | Audit mirror dir |
|---|---|---|
| 0 | `test/automated/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/` | `test/audits/unit/0-system-architecture-foundation/0-0-system-architecture-foundation/` |
| 1 | `test/automated/unit/1-file-watching-detection/1-0-file-watching-detection/` | `test/audits/unit/1-file-watching-detection/1-0-file-watching-detection/` |
| 2 | `test/automated/unit/2-link-parsing-update/2-0-link-parsing-update/` | `test/audits/unit/2-link-parsing-update/2-0-link-parsing-update/` |
| 3 | `test/automated/unit/3-logging-monitoring/3-0-logging-monitoring/` | `test/audits/unit/3-logging-monitoring/3-0-logging-monitoring/` |
| 6 | `test/automated/unit/6-link-validation-reporting/6-0-link-validation-reporting/` | `test/audits/unit/6-link-validation-reporting/6-0-link-validation-reporting/` |
| L2 | `test/automated/performance/level2-operation/` | `test/audits/performance/level2-operation/` |
| L3 | `test/automated/performance/level3-scale/` | `test/audits/performance/level3-scale/` |

**Stay put** (NOT moved): `test/automated/conftest.py`, `utils.py`, `__init__.py`, `test_config.py` (utility,
no marker), `fixtures/`, `bug-validation/` (MIG-004 scope). `audits/e2e/` stays.

## Source test files (34) — old → leaf

| # | Current path | Feature | Leaf | Status |
|---|---|---|---|---|
| 1 | automated/unit/test_service.py | 0.1.1 | 0 | ☐ |
| 2 | automated/unit/test_lock_file.py | 0.1.1 | 0 | ☐ |
| 3 | automated/unit/test_database.py | 0.1.2 | 0 | ☐ |
| 4 | automated/unit/test_config.py | 0.1.3 | 0 | ☐ |
| 5 | automated/integration/test_complex_scenarios.py | 0.1.1 | 0 | ☐ |
| 6 | automated/integration/test_error_handling.py | 0.1.1 | 0 | ☐ |
| 7 | automated/integration/test_service_integration.py | 0.1.1 | 0 | ☐ |
| 8 | automated/integration/test_windows_platform.py | 0.1.1 | 0 | ☐ |
| 9 | automated/unit/test_comprehensive_file_monitoring.py | 1.1.1 | 1 | ☐ |
| 10 | automated/unit/test_reference_lookup.py | 1.1.1 | 1 | ☐ |
| 11 | automated/integration/test_file_movement.py | 1.1.1 | 1 | ☐ |
| 12 | automated/integration/test_image_file_monitoring.py | 1.1.1 | 1 | ☐ |
| 13 | automated/integration/test_powershell_script_monitoring.py | 1.1.1 | 1 | ☐ |
| 14 | automated/integration/test_sequential_moves.py | 1.1.1 | 1 | ☐ |
| 15 | automated/test_move_detection.py | 1.1.1 | 1 | ☐ |
| 16 | automated/test_directory_move_detection.py | 1.1.1 | 1 | ☐ |
| 17 | automated/unit/test_parser.py | 2.1.1 | 2 | ☐ |
| 18 | automated/unit/test_updater.py | 2.2.1 | 2 | ☐ |
| 19 | automated/integration/test_link_updates.py | 2.2.1 | 2 | ☐ |
| 20 | automated/parsers/test_dart.py | 2.1.1 | 2 | ☐ |
| 21 | automated/parsers/test_generic.py | 2.1.1 | 2 | ☐ |
| 22 | automated/parsers/test_image_files.py | 2.1.1 | 2 | ☐ |
| 23 | automated/parsers/test_json.py | 2.1.1 | 2 | ☐ |
| 24 | automated/parsers/test_markdown.py | 2.1.1 | 2 | ☐ |
| 25 | automated/parsers/test_powershell.py | 2.1.1 | 2 | ☐ |
| 26 | automated/parsers/test_python.py | 2.1.1 | 2 | ☐ |
| 27 | automated/parsers/test_yaml.py | 2.1.1 | 2 | ☐ |
| 28 | automated/unit/test_advanced_logging.py | 3.1.1 | 3 | ☐ |
| 29 | automated/unit/test_logging.py | 3.1.1 | 3 | ☐ |
| 30 | automated/unit/test_main_logging_setup.py | 3.1.1 | 3 | ☐ |
| 31 | automated/unit/test_validator.py | 6.1.1 | 6 | ☐ |
| 32 | automated/unit/test_shouldmonitorfileancestorpath.py | 6.1.1 | 6 | ☐ |
| 33 | automated/performance/test_benchmark.py | BM-* | L2 | ☐ |
| 34 | automated/performance/test_large_projects.py | PH-* (4.1.1) | L3 | ☐ |

## Audit reports (36) — old → mirror leaf

| # | Current path (under test/audits/) | Mirror leaf | Status |
|---|---|---|---|
| a1 | foundation/audit-report-0-1-1-pd-tst-102.md | 0 | ☐ |
| a2 | foundation/audit-report-0-1-1-test-complex-scenarios.md | 0 | ☐ |
| a3 | foundation/audit-report-0-1-1-test-error-handling.md | 0 | ☐ |
| a4 | foundation/audit-report-0-1-1-test-lock-file.md | 0 | ☐ |
| a5 | foundation/audit-report-0-1-1-test-service-integration.md | 0 | ☐ |
| a6 | foundation/audit-report-0-1-1-test-service.md | 0 | ☐ |
| a7 | foundation/audit-report-0-1-1-test-windows-platform.md | 0 | ☐ |
| a8 | foundation/audit-report-0-1-2-pd-tst-104.md | 0 | ☐ |
| a9 | foundation/audit-report-0-1-2-test-database.md | 0 | ☐ |
| a10 | foundation/audit-report-0-1-3-pd-tst-106.md | 0 | ☐ |
| a11 | foundation/audit-report-0-1-3-test-config.md | 0 | ☐ |
| a12 | authentication/audit-report-1-1-1-pd-tst-101.md | 1 | ☐ |
| a13 | authentication/audit-report-1-1-1-test-comprehensive-file-monitoring.md | 1 | ☐ |
| a14 | authentication/audit-report-1-1-1-test-file-movement.md | 1 | ☐ |
| a15 | authentication/audit-report-1-1-1-test-image-file-monitoring.md | 1 | ☐ |
| a16 | authentication/audit-report-1-1-1-test-move-detection.md | 1 | ☐ |
| a17 | authentication/audit-report-1-1-1-test-powershell-script-monitoring.md | 1 | ☐ |
| a18 | authentication/audit-report-1-1-1-test-sequential-moves.md | 1 | ☐ |
| a19 | core-features/audit-report-2-1-1-pd-tst-103.md | 2 | ☐ |
| a20 | core-features/audit-report-2-1-1-test-json.md | 2 | ☐ |
| a21 | core-features/audit-report-2-1-1-test-markdown.md | 2 | ☐ |
| a22 | core-features/audit-report-2-1-1-test-parser.md | 2 | ☐ |
| a23 | core-features/audit-report-2-1-1-test-python.md | 2 | ☐ |
| a24 | core-features/audit-report-2-1-1-test-yaml.md | 2 | ☐ |
| a25 | core-features/audit-report-2-2-1-pd-tst-105.md | 2 | ☐ |
| a26 | core-features/audit-report-2-2-1-test-link-updates.md | 2 | ☐ |
| a27 | core-features/audit-report-2-2-1-test-updater.md | 2 | ☐ |
| a28 | core-features/audit-report-3-1-1-pd-tst-107.md | 3 | ☐ |
| a29 | core-features/audit-report-3-1-1-test-advanced-logging.md | 3 | ☐ |
| a30 | core-features/audit-report-3-1-1-test-logging.md | 3 | ☐ |
| a31 | core-features/audit-report-6-1-1-test-shouldmonitorfileancestorpath.md | 6 | ☐ |
| a32 | core-features/audit-report-6-1-1-test-validator.md | 6 | ☐ |
| a33 | performance/audit-report-2-1-1-test-benchmark.md | L2 | ☐ |
| a34 | performance/audit-report-0-1-1-test-large-projects.md | L3 | ☐ |
| a35 | performance/old/audit-report-2-1-1-test-benchmark-2026-04-20.md | L2 (archived) | ☐ |
| a36 | performance/old/audit-report-0-1-1-test-large-projects-2026-04-29-TE-TAR-070.md | L3 (archived) | ☐ |

## Post-move steps

- ☐ Run `New-TestInfrastructure.ps1 -Update` (corrected config) → regen `audits/README.md` + `TE-id-registry.json` (TE-TAR/TE-TST `directories`)
- ☐ Remove stale `audits/{foundation,authentication,core-features}/` (+ empty `old/` subdirs); remove emptied `automated/{integration,parsers}/`
- ☐ `test/archive/` decision (holds `test-registry-archived-2026-03-26.yaml`) — leave in place (referenced history)
- ☐ `project-config.json` `quickCategories`: drop `parsers`
- ☐ Full suite regression run — must match baseline (≈839 passed)
- ☐ TD item: split `test_benchmark.py` BM component(L1)/operation(L2)
- ☐ `Validate-StateTracking.ps1 -Surface AuditMirror,CategoryAlignment`; `Validate-TestTracking.ps1`; `python main.py --validate`
- ☐ Resolve MIG-005 in ledger (note expanded scope; supersedes MIG-002) + feedback form

## Execution log

- 2026-06-04: paths.tests fix, importlib addopts, re-baseline (839 passed). Temp file created.
- 2026-06-04: Pilot (test_validator.py + audit) — LinkWatcher updated links in 2s; 111 passed at new location.
- 2026-06-04: Moved all 34 test files (Batches T1/T2/P) + 36 audit reports (Batches A/B + pilot). All LinkWatcher link updates confirmed. Old `audits/{foundation,authentication,core-features}/` + `automated/{integration,parsers}/` removed. `New-TestInfrastructure -Update` regenerated README (auto-gen banner) + registry (TE-TAR/TE-TST clean). `quickCategories` → `[unit]`. `__pycache__` cleaned from registry.
- 2026-06-04: **LinkWatcher corrupted 18 moved test files' path-like data strings** ("fix relative links inside moved file" misfire). Restored all 18 in place from exact HEAD content; verified 18/18 == HEAD; no re-corruption (modify ≠ move).
- 2026-06-04: **Regression GREEN** — `839 passed, 3 skipped, 4 deselected, 4 xfailed` (= baseline) + `4 slow passed`. `Validate-TestTracking` 0 errors (33 pre-existing count warnings). `CategoryAlignment` 0 errors. `AuditMirror` 2 errors = pre-existing `fixtures/` false-positives. `main.py --validate`: only 7 of the project's 1172 standing broken-links touch migrated files, all pre-existing content false-positives.
- 2026-06-04: TD254 created (split perf files across levels). MIG-005 Resolved in ledger (supersedes MIG-002) with expanded-scope note. Feedback form completed.

## Outcome

✅ **COMPLETE.** Test/audit tree reorganized to appdev-prescribed layout; suite behavior-preserved (843 passing). Follow-up IMP candidates recorded in the ledger Resolution Note (alpha-project namespace migration for old test files; AuditMirror fixtures false-positive; registry __pycache__ noise; MIG-007 doc-map headings).
