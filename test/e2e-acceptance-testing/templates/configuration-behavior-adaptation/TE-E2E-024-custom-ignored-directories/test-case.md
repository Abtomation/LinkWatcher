---
id: TE-E2E-024
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

# Test Case: TE-E2E-024 Custom Ignored Directories

## Preconditions

- [ ] LinkWatcher is installed and available via `python main.py`
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group configuration-behavior-adaptation`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] LinkWatcher started with `--config <workspace>/project/config.yaml --project-root <workspace>/project`

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/config.yaml` | Config adding `archive` to ignored_directories | `ignored_directories: [".git", "archive"]` |
| `project/docs/readme.md` | Monitored file with link to api-guide.md | `[API Guide](api-guide.md)` |
| `project/docs/api-guide.md` | Target file that will be moved | API documentation content |
| `project/archive/index.md` | File in ignored directory with link to api-guide.md | `[API Guide](../docs/api-guide.md)` |

## Steps

1. **Start LinkWatcher**: Launch with the config that ignores archive/
   - **Tool**: Command Line
   - **Command**: `python main.py --config <workspace>/project/config.yaml --project-root <workspace>/project`

2. **Wait for initial scan**: Wait for LinkWatcher to index files
   - **Duration**: Wait 3-5 seconds for initial scan to complete
   - **Observe**: Log should NOT show scanning of files under archive/

3. **Move the target file**: Move api-guide.md to moved/
   - **Tool**: run.ps1 (scripted action)
   - **Target**: `project/docs/api-guide.md` moves to `project/moved/api-guide.md`

4. **Wait for event processing**: Allow LinkWatcher to detect and process the move
   - **Duration**: Wait 3-5 seconds for file system events to propagate
   - **Observe**: Log output showing move detection and link update in readme.md

5. **Verify readme.md IS updated**: The file in the monitored directory should be updated
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: `project/docs/readme.md` should now contain `[API Guide](../moved/api-guide.md)`

6. **Verify archive/index.md is NOT updated**: The file in the ignored directory should remain unchanged
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: `project/archive/index.md` should still contain `[API Guide](../docs/api-guide.md)`

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates moved/ directory and moves project/docs/api-guide.md to project/moved/api-guide.md

## Expected Results

### File Changes

| File | Expected State |
|------|---------------|
| `project/docs/readme.md` | UPDATED — link changed from `[API Guide](api-guide.md)` to `[API Guide](../moved/api-guide.md)` |
| `project/archive/index.md` | UNCHANGED — still contains `[API Guide](../docs/api-guide.md)` (archive/ is ignored) |
| `project/moved/api-guide.md` | EXISTS — file was physically moved |
| `project/docs/api-guide.md` | DELETED — file was moved away |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- Log shows move detection for api-guide.md
- Log shows link update in docs/readme.md
- Log does NOT show any scan or update activity for archive/index.md
- LinkWatcher continues running without errors

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-024` — compares workspace against `expected/`
- [ ] **Log check**: Confirm log mentions readme.md update but NOT archive/index.md

## Pass Criteria

- [ ] `project/docs/readme.md` contains updated link `[API Guide](../moved/api-guide.md)`
- [ ] `project/archive/index.md` still contains original link `[API Guide](../docs/api-guide.md)` (unchanged)
- [ ] `project/moved/api-guide.md` exists (file was physically moved)
- [ ] No errors or warnings in application log during test execution

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Take screenshots or save log output as evidence

## Notes

- This test validates that `ignored_directories` config actually prevents LinkWatcher from scanning and updating files in excluded directories.
- The `archive/index.md` file contains a valid link to the moved file but should NOT be updated because its parent directory is in `ignored_directories`.
- If `archive/index.md` IS updated, the directory exclusion filtering is broken.
