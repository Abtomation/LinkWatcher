---
id: PF-TEM-013
type: Process Framework
category: Template
version: 1.0
created: 2025-07-04
updated: 2025-07-04
---

# Task Completion Template

This template provides a standardized completion checklist for all task definitions to ensure consistent task completion practices.

## ⚠️ MANDATORY Task Completion Checklist
**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Ensure all required outputs have been produced
- [ ] **Update State Files**: Confirm all relevant state tracking documents have been updated
- [ ] **Complete Feedback Forms**: Fill out a feedback form (artifact) for each tool/template/guide used during this task:
   ```bash
   # Windows command pattern (use this for reliable execution):
   echo Set-Location 'c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\process-framework\scripts\file-creation'; ^& .\New-FeedbackForm.ps1 -DocumentId '[TASK-ID]' -TaskContext '[Task Name]' -FeedbackType 'Multiple Tools' -Confirm:$false > temp_feedback.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp_feedback.ps1 && del temp_feedback.ps1
   ```

   > **Note**: Update the path to match your actual project location

   **Script automatically**:
   - Names file using format: `YYYYMMDD-HHMMSS-document-id-feedback.md`
   - Places file in `/doc/process-framework/feedback/feedback-forms/`
   - Assigns unique artifact IDs (`ART-FEE-XXX`) in metadata

   For more details, see the [Feedback Process Guide](../../feedback/README.md).

## Usage Instructions

1. Copy this template into task definitions
2. Replace `[TASK-ID]` with the actual task document ID (e.g., PF-TSK-002)
3. Replace `[Task Name]` with the actual task name (e.g., "Feature Tier Assessment")
4. Customize the "Verify Outputs" and "Update State Files" items to be specific to the task
5. Add the reference to this checklist in the Process section with:
   ```markdown
   3. **⚠️ BEFORE CONSIDERING TASK COMPLETE**: Complete the [Task Completion Checklist](#task-completion) below
   ```

## Benefits

- **Consistency**: All tasks follow the same completion pattern
- **Visibility**: Prominent warnings ensure completion steps aren't missed
- **Accountability**: Checkbox format provides clear tracking
- **Quality**: Ensures feedback loop is maintained for continuous improvement
