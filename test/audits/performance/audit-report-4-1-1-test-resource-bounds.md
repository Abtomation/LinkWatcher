---
id: TE-TAR-072
type: Performance Test Audit
category: Test Audit Report
version: 1.0
created: 2026-06-04
updated: 2026-06-04
auditor: AI Agent
feature_id: 4.1.1
test_file_path: test/automated/performance/level4-resource/test_resource_bounds.py
audit_date: 2026-06-04
---

# Performance Test Audit Report - Feature 4.1.1 (Resource Bounds, cross-cutting)

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | 4.1.1 (performance/scalability cross-cutting) — touches 0.1.1 (scan), 1.1.1 (move detection), 2.2.1 (updater) |
| **Test File ID** | test_resource_bounds.py |
| **Test File Location** | `test/automated/performance/level4-resource/test_resource_bounds.py` |
| **Performance Level** | Resource (L4) — PH-007 (memory), PH-008 (CPU) |
| **Auditor** | AI Agent |
| **Audit Date** | 2026-06-04 |
| **Audit Status** | ✅ Audit Approved |
| **Audit Type** | Fresh per-level re-audit mandated by the **TD254 split** (2026-06-04, PD-REF-231): PH-007/PH-008 were spun out of `test_large_projects.py` into this Level-4 file. The pre-split combined file was approved by [TE-TAR-071](level3-scale/audit-report-0-1-1-test-large-projects.md) (2026-04-29); that report is retained as historical reference only — all four criteria were re-evaluated independently here against the live file and two fresh stability runs. Both rows were flagged 🔄 Needs Update in [performance-test-tracking.md](/test/state-tracking/permanent/performance-test-tracking.md) pending this audit. |

## Tests Audited

Measured across **2 consecutive runs** of this file (direct-path invocation, `-v -s --durations=0`) on the audit machine (2026-06-04; 16 logical cores; psutil 7.2.2; Python 3.11). Both runs: **2/2 PASSED**.

| Test ID | Metric | Operation | Level | Related Features | Current Status | Calibration Baseline | Tolerance Ratio | Tolerance (absolute) | Last Result (this audit) |
|---------|--------|-----------|-------|-----------------|----------------|----------------------|-----------------|----------------------|--------------------------|
| PH-007 | net | Memory usage (200 files) | L4 | cross-cutting | ✅ Baselined (audit re-flagged 🔄 by TD254 split) | ~0 MB (RSS roughly flat post-scan; GC noise) | resource ceiling (not a multiplier) | `<100 MB` | -1.9 MB (run 1), 0.3 MB (run 2) |
| PH-007 | op-delta | Memory usage (200 files) | L4 | cross-cutting | ✅ Baselined (audit re-flagged 🔄 by TD254 split) | ~5.0 MB during 10 moves | ~4× typical | `<20 MB` | 5.0 MB (both runs) |
| PH-008 | avg-raw | CPU usage (100 files + 20 moves) | L4 | cross-cutting | ✅ Baselined (audit re-flagged 🔄 by TD254 split) | 56–65% raw → 3.5–4.1% per-core normalized | ~20× headroom on normalized | `(avg/cpu_count) < 80%` (enforced in test code) | 56.1% raw → 3.5% norm (run 1); 65.3% raw → 4.1% norm (run 2) |
| PH-008 | peak | CPU usage (100 files + 20 moves) | L4 | cross-cutting | ✅ Baselined (diagnostic only post-PD-REF-217) | n/a (diagnostic) | n/a — not asserted | `—` | 116.4% (run 1), 117.6% (run 2) |

> **Why three tolerance columns**: Tests in code use absolute numbers, but absolutes go stale when typical measurements drift. The **Calibration Baseline** (what was typical at audit time) plus the **Tolerance Ratio** (the auditor's judgment) preserve the math intent so future refactorings can recompute `current_baseline × ratio` instead of inheriting a stale absolute. For L4 resource ceilings, the "ratio" is a headroom factor over typical, not a tight multiplier — resource gating asks "does it stay bounded?" not "is it 10% slower than yesterday?".

> **Behavior preservation across the split**: Every metric tracks its 2026-04-29 baseline closely (op-delta 4.9→5.0 MB; net ≈0; PH-008 normalized 4.1%→3.5–4.1%; peak 117.6%). This confirms TD254's claim that the split preserved test logic, assertions, tolerances, and baselines. The existing baselines remain **valid** — no re-baseline is warranted.

## Audit Evaluation

### 1. Measurement Methodology
**Question**: Is the test measuring the right thing with appropriate precision?

**Assessment**: PASS

**Findings**:
- **Warmup cycles**: Both tests warm up **before** the measured window via the shared `warmup_service` factory fixture in [performance/conftest.py](/test/automated/performance/conftest.py). PH-007 calls `warmup_service(num_files=5)` at [test_resource_bounds.py:40](/test/automated/performance/level4-resource/test_resource_bounds.py) before `initial_memory` is captured; PH-008 calls `warmup_service(num_files=5, num_moves=1)` at [test_resource_bounds.py:105](/test/automated/performance/level4-resource/test_resource_bounds.py) before the `monitor_cpu` thread starts. The fixture instantiates a separate `LinkWatcherService` + initial scan against an **external** `tempfile.TemporaryDirectory()`, so warmup files are excluded from the test's own scan. This is functionally equivalent to the in-file `_warmup_service()` helper TE-TAR-071 approved; the conftest indirection is sound and well-justified (level dirs contain hyphens → not importable under `--import-mode=importlib`, so a fixture is the only import-safe sharing channel). Carries TD246 forward — verified.
- **Iteration count**: Single measurement per test. Consistent with the established performance-suite pattern (BM tests post-PD-REF-196, PH-001..006); statistical aggregation is deferred to baseline capture (PF-TSK-085) + `performance_db.py`. No regression vs the approved bar.
- **Timing precision**: N/A for resource tests — these assert on `psutil` RSS/CPU, not wall-clock. No `time.time()` / `perf_counter()` concern applies.
- **CPU measurement correctness (PH-008)**: Measures **this process**, not host-wide — `process = psutil.Process(os.getpid())` then `process.cpu_percent(interval=0.1)` inside the monitor thread ([test_resource_bounds.py:113-117](/test/automated/performance/level4-resource/test_resource_bounds.py)). The avg assertion is per-core normalized: `(avg_cpu / cpu_count) < 80` ([test_resource_bounds.py:168-169](/test/automated/performance/level4-resource/test_resource_bounds.py)) — preserving `[0,100]` semantics on multi-core hosts. The peak assertion is removed (diagnostic-only), eliminating the false-positive class TE-TAR-071 documented. Carries TD247 / TD249's PH-008 sub-item forward — verified.
- **Memory measurement (PH-007)**: `initial_memory` captured after warmup but before the 200-file fixture; `after_scan_memory` after `_initial_scan()`; `memory_increase` brackets the scan. A second window (`operation_memory_change`) brackets 10 move operations to catch leaks. Both windows are correctly isolated — file creation and print statements sit outside the assertion-relevant deltas.
- **Isolation**: `temp_project_dir` fixture (`tempfile.mkdtemp()` + `shutil.rmtree` teardown) gives clean per-test tempdirs **outside the workspace** — so the repo's running LinkWatcher daemon does not interfere with fixtures, and warmup uses a separate external tempdir.
- **Result stability** (2 runs):

| Metric | Run 1 | Run 2 | Verdict |
|--------|-------|-------|---------|
| PH-007 net | -1.9 MB | 0.3 MB | Stable near 0 (GC noise); far under 100 MB ceiling |
| PH-007 op-delta | 5.0 MB | 5.0 MB | Identical |
| PH-008 avg (normalized) | 3.5% | 4.1% | Stable; ~20× under 80% threshold |
| PH-008 peak (diagnostic) | 116.4% | 117.6% | Stable; not asserted |

**Evidence**:
- Run 1: `Memory increase: -1.9MB for 200 files` / `Memory change during operations: 5.0MB`; `CPU usage - Average: 56.1%, Peak: 116.4%`. Run 2: `Memory increase: 0.3MB` / `5.0MB`; `CPU - Average: 65.3%, Peak: 117.6%`.
- PH-008 raw avg varies with host load (56→65%) but per-core normalized stays at 3.5–4.1% — the normalization makes the assertion robust to background load, exactly as designed.

**Recommendations**:
- None blocking. Methodology is consistent with the approved BM/PH bar.

---

### 2. Tolerance Appropriateness
**Question**: Are thresholds realistic, meaningful, and calibrated to observed variance?

**Assessment**: PASS

Per [Performance Testing Guide §Level 4](/process-framework/guides/03-testing/performance-testing-guide.md#performance-test-levels), L4 tolerances are **ceilings derived from observed peak** — resource bounds, not throughput multipliers. Loose-by-design is correct here.

| Metric | Typical (this audit) | Tolerance | Headroom | Verdict |
|--------|----------------------|-----------|----------|---------|
| PH-007 net | ≈0 MB (-1.9 / 0.3) | `<100 MB` | n/a (ceiling) | ✅ Reasonable resource ceiling |
| PH-007 op-delta | 5.0 MB | `<20 MB` | ~4× | ✅ Within L4 guide; catches a real leak (4× growth) |
| PH-008 avg-norm | 3.5–4.1% | `<80%` | ~20× | ⚠️ Loose — but L4 by design ("does it pin the box?" not "5% more CPU") |
| PH-008 peak | 116–118% | `—` | n/a | ✅ Correctly un-asserted (interval-sampler peaks are unstable) |

**Code ↔ tracking consistency** (Criterion-3 cross-check performed here too):

| Metric | Code assertion | Tracking Tolerance | Match? |
|--------|----------------|--------------------|--------|
| PH-007 net | `memory_increase < 100` | `<100MB` | ✅ |
| PH-007 op-delta | `abs(operation_memory_change) < 20` | `<20MB` | ✅ |
| PH-008 avg-raw | `(avg_cpu / cpu_count) < 80` | `—` (enforced in code; non-band entries skipped by `performance_db.py`) | ✅ consistent with the documented convention |
| PH-008 peak | (assertion removed) | `—` | ✅ |

**Evidence**:
- All four tracking-file Tolerance cells agree with the live code assertions — **no drift**. (Contrast: the BM rows in the same tracking file still carry 🔄 Needs Update from a separate pending re-audit — out of this audit's scope.)

**Recommendations**:
- None blocking. Tolerances are guide-aligned and trip on meaningful resource events.

---

### 3. Baseline Readiness
**Question**: Is the test ready for reliable baseline capture?

**Assessment**: PASS (with one discoverability fix applied during this audit — see Minor Fixes)

**Findings**:
- **Setup/teardown**: `temp_project_dir` (mkdtemp + rmtree) — clean per-test isolation, no leftover state. ✅
- **Determinism**: Fixtures built from `range()` loops; no randomness. ✅
- **External dependencies**: PH-007/PH-008 require `psutil`, declared as `psutil>=5.9.0` in [pyproject.toml](/pyproject.toml) `[project.optional-dependencies].test` (verified at audit time). `pip install -e .[test]` installs it; tests will not silently `importorskip`. Carries TD250 forward — verified.
- **Tracking-file consistency**: Verified — all four Tolerance cells match code (see Criterion 2). ✅
- **Test discoverability (finding → fixed)**: As created, the file carried only `test_type("performance")` at module scope — **not** the bare `@pytest.mark.performance` marker. Empirically, `pytest test/automated/performance -m performance --collect-only` collected **6/14** tests and **deselected all 8 PH tests** (PH-007/008 included). This matters because the framework's `performance` test category maps to `-m performance` ([python-config.json](/process-framework/languages-config/python/python-config.json) line 25) and the Performance Testing Guide's documented baseline command is `pytest test/automated/performance/ -v -s -m performance`. So the **standard/documented selection path silently skipped these tests** — a baseline-readiness defect. The tests also lacked `@pytest.mark.slow` despite running ~21–29s (>>10s; the Level-4 guide and the L3 sibling both require/use `slow`). **Both markers were added during this audit** (see Minor Fixes); re-verification: `-m performance` now collects 8/14 and both tests are reachable under `-m "performance and slow"`.
- **Environment requirements**: Python 3.9+, `watchdog`, `pytest`, `psutil` — all in pyproject.toml extras. 16-core host; per-core normalization keeps PH-008 portable across core counts.
- **Marker discipline**: module-level `feature("4.1.1")`, `priority("Extended")`, `cross_cutting(["0.1.1","1.1.1","2.2.1"])`, `test_type("performance")`, plus the newly added `performance` + `slow`. All registered in pyproject.toml under `--strict-markers`. ✅

**Evidence**:
- 2 full runs of the file, 4/4 test executions PASS.
- `-m performance` collection: 6/14 → 8/14 after the marker fix (PH-007/008 now included).
- pyproject.toml test extras inspected — `psutil>=5.9.0` present.

**Recommendations**:
- None blocking after the marker fix. Ready for baseline capture / regression monitoring.
- **PF-TSK-085 note**: baselines from 2026-04-29 remain valid (behavior preserved by the split, confirmed by this audit's measurements) — no re-baseline required. If a future capture uses the `-m performance` path, it will now include these tests.

---

### 4. Regression Detection Config
**Question**: Will this test actually catch meaningful regressions?

**Assessment**: PASS

| Metric | Tolerance | Typical | What trips it | Verdict |
|--------|-----------|---------|---------------|---------|
| PH-007 net | `<100 MB` | ≈0 MB | RSS balloons >100 MB during scan of 200 files | ✅ Catches runaway allocation |
| PH-007 op-delta | `<20 MB` | 5.0 MB | >4× memory growth across 10 moves | ✅ Catches a real leak |
| PH-008 avg-norm | `<80%` | 3.5–4.1% | LinkWatcher pins ~64% of all cores on average | ✅ Catches saturation (loose by L4 design) |
| PH-008 peak | `—` | 116–118% | (not asserted) | ✅ Correctly diagnostic |

**Findings**:
- **False positive rate**: 0 across 2 runs (4 executions). PH-008's per-core-normalized avg + removal of the peak assertion eliminate the system-noise false-positive class TE-TAR-071 fixed.
- **Comparison method**: absolute ceilings (`<X MB`, `<Y%`). Same posture as the rest of the suite; `performance_db.py` trend integration remains a cross-suite long-term opportunity (out of scope), not a blocker.
- **Detection sensitivity**: appropriate for L4 — these are guardrails against unbounded resource growth, not fine-grained throughput watchdogs.

**Evidence**:
- 2 runs, 0 false positives; measurements ~4–20× inside their ceilings.

**Recommendations**:
- None blocking.

## Overall Audit Summary

### Audit Decision
**Status**: ✅ Audit Approved

**Status Definitions**:
- **✅ Audit Approved**: All criteria pass — test is ready for baseline capture
- **🔄 Needs Update**: Test has issues that need fixing before baseline capture
- **🔴 Audit Failed**: Fundamental methodology or measurement issues

**Rationale**:

This fresh per-level re-audit (mandated by the TD254 split) confirms PH-007 and PH-008 are methodologically sound: warmup-before-measurement, process-scoped + per-core-normalized CPU measurement, clean tempdir isolation outside the workspace, deterministic fixtures, declared `psutil` dependency, and code↔tracking tolerance agreement with **zero drift**. Two stability runs passed 4/4 executions with measurements tracking the 2026-04-29 baselines closely — corroborating that the split preserved behavior, so the existing baselines remain valid. The methodology carries forward all the prior rework verified by TE-TAR-071 (TD244/246/247/248/249/250).

The one genuine new finding — the tests were undiscoverable via the standard `-m performance` selection path and lacked the `slow` marker their ~21–29s runtime requires — was within Minor Fix Authority and **fixed during this audit** (markers added, collection re-verified 6/14 → 8/14). With that fix, all four criteria PASS.

Result: **4 of 4 criteria PASS.**

### Critical Issues
None.

### Improvement Opportunities
- **L3 sibling has the identical `-m performance` gap (out of scope — flag for its pending re-audit)**: After fixing L4, `-m performance` still deselects 6/14 — the 6 PH tests in `test_large_projects.py` (PH-001..006), which also carry only `test_type("performance")`, not the bare `performance` marker. `test_large_projects.py` is already flagged 🔄 Needs Update for its own fresh per-level re-audit per TD254; that re-audit should apply the same `@pytest.mark.performance` fix (its `slow` markers are already present per-test). Surfaced here as an observation — not separately tracked, since the L3 re-audit is already queued.
- **`New-TestAuditReport.ps1` placement vs. guide audit-mirror convention (framework tooling, out of scope)**: The script created this report at the flat `test/audits/performance/` path (matching the task's stated Output Location), but the Performance Testing Guide's audit-mirror convention, the sibling reports (TE-TAR-069 in `level2-operation/`, TE-TAR-071 in `level3-scale/`), and the purpose-built `test/audits/performance/level4-resource/.gitkeep` all indicate the report should live in `level4-resource/`. This is recent doc/tooling drift (the 4-level audit mirror landed today with TD254/PD-REF-231). Recommend a Process Improvement to reconcile the script + task Output-Location wording with the guide (route reports to `level{N}-{name}/`).
- **`performance_db.py` trend integration (cross-suite, out of scope)**: same long-term opportunity flagged for the whole suite — absolute thresholds work; trend-based detection would add historical awareness.

### Strengths Identified
- **PH-008 process-CPU rewrite is robust**: raw avg ranged 56→65% across the two runs yet per-core normalization held at 3.5–4.1% — the assertion is decoupled from host load.
- **Warmup-before-measurement** correctly excludes cold-start/import costs from both the memory and CPU windows.
- **Clean, workspace-external fixture isolation** — no interference from the repo's running LinkWatcher daemon.
- **Tolerance/tracking agreement with zero drift** — the tracking file faithfully mirrors the code.
- **Sound conftest fixture extraction** — the `warmup_service` factory is the correct import-safe sharing mechanism for the hyphenated level-dir layout.

## Minor Fixes Applied

| Fix | What Changed | Why | Time Spent |
|-----|-------------|-----|------------|
| Add `@pytest.mark.performance` + `@pytest.mark.slow` | Appended `pytest.mark.performance` and `pytest.mark.slow` to the module `pytestmark` list in [test_resource_bounds.py](/test/automated/performance/level4-resource/test_resource_bounds.py) | The file carried only `test_type("performance")`, so `-m performance` (the framework's `performance` category selector and the guide's baseline command) deselected both tests — they were invisible to the standard baseline-capture path. Both tests also run ~21–29s (>>10s), which the Level-4 guide says must be `slow`-marked (the L3 sibling marks its long tests slow). Task Minor Fix Authority explicitly permits "adding missing `@pytest.mark` markers". Re-verified: `-m performance` collection went 6/14 → 8/14; both tests reachable under `-m "performance and slow"`. | ~5 min |

## Action Items

- [ ] Update [performance-test-tracking.md](/test/state-tracking/permanent/performance-test-tracking.md) Audit Status for the 4 PH-007/PH-008 rows from `🔄 Needs Update` → `✅ Audit Approved` via `Update-TestFileAuditState.ps1 -TestType Performance` (Lifecycle Status stays ✅ Baselined — no `-LifecycleCorrection`, baselines remain valid).
- [ ] When `test_large_projects.py` (L3) gets its pending TD254 re-audit, apply the same `@pytest.mark.performance` fix so `-m performance` collects all 14 perf tests.
- [ ] (Framework maintenance, separate) Reconcile `New-TestAuditReport.ps1` / task Output-Location wording with the guide's `level{N}-{name}/` audit-mirror convention.

## Audit Completion

### Validation Checklist
- [x] All four evaluation criteria have been assessed
- [x] Specific findings documented with evidence (2-run measurements, line-number citations, collection counts)
- [x] Clear audit decision made with rationale (✅ Audit Approved)
- [x] Action items defined
- [ ] Performance test tracking updated with audit status (pending — done via `Update-TestFileAuditState.ps1` in finalization)

### Next Steps
1. Update performance-test-tracking.md Audit Status via `Update-TestFileAuditState.ps1 -TestType Performance -AuditStatus "Audit Approved"`.
2. No baseline action required — the 2026-04-29 baselines remain valid (behavior preserved by the split).

### Follow-up Required
- **Re-audit Date**: Not required (audit approved).
- **Follow-up Items**: L3 sibling `-m performance` marker fix at its pending re-audit; framework-maintenance reconciliation of audit-report placement.

---

**Audit Completed By**: AI Agent
**Completion Date**: 2026-06-04
**Report Version**: 1.0
