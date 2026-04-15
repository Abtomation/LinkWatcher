---
id: TE-E2E-025
type: E2E Acceptance Test Case
group: TE-E2G-012
feature_ids: ["0.1.3", "1.1.1", "3.1.1"]
workflow: WF-006
priority: P3
execution_mode: scripted
estimated_duration: 5 minutes
source: WF-006 user-workflow-tracking
lw_flags: "--config <workspace>/project/config.yaml"
created: 2026-04-12
updated: 2026-04-12
---

# Test Case: TE-E2E-025 Backup Creation Enabled

## Preconditions

- [ ] LinkWatcher is installed and available via `python main.py`
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group configuration-behavior-adaptation`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] LinkWatcher started with `--config <workspace>/project/config.yaml --project-root <workspace>/project`

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/config.yaml` | Config enabling backup creation | `create_backups: true` |
| `project/docs/readme.md` | File with link to api-guide.md that will be backed up before update | `[API Guide](api-guide.md)` |
| `project/docs/api-guide.md` | Target file that will be moved | API documentation content |

## Steps

1. **Start LinkWatcher**: Launch with config that enables backup creation
   - **Tool**: Command Line
   - **Command**: `python main.py --config <workspace>/project/config.yaml --project-root <workspace>/project`

2. **Wait for initial scan**: Wait for LinkWatcher to index files
   - **Duration**: Wait 3-5 seconds for initial scan to complete
   - **Observe**: Log output confirming initial scan is done

3. **Move the target file**: Move api-guide.md to archive/
   - **Tool**: run.ps1 (scripted action)
   - **Target**: `project/docs/api-guide.md` moves to `project/archive/api-guide.md`

4. **Wait for event processing**: Allow LinkWatcher to detect and process the move
   - **Duration**: Wait 3-5 seconds for file system events to propagate
   - **Observe**: Log output showing move detection, backup creation, and link update

5. **Verify readme.md IS updated**: The link should point to the new location
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: `project/docs/readme.md` should now contain `[API Guide](../archive/api-guide.md)`

6. **Verify backup file exists**: A `.bak` file should be created with the original content
   - **Tool**: File Explorer or `ls project/docs/`
   - **Target**: `project/docs/readme.md.bak` should exist and contain original `[API Guide](api-guide.md)`

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates archive/ directory and moves project/docs/api-guide.md to project/archive/api-guide.md

## Expected Results

### File Changes

| File | Expected State |
|------|---------------|
| `project/docs/readme.md` | UPDATED — link changed from `[API Guide](api-guide.md)` to `[API Guide](../archive/api-guide.md)` |
| `project/docs/readme.md.bak` | CREATED — backup with original content `[API Guide](api-guide.md)` |
| `project/archive/api-guide.md` | EXISTS — file was physically moved |
| `project/docs/api-guide.md` | DELETED — file was moved away |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- Log shows move detection for api-guide.md
- Log shows backup creation for readme.md (e.g., "Creating backup" or similar message)
- Log shows link update in readme.md
- `.bak` file contains the pre-update content of readme.md
- LinkWatcher continues running without errors

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-025` — compares workspace against `expected/`
- [ ] **Visual inspection**: Confirm `readme.md.bak` exists and contains original link text
- [ ] **Log check**: Confirm log mentions backup creation

## Pass Criteria

- [ ] `project/docs/readme.md` contains updated link `[API Guide](../archive/api-guide.md)`
- [ ] `project/docs/readme.md.bak` exists and contains original link `[API Guide](api-guide.md)`
- [ ] `project/archive/api-guide.md` exists (file was physically moved)
- [ ] No errors or warnings in application log during test execution

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Take screenshots or save log output as evidence

## Notes

- This test validates that the `create_backups: true` config option causes LinkWatcher to create `.bak` backup files before modifying any file.
- The backup file should be an exact copy of the file before the link update was applied.
- By default, `create_backups` is `false`, so this tests that the config override takes effect.
- If no `.bak` file is created, the backup feature is not responding to config.
