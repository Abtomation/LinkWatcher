---
id: TE-E2E-019
type: E2E Acceptance Test Case
group: TE-E2G-009
feature_ids: ["0.1.3", "0.1.1", "2.2.1", "3.1.1"]
workflow: WF-007
priority: P3
execution_mode: scripted
estimated_duration: 5 minutes
source: Cross-Cutting Spec PF-TSP-044 S-016
lw_flags: "--dry-run"
created: 2026-03-18
updated: 2026-03-23
---

# Test Case: TE-E2E-019 Move File in Dry-Run Mode

## Preconditions

- [ ] LinkWatcher is running with `--dry-run --project-root <workspace>/project`
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group dry-run-mode`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] LinkWatcher has completed initial scan (log shows initial scan output)

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/docs/readme.md` | Referencing file with a link to api-guide.md | Contains `[API Guide](api-guide.md)` |
| `project/docs/api-guide.md` | Target file that will be moved | Contains API documentation content |

## Steps

1. **Start LinkWatcher**: Launch LinkWatcher in dry-run mode against the workspace project directory
   - **Tool**: Command Line
   - **Command**: `python main.py --dry-run --project-root <workspace>/project`

2. **Wait for initial scan**: Wait for LinkWatcher to complete the initial file scan
   - **Duration**: Wait 3-5 seconds for initial scan to complete
   - **Observe**: Log output confirming initial scan is done

3. **Move the target file**: Move api-guide.md from docs/ to a new archive/ directory
   - **Tool**: run.ps1 (scripted action)
   - **Target**: `project/docs/api-guide.md` moves to `project/archive/api-guide.md`

4. **Wait for event processing**: Allow LinkWatcher to detect and process the move event
   - **Duration**: Wait 3-5 seconds for file system events to propagate
   - **Observe**: Log output showing dry-run messages

5. **Verify readme.md is unchanged**: Open readme.md and confirm the link was NOT updated
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: `project/docs/readme.md` should still contain `[API Guide](api-guide.md)`

6. **Verify log output**: Check that the log contains dry-run messages indicating what would have been updated
   - **Tool**: Log file or terminal output
   - **Observe**: Messages containing "DRY RUN", "dry run", or "would update"

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates archive/ directory and moves project/docs/api-guide.md to project/archive/api-guide.md

## Expected Results

### File Changes

| File | Expected State |
|------|---------------|
| `project/docs/readme.md` | UNCHANGED — still contains `[API Guide](api-guide.md)` (dry-run prevents writes) |
| `project/archive/api-guide.md` | EXISTS — file was physically moved |
| `project/docs/api-guide.md` | DELETED — file was moved away |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- Log contains dry-run indicator message (e.g., "DRY RUN", "dry run", or "would update") showing what link update would have occurred
- The dry-run message references readme.md and the link to api-guide.md
- LinkWatcher continues running without errors after the dry-run detection

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-019` — compares workspace against `expected/`
- [ ] **Log check**: Check application log for dry-run messages and absence of error messages

## Pass Criteria

- [ ] `project/docs/readme.md` still contains the original link text `[API Guide](api-guide.md)` (not updated)
- [ ] `project/archive/api-guide.md` exists (file was physically moved)
- [ ] Application log contains at least one dry-run indicator message (matching "DRY RUN", "dry run", or "would update")
- [ ] No error messages in application log during test execution
- [ ] LinkWatcher process remains running after the move event

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Take screenshots or save log output as evidence

## Notes

- This test validates that the `--dry-run` flag prevents all file writes while still logging what would change.
- The key distinction is: the file move itself is a real OS operation (not controlled by LinkWatcher), but the link update in readme.md must be suppressed by dry-run mode.
- If readme.md is updated despite dry-run mode, this is a critical bug in the dry-run implementation.
