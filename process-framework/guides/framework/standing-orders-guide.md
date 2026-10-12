---
id: FB-GDE-001
type: Process Framework
category: Guide
version: 1.1
created: 2026-08-25
updated: 2026-08-25
description: "The portfolio governance mechanism (PF-PRO-059, shipped by PF-PRO-071): what a workspace's Standing Orders grant table is, the grant classes and provenance markers, the tripwires, the Fast-Track Lane, and the owner-review contract - the agnostic mechanism whose per-workspace instance lives in each CLAUDE.md (instantiated from the standing-orders template)"
owned_by: FWK-FB
---

# Standing Orders

## Overview

**Standing Orders are the owner's revocable autonomy policy**: which change classes an agent executes autonomously (with provenance) and which require blocking approval. This guide is the **mechanism** — the vocabulary, markers, tripwires, and review contract, identical at every workspace. The **policy** — which grants a given workspace actually holds — lives in that workspace's own `CLAUDE.md` **Standing Orders section**, instantiated from the [Standing Orders Template](../../templates/support/standing-orders-template.md) and authored by the owner, never by an agent (an agent authoring its own autonomy grants is a conflict of interest).

Framework procedures reference this mechanism conditionally — "if your workspace's `CLAUDE.md` defines a **Standing Orders** section…" ([Task Execution Protocol](task-execution-protocol-guide.md)). A workspace without an instance simply has no grants: every checkpoint blocks, which is the safe default, not an error.

## When to Use

- **Every session, before task selection**: re-read the workspace's grant table (its `CLAUDE.md` is always loaded). Any grant tightens with one line there — **the tightest reading wins**.
- **When a task step names an autonomous class** (edge-file entries, Fast-Track, spillover, digest mode): this guide defines what the class means and which marker records the act; the workspace instance says whether the class is *granted* there.
- **When standing up or reviewing a workspace**: the instantiation and calibration rules below.

## Grant model

- **Autonomous (provenance required, no checkpoint)** — a *class* of change the owner has pre-authorized. Executing one replaces the step's checkpoint with a **provenance marker** (below), which is what makes the act reviewable after the fact. The grant is always the class, never the instance: if the concrete change outgrows its class mid-edit, stop and take the normal path.
- **Always escalate (blocking — the one-way doors)** — the classes no instance may grant: anything growing a core file or checklist; new steps, checkpoints, or rules; new mechanisms, scripts, templates, state files, or ID prefixes; deletions and retirements; blueprint structural changes; rollouts; raising any size budget. Autonomy covers **executing decided work, never the pipeline approving its own expansion** — the intake valve stays human.
- **Calibration rule** — grant sets start **narrow** and widen only on owner-review evidence (correction density per class, see the review contract). A producer workspace's blast radius is every child on the next rollout, so its grants default narrower than a leaf project's.

### Standard autonomous classes

The classes framework tasks already reference. An instance grants a subset by listing them; anything unlisted blocks.

| Class | What it covers | Provenance |
|---|---|---|
| **Edge-case file entries** | Create/append/rewrite a task's consult-on-stumble edge file (two-zone convention: core stays lean, rare-situation lore lives in the edge file). Lazy creation on first entry. A *silently-failing* class gets a detector/assert (two-strikes rule), never edge prose | the edge-file entry itself (names its provenance) |
| **Fast-Track Lane fixes** | Per the lane's criteria (below) | `[FAST-TRACK]` archive row |
| **Spillover filings** | A deferred remainder filed directly into the owning tracker section (existing scripts only; defer only across verification boundaries) | `[SPILLOVER PF-IMP-nnnn]` in Notes |
| **Single-script defect fixes** | One script, its verification kind green (Pester + convention gate for PowerShell; recorded before/after contrast run for Python) | `[AUTONOMOUS: single-script-fix]` in completion ValidationNotes |
| **Regenerating generated projections** | Doc maps, task metadata — drifted by any change | regeneration commit |
| **Tracker mutations via existing scripts** | Never hand-edits | the script's own audit trail |
| **Pipeline digest mode** | Tools Review / IMP Triage sessions file and route per their task definitions, ending with a digest to `feedback/reviews/` | the digest |

## Provenance markers

Defined **exactly as the scripts implement them** — the guide documents, the scripts are the source of truth:

- **`[FAST-TRACK]`** — written into the archive's Completed section by [`New-ProcessImprovement.ps1 -FastTrack`](../../scripts/file-creation/support/New-ProcessImprovement.ps1). Tools Review samples these retrospectively.
- **`[SPILLOVER PF-IMP-nnnn]`** — written into the owning tracker section's Notes, naming the originating IMP. A spillover chain deeper than one is a tripwire.
- **`[AUTONOMOUS: <class>]`** — written into a completion's ValidationNotes when an Autonomous grant replaced a task step's checkpoint, naming the class exercised.
- **Edge-file entries** — each entry names its own provenance (date + originating incident).

These four are what the owner-review soft anchor counts (below).

## Fast-Track Lane

An obvious framework fix executes directly — no approach checkpoint, no evaluation ceremony — when **all three** hold: (1) content/documentation only — no script behavior change (comment/docstring-only script edits count as content); (2) no new mechanism, section, or structure (wording, accuracy, link, stale-reference fixes); (3) every affected file is enumerated in-session (grep the pattern first) and the whole fix is contained in a single commit.

- **No IMP row yet**: fix inline and log via `New-ProcessImprovement.ps1 -FastTrack -Artifact "<file>" -Description "<what>" -Reason "<why>"` — the entry lands directly in the archive's Completed section with the `[FAST-TRACK]` marker.
- **Filed row**: claim it, **confirm the problem is still real and current** (stale rows are routine — if verification changes the filed scope, drop to the normal path), fix, and complete with `[AUTONOMOUS: fast-track]` in `-ValidationNotes`. **Excluded**: rows with coordination/sequencing conditions in Notes, and umbrella/consolidation rows.

If the fix grows past the criteria mid-edit, stop and take the normal path.

## Tripwires (auto-escalate to the owner)

1. **A gate/test failure not resolved in-session.**
2. **Oscillation** — the same core section edited by ≥2 sessions within one review interval. *Measurement note (appdev review finding, 2026-08-14)*: raw touch/commit counts overstate it — every guarded edit commits through `Release-ArtifactLock` — so measure by **distinct edit-days**, and weigh **direction**: a section reverted or rewritten is the churn signal; sustained additive growth is not.
3. **A spillover chain deeper than one.**
4. **An edge file passing ~150 lines** — promotion review: does this class need a detector/class-kill instead of more prose?

## Owner-review contract (event-based — no calendar timers)

- **Hard anchor**: an owner review is a precondition of [Framework Rollout](../../tasks/support/framework-rollout-task.md) **Mode B** (its Step 0) — nothing ships unreviewed.
- **Soft anchor**: when digests newer than the `Last review:` stamp reach **5**, or provenance-marked autonomous changes since the stamp reach **30**, surface *"owner review suggested"* in the session's recommend-next-action.
- **The review session**:
  1. Read pending digests in `feedback/reviews/` (their shape is the [Tools Review Summary Template](../../templates/support/tools-review-summary-template.md)'s Session Digest — **owner silence = consent; a veto is a scripted move-back**: rows move, never delete).
  2. Deep-dive **3–5 randomly sampled** autonomous changes — **one `imp-reviewer` agent per sampled change** (the shipped instrument in the workspace's root `.claude/agents/`; evidence-grounded findings, never verdicts). *Degradation rung*: where the instrument or a subagent runtime is absent, hand-review each sampled change against the same dimensions — the contract survives the mechanism.
  3. Act on tripwire flags; adjust the grants (the calibration metric is **correction density on sampled reviews** — rising density in a class tightens that class's grant).
  4. Update the stamp, including the counter: `**Last review:** YYYY-MM-DD (<digests read>; N sampled / M agent-reviewed; corrections X/N; grants adjusted: …)`. The `N sampled / M agent-reviewed` counter makes a review that spawned nothing visible in the very line Mode B Step 0 reads before shipping.

## Adjacent standing rules the grants lean on

- **Fresh foreign-lock force-release requires human approval** — [`Remove-ArtifactLock.ps1`](../../scripts/locking/Remove-ArtifactLock.ps1) is the manual override for a wedged *fresh* foreign lock; expired locks take over automatically at checkout.
- **Raising any size budget is an owner-escalation door** — [`Check-CoreFileBudget.ps1`](../../scripts/validation/Check-CoreFileBudget.ps1) enforces the budgets; a raise is recorded in the budget file's policy, never self-granted.

## Instantiating a workspace's Standing Orders

1. The owner and agent copy the [Standing Orders Template](../../templates/support/standing-orders-template.md) into the workspace's root `CLAUDE.md` and fill the grant table **narrow** (the calibration rule).
2. The grants are the owner's: the agent drafts, the owner decides — recorded at a checkpoint, not inferred.
3. The stamp starts `**Last review:** none (adopted YYYY-MM-DD)`; counters accrue from adoption.
4. Existing children receive the instance by per-workspace instantiation (a Mode C migration entry), never by overwrite — a child's `CLAUDE.md` carries its own content.

## Related Resources

- [Standing Orders Template](../../templates/support/standing-orders-template.md) — the per-workspace instance (FB-TEM-001)
- [Task Execution Protocol](task-execution-protocol-guide.md) — the two conditional delegation sites (Standing Orders authority; Fast-Track Lane)
- [Framework Rollout Task](../../tasks/support/framework-rollout-task.md) — Mode B Step 0, the hard review anchor
- [Tools Review Summary Template](../../templates/support/tools-review-summary-template.md) — the digest shape the review reads
- [Process Improvement Task](../../tasks/support/process-improvement-task.md) — the Step-6 exception and Skip-Step-13 rule that consume `[AUTONOMOUS: <class>]`
