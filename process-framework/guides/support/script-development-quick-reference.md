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
    "\[Feature Name\]" = $FeatureName  # This won't work!
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

### PowerShell Script Output Not Visible (AI Agents)

**Symptom:** When AI agents execute PowerShell scripts using `pwsh.exe -Command`, no output is displayed even though the script executes successfully (Exit Code 0).

**Status (2026-02-28):** This issue has been **resolved** in Claude Code. Output from `pwsh.exe -Command` is now captured correctly when using bash single quotes.

**Preferred Solution:** Wrap the entire `-Command` argument in **bash single quotes**:

```bash
# Preferred pattern — bash single quotes prevent shell interpretation
cd process-framework/scripts/file-creation && pwsh.exe -ExecutionPolicy Bypass -Command '& .\ScriptName.ps1 -Param "value" -Confirm:$false'
```

**Example:**
```bash
cd process-framework/scripts/file-creation && pwsh.exe -ExecutionPolicy Bypass -Command '& .\New-FeedbackForm.ps1 -DocumentId "PF-TSK-009" -TaskContext "Process Improvement" -FeedbackType "MultipleTools" -Confirm:$false'
```

**Why this works:**
- Bash single quotes prevent `$`, `&`, and other characters from being interpreted by bash
- PowerShell receives the command string intact and executes it normally
- All output streams (`Write-Host`, `Write-Output`, custom formatters) are captured

**Fallback (complex quoting):** When bash single quotes conflict with the PowerShell command (e.g., the command itself contains single quotes), use a temp file:

```bash
cat > temp.ps1 << 'ENDOFSCRIPT'
Set-Location 'process-framework/scripts/file-creation'
& .\Script.ps1 -Params -Confirm:$false
ENDOFSCRIPT
pwsh.exe -ExecutionPolicy Bypass -File temp.ps1 && rm temp.ps1
```

**For human users:** You can continue using `pwsh.exe -Command` directly in your terminal with any quoting style — it works fine for interactive use.

**Historical context:** Prior to 2026-02-28, the Bash tool could not capture PowerShell `-Command` output. The temp file pattern was the only working approach. The solutions listed below were tested and did not work at that time:
- `*>&1` stream redirection
- `| Out-String` piping
- `-NoLogo -NoProfile` flags
- `Start-Transcript` with output capture
- Setting `$InformationPreference`
- Using `Write-Output` instead of `Write-Host`

### Double Quotes in `echo` Cause Garbled Paths (Historical — Temp File Pattern)

> **Note (2026-02-28):** This issue only applies to the legacy `echo ... > temp.ps1` pattern. With the preferred `pwsh.exe -Command '...'` pattern (bash single quotes), this problem does not occur because cmd.exe is not involved in interpreting the command string.

**Symptom:** When using the old temp file pattern, script runs successfully (Exit Code 0) but creates a nested directory structure instead of the expected file.

**Cause:** cmd.exe interprets `"` double quotes inside an `echo` command, garbling parameter values.

**Solution:** Use the preferred pattern instead:

```bash
# ✅ Preferred — bash single quotes, no echo/temp file needed
cd process-framework/scripts/file-creation/02-design && pwsh.exe -ExecutionPolicy Bypass -Command '& .\New-FDD.ps1 -FeatureId "3.1.1" -FeatureName "Parser Framework" -Confirm:$false'
```

If you must use the temp file fallback, use single quotes for all parameter values inside `echo`.

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
