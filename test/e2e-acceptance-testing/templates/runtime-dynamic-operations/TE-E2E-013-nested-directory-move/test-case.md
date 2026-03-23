---
id: TE-E2E-013
type: E2E Acceptance Test Case
group: TE-E2G-005
feature_ids: ["1.1.1", "0.1.2", "2.1.1", "2.2.1"]
workflow: WF-002
priority: P1
execution_mode: scripted
estimated_duration: 3 minutes
source: Cross-Cutting Spec PF-TSP-044, Scenario S-009
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-013 Nested Directory Move

## Preconditions

- [ ] LinkWatcher is **stopped** before workspace setup
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group runtime-dynamic-operations -Clean`
- [ ] LinkWatcher is **started** after setup (fresh scan indexes README.md references)
- [ ] Wait 5 seconds for initial scan to complete
- [ ] The directory `modules/` does NOT exist yet in the workspace project (it will be created by the test)

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/README.md` | Markdown file referencing files at multiple nesting levels | Contains links to `modules/core/engine.py`, `modules/core/config.yaml`, and `modules/plugins/auth.py` |

## Steps

1. **Create the nested directory structure with files**: Create `modules/` directory with subdirectories `core/` and `plugins/`, each containing referenced files
   - **Tool**: Command Line or File Explorer
   - **Target**: `project/modules/core/engine.py`, `project/modules/core/config.yaml`, `project/modules/plugins/auth.py`

2. **Wait for LinkWatcher to scan**: Allow time for LW to detect and index all new files
   - **Duration**: Wait 5 seconds
   - **Observe**: LinkWatcher log should show detection of all 3 new files

3. **Move the top-level directory**: Move `project/modules/` to `project/lib/`
   - **Tool**: File Explorer (drag and drop) or Command Line
   - **Target**: `project/modules/` → `project/lib/`

4. **Wait for LinkWatcher to process**: Allow time for directory move detection and reference updates
   - **Duration**: Wait 5–10 seconds
   - **Observe**: LinkWatcher log should show directory move detection and reference updates for all contained files at both nesting levels

5. **Verify references updated**: Check that README.md now points to files under `lib/`
   - **Tool**: Text editor
   - **Target**: Open `README.md` and check all link targets

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates `project/modules/` with nested subdirectories `core/` and `plugins/` containing test files, waits 5 seconds, then moves the entire `modules/` directory to `project/lib/`

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `README.md` | Line 3 | `[Engine](modules/core/engine.py)` | `[Engine](lib/core/engine.py)` |
| `README.md` | Line 5 | `[Config](modules/core/config.yaml)` | `[Config](lib/core/config.yaml)` |
| `README.md` | Line 7 | `[Auth Plugin](modules/plugins/auth.py)` | `[Auth Plugin](lib/plugins/auth.py)` |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows detection of new files in `modules/core/` and `modules/plugins/`
- LinkWatcher log shows directory move detection from `modules/` to `lib/`
- LinkWatcher log shows updates to `README.md` for all 3 contained files across both subdirectories
- No errors or warnings in LinkWatcher log

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-013` — compares workspace against `expected/`
- [ ] **Log check**: Check LinkWatcher log for directory move detection and update messages without errors

## Pass Criteria

- [ ] All 3 references in README.md updated from `modules/` paths to `lib/` paths
- [ ] `engine.py` and `config.yaml` exist at `lib/core/` with original content
- [ ] `auth.py` exists at `lib/plugins/` with original content
- [ ] `Verify-TestResult.ps1` reports all files match expected state
- [ ] No errors or warnings in LinkWatcher log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Save LinkWatcher log output as evidence

## Notes

- This test extends S-008 (TE-E2E-009) by verifying that directory move detection works with nested subdirectories, not just flat directories
- Tests that LinkWatcher's directory move detection correctly handles files at multiple nesting levels within the moved directory
- The nested directory and all contents are created at runtime, verifying dynamic file tracking works for deep directory structures
