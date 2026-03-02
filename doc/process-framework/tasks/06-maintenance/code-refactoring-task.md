---
id: PF-TSK-022
type: Process Framework
category: Task Definition
version: 1.2
created: 2025-07-21
updated: 2026-03-02
task_type: Discrete
---

# Code Refactoring Task

## Purpose & Context

Systematic code improvement and technical debt reduction without changing external behavior

## AI Agent Role

**Role**: Senior Software Engineer
**Mindset**: Pragmatic, quality-focused, delivery-oriented
**Focus Areas**: Code quality, maintainability, performance, technical debt reduction
**Communication Style**: Present trade-offs between speed and quality, discuss refactoring benefits and risks

## When to Use

- When code quality metrics decline or technical debt accumulates
- Before implementing new features in areas with known technical debt
- When code complexity makes maintenance difficult or error-prone
- After identifying code smells during code reviews
- When refactoring is recommended by Technical Debt Assessment Task
- Before major feature releases to improve code maintainability

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/06-maintenance/code-refactoring-task-map.md)

- **Critical (Must Read):**

  - **Target Code Area** - Specific files, modules, or components to be refactored
  - **Current Code Quality Issues** - Identified problems, code smells, or technical debt items
  - **Existing Test Coverage** - Current test suite for the code area to ensure behavior preservation

- **Important (Load If Space):**

  - **Technical Debt Assessment** - Results from Technical Debt Assessment Task if available
  - **Code Quality Metrics** - Current complexity, maintainability, and quality measurements
  - **System Architecture Documentation** - Understanding of how refactored code fits into overall system
  - **Recent Code Changes** - Git history and recent modifications to understand change patterns

- **Reference Only (Access When Needed):**
  - **Coding Standards** - Project-specific coding conventions and style guides
  - **Performance Benchmarks** - Current performance metrics to ensure refactoring doesn't degrade performance
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the appropriate automation tools where indicated.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Step 1: Effort Assessment Gate

Evaluate the refactoring scope against these criteria:

| Criteria | Lightweight | Standard |
|----------|-------------|----------|
| Estimated code effort | ≤ 15 minutes | > 15 minutes |
| Files affected | Single file | Multiple files |
| Architectural impact | None | Any |
| Interface/API changes | None | Any |

**Lightweight** — ALL criteria in the Lightweight column must apply.
**Standard** — ANY criteria in the Standard column triggers the standard path.

> **🚨 CHECKPOINT**: Present effort classification (Lightweight or Standard) to human partner for approval.
>
> - **If Lightweight**: Follow the [Lightweight Path](#lightweight-path) below.
> - **If Standard**: Skip to the [Standard Path](#standard-path) below.

---

### Lightweight Path

For low-effort refactorings (≤ 15 min, single file, no architectural impact). Supports batch mode — multiple quick fixes in one session using one plan document.

**L1. Create Lightweight Refactoring Plan**:

```powershell
cd doc/process-framework/scripts/file-creation
.\New-RefactoringPlan.ps1 -RefactoringScope "Brief description" -TargetArea "Component/Module name" -Lightweight
```

For batch mode: copy the "Item N" section in the generated plan for each additional debt item.

**L2. Fill Item Scope**: For each item in the plan, fill in the Scope, Debt Item ID, and Test Baseline fields.

**L3. 🚨 CHECKPOINT**: Present the plan (scope + changes) to human partner for approval before implementing.

**L4. Implement Changes**: Apply refactoring. Run tests after each change to verify behavior preservation.

**L5. Complete Documentation & State Updates Checklist**: For each item in the plan, check every item in the "Documentation & State Updates" section:
   - Feature implementation state file updated (or N/A)
   - TDD updated (or N/A — no interface/design change)
   - Test spec updated (or N/A — no behavior change)
   - FDD updated (or N/A — no functional change)
   - Technical Debt Tracking: TD item marked resolved

**L6. Fill Results**: Record test results, bugs discovered, and doc updates in the plan. Complete the Results Summary table.

**L7. Update State Files**:
   - [ ] [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md): Mark resolved items using `Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "Resolved" -ResolutionNotes "..."`
   - [ ] [Feature Tracking](../../state-tracking/permanent/feature-tracking.md): Update feature status if applicable
   - [ ] [Bug Tracking](../../state-tracking/permanent/bug-tracking.md): Report any discovered bugs using New-BugReport.ps1

**L8. 🚨 CHECKPOINT**: Present results summary to human partner for review.

**L9. 🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below (use the Lightweight checklist variant).

---

### Standard Path

For medium/complex refactorings (> 15 min, multiple files, or architectural impact).

#### Standard — Preparation

1. **Create Refactoring Plan**: Use automation script to create structured refactoring plan document

   ```powershell
   cd doc/process-framework/scripts/file-creation
   .\New-RefactoringPlan.ps1 -RefactoringScope "Brief description" -TargetArea "Component/Module name"
   ```

2. **Create Temporary State Tracking** (conditional):

   - **< 5 items and ≤ 2 sessions expected**: Skip temp state file. Use the refactoring plan's "Implementation Tracking" section for all progress tracking.
   - **≥ 5 items or multi-session (3+)**: Create a separate temp state file:

   ```powershell
   # Navigate to state tracking directory
   Set-Location "doc/process-framework/state-tracking"

   # Create temporary tracking file for refactoring work
   ../../scripts/file-creation/New-TempTaskState.ps1 -TaskName "[Refactoring Scope] Refactoring" -TaskType "Discrete" -Description "Refactoring work for [specific component/feature]"
   ```

   - Document refactoring progress and blockers in the chosen tracking surface
   - Update status regularly during implementation

3. **Analyze Current State**: Document current code quality issues, complexity metrics, and technical debt items
4. **Verify Test Coverage**: Ensure comprehensive test coverage exists for the target code area
5. **Create Baseline Measurements**: Record current performance metrics and code quality indicators
6. **🚨 CHECKPOINT**: Present analysis findings, baseline metrics, and test coverage status to human partner

#### Standard — Execution

7. **Define Refactoring Strategy**: Document specific refactoring techniques and approach in the plan
8. **🚨 CHECKPOINT**: Get explicit approval on refactoring strategy before implementing changes

9. **Document Architectural Decisions** (if applicable):

   If refactoring involves architectural changes, create Architecture Decision Records:

   ```powershell
   # Navigate to ADR creation directory
   Set-Location "doc/process-framework/scripts/file-creation"

   # Create ADR for architectural decisions made during refactoring
   ../../scripts/file-creation/New-ADR.ps1 -Title "[Decision Title]" -Context "[Refactoring context and need for decision]"
   ```

   **When to Create ADRs During Refactoring**:

   - Changing design patterns (e.g., Repository → Service Layer)
   - Modifying dependency injection strategies
   - Altering error handling approaches
   - Restructuring module boundaries
   - Changing data flow or state management patterns

   **Integration Requirements**:

   - Link ADR to refactoring plan in the plan document
   - Update [Architecture Tracking](../../state-tracking/permanent/architecture-tracking.md)
   - Update relevant [Context Packages](../../architecture/context-packages) with decision impact

10. **Implement Incremental Changes**: Apply refactoring in small, testable increments
    - Run existing tests after each change to ensure behavior preservation
    - Commit changes frequently with descriptive messages
    - **🚨 CHECKPOINT**: For each significant change, present the change and get approval before proceeding
11. **Monitor Quality Improvements**: Track code complexity, maintainability, and quality metrics during refactoring
12. **Update Documentation**: Revise code comments, documentation, and architectural notes as needed

#### Standard — Finalization

13. **Systematic Bug Discovery During Refactoring**: As code is restructured and simplified, bugs often become visible that were previously hidden by complexity. Systematically identify and document any bugs discovered during refactoring:

- **Logic Errors**: Bugs revealed when simplifying or restructuring complex code (e.g., incorrect conditional logic, off-by-one errors)
- **Hidden Dependencies**: Issues with undocumented dependencies exposed during refactoring (e.g., implicit ordering requirements, shared state assumptions)
- **Performance Issues**: Performance problems revealed through code analysis and restructuring (e.g., inefficient algorithms, memory leaks)
- **Error Handling Gaps**: Missing or inadequate error handling discovered during code cleanup (e.g., unhandled exceptions, silent failures)
- **Integration Issues**: Problems with component interactions revealed during refactoring (e.g., interface mismatches, protocol violations)
- **Data Handling Bugs**: Issues with data validation or transformation exposed during restructuring (e.g., type conversion errors, boundary condition failures)
- **Concurrency Issues**: Race conditions or synchronization problems revealed when refactoring multi-threaded code
- **Resource Management**: Memory leaks, file handle leaks, or other resource management issues exposed during cleanup

#### Bug Discovery Decision Matrix

When bugs are discovered during refactoring, follow this decision process:

| Bug Severity    | Impact on Refactoring       | Action Required                                                                                                                   | Timeline         |
| --------------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ---------------- |
| **🔴 Critical** | Blocks refactoring progress | 1. **STOP** refactoring<br>2. Create bug report immediately<br>3. Fix bug before continuing<br>4. Update temporary state tracking | Immediate        |
| **🟠 High**     | Affects refactoring quality | 1. Create bug report<br>2. **DECIDE**: Fix now or defer<br>3. Document decision in refactoring plan<br>4. Continue with caution   | Within session   |
| **🟡 Medium**   | Minor impact on refactoring | 1. Document in refactoring plan<br>2. Create bug report<br>3. Continue refactoring<br>4. Schedule fix separately                  | End of session   |
| **🟢 Low**      | No impact on refactoring    | 1. Document in technical debt tracking<br>2. Continue refactoring<br>3. Create bug report if time permits                         | Post-refactoring |

#### Decision Criteria:

- **Critical**: Security vulnerabilities, data corruption, system crashes
- **High**: Functional failures, performance degradation, integration breaks
- **Medium**: UI issues, minor logic errors, edge case failures
- **Low**: Code style issues, minor inefficiencies, cosmetic problems

#### Bug Report Integration:

```powershell
# For bugs discovered during refactoring
../../scripts/file-creation/New-BugReport.ps1 -Title "[Bug Title]" -Description "[Description]" -DiscoveredBy "Refactoring" -Severity "[Critical/High/Medium/Low]" -Component "[Component]" -Environment "Development" -Evidence "Discovered during refactoring: [specific location and context]"
```

14. **Report Discovered Bugs**: If bugs are identified during refactoring:

    - Use [../../scripts/file-creation/New-BugReport.ps1](../../scripts/file-creation/New-BugReport.ps1) script to create standardized bug reports
    - Follow [Bug Reporting Guide](../../guides/guides/bug-reporting-guide.md) for consistent documentation
    - Add bug entries to [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) with status 🆕 Reported
    - Include refactoring context and evidence in bug reports
    - Reference specific code areas or patterns that revealed the bugs
    - Note impact on refactoring goals and code quality improvements

    **Example Bug Report Command**:

    ```powershell
    # Navigate to the scripts directory from project root
    Set-Location "doc/process-framework/scripts/file-creation"

    # Create bug report for issues found during refactoring
    ../../scripts/file-creation/New-BugReport.ps1 -Title "Race condition in async data processing" -Description "Refactoring revealed race condition in async data processing that causes intermittent data corruption" -DiscoveredBy "Development" -Severity "High" -Component "Data Processing" -Environment "Development" -Evidence "Code analysis during refactoring: src/services/data_processor.py:89-102"
    ```

15. **Validate Behavior Preservation**: Run full test suite to confirm no functional changes
16. **Measure Improvements**: Compare final metrics against baseline measurements
17. **🚨 CHECKPOINT**: Present before/after metrics, discovered bugs, and improvement summary to human partner for review
18. **Update Refactoring Plan**: Document actual results, lessons learned, and any remaining technical debt

19. **Complete State File Updates** - Follow this checklist in order:

##### Phase 1: During Refactoring

- [ ] **Update Temporary State Tracking**: Document progress, blockers, and decisions
- [ ] **Update [Bug Tracking](../../state-tracking/permanent/bug-tracking.md)**: Add any discovered bugs with refactoring context
- [ ] **Update [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md)**: `Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "InProgress"`

##### Phase 2: On Refactoring Completion

- [ ] **Update [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md)**: `Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "Resolved" -ResolutionNotes "..." -PlanLink "[TD###](path)"`
- [ ] **Update [Feature Tracking](../../state-tracking/permanent/feature-tracking.md)**: Improve feature status (e.g., "🔄 Needs Revision" → "🧪 Testing")
- [ ] **Update [Architecture Tracking](../../state-tracking/permanent/architecture-tracking.md)**: For foundation features (0.x.x), document architectural improvements
- [ ] **Update [Test Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md)**: Note test improvements or new test requirements

##### Phase 3: Post-Completion

- [ ] **Archive Temporary State** (if created in Step 2): Move temporary state tracking to [archive](../../state-tracking/temporary/old) or delete if no longer needed
- [ ] **Update [Context Packages](../../architecture/context-packages)**: For architectural refactoring, update relevant context packages

20. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Refactoring Plan Document** - Lightweight or standard plan documenting scope, changes, and results (stored in `doc/process-framework/refactoring/plans/`)
- **Refactored Code** - Improved code with better structure, reduced complexity, and maintained functionality
- **Updated Test Suite** - Enhanced or additional tests to cover refactored code areas (standard path)
- **Quality Metrics Report** - Before/after comparison of code quality indicators and performance metrics (standard path)
- **Technical Debt Reduction** - Documented reduction in technical debt items and code quality issues
- **Bug Reports** - Any bugs discovered during refactoring documented in [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) with status 🆕 Reported
- **Updated State Files** - All relevant state tracking files updated according to the applicable path

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Use the checklist matching the path selected in Step 1 (Effort Assessment Gate).

### Lightweight Checklist

- [ ] **Verify Outputs**:
  - [ ] Lightweight Refactoring Plan created with all Item sections filled
  - [ ] Code refactoring implemented and tests passing
  - [ ] Documentation & State Updates checklist completed for each item in the plan
  - [ ] Results Summary table filled in the plan
  - [ ] Any discovered bugs reported using New-BugReport.ps1
- [ ] **Update State Files**:
  - [ ] [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md): resolved items updated via `Update-TechDebt.ps1`
  - [ ] [Feature Tracking](../../state-tracking/permanent/feature-tracking.md): feature status updated if applicable
  - [ ] [Bug Tracking](../../state-tracking/permanent/bug-tracking.md): any discovered bugs added
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-022" and context "Code Refactoring Task"

### Standard Checklist

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Refactoring Plan Document created and completed with results
  - [ ] Code refactoring implemented and tested
  - [ ] Quality metrics measured and documented
  - [ ] Technical debt reduction documented
  - [ ] Bug discovery performed systematically during refactoring using the comprehensive checklist:
    - [ ] Logic errors checked when simplifying complex code
    - [ ] Hidden dependencies identified during component isolation
    - [ ] Performance issues analyzed during code restructuring
    - [ ] Error handling gaps discovered during cleanup
    - [ ] Integration issues revealed during interface changes
    - [ ] Data handling bugs exposed during validation improvements
    - [ ] Concurrency issues checked in multi-threaded code areas
    - [ ] Resource management problems identified during cleanup
  - [ ] Any discovered bugs reported using ../../scripts/file-creation/New-BugReport.ps1 script with proper context and evidence
- [ ] **Update State Files**: Ensure all state tracking files have been updated according to the 3-phase checklist
  - [ ] **Phase 1 (During)**: Temporary state tracking, bug tracking, technical debt progress documented
  - [ ] **Phase 2 (Completion)**: [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) resolved items, [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) status improved, [Architecture Tracking](../../state-tracking/permanent/architecture-tracking.md) updated for foundation features, [Test Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md) updated
  - [ ] **Phase 3 (Post)**: Temporary state archived (if created) to [old directory](../../state-tracking/temporary/old), [Context Packages](../../architecture/context-packages) updated for architectural changes
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-022" and context "Code Refactoring Task"

## Next Tasks

- [**Code Review Task**](code-review-task.md) - Review refactored code for quality and correctness
- [**Technical Debt Assessment Task**](../cyclical/technical-debt-assessment-task.md) - Reassess technical debt after refactoring completion

## Related Resources

- [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) - For identifying refactoring targets
- [Code Quality Standards](../../guides/guides/code-quality-standards.md) - Project coding standards and best practices
- [Testing Guidelines](../../guides/guides/testing-guidelines.md) - Ensuring behavior preservation during refactoring
