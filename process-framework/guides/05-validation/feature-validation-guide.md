---
id: PF-GDE-042
type: Process Framework
category: Guide
version: 2.0
created: 2025-08-17
updated: 2026-06-16
related_script: New-ValidationReport.ps1
related_task: PF-TSK-092,PF-TSK-077
description: "Comprehensive guide for conducting feature validation across the 10-dimension framework (plus standalone AI Agent Continuity)"
---

# Feature Validation Guide

## Overview

The methodology home for feature validation: the **dimension catalog**, the **0–3 scoring** contract, the **tech-debt quality gate**, and the **layer-boundary detection** workflow. The *execution process* lives in the [Dimension Validation dispatcher](../../tasks/05-validation/dimension-validation-task.md) (PF-TSK-092), which runs each dimension's **path file**; a round is planned with [Validation Preparation](../../tasks/05-validation/validation-preparation.md) (PF-TSK-077). The framework spans **10 development dimensions** (aligned with the [Development Dimensions Guide](../framework/development-dimensions-guide.md)) plus a standalone **AI Agent Continuity** task. Not every dimension applies to every feature — for features with a Dimension Profile in their implementation state file, that profile is the primary source for applicability.

> **🚨 Multi-session by design**: never validate all features × dimensions in one session (context limits). Run one dimension × a small feature batch per session.

## Dimension Catalog

Each dimension has its own **path file** (specialized agent role, criteria, steps), all executed through the [Dimension Validation](../../tasks/05-validation/dimension-validation-task.md) dispatcher (PF-TSK-092). [Validation Preparation](../../tasks/05-validation/validation-preparation.md) guides selection.

### Core Dimensions (universal — apply to all projects)

| # | Abbr | Dimension | Path | Focus |
|---|------|-----------|------|-------|
| 1 | AC | Architectural Consistency | [AC path](../../tasks/05-validation/architectural-consistency-validation-path.md) | Pattern adherence, ADR compliance, interface consistency |
| 2 | CQ | Code Quality & Standards | [CQ path](../../tasks/05-validation/code-quality-standards-validation-path.md) | SOLID, code style, language best practices, layer boundaries |
| 3 | ID | Integration & Dependencies | [ID path](../../tasks/05-validation/integration-dependencies-validation-path.md) | Dependency health, interface contracts, data flow |
| 4 | DA | Documentation Alignment | [DA path](../../tasks/05-validation/documentation-alignment-validation-path.md) | TDD alignment, ADR compliance, API-doc accuracy |

### Extended Dimensions (evaluate per project / feature)

| # | Abbr | Dimension | Path | Apply When |
|---|------|-----------|------|------------|
| 5 | EM | Extensibility & Maintainability | [EM path](../../tasks/05-validation/extensibility-maintainability-validation-path.md) | Growing / evolving projects |
| 6 | SE | Security & Data Protection | [SE path](../../tasks/05-validation/security-data-protection-validation-path.md) | User input, auth, sensitive data, external APIs |
| 7 | PE | Performance & Scalability | [PE path](../../tasks/05-validation/performance-scalability-validation-path.md) | I/O, large data, real-time, production load |
| 8 | OB | Observability | [OB path](../../tasks/05-validation/observability-validation-path.md) | Background / async ops, production monitoring |
| 9 | UX | Accessibility / UX Compliance | [UX path](../../tasks/05-validation/accessibility-ux-compliance-validation-path.md) | UI-focused / user-facing features |
| 10 | DI | Data Integrity | [DI path](../../tasks/05-validation/data-integrity-validation-path.md) | Features modifying / transforming / migrating data |

### Standalone Task (not a development dimension)

| Task | Focus | Apply When |
|------|-------|------------|
| AI Agent Continuity [path](../../tasks/05-validation/ai-agent-continuity-validation-path.md) | Context clarity, modular structure, doc quality for AI workflow continuity | AI-assisted development |

> **Standalone, not a dimension**: AI Continuity's criteria (context-window optimization, continuation points) are a valuable periodic check but during development collapse into CQ (readability/naming), EM (modularity), and DA (doc clarity) — so it doesn't flow through the full lifecycle as a dimension.

**Selection**: Core (1–4) apply to virtually all features; Extended (5–10) per the feature's Dimension Profile; AI Continuity for AI-assisted projects. Mark non-applicable dimensions **N/A** with a brief rationale in the tracking matrix. These 10 + the standalone task are a **bounded catalog** — a "new dimension" is almost always a sub-criterion of an existing one.

## Running a round

[Validation Preparation](../../tasks/05-validation/validation-preparation.md) selects features + applicable dimensions and creates the tracking matrix (N features × selected dimensions; cells link to per-(feature, dimension) reports, `N/A` for excluded). Each dimension session then runs through the [Dimension Validation dispatcher](../../tasks/05-validation/dimension-validation-task.md), which owns the shared process (load path file → analyze the feature batch against the dimension's criteria → score → report → update tracking → tech-debt step). Group 2–4 features per session, preferably co-participants in the same user workflow ([user-workflow-tracking.md](../../../doc/state-tracking/permanent/user-workflow-tracking.md)) so cross-feature issues surface together.

Scripts:
```powershell
# create a report template for a dimension + feature batch
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/05-validation/New-ValidationReport.ps1 -ValidationType "ArchitecturalConsistency" -FeatureIds "<f1>,<f2>" -SessionNumber 1
# consolidated summary across reports
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/05-validation/Generate-ValidationSummary.ps1 -IncludeDetails
```
Update the tracking matrix atomically with [Update-ValidationReportState.ps1](../../scripts/update/Update-ValidationReportState.ps1) (not manual Read→Edit→Write — prevents clobbering during parallel sessions).

## Scoring and Interpretation

Each criterion scores on a **0–3** scale: **3** Fully Met (exemplary, a model for others) · **2** Mostly Met (solid, minor issues) · **1** Partially Met (works but major gaps — attention before release) · **0** Not Met (fundamental problems / not implemented — immediate remediation). Any **0** is a **critical issue**, flagged and remediated regardless of overall score.

Scores roll up by averaging: feature score = mean of its criteria; dimension score = mean of feature scores; overall = mean of dimension scores. **Quality gates** on the overall: **≥ 2.5** production-ready · **2.0–2.4** functional, needs targeted improvement · **< 2.0** significant refactoring before production.

**N/A criteria** — when a criterion references an artifact that doesn't exist (e.g. no ADR/TDD for Tier 1), the dimension's path file says whether to **substitute** an equivalent, **skip** (exclude from the score denominator so it doesn't penalize the feature), or **flag as a finding**.

## Layer-Boundary Validation

**Purpose**: detect source-code violations of declared layer dependency rules. **Source of truth**: `doc/project-config.json::layering_rules` (declarative, machine-readable; narrative companion: [`source-layout` craft skill § Layer Dependency Rules](../../../.claude/skills/source-layout/SKILL.md#layer-dependency-rules) — JSON leads, prose follows). Run at the **Code Quality** dimension's Best-Practices-Review step when `layering_rules.layers` is non-empty (empty array = skipped, the default, zero findings, no behavior change).

For each declared layer:
1. **Scope** source files via the layer's `directory_glob`.
2. **Grep imports** for the project's `testing.language`: Python `^\s*from\s+(\S+)\s+import` / `^\s*import\s+(\S+)`; Dart `^\s*import\s+'([^']+)'`; PowerShell `Import-Module` / `using module` / dot-source; JS/TS `import … from '(\S+)'` / `require('(\S+)')`.
3. **Resolve** each import target to a layer (longest matching `directory_glob` wins).
4. **Check `may_import_from`**: intra-layer imports are fine; otherwise the target's layer must be listed in the importing layer's `may_import_from`, else it's a finding.
5. **Emit findings** (file, line, import, accessed layer, rule violated) into the report's Quality Issues; add a Tech Debt item via the dispatcher's tech-debt step.

If `cross_feature_isolation.enabled` is true, also flag cross-feature imports that don't target the foreign feature's `services/` layer (feature A may call B's services, never B's data or ui).

**Worked example (PRJ-002)**: onboarding found 4/9 features with a UI→repository bypass (UI calling `<service>.repository.<method>` directly). With layered `layering_rules` (ui → [services, shared]; services → [data, shared]; data → [shared]; cross-feature isolation on), a Code-Quality session on feature 1.1.3 scanning `src/1.1.3-invoice-generation/ui/**` finds `invoice_service.log_repository.get_all()` in `ui/invoice_screen.py:42` — UI reaching the data layer (not in its `may_import_from`). **Finding**: route through `invoice_service.get_all_logs()` instead.

> Languages without a defined import pattern fall back to generic substring matching against `directory_glob`. A dedicated `Validate-LayerBoundaries.ps1` is a planned follow-up; agent-driven detection is the lightweight first step.

## Tech Debt Item Quality Gate

**Principle**: if an issue is significant enough to document in a validation report, track it as a tech debt item.

> **⚠️ These filters improve TD item *quality* — they do not exclude findings from being tracked.**

Apply before creating a TD item from a finding:

1. **Deduplication** — search [technical-debt-tracking.md](../../../doc/state-tracking/permanent/technical-debt-tracking.md); if an item already covers it, reference that instead of duplicating.
2. **Existing-state verification** — read the current code to confirm the issue still exists (prior work may have fixed it).
3. **Language-context filter** — is the recommendation idiomatic for the project's language? (Java/C# patterns like ABC interfaces / factories may not fit Python's duck-typing.) If not, note as an observation, not a TD item.
4. **Fix viability** — is the fix implementable without side effects? (e.g. adding a lock to a property already called under a lock → deadlock.)
5. **Duplication vs. similarity** — actual duplicated business logic, or incidental shared stdlib calls in different contexts (two `os.path.exists()` for different lifecycle stages isn't problematic duplication)?
6. **Design-decision awareness** — check ADRs / refactoring history; a decision documented in an ADR is an intentional trade-off, not debt.
7. **Scale-informed priority** — set priority by scale (LOW localized, MED/HIGH widespread) but never use scale to skip tracking.
8. **Conditionality** — unconditional issue vs conditional recommendation ("consider X if Y")? Track conditional ones for institutional memory but prefix the Description with `[CONDITIONAL: trigger]` and set LOW priority so they aren't treated as action items until the trigger is verified.

**Every validation finding results in either a TD item or an explicit "not applicable" note** (with reason, citing filters 2–8). Never silently drop a finding.

## Troubleshooting

- **`New-ValidationReport.ps1` "Invalid ValidationType"** — use the exact dimension value (e.g. `Architectural`, `CodeQuality`, `Integration`, `Documentation`, `Extensibility`, `AIContinuity`, and the remaining dimension names); run from the validation directory.
- **Scoring inconsistency** — re-read the 0–3 definitions, use prior reports as benchmarks, score relatively within a dimension, and document evidence per score.

## Related Resources

- [Validation Preparation Task](../../tasks/05-validation/validation-preparation.md) (PF-TSK-077) — **start here** to plan a round
- [Dimension Validation dispatcher](../../tasks/05-validation/dimension-validation-task.md) (PF-TSK-092) — owns the shared process; runs each path file
- Dimension path files: [AC](../../tasks/05-validation/architectural-consistency-validation-path.md) · [CQ](../../tasks/05-validation/code-quality-standards-validation-path.md) · [ID](../../tasks/05-validation/integration-dependencies-validation-path.md) · [DA](../../tasks/05-validation/documentation-alignment-validation-path.md) · [EM](../../tasks/05-validation/extensibility-maintainability-validation-path.md) · [SE](../../tasks/05-validation/security-data-protection-validation-path.md) · [PE](../../tasks/05-validation/performance-scalability-validation-path.md) · [OB](../../tasks/05-validation/observability-validation-path.md) · [UX](../../tasks/05-validation/accessibility-ux-compliance-validation-path.md) · [DI](../../tasks/05-validation/data-integrity-validation-path.md) · [AI Continuity](../../tasks/05-validation/ai-agent-continuity-validation-path.md)
- [Development Dimensions Guide](../framework/development-dimensions-guide.md) — dimension definitions
- Templates: [Validation Report](../../templates/05-validation/validation-report-template.md) · [Validation Tracking](../../templates/05-validation/validation-tracking-template.md)
- Scripts: [New-ValidationReport.ps1](../../scripts/file-creation/05-validation/New-ValidationReport.ps1) · [Update-ValidationReportState.ps1](../../scripts/update/Update-ValidationReportState.ps1) · [Generate-ValidationSummary.ps1](../../scripts/file-creation/05-validation/Generate-ValidationSummary.ps1)
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)
