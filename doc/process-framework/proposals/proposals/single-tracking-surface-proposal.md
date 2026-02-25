---
id: PF-PRO-005
type: Process Framework
category: Proposal
version: 1.0
created: 2026-02-21
updated: 2026-02-21
proposal_name: Single Tracking Surface for Document Status
proposal_status: Deferred
source_improvement: IMP-037
---

# Single Tracking Surface for Document Status

## Document Metadata

| Metadata | Value |
|----------|-------|
| Document Type | Process Improvement Proposal |
| Created Date | 2026-02-21 |
| Status | Deferred |
| Source | [IMP-037 — Tools Review 2026-02-21](../../feedback/reviews/tools-review-20260221.md) |
| Author | AI Agent & Human Partner |

---

## 1. Problem Statement

Document status (FDD, TDD, ADR, Test Spec IDs and completion status) is currently tracked in **two independent surfaces** that must be kept in sync manually:

1. **[feature-tracking.md](../../state-tracking/permanent/feature-tracking.md)** — master table with one row per feature, columns for each document type
2. **Individual feature state files** (e.g., [0.1.1-core-architecture-implementation-state.md](../../state-tracking/features/0.1.1-core-architecture-implementation-state.md)) — Section 4 "Documentation Inventory" tables

This creates sync overhead: scripts must write to both surfaces, and when persistence fails (see IMP-033) or a manual update misses one surface, the two diverge with no automated detection.

### Overlap Matrix

| Data Point | feature-tracking.md | Feature state file (Section 4) |
|---|:---:|:---:|
| FDD ID + link | Column | Row |
| TDD ID + link | Column | Row |
| ADR ID + link | Column | Row |
| Test Spec ID + link | Column | Row |
| Tier Assessment link | Doc Tier column | Row |
| Overall status | Status column (emoji) | Section 2 (text) |

### How Drift Occurs

- A new TDD is created → state file Section 4 updated → feature-tracking.md not updated (or vice versa)
- Auto-update scripts claim success but persistence doesn't stick (IMP-033, now fixed but illustrates the fragility)
- `Validate-StateTracking.ps1` checks link validity but does not cross-check the two surfaces against each other

---

## 2. Recommended Solution: Auto-Generate feature-tracking.md

Make individual feature state files the **single source of truth**. feature-tracking.md becomes a **read-only generated view**.

### How It Works

```
Feature state files (9 files)     Generate-FeatureTrackingDocument.ps1
  ├─ YAML frontmatter ─────────►  ├─ Extract feature_id, feature_name
  ├─ Section 2 (status) ───────►  ├─ Map to status emoji
  ├─ Section 4 (doc inventory) ►  ├─ Extract FDD/TDD/ADR/TestSpec links
  └─ Section 6 (dependencies) ─►  ├─ Extract dependency list
                                   └─► Regenerate feature-tracking.md
                                        (including summary tables via
                                         existing Update-FeatureTrackingSummary)
```

### Why This Approach

- Feature state files are the natural **write point** — updated during task execution
- feature-tracking.md is the natural **read point** — consulted for overview/planning
- Making the read-only view auto-generated **eliminates all sync by design**
- `Update-FeatureTrackingSummary` in [FeatureTracking.psm1](../../scripts/Common-ScriptHelpers/FeatureTracking.psm1) already parses and regenerates summary tables — the pattern is established

### Alternative Considered: Master Table as Single Source

Remove Section 4 from state files; keep only feature-tracking.md. Rejected because:
- State files become less self-contained for task handover
- Loses per-document last-updated dates
- feature-tracking.md rows are already dense; adding more detail would make them unreadable

---

## 3. Change Inventory

### 3.1 Scripts

| Change | File | Description |
|--------|------|-------------|
| **New** | `Generate-FeatureTrackingDocument.ps1` | Scan `features/*.md`, parse YAML + Section 4, regenerate feature-tracking.md |
| Modify | [FeatureTracking.psm1](../../scripts/Common-ScriptHelpers/FeatureTracking.psm1) | Add `Get-FeatureStateFiles`, `Extract-DocumentationInventory` helper functions |
| Modify | [Update-BatchFeatureStatus.ps1](../../scripts/file-creation/Update-BatchFeatureStatus.ps1) | Call generation script after state file updates instead of `Update-FeatureTrackingStatus` |
| Modify | [Update-FeatureImplementationState.ps1](../../scripts/file-creation/Update-FeatureImplementationState.ps1) | Remove direct feature-tracking writes; call generation script |
| Modify | [New-FeatureImplementationState.ps1](../../scripts/file-creation/New-FeatureImplementationState.ps1) | Add optional `-RegenerateTracking` switch |
| Modify | [Validate-StateTracking.ps1](../../scripts/Validate-StateTracking.ps1) | Add cross-surface validation: state file Section 4 matches generated row |
| Modify | FDD/TDD/ADR creation scripts | Stop calling `Update-FeatureTrackingStatus` — generation picks up links from state file Section 4 automatically |

### 3.2 Task Definitions (~25 files)

Every task that currently says "Update feature-tracking.md with [link/status]" must change to "Update the feature state file; feature-tracking.md is auto-generated."

Key tasks affected:

| Task | Current Instruction | New Instruction |
|------|---|---|
| Feature Tier Assessment (PF-TSK-002) | Run `Update-FeatureTrackingFromAssessment.ps1` | Update state file Section 4 with assessment link; regenerate |
| FDD Creation (PF-TSK-013) | "Update feature-tracking with FDD link" | Automatic — generation reads Section 4 |
| TDD Creation (PF-TSK-015) | "Update feature-tracking with TDD link" | Automatic — generation reads Section 4 |
| ADR Creation | "Update feature-tracking with ADR link" | Automatic |
| Feature Implementation Planning (PF-TSK-044) | Set status to "In Progress" in feature-tracking | Set status in state file Section 2; regenerate |

### 3.3 Guides and Documentation (~13 files)

| Change | File |
|--------|------|
| **New** | `feature-tracking-autogeneration-guide.md` — algorithm, when to regenerate, parsing details |
| Update | [documentation-map.md](../../documentation-map.md) — mark feature-tracking.md as auto-generated |
| Update | [state-file-creation-guide.md](../../guides/guides/state-file-creation-guide.md) — state files as source of truth |
| Update | [task-transition-guide.md](../../guides/guides/task-transition-guide.md) — auto-generation workflow |
| Update | ~10 other guides referencing manual feature-tracking edits |

### 3.4 feature-tracking.md Itself

Add a header warning:
```yaml
# WARNING: AUTO-GENERATED — Do not edit manually.
# Source: doc/process-framework/state-tracking/features/*.md
# Regenerate: Generate-FeatureTrackingDocument.ps1
```

---

## 4. Data Gaps to Resolve

Feature state files currently lack some data present in feature-tracking.md:

| Data Point | In feature-tracking.md | In state files | Resolution |
|---|---|---|---|
| Priority (P1/P2) | Column | Not present | Add `priority` to YAML frontmatter |
| Dependencies (compact) | Column (`0.1.1, 0.1.2`) | Section 6 (prose) | Add `dependencies` list to YAML frontmatter |
| Notes (free text) | Column | Spread across sections | Add `tracking_notes` to YAML frontmatter |
| ADR column presence | Only in category 0 tables | Section 4 row (if exists) | Generation script detects ADR presence per category |

---

## 5. Implementation Estimate

| Session | Focus | Scope |
|---------|-------|-------|
| 1 | Core script + module functions | `Generate-FeatureTrackingDocument.ps1`, `FeatureTracking.psm1` helpers, YAML frontmatter additions to 9 state files |
| 2 | Script integration + validation | Modify Update-*/New-* scripts, update `Validate-StateTracking.ps1` |
| 3 | Documentation updates | Update 25+ task definitions, create autogeneration guide, update ~13 guides |

---

## 6. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Breaking 25+ task definitions if generation logic incomplete | HIGH | Implement and validate generation script first (Session 1), only update tasks after script is proven |
| Loss of manual Notes column content | MEDIUM | Add `tracking_notes` to YAML frontmatter before switching; migrate existing notes |
| Parsing fragility if state file format varies | MEDIUM | Validate Section 4 table format with `Validate-StateTracking.ps1` before generation |
| Performance (scanning 9 files each time) | LOW | 9 files < 500 lines each; negligible overhead |

---

## 7. Decision

**Status: Deferred** — Analysis complete, solution designed. Implementation to be scheduled when prioritized.

### To Implement

Select the **Process Improvement** task from [ai-tasks.md](/ai-tasks.md) and follow the 3-session plan in Section 5.

---

*This proposal was created to document IMP-037 findings. It is not a Framework Extension Concept — it is a focused process improvement affecting existing infrastructure.*
