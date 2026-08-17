---
name: integration-narrative
description: >-
  Craft for customizing an Integration Narrative (PD-INT) well — the "how to fill it" half of the
  framework's Integration Narrative Creation task (PF-TSK-083). Covers workflow scoping, diagram
  detail level, the source-code-verification discipline (verify against code, not TDDs), authoring
  the Component Interaction Diagram and Data Flow Sequence, and the completeness self-check.
  Activated only from the Integration Narrative Creation task's Check-Recommended-Skills step (via
  recommended_skills); not a TDD-authoring, E2E-testing, or feature-design skill.
user-invocable: false
---

# Integration Narrative Craft

This skill owns the **craft** of customizing an Integration Narrative — *how* to fill a PD-INT
document well. It is the customization-craft home for the **Integration Narrative Creation task
(PF-TSK-083)**, which owns everything else: task selection, role, checkpoints, source-code reading
steps, document creation via script, divergence filing, state-file updates, and the feedback form.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** run checkpoints,
> create the document, or write state from this skill — those stay in the task. This skill drives
> the narrative customization at the task's customize-the-narrative step.

> **🚨 CRITICAL — verify against source, not TDDs**: every cross-feature interaction in the
> narrative MUST be confirmed against actual source code. TDDs drift; the narrative records what
> the code *does*. Where code and TDD disagree, document the code and file the divergence via the
> task's tech-debt reporting step (`process-framework/scripts/update/Update-TechDebt.ps1`).

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. The **task** creates the document with
`process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1` (which assigns the
PD-INT ID and sets the workflow's Integration Doc column); this skill guides filling the structure
it writes.

## Customization decision points

- **Workflow scope** — one narrative = one complete workflow, trigger → outcome. Match scope to a
  single row in `doc/state-tracking/permanent/user-workflow-tracking.md`. Split clearly-independent
  sub-pipelines; consider combining workflows that share significant components.
- **Diagram detail level** — show only components that interact **across** feature boundaries —
  omit purely internal ones (those belong in TDDs). Include a data store only if multiple features
  read/write it. Target 5–15 components; beyond 15, split the diagram.

## Filling the template

Complete sections in template order — each builds on the last: Workflow Overview → Participating
Features → Component Interaction Diagram → Data Flow Sequence → (Callback/Event Chains,
Configuration Propagation, Error Handling). Conditional sections get real content **or** an
explicit "not applicable" statement — never left as placeholders.

The two sections that carry the value:

- **Component Interaction Diagram** — list the source files implementing each cross-feature
  interaction point; draw with the
  [Visual Notation Guide](../../../process-framework/guides/support/visual-notation-guide.md)
  symbols (`([logic])`, `[(store)]`, `[/file/]`), label every edge with what crosses it (data type,
  event name, callback signature), and **verify each connection exists in the actual source**
  (call, import, instantiation).
- **Data Flow Sequence** — the most important section. Trace the data entry → exit through every
  feature boundary. For each step name the **specific function/method**
  (`MoveDetector.process_event()`, not "MoveDetector"), the input structure, what it does, and the
  output structure passed on. Verify each step by reading the code.

**Self-check** — a complete narrative lets a reader trace an event entry → exit, know which
component to investigate for a cross-feature bug, see which config affects the workflow, and know
what happens when a mid-pipeline component fails. If any of those still needs 3+ other documents,
add detail.

## Example — a Data Flow Sequence step

Source (`src/linkwatcher/handler.py`):
```python
def on_moved(self, event):
    self.service.handle_move(event.src_path, event.dest_path)
```
Narrative step:
> 2. **EventHandler.on_moved()** receives `FileMovedEvent(src_path, dest_path)` — extracts old/new
> paths from the watchdog event and passes to `LinkWatcherService.handle_move(old_path, new_path)`.

For a conditional section with no applicable mechanism, state it plainly rather than deleting the
heading — e.g. *"This workflow uses direct function calls; no callback/event chains are used."*

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Diagram has 20+ components | Internal (non-boundary) components included | Keep only components that sit at a feature boundary |
| TDD and code disagree on a data type | Code evolved after the TDD | Document the code's behavior; report the divergence via `Update-TechDebt.ps1` |
| Following the flow leads into another workflow | Boundaries unclear in tracking | A workflow ends when its primary objective is achieved; note (don't follow) secondary effects. Confirm scope with the human partner |
