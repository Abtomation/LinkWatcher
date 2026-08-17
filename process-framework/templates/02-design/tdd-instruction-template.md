---
id: PF-TEM-108
type: Process Framework
category: Template
version: 1.1
created: 2026-08-04
updated: 2026-08-04
creates_document_category: Technical Design Document
creates_document_prefix: PD-TDD
creates_document_type: Product Documentation
creates_document_version: 1.0
description: Instruction-shaped terminal design document for a pure-instruction feature - the medium-aware sibling of the tier-forked tdd-t1/t2/t3 templates
template_for: TDD Instruction (terminal design document, instruction medium)
usage_context: Product Documentation - Technical Design Documents
documentation_mode: as-built
additional_fields:
  feature_id: "[FEATURE_ID]"
variant_group: tdd-templates
variant_siblings:
  - tdd-t1-template.md
  - tdd-t2-template.md
  - tdd-t3-template.md
---

# Technical Design Document (Instruction Medium): [Feature Name]

<!--
WHY THIS TEMPLATE EXISTS — read before editing or forking it.

The tdd-* family forks on TWO independent axes, and only two:

  * TIER   (t1 / t2 / t3) — how much design depth a CODE feature warrants.
  * MEDIUM (this file)    — what the deliverable is made of.

This file is the MEDIUM fork, and it is deliberately TIER-AGNOSTIC: an instruction feature's
terminal document scales by marking sections N/A, not by a t1/t2/t3 fork. Do not create
tdd-instruction-t1/t2/t3 — that would multiply the two axes into a six-template family, which
is exactly the variant-fork pressure PF-PRO-064 names as a standing risk.

WHEN THIS TEMPLATE IS USED (selected by New-TDD.ps1 -Medium):
  * -Medium instruction → this template. A pure-instruction feature must never receive the
    Models / Services / Repositories structure of the code TDD.
  * -Medium mixed       → the tier-appropriate CODE TDD (tdd-t{1,2,3}), whose Instruction
    Design Reference section points at the feature's PD-IND.
  * -Medium code        → the tier-appropriate code TDD, unchanged.

Medium is declared, never inferred, and NEVER stamped on an artifact: this document carries no
medium field of its own. It inherits the medium of the feature that owns it.
-->

## 1. Overview

### 1.1 Purpose

[Brief description of the feature and what its instructions accomplish]

### 1.2 Scope

[What is included and excluded from this design]

### 1.3 Related Features

[Related features and dependencies — including any feature that owns a shared artifact this one consumes]

### 1.4 Workflow Context

**Workflows**: [List WF-IDs from [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md), or "None" if this feature does not participate in any user workflow]

## 2. Requirements

### 2.1 Functional Requirements

[The functional requirements this instruction system delivers]

### 2.2 Quality Attribute Requirements

<!--
The code TDD's quality attributes (throughput, memory, RLS policies) mostly do not apply. These
are the instruction-medium analogues. Mark any that do not apply as N/A with a reason — an
unmarked attribute is an unresolved decision, not an omission.
-->

#### Determinism & Repeatability

- **Same inputs → same outcome**: [what must be reproducible across runs and across agents]
- **Tolerated variation**: [where the executing agent may legitimately differ]

#### Clarity & Unambiguity

- **Assumed knowledge**: [what the instruction assumes the executing agent already knows]
- **Ambiguity budget**: [which steps must be exact, and which are deliberately judgment-based]

#### Recoverability

- **Partial-completion behavior**: [what a half-finished run leaves behind]
- **Resumption**: [how a later run detects that state and continues]

#### Context Cost

- **Budget**: [how much the agent must read to execute this — the instruction analogue of resource usage]
- **Progressive disclosure**: [what is deferred to a consulted reference rather than carried on the happy path]

### 2.3 Constraints

[Constraints imposed by the executing agent, framework conventions, or artifacts this feature does not own]

## 3. Instruction Architecture

### 3.1 Artifact Map

<!--
The realized form of the Instruction Design's Artifact Inventory (§2 of the PD-IND). Where the
two disagree, the PD-IND is the design record and this is the as-built map — reconcile them
rather than letting them drift.
-->

| Artifact | Kind | Path | Role |
|----------|------|------|------|
| [file] | [Task / Guide / Template / Craft skill / Companion / Edge-case] | [`src/<feature>/...`] | [what it contributes] |

### 3.2 Entry Point & Invocation Surface

- **Entry point**: [the one independently-invocable entry point this feature owns]
- **Invoked by**: [user selection, slash command, chained from another entry point, status trigger]
- **Preconditions checked at entry**: [what the instruction verifies before doing any work]

### 3.3 Composition & Traversal

[How the artifacts reference each other: which are read on the happy path, which are consulted only on a stumble, and in what order. This is the instruction analogue of a component diagram.]

### 3.4 Delegation Boundaries

[What this feature deliberately does NOT own, and which artifact or feature owns it instead]

## 4. Detailed Design

<!-- One subsection per artifact in §3.1 that needs more than its map row. -->

### 4.1 [Artifact name]

- **Structure**: [sections/steps, and why they are ordered that way]
- **Judgment points**: [where the agent must decide rather than follow]
- **Failure behavior**: [what the artifact does when a precondition fails mid-run]

### 4.2 State & Side Effects

| File / tracker | Read | Written | Mutation shape |
|----------------|------|---------|----------------|
| [path] | [Yes/No] | [Yes/No] | [row append, status flip, file creation] |

- **Idempotency**: [is a second run safe, and what changes]
- **Concurrency**: [behavior when two agents run this simultaneously]

## 5. Cross-References

### 5.1 Functional Requirements Reference

> **📋 Primary Documentation**: FDD Creation Task (PF-TSK-027)
> **🔗 Link**: [Functional Design Document - PD-FDD-XXX] > **👤 Owner**: FDD Creation Task

**Brief Summary**: [which functional requirements this instruction system implements]

### 5.2 Instruction Design Reference

> **📋 Primary Documentation**: Instruction Design Task (PF-TSK-094)
> **🔗 Link**: [Instruction Design Document - PD-IND-XXX] > **👤 Owner**: Instruction Design Task

**Brief Summary**: [the design decisions this document realizes — especially the Artifact Inventory and its kind justifications]

### 5.3 Testing Reference

> **📋 Primary Documentation**: Test Specification Creation Task (PF-TSK-012)
> **🔗 Link**: [Test Specification Document - TE-TSP-XXX] > **👤 Owner**: Test Specification Creation Task

**Brief Summary**: [how the §6 verification plan is realized as tracked tests]

### 5.4 Code Interface Reference (remove if this feature invokes no code)

<!--
A pure-instruction feature may still INVOKE code owned elsewhere. Name that seam here; a
feature that SHIPS code of its own is `mixed` and belongs on the code TDD instead.
-->

**Brief Summary**: [scripts or services the instructions invoke, and the contract relied on]

## 6. Verification Design

<!--
Realizes the verification plan from the PD-IND (§6). Mark every level Applicable or N/A WITH A
REASON — these are the framework's instruction-verification levels, and an unmarked level is an
unresolved decision.
-->

| Level | Verifies | Applicability | How it is realized here |
|-------|----------|---------------|--------------------------|
| **1 · Static** | Links, IDs, frontmatter, generated maps | [Applicable / N/A] | [reused tooling] |
| **2 · Instruction contract** | That what an instruction *names* exists | [Applicable / N/A] | [which references are checked] |
| **3 · Execution** | Agent + instruction + fixture → asserted end state | [Applicable / N/A] | [fixture + assertions] |
| **4 · Judgment** | Whether a required judgment call was defensible | Designed only | [the judgment points from §4.1 are its inputs] |

### 6.1 Level 3 Fixture Realization (if applicable)

- **Fixture**: [the starting state the agent is handed]
- **Invocation**: [exactly how the instruction is run against it]
- **Assertions**: [the end-state facts checked]

## 7. Implementation Plan

### 7.1 Dependencies

[What must exist before authoring begins — shared artifacts, invoked scripts, upstream designs]

### 7.2 Authoring Order

[The order the artifacts are written in, and why — usually entry point first, consulted references last]

## 8. Open Questions

[Unresolved design questions, each with what would settle it]

## 9. AI Agent Session Handoff Notes

<!-- Context a future session needs in order to continue without re-deriving it. -->

- **Current state**: [what exists, what is stubbed, what is unstarted]
- **Decisions already made (do not re-litigate)**: [decision → where it is recorded]
- **Next concrete step**: [the single next action]

## 10. Appendix

### 10.1 References

[Links to related documents, external conventions, prior art]

### 10.2 Glossary

[Terms specific to this feature's domain]
