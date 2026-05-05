---
id: PD-REF-214
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
debt_item: TD250
mode: lightweight
refactoring_scope: Add psutil to test extra in pyproject.toml
priority: Medium
target_area: pyproject.toml
---

# Lightweight Refactoring Plan: Add psutil to test extra in pyproject.toml

- **Target Area**: pyproject.toml
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD250
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD250 — Add psutil to test extra in pyproject.toml

**Dimension**: TST (Testing)

**Scope**: PH-007 (memory) and PH-008 (CPU) in `test/automated/performance/test_large_projects.py` use `pytest.importorskip("psutil")` at lines 501 and 560. When psutil is not installed in the test environment, both tests silently skip — this caused false-compliance baselines on 2026-04-09 (PH-007/PH-008 marked Baselined with Last Result=skipped, identified in audit TE-TAR-070 Criterion 3). Fix: declare `psutil>=5.9.0` in `[project.optional-dependencies].test` so the standard `pip install -e ".[test]"` workflow guarantees the dep is present and `importorskip` actually exercises the tests.

**Changes Made**:
- [x] Added `"psutil>=5.9.0"` to `[project.optional-dependencies].test` in `pyproject.toml` (after `responses>=0.23.0`).

**Test Baseline** (2026-04-29, `pytest test/automated/ -m "not slow"`):
- 829 passed, 2 failed, 3 skipped, 4 deselected, 4 xfailed (105.99s)
- Pre-existing failures:
  - `test/automated/performance/test_large_projects.py::TestPerformanceMetrics::test_cpu_usage_monitoring` (PH-008 — flaky, CPU-load-dependent per TD247)
  - `test/automated/unit/test_validator.py::TestLinkValidator::test_linkwatcher_local_dir_ignored` (validator does not auto-skip `process-framework-local/tools/linkWatcher/` — pre-existing)

**Test Result** (post-change, same command):
- 830 passed, 1 failed, 3 skipped, 4 deselected, 4 xfailed (96.85s)
- Remaining failure: `test_linkwatcher_local_dir_ignored` (unchanged from baseline)
- PH-008 `test_cpu_usage_monitoring` passed on this run (consistent with TD247 flakiness — host CPU load dependent)
- **Diff vs baseline**: 0 new failures. The pyproject.toml `[project.optional-dependencies].test` edit cannot affect runtime test behavior (pytest does not read this section).

**Documentation & State Updates**:
<!-- Items 1-6 batched N/A via Test-only shortcut: pyproject.toml [project.optional-dependencies].test edit affects only test environment installation; no production code, design documents, or validation artifacts reference test deps lists. -->
- [x] Items 1–6 (Feature state, TDD, Test spec, FDD, ADR, Validation tracking): **N/A — Test-only refactoring** (build/test config only; no production code changes; design and state documents do not reference test extras).
- [x] Integration Narrative: **N/A** — same justification (no PD-INT narrative references pyproject.toml or test deps).
- [ ] Technical Debt Tracking: TD250 marked resolved (handled in L10)

**Bugs Discovered**: None.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD250 | Complete | None | None (test-only shortcut applied — no production code or design docs affected) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
