---
id: PF-TEM-073
type: Process Framework
category: Template
version: 1.2
created: 2026-04-13
updated: 2026-04-30
template_for: Performance Test Audit Report
creates_document_prefix: TE-TAR
creates_document_category: Test Audit Report
creates_document_type: Performance Test Audit
description: Template for performance test audit reports with 4 criteria
usage_context: Used by New-TestAuditReport.ps1 -TestType Performance during PF-TSK-030
---

# Performance Test Audit Report - Feature [Feature ID]

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | [Feature ID] |
| **Test File ID** | [Test File ID] |
| **Test File Location** | `[Test File Path]` |
| **Performance Level** | [Component (L1) / Operation (L2) / Scale (L3) / Resource (L4)] |
| **Auditor** | [Auditor Name] |
| **Audit Date** | [Audit Date] |
| **Audit Status** | [Audit Status] |

## Tests Audited

| Test ID | Operation | Level | Related Features | Current Status | Calibration Baseline | Tolerance Ratio | Tolerance (absolute) | Last Result (this audit) |
|---------|-----------|-------|-----------------|----------------|----------------------|-----------------|----------------------|--------------------------|
| [BM/PH-XXX] | [Operation description] | [L1-L4] | [Feature IDs] | [Status] | [Typical measurement at audit time, e.g., `0.002s avg over 3 runs`] | [Multiplier expressing audit intent, e.g., `10× typical` or `floor: 50 f/s`] | [Derived from baseline × ratio, e.g., `<0.02s`] | [Result; include run count, or — if not measured] |

> **Why three tolerance columns**: Tests in code use absolute numbers (`assert update_time < 0.02`), but absolutes go stale when typical measurements drift. Recording the **Calibration Baseline** (what was typical at audit time) and the **Tolerance Ratio** (the auditor's actual judgment, e.g., "10× typical") preserves the math intent — so future refactorings hitting an audit-derived TD can recompute `current_baseline × ratio` instead of inheriting a stale absolute.

## Audit Evaluation

### 1. Measurement Methodology
**Question**: Is the test measuring the right thing with appropriate precision?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- **Warmup cycles**: [Are warmup iterations sufficient to reach steady state?]
- **Iteration count**: [Are enough iterations run for statistical significance?]
- **Timing precision**: [Is the timing method appropriate? `time.perf_counter()` vs `time.time()` vs framework timers]
- **Isolation**: [Is the measurement isolated from external factors? Other processes, I/O, network, GC]
- **Result stability**: [Variance across multiple runs — CV% and whether results are reproducible]

**Evidence**:
- [Run results showing stability or instability]

**Recommendations**:
- [Specific improvements to measurement methodology]

---

### 2. Tolerance Appropriateness
**Question**: Are thresholds realistic, meaningful, and calibrated to observed variance?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- **Tolerance basis**: [Is the tolerance derived from observed variance or arbitrary?]
- **Sensitivity**: [Too tight = false alarm noise; Too loose = misses real regressions. Assess the balance]
- **Level expectations**: [Does the tolerance match what is expected for this performance level?]
- **Units consistency**: [Are tolerance units consistent with the measurement?]
- **Calibration intent**: [Record the ratio (e.g., `10× typical`, `5× baseline`, `floor: 50 f/s`) and the baseline measurement used to derive the absolute tolerance — preserves recalibration data for downstream refactorings when typical measurements drift. Goes into the Tests Audited table's `Calibration Baseline` and `Tolerance Ratio` columns.]

**Evidence**:
- [Observed variance data supporting or contradicting tolerance choices]

**Recommendations**:
- [Specific tolerance adjustments with rationale]

---

### 3. Baseline Readiness
**Question**: Is the test ready for reliable baseline capture?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- **Setup/teardown**: [Clean environment creation and cleanup? No leftover state between runs]
- **Determinism**: [Are results deterministic given the same environment?]
- **External dependencies**: [Does the test depend on external resources that may vary?]
- **Environment requirements**: [Are environment requirements documented?]
- **Tracking-file consistency**: [Does `performance-test-tracking.md` Tolerance column match code assertions? Drift indicates upstream refactoring left documentation behind]

**Evidence**:
- [Results from clean environment vs dirty environment comparison]

**Recommendations**:
- [Specific improvements to baseline readiness]

---

### 4. Regression Detection Config
**Question**: Will this test actually catch meaningful regressions?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- **Detection sensitivity**: [Minimum detectable regression size]
- **False positive rate**: [How often would normal variance trigger a false alarm?]
- **Comparison method**: [Absolute threshold, percentage delta, or statistical test]
- **Trend awareness**: [Is performance_db.py trend tracking configured?]

**Evidence**:
- [Analysis of detection capabilities]

**Recommendations**:
- [Specific improvements to regression detection]

## Overall Audit Summary

### Audit Decision
**Status**: [AUDIT_APPROVED/NEEDS_UPDATE/AUDIT_FAILED]

**Status Definitions**:
- **✅ Audit Approved**: All criteria pass — test is ready for baseline capture
- **🔄 Needs Update**: Test has issues that need fixing before baseline capture
- **🔴 Audit Failed**: Fundamental methodology or measurement issues

**Rationale**:
[Detailed explanation of the audit decision based on the four evaluation criteria]

### Critical Issues
- [Critical issue 1 requiring immediate attention]

### Improvement Opportunities
- [Improvement opportunity 1]

### Strengths Identified
- [Strength 1 worth highlighting]

## Minor Fixes Applied

<!-- Delete this section if no minor fixes were applied during audit. -->

| Fix | What Changed | Why | Time Spent |
|-----|-------------|-----|------------|
| [Fix 1] | [Description] | [Rationale] | [X min] |

## Action Items

- [ ] [Action item 1 with specific details]
- [ ] [Action item 2 with specific details]

## Audit Completion

### Validation Checklist
- [ ] All four evaluation criteria have been assessed
- [ ] Specific findings documented with evidence
- [ ] Clear audit decision made with rationale
- [ ] Action items defined
- [ ] Performance test tracking updated with audit status

### Next Steps
1. [Next step — typically "Proceed to baseline capture (PF-TSK-085)" or "Return to test creation (PF-TSK-084) for fixes"]

### Follow-up Required
- **Re-audit Date**: [DATE if NEEDS_UPDATE]
- **Follow-up Items**: [Specific items to track]

---

**Audit Completed By**: [Auditor Name]
**Completion Date**: [Audit Date]
**Report Version**: 1.0
