<#
.SYNOPSIS
    Template for creating a per-language test runner (Run-Tests.<language>.ps1).

.DESCRIPTION
    Starting point for a new language adopter. Copy this file to:
        <process-framework>/scripts/language-specific-scripts/<language>/Run-Tests.<language>.ps1
    then customize the marked sections.

    Invoked by Run-Tests.ps1 dispatcher, which forwards bound parameters.
    Created by Framework Self-Testing extension (PF-PRO-035) Phase 3a, 2026-05-17.

.NOTES
    Used by [Project Initiation (PF-TSK-059)](../../tasks/00-setup/project-initiation-task.md)
    when a project introduces a language new to the framework (no existing
    Run-Tests.<lang>.ps1 in scripts/language-specific-scripts/).

    Companion: <process-framework>/languages-config/<language>/<language>-config.json
    (create via template at <process-framework>/templates/support/language-config-template.json).
#>

# CUSTOMIZE: Update the [param] block as needed for your test runner.
# Keep the parameter NAMES consistent with the dispatcher (Run-Tests.ps1) so dispatch
# via @PSBoundParameters works; you can leave flags unimplemented and exit with code 2.

[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]]$Category,
    [switch]$Quick,
    [switch]$All,
    [switch]$Coverage,
    [switch]$Discover,
    [switch]$Lint,
    [switch]$Critical,
    [switch]$Performance,
    [switch]$ListCategories,
    [switch]$VerboseOutput,
    [switch]$UpdateTracking
)

# --- Import Common-ScriptHelpers (provides Get-ProjectRoot, Get-ProjectConfig,
#     Write-ProjectError, Write-ProjectSuccess, Get-TestRunnerLanguageConfig) ---
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "../../Common-ScriptHelpers.psm1"
try {
    Import-Module (Resolve-Path $modulePath -ErrorAction Stop) -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers: $($_.Exception.Message)"
    exit 1
}

# --- Resolve project context ---
$projectRoot = Get-ProjectRoot
if (-not $projectRoot) { Write-ProjectError -Message "Could not find project root" -ExitCode 1 }

$config = Get-ProjectConfig
$testDir = $config.testing.testDirectory
if (-not $testDir) { $testDir = $config.paths.tests }
if (-not $testDir) { Write-ProjectError -Message "testing.testDirectory and paths.tests both empty in project-config.json" -ExitCode 1 }

$testPath = Join-Path $projectRoot $testDir
if (-not (Test-Path $testPath)) { Write-ProjectError -Message "Test directory not found: $testPath" -ExitCode 1 }

# CUSTOMIZE: Replace 'LANGUAGE_NAME' with your language identifier (e.g., 'go', 'rust').
$language = 'LANGUAGE_NAME'
$langConfig = Get-TestRunnerLanguageConfig -Language $language -ProjectRoot $projectRoot

# --- CUSTOMIZE: Verify your language's test framework is available ---
# Example for Pester (PowerShell):
#   if (-not (Get-Module -ListAvailable Pester | Where-Object { $_.Version.Major -ge 5 })) {
#       Write-ProjectError -Message "Pester 5.x not found. Install via: Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser" -ExitCode 1
#   }
# Example for go:
#   if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
#       Write-ProjectError -Message "go not found in PATH" -ExitCode 1
#   }

# --- CUSTOMIZE: Category discovery (typically subdirs of testPath/automated/ or testPath) ---
$categories = @()  # populate from filesystem scan

if ($ListCategories) {
    Write-Host "Available test categories:"
    foreach ($cat in $categories) { Write-Host "  - $cat" }
    exit 0
}

# --- CUSTOMIZE: Default to Quick if nothing specified ---
$anyFlag = ($Category -and $Category.Count -gt 0) -or $Quick -or $All -or $Coverage -or $Discover -or $Lint -or $Critical -or $Performance
if (-not $anyFlag) { $Quick = $true }

# --- CUSTOMIZE: Build and invoke test command ---
# Use $langConfig.testing.baseCommand and $langConfig.testing.markers as starting points.
# See blueprint/process-framework/scripts/language-specific-scripts/python/Run-Tests.python.ps1
# or blueprint/process-framework/scripts/language-specific-scripts/powershell/Run-Tests.powershell.ps1
# for reference implementations.

# CUSTOMIZE: Replace the placeholder below with your actual test invocation.
$success = $true
# ... your test invocation here ...

# --- Summary + exit code ---
Write-Host ""
Write-Host ("=" * 60)
if ($success) {
    Write-ProjectSuccess -Message "All tests completed successfully!"
} else {
    Write-ProjectError -Message "Some tests failed!"
}
Write-Host ("=" * 60)

exit $(if ($success) { 0 } else { 1 })
