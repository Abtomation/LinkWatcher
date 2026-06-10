---
id: PF-GDE-067
type: Process Framework
category: Guide
version: 1.3
created: 2026-05-10
updated: 2026-06-09
related_tasks: PF-TSK-089, PF-TSK-009, PF-TSK-014, PF-TSK-026
description: "Decision criteria, cluster-detection patterns, and consolidation worked examples for the PF-TSK-089 IMP Triage Task"
---

# IMP Triage Usage

## Overview

Practical decision criteria, cluster-detection patterns, consolidation worked examples, and helper-script invocation patterns for the [IMP Triage Task (PF-TSK-089)](../../tasks/support/imp-triage-task.md). This guide does **not** re-explain the task workflow itself — that lives in the task definition. It captures the operational judgment calls that recur every triage session.

> **🚨 Scope reminder**: Triage classifies and routes. Triage does **not** evaluate IMP merit, propose solutions, or implement anything. Merit evaluation is the receiving task's responsibility (e.g., PF-TSK-009 Step 3). If you're using this guide and find yourself thinking "should we even do this?" beyond Reject-vs-route, stop — that judgment belongs to the receiving task.

## When to Use

- You are running a triage session against a non-empty Intake section.
- A downstream task (PF-TSK-009/014/026) has picked up an IMP, evaluated it, and concluded scope mismatch — that task invokes the helper inline as a re-route.
- You are unsure how to classify an Intake row and want criteria + worked examples.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Classification Decision Tree](#classification-decision-tree)
4. [Cluster Detection — What Counts and What Doesn't](#cluster-detection--what-counts-and-what-doesnt)
5. [Consolidation Worked Examples](#consolidation-worked-examples)
6. [Re-Routing Patterns (post-triage)](#re-routing-patterns-post-triage)
7. [Helper Script Invocation Patterns](#helper-script-invocation-patterns)
8. [Validation Evidence Access (cwd=appdev → project files)](#validation-evidence-access-cwdappdev--project-files)
9. [Troubleshooting](#troubleshooting)
10. [Related Resources](#related-resources)

## Prerequisites

- The centralized `process-improvement-tracking.md` exists with the canonical 7-section structure (`Section 1 — Intake` through `Section 7 — Rejected`). Created in PF-PRO-029 Phase 2.
- `project-registry.json` exists with at least one registered project (so `Project` column resolves).
- `Update-ProcessImprovement.ps1` is the version that supports the `SectionMove` parameter set (PF-PRO-029 Phase 4).
- Until PF-PRO-029 Phase 7 cuts over the default, you must pass `-TrackingFile <central-path>` on every helper invocation. The helper refuses to run against the legacy 3-section project-local file.

## Background

The 7-section model separates **collection** (Tools Review fills Intake) from **classification** (Triage drains Intake into destination sections) from **execution** (PF-TSK-009/014/026 pull from their owned sections). Each section corresponds to exactly one downstream task; the mapping is the load-bearing contract:

| Section | Owning task | Column-schema width |
|---|---|---|
| Intake | none (raw) | 7 cols |
| Improvements | PF-TSK-009 | 10 cols (adds Priority/Status/Resp Task) |
| Extensions | PF-TSK-026 | 10 cols (same) |
| Structural Changes | PF-TSK-014 | 10 cols (same) |
| Active Pilots | PF-TSK-026 (extension-origin) or PF-TSK-009 (improvement-origin, PF-IMP-883) — PF-PRO-030 lifecycle | 7 cols (different schema — Concept + Pilot Description) |
| Completed | receiving task on resolution | 8 cols (Resolution Date / Implementing Task / Resolved From) |
| Rejected | Triage (or receiving task on later re-evaluation) | 7 cols (Rejection Date / Rejection Reason) |

The `Update-ProcessImprovement.ps1 -MoveToSection` operation handles the column-schema transformation between source and destination so the operator only thinks about the routing decision, not about table layout.

## Classification Decision Tree

Use this top-down. The first rule that fires wins.

```
1. Is the IMP describing a problem that is already resolved, can't be reproduced,
   or duplicates an open IMP that you've already classified?
   → Rejected (with one-line Rejection Reason)
   OR if it's a duplicate of an open IMP, treat as cluster member (see §4)

2. Does the proposed work require creating multiple new framework artifacts
   (new task definition + new template + new script + new guide), or a new
   workflow that doesn't exist today?
   → Extensions (PF-TSK-026)

3. Does the proposed work move/rename files, reorganize directories, or change
   the framework's shape such that projects' working docs need migration entries?
   → Structural Changes (PF-TSK-014)

4. Otherwise (bug-fix-shaped, content update to existing artifact, behavior-
   preserving script edit, stale doc-reference fix, missing cross-link, typo,
   regex tightening, parameter-validation tweak):
   → Improvements (PF-TSK-009)
```

**Reconciliation before Rule 1 (already-covered → Rejected, PF-IMP-1004):** Rule 1's "already resolved" is the single most common way stale IMPs slip through to a downstream session and burn a full claim/verify cycle before being rejected. Before routing, quick-check the IMP against four reconciliation sources for coverage that is **not** an open IMP:

- **Recently-completed IMPs** — Section 6 (Completed) in the archive file.
- **Pending-migration entries** — `per-project-migrations/<PRJ-ID>/pending-migrations.md` (the fix may already be queued/applied as a migration).
- **Shipped `blueprint/` changes** — a file already corrected in `blueprint/` touching the same artifact.
- **Validate-StateTracking surfaces** — a check that already covers the reported condition.

If any source already covers it, route to **Rejected** (`Already resolved/covered by <ref>`). This is still the already-resolved judgment Triage owns — not merit evaluation. (Tools Review applies the same reconciliation at intake; see its Step 12 deduplication bullet.)

**Edge cases:**

| If the IMP says… | Likely route | Why |
|---|---|---|
| "Add a new column to feature-tracking.md" | Structural Changes | Schema **reshape of an existing** project working doc → `pending-migrations.md` entries needed |
| "Add a *new* per-project config file that ships migration entries" | Extensions | A new project-level artifact also needs migration entries, but it's a capability addition, not a reorganization — the migration signal does **not** override that (PF-IMP-990) |
| "Fix the regex in `Validate-StateTracking.ps1` Surface 6" | Improvements | Behavior-preserving framework script edit (PF-TSK-009 medium-risk path) |
| "Create a new task for Y workflow" | Extensions | Brand-new task definition. Resp Task = section owner **PF-TSK-026**, which authors it via PF-TSK-001 as a sub-task — not the section-less PF-TSK-001 (PF-IMP-990) |
| "Improve the wording of PF-TSK-009 Step 3" | Improvements | Content edit to an existing task |
| "Move PF-TSK-XXX from `support/` to `cyclical/`" | Structural Changes | File move with cross-references to update |
| "Pilot the `feature-tracking.md` lightweight-index proposal" | (do NOT route here) | Pilots are created via `New-ProcessImprovement.ps1 -AsPilot` directly into Active Pilots; they don't enter through Intake |

**Ambiguity rule:** if you can articulate equally good reasons for two routes, present both at the Step 7 checkpoint with a recommendation. Don't silently pick one. Common ambiguous pairs:

- **Improvement vs Structural Change**: "moves a section heading and rewrites the surrounding text" — if the heading move is the load-bearing change, → Structural Change. If the text rewrite is the load-bearing change and the heading move is incidental, → Improvement.
- **Improvement vs Extension**: "adds a `-NewFlag` parameter to an existing script" — if the new behavior is a meaningful workflow on its own, → Extension (it's effectively a new capability). If it's a small variation on existing behavior, → Improvement.

## Cluster Detection — What Counts and What Doesn't

**Scope of scan**: Intake + Improvements + Extensions + Structural Changes + Active Pilots. **Never scan Completed or Rejected** — they're closed; their similarity to Intake rows is historical interest only.

### The three-signal cluster criterion (PF-IMP-850, 2026-05-12)

A cluster exists when 2+ open IMPs share **all three** of the following:

1. **Same primary read-set** — the implementing agent would read the same files / scripts / templates / guides to evaluate and implement each IMP.
2. **Linked decisions** — implementing IMP A meaningfully constrains how IMP B is implemented. One edit may delete sections another would patch; one new sub-rule may contradict another's removal; an architectural choice in one binds the next.
3. **Coherent scope** — the work forms one logical edit pass that a single implementing session can plan, execute, and validate without losing context.

This replaces the older "same artifact + overlapping intent" rule, which over-fragmented the recent 14-IMP PF-EVR-023 batch by biasing on source-similarity rather than implementing-session efficiency.

### Tension forces consolidation

When 2+ IMPs target the same artifact with **contradicting or tensioned intent** — e.g., one IMP wants to streamline a section another IMP wants to extend — they **must** cluster. The implementing session is the right place to resolve the conflict; splitting them across separate sessions produces incoherent successive edits. Tension is a *stronger* clustering signal than agreement: it forces the implementing agent to pick a stance before editing.

Under the old "same artifact + different intent → not a cluster" rule, tensioned IMPs explicitly *avoided* consolidation. The new rule reverses that — tension is exactly when consolidation pays off most.

### Counts as a cluster

- Three IMPs proposing different fixes against `Validate-StateTracking.ps1` Surface 6 — **cluster** (same read-set; the fixes interact since they edit the same surface's logic; coherent edit pass).
- Two IMPs proposing similar audit-trail prefixes for different scripts — **cluster** (same pattern, likely a missing helper extraction; the implementing session would design the helper once and apply it to both call sites).
- One IMP wanting to remove a CRITICAL callout from a task definition's Step 5 + one IMP wanting to add a new sub-rule that uses a CRITICAL prefix in the same Step 5 — **cluster** under the tension rule (same artifact, contradicting intent; the implementing session must pick a callout-style stance).

### Does NOT count as a cluster

- Two IMPs about `feature-tracking.md` where one edits schema and the other edits a far-away validation surface — **not a cluster** (same file mention, but no linked decisions and no coherent edit pass).
- One IMP about a script's regex and one IMP about a documentation typo in the same script's comments — **not a cluster** (same read-set, but the decisions are unlinked and the work isn't a coherent edit pass).

The key disqualifier under the new rule is the **linked-decisions** signal: same target file is not enough on its own.

### Threshold for action

- **2-IMP cluster** is a **flag** — mention at the Step 7 checkpoint with the three-signal analysis. Default to consolidation when all three signals are present; leave separate when one signal is weak.
- **3+-IMP cluster** is an **action** — recommend consolidation when the three signals are met. Apply the [Classification Decision Tree](#classification-decision-tree) to the cluster's combined work scope to determine the destination (Improvements / Extensions / Structural Changes — **do not default to Extensions**).
- **Tension/contradiction** on the same artifact: cluster regardless of count.

The destination section for the consolidating IMP is an **independent decision** from the consolidation itself — apply the Classification Decision Tree to the *combined* work scope, not to the cluster shape.

## Consolidation Worked Examples

> **Always surface the constituents in the umbrella's Notes** *(PF-IMP-1028)*: in every example below, after creating the umbrella record `Constituents: <ID> (<one-line scope>), …` in its Notes (via `-Notes` at creation or a follow-up `-AppendNotes`). The Description summarizes the theme; the Notes preserve per-item scope/priority/frequency so the implementing session doesn't have to reconstruct them from the superseded archive rows.

### Example 1: Three IMPs proposing a shared audit-trail helper → Extensions

**Cluster found:**
- PF-IMP-810: "Update-FeatureTracking.ps1 should log status transitions to a notes column."
- PF-IMP-811: "Update-TestTracking.ps1 should log status transitions similarly."
- PF-IMP-812: "Update-TechDebt.ps1 needs a similar audit-trail mechanism."

**Three-signal analysis:**
- **Same primary read-set** — yes; designing one audit-trail helper means reading all three scripts' status-transition logic plus the existing Common-ScriptHelpers/TableOperations.psm1.
- **Linked decisions** — yes; the helper's signature is bound by all three call sites' needs; designing one in isolation would either over- or under-fit the others.
- **Coherent scope** — yes; one helper + three caller refactors is a single planning-and-validation pass.

**Step 1 — Create the consolidating IMP in Intake (also supersedes the source IMPs):**

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 \
    -Source "PF-TSK-089 cluster consolidation" \
    -Description "Add Add-AuditTrailPrefix helper to Common-ScriptHelpers/TableOperations.psm1; refactor PF-IMP-810/811/812 sites to use it" \
    -Supersedes "PF-IMP-810, PF-IMP-811, PF-IMP-812" \
    -TrackingFile "<central path>" \
    -Confirm:$false
```

After this: a new IMP (e.g., PF-IMP-820) is created in **Intake**; each of PF-IMP-810/811/812 is moved to **Section 7 — Rejected** with `Status = "Superseded"` and `Rejection Reason = "Superseded by PF-IMP-820"`. The new consolidating IMP owns the work; the source IMPs are closed by section membership, not by Notes-cell annotation (PF-IMP-850 (a)).

> **Phase 7 note (2026-05-11)**: `-Priority` / `-Status` / `-RespTask` were removed from `New-ProcessImprovement.ps1`'s Single path. All new IMPs land in Intake; classification happens in Step 2.

**Step 2 — Classify and route via the Classification Decision Tree.** Applying the tree to the *combined* scope ("extract a new shared helper into Common-ScriptHelpers and refactor three caller scripts to consume it"):

- Rule 2 (multiple new artifacts or new workflow?) — a new shared helper added to Common-ScriptHelpers is a meaningful new capability that other scripts will adopt; the cross-artifact scope (one new function + three refactored callers) exceeds what PF-TSK-009's medium-risk path is sized for.
- Route to **Extensions**.

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-ProcessImprovement.ps1 \
    -ImprovementId "PF-IMP-820" \
    -MoveToSection "Extensions" \
    -Priority "Medium" \
    -TrackingFile "<central path>" \
    -Confirm:$false
```

> **Counter-example**: if the same cluster had been three IMPs proposing identical regex fixes to **one** script (no shared helper extraction, no new capability), the consolidating IMP would route to **Improvements** — same cluster shape, different classification because the *combined work* is a single behavior-preserving edit set. The cluster shape doesn't dictate the destination; the combined work does.

### Example 2: Two IMPs about distinct `Validate-StateTracking.ps1` surfaces → not a cluster

**Candidate cluster:**
- PF-IMP-830: "Surface 6 false-positive when feature-tracking has dependency rows for retired features."
- PF-IMP-831: "Surface 14 doesn't catch test-status-aggregation drift after row deletions."

**Three-signal analysis:**
- **Same primary read-set** — partially. Both fixes read `Validate-StateTracking.ps1`, but each surface is its own function block; the implementing agent only needs to read the relevant surface's logic plus a state-file fixture. The shared-file overlap is shallow.
- **Linked decisions** — no. Surface 6 logic and Surface 14 logic don't interact; a fix to one doesn't constrain the shape of the other.
- **Coherent scope** — weak. Two independent surface fixes can be done in either order; the implementing session gains little from doing them together.

**Decision**: not a cluster. Two of three signals fail. Route both to Improvements separately. (If during PF-TSK-009 implementation the two fixes turn out to share helper code, PF-TSK-009 can re-route one to consolidate via the inline re-route helper — but at triage time, the call is "two separate Improvements".)

> **Why this is different from Example 1**: Example 1's three IMPs share design decisions about an extracted helper's contract — linked decisions. Example 2's two IMPs share only a target file. Same-file overlap is the *easiest* signal to spot but the weakest on its own; the new three-signal rule (PF-IMP-850) demands all three before clustering.

### Example 3: Three Intake rows on script behavior in one file → Improvements

**Cluster found:**
- PF-IMP-840: "LinkWatcher startup fails silently when .venv is missing — should emit a clear error."
- PF-IMP-841: "LinkWatcher startup logs warnings to stderr when stdout would be more visible."
- PF-IMP-842: "LinkWatcher startup exits 0 even on config errors — should exit 1."

**Three-signal analysis:**
- **Same primary read-set** — yes; all three fixes touch `start_linkwatcher_background.ps1`'s startup path.
- **Linked decisions** — yes; the exit-code (842) and the error-emission style (840, 841) interact (a clear error message ought to align with the new exit code; logging-stream choice ought to be consistent across all three error paths).
- **Coherent scope** — yes; one edit pass on the startup function's error handling.

**Step 1 — Create the consolidating IMP in Intake (also supersedes the source IMPs):**

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 \
    -Source "PF-TSK-089 cluster consolidation" \
    -Description "Tighten error handling and exit-code semantics in start_linkwatcher_background.ps1 — clear error on missing .venv, stdout for user-facing warnings, exit 1 on config errors" \
    -Supersedes "PF-IMP-840, PF-IMP-841, PF-IMP-842" \
    -TrackingFile "<central path>" \
    -Confirm:$false
```

The new consolidating IMP (e.g., PF-IMP-850) lands in Intake; PF-IMP-840/841/842 are moved to Section 7 — Rejected with `Status = "Superseded"` and `Rejection Reason = "Superseded by PF-IMP-850"`.

**Step 2 — Classify and route.** Applying the Classification Decision Tree to the combined scope ("three behavior-preserving fixes against one existing script"):

- Rule 2 (new artifacts or new workflow?) — no.
- Rule 3 (file moves / directory reorg?) — no.
- Rule 4 (behavior-preserving edits to existing artifact) — **yes**.
- Route to **Improvements**. PF-TSK-009's Step 10 medium-risk path is exactly sized for this kind of multi-defect edit pass against one script.

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-ProcessImprovement.ps1 \
    -ImprovementId "PF-IMP-850" \
    -MoveToSection "Improvements" \
    -Priority "Medium" \
    -TrackingFile "<central path>" \
    -Confirm:$false
```

> **Practical lesson**: cluster size (3 IMPs) does not determine the destination. The *combined work scope* does. A cluster of three small fixes against one file is still an Improvement, not an Extension. The original version of this guide defaulted such clusters to Extensions; that was the bug fixed on 2026-05-12.

### Example 4: Three Intake rows on framework reorganization → Structural Changes

**Cluster found:**
- PF-IMP-860: "Rename `process-framework-local/` to `doc/state-tracking/` for terminology consistency."
- PF-IMP-861: "Move `process-improvement-tracking.md` from project-local to central."
- PF-IMP-862: "Normalize the central `feedback/` directory to the underscore-separated naming convention."

**Three-signal analysis:**
- **Same primary read-set** — yes; all three move/rename IMPs interact with the same per-project `pending-migrations.md` ledgers and the same set of cross-reference grep targets across projects.
- **Linked decisions** — yes; rename ordering, pending-migration entry shape, and rollout cadence are all interdependent.
- **Coherent scope** — yes; one Structure Change campaign with one rollout window.

**Step 1 — Create the consolidating IMP in Intake (also supersedes the source IMPs):**

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 \
    -Source "PF-TSK-089 cluster consolidation" \
    -Description "Framework path/rename cleanup pass — eliminate process-framework-local, centralize improvement tracking, normalize feedback dir convention; coordinate pending-migrations entries across affected projects" \
    -Supersedes "PF-IMP-860, PF-IMP-861, PF-IMP-862" \
    -TrackingFile "<central path>" \
    -Confirm:$false
```

The new consolidating IMP (e.g., PF-IMP-870) lands in Intake; the three source rows are moved to Section 7 — Rejected with `Status = "Superseded"` and `Rejection Reason = "Superseded by PF-IMP-870"`.

**Step 2 — Classify and route.** Applying the Classification Decision Tree:

- Rule 3 (moves/renames that ripple to projects' working docs, requiring migration entries) — **yes**.
- Route to **Structural Changes**.

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-ProcessImprovement.ps1 \
    -ImprovementId "PF-IMP-870" \
    -MoveToSection "StructuralChanges" \
    -Priority "High" \
    -TrackingFile "<central path>" \
    -Confirm:$false
```

> **Why three worked examples ending in three different sections**: clusters routing to Extensions (Example 1), Improvements (Example 3), and Structural Changes (Example 4) are all common in practice. The cluster pattern is independent of the destination section; classify each consolidating IMP on its own merits via the Decision Tree applied to the combined work scope.

### Example 5: Tensioned IMPs against the same artifact → forced cluster

**Cluster found:**
- PF-IMP-A: "Demote CRITICAL callouts in PF-TSK-009 Step 5 to bullet-style guidance (Tools Review evaluation report — streamlining intent)."
- PF-IMP-B: "Add a new CRITICAL sub-rule to PF-TSK-009 Step 5 covering scope-creep detection (Tools Review feedback form — additive intent)."

**Three-signal analysis:**
- **Same primary read-set** — yes; both IMPs edit PF-TSK-009 Step 5 and the surrounding callout style.
- **Linked decisions** — yes; the implementing session must pick a callout-style stance (demote-all vs add-new) before either IMP can be implemented. Implementing them in separate sessions produces incoherent successive edits — Session 1 demotes the callouts, Session 2 then adds a new CRITICAL callout that violates the style Session 1 just chose.
- **Coherent scope** — yes; one edit pass on Step 5's callout block.

**Tension forces consolidation** (PF-IMP-850 (c)). Under the old "same artifact + different intent → not a cluster" rule, these two IMPs would have been left separate. The new rule clusters them precisely because their intents conflict: the implementing session is the only place where the conflict can be resolved coherently.

**Step 1 — Create the consolidating IMP in Intake (also supersedes the source IMPs):**

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 \
    -Source "PF-TSK-089 cluster consolidation (tension)" \
    -Description "Reconcile callout-style tension in PF-TSK-009 Step 5: implementing session must pick demote-vs-extend stance before editing. Sources: PF-IMP-A (streamlining) + PF-IMP-B (additive sub-rule on scope-creep)." \
    -Supersedes "PF-IMP-A, PF-IMP-B" \
    -TrackingFile "<central path>" \
    -Confirm:$false
```

The Description explicitly names the conflict the implementing session must resolve. The two source IMPs move to Section 7 — Rejected with `Status = "Superseded"`; the implementing session sees the conflict as one unified IMP rather than as two independent ones to interleave.

**Step 2 — Classify and route via the Classification Decision Tree.** The combined scope is "content edits to PF-TSK-009 Step 5" — Rule 4 (behavior-preserving content edit to existing artifact) → **Improvements** (PF-TSK-009).

## Re-Routing Patterns (post-triage)

Re-routes happen when a downstream task picks up an IMP and concludes scope mismatch. Three legitimate patterns:

### Pattern A: Improvements → Structural Changes

**Trigger**: PF-TSK-009 picks up an Improvement, examines the work, realizes it requires file moves or directory reorganization.

**Action**: PF-TSK-009 invokes the helper inline — does **not** spin up a Triage session.

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-ProcessImprovement.ps1 \
    -ImprovementId "PF-IMP-NNN" \
    -MoveToSection "StructuralChanges" \
    -Priority "<preserved or adjusted>" \
    -Reason "Requires directory reorganization — out of PF-TSK-009 scope" \
    -TrackingFile "<central path>" \
    -Confirm:$false
```

The helper auto-defaults `-RoutedBy = PF-TSK-009` (from the Improvements source section's conventional routing-task) and auto-prepends `[REROUTED 2026-05-10 by PF-TSK-009: Requires directory reorganization — out of PF-TSK-009 scope]` to the Notes column. The original IMP's audit history is preserved.

### Pattern B: Improvements → Extensions

**Trigger**: PF-TSK-009 picks up an Improvement, evaluates per its Step 3 rubric, and concludes the proper fix requires creating multiple new artifacts.

**Same shape as Pattern A**, with `-MoveToSection Extensions` and `-RespTask` updates to PF-TSK-026.

### Pattern C: Any open section → Rejected

**Trigger**: receiving task evaluates the IMP per its merit criteria and concludes "we shouldn't do this" (root cause out of scope, fix would degrade rather than improve, IMP premise was wrong on closer inspection).

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-ProcessImprovement.ps1 \
    -ImprovementId "PF-IMP-NNN" \
    -MoveToSection "Rejected" \
    -RejectionReason "Per Step 3 evaluation, root-cause-vs-symptom gate triggered — fix would mask the underlying defect" \
    -Reason "Step 3 rejection" \
    -TrackingFile "<central path>" \
    -Confirm:$false
```

`-RoutedBy` auto-defaults from the source section (PF-TSK-009 if rejecting from Improvements, etc.). Notes column gets the `[REROUTED ...]` prefix; Rejection Reason column gets the merit-based rationale.

### Anti-pattern: Triage doing merit evaluation

**Don't** reject an IMP at Triage because "I don't think we should do this." Triage's only rejection criteria are:
- Already resolved (cannot reproduce).
- Duplicates an open IMP that's already classified (consolidate via cluster instead).
- Out of scope (e.g., not a process improvement at all — likely a misfile from Tools Review).

Merit-based rejection ("we evaluated this and it's not worth doing") is the receiving task's call, not Triage's.

## Helper Script Invocation Patterns

### Initial sort from Intake (no `[REROUTED ...]` prefix)

The typical invocation is short — the helper supplies smart defaults:

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-ProcessImprovement.ps1 \
    -ImprovementId "PF-IMP-800" \
    -MoveToSection "Improvements" \
    -Priority "Medium" \
    -TrackingFile "<central path>" \
    -Confirm:$false
```

The helper:
- Auto-defaults `-Status` to `"Needs Prioritization"` on triaged-section moves.
- Auto-defaults `-RespTask` to the conventional owner of the destination section (PF-TSK-009 for Improvements, PF-TSK-026 for Extensions, PF-TSK-014 for Structural Changes).
- Auto-defaults `-RoutedBy` to `PF-TSK-089` (the conventional routing-task for Intake-source moves).
- Does **not** prepend `[REROUTED ...]` to Notes when source is Intake. `-Reason` is optional on Intake-source moves (logged when supplied; not written to Notes).

### Re-route from a triaged section (auto-prepends `[REROUTED ...]`)

Same shape — the helper auto-defaults `-RoutedBy` based on the source section, so you typically only supply `-Reason`:

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-ProcessImprovement.ps1 \
    -ImprovementId "PF-IMP-802" \
    -MoveToSection "StructuralChanges" \
    -Priority "High" \
    -Reason "Scope mismatch — requires structural reorganization" \
    -TrackingFile "<central path>" \
    -Confirm:$false
```

When invoked from a PF-TSK-009 session against an Improvements-section row, the helper auto-defaults `-RoutedBy = PF-TSK-009` (from the source section's conventional routing-task) and auto-prepends `[REROUTED YYYY-MM-DD by PF-TSK-009: Scope mismatch — requires structural reorganization]` to the existing Notes column.

**Override case**: if Triage re-evaluates a triaged-section row in a follow-up session (rare), pass `-RoutedBy "PF-TSK-089"` explicitly to override the source-section default. The audit-trail prefix will then read `by PF-TSK-089`.

**Missing `-Reason` on a re-route**: the helper warns and still records the prefix as `[REROUTED YYYY-MM-DD by PF-TSK-NNN: <no reason supplied>]` — audit-trail integrity is preserved even when the operator forgot the rationale.

### Bulk triage in a single session

The helper is single-IMP. For a bulk triage, invoke it per IMP:

```bash
foreach ($imp in @(
    @{ Id = "PF-IMP-800"; Section = "Improvements"; Pri = "Medium" },
    @{ Id = "PF-IMP-801"; Section = "Extensions";   Pri = "High" },
    @{ Id = "PF-IMP-802"; Section = "Rejected";     RejReason = "Duplicate of PF-IMP-650" }
)) {
    if ($imp.Section -eq "Rejected") {
        & .\Update-ProcessImprovement.ps1 -ImprovementId $imp.Id -MoveToSection $imp.Section `
            -RejectionReason $imp.RejReason `
            -TrackingFile $central -Confirm:$false
    } else {
        & .\Update-ProcessImprovement.ps1 -ImprovementId $imp.Id -MoveToSection $imp.Section `
            -Priority $imp.Pri `
            -TrackingFile $central -Confirm:$false
    }
}
```

(`-RoutedBy` and `-Reason` are dropped from the loop body — the helper auto-defaults `-RoutedBy = PF-TSK-089` from the Intake source section, and `-Reason` is optional on initial sorts.)

Each invocation is independent. Failures abort one row but don't roll back prior moves — verify Intake is empty after the loop.

### -WhatIf preview

```bash
... -MoveToSection "Improvements" ... -WhatIf
```

Outputs the operation prompt without writing the file. Useful when the cluster-detection scan is uncertain about source-section identification.

### Targeting the central file (until Phase 7)

The default `-TrackingFile` is the project-local 3-section file. Until PF-PRO-029 Phase 7 cuts over the default, **always** pass `-TrackingFile <central-path>` to SectionMove invocations. The helper refuses (with a clear error) when the file lacks the canonical `## Section 1 — Intake` heading.

## Validation Evidence Access (cwd=appdev → project files)

Triage runs in cwd=appdev but may need to read project files (source code, tracking, test artifacts) to confirm a duplicate or sanity-check classification. The mechanism is the **registry path lookup**:

```powershell
# Resolve once at session start
$registry = Get-Content "appdev/process-framework-central/project-registry.json" | ConvertFrom-Json

function Get-ProjectPath {
    param([string]$ProjectColumnValue)  # e.g., "PRJ-002 (ExampleProject)"
    if ($ProjectColumnValue -match '^(PRJ-\d+)') {
        $prjId = $matches[1]
        return $registry.projects.$prjId.path
    }
    return $null
}

# Per IMP, when reading evidence:
$projectPath = Get-ProjectPath $row.Project
$evidence = Get-Content (Join-Path $projectPath "doc/state-tracking/permanent/feature-tracking.md")
```

No cwd switching. The path is absolute; works from any cwd.

When `Project` column shows `PRJ-000 (appdev)` — the IMP originated from appdev itself (e.g., from a framework-management session in cwd=appdev). Resolution is the same; `PRJ-000.path` points back to appdev.

## Troubleshooting

### "Tracking file does not have the central 7-section structure"

**Symptom**: helper exits with this error.

**Cause**: `-TrackingFile` was not passed (defaulted to project-local 3-section file) OR the central file is malformed (someone deleted the `## Section 1 — Intake` heading).

**Solution**: Verify `-TrackingFile <central-path>` is set on the invocation. If yes, inspect the central file's section headings — they must match the canonical 7-section layout exactly.

### "PF-IMP-NNN not found in any section"

**Symptom**: helper exits saying the IMP isn't in any of the 7 sections.

**Cause**: typo in `-ImprovementId`, OR the IMP was already moved by a parallel session, OR the IMP exists in the legacy project-local file but not in the central file.

**Solution**: grep the central file for the ID. If absent, check the project-local file. If found there, the IMP needs hand-migration to central (Phase 8 workflow) before triage.

### Re-route prefix shows `<no reason supplied>`

**Symptom**: source != Intake; Notes column has `[REROUTED YYYY-MM-DD by PF-TSK-NNN: <no reason supplied>]` instead of a meaningful rationale.

**Cause**: caller forgot `-Reason` on the re-route. The helper logs a warning but still records the prefix with the missing-reason marker (audit-trail integrity beats narrative).

**Solution**: this is a soft failure — the move succeeded and the audit trail records who and when, just not why. If the rationale matters, hand-edit the row's Notes column to replace `<no reason supplied>` with the actual reason. To prevent recurrence: surface the warning at the operator's session checkpoint.

### Re-route prefix is missing entirely (no `[REROUTED ...]` at all)

**Symptom**: source != Intake, but Notes column still has just the original text — no prefix at all.

**Cause**: caller passed `-RoutedBy ""` (empty string) AND the source section is not one of the four with a conventional routing-task default (Intake / Improvements / Extensions / StructuralChanges). The helper warns and skips the prefix to avoid recording a malformed audit-trail tag.

**Solution**: re-invoke with `-RoutedBy "<task ID>"` explicit. The auto-default covers normal cases — this only fires when the source section is unrecognized.

### Cluster detection missed an obvious duplicate

**Symptom**: triage routes PF-IMP-A to Improvements, then realizes PF-IMP-B (already in Improvements) is the same topic.

**Cause**: cluster scan in Step 6 didn't flag the match, usually because the rows describe the same problem in very different language.

**Solution**: in the same triage session, run the consolidation command — `New-ProcessImprovement.ps1 -Supersedes "PF-IMP-A, PF-IMP-B"` — to create a new consolidating IMP (lands in Intake) that subsumes both. The same call moves both source rows to Section 7 — Rejected with `Status = "Superseded"` and `Rejection Reason = "Superseded by <new-IMP-ID>"`. Then classify the new IMP per the Classification Decision Tree and route it via `Update-ProcessImprovement.ps1 -MoveToSection` to Improvements, Extensions, or Structural Changes as the combined work scope warrants. Mention to the human partner; this is also useful Tools Review feedback (the IMP descriptions could be more pattern-recognizable).

### Helper says "already in section X — no change"

**Symptom**: WARN-level message; exit 0; nothing changes.

**Cause**: source and destination are the same (e.g., re-running a previously-applied move).

**Solution**: not an error — confirms the desired state was already achieved. Continue.

### `Project` column is blank or malformed

**Symptom**: validation evidence access fails because `Get-ProjectPath` returns null.

**Cause**: the IMP was created before the `Project` column was populated, OR the column has freeform text instead of `PRJ-NNN (name)` format.

**Solution**: hand-edit the row to set `Project` to the correct `PRJ-NNN (current-name)` format. If the originating project genuinely cannot be determined, set to `PRJ-000 (appdev)` — at least the row is parseable.

## Related Resources

- [IMP Triage Task (PF-TSK-089)](../../tasks/support/imp-triage-task.md) — Workflow execution; this guide complements but does not duplicate the task definition.
- [IMP Triage Context Map](../../visualization/context-maps/support/imp-triage-map.md) — Component relationships.
- [Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1) — Helper script implementing both `StatusUpdate` and `SectionMove` parameter sets.
- [Tools Review Task (PF-TSK-010)](../../tasks/support/tools-review-task.md) — Upstream collector that fills Intake.
- [Process Improvement (PF-TSK-009)](../../tasks/support/process-improvement-task.md) — Receives Improvements section; performs merit evaluation per its Step 3 rubric.
- [Framework Extension (PF-TSK-026)](../../tasks/support/framework-extension-task.md) — Receives Extensions section; pilots Active Pilots.
- [Structure Change (PF-TSK-014)](../../tasks/support/structure-change-task.md) — Receives Structural Changes section.
- [Centralized Framework Management proposal §3.6 / §3.7](../../../process-framework-central/proposals/centralized-framework-management.md) — Source design doc for the 7-section model and triage workflow.
- [Script Development Quick Reference](script-development-quick-reference.md) — PowerShell execution patterns.
