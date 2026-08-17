---
id: PF-TSK-010
type: Process Framework
category: Task Definition
domain: agnostic
version: 2.14
created: 2023-06-15
updated: 2026-08-10
description: "Review and improve project tools and templates"
use_when: >-
  Periodic review of feedback forms accumulated since last review — extract findings, file raw IMPs into central Intake. Triggers: 'do tools review', 'review feedback forms', 'process the feedback backlog'.
triggers:
  - "do tools review"
  - "review feedback forms"
  - "process the feedback backlog"
automation: partial
scripts:
  - ../../scripts/file-creation/06-maintenance/New-ReviewSummary.ps1
  - ../../scripts/file-creation/support/New-ProcessImprovement.ps1
  - ../../scripts/update/Update-ImprovementBacklog.ps1
trigger_status:
  - raw: "_(schedule / task count)_ + unprocessed feedback forms in `appdev/process-framework-central/feedback/feedback-forms/`"
output_status:
  - raw: "`process-improvement-tracking.md` → new IMP items; `bug-tracking.md` → `🆕 Needs Triage` (if bugs); `feature-request-tracking.md` → `📥 Submitted` (if features)"
next_tasks:
  - task: imp-triage-task.md
    condition: "primary downstream task. Drains Intake into the appropriate destination sections (Improvements / Extensions / Structural Changes / Active Pilots / Rejected). Run this next so the freshly-intaken framework IMPs get properly classified before they sit too long."
  - task: process-improvement-task.md
    condition: "for implementing IMPs that Triage routes to the Improvements section (downstream of Triage, not directly from Tools Review)."
---

# Tools Review Task

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Systematically evaluate and enhance the templates, guides, and other tools by collecting, analyzing, and implementing feedback, ensuring continuous improvement of documentation and processes.

## AI Agent Role

**Role**: DevOps Engineer
**Mindset**: Tool optimization-focused, efficiency-driven, continuous improvement-oriented
**Focus Areas**: Tool effectiveness, automation opportunities, user experience, process optimization
**Communication Style**: Focus on tool usability and efficiency gains, ask about pain points and improvement priorities

## Context Requirements

- **Critical (Must Read):**

  - **Central feedback forms** at `appdev/process-framework-central/feedback/feedback-forms/` — incoming forms from all registered projects, named `YYYYMMDD-HHMMSS_<PROJECT-ID>_PF-TSK-XXX_feedback.md` (Phase 7 cutover, 2026-05-11). All sessions read from this location regardless of cwd.
  - **Central process-improvement-tracking.md** at `appdev/process-framework-central/state-tracking/permanent/process-improvement-tracking.md` — Tools Review writes new IMPs to its **Section 1 — Intake** subsection only; downstream routing is owned by IMP Triage (PF-TSK-089).

- **Important (Load If Space):**

  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) - PowerShell execution patterns and parameter checking (**always check script parameters with `Get-Help <script> -Parameter *` before running**)
  - [Task Templates](../../templates) - Templates used in tasks

- **Reference Only (Access When Needed):**
  - [Documentation Map](../../PF-documentation-map.md) - Overview of all project documentation
  - [IMP Triage Task (PF-TSK-089)](imp-triage-task.md) - The downstream task that drains the Intake section

## Process

> **⚠️ MANDATORY: Always group feedback forms by task type for consistent analysis.**
>
> **📄 DIGEST MODE (PF-PRO-059)**: This task runs without blocking approval checkpoints. Decision points (batch selection, filing plan) are recorded in the session digest — the review summary's decisions sections (see the fill-review-summary step) — for post-hoc owner review at the Standing Orders cadence. Owner silence = consent; a veto is a scripted move-back (`Update-ProcessImprovement.ps1 -MoveToSection`), never a deletion. One-way doors (anything on the workspace Standing Orders always-escalate list) still block.

### Preparation

1. Review feedback forms collected at the end of each task. Source location: `appdev/process-framework-central/feedback/feedback-forms/` (Phase 7 cutover, 2026-05-11). Form filenames follow `YYYYMMDD-HHMMSS_<PROJECT-ID>_PF-TSK-XXX_feedback.md` — the `<PROJECT-ID>` segment identifies which project produced the form (a legacy-named form: see the [edge-cases guide](../../guides/support/tools-review-edge-cases-guide.md)).
2. **Group feedback forms by task type** (e.g., all PF-TSK-009 forms together)
   - **📊 BATCH SIZING (density-driven)**: Size the session's batch from the actual inventory rather than a fixed quota — select whole task groups whose combined form count fits one session's analysis budget. **~40 feedback forms is the backstop ceiling, not a target**: a session of small task groups may comfortably exceed it, while a session of dense, high-finding-yield forms may warrant fewer. The batch is chosen at Step 5 and digest-listed.
   - **Analysis quality over speed**: Analyze each form individually and thoroughly before moving to the next. Do not parallelize form analysis — sequential, careful reading catches improvement patterns that batch scanning misses.
   - **Task-group integrity (default, splittable)**: Prefer analyzing all forms of the same task type in the same session; when the inventory spans multiple groups, split sessions on task-group boundaries. A single task group **may** be split across sessions (owner decision 2026-07-29, PF-IMP-1882 — the materiality-bar/backlog procedure in the classify-and-register step adds per-form overhead): split on a chronological boundary (oldest forms first), and the later session must dedupe its candidates against the earlier session's **freshly filed** Intake rows and Improvement Backlog entries, not only pre-existing ones. When a theme straddles the split boundary, name the counterpart batch in each affected IMP row's Notes, so Triage consolidates the halves rather than filing them as independent changes (the split-specific instance of the IMP-Notes cross-reference channel). Group integrity binds the batch selected at Step 5, not every form of that task type in existence: a same-type form that arrives *after* that selection belongs to the next cycle and stays active. **Unfilled is mechanical**: run [`Validate-FeedbackForms.ps1`](../../scripts/validation/Validate-FeedbackForms.ps1) (report mode — never `-FixIncomplete` here) over the active folder at inventory; a form it flags incomplete likewise stays active and out of the batch — group integrity binds only validator-passing forms, and a flagged form gets a second chance at the archive step's pre-archive re-run (Step 14).
3. Create a structured analysis framework for each task group
4. Prepare a tracking sheet for identified improvements
5. **📄 DIGEST-LISTED DECISION — batch selection**: Record the feedback inventory, task groupings, the **selected batch for this session** (which whole task groups, total form count, and why that fits one session per the density-driven sizing in Step 2 — and, when one task group alone exceeds roughly half the inventory, say so: that shape determines which split options are even available), and initial themes — this becomes the digest's batch-selection entry (Step 17). Proceed without waiting for approval.

### Execution

> **🎯 UNIT OF ANALYSIS**: The output unit is the **individual improvement opportunity**, not the feedback form or task group. Task-group analysis (Steps 6–9) organizes the reading — but when registering IMPs (Step 12), each distinct actionable change must be its own entry. If a single form contains 3 independent suggestions, that's 3 IMPs. If a theme spans multiple forms but describes one change, that's 1 IMP.

6. Identify common themes and patterns across feedback **within each task group**
7. Evaluate each task type separately to ensure consistent analysis
8. Quantify ratings across all five dimensions: effectiveness, clarity, completeness, efficiency, and conciseness
9. Prioritize potential improvements based on frequency and impact — alongside the form-derived frequency signal, consult the change-log hotspot view (`python process-framework/scripts/feedback_db.py trend-changes`) for artifacts with repeated recent fixes; a distinct-IMP count well below the change count marks recurrence candidates
10. **📄 DIGEST-LISTED DECISION — filing plan**: Itemize the analysis findings, identified themes, and prioritized improvement opportunities as a single numbered list (the filing plan Step 12 executes; the item count is self-verifying). Name each genuine ambiguity **individually** — ambiguous calls are what the owner reviews in the digest. Record it all for the digest (Step 17) and proceed to filing.
11. **Create review summary skeleton**: Run [`New-ReviewSummary.ps1`](../../scripts/file-creation/06-maintenance/New-ReviewSummary.ps1) now so the filename (which includes an unpredictable HHMMSS timestamp) is known before registering IMPs. Note the created filename for use in `-SourceLink` parameters below. Pass `-FormsList` with the filenames of the forms you analyzed this session (the same list you build at Step 14.2) to auto-populate the Archived Forms table's Form and Task columns — you then only fill each row's Context during finalization.
    ```powershell
    # -FormsList is an array, so this needs -Command (arrays do not survive -File)
    pwsh.exe -ExecutionPolicy Bypass -Command "& process-framework/scripts/file-creation/06-maintenance/New-ReviewSummary.ps1 -FormsAnalyzed <N> -DateRangeStart 'YYYY-MM-DD' -DateRangeEnd 'YYYY-MM-DD' -FormsList '<form1>.md','<form2>.md',…"
    ```
    > Content sections will be filled during Finalization (Step 17). Skeleton-only at this stage.
12. **Classify and register each improvement** — Phase 7 collect-only model (2026-05-11). Tools Review does **not** triage; it only routes by domain (framework vs. product) — use the [Issue Classification and Routing Guide](../../guides/framework/issue-classification-and-routing-guide.md) to make that determination — and lets the downstream task handle priority/section/owner assignment.

    | If the item is... | Route to... | Script |
    |---|---|---|
    | Process framework improvement (task, template, guide, script, workflow) | **Central Intake section** of `appdev/process-framework-central/state-tracking/permanent/process-improvement-tracking.md` (Section 1 — Intake) | [`New-ProcessImprovement.ps1`](../../scripts/file-creation/support/New-ProcessImprovement.ps1) |
    | Product feature request (new capability or enhancement to existing feature) | Project-local [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) (per project, not central) | [`New-FeatureRequest.ps1`](../../scripts/file-creation/01-planning/New-FeatureRequest.ps1) |
    | Bug (something broken that needs fixing) | Project-local [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) (per project) | [`New-BugReport.ps1`](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) |
    | Technical debt (code quality issue, not broken but should be improved) | Project-local [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) (per project) | [`Update-TechDebt.ps1 -Add`](../../scripts/update/Update-TechDebt.ps1) |

    > **🎯 NEW IN PHASE 7**: Framework IMPs land in the central **Intake** section with a 7-column row (no Priority/Status/Resp Task cells). The [IMP Triage Task (PF-TSK-089)](imp-triage-task.md) then sorts Intake rows into Improvements / Extensions / Structural Changes / Active Pilots / Rejected based on classification. Tools Review's job is observation + intake, not classification.

    ```powershell
    # Framework improvement — single item (lands in Intake)
    # Phase 7: -Priority / -Status / -RespTask params no longer accepted; routing happens during Triage.
    # Length caps (single and batch): -Description 10–500 chars (-Notes is uncapped) — compose to length;
    # pre-flight a borderline call with -WhatIf (validation fires before anything is created).
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 -Source "Tools Review YYYY-MM-DD" -SourceLink "appdev/process-framework-central/feedback/reviews/tools-review-YYYYMMDD-HHMMSS.md" -Description "What needs improving" -Notes "Context"

    # Framework improvements — batch mode (preferred when registering multiple IMPs)
    # Create a JSON file with an array of improvement objects, then:
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1 -BatchFile "improvements.json"
    # Each object supports: Source, SourceLink, Description (required), Notes. Phase 7: Priority/Status/RespTask are
    # silently ignored on intake (warning emitted) — pass them to Update-ProcessImprovement.ps1 -MoveToSection after Triage.

    # Product feature request — use the actual filename from Step 11
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/01-planning/New-FeatureRequest.ps1 -Source "Tools Review YYYY-MM-DD" -SourceLink "appdev/process-framework-central/feedback/reviews/tools-review-YYYYMMDD-HHMMSS.md" -Description "What is being requested" -Priority "MEDIUM" -Notes "Context"
    ```
    - **📥 SUBSECTIONS TO DRAIN**: Each feedback form has three IMP-yielding subsections — `## Improvement Suggestions` (especially `### What could be improved` and `### Specific suggestions`), `### Documentation Streamlining Opportunities` (under `## Follow-up Actions Required`), AND `## Human Intervention Log` (including rows the human partner appended post-session). The checkbox-todo formatting of Streamlining Opportunities does NOT mean human-only work; each checkbox item is an IMP candidate. For the intervention log, each row whose *Doc with Gap* / *Suggested Fix* columns name a concrete fix is an IMP candidate ("N/A — inherently human decision" / "None — judgment call" rows are not). Drain all three. Entries marked `[ALREADY FILED — PF-IMP-NNNN, do not re-file]` are cross-references to IMPs the session filed directly (per the [Issue Classification and Routing Guide](../../guides/framework/issue-classification-and-routing-guide.md)'s file-now conditions) — confirm the named row exists, then skip them.
    - **🧑‍🔧 HUMAN-CORRECTION PROVENANCE**: When an IMP originates from a Human Intervention Log row, append the token `[HUMAN-CORRECTION]` to its `-Notes`. Human counter-flow corrections are the highest-trust improvement signal — the framework demonstrably failed in-session and a human had to step in — and [IMP Triage (PF-TSK-089)](imp-triage-task.md) treats the token as a priority booster.
    - **🏷️ BUG vs IMP CLASSIFICATION**: The distinction is **domain-based**, not severity-based. Use the file location as the primary heuristic:
      - `process-framework/`, `doc/` (in projects) or `blueprint/process-framework/`, `blueprint/doc/` (in appdev) → **IMP** (framework tooling, even if the script crashes)
      - `src/...` → **BUG** (product code)
      - `test/` → either: test infrastructure issues (runner scripts, tracking) = **IMP**; product test defects = **BUG**
    - **🔗 TRACEABILITY REQUIREMENT**: Use `-SourceLink` with the actual review summary filename from Step 11 for full traceability. The review summary itself lives at `appdev/process-framework-central/feedback/reviews/` post-Phase-7.
    - **🎯 ROUTING HINT (optional, goes in Notes)**: When the analysis you've already done makes the destination section obvious — multi-component scope (new task + template + script + guide) → suggests Extension; pure file/directory reorganization → suggests Structural Change; new task creation → suggests Extension via PF-TSK-001 — note that observation in `-Notes` as a hint to Triage (e.g., `-Notes "Triage hint: extension scope (new task + template + guide)"`). **Do not pass `-RespTask`** — that parameter no longer exists in Phase 7's New-ProcessImprovement intake path. Triage decides routing.
    - **🔍 DEDUPLICATION & RECONCILIATION**: Before registering a new IMP, search for existing entries covering the same tool or issue across **both** files — the **open sections** of the central `process-improvement-tracking.md` (Intake / Improvements / Extensions / Structural Changes / Active Pilots) **and the Completed / Rejected rows in `appdev/process-framework-central/state-tracking/permanent/archive/process-improvement-tracking-archive.md`** (the live file ends at Section 5 — Active Pilots; completed and rejected rows are relocated to the archive, so a dedup pass that reads only the live file silently misses everything already done). Run this search with [`Find-Improvement.ps1`](../../scripts/Find-Improvement.ps1) `-Keyword <topic / artifact-name>` (search the named script/file too, not only topic wording — same-defect rows often share only the filename) — it scans both files row-aware and prints one readable snippet per match, where plain line grep returns `[Omitted long matching line]` on the archive's long Notes cells. Also search the project's own [technical-debt-tracking.md](../../../doc/state-tracking/permanent/technical-debt-tracking.md) — script/automation defects sometimes land there first when discovered mid-task. A **concurrent sibling review** is a further source: check `appdev/process-framework-central/feedback/reviews/` for a review summary dated within the current cycle (since the oldest form in your batch was created); if one exists, read the Intake rows whose `Source` names it before registering — one read establishes batch-level disjointness against everything the sibling filed (its summary lists row IDs only; the tracker carries their descriptions). Skip registration if already tracked in any of them — **unless the hit is a Completed archive row and the symptom re-appeared after the fix took effect**: that is a *recurrence*, not a duplicate — register with `[RECURRENCE of PF-IMP-NNN]` appended to `-Notes`, naming the completed row whose fix failed ([IMP Triage](imp-triage-task.md) treats the token as a priority booster, parallel to `[HUMAN-CORRECTION]`); the ordering test that distinguishes a recurrence from a plain duplicate is in the [edge-cases guide](../../guides/support/tools-review-edge-cases-guide.md). The **Rejected** mirror: a Rejected-row hit skips only while its recorded rejection reason still holds — read the reason (following a `Superseded by` pointer to the umbrella's `[CONSTITUENT …]` marker): a terminal reason (`[DEAD PREMISE]`, `dropped — do not re-file`) keeps the skip; a **conditional** reason whose condition has since been falsified makes the candidate a *revival*, not a duplicate — register with `[REVIVES PF-IMP-NNNN]` appended to `-Notes`, quoting the recorded reason. On any closed-row hit, the skip verdict is read off the **terminal row in full**: an umbrella's constituent-disposition markers decide coverage — an ask absent from them is *not* covered (pre-convention umbrellas carry no markers at all); a supersession chain is followed to its terminal Completed row and both its description **and** Notes read — an ask can ship recorded only in the Notes, or drop silently along the chain. Never conclude handled-or-not from a pointer or a description snippet. **Also reconcile against non-IMP coverage** *(PF-IMP-1004)* — a pending-migration entry (`per-project-migrations/<PROJECT-ID>/pending-migrations.md`) or a change already shipped in `blueprint` touching the same artifact may have already resolved it. Skip when the issue is already covered there, not only when an IMP already exists. (IMP Triage applies the same reconciliation downstream; catching it at intake avoids the row entirely.) The same `Find-Improvement.ps1` search also covers the [Improvement Backlog](../../../process-framework-central/state-tracking/permanent/improvement-backlog.md) (`backlog`-labeled hits) — a backlog hit is handled by the materiality-bar bullet below, not skipped.
    - **🚧 MATERIALITY BAR — Intake vs. backlog** *(framework IMPs only; PF-IMP-1882)*: a candidate files into Intake only if it carries at least one of: **(a)** an observed in-session failure or friction, with the incident named (wrong action taken, human had to intervene, measurable cost); **(b)** a verified defect — behavior contradicts documentation, or a crash/data error; **(c)** `[HUMAN-CORRECTION]` or `[RECURRENCE …]` provenance; **(d)** an explicit human-partner request. A candidate with none of these — prophylactic wording, robustness ideas, "consider X" suggestions with no incident behind them — routes to the central [Improvement Backlog](../../../process-framework-central/state-tracking/permanent/improvement-backlog.md) instead — all three backlog operations go through [`Update-ImprovementBacklog.ps1`](../../scripts/update/Update-ImprovementBacklog.ps1), never hand-edits (independent recurrence, not filing, is what earns a speculative suggestion a tracker row):
      1. **Match check**: search the backlog for a row with the same affected artifact and the same underlying suggestion (`Find-Improvement.ps1 -Keyword <artifact/topic>`, `backlog`-labeled hits). **Match → promote**: `Update-ImprovementBacklog.ps1 -Promote -BklId BKL-NNN -Source "Tools Review YYYY-MM-DD"` — files the fresh Intake IMP (row's Description, `[BACKLOG-PROMOTED BKL-NNN]` provenance with both reports' sources) and deletes the backlog row. A **bar-passing** candidate that matches a backlog row promotes it the same way.
      2. **No match → append**: `Update-ImprovementBacklog.ps1 -Description "<candidate>" -SourceTask PF-TSK-XXX -Source "Tools Review YYYY-MM-DD" -AffectedArtifact "<file/script/task>" -FormsEvaluated <N of that task's forms this cycle>` — the script mints the BKL id and computes the Counter (task max + FormsEvaluated; same-cycle adds share one Counter; approximate arithmetic is acceptable by design).
      3. **Expiry sweep** (once per session, for each Source Task whose forms this session evaluated): `Update-ImprovementBacklog.ps1 -ExpireSweep -SourceTask PF-TSK-XXX` — deletes that task's rows sitting ≥ 100 behind its high-water counter; add `-FormsEvaluated <N>` only when the session appended no rows for the task (appended rows already carry this cycle's forms in their Counter).

      Record the session's backlog accounting — candidates backlogged (with BKL-IDs), promoted, and expired — in the review summary (Step 17): the counts are digest-visible so the owner can rescue any backlogged candidate with one word.
    - **🔎 VERIFY SPECIFICS BEFORE FILING** *(PF-IMP-1162)*: A feedback form's claim is raw input, not ground truth. Before registering an IMP, code-verify any load-bearing specific it asserts — a file/line reference, a validator surface label, a parameter or flag name, an "X is missing / does Y" behavioral claim, or a proposed fix mechanism — against the **canonical `blueprint/process-framework` source** (not a project's working copy, which drifts). If a specific checks out, file it concretely; if you cannot confirm it in the time available, still file the IMP but **mark the unverified specifics approximate** in `-Notes` (e.g., "param name approximate — verify at implementation") so the downstream task knows not to trust them verbatim. Drop the claim if verification shows it is already resolved or simply wrong. This is the intake-time defense against the stale-IMP pattern — specifics that read precise but are outdated by the time the IMP reaches implementation. When a claim enumerates affected sites (files, call sites, snippets), also record in `-Notes` the search that produced the list — the actual pattern/command — labeled **EXHAUSTIVE** (the search defines the population) or **ILLUSTRATIVE** (examples only — scope must be re-derived at implementation). A pasted search lets the implementing session re-derive scope in one command; an unlabeled list reads as complete when it isn't (precedent in the edge-cases guide).
    - **🔖 NAME-ANCHORED REFERENCES** *(PF-IMP-1302)*: When an IMP cites a task step or a state-file section, anchor it by **heading title, not number** — e.g. "the Classify-and-register step", not "Step 12"; a section by its title, not "§10". Step/section numbers drift between filing and implementation; a stale number is the most common cause of an IMP that reads precise but points the implementing session at the wrong target.
    - **🎯 GRANULARITY**: Each IMP must describe exactly one actionable change. If a theme or feedback item contains multiple independent changes (e.g., "add X to task A, add Y to task B, add Z to task C"), register each as a separate IMP. Conversely, do not split a single cohesive change across multiple IMPs.
    - **🧩 CROSS-ROW NOTES — cluster hints and forecast notes**: Two `-Notes` records let downstream sessions reuse this session's analysis; write both at filing time. **Backward — cluster hint**: when rows filed this session should settle together (one principle across several artifacts; an instance and its guard), name the sibling row IDs in each row's `-Notes` — [IMP Triage](imp-triage-task.md) consolidates on these hints while still applying its own cluster criteria independently. **Forward — forecast note**: when analysis shows specific *unprocessed* forms will yield near-duplicates or sharper versions of a row being filed, name those forms and the expected relation in `-Notes` (e.g. "RECURS: PF-FEE-NNNN in the unprocessed remainder reports the same issue") — the next Tools Review dedups its candidates against these. The straddling-theme record for split batches (Step 2) is the split-specific instance of this channel.
13. **🚨 SCOPE BOUNDARY**: Tools Review identifies and documents improvements only. Triage is the **next** task, not part of this one. Hand off to [IMP Triage (PF-TSK-089)](imp-triage-task.md) — it drains the Intake section and routes rows to Improvements / Extensions / Structural Changes / Active Pilots / Rejected. For product items, the appropriate downstream is [Feature Request Evaluation](../01-planning/feature-request-evaluation.md) (feature requests) or [Bug Triage](../06-maintenance/bug-triage-task.md) (bugs). Queue depth and drain capacity are out of scope by design (see the edge-cases guide before filing an observation about them).
14. **Archive processed feedback forms** (paths feed Step 15). Phase 7 cutover: archives live under `appdev/process-framework-central/feedback/archive/` regardless of which project's forms are being processed (cross-project shared archive).
    1. **Create the archive folder using the same HHMMSS as the review summary filename from Step 11** so concurrent same-date sessions stay isolated:
       `appdev/process-framework-central/feedback/archive/YYYY-MM/tools-review-YYYYMMDD-HHMMSS/processed-forms/`
    2. **Build an explicit move list** — first re-run [`Validate-FeedbackForms.ps1`](../../scripts/validation/Validate-FeedbackForms.ps1) (report mode) over the active folder: a form excluded at inventory as validator-flagged that now **passes** was completed by its parallel session within the cycle and joins the batch — analyze it now (Steps 6–9), register its findings (Step 12), and include it in the summary; one still failing stays active for the next cycle. Then enumerate the exact filenames of the forms you analyzed this session (the same list that goes into the review summary's Archived Forms section). Do **not** use a `*.md` glob: concurrent sessions may have created additional forms in the active folder since you started reading.
    3. **Move by explicit filename list** (e.g., `Move-Item -Path 'appdev/process-framework-central/feedback/feedback-forms/<form1>.md','...<form2>.md',… -Destination '<archive>/'`), not by glob.
    4. **Verify after move**: count of files in the new archive folder equals length of your move list, AND none of the listed filenames remain in `appdev/process-framework-central/feedback/feedback-forms/`. Stop and reconcile before Step 15 if either check fails.
15. **Record ratings in feedback database**: After archiving, extract ratings from the archived forms and record them:
    ```bash
    # Extract ratings from archived forms into JSON
    # Use the same YYYYMMDD-HHMMSS as the archive folder created in Step 14
    python process-framework/scripts/extract_ratings.py \
        --review-cycle-id "tools-review-YYYYMMDD-HHMMSS" \
        --archived-prefix "appdev/process-framework-central/feedback/archive/YYYY-MM/tools-review-YYYYMMDD-HHMMSS/processed-forms" \
        appdev/process-framework-central/feedback/archive/YYYY-MM/tools-review-YYYYMMDD-HHMMSS/processed-forms/*feedback*.md \
        -o ratings-input.json

    # Record in database
    python process-framework/scripts/feedback_db.py record --json ratings-input.json
    ```
    The [`extract_ratings.py`](../../scripts/extract_ratings.py) script parses feedback form markdown and generates JSON matching the [feedback-db-input-template.json](../../templates/support/feedback-db-input-template.json) schema. Review the output before recording: each `tool_doc_id` should be the artifact's **portable framework ID** (`PF-TSK-009`, `PF-GDE-068`, `PF-TEM-033`, `PF-FST-003`), the **filename** only for a genuinely ID-less artifact (script, craft skill, companion path file). The extractor and `record` both normalize to this form — a heading that named the tool by filename still keys by ID (a filename key for an ID-carrying artifact: see the edge-cases guide). Per the [TOOL_DOC_ID convention](../../guides/support/process-improvement-task-reference-guide.md#tool_doc_id-convention), a project-local instance ID (`PD-*`/`TE-*`/`PF-STA`) is never a key.

### Finalization

16. Verify all improvement opportunities are properly documented
17. **Fill review summary content — this is the session digest (PF-PRO-059)**: Complete every section of the skeleton created in Step 11, including its **Session Digest** slots (batch-selection decision from Step 5; filing plan, one line per filed row; each ambiguity named individually; core files touched, which feeds the Standing Orders oscillation tripwire) and the backlog accounting per the materiality-bar bullet. The template's slots are the digest's shape — fill them rather than inventing headings. Throughout, **reference filed PF-IMP row IDs and never restate a tracker row**: the row is authoritative for what it says, this summary for why it was filed, and a description hand-copied here is read downstream as if authoritative. If you passed `-FormsList` at Step 11, the Archived Forms Form and Task columns are already filled — add only each row's Context. The owner reviews digests at the Standing Orders cadence; silence = consent, veto = scripted move-back.
18. Ensure all tracking files are updated (process-improvement-tracking, feature-request-tracking, bug-tracking, technical-debt-tracking — as applicable)
19. Communicate identified improvements to project stakeholders
20. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Framework IMP rows in central Intake** — written to Section 1 — Intake of `appdev/process-framework-central/state-tracking/permanent/process-improvement-tracking.md` (Phase 7). Triage (PF-TSK-089) is the consumer.
- **Product-side opportunities** (per project, not central): [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) for product feature requests, [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) for bugs, [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) for tech debt
- **Review Summary** - Documentation of findings and identified improvements, using the [Tools Review Summary Template](../../templates/support/tools-review-summary-template.md). Created via [`New-ReviewSummary.ps1`](../../scripts/file-creation/06-maintenance/New-ReviewSummary.ps1) — writes to `appdev/process-framework-central/feedback/reviews/` (Phase 7).
- **Ratings Database Update** - Quantified ratings recorded in `appdev/process-framework-central/feedback/ratings.db` for trend analysis via `python process-framework/scripts/feedback_db.py record` (use [feedback-db-input-template.json](../../templates/support/feedback-db-input-template.json) as reference)
- **Archive of Processed Forms** - Organized archive at `appdev/process-framework-central/feedback/archive/YYYY-MM/tools-review-YYYYMMDD-HHMMSS/processed-forms/`

## State Tracking

The following state files must be updated as part of this task:

- **Central `process-improvement-tracking.md`** (Section 1 — Intake) at `appdev/process-framework-central/state-tracking/permanent/` — framework improvements from feedback analysis. Phase 7: rows always land in Intake; downstream Triage moves them to destination sections.
- **Central [Improvement Backlog](../../../process-framework-central/state-tracking/permanent/improvement-backlog.md)** (`improvement-backlog.md`, same central directory) — below-materiality-bar candidates appended, matched rows promoted to Intake, expired rows deleted (per the classify-and-register step's materiality-bar bullet)
- Project-local [Feature Request Tracking](../../../doc/state-tracking/permanent/feature-request-tracking.md) — product feature requests identified from feedback analysis (per project)
- Project-local [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) — bugs identified from feedback analysis (per project)
- Project-local [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) — technical debt items identified from feedback analysis (per project)
- **🔗 MANDATORY**: All entries must include links to the tools review analysis file for full traceability. The review summary lives in `appdev/process-framework-central/feedback/reviews/` post-Phase-7.

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Framework IMP rows landed in central **Section 1 — Intake** with the 7-col schema (ID, Source, Description, Project, Framework Version, Last Updated, Notes)
  - [ ] Product-side opportunities documented in the appropriate project-local tracking files (feature-request-tracking, bug-tracking, technical-debt-tracking)
  - [ ] Review summary created at `appdev/process-framework-central/feedback/reviews/` — including the digest content (batch-selection decision, filing plan with row-ID references, ambiguities named individually, core files touched)
  - [ ] Archive of processed feedback forms at `appdev/process-framework-central/feedback/archive/YYYY-MM/...`
- [ ] **Verify Feedback Grouping**: Ensure that only feedback forms for the same task type were analyzed together
- [ ] **Update State Files**: Confirm all state tracking files have been updated
  - [ ] Central process-improvement-tracking.md Intake section has the new rows
  - [ ] Central improvement-backlog.md reflects this session's backlog outcomes (appends, promotions, expiries) and the review summary carries the accounting
  - [ ] Project-local trackers updated for product items (per project, where applicable)
- [ ] **Archive Processed Forms**: Move analyzed feedback forms to central archive (must happen before recording ratings):
  - [ ] Create archive folder with session HHMMSS suffix matching the review summary filename from Step 11: `appdev/process-framework-central/feedback/archive/YYYY-MM/tools-review-YYYYMMDD-HHMMSS`
  - [ ] Create subfolder: `processed-forms/` within the archive folder
  - [ ] **⚠️ CRITICAL DISTINCTION**: Only move feedback forms that were **analyzed during this session**
    - ✅ **Archive These**: Feedback forms that you reviewed, analyzed, and extracted improvements from
    - ❌ **DO NOT Archive**: Newly created feedback forms (including the PF-TSK-010 form created for this session)
    - ❌ **DO NOT Archive**: Feedback forms that haven't been analyzed yet
  - [ ] **Move by explicit filename list, not glob** — concurrent same-date sessions may have created additional forms in the active folder
  - [ ] **Verify after move**: archive folder count equals move-list length; no listed filenames remain in the active folder
  - [ ] **Keep Active**: Leave newly created feedback forms in the active feedback-forms folder for future analysis
  - [ ] Document which specific forms were archived vs. kept active in the review summary
- [ ] **Record Ratings**: Extract ratings via [`extract_ratings.py`](../../scripts/extract_ratings.py) and record in database via `feedback_db.py record` (see Step 15 for commands)
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-010`, context "Tools Review".
- [ ] **Schedule Next Review**: Set a reminder for the next tools review cycle

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `appdev/process-framework-central/feedback/reviews/tools-review-YYYYMMDD.md` | Script | Review summary from template (PF-TEM-046) |
| **Updates** | [`process-improvement-tracking.md`](../../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) | Script | Adds new improvement entries via New-ProcessImprovement.ps1 |
| **Updates** | [`feature-request-tracking.md`](../../../doc/state-tracking/permanent/feature-request-tracking.md) | `New-FeatureRequest.ps1` (conditional) | Product feature requests from feedback analysis |
| **Updates** | [`bug-tracking.md`](../../../doc/state-tracking/permanent/bug-tracking.md) | `New-BugReport.ps1` (conditional) | Bugs identified from feedback analysis |
| **Updates** | [`technical-debt-tracking.md`](../../../doc/state-tracking/permanent/technical-debt-tracking.md) | `Update-TechDebt.ps1` (conditional) | Tech debt items from feedback analysis |
| **Updates** | `appdev/process-framework-central/feedback/ratings.db` | `feedback_db.py record` | Feedback ratings database |

## Next Tasks

- [**IMP Triage (PF-TSK-089)**](imp-triage-task.md) — primary downstream task. Drains Intake into the appropriate destination sections (Improvements / Extensions / Structural Changes / Active Pilots / Rejected). Run this next so the freshly-intaken framework IMPs get properly classified before they sit too long.
- [**Process Improvement (PF-TSK-009)**](process-improvement-task.md) — for implementing IMPs that Triage routes to the Improvements section (downstream of Triage, not directly from Tools Review).

<!-- merged from transition-registry entry: Tools Review -->
### Prerequisites for Transition

- [ ] Tool evaluation completed
- [ ] Tool improvements implemented
- [ ] Tool documentation updated
- [ ] Tool effectiveness measured

### Next Task Selection

- **Always**: → Return to development work with improved tools

## Related Resources

- [Tools Review Edge Cases (PF-GDE-078)](../../guides/support/tools-review-edge-cases-guide.md) - this task's consult-on-stumble edge-case file (PF-PRO-059); consult on an error, surprise, or ambiguous fork at any step
- [IMP Triage Task (PF-TSK-089)](imp-triage-task.md) - The task that drains the Intake section into destination sections
- [`imp-triage` craft skill](../../../.claude/skills/imp-triage/SKILL.md) - Decision criteria for the downstream Triage (replaced the retired IMP Triage Usage Guide)
