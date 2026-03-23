---
id: TE-E2E-010
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

# Test Case: TE-E2E-010 File Create and Rename

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

3. **Rename the file**: Rename `project/docs/report.md` to `project/docs/summary.md` (same directory, different name)
   - **Tool**: File Explorer (right-click → Rename) or Command Line
   - **Target**: `project/docs/report.md` → `project/docs/summary.md`

4. **Wait for LinkWatcher to process**: Allow time for rename detection and reference updates
   - **Duration**: Wait 5–10 seconds
   - **Observe**: LinkWatcher log should show rename detection and reference updates

5. **Verify references updated**: Check that README.md and index.md now point to the new name
   - **Tool**: Text editor
   - **Target**: Open `README.md` and `index.md` and check link targets

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates `project/docs/report.md`, waits 5 seconds, then renames it to `project/docs/summary.md`

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `README.md` | Line 3 | `[Report](docs/report.md)` | `[Report](docs/summary.md)` |
| `index.md` | Line 3 | `[See the report](docs/report.md)` | `[See the report](docs/summary.md)` |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows detection of new file `docs/report.md`
- LinkWatcher log shows rename detection from `docs/report.md` to `docs/summary.md`
- LinkWatcher log shows updates to `README.md` and `index.md`
- No errors or warnings in LinkWatcher log

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-010` — compares workspace against `expected/`
- [ ] **Log check**: Check LinkWatcher log for rename detection and update messages without errors

## Pass Criteria

- [ ] Both references to `docs/report.md` updated to `docs/summary.md`
- [ ] `summary.md` exists at `docs/summary.md` with original content
- [ ] `report.md` no longer exists at `docs/report.md`
- [ ] `Verify-TestResult.ps1` reports all files match expected state
- [ ] No errors or warnings in LinkWatcher log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Save LinkWatcher log output as evidence

## Notes

- This tests in-place rename (same directory, different filename) as opposed to a cross-directory move
- Renames generate delete+create events at the file system level; LinkWatcher's move detector must pair them correctly
- The file stays in the same directory, so only the filename portion of references should change
