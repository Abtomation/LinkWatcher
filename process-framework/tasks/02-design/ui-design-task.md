---
id: PF-TSK-090
type: Process Framework
category: Task Definition
version: 1.3
created: 2026-05-27
updated: 2026-08-04
description: "Systematic UI/UX design planning before implementation: translate functional requirements into wireframes, visual specifications, component definitions, accessibility requirements, and platform adaptations as a PD-UIX design document."
complexity: medium
use_when: >-
  Create UI/UX design specifications: wireframes, visual specs, component definitions, accessibility requirements, platform adaptations as a PD-UIX design document. Triggers: 'create UI design', 'design the UI for feature X', 'spec the screens'.
triggers:
  - "create UI design"
  - "design the UI for feature X"
  - "spec the screens"
automation: full
scripts:
  - ../../scripts/file-creation/02-design/New-UIDesign.ps1
trigger_status:
  - raw: "Triggered by feature-tracking Status `🎨 Needs UI Design` — the design-chain gate ordered after API and before Instruction Design (PF-IMP-1352 / PF-PRO-064, per `AssessmentParsing.psm1`). Also invoked by: human-partner request; tier-assessment narrative recommending UI Design; FDD review surfacing UI complexity; PF-TSK-066 Retrospective Documentation Creation backfilling UI Design for existing features."
output_status:
  - raw: "`feature-tracking.md` → next design gate (`📜 Needs Instruction Design` when the feature has an instruction dimension, else `📝 Needs TDD` for Tier 2+, or `🔧 Needs Impl Plan`), advancing past the UI gate (PF-IMP-1352); per-feature state file §4 Documentation Inventory → UI Design row (the creation is also recorded in the Notes column); PD-documentation-map.md → reflected on `-Tree PD` regeneration"
---

# UI Design

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

**🤖 AUTOMATION NOTE**: This task is **FULLY AUTOMATED** by [New-UIDesign.ps1](../../scripts/file-creation/02-design/New-UIDesign.ps1) (via the shared `Invoke-DesignArtifactCreation` core). The script generates the UI Design document (with a `description:` frontmatter line), sets the feature's Status to the next design gate (`📜 Needs Instruction Design` / `📝 Needs TDD` / `🔧 Needs Impl Plan`), and inserts a UI Design row into the per-feature state file's §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760). The PD documentation map is **generated** (`Build-DocumentationMap.ps1 -Tree PD`, PF-PRO-050) — it picks up the new document's `description:` on regeneration; the script no longer appends to it.

## Purpose & Context

Systematic UI/UX design planning before implementation. Translates functional requirements into concrete visual and interaction designs — wireframes, visual specifications, component definitions, accessibility requirements, responsive behavior, and platform adaptations — captured as a PD-UIX design document for handoff to TDD and implementation.

**Scope**: This task owns **design-document concerns**: wireframes, visual specs, component specs, accessibility requirements, responsive design, platform adaptations, motion. UI code implementation, state management plumbing, API endpoint design, and database schema are owned by their respective tasks.

## AI Agent Role

**Role**: UX/UI Designer
**Mindset**: User-centered, accessibility-aware, design-system-aligned
**Focus Areas**: Visual design, interaction patterns, accessibility, platform adaptation, design system consistency
**Communication Style**: Consider user needs and design system implications, ask about brand requirements and platform priorities

## Information Flow

> **📋 Ownership & cross-reference rules**: [Information Flow Guide → UI Design Task (PF-TSK-090)](../../guides/framework/information-flow-guide.md#ui-design-task-pf-tsk-090) — what this task owns, what it references instead, and the cross-reference format.

### Inputs from Other Tasks

- **FDD Creation Task** (PF-TSK-027): Functional requirements, user flows, data display needs, business rules
- **Tier assessment** (via Feature Request Evaluation, PF-TSK-067): Complexity tier, confirmation that UI Design is needed
- **API Design Task** (PF-TSK-020): Data structures and loading patterns (when API Design precedes UI Design)
- **Database Schema Design Task** (PF-TSK-021): Data shape and constraints (when Schema Design precedes UI Design)

### Outputs to Other Tasks

- **TDD Creation Task** (PF-TSK-015): Component specifications, accessibility requirements, animation specs, UI implementation guidance
- **UI Implementation Task** (PF-TSK-052): Wireframes, component specs, asset list, visual design tokens
- **State Management Implementation Task** (PF-TSK-056): UI state inventory (local / feature / global)
- **API Design Task** (PF-TSK-020): UI-driven data needs and loading-state patterns (when UI Design precedes API Design)

## Context Requirements

- **Critical (Must Read):**

  - **Design Guidelines (PD-UIX-001)** — Project-level design system reference at `doc/technical/design/ui-ux/design-system/design-guidelines.md`. **MUST be consulted before every UI Design** (Preparation Step 4).
  - **Functional Design Document (FDD)** — Tier 2+ feature's FDD containing functional requirements, user flows, and data display needs (located in `doc/functional-design/fdds`)
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Feature row used to verify the feature exists; its Status advances past the UI gate on completion (→ `📜 Needs Instruction Design` / `📝 Needs TDD` / `🔧 Needs Impl Plan`)
  - **Tier assessment** — Tier evaluation document; consult the design-needs narrative (locate via [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md))

- **Important (Load If Space):**

  - [`ui-design` craft skill](../../../.claude/skills/ui-design/SKILL.md) — the customization craft (how to fill the UI Design document well), activated in Preparation Step 1 (Check Recommended Skills). Replaces the former procedural customization guide and **drives the bulk of the design work in Execution.**
  - [UI Design Template](../../templates/02-design/ui-design-template.md) — Template structure (11 sections) that the script populates
  - **Existing UI Designs for related features** — For consistency with established design patterns (located in `doc/technical/design/ui-ux/features`)
  - **API Specifications** — Existing or planned API contracts that constrain UI data binding and loading states (`doc/technical/api/specifications`)
  - **Schema Designs** — Existing data model that constrains form fields and display patterns

- **Reference Only (Access When Needed):**

  - [New-UIDesign.ps1](../../scripts/file-creation/02-design/New-UIDesign.ps1) — The automation script used in Execution Step 8
  - [New-DesignGuidelines.ps1](../../scripts/file-creation/02-design/New-DesignGuidelines.ps1) — Creates the project's Design Guidelines (PD-UIX-001) from the design-guidelines template (opt-in, when absent)
  - **Platform Guidelines** — [iOS HIG](https://developer.apple.com/design/human-interface-guidelines/) and [Material Design 3](https://m3.material.io/) for platform-specific adaptation work
  - [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/) — Accessibility compliance reference

## Process

> **⚠️ MANDATORY: Use [New-UIDesign.ps1](../../scripts/file-creation/02-design/New-UIDesign.ps1) for document creation. Never hand-author a UI Design document.**
>
> **🚨 CRITICAL: All design work MUST proceed incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

> **📝 Invocation note**: UI Design is a **state-file gate** — feature-tracking Status `🎨 Needs UI Design`, a design-chain gate (after any DB and API gates; design-chain order DB → API → 🎨 UI → 📜 Instruction → TDD, PF-IMP-1352 / PF-PRO-064, computed by `AssessmentParsing.psm1`). On completion the script advances the feature to the next gate — `📜 Needs Instruction Design` when the feature has an instruction dimension, otherwise `📝 Needs TDD` for Tier 2+ or `🔧 Needs Impl Plan` for Tier 1. The gate is also reachable ad hoc — a human-partner request, a tier-assessment narrative recommending a UI Design pass, an FDD review surfacing UI complexity, or PF-TSK-066 Retrospective Documentation Creation backfilling a UI Design for an existing feature.

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `ui-design-task`. If the `ui-design` craft skill is available in the session, activate it — it owns the **customization craft** this task delegates to (how to fill the UI Design document well). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/ui-design/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The customization craft is unavailable for this run only if the skill file itself is absent (the retired procedural customization guide has no successor).
2. **Verify UI Design is Warranted**: Confirm the feature has user-facing UI complexity that warrants a dedicated design doc. Inputs: Tier Assessment narrative, FDD content, human-partner request. If unclear, surface to human partner before proceeding.
3. **Review the tier assessment** to understand complexity tier and any design-specific guidance recorded there
4. **Consult Design Guidelines (PD-UIX-001)**: Thoroughly review the project's design system document before any design work; if the project has none yet, create it (opt-in) and fill it per the `ui-design` skill's [design-guidelines reference](../../../.claude/skills/ui-design/references/design-guidelines.md), then consult it before proceeding (consulting Design Guidelines remains mandatory).
5. **Gather Context**: Load the FDD, relevant existing UI Designs for related features, and any upstream API/Schema designs that constrain the UI
6. **Identify Design Scope**: Determine target platforms (iOS / Android / Web / Desktop), feature complexity (Tier 1 / 2 / 3), and design depth required (the `ui-design` craft skill carries the design-depth decision points). If the feature touches shared or app-shell UI (a host window, navigation, a pane reused across features), apply the [App-Shell vs Feature-Views Convention](../../guides/02-design/app-shell-vs-feature-views-convention-guide.md) to decide what belongs in this feature's UI Design vs. a shared design doc.
7. **🚨 CHECKPOINT**: Present to human partner: target platforms, Design Guidelines patterns to apply, identified UI components, complexity assessment, and any open design questions. Get explicit approval before proceeding.

### Execution

8. **Create UI Design Document via Script**: Run [New-UIDesign.ps1](../../scripts/file-creation/02-design/New-UIDesign.ps1) to generate the document and trigger automated tracking updates:

   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-UIDesign.ps1 -FeatureId "X.Y.Z" -FeatureName "Feature Name" -Description "Brief design scope" -Confirm:\$false
   ```

   This automatically: assigns a PD-UIX ID, generates the document (with a `description:` frontmatter line) under `doc/technical/design/ui-ux/features/`, sets feature Status to the next design gate (`📜 Needs Instruction Design` / `📝 Needs TDD` / `🔧 Needs Impl Plan`), and inserts a row into the per-feature state file's §4 Documentation Inventory. (The PD map is regenerated separately — see Step 19.)

9. **Customize the Template**: Drive content customization with the `ui-design` craft skill (activated in Preparation, Step 1) — it is the **canonical home for the UI Design customization craft**. This task orchestrates around it; do not hand-author the craft the skill owns. (The skill replaced the former procedural customization guide; there is no parallel guide.)
10. **Design Wireframes and User Flows**: Create Mermaid user-flow diagrams and ASCII/Mermaid wireframes for each screen
11. **Define Visual Design Specifications**: Colors, typography, spacing, iconography — all sourced from Design Guidelines (PD-UIX-001)
12. **Define Component Specifications**: Variants, states, dimensions, behavior, accessibility per component
13. **Define Accessibility, Responsive, and Platform Adaptations**: WCAG 2.1 compliance, breakpoints, iOS / Android / Web / Desktop-specific designs
14. **Define Animation and Design System Integration**: Motion principles, transition specs, patterns applied, new candidate patterns
15. **🚨 CHECKPOINT**: Present the customized UI Design to human partner — wireframes, visual specs, component specs, accessibility plan, platform adaptations. Get explicit approval before finalization.

### Finalization

16. **Verify Design Guidelines Compliance**: Cross-check completed design against PD-UIX-001 (colors, typography, spacing, icons, component library, accessibility, platform guidelines, patterns). Document any deviations in the Design Decisions Log (Template Appendix A) with rationale and approval. If the design standardizes a component or pattern reused across ≥2 features (real reuse, not anticipated), promote it into PD-UIX-001 — add it to the Component Library / Design Patterns section and log the change in that document's Maintenance table — per the promotion rule in the [App-Shell vs Feature-Views Convention](../../guides/02-design/app-shell-vs-feature-views-convention-guide.md).
17. **Complete Design Handoff Checklist**: Work through Section 11 of the UI Design document (deliverables, review & approval, handoff to development)
18. **Add Cross-References**: Brief cross-reference notes linking to API Design and TDD where the UI Design depends on or constrains them
19. **Verify Automated Updates and Regenerate the PD Map**: Confirm that `New-UIDesign.ps1` correctly:
    - Inserted a UI Design row into the per-feature state file's §4 Documentation Inventory
    - Updated [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) row Status to the next design gate (`📜 Needs Instruction Design` / `📝 Needs TDD` / `🔧 Needs Impl Plan`)
    - Generated the document with a `description:` frontmatter line (this is what the PD map renders)

    Then regenerate the PD documentation map so it reflects the new design: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-DocumentationMap.ps1 -Tree PD`, then `… -Tree PD -Check` — exit 0 (the PD map is a generated DO-NOT-EDIT projection, PF-PRO-050).
20. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#mandatory-task-completion-checklist) below

## Outputs

- **UI Design Document** — Comprehensive UI/UX specification at `doc/technical/design/ui-ux/features/ui-design-<id>-<slug>.md` (PD-UIX-NNN)
  - Wireframes and user flows
  - Visual design specifications (colors, typography, spacing, icons)
  - Component specifications with states and accessibility
  - WCAG 2.1 compliance plan
  - Responsive design and platform adaptations
  - Animation specifications
  - Implementation notes (UI component recommendations, asset requirements)
  - Cross-references to FDD, Design Guidelines, TDD, API Design
- **Updated [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)** — Status set to the next design gate (`📜 Needs Instruction Design` / `📝 Needs TDD` / `🔧 Needs Impl Plan`) (automated by script)
- **Updated per-feature state file** — UI Design row inserted into §4 Documentation Inventory (automated by script; PF-PRO-002 / PF-IMP-760)
- **Updated [PD-documentation-map.md](../../../doc/PD-documentation-map.md)** — Regenerated via `Build-DocumentationMap.ps1 -Tree PD` to reflect the new design's `description:` (generated DO-NOT-EDIT projection, PF-PRO-050)

## State Tracking

The following state files are updated as part of this task:

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — **AUTOMATICALLY UPDATED** by `New-UIDesign.ps1`: Status set to the next design gate (`📜 Needs Instruction Design` / `📝 Needs TDD` / `🔧 Needs Impl Plan`)
- Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`) — **AUTOMATICALLY UPDATED**: UI Design row inserted into §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760)
- [PD-documentation-map.md](../../../doc/PD-documentation-map.md) — **GENERATED** (`Build-DocumentationMap.ps1 -Tree PD`): reflects the new design's `description:` on regeneration (DO-NOT-EDIT projection, PF-PRO-050)

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**:
  - [ ] UI Design document created via `New-UIDesign.ps1` (not hand-authored)
  - [ ] All 11 template sections customized (no placeholder text remaining)
  - [ ] Wireframes completed for all in-scope screens
  - [ ] Visual design specifications sourced from Design Guidelines (PD-UIX-001)
  - [ ] All major UI components specified with states and accessibility
  - [ ] WCAG 2.1 compliance plan documented
  - [ ] Responsive design and platform adaptations specified
  - [ ] Animation specifications defined (or explicitly marked as not applicable)
  - [ ] Cross-references to FDD, Design Guidelines, TDD, API Design present
- [ ] **Verify Design Guidelines Compliance**:
  - [ ] Colors match PD-UIX-001 palette
  - [ ] Typography follows PD-UIX-001 type scale
  - [ ] Spacing uses PD-UIX-001 scale
  - [ ] Icons from approved library
  - [ ] Components use approved component library
  - [ ] WCAG 2.1 Level AA targeted
  - [ ] Platform-specific guidelines respected
  - [ ] Any deviations documented in Design Decisions Log with rationale and approval
  - [ ] Any component/pattern reused across ≥2 features promoted into PD-UIX-001 (Component Library / Design Patterns + Maintenance log), or N/A
- [ ] **Verify State File Updates**:
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Status **AUTOMATICALLY UPDATED** to the next design gate (`📜 Needs Instruction Design` / `📝 Needs TDD` / `🔧 Needs Impl Plan`)
  - [ ] Per-feature state file §4 Documentation Inventory contains the UI Design row
  - [ ] [PD-documentation-map.md](../../../doc/PD-documentation-map.md) regenerated via `Build-DocumentationMap.ps1 -Tree PD` and `-Check`-clean; contains the new design entry
- [ ] **Complete Human-Partner Review**: Wireframes, visual specs, component specs, accessibility plan, platform adaptations all reviewed and approved
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-090`, context "UI Design".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| Create | `doc/technical/design/ui-ux/features/ui-design-<id>-<slug>.md` | Script | New PD-UIX document from template |
| Regenerate | `doc/PD-documentation-map.md` | [`Build-DocumentationMap.ps1 -Tree PD`](../../scripts/validation/Build-DocumentationMap.ps1) | Picks up the new design's `description:` (generated DO-NOT-EDIT projection, PF-PRO-050) |
| Update | `doc/state-tracking/permanent/feature-tracking.md` | Script | Sets feature row Status to the next design gate (`📜 Needs Instruction Design` / `📝 Needs TDD` / `🔧 Needs Impl Plan`) |
| Insert | `doc/state-tracking/features/<id>-implementation-state.md` | Script | Inserts UI Design row into §4 Documentation Inventory |

## Next Tasks

- **[Instruction Design](instruction-design-task.md)** (PF-TSK-094) — If the feature also has an instruction dimension, the router hands it `📜 Needs Instruction Design` next; the instruction design is authored with the code designs in hand
- **[TDD Creation](tdd-creation-task.md)** (PF-TSK-015) — Translate the UI Design's component specifications and accessibility requirements into technical implementation guidance
- **[API Design](api-design-task.md)** (PF-TSK-020) — If not already designed, surface API contracts implied by the UI Design's data binding and loading-state patterns
- **[UI Implementation](../04-implementation/ui-implementation.md)** (PF-TSK-052) — Build the designed UI (after TDD completes, or directly for Tier 1 features)
- **[Code Review](../06-maintenance/code-review-task.md)** (PF-TSK-005) — Review the UI Design before TDD/implementation begins (optional but recommended for Tier 3 features)

<!-- merged from transition-registry entry: UI Design (PF-TSK-090) -->
### Prerequisites for Transition

- [ ] UI Design document created via [New-UIDesign.ps1](../../scripts/file-creation/02-design/New-UIDesign.ps1) (PD-UIX-NNN)
- [ ] All 11 template sections customized (no placeholder text remaining)
- [ ] Wireframes, visual specs, component specs, and accessibility plan complete
- [ ] Design Guidelines (PD-UIX-001) compliance verified; any deviations documented in Design Decisions Log
- [ ] Feature Tracking row Status set to the next design gate (`📜 Needs Instruction Design` / `📝 Needs TDD` / `🔧 Needs Impl Plan`) (automated by script)
- [ ] UI Design row inserted into per-feature state file's §4 Documentation Inventory (automated by script)
- [ ] Human partner approved customized UI Design at the Execution checkpoint

### Next Task Selection

```
Is a TDD required for this feature (Tier 2+)?
├─ Yes → TDD Creation
│   └─ Reason: TDD translates UI component specs and accessibility requirements into implementation guidance
└─ No (Tier 1) → UI Implementation
    └─ Reason: Tier 1 features skip TDD; UI Design hands off directly to implementation
```

If the UI Design surfaces API or Schema needs that were not anticipated upstream:

- → **API Design** (PF-TSK-020) — when UI data-binding patterns imply API contracts not yet specified
- → **Database Schema Design** (PF-TSK-021) — when UI input/display patterns imply data shape not yet modeled

### Preparation for Next Task

1. Confirm Design Handoff Checklist (Section 11 of the UI Design document) is fully checked
2. Confirm cross-references to FDD, API Design, TDD are populated
3. Verify the UI Design row in the per-feature state file §4 Documentation Inventory points at the created PD-UIX document
4. Communicate any newly discovered API/Schema needs to the downstream design task

## Related Resources

### Core Inputs

- [UI Design Template](../../templates/02-design/ui-design-template.md) — Template populated by the script
- [`ui-design` craft skill](../../../.claude/skills/ui-design/SKILL.md) — the UI Design customization craft (replaces the retired customization guide); activated by the Check Recommended Skills step
- [New-UIDesign.ps1](../../scripts/file-creation/02-design/New-UIDesign.ps1) — Document creation script
- **Design Guidelines (PD-UIX-001)** — Project-level design system reference (consulted at Preparation Step 4)
- [App-Shell vs Feature-Views Convention](../../guides/02-design/app-shell-vs-feature-views-convention-guide.md) — Decide whether shared/app-shell UI belongs in a shared design doc or this feature's UI Design

### Related Tasks

- [FDD Creation Task](fdd-creation-task.md) (PF-TSK-027) — Upstream input
- [TDD Creation Task](tdd-creation-task.md) (PF-TSK-015) — Downstream consumer
- [API Design Task](api-design-task.md) (PF-TSK-020) — Sibling design task
- [Database Schema Design Task](database-schema-design-task.md) (PF-TSK-021) — Sibling design task
- [UI Implementation Task](../04-implementation/ui-implementation.md) (PF-TSK-052) — Implementation task that consumes this output
- [Feature Request Evaluation](../01-planning/feature-request-evaluation.md) (PF-TSK-067) — Upstream task whose embedded tier assessment flags when UI Design is needed

### Reference Materials

- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Material Design 3](https://m3.material.io/)
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
