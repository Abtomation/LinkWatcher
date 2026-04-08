---
id: PF-TEM-069
type: Process Framework
category: Template
version: 1.0
created: 2026-04-05
updated: 2026-04-05
usage_context: Onboarding - Quality Gate (PF-TSK-065/PF-TSK-066)
creates_document_version: 1.0
template_for: Quality Assessment Report
creates_document_category: Quality Assessment Report
description: Template for Quality Assessment Reports created during onboarding for Target-State features
creates_document_prefix: PD-QAR
creates_document_type: Product Documentation
---

# Quality Assessment Report: [Feature Name]

> **Onboarding Quality Gate**: This report summarizes the quality evaluation for a feature classified as **Target-State** during onboarding. It provides the big-picture view linking all generated tech debt items together with a recommended remediation sequence.
>
> **Related Feature**: [Feature ID] — [Feature Implementation State file link]

---

## 1. Feature Summary

- **Feature ID**: [Feature ID]
- **Feature Name**: [Feature Name]
- **Tier**: [Tier 1 / Tier 2 / Tier 3]
- **Classification**: Target-State
- **Average Score**: [X.X] / 3.0
- **Assessed During**: PF-TSK-065 (Codebase Feature Analysis)
- **Assessment Date**: [YYYY-MM-DD]

---

## 2. Dimension Scores

| Dimension | Score (0-3) | Evidence |
|-----------|-------------|----------|
| **Structural clarity** | [0-3] | [Specific observations — e.g., god class in X, no layer separation] |
| **Error handling** | [0-3] | [Specific observations — e.g., silent exception swallowing in Y] |
| **Data integrity** | [0-3] | [Specific observations — e.g., no input validation on Z] |
| **Test coverage** | [0-3] | [Specific observations — e.g., 0 tests, or only happy path covered] |
| **Maintainability** | [0-3] | [Specific observations — e.g., cyclomatic complexity > 20 in W] |

### Score Legend

| Score | Meaning |
|-------|---------|
| **0** | Absent or broken — capability doesn't exist or is non-functional |
| **1** | Present but problematic — exists but has significant issues |
| **2** | Adequate — works correctly, follows reasonable patterns |
| **3** | Well-implemented — clean, robust, follows best practices |

---

## 3. Overall Quality Assessment

[2-3 paragraph summary of the feature's quality. Describe the systemic issues — not just individual symptoms, but what's fundamentally wrong with the implementation approach. This section answers: "Why is this feature below standard as a whole?"]

### Strengths

- [What works well despite the overall low score]

### Systemic Issues

- [Issue 1 — the root cause, not just a symptom]
- [Issue 2]

---

## 4. Gap Analysis Summary

> Each gap identified in the target-state FDD/TDD maps to a tech debt item. This table provides the consolidated view.

| Gap ID | Description | Dimension | Severity | Tech Debt Item | Status |
|--------|-------------|-----------|----------|---------------|--------|
| GAP-001 | [Brief description of gap between current and target state] | [Dimension] | [CRITICAL/HIGH/MEDIUM/LOW] | [PD-TDI-XXX or PENDING] | [OPEN / IN_PROGRESS / RESOLVED] |
| GAP-002 | [Brief description] | [Dimension] | [Severity] | [PD-TDI-XXX or PENDING] | [Status] |

---

## 5. Recommended Remediation Sequence

> Order gaps by dependency and impact. Fix foundational issues first so that subsequent fixes build on stable ground.

### Phase 1: Foundation Fixes
*Fix these first — other improvements depend on them.*

1. **GAP-XXX**: [Description] — **Why first**: [Reason]

### Phase 2: Quality Improvements
*Fix these after foundation is stable.*

2. **GAP-XXX**: [Description] — **Why second**: [Reason]

### Phase 3: Polish
*Fix these last — nice-to-have improvements.*

3. **GAP-XXX**: [Description] — **Why last**: [Reason]

### Estimated Effort

| Phase | Gaps | Estimated Effort |
|-------|------|-----------------|
| Foundation Fixes | [N] | [Rough estimate] |
| Quality Improvements | [N] | [Rough estimate] |
| Polish | [N] | [Rough estimate] |

---

## 6. Links

- **Feature Implementation State**: [path to feature state file]
- **FDD (Target-State)**: [path to FDD, if created]
- **TDD (Target-State)**: [path to TDD, if created]
- **Tech Debt Items**: [links to individual PD-TDI-XXX items]
- **Feature Tracking**: [link to feature-tracking.md entry]
