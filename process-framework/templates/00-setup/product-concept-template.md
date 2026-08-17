---
id: PF-TEM-086
type: Process Framework
category: Template
version: 1.0
created: 2026-07-17
updated: 2026-07-17
creates_document_category: Concept
creates_document_prefix: PD-DOC
creates_document_type: Product Documentation
creates_document_version: 1.0
description: Template for a project's Product Concept (PD-DOC-001) - the synthesis of the project's founding inputs into an authoritative statement of what is being built
template_for: Concept
usage_context: Product Documentation - Concept Creation
---

# [Product Name] — Product Concept

<!--
INSTANCE INSTRUCTIONS — delete this whole comment block in the finished concept.

This document is the project's authoritative statement of WHAT is being built and WHY. It is
the synthesis of the project's founding inputs — whatever pre-existing material the human
partner had in hand (a brief, a business-model document, a deck export, a transcript), which
lives raw and un-ID'd in `doc/founding/inputs/`.

It ships as `doc/founding/product-concept.md` (the reserved singleton `PD-DOC-001`) and is
instantiated one of two ways:

  • Greenfield  — Project Initiation (PF-TSK-059) reads `doc/founding/inputs/` and SYNTHESIZES
                  this document from it, gated by a human checkpoint.
  • Onboarding  — Retrospective Documentation Creation (PF-TSK-066) captures an existing
                  codebase's origin documents into this structure, handing the originals to
                  the pre-framework archival step.

A project with no founding material leaves this stub unfilled — exactly as the Release Process
Guide stub ships unfilled. An unfilled stub is a valid state, not a defect.

Downstream consumers read this BY PATH, not by ID: Feature Discovery (PF-TSK-013) reads it as
the greenfield stand-in for "existing features", and Feature Request Evaluation (PF-TSK-067)
reads it as product-intent context. Keep it current when product intent changes.

Fill every [placeholder]. Delete sections that do not apply. Remove every instructional
comment before the concept is complete.
-->

> **📝 Structured stub.** Until filled, this document's `status` reads
> `Stub — no founding material synthesized yet`. Fill it when the project's intent is known.

## Provenance Convention

<!--
This convention is load-bearing — keep this section in the finished concept.
-->

This concept distinguishes two kinds of statement, and every reader depends on the distinction:

- **Input-sourced commitments** — traceable to a document in `doc/founding/inputs/`. These are
  what the human partner actually decided.
- **Agent-developed interpretation** — marked inline with *(elaboration)*. These are reasoned
  extensions, not commitments, and may be corrected without contradicting the source.

Mark every elaboration. An unmarked claim is read as a commitment.

## Sources

<!--
List the founding inputs this concept was synthesized from, by path. Inputs are raw human
material — they carry no IDs and no frontmatter, and are deliberately excluded from the product
documentation map. This section is their only index, so it is how traceability survives.
-->

| Input | Path | What it contributes |
|-------|------|---------------------|
| [Input name] | `doc/founding/inputs/[filename]` | [What this concept drew from it] |

## Vision

<!-- 2-4 sentences: what this product is, for whom, and what changes for them if it exists. -->

[Vision statement]

## Target Users

<!--
Name each distinct user group. Many products are two-sided (e.g. consumers + operators) —
if so, say so explicitly; downstream feature discovery will group around these groups.
-->

- **[User group]** — [who they are, what they need, what they do today instead]

## Core Value Proposition

<!-- Why would each target user group choose this over what they use now? -->

[Value proposition]

## Capability Areas

<!--
The broad areas of capability the product needs — NOT a feature list. Feature Discovery
(PF-TSK-013) derives features from this; do not pre-empt it with granular features here.
-->

- **[Capability area]** — [what it covers, and for which user group]

## Business Model Notes (if applicable)

<!--
Delete this section for products with no commercial model. Where the model lives in a founding
input (e.g. a pricing or retention-program document), summarize here and cite the source rather
than restating it in full.
-->

[Business model notes]

## Open Questions

<!--
Unresolved product-intent questions. These are DIFFERENT from technical explorations: an open
question here is "what should this product do?"; a question about feasibility or which
technology to use belongs in technical-exploration-tracking.md via New-Exploration.ps1
(PF-TSK-013's exploration-filing step), where PF-TSK-093 resolves it.
-->

| # | Question | Why it matters | Status |
|---|----------|----------------|--------|
| Q1 | [Question] | [What it blocks or changes] | Open |

## Related Resources

- [Feature Discovery (PF-TSK-013)](../../tasks/01-planning/feature-discovery-task.md) — the primary downstream consumer
- [Project Initiation (PF-TSK-059)](../../tasks/00-setup/project-initiation-task.md) — creates this document for greenfield projects
- [Retrospective Documentation Creation (PF-TSK-066)](../../tasks/00-setup/retrospective-documentation-creation.md) — captures into it for onboarded projects
- [Feature Landscape Template (PF-TEM-087)](../01-planning/feature-landscape-template.md) — the discovery-cycle rationale record derived from this concept
