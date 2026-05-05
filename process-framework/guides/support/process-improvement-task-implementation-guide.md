---
id: PF-GDE-037
type: Process Framework
category: Guide
version: 2.3
created: 2025-07-29
updated: 2026-05-04
related_task: PF-TSK-009
guide_title: Process Improvement Task Implementation Guide
---
# Process Improvement Task Implementation Guide

## Overview

This guide provides practical instructions for executing the Process Improvement task (PF-TSK-009). The task follows a 17-step process: select an improvement from tracking, **verify the problem independently**, evaluate, plan with human approval, **execute by risk class**, and finalize. The IMP is treated as raw input, not a specification — PF-TSK-009 owns problem verification, solution exploration, and implementation.

## When to Use

Use this guide when you need to:
- Execute a Process Improvement task (PF-TSK-009) systematically
- Understand how to navigate the human feedback checkpoints
- Ensure all state tracking and documentation requirements are met

> **🚨 CRITICAL**: Never implement a solution without first getting explicit approval on the approach (Step 6 checkpoint). Per-change checkpoint frequency is risk-classified at Step 10 — low- and medium-risk changes execute in batch with a single decision review at Step 13; high-risk changes still use a per-change loop. Step 11 (linked-doc verification) and Step 12 (feedback-DB log) are silent housekeeping — do not surface them at the human checkpoint unless substantive findings emerge.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step-by-Step Instructions](#step-by-step-instructions)
3. [Examples](#examples)
4. [Troubleshooting](#troubleshooting)
5. [Related Resources](#related-resources)

## Prerequisites

Before you begin, ensure you have:

- Access to the Process Improvement task definition (PF-TSK-009)
- A prioritized improvement in [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md)
- Access to the [Tools Review summary](../../feedback/reviews) that identified the improvement
- Ability to make incremental changes with human partner approval

## Step-by-Step Instructions

### Phase 1: Preparation (Steps 1–6)

#### 1. Select and Claim the Improvement

1. **Open** [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md)
2. **Select** an improvement to execute (typically HIGH priority first)
3. **Claim** by setting status to **In Progress** via `Update-ProcessImprovement.ps1 -ImprovementId "IMP-XXX" -NewStatus "InProgress"` (covers parallel-session safety)

**Expected Result:** IMP claimed and locked from concurrent work

#### 2. Verify the Problem

The IMP description is raw input, not a specification. Independently confirm the problem still exists and is current.

1. **Grep recent sessions** for the symptom; **read the artifact** under discussion; **check IMP history** for prior similar reports; **inspect the feedback DB** if relevant
2. If the problem is clearly absent, already resolved, or trivially mis-described, **mark the IMP as Rejected** with rationale and skip to Step 14 — no human checkpoint needed at this gate

**Expected Result:** Either rejection at this gate, or a verified problem to evaluate

#### 3. Evaluate, Review Source, Read Current State

1. **Fill the evaluation table** (Step 3) — Still Valid / Recurring Value / Framework Fit / Maintainability / Complexity-to-Benefit / Minimum Viability / Root-Cause Targeting / Data-Driven Validation
2. **Read source feedback** (Tools Review summary, specific feedback forms) — Step 4
3. **Read current state** of the file(s)/tool(s) being changed — Step 5

> Apply the **conciseness rule**: if all evaluation criteria are favorable, present a one-line summary at the Step 6 checkpoint instead of the full table.

**Expected Result:** Verified problem, completed evaluation, and full understanding of current state

#### 4. Present and Get Approval (Step 6 CHECKPOINT)

Before presenting, **explore the solution space**: at minimum consider an MVP variant *and* a more radical alternative, weighting the radical option by its benefit ceiling rather than its effort cost.

1. **Restate the problem** in 1–2 sentences (your verified version, not a copy of the IMP description)
2. **Show the evaluation** (full table or one-line summary per the conciseness rule)
3. **Propose 1–3 surviving approaches** — do **not** enumerate ideas you discarded during exploration
4. **Wait for explicit approval** before any execution

**Expected Result:** Human approval of the chosen approach

### Phase 2: Execution (Steps 10–12)

#### 5. Execute by Risk Class

Classify the change set first:

- **Low-risk**: typo, wording, link fix, additive callout, single-file edit with no semantic change, formatting/style
- **Medium-risk**: behavior changes within one task/script/template, non-trivial logic, multi-file but bounded
- **High-risk**: structural change, cross-task or cross-script impact, change to a high-frequency workflow, anything affecting human-facing UX in repeated tasks

Then execute according to class:

- **Low-risk**: implement directly in batch — no per-change checkpoint
- **Medium-risk**: state the planned change set briefly, implement in batch — no per-change checkpoint (the Step 6 approval covers it)
- **High-risk**: per-change loop — present, **CHECKPOINT** approve, implement, **CHECKPOINT** confirm

State the classification you applied so the human can override it at the Step 13 review.

#### 6. Silent Housekeeping (Steps 11–12)

Do not surface these to the human at Step 13 unless substantive findings emerge:

1. **Verify linked documents** — grep for each modified file's path/filename, read surrounding context for each hit, apply updates where context is outdated. Mention at Step 13 only if substantive references were found and updated.
2. **Log tool change in feedback DB** — `python process-framework/scripts/feedback_db.py log-change ...`. Do not mention at Step 13.

**Expected Result:** All changes implemented; linked docs updated silently; tool change logged

### Phase 3: Finalization (Steps 13–17)

#### 7. Decision Review and Close (Step 13 CHECKPOINT)

1. **Present the diff** (what changed and why) and the **risk classification** you applied
2. Mention substantive Step 11 findings only if any were needed; do not mention Step 12
3. Get **approve / revise / reject** decision

> **Compressed format option**: If Step 11 sweep was clean AND the change matches the Step 6 plan with no deviation, present a one-line variant — *"Risk class: \<class\>. Step 11 sweep clean. No deviation from Step 6 plan. Approve / revise / reject?"* — instead of restating the diff. Use the full format whenever the change deviates from the Step 6 plan or Step 11 surfaced substantive findings.

#### 8. Update State and (at Session End) Submit Feedback

1. **Update Process Improvement Tracking** via `Update-ProcessImprovement.ps1 -ImprovementId "IMP-XXX" -NewStatus "Completed" -Impact "..." -ValidationNotes "..."`
2. **Update any other affected state files** (e.g., temp state file → archive to `state-tracking/temporary/old/`)
3. **Ask**: "Continue with another improvement or close the session?" If continuing and session limit (3) not reached, return to Step 1
4. **At session end** (last IMP done or 3-IMP limit reached): create the feedback form via `New-FeedbackForm.ps1` with task ID `PF-TSK-009` — one form covers all improvements done in the session

**Expected Result:** Tracking up to date; session closed cleanly with feedback recorded

## Examples

### Example: Streamlining a Task Definition

**Improvement:** IMP-038 — "Add lightweight mode to PF-TSK-009"

**Preparation:**
- Read the Tools Review summary identifying the problem (4/4 feedback forms flagged 27-step process as disproportionate)
- Read the current task definition to understand the 27-step structure
- Present analysis: testing infrastructure is the main bloat, steps 1-5 overlap with Tools Review

**Execution:**
1. Replace the 27-step process with a streamlined 14-step version
2. Remove testing infrastructure sections (Tools & Scripts, testing outputs, test tracking)
3. Simplify the completion checklist
4. Update linked documents (implementation guide, task registry, guides README)
5. Delete obsolete files (testing guide, test tracking template)

**Result:** Task reduced from 27 to 14 steps, 36% reduction in document size, clearer process flow

### Example: Adding Inline Guidance to a Task Step

**Improvement:** "Add test documentation cross-references to Step 11 of PF-TSK-007"

**Preparation:**
- Read the feedback identifying the gap (bug fix tests bypass test registry)
- Read PF-TSK-007 Step 11 to see current content
- Evaluate whether to reference other tasks or inline the relevant parts

**Execution:**
1. Evaluated PF-TSK-012 and PF-TSK-053 — determined their full processes are disproportionate for bug fix regression tests
2. Extracted the relevant pieces (test registry updates, New-TestFile.ps1 for new files) and added inline guidance to Step 11
3. Covered both scenarios: adding to existing test files (common) and creating new test files (rare)

**Result:** Bug fix tests now have self-contained guidance on test documentation standards without requiring agents to read unrelated 250-line task definitions

## Troubleshooting

### Approach Approval Skipped

**Symptom:** Implementation started without approval at Step 6 (or without approval at Step 9 when multiple alternatives were proposed)

**Solution:**
1. Stop implementation immediately
2. Present current progress and the planned approach to the human partner
3. Get explicit approval before proceeding

> **Note:** Per-change sub-checkpoints (Step 10 a–d loop) are required only for **high-risk** changes. Skipping them on low- or medium-risk changes is correct behavior — not a process violation.

### Linked Documents Missed

**Symptom:** After completing the improvement, other documents still reference the old version

**Solution:**
1. Search for references to the changed file(s) using grep/search
2. Check: implementation guides, context maps, task registries, README files
3. Update or remove outdated references

## Related Resources

- [Process Improvement Task Definition](../../tasks/support/process-improvement-task.md) - Complete task definition with all requirements
- [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) - State tracking for improvement initiatives
- [Tools Review Task](../../tasks/support/tools-review-task.md) - Upstream task that identifies and prioritizes improvements
- [Feedback Form Guide](../framework/feedback-form-guide.md) - Standard feedback form procedures
