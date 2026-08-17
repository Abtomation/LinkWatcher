---
name: fdd-creation
description: >-
  Craft for customizing a Functional Design Document (PD-FDD) well — the "how to fill it" half of
  the framework's FDD Creation task (PF-TSK-027). Covers the Feature-ID requirement-prefix
  convention (FR/UI/BR/AC/EC), requirement granularity and flow-detail decisions, edge-case
  coverage, workflow participation, and the functional-vs-technical separation of concerns.
  Activated only from the FDD Creation task's Check-Recommended-Skills step (via
  recommended_skills); not a technical-design, API-design, or implementation skill.
user-invocable: false
---

# FDD Creation Craft

This skill owns the **craft** of customizing a Functional Design Document — *how* to fill a PD-FDD
document well. It is the customization-craft home for the **FDD Creation task (PF-TSK-027)**, which
owns everything else: task selection, role, checkpoints, document creation via script, state-file
updates, and the feedback form.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** run checkpoints,
> create the document, or write state from this skill — those stay in the task. This skill drives
> the requirement authoring between the task's Execution checkpoints.

An FDD captures **what** a feature does from the user's perspective, not **how** it's built —
that's the line to hold while customizing. Requirements read as implementation? Ask "what does the
user experience?", not "how does the system work?".

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. The **task** creates the document with
`process-framework/scripts/file-creation/02-design/New-FDD.ps1` (which also advances feature
tracking and inserts the §4 Documentation Inventory row); this skill never hand-authors the shell.
Never ship an uncustomized FDD template — it is scaffolding only.

## The one convention you can't guess: Feature-ID requirement prefixes

Every requirement is prefixed with the feature's ID (dots → dashes) plus a type code and number, so
requirements never collide across features. For Feature ID `1.1.1`:

| Type | Code | Example |
|---|---|---|
| Functional requirement (what the system does) | `FR` | `1-1-1-FR-1`: System validates email format during registration |
| User interaction | `UI` | `1-1-1-UI-1`: User enters email, password, confirm-password |
| Business rule (validation / constraint) | `BR` | `1-1-1-BR-1`: Password ≥ 8 chars, 1 number + 1 special |
| Acceptance criterion (testable) | `AC` | `1-1-1-AC-2`: System rejects an invalid email format |
| Edge case / error handling | `EC` | `1-1-1-EC-1`: Email already exists → "Email already registered" |

Acceptance criteria trace back to the FR/UI/BR they verify; keep the prefix identical across all of
a feature's requirements. Make acceptance criteria measurable with clear pass/fail conditions
("loads within 3 s"), never vague ("user-friendly", "fast").

## Customization decision points

- **Requirement granularity** — 3–5 core requirements for a simple feature; 10+ across FR/UI/BR for
  complex ones. Start with the core set and expand.
- **User-experience-flow detail** — a linear step list for simple features; multiple paths +
  decision points + alternative flows for complex ones.
- **Edge-case coverage** — at minimum critical error scenarios + data validation; comprehensive
  exception paths for high-risk / high-impact features.

For the **Workflow Participation** table (the task's workflow-participation step): consult
`doc/state-tracking/permanent/user-workflow-tracking.md` and state this feature's role in each
workflow it joins (note any new workflow it enables).

## Separation of concerns

FDDs own functional-level concerns only — user stories, functional requirements, business rules,
user workflows, acceptance criteria, user-facing edge cases. Reference (don't duplicate): API
contracts → API Specification (PF-TSK-020); database schema → Database Schema Design (PF-TSK-021);
implementation / architecture → TDD; test cases → Test Specification. Keep functional requirements
in user-visible language — no technical jargon. Canonical ownership rules and the cross-reference
format live in the
[Information Flow Guide — FDD Creation Task](../../../process-framework/guides/framework/information-flow-guide.md#fdd-creation-task-pf-tsk-027).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Requirements read as implementation | "What" vs "how" confused | Describe user-visible behavior; ask "what does the user experience?" |
| Acceptance criteria not testable | Vague language ("user-friendly", "fast") | Use measurable conditions ("loads within 3 s") with clear pass/fail |
| Prefix inconsistency | Manual typos / dots not converted | Use `[feature-id]-[type]-[n]` with dots → dashes; same feature-ID prefix throughout |
