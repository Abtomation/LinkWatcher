---
id: TE-TAR-074
type: Performance Test Audit
category: Test Audit Report
version: 1.0
created: 2026-06-04
updated: 2026-06-04
feature_id: 0.1.1
auditor: AI Agent
test_file_path: test/automated/performance/level2-operation/test_operation_benchmarks.py
audit_date: 2026-06-04
---

# Performance Test Audit Report - Operation Benchmarks (Level 2)

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | 0.1.1 (primary) — cross-cutting with 0.1.2, 1.1.1, 2.1.1 |
| **Test File ID** | test_operation_benchmarks.py |
| **Test File Location** | `test/automated/performance/level2-operation/test_operation_benchmarks.py` |
| **Performance Level** | Operation (L2) — BM-003, BM-005, BM-006 |
| **Auditor** | AI Agent |
| **Audit Date** | 2026-06-04 |
| **Audit Status** | ✅ Audit Approved |
| **Audit Type** | Fresh per-level re-audit following the TD254 / PD-REF-231 split (2026-06-04). The pre-split file `test_benchmark.py` was audited by [TE-TAR-069](level2-operation/audit-report-2-1-1-test-benchmark.md) (2026-04-29), retained as historical record. This audit re-evaluates all four criteria independently for the split-out operation-level file. |

## Tests Audited

| Test ID | Operation | Level | Related Features | Current Status | Calibration Baseline | Tolerance Ratio | Tolerance (absolute) | Last Result (this audit) |
|---------|-----------|-------|-----------------|----------------|----------------------|-----------------|----------------------|--------------------------|
| BM-003 | Initial scan (100 file sets, 400 files) | L2 | 0.1.1, 2.1.1, 0.1.2 | ✅ Baselined | 1.55–2.33s (mean 1.85s, 3 runs post-fix) | ~5× typical (intentionally generous — absorbs cold-scan OS-cache variance) | `<10s` (unchanged) | 1.55 / 1.67 / 2.33s — all pass |
| BM-005 | Validation mode (100 file sets, 300 validated) | L2 | 0.1.1, 2.1.1 | ✅ Baselined | 1.02–1.085s (mean 1.06s, 3 runs post-fix) | ~4–5× typical | `<5s` **(tightened from `<10s`)** | 1.020 / 1.060 / 1.085s — all pass |
| BM-006 | Delete+create correlation (20 moves) | L2 | 1.1.1 | ✅ Baselined | 1.05–1.23ms avg (mean 1.15ms, 3 runs post-fix) | ~4× typical (avg); `match_rate==100` strict | `<5ms` avg **(tightened from `<10ms`)** + 100% match | 1.05 / 1.16 / 1.23ms avg, 100% match — all pass |

> **Why three tolerance columns**: Tests in code use absolute numbers (`assert elapsed < 5.0`), but absolutes go stale when typical measurements drift. Recording the **Calibration Baseline** (what was typical at audit time) and the **Tolerance Ratio** (the auditor's actual judgment, e.g., "4× typical") preserves the math intent — so future refactorings hitting an audit-derived TD can recompute `current_baseline × ratio` instead of inheriting a stale absolute.

## Audit Evaluation

### 1. Measurement Methodology
**Question**: Is the test measuring the right thing with appropriate precision?

**Assessment**: PASS

**Findings**:
- **Warmup cycles**:
  - BM-005 warms up with a separate `LinkValidator` on an external 5-set tempdir before the timed pass ([lines 86–93](/test/automated/performance/level2-operation/test_operation_benchmarks.py)). ✅
  - BM-006 warms up with 2 throwaway delete+create correlation cycles before the timed loop ([lines 159–165](/test/automated/performance/level2-operation/test_operation_benchmarks.py)). ✅
  - **BM-003 had no warmup** (the only L2 test lacking one). A warmup using the existing `warmup_service` conftest fixture was **added during this audit** (with human approval at the audit checkpoint) so BM-003's Python-level hot paths (service instantiation, parser regex compilation, `_initial_scan()` specialization) are primed outside the timed window — matching the other two tests and the guide's warmup best practice.
  - **Honest caveat on warmup effectiveness**: adding the warmup gave BM-003 *methodology consistency* but did **not** eliminate its run-to-run variance. The cold first run is still elevated (2.33s vs ~1.55s warm; ~±20% across runs). The residual variance is dominated by **cross-process OS filesystem-cache effects on the 400 freshly-created production files** — an in-test warmup (which primes a *different* 5-set tempdir) cannot address this, and it is inherent to a single-shot cold-scan measurement. This is not a defect: BM-003 still clears the `<10s` tolerance with ≥4.3× headroom even on the cold run, and the deliberately generous tolerance (Criterion 2) is sized precisely to absorb this variance.
- **Iteration count**: BM-003 and BM-005 take a single timed measurement of a heavyweight operation (full scan / full validation) — appropriate at L2. BM-006 captures 20 individual correlation timings and reports avg + max — good statistical body for a sub-millisecond operation.
- **Timing precision**: All three tests use `time.perf_counter()` (monotonic, sub-µs resolution on Windows). ✅
- **Isolation**: Fixture file creation, service/validator setup, warmup, and all `print` statements are outside the timing windows. `temp_project_dir` provides a clean per-test tempdir. BM-006 times only the `match_created_file()` correlation call, with `buffer_delete` + `src.rename()` outside the window. ✅
- **Result stability** (this audit, 3 runs each, pre-fix and post-fix):

| Test | Pre-fix (3 runs) | Post-fix (3 runs) | Post-fix variance | Assessment |
|------|------------------|-------------------|-------------------|------------|
| BM-003 Initial scan | 2.02 / 1.70 / 1.46s | 2.33 / 1.67 / 1.55s | ±~20% | OS-cache-driven cold-start variance; absorbed by generous tolerance |
| BM-005 Validation | 1.159 / 1.300 / 1.160s | 1.020 / 1.085 / 1.060s | ±3% | Very stable |
| BM-006 Correlation (avg) | 1.27 / 1.21 / 1.16ms | 1.05 / 1.16 / 1.23ms | ±8% | Stable |

**Evidence**:
- BM-005 and BM-006 are stable across 6 total runs (±3% / ±8%) with warmup in place.
- BM-003's ±20% variance is attributable to a single elevated cold run per process invocation; the warm runs cluster at 1.55–1.70s. The decreasing trend across separate processes (2.33 → 1.67 → 1.55s) reflects OS-level filesystem caching warming across runs — not a measurement methodology defect.
- All three tests pass cleanly in every run.

**Recommendations**:
- None blocking. BM-003's residual variance is inherent to a cold initial-scan benchmark and is correctly absorbed by the `<10s` tolerance.

---

### 2. Tolerance Appropriateness
**Question**: Are thresholds realistic, meaningful, and calibrated to observed variance?

**Assessment**: PASS (after minor fixes applied during this audit)

**Findings**:

Per [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) §Tolerance Bands, L2 Operation tolerances target **3–5× typical measurement**.

**Tolerance ratios**:

| Test | Typical (this audit) | Pre-audit tolerance | Pre-audit ratio | Post-fix tolerance | Post-fix ratio | Status |
|------|----------------------|---------------------|-----------------|--------------------|----------------|--------|
| BM-003 | ~1.85s (mean) | `<10s` | ~5–6× | `<10s` (kept) | ~5× | ✅ Kept generous deliberately — absorbs cold-scan OS-cache variance (Criterion 1); tightening would risk a false positive on the cold first run |
| BM-005 | ~1.06s (mean) | `<10s` | ~9–10× | **`<5s`** | ~4–5× | ✅ Now within L2 3–5× target |
| BM-006 | ~1.15ms avg | `<10ms` | ~8–9× | **`<5ms`** | ~4× | ✅ Now within L2 3–5× target |

- BM-005 and BM-006 were ~2× looser than the guide's 3–5× target. This was **the prior audit's explicitly deferred action item** (TE-TAR-069: "After PF-TSK-085 captures fresh baselines, reconsider BM-005 tolerance"). PF-TSK-085 captured those baselines on 2026-04-29, so the recalibration is now actionable and was applied this audit (single-line constant changes; see Minor Fixes).
- BM-003 was intentionally **not** tightened. At ~5× it is at the loose edge of the guide range, but its ±20% cold-scan variance needs the headroom — tightening to 3× (~5.5s) would risk a false positive when the cold first run lands near 2.3s under load.
- **Code/tracking consistency maintained**: both the code assertions and the `performance-test-tracking.md` Tolerance column were updated in lockstep (`<5s` / `<5ms`), so no drift was introduced.

**Evidence**:
- BM-005 at `<5s` vs typical ~1.06s gives ~4.7× headroom against ±3% variance — comfortable margin, catches a 4–5× regression.
- BM-006 at `<5ms` vs typical ~1.15ms gives ~4.3× headroom against ±8% variance — catches a ~4× regression; `match_rate==100` is a strict correctness gate independent of timing.

**Recommendations**:
- None outstanding. The prior audit's BM-005 recalibration item is now closed; BM-006 brought to the same band.

---

### 3. Baseline Readiness
**Question**: Is the test ready for reliable baseline capture?

**Assessment**: PASS

**Findings**:
- **Setup/teardown**: `temp_project_dir` uses `tempfile.mkdtemp()` + `shutil.rmtree` on teardown — clean per-test isolation in a system tempdir (outside the repo, so unaffected by the repo's own LinkWatcher daemon). ✅
- **Determinism**: Fixtures generated from seeded `range()` loops; no randomness. ✅
- **External dependencies**: None — filesystem tempdir + in-process Python only (no network, DB services, or MCP). ✅
- **Internal API access**: BM-006 sets `detector._stopped = True` to shut down the daemon worker ([lines 187–188](/test/automated/performance/level2-operation/test_operation_benchmarks.py)) — sanctioned by the guide §Benchmarking Internal Components Pattern 3. Noted, acceptable.
- **Tracking-file consistency**: After this audit's lockstep edits, the `performance-test-tracking.md` Tolerance column matches the code assertions for all three tests (BM-003 `<10s` = `< 10.0`; BM-005 `<5s` = `< 5.0`; BM-006 `<5ms` = `< 5`). ✅
- **Run cleanliness**: All three tests pass cleanly across 6 consecutive runs this audit (3 pre-fix + 3 post-fix). No flakes, no resource leaks.
- **Baseline freshness note** (not blocking): The tracking baselines (BM-003 1.51s, BM-005 1.020s, BM-006 1.06ms; captured 2026-04-29) sit slightly below this audit's measurements (1.85s / 1.06s / 1.15ms). The split was behavior-preserving (logic/assertions unchanged), so the deltas are machine-load + the BM-003 cold effect. **The BM-003 warmup added this audit is a methodology change**, so BM-003's baseline should be refreshed at the next Baseline Capture (PF-TSK-085) — see Action Items. BM-005/BM-006 baselines remain representative.

**Evidence**:
- Clean, deterministic fixtures and 6/6 passing runs confirm baseline readiness.
- Print outputs include all metrics (scan seconds, validation seconds, correlation avg/max ms, match rate) needed for `performance_db.py` recording.

**Recommendations**:
- Refresh the BM-003 baseline during PF-TSK-085 (warmup added). Non-blocking for the audit gate.

---

### 4. Regression Detection Config
**Question**: Will this test actually catch meaningful regressions?

**Assessment**: PASS (after minor fixes applied during this audit)

**Findings**:

**Detection sensitivity** (slowdown factor needed to trip the tolerance):

| Test | Post-fix tolerance | Typical | Slowdown to fail | Verdict |
|------|--------------------|---------|------------------|---------|
| BM-003 | `<10s` | ~1.85s (cold up to 2.33s) | ~4.3–5.4× | OK — generous by design; absorbs cold variance |
| BM-005 | `<5s` | ~1.06s | ~4.7× | OK (was ~9.8× — now catches a 4–5× regression) |
| BM-006 | `<5ms` avg | ~1.15ms | ~4.3× | OK (was ~9.4×); `match_rate==100` also gates correctness |

- **False positive rate**: Measured variance (±3% BM-005, ±8% BM-006, ±20% BM-003) is well within each tolerance. BM-003's ±20% against ~4.3× headroom leaves no realistic false-positive risk.
- **Comparison method**: All three use absolute thresholds (`<X seconds` / `<X ms`). No test-time comparison against `performance_db.py` last baseline — same finding as the prior audit; finer trend-based detection is infrastructure work belonging to PF-TSK-085 / `performance_db.py`, out of scope for a test-file audit.
- **Trend awareness**: `performance_db.py` exists; baselines are recorded by PF-TSK-085 (manual workflow task), not on every test run.

**Evidence**:
- A 4–5× regression on initial scan, validation, or correlation will now trip the corresponding tolerance. BM-005/BM-006 detection improved from ~9–10× (would miss meaningful 4–7× regressions) to ~4× post-fix.

**Recommendations**:
- Long-term (out of audit scope): consider test-time comparison against `performance_db.py` last baseline for finer regression detection.

## Overall Audit Summary

### Audit Decision
**Status**: ✅ Audit Approved

**Status Definitions**:
- **✅ Audit Approved**: All criteria pass — test is ready for baseline capture
- **🔄 Needs Update**: Test has issues that need fixing before baseline capture
- **🔴 Audit Failed**: Fundamental methodology or measurement issues

**Rationale**:

The TD254/PD-REF-231 split of `test_benchmark.py` into per-level files was behavior-preserving, and the three operation-level benchmarks (BM-003, BM-005, BM-006) were re-evaluated independently against all four criteria. Two substantive findings surfaced and were resolved within [Minor Fix Authority](../../../process-framework/tasks/03-testing/test-audit-task.md#minor-fix-authority) (human-approved at the audit checkpoint):

1. **BM-003 missing warmup** (Criterion 1) — the only L2 test without one. A warmup via the existing `warmup_service` fixture was added for methodology consistency. Transparently, this did not eliminate BM-003's cold-scan variance (which is OS-filesystem-cache-driven and inherent to a single-shot initial scan), but it primes the Python-level hot paths in line with BM-005/BM-006, and the generous `<10s` tolerance absorbs the residual variance.
2. **BM-005 and BM-006 loose tolerances** (Criteria 2 & 4) — ~9–10× vs the L2 guide's 3–5× target. This was the prior audit's explicitly-deferred recalibration item, now actionable since PF-TSK-085 captured baselines on 2026-04-29. Tightened to `<5s` / `<5ms` (~4–5×), with code and tracking updated in lockstep.

After these fixes all four criteria PASS, all three tests pass cleanly across 6 runs, and BM-005/BM-006 detection sensitivity improved from ~9–10× to ~4×.

### Critical Issues
None.

### Improvement Opportunities
- Refresh the BM-003 baseline during the next Baseline Capture (PF-TSK-085) to reflect the added warmup.
- Long-term (out of audit scope): add test-time comparison against `performance_db.py` last baseline for finer-grained regression detection across all performance levels.

### Strengths Identified
- **Clean fixture isolation**: `temp_project_dir` per-test tempdirs in a system temp area; deterministic seeded fixtures; no external dependencies.
- **Sound timing**: `time.perf_counter()` throughout; setup/warmup/prints outside the timed windows.
- **Marker discipline**: module-level `@pytest.mark.feature("cross-cutting")`, `priority("Extended")`, `cross_cutting([...])`, `test_type("performance")`, plus per-test `@pytest.mark.performance`.
- **Documentation hygiene**: tolerance comments point to `performance-test-tracking.md` as the single source of truth (no drift-prone ratio claims encoded in code).

## Minor Fixes Applied

| Fix | What Changed | Why | Time Spent |
|-----|-------------|-----|------------|
| Add BM-003 warmup | [test_operation_benchmarks.py](/test/automated/performance/level2-operation/test_operation_benchmarks.py): added `warmup_service` fixture param + `warmup_service(num_files=5)` call before the timed scan | BM-003 was the only L2 test without warmup; primes Python-level hot paths outside the timed window, matching BM-005/BM-006 and the guide's warmup best practice (human-approved at checkpoint) | ~3 min |
| Tighten BM-005 tolerance | Code `elapsed < 10.0` → `elapsed < 5.0` + assertion message; tracking Tolerance `<10s` → `<5s` | Prior `<10s` allowed a ~9–10× slowdown to pass — looser than L2 guide's 3–5× target; resolves the prior audit's deferred recalibration item now that the baseline exists | ~2 min |
| Tighten BM-006 tolerance | Code `avg_ms < 10` → `avg_ms < 5` + assertion message + comment; tracking Tolerance `<10ms` → `<5ms` | Prior `<10ms` allowed a ~9× slowdown to pass; brought to ~4× of typical to match the L2 band | ~2 min |
| Fix file-count descriptions | Tracking: BM-003 `(400 files)` → `(100 file sets, 400 files)`, BM-005 `(100 files)` → `(100 file sets, 300 validated)`; matching docstring corrections in the test file | The two rows used inconsistent counting conventions for the same 100-set fixture; "100 files" was inaccurate (the fixture creates 400 files, validation scans 300) | ~2 min |

**Verification**: Re-ran `pytest test/automated/performance/level2-operation/test_operation_benchmarks.py` 3× after edits — all 3 tests pass on every run with the warmup added and the tightened tolerances.

## Action Items

- [ ] Set Audit Status `🔄 Needs Update` → `✅ Audit Approved` for BM-003/BM-005/BM-006 via `Update-TestFileAuditState.ps1 -TestType Performance` (finalization step).
- [ ] Proceed to [Performance Baseline Capture (PF-TSK-085)](/process-framework/tasks/03-testing/performance-baseline-capture-task.md): refresh the **BM-003** baseline (warmup added) and confirm BM-005/BM-006 against the tightened `<5s` / `<5ms` tolerances.

## Audit Completion

### Validation Checklist
- [x] All four evaluation criteria have been assessed
- [x] Specific findings documented with evidence
- [x] Clear audit decision made with rationale (✅ Audit Approved)
- [x] Action items defined
- [ ] Performance test tracking updated with audit status (pending — done via `Update-TestFileAuditState.ps1` in finalization)

### Next Steps
1. Update `performance-test-tracking.md` Audit Status for BM-003/BM-005/BM-006 from `🔄 Needs Update` → `✅ Audit Approved` via `Update-TestFileAuditState.ps1 -TestType Performance`.
2. Proceed to Performance Baseline Capture (PF-TSK-085) — tests are ready; refresh BM-003 baseline.

### Follow-up Required
- **Re-audit Date**: Not required (audit approved). Re-audit triggered by significant code refactoring per the task definition.
- **Follow-up Items**: BM-003 baseline refresh during PF-TSK-085 (warmup methodology change).

---

**Audit Completed By**: AI Agent
**Completion Date**: 2026-06-04
**Report Version**: 1.0
