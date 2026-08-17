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

.PARAMETER TestFile
    Run one or more specific test files in isolation, bypassing category resolution. For the
    iterate-after-fix loop — far faster than re-running a whole -Category. Takes precedence over
    -Category. Accepts a path relative to the project root or the current directory, a bare
    filename (resolved by searching the test directory; must match exactly one file), or a
    comma-separated list of either (split per the framework CSV-string convention, so the list
    survives pwsh -File's literal-token binding; PF-IMP-1542).

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

.PARAMETER SaveBaseline
    Save this run's failed-test fingerprints as a baseline for a later -Baseline delta
    (PF-IMP-1308). PowerShell runner only. See Run-Tests.powershell.ps1 for full semantics.

.PARAMETER Baseline
    Path to a saved baseline; makes the verdict delta-based (fails only on NEW failures vs the
    baseline). PowerShell runner only. See Run-Tests.powershell.ps1 for full semantics.

.EXAMPLE
    Run-Tests.ps1 -Quick

.EXAMPLE
    Run-Tests.ps1 -All -Coverage

.NOTES
    Per-language runners may implement only a subset of these flags in their first iteration.
    Run-Tests.powershell.ps1 supports: -Category / -TestFile / -Quick / -All / -Coverage / -ListCategories / -VerboseOutput.
    Not yet implemented in the PowerShell runner: -Discover / -Lint / -Critical / -Performance / -UpdateTracking (the Python runner implements these).
    -SaveBaseline / -Baseline (PF-IMP-1308) are PowerShell-runner only (Pester-specific), like -TestFile;
    the Python runner does not implement them.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]]$Category,
    [string[]]$TestFile,
    [switch]$Quick,
    [switch]$All,
    [switch]$Coverage,
    [switch]$Discover,
    [switch]$Lint,
    [switch]$Critical,
    [switch]$Performance,
    [switch]$ListCategories,
    [switch]$VerboseOutput,
    [switch]$UpdateTracking,
    [switch]$SaveBaseline,
    [string]$Baseline
)

# --- PF-IMP-1107: guarantee a non-interactive host for the test run ---
# A Pester test that hits an interactive prompt (classically a missing mandatory parameter in a
# Should-Throw case) blocks forever in an interactive-capable host. Under -NonInteractive that
# same prompt becomes an immediate terminating error instead. Relaunch self under -NonInteractive
# whenever the current process was not started with it — covering every launch path (pre-commit
# hook, agent shell, human terminal) without each caller having to remember the flag.
$startedNonInteractive = (@([Environment]::GetCommandLineArgs()) -join ' ') -match '(?i)(^|\s)-noni'
if (-not $startedNonInteractive -and $env:PF_RUNTESTS_RELAUNCHED -ne '1') {
    # Re-exec this exact invocation with -NonInteractive prepended. Replaying the original argv
    # verbatim (rather than reconstructing from $PSBoundParameters) guarantees the relaunched
    # parameter binding is identical to the original — no array/quoting mangling, no per-parameter
    # maintenance. [Environment]::GetCommandLineArgs()[0] is the host executable/dll; the rest are
    # the original arguments. The env-var guard backstops the command-line detection against an
    # infinite relaunch loop.
    $origArgs = @([Environment]::GetCommandLineArgs())
    $rest = if ($origArgs.Count -gt 1) { $origArgs[1..($origArgs.Count - 1)] } else { @() }
    $env:PF_RUNTESTS_RELAUNCHED = '1'
    & (Get-Process -Id $PID).Path -NonInteractive @rest
    exit $LASTEXITCODE
}

# --- PF-IMP-1107 / PF-IMP-1083: pin UTF-8 console encoding for the run ---
# Subprocess-output assertions that match non-ASCII glyphs (em-dash, arrows, emoji) flake under
# OEM consoles. Guarded — assigning Console encoding can throw in some headless/redirected hosts.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

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
