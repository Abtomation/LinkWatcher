---
id: PF-TEM-087
type: Process Framework
category: Template
version: 1.0
created: 2026-07-17
updated: 2026-07-17
creates_document_category: Planning
creates_document_prefix: PD-DOC
creates_document_type: Product Documentation
creates_document_version: 1.0
description: "Template for a project's Feature Landscape (PD-DOC-002) - the discovery-cycle rationale record: method, granularity-test outcomes, category and prioritization rationale"
template_for: Planning
usage_context: Product Documentation - Planning Creation
---

# [Product Name] Feature Landscape

<!--
INSTANCE INSTRUCTIONS — delete this whole comment block in the finished landscape.

This document records WHY the feature set is shaped the way it is. It is filled at Feature
Discovery (PF-TSK-013) Finalization and EXTENDED IN PLACE on each later discovery cycle — one
landscape per project, never a new document per cycle.

🚨 THIS DOCUMENT CARRIES NO FEATURE LIST. That is the single most important rule here, and it
is deliberate. Every piece of feature DATA already has an owner:

  • the features themselves, their descriptions,
    user benefits and priorities  → feature-request-tracking.md (via New-FeatureRequest.ps1)
  • the category structure, once
    features are promoted          → feature-tracking.md's hierarchical IDs
  • open research questions        → technical-exploration-tracking.md (via New-Exploration.ps1)
  • complexity estimates           → the tier assessment at Feature Request Evaluation

Re-listing any of that here creates a duplicate that silently rots as the trackers move on.
What has NO other home — and what this document exists for — is the REASONING: the method, the
granularity calls, and the category and prioritization rationale. Reference features by their
PD-FRQ IDs; never restate their content.

It ships as `doc/founding/feature-landscape.md` (the reserved singleton `PD-DOC-002`). A
project whose discovery cycle made no non-obvious calls can leave it thin — the record should
scale with the reasoning actually done, not with the feature count.

Fill every [placeholder]. Delete sections that do not apply. Remove every instructional
comment before the landscape is complete.
-->

> **📝 Structured stub.** Until a discovery cycle fills it, this document's `status` reads
> `Stub — no discovery cycle recorded yet`.

## Scope — What This Document Owns

This landscape owns the **reasoning behind the feature set**: the method a discovery cycle
applied, the granularity calls it made, and why the categories and priorities came out as they
did. It deliberately does **not** hold the feature set itself — see
[Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md)
for the requests and [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)
for promoted features. Features are referenced here by `PD-FRQ` ID only.

Its consumers are human: the reader who later asks *"why isn't Search part of Discovery?"*, and
Feature Request Evaluation (PF-TSK-067) reading the grouping and rationale forward. It is also
the artifact each intake row's `Source` link points at, so discovery provenance resolves to a
real document rather than a bare date string.

## Method

<!-- How this cycle was run: what was read, what was compared, what order. One short paragraph. -->

[Method]

## Granularity Calls

<!--
The Feature Granularity Guide mandates three tests per feature — planning, conversation,
independence. Their OUTCOMES are what vanishes without this section. Record only the non-obvious
ones: features that were split, merged, or that failed a test and were reshaped. A feature that
passed all three tests uneventfully needs no row.
-->

| Feature (PD-FRQ) | Call | Which test drove it | Reasoning |
|------------------|------|---------------------|-----------|
| [PD-FRQ-NNN] | Split / Merged / Kept whole / Reshaped | Planning / Conversation / Independence | [Why] |

## Category Rationale

<!--
Step 10 groups features into coherent categories. The grouping is a CROSS-CUTTING decision — no
per-row tracker field can hold it, which is why it is recorded here. Give the reasoning, not a
feature roster: name each category and why it is a category, referencing PD-FRQ IDs.
-->

| Category | Why this is a category | Members (PD-FRQ) |
|----------|------------------------|------------------|
| [Category name] | [What makes these one coherent group] | [PD-FRQ-NNN, ...] |

**Borderline groupings**: [Features that could reasonably have gone in another category, and why they landed where they did.]

## Prioritization Rationale

<!--
The tracker holds each request's priority VALUE. It does not hold why. Record the reasoning —
especially anything that would look arbitrary to a later reader.
-->

[Prioritization rationale — what drove HIGH vs. MEDIUM vs. LOW for this cycle, and any priority that needs defending.]

## 0.x Foundation Candidates (if applicable)

<!--
Delete unless the project opted into the 0.x foundation category at Project Initiation.
Features that look like architectural foundations rather than business features, feeding the
Architecture-First workflow.
-->

| Candidate (PD-FRQ) | Why it reads as foundation | Depends on |
|--------------------|---------------------------|------------|
| [PD-FRQ-NNN] | [Reasoning] | [Dependencies] |

## Predecessor Complement (relaunch projects only)

<!--
🚨 DELETE THIS ENTIRE SECTION unless this project relaunches or replaces a predecessor product.
It exists for the narrow case where a blind-first draft is deliberately complemented against an
archived predecessor feature list — a relaunch-specific practice, NOT part of a normal cycle.
Keeping it in a non-relaunch project is pure overhead.
-->

**Predecessor**: [Product name and where its feature list lives]

| Feature (PD-FRQ) | Origin | Reasoning |
|------------------|--------|-----------|
| [PD-FRQ-NNN] | Blind draft / Added by complement pass / Deliberately not carried over | [Why] |

**Deliberate omissions**: [Predecessor features intentionally NOT carried forward, and why — this is the most valuable half of a complement pass and the easiest to lose.]

## Cycle Log

<!--
One row per discovery cycle. This document is extended in place, so this log is how a reader
tells which reasoning came from which cycle.
-->

| Cycle | Date | Scope | Outcome |
|-------|------|-------|---------|
| 1 | [YYYY-MM-DD] | [What this cycle covered] | [N requests filed as PD-FRQ-NNN..NNN; approved at checkpoint] |

## Related Resources

- [Feature Discovery (PF-TSK-013)](../../tasks/01-planning/feature-discovery-task.md) — fills and extends this document
- [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) — the three tests whose outcomes this document records
- [Product Concept Template](../00-setup/product-concept-template.md) — the concept this cycle derived features from
- [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) — owns the feature data this document deliberately does not duplicate
