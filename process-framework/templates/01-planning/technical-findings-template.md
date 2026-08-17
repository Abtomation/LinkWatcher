---
id: PF-TEM-085
type: Process Framework
category: Template
version: 1.0
created: 2026-07-16
updated: 2026-07-16
creates_document_category: Technical
creates_document_prefix: PD-TEC
creates_document_type: Product Documentation
creates_document_version: 1.0
description: "Template for Technical Exploration findings documents (PD-TEC) — research summary, options comparison, recommendation, and residual-items table"
template_for: Technical
usage_context: Product Documentation - Technical Creation
---

# [DOCUMENT_ID]: [Exploration title — the question, not the answer]

<!--
Created by New-TechnicalDoc.ps1 for the Technical Exploration task (PF-TSK-093).
This document is the ARTIFACT OF RECORD for one exploration spike, and the RUNNING LOG for a
spike that spans sessions — bump `Findings Version` and add a Research Log row each session.
Keep the research here, not in the tracker's Notes cell.
Remove instructional comments (<!-- ... -->) as you fill each section.
-->

| Field | Value |
|-------|-------|
| Exploration | [PD-EXP-NNN] — [link to the Technical Exploration Tracking row] |
| Related Feature | [Feature ID + name, or "— (pre-feature exploration)"] |
| Findings Version | 1.0 <!-- bump each session this document is extended --> |
| Status | [🔬 In Progress / ✅ Resolved — mirrors the tracker row] |
| Created / Updated | [DATE] / [DATE] |

## Research Question

<!-- State the question so that "answered" is unambiguous. Copy it from the tracker row and
sharpen it if the row was terse. -->

[The open question this spike must answer before the dependent work can proceed.]

### Acceptance Criteria

<!-- What must be true for this exploration to be resolvable. These are the criteria the
recommendation is judged against — not a wish list. -->

- [ ] [Criterion 1 — what must be established]
- [ ] [Criterion 2]

### Scope Boundaries

<!-- Research expands without a stated edge. Name what this spike deliberately does NOT
investigate, so the reader knows the silence is intentional rather than an omission. -->

- **In scope**: [what was investigated]
- **Out of scope**: [what was deliberately not investigated, and why]

## Research Summary

<!-- The evidence gathered, and how. Keep it decision-relevant: what a reader needs to trust
the recommendation. Cite sources/versions — a findings doc read six months later is judged on
whether its evidence is still current. -->

[Narrative summary of what was investigated, how, and what the evidence shows.]

### Evaluation Criteria

<!-- The criteria the options are compared against, stated BEFORE the comparison so the
verdict is auditable rather than post-hoc. Weight them if they are not equal. -->

| Criterion | Why it matters | Weight (if unequal) |
|-----------|----------------|---------------------|
| [Criterion] | [What decision it drives] | [High/Medium/Low] |

## Options Compared

<!-- One row per candidate. Every option is scored against the criteria above. An option that
was rejected early still belongs here with the reason — "we considered and rejected X" is a
finding, and it stops the next agent re-running the same dead end. -->

| Option | Summary | Strengths | Weaknesses | Verdict |
|--------|---------|-----------|------------|---------|
| [Option A] | [What it is] | [Where it fits the criteria] | [Where it fails them] | [Recommended / Rejected — why] |
| [Option B] | [What it is] | [Strengths] | [Weaknesses] | [Verdict] |

### Prototype / Benchmark Evidence (if applicable)

<!-- Only when a prototype or benchmark was actually built/run. Record what was measured, the
conditions, and the numbers — not an impression. Remove this section if the decision needed no
prototype (per the task: prototype only as deep as the decision requires). -->

[What was built or measured, under what conditions, and the results.]

## Recommendation

<!-- The decision-oriented core. State a clear recommendation, not a menu — the downstream task
reads this to proceed. If the evidence genuinely does not separate the options, say so and state
what would. -->

**Recommendation**: [The recommended option / answer.]

**Rationale**: [Why it wins against the stated criteria.]

**Confidence**: [High / Medium / Low] — [what drives the confidence level, and what would change it.]

### Residual Uncertainty

<!-- Honest recording of what remains unknown. A spike that claims certainty it does not have is
worse than one that names its gaps. -->

[What this exploration could NOT establish, and what risk that leaves for the dependent work.]

## Residual Items

<!-- Open items this exploration surfaced but did not resolve — each with the vehicle that
should carry it. This table is how a spike hands off work it is not allowed to do itself:
the exploration task is research-only, so anything actionable leaves through a vehicle.
Vehicles: new feature request (New-FeatureRequest.ps1) · follow-up exploration
(New-Exploration.ps1) · technical debt item (New-DebtItem.ps1) · bug report (New-BugReport.ps1)
· framework improvement (New-ProcessImprovement.ps1). Record the filed ID once routed. -->

| Item | Why it is out of this spike's scope | Suggested Vehicle | Filed As |
|------|-------------------------------------|-------------------|----------|
| [Open item] | [Why it is not resolved here] | [Feature request / Follow-up exploration / Tech debt / Bug / IMP] | [ID once filed, or "not yet filed"] |

## Impact on Dependent Work

<!-- Close the loop the exploration was queued to close: what the blocked work should now do. -->

[What the dependent feature/design should do given the recommendation — the constraint,
choice, or approach it now inherits.]

## Research Log

<!-- One row per session. For a multi-session spike this is the continuity record: the next
session reads it to learn where the research stands. Bump `Findings Version` above with each
new row. -->

| Date | Version | Session Focus | Outcome |
|------|---------|---------------|---------|
| [YYYY-MM-DD] | [1.0] | [What this session investigated] | [What it established / what remains] |

## References

<!-- Sources, with versions/dates where the claim is version-sensitive (library docs, pricing
pages, API capabilities all drift). -->

- [Source — URL / document reference, version or access date]
