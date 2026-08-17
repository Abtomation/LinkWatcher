---
id: PF-TEM-084
type: Process Framework
category: Template
version: 1.0
created: 2026-06-30
updated: 2026-06-30
creates_document_category: UI/UX Design
creates_document_prefix: PD-UIX
creates_document_type: Product Documentation
creates_document_version: 1.0
description: Template for a project's Design Guidelines (design-system reference, PD-UIX-001) — design principles, color palette, typography, spacing, component library, accessibility standards, platform guidelines, and design patterns.
template_for: UI/UX Design
usage_context: Product Documentation - UI/UX Design Creation
---

# [Project Name] — Design Guidelines

> **Design Guidelines (PD-UIX-001)** — this project's single **design-system reference**. Every UI Design (PD-UIX-NNN) and UI Implementation consults it before design or build. It is created once per project (the reserved `PD-UIX-001` slot) by `New-DesignGuidelines.ps1` and customized here.

<!--
PROPORTIONALITY — read before filling this in:
- Keep this document proportionate to the project's actual UI surface; it is a reference, not a governance system.
- Single-GUI tool: fill the Required sections briefly and DELETE the Optional sections you don't need.
- Multi-GUI / multi-platform product: scale each section by adding per-surface or per-platform subsections.
- As the system grows, formal design-system governance (component registries, promotion workflows,
  design-token debt tracking) is handled as a separate concern — add it only when a genuinely multi-GUI
  project creates the need, not pre-emptively here.
- Remove every instructional comment (text between <!-- and -->) and every unused [placeholder] during customization.
-->

- **Project**: [Project Name]
- **Maintained by**: [Author]
- **Last reviewed**: [Date]
- **Scope**: [Description]

## 1. Design Principles  *(Required)*

<!-- 3–6 short principles that guide every UI decision (e.g. "Clarity over density", "Keyboard-first",
"Progressive disclosure"). Each: a one-line principle + one sentence on what it means in practice. -->

- **[Principle 1]** — [what it means in practice]
- **[Principle 2]** — [what it means in practice]

## 2. Color Palette  *(Required)*

<!-- Name the colors and their roles. Include hex/token values and intended usage. Note light/dark variants
if the project has them. -->

| Token / Name | Value | Role / Usage |
|--------------|-------|--------------|
| [primary]    | [#RRGGBB] | [primary actions, links] |
| [surface]    | [#RRGGBB] | [backgrounds] |
| [text]       | [#RRGGBB] | [body text] |

## 3. Typography  *(Required)*

<!-- Font families and the type scale (sizes / weights / line-heights), and where each role is used. -->

| Role | Font / Size / Weight | Usage |
|------|----------------------|-------|
| [Heading 1] | [family, size, weight] | [page / window titles] |
| [Body]      | [family, size, weight] | [default text] |

## 4. Spacing & Layout Scale  *(Required)*

<!-- The spacing scale and any layout/grid conventions every screen follows. -->

- **Spacing scale**: [e.g. 4, 8, 12, 16, 24, 32 px]
- **Layout / grid**: [columns, gutters, max content width, breakpoints if responsive]

## 5. Component Library  *(Required)*

<!-- The reusable UI components this project standardizes on (buttons, inputs, dialogs, lists, …) and where
they come from (a framework/widget library, custom widgets, or both). For each: name, source, and the
variants/states in use. Keep this a catalog the team reads — not a governance registry. -->

| Component | Source | Variants / States | Notes |
|-----------|--------|-------------------|-------|
| [Button]  | [library / custom] | [primary, secondary, disabled] | [usage notes] |

## 6. Accessibility Standards  *(Required)*

<!-- The target standard and the project-wide rules every UI must meet. -->

- **Target**: [e.g. WCAG 2.1 Level AA]
- **Contrast**: [minimum ratios]
- **Keyboard**: [full keyboard operability expectations]
- **Screen readers / semantics**: [labeling, roles, focus-order expectations]
- **Motion**: [reduced-motion expectations]

## 7. Platform-Specific Guidelines  *(Optional — include only for multi-platform UIs)*

<!-- DELETE this section for a single-platform tool. Otherwise document per-platform adaptations
(iOS / Android / Web / Desktop): which platform conventions to follow and where they override the
cross-platform defaults above. -->

- **[Platform]**: [conventions + references, e.g. iOS HIG, Material Design 3]

## 8. Design Patterns  *(Optional — grows over time)*

<!-- Recurring interaction/layout patterns the project has standardized (empty states, error handling,
loading, confirmation flows, navigation). Start empty; promote a pattern here once it recurs across ≥2
features. Each: name, when to use, and a brief spec or a pointer to the UI Design (PD-UIX-NNN) that
established it. -->

| Pattern | When to use | Reference |
|---------|-------------|-----------|
| [Empty state] | [no data yet] | [PD-UIX-NNN] |

## Shared UI vs. Feature UI

<!-- If the project has a shared app-shell (a window / navigation host shared across features), document
shell-wide conventions here and keep feature-specific UI in each feature's UI Design (PD-UIX-NNN); see the
app-shell-vs-feature-views convention. For a single-GUI tool whose whole UI is one surface, this document
and that surface's UI Design may be nearly the same — keep both minimal and avoid duplicating content. -->

[For a single-surface tool, note that here and keep this section short. For a multi-surface product, list what is shell-wide vs. feature-local.]

## Maintenance

<!-- Keep this document current as the design system evolves: update it whenever a UI Design or UI
Implementation promotes a feature-local component/pattern into the shared system (the ≥2-feature
promotion rule). The maintainer named at the top owns keeping it current. Record each material change below. -->

| Date | Change | By |
|------|--------|----|
| [Date] | Initial Design Guidelines created | [Author] |
