---
id: TE-E2G-011
type: E2E Acceptance Test Group
feature_ids: ["0.1.1", "2.2.1", "3.1.1"]
test_cases_count: 1
estimated_duration: 5 minutes
created: 2026-03-18
updated: 2026-03-18
---

# Master Test: error-recovery

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

- [ ] LinkWatcher running and monitoring workspace
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group error-recovery`
- [ ] Workspace contains pristine copies of all test fixtures
- [ ] One referencing file (`docs/readme.md`) made read-only before the move

## Quick Validation Sequence

1. **Move file when a referencing file is read-only**
   - Action: Set `docs/readme.md` read-only, then move `data/schema.md` to `reference/schema.md`
   - Tool: Command Line
   - Target: `data/schema.md`
   - Expected: `docs/guide.md` UPDATED with new path, `docs/readme.md` UNCHANGED (read-only), log contains warning/error about failed update to readme.md, LinkWatcher continues running

## Pass Criteria

- [ ] All steps above produce their expected results
- [ ] LinkWatcher log contains warning/error about the read-only file
- [ ] LinkWatcher is still running after the error (no crash)
- [ ] Run `Verify-TestResult.ps1 -Group error-recovery` shows all green

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-022 | [TE-E2E-022-read-only-referencing-file/test-case.md](TE-E2E-022-read-only-referencing-file/test-case.md) | Move file when a referencing file is read-only — error logged, other files still updated, no crash |

## Notes

After test, remember to remove the read-only attribute to allow cleanup.
