---
id: PF-TSK-094
type: Process Framework
category: Task Definition
version: 1.3
created: 2026-08-04
updated: 2026-08-04
automation: full
complexity: medium
description: "Design the instruction-medium parts of a feature: the executable procedure, its artifact inventory with declared kinds, its instruction contract, and its verification plan, captured as a PD-IND design document"
domain: agnostic
use_when: >-
  Create the instruction design for a feature whose deliverable includes instruction artifacts an agent executes. Triggers: 'create the instruction design', 'design the instructions for feature X', 'spec the procedure'.
triggers:
  - "create the instruction design"
  - "design the instructions for feature X"
  - "spec the procedure"
scripts:
  - ../../scripts/file-creation/02-design/New-InstructionDesign.ps1
trigger_status:
  - raw: "Triggered by feature-tracking Status `📜 Needs Instruction Design` — the fourth design-dimension gate, ordered LAST in the design chain (DB → API → UI → Instruction), so a mixed feature's instruction design is authored with its code designs already in hand (PF-PRO-064, per `AssessmentParsing.psm1`). Also invoked by: human-partner request; a tier-assessment narrative recommending an instruction design pass."
output_status:
  - raw: "`feature-tracking.md` → the terminal design status (`📝 Needs TDD` for Tier 2+, or `🔧 Needs Impl Plan` for Tier 1), advancing past the instruction gate; per-feature state file §4 Documentation Inventory → Instruction Design row (the creation is also recorded in the Notes column); PD-documentation-map.md → reflected on `-Tree PD` regeneration"
next_tasks:
  - task: tdd-creation-task.md
    condition: "Tier 2+ — the terminal document integrates this dimension with the code dimensions"
  - task: ../04-implementation/feature-implementation-planning-task.md
    condition: "Tier 1 — skips TDD; the Artifact Inventory feeds planning directly"
---

# Instruction Design

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

**🤖 AUTOMATION NOTE**: This task is **FULLY AUTOMATED** by [New-InstructionDesign.ps1](../../scripts/file-creation/02-design/New-InstructionDesign.ps1) (via the shared `Invoke-DesignArtifactCreation` core). The script generates the Instruction Design document (with a `description:` frontmatter line), advances the feature's Status past the instruction gate, and inserts an Instruction Design row into the per-feature state file's §4 Documentation Inventory. The PD documentation map is **generated** (`Build-DocumentationMap.ps1 -Tree PD`, PF-PRO-050) — it picks up the new document's `description:` on regeneration.

## Purpose & Context

Design the **instruction-medium** parts of a feature — the parts whose deliverable is instructions an agent executes rather than program code. Produces a PD-IND design document carrying the executable procedure's shape, its **Artifact Inventory** (every planned instruction artifact with a declared *kind*), its instruction contract, and its verification plan, for handoff to the terminal design document and implementation.

**Scope**: This task owns **instruction-design concerns**: the entry point and its granularity, artifact kinds, the input/output contract, execution flow and decision points, state and side effects, and the verification plan. Program code, UI, API contracts, and database schema are owned by their respective design tasks — a **mixed** feature carries this document alongside theirs.

> **Medium is declared, never inferred.** This task designs a feature's instruction dimension because the tier assessment says the feature *has* one (`### Instruction Design Required` → Yes). That is independent of the feature's `Medium` value: medium says what the deliverable is made of; the gate says whether there is an instruction dimension to design.

## AI Agent Role

**Role**: Systems Analyst
**Mindset**: Contract-first, execution-aware, verification-minded
**Focus Areas**: Procedure decomposition, artifact-kind selection, input/output contracts, decision points, verification design
**Communication Style**: Ask who executes each instruction and how its success would be observed; surface judgment calls rather than burying them in prose

## Information Flow

### Inputs from Other Tasks

- **Feature Request Evaluation** (PF-TSK-067): the tier assessment — complexity tier, declared `Medium`, and the `Instruction Design Required` determination that opens this gate
- **FDD Creation** (PF-TSK-027): functional requirements and user flows the procedure must deliver (Tier 2+)
- **UI / API / Database Schema Design** (PF-TSK-090 / 020 / 021): for a **mixed** feature, the code-dimension artifacts this instruction half invokes or consumes

### Outputs to Other Tasks

- **TDD Creation** (PF-TSK-015): the Instruction Design Reference the terminal document integrates
- **Feature Implementation Planning** (PF-TSK-044): the Artifact Inventory, which decomposes directly into implementation steps
- **Test Specification Creation** (PF-TSK-012) / **Test Audit** (PF-TSK-030): the verification plan (§6), including which levels apply and the Level 3 fixture design

## Context Requirements

- **Critical (Must Read):**

  - **Tier assessment** (`PD-ASS-NNN`) — the determination record: the feature's `Medium` and its `Instruction Design Required` answer (locate via [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md))
  - [Instruction Design Template](../../templates/02-design/instruction-design-template.md) — the structure the script populates; its instructional comments carry the **authoring craft** (kind selection, the entry-point rule, the mandatory Artifact Inventory)
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — the feature row whose Status advances past the instruction gate on completion

- **Important (Load If Space):**

  - **Functional Design Document (FDD)** — Tier 2+ functional requirements the procedure delivers (`doc/functional-design/fdds`)
  - **Existing Instruction Designs for related features** — for consistency in kind selection and contract shape (`doc/technical/design/instruction/features`)
  - **The feature's sibling design documents** — UI / API / Schema, for a mixed feature's §7 code seam
  - [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) — the general granularity tests the entry-point rule specializes

- **Reference Only (Access When Needed):**
  - [New-InstructionDesign.ps1](../../scripts/file-creation/02-design/New-InstructionDesign.ps1) — the automation script used at the create-the-document step
  - [Build-DocumentationMap.ps1](../../scripts/validation/Build-DocumentationMap.ps1) — regenerates the PD map at finalization

## Process

> **⚠️ MANDATORY: Use [New-InstructionDesign.ps1](../../scripts/file-creation/02-design/New-InstructionDesign.ps1) for document creation. Never hand-author an Instruction Design document.**
>
> **🚨 The Artifact Inventory (§2) is not optional.** A design document whose inventory is unfilled has not made the decision the document exists to make — instruction *kind* becomes an implementation accident again.
>
> **⚠️ Never fork the template by kind.** Kind is a field in the inventory, never a `instruction-design-{task,guide,skill}-template.md` family. This is a declared invariant (PF-PRO-064).

### Preparation

> **📝 Invocation note**: Instruction Design is a **state-file gate** — feature-tracking Status `📜 Needs Instruction Design`, the last design-chain gate before the terminal document (after any DB, API and UI gates). On completion the script advances the feature to the terminal status (`📝 Needs TDD` for Tier 2+, `🔧 Needs Impl Plan` for Tier 1). The gate is also reachable ad hoc, on a human-partner request or a tier-assessment narrative recommending an instruction design pass.

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `instruction-design-task`, and activate any bound skill available in the session. **No framework craft skill ships bound to this task by default** — the authoring craft lives in the [Instruction Design Template](../../templates/02-design/instruction-design-template.md)'s own instructional comments, which are the canonical source for kind selection and the entry-point rule. A project may bind an implementation skill of its own.
2. **Confirm the instruction dimension is real**: verify the tier assessment answers `### Instruction Design Required` → **Yes**, and read its `## Implementation Medium` declaration. If the assessment says No, this gate should not be open — stop and reconcile the assessment rather than designing around it.
3. **Establish the entry point and its boundary**: apply the entry-point rule — *a feature is one independently-invocable instruction entry point plus every artifact that exists to serve it*. A second entry point a user or agent would select independently is a **second feature**. Record adjacent entry points you are deliberately excluding, and which feature owns each.
4. **Gather context**: the FDD, existing Instruction Designs for related features, and — for a mixed feature — the sibling UI / API / Schema designs that the instruction half invokes or consumes.
5. **🚨 CHECKPOINT**: Present to the human partner: the entry point and its boundary, the provisional artifact list with proposed kinds, the medium composition (which parts are instruction and which are code), and any open questions. Get explicit approval before creating the document.

### Execution

6. **Create the Instruction Design document via script**:

   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-InstructionDesign.ps1 -FeatureId "X.Y.Z" -FeatureName "Feature Name" -Description "Brief design scope" -Confirm:\$false
   ```

   This automatically: assigns a `PD-IND` ID, generates the document under `doc/technical/design/instruction/features/`, advances the feature Status past the instruction gate, and inserts a row into the per-feature state file's §4 Documentation Inventory.

   **Expected result**: a success report naming the assigned `PD-IND-NNN`. If instead the script reports that **PD-IND is not registered in this project's PD ID registry**, the project's registry migration has not drained yet — apply it via [Framework Rollout](../support/framework-rollout-task.md) Mode C, then re-run. Do not work around the guard by hand-authoring the document.

7. **Fill the Artifact Inventory (§2)**: name every planned instruction artifact with its **kind** and a one-line justification for that kind, choosing from the template's Instruction Kinds Reference. Record what you considered and rejected under *Artifacts Deliberately Not Created* — an inventory with no rejections usually means the alternatives were never weighed.
8. **Specify the instruction contract (§3)**: inputs and how each precondition is checked, outputs and their postconditions, and the reference table of every script, path and parameter the instructions assert. Keep invocation lines exact — that table is the mechanically-checked surface.
9. **Design the execution flow (§4)**: step structure, decision points where the agent must *judge* rather than follow, checkpoints and their blocking status, and failure/recovery behavior including partial-completion state.
10. **Record state and side effects (§5)**: every file or tracker read and written, plus idempotency and concurrency behavior.
11. **Design the verification plan (§6)**: mark **every** level Applicable or N/A **with a reason**. An unmarked level is an unresolved design decision, not an omission. Where Level 3 applies, design the fixture — starting state, invocation, and the end-state assertions.
12. **For a mixed feature, specify the code seam (§7)**: where the instruction half meets the code half, in both directions. This is the part most often assumed rather than designed.
13. **🚨 CHECKPOINT**: Present the customized Instruction Design to the human partner — the inventory with its kind justifications, the contract, the decision points, and the verification plan. Get explicit approval before finalization.

### Finalization

14. **Complete the Design Handoff Checklist** (§9 of the document), including the cross-reference from the terminal design document back to this one.
15. **Verify automated updates and regenerate the PD map**: confirm the script inserted the §4 Documentation Inventory row, advanced the [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Status past the instruction gate, and generated the document with a `description:` frontmatter line. Then run `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Build-DocumentationMap.ps1 -Tree PD`, followed by `… -Tree PD -Check` — exit 0 (the PD map is a generated DO-NOT-EDIT projection, PF-PRO-050).
16. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#mandatory-task-completion-checklist) below

## Outputs

- **Instruction Design Document** — at `doc/technical/design/instruction/features/instruction-design-<id>-<slug>.md` (`PD-IND-NNN`), containing:
  - The entry point and its deliberately-excluded neighbours
  - The **Artifact Inventory** — every planned artifact with kind and justification
  - The instruction contract (inputs, outputs, referenced scripts/paths/parameters)
  - Execution flow, decision points, checkpoints, failure and recovery behavior
  - State and side effects, idempotency and concurrency
  - The verification plan across levels 1–4, with the Level 3 fixture design where applicable
  - The code seam, for a mixed feature
- **Updated [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)** — Status advanced past the instruction gate (automated by script)
- **Updated per-feature state file** — Instruction Design row inserted into §4 Documentation Inventory (automated by script)
- **Updated [PD-documentation-map.md](../../../doc/PD-documentation-map.md)** — regenerated via `Build-DocumentationMap.ps1 -Tree PD` (generated DO-NOT-EDIT projection, PF-PRO-050)

## State Tracking

The following state files are updated as part of this task:

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) — **AUTOMATICALLY UPDATED** by `New-InstructionDesign.ps1`: Status advanced past the instruction gate (`📝 Needs TDD` / `🔧 Needs Impl Plan`)
- Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`) — **AUTOMATICALLY UPDATED**: Instruction Design row inserted into §4 Documentation Inventory
- [PD-documentation-map.md](../../../doc/PD-documentation-map.md) — **GENERATED** (`Build-DocumentationMap.ps1 -Tree PD`): reflects the new document's `description:` on regeneration

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**:
  - [ ] Instruction Design document created via `New-InstructionDesign.ps1` (not hand-authored)
  - [ ] **Artifact Inventory (§2) filled** — every artifact carries a kind and a justification; no placeholder rows remain
  - [ ] *Artifacts Deliberately Not Created* records what was considered and rejected
  - [ ] Entry point named (§1.2), with excluded adjacent entry points recorded
  - [ ] Instruction contract (§3) complete, including the referenced scripts/paths/parameters table with exact invocation lines
  - [ ] Execution flow (§4) records decision points, even where nothing checks them yet
  - [ ] State and side effects (§5) list every file read and written, with idempotency stated
  - [ ] **Every verification level in §6 marked Applicable or N/A with a reason**
  - [ ] Code seam (§7) specified for a mixed feature, or the section removed for a pure-instruction one
  - [ ] No placeholder text remaining anywhere in the document
- [ ] **Verify Invariants Held**:
  - [ ] The template was **not** forked by instruction kind
  - [ ] No instruction artifact was labelled with a medium of its own (artifacts inherit from the feature)
  - [ ] Shipped instruction artifacts are placed under the project's configured source directory and carry no document ID
- [ ] **Verify State File Updates**:
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Status **AUTOMATICALLY UPDATED** past the instruction gate
  - [ ] Per-feature state file §4 Documentation Inventory contains the Instruction Design row
  - [ ] [PD-documentation-map.md](../../../doc/PD-documentation-map.md) regenerated and `-Check`-clean; contains the new document's entry
- [ ] **Complete Human-Partner Review**: inventory with kind justifications, contract, decision points, and verification plan reviewed and approved
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-094`, context "Instruction Design".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `doc/technical/design/instruction/features/instruction-design-<id>-<slug>.md` | [`New-InstructionDesign.ps1`](../../scripts/file-creation/02-design/New-InstructionDesign.ps1) | New `PD-IND` document from [the template](../../templates/02-design/instruction-design-template.md) |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | [`New-InstructionDesign.ps1`](../../scripts/file-creation/02-design/New-InstructionDesign.ps1) | Advances Status past the instruction gate (`📝 Needs TDD` / `🔧 Needs Impl Plan`) |
| **Updates** | `doc/state-tracking/features/<id>-implementation-state.md` | [`New-InstructionDesign.ps1`](../../scripts/file-creation/02-design/New-InstructionDesign.ps1) | Inserts the Instruction Design row into §4 Documentation Inventory |
| **Updates** | [`PD-documentation-map.md`](../../../doc/PD-documentation-map.md) | [`Build-DocumentationMap.ps1 -Tree PD`](../../scripts/validation/Build-DocumentationMap.ps1) | Picks up the new document's `description:` (generated DO-NOT-EDIT projection) |

## Next Tasks

- **[TDD Creation](tdd-creation-task.md)** (PF-TSK-015) — Tier 2+: the terminal document integrates this dimension with the feature's code dimensions
- **[Feature Implementation Planning](../04-implementation/feature-implementation-planning-task.md)** (PF-TSK-044) — Tier 1: skips TDD; the Artifact Inventory decomposes directly into implementation steps
- **[Test Specification Creation](../03-testing/test-specification-creation-task.md)** (PF-TSK-012) — consumes the §6 verification plan and the Level 3 fixture design

### Prerequisites for Transition

- [ ] Instruction Design document created via [New-InstructionDesign.ps1](../../scripts/file-creation/02-design/New-InstructionDesign.ps1) (`PD-IND-NNN`)
- [ ] Artifact Inventory filled — every artifact has a kind and a justification
- [ ] Instruction contract, execution flow, and state/side-effects sections complete
- [ ] Every verification level marked Applicable or N/A with a reason
- [ ] Feature Tracking Status advanced past the instruction gate (automated by script)
- [ ] Instruction Design row present in the per-feature state file's §4 Documentation Inventory (automated by script)
- [ ] Human partner approved the customized design at the Execution checkpoint

### Next Task Selection

```
Is a TDD required for this feature (Tier 2+)?
├─ Yes → TDD Creation
│   └─ Reason: the terminal document integrates the instruction dimension with the code dimensions;
│      for a pure-instruction feature it is created in its instruction-shaped form
└─ No (Tier 1) → Feature Implementation Planning
    └─ Reason: Tier 1 skips TDD; the Artifact Inventory is already an implementation decomposition
```

If the design surfaces code needs that were not anticipated upstream:

- → **API Design** (PF-TSK-020) — when the §7 code seam implies a contract not yet specified
- → **Database Schema Design** (PF-TSK-021) — when the instructions read or write state not yet modeled

### Preparation for Next Task

1. Confirm the Design Handoff Checklist (§9) is fully checked
2. Confirm the terminal design document will carry an Instruction Design Reference pointing at this `PD-IND`
3. Verify the §4 Documentation Inventory row points at the created document
4. Carry the §6 verification plan forward to Test Specification Creation, and the §4.2 decision points forward as the inputs a future judgment-level check would consume

## Related Resources

### Core Inputs

- [Instruction Design Template](../../templates/02-design/instruction-design-template.md) — the structure the script populates; its instructional comments carry the authoring craft
- [New-InstructionDesign.ps1](../../scripts/file-creation/02-design/New-InstructionDesign.ps1) — document creation script
- [Feature Granularity Guide](../../guides/01-planning/feature-granularity-guide.md) — the general granularity tests the entry-point rule specializes

### Related Tasks

- [Feature Request Evaluation](../01-planning/feature-request-evaluation.md) (PF-TSK-067) — upstream: its embedded tier assessment declares the medium and opens this gate
- [FDD Creation Task](fdd-creation-task.md) (PF-TSK-027) — upstream input for Tier 2+
- [TDD Creation Task](tdd-creation-task.md) (PF-TSK-015) — downstream consumer
- [UI Design](ui-design-task.md) (PF-TSK-090) · [API Design](api-design-task.md) (PF-TSK-020) · [Database Schema Design](database-schema-design-task.md) (PF-TSK-021) — sibling design dimensions
- [Framework Rollout](../support/framework-rollout-task.md) (PF-TSK-088) — Mode C drains the `PD-IND` registry migration this task's script depends on
