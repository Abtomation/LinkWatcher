---
id: TE-E2E-006
type: E2E Acceptance Test Case
group: TE-E2G-004
feature_ids: ["1.1.1", "2.1.1", "2.2.1"]
workflow: WF-001
priority: P1
execution_mode: scripted
estimated_duration: 3 minutes
source: Cross-Cutting Spec PF-TSP-044, Scenario S-004
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-006 JSON Link Update on File Move

## Preconditions

- [ ] LinkWatcher is running and monitoring the workspace directory
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group yaml-json-python-parser-scenarios`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] The `moved/` subdirectory does NOT exist yet in the workspace project

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/package.json` | Main JSON config referencing the target file | Simple string value, nested object value, and array references to `src/utils.js` |
| `project/tsconfig.json` | Secondary JSON config with different nesting patterns | Deep-nested and mixed-array references to `src/utils.js` |
| `project/src/utils.js` | Target file that will be moved | Simple JavaScript utility |
| `project/src/index.js` | Non-moved file also referenced in JSON | Verifies only moved file references change |

## Steps

1. **Create destination directory**: Create a `moved/` directory inside `project/`
   - **Tool**: File Explorer or Command Line
   - **Target**: `project/moved/`

2. **Move the target file**: Move `project/src/utils.js` into `project/moved/`
   - **Tool**: File Explorer (drag and drop) or Command Line
   - **Target**: `project/src/utils.js` → `project/moved/utils.js`

3. **Wait for LinkWatcher**: Allow time for file system events to be detected and processed
   - **Duration**: Wait 5–10 seconds
   - **Observe**: LinkWatcher log should show detection of the move and reference updates

4. **Verify JSON files updated**: Check that all JSON references to the moved file are updated
   - **Tool**: Text editor (open `package.json` and `tsconfig.json`)
   - **Target**: All paths previously pointing to `src/utils.js` should now point to `moved/utils.js`

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates `project/moved/` directory and moves `project/src/utils.js` to `project/moved/utils.js`

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `package.json` | Line 3 (simple value) | `"main": "src/utils.js"` | `"main": "moved/utils.js"` |
| `package.json` | Line 8 (nested value) | `"entry": "src/utils.js"` | `"entry": "moved/utils.js"` |
| `package.json` | Line 12 (array entry) | `"src/utils.js"` | `"moved/utils.js"` |
| `tsconfig.json` | Line 6 (deep nested) | `"path": "src/utils.js"` | `"path": "moved/utils.js"` |
| `tsconfig.json` | Line 11 (mixed array object) | `"file": "src/utils.js"` | `"file": "moved/utils.js"` |

References to `src/index.js` must remain **unchanged** in both files (it was not moved).

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows detection of `src/utils.js` move
- LinkWatcher log shows updates to `package.json` and `tsconfig.json`
- No errors or warnings in LinkWatcher log

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-006` — compares workspace against `expected/`
- [ ] **Log check**: Check LinkWatcher log for move detection and update messages without errors

## Pass Criteria

- [ ] All 5 JSON references to `src/utils.js` updated to `moved/utils.js`
- [ ] All references to `src/index.js` remain unchanged
- [ ] JSON files remain valid JSON after updates
- [ ] `Verify-TestResult.ps1` reports all files match expected state
- [ ] No errors or warnings in LinkWatcher log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Save LinkWatcher log output as evidence

## Notes

- Tests simple string values, nested objects, arrays, deep nesting, and mixed arrays with objects
- The JSON parser uses a `claimed` set to correctly track duplicate value line numbers (PD-BUG-013 fix)
- Invalid JSON falls back to the generic parser
