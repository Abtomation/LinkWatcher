---
name: imp-triage
description: >-
  Craft for classifying and routing raw framework-improvement (IMP) Intake rows well — the
  judgment half of the framework's IMP Triage task (PF-TSK-089). Covers the classification
  decision tree, already-covered reconciliation and staleness checks, priority inputs
  (human-correction provenance, ratings trends), cluster detection and consolidation, re-route
  patterns, and triage-helper invocation. Activated only from the IMP Triage task's
  Check-Recommended-Skills step (via recommended_skills); not a merit-evaluation or
  implementation skill.
user-invocable: false
---

# IMP Triage Craft

This skill owns the **craft** of triaging IMPs — the recurring judgment calls of classifying
Intake rows and detecting clusters. It is the craft home for the **IMP Triage task
(PF-TSK-089)**, which owns everything else: the step sequence, checkpoints, section schemas,
integrity checks, and the feedback form.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** apply moves
> from this skill on its own initiative — classification decisions flow through the task's
> classification pass and are recorded in its session digest for post-hoc owner review
> (digest mode; the owner's veto is a scripted move-back).

> **🚨 Scope guard (mirrors the task's).** Triage classifies and routes. It does **not**
> evaluate IMP merit, propose solutions, or implement anything. If the thinking drifts past
> "Reject-vs-route" into "should we even do this?", stop — that judgment belongs to the
> receiving task.

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. It points at the framework's agnostic scripts (run from
the project root):

- `process-framework/scripts/update/Update-ProcessImprovement.ps1` — the triage helper
  (`-MoveToSection` moves rows between sections and transforms column schemas).
- `process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1` — creates a
  consolidating IMP; `-Supersedes` closes the source rows in the same call.
- `process-framework/scripts/Find-Improvement.ps1` — keyword search across open sections and
  the archive (`-Scope Open`); long Notes cells defeat plain line grep.
- `process-framework/scripts/feedback_db.py` — per-tool ratings drill-down
  (`report --tool <tool_doc_id>`) for a contested priority read.

Invocation patterns, auto-default behavior, and failure modes:
[references/helpers-reroutes-troubleshooting.md](references/helpers-reroutes-troubleshooting.md).

## Classification decision tree

Use top-down per Intake row; the first rule that fires wins.

```
0. Does another workspace OWN the artifact this row targets (its ownership line names
   a workspace that is not this one)?
   → Escalate to that workspace's Intake (-EscalateTo), do not classify locally.
   Ambiguity escalates by default. Home-tree resolution, the escalate/don't-escalate
   boundary, and the reason-writing rule: references/classification-and-priority.md.

1. Already resolved, cannot reproduce, or duplicates an open IMP already classified?
   → Rejected (one-line Rejection Reason) — or treat as a cluster member.
   Run the RECONCILIATION CHECK first (four already-covered sources + a staleness
   spot-check): see references/classification-and-priority.md.

2. Requires multiple new framework artifacts (task + template + script + guide), a
   workflow that doesn't exist today, or a behavior-preserving refactor whose scale
   exceeds PF-TSK-009's single-session shape (shared helper + many callers,
   multi-session)?
   → Extensions (PF-TSK-026)

3. Moves/renames files, reorganizes directories, or reshapes the framework such that
   projects' working docs need migration entries?
   → Structural Changes (PF-TSK-014)

4. Otherwise (bug-fix-shaped, content update, behavior-preserving script edit, stale
   reference, typo, regex/validation tweak):
   → Improvements (PF-TSK-009)
```

**Ambiguity rule**: when two routes are equally arguable, route on your recommendation and
name the ambiguity **individually** in the task's session digest (both options + why the
pick) — never silently pick one. Edge-case routing
table and the common ambiguous pairs:
[references/classification-and-priority.md](references/classification-and-priority.md).

**Priority is evidence-adjusted, not gut-feel**: `[HUMAN-CORRECTION]`-marked rows start one
priority level higher, as do `[RECURRENCE of PF-IMP-NNN]`-marked rows (a completed fix that
failed to hold); ratings-trend queries separate chronic problems from one-off complaints.
Same reference file.

## Cluster detection

Scan Intake against all open sections (never Completed/Rejected). A cluster requires **all
three** signals — same primary read-set, linked decisions, coherent scope — and **tension
forces consolidation** regardless of agreement. Criterion detail, counts/doesn't-count
contrasts, thresholds, and compressed worked examples (clusters routing to Extensions,
Improvements, and Structural Changes alike):
[references/clusters-and-consolidation.md](references/clusters-and-consolidation.md).

**Destination is independent of cluster shape** — classify the *combined work scope* through
the decision tree above; a cluster is not automatically an Extension.

## What the helper supports (move topology)

`-MoveToSection` handles: Intake → Improvements/Extensions/StructuralChanges/Rejected, and
triaged-section → triaged-section/Rejected (re-routes get an auto `[REROUTED …]` Notes prefix).
`-EscalateTo <workspace-id>` is the separate cross-tracker operation (Rule 0): it moves the row
out of this tracker into the owning workspace's **Intake**, ID-preserving, with an
`[ESCALATED …]` Notes prefix. It refuses a workspace ID that is not on the parent-pointer chain,
an ID already present in the target, and any Completed/Rejected/Active-Pilots source row.
Moves **to Completed** use the separate `-NewStatus Completed`/`Resolved` paths. **Active
Pilots** rows never enter through Intake — they are created directly via
`New-ProcessImprovement.ps1 -AsPilot` by the originating task.

## Reference index

- [references/classification-and-priority.md](references/classification-and-priority.md) —
  reconciliation/staleness checks, edge-case routing table, ambiguous pairs, priority inputs
  (provenance + ratings trends). Load when classifying rows.
- [references/clusters-and-consolidation.md](references/clusters-and-consolidation.md) —
  three-signal criterion, tension rule, thresholds, consolidation mechanism (constituents in
  Notes; the description cap), worked examples. Load when scanning for clusters.
- [references/helpers-reroutes-troubleshooting.md](references/helpers-reroutes-troubleshooting.md)
  — helper invocation patterns and auto-defaults, the two-step consolidation flow, re-route
  patterns, project-file evidence access from cwd=appdev, troubleshooting. Load when applying
  approved moves or when a helper invocation misbehaves.
