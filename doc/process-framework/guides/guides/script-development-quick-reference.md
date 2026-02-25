---
id: PF-GDE-019
type: Document
category: General
version: 1.0
created: 2025-07-21
updated: 2025-07-21
guide_title: Script Development Quick Reference
guide_status: Active
guide_description: Quick reference for common script development issues and solutions
---
# Script Development Quick Reference

## Overview

Quick reference for common script development issues and solutions

## When to Use

Use this guide when you encounter issues while developing PowerShell document creation scripts for the BreakoutBuddies project. This guide provides immediate solutions to the most common problems.

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
- Understanding of BreakoutBuddies project structure
- Access to `doc/process-framework/scripts/Common-ScriptHelpers.psm1`

## Background

This quick reference addresses the most common issues encountered when developing document creation scripts for the BreakoutBuddies project, based on real implementation experiences from the Database Schema Design Task and other script implementations.

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
$modulePath = Join-Path -Path $scriptDir -ChildPath "../../../process-framework/scripts/Common-ScriptHelpers.psm1"
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
    -TemplatePath "doc/process-framework/templates/templates/your-template.md" `
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

**Cause:** The Bash tool (used by AI agents like Zencoder) cannot capture PowerShell console host output when using the `-Command` parameter. This affects:
- `Write-Host` output
- `Write-Output` output
- Custom formatting functions from Common-ScriptHelpers
- All console output streams

This is **not** a PowerShell or script issue - it's a limitation of how the Bash tool spawns and captures output from PowerShell processes. The same commands work perfectly when executed directly in a terminal.

**Solution:** Use the documented temp file pattern:

```cmd
# Pattern for AI agents executing through Bash tool
echo Set-Location 'c:\path\to\script\directory'; ^& .\ScriptName.ps1 -Parameters 'values' -Confirm:$false > temp_script.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp_script.ps1 && del temp_script.ps1
```

**Example:**
```cmd
echo Set-Location 'c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\process-framework\scripts\file-creation'; ^& .\New-Task.ps1 -TaskType 'Discrete' -TaskName 'Test Task' -WorkflowPhase '01-planning' -Description 'Test description' -Confirm:$false -WhatIf > temp_task.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp_task.ps1 && del temp_task.ps1
```

**Why this works:**
- Creates a temporary PowerShell script file with the commands
- Executes it using `-File` instead of `-Command`
- `-File` execution properly captures all console output
- Automatically cleans up the temp file afterward

**For human users:** You can continue using `pwsh.exe -Command` directly in your terminal - it works fine for interactive use.

**Alternative (Not Recommended):** Refactoring all scripts to replace `Write-Host` with `Write-Output` would require changing Common-ScriptHelpers and all 30+ scripts, and testing shows this doesn't solve the Bash tool capture issue anyway.

**Tested Solutions That Don't Work:**
- `*>&1` stream redirection
- `| Out-String` piping
- `-NoLogo -NoProfile` flags
- `Start-Transcript` with output capture
- Setting `$InformationPreference`
- Using `Write-Output` instead of `Write-Host`

### 🚨 Double Quotes in `echo` Cause Garbled Paths / Wrong Directory Structure

**Symptom:** Script runs successfully (Exit Code 0) but creates a nested directory structure instead of the expected file. For example, running with `-FeatureId "3.1.1"` creates `fdd-\3-1-1\-\name\.md` (a deeply nested folder) instead of `fdd-3-1-1-name.md`.

**Cause:** cmd.exe interprets `"` double quotes inside an `echo` command. When the temp file is written, the parameter values arrive in the PowerShell script with surrounding backslashes (e.g., `\3.1.1\`). The script then uses these as path components, turning dots and hyphens into directory separators.

**Solution:** Always use single quotes `'` for ALL string parameter values inside the `echo` command:

```cmd
# ✅ CORRECT — single quotes for all parameter values
echo Set-Location 'c:\path\to\scripts'; ^& .\New-FDD.ps1 -FeatureId '3.1.1' -FeatureName 'Parser Framework' > temp.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp.ps1 && del temp.ps1

# ❌ WRONG — double quotes cause cmd.exe to garble the parameter values
echo Set-Location 'c:\path\to\scripts'; ^& .\New-FDD.ps1 -FeatureId "3.1.1" -FeatureName "Parser Framework" > temp.ps1 && pwsh.exe -ExecutionPolicy Bypass -File temp.ps1 && del temp.ps1
```

**Recovery:** If a malformed directory structure was created by a failed script run:
1. Delete the malformed directory (use PowerShell `Remove-Item -Recurse -Force "path\to\bad-dir"` via a temp .ps1 file)
2. Reset the `nextAvailable` counter in `doc/id-registry.json` back to the value before the failed run
3. Re-run the script with single quotes

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

- <!-- [Link to related guide](../../guides/related-guide.md) - Template/example link commented out -->
- <!-- [Link to relevant API documentation](../../api/relevant-api.md) - File not found -->
- [External resource](https://example.com)
