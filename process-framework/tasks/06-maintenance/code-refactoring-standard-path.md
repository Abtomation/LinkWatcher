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
   cd process-framework/scripts/file-creation/06-maintenance
   New-RefactoringPlan.ps1 -RefactoringScope "Brief description" -TargetArea "Component/Module name"
   # Add -DocumentationOnly for doc-only changes (no code metrics/test sections)
   # Add -DebtItemId "TDXXX" to auto-populate debt item reference
   ```

2. **Create Temporary State Tracking** (conditional):

   - **< 5 items and ≤ 2 sessions expected**: Skip temp state file. Use the refactoring plan's "Implementation Tracking" section for all progress tracking.
   - **≥ 5 items or multi-session (3+)**: Create a separate temp state file:

   ```powershell
   # Navigate to state tracking directory
   Set-Location "process-framework-local/state-tracking"

   # Create temporary tracking file for refactoring work
   ../../scripts/file-creation/support/New-TempTaskState.ps1 -TaskName "[Refactoring Scope] Refactoring" -Description "Refactoring work for [specific component/feature]"
   ```

   - Document refactoring progress and blockers in the chosen tracking surface
   - Update status regularly during implementation

3. **Analyze Current State**: Document current code quality issues, complexity metrics, and technical debt items. Read the tech debt item's **Dims** column from [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) to understand the primary dimension(s) the refactoring should improve along — verify the refactoring plan addresses the flagged dimension(s)
4. **Check manual test coverage**: Review [test-tracking.md](../../../test/state-tracking/permanent/test-tracking.md) for manual test cases covering the affected functionality. Note which test groups will need re-execution after refactoring.
5. **Capture Test Baseline**: Before any code changes, run the full test suite and record the exact pass/fail state. This baseline is the accountability anchor — any NEW failures after refactoring are owned by this session.
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -All
   ```
   Record in the refactoring plan's Test Baseline field:
   - Total tests, passed, failed, errors
   - **Exact names of any pre-existing failing tests** (copy the FAILED lines from pytest output)

   > **Why**: Without a recorded baseline, parallel sessions dismiss failures as "pre-existing" with no way to verify. The baseline lets you diff at Step 18 and own any regressions.
6. **Assess Test Coverage**: Check whether existing tests exercise the specific code paths being refactored. If coverage is insufficient, write characterization tests to lock current behavior before proceeding:
   - **Sufficient coverage**: Existing tests exercise the specific code paths being refactored (both happy paths and error/edge cases touched by the change). Proceed to Step 6.
   - **Insufficient coverage**: No tests exist for the target method/class, or tests only cover happy paths while the refactoring touches error handling or edge cases. Write characterization tests first:
     ```powershell
     cd process-framework/scripts/file-creation/03-testing
     New-TestFile.ps1 -FeatureId "X.Y.Z" -TestType "unit" -Component "ComponentName"
     ```
   - Characterization tests capture *current* behavior (even if imperfect) — they are a safety net, not a quality judgment.
   - After creating or modifying tests, complete the documentation steps in the [Test File Creation Guide — Test Documentation Completeness](/process-framework/guides/03-testing/test-file-creation-guide.md#5-complete-test-documentation) section.
7. **Create Baseline Measurements**: Record current performance metrics and code quality indicators
8. **🚨 CHECKPOINT**: Present analysis findings, baseline metrics, and test coverage status to human partner

### Execution

9. **Define Refactoring Strategy**: Document specific refactoring techniques and approach in the plan
10. **🚨 CHECKPOINT**: Get explicit approval on refactoring strategy before implementing changes

11. **Document Architectural Decisions** (if applicable):

   If refactoring involves architectural changes, create Architecture Decision Records:

   ```powershell
   # Navigate to ADR creation directory
   Set-Location "process-framework/scripts/file-creation/02-design"

   # Create ADR for architectural decisions made during refactoring
   New-ArchitectureDecision.ps1 -Title "[Decision Title]" -Context "[Refactoring context and need for decision]"
   ```

   **When to Create ADRs During Refactoring**:

   - Changing design patterns (e.g., Repository → Service Layer)
   - Modifying dependency injection strategies
   - Altering error handling approaches
   - Restructuring module boundaries
   - Changing data flow or state management patterns

   **Integration Requirements**:

   - Link ADR to refactoring plan in the plan document
   - Update [Architecture Tracking](../../../doc/state-tracking/permanent/architecture-tracking.md)
   - Update relevant [Architecture Tracking](../../../doc/state-tracking/permanent/architecture-tracking.md) with decision impact

12. **Implement Incremental Changes**: Apply refactoring in small, testable increments
    - Run existing tests after each change to ensure behavior preservation
    - Commit changes frequently with descriptive messages
    - **After any module rename, split, move, or import removal**: Find and update all test files that reference the affected modules:
      ```bash
      # Find tests that import from or mock the changed module
      grep -rn "from old_module\|import old_module\|@patch.*old_module" test/
      ```
      Update mock paths (`@patch("module.Class")`), import statements, and any hardcoded module references to match the new structure. Consult [test-tracking.md](../../../test/state-tracking/permanent/test-tracking.md) to identify which test files cover the affected feature.
    - **🚨 CHECKPOINT**: For each significant change, present the change and get approval before proceeding
13. **Monitor Quality Improvements**: Track code complexity, maintainability, and quality metrics during refactoring
14. **Update Product Documentation**: When refactoring changes module boundaries, interfaces, or design patterns, update the affected product documentation:
    - **Feature implementation state file** — update component lists, file paths, architecture notes
    - **TDD** — update if interface contracts, component diagrams, or design patterns changed
    - **FDD** — update if functional behavior or user-facing workflows changed
    - **Test spec** — update if test categories, component mappings, or coverage expectations changed
    - **Feature tracking** — update if module scope or feature boundaries shifted
    - **Integration Narrative** (`doc/technical/integration/`) — update if refactoring changes how features interact in a cross-feature workflow documented by a PD-INT narrative

### Finalization

15. **Systematic Bug Discovery During Refactoring**: As code is restructured and simplified, bugs often become visible that were previously hidden by complexity. Systematically identify and document any bugs discovered during refactoring:

> **N/A escape hatches** (pick the first that applies, mark the corresponding completion checklist items as N/A):
>
> - **Non-logic changes** (string replacements, comment-only, documentation-only refactorings): Skip this checklist entirely — no bug discovery is expected when no logic is modified.
> - **Structural-only changes** (logic-preserving restructuring such as Extract Class, Move Method, pattern extraction where all logic paths are preserved): Check only **Hidden Dependencies** and **Integration Issues** below. Skip the other 6 categories — concurrency, resource management, performance, etc. are not affected when logic is moved but not modified.

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

16. **Assess Test Gaps for Extracted Units**: After refactoring, evaluate whether newly created code units need dedicated tests. Skip this step (mark N/A) for non-logic changes (string replacements, comment-only, documentation-only refactorings).

   - **Extracted methods/functions** — do they have unit tests exercising their inputs, outputs, and edge cases?
   - **New classes/modules** — do they have a dedicated test file?
   - **Changed interfaces** — are integration tests updated to cover the new contract?
   - **Extracted utility/helper functions** — are boundary conditions and error cases covered?

   If gaps are found, create tests:
   ```powershell
   cd process-framework/scripts/file-creation/03-testing
   New-TestFile.ps1 -FeatureId "X.Y.Z" -TestType "unit" -Component "ComponentName"
   ```

   > **Scope check**: If test gaps are systemic (spanning multiple components or features beyond the refactoring scope), document the gap and recommend [Test Specification Creation (PF-TSK-012)](../03-testing/test-specification-creation-task.md) as a follow-up rather than addressing it inline.

   After creating or modifying tests, complete the documentation steps in the [Test File Creation Guide — Test Documentation Completeness](/process-framework/guides/03-testing/test-file-creation-guide.md#5-complete-test-documentation) section.

17. **Report Discovered Bugs**: If bugs are identified during refactoring:

    - Use [../../scripts/file-creation/06-maintenance/New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) script to create standardized bug reports
    - Follow [Bug Reporting Guide](../../guides/06-maintenance/bug-reporting-guide.md) for consistent documentation
    - Add bug entries to [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Reported
    - Include refactoring context and evidence in bug reports
    - Reference specific code areas or patterns that revealed the bugs
    - Note impact on refactoring goals and code quality improvements

    **Example Bug Report Command**:

    ```powershell
    # Navigate to the scripts directory from project root
    Set-Location "process-framework/scripts/file-creation"

    # Create bug report for issues found during refactoring
    ../../scripts/file-creation/06-maintenance/New-BugReport.ps1 -Title "Race condition in async data processing" -Description "Refactoring revealed race condition in async data processing that causes intermittent data corruption" -DiscoveredBy "Refactoring" -Severity "High" -Component "Data Processing" -Environment "Development" -Evidence "Code analysis during refactoring: src/services/data_processor.py:89-102"
    ```

18. **Validate Behavior Preservation & Diff Against Baseline**: Run full test suite (`Run-Tests.ps1 -All`) and compare results against the Step 5 baseline. If manual tests exist for the affected features, set their status to "Needs Re-execution" in test-tracking.md.
   - **Same failures as baseline**: Pre-existing — no action required.
   - **NEW failures not in baseline**: Owned by this session — must be fixed before proceeding, or documented as a discovered bug with a bug report.
   - Record the diff summary in the refactoring plan's Results Summary.
19. **Measure Improvements**: Compare final metrics against baseline measurements
20. **🚨 CHECKPOINT**: Present before/after metrics, discovered bugs, and improvement summary to human partner for review
21. **Update Refactoring Plan**: Document actual results, lessons learned, and any remaining technical debt

22. **Complete State File Updates** - Follow this checklist in order:

##### Phase 1: During Refactoring

- [ ] **Update Temporary State Tracking**: Document progress, blockers, and decisions
- [ ] **Update [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md)**: Add any discovered bugs with refactoring context
- [ ] **Update [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md)**: `Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "InProgress"`

##### Phase 2: On Refactoring Completion

- [ ] **Update [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md)**: `Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "Resolved" -ResolutionNotes "..." -PlanLink "[TD###](path)"` — if tracked in a validation tracking file, also pass `-ValidationNote "PD-REF-### — description"` (validation file auto-discovered)
- [ ] **Update [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)**: Improve feature status (e.g., "🔄 Needs Revision" → "🧪 Testing")
- [ ] **Update [Architecture Tracking](../../../doc/state-tracking/permanent/architecture-tracking.md)**: For foundation features (0.x.x), document architectural improvements
- [ ] **Update [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md)**: Note test improvements or new test requirements
- [ ] **Mark manual test groups for re-execution** (if applicable): `Update-TestExecutionStatus.ps1 -FeatureId "X.Y.Z" -Status "Needs Re-execution" -Reason "Refactoring [scope]"`

##### Phase 3: Post-Completion

- [ ] **Archive Temporary State** (if created in Step 2): Move temporary state tracking to [archive](../../state-tracking/temporary/old) or delete if no longer needed
- [ ] **Update [Architecture Tracking](../../../doc/state-tracking/permanent/architecture-tracking.md)**: For architectural refactoring, update relevant context packages

23. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Refactoring Plan Document created and completed with results
  - [ ] Code refactoring implemented and tested
  - [ ] Quality metrics measured and documented
  - [ ] Technical debt reduction documented
  - [ ] Bug discovery performed systematically during refactoring using the checklist (see Step 15 N/A escape hatches: skip entirely for non-logic changes; for structural-only changes check only hidden dependencies + integration issues):
    - [ ] Logic errors checked when simplifying complex code
    - [ ] Hidden dependencies identified during component isolation
    - [ ] Performance issues analyzed during code restructuring
    - [ ] Error handling gaps discovered during cleanup
    - [ ] Integration issues revealed during interface changes
    - [ ] Data handling bugs exposed during validation improvements
    - [ ] Concurrency issues checked in multi-threaded code areas
    - [ ] Resource management problems identified during cleanup
  - [ ] Any discovered bugs reported using ../../scripts/file-creation/06-maintenance/New-BugReport.ps1 script with proper context and evidence
  - [ ] Test gap assessment for extracted units completed (N/A for non-logic changes — skip when refactoring involves no extraction of new methods/classes)
- [ ] **Update State Files**: Ensure all state tracking files have been updated according to the 3-phase checklist
  - [ ] **Phase 1 (During)**: Temporary state tracking, bug tracking, technical debt progress documented
  - [ ] **Phase 2 (Completion)**: [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) resolved items, [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) status improved, [Architecture Tracking](../../../doc/state-tracking/permanent/architecture-tracking.md) updated for foundation features, [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) updated
  - [ ] Run [`Validate-TestTracking.ps1`](../../scripts/validation/Validate-TestTracking.ps1) — 0 errors (if tests were added or modified)
  - [ ] **Product Documentation**: If refactoring changed module boundaries/interfaces/design patterns — feature state file, TDD, FDD, and test spec updated (Step 13)
  - [ ] **Phase 3 (Post)**: Temporary state archived (if created) to [old directory](../../state-tracking/temporary/old), [Architecture Tracking](../../../doc/state-tracking/permanent/architecture-tracking.md) updated for architectural changes, refactoring plan archived to `doc/refactoring/plans/archive`
  - [ ] If file moves changed the source directory structure: run `New-SourceStructure.ps1 -Update` to refresh the [Source Code Layout](/doc/technical/architecture/source-code-layout.md) directory tree
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-022" and context "Code Refactoring Task"
