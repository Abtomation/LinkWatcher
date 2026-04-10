---
id: PF-GDE-019
type: Process Framework
category: Guide
version: 1.0
created: 2025-07-21
updated: 2025-07-21
guide_description: Quick reference for common script development issues and solutions
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

## Troubleshooting

### PowerShell Script Execution (AI Agents)

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

- [External resource](https://example.com)
