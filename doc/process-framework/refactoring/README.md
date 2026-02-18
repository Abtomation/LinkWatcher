# Refactoring Infrastructure Directory

This directory contains the infrastructure and documentation for the Code Refactoring Task (PF-TSK-022).

## Directory Structure

### 📝 **Active Directories**

| Directory        | Purpose                                      | Content Type                                      | Created By                     |
| ---------------- | -------------------------------------------- | ------------------------------------------------- | ------------------------------ |
| **`plans/`**     | Refactoring plan documents                   | PF-REF-XXX documents                              | ../scripts/file-creation/New-RefactoringPlan.ps1n/New-RefactoringPlan.ps1n/New-RefactoringPlan.ps1 script |
| **`summaries/`** | Completed refactoring summaries and reports  | PF-REF-XXX, PF-REF-SUM-XXX, PF-COMP-XXX documents | Manual creation                |
| **`analysis/`**  | Code analysis and assessment documents       | Analysis reports                                  | Manual creation                |
| **`status/`**    | Status tracking and phase completion reports | Status reports                                    | Manual creation                |

### 🔧 **Scripts**

| File                          | Purpose                                | Usage                                                                               |
| ----------------------------- | -------------------------------------- | ----------------------------------------------------------------------------------- |
| **`New-RefactoringPlan.ps1`** | Creates new refactoring plan documents | `.\New-RefactoringPlan.ps1 -RefactoringScope "Description" -TargetArea "Component"` |

### 📋 **Archive Directories**

| Directory         | Purpose                    | Status               |
| ----------------- | -------------------------- | -------------------- |
| **`plans/old/`**  | Archived refactoring plans | Historical reference |
| **`status/old/`** | Archived status reports    | Historical reference |

## Usage Workflow

### 1. **Creating a New Refactoring Plan**

```powershell
cd doc/process-framework/refactoring
..\scripts\file-creation\New-RefactoringPlan.ps1New-RefactoringPlan.ps1New-RefactoringPlan.ps1 -RefactoringScope "User Authentication Module" -TargetArea "lib/services/auth/"
```

### 2. **Customizing the Plan**

- Follow the [Refactoring Plan Template Customization Guide](../guides/guides/code-refactoring-task-usage-guide.md)
- Use the [Context Map](../visualization/context-maps/06-maintenance/code-refactoring-task-map.md) for component relationships

### 3. **Completing the Refactoring**

- Implement the refactoring according to the plan
- Create a summary document in `summaries/` directory
- Update state tracking files as specified in the task definition

## Document Types

### **Refactoring Plans (PF-REF-XXX)**

- **Location**: `plans/`
- **Purpose**: Detailed refactoring planning and strategy documents
- **Created By**: ../scripts/file-creation/New-RefactoringPlan.ps1n/New-RefactoringPlan.ps1n/New-RefactoringPlan.ps1 script
- **Template**: [refactoring-plan-template.md](../templates/templates/refactoring-plan-template.md)

### **Refactoring Summaries (PF-REF-XXX, PF-REF-SUM-XXX)**

- **Location**: `summaries/`
- **Purpose**: Post-completion summaries of refactoring work
- **Created By**: Manual creation
- **Content**: Implementation details, improvements achieved, files modified

### **Completion Reports (PF-COMP-XXX)**

- **Location**: `summaries/`
- **Purpose**: Formal completion reports for feature refactoring
- **Created By**: Manual creation
- **Content**: Executive summaries, metrics, test results

### **Analysis Documents**

- **Location**: `analysis/`
- **Purpose**: Code analysis and assessment reports
- **Created By**: Manual creation
- **Content**: Function analysis, architectural assessments

## Integration with Process Framework

This directory integrates with:

- **[Code Refactoring Task](../tasks/06-maintenance/code-refactoring-task.md)** - Main task definition
- **[Context Map](../visualization/context-maps/06-maintenance/code-refactoring-task-map.md)** - Component relationships
- **[Template Customization Guide](../guides/guides/code-refactoring-task-usage-guide.md)** - Detailed usage instructions
- **[Technical Debt Tracking](../state-tracking/permanent/technical-debt-tracking.md)** - State tracking integration
- **[Feature Tracking](../state-tracking/permanent/feature-tracking.md)** - Feature status updates

## Directory Cleanup History

**2025-01-27**: Consolidated multiple summary directories:

- Merged `summary/` → `summaries/`
- Merged `implementation-summary/` → `summaries/`
- Maintained single `summaries/` directory for all completion documentation
- Aligned structure with script expectations and process framework standards

---

_This directory structure supports the systematic approach to code refactoring as defined in the Process Framework._
