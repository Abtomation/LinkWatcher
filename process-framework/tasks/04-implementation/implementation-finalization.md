---
id: PF-TSK-055
type: Process Framework
category: Task Definition
version: 2.0
created: 2025-12-13
updated: 2026-06-12
description: "Complete remaining items and close out the feature"
complexity: medium
use_when: >-
  Complete remaining items and close out the feature
automation: manual
trigger_status:
  - raw: "Feature impl state file → PF-TSK-053 (Integration & Testing) = `completed`"
output_status:
  - file: feature-tracking.md
    status: "👀 Needs Review"
next_tasks:
  - task: ../06-maintenance/code-review-task.md
    condition: "Review the implemented feature for quality"
---

# Implementation Finalization

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Complete remaining items and close out a feature after implementation and integration testing: finalize documentation, confirm the full test suite is green, update and finalize the feature's state tracking in place, and hand the feature to Code Review (the consolidated quality gate, which validates acceptance criteria, performance-vs-targets, and code quality). Release mechanics — release notes, deployment preparation, rollback planning, versioning — are exclusively [Release & Deployment (PF-TSK-008)](../07-deployment/release-deployment-task.md)'s job and are not part of this task.

**Focus**: Close out the feature, NOT implement new functionality or fix issues (those should be handled in previous tasks).

## AI Agent Role

**Role**: Technical Lead
**Mindset**: Completion-focused lead specializing in documentation completeness and clean feature handoff
**Focus Areas**: Documentation completeness, test suite health, state tracking accuracy
**Communication Style**: Present closeout status clearly, highlight remaining gaps, ask for decisions on open items

## Context Requirements

- **Critical (Must Read):**

  - **Feature Implementation State File** - The permanent state tracking document at `/doc/state-tracking/features/[feature-id]-implementation-state.md` containing implementation progress and context

- **Important (Load If Space):**

  - **Feature Tracking** - [Feature details from feature-tracking.md](../../../doc/state-tracking/permanent/feature-tracking.md) for feature context
  - **TDD (Technical Design Document)** - Acceptance criteria for confirming feature completeness

- **Reference Only (Access When Needed):**

## Process

> **⚠️ MANDATORY: Update Feature Implementation State File throughout finalization.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Review Implementation Readiness**: Examine the feature implementation state file (Issues & Resolutions Log, Implementation Progress) and confirm no open blocking issues remain (quality auditing — acceptance criteria, performance-vs-targets, security — is performed at the subsequent Code Review gate, not here)
2. **Verify Prerequisites**: Confirm all implementation tasks for the feature are complete and tests are passing
3. **Plan the Closeout**: Identify documentation gaps and remaining closeout items
4. **🚨 CHECKPOINT**: Present implementation readiness, prerequisites status, and closeout plan to human partner for approval

### Execution

5. **Complete Feature Documentation**: Finalize all feature documentation
   - Update code documentation (inline comments, README files)
   - Create/update user documentation (user guides, API docs) — see [User Documentation Creation](../07-deployment/user-documentation-creation.md) for the full handbook creation workflow. If user docs are not yet created for this feature, flag `❌ Needed` in the feature implementation state file's User Documentation section.
   - Document configuration requirements and environment variables
   - Update architecture diagrams if needed
6. **Conduct Final Validation**: Run the full test suite and verify all tests pass
7. **Update Feature Implementation State File**: Document finalization completion and any remaining items
8. **🚨 CHECKPOINT**: Present completed documentation and final validation results to human partner for review

### Finalization

9. **Finalize Feature Implementation State File in place**: Set the state file status to `COMPLETE` and record final notes. Do **not** move or rename it — it is the permanent living documentation hub and is never archived (see [PF-TEM-037](../../templates/04-implementation/feature-implementation-state-template.md))
10. **Update Feature Tracking**: Set the feature's status to 👀 Needs Review in feature-tracking.md ([Code Review](../06-maintenance/code-review-task.md) is the next gate; 🔎 Needs Test Scoping, 📖 Needs User Docs, and 🟢 Completed are set by their owning tasks)
11. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Complete Feature Documentation** - Finalized documentation in `/doc/features/[feature-name]/` including user guides, API documentation, and configuration guides
- **Updated Feature Tracking** - Feature status set to 👀 Needs Review in feature-tracking.md
- **Finalized Feature Implementation State File** - State file set to status `COMPLETE` in place at its permanent location `/doc/state-tracking/features/[feature-id]-implementation-state.md` (never archived — [PF-TEM-037](../../templates/04-implementation/feature-implementation-state-template.md))

## State Tracking

The following state files must be updated as part of this task:

- [Feature Implementation State File](../../state-tracking/permanent/feature-implementation-state-[feature-id].md) - Update **Implementation Progress** section to 100% completion, finalize **Implementation Notes** with lessons learned, set status to `COMPLETE` in place (never archived — PF-TEM-037)
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Update feature status to 👀 Needs Review

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Feature documentation completed (code docs, user guides, API docs) — or user docs flagged `❌ Needed` in the feature implementation state file
  - [ ] Full test suite passing
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Feature Implementation State File](../../state-tracking/permanent/feature-implementation-state-[feature-id].md) Implementation Progress updated to 100%
  - [ ] Implementation Notes finalized with lessons learned
  - [ ] Feature state file finalized in place (status `COMPLETE`); never archived (PF-TEM-037)
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) status set to 👀 Needs Review
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-055`, context "Implementation Finalization".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | Feature documentation | Manual | Code docs, user docs, configuration docs finalized |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Status updated to "👀 Needs Review" |
| **Updates** | Feature Implementation State File | Manual | Finalized in place (status `COMPLETE`) after 100% completion; never archived |

## Next Tasks

- [**Code Review**](../06-maintenance/code-review-task.md) - Review the implemented feature for quality

## Related Resources

- [Living-document maintenance craft (`feature-implementation-planning` skill)](../../../.claude/skills/feature-implementation-planning/references/living-document-maintenance.md) - Maintaining and finalizing the feature state file (replaces the retired Feature Implementation State Tracking Guide)
- [Release & Deployment Task](../07-deployment/release-deployment-task.md) - Owns all release and deployment mechanics
