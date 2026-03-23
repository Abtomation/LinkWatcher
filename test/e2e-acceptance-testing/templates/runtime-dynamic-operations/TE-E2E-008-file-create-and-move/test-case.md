---
id: TE-E2E-008
type: E2E Acceptance Test Case
group: TE-E2G-005
feature_ids: ["1.1.1", "2.1.1", "2.2.1"]
workflow: WF-001
priority: P1
execution_mode: scripted
estimated_duration: 3 minutes
source: Cross-Cutting Spec PF-TSP-044
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-008 File Create and Move

## Preconditions

- [ ] LinkWatcher is **stopped** before workspace setup, then **started** after setup (fresh scan)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group runtime-dynamic-operations`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] The file `docs/report.md` does NOT exist yet in the workspace project (it will be created by the test)

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/README.md` | Markdown file referencing a not-yet-created file | Contains `[Report](docs/report.md)` link |
| `project/index.md` | Second file referencing the same not-yet-created file | Contains `[See the report](docs/report.md)` link |

## Steps

1. **Create the target file**: Create `docs/report.md` inside the project directory
   - **Tool**: Command Line or File Explorer
   - **Target**: `project/docs/report.md` with content `# Report\n\nThis is the report.`

2. **Wait for LinkWatcher to scan**: Allow time for LW to detect the new file and index it
   - **Duration**: Wait 5 seconds
   - **Observe**: LinkWatcher log should show detection of the new file

3. **Move the file**: Move `project/docs/report.md` to `project/archive/report.md`
   - **Tool**: File Explorer (drag and drop) or Command Line
   - **Target**: `project/docs/report.md` → `project/archive/report.md`

4. **Wait for LinkWatcher to process**: Allow time for move detection and reference updates
   - **Duration**: Wait 5–10 seconds
   - **Observe**: LinkWatcher log should show move detection and reference updates

5. **Verify references updated**: Check that README.md and index.md now point to the new location
   - **Tool**: Text editor
   - **Target**: Open `README.md` and `index.md` and check link targets

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates `project/docs/report.md`, waits 5 seconds, then moves it to `project/archive/report.md`

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `README.md` | Line 3 | `[Report](docs/report.md)` | `[Report](archive/report.md)` |
| `index.md` | Line 3 | `[See the report](docs/report.md)` | `[See the report](archive/report.md)` |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows detection of new file `docs/report.md`
- LinkWatcher log shows move detection from `docs/report.md` to `archive/report.md`
- LinkWatcher log shows updates to `README.md` and `index.md`
- No errors or warnings in LinkWatcher log

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-008` — compares workspace against `expected/`
- [ ] **Log check**: Check LinkWatcher log for move detection and update messages without errors

## Pass Criteria

- [ ] Both references to `docs/report.md` updated to `archive/report.md`
- [ ] `report.md` exists at `archive/report.md` with original content
- [ ] `Verify-TestResult.ps1` reports all files match expected state
- [ ] No errors or warnings in LinkWatcher log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Save LinkWatcher log output as evidence

## Notes

- This test verifies that files created AFTER LinkWatcher starts monitoring are properly tracked and their moves are detected
- The key difference from TE-E2E-001–007 is that the moved file does not exist in the initial project state
- The 5-second wait after file creation ensures LW has time to scan and index the new file before the move
