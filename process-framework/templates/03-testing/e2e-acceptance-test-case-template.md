---
id: PF-TEM-054
type: Process Framework
category: Template
version: 1.1
created: 2026-03-15
updated: 2026-03-18
template_for: E2E Acceptance Test Case
description: Template for individual E2E acceptance test case files with exact steps, preconditions, expected outcomes, and verification methods
creates_document_category: Testing
usage_context: E2E Acceptance Test Case Creation Task (PF-TSK-069)
---

<!-- TEMPLATE STARTS BELOW THIS LINE -->
<!-- Copy everything below into test/e2e-acceptance-testing/templates/<group>/TE-E2E-NNN-<name>/test-case.md -->
<!-- Replace all [PLACEHOLDERS] with actual values -->
<!-- Remove all instructional comments when creating the actual file -->

---
id: [E2E-NNN]
type: E2E Acceptance Test Case
group: [GROUP-ID]
feature_ids: [FEATURE-IDS-YAML]
workflow: [WF-NNN]
priority: [P0 / P1 / P2 / P3]
execution_mode: [manual / scripted]
estimated_duration: [X minutes]
source: [Test Spec / Bug Report / Refactoring Plan] — [SOURCE-ID]
lw_flags: ""
expected_exit_code: 0
created: [YYYY-MM-DD]
updated: [YYYY-MM-DD]
---

<!-- Priority Guide:
  P0 — Critical path, blocks release. Must pass before any deployment.
  P1 — High priority. Core functionality that should always work.
  P2 — Medium priority. Important but not blocking.
  P3 — Low priority. Edge cases and nice-to-have validations.
-->

# Test Case: [E2E-NNN] [TITLE]

<!-- Execution Mode:
  manual — Human follows Steps section to execute (default)
  scripted — run.ps1 performs the action; can be run by AI agent via Run-E2EAcceptanceTest.ps1 or by human directly
-->

## Preconditions

<!-- List the EXACT starting state required before executing this test -->
<!-- Be specific: running services, configuration, file system state -->

- [ ] [Service/application] is running with [specific configuration]
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group [GROUP-NAME]`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] [Any additional preconditions specific to this test case]

## Test Fixtures

<!-- Describe the project fixtures in the project/ subdirectory -->
<!-- These are the files that form the starting state of the test -->

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/[file-path]` | [What this file represents] | [Brief description of relevant content] |
| `project/[file-path]` | [What this file represents] | [Brief description of relevant content] |

<!-- If fixtures are complex, reference the project/ directory directly:
     "See project/ directory for complete starting state"
-->

## Steps

<!-- Numbered steps with EXACT actions. Each step should be unambiguous -->
<!-- A person unfamiliar with the codebase should be able to follow these -->

1. **[Action verb]**: [Exact description of what to do]
   - **Tool**: [File Explorer / VS Code / Command Line / Browser / etc.]
   - **Target**: [Exact file path, UI element, or command]

<!-- Optional: Add wait/observe steps where timing matters -->

2. **[Wait/Observe]**: [What to observe and for how long]
   - **Duration**: [Specific time to wait, e.g., "Wait 2–3 seconds for file system events to process"]
   - **Observe**: [What to look for during the wait]

3. **[Verify]**: [What to check after the action]
   - **Tool**: [How to check — e.g., "Open in text editor", "Check terminal output"]
   - **Target**: [Exact file or location to inspect]

<!-- Add more steps as needed. Keep steps atomic — one action per step -->

## Scripted Action

<!-- SCRIPTED TESTS ONLY — Remove this section entirely for non-scripted tests -->
<!-- Documents what run.ps1 does. The script lives in the test case directory. -->

**Script**: `run.ps1`
**Action**: [One-line description, e.g., "Moves project/docs/readme.md to project/archive/readme.md"]

<!-- run.ps1 contains ONLY the test action (e.g., Move-Item, Set-Content).
     Setup is handled by Setup-TestEnvironment.ps1.
     Verification is handled by Verify-TestResult.ps1.
     Full pipeline: Setup → run.ps1 → wait → Verify (orchestrated by Run-E2EAcceptanceTest.ps1) -->

## Expected Results

<!-- Define the concrete, measurable outcomes -->
<!-- Use tables for file content changes, lists for behavioral outcomes -->

### File Changes

<!-- List specific file content changes expected after executing the steps -->

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `[file-path]` | [line number or section] | `[old content]` | `[new content]` |
| `[file-path]` | [line number or section] | `[old content]` | `[new content]` |

<!-- If expected state is an entire file, reference the expected/ subdirectory:
     "See expected/ directory for complete post-test file state"
-->

### Behavioral Outcomes

<!-- List observable behaviors (log messages, UI state, service responses) -->

- [Expected log message or output]
- [Expected UI state or visual confirmation]
- [Expected service behavior]

## Verification Method

<!-- How to confirm the test passed — multiple methods can be used -->

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase [TE-E2E-NNN]` — compares workspace against `expected/`
- [ ] **Visual inspection**: Open files listed in Expected Results and confirm changes
- [ ] **Log check**: Check application log for [specific messages or absence of errors]

<!-- Remove verification methods that don't apply to this test case -->

## Pass Criteria

<!-- All conditions must be TRUE for the test to pass -->
<!-- These should be concrete and measurable, not subjective -->

- [ ] [Specific, measurable criterion 1]
- [ ] [Specific, measurable criterion 2]
- [ ] [Specific, measurable criterion 3]
- [ ] No errors or warnings in application log during test execution

## Fail Actions

<!-- What to do if this test case fails -->

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Take screenshots or save log output as evidence

## Notes

<!-- Optional: Edge cases, known issues, environment-specific considerations -->
<!-- Remove this section if not needed -->

[Any additional context, known limitations, or things to watch for]
