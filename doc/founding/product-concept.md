---
id: PD-DOC-001
type: Product Documentation
category: Concept
version: 1.0
created: 2026-07-17
updated: 2026-07-17
status: Stub — no founding material synthesized yet
description: "The project's Product Concept — the authoritative statement of what is being built and why, synthesized from the founding inputs."
---

# [Product Name] — Product Concept

> **📝 This is a structured stub.** It ships with the framework so that every task needing the
> project's product intent has a stable path to read from day one. It is intentionally
> **unfilled** — its `status` reads `Stub — no founding material synthesized yet`.
>
> - **Greenfield**: [Project Initiation (PF-TSK-059)](../../process-framework/tasks/00-setup/project-initiation-task.md)
>   reads [`founding/inputs/`](inputs/README.md) and synthesizes this document from it, gated by a
>   human checkpoint.
> - **Onboarding**: [Retrospective Documentation Creation (PF-TSK-066)](../../process-framework/tasks/00-setup/retrospective-documentation-creation.md)
>   captures the existing codebase's origin documents into this structure.
>
> A project with no founding material leaves this stub unfilled — that is a valid state, not a
> defect (the same treatment as the Release Process Guide stub). This stub is instantiated from
> the [Product Concept Template (PF-TEM-086)](../../process-framework/templates/00-setup/product-concept-template.md).
>
> Fill every `[placeholder]`, set `status`, and delete this banner when the concept is written.

## Provenance Convention

This concept distinguishes two kinds of statement, and every reader depends on the distinction:

- **Input-sourced commitments** — traceable to a document in `founding/inputs/`. These are what
  the human partner actually decided.
- **Agent-developed interpretation** — marked inline with *(elaboration)*. These are reasoned
  extensions, not commitments, and may be corrected without contradicting the source.

Mark every elaboration. An unmarked claim is read as a commitment.

## Sources

> The founding inputs this concept was synthesized from. Inputs carry no IDs and are excluded
> from the documentation map, so this table is their only index — it is how traceability
> survives. Add a row whenever an input is added.

| Input | Path | What it contributes |
|-------|------|---------------------|
| [Input name] | `founding/inputs/[filename]` | [What this concept drew from it] |

## Vision

[2-4 sentences: what this product is, for whom, and what changes for them if it exists.]

## Target Users

- **[User group]** — [who they are, what they need, what they do today instead]

## Core Value Proposition

[Why would each target user group choose this over what they use now?]

## Capability Areas

> The broad areas of capability the product needs — **not** a feature list. Feature Discovery
> (PF-TSK-013) derives features from these.

- **[Capability area]** — [what it covers, and for which user group]

## Business Model Notes (if applicable)

> Delete this section for products with no commercial model. Where the model lives in a founding
> input, summarize and cite rather than restating it in full.

[Business model notes]

## Open Questions

> Unresolved **product-intent** questions ("what should this product do?"). A question about
> feasibility or which technology to use is a *technical exploration* instead — file it into
> `state-tracking/permanent/technical-exploration-tracking.md` via `New-Exploration.ps1`.

| # | Question | Why it matters | Status |
|---|----------|----------------|--------|
| Q1 | [Question] | [What it blocks or changes] | Open |

## Related Resources

- [Founding Inputs](inputs/README.md) — the raw material this concept synthesizes
- [Feature Landscape](feature-landscape.md) — the discovery-cycle rationale record derived from this concept
- [Feature Discovery (PF-TSK-013)](../../process-framework/tasks/01-planning/feature-discovery-task.md) — the primary downstream consumer
