---
name: test-specification
description: >-
  Craft for customizing a Test Specification (TE-TSP) well — the "how to fill it" half of the
  framework's Test Specification Creation task (PF-TSK-012). Covers tier-appropriate automated-test
  depth, mapping TDD components to test categories, mock requirements, the Implementation Coverage
  line, and the testing-level separation of concerns; a bundled reference holds the test-file
  customization craft (New-TestFile.ps1 TestType/Priority selection, mock strategy) consulted by any
  task that creates test files. Activated from the Test Specification Creation task's
  Check-Recommended-Skills step (via recommended_skills); not a test-implementation, test-audit, or
  E2E/performance-scoping skill.
user-invocable: false
---

# Test Specification Craft

This skill owns the **craft** of customizing a Test Specification — *how* to translate a TDD into
behavioral, automated-test requirements at the tier-appropriate depth. It is the customization-craft
home for the **Test Specification Creation task (PF-TSK-012)**, which owns everything else: task
selection, role, checkpoints, document creation via script, state-file updates, and the feedback
form. Its [test-file customization reference](references/test-file-customization.md) is also the
craft home consulted inline by the tasks that *implement* tests (Integration and Testing, Core
Logic Implementation, Bug Fixing, Code Refactoring, Feature Enhancement) when they create test
files.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** run checkpoints,
> create the document, or write state from this skill — those stay in the task. This skill drives
> the spec content customization between the task's checkpoints.

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. The **task** creates the document with
`process-framework/scripts/file-creation/03-testing/New-TestSpecification.ps1` — always via the
script, never hand-authored. `-TddPath` (relative from project root, forward slashes) names the
source design the spec is derived from: **a Test Specification is always created from an existing
TDD**, translating architectural design into behavioral test requirements.

## Scope: automated tests only

Test Specifications cover **automated tests** (unit, integration, component; E2E automation at
Tier 3). E2E *acceptance* tests are identified by cross-cutting milestone triggers, and performance
tests are identified after code review by the Performance & E2E Test Scoping task — that "when to
test" judgment is the `perf-e2e-scoping` craft, not this one.

## Tier-appropriate test depth

Automated test depth scales with the feature's complexity tier — this drives the task's
automated-test-depth assessment step:

- **Tier 1** — core unit tests + key integration scenarios (happy paths + critical edge cases).
- **Tier 2** — comprehensive unit + integration + component tests (broader edge-case coverage).
- **Tier 3** — full automated suite: exhaustive edge cases, error paths, component-interaction
  tests.

When the feature's **Dimension Profile** marks a dimension Critical, add focused scenarios for it —
Critical SE → security boundary tests, Critical DI → data-integrity edge cases — even at Tier 1/2.

## Customizing the spec

- **TDD Summary** — concise summary of the TDD's components + design decisions that require
  testing; note integration points and dependencies. Summarize for a *testing* reader — what must
  be validated, not how it is built.
- **Test Categories** — map each TDD component to test types: models / services → Unit; component
  interactions → Integration; component-level → Component; automated workflows → E2E (Tier 3
  only). For each, define test cases (Arrange / Act / Assert), edge cases, error conditions, mock
  requirements, and test data.
- **Implementation Coverage** (Overview line) — count total scenarios across all Test Categories
  tables; a new spec reads `**Implementation Coverage**: 0/N scenarios implemented (0%)`. It is
  updated as tests land — the at-a-glance coverage status the documentation-completeness procedure
  keeps honest (see
  [Test Infrastructure Guide — Test Documentation Completeness](../../../process-framework/guides/03-testing/test-infrastructure-guide.md#test-documentation-completeness)).

## Separation of concerns

Test Specifications own testing-level concerns only (test cases, data, mocks, validation criteria,
coverage). Reference (don't duplicate): functional requirements → FDD; API contracts → API
Specification; schema → Database Schema Design; design / architecture → TDD. Canonical ownership
rules and the cross-reference format live in the
[Information Flow Guide — Test Specification Creation Task](../../../process-framework/guides/framework/information-flow-guide.md#test-specification-creation-task-pf-tsk-012).

## Implementing the tests a spec defines

When a task creates or customizes actual test files (`New-TestFile.ps1` — TestType and Priority
selection, mock strategy, customizing the generated scaffolding), load
[references/test-file-customization.md](references/test-file-customization.md).

## Edge cases

On an error, surprise, or ambiguous fork at any task step (a script rejection, a feature that
turns out not to need tests, a spec coming out too thin), consult
[references/edge-cases.md](references/edge-cases.md) — the task's consult-on-stumble record;
append autonomously per the workspace Standing Orders.
