---
id: TE-E2E-020
type: E2E Acceptance Test Case
group: TE-E2G-010
feature_ids: ["0.1.1, 2.2.1, 0.1.2"]
workflow: WF-008
priority: P2
execution_mode: scripted
estimated_duration: 3 minutes
source: Cross-Cutting Spec PF-TSP-044 S-017
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-020 Stop During Idle

## Preconditions

- [ ] LinkWatcher is running with `--project-root <workspace>/project`
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group graceful-shutdown`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] LinkWatcher has completed initial scan and is idle (no pending move events)

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/docs/readme.md` | Referencing file with a link | Contains `[Guide](guide.md)` |
| `project/docs/guide.md` | Target file referenced by readme.md | Contains user guide content |

## Steps

1. **Start LinkWatcher**: Launch LinkWatcher against the workspace project directory
   - **Tool**: Command Line
   - **Command**: `python main.py --project-root <workspace>/project`

2. **Wait for idle state**: Wait for LinkWatcher to complete the initial file scan and become idle
   - **Duration**: Wait 5 seconds for initial scan to complete
   - **Observe**: Log output confirming initial scan is done; no further activity

3. **Stop LinkWatcher**: Send stop signal (SIGINT/Ctrl+C or process termination)
   - **Tool**: Command Line or test orchestrator
   - **Target**: The running LinkWatcher process

4. **Verify clean shutdown**: Check that the process exited cleanly
   - **Tool**: Terminal output and log file
   - **Observe**: Process exit code is 0; log shows shutdown message

5. **Verify no file corruption**: Confirm all project files are identical to their pre-test state
   - **Tool**: `Verify-TestResult.ps1` or manual comparison
   - **Target**: All files in `project/` directory

## Scripted Action

**Script**: `run.ps1`
**Action**: Waits 5 seconds for LinkWatcher to reach idle state (no file operations performed; stop signal is sent by the test orchestrator)

## Expected Results

### File Changes

| File | Expected State |
|------|---------------|
| `project/docs/readme.md` | UNCHANGED — identical to starting state |
| `project/docs/guide.md` | UNCHANGED — identical to starting state |

See `expected/` directory for complete post-test file state (identical to `project/`).

### Behavioral Outcomes

- Log shows clean shutdown message (e.g., "Stopping", "Shutdown complete", "LinkWatcher stopped", or similar)
- No error messages or stack traces in the log
- Process exits with code 0

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-020` — compares workspace against `expected/`
- [ ] **Log check**: Check application log for clean shutdown message and absence of errors

## Pass Criteria

- [ ] All project files are byte-identical to their pre-test state (no corruption)
- [ ] Application log contains a shutdown/stopping message
- [ ] No error messages, exceptions, or stack traces in application log
- [ ] LinkWatcher process exited with code 0

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Take screenshots or save log output as evidence

## Notes

- This test validates the basic graceful shutdown path when no work is pending.
- The stop signal may be SIGINT (Ctrl+C), SIGTERM, or process kill depending on the test orchestrator implementation.
- If the process hangs on shutdown, it indicates a thread or resource cleanup issue.
