---
name: feature-implementation-planning
description: >-
  Craft for initializing and maintaining a Feature Implementation State file well — the "how to
  fill it" half of the framework's Feature Implementation Planning task (PF-TSK-044). Covers the
  two-planning-task section-ownership boundary (Feature Request Evaluation creates and seeds the
  file; this task initializes it), template-variant awareness (full vs. lightweight), and
  section-by-section initialization judgment (Feature Overview, Dimension Profile, Code
  Inventory's three directions, Documentation Inventory); references hold the living-document
  maintenance craft (consumed inline by the decomposed implementation tasks), the bidirectional
  feature-marker standard, and the onboarding/retrospective sections (consumed inline by the
  onboarding tasks). Activated from the Feature Implementation Planning task's
  Check-Recommended-Skills step (via recommended_skills); not an implementation-plan-sequencing,
  design, or coding skill.
user-invocable: false
---

# Feature Implementation Planning Craft

This skill owns the **craft** of initializing and maintaining a **Feature Implementation State
file** — the permanent living document that tracks a feature through its entire lifecycle. It is
the craft home for the **Feature Implementation Planning task (PF-TSK-044)**, which owns
everything else: design-document review, the implementation roadmap and dependency mapping, the
Implementation Plan document, checkpoints, feature-tracking updates, and the feedback form.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** run task
> sequencing, effort estimation, or risk assessment from this skill — those are the task's
> roadmap steps. This skill drives *how to fill the state file well* at the task's
> initialization step, and its references are also consumed inline (no binding) by the
> decomposed implementation tasks, Code Review, and the onboarding tasks when they maintain or
> populate the same file.

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. The state file is created earlier — at Feature Request
Evaluation — by `process-framework/scripts/file-creation/04-implementation/New-FeatureImplementationState.ps1`
(never hand-authored; `-Lightweight` selects the tier-1 variant, `-Workflows "WF-001, WF-003"`
sets the workflows frontmatter at creation). Onboarding quality scoring is computed by
`process-framework/scripts/update/Update-QualityClassification.ps1` (see the onboarding
reference). Run `Get-Help <script> -Parameter *` for the authoritative parameter list.

## The two-planning-task ownership boundary

Two tasks touch the state file before implementation — don't conflate them:

- **Feature Request Evaluation (PF-TSK-067)** *creates* the file (via
  `New-FeatureImplementationState.ps1`) and, if the evaluation surfaced material design
  discussion, seeds design context — settled choices in §Design Decisions, open threads under
  §Next Steps. It does **not** populate Feature Overview, Dependencies, or Dimension Profile.
- **Feature Implementation Planning (PF-TSK-044)** *initializes the planning content* of the
  already-existing file: §Feature Overview, §Implementation Progress, §Dependencies,
  §Dimension Profile, §Documentation Inventory.

So at planning time: **locate** the file at `doc/state-tracking/features/[feature-id]-implementation-state.md`
and confirm its identity — never create a second one.

## Template variants

The tier assessed at evaluation selected the variant; initialize the sections that variant has:

| Variant | Template | Sections | Use |
|---|---|---|---|
| Full | `feature-implementation-state-template.md` (PF-TEM-037) | 10 | Tier 2/3 features |
| Lightweight | `feature-implementation-state-lightweight-template.md` (PF-TEM-068) | 7 | Tier 1 features and retrospective analysis |

The lightweight variant omits Implementation Progress and Dimension Profile and merges Issues &
Resolutions + Next Steps into a compact Notes & Next Steps section.

Instances are **never archived** — the permanent-record policy is stated in the template headers;
finalization sets status `COMPLETE` in place.

## Section-by-section initialization judgment

- **Metadata**: status walks `PLANNING → IN_PROGRESS → TESTING → COMPLETE → DEPLOYED →
  MAINTAINED`; `workflows:` lists the WF-IDs the feature participates in (from user-workflow
  tracking; `workflows: []` when none) so downstream tasks can judge blast radius without the
  central file.
- **Feature Overview** — the one section that stays *stable* through implementation, so complete
  it thoroughly now: 2–3 paragraphs of what/why/fit, business value as user need + business goal
  + success metrics, and an explicit **Out of Scope** list (deferrals included). Test: a reader
  understands purpose, value, and boundaries without external documents.
- **Current State Summary**: status `PLANNING`, completion 0%, planning activities under "In
  Progress". Keep this section high-level always — 3–5 items per subsection.
- **Implementation Progress**: copy the phase sequence from the implementation plan; each
  decomposed task gets its own registry-assigned task ID; mark planning `[⚙]`, the rest `[ ]`,
  with per-task dependencies.
- **Dimension Profile**: record the task's dimension-applicability evaluation — two tables,
  Applicable (with **Critical**/**Relevant** level and key considerations) and Not Applicable
  (with rationale). This is the *single source of truth* consumed downstream: implementation
  tasks focus on Critical dimensions, Code Review prioritizes by it, Validation Preparation
  selects from it. Update it if implementation proves an evaluation wrong.
- **Documentation Inventory**: link every design document and the sections relevant per phase.
  For onboarding/retrospective files, also populate the Existing Project Documentation
  subsection — see [references/onboarding-sections.md](references/onboarding-sections.md).
- **Code Inventory** — three subsections with *opposite directions*; do not confuse them:
  (a) **files this feature imports** (direct dependencies — what my code needs),
  (b) **files that depend on this feature** (reverse dependencies — who imports me; impact
  analysis), (c) **files created/modified by this feature** (ownership footprint). One row per
  file; key components, not every function.
- **Design Decisions**: rationale over description — options considered, decision, why,
  implications, validation criteria. Check whether evaluation-seeded entries already exist
  before adding.
- **Next Steps**: name the concrete decomposed implementation task to run next — specific enough
  that the next session starts without archaeology.

## References

| Reference | Load when |
|---|---|
| [living-document-maintenance.md](references/living-document-maintenance.md) | Maintaining the file during/after implementation — update cadence, session start/end patterns, finalization, troubleshooting. Consumed inline by the decomposed implementation tasks, Implementation Finalization, and Code Review. |
| [bidirectional-markers.md](references/bidirectional-markers.md) | Creating or modifying code — the feature-marker formats that keep code and Code Inventory traceable both ways. |
| [onboarding-sections.md](references/onboarding-sections.md) | Onboarding/retrospective state files — Existing Project Documentation lifecycle and the Quality Assessment scoring. Consumed inline by Codebase Feature Discovery, Codebase Feature Analysis, and Retrospective Documentation Creation. |
