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
cd doc/process-framework/scripts/file-creation
.\New-RefactoringPlan.ps1 -RefactoringScope "Brief description" -TargetArea "Component/Module name" -Lightweight
```

For batch mode: copy the "Item N" section in the generated plan for each additional debt item.

**L2. Fill Item Scope**: For each item in the plan, fill in the Scope, Debt Item ID, and Test Baseline fields.

**L3. 🚨 CHECKPOINT**: Present the plan (scope + changes) to human partner for approval before implementing.

**L4. Implement Changes**: Apply refactoring. Run tests after each change to verify behavior preservation.

**L5. Run Regression Tests**: Run `Run-Tests.ps1 -All` to confirm the refactoring preserves all existing behavior across the full test suite. If manual tests exist for the affected feature, set their status to "Needs Re-execution" in test-tracking.md.

**L6. Complete Documentation & State Updates Checklist**: For each item in the plan, check every item in the "Documentation & State Updates" section. Each N/A requires a brief justification note in the plan (e.g., "Grepped TDD — no references to changed method"):
   - Feature implementation state file updated, or N/A — verified file does not reference changed component (grep state file for component/method name)
   - TDD updated, or N/A — verified no interface/design changes documented (grep TDD for references to changed component)
   - Test spec updated, or N/A — verified no behavior change affects spec (grep test spec for changed component)
   - FDD updated, or N/A — verified no functional change affects FDD (grep FDD for changed component)
   - ADR updated, or N/A — verified no architectural decision affected (grep ADR directory for changed component)
   - Validation tracking updated, or N/A — verified feature is not tracked or change doesn't affect validation (check validation-tracking file for feature)
   - Technical Debt Tracking: TD item marked resolved

**L7. Fill Results**: Record test results, bugs discovered, and doc updates in the plan. Complete the Results Summary table.

**L8. Update State Files**:
   - [ ] [Technical Debt Tracking](../../../product-docs/state-tracking/permanent/technical-debt-tracking.md): Mark resolved items using `Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "Resolved" -ResolutionNotes "..."` — if tracked in a validation tracking file (e.g., [validation-tracking.md](../../../product-docs/state-tracking/temporary/validation-tracking.md)), also pass `-FoundationalNote "Resolved (...)" -FoundationalTrackingPath "<absolute-path>"`
   - [ ] [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md): Update feature status if applicable
   - [ ] [Bug Tracking](../../../product-docs/state-tracking/permanent/bug-tracking.md): Report any discovered bugs using New-BugReport.ps1

**L9. 🚨 CHECKPOINT**: Present results summary to human partner for review.

**L10. 🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below.

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] **Verify Outputs**:
  - [ ] Lightweight Refactoring Plan created with all Item sections filled
  - [ ] Code refactoring implemented and tests passing
  - [ ] Documentation & State Updates checklist completed for each item in the plan
  - [ ] Results Summary table filled in the plan
  - [ ] Any discovered bugs reported using New-BugReport.ps1
- [ ] **Update State Files**:
  - [ ] [Technical Debt Tracking](../../../product-docs/state-tracking/permanent/technical-debt-tracking.md): resolved items updated via `Update-TechDebt.ps1`
  - [ ] [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md): feature status updated if applicable
  - [ ] [Bug Tracking](../../../product-docs/state-tracking/permanent/bug-tracking.md): any discovered bugs added
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-022" and context "Code Refactoring Task"
