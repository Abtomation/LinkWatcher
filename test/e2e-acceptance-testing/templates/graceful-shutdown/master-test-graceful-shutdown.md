---
id: TE-E2G-010
type: E2E Acceptance Test Group
feature_ids: ["0.1.1, 2.2.1, 0.1.2"]
workflow: WF-008
test_cases_count: 2
estimated_duration: 6 minutes
created: 2026-03-18
updated: 2026-03-18
---

# Master Test: graceful-shutdown

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

- [ ] LinkWatcher running and monitoring workspace
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group graceful-shutdown`
- [ ] Workspace contains pristine copies of all test fixtures

## Quick Validation Sequence

1. **Stop LinkWatcher during idle state**
   - Action: Wait for LinkWatcher to reach idle state (5 seconds after startup), then stop it
   - Tool: Command Line
   - Target: LinkWatcher process
   - Expected: Clean shutdown, no error messages, process exits with code 0, all files unchanged

2. **Stop LinkWatcher immediately after a file move**
   - Action: Reset environment, move `docs/report.md` to `archive/report.md`, immediately stop LinkWatcher
   - Tool: Command Line
   - Target: `docs/report.md` then LinkWatcher process
   - Expected: `docs/readme.md` is either fully updated (`[Report](../archive/report.md)`) or completely untouched (`[Report](report.md)`) — no partial/corrupted state

## Pass Criteria

- [ ] All steps above produce their expected results
- [ ] No errors in LinkWatcher log (warnings about interrupted operations are acceptable)
- [ ] Run `Verify-TestResult.ps1 -Group graceful-shutdown` shows all green

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-020 | [TE-E2E-020-stop-during-idle/test-case.md](TE-E2E-020-stop-during-idle/test-case.md) | Stop LinkWatcher during idle — clean shutdown, no errors, no corrupted files |
| TE-E2E-021 | [TE-E2E-021-stop-immediately-after-move/test-case.md](TE-E2E-021-stop-immediately-after-move/test-case.md) | Stop LinkWatcher immediately after file move — files are either fully updated or untouched (atomic) |

## Notes

Test 2 has two valid outcomes (fully updated or untouched). Both are acceptable. Partial updates are a FAIL.
