# Code Refactoring — Standard Path

> **Parent task**: [Code Refactoring Task](code-refactoring-task.md) (PF-TSK-022)
>
> **Scope**: Medium/complex refactorings (> 15 min, multiple files, or architectural impact).

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the appropriate automation tools where indicated.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Create Refactoring Plan**: Use automation script to create structured refactoring plan document

   ```powershell
   cd doc/process-framework/scripts/file-creation
   .\New-RefactoringPlan.ps1 -RefactoringScope "Brief description" -TargetArea "Component/Module name"
   # Add -DocumentationOnly for doc-only changes (no code metrics/test sections)
   # Add -DebtItemId "TDXXX" to auto-populate debt item reference
   ```

2. **Create Temporary State Tracking** (conditional):

   - **< 5 items and ≤ 2 sessions expected**: Skip temp state file. Use the refactoring plan's "Implementation Tracking" section for all progress tracking.
   - **≥ 5 items or multi-session (3+)**: Create a separate temp state file:

   ```powershell
   # Navigate to state tracking directory
   Set-Location "doc/process-framework/state-tracking"

   # Create temporary tracking file for refactoring work
   ../../scripts/file-creation/support/New-TempTaskState.ps1 -TaskName "[Refactoring Scope] Refactoring" -TaskType "Discrete" -Description "Refactoring work for [specific component/feature]"
   ```

   - Document refactoring progress and blockers in the chosen tracking surface
   - Update status regularly during implementation

3. **Analyze Current State**: Document current code quality issues, complexity metrics, and technical debt items
4. **Check manual test coverage**: Review [test-tracking.md](../../state-tracking/permanent/test-tracking.md) for manual test cases covering the affected functionality. Note which test groups will need re-execution after refactoring.
5. **Verify Test Coverage**: Ensure comprehensive test coverage exists for the target code area
5. **Create Baseline Measurements**: Record current performance metrics and code quality indicators
6. **🚨 CHECKPOINT**: Present analysis findings, baseline metrics, and test coverage status to human partner

### Execution

7. **Define Refactoring Strategy**: Document specific refactoring techniques and approach in the plan
8. **🚨 CHECKPOINT**: Get explicit approval on refactoring strategy before implementing changes

9. **Document Architectural Decisions** (if applicable):

   If refactoring involves architectural changes, create Architecture Decision Records:

   ```powershell
   # Navigate to ADR creation directory
   Set-Location "doc/process-framework/scripts/file-creation/02-design"

   # Create ADR for architectural decisions made during refactoring
   ./New-ArchitectureDecision.ps1 -Title "[Decision Title]" -Context "[Refactoring context and need for decision]"
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
12. **Update Product Documentation**: When refactoring changes module boundaries, interfaces, or design patterns, update the affected product documentation:
    - **Feature implementation state file** — update component lists, file paths, architecture notes
    - **TDD** — update if interface contracts, component diagrams, or design patterns changed
    - **FDD** — update if functional behavior or user-facing workflows changed
    - **Test spec** — update if test categories, component mappings, or coverage expectations changed
    - **Feature tracking** — update if module scope or feature boundaries shifted

### Finalization

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
../../scripts/file-creation/06-maintenance/New-BugReport.ps1 -Title "[Bug Title]" -Description "[Description]" -DiscoveredBy "Refactoring" -Severity "[Critical/High/Medium/Low]" -Component "[Component]" -Environment "Development" -Evidence "Discovered during refactoring: [specific location and context]"
```

14. **Report Discovered Bugs**: If bugs are identified during refactoring:

    - Use [../../scripts/file-creation/06-maintenance/New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) script to create standardized bug reports
    - Follow [Bug Reporting Guide](../../guides/06-maintenance/bug-reporting-guide.md) for consistent documentation
    - Add bug entries to [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) with status 🆕 Reported
    - Include refactoring context and evidence in bug reports
    - Reference specific code areas or patterns that revealed the bugs
    - Note impact on refactoring goals and code quality improvements

    **Example Bug Report Command**:

    ```powershell
    # Navigate to the scripts directory from project root
    Set-Location "doc/process-framework/scripts/file-creation"

    # Create bug report for issues found during refactoring
    ../../scripts/file-creation/06-maintenance/New-BugReport.ps1 -Title "Race condition in async data processing" -Description "Refactoring revealed race condition in async data processing that causes intermittent data corruption" -DiscoveredBy "Development" -Severity "High" -Component "Data Processing" -Environment "Development" -Evidence "Code analysis during refactoring: src/services/data_processor.py:89-102"
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

- [ ] **Update [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md)**: `Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "Resolved" -ResolutionNotes "..." -PlanLink "[TD###](path)"` — if the TD item is tracked in [Foundational Validation Tracking](../../state-tracking/temporary/foundational-validation-tracking.md), also pass `-FoundationalNote "Resolved (...)" -FoundationalTrackingPath "<absolute-path>"`
- [ ] **Update [Feature Tracking](../../state-tracking/permanent/feature-tracking.md)**: Improve feature status (e.g., "🔄 Needs Revision" → "🧪 Testing")
- [ ] **Update [Architecture Tracking](../../state-tracking/permanent/architecture-tracking.md)**: For foundation features (0.x.x), document architectural improvements
- [ ] **Update [Test Tracking](../../state-tracking/permanent/test-tracking.md)**: Note test improvements or new test requirements
- [ ] **Mark manual test groups for re-execution** (if applicable): `Update-TestExecutionStatus.ps1 -FeatureId "X.Y.Z" -Status "Needs Re-execution" -Reason "Refactoring [scope]"`

##### Phase 3: Post-Completion

- [ ] **Archive Temporary State** (if created in Step 2): Move temporary state tracking to [archive](../../state-tracking/temporary/old) or delete if no longer needed
- [ ] **Update [Context Packages](../../architecture/context-packages)**: For architectural refactoring, update relevant context packages

20. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

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
  - [ ] Any discovered bugs reported using ../../scripts/file-creation/06-maintenance/New-BugReport.ps1 script with proper context and evidence
- [ ] **Update State Files**: Ensure all state tracking files have been updated according to the 3-phase checklist
  - [ ] **Phase 1 (During)**: Temporary state tracking, bug tracking, technical debt progress documented
  - [ ] **Phase 2 (Completion)**: [Technical Debt Tracking](../../state-tracking/permanent/technical-debt-tracking.md) resolved items, [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) status improved, [Architecture Tracking](../../state-tracking/permanent/architecture-tracking.md) updated for foundation features, [Test Tracking](../../state-tracking/permanent/test-tracking.md) updated
  - [ ] **Product Documentation**: If refactoring changed module boundaries/interfaces/design patterns — feature state file, TDD, FDD, and test spec updated (Step 12)
  - [ ] **Phase 3 (Post)**: Temporary state archived (if created) to [old directory](../../state-tracking/temporary/old), [Context Packages](../../architecture/context-packages) updated for architectural changes
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-022" and context "Code Refactoring Task"
