# Design Guidelines (PD-UIX-001) — consult, and create-when-absent

The **Design Guidelines** is the project's single design-system reference (the reserved singleton
**PD-UIX-001**) at `doc/technical/design/ui-ux/design-system/design-guidelines.md`. Every UI Design
sources its visual decisions from it. There is exactly one per project.

## Always consult it first

Before any visual-design work, read these areas of PD-UIX-001 and design *from* them: Design
Principles, Color Palette, Typography, Spacing & Layout Scale, Component Library, Accessibility
Standards, Platform-Specific Guidelines, Design Patterns. Sourcing visual specs from it (rather than
inventing) is what keeps features visually consistent.

## When the project has none yet — create it (opt-in)

A project may not have a Design Guidelines doc yet. Create the reserved singleton from its template:

```
process-framework/scripts/file-creation/02-design/New-DesignGuidelines.ps1 -Confirm:$false
```

This scaffolds PD-UIX-001 (it pins the reserved ID directly — it does not consume a new PD-UIX
number). Then fill it before continuing the UI Design; consulting it remains mandatory.

## Filling it well — the 8 sections, proportionately

The template (`process-framework/templates/02-design/design-guidelines-template.md`) carries the
per-section skeleton. Fill the eight sections to a depth proportionate to the product — a single-GUI
internal tool needs far less than a multi-surface product. Don't over-build a governance document for
a small tool (design-system *governance* is out of scope here).

| # | Section | Fill with |
|---|---------|-----------|
| 1 | Design Principles | the few principles that actually steer decisions for this product |
| 2 | Color Palette | named colors + hex, with usage roles (primary/success/error/surface/…) |
| 3 | Typography | the type scale actually used (sizes/weights per role) |
| 4 | Spacing & Layout Scale | the spacing unit/grid (commonly 8px) and the steps used |
| 5 | Component Library | the shared/approved components and their canonical specs |
| 6 | Accessibility Standards | the project's baseline (e.g. WCAG 2.1 AA) and any house rules |
| 7 | Platform-Specific Guidelines | per-platform conventions, when the product spans platforms |
| 8 | Design Patterns | reusable interaction/layout patterns features should apply |

**Shared vs feature UI** — where shared app-shell UI (host window, nav, reused panes) is documented
(here vs. a dedicated app-shell UI Design) follows the
[App-Shell vs Feature-Views Convention](../../../../process-framework/guides/02-design/app-shell-vs-feature-views-convention-guide.md).

## Keeping it current

When a UI Design introduces a genuinely reusable new pattern (High reusability — see the
design-system-integration craft), recommend adding it to PD-UIX-001 so the next feature inherits it.
The Design Guidelines is a living reference, not a one-time artifact.
