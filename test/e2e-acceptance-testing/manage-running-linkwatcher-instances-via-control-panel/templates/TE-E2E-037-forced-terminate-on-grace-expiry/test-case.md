---
id: TE-E2E-037
type: Testing
category: E2E Acceptance Test Case
description: "E2E acceptance test case: forced terminate on grace expiry"
group: TE-E2G-015
feature_ids: ["7.1.1", "2.2.1", "0.1.2"]
workflow: WF-010
priority: P1
execution_mode: manual
estimated_duration: 8 minutes
source: WF-010 milestone
expected_exit_code: 0
created: 2026-08-25
updated: 2026-08-25
---

# Test Case: TE-E2E-037 forced terminate on grace expiry

A daemon that never goes quiet must not be able to hold the panel open forever. Continuous churn
keeps the daemon logging so quiescence is never observed; at grace expiry the panel must
force-terminate it, report the forced stop visibly, and still exit — leaving no file corrupted.

Covers **AC-9**. The counterpart to TE-E2E-036: that case proves the drain *waits*, this one proves
it *gives up safely*.

## Preconditions

- [ ] LinkWatcher is installed globally, or `LINKWATCHER_INSTALL_DIR` points at this repository
- [ ] **No other Control Panel instance is running** (see TE-E2E-034 preconditions for why)
- [ ] No LinkWatcher daemon is running for the sandbox project root
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`
- [ ] Sandbox registry seeded via `seed-sandbox.ps1 -WorkspacePath <workspace>/TE-E2E-037-forced-terminate-on-grace-expiry`
- [ ] The panel's `grace_period_seconds` is at its default (20 s). If `panel-config.yaml` in the
      install directory overrides it, note the effective value — the expected wait scales with it.

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/sandbox-a/docs/guide.md` | The no-corruption witness — untouched by the churn | `[Setup Notes](../notes/setup.md)` |
| `project/sandbox-a/notes/setup.md` | Reference target, also untouched | Plain markdown |
| `project/sandbox-a/tools/linkwatcher/linkwatcher-config.yaml` | Daemon config; `.md` is monitored so churn files generate events | monitored extensions include `.md` |
| `project/sandbox-a/process-framework/tools/linkWatcher/start_linkwatcher_background.ps1` | Launcher | Verbatim copy |
| `project/sandbox-a/doc/project-config.json` | Root resolution guard | `project_id: SBX-A` |

**File-side action**: `action.ps1` starts a detached churn writer (a file under `churn/` every
400 ms) and stops it again with `-Stop`. Churn files live outside `expected/`, so they cannot
affect the comparison. Not named `run.ps1` — see TE-E2E-036.

## Steps

1. **Set up the workspace**.
   - **Tool**: Command Line (repository root)
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`

2. **Seed the sandbox registry**.
   - **Tool**: Command Line
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/seed-sandbox.ps1 -WorkspacePath test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/workspace/TE-E2E-037-forced-terminate-on-grace-expiry`

3. **Open the panel and start the sandbox-a daemon from it**.
   - **Tool**: Command Line, then Control Panel window
   - **Command**: `python control_panel.py --registry "<workspace>/TE-E2E-037-forced-terminate-on-grace-expiry/sandbox-registry.json" --debug`
   - **Check**: The `sandbox-a` row reaches **running**

4. **Start the churn writer**.
   - **Tool**: Command Line
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/TE-E2E-037-forced-terminate-on-grace-expiry/action.ps1 -WorkspacePath test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/workspace/TE-E2E-037-forced-terminate-on-grace-expiry`
   - **Observe**: It prints the churn writer PID, its run duration, and **how many churn files it
     has already seen on disk**. The script waits for real churn before reporting success, so a
     non-zero exit or "No churn produced" means the writer is broken — **abandon the run and record
     no verdict** rather than continuing (PD-BUG-138: a silent writer makes this case pass while
     testing nothing). Diagnostics: `churn-writer.ps1` and `churn-writer.err.log` in the workspace root.

5. **Confirm the daemon is genuinely non-quiescent**.
   - **Duration**: 5 seconds
   - **Observe**: The newest log file under `sandbox-a/logs/linkwatcher/` is growing continuously —
     never silent for 3 s. Step 4 has already proven churn is reaching *disk*; this step proves it
     is reaching the *daemon*. If the log is going quiet anyway, check that `.md` is in the
     project's `monitored_extensions`, and stop — do not close the panel.

6. **Close the panel window while churn is active**.
   - **Tool**: Control Panel window
   - **Target**: The window close control (title-bar X)
   - **Note the wall-clock time** at which the close was requested

7. **Observe the shutdown**.
   - **Duration**: Just over the grace period (default ~20 s)
   - **Observe**: The dialog shows the drain not completing, then reports a **forced** stop for
     `sandbox-a`. The application exits by itself.

8. **Record the elapsed time** from step 6 to process exit — it must be bounded, roughly the grace
   period plus a small margin, not indefinite.

9. **Stop the churn writer**.
   - **Tool**: Command Line
   - **Command**: the step 4 command with `-Stop` appended

10. **Confirm everything terminated**.
    - **Tool**: Command Line
    - **Check**: No sandbox-a daemon process, no panel process; `sandbox-a/.linkwatcher.lock` removed

11. **Inspect the witness files**: open `docs/guide.md` and `notes/setup.md`.
    - **Tool**: Text editor
    - **Check**: Both are complete and unchanged — the forced kill corrupted nothing

## Expected Results

### File Changes

No changes to the witness files. `docs/guide.md` and `notes/setup.md` must be byte-identical to
their starting state — no move was performed, so no reference should have been rewritten.

Churn files under `sandbox-a/churn/` are test scaffolding, are not in `expected/`, and are ignored
by the comparison.

### Behavioral Outcomes

- The daemon never reaches quiescence while churn is active
- The panel does **not** wait indefinitely: it force-terminates at grace expiry
- The forced stop is **visibly reported** — in the shutdown dialog and/or status bar — not silent
- The application exits on its own; no hang, no second close, no manual kill needed
- Total shutdown time is bounded at roughly the grace period plus a small margin
- The panel log records the forced termination at WARN or above (this is the record that answers
  "why was my daemon force-stopped")
- No file under `sandbox-a` is left truncated or partially written

## Verification Method

- [ ] **Automated comparison**: `Verify-TestResult.ps1 -TestCase TE-E2E-037 -Workflow manage-running-linkwatcher-instances-via-control-panel` — confirms the witness files are unchanged
- [ ] **Timing check**: Elapsed close-to-exit recorded at step 8 is bounded
- [ ] **Visual inspection**: The forced stop was reported in the UI, and `guide.md` is intact
- [ ] **Log check**: Panel log contains a forced-termination entry at WARN or above

## Pass Criteria

- [ ] **Churn was genuinely active** — step 4 reported churn files on disk *and* step 5 saw the
      daemon log advancing. Every criterion below is meaningless without this one: a dead writer
      lets the daemon go quiet, the drain then completes normally, and the case reports PASS having
      exercised nothing (PD-BUG-138). If churn cannot be confirmed, the run is **inconclusive**, not
      passed.
- [ ] The panel force-terminates the non-quiescent daemon rather than waiting indefinitely
- [ ] The application exits without hanging, within roughly the grace period plus a small margin
- [ ] The forced stop is visibly reported in the UI
- [ ] The panel log records the forced termination at WARN or above
- [ ] `docs/guide.md` and `notes/setup.md` match `expected/` byte-for-byte
- [ ] No sandbox-a daemon or panel process survives; the lock file is removed

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- If the panel **hung**, capture a process dump or at least the process list and the panel log
  before killing it — a hang is the defect and the evidence disappears on kill
- Always run `action.ps1 -Stop` afterwards; a leaked churn writer keeps rewriting files
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect

## Notes

- If a `panel-config.yaml` in the install directory lowers `grace_period_seconds`, the wait in
  step 7 shortens accordingly — the pass criterion is "bounded and roughly the configured grace",
  not a fixed 20 s.
- The churn writer stops on its own after its duration (default 90 s) even if `-Stop` is forgotten,
  but running `-Stop` is still the clean path and removes the PID file that blocks a re-run.
- Runtime files (`panel.log`, `panel.port`) live in the panel's install directory, not the workspace.
- `action.ps1` writes the writer's body to `churn-writer.ps1` in the workspace root and launches it
  from there (an inline payload cannot survive `Start-Process -ArgumentList` intact — PD-BUG-138).
  That file, plus `churn-writer.err.log` on failure, sit outside `project/`, so the daemon never
  sees them and `expected/` is unaffected. Regression coverage:
  [test_pd_bug_138_e2e037_churn_writer.py](../../../../automated/unit/7-operations-control/7-1-control-panel/test_pd_bug_138_e2e037_churn_writer.py).
