---
id: PF-TEM-053
type: Process Framework
category: Template
version: 1.0
created: 2026-03-15
updated: 2026-03-15
template_for: E2E Acceptance Master Test
description: Template for group-level master test files that provide quick validation sequences covering all test cases in a test group
creates_document_category: Testing
usage_context: E2E Acceptance Test Case Creation Task (PF-TSK-069)
---

<!-- TEMPLATE STARTS BELOW THIS LINE -->
<!-- Copy everything below into test/e2e-acceptance-testing/templates/<group>/master-test-<group-name>.md -->
<!-- Replace all [PLACEHOLDERS] with actual values -->
<!-- Remove all instructional comments when creating the actual file -->

---
id: [GROUP-ID]
type: E2E Acceptance Test Group
feature_ids: ["[FEATURE-ID]"]
workflow: [WF-NNN]
test_cases_count: [NUMBER]
estimated_duration: [X minutes]
created: [YYYY-MM-DD]
updated: [YYYY-MM-DD]
---

# Master Test: [GROUP-NAME]

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

<!-- List the shared preconditions for all test cases in this group -->

- [ ] [Service/application] is running
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group [GROUP-NAME]`
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
- [ ] Run `Verify-TestResult.ps1 -Group [GROUP-NAME]` shows all green

<!-- Optional: Add additional pass criteria specific to this group -->

## If Failed

Run individual test cases to isolate the issue:

<!-- List all test cases in this group with brief descriptions -->

| Test Case | Path | Description |
|-----------|------|-------------|
| [E2E-001] | [E2E-001-xxx/test-case.md](E2E-001-xxx/test-case.md) | [Brief description] |
| [E2E-002] | [E2E-002-xxx/test-case.md](E2E-002-xxx/test-case.md) | [Brief description] |
| [E2E-003] | [E2E-003-xxx/test-case.md](E2E-003-xxx/test-case.md) | [Brief description] |

## Notes

<!-- Optional: Edge cases, known issues, things to watch for across the group -->

[Any group-level notes, known limitations, or environment-specific considerations]
