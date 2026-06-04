---
id: PF-GDE-037
type: Process Framework
category: Guide
version: 4.0
created: 2025-07-29
updated: 2026-05-20
related_task: PF-TSK-009
guide_title: Process Improvement Task Implementation Guide
description: "Practical instructions for executing the Process Improvement task (PF-TSK-009)"
---
# Process Improvement Task Implementation Guide

## Document set

Three files cover the Process Improvement task:

- **[Task definition](../../tasks/support/process-improvement-task.md)** — the operative process: 17 steps to execute end-to-end
- **[Reference companion](process-improvement-task-reference-guide.md)** — tables and conventions you look up at specific steps: evaluation criteria, routing destinations, risk classes, common stale-description sites, TOOL_DOC_ID convention
- **This file** — worked examples, troubleshooting, and the reasoning behind the gates in this process

Read the task definition end-to-end at session start. Cross to the reference at the step that points to it. Read this guide when you want a pattern to imitate or to understand why a gate exists.

## Overview

This guide holds the **examples**, **troubleshooting**, and **explanation** content for the Process Improvement task — the worked patterns, recovery recipes, and gate rationales that don't belong inside the operative task definition or the flat-lookup reference.

## When to Use

- You have read the task definition and want a concrete IMP to use as a template (see [Examples](#examples))
- You hit a friction surface during execution and want a known-good response (see [Troubleshooting](#troubleshooting))
- You want to understand *why* a gate exists before deciding how to apply it at an edge case (see [Explanation](#explanation))

## Prerequisites

- Task definition (read first)
- A claimed improvement in [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) Section 2 — Improvements
- Source feedback from a [Tools Review summary](../../../process-framework-central/feedback/reviews/) or evaluation report that motivated the IMP

## Explanation

The task definition states the gates as operative rules. This section gives the reasoning behind each — so when you hit an edge case the rule doesn't cleanly cover, you can decide by intent rather than by literal-rule mechanical application.

### Conciseness rule (Step 3 → Step 6)

**What it says:** Present a one-line summary at Step 6 when all 7 evaluation criteria are favorable; present the full table only when at least one criterion rates poorly or triggers a gate.

**Why it exists:** The full 7-row table costs reading time and obscures the actual decision when the answer is "all good, here's the approach." A one-line summary keeps Step 6 focused on the proposal. The table is for cases where the analysis itself is the point — the human partner needs to see *which* criterion is failing.

**Edge case:** If a criterion is borderline (e.g., Recurring Value is "Medium" but you judge it as effectively High), state the borderline criterion in the one-line summary. The conciseness rule is about removing redundancy, not hiding nuance.

### Minimum-viability gate (Step 3 → Step 6)

**What it says:** If **Minimum Viability** rates "Yes" or "Not Explored", Step 6 must compare the proposed approach against the simpler alternative before committing.

**Why it exists:** IMPs often propose a structural fix when a doc-only or warning-only change would resolve the same friction. The gate forces the lighter alternative to be considered *out loud* — even when it loses, the comparison disciplines the choice. "Not Explored" gets the same treatment as "Yes" because absent exploration is indistinguishable from absent existence.

**Edge case:** If the simpler alternative was tried in a prior IMP and didn't work, cite that IMP at the Step 6 comparison. The gate satisfies itself with evidence, not ceremony.

### Root-cause-vs-symptom gate (Step 3 → Step 6)

**What it says:** If **Root-Cause Targeting** rates "Symptom-only", Step 6 must articulate the underlying defect and present both fix variants for human review.

**Why it exists:** Telltale symptom-fix framings ("add a flag to disable X", "add an option to skip Y") usually mean the *default* of X / Y is the actual bug. The gate forces the underlying defect to be named so the human partner can decide between fixing the default for everyone vs. adding an escape hatch for some callers. The symptom-fix is sometimes correct (root cause out of scope, or the symptom *is* the actual problem) — but the distinction must be surfaced before commitment.

**Edge case:** If the root cause is a third party or external dependency you can't change, name it as out-of-reach in the Step 6 surfacing. The gate's job is the articulation, not the resolution.

### Data-driven validation gate (Step 3)

**What it says:** When **Data-Driven Validation** rates "Analyzed", do not proceed to implementation until the analysis is complete — even if a multi-session data collection effort is needed.

**Why it exists:** IMPs born of intuition can read as obviously correct and still be wrong against the data. The IMP-525 precedent: a feedback-DB query found that the friction the IMP wanted to fix appeared in <2 % of sessions, while the proposed fix would have added overhead to all of them. Implementing intuition-only would have made the framework worse. If data is available *anywhere* in the project, it should validate or invalidate the IMP's premise before code moves.

**Edge case:** "No Data Available" is acceptable — the gate doesn't require manufacturing data. It requires that available data not be ignored.

### Solution exploration directives (Step 6)

**What it says:** Before proposing, explore the solution space — at minimum consider an MVP variant *and* a more radical alternative, weighting the radical option by its benefit ceiling rather than effort cost. Present 1–3 surviving options at Step 6; don't enumerate discarded ideas.

**Why it exists:** Without explicit exploration, the first viable approach becomes the chosen approach. The MVP variant is the floor (forces the question "is doing nothing structural enough?"), the radical alternative is the ceiling (forces the question "what would solving this *properly* look like?"). The presented set is what survived — the human partner's review budget doesn't pay for the exploration itself.

**Edge case:** If the solution space is genuinely 1-dimensional and the only meaningful axis is yes/no, state that explicitly at Step 6 so the human partner isn't waiting for alternatives that don't exist.

### Counter-proposal evaluation (Step 6)

**What it says:** When your proposed approach materially differs from the IMP description (counter-design, target re-routing, doc-only fix instead of code, scope reduction), run the counter-proposal through the same 7-criterion evaluation the IMP got. Present both evaluations at Step 6.

**Why it exists:** The IMP got scrutinized at Step 3. The counter-proposal is *also* raw input — usually shaped by the agent's read of the situation, not by independent verification. Without parallel scrutiny, the counter-proposal sneaks in via authority. Pay particular attention to Recurring Value (does the counter-proposal fire usefully across future sessions, or is it ceremony?) and Minimum Viability (would leaving it alone work?).

**Edge case:** A counter-proposal that's strictly narrower than the IMP (e.g., "just doc-fix the smaller of the two reported symptoms") doesn't need the full table — note the scope reduction and proceed. The gate is for materially different approaches, not for incremental scope adjustments.

### Reclassification domain heuristic (Step 6)

**What it says:** When reclassifying an IMP as a different artifact type (Bug, Feature Request, Tech Debt), apply the heuristic: `process-framework/` and `doc/` = IMP; `src/...` = BUG; `test/` = infrastructure (IMP) or product defect (BUG).

**Why it exists:** Triage at intake (Tools Review writing to Section 1) doesn't always classify correctly — raw feedback comes from session-end forms where the partner's framing might be product-shaped while the underlying issue is framework-shaped (or vice versa). The domain heuristic gives a fast, path-based pre-filter; the actual reclassification still requires reading the entry to confirm the underlying issue matches the heuristic's suggestion.

**Edge case:** Cross-path IMPs (e.g., framework script that operates on `src/`) belong to the framework path — the script is the artifact, its target isn't.

## Examples

### Example: Streamlining a Task-Definition Ecosystem

**Improvement:** [PF-IMP-865](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) — apply [PF-EVR-023](../../../process-framework-central/evaluation-reports/20260512-framework-evaluation-pf-tsk-009-process-improvement-task-and-surroundin.md) findings to PF-TSK-009 + PF-GDE-037 + PF-VIS-008 in one coordinated session.

**Preparation:**
- Read the source evaluation report and verify each finding against the current state of the target artifacts (line-level pre-confirmation before claiming)
- Surface the streamlining-vs-additive tension at Step 6 — the source IMP bundled 11 streamlining edits + 5 additive sub-rules; the session committed to streamlining-only and deferred the additive set
- Get the human partner's pick on a strategic sub-decision embedded in the IMP (slim the guide vs. retire it entirely) before execution

**Execution (medium-risk, batched):**
1. Task-definition edits: routing consolidation (one reference table replacing 3 scattered routing blocks), Step 1 callout collapse (4 nested callouts → bullet list), critical-callout demotion (5+ at top → 1 operative gate), vestigial-criterion removal
2. Guide slim: delete process narration that duplicated the task; keep Examples + Troubleshooting
3. Context-map full rewrite (was 11 months stale; described a workflow that no longer existed)

**Result:** Task + guide + context map shrink toward a stable shape. Same operational behavior; less cognitive overhead per session.

### Example: Adding Inline Guidance to a Task Step

**Improvement:** "Add cross-references for test-documentation standards to Step 11 of <task>"

**Preparation:**
- Read the feedback identifying the gap (e.g., bug-fix tests bypass the test registry)
- Read the target Step 11 to see current content
- Evaluate: reference another task's full process, or extract the relevant subset inline?

**Execution:**
1. Read the candidate full processes (Test Specification Creation, Integration & Testing) — verify scope matches the trigger
2. Extract the load-bearing pieces (test registry updates, `New-TestFile.ps1` for new files) and add as inline guidance
3. Cover both the common case (adding to existing test files) and the rare case (creating new test files)

**Result:** Step 11 has self-contained guidance; agents don't need to read unrelated 250-line task definitions to handle the routine path.

## Troubleshooting

### Approach Approval Skipped

**Symptom:** Implementation started without explicit approval at Step 6 (or without Step 9 approval when multiple alternatives were proposed).

**Resolution:**
1. Stop implementation immediately
2. Present current progress + planned approach to the human partner
3. Get explicit approval before proceeding

> Per-change sub-checkpoints (Step 10 a–d loop) are required only for **high-risk** changes. Skipping them on low- or medium-risk changes is correct — not a process violation.

### Linked Documents Missed

**Symptom:** After completing the improvement, other documents still reference the old version.

**Resolution:**
1. Grep for references to the changed file(s) across the project
2. Sweep the [common stale-description sites](../../tasks/support/process-improvement-task.md) listed in Step 11 (script header blocks, PF-documentation-map.md, process-framework-task-registry.md, READMEs, task definitions)
3. Update or remove outdated references

## Related Resources

- [Process Improvement Task Definition](../../tasks/support/process-improvement-task.md) — the canonical process
- [Process Improvement Task Reference](process-improvement-task-reference-guide.md) — flat-lookup tables and conventions
- [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) — IMP lifecycle state
- [Tools Review Task](../../tasks/support/tools-review-task.md) — upstream task that intakes IMPs into the central Section 1
- [IMP Triage Task](../../tasks/support/imp-triage-task.md) — sorts intake into destination sections (Improvements / Extensions / Structural Changes / Rejected)
- [Feedback Form Guide](../framework/feedback-form-guide.md) — feedback form procedures
