<#
.SYNOPSIS
    Language-agnostic dispatcher to the per-language test runner declared in project-config.json.

.DESCRIPTION
    Reads testing.language from doc/project-config.json and dispatches to:
        <process-framework>/scripts/language-specific-scripts/<language>/Run-Tests.<language>.ps1
    forwarding all bound parameters.

    Refactored from the monolithic Run-Tests.ps1 by the Framework Self-Testing extension
    (PF-PRO-035) Phase 3a, 2026-05-17.

    Backward compatibility: Python projects (testing.language='python') dispatch to
    Run-Tests.python.ps1 which preserves all prior Run-Tests.ps1 behavior verbatim.
    PowerShell projects (e.g. appdev / PRJ-000) dispatch to Run-Tests.powershell.ps1
    which invokes Pester programmatically.

.PARAMETER Category
    Run tests in one or more subdirectory categories of the test directory.

.PARAMETER Quick
    Quick subset: categories defined in project-config.json testing.quickCategories.

.PARAMETER All
    Run all tests (the per-language runner decides what 'all' means — e.g. pytest excludes slow by default).

.PARAMETER Coverage
    Generate coverage report.

.PARAMETER Discover
    Run test discovery only.

.PARAMETER Lint
    Run language-specific linting on test files.

.PARAMETER Critical
    Run only critical-tagged tests.

.PARAMETER Performance
    Run performance/slow tests.

.PARAMETER ListCategories
    List available test categories and exit.

.PARAMETER VerboseOutput
    Enable verbose test output.

.PARAMETER UpdateTracking
    After running tests, parse results and update test-tracking.md.

.EXAMPLE
    Run-Tests.ps1 -Quick

.EXAMPLE
    Run-Tests.ps1 -All -Coverage

.NOTES
    Per-language runners may implement only a subset of these flags in their first iteration.
    Run-Tests.powershell.ps1 v1 (Phase 3a) supports: -Category / -Quick / -All / -Coverage / -ListCategories / -VerboseOutput.
    Advanced flags (-Discover / -Lint / -Critical / -Performance / -UpdateTracking) are scheduled for Phase 3c.
#>

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

# --- Import Common-ScriptHelpers for standardized utilities ---
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "../Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers: $($_.Exception.Message)"
    exit 1
}

# --- Resolve project root and language ---
$projectRoot = Get-ProjectRoot
if (-not $projectRoot) {
    Write-ProjectError -Message "Could not find project root" -ExitCode 1
}

$config = Get-ProjectConfig
$language = $config.testing.language
if (-not $language) {
    Write-ProjectError -Message "testing.language not set in project-config.json. Edit doc/project-config.json to set testing.language (e.g., 'python' or 'powershell')." -ExitCode 1
}

# --- Resolve per-language runner ---
try {
    $runnerScript = Resolve-TestLanguageRunner -Language $language -ProjectRoot $projectRoot
} catch {
    Write-ProjectError -Message $_.Exception.Message -ExitCode 1
}

# --- Forward all bound parameters to the per-language runner ---
Write-Verbose "Dispatching to $runnerScript (language: $language)"
& $runnerScript @PSBoundParameters
exit $LASTEXITCODE
