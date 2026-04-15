---
id: TE-E2G-012
type: E2E Acceptance Test Group
feature_ids: ["0.1.3", "1.1.1", "3.1.1"]
workflow: WF-006
test_cases_count: 3
estimated_duration: 15 minutes
created: 2026-04-12
updated: 2026-04-12
---

# Master Test: Configuration Behavior Adaptation

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change affecting configuration handling. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

This group validates WF-006: "Configuration change → behavior adapts" — that LinkWatcher respects configuration settings (monitored extensions, ignored directories, backup creation) and adjusts its runtime behavior accordingly.

## Preconditions

- [ ] LinkWatcher is installed and available via `python main.py`
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group configuration-behavior-adaptation`
- [ ] Workspace contains pristine copies of all test fixtures
- [ ] No other LinkWatcher instance is running

## Quick Validation Sequence

Each step uses a different config file to test a different configuration dimension. Between steps, stop LinkWatcher and reset the workspace.

1. **Monitored extensions filtering (TE-E2E-023)**
   - Action: Start LinkWatcher with config restricting `monitored_extensions` to `.md` only. Move `docs/api-guide.md` to `archive/api-guide.md`.
   - Tool: Command Line + run.ps1
   - Target: `project/docs/readme.md` (monitored) and `project/docs/references.yaml` (unmonitored)
   - Expected: `readme.md` link updated to `../archive/api-guide.md`; `references.yaml` unchanged (`.yaml` not monitored)

2. **Ignored directories exclusion (TE-E2E-024)**
   - Action: Start LinkWatcher with config adding `archive` to `ignored_directories`. Move `docs/api-guide.md` to `moved/api-guide.md`.
   - Tool: Command Line + run.ps1
   - Target: `project/docs/readme.md` (monitored dir) and `project/archive/index.md` (ignored dir)
   - Expected: `readme.md` link updated to `../moved/api-guide.md`; `archive/index.md` unchanged (ignored dir)

3. **Backup creation on update (TE-E2E-025)**
   - Action: Start LinkWatcher with `create_backups: true`. Move `docs/api-guide.md` to `archive/api-guide.md`.
   - Tool: Command Line + run.ps1
   - Target: `project/docs/readme.md` and `project/docs/readme.md.bak`
   - Expected: `readme.md` updated; `readme.md.bak` created with original content

## Pass Criteria

- [ ] All steps above produce their expected results
- [ ] No errors in application log across all three config scenarios
- [ ] Run `Verify-TestResult.ps1 -Group configuration-behavior-adaptation` shows all green

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-023 | [TE-E2E-023-custom-monitored-extensions/test-case.md](TE-E2E-023-custom-monitored-extensions/test-case.md) | Config restricts monitored_extensions to .md only; unmonitored .yaml file refs not updated |
| TE-E2E-024 | [TE-E2E-024-custom-ignored-directories/test-case.md](TE-E2E-024-custom-ignored-directories/test-case.md) | Config adds archive/ to ignored_directories; file in ignored dir not updated |
| TE-E2E-025 | [TE-E2E-025-backup-creation-enabled/test-case.md](TE-E2E-025-backup-creation-enabled/test-case.md) | Config enables create_backups; .bak files created alongside updated files |

## Notes

- Configuration is immutable after startup (no hot-reload). Each test case requires a separate LinkWatcher start with its own config file.
- All three test cases share the same basic pattern: start with config → move a file → verify that the configured behavior took effect.
- Dry-run mode is intentionally excluded from this group — it is already covered by WF-007 (TE-E2G-009).
