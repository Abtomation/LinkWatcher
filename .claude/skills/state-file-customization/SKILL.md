---
name: state-file-customization
description: >-
  Craft for customizing state tracking files well — both classes: permanent state files
  created with New-PermanentState.ps1 (provenance/pool selection — framework-shipped PF-FST
  via -Shipped vs. project-created PD-STA/PF-STA — status-legend tailoring, column-structure
  selection, granularity/semantics/ownership decisions, mutation script support) and temporary multi-session state files created
  with New-TempTaskState.ps1 or New-StructureChangeState.ps1 (template-variant selection
  across the task-creation / structure-change / process-improvement / framework-extension /
  framework-evaluation / refactoring / retrospective-documentation variants, phase
  customization, session planning). Activated from the New Task Creation task's
  Check-Recommended-Skills step (via recommended_skills); also consulted inline by any task
  or session that runs one of the three state-file creation scripts — their success output
  points here. Not a state-file *update* skill (each tracker's own update scripts and owning
  tasks govern that) and not a template-development skill.
user-invocable: false
---

# State File Customization Craft

This skill owns the **craft** of turning a freshly scaffolded state tracking file into a
functional tracker — legend, columns, phases, and session plan tailored to the tracked
domain. The **creating task** owns everything else: when a tracker is needed, checkpoints,
archival, and completion. Primary host: **New Task Creation (PF-TSK-001)** (its
customize-temp-state-file step). Any task that runs `New-PermanentState.ps1`,
`New-TempTaskState.ps1`, or `New-StructureChangeState.ps1` consults this craft inline at
that moment — e.g. Framework Extension's and Structure Change's state-file creation steps.

> **Division of labor.** The task owns process; this skill owns customization judgment.
> 🚨 Always scaffold with the creation scripts
> (`process-framework/scripts/file-creation/support/New-PermanentState.ps1` /
> `New-TempTaskState.ps1` / `New-StructureChangeState.ps1`) — never hand-create a tracked
> state file — so IDs and base structure are assigned correctly.

## Permanent state files

Permanent state files track the ongoing status of a component, process, or work-item
category throughout its lifecycle — the source of truth a task reads to decide its next
action. Before creating one, review the existing files in `doc/state-tracking/permanent` to
avoid duplicating a tracker.

### Which pool the tracker draws from (decide before scaffolding)

This picks the creation mode, so settle it first:

| The tracker is… | Prefix | How to create |
|---|---|---|
| **Framework-shipped** — it lives in the blueprint and exists in every child from initiation (feature / feature-request / bug / technical-debt / architecture / user-workflow tracking, and their archives) | `<FAMILY>-FST` | `New-PermanentState.ps1 -Shipped` — **producer faces only**; writes into `blueprint/doc/state-tracking/permanent/` and allocates from the portable pool |
| **Created during project work** — the project's own tracker (validation-round tracking, temp task state) | `PD-STA` / `PF-STA` | `New-PermanentState.ps1` (default; routed by `Get-StateTrackingContext`) |

The deciding axis is **provenance, not content**. A shipped tracker's *rows* hold product data,
but the *file* is a framework fixture — schema and identity owned by the framework — so its id
must come from the framework's portable pool, where it is allocated once and is identical in
every project. It cannot come from `PD-STA`: each project grows that pool independently, so the
framework has no collision-free `PD-STA` number to hand a newly shipped tracker (PF-IMP-1492 —
a real collision: PRJ-001 had already consumed the next blueprint `PD-STA` number).

> **The `FST` family varies by workspace** (PF-PRO-068 P-12a): `-Shipped` mints
> `$(Get-ArtifactPrefix)-FST` — `PF-FST` at appdev, `FB-FST` at FrameworkBuilder — so a producer
> face declares the pool its own children will resolve. `-Shipped` refuses at a leaf, and refuses
> at a producer face that has not declared **both** halves of the contract: the `<FAMILY>-FST` pool
> in its framework ID registry, and `blueprint/doc/state-tracking/permanent/` to write into.
> Don't confuse `FST` with `SST` — the registry descriptions lead with the discriminator
> (copies × location × who may mint) for exactly that reason.

Two further areas need real tailoring:

### Status legend (primary customization)

Define every status value an entry can hold, reflecting the domain's natural workflow
progression plus terminal states (Completed, Rejected, Deferred) and any blocked/error state
the domain needs. Reuse an established legend where it fits:

| Domain | Status values |
|---|---|
| Feature implementation | Needs Assessment → Needs FDD → Needs TDD → Needs Test Spec → Needs Impl Plan → In Progress → Needs Review → Completed |
| Technical debt | Identified → Prioritized → In Progress → Resolved → Deferred |
| Process improvement | Identified → Prioritized → In Progress → Completed → Rejected |
| Generic component / integration | Not Started → In Progress → Testing → Complete → Blocked (add Deprecated / Failed / Deferred as needed) |

### Column structure

Standard columns are **ID · Name · Status · Last Updated · Notes**. Add a domain column only
when it drives a decision: Priority (scheduling), Category (filtering), Effort (resource
planning), Dependencies (cross-item coordination), Owner (responsibility), Target Date
(deadlines), Risk Level (risk assessment). Use a consistent entry-ID convention (e.g.
`API-001`, `COMP-001`).

### Customization decisions

- **Granularity** — milestones only (low maintenance) vs. sub-components and intermediate
  states (more coordination value); balance detail against update overhead.
- **Status semantics** — workflow-based, state-based (Active / Inactive / Deprecated), or
  priority-tiered.
- **Integration** — standalone, cross-referenced to related state files, or hierarchical.
- **Update ownership** — document which tasks update the file in a **Tasks That Update This
  File** section (when, and with what information). Clear ownership is what keeps the file
  current; an unmaintained state file is worse than none.
- **Mutation script support** — rows are script-written: the scripts-write-tables convention
  has no manual-edit exception, even for a low-integrity, approximate-by-design tracker
  (PF-IMP-1890). If no existing update script covers the tracker's mutations, script support
  for them is part of the new tracker's deliverable — design the operations (add / promote /
  remove / sweep, as the domain needs) alongside the columns, not as a follow-up.

Worked examples of customized legends and columns: `doc/state-tracking/permanent/feature-tracking.md`
and `technical-debt-tracking.md` in any framework project; the central
`process-improvement-tracking.md` for a cross-project tracker.

## Temporary (multi-session) state files

Pick the template variant by workflow type, then customize phases and session plan — the
full selection guide, phase patterns, and planning strategies are in
[references/temp-state-customization.md](references/temp-state-customization.md). Quick map:

| Workflow | Script / variant |
|---|---|
| Task creation (new artifacts) | `New-TempTaskState.ps1` (default variant) |
| Process improvement | `New-TempTaskState.ps1 -Variant ProcessImprovement` |
| Framework extension (multi-artifact) | `New-TempTaskState.ps1 -Variant FrameworkExtension` |
| Framework evaluation (multi-session) | `New-TempTaskState.ps1 -Variant FrameworkEvaluation` |
| Code refactoring (Standard Path) | `New-TempTaskState.ps1 -Variant Refactoring` |
| Retrospective documentation (per-feature) | `New-TempTaskState.ps1 -Variant RetrospectiveDocumentation` |
| Structure change (incl. rename / content-update / framework-extension / from-proposal shapes) | `New-StructureChangeState.ps1` (`-ChangeType` / `-FromProposal`) |

## Reference index

- [references/temp-state-customization.md](references/temp-state-customization.md) — the
  temporary-state craft in full: per-variant selection criteria and characteristics,
  `-FromProposal` compatibility rules, phase customization patterns, session planning
  strategies, integration best practices, and common pitfalls. Load when creating or
  customizing any temporary state file.
