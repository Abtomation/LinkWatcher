---
id: PF-VIS-001
type: Documentation
version: 1.0
created: 2025-06-03
updated: 2025-06-05
---

# Feedback Process Flowchart

## Overview

This flowchart illustrates the complete feedback process for tools, templates, and guides used during tasks in the project.

## Process Flow

```mermaid
flowchart TD
    A[Task Completion] --> B{Used any tools/templates/guides?}
    B -->|No| Z[Task Complete]
    B -->|Yes| C[Navigate to feedback directory]

    C --> D[cd process-framework/scripts/file-creation/support]
    D --> E[Run automation script]
    E --> F[./New-FeedbackForm.ps1 -DocumentId PREFIX-XXX-XXX -TaskContext Task Name -FeedbackType MultipleTools]

    F --> G[Script automatically:]
    G --> H[• Assigns ART-FEE-XXX ID]
    G --> I[• Creates ../../process-framework-local/feedback/YYYYMMDD-HHMMSS-document-id-feedback.md]
    G --> J[• Places file in feedback-forms/ subdirectory]
    G --> K[• Updates ID tracker]
    G --> L[• Pre-fills template with metadata]

    L --> M[Complete the feedback form:]
    M --> N[• Rate effectiveness 1-5]
    M --> O[• Rate clarity 1-5]
    M --> P[• Rate completeness 1-5]
    M --> Q[• Rate efficiency 1-5]
    M --> R[• Provide detailed comments]
    M --> S[• Suggest improvements]
    M --> T[• Document task context]

    T --> T1[AI Assistant asks for human feedback]
    T1 --> T2[Human provides feedback on task/process]
    T2 --> T3[AI Assistant adds feedback to form]

    T3 --> U{More tools to evaluate?}
    U -->|Yes| E
    U -->|No| V[All feedback forms completed]

    V --> W[Feedback forms stored in:]
    W --> X[process-framework-local/feedback/feedback-forms/]
    X --> Y[Feedback reviewed in Tools Review Task]
    Y --> Z[Task Complete]

    style A fill:#e1f5fe
    style Z fill:#c8e6c9
    style F fill:#fff3e0
    style M fill:#f3e5f5
    style Y fill:#e8f5e8
```

## Key Points

### Automation Benefits
- **Consistent naming**: Automatic timestamp and document ID formatting
- **Unique IDs**: Prevents ID conflicts with automatic assignment
- **Correct placement**: Files automatically go to the right directory
- **Template pre-filling**: Reduces manual setup time

### File Structure
```
/process-framework-local/feedback
├── README.mdss documentation
├── feedback-process-flowchart.md      # This flowchart
├── scripts/file-creation/support/New-FeedbackForm.ps1
├── config.json                     # ID tracking
└── feedback-forms/                    # All feedback files
    ├── ../../process-framework-local/feedback/20250127-210602-PF-TSK-002-feedback.md
    ├── ../../process-framework-local/feedback/20250527-224101-PF-TEM-001-feedback.md
    └── [../../process-framework-local/feedback/YYYYMMDD-HHMMSS-document-id-feedback.md]
```

### Naming Convention Details

#### File Name Format
```
../../process-framework-local/feedback/YYYYMMDD-HHMMSS-document-id-feedback.md
```

#### Metadata ID Format
```yaml
---
id: PF-FEE-XXX  # Automatically assigned
type: Artifact
---
```

## Integration Points

### Task Definitions
All task definitions include a "Task Completion" section that references this feedback process.

### Tools Review Process
Feedback forms are aggregated and analyzed during the [Tools Review Task](../../tasks/support/tools-review-task.md) for continuous improvement.

### Documentation Map
Individual feedback forms are not tracked in the documentation map - only the README and this flowchart are included.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Script not found | Ensure you're in `/process-framework/scripts/file-creation/support` directory |
| Permission denied | Run PowerShell as administrator or check execution policy |
| ID tracker error | Verify `../../process-framework-local/feedback/../../process-framework-local/feedback/directory.json` exists and is properly formatted |
| Template not found | Ensure `process-framework/templates/support/feedback-form-template.md` exists |

## Best Practices

1. **Complete feedback immediately** after task completion while details are fresh
2. **Be specific** in comments and suggestions
3. **Rate honestly** - both strengths and weaknesses help improve tools
4. **Include context** about how the tool was used in your specific task
5. **Suggest actionable improvements** rather than just identifying problems
6. **Provide human feedback** when prompted by the AI assistant to capture user perspective
7. **Be honest about process efficiency** and time tracking accuracy

## Related Documents

- [Feedback Process Guide](../../../process-framework-local/feedback/archive/README.md) - Detailed documentation
- [Feedback Form Template](../../templates/support/feedback-form-template.md) - Template structure
- [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) - Comprehensive completion instructions
- [Tools Review Task](../../tasks/support/tools-review-task.md) - How feedback is used
- [Task Template](../../templates/support/task-template.md) - Standard task completion process
