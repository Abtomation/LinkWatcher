---
id: PF-TSK-056
type: Process Framework
category: Task Definition
version: 1.0
domain: agnostic
created: 2026-01-28
updated: 2026-01-28
task_type: Support
---

# Framework Domain Adaptation

## Purpose & Context

Systematically adapt the process framework from one business domain (software development) to another (legal document generation) while preserving the core task-based structure, automation capabilities, and workflow principles. The legal directory has inherited a complete process framework originally designed for software development task management. While the core principles are universally applicable, the specific content, terminology, and artifacts need adaptation for legal document generation use cases.

**Current State**: 66 documents designed for software development workflows
**Target State**: Adapted framework supporting legal document generation workflows
**Business Domain**: Letscape - Escape room booking platform requiring legal documentation

## AI Agent Role

**Role**: Process Architect & Domain Migration Specialist
**Mindset**: Systematic, methodical, preservation-focused while driving necessary change
**Focus Areas**: Framework coherence, cross-reference integrity, domain terminology mapping, selective deletion vs. adaptation
**Communication Style**: Present decisions with clear rationale, seek approval for critical deletions, highlight risks and dependencies

## When to Use

- When migrating the process framework to a fundamentally different business domain
- When inherited framework requires systematic domain-specific adaptation
- When scope affects majority of framework documents (50%+ affected)
- When domain terminology needs comprehensive translation

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/support/framework-domain-adaptation-map.md)

- **Critical (Must Read):**

  - [Framework Domain Adaptation Concept](../../proposals/proposals/old/framework-domain-adaptation-concept.md) - Complete adaptation strategy and approach
  - [Legal Framework Cleanup State](../../state-tracking/temporary/legal-framework-cleanup-state.md) - Current document inventory and tracking
  - Business Context Document - Business requirements and domain context
  - [Process Framework README](../../README.md) - Understanding the framework structure
  - [Documentation Map](../../documentation-map.md) - Complete framework structure overview

- **Important (Load If Space):**

  - [Domain Terminology Mapping](../../proposals/proposals/old/framework-domain-adaptation-concept.md#domain-terminology-mapping) - Software dev → Legal mappings
  - [Deletion Criteria](../../proposals/proposals/old/framework-domain-adaptation-concept.md#deletion-criteria) - DELETE vs. ADAPT vs. KEEP guidelines
  - [AI Tasks Registry](../../../ai-tasks.md) - Task system overview

- **Reference Only (Access When Needed):**
  - [Visual Notation Guide](../../guides/guides/visual-notation-guide.md) - For interpreting diagrams
  - [Terminology Guide](../../guides/guides/terminology-guide.md) - Current terminology definitions
  - Individual framework documents as referenced in cleanup state file

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Multi-session task - use temporary state tracking file throughout.**

### Phase 1: Preparation & Analysis

1. **🚨 CRITICAL FIRST STEP: Framework Familiarization**
   - Read and understand core framework documentation (README, documentation-map, ai-tasks.md)
   - Understand how the framework is supposed to work end-to-end
   - Identify main workflow paths and how components connect
   - Document understanding before proceeding

2. **Review Domain Adaptation Concept**
   - Read [Framework Domain Adaptation Concept](../../proposals/proposals/old/framework-domain-adaptation-concept.md)
   - Understand the 3-decision framework: DELETE / ADAPT / KEEP
   - Review domain terminology mapping (software dev → legal)
   - Confirm deletion criteria with human partner

3. **Access Temporary State Tracking File**
   - Use existing [Legal Framework Cleanup State](../../state-tracking/temporary/legal-framework-cleanup-state.md)
   - File is organized by process flow order, not file type
   - Includes decision tracking columns (DELETE/ADAPT/KEEP + notes)
   - Update status as you progress through documents

4. **Verify Link Integrity**
   - Check all links in existing documents
   - Identify broken links from previous cleanup
   - Evaluate if deleted/missing linked documents are critical
   - Re-add critical documents or update references

### Phase 2: Systematic Review (Process Flow Order)

5. **Review Documents in Process Flow Order**
   - Follow the order in [Legal Framework Cleanup State](../../state-tracking/temporary/legal-framework-cleanup-state.md)
   - For each document, make one of three decisions:
     - **DELETE**: Not applicable to legal domain
     - **ADAPT**: Reusable with modifications for legal context
     - **KEEP**: Domain-agnostic, works as-is

   - **⚠️ IMPORTANT - KEEP File Review Protocol:**
     - Files marked KEEP should remain domain-agnostic (generic/reusable)
     - During review, identify if KEEP files contain domain-specific references (e.g., "BreakoutBuddies project")
     - Mark these in notes with **"Domain-ref cleanup needed"** flag
     - These references should be REMOVED (not replaced with new domain)
     - Example: "BreakoutBuddies project" → remove entirely, keep generic
     - Example: Keep "Central ID management module" (don't add domain-specific suffixes)

   **Review Groups:**
   1. Core Framework Understanding (README, documentation-map, ai-tasks.md, terminology-guide)
   2. Foundation Infrastructure (helper modules, core scripts, IdRegistry, automation-config)
   3. Document Creation Flow (scripts → templates → guides for each creation type)
   4. Task Workflow (support tasks and their context maps)
   5. State Management (state templates and permanent state files)
   6. Feedback & Quality (feedback system components)
   7. Remaining Guides (reference material not yet covered)
   8. Automation & Utilities (batch processing, validation, update scripts)

6. **Track Decisions in State File**
   - For each document, record:
     - Decision (DELETE/ADAPT/KEEP)
     - Reasoning notes
     - Any broken links found
     - Adaptation complexity (Low/Medium/High)
     - **For KEEP files**: Note if "Domain-ref cleanup needed" (has domain references to remove)
   - Update status from Pending → Reviewed → Decided

7. **Get Human Approval for Deletions**
   - Present complete list of documents marked DELETE
   - Explain rationale for each deletion
   - Get explicit approval before proceeding to execution

### Phase 3: Execution

> **🚨 CRITICAL UNDERSTANDING: Document Status Workflow**
>
> **Status Progression**: Pending → Reviewed → **Proposed** → **Approved**
>
> - **"Pending"** = Not yet reviewed
> - **"Reviewed"** = Decision made (DELETE/ADAPT/KEEP), not yet executed
> - **"Proposed"** = Adaptation complete, awaiting human approval
> - **"Approved"** = Human confirmed, safe to reference and consult
>
> **Which documents can be consulted for content?**
> - ✅ **"Approved"** = Already adapted to legal domain, safe to reference
> - ⚠️ **"Pending/Reviewed/Proposed"** = Still contains software domain content or awaiting approval
>   - Understand PRINCIPLE/STRUCTURE only, NOT the content
>
> **📋 Adaptive Execution Principle:**
> - Priority reshuffling during execution is EXPECTED and PART OF the task
> - If you discover a document should be adapted earlier, update priorities and document the reasoning
> - The state tracking file order is a starting point, not rigid

8. **Delete Identified Files**
   - Remove all files marked DELETE (after human approval)
   - Document deletions in state file
   - Status: Reviewed → Approved (after deletion confirmed)

9. **Execute Adaptations**
   - For files marked ADAPT, apply systematic terminology updates
   - Use domain terminology mapping as reference
   - Update examples, descriptions, and context for legal domain
   - Preserve core structure and functionality
   - **For files marked KEEP with "Domain-ref cleanup needed":**
     - REMOVE domain-specific references (e.g., "BreakoutBuddies project")
     - Do NOT replace with new domain references (keep generic)
     - Goal: Make truly domain-agnostic
   - **Only consult documents marked "Approved" for content reference**
   - **For non-approved documents: understand structure/principle, create new content for legal domain**
   - **🚨 MANDATORY: Test All Script Adaptations**
     - **For PowerShell scripts (.ps1, .psm1):**
       1. **Syntax validation**: Verify script loads without errors (`Get-Help ./script.ps1`)
       2. **Functional testing**: Test with sample parameters using `-WhatIf` flag
       3. **Validate new parameters**: Test new ValidateSet values, category options, etc.
       4. **Document test results**: Add "Tested: [test summary]" to state tracking file notes
       5. **Example test commands**:
          - `./New-Task.ps1 -TaskType Support -TaskName "Test" -WorkflowPhase 02-drafting -WhatIf`
          - Verify script accepts new values and creates files in correct directories
     - **Testing is NOT optional** - mark as "Proposed" only after successful testing
     - **Include test summary in approval request** to human partner
   - **🚨 CRITICAL: Parameter Changes & File Renames with Dependencies**
     - **BEFORE** changing parameter names or renaming/deleting files:
       1. **Search for all references** using Grep across entire codebase
       2. **Identify dependent files** that call functions or import modules
       3. **Create dependency update list** documenting all files that need changes
       4. **Update state tracking file** to mark dependent files as "Modified (needs verification)"
       5. **Update ALL dependent files FIRST** before committing the change
       6. **Test the functionality** of all updated modules/scripts
       7. **Verify no broken calls** remain after updates
       8. **Mark as Approved** only after testing confirms functionality
     - **Parameter changes** (e.g., `-FeatureId` → `-ItemId`):
       - Search pattern: `Update-MarkdownTable.*-FeatureId`
       - Update all function calls to use new parameter name
       - Consider backward compatibility aliases if heavily used
     - **File renames** (e.g., `FeatureTracking.psm1` → `ItemTracking.psm1`):
       - Search for: module filename, function names, Import-Module statements
       - Update: module loaders, import statements, documentation references
       - Delete old file ONLY after all references updated
     - **State Tracking Requirements**:
       - **Document the dependency chain** in state tracking file notes
       - **Add new row** for newly created file (if renamed/replaced)
       - **Update status** for modified dependent files to "Modified (needs verification)"
       - **Add notes** explaining what was modified and why (e.g., "Updated to use ItemTracking.psm1 instead of FeatureTracking.psm1")
       - **After testing**: Update all affected files to "Verified" or "Approved"
     - **Testing Requirements**:
       - Test module loading (Import-Module)
       - Test function calls with new parameters
       - Verify no PowerShell errors or warnings
       - If possible, run end-to-end test of affected workflow
   - **🚨 CRITICAL WORKFLOW for each adaptation:**
     1. Complete the adaptation
     2. **🚨 MANDATORY: Add domain metadata field** to YAML frontmatter:
        - Add `domain: agnostic` (meta-framework/generic) OR `domain: legal` (legal-specific content)
        - Update "Domain Field" column in state tracking file (✓ = added, ✗ = not added, N/A = no frontmatter)
        - Files without frontmatter (.psm1, .json): mark as "N/A"
     3. **FOR SCRIPTS: Test the adaptation** (syntax + functional testing with sample parameters)
     4. **Verify all links** in the adapted document
     5. **Log broken links** in state tracking file "Broken Links Log" section
     6. **Fix or document** each broken link (update reference, remove link, or note as intentional)
     7. Update status to **"Proposed"** in state tracking file (only after testing for scripts)
     8. Present changes to human and **request feedback** (include test results for scripts)
     9. Wait for human response
     10. Apply corrections if needed
     11. After human confirms approval, update status to **"Approved"**
     12. Only then proceed to next document
   - **Document priority changes**: If you reshuffle adaptation order, update state file with reasoning

   **📋 Domain Metadata Reference:**
   - **Purpose**: Mark each file as domain-agnostic or domain-specific for future clarity
   - **When**: Add during adaptation (for ADAPT files) or during domain-ref cleanup (for KEEP files)
   - **Metadata field**: Add to YAML frontmatter (if file has frontmatter)
   - **Values**:
     - `domain: agnostic` - Works for any domain (meta-framework tools, generic guides, domain-neutral templates)
     - `domain: legal` - Contains legal-specific content (legal examples, legal terminology, legal workflows)
   - **Example**:
     ```yaml
     ---
     id: PF-GDE-004
     type: Process Framework
     category: Guide
     domain: agnostic  # Added domain field
     version: 1.0
     ---
     ```
   - **Files without YAML frontmatter** (.psm1, .json): Note as "N/A" in tracking

10. **Update Cross-References**
    - Fix all broken links resulting from deletions
    - Update documentation map to reflect new structure
    - Verify all internal links are valid across framework

11. **Test Script Functionality**
    - Test key PowerShell scripts still function
    - Verify New-Task.ps1, New-Template.ps1, New-Guide.ps1 work
    - Check IdRegistry.psm1 functionality

### Phase 4: Validation & Finalization

12. **Validate Domain Configuration**
    - **Verify domain-config.json exists** and contains current domain values:
      ```powershell
      Get-Content ".\doc\process-framework\domain-config.json" | ConvertFrom-Json
      ```
    - **Update domain-config.json** with new domain values:
      - `workflow_phases.values` - Update to new domain phases (e.g., "01-planning", "02-drafting")
      - `task_types.values` - Verify task types are domain-appropriate
      - `business_domains.values` - Update domain identifiers
      - `validation_rules.deprecated_keywords` - Add old domain keywords to detect
      - `domain` and `domain_description` - Update to reflect new domain
    - **Verify scripts load config correctly**:
      - New-Task.ps1, New-ContextMap.ps1, New-TempTaskState.ps1, New-BusinessContext.ps1 should all load domain-config.json
      - Test with sample parameters to verify validation works
    - **Test validation with invalid values** to confirm rejection works:
      ```powershell
      # Should fail with clear error message showing valid values
      .\New-Task.ps1 -TaskType "InvalidType" -TaskName "Test"
      ```
    - **Benefits of config-based approach**:
      - Future domain adaptations only require updating domain-config.json
      - Scripts remain domain-agnostic and don't need modification
      - Validation is automatic and consistent across all scripts

13. **Verify Framework Coherence**
    - Ensure adapted framework is internally consistent
    - Check that terminology is consistent throughout
    - Verify all cross-references are valid

14. **Test Core Workflows**
    - Test task creation workflow
    - Verify state tracking still functions
    - Confirm automation scripts work

15. **Create Legal Document Tracking**
    - Create legal-document-tracking.md to replace feature-tracking.md
    - Set up tracking structure for legal documents

16. **Update Documentation Map**
    - Reflect final structure after all changes
    - Ensure all remaining documents are properly indexed

17. **Archive Temporary State**
    - Move legal-framework-cleanup-state.md to old/ directory
    - Document adaptation completion date

18. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Adapted Task Definitions** - Tasks modified for legal context in `/doc/process-framework/tasks/`
- **Adapted Templates** - Templates for legal documents and processes in `/doc/process-framework/templates/`
- **Adapted Guides** - Guides using legal terminology and examples in `/doc/process-framework/guides/`
- **Updated Documentation Map** - Reflects cleaned-up structure at `/doc/process-framework/documentation-map.md`
- **Legal Document Tracking** - Replacement for feature-tracking.md at `/doc/process-framework/state-tracking/permanent/legal-document-tracking.md`
- **Cleaned Directory Structure** - Removed unnecessary directories
- **Updated Scripts** - Scripts adapted for legal context (parameter names, help text)
- **Updated ID Registry** - New ID prefixes for legal document types at `/doc/id-registry.json`
- **Archived Temporary State** - Domain adaptation state file archived at `/doc/process-framework/state-tracking/temporary/old/`

## State Tracking

The following state files must be updated as part of this task:

- [Legal Framework Cleanup State](../../state-tracking/temporary/legal-framework-cleanup-state.md) - Track review status and decisions for each document
- [Documentation Map](../../documentation-map.md) - Update continuously as structure changes
- [ID Registry](../../../id-registry.json) - Add new ID prefixes for legal document types
- [Legal Document Tracking](../../state-tracking/permanent/legal-document-tracking.md) - Create to replace feature-tracking.md

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Phase 1: Preparation & Analysis**
  - [ ] Framework familiarization completed and documented
  - [ ] Domain adaptation concept reviewed and understood
  - [ ] Link integrity verified
  - [ ] Deletion criteria confirmed with human partner

- [ ] **Phase 2: Systematic Review**
  - [ ] All 66 documents reviewed (per cleanup state file)
  - [ ] Decision made for each document (DELETE/ADAPT/KEEP)
  - [ ] Decisions tracked in cleanup state file
  - [ ] Human approval obtained for all DELETE decisions

- [ ] **Phase 3: Execution**
  - [ ] All DELETE files removed and approved
  - [ ] All ADAPT files updated with legal terminology (Proposed → Approved workflow for each file)
  - [ ] Cross-references updated
  - [ ] Scripts tested and functional

- [ ] **Phase 4: Validation & Finalization**
  - [ ] Framework coherence verified
  - [ ] Core workflows tested
  - [ ] Legal document tracking created
  - [ ] Documentation map updated
  - [ ] Temporary state file archived

- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Legal Framework Cleanup State](../../state-tracking/temporary/legal-framework-cleanup-state.md) - All documents marked as Approved
  - [ ] [Documentation Map](../../documentation-map.md) - Reflects final structure
  - [ ] [Legal Document Tracking](../../state-tracking/permanent/legal-document-tracking.md) - Created and functional

- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-056" and context "Framework Domain Adaptation"

## Next Tasks

- **Begin Domain Work** - Use adapted framework to work in the target domain
- [**Process Improvement**](process-improvement-task.md) - Document lessons learned from adaptation process

## Domain Terminology Mapping Reference

Quick reference for adaptations:

| Software Development | Legal Domain |
|---------------------|--------------|
| Feature | Legal Document |
| Implementation | Drafting |
| Code Quality Check | Compliance Check |
| Testing | Gap Analysis / Review |
| Bug Fix | Document Correction |
| Deployment | Finalization / Lawyer Review |
| Feature Tracking | Document Tracking |
| Release | Document Version |
| Development Session | Drafting Session |
| Build/Compile | Document Assembly |
| Repository | Document Repository |
| Pull Request | Review Cycle |

## Success Criteria

1. **Completeness**: All 66 documents reviewed and processed
2. **Coherence**: Adapted framework is internally consistent
3. **Functionality**: Core workflows (task creation, state tracking, automation) still work
4. **Clarity**: Legal terminology is clear and appropriate
5. **Efficiency**: Unnecessary artifacts removed, no bloat
6. **Traceability**: Adaptation decisions documented for future reference

## Related Resources

- [Framework Domain Adaptation Concept](../../proposals/proposals/old/framework-domain-adaptation-concept.md) - Complete strategy document
- [Legal Framework Cleanup State](../../state-tracking/temporary/legal-framework-cleanup-state.md) - Document tracking
- Business Context Document - Business requirements and domain context
- [New Task Creation Process](new-task-creation-process.md) - Process being followed to create this task
- [Structure Change Task](structure-change-task.md) - Similar but different scope
