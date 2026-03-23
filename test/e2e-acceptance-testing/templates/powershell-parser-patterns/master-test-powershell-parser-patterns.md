---
id: TE-E2G-002
type: E2E Acceptance Test Group
feature_ids: ["1.1.1", "2.1.1", "2.2.1"]
workflow: WF-001
test_cases_count: 2
estimated_duration: 6 minutes
created: 2026-03-16
updated: 2026-03-16
---

# Master Test: powershell-parser-patterns

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

<!-- List the shared preconditions for all test cases in this group -->

- [ ] [Service/application] is running
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group powershell-parser-patterns`
- [ ] Workspace contains pristine copies of all test fixtures
- [ ] [Any additional configuration requirements]

## Quick Validation Sequence

<!-- Each step combines key scenarios from individual test cases -->
<!-- Steps should be ordered to build on each other where possible -->
<!-- Use specific, unambiguous actions with exact targets -->

1. **[Action description combining E2E-001 scenario]**
   - Action: [Exact action to perform]
   - Tool: [File Explorer / VS Code / Command Line / Browser / etc.]
   - Target: [Exact path or UI element]
   - Expected: [Observable result]

2. **[Action description combining E2E-002 scenario]**
   - Action: [Exact action to perform]
   - Tool: [Tool to use]
   - Target: [Exact path or UI element]
   - Expected: [Observable result]

3. **[Action description combining E2E-003 scenario]**
   - Action: [Exact action to perform]
   - Tool: [Tool to use]
   - Target: [Exact path or UI element]
   - Expected: [Observable result]

<!-- Add more steps as needed — one per test case scenario -->

## Pass Criteria

- [ ] All steps above produce their expected results
- [ ] No errors in service/application log
- [ ] Run `Verify-TestResult.ps1 -Group powershell-parser-patterns` shows all green

<!-- Optional: Add additional pass criteria specific to this group -->

## If Failed

Run individual test cases to isolate the issue:

<!-- List all test cases in this group with brief descriptions -->

| Test Case | Path | Description |
|-----------|------|-------------|
| E2E-006 | [E2E-006-ps-md-move/test-case.md](E2E-006-ps-md-move/test-case.md) | Move markdown file referenced in PS |

## Notes

<!-- Optional: Edge cases, known issues, things to watch for across the group -->

[Any group-level notes, known limitations, or environment-specific considerations]
