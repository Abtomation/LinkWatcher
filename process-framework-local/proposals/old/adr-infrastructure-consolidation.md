---
id: PF-PRO-019
type: Document
category: General
version: 1.0
created: 2026-04-12
updated: 2026-04-12
extension_scope: ADR task retirement, tracking consolidation, parent task updates, script cleanup
extension_name: ADR Infrastructure Consolidation
extension_description: Retire standalone ADR task, embed ADR creation inline in parent tasks, consolidate tracking in architecture-tracking.md
---

# ADR Infrastructure Consolidation - Framework Extension Concept

## Document Metadata
| Metadata | Value |
|----------|-------|
| Document Type | Framework Extension Concept |
| Created Date | 2026-04-12 |
| Status | Awaiting Human Review |
| Extension Name | ADR Infrastructure Consolidation |
| Extension Scope | ADR task retirement, tracking consolidation, parent task updates, script cleanup |
| Author | AI Agent & Human Partner |
| Origin | PF-EVR-013 (Framework Evaluation: ADR infrastructure and architecture feature separation) |
| Related IMPs | PF-IMP-487 (reject), PF-IMP-488 (keep), PF-IMP-491 (already done) |

---

## 🔀 Extension Type

**Selected Type**: Modification

This extension modifies existing artifacts exclusively — it retires a task, updates parent tasks, modifies a script, and restructures tracking. No new tasks, templates, or guides are created.

---

## 🎯 Purpose & Context

**Brief Description**: ADR creation is currently a standalone task (PF-TSK-028) that wraps what is always an inline activity within another task. Every ADR trigger is downstream of Foundation Implementation, System Architecture Review, Code Refactoring, Bug Fixing, or Validation. The task adds ceremony (checkpoints, feedback form) without proportional value — the script, guide, and quality checklist already provide the necessary guardrails. Meanwhile, ADR tracking is inconsistently scoped: the ADR column exists only in the 0.x feature table despite ADRs having an N:M relationship with features.

### Extension Overview

This extension consolidates ADR infrastructure by:
1. Retiring PF-TSK-028 as a standalone task
2. Embedding ADR creation as an inline step in parent tasks (referencing both script and guide as it is with the feedback form)
3. Removing the ADR column from feature-tracking.md (N:M relationship makes per-feature columns misleading)
4. Establishing architecture-tracking.md ADR Index as the sole authoritative ADR registry
5. Reworking architecture-tracking.md to better serve its cross-cutting role
6. Cleaning up the New-ArchitectureDecision.ps1 script to stop updating feature-tracking.md

### Key Distinction from Existing Framework Components

| Existing Component | Purpose | Scope |
|-------------------|---------|-------|
| **Structure Change Task** | Reorganizes existing framework components | Rearrangement of current elements |
| **Process Improvement Task** | Makes granular improvements to existing processes | Optimization of current workflows |
| **ADR Infrastructure Consolidation** *(This Extension)* | **Retires a task and restructures how ADR creation and tracking work across the framework** | **Cross-cutting modification of task definitions, state files, scripts, and registries** |

### Rationale

**Industry alignment**: Nygard, arc42, GOV.UK, and AWS all treat ADRs as lightweight artifacts created at the moment of decision — not as a separate ceremony. The framework should align with this practice.

**N:M relationship**: ADRs have a many-to-many relationship with features. One ADR can span multiple features; one feature can have multiple ADRs; some ADRs are project-wide with no specific feature. A per-feature column in feature-tracking.md cannot represent this accurately. A flat, cross-cutting ADR Index in architecture-tracking.md can.

**Existing patterns already work**: The 3 tasks that create ADRs most frequently (Foundation Feature Implementation, System Architecture Review, Code Refactoring Standard Path) already embed ADR creation as an inline step with direct script calls. PF-TSK-028 adds a redundant layer.

## 🔎 Existing Project Precedents

| Precedent | Where It Lives | What It Does | How It Relates to This Extension |
|-----------|---------------|--------------|----------------------------------|
| Foundation Feature Implementation inline ADR step | PF-TSK-043 line 75 | Creates ADRs inline during implementation using script directly | Validates the pattern — already bypasses PF-TSK-028 |
| System Architecture Review inline ADR step | PF-TSK-082 line 116 | Creates ADRs inline during review using script directly | Same pattern — task-switch to PF-TSK-028 never happens |
| Code Refactoring Standard Path inline ADR step | PF-TSK-022 lines 77-84 | Creates ADRs inline during refactoring | Same pattern |
| New-ArchitectureDecision.ps1 auto-updates | Script lines 170-228 | Already auto-updates architecture-tracking.md ADR Index | Automation for IMP-491 already exists; 3 existing ADRs just predate it |

**Key takeaway**: The inline pattern is already the de facto standard for ADR creation. PF-TSK-028 exists as a formality that no task actually switches to in practice.

## 🔌 Interfaces to Existing Framework

### Task Interfaces

| Existing Task | Interface Type | Description |
|--------------|----------------|-------------|
| Foundation Feature Implementation (PF-TSK-043) | Modified by extension | Add guide reference to existing inline ADR step |
| System Architecture Review (PF-TSK-082) | Modified by extension | Add guide reference to existing inline ADR step |
| Code Refactoring Standard Path (PF-TSK-022) | Modified by extension | Add guide reference to existing inline ADR step |
| Bug Fixing (PF-TSK-006) | Modified by extension | Change from "recommend PF-TSK-028" to inline ADR creation with script + guide |
| Core Logic Implementation (PF-TSK-057) | Modified by extension | Change from "recommend PF-TSK-028" to inline ADR creation with script + guide |
| Architectural Consistency Validation (PF-TSK-031) | Modified by extension | Change from "recommend PF-TSK-028" to "recommend ADR creation using script + guide" |
| Retrospective Documentation Creation (PF-TSK-066) | Modified by extension | Change from "Use ADR Creation Task" to "Create ADR using script + guide" |
| Documentation Alignment Validation (PF-TSK-035) | Consumer (read-only) | References ADR guide — update link if PF-TSK-028 reference exists |
| Task Transition Guide (PF-GDE-019) | Modified by extension | Remove "Transitioning FROM ADR Creation" section (lines 1733-1760); update "Architectural decisions → ADR Creation" redirect (line 345); remove ADR column reference (line 1451) |

### State File Interfaces

| State File | Read / Write / Both | What the Extension Uses or Updates |
|-----------|---------------------|-----------------------------------|
| feature-tracking.md | Write | Remove ADR column from 0.x table; remove ADR note from line 50 |
| architecture-tracking.md | Write | Populate ADR Index with 3 existing ADRs; rework structure for cross-cutting role |

### Artifact Interfaces

| Existing Artifact | Relationship | Description |
|------------------|--------------|-------------|
| adr-creation-task.md (PF-TSK-028) | Deleted by extension | Task file retired |
| adr-creation-map.md (context map) | Deleted by extension | Context map for retired task |
| ai-tasks.md | Updated by extension | Remove ADR Creation from task table and workflow strings |
| PF-documentation-map.md | Updated by extension | Remove PF-TSK-028 entry; remove context map entry |
| Process Framework Task Registry | Updated by extension | Remove Section 9 (ADR Creation Task) |
| Task Trigger & Output Traceability | Updated by extension | Remove PF-TSK-028 entry |
| Architecture Decision Creation Guide | Updated by extension | Remove any PF-TSK-028 references |
| New-ArchitectureDecision.ps1 | Updated by extension | Remove feature-tracking ADR column update logic |
| tasks/README.md | Updated by extension | Remove ADR Creation entry |

---

## 🔄 Modification-Focused Sections

### State Tracking Audit

| State File | Current Purpose | Modification Needed | Change Type |
|-----------|-----------------|---------------------|-------------|
| feature-tracking.md | Tracks feature status including ADR column in 0.x table | Remove ADR column from 0.x table; remove ADR mention from design status branching note (line 50) | Remove field |
| architecture-tracking.md | Cross-cutting architectural state (mostly empty) | Populate ADR Index with 3 ADRs; rework document structure to better serve as authoritative ADR registry | Modify schema |

**Cross-reference impact**:
- `New-ArchitectureDecision.ps1` writes to both state files — feature-tracking write logic must be removed
- `Update-FeatureImplementationState.ps1` may reference ADR column — needs verification
- `Validate-StateTracking.ps1` may parse ADR column in feature tables — needs verification

### Guide Update Inventory

| File to Update | References To | Update Needed |
|---------------|---------------|---------------|
| Foundation Feature Implementation (PF-TSK-043) | ADR template in Context Requirements; inline ADR step at line 75 | Add guide reference: "Follow the [Architecture Decision Creation Guide](guide-path) for content customization" |
| System Architecture Review (PF-TSK-082) | Inline ADR step at line 116; ADR index update at line 129 | Add guide reference alongside script call |
| Code Refactoring Standard Path (PF-TSK-022) | Inline ADR step at lines 77-84 | Add guide reference alongside script call |
| Bug Fixing (PF-TSK-006) | "recommend PF-TSK-028 as follow-up" at line 150 | Replace with inline: "If the fix changed architectural behavior or introduced a new pattern, create an ADR using [New-ArchitectureDecision.ps1](script-path) and the [Architecture Decision Creation Guide](guide-path)" |
| Core Logic Implementation (PF-TSK-057) | "recommend PF-TSK-028 as follow-up" at line 118 | Same pattern as Bug Fixing |
| Architectural Consistency Validation (PF-TSK-031) | "recommend PF-TSK-028" at line 76 | Replace with: "recommend creating an ADR using [New-ArchitectureDecision.ps1](script-path) and the [Architecture Decision Creation Guide](guide-path)" |
| Retrospective Documentation Creation (PF-TSK-066) | "Use ADR Creation Task" at line 177 | Replace with: "Create ADR using [New-ArchitectureDecision.ps1](script-path) following the [Architecture Decision Creation Guide](guide-path)" |
| Architecture Decision Creation Guide (PF-GDE-033) | `related_task: PF-TSK-019` in frontmatter; references PF-TSK-019 in Related Resources | Remove `related_task` field (guide is now standalone, not bound to one task); update Related Resources |
| Task Transition Guide (PF-GDE-019) | "Transitioning FROM ADR Creation" section (lines 1733-1760); "Architectural decisions → ADR Creation" at line 345; "ADR column" at line 1451 | Remove "Transitioning FROM ADR Creation" section entirely; change line 345 to reference inline ADR creation via script + guide; remove ADR column reference at line 1451 |
| ai-tasks.md | ADR Creation row in 02-Design table; `[ADR Creation]` in 2 workflow strings | Remove table row; remove from workflow strings |
| PF-documentation-map.md | PF-TSK-028 under 02-Design Tasks; adr-creation-map under context maps | Remove both entries |
| Process Framework Task Registry | Section 9: ADR Creation Task | Remove entire section |
| Task Trigger & Output Traceability | PF-TSK-028 entry | Remove entry |
| tasks/02-design/README.md (if exists) | ADR Creation listing | Remove entry |
| tasks/README.md | ADR Creation in task list | Remove entry |

**Discovery method**: `grep -r "ADR\|PF-TSK-028" process-framework/tasks/` across 22 matching files, then categorized by usage pattern.

### Automation Integration Strategy

| Existing Script | Current Behavior | Required Change | Backward Compatible? |
|----------------|-----------------|-----------------|---------------------|
| New-ArchitectureDecision.ps1 | Updates feature-tracking.md ADR column (lines 75-122) AND architecture-tracking.md ADR Index (lines 170-228) | Remove feature-tracking update logic (lines 75-122); keep architecture-tracking update logic | Yes — script still creates ADRs; feature-tracking update was best-effort anyway |
| Update-FeatureImplementationState.ps1 | May reference ADR column | Verify and remove if present | Needs verification |
| Validate-StateTracking.ps1 | May parse feature-tracking ADR column | Verify and remove if present | Needs verification |

**New automation needed**: None — existing script (New-ArchitectureDecision.ps1) already handles architecture-tracking.md updates.

---

## architecture-tracking.md Rework

### Current Problems

The current architecture-tracking.md has several issues beyond the empty ADR Index:
1. **Empty tables**: Current Architecture State and Architecture Sessions Summary are completely empty and have never been populated
2. **Unclear role**: The "Relationship to Feature Tracking" section describes it as a "reference and summary document" but it doesn't actually summarize anything
3. **Stale guidance**: ADR Creation Workflow section references `cd doc/technical/adr` path pattern that is inconsistent with how the script is actually invoked
4. **Dead links**: Architecture Context Packages section lists 3 packages that don't exist with strikethrough
5. **Scope confusion**: Mixes ADR tracking with architecture session tracking and context package tracking — three different concerns

### Proposed Rework

Refocus architecture-tracking.md as the **authoritative cross-cutting ADR registry** with a secondary role for architectural state. Specific changes:

1. **ADR Index**: Populate with 3 existing ADRs and move to a prominent position
2. **Remove empty tables**: Remove Current Architecture State and Architecture Sessions Summary if they've never been used (or mark them as optional future sections)
3. **Update ADR Creation Workflow**: Replace with current script invocation pattern + guide reference
4. **Clean up dead links**: Remove strikethrough context package references
5. **Clarify purpose**: Update "Relationship to Feature Tracking" to reflect that ADR column no longer exists — architecture-tracking is now the sole ADR registry

> **Note**: The exact target structure for architecture-tracking.md should be designed during implementation when we can review the full file in context. This section captures the intent; the implementation session will determine the details.

---

## 🔧 Implementation Roadmap

### Session 1: Core Retirement & Tracking Changes

**Priority**: HIGH — establishes the new structure that other changes depend on

- [ ] Delete adr-creation-task.md (PF-TSK-028)
- [ ] Delete adr-creation-map.md (context map)
- [ ] Update ai-tasks.md: remove ADR Creation from task table and workflow strings
- [ ] Update feature-tracking.md: remove ADR column from 0.x table and ADR note
- [ ] Rework architecture-tracking.md: populate ADR Index, clean up structure
- [ ] Update PF-documentation-map.md: remove PF-TSK-028 and context map entries
- [ ] Update tasks/README.md: remove ADR Creation entry
- [ ] Update IMP tracking: reject IMP-487, complete IMP-488, close IMP-491 as already-done

### Session 2: Parent Task Updates & Script Cleanup

**Priority**: HIGH — completes the migration

- [ ] Update Foundation Feature Implementation (PF-TSK-043): add guide reference
- [ ] Update System Architecture Review (PF-TSK-082): add guide reference
- [ ] Update Code Refactoring Standard Path: add guide reference
- [ ] Update Bug Fixing (PF-TSK-006): convert from follow-up to inline
- [ ] Update Core Logic Implementation (PF-TSK-057): convert from follow-up to inline
- [ ] Update Architectural Consistency Validation (PF-TSK-031): update recommendation
- [ ] Update Retrospective Documentation Creation (PF-TSK-066): update references
- [ ] Update Architecture Decision Creation Guide (PF-GDE-033): remove task binding
- [ ] Update Task Transition Guide: remove "Transitioning FROM ADR Creation" section, update ADR references
- [ ] Update New-ArchitectureDecision.ps1: remove feature-tracking update logic
- [ ] Verify/update Update-FeatureImplementationState.ps1 and Validate-StateTracking.ps1
- [ ] Update Process Framework Task Registry: remove Section 9
- [ ] Update Task Trigger & Output Traceability: remove PF-TSK-028 entry
- [ ] Finalize state tracking, feedback form

---

## 🎯 Success Criteria

### Functional Success Criteria
- [ ] No task references PF-TSK-028 — all ADR creation is inline
- [ ] Every inline ADR step references both the script and the guide
- [ ] Inline ADR steps use conditional phrasing ("if an architectural decision was made" / "if needed")
- [ ] architecture-tracking.md ADR Index contains all 3 existing ADRs
- [ ] feature-tracking.md has no ADR column in any table
- [ ] New-ArchitectureDecision.ps1 only updates architecture-tracking.md, not feature-tracking.md
- [ ] All framework registries and maps reflect the removal

### Quality Success Criteria
- [ ] Validate-StateTracking.ps1 passes after changes
- [ ] No broken links introduced (LinkWatcher validates)
- [ ] No orphan references to PF-TSK-028 remain anywhere in the codebase

---

## 📋 IMP Disposition

| IMP | Original Scope | Disposition | Rationale |
|-----|---------------|-------------|-----------|
| PF-IMP-487 | Add ADR column to all feature tables | **Reject** | Removing ADR column entirely — N:M relationship makes per-feature columns misleading. Architecture-tracking.md ADR Index handles this cross-cuttingly |
| PF-IMP-488 | Populate ADR Index in architecture-tracking.md | **Keep** | Core deliverable of this extension |
| PF-IMP-489 | Add Architecture-First workflow in ai-tasks.md | **Unchanged** | Separate concern — not addressed by this extension |
| PF-IMP-490 | Add 0.x opt-in guidance in Project Initiation | **Unchanged** | Separate concern — not addressed by this extension |
| PF-IMP-491 | Add automation to ADR script for ADR Index | **Close (already done)** | Script already has this logic (lines 170-228); 3 existing ADRs predate the automation |

---

## 📋 Human Review Checklist

**🚨 This concept requires human review before implementation can begin! 🚨**

### Concept Validation
- [ ] **Extension Necessity**: Confirm retiring PF-TSK-028 is the right approach vs. keeping it as lightweight sub-procedure
- [ ] **Scope Appropriateness**: Verify the architecture-tracking.md rework scope is appropriate
- [ ] **IMP Disposition**: Approve rejecting IMP-487 (removing column vs. adding to all tables)
- [ ] **Session Split**: Approve 2-session implementation plan

### Approval Decision
- [ ] **APPROVED**: Concept is approved for implementation
- [ ] **NEEDS REVISION**: Concept needs changes before approval
- [ ] **REJECTED**: Concept is not suitable for framework extension

**Human Reviewer**: ___
**Review Date**: 2026-04-12
**Decision**: [APPROVED/NEEDS REVISION/REJECTED]
**Comments**: ___

---

*This concept document was created using the Framework Extension Concept Template (PF-TEM-032) as part of the Framework Extension Task (PF-TSK-026).*
