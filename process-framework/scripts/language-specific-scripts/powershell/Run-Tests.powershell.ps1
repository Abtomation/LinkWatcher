<#
.SYNOPSIS
    PowerShell/Pester test runner — invoked by Run-Tests.ps1 dispatcher when testing.language='powershell'.

.DESCRIPTION
    Invokes Pester 5+ programmatically against the test directory configured in project-config.json.
    Reads language-specific commands from languages-config/powershell/powershell-config.json.

    Phase 3a v1 (2026-05-17) — Framework Self-Testing extension (PF-PRO-035):
      Supported flags: -Category / -Quick / -All / -Coverage / -ListCategories / -VerboseOutput
      Deferred to Phase 3c: -Discover / -Lint / -Critical / -Performance / -UpdateTracking

.PARAMETER Category
    Run tests in one or more subdirectory categories of the test directory.

.PARAMETER Quick
    Run categories from project-config.json testing.quickCategories. Default if no flag given.

.PARAMETER All
    Run all tests, excluding tag 'slow' by default (mirrors python-runner -All semantics).

.PARAMETER Coverage
    Generate code coverage report. Coverage target = paths.source_code from project-config.json
    (or the project root if source_code is empty).

.PARAMETER ListCategories
    List available test categories and exit.

.PARAMETER VerboseOutput
    Use Pester Output.Verbosity = 'Detailed'.

.PARAMETER Discover, Lint, Critical, Performance, UpdateTracking
    Accepted for forward-compatibility with the dispatcher; not yet implemented (Phase 3c).
    Invoking with these will produce a clear "not yet implemented" message and exit code 2.
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

# --- Import Common-ScriptHelpers ---
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "../../Common-ScriptHelpers.psm1"
try {
    Import-Module (Resolve-Path $modulePath -ErrorAction Stop) -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers: $($_.Exception.Message)"
    exit 1
}

# --- Forward-compatibility: unimplemented flags ---
$deferred = @()
if ($Discover)       { $deferred += '-Discover' }
if ($Lint)           { $deferred += '-Lint' }
if ($Critical)       { $deferred += '-Critical' }
if ($Performance)    { $deferred += '-Performance' }
if ($UpdateTracking) { $deferred += '-UpdateTracking' }
if ($deferred.Count -gt 0) {
    Write-ProjectError -Message "Flags not yet implemented in Run-Tests.powershell.ps1 v1 (Phase 3a): $($deferred -join ', '). Scheduled for Phase 3c reassessment." -ExitCode 2
}

# --- Verify Pester 5+ is available ---
$pesterModule = Get-Module -ListAvailable Pester | Where-Object { $_.Version.Major -ge 5 } | Sort-Object Version -Descending | Select-Object -First 1
if (-not $pesterModule) {
    Write-ProjectError -Message "Pester 5.x not found. Install via: Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser" -ExitCode 1
}
Import-Module Pester -MinimumVersion 5.0 -Force

# --- Resolve project root, configs, test dir ---
$projectRoot = Get-ProjectRoot
if (-not $projectRoot) { Write-ProjectError -Message "Could not find project root" -ExitCode 1 }

$config = Get-ProjectConfig
$testDir = $config.testing.testDirectory
if (-not $testDir) { $testDir = $config.paths.tests }
if (-not $testDir) { Write-ProjectError -Message "testing.testDirectory and paths.tests both empty in project-config.json" -ExitCode 1 }

$testPath = Join-Path $projectRoot $testDir
if (-not (Test-Path $testPath)) {
    Write-ProjectError -Message "Test directory not found: $testPath" -ExitCode 1
}

# Language-specific config (loaded via TestRunner.psm1 — for parity with python flow)
$langConfig = Get-TestRunnerLanguageConfig -Language 'powershell' -ProjectRoot $projectRoot

# --- Category discovery (auto-scan subdirs of testDir, with exclusions) ---
$excludedDirs = @('.pester-cache', 'fixtures', 'helpers', 'utils', 'state-tracking', 'audits', 'specifications', 'bug-validation', 'e2e-acceptance-testing')
$categories = Get-ChildItem -Path (Join-Path $testPath 'automated') -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notin $excludedDirs -and -not $_.Name.StartsWith('.') } |
    ForEach-Object { $_.Name }
# Fallback: if test/automated/ doesn't exist yet, scan testPath directly
if (-not $categories) {
    $categories = Get-ChildItem -Path $testPath -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin $excludedDirs -and -not $_.Name.StartsWith('.') } |
        ForEach-Object { $_.Name }
}

if ($ListCategories) {
    Write-Host "Available test categories (subdirectories under $testDir/automated/):"
    foreach ($cat in $categories) { Write-Host "  - $cat" }
    Write-Host ""
    Write-Host "-Category also accepts a nested area by unique name (e.g. 'helpers' -> automated/unit/framework/helpers) or a relative path under automated/."
    $quickCats = $config.testing.quickCategories
    if ($quickCats) {
        Write-Host ""
        Write-Host "Quick categories: $($quickCats -join ', ')"
    }
    exit 0
}

# --- Default to Quick if nothing specified ---
$anyFlag = ($Category -and $Category.Count -gt 0) -or $Quick -or $All -or $Coverage
if (-not $anyFlag) { $Quick = $true }

# --- Resolve test paths based on flag combination ---
$pesterPaths = @()
$automatedRoot = Join-Path $testPath 'automated'

if ($Category) {
    foreach ($cat in $Category) {
        try {
            # Resolves top-level categories, nested framework areas (e.g. 'helpers' ->
            # automated/unit/framework/helpers), and relative subpaths. Throws on
            # unknown/ambiguous names.
            $pesterPaths += Resolve-TestCategoryPath -Category $cat -TestPath $testPath -TopLevelCategories $categories
        } catch {
            Write-ProjectError -Message $_.Exception.Message -ExitCode 1
        }
    }
} elseif ($Quick) {
    $quickCats = $config.testing.quickCategories
    if ($quickCats -and $quickCats.Count -gt 0) {
        foreach ($cat in $quickCats) {
            $catPath = if (Test-Path (Join-Path $automatedRoot $cat)) {
                Join-Path $automatedRoot $cat
            } elseif (Test-Path (Join-Path $testPath $cat)) {
                Join-Path $testPath $cat
            } else {
                Write-Host "Warning: quickCategory '$cat' not found under $testDir/automated/ or $testDir/ — skipping."
                continue
            }
            $pesterPaths += $catPath
        }
    }
    if ($pesterPaths.Count -eq 0) {
        $pesterPaths += if (Test-Path $automatedRoot) { $automatedRoot } else { $testPath }
    }
} else {
    # -All
    $pesterPaths += if (Test-Path $automatedRoot) { $automatedRoot } else { $testPath }
}

# --- Build Pester configuration (programmatic Pester 5+ API) ---
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $pesterPaths
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = if ($VerboseOutput) { 'Detailed' } else { 'Normal' }

# -All flag: exclude 'slow' tag by default (mirrors python -All semantics)
if ($All) {
    $pesterConfig.Filter.ExcludeTag = @('slow')
}

# -Quick flag: stop on first failure
if ($Quick) {
    $pesterConfig.Run.Exit = $true
    # Pester 5 doesn't have a hard stop-on-first-failure equivalent; closest is to enable strict mode.
    # If needed in future, can use Pester's Should -ErrorAction Stop pattern in tests themselves.
}

# Coverage
if ($Coverage) {
    $pesterConfig.CodeCoverage.Enabled = $true
    $coverageTarget = if ($config.paths.source_code) {
        Join-Path $projectRoot $config.paths.source_code
    } else {
        # appdev case: coverage targets the framework scripts being tested
        $processFrameworkRel = if ($config.paths.process_framework) { $config.paths.process_framework } else { 'process-framework' }
        Join-Path $projectRoot (Join-Path $processFrameworkRel 'scripts')
    }
    if (Test-Path $coverageTarget) {
        $pesterConfig.CodeCoverage.Path = $coverageTarget
        $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
        $pesterConfig.CodeCoverage.OutputPath = Join-Path $projectRoot 'test/coverage.xml'
    } else {
        Write-Host "Warning: coverage target not found at $coverageTarget — running without coverage."
        $pesterConfig.CodeCoverage.Enabled = $false
    }
}

# --- Invoke Pester ---
Write-Host ""
Write-Host ("=" * 60)
Write-Host "Pester paths: $($pesterPaths -join ', ')"
if ($VerboseOutput) { Write-Host "Verbosity: Detailed" }
if ($All)           { Write-Host "Filter: ExcludeTag=slow" }
if ($Coverage)      { Write-Host "Coverage enabled: $($pesterConfig.CodeCoverage.Path)" }
Write-Host ("=" * 60)

# Pre-check: Pester 5 throws when no *.Tests.ps1 files exist anywhere under the configured paths.
# Treat that as a clean "no tests found" exit rather than a failure.
$testFiles = @()
foreach ($p in $pesterPaths) {
    if (Test-Path $p) {
        $testFiles += Get-ChildItem -Path $p -Filter '*.Tests.ps1' -Recurse -ErrorAction SilentlyContinue
    }
}
if ($testFiles.Count -eq 0) {
    Write-Host ""
    Write-ProjectSuccess -Message "No *.Tests.ps1 files found under: $($pesterPaths -join ', '). Nothing to run."
    Write-Host ("=" * 60)
    exit 0
}

# PF-IMP-904: suppress soak counting for the duration of the test run so in-process
# (and subprocess-descendant) test invocations of soak-armored scripts never advance
# the real soak counter. Tests that intentionally verify soak counting set
# $env:PF_SOAK_DISABLE='0' locally (see ExecutionVerification.Tests.ps1).
$priorSoakDisable = $env:PF_SOAK_DISABLE
$env:PF_SOAK_DISABLE = '1'

$result = $null
try {
    $result = Invoke-Pester -Configuration $pesterConfig
} catch {
    $env:PF_SOAK_DISABLE = $priorSoakDisable
    Write-ProjectError -Message "Pester invocation failed: $($_.Exception.Message)" -ExitCode 1
}
$env:PF_SOAK_DISABLE = $priorSoakDisable

# --- Summary ---
Write-Host ""
Write-Host ("=" * 60)
if ($result) {
    $countsSummary = "$($result.PassedCount) passed"
    if ($result.FailedCount  -gt 0) { $countsSummary += ", $($result.FailedCount) failed" }
    if ($result.SkippedCount -gt 0) { $countsSummary += ", $($result.SkippedCount) skipped" }
    if ($result.NotRunCount  -gt 0) { $countsSummary += ", $($result.NotRunCount) not run" }
    $duration = '{0:N2}s' -f $result.Duration.TotalSeconds

    if ($result.FailedCount -eq 0) {
        Write-ProjectSuccess -Message "All tests completed successfully! ($countsSummary in $duration)"
    } else {
        Write-ProjectError -Message "Some tests failed! ($countsSummary in $duration)" -ExitCode 1
    }
} else {
    Write-ProjectError -Message "No Pester result object returned." -ExitCode 1
}
Write-Host ("=" * 60)

exit $(if ($result.FailedCount -eq 0) { 0 } else { 1 })
