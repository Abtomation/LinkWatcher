---
id: PF-GDE-042
type: Process Framework
category: Guide
version: 1.0
created: 2025-01-15
updated: 2025-01-15
---

# Bug Reporting Guide

## Purpose

This guide provides standardized procedures for reporting bugs discovered during task execution, ensuring consistent bug documentation and proper integration with the Bug Triage workflow.

## When to Use This Guide

- When discovering bugs during **Test Audit** tasks
- When finding issues during **Code Review** tasks
- When encountering problems during **Feature Implementation** tasks
- When identifying defects during **Manual Testing**
- When monitoring systems reveal issues
- When users report problems

## Bug Reporting Script

Use the `New-BugReport.ps1` script located in `/doc/process-framework/scripts/file-creation/` to create standardized bug reports.

### Basic Usage

```powershell
# Navigate to the scripts directory
cd doc/process-framework/scripts/file-creation

# Create a basic bug report
./New-BugReport.ps1 -Title "Brief bug description" -Description "Detailed explanation" -DiscoveredBy "Task Name"
```

### Complete Usage Example

```powershell
./New-BugReport.ps1 `
  -Title "Login form validation fails for email format" `
  -Description "The email validation accepts clearly invalid email formats like 'test@' or 'invalid.email'" `
  -DiscoveredBy "Test Audit" `
  -Severity "High" `
  -Component "Authentication" `
  -ReproductionSteps "1. Navigate to login page`n2. Enter 'test@' in email field`n3. Click submit`n4. Form accepts invalid email" `
  -ExpectedBehavior "Form should reject invalid email formats with clear error message" `
  -ActualBehavior "Form accepts invalid email and attempts login" `
  -Environment "Development" `
  -RelatedFeature "User Authentication System"
```

## Required Parameters

| Parameter        | Description                        | Example                                                      |
| ---------------- | ---------------------------------- | ------------------------------------------------------------ |
| **Title**        | Brief, descriptive bug title       | "Memory leak in user service"                                |
| **Description**  | Detailed explanation of the issue  | "Memory usage increases continuously during user operations" |
| **DiscoveredBy** | Task or process that found the bug | "Code Review", "Test Audit", "Feature Implementation"        |

## Optional Parameters

| Parameter             | Description                  | Default       | Example                                   |
| --------------------- | ---------------------------- | ------------- | ----------------------------------------- |
| **Severity**          | Technical impact level       | "Medium"      | "Critical", "High", "Medium", "Low"       |
| **Component**         | Affected system component    | ""            | "Authentication", "UI", "Database", "API" |
| **ReproductionSteps** | How to reproduce the bug     | ""            | Step-by-step instructions                 |
| **ExpectedBehavior**  | What should happen           | ""            | Expected system behavior                  |
| **ActualBehavior**    | What actually happens        | ""            | Actual system behavior                    |
| **Environment**       | Where bug was found          | "Development" | "Testing", "Staging", "Production"        |
| **Evidence**          | Links to proof/documentation | ""            | Screenshot URLs, log file paths           |
| **RelatedFeature**    | Associated feature           | ""            | Feature name or ID                        |

## Bug Reporting Standards

### Title Guidelines

- **Be specific**: "Login validation fails" not "Login broken"
- **Include component**: "User service memory leak" not "Memory issue"
- **Avoid jargon**: Use clear, understandable language
- **Keep concise**: Maximum 80 characters

### Description Guidelines

- **Explain the problem**: What exactly is wrong?
- **Provide context**: When does it happen?
- **Include impact**: How does it affect users/system?
- **Be objective**: Stick to facts, avoid opinions

### Reproduction Steps Format

```
1. Navigate to [specific page/component]
2. Perform [specific action]
3. Enter [specific data]
4. Click/Submit [specific element]
5. Observe [specific result]
```

### Severity Guidelines

| Severity     | When to Use                                   | Examples                                                 |
| ------------ | --------------------------------------------- | -------------------------------------------------------- |
| **Critical** | System crash, data loss, security breach      | Database corruption, authentication bypass               |
| **High**     | Major feature broken, significant user impact | Payment processing fails, core functionality unavailable |
| **Medium**   | Minor feature issue, workaround available     | UI glitch, non-critical validation error                 |
| **Low**      | Cosmetic issue, minimal impact                | Text alignment, color inconsistency                      |

## Integration with Bug Triage

After creating a bug report:

1. **Automatic Status**: Bug gets status "🆕 Reported"
2. **Triage Required**: Bug needs evaluation via Bug Triage task
3. **Priority Assignment**: Triage will assign business priority
4. **Assignment**: Triage will recommend developer/team
5. **Resolution**: Bug moves to Bug Fixing task

## Task-Specific Reporting

### During Test Audit

```powershell
./New-BugReport.ps1 `
  -Title "Test case TC-001 fails consistently" `
  -Description "Authentication test fails due to session timeout handling" `
  -DiscoveredBy "Test Audit" `
  -Component "Authentication" `
  -Evidence "Test execution log: /logs/test-audit-2025-01-15.log"
```

### During Code Review

```powershell
./New-BugReport.ps1 `
  -Title "Null pointer exception in user validation" `
  -Description "Method getUserProfile() doesn't handle null user ID parameter" `
  -DiscoveredBy "Code Review" `
  -Severity "High" `
  -Component "User Management" `
  -Evidence "Code location: src/services/UserService.java:142"
```

### During Feature Implementation

```powershell
./New-BugReport.ps1 `
  -Title "Database migration fails on existing data" `
  -Description "New column addition breaks when existing records have null values" `
  -DiscoveredBy "Feature Implementation" `
  -Severity "Critical" `
  -Component "Database" `
  -RelatedFeature "User Profile Enhancement"
```

## Best Practices

### Do's

- ✅ **Report immediately**: Don't wait or accumulate bugs
- ✅ **Be thorough**: Include all relevant information
- ✅ **Test reproduction**: Verify steps work before reporting
- ✅ **Include evidence**: Screenshots, logs, error messages
- ✅ **Reference context**: Link to related features/tasks

### Don'ts

- ❌ **Don't assume priority**: Let triage determine business priority
- ❌ **Don't assign yourself**: Let triage recommend assignment
- ❌ **Don't duplicate**: Check existing bugs first
- ❌ **Don't be vague**: Provide specific, actionable information
- ❌ **Don't skip triage**: All bugs need proper evaluation

## Script Output

The script provides clear feedback:

```
🐛 Creating bug report: BUG-042
📝 Title: Login form validation fails
✅ Bug report created successfully!
📍 Bug ID: BUG-042
📂 Added to: /doc/process-framework/state-tracking/permanent/bug-tracking.md

🔄 Next Steps:
  1. Run Bug Triage task to evaluate and prioritize this bug
  2. Bug will be assigned priority and severity during triage
  3. After triage, bug can be assigned for fixing

💡 Tip: Use 'Bug Triage' task to process all reported bugs
```

## Troubleshooting

### Common Issues

**Script not found**

```
Solution: Ensure you're in the correct directory
cd doc/process-framework/state-tracking
```

**Permission denied**

```
Solution: Check file permissions or run as administrator
```

**Bug tracking file not found**

```
Solution: Verify bug-tracking.md exists in permanent/ subdirectory
```

**Invalid severity value**

```
Solution: Use only: Critical, High, Medium, Low
```

## Related Resources

- [Bug Tracking State File](../state-tracking/permanent/bug-tracking.md) - Central bug registry
- [Bug Triage Task](../../tasks/06-maintenance/bug-triage-task.md) - Bug evaluation and prioritization
- [Bug Fixing Task](../../tasks/06-maintenance/bug-fixing-task.md) - Bug resolution workflow
- [Test Audit Task](../../tasks/03-testing/test-audit-task.md) - Testing workflow with bug discovery
- [Code Review Task](../../tasks/06-maintenance/code-review-task.md) - Review workflow with bug discovery
