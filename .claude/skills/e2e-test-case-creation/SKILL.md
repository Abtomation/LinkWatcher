---
name: e2e-test-case-creation
description: >-
  Craft for customizing an E2E acceptance test case well — the "how to fill it" half of the
  framework's E2E Acceptance Test Case Creation task (PF-TSK-069). Covers customizing test-case.md
  (preconditions, unambiguous steps, verifiable expected results, pass criteria), populating
  project/ and expected/ fixture directories, the run.ps1 action-only recipe for scripted tests,
  master-test Quick Validation Sequences, naming conventions, and (via reference) the
  hermetic-central pattern for scripted tests that touch central framework state. Activated from
  the E2E Acceptance Test Case Creation task's Check-Recommended-Skills step (via
  recommended_skills); not a test-execution, test-audit, or test-scoping skill.
user-invocable: false
---

# E2E Acceptance Test Case Creation Craft

This skill owns the **craft** of customizing an E2E acceptance test case — *how* to fill
`test-case.md`, the fixture directories, and (for scripted tests) `run.ps1` well. It is the
customization-craft home for the **E2E Acceptance Test Case Creation task (PF-TSK-069)**, which
owns everything else: task selection, role, checkpoints, test-case creation via script, tracking
updates, and the feedback form.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** run checkpoints,
> create test-case directories, or write tracking state from this skill — those stay in the task.
> This skill drives the per-file customization after the task's creation script has scaffolded the
> case.

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. The **task** creates each case with
`process-framework/scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1` (directory
structure, IDs, tracking updates). Non-obvious parameters: **`-Workflow`** must match an existing
workflow-slug directory (or pair with `-NewMaster`); **`-NewMaster`** creates
`master-test-<workflow-slug>.md`; **`-Scripted`** adds a `run.ps1` skeleton and sets
`Execution Mode: scripted`. Scripted cases run via
`process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1`
(orchestrates `Setup-TestEnvironment.ps1` → `run.ps1` → wait → `Verify-TestResult.ps1`).

## Customizing the generated files

- **`test-case.md`** — the script pre-fills metadata; the craft is in: **Preconditions** (exact
  starting state — services + config, file-system state, env vars), **Test Fixtures** (what's in
  `project/` and why), **Steps** (one unambiguous action each — exact tool + target, executable by
  someone unfamiliar with the codebase, with wait/observe steps where timing matters), **Expected
  Results** (file-change table with before/after + behavioral outcomes — concrete, never vague),
  **Verification Method**, and **Pass Criteria** (measurable, all must hold).
- **`project/`** — the exact, complete, **minimal** starting files: self-contained, only what the
  test needs, not a whole project.
- **`expected/`** — only the files that should change, in their post-test state, for automated
  comparison via `Verify-TestResult.ps1`.
- **Master test** (new workflows): the **Quick Validation Sequence** is the judgment part — chain
  key scenarios from individual cases into a sequential, each-step-verifiable flow. The "If
  Failed" table is script-maintained.

## run.ps1 (scripted tests only): action-only

`run.ps1` contains **only the test action** — it uses the `$WorkspacePath` parameter, does no
setup (handled by `Setup-TestEnvironment.ps1`) and no verification (handled by
`Verify-TestResult.ps1`).

```powershell
param([Parameter(Mandatory=$true)][string]$WorkspacePath)

# file move
Move-Item "$WorkspacePath/project/docs/readme.md" "$WorkspacePath/project/archive/readme.md"

# file edit (same param block)
# $configPath = "$WorkspacePath/project/config/settings.yaml"
# $c = Get-Content $configPath -Raw -Encoding UTF8
# Set-Content $configPath ($c -replace 'output_dir: docs/', 'output_dir: archive/') -Encoding UTF8
```

**When the script under test touches central framework state** (`process-framework-central/` —
IMP lifecycle, central ID allocation, soak tracking, rollout), the plain sandbox is not enough:
load [references/hermetic-central.md](references/hermetic-central.md) for the
`FRAMEWORK_CENTRAL_OVERRIDE` pattern, the `sandbox-central-seed/` convention, and the
leak-detection `run.ps1` recipe. If the script only touches project-local `doc/` state, the
standard sandbox-everywhere pattern suffices.

**When the subject is an instruction, not a script** — a task, guide or playbook an agent executes
(instruction-medium features, PF-PRO-064 verification Level 3) — the case has no `run.ps1` at all,
because the actor is the agent. Load
[references/instruction-fixtures.md](references/instruction-fixtures.md): the agent-as-actor /
shipped-oracle split, why `expected/` holds a verdict rather than an end state, how to design
assertions that discriminate a correct run from a wrong-order one, and how to write the protocol
without restating the procedure under test.

## Naming conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Workflow directory | `<workflow-slug>` | `basic-file-operations` |
| Test case directory | `TE-E2E-NNN-<descriptive-name>` | `TE-E2E-001-single-file-rename` |
| Master test file | `master-test-<workflow-slug>.md` | `master-test-basic-file-operations.md` |
| Test case file | `test-case.md` (always) | `test-case.md` |

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| "Workflow directory does not exist" | `-Workflow` doesn't match an existing slug | Use `-NewMaster` (the directory is pre-scaffolded by `New-WorkflowEntry.ps1`), or match the existing slug exactly |
| New case missing from the master "If Failed" table | Master file name mismatch | The master file name must match `master-test-<workflow-slug>.md` exactly |
| Real-central files changed during a hermetic-central test | A code path bypassed the override | See [references/hermetic-central.md](references/hermetic-central.md) — leak-assertion failure procedure |
