---
id: PF-TEM-101
type: Process Framework
category: Proposal
version: 1.1
created: [Created Date]
updated: [Created Date]
extension_name: [Extension Name]
extension_description: [Extension Description]
extension_scope: [Extension Scope]
mode: pattern
variant_group: framework-extension-concept-templates
variant_siblings:
  - framework-extension-concept-template.md
  - framework-extension-concept-creation-template.md
  - framework-extension-concept-modification-template.md
  - framework-extension-concept-minimal-template.md
creates_document_type: Process Framework
creates_document_category: Proposal
description: "Pattern/architecture template for cross-cutting extensions that introduce a convention or pattern — lighter than the Hybrid template, omitting the per-task numbered-step process skeleton and the fixed multi-session plan; used by New-FrameworkExtensionConcept.ps1 -Pattern"
---

# [Extension Name] - Framework Extension Concept (Pattern)

## Document Metadata
| Metadata | Value |
|----------|-------|
| Document Type | Framework Extension Concept (Pattern) |
| Created Date | [Created Date] |
| Status | Awaiting Human Review |
| Extension Name | [Extension Name] |
| Extension Scope | [Extension Scope] |
| Extension Type | [Creation / Modification / Hybrid] |
| Author | [Author] |

---

> **Pattern / architecture extension.** This variant is for a cross-cutting *pattern, convention, or architecture* that touches many existing artifacts rather than adding one new task with a numbered process. It deliberately omits the per-task Core Process numbered-step skeleton and the fixed multi-session plan: describe the pattern as it executes, and structure the roadmap to the work you actually have.

---

## 🎯 Purpose & Context

**Brief Description**: [Extension Description]

### Extension Overview
[What pattern, convention, or architecture this introduces, and why the existing framework doesn't already express it. State the value hypothesis explicitly — what improves, and at what cost.]

### Key Distinction from Existing Framework Components

| Existing Component | Purpose | Scope |
|-------------------|---------|-------|
| **Structure Change Task** | Reorganizes existing framework components | Rearrangement of current elements |
| **Process Improvement Task** | Makes granular improvements to existing processes | Optimization of current workflows |
| **New Task Creation Process** | Creates individual new tasks | Single task creation |
| **[Extension Name]** *(This Extension)* | **[Describe the pattern's unique purpose]** | **[Describe the cross-cutting pattern/convention scope]** |

## 🔍 When to Use This Pattern

This pattern applies when:

- **[Condition 1]**: [When the pattern should be used]
- **[Condition 2]**: [Another trigger condition]
- **[Condition 3]**: [Additional condition]

### Non-candidates
- [Where the pattern explicitly does NOT apply — state this so the pattern isn't over-applied]

## 🔎 Existing Project Precedents

> **Before designing the pattern**, study how the project already handles similar or analogous cases. This prevents reinventing patterns that exist and ensures the extension builds on proven approaches.

| Precedent | Where It Lives | What It Does | How It Relates to This Pattern |
|-----------|---------------|--------------|---------------------------------|
| [Existing pattern/workflow 1] | [File path or component] | [What it accomplishes] | [Reuse opportunity, gap it doesn't cover, or contrast] |
| [Existing pattern/workflow 2] | [File path or component] | [What it accomplishes] | [Reuse opportunity, gap it doesn't cover, or contrast] |

**Key takeaways**: [What the project already does well, what gaps remain, and what to reuse vs. replace]

## 🔌 Interfaces to Existing Framework

> A cross-cutting pattern touches many surfaces — make every touchpoint explicit.

### Task Interfaces

| Existing Task | Interface Type | Description |
|--------------|----------------|-------------|
| [Task name (ID)] | Upstream input / Downstream consumer / Modified by extension | [What data or artifacts flow between this task and the pattern] |
| [Task name (ID)] | Upstream input / Downstream consumer / Modified by extension | [What data or artifacts flow between this task and the pattern] |

### State File Interfaces

| State File | Read / Write / Both | What the Extension Uses or Updates |
|-----------|---------------------|-----------------------------------|
| [State file name] | [Read / Write / Both] | [Specific fields, sections, or entries affected] |

### Artifact Interfaces

| Existing Artifact | Relationship | Description |
|------------------|--------------|-------------|
| [Artifact type/name] | Input to extension / Updated by extension / Referenced by extension | [How the pattern uses or affects this artifact] |

## 🏗️ Core Pattern: How It Works

> Describe the pattern as it executes — the division of responsibilities, the rule(s) it establishes, and how a unit of work flows through it. Use whatever structure fits (roles, phases, before/after). Do **not** force a fixed numbered task-process here.

[Narrative or short phase description of the pattern in action. Example shape:]

- **[Role / Owner A]** — [what it owns under the pattern]
- **[Role / Owner B]** — [what it owns]
- **[Rule / invariant]** — [the load-bearing convention the pattern establishes]

### Pattern Invariants & Constraints

- **[Invariant 1]**: [A rule the pattern must preserve — e.g. agent-agnostic core, backward compatibility]
- **[Invariant 2]**: [Another constraint]

## 🔗 Integration with Task-Based Development Principles

- **Task Granularity**: [How the pattern preserves or affects session-sized work]
- **State Tracking**: [How state ownership is affected]
- **Artifact Management**: [How artifact ownership/placement is affected]
- **Task Handover**: [How cross-session handover is affected]
- **Agent-agnostic core**: [Whether the pattern keeps the portable `process-framework/` core clean; flag any agent coupling it introduces]

## 🔄 Affected Artifacts & Modifications

> A pattern extension is mostly *modification* of existing artifacts plus a small number of new ones. List both, and record how the affected set was found.

### Modifications to Existing Artifacts

| Artifact (file) | Current Behavior / Content | Modification Needed | Backward Compatible? |
|-----------------|----------------------------|---------------------|----------------------|
| [File 1] | [What it does/says now] | [What changes] | Yes / No — [migration note if No] |
| [File 2] | [What it does/says now] | [What changes] | Yes / No — [migration note if No] |

**Discovery method**: [How the affected-artifact list was found — e.g. grep for a task ID / convention name / file path across `blueprint/`]

### New Artifacts Created (if any)

| Artifact Type | Name | Directory | Purpose |
|---------------|------|-----------|---------|
| [Type] | [Name] | [Directory] | [Purpose] |

> **Design checklist** — for each new artifact: who **references** it, who **creates** it, who **updates** it (and on what trigger).

### State Tracking Impact

- **New permanent state files**: [None / list — if any, complete the State File Locality Pre-Flight from the Hybrid template before assigning IDs]
- **Updates to existing state files**: [Which state files gain entries/fields, and when]

## 🔧 Implementation Roadmap (adaptive)

> Structure this to the *actual* shape of the work — a pilot + backlog, a single session, or N phases. Do **not** pad to a fixed session count. If the pattern is unproven, prefer a **pilot** (one adopter) before broad rollout (PF-PRO-030).

### Pilot vs. Full Rollout (PF-PRO-030)

**Decision**: [PILOT / FULL ROLLOUT] — [rationale: does the pattern's failure mode only show in real use?]

- **Adopter (if pilot)**: [The single artifact/task that adopts the pattern first]
- **Success criteria**: [Observable signals the pattern works]
- **Decision trigger (if pilot)**: [What/when drives the rollout-or-rollback decision]

### Work Items

| # | Work Item | Scope (Pilot / Rollout) | Priority |
|---|-----------|-------------------------|----------|
| 1 | [Item] | [Pilot / Rollout] | HIGH / MEDIUM / LOW |
| 2 | [Item] | [Pilot / Rollout] | HIGH / MEDIUM / LOW |

> **Framework integration reminder** — after implementation, regenerate any affected generated projections (PF/PD/TE documentation maps via `Build-DocumentationMap.ps1`; task metadata via `Build-TaskMetadata.ps1`) and add ID-registry prefixes if the pattern introduces new file types.

## 🎯 Success Criteria

### Functional Success Criteria
- [ ] **[Criterion 1]**: [What success looks like for the pattern]
- [ ] **[Criterion 2]**: [...]

### Quality Success Criteria
- [ ] **Consistency**: The pattern is applied uniformly wherever it claims to apply
- [ ] **No regression**: Existing workflows that touch the affected artifacts still work
- [ ] **[Invariant preserved]**: [e.g. agent-agnostic core intact — if applicable]

### Human Collaboration Requirements
- [ ] **Concept Approval**: Mandatory human review and approval before implementation
- [ ] **Scope Validation**: The pattern truly warrants a framework-level change (not a single Process Improvement / Structure Change)

## 📝 Next Steps

1. **Human Review**: This concept requires human review and approval
2. **Create Temporary State Tracking File**: Use `New-TempTaskState.ps1` for multi-session tracking (if the roadmap spans sessions)
3. **Plan the first work item** (the pilot adopter first, if piloting)

---

## 📋 Human Review Checklist

**This concept requires human review before implementation can begin!**

### Concept Validation
- [ ] **Pattern Necessity**: A cross-cutting pattern is genuinely warranted (vs. a one-off Process Improvement / Structure Change)
- [ ] **Scope Appropriateness**: The pattern's reach is well-bounded
- [ ] **Precedent Reuse**: Builds on existing precedents rather than reinventing
- [ ] **Invariants Preserved**: Load-bearing constraints (agnosticism, backward compatibility) are respected

### Technical Review
- [ ] **Affected-Artifact Completeness**: The modification list was found by a documented discovery method
- [ ] **Pilot Definition** (if piloting): adopter / success criteria / decision trigger are clear
- [ ] **Backward Compatibility**: Migration is noted for any non-compatible change

### Approval Decision
- [ ] **APPROVED**: Concept is approved for implementation
- [ ] **NEEDS REVISION**: Concept needs changes before approval
- [ ] **NOT ADOPTED**: Declined on current evidence — record falsifiable re-open conditions in the concept and archive it to proposals/old/ as the evaluation record

**Human Reviewer**: [Name]
**Review Date**: [Date]
**Decision**: [APPROVED/NEEDS REVISION/NOT ADOPTED]
**Comments**: [Review comments and feedback]

---

*This concept document was created using the Framework Extension Concept Pattern Template as part of the Framework Extension Task (PF-TSK-026).*
