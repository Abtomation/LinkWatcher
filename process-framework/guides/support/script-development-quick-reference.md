---
id: PF-GDE-019
type: Process Framework
category: Guide
version: 1.0
created: 2025-07-21
updated: 2025-07-21
guide_description: Quick reference for common script development issues and solutions
description: "Quick reference for common script development issues and solutions"
---
# Script Development Quick Reference

## Overview

Quick reference for common script development issues and solutions

## When to Use

Use this guide when you encounter issues while developing PowerShell document creation scripts for the project. This guide provides immediate solutions to the most common problems.

> **🚨 CRITICAL**: Always test scripts thoroughly before considering them complete. Use the testing checklist provided below.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Quick Fixes](#quick-fixes)
4. [Testing Checklist](#testing-checklist)
5. [Common Patterns](#common-patterns)
6. [Troubleshooting](#troubleshooting)
7. [Related Resources](#related-resources)

## Prerequisites

Before you begin, ensure you have:

- Basic PowerShell knowledge
- Understanding of project structure
- Access to process-framework/scripts/Common-ScriptHelpers.psm1
- PowerShell module `powershell-yaml` installed (`Install-Module powershell-yaml -Scope CurrentUser`) — required by `Get-TemplateMetadata` for YAML frontmatter parsing

## Background

This quick reference addresses the most common issues encountered when developing document creation scripts for the project, based on real implementation experiences from the Database Schema Design Task and other script implementations.

## Quick Fixes

### 🚨 Module Import Failures

**Issue**: "The specified module was not loaded because no valid module file was found"

**Quick Fix**:
```powershell
# Replace simple import with robust path resolution
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "relative/path/to/Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers: $($_.Exception.Message)"
    exit 1
}
```

### 🚨 Module Import Warnings

**Issue**: `WARNING: The names of some imported commands from the module '...' include unapproved verbs`

**Cause**: A function in the module uses a verb that is not in PowerShell's approved verb list (e.g., `Ensure-Something` instead of `Initialize-Something`).

**Fix**: Rename the function to use an approved verb. Do **not** suppress with `-WarningAction SilentlyContinue`.

```powershell
# List all approved verbs
Get-Verb

# Common replacements:
#   Ensure-*     → Initialize-*  (create if absent)
#   Parse-*      → ConvertFrom-* (transform input)
#   Check-*      → Test-*        (verify condition)
#   Setup-*      → Initialize-*  (prepare resource)
#   Create-*     → New-*         (instantiate)
#   Delete-*     → Remove-*      (dispose)
```

After renaming, update all call sites and the module's export list.

### 🚨 Sub-Module Function Scoping (Common-ScriptHelpers)

**Issue**: A function added to a Common-ScriptHelpers sub-module (e.g., `DocumentManagement.psm1`) calls into another sub-module's exports (e.g., `IdRegistry`'s `New-NextId`) and gets `CommandNotFoundException` even though the umbrella `Common-ScriptHelpers.psm1` exports both.

**Cause**: PowerShell modules have isolated session states. When you call `Import-ProjectModule -ModuleName "IdRegistry"` *inside* a function in `DocumentManagement.psm1`, the imported functions land in `Core.psm1`'s session state (where `Import-ProjectModule` is defined), not in `DocumentManagement.psm1`'s session state. Functions in your sub-module can't see them.

**Fix**: Import dependencies at the **top of your sub-module file**, not lazily inside a function:

```powershell
# At the top of YourSubModule.psm1 — runs in this module's session state
$scriptPath = Split-Path -Parent $PSScriptRoot
$idRegistryModule = Join-Path -Path $scriptPath -ChildPath "IdRegistry.psm1"
if (Test-Path $idRegistryModule) { Import-Module $idRegistryModule -Force }

function Your-Function {
    $id = New-NextId -Prefix "PF-XXX"   # ✅ resolves
}
```

Canonical example: [DocumentManagement.psm1](../../scripts/Common-ScriptHelpers/DocumentManagement.psm1) lines 22-30.

**Avoid**:

```powershell
function Your-Function {
    Import-ProjectModule -ModuleName "IdRegistry" -Required   # imports into Core's scope
    $id = New-NextId -Prefix "PF-XXX"                         # ❌ CommandNotFoundException
}
```

> Applies only to authors *extending* Common-ScriptHelpers sub-modules. Scripts that consume Common-ScriptHelpers via the umbrella import are unaffected — `Import-ProjectModule` works fine when called from a script (script scope is separate from module scope).

### 🚨 Reserved PowerShell Automatic Variables

**Issue**: Your function parameter shadows a PowerShell automatic variable, causing silent type coercion or argument-parsing failures.

**Cause**: PowerShell reserves several variable names for automatic use. The most common collision in custom scripts and test helpers is `$Args` — PowerShell pre-populates it with unbound positional arguments. Even when you declare `[hashtable]$Args` as a parameter, callers passing `@{...}` may have their hashtable silently coerced to `System.Object[]`, producing `Cannot convert the "System.Object[]" value of type "System.Object[]" to type "System.Collections.Hashtable"`.

**Fix**: Rename the parameter. Common safe alternatives: `$Params`, `$Splat`, `$Arguments`, `$Options`.

```powershell
# ❌ Avoid — collides with PowerShell's $Args automatic
function Invoke-Helper { param([hashtable]$Args) ... }

# ✅ Safe
function Invoke-Helper { param([hashtable]$Params) ... }
```

**Other reserved automatic variables to avoid as parameters, iterators, or assignment targets**: `$Input`, `$MyInvocation`, `$PSItem` / `$_`, `$Error`, `$Host`, `$PSCmdlet`, `$ExecutionContext`, `$PWD`, `$PID`, `$Home`, `$PSScriptRoot`, `$PSCommandPath`, `$Matches`, `$LASTEXITCODE`, `$null`, `$true`, `$false`. The full list is in `Get-Help about_Automatic_Variables`. The collision site can be a parameter declaration, a `foreach` iterator, or any variable assignment — all three forms count. Surfaced 2026-05-14 during PF-IMP-871 Phase 2a synthetic-fixture test development (the `$Args` case above); a complementary case (PF-FEE-039) hit Push-FrameworkUpdate.ps1 via `foreach ($pid in $eligible.Keys)` — `$PID` is **read-only**, so the failure mode is `Cannot overwrite variable PID` rather than the silent `$Args`-style coercion.

### 🚨 Script-Level Functions Are Not Hoisted

**Issue**: A function called from a script-level `if` / early-exit block throws `CommandNotFoundException`, even though the function is defined lower in the same file. Common in dual-mode scripts (e.g. `-Scaffold` / `-Update`) whose mode branch sits above the helper definitions.

**Cause**: PowerShell executes a script top-to-bottom, and a `function Foo { }` definition only takes effect once execution reaches that line. Unlike JavaScript, script-level function declarations are **not hoisted**. A branch that runs (and may `exit`) before the definition line cannot see the function.

**Fix**: Declare all functions at the top of the script — immediately after `param()` and module imports, above any executable or early-exit logic.

```powershell
# ❌ Fails — Get-FeatureCategoriesFromTracking runs before its definition line
param([switch]$Update)
if ($Update) {
    $cats = Get-FeatureCategoriesFromTracking   # CommandNotFoundException
    exit 0
}
function Get-FeatureCategoriesFromTracking { ... }

# ✅ Works — definitions precede the mode branches that call them
param([switch]$Update)
function Get-FeatureCategoriesFromTracking { ... }
if ($Update) {
    $cats = Get-FeatureCategoriesFromTracking
    exit 0
}
```

Surfaced 2026-05-14 during PF-IMP-871 Phase 2b: `New-TestInfrastructure.ps1`'s parser functions were defined below the `-Update` branch that called them (~5 min to diagnose). Companion to the `$Args` automatic-variable footgun above.

### 🚨 Template Replacements Not Working

**Issue**: Placeholders like `[Feature Name]` remain unreplaced in generated documents

**Quick Fix**:
```powershell
# ✅ CORRECT - Use literal brackets
$customReplacements = @{
    "[Feature Name]" = $FeatureName
    "[Description]" = $Description
}

# ❌ WRONG - Don't escape brackets
$customReplacements = @{
    "/[Feature Name/]" = $FeatureName  # This won't work!
}
```

### 🚨 Script Fails in Different Directories

**Issue**: Script works from one directory but fails from another

**Quick Fix**:
```powershell
# Always use absolute paths for critical files
$templatePath = Join-Path $PSScriptRoot "../../templates/your-template.md"
$resolvedTemplatePath = Resolve-Path $templatePath
```

### 🚨 Wrapper Detection of Parameter-Binding Failures

**Issue**: A wrapper script iterates over inputs invoking a framework script, checks `$LASTEXITCODE` after each call to detect failures, and silently skips entries that failed `[ValidateLength]` / `[ValidateScript]` / `[ValidateSet]` validation. The wrapper reports success while one or more entries were never actually created.

**Cause**: PowerShell parameter-binding errors are terminating errors that fire *before* the script body runs. The script's own `try { ... } catch { ... }` block can't intercept them — by the time the body starts, the script has already exited. Critically, `$LASTEXITCODE` is **not set** by these failures (it's only set by native exits or explicit `exit N` calls inside the body). Wrappers relying on `$LASTEXITCODE` alone see `$null` and infer success.

**Fix**: In the wrapper, use `try { & $script ... } catch { ... }` instead of checking `$LASTEXITCODE`. The exception propagates from parameter binding cleanly.

```powershell
# ❌ Avoid — misses parameter-binding failures
foreach ($entry in $entries) {
    & $script @entry -Confirm:$false
    if ($LASTEXITCODE -ne 0) { Write-Warning "Failed: $($entry.Name)" }
}

# ✅ Safe — try/catch captures both param-binding and body errors
foreach ($entry in $entries) {
    try {
        & $script @entry -Confirm:$false -ErrorAction Stop
    } catch {
        Write-Warning "Failed: $($entry.Name) — $($_.Exception.Message)"
    }
}
```

> **Why not "fix the script to call `exit 1`"**: Parameter-binding failures happen outside the script body's execution. No top-level `try`/`catch` or `trap` inside the script can intercept them. Body-level `exit 1` after the fact can't help either — control never reached the body. The correct fix is at the call site.

Surfaced 2026-05-17 during the Framework Self-Testing extension (Bug C) when a wrapper looping over 11 workflow inputs silently skipped one whose `Description` failed a `ValidateScript` length check.

### 🚨 `-WhatIf` Output Is Not Capturable In-Process

**Issue**: A test runs a `SupportsShouldProcess` script with `-WhatIf` in the current session and tries to capture the `"What if:"` lines via `2>&1` / `*>&1`. The captured output is empty.

**Cause**: `ShouldProcess` `"What if:"` messages are written to the PowerShell **host**, not to the output / error / warning / verbose / information streams that redirection operators tap. In-process redirection never sees them.

**Fix**: Run the script in a child `pwsh.exe` process and capture its combined output — the child host renders the `"What if:"` lines to its stdout, which the parent captures via `2>&1`. This is one reason the [Subprocess + WhatIf + Side-Effect-Counting Test Pattern](#subprocess--whatif--side-effect-counting-test-pattern) uses a subprocess rather than an in-process call.

```powershell
# ✅ Subprocess capture (Update-ProcessImprovement.Tests.ps1)
$cmd = "& '$Script' -ImprovementId 'PF-IMP-001' -NewStatus 'InProgress' -WhatIf"
$whatIf = (pwsh.exe -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1) -join "`n"
$whatIf | Should -Match 'What if: Performing the operation'
```

Surfaced repeatedly during the Framework Self-Testing extension (2026-05-13 to 05-20) when asserting that side-effecting scripts reach their `ShouldProcess` gates.

### 🚨 Capturing `Write-Error` From a Script Under Test

**Issue**: A Pester test needs to assert on the error text a script emits, but the script reports failure via `Write-Error` (often a `Write-ProjectError` helper) followed by `exit 1`, not `throw`. Calling it in-process either aborts the test (governed by the caller's `$ErrorActionPreference`) or yields no catchable exception to inspect.

**Cause**: `Write-Error` + `exit` writes to the error stream and terminates; it does not surface a `throw`-style exception the test can catch. In-process, the error record is subject to the *caller's* `$ErrorActionPreference` and stream context, so its text cannot be asserted on cleanly.

**Fix**: Invoke the script as a subprocess and capture stderr. Two forms:

- **Inline `-Command` + `2>&1`** — simplest; merges stderr into the captured string:
  ```powershell
  $cmd = "& '$Script' -DryRun"   # missing required arg → Write-Error + exit 1
  $out = (pwsh.exe -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1) -join "`n"
  $out | Should -Match 'AssessmentId or AssessmentFile must be provided'
  ```
- **`Start-Process -RedirectStandardError <tempfile>`** — when stdout and stderr must stay separate (e.g. exit-code plus clean-stderr assertions):
  ```powershell
  $tempErr = [System.IO.Path]::GetTempFileName()
  $p = Start-Process pwsh.exe -ArgumentList @('-NoProfile','-File',$Script,'-Bad') `
      -RedirectStandardError $tempErr -Wait -PassThru -NoNewWindow
  $errText = Get-Content $tempErr -Raw
  Remove-Item $tempErr -Force
  ```

Surfaced across the Framework Self-Testing extension; the subprocess + tempfile form recurs across the orchestration / creation / update / validation test directories. Pairs with the [Subprocess + WhatIf + Side-Effect-Counting Test Pattern](#subprocess--whatif--side-effect-counting-test-pattern) above.

## Testing Checklist

**Before considering script complete**:

- [ ] Test module import from script directory
- [ ] Create test document and verify content
- [ ] Check all placeholders are replaced
- [ ] Verify ID assignment and registry update
- [ ] Test error handling with invalid inputs
- [ ] Clean up test files

## Common Patterns

### Robust Module Import Pattern
```powershell
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "../../scripts/Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers: $($_.Exception.Message)"
    exit 1
}
```

### Template Replacement Pattern
```powershell
$customReplacements = @{
    "[Feature Name]" = $FeatureName
    "[Description]" = if ($Description -ne "") { $Description } else { "Default description" }
    "[Date]" = Get-Date -Format "yyyy-MM-dd"
    "[Author]" = "AI Agent & Human Partner"
}
```

### Standard Document Creation Pattern
```powershell
$documentId = New-StandardProjectDocument `
    -TemplatePath "process-framework/templates/[SUBFOLDER]/your-template.md" `
    -IdPrefix "YOUR-PREFIX" `
    -IdDescription "Description for $FeatureName" `
    -DocumentName $FeatureName `
    -DirectoryType "your-directory-type" `
    -Replacements $customReplacements `
    -AdditionalMetadataFields $additionalMetadataFields `
    -OpenInEditor:$OpenInEditor
```

### Subprocess + WhatIf + Side-Effect-Counting Test Pattern

The canonical approach for testing side-effecting framework scripts (those that create files, update tracking tables, or modify registries). The three components work together:

1. **Subprocess isolation** — invoke the script under test via `pwsh.exe -NoProfile -ExecutionPolicy Bypass -Command` so the test host's module state, variables, and `$PSScriptRoot` don't leak into the script.
2. **`-WhatIf` mode** — the script body runs its full logic path but `ShouldProcess`-guarded operations (file writes, registry updates) are skipped, emitting `"What if:"` markers instead. This lets you assert that the script *reaches* each side-effect without *executing* it.
3. **Side-effect counting** — snapshot the affected directory or file state before and after the `-WhatIf` invocation. Assert that counts are unchanged. This catches leaks where a code path bypasses `ShouldProcess`.

```powershell
# Canonical example (from New-SourceStructure.Tests.ps1)

BeforeAll {
    $script:RepoRoot  = Resolve-Path (Join-Path $PSScriptRoot '../../../../..')
    $script:ScriptPath = Join-Path $script:RepoRoot 'blueprint/.../Script.ps1'
    $script:TargetDir  = Join-Path $script:RepoRoot 'target-dir'
}

Context '-WhatIf integration' {
    BeforeAll {
        # 1. Snapshot: count dirs/files before
        $script:PreCount = (Get-ChildItem $script:TargetDir -Directory).Count

        # 2. Subprocess: run with -WhatIf
        $cmd = "& '$($script:ScriptPath)' -Mode -WhatIf"
        $script:Output = (pwsh.exe -NoProfile -ExecutionPolicy Bypass `
            -Command $cmd 2>&1) -join "`n"

        # 3. Snapshot: count dirs/files after
        $script:PostCount = (Get-ChildItem $script:TargetDir -Directory).Count
    }

    It 'reaches the expected ShouldProcess marker' {
        $script:Output | Should -Match 'What if:.*Create.*'
    }

    It 'creates nothing on disk (side-effect check)' {
        $script:PostCount | Should -Be $script:PreCount `
            -Because '-WhatIf must not create files'
    }
}
```

**When to use**: Any Pester test for a framework `.ps1` that creates or modifies files. The pattern emerged during Framework Self-Testing Phase 3b–3d (2026-05-14) and is now the standard across `test/automated/unit/framework/`.

**When NOT to use**: Pure-function helpers (string transforms, slug generators, validators) that have no side effects — test those with direct invocation, no subprocess needed.

## Troubleshooting

### PowerShell Script Execution (AI Agents)

> **Single source of truth.** This section is the canonical reference for running framework PowerShell scripts. `CLAUDE.md` and `.ai-entry-point.md` (both appdev and project copies) carry only a short `-File` snippet plus a pointer here — keep the full recipe (preferred/fallback patterns, human-terminal usage, troubleshooting) in this section rather than duplicating it there.

**Before running any script, check its parameters first:**
```bash
pwsh.exe -ExecutionPolicy Bypass -File path/to/Script.ps1 -?
```
Do not guess parameter names — scripts use `ValidateSet` constraints that reject unknown values.

**Preferred pattern — `pwsh.exe -File`:**

Use `-File` with a direct relative path from the repo root. No `cd` needed, no quoting wrappers.

```bash
# Preferred pattern — direct path, escape $ with backslash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/ScriptName.ps1 -Param "value" -Confirm:\$false
```

**Example:**
```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/support/New-FeedbackForm.ps1 -DocumentId "PF-TSK-009" -TaskContext "Process Improvement" -FeedbackType "MultipleTools" -Confirm:\$false
```

**Why `-File` is preferred:**
- No `cd` into the script directory needed — use the path directly
- No bash single-quote wrapping needed
- No `&` call operator needed
- Only caveat: escape `$` with backslash (`\$false`) so bash doesn't interpret it as a variable

**Fallback — `pwsh.exe -Command`:** Use when you need PowerShell expressions, piped commands, or one-liners that aren't script files. Wrap the entire `-Command` argument in **bash single quotes**:

```bash
pwsh.exe -ExecutionPolicy Bypass -Command '& process-framework/scripts/file-creation/ScriptName.ps1 -Param "value" -Confirm:$false'
```

**For human users:** You can use either pattern directly in your terminal — both work fine for interactive use.

**Historical context:** Prior to 2026-02-28, the Bash tool could not capture `pwsh.exe -Command` output. A temp file pattern was the only working approach. This was resolved and `-Command` with bash single quotes works correctly. As of 2026-04-04, `-File` is the preferred pattern for its simplicity.

**Bash-tool pipe buffering with long-running scripts:** Piping a long-running `pwsh.exe` invocation directly to `tail -N`, `head -N`, `grep`, or similar can appear hung or return only partial output. `tail` buffers stdin until EOF; pytest and other tools may also buffer summary lines when stdout is non-TTY. **Recipe**: redirect to a log file, then read it after completion:

```bash
pwsh.exe -ExecutionPolicy Bypass -File path/to/Script.ps1 > /tmp/script.log 2>&1
tail -80 /tmp/script.log
```

For scripts taking >30s, prefer the Bash tool's `run_in_background: true` and read the log when done — avoids tying up the foreground waiting on a pipe that may never flush.

### Double Quotes in `echo` Cause Garbled Paths (Historical)

> **Note:** This issue only applies to the legacy `echo ... > temp.ps1` pattern. With either the `-File` or `-Command` patterns, this problem does not occur.

**Symptom:** When using the old temp file pattern, script runs successfully (Exit Code 0) but creates a nested directory structure instead of the expected file.

**Cause:** cmd.exe interprets `"` double quotes inside an `echo` command, garbling parameter values.

**Solution:** Use the preferred `-File` pattern instead:

```bash
# ✅ Preferred — direct path
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-FDD.ps1 -FeatureId "3.1.1" -FeatureName "Parser Framework" -Confirm:\$false
```

### Script Fails with "Out-Null" Errors

**Symptom:** Files aren't created when running scripts, or you see unexpected behavior with directory creation.

**Cause:** The `| Out-Null` pattern is used extensively to suppress unwanted output from `New-Item -ItemType Directory -Force`. Without it, PowerShell returns a `DirectoryInfo` object that can interfere with function return values and `-WhatIf` mode.

**Solution:** This is by design - the `| Out-Null` pattern is correct and necessary:

```powershell
# Correct pattern - suppresses directory creation output
New-Item -ItemType Directory -Path $directory -Force | Out-Null
```

If files aren't being created, check that you're not running with `-WhatIf` flag, which prevents actual file creation by design.

## Related Resources

- [Document Creation Script Development Guide](document-creation-script-development-guide.md) - Comprehensive, standardized approach for creating documents from templates through PowerShell scripts (this quick reference is its troubleshooting companion)
- [Template Development Guide](template-development-guide.md) - Developing and maintaining the framework templates these scripts consume
