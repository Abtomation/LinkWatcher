---
id: PF-TSK-090
type: Process Framework
category: Task Definition
version: 1.0
created: 2026-05-27
updated: 2026-05-27
description: "Systematic UI/UX design planning before implementation: translate functional requirements into wireframes, visual specifications, component definitions, accessibility requirements, and platform adaptations as a PD-UIX design document."
---

# UI Design

**🤖 AUTOMATION NOTE**: This task is **FULLY AUTOMATED** by [New-UIDesign.ps1](../../scripts/file-creation/02-design/New-UIDesign.ps1) (via the shared `Invoke-DesignArtifactCreation` core). The script generates the UI Design document, appends to PD-documentation-map.md, sets the feature's Status to `🎨 UI Design Created`, and inserts a UI Design row into the per-feature state file's §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760).

## Purpose & Context

Systematic UI/UX design planning before implementation. Translates functional requirements into concrete visual and interaction designs — wireframes, visual specifications, component definitions, accessibility requirements, responsive behavior, and platform adaptations — captured as a PD-UIX design document for handoff to TDD and implementation.

**Scope**: This task owns **design-document concerns**: wireframes, visual specs, component specs, accessibility requirements, responsive design, platform adaptations, motion. UI code implementation, state management plumbing, API endpoint design, and database schema are owned by their respective tasks.

## AI Agent Role

**Role**: UX/UI Designer
**Mindset**: User-centered, accessibility-aware, design-system-aligned
**Focus Areas**: Visual design, interaction patterns, accessibility, platform adaptation, design system consistency
**Communication Style**: Consider user needs and design system implications, ask about brand requirements and platform priorities

## Information Flow

> **📋 Detailed Guidance**: See [Information Flow Guide](../../guides/framework/information-flow-guide.md) for comprehensive information flow patterns.

### Inputs from Other Tasks

- **FDD Creation Task** (PF-TSK-027): Functional requirements, user flows, data display needs, business rules
- **Feature Tier Assessment** (PF-TSK-002): Complexity tier, confirmation that UI Design is needed
- **API Design Task** (PF-TSK-020): Data structures and loading patterns (when API Design precedes UI Design)
- **Database Schema Design Task** (PF-TSK-021): Data shape and constraints (when Schema Design precedes UI Design)

### Outputs to Other Tasks

- **TDD Creation Task** (PF-TSK-015): Component specifications, accessibility requirements, animation specs, UI implementation guidance
- **UI Implementation Task** (PF-TSK-052): Wireframes, component specs, asset list, visual design tokens
- **State Management Implementation Task** (PF-TSK-056): UI state inventory (local / feature / global)
- **API Design Task** (PF-TSK-020): UI-driven data needs and loading-state patterns (when UI Design precedes API Design)

### Separation of Concerns

**This task owns**:

- ✅ Wireframes and user flow diagrams
- ✅ Visual design specifications (colors, typography, spacing, icons)
- ✅ Component specifications (variants, states, dimensions, behavior, accessibility)
- ✅ Accessibility requirements (WCAG 2.1 compliance, screen reader support)
- ✅ Responsive design and platform adaptations (iOS, Android, Web)
- ✅ Animation and motion specifications
- ✅ Design system integration (patterns applied, new patterns proposed)

**Other tasks own**:

- ❌ UI code implementation → [UI Implementation Task](../04-implementation/ui-implementation.md) (PF-TSK-052)
- ❌ State management implementation → [State Management Implementation Task](../04-implementation/state-management-implementation.md) (PF-TSK-056)
- ❌ API endpoint specifications → [API Design Task](api-design-task.md) (PF-TSK-020)
- ❌ Database schema → [Database Schema Design Task](database-schema-design-task.md) (PF-TSK-021)
- ❌ Test specifications → [Test Specification Creation Task](../03-testing/test-specification-creation-task.md) (PF-TSK-012)

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/02-design/ui-design-task-map.md)

- **Critical (Must Read):**

  - **Design Guidelines (PD-UIX-001)** — Project-level design system reference at `doc/technical/design/ui-ux/design-system/design-guidelines.md`. Contains design principles, color palette, typography, spacing scale, component library, accessibility standards, platform-specific guidelines. **MUST be consulted before every UI Design.** If the project has no Design Guidelines yet, surface this gap to the human partner before proceeding.
  - **Functional Design Document (FDD)** — Tier 2+ feature's FDD containing functional requirements, user flows, and data display needs (located in `doc/functional-design/fdds`)
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — Feature row used to verify the feature exists and to receive the `🎨 UI Design Created` milestone marker on completion
  - **Feature Tier Assessment** — Tier evaluation document; consult the design-needs narrative (locate via [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md))

- **Important (Load If Space):**

  - [UI Design Customization Guide](../../guides/02-design/ui-design-customization-guide.md) — 19-step, 6-phase guide for customizing the UI Design template. **Drives the bulk of the design work in Execution.**
  - [UI Design Template](../../templates/02-design/ui-design-template.md) — Template structure (11 sections) that the script populates
  - **Existing UI Designs for related features** — For consistency with established design patterns (located in `doc/technical/design/ui-ux/features`)
  - **API Specifications** — Existing or planned API contracts that constrain UI data binding and loading states (`doc/technical/api/specifications`)
  - **Schema Designs** — Existing data model that constrains form fields and display patterns

- **Reference Only (Access When Needed):**

  - [New-UIDesign.ps1](../../scripts/file-creation/02-design/New-UIDesign.ps1) — The automation script used in Execution Step 7
  - [Visual Notation Guide](../../guides/support/visual-notation-guide.md) — For interpreting context map diagrams
  - **Platform Guidelines** — [iOS HIG](https://developer.apple.com/design/human-interface-guidelines/) and [Material Design 3](https://m3.material.io/) for platform-specific adaptation work
  - [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/) — Accessibility compliance reference

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including the feedback form are finished!**
>
> **⚠️ MANDATORY: Use [New-UIDesign.ps1](../../scripts/file-creation/02-design/New-UIDesign.ps1) for document creation. Never hand-author a UI Design document.**
>
> **🚨 CRITICAL: All design work MUST proceed incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

> **📝 Invocation note**: UI Design is **not driven by a state-file gate** (unlike FDD/TDD/API/Schema which have `📋 Needs FDD` / `📝 Needs TDD` / `🔌 Needs API Design` / `🗄️ Needs DB Design` triggers). It is invoked when: the human partner requests it, the Feature Tier Assessment narrative recommends a UI Design pass, FDD review surfaces UI complexity warranting a dedicated design doc, or PF-TSK-066 Retrospective Documentation Creation needs to backfill a UI Design for an existing feature. The task produces a `🎨 UI Design Created` **milestone marker** on the feature row, not a next-action gate. This is documented in `AssessmentParsing.psm1` and is intentional framework design.

1. **Verify UI Design is Warranted**: Confirm the feature has user-facing UI complexity that warrants a dedicated design doc. Inputs: Tier Assessment narrative, FDD content, human-partner request. If unclear, surface to human partner before proceeding.
2. **Review Feature Tier Assessment** to understand complexity tier and any design-specific guidance recorded there
3. **Consult Design Guidelines (PD-UIX-001)**: Thoroughly review the project's design system document before any design work. Required areas: Design Principles, Color Palette, Typography, Spacing scale, Component Library, Accessibility Standards, Platform-Specific Guidelines, Design Patterns. **If the project has no Design Guidelines document yet, stop and surface this gap to the human partner — UI Design cannot proceed without it.**
4. **Gather Context**: Load the FDD, relevant existing UI Designs for related features, and any upstream API/Schema designs that constrain the UI
5. **Identify Design Scope**: Determine target platforms (iOS / Android / Web), feature complexity (Tier 1 / 2 / 3), and design depth required (see [Customization Decision Points](../../guides/02-design/ui-design-customization-guide.md#customization-decision-points))
6. **🚨 CHECKPOINT**: Present to human partner: target platforms, Design Guidelines patterns to apply, identified UI components, complexity assessment, and any open design questions. Get explicit approval before proceeding.

### Execution

7. **Create UI Design Document via Script**: Run [New-UIDesign.ps1](../../scripts/file-creation/02-design/New-UIDesign.ps1) to generate the document and trigger automated tracking updates:

   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-UIDesign.ps1 -FeatureId "X.Y.Z" -FeatureName "Feature Name" -Description "Brief design scope" -Confirm:\$false
   ```

   This automatically: assigns a PD-UIX ID, generates the document under `doc/technical/design/ui-ux/features/`, updates PD-documentation-map.md, sets feature Status to `🎨 UI Design Created`, and inserts a row into the per-feature state file's §4 Documentation Inventory.

8. **Customize the Template**: Follow the [UI Design Customization Guide](../../guides/02-design/ui-design-customization-guide.md) (19 steps across 6 phases). The guide is the canonical source for content-customization work — this task definition orchestrates around it; do not duplicate its content.
9. **Design Wireframes and User Flows** (Phase 2 of customization guide): Create Mermaid user-flow diagrams and ASCII/Mermaid wireframes for each screen
10. **Define Visual Design Specifications** (Phase 2): Colors, typography, spacing, iconography — all sourced from Design Guidelines (PD-UIX-001)
11. **Define Component Specifications** (Phase 2): Variants, states, dimensions, behavior, accessibility per component
12. **Define Accessibility, Responsive, and Platform Adaptations** (Phase 3): WCAG 2.1 compliance, breakpoints, iOS / Android / Web-specific designs
13. **Define Animation and Design System Integration** (Phase 4): Motion principles, transition specs, patterns applied, new candidate patterns
14. **🚨 CHECKPOINT**: Present the customized UI Design to human partner — wireframes, visual specs, component specs, accessibility plan, platform adaptations. Get explicit approval before finalization.

### Finalization

15. **Verify Design Guidelines Compliance**: Cross-check completed design against PD-UIX-001 (colors, typography, spacing, icons, component library, accessibility, platform guidelines, patterns). Document any deviations in the Design Decisions Log (Template Appendix A) with rationale and approval.
16. **Complete Design Handoff Checklist**: Work through Section 11 of the UI Design document (deliverables, review & approval, handoff to development)
17. **Add Cross-References**: Brief cross-reference notes linking to API Design and TDD where the UI Design depends on or constrains them
18. **Verify Automated Updates**: Confirm that `New-UIDesign.ps1` correctly:
    - Inserted a UI Design row into the per-feature state file's §4 Documentation Inventory
    - Updated [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) row Status to `🎨 UI Design Created`
    - Appended the new design to PD-documentation-map.md
19. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#mandatory-task-completion-checklist) below

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
- **Updated [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)** — Status set to `🎨 UI Design Created` (automated by script)
- **Updated per-feature state file** — UI Design row inserted into §4 Documentation Inventory (automated by script; PF-PRO-002 / PF-IMP-760)
- **Updated [PD-documentation-map.md](../../../doc/PD-documentation-map.md)** — New UI Design entry appended (automated by script)

## State Tracking

The following state files are updated as part of this task:

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — **AUTOMATICALLY UPDATED** by `New-UIDesign.ps1`: Status set to `🎨 UI Design Created`
- Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`) — **AUTOMATICALLY UPDATED**: UI Design row inserted into §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760)
- [PD-documentation-map.md](../../../doc/PD-documentation-map.md) — **AUTOMATICALLY UPDATED**: New design entry appended

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

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
- [ ] **Verify State File Updates**:
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Status **AUTOMATICALLY UPDATED** to `🎨 UI Design Created`
  - [ ] Per-feature state file §4 Documentation Inventory contains the UI Design row
  - [ ] [PD-documentation-map.md](../../../doc/PD-documentation-map.md) contains the new design entry
- [ ] **Complete Human-Partner Review**: Wireframes, visual specs, component specs, accessibility plan, platform adaptations all reviewed and approved
- [ ] **Complete Feedback Form**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md), using task ID `PF-TSK-090` and context `UI Design`

## Next Tasks

- **[TDD Creation](tdd-creation-task.md)** (PF-TSK-015) — Translate the UI Design's component specifications and accessibility requirements into technical implementation guidance
- **[API Design](api-design-task.md)** (PF-TSK-020) — If not already designed, surface API contracts implied by the UI Design's data binding and loading-state patterns
- **[UI Implementation](../04-implementation/ui-implementation.md)** (PF-TSK-052) — Build the designed UI (after TDD completes, or directly for Tier 1 features)
- **[Code Review](../06-maintenance/code-review-task.md)** (PF-TSK-005) — Review the UI Design before TDD/implementation begins (optional but recommended for Tier 3 features)

## Related Resources

### Core Inputs

- [UI Design Template](../../templates/02-design/ui-design-template.md) — Template populated by the script
- [UI Design Customization Guide](../../guides/02-design/ui-design-customization-guide.md) — 19-step customization process (Phases 1-6)
- [New-UIDesign.ps1](../../scripts/file-creation/02-design/New-UIDesign.ps1) — Document creation script
- **Design Guidelines (PD-UIX-001)** — Project-level design system (must be present in the project before this task runs)

### Related Tasks

- [FDD Creation Task](fdd-creation-task.md) (PF-TSK-027) — Upstream input
- [TDD Creation Task](tdd-creation-task.md) (PF-TSK-015) — Downstream consumer
- [API Design Task](api-design-task.md) (PF-TSK-020) — Sibling design task
- [Database Schema Design Task](database-schema-design-task.md) (PF-TSK-021) — Sibling design task
- [UI Implementation Task](../04-implementation/ui-implementation.md) (PF-TSK-052) — Implementation task that consumes this output
- [Feature Tier Assessment](../01-planning/feature-tier-assessment-task.md) (PF-TSK-002) — Upstream task that flags when UI Design is needed

### Reference Materials

- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Material Design 3](https://m3.material.io/)
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
