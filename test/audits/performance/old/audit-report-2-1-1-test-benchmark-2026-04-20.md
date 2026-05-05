---
id: TE-TAR-066
type: Performance Test Audit
category: Test Audit Report
version: 1.0
created: 2026-04-20
updated: 2026-04-20
feature_id: 2.1.1
audit_date: 2026-04-20
test_file_path: test/automated/performance/test_benchmark.py
auditor: AI Agent
---

# Performance Test Audit Report - Feature 2.1.1 (and cross-cutting)

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | 2.1.1 (primary) — cross-cutting with 0.1.1, 0.1.2, 1.1.1, 2.1.1, 2.2.1 |
| **Test File ID** | test_benchmark.py |
| **Test File Location** | `test/automated/performance/test_benchmark.py` |
| **Performance Level** | Component (L1) — BM-001/002/004/006; Operation (L2) — BM-003/005 |
| **Auditor** | AI Agent |
| **Audit Date** | 2026-04-20 |
| **Audit Status** | COMPLETED |
| **Audit Type** | Retroactive audit (tests baselined 2026-04-09, before audit gate was formalized) |

## Tests Audited

| Test ID | Operation | Level | Related Features | Current Status | Tolerance | Baseline |
|---------|-----------|-------|-----------------|----------------|-----------|----------|
| BM-001 | Parser throughput (100 mixed-format files) | L1 | 2.1.1 | ✅ Baselined | >50 files/sec | 144.0 files/sec |
| BM-002 | DB add (1000 refs) | L1 | 0.1.2 | ✅ Baselined | <5s | 0.015s (68067 ops/sec) |
| BM-002 | DB lookup (100 refs) | L1 | 0.1.2 | ✅ Baselined | <2s | 0.265s (377 ops/sec) |
| BM-002 | DB update (50 refs) | L1 | 0.1.2 | ✅ Baselined | <2s | 0.003s (19805 ops/sec) |
| BM-003 | Initial scan (400 files) | L2 | 0.1.1, 2.1.1, 0.1.2 | ✅ Baselined | <10s | 2.06s (48.6 files/sec) |
| BM-004 | Updater throughput (50 files, 50 refs) | L1 | 2.2.1 | ✅ Baselined | >10 files/sec | 43.0 files/sec |
| BM-005 | Validation mode (100 files) | L2 | 0.1.1, 2.1.1 | ✅ Baselined | <10s | 2.47s |
| BM-006 | Delete+create correlation (20 moves) | L1 | 1.1.1 | ✅ Baselined | <100ms avg, 100% rate | 1.79ms avg, 100% |

## Audit Evaluation

### 1. Measurement Methodology
**Question**: Is the test measuring the right thing with appropriate precision?

**Assessment**: PARTIAL

**Findings**:
- **Warmup cycles**: Only BM-001 has an explicit warmup loop (10 files warmed before timing). BM-002/004/005/006 have no warmup — cold-start effects (import initialization, first-run JIT / filesystem cache) contaminate the first timed iteration. Guide (PF-GDE-060 §Avoiding Flaky Benchmarks) explicitly recommends warmup.
- **Iteration count**: Single measurement per run across all six tests. No statistical aggregation (mean/median/p95). For fast operations (BM-002, BM-006) this makes individual runs noisy.
- **Timing precision**: Uses `time.time()`. Guide permits this (§Measurement Best Practices item 1), but `time.perf_counter()` is monotonic and higher-resolution — strictly preferable for sub-millisecond measurements. For BM-002 Adds (measured 0.011–0.023s) and BM-002 Updates (measured 0.002–0.003s), `time.time()` precision is marginal on Windows (default ~15ms resolution depending on timer).
- **Isolation**: Setup (file creation, service init) is outside the timing window ✅. Print statements are outside the timing window ✅. The `temp_project_dir` fixture creates clean tempdirs per test ✅.
- **Result stability**: Measured across 2 consecutive runs (same machine, quiescent):

| Test | Run 2 | Run 3 | Relative variance | Assessment |
|------|-------|-------|-------------------|-----------|
| BM-001 Parsing | 251.4 f/s | 258.7 f/s | ±1.5% | Stable ✅ |
| BM-002 Adds | 88,962/s | 44,087/s | **±34%** | Unstable ⚠️ |
| BM-002 Lookups | 474/s | 405/s | ±8% | Stable ✅ |
| BM-002 Updates | 27,144/s | 18,192/s | **±20%** | Unstable ⚠️ |
| BM-003 Initial scan | 2.00s | 1.99s | ±0.3% | Very stable ✅ |
| BM-004 Updater | 55.0 f/s | 57.8 f/s | ±2.5% | Stable ✅ |
| BM-005 Validation | 1.389s | 1.415s | ±0.9% | Very stable ✅ |
| BM-006 Correlation | 1.33ms | 1.02ms | **±13%** | Moderate variance ⚠️ |

**Evidence**:
- BM-002 Adds & Updates measurement windows are so small (2–23 ms) that `time.time()` precision and OS scheduling jitter dominate the signal. This is a classic signal-to-noise problem: the metric measures the clock's noise floor, not the actual operation cost.
- BM-006 individual correlation timings captured in test output include several 0.00ms readings (below `time.time()` resolution) — per-correlation measurement is too fine-grained.

**Recommendations**:
1. Add warmup cycles to BM-002, BM-004, BM-005, BM-006 (run the target operation once outside the timing window).
2. Switch all tests from `time.time()` to `time.perf_counter()` for monotonic, higher-resolution timing.
3. For BM-002 Adds/Updates and BM-006: either (a) increase iteration count (10,000+ ops) so the timing window exceeds 100ms, or (b) run N measurement repetitions and report median. Current ~0.003–0.015s windows are below noise floor.

---

### 2. Tolerance Appropriateness
**Question**: Are thresholds realistic, meaningful, and calibrated to observed variance?

**Assessment**: PARTIAL

**Findings**:
- **Tolerance basis**: Several tolerances are orders of magnitude looser than the baseline measurement. Per guide PF-GDE-060 §Tolerance Bands, L1 component benchmarks should use "throughput floor — well below typical measurement" and L2 should use "3–5x typical measurement." Actual ratios:

| Test | Baseline | Tolerance | Ratio | Guide target | Status |
|------|----------|-----------|-------|--------------|--------|
| BM-001 Parsing | 144 f/s | >50 f/s | 2.9× floor | ~3–5× | ✅ Meets guide |
| BM-002 Adds | 0.015s | <5s | **333×** | ~3–5× for L1? | ❌ Far too loose |
| BM-002 Lookups | 0.265s | <2s | 7.5× | ~3–5× | ⚠️ Slightly loose |
| BM-002 Updates | 0.003s | <2s | **667×** | ~3–5× | ❌ Far too loose |
| BM-003 Initial scan | 2.06s | <10s | 4.9× | 3–5× | ✅ Meets guide |
| BM-004 Updater | 43 f/s | >10 f/s | 4.3× floor | ~3–5× | ✅ Meets guide |
| BM-005 Validation | 2.47s | <10s | 4.0× | 3–5× | ✅ Meets guide |
| BM-006 Correlation | 1.79ms | <100ms | **56×** | ~3–5× | ❌ Far too loose |

- **Sensitivity**: Code assertions enforce the tracked tolerances except BM-001, where code asserts `elapsed < 10.0` (absolute time) while tracking declares `>50 files/sec` (throughput). With 400 parseable files at 50 f/s = 8s, the code assertion (10s) is 25% looser than the tracked tolerance. Not a catastrophic mismatch but the two should agree.
- **Level expectations**: BM-002 (L1 Component) and BM-006 (L1 Component) tolerances allow 300–667× slowdown. A regression from O(n) to O(n²) on DB operations (10× slowdown on 1000 refs) would not be caught. This defeats the purpose of regression detection at L1.
- **Units consistency**: Tracking-file tolerances are consistent with measurements (seconds vs seconds, ops/sec vs ops/sec). ✅

**Evidence**:
- Baseline measurements range from 0.003s to 2.47s; tolerances are uniformly ≤10s or at least several seconds — suggesting the tolerances were chosen as "won't ever fail in CI" safety margins rather than calibrated detection thresholds.

**Recommendations**:
1. **Tighten BM-002 Adds tolerance** from `<5s` to `<0.1s` (≈6–7× baseline, detects catastrophic slowdown).
2. **Tighten BM-002 Updates tolerance** from `<2s` to `<0.02s` (≈7× baseline).
3. **Tighten BM-006 Correlation tolerance** from `<100ms avg` to `<10ms avg` (≈5× baseline).
4. **Reconcile BM-001** — change test assertion from `elapsed < 10.0` to `files_per_second > 50` to match tracked tolerance.

---

### 3. Baseline Readiness
**Question**: Is the test ready for reliable baseline capture?

**Assessment**: PASS (with caveats)

**Findings**:
- **Setup/teardown**: `temp_project_dir` fixture uses `tempfile.mkdtemp()` + `shutil.rmtree` on teardown. Clean per-test isolation. ✅
- **Determinism**: Fixtures are deterministic (generated from a seeded `range()` loop, no randomness). ✅
- **External dependencies**: No network, no database, no MCP services. Only filesystem + in-process Python. ✅
- **Environment requirements**: Python 3.9+, `watchdog` package, `pytest`. Standard dev environment requirements, documented implicitly via `pytest` marker setup. ✅
- **Baseline staleness signal**: Three tests measured significantly faster than their 2026-04-09 baselines:
  - BM-001: 251–259 f/s vs baseline 144 f/s (**+75%**)
  - BM-004: 55–58 f/s vs baseline 43 f/s (**+28%**)
  - BM-005: 1.39–1.42s vs baseline 2.47s (**−44%** time)
  This suggests either measurement environment changes (hardware warm/cold, other system load at baseline time) or real code improvements since 2026-04-09. These baselines should be re-captured. (Note: per tracking-file lifecycle, this is a ⚠️ Needs Re-baseline condition — but flagged via audit, not regression detection.)
- **Internal API access**: BM-006 uses `detector._stopped = True` — direct access to a private attribute for cleanup. Guide §Benchmarking Internal Components (pattern 3) sanctions this pattern but calls it fragile. Acceptable, noted.
- **Parser entrypoint issue**: BM-001 manually filters `if file.suffix in parseable_extensions` and calls `parser.parse_file(str(file))` directly, bypassing whatever extension dispatch logic `LinkParser` uses normally. This measures parser raw speed, not the extension-dispatch-plus-parse speed a real scan incurs. Not wrong for L1 "component benchmark," but the name "Parser throughput" is slightly broader than what's actually measured.

**Evidence**:
- All 6 tests pass in a clean run. No flaky results observed across 2 runs.
- Fixture cleanup confirmed via `temp_project_dir` teardown.

**Recommendations**:
1. **Re-baseline BM-001, BM-004, BM-005** — current measurements diverge significantly from recorded baselines. Either the hardware/environment changed, or code is now faster. Either way, drift this large (28–75%) means the current baselines no longer represent reality, and "Baselined" status is misleading.
2. **Document BM-001 scope** — either rename to "Parser raw throughput (per-file API)" or refactor to use the same entrypoint as initial scan does.

---

### 4. Regression Detection Config
**Question**: Will this test actually catch meaningful regressions?

**Assessment**: FAIL (partial — 3 of 8 tests cannot catch meaningful regressions)

**Findings**:
- **Detection sensitivity** (minimum detectable regression, based on current tolerances):

| Test | Detectable slowdown | Meaningful? |
|------|---------------------|-------------|
| BM-001 | ~65% (144→50 f/s, or code assertion: ~540% via elapsed) | Moderate — code assertion too loose |
| BM-002 Adds | ~33,000% (0.015s→5s) | No — misses everything |
| BM-002 Lookups | 655% (0.265s→2s) | Weak |
| BM-002 Updates | ~66,600% (0.003s→2s) | No — misses everything |
| BM-003 | 386% (2.06s→10s) | Moderate |
| BM-004 | 330% (43→10 f/s) | Moderate |
| BM-005 | 305% (2.47s→10s) | Moderate |
| BM-006 | 5,500% (1.79ms→100ms) | No — misses everything |

- **False positive rate**: Measured variance (±13% to ±34% for unstable tests) is well within even tight tolerances. Noise-triggered failures are unlikely. But tolerance looseness, not noise immunity, dominates the signal-to-noise ratio.
- **Comparison method**: All tests use absolute thresholds (`<10s` or `>10 f/s`). No percentage-delta-from-baseline check. `performance_db.py` records the values but the test itself doesn't compare against the last recorded baseline — a 10× regression that still passes the absolute threshold would go undetected at test-time.
- **Trend awareness**: `performance_db.py` exists and recorded initial baselines on commit 091ad8c, but no automated `record` step in the test fixtures. Baseline capture is manual (per PF-TSK-085). This means trend tracking only happens when someone runs the capture script, not on every test run.

**Evidence**:
- A developer introducing an accidental O(n²) DB operation (10× slowdown on BM-002 Adds, pushing 0.015s → 0.15s) would not trigger any test failure — the test still passes `<5s`.
- The tracked tolerance column is not enforced by the test code for BM-001 (as noted in Criterion 2).

**Recommendations**:
1. **Augment regression detection** — consider adding a test-time check against last baseline, not just absolute threshold. E.g., fail if `elapsed > 3 × last_baseline.value`. Requires integration with `performance_db.py` or a lightweight threshold file.
2. **Tighten tolerances** per Criterion 2 recommendations — this alone moves BM-002 and BM-006 from "no meaningful detection" to "moderate detection."
3. **Longer-term**: for L1 Component benchmarks, consider statistical tests (Mann-Whitney U over N runs) instead of single-sample absolute thresholds. Out of scope for this audit.

## Overall Audit Summary

### Audit Decision
**Status**: 🔄 NEEDS_UPDATE

**Status Definitions**:
- **🔍 Audit Approved**: All criteria pass — test is ready for baseline capture
- **🔄 Needs Update**: Test has issues that need fixing before baseline capture
- **🔴 Audit Failed**: Fundamental methodology or measurement issues

**Rationale**:

The tests are **functionally correct and run cleanly** — they do measure what they claim to measure, fixtures are sound, results are reproducible. The audit cannot approve them as-is because three significant issues would allow regressions to slip through undetected:

1. **Criterion 2 (Tolerance) — FAIL for 3 tests**: BM-002 Adds (333× loose), BM-002 Updates (667× loose), and BM-006 Correlation (56× loose) tolerances make these tests effectively "smoke tests that never fail" rather than regression detectors.
2. **Criterion 4 (Regression Detection) — FAIL**: No test-time comparison against baseline; absolute-threshold-only detection at current tolerance levels cannot catch 10× slowdowns on the fastest operations.
3. **Criterion 1 (Methodology) — PARTIAL**: Missing warmups on 5/6 tests; `time.time()` precision marginal for sub-20ms measurements (directly causing ±20–34% variance on BM-002 Adds/Updates).

**Criterion 3 (Baseline Readiness) passes** but flags baseline staleness: BM-001, BM-004, BM-005 are 28–75% faster than their 2026-04-09 baselines. Baselines should be re-captured.

**Retroactive audit context**: These tests were baselined 2026-04-09 before the audit gate was formalized (2026-04-13). They skipped the gate. This audit retroactively closes that compliance gap. The findings are **design-level observations**, not "tests were broken" — the current tests were acceptable under the pre-gate process but would be rejected under the current audit gate.

### Critical Issues
1. **BM-002 Adds/Updates and BM-006 tolerances are 56×–667× looser than guide-recommended 3–5× baseline** — meaningful regressions would not be caught. Needs tolerance tightening before these tests can be considered effective regression detectors.
2. **No warmup cycles on 5/6 tests** — cold-start effects contaminate first-iteration measurements, contributing to the ±20–34% variance on sub-20ms measurements.
3. **BM-001 code assertion disagrees with tracked tolerance** — code asserts `elapsed<10s`, tracking declares `>50 files/sec`. These aren't equivalent.

### Improvement Opportunities
- Switch from `time.time()` to `time.perf_counter()` globally (monotonic clock, higher resolution).
- Re-baseline BM-001, BM-004, BM-005 — measured 28–75% different from 2026-04-09 baselines.
- Augment regression detection with test-time comparison against `performance_db.py` last-known baseline (out of scope for this audit).
- Reconsider `@pytest.mark.slow` on BM-003 — test completes in ~2s, doesn't meet guide's ">10 seconds" threshold for the slow marker.

### Strengths Identified
- **Clean fixture isolation**: `temp_project_dir` gives each test a fresh tempdir, cleaned up on teardown. No cross-test pollution.
- **Correct marker discipline**: All tests carry `@pytest.mark.performance`, `@pytest.mark.feature("cross-cutting")`, `@pytest.mark.priority("Extended")`, `@pytest.mark.test_type("performance")` as required by the guide.
- **Measurement-outside-print discipline**: Setup is correctly outside the timing window; print statements are after `elapsed = …`.
- **Reproducibility**: 2 runs produced stable results for 5/8 test measurements (±3% or better). The 3 unstable ones (BM-002 Adds/Updates, BM-006) are unstable due to timing precision, not nondeterminism.
- **Guide conformance on BM-003/005**: These L2 operation benchmarks correctly use 4–5× tolerance as the guide prescribes.

## Minor Fixes Applied

<!-- No minor fixes were applied during this audit. -->

No code changes were applied during the audit. All identified issues were categorized as:
- **Design-level recommendations** → documented above, to be addressed via separate tech debt work.
- **Baseline re-capture needs** → flagged for PF-TSK-085 Performance Baseline Capture.
- **Assertion logic changes** → deliberately deferred; modifying test assertions mid-audit changes test semantics in ways that warrant separate review, not a 15-minute drop-in fix.

## Action Items

- [ ] Register tech debt: tighten BM-002 Adds/Updates and BM-006 tolerances to guide-recommended 3–5× baseline (target via Code Refactoring PF-TSK-022, test-only shortcut).
- [ ] Register tech debt: add warmup cycles to BM-002, BM-004, BM-005, BM-006.
- [ ] Register tech debt: switch `time.time()` → `time.perf_counter()` across all 6 BM tests.
- [ ] Register tech debt: reconcile BM-001 code assertion with tracked tolerance (`elapsed < 10.0` → `files_per_second > 50`).
- [ ] Register tech debt: remove `@pytest.mark.slow` from BM-003 (completes in ~2s, below the 10s threshold for slow).
- [ ] Flag BM-001, BM-004, BM-005 as ⚠️ Needs Re-baseline in performance-test-tracking.md (measured results 28–75% different from recorded baselines).
- [ ] Process improvement already logged as **PF-IMP-576** (retroactive audit + stale-audit trigger gaps in PF-TSK-030).

## Audit Completion

### Validation Checklist
- [x] All four evaluation criteria have been assessed
- [x] Specific findings documented with evidence
- [x] Clear audit decision made with rationale (🔄 NEEDS_UPDATE)
- [x] Action items defined
- [x] Performance test tracking updated with audit status (completed 2026-04-22, step 17 of PF-TSK-030)

### Next Steps
1. Register tech debt items listed above in [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md) via `Update-TechDebt.ps1 -Add -Dims "TST"`.
2. Update [performance-test-tracking.md](/test/state-tracking/permanent/performance-test-tracking.md) Audit Status column for all 8 BM test rows via `Update-TestFileAuditState.ps1 -TestType Performance`.
3. After tech-debt items are resolved via [Code Refactoring (PF-TSK-022)](/process-framework/tasks/06-maintenance/code-refactoring-task.md), re-audit via PF-TSK-030 and (if approved) proceed to [Performance Baseline Capture (PF-TSK-085)](/process-framework/tasks/03-testing/performance-baseline-capture-task.md).

### Follow-up Required
- **Re-audit Date**: After tech-debt items addressed (no fixed date — triggered by refactoring completion).
- **Follow-up Items**:
  - 5 tech-debt items listed in Action Items
  - Baseline re-capture for BM-001/004/005
  - Second-session audit of `test_large_projects.py` (PH-001..006, PH-MEM, PH-CPU)

---

**Audit Completed By**: AI Agent
**Completion Date**: 2026-04-20
**Report Version**: 1.0
