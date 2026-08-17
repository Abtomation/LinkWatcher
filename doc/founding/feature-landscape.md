---
id: PD-DOC-002
type: Product Documentation
category: Planning
version: 1.0
created: 2026-07-17
updated: 2026-07-17
status: Stub — no discovery cycle recorded yet
description: "The project's Feature Landscape — why the feature set is shaped the way it is: method, granularity calls, category and prioritization rationale."
---

# [Product Name] Feature Landscape

> **📝 This is a structured stub.** It is filled at [Feature Discovery (PF-TSK-013)](../../process-framework/tasks/01-planning/feature-discovery-task.md)
> Finalization and **extended in place** on each later discovery cycle — one landscape per
> project, never a new document per cycle. Its `status` reads
> `Stub — no discovery cycle recorded yet` until then.
>
> **🚨 This document carries no feature list.** Every piece of feature *data* already has an
> owner: the requests, descriptions and priorities live in
> [feature-request-tracking.md](../state-tracking/permanent/feature-request-tracking.md); the
> category structure lands in [feature-tracking.md](../state-tracking/permanent/feature-tracking.md)
> once features are promoted; research questions go to
> [technical-exploration-tracking.md](../state-tracking/permanent/technical-exploration-tracking.md);
> complexity is assessed at Feature Request Evaluation. Re-listing any of it here creates a
> duplicate that rots as the trackers move on. Reference features by `PD-FRQ` ID only.
>
> This stub is instantiated from the [Feature Landscape Template (PF-TEM-087)](../../process-framework/templates/01-planning/feature-landscape-template.md).
> Fill every `[placeholder]`, set `status`, and delete this banner when the first cycle is recorded.

## Scope — What This Document Owns

This landscape owns the **reasoning behind the feature set**: the method a discovery cycle
applied, the granularity calls it made, and why the categories and priorities came out as they
did. It does **not** hold the feature set itself.

Its consumers are human: the reader who later asks *"why isn't Search part of Discovery?"*, and
Feature Request Evaluation (PF-TSK-067) reading the grouping and rationale forward. It is also
the artifact each intake row's `Source` link points at, so discovery provenance resolves to a
real document rather than a bare date string.

A cycle that made no non-obvious calls can leave this thin — the record scales with the
reasoning actually done, not with the feature count.

## Method

[How this cycle was run: what was read, what was compared, in what order.]

## Granularity Calls

> The [Feature Granularity Guide](../../process-framework/guides/01-planning/feature-granularity-guide.md)
> mandates three tests per feature — planning, conversation, independence. Their **outcomes** are
> what vanishes without this section. Record only the non-obvious ones; a feature that passed all
> three uneventfully needs no row.

| Feature (PD-FRQ) | Call | Which test drove it | Reasoning |
|------------------|------|---------------------|-----------|
| [PD-FRQ-NNN] | Split / Merged / Kept whole / Reshaped | Planning / Conversation / Independence | [Why] |

## Category Rationale

> Grouping features into categories is a **cross-cutting** decision — no per-row tracker field
> can hold it, which is why it is recorded here. Give the reasoning, not a feature roster.

| Category | Why this is a category | Members (PD-FRQ) |
|----------|------------------------|------------------|
| [Category name] | [What makes these one coherent group] | [PD-FRQ-NNN, ...] |

**Borderline groupings**: [Features that could reasonably have gone elsewhere, and why they landed where they did.]

## Prioritization Rationale

> The tracker holds each request's priority *value*. It does not hold why.

[What drove HIGH vs. MEDIUM vs. LOW for this cycle, and any priority that needs defending.]

## 0.x Foundation Candidates (if applicable)

> Delete unless the project opted into the 0.x foundation category at Project Initiation.

| Candidate (PD-FRQ) | Why it reads as foundation | Depends on |
|--------------------|---------------------------|------------|
| [PD-FRQ-NNN] | [Reasoning] | [Dependencies] |

## Predecessor Complement (relaunch projects only)

> **🚨 Delete this entire section** unless this project relaunches or replaces a predecessor
> product. It exists for the narrow case where a blind-first draft is deliberately complemented
> against an archived predecessor feature list — a relaunch-specific practice, not part of a
> normal cycle.

**Predecessor**: [Product name and where its feature list lives]

| Feature (PD-FRQ) | Origin | Reasoning |
|------------------|--------|-----------|
| [PD-FRQ-NNN] | Blind draft / Added by complement pass / Deliberately not carried over | [Why] |

**Deliberate omissions**: [Predecessor features intentionally not carried forward, and why — the most valuable half of a complement pass and the easiest to lose.]

## Cycle Log

| Cycle | Date | Scope | Outcome |
|-------|------|-------|---------|
| 1 | [YYYY-MM-DD] | [What this cycle covered] | [N requests filed as PD-FRQ-NNN..NNN; approved at checkpoint] |

## Related Resources

- [Product Concept](product-concept.md) — the concept each cycle derives features from
- [Feature Request Tracking](../state-tracking/permanent/feature-request-tracking.md) — owns the feature data this document deliberately does not duplicate
- [Feature Discovery (PF-TSK-013)](../../process-framework/tasks/01-planning/feature-discovery-task.md) — fills and extends this document
