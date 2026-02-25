---
id: PF-TSK-001
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.3
created: 2025-07-06
updated: 2026-02-15
task_type: Discrete
---

# New Task Creation Process

## Purpose & Context

Complete process for creating a new task from concept to implementation-ready definition, including task definition creation, supporting infrastructure setup (directories, templates, guides), and multi-session implementation tracking.

## AI Agent Role

**Role**: Process Engineer
**Mindset**: Systematic, efficiency-focused, improvement-oriented
**Focus Areas**: Workflow optimization, automation opportunities, standardization, process completeness
**Communication Style**: Identify process bottlenecks and improvement opportunities, ask about workflow preferences and automation needs

## When to Use

- When you have a new task concept that needs to be turned into a complete task definition
- When creating a task that requires supporting infrastructure (directories, templates, guides)
- When a task concept references components that don't exist yet
- Before implementing a complex task that needs multiple supporting artifacts
- When the new task will be implemented across multiple sessions and needs state tracking

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/support/new-task-creation-process-map.md)

- **Critical (Must Read):**

  - **Task Concept Description** - Human-provided description of the new task concept and its purpose
  - [Task Creation Guide](../../guides/guides/task-creation-guide.md) - Understanding task structure requirements
  - [Temporary State Tracking Customization Guide](../../guides/guides/temp-state-tracking-customization-guide.md) - For creating and managing multi-session state tracking
  - [AI Tasks System](../../../ai-tasks.md) - For updating the main task registry

- **Important (Load If Space):**

  - [Document Creation Script Development Guide](../../guides/guides/document-creation-script-development-guide.md) - For creating scripts when task generates new files
  - [Template Development Guide](../../guides/guides/template-development-guide.md) - For creating templates when needed
  - [Documentation Structure Guide](../../guides/guides/documentation-structure-guide.md) - For organizing and structuring documentation
  - [Visualization Creation Guide](../../guides/guides/visualization-creation-guide.md) - For creating context maps
  - [ID Registry](../../../id-registry.json) - For understanding and updating ID prefixes

- **Reference Only (Access When Needed):**
  - [Documentation Map](../../documentation-map.md) - For updating with new artifacts
  - [Visual Notation Guide](../../guides/guides/visual-notation-guide.md) - For creating context maps
  - [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - For tracking infrastructure completion
  - [New-Task.ps1](../../scripts/file-creation/New-Task.ps1) - Script for creating task definitions
  - [New-TempTaskState.ps1](../../scripts/file-creation/New-TempTaskState.ps1) - Script for creating temporary state files
  - [New-Template.ps1](../../scripts/file-creation/New-Template.ps1) - Script for creating templates
  - [New-Guide.ps1](../../scripts/file-creation/New-Guide.ps1) - Script for creating guides
  - [New-ContextMap.ps1](../../scripts/file-creation/New-ContextMap.ps1) - Script for creating context maps

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Create temporary state tracking file for multi-session implementation.**

## 🚨 FUNDAMENTAL CONCEPT: Two-Phase Task Creation Process

> **CRITICAL UNDERSTANDING**: Task creation involves TWO distinct phases that must be clearly understood:

### Phase 1: Meta-Template Generation (Automated)

**What happens**: Creation scripts generate structural frameworks with consistent metadata and organization

- **Tools**: New-Task.ps1, New-Template.ps1, New-Guide.ps1, New-ContextMap.ps1
- **Output**: Meta-templates with proper IDs, file structure, and placeholder sections
- **User Experience**: Scripts now display prominent warnings about template nature and customization requirements
- **Responsibility**: Scripts handle this automatically

### Phase 2: Content Customization (AI Agent Responsibility)

**What happens**: AI agent develops task-specific content within the meta-template frameworks

- **Tools**: Manual editing and content development
- **Output**: Fully functional, task-specific documentation with detailed content
- **Responsibility**: AI agent must customize all content

### ⚠️ Critical Misunderstanding to Avoid

**Scripts DO NOT create ready-to-use content** - they create structural frameworks that require extensive AI agent customization to become functional.

**🚨 NEW: Enhanced User Experience**: All creation scripts now display prominent "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - EXTENSIVE CUSTOMIZATION REQUIRED 🚨🚨🚨" warnings to prevent misuse and set proper expectations.

---

### Preparation

1. **Gather Task Concept**: Obtain clear description of the new task concept from human partner. Require him to take critical decisions
2. **Create Concept Document** (Recommended): Create a comprehensive concept document in `/doc/process-framework/proposals/[task-name]-concept.md` for human review before implementation
   - Include purpose, context, process outline, outputs, and integration considerations
   - Allow human partner to review and approve concept before proceeding
   - Reference concept document in temporary state tracking file
3. **Review Available Artifacts**: Examine what directories, templates, guides, and state files currently exist in the process framework
4. **Evaluate Task Requirements**: Determine which artifacts are actually needed for this specific task (not all tasks need all types of artifacts)

5. **🔍 Scope Assessment — Propose Approach to Human Partner**:

   Evaluate the following criteria:
   - Does this task create **new file types** as outputs?
   - Are **new templates, guides, or scripts** needed?
   - Will implementation require **multiple sessions**?

   Based on your evaluation, propose one of two modes to the human partner:

   | Criteria | → Lightweight Mode | → Full Mode |
   |----------|-------------------|-------------|
   | Creates new file types | No | Yes |
   | Needs new templates/guides/scripts | No | Yes |
   | Requires multiple sessions | No | Yes |

   **If ALL answers are "No"** → Propose **Lightweight Mode** to the human partner with your reasoning.
   **If ANY answer is "Yes"** → Propose **Full Mode** (current multi-session process).

   > **🚨 MANDATORY**: The AI agent MUST present the scope assessment and proposed mode to the human partner and receive explicit approval before proceeding. The human partner may override the recommendation in either direction.

   - If **Lightweight Mode approved** → Continue with [Lightweight Mode Process](#lightweight-mode-process) below
   - If **Full Mode approved** → Continue with [Full Mode Process](#full-mode-process) below

---

## Lightweight Mode Process

> **When to use**: Approved by human partner after Scope Assessment. For tasks that do NOT create new file types and do NOT require new templates, guides, or scripts. Completes in a single session.

### Lightweight Execution

6L. **Create Task Definition**: Use [New-Task.ps1](../../scripts/file-creation/New-Task.ps1) and [Task Creation Guide](../../guides/guides/task-creation-guide.md)
   ```bash
   # Windows command pattern:
   echo Set-Location 'c:\path\to\project\doc\process-framework\scripts\file-creation'; ^& .\New-Task.ps1 -TaskType 'Discrete' -TaskName 'Your Task Name' -WorkflowPhase '04-implementation' -Description 'Your description' -Confirm:$false > temp_task.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp_task.ps1 && del temp_task.ps1
   ```
   > **📝 NAMING**: Rename the generated file to include `-task` suffix (e.g., `your-task-name.md` → `your-task-name-task.md`)

7L. **🚨 CRITICAL: Customize Task Definition Content** — Using the [Task Creation Guide](../../guides/guides/task-creation-guide.md), customize all placeholder sections:
   - **When to Use** — Clear criteria and trigger conditions
   - **Context Requirements** — Critical, Important, and Reference inputs with actual links
   - **Process** — Detailed step-by-step instructions (Preparation, Execution, Finalization)
   - **Outputs** — Specific outputs with exact file locations and formats
   - **State Tracking** — Link to actual state files this task updates
   - **Task Completion Checklist** — Customized verification items
   - **Next Tasks** — Link to actual follow-up tasks
   - **AI Agent Role** — Appropriate professional role after "Purpose & Context" section
   > **🌍 IMPORTANT**: Make tasks **generic and reusable** — use category references and examples instead of project-specific details.

8L. **Create Context Map**: Use [New-ContextMap.ps1](../../scripts/file-creation/New-ContextMap.ps1) and customize
   ```bash
   # Windows command pattern:
   echo Set-Location 'c:\path\to\project\doc\process-framework\scripts\file-creation'; ^& .\New-ContextMap.ps1 -TaskName 'Your Task Name' -WorkflowPhase '02-drafting' -MapDescription 'Context map for Your Task Name task' -Confirm:$false > temp_map.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp_map.ps1 && del temp_map.ps1
   ```

9L. **Verify Documentation Updates**: Confirm that New-Task.ps1 automatically updated documentation-map.md, tasks/README.md, and ai-tasks.md

10L. **🚨 MANDATORY FINAL STEP**: Complete the [Lightweight Task Completion Checklist](#lightweight-task-completion-checklist) below

### Lightweight Outputs

- **Task Definition File** — Generated and fully customized task definition with AI Agent Role
- **Context Map** — Visual representation of task context and component relationships
- **✅ AUTOMATED Documentation Updates** — documentation-map.md, tasks/README.md, ai-tasks.md updated by New-Task.ps1

> **Not produced in Lightweight Mode**: No temp state file, no concept document, no templates, no guides, no scripts, no directory structures, no ID registry changes.

---

## Full Mode Process

> **When to use**: Approved by human partner after Scope Assessment. For tasks that create new file types or require new templates, guides, or scripts. Spans multiple sessions.

### Execution

5. **Create Temporary State Tracking File**: Use the [New-TempTaskState.ps1](../../scripts/file-creation/New-TempTaskState.ps1) script to create tracking file with implementation roadmap

   ```bash
   # Windows command pattern:
   echo Set-Location 'c:\path\to\project\doc\process-framework\scripts\file-creation'; ^& .\New-TempTaskState.ps1 -TaskName 'Task Name' -TaskType 'Discrete' -Description 'Brief task description' -Confirm:$false > temp_state.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp_state.ps1 && del temp_state.ps1
   ```
   > **Note**: Update the path to match your actual project location. TaskType options: Discrete, Cyclical, Support

   **Reference**: [Temporary State File Customization Guide](../../guides/guides/temp-state-tracking-customization-guide.md)

6. **🚨 CRITICAL: Customize Temporary State File** - Using the [Temporary State File Customization Guide](../../guides/guides/temp-state-tracking-customization-guide.md), customize the generated temp state file:

   - **Task Overview** - Update task name, type, and ID information
   - **Infrastructure Analysis** - Document which artifacts are needed vs. available for reuse
   - **Required Artifacts Table** - List specific templates, guides, scripts, directories needed for this task
   - **File Creation Requirements** - Determine whether the task creates new files (determines if document creation infrastructure is needed)
   - **Implementation Roadmap** - Adjust phases and priorities based on task requirements
   - **Session Planning** - Customize for expected workflow and dependencies

   > **Reference**: This transforms the meta-template into a functional tracking document for multi-session implementation

7. **Execute Multi-Session Implementation**: Follow the structured roadmap in the temporary state file across multiple sessions:

   **Session 1 - Core Task Infrastructure:**

   - Create task definition using [New-Task.ps1](../../scripts/file-creation/New-Task.ps1) and [Task Creation Guide](../../guides/guides/task-creation-guide.md)
     ```bash
     # Windows command pattern:
     echo Set-Location 'c:\path\to\project\doc\process-framework\scripts\file-creation'; ^& .\New-Task.ps1 -TaskType 'Discrete' -TaskName 'Your Task Name' -WorkflowPhase '04-implementation' -Description 'Your description' -Confirm:$false > temp_task.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp_task.ps1 && del temp_task.ps1
     ```
     > **Note**: Script will display prominent warnings about template nature and customization requirements
     > **✨ ENHANCED**: Script now automatically updates three documentation files: documentation-map.md, tasks/README.md, and ai-tasks.md
     > **📝 NAMING**: Rename the generated file to include `-task` suffix (e.g., `your-task-name.md` → `your-task-name-task.md`) for easy identification

   - **🚨 CRITICAL: Phase 2 - Customize Task Definition Content** - Using the [Task Creation Guide](../../guides/guides/task-creation-guide.md), customize all placeholder sections in the generated task file:
     - **When to Use** - Clear criteria and trigger conditions specific to this task
     - **Context Requirements** - Critical, Important, and Reference inputs with actual links to files
     - **Process** - Detailed step-by-step instructions (Preparation, Execution, Finalization) specific to this task
     - **Outputs** - Specific outputs with exact file locations and formats
     - **State Tracking** - Link to actual state files that this task updates
     - **Task Completion Checklist** - Customize verification items for this specific task
     - **Next Tasks** - Link to actual follow-up tasks in the workflow
     > **Reference**: See "Phase 2: Content Customization" section above - this transforms the meta-template into a functional task definition
     >
     > **🌍 IMPORTANT**: Make tasks **generic and reusable** - use category references and examples (e.g., "business types: B2B, B2C, SaaS") instead of project-specific details. Use placeholders in commands. See [Task Creation Guide](../../guides/guides/task-creation-guide.md) for detailed guidance.

   - **Assign AI Agent Role**: Add appropriate professional role assignment to the task definition after "Purpose & Context" section
     - Select from established professional roles (Senior Software Engineer, Software Architect, Debugging Specialist, Code Quality Auditor, Product Analyst, Technical Lead, DevOps Engineer, QA Engineer, Business Analyst, Legal Requirements Specialist, etc.)
     - Use format: Role, Mindset, Focus Areas, Communication Style (keep to 3-4 lines maximum)
   - Evaluate if task creates new files as outputs (determines if document creation infrastructure is needed)

   **Session 2 - Document Creation Infrastructure (conditional):**

   > **⚠️ CONDITIONAL**: Only execute if task creates new files as outputs

   - Create directory structure for task outputs (consider using subdirectories for better organization)
   - Create document creation script using [Document Creation Script Development Guide](../../guides/guides/document-creation-script-development-guide.md) and [Document Creation Script Template](../../templates/templates/document-creation-script-template.ps1)
     - Use `DirectoryType` parameter for ID registry-based directory resolution
     - Configure subdirectory mappings in ID registry if needed
   - Update [ID Registry](../../../id-registry.json) with new ID prefix for file types created by task

   **Session 3 - Templates and Guides:**

   - Create task-specific template using [Template Development Guide](../../guides/guides/template-development-guide.md) and [New-Template.ps1](../../scripts/file-creation/New-Template.ps1) (if task creates files)
     ```bash
     # Windows command pattern:
     echo Set-Location 'c:\path\to\project\doc\process-framework\scripts\file-creation'; ^& .\New-Template.ps1 -TemplateName 'Your Template Name' -TemplateDescription 'Template description' -DocumentPrefix 'PF-XXX' -DocumentCategory 'YourCategory' -Confirm:$false > temp_template.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp_template.ps1 && del temp_template.ps1
     ```
     > **Note**: Script will display prominent warnings about template nature and customization requirements. Update the path to match your actual project location. Replace 'PF-XXX' with the appropriate document prefix and 'YourCategory' with the document category.

   - Create template customization guide using [New-Guide.ps1](../../scripts/file-creation/New-Guide.ps1) and [Guide Creation Best Practices Guide](../../guides/guides/guide-creation-best-practices-guide.md) (if task creates files)
     ```bash
     # Windows command pattern:
     echo Set-Location 'c:\path\to\project\doc\process-framework\scripts\file-creation'; ^& .\New-Guide.ps1 -GuideTitle 'Your Guide Name' -GuideDescription 'Guide description' -GuideCategory 'guides' -Confirm:$false > temp_guide.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp_guide.ps1 && del temp_guide.ps1
     ```
     > **Note**: Script will display prominent warnings about template nature and customization requirements. Update the path to match your actual project location.

     - **Purpose**: Guide users on how to customize the template created by the task's script
     - **Focus**: Template structure, customization decision points, step-by-step instructions for using the script and customizing its output
     - **NOT**: A guide for how to execute the task itself

     > **🚨 CRITICAL**: Never create "task usage guides" that explain task workflow execution. These duplicate task definitions and create maintenance overhead. Always focus on artifact customization instead.

   **Session 4 - Documentation and Visualization:**

   - Update [Documentation Map](../../documentation-map.md) with all new artifacts
   - Create context map using [Visualization Creation Guide](../../guides/guides/visualization-creation-guide.md) and [New-ContextMap.ps1](../../scripts/file-creation/New-ContextMap.ps1)
     ```bash
     # Windows command pattern:
     echo Set-Location 'c:\path\to\project\doc\process-framework\scripts\file-creation'; ^& .\New-ContextMap.ps1 -TaskName 'Your Task Name' -WorkflowPhase '02-drafting' -MapDescription 'Context map for Your Task Name task' -Confirm:$false > temp_map.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp_map.ps1 && del temp_map.ps1
     ```
     > **Note**: Script will display prominent warnings about template nature and customization requirements. Update the path to match your actual project location.

8. **Track Progress**: Update the temporary state file after each session with:
   - Completed items and their status
   - Issues encountered and resolutions
   - Next session planning
   - Placeholder component tracking

### Finalization

9. **Update Documentation Map**: Add all new artifacts to the [documentation map](../../documentation-map.md)
10. **Verify Infrastructure Completeness**: Ensure all required directories and placeholder files exist
11. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

### Preparation Outputs (Optional but Recommended)

- **Task Concept Document** - Comprehensive concept document in `/doc/process-framework/proposals/[task-name]-concept.md` for human review and approval

### Session 1 Outputs (Core Infrastructure)

- **Task Definition File** - Generated task definition in `/doc/process-framework/tasks/[type]/[task-name].md` with assigned AI Agent Role
- **Temporary State Tracking File** - Multi-session implementation tracker in `/doc/process-framework/state-tracking/temporary/temp-task-creation-[task-name].md`
- **✅ AUTOMATED Documentation Updates** - Three files automatically updated by New-Task.ps1:
  - **Documentation Map** - New task added to [documentation-map.md](../../documentation-map.md) with proper categorization
  - **Tasks README** - New task added to [tasks/README.md](../README.md) in appropriate task type table
  - **AI Tasks Registry** - New task added to [ai-tasks.md](../../../ai-tasks.md) with correct section and table format
- **Required Directory Structure** - Only the directories actually needed for task outputs (if task creates new files)

### Session 2 Outputs (Document Creation Infrastructure - conditional)

> **⚠️ CONDITIONAL**: Only produced if task creates new files as outputs

- **Task Output Directory Structure** - Directories created for storing task outputs
- **Document Creation Script** - PowerShell script for generating files created by the task (using document-creation-script-development-guide.md and document-creation-script-template.ps1)
- **Updated ID Registry** - New ID prefix added to [id-registry.json](../../../id-registry.json) for file types created by task

### Session 3 Outputs (Templates and Guides)

- **Task-Specific Template** - Template for files generated by the task (created using template-development-guide.md and New-Template.ps1, only if task creates files)
- **Template Customization Guide** - Comprehensive guide for customizing the template created by the task's script (created using New-Guide.ps1 and guide-creation-best-practices-guide.md, only if task creates files)
  - **Purpose**: Helps users understand how to use the script and customize the resulting template
  - **Content**: Template structure analysis, customization decision points, step-by-step instructions
  - **NOT**: A guide for executing the task workflow itself

### Session 4 Outputs (Documentation and Visualization)

- **Updated Documentation Map** - All new artifacts registered in [documentation-map.md](../../documentation-map.md)
- **Context Map** - Visual representation of task context and component relationships (created using visualization-creation-guide.md and New-ContextMap.ps1)

### Final Outputs (All Sessions Complete)

- **Updated Documentation Map** - All new artifacts registered in the [documentation map](../../../documentation-map.md)
- **Complete Task Infrastructure** - Fully functional task with all supporting components
- **Deleted Temporary State File** - Temporary tracking file removed after completion

## State Tracking

The following state files are updated as part of this task:

### ✅ Automated Updates (via New-Task.ps1)

- [Documentation Map](../../documentation-map.md) - **AUTOMATED**: Add new task to appropriate category section
- [Tasks README](../README.md) - **AUTOMATED**: Add new task to task type table with flexible pattern matching
- [AI Tasks System](../../../ai-tasks.md) - **AUTOMATED**: Add new task to appropriate category with correct table format

### 🔧 Manual Updates Required (Full Mode only)

- **Temporary State File** - Create `temp-task-creation-[task-name].md` to track implementation progress across sessions

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

> **Note**: Use the checklist matching the mode approved during Scope Assessment.

### Lightweight Task Completion Checklist

> **Use this checklist when Lightweight Mode was approved by the human partner.**

- [ ] **Scope Assessment Documented**: Human partner approved Lightweight Mode
- [ ] **Task Definition Verified**:
  - [ ] Task definition file generated using [New-Task.ps1](../../scripts/file-creation/New-Task.ps1)
  - [ ] **🚨 Task definition content fully customized** — All placeholder sections replaced with task-specific content:
    - [ ] When to Use section has clear criteria
    - [ ] Context Requirements lists actual files with links
    - [ ] Process section has detailed step-by-step instructions
    - [ ] Outputs section specifies exact deliverables and locations
    - [ ] State Tracking links to actual state files
    - [ ] Task Completion Checklist customized for this task
    - [ ] Next Tasks links to actual follow-up tasks
    - [ ] **🌍 Task is generic and reusable** — Uses category references and examples instead of project-specific details
  - [ ] **AI Agent Role assigned** with appropriate professional role, mindset, focus areas, and communication style
- [ ] **Context Map Created**: Context map created using [New-ContextMap.ps1](../../scripts/file-creation/New-ContextMap.ps1) and customized with task-specific components
- [ ] **Documentation Updates Verified**: Confirm New-Task.ps1 automatically updated documentation-map.md, tasks/README.md, and ai-tasks.md
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-001" and context "New Task Creation Process (Lightweight)"
  - **⚠️ IMPORTANT**: Evaluate the New Task Creation Process itself (PF-TSK-001), not the task you created.

---

### Full Mode Task Completion Checklist

> **Use this checklist when Full Mode was approved by the human partner.** Complete verification applies to the ENTIRE task across all sessions.

#### Session 1 Completion (Core Infrastructure)

- [ ] **Core Outputs Verified**:
  - [ ] Task definition file generated using [New-Task.ps1](../../scripts/file-creation/New-Task.ps1) and [Task Creation Guide](../../guides/guides/task-creation-guide.md)
  - [ ] **🚨 Phase 2: Task definition content fully customized** - All placeholder sections replaced with task-specific content:
    - [ ] When to Use section has clear criteria
    - [ ] Context Requirements lists actual files with links
    - [ ] Process section has detailed step-by-step instructions
    - [ ] Outputs section specifies exact deliverables and locations
    - [ ] State Tracking links to actual state files
    - [ ] Task Completion Checklist customized for this task
    - [ ] Next Tasks links to actual follow-up tasks
    - [ ] **🌍 Task is generic and reusable** - Uses category references and examples instead of project-specific details, placeholders in commands
  - [ ] **AI Agent Role assigned** to task definition after "Purpose & Context" section with appropriate professional role, mindset, focus areas, and communication style
  - [ ] Temporary state tracking file created using [New-TempTaskState.ps1](../../scripts/file-creation/New-TempTaskState.ps1) script
  - [ ] File creation evaluation completed (CREATES_FILES or NO_FILES_CREATED decision made)
  - [ ] ✅ **AUTOMATED**: Documentation Map, Tasks README, and AI Tasks registry automatically updated by script

#### Session 2 Completion (Document Creation Infrastructure - conditional)

> **⚠️ CONDITIONAL**: Only verify if task creates new files as outputs

- [ ] **Document Creation Infrastructure Verified**:
  - [ ] Task output directory structure created
  - [ ] Document creation script created using [Document Creation Script Development Guide](../../guides/guides/document-creation-script-development-guide.md) and [Document Creation Script Template](../../templates/templates/document-creation-script-template.ps1)
  - [ ] ID registry updated with new prefix for file types created by task
  - [ ] Script tested and functional

#### Session 3 Completion (Templates and Guides)

- [ ] **Templates and Guides Verified**:
  - [ ] Task-specific template created using [Template Development Guide](../../guides/guides/template-development-guide.md) and [New-Template.ps1](../../scripts/file-creation/New-Template.ps1) (if task creates files)
  - [ ] Template customization guide created using [New-Guide.ps1](../../scripts/file-creation/New-Guide.ps1) and [Guide Creation Best Practices Guide](../../guides/guides/guide-creation-best-practices-guide.md) (if task creates files)
  - [ ] Guide focuses on template customization and script usage, NOT task execution workflow
  - [ ] Both documents properly integrated with task definition

#### Session 4 Completion (Documentation and Visualization)

- [ ] **Documentation and Visualization Verified**:
  - [ ] [Documentation Map](../../documentation-map.md) updated with all new artifacts
  - [ ] Context map created using [Visualization Creation Guide](../../guides/guides/visualization-creation-guide.md) and [New-ContextMap.ps1](../../scripts/file-creation/New-ContextMap.ps1)
  - [ ] Context map properly shows component relationships and task context

#### Final Task Completion (All Sessions)

- [ ] **All Infrastructure Complete**:
  - [ ] All components from temporary state file implemented (no placeholders remaining)
  - [ ] [Documentation Map](../../documentation-map.md) updated with all new artifacts
  - [ ] Temporary state tracking file deleted (task infrastructure complete)
  - [ ] Task fully functional and ready for use
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-001" and context "New Task Creation Process (Full Mode)"
  - **⚠️ IMPORTANT**: Evaluate the New Task Creation Process itself (PF-TSK-001), not the task you created. Assess how well the process worked, the effectiveness of the tools used (New-Task.ps1, guides, etc.), and the clarity of the process steps.

## Next Tasks

### Lightweight Mode — Next Tasks

- **New Task Usage** — The new task is ready for use immediately after completion

### Full Mode — Next Tasks

- **Continue Multi-Session Implementation** — Use the temporary state tracking file to continue implementation across sessions:
  - Session 2: Document creation infrastructure (if task creates new files)
  - Session 3: Templates and guides creation
  - Session 4: Visualization and context mapping
- **Track Progress** — Update temporary state file after each session with completed items and next steps
- **Delete Temporary State File** — Remove the temporary tracking file once all infrastructure is complete and functional

### Follow-Up Tasks (Both Modes)

- [**Process Improvement**](process-improvement-task.md) - If task creation reveals process gaps or improvements needed
- **New Task Usage** - Once complete, the new task can be used for its intended purpose

## Related Resources

### Core Guides

- [Task Creation Guide](../../guides/guides/task-creation-guide.md) - Comprehensive guide for creating and improving tasks
- [Temporary State File Customization Guide](../../guides/guides/temp-state-tracking-customization-guide.md) - Guide for customizing temporary state files for different workflows
- [Document Creation Script Development Guide](../../guides/guides/document-creation-script-development-guide.md) - Guide for creating PowerShell scripts that generate documents
- [Template Development Guide](../../guides/guides/template-development-guide.md) - Guide for creating new templates
- [Documentation Structure Guide](../../guides/guides/documentation-structure-guide.md) - Guide for organizing and structuring documentation
- [Visualization Creation Guide](../../guides/guides/visualization-creation-guide.md) - Guide for creating context maps and other visualizations

### Automation Scripts

- [New-Task.ps1](../../scripts/file-creation/New-Task.ps1) - Script for creating task definitions
- [New-TempTaskState.ps1](../../scripts/file-creation/New-TempTaskState.ps1) - Script for creating temporary state tracking files
- [New-Template.ps1](../../scripts/file-creation/New-Template.ps1) - Script for creating templates
- [New-Guide.ps1](../../scripts/file-creation/New-Guide.ps1) - Script for creating guides
- [New-ContextMap.ps1](../../scripts/file-creation/New-ContextMap.ps1) - Script for creating context maps

### Templates

- [Task Template](../../templates/templates/task-template.md) - Template for creating task definitions
- [Temporary Task State Template](../../templates/templates/temp-task-creation-state-template.md) - Template for multi-session state tracking
- [Document Creation Script Template](../../templates/templates/document-creation-script-template.ps1) - Template for creating PowerShell scripts
- [Context Map Template](../../templates/templates/context-map-template.md) - Template for creating context maps

### Related Tasks

- [Process Improvement Task](process-improvement-task.md) - For implementing infrastructure components over time
