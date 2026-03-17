<!-- Replace all [PLACEHOLDERS] with actual values -->
<!-- Remove all instructional comments when creating the actual file -->

# Master Test: markdown-parser-scenarios

## Metadata

| Field | Value |
|-------|-------|
| Group ID | MT-GRP-03 |
| Feature | 2.1.1 — Link Parsing System |
| Test Cases Covered | 1 |
| Estimated Duration | [ESTIMATED DURATION] |
| Created | 2026-03-16 |
| Last Updated | 2026-03-16 |

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

<!-- List the shared preconditions for all test cases in this group -->

- [ ] [Service/application] is running
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group markdown-parser-scenarios`
- [ ] Workspace contains pristine copies of all test fixtures
- [ ] [Any additional configuration requirements]

## Quick Validation Sequence

<!-- Each step combines key scenarios from individual test cases -->
<!-- Steps should be ordered to build on each other where possible -->
<!-- Use specific, unambiguous actions with exact targets -->

1. **[Action description combining MT-001 scenario]**
   - Action: [Exact action to perform]
   - Tool: [File Explorer / VS Code / Command Line / Browser / etc.]
   - Target: [Exact path or UI element]
   - Expected: [Observable result]

2. **[Action description combining MT-002 scenario]**
   - Action: [Exact action to perform]
   - Tool: [Tool to use]
   - Target: [Exact path or UI element]
   - Expected: [Observable result]

3. **[Action description combining MT-003 scenario]**
   - Action: [Exact action to perform]
   - Tool: [Tool to use]
   - Target: [Exact path or UI element]
   - Expected: [Observable result]

<!-- Add more steps as needed — one per test case scenario -->

## Pass Criteria

- [ ] All steps above produce their expected results
- [ ] No errors in service/application log
- [ ] Run `Verify-TestResult.ps1 -Group markdown-parser-scenarios` shows all green

<!-- Optional: Add additional pass criteria specific to this group -->

## If Failed

Run individual test cases to isolate the issue:

<!-- List all test cases in this group with brief descriptions -->

| Test Case | Path | Description |
|-----------|------|-------------|
| MT-004 | [MT-004-markdown-link-update-on-file-move/test-case.md](MT-004-markdown-link-update-on-file-move/test-case.md) | Move files referenced in markdown links (standard, special characters, quoted) and verify LinkWatcher updates all references |

## Notes

<!-- Optional: Edge cases, known issues, things to watch for across the group -->

[Any group-level notes, known limitations, or environment-specific considerations]
