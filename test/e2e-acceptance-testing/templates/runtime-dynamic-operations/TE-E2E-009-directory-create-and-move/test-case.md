---
id: TE-E2E-009
type: E2E Acceptance Test Case
group: TE-E2G-005
feature_ids: ["1.1.1", "0.1.2", "2.1.1", "2.2.1"]
workflow: WF-002
priority: P1
execution_mode: scripted
estimated_duration: 3 minutes
source: Cross-Cutting Spec PF-TSP-044, Scenario S-008
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-009 Directory Create and Move

## Preconditions

- [ ] LinkWatcher is **stopped** before workspace setup, then **started** after setup (fresh scan)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group runtime-dynamic-operations`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] The directory `utils/` does NOT exist yet in the workspace project (it will be created by the test)

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/README.md` | Markdown file referencing files inside a not-yet-created directory | Contains links to `utils/helper.py` and `utils/config.yaml` |

## Steps

1. **Create the target directory with files**: Create `utils/` directory with `helper.py` and `config.yaml` inside the project
   - **Tool**: Command Line or File Explorer
   - **Target**: `project/utils/helper.py` and `project/utils/config.yaml`

2. **Wait for LinkWatcher to scan**: Allow time for LW to detect the new files and index them
   - **Duration**: Wait 5 seconds
   - **Observe**: LinkWatcher log should show detection of the new files

3. **Move the directory**: Move `project/utils/` to `project/lib/`
   - **Tool**: File Explorer (drag and drop) or Command Line
   - **Target**: `project/utils/` → `project/lib/`

4. **Wait for LinkWatcher to process**: Allow time for directory move detection and reference updates
   - **Duration**: Wait 5–10 seconds
   - **Observe**: LinkWatcher log should show directory move detection and reference updates for all contained files

5. **Verify references updated**: Check that README.md now points to files in `lib`
   - **Tool**: Text editor
   - **Target**: Open `README.md` and check link targets

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates `project/utils/` with `helper.py` and `config.yaml`, waits 5 seconds, then moves the entire directory to `project/lib/`

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `README.md` | Line 3 | `[Helper](utils/helper.py)` | `[Helper](lib/helper.py)` |
| `README.md` | Line 5 | `[Config](utils/config.yaml)` | `[Config](lib/config.yaml)` |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows detection of new files in `utils/`
- LinkWatcher log shows directory move detection from `utils/` to `lib`
- LinkWatcher log shows updates to `README.md` for both contained files
- No errors or warnings in LinkWatcher log

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-009` — compares workspace against `expected/`
- [ ] **Log check**: Check LinkWatcher log for directory move detection and update messages without errors

## Pass Criteria

- [ ] Both references in README.md updated from `utils/` paths to `lib` paths
- [ ] `helper.py` and `config.yaml` exist at `lib` with original content
- [ ] `Verify-TestResult.ps1` reports all files match expected state
- [ ] No errors or warnings in LinkWatcher log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Save LinkWatcher log output as evidence

## Notes

- This test covers WF-002 (Directory Move) which has zero E2E coverage prior to this test case
- Tests that LinkWatcher's directory move detection (dir_move_detector.py) correctly identifies all contained files and updates references for each
- The directory and its contents are created at runtime, verifying dynamic file tracking works for directory operations
