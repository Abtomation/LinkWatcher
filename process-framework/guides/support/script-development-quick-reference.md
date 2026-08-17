---
id: PF-GDE-019
type: Process Framework
category: Guide
version: 1.9
created: 2025-07-21
updated: 2026-08-13
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
- _(optional)_ PowerShell module `PSScriptAnalyzer` installed (`Install-Module PSScriptAnalyzer -Scope CurrentUser`) — used by the script-convention gate (`Run-ScriptConventionGate.ps1`)

## Background

This quick reference addresses the most common issues encountered when developing document creation scripts for the project, based on real implementation experiences from the Database Schema Design Task and other script implementations.

## Quick Fixes

> **Jump by theme** — the fixes below, grouped by the kind of problem they solve:
>
> - **Modules & path resolution**: Module Import Failures · Import Warnings (unapproved verbs) · Sub-Module Function Scoping · Script Fails in Different Directories
> - **PowerShell language footguns**: Reserved Automatic Variables · Functions Not Hoisted · Single-Match Scalars · Single-Quoted Literal Quotes · Typographic Quotes Are Delimiters · `-replace` Bracketed Literals Are Regex · Unparenthesized `-replace` Pattern Swallows the Replacement · Array, `[bool]` & `[hashtable]` Params Don't Survive `-File` · Returning a Collection Unwraps It
> - **Exit codes & invocation**: Wrapper Parameter-Binding Failures · `exit N` Through the `&` Operator
> - **Testing framework scripts (Pester / host)**: `-WhatIf` Not Capturable · `ShouldProcess`-Gated Log Lines · Capturing `Write-Error` · `Update-*` Default-Quiet Needs `-Verbose` · Testing Mandatory Parameters · Angle-Bracket Tokens in Pester Names · `Should -BeLike` Bracketed Literals · Phantom Parameters Survive `-WhatIf`-Only Suites
> - **Templates, doc-map & refactor hygiene**: Template Replacements · Doc-Map Description From First `.SYNOPSIS` Paragraph · Removing a Code Path or Doc Subsection Leaves Residue
>
> When you add a Quick Fix entry, add its short title to the matching group above.

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

**When an import cycle forbids sharing, extract — never duplicate.** The fix above works because the dependency runs one way. Where two modules need the *same* logic and a cycle blocks it (`Core.psm1` imports `IdRegistry.psm1`, so IdRegistry cannot import back), move it to a **leaf module both import** — no outgoing imports means it cannot close a cycle. Duplicating buys a parity guard maintained forever covering only the pairs someone listed; the drifting pair is typically the unlisted one. Unrelated to per-level file twins, which *are* meant to be duplicated.

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

### 🚨 Single-Match Pipeline Results Are Scalars, Not Arrays

**Issue**: `($lines | Where-Object { ... })[0]` returns the first **character** instead of the first line when exactly one line matches.

**Cause**: PowerShell unwraps single-element pipeline output to a scalar. With one matching string, `[0]` indexes into the string and yields a `[char]`; with two or more matches it returns the expected first element — so the defect only appears on single-match data and survives most testing.

**Fix**: force an array or take explicitly:

```powershell
# ❌ Fragile — works for 2+ matches, returns a [char] for exactly 1
$first = ($lines | Where-Object { $_ -match $pattern })[0]

# ✅ Safe forms
$first = @($lines | Where-Object { $_ -match $pattern })[0]
$first = $lines | Where-Object { $_ -match $pattern } | Select-Object -First 1
```

Surfaced 2026-06-04 during a PRJ-001 Mode C migration (a ToC rewrite blanked an entry to a bare `-`). Companion to the `$Args` automatic-variable and function-hoisting footguns above.

### 🚨 Single-Quoted Strings Need `''` to Embed a Literal `'`

**Issue**: Pasting example code that contains a single quote into a **single-quoted** string — e.g. a `$L.Add('...')` skeleton/hint line in a creation script — silently breaks it: the embedded `'` ends the literal early and the rest is mis-parsed, so the emitted text is mangled.

**Cause**: In a single-quoted (verbatim) PowerShell string the only escape is a **doubled** quote — `''` yields one literal `'`; backtick escaping does not apply inside single quotes. Framework creation scripts build emitted hint/skeleton text from single-quoted `.Add('...')` lines, so any example code containing `'` must have each quote doubled.

```powershell
# ❌ Embedded quotes terminate the literal — parse error / mangled output
$L.Add('  -replace '<old>','<new>'')

# ✅ Double each embedded single quote
$L.Add('  -replace ''<old>'',''<new>''')   # emits:   -replace '<old>','<new>'
```

Surfaced 2026-06-26 (PF-IMP-1325 / PF-FEE-1480) adding example code to `New-PendingMigration.ps1`'s `New-EntrySection` hint lines. Companion to the `$Args` / hoisting / single-match entries above.

### 🚨 Typographic Quotes Are Real String Delimiters (Silent Early Close)

**Issue**: A curly apostrophe pasted into a **straight** single-quoted string closes it early. The line looks correct on inspection — the two glyphs render almost identically — and the parse error names a token from a *later* line, so re-reading the named line finds nothing wrong.

**Cause**: PowerShell's tokenizer accepts the typographic quotes `‘ ’ “ ”` (U+2018/2019/201C/201D) as string delimiters, fully interchangeable with `'` and `"`. Measured: `‘hello’`, `“hello”`, even `’hello’`, all parse and evaluate to `hello` — and a `’` **closes a string opened with a straight `'`**. Prose pasted from a document, a chat window, or an editor with smart quotes carries these invisibly.

```powershell
# ❌ The ’ CLOSES the string opened at the straight quote; `t` is then an unexpected
#    token, and the parser consumes the REST OF THE FILE hunting for a terminator
$msg = 'the run didn’t reach the gate'

# ✅ Straight apostrophe, doubled per the entry above
$msg = 'the run didn''t reach the gate'
```

Because the run-on string swallows every following line, the second error's message quotes code far from the defect — which is what makes it read as a problem further down the file. Sweep for them rather than hunting one:

```powershell
Select-String -Path <path> -Pattern '[‘’“”]'
```

Distinct from the entry above: there the delimiter is the right character and needs doubling; here it is a *different* character PowerShell honours anyway, so the fix replaces the glyph rather than escaping it. Surfaced 2026-08-12 (PF-PRO-068 S3 E4-c) as a Pester discovery failure; mechanism measured 2026-08-13.

### 🚨 `-replace` Treats a Bracketed Literal as a Regex Character Class (Silent No-Op)

**Issue**: A config-key substitution like `'stages: [commit]' -replace 'stages: [commit]', 'stages: [pre-commit]'` returns the string unchanged — no error, no match, a no-op that looks like success.

**Cause**: `-replace`'s pattern operand is a **regex**, not a literal. `[commit]` is a character class (one character from `c/o/m/i/t`), so the pattern never matches the literal brackets in the text. Any search literal containing `[ ] ( ) . + ? * ^ $ \ |` silently changes meaning the same way.

**Fix**: use the literal `.Replace()` String method, or escape the search literal:

```powershell
# ❌ Silent no-op — [commit] is a character class; the literal '[' is never matched
$content = $content -replace 'stages: [commit]', 'stages: [pre-commit]'

# ✅ Literal string replacement (also keeps the replacement side literal — in -replace,
#    a $ in the replacement text triggers regex substitution syntax like $1)
$content = $content.Replace('stages: [commit]', 'stages: [pre-commit]')

# ✅ Regex replacement with the search literal escaped
$content = $content -replace [regex]::Escape('stages: [commit]'), 'stages: [pre-commit]'
```

Surfaced 2026-07-17 (PF-IMP-1609 / PF-FEE-1638) preparing a pre-commit `stages:` substitution for a Framework Rollout Mode C migration entry — a silent no-op there would have produced a "migration applied" record against an unchanged file; caught by testing the expression before filing it, not by review. Companion to the single-quoted-literal entry above.

### 🚨 An Unparenthesized `-replace` Pattern Swallows the Replacement (Silent No-Op or Deletion)

**Issue**: A `-replace` whose pattern is built by concatenation — `$text -replace '^prefix:\s*' + [regex]::Escape($old) + '\s*$', "prefix: $new"` — changes nothing. No error, no warning; a loop around it reports every file as processed while writing identical content back.

**Cause**: `,` binds tighter than `+`, so the replacement string is absorbed into the **pattern** operand. `-replace` receives one argument instead of two, which means *replace matches with the empty string* — and the pattern, now carrying the replacement text, no longer matches anything:

```powershell
$arg = '^workflow:\s*' + [regex]::Escape($old) + '\s*$', "workflow: $new"
$arg.GetType().Name   # String — not the 2-element array you intended
$arg                  # ^workflow:\s*feedback-collection\s*$ workflow: WF-004
```

The failure is silent in both directions: usually a **no-op** (the mangled pattern matches nothing), but if it *does* match, the single-argument form **deletes** the matched text.

**Fix**: parenthesize the pattern whenever it is an expression rather than a literal.

```powershell
# ❌ Replacement is concatenated into the pattern — silent no-op
$new = $raw -replace '(?m)^workflow:\s*' + [regex]::Escape($old) + '\s*$', "workflow: $id"

# ✅ Parenthesized pattern — -replace gets both operands
$new = $raw -replace ('(?m)^workflow:\s*' + [regex]::Escape($old) + '\s*$'), "workflow: $id"

# ✅ Or build the pattern first, which also reads better under review
$pattern = '(?m)^workflow:\s*' + [regex]::Escape($old) + '\s*$'
$new = $raw -replace $pattern, "workflow: $id"
```

Surfaced 2026-07-22 (PF-IMP-1699) in a backfill script: 13 files were reported updated and none were written. The tell is a run whose **self-reported count disagrees with the files on disk** — verify a batch mutation by re-reading the targets, never by trusting the loop's own tally. Companion to the bracketed-literal entry above — both are silent `-replace` failures, and both are caught by testing the expression on one sample before running it over a set.

### 🚨 Array Parameters Don't Survive `pwsh -File` Invocation

**Issue**: A script with a `[string[]]` (array) parameter is invoked via `pwsh.exe -File Script.ps1 -Items a,b,c` and the array arrives malformed — the whole comma-string as a **single** element, or (space-separated) silently truncated to just the first token — so per-element `[ValidatePattern]` rejects it or downstream loops process the wrong data.

**Cause**: `-File` passes the remaining command-line tokens to the script as **literal strings**, with no PowerShell array parsing. `-Items a,b,c` binds the whole `"a,b,c"` as one element; `-Items a b c` binds only `a` and drops the rest. Only the in-session parser — used by `-Command`, dot-sourcing, or splatting — turns `a,b,c` into a real 3-element array. The same literal-token rule breaks `[bool]` parameters: `-BackupFile $false` passes the string `$false`, which fails `[bool]` binding with a conversion error — only `[switch]` parameters accept the colon form (`-Confirm:$false`) under `-File`; a `[bool]` has no `-File`-passable form. `[hashtable]` parameters are the third member of the class: `-LanguageValues @{ python = 'x' }` under `-File` binds the literal token `@{` and fails with `Cannot convert the "@{" value of type "System.String" to type "System.Collections.Hashtable"` — only `-Command` parses a hashtable literal. And once forced onto `-Command`, a second trap: an escaped double quote inside **any sibling string argument** terminates that string early and misreports as a binder error naming the wrong argument entirely (`A positional parameter cannot be found that accepts argument '...'`) — the quoting defect is never named; keep sibling arguments free of embedded quotes or read the quote-heavy value from a file (see the `-Command` hazard box under [PowerShell Script Execution (AI Agents)](#powershell-script-execution-ai-agents)).

**Fix**: For array or `[bool]` parameters, invoke via `-Command` (wrap in bash single quotes), pass a delimited string the script splits itself, or use a batch/JSON-file input.

```bash
# ❌ -File: -Items arrives as ONE element "a,b,c" (or just "a" when space-separated)
pwsh.exe -ExecutionPolicy Bypass -File Script.ps1 -Items a,b,c

# ✅ -Command: PowerShell parses a,b,c into a real 3-element array
pwsh.exe -ExecutionPolicy Bypass -Command '& Script.ps1 -Items a,b,c'
```

When a script must stay `-File`-invocable, have it **split the delimiter itself**. For a *new* parameter, take a delimited string (e.g. `New-ProcessImprovement.ps1 -Supersedes "PF-IMP-810,PF-IMP-811"` takes a CSV string, not `[string[]]`) or a batch-JSON input. For an *existing* `[string[]]` parameter, keep the array type and split each element — `-split` applies per element, so the one-element `"a,b"` that `-File` binds and the real 2-element array that `-Command` binds both yield the same list:

```powershell
[string[]]$Project = @()
...
$ids = @($Project -split '[,\s]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
```

Prefer this over retyping the parameter to `[string]`: parameter binding **throws** on an array bound to `[string]` (`Cannot convert value to type System.String`) — it does not join it — so retyping silently breaks every in-session/`-Command` caller that passes a real array. See [PowerShell Script Execution (AI Agents)](#powershell-script-execution-ai-agents) for the `-File`/`-Command` distinction.

Surfaced 2026-06-16 (PF-IMP-1163 (a) / PF-IMP-1250; PF-FEE-1316); the `[bool]` sibling surfaced 2026-07-06 (PF-IMP-1419 / PF-FEE-1552) migrating a test against `Add-MarkdownTableColumn.ps1`'s `[bool]$BackupFile`. The split-in-place fix for an existing `[string[]]` param, and the array-to-`[string]` binding throw that rules out retyping, were established 2026-07-14 (PF-IMP-1428 / PF-FEE-1539) on `Push-FrameworkUpdate.ps1 -Project`. The `[hashtable]` sibling and the misleading sibling-quote binder error surfaced 2026-07-30 (PF-IMP-1857 / PF-FEE-1717) on `Update-LanguageConfig.ps1 -LanguageValues`. Companion to the single-match scalar footgun above.

### 🚨 Returning a Collection From an `if`/`switch` Unwraps It — and a Typed Param Then Binds a Copy

**Issue**: A function returns a `[List[T]]` (or other collection) built inside an `if`/`switch` block, and the caller receives `object[]` instead of the `List`. Worse, when that `object[]` is passed to a typed `[List[T]]` parameter, in-place `.Add()` mutations inside the callee are **invisible** to the caller.

**Cause**: Two compounding behaviors:
1. A value emitted from inside a block (implicit, or via `return`) is written to the pipeline, which **enumerates** the collection — a `[List[T]]` decays to `object[]` (and a single-element collection decays to a scalar, per the footgun above).
2. Passing `object[]` to a typed `[List[T]]` parameter makes PowerShell **convert-and-copy** into a fresh `List[T]`; the callee mutates the copy, not the caller's array. (A *genuine* `List[T]` passed to a `List[T]` param binds by reference — mutations propagate.)

**Fix**: Prevent enumeration on return with the unary comma operator (`,$collection`) or `Write-Output -NoEnumerate`; this preserves the `List[T]` type so a later typed-param bind is by-reference.

```powershell
# ❌ Caller gets object[]; a later typed-[List[T]]-param .Add() is then lost
function Get-Items { if ($cond) { $l = [Collections.Generic.List[string]]::new(); $l.Add('x'); $l } }

# ✅ Unary comma preserves the List[T] type out of the block
function Get-Items { if ($cond) { $l = [Collections.Generic.List[string]]::new(); $l.Add('x'); ,$l } }
```

Surfaced 2026-06-16 (PF-IMP-1146). Companion to the single-match scalar footgun above — both are pipeline-enumeration gotchas.

### Doc-Map Description Comes From the First `.SYNOPSIS` Paragraph

[`Build-DocumentationMap.ps1`](../../scripts/validation/Build-DocumentationMap.ps1) renders each artifact's one-line map description from the **first paragraph** of its `.SYNOPSIS` — the contiguous non-blank lines joined with single spaces, stopping at the first blank line, the next help directive, or `#>` (PF-IMP-1272). The same first-paragraph rule applies to `.py` module docstrings and the module-level `.SYNOPSIS` of a `.psm1`; the `.DESCRIPTION` is never indexed.

**Authoring guidance**: keep that first paragraph to one concise sentence — the *whole* paragraph is rendered, so a rambling multi-sentence paragraph produces a bloated map line. Put elaboration in `.DESCRIPTION`, separated by a blank line so it stays out of the indexed description. Wrapping a single sentence across lines is safe.

```powershell
# ✅ One concise paragraph — rendered in full even when it wraps across lines
<#
.SYNOPSIS
    Generates the documentation map from each artifact's
    own .SYNOPSIS / frontmatter description.
.DESCRIPTION
    Longer multi-line elaboration belongs here, where length is unconstrained.
#>
```

A wrapped synopsis was previously truncated mid-sentence (PF-IMP-1025 / PF-FEE-1237, 2026-06-08); the generator now joins the first paragraph (PF-IMP-1272). Verify the rendered description with `Build-DocumentationMap.ps1 -Check`.

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

### 🚨 `exit N` Does Not Propagate Through the `&` Call Operator (Use a Terminating Error)

**Issue**: A script guards a failure with `exit 2`, but a caller that invoked it with the `&` call operator — `pwsh -Command "& script.ps1 …"`, or a parent `.ps1` running `& .\child.ps1` — sees exit `0` and treats the run as a pass, silently green-lighting a no-op or failed run.

**Cause**: `exit N` propagates the code reliably only when the script is the process entry point — `pwsh.exe -File script.ps1` exits `N`. Invoked with `&`, the script runs in a child scope; `exit N` unwinds **only that scope** and returns control to the caller without terminating it or setting its exit code. The caller then runs to normal completion and exits `0` (or `1` if the `&` call was its last statement) — never the intended `N`. A script with a non-`-File`-passable parameter (e.g. a mandatory `[hashtable]`) *must* be invoked via `&`, so it is always exposed.

**Fix**: When a non-zero exit must survive a nested `&` invocation, raise a **terminating error** — a `throw`, or `Write-Error` under `$ErrorActionPreference = 'Stop'`. The exception unwinds the whole call stack, so the outer `pwsh` reliably exits non-zero.

```powershell
# ❌ Swallowed when run via `& script.ps1` / `-Command "& ..."` — caller sees exit 0
if ($noOutput) { Write-Warning "no-op run"; exit 2 }

# ✅ Terminating error propagates a reliable non-zero exit through `&`
$ErrorActionPreference = 'Stop'
if ($noOutput) { Write-Error "INCONCLUSIVE: no-op run" }   # throws → outer pwsh exits non-zero
```

Note the asymmetry: `pwsh -File script.ps1` **does** propagate `exit N` — it is the `&` call operator, not `-File`, that drops the code. Surfaced 2026-06-25 (PF-IMP-1322 / PF-FEE-1476) hardening `Compare-CreationGolden.ps1`, whose mandatory `[hashtable]$ScriptArgs` forces `&` invocation; an `exit 2` empty-output guard returned exit 0 and would have passed a vacuous run. Companion to the *Wrapper Detection of Parameter-Binding Failures* entry above.

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

### 🚨 A Log Line Inside a `ShouldProcess` Block Doesn't Run Under `-WhatIf`

**Issue**: A test asserts on a WARN/INFO line a `SupportsShouldProcess` script emits, but the capture is empty under `-WhatIf` — even when taken from a subprocess.

**Cause**: The line sits *inside* `if ($PSCmdlet.ShouldProcess(...)) { ... }`. Under `-WhatIf`, `ShouldProcess` returns `$false`, so the gated body — and every line in it — never executes. Distinct from [`-WhatIf` Output Is Not Capturable In-Process](#--whatif-output-is-not-capturable-in-process) above: there the gate *fires* and only the `"What if:"` host message escapes redirection; here the gated line *never runs at all*, so nothing exists to capture.

**Fix**: Assert the line where it actually executes — a **real run against a sandbox fixture** (no `-WhatIf`), or at the **source level** (assert the line is present in the gated block). Reserve `-WhatIf` for asserting the `"What if:"` markers themselves; the [Subprocess + WhatIf + Side-Effect-Counting Test Pattern](#subprocess--whatif--side-effect-counting-test-pattern) proves the gate is *reached* without executing the body.

```powershell
# ❌ Never emitted under -WhatIf — ShouldProcess returns $false, the block is skipped
if ($PSCmdlet.ShouldProcess($target, 'Update')) {
    Write-Warning "stale row detected"
}

# ✅ Assert it on a real run against a sandbox fixture (no -WhatIf)
$out = (pwsh.exe -NoProfile -ExecutionPolicy Bypass -Command "& '$Script' -Target '$fixture'" 2>&1) -join "`n"
$out | Should -Match 'stale row detected'
```

Surfaced twice in the 2026-06-30 cycle (PF-FEE-1512, PF-FEE-1516); the second was a latent self-test bug (PF-IMP-1350) that a `-WhatIf` regression pass missed because the asserted line never ran. Companion to the [`-WhatIf` Output Is Not Capturable In-Process](#--whatif-output-is-not-capturable-in-process) entry above.

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

Either way the captured text is the child's **console-rendered** error, word-wrapped at the child's console width (120 columns in a redirected host) — a long message can wrap mid-phrase and silently flip a `-Match`/`-Not -Match` assertion, so keep asserted spans short, and prefer asserting supplied-value validation errors in-process (`{ & $script -Bad 'x' } | Should -Throw`, safe per [Testing Mandatory Parameters](#-testing-mandatory-parameters-without-triggering-the-interactive-prompt)), where the raw exception message is wrap-free (PF-IMP-1474).

Surfaced across the Framework Self-Testing extension; the subprocess + tempfile form recurs across the orchestration / creation / update / validation test directories. Pairs with the [Subprocess + WhatIf + Side-Effect-Counting Test Pattern](#subprocess--whatif--side-effect-counting-test-pattern) above.

### 🚨 `Update-*` Scripts Log Default-Quiet — Pester Assertions on INFO Text Need `-Verbose`

**Issue**: A Pester test asserts on an `Update-*` script's INFO/SUCCESS log text (e.g. "Found improvement entry…", "Updated … status to…") and the assertion fails on an empty capture, even though the script ran correctly.

**Cause**: The `Update-*` scripts log **default-quiet** via the shared `Write-ProjectLog`: INFO/SUCCESS go to `Write-Verbose` (visible only under `-Verbose`); only WARN/ERROR and the single `Write-ProjectSummary` outcome line reach the host. A capture taken without `-Verbose` never sees the INFO/SUCCESS text. Canonical logger: `Write-ProjectLog` / `Write-ProjectSummary` in [OutputFormatting.psm1](../../scripts/Common-ScriptHelpers/OutputFormatting.psm1) (promoted from the per-script `Write-Log` / `Write-SummaryLine` copies, PF-IMP-1327).

**Fix**: Run the script under test with `-Verbose` and capture via `2>&1` so the verbose stream is merged in, or assert on the always-emitted summary line / WARN / ERROR instead.

```powershell
# ✅ Subprocess capture WITH -Verbose so INFO/SUCCESS render into the merged stream
$cmd = "& '$Script' -ImprovementId 'PF-IMP-001' -NewStatus 'InProgress' -Verbose"
$out = (pwsh.exe -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1) -join "`n"
$out | Should -Match 'Updated .* status to'
```

> **Why a module logger needs an explicit verbose-preference resolve**: `Write-ProjectLog` reads the *caller's* `$VerbosePreference` itself (`$PSCmdlet.GetVariableValue('VerbosePreference')`) rather than trusting PowerShell's implicit advanced-function `-Verbose` inheritance. That inheritance reaches a module function under `pwsh -File script -Verbose` but **not** under `pwsh -Command "& script -Verbose"` — the `&`-call form the test suites use. A plain in-script `Write-Log` resolved `$VerbosePreference` by dynamic scope and so worked under both; a module advanced function does not, so without the explicit resolve every `-Command "& … -Verbose"` capture of INFO/SUCCESS comes back empty. Carry that resolve into any new module-level default-quiet logger.

Surfaced 2026-06-16 (PF-IMP-1163 (c); PF-FEE-1339); the `&`-call propagation gap surfaced 2026-06-27 (PF-IMP-1327) during the logger consolidation. Companion to the output-capture entries above and to the [`exit N` through `&`](#-exit-n-does-not-propagate-through-the--call-operator-use-a-terminating-error) entry (both are `&`-call-operator footguns).

### 🚨 Testing Mandatory Parameters Without Triggering the Interactive Prompt

**Issue**: A Pester test asserts that a script rejects a missing required parameter via in-process invocation — `{ & $script -WhatIf } | Should -Throw` with the parameter omitted. The suite passes in most contexts but freezes the entire Pester host indefinitely when run in a detached interactive-capable host (background shell, hidden window).

**Cause**: A missing `[Parameter(Mandatory)]` value does not throw — the parameter binder *prompts* for it (`Supply values for the following parameters:`). The outcome depends on the host: `-NonInteractive` and EOF-stdin hosts convert the prompt to an immediate error (test passes), but an interactive-capable host with an open, silent stdin waits forever for input that never comes. Validation attributes on *supplied* values (`ValidateSet`, `ValidateLength`, `ValidateRange`, `ValidateScript`) always throw and are safe to test in-process — only the missing-Mandatory path has the interactive fallback.

**Fix**: Assert the declaration through parameter metadata — same contract, no execution, no prompt possible in any host:

```powershell
It 'requires the FeatureName parameter' {
    (Get-Command $script:ScriptPath).Parameters['FeatureName'].Attributes.Where({
        $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory |
        Should -Contain $true
}
```

When the test must exercise the *runtime* failure (e.g., asserting error text), run it as a subprocess with `-NonInteractive` so the prompt deterministically becomes an error — see [Capturing `Write-Error` From a Script Under Test](#-capturing-write-error-from-a-script-under-test) above.

Surfaced 2026-06-11 (PF-IMP-1114) when the creation-category suite hung 95 minutes in a detached background host; 28 missing-Mandatory cases across 13 test files were converted to declaration assertions.

### 🚨 Phantom Parameters on Shared Helpers Survive `-WhatIf`-Only Suites

**Issue**: An update script calls a shared helper with parameters the helper does not declare (e.g. `Get-StateFileBackup -FilePaths ... -BackupPrefix ...`), or calls a function that exists nowhere — and its Pester suite stays green while every real run fails or partial-writes.

**Cause**: Two gaps compound. The phantom binding sits on the **real-write path**, which `-WhatIf`/`-DryRun`-only coverage never executes — so it only fires in production. And while the script-convention gate's AST check ([Run-ScriptConventionGate.ps1](../../scripts/validation/Run-ScriptConventionGate.ps1), PF-IMP-1328/1344) catches calls to **undefined functions** fleet-wide at commit time, a phantom **parameter** on a real function is invisible to it — nothing binds until the call runs.

**Fix**: pair the `-WhatIf` tests with the two guards that fire at test time:

1. **Real-write coverage via the project-root override seam** — set `$env:FRAMEWORK_PROJECT_ROOT_OVERRIDE` to a TestDrive sandbox fixture so root resolution (both `Get-ProjectRoot` and IdRegistry's inlined `Resolve-ProjectRootForRegistry`) lands in the sandbox, run the script for real, and assert the write **on disk**. The override throws if the path doesn't exist; central writes have the analogous `$env:FRAMEWORK_CENTRAL_OVERRIDE`. Canonical example: the `Update-FeatureTrackingStatus` real-write Describe in appdev's FeatureTracking helper suite.
2. **Source-level phantom-parameter assertion** — for each shared helper the script calls, assert every named parameter used actually exists on the helper:

```powershell
It 'passes only declared parameters to Get-StateFileBackup' {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$null)
    $calls = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and
        $n.GetCommandName() -eq 'Get-StateFileBackup' }, $true)
    $declared = (Get-Command Get-StateFileBackup).Parameters.Keys
    foreach ($call in $calls) {
        foreach ($p in $call.CommandElements.Where({ $_ -is [System.Management.Automation.Language.CommandParameterAst] })) {
            $declared | Should -Contain $p.ParameterName
        }
    }
}
```

**Adopt on touch** (PF-IMP-1737): when you next edit an update script whose Pester suite is still `-WhatIf`-only, add real-write coverage in the same change — the same consolidate-on-touch device the [table-surgery helpers](#markdown-table-surgery-pattern) use; suites are not swept proactively. At the time this was recorded, 17 of 18 update-script suites still had no real-write coverage.

Surfaced 2026-07-13 (PF-IMP-1384 / PF-FEE-1590): phantom `Get-StateFileBackup` parameters and writes to removed columns survived two `-WhatIf`-only test passes in two update scripts; a phantom `Sync-CrossReferencedFiles` call (PF-IMP-1339) from the same cycle drove the convention gate's undefined-function check. The override seam and this pattern landed under PF-IMP-1573. Companion to the [Subprocess + WhatIf + Side-Effect-Counting Test Pattern](#subprocess--whatif--side-effect-counting-test-pattern) — that pattern proves gates are *reached*; this one proves the gated body actually *works*.

### 🚨 Angle-Bracket Tokens in Pester `It`/`Describe` Names

Pester v5 **always** expands a literal `<token>` in a test name as the subexpression `$($token)` — no `-ForEach` needed. An unknown token blanks silently; one containing a hyphen (`<00-setup>` → `$($00-setup)`) throws a `ParseException` *at run time* (passes discovery, fails only on execution). Use bracket-free names, or backtick-escape: `` `<00-setup`> ``.

Surfaced 2026-06-25 (PF-IMP-1306).

### 🚨 `Should -BeLike` Treats a Bracketed Literal as a Wildcard Character Class

**Issue**: An assertion against content carrying bracketed literals — template placeholders like `[Artifact name]`, table IDs like `[C-1]` — fails against *correct* content, or passes against content that never contained the literal.

**Cause**: `-BeLike` matches with PowerShell wildcards, where `[...]` is a **character class**, not a literal. Two failure modes, and the quiet one is the dangerous one:

- **Invalid range** — `[C-1]` (`C` sorts after `1`) throws `WildcardPatternException: The specified wildcard character pattern is not valid`. Loud, but the failure output points at the assertion, not at the bracket.
- **Valid class** — `[Artifact name]` matches **one character** from that set, so `'*[Artifact name]*'` matches the string `totally unrelated text`. A positive `Should -BeLike` then **passes vacuously** and proves nothing.

**Fix**: assert literal containment, or escape the literal for regex:

```powershell
# ❌ Bracketed literal — throws, or passes vacuously
$content | Should -BeLike '*[Artifact name]*'

# ✅ Literal containment
$content.Contains('[Artifact name]') | Should -BeTrue

# ✅ Regex with the literal escaped
$content | Should -Match ([regex]::Escape('[Artifact name]'))
```

The assertion-layer twin of [`-replace` Bracketed Literals Are Regex](#--replace-treats-a-bracketed-literal-as-a-regex-character-class-silent-no-op) — same bracket blindness, different operator. Surfaced 2026-07-23 (PF-IMP-1754 / PF-FEE-1697) asserting that table rows containing `[C-1]` and `[Artifact name]` survived a filter; the assertion failed against correct code and the output pointed at an unrelated document section. Exposure is broad because framework suites routinely assert on template content full of `[Placeholder]` tokens.

### 🚨 Removing a Code Path or Doc Subsection Leaves Residue (Stale Help, Dead Branches, Coupled Tests, Orphaned Prose)

**Issue**: A refactor removes a code path — a helper, a step, or a return field the script no longer emits — but leaves references that still parse and run silently: stale `.SYNOPSIS` / `.DESCRIPTION` / comment text describing the gone behavior, and dead conditional branches testing a return field that is never set again (e.g. `if ($result.RemovedField)`, now always false). The dead branch never throws — it just never runs — so the suite stays green and only a grep finds it. Residue also hides in the **test suite**: a test in *any* suite — not just the path's own — that derived its expected output or error from the removed path keeps asserting against behavior that no longer exists, silently invalidated rather than failing loudly.

**Fix**: In the **same change** that removes the path, grep the affected scripts **and the test suite** for all three code-path residue kinds and clean them:

```powershell
# (a) stale help / comment references to the removed behavior
Select-String -Path <scripts> -Pattern '<removed-term>'
# (b) dead branches on the removed return field
Select-String -Path <scripts> -Pattern '\$result\.<RemovedField>'
# (c) tests (in ANY suite) coupled to the removed path's output/errors — not just the path's own tests
Select-String -Path <test-suite> -Pattern '<removed-error-or-output-string>'
```

Those greps are for **discovery**. When you *pin* the removal in a Pester assertion, match the call in the **AST**, not the source text: `Should -Not -Match 'Verb-Noun'` also matches the `.SYNOPSIS` or comment line explaining the removal, so the most natural follow-up to removing a call — writing a note saying you removed it — turns an unrelated test red later.

```powershell
# ❌ Text-match — a comment naming the removed call fails this
$script:Source | Should -Not -Match 'Get-StateFileBackup'

# ✅ CommandAst — only real invocations count
$ast = [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$null)
@($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and
    $n.GetCommandName() -eq 'Get-StateFileBackup' }, $true)).Count | Should -Be 0
```

The same split applies to a removed *parameter*: assert `(Get-Command $script).Parameters.Keys | Should -Not -Contain '<Name>'`, which a mention in prose cannot trip.

**Doc content has its own residue — and greps don't find it**: deleting a subsection from a task or guide leaves orphaned list tails, bullets stranded under a removed heading, and lead-ins that no longer match what follows (a "three principles" sentence above two). None of it carries a greppable token or leaves a blank-line signature, so a pattern-shaped check — grepping the residue kinds you thought of — passes on a section that is still broken. **Verify by reading the enclosing section in full**: print it end to end and confirm every surviving line still belongs, rather than searching for the residue you anticipated.

Surfaced 2026-06-24 (PF-IMP-1290 / PF-FEE-1464): a docmap-append removal left stale synopses + dead `if ($result.DocMapUpdated)` branches across 7 design-creation scripts, caught only by an opportunistic grep. Test-residue kind (c) surfaced 2026-06-27 (PF-IMP-1323 / PF-FEE-1486): a baseline/delta Pester suite synthesized its expected error from the exact broken-link check being removed, silently invalidating an unrelated suite. The doc-content analogue surfaced 2026-07-19 (PF-IMP-1727 / PF-FEE-1652): a residue check shaped around headings, IDs and blank-line runs passed while three orphaned `(owned by …)` bullets sat in two task files — an external editor touch revealed them, not the check. The AST-vs-text-match split for removal assertions came from PF-IMP-1736 / PF-FEE-1668 (2026-07-27): 10 assertions across 5 suites pinned a removed call by source text, each one green only until someone documents the removal. Companion to the refactor footguns above.

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
# New-FrameworkDocument (the shared creation wrapper) returns the bare document ID;
# add -PassThru when a post-creation write needs the created file's path — it then
# returns {Id, Path, RelativePath}, so the filename is never re-derived by the caller.
$documentId = New-FrameworkDocument `
    -TemplatePath "process-framework/templates/[SUBFOLDER]/your-template.md" `
    -IdPrefix "YOUR-PREFIX" `
    -IdDescription "Description for $FeatureName" `
    -DocumentName $FeatureName `
    -DirectoryType "your-directory-type" `
    -Replacements $customReplacements `
    -Metadata $additionalMetadataFields `
    -Label "your document type" `
    -OpenInEditor:$OpenInEditor
```

### Load-Bearing Assertions (Discriminating Condition + Mutation Verification)

An assertion counts as coverage only once it can fail for the reason it names. Two obligations, both discharged **when the assertion is written** — each produces evidence once and then costs nothing, like the golden-file harness below. Neither is a test of a test: they are authoring steps, not a review layer.

**1. Name a discriminating condition.** "X is present" is not an assertion until you can state, and exercise, the condition under which X would be *absent*. Where the fixture makes X true by construction, the assertion says nothing about the code.

```powershell
# ❌ Passes whether or not the code ran — the fixture was seeded from the same source
$received | Should -Contain 'tasks/support/framework-rollout-task.md'

# ✅ Seed content that exists nowhere in the source, so "preserved" ≠ "identical by construction"
'{"SENTINEL":"authored-at-the-consumer"}' | Set-Content $consumerOwnedFile
# ... run ... then assert the sentinel survived (or is gone, where removal is the contract)
```

Shapes that structurally cannot name a discriminating condition, and are therefore always suspect: a `Test-Path`-guarded body that silently skips itself when the file is absent; a count compared against a file that may not exist (0 vs 0); a `Should -Not -Match` guard on a run that may die before reaching the guarded line; a `-Match` on error text that names the very file it failed to find.

**2. Mutation-verify it.** Break the thing the assertion asserts, confirm *that* assertion goes red, restore. Green under mutation means it was vacuous. A **different** assertion going red means the mapping is wrong — fix the mapping, not the mutation. Record the contrast where the next reader will meet it (suite header or session log): *"removing the seeded tracker turns 9 red; the same absence previously turned 11 red and left 4 falsely green."*

Cost is bounded — the code is already in front of you and the mutation is one edit plus one re-run. Do it per assertion while authoring rather than as a later sweep; a sweep is the review layer this deliberately replaces.

The framework already demands exactly this in one narrow place: an E2E instruction-fixture oracle must have been *observed failing* on a wrong-order run ([Test Audit](../../tasks/03-testing/test-audit-task.md)). The two obligations above generalize it to every assertion.

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

### Behavior-Preserving Refactor Verification (Golden-File Equivalence Harness)

When a refactor must be **behavior-preserving across many scripts** — e.g. converting a fleet of creation scripts to a shared helper — per-script Pester is the wrong tool: it asserts *expected* behavior, not *unchanged* behavior, and writing characterization tests for every script is prohibitive. A **golden-file equivalence harness** proves byte-for-byte equivalence instead:

1. **Two isolated sandboxes** — copy the framework into a fresh sandbox twice: `orig` (the script's pre-refactor version, extracted byte-exact from git HEAD) and `conv` (the working-tree version). Make each a *faithful* copy (project-config, all ID registries, central paths) so the script resolves everything exactly as in production.
2. **Same representative invocation in each** — run the script once per sandbox with an identical argument set covering the side-effects you care about.
3. **Assert whole-sandbox byte-identity except the script** — hash every file in both sandboxes and require them to match, excluding only the refactored script itself (and any run-log). Any divergence in a created document, ID registry, documentation map, or tracking write is a behavior change the refactor introduced.

Two gotchas the pattern must encode:
- **Extract the HEAD baseline byte-exact** via `cmd /c "git show HEAD:<path> > <file>"` — PowerShell's native-stdout decoding corrupts UTF-8 multibyte characters (e.g. the em-dash in section-header literals), producing false diffs.
- **Redirect out-of-sandbox writes back into the compared tree** — point any "central" write path (e.g. a `FRAMEWORK_CENTRAL_OVERRIDE`-style env var) at the per-sandbox copy, so central-registry increments and central document writes land *inside* what you hash. Otherwise both runs write to the real tree and the harness sees no difference where there is one.
- **The baseline is the pre-refactor state, which is not always `HEAD`** — when the same session also lands an intended behavior change (a bug fix) in the script, `HEAD` is two deltas away and comparing against it reports the *intended* change as a diff. Reconstruct the intermediate state (`HEAD` + the intended fix) and pass it explicitly, so the golden isolates only the refactor.
- **Prove the run wasn't a no-op** — a byte-identical PASS over two runs that did nothing is vacuous. Require evidence the script acted: a file added, **changed, or removed**. Counting only *added* files silently refuses every script that mutates a tracked file in place rather than creating one (PF-IMP-1601).

appdev's reference implementation is `Compare-CreationGolden.ps1` (in the appdev self-test tree, built for the Registry-Driven Document Creation conversion, PF-IMP-1135; extended to mutation-only scripts such as the tracking-table row-inserters, PF-IMP-1601) — kept deliberately OUT of the `*.Tests.ps1` suite because it is heavy (copies the framework, spawns subprocesses) and is run explicitly per converted script during the conversion, not in the normal test run.

**When to use**: behavior-preserving mass conversions / mechanical refactors where the contract is "produce exactly what the old code produced."

**When NOT to use**: new behavior or bug fixes (no golden to match — use Pester); a mass *additive* change that intentionally alters output (e.g. a new frontmatter field emitted across every creation script) — verify the single intended delta with a focused before/after diff, not whole-tree byte-identity; or pure-function helpers (direct-invocation unit tests are cheaper and clearer).

### Markdown Table Surgery Pattern

Use the `TableOperations.psm1` helpers for state-file table manipulation instead of hand-rolled line splicing: `Move-MarkdownTableRow` for moving rows between sections (same-file or two-file archive mode, header-driven column mapping), `ConvertFrom-MarkdownTable` / `Split-MarkdownTableRow` / `ConvertTo-MarkdownTableRow` for parsing and rebuilding rows. Wrapper functions in update scripts keep only what is genuinely per-file: section discovery, decorative placeholder rows, summary counts. Canonical wrapper examples: `Move-BugFromArchiveContent` and `Move-BugBetweenActiveSectionsContent` in [Update-BugStatus.ps1](../../scripts/update/Update-BugStatus.ps1).

**Consolidate on touch** (PF-IMP-1136): when editing an update script that still hand-rolls table surgery, move that code onto the TableOperations helpers as part of the same change, with Pester coverage — working scripts are not rewritten proactively.

**Verify an inserted row against its header** (PF-IMP-1563): after writing a row into a tracking table, verify it with `Assert-TableRowInFile -Path <file> -Pattern "\| $id \|" -Context "<what>"` rather than `Assert-LineInFile`. Both confirm the row landed; only the former also parses the row, resolves its table's header, and throws when the cell counts disagree. A presence-only assert passes a row whose template has drifted from a header that gained a column — the row is well-formed markdown with the right ID, but every cell after the new column sits under the wrong header, and no reader notices (`New-PerformanceTestEntry.ps1` shipped that way for ~2.5 months, PF-IMP-1534). It also rejects a row that isn't a well-formed table row at all — e.g. a missing trailing pipe, which markdown table parsers skip silently. Detection is the backstop, not the cure: build the row from the table's own headers with `New-HeaderDrivenTableRow -Content <file content> -SectionHeading <heading> -ValueMap @{ '<Header>' = $value; ... }` (TableOperations.psm1) — headers absent from the map take `-DefaultCell` (default `—`; pass `-` for tables that use a plain hyphen), so a schema change lands as a placeholder in the correct position instead of shifting cells. The pattern originated in `Update-TechDebt.ps1` (PF-IMP-006) and was promoted to the shared helper when every tracking-table inserter adopted it (PF-IMP-1599).

### Soak Re-Sync After Editing a Soak-Enrolled Script

**Issue**: You edited a script enrolled in [script-soak-tracking.md](../../../process-framework-central/state-tracking/permanent/script-soak-tracking.md). The edit changes the content hash, which must reset the soak counter — *how* that happens depends on whether the script is **self-armored** or **agent-maintained**.

- **Self-armored** (the common case — creation scripts armored via the `DocumentManagement.psm1` helper, update scripts that adopted the assert+soak pattern): the script calls the soak helpers itself, so `Test-ScriptInSoak` auto-resets the counter against the new hash on the next real invocation and `Confirm-SoakInvocation` fires from the script's own flow. No manual action.
- **Agent-maintained** (externally registered, not self-instrumented — e.g. `Build-DocumentationMap.ps1`, `Build-TaskMetadata.ps1`, `Push-FrameworkUpdate.ps1`): nothing in the script touches soak state, so re-sync it manually after a verified real run. First bring the helpers into your session: `Import-Module` the umbrella `process-framework/scripts/Common-ScriptHelpers.psm1` by **absolute path** — it exports all four soak functions (`Register-SoakScript`, `Test-ScriptInSoak`, `Confirm-SoakInvocation`, `Get-SoakStatus`). Then:
  1. `Test-ScriptInSoak -ScriptId <id> -ScriptPath <path>` — detects the hash change and resets the counter to `$DefaultSoakCounter`. (Both params are required together: pass *neither* to auto-resolve from the calling script, or *both* for a standalone re-sync — `-ScriptPath` alone errors.)
  2. Run the script for real and verify the outcome.
  3. `Confirm-SoakInvocation -ScriptId <id> -Outcome success` — records the verified run and decrements the counter. (Takes `-ScriptId`, not `-ScriptPath`.)
  4. `Register-SoakScript` is **not** needed — it no-ops on an already-registered ID.

  **Run this sequence once, after the session's edits to that script have settled.** Every further edit changes the content hash, so a re-sync recorded earlier now asserts a verified run against content that no longer exists — and unlike a self-armored script, nothing reconciles it later (PF-IMP-1755). Check with `Get-SoakStatus -ScriptId <id>`: `NeedsResync` is `$true` for exactly this condition.

**Which path applies is derived, not annotated** (PF-IMP-1880): `Get-SoakStatus -ScriptId <id>` returns an `Arming` value — `self-armored`, `agent-maintained`, or `unknown` (the ScriptId resolves to no file on disk, so the row is stale). It inspects the script's own AST at call time and therefore cannot drift. The `[agent-maintained]` text some Notes cells carry is human annotation kept for readability; where the two disagree, the derived value wins.

Each entry also carries `HashCurrent` (does the row's recorded hash still match the file?) and `NeedsResync` (`$true` only when `agent-maintained` **and** the hash is stale). A stale hash on a *self-armored* script is benign — it re-arms on its next real invocation — which is why `NeedsResync` composes the two rather than flagging staleness alone. `Get-SoakStatus | Where-Object NeedsResync` is the fleet-wide sweep.

## Troubleshooting

### PowerShell Script Execution (AI Agents)

> **Single source of truth.** This section is the canonical reference for running framework PowerShell scripts. `CLAUDE.md` (both appdev and project copies) carries only a short `-File` snippet plus a pointer here — keep the full recipe (preferred/fallback patterns, human-terminal usage, troubleshooting) in this section rather than duplicating it there.

**Before running any script, check its parameters first** — do not guess parameter names; scripts use `ValidateSet` constraints that reject unknown values.

```bash
# Parameter descriptions (comment-based help)
pwsh.exe -ExecutionPolicy Bypass -Command 'Get-Help path/to/Script.ps1 -Parameter *'
```

`-?` shows only NAME / SYNOPSIS / SYNTAX / DESCRIPTION — never the per-parameter descriptions, so a fully documented script still reads as "no help" through it. Use `-Parameter *` (all parameters) or `-Full` (help plus examples).

**Constraints are a separate lookup.** Comment-based help never renders `ValidateSet` values or length limits in any view — those live in parameter metadata, and a script surfaces them through `Get-Help` only where someone hand-copied them into `.PARAMETER` prose, which then drifts from the code. Read them from the metadata instead, which cannot go stale:

```bash
# Every parameter with its type, mandatory flag, and ValidateSet / length constraints
pwsh.exe -ExecutionPolicy Bypass -Command '
  $common = [System.Management.Automation.PSCmdlet]::CommonParameters +
            [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
  (Get-Command path/to/Script.ps1).Parameters.GetEnumerator() |
    Where-Object { $_.Key -notin $common } | ForEach-Object {
    $c = $_.Value.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] -or
                                              $_ -is [System.Management.Automation.ValidateLengthAttribute] }
    "{0} <{1}>{2}" -f $_.Key, $_.Value.ParameterType.Name, $(if ($c) { "  [" + (($c | ForEach-Object {
      if ($_ -is [System.Management.Automation.ValidateSetAttribute]) { $_.ValidValues -join " | " }
      else { "len {0}-{1}" -f $_.MinLength, $_.MaxLength } }) -join "; ") + "]" })
  }'
```

**Preferred pattern — `pwsh.exe -File`:**

Use `-File` with a direct relative path from the repo root. No `cd` needed, no quoting wrappers.

All literal `process-framework/scripts/...` paths in this guide assume the project's default `paths.process_framework` (`project-config.json`); appdev is the one deviation — its framework tree lives at `blueprint/process-framework`, so prepend `blueprint/` there (per appdev's own `CLAUDE.md`).

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
- **Prose arguments arrive verbatim** — inside bash single quotes, `$`, backticks, `|` and newlines all survive, so quote-heavy values (IMP `-Notes`, `-ValidationNotes`, `-Description`) need no escaping or workaround — with one exception: a bash single-quoted value cannot carry a nested `'` (hazard (b) below)
- Only caveat: escape `$` with backslash (`\$false`) so bash doesn't interpret it as a variable

> **🚨 Quote-heavy prose — two transit hazards.**
>
> **(a) `-Command` double-parsing (`-Command`-only).** Under `-Command`, the argument is parsed by PowerShell a **second** time, so a value inside double quotes loses `$…` (interpolated as a variable — `cost $500` becomes `cost `) and its backticks (consumed as escapes). The loss is **silent**: the row is written, just with text missing. `|` inside quotes survives, and the Bash tool is not involved — both are common misattributions. Verified by probe, 2026-07-28 (PF-IMP-1809).
>
> **(b) Nested `'` in bash single quotes (hits `-File` too).** A `'` inside a bash single-quoted argument ends the quoting — the nested quote can never arrive. With spaces in the nested span the prose splits into extra tokens and **parameter binding aborts before the script body** (stderr error, exit 1, no row written — loud in raw form, but a pipeline filter such as `… | grep` eats the stderr and masks the exit code, so it reads as a total silent failure); with adjacent segments bash **silently drops the quotes** and the script writes the row with altered text. For apostrophe-bearing prose, use bash double quotes and backslash-escape `$` and backticks, or the file-based form below. Verified by probe, 2026-07-30 (PF-IMP-1884).
>
> ```bash
> # ❌ -Command + inline double quotes — "cost $500 and `Get-Date`" arrives as "cost  and Get-Date"
> pwsh.exe -ExecutionPolicy Bypass -Command "& Script.ps1 -Notes \"cost \$500 and \`Get-Date\`\""
>
> # ✅ Preferred: -File passes it verbatim, no escaping
> pwsh.exe -ExecutionPolicy Bypass -File Script.ps1 -Notes 'cost $500 and `Get-Date` and a | pipe'
>
> # ❌ Nested ' inside bash single quotes — binding abort (spaced span) or silent de-quoting (adjacent)
> pwsh.exe -ExecutionPolicy Bypass -File Script.ps1 -Notes 'the task's 'unfilled' check'
>
> # ✅ Apostrophe-bearing prose: bash double quotes, with $ and backticks backslash-escaped
> pwsh.exe -ExecutionPolicy Bypass -File Script.ps1 -Notes "the task's 'unfilled' check costs \$500"
>
> # ✅ When -Command is unavoidable (array or [bool] params, PowerShell expressions),
> #    or the prose mixes hazards: read the value from a file so it arrives already parsed
> pwsh.exe -ExecutionPolicy Bypass -Command "& Script.ps1 -Notes (Get-Content '/path/notes.txt' -Raw)"
> ```

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

**🚨 `Select-Object -First N` on a running script ABORTS it — silently.** `-First` stops the upstream pipeline the moment it holds N objects, and a script is an upstream producer like any other: it is unwound where it stood, so **everything after its last emitted object never runs**. Measured against a producer that writes a side-effect file after its output:

| Form | Producer ran to completion? |
| ---- | --------------------------- |
| `& script.ps1` (control) | ✅ |
| `& script.ps1 \| Select-Object -First 2` | ❌ **killed** |
| `& script.ps1 \| Select-Object -Last 2` | ✅ (no early stop) |
| `& script.ps1 \| Where-Object { ... }` | ✅ |
| `$out = & script.ps1` then `$out \| Select-Object -First 2` | ✅ — **the fix** |
| producer logging via `Write-Host` | ✅ (the host stream is not the pipeline) |

Nothing surfaces: no exception reaches the caller, `$Error` does not grow, and the captured output is a clean, plausible short run. The producer's `finally` blocks **do** still run while its `catch` never fires — so a script that reports success from `finally` reports it after being killed. **Fix: capture, then filter.**

Surfaced 2026-08-12 (PF-PRO-068 S3 E4-c), where it killed `Push-FrameworkUpdate.ps1` after its diff preview and before tagging or mirroring; mechanism measured 2026-08-13. Same shape as the pipe-buffering entry above — both are filtering a long-running script's output — but this one changes what the script *did*, not just what you see.

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

- [`creation-script-development` craft skill](../../../.claude/skills/creation-script-development/SKILL.md) - the script-authoring craft for creating documents from templates through PowerShell scripts (this quick reference is its agnostic troubleshooting companion)
- [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md) - developing and maintaining the framework templates these scripts consume
