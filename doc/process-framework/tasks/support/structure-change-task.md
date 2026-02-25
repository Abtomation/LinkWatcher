---
id: PF-TSK-014
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.0
created: 2025-06-07
updated: 2025-06-07
task_type: Discrete
---

# Structure Change Task

## Purpose & Context

This task manages systematic changes to documentation structures, templates, or frameworks across multiple files. It ensures consistent, well-tested structural evolution with clear migration paths and rollback options.

## AI Agent Role

**Role**: Systems Analyst
**Mindset**: Structure-focused, impact-aware, change-management oriented
**Focus Areas**: System organization, change impact analysis, migration planning, dependency mapping
**Communication Style**: Analyze dependencies and change ripple effects, ask about migration preferences and rollback requirements

## When to Use

- When updating documentation templates that affect multiple files
- When changing metadata structures across the documentation system
- When reorganizing section layouts in standardized documents
- When implementing new formatting or structural conventions
- When evolving the information architecture of the documentation

## Context Requirements

- [Structure Change Context Map](/doc/process-framework/visualization/context-maps/support/structure-change-map.md) - Visual guide to the components relevant to this task

- **Critical (Must Read):**

  - [Structure Change Proposal](../../templates/templates/structure-change-proposal-template.md) - Detailed description of proposed changes
  - [Documentation Map](../../documentation-map.md) - Map of all documentation
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**
  - [Template Development Guide](../../guides/guides/template-development-guide.md) - **REQUIRED** for creating or updating templates
  - [Document Creation Script Development Guide](../../guides/guides/document-creation-script-development-guide.md) - **REQUIRED** for creating automation scripts
  - [Process Framework Documentation](../../../process-framewor) - Current documentation structure
  - [Feedback Forms](../../feedback/feedback-forms) - Feedback related to current structure

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Create backup copies of all files before making changes.**
>
> **📋 IMPORTANT: Use established document creation processes for all new templates, guides, and scripts. Do NOT create these manually - use the provided scripts and follow the development guides.**

### Scope Assessment

1. **Identify Scope**: Review the structure change requirements and identify all files affected. Classify the change:

   | Criteria | Lightweight | Full |
   |---|---|---|
   | **Files affected** | ≤ 5 files | > 5 files |
   | **Change type** | Single-type (rename, move, update references, add column) | Multi-type (template + guide + script + content) |
   | **Breaking changes** | No (backward-compatible or self-contained) | Yes (changes that affect other tasks/workflows) |
   | **Cross-references** | Handled by LinkWatcher or minimal manual updates | Extensive manual cross-reference updates needed |

   > A change qualifies as **Lightweight** if it meets ALL lightweight criteria. If ANY criterion falls into Full, use the Full process.

2. **🚨 HUMAN APPROVAL REQUIRED**: Present the scope assessment to the human partner with a recommendation (Lightweight or Full) and the reasoning. **Do not proceed until the human confirms the mode.**

   > If Lightweight → continue to [Lightweight Process](#lightweight-process)
   > If Full → continue to [Full Process](#full-process)

---

### Lightweight Process

> For small, contained structure changes (≤ 5 files, single-type, no breaking changes).

3. **Make Changes**: Implement the structure change directly:
   - Use established scripts when creating new documents ([New-Template.ps1](../../scripts/file-creation/New-Template.ps1), [New-Guide.ps1](../../scripts/file-creation/New-Guide.ps1), etc.)
   - For markdown table changes, consider [Add-MarkdownTableColumn.ps1](../../scripts/Add-MarkdownTableColumn.ps1)
   - Verify LinkWatcher is running for automatic cross-reference updates

4. **Verify**: Confirm all changes are correct:
   - All affected files updated
   - Cross-references valid (check LinkWatcher log if relevant)
   - No broken links or orphaned references

5. **Update Documentation Map**: Update [Documentation Map](../../documentation-map.md) if document organization changed

6. **🚨 MANDATORY FINAL STEP**: Complete the [Lightweight Completion Checklist](#lightweight-completion-checklist) below

---

### Full Process

> For large, multi-type, or breaking structure changes.

#### Preparation

3. **Create Structure Change State Tracking File**: Use the [New-StructureChangeState.ps1](../../scripts/file-creation/New-StructureChangeState.ps1) script to create tracking file with implementation roadmap
   ```powershell
   # Navigate to the state-tracking directory and create structure change state tracking file
   cd doc/process-framework/state-tracking
   ./New-StructureChangeState.ps1 -ChangeName "Change Name" -ChangeType "Template Update|Directory Reorganization|Metadata Structure|Documentation Architecture" -Description "Brief description"
   ```
4. **Create a structure change proposal in `/doc/process-framework/state-tracking/temporary/` using the structure-change-proposal-template.md**
5. Use the existing `/doc/process-framework/state-tracking/temporary/` directory for transition files
6. Create mapping documents and migration checklists in the temporary directory
7. Establish clear metrics for measuring the success of the structure change

#### Execution

8. **Update or Create Templates Using Established Processes**:
   - **For new templates**: Use [New-Template.ps1](../../scripts/file-creation/New-Template.ps1) script following [Template Development Guide](../../guides/guides/template-development-guide.md)
   - **For existing templates**: Update following template versioning guidelines in Template Development Guide
   - **For new guides**: Use [New-Guide.ps1](../../scripts/file-creation/New-Guide.ps1) script
   - **For new scripts**: Use [document-creation-script-template.ps1](../../templates/templates/document-creation-script-template.ps1) following [Document Creation Script Development Guide](../../guides/guides/document-creation-script-development-guide.md)
9. **Update Guide Files**: Update guides that explain the templates, ensuring consistency with template changes
10. **Create Migration Plan**: Create a phased migration plan for updating individual files affected by structure changes
11. **Pilot Implementation**: Implement changes on a small subset of files first to validate the approach
12. **Thorough Testing**: Test the changes thoroughly before proceeding with full implementation
13. **Update Automation Scripts**: Create or update any automation scripts needed to assist with the migration using established script development processes
    - For markdown table structure changes, consider using [Add-MarkdownTableColumn.ps1](../../scripts/Add-MarkdownTableColumn.ps1) to add columns systematically
14. **Full Implementation**: Implement changes across all remaining files according to the migration plan
15. **Update Cross-References**: Update cross-references and links between documents to reflect structural changes

#### Finalization

16. Verify all files have been updated correctly
17. Document any issues encountered and their resolutions
18. Update the documentation map if structure changes affected document organization

#### 🚨 MANDATORY Cleanup Phase

19. **🚨 CRITICAL CLEANUP STEP**: Archive completed temporary state tracking files to `/doc/process-framework/state-tracking/temporary/old/`
20. Remove excessive migration mapping documents if they don't provide ongoing value
21. Clean up any redundant documentation created during the process
22. Update the Process Improvement Tracking file with cleanup completion

#### Final Completion

23. **🚨 MANDATORY FINAL STEP**: Complete the [Full Completion Checklist](#full-completion-checklist) below

## Outputs

- **Updated Structure Files** - Templates and guides with new structure
- **Migrated Content Files** - All content files updated to the new structure
- **Structure Change Tracking** - State tracking file documenting the structure change
- **Migration Artifacts** - Temporary files used during migration (to be archived or deleted)

## State Tracking

The following state files must be updated as part of this task:

- **Structure Change State File** - Create using New-StructureChangeState.ps1 to track multi-session implementation progress
- [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - Update to reflect the process improvement
- [Documentation Map](../../documentation-map.md) - Update if document organization changes

<!-- Note to task creator: Replace placeholders with actual linked state files (e.g., [Feature Tracking](../../state-tracking/permanent/feature-tracking.md)) -->

## ⚠️ MANDATORY Task Completion Checklists

### Lightweight Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] **Scope Assessment**: Human partner confirmed Lightweight mode
- [ ] **Verify Changes**: All affected files updated correctly
  - [ ] New documents created using established scripts (if applicable)
  - [ ] Cross-references valid (no broken links)
  - [ ] Run `Validate-StateTracking.ps1` — 0 errors across all surfaces
- [ ] **Update State Files**:
  - [ ] [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) updated (if this change addresses an IMP item)
  - [ ] [Documentation Map](../../documentation-map.md) updated if document organization changed
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-014" and context "Structure Change (Lightweight)"

---

### Full Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] **Scope Assessment**: Human partner confirmed Full mode
- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] **All template files updated using proper processes**: New templates created with [New-Template.ps1](../../scripts/file-creation/New-Template.ps1), existing templates updated following [Template Development Guide](../../guides/guides/template-development-guide.md)
  - [ ] **All guide files updated using proper processes**: New guides created with [New-Guide.ps1](../../scripts/file-creation/New-Guide.ps1), existing guides updated appropriately
  - [ ] **All automation scripts created using proper processes**: New scripts created using [document-creation-script-template.ps1](../../templates/templates/document-creation-script-template.ps1) and [Document Creation Script Development Guide](../../guides/guides/document-creation-script-development-guide.md)
  - [ ] All affected content files migrated to new structure
  - [ ] Structure change tracking file properly maintained
  - [ ] Run `Validate-StateTracking.ps1` — 0 errors across all surfaces
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Structure change state tracking file completed and properly maintained
  - [ ] [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) updated with structure change completion
  - [ ] [Documentation Map](../../documentation-map.md) updated if document organization changed
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-014" and context "Structure Change (Full)"
- [ ] **🚨 MANDATORY Cleanup Phase**: Remove temporary documentation artifacts created during the structure change:
  - [ ] **🚨 CRITICAL**: Archive completed temporary state tracking files to `/doc/process-framework/state-tracking/temporary/old/`
  - [ ] Remove excessive migration mapping documents if they don't provide ongoing value
  - [ ] Clean up any redundant documentation created during the process
  - [ ] Update the Process Improvement Tracking file with cleanup completion
        **Cleanup Criteria**:
  - Archive: Completed temporary state tracking files (move to old/ directory for historical reference)
  - Keep: Files that provide ongoing reference value or audit trail
  - Remove: Redundant tracking files, excessive migration artifacts, temporary working documents
  - Archive: Files that may have historical value but aren't needed for daily operations

## Next Tasks

- [**Process Improvement**](../06-maintenance/process-improvement-task.md) - If further process refinements are needed
- [**Tools Review**](tools-review-task.md) - Review any tools affected by structure changes

## Related Resources

### Document Creation Processes (MANDATORY for Structure Changes)

- [Template Development Guide](../../guides/guides/template-development-guide.md) - **REQUIRED** for creating or updating templates
- [New-Template.ps1](../../scripts/file-creation/New-Template.ps1) - **REQUIRED** script for creating new templates
- [New-Guide.ps1](../../scripts/file-creation/New-Guide.ps1) - **REQUIRED** script for creating new guides
- [Document Creation Script Template](../../templates/templates/document-creation-script-template.ps1) - **REQUIRED** for creating automation scripts
- [Document Creation Script Development Guide](../../guides/guides/document-creation-script-development-guide.md) - **REQUIRED** for script development

### Additional Resources

- [Documentation Structure Guide](../../guides/guides/documentation-structure-guide.md) - Principles for documentation structure
- [Migration Best Practices](../../guides/guides/migration-best-practices.md) - Guidance for content migration
- [Task Creation and Improvement Guide](../task-creation-guide.md) - Guide for creating and improving tasks

### Automation Scripts

- [Add-MarkdownTableColumn.ps1](../../scripts/Add-MarkdownTableColumn.ps1) - Utility script for adding columns to markdown tables with intelligent table detection and positioning
