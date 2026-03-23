---
id: TE-E2E-016
type: E2E Acceptance Test Case
group: TE-E2G-007
feature_ids: ["1.1.1, 0.1.2, 2.2.1"]
workflow: WF-004
priority: P2
execution_mode: scripted
estimated_duration: 3 minutes
source: Cross-Cutting Spec PF-TSP-044 S-013
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-016 Two Files Moved Rapidly

## Preconditions

- [ ] LinkWatcher is running and monitoring the workspace project directory
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group rapid-sequential-moves`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] The `project/src/` directory does NOT exist yet (created by the test action)

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/index.md` | File referencing both targets | Links to `lib/utils.md` and `lib/helpers.md` |
| `project/lib/utils.md` | First file to be moved | `# Utils` with description |
| `project/lib/helpers.md` | Second file to be moved | `# Helpers` with description |

## Steps

1. **Start LinkWatcher**: Ensure LinkWatcher is running and monitoring the workspace project directory
   - **Tool**: Command Line
   - **Target**: `python main.py` pointed at the workspace

2. **Wait for initial scan**: Allow LinkWatcher to complete its startup scan
   - **Duration**: Wait 3-5 seconds
   - **Observe**: Log output confirming initial scan is complete

3. **Move first file**: Move `project/lib/utils.md` to `project/src/utils.md`
   - **Tool**: Command Line / File Explorer
   - **Target**: `project/lib/utils.md` -> `project/src/utils.md`

4. **Move second file rapidly**: Move `project/lib/helpers.md` to `project/src/helpers.md` within 200ms of the first move
   - **Tool**: Command Line / File Explorer
   - **Target**: `project/lib/helpers.md` -> `project/src/helpers.md`

5. **Wait for processing**: Allow LinkWatcher to detect and process both moves
   - **Duration**: Wait 3-5 seconds for all file system events to process
   - **Observe**: Log output showing detection of both moves and link updates

6. **Verify results**: Check that `index.md` has both links updated
   - **Tool**: Text editor
   - **Target**: `project/index.md`

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates `project/src/` directory, then moves `project/lib/utils.md` and `project/lib/helpers.md` to `project/src/` with only 200ms between moves

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `index.md` | Utils link | `[Utils](lib/utils.md)` | `[Utils](src/utils.md)` |
| `index.md` | Helpers link | `[Helpers](lib/helpers.md)` | `[Helpers](src/helpers.md)` |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows detection of both file moves (utils.md and helpers.md)
- LinkWatcher log shows link updates in `index.md` for both references
- Both moves are processed without race conditions or missed events

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-016` — compares workspace against `expected/`
- [ ] **Log check**: Check application log for detection of both moves and both link updates

## Pass Criteria

- [ ] `index.md` contains `[Utils](src/utils.md)` (first link updated)
- [ ] `index.md` contains `[Helpers](src/helpers.md)` (second link updated)
- [ ] `src/utils.md` exists with original content
- [ ] `src/helpers.md` exists with original content
- [ ] No errors or warnings in application log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Take screenshots or save log output as evidence

## Notes

- The 200ms delay between moves tests LinkWatcher's ability to handle rapid sequential file system events without losing any.
- If only one of the two links is updated, this indicates a race condition or event coalescing issue in the file watcher.
