---
id: PF-FEE-000
type: Documentation
version: 1.0
created: 2023-06-15
updated: 2023-06-15
---

# Tool Feedback

This directory contains feedback forms (artifacts) for templates, guides, and other tools (documents) used in the BreakoutBuddies project. These feedback artifacts are collected at the end of each task and are used to continuously improve our development tools.

> **Quick Reference**: See the [Feedback Process Flowchart](../../process-framework/feedback/feedback-process-flowchart.md) for a visual overview of the complete process.

## Purpose

The feedback collected in this directory serves several purposes:
1. Identify strengths and weaknesses in existing tools
2. Gather suggestions for tool improvements
3. Track tool effectiveness over time
4. Inform the tools review process

## Feedback Form Structure

We use a **hybrid feedback approach** with the enhanced [Feedback Form Template](../templates/templates/feedback-form-template.md) that supports:

### Flexible Evaluation Modes
- **Single Tool**: Detailed evaluation of one specific tool
- **Multiple Tools**: Quick assessment of all tools used in a task
- **Task-Level**: Overall process effectiveness evaluation

### Comprehensive Assessment Criteria
- **Effectiveness**: How well the tool/process supported task completion
- **Clarity**: How clear and understandable the tool was
- **Completeness**: Whether all necessary information was provided
- **Efficiency**: How well the tool helped complete tasks efficiently
- **Conciseness**: Critical assessment of overdocumentation and information relevance

### Key Innovation: Conciseness Evaluation
All feedback forms now include **conciseness assessment** to combat overdocumentation:
- 5: Perfect balance - only essential information
- 4: Mostly concise with minimal unnecessary content
- 3: Adequate but some non-essential information
- 2: Contains significant unnecessary/redundant content
- 1: Heavily overdocumented with excessive irrelevant information

### Human User Feedback Integration
The template includes a dedicated section for human user feedback:
- AI assistant prompts the user for feedback on task completion and process
- User provides feedback on satisfaction, efficiency, and value
- AI assistant records the feedback in the form
- Captures user perspective alongside technical assessment

### Follow-up Action Identification
The template includes sections to identify:
- Tools scoring ≤3 that need detailed follow-up feedback
- Process improvements to consider
- Documentation streamlining opportunities

## Naming Convention

Feedback forms follow this naming convention:

### File Name
```
../../process-framework/feedback/YYYYMMDD-HHMMSS-document-id-feedback.md
```

For example:
```
../../process-framework/feedback/20250527-224101-PF-TEM-001-feedback.md
```

Where:
- `20250527` is the date (May 27, 2025)
- `224101` is the time (22:41:01)
- `PF-TEM-001` is the ID of the document being evaluated

### File Location
All feedback forms are stored in:
```
/doc/process-framework/feedback/feedback-forms/
```

### Metadata ID
Each feedback form has a unique artifact ID in its metadata:
```yaml
---
id: PF-FEE-XXX  # Automatically assigned by the script
type: Artifact
---
```

**Important**: Individual feedback forms are not tracked in the documentation map. Only this README file is included in the documentation map.

## Review Process

Feedback forms are reviewed as part of the [Tools Review Task](../tasks/support/tools-review-task.md). This task aggregates feedback, identifies patterns, and prioritizes improvements to our development tools.

## Contributing Feedback

At the end of each task, complete a feedback form for each template, guide, checklist, or other tool used during the task:

1. **Create a Feedback Form** (Recommended Method):

   Use the provided PowerShell script to automatically create a feedback form:

   > **⚠️ Important**: Use PowerShell Core (`pwsh`) rather than Windows PowerShell for better compatibility.

   ```powershell
   # Windows command pattern (use this for reliable execution):
   echo Set-Location 'c:\Users\ronny\VS_Code\LinkWatcher\doc\process-framework\scripts\file-creation'; ^& .\New-FeedbackForm.ps1 -DocumentId 'PF-TSK-044' -TaskContext 'Feature Implementation Planning' -FeedbackType 'MultipleTools' -Confirm:$false > temp_feedback.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp_feedback.ps1 && del temp_feedback.ps1
   ```

   > **Note**: Update the path to match your actual project location

   The script automatically:
   - Assigns the next available artifact ID (`ART-FEE-XXX`)
   - Creates the file with proper naming convention
   - Places the file in `/feedback-forms/` subdirectory
   - Updates the ID tracker
   - Pre-fills the template with correct metadata

2. **Complete the Form**:
   - Rate the tool on effectiveness, clarity, completeness, and efficiency (1-5 scale)
   - Provide detailed comments for each rating
   - Document what worked well and what could be improved
   - Suggest specific, actionable enhancements
   - Include context about how the tool was used in the task
   - Provide human feedback when prompted by the AI assistant

3. **File Location**:
   - All feedback forms are automatically saved in `/doc/process-framework/feedback/feedback-forms/`
   - Files follow the naming convention: `../../process-framework/feedback/YYYYMMDD-HHMMSS-document-id-feedback.md`

The feedback should be specific, actionable, and focused on how the tool could be improved to better support the development process.

## Best Practices for Providing Feedback

1. **Be specific**: Provide detailed examples of issues or strengths
2. **Be constructive**: Focus on how tools can be improved
3. **Be comprehensive**: Evaluate all aspects of the tool
4. **Be balanced**: Note both strengths and weaknesses
5. **Be actionable**: Suggest specific improvements
6. **Be contextual**: Explain how the tool was used in the task
7. **Engage with human feedback**: Provide honest feedback when prompted by the AI assistant
8. **Focus on process efficiency**: Highlight areas where development speed can be improved
