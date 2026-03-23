---
id: TE-E2G-004
type: E2E Acceptance Test Group
feature_ids: ["1.1.1", "2.1.1", "2.2.1"]
workflow: WF-001
test_cases_count: 3
estimated_duration: 10 minutes
created: 2026-03-18
updated: 2026-03-18
---

# Master Test: yaml-json-python-parser-scenarios

## Purpose

Quick validation sequence covering YAML, JSON, and Python parser scenarios for single file moves. Tests that LinkWatcher correctly detects file moves and updates references in all three formats. Run this FIRST after a code change affecting any parser. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

- [ ] LinkWatcher is running and monitoring the workspace directory
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group yaml-json-python-parser-scenarios`
- [ ] Workspace contains pristine copies of all test fixtures
- [ ] No `moved/` or `core/` subdirectories exist in any test case workspace

## Quick Validation Sequence

1. **YAML: Move file referenced in YAML configs**
   - Action: Move `TE-E2E-005/.../project/data/settings.conf` to `project/moved/settings.conf`
   - Tool: File Explorer or `run.ps1`
   - Target: `TE-E2E-005-yaml-link-update-on-file-move/`
   - Expected: `config.yaml` and `pipeline.yaml` update all 5 references from `data/settings.conf` to `moved/settings.conf`; references to `data/schema.sql` unchanged

2. **JSON: Move file referenced in JSON configs**
   - Action: Move `TE-E2E-006/.../project/src/utils.js` to `project/moved/utils.js`
   - Tool: File Explorer or `run.ps1`
   - Target: `TE-E2E-006-json-link-update-on-file-move/`
   - Expected: `package.json` and `tsconfig.json` update all 5 references from `src/utils.js` to `moved/utils.js`; references to `src/index.js` unchanged

3. **Python: Move module referenced via imports and quoted paths**
   - Action: Move `TE-E2E-007/.../project/utils/helpers.py` to `project/core/helpers.py`
   - Tool: File Explorer or `run.ps1`
   - Target: `TE-E2E-007-python-import-update-on-file-move/`
   - Expected: `app/main.py` and `app/runner.py` update import statements (`utils.helpers` → `core.helpers`) and quoted paths (`utils/helpers.py` → `core/helpers.py`); references to `utils/__init__.py` unchanged

## Pass Criteria

- [ ] All 3 steps above produce their expected results
- [ ] Non-moved file references remain unchanged in all test cases
- [ ] Updated files remain valid in their respective formats (YAML, JSON, Python)
- [ ] No errors or warnings in LinkWatcher log
- [ ] Run `Verify-TestResult.ps1 -Group yaml-json-python-parser-scenarios` shows all green

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-005 | [TE-E2E-005-yaml-link-update-on-file-move/test-case.md](TE-E2E-005-yaml-link-update-on-file-move/test-case.md) | Move a file referenced in YAML configs and verify all YAML references updated |
| TE-E2E-006 | [TE-E2E-006-json-link-update-on-file-move/test-case.md](TE-E2E-006-json-link-update-on-file-move/test-case.md) | Move a file referenced in JSON configs and verify all JSON references updated |
| TE-E2E-007 | [TE-E2E-007-python-import-update-on-file-move/test-case.md](TE-E2E-007-python-import-update-on-file-move/test-case.md) | Move a Python module and verify import statements and quoted path references updated |

## Notes

- Each test case uses a different non-moved file to verify selectivity (only moved file references change)
- YAML test exercises: simple values, nested values, arrays, deep nesting, anchors/aliases
- JSON test exercises: simple string values, nested objects, arrays, mixed arrays with objects
- Python test exercises: from/import statements, quoted paths, comment references
