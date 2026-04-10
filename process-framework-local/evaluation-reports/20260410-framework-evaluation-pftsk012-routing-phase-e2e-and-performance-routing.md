---
id: PF-EVR-012
type: Process Framework
category: Evaluation Report
version: 1.0
created: 2026-04-10
updated: 2026-04-10
evaluation_scope: PF-TSK-012 Routing Phase: E2E and performance routing viability before code exists
---

# Framework Evaluation Report

## Document Metadata

| Field | Value |
|-------|-------|
| Report ID | PF-EVR-012 |
| Date | 2026-04-10 |
| Evaluation Scope | PF-TSK-012 Routing Phase: E2E and performance routing viability before code exists |
| Evaluator | AI Agent & Human Partner |
| Task Reference | PF-TSK-079 (Framework Evaluation) |
| Prior Evaluation | [PF-EVR-011](/process-framework-local/evaluation-reports/20260409-framework-evaluation-targeted-evaluation-of-pftsk012-test-specification.md) — structural evaluation that led to the current Routing Phase |

## Evaluation Scope

**Scope Description**: Targeted evaluation challenging whether PF-TSK-012's Routing Phase can reliably identify E2E and performance tests before code exists, from a single-feature perspective.

**Scope Type**: Targeted

**Evaluation Question**: At the pre-code, single-feature stage where PF-TSK-012 runs, can E2E and performance test routing decisions be made with sufficient confidence to justify binding downstream task queues?

**Artifacts in Scope**:

| # | Artifact | Type | ID |
|---|----------|------|----|
| 1 | Test Specification Creation Task (v2.1) | Task | PF-TSK-012 |
| 2 | Test Specification Template (v1.2) | Template | PF-TEM-031 |
| 3 | Test Specification Creation Guide (v1.1) | Guide | PF-GDE-028 |
| 4 | E2E Acceptance Test Case Creation Task | Task | PF-TSK-069 |
| 5 | Performance Test Creation Task | Task | PF-TSK-084 |
| 6 | Performance Testing Guide | Guide | PF-GDE-060 |
| 7 | 7 existing feature test specs | Specs | TE-TSP-001 through TE-TSP-044 |
| 8 | Cross-cutting E2E spec | Spec | TE-TSP-044 |
| 9 | E2E test tracking | State | TE-STA-002 |
| 10 | Performance test tracking | State | — |
| 11 | Previous evaluation report | Report | PF-EVR-011 |

## Dimensions Evaluated

| # | Dimension | Score | Key Finding |
|---|-----------|-------|-------------|
| 5 | Effectiveness | 2 | E2E and performance routing decisions cannot be made reliably before code exists; zero existing E2E/performance tests originated from per-feature routing |
| 2 | Consistency | 2 | Single-feature scope contradicts cross-cutting test nature; two competing E2E identification mechanisms |
| 3 | Redundancy | 2 | Per-feature routing duplicates decisions better made at milestone triggers (E2E) and implementation time (performance) |

**Overall Score**: 2.0 / 4.0

**Score Legend**: 4 = Excellent, 3 = Good, 2 = Adequate, 1 = Poor

**Note**: Only three dimensions evaluated (targeted scope). PF-EVR-011 previously scored all seven dimensions for structural concerns.

## Detailed Findings

### 5. Effectiveness

**Score**: 2

**Assessment**: The Routing Phase (Steps 9-12) is structurally well-organized after PF-EVR-011's restructuring. The problem is epistemic, not structural: the E2E and performance routing decisions it asks for cannot be made reliably at this stage of the workflow.

**Evidence from practice**:
- All 22 existing E2E test cases in e2e-test-tracking.md are cross-cutting workflow tests (WF-001 through WF-008), created from cross-cutting spec TE-TSP-044 driven by user-workflow-tracking.md
- Zero E2E tests originated from per-feature routing plans in any feature test spec
- All entries in performance-test-tracking.md have `Spec Ref: —` — no performance test was ever specified by PF-TSK-012
- None of the 7 existing feature test specs contain a "Routing Plan" section (all are retrospective, predating the Routing Phase addition)

**Findings**:

| # | Finding | Severity | Affected Artifact(s) |
|---|---------|----------|---------------------|
| EFF-1 | E2E routing at per-feature scope is structurally mismatched — E2E tests are inherently cross-cutting workflows spanning multiple features. The framework already has a working cross-cutting milestone trigger that doesn't need per-feature routing | High | PF-TSK-012 Steps 9-12 |
| EFF-2 | Performance routing before code is speculative — the Performance Testing Guide's own decision matrix asks implementation-time questions ("does this change affect a hot-path component?") that can't be answered from a TDD | High | PF-TSK-012 Step 9b, PF-GDE-060 |
| EFF-3 | The `both` classification (needs automated AND E2E) requires pre-deciding testability vs. human observation necessity before any code exists | Medium | PF-TSK-012 Step 9a |

---

### 2. Consistency

**Score**: 2

**Assessment**: The single-feature scope of PF-TSK-012 conflicts with the inherently cross-cutting nature of E2E and performance testing. The framework has two competing mechanisms for E2E test identification.

**Findings**:

| # | Finding | Severity | Affected Artifact(s) |
|---|---------|----------|---------------------|
| CON-1 | Single-feature scope contradicts cross-cutting test nature — PF-TSK-012 asks a single-feature spec to anticipate multi-feature integration, but integration information lives in user-workflow-tracking.md | High | PF-TSK-012 Step 9 |
| CON-2 | Two competing E2E identification mechanisms: (1) per-feature routing in PF-TSK-012 and (2) milestone trigger in ai-tasks.md workflows. These can produce duplicate or contradictory E2E specifications | Medium | PF-TSK-012, ai-tasks.md |

---

### 3. Redundancy

**Score**: 2

**Assessment**: Per-feature E2E/performance routing duplicates decisions that are better made at other workflow points where more information is available.

**Findings**:

| # | Finding | Severity | Affected Artifact(s) |
|---|---------|----------|---------------------|
| RED-1 | E2E routing in PF-TSK-012 duplicates the cross-cutting milestone trigger mechanism which has proven effective in practice | Medium | PF-TSK-012 Step 9a, ai-tasks.md |
| RED-2 | Performance routing in PF-TSK-012 duplicates the Performance Testing Guide's decision matrix which operates at implementation time | Medium | PF-TSK-012 Step 9b, PF-GDE-060 |
| RED-3 | Routing plan table in test spec documents creates maintenance burden — routing decisions change during implementation, requiring updates to both the spec and tracking files | Low | PF-TEM-031 |

## Industry Research Context

**Research conducted to calibrate dimension scores against external standards.**

| Dimension | External Reference(s) | Calibration Impact |
|-----------|----------------------|-------------------|
| Effectiveness | ISTQB Test Management — separates "Test Planning" (scope, approach) from "Test Design" (detailed cases). Planning identifies what needs testing, not execution method | Confirms: pre-code planning should identify test scope, not who runs it |
| Effectiveness | Google Testing Pyramid — classifies by size (small/medium/large) based on execution constraints, decided at implementation time | Confirms: test classification is an implementation-time decision |
| Consistency | BDD (Behavior-Driven Development) — scenarios written before code, but execution method decided during automation | Confirms: scenario identification pre-code ✓, execution routing pre-code ✗ |
| Redundancy | IEEE 829 Master Test Plan — identifies items and features to test early; assigns testing approach during test design phase | Confirms: what-to-test early, how-to-test later |

**Key Observations**: Industry standards consistently support identifying what needs testing before code (test scope planning), but defer how to test it and who runs it to implementation time. PF-TSK-012's Routing Phase conflates scope planning with execution routing.

## Improvement Recommendations

| # | Finding Ref | Description | Priority | Effort | Route |
|---|-------------|-------------|----------|--------|-------|
| 1 | EFF-1, EFF-2, EFF-3, CON-1, CON-2, RED-1, RED-2 | **Eliminate per-feature E2E and performance routing from PF-TSK-012** (Level C). Remove the Routing Phase entirely. E2E testing relies exclusively on the cross-cutting milestone trigger. Performance testing relies on the Performance Testing Guide's decision matrix at implementation time. PF-TSK-012 becomes purely "automated test specification from TDDs." | High | Medium | PF-TSK-009 |
| 2 | RED-3 | **Remove Routing Plan section from test specification template**. Replace with simplified component-to-test-type mapping within the Specification Phase. | High | Low | Part of #1 |
| 3 | CON-2 | **Update ai-tasks.md workflow descriptions** to clarify that E2E identification happens at milestone trigger, not during per-feature test spec creation | Medium | Low | Part of #1 |

**Decision**: Level C selected by human partner. All three improvements implemented together as a single change.

## Summary

**Strengths**:
- PF-TSK-012's automated test specification capability is strong and well-suited to pre-code, per-feature scope
- The Routing Phase structure (from PF-EVR-011) is well-organized — the problem is scope, not structure
- The cross-cutting E2E milestone trigger mechanism works well in practice and doesn't need per-feature routing
- The Performance Testing Guide's decision matrix is self-contained and operates at the right workflow point

**Areas for Improvement**:
- E2E and performance routing decisions cannot be made reliably before code exists, from a single-feature perspective
- Zero existing E2E or performance tests were created through per-feature routing — the mechanism has never produced results
- Two competing E2E identification mechanisms create confusion and potential duplication

**Decision**: Eliminate per-feature E2E/PE routing entirely (Level C). PF-TSK-012 becomes focused on automated test specification — its proven core competency.
