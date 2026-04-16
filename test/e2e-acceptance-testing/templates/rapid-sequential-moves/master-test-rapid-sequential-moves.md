---
id: TE-E2G-007
type: E2E Acceptance Test Group
feature_ids: ["1.1.1", "0.1.2", "2.2.1"]
workflow: WF-004
test_cases_count: 2
estimated_duration: 6 minutes
created: 2026-03-18
updated: 2026-03-18
---

# Master Test: rapid-sequential-moves

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

- [ ] LinkWatcher running and monitoring workspace
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group rapid-sequential-moves`
- [ ] Workspace contains pristine copies of all test fixtures
- [ ] `project/src/` directory does NOT exist yet

## Quick Validation Sequence

1. **Rapid simultaneous move of two files**
   - Action: Move both `lib/utils.md` and `lib/helpers.md` to `src/` within 200ms
   - Tool: Command Line
   - Target: `lib/utils.md` and `lib/helpers.md`
   - Expected: `index.md` has both links updated to `src/utils.md` and `src/helpers.md`

2. **Sequential moves with short delay**
   - Action: Reset fixtures, then move `config/settings.md` to `archive/`, wait 500ms, move `docs/readme.md` to `guides/`
   - Tool: Command Line
   - Target: `config/settings.md` then `docs/readme.md`
   - Expected: `guides/readme.md` has `[Config](../archive/settings.md)`

## Pass Criteria

- [ ] All steps above produce their expected results
- [ ] No errors in LinkWatcher log
- [ ] Run `Verify-TestResult.ps1 -Group rapid-sequential-moves` shows all green

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-016 | [TE-E2E-016-two-files-moved-rapidly/test-case.md](TE-E2E-016-two-files-moved-rapidly/test-case.md) | Two files moved within 1 second — both references updated correctly, no race conditions |
| TE-E2E-017 | [TE-E2E-017-move-file-then-referencing-file/test-case.md](TE-E2E-017-move-file-then-referencing-file/test-case.md) | Move target file, then immediately move referencing file — both have correct references after both moves |

## Notes

These tests are timing-sensitive. If LinkWatcher's move detection timeout is > 1 second, rapid moves may be coalesced differently.
