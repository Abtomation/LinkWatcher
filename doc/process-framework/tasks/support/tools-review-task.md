---
id: PF-TSK-010
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.3
created: 2023-06-15
updated: 2025-08-07
task_type: support
---

# Tools Review Task

## Purpose & Context

Systematically evaluate and enhance the templates, guides, and other tools by collecting, analyzing, and implementing feedback, ensuring continuous improvement of documentation and processes.

## AI Agent Role

**Role**: DevOps Engineer
**Mindset**: Tool optimization-focused, efficiency-driven, continuous improvement-oriented
**Focus Areas**: Tool effectiveness, automation opportunities, user experience, process optimization
**Communication Style**: Focus on tool usability and efficiency gains, ask about pain points and improvement priorities

## When to Use

- After completing 5 development tasks
- Monthly, if fewer than 5 tasks have been completed
- Quarterly for comprehensive reviews
- When multiple feedback items suggest a common improvement opportunity
- When new tools or templates have been recently introduced

## Context Requirements

- [Tools Review Context Map](/doc/process-framework/visualization/context-maps/support/tools-review-map.md) - Visual guide to the components relevant to this task

- **Critical (Must Read):**

  - [Feedback Forms](../../feedback) - Collected feedback on tools used in previous tasks
  - [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - Current improvement initiatives
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - <!-- [Task Templates](../../templates) - Template/example link commented out --> - Templates used in tasks

- **Reference Only (Access When Needed):**
  - [Documentation Map](../../documentation-map.md) - Overview of all project documentation

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Always group feedback forms by task type for consistent analysis.**
>
> **⏱️ Time Tracking**: Record your start time now for accurate feedback completion.

### Preparation

1. Review [feedback forms](../../feedback/feedback-forms/) collected at the end of each task
2. **Group feedback forms by task type** (e.g., all PF-TSK-002 forms together)
   - **🚨 BATCH SIZE LIMIT**: Evaluate a maximum of **20 feedback forms per session** to prevent context window exhaustion before analysis is complete
   - All forms belonging to the same task type **must** be included in the same session — never split a task group across sessions
   - If total forms exceed 20, split into multiple sessions by task group boundaries (complete task groups only)
3. Create a structured analysis framework for each task group
4. Prepare a tracking sheet for identified improvements

### Execution

5. Identify common themes and patterns across feedback **within each task group**
6. Evaluate each task type separately to ensure consistent analysis
7. Quantify ratings for effectiveness, clarity, completeness, and efficiency
8. Prioritize potential improvements based on frequency and impact
9. Document improvement opportunities in the [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) file
   - **🔗 TRACEABILITY REQUIREMENT**: Include link to the tools review analysis file in the improvement opportunity notes for full traceability
10. **🚨 SCOPE BOUNDARY**: Tools Review identifies and documents improvements only. For implementation, create [Process Improvement Task](process-improvement-task.md) entries
11. Archive processed feedback forms for future reference

### Finalization

12. Verify all improvement opportunities are properly documented
13. Ensure [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) file is updated
14. Communicate identified improvements to project stakeholders
15. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Improvement Opportunities** - Documented improvement opportunities in [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md)
- **Review Summary** - Documentation of findings and identified improvements
- **Process Improvement Tasks** - Created [Process Improvement Task](process-improvement-task.md) entries for implementation
- **Archive of Processed Forms** - Organized archive of processed feedback forms

## State Tracking

The following state files must be updated as part of this task:

- [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - Update with:
  - New improvement opportunities identified from feedback analysis
  - **🔗 MANDATORY**: Links to the tools review analysis file for full traceability
  - Prioritization of pending improvements
  - Links to created [Process Improvement Task](process-improvement-task.md) entries

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Improvement opportunities documented in [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md)
  - [ ] Review summary documenting findings and identified improvements
  - [ ] [Process Improvement Task](process-improvement-task.md) entries created for implementation
  - [ ] Archive of processed feedback forms
- [ ] **Verify Feedback Grouping**: Ensure that only feedback forms for the same task type were analyzed together
- [ ] **Update State Files**: Confirm all state tracking files have been updated
  - [ ] [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) reflects identified improvement opportunities
  - [ ] [Process Improvement Task](process-improvement-task.md) entries created for implementation
- [ ] **Solicit User Feedback**: **MANDATORY** - Actively ask the human user for their feedback on the session:
  - [ ] Ask specific questions about process effectiveness
  - [ ] Request feedback on any issues or challenges observed
  - [ ] Solicit suggestions for improvement
  - [ ] Gather overall satisfaction assessment
  - [ ] **Do not proceed** until user feedback has been collected and documented
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-010" and context "Tools Review"
- [ ] **Archive Processed Forms**: Move analyzed feedback forms to archive:
  - [ ] Create archive folder: `/doc/process-framework/feedback/archive/YYYY-MM/tools-review-YYYYMMDD/`
  - [ ] Create subfolder: `processed-forms/` within the archive folder
  - [ ] **⚠️ CRITICAL DISTINCTION**: Only move feedback forms that were **analyzed during this session**
    - ✅ **Archive These**: Feedback forms that you reviewed, analyzed, and extracted improvements from
    - ❌ **DO NOT Archive**: Newly created feedback forms (including the PF-TSK-010 form created for this session)
    - ❌ **DO NOT Archive**: Feedback forms that haven't been analyzed yet
  - [ ] Move only the analyzed feedback forms to the `processed-forms/` subfolder
  - [ ] **Keep Active**: Leave newly created feedback forms in the active feedback-forms folder for future analysis
  - [ ] Document which specific forms were archived vs. kept active in the review summary
- [ ] **Schedule Next Review**: Set a reminder for the next tools review cycle

## Next Tasks

- [**Process Improvement**](process-improvement-task.md) - For implementing larger process changes

## Related Resources

- [Feedback Process Guide](../../feedback/README.md) - Guide for collecting and processing feedback
- <!-- [Tool Rating Guide](../../guides/tool-rating-guide.md) - File not found --> - Standards for evaluating tools
- [Task Creation and Improvement Guide](../task-creation-guide.md) - Guide for creating and improving tasks

## Critical Process Note

**USER FEEDBACK IS MANDATORY**: The AI assistant must actively solicit and collect human user feedback before completing any feedback form. This is not optional - the process cannot be considered complete without genuine user input on the session's effectiveness, challenges, and improvement suggestions.
