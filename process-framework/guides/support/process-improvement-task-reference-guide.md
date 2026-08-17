---
id: PF-GDE-068
type: Process Framework
category: Guide
version: 1.22
created: 2026-05-20
updated: 2026-08-04
related_task: PF-TSK-009
description: "Lookup tables and conventions consulted at specific steps of the Process Improvement task: problem-verification notes, evaluation criteria, routing destinations, risk classification, framework-script verification by edit kind, common stale-description sites, TOOL_DOC_ID and constituent-disposition conventions."
---

# Process Improvement Task Reference

## Document set

Three artifacts cover the Process Improvement task:

- **[Task definition](../../tasks/support/process-improvement-task.md)** — the operative process: 17 steps to execute end-to-end
- **This file** — tables and conventions you look up at specific steps: problem-verification notes, evaluation criteria, routing destinations, risk classes, framework-script verification by edit kind, common stale-description sites, TOOL_DOC_ID and constituent-disposition conventions
- **[`process-improvement` craft skill](../../../.claude/skills/process-improvement/SKILL.md)** — worked examples, troubleshooting, and the reasoning behind the gates; activated at the task's Step 0 (Check Recommended Skills). Replaces the retired implementation guide.

Read the task definition end-to-end at session start. Cross to this file at the step that points to it. The skill (when active) supplies the pattern to imitate and the intent behind each gate.

## Overview

This reference holds the lookup-shaped content extracted from the Process Improvement task definition during the PF-IMP-880 Diataxis-pilot split. Each section names the task step that consults it.

---

## Problem-verification notes

> **Consulted at**: Task Step 2 (Verify the problem — absence test first).

- **Template-dedup claims** — a "body restates frontmatter" claim can only be judged at the creation script's `AdditionalMetadataFields` injection: a generated document's frontmatter is assembled at creation time (template `creates_document_*` defaults plus script-injected fields), so template files do not carry the fields in question and the duplication may exist only in generated documents. Read the script's injection before evaluating.
- **Validator-count premises** — when an IMP's premise is a finding count from a validator (LinkWatcher `--validate`, `Validate-StateTracking.ps1`), classify the findings by detector/type before accepting the count: bulk counts routinely mix true positives with detector-specific false-positive classes (a "300 broken links" premise held 3 real breaks, PF-FEE-1615). Evaluate against the classified count, not the headline. For the state-tracking-drift subclass, the [schema-audit guide's Declare/Fix table](schema-audit-procedure-guide.md#the-two-reconciliation-paths) is the reconciliation path.
- **Cross-project-origin IMPs** — when the row originates from another project's session or a cross-project evaluation (origin named in its Source), verify its claims against that project's live tree, not only appdev's artifacts: the decisive check often requires reading the origin project.
- **Data/analytics IMPs** — trace the affected field to its write site (DB column, generated file) and quantify the defect there before evaluating value.
- **Runtime-behavior claims** — when the premise is that another tool misbehaves (a script errors, a validator misses, a call fails), reproduce it before accepting **or rejecting** the row: a failed reproduction is inconclusive until you can explain what the reporter saw.
- **The absence test in its common shapes** — the canonical catalog of shape readings (the Step 2 rule applied); the task step and the craft skill point here rather than restating them, so a new shape lands once, here. *Data field or output* — grep for readers, not writers; a write-only field is a removal candidate, not a reformat candidate (a Session-Duration reformat was rescoped to removal once the field proved write-only, PF-FEE-1618). *Guidance passage* (a step, check, note, or example) — delete it hypothetically and find the decision or action that breaks; a passage whose deletion breaks nothing is a removal candidate, not a rewording candidate (its own text claiming an audience is not evidence, PF-IMP-1695), and one whose obligation already lives at a canonical home elsewhere is duplication. *Purely additive proposal* — nothing exists to delete, so absence-test the neighbouring existing target whose function the addition would serve, then confirm the addition actually serves it; an addition whose neighbour itself breaks nothing is that neighbour's removal case, not a new clause. *Partially-inert target* — when the test splits one target into a half nothing consumes and a half with a live consumer, the inert half's removal is the finding, not a rewrite of the whole; re-mechanizing the inert half is the symptom fix, and the live half's legitimacy is exactly what makes re-mechanizing feel justified (a ratings drill-down half was genuinely useful while its sweep half had never fired, PF-IMP-1864).

---

## Evaluation criteria

> **Consulted at**: Task Step 3 (Evaluate the IMP).

First validity, then implementation merit:

| Criterion | Question | Rating |
|-----------|----------|--------|
| **Recurring Value** | Will this benefit multiple future sessions, not just a one-off scenario? For a capability-completion IMP ("finish deferred/parked X"), confirm the capability has a consumer — a task, guide, or workflow that will actually invoke it; no consumer weighs decisively toward park/document over finish. | High / Medium / Low |
| **Framework Fit** | Does this align with framework principles and existing patterns? (If the fix requires creating new artifacts rather than modifying existing tooling, route to PF-TSK-026 / PF-TSK-001 instead — except a single new script mirroring an existing sibling pattern, which stays in PF-TSK-009; only multi-component capabilities route away.) | Good / Marginal / Poor |
| **Maintainability** | Will the change be easy to maintain, or does it add complexity / fragility? | Improves / Neutral / Degrades |
| **Complexity-to-Benefit** | Is the implementation effort proportional to the expected benefit? | Favorable / Balanced / Unfavorable |
| **Minimum Viability** | Could a simpler change (warning-only, doc-only, smaller scope, or *no change at all*) solve the same problem? If yes, prefer the simpler change unless concrete evidence shows it's insufficient. For a task/guide content-addition, apply the *no-change* option literally — if existing wording already carries the guidance, rate Yes. | Yes / No / Not Explored |
| **Root-Cause Targeting** | Does the proposed fix target the underlying defect, or route around it via a flag / option / opt-out / escape hatch? If the latter, what is the underlying defect, and is fixing it in scope? | Root-cause / Symptom-only / N/A |
| **Feasibility** | Can the proposed fix be implemented on this platform, or does it require behavior the runtime does not permit (e.g. an in-script check for a parameter-binding failure PowerShell raises before any script line runs)? Near-fit distinction: Root-Cause Targeting judges what the fix *targets*; Feasibility judges whether the fix *can exist*. For script-behavior IMPs, check the proposed mechanism against the [Script Development Quick Reference](script-development-quick-reference.md#quick-fixes) footguns. An Infeasible rating rejects or reshapes the proposal regardless of other ratings. | Feasible / Infeasible / N/A |
| **Data-Driven Validation** | Is there data anywhere in the project (feedback DB, review summaries, IMP history, code metrics, git history, test results, etc.) that could validate or invalidate this IMP's premise? If yes, has it been analyzed? | Analyzed / No Data Available |
| **Prevention** | For a defect fix: did an upstream artifact gap — an authoring guide, template, creation script, validator, or test pattern — let this defect arise or persist undetected? A named gap must name a concrete artifact and a concrete change ("be more careful" is not a gap). "None found" is the expected default. | Named gap / None found / N/A |

### Gates

- **Conciseness rule** — When all criteria are favorable (High / Good / Improves / Favorable / Yes-or-No / Root-cause-or-N/A / Feasible-or-N/A / Analyzed-or-N/A / None-found-or-N/A), present a one-line summary at Step 6 (e.g., "Evaluation: all favorable; proceeding with Approach X"). Present the full table only when one or more criteria rate poorly or trigger a gate below.
- **Multiple-poor-rating rule** — If multiple criteria rate poorly (Low / Poor / Degrades / Unfavorable), recommend rejection with rationale.
- **Minimum-viability gate** — If **Minimum Viability** is "Yes" or "Not Explored", the Step 6 checkpoint must explicitly compare the proposed approach against the simpler alternative — present both options to the human partner before committing.
- **Root-cause-vs-symptom gate** — If **Root-Cause Targeting** is "Symptom-only", the Step 6 checkpoint must articulate the underlying defect explicitly and present both the symptom-fix (as the IMP describes) and the root-cause-fix as options for human review. The symptom-fix is sometimes the correct answer (root cause out of scope, or the symptom *is* the actual problem) — but the *distinction* must be surfaced before commitment.
- **Prevention gate** — When **Prevention** names a gap, present it at the Step 6 checkpoint; on human approval, file it as a separate prevention IMP via the spillover mechanism (Step 10) after a [`Find-Improvement.ps1`](../../scripts/Find-Improvement.ps1) dedupe — the filed IMP must later survive this evaluation on its own merits. Re-answer the criterion at the Step 13 decision review when execution changed the picture. "None found" stays silent — no checkpoint mention, and never fabricate a gap to satisfy the step.
- **Data-driven validation gate** — When **Data-Driven Validation** is "Analyzed", do not proceed to implementation until the analysis is complete. This may require a dedicated multi-session data collection effort (create a temp state file via Step 7). Data sources are unrestricted — feedback DB ratings, review summaries, IMP history, code metrics, git history, test results, or anything else relevant. If the data contradicts the IMP's premise, reject the IMP regardless of intuitive appeal. See [Framework Evaluation](../../tasks/support/framework-evaluation.md) Step 8 for methodology and the IMP-525 precedent. For validator-noise IMPs, see the [schema-audit guide's Declare/Fix table](schema-audit-procedure-guide.md#the-two-reconciliation-paths) — declaring a legitimate-but-undeclared field also removes the recurring false-drift warning (the root-cause framing).

> Rationale for these gates — minimum-viability, root-cause-vs-symptom, prevention, data-driven validation — lives in the [`process-improvement` craft skill](../../../.claude/skills/process-improvement/SKILL.md) (activated at the task's Step 0).

---

## Routing

> **Consulted at**: Task Step 3 (re-route ill-fitting IMPs), Step 6 (reclassify out-of-framework work), Step 10 (file spillover IMPs).

| Destination | When | Mechanism |
|---|---|---|
| **Section 3 — Extensions** (PF-TSK-026) | New framework capability (new task / new template+script+guide / new workflow) | `Update-ProcessImprovement.ps1 -MoveToSection Extensions -RoutedBy "PF-TSK-009" -Reason "<one-line>"` |
| **Section 4 — Structural Changes** (PF-TSK-014) | Moving files, renaming dirs, reorganizing sections | `Update-ProcessImprovement.ps1 -MoveToSection StructuralChanges -RoutedBy "PF-TSK-009" -Reason "<one-line>"` |
| **Bug Tracking** | Product bug (`src/` defect) misfiled as IMP | [`New-BugReport.ps1`](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) |
| **Feature Request Tracking** | Product feature request misfiled as IMP | [`New-FeatureRequest.ps1`](../../scripts/file-creation/01-planning/New-FeatureRequest.ps1) |
| **Technical Debt Tracking** | Technical / test-infrastructure debt | [`Update-TechDebt.ps1 -Add`](../../scripts/update/Update-TechDebt.ps1) |
| **Scope-spillover IMP (spillover lane, PF-PRO-059)** | Mid-execution: planned change overflows into another task's work (PF-TSK-001 / PF-TSK-014 / PF-TSK-026), or across a verification boundary (a remainder this session cannot verify). Complete the in-scope parts; file the remainder **directly into its owning section** — never back through the feedback pipeline — with Notes marked `[SPILLOVER PF-IMP-nnnn]` naming the originating IMP. A spillover chain deeper than one is a Standing Orders tripwire (escalate). | [`New-ProcessImprovement.ps1`](../../scripts/file-creation/support/New-ProcessImprovement.ps1) (pre-flight a long `-Description`: length must be 10–500 — measure before composing the call; over-cap detail moves to `-Notes`, uncapped) then [`Update-ProcessImprovement.ps1 -MoveToSection <owning section>`](../../scripts/update/Update-ProcessImprovement.ps1) |

Section moves auto-prepend `[REROUTED YYYY-MM-DD by PF-TSK-009: <reason>]` to Notes. Reclassifications record the new artifact's ID in the IMP rejection note. After re-routing, surface to the human partner — the IMP is no longer this task's responsibility.

**Domain heuristic** (Step 6 reclassification): classify by **what the corrective fix changes**, not the symptom's directory — see the [Issue Classification and Routing Guide](../framework/issue-classification-and-routing-guide.md). In short: a fix to framework-provided material (under `process-framework/`, or the template-imposed structure of a project artifact) is an IMP; a fix to product material (`src/`, or product doc/content) is a bug / feature / tech-debt per that guide.

---

## Inline-authorization recipe

> **Consulted at**: Task Step 10 (a mid-session IMP the human authorized for inline handling).

A new IMP filed mid-session — a scope-spillover remainder, or a defect surfaced by the current work — that the human authorizes for inline handling needs its triage decision recorded, but not a separate [IMP Triage (PF-TSK-089)](../../tasks/support/imp-triage-task.md) session:

```powershell
Update-ProcessImprovement.ps1 -MoveToSection Improvements -Priority <High|Medium|Low> -AppendNotes "<authorization one-line>"
```

The `-AppendNotes` one-line is the authorization record — name who authorized it and that it was handled inline, so a later reader sees why the row skipped triage.

---

## Risk classification

> **Consulted at**: Task Step 10 (Execute changes by risk class).

| Class | Definition |
|---|---|
| **Low-risk** | Typo, wording, link fix, additive callout, single-file edit with no semantic change, formatting / style. A **many-file but mechanical** edit with no semantic change (e.g. a fleet-wide wording/snippet conversion) also classifies here — change nature decides, not file count; Step 10's grep-based completeness check is the matching safeguard |
| **Medium-risk** | Behavior changes within one task / script / template, non-trivial logic, multi-file but bounded |
| **High-risk** | Structural change, cross-task or cross-script impact, change to a high-frequency workflow, anything affecting human-facing UX in repeated tasks — **except** a cross-script change that is N mechanically identical repetitions of one reviewed edit, which executes as **Medium**: the per-change loop exists for *distinct* changes, the risk sits in the one reviewed edit, and Step 10's grep-based completeness check covers the fan-out |

Execution mechanics per class (batch vs. per-change loop, checkpoint frequency, stating the applied classification at Step 13) are owned by task Step 10. One nuance beyond it: a High-risk change consisting of a **single atomic edit** (e.g. one shared-writer change whose blast radius is fleet-wide) collapses the per-change loop to one present → approve → implement → confirm pass — do not manufacture artificial sub-checkpoints or downgrade the class to avoid them.

---

## Framework-script verification (by edit kind)

> **Consulted at**: Task Step 10 (Execute changes — framework-script edits). Risk class (above) decides checkpoint frequency; this table decides the verification method. Match the edit to its kind — and re-match here when problem verification or execution invalidates a prescription pre-filed in the IMP's row (an intended delta surfacing mid-"behavior-preserving" work is the recurring case; the shared-helper row owns that boundary):

| Edit kind | Verification |
|---|---|
| **PowerShell behavior change** (`.ps1`/`.psm1`) | Add or update the script's Pester unit test alongside the edit and run it — full obligations (test location, fixture realism, iteration loop, sandboxing constraint) are listed under [Framework-script edit obligations](#framework-script-edit-obligations) below |
| **Creation-script behavior change** (a document-creating `New-*.ps1`) | The creation-suite convention: dot-source-guard unit tests on extracted pure helpers, plus subprocess `-WhatIf` reachability with side-effect counting. Real-creation content assertions are fixture-blocked across the whole creation suite (appdev's BD-001) — do not plan content-assertion fixtures that do not exist; a Step 6 verification plan has been walked back on exactly that promise (PF-IMP-1749) |
| **Comment/docstring-only edit** (no behavior change, e.g. a `.SYNOPSIS`/`.DESCRIPTION` or Python-docstring fix) | Per touched script, prove the help still parses and renders: an AST parse with zero errors (`[System.Management.Automation.Language.Parser]::ParseFile`) plus a `Get-Help <path> -Full` render confirming the edited fields appear intact — this catches a malformed help block (e.g. merged `.PARAMETER` entries) that a green test suite does not. Author no new test, and skip the suite run: for an edit that cannot change behavior it is neither necessary nor sufficient (PF-IMP-1749) |
| **Python script** (no Pester harness, e.g. `feedback_db.py`, `extract_ratings.py`) | Recorded before/after contrast run — capture the relevant output before and after the edit and confirm the intended delta. When the contrast target is shared live data written by parallel sessions (e.g. `ratings.db`), run both captures against a scratch copy of the data (`feedback_db.py --db <copy>`) so a concurrent write cannot contaminate the contrast |
| **Template edit** (verified through its consuming creation script) | Create-verify-delete: run the creation script against the edited template, verify the created instance carries the intended change, delete the instance. The consumed ID stays an accepted gap per the registry's `id_gaps_policy` — no counter rollback, no backfill (PF-IMP-1749) |
| **Behavior-preserving mass conversion** (the same refactor across many scripts, e.g. converting a fleet to a shared helper) | Per-script Pester asserts *expected*, not *unchanged*, behavior — prove equivalence with the [golden-file harness](script-development-quick-reference.md#behavior-preserving-refactor-verification-golden-file-equivalence-harness) |
| **Shared-helper behavior change** (one edit whose output *intentionally* changes for consumers, e.g. a writer-level fix that alters output only on inputs that were already broken) | Whole-tree byte-identity misroutes here — it reports the intended delta as a diff. Verify with the helper's own Pester tests plus a full consumer-category regression (`Run-Tests.ps1 -Category <area>`); the golden-file harness's ["when NOT to use" guidance](script-development-quick-reference.md#behavior-preserving-refactor-verification-golden-file-equivalence-harness) covers the boundary |
| **Soak-enrolled script** (check with `Get-SoakStatus`) | The edit resets the soak counter in [script-soak-tracking.md](../../../process-framework-central/state-tracking/permanent/script-soak-tracking.md) against the new hash — a **self-armored** script handles that automatically on its next real invocation; an **agent-maintained** script needs the [manual re-sync sequence](script-development-quick-reference.md#soak-re-sync-after-editing-a-soak-enrolled-script). `Get-SoakStatus -ScriptId <id>` reports which, in its `Arming` value — derived from the script's own AST, not from any annotation (PF-IMP-1880). Non-enrolled scripts validate via the matching row above |
| **Brand-new script joining an existing family** (e.g. a new pre-commit guard beside existing ones) | Read the convention off the siblings rather than re-deriving it: Pester suite beside theirs (appdev `test/automated/unit/framework/<area>/`), a test-tracking row is expected, and soak-enrollment follows family precedent — check a sibling with `Get-SoakStatus` (the pre-commit guards are deliberately unenrolled; interactive creation/update scripts enroll) (PF-IMP-1851) |

### Framework-script edit obligations

The full obligations the verification rows above point to, for any framework-script edit regardless of risk class:

- **Pester obligation** — add or update the script's Pester unit test (`<ScriptName>.Tests.ps1` under `appdev/test/automated/unit/framework/<area>/`) inline with the edit and run the affected suites via `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1` at the cadence the **Iteration** bullet below prescribes — the test pass is the validation evidence.
- **Fixture realism** — build the fixture rows against a **real rolled-out project's** state-file format, not appdev's blueprint scaffold — blueprint state files are empty or use simplified bare-ID rows, while real projects use linked `[id](path)` cells, so a fixture modeled on the blueprint can pass while the production-row code path matches nothing. Use a **synthetic** fixture with known rows in every section the change touches, never the live file: its sections may be legitimately empty, letting a probe match a different section and pass while proving nothing (PF-IMP-1608).
- **Iteration** — derive the edited script's dependent suites (`grep -rl '<ScriptName>.ps1' test/automated/`) and run them in one pass: `-TestFile` takes a comma-separated list and resolves bare filenames (PF-IMP-1542), so this costs seconds against a whole `-Category`. The same-named `<ScriptName>.Tests.ps1` is rarely the whole set, and dependents routinely span categories (PF-IMP-1856) — so close with the full `-Category` run as the regression check, **plus any dependent suite outside it**, which that pass does not reach. That closing pass is **per session per category, not per edit**: in a same-session IMP chain touching one category, each edit's evidence is its grep-derived `-TestFile` pass, and a single `-Category` run after the chain's last edit in that category covers the union (PF-IMP-1710). A closing-pass failure resolves in-session before finalization — even for rows already completed — attributed by re-running each chained edit's dependent list. Schedule that category pass to overlap none of the session's own writes to the central tracking files — suites asserting `-WhatIf` side-effect freedom on those files fail spuriously when a concurrent write lands mid-run, and the failure reads as a regression in the change under test; re-run the failing suite in isolation before treating it as one (PF-IMP-1845).
- **Synthetic harnesses** — happy / error / defect-specific cases against real state files remain a complementary technique for ad-hoc validation when the script's failure mode isn't unit-testable; record pre-fix and post-fix counts in IMP completion notes when used.
- **Sandboxing constraint** — creation scripts resolve their project root from `$PSScriptRoot` (script location), not the working directory — changing cwd cannot redirect a run into a sandbox copy; sandbox via the [golden-file framework-copy harness](script-development-quick-reference.md#behavior-preserving-refactor-verification-golden-file-equivalence-harness) or exercise the emission path directly.
- **Launcher scripts** — for process-spawning scripts where a plain unit test is impossible, extract pure helpers and add a dot-source guard (`if ($MyInvocation.InvocationName -eq '.') { return }`) so Pester can dot-source the functions without side effects; cover live startup via the existing E2E smoke test.
- **Follow-up routing** — if the edit affects a user-facing framework workflow (new tracked workflow row or substantively new behavior on an existing one), file a follow-up via [E2E Acceptance Test Case Creation (PF-TSK-069)](../../tasks/03-testing/e2e-acceptance-test-case-creation-task.md); if it changes performance characteristics on a measured surface, route to [Performance Test Creation (PF-TSK-084)](../../tasks/03-testing/performance-test-creation-task.md).

---

## Common stale-description sites

> **Consulted at**: Task Step 11 (Linked-document verification sweep).

For each file modified in this improvement, grep for its path / filename across the project and read the surrounding paragraph — descriptions, parameter examples, and usage guidance may reference the old behavior and need updating even when the link itself is correct. Sweep these first (non-exhaustive):

- **Script header blocks** — PowerShell `.SYNOPSIS` / `.DESCRIPTION` / `.PARAMETER` / `.EXAMPLE`; Python module docstrings and `--help` / argparse text
- **Documentation maps (PF / PD / TE)** — all generated, DO-NOT-EDIT (PF-PRO-037 / PF-PRO-050): each map's one-line descriptions are rendered from each artifact's own `.SYNOPSIS` / `description:` frontmatter / `metadata.description`. Don't hand-edit a map; fix the description at the **source** and rerun the generator for that tree — `Build-DocumentationMap.ps1` (PF) / `… -Tree PD` (`doc/`) / `… -Tree TE` (`test/`), each with `-Check` to verify in sync
- **Task-metadata projections (`Build-TaskMetadata.ps1`)** — `ai-tasks.md` tables, `process-framework-task-registry.md`, `task-transition-registry.md`, and `tasks/README.md` are generated from task files; a task-file edit drifts them. Fix the source task file, then rerun `Build-TaskMetadata.ps1` (`-Check` to verify in sync).
- **README.md files** — `templates/README.md`, directory READMEs, and root README script tables
- **Task definitions** referencing the modified artifact — embedded example invocations and parameter lists
- **Hand-written invocation / Preparation notes in task bodies** — when a paired change adds or removes a status gate, the frontmatter (`trigger_status`) and code get updated while the prose note lags, contradicting them in the same file
- **Design-chain gate order (DB → API → UI → TDD) re-encoded in prose** — transition trees and task prose restate the order and drift independently of its canonical encoding in `AssessmentParsing.psm1`

---

## TOOL_DOC_ID convention

> **Consulted at**: Task Step 12 (Log tool change in feedback database).

The `<TOOL_DOC_ID>` is the **portable framework ID of the `blueprint/` artifact being rated** — its filename only when that artifact carries no ID (verify with `feedback_db.py list-tools --filter <substring>`). The extractor and both DB write paths normalize to this form automatically (PF-IMP-1691), so a heading that names the artifact by *either* its ID or its filename stores the same key; the rule below is what to write when authoring a heading or a `log-change`.

- **Artifact carries a portable framework ID** (declares `id: PF-XXX-NNN` in frontmatter, from a pool in the rolled-out `PF-id-registry.json` — `PF-TSK PF-GDE PF-TEM PF-INF PF-VIS PF-DOC PF-MAI PF-MTH PF-FST`) → use that ID: `PF-TSK-009` (task), `PF-GDE-068` (guide), `PF-TEM-033` (template), `PF-FST-003` (framework-shipped state tracker). This is the common case — tasks, guides, templates, infrastructure docs and shipped trackers all qualify.
- **Artifact carries no ID** (scripts, craft skills, companion path files like `code-refactoring-lightweight-path.md`, `README.md`) → use the filename: `New-FeedbackForm.ps1`, `process-improvement/SKILL.md`.
- **Non-unique basenames** (ID-less artifacts only) → qualify with the shortest trailing path that disambiguates. Craft-skill files use the skill-relative path (`imp-triage/SKILL.md`, `process-improvement/references/examples-and-troubleshooting.md` — every skill's entry file shares the name `SKILL.md`); other shared basenames use the immediate parent directory (`unit/README.md`, `doc/README.md`). A unique basename stays bare.

**Two things are never a tool_doc_id** (both are corollaries of "rate the `blueprint/` artifact"):

- **A project-local artifact instance** — a generated `PD-REF-166` refactoring plan, an `ART-REV-003` review summary, a `PF-STA-043` state file. These are project-specific; a defect in one is a *bug or tech debt*, not a Process Improvement, so the rated tool is the `blueprint/` **template or script that generated it**, not the instance. Its ID (`PD-*`, `TE-*`, `PF-STA`/`PF-TMP`) is project-local and not globally unique, so it can never key the cross-project DB.
- **A non-portable prefix generally** — the resolver refuses any `XX-YYY-NNN` outside the portable pools and falls back to the artifact's name.

> **Note — 20 templates are legitimately filename-keyed.** Their `id:` frontmatter holds the *generated document's* placeholder (`[TE-TAR-XXX]`, `[DOCUMENT_ID]`) rather than their own PF-TEM ID, so no ID is discoverable and the filename is the canonical key. (Phase 3b of PF-IMP-1691 gives them their own IDs; until then, filename is correct for them.)

Registered the same artifact under two ids by mistake? Repair with `feedback_db.py merge-tool-id --from <wrong-id> --to <canonical-id>` (`--dry-run` to preview) — it re-attributes all rating and change rows. A retired artifact keeps the ID it had (the record outlives the file); historical keys and instance→template mappings live in the DB's `tool_aliases` table, which the resolver consults first.

**⚠️ Unknown tool_doc_id?** The script blocks unknown IDs to prevent silent typos. Before logging, verify the canonical ID:

```bash
python process-framework/scripts/feedback_db.py list-tools --filter <substring>
```

If the tool is genuinely new (first-time registration), add `--new-tool` to acknowledge. For `log-change --batch` (or `Update-ProcessImprovement.ps1 -LogToolChanges`) mixed batches with both known tools and first-time registrations, prefer per-entry `"new_tool": true` in the JSON over the global `--new-tool` flag — it preserves typo detection on the other entries (PF-IMP-866).

---

## Constituent-disposition convention (umbrella IMPs)

> **Consulted at**: Task Step 14 (Update Process Improvement Tracking) — when completing a consolidation umbrella. Read by IMP Triage's reconciliation check and Tools Review's dedupe.

A consolidation umbrella's constituents archive as `Superseded by <umbrella-ID>` the moment the umbrella is created — a pointer that says nothing about how each constituent actually fared. The umbrella's completing `-ValidationNotes` is the one place the real outcomes are known, so encode them there, one marker per constituent:

- `[CONSTITUENT PF-IMP-NNNN: shipped]`
- `[CONSTITUENT PF-IMP-NNNN: dropped — do not re-file: <reason>]`
- `[CONSTITUENT PF-IMP-NNNN: carved out → <ID>]`

The bracketed form is kin to `[DEAD PREMISE]` / `[RECURRENCE of PF-IMP-NNN]` and keeps each disposition greppable by constituent ID (`Find-Improvement.ps1 -Keyword PF-IMP-NNNN`). Free prose around the markers (what shipped, why a constituent was dropped) stays as useful as ever — the markers are the machine-findable spine, not a replacement for the narrative.

---

## Bash `-ValidationNotes` backtick gotcha

> **Consulted at**: Task Step 14 (Update Process Improvement Tracking).

If invoking `Update-ProcessImprovement.ps1` from bash and `-ValidationNotes` contains backtick code spans (e.g., `` `[string]$Param` ``), use **single quotes** around the value — bash command substitution silently truncates backtick segments inside double-quoted strings before pwsh sees them.

---

## Related resources

- [Process Improvement Task Definition](../../tasks/support/process-improvement-task.md) — the canonical process
- [`process-improvement` craft skill](../../../.claude/skills/process-improvement/SKILL.md) — examples, troubleshooting, gate rationales (replaces the retired implementation guide)
- [Update-ProcessImprovement.ps1](../../scripts/update/Update-ProcessImprovement.ps1) — driver script for all IMP lifecycle operations
