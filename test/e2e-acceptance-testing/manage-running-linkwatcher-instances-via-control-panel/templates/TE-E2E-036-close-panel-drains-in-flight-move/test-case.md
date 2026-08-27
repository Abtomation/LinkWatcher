---
id: TE-E2E-036
type: Testing
category: E2E Acceptance Test Case
description: "E2E acceptance test case: close panel drains in flight move"
group: TE-E2G-015
feature_ids: ["7.1.1", "2.2.1", "0.1.2"]
workflow: WF-010
priority: P0
execution_mode: manual
estimated_duration: 8 minutes
source: WF-010 milestone
expected_exit_code: 0
created: 2026-08-25
updated: 2026-08-25
---

# Test Case: TE-E2E-036 close panel drains in flight move

A file move is put in flight as a **delete followed a few seconds later by a create**, and the
panel window is closed in the gap between the two halves — while the daemon is holding the
buffered delete, waiting for its matching create to decide whether this was a move. Closing the
panel is the deliberate stop action for every managed daemon, so this is the moment a naive
implementation drops the pending update. The drain must let the correlation resolve first.

> **The delete+create shape is load-bearing** (PD-BUG-136). A rename is delivered to the daemon as
> a *native* move event and is applied end to end in ~200 ms, so it is finished long before a human
> reaches the close control — a rename-based version of this case degraded into TE-E2E-035's clean
> stop and passed without ever exercising the drain. Only a buffered correlation leaves real work
> pending, and while the daemon waits it writes nothing to its log, which is precisely the state
> the drain used to misread as quiescence.

This is the scenario the TDD earmarks for E2E acceptance (§7.3, AC-8/AC-9) and the highest-value
case in the workflow. Covers **AC-7** (close drains and terminates every managed daemon, the app
exits) and **AC-8** (an in-progress update completes; no partial or corrupted file).

## Preconditions

- [ ] LinkWatcher is installed globally, or `LINKWATCHER_INSTALL_DIR` points at this repository
- [ ] **No other Control Panel instance is running** (see TE-E2E-034 preconditions for why)
- [ ] No LinkWatcher daemon is running for the sandbox project root
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`
- [ ] Sandbox registry seeded via `seed-sandbox.ps1 -WorkspacePath <workspace>/TE-E2E-036-close-panel-drains-in-flight-move`
- [ ] The operator can reach the panel window and the terminal within ~2 seconds of each other
      (the close must land in the gap between the delete and the create)

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/sandbox-a/docs/guide.md` | The file whose reference must be rewritten — the corruption witness | `[Setup Notes](../notes/setup.md)` |
| `project/sandbox-a/notes/setup.md` | Deleted, then re-created under `archive/` inside the correlation window | Plain markdown |
| `project/sandbox-a/tools/linkwatcher/linkwatcher-config.yaml` | Daemon config | `move_detect_delay: 10` |
| `project/sandbox-a/process-framework/tools/linkWatcher/start_linkwatcher_background.ps1` | Launcher used by the panel start path | Verbatim copy |
| `project/sandbox-a/doc/project-config.json` | Root resolution guard | `project_id: SBX-A` |

**File-side action**: `action.ps1` performs the delete, waits `-CreateDelaySeconds` (default 6),
then performs the create — a human cannot time the two halves accurately by hand. The gap must
stay **above** the panel log-idle threshold (3 s) and **below** the sandbox `move_detect_delay`
(10 s); outside that band the case stops testing the drain. It is deliberately **not** named
`run.ps1` — `Run-E2EAcceptanceTest.ps1` treats a `run.ps1` as "fully scripted" and would run this
case with no panel open, testing nothing.

## Steps

1. **Set up the workspace**.
   - **Tool**: Command Line (repository root)
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`

2. **Seed the sandbox registry**.
   - **Tool**: Command Line
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/seed-sandbox.ps1 -WorkspacePath test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/workspace/TE-E2E-036-close-panel-drains-in-flight-move`

3. **Open the panel and start the sandbox-a daemon from it**.
   - **Tool**: Command Line, then Control Panel window
   - **Command**: `python control_panel.py --registry "<workspace>/TE-E2E-036-close-panel-drains-in-flight-move/sandbox-registry.json" --debug`
   - **Check**: The `sandbox-a` row reaches **running** before continuing

4. **Let the daemon settle**: wait until its initial scan is done and the log goes quiet.
   - **Duration**: 5 seconds
   - **Observe**: `<workspace>/.../project/sandbox-a/logs/linkwatcher/` contains a log file that has stopped growing

5. **Position the windows**: put the terminal and the panel window side by side so the close
   control can be clicked immediately after the next step.

6. **Put the move in flight**: run the action script. It deletes the file, then re-creates it
   under `archive/` six seconds later — leaving the daemon holding a buffered correlation in
   between.
   - **Tool**: Command Line
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/TE-E2E-036-close-panel-drains-in-flight-move/action.ps1 -WorkspacePath test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/workspace/TE-E2E-036-close-panel-drains-in-flight-move`
   - **Observe**: The script prints the delete timestamp and the instruction to close the panel;
     it then blocks until it prints the create timestamp

7. **Close the panel window immediately** — within 1–3 seconds of step 6, i.e. **before** the
   script prints its create line.
   - **Tool**: Control Panel window
   - **Target**: The window close control (title-bar X)
   - **Observe**: The shutdown dialog appears and reports the drain in progress

8. **Watch the shutdown to completion**.
   - **Duration**: Up to the 20 s grace period
   - **Observe**: The create line appears **while the drain is still running** — that overlap is
     the whole point of the case. The dialog then reports each managed daemon draining, and the
     application exits by itself. It must not hang and must not require a second close.

9. **Confirm the process is gone**.
   - **Tool**: Command Line
   - **Check**: No `python` process with the sandbox-a root in its command line; no panel process;
     `sandbox-a/.linkwatcher.lock` removed

10. **Inspect the reference**: open `<workspace>/.../project/sandbox-a/docs/guide.md`.
    - **Tool**: Text editor
    - **Check**: The link reads `[Setup Notes](../archive/setup.md)` and the file is complete —
      no truncation, no duplicated fragment, no partial path

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `sandbox-a/docs/guide.md` | Link line | `[Setup Notes](../notes/setup.md)` | `[Setup Notes](../archive/setup.md)` |
| `sandbox-a/notes/setup.md` | whole file | present | moved away (no longer at this path) |
| `sandbox-a/archive/setup.md` | whole file | absent | present, content unchanged |

See `expected/` for the complete post-test state of the two files that must change.

### Behavioral Outcomes

- Closing the window triggers the shutdown dialog, not an immediate kill
- The in-flight reference update **completes** — `guide.md` is fully written and correct
- Every managed daemon is drained and terminated (**AC-7**)
- The application exits on its own, with no hang and no second close required
- `guide.md` is valid markdown throughout — never truncated mid-line or mid-path
- The panel log records a **clean drain** for `sandbox-a` (not a forced termination); a forced
  termination here would mean the drain gave up on an update that was still in progress

## Verification Method

- [ ] **Automated comparison**: `Verify-TestResult.ps1 -TestCase TE-E2E-036 -Workflow manage-running-linkwatcher-instances-via-control-panel` — compares `guide.md` and `archive/setup.md` against `expected/`
- [ ] **Visual inspection**: Open `guide.md` and confirm the whole file is intact, not just the link line
- [ ] **Process check**: No sandbox-a daemon and no panel process survive
- [ ] **Log check**: Panel log shows a clean drain for `sandbox-a` and no ERROR entries

## Pass Criteria

- [ ] `sandbox-a/docs/guide.md` matches `expected/` byte-for-byte — the in-flight update completed
- [ ] `sandbox-a/archive/setup.md` exists with unchanged content, and `notes/setup.md` is gone
- [ ] No file is left partially written, truncated, or containing a fragment of a path
- [ ] The panel exits by itself within the grace period, without hanging (**AC-7**)
- [ ] No sandbox-a daemon process survives and the lock file is removed
- [ ] The panel log records a clean drain, not a forced termination
- [ ] No ERROR entries in the panel log

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- **Preserve the workspace before anything else** — `guide.md` *and the daemon log* are the
  evidence, and re-running `Setup-TestEnvironment.ps1 -Clean` destroys both. Copy the workspace
  aside first. Expect the failure to be a *stale* `guide.md`, not a corrupted one: atomic writes
  mean the loss is silent (BR-7), so an intact file is not by itself a pass.
- Note whether the panel logged a clean drain or a forced termination; the two point at different
  defects (drain-completion logic vs. quiescence detection)
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect

## Notes

- **Timing sensitivity is inherent, not incidental.** If the close lands after the create, the case
  degrades into TE-E2E-035's clean stop and proves nothing about AC-8. The daemon has
  `move_detect_delay: 10`, so it holds the buffered delete for up to 10 s waiting for the create —
  closing within 1–3 seconds of the delete keeps genuinely pending work in the daemon. If the panel
  log shows the update completed **before** the close was requested, re-run the case.
- **A silent pass is the failure mode to watch for here.** The daemon writes nothing while a
  correlation is buffered, so an under-timed run looks indistinguishable from a successful one:
  both end with `guide.md` rewritten. The discriminating check is the **overlap** — the action
  script's create line must appear while the shutdown dialog is still draining. If it appears after
  the panel has exited, the run proved nothing regardless of the final file state.
- The moved file itself is not the interesting artefact — `guide.md` is. Loss shows up in the file
  being **rewritten**, not the one being moved: an untouched `guide.md` that is otherwise perfectly
  valid markdown is exactly what the PD-BUG-136 failure looks like.
- Runtime files (`panel.log`, `panel.port`) live in the panel's install directory, not the workspace.
