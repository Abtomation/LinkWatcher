---
variant_group: code-review-paths
description: "Process steps and checklist for bug-fix reviews — claims-driven re-verification of the fix record, Dims-scoped examination, and the bug-tracking close/reject exit"
---

# Code Review — Bug-Fix Review Path

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this path's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

> **Parent task**: [Code Review](code-review-task.md) (PF-TSK-005)
>
> **Scope**: Reviews of a bug fix exiting [Bug Fixing](bug-fixing-task.md) at 👀 Needs Review — identified by a bug-tracking row (Dims column), not a feature implementation state file. The parent's scope guard (product code only) and its 🚫 NO CODE CHANGES rule apply here unchanged, with the one clarification in B5.

## Process

> **🚨 CRITICAL: Checkpoints block — present findings and wait for explicit approval before continuing.**

**B1. Select and scope the review**: Pick the bug at 👀 Needs Review in [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md). Working trees here often mix the fix with unrelated uncommitted edits (parallel sessions, LinkWatcher updates) — establish the change-set scope up front with `git diff HEAD -- <path>` cross-referenced against the bug's footprint, review only that change set, and verify interaction seams with adjacent changes without re-reviewing change sets already closed. On a **re-review** (a fix returning after this path's own rejection), scope to the fix delta recorded in the bug's `-VerificationNotes`, seam-check the previously passed scope, and check the rejected iteration's documentation (the feature state file's entry above all) against the current fix.

**B2. Read the bug's Dims column and the fix record** (fix details, root cause, tests added, verification notes; the bug fix state file for L-scope bugs). The Dims column scopes the whole review — the B4 examination, which of the parent's deep checks run at all (Steps 16–18: performance, accessibility, security), and the focus points from the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md); dimensions not listed are N/A.

**B3. 🚨 CHECKPOINT**: Present bug selection, change-set scope, and Dims focus for approval before analysis.

**B4. Examine the change set** against the parent task's Step 12 dimension bullets, scoped per B2 — mark non-listed dimensions N/A in your findings rather than walking each one. Run the parent's automated quality checks (Step 10) over the changed files.

**B5. Verify the fix record — its claims, not suite state**: enumerate what the record claims — tests that pin the defect, the validation script and its headline numbers, suite state, coverage of the changed code, and the Bug Fixing similar-issues enumeration in `-FixDetails` (a site its invariant governs that the line omits is a finding) — and **re-derive each from the live tree**; a re-review holds the current fix iteration to the same bar. A transient, fully restored break of the fixed mechanism, made to confirm exactly its tests go red, is re-derivation — not a code change under the parent's NO CODE CHANGES rule. The author's bar is the [Test Authoring Guide — Phase 3](../../guides/03-testing/test-authoring-guide.md#phase-3-prove) (PF-GDE-079); the contrast record in the fix record (`-VerificationNotes` / `-TestsAdded`) is the evidence to re-derive against. Then run the full suite (`Run-Tests.ps1 -All`) to confirm no regressions beyond the change set — attributing any failure outside it per [Test Infrastructure Guide — Attributing a Failure You Did Not Cause](../../guides/03-testing/test-infrastructure-guide.md#attributing-a-failure-you-did-not-cause) before it becomes a finding.

**B6. Identify and route discovered defects** per the parent's Steps 20–21 — same finding taxonomy and routing table (bugs → bug tracking, tech debt → technical-debt tracking, implementation gaps → feature state file).

**B7. 🚨 CHECKPOINT**: Present findings (severity levels per the parent's Step 23 scale), the re-derivation results from B5, and a close/reject recommendation.

**B8. Update [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md)** (Feature Tracking is N/A when the underlying feature is already Implemented):
- **On approval**: transition 👀 Needs Review → 🔒 Closed via `Update-BugStatus.ps1 -BugId "PD-BUG-XXX" -NewStatus "Closed" -VerificationNotes "Code review approved, no regressions"`.
- **On rejection**: transition back to 🟡 In Progress via `Update-BugStatus.ps1 -BugId "PD-BUG-XXX" -NewStatus "InProgress" -VerificationNotes "<review findings summary>"`, then route to [Bug Fixing](bug-fixing-task.md) — the `-VerificationNotes` summary is the carrier the next Bug Fixing session reads.

**B9. 🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below.

## Outputs

- **Updated Bug Tracking** — close or reject recorded via `Update-BugStatus.ps1 -VerificationNotes`, plus any findings routed at B6. A standalone review document is optional — create one only when the review's depth warrants it.

## ⚠️ Task Completion Checklist (bug-fix path)

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C).

- [ ] Change-set scope established and approved at B3
- [ ] Examination and deep checks scoped to the bug's Dims column (non-listed dimensions N/A)
- [ ] Every claim in the fix record re-derived from the live tree (B5) — including that the fix's tests can actually fail
- [ ] Full suite run; any failure attributed
- [ ] Discovered defects routed per the parent's routing table
- [ ] Bug Tracking updated: 🔒 Closed on approval, or 🟡 In Progress with the findings carrier on rejection
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-005`, context "Code Review".
