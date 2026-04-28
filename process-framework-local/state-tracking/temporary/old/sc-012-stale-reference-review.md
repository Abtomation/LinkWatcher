# SC-012 Stale Reference Review

Systematic review of 256 files with remaining `linkwatcher/` references after directory move to `src/linkwatcher/`.

**Legend**:
- `[I]` = Ignored (archived/historical — no update needed)
- `[U]` = Updated to `src/linkwatcher/`
- `[F]` = False positive — `linkwatcher/` is correct (not a source code path)
- `[B]` = Bug — reference should have been updated by LinkWatcher but wasn't
- `[ ]` = Not yet reviewed

---

## 1. Root Config & Build Files (3 files)

- [U] `.claude/settings.local.json` — L28: absolute path in bash allowlist updated
- [F] `pyproject.toml` — L56,58,59: GitHub URLs (org/repo slug), not filesystem paths
- [F] `config-examples/production-config.yaml` — L36: Linux system log path `/var/log/linkwatcher/`

## 2. README (1 file)

- [F] `README.md` — Clean (all refs already `src/linkwatcher/`)

## 3. FDDs (6 files)

- [F] `doc/functional-design/fdds/fdd-0-1-1-core-architecture.md` — Clean
- [F] `doc/functional-design/fdds/fdd-0-1-2-in-memory-database.md` — Clean
- [F] `doc/functional-design/fdds/fdd-1-1-1-file-system-monitoring.md` — Clean
- [F] `doc/functional-design/fdds/fdd-2-1-1-parser-framework.md` — Clean
- [F] `doc/functional-design/fdds/fdd-2-2-1-link-updater.md` — Clean
- [F] `doc/functional-design/fdds/fdd-3-1-1-logging-framework.md` — Clean

## 4. TDDs (7 files)

- [F] `doc/technical/tdd/tdd-0-1-1-core-architecture-t3.md` — Clean
- [F] `doc/technical/tdd/tdd-0-1-2-in-memory-database-t2.md` — Clean
- [F] `doc/technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md` — Clean
- [F] `doc/technical/tdd/tdd-2-1-1-parser-framework-t2.md` — Clean
- [F] `doc/technical/tdd/tdd-2-2-1-link-updater-t2.md` — Clean
- [F] `doc/technical/tdd/tdd-3-1-1-logging-framework-t2.md` — Clean
- [F] `doc/technical/tdd/archive/tdd-4-1-1-test-suite-t2.md` — Clean

## 5. ADRs (3 files)

- [F] `doc/technical/adr/orchestrator-facade-pattern-for-core-architecture.md` — Clean
- [F] `doc/technical/adr/target-indexed-in-memory-link-database.md` — Clean
- [F] `doc/technical/adr/timer-based-move-detection-with-3-phase-directory-batch-algorithm.md` — Clean

## 6. Implementation Plans (1 file)

- [F] `doc/technical/implementation-plans/6-1-1-link-validation-implementation-plan.md` — Clean

## 7. User Handbooks (3 files)

- [F] `doc/user/handbooks/file-type-quick-fix.md` — Clean
- [U] `doc/user/handbooks/multi-project-setup.md` — L14: directory tree updated to `src/linkwatcher/`
- [F] `doc/user/handbooks/troubleshooting-file-types.md` — Clean

## 8. CI/CD Docs (1 file)

- [F] `doc/ci-cd/release-process.md` — L92: `~/bin/linkwatcher/` is deployment target, not source path

## 9. Documentation Tiers (1 file)

- [U] `doc/documentation-tiers/assessments/PD-ASS-194-1-1-1-file-system-monitoring.md` — L81: prose source path updated

## 10. Feature State Files — Active (8 files)

- [F] `doc/state-tracking/features/0.1.1-core-architecture-implementation-state.md` — Clean
- [F] `doc/state-tracking/features/0.1.2-in-memory-link-database-implementation-state.md` — Clean
- [F] `doc/state-tracking/features/0.1.3-configuration-system-implementation-state.md` — Clean
- [F] `doc/state-tracking/features/1.1.1-file-system-monitoring-implementation-state.md` — Clean
- [F] `doc/state-tracking/features/2.1.1-link-parsing-system-implementation-state.md` — Clean
- [F] `doc/state-tracking/features/2.2.1-link-updating-implementation-state.md` — Clean
- [F] `doc/state-tracking/features/3.1.1-logging-system-implementation-state.md` — Clean
- [F] `doc/state-tracking/features/6.1.1-Link Validation-implementation-state.md` — Clean

## 11. Feature State Files — Archive (36 files)

All clean — LinkWatcher already updated all references to `src/linkwatcher/`. No stale `linkwatcher/` remains.

- [I] `doc/state-tracking/features/archive/0.1.2-data-models-implementation-state.md`
- [I] `doc/state-tracking/features/archive/0.1.3-in-memory-database-implementation-state.md`
- [I] `doc/state-tracking/features/archive/0.1.4-configuration-system-implementation-state.md`
- [I] `doc/state-tracking/features/archive/0.1.5-path-utilities-implementation-state.md`
- [I] `doc/state-tracking/features/archive/1.1.1-watchdog-integration-implementation-state.md`
- [I] `doc/state-tracking/features/archive/1.1.2-event-handler-implementation-state.md`
- [I] `doc/state-tracking/features/archive/1.1.3-initial-scan-implementation-state.md`
- [I] `doc/state-tracking/features/archive/1.1.4-file-filtering-implementation-state.md`
- [I] `doc/state-tracking/features/archive/1.1.5-real-time-monitoring-implementation-state.md`
- [I] `doc/state-tracking/features/archive/2.1.1-parser-framework-implementation-state.md`
- [I] `doc/state-tracking/features/archive/2.1.2-markdown-parser-implementation-state.md`
- [I] `doc/state-tracking/features/archive/2.1.3-yaml-parser-implementation-state.md`
- [I] `doc/state-tracking/features/archive/2.1.4-json-parser-implementation-state.md`
- [I] `doc/state-tracking/features/archive/2.1.5-python-parser-implementation-state.md`
- [I] `doc/state-tracking/features/archive/2.1.6-dart-parser-implementation-state.md`
- [I] `doc/state-tracking/features/archive/2.1.7-generic-parser-implementation-state.md`
- [I] `doc/state-tracking/features/archive/2.2.1-link-updater-implementation-state.md`
- [I] `doc/state-tracking/features/archive/2.2.2-relative-path-calculation-implementation-state.md`
- [I] `doc/state-tracking/features/archive/2.2.3-anchor-preservation-implementation-state.md`
- [I] `doc/state-tracking/features/archive/2.2.4-dry-run-mode-implementation-state.md`
- [I] `doc/state-tracking/features/archive/2.2.5-backup-creation-implementation-state.md`
- [I] `doc/state-tracking/features/archive/3.1.1-logging-framework-implementation-state.md`
- [I] `doc/state-tracking/features/archive/3.1.2-colored-console-output-implementation-state.md`
- [I] `doc/state-tracking/features/archive/3.1.3-statistics-tracking-implementation-state.md`
- [I] `doc/state-tracking/features/archive/3.1.4-progress-reporting-implementation-state.md`
- [I] `doc/state-tracking/features/archive/3.1.5-error-reporting-implementation-state.md`
- [I] `doc/state-tracking/features/archive/4.1.1-test-framework-implementation-state.md`
- [I] `doc/state-tracking/features/archive/4.1.2-unit-tests-implementation-state.md`
- [I] `doc/state-tracking/features/archive/4.1.3-integration-tests-implementation-state.md`
- [I] `doc/state-tracking/features/archive/4.1.4-parser-tests-implementation-state.md`
- [I] `doc/state-tracking/features/archive/4.1.5-performance-tests-implementation-state.md`
- [I] `doc/state-tracking/features/archive/4.1.6-test-fixtures-implementation-state.md`
- [I] `doc/state-tracking/features/archive/4.1.7-test-utilities-implementation-state.md`
- [I] `doc/state-tracking/features/archive/5.1.3-code-quality-checks-implementation-state.md`
- [I] `doc/state-tracking/features/archive/5.1.4-coverage-reporting-implementation-state.md`
- [I] `doc/state-tracking/features/archive/5.1.6-package-building-implementation-state.md`

## 12. Permanent State Files (2 files)

- [F] `doc/state-tracking/permanent/bug-tracking.md` — Clean
- [U] `doc/state-tracking/permanent/technical-debt-tracking.md` — L126,147: bare `linkwatcher/` in TD097/TD108 Target Area updated; L56,64-68,254: [B] backtick `:line_number` refs in resolved section (PD-BUG-093)

## 13. Refactoring Plans — Active (2 files)

- [U] `doc/refactoring/plans/extract-shared-structured-data-tree-walk-logic-from-yaml.md` — L11,17: `target_area` updated to `src/linkwatcher/parsers`
- [F] `doc/refactoring/plans/wire-parser-enable-disable-config-flags-into-linkparser-runtime.md` — Clean

## 14. Refactoring — Other (1 file)

- [F] `doc/refactoring/README.md` — Clean

## 15. Refactoring Plans — Archive (107 files)

All archived/historical — completed refactoring work. Some have `target_area: linkwatcher/...` in frontmatter; these are historical records of where the work was done at the time. No update needed.

- [I] All 107 files — archived, historical records of completed refactoring work

## 16. Validation Reports (40+ files)

All clean — LinkWatcher already updated all references to `src/linkwatcher/`. No stale `linkwatcher/` remains after filtering out `src/linkwatcher/`.

- [I] All 40+ validation report files — historical validation snapshots, already clean

## 17. Process Framework Files (7 files)

- [F] `process-framework/guides/02-design/integration-narrative-customization-guide.md` — Clean
- [F] `process-framework/guides/03-testing/performance-and-e2e-test-scoping-guide.md` — Clean
- [F] `process-framework/guides/06-maintenance/code-refactoring-task-usage-guide.md` — Clean
- [F] `process-framework/scripts/file-creation/06-maintenance/New-RefactoringPlan.ps1` — L75: `.EXAMPLE` block, illustrative text
- [F] `process-framework/scripts/update/Update-TechDebt.ps1` — Clean
- [F] `process-framework/tasks/03-testing/test-specification-creation-task.md` — Clean
- [F] `process-framework/tasks/05-validation/ai-agent-continuity-validation.md` — L48: display label text, hyperlink already correct

## 18. Test Files (9 files)

- [F] `test/audits/core-features/audit-report-2-1-1-test-json.md` — Clean
- [F] `test/audits/core-features/audit-report-2-1-1-test-markdown.md` — Clean
- [F] `test/audits/core-features/audit-report-2-1-1-test-parser.md` — Clean
- [F] `test/audits/core-features/audit-report-2-1-1-test-python.md` — Clean
- [F] `test/audits/core-features/audit-report-2-1-1-test-yaml.md` — Clean
- [F] `test/audits/core-features/audit-report-6-1-1-test-validator.md` — Clean
- [F] `test/audits/foundation/audit-report-0-1-3-test-config.md` — Clean
- [F] `test/automated/conftest.py` — L19: comment listing dir names to avoid in test strings
- [B] `test/state-tracking/permanent/test-tracking.md` — L107: coverage notation (PD-BUG-093)

## 19. Process Framework Local (14 files)

- [F] `process-framework-local/feedback/archive/2026-02/.../20260218-110608-PF-TSK-064-feedback.md` — L101: historical narrative
- [F] `process-framework-local/feedback/archive/2026-03/.../20260302-234247-PF-TSK-007-feedback.md` — Clean
- [F] `process-framework-local/feedback/archive/2026-03/.../20260326-112131-PF-TSK-007-feedback.md` — L82: historical heading
- [F] `process-framework-local/feedback/archive/2026-03/.../20260327-230036-PF-TSK-022-feedback.md` — Clean
- [F] `process-framework-local/feedback/archive/2026-04/.../20260403-114501-PF-TSK-030-feedback.md` — L199: contrast example
- [F] `process-framework-local/feedback/archive/2026-04/.../20260408-134931-PF-TSK-010-feedback.md` — L206: classification heuristic
- [F] `process-framework-local/feedback/reviews/tools-review-20260408-132512.md` — L266: classification heuristic
- [F] `process-framework-local/proposals/old/structure-change-move-source-code-to-src-layout-proposal.md` — L26,50,56: before/after tree diagrams
- [F] `process-framework-local/state-tracking/permanent/process-improvement-tracking.md` — L411,496,498,1300,1473,1482: classification heuristics
- [F] `process-framework-local/state-tracking/temporary/old/enhancement-duplicate-session-prevention.md` — Clean
- [F] `process-framework-local/state-tracking/temporary/old/enhancement-powershell-parser.md` — Clean
- [F] `process-framework-local/state-tracking/temporary/old/retrospective-master-state.md` — L154,482: archived state file
- [F] `process-framework-local/state-tracking/temporary/old/temp-section5-6-restructure.md` — Clean
- [F] `process-framework-local/state-tracking/temporary/structure-change-move-source-code-to-src-layout.md` — Our own state file, narrative text

## 20. Dev Script (1 file)

- [U] `dev.bat` — L82-95: flake8/black/isort/mypy paths updated to `src/linkwatcher`

## 21. Additional files found during review

- [U] `.linkwatcher-ignore` — L133,174: suppression rule path updated
- [U] `deployment/install_global.py` — L131-134: core_dirs updated to tuple mapping for src layout
- [U] 17 test .py files — Python imports had `src.src.linkwatcher` (PD-BUG-094: double-prefix), fixed to `linkwatcher`
