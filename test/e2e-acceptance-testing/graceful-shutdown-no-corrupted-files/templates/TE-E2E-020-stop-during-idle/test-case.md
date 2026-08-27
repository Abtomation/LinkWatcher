---
id: TE-E2E-020
description: "E2E acceptance test (WF-008): TE-E2E-020 Stop During Idle."
type: Testing
category: E2E Acceptance Test Case
group: TE-E2G-010
feature_ids: ["0.1.1", "2.2.1", "0.1.2"]
workflow: WF-008
priority: P2
execution_mode: scripted
estimated_duration: 3 minutes
source: Cross-Cutting Spec PF-TSP-044 S-017
created: 2026-03-18
updated: 2026-08-27
---

# Test Case: TE-E2E-020 Stop During Idle

## Preconditions

- [ ] LinkWatcher is running with `--project-root <workspace>/project`
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow graceful-shutdown-no-corrupted-files`
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

3. **Stop LinkWatcher**: Terminate the running process
   - **Tool**: `Stop-WorkspaceLinkWatcher` (`run.ps1` finally block), which uses `Stop-Process -Force`
   - **Target**: The running LinkWatcher process
   - **Note**: This is a hard `TerminateProcess`, matching how every operator stop path ends the daemon — see the scope note under [Notes](#notes)

4. **Verify the process is gone**: Confirm the daemon is no longer running
   - **Tool**: Terminal output
   - **Observe**: The PID reported at startup no longer exists

5. **Verify no file corruption**: Confirm all project files are identical to their pre-test state
   - **Tool**: `Verify-TestResult.ps1` or manual comparison
   - **Target**: All files in `project/` directory

## Scripted Action

**Script**: `run.ps1`
**Action**: Waits 5 seconds for LinkWatcher to reach idle state (no file operations performed), then terminates the daemon from its own `finally` block via `Stop-WorkspaceLinkWatcher`

## Expected Results

### File Changes

| File | Expected State |
|------|---------------|
| `project/docs/readme.md` | UNCHANGED — identical to starting state |
| `project/docs/guide.md` | UNCHANGED — identical to starting state |

See `expected/` directory for complete post-test file state (identical to `project/`).

### Behavioral Outcomes

- All project files are intact — an idle daemon holds no partial write, so termination cannot truncate or corrupt a file
- No error messages or stack traces in the log up to the moment of termination
- The daemon is ended by a hard kill and runs no Python cleanup, so it writes no `service_stopping` / `service_stopped` records and its exit code is -1. **This is the path under test, not a defect** — see the scope note under [Notes](#notes)

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-020 -Workflow graceful-shutdown-no-corrupted-files` — compares workspace against `expected/`
- [ ] **Log check** (manual): Read `<workspace>/linkwatcher-e2e.log` and confirm it contains no errors, exceptions, or stack traces

## Pass Criteria

- [ ] All project files are byte-identical to their pre-test state (no corruption) — machine-checked by `Verify-TestResult.ps1`
- [ ] No error messages, exceptions, or stack traces in application log up to termination — manual check, not machine-checked

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Take screenshots or save log output as evidence

## Notes

### Scope of this case: kill-safety, not graceful shutdown

This case verifies that terminating an idle daemon leaves no file damaged. It does **not** verify
the graceful shutdown sequence, and its criteria deliberately assert nothing about one.

`run.ps1` stops the daemon with `Stop-Process -Force` — a hard `TerminateProcess` that runs no
Python code in the target. `LinkWatcherService.stop()` never executes, so its `service_stopping` /
`service_stopped` records are never written and the exit code is -1. That is not a harness
shortcoming: it mirrors the product, where **every** operator stop path is a hard kill —
`stop_linkwatcher.ps1` uses `Stop-Process -Force`, and the Control Panel uses `psutil terminate()`,
whose own module docstring notes there is no graceful cross-process signal. Making this harness
stop gracefully would exercise a path no operator tool can reach.

The graceful sequence is reachable only by an interactive `Ctrl+C` in a foreground console (plus
the daemon's own liveness/health self-stops). **No E2E case covers it** — a known gap, recorded at
PD-BUG-144 triage and restated here so a reader of this case is not left believing otherwise.

Earlier revisions of this case listed "Application log contains a shutdown/stopping message" and
"LinkWatcher process exited with code 0" among its pass criteria. Both were unsatisfiable under
this harness, and because `Verify-TestResult.ps1` compares only files under `expected/`, neither
was ever machine-checked — the case sat at Passed and Audit Approved regardless (PD-BUG-146).
`test/automated/unit/0-system-architecture-foundation/test_pd_bug_146_shutdown_criteria_guard.py`
now fails the build if any force-killed case reintroduces such a criterion.

### Other notes

- If the process hangs on termination, it indicates a thread or resource cleanup issue.
- An idle daemon is the weakest corruption case by design; TE-E2E-021 covers termination while a
  reference update is in flight.
