---
id: PF-GDE-063
type: Process Framework
category: Guide
version: 1.0
created: 2026-04-27
updated: 2026-04-27
related_task: PF-TSK-044,PF-TSK-066,PF-TSK-081
---

# Diátaxis Content Type Guide

## Overview

Single source of truth for the Diátaxis content-type taxonomy used throughout the framework for user-facing documentation. The framework classifies user docs along two axes: **content type** (the reader's cognitive mode — tutorials/how-to/reference/explanation) and optional **L2 topics** (project-declared domain areas). This guide defines the decision matrix, the per-row status taxonomy, and the consumption points across tasks.

## When to Use

Consult this guide whenever you need to:

- Decide which Diátaxis content types apply to a feature (during planning, retrospective audit, or creation)
- Populate or refine the `### User Documentation` section of a [Feature Implementation State file](/doc/state-tracking/features)
- Choose between status values for a content-type row
- Understand how user-doc planning, retrospective audit, and creation tasks connect

The three primary consumers are:

| Task | When | Action |
|------|------|--------|
| [PF-TSK-044 (Feature Implementation Planning)](/process-framework/tasks/04-implementation/feature-implementation-planning-task.md) | Forward planning for new features | Apply matrix to identify needed content types; populate `### User Documentation` rows with status `❌ Needed` |
| [PF-TSK-066 (Retrospective Documentation Creation)](/process-framework/tasks/00-setup/retrospective-documentation-creation.md) | Onboarding existing codebase | Apply matrix per feature; categorize against existing handbook coverage; populate rows and flag `📖 Needs User Docs` where new handbooks are required |
| [PF-TSK-081 (User Documentation Creation)](/process-framework/tasks/07-deployment/user-documentation-creation.md) | Creating handbooks | Validate/refine the rows populated by PF-TSK-044 or PF-TSK-066; create the handbooks themselves |

## Decision Matrix

For each feature, apply these four questions. Each "Yes" answer identifies a relevant content type. A feature can need zero (internal/architectural), one, or all four types.

| Question | If Yes → Content Type | Example |
|----------|----------------------|---------|
| Is the feature complex enough that newcomers need a guided walk-through from zero to first success? | `tutorials` | "Your first LinkWatcher project" |
| Do users need practical step-by-step directions to accomplish specific tasks with the feature? | `how-to` | "How to configure log rotation" |
| Does the feature have settings, options, CLI flags, API surface, or other facts users will look up? | `reference` | "Complete CLI options reference" |
| Does the feature involve architecture, design concepts, or "why" questions that benefit from explanation? | `explanation` | "How LinkWatcher detects file moves" |

**Internal/architectural features** that have no user-visible behavior get no content-type rows — instead, add a single `N/A` row with rationale (e.g., "internal foundation feature").

### Typical Mappings

These shortcuts catch the common cases. The decision-matrix questions above remain authoritative when in doubt.

- Feature with CLI options or configuration → `reference`
- Feature introducing a new user workflow → `how-to`
- Complex new capability with onboarding friction → also consider `tutorials`
- Architectural change with non-obvious concepts → also consider `explanation`

**Bias toward inclusion when uncertain**: PF-TSK-081 refines the analysis at creation time and can remove rows that prove unnecessary. Rows declared `❌ Needed` are cheaper to drop than missed needs are to retrofit.

## Content Type Values

The four Diátaxis values are the framework default, declared in [PD-id-registry.json](/doc/PD-id-registry.json) under `PD-UGD.subdirectories.values`:

```json
"PD-UGD": {
  "subdirectories": {
    "description": "L1: Diátaxis content type — the reader's cognitive mode",
    "values": ["tutorials", "how-to", "reference", "explanation"],
    "default": "how-to"
  }
}
```

Projects may customize these values during [Project Initiation (PF-TSK-059)](/process-framework/tasks/00-setup/project-initiation-task.md) — for instance, renaming `how-to` to `guides`. Keeping the Diátaxis defaults aids onboarding and tool reuse, but the registry is the source of truth: if a project has customized values, use those.

### L2 Topics (Optional)

Projects may declare second-level topic groupings in `PD-UGD.topics.values` (e.g., `["auth", "payments", "users"]` for an API service). L2 represents **topic/domain area**, not audience segments or document formats. New projects typically leave `values: []` until any L1 directory exceeds ~15-20 docs. When applicable, identify the topic alongside the content type when populating state file rows.

## Status Taxonomy

Each content-type row in a feature's `### User Documentation` table carries one of these statuses:

| Status | Meaning | When to use |
|--------|---------|-------------|
| `✅ Created — [link]` | A dedicated handbook of this content type exists for this feature | Handbook lives in `doc/user/handbooks/<content-type>/[<topic>/]` and is registered in [PD Documentation Map](/doc/PD-documentation-map.md) |
| `✅ Covered Elsewhere — [link]` | Content of this type for this feature is captured in a cross-cutting handbook (quick-reference, capabilities-reference, etc.) | A cross-cutting handbook adequately covers this need without a feature-dedicated handbook. Include a note describing the coverage |
| `❌ Needed` | The content type is relevant but no coverage exists | Feature qualifies via the decision matrix but no current handbook (dedicated or cross-cutting) covers it. Triggers `📖 Needs User Docs` on the feature |
| `N/A` | This content type is not relevant for this feature | Internal/architectural feature, or content type ruled out by the decision matrix. Include a brief rationale |

### Triggering Conditions

- **Any row `❌ Needed`** → set the feature to `📖 Needs User Docs` in [feature-tracking.md](/doc/state-tracking/permanent/feature-tracking.md). This enters the [PF-TSK-081](/process-framework/tasks/07-deployment/user-documentation-creation.md) queue.
- **All rows `✅ Created` / `✅ Covered Elsewhere` / `N/A`** → feature is `🟢 Completed` from a user-doc perspective.

## Examples

### Example 1: Feature with CLI Options and Configuration

**Feature**: Configuration System (LinkWatcher 0.1.3 — config files, CLI args, env vars, presets, ignore system)

| Content Type | Status | Note |
|--------------|--------|------|
| `tutorials` | `N/A` | Configuration is a lookup activity, not a guided walkthrough from zero |
| `how-to` | `❌ Needed` | Users need task-oriented guidance ("How to set up multi-project monitoring", "How to configure log rotation") |
| `reference` | `✅ Created — [configuration-guide.md (PD-UGD-005)]` | All 30+ settings, CLI args, env vars, presets, ignore system documented |
| `explanation` | `✅ Covered Elsewhere — [quick-reference.md]` | Config precedence (CLI > env > config > defaults) explained briefly |

### Example 2: Internal Foundation Feature

**Feature**: In-Memory Link Database (LinkWatcher 0.1.2 — internal storage component)

| Content Type | Status | Note |
|--------------|--------|------|
| `N/A` | — | Internal foundation feature; no user-visible behavior. Architecture documented in TDD/ADR |

### Example 3: Feature with Cross-Cutting Coverage

**Feature**: Link Parsing System (LinkWatcher 2.1.1 — parser implementations)

| Content Type | Status | Note |
|--------------|--------|------|
| `tutorials` | `N/A` | Parsing is automatic — no user-initiated workflow |
| `how-to` | `N/A` | Users don't directly invoke parsers |
| `reference` | `✅ Covered Elsewhere — [linkwatcher-capabilities-reference.md (PD-UGD-004)]` | "Link Detection by Parser" section covers all 7 parsers with pattern tables |
| `explanation` | `✅ Covered Elsewhere — [linkwatcher-capabilities-reference.md (PD-UGD-004)]` | Parser architecture and detection patterns explained |

## Troubleshooting

### Feature has multiple aspects — which content types apply?

Apply the four questions independently for each aspect. A feature with both a CLI surface (reference) and a new user workflow (how-to) gets both rows. Bias toward inclusion; PF-TSK-081 prunes during creation.

### Existing handbook only partially covers the feature

If an existing handbook covers some content types but not others (e.g., reference exists, how-to doesn't), set the covered types to `✅ Created` or `✅ Covered Elsewhere` and the missing types to `❌ Needed`. Do not lump the feature into one row — the per-content-type granularity is the point.

### Project has customized content-type values

Projects may declare values other than the Diátaxis defaults via `PD-UGD.subdirectories.values`. Use the registry's declared values when populating state files. The decision-matrix logic (which need does each type address?) remains useful as a thinking tool even when the names differ.

### "Covered Elsewhere" vs. "Created" — when to choose which

- `✅ Created` = a dedicated handbook for this feature (or for a closely related cluster the feature is the primary subject of)
- `✅ Covered Elsewhere` = a cross-cutting handbook (quick-reference, capabilities-reference, multi-project-setup, etc.) that mentions this feature alongside others

If unsure, prefer `✅ Created` only when you can point to a handbook whose primary subject is the feature.

## Related Resources

- [PF-TSK-044 (Feature Implementation Planning)](/process-framework/tasks/04-implementation/feature-implementation-planning-task.md) — Forward planning consumer
- [PF-TSK-066 (Retrospective Documentation Creation)](/process-framework/tasks/00-setup/retrospective-documentation-creation.md) — Retrospective audit consumer
- [PF-TSK-081 (User Documentation Creation)](/process-framework/tasks/07-deployment/user-documentation-creation.md) — Creation/refinement consumer
- [PF-TSK-059 (Project Initiation)](/process-framework/tasks/00-setup/project-initiation-task.md) — Where the taxonomy is declared/customized
- [PD-id-registry.json](/doc/PD-id-registry.json) — Source of truth for declared content-type and topic values
- [Diátaxis framework (external)](https://diataxis.fr/) — Original framework reference
