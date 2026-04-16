---
id: PF-TSK-026
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.4
created: 2025-07-26
updated: 2026-04-15
---

# Framework Extension Task

## Purpose & Context

This task manages the systematic extension of the task-based development framework with entirely new functionalities, capabilities, or systematic approaches. It ensures that framework extensions are properly planned, implemented across multiple sessions, and integrated with existing framework components while maintaining consistency with established principles.

## AI Agent Role

**Role**: Framework Architect
**Mindset**: Extensibility-focused, component-oriented, integration-aware
**Focus Areas**: Framework design, component relationships, extensibility patterns, integration points
**Communication Style**: Consider framework evolution and component interactions, ask about long-term extensibility and integration requirements

## When to Use

- When adding entirely new framework capabilities (e.g., architecture framework, testing framework, deployment framework)
- When extending framework scope with new domains of functionality requiring multiple interconnected components
- When making systematic framework evolution that affects fundamental structure or capabilities
- When creating multi-component extensions requiring multiple new tasks, templates, guides, and infrastructure components working together
- When the extension requires more than just creating a single new task (use New Task Creation Process for single tasks)

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/support/framework-extension-task-map.md)

- **Critical (Must Read):**

  - **Framework Extension Concept Document** - Human-provided concept document defining the extension scope, workflow, and integration strategy
  - [Framework Extension Customization Guide](../../guides/support/framework-extension-customization-guide.md) - Essential guide for customizing Framework Extension Concept documents
  - [Task-Based Development Principles](../../ai-tasks.md#understanding-task-based-development) - Understanding of framework principles for consistent extension
  - [New Task Creation Process](new-task-creation-process.md) - For creating individual tasks within the extension
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) - PowerShell execution patterns and parameter checking (**always check script parameters with `-?` before running**)
  - [Documentation Map](../../PF-documentation-map.md) - For understanding current framework structure and updating with new artifacts
  - [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) - For tracking framework capability enhancements
  - [New-TempTaskState.ps1](../../scripts/file-creation/support/New-TempTaskState.ps1) - State tracking for creation-heavy extensions (use `-Variant FrameworkExtension` for multi-artifact tracking)
  - [New-StructureChangeState.ps1](../../scripts/file-creation/support/New-StructureChangeState.ps1) - State tracking for modification-heavy extensions
  - [Template Development Guide](../../guides/support/template-development-guide.md) - For creating extension-specific templates
  - [Document Creation Script Development Guide](../../guides/support/document-creation-script-development-guide.md) - For creating automation scripts

- **Reference Only (Access When Needed):**
  - [PF ID Registry](../../PF-id-registry.json) - For adding new ID prefixes for extension-created file types
  - [Process Framework Task Registry — Trigger & Output](../../infrastructure/process-framework-task-registry.md) - For studying existing trigger/output chains (`🔗 TRIGGER & OUTPUT` blocks and State File Trigger Index)
  - [Structure Change Task](structure-change-task.md) - For understanding structural modifications vs. extensions
  - [Process Improvement Task](process-improvement-task.md) - For understanding granular improvements vs. extensions

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Create comprehensive concept document and get human approval before implementation.**
>
> **📋 IMPORTANT: This is a multi-session task requiring temporary state tracking for implementation continuity.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Phase 1: Concept Development & Approval

1. **Pre-Concept Analysis** — before creating the concept document, study the landscape:
   - (a) **Read the [Task Transition Registry](../../infrastructure/task-transition-registry.md)** to understand how existing tasks connect and hand over work
   - (a2) **Study the [Process Framework Task Registry — Trigger & Output](../../infrastructure/process-framework-task-registry.md)** (`🔗 TRIGGER & OUTPUT` blocks and State File Trigger Index) to understand which state file statuses trigger which tasks and what outputs each task produces — this reveals the full signal chain the extension must integrate with
   - (b) **Study existing project patterns** solving similar problems — identify precedents in the project's current workflow (e.g., how E2E tracking handles non-standard test types, how validation dimensions were modularized)
   - (c) **Establish the abstraction model** — what are the natural levels in the project's architecture? Define categories specific to the project, not copied from generic industry terminology
   - (d) **Trace the full lifecycle end-to-end** — who triggers → who plans → who creates → who runs → who records → who reviews → how do you know what's left?
   - (e) **Evaluate scalability, abstraction level, and ownership** for every new concept — will this scale as the project grows? Does it match the project's architecture? Who owns each artifact, process, and decision?
   > Each sub-step should produce a concrete answer. If you cannot answer a question, that is a gap to resolve before proceeding.
2. **Create Framework Extension Concept Document** using the standardized script:
   ```powershell
   cd process-framework-local/proposals
   ./New-FrameworkExtensionConcept.ps1 -ExtensionName "[Extension Name]" -ExtensionDescription "[Brief description]" -Type [Creation/Modification/Hybrid] -ExtensionScope "[Extension scope]" -OpenInEditor
   ```
   - **`-Type`** selects a type-specific template: `Creation` (new artifacts only), `Modification` (changes to existing artifacts only), or `Hybrid` (both)
   - Script creates structural template in `/process-framework-local/proposals/[extension-name]-concept.md`
   - **CRITICAL**: Template requires extensive customization following [Framework Extension Customization Guide](../../guides/support/framework-extension-customization-guide.md)
   - Define extension scope and new capabilities to be added
   - Specify workflow definition with clear input-process-output flow
   - Create artifact dependency map showing how new artifacts serve as inputs for subsequent tasks
   - Define state tracking integration strategy (new permanent state files vs. updating existing ones)
   - Include integration strategy with current framework workflow
3. **Present Concept for Human Review** - Get explicit approval before proceeding to implementation
4. **Analyze Framework Impact** — For each existing framework element (task, script, template) that the extension will modify:
   - Read the complete element
   - Summarize: (a) what information it has at each step, (b) what it is responsible for, (c) what it delegates
   - Document how the extension affects it, considering its actual knowledge state
   - **Do not propose modifications based on assumptions** — present this analysis at the checkpoint first
   > **Validation script check**: If the extension modifies state file structure (columns, sections, headings), identify which [Validate-StateTracking.ps1](../../scripts/validation/Validate-StateTracking.ps1) surfaces parse those files and include them in the impact analysis. Run `Validate-StateTracking.ps1` before and after changes to catch regressions.
   >
   > **Column-index impact check**: If the extension modifies tracking file structure (adds, removes, or reorders columns), grep for `Split-MarkdownTableRow` and hardcoded column index patterns (e.g., `\[3\]`, `\[4\]`) in all scripts that reference the modified tracking file. Scripts that *read* column indices break just as silently as scripts that *write* them.
5. **🚨 CHECKPOINT**: Present concept document, impact analysis, and proposed implementation approach to human partner for approval
   > **Single-session lightweight path**: If the extension meets **all** of these criteria — (1) modification-type (changes existing artifacts only, no new tasks/templates/guides), (2) completable in a single session, (3) no new ID prefixes needed — then at this checkpoint, propose the lightweight path to the human partner. If approved:
   > - **Skip Phase 2 entirely** (Steps 6–10: no temp state file, no roadmap, no session planning)
   > - **Phase 3 compresses to**: Implement modifications (Step 12) → verify linked documents with grep sweep → integration testing (Step 15)
   > - **Phase 4 compresses to**: Checkpoint (Step 16) → update core framework files (Step 17) → update permanent state files (Step 19) → completion checklist (Step 22). Skip Steps 18 (usage docs), 20 (state file archival), and 21 (concept archival — archive concept inline at this step instead).

### Phase 2: State Tracking & Planning

6. **Create Temporary State Tracking File** — choose the template based on extension type:
   - **Creation-heavy** (new tasks, templates, scripts): Use `New-TempTaskState.ps1` (FrameworkExtension variant):
     ```powershell
     New-TempTaskState.ps1 -TaskName "[Extension Name]" -Variant "FrameworkExtension" -Description "Framework extension for [brief description]"
     ```
   - **Modification-heavy** (primarily changing existing tasks, templates, scripts): Use `New-StructureChangeState.ps1` with the `"Framework Extension"` ChangeType — lightweight artifact tracking without pilot/rollback/metrics:
     ```powershell
     New-StructureChangeState.ps1 -ChangeName "[Extension Name]" -ChangeType "Framework Extension" -Description "Framework extension for [brief description]"
     ```
7. **Develop Implementation Roadmap** with detailed multi-session breakdown in the temporary state file
8. **Identify Required Components** (tasks, templates, guides, scripts, directories) and their dependencies
   - If the extension introduces language-specific commands or tooling, check if new fields are needed in `languages-config` files. Use [Update-LanguageConfig.ps1](../../scripts/update/Update-LanguageConfig.ps1) to add fields consistently across all language configs and the template.
   - For each new task, verify its "When to Use" section defines concrete triggers (specific events, states, or conditions) — not generic "when needed" statements.
9. **Plan Integration Points** with existing framework components and state tracking files
10. **🚨 CHECKPOINT**: Present implementation roadmap, required components list, and session plan to human partner for approval

### Phase 3: Multi-Session Implementation

11. **Execute Session-by-Session Implementation** following the detailed roadmap in temporary state tracking file:
    - **Session 1**: Core task definitions and primary infrastructure
    - **Session 2**: Supporting templates and document creation scripts
    - **Session 3**: Usage guides and integration documentation
    - **Session 4**: Framework integration and testing
12. **Modify Existing Task Definitions** (if the extension requires inserting steps into existing tasks):
    > **Step renumbering warning**: Inserting or removing numbered steps triggers cascading renumbering of all subsequent steps plus internal "Step N" cross-references. For large tasks (e.g., Bug Fixing) this can involve 10+ sequential edits. To reduce effort and errors: (1) add steps at the end of a phase where possible to minimize renumbering, (2) batch-verify all "Step" references with grep after renumbering to catch stale cross-references.
13. **Progressive Component Creation** using two-phase document creation approach:
    - **Phase A - Structure Generation**: Use scripts (New-Task.ps1, New-Template.ps1, New-Guide.ps1) to generate basic document frameworks
      - ⚠️ **CRITICAL**: Script outputs are STARTING POINTS requiring extensive customization
      - Scripts create structural frameworks with placeholder content that MUST be replaced
    - **Phase B - Content Customization**: Follow best practices guides to fully customize generated structures
      - Templates require comprehensive content development following Template Development Guide
      - Guides require extensive customization following Guide Creation Best Practices Guide
      - Tasks require detailed process definition following Task Creation Guide
    > **⚠️ Cross-cutting reminder**: Each task created via [PF-TSK-001](new-task-creation-process.md) includes mandatory cross-cutting updates (Step 12L) — Task Transition Guide, Process Framework Task Registry, Task Trigger & Output Traceability, and existing task definitions' Next Tasks/Related Resources sections. Complete these during Phase 3 for each new task, not deferred to Phase 4.
14. **Update Temporary State Tracking** after each session with progress and next steps
15. **Integration Testing** to ensure compatibility with existing framework components

### Phase 4: Framework Integration & Finalization

16. **🚨 CHECKPOINT**: Present completed extension components, integration test results, and remaining work to human partner for review
17. **Update Core Framework Files**:
    - Update [ai-tasks.md](../../ai-tasks.md) with new tasks
    - Update [PF-documentation-map.md](../../PF-documentation-map.md) with all new artifacts
    - Update the appropriate [ID registry](../../PF-id-registry.json) with new ID prefixes if needed
18. **Create Usage Documentation** demonstrating how to use the new framework extension
19. **Update Permanent State Files** as defined in the concept document
20. **Move Temporary State Tracking** file to `/process-framework-local/state-tracking/temporary/old`
21. **Archive Completed Concept Document**: Move the framework extension concept document from `/process-framework-local/proposals/` to `/process-framework-local/proposals/old/` — the concept has served its purpose and should not remain alongside active proposals
22. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

### Concept Phase Outputs

- **Framework Extension Concept Document** - Comprehensive proposal in `/process-framework-local/proposals/[extension-name]-concept.md` including workflow definition, artifact dependency map, and state tracking integration plan
- **Impact Analysis** - Documentation of how the extension affects existing framework components

### Implementation Phase Outputs

- **New Task Definitions** - Multiple interconnected tasks with clear input requirements, process workflows, and output specifications
- **Supporting Infrastructure** - Templates, guides, scripts, and directories for extension functionality
- **Integration Documentation** - Documentation showing how the extension works with existing framework workflow
- **Updated Core Framework Files** - Modified ai-tasks.md, the appropriate documentation map (PF-documentation-map.md for PF artifacts, doc/PD-documentation-map.md for product artifacts, test/TE-documentation-map.md for test artifacts), and the appropriate ID registry

### State Tracking Outputs

- **Temporary State Tracking File** - Multi-session implementation tracker with detailed roadmap and progress tracking
- **Updated Permanent State Files** - Enhanced existing state files or new permanent state files as defined in concept

## State Tracking

The following state files must be updated as part of this task:

- **Temporary State Tracking File** - Create using New-TempTaskState.ps1 to track multi-session implementation progress
- [Documentation Map](../../PF-documentation-map.md) - Update with all new artifacts and their relationships
- [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) - Update with framework capability enhancements
- **Additional State Files** - As defined in the framework extension concept document (may include new permanent state files or updates to existing ones)

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

> **Note**: This is typically a multi-session task. Complete verification applies to the ENTIRE extension across all sessions. For **single-session lightweight path** extensions (approved at Step 5), items marked *(full path only)* can be skipped.

Before considering this task finished:

- [ ] **Verify Concept Phase**: Confirm concept development and approval completed

  - [ ] Framework extension concept document created using New-FrameworkExtensionConcept.ps1 script
  - [ ] Template extensively customized following Framework Extension Customization Guide
  - [ ] Comprehensive workflow definition with clear input-process-output flow
  - [ ] Artifact dependency map clearly shows how new artifacts serve as inputs for subsequent tasks
  - [ ] State tracking integration strategy defined (new permanent state files vs. updating existing ones)
  - [ ] Human approval obtained for concept before implementation

- [ ] **Verify Implementation Phase**: Confirm all extension components implemented using two-phase approach *(full path only)*

  - [ ] **Phase A - Structure Generation**: All document structures generated using appropriate scripts
    - [ ] Task definitions created using New-Task.ps1 (structural framework only)
    - [ ] Templates created using New-Template.ps1 (structural framework only)
    - [ ] Guides created using New-Guide.ps1 (structural framework only)
  - [ ] **Phase B - Content Customization**: All generated structures fully customized
    - [ ] Task definitions contain detailed input-process-output specifications (not placeholder content)
    - [ ] Templates contain comprehensive customizable content (not placeholder sections)
    - [ ] Guides contain detailed step-by-step instructions and examples (not template boilerplate)
  - [ ] Integration documentation shows how extension works with existing framework
  - [ ] Multi-session implementation tracked in temporary state file with two-phase progress tracking

- [ ] **Verify Framework Integration**: Confirm extension properly integrated

  - [ ] [ai-tasks.md](../../ai-tasks.md) updated with new tasks
  - [ ] [Documentation Map](../../PF-documentation-map.md) updated with all new artifacts and relationships
  - [ ] [PF ID Registry](../../PF-id-registry.json) updated with new prefixes if needed
  - [ ] Permanent state files updated as defined in concept document

- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Temporary state tracking file moved to `/process-framework-local/state-tracking/temporary/old` *(full path only)*
  - [ ] Framework extension concept document moved to `/process-framework-local/proposals/old/`
  - [ ] [Documentation Map](../../PF-documentation-map.md) reflects all new artifacts
  - [ ] [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) updated with framework capability enhancement
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-026" and context "Framework Extension Task"

## Next Tasks

- [**Process Improvement Task**](process-improvement-task.md) - If further refinements are needed for the extension
- **Extension-Specific Tasks** - Use the newly created tasks that comprise the framework extension

## Related Resources

### Core Framework Resources

- [Task-Based Development Principles](../../ai-tasks.md#understanding-task-based-development) - Understanding framework principles
- [New Task Creation Process](new-task-creation-process.md) - For creating individual tasks within extensions
- [Structure Change Task](structure-change-task.md) - For understanding structural modifications vs. extensions
- [Process Improvement Task](process-improvement-task.md) - For understanding granular improvements vs. extensions

### Development Infrastructure

- [Template Development Guide](../../guides/support/template-development-guide.md) - For creating extension-specific templates
- [Document Creation Script Development Guide](../../guides/support/document-creation-script-development-guide.md) - For creating automation scripts
- [Framework Extension Customization Guide](../../guides/support/framework-extension-customization-guide.md) - For customizing Framework Extension Concept documents
- [Visualization Creation Guide](../../guides/support/visualization-creation-guide.md) - For creating context maps

### State Management

- [New-TempTaskState.ps1](../../scripts/file-creation/support/New-TempTaskState.ps1) - State tracking for creation-heavy extensions (use `-Variant FrameworkExtension` for multi-artifact tracking)
- [New-StructureChangeState.ps1](../../scripts/file-creation/support/New-StructureChangeState.ps1) - State tracking for modification-heavy extensions
- [Documentation Map](../../PF-documentation-map.md) - Framework structure and artifact relationships
- [Process Improvement Tracking](../../../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) - Framework capability tracking
