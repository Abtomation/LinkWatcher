---
id: TE-E2G-014
description: "E2E acceptance test (WF-011): override-folder move — virtual-root links updated."
type: Testing
category: E2E Acceptance Test Group
feature_ids: ["0.1.3", "1.1.1", "0.1.2", "2.1.1", "2.2.1"]
workflow: WF-011
test_cases_count: 2
estimated_duration: 10 minutes
created: 2026-08-10
updated: 2026-08-10
---

# Master Test: override-folder-move-virtual-root-links-updated

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change to override-aware resolution (2.2.1 blueprint-aware reference updating). If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

- [ ] LinkWatcher is installed (`pip install -e .` from project root)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow override-folder-move-virtual-root-links-updated`
- [ ] Workspace contains pristine copies of all test fixtures
- [ ] No other LinkWatcher instance is running against the workspace (each run.ps1 starts its own workspace-scoped instance with the test's `path_resolution_overrides` config)

## Quick Validation Sequence

1. **File rename inside the override folder (TE-E2E-032)**
   - Action: Run `Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-032" -Workflow "override-folder-move-virtual-root-links-updated"` (run.ps1 starts LinkWatcher with `project/config.yaml`, renames `blueprint/tasks/example.md` → `example-task.md`, settles, stops)
   - Tool: Command Line
   - Target: TE-E2E-032 fixtures (override folder `blueprint/`, virtual-root link in `blueprint/index.md`, control file `outside-note.md`)
   - Expected: `blueprint/index.md` link rewritten to `/tasks/example-task.md` (leading-slash virtual-root style preserved); `outside-note.md` byte-for-byte unchanged; log contains `update_resolution_override_applied`

2. **Directory move inside the override folder (TE-E2E-033)**
   - Action: Run `Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-033" -Workflow "override-folder-move-virtual-root-links-updated"` (run.ps1 starts LinkWatcher with `project/config.yaml`, renames `blueprint/doc/` → `blueprint/doc-renamed/`, settles, stops)
   - Tool: Command Line
   - Target: TE-E2E-033 fixtures (two virtual-root links in `blueprint/index.md` incl. one to a nested file, control file `outside-note.md`)
   - Expected: both links rewritten to `/doc-renamed/...` preserving virtual-root style (nested file included); `outside-note.md` byte-for-byte unchanged; log contains `update_resolution_override_applied`

## Pass Criteria

- [ ] All steps above produce their expected results
- [ ] Rewrites preserve the host-absolute `/…` style — a relative or on-disk-path rewrite is a FAIL even though the link was "updated"
- [ ] Files outside the override folder are never modified
- [ ] No errors in application log
- [ ] `Verify-TestResult.ps1` shows all green for both test cases

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-032 | [TE-E2E-032-file-rename-virtual-root-links/test-case.md](TE-E2E-032-file-rename-virtual-root-links/test-case.md) | Rename a file inside a path_resolution_overrides folder; sibling virtual-root links rewritten preserving style, outside file untouched |
| TE-E2E-033 | [TE-E2E-033-directory-move-virtual-root-links/test-case.md](TE-E2E-033-directory-move-virtual-root-links/test-case.md) | Move a directory inside a path_resolution_overrides folder; virtual-root links to contained files rewritten preserving style, outside file untouched |

## Notes

- The override-aware behavior is config-driven: both cases start LinkWatcher with `--config project/config.yaml` carrying `path_resolution_overrides: {blueprint: blueprint}`. Without that key the daemon must leave the virtual-root links alone (v1.0 behavior) — a rewrite without the config would itself be a defect.
- Resolver-internal guard scenarios (non-existent target, separator preservation, suffix-hijack gate) are deliberately covered at unit level only — see [TE-TSP-046](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-override-folder-move-scenarios.md).
