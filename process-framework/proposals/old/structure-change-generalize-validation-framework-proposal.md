---
id: PF-PRO-010
type: Document
category: General
version: 1.0
created: 2026-03-23
updated: 2026-03-23
---

# Proposal: Generalize Validation Framework

## Overview

Transform the current "foundational-only" 6-type validation framework into a **reusable, project-agnostic validation system** with a configurable dimension catalog and explicit preparation workflow. This proposal merges two related changes:

1. **Generalization** — Remove "foundational" hardcoding from existing tasks, guides, templates, and scripts (partially complete)
2. **Framework extension** — Add a Validation Preparation task, establish a dimension catalog in the guide, and define how new dimension tasks are created

**Proposal ID:** PF-PRO-010
**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-03-23

## Current Structure

### How validation works today

- **6 hardcoded tasks** (PF-TSK-031–036), one per validation dimension, scoped to "foundational features"
- **No preparation step** — which features to validate and which dimensions to apply is decided ad-hoc
- **One tracking file** — `foundational-validation-tracking.md` in `state-tracking/temporary/`, hardcoded to the 9 LinkWatcher foundational features × 6 dimensions
- **No dimension catalog** — the 6 dimensions exist only as separate task definitions with no unified reference
- **Adding a dimension** requires creating a new task, but no guidance exists for this

### Current validation dimensions

| # | Dimension | Task ID |
|---|-----------|---------|
| 1 | Architectural Consistency | PF-TSK-031 |
| 2 | Code Quality & Standards | PF-TSK-032 |
| 3 | Integration & Dependencies | PF-TSK-033 |
| 4 | Documentation Alignment | PF-TSK-034 |
| 5 | Extensibility & Maintainability | PF-TSK-035 |
| 6 | AI Agent Continuity | PF-TSK-036 |

### Current workflow

```
(ad-hoc decision) → Run dimension task → Generate report → Update tracking
```

## Proposed Structure

### Design principles

1. **One task per dimension** — retained; each dimension has a distinct AI agent role, execution approach, and criteria that benefit from independent improvement
2. **Per-dimension validation** — retained; validating one dimension across a feature group reveals cross-feature inconsistencies, which is the primary value
3. **Explicit preparation step** — new; a Validation Preparation task creates the tracking file and decides which features × dimensions to validate
4. **Dimension catalog in guide** — new; the Feature Validation Guide maintains the master list of available dimensions with descriptions, applicability criteria, and links to their tasks
5. **Variable dimension set** — new; not every feature needs all dimensions; the preparation task records the selection rationale

### Proposed validation dimensions

| # | Dimension | Status | Applicability |
|---|-----------|--------|---------------|
| 1 | Architectural Consistency | Existing (PF-TSK-031) | Universal — all projects |
| 2 | Code Quality & Standards | Existing (PF-TSK-032) | Universal — all projects |
| 3 | Integration & Dependencies | Existing (PF-TSK-033) | Universal — all projects |
| 4 | Documentation Alignment | Existing (PF-TSK-034) | Universal — all projects |
| 5 | Extensibility & Maintainability | Existing (PF-TSK-035) | Widely applicable — growing projects |
| 6 | AI Agent Continuity | Existing (PF-TSK-036) | AI-assisted development workflows |
| 7 | Security & Data Protection | **New — to create** (PF-TSK-071) | Most projects (web, API, auth, data) |
| 8 | Performance & Scalability | **New — to create** (PF-TSK-072) | Production systems, real-time, high-load |
| 9 | Observability | **New — to create** (PF-TSK-073) | Production systems with monitoring needs |
| 10 | Accessibility / UX Compliance | **New — to create** (PF-TSK-074) | UI-focused projects |
| 11 | Data Integrity | **New — to create** (PF-TSK-075) | Data-heavy projects, migrations |

The dimension catalog is **bounded** (~10-12 total dimensions covers the full universe of software quality attributes). New dimensions are rare after the initial catalog is established.

### Proposed workflow

```
Validation Preparation (new task)
  ├── Select feature scope
  ├── Evaluate each feature against dimension catalog
  ├── Record dimension selection + rationale in tracking file
  └── Plan session sequence
      │
      ├── Dimension Task A (e.g., Architectural Consistency)
      │   └── Validate feature group → Report → Update tracking
      │
      ├── Dimension Task B (e.g., Code Quality)
      │   └── Validate feature group → Report → Update tracking
      │
      └── ... (repeat for selected dimensions)
```

### Tracking file structure (per validation round)

Created by Validation Preparation task using the `validation-tracking-template.md`:

| Feature | Arch | Quality | Integration | Docs | Extensibility | AI Continuity | Security | ... |
|---------|------|---------|-------------|------|---------------|---------------|----------|-----|
| X.Y.Z   | ⏳   | ⏳      | ⏳          | ⏳   | N/A           | ⏳            | ⏳       | ... |

Columns vary per validation round — only selected dimensions appear. "N/A" marks dimensions explicitly excluded for a feature.

## Rationale

### Benefits

- **Reusable across projects** — same framework works for LinkWatcher, Breakout Buddies, or any future project
- **Iterative template improvement** — shared templates and guide improve with every validation round
- **Explicit dimension selection** — decisions about what to validate are traceable, not ad-hoc
- **Bounded dimension catalog** — ~10-12 dimensions covers essentially all software quality attributes; adding new ones is rare
- **Independent task improvement** — each dimension task evolves toward excellence in its domain without compromising others
- **Project-specific customization** — projects select which dimensions matter; no forced overhead for irrelevant dimensions

### Challenges

- **Task creation overhead for new dimensions** — each new dimension requires PF-TSK-001 (New Task Creation), context map, and guide section. Estimated ~1 session per new dimension.
- **More tasks to maintain** — growing from 6 to 8-11 dimension tasks means more entries in documentation-map, ai-tasks.md, and task registry
- **Preparation task adds a session** — one extra session before validation begins (mitigated by lightweight path for small projects)
- **Cross-dimension consistency** — independent task evolution may cause structural drift (mitigated by the guide's catalog providing the unifying reference)

## Affected Files

### Already Changed (Phase 1 — Generalization, partially complete)

| Category | Files | Status |
|----------|-------|--------|
| Task definitions (6) | `tasks/05-validation/*.md` | ✅ Done |
| Context maps (6) | `visualization/context-maps/05-validation/*.md` | ✅ Done |
| Validation guide (1) | Renamed to `feature-validation-guide.md`, content generalized | ✅ Done |

### Remaining from Phase 1

| Category | Files |
|----------|-------|
| Templates | `templates/05-validation/validation-report-template.md` (edit "foundational" references) |
| Templates | `templates/05-validation/foundational-validation-tracking.md` (rename to `validation-tracking-template.md`, generalize content) |
| Templates | `templates/05-validation/validation-tracking-template.md` (DELETE — the abstract placeholder version is inferior to the pre-filled one) |
| Scripts (5) | `Run-FoundationalValidation.ps1`, `Quick-ValidationCheck.ps1`, `New-ValidationReport.ps1`, `Generate-ValidationSummary.ps1`, `Update-ValidationReportState.ps1` |
| Registries | `PF-documentation-map.md`, `ai-tasks.md`, `infrastructure/process-framework-task-registry.md` |

### Template decision: which tracking template to keep

**Decision**: Keep `foundational-validation-tracking.md` (PF-TEM-051), rename and generalize it. Delete `validation-tracking-template.md` (no registered ID).

**Rationale**: The foundational template has a registered ID, pre-filled dimension names (which are the core defaults), and is immediately usable after filling feature rows. The abstract template requires replacing 50+ generic placeholders (`[VALIDATION_TYPE_1]`, `[VAL_TYPE_1_SHORT]`, etc.) — busywork that the pre-filled template avoids. The renamed template will note that dimensions can be added/removed per project.

### Guide decision: one guide vs per-task guides

**Decision**: Keep one unified `feature-validation-guide.md`. Do not create per-dimension guides.

**Rationale**: 80% of guide content is shared (scoring system, session planning, report workflow, troubleshooting). Dimension-specific criteria already live in the task definitions themselves (AI agent role, execution steps). Per-task guides would duplicate the shared content and diverge over time. The single guide gains a Dimension Catalog section as the unifying reference.

### Phase 2 — Framework Extension (new work)

| Category | Action |
|----------|--------|
| New task | Create **Validation Preparation** task (PF-TSK-001 process) |
| Guide update | Add **Dimension Catalog** section to `feature-validation-guide.md` |
| Template update | Generalize renamed `validation-tracking-template.md` to support variable dimension columns |
| New dimension tasks (5) | Create all remaining dimensions as tasks: Security & Data Protection (PF-TSK-071), Performance & Scalability (PF-TSK-072), Observability (PF-TSK-073), Accessibility / UX Compliance (PF-TSK-074), Data Integrity (PF-TSK-075) |
| Workflow updates | Update `ai-tasks.md` common workflows to include Validation Preparation → Dimension Tasks flow |
| Task transition guide | Add validation workflow to task-transition-guide.md |

## Migration Strategy

### Phase 1: Complete Generalization (current session)

- Finish remaining file edits (validation-report-template, scripts, registries)
- Rename `foundational-validation-tracking.md` → `validation-tracking-template.md` (generalize content)
- Delete redundant abstract `validation-tracking-template.md`
- Verify no remaining "foundational" references in validation context

### Phase 2: Create All Dimension Tasks (next session)

- Create 5 new validation dimension tasks: Security & Data Protection (PF-TSK-071), Performance & Scalability (PF-TSK-072), Observability (PF-TSK-073), Accessibility / UX Compliance (PF-TSK-074), Data Integrity (PF-TSK-075)
- Create context maps for each new dimension task
- Update `ai-tasks.md`, `PF-documentation-map.md`, and task registry with new tasks

### Phase 3: Validation Preparation Task & Guide Updates (future session)

- Create Validation Preparation task definition via PF-TSK-001
- Add Dimension Catalog section to `feature-validation-guide.md` (all 11 dimensions with applicability criteria)
- Update renamed `validation-tracking-template.md` to support variable dimension columns
- Update common workflows in `ai-tasks.md` and task-transition-guide

## New Tasks

### Validation Preparation (05-validation)

**Purpose:** Plan a validation round by selecting features and applicable dimensions, then create the tracking state file with the feature×dimension matrix.

**When to Use:**
- Before starting a new validation round for any set of features
- When new features reach implementation-complete status and need validation
- When establishing validation baselines for a new project

**AI Agent Role:**
- **Role**: Quality Assurance Planner
- **Mindset**: Systematic, scope-aware, risk-based prioritization
- **Focus Areas**: Feature maturity assessment, dimension applicability, session planning
- **Communication Style**: Present dimension selection rationale, ask about project-specific quality priorities

**Process (high-level):**
1. Identify features to validate (from feature tracking — filter by status, priority, or category)
2. For each feature, evaluate which dimensions apply using the Dimension Catalog criteria in the Feature Validation Guide
3. Create validation tracking state file using `validation-tracking-template.md` with selected features × dimensions
4. Plan session sequence — which dimension tasks to run, in what order, with which feature batches
5. Checkpoint: present validation plan (feature scope, dimension selection, session plan) for human approval

**Outputs:**
- Validation tracking state file (in `state-tracking/temporary/`)
- Validation plan with session sequence and rationale

**Workflow position:**
- Precedes all dimension validation tasks (PF-TSK-031–036 and future dimension tasks)
- Triggered by: feature implementations reaching complete/testing status, milestone reviews, quarterly assessments

## Handover Interfaces

| From Task | To Task | Interface | Change |
|-----------|---------|-----------|--------|
| Validation Preparation (new) | All dimension tasks (PF-TSK-031–036+) | Validation tracking state file | **New** — preparation task creates the file; dimension tasks read and update it |
| Feature Implementation tasks | Validation Preparation (new) | Feature tracking (implementation status) | **New** — preparation task reads feature status to determine validation scope |
| Dimension tasks (PF-TSK-031–036) | Technical Debt Tracking | Tech debt items | Unchanged |

### Additional Tasks to Review

- **Task Transition Guide** — Add validation preparation → dimension task flow
- **Common Workflows in ai-tasks.md** — Add validation workflow section
- **Feature Tracking** — Consider adding a "Validation Status" column (future enhancement)

## Testing Approach

### Success Criteria

- Zero remaining "foundational" references in active validation files (Phase 1)
- Validation Preparation task can create a tracking file for an arbitrary set of features with variable dimensions (Phase 2)
- Existing dimension tasks work unchanged with the new tracking file format (Phase 2)
- New dimension task (Security) follows the same structure as existing ones (Phase 3)
- `Validate-StateTracking.ps1` passes with 0 errors after all changes

## Approval

**Status:** ✅ Implemented (all 3 phases complete — 2026-03-23)

**Key decisions requiring approval:**
1. Confirm the per-dimension task approach (vs single unified task)
2. Confirm Validation Preparation as a new task (vs informal planning)
3. Confirm the proposed dimension catalog scope (6 existing + 2 new + 3 future)
4. Confirm Phase 1 completion before Phase 2 begins
