---
id: PF-FST-009
description: "Intake queue for technical exploration spikes — bounded research investigations that must resolve before dependent design or implementation can proceed."
type: Process Framework
category: State Tracking
version: 1.0
created: 2026-07-16
updated: 2026-07-16
---

# Technical Exploration Tracking

This file tracks technical exploration spikes — bounded research investigations that must resolve **before** a dependent feature can be designed or implemented. It serves as the intake queue for the [Technical Exploration](../../../process-framework/tasks/01-planning/technical-exploration-task.md) task (PF-TSK-093), which executes a queued spike, records its findings in a PD-TEC document, and resolves the row.

> **Scope**: An exploration is an **open question to answer before building** — evaluate a library, prototype a risky integration, benchmark an approach, confirm a platform capability. It is *not* deferred rework from a shortcut already taken; that belongs in [technical-debt-tracking.md](technical-debt-tracking.md). Framework (not product) research belongs in the central process-improvement tracking instead.

## Status Legend

| Status | Description |
|--------|-------------|
| 📥 Queued | Exploration filed and awaiting execution by Technical Exploration (PF-TSK-093) |
| 🔬 In Progress | Research underway — the linked findings doc carries the running log across sessions |
| ✅ Resolved | Findings documented and approved at checkpoint; dependent work is unblocked |
| ❌ Abandoned | No longer needed (question moot, feature dropped, or answered elsewhere) — see Notes |

## Active Explorations

| ID | Source | Description | Related Feature | Priority | Status | Findings Doc | Last Updated | Notes |
|----|--------|-------------|-----------------|----------|--------|--------------|--------------|-------|


## Resolved Explorations

<details>
<summary>Show resolved explorations (0 items)</summary>

<!-- Terminal rows (✅ Resolved / ❌ Abandoned) are moved here out of the active queue by
Update-Exploration.ps1. The Outcome column carries the terminal disposition, since this table
has no Status column. -->

| ID | Source | Description | Related Feature | Outcome | Findings Doc | Resolved Date | Notes |
|----|--------|-------------|-----------------|---------|--------------|---------------|-------|

</details>

## Column Reference

| Column | Table | Meaning |
|--------|-------|---------|
| ID | both | `PD-EXP-NNN`, assigned by `New-Exploration.ps1` from the PD ID registry |
| Source | both | The task or session that filed the exploration (e.g. Feature Discovery, PF-TSK-013) |
| Description | both | The research question to answer, stated so that "answered" is unambiguous |
| Related Feature | both | Feature ID this blocks, or `—` for a pre-feature / cross-cutting spike |
| Priority | Active | High / Medium / Low — scheduling input, driven by how soon the dependent work starts. Dropped on the terminal move |
| Status | Active | One of the four Status Legend values above. Terminal rows leave this table, so it only ever reads `📥 Queued` or `🔬 In Progress` in practice |
| Findings Doc | both | Link to the PD-TEC findings document in `doc/technical/explorations/` (`—` until research produces one) |
| Last Updated | Active | Date of the last status change or notes annotation. Dropped on the terminal move |
| Notes | both | Acceptance criteria, context, and the pipeline status a diverted feature returns to |
| Outcome | Resolved | The terminal disposition — `✅ Resolved` or `❌ Abandoned`. Exists because the Resolved table has no Status column |
| Resolved Date | Resolved | Date the row reached its terminal state |

> **Related Feature and the feature-tracking block**: when an exploration blocks an *existing* feature row, [Feature Request Evaluation](../../../process-framework/tasks/01-planning/feature-request-evaluation.md) (PF-TSK-067) also sets that feature to `🔬 Needs Technical Exploration` in [feature-tracking.md](feature-tracking.md), and the Technical Exploration task clears it back to the pipeline status on resolution. Pre-feature spikes never touch feature-tracking.

## Tasks That Update This File

The following tasks update this state file:

- **[Feature Discovery](../../../process-framework/tasks/01-planning/feature-discovery-task.md) (PF-TSK-013)**: files a `📥 Queued` row via `New-Exploration.ps1` when discovery surfaces a research question that blocks a candidate feature.
- **[Feature Request Evaluation](../../../process-framework/tasks/01-planning/feature-request-evaluation.md) (PF-TSK-067)**: files a `📥 Queued` row when a request cannot be classified or scoped until a research question resolves.
- **[Technical Exploration](../../../process-framework/tasks/01-planning/technical-exploration-task.md) (PF-TSK-093)**: advances `📥 Queued` → `🔬 In Progress` → `✅ Resolved` (or `❌ Abandoned`) via `Update-Exploration.ps1`, and links the findings doc.

## Update History

<details>
<summary>Show update history (0 entries)</summary>

| Date | Action | Updated By |
|------|--------|------------|

</details>
