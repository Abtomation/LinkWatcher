---
name: ui-design
description: >-
  Craft for customizing a UI/UX Design document (PD-UIX) well — the "how to fill it" half of
  the framework's UI Design task (PF-TSK-090). Covers sourcing visual specs from the project
  Design Guidelines (PD-UIX-001), wireframes & user flows, component specs, accessibility,
  responsive & platform adaptations, motion, and design-system integration. Activated only from
  the UI Design task's Check-Recommended-Skills step (via recommended_skills); not a general
  UI-building, frontend-coding, or product-design skill.
user-invocable: false
---

# UI Design Craft

This skill owns the **craft** of customizing a UI/UX Design document — *how* to fill a PD-UIX
document well. It is the customization-craft home for the **UI Design task (PF-TSK-090)**, which
owns everything else: task selection, role, checkpoints, document creation via script, state-file
updates, and the feedback form.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** run checkpoints,
> create the document, or write state from this skill — those stay in the task. This skill drives
> the customization between the task's Execution checkpoints.

## When this applies

Activated from PF-TSK-090's first Preparation step (Check Recommended Skills) when a UI Design is
warranted for a feature. The document itself is created by the task's script step (below); this
skill guides filling its 11 sections.

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. It points at the framework's agnostic scripts, which the
task runs from the project root (cwd = project):

- `process-framework/scripts/file-creation/02-design/New-UIDesign.ps1` — creates the PD-UIX
  document, sets the feature's status to the next design gate, and inserts the §4 Documentation
  Inventory row. The **task** runs this at its Execution step; this skill never hand-authors the doc.
- `process-framework/scripts/file-creation/02-design/New-DesignGuidelines.ps1` — creates the
  reserved singleton Design Guidelines doc (PD-UIX-001) from its template when a project has none yet.
- `process-framework/scripts/validation/Build-DocumentationMap.ps1 -Tree PD` — regenerates the PD
  documentation map (the task runs this at finalization).

## Step 0 (mandatory): consult the Design Guidelines (PD-UIX-001)

**Always consult the project's Design Guidelines before and during design.** It is the design-system
reference (principles, color palette, typography, spacing scale, component library, accessibility
standards, platform guidelines, design patterns) at
`doc/technical/design/ui-ux/design-system/design-guidelines.md`. Every visual spec — colors,
typography, spacing, icons, components, patterns — is **sourced from it**, not invented.

If the project has **no** Design Guidelines yet, create it (opt-in) with `New-DesignGuidelines.ps1`,
then fill and consult it before proceeding. Filling it well is its own craft —
see [references/design-guidelines.md](references/design-guidelines.md).

## Scope the design depth first

Match effort to the feature's complexity tier and risk. Apply these decision points before
customizing (full rationale in
[references/quality-and-examples.md](references/quality-and-examples.md)):

| Decision | Options | Default |
|----------|---------|---------|
| **Design depth** | Tier 1: wireframes + basic component specs · Tier 2: + detailed visual/component specs · Tier 3: all 11 sections complete | by tier |
| **Wireframe fidelity** | ASCII (early/simple) · Mermaid (flows/structure) · external mockup (complex UIs) | start low, raise as it solidifies |
| **Component reuse** | prefer existing/standard components → extend minimally → create new (and add reusable ones to the design system) | prefer existing |
| **Platform strategy** | unified visual design + platform-specific adaptations vs. fully platform-specific | unified + adaptations |
| **Motion** | minimal (standard transitions) · moderate (feedback/loading) · rich (multi-step) — keep 60 FPS | minimal–moderate |

**Shared / app-shell UI** (a host window, navigation, a pane reused across features) follows the
[App-Shell vs Feature-Views Convention](../../../process-framework/guides/02-design/app-shell-vs-feature-views-convention-guide.md):
decide whether it belongs in *this* feature's UI Design or a shared design doc before designing it.

## The 11-section document and where the craft lives

The template has 11 sections. Fill them in this order; the detailed craft for each cluster is in a
reference file (load only the one you need):

1. **Feature Overview** · 2. **Related Documentation** · 3. **Design Overview** (goals, user
   context, constraints) — straightforward; fill from the FDD + tier assessment.
4. **Wireframes & User Flows** · 5. **Visual Design Specifications** · 6. **Component
   Specifications** → [references/wireframes-visual-components.md](references/wireframes-visual-components.md)
7. **Accessibility Requirements** · 8. **Responsive Design** · 9. **Platform-Specific Adaptations** ·
   10. **Animation & Transitions** · 11. **Design System Integration** →
   [references/accessibility-responsive-platform-motion.md](references/accessibility-responsive-platform-motion.md)

Optional: Implementation Notes (component/widget recommendations, state-type inventory, assets),
Design Handoff Checklist, Appendix (Design Decisions Log). Implementation-notes and handoff craft is
in [references/quality-and-examples.md](references/quality-and-examples.md).

## Finalization craft (task owns the checkpoint; this informs it)

- **Design Guidelines compliance cross-check** — verify colors, typography, spacing, icons,
  components, accessibility level, platform guidelines, and patterns against PD-UIX-001. Record any
  deliberate **deviation** in the document's **Design Decisions Log** (Appendix A) with rationale +
  approval — a deviation is a documented choice, not a silent drift.
- **Design Handoff Checklist** (§11) — work through it before the design is handed to TDD/implementation.
- **Tiered scope, QA completeness checks, and worked Tier 1/2/3 examples** are in
  [references/quality-and-examples.md](references/quality-and-examples.md).

## Reference index

- [references/design-guidelines.md](references/design-guidelines.md) — consulting and (when absent)
  creating + filling the Design Guidelines doc (PD-UIX-001).
- [references/wireframes-visual-components.md](references/wireframes-visual-components.md) — wireframes,
  user flows, visual specs, component specs (template sections 4–6).
- [references/accessibility-responsive-platform-motion.md](references/accessibility-responsive-platform-motion.md)
  — accessibility, responsive design, platform adaptations, motion, design-system integration
  (sections 7–11).
- [references/quality-and-examples.md](references/quality-and-examples.md) — design-depth decision
  rationale, QA completeness checks, tiered worked examples, troubleshooting.
