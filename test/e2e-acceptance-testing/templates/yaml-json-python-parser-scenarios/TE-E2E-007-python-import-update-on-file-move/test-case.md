---
id: TE-E2E-007
type: E2E Acceptance Test Case
group: TE-E2G-004
feature_ids: ["1.1.1", "2.1.1", "2.2.1"]
workflow: WF-001
priority: P1
execution_mode: scripted
estimated_duration: 3 minutes
source: Cross-Cutting Spec PF-TSP-044, Scenario S-005
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-007 Python Import Update on File Move

## Preconditions

- [ ] LinkWatcher is running and monitoring the workspace directory
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group yaml-json-python-parser-scenarios`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] The `core/` subdirectory does NOT exist yet in the workspace project

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/app/main.py` | Main Python file referencing the target via imports and quoted paths | `from utils.helpers import ...`, quoted path `"core/helpers.py"`, comment reference |
| `project/app/runner.py` | Secondary Python file with different reference patterns | `import utils.helpers`, quoted config path `"core/helpers.py"` |
| `project/utils/helpers.py` | Target file that will be moved | Simple Python helper functions |
| `project/utils/__init__.py` | Package init (not moved, referenced) | Verifies only moved file references change |

## Steps

1. **Create destination directory**: Create a `core/` directory inside `project/`
   - **Tool**: File Explorer or Command Line
   - **Target**: `project/core/`

2. **Move the target file**: Move `project/utils/helpers.py` into `project/core/`
   - **Tool**: File Explorer (drag and drop) or Command Line
   - **Target**: `project/utils/helpers.py` → `project/core/helpers.py`

3. **Wait for LinkWatcher**: Allow time for file system events to be detected and processed
   - **Duration**: Wait 5–10 seconds
   - **Observe**: LinkWatcher log should show detection of the move and reference updates

4. **Verify Python files updated**: Check that all Python references to the moved file are updated
   - **Tool**: Text editor (open `app/main.py` and `app/runner.py`)
   - **Target**: Import statements and quoted paths previously pointing to `utils/helpers` should now point to `core/helpers`

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates `project/core/` directory and moves `project/utils/helpers.py` to `project/core/helpers.py`

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `app/main.py` | Line 2 (from import) | `from utils.helpers import format_name` | `from core.helpers import format_name` |
| `app/main.py` | Line 5 (quoted path) | `HELPERS_PATH = "core/helpers.py"` | `HELPERS_PATH = "core/helpers.py"` |
| `app/main.py` | Line 6 (comment ref) | `# See core/helpers.py for details` | `# See core/helpers.py for details` |
| `app/runner.py` | Line 1 (import) | `import utils.helpers` | `import core.helpers` |
| `app/runner.py` | Line 4 (quoted path) | `helper_file = "core/helpers.py"` | `helper_file = "core/helpers.py"` |

References to `utils/__init__.py` must remain **unchanged** in both files (it was not moved).

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows detection of `utils/helpers.py` move
- LinkWatcher log shows updates to `app/main.py` and `app/runner.py`
- No errors or warnings in LinkWatcher log

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-007` — compares workspace against `expected/`
- [ ] **Log check**: Check LinkWatcher log for move detection and update messages without errors

## Pass Criteria

- [ ] All import statements referencing `utils.helpers` updated to `core.helpers`
- [ ] All quoted paths referencing `utils/helpers.py` updated to `core/helpers.py`
- [ ] Comment references to `utils/helpers.py` updated to `core/helpers.py`
- [ ] References to `utils/__init__.py` remain unchanged
- [ ] `Verify-TestResult.ps1` reports all files match expected state
- [ ] No errors or warnings in LinkWatcher log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Save LinkWatcher log output as evidence

## Notes

- Tests three Python link types: `python-import` (from/import statements), `python-quoted` (string paths), and `python-comment` (comment references)
- The Python parser converts dot notation imports to slash notation for resolution, then back to dot notation when updating
- Standard library imports (os, sys, json, etc.) are filtered out and never treated as file references
- Only imports starting with known local prefixes (src, lib, app, core, utils, helpers, modules, packages) are considered
