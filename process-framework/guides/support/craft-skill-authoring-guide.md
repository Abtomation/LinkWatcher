---
id: PF-GDE-077
type: Process Framework
category: Guide
version: 1.4
created: 2026-07-13
updated: 2026-07-30
description: "Authoring and conversion conventions for framework craft skills - skill-creator deltas (user-invocable false, no packaging, reference-don't-bundle), the task wiring recipe with the renumber-vs-Step-0 decision rule, the retire-the-source-guide checklist (trigger preservation, link repointing), distribution via the Push skills mirror, and the mandatory agent-coupling-registry row per conversion (BL-6 policy)."
related_task: PF-TSK-026,PF-TSK-001
---

# Craft Skill Authoring

## Overview

How to author a framework **craft skill** — the judgment half of a task, packaged as a Claude Code skill under `blueprint/.claude/skills/` — and how to convert an existing procedural-customization guide into one. Codifies the conventions proven by the Craft-as-Skill pilot's three conversions (`ui-design`, `process-improvement`, `imp-triage`; PF-PRO-051, pilot PF-IMP-1373 resolved successful 2026-07-12).

## When to Use

- **Authoring a new craft skill** for a task whose craft (the recurring judgment calls, not the step sequence) warrants its own home — typically alongside [New Task Creation (PF-TSK-001)](../../tasks/support/new-task-creation-process.md) or a [Framework Extension (PF-TSK-026)](../../tasks/support/framework-extension-task.md).
- **Converting a procedural-customization guide** into a craft skill (the BL-5 rollout batches). Only *procedural-customization* guides convert; **reference guides stay agnostic documents** — the craft/reference split is the resolved concept decision, and a guide that is a lookup table rather than a "how to do this well" is not a conversion candidate.

> **🚨 CRITICAL — coupling policy (BL-6 decision, 2026-07-13)**: Claude-coupled craft is accepted framework-wide, on the condition that **every conversion appends its AC-row to the agent-coupling registry (`appdev/agent-coupling-registry.md`) in the same change** (Step 5 below). This registry is the framework's only migration ledger; the rule failed silently twice during the pilot trials, which is why it is now a mandatory authoring step. Revisit trigger: a concrete plan to run the framework under a second agent reopens the projection question before the next conversion batch.

## Prerequisites

Before you begin, ensure you have:

- The public `skill-creator` skill available in the session (the generic authoring engine; this guide holds only the framework-specific deltas).
- For conversions: the source guide, and the task definition that will bind the skill.
- cwd = appdev — craft skills are authored in the canonical tree (`blueprint/.claude/skills/`); conversions never run in a rolled-out project.

## Background

**Division of labor**: the *task* owns process (step sequence, checkpoints, completion checklist, feedback form); the *skill* owns craft (the judgment the steps delegate to). A craft-skill-backed task runs its own spine unchanged and activates the skill at its Check-Recommended-Skills step; a skill the Skill tool does not list degrades gracefully — the agent reads the skill's `SKILL.md` directly, which is the canonical source the Skill tool would load (equivalent, not degraded), and the craft is unavailable for that run only if the skill file itself is absent (PF-IMP-885 convention).

**Why a skill instead of a guide**: single craft home (no dual maintenance), and context economy — the pilot measured ~29–56% leaner craft vs. the retired guides, with only ~tens of words resident until invoked and per-reference loading on demand.

## Step-by-Step Instructions

### 1. Scope the craft

1. Separate the source material into **craft** (judgment, decision rules, worked examples → the skill) and **reference** (lookup tables, schemas, conventions other tasks also consult → stays an agnostic guide). A guide can split: the pilot kept the step-keyed reference companion (PF-GDE-068) agnostic while its implementation-guide sibling became the `process-improvement` skill.
2. **Verify the consumer set before committing to an owning task**: grep the framework for inbound references to the source guide and confirm each proposed owning task actually consumes it — a proposed owning task with zero inbound references signals a re-scope, not a wiring detail (this contradicted the approved conversion plan twice during BL-5). A different question from Step 3's step-reference-density grep, which chooses the wiring *shape* after the home is settled.
3. Identify any **process trigger** the source guide implies — a "when/who updates X" step, distinct from the craft itself. Mark each for absorption into the agnostic task definition at Step 4 (this is the retire-checklist's trigger-preservation check).

**Expected Result:** A craft inventory (what moves into the skill), a reference disposition (what stays agnostic and where), a reference-verified owning-task set, and a trigger list for the task definition.

### 2. Author the skill with skill-creator, applying the framework deltas

Use `skill-creator` as the engine, with these framework-specific deviations:

1. **Skip init/packaging** — author the directory directly under `blueprint/.claude/skills/<skill-name>/`; framework skills are never packaged as `.skill` bundles (distribution is the Push mirror, Step 6).
2. **`user-invocable: false`** in the SKILL.md frontmatter — craft skills activate only from their task's Check-Recommended-Skills step, never as user slash commands.
3. **Reference-don't-bundle** — the skill points at the framework's agnostic scripts (`process-framework/scripts/...`) and never bundles executables; only craft prose is agent-coupled.
4. **Task steps by name, not number** — the skill says "the task's triage-decisions checkpoint", never "Step 8", so task renumbering can't silently break the skill.
5. **Carry the division-of-labor header and scope guard** — open the SKILL.md by naming the owning task and what the skill does *not* own (checkpoints, moves, merit judgments stay with the task), mirroring the three live skills.
6. **Progressive disclosure** — a lean SKILL.md with a reference index; per-topic reference files loaded on demand.
7. **Preserve deep-linked anchors** (conversions) — carry headings that inbound deep links target verbatim into the SKILL.md (or its references), so `#anchor` references keep resolving after Step 4 repoints them.
8. **Generalize project-specific source content** (conversions) — a framework-owned skill ships to every project: rewrite per-project tables, module lists, and project-named examples into agnostic form before they fossilize as false framework facts.
9. **Optional public-skill comparison pass** — after the framework draft is complete (draft first; surveying first anchors the structure on outside conventions), survey public skills (e.g. `anthropics/skills`, SOP-authoring formats) and fold in genuinely additive conventions; record adopted and rejected conventions in the Step 5 AC-row.
10. **`references/edge-cases.md` is a standard skill component, lazy-created (PF-PRO-059)** — the owning task's consult-on-stumble incident record. Never author it as an empty stub: it is created on the first real entry (often the extraction pass that moves per-incident conditionals out of the cores), and the skill's reference index names it once it exists. **Core leanness**: per-incident conditionals, rare-situation cautions, and footnote-shaped exceptions route there, never into the SKILL.md main flow — the SKILL.md keeps the happy path and load-bearing craft. Entries are agent-autonomous per the workspace Standing Orders; a *silently-failing* class gets a detector (two-strikes rule), never an entry.

**Expected Result:** `blueprint/.claude/skills/<skill-name>/SKILL.md` (+ reference files), leaner than the source guide, with no bundled executables.

### 3. Wire the task

1. **Choose the wiring shape by measuring external step-reference density**: run a repo grep for `"<task-id> Step"` (and the task's step numbers in routing policy, sibling tasks, and any step-keyed companion). Weigh **internal numbering hazards** alongside the external grep — dual-mode step branches, suffixed step schemes (7a/7b), and pre-existing numbering collisions all push toward the Step-0 variant.
   - **Default — renumbered Step 1**: insert *Check Recommended Skills* as Preparation Step 1 and renumber. Then batch-verify with a grep sweep of `"Step N"` internal references — renumbering surfaces both your edits and any pre-existing off-by-one (fix those inline and record them).
   - **Step-0 no-renumber variant**: when the grep shows the task's step numbers are externally load-bearing (e.g. PF-TSK-009: cited by the ai-tasks routing policy, Code Review disambiguation, the IMP Triage rubric, and a step-keyed reference companion), insert as **Step 0** and leave all numbering untouched — the pilot's Step-0 wiring avoided ~20 renumber edits plus a framework-wide reference sweep.
2. **Write the step from the canonical wording** — reuse a live wired task rather than improvising: the single-skill form in IMP Triage's *Check Recommended Skills* step, the multi-skill single-step form in Codebase Feature Discovery's Step 0, and the multi-skill extend-an-existing-Step-0 form in Retrospective Documentation Creation's Step 0. All carry the same required elements: the `recommended_skills` config read, what craft the skill owns, the read-`SKILL.md`-directly equivalence fallback, and the absent-file degradation clause.
3. **Bind the skill**: add the `recommended_skills.tasks.<task-slug>` entry in `project-config.json` (or the language-config, when language-scoped) — an object `{ "skill": "<name>", "kind": "craft", "note": "<one line>" }`. In appdev this is a direct edit; for rolled-out projects the binding is a **Mode C pending-migration entry** per project — skill *files* auto-deploy via the Push mirror, the *binding* does not. Seed the blueprint template's `project-config.json` too when the owning task runs in product projects, so new projects get the binding at bootstrap.
4. **Point the task's craft references at the skill**: the task's Context Requirements and Related Resources name the skill as the craft home (see the three wired tasks for the phrasing).
5. **Remove the craft the skill now owns — sweep the whole task body**: a step-wise wiring pass touches only the wired step, so sweep the entire task file for superseded craft content — including concept blocks *outside* the numbered step sequence, which a step-by-step pass never visits, and orphaned copies left beneath a freshly added pointer. Remove them, leaving inline step-point pointers to the skill (the Process Improvement task shows the form). Residue drifts into task-vs-skill contradictions: the post-BL-5 audit found ~150 duplicated lines across 9 tasks, two already contradictory (PF-IMP-1592).
6. **Wire companion documents too**: when the task delegates operative steps to path/variant companion documents (e.g. Code Refactoring's lightweight/standard paths), add the skill reference at each companion's operative step and run the same residue sweep there — wiring the task file alone leaves the skill unreferenced at the step that actually creates the artifact (PF-IMP-1595).

**Expected Result:** Task activates the skill at its Check-Recommended-Skills step; `Build-TaskMetadata.ps1 -Check` green; grep sweep shows no stale `"Step N"` references; task body and companion docs carry no craft the skill now owns.

### 4. Retire the source guide (conversions only)

Run this checklist in the same change:

1. **Trigger preservation**: every process trigger identified at Step 1 is written into the agnostic task definition as a task step — otherwise the trigger becomes skill-coupled with no fallback. (Grounded incident: retiring the UI customization guide silently stranded the Design-Guidelines update trigger; corrected after the fact. PF-IMP-1406.)
2. **Repoint inbound links**: grep the framework for the guide's filename; repoint each reference to the **skill** — the skill is the default target for every inbound reference (human directive, BL-5 rollout 2026-07-13). Only in a split conversion may references that target surviving agnostic reference content point at the companion instead. Sweep beyond plain markdown links: non-markdown carriers (JSON config `description` prose, JSON embedded in task definitions), creation-script success-output hint lines, and hidden directories — default ripgrep skips `blueprint/.claude/`, so pass `--hidden` (or glob it explicitly) or the skills tree is silently excluded. LinkWatcher does not do this for a deletion — repoint first, then delete.
3. **Delete the guide file** and regenerate the documentation map (`Build-DocumentationMap.ps1`, then `-Check`).

**Expected Result:** The craft has exactly one home; no broken inbound references; doc map in sync.

### 5. Register the coupling (mandatory)

Append the skill's row to the **agent-coupling registry** (`appdev/agent-coupling-registry.md`, 🟡 content tier) **in the same change**: surface, location (skill path + retired source guide), what's coupled, and the translation note — `Same as AC-6; referenced scripts agnostic.` (AC-6 holds the canonical translation statement, kept current against the agent landscape in the registry). See rows AC-6–AC-8 for the shape.

**Expected Result:** The registry remains the complete migration ledger — one row per craft home.

### 6. Distribute and verify

1. Skill files reach registered projects automatically via `Push-FrameworkUpdate.ps1`'s per-skill `.claude/skills/` mirror at the next rollout; new projects get them at bootstrap.
2. File the binding migration entries (Step 3.3) for every registered project when the wiring is framework-wide rather than appdev-only.
3. Regenerate + `-Check` the doc map and task metadata; run the framework Pester suite if any script was touched (a pure conversion touches none).

**Expected Result:** Staged for the next rollout; all `-Check` gates green.

## Quality Assurance

### Self-Review Checklist
- [ ] SKILL.md frontmatter has `user-invocable: false`; no `.skill` packaging artifacts
- [ ] No executables bundled — all script mentions point into `process-framework/scripts/`
- [ ] Task steps referenced by name, never by number
- [ ] Wiring shape chosen by the `"<task-id> Step"` grep, and the post-renumber `"Step N"` sweep is clean (or Step-0 variant used)
- [ ] Whole-task-body and companion-doc residue sweep done — no superseded craft blocks remain beside the pointers
- [ ] Relative link depths verified from each file's own directory (`../` depth errors shipped twice during BL-5)
- [ ] Trigger-preservation check done; absorbed triggers live in the task definition
- [ ] Inbound links to the retired guide repointed (including non-markdown carriers and hidden dirs); guide deleted
- [ ] AC-row appended to `appdev/agent-coupling-registry.md` in the same change
- [ ] `Build-DocumentationMap.ps1 -Check` and `Build-TaskMetadata.ps1 -Check` exit 0

## Examples

### Example 1: Renumbered Step 1 wiring (imp-triage)

The `"PF-TSK-089 Step"` grep showed no externally load-bearing step numbers, so *Check Recommended Skills* went in as Preparation Step 1 with a full renumber (task v1.6, 13→14 steps). The post-renumber sweep caught a pre-existing internal off-by-one ("cluster detection in Step 5" pointing at the classification step) — fixed inline and recorded.

### Example 2: Step-0 no-renumber wiring (process-improvement)

The grep showed PF-TSK-009's step numbers cited framework-wide (ai-tasks routing policy, Code Review disambiguation, IMP Triage rubric, the step-keyed PF-GDE-068 companion). The skill activation went in as **Step 0** (task v3.4), avoiding ~20 renumber edits and a framework-wide reference sweep. The Diataxis-split reference companion stayed agnostic; only the implementation-guide craft converted.

## Troubleshooting

### A helper the skill documents refuses part of its documented surface

**Symptom:** A skill reference describes a helper invocation that errors on a specific row/section type the reference does not mention (e.g. a tracker helper that only handles one section's column shape).

**Cause:** Skill references summarize helper contracts; helpers evolve and edge-case scope is easy to understate.

**Solution:** Fix the skill reference in the same session you hit the mismatch (skill content is framework-owned — edit `blueprint/.claude/skills/...` directly), and note the incident in the session's feedback form so the ratings history links it to the helper.

### Closing the pilot that hatched a skill

**Symptom:** Uncertainty about what resolving a craft-skill pilot does to its artifacts.

**Cause:** Two pilot origins with different closure side effects.

**Solution:** Extension-origin pilots (`SourceConcept: PF-PRO-NNN`) resolve via `Update-ProcessImprovement.ps1 -NewStatus Resolved`, which also archives the concept to `proposals/old/`. Improvement-origin pilots resolve through the same path with **no concept-archive side effect** (pilot PF-IMP-884 precedent). In both cases the skill itself stays live unless the resolution explicitly reverts it.

## Related Resources

- The three canonical skills: [`ui-design`](../../../.claude/skills/ui-design/SKILL.md) · [`process-improvement`](../../../.claude/skills/process-improvement/SKILL.md) · [`imp-triage`](../../../.claude/skills/imp-triage/SKILL.md)
- [Craft-as-Skill Architecture concept (PF-PRO-051, archived)](../../../process-framework-central/proposals/old/PRJ-000_craft-as-skill-architecture.md) — origin decisions and the Global Rollout Backlog
- Agent-Coupling Registry — `appdev/agent-coupling-registry.md` (the migration ledger Step 5 appends to; BL-6 decision section)
- [Guide Creation Best Practices](guide-creation-best-practices-guide.md) — for the reference content that stays a guide
- [Framework Rollout task (PF-TSK-088)](../../tasks/support/framework-rollout-task.md) — the Push mirror and Mode C binding migrations
