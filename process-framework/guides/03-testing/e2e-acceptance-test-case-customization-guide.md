---
id: PF-GDE-049
type: Process Framework
category: Guide
version: 1.3
created: 2026-03-15
updated: 2026-05-29
related_script: New-E2EAcceptanceTestCase.ps1
related_task: PF-TSK-069
description: "Step-by-step instructions for customizing E2E acceptance test case and master test templates created by New-E2EAcceptanceTestCase.ps1"
---

# E2E Acceptance Test Case Customization Guide

## Overview

This guide explains how to use `New-E2EAcceptanceTestCase.ps1` to create E2E acceptance test cases and how to customize the generated output. The script creates the directory structure, assigns IDs, and updates tracking files automatically. Your job is to customize the `test-case.md` content and populate the fixture directories.

## When to Use

Use this guide when the [E2E Acceptance Test Case Creation task (PF-TSK-069)](../../tasks/03-testing/e2e-acceptance-test-case-creation-task.md) requires you to create concrete test cases. The script handles infrastructure; this guide focuses on content customization.

## Prerequisites

- Test specification, bug report, or refactoring plan identifying what needs E2E acceptance testing
- Feature ID and name for the feature being tested
- Understanding of the workflow this case belongs to (or decision to create the workflow's master test)

## Step-by-Step Instructions

### 1. Run the Creation Script

**New workflow's first test case (create master test alongside):**

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1 -TestCaseName "descriptive-name" -Workflow "<workflow-slug>" -FeatureIds "X.Y.Z" -FeatureName "Feature Name" -NewMaster -Source "Test Spec PF-TSP-NNN" -Description "Brief description" -Confirm:\$false
```

**Additional test case in existing workflow:**

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1 -TestCaseName "descriptive-name" -Workflow "<workflow-slug>" -FeatureIds "X.Y.Z" -FeatureName "Feature Name" -Source "Test Spec PF-TSP-NNN" -Description "Brief description" -Confirm:\$false
```

**Scripted test case (automatable):**

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1 -TestCaseName "move-readme" -Workflow "<workflow-slug>" -FeatureIds "X.Y.Z" -FeatureName "Feature Name" -Scripted -Source "Test Spec PF-TSP-NNN" -Description "Move readme and verify link updates" -Confirm:\$false
```

When `-Scripted` is used, the script additionally creates a `run.ps1` skeleton and sets `Execution Mode` to `scripted` in test-case.md.

**Script output (PF-IMP-871 Phase 3c2 per-workflow layout):**
- `test/e2e-acceptance-testing/<workflow-slug>/templates/TE-E2E-NNN-<name>/` directory with `test-case.md`, `project/`, `expected/`
- If `-NewMaster`: `master-test-<workflow-slug>.md` in the workflow's templates directory
- Updated test-tracking.md (new entry with status `📋 Needs Execution`)
- Updated feature-tracking.md (Test Status updated)
- Updated master test "If Failed" table (new row added)

### 2. Customize test-case.md

The script pre-fills metadata (ID, group, feature, priority, dates, source). You need to customize:

**Preconditions** — Replace placeholders with exact starting state:
- What services must be running and with what configuration
- What the file system state must be before starting
- Any specific settings or environment variables

**Test Fixtures** — Document what's in the `project/` directory:
- List each fixture file with its purpose
- Describe relevant content that the test depends on

**Steps** — Replace placeholder steps with exact, unambiguous actions:
- One action per step
- Specify the exact tool (File Explorer, VS Code, command line)
- Specify the exact target (file path, UI element, command)
- Add wait/observe steps where timing matters (e.g., "Wait 2-3 seconds for events to process")

**Expected Results** — Define concrete outcomes:
- File Changes table: exact file, line, before/after content
- Behavioral Outcomes: log messages, UI state, service behavior
- Reference `expected/` directory if the entire post-test state is captured there

**Verification Method** — Select applicable methods:
- Automated comparison via `Verify-TestResult.ps1`
- Visual inspection
- Log checking

**Pass Criteria** — Define measurable conditions that must ALL be true.

### 3. Populate project/ Directory

Add the exact files needed as the starting state of the test. These should be:
- Complete, valid files (not stubs)
- Minimal — only what the test needs, not an entire project
- Self-contained — the test should work with only these files

### 4. Populate expected/ Directory

Add files in their expected post-test state. This enables automated comparison via `Verify-TestResult.ps1`. Only include files that should change during the test.

### 5. Customize Master Test (New Workflows Only)

If you created the workflow's master test with `-NewMaster`, customize `master-test-<workflow-slug>.md`:

**Quick Validation Sequence** — This is the curated part that requires judgment:
- Combine key scenarios from individual test cases into a sequential flow
- Order steps to build on each other where possible
- Each step should produce a verifiable result

The "If Failed" table is automatically maintained by the script when you add new test cases.

### 6. Customize run.ps1 (Scripted Tests Only)

If you created the test case with `-Scripted`, customize the generated `run.ps1` skeleton:

**What `run.ps1` should contain:**
- Only the test action (e.g., `Move-Item`, `Set-Content`, `Rename-Item`)
- Uses the `$WorkspacePath` parameter to reference files in the workspace
- No setup (handled by `Setup-TestEnvironment.ps1`)
- No verification (handled by `Verify-TestResult.ps1`)

**Example `run.ps1` for a file move test:**

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

Move-Item "$WorkspacePath/project/docs/readme.md" "$WorkspacePath/project/archive/readme.md"
```

**Example `run.ps1` for a file edit test:**

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$configPath = "$WorkspacePath/project/config/settings.yaml"
$content = Get-Content $configPath -Raw -Encoding UTF8
$content = $content -replace 'output_dir: docs/', 'output_dir: archive/'
Set-Content $configPath $content -Encoding UTF8
```

**Running scripted tests:**

```bash
# Via orchestrator (recommended)
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1 -TestCase "E2E-NNN" -Workflow "<workflow-slug>" -Clean

# Manual pipeline (step by step)
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1 -Workflow "<workflow-slug>" -Clean
pwsh.exe -ExecutionPolicy Bypass -File test/e2e-acceptance-testing/<workflow-slug>/templates/E2E-NNN-name/run.ps1 -WorkspacePath "test/e2e-acceptance-testing/<workflow-slug>/workspace/E2E-NNN-name"
# Wait for system propagation...
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Verify-TestResult.ps1 -TestCase "E2E-NNN" -Workflow "<workflow-slug>"
```

## Hermetic-Central Pattern (Scripted Tests That Touch Central State)

Most scripted test cases exercise a script that mutates state files at fixed relative paths inside the project tree — the sandbox plays "the project" and `Setup-TestEnvironment.ps1` gives each run a clean workspace (the "sandbox-everywhere" pattern). But some framework scripts resolve `process-framework-central/` instead (IMP lifecycle, central ID allocation, soak tracking, rollout). Without intervention, a test invoking those would write sentinel rows and advance counters in appdev's **real** central tracking files on every run.

The **hermetic-central pattern** redirects all central reads/writes to a per-test sandbox via an environment-variable override, so the real appdev central is never touched mid-test.

### When it applies

Use this pattern when the script under test reaches central state — e.g. `New-ProcessImprovement.ps1`, `Update-ProcessImprovement.ps1`, anything that allocates a central `PF-IMP` / `PF-PRO` / etc. ID, soak-tracking scripts, or rollout/restore. If the script only touches project-local `doc/` state, the plain sandbox-everywhere pattern is sufficient — you do not need this.

### The override hook

Setting `$env:FRAMEWORK_CENTRAL_OVERRIDE` to a directory path redirects central resolution there. It is honored by both central-path resolvers (PF-PRO-035 Session 29/30, OP-1):

- `Get-CentralFrameworkPath` in [Common-ScriptHelpers/Core.psm1](../../scripts/Common-ScriptHelpers/Core.psm1) — returns the override directly as the central path.
- `Resolve-CentralRegistryPath` in [IdRegistry.psm1](../../scripts/IdRegistry.psm1) — returns `<override>/PF-id-registry-central.json`. The override **must** cover this resolver too, otherwise ID allocations bypass it and leak counter increments into the real central registry.

Properties to rely on:

- The value is the **full central path**, not the appdev root — the fixture constructs exactly the directory it wants, including required state-file skeletons.
- Both resolvers **throw** if the override points at a non-existent path — the fixture must create the sandbox-central directory *before* invoking the script.
- Unset in production. (Distinct from `$env:PF_SOAK_DISABLE`, which suppresses soak counting rather than redirecting central state.)

### The `sandbox-central-seed/` convention

Place a `sandbox-central-seed/` directory beside the test case (alongside `test-case.md`, `project/`, `expected/`). Seed it with the minimal central skeleton the script needs — typically schema-correct, data-empty `process-framework-tracking` files plus minimal `PF-id-registry-central.json` / `project-registry.json`. Pin counters to a **sentinel range** (e.g. `PF-IMP.nextAvailable = 999900`) so allocated IDs are obviously distinguishable from real central IDs and any leak is immediately visible as out-of-distribution noise.

This seed directory is **not** copied to the workspace by `Setup-TestEnvironment.ps1` (which only copies `project/`). `run.ps1` copies it explicitly as its first action.

### The `run.ps1` recipe

1. **Snapshot real central** — read appdev's real `PF-id-registry-central.json` counter and `Get-FileHash` (SHA256) the real tracking file. These are the leak-detection baselines.
2. **Build a fresh sandbox-central** — copy `sandbox-central-seed/` → `<workspace>/sandbox-central/` (force-overwrite any prior run's state).
3. **Activate the override inside `try`/`finally`** — `$env:FRAMEWORK_CENTRAL_OVERRIDE = <workspace>/sandbox-central/`. Clear it in the `finally` so it clears even on assertion failure.
4. **Invoke the script(s) from the sandbox project** so `Get-ProjectRoot` resolves to the sandbox's project_id; all central writes land in the sandbox-central.
5. **Assert both directions** — the expected rows/counter landed in the sandbox-central, **and** the real central counter and tracking-file SHA256 are byte-identical to step 1's snapshot. The second assertion is the whole point of the pattern.

```powershell
param([Parameter(Mandatory=$true)][string]$WorkspacePath)
$ErrorActionPreference = 'Stop'

# 1. Snapshot real central (leak-detection baseline)
$realRegistry = Join-Path $appdevRoot 'process-framework-central/PF-id-registry-central.json'
$realTracking = Join-Path $appdevRoot 'process-framework-central/state-tracking/permanent/process-improvement-tracking.md'
$preCounter = (Get-Content $realRegistry -Raw | ConvertFrom-Json).prefixes.'PF-IMP'.nextAvailable
$preHash    = (Get-FileHash $realTracking -Algorithm SHA256).Hash

# 2. Fresh sandbox-central from the seed
$sandboxCentral = Join-Path $WorkspacePath 'sandbox-central'
if (Test-Path $sandboxCentral) { Remove-Item $sandboxCentral -Recurse -Force }
Copy-Item (Join-Path $PSScriptRoot 'sandbox-central-seed') $sandboxCentral -Recurse -Force

# 3. Activate override (cleared in finally even on failure)
$env:FRAMEWORK_CENTRAL_OVERRIDE = $sandboxCentral
try {
    # 4. Invoke the script(s) under test from the sandbox project
    & $scriptUnderTest -Param ... -Confirm:$false

    # 5a. Assert the write landed in the sandbox-central
    #     (counter advanced, row present, etc.)

    # 5b. Assert the REAL central was untouched (the leak gate)
    $postCounter = (Get-Content $realRegistry -Raw | ConvertFrom-Json).prefixes.'PF-IMP'.nextAvailable
    if ($postCounter -ne $preCounter) { Write-Error "Real central counter changed — override leaked"; exit 1 }
    if ((Get-FileHash $realTracking -Algorithm SHA256).Hash -ne $preHash) { Write-Error "Real central tracking changed — override leaked"; exit 1 }

    'ok' | Out-File (Join-Path $WorkspacePath 'project/success.txt') -Encoding utf8 -NoNewline
    exit 0
}
finally {
    Remove-Item env:FRAMEWORK_CENTRAL_OVERRIDE -ErrorAction SilentlyContinue
}
```

New central-touching cases pattern-match against this shape: the same `sandbox-central-seed/` skeleton, the same override activation in a `try`/`finally`, and the same pre/post real-central snapshot assertions.

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Workflow directory | `<workflow-slug>` | `basic-file-operations` |
| Test case directory | `TE-E2E-NNN-<descriptive-name>` | `TE-E2E-001-single-file-rename` |
| Master test file | `master-test-<workflow-slug>.md` | `master-test-basic-file-operations.md` |
| Test case file | `test-case.md` (always) | `test-case.md` |

## Script Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-TestCaseName` | Yes | Short descriptive name (used in directory, e.g., `single-file-rename`) |
| `-Workflow` | Yes | Workflow slug (must match an existing workflow directory, or use `-NewMaster`). Per PF-IMP-871 Phase 3c2, this is the directory-name source for the per-workflow layout. |
| `-FeatureIds` | Yes | Feature ID(s), comma-separated for multi-feature (e.g., `"1.1.1,2.1.1,2.2.1"`) |
| `-FeatureName` | Yes | Human-readable name for the primary feature |
| `-Priority` | No | P0/P1/P2/P3 (default: P1) |
| `-Source` | No | What triggered creation (e.g., `Test Spec PF-TSP-038`) |
| `-Description` | No | Brief description of what the test validates |
| `-NewMaster` | No | Switch to create the workflow's master test alongside the first test case (the workflow's `templates/` directory is pre-scaffolded by `New-WorkflowEntry.ps1`) |
| `-Scripted` | No | Switch to create a scripted test case with `run.ps1` skeleton |
| `-OpenInEditor` | No | Opens test-case.md in default editor after creation |

## Troubleshooting

### Workflow directory does not exist

**Symptom:** Script throws "Workflow directory does not exist"

**Solution:** Either use `-NewMaster` to create the workflow's master test (the directory itself is pre-scaffolded by `New-WorkflowEntry.ps1`), or check that `-Workflow` matches an existing workflow slug exactly.

### Master test not updated

**Symptom:** New test case not appearing in master test's "If Failed" table

**Cause:** Master test file name doesn't match `master-test-<workflow-slug>.md` convention

**Solution:** Ensure the master test file follows the naming convention exactly.

### Real-central files changed during a hermetic-central test

**Symptom:** A test using the [hermetic-central pattern](#hermetic-central-pattern-scripted-tests-that-touch-central-state) fails its leak assertion — the real appdev central counter or tracking-file SHA256 changed.

**Cause:** A code path in the script under test bypassed the `$env:FRAMEWORK_CENTRAL_OVERRIDE` redirect and wrote to the real central.

**Solution:** Stop — do not commit the polluted central files. Run `git diff HEAD -- process-framework-central/` from the appdev root to see what leaked, then extend the override coverage to whichever resolver the bypassing path used. Confirm the override was set *before* the first script invocation and that the sandbox-central directory existed at that point (both resolvers throw on a missing override path).

## Related Resources

- [E2E Acceptance Test Case Creation Task](../../tasks/03-testing/e2e-acceptance-test-case-creation-task.md) — Task definition
- [E2E Acceptance Test Case Template](../../templates/03-testing/e2e-acceptance-test-case-template.md) — Template for test-case.md
- [E2E Acceptance Master Test Template](../../templates/03-testing/e2e-acceptance-master-test-template.md) — Template for master test files
- [New-E2EAcceptanceTestCase.ps1](../../scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1) — Creation script
