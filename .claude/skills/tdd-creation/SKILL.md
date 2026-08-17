---
name: tdd-creation
description: >-
  Craft for customizing a Technical Design Document (PD-TDD) well — the "how to fill it" half of
  the framework's TDD Creation task (PF-TSK-015). Covers tier selection (T1/T2/T3) and the
  structural differences between tier templates, dimension-informed quality-attribute depth (D10),
  workflow context, session-handoff notes, and the implementation-vs-functional separation of
  concerns. Activated only from the TDD Creation task's Check-Recommended-Skills step (via
  recommended_skills); not a functional-design, API-design, or coding skill.
user-invocable: false
---

# TDD Creation Craft

This skill owns the **craft** of customizing a Technical Design Document — *how* to fill a PD-TDD
document well at the tier-appropriate depth. It is the customization-craft home for the **TDD
Creation task (PF-TSK-015)**, which owns everything else: task selection, role, checkpoints,
quality-attribute analysis steps, document creation via script, state-file updates, and the
feedback form.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** run checkpoints,
> create the document, or write state from this skill — those stay in the task. This skill drives
> the content customization between the task's checkpoints.

A TDD is both the architectural blueprint and the session-handoff record — fill every section with
both readers in mind.

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. The **task** creates the document with
`process-framework/scripts/file-creation/02-design/New-TDD.ps1` — always via the script, so you get
the tier-correct template and a valid PD-TDD id. `-Tier` selects the template; take it from the
tier assessment, not by feel.

## Two selection axes: tier and medium

Template selection forks on **two independent axes**, and both come from the feature's tier
assessment — never from feel:

| Axis | Parameter | Question it answers |
|---|---|---|
| **Tier** | `-Tier 1\|2\|3` | How much design depth does this *code* feature warrant? |
| **Medium** | `-Medium code\|mixed\|instruction` | What is the deliverable made of? |

- **`code`** (default) and **`mixed`** → the tier-appropriate code TDD (`tdd-t{1,2,3}`). A mixed
  feature keeps the code TDD *by design*; its instruction half is carried by the template's
  **Instruction Design Reference** section, which you fill with a pointer to the feature's
  `PD-IND` document.
- **`instruction`** → `tdd-instruction-template.md`, the **tier-agnostic** instruction terminal.
  A pure-instruction feature must never receive the Models / Services / Repositories structure of
  the code TDD. Scale it by marking sections N/A **with a reason**, never by forking a per-tier
  instruction template.

Read the medium from the assessment's `## Implementation Medium` section, or the `**Medium**`
scalar in the feature's implementation state file §2 — it is declared, never inferred, and never
recorded on the document you are creating. Omitting `-Medium` silently means `code`, so a
pure-instruction feature whose flag you forget lands back on the code TDD — the exact defect the
parameter exists to prevent.

## Tier selection & structural differences

*(Applies to the code TDD. Under `-Medium instruction` the tier still classifies the feature and
still appears in the filename, but it no longer selects the template.)*

| Tier | Use when | Template adds (over the lighter tier) |
|---|---|---|
| **T1** (`tdd-t1-template.md`) | Simple feature, minimal architectural impact, single dev, < 1 week | Overview, single user story, 3–5 requirements, implementation approach (UI/Logic/Data), handoff notes |
| **T2** (`tdd-t2-template.md`) | Moderate feature, some architectural decisions, 1–4 weeks | + Design (data models, components, business logic, API contracts), phased Implementation Plan, Testing Strategy, Deployment Considerations |
| **T3** (`tdd-t3-template.md`) | Complex feature, system-wide impact, multi-dev, > 4 weeks | + Architecture (component diagrams, data flow, state mgmt), Detailed Design, Security, Performance, Deployment Strategy, Monitoring/Observability |

All tiers carry **AI Agent Session Handoff Notes** — current state, key decisions, next steps,
blockers (T2/T3 add architectural context + integration points). Detail in every section scales the
same way: T1 = key decisions only, T2 = decisions + rationale, T3 = full specifications. If handoff
notes feel too thin for a clean transition, record the architectural decisions made, concrete next
steps with priorities, and blockers plus the files/resources to continue from.

## Dimension-informed quality attribute depth (D10)

When the feature has a **Dimension Profile** (from Feature Implementation Planning), use it to set
the depth of each quality-attribute subsection — this drives the task's dimension-informed depth
step. Principle: **a Critical dimension gets one tier higher depth** than the feature's base tier.

| Base Tier | N/A Dimension | Relevant Dimension | Critical Dimension |
|-----------|--------------|-------------------|-------------------|
| Tier 1 | Omit subsection | Tier 1 depth (brief note) | **Tier 2 depth** (requirements + approach) |
| Tier 2 | Omit subsection | Tier 2 depth (standard) | **Tier 3 depth** (comprehensive + measurement) |
| Tier 3 | Omit subsection | Tier 3 depth (standard) | Tier 3 depth (already maximum) |

**Dimension → TDD quality attribute subsection:**

| Dimension | TDD Subsection |
|-----------|---------------|
| SE (Security) | Security Design — threat model, input validation, auth, secrets |
| PE (Performance) | Performance Design — complexity targets, I/O strategy, resource budgets |
| DI (Data Integrity) | Data Integrity Design — atomicity, consistency, error recovery, backup |
| OB (Observability) | Observability Design — logging strategy, error tracing, monitoring hooks |
| UX (Accessibility) | Accessibility Design — standards compliance, keyboard nav, screen reader |
| EM (Extensibility) | Extensibility Design — plugin points, configuration, upgrade paths |
| AC, ID | Usually covered in the main TDD body (component design, interfaces) |
| CQ | Usually referenced, not detailed in the TDD |
| DA | N/A — DA is about documentation itself |

See the
[Development Dimensions Guide](../../../process-framework/guides/framework/development-dimensions-guide.md)
for dimension definitions.

## Workflow context

Populate the Workflow Context field from the feature's FDD "Workflow Participation" section, or
look up `doc/state-tracking/permanent/user-workflow-tracking.md` directly. List the WF-IDs
(e.g. `WF-001, WF-002`), or "None".

## Separation of concerns

TDDs own implementation-level concerns — component architecture, design patterns, service /
state-management implementation, algorithms, technical integration. Reference (don't duplicate):
functional requirements → FDD; API contracts → API Specification; database schema → Database Schema
Design; detailed test plans → Test Specification. Canonical ownership rules and the cross-reference
format live in the
[Information Flow Guide — TDD Creation Task](../../../process-framework/guides/framework/information-flow-guide.md#tdd-creation-task-pf-tsk-015).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Template doesn't fit the feature's complexity | Wrong `-Tier`, or stale tier assessment | Re-confirm the tier assessment; recreate with the correct `-Tier` (re-assess first if the assessment is outdated) |
| Handoff notes too thin for a clean transition | Current state / decisions / next steps under-documented | Record decisions made, concrete next steps with priorities, and blockers + the files/resources to continue from |

(Script path / module-resolution errors: see the
[Script Development Quick Reference](../../../process-framework/guides/support/script-development-quick-reference.md).)
