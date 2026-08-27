---
id: TE-E2E-035
type: Testing
category: E2E Acceptance Test Case
description: "E2E acceptance test case: start and stop daemon from panel"
group: TE-E2G-015
feature_ids: ["7.1.1"]
workflow: WF-010
priority: P0
execution_mode: manual
estimated_duration: 7 minutes
source: WF-010 milestone
expected_exit_code: 0
created: 2026-08-25
updated: 2026-08-25
---

# Test Case: TE-E2E-035 start and stop daemon from panel

The panel starts a daemon for a project that has none, stops it cleanly, and — critically —
refuses to create a **second** daemon when a start is attempted against a project that already has
one. The duplicate-start guard is the race the `SessionStart` hook can lose against an operator
clicking start.

Covers **AC-2** (start), **AC-3** (stop drains and the row reflects it) and **AC-10** (no second
daemon for an already-running project).

## Preconditions

- [ ] LinkWatcher is installed globally, or `LINKWATCHER_INSTALL_DIR` points at this repository
- [ ] **No other Control Panel instance is running** (see TE-E2E-034 preconditions for why)
- [ ] No LinkWatcher daemon is running for either sandbox project root
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`
- [ ] Sandbox registry seeded via `seed-sandbox.ps1 -WorkspacePath <workspace>/TE-E2E-035-start-and-stop-daemon-from-panel`

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/sandbox-a/**` | The project started and stopped in this test | Launcher + `doc/project-config.json` (`SBX-A`) + config + guide/setup reference pair |
| `project/sandbox-b/**` | Second project, left stopped throughout — proves start is row-scoped | Same shape, `project_id: SBX-B` |

## Steps

1. **Set up the workspace**.
   - **Tool**: Command Line (repository root)
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`

2. **Seed the sandbox registry**.
   - **Tool**: Command Line
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/seed-sandbox.ps1 -WorkspacePath test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/workspace/TE-E2E-035-start-and-stop-daemon-from-panel`

3. **Open the panel against the sandbox registry**.
   - **Tool**: Command Line (repository root)
   - **Command**: `python control_panel.py --registry "<workspace>/TE-E2E-035-start-and-stop-daemon-from-panel/sandbox-registry.json" --debug`
   - **Observe**: Both rows appear as **stopped** once the first discovery pass lands

4. **Select `sandbox-a` and start it from the panel**.
   - **Tool**: Control Panel window
   - **Target**: The start control on the toolbar

5. **Wait for the start to converge**.
   - **Duration**: Up to 30 seconds — the launcher sleeps ~2 s for its own post-start check, and the panel needs up to two poll cycles
   - **Observe**: The row moves through a transitional state to **running** and reports a PID

6. **Record the daemon PIDs**.
   - **Tool**: Command Line
   - **Command**: `Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*sandbox-a*' -and $_.Name -like 'python*' } | Select-Object ProcessId, CommandLine`
   - **Note**: A healthy daemon is a **pair** (venv shim parent + real interpreter) with identical command lines — two rows here is correct, not a duplicate

7. **Attempt a second start on the same row** (**AC-10**).
   - **Tool**: Control Panel window
   - **Target**: The start control, with `sandbox-a` still selected. If the control is disabled for a running row, record that — a disabled control satisfies AC-10 by construction.

8. **Re-check the process list**.
   - **Tool**: Command Line
   - **Command**: Repeat the step 6 command
   - **Check**: The PID set is **unchanged** — no third or fourth process appeared

9. **Confirm `sandbox-b` is still stopped** — the start acted only on the selected row.

10. **Stop `sandbox-a` from the panel** and wait for the row to reach stopped.
    - **Duration**: Up to the 20 s grace period; a quiescent daemon drains in a few seconds

11. **Verify termination**.
    - **Tool**: Command Line
    - **Check**: No process from step 6 survives, and `sandbox-a/.linkwatcher.lock` is gone

12. **Close the panel** and confirm it exits.

## Expected Results

### File Changes

No file changes — no move or rename is performed. See `expected/` for the content files asserted
unchanged across both sandbox projects.

### Behavioral Outcomes

- Both rows start as **stopped**
- After step 4 the `sandbox-a` row reaches **running** and reports the lock file PID
- The daemon appears as a process **pair** with identical command lines (expected process model,
  not a duplicate daemon)
- The second start attempt (step 7) produces **no additional daemon**: either the control is
  disabled for a running row, or the launcher exits 0 on its idempotent already-running path and
  the PID set is unchanged
- `sandbox-b` remains stopped throughout
- The stop drains and terminates the pair and removes the lock file
- Panel log records the start, the no-op second start, and the stop, with no ERROR entries

## Verification Method

- [ ] **Automated comparison**: `Verify-TestResult.ps1 -TestCase TE-E2E-035 -Workflow manage-running-linkwatcher-instances-via-control-panel`
- [ ] **Process check**: PID sets captured at steps 6 and 8 are identical
- [ ] **Visual inspection**: Row status transitions as described
- [ ] **Log check**: Panel log has no ERROR entries

## Pass Criteria

- [ ] Starting from the panel produces a running daemon for `sandbox-a` within 30 seconds
- [ ] The PID set after the second start attempt is **identical** to the set before it (**AC-10**)
- [ ] `sandbox-b` is never started
- [ ] Stopping from the panel terminates the daemon pair and removes the lock file (**AC-3**)
- [ ] All files in `expected/` match the workspace byte-for-byte
- [ ] The panel exits cleanly on close
- [ ] No ERROR entries in the panel log

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- If a second daemon **did** appear, capture both command lines and the lock file contents — that
  is an AC-10 defect and the singleton guard is the first suspect
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect

## Notes

- Two processes per daemon is the documented Store-Python venv process model (shim parent + real
  interpreter): a process **count** must never be read as an instance count.
- Start goes through the project's own launcher by design (D-T4), so launcher failures surface here
  as start failures. Check the launcher's own output before blaming the panel.
- Runtime files (`panel.log`, `panel.port`) live in the panel's install directory, not the workspace.
