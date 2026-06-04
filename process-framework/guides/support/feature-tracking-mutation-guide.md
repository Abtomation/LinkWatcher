---
id: PF-GDE-069
type: Process Framework
category: Guide
version: 1.0
created: 2026-05-28
updated: 2026-05-28
description: "Canonical policy and script reference for mutating feature-tracking.md"
---

# Feature Tracking Mutation Guide

## Overview

`doc/state-tracking/permanent/feature-tracking.md` is the project's authoritative feature-status registry. The file contains hand-readable tables (one per category/subgroup) plus a derived **Progress Summary** (Implementation Status Overview + Documentation Tier Distribution).

The Progress Summary is **computed from the row data** by the framework helper `Update-FeatureTrackingSummary`. Whenever rows change, the summary must be recomputed; otherwise counts go stale.

**Principle**: every mutation routes through a script. Scripts call the recompute helper as a side effect, so the summary stays in sync automatically. Direct edits via the Edit tool bypass the recompute and create silent drift.

## When to Use

Consult this guide whenever you need to:

- Add a feature, subgroup, or category
- Change a feature's Status, Doc Tier, Test Status, Notes, or Dependencies cell
- Move a feature to archived
- Restore a feature's status after an enhancement
- Close a feature request that flips a status

Do **not** open `feature-tracking.md` with the Edit/Write tool to make any of the above changes. Use the matching script below.

## Script Reference

### Row / category structure

| Mutation | Script | Notes |
|---|---|---|
| Add new category (level 1: `N`) | [Update-FeatureCategory.ps1](../../scripts/update/Update-FeatureCategory.ps1) | `-Id "N" -Name "..."` |
| Add new subgroup (level 2: `N.X`) | [Update-FeatureCategory.ps1](../../scripts/update/Update-FeatureCategory.ps1) | `-Id "N.X" -Name "..."` |
| Add new feature row (level 3: `N.X.Y`) | [Update-FeatureCategory.ps1](../../scripts/update/Update-FeatureCategory.ps1) | `-Id "N.X.Y" -Name "..." -Status "..." -DocTier "..."` |
| Move feature to archived | [Archive-Feature.ps1](../../scripts/update/Archive-Feature.ps1) | Atomic move + summary recompute |

### Status column transitions

| Mutation | Script | Typical caller |
|---|---|---|
| Assessment → next design status | [Update-FeatureTrackingFromAssessment.ps1](../../scripts/update/Update-FeatureTrackingFromAssessment.ps1) (auto-chained by `New-Assessment.ps1`) | Feature Tier Assessment |
| FDD created → next status | [New-FDD.ps1](../../scripts/file-creation/02-design/New-FDD.ps1) (auto-updates) | FDD Creation |
| TDD created → 🧪 Needs Test Spec | [New-TDD.ps1](../../scripts/file-creation/02-design/New-TDD.ps1) (auto-updates) | TDD Creation |
| UI Design created → 🎨 UI Design Created | [New-UIDesign.ps1](../../scripts/file-creation/02-design/New-UIDesign.ps1) (auto-updates) | UI Design |
| Implementation Status transitions (🟡 In Progress, 👀 Needs Review, etc.) | [Update-FeatureImplementationState.ps1](../../scripts/update/Update-FeatureImplementationState.ps1) | Implementation tasks |
| Code Review column updates | [Update-CodeReviewState.ps1](../../scripts/update/Update-CodeReviewState.ps1) | Code Review |
| Test Status (per-feature aggregation from test files) | [Update-TestFileAuditState.ps1](../../scripts/update/Update-TestFileAuditState.ps1) | Test audit; also written transitively by `New-TestFile.ps1` |
| 🔄 Needs Enhancement (request closure → status flip) | [Update-FeatureRequest.ps1](../../scripts/update/Update-FeatureRequest.ps1) | Feature Request Evaluation |
| Status restoration after enhancement | [Finalize-Enhancement.ps1](../../scripts/update/Finalize-Enhancement.ps1) | Feature Enhancement |
| 🟢 Completed (post-user-docs) | [Update-BatchFeatureStatus.ps1](../../scripts/update/Update-BatchFeatureStatus.ps1) | User Documentation Creation |

### Common-ScriptHelpers entry points

The scripts above ultimately route through one of these helpers in [FeatureTracking.psm1](../../scripts/Common-ScriptHelpers/FeatureTracking.psm1). New automation should reuse them rather than writing the file directly:

- `Update-FeatureTrackingStatus -FeatureId <Id> -Status <Symbol> -StatusColumn <Name>` — single-feature status/cell update; recomputes the summary.
- `Update-MultipleTrackingFiles` — multi-file batch helper; recomputes when the file is `Type = Feature`.
- `Update-FeatureTrackingSummary -Content <text>` — pure-function recompute of the Progress Summary block. Call this after any custom mutation, then `Set-Content`.

## How the recompute works

`Update-FeatureTrackingSummary` parses every row under `## Feature Categories` (stops at `## Archived Features`), tallies counts by **Status** and **Doc Tier**, and rewrites the **Implementation Status Overview** and **Documentation Tier Distribution** tables under `## Progress Summary`. The function is pure (transforms one content string to another) and is called by every mutation script before `Set-Content`. As long as mutations go through scripts, the displayed counts can never drift from the row data.

## Why scripts (not Edit) — the design rationale

- **Drift elimination**: hand-edits cannot keep the Progress Summary in sync. The recompute is hundreds of lines of column-aware logic that's not reasonable to replicate per-edit.
- **Cross-file coordination**: many mutations also touch the per-feature state file's §4 Documentation Inventory, ID registries, or test-tracking. Scripts atomically coordinate these; manual edits miss them.
- **Validation surface**: future validators (e.g. `Validate-StateTracking.ps1`) can detect drift but cannot fix it cheaply. The cheapest defense is "no path that causes drift in the first place".

## What goes in the per-feature state file, not here

After PF-PRO-002 (2026-05-08), design artifact links (FDD, TDD, Test Spec, ADR, Architecture Impact Assessment, UI Design, API Spec, Schema, Integration Narrative) live in the per-feature implementation state file's `§4 Documentation Inventory` table — **not** as columns in `feature-tracking.md`. Cross-feature queries use [Get-FeatureDesignArtifacts.ps1](../../scripts/Get-FeatureDesignArtifacts.ps1). The master tracking file carries only: ID, Feature, Status, Priority, Doc Tier, Test Status, Dependencies, Notes.

## Related Resources

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — the tracked file
- [FeatureTracking.psm1](../../scripts/Common-ScriptHelpers/FeatureTracking.psm1) — recompute helper + `Update-FeatureTrackingStatus`
- [Get-FeatureDesignArtifacts.ps1](../../scripts/Get-FeatureDesignArtifacts.ps1) — cross-feature design-artifact query (replaces the dropped master columns)
- [Script Development Quick Reference](script-development-quick-reference.md) — patterns for new mutation scripts
