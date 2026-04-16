---
id: TE-E2G-009
type: E2E Acceptance Test Group
feature_ids: ["0.1.3", "0.1.1", "2.2.1", "3.1.1"]
workflow: WF-007
test_cases_count: 1
estimated_duration: 5 minutes
created: 2026-03-18
updated: 2026-03-18
---

# Master Test: dry-run-mode

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

- [ ] LinkWatcher started with `--dry-run` flag
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group dry-run-mode`
- [ ] Workspace contains pristine copies of all test fixtures

## Quick Validation Sequence

1. **Move file in dry-run mode — verify no changes applied**
   - Action: Move `docs/api-guide.md` to `archive/api-guide.md`
   - Tool: File Explorer
   - Target: `docs/api-guide.md`
   - Expected: `docs/readme.md` is UNCHANGED (still `[API Guide](api-guide.md)`), log shows dry-run message indicating what would have been updated

## Pass Criteria

- [ ] All steps above produce their expected results
- [ ] No errors in LinkWatcher log (dry-run messages are informational, not errors)
- [ ] Run `Verify-TestResult.ps1 -Group dry-run-mode` shows all green

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-019 | [TE-E2E-019-move-file-dry-run-no-changes/test-case.md](TE-E2E-019-move-file-dry-run-no-changes/test-case.md) | Move file in dry-run mode — log shows what would be updated but files are unchanged |

## Notes

LinkWatcher must be started with --dry-run for this test. The file is physically moved, only the link updates are skipped.
