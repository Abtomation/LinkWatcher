---
id: PF-GDE-065
type: Process Framework
category: Guide
version: 1.1
created: 2026-05-05
updated: 2026-05-11
related_task: PF-TSK-087
status: deprecated
deprecated_on: 2026-05-11
replaced_by: PF-TSK-088
---

# Blueprint Sync Consideration Policy

> **🗄️ DEPRECATED (2026-05-11)**: This guide supported the now-deprecated PF-TSK-087 framework-blueprint-sync task and has no current consumer. The Push/Restore model in [Framework Rollout Task (PF-TSK-088)](../../tasks/support/framework-rollout-task.md) replaces the workflow this guide informed. The content below is retained for historical reference only — references to `process-framework-local/` describe pre-migration source-project layout that does not apply to registered projects post-migration. **Do not consult this guide for new work.**

## Overview

Per-subdirectory and per-skeleton-file classification policy for [PF-TSK-087 framework-blueprint-sync](../../tasks/support/framework-blueprint-sync-task.md) drift discovery (Step 5). Classifies every top-level and second-level directory and the skeleton files inside them as one of three handling modes so the agent walks deeply enough on the first pass to catch framework-shape drift.

## When to Use

Use this guide when executing **Step 5 (Discover new drift)** of [PF-TSK-087](../../tasks/support/framework-blueprint-sync-task.md). For each in-scope top-level directory, look up its second-level subdirs and skeleton files in the [Coverage Tables](#coverage-tables) below to determine the depth of comparison required.

> **🚨 CRITICAL**: Do not declare a directory "no structural drift" after a 1-level walk. Subdirectories tagged **Always Consider Section-Shape** require deep skeleton-file comparison (sections, table columns, status legends, schema fields), not just file-presence comparison. The first execution of PF-TSK-087 (2026-05-05) needed 3 catch-up rounds because this depth was skipped.

## Table of Contents

1. [Background](#background)
2. [The Three Classifications](#the-three-classifications)
3. [Coverage Tables](#coverage-tables)
   - [Top-Level Directories](#top-level-directories)
   - [`process-framework-local/` Second-Level](#process-framework-local-second-level)
   - [`doc/` Second-Level](#doc-second-level)
   - [`test/` Second-Level](#test-second-level)
   - [Root Files](#root-files)
4. [Skeleton-File Section-Shape Comparison](#skeleton-file-section-shape-comparison)
5. [Updating This Policy](#updating-this-policy)
6. [Related Resources](#related-resources)

## Background

Sync sessions repeatedly under-walked because PF-TSK-087 Step 5 only said "compare structure" without distinguishing dirs whose contents are project-specific (no walk needed) from dirs whose contents include skeleton files carrying framework-shape (deep walk required). The first execution surfaced this through three catch-up rounds:

| Round | Discovery | Cause |
|-------|-----------|-------|
| 1 | PFL-2/3/4/5 missed in `process-framework-local/` | 1-level walk; missed Status Legend table column count drift, Task Routing section, Active Pilots section, `tools/linkWatcher/logs/` dir |
| 2 | TEST-6/7/8 + DOC-5 missed in `test/` and `doc/` | Same shallow walk applied to other dirs; missed `performance-test-tracking.md` Status Legend + audit columns, `e2e-test-tracking.md` dual-status framework, `test-tracking.md` Status Legend vocabulary, `PD-id-registry.json` `id_gaps_policy` field |
| 3 | DOC-7→11 registry drift | Surfaced during deep walk in round 2; required separate sync round |

The pattern: skeleton files (registries, trackers, doc-maps) are framework-canonical scaffolding whose section/table/schema shape evolves over time. Comparing only the file's existence misses real drift inside the file.

## The Three Classifications

| Classification | Meaning | Sync action |
|----------------|---------|-------------|
| **Ignore Content** | Directory or file contents are project-specific (feedback forms, FDDs, test cases, validation reports). Do not diff or sync the contents. | Skip the contents entirely. |
| **Consider Structure** | The directory's *presence* (and any sub-scaffolding like `archive/`) is framework-shape, but the contents are project-specific. | Verify the directory exists in the blueprint with its expected sub-scaffolding. Do not diff inner files. |
| **Always Consider Section-Shape** | File or directory contains skeleton files whose internal shape (section headers, table columns, status-legend rows, schema fields) is framework-canonical. | Walk into the file. Compare structure section-by-section, not byte-by-byte. Sync structural changes; do not sync project-specific values (entries, populated rows, ID counters). |

A second-level subdir can mix classifications — e.g., `feedback/archive/` is Consider Structure (the `archive/` scaffolding is structural) but `feedback/archive/YYYY-MM/` underneath is Ignore Content.

## Coverage Tables

### Top-Level Directories

The top-level rules from [PF-TSK-087 Per-Directory Handling Rules](../../tasks/support/framework-blueprint-sync-task.md#per-directory-handling-rules) determine the strategy. The tables below detail **second-level** classification within each top-level dir.

| Directory | Top-level rule (from PF-TSK-087) | Second-level walk required? |
|-----------|----------------------------------|------------------------------|
| `process-framework/` | Wholesale replace | No — entire tree is overwritten. Skip the second-level walk. |
| `process-framework-local/` | Structure-only sync | **Yes** — see [`process-framework-local/` table](#process-framework-local-second-level) |
| `doc/` | Diff + classify + checkpoint | **Yes** — see [`doc/` table](#doc-second-level) |
| `test/` | Diff + classify + checkpoint | **Yes** — see [`test/` table](#test-second-level) |
| `src/` | Skip by default | No — project-specific source. |
| Root files | Diff + classify + checkpoint | **Yes** — see [Root Files table](#root-files) |

### `process-framework-local/` Second-Level

| Path | Classification | Notes |
|------|---------------|-------|
| `PF-id-registry-local.json` | Always Consider Section-Shape | Compare metadata fields (`id_gaps_policy`, etc.) and prefix-entry schema. Reset `nextAvailable` to 1 in blueprint; do not sync values. |
| `evaluation-reports/` | Consider Structure | Presence required. |
| `evaluation-reports/archive/` | Consider Structure | Scaffolding required even when empty. |
| `feedback/` | Consider Structure | Presence required. |
| `feedback/feedback-forms/` | Ignore Content | Forms are project-specific. |
| `feedback/archive/` | Consider Structure | Verify `README.md` if present is framework-canonical. |
| `feedback/archive/YYYY-MM/` | Ignore Content | Archived project forms. |
| `feedback/reviews/` | Ignore Content | Review summaries are project-specific. |
| `proposals/` | Consider Structure | Presence required (with `old/` subdir). |
| `proposals/old/` | Ignore Content | Archived project proposals. |
| `state-tracking/` | Consider Structure | Presence required. |
| `state-tracking/permanent/` | Always Consider Section-Shape | Skeleton files: [`process-improvement-tracking.md`](#process-improvement-tracking-md). |
| `state-tracking/temporary/` | Ignore Content | Transient session state. |
| `state-tracking/temporary/old/` | Ignore Content | Archived session state. |
| `tools/` | Consider Structure | Presence required. |
| `tools/linkWatcher/` | Consider Structure | Presence required. |
| `tools/linkWatcher/logs/` | Consider Structure | Ensure dir exists; do not sync log contents. |
| `tools/linkWatcher/.linkwatcher-ignore` | Always Consider Section-Shape | Skeleton ignore file; sync structural rule additions, not project-specific globs. |

### `doc/` Second-Level

| Path | Classification | Notes |
|------|---------------|-------|
| `PD-id-registry.json` | Always Consider Section-Shape | Compare metadata fields and prefix-entry schema. Reset counters. |
| `PD-documentation-map.md` | Always Consider Section-Shape | Compare section header structure (top-level `##`, sub-sections per phase). Do not sync project-specific entries. |
| `ci-cd/` | Ignore Content | Project-specific CI/CD docs. Consider Structure for presence only. |
| `documentation-tiers/` | Ignore Content | Project-specific tier docs. |
| `functional-design/` | Ignore Content | FDDs are project content. |
| `refactoring/` | Ignore Content | Refactoring plans are project content. |
| `state-tracking/` | Consider Structure | Presence required. |
| `state-tracking/audit/` | Consider Structure | Scaffolding required; audit tracking files inside are project content. |
| `state-tracking/features/` | Ignore Content | Feature state files are project-specific. |
| `state-tracking/permanent/` | Always Consider Section-Shape | Skeleton files: [`feature-tracking.md`](#feature-tracking-md), [`feature-request-tracking.md`](#feature-request-tracking-md), [`technical-debt-tracking.md`](#technical-debt-tracking-md), [`bug-tracking.md`](#bug-tracking-md), [`user-workflow-tracking.md`](#user-workflow-tracking-md), [`feature-dependencies.md`](#feature-dependencies-md). |
| `state-tracking/temporary/` | Ignore Content | Transient session state. |
| `state-tracking/validation/` | Consider Structure | Scaffolding required; validation reports inside are project content. |
| `technical-debt/` | Ignore Content | Debt assessments and items are project content. |
| `technical/` | Ignore Content | TDDs, ADRs are project content. |
| `user/` | Consider Structure | Verify expected sub-scaffolding (`handbooks/`, `quick-reference/`); handbook contents are project-specific. |
| `validation/` | Ignore Content | Validation reports are project content. Consider Structure for presence. |

### `test/` Second-Level

| Path | Classification | Notes |
|------|---------------|-------|
| `TE-id-registry.json` | Always Consider Section-Shape | Compare metadata fields and prefix-entry schema. Reset counters. |
| `TE-documentation-map.md` | Always Consider Section-Shape | Compare section header structure. Do not sync project-specific entries. |
| `archive/` | Ignore Content | Archived tests are project content. Consider Structure for presence. |
| `audits/` | Consider Structure | Verify all category subdirs exist (`foundation/`, `authentication/`, `core-features/`, `e2e/`, `performance/`). Audit reports inside are project content. |
| `audits/README.md` | Ignore Content | Project-managed README describing audit category taxonomy. Do not sync from project to blueprint. (Future: when [PF-IMP-010](/process-framework-central/state-tracking/permanent/process-improvement-tracking.md) lands and the README becomes auto-generated from `TE-id-registry.json` `TE-TAR.directories`, reclassify as Always Consider Section-Shape with auto-generation as the canonical state.) |
| `automated/` | Consider Structure | Verify all category subdirs exist (`unit/`, `integration/`, `parsers/`, `performance/`, `bug-validation/`). Test files inside are project content. |
| `automated/bug-validation/` | Consider Structure | Canonical category for PD-BUG-* regression validation scripts (per [test-infrastructure-guide.md:34](../03-testing/test-infrastructure-guide.md#L34)). Presence required; contents are project-specific (e.g., bug-reproduction scripts and regression test files). The blueprint must not contain a `test_procedures.md` or any other populated procedures doc — those are pure project content. |
| `e2e-acceptance-testing/` | Consider Structure | Presence required. |
| `e2e-acceptance-testing/templates/` | Consider Structure | Templates here are framework-canonical; if a new template is added in project, sync it (treat as Always Consider Section-Shape). |
| `specifications/` | Consider Structure | Verify `feature-specs/` and `cross-cutting-specs/` subdirs exist. Specs inside are project content. |
| `state-tracking/` | Consider Structure | Presence required. |
| `state-tracking/audit/` | Consider Structure | Scaffolding required; audit tracking files inside are project content. |
| `state-tracking/permanent/` | Always Consider Section-Shape | Skeleton files: [`test-tracking.md`](#test-tracking-md), [`e2e-test-tracking.md`](#e2e-test-tracking-md), [`performance-test-tracking.md`](#performance-test-tracking-md). |
| `state-tracking/temporary/` | Ignore Content | Transient session state. |

### Root Files

| File | Classification | Notes |
|------|---------------|-------|
| `CLAUDE.md` | Always Consider Section-Shape | Mostly framework-general; per-section review at the checkpoint. Project-specific snippets (project name, paths) must be stripped before sync. |
| `MEMORY.md` | Ignore Content | User-personal, never synced. |
| `README.md` | Ignore Content | Project-specific. |
| `.gitignore` | Always Consider Section-Shape | Sync framework-canonical patterns; do not sync project-specific entries. |
| `.pre-commit-config.yaml` | Always Consider Section-Shape | Sync framework-canonical hooks; do not sync project-specific paths. |
| Cross-project artifacts (e.g., `ratings.db`, `ratings.db.bak-*`) | Protected — Do Not Touch | Intentional cross-project shared artifacts. Listed under "Known Protected Artifacts" if extended in PF-TSK-087. **Require user confirmation before any DELETE action on populated DB/binary files at blueprint root.** |

## Skeleton-File Section-Shape Comparison

For each file tagged **Always Consider Section-Shape** above, compare these surfaces between project and blueprint. Sync structural drift; do not sync project-specific values.

> **🚨 Reset rule for template-backed files**: For any skeleton file with a corresponding framework template under `process-framework/templates/` (listed as `Template source:` in the entries below), the blueprint's canonical state is the **empty template**. Structural drift (new sections, new table columns, new taxonomy rows) is propagated into the template *and* the blueprint instance — never by copying the project's populated version. The reason this matters: a project's populated tracker can satisfy section-shape comparison while still carrying project-specific rows, populated counters, accumulated history, and project-name leakage. Treating "structurally equal" as "safe to sync" is what allowed LinkWatcher's `test_procedures.md` and tracker pollution to reach the appdev blueprint and propagate into TimeTrackingV2 at bootstrap. Verification: at PF-TSK-087 Step 11, blueprint state-tracking files must match the empty-template version (after placeholder substitution); see [PF-TSK-087 Step 11](../../tasks/support/framework-blueprint-sync-task.md#process).

### `process-improvement-tracking.md`

- Top-level section headers (`## Status Legend`, `## Task Routing`, `## Active Pilots`, `## Current Improvement Opportunities`, `## Completed Improvements`, `## Update History`)
- Status Legend table column count and headers
- Task Routing section presence and rule list
- Active Pilots section presence and table column shape
- Current Improvement Opportunities table columns
- Completed Improvements table columns

### `feature-tracking.md`

- Tier classification rows (Tier 1 / Tier 2 / Tier 3 + Foundation 0.x.x rules)
- Lifecycle status taxonomy
- Feature table columns
- Foundation Features section presence

### `feature-request-tracking.md`

- Section structure (Inbox / Classified / Deferred / Closed)
- Status taxonomy
- Table column shape

### `technical-debt-tracking.md`

- Registry vs. Resolved section split
- Status taxonomy
- Impact/Effort matrix headers
- Table column shape

### `bug-tracking.md`

- Status taxonomy
- Severity taxonomy
- Table column shape

### `user-workflow-tracking.md`

- Workflow ID prefix and table column shape
- Section structure

### `feature-dependencies.md`

- Auto-generation header (this is generated by `Update-FeatureDependencies.ps1` — verify the header matches)
- Mermaid graph block presence
- Priority matrix presence

### `test-tracking.md`

- **Canonical empty form**: the blueprint copy of `test/state-tracking/permanent/test-tracking.md` IS the canonical starter; no template file exists. The blueprint version must contain no project test rows, no Coverage Summary entries, no Testing Infrastructure rows, and no per-feature category sections beyond placeholder comments.
- Status Legend section presence and vocabulary
- Audit columns (3-column or 2-column variants)
- Test category sections
- Table column shape

### `e2e-test-tracking.md`

- **Canonical empty form**: the blueprint copy of `test/state-tracking/permanent/e2e-test-tracking.md` IS the canonical starter; no template file exists. The blueprint version must contain no Workflow Milestone rows and no E2E Test Case rows.
- Dual-status framework (acceptance status + audit status)
- Workflow Milestone Tracking table presence and columns
- Status Legend section
- Per-group test table column shape

### `performance-test-tracking.md`

- **Canonical empty form**: the blueprint copy of `test/state-tracking/permanent/performance-test-tracking.md` IS the canonical starter; no template file exists. The blueprint version must contain no Test Inventory rows; Summary table all zeroed.
- Status Legend section presence
- Level taxonomy (Component / Operation / Scale / Resource)
- Audit columns
- Per-level test table column shape

### `PF-id-registry.json` / `PD-id-registry.json` / `TE-id-registry.json` / `PF-id-registry-local.json`

- `metadata` field set (e.g., `id_gaps_policy` field — present in all four registries)
- `prefixes` block: each prefix entry's schema (`description`, `category`, `type`, `directories`, `nextAvailable`)
- Set of registered prefixes (sync new prefixes; reset `nextAvailable` to `1` in blueprint)

### `PF-documentation-map.md` / `PD-documentation-map.md` / `TE-documentation-map.md`

- Top-level section headers (`## Process Framework Documents`, `## Maintaining This Documentation`, etc.)
- Sub-section structure per phase (`#### 01 - Planning Tasks`, etc.)
- Section presence: Tasks / Templates / Guides / Scripts / Context Maps subsections

### `.linkwatcher-ignore` (in `process-framework-local/tools/linkWatcher/`)

- Top-level comment headers / section markers
- Framework-canonical rule patterns (do not sync project-specific globs)

### `CLAUDE.md`

- Top-level section structure (e.g., `## Project Overview`, `## Mandatory Workflow`, `## Session Startup Requirements`, `## Prohibited Git Commands`, `## PowerShell Script Execution`, `## Architecture Overview`, etc.)
- Per-section presence and ordering
- Project-specific snippets (project name, project-specific paths) must be stripped before sync

### `.gitignore` / `.pre-commit-config.yaml`

- Framework-canonical pattern blocks (sync these)
- Project-specific entries (do not sync)

## Updating This Policy

Add an entry to the [Coverage Tables](#coverage-tables) when:

- A new top-level or second-level directory is introduced in the framework (any project)
- A new skeleton file is added (registry, tracker, doc-map)
- A directory's purpose changes such that its classification flips (e.g., a previously project-only dir gains a skeleton README)
- A protected cross-project artifact is added at blueprint root

Add an entry to the [Skeleton-File Section-Shape Comparison](#skeleton-file-section-shape-comparison) section when a new file is tagged **Always Consider Section-Shape**.

This guide is referenced from PF-TSK-087 Step 5. Out-of-date classifications cause the same catch-up cycles this guide was created to prevent — keep it current.

## Related Resources

- [PF-TSK-087 framework-blueprint-sync](../../tasks/support/framework-blueprint-sync-task.md) — the consuming task
- [PF-TSK-087 Per-Directory Handling Rules](../../tasks/support/framework-blueprint-sync-task.md#per-directory-handling-rules) — the top-level rules this guide refines
