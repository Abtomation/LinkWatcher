---
id: PD-REF-197
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-28
updated: 2026-04-28
refactoring_scope: Wire max_file_size_mb config field into scan and runtime read paths so it has its documented effect
priority: Medium
mode: lightweight
debt_item: TD227
target_area: src/linkwatcher (config + scan + handler)
---

# Lightweight Refactoring Plan: Wire max_file_size_mb config field into scan and runtime read paths so it has its documented effect

- **Target Area**: src/linkwatcher (config + scan + handler)
- **Priority**: Medium
- **Created**: 2026-04-28
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Debt Item**: TD227
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD227 — Wire max_file_size_mb into parse path

**Scope**: The config field `max_file_size_mb` is declared, validated, presetted (DEFAULT=10, PRODUCTION=5), exposed via env var and YAML/JSON config, and documented in three handbooks as "Skip files larger than this", but it is never read by any code outside `config.validate()`. Validation reports PD-VAL-055/076/096/097 cite it as an existing memory-protection mitigation. This item wires the field into `LinkParser.parse_file` so every file-read path (initial scan, rescan, retry, post-move rescan) honors it. **Dimension**: EM (Extensibility/Maintainability).

**Approach**: Single-gate wire-in at the parser level — `LinkParser.parse_file` is the only function called by all read paths (verified via grep of `parse_file` and `rescan_file_links` call sites). Changes are confined to one new helper in `utils.py` and one capture+check pair in `parser.py`. No call-site changes needed in `service.py`, `handler.py`, or `reference_lookup.py`.

**Changes Made**:
- [x] Added `is_file_size_within_limit(file_path, max_size_mb)` helper to [src/linkwatcher/utils.py](src/linkwatcher/utils.py): returns True if file is within limit; treats `max_size_mb <= 0` as disabled; treats stat failures as "let downstream handle it" (return True).
- [x] In [src/linkwatcher/parser.py](src/linkwatcher/parser.py) `LinkParser.__init__`: captured `self.max_file_size_mb = config.max_file_size_mb if config else DEFAULT_CONFIG.max_file_size_mb`. Imported `DEFAULT_CONFIG` and `is_file_size_within_limit`.
- [x] In `LinkParser.parse_file`: added size check at top after computing `file_ext`; oversized files log `file_skipped_oversize` warning with `file_path`/`size_mb`/`limit_mb` and return `[]`.
- [x] Added 4 unit tests in [test/automated/unit/test_parser.py](test/automated/unit/test_parser.py) `TestLinkParserMaxFileSize` class: under-limit parses normally, oversized returns `[]`, `max_file_size_mb=0` disables check, missing file still graceful-empty.

**Test Baseline** (captured 2026-04-28 before any code changes, full suite minus `slow`):
- 804 passed, 6 failed, 5 skipped, 4 xfailed (218.39s)
- Pre-existing failures:
  - `test/automated/integration/test_link_updates.py::TestBug094PythonImportDoubleApply::test_bug094_multi_rename_order_independent`
  - `test/automated/performance/test_benchmark.py::TestParsingBenchmark::test_bm_001_parsing_throughput`
  - `test/automated/performance/test_benchmark.py::TestDatabaseBenchmark::test_bm_002_database_operations`
  - `test/automated/performance/test_benchmark.py::TestUpdaterBenchmark::test_bm_004_updater_throughput`
  - `test/automated/performance/test_benchmark.py::TestValidationBenchmark::test_bm_005_validation_mode`
  - `test/automated/performance/test_large_projects.py::TestLargeProjectHandling::test_ph_004_many_references_to_single_file`

**Test Result** (full suite, 2026-04-28):
- 810 passed (was 804 — gained 4 new size-gate tests + 2 baseline flaky-pass), 4 failed, 5 skipped, 5 xfailed (252.99s)
- **Diff vs baseline**: 0 new regressions owned by this session.
  - Pre-existing failures still failing: `test_bm_001_parsing_throughput`, `test_bm_004_updater_throughput`, `test_ph_004_many_references_to_single_file` (all perf benchmarks; were in baseline)
  - Baseline failures now passing (flaky): `test_bug094_multi_rename_order_independent`, `test_bm_002_database_operations`, `test_bm_005_validation_mode`
  - New flake: `test_advanced_logging.py::TestLoggingPerformance::test_logging_overhead` — verified passes in isolation, does not import parser/utils, unrelated to this change.
- All 4 new `TestLinkParserMaxFileSize` tests pass.
- All 12 pre-existing `TestLinkParser` tests still pass.

**Documentation & State Updates**:
- [x] Feature implementation state file updated, or N/A: _N/A — grepped `doc/state-tracking/features/*.md`, zero matches for `max_file_size_mb`. Neither 0.1.3 nor 2.1.1 state files reference the field._
- [x] TDD updated, or N/A: _N/A — grepped `doc/technical/tdd/*.md`, zero matches for `max_file_size_mb`. No TDD documents file-size gating._
- [x] Test spec updated: [test-spec-2-1-1-link-parsing-system.md](test/specifications/feature-specs/test-spec-2-1-1-link-parsing-system.md) — added 4 new rows in "Unit Tests — Parser Facade" table for the size-gate cases; bumped method count 12 → 16. (test-spec-0-1-3-configuration-system.md already references `max_file_size_mb` only in the validation context, which is unchanged — no edit needed there.)
- [x] FDD updated, or N/A: _N/A — grepped `doc/functional-design/fdds/*.md`, zero matches for `max_file_size_mb`._
- [x] ADR updated, or N/A: _N/A — grepped `doc/technical/adr/*.md`, zero matches; no architectural decision affected._
- [x] Integration Narrative updated: [configuration-change-integration-narrative.md](doc/technical/integration/configuration-change-integration-narrative.md) — added `max_file_size_mb` row to Consumed-fields table under feature 2.1.1; removed it from Orphan-configuration-fields table; updated TD reference list `TD227, TD229, TD231` → `TD229, TD231`; added a "Resolved" pointer note above the orphan table referencing PD-REF-197.
- [x] Validation tracking updated, or N/A: _N/A — grepped active rounds [validation-tracking-3.md](doc/state-tracking/validation/validation-tracking-3.md) and [validation-tracking-4.md](doc/state-tracking/validation/validation-tracking-4.md): zero matches for TD227 or `max_file_size_mb`. Historical reports PD-VAL-055/076/096/097 cited the field as a mitigation — those statements are now actually true after this fix; no edits to historical reports needed._
- [ ] Technical Debt Tracking: TD227 marked resolved (pending — to be done at L10 via `Update-TechDebt.ps1`)

**Bugs Discovered**: None / [Description]

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD227 | Complete | None | test-spec-2-1-1-link-parsing-system.md (added 4 size-gate test rows); configuration-change-integration-narrative.md (moved field from Orphan to Consumed table) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

