---
id: TE-E2E-033
type: Testing
category: E2E Acceptance Test Case
description: "E2E acceptance test (WF-011): TE-E2E-033 Directory Move — Virtual-Root Links Updated."
group: TE-E2G-014
feature_ids: ["0.1.3", "1.1.1", "0.1.2", "2.1.1", "2.2.1"]
workflow: WF-011
priority: P2
execution_mode: scripted
estimated_duration: 5 minutes
source: Cross-cutting spec TE-TSP-046 (S-046-03, S-046-02)
expected_exit_code: 0
created: 2026-08-10
updated: 2026-08-10
---

# Test Case: TE-E2E-033 Directory Move — Virtual-Root Links Updated

## Preconditions

- [ ] LinkWatcher is installed and available via `python main.py`
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow override-folder-move-virtual-root-links-updated`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] LinkWatcher started with `--config <workspace>/project/config.yaml --project-root <workspace>/project` (run.ps1 does this via the `_lib/lw-e2e-helpers.ps1` lifecycle helpers)

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/config.yaml` | Config mapping the override folder to its virtual root | `path_resolution_overrides: {blueprint: blueprint}` |
| `project/blueprint/index.md` | Override-folder file referencing two contained files via virtual-root links | `[Guide](/doc/guide.md)`, `[Reference Data](/doc/data/reference.md)` |
| `project/blueprint/doc/guide.md` | File inside the directory that will be moved | Guide content |
| `project/blueprint/doc/data/reference.md` | Nested file (one level deeper) inside the moved directory | Reference content |
| `project/outside-note.md` | Control file OUTSIDE the override folder with byte-identical references | Same two `/doc/...` links |

## Steps

1. **Start LinkWatcher**: Launch with the override config
   - **Tool**: Command Line (run.ps1 does this automatically)
   - **Command**: `python main.py --config <workspace>/project/config.yaml --project-root <workspace>/project`

2. **Wait for initial scan**: Wait for LinkWatcher to index the project
   - **Duration**: Wait 3-5 seconds for initial scan to complete
   - **Observe**: Log output confirming initial scan; all `/doc/...` references indexed

3. **Move the directory**: Rename the doc directory inside the override folder
   - **Tool**: run.ps1 (scripted action)
   - **Target**: `project/blueprint/doc/` renamed to `project/blueprint/doc-renamed/`

4. **Wait for event processing**: Allow the directory-move detector to correlate the per-file delete+create events
   - **Duration**: Wait 10-12 seconds (Windows reports directory moves as individual file events)
   - **Observe**: Log output showing directory move detection and reference updates in blueprint/index.md

5. **Verify blueprint/index.md IS updated with virtual-root style preserved**
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: `project/blueprint/index.md` should now contain `[Guide](/doc-renamed/guide.md)` and `[Reference Data](/doc-renamed/data/reference.md)` — leading slash preserved for both, including the nested file

6. **Verify outside-note.md is NOT updated**
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: `project/outside-note.md` should still contain both original `/doc/...` links byte-for-byte

## Scripted Action

**Script**: `run.ps1`
**Action**: Starts a workspace-scoped LinkWatcher with the override config, renames `project/blueprint/doc/` to `doc-renamed/`, waits for settle, stops the instance.

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `project/blueprint/index.md` | Documentation list | `[Guide](/doc/guide.md)` | `[Guide](/doc-renamed/guide.md)` |
| `project/blueprint/index.md` | Documentation list | `[Reference Data](/doc/data/reference.md)` | `[Reference Data](/doc-renamed/data/reference.md)` |
| `project/blueprint/doc-renamed/` | whole tree | did not exist | EXISTS — moved directory with guide.md and data/reference.md, contents unchanged |
| `project/blueprint/doc/` | whole tree | existed | DELETED — moved away |
| `project/outside-note.md` | whole file | two `/doc/...` links | UNCHANGED — byte-for-byte identical |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- Log shows directory move detection for blueprint/doc/ → blueprint/doc-renamed/
- Log shows the `update_resolution_override_applied` event for the blueprint/index.md rewrites
- Log does NOT show any update to outside-note.md
- LinkWatcher continues running without errors until stopped by run.ps1

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-033 -Workflow override-folder-move-virtual-root-links-updated` — compares workspace against `expected/`
- [ ] **Log check**: Confirm `update_resolution_override_applied` appears in `<workspace>/linkwatcher-e2e.log` and no update is logged for outside-note.md

## Pass Criteria

- [ ] `project/blueprint/index.md` contains `[Guide](/doc-renamed/guide.md)` — virtual-root style preserved
- [ ] `project/blueprint/index.md` contains `[Reference Data](/doc-renamed/data/reference.md)` — nested-file reference also updated, style preserved
- [ ] `project/outside-note.md` still contains both original `/doc/...` links (byte-for-byte unchanged)
- [ ] `project/blueprint/doc-renamed/data/reference.md` exists; `project/blueprint/doc/` does not
- [ ] Log contains the `update_resolution_override_applied` event
- [ ] No errors or warnings in application log during test execution

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Save the workspace log (`linkwatcher-e2e.log`) as evidence

## Notes

- This is the blueprint restructuring case: reorganizing a subdirectory of the blueprint tree. It mirrors the real-blueprint dry-run performed during the enhancement (directory move proposing 1648 reference updates with 0 errors).
- The nested file (`doc/data/reference.md`) proves the rewrite reaches references at all nesting levels inside the moved directory, through the directory-move batch path (In-Memory Link Database batch lookups).
- The outside-file control guards the workflow's containment guarantee: references from files outside every override folder are never affected (TE-TSP-046 S-046-02).
