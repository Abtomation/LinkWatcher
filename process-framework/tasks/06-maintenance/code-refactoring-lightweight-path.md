# Code Refactoring — Lightweight Path

> **Parent task**: [Code Refactoring Task](code-refactoring-task.md) (PF-TSK-022)
>
> **Scope**: Refactorings with no architectural impact and no interface/API changes (any file count, any effort level). Supports batch mode — multiple quick fixes in one session using one plan document.

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**

**L1. Create Lightweight Refactoring Plan**:

```powershell
cd process-framework/scripts/file-creation/06-maintenance
New-RefactoringPlan.ps1 -RefactoringScope "Brief description" -TargetArea "Component/Module name" -Lightweight
```

> **Variant**: Use `-DocumentationOnly` for DA-category items (strips test/baseline sections), `-Performance` for performance-focused refactorings (substitutes user-defined metrics), otherwise `-Lightweight`.

For batch mode: pass `-ItemCount N` (e.g., `-ItemCount 4`) to pre-generate N Item sections plus N Results Summary rows in one go. If you discover additional debt items mid-flight (i.e., new TD IDs — sub-findings of an existing TD become additional `Changes Made` bullets within its Item, not new Items), copy the "Item N" section in the generated plan for each one beyond the original count.

> **Metadata maintenance for scope expansion**: When the plan grows beyond the original `-RefactoringScope` and `-DebtItemId` (whether via `-ItemCount` upfront or item additions mid-flight), also update the plan's frontmatter (`debt_item`, `refactoring_scope`) and document `# Title` to reflect the broader scope. Only the Item sections expand automatically — metadata fields don't.

**L2. Fill Item Scope**: For each item in the plan, fill in the Scope, Debt Item ID, and Test Baseline fields. Read the tech debt item's **Dims** column from [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) to understand which dimension(s) the refactoring should improve along.

   > **DA-category guidance**: For Documentation Alignment items (Dims column contains "DA"), trace the root cause of the drift before fixing it:
   > 1. Identify the originating task/session that introduced the drift (use `git log` on the affected files)
   > 2. Document the drift mechanism (e.g., "implementation changed in PF-TSK-053 session but TDD not updated")
   > 3. Record findings in the refactoring plan's Scope section
   >
   > Understanding *why* documentation drifted is often the primary deliverable for DA items — the text fix itself is secondary.

**L3. Capture Test Baseline**: Before any code changes, run the full test suite and record the exact pass/fail state. This baseline is the accountability anchor — any NEW failures after refactoring are owned by this session.

   > **Documentation-only exemption**: If the change modifies only documentation files (no `.py`/`.js`/code files changed), skip this step and note in the plan: *"Documentation-only change — test baseline skipped."*

   > **Build-config-only exemption**: If the change is confined to declarative build/dependency config that pytest doesn't read at runtime — pyproject.toml `[project.dependencies]`, `[project.optional-dependencies]`, or `[project]` metadata fields; `requirements*.txt` entries — skip this step and note in the plan: *"Build-config-only change — test baseline skipped."* **Not exempt**: `[tool.pytest.*]` sections (directly affect pytest runtime) or any tool config that changes how tests execute.

   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -All
   ```

   > **Slow-marked targets**: `-All` excludes `@pytest.mark.slow` tests (typically files under `test/automated/performance/`). If your refactoring target is slow-marked, the default `-All` baseline won't include it — silently. For slow targets, baseline with `-All -Performance` together (covers both fast and slow), or invoke pytest directly: `python -m pytest test/automated/ -v`. Verify your target appears in the captured output before treating the baseline as complete. Use the **same command at L7** so the regression diff compares like with like.

   Record in the refactoring plan's Test Baseline field:
   - Total tests, passed, failed, errors
   - **Exact names of any pre-existing failing tests** (copy the FAILED lines from pytest output)

   > **Why**: Without a recorded baseline, parallel sessions dismiss failures as "pre-existing" with no way to verify. The baseline lets you diff at L7 and own any regressions.

**L4. Assess Test Coverage**: For each item, check whether existing tests exercise the specific code paths being refactored. If coverage is insufficient, write characterization tests to lock current behavior before refactoring:

   > **Test-only exemption**: If the refactoring targets exclusively test code (no production code changes — e.g., assertion thresholds, fixture data, test scaffolding), L4 does not apply: the modified test verifies its own behavior. Skip to L5 and note in the plan: *"Test-only refactoring — coverage assessment N/A; modified test verifies its own behavior."*

   - **Sufficient coverage**: Existing tests exercise the specific code paths being refactored (both happy paths and error/edge cases touched by the change). Proceed to L4.
     - **Include transitive callers**: Tests that exercise the affected branch through higher-level public APIs (e.g., `update_references()` → `_calculate_new_target()` → branch under test) count as coverage even if they don't name the changed method. Trace the call path from public APIs into the refactored code rather than grepping for the method name alone.
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

**L7. Run Regression Tests & Diff Against Baseline**: Run `Run-Tests.ps1 -All` and compare results against the L3 baseline. If E2E acceptance tests exist for the affected feature in [e2e-test-tracking.md](../../../test/state-tracking/permanent/e2e-test-tracking.md), mark them for re-execution:

   ```powershell
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1 -FeatureId "X.Y.Z" -Status "Needs Re-execution" -Reason "Refactoring [scope]" -Confirm:\$false
   ```

   > **Documentation-only exemption**: If L3 was skipped (documentation-only change), skip this step too. Note in the plan: *"Documentation-only change — regression testing skipped."*

   > **Build-config-only exemption**: If L3 was skipped under the build-config-only exemption, skip this step too. Note in the plan: *"Build-config-only change — regression testing skipped."*

   - **Same failures as baseline**: Pre-existing — no action required.
   - **NEW failures not in baseline**: Owned by this session — must be fixed before proceeding, or documented as a discovered bug with a bug report.
   - Record the diff summary in the refactoring plan's Results Summary.

**L8. Complete Documentation & State Updates Checklist**: For each item in the plan, check every item in the "Documentation & State Updates" section. Each N/A requires a brief justification note in the plan (e.g., "Grepped TDD — no references to changed method"):

   > **Tier 1 shortcut**: If the feature is Tier 1 and has no design documents (TDD, FDD, ADR, test spec), batch items 2–5 below as N/A with a single justification: *"Tier 1 feature — no design documents exist for [feature name]."* Still check items 1 (feature state file), 6 (integration narrative), 7 (user documentation), 8 (validation tracking), and 9 (tech debt) individually.

   > **Test-only shortcut**: If the refactoring targets exclusively test code (no production code changes), batch items 1–8 below as N/A with a single justification: *"Test-only refactoring — no production code changes; design, user-facing, and state documents do not reference test internals."* Still check item 9 (tech debt) individually.

   > **Documentation-only shortcut**: If the refactoring modifies only documentation files, docstrings, or comments (no behavioral code changes), batch items 1–8 below as N/A with a single justification: *"Documentation-only change — no behavioral code changes; design, user-facing, and state documents do not need updates for [description of change]."* Still check item 9 (tech debt) individually.

   > **Build-config-only shortcut**: If the refactoring modifies only declarative build/dependency config (pyproject.toml `[project.*]`, `requirements*.txt`) with no code, test, or `[tool.pytest.*]` changes, batch items 1–8 below as N/A with a single justification: *"Build-config-only change — declarative dependency/metadata edit; design, user-facing, and state documents do not reference build config."* Still check item 9 (tech debt) individually.

   > **Grep recipe (internal-only refactors)**: When a refactoring is confined to internal identifiers (signatures unchanged, no public API surface touched, test diff zero against L3 baseline), verify all 8 doc surfaces in one ripgrep pass:
   > ```bash
   > rg -l "<identifier>" doc/state-tracking/features/ doc/technical/ doc/functional-design/ doc/user/ doc/state-tracking/validation/ test/specifications/ README.md
   > ```
   > If 0 matches across all surfaces, items 1–8 may share one collective justification: *"Grepped all design/state/user-doc/validation surfaces for `<identifier>` — 0 matches; no doc surface references the refactored internal."* Item 9 (tech debt) still individual.
   >
   > **Use this instead of writing 8 similar per-item N/A lines.** Hits in unexpected surfaces (e.g., a TDD that documents the renamed helper) signal that the refactoring isn't internal-only after all and the affected items need real updates.

   1. Feature implementation state file updated, or N/A — verified file does not reference changed component (grep state file for component/method name)
   2. TDD updated, or N/A — verified no interface or significant internal design changes (new data structures, algorithm rewrites, storage layout changes) documented in TDD (grep TDD for references to changed component)
   3. Test spec updated, or N/A — verified no behavior change affects spec (grep test spec for changed component)
   4. FDD updated, or N/A — verified no functional change affects FDD (grep FDD for changed component)
   5. ADR updated, or N/A — verified no architectural decision affected (grep ADR directory for changed component)
   6. Integration Narrative updated, or N/A — verified no PD-INT narrative in `doc/technical/integration/` references the refactored component (grep narrative directory for component/method name)
   7. User documentation updated, or N/A — verified no behavioral or interface change visible to end users (grep `doc/user/handbooks/` and root `README.md` for component/method/script name)
   8. Validation tracking updated, or N/A — verified feature is not tracked or change doesn't affect validation (check validation-tracking file for feature)
   9. Test tracking files updated, or N/A — verified no columns mirroring code values changed (e.g., `performance-test-tracking.md` Tolerance column when test assertions changed). Leaving drift here causes the next Test Audit (PF-TSK-030 Criterion 3) to flag it.
   10. Technical Debt Tracking: TD item marked resolved

**L9. Fill Results**: Record test results, bugs discovered, and doc updates in the plan. Complete the Results Summary table.

**L10. 🚨 CHECKPOINT**: Present results summary to human partner for review **before** updating any state files.

   > **Why checkpoint first**: L11's actions (TD resolution, plan archive, bug reports, audit-status propagation) are non-trivial to reverse if the human redirects scope (e.g., "also fix related TD###" or "split this into two refactorings"). Gating the permanent updates behind approval keeps the checkpoint a real decision point rather than a fait accompli.

**L11. Update State Files** *(after L10 approval)*:
   - [ ] [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md): Mark resolved items using `Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "Resolved" -ResolutionNotes "..."` — if tracked in a validation tracking file, also pass `-ValidationNote "PD-REF-### — description"` (validation file auto-discovered)
   - [ ] **Audit-flagged TD closure** (only if the resolved TD's Source column or resolution notes reference a `TE-TAR-*` audit report): after `Update-TechDebt.ps1` completes, close the audit status loop — otherwise `test-tracking.md` and `feature-tracking.md` retain the stale audit status from the original audit report (the gap that caused feature 0.1.2 to sit in split-brain state for ~2 weeks).
       - **If the resolution closes ALL findings from that audit** — run:
         ```powershell
         Update-TestFileAuditState.ps1 -TestFilePath <test file> -AuditStatus "Audit Approved" -AuditReportPath <original TE-TAR report>
         ```
       - **If findings are only partially addressed** — do NOT mark as "Audit Approved". Route to [Test Audit (PF-TSK-030)](../03-testing/test-audit-task.md) for a re-audit instead.
   - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md): Update feature status if applicable
   - [ ] [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md): Report any discovered bugs using New-BugReport.ps1
   - [ ] **Archive Refactoring Plan**: Move completed plan to `doc/refactoring/plans/archive`

**L12. 🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below.

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

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
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-022" and context "Code Refactoring Task"
