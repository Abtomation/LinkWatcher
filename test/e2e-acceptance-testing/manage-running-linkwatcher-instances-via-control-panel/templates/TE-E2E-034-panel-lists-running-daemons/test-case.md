---
id: TE-E2E-034
type: Testing
category: E2E Acceptance Test Case
description: "E2E acceptance test case: panel lists running daemons"
group: TE-E2G-015
feature_ids: ["7.1.1"]
workflow: WF-010
priority: P0
execution_mode: manual
estimated_duration: 6 minutes
source: WF-010 milestone
expected_exit_code: 0
created: 2026-08-25
updated: 2026-08-25
---

# Test Case: TE-E2E-034 panel lists running daemons

The panel opens against a two-project sandbox registry where one project already has a daemon
running — started **outside** the panel, by the project's own launcher, exactly as the
`SessionStart` hook starts one. The panel must list both projects with correct identity, show the
running one as running and the other as stopped, and offer the running one for stopping.

Covers **AC-1** (lists running daemons with correct identity and status) and **AC-4** (a daemon the
panel did not start appears in the list and is stoppable from the panel).

## Preconditions

- [ ] LinkWatcher is installed globally, or `LINKWATCHER_INSTALL_DIR` points at this repository
- [ ] **No other Control Panel instance is running** — the single-instance guard would surface the
      existing window and exit, and the test would silently observe the wrong panel
      (check: no `control_panel.py` / `pythonw.exe` panel process; delete a stale `panel.port`
      in the install directory if one remains)
- [ ] No LinkWatcher daemon is running for either sandbox project root
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`
- [ ] Sandbox registry seeded via `seed-sandbox.ps1 -WorkspacePath <workspace>/TE-E2E-034-panel-lists-running-daemons`
- [ ] Workspace contains a pristine copy of this test case's fixtures

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/sandbox-a/doc/project-config.json` | Makes sandbox-a a resolvable project root | `project_id: SBX-A` — **load-bearing**: without it the launcher walks up and resolves the real repository |
| `project/sandbox-a/process-framework/tools/linkWatcher/start_linkwatcher_background.ps1` | The launcher the panel shells out to (D-T4) | Verbatim copy of this repository's launcher |
| `project/sandbox-a/tools/linkwatcher/linkwatcher-config.yaml` | Per-project daemon config | Small monitored-extension and ignored-directory set |
| `project/sandbox-a/docs/guide.md` | Reference source — the no-corruption witness | `[Setup Notes](../notes/setup.md)` |
| `project/sandbox-a/notes/setup.md` | Reference target | Plain markdown |
| `project/sandbox-b/**` | Second registered project, deliberately left stopped | Same shape, `project_id: SBX-B` |

The sandbox registry itself is **generated at test time** by `seed-sandbox.ps1` — it must carry
absolute project roots, so it cannot be a static fixture.

## Steps

1. **Set up the workspace**: Copy pristine fixtures.
   - **Tool**: Command Line (repository root)
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`

2. **Seed the sandbox registry**: Generate `sandbox-registry.json` with absolute roots.
   - **Tool**: Command Line
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/seed-sandbox.ps1 -WorkspacePath test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/workspace/TE-E2E-034-panel-lists-running-daemons`
   - **Observe**: The script prints `SBX-001 sandbox-a` and `SBX-002 sandbox-b` with absolute paths, and the exact panel command to use in step 4.

3. **Start sandbox-a's daemon from outside the panel**: Run that project's own launcher directly.
   - **Tool**: Command Line
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File <workspace>/TE-E2E-034-panel-lists-running-daemons/project/sandbox-a/process-framework/tools/linkWatcher/start_linkwatcher_background.ps1`
   - **Check**: The launcher reports a started daemon and prints its PID. Confirm `<workspace>/.../project/sandbox-a/.linkwatcher.lock` now exists.
   - **⚠️ Verify the resolved root**: the launcher banner must name the **sandbox-a** path. If it
     names the LinkWatcher repository, stop — `doc/project-config.json` is missing from the fixture.

4. **Open the panel against the sandbox registry**.
   - **Tool**: Command Line (repository root)
   - **Command**: `python control_panel.py --registry "<workspace>/TE-E2E-034-panel-lists-running-daemons/sandbox-registry.json" --debug`

5. **Wait for the first discovery pass to land**.
   - **Duration**: Up to 10 seconds — a cold `psutil` pass has been measured at 7.5 s on a busy machine
   - **Observe**: The list shows **"Discovering daemons…"** first, and must never claim
     "No registered projects found." while discovery is still pending

6. **Read the daemon list**: Inspect both rows.
   - **Tool**: Control Panel window
   - **Target**: The project list pane

7. **Select the sandbox-a row and confirm the stop control is offered**.
   - **Tool**: Control Panel window
   - **Target**: Toolbar / row actions — do **not** click stop yet

8. **Stop sandbox-a from the panel**: Click the stop control.
   - **Tool**: Control Panel window
   - **Observe**: The row moves through a transitional state to stopped

9. **Verify the daemon really terminated**.
   - **Tool**: Command Line
   - **Check**: No `python` process remains whose command line contains the sandbox-a root, and
     `sandbox-a/.linkwatcher.lock` has been removed

10. **Close the panel** and confirm the process exits.

## Expected Results

### File Changes

No file changes. No move or rename is performed, so no reference is rewritten.

See `expected/` for the content files asserted unchanged (`sandbox-a` and `sandbox-b`
`docs/guide.md` and `notes/setup.md`). Daemon runtime artefacts (`logs/`, `.linkwatcher.lock`)
appear in the workspace and are correctly ignored by the comparison.

### Behavioral Outcomes

- The list shows **exactly two** rows — `sandbox-a` and `sandbox-b` — and no other project;
  the operator's real registered projects never appear
- `sandbox-a` renders as **running**, with the PID recorded in its lock file
- `sandbox-b` renders as **stopped**
- The wait state (`Discovering daemons…`) is shown before the first poll lands, never an
  empty-registry claim
- Selecting the externally started `sandbox-a` enables the stop control (**AC-4**)
- Stopping it terminates the daemon pair and removes the lock file
- The panel log records the registry resolving via source `cli`

## Verification Method

- [ ] **Automated comparison**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Verify-TestResult.ps1 -TestCase TE-E2E-034 -Workflow manage-running-linkwatcher-instances-via-control-panel` — confirms no content file was rewritten
- [ ] **Visual inspection**: Both rows, their identity and their status, read as described above
- [ ] **Process check**: `Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*sandbox-a*' }` returns nothing after step 9
- [ ] **Log check**: Panel log contains `registry resolved via cli` and no ERROR entries

## Pass Criteria

- [ ] Exactly two rows are listed, named `sandbox-a` and `sandbox-b`
- [ ] `sandbox-a` shows as running and `sandbox-b` as stopped, before any panel action
- [ ] The pending-discovery wait state is shown rather than a false empty-registry message
- [ ] The externally started daemon can be stopped from the panel (**AC-4**)
- [ ] After the stop, no sandbox-a daemon process survives and the lock file is gone
- [ ] All files in `expected/` match the workspace byte-for-byte
- [ ] No ERROR entries in the panel log during the run

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- If the panel listed the operator's **real** projects, the `--registry` argument did not take —
  capture the panel log line reporting the resolution source before anything else
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect

## Notes

- The daemon started here runs from the **global install** (`~/bin`), not this repository's `src/`.
  To exercise repository source instead, set `LINKWATCHER_INSTALL_DIR` to the repository root
  before step 3.
- The panel writes `panel.log`, `panel.port` and reads `panel-config.yaml` from its **install
  directory**, not the workspace — these cases are hermetic in their *registry and projects*, not
  in the panel's own runtime files. Clean up a stale `panel.port` between runs.
- The repository's own daemon may keep running throughout: `e2e-acceptance-testing` is in its
  `ignored_directories`, so the workspace is invisible to it.
