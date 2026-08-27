---
id: TE-E2G-015
type: Testing
category: E2E Acceptance Test Group
feature_ids: ["7.1.1", "2.2.1", "0.1.2", "6.1.1", "0.1.3"]
workflow: WF-010
test_cases_count: 8
estimated_duration: 20 minutes
created: 2026-08-25
updated: 2026-08-25
---

# Master Test: manage-running-linkwatcher-instances-via-control-panel

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

The sequence runs in three phases because two scenarios need a workspace in a specific starting
state: the drain-with-in-flight-move (phase 2) and the forced-terminate-under-churn (phase 3) each
consume their own pristine workspace and cannot follow other actions in the same one.

## Coverage and its one deliberate gap

This group covers **11 of the feature's 12 acceptance criteria**: AC-1 … AC-10, AC-12, and the
second clause of AC-11.

**AC-11's first clause — the panel opening automatically when the `SessionStart` hook starts a
daemon — is deliberately uncovered.** That behaviour is not currently delivered: it was
live-verified on 2026-08-10, silently reverted by the 2026-08-14 framework rollout, and is
re-tracked as PF-IMP-2032. FR-8, UI-7 and BR-8 stay UNMET alongside it. **Do not author an
auto-open case before that IMP lands — it cannot pass.** When it does land, add a new case to this
group and extend the sequence below with an auto-open step.

## Preconditions

- [ ] LinkWatcher is installed globally, or `LINKWATCHER_INSTALL_DIR` points at this repository
- [ ] **No other Control Panel instance is running**, and no stale `panel.port` remains in the
      panel's install directory — the single-instance guard would otherwise surface an unrelated
      window and every observation below would be about the wrong panel
- [ ] No LinkWatcher daemon is running for any sandbox project root
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`
- [ ] Each phase's workspace seeded via `seed-sandbox.ps1 -WorkspacePath <workspace>/<case-dir>`
- [ ] The repository's own daemon may keep running — `e2e-acceptance-testing` is in its
      `ignored_directories`, so the workspace is invisible to it

## Quick Validation Sequence

### Phase 1 — supervision, panes and lifecycle (workspace: `TE-E2E-034-panel-lists-running-daemons`)

1. **Start one daemon outside the panel, then open the panel** (TE-E2E-034)
   - Action: Run sandbox-a's own launcher directly, then launch the panel against the seeded registry
   - Tool: Command Line
   - Target: `<workspace>/TE-E2E-034-.../project/sandbox-a/process-framework/tools/linkWatcher/start_linkwatcher_background.ps1`, then `python control_panel.py --registry "<workspace>/TE-E2E-034-.../sandbox-registry.json" --debug`
   - Expected: A wait state while discovery runs, then exactly two rows — `sandbox-a` **running**, `sandbox-b` **stopped**. No real registered project appears.

2. **Start the second project from the panel, then attempt a duplicate start** (TE-E2E-035)
   - Action: Select `sandbox-b`, start it; once running, trigger start again
   - Tool: Control Panel window
   - Target: Start control
   - Expected: `sandbox-b` reaches running within 30 s; the second start adds **no** process (or the control is disabled). Each daemon is a process *pair* — that is the expected process model, not a duplicate.

3. **Watch the log pane update live** (TE-E2E-040)
   - Action: Open the log pane for `sandbox-b`, note the last entry, then create `docs/tail-probe.md` in that
     project with a line of text and save
   - Tool: Control Panel window + text editor
   - Target: `<workspace>/TE-E2E-034-.../project/sandbox-b/docs/tail-probe.md` — a **new** file, chosen
     deliberately because this phase runs in TE-E2E-034's workspace and that case's `expected/` asserts
     `sandbox-b/docs/guide.md` unchanged. Editing `guide.md` here would make the Verify pass criterion
     below fail every run.
   - Expected: Existing entries visible on open; new entries appear below the noted baseline within 10 s, with no manual refresh

4. **Edit and save a config, and read the restart indication** (TE-E2E-039)
   - Action: Open sandbox-b's config pane, change `move_detect_delay: 10` to `15`, save
   - Tool: Control Panel window
   - Target: Config pane, `move_detect_delay` line
   - Expected: Save succeeds; the on-disk file shows `15` with all comments intact; the panel indicates whether a restart is required

5. **Trigger validation and confirm the daemon survives it** (TE-E2E-038)
   - Action: With `sandbox-b` selected and running, trigger validation; record the daemon PIDs before and after
   - Tool: Control Panel window + Command Line
   - Target: Validation control
   - Expected: A broken-link **count** and a **report path** are reported, a file exists at that path, and the daemon PIDs are unchanged. In this workspace the fixtures are all valid, so the expected count is **0**; the seeded broken link lives in TE-E2E-038's own workspace.

6. **Stop a daemon from the panel** (TE-E2E-035)
   - Action: Stop `sandbox-a` — the one the panel did not start (AC-4)
   - Tool: Control Panel window
   - Expected: Row reaches stopped, the process pair is gone, `.linkwatcher.lock` removed

7. **Confirm a second launch surfaces the existing window** (TE-E2E-041)
   - Action: Send the window behind another, then run the identical panel command from a second terminal
   - Tool: Command Line
   - Expected: The existing window comes to the front with its position and contents preserved; the second process prints a message and exits; still exactly one panel process, same PID

8. **Close the panel** and confirm every remaining managed daemon is drained and the app exits by itself (AC-7)

### Phase 2 — clean drain of an in-flight update (workspace: `TE-E2E-036-close-panel-drains-in-flight-move`)

9. **Close the panel with a reference update in flight** (TE-E2E-036)
   - Action: Open the panel against this workspace, start `sandbox-a`, let it settle 5 s, run this case's `action.ps1`, then close the window within 1–2 seconds
   - Tool: Command Line + Control Panel window
   - Target: `TE-E2E-036-close-panel-drains-in-flight-move/action.ps1`
   - Expected: The shutdown dialog appears, the drain lets the update finish, the app exits by itself, and `docs/guide.md` reads `[Setup Notes](../archive/setup.md)` — complete and uncorrupted. The panel log records a **clean drain**, not a forced stop.

### Phase 3 — forced terminate at grace expiry (workspace: `TE-E2E-037-forced-terminate-on-grace-expiry`)

10. **Close the panel against a daemon that never goes quiet** (TE-E2E-037)
    - Action: Open the panel against this workspace, start `sandbox-a`, start this case's churn writer, then close the window while churn is active; stop the churn writer afterwards with `-Stop`
    - Tool: Command Line + Control Panel window
    - Target: `TE-E2E-037-forced-terminate-on-grace-expiry/action.ps1`
    - Expected: The drain does not complete, the panel force-terminates at grace expiry and **visibly reports** the forced stop, the app exits within roughly the grace period plus a small margin, and `docs/guide.md` and `notes/setup.md` are intact

## Pass Criteria

- [ ] All steps above produce their expected results
- [ ] No ERROR entries in the panel log across all three phases (a warning for the forced stop in step 10 is expected and required)
- [ ] The panel exits by itself in steps 8, 9 and 10 — never hanging, never needing a manual kill
- [ ] No sandbox daemon process survives any phase, and every `.linkwatcher.lock` is removed
- [ ] `Verify-TestResult.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel` shows all green for the cases whose workspaces this sequence used (TE-E2E-034, TE-E2E-036, TE-E2E-037)
- [ ] No file in any sandbox project is left truncated or partially written

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-034 | [TE-E2E-034-panel-lists-running-daemons/test-case.md](TE-E2E-034-panel-lists-running-daemons/test-case.md) | Panel lists daemons for a two-project sandbox registry, including a daemon started outside the panel |
| TE-E2E-035 | [TE-E2E-035-start-and-stop-daemon-from-panel/test-case.md](TE-E2E-035-start-and-stop-daemon-from-panel/test-case.md) | Start a daemon from the panel, stop it, and confirm a second start creates no duplicate daemon |
| TE-E2E-036 | [TE-E2E-036-close-panel-drains-in-flight-move/test-case.md](TE-E2E-036-close-panel-drains-in-flight-move/test-case.md) | Closing the panel with a file move in flight drains the daemon so the reference update completes uncorrupted |
| TE-E2E-037 | [TE-E2E-037-forced-terminate-on-grace-expiry/test-case.md](TE-E2E-037-forced-terminate-on-grace-expiry/test-case.md) | A daemon that never reaches quiescence is force-terminated at grace expiry and the panel still exits |
| TE-E2E-038 | [TE-E2E-038-panel-triggered-validation/test-case.md](TE-E2E-038-panel-triggered-validation/test-case.md) | Panel-triggered validation reports the broken-link count and report path without stopping the running daemon |
| TE-E2E-039 | [TE-E2E-039-config-edit-persists-and-flags-restart/test-case.md](TE-E2E-039-config-edit-persists-and-flags-restart/test-case.md) | Editing and saving a project config from the panel persists the change and flags that a restart is required |
| TE-E2E-040 | [TE-E2E-040-log-pane-live-tail/test-case.md](TE-E2E-040-log-pane-live-tail/test-case.md) | The log pane shows recent entries for the selected daemon and appends new entries as they are written |
| TE-E2E-041 | [TE-E2E-041-second-launch-surfaces-existing-window/test-case.md](TE-E2E-041-second-launch-surfaces-existing-window/test-case.md) | A second panel launch surfaces the existing window instead of opening a duplicate |

## Notes

- **Every case in this group is `execution_mode: manual`.** The subject is a desktop window, so a
  human drives it. Four cases carry an `action.ps1` for the file-side half only (the in-flight
  move, the churn writer, the daemon-liveness witness). These are deliberately **not** named
  `run.ps1`: `Run-E2EAcceptanceTest.ps1` classifies a case as fully scripted by the presence of
  `run.ps1` and would execute these unattended with no panel open, producing a false verdict.
- **Hermetic in the registry, not in the panel's own runtime files.** `--registry` points the panel
  at a sandbox registry inside the workspace, so the operator's real projects are never touched.
  But `panel-config.yaml`, `panel.log` and `panel.port` resolve against the panel's **install
  directory**. Clean up a stale `panel.port` between runs.
- **The sandbox root guard is load-bearing.** Each sandbox project carries its own
  `doc/project-config.json`. Without it, the launcher walks up looking for one and resolves the
  **real LinkWatcher repository** as the project root — starting a daemon over the whole repo.
  `seed-sandbox.ps1` refuses to seed a sandbox missing that file; do not work around it.
- Daemons started here run from the **global install** (`~/bin`), not this repository's `src/`. Set
  `LINKWATCHER_INSTALL_DIR` to the repository root to exercise repository source instead.
- A healthy daemon is **two** processes (venv shim parent + real interpreter) with identical
  command lines. A process count is never an instance count.
