---
id: TE-E2E-039
type: Testing
category: E2E Acceptance Test Case
description: "E2E acceptance test case: config edit persists and flags restart"
group: TE-E2G-015
feature_ids: ["7.1.1", "0.1.3"]
workflow: WF-010
priority: P1
execution_mode: manual
estimated_duration: 6 minutes
source: WF-010 milestone
expected_exit_code: 0
created: 2026-08-25
updated: 2026-08-25
---

# Test Case: TE-E2E-039 config edit persists and flags restart

A project's LinkWatcher configuration is opened in the panel, one value is changed, and the change
is saved. The edit must reach disk exactly as authored — comments and untouched keys intact — and
the panel must tell the operator whether the running daemon needs restarting to pick it up.

Covers **AC-12**.

## Preconditions

- [ ] LinkWatcher is installed globally, or `LINKWATCHER_INSTALL_DIR` points at this repository
- [ ] **No other Control Panel instance is running** (see TE-E2E-034 preconditions for why)
- [ ] No LinkWatcher daemon is running for the sandbox project root
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`
- [ ] Sandbox registry seeded via `seed-sandbox.ps1 -WorkspacePath <workspace>/TE-E2E-039-config-edit-persists-and-flags-restart`

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/sandbox-a/tools/linkwatcher/linkwatcher-config.yaml` | The file edited and saved | `move_detect_delay: 10`, plus comments and other keys that must survive the round trip |
| `project/sandbox-a/docs/guide.md` | Untouched — proves the save is scoped to the config | `[Setup Notes](../notes/setup.md)` |
| `project/sandbox-a/process-framework/tools/linkWatcher/start_linkwatcher_background.ps1` | Launcher | Verbatim copy |
| `project/sandbox-a/doc/project-config.json` | Root resolution guard | `project_id: SBX-A` |

No `action.ps1`: the entire action happens inside the panel, and the disk assertion is exactly what
`Verify-TestResult.ps1` already does.

## Steps

1. **Set up the workspace**.
   - **Tool**: Command Line (repository root)
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`

2. **Seed the sandbox registry**.
   - **Tool**: Command Line
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/seed-sandbox.ps1 -WorkspacePath test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/workspace/TE-E2E-039-config-edit-persists-and-flags-restart`

3. **Open the panel and start the sandbox-a daemon from it**.
   - **Tool**: Command Line, then Control Panel window
   - **Command**: `python control_panel.py --registry "<workspace>/TE-E2E-039-config-edit-persists-and-flags-restart/sandbox-registry.json" --debug`
   - **Check**: The `sandbox-a` row reaches **running** — the restart indication only means
     something while a daemon is actually running

4. **Open the configuration pane** for the selected `sandbox-a` row.
   - **Tool**: Control Panel window
   - **Observe**: The pane shows the config file's text **including its comments**

5. **Change one value**: edit `move_detect_delay: 10` to `move_detect_delay: 15`.
   - **Tool**: Control Panel window (config pane)
   - **Target**: The `move_detect_delay` line — change nothing else

6. **Save the change**.
   - **Tool**: Control Panel window
   - **Target**: The save control (or Ctrl+S)
   - **Observe**: The panel confirms the save and indicates whether a daemon restart is required

7. **Read the restart indication** and record its exact wording.

8. **Inspect the file on disk**.
   - **Tool**: Text editor
   - **Target**: `<workspace>/.../project/sandbox-a/tools/linkwatcher/linkwatcher-config.yaml`
   - **Check**: `move_detect_delay: 15`; every comment and every other key byte-identical to before

9. **Attempt an invalid save** (negative check): change `move_detect_delay` to `not-a-number`, then save.
   - **Tool**: Control Panel window
   - **Observe**: The panel **rejects** the save with a diagnostic; the file on disk is unchanged

10. **Restore the valid value**: set `move_detect_delay: 15` again and save successfully, so the
    workspace ends in the state `expected/` describes.

11. **Close the panel** and confirm it exits.

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `sandbox-a/tools/linkwatcher/linkwatcher-config.yaml` | `move_detect_delay` | `move_detect_delay: 10` | `move_detect_delay: 15` |

Every other line of that file — comments included — is unchanged. See `expected/` for the complete
post-test file.

### Behavioral Outcomes

- The config pane displays the file's text, comments included (it is a text editor over the real
  file, not a re-serialised view)
- The save persists the edit to the project's own config file
- The panel indicates whether the running daemon must be restarted for the change to apply
- The invalid save in step 9 is **refused** and never reaches disk — the file keeps its previous
  valid contents
- The save is atomic: at no point does the file exist in a partial state
- No ERROR entries in the panel log for the successful saves (the rejected save may legitimately
  log a warning)

## Verification Method

- [ ] **Automated comparison**: `Verify-TestResult.ps1 -TestCase TE-E2E-039 -Workflow manage-running-linkwatcher-instances-via-control-panel` — compares the saved config against `expected/`
- [ ] **Visual inspection**: Comments and untouched keys survived the round trip
- [ ] **Negative check**: After step 9 the on-disk file still parses and holds `move_detect_delay: 15`
- [ ] **Log check**: Panel log records the save; no ERROR entries for the valid saves

## Pass Criteria

- [ ] `linkwatcher-config.yaml` matches `expected/` byte-for-byte after step 10
- [ ] Comments and all non-edited keys are preserved exactly
- [ ] The panel displays a restart indication after the save (**AC-12**)
- [ ] The invalid save is rejected with a diagnostic and does not modify the file
- [ ] `docs/guide.md` is unchanged — the save touched only the config
- [ ] The panel exits cleanly on close

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- If comments were stripped, capture the before/after file — that indicates the editor
  re-serialises parsed YAML instead of persisting the authored text, which silently destroys every
  project's config commentary
- If the invalid save **reached disk**, preserve the file: a config that fails to load leaves the
  project's daemon unstartable, which is the severe form of this defect
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect

## Notes

- `move_detect_delay` is chosen because it is unambiguous to verify and plainly requires a restart
  to take effect. Any other scalar key would do; the assertion is about persistence and the
  restart indication, not about this particular setting.
- The exact restart wording is recorded rather than asserted verbatim — AC-12 requires that the
  panel *indicates* the need, not that it uses a specific phrase. Record it so the next execution
  can spot an unexplained change.
- Runtime files (`panel.log`, `panel.port`) live in the panel's install directory, not the workspace.
