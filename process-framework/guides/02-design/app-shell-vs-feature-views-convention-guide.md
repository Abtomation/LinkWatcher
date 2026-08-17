---
id: PF-GDE-076
type: Process Framework
category: Guide
version: 1.0
created: 2026-06-30
updated: 2026-06-30
description: "When shared app-shell UI belongs in a shared design doc vs. a feature's own UI Design — proportionate for single-GUI tools, scalable for multi-surface products."
related_task: PF-TSK-090
---

# App-Shell vs Feature-Views Convention

## Overview

The framework's per-feature vertical-slice model gives every feature its own UI Design (PD-UIX-NNN). But some UI is **not** feature-local — the window or navigation host, global menus, shared panes, and layout chrome belong to **more than one** feature, or to the application as a whole. This convention decides, for any screen or component, whether it belongs to a shared **app shell** or to a single feature's **feature views** — and where each is documented.

It is deliberately lightweight: a single-GUI tool barely needs it; a multi-surface product scales it by section.

## When to Use

Consult this convention during [UI Design (PF-TSK-090)](../../tasks/02-design/ui-design-task.md) (and again at UI Implementation) whenever a feature's UI touches infrastructure that is — or could become — shared with other features: a host window, navigation, a global toolbar/menu, a status bar, or a pane reused across features. A project whose entire UI is a single surface can answer the decision in one line (see Proportionality) and move on.

## Definitions

- **App shell** — the UI infrastructure shared across features or owned by the application as a whole: the host window, navigation/menus, global layout chrome, status/notification areas, and panes reused by ≥ 2 features. The shell *hosts* feature views; it is not owned by any one feature.
- **Feature views** — the screens, components, and interactions that belong to a single feature and live in that feature's UI Design (PD-UIX-NNN). A feature view renders *inside* the shell.

## The Decision Rule

For each screen, pane, or component, ask **"who owns it?"**:

- **Shell** if it is part of the host window / navigation, or it is shared by **≥ 2 features**, or it exists independently of any single feature (e.g. a global menu bar, an app-wide status strip). Document it as shell UI (see below).
- **Feature view** if it belongs to **exactly one** feature and renders inside the shell. Document it in that feature's UI Design (PD-UIX-NNN).

When unsure, default to **feature-local** until a second feature actually needs it — promote to the shell only when sharing is real, not anticipated. (This mirrors the Design Patterns promotion rule in the Design Guidelines: promote on the second occurrence, not the first.)

## Where Shell UI Is Documented

- **Shell-wide conventions** (navigation model, where features mount, global layout rules) → the project's **Design Guidelines (PD-UIX-001)**, in its *Shared UI vs. Feature UI* section.
- **The shell's own screens** (when the shell is substantial enough to have wireframes/components of its own) → a dedicated **app-shell UI Design** document (its own PD-UIX-NNN, created with [New-UIDesign.ps1](../../scripts/file-creation/02-design/New-UIDesign.ps1) like any feature's UI Design), cross-referenced from the features that mount into it.

Keep the lighter option until the heavier one is justified: most projects need only the Design Guidelines section; reach for a dedicated app-shell UI Design only when the shell has real design surface of its own.

## Proportionality

- **Single-GUI tool** (the whole UI is one surface): the shell and the (single) feature view collapse into one. Document it as **one** UI Design plus the shared conventions in the Design Guidelines — do not create a separate app-shell document or any extra ceremony.
- **Multi-surface / multi-GUI product**: keep the shell's conventions in the Design Guidelines and give the shell its own UI Design; each feature's UI Design covers only its own views and references the shell for where it mounts.

## Worked Example — LinkWatcher Control Panel

The LinkWatcher Control Panel (PRJ-001 feature 7.1.1) is one window hosting a daemon list, a log view, a config pane, and a validation pane. It **is** an app shell (one host window with several panes) **and** the project's entire UI surface.

Applying the rule: because the Control Panel is the whole UI, the shell and feature views collapse. Document it as **one** UI Design for the Control Panel, with the host-window/navigation conventions captured in the Design Guidelines' *Shared UI vs. Feature UI* section. Do **not** split it into a separate app-shell document plus per-pane feature designs — that ceremony only pays off once the project grows a second, independent UI surface.

## Related Resources

- [UI Design Task (PF-TSK-090)](../../tasks/02-design/ui-design-task.md) — the primary consumer of this convention
- **Design Guidelines (PD-UIX-001)** — the project's design-system reference; its *Shared UI vs. Feature UI* section is where shell-wide conventions live (create it with [New-DesignGuidelines.ps1](../../scripts/file-creation/02-design/New-DesignGuidelines.ps1) if absent)
- [UI Design Template](../../templates/02-design/ui-design-template.md) — the per-feature (and per-shell) UI Design structure
- [design-guidelines-template.md](../../templates/02-design/design-guidelines-template.md) — the Design Guidelines content spec
