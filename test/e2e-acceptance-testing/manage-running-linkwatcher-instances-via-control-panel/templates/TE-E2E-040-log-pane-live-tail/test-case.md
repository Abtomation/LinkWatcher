---
id: TE-E2E-040
type: Testing
category: E2E Acceptance Test Case
description: "E2E acceptance test case: log pane live tail"
group: TE-E2G-015
feature_ids: ["7.1.1"]
workflow: WF-010
priority: P2
execution_mode: manual
estimated_duration: 5 minutes
source: WF-010 milestone
expected_exit_code: 0
created: 2026-08-25
updated: 2026-08-25
---

# Test Case: TE-E2E-040 log pane live tail

The log pane shows the selected daemon's recent entries and keeps up as the daemon writes more. The
"keeps up" half is what distinguishes a live tail from a one-shot file read, so the test provokes
new entries **while the pane is open** and watches them arrive.

Covers **AC-5**.

## Preconditions

- [ ] LinkWatcher is installed globally, or `LINKWATCHER_INSTALL_DIR` points at this repository
- [ ] **No other Control Panel instance is running** (see TE-E2E-034 preconditions for why)
- [ ] No LinkWatcher daemon is running for the sandbox project root
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`
- [ ] Sandbox registry seeded via `seed-sandbox.ps1 -WorkspacePath <workspace>/TE-E2E-040-log-pane-live-tail`

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/sandbox-a/docs/guide.md` | Reference source; edited during the test to provoke log activity | `[Setup Notes](../notes/setup.md)` |
| `project/sandbox-a/notes/setup.md` | Reference target | Plain markdown |
| `project/sandbox-a/tools/linkwatcher/linkwatcher-config.yaml` | Daemon config; `.md` monitored so edits generate log entries | monitored extensions include `.md` |
| `project/sandbox-a/process-framework/tools/linkWatcher/start_linkwatcher_background.ps1` | Launcher | Verbatim copy |
| `project/sandbox-a/doc/project-config.json` | Root resolution guard | `project_id: SBX-A` |

No `action.ps1`: the provoking edit is a single deliberate action a human performs directly, and
doing it by hand is what makes the arrival visible in real time.

## Steps

1. **Set up the workspace**.
   - **Tool**: Command Line (repository root)
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`

2. **Seed the sandbox registry**.
   - **Tool**: Command Line
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/seed-sandbox.ps1 -WorkspacePath test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/workspace/TE-E2E-040-log-pane-live-tail`

3. **Open the panel and start the sandbox-a daemon from it**.
   - **Tool**: Command Line, then Control Panel window
   - **Command**: `python control_panel.py --registry "<workspace>/TE-E2E-040-log-pane-live-tail/sandbox-registry.json" --debug`
   - **Check**: The `sandbox-a` row reaches **running**

4. **Open the log pane** for the selected `sandbox-a` row.
   - **Tool**: Control Panel window
   - **Observe**: Entries from the daemon's startup and initial scan are already visible — the pane
     shows **recent history**, not only what arrives from now on

5. **Note the last visible entry**: record its text or timestamp. This is the baseline for step 7.

6. **Provoke new log activity while the pane stays open**: edit and save a monitored file.
   - **Tool**: Text editor
   - **Target**: `<workspace>/.../project/sandbox-a/docs/guide.md` — append a line such as
     `Appended during TE-E2E-040.` and save
   - **Do not** close or reopen the log pane

7. **Watch the pane**.
   - **Duration**: Up to 10 seconds
   - **Observe**: New entries appear **below** the baseline entry from step 5, without any manual
     refresh, reopening, or row re-selection

8. **Provoke a second batch**: save the file again with another appended line, and confirm the pane
   updates a second time — one update could be coincidence.

9. **Close the panel** and confirm it exits.

## Expected Results

### File Changes

`docs/guide.md` is deliberately edited during this test and therefore ends **different** from its
starting state. It is not asserted by comparison here — the appended text is chosen freely by the
operator, so `expected/` holds only `notes/setup.md`, which must remain untouched.

No reference rewrite should occur: nothing was moved or renamed, only edited.

### Behavioral Outcomes

- Opening the pane shows **existing recent entries**, not an empty view
- New entries appear automatically after each save, with no manual refresh
- Entries arrive in order and are appended at the end of the view
- The pane stays responsive; the window does not freeze while tailing
- The entries shown belong to the **selected** project's daemon
- `notes/setup.md` is untouched — an edit is not a move and must not trigger a rewrite

## Verification Method

- [ ] **Automated comparison**: `Verify-TestResult.ps1 -TestCase TE-E2E-040 -Workflow manage-running-linkwatcher-instances-via-control-panel` — confirms `notes/setup.md` was not rewritten
- [ ] **Visual inspection**: New entries appeared twice, unprompted, below the recorded baseline
- [ ] **Cross-check**: The pane's newest entries match the tail of the daemon's log file under `sandbox-a/logs/linkwatcher/`
- [ ] **Log check**: Panel log has no ERROR entries

## Pass Criteria

- [ ] The pane shows recent entries immediately on open (**AC-5**, history half)
- [ ] New entries appear automatically after the step 6 save, within 10 seconds
- [ ] New entries appear again after the step 8 save (**AC-5**, live half)
- [ ] The pane content matches the tail of the daemon's own log file
- [ ] `notes/setup.md` matches `expected/` byte-for-byte
- [ ] No ERROR entries in the panel log

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- If history shows but nothing new arrives, the pane is doing a one-shot read rather than a tail —
  note whether reopening the pane reveals the missing entries, which distinguishes a polling defect
  from a rendering one
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect

## Notes

- The daemon must actually log on a file save. If nothing appears in the underlying log file either,
  the defect is not in the pane — check that `.md` is in the project's `monitored_extensions`
  before filing against the panel.
- Log rotation mid-test is not expected at this scale, but the pane is designed to reattach after
  one; if a rotation happens, entries should continue rather than stop.
- Runtime files (`panel.log`, `panel.port`) live in the panel's install directory, not the workspace.
