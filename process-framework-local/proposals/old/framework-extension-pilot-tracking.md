---
id: PF-PRO-030
type: Document
category: General
version: 1.0
created: 2026-04-29
updated: 2026-04-29
extension_name: Framework Extension Pilot Tracking
extension_scope: Modifies framework-extension-task.md to add Phase 1 pilot decision and defers Phase 5 archive until pilot completion; adds Active Pilots section to process-improvement-tracking.md; retroactively registers the in-flight script-self-verification soak pilot
extension_description: Adds a pilot-vs-full-rollout decision step to the Framework Extension Task and an Active Pilots tracking section in process-improvement-tracking.md so multi-session pilots remain visible after concept/temp-state archival
related_imp: PF-IMP-686
related_imp_secondary: PF-IMP-685
---

# Framework Extension Pilot Tracking — Framework Extension Concept

## Document Metadata
| Metadata | Value |
|----------|-------|
| Document Type | Framework Extension Concept |
| Created Date | 2026-04-29 |
| Status | Awaiting Human Review |
| Extension Name | Framework Extension Pilot Tracking |
| Extension Type | Modification |
| Author | AI Agent & Human Partner |
| Origin | [PF-IMP-686](../../state-tracking/permanent/process-improvement-tracking.md) (with [PF-IMP-685](../../state-tracking/permanent/process-improvement-tracking.md) as the immediate concrete instance) |

---

## 🎯 Purpose & Context

### Extension Overview

Some Framework Extensions introduce behavior whose failure modes are unknown at design time. Rolling such behavior out across the entire framework in one step is high-risk: the cost of revert is high, blast radius is wide, and discipline failures only surface late. A pilot — adoption in a small set of representative artifacts before broader rollout — is the natural mitigation, and the existing [Script Self-Verification extension](script-self-verification.md) already used one (`New-IntegrationNarrative.ps1` and `New-Handbook.ps1` armored before any broader adoption decision).

The framework currently has **no first-class place to record that a pilot is in flight**. The script-self-verification pilot's broader-rollout decision was recorded as a "Key Decision" in the temp state file, archived alongside the temp state at Phase 5 closeout, and then forgotten until [PF-IMP-685](../../state-tracking/permanent/process-improvement-tracking.md) was filed during a routine Process Improvement session noticing the soak counters had stalled at 4-5 on three scripts. The decision wasn't lost because the framework lacks a "pilot framework"; it was lost because there is no surface that survives temp-state archival to keep it visible.

This extension closes that specific gap with four modifications:

1. **A pilot vs. full-rollout decision step** added to [Framework Extension Task](../../../process-framework/tasks/support/framework-extension-task.md) Phase 1, evaluated alongside the existing impact analysis (Step 4) and presented at the Step 5 checkpoint. The agent and human partner explicitly choose: roll the new behavior out broadly, or pilot it in a representative subset first.
2. **An "Active Pilots" section** in [process-improvement-tracking.md](../../state-tracking/permanent/process-improvement-tracking.md) — an existing, actively-monitored surface. Pilot rows consume IDs from the same `PF-IMP-NNN` pool as the Current Improvement Opportunities table; a pilot is "an IMP with a multi-stage lifecycle" rather than a separate kind of object.
3. **A Phase 5 archive deferral rule for the concept document only**: when a pilot was chosen at Step 5, Step 21 (concept archive) is conditional on pilot status — concept stays in `proposals/` until the pilot row flips to `Resolved`. The temp state file (Step 20) archives normally, since the implementation work is complete; only the concept (which is the spec for what's being scaled) needs to live alongside the pilot.
4. **Automation extensions** to [New-ProcessImprovement.ps1](../../../process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1) (add pilot rows to the new section using the same PF-IMP ID pool) and [Update-ProcessImprovement.ps1](../../../process-framework/scripts/update/Update-ProcessImprovement.ps1) (manage pilot status transitions Active → Resolved by IMP ID, and trigger concept-doc archive on resolution).

### Key Distinction from Existing Framework Components

| Existing Component | Purpose | Scope |
|-------------------|---------|-------|
| Process Improvement Task — Active Improvement table | Tracks individual IMP items through prioritization → implementation → completion | Per-IMP granularity; rows close when the IMP is implemented |
| Framework Extension Task — Phase 5 archive | Moves concept + temp state to `.` at task completion | Discrete, terminal — no signal survives once archived |
| Temp state Notes/Decisions section | Records design rationale and deferred decisions during multi-session work | Local to the extension; invisible after archive |
| Tools Review periodic feedback aggregation | Surfaces patterns across forms (e.g., a stalled soak counter) | Reactive — depends on someone noticing during periodic review |
| **Framework Extension Pilot Tracking** *(this extension)* | **Persistent visibility of in-flight pilots between Phase 4 adoption and final rollout/rollback decision** | **Per-pilot row in an existing tracked surface; survives Phase 5 archive deferral; flips to Resolved when rollout/rollback completes** |

## 🔍 When to Use This Extension

This framework extension changes the Framework Extension Task itself. The pilot mechanism it introduces is used when:

- **A new framework capability has unknown failure modes** — e.g., a new helper, hook, or assertion pattern that no existing script has exercised in production. The script-self-verification soak system is the canonical example.
- **Broad rollout would create disproportionate revert cost** — armoring 100+ scripts with a new pattern is expensive both to do and to undo if the pattern proves wrong.
- **A representative subset can validate the design** — typically 1-3 adopter artifacts that exercise the new behavior in real conditions while keeping rollback to one or two reverts.

It is **not used** when:

- The change is mechanical or fully understood (most modifications fall here — schema-aligned table additions, doc updates, parameter additions to existing scripts).
- The change is intrinsically lightweight-path (single session, modification-only, no untested behavior).

### Example Use Cases

- **Script Self-Verification (existing pilot, retroactively registered)**: armored 2 scripts (`New-IntegrationNarrative.ps1`, `New-Handbook.ps1`) before deciding broader rollout. Decision trigger: PF-IMP-685.
- **Hypothetical future "Idempotent Update Helper" extension**: pilot in 2 update scripts before adopting in all ~15. Decision trigger: filed IMP after counters reach 0.
- **Hypothetical future "Pre-commit Check Hook" extension**: pilot one hook category (e.g., line-length) before activating five more. Decision trigger: 30-day stability window.

## 🔎 Existing Project Precedents

| Precedent | Where It Lives | What It Does | How It Relates to This Extension |
|-----------|---------------|--------------|----------------------------------|
| `script-soak-tracking.md` Registered Scripts table | [process-framework/state-tracking/permanent/script-soak-tracking.md](../../../process-framework/state-tracking/permanent/script-soak-tracking.md) | Tracks per-script soak counter and content hash for individual armored scripts | **Operates one level below**: tracks per-script soak progress within an in-flight pilot, but says nothing about the pilot's success criteria or decision trigger. The pilot row in this extension references the soak rows as adopters. |
| Process Improvement Tracking — Current Improvement Opportunities table | [process-improvement-tracking.md](../../state-tracking/permanent/process-improvement-tracking.md) | Tracks IMPs through prioritization → implementation → completion | **Reuses the surface**: pilots live in a sibling section (Active Pilots) of the same file. The same operator already reads this file weekly; pilots benefit from the same attention. |
| Status Legend / Task Routing pattern | [process-improvement-tracking.md](../../state-tracking/permanent/process-improvement-tracking.md) lines 14-34 | Documents allowed status values and routing rules for IMP types | **Reuses the pattern**: Active Pilots section gets its own Status Legend with three values (`Active` / `Awaiting Decision` / `Resolved`). |
| Temp state file "Key Decisions" + "Notes/Decisions" sections | E.g. [old/temp-framework-extension-script-self-verification.md](../../state-tracking/temporary/old/temp-framework-extension-script-self-verification.md) lines 320-334 | Captures deferred-decision rationale during multi-session work | **The gap this extension closes**: deferred decisions in this section disappear at Phase 5 archive. The Active Pilots section makes them outlive the archive. |
| `update-temporary-state` workflow in PF-TSK-026 Phase 4 | [framework-extension-task.md](../../../process-framework/tasks/support/framework-extension-task.md) Step 14 | Tracks per-session implementation progress | **Continues to apply**: the temp state file still exists during pilot phase. Archive deferral merely delays its move to `old/`. |

**Key takeaways**: pilots fit naturally on top of existing surfaces. `script-soak-tracking.md` already tracks the per-script mechanism; `process-improvement-tracking.md` already gets weekly operator attention. No new file or tool is needed — the gap is purely about *placing* a pilot row where it survives temp-state archival.

## 🔌 Interfaces to Existing Framework

### Task Interfaces

| Existing Task | Interface Type | Description |
|--------------|----------------|-------------|
| [Framework Extension Task](../../../process-framework/tasks/support/framework-extension-task.md) | **Modified by extension** | Phase 1 gains a pilot-vs-rollout decision step (presented at Step 5 checkpoint). Phase 4 finalization gains a pilot-row append sub-bullet. Phase 5 Step 21 (concept archive) becomes conditional on pilot status; Step 20 (temp state archive) is unchanged. Task Completion Checklist gains a pilot-row-status assertion. |
| [Process Improvement Task](../../../process-framework/tasks/support/process-improvement-task.md) | Downstream consumer | When a pilot review IMP fires (e.g., PF-IMP-685), Process Improvement processes it; on resolution, the operator updates the Active Pilots row to `Resolved` via [Update-ProcessImprovement.ps1](../../../process-framework/scripts/update/Update-ProcessImprovement.ps1), which triggers concept-doc archive. No task-definition change required. |
| [Task Transition Registry](../../../process-framework/infrastructure/task-transition-registry.md) | Updated by extension | The "FROM Framework Extension Task" section gains a pilot path describing conditional Phase 5 archive and the eventual rollout-decision session via Process Improvement. ~10 lines added. |

### State File Interfaces

| State File | Read / Write / Both | What the Extension Uses or Updates |
|-----------|---------------------|-----------------------------------|
| [process-improvement-tracking.md](../../state-tracking/permanent/process-improvement-tracking.md) | Both | New `## Active Pilots` section added between Task Routing and Current Improvement Opportunities. Read by Framework Extension Task Phase 5 archive guard; written when Framework Extension Task chooses pilot path; closed when rollout/rollback decision recorded. Pilot rows use the **same PF-IMP-NNN ID pool** as the Current Improvement Opportunities table (no separate ID prefix). |
| [script-soak-tracking.md](../../../process-framework/state-tracking/permanent/script-soak-tracking.md) | Read only (by extension) | Pilot rows may reference soak rows (by Script ID) in their Adopters column. No schema change. |

### Artifact Interfaces

| Existing Artifact | Relationship | Description |
|------------------|--------------|-------------|
| [framework-extension-task.md](../../../process-framework/tasks/support/framework-extension-task.md) | Updated by extension | Add Step 4.5 (Pilot Decision); modify Step 5 (Checkpoint) to include pilot decision in checkpoint material; modify Steps 20-21 (Archive) to conditional on pilot status; add line to Task Completion Checklist. |
| [process-improvement-tracking.md](../../state-tracking/permanent/process-improvement-tracking.md) | Updated by extension | New `## Active Pilots` section with Status Legend, columns, and initial row for the soak pilot. |
| `script-self-verification.md` (concept doc) | Pulled back from archive | Move from `process-framework-local/proposals/old/` to `process-framework-local/proposals/` to live alongside other active concepts during pilot. |
| `old/temp-framework-extension-script-self-verification.md` | Pulled back from archive | Move from `process-framework-local/state-tracking/temporary/old/` to `process-framework-local/state-tracking/temporary/` for the same reason. |

## 🏗️ Core Process Overview

The extension introduces no new workflow — it modifies the existing Framework Extension Task workflow at three points and adds a tracking surface. The behaviors it produces:

### Phase 1: Pilot Decision

1. **At Step 4.5 (new) — Pilot Decision**: after impact analysis (Step 4), the agent and human partner evaluate whether the extension's new behavior has unknown failure modes warranting a pilot. Decision options: `Full Rollout` (default) or `Pilot`. If `Pilot`: identify representative adopter artifacts, define success criteria, and identify the decision trigger (typically a follow-up IMP filed at Phase 4 finalization).
2. **At Step 5 (modified) — Checkpoint**: pilot decision and rationale are part of the checkpoint material presented to the human partner alongside concept doc and impact analysis.

### Phase 2: Pilot Registration (only if pilot chosen)

3. **At Phase 4 finalization (new sub-step)** — when the pilot adopters are complete and registered for any per-script tracking (e.g., soak), append a row to the Active Pilots section via `New-ProcessImprovement.ps1 -AsPilot ...` (which consumes the next PF-IMP-NNN ID and writes to the Active Pilots section). Initial status: `Active`.

### Phase 3: Archive Deferral (only if pilot chosen)

4. **At Step 20 (unchanged) — Move Temporary State Tracking**: temp state archives normally. The implementation work is complete; the temp state has nothing more to track. The pilot lifecycle is now owned by the Active Pilots row.
5. **At Step 21 (modified) — Archive Concept Document**: conditional — skip if pilot row is not yet `Resolved`. Concept stays in `proposals/` because it is the source of truth for the rollout decision and the spec for what's being scaled.
6. **At Task Completion Checklist (modified)** — gain a line: "If pilot chosen at Step 4.5, Active Pilots row exists with status `Active` and concept-doc archive is correctly deferred. (Concept archive happens later when pilot reaches Resolved.)"

### Phase 4: Pilot Resolution (later, separate session)

7. **Decision trigger fires** (the IMP filed at Phase 4, e.g., PF-IMP-685 for the soak pilot, processed by Process Improvement Task). Operator and human partner evaluate pilot success criteria and choose: rollout, rollback, or extend.
8. **Resolution recorded** via `Update-ProcessImprovement.ps1 -ImprovementId PF-IMP-NNN -NewStatus Resolved -Notes "<decision summary>"`. Script:
   - Looks up IMP-NNN in the Active Pilots section (in addition to its existing Current/Completed search).
   - Updates the row's Status to `Resolved` and writes Notes.
   - Triggers archive of the linked concept doc (resolved via the row's Source column referencing the concept ID).
   - Logs the action in the file's Update History.

## 🔗 Integration with Task-Based Development Principles

### Adherence to Core Principles
- **Task Granularity**: extension is single-session and lightweight — modification-only, no new tasks/templates/scripts.
- **State Tracking**: reuses an existing tracked file (process-improvement-tracking.md). No new state files.
- **Artifact Management**: pilot rows have a defined lifecycle (`Active` → `Awaiting Decision` → `Resolved`), with archive of associated concept/temp-state gated on resolution.
- **Task Handover**: pilot row + concept doc (kept in `proposals/`) + temp state file (kept in `temporary/`) form a coherent handover surface for the eventual rollout-decision session.

### Framework Evolution Approach
- **Incremental Extension**: pilot decision is opt-in (default is full rollout). Extensions that don't need a pilot are unaffected.
- **Consistency Maintenance**: Active Pilots section follows the same Status Legend / table conventions used elsewhere in process-improvement-tracking.md.
- **Integration Focus**: hooks at three precise points in the Framework Extension Task; touches no other tasks.
- **Documentation Alignment**: PF-documentation-map.md gets one entry update (process-improvement-tracking.md description amended to mention Active Pilots).

## 📊 Detailed Workflow & Artifact Management

### Workflow Definition

#### Input Requirements
- **Decision input**: human-partner judgment at the Step 5 checkpoint on whether the new behavior warrants a pilot, given impact analysis findings.
- **Pilot definition input** (only if pilot chosen): adopter artifacts, success criteria, decision trigger.

#### Process Flow

```
Phase 1 (Concept):                           Phase 4 (Adoption, only if pilot):
─────────────────                            ───────────────────────────────────
Impact Analysis (Step 4)                     Adopter scripts armored & registered
        ↓                                              ↓
Pilot Decision (new Step 4.5)                Append row to Active Pilots
        ↓                                              ↓
Step 5 Checkpoint (decision presented)       Pilot status: Active
        ↓
Approved → Phase 2 / 3 / 4 implementation   Phase 5 (Finalization):
                                             ──────────────────────
                                             Read pilot row status
                                                       ↓
                                             Resolved? ─── yes → archive concept + temp state
                                                       │
                                                       no → SKIP archive; mark temp state
                                                            frontmatter pilot_phase: in_progress

Later (separate Process Improvement session):
─────────────────────────────────────────────
Decision-trigger IMP processed (e.g. PF-IMP-685)
        ↓
Operator + human evaluate pilot success criteria
        ↓
Active Pilots row Notes ← decision; status → Resolved
        ↓
Archive originally-deferred concept + temp state
```

### Artifact Dependency Map

#### Dependencies on Existing Artifacts
| Required Artifact | Source | Usage |
|------------------|--------|-------|
| [framework-extension-task.md](../../../process-framework/tasks/support/framework-extension-task.md) | Project | Modified — three insertion points (Step 4.5, Step 5, Step 20-21) plus checklist line |
| [process-improvement-tracking.md](../../state-tracking/permanent/process-improvement-tracking.md) | Project | Modified — new Active Pilots section between existing Task Routing and Current Improvement Opportunities |
| [script-self-verification.md](script-self-verification.md) (currently in `.`) | Project | Pulled back to active location for retroactive pilot registration |
| [old/temp-framework-extension-script-self-verification.md](../../state-tracking/temporary/old/temp-framework-extension-script-self-verification.md) | Project | Pulled back to active location for retroactive pilot registration |

### State Tracking Integration Strategy

#### Updates to Existing State Files
- **process-improvement-tracking.md**: new `## Active Pilots` section (placed between `## Task Routing` and `## Current Improvement Opportunities`). Includes its own Status Legend (3 values) and table with columns: `Pilot Name | Source | Started | Adopters | Success Criteria | Decision Trigger | Status | Notes`.

#### State Update Triggers
- **Pilot chosen at Framework Extension Task Step 4.5 + Phase 4 finalization complete** → row appended to Active Pilots with status `Active`.
- **Pilot adopters reach success criteria** (e.g., soak counters at 0) → status remains `Active` until decision recorded; optionally flipped to `Awaiting Decision` to flag for next Process Improvement session.
- **Decision trigger IMP processed and resolution recorded** → status `Resolved`; Notes column gets the decision; deferred concept + temp state archived.

## 🔄 Modification Details

### State Tracking Audit

| State File | Current Purpose | Modification Needed | Change Type |
|-----------|-----------------|---------------------|-------------|
| [process-improvement-tracking.md](../../state-tracking/permanent/process-improvement-tracking.md) | Tracks IMPs and routing | Add `## Active Pilots` section with Status Legend (2 statuses: `Active` / `Resolved`) + table; add initial row (PF-IMP-NNN) for retroactive soak pilot | Add section |

**Cross-reference impact**:
- [Validate-StateTracking.ps1](../../../process-framework/scripts/validation/Validate-StateTracking.ps1) — confirmed via grep: zero references to process-improvement-tracking.md or `ProcessImprovement` patterns. New section is outside its scope. Will re-verify clean before/after the section addition.
- [Update-ProcessImprovement.ps1](../../../process-framework/scripts/update/Update-ProcessImprovement.ps1) — currently scoped to `## Current Improvement Opportunities` and `## Completed Improvements` (regex `## $section[\s\S]*?(?=\n## |\z)` naturally stops at a new `## ` heading). **This extension adds Active Pilots handling**: the script will search Active Pilots in addition to the existing two sections when locating an IMP-NNN, and dispatch to the pilot-status code path when the IMP is found there.
- [New-ProcessImprovement.ps1](../../../process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1) — currently writes to Current Improvement Opportunities. **This extension adds an `-AsPilot` switch** that routes the row to Active Pilots instead, with a different column schema (the pilot-specific columns).

### Guide Update Inventory

| File to Update | References To | Update Needed |
|---------------|---------------|---------------|
| [framework-extension-task.md](../../../process-framework/tasks/support/framework-extension-task.md) | Phase 1 / Phase 4 / Phase 5 / Task Completion Checklist | (a) Add Step 4.5 (Pilot Decision). (b) Step 5 checkpoint material includes pilot decision. (c) Phase 4 finalization gains `New-ProcessImprovement.ps1 -AsPilot ...` sub-bullet. (d) Step 21 archive becomes conditional on pilot status; Step 20 unchanged. (e) Task Completion Checklist gains pilot-row assertion line. |
| [process-improvement-tracking.md](../../state-tracking/permanent/process-improvement-tracking.md) | Header section + body | Add `## Active Pilots` section between `## Task Routing` and `## Current Improvement Opportunities`. Status Legend (2 states: `Active` / `Resolved`); columns: `ID | Source | Started | Adopters | Success Criteria | Decision Trigger | Status | Notes`. |
| [task-transition-registry.md](../../../process-framework/infrastructure/task-transition-registry.md) | "FROM Framework Extension Task" section (lines 1063-1078) | Add pilot-path note: when pilot was chosen at Step 4.5, Phase 5 archive of concept doc is deferred until pilot reaches `Resolved`; rollout-decision happens later via Process Improvement Task on the pilot's decision-trigger IMP. ~10 lines. |
| [PF-documentation-map.md](../../../process-framework/PF-documentation-map.md) | process-improvement-tracking.md entry | Update one-line description to mention Active Pilots section. |

**Discovery method**:
- Read of framework-extension-task.md Phase 5 to locate the existing Step 20/21 archive logic.
- Manual read of process-improvement-tracking.md structure to identify the right placement for the Active Pilots section.
- Read of task-transition-registry.md "FROM Framework Extension Task" section to identify the integration point (existing section needs a pilot path described).
- Confirmed via grep that no other task or script references a "pilot" surface — none exists.

### Automation Integration Strategy

| Existing Script | Current Behavior | Required Change | Backward Compatible? |
|----------------|-----------------|-----------------|---------------------|
| [New-ProcessImprovement.ps1](../../../process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1) | Adds rows to Current Improvement Opportunities; consumes next PF-IMP-NNN from registry | **Add `-AsPilot` switch** plus pilot-specific parameters (`-SourceConcept`, `-OriginatingTask`, `-Adopters`, `-SuccessCriteria`, `-DecisionTrigger`). When `-AsPilot` is set: write to Active Pilots section instead of Current Improvement Opportunities, with the pilot column schema. ID consumption is unchanged (same PF-IMP pool). | **Yes** — existing call sites with no `-AsPilot` switch behave identically |
| [Update-ProcessImprovement.ps1](../../../process-framework/scripts/update/Update-ProcessImprovement.ps1) | Searches Current Improvement Opportunities for IMP-NNN; updates status or moves to Completed | **Add Active Pilots search**: search Active Pilots in addition to Current/Completed when looking up `-ImprovementId`. When IMP found in Active Pilots: dispatch to pilot-status code path — accept `-NewStatus` `Active` or `Resolved`; on `Resolved`, write Notes and trigger archive of the linked concept doc (resolved by reading the row's Source column). Update History gets a pilot-specific log entry. | **Yes** — existing call sites operating on IMPs in Current/Completed sections are unaffected; only new behavior is for IMPs in Active Pilots |
| [Validate-StateTracking.ps1](../../../process-framework/scripts/validation/Validate-StateTracking.ps1) | 15 surfaces; no current reference to process-improvement-tracking.md | None — confirmed via grep | **Yes** |

**New automation**: **None.** No new scripts. Both extensions are additive parameter sets on existing scripts.

---

## 🔧 Implementation Roadmap

This extension still qualifies for the **lightweight path** in [Framework Extension Task Step 5](../../../process-framework/tasks/support/framework-extension-task.md):

- ✅ **Modification-type**: no new tasks, templates, guides, or scripts. Two existing scripts gain new parameters (additive); one task definition gains a step + conditionals; one state file gains a section; one infrastructure doc gains a paragraph.
- ⚠️ **Single-session**: scope is larger than the original framing — script extensions add real PowerShell work. Estimated 60-90 minutes. Single-session is achievable but should not be padded with other work.
- ✅ **No new ID prefixes**: pilots reuse the PF-IMP pool.

If approved at Step 5, the implementation breaks down into these steps (single session):

### Single Implementation Session

1. **Extend [New-ProcessImprovement.ps1](../../../process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1)** with `-AsPilot` switch and pilot-specific parameters. When set, route the row to Active Pilots with the pilot column schema. Validate parameter combinations (`-AsPilot` requires the pilot params; non-`-AsPilot` rejects them). `-WhatIf` smoke test for both modes.
2. **Extend [Update-ProcessImprovement.ps1](../../../process-framework/scripts/update/Update-ProcessImprovement.ps1)** with Active Pilots search + pilot-status dispatch. On `-NewStatus Resolved` for an Active Pilots IMP: write Notes, trigger concept-doc archive (move from `proposals/` to `proposals/old/`), log to Update History. `-WhatIf` smoke test.
3. **Add `## Active Pilots` section** to [process-improvement-tracking.md](../../state-tracking/permanent/process-improvement-tracking.md) between `## Task Routing` and `## Current Improvement Opportunities`. Contents: intro paragraph, Status Legend (2 states: `Active` / `Resolved`), columns table (`ID | Source | Started | Adopters | Success Criteria | Decision Trigger | Status | Notes`).
4. **Modify [framework-extension-task.md](../../../process-framework/tasks/support/framework-extension-task.md)**:
   - Add Step 4.5 (Pilot Decision) after Step 4.
   - Adjust Step 5 checkpoint material to include pilot decision.
   - Add Phase 4 finalization sub-bullet referencing `New-ProcessImprovement.ps1 -AsPilot`.
   - Make Step 21 conditional on pilot row status. (Step 20 unchanged.)
   - Add line to Task Completion Checklist.
5. **Update [task-transition-registry.md](../../../process-framework/infrastructure/task-transition-registry.md)** `FROM Framework Extension Task` section: add a pilot-path note about deferred concept archive and the eventual rollout-decision session via Process Improvement.
6. **Pull soak pilot concept doc back** from `proposals/old/` to `proposals/` (the temp state file stays in `temporary/old/` — it does not need to be reactivated under the corrected Q4 rule).
7. **Append soak pilot row** to the new Active Pilots section via the extended `New-ProcessImprovement.ps1 -AsPilot ...` command (this is also the first end-to-end test of the extended script). Status: `Active`. Decision trigger: PF-IMP-685.
8. **Update [PF-documentation-map.md](../../../process-framework/PF-documentation-map.md)** description for process-improvement-tracking.md to mention Active Pilots.
9. **Verification**: `Validate-StateTracking.ps1` clean before/after; both extended scripts pass `-WhatIf` and a real-execution smoke test; manual re-read of framework-extension-task.md edits.
10. **Close PF-IMP-686** as `Completed` via `Update-ProcessImprovement.ps1` and archive this concept doc to `proposals/old/`. Note: PF-PRO-030 is the *pilot-tracking framework* concept; the soak pilot's concept is **PF-PRO-028** (script-self-verification.md), which is the one that stays in `proposals/` until the soak pilot resolves. PF-PRO-030 itself had no pilot chosen at its own Step 4.5, so Step 21 archive fires normally.

### Out of Scope

- **Pilot decision step in Process Improvement Task**: not included; per agreement, scope is Framework Extension Task only.
- **Pilot decision step in Structure Change Task**: not included.
- **Pilot review task definition**: not needed — decision triggers fire as ordinary IMPs processed by Process Improvement Task.
- **ai-tasks.md update**: not needed — pilots are managed inside Framework Extension Task, not as a top-level task type.

## 🎯 Success Criteria

### Functional Success Criteria
- [ ] Active Pilots section exists in process-improvement-tracking.md with 2-state Status Legend and the agreed columns.
- [ ] Soak pilot row appears in Active Pilots with status `Active`, PF-IMP-685 as decision trigger, and both original pilot scripts (and the opportunistically-armored New-ProcessImprovement.ps1) listed as adopters. Row was created via the extended `New-ProcessImprovement.ps1 -AsPilot ...` (consumed next PF-IMP-NNN from the registry).
- [ ] `New-ProcessImprovement.ps1 -AsPilot` works end-to-end: WhatIf smoke test passes; real execution wrote the soak pilot row correctly.
- [ ] `Update-ProcessImprovement.ps1` finds an IMP-NNN in Active Pilots and accepts `-NewStatus Resolved`; on Resolved, the linked concept doc is archived. (Tested with WhatIf only during this session — real execution will happen when PF-IMP-685 resolves.)
- [ ] Framework Extension Task definition has Step 4.5, modified Step 5 checkpoint, Phase 4 finalization sub-bullet, Step 21 archive conditional (Step 20 unchanged), and Task Completion Checklist line.
- [ ] Task Transition Registry `FROM Framework Extension Task` section has the pilot-path note.
- [ ] Soak concept doc is back in `proposals/`. Temp state file stays in `temporary/old/`.
- [ ] PF-documentation-map.md description for process-improvement-tracking.md mentions Active Pilots.

### Human Collaboration Requirements
- [ ] **Concept Approval at Step 5 checkpoint** (this concept doc + impact analysis).
- [ ] **Lightweight path approval** at Step 5 (with the acknowledged 60-90 minute single-session expectation, larger than the original framing).

### Technical & Integration Requirements
- [ ] [Validate-StateTracking.ps1](../../../process-framework/scripts/validation/Validate-StateTracking.ps1) runs clean before and after the section addition.
- [ ] No script in `process-framework/scripts/` parses the new section — confirmed by manual review and by Validate-StateTracking.ps1 run.
- [ ] Backward compatible: any existing Framework Extension Task in flight at the time of this change continues working unchanged (new step is opt-in via Step 4.5 default = `Full Rollout`).

### Quality Success Criteria
- [ ] Framework Extension Task edits read coherently end-to-end (re-read after edits).
- [ ] Active Pilots section's Status Legend and columns are usable by an operator who has never seen the section before, without consulting other docs.

## 📝 Next Steps

### Immediate Actions Required (at Step 5 Checkpoint)
1. **Human review** of this concept and impact analysis.
2. **Confirm Question 4** default (pilot end definition).
3. **Approve lightweight path**.

### Implementation Preparation (post-approval)
1. Run [Validate-StateTracking.ps1](../../../process-framework/scripts/validation/Validate-StateTracking.ps1) baseline (capture clean state).
2. Execute the 7 steps in the Single Implementation Session above.
3. Re-run [Validate-StateTracking.ps1](../../../process-framework/scripts/validation/Validate-StateTracking.ps1); confirm no new errors.

---

## 📋 Human Review Checklist

**🚨 This concept requires human review before implementation can begin.**

### Concept Validation
- [x] **Extension Necessity**: confirmed — visibility-after-archive gap is real (PF-IMP-685 surfaced it).
- [x] **Scope Appropriateness**: confirmed — modification-only with two existing-script extensions.
- [x] **Active Pilots placement**: confirmed — between Task Routing and Current Improvement Opportunities.
- [x] **Archive policy**: confirmed — temp state archives normally at Phase 5; only concept doc archive defers (concept is the spec for what's being scaled).

### Technical Review
- [x] **Pilot decision step (Step 4.5)**: confirmed — presented at Step 5 checkpoint material.
- [x] **Two-status legend** (`Active` / `Resolved`): confirmed.
- [x] **ID model**: confirmed — pilot rows use PF-IMP-NNN from the same pool as Current Improvement Opportunities; pilots are "IMPs with a multi-stage lifecycle".
- [x] **Columns** (`ID | Source | Started | Adopters | Success Criteria | Decision Trigger | Status | Notes`): confirmed.
- [x] **Question 4** (what ends a pilot): confirmed with refinement — success criteria met → decision recorded via `Update-ProcessImprovement.ps1 -NewStatus Resolved` → script triggers concept-doc archive. Temp state file archives at Phase 5 normally (separate from pilot lifecycle).

### Open Design Questions
- All resolved during pre-checkpoint review (2026-04-29).

### Approval Decision
- [ ] **APPROVED**: Concept is approved; lightweight path execution authorized.
- [ ] **NEEDS REVISION**: Concept needs changes before approval.
- [ ] **REJECTED**: Concept is not suitable for framework extension.

**Human Reviewer**: Ronny Wette
**Review Date**: 2026-04-29
**Decision**: [APPROVED / NEEDS REVISION / REJECTED]
**Comments**: [Review comments and feedback]

---

*This concept document was created using the Framework Extension Concept Modification Template as part of the Framework Extension Task ([PF-TSK-026](../../../process-framework/tasks/support/framework-extension-task.md)). Originating IMP: [PF-IMP-686](../../state-tracking/permanent/process-improvement-tracking.md).*
