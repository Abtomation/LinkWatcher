---
id: TE-E2E-041
type: Testing
category: E2E Acceptance Test Case
description: "E2E acceptance test case: second launch surfaces existing window"
group: TE-E2G-015
feature_ids: ["7.1.1"]
workflow: WF-010
priority: P2
execution_mode: manual
estimated_duration: 4 minutes
source: WF-010 milestone
expected_exit_code: 0
created: 2026-08-25
updated: 2026-08-27
---

# Test Case: TE-E2E-041 second launch surfaces existing window

Launching the panel while one is already open must surface the existing window rather than create a
second one. Two panels would mean two supervisors issuing stop commands against the same daemons.

Covers the **second clause of AC-11** only — "if a panel window is already open, that existing
window is surfaced rather than a second window being created".

> **Scope boundary — the first clause is deliberately not tested here.** AC-11 also requires the
> panel to open automatically when the `SessionStart` hook starts a daemon. That behaviour is
> **not currently delivered**: it was live-verified on 2026-08-10, silently reverted by the
> 2026-08-14 framework rollout, and is re-tracked as PF-IMP-2032. FR-8, UI-7, BR-8 and AC-11's
> first clause stay UNMET until it lands. **Do not add an auto-open case to this workflow before
> then — it cannot pass.** When PF-IMP-2032 lands, add it as a new case rather than widening this one.

## Preconditions

- [ ] LinkWatcher is installed globally, or `LINKWATCHER_INSTALL_DIR` points at this repository
- [ ] **No Control Panel instance is running at the start of this test** — this case is about the
      guard itself, so a pre-existing panel invalidates it completely
- [ ] No stale `panel.port` file in the panel's install directory (delete one if present)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`
- [ ] Sandbox registry seeded via `seed-sandbox.ps1 -WorkspacePath <workspace>/TE-E2E-041-second-launch-surfaces-existing-window`

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/sandbox-a/**` | A registered project so the panel has something to list | Launcher + `doc/project-config.json` (`SBX-A`) + config + guide/setup pair |

No daemon needs to run for this case — the subject is the panel's own single-instance guard.

## Steps

1. **Set up the workspace**.
   - **Tool**: Command Line (repository root)
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`

2. **Seed the sandbox registry**.
   - **Tool**: Command Line
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/seed-sandbox.ps1 -WorkspacePath test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/workspace/TE-E2E-041-second-launch-surfaces-existing-window`

3. **Confirm no panel is running**.
   - **Tool**: Command Line
   - **Command**: `Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*control_panel*' } | Select-Object ProcessId, Name`
   - **Check**: Returns nothing

4. **Launch the first panel**.
   - **Tool**: Command Line (repository root)
   - **Command**: `python control_panel.py --registry "<workspace>/TE-E2E-041-second-launch-surfaces-existing-window/sandbox-registry.json" --debug`
   - **Check**: The window opens and lists `sandbox-a`

5. **Record the panel process ID**.
   - **Tool**: Command Line
   - **Command**: the step 3 command
   - **Note**: Exactly one panel process; record its PID

6. **Move the panel window** somewhere unmistakable, then **send it behind another window** so a
   surfacing action will be visibly distinguishable from "it was already in front".

7. **Launch a second panel from a separate terminal**.
   - **Tool**: Command Line (repository root, second terminal)
   - **Command**: the step 4 command, unchanged
   - **Observe**: The existing window is surfaced — it is raised to the front, **or**, where
     Windows' foreground lock refuses the activation, its taskbar button flashes (TDD §4.5 states
     the flash as the guaranteed floor). **Record which of the two occurred.** Either way the
     window keeps the position set in step 6 and its contents, so it is plainly the same window,
     not a new one

8. **Confirm the second launch exited rather than staying resident**.
   - **Tool**: Command Line (second terminal)
   - **Check**: The command printed a message and returned to the prompt; it is not still running

9. **Re-check the process list**.
   - **Tool**: Command Line
   - **Command**: the step 3 command
   - **Check**: Still exactly **one** panel process, with the **same PID** recorded in step 5

10. **Close the panel** and confirm it exits.

## Expected Results

### File Changes

No file changes — the panel is only opened and surfaced. See `expected/` for the content files
asserted unchanged.

### Behavioral Outcomes

- The first launch opens exactly one window
- The second launch **does not** create a second window
- The existing window is surfaced — raised to the front, or (where Windows' foreground lock refuses
  the activation) its taskbar button flashes — preserving its position and contents
- The second process prints an informational message and **exits**
- The panel process count and PID are unchanged across the second launch
- The panel log records the surface handshake; no ERROR entries

## Verification Method

- [ ] **Automated comparison**: `Verify-TestResult.ps1 -TestCase TE-E2E-041 -Workflow manage-running-linkwatcher-instances-via-control-panel`
- [ ] **Process check**: PID recorded at step 5 equals the single PID at step 9
- [ ] **Visual inspection**: A surfacing response was observed — raise to front or taskbar flash,
      recorded as one or the other — and the surfaced window kept the position set in step 6
- [ ] **Log check**: Panel log records the surface handshake and no ERROR entries

## Pass Criteria

- [ ] Exactly one panel process exists after the second launch, with the same PID as before it
- [ ] No second window appears
- [ ] The surfaced window is the same window — the position set in step 6 and its contents are preserved
- [ ] Surfacing was positively observed: the window was raised to the front, **or** — where Windows'
      foreground lock refused the activation — its taskbar button flashed (the TDD §4.5 floor).
      Record which occurred; observing **neither** is a FAIL
- [ ] The second launch process exits rather than remaining resident
- [ ] All files in `expected/` match the workspace byte-for-byte
- [ ] No ERROR entries in the panel log

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- If a **second window** opened, capture both PIDs and the `panel.port` file contents — a recycled
  or stale port is the known failure mode of the guard
- If **neither** a raise nor a taskbar flash was observed and the second process exited silently,
  distinguish "guard worked, surfacing failed" from "guard worked, window was already in front" —
  step 6 exists to make that distinguishable, so re-run it properly rather than guessing. A flash
  without a raise is **not** a failure (TDD §4.5); only the absence of both is
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect

## Notes

- Simultaneous double-launch (two launches racing before either publishes its port) is an accepted
  Known Limitation and is **not** what this case tests. Launch the second panel only after the
  first window is fully open.
- A stale `panel.port` from a crashed panel can make the guard behave unexpectedly; the
  preconditions require removing one, and the incumbent must answer a banner handshake precisely so
  a recycled port cannot block the panel permanently.
- Runtime files (`panel.log`, `panel.port`) live in the panel's install directory, not the workspace.
