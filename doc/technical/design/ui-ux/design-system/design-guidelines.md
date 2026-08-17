---
id: PD-UIX-001
type: Product Documentation
category: UI/UX Design
version: 1.0
created: 2026-07-06
updated: 2026-07-06
description: "Design-system reference for LinkWatcher desktop GUI surfaces (first surface: Control Panel 7.1.1)"
---

# LinkWatcher — Design Guidelines

> **Design Guidelines (PD-UIX-001)** — this project's single **design-system reference**. Every UI Design (PD-UIX-NNN) and UI Implementation consults it before design or build. It is created once per project (the reserved `PD-UIX-001` slot) by `New-DesignGuidelines.ps1` and customized here.

- **Project**: LinkWatcher
- **Maintained by**: AI Agent & Human Partner
- **Last reviewed**: 2026-07-06
- **Scope**: Design-system reference for LinkWatcher desktop GUI surfaces (first surface: Control Panel 7.1.1)

> **Proportionality note**: LinkWatcher is a single-GUI Windows desktop tool. This document is deliberately thin — it fixes the few decisions every GUI surface must share and defers everything feature-specific to the per-feature UI Designs (PD-UIX-NNN).

## 1. Design Principles  *(Required)*

- **Truthful state** — the UI is a live mirror of actual system state (running processes, real log content, saved config). Never show optimistic state the system hasn't confirmed; show transitional states ("starting…", "draining…") explicitly while awaiting confirmation.
- **Clarity over density** — operators glance at this tool while doing other work. One primary piece of information per element; status readable at a glance without reading labels.
- **Safe by default** — actions that terminate processes or overwrite files are explicit, labeled with consequences, and never triggered by a single ambiguous click. Invalid input is blocked at save time with an explanation, not persisted.
- **Keyboard operable** — every action reachable by keyboard alone: logical tab order, visible focus, accelerator keys on primary actions.
- **System-native appearance** — defer to Windows conventions and system theming rather than inventing custom chrome. The tool should feel like a well-behaved Windows utility, not a branded application.

## 2. Color Palette  *(Required)*

Window chrome, controls, and default text use **system-native theme colors** (toolkit defaults). The palette below defines only the **semantic accent tokens** layered on top:

| Token / Name | Value | Role / Usage |
|--------------|-------|--------------|
| `status.running` | `#107C10` | Running / healthy state (green) |
| `status.stopped` | `#6E6E6E` | Stopped / inactive state (neutral gray) |
| `status.transition` | `#9D5D00` | Transitional states: starting, stopping, draining (amber) |
| `status.error` | `#C42B1C` | Errors, failed operations, forced termination (red) |
| `accent.primary` | `#0067C0` | Primary action emphasis, selection, links (Windows accent blue) |
| `surface.log` | `#FFFFFF` / system | Log/config text panes (with system dark-mode equivalent if the toolkit supports it) |

All semantic colors meet ≥ 4.5:1 contrast against white/system-light surfaces. **Status is never conveyed by color alone** — always pair with an icon/glyph or text label (see §6).

## 3. Typography  *(Required)*

| Role | Font / Size / Weight | Usage |
|------|----------------------|-------|
| Window / pane heading | Segoe UI, 14 px, Semibold | Pane titles, dialog headings |
| Body / controls | Segoe UI, 12 px, Regular | Labels, table cells, buttons, status text |
| Secondary / caption | Segoe UI, 11 px, Regular, muted | Timestamps, hints, uptime, paths |
| Monospace | Consolas, 12 px, Regular | Log content, configuration text, file paths in results |

Use the system UI font stack (Segoe UI on Windows 10/11); never embed custom fonts.

## 4. Spacing & Layout Scale  *(Required)*

- **Spacing scale**: 4, 8, 12, 16, 24 px (8 px base unit; 4 px only for tight intra-control gaps)
- **Layout / grid**: no column grid — desktop panel layout. Pane padding 12 px; control-group spacing 8 px; section separation 16 px. Minimum window size must keep all primary actions visible; panes use resizable splitters rather than fixed dimensions.

## 5. Component Library  *(Required)*

Source: **toolkit-native standard widgets only** (conservative envelope — the design must survive either a Tkinter/ttk or Qt/PySide toolkit choice made in the TDD). No custom-drawn controls.

| Component | Source | Variants / States | Notes |
|-----------|--------|-------------------|-------|
| Main window | toolkit-native | normal, minimized; single-instance | System title bar, resizable |
| Table / list view | toolkit-native | row selection (single), hover | Column headers; one row per item |
| Button | toolkit-native | default, primary/accent, disabled | Disabled while action unavailable or in flight |
| Tab strip | toolkit-native | active, inactive | Detail-pane navigation |
| Read-only text pane | toolkit-native | auto-scrolling, scroll-locked | Log viewing (monospace) |
| Text editor pane | toolkit-native | editable, modified (dirty), read-only | Config editing (monospace) |
| Status bar | toolkit-native | info, busy | App-wide messages, background-operation state |
| Progress indicator | toolkit-native | indeterminate | Validation runs, drain waits |
| Message dialog | toolkit-native | info, warning, error, confirm | Modal; confirm used for destructive actions |
| Empty-state text | styled label | — | Centered muted text + one action hint |

## 6. Accessibility Standards  *(Required)*

- **Target**: WCAG 2.1 Level AA, applied to desktop GUI (keyboard, contrast, semantics)
- **Contrast**: ≥ 4.5:1 for text and status glyphs; ≥ 3:1 for large text and UI boundaries
- **Keyboard**: all functionality operable via keyboard; logical tab order; visible focus indicator; Esc cancels dialogs; accelerator keys on primary actions
- **Screen readers / semantics**: every control has an accessible name; status changes announced via accessible labels, not color changes alone
- **Status encoding**: never color-only — pair color with glyph (●/■/▲) and/or text ("Running", "Stopped", "Draining…")
- **Motion**: essential progress indication only; no decorative animation (see per-feature motion specs)

## 7. Design Patterns  *(grows over time)*

Patterns are promoted here once they recur across ≥ 2 features. None promoted yet (single-feature UI as of 2026-07-06).

| Pattern | When to use | Reference |
|---------|-------------|-----------|
| — | — | — |

## Shared UI vs. Feature UI

LinkWatcher is a **single-GUI tool**: the Control Panel (feature 7.1.1) is both the app shell and the entire UI surface, so shell and feature views collapse into **one** UI Design document per the [App-Shell vs Feature-Views Convention](../../../../../process-framework/guides/02-design/app-shell-vs-feature-views-convention-guide.md). Shell-wide conventions (recorded here so a future second surface inherits them):

- **Single window, single instance** — one main window; re-launch surfaces/focuses the existing window instead of opening a second.
- **Master–detail layout** — primary object list (master) with a tabbed detail area; detail panes never open as separate top-level windows.
- **System-native chrome** — no custom title bars, no tray-only operation for primary workflows.

Everything else (specific panes, actions, states) is feature-local and lives in the feature's UI Design (first: Control Panel, PD-UIX-003).

## Maintenance

| Date | Change | By |
|------|--------|----|
| 2026-07-06 | Initial Design Guidelines created and filled (minimal, single-GUI scope) for Control Panel 7.1.1 UI Design | AI Agent & Human Partner |
