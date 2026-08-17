---
id: PF-GDE-072
type: Process Framework
category: Guide
version: 1.7
created: 2026-06-15
updated: 2026-07-30
description: The universal execution spine every task runs under — task selection, role adoption, the Read-Do step contract, and session-end (state updates and feedback). The selected task's definition plugs in at a placeholder. Holds once what was formerly stamped into every task (PF-IMP-1128 / F4).
---

# Task Execution Protocol

> **🚨 This is the operative procedure for executing ANY task — not background reference.** Every task in this framework runs under this protocol. Task definitions hold only their task-specific content (purpose, context, process steps, outputs); the universal contract — role adoption, step discipline, completion, feedback — lives here, once.

## How this page works

You are routed here first. This page walks the three phases every task shares. At **Phase B** you open your selected task's definition and execute *its* steps; then you return here to close out. The task file is the **placeholder content** that plugs into this spine.

```
entry point ──▶ THIS PROTOCOL ──▶ select task (ai-tasks.md table)
                                 └▶ ▶ PLACEHOLDER: execute the selected task's own Process steps
                                 └▶ return here for completion + feedback
```

> **Why following the link matters:** this framework is a graph of linked documents you are expected to traverse, not a single file. Content placed behind a link (this protocol, a task definition, a step-referenced lookup table) is **load-bearing and mandatory**, exactly as if it were inlined. Do not skip a linked document because the pointer "looked optional."

---

## Phase A — Before the task

1. **🚨 Select a task FIRST.** Establish what the request refers to and where that work currently stands, then match it against the **Use When** column in the [task table](../../ai-tasks.md#task-definitions). Task selection is your **very first action** — before any code exploration, file reading, or other work. If no task's Use When matches, **stop and ask the human partner**; do not invent a task. (See [How to Choose a Task](../../ai-tasks.md#how-to-choose-a-task) and the framework/product disambiguation note.)
2. **Read the COMPLETE task definition**, including its completion checklist, before starting — understand the full scope and all required outputs (not just the primary deliverable).
3. **Adopt the AI Agent Role** the task specifies (its Role / Mindset / Focus Areas / Communication Style) for the duration of the task.
4. **Note the feedback-form requirement now** (Phase C) so it shapes how you work, rather than being reconstructed at the end.

## Phase B — During execution

5. **▶ PLACEHOLDER — execute your selected task's `## Process` now.** Follow the task definition step-by-step, **Read-Do**: seed a faithful per-step checklist (one item per numbered step *and* sub-step, transcribed 1:1, never grouped or summarized), then work one step at a time — re-read the step, do it, and give it an explicit disposition: `done` / `skipped (reason)` / `N-A (reason)`. No step is silently dropped. On an error, surprise, or ambiguous fork at any step, check the task's **edge-case file** if one exists (linked from the task definition or its craft skill) — it holds consult-on-stumble incident guidance.
6. **Human-checkpoint steps block.** Where a task step is marked as a checkpoint, present findings and **wait for explicit approval** before continuing — never proceed past a checkpoint on your own judgment. If your workspace's `CLAUDE.md` defines a **Standing Orders** section, it is the authority on which change classes are pre-authorized (autonomous, provenance required) and which require blocking approval.
7. **Always use the automation scripts** a task references (never hand-create tracked files). Scripts maintain surrounding infrastructure — ID registries, tracking tables, counters — that manual edits miss. If a script fails: report the error → diagnose and fix the script → re-run it. Never bypass a broken script by creating files manually.
8. **Update state files as you progress**, not only at the end.

> **🔒 Artifact checkout locking** *(applies only where `doc/project-config.json` has
> `locking.enabled: true` — with the block absent or false, skip this box entirely)*: guarded
> artifacts are edited under per-file micro-locks so parallel sessions never edit the same
> file simultaneously. The cycle, one file at a time:
> `process-framework/scripts/locking/Checkout-Artifact.ps1 -Path <file> -Holder "<task + context>"`
> immediately before directly editing (Edit/Write) a guarded file →
> edit → `Release-ArtifactLock.ps1 -Path <file>` **directly after that file's edits are
> done** (it commits the file path-scoped, then unlocks — commit-then-release). A session
> never holds two locks. Script-mediated writes (`New-*`/`Update-*`/generators) need no
> locks. Frontmatter revision stamps are release-maintained (PF-IMP-1900): releasing a
> changed markdown artifact sets its `updated:` date and increments its `version:` last
> segment automatically — never hand-compute a bump; script writes stamp `updated:` through
> their own helper, and a deliberately mechanical fleet sweep with no semantic change bumps
> nothing (state that in its completion notes). On a collision the checkout errors naming the holder — edit something else or retry
> shortly; a lock idle past the TTL is taken over automatically; force-releasing a *fresh*
> foreign lock (`Remove-ArtifactLock.ps1`) requires human approval. Enforcement is
> mechanical: a PreToolUse hook blocks lockless guarded edits, so an unexpected
> "NOT CHECKED OUT" block means run the checkout, not a workaround. (PF-PRO-061; appdev
> path prefix: `blueprint/process-framework/scripts/locking/`.)

## Phase C — Before claiming completion

9. **Verify ALL outputs by re-reading files, and reconcile the per-step checklist.** Do not rely on memory: re-read state tracking files and grep for `- [ ]` / `PENDING` / `NOT_STARTED` to confirm nothing was missed. Walk the per-step checklist from Phase B and confirm every step carries an explicit disposition. *"I think I'm finished"* is not a stop condition; *"every step accounted for"* is.
10. **Complete every item** in the task's mandatory completion checklist — every checkbox, every state-file update, every linked document.
11. **Complete feedback forms** for the tools used (see [Feedback step](#feedback-step) below). Do not solicit human feedback; the human partner appends to the Human Intervention Log after the session.

> **Committing** (PF-IMP-1876 — no per-session commit step): where artifact locking is enabled, guarded edits are already committed by their lock releases; the remaining script-written residue (tracker rows, registries, regenerated maps) and pushes ride periodic [Git Commit and Push](../../tasks/07-deployment/git-commit-and-push.md) **Mode B** remainder sweeps, run when the human asks. A scoped **Mode A** commit remains available when the human asks to commit specific work. Do not offer or perform **Git Commit and Push** runs unasked — this does not restrain the lock-release commits above, which are part of the editing protocol rather than a commit decision.

> **🚨 The task is NOT complete until every step, the completion checklist, the state-file updates, and the feedback form are all finished.**

---

## Feedback step

At the end of **each session** (not the end of a multi-session task), create one feedback form and fill in all sections:

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-FeedbackForm.ps1 -DocumentId "PF-TSK-XXX" -TaskContext "Task Name" -FeedbackType "MultipleTools" -Confirm:\$false
```

- `FeedbackType`: `SingleTool` | `MultipleTools` | `TaskLevel`.
- Use the **task ID** (e.g. `PF-TSK-009`) in `-DocumentId`, never an artifact ID created during the task.
- Full guidance: [Feedback Form Guide](feedback-form-guide.md) and [Feedback Form Completion Instructions](feedback-form-completion-instructions.md).

> If your workspace's `CLAUDE.md` defines a **Fast-Track Lane**, small already-applied framework fixes are logged per that rule instead of running a full task — decide that *before* task selection.

## Operating principles (apply throughout)

- **One batch per session for validation tasks** — never run multiple validation batches in one session; each batch closes out through its own checkpoint → report → state updates → feedback cycle.
- **Minimize documentation overhead** — update state files rather than creating new docs; record decisions in the appropriate state file.
- **Follow step-referenced lookups** — when a task step says "consult table X" or links a guide at the point of use, follow it; that content is part of the step.
- **Collaborate on decisions** — present options with trade-offs at genuine decision points; ask when requirements are unclear.
- **Classify discovered issues before filing** — when you find a defect, gap, or improvement opportunity outside the current task's scope, route it via the [Issue Classification and Routing Guide](issue-classification-and-routing-guide.md) (product bug / feature request / framework improvement / technical debt) rather than dropping it or guessing the tracker.
- **LinkWatcher maintains references automatically** — move/rename files by any method; do not hand-fix path references unless LinkWatcher demonstrably missed one (then investigate the root cause).
- **Parallel-session safety on shared files** — when editing files multiple sessions touch (`ai-tasks.md`, the ID registries, generator scripts and their projections), **read immediately before you write** so a concurrent edit isn't clobbered by a stale snapshot. A `Build-TaskMetadata.ps1` / `Build-DocumentationMap.ps1` `-Check` failure that traces to *another* slice's in-flight generator change is **non-blocking** — re-run after that slice lands rather than reverting it. Surface pre-existing drift to its owner; don't sweep unrelated drift into your change.

## Related Resources

- [AI Task-Based Development System (ai-tasks.md)](../../ai-tasks.md) — the task catalog this protocol selects from
- [Feedback Form Guide](feedback-form-guide.md)
- [Visual Notation Guide](../support/visual-notation-guide.md) — for interpreting any diagrams a task references
