---
id: PF-GDE-004
type: Process Framework
category: Guide
version: 1.0
created: 2025-05-27
updated: 2025-05-30
---

# Task Creation and Improvement Guide

## Purpose

This guide provides comprehensive instructions for creating new tasks and improving the overall task structure in the BreakoutBuddies project. It ensures consistency across all task documentation and helps maintain the task-based development approach.

## When to Use

- When creating a new task that doesn't exist in the current structure
- When improving or refining existing task definitions
- When evaluating the overall task structure for completeness and effectiveness
- When integrating new development processes into the task-based approach

## Task Types Overview

The BreakoutBuddies project organizes tasks into three categories:

### 1. Discrete Tasks

**Characteristics:**

- One-time activities with clear start and end points
- Performed sequentially with specific completion criteria
- Results in specific, measurable outputs

**Examples:** Feature Implementation, Bug Fixing, TDD Creation

**Directory:** `../../tasks/01-planning/`, `../../tasks/02-design/`, `../../tasks/03-testing/`, `../../tasks/04-implementation/`, `../../tasks/05-validation/`, `../../tasks/06-maintenance/`, `../../tasks/07-deployment/`

### 2. Cyclical Tasks

**Characteristics:**

- Recurring activities that follow a defined cycle
- Performed at regular intervals or triggered by specific events
- Follow a defined cycle with clear triggers and frequency

**Examples:** Tools Review, Documentation Tier Adjustment

**Directory:** `../../tasks/cyclical/`

## 🚨 CRITICAL: Understanding the Two-Phase Task Creation Process

> **FUNDAMENTAL CONCEPT**: Task creation involves TWO distinct phases that must be clearly understood:

### Phase 1: Meta-Template Generation (Automated)

**What happens**: Creation scripts generate structural frameworks with consistent metadata and organization

- **Tools involved**: New-Task.ps1, New-Template.ps1, New-Guide.ps1, New-ContextMap.ps1
- **Output**: Meta-templates with proper IDs, file structure, and placeholder sections
- **Responsibility**: Scripts handle this automatically

### Phase 2: Content Customization (AI Agent Responsibility)

**What happens**: AI agent develops task-specific content within the meta-template frameworks

- **Tools involved**: Manual editing and content development
- **Output**: Fully functional, task-specific documentation with detailed content
- **Responsibility**: AI agent must customize all content

### ⚠️ Common Misunderstanding

**Scripts DO NOT create ready-to-use content** - they create structural frameworks that require extensive AI agent customization to become functional.

---

## Creating a New Task

> **🚨 CRITICAL: ALWAYS use automation scripts for task creation. Manual task creation is NOT permitted.**

Follow these steps to create a new task:

1. **Determine the Task Type**

   - Review the characteristics of each task type
   - Consider how the task fits into the overall workflow
   - Determine if it's discrete, cyclical, or continuous

2. **Use the Task Creation Script**

   ```powershell
   # Navigate to the script directory
   cd doc/process-framework/scripts/file-creation

   # Create a new task (Interactive PowerShell)
   .\New-Task.ps1 -TaskName "Task Name" -TaskType "Discrete" -Category "04-implementation" -Description "Brief task description"
   ```

   **For Automated Execution (Bash tool/CI):**

   > **⚠️ Note**: When using the Bash tool (which runs via Windows cmd.exe), PowerShell's `-Command` parameter doesn't execute due to quote handling issues. The workaround creates a temporary script file instead.

   ```cmd
   echo Set-Location 'c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\process-framework\scripts\file-creation'; ^& .\New-Task.ps1 -TaskType 'Discrete' -TaskName 'Task Name' -Category '04-implementation' -Description 'Brief task description' -Confirm:$false > temp_task.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp_task.ps1 && del temp_task.ps1
   ```

   **Key differences:**
   - Uses `echo ... > temp.ps1` to create temporary script file
   - Uses `-File` parameter instead of `-Command`
   - Includes `-Confirm:$false` to bypass interactive prompts
   - Automatically cleans up temporary file after execution

   **Parameters:**

   - `-TaskName`: Name of the task (required)
   - `-TaskType`: Type of task - "Discrete", "Cyclical", or "Support" (required)
   - `-Category`: Task category - "01-planning", "02-design", "03-testing", "04-implementation", "05-validation", "06-maintenance", "07-deployment" (optional, defaults to "01-planning")
   - `-Description`: Brief task description (optional)
   - `-OpenInEditor`: Switch to open the created file in the editor (optional)

   **Why Script Usage Is Mandatory:**

   - Ensures proper sequential ID assignment and prevents conflicts
   - Maintains consistent metadata across all task files
   - Updates the tracking system automatically
   - Enforces process constraints and validation rules

3. **NEVER Manually Create Task Files**

   - Manual creation will break the ID sequence and tracking system
   - Script usage is not optional - it is required for process integrity

4. **🎯 PHASE 2: Content Customization** (This is where the real work begins)

   > **IMPORTANT**: The script created a meta-template. Now you must develop all task-specific content.

   **Required Content Development** (Metadata is automatically filled by the script):

   - **Purpose & Context**: Clearly explain what the task accomplishes and its role in the process
   - **AI Agent Role**: Assign appropriate professional role with mindset, focus areas, and communication style
   - **When to Use**: Specify scenarios, prerequisites, and trigger conditions
   - **Inputs**: List all required inputs with links to sources
   - **Process**: Structure the process into Preparation, Execution, and Finalization phases
   - **Outputs**: Define all expected outputs with exact locations and detailed descriptions
   - **State Tracking**: Specify which state files to update and what information to change
   - **Task Completion Checklist**: Create a structured checklist with specific verification steps
   - **Next Tasks**: Link to tasks that typically follow with connection explanations
   - **Related Resources**: Add links to helpful reference materials

5. **Add Type-Specific Sections**

   - For Cyclical Tasks: Add "Cycle Frequency" and "Trigger Events" sections
   - For Cyclical Tasks: Add "Metrics and Evaluation" and "Continuous Improvement" sections

6. **Update the Documentation Map**

   - Add the new task to the appropriate section in `../doc/process-framework/documentation-map.md`
   - Include the ID, file path, type, description, and linked from information

7. **Update the Tasks README**
   - Add the new task to the appropriate table in `../doc/process-framework/tasks/README.md`
   - Include the task name, description, and when to use information

## Task Template Sections Explained

### Core Sections (All Task Types)

#### Purpose & Context

A clear, concise statement of what the task accomplishes and why it's important in the overall process. This should be 1-2 sentences that capture the essence of the task and its role in the development workflow.

#### AI Agent Role

Assign a professional role that optimizes the AI agent's approach to this specific task type. Use this format:

```markdown
## AI Agent Role

**Role**: [Professional Role Title]
**Mindset**: [Key behavioral and thinking patterns for this role]
**Focus Areas**: [Primary areas of attention and expertise]
**Communication Style**: [How to interact with human partner in this role]
```

**Guidelines:**

- Keep each element to 1 line maximum (3-4 lines total)
- Choose roles that match the task's primary expertise needs
- Select from established professional roles (Senior Software Engineer, Software Architect, Debugging Specialist, Code Quality Auditor, Product Analyst, Technical Lead, DevOps Engineer, QA Engineer, etc.)
- Focus on mindset and communication style that best serves the task's objectives

**Example:**

```markdown
## AI Agent Role

**Role**: Senior Software Engineer
**Mindset**: Pragmatic, quality-focused, delivery-oriented
**Focus Areas**: Code quality, maintainability, performance optimization
**Communication Style**: Present trade-offs between speed and quality, ask about priorities when multiple approaches exist
```

#### When to Use

A bulleted list of specific scenarios where this task is appropriate, including any prerequisites or trigger conditions. This helps users quickly determine if this is the right task for their current work.

#### Context Requirements

A prioritized list of all files, information, and resources needed to complete the task, organized by importance:

1. **Context Map Reference**: Include a link to the relevant context map at the top of this section

   ```markdown
   <!-- [View Context Map for this task](../../../visualization/context-maps/[task-type]/[task-name]-map.md) - File not found -->
   ```

2. **Prioritized Requirements**:
   - **Critical (Must Read):** Files and information that must be loaded into the AI agent's context window
   - **Important (Load If Space):** Files that provide valuable context but could be accessed later if needed
   - **Reference Only (Access When Needed):** Files only needed for specific operations like updating state tracking

Include file paths where applicable and brief descriptions of each item, with links to source documents where appropriate.

> **Note**: For any new task, create a corresponding context map using the [context map template](../../templates/templates/context-map-template.md) and place it in the appropriate directory under `/doc/process-framework/visualization/context-maps/`.

#### Process

Structured process guidance with clear phases:

1. **Preparation**: Initial steps to get ready for the task
2. **Execution**: Main task steps with detailed instructions
3. **Finalization**: Final steps and verification

For each phase, use numbered steps with clear, actionable guidance. Include command examples for automation steps and highlight decision points.

#### Outputs

A bulleted list of all files, changes, and other outputs produced by the task. Use bold formatting for output names, include exact file paths (including subdirectories where applicable), and provide detailed descriptions of each output.

**File Path Guidelines:**

- Include full paths with subdirectories (e.g., `/doc/product-docs/technical/api/specifications/specifications/[api-name].md`)
- Use subdirectories for better organization when task creates multiple file types
- Ensure paths match the directory mappings configured in the ID registry

#### State Tracking

Specify exactly which state files must be updated and what information should be changed in each file. Be specific about the format and content of updates.

#### Task Completion Checklist

A structured checklist that must be completed before the task is considered finished:

- Output verification with specific items for each output
- State file update verification with specific checks
- Feedback form completion with exact commands

#### Next Tasks

Links to tasks that typically follow this one, with brief descriptions of how they connect to the current task. Include guidance on continuous tasks that should be performed alongside next tasks.

#### Related Resources

Links to additional resources that may be helpful when performing the task, such as reference documents, examples, or related guides.

### Type-Specific Sections

#### For Cyclical Tasks

- **Cycle Frequency**: How often the task should be performed (e.g., monthly, after every 5 features)
- **Trigger Events**: Specific events that trigger this task (e.g., before a release, when feedback accumulates)

#### For Cyclical Tasks

- **Metrics and Evaluation**: How to measure the effectiveness of the task
- **Continuous Improvement**: How the task or process should be evaluated and improved over time

## Improving Existing Tasks

When improving existing tasks, focus on these aspects:

1. **Consistency Check**

   - Ensure the task follows the current template format
   - Verify that all required sections are present and complete
   - Check that metadata is correct and up-to-date

2. **Content Enhancement**

   - Improve clarity of instructions and explanations
   - Add missing details or context
   - Update outdated information
   - Enhance process steps with more specific guidance

3. **Cross-Reference Verification**

   - Verify that links to other tasks are correct
   - Ensure state tracking references are accurate
   - Check that input and output file paths exist

4. **Usability Improvements**

   - Add examples where helpful
   - Include troubleshooting guidance for common issues
   - Consider adding diagrams or visual aids for complex processes

5. **Feedback Integration**
   - Review feedback forms related to the task
   - Incorporate improvements suggested in feedback
   - Address pain points identified by users

## Evaluating the Overall Task Structure

Periodically evaluate the task structure for:

1. **Completeness**

   - Are all necessary development activities covered by tasks?
   - Are there gaps in the workflow that need new tasks?
   - Do the tasks collectively cover the entire development lifecycle?

2. **Clarity**

   - Is it clear which task to use in different scenarios?
   - Are task boundaries well-defined with minimal overlap?
   - Are task names descriptive and intuitive?

3. **Efficiency**

   - Do tasks minimize duplication of effort?
   - Is the level of detail appropriate (not too granular or too broad)?
   - Do tasks flow logically from one to another?

4. **Adaptability**
   - Can the task structure accommodate new development approaches?
   - Is it flexible enough to evolve with the project?
   - Can it scale as the project grows?

## Integration with AI-Tasks Workflow

The task structure should align with the AI-Tasks workflow described in `/ai-tasks.md`:

1. **Task Type Mapping**

   - Ensure categorized (01-planning through 07-deployment), cyclical, and support tasks map to the task types in AI-Tasks
   - Verify that task definitions are referenced correctly in AI-Tasks

2. **State Tracking Alignment**

   - Confirm that state tracking in tasks aligns with the state files listed in AI-Tasks
   - Ensure consistent state tracking approaches across all tasks

3. **Feedback System Integration**

   - Verify that all tasks include the feedback collection step
   - Ensure feedback forms are properly referenced and used

4. **Collaboration Guidance**
   - Include appropriate guidance for AI-human collaboration in task definitions
   - Highlight decision points that require human input

## Best Practices for Task Documentation

1. **Be Specific and Actionable**

   - Provide clear, specific instructions rather than general guidance
   - Use action verbs and imperative language in process steps

2. **Maintain Consistent Formatting**

   - Use consistent heading levels, bullet styles, and terminology
   - Follow the established template structure

3. **Focus on the User's Perspective**

   - Write task documentation from the perspective of someone using it
   - Anticipate questions and provide answers proactively

4. **Keep It Current**

   - Regularly review and update task documentation
   - Remove outdated information promptly

5. **Balance Detail and Brevity**

   - Include enough detail to be helpful without overwhelming
   - Use concise language and avoid unnecessary explanation

6. **Proper Feedback Collection**

   - **🚨 CRITICAL: Feedback collection MUST follow the structured process below**
   - Present draft output to the human partner
   - Request specific feedback using this format:

     ```
     ## Request for Feedback

     Now that I've implemented [task name], I'd like to get your feedback on:

     1. **Usefulness**: How useful do you find this [output]? (1-5 scale)
     2. **Clarity**: How clear is the [specific aspect]? (1-5 scale)
     3. **Efficiency**: How efficient do you think this will be compared to [alternative]? (1-5 scale)
     4. **Any additional comments or suggestions** for improving this [output]
     ```

   - Wait for human partner response before proceeding
   - Document feedback in the feedback form
   - Make adjustments based on the feedback received
   - Verify that the changes address the feedback
   - NEVER skip the feedback collection step

7. **Manage Dependencies Properly**
   - **🚨 CRITICAL: Always identify and document dependencies for any task**
   - List all files, scripts, and components the task depends on
   - Confirm all dependencies exist before finalizing the task
   - Clearly mark any dependencies that need to be created:
     ```markdown
     > **⚠️ DEPENDENCY NOTE:** The `[component]` is currently a placeholder and needs to be fully
     > implemented before this task can be used. [Include specific requirements]
     ```
   - If a dependency doesn't exist, create a placeholder with clear "PLACEHOLDER" markings
   - Add dependency implementation to the Process Improvement Tracking document
   - NEVER reference non-existent components without proper documentation

## Example: Creating a New Discrete Task

Here's an example of creating a new categorized task following the **mandatory script-based approach**:

1. **Determine the Task Type**: This is a one-time activity with clear start/end points, so it's a Discrete Task.

2. **Use the Task Creation Script** (🚨 MANDATORY):

   ```powershell
   # Navigate to the script directory
   cd doc/process-framework/scripts/file-creation

   # Create the new task using the script
   .\New-Task.ps1 -TaskName "Code Refactoring Task" -TaskType "Discrete" -Category "06-maintenance" -Description "Systematically improve code quality and maintainability without changing external behavior"
   ```

   **Script Output Example**:

   ```
   Created task with ID: PF-TSK-18 at C:\...\06-maintenance\code-refactoring-task.md
   Updated documentation map with new task
   Updated tasks README with new task
   Edit the file to complete the task documentation
   ```

3. **Complete the Task Content**: The script automatically creates the file with correct metadata. Now fill in all required sections following the unified structure:

   ```markdown
   # Code Refactoring Task

   ## Purpose & Context

   Systematically improve code quality and maintainability without changing external behavior. This task ensures technical debt is addressed proactively and codebase health is maintained.

   ## When to Use

   - When technical debt has accumulated in a specific area
   - After completing several features in the same module
   - Before adding significant new functionality to existing code
   - When performance issues have been identified

   ## Context Requirements

   - **Critical (Must Read):**

     - [Development Guide](/doc/product-docs/guides/guides/development-guide.md) - Coding standards to follow
     - <!-- [Code Quality Reports](/doc/product-docs/development/reports/code-quality-reports.md) - File not found --> - Metrics indicating problem areas

   - **Reference Only (Access When Needed):**
     - [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) - Items marked for refactoring

   ## Process

   > **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
   >
   > **⚠️ MANDATORY: Use code analysis tools to guide refactoring priorities.**

   ### Preparation

   1. Review the Technical Debt Tracking document to identify refactoring priorities
   2. Run code analysis tools to identify code smells, complexity issues, and potential bugs
   3. Create a refactoring plan listing specific changes with their rationale

   ### Execution

   4. Make incremental changes, testing after each significant modification
   5. Apply consistent patterns and naming conventions across the refactored code
   6. Update any affected documentation or comments
   7. Ensure test coverage is maintained or improved

   ### Finalization

   8. Run the full test suite to verify no regressions were introduced
   9. Document any architectural or pattern changes made
   10. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below
   ```

   **Example Task Completion Checklist**:

   ```markdown
   ## ⚠️ MANDATORY Task Completion Checklist

   **🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

   Before considering this task finished:

   - [ ] **Verify Outputs**: Confirm all required outputs have been produced
     - [ ] Refactored code passes all tests
     - [ ] Code quality metrics show improvement
     - [ ] No new warnings or errors introduced
   - [ ] **Update State Files**: Ensure all state tracking files have been updated
     - [ ] Technical Debt Tracking document updated with completed items
     - [ ] Feature Tracking updated if the refactoring affects specific features
   - [ ] **Complete Feedback Forms**: Create feedback forms for each tool used
   ```

4. **Verify Automatic Updates**: The script automatically handles:

   - ✅ **Tasks README**: New task added to the appropriate table
   - ✅ **ID Tracking**: Next available ID assigned and ../../../tasks/config.json updated
   - ⚠️ **Documentation Map**: New task added to the `### Discrete Tasks` table section
     - **Note**: The documentation map has multiple task sections; the script updates the table format section

   **Mostly automated** - only minor manual cleanup may be needed for documentation map consistency.

## Conclusion

Creating and maintaining high-quality task documentation is essential for the success of the task-based development approach. By following this guide, you can ensure that all tasks are consistent, comprehensive, and effective in guiding development work.

Remember that the task structure should evolve with the project. Regularly review and improve task definitions based on feedback and changing project needs.

---

_This guide is part of the Process Framework and provides instructions for creating and improving task documentation._
