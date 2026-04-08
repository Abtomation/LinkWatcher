---
id: PF-STA-070
type: Document
category: General
version: 1.0
created: 2026-04-01
updated: 2026-04-01
task_name: registry-drift-prevention
---

# Temporary Process Improvement State: Registry Drift Prevention

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of a process improvement. Move to `process-framework-local/state-tracking/temporary/old` after all phases are complete.

## Improvement Overview

- **Improvement Name**: Registry Drift Prevention
- **Source IMP(s)**: [PF-IMP-283](../../permanent/process-improvement-tracking.md) — Registry drift prevention
- **Source Feedback**: Root cause analysis during PF-IMP-273 audit (2026-04-01)
- **Scope**: Prevent future drift of process-framework-task-registry.md by automating updates and adding validation

## Root Cause Analysis (completed 2026-04-01)

The registry drifted because:
1. **New-Task.ps1 updates 3 files but not the registry** — every task created since Oct 2025 was missed
2. **Registry update is mandatory but manual in PF-TSK-001** — manual steps are fragile when 3 other files auto-update
3. **No script creation workflow mentions the registry** — PF-GDE-013 never references it
4. **PF-TSK-026 omits registry from mandatory updates** — extensions add tasks/scripts without registry update
5. **No validation surface detects drift** — Validate-StateTracking.ps1 has 8 surfaces but none for registry

## Sustainability Insight

The registry's **detailed Task Catalog** (lines 77+) duplicates information from individual task definitions. The **unique value** is in the summary sections (lines 23-75): Automation Status Summary, State File Update Frequency, Automation Gaps. These cross-cutting views can't be derived from reading individual tasks. Consider whether New-Task.ps1 should generate a lightweight entry vs. the full detailed entry.

## Affected Components

| Component Type | Name | Current State | Planned Change | Priority |
| -------------- | ---- | ------------- | -------------- | -------- |
| Script | New-Task.ps1 | Updates doc-map, tasks/README, ai-tasks — NOT registry | Add registry update (skeleton entry with task name, ID, process type) | HIGH |
| Script | Validate-StateTracking.ps1 | 8 validation surfaces, none for registry | Add Surface 9: compare task files vs registry entries | HIGH |
| Task Def | PF-TSK-026 framework-extension-task.md | Mandatory updates list omits registry | Add registry to mandatory core file updates | MEDIUM |
| Guide | PF-GDE-013 document-creation-script-guide | No mention of registry | Add note about updating registry when creating scripts for new tasks | LOW |

## Implementation Roadmap

### Phase 1: Root Cause Analysis (Session 1 — 2026-04-01)

**Priority**: HIGH - Completed as part of PF-IMP-273 investigation

- [x] **Root cause analysis**: Identified 5 process gaps (see Root Cause Analysis section above)
  - **Status**: COMPLETED
- [x] **CHECKPOINT**: Presented findings to human partner
  - **Status**: APPROVED
  - **Outcome**: Human partner confirmed approach; asked about sustainability (how to keep registry updated, not just initially populated)

### Phase 2: Implement New-Task.ps1 Registry Update (Session 2)

**Priority**: HIGH - Prevents the most common drift source

- [x] **Design registry entry format**: Decided on lightweight skeleton (task name + ID + process type + placeholder)
  - **Status**: COMPLETED
  - **Decision**: Lightweight skeleton — full entries require manual customization anyway (scripts/file ops aren't known at task creation time)
- [x] **Implement New-Task.ps1 change**: Added registry update logic (lines 272-359) as 4th auto-updated file
  - **Status**: COMPLETED
- [x] **Test with -WhatIf**: Verified registry is updated correctly
  - **Status**: COMPLETED
- [x] **CHECKPOINT**: Reviewed implementation with human partner
  - **Status**: COMPLETED

### Phase 3: Implement Validation Surface (Session 2 or 3)

**Priority**: HIGH - Safety net for all drift sources

- [x] **Design validation logic**: Compares PF-TSK IDs from disk against registry entries
  - **Status**: COMPLETED
  - **Approach**: Glob `tasks/**/*.md`, extract PF-TSK IDs, compare against registry mentions
- [x] **Implement Surface 9 in Validate-StateTracking.ps1**: Lines 734-797, reports 55/55 pass
  - **Status**: COMPLETED
- [x] **Test**: Validation runs successfully, catches missing entries
  - **Status**: COMPLETED
- [x] **CHECKPOINT**: Reviewed with human partner
  - **Status**: COMPLETED

### Phase 4: Documentation Updates & Finalization (Session 3)

**Priority**: MEDIUM

- [x] **Update PF-TSK-026**: Registry referenced as infrastructure component
  - **Status**: COMPLETED
- [x] **Update PF-GDE-013**: Multiple sections now reference registry including full ID Registry Integration section
  - **Status**: COMPLETED
- [x] **Log tool changes in feedback database**
  - **Status**: COMPLETED
- [x] **Update process-improvement-tracking.md**: PF-IMP-283 marked Completed (2026-04-02)
  - **Status**: COMPLETED
- [x] **Complete feedback form**
  - **Status**: COMPLETED

## Session Tracking

### Session 1: 2026-04-01

**Focus**: Root cause analysis (done alongside PF-IMP-273 audit)
**Completed**:

- Identified 5 process gaps causing registry drift
- Created PF-IMP-283 in process-improvement-tracking.md
- Created this state file (PF-STA-070)
- Sustainability analysis: registry's detailed Task Catalog duplicates task definitions; unique value is in summary sections

**Issues/Blockers**:

- None

**Next Session Plan**:

- Implement New-Task.ps1 registry update (Phase 2)
- Implement Validate-StateTracking.ps1 Surface 9 (Phase 3)

## Completion Criteria

This temporary state file can be moved to `process-framework-local/state-tracking/temporary/old` when:

- [x] All implementation phases are complete
- [x] All affected components are updated and tested
- [x] Process improvement tracking is updated (Completed status)
- [x] Linked documents are updated
- [x] Feedback form is completed

## Notes and Decisions

### Key Decisions Made

- **Lightweight skeleton entry for New-Task.ps1** (proposed): Full registry entries require knowledge of scripts/file operations that don't exist at task creation time. New-Task.ps1 should insert a placeholder entry that gets fleshed out when scripts are created.
- **Validation surface as primary safety net**: Even with New-Task.ps1 automation, scripts added later (during PF-TSK-009, PF-TSK-026) won't trigger registry updates. The validation surface catches all drift sources.

### Implementation Notes

- Registry analysis showed the detailed Task Catalog (lines 77+) duplicates task definition content. The unique value is in summary/aggregated sections (lines 23-75). Consider whether to maintain the detailed catalog or generate it.
- 16 of 16 missing tasks would have been caught by either Fix A or Fix B.
- 41 missing scripts would only be caught by Fix B (validation) since scripts are created across multiple workflows.
