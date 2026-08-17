---
id: PF-TEM-064
type: Process Framework
category: Template
version: 1.3
created: 2026-03-24
updated: 2026-07-19
description: Template for structured framework evaluation reports with dimension scoring
creates_document_prefix: PF-EVR
template_for: Evaluation Report
usage_context: Process Framework - Evaluation Report Creation
creates_document_category: Evaluation Report
creates_document_type: Process Framework
creates_document_version: 1.0
---

# Framework Evaluation Report

## Document Metadata

| Field | Value |
|-------|-------|
| Report ID | [DOCUMENT_ID] |
| Date | [DATE] |
| Evaluation Scope | [Evaluation Scope] |
| Evaluator | AI Agent & Human Partner |
| Task Reference | PF-TSK-079 (Framework Evaluation) |

## Evaluation Scope

**Scope Description**: [Evaluation Scope]

**Scope Type**: [Full Framework / Phase Scope / Component Type / Workflow Scope / Targeted]

**Artifacts in Scope**:

| # | Artifact | Type | ID |
|---|----------|------|----|
| 1 | [Artifact name] | [task/template/guide/script/etc.] | [ID] |

## Dimensions Evaluated

| # | Dimension | Score | Key Finding |
|---|-----------|-------|-------------|
| 1 | Completeness | [1-4] | [One-line summary] |
| 2 | Consistency | [1-4] | [One-line summary] |
| 3 | Redundancy | [1-4] | [One-line summary] |
| 4 | Accuracy | [1-4] | [One-line summary] |
| 5 | Effectiveness | [1-4] | [One-line summary] |
| 6 | Automation Coverage | [1-4] | [One-line summary] |
| 7 | Scalability | [1-4] / N/A | [One-line summary] |

**Overall Score**: [Average of evaluated dimensions] / 4.0

**Score Legend**: 4 = Excellent, 3 = Good, 2 = Adequate, 1 = Poor

## Detailed Findings

> **Targeted / single-artifact scope**: For a small scope (a single artifact, or a narrow targeted evaluation), you need not instantiate all seven dimension sections — keep only the dimensions you actually evaluated and delete the rest (and their rows from the Dimensions Evaluated table above). At this scope you may also use **flat finding numbering** (`F-1`, `F-2`, …) across the whole report instead of the per-dimension prefixes (`C-`/`N-`/`R-`/`A-`/`E-`/`U-`/`S-`); the per-dimension prefixes pay off only when many findings span several dimensions.

> **Cross-cutting findings**: When a finding affects 2+ dimensions, record it once in the [Cross-Cutting Findings](#cross-cutting-findings) section below and reference it by ID (e.g., "See X-1") in each affected dimension's table. Do not repeat the full description under each dimension.

> **Dimension with no findings**: an in-scope dimension that produced no findings keeps its Score and Assessment; fill its findings table with the single row `| — | No findings | — | — |`.

### 1. Completeness

**Score**: [1-4]

**Assessment**: [Detailed assessment with specific evidence]

**Findings**:

| # | Finding | Severity | Affected Artifact(s) |
|---|---------|----------|---------------------|
| C-1 | [Description] | [High/Medium/Low] | [File path(s)] |

---

### 2. Consistency

**Score**: [1-4]

**Assessment**: [Detailed assessment with specific evidence]

**Findings**:

| # | Finding | Severity | Affected Artifact(s) |
|---|---------|----------|---------------------|
| N-1 | [Description] | [High/Medium/Low] | [File path(s)] |

---

### 3. Redundancy

**Score**: [1-4]

**Assessment**: [Detailed assessment with specific evidence]

**Findings**:

| # | Finding | Severity | Affected Artifact(s) |
|---|---------|----------|---------------------|
| R-1 | [Description] | [High/Medium/Low] | [File path(s)] |

---

### 4. Accuracy

**Score**: [1-4]

**Assessment**: [Detailed assessment with specific evidence]

**Findings**:

| # | Finding | Severity | Affected Artifact(s) |
|---|---------|----------|---------------------|
| A-1 | [Description] | [High/Medium/Low] | [File path(s)] |

---

### 5. Effectiveness

**Score**: [1-4]

**Assessment**: [Detailed assessment with specific evidence]

**Findings**:

| # | Finding | Severity | Affected Artifact(s) |
|---|---------|----------|---------------------|
| E-1 | [Description] | [High/Medium/Low] | [File path(s)] |

---

### 6. Automation Coverage

**Score**: [1-4]

**Assessment**: [Detailed assessment with specific evidence]

**Findings**:

| # | Finding | Severity | Affected Artifact(s) |
|---|---------|----------|---------------------|
| U-1 | [Description] | [High/Medium/Low] | [File path(s)] |

---

### 7. Scalability

**Score**: [1-4] / N/A

**Assessment**: [Detailed assessment with specific evidence]

**Findings**:

| # | Finding | Severity | Affected Artifact(s) |
|---|---------|----------|---------------------|
| S-1 | [Description] | [High/Medium/Low] | [File path(s)] |

## Cross-Cutting Findings

> Findings that affect 2+ dimensions are listed here once. Each dimension's findings table references these by ID rather than repeating the description.

| # | Finding | Severity | Affected Dimensions | Affected Artifact(s) |
|---|---------|----------|---------------------|---------------------|
| X-1 | [Description of cross-cutting issue] | [High/Medium/Low] | [e.g., Consistency, Accuracy] | [File path(s)] |

## Industry Research Context

**Research conducted to calibrate dimension scores against external standards.**

| Dimension | External Reference(s) | Calibration Impact |
|-----------|----------------------|-------------------|
| [Dimension] | [Framework, standard, or practice referenced] | [How it influenced the score] |

**Key Observations**: [Summary of how the evaluated scope compares to industry norms]

## Improvement Recommendations

| # | Finding Ref | Description | Priority | Effort | IMP ID |
|---|-------------|-------------|----------|--------|--------|
| 1 | [C-1] | [Improvement description] | [High/Medium/Low] | [High/Medium/Low] | [PF-IMP-XXX] |

## Findings Resolved In-Session

> Findings fixed during the evaluation session itself under the task's fix-vs-route rule (fix confined to artifacts the session or its parent extension created or modified) are recorded here; they have no Improvement Recommendations row.

| # | Finding Ref | Fix Applied | Verification |
|---|-------------|-------------|--------------|
| 1 | [C-1] | [What was changed] | [How the fix was verified] |

## Withdrawn During Verification

> Candidate findings dropped by the verify-each-finding pass are recorded here so the report shows its own false-positive rate, not only surviving findings.

| # | Candidate Finding | Withdrawal Reason |
|---|-------------------|-------------------|
| 1 | [Description] | [Why it did not survive verification] |

## Summary

**Strengths**: [Key areas where the framework performs well]

**Areas for Improvement**: [Key areas that need attention]

**Recommended Next Steps**:
1. [Highest priority action]
2. [Second priority action]
3. [Third priority action]
