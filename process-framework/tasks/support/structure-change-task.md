---
id: PF-TSK-014
type: Process Framework
category: Task Definition
domain: agnostic
version: 2.1
created: 2025-06-07
updated: 2026-04-03
---

# Structure Change Task

## Purpose & Context

This task **orchestrates** systematic changes to documentation structures, templates, or frameworks across multiple files. It plans the overall change, delegates specialized work to appropriate tasks/processes (e.g., task creation to PF-TSK-001, template work to the Template Development Guide), tracks progress, and coordinates handover — ensuring consistent, well-tested structural evolution with clear migration paths and rollback options.

> **Key principle**: PF-TSK-014 is a **coordinator**, not an executor of specialized work. It should never bypass the quality gates of specialized tasks by doing their work inline.

## AI Agent Role

**Role**: Project Coordinator / Change Manager
**Mindset**: Delegation-focused, impact-aware, change-management oriented
**Focus Areas**: Change impact analysis, delegation planning, progress tracking, handover coordination
**Communication Style**: Analyze dependencies and change ripple effects, identify which specialized tasks/processes to delegate to, ask about migration preferences and rollback requirements

## When to Use

- When updating documentation templates that affect multiple files
- When changing metadata structures across the documentation system
- When reorganizing section layouts in standardized documents
- When implementing new formatting or structural conventions
- When evolving the information architecture of the documentation

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/support/structure-change-map.md)

- **Critical (Must Read):**

  - [Structure Change Proposal](../../templates/support/structure-change-proposal-template.md) - Detailed description of proposed changes
  - [Documentation Map](../../PF-documentation-map.md) - Map of all documentation
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**
  - [Template Development Guide](../../guides/support/template-development-guide.md) - **REQUIRED** for creating or updating templates
  - [Document Creation Script Development Guide](../../guides/support/document-creation-script-development-guide.md) - **REQUIRED** for creating automation scripts
  - [Process Framework Documentation](../../README.md) - Current documentation structure
  - [Feedback Forms](../../feedback/feedback-forms) - Feedback related to current structure

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Create backup copies of all files before making changes.**
>
> **📋 IMPORTANT: Use established document creation processes for all new templates, guides, and scripts. Do NOT create these manually - use the provided scripts and follow the development guides.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Scope Assessment

1. **Identify Scope**: Review the structure change requirements and identify all files affected. Classify the change:

   | Criteria | Lightweight | Full |
   |---|---|---|
   | **Files affected** | ≤ 5 files | > 5 files |
   | **Change type** | Single-type (rename, move, update references, add column) | Multi-type (template + guide + script + content) |
   | **Breaking changes** | No (backward-compatible or self-contained) | Yes (changes that affect other tasks/workflows) |
   | **Cross-references** | Handled by LinkWatcher or minimal manual updates | Extensive manual cross-reference updates needed |
   | **Incoming references** | ≤ 20 files reference the affected file(s) | > 20 files reference the affected file(s) (grep to verify) |

   > A change qualifies as **Lightweight** if it meets ALL lightweight criteria. If ANY criterion falls into Full, use the Full process.

2. **🚨 HUMAN APPROVAL REQUIRED**: Present the scope assessment to the human partner with a recommendation (Lightweight or Full) and the reasoning. **Do not proceed until the human confirms the mode.**

   > If Lightweight → continue to [Lightweight Process](#lightweight-process)
   > If Full → continue to [Full Process](#full-process)

---

### Lightweight Process

> For small, contained structure changes (≤ 5 files, single-type, no breaking changes).

3. **Make Changes**: Implement the structure change directly:
   - Use established scripts when creating new documents ([New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1), [New-Guide.ps1](../../scripts/file-creation/support/New-Guide.ps1), etc.)
   - For markdown table changes, consider [Add-MarkdownTableColumn.ps1](../../scripts/Add-MarkdownTableColumn.ps1)
   - Verify LinkWatcher is running for automatic cross-reference updates

4. **🚨 CHECKPOINT**: Present implemented changes and affected files to human partner for review
5. **Verify**: Confirm all changes are correct:
   - All affected files updated
   - Cross-references valid (check LinkWatcher log if relevant)
   - No broken links or orphaned references

6. **Update Documentation Map**: Update the appropriate map if document organization changed:
   - Process-framework artifacts → [PF Documentation Map](../../PF-documentation-map.md)
   - Product documents (FDDs, TDDs, ADRs, handbooks) → [PD Documentation Map](../../../doc/PD-documentation-map.md)
   - Test artifacts (test specs, audit reports) → [TE Documentation Map](../../../test/TE-documentation-map.md)

7. **🚨 MANDATORY FINAL STEP**: Complete the [Lightweight Completion Checklist](#lightweight-completion-checklist) below

---

### Full Process

> For large, multi-type, or breaking structure changes.

#### Preparation

3. **🚨 MANDATORY Impact Analysis**: Before creating the proposal, systematically assess the full scope of the change. This step prevents incremental scope discovery during execution.

   a. **Reference grep**: For each affected file, grep the entire project to find all files that reference it (markdown links, imports, script paths, string literals). Record the count and list.
   b. **Script audit**: Identify all automation scripts that read from or write to the affected file(s). Check `process-framework/scripts/` for scripts that target these paths.
   c. **Task definition audit**: Search task definitions (`process-framework/tasks/`) for manual update instructions referencing the affected file(s) (e.g., "update documentation-map.md").
   d. **Infrastructure doc consultation**: Read [Process Framework Task Registry](../../infrastructure/process-framework-task-registry.md) (catalogs what each task creates/updates) and [Task Transition Guide](../../guides/framework/task-transition-guide.md) (documents handover interfaces between tasks) to identify additional downstream impacts.
   e. **Present impact matrix**: Compile findings into a matrix (affected files × change type: link update, content update, script change, task definition change) and present at the checkpoint below.

   > **Why this step exists**: SC-009 demonstrated that without structured impact analysis, scope gaps are caught incrementally by the human partner across multiple checkpoints — wasting review cycles and risking missed items.

4. **Create Structure Change Proposal**: Use the [New-StructureChangeProposal.ps1](../../scripts/file-creation/support/New-StructureChangeProposal.ps1) script. Incorporate the impact matrix from Step 3 into the proposal:
   ```powershell
   cd process-framework/scripts/file-creation
   .\New-StructureChangeProposal.ps1 -ChangeName "Change Name" -Description "Brief description"
   ```
5. **Create Structure Change State Tracking File**: Use the [New-StructureChangeState.ps1](../../scripts/file-creation/support/New-StructureChangeState.ps1) script to create tracking file with implementation roadmap
   ```powershell
   # Navigate to the state-tracking directory and create structure change state tracking file
   cd process-framework-local/state-tracking
   ./New-StructureChangeState.ps1 -ChangeName "Change Name" -ChangeType "Template Update|Directory Reorganization|Metadata Structure|Documentation Architecture|Rename|Content Update" -Description "Brief description"
   # Use -ChangeType "Rename" for lightweight rename/move operations (simplified template without pilot/rollback/metrics sections)
   # Use -ChangeType "Content Update" for content-only changes across files (simplified template without pilot/rollback/metrics sections)
   # Use -FromProposal when a detailed proposal already exists — generates a lightweight state file (phase checklist + session log only, no redundant sections)
   ```
6. Use the existing `/process-framework-local/state-tracking/temporary` directory for transition files
7. Create mapping documents and migration checklists in the temporary directory
8. Establish clear metrics for measuring the success of the structure change
9. **🚨 CHECKPOINT**: Present structure change proposal (including impact matrix from Step 3), migration plan, and impact analysis to human partner for approval

#### Execution

> **🚨 ORCHESTRATOR PRINCIPLE**: PF-TSK-014 plans, tracks, and coordinates structure changes. It does NOT perform specialized work inline. When a deliverable requires template creation, guide creation, script creation, or task creation, **delegate to the appropriate specialized task or process** and track completion.

10. **Delegation Planning**: Review the deliverables identified in the proposal and classify each one:

   | Deliverable Type | Delegate To | Process |
   |---|---|---|
   | New task definition | [New Task Creation Process (PF-TSK-001)](new-task-creation-process.md) | Full task creation workflow with quality gates |
   | New/updated template | [Template Development Guide](../../guides/support/template-development-guide.md) + [New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1) | Template development process |
   | New/updated guide | [New-Guide.ps1](../../scripts/file-creation/support/New-Guide.ps1) | Guide creation process |
   | New automation script | [Document Creation Script Development Guide](../../guides/support/document-creation-script-development-guide.md) + [script template](../../templates/support/document-creation-script-template.ps1) | Script development process |
   | Content migration | PF-TSK-014 (this task) | Direct execution — see step 13 |
   | Cross-reference updates | PF-TSK-014 (this task) | Direct execution — LinkWatcher handles most |

   Record the delegation plan in the structure change state tracking file.

11. **🚨 CHECKPOINT**: Present the delegation plan to the human partner — which deliverables are delegated, which are handled directly, and the execution order.

12. **Execute Delegated Work**: For each delegated deliverable:
    a. Start the delegated task/process (may be a separate session if context-heavy)
    b. Track completion status in the structure change state tracking file
    c. **🚨 CHECKPOINT**: Confirm each delegated deliverable meets expectations before proceeding to the next

13. **Direct Execution — Migration and Updates**: Handle work that belongs to PF-TSK-014 directly:
    - Create migration plan for updating files affected by structure changes
    - Pilot changes on a small subset of files to validate the approach
    - **🚨 CHECKPOINT**: Present pilot results to human partner for approval before full rollout
    - Implement changes across remaining files
    - For markdown table changes, consider [Add-MarkdownTableColumn.ps1](../../scripts/Add-MarkdownTableColumn.ps1)
    - Update cross-references and links (verify LinkWatcher is running)

#### Finalization

14. Verify all files have been updated correctly
15. Document any issues encountered and their resolutions
16. Update the documentation map if structure changes affected document organization

#### 🚨 MANDATORY Cleanup Phase

17. **🚨 CRITICAL CLEANUP STEP**: Archive completed temporary state tracking files to `/process-framework-local/state-tracking/temporary/old`
18. **Archive completed proposal**: Move the structure change proposal to its `old/` subdirectory (e.g., `proposals/old`) — the proposal has served its purpose and should not remain alongside active proposals
19. Remove excessive migration mapping documents if they don't provide ongoing value
20. Clean up any redundant documentation created during the process
21. Update the Process Improvement Tracking file with cleanup completion

#### Final Completion

21. **🚨 MANDATORY FINAL STEP**: Complete the [Full Completion Checklist](#full-completion-checklist) below

## Outputs

- **Updated Structure Files** - Templates and guides with new structure
- **Migrated Content Files** - All content files updated to the new structure
- **Structure Change Tracking** - State tracking file documenting the structure change
- **Migration Artifacts** - Temporary files used during migration (to be archived or deleted)

## State Tracking

The following state files must be updated as part of this task:

- **Structure Change State File** - Create using New-StructureChangeState.ps1 to track multi-session implementation progress
- [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) - Update to reflect the process improvement
- [PF Documentation Map](../../PF-documentation-map.md) - Update if process-framework document organization changes
- [PD Documentation Map](../../../doc/PD-documentation-map.md) - Update if product document organization changes
- [TE Documentation Map](../../../test/TE-documentation-map.md) - Update if test artifact organization changes

<!-- Note to task creator: Replace placeholders with actual linked state files (e.g., [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)) -->

## ⚠️ MANDATORY Task Completion Checklists

### Lightweight Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] **Scope Assessment**: Human partner confirmed Lightweight mode
- [ ] **Verify Changes**: All affected files updated correctly
  - [ ] New documents created using established scripts (if applicable)
  - [ ] Cross-references valid (no broken links)
  - [ ] Run [`Validate-StateTracking.ps1`](../../scripts/validation/Validate-StateTracking.ps1) — 0 errors across all surfaces
- [ ] **Update State Files**:
  - [ ] [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) updated (if this change addresses an IMP item)
  - [ ] Appropriate documentation map(s) updated if document organization changed: [PF](../../PF-documentation-map.md) / [PD](../../../doc/PD-documentation-map.md) / [TE](../../../test/TE-documentation-map.md)
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-014" and context "Structure Change (Lightweight)"

---

### Full Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] **Scope Assessment**: Human partner confirmed Full mode
- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] **Delegation completed**: All delegated deliverables completed through their specialized tasks/processes
  - [ ] **No specialized work done inline**: Task creation used PF-TSK-001, templates used Template Dev Guide, scripts used Script Dev Guide
  - [ ] All affected content files migrated to new structure
  - [ ] Structure change tracking file properly maintained (delegation status recorded)
  - [ ] Run `Validate-StateTracking.ps1` — 0 errors across all surfaces
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Structure change state tracking file completed and properly maintained
  - [ ] [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) updated with structure change completion
  - [ ] Appropriate documentation map(s) updated if document organization changed: [PF](../../PF-documentation-map.md) / [PD](../../../doc/PD-documentation-map.md) / [TE](../../../test/TE-documentation-map.md)
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-014" and context "Structure Change (Full)"
- [ ] **🚨 MANDATORY Cleanup Phase**: Remove temporary documentation artifacts created during the structure change:
  - [ ] **🚨 CRITICAL**: Archive completed temporary state tracking files to `/process-framework-local/state-tracking/temporary/old`
  - [ ] **🚨 CRITICAL**: Archive completed structure change proposal to its `old/` subdirectory
  - [ ] Remove excessive migration mapping documents if they don't provide ongoing value
  - [ ] Clean up any redundant documentation created during the process
  - [ ] Update the Process Improvement Tracking file with cleanup completion
        **Cleanup Criteria**:
  - Archive: Completed temporary state tracking files (move to old/ directory for historical reference)
  - Archive: Completed proposals (move to proposals/old/ directory — no longer active)
  - Keep: Files that provide ongoing reference value or audit trail
  - Remove: Redundant tracking files, excessive migration artifacts, temporary working documents

## Next Tasks

- [**Process Improvement**](process-improvement-task.md) - If further process refinements are needed
- [**Tools Review**](tools-review-task.md) - Review any tools affected by structure changes

## Related Resources

### Delegation Targets (for Full Process)

- [New Task Creation Process (PF-TSK-001)](new-task-creation-process.md) - **DELEGATE** task definition creation here
- [Template Development Guide](../../guides/support/template-development-guide.md) - **DELEGATE** template creation/updates here
- [New-Template.ps1](../../scripts/file-creation/support/New-Template.ps1) - Script for creating new templates
- [New-Guide.ps1](../../scripts/file-creation/support/New-Guide.ps1) - Script for creating new guides
- [Document Creation Script Template](../../templates/support/document-creation-script-template.ps1) - Template for creating automation scripts
- [Document Creation Script Development Guide](../../guides/support/document-creation-script-development-guide.md) - **DELEGATE** script creation here

### Additional Resources

- [Documentation Structure Guide](../../guides/framework/documentation-structure-guide.md) - Principles for documentation structure
- [Migration Best Practices](../../guides/support/migration-best-practices.md) - Guidance for content migration
- [Task Creation and Improvement Guide](../../guides/support/task-creation-guide.md) - Guide for creating and improving tasks

### Automation Scripts

- [Add-MarkdownTableColumn.ps1](../../scripts/Add-MarkdownTableColumn.ps1) - Utility script for adding columns to markdown tables with intelligent table detection and positioning
