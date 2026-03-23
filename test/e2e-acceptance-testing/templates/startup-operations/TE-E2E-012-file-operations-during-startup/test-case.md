---
id: TE-E2E-012
type: E2E Acceptance Test Case
group: TE-E2G-006
feature_ids: ["0.1.1", "0.1.2", "0.1.3", "1.1.1", "2.1.1", "2.2.1"]
workflow: WF-003
priority: P1
execution_mode: scripted
estimated_duration: 5 minutes
source: Cross-Cutting Spec PF-TSP-044, Scenario S-011
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-012 File Operations During Startup

## Preconditions

- [ ] LinkWatcher is running (it will be stopped and restarted by the test)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group startup-operations`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] The file `settings/config.yaml` exists in the workspace project

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/README.md` | Markdown file referencing the target file | Contains `[Config](settings/config.yaml)` link |
| `project/settings/config.yaml` | Target file that will be moved during startup | Simple YAML configuration content |

## Steps

1. **Stop LinkWatcher**: Kill the running LinkWatcher process
   - **Tool**: Command Line (via lock file PID)
   - **Target**: The LinkWatcher process for this project

2. **Create a new file**: Create `docs/guide.md` in the project with a reference to `settings/config.yaml`
   - **Tool**: Command Line
   - **Target**: `project/docs/guide.md` with content referencing `../settings/config.yaml`

3. **Start LinkWatcher**: Restart LinkWatcher scoped to workspace
   - **Tool**: `LinkWatcher_run/start_linkwatcher_background.ps1 -ProjectRoot <workspace-path>`
   - **Observe**: LinkWatcher begins scanning the workspace

4. **Immediately move the target file**: While LinkWatcher is still starting up/scanning, move `settings/config.yaml` to `config/config.yaml`
   - **Tool**: Command Line
   - **Target**: `project/settings/config.yaml` → `project/config/config.yaml`
   - **Timing**: Execute within 2 seconds of starting LinkWatcher (before full scan completes)

5. **Wait for LinkWatcher to process**: Allow time for startup scan to complete and move to be processed
   - **Duration**: Wait 15 seconds
   - **Observe**: LinkWatcher log should show startup scan and then move detection

6. **Verify references updated**: Check that both README.md and docs/guide.md point to the new location
   - **Tool**: Text editor
   - **Target**: Open `README.md` and `docs/guide.md` and check link targets

## Scripted Action

**Script**: `run.ps1`
**Action**: Stops LW, creates `docs/guide.md` referencing `settings/config.yaml`, restarts LW, immediately moves `settings/config.yaml` to `config/config.yaml`

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `README.md` | Line 3 | `[Config](settings/config.yaml)` | `[Config](config/config.yaml)` |
| `docs/guide.md` | Line 3 | `[Config](../settings/config.yaml)` | `[Config](../config/config.yaml)` |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows startup/initialization messages
- LinkWatcher log shows scanning of project files (including the newly created `docs/guide.md`)
- LinkWatcher log shows move detection from `settings/config.yaml` to `config/config.yaml`
- LinkWatcher log shows reference updates to `README.md` and `docs/guide.md`
- No errors or warnings in LinkWatcher log

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-012` — compares workspace against `expected/`
- [ ] **Log check**: Check LinkWatcher log for startup, scan, move detection, and update messages without errors

## Pass Criteria

- [ ] `README.md` reference updated from `settings/config.yaml` to `config/config.yaml`
- [ ] `docs/guide.md` reference updated from `../settings/config.yaml` to `../config/config.yaml`
- [ ] `config.yaml` exists at `config/config.yaml` with original content
- [ ] LinkWatcher is running after the test completes
- [ ] `Verify-TestResult.ps1` reports all files match expected state
- [ ] No errors or crashes in LinkWatcher log during startup + move sequence

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Save LinkWatcher log output as evidence
- **Important**: Ensure LinkWatcher is restarted after a failure so other tests can proceed

## Notes

- This test deliberately creates a race condition: a file move happens while LW is still scanning/starting up
- The 2-second delay before moving is intentionally short — LW may or may not have finished scanning at this point
- If the test fails, it may indicate a timing issue in LW's startup sequence rather than a fundamental bug
- The test restarts LW at the end, leaving the system in a usable state for subsequent tests
