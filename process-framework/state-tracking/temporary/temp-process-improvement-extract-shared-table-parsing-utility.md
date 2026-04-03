---
id: PF-STA-075
type: Document
category: General
version: 1.0
created: 2026-04-03
updated: 2026-04-03
task_name: extract-shared-table-parsing-utility
---

# Temporary Process Improvement State: Extract Shared Table Parsing Utility

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of a process improvement. Move to `process-framework/state-tracking/temporary/old` after all phases are complete.

## Improvement Overview

- **Improvement Name**: Extract Shared Table Parsing Utility
- **Source IMP(s)**: [PF-IMP-366](../permanent/process-improvement-tracking.md)
- **Source Feedback**: [PF-EVR-007](../../evaluation-reports/archive/20260403-framework-evaluation-03testing-and-04implementation-phases-tasks-templa.md) — Finding U-2
- **Scope**: Extract shared markdown table parsing helpers into TableOperations.psm1 and refactor 4 scripts

## Affected Components

| Component Type | Name | Current State | Planned Change | Priority |
| -------------- | ---- | ------------- | -------------- | -------- |
| Module | TableOperations.psm1 | 3 high-level functions, no low-level helpers | Add 4 low-level helpers, refactor internals | HIGH |
| Script | New-AuditTracking.ps1 | 46 lines inline table parsing | Use ConvertFrom-MarkdownTable + helpers | HIGH |
| Script | New-E2EAcceptanceTestCase.ps1 | 53 lines inline table parsing | Use helpers for 3 parsing segments | MEDIUM |
| Script | Update-TestExecutionStatus.ps1 | 74 lines inline table parsing | Use helpers for 2 parsing segments | MEDIUM |
| Script | Run-Tests.ps1 | 107 lines inline table parsing | Use helpers for table update logic | MEDIUM |

## Implementation Roadmap

### Phase 1: Helpers + Internal Refactor + Proof of Concept (Session 1) ✅

**Priority**: HIGH

- [x] **Review source feedback**: PF-EVR-007 finding U-2
  - **Status**: COMPLETED
  - **Key findings**: 4 scripts with ~280 lines of fragile inline regex table parsing; existing TableOperations.psm1 has high-level functions but no low-level helpers; scripts don't use the module

- [x] **Analyze current state**: Examined all 4 affected scripts + TableOperations.psm1
  - **Status**: COMPLETED
  - **Root cause**: No shared low-level building blocks for parsing/reconstructing table rows; each script reinvents column splitting, link extraction, row formatting

- [x] **Design solution**: Add 4 low-level helpers + AllTables mode
  - **Status**: COMPLETED
  - **Chosen approach**: Add Split-MarkdownTableRow, Get-MarkdownLinkText, ConvertTo-MarkdownTableRow, ConvertFrom-MarkdownTable (with -AllTables, -Section, -IncludeLineNumber, -ResolveLinkColumn); refactor existing 3 functions internally; migrate scripts incrementally
  - **Alternatives considered**: (1) Reject — LOW priority/HIGH effort unfavorable; (2) Descope to just small helpers — insufficient for ConvertFrom use case

- [x] **CHECKPOINT**: Approved by human partner

- [x] **Implement helpers**: 4 new functions in TableOperations.psm1 v2.0
  - **Status**: COMPLETED

- [x] **Refactor internals**: All 3 existing functions use new helpers
  - **Status**: COMPLETED — ~60 lines of duplicate parsing code removed

- [x] **Refactor New-AuditTracking.ps1**: Proof of concept
  - **Status**: COMPLETED — 46→25 lines of table parsing, no hardcoded column indices

- [x] **Verify**: 672 tests pass, Update-ProcessImprovement.ps1 -WhatIf works
  - **Status**: COMPLETED

- [x] **Log tool change**: `feedback_db.py log-change` — change #350
  - **Status**: COMPLETED

### Phase 2: Refactor E2E Scripts (Session 2)

**Priority**: MEDIUM

- [ ] **Refactor New-E2EAcceptanceTestCase.ps1**: 3 parsing segments → helpers
  - **Status**: NOT_STARTED

- [ ] **Refactor Update-TestExecutionStatus.ps1**: 2 parsing segments → helpers
  - **Status**: NOT_STARTED

- [ ] **Test both scripts**: -WhatIf + regression tests
  - **Status**: NOT_STARTED

### Phase 3: Refactor Run-Tests.ps1 + Finalize (Session 3)

**Priority**: MEDIUM

- [ ] **Refactor Run-Tests.ps1**: Table update logic → helpers
  - **Status**: NOT_STARTED

- [ ] **Update documentation map**: Add new functions to docs if needed
  - **Status**: NOT_STARTED

- [ ] **Final checkpoint**: Get human approval on complete solution
  - **Status**: NOT_STARTED

- [ ] **Mark IMP-366 Completed**: Update-ProcessImprovement.ps1
  - **Status**: NOT_STARTED

- [ ] **Complete feedback form**: Submit feedback for PF-TSK-009
  - **Status**: NOT_STARTED

## Session Tracking

### Session 1: 2026-04-03

**Focus**: Design helpers, implement in module, refactor internals, proof of concept
**Duration**: ~25 min (20:12–20:37)
**Completed**:

- Implemented 4 new low-level helper functions in TableOperations.psm1 (v2.0)
- Added -AllTables switch to ConvertFrom-MarkdownTable for multi-section files
- Refactored all 3 existing high-level functions to use new helpers (~60 lines removed)
- Refactored New-AuditTracking.ps1 as proof of concept (46→25 lines table parsing)
- Verified: 672 tests pass, Update-ProcessImprovement.ps1 works, New-AuditTracking.ps1 -WhatIf works
- Logged tool change #350 in feedback DB
- Updated IMP-366 status to InProgress

**Issues/Blockers**:

- Empty string handling in Split-MarkdownTableRow needed AllowEmptyString — fixed
- AllTables initially adopted first table's schema (Status Legend) — fixed with header matching
- AllTables + Section needed to not limit end range — fixed

**Next Session Plan**:

- Refactor New-E2EAcceptanceTestCase.ps1 (3 parsing segments)
- Refactor Update-TestExecutionStatus.ps1 (2 parsing segments)

## Completion Criteria

This temporary state file can be moved to `process-framework/state-tracking/temporary/old` when:

- [ ] All implementation phases are complete
- [ ] All affected components are updated and tested
- [ ] Process improvement tracking is updated (Completed status)
- [ ] Linked documents are updated
- [ ] Feedback form is completed

## Notes and Decisions

### Key Decisions Made

- **Add low-level helpers rather than extending high-level functions**: The existing Update-MarkdownTable/etc. are too opinionated (feature-ID matching, status column) for the 4 target scripts which need section-aware parsing, read-only queries, and multi-column matching.
- **AllTables mode with header-schema matching**: Files like test-tracking.md have multiple tables with same columns across sections. AllTables skips tables with different schemas (Status Legend, Coverage Summary) automatically.
- **Refactor existing functions to eat own dog food**: The 3 high-level functions now use Split-MarkdownTableRow, Get-MarkdownLinkText, ConvertTo-MarkdownTableRow internally, proving the helpers work and reducing ~60 lines.

### Implementation Notes

- ConvertFrom-MarkdownTable -Section + -AllTables: Section sets the start point, AllTables removes the end-of-section limit so it scans the entire file from there
- ResolveLinkColumn creates both `ColumnName` (display text) and `ColumnName_Link` (original markdown link) properties
