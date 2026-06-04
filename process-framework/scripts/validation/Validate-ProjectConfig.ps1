#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Validates a project-config.json for JSON syntax, populated required fields, and leftover placeholders.

.DESCRIPTION
    Created for PF-IMP-952 (Framework Evaluation PF-EVR-024, finding F8a; consolidates F14).
    Replaces the manual "ensure the file is valid JSON" eyeball check at Project Initiation
    (PF-TSK-059) Step 9 with a programmatic gate. Read-only — never writes or creates files.

    Checks performed:
      1. File exists at the resolved path.
      2. Content parses as JSON (catches the syntax errors Step 9 was guarding against — F14).
      3. Required core fields are present and non-empty (the fields downstream framework
         scripts depend on: identity, paths, testing language, primary language / platform).
      4. paths.source_code is set and not "." (New-SourceStructure.ps1 depends on a real dir name).
      5. No leftover "[Placeholder]" bracket tokens remain in any string value.

    project_id == null is reported as informational, not a failure — Register-Project.ps1
    sets it during PF-TSK-059 Step 19, after this validation runs.

    Exit code: 0 when valid, 1 when any error is found (so it can gate a task step or CI).

.PARAMETER Path
    Path to the project-config.json to validate. Defaults to <project-root>/doc/project-config.json.

.EXAMPLE
    Validate-ProjectConfig.ps1
    # Validates doc/project-config.json in the current project.

.EXAMPLE
    Validate-ProjectConfig.ps1 -Path "C:\proj\doc\project-config.json"
#>

param(
    [string]$Path = ""
)

# --- Module import (walk up to find Common-ScriptHelpers.psm1 for Get-ProjectRoot) ---
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
if ($dir) {
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
}

# --- Helpers (defined before use — script-level functions are not hoisted) ---

# Return a nested property value by dotted path, or $null if any segment is absent.
function Get-ConfigValue {
    param($Object, [string]$DottedPath)
    $current = $Object
    foreach ($segment in $DottedPath.Split('.')) {
        if ($null -eq $current) { return $null }
        $prop = $current.PSObject.Properties[$segment]
        if (-not $prop) { return $null }
        $current = $prop.Value
    }
    return $current
}

# Recursively flag any string value that is wholly an unreplaced "[...]" placeholder token.
function Find-Placeholders {
    param($Node, [string]$PathPrefix)
    if ($null -eq $Node) { return }
    if ($Node -is [string]) {
        if ($Node -match '^\s*\[.+\]\s*$') {
            $script:errors.Add("Unreplaced placeholder at '$PathPrefix': $Node")
        }
        return
    }
    if (($Node -is [System.Collections.IEnumerable]) -and ($Node -isnot [string])) {
        $i = 0
        foreach ($item in $Node) {
            Find-Placeholders -Node $item -PathPrefix ("{0}[{1}]" -f $PathPrefix, $i)
            $i++
        }
        return
    }
    if ($Node.PSObject -and $Node.PSObject.Properties) {
        foreach ($p in $Node.PSObject.Properties) {
            $childPath = if ([string]::IsNullOrEmpty($PathPrefix)) { $p.Name } else { "$PathPrefix.$($p.Name)" }
            Find-Placeholders -Node $p.Value -PathPrefix $childPath
        }
    }
}

# --- Resolve config path ---
if ([string]::IsNullOrWhiteSpace($Path)) {
    if (Get-Command Get-ProjectRoot -ErrorAction SilentlyContinue) {
        $Path = Join-Path (Get-ProjectRoot) "doc/project-config.json"
    } else {
        $Path = Join-Path (Get-Location).Path "doc/project-config.json"
    }
}

Write-Host "🔍 Validating project-config.json..." -ForegroundColor Cyan
Write-Host "   Target: $Path" -ForegroundColor Gray
Write-Host ""

$script:errors = New-Object System.Collections.Generic.List[string]

# --- Check 1: file exists ---
if (-not (Test-Path $Path)) {
    Write-Host "📊 Validation Summary: 1 error" -ForegroundColor Red
    Write-Host "   ❌ File not found: $Path" -ForegroundColor Red
    exit 1
}

# --- Check 2: JSON parses (the F14 guard) ---
$config = $null
try {
    $config = Get-Content $Path -Raw | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Host "📊 Validation Summary: 1 error" -ForegroundColor Red
    Write-Host "   ❌ Invalid JSON syntax: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
if ($null -eq $config) {
    Write-Host "📊 Validation Summary: 1 error" -ForegroundColor Red
    Write-Host "   ❌ File is empty or contains no JSON object." -ForegroundColor Red
    exit 1
}

# --- Check 3: required core fields populated ---
# Load-bearing fields only — ones framework automation actually reads to function.
# Descriptive metadata (display_name, description, primary_language, platform) is left
# out deliberately: it is not load-bearing (appdev legitimately leaves primary_language
# blank, relying on testing.language), and the placeholder scan in Check 5 still catches
# any of those left as an unfilled "[...]" token.
$requiredFields = @(
    'project.name',
    'project.root_directory',
    'paths.documentation_root',
    'paths.process_framework',
    'paths.source_code',
    'paths.tests',
    'paths.scripts',
    'testing.language',
    'testing.testDirectory'
)
foreach ($field in $requiredFields) {
    $value = Get-ConfigValue -Object $config -DottedPath $field
    if ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrWhiteSpace($value))) {
        $script:errors.Add("Required field '$field' is missing or empty.")
    }
}

# --- Check 4: source_code is a real directory name, not "." ---
if ((Get-ConfigValue -Object $config -DottedPath 'paths.source_code') -eq '.') {
    $script:errors.Add("paths.source_code is '.' — set it to the actual source directory name (e.g. 'src'); New-SourceStructure.ps1 depends on it.")
}

# --- Check 5: leftover [Placeholder] tokens anywhere in the document ---
Find-Placeholders -Node $config -PathPrefix ""

# --- Summary ---
$errorColor = if ($script:errors.Count -eq 0) { 'Green' } else { 'Red' }
Write-Host "📊 Validation Summary: $($script:errors.Count) error(s)" -ForegroundColor $errorColor
foreach ($e in $script:errors) {
    Write-Host "   ❌ $e" -ForegroundColor Red
}

# project_id is informational (set later by Register-Project.ps1), not a validation error.
$projectId = Get-ConfigValue -Object $config -DottedPath 'project_id'
if ($null -eq $projectId -or ($projectId -is [string] -and [string]::IsNullOrWhiteSpace($projectId))) {
    Write-Host "   ℹ️  project_id is null — Register-Project.ps1 sets it during PF-TSK-059 Step 19." -ForegroundColor Yellow
}

Write-Host ""
if ($script:errors.Count -eq 0) {
    Write-Host "✅ project-config.json is valid." -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ project-config.json has $($script:errors.Count) error(s) — see above." -ForegroundColor Red
    exit 1
}
