---
id: PD-STA-063
type: Document
category: General
version: 1.0
created: 2026-03-23
updated: 2026-03-23
change_name: generalize-validation-framework
---

# Structure Change State: Generalize Validation Framework

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of structure change. Move to `process-framework-local/state-tracking/temporary/old` after all changes are implemented and validated.

## Structure Change Overview
- **Change Name**: Generalize Validation Framework
- **Change Type**: Content Generalization + Framework Extension
- **Proposal**: [PF-PRO-010](../../../proposals/old/structure-change-generalize-validation-framework-proposal.md)
- **Scope**: Two-part change:
  1. **Phase 1 (Generalization)**: Replace "foundational"-specific language so the framework is reusable across any feature set
  2. **Phase 2 (Framework Extension)**: Add Validation Preparation task, dimension catalog, and support for new dimension tasks
- **Rationale**: Reusable validation templates across projects; explicit preparation step for dimension selection; bounded dimension catalog (~10-12 total)
- **Started**: 2026-03-23

## Phase 1: Generalization — Progress

### Completed

| Category | Files | Status |
|----------|-------|--------|
| Task definitions (6) | `tasks/05-validation/*.md` | ✅ All 6 generalized |
| Context maps (6) | `visualization/context-maps/05-validation/*.md` | ✅ All 6 generalized |
| Validation guide (1) | `guides/05-validation/foundational-validation-guide.md` → `feature-validation-guide.md` | ✅ Renamed + content generalized, LinkWatcher updated 3 refs |

### Phase 1 Remaining — ✅ ALL COMPLETE

| Category | Files | Status |
|----------|-------|--------|
| Templates | `validation-report-template.md` | ✅ Generalized |
| Templates | `foundational-validation-tracking.md` → `validation-tracking-template.md` | ✅ Renamed + generalized (PF-TEM-051) |
| Templates | `validation-tracking-template.md` (abstract, no ID) | ✅ Deleted |
| Scripts (5) | All 5 validation scripts | ✅ Content generalized |
| Registries | `PF-documentation-map.md`, `ai-tasks.md`, `task-registry`, `tasks/README.md` | ✅ Updated |
| Additional | `task-transition-guide.md`, refactoring paths, lightweight template | ✅ Updated |

## Phase 2: Create All Dimension Tasks — ✅ ALL COMPLETE

| Deliverable | Task ID | Status |
|-------------|---------|--------|
| Security & Data Protection validation | PF-TSK-072 | ✅ Created + customized |
| Performance & Scalability validation | PF-TSK-073 | ✅ Created + customized |
| Observability validation | PF-TSK-074 | ✅ Created + customized |
| Accessibility / UX Compliance validation | PF-TSK-075 | ✅ Created + customized |
| Data Integrity validation | PF-TSK-076 | ✅ Created + customized |
| Context maps for new tasks (5) | PF-VIS-051–055 | ✅ Created + customized |
| Update ai-tasks.md, documentation-map, task registry | — | ✅ Updated |

> **Note**: Task IDs shifted by +1 from planned (PF-TSK-071–075 → PF-TSK-072–076) because the ID counter was already at 72 when creation started.

## Phase 3: Validation Preparation & Guide Updates — ✅ ALL COMPLETE

| Deliverable | Method | Status |
|-------------|--------|--------|
| Validation Preparation task | PF-TSK-077 via PF-TSK-001 Lightweight | ✅ Created + customized |
| Validation Preparation context map | PF-VIS-056 via New-ContextMap.ps1 | ✅ Created + customized |
| Dimension Catalog in guide | Added to `feature-validation-guide.md` | ✅ Complete (11 dimensions with applicability criteria) |
| Update validation guide | Updated overview, matrix structure, related resources | ✅ Complete |
| Update common workflows | `ai-tasks.md` — added "For Feature Validation" workflow | ✅ Complete |
| Update task-transition-guide | Updated Feature Validation section with preparation step + 11 dimensions | ✅ Complete |
| Update documentation-map | Added Validation Preparation task + context map entries | ✅ Complete |
| Update process-framework/ai-tasks.md | Added Validation Preparation as entry point with 🟢 Simple | ✅ Complete |

## Key Design Decisions

1. **One task per dimension** — retained; each dimension has distinct AI agent role, execution approach, and criteria
2. **Per-dimension validation** (not per-feature) — validates one dimension across a feature group to reveal cross-feature inconsistencies
3. **Validation Preparation task** — new task owns feature scope selection, dimension applicability evaluation, and tracking file creation
4. **Dimension catalog bounded** — 11 dimensions covers all software quality attributes; new ones are rare after initial catalog
5. **Not every feature needs all dimensions** — preparation task records selection rationale per feature
6. **Keep pre-filled tracking template** — rename `foundational-validation-tracking.md` (PF-TEM-051) to `validation-tracking-template.md`; delete the abstract placeholder version
7. **One unified guide** — `feature-validation-guide.md` serves all dimensions; dimension-specific criteria live in the task definitions

## Session Log

### Session 1: 2026-03-23
**Completed**:
- Scope assessment (Full process, ~22 files)
- Generalized all 6 validation task definitions
- Generalized all 6 validation context maps
- Renamed `foundational-validation-guide.md` → `feature-validation-guide.md` (LinkWatcher handled refs)
- Generalized all content in feature-validation-guide.md

**Conceptual discussion**: Clarified validation approach:
- Per-dimension validation (not per-feature) — better for cross-feature pattern detection
- Validation Preparation task — owns feature scope selection and dimension applicability
- Keep separate tasks per dimension — distinct AI agent roles and improvement paths
- Created proposal [PF-PRO-010](../../../proposals/old/structure-change-generalize-validation-framework-proposal.md)

**Additional decisions** (post-proposal):
- Keep `foundational-validation-tracking.md` (PF-TEM-051), rename + generalize; delete abstract `validation-tracking-template.md`
- Keep one unified guide (not per-task) — dimension criteria live in task definitions
- Create ALL 5 new dimension tasks now (Security, Performance, Observability, Accessibility, Data Integrity) — not "future consideration"
- Updated proposal and state tracking with these decisions

**Phase 1 completed** — all generalization work done

**Next session**: Phase 2 — create 5 new dimension tasks + context maps

### Session 2: 2026-03-23
**Completed**:
- Fixed bug in `New-Task.ps1` (wrong template path: `doc/templates/templates` → `process-framework/templates/support`)
- Created 5 new dimension task definitions via PF-TSK-001 Lightweight Mode:
  - PF-TSK-072: Security & Data Protection Validation
  - PF-TSK-073: Performance & Scalability Validation
  - PF-TSK-074: Observability Validation
  - PF-TSK-075: Accessibility / UX Compliance Validation
  - PF-TSK-076: Data Integrity Validation
- Created 5 context maps (PF-VIS-051–055) for all new tasks
- Customized all 10 files with dimension-specific content following existing validation task patterns
- Updated registries: ai-tasks.md, documentation-map.md, task-registry.md
- Fixed auto-generated task names in process-framework/ai-tasks.md (added `&` and `/` symbols)

**Phase 3 completed in same session (continued below)**

### Session 2 continued: Phase 3
**Completed**:
- Created Validation Preparation task (PF-TSK-077) via PF-TSK-001 Lightweight Mode
- Created Validation Preparation context map (PF-VIS-056)
- Added Dimension Catalog section to `feature-validation-guide.md` (all 11 dimensions with applicability criteria)
- Updated guide: metadata, overview, matrix structure, related resources (6→11 dimensions)
- Updated `task-transition-guide.md`: Feature Validation section with preparation step and 11 dimensions
- Updated `ai-tasks.md`: added "For Feature Validation" common workflow section
- Updated `PF-documentation-map.md`: added Validation Preparation task + context map

**All three phases complete.** Next: finalize structure change (cleanup, validation, feedback form)
