---
id: PF-TEM-046
type: Process Framework
category: Template
version: 1.8
created: 2026-02-26
updated: 2026-08-04
template_for: Review
creates_document_category: Review
creates_document_prefix: ART-REV
creates_document_type: Process Framework
usage_context: Tools Review Task (PF-TSK-010) - Review Summary Output
creates_document_version: 1.0
description: Standardized template for Tools Review task (PF-TSK-010) summary output documents
---

# Tools Review Summary — [YYYY-MM-DD]

## Review Scope

| Attribute | Value |
|-----------|-------|
| Forms Analyzed | [N] feedback forms |
| Date Range | [start date] to [end date] |
| Tools Evaluated | [N]+ unique tools |

---

## Task Group Analysis

<!-- Repeat this block for each task type group. All forms for the same task type must be analyzed together. -->

### Group [N]: [PF-TSK-XXX] — [Task Name] ([N] forms)

**Context**: [Brief description of what was being done when these forms were created]

#### Quantified Ratings

| Tool | Effectiveness | Clarity | Completeness | Efficiency | Conciseness |
|------|:---:|:---:|:---:|:---:|:---:|
| [Tool Name] | [1-5] | [1-5] | [1-5] | [1-5] | [1-5] |
| **Overall effectiveness** | **[1-5]** | — | — | — | — |
| **Process conciseness** | — | — | — | — | **[1-5]** |

#### Themes
- [Key finding or pattern from this task group]

#### Improvement Opportunities

<!-- IDs only — the tracker row is authoritative for what a row says. Why each was filed goes once in the Session Digest's filing plan, not here. -->

- **[PF-IMP-XXXX]**

---

<!-- End of repeatable Task Group block -->

## Cross-Group Themes

<!-- Identify patterns that appear across multiple task groups. Include task group references and frequency. If this session's batch was split from a larger inventory, record the deferred scope (which forms/groups remain) and which themes could not be fully verified against the deferred forms. -->

### Theme [N]: [Theme Title] ([N]/[total] forms)
[Description of the cross-cutting pattern, which task groups it appears in, and why it matters.]

---

## Improvement Opportunities Summary

<!-- Row IDs only — never restate a tracker row's description here. A description copied into this table is a second, hand-paired copy of data the tracker already owns: it can be wrong the moment it is written, it cannot be checked by a reader who has only this file, and it is read downstream as if authoritative (PF-TSK-009's review-source step sends every implementing session here). Resolve any ID with `Find-Improvement.ps1 -Keyword PF-IMP-NNNN`, which prints the row's real description and its current disposition. -->

| ID | Source Tasks | Frequency |
|----|-------------|-----------|
| PF-IMP-[XXXX] | [PF-TSK-XXX] | [N]/[total] forms |

---

## Candidates Dropped on Dedup / Verification

<!-- Raw candidates considered but NOT filed as IMPs — dropped on Step 2 verification or cross-file dedup (already-done, already-resolved, rejected-conversion, covered/trivial). On a mature, low-net-new batch this set is most of the analytical output, so capturing the dedup reasoning is the point of the review. Omit the section only when nothing was dropped. -->

| Candidate | Source form | Disposition |
|-----------|-------------|-------------|
| [Brief candidate description] | [PF-FEE-XXX] | [Already shipped/resolved (IMP-ID) · Covered · Rejected · Trivial — one-line reason] |

---

## Backlog Accounting (materiality bar — PF-IMP-1882)

<!-- Candidates below the materiality bar routed to the central improvement-backlog.md instead of Intake, plus rows promoted (second report) and expired (counter aged out) this session. Digest-visible so the owner can rescue a backlogged candidate with one word. Omit the section only when the bar produced no backlog activity. -->

| BKL-ID | Candidate | Source Task | Outcome |
|--------|-----------|-------------|---------|
| [BKL-NNN] | [Brief candidate description] | [PF-TSK-XXX] | [Backlogged (Counter [N]) · Promoted → PF-IMP-XXXX · Expired] |

---

## Human User Feedback

<!-- Source: human-appended (post-session) rows in the analyzed forms' Human Intervention Logs, plus any direct feedback given during the review session itself. This is MANDATORY per PF-TSK-010. -->

| # | Feedback | Source |
|---|----------|--------|
| 1 | [Direct quote or paraphrase] | [Form intervention-log row / review-session input] |

---

## Session Digest (PF-PRO-059)

<!-- This document IS the session digest — the owner reviews it at the Standing Orders cadence, where silence = consent and a veto is a scripted move-back. The four slots below are what PF-TSK-010's fill-review-summary step mandates and no other section houses; Candidates Dropped and Backlog Accounting above complete the digest. -->

### Batch-selection decision

[Feedback inventory, task groupings, the batch selected for this session (which whole task groups, total form count), and why that fits one session per the density-driven sizing. When one task group alone exceeds roughly half the inventory, say so — that shape determines which split options exist. Initial themes at selection.]

### Filing plan

<!-- One line per filed row: why it was filed. Reference the row ID; never restate the row. -->

- **[PF-IMP-XXXX]** — [why this was filed]

### Ambiguities, named individually

[Each genuine judgment call as its own entry — ambiguous calls are what the owner reviews. A row the owner may read as churn belongs here, named, with the reason it is arguable.]

### Core files touched

[Task definitions and guides this session edited — feeds the Standing Orders oscillation tripwire (same core section edited by ≥2 sessions in one review interval).]

---

## Archived Forms

<!-- List all feedback forms analyzed in this review. These will be moved to the archive after the review. -->

| Form | Task | Context |
|------|------|---------|
| [filename.md] | [PF-TSK-XXX] | [Brief context] |

**Kept active**: [List any forms NOT archived, e.g., the PF-TSK-010 feedback form created for this session]
