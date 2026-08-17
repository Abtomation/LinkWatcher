---
id: PF-TSK-093
type: Process Framework
category: Task Definition
version: 1.1
created: 2026-07-15
updated: 2026-07-16
automation: semi
complexity: medium
description: "Execute a technical exploration spike: bounded research that must resolve before a feature can proceed to design/implementation"
domain: agnostic
use_when: >-
  Execute a queued technical exploration spike — a bounded research investigation that must resolve before a feature's design or implementation can proceed. Produces a findings document and resolves the exploration tracker row.
triggers:
  - "run the exploration for X"
  - "do the technical exploration"
  - "resolve exploration EXP-NNN"
scripts:
  - ../../scripts/file-creation/01-planning/New-TechnicalDoc.ps1
  - ../../scripts/update/Update-Exploration.ps1
  - ../../scripts/update/Update-BatchFeatureStatus.ps1
trigger_status:
  - file: technical-exploration-tracking.md
    status: "📥 Queued"
  - file: feature-tracking.md
    status: "🔬 Needs Technical Exploration"
output_status:
  - file: technical-exploration-tracking.md
    status: "✅ Resolved"
  - file: feature-tracking.md
    status: "<prior pipeline status>"
    condition: "when a feature was blocked on the exploration"
next_tasks:
  - task: feature-request-evaluation.md
    condition: "Pre-feature exploration — findings inform classification / tier assessment"
  - task: ../02-design/fdd-creation-task.md
    condition: "Feature-blocking exploration resolved — resume the feature's design chain"
---

# Technical Exploration

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

> **⚠️ ROLLOUT NOTE**: This task is fully wired — tracking file (`technical-exploration-tracking.md`, PF-FST-009), the three scripts, the findings-doc template (PF-TEM-085), the `PD-EXP` prefix, the `🔬 Needs Technical Exploration` feature-tracking status, and the Feature Discovery / Feature Request Evaluation producers are all in place. In an **already-onboarded project**, the tracking file and the legend row arrive only once the next [Framework Rollout](../support/framework-rollout-task.md) (PF-TSK-088) drains that project's pending migration; until then this task has no tracker to read in that project.

## Purpose & Context

Execute a **technical exploration spike** — a bounded research investigation (evaluate a library, prototype a risky integration, benchmark an approach, confirm a platform capability) that must resolve *before* a feature can proceed to design or implementation. The task takes one queued exploration item, conducts the research, records a findings document, resolves the tracker row, and unblocks the dependent work. It is the consumer of the exploration items that Feature Discovery (and other planning tasks) produce.

## AI Agent Role

**Role**: Technical Investigator
**Mindset**: Evidence-driven, options-comparing, decision-oriented — resolve the open question, don't gold-plate it
**Focus Areas**: Research scoping, option evaluation against explicit criteria, prototyping/benchmarking only as deep as the decision needs, honest recording of residual uncertainty
**Communication Style**: Present options with trade-offs and a clear recommendation; surface blocking unknowns early; gate resolution on human approval

## Context Requirements

- **Critical (Must Read):**

  - [Technical Exploration Tracking](../../../doc/state-tracking/permanent/technical-exploration-tracking.md) - The exploration item to execute (the research question + acceptance criteria + related feature, if any). The selected `📥 Queued` row is the task's input.
  - [Findings-document template](../../templates/01-planning/technical-findings-template.md) - Structure for the PD-TEC findings document this task produces (research summary, options, recommendation, residual-items table).

- **Important (Load If Space):**

  - The related feature's implementation state file (if the exploration blocks a specific feature) - the feature context the research serves; found via the tracker row's *Related Feature* column.
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - When a feature is blocked on this exploration it shows `🔬 Needs Technical Exploration`; this task clears that block on resolution.

- **Reference Only (Access When Needed):**
  - [PD ID Registry](../../../doc/PD-id-registry.json) - PD-TEC (findings docs) and PD-EXP (exploration rows) prefixes.
  - [Feature Request Evaluation](feature-request-evaluation.md) - Downstream consumer for pre-feature findings (classification / tier assessment).

## Process

> **🚨 Core cautions**: This is a research task, not an implementation task — do not begin building the feature the exploration serves. Resolve the tracker row only after the findings checkpoint is approved.

### Preparation

1. **Select the exploration item**: From [Technical Exploration Tracking](../../../doc/state-tracking/permanent/technical-exploration-tracking.md), pick the `📥 Queued` row named by the human partner. Confirm its **research question** and **acceptance criteria** — what must be answered for the dependent work to unblock. If the acceptance criteria are unclear, resolve them with the human before researching.
2. **Mark it in progress**: Set the row to `🔬 In Progress` so the work is visible.
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-Exploration.ps1 -ExplorationId "PD-EXP-NNN" -NewStatus "InProgress" -Confirm:\$false
   ```
   > **Expected result**: the row's Status column reads `🔬 In Progress`. (Status values are passed as plain words — `InProgress` / `Resolved` / `Abandoned` — and rendered to the tracker's emoji legend by the script, keeping emoji off the command line where shell encoding can mangle them. This is the convention among the feature-tracking and exploration/request/debt lifecycle scripts, including `Update-BatchFeatureStatus.ps1` at Step 8.)
3. **Check for a blocked feature**: If the tracker row names a *Related Feature*, confirm that feature shows `🔬 Needs Technical Exploration` in [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) (set by Feature Request Evaluation). A *pre-feature* exploration (no related feature row) skips this — its findings feed feature planning instead.

### Execution

4. **Conduct the research**: Investigate against an explicit method — state the evaluation criteria, gather evidence, compare the candidate options against the criteria, and prototype or benchmark **only as deep as the decision requires**. Consult the human partner at decision points and whenever a blocking unknown surfaces.
5. **Author the findings document**: Create (first session) or update (a continuing multi-session spike) the PD-TEC findings document, applying the findings-document template. Write it to `doc/technical/explorations/`. **For a feature-blocking exploration, pass `-FeatureId`** so the script links the findings document into that feature's per-feature state file **§4 Documentation Inventory** (the canonical per-feature artifact home, per PF-PRO-002 / PF-IMP-760) — the same mechanism the design-creation scripts use.
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/01-planning/New-TechnicalDoc.ps1 -Title "Exploration: [question]" -ExplorationId "PD-EXP-NNN" -FeatureId "<feature-id — omit for a pre-feature exploration>" -Confirm:\$false
   ```
   The findings document must carry: a **research summary**, the **options compared** against the stated criteria, a **recommendation**, and a **residual-items table** (each open item + its suggested vehicle — e.g. a new feature request, a follow-up exploration, a tech-debt item). For a spike that spans sessions, **bump the findings-document version** each session; the findings document — not a tracker Notes cell — is the running research log.
6. **🚨 CHECKPOINT**: Present the findings and recommendation to the human partner. **Resolution is gated on approval** — do not resolve the tracker row or clear a feature block until the human accepts the findings (or directs further investigation).

### Finalization

7. **Resolve the exploration row**: Set the tracker row to `✅ Resolved` and link the findings document.
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-Exploration.ps1 -ExplorationId "PD-EXP-NNN" -NewStatus "Resolved" -FindingsDoc "PD-TEC-NNN" -Confirm:\$false
   ```
   > `-FindingsDoc` is **required** when resolving — a resolved row with no findings link strands the downstream task that reads it. The row moves out of the active queue into the collapsed **Resolved Explorations** archive, where the Outcome column carries the disposition. (Use `-NewStatus "Abandoned"` for a spike that is no longer needed; no findings doc required.)
8. **Unblock the downstream work**:
   - **Feature-blocking exploration**: return the related feature from `🔬 Needs Technical Exploration` to the pipeline status recorded in the exploration's Notes (Feature Request Evaluation records it there when it diverts the feature), adjusted if the findings changed which gate comes next.
     ```bash
     pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-BatchFeatureStatus.ps1 -FeatureIds "X.Y.Z" -Status "NeedsFDD" -UpdateType "StatusOnly"
     ```

     The findings link lives in the feature's §4 Documentation Inventory (Step 5), not the master tracker (per PF-PRO-002 / PF-IMP-760). The feature resumes its normal design chain.
   - **Pre-feature exploration**: no feature status to clear — carry the findings to [Feature Request Evaluation](feature-request-evaluation.md) or [Feature Discovery](feature-discovery-task.md), which decide whether/what to build.
9. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below.

## Outputs

- **Technical Findings Document (PD-TEC)** - The research artifact, written to `doc/technical/explorations/`, holding research summary, options comparison, recommendation, and residual-items table. Versioned per session for multi-session spikes.
- **Resolved exploration row** - The Technical Exploration Tracking row at `✅ Resolved`, linked to the findings document.
- **§4 Documentation Inventory link** *(conditional)* - For a feature-blocking exploration, the findings document linked in the related feature's per-feature state file §4 Documentation Inventory (via `New-TechnicalDoc.ps1 -FeatureId`).
- **Cleared feature block** *(conditional)* - The related feature returned from `🔬 Needs Technical Exploration` to its pipeline status (feature-blocking explorations only).

## State Tracking

The following state files must be updated as part of this task:

- [Technical Exploration Tracking](../../../doc/state-tracking/permanent/technical-exploration-tracking.md) - Row status advanced `📥 Queued` → `🔬 In Progress` → `✅ Resolved`, findings document linked.
- **Per-feature state file §4 Documentation Inventory** - *Conditional*: the findings document (PD-TEC) linked in the related feature's state file (feature-blocking explorations only; canonical per-feature artifact home per PF-PRO-002 / PF-IMP-760).
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - *Conditional*: the related feature returned from `🔬 Needs Technical Exploration` to its pipeline status (feature-blocking explorations only).

## ⚠️ Task Completion Checklist (task-specific)

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Findings document created/updated in `doc/technical/explorations/` with research summary, options comparison, recommendation, and residual-items table
  - [ ] Findings presented and approved at the Execution checkpoint before resolution
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Technical Exploration Tracking](../../../doc/state-tracking/permanent/technical-exploration-tracking.md) row at `✅ Resolved` with the findings document linked
  - [ ] *Conditional*: related feature returned from `🔬 Needs Technical Exploration` to its pipeline status (feature-blocking explorations only)
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-093`, context "Technical Exploration".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `doc/technical/explorations/PD-TEC-NNN-*.md` | [`New-TechnicalDoc.ps1`](../../scripts/file-creation/01-planning/New-TechnicalDoc.ps1) | Findings document (research summary, options, recommendation, residual-items table) |
| **Updates** | Related feature's per-feature state file §4 Documentation Inventory | [`New-TechnicalDoc.ps1`](../../scripts/file-creation/01-planning/New-TechnicalDoc.ps1) `-FeatureId` | *Conditional*: findings-document row inserted (feature-blocking explorations only) |
| **Updates** | [`technical-exploration-tracking.md`](../../../doc/state-tracking/permanent/technical-exploration-tracking.md) | [`Update-Exploration.ps1`](../../scripts/update/Update-Exploration.ps1) | Row status `📥 Queued` → `🔬 In Progress` → `✅ Resolved`; findings-doc link |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | [`Update-BatchFeatureStatus.ps1`](../../scripts/update/Update-BatchFeatureStatus.ps1) | *Conditional*: clear `🔬 Needs Technical Exploration` back to the feature's pipeline status |

## Next Tasks

- **Feature Request Evaluation** - For a pre-feature exploration, the findings feed classification and tier assessment.
- **FDD Creation** (or the feature's next design-chain gate) - For a feature-blocking exploration, the unblocked feature resumes its design chain.

### Prerequisites for Transition

- [ ] Findings document produced and approved at the checkpoint
- [ ] Exploration row at `✅ Resolved` with the findings document linked
- [ ] Any related feature returned from `🔬 Needs Technical Exploration` to its pipeline status

### Next Task Selection

```
Was the exploration blocking an existing feature?
├─ Yes → the feature is returned to its pipeline status → resume its design chain
│        (FDD Creation / the recomputed design-chain gate, or Feature Implementation Planning for Tier 1)
└─ No (pre-feature) → Feature Request Evaluation / Feature Discovery
         └─ the findings inform whether/what feature to create
```

### Preparation for Next Task

1. Ensure the findings document's recommendation and residual-items table are complete — the downstream task reads them.
2. For a feature-blocking exploration, confirm the feature's restored status reflects where its design chain resumes.
3. For a pre-feature exploration, carry the recommendation into the classification/discovery discussion.

## Related Resources

- [Feature Discovery](feature-discovery-task.md) - The primary producer of exploration items (step 15 files them into Technical Exploration Tracking).
- [Technical Debt Assessment](../cyclical/technical-debt-assessment-task.md) - Distinct concern: identifies *rework debt*, not open research questions. An exploration's residual items may include debt items filed there.
