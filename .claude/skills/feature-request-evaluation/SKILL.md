---
name: feature-request-evaluation
description: >-
  Craft for evaluating change requests well — the judgment half of the framework's Feature Request
  Evaluation task (PF-TSK-067). Two craft areas as references: complexity-tier assessment scoring
  (factor weights, normalized-score thresholds, the Implementation Medium determination with the
  instruction-feature granularity rule, the Design Requirements Evaluation UI/API/DB/Instruction
  criteria, reassessment triggers — references/tier-assessment.md, also consulted inline by the
  onboarding tasks' tier-assessment steps and the Documentation Tier Adjustment task) and
  Enhancement State Tracking File customization (header sections, the 17 workflow-block
  applicability decisions, session grouping — references/enhancement-scoping.md). Activated only
  from the Feature Request Evaluation task's Check-Recommended-Skills step (via
  recommended_skills); not a feature-design, implementation, or enhancement-execution skill.
user-invocable: false
---

# Feature Request Evaluation Craft

This skill owns the **craft** of evaluating a change request — *how to score a new feature's
complexity tier honestly and how to scope an enhancement into an executable state file*. It is the
judgment home for the **Feature Request Evaluation task (PF-TSK-067)**, which owns everything
else: classification checkpoints, tracking-file mutations via scripts, state-file creation, and
the feedback form.

Its [tier-assessment reference](references/tier-assessment.md) is also the scoring-criteria home
consulted inline by other tasks that run tier assessments: the onboarding tasks (Codebase Feature
Discovery's tier-assessment step; Retrospective Documentation Creation) and the Documentation Tier
Adjustment task's reassessment procedure.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** run checkpoints,
> create documents, or update tracking files from this skill — those stay in the task. This skill
> drives the scoring and scoping judgment between the task's checkpoints.

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. The **task** creates artifacts via
`process-framework/scripts/file-creation/01-planning/New-Assessment.ps1` (the PD-ASS assessment
document — always via script, never hand-authored) and
`process-framework/scripts/file-creation/04-implementation/New-EnhancementState.ps1` (the
Enhancement State Tracking File whose customization this craft drives).

## Reference index (load per task path)

- **New-feature path — tier assessment**: load
  [references/tier-assessment.md](references/tier-assessment.md) when scoring complexity factors,
  determining the Implementation Medium, and completing the Design Requirements Evaluation
  (UI / API / DB / Instruction). Also holds the reassessment-trigger indicators consulted when
  implementation complexity diverges from the initial assessment.
- **Enhancement path — state-file customization**: load
  [references/enhancement-scoping.md](references/enhancement-scoping.md) when customizing the
  generated Enhancement State Tracking File — header sections, the 17 workflow-block
  Applicable/Not-Applicable decisions, and session-boundary planning.

## Classification judgment (before either path)

The feature-vs-enhancement-vs-reject call itself stays with the task's classification steps and
the agnostic
[Feature Granularity Guide](../../../process-framework/guides/01-planning/feature-granularity-guide.md)
(its three validation tests). One craft signal worth carrying into the enhancement path: an
"enhancement" whose scoping ends up marking most workflow blocks applicable across 3+ sessions is
usually a misclassified new feature — take it back to the classification checkpoint rather than
stretching the state file (see the enhancement-scoping reference's troubleshooting).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Tier feels wrong despite the score | Special considerations ignored (risk, unfamiliar domain, core infrastructure, compliance) | Apply the special-considerations list in the tier-assessment reference — they may justify a tier above the raw score |
| Enhancement state file useless to the executing task | Placeholders left, blocks unevaluated | Every block needs Applicable + Rationale filled; scan for remaining `[bracketed placeholders]` before the task's finalization checkpoint |

(Script path / module-resolution errors: see the
[Script Development Quick Reference](../../../process-framework/guides/support/script-development-quick-reference.md).)
