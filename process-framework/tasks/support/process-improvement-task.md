---
id: PF-TSK-009
type: Process Framework
category: Task Definition
domain: agnostic
version: 3.43
created: 2024-07-15
updated: 2026-08-10
description: "Improve development processes"
use_when: >-
  Enhancing existing framework artifacts: content edits to tasks/guides/templates, behavior-preserving script refactors, defect fixes. Triggers: 'improve task X', 'fix script Y', 'update guide Z', 'implement IMP-NNN' (only IMPs whose tracking row carries Resp Task blank or PF-TSK-009 — for any other Resp Task value, that column names the owning task; check the row before selecting).
triggers:
  - "improve task X"
  - "fix script Y"
  - "update guide Z"
  - "implement IMP-NNN (Resp Task blank or PF-TSK-009; otherwise the IMP's Resp Task column names the owning task)"
automation: semi
scripts:
  - ../../scripts/file-creation/support/New-ProcessImprovement.ps1
  - ../../scripts/update/Update-ProcessImprovement.ps1
trigger_status:
  - raw: "`process-improvement-tracking.md` → Active items (not Completed/Deferred)"
output_status:
  - file: process-improvement-tracking.md
    status: "✅ Completed"
---

# Process Improvement

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only the Process-Improvement–specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Analyze, optimize, and document development processes to improve efficiency, quality, and consistency across the project, enabling more effective workflows and higher quality outputs through systematic improvements.

## Document set

Three artifacts cover this task:

- **This file** — the operative process: 17 steps to execute end-to-end
- **[Reference companion](../../guides/support/process-improvement-task-reference-guide.md)** — tables and conventions you look up at specific steps: problem-verification notes, evaluation criteria, routing destinations, risk classes, framework-script verification by edit kind, common stale-description sites, TOOL_DOC_ID and constituent-disposition conventions
- **[`process-improvement` craft skill](../../../.claude/skills/process-improvement/SKILL.md)** — the reasoning behind the gates, entry modes, execution safeguards, worked examples, and troubleshooting; activated at Step 0 (Check Recommended Skills). Replaces the retired implementation guide; if the Skill tool does not list it, read the linked `SKILL.md` directly — equivalent, not degraded.

Read this file end-to-end at session start. Cross to the reference at the step that points to it. The skill (when active) supplies the pattern to imitate and the intent behind each gate for edge cases.

## AI Agent Role

**Role**: Process Engineer
**Mindset**: Analytical, efficiency-focused, systematic improvement-oriented
**Focus Areas**: Workflow bottlenecks, automation opportunities, process standardization, quality metrics
**Communication Style**: Present data-driven improvement recommendations, ask about pain points and workflow preferences

> **Note**: Phase 7 workflow (2026-05-11): IMP *intake* is handled by [Tools Review (PF-TSK-010)](tools-review-task.md) (writes to Section 1 — Intake); IMP *classification and section routing* is handled by [IMP Triage (PF-TSK-089)](imp-triage-task.md) (moves rows from Intake to Improvements / Extensions / Structural Changes / Active Pilots / Rejected). This task picks up rows that Triage placed in **Section 2 — Improvements** and *executes* them. If scope mismatch surfaces during evaluation (Step 3), re-route via the [Routing reference](../../guides/support/process-improvement-task-reference-guide.md#routing) rather than handling out-of-scope work inline.

## Context Requirements

- **Critical (Must Read):**

  - [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - Select the improvement to execute
  - [Tools Review Summaries](../../../process-framework-central/feedback/reviews/) - Source analysis for the selected improvement
  - [Process Improvement Task Reference](../../guides/support/process-improvement-task-reference-guide.md) - Lookup tables consulted at Steps 2, 3, 10, 11, 12, 14
  - [`process-improvement` craft skill](../../../.claude/skills/process-improvement/SKILL.md) - Gate rationales, entry modes, execution safeguards, examples, troubleshooting; activated at Step 0 (Check Recommended Skills). Replaces the retired implementation guide.

- **Important (Load If Space):**

  - [Task Definitions](..) - Current task definitions (read the specific file(s) being improved)
  - [Feedback Forms](../../../process-framework-central/feedback/feedback-forms/) - Source feedback forms referenced by the improvement

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Can be used to identify areas needing improvement

## Process

> **🚨 Never implement a solution without explicit Step 6 approval** — with one exception, which this step owns rather than delegates: a change whose class appears on the **Autonomous** list of the workspace's `CLAUDE.md` **Standing Orders** section (where that workspace defines one) proceeds without the checkpoint, recording the classification in the Step 14 `-ValidationNotes` as `[AUTONOMOUS: <class>]` — that record is the provenance those orders require, and the surface an owner review samples. A class not on that list checkpoints, whatever its size. Per-change checkpoint frequency is risk-classified — see Step 10.

### Preparation

> **Session pacing**: No hard per-session cap. At each Step 16 decision, recommend either continuing with a specific open improvement — preferring one topically related to the one just completed (same task / script / area, so context is already loaded) — or finalizing. Favor finalizing as the session lengthens: checkpoint discipline and verification quality degrade with volume.

0. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `process-improvement-task`. If the `process-improvement` craft skill is available in the session, activate it — it owns the **judgment craft** this task delegates to (gate rationales for edge cases, non-standard entry modes, execution safeguards for risky change shapes, worked examples, troubleshooting). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/process-improvement/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The craft is unavailable for this run only if the skill file itself is absent (the retired implementation guide has no successor). *(Numbered 0 so the framework-wide references to this task's Steps 1–17 stay stable.)*
1. **Select improvement** from [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) and run the **claim protocol** — three checks, then claim:
   - **Parallel-session check**: **In Progress** → another session may hold it; flag to the human partner and pause until confirmed safe. **Needs Prioritization** / **Needs Implementation** → free to claim.
   - **Resp Task pre-routing**: blank or `PF-TSK-009` → claim and continue (Step 3 still runs the routing assessment — triager may have misjudged scope). Any other task ID → do not claim; surface to the human partner: *"PF-IMP-XXX is pre-routed to <task-id>; switch tasks or override?"* Resp Task is a hint at intake, not authoritative routing.
   - **Sequencing/coordination check**: read the **Notes** column for sequencing, dependency, or "implement together" conditions; carry them into Step 3 and surface conflicts there — including a named sibling completed since the note was written (a stale note), which changes the scope you actually execute.
   - **Claim**: `Update-ProcessImprovement.ps1 -ImprovementId "IMP-XXX" -NewStatus "InProgress"` — one claim per row, placed when work on that row begins: a coordinated sibling taken sequentially is claimed at the point you start it, and a triage-recorded batch worked as one combined verification is claimed in full when that verification begins. At session end, release any batch member left uncompleted (`-NewStatus NeedsImplementation`) so no stale claim survives a normal finalization.
   - **Off-pattern entry or end** (deferred row, no IMP minted yet, cross-section override; a recommended candidate taken by a parallel session before you claim it; a claim lost mid-session): consult the task's [edge-case file](../../../.claude/skills/process-improvement/references/edge-cases.md), then rejoin the protocol.
2. **Verify the problem — absence test first**: The IMP description is raw input, not a specification.
   - **Filed figures are hints**: every locator and quantitative claim the row makes — a line number, a site count, a version, a size figure, a time window ("untracked for weeks") — is re-derived at its source before use: match the site by content, read counts and versions off the file, derive the window from git history. Plausible-but-wrong figures are routine and do not by themselves invalidate the row.
   - **Run the absence test, then state the gap it reveals**: assume each target the IMP would change (artifact, passage, check, field) deleted, and say what concretely breaks — which step stalls, which decision goes wrong, which action is taken differently. Only what breaks is the target's function: the bar is a nameable consumer — a step or decision that acts on it, judgment-context consumption included — never the target's own claim of an audience. Note where else the same obligation is documented. State the verified problem as the gap between that function and the target's current state, never as a restatement of the IMP: nothing breaks → no function, so the change to evaluate is **removal**, whatever the IMP proposed; already served at a canonical home → duplication, likewise removal; the target says more than its consumers use → the problem is the **excess**. Shape-specific readings — data field, guidance passage, purely additive, partially-inert — live in [the absence test in its common shapes](../../guides/support/process-improvement-task-reference-guide.md#problem-verification-notes), the canonical catalog; consult it for the shape in hand.
   - **Confirm the problem is real and current** (use what fits): grep recent sessions for the symptom, read the artifact under discussion, inspect the feedback DB, check IMP history for prior similar reports ([`Find-Improvement.ps1`](../../scripts/Find-Improvement.ps1) `-Keyword <topic>`) — a prior **completed** same-class fix means **two strikes** (PF-PRO-059): the change to evaluate is a detector/assert/gate that kills the class, not another instance fix or prose round. When the row's own Notes cite a recurring class ("7+ archived per-script fixes"), check whether those precedents share one documented cause before accepting the per-instance framing — a shared cause makes the class the target, not the instance.
   - **By IMP shape**: cross-project-origin, data/analytics, runtime-behavior-claim, template-dedup and validator-count IMPs each carry a distinct verification obligation — see [Problem-verification notes](../../guides/support/process-improvement-task-reference-guide.md#problem-verification-notes) in the reference.
   - **Scope delta**: if verification materially changes the filed scope (the real site count or affected population differs from what the row describes), surface it to the human partner as its own beat before designing an approach — not folded into the Step 6 checkpoint.
   - **Close paths**: if the problem is clearly absent or already resolved, close the IMP and skip to Step 14 — no human checkpoint needed at this gate: mark it **Rejected** with rationale, or **Superseded** (`-NewStatus Superseded`) when a sibling change already resolved it (distinct from Rejected; kept out of the Completed trend count). Otherwise, proceed to Step 3.
3. **Evaluate the IMP** against the 9-criterion matrix in [Evaluation criteria](../../guides/support/process-improvement-task-reference-guide.md#evaluation-criteria) of the reference. The IMP's proposed solution decomposition — its own (a)/(b) breakdown of the fix — is raw input just like its problem statement: re-derive the solution space from the Step 2-verified problem before evaluating the IMP's parts, especially when `[HUMAN-CORRECTION]` provenance or prior pre-analysis makes the framing feel pre-validated. Apply the **conciseness rule** (one-line summary at Step 6 if all criteria favorable; full table only when one or more rate poorly or trigger a gate). If multiple criteria rate poorly, recommend rejection with rationale. The **minimum-viability**, **root-cause-vs-symptom**, **prevention**, and **data-driven validation** gates fire at Step 6 — see the reference. If the IMP needs re-routing, consult the [Routing reference](../../guides/support/process-improvement-task-reference-guide.md#routing); the IMP leaves this task's responsibility after re-routing.
4. **Review source feedback**: Read the [Tools Review summary](../../../process-framework-central/feedback/reviews/) and/or specific feedback forms that identified this improvement
5. **Read current state**: Examine the file(s)/tool(s) to be improved to understand the current implementation, and grep the project for the artifact/pattern being changed — a documented instruction (prose target) is matched by its *phrasings*, not one literal form: sweep synonym, backtick/code-span, and paraphrase variants until additional forms stop yielding new sites — so the Step 6 statement of which files the change touches is evidence-backed rather than assumed. Before proposing to change an existing structure or rule, also establish **why** it is the way it is — `git log -S`/`git blame` for a config line, the owning decision record (proposal, concept, ADR, archived IMP) for a structure (PF-IMP-1606)
6. **🚨 CHECKPOINT**: Present problem analysis and proposed approach(es) to human partner.

   **Format**: Begin with a **Problem Summary** (1-2 sentences — your restated problem after Step 2 verification, not a copy of the IMP description) ending with the mandatory absence-test verdict line — `Removal: proposed`, `Removal: rejected — <consumer> would <concrete break>`, or `Removal: proposed for <the inert part>` when the test splits the target, where a purely additive IMP names the neighbouring target it tested — then the evaluation table from Step 3 (or a one-line summary per the conciseness rule), then proposed approach(es) (for a low-risk single-artifact IMP, a sentence or two — not multi-paragraph prose). When proposing content edits, cite the exact target (file + section + line) alongside the proposed text. For a consolidation-umbrella IMP (one row standing in for several constituents), present one compact row per constituent — its own underlying problem and proposed fix — so each is approved on its own merits, not just the bundle.

   **Solution exploration**: Before proposing, explore the solution space — at minimum consider an MVP variant *and* a more radical alternative; for a consolidation-umbrella IMP this holds **per constituent** — each compact row presents its own explored options, not one exploration for the bundle. For a workflow-shaped IMP (context switches, round trips, task/session handoffs), one explored alternative must re-sequence the process itself — enumerate each operation's true preconditions and genuine context requirement, then reorder to minimize transitions — before considering making any tool more flexible. Present 1–3 surviving options, each one you would implement if the human selected it — a pre-rejected idea is not an alternative — and each stating its **mechanism** in one line (how it would work, not only its shape: beyond a plain content edit, shape alone is not decidable). Do not enumerate discarded ideas.

   **Counter-proposal evaluation**: When your proposed approach materially differs from the IMP description, run it through the same 9-criterion evaluation the IMP got and present both. The counter-proposal is also raw input, not a spec.

   *Rationale for solution exploration and counter-proposal evaluation: [`process-improvement` skill → gate rationales](../../../.claude/skills/process-improvement/SKILL.md) (activated at Step 0).*

   **Valid outcomes**: Approve an approach and proceed, request alternative approaches, **reject the improvement** if analysis shows it's unnecessary (mark as Rejected in tracking and skip to finalization), or **supersede into an open sibling IMP** whose scope owns the decision this IMP would pre-empt (`-NewStatus Superseded -SupersededBy <ID>`; distinct from Step 2's already-resolved case) — first carry the session's verification findings onto the absorbing IMP's Notes (`-AppendNotes`) so they survive the row's archival.

   **Reclassification**: If the IMP describes valid work that is not a process improvement (product bug, feature request, tech debt), reject it and route per the [Routing reference](../../guides/support/process-improvement-task-reference-guide.md#routing).

### Planning

7. **For multi-session improvements**: Create a state tracking file to track progress across sessions:
   ```powershell
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-TempTaskState.ps1 -TaskName "<Improvement Name>" -Variant "ProcessImprovement" -Description "<scope>"
   ```
   > Single-session improvements do not need a state file — skip this step.
8. For complex improvements with multiple distinct approaches worth deliberating, present them at Step 6 with pros/cons. Otherwise skip.
9. **🚨 CHECKPOINT** *(conditional)*: If Step 8 produced multiple alternatives, get explicit human approval on the chosen approach.
   > **Skip if Step 8 was not used and Step 6 already approved a single concrete approach.** Step 6's "approve an approach and proceed" outcome covers both checkpoints when there are no alternatives to deliberate.

### Execution

10. **Execute changes.** Work through the approved change set:
    - **Use automation scripts first**: before creating or modifying any tracked file, check `process-framework/scripts/file-creation/` and `process-framework/scripts/update/` for a script covering the operation and use it — scripts update surrounding infrastructure (ID registries, tracking tables, counters) that manual edits miss.
    - **Shared-tree concurrency**: parallel sessions edit the same appdev tree. Before editing framework files, check them for concurrent modification — `git status --porcelain -- <paths…>` takes the whole set and names only the dirty ones, so one command covers a fan-out of any size; for each file it names, `git diff HEAD -- <file>` and confirm known work accounts for every delta you didn't make.
    - **Execute by risk class** per [Risk classification](../../guides/support/process-improvement-task-reference-guide.md#risk-classification):
      - **Low-risk**: implement directly in batch — no per-change checkpoint
      - **Medium-risk**: state the planned change set briefly, implement in batch
      - **High-risk**: per-change loop — state → checkpoint → implement → checkpoint

      State the applied classification at the decision review (Step 13 — or the Step 16 beat its one-line rides) so the human can override it.
    - **Framework-script edits**: verify by edit kind per the [Framework-script verification table](../../guides/support/process-improvement-task-reference-guide.md#framework-script-verification-by-edit-kind) in the reference — each edit shape, from a docstring-only fix to a mass conversion or a brand-new script, carries a distinct verification obligation the table names.
    - **Content edits to tasks and guides** follow four principles:
      - **Rewrite, don't append — and don't over-document**: when a step needs new guidance, first ask whether it's needed at all (often the existing wording already carries it). When it is, rewrite the step so the rule absorbs it in the fewest words that work — never bolt on a Note, example, or clarification block. Additive growth is what makes task files long enough that steps get skipped.
      - **Edge material routes to the edge file (PF-PRO-059)**: anything conditional on a rare situation ("if X happens…", incident lore, anti-pattern cautions) belongs in the owning task's **edge-case file** — `references/edge-cases.md` in its craft skill, or its PF-GDE edge-cases guide (via `New-Guide.ps1`) where no skill exists — created/appended autonomously per the workspace Standing Orders (lazy creation, no empty stubs). Core keeps the happy path and load-bearing rules; growing a core file needs owner sign-off. A *silently-failing* edge case becomes a detector/assert (two-strikes rule), never prose — an agent that doesn't know it stumbled consults nothing.
      - **Step-point links**: link lookup tables and reference material at the step that consults them, not in Related Resources — links in the execution path get followed; bottom-of-file lists don't.
      - **Blueprint references stay project-agnostic** (cwd=appdev): anything under `blueprint/` rolls out to every project, so a reference an edit adds must resolve in the rolled-out layout — name appdev-local artifacts (appdev's self-test tree, root-level files) in prose as appdev's instead of linking them; central references follow the central-pointer convention (PF-IMP-1097).
    - **Full extent first (PF-PRO-059)**: for a pattern-shaped change, enumerate every site of the pattern (grep) **before** editing and execute against the full enumeration — the approved fix covers the verified defect class, not just the filed instance. After applying, verify completeness with grep-based checks — all target files contain the new pattern, none still contain the old one. If enumeration reveals materially more sites than the Step 6-approved scope, surface the delta per (b) below.
    - **Stay in scope** — two distinct cases when execution outgrows the approved plan: *(a) spillover into another task's work or across a verification boundary* (new task definition, dir reorg, framework extension, a remainder this session cannot verify) — implement the in-scope parts and file the remainder via the **spillover lane** per the [Routing reference](../../guides/support/process-improvement-task-reference-guide.md#routing): create the IMP and route it directly into its owning section, Notes marked `[SPILLOVER PF-IMP-nnnn]` naming the originating IMP (PF-PRO-059 — never back through the feedback pipeline; a spillover chain deeper than one escalates per Standing Orders); *(b) same-task scope expansion* — execution reveals more instances of the same defect class than the approved scope covered — surface the delta (count, shape, boundedness) to the human partner rather than silently absorbing or deferring it, recommending completion in one pass when the remainder is bounded and mechanically identical. A new IMP filed mid-session (scope-spillover, or a defect surfaced during the current work) and human-authorized for inline handling continues in the current session — no separate [IMP Triage (PF-TSK-089)](imp-triage-task.md) run is required for a single inline-authorized IMP; record its triage decision per the [inline-authorization recipe](../../guides/support/process-improvement-task-reference-guide.md#inline-authorization-recipe).
11. **🔍 Linked-document verification sweep**: For each file modified, grep for its path/filename across the project. Read the surrounding paragraph at each hit — descriptions and usage guidance may reference the old behavior. This sweep is part of verifying the change, not optional cleanup — its findings are regularly decision-grade (stale rules, collisions with concurrent sessions), so never skip it as routine. Update outdated context. Sweep the [common stale-description sites](../../guides/support/process-improvement-task-reference-guide.md#common-stale-description-sites) first. You may also fold in an out-of-scope quick fix the sweep surfaces — regenerating a generated projection (PF/PD/TE doc-map, task-registry) drifted by an unrelated change (when your own edit and unrelated drift both land in the projection, regenerating necessarily sweeps in both — do it, and report the combined blast radius at Step 13), or a single-artifact stale-link / wording fix small enough that one commit fully contains it; for anything larger or behavior-changing, file a spillover IMP per Step 10 instead. Report substantive findings at the Step 13 checkpoint — they may warrant re-approval; an empty sweep needs no mention there.
12. **Log tool change in feedback database** *(silent housekeeping — do not surface to the human)*. **Default (PF-IMP-832 (b))**: defer the log to Step 14 — pass the change list as JSON to [Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1) via `-LogToolChanges <json>` on the `-NewStatus Completed` invocation, so nothing is logged before a possible Step 13 revision or rejection (the payload is validated before the move — a bad tool_doc_id, or a value that resolved empty/whitespace such as a failed `Get-Content`, aborts with nothing written; a runtime log-change failure after the move emits a WARN with the move preserved). Log standalone at this step when the session does not end in `-NewStatus Completed` (e.g. multi-session work), or when any description is quote-heavy (regexes, Windows paths, backticks, `$`/`|`) — write those to a file and use `feedback_db.py log-change --batch <path>`, since JSON passed inline through **`pwsh -Command`** (via `-LogToolChanges` or `echo '[…]' | … --batch -`) is parsed by PowerShell a second time, which silently strips `$…` and backticks before the script reads it. The hazard is `-Command`-specific: `-File` passes prose verbatim, `|` survives either way, and the Bash tool is not the cause — see [PowerShell Script Execution](../../guides/support/script-development-quick-reference.md#powershell-script-execution-ai-agents) (PF-IMP-1809). See [TOOL_DOC_ID convention](../../guides/support/process-improvement-task-reference-guide.md#tool_doc_id-convention) for the canonical ID form.
    ```bash
    # Standalone single change (--date defaults to today; pass it only for retroactive logging):
    python process-framework/scripts/feedback_db.py log-change --tool <TOOL_DOC_ID> --imp <IMP-XXX> --description "<what changed>"

    # Standalone multiple changes — write the array to a file and pass it by path (robust to bash quoting; "date" optional per entry, defaults to today):
    python process-framework/scripts/feedback_db.py log-change --batch changes.json
    # (stdin form, fine only for simple text: echo '[{"tool": "ID-1", "imp": "IMP-XXX", "description": "..."}, ...]' | python process-framework/scripts/feedback_db.py log-change --batch -)
    ```

    > Verify what is logged for an IMP with `feedback_db.py list-changes --imp <IMP-XXX>` — cross-project, matches both `IMP-NNN` and `PF-IMP-NNN` historical forms. Step 14 `-ValidationNotes` references logged changes the same way — by IMP, never by change-ID range: IDs are allocated at log time (after the notes are composed, on the default deferred path) and race under parallel sessions.

### Finalization

13. **🚨 CHECKPOINT — Decision review**: Present the diff + risk classification + any substantive Step 11 findings, and any residual behavior choice the execution settled (describing one: see the [edge-case file](../../../.claude/skills/process-improvement/references/edge-cases.md)). Get approve / revise / reject. Do not mention Step 12. Format scales with risk and deviation:
    - **Skip Step 13 entirely** — low-risk AND matches the Step 6 plan AND Step 11 clean, or ran under a Standing Orders **Autonomous** class within its grant (any risk class — the `[AUTONOMOUS: <class>]` ValidationNotes record replaces the review; a deviation or substantive Step 11 finding escalates to the tiers below). The prior approval or grant already covered everything; go directly to Step 14.
    - **One-line rides Step 16** — medium- or high-risk, matches Step 6 plan, Step 11 clean. No separate checkpoint: hold Step 14's `Completed` transition and carry the line *"Risk class: \<class\>. Step 11 sweep clean. No deviation from Step 6 plan."* into the Step 16 recommendation — the human's continue/finalize answer doubles as approval, an objection routes back here as revise/reject, and the held Step 14 runs after that answer.
    - **Full diff** — change deviated from Step 6 plan OR Step 11 surfaced substantive findings. Re-approval signal needed here, before Step 14.
14. Update [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) using [Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1):
    ```powershell
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-ProcessImprovement.ps1 -ImprovementId "IMP-XXX" -NewStatus "Completed" -Impact "HIGH|MEDIUM|LOW" -ValidationNotes "What was done."
    ```

    > **Bash gotcha for `-ValidationNotes` with backticks**: see the [reference](../../guides/support/process-improvement-task-reference-guide.md#bash--validationnotes-backtick-gotcha).
    > **Consolidation umbrella**: `-ValidationNotes` must also encode each constituent's outcome with a `[CONSTITUENT PF-IMP-NNNN: shipped | dropped — do not re-file: <reason> | carved out → <ID>]` marker per the [constituent-disposition convention](../../guides/support/process-improvement-task-reference-guide.md#constituent-disposition-convention-umbrella-imps) — the constituents' own rows archive as bare `Superseded by` pointers, so the umbrella row is where a later dedup scan learns a dropped constituent must not be re-filed.
15. Update any other affected state files, **remove any scratch artifacts this session created** (pre-delete backups, synthetic-harness output, temp fixtures) so nothing transient is left in the tree, and confirm every file this session touched still exists (a ` D` in `git status`: see the edge-case file)
    > If a temp state file was created in Step 7, mark its checkboxes complete and move it to the `state-tracking/temporary/old/` directory at the location that `Get-StateTrackingContext` resolved for you (post-Phase-5/7: appdev → `process-framework-central/state-tracking/temporary/old/`; projects → `doc/state-tracking/temporary/old/`).
    > **Pending-migration entries (cwd=appdev only)**: If the change touched a `blueprint/` file *outside* `blueprint/process-framework/` — e.g. `blueprint/CLAUDE.md`, `blueprint/doc/`, or `blueprint/test/` — file a pending-migration entry under `process-framework-central/per-project-migrations/<PROJECT-ID>/pending-migrations.md` for every registered product project. `Push-FrameworkUpdate.ps1` mirrors only `blueprint/process-framework/` (plus per-skill `.claude/skills/`); the rest of `blueprint/` seeds project working trees at `Register-Project` bootstrap, so post-bootstrap changes don't reach existing projects without a migration. Use the [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md). The same applies to framework templates whose per-project instantiation is project-local (e.g. `tools/linkWatcher/linkwatcher-config.template.yaml`, `.linkwatcher-ignore.template`): rollout updates only the template copy — changes to baseline content reach projects' active files via migration entries.
16. **Recommend next action**: either "continue with `<improvement>` (related to what we just did)" or "finalize the session", and let the human partner choose — leading with any decision-review line held from Step 13 (the answer doubles as its approval; run the held Step 14 after it). Draw the continuation candidate from a fresh read of the current Section 2 — Improvements taken at recommendation time, reading its ID, open status, and the topic you name off that row, never from memory or a secondary artifact — the section shifts underneath the session: items completed earlier are gone from it, and parallel sessions claim, complete, or reject rows between any two reads. If continuing, return to Step 1 for the next improvement; otherwise proceed to Step 17.
17. **🚨 MANDATORY FINAL STEP** (session end only): Complete the Task Completion Checklist below — one feedback form covering all improvements done in this session

> **Validation**: Improvements are validated through the next usage cycle. Subsequent feedback (via [Tools Review](tools-review-task.md)) will confirm whether the improvement achieved its goal.

## Tools and Scripts

- **[New-ProcessImprovement.ps1](../../scripts/file-creation/support/New-ProcessImprovement.ps1)** - Add new improvement entries with auto-assigned PF-IMP IDs
- **[Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1)** - Automate tracking file updates (status changes, completion moves, summary count, update history)
- **[New-TempTaskState.ps1 -Variant ProcessImprovement](../../scripts/file-creation/support/New-TempTaskState.ps1)** - Create multi-session process improvement state tracking files (uses [process improvement template](../../templates/support/temp-process-improvement-state-template.md))
- **[New-FeedbackForm.ps1](../../scripts/file-creation/support/New-FeedbackForm.ps1)** - Create feedback forms for task completion
- **[Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md)** - Central tracking file for all improvements
- **[feedback_db.py](../../scripts/feedback_db.py)** - Record tool changes for trend analysis (`log-change` subcommand, supports `--batch` for multiple changes)

## Outputs

- **Process Documentation** - New or updated process documentation (task definitions, templates, guides, scripts)
- **Updated Tracking** - [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) updated with improvement status and completion details

## State Tracking

The following state files must be updated as part of this task:

- [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - Update with:
  - Completion date and impact for implemented improvements
  - Move completed items from "Section 2 — Improvements" to "Section 6 — Completed" **in the archive file ([process-improvement-tracking-archive.md](../../../process-framework-central/state-tracking/permanent/archive/process-improvement-tracking-archive.md)), where `Update-ProcessImprovement.ps1` relocates completed rows — confirm the move by grepping the ID in row form (`| PF-IMP-NNNN |`, with the pipes) — a bare-ID grep false-positives on sibling rows' Notes cross-references to the archived ID — now in the archive Completed section, gone from this tracker's Section 2; never by section row counts, which a concurrent draining session can shift mid-task**
  - Ensure "Section 2 — Improvements" contains only open items

## ⚠️ Task Completion Checklist (Process-Improvement–specific)

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **Process-Improvement–specific** verifications that plug into it.

- [ ] **Verify Process Discipline**: Confirm the process was followed correctly (where a Standing Orders **Autonomous** class applied, the Step 6 / Step 9 items below are satisfied by the `[AUTONOMOUS: <class>]` classification recorded in the completion ValidationNotes, not by an approval)
  - [ ] Each IMP was either rejected at the problem-verification gate (Step 2) or evaluated against structured criteria (Step 3)
  - [ ] Problem analysis was presented at Step 6 before any solution work
  - [ ] Approach was approved at Step 6 (and Step 9 if multiple alternatives) before execution
  - [ ] Changes were executed by risk class (Step 10); high-risk changes used per-change sub-checkpoints
  - [ ] Human feedback was received at all required checkpoints (Step 6, Step 13 — directly or via its one-line riding the Step 16 beat — plus Step 10 sub-checkpoints for high-risk)
  - [ ] Each Step 16 continue/finalize decision was an explicit recommendation to the human partner

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Process documentation changes are clear and actionable
  - [ ] Changed files are consistent with the rest of the framework
  - [ ] Linked documents (guides, context maps, registries) are updated or removed
  - [ ] **Scratch artifacts cleaned up**: session-created transient files (pre-delete backups, synthetic-harness output, temp fixtures) removed; none left in the tree (N/A if none created)
  - [ ] **Framework script verification** (by edit kind): each script touched was verified per its edit kind's row in the [framework-script verification table](../../guides/support/process-improvement-task-reference-guide.md#framework-script-verification-by-edit-kind) — the table's prescription, not a from-memory restatement, is the contract. N/A if the session touched no scripts.

- [ ] **Update State Files**:
  - [ ] Process Improvement Tracking: completed improvement moved to "Section 6 — Completed" (in the archive file, where `Update-ProcessImprovement.ps1` relocates it) with date and impact
  - [ ] "Section 2 — Improvements" contains only open items
  - [ ] File metadata updated with current date
  - [ ] **Pending-migration entries filed (cwd=appdev only)**: If this change touched a `blueprint/` file outside `blueprint/process-framework/` (e.g. `blueprint/CLAUDE.md`, `blueprint/doc/`, `blueprint/test/`), a pending-migration entry has been filed under `process-framework-central/per-project-migrations/<PROJECT-ID>/pending-migrations.md` for every registered product project, using the [Pending Migration Entry Template](../../templates/support/pending-migration-entry-template.md). `Push-FrameworkUpdate.ps1` mirrors only `blueprint/process-framework/` (plus per-skill `.claude/skills/`); everything else in `blueprint/` reaches existing projects only via a migration entry. N/A if the change touched only `blueprint/process-framework/` (which Push mirrors automatically).

- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-009`, context "Process Improvement".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`process-improvement-tracking.md`](../../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) | Script | Status-only: updates Status and Last Updated columns in Current table<br/>Completion: moves row from Current to Completed, updates summary count<br/>Supersession (PF-IMP-832 (c)): `-NewStatus Superseded -SupersededBy <ID>` moves the row to Section 7 — Rejected with `Rejection Reason = "Superseded by <ID>"`<br/>Annotation (PF-IMP-832 (a)): `-AppendNotes <text>` (idempotent), `-SetRespTask <PF-TSK-NNN>` and `-SetPriority <High\|Medium\|Low>` (PF-IMP-1885 — the only re-prioritization path, since a same-section `-MoveToSection` is refused as a no-op) edit Notes / Resp Task / Priority columns alone or alongside any non-pilot `-NewStatus`; `-AppendNotes` also rides `-MoveToSection` moves (PF-IMP-1393 (c)) and, annotation-only, covers every section — the live ones including Intake and Active Pilots (PF-IMP-1570) plus already-archived Completed / Rejected rows, written to the archive file with their terminal Resolution / Rejection Date left intact (PF-IMP-1719) — `-SetRespTask` / `-SetPriority` stay triaged-sections-only (Intake / Active Pilots / archived rows have no Resp Task / Priority column)<br/>Concept archival (PF-IMP-1688): `-ArchiveConcept <PF-PRO-NNN>` moves a full-rollout extension concept to `proposals/old/` alongside any non-`Resolved` transition (the pilot `Resolved` path discovers its concept from the Active Pilots row instead)<br/>Tool-change logging (PF-IMP-832 (b)): `-LogToolChanges <json>` folds the PF-TSK-009 Step 12 `feedback_db log-change --batch -` invocation into the Completed transition, with the payload validated before the move (PF-IMP-1393 (b)) |

## Next Tasks

<!-- merged from transition-registry entry: Process Improvement -->
### Prerequisites for Transition

- [ ] Process improvement analysis completed
- [ ] Improvement recommendations documented
- [ ] Process changes implemented or planned
- [ ] Impact assessment completed
- [ ] **Framework script verification done**: each script touched was verified per its edit kind's row in the [framework-script verification table](../../guides/support/process-improvement-task-reference-guide.md#framework-script-verification-by-edit-kind). N/A if no scripts were touched. Introduced by the Framework Self-Testing extension (PF-PRO-035).

### Next Task Selection

```
What type of improvement was made?
├─ Workflow changes → Return to development with new process
├─ Documentation structure changes → Structure Change
└─ Tool improvements needed → Tools Review
```

## Related Resources

- [Process Improvement Task Reference](../../guides/support/process-improvement-task-reference-guide.md) - Lookup tables and conventions
- [`process-improvement` craft skill](../../../.claude/skills/process-improvement/SKILL.md) - Gate rationales, entry modes, safeguards, examples, troubleshooting (replaces the retired implementation guide); activated by Step 0
- [Tools Review Task](tools-review-task.md) - Identifies and prioritizes improvements (upstream of this task)
- [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md) - Task-authoring craft (replaces the retired Task Creation Guide)
