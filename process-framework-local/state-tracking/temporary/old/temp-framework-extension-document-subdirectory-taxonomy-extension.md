---
id: PF-STA-093
type: Document
category: General
version: 1.0
created: 2026-04-17
updated: 2026-04-17
task_name: document-subdirectory-taxonomy-extension
---

# Temporary Framework Extension State: Document Subdirectory Taxonomy Extension

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of a framework extension (PF-TSK-048). Move to `process-framework-local/state-tracking/temporary/old` after all phases are complete.

## Extension Overview

- **Extension Name**: Document Subdirectory Taxonomy Extension
- **Source Concept**: [PF-PRO-026 — document-subdirectory-taxonomy.md](../../proposals/document-subdirectory-taxonomy.md)
- **Source IMP(s)**: [PF-IMP-571 — process-improvement-tracking.md](../../permanent/process-improvement-tracking.md)
- **Scope**: Add a two-layer faceted taxonomy for user documentation: L1 (Diátaxis content types: tutorials, how-to, reference, explanation) and L2 (project-specific topics). Framework declares the schema, validates via scripts, and integrates the analysis into existing documentation workflow. This project implements L1 only in practice; L2 schema is declared but unused.
- **Estimated Sessions**: 1-2 sessions

## Artifact Tracking

| Artifact | Type | Location | Creator Task | Updater Task(s) | Status |
|----------|------|----------|-------------|-----------------|--------|
| PD-id-registry.json `subdirectories` + `topics` schema | Config | `doc/PD-id-registry.json` | PF-TSK-048 | — | NOT_STARTED |
| DocumentManagement.psm1 validation logic | Script | `process-framework/scripts/Common-ScriptHelpers/DocumentManagement.psm1` | PF-TSK-048 | — | NOT_STARTED |
| New-Handbook.ps1 `-Topic` param + remove ValidateSet | Script | `process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1` | PF-TSK-048 | — | NOT_STARTED |
| PF-TSK-081 Diátaxis analysis step | Task Def | `process-framework/tasks/07-deployment/user-documentation-creation.md` | PF-TSK-048 | — | NOT_STARTED |
| Feature state template Content Type column | Template | `process-framework/templates/04-implementation/feature-implementation-state-template.md` | PF-TSK-048 | — | NOT_STARTED |
| Update-UserDocumentationState.ps1 ContentType param | Script | `process-framework/scripts/update/Update-UserDocumentationState.ps1` | PF-TSK-048 | — | NOT_STARTED |
| project-initiation-task taxonomy declaration step | Task Def | `process-framework/tasks/00-setup/project-initiation-task.md` | PF-TSK-048 | — | NOT_STARTED |
| codebase-feature-discovery Diátaxis classification note | Task Def | `process-framework/tasks/00-setup/codebase-feature-discovery.md` | PF-TSK-048 | — | NOT_STARTED |
| Concept document update (full L1+L2 scope) | Proposal | `process-framework-local/proposals/document-subdirectory-taxonomy.md` | PF-TSK-048 | — | NOT_STARTED |

**Status Legend**: NOT_STARTED | IN_PROGRESS | COMPLETED | DEFERRED

## Task Impact

Existing tasks affected by this extension:

| Task | ID | Change Required | Priority | Status |
|------|----|----|----------|--------|
| User Documentation Creation | PF-TSK-081 | Add Diátaxis analysis step (Step 1 enhancement); update Step 5/6 to pass content type to scripts; add decision matrix | HIGH | NOT_STARTED |
| Project Initiation | PF-TSK-059 | Add step to declare documentation taxonomy (L1 defaults + optional L2) in PD-id-registry.json | HIGH | NOT_STARTED |
| Codebase Feature Discovery | PF-TSK-064 | Add brief note: when auditing existing docs, classify by Diátaxis content type | LOW | NOT_STARTED |

## Implementation Roadmap

### Phase 1: Concept & Approval ✅

**Priority**: HIGH — Must complete before implementation begins

- [x] **Pre-concept analysis**: Studied Diátaxis framework, existing `-Subdirectory` pattern (IMP-568), registry schema precedents
  - **Status**: COMPLETED
  - **Key findings**: Two-layer faceted taxonomy is industry standard (L1 = content type, L2 = topic). Diátaxis is the de facto L1 standard. L2 is project-specific topic/domain.

- [x] **Create concept document**: PF-PRO-026 document-subdirectory-taxonomy.md
  - **Status**: COMPLETED — needs scope update to include L2 and 00-setup impact

- [x] **CHECKPOINT**: Concept approved with expanded scope (L1+L2, PF-TSK-081 enhancement, 00-setup updates)
  - **Status**: APPROVED 2026-04-17

### Phase 2: Update Concept Document with Full Scope

- [ ] Update PF-PRO-026 to reflect L1+L2 design, PF-TSK-081 enhancement, 00-setup impact
  - **Status**: NOT_STARTED

### Phase 3A: Registry + Scripts

- [ ] Add `subdirectories` and `topics` fields to `PD-UGD` in PD-id-registry.json
  - **Status**: NOT_STARTED

- [ ] Add validation logic to `New-StandardProjectDocument` in DocumentManagement.psm1
  - **Status**: NOT_STARTED

- [ ] Update New-Handbook.ps1: remove hardcoded ValidateSet, rename `-Category` to reflect Diátaxis, add optional `-Topic` parameter
  - **Status**: NOT_STARTED

### Phase 3B: Task + Template Integration

- [ ] Enhance PF-TSK-081 with Diátaxis analysis step and decision matrix
  - **Status**: NOT_STARTED

- [ ] Update feature-implementation-state-template.md Documentation Inventory with Content Type column
  - **Status**: NOT_STARTED

- [ ] Update Update-UserDocumentationState.ps1 to accept `-ContentType` parameter
  - **Status**: NOT_STARTED

### Phase 3C: 00-Setup Integration

- [ ] Add taxonomy declaration step to project-initiation-task.md
  - **Status**: NOT_STARTED

- [ ] Add Diátaxis classification note to codebase-feature-discovery.md
  - **Status**: NOT_STARTED

### Phase 4: Finalization

- [ ] Grep sweep: verify linked documents
  - **Status**: NOT_STARTED

- [ ] Integration testing: create a test handbook with `-Category how-to`
  - **Status**: NOT_STARTED

- [ ] Update permanent state files: mark PF-IMP-571 as Completed
  - **Status**: NOT_STARTED

- [ ] Log tool changes in feedback database
  - **Status**: NOT_STARTED

- [ ] Archive concept document to proposals/old/
  - **Status**: NOT_STARTED

- [ ] Complete feedback form
  - **Status**: NOT_STARTED

## Session Tracking

### Session 1: 2026-04-17

**Focus**: Full implementation (all phases)
**Completed**:

- Pre-concept analysis
- Initial concept document creation
- Scope discussion and approval (L1+L2, 00-setup integration)

**Issues/Blockers**:

- None

**Next Session Plan**:

- Continue implementation per roadmap; ending session-by-session if context tight

## Completion Criteria

- [ ] All artifacts in Artifact Tracking table COMPLETED
- [ ] All task impacts in Task Impact table COMPLETED
- [ ] PD-id-registry.json updated with schema
- [ ] Scripts tested with `-WhatIf` and real invocation
- [ ] PF-IMP-571 marked Completed in process-improvement-tracking.md
- [ ] Concept document archived
- [ ] Feedback form submitted

## Notes and Decisions

### Key Decisions

- **Taxonomy standard**: Diátaxis (tutorials/how-to/reference/explanation) as L1 — industry best practice, adopted by Django, NumPy, Gatsby, Canonical
- **L2 semantics**: Project-specific topic/domain area, optional by declaration (framework doesn't force feature/module naming)
- **This project practice**: Implement L1 only; leave existing 8 handbooks flat until count justifies migration (~15+ handbooks)
- **No file migration in this extension**: Migration of existing handbooks deferred to future Structure Change task when warranted
