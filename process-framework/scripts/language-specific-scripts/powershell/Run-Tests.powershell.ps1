<#
.SYNOPSIS
    PowerShell/Pester test runner — invoked by Run-Tests.ps1 dispatcher when testing.language='powershell'.

.DESCRIPTION
    Invokes Pester 5+ programmatically against the test directory configured in project-config.json.
    Reads language-specific commands from languages-config/powershell/powershell-config.json.

    Phase 3a v1 (2026-05-17) — Framework Self-Testing extension (PF-PRO-035):
      Supported flags: -Category / -TestFile / -Quick / -All / -Coverage / -ListCategories / -VerboseOutput
      Not yet implemented: -Discover / -Lint / -Critical / -Performance / -UpdateTracking (accepted for dispatcher
      forward-compatibility; the Python runner implements them). For linting the framework's own scripts, use
      scripts/validation/Run-ScriptConventionGate.ps1.

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
    Run categories from project-config.json testing.quickCategories, stopping at the first
    failure. Default if no flag given. The stop-at-first-failure is suppressed under -SaveBaseline
    / -Baseline, whose delta needs the complete failure set.

.PARAMETER All
    Run all tests, excluding tag 'slow' by default (mirrors python-runner -All semantics).

.PARAMETER Coverage
    Generate code coverage report. Coverage target = paths.source_code from project-config.json
    (or the project root if source_code is empty).

.PARAMETER ListCategories
    List available test categories and exit.

.PARAMETER VerboseOutput
    Use Pester Output.Verbosity = 'Detailed'.

.PARAMETER Discover
    Accepted for forward-compatibility with the dispatcher; not yet implemented in this runner
    (the Python runner implements it). Invoking it produces a clear "not yet implemented"
    message and exit code 2.

.PARAMETER Lint
    Accepted for forward-compatibility with the dispatcher; deliberately left unimplemented
    (PF-IMP-1365) — produces a "not yet implemented" message and exit code 2. To lint the
    framework's own scripts, use Run-ScriptConventionGate.ps1.

.PARAMETER Critical
    Accepted for forward-compatibility with the dispatcher; not yet implemented in this runner
    (the Python runner implements it). Produces a "not yet implemented" message and exit code 2.

.PARAMETER Performance
    Accepted for forward-compatibility with the dispatcher; not yet implemented in this runner
    (the Python runner implements it). Produces a "not yet implemented" message and exit code 2.

.PARAMETER UpdateTracking
    Accepted for forward-compatibility with the dispatcher; not yet implemented in this runner
    (the Python runner implements it). Produces a "not yet implemented" message and exit code 2.

.PARAMETER SaveBaseline
    Save this run's FAILED-test fingerprints as a baseline JSON for later delta comparison
    (PF-IMP-1308 — mirrors Validate-StateTracking.ps1's -SaveBaseline). Auto-named per session
    (pester-baseline-<project>-<timestamp>-<PID>.json, so parallel sessions never collide) under
    $env:TEMP\pester-baselines\; the path is printed at the end. Save a baseline BEFORE starting a
    scoped change, then re-run with -Baseline <path> afterward to prove your change introduced no
    NEW failures even in a tree carrying another session's in-progress failing edits. Each save
    prunes baselines older than 3 days. The run's exit code is unchanged by saving (a failing run
    still exits 1).

.PARAMETER Baseline
    Path to a baseline JSON previously written by -SaveBaseline. After the run, compares current
    failures against the baseline and reports NEW / pre-existing / resolved. The exit code becomes
    delta-based: 0 unless this run introduced NEW failures, so pre-existing failures (e.g. from a
    parallel session's edits) no longer fail the run. Warns if the baseline was saved for a
    different project root or test scope. Use the SAME scope (-All / -Category / -TestFile) on save
    and compare.
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

# --- Import Common-ScriptHelpers ---
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "../../Common-ScriptHelpers.psm1"
try {
    Import-Module (Resolve-Path $modulePath -ErrorAction Stop) -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers: $($_.Exception.Message)"
    exit 1
}

# --- Forward-compatibility: still-unimplemented flags (accepted for dispatcher parity) ---
# -Lint was reassessed 2026-06-30 (PF-IMP-1365) and deliberately left unimplemented: nothing
# consumes it, and framework *script* linting is owned by Run-ScriptConventionGate.ps1 — so the
# -Lint stub redirects there rather than re-implementing PSScriptAnalyzer over the test dir.
$deferred = @()
if ($Discover)       { $deferred += '-Discover' }
if ($Lint)           { $deferred += '-Lint' }
if ($Critical)       { $deferred += '-Critical' }
if ($Performance)    { $deferred += '-Performance' }
if ($UpdateTracking) { $deferred += '-UpdateTracking' }
if ($deferred.Count -gt 0) {
    $msg = "Flags not yet implemented in Run-Tests.powershell.ps1: $($deferred -join ', '). (The Python runner implements them.)"
    if ($Lint) { $msg += " For linting the framework's own scripts, use scripts/validation/Run-ScriptConventionGate.ps1." }
    Write-ProjectError -Message $msg -ExitCode 2
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
    Write-Host "-Category also accepts a nested area by unique name (e.g. 'helpers' -> automated/unit/framework/helpers) or a relative path under automated"
    $quickCats = $config.testing.quickCategories
    if ($quickCats) {
        Write-Host ""
        Write-Host "Quick categories: $($quickCats -join ', ')"
    }
    exit 0
}

# --- Default to Quick if nothing specified ---
$anyFlag = ($TestFile -and $TestFile.Count -gt 0) -or ($Category -and $Category.Count -gt 0) -or $Quick -or $All -or $Coverage
if (-not $anyFlag) { $Quick = $true }

# --- Resolve test paths based on flag combination ---
$pesterPaths = @()
$automatedRoot = Join-Path $testPath 'automated'

if ($TestFile) {
    # PF-IMP-1167: run specific test files in isolation (fast iterate-after-fix loop).
    # Resolve each path relative to the current directory first, then the project root.
    # Takes precedence over -Category; the caller never re-runs a whole category to
    # validate a one-file change.
    #
    # PF-IMP-1542: split each element on commas so a CSV list survives pwsh -File's
    # literal-token binding (which delivers 'a,b' as ONE element) — the split-in-place
    # pattern from Push-FrameworkUpdate.ps1 -Project (PF-IMP-1428). Comma-only: file
    # paths may contain spaces.
    $testFileTokens = @($TestFile -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    foreach ($tf in $testFileTokens) {
        $resolved = if (Test-Path $tf) {
            (Resolve-Path $tf).Path
        } elseif (Test-Path (Join-Path $projectRoot $tf)) {
            (Resolve-Path (Join-Path $projectRoot $tf)).Path
        } else {
            $null
        }
        # PF-IMP-1542: a bare filename (no directory separator) not found as a path is
        # resolved by searching the test tree — it must match exactly one file.
        if (-not $resolved -and $tf -notmatch '[\\/]') {
            $found = @(Get-ChildItem -Path $testPath -Filter $tf -File -Recurse -ErrorAction SilentlyContinue)
            if ($found.Count -eq 1) {
                $resolved = $found[0].FullName
            } elseif ($found.Count -gt 1) {
                $rels = @($found | ForEach-Object { $_.FullName.Replace($projectRoot, '').TrimStart('\', '/') -replace '\\', '/' })
                Write-ProjectError -Message "Test file name '$tf' is ambiguous under '$testDir' ($($found.Count) matches): $($rels -join '; '). Pass a project-root-relative path." -ExitCode 1
            }
        }
        if (-not $resolved) {
            Write-ProjectError -Message "Test file not found: '$tf' (looked relative to the current directory, the project root '$projectRoot', and by filename under '$testDir')." -ExitCode 1
        }
        $pesterPaths += $resolved
    }
} elseif ($Category) {
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

# PF-IMP-1308: baseline/delta mode must see the COMPLETE failure set — it suppresses -Quick's
# fail-fast below, and nothing may make Pester self-exit before the delta logic runs.
$baselineMode = $SaveBaseline -or -not [string]::IsNullOrWhiteSpace($Baseline)

# -Quick: stop at the first failure — parity with the python and dart runners, and with the
# contract documented in languages-config/powershell/powershell-config.json.
#
# PF-IMP-1721: use SkipRemainingOnFailure, never Pester's Run.Exit. Run.Exit calls exit from
# INSIDE Invoke-Pester, before the assignment to $result completes, so the entire post-run tail
# is skipped (summary line, failure recap) and the PassThru result object lands in the log as a
# raw property dump — exactly where tail -N and a human look. -Quick set Run.Exit until
# 2026-07-29 in the name of a fail-fast it never actually delivered. SkipRemainingOnFailure
# returns normally, so the tail renders and the script's own verdict below owns the exit code
# (1 on failure, uniform with -Category / -TestFile / -All).
if ($Quick -and -not $baselineMode) {
    $pesterConfig.Run.SkipRemainingOnFailure = 'Run'
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

# PF-IMP-1168: print the queued test-file manifest as a heartbeat before the run, and flush
# it immediately. Printed up front (and flushed) so a stalled container is diagnosable in a
# redirected, non-TTY log — the hung file is the manifest entry with no subsequent Pester
# completion line. Surfaces the silent-hang case where a test stalls and Pester's per-file
# output never flushes before process exit.
Write-Host ""
Write-Host ("Running {0} test file(s):" -f $testFiles.Count)
foreach ($tf in $testFiles) {
    $relPath = $tf.FullName.Replace($projectRoot, '').TrimStart('\', '/')
    Write-Host "  -> $relPath"
}
[Console]::Out.Flush()

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

# --- Summary (informational counts; the verdict/exit is decided below, baseline-aware) ---
Write-Host ""
Write-Host ("=" * 60)
if (-not $result) {
    Write-ProjectError -Message "No Pester result object returned." -ExitCode 1
}
$countsSummary = "$($result.PassedCount) passed"
if ($result.FailedCount  -gt 0) { $countsSummary += ", $($result.FailedCount) failed" }
if ($result.SkippedCount -gt 0) { $countsSummary += ", $($result.SkippedCount) skipped" }
if ($result.NotRunCount  -gt 0) { $countsSummary += ", $($result.NotRunCount) not run" }
$duration = '{0:N2}s' -f $result.Duration.TotalSeconds
Write-Host ("=" * 60)

# =========================================================================
# PF-IMP-1308: baseline/delta mode — mirrors Validate-StateTracking.ps1's
# -SaveBaseline / -Baseline. A failed-test fingerprint is "<relFile>::<ExpandedPath>".
# -SaveBaseline records the current failure set (verdict unchanged); -Baseline makes the
# verdict delta-based so a tree carrying another session's pre-existing failures still
# answers "did MY change add a NEW failure?" unambiguously.
# $baselineMode is resolved before the Pester config is built (it also suppresses -Quick's
# fail-fast, which would otherwise truncate the failure set this delta depends on).
# =========================================================================
if ($baselineMode) {
    $failedTests = @($result.Tests | Where-Object { $_.Result -eq 'Failed' })
    $failureFingerprints = @($failedTests | ForEach-Object {
        $file = $null
        try { $file = $_.ScriptBlock.File } catch { $file = $null }
        $rel = if ($file) { ($file.Replace($projectRoot, '').TrimStart('\', '/') -replace '\\', '/') } else { '?' }
        $path = if ($_.ExpandedPath) { $_.ExpandedPath } elseif ($_.Path) { ($_.Path -join '.') } else { $_.Name }
        "$rel::$path"
    } | Sort-Object -Unique)
    $scopeRel = @($pesterPaths | ForEach-Object { ($_.Replace($projectRoot, '').TrimStart('\', '/') -replace '\\', '/') })
}

# --- Baseline compare (-Baseline): delta this run's failures against a saved baseline ---
$newFailures = $null
if (-not [string]::IsNullOrWhiteSpace($Baseline)) {
    if (-not (Test-Path $Baseline)) {
        Write-ProjectError -Message "Baseline file not found: $Baseline" -ExitCode 1
    }
    try {
        $baselineData = Get-Content $Baseline -Raw | ConvertFrom-Json
    } catch {
        Write-ProjectError -Message "Baseline file is not valid JSON: $Baseline" -ExitCode 1
    }

    Write-Host ""
    Write-Host "  Baseline comparison ($(Split-Path $Baseline -Leaf), saved $($baselineData.saved))" -ForegroundColor Cyan

    $normCurrentRoot  = "$projectRoot".TrimEnd('\', '/')
    $normBaselineRoot = "$($baselineData.projectRoot)".TrimEnd('\', '/')
    if ($normBaselineRoot -ne $normCurrentRoot) {
        Write-Host "  $([char]0x26A0)  Baseline was saved for a different project root ($normBaselineRoot) - comparison may be meaningless" -ForegroundColor Yellow
    }
    $baselineScope = (@($baselineData.scope) | Sort-Object) -join ','
    $currentScope  = (@($scopeRel) | Sort-Object) -join ','
    if ($baselineScope -ne $currentScope) {
        Write-Host "  $([char]0x26A0)  Baseline scope ($baselineScope) differs from this run ($currentScope) - delta may be incomplete" -ForegroundColor Yellow
    }

    $baselineSet = [System.Collections.Generic.HashSet[string]]::new([string[]]@($baselineData.failures | Where-Object { $_ }))
    $currentSet  = [System.Collections.Generic.HashSet[string]]::new([string[]]@($failureFingerprints))
    $newFailures = @($failureFingerprints | Where-Object { -not $baselineSet.Contains($_) } | Select-Object -Unique)
    $resolved    = @($baselineSet | Where-Object { -not $currentSet.Contains($_) })
    $preExisting = $currentSet.Count - $newFailures.Count

    Write-Host "  New failures:          $($newFailures.Count)" -ForegroundColor $(if ($newFailures.Count -eq 0) { 'Green' } else { 'Red' })
    Write-Host "  Pre-existing failures: $preExisting" -ForegroundColor Gray
    Write-Host "  Resolved failures:     $($resolved.Count)" -ForegroundColor $(if ($resolved.Count -gt 0) { 'Green' } else { 'Gray' })
    foreach ($fp in $newFailures) {
        Write-Host "    $([char]0x274C) NEW: $fp" -ForegroundColor Red
    }
}

# --- Baseline save (-SaveBaseline): write the failure fingerprints for a later -Baseline run ---
if ($SaveBaseline) {
    $baselineDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester-baselines"
    New-Item -ItemType Directory -Path $baselineDir -Force | Out-Null

    # Retention: prune baselines older than 3 days on every save (self-cleaning).
    Get-ChildItem -Path $baselineDir -Filter "pester-baseline-*.json" -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) } |
        Remove-Item -Force -ErrorAction SilentlyContinue

    $projectName  = (Split-Path $projectRoot -Leaf) -replace '[^\w\-]', '-'
    $baselineFile = Join-Path $baselineDir ("pester-baseline-{0}-{1}-{2}.json" -f $projectName, (Get-Date -Format 'yyyyMMdd-HHmmss'), $PID)
    [ordered]@{
        schema      = 1
        saved       = (Get-Date -Format 'o')
        projectRoot = "$projectRoot"
        scope       = @($scopeRel)
        failedCount = $result.FailedCount
        failures    = @($failureFingerprints)
    } | ConvertTo-Json -Depth 4 | Set-Content -Path $baselineFile -Encoding UTF8

    Write-Host ""
    Write-Host "  Baseline saved: $baselineFile" -ForegroundColor Cyan
    Write-Host "  Compare after your change with: -Baseline `"$baselineFile`"" -ForegroundColor Gray
}

# PF-IMP-1523: failure recap at the tail. Test files spawn child pwsh processes whose
# console output the runner cannot suppress (children inherit the OS stdout handle,
# bypassing every PowerShell stream), and the closing summary names only counts — so a
# mid-run failure is buried in a long log. Re-print every failed test here, where
# tail -N and a human land first. Prints nothing on a green run.
if ($result.FailedCount -gt 0) {
    Write-Host ""
    Write-Host "  Failed test recap ($($result.FailedCount)):" -ForegroundColor Red
    foreach ($t in @($result.Tests | Where-Object { $_.Result -eq 'Failed' })) {
        $file = $null
        try { $file = $t.ScriptBlock.File } catch { $file = $null }
        $rel = if ($file) { ($file.Replace($projectRoot, '').TrimStart('\', '/') -replace '\\', '/') } else { '?' }
        $path = if ($t.ExpandedPath) { $t.ExpandedPath } elseif ($t.Path) { ($t.Path -join '.') } else { $t.Name }
        Write-Host "    [-] ${rel}::${path}" -ForegroundColor Red
        $msg = $null
        try { $msg = @($t.ErrorRecord)[0].DisplayErrorMessage } catch { $msg = $null }
        if (-not $msg) { try { $msg = @($t.ErrorRecord)[0].Exception.Message } catch { $msg = $null } }
        if ($msg) {
            $firstLine = @($msg -split "`r?`n" | Where-Object { $_.Trim() })[0]
            if ($firstLine -and $firstLine.Length -gt 220) { $firstLine = $firstLine.Substring(0, 220) + '...' }
            if ($firstLine) { Write-Host "        $($firstLine.Trim())" -ForegroundColor DarkGray }
        }
    }
    Write-Host ""
}

# --- Verdict: delta-based when -Baseline supplied; otherwise the normal all-or-nothing gate ---
if ($null -ne $newFailures) {
    Write-Host ("=" * 60)
    if ($newFailures.Count -eq 0) {
        Write-ProjectSuccess -Message "No new failures vs baseline. ($countsSummary in $duration)"
        exit 0
    } else {
        Write-ProjectError -Message "$($newFailures.Count) new failure(s) vs baseline. ($countsSummary in $duration)" -ExitCode 1
    }
}

if ($result.FailedCount -eq 0) {
    Write-ProjectSuccess -Message "All tests completed successfully! ($countsSummary in $duration)"
} else {
    Write-ProjectError -Message "Some tests failed! ($countsSummary in $duration)" -ExitCode 1
}
Write-Host ("=" * 60)

exit $(if ($result.FailedCount -eq 0) { 0 } else { 1 })
