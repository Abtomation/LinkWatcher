---
id: PF-TSK-089
type: Process Framework
category: Task Definition
version: 2.9
created: 2026-05-10
updated: 2026-08-10
description: "Sort raw IMPs from the Intake section into Improvements / Extensions / Structural Changes / Active Pilots / Rejected."
use_when: >-
  Sort raw IMPs from the Intake section into Improvements / Extensions / Structural Changes / Active Pilots / Rejected. Detect duplicate-topic clusters across open sections and consolidate them into new Extension IMPs. Triggers: 'triage the IMP intake', 'drain the intake', 'sort the incoming IMPs'.
triggers:
  - "triage the IMP intake"
  - "drain the intake"
  - "sort the incoming IMPs"
automation: manual
---

# IMP Triage

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Sort raw IMPs from the **Intake** section of the central process-improvement tracking file into the correct destination section (`Improvements` / `Extensions` / `Structural Changes` / `Active Pilots` / `Rejected`). Detect duplicate-topic clusters across all open sections and consolidate them into new IMPs when the cluster justifies it — the consolidating IMP is classified per the same [Classification Rubric](#classification-rubric) used for individual IMPs (may route to Improvements, Extensions, or Structural Changes depending on the cluster's combined work scope).

**Position in workflow**: between [Tools Review (PF-TSK-010)](tools-review-task.md) (which now collects IMPs into Intake without routing) and the dispatch tasks ([PF-TSK-009 Process Improvement](process-improvement-task.md), [PF-TSK-014 Structure Change](structure-change-task.md), [PF-TSK-026 Framework Extension](framework-extension-task.md)). Tools Review fills the Intake; Triage drains it.

**Boundary**: Triage classifies and routes — it does **not** evaluate IMP merit or implement anything. Merit evaluation against structured criteria stays with the receiving task (e.g., PF-TSK-009's evaluation step). Triage's only judgment call is "which task should own this?" plus "is this a duplicate of something already open?"

**Re-routing**: The same triage helper (`Update-ProcessImprovement.ps1 -MoveToSection`) is also invoked by PF-TSK-009/014/026 when a downstream task picks up an IMP and concludes it belongs in a different section. The script auto-prepends a `[REROUTED YYYY-MM-DD by PF-TSK-NNN: <reason>]` audit-trail tag to the Notes column on re-routes.

## AI Agent Role

**Role**: Triage Coordinator
**Mindset**: Sorting-focused, pattern-spotting, transparency-first — when in doubt about classification, route on your recommendation and name the ambiguity individually in the digest rather than silently guessing.
**Focus Areas**: Section schema awareness, duplicate-topic detection across sections, audit-trail preservation, IMP-merit-deferred-to-receiving-task discipline.
**Communication Style**: Record the classification per IMP with one-line rationale and the cluster-detection findings in the session digest (batch table, not per-IMP prose). Flag ambiguous classifications explicitly and individually ("could be Improvement OR Extension — routed X because…").

## Key Concepts

### Section Schemas (canonical, 7-section model)

Per [Centralized Framework Management proposal §3.7](../../../process-framework-central/proposals/old/centralized-framework-management.md#37-tracking-file-layout):

| Section | Columns | Owner Task |
|---|---|---|
| **Intake** | `ID \| Source \| Description \| Project \| Framework Version \| Last Updated \| Notes` | Tools Review fills; Triage drains |
| **Improvements** | + `Priority \| Status \| Resp Task` | PF-TSK-009 |
| **Extensions** | + `Priority \| Status \| Resp Task` | PF-TSK-026 |
| **Structural Changes** | + `Priority \| Status \| Resp Task` | PF-TSK-014 |
| **Active Pilots** | `ID \| Concept \| Pilot Description \| Project \| Framework Version \| Status \| Notes` | PF-TSK-026 (extension-origin) or PF-TSK-009 (improvement-origin, PF-IMP-883) — both use PF-PRO-030 lifecycle |
| **Completed** | `ID \| Description \| Project \| Framework Version \| Resolution Date \| Implementing Task \| Resolved From \| Notes` | Receiving task on completion |
| **Rejected** | `ID \| Description \| Project \| Framework Version \| Rejection Date \| Rejection Reason \| Notes` | Triage (or receiving task on later re-evaluation) |

The triage helper handles column transformation between schemas when moving rows.

### Classification Rubric

The destination-section decision — which section an Intake row routes to — is owned by the [`imp-triage` craft skill](../../../.claude/skills/imp-triage/SKILL.md): its classification decision tree and ambiguity rule, plus [references/classification-and-priority.md](../../../.claude/skills/imp-triage/references/classification-and-priority.md) for edge-case routing and ambiguous pairs.

### Duplicate-Topic Cluster Detection

Cluster craft — scope of scan, the three-signal criterion (PF-IMP-850), the tension rule, cross-section edit-target overlap (PF-IMP-1239), thresholds, and consolidation destination — is owned by the skill's [clusters-and-consolidation reference](../../../.claude/skills/imp-triage/references/clusters-and-consolidation.md); the operative consolidation commands and audit-trail conventions live in Process Steps 6–11 below.

## Context Requirements

- **Critical (Must Read):**

  - `appdev/process-framework-central/state-tracking/permanent/process-improvement-tracking.md` — The tracking file. Read all open sections (Intake + Improvements + Extensions + Structural Changes + Active Pilots) at session start.
  - [`imp-triage` craft skill](../../../.claude/skills/imp-triage/SKILL.md) — the triage craft (classification decision tree, reconciliation/staleness checks, cluster and consolidation judgment, helper invocation patterns), activated in Preparation Step 1 (Check Recommended Skills). Replaces the retired usage guide and **drives the per-IMP judgment in Execution.**
  - `appdev/process-framework-central/project-registry.json` — `APP-NNN` → project path lookup (mnemonic-derived child IDs since P-14; historical rows may read `PRJ-NNN`) for validation-evidence access.

- **Important (Load If Space):**

  - [Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1) — Helper script (`-MoveToSection` operation); read `Get-Help <script> -Parameter *` to confirm the parameter contract before invocation.
  - [Process Improvement (PF-TSK-009)](process-improvement-task.md) — Receiving task for `Improvements` section; understand its evaluation step's rubric to set realistic Resp Task hints.
  - [Framework Extension (PF-TSK-026)](framework-extension-task.md) — Receiving task for `Extensions` and pilots in `Active Pilots`.
  - [Structure Change (PF-TSK-014)](structure-change-task.md) — Receiving task for `Structural Changes`.

- **Reference Only (Access When Needed):**

  - [feedback_db.py](../../scripts/feedback_db.py) — Per-tool ratings drill-down (`report --tool <tool_doc_id>`) for a contested Step 6 priority read.
  - [Tools Review (PF-TSK-010)](tools-review-task.md) — Upstream task that fills Intake. Useful for understanding what shape Intake rows arrive in.
  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) — PowerShell execution patterns; **always check parameters with `Get-Help <script> -Parameter *` before running**.

> **Historical context (post-migration archived; do not rely on as live references):**
>
> - Source proposal `appdev/process-framework-central/proposals/old/centralized-framework-management.md` (working draft v4) — the design doc that produced this task. Archived 2026-07-16 when the migration completed.
> - Extension state file `appdev/process-framework-central/state-tracking/temporary/old/temp-framework-extension-centralized-framework-management.md` — multi-phase implementation tracker. Archived 2026-07-16 when Phase 10 completed (all phases 0–10 done).

## Process

> **🚨 SCOPE GUARD: Triage classifies and routes. Triage does NOT evaluate IMP merit, propose solutions, or implement anything.** Merit evaluation is the receiving task's responsibility (e.g., PF-TSK-009's evaluation step). If you find yourself thinking "should we even do this?" beyond the Reject-vs-route decision, stop — that judgment belongs to the receiving task.

### Preparation

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `imp-triage-task`. If the `imp-triage` craft skill is available in the session, activate it — it owns the **triage craft** this task delegates to (classification decision tree, reconciliation/staleness checks, cluster and consolidation judgment, helper invocation patterns). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/imp-triage/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The triage craft is unavailable for this run only if the skill file itself is absent (the retired usage guide has no successor).

2. **Confirm cwd is `appdev/`** (or that the central file path resolves correctly from your current cwd via `.framework-central-pointer`). Triage operates against the central tracking file.

3. **Read the current Intake section**: open `appdev/process-framework-central/state-tracking/permanent/process-improvement-tracking.md` and list all rows currently in Intake. If Intake is empty, the session has nothing to triage — close it.

4. **Read all other open sections** (Improvements, Extensions, Structural Changes, Active Pilots) once at session start. You need this context for cluster detection in Step 7.

5. **For each Intake row, resolve its `Project` column**: if you need to inspect project files for classification (e.g., to confirm whether an IMP duplicates an open one), use the path from `project-registry.json[APP-NNN].path`.

### Execution

6. **Per-IMP classification**: For each Intake row, decide:
   - **Ownership check (→ escalate)** *(PF-PRO-068)*: first, whose artifact is this? Read the target artifact's ownership line. If another workspace owns it, **escalate** (Step 9) rather than classify — it holds the canonical copy, so it triages and fixes; a local claim edits a received copy the next sync overwrites. **Ambiguity escalates by default.** Craft: [`imp-triage` skill](../../../.claude/skills/imp-triage/references/classification-and-priority.md#ownership-check-rule-0).
   - **Reconciliation check (already-covered → Rejected)** *(PF-IMP-1004)*: before assigning a destination, quick-check whether the IMP is already resolved or covered, and **spot-check one load-bearing specific** it leans on against canonical `blueprint/process-framework` source *(PF-IMP-1162)*. If resolved or covered, route to **Rejected** (`Rejection Reason = "Already resolved/covered by <ref>"`) instead of giving it a slot — the already-resolved judgment Triage already owns (Classification Rubric, Rejected row), **not** merit evaluation; the point is to stop stale IMPs before they consume a downstream claim/verify cycle. The four coverage sources, the search-by-named-artifact rule, the evidence-vs-mechanism independence caveat *(PF-IMP-1579)*, and the conditional-rejection revival rule (`[REVIVES PF-IMP-NNNN]` — a Rejected hit whose recorded reason has since been falsified is not terminal): [`imp-triage` skill → classification-and-priority reference](../../../.claude/skills/imp-triage/references/classification-and-priority.md#reconciliation-check-before-decision-tree-rule-1).
   - **Destination section** per the [Classification Rubric](#classification-rubric).
   - **Resp Task hint** (PF-TSK-009 / PF-TSK-014 / PF-TSK-026 — the task ID matching the destination section). For a new-task IMP the section is **Extensions** and the Resp Task is its owner **PF-TSK-026** (which delegates to PF-TSK-001) — never set Resp Task to a section-less task ID.
   - **Initial Status**: default `Needs Prioritization` for triaged sections (the receiving task moves to `Needs Implementation` after its own Step 3 evaluation). For routes to Active Pilots, set `Active`. For routes to Rejected, no Status (rejected rows have a Rejection Reason instead).
   - **Initial Priority**: default `Low`/`Medium`/`High` per Triage's preliminary read; the receiving task can adjust during its evaluation. Triage is not the final priority arbiter. Two evidence inputs adjust the preliminary read: rows carrying the `[HUMAN-CORRECTION]` token in Notes (drained from a form's Human Intervention Log) start **one priority level higher** — human counter-flow corrections are the highest-trust improvement signal; and rows carrying `[RECURRENCE of PF-IMP-NNN]` likewise (a completed fix that failed to hold — spot-check the premise per the [classification-and-priority reference](../../../.claude/skills/imp-triage/references/classification-and-priority.md)). Where a row's priority is genuinely contested, the per-tool ratings drill-down (`feedback_db.py report --tool <tool_doc_id>`) is available — see the same reference.

7. **Cluster detection**: Cross-reference the Intake rows against open sections (loaded in Step 4). For each Intake row:
   - Apply the three-signal cluster criterion (same primary read-set + linked decisions + coherent scope; tension forces consolidation) — see [Duplicate-Topic Cluster Detection](#duplicate-topic-cluster-detection). Borderline matches (one or two signals only) still get surfaced at the checkpoint.
   - **2-IMP clusters**: flag at the Step 8 checkpoint. Default to consolidation when all three signals are present; otherwise leave separate.
   - **3+-IMP clusters**: recommend consolidation when the three signals are met; apply the [Classification Rubric](#classification-rubric) to the cluster's combined work scope to determine the destination section (Improvements / Extensions / Structural Changes). **Do not default to Extensions** — clusters of behavior-preserving fixes route to Improvements; rename/move clusters route to Structural Changes.
   - **Tension/contradiction across IMPs targeting the same artifact**: cluster regardless of count. The implementing session must resolve the conflict in one place rather than producing incoherent successive edits across separate sessions.

8. **📄 DIGEST-LISTED DECISIONS — classification pass (PF-PRO-059)**: Build the batch table of all classifications + cluster findings — this becomes the core of the session digest (Step 14). Format:

   | Intake ID | Destination | Resp Task | Priority | Cluster Findings | Rationale (one line) |
   |---|---|---|---|---|---|

   Plus a separate section for cluster consolidations (Step 7 3+-row clusters):
   - "Cluster: PF-IMP-A, PF-IMP-B, PF-IMP-C all touch X. Consolidating into a new IMP titled '<theme>', classified as **<Improvements|Extensions|Structural Changes>** because <one-line rationale per the Classification Rubric>."

   Name each genuinely ambiguous call **individually** (both options + why the pick) — ambiguities are what the owner reviews in the digest. Proceed to apply without waiting for approval; the owner's veto is a scripted post-hoc move-back (rows move, never delete).

### Application

9. **Apply the classified moves** via the triage helper — first re-read Intake and drop any row that left it since the Step 8 classification pass (claimed by a concurrent session; report drops in the Step 14 digest rather than attempting the move). For each remaining Intake row, the typical invocation is just:

   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-ProcessImprovement.ps1 \
       -ImprovementId "PF-IMP-NNN" \
       -MoveToSection "<Improvements|Extensions|StructuralChanges>" \
       -Priority "<High|Medium|Low>" \
       -TrackingFile "<central path>" \
       -Confirm:\$false
   ```

   The helper auto-defaults `-Status` to `Needs Prioritization`, `-RespTask` to the destination section's conventional owner (PF-TSK-009 / PF-TSK-026 / PF-TSK-014), and `-RoutedBy` to `PF-TSK-089` (since source is Intake). No need to repeat them on every invocation.

   For routes to Rejected, drop `-Priority` and add `-RejectionReason`:

   ```bash
   ... -MoveToSection "Rejected" -RejectionReason "<one-line rationale>" ...
   ```

   For rows the Step 6 ownership check escalated, use the escalation operation instead — the row leaves this tracker and lands in the owner's Intake, ID intact:

   ```bash
   ... -ImprovementId "PF-IMP-NNN" -EscalateTo "<owning workspace id>" -Reason "<why that workspace owns the artifact>" -Confirm:\$false
   ```

   > **Note**: When moving from Intake (Triage's normal case), the helper does **not** prepend `[REROUTED ...]` to Notes — that prefix is reserved for re-routes from already-triaged sections (where it auto-fires). The `-Reason` parameter is optional on Intake-source moves; supply it only when you want it logged.

10. **Apply cluster consolidations — create each consolidating IMP in Intake, superseding its source IMPs**: Each Step 8 cluster consolidation is a **two-step** flow — this step creates the consolidating IMP (which also supersedes the source IMPs in one call); Step 11 routes the new IMP to its classified section.

   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 \
       -Source "PF-TSK-089 cluster consolidation" \
       -Description "<theme summarizing the cluster's combined work scope (500-char cap)>" \
       -Supersedes "PF-IMP-810, PF-IMP-811, PF-IMP-812" \
       -TrackingFile "<central path>" \
       -Confirm:\$false
   ```

   The script:
   - Creates the new IMP row in the **Intake** section (consumes a fresh PF-IMP-NNN from `PF-id-registry-central.json`). Per Phase 7 (2026-05-11), `-Priority` / `-Status` / `-RespTask` were removed from the Single path — all new IMPs land in Intake.
   - For each ID in `-Supersedes`: invokes `Update-ProcessImprovement.ps1 -NewStatus Superseded -SupersededBy <new-ID>` as a subprocess, moving the source IMP to Section 7 — Rejected with `Status = "Superseded"` and `Rejection Reason = "Superseded by <new-IMP-ID>"`.
   - Source IMPs leave their open sections in the same operation that creates the consolidating IMP (PF-IMP-850 (a)) — closed by section membership, not by Notes-cell annotation.
   - Pilots and already-rejected source IMPs produce warnings and are skipped; the new consolidating IMP in Intake is still created.
   - Idempotent on re-run with the same `-Supersedes` values: subprocess calls against already-superseded rows fail at the subprocess's source-section gate, emit warnings, and continue (no state corruption).

   **Surface the constituents in the umbrella's Notes** *(PF-IMP-1028)*: `-Description` is capped at 500 chars, so it can only summarize the cluster theme — keep per-item detail out of it (overrunning the cap forces a retry). Record `Constituents: <ID> (<one-line scope>), …` in the new IMP's Notes (uncapped) — either via `-Notes` on the `New-ProcessImprovement.ps1` call above, or a follow-up `Update-ProcessImprovement.ps1 -AppendNotes` — so the implementing session reads per-item scope/priority directly instead of digging through the superseded rows in the archive.

11. **Classify and route the new consolidating IMP** to its destination section (decided at Step 8) via the standard move helper:

   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-ProcessImprovement.ps1 \
       -ImprovementId "<new PF-IMP-NNN from Step 10>" \
       -MoveToSection "<Improvements|Extensions|StructuralChanges>" \
       -Priority "<High|Medium|Low>" \
       -TrackingFile "<central path>" \
       -Confirm:\$false
   ```

   The destination is whatever the cluster's combined work scope warrants per the Classification Rubric — **not** always Extensions. A cluster of behavior-preserving edits routes to Improvements; a cluster of file moves routes to Structural Changes; a cluster implying a new shared helper or workflow routes to Extensions.

12. **Verify Intake is empty**: re-read the Intake section after all moves. A row still present is either a deliberate deferral *or* a late arrival filed concurrently after the Step 8 classification pass (Intake is shared across parallel project sessions) — classify or defer each one explicitly rather than assuming it is a carry-over. Record any remaining rows in the Step 14 digest.

### Finalization

13. **Integrity check**: `Validate-StateTracking.ps1` does **not** cover `process-improvement-tracking.md` (its surfaces target project state files, several of which are absent in appdev), so verify the central file directly *(PF-IMP-989)*:
    - **Intake drained** — Section 1 holds only deliberate deferrals (Step 12), if any.
    - **No PF-IMP ID appears in two open sections** (Intake / Improvements / Extensions / Structural Changes / Active Pilots).
    - **Escalated rows left cleanly** — each escalated ID is gone from every local section and present exactly once in the owner's Intake (IDs are portfolio-global: a row in both trackers is a duplicate, not a copy).
    - **No malformed table rows** after the moves — column counts intact in every touched section. Verify with the escaped-pipe-aware helper `Assert-TableRowInFile` ([TableOperations.psm1](../../scripts/Common-ScriptHelpers/TableOperations.psm1)) rather than a hand-rolled pipe-split counter — Notes cells quote PowerShell pipelines, so their `\|` escapes make a naive split-on-`|` cell count wrong. Loop the session's moved/created IMP IDs through it; it resolves each row's governing header and throws on a cell-count mismatch:

      ```powershell
      Import-Module process-framework/scripts/Common-ScriptHelpers.psm1
      foreach ($id in $movedIds) {
          Assert-TableRowInFile -Path $centralTracker -Pattern "\| $id \|" -Context "triage integrity check"
      }
      ```
    - **All consolidated source rows** are in Section 7 — Rejected with `Status = "Superseded"` and `Rejection Reason = "Superseded by <new-IMP-ID>"`.
    - **No orphaned subsumed rows** *(PF-IMP-1032)* — no open-section row is annotated as deferred/rolled-into/subsumed by an umbrella IMP that is now Completed or Rejected. If one is found, close it via `Update-ProcessImprovement.ps1` (Section 3/4/5 status transitions are supported per PF-IMP-864) referencing the umbrella, rather than leaving it parked. (Normal consolidation closes sources by section-move at creation time — Step 10 — so this only catches legacy or hand-annotated rows.)

14. **📄 Write the session digest (PF-PRO-059)**: Write a lightweight digest document to `appdev/process-framework-central/feedback/reviews/` (one per drain; filename `triage-digest-YYYYMMDD-HHMMSS.md`) containing: the outcome summary line (e.g., "12 Intake rows triaged: 6 → Improvements, 3 → Extensions, 1 → Structural Changes, 2 → Rejected; 1 cluster consolidated into PF-IMP-NNN") plus the resulting **open-row count per destination section** after the drain (reporting only, never a gate — a drain can empty Intake while merely relocating the backlog, and the owner sees that only if the digest says so), the Step 8 classification table **referencing tracker row IDs — never restating rows**, each ambiguity named individually, consolidations with rationale, concurrent drops/deferrals (Steps 9/12), and the list of core files this session touched (feeds the Standing Orders oscillation tripwire). The owner reviews digests at the Standing Orders cadence; silence = consent, veto = scripted move-back.

15. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#mandatory-task-completion-checklist) below.

## Outputs

- **Updated central tracking file** — `appdev/process-framework-central/state-tracking/permanent/process-improvement-tracking.md`. Intake rows moved to destination sections; consolidated source rows moved to Section 7 — Rejected with `Status = "Superseded"`.
- **(Conditional) New consolidating IMPs** — one per approved cluster consolidation. Each lands in Intake at creation time (Step 10, which also supersedes its source IMPs), then is routed to its classified destination section (Improvements / Extensions / Structural Changes — per the Classification Rubric applied to the cluster's combined work scope) within the same triage session (Step 11).
- **Updated** `PF-id-registry-central.json` — PF-IMP counter incremented for any new consolidating IMPs created from clusters.
- **Session digest** — one lightweight document per drain in `appdev/process-framework-central/feedback/reviews/` (`triage-digest-YYYYMMDD-HHMMSS.md`): classification table with row-ID references, ambiguities individually named, consolidation rationale, core files touched (PF-PRO-059).

## State Tracking

The following state file is updated by this task:

- `appdev/process-framework-central/state-tracking/permanent/process-improvement-tracking.md` — Intake drains; destination sections grow; consolidated rows annotated.

> **No temp state file required.** Triage is single-session by design. A typical session drains the current Intake batch in one sitting. If Intake is unusually large (20+ rows), run **global cluster detection across the whole Intake in one pass first** *(PF-IMP-1065)* — clusters frequently span source-batches, so splitting Intake by batch can fragment them (a 61-row Intake's strongest clusters spanned two batches). Only after the global cluster pass, if the session is still too large, close at a natural boundary and resume in a fresh session. Durable state lives in the tracking file itself.

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Triage skill checked**: `recommended_skills` consulted at Preparation Step 1; the `imp-triage` craft skill activated when available (or its absence noted)
- [ ] **Triage decisions digest-listed**: All Intake rows carried in the Step 8 classification table with destination + Resp Task + Priority + cluster findings + one-line rationale; ambiguous calls named individually
- [ ] **Cluster detection completed**: Open sections (Intake + Improvements + Extensions + Structural Changes + Active Pilots) scanned for duplicate-topic clusters; 3+-row clusters proposed for consolidation
- [ ] **Ownership checked per row**: each Intake row's target artifact resolved to an owning workspace; foreign-owned rows escalated via `-EscalateTo` rather than classified locally
- [ ] **Classified moves applied**: All classified Intake rows moved via `Update-ProcessImprovement.ps1 -MoveToSection`
- [ ] **Consolidations applied**: New consolidating IMPs created in Intake via `New-ProcessImprovement.ps1 -Supersedes` (Step 10, which also moves source IMPs to Section 7 — Rejected with `Status = "Superseded"`), then routed to their classified destination section via `Update-ProcessImprovement.ps1 -MoveToSection` (Step 11)
- [ ] **Intake drained or remainders recorded**: Re-read Intake section; any remaining rows have a deliberate deferral reason recorded in the Step 14 digest
- [ ] **Integrity check passes** (Step 13): Intake drained; no PF-IMP ID in two open sections; no malformed rows; all consolidated source rows in Section 7 — Rejected with `Status = "Superseded"`; no orphaned subsumed rows pointing at a closed umbrella
- [ ] **Session digest written** to `feedback/reviews/` (Step 14) — classification table with row-ID references, ambiguities individually named, core files touched
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-089`, context "IMP Triage".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| _TBD_ | _Update after task customization_ | _TBD_ | _TBD_ |

## Next Tasks

- **PF-TSK-009 Process Improvement** — pulls IMPs from the `Improvements` section that Triage filled.
- **PF-TSK-014 Structure Change** — pulls IMPs from the `Structural Changes` section that Triage filled.
- **PF-TSK-026 Framework Extension** — pulls IMPs from the `Extensions` section; pilots from `Active Pilots`.
- **(Re-route loop)** — If any of the above tasks evaluates an IMP and concludes scope mismatch, that task invokes the same triage helper inline (`-MoveToSection` with `-RoutedBy <its task ID>` and `-Reason <rationale>`) — no full Triage session needed for one re-route. The helper auto-prepends `[REROUTED YYYY-MM-DD by PF-TSK-NNN: …]` to Notes for the audit trail.

## Related Resources

- [`imp-triage` craft skill](../../../.claude/skills/imp-triage/SKILL.md) — the triage craft (replaces the retired usage guide); activated by the Check Recommended Skills step.
- [Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1) — Triage helper script (`-MoveToSection` operation).
- [Tools Review (PF-TSK-010)](tools-review-task.md) — Upstream collector that fills Intake.
- [Process Improvement (PF-TSK-009)](process-improvement-task.md) — Receives `Improvements` section; may file improvement-origin pilots into `Active Pilots` (PF-IMP-883).
- [Structure Change (PF-TSK-014)](structure-change-task.md) — Receives `Structural Changes` section.
- [Framework Extension (PF-TSK-026)](framework-extension-task.md) — Receives `Extensions`; files extension-origin pilots into `Active Pilots` (PF-PRO-030 lifecycle).
