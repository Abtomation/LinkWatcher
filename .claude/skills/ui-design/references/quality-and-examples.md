# Design Depth, QA Completeness & Worked Examples

- [Design-depth decision rationale](#design-depth-decision-rationale)
- [Implementation notes & handoff (optional sections)](#implementation-notes--handoff-optional-sections)
- [QA completeness checks](#qa-completeness-checks)
- [Tiered worked examples](#tiered-worked-examples)
- [Troubleshooting](#troubleshooting)

## Design-depth decision rationale

The SKILL.md decision table sets the defaults; the reasoning behind them:

- **Design depth by tier** — base on complexity, novelty, and risk. Tier 1 (simple): wireframes +
  basic component specs. Tier 2 (moderate): + detailed wireframes/visual/component specs. Tier 3
  (complex): complete specifications across all sections.
- **Wireframe fidelity** — start low (ASCII) for discussion, raise fidelity (Mermaid, then external
  mockups) only as the design solidifies. Don't pixel-polish a design still in flux.
- **Component reuse** — prefer existing/standard components; extend minimally before creating new;
  document any genuinely-new reusable component back into the design system.
- **Platform strategy** — unified visual design with platform-specific *adaptations* is the default;
  go fully platform-specific only when the platforms genuinely diverge.
- **Animation complexity** — minimal/moderate by default; rich only when it earns its keep, always
  at 60 FPS on mid-range devices.

## Implementation notes & handoff (optional sections)

- **Implementation Notes** — suggested components/widgets grouped by purpose (screen structure,
  layout, inputs, buttons, display, navigation); the UI **state types** in play (local / feature /
  global); and **asset requirements** (images, icons, illustrations) with formats/resolutions. Keep
  framework-agnostic — recommend by role, not a specific UI library, unless the project's stack is known.
- **Design Handoff Checklist** (§11 of the document) — wireframes complete · visual specs documented
  · component specs defined · accessibility documented · platform adaptations specified · animations
  specified (or N/A) · implementation notes provided · human review complete · technical feasibility
  confirmed.

## QA completeness checks

Before treating the design as done:

- **Section completeness** — every in-scope template section filled; no placeholder text remaining.
- **Content quality** — wireframes clear; component specs implementation-ready; measurements have
  units (px/dp/pt); colors have hex codes; accessibility requirements are testable.
- **Consistency** — follows PD-UIX-001; terminology matches the FDD; component naming consistent
  throughout; platform designs respect platform conventions.

## Tiered worked examples

- **Tier 1 — empty-state screen**: brief overview, one ASCII wireframe, referenced colors/typography,
  a short icon+text+button component spec, a basic accessibility checklist, a widget list. (~30–45 min)
- **Tier 2 — profile form**: complete overview, 2–3 wireframes, form visual specs, detailed
  text-field/button/avatar specs, full WCAG checklist + screen-reader labels, mobile vs desktop
  layouts, iOS vs Android input styles, widget + state-management notes. (~2–3 h)
- **Tier 3 — multi-step booking flow**: all platforms; 5–7 wireframes + full Mermaid flow; full visual
  specs; 10+ component specs; comprehensive accessibility incl. testing notes; all breakpoints;
  full iOS/Android/Web adaptations; screen transitions + loading + micro-interactions; new patterns
  proposed; detailed widget architecture + state-management strategy. (~4–6 h)

## Troubleshooting

- **Which patterns to use?** — PD-UIX-001 §Design Patterns first, then similar in-app features, then
  platform guidelines (HIG / Material); ask the human partner for direction if still unclear.
- **Wireframes too complex for ASCII?** — switch to Mermaid, or link an external mockup in the
  Appendix, or describe the layout in prose.
- **Unsure about contrast?** — use a contrast checker; ≥ 4.5:1 normal text, ≥ 3:1 large; prefer
  pre-approved PD-UIX-001 colors.
- **Platform designs feel redundant?** — if ≥ 90% identical, document once + note differences; only
  split out genuinely divergent navigation/native-component/gesture behavior.
- **Design must violate the guidelines?** — confirm the deviation is truly necessary (user need /
  technical constraint / business requirement), record it in the **Design Decisions Log** with
  rationale + approval, and if the pattern is reusable, propose evolving PD-UIX-001.
