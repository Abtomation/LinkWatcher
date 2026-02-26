---
id: PF-STA-003
type: Process Framework
category: State Tracking
version: 1.0
created: 2025-06-05
updated: 2026-02-26
---

# Process Improvement Tracking

This file tracks the status of process improvements identified through feedback collection and tools review in the BreakoutBuddies project.

## Status Legend

| Status      | Description                                                         |
| ----------- | ------------------------------------------------------------------- |
| Identified  | Improvement opportunity has been identified but not yet prioritized |
| Prioritized | Improvement has been evaluated and prioritized for implementation   |
| In Progress | Improvement is currently being implemented                          |
| Completed   | Improvement has been implemented and validated                      |
| Deferred    | Improvement has been postponed to a later time                      |
| Rejected    | Improvement was evaluated but determined not to be beneficial       |

## Current Improvement Opportunities

| ID | Source | Description | Priority | Status | Last Updated | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| IMP-009 | [Tools Review 2026-02-21](../../feedback/reviews/tools-review-20260221.md) | Create retrospective-specific state file template variant | MEDIUM | Identified | 2026-02-21 | Collapse sections 8-12 (~70% size reduction). 6+ forms, TSK-064/065. |
| IMP-037 | [Tools Review 2026-02-21](../../feedback/reviews/tools-review-20260221.md) | Consider reducing to single tracking surface for document status | MEDIUM | Deferred | 2026-02-21 | Proposal: [PF-PRO-005](../../proposals/proposals/single-tracking-surface-proposal.md). Auto-generate feature-tracking.md from state files. ~50 files affected, 3-session estimate. |
| IMP-043 | [Tools Review 2026-02-26](../../feedback/reviews/tools-review-20260226.md) | Add retrospective mode to PF-TSK-012 | MEDIUM | Identified | 2026-02-26 | Process assumes pre-implementation spec creation. Retrospective mode would adapt steps for documenting existing tests. |
| IMP-046 | [Tools Review 2026-02-26](../../feedback/reviews/tools-review-20260226.md) | Add regression test strategy guidance to PF-TSK-007 | LOW | Identified | 2026-02-26 | No explicit guidance on how many tests, unit vs integration balance for bug fix regression tests. |
| IMP-047 | [Tools Review 2026-02-26](../../feedback/reviews/tools-review-20260226.md) | Improve bug tracking table format for complex bugs | LOW | Identified | 2026-02-26 | Single-row table format causes extreme horizontal scrolling for complex bugs with long descriptions. |
| IMP-048 | [Tools Review 2026-02-26](../../feedback/reviews/tools-review-20260226.md) | Add batch spec creation guidance to PF-TSK-012 | LOW | Identified | 2026-02-26 | No guidance for creating multiple specs in one session. Batch creation was done ad-hoc for 8 specs. |
| IMP-049 | [Tools Review 2026-02-26](../../feedback/reviews/tools-review-20260226.md) | Create persistent ratings history table to track tool improvement over time | MEDIUM | Identified | 2026-02-26 | User suggestion. Track numeric ratings per task per review cycle in a cumulative table (e.g., in reviews/ directory). Enables trend analysis across review cycles. |


## Completed Improvements

| ID      | Description                                                    | Completed Date | Impact   | Validation Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| ------- | -------------------------------------------------------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| IMP-033 | Fix feature-tracking auto-update persistence issue | 2026-02-21 | HIGH | Root cause: `Update-MarkdownTable` did exact match on first column (`$columns[0] -eq $FeatureId`) but feature-tracking.md wraps IDs in links (`[0.1.1](path)`). Fixed both `Update-MarkdownTable` and `Update-MarkdownTableWithAppend` in TableOperations.psm1 to extract plain text from `[text](url)` before comparing. Verified with live test against feature 0.1.1. |
| IMP-017 | Standardize parameter names across file creation scripts | 2026-02-21 | MEDIUM | Renamed `-Category` to `-WorkflowPhase` in New-Task.ps1 to match New-ContextMap.ps1. Updated all internal variable references ($Category→$WorkflowPhase, $categoryToSection→$phaseToSection). Updated 4 documentation files (new-task-creation-process.md, task-creation-guide.md, script-development-quick-reference.md, framework-domain-adaptation.md). Validated with -WhatIf test and old parameter rejection test. |
| IMP-001 | Automate summary table recalculation in feature-tracking.md | 2026-02-21 | LOW | Added `Update-FeatureTrackingSummary` function to FeatureTracking.psm1. Parses all feature tables, counts statuses/tiers/docs, regenerates 3 summary sections. Integrated into both `Update-FeatureTrackingStatus` and `Update-FeatureTrackingStatusWithAppend` — summaries now auto-update on every feature row change. Validated with standalone test and DryRun integration test. |
| IMP-008 | Fix New-FeedbackForm.ps1 parameter validation for FeedbackType | 2026-02-21 | LOW | Added space-separated variants to ValidateSet: `"Single Tool"`, `"Multiple Tools"`, `"Task-Level"` alongside existing camelCase forms. Updated switch to handle both forms via `$_ -in` pattern. Updated ai-tasks.md to document both accepted formats. |
| IMP-029 | Standardize auto-update behavior across FDD/TDD/ADR scripts | 2026-02-21 | MEDIUM | Refactored ADR script to call `Update-FeatureTrackingStatus` directly (like FDD/TDD). Added `-DryRun` parameter. Removed redundant feature-tracking code from DocumentTracking.psm1 ADR case. Verified with WhatIf+DryRun tests. |
| IMP-032 | Evaluate retrospective documentation value (user request) | 2026-02-21 | HIGH | **Rejected**: Evaluated and concluded retrospective documentation does not bring enough value to justify the effort. |
| IMP-028 | Create master state validation script (verify checkmarks vs files) | 2026-02-21 | HIGH | Created `Validate-StateTracking.ps1` with 5 validation surfaces (FeatureTracking, StateFiles, TestTracking, CrossRef, IdCounters). Fixed 57 broken links across 9 feature state files. Integrated into documentation-map.md, CLAUDE.md, and task checklists (PF-TSK-014, PF-TSK-066). |
| IMP-016 | Fix New-FrameworkExtensionConcept.ps1 path resolution bug | 2026-02-21 | HIGH | Fixed garbled template path `../../../../proposals/doc/...` to correct project-root-relative path `doc/process-framework/templates/templates/framework-extension-concept-template.md`. Script is now usable. |
| IMP-018 | Fix WhatIf support in New-StandardProjectDocument | 2026-02-21 | MEDIUM | Two fixes: (1) moved ID generation and replacement building inside ShouldProcess block so IDs aren't consumed in WhatIf mode, (2) added cross-module WhatIf propagation via Get-PSCallStack inspection. Tested with 3 scripts: WhatIf no-op, normal creation, and cross-script WhatIf — all pass. |
| IMP-024 | Audit all file-creation scripts for template path correctness | 2026-02-21 | HIGH | Audited all 30 scripts. Fixed 7 bugs across 5 scripts: (A) garbled template paths in New-TechnicalDebtAssessment.ps1 and New-TestAuditReport.ps1 (also fixed garbled module import), (B) escaped brackets in replacement keys in New-tdd.ps1, New-EnhancementState.ps1, New-PermanentState.ps1, New-TempTaskState.ps1. All verified with -WhatIf tests. 23 scripts confirmed correct. |
| IMP-025 | Fix scripts with missing/broken $projectRoot path resolution | 2026-02-21 | HIGH | Root cause was garbled paths (same as IMP-024 Category A), not missing Get-ProjectRoot calls. All scripts that use $projectRoot already define it. Scripts using relative paths rely on framework-internal resolution (correct design). Fixes applied via IMP-024. |
| IMP-022 | Genericize Flutter/Dart refs in PF-TSK-012 and PF-TSK-053 | 2026-02-21 | LOW | Replaced 6 Flutter/Dart references in PF-TSK-012 (widget→UI/component, removed Flutter/Mockito external links) and 4 in PF-TSK-053 (removed Dart-specific examples from test type lists and coverage tool references). Verified zero Flutter/Dart references remain in either task. |
| IMP-019 | Merge overlapping concept template sections | 2026-02-21 | LOW | Merged "Critical Success Factors" into "Success Criteria" (combined human/technical requirements with functional/integration/quality checklists). Removed duplicate "Output Specifications" subsection (already covered by "Expected Outputs" section). Template reduced from 337 to ~323 lines. |
| IMP-003 | Add activity-level tags to Context Requirements in task definitions | 2026-02-21 | LOW | **Rejected**: Existing Critical/Important/Reference classification already provides sufficient guidance. Adding a second ACTIVE/REFERENCE/CONTEXT layer would increase complexity without proportional benefit. |
| IMP-026 | Make templates technology-agnostic (remove Flutter/Dart-specific sections) | 2026-02-21 | HIGH | Removed all Flutter/Dart/Riverpod/Supabase/GoRouter references from 8 templates: ui-design, test-specification, feature-implementation, implementation-plan, validation-report, cross-cutting-test-spec, api-reference, documentation. Replaced with generic, framework-agnostic guidance. Verified zero Flutter/Dart references remain in .md templates. |
| IMP-038 | Streamline PF-TSK-009 process and remove testing infrastructure | 2026-02-26 | HIGH | Rewrote PF-TSK-009 from 27 steps to 14 (~48% reduction). Removed testing infrastructure (6 steps, scripts section, test tracking). Replaced Steps 1-5 with "select from tracking + review feedback" (eliminates overlap with Tools Review). Added Step 9 for updating linked documents. Deleted ai-framework-testing-guide.md and ai-framework-test-tracking-template.md. Rewrote implementation guide (PF-GDE-037). Updated task registry, guides README, state-tracking README. |
| IMP-039 | Add test documentation cross-references to PF-TSK-007 Step 10 | 2026-02-26 | HIGH | Evaluated PF-TSK-012 and PF-TSK-053 — full task references rejected as disproportionate for bug fix regression tests. Instead added inline guidance to Step 10 covering two scenarios: adding to existing test files (update testCaseCount in test-registry.yaml) and creating new test files (use New-TestFile.ps1). Also updated implementation guide example (PF-GDE-037) to reflect actual approach. |
| IMP-040 | Document replacement key literal-brackets requirement in DocumentManagement.psm1 | 2026-02-26 | HIGH | Added comment blocks to both replacement loops (New-ProjectDocumentWithMetadata and New-ProjectDocumentWithCodeMetadata) explaining auto-escaping behavior. Added runtime Write-Warning when keys contain escaped brackets (`\[` or `\]`). Prevents the 4-script bug pattern from recurring. |
| IMP-041 | Add triage prerequisite check to PF-TSK-007 for un-triaged bugs | 2026-02-26 | MEDIUM | Added Step 2: if no triaged bugs found but 🆕 Reported bugs exist, agent must ask human partner whether to switch to Bug Triage (PF-TSK-041) first. Renumbered all subsequent steps (+1). Updated implementation guide step references. |
| IMP-042 | Note manual updates as practical default for Update-BugStatus.ps1 in PF-TSK-007 | 2026-02-26 | — | **Rejected**: Manual updates are the obvious fallback when a script doesn't apply; adding explicit notes would clutter the task definition without adding value. |
| IMP-045 | Create review summary template for PF-TSK-010 | 2026-02-26 | MEDIUM | Created PF-TEM-046 (tools-review-summary-template.md) with standardized sections: Review Scope, Task Group Analysis (repeatable), Cross-Group Themes, Improvement Opportunities Summary, Human User Feedback, Archived Forms. Also created New-ReviewSummary.ps1 (ART-REV prefix, date-based filenames). Referenced from PF-TSK-010 Outputs section and documentation-map.md. |
| IMP-044 | Add lightweight plan mode to PF-TSK-022 for < 5 items | 2026-02-26 | MEDIUM | Made temp state file creation conditional in Step 2: < 5 items and ≤ 2 sessions use refactoring plan's Implementation Tracking section only; ≥ 5 items or 3+ sessions create separate temp state file. Updated Phase 3 archival, completion checklist, and task registry. |

## Priority Criteria

Improvements are prioritized based on:

1. **Frequency** - How often the issue appears in feedback
2. **Impact** - Potential improvement to efficiency or quality
3. **Effort** - Resources required for implementation
4. **Risk** - Potential negative consequences if not addressed

## Tasks That Update This File

The following tasks update this state file:

- [Tools Review Task](../../tasks/support/tools-review-task.md): Updates when improvements are identified, prioritized, or completed
- [Process Improvement Task](../../tasks/support/process-improvement-task.md): Updates when implementing larger process changes
- [Structure Change Task](../../tasks/support/structure-change-task.md): Updates when implementing structure changes
- [Framework Extension Task](../../tasks/support/framework-extension-task.md): Updates when adding new framework capabilities

## Update History

| Date       | Change                                                                                                                        | Updated By               |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| 2026-02-21 | Initial population: 18 improvement opportunities from Tools Review of 23 feedback forms (6 HIGH, 6 MEDIUM, 6 LOW) | AI Agent (PF-TSK-010) |
| 2026-02-21 | Completed IMP-024 and IMP-025: Fixed 7 bugs across 5 file-creation scripts (garbled paths + escaped brackets). Moved to Completed. | AI Agent (PF-TSK-009) |
| 2026-02-21 | Completed IMP-026: Made 8 templates technology-agnostic by removing all Flutter/Dart-specific references. Moved to Completed. | AI Agent (PF-TSK-009) |
| 2026-02-21 | Completed IMP-028: Created Validate-StateTracking.ps1, fixed 57 broken links in state files, integrated into docs and task checklists. Moved to Completed. | AI Agent (PF-TSK-009) |
| 2026-02-21 | Rejected IMP-032: Retrospective documentation evaluated as not bringing sufficient value. Moved to Completed (Rejected). | AI Agent (PF-TSK-009) |
| 2026-02-21 | Completed IMP-029: Refactored ADR script to call Update-FeatureTrackingStatus directly (like FDD/TDD). Added -DryRun param. Removed redundant feature-tracking from DocumentTracking.psm1. | AI Agent (PF-TSK-009) |
| 2026-02-21 | Completed IMP-033: Fixed Update-MarkdownTable and Update-MarkdownTableWithAppend to extract plain text from markdown links before ID matching. Root cause of all auto-update persistence failures. | AI Agent (PF-TSK-009) |
| 2026-02-21 | Completed IMP-017: Renamed -Category to -WorkflowPhase in New-Task.ps1 + updated 4 docs. Both scripts now use -WorkflowPhase consistently. | AI Agent (PF-TSK-009) |
| 2026-02-21 | Completed IMP-001: Added Update-FeatureTrackingSummary to FeatureTracking.psm1. Auto-recalculates summary tables on every feature tracking update. | AI Agent (PF-TSK-009) |
| 2026-02-21 | Completed IMP-008: Added space-separated FeedbackType variants to ValidateSet in New-FeedbackForm.ps1. Updated ai-tasks.md docs. | AI Agent (PF-TSK-009) |
| 2026-02-21 | Completed IMP-022: Genericized Flutter/Dart refs in PF-TSK-012 (6 refs: widget→UI/component, removed external links) and PF-TSK-053 (4 refs: removed language-specific examples). Zero Flutter/Dart refs remain. | AI Agent (PF-TSK-009) |
| 2026-02-21 | Completed IMP-019: Merged overlapping sections in framework-extension-concept-template.md. Removed duplicate "Output Specifications" and "Critical Success Factors", folded content into "Expected Outputs" and "Success Criteria". | AI Agent (PF-TSK-009) |
| 2026-02-21 | Rejected IMP-003: Activity-level tags deemed unnecessary — existing Critical/Important/Reference classification is sufficient. | AI Agent (PF-TSK-009) |
| 2026-02-26 | Tools Review cycle 2: Added 11 improvement opportunities (IMP-038 through IMP-048) from analysis of 11 feedback forms across 7 task types. 3 HIGH, 5 MEDIUM, 3 LOW. Review summary: [ART-REV-002](../../feedback/reviews/tools-review-20260226.md). | AI Agent (PF-TSK-010) |
| 2026-02-26 | Completed IMP-038: Streamlined PF-TSK-009 from 27 to 14 steps. Removed testing infrastructure, fixed overlap with Tools Review, added linked-documents step. Deleted 2 obsolete files, rewrote implementation guide, updated 3 other docs. | AI Agent (PF-TSK-009) |
| 2026-02-26 | Completed IMP-039: Added inline test documentation guidance to PF-TSK-007 Step 10. Covers existing-file (testCaseCount update) and new-file (New-TestFile.ps1) scenarios. Chose inline over task references after evaluating PF-TSK-012/053 as disproportionate. Updated implementation guide example. | AI Agent (PF-TSK-009) |
| 2026-02-26 | Completed IMP-040: Added comment blocks and runtime Write-Warning to both replacement loops in DocumentManagement.psm1. Warns when keys contain pre-escaped brackets. No linked document updates needed (guides already document correct pattern). | AI Agent (PF-TSK-009) |
| 2026-02-26 | Rejected IMP-042: Manual updates are the obvious fallback; adding notes would clutter PF-TSK-007. | AI Agent (PF-TSK-009) |
| 2026-02-26 | Completed IMP-041: Added triage prerequisite check (Step 2) to PF-TSK-007. Agent must ask human partner to switch to Bug Triage (PF-TSK-041) when encountering un-triaged bugs. Renumbered steps 3-21. Updated implementation guide step references. | AI Agent (PF-TSK-009) |
| 2026-02-26 | Completed IMP-045: Created PF-TEM-046 (tools-review-summary-template.md) via New-Template.ps1. Standardized 6 sections from best elements of both existing reviews. Referenced from PF-TSK-010 Outputs and documentation-map.md. | AI Agent (PF-TSK-009) |
| 2026-02-26 | Completed IMP-044: Made temp state file conditional in PF-TSK-022 Step 2 (< 5 items use refactoring plan's Implementation Tracking; ≥ 5 items create separate temp state). Updated Phase 3 archival, completion checklist, and task registry. | AI Agent (PF-TSK-009) |
