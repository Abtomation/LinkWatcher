# Code Refactoring — Lightweight Path

> **Parent task**: [Code Refactoring Task](code-refactoring-task.md) (PF-TSK-022)
>
> **Scope**: Refactorings with no architectural impact and no interface/API changes (any file count, any effort level). Supports batch mode — multiple quick fixes in one session using one plan document.

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**

**L1. Create Lightweight Refactoring Plan**:

```powershell
cd process-framework/scripts/file-creation/06-maintenance
New-RefactoringPlan.ps1 -RefactoringScope "Brief description" -TargetArea "Component/Module name" -Lightweight
```

For batch mode: copy the "Item N" section in the generated plan for each additional debt item.

**L2. Fill Item Scope**: For each item in the plan, fill in the Scope, Debt Item ID, and Test Baseline fields. Read the tech debt item's **Dims** column from [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) to understand which dimension(s) the refactoring should improve along.

**L3. Capture Test Baseline**: Before any code changes, run the full test suite and record the exact pass/fail state. This baseline is the accountability anchor — any NEW failures after refactoring are owned by this session.

   > **Documentation-only exemption**: If the change modifies only documentation files (no `.py`/`.js`/code files changed), skip this step and note in the plan: *"Documentation-only change — test baseline skipped."*

   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -All
   ```
   Record in the refactoring plan's Test Baseline field:
   - Total tests, passed, failed, errors
   - **Exact names of any pre-existing failing tests** (copy the FAILED lines from pytest output)

   > **Why**: Without a recorded baseline, parallel sessions dismiss failures as "pre-existing" with no way to verify. The baseline lets you diff at L7 and own any regressions.

**L4. Assess Test Coverage**: For each item, check whether existing tests exercise the specific code paths being refactored. If coverage is insufficient, write characterization tests to lock current behavior before refactoring:
   - **Sufficient coverage**: Existing tests exercise the specific code paths being refactored (both happy paths and error/edge cases touched by the change). Proceed to L4.
   - **Insufficient coverage**: No tests exist for the target method/class, or tests only cover happy paths while the refactoring touches error handling or edge cases. Write characterization tests first:
     ```powershell
     cd process-framework/scripts/file-creation/03-testing
     New-TestFile.ps1 -FeatureId "X.Y.Z" -TestType "unit" -Component "ComponentName"
     ```
   - Characterization tests capture *current* behavior (even if imperfect) — they are a safety net, not a quality judgment.
   - After creating or modifying tests, complete the documentation steps in the [Test File Creation Guide — Test Documentation Completeness](/process-framework/guides/03-testing/test-file-creation-guide.md#5-complete-test-documentation) section.

**L5. 🚨 CHECKPOINT**: Present the plan (scope + changes) to human partner for approval before implementing.

**L6. Implement Changes**: Apply refactoring. Run tests after each change to verify behavior preservation.

   **After any module rename, split, move, or import removal**: Find and update all test files that reference the affected modules:
   ```bash
   # Find tests that import from or mock the changed module
   grep -rn "from old_module\|import old_module\|@patch.*old_module" test/
   ```
   Update mock paths (`@patch("module.Class")`), import statements, and any hardcoded module references to match the new structure. Consult [test-tracking.md](../../../test/state-tracking/permanent/test-tracking.md) to identify which test files cover the affected feature.

**L7. Run Regression Tests & Diff Against Baseline**: Run `Run-Tests.ps1 -All` and compare results against the L3 baseline. If manual tests exist for the affected feature, set their status to "Needs Re-execution" in test-tracking.md.

   > **Documentation-only exemption**: If L3 was skipped (documentation-only change), skip this step too. Note in the plan: *"Documentation-only change — regression testing skipped."*

   - **Same failures as baseline**: Pre-existing — no action required.
   - **NEW failures not in baseline**: Owned by this session — must be fixed before proceeding, or documented as a discovered bug with a bug report.
   - Record the diff summary in the refactoring plan's Results Summary.

**L8. Complete Documentation & State Updates Checklist**: For each item in the plan, check every item in the "Documentation & State Updates" section. Each N/A requires a brief justification note in the plan (e.g., "Grepped TDD — no references to changed method"):

   > **Tier 1 shortcut**: If the feature is Tier 1 and has no design documents (TDD, FDD, ADR, test spec), batch items 2–5 below as N/A with a single justification: *"Tier 1 feature — no design documents exist for [feature name]."* Still check items 1 (feature state file), 6 (validation tracking), and 7 (tech debt) individually.

   > **Test-only shortcut**: If the refactoring targets exclusively test code (no production code changes), batch items 1–6 below as N/A with a single justification: *"Test-only refactoring — no production code changes; design and state documents do not reference test internals."* Still check item 7 (tech debt) individually.

   1. Feature implementation state file updated, or N/A — verified file does not reference changed component (grep state file for component/method name)
   2. TDD updated, or N/A — verified no interface or significant internal design changes (new data structures, algorithm rewrites, storage layout changes) documented in TDD (grep TDD for references to changed component)
   3. Test spec updated, or N/A — verified no behavior change affects spec (grep test spec for changed component)
   4. FDD updated, or N/A — verified no functional change affects FDD (grep FDD for changed component)
   5. ADR updated, or N/A — verified no architectural decision affected (grep ADR directory for changed component)
   6. Validation tracking updated, or N/A — verified feature is not tracked or change doesn't affect validation (check validation-tracking file for feature)
   7. Technical Debt Tracking: TD item marked resolved

**L9. Fill Results**: Record test results, bugs discovered, and doc updates in the plan. Complete the Results Summary table.

**L10. Update State Files**:
   - [ ] [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md): Mark resolved items using `Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "Resolved" -ResolutionNotes "..."` — if tracked in a validation tracking file, also pass `-ValidationNote "PD-REF-### — description"` (validation file auto-discovered)
   - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md): Update feature status if applicable
   - [ ] [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md): Report any discovered bugs using New-BugReport.ps1
   - [ ] **Archive Refactoring Plan**: Move completed plan to `doc/refactoring/plans/archive`

**L11. 🚨 CHECKPOINT**: Present results summary to human partner for review.

**L12. 🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below.

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] **Verify Outputs**:
  - [ ] Lightweight Refactoring Plan created with all Item sections filled
  - [ ] Code refactoring implemented and tests passing
  - [ ] Documentation & State Updates checklist completed for each item in the plan
  - [ ] Results Summary table filled in the plan
  - [ ] Any discovered bugs reported using New-BugReport.ps1
- [ ] **Update State Files**:
  - [ ] [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md): resolved items updated via `Update-TechDebt.ps1`
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md): feature status updated if applicable
  - [ ] [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md): any discovered bugs added
  - [ ] Run [`Validate-TestTracking.ps1`](../../scripts/validation/Validate-TestTracking.ps1) — 0 errors (if tests were added or modified)
  - [ ] Refactoring plan archived to `doc/refactoring/plans/archive`
  - [ ] If file moves changed the source directory structure: run `New-SourceStructure.ps1 -Update` to refresh the [Source Code Layout](/doc/technical/architecture/source-code-layout.md) directory tree
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-022" and context "Code Refactoring Task"
