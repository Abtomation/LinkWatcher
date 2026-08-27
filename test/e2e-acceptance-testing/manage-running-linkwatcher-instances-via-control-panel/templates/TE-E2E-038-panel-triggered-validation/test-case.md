---
id: TE-E2E-038
type: Testing
category: E2E Acceptance Test Case
description: "E2E acceptance test case: panel triggered validation"
group: TE-E2G-015
feature_ids: ["7.1.1", "6.1.1"]
workflow: WF-010
priority: P1
execution_mode: manual
estimated_duration: 6 minutes
source: WF-010 milestone
expected_exit_code: 0
created: 2026-08-25
updated: 2026-08-25
---

# Test Case: TE-E2E-038 panel triggered validation

Validation is triggered from the panel against a project seeded with exactly one broken link. The
panel must report the broken-link count and the report path — and must **not** stop that project's
running daemon while doing it.

Covers **AC-6**. Both halves matter: the count and path are read in the window; the daemon's
survival is asserted by `action.ps1`, because process liveness is a fact neither the window nor the
file comparison can establish.

## Preconditions

- [ ] LinkWatcher is installed globally, or `LINKWATCHER_INSTALL_DIR` points at this repository
- [ ] **No other Control Panel instance is running** (see TE-E2E-034 preconditions for why)
- [ ] No LinkWatcher daemon is running for the sandbox project root
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`
- [ ] Sandbox registry seeded via `seed-sandbox.ps1 -WorkspacePath <workspace>/TE-E2E-038-panel-triggered-validation`

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/sandbox-a/docs/broken.md` | Supplies exactly one broken reference | `[Missing Page](../notes/does-not-exist.md)` — target deliberately absent |
| `project/sandbox-a/docs/guide.md` | A **valid** reference, so the count is 1 and not 2 | `[Setup Notes](../notes/setup.md)` |
| `project/sandbox-a/notes/setup.md` | Makes the guide.md reference resolve | Plain markdown |
| `project/sandbox-a/tools/linkwatcher/linkwatcher-config.yaml` | Per-project config the validate run honours | monitored extensions include `.md` |
| `project/sandbox-a/process-framework/tools/linkWatcher/start_linkwatcher_background.ps1` | Launcher | Verbatim copy |
| `project/sandbox-a/doc/project-config.json` | Root resolution guard | `project_id: SBX-A` |

**File-side action**: `action.ps1 -Before` / `-After` records and re-checks the daemon PIDs around
the validation run. Not named `run.ps1` — see TE-E2E-036.

## Steps

1. **Set up the workspace**.
   - **Tool**: Command Line (repository root)
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean`

2. **Seed the sandbox registry**.
   - **Tool**: Command Line
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/seed-sandbox.ps1 -WorkspacePath test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/workspace/TE-E2E-038-panel-triggered-validation`

3. **Open the panel and start the sandbox-a daemon from it**.
   - **Tool**: Command Line, then Control Panel window
   - **Command**: `python control_panel.py --registry "<workspace>/TE-E2E-038-panel-triggered-validation/sandbox-registry.json" --debug`
   - **Check**: The `sandbox-a` row reaches **running**

4. **Record the daemon PIDs before validation**.
   - **Tool**: Command Line
   - **Command**: `pwsh.exe -ExecutionPolicy Bypass -File test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/templates/TE-E2E-038-panel-triggered-validation/action.ps1 -WorkspacePath test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/workspace/TE-E2E-038-panel-triggered-validation -Before`
   - **Check**: It reports at least one PID. If it errors with "No sandbox-a daemon is running", step 3 did not converge — do not continue.

5. **Trigger validation from the panel** for the selected `sandbox-a` row.
   - **Tool**: Control Panel window
   - **Target**: The validation control

6. **Wait for the validation run to finish**.
   - **Duration**: Up to 30 seconds for this small sandbox
   - **Observe**: The panel reports a result rather than staying busy indefinitely

7. **Read the reported result**: note the broken-link count and the report path shown by the panel.
   - **Tool**: Control Panel window

8. **Re-check the daemon PIDs after validation**.
   - **Tool**: Command Line
   - **Command**: the step 4 command with `-After` instead of `-Before`
   - **Check**: It prints `PASS` — every recorded PID is still alive

9. **Open the report file** at the path the panel reported.
   - **Tool**: Text editor
   - **Check**: It names `docs/broken.md` and the unresolved target `does-not-exist.md`

10. **Confirm the row is still running** in the panel, then close the panel and confirm it exits.

## Expected Results

### File Changes

No changes to project content — validation is read-only. See `expected/` for `guide.md`,
`broken.md` and `setup.md` asserted unchanged.

The broken-link report is a **new** file written under the sandbox project's
`logs/linkwatcher/` directory. It is a run artefact, not in `expected/`, and correctly ignored by
the comparison.

### Behavioral Outcomes

- The panel reports a broken-link count of exactly **1**
- The panel reports a **report path**, and a file exists at that path
- The report names `docs/broken.md` as the source and the missing target
- The `sandbox-a` daemon is **still running** after the validation run — same PIDs (**AC-6**)
- The row continues to render as running; validation never flips it to stopped
- The panel reports a *result*, not a failure state — a `failed` state here would mean the run
  never completed its scan
- No ERROR entries in the panel log

## Verification Method

- [ ] **Automated comparison**: `Verify-TestResult.ps1 -TestCase TE-E2E-038 -Workflow manage-running-linkwatcher-instances-via-control-panel` — confirms validation changed no content file
- [ ] **Liveness assertion**: `action.ps1 -After` prints `PASS`
- [ ] **Report inspection**: The report at the reported path names `broken.md` and its missing target
- [ ] **Visual inspection**: Count and path are both displayed in the window
- [ ] **Log check**: Panel log has no ERROR entries

## Pass Criteria

- [ ] The panel reports exactly **1** broken link
- [ ] The panel reports a report path, and a report file exists there
- [ ] The report identifies `docs/broken.md` and the unresolved target
- [ ] `action.ps1 -After` reports `PASS` — no recorded daemon PID disappeared (**AC-6**)
- [ ] The `sandbox-a` row still shows as running after validation
- [ ] All files in `expected/` match the workspace byte-for-byte
- [ ] No ERROR entries in the panel log

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- If the panel reported a count with **no** report path, or a path with no file, capture the panel
  log — resolving the path and evidencing the run are separate concerns and the failure names which
- If the daemon disappeared, that is the AC-6 defect; capture the panel log around the validation
  subprocess before re-running
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect

## Notes

- A count of 1 depends on `guide.md`'s reference resolving. If validation reports 2, check that
  `notes/setup.md` survived setup — a missing fixture inflates the count and masks the real result.
- The panel derives the count from the report file's summary line and the path from the validate
  run's stdout, and requires positive evidence from *this* run that the scan completed. A stale
  report from an earlier run must never be presented as a result.
- Runtime files (`panel.log`, `panel.port`) live in the panel's install directory, not the workspace.
