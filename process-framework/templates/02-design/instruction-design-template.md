---
id: PF-TEM-107
type: Process Framework
category: Template
version: 1.6
created: 2026-08-04
updated: 2026-08-05
creates_document_category: Instruction Design
creates_document_prefix: PD-IND
creates_document_type: Product Documentation
creates_document_version: 1.0
description: Template for creating Instruction Design Documents (PD-IND) - the fourth design dimension artifact for features whose deliverable includes instruction artifacts an agent executes
template_for: Instruction Design
usage_context: Product Documentation - Instruction Design Creation
---

# [Feature Name] - Instruction Design Document

## Feature Overview

- **Feature ID**: [Feature ID]
- **Feature Name**: [Feature Name]
- **Medium**: declared by the feature, not here — read it from the tier assessment's `## Implementation Medium` section, carried forward in the implementation state file §2. <!-- Deliberately a POINTER, never a copy: medium is declared at exactly two levels and artifacts inherit it. A third hand-maintained copy is the `primary_language` / `testing.language` duplication this extension cites as its counter-example. -->
- **Instruction Entry Point**: [The one independently-invocable entry point this feature owns — see §1.2]
- **Design Scope**: [Feature Description]
- **Design Status**: 📜 Draft / 👀 Review / ✅ Approved

## Related Documentation

> **Note**: An Instruction Design Document specifies the parts of a feature whose deliverable is **instructions an agent executes**, not program code. It is the fourth design dimension, sibling to UI Design, API Design and Database Schema Design. A **mixed** feature carries this document *alongside* its code design documents; the terminal design document (TDD or Implementation Plan) references all of them.

### Functional Design Reference

> **📋 Primary Documentation**: FDD Creation Task (PF-TSK-027)
> **🔗 Link**: [Functional Design Document - PD-FDD-XXX] > **👤 Owner**: FDD Creation Task
>
> **Purpose**: The FDD defines what the feature does and why. This document translates the instruction-medium parts of those requirements into an executable procedure and its supporting artifacts.

**Key Functional Requirements Served by Instructions**:

- [Functional requirement this procedure delivers]
- [Judgment or decision the requirement demands of the executing agent]

### Terminal Design Reference

> **📋 Primary Documentation**: TDD Creation Task (PF-TSK-015) — or Feature Implementation Planning (PF-TSK-044) for Tier 1
> **🔗 Link**: [Technical Design Document - PD-TDD-XXX] > **👤 Owner**: TDD Creation Task
>
> **Purpose**: The terminal document integrates every design dimension. For a **pure-instruction** feature it is the instruction-shaped terminal; for a **mixed** feature it is the code TDD carrying an Instruction Design Reference section pointing here.

### Sibling Design References (mixed features only — remove if pure instruction)

<!-- A mixed feature's code half has its own dimension artifacts. Name only those that exist. -->

- **UI Design**: [PD-UIX-XXX] — [what the instruction half consumes from it, or "N/A"]
- **API Design**: [PD-API-XXX] — [contract the instructions invoke, or "N/A"]
- **Database Schema Design**: [PD-SCH-XXX] — [state the instructions read/write, or "N/A"]

---

## 1. Design Overview

### 1.1 Purpose & Executing Agent

<!--
State who or what executes these instructions. This is the medium test: instructions are
executed by an AGENT (human or AI) reading them. A prompt or template consumed by your own
code is code's data, not the instruction medium.
-->

- **Executed by**: [AI agent / human operator / either]
- **Invoked how**: [slash command, task selection, direct read, chained from another entry point]
- **What "done" means**: [the observable end state a successful execution produces]

### 1.2 Entry Point Definition

<!--
The feature-granularity rule for instruction work (PF-PRO-064, O-5):

  A feature is ONE independently-invocable instruction entry point plus every artifact that
  exists to serve it — its guides, templates, craft skill, and helper scripts. A second entry
  point that a user or agent would select independently is a SECOND feature.

Artifacts serving several entry points route by the existing shared-utility rule: assign to
the entry point they most closely support; create a shared-infrastructure feature once they
exceed ~3 files / ~300 lines with cross-feature impact.
-->

- **This feature's entry point**: [name it]
- **Adjacent entry points deliberately excluded**: [name them and the feature that owns each, or "none"]
- **Shared artifacts consumed but not owned**: [artifact → owning feature, or "none"]

### 1.3 Design Constraints

- [Constraint imposed by the executing agent's capabilities or context budget]
- [Constraint imposed by existing framework/product conventions this must obey]
- [Constraint imposed by the artifacts this feature does not own]

---

## 2. Artifact Inventory 🚨 REQUIRED

<!--
MANDATORY SECTION — do not remove.

This inventory is why the design document exists: instruction KIND becomes an authored design
decision instead of an implementation accident. Name every planned instruction artifact, its
kind, and a one-line justification for that kind.

This template is deliberately KIND-AGNOSTIC (a declared invariant of PF-PRO-064): kind is a
FIELD in this table, never a template fork. Do not create per-kind variants of this template.

Shipped instructions are SOURCE: they live under the project's configured source directory
(`paths.source_code` in project-config.json), typically `src/<feature>/`, and carry NO document
ID. Only this design document carries an ID (PD-IND).
-->

| # | Artifact | Kind | Path (under `src/<feature>/`) | Purpose | Why this kind |
|---|----------|------|-------------------------------|---------|---------------|
| 1 | [file name] | [Task] | [path] | [one line] | [why a task and not a guide] |
| 2 | [file name] | [Guide] | [path] | [one line] | [why a guide and not task prose] |
| 3 | [file name] | [Template] | [path] | [one line] | [what it is instantiated into] |

### Instruction Kinds Reference

<!-- The framework's own taxonomy. Choose from these; add a row above only with justification. -->

| Kind | What it is | Choose when |
|------|-----------|-------------|
| **Task** | A selectable procedure with steps, checkpoints, and a completion contract | The agent needs to *do* a bounded unit of work end to end |
| **Guide** | Agnostic reference consulted during work — decision criteria, lookup tables, conventions | Content is consulted, not executed in sequence |
| **Template** | A structure instantiated into a produced artifact | The output is a document with a repeatable shape |
| **Craft skill** | The judgment half of a task, activated by that task's recommended-skills step | Craft is coupled to an agent and would bloat the task's happy path |
| **Path / variant companion** | A branch file a parent selects between (`variant_group` frontmatter, no ID, no `use_when`) | One procedure has genuinely divergent modes |
| **Edge-case file** | Consult-on-stumble incident record (two-zone convention) | Rare-situation lore that must not bloat the core happy path |

### Artifacts Deliberately Not Created

<!-- Record what was considered and rejected. This is what keeps the inventory honest. -->

- [Artifact considered] — [why it is not needed, or which existing artifact covers it]

---

## 3. Instruction Contract

### 3.1 Inputs & Preconditions

| Input | Source | Required? | Precondition checked how |
|-------|--------|-----------|--------------------------|
| [input] | [where it comes from] | [Yes/No] | [how the instruction verifies it before proceeding] |

### 3.2 Outputs & Postconditions

| Output | Destination | Postcondition |
|--------|-------------|---------------|
| [artifact or state change] | [path or tracker] | [what must be true afterward] |

### 3.3 Referenced Scripts, Paths & Parameters

<!--
This subsection is the L2 (instruction contract) verification surface. Every entry here is a
name the instruction asserts exists. Keep invocation lines exact — they are checked
mechanically, and a wrong path or parameter is exactly the drift L2 catches.
-->

| Referenced thing | Exact reference | Must exist because |
|------------------|-----------------|--------------------|
| [script] | `[full invocation line]` | [the step that runs it] |
| [cross-document step reference] | [document → Step N] | [what depends on it] |

---

## 4. Execution Flow

### 4.1 Step Structure

<!-- Outline the procedure's shape. Full step text belongs in the artifact, not here. -->

1. [Phase or step group] — [what it accomplishes]
2. [Phase or step group] — [what it accomplishes]

### 4.2 Decision Points & Judgment Calls

<!--
Each row is a place where the agent must decide rather than follow. These are the inputs to
Level 4 (judgment) verification — designed but not yet built — so record them even though
nothing checks them today.
-->

| Decision point | What is being judged | What makes a defensible call |
|----------------|----------------------|------------------------------|
| [step] | [the judgment] | [the criteria a reviewer would apply] |

### 4.3 Checkpoints & Human Interaction

| Checkpoint | Blocking? | What is presented | What approval unblocks |
|------------|-----------|-------------------|------------------------|
| [name] | [Yes/No] | [material] | [subsequent work] |

### 4.4 Failure & Recovery Behavior

- **When a precondition fails**: [stop / warn / substitute — and how the agent knows]
- **When a step's output is wrong**: [detection and recovery]
- **Partial-completion state**: [what is left behind, and how a later run resumes]

---

## 5. State & Side Effects

| File / tracker | Read | Written | Notes |
|----------------|------|---------|-------|
| [path] | [Yes/No] | [Yes/No] | [mutation shape, e.g. table row append] |

- **Idempotency**: [is a second run safe? what changes?]
- **Concurrency**: [what happens if two agents run this at once]

---

## 6. Verification Plan

<!--
The instruction verification stack. Mark each level Applicable / N/A with a reason — an
unmarked level is an unresolved design decision, not an omission.

Level 1 is INHERITED, not built: the framework's static tooling already covers shipped
instruction artifacts. The one thing it asks of this design is that every artifact in the
§2 inventory carries a `description:` frontmatter line — that is what the Source Code
Documentation Map indexes, and an artifact without one is rendered as a gap in it.
-->

| Level | Verifies | Applicability here | How |
|-------|----------|--------------------|-----|
| **1 · Static** | Links, IDs, frontmatter, generated maps | [Applicable / N/A] | LinkWatcher `--validate` + `Build-DocumentationMap.ps1 -Tree SC -Check` (the Source Code Documentation Map's description-drift gate) |
| **2 · Instruction contract** | That what an instruction *names* exists | [Applicable / N/A] | `Check-InstructionContract.ps1 -Path <shipped artifacts' directory>` (invocation lines, cross-document step refs, parameter names) over [the §3.3 surface] |
| **3 · Execution** | Agent + instruction + fixture → asserted end state | [Applicable / N/A] | [fixture description] |
| **4 · Judgment** | Whether a required judgment call was defensible | Designed only | [the §4.2 decision points are its inputs] |

### 6.1 Level 3 Fixture Design (if applicable)

<!--
The fixture is run through the E2E acceptance-test harness, with one inversion that matters:
the AGENT is the actor, so the assertions cannot live in the thing being tested. They go in a
shipped assert script that runs after the agent. Pattern and worked example:
`.claude/skills/e2e-test-case-creation/references/instruction-fixtures.md`.
-->

- **Fixture**: [the starting state the agent is handed]
- **Invocation**: [exactly how the instruction is run against it]
- **Assertions**: [the end-state facts checked, and what asserts them]

---

## 7. Code Interfaces (mixed features only — remove if pure instruction)

<!--
Where the instruction half meets the code half. Name the seam explicitly: it is the part most
likely to be assumed rather than designed.
-->

| Interface | Direction | Contract |
|-----------|-----------|----------|
| [script or module] | [instruction calls code / code reads instruction output] | [parameters, exit codes, file format] |

---

## 8. Implementation Notes

- **Authoring order**: [which artifact is written first and why]
- **Reused conventions**: [existing patterns this follows rather than reinventing]
- **Known risks**: [what is most likely to be got wrong in implementation]

---

## 9. Design Handoff Checklist

- [ ] Every artifact in the §2 inventory has a kind and a justification
- [ ] The entry point (§1.2) is named, and excluded adjacent entry points are recorded
- [ ] The §3.3 reference table lists every script, path and parameter the instructions assert
- [ ] Every verification level in §6 is marked Applicable or N/A **with a reason**
- [ ] Decision points (§4.2) are recorded even where nothing checks them yet
- [ ] For a mixed feature: §7 names the code seam, and the terminal document references this document
- [ ] Reviewed and approved by the human partner

---

## Appendix A. Design Decisions Log

| Date | Decision | Alternatives considered | Rationale |
|------|----------|-------------------------|-----------|
| [Date] | [what was decided] | [what else was on the table] | [why] |

## Custom Sections (as needed)

<!-- Add feature-specific sections here. Do not fork this template by instruction kind. -->
