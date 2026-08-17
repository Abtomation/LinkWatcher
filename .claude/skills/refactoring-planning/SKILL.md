---
name: refactoring-planning
description: >-
  Craft for customizing a Refactoring Plan (PF-RFP) well — the "how to fill it" half of the
  framework's Code Refactoring task (PF-TSK-022). Covers mode/template selection
  (standard / lightweight / documentation-only / performance), scope-discovery honesty (the scope
  delta), measurable baselines and goals, strategy and testing-section depth, and the
  workflow-aware and dimension-aware customization patterns. Activated only from the Code
  Refactoring task's Check-Recommended-Skills step (via recommended_skills); not the
  justification/effort-gate decision (that is the task's Effort Assessment Gate) and not an
  implementation or code-review skill.
user-invocable: false
---

# Refactoring Planning Craft

This skill owns the **craft** of customizing a Refactoring Plan — *how* to fill a PF-RFP document
so it drives systematic, behavior-preserving improvement. It is the customization-craft home for
the **Code Refactoring task (PF-TSK-022)**, which owns everything else: the Effort Assessment Gate
(justification + Lightweight/Standard classification), the path documents' step sequences,
checkpoints, bug discovery, state-file updates, and the feedback form.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** decide
> justification or effort classification from this skill — that is the task's Effort Assessment
> Gate checkpoint. This skill drives the plan-content customization inside whichever path
> (Lightweight or Standard) the gate selected.

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. The **task's path documents** create the plan with
`process-framework/scripts/file-creation/06-maintenance/New-RefactoringPlan.ps1` — always via the
script, never hand-authored, so the PF-RFP id and metadata are assigned correctly. Run
`Get-Help New-RefactoringPlan.ps1 -Parameter *` for the authoritative parameter list.

## Mode selection (which template you get)

The switch selects the template and the section set you customize:

| Mode (switch) | Template | Use for |
|---|---|---|
| _(default)_ Standard | `refactoring-plan-template.md` | Architectural impact or interface/API changes |
| `-Lightweight` | `lightweight-refactoring-plan-template.md` | No architectural/interface impact (any file count, any effort). Add `-IncludeDependencies` for multi-file changes; batch mode via `-ItemCount N`. Carries a per-item Documentation & State Updates checklist |
| `-DocumentationOnly` | `documentation-refactoring-plan-template.md` | Documentation-only refactoring (no code/test changes) — swaps code-metrics/test sections for a documentation-quality baseline + verification approach |
| `-Performance` | `performance-refactoring-plan-template.md` | Performance-focused — replaces code-quality metrics with user-defined performance baselines |

The mode follows the **chosen fix approach** the task's gate approved — pick the switch that
matches that classification, don't re-derive it here.

## Scope discovery: record the scope delta honestly

Compare the original tech-debt item description against what code analysis actually finds:

- Scope matches → write "None — scope matches original description" in Scope Delta.
- Scope differs → say what changed and why (e.g. the debt item described one method but the
  pattern exists in 3). This is calibration data for future assessments — don't silently widen or
  narrow the plan.

## Be specific and measurable

The load-bearing craft across every section: concrete numbers over adjectives.

- **Current Issues** — name specific files/methods with measurable indicators (cyclomatic
  complexity, duplication line counts, coverage %), and link the source debt item or review
  finding.
- **Refactoring Goals** — each goal gets a target the results section can verify (complexity 15 →
  under 8; eliminate the 3 duplicate validation paths), aligned with the system architecture.
- **Current State Analysis** — baseline metrics from real tool output, not estimates; list every
  affected component with its role, dependencies, and risk level.
- **Strategy** — name the techniques (Extract Method, Strategy pattern, …) chosen for the specific
  issues; break implementation into testable phases with rollback thinking.
- **Testing Strategy** — existing coverage, gaps to close before refactoring, incremental
  verification per phase, regression approach.

## Workflow-aware customization

Before finalizing the plan, check which user workflows the affected feature participates in
(`workflows:` metadata in the feature's implementation state file, or
`doc/state-tracking/permanent/user-workflow-tracking.md`). This sets:

- **Regression-testing scope** — a feature in many workflows needs broader regression coverage.
- **Co-participant awareness** — verify refactored interfaces stay compatible with features
  sharing the workflow.
- **E2E re-execution** — mark affected E2E test groups for re-execution in the plan's follow-ups.

## Dimension-aware customization

Check the **Dims** column of the source item in
`doc/state-tracking/permanent/technical-debt-tracking.md` and verify the plan improves along the
flagged dimension(s), using the
[Development Dimensions Guide](../../../process-framework/guides/framework/development-dimensions-guide.md)
implementation checklists: PE → complexity analysis or benchmarks; SE → validation/sanitization/
access-control improvements; DI → atomicity/recovery/consistency; CQ → readability/SOLID/complexity
reduction.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Plan sections feel generic / unverifiable | Goals written as adjectives, no baselines | Re-measure: pull real metrics for the baseline, restate each goal with a numeric target |
| Plan keeps growing during customization | Scope delta absorbed silently | Record the delta, then take the widened scope back through the task's gate rather than expanding the plan in place |

(Script path / module-resolution errors: see the
[Script Development Quick Reference](../../../process-framework/guides/support/script-development-quick-reference.md).)
