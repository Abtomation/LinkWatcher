---
id: TE-E2G-006
type: E2E Acceptance Test Group
feature_ids: ["0.1.1", "0.1.2", "0.1.3", "1.1.1", "2.1.1", "2.2.1"]
workflow: WF-003
test_cases_count: 1
estimated_duration: 5 minutes
created: 2026-03-18
updated: 2026-03-18
---

# Master Test: startup-operations

## Purpose

Quick validation sequence covering startup-related test cases. Tests that LinkWatcher correctly handles file operations that occur during its startup/initialization phase.

Run this FIRST after a code change affecting startup behavior. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

- [ ] LinkWatcher is running (it will be stopped and restarted by the test)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group startup-operations`
- [ ] Workspace contains pristine copies of all test fixtures

## Quick Validation Sequence

1. **File operations during startup (TE-E2E-012)**
   - Action: Stop LW, create `docs/guide.md` referencing `settings/config.yaml`, restart LW, immediately move `settings/config.yaml` to `config/config.yaml`
   - Tool: Command Line or scripted via `run.ps1`
   - Target: `TE-E2E-012-file-operations-during-startup/project/`
   - Expected: After 15s, `README.md` link updated from `settings/config.yaml` to `config/config.yaml`, and `docs/guide.md` link updated from `../settings/config.yaml` to `../config/config.yaml`

## Pass Criteria

- [ ] All steps above produce their expected results
- [ ] No errors or crashes in LinkWatcher log during startup + move sequence
- [ ] LinkWatcher is running after the test completes
- [ ] Run `Verify-TestResult.ps1 -Group startup-operations` shows all green

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-012 | [TE-E2E-012-file-operations-during-startup/test-case.md](TE-E2E-012-file-operations-during-startup/test-case.md) | Stop LW, start LW, create file with references during startup, move referenced file — verify updates after startup completes |
| TE-E2E-015 | [TE-E2E-015-startup-custom-config-excludes/test-case.md](TE-E2E-015-startup-custom-config-excludes/test-case.md) | Startup with custom config excluding a directory — excluded files not scanned or monitored |

## Notes

- This group tests race conditions between LW startup scanning and file operations
- If tests fail intermittently, it may indicate a timing issue rather than a fundamental bug — increase wait times and re-test
- **Important**: These tests stop and restart LinkWatcher. Run them LAST to avoid disrupting other test groups
- After running this group, verify LinkWatcher is running for subsequent work

