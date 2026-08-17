---
id: TE-E2E-032
type: Testing
category: E2E Acceptance Test Case
description: "E2E acceptance test (WF-011): TE-E2E-032 File Rename — Virtual-Root Links Updated."
group: TE-E2G-014
feature_ids: ["0.1.3", "1.1.1", "0.1.2", "2.1.1", "2.2.1"]
workflow: WF-011
priority: P2
execution_mode: scripted
estimated_duration: 5 minutes
source: Cross-cutting spec TE-TSP-046 (S-046-01, S-046-02)
expected_exit_code: 0
created: 2026-08-10
updated: 2026-08-10
---

# Test Case: TE-E2E-032 File Rename — Virtual-Root Links Updated

## Preconditions

- [ ] LinkWatcher is installed and available via `python main.py`
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow override-folder-move-virtual-root-links-updated`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] LinkWatcher started with `--config <workspace>/project/config.yaml --project-root <workspace>/project` (run.ps1 does this via the `_lib/lw-e2e-helpers.ps1` lifecycle helpers)

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/config.yaml` | Config mapping the override folder to its virtual root | `path_resolution_overrides: {blueprint: blueprint}` |
| `project/blueprint/index.md` | Override-folder file referencing the target via virtual-root link | `[Example Task](/tasks/example.md)` |
| `project/blueprint/tasks/example.md` | Target file that will be renamed | Task definition content |
| `project/outside-note.md` | Control file OUTSIDE the override folder with the byte-identical reference | `[Example Task](/tasks/example.md)` |

## Steps

1. **Start LinkWatcher**: Launch with the override config
   - **Tool**: Command Line (run.ps1 does this automatically)
   - **Command**: `python main.py --config <workspace>/project/config.yaml --project-root <workspace>/project`

2. **Wait for initial scan**: Wait for LinkWatcher to index the project
   - **Duration**: Wait 3-5 seconds for initial scan to complete
   - **Observe**: Log output confirming initial scan; both `/tasks/example.md` references indexed

3. **Rename the target file**: Add the `-task` suffix inside the override folder
   - **Tool**: run.ps1 (scripted action)
   - **Target**: `project/blueprint/tasks/example.md` renamed to `project/blueprint/tasks/example-task.md`

4. **Wait for event processing**: Allow LinkWatcher to detect and process the rename
   - **Duration**: Wait 10-12 seconds (delete+create correlation window is 10s)
   - **Observe**: Log output showing move detection and reference update in blueprint/index.md

5. **Verify blueprint/index.md IS updated with virtual-root style preserved**
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: `project/blueprint/index.md` should now contain `[Example Task](/tasks/example-task.md)` — leading slash preserved, NOT a relative path like `tasks/example-task.md` and NOT an on-disk path like `/blueprint/tasks/example-task.md`

6. **Verify outside-note.md is NOT updated**
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: `project/outside-note.md` should still contain `[Example Task](/tasks/example.md)` byte-for-byte

## Scripted Action

**Script**: `run.ps1`
**Action**: Starts a workspace-scoped LinkWatcher with the override config, renames `project/blueprint/tasks/example.md` to `example-task.md`, waits for settle, stops the instance.

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `project/blueprint/index.md` | Tasks list | `[Example Task](/tasks/example.md)` | `[Example Task](/tasks/example-task.md)` |
| `project/blueprint/tasks/example-task.md` | whole file | did not exist | EXISTS — renamed file, content unchanged |
| `project/blueprint/tasks/example.md` | whole file | existed | DELETED — renamed away |
| `project/outside-note.md` | whole file | `[Example Task](/tasks/example.md)` | UNCHANGED — byte-for-byte identical |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- Log shows move detection for example.md → example-task.md
- Log shows the `update_resolution_override_applied` event for the blueprint/index.md rewrite
- Log does NOT show any update to outside-note.md
- LinkWatcher continues running without errors until stopped by run.ps1

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-032 -Workflow override-folder-move-virtual-root-links-updated` — compares workspace against `expected/`
- [ ] **Log check**: Confirm `update_resolution_override_applied` appears in `<workspace>/linkwatcher-e2e.log` and no update is logged for outside-note.md

## Pass Criteria

- [ ] `project/blueprint/index.md` contains `[Example Task](/tasks/example-task.md)` — virtual-root (leading-slash) style preserved
- [ ] `project/outside-note.md` still contains `[Example Task](/tasks/example.md)` (byte-for-byte unchanged)
- [ ] `project/blueprint/tasks/example-task.md` exists; `project/blueprint/tasks/example.md` does not
- [ ] Log contains the `update_resolution_override_applied` event
- [ ] No errors or warnings in application log during test execution

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Save the workspace log (`linkwatcher-e2e.log`) as evidence

## Notes

- This is the founding blueprint use case: adding a `-task` suffix to a task file during blueprint restructuring. Blueprint links are written against the rollout-target root (virtual root), so without `path_resolution_overrides` the live update path cannot match them at all.
- The critical assertion is **style preservation**: a rewrite that produces a relative or on-disk path (e.g. `/blueprint/tasks/example-task.md`) would "fix" the link into a broken form for the rollout target — that is a failure even though the daemon technically updated it.
- The outside-file control guards the workflow's containment guarantee: references from files outside every override folder are never affected (TE-TSP-046 S-046-02).
