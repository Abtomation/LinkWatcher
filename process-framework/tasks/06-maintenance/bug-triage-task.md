---
id: PF-TSK-041
type: Process Framework
category: Task Definition
version: 1.15
created: 2025-08-30
updated: 2026-09-29
description: "Systematically evaluate, prioritize, and assign reported bugs"
complexity: simple
use_when: >-
  Systematically evaluate, prioritize, and assign reported product bugs. Triggers: 'triage this bug', 'evaluate bug report X', 'prioritize the bug backlog'
triggers:
  - "triage this bug"
  - "evaluate bug report X"
  - "prioritize the bug backlog"
automation: semi
scripts:
  - ../../scripts/update/Update-BugStatus.ps1
trigger_status:
  - file: bug-tracking.md
    status: "🆕 Needs Triage"
output_status:
  - raw: "`bug-tracking.md` → `🔍 Needs Fix` + priority (Critical/High/Medium/Low) + scope (S/M/L) + Dims"
next_tasks:
  - task: bug-fixing-task.md
    condition: "To resolve triaged bugs"
  - task: ../01-planning/feature-request-evaluation.md
    condition: "If bugs reveal need for new functionality, or a chain decision routes the class to a behaviour change"
---

# Bug Triage

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Systematically evaluate, prioritize, and assign reported bugs to ensure efficient resource allocation and timely resolution of issues based on their impact, severity, and business priority.

## AI Agent Role

**Role**: Bug Triage Specialist
**Mindset**: Analytical, priority-focused, systematic evaluation
**Focus Areas**: Impact assessment, priority assignment, resource allocation, stakeholder communication
**Communication Style**: Ask detailed questions about bug impact and user experience, request reproduction steps, discuss priority rationale

## Context Requirements

- **Critical (Must Read):**

  - [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - Current bug registry and status
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - To understand feature priorities and relationships

- **Important (Load If Space):**

  - [Feature Implementation State Files](../../../doc/state-tracking/features) - State file for the affected feature (known issues, related bugs, implementation progress, Dimension Profile)
  - [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md) - Dimension definitions for identifying which dimensions a bug affects
  - [Project Architecture](../../../doc/technical/architecture) - Understanding system architecture for impact assessment

- **Reference Only (Access When Needed):**
  - [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - For process-related bug patterns

## Process

> **⚠️ MANDATORY: All bug triage decisions must be documented with clear rationale.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. Review the [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) document to identify bugs with status 🆕 Needs Triage or bugs that need reopening (see [Reopen Workflow](#reopen-workflow) below)
2. Gather all available information about each bug (reproduction steps, screenshots, logs)
3. **Identify each bug's feature** in [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — the owner of the code the defect lives in; a filed Related Feature is only a hint, often naming the feature whose review surfaced the bug. Record `none` when no feature owns that code, naming the path in the rationale. Then read the current development priorities there.
4. For each bug, read that feature's [implementation state file](../../../doc/state-tracking/features) for known issues, related bugs, status, and **prior analysis of this defect** in its issues log; cite any in the triage notes.
5. **Walk the chain**: read the derived **Open chains** line in [Bug Statistics](../../../doc/state-tracking/permanent/bug-tracking.md#bug-statistics), then follow each bug's **Origin** cell back through the registry and the archive. For a bug with no Origin, scan both for an unlinked sibling on its **Related Feature** — above all a closed bug of the same class whose fix left this bug's path uncovered. Record each bug's chain, or that it is a singleton.
6. **🚨 CHECKPOINT**: Present bug inventory, initial analysis, and current development priorities to human partner. For small rounds (1–2 bugs), combine this with the Step 12 decision checkpoint into a single gate — carry the inventory through evaluation and present it together with the triage decisions at Step 12

### Evaluation

7. **Assess Bug Validity**: Determine if the reported issue is actually a bug
   - **Description Accuracy**: Reproduce the report at the cheapest level that exercises it, and correct the description in the bug report to match observed behavior before assigning severity/priority. In the triage notes, a mechanism you only read, or a regression test not seen to fail, is labeled *inferred*; no mechanism may dismiss evidence it does not explain.
   - Confirm expected vs actual behavior — expected as the affected feature's [FDD](../../../doc/functional-design/fdds) defines it (business rules, acceptance criteria) where one exists, not as the report assumes
   - **Wrong tracker? Reclassify and route.** If the issue is not a product bug — it describes desired new behavior, a framework defect, or technical debt — reclassify it using the [Issue Classification and Routing Guide](../../guides/framework/issue-classification-and-routing-guide.md) (product bug / feature request / framework improvement / technical debt, decided by where the corrective fix lands). Close the bug ("Not a Bug" / reclassified) and file it in the tracker that guide names.
8. **Evaluate Impact and Severity**:
   - **Critical**: System crash, data loss, security vulnerability
   - **High**: Major feature not working, significant user impact
   - **Medium**: Minor feature issue, workaround available
   - **Low**: Cosmetic issue, minimal user impact
9. **Identify Affected Dimensions**: Determine which development dimensions the bug impacts using the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md):
   - Reference the affected feature's Dimension Profile from its implementation state file for context
   - Identify the subset of dimensions this bug affects (e.g., `SE DI` for a bug causing data loss through unsanitized input)
   - Record abbreviations only, at every scope — an L bug's detailed dimension context goes into its Bug Fix State File at Bug Fixing
10. **Determine Priority Level** (per the [Priority Assignment Matrix](#priority-assignment-matrix)):
   - **Critical**: System breaking, security issues - Immediate response
   - **High**: Major functionality affected - Within 24 hours
   - **Medium**: Minor functionality affected - Within 1 week
   - **Low**: Cosmetic or enhancement requests - When time permits
11. **Check for Duplicates**: Compare with existing bugs to identify duplicates
11b. **Take the chain decision** (mandatory once the Step 5 chain reaches its **third** member): N independent defects, or one design defect with N symptoms? Record the answer; each member stays its own bug either way. Four outcomes, three routing the class to an existing container:
    - **Independent** — legitimate; state what distinguishes the members.
    - **One fix** — triage the newest member **Scope = L**, engaging [Bug Fixing](bug-fixing-task.md)'s multi-session gate and its state file's **Chain** line.
    - **Design debt** — a missing abstraction: [`Update-TechDebt.ps1 -Add`](../../scripts/update/Update-TechDebt.ps1) naming the members.
    - **Behaviour change** — [Feature Request Evaluation](../01-planning/feature-request-evaluation.md).
12. **🚨 CHECKPOINT**: Present triage decisions (priority, scope, affected dimensions, duplicates, fix order, rationale) to human partner for approval — including, for any third-or-later chain member, the Step 11b chain decision and which container it routes to

### Assignment and Documentation

13. **Record the triage**: one [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) call per bug moves it from 🆕 Needs Triage to 🔍 Needs Fix, into its priority table, and recalculates the statistics. Its parameters carry the decisions:
    - `-Priority` (Step 10), `-Dims` (Step 9), `-RelatedFeature` (Step 3)
    - `-Scope` per [Scope Levels](../../../doc/state-tracking/permanent/bug-tracking.md#scope-levels) — **S** when the fix approach is settled, **M** when it carries an unresolved design fork, **L** when it spans sessions or Step 11b took the one-fix decision
    - `-Workflows` — only the [workflows](../../../doc/state-tracking/permanent/user-workflow-tracking.md) that reach the defective code path, not every one the feature joins: Bug Fixing derives that list itself, and an extra entry becomes a false E2E re-execution. Re-check a pre-filled list the same way; `none` when no workflow does
    - `-OriginBug` — the Step 5 chain link the reporter did not know; omit it for a bug with no origin. The id must resolve to an existing row, live or archived, or the call is refused
    - `-TriageNotes` — the rationale behind each value, plus any fix order binding this bug to another (which lands first, and why)
    ```powershell
    ../../scripts/update/Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "NeedsFix" -Priority "High" -Scope "S" -RelatedFeature "1.1.1" -Dims "SE DI" -Workflows "WF-001, WF-003" -OriginBug "PD-BUG-000" -TriageNotes "Rationale for priority and scope"
    ```

### Finalization

14. **Update Bug Registry**: Ensure all bug information is properly recorded
15. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Triage Decision Framework

### Priority Assignment Matrix

| Impact | Frequency | Priority |
| ------ | --------- | -------- |
| High   | High      | Critical |
| High   | Medium    | High     |
| High   | Low       | High     |
| Medium | High      | High     |
| Medium | Medium    | Medium   |
| Medium | Low       | Medium   |
| Low    | High      | Medium   |
| Low    | Medium    | Low      |
| Low    | Low       | Low      |

### Severity vs Priority Guidelines

- **Severity**: Technical impact of the bug
- **Priority**: Business urgency for fixing the bug
- A low-severity bug can have high priority if it affects critical business functions
- A high-severity bug can have lower priority if it affects rarely-used features

### Special Considerations

- **Security Issues**: Always Critical regardless of other factors
- **Data Loss Bugs**: Always Critical regardless of other factors
- **Regression Bugs**: Priority based on affected feature priority
- **Performance Issues**: Priority based on user impact and frequency
- **Chain members**: for a third-or-later member (Step 11b), read the matrix's **Frequency** axis at the **class** level — a recurring class is High frequency however rare each instance is. Priority follows; the Step 11b routing is the stronger lever.

## Reopen Workflow

When a previously closed bug recurs, decide whether to **reopen** the original or **create a new bug**:

| Reopen the original | Create a new bug |
|---|---|
| Same root cause as the original fix | Different root cause or different component |
| Fix was incomplete or regressed | Similar symptom but distinct underlying issue |
| Discovered shortly after closure | Original was closed long ago and codebase has changed significantly |

> **The new bug carries the link.** Routing a recurrence to a new bug is right, but on its own it atomises the chain. File it with `-OriginBug <the closed bug>` so Step 5 can still walk it.

### Steps to reopen a bug

1. **Update status** using the automation script:
   ```powershell
   ../../scripts/update/Update-BugStatus.ps1 -BugId "PD-BUG-XXX" -NewStatus "Reopened" -ReopenReason "Description of why the bug recurred"
   ```
   This automatically moves the entry from the Closed section back to the correct active priority table and recalculates statistics.
2. **Re-evaluate priority and scope** — the original priority and scope may no longer apply (e.g., a Low bug that now causes data loss becomes Critical)
3. **Continue with the normal Evaluation steps** (Steps 7–12) to update the triage rationale

## Outputs

- **Updated Bug Registry** - [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with triaged bugs
- **Triage Documentation** - Clear rationale for all priority and scope assignments
- **Duplicate Identification** - Consolidated duplicate bugs with cross-references

## State Tracking

The following state files must be updated as part of this task:

- [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - Update with:
  - Bug status changed from 🆕 Needs Triage to 🔍 Needs Fix
  - Priority and scope assignments
  - Triage rationale and notes
  - Related feature references
  - Updated statistics

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Evaluation Completeness**: Confirm all reported bugs have been evaluated

  - [ ] Bug validity has been assessed for all reported bugs
  - [ ] Impact has been evaluated and scope (S/M/L) has been determined
  - [ ] Affected dimensions have been identified and recorded in the Dims column
  - [ ] Priority has been assigned using the decision matrix
  - [ ] Duplicate bugs have been identified and consolidated
  - [ ] Every bug's chain position established (Origin walked, or singleton recorded); for any third-or-later member, the Step 11b chain decision taken, recorded, and routed
  - [ ] Triage rationale is documented for all decisions

- [ ] **Verify Documentation**: Confirm proper documentation

  - [ ] All bugs have clear priority and scope assignments
  - [ ] Triage rationale is documented for each bug
  - [ ] Related features are identified and linked
  - [ ] Affected workflows are identified and recorded in the Workflows column

- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Bug Tracking document reflects all triage decisions
  - [ ] Bug status updated from 🆕 Needs Triage to 🔍 Needs Fix
  - [ ] Statistics section is updated with current numbers
  - [ ] All required fields are populated for triaged bugs
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-041`, context "Bug Triage".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`bug-tracking.md`](../../../doc/state-tracking/permanent/bug-tracking.md) | [`Update-BugStatus.ps1`](../../scripts/update/Update-BugStatus.ps1) | Update bug status from 🆕 Needs Triage to 🔍 Needs Fix<br/>• Automated priority (Critical/High/Medium/Low) and scope (S/M/L) assignments<br/>• Automated status emoji updates (🔍 Needs Fix)<br/>• Automated timestamp and notes updates<br/>• Auto-moves bugs between active/Closed sections on Close/Reopen<br/>**Usage:** Step 13 |

## Next Tasks

- [**Bug Fixing**](bug-fixing-task.md) - To resolve triaged bugs

- [**Feature Request Evaluation**](../01-planning/feature-request-evaluation.md) - If bugs reveal need for new functionality, or a chain decision (Step 11b) routes the class to a behaviour change. It is the entry point for every change request; it classifies and routes onward to the implementation chain.

<!-- merged from transition-registry entry: Bug Triage -->
### Prerequisites for Transition

- [ ] Bug impact assessment completed
- [ ] Priority level assigned (Critical 🔴, High 🟠, Medium 🟡, Low 🟢)
- [ ] Resource assignment determined
- [ ] Bug status updated to 🔍 Needs Fix
- [ ] Scheduling decision made based on priority

**Next Task Selection Decision:**

```
What priority was assigned?
├─ 🔴 Critical → Immediate Bug Fixing (within 24 hours)
│   └─ Reason: Critical bugs require immediate attention
├─ 🟠 High → Scheduled Bug Fixing (within 1 week)
│   └─ Reason: High priority bugs need prompt resolution
├─ 🟡 Medium → Backlog Assignment → Planned Bug Fixing
│   └─ Reason: Medium priority bugs can be scheduled with regular development
└─ 🟢 Low → Future Backlog → Bug Fixing when resources available
    └─ Reason: Low priority bugs addressed during maintenance cycles
```

### Preparation for Next Task

Critical and High bugs go to Bug Fixing now; Medium and Low go to the backlog with a timeline estimate. Where a chain decision routed the class to a container, name that container in the handover so the next session works the class, not just the instance.

## Related Resources

- [Bug Tracking State File](../../../doc/state-tracking/permanent/bug-tracking.md) - Central bug registry
- [Feature Tracking State File](../../../doc/state-tracking/permanent/feature-tracking.md) - Feature priorities and relationships
- [Task Transition Registry](../../infrastructure/task-transition-registry.md) - Guidance on transitioning between tasks
