---
id: PF-PRO-018
type: Document
category: General
version: 1.0
created: 2026-04-10
updated: 2026-04-10
---

# Structure Change Proposal Template

## Overview
Restructure feature-tracking.md Implementation Status from last-completed to next-action statuses

**Structure Change ID:** SC-PENDING
**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-04-10
**Target Implementation Date:** 2026-04-10

## Current Structure

The `feature-tracking.md` Implementation Status legend uses **last-completed** statuses — each status describes the most recent milestone achieved:

| Symbol | Current Status |
|--------|---------------|
| ⬜ | Not Started |
| 📊 | Assessment Created |
| 📋 | FDD Created |
| 🏗️ | Architecture Reviewed |
| 📝 | TDD Created |
| 🟡 | In Progress |
| 🧪 | Testing |
| 👀 | Ready for Review |
| 🟢 | Completed |
| 🔄 | Needs Revision |

### Example of Current Structure
```markdown
| [0.1.1](...) | Core Architecture | 📋 ADR Created | P1 | ...
| [6.1.1](...) | Link Validation   | 🔄 Needs Revision | P2 | ...
```

An AI agent reading "📋 ADR Created" must consult the Task Transition Guide or traceability doc to determine which task to pick up next.

## Proposed Structure

Replace the Implementation Status legend with **next-action** statuses — each status tells the reader what needs to happen next:

| Symbol | New Status | Implies Completed | Next Task |
|--------|-----------|-------------------|-----------|
| ⬜ | Needs Assessment | Feature added | PF-TSK-002 Feature Tier Assessment |
| 📋 | Needs FDD | Assessment (Tier 2+ only) | PF-TSK-027 FDD Creation |
| 📝 | Needs TDD | Assessment (T1) or FDD (T2+) | PF-TSK-015 TDD Creation |
| 🧪 | Needs Test Spec | TDD | PF-TSK-012 Test Spec Creation |
| 🔧 | Needs Impl Plan | Test Spec | PF-TSK-044 Implementation Planning |
| 🟡 | In Progress | Impl Plan created | Per impl state file sequence |
| 👀 | Needs Review | Implementation | PF-TSK-005 Code Review |
| 🟢 | Completed | Code Review passed | — |
| 🔄 | Needs Enhancement | Enhancement scoped | PF-TSK-068 Feature Enhancement |

### Key design decisions

1. **Tier-dependent routing baked into scripts, not status.** When Assessment completes, the update script checks the tier: Tier 2+ → `Needs FDD`; Tier 1 → `Needs TDD` directly.
2. **Parallel design tasks gated by scripts, not separate statuses.** ADR, API Design, and DB Schema Design are parallel planning tasks with clear trigger rules. The script checks their completion before advancing the primary status:
   - **ADR** (PF-TSK-028): Required when Feature ID = `0.x.x` (foundation). Script checks ADR column has a link before advancing past design phase.
   - **API Design** (PF-TSK-020): Required when API Design column = `Yes`. Script checks API Design column has a link before advancing.
   - **DB Schema Design** (PF-TSK-021): Required when DB Design column = `Yes`. Script checks DB Design column has a link before advancing.

   Note: API Design and DB Design columns do not yet exist in feature-tracking.md (no current feature needs them). The script should handle their absence gracefully and gate only when columns exist and are set to `Yes`.
3. **"In Progress" is the only non-specific status.** Detailed task sequence lives in the feature implementation state file.
4. **Implied completion chain.** Each status confirms all prior steps: "Needs Test Spec" inherently means TDD is done, FDD is done (if applicable), Assessment is done, and all required parallel design tasks are done.
5. **Removed statuses**: "🏗️ Architecture Reviewed" (tracked in ADR column), "🧪 Testing" (merged into "In Progress" — detail in impl state file).

### Example of Proposed Structure
```markdown
| [0.1.1](...) | Core Architecture | 🟢 Completed       | P1 | ...
| [6.1.1](...) | Link Validation   | 🔄 Needs Enhancement | P2 | ...
```

## Rationale

### Benefits
- **Immediate actionability** — AI agent reads status, knows exactly which task to select. No cross-referencing needed
- **Closes framework gaps** — Resolves "No post-planning status" (Medium) and "Decomposed impl tasks don't update feature-tracking" (Medium) gaps from task-trigger-output-traceability.md
- **No information loss** — Each "Needs X" status implicitly confirms all prior milestones
- **Script-encoded routing** — Tier-dependent next steps are determined by automation, not AI judgment

### Challenges
- **Large ripple** — ~40 files must be updated atomically (scripts, task definitions, infrastructure docs, state files)
- **Breaking change** — PowerShell `ValidateSet` constraints will reject old values until updated
- **Historical state files** — Archived validation tracking files contain old status references (acceptable — they are historical records)

## Affected Files

### Scripts (14 files)

| File | Change Type | Status Values Referenced |
|------|------------|------------------------|
| `scripts/Common-ScriptHelpers/FeatureTracking.psm1` | Content update | Status string matching |
| `scripts/file-creation/01-planning/New-Assessment.ps1` | Content update | Sets "Assessment Created" → must set next-action status |
| `scripts/file-creation/02-design/New-FDD.ps1` | Content update | Sets "FDD Created" → must set next-action status |
| `scripts/file-creation/02-design/New-TDD.ps1` | Content update | Sets "TDD Created" → must set next-action status |
| `scripts/file-creation/02-design/New-ArchitectureAssessment.ps1` | Content update | Sets "Architecture Reviewed" |
| `scripts/update/Update-FeatureTrackingFromAssessment.ps1` | Content update | Validates/sets assessment statuses |
| `scripts/update/Update-CodeReviewState.ps1` | Content update | "Ready for Review" → "Completed" / "Needs Revision" |
| `scripts/update/Update-FeatureImplementationState.ps1` | Content update | Implementation status transitions |
| `scripts/update/Update-FeatureRequest.ps1` | Content update | Sets "Needs Revision" for enhancements |
| `scripts/update/Update-BatchFeatureStatus.ps1` | Content update | ValidateSet of allowed statuses |
| `scripts/update/Finalize-Enhancement.ps1` | Content update | Enhancement status transitions |
| `scripts/validation/Validate-StateTracking.ps1` | Content update | Validates status values |
| `scripts/Start-AutomationMenu.ps1` | Content update | Menu references statuses |
| `scripts/AUTOMATION-USAGE-GUIDE.md` | Content update | Documents status values |

### Task Definitions (11 files)

| File | Change Type |
|------|------------|
| `tasks/01-planning/feature-tier-assessment-task.md` | Output status: "Assessment Created" → next-action |
| `tasks/01-planning/feature-request-evaluation.md` | Sets "Needs Revision" → "Needs Enhancement" |
| `tasks/01-planning/system-architecture-review.md` | Sets "Architecture Reviewed" → remove from primary chain |
| `tasks/02-design/fdd-creation-task.md` | Output status: "FDD Created" → next-action |
| `tasks/02-design/tdd-creation-task.md` | Output status: "TDD Created" → next-action |
| `tasks/04-implementation/feature-enhancement.md` | Trigger: "Needs Revision" → "Needs Enhancement" |
| `tasks/04-implementation/feature-implementation-planning-task.md` | Trigger statuses, output status |
| `tasks/04-implementation/foundation-feature-implementation-task.md` | Output: "Ready for Review" → "Needs Review" |
| `tasks/06-maintenance/code-review-task.md` | Trigger/output statuses |
| `tasks/06-maintenance/code-refactoring-standard-path.md` | Status references |
| `tasks/00-setup/codebase-feature-analysis.md` | Status references |

### Infrastructure & Guides (4 files)

| File | Change Type |
|------|------------|
| `infrastructure/task-trigger-output-traceability.md` | 26 status references in trigger chain |
| `infrastructure/process-framework-task-registry.md` | Status references |
| `guides/framework/task-transition-guide.md` | Status-based routing logic |
| `guides/support/state-file-creation-guide.md` | Status references |

### State Tracking & Visualization (11 files)

| File | Change Type |
|------|------------|
| `doc/state-tracking/permanent/feature-tracking.md` | Legend + all data rows |
| `doc/state-tracking/permanent/feature-request-tracking.md` | Status references |
| `doc/state-tracking/features/6.1.1-Link Validation-implementation-state.md` | Parent status reference |
| `doc/state-tracking/validation/validation-tracking-3.md` | Historical — update if active |
| `doc/state-tracking/validation/validation-tracking-4.md` | Historical — update if active |
| `doc/state-tracking/temporary/old/enhancement-ignored-patterns-configuration.md` | Historical — skip |
| `doc/state-tracking/validation/archive/validation-tracking-2.md` | Historical — skip |
| `doc/state-tracking/validation/archive/validation-tracking-3.md` | Historical — skip |
| `visualization/context-maps/00-setup/retrospective-documentation-creation-map.md` | Status references |
| `visualization/context-maps/04-implementation/feature-enhancement-map.md` | Status references |
| `visualization/context-maps/01-planning/feature-request-evaluation-map.md` | Status references |

## Migration Strategy

### Phase 1: Core update (feature-tracking.md + scripts)

Scripts and feature-tracking.md must be updated atomically — if scripts emit new status values but the legend still has old values (or vice versa), `Validate-StateTracking.ps1` will fail.

1. Update `feature-tracking.md` Implementation Status legend
2. Update all feature data rows (6 Completed stay as-is; 0.1.1 and 6.1.1 need new status)
3. Update `FeatureTracking.psm1` helper module
4. Update all 13 scripts that set/validate status values
5. Run `Validate-StateTracking.ps1` to confirm no errors

### Phase 2: Task definitions + infrastructure

6. Update 11 task definitions (output/trigger status references)
7. Update `task-trigger-output-traceability.md` (26 status references + State File Trigger Index)
8. Update `process-framework-task-registry.md`
9. Update 2 guides (task-transition-guide, state-file-creation-guide)

### Phase 3: State tracking + visualization + cleanup

10. Update active validation tracking files (3/4)
11. Update feature state files (6.1.1)
12. Update 3 context maps
13. Skip archived/historical files (they record what was true at the time)
14. Update `feature-tracking.md` Progress Summary section

## Task Modifications

### Feature Tier Assessment (PF-TSK-002)

**Changes needed:**
- Output status: "📊 Assessment Created" → determine next-action based on tier: "📋 Needs FDD" (Tier 2+) or "📝 Needs TDD" (Tier 1)
- Script `New-Assessment.ps1` encodes the routing logic

**Rationale:** This is the key branching point where tier determines the next status.

### FDD Creation (PF-TSK-027)

**Changes needed:**
- Output status: "📋 FDD Created" → "📝 Needs TDD"

**Rationale:** After FDD is created, the next step is always TDD creation.

### TDD Creation (PF-TSK-015)

**Changes needed:**
- Output status: "📝 TDD Created" → "🧪 Needs Test Spec"

**Rationale:** After TDD is created, the next step is test specification creation.

### System Architecture Review (PF-TSK-019)

**Changes needed:**
- Remove "🏗️ Architecture Reviewed" from primary status chain
- Architecture review completion tracked in ADR column
- Script gates primary status advancement: for foundation features (0.x.x), ADR column must have a link before advancing past the design phase

**Rationale:** Architecture Review is a parallel design task with a clear rule (foundation features require it). Like API Design and DB Design, it gates advancement through the primary chain without having its own primary status.

### ADR Creation (PF-TSK-028)

**Changes needed:**
- No longer sets a primary status ("🏗️ Architecture Reviewed" removed)
- Populates ADR column with link only
- Primary status advances when the update script detects ADR column is populated (for foundation features)

**Rationale:** ADR is a parallel gating task, not a primary chain milestone.

### Feature Request Evaluation (PF-TSK-067)

**Changes needed:**
- Enhancement status: "🔄 Needs Revision" → "🔄 Needs Enhancement"
- New feature status: "⬜ Not Started" → "⬜ Needs Assessment"

**Rationale:** Label clarification to match next-action semantics.

### Code Review (PF-TSK-005)

**Changes needed:**
- Trigger: "👀 Ready for Review" → "👀 Needs Review"
- Pass output: "🟢 Completed" (unchanged)
- Fail output: "🔄 Needs Revision" → context-dependent: either "🔄 Needs Enhancement" or back to an earlier next-action status

**Rationale:** Match new labels.

### Feature Enhancement (PF-TSK-068)

**Changes needed:**
- Trigger: "🔄 Needs Revision" → "🔄 Needs Enhancement"

**Rationale:** Label change only.

### Foundation Feature Implementation (PF-TSK-024)

**Changes needed:**
- Output status: "👀 Ready for Review" → "👀 Needs Review"

**Rationale:** Label change only.

### Feature Implementation Planning (PF-TSK-044)

**Changes needed:**
- Trigger: "📋 Specs Created" or "📝 TDD Created" → "🔧 Needs Impl Plan"
- Output: set status to "🟡 In Progress"

**Rationale:** Closes the "No post-planning status" gap.

## Handover Interfaces

| From Task | To Task | Interface | Change |
|-----------|---------|-----------|--------|
| PF-TSK-002 | PF-TSK-027 or PF-TSK-015 | `feature-tracking.md` Status column | Modified: script now sets tier-dependent next-action |
| PF-TSK-027 | PF-TSK-015 | `feature-tracking.md` Status column | Modified: "FDD Created" → "Needs TDD" |
| PF-TSK-015 | PF-TSK-012 | `feature-tracking.md` Status column | Modified: "TDD Created" → "Needs Test Spec" |
| PF-TSK-012 | PF-TSK-044 | `feature-tracking.md` Status column | Modified: "Specs Created" → "Needs Impl Plan" |
| PF-TSK-044 | PF-TSK-078/051/024 | `feature-tracking.md` Status column | New: "Needs Impl Plan" → "In Progress" |
| PF-TSK-078/024 | PF-TSK-005 | `feature-tracking.md` Status column | Modified: "Ready for Review" → "Needs Review" |

## Testing Approach

### Test Cases
- Run `Validate-StateTracking.ps1` after Phase 1 — 0 errors expected
- Run each updated script with `-WhatIf` to verify correct status values
- Verify `Update-BatchFeatureStatus.ps1` accepts all new status values via `ValidateSet`

### Success Criteria
- `Validate-StateTracking.ps1` passes with 0 errors across all surfaces
- All scripts accept new status values without `ValidateSet` rejections
- Feature-tracking.md legend matches all status values in data rows
- Task-trigger-output-traceability.md State File Trigger Index reflects new status values

## Rollback Plan

### Trigger Conditions
- `Validate-StateTracking.ps1` reports errors that cannot be resolved
- Scripts fail with unexpected status value rejections

### Rollback Steps
1. All changes are in uncommitted working tree — `git diff HEAD` shows full delta
2. Revert specific files with `git show HEAD:<file> > file` if needed
3. Status values are plain strings — no database migration or binary format change

## Approval

**Approved By:** _________________
**Date:** 2026-04-10

**Comments:**
