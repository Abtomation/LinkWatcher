# Code Inventory Section Update Instructions

## Issue Identified

The "Files Used by This Feature" section was ambiguous - sometimes documenting:
- Files THIS feature imports (direct dependencies)
- Files that import THIS feature (reverse dependencies)

This caused **inconsistent documentation** across feature implementation state files.

## Solution

Split into **two clearly labeled sections**:

1. **Files This Feature Imports (Direct Dependencies)**
   - What this feature needs to function
   - All `import` statements FROM this feature's code

2. **Files That Depend On This Feature (Reverse Dependencies)**
   - Which files USE/IMPORT this feature
   - For impact analysis when modifying

## Files Updated

✅ **Template**: [feature-implementation-state-template.md](../../../templates/templates/feature-implementation-state-template.md)
✅ **Guide**: [feature-implementation-state-tracking-guide.md](../../../guides/guides/feature-implementation-state-tracking-guide.md)

## Files Requiring Update

All 42 existing feature implementation state files in this directory need the section header changed:

### Current Header (Ambiguous):
```markdown
### Files Used by This Feature

| File Path | How Used | Methods/APIs Used | Notes   |
| --------- | -------- | ----------------- | ------- |
```

### Required Changes:

**Add BEFORE the table:**
```markdown
### Files This Feature Imports (Direct Dependencies)

> **Purpose**: Document which files THIS feature imports/depends on. This shows what this feature needs to function.
>
> **What to list**: All `import` statements and file references FROM this feature's code (internal and external packages).

| File Path | How Used | Methods/APIs Used | Notes   |
| --------- | -------- | ----------------- | ------- |
| [List ALL imports from source files] | | | |

### Files That Depend On This Feature (Reverse Dependencies)

> **Purpose**: Document which files IMPORT or USE this feature. This enables impact analysis - when modifying this feature, you know which files to check/test.
>
> **What to list**: Files that have `import` statements or references TO this feature's files (not files this feature imports FROM).

| File Path | How They Use This Feature | Methods/APIs Used | Notes   |
| --------- | ------------------------- | ----------------- | ------- |
| [List files that import THIS feature] | | | |
```

## Action Required

Each feature implementation state file needs:

1. **Re-analysis** of the source code to correctly populate:
   - **Direct Dependencies**: Read the feature's source files, extract ALL import statements
   - **Reverse Dependencies**: Search codebase for which files import this feature's files

2. **Verification**: Cross-check that:
   - Every import statement is documented
   - No files listed in wrong direction
   - External packages (like `colorama`, `yaml`) are included

## List of Files to Update

All 42 files in `doc/process-framework/state-tracking/features/`:

- ../../features/0.1.1-core-architecture-implementation-state.md
- ../../features/0.1.2-data-models-implementation-state.md
- ../../features/0.1.3-in-memory-database-implementation-state.md
- ../../features/0.1.4-configuration-system-implementation-state.md
- ../../features/0.1.5-path-utilities-implementation-state.md
- ../../features/1.1.1-watchdog-integration-implementation-state.md
- ../../features/1.1.2-event-handler-implementation-state.md
- ../../features/1.1.3-initial-scan-implementation-state.md
- ../../features/1.1.4-file-filtering-implementation-state.md
- ../../features/1.1.5-real-time-monitoring-implementation-state.md
- ../../features/2.1.1-parser-framework-implementation-state.md
- ../../features/2.1.2-markdown-parser-implementation-state.md
- ../../features/2.1.3-yaml-parser-implementation-state.md
- ../../features/2.1.4-json-parser-implementation-state.md
- ../../features/2.1.5-python-parser-implementation-state.md
- ../../features/2.1.6-dart-parser-implementation-state.md
- ../../features/2.1.7-generic-parser-implementation-state.md
- ../../features/2.2.1-link-updater-implementation-state.md
- ../../features/2.2.2-relative-path-calculation-implementation-state.md
- ../../features/2.2.3-anchor-preservation-implementation-state.md
- ../../features/2.2.4-dry-run-mode-implementation-state.md
- ../../features/2.2.5-backup-creation-implementation-state.md
- ../../features/3.1.1-logging-framework-implementation-state.md
- ../../features/3.1.2-colored-console-output-implementation-state.md
- ../../features/3.1.3-statistics-tracking-implementation-state.md
- ../../features/3.1.4-progress-reporting-implementation-state.md
- ../../features/3.1.5-error-reporting-implementation-state.md
- ../../features/4.1.1-test-framework-implementation-state.md
- ../../features/4.1.2-unit-tests-implementation-state.md
- ../../features/4.1.3-integration-tests-implementation-state.md
- ../../features/4.1.4-parser-tests-implementation-state.md
- ../../features/4.1.5-performance-tests-implementation-state.md
- ../../features/4.1.6-test-fixtures-implementation-state.md
- ../../features/4.1.7-test-utilities-implementation-state.md
- ../../features/4.1.8-test-documentation-implementation-state.md
- ../../features/5.1.1-github-actions-ci-implementation-state.md
- ../../features/5.1.2-test-automation-implementation-state.md
- ../../features/5.1.3-code-quality-checks-implementation-state.md
- ../../features/5.1.4-coverage-reporting-implementation-state.md
- ../../features/5.1.5-pre-commit-hooks-implementation-state.md
- ../../features/5.1.6-package-building-implementation-state.md
- ../../features/5.1.7-windows-dev-scripts-implementation-state.md

## Priority Files (High Connectivity)

Start with these files as they have the most dependencies:

1. **../../features/0.1.1-core-architecture-implementation-state.md** (../../features/service.py, main.py)
2. **../../features/0.1.3-in-memory-database-implementation-state.md** (database.py)
3. **../../features/1.1.2-event-handler-implementation-state.md** (../../features/handler.py)
4. **../../features/2.1.1-parser-framework-implementation-state.md** (parser.py)
5. **../../features/2.2.1-link-updater-implementation-state.md** (../../features/updater.py)
6. **../../features/3.1.1-logging-framework-implementation-state.md** (logging.py)

## Progress (Sessions 2026-02-18)

### ✅ Completed: 42 / 42 files (100%) — ALL DONE

**High-Connectivity Files (Critical for Impact Analysis):**
1. ✅ **../../features/0.1.1-core-architecture-implementation-state.md** (../../features/service.py, main.py) - 18 reverse dependencies
2. ✅ **../../features/0.1.2-data-models-implementation-state.md** (models.py) - 12 reverse dependencies
3. ✅ **../../features/0.1.3-in-memory-database-implementation-state.md** (database.py) - 3 reverse dependencies
4. ✅ **../../features/1.1.2-event-handler-implementation-state.md** (../../features/handler.py) - 3 reverse dependencies
5. ✅ **../../features/2.1.1-parser-framework-implementation-state.md** (parser.py) - 13 reverse dependencies
6. ✅ **../../features/2.2.1-link-updater-implementation-state.md** (../../features/updater.py) - 10 reverse dependencies
7. ✅ **../../features/3.1.1-logging-framework-implementation-state.md** (logging.py) - 11 reverse dependencies

**Foundation Features (0.x.x):**
8. ✅ **../../features/0.1.4-configuration-system-implementation-state.md** (config package) - 6 reverse dependencies
9. ✅ **../../features/0.1.5-path-utilities-implementation-state.md** (utils.py) - 17 reverse dependencies

**Parser Features (2.1.x):**
10. ✅ **../../features/2.1.2-markdown-parser-implementation-state.md** (markdown.py) - 5 reverse dependencies
11. ✅ **../../features/2.1.3-yaml-parser-implementation-state.md** (yaml_parser.py) - 3 reverse dependencies
12. ✅ **../../features/2.1.4-json-parser-implementation-state.md** (json_parser.py) - 3 reverse dependencies
13. ✅ **../../features/2.1.5-python-parser-implementation-state.md** (python.py) - 4 reverse dependencies
14. ✅ **../../features/2.1.6-dart-parser-implementation-state.md** (dart.py) - 3 reverse dependencies
15. ✅ **../../features/2.1.7-generic-parser-implementation-state.md** (generic.py) - 6 reverse dependencies (includes fallback usage)

**File Watching Features (1.x.x):**
16. ✅ **../../features/1.1.1-watchdog-integration-implementation-state.md** (watchdog integration in ../../features/service.py)
17. ✅ **../../features/1.1.3-initial-scan-implementation-state.md** (_initial_scan method in ../../features/service.py)
18. ✅ **../../features/1.1.4-file-filtering-implementation-state.md** (filtering in ../../features/handler.py and utils.py)
19. ✅ **../../features/1.1.5-real-time-monitoring-implementation-state.md** (monitoring orchestration in ../../features/service.py)

**Link Updater Features (2.2.x):**
20. ✅ **../../features/2.2.2-relative-path-calculation-implementation-state.md** (path calculation in ../../features/updater.py)
21. ✅ **../../features/2.2.3-anchor-preservation-implementation-state.md** (anchor handling in ../../features/updater.py)
22. ✅ **../../features/2.2.4-dry-run-mode-implementation-state.md** (dry-run flag in ../../features/updater.py and ../../features/service.py)
23. ✅ **../../features/2.2.5-backup-creation-implementation-state.md** (backup logic in ../../features/updater.py)

**Logging Features (3.1.x):**
24. ✅ **../../features/3.1.2-colored-console-output-implementation-state.md** (ColoredFormatter in logging.py)
25. ✅ **../../features/3.1.3-statistics-tracking-implementation-state.md** (statistics in ../../features/service.py)
26. ✅ **../../features/3.1.4-progress-reporting-implementation-state.md** (progress reporting in ../../features/service.py and logging.py)
27. ✅ **../../features/3.1.5-error-reporting-implementation-state.md** (error handling in logging.py)

**Test Infrastructure (4.1.x):**
28. ✅ **../../features/4.1.1-test-framework-implementation-state.md** (run_tests.py, pytest.ini, conftest.py)
29. ✅ **../../features/4.1.2-unit-tests-implementation-state.md** (tests/unit/)
30. ✅ **../../features/4.1.3-integration-tests-implementation-state.md** (tests/integration/)
31. ✅ **../../features/4.1.4-parser-tests-implementation-state.md** (tests/parsers/)
32. ✅ **../../features/4.1.5-performance-tests-implementation-state.md** (tests/performance/)
33. ✅ **../../features/4.1.6-test-fixtures-implementation-state.md** (tests/conftest.py fixtures)
34. ✅ **../../features/4.1.7-test-utilities-implementation-state.md** (tests/test_config.py, scripts/cleanup_test.py)
35. ✅ **../../features/4.1.8-test-documentation-implementation-state.md** (tests/README.md, TEST_PLAN.md, etc.)

**CI/CD Features (5.1.x):**
36. ✅ **../../features/5.1.1-github-actions-ci-implementation-state.md** (.github/workflows/ci.yml)
37. ✅ **../../features/5.1.2-test-automation-implementation-state.md** (scripts/__init__.py; CI test orchestration)
38. ✅ **../../features/5.1.3-code-quality-checks-implementation-state.md** (pyproject.toml quality tool config)
39. ✅ **../../features/5.1.4-coverage-reporting-implementation-state.md** (pyproject.toml coverage config, Codecov)
40. ✅ **../../features/5.1.5-pre-commit-hooks-implementation-state.md** (.pre-commit-config.yaml)
41. ✅ **../../features/5.1.6-package-building-implementation-state.md** (pyproject.toml, setup.py, deployment/)
42. ✅ **../../features/5.1.7-windows-dev-scripts-implementation-state.md** (dev.bat, Makefile)

## Timeline

- **Session 1 (2026-02-18)**: Completed 28 files (7 high-connectivity + 2 foundation + 6 parsers + 4 file watching + 4 link updater + 4 logging)
- **Session 2 (2026-02-18)**: Completed remaining 14 files (8 test infrastructure + 6 CI/CD features)
- **✅ COMPLETE**: All 42 feature implementation state files now have accurate dependency documentation
