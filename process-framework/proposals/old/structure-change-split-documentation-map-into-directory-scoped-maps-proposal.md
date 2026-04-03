---
id: PF-PRO-014
type: Document
category: General
version: 1.0
created: 2026-04-03
updated: 2026-04-03
---

# Structure Change Proposal: Split Documentation Map Into Directory-Scoped Maps

## Overview

Split the monolithic `process-framework/PF-documentation-map.md` into three directory-scoped documentation maps — one per major directory — so each map only indexes files within its own directory. This mirrors the earlier ID registry split (SC-008).

**Structure Change ID:** SC-009
**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-04-03
**Target Implementation Date:** 2026-04-03

## Current Structure

A single file `process-framework/PF-documentation-map.md` (637 lines) indexes **all** documentation across three directories:
- Process Framework files (`process-framework/`) — tasks, templates, guides, scripts, context maps
- Product Documentation files (`doc/`) — FDDs, TDDs, ADRs, validation reports, state tracking, handbooks
- Test files (`test/`) — test specifications, audit reports, test state tracking

### Problems with Current Structure

1. **Ownership mismatch**: `doc/` and `test/` content is indexed inside `process-framework/`, creating cross-directory ownership confusion
2. **File size**: 637 lines makes the map hard to navigate and expensive for AI agent context
3. **Inconsistency**: ID registries are already split per directory, but the documentation map is not
4. **Link maintenance**: All links to `doc/` and `test/` files use `../..` relative paths, which is fragile

## Proposed Structure

Three documentation maps, each local to its directory:

```
process-framework/PF-documentation-map.md  — Tasks, templates, guides, scripts, context maps, PF state tracking
doc/PD-documentation-map.md                — FDDs, TDDs, ADRs, validation reports, state tracking, handbooks
test/documentation-map.md               — Test specs, cross-cutting specs, audit reports, test state tracking
```

Each map:
- Uses directory-local relative paths (no `../..` needed)
- Has a "Cross-References" section linking to the other two maps
- Retains the same content structure (section headers, descriptions) as the original

The `process-framework/PF-documentation-map.md` file keeps the same path, so all 126 existing references remain valid.

## Rationale

### Benefits
- **Consistency**: Mirrors the ID registry split — same principle of directory-scoped ownership
- **Smaller files**: Each map is focused and faster to navigate for both humans and AI agents
- **Correct ownership**: Each directory owns its own index
- **Simpler links**: Local relative paths instead of cross-directory `../..` references
- **Independent maintenance**: Adding a new TDD only requires updating `doc/PD-documentation-map.md`

### Challenges
- **Cross-directory awareness**: Agents need to know about all three maps (mitigated by cross-reference sections and CLAUDE.md updates)
- **One-time migration effort**: Content must be carefully split without losing entries
- **Script updates**: `Update-UserDocumentationState.ps1` currently adds entries to `PF-documentation-map.md` User Handbooks section — needs path update to `doc/PD-documentation-map.md`

## Affected Files

### Primary Files (created/modified)
- `process-framework/PF-documentation-map.md` — **Modified**: remove `doc/` and `test/` content, add cross-references
- `doc/PD-documentation-map.md` — **Created**: product documentation index
- `test/documentation-map.md` — **Created**: test documentation index

### Scripts Requiring Path Updates (write to documentation-map)
- `process-framework/scripts/update/Update-UserDocumentationState.ps1` — Appends handbook entries to "User Handbooks" section; path needs to change to `doc/PD-documentation-map.md`
- `process-framework/scripts/update/Update-ValidationReportState.ps1` — Appends validation report entries; path needs to change to `doc/PD-documentation-map.md`

### Scripts NOT Requiring Updates (already target correct map)
- `process-framework/scripts/file-creation/support/New-Task.ps1` — Adds task entries to Task Definitions section, which stays in `process-framework/PF-documentation-map.md`
- `process-framework/scripts/file-creation/02-design/New-ArchitectureDecision.ps1` — Does NOT write to documentation-map (comment only)
- `process-framework/scripts/file-creation/05-validation/New-ValidationReport.ps1` — Does NOT write to documentation-map

### Task Definitions Requiring Updates (instruct agent to update wrong map)

The following tasks instruct the AI agent to manually add entries to `PF-documentation-map.md`. After the split, the sections they reference (Validation Reports, Test Specifications, ADRs, etc.) will no longer exist in `process-framework/PF-documentation-map.md`. Their checklist items need updating to point to the correct directory-scoped map.

**Tasks creating `doc/` content → should reference `doc/PD-documentation-map.md`:**
- All 11 validation dimension tasks: Architectural Consistency, Code Quality, Integration Dependencies, Documentation Alignment, Extensibility & Maintainability, AI Agent Continuity, Security & Data Protection, Performance & Scalability, Observability, Accessibility/UX, Data Integrity — checklist item: "Documentation Map updated with new validation report entry"
- ADR Creation (PF-TSK-019) — output: "ADR entry added to the architecture documentation map"
- Validation Preparation (PF-TSK-077) — checklist: "Documentation Map updated if applicable"

**Tasks creating `test/` content → should reference `test/documentation-map.md`:**
- Test Specification Creation (PF-TSK-012) — checklist: "Documentation Map — New test spec entries added to Test Specifications section"

**Tasks creating mixed content → need awareness of all three maps:**
- Retrospective Documentation Creation (PF-TSK-066) — creates FDDs/TDDs/ADRs (→ `doc/`) and test specs (→ `test/`)

**Tasks referencing `process-framework/PF-documentation-map.md` correctly (no content change needed, but link text may mention "all artifacts"):**
- New Task Creation Process (PF-TSK-001) — automated by `New-Task.ps1`, targets process-framework
- Framework Extension Task (PF-TSK-026) — creates framework artifacts
- Structure Change Task (PF-TSK-014) — generic, depends on change type
- Framework Domain Adaptation — generic reference

### Guides Requiring Updates
- `guides/05-validation/documentation-guide.md` — Multiple references to "the Documentation Map" as a single file; "Updating the Documentation Map" section needs to explain the three-map structure
- `guides/support/document-creation-script-development-guide.md` — Code example shows `$docMapPath = "../../PF-documentation-map.md"` which is fine for process-framework content but guide should note that doc/ and test/ content goes to their respective maps
- `guides/support/migration-best-practices.md` — Step "Update documentation-map.md: mark archived entries" needs to specify which map based on content type
- `guides/support/task-creation-guide.md` — "Add the new task to process-framework/documentation-map.md" — correct target, no change needed
- `guides/framework/task-transition-guide.md` — Checklist items referencing documentation-map for retrospective and framework extension tasks

### Templates Requiring Updates
- `templates/support/temp-task-creation-state-template.md` — "Documentation Map Update" step references `process-framework/PF-documentation-map.md` — correct for task creation, but should clarify scope
- `templates/support/temp-process-improvement-state-template.md` — "Update documentation map" step — should clarify which map based on what artifacts were created
- `templates/support/framework-extension-concept-template.md` — "documentation-map.md: All new artifacts" — should clarify which map(s)

### Infrastructure Files Requiring Updates
- `infrastructure/process-framework-task-registry.md` — Multiple references describe which tasks update documentation-map; needs to specify which map per content type
- `scripts/AUTOMATION-USAGE-GUIDE.md` — Lists `PF-documentation-map.md` as an output of `Update-ValidationReportState.ps1`

### Context/Reference Files (link-only, path still resolves — low priority)
- `CLAUDE.md` — "Documentation Map: @process-framework/PF-documentation-map.md" — should also mention doc/ and test/ maps
- Various context maps (6 files) — link to `PF-documentation-map.md` as a reference; path still resolves, descriptions are generic enough

## Content Split

### Stays in `process-framework/PF-documentation-map.md`
- Task Definitions (all phases 00–07, cyclical, support)
- Core Process Documents
- Process Framework State Tracking (`process-framework/state-tracking/`)
- Templates (all categories)
- Automation Scripts, Testing Scripts, State Update Scripts, Validation Scripts
- Process Framework Guides (all categories)
- Visualization Resources / Context Maps
- How to Use / Document Relationships / Maintaining sections

### Moves to `doc/PD-documentation-map.md`
- Product State Tracking (`doc/state-tracking/` — permanent + temporary)
- Core Product Documents (feature dependencies, user workflow tracking)
- User Handbooks
- Product Technical Design
- Functional Design Documents (FDDs)
- Technical Design Documents (TDDs)
- Architecture Decision Records (ADRs)
- Validation Reports (Round 1, 2, 3)

### Moves to `test/documentation-map.md`
- Test State Tracking (`test/state-tracking/`)
- Test Specifications (feature-specific)
- Cross-Cutting Test Specifications
- Test Audit Reports

## Migration Strategy

### Phase 1: Create New Maps
- Create `doc/PD-documentation-map.md` with product documentation content, converting `../doc/` relative paths to local paths
- Create `test/documentation-map.md` with test content, converting `../test/` relative paths to local paths
- Add cross-reference sections to both new maps

### Phase 2: Trim Process Framework Map
- Remove `doc/` and `test/` content from `process-framework/PF-documentation-map.md`
- Add cross-reference section pointing to `doc/PD-documentation-map.md` and `test/documentation-map.md`
- Move "Process Framework Guides" from under the "Product Documentation" header to the correct "Process Framework Documents" section

### Phase 3: Update Scripts
- Update `Update-UserDocumentationState.ps1` path to write to `doc/PD-documentation-map.md`
- Update `Update-ValidationReportState.ps1` path to write to `doc/PD-documentation-map.md`

### Phase 4: Update Task Definitions
- Update all 11 validation dimension task checklists: change documentation-map link to `doc/PD-documentation-map.md`
- Update Test Specification Creation (PF-TSK-012) checklist: change to `test/documentation-map.md`
- Update ADR Creation (PF-TSK-019) outputs: change to `doc/PD-documentation-map.md`
- Update Validation Preparation (PF-TSK-077) checklist: change to `doc/PD-documentation-map.md`
- Update Retrospective Documentation Creation (PF-TSK-066): clarify which map for each content type

### Phase 5: Update Guides, Templates, and Infrastructure
- Update `guides/05-validation/documentation-guide.md` "Updating the Documentation Map" section
- Update `guides/support/migration-best-practices.md` archive step
- Update `templates/support/framework-extension-concept-template.md` to clarify map scope
- Update `templates/support/temp-process-improvement-state-template.md` to clarify map scope
- Update `infrastructure/process-framework-task-registry.md` references
- Update `scripts/AUTOMATION-USAGE-GUIDE.md`
- Update `CLAUDE.md` Key References section

## Testing Approach

### Success Criteria
- All three maps contain only files from their own directory
- No entries lost in the split (total entries across 3 maps = original entries)
- All links in each map resolve correctly
- `Update-UserDocumentationState.ps1` writes to the correct map
- `Validate-StateTracking.ps1` passes with 0 errors
- Existing references to `process-framework/PF-documentation-map.md` still work

## Rollback Plan

### Trigger Conditions
- Broken cross-references that cannot be easily fixed
- Scripts fail due to path changes

### Rollback Steps
1. Revert changes to `process-framework/PF-documentation-map.md` (restore removed content)
2. Delete `doc/PD-documentation-map.md` and `test/documentation-map.md`
3. Revert script changes

Low risk since the original file path is preserved and content is copied (not moved).

## Approval

**Approved By:** _________________
**Date:** 2026-04-03

**Comments:**

