<#
.SYNOPSIS
    Per-language test runner for Dart/Flutter projects (dispatched by Run-Tests.ps1).

.DESCRIPTION
    Reads project-config.json for project-specific settings (test directory, quick categories)
    and process-framework/languages-config/dart/dart-config.json for Dart-specific commands.

    Test categories are discovered dynamically by scanning subdirectories of the test directory.
    Use -ListCategories to see available categories.

    CLI-style runner: executes the command strings from dart-config.json directly
    (flutter test). Created via the Run-Tests runner template for Project Initiation
    (PF-TSK-059) of the first Dart/Flutter project on the framework (Letscape, PRJ-003).

.PARAMETER Category
    Run tests in one or more subdirectory categories (e.g., -Category unit, -Category unit,widget).

.PARAMETER Quick
    Run quick subset: categories defined in project-config.json quickCategories, stop on first failure.
    Default if no flag given.

.PARAMETER All
    Run all tests (excluding slow-tagged tests by default).

.PARAMETER Coverage
    Generate coverage report (flutter test --coverage → coverage/lcov.info). Can combine with -Category or -All.

.PARAMETER Discover
    List test files (filesystem scan for *_test.dart — flutter test has no collect-only mode).

.PARAMETER Lint
    Run dart analyze on the test directory.

.PARAMETER Critical
    Run only tests tagged 'critical' (dart_test.yaml tags).

.PARAMETER Performance
    Run tests tagged 'slow' (dart_test.yaml tags).

.PARAMETER ListCategories
    List available test categories (subdirectories) and exit.

.PARAMETER VerboseOutput
    Enable expanded reporter output.

.PARAMETER UpdateTracking
    Not yet implemented for dart — prints a notice and continues. Extend this runner
    (parse expanded-reporter per-test lines) once the Flutter scaffold exists to test against.

.EXAMPLE
    Run-Tests.ps1 -Category unit
    Run-Tests.ps1 -All -Coverage
    Run-Tests.ps1 -Quick
    Run-Tests.ps1 -ListCategories

.NOTES
    Config: doc/project-config.json (project settings) + process-framework/languages-config/dart/dart-config.json (commands).
    Requires the Flutter SDK on PATH and a pubspec.yaml at the project root (created during 0.x foundation work).
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
$modulePath = Join-Path -Path $scriptDir -ChildPath "../../Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers: $($_.Exception.Message)"
    exit 1
}

# --- Resolve project root and configs ---
$projectRoot = Get-ProjectRoot
if (-not $projectRoot) {
    Write-ProjectError -Message "Could not find project root" -ExitCode 1
}
$configPath = Join-Path $projectRoot "doc/project-config.json"

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$testDir = $config.testing.testDirectory
if (-not $testDir) { $testDir = $config.paths.tests }
$language = $config.testing.language

if (-not $language) {
    Write-ProjectError -Message "testing.language not set in project-config.json" -ExitCode 1
}

# --- Load language config ---
$langConfigPath = Join-Path (Get-ProcessFrameworkPath) "languages-config/$language/$language-config.json"
if (-not (Test-Path $langConfigPath)) {
    Write-ProjectError -Message "Language config not found: $langConfigPath. Create it or check testing.language in project-config.json." -ExitCode 1
}

$langConfig = Get-Content $langConfigPath -Raw | ConvertFrom-Json
$testing = $langConfig.testing

# --- SDK/package guards live in Invoke-TestCommand, not here: metadata operations
#     (-ListCategories, -Discover) must work before the Flutter scaffold exists. ---
$baseCmd = ($testing.baseCommand -split '\s+')[0]

# --- Helper: substitute placeholders in a string ---
function Expand-Placeholders {
    param([string]$Template)
    $Template = $Template -replace '\{module\}', $config.project.name.ToLower()
    $Template = $Template -replace '\{testDir\}', $testDir
    return $Template
}

# --- Helper: split a command string into an array ---
function Split-Command {
    param([string]$CommandString)
    # Handle quoted segments (e.g., --tags "slow")
    $parts = [System.Collections.ArrayList]@()
    $regex = [regex]'"([^"]+)"|(\S+)'
    foreach ($match in $regex.Matches($CommandString)) {
        if ($match.Groups[1].Success) {
            [void]$parts.Add($match.Groups[1].Value)
        } else {
            [void]$parts.Add($match.Groups[2].Value)
        }
    }
    return $parts.ToArray()
}

# --- Helper: build base command array from language config ---
function Get-BaseCommand {
    return Split-Command (Expand-Placeholders $testing.baseCommand)
}

# --- Resolve test directory relative to project root ---
$testPath = Join-Path $projectRoot $testDir
if (-not (Test-Path $testPath)) {
    Write-ProjectError -Message "Test directory not found: $testPath" -ExitCode 1
}

# --- Discover categories from subdirectories ---
$excludedDirs = @('.dart_tool', 'build', 'fixtures', 'helpers', 'utils', 'node_modules', '__pycache__')
$categories = Get-ChildItem -Path $testPath -Directory |
    Where-Object { $_.Name -notin $excludedDirs -and -not $_.Name.StartsWith('.') } |
    ForEach-Object { $_.Name }

# --- List categories ---
if ($ListCategories) {
    Write-Host "Available test categories (subdirectories of $testDir):"
    foreach ($cat in $categories) {
        Write-Host "  - $cat"
    }
    $quickCats = $config.testing.quickCategories
    if ($quickCats) {
        Write-Host ""
        Write-Host "Quick categories: $($quickCats -join ', ')"
    }
    exit 0
}

# --- Collected test output for summary parsing ---
$script:capturedTestOutput = @()

# --- Helper: run a command and return success ---
function Invoke-TestCommand {
    param(
        [string[]]$Command,
        [string]$Description
    )

    Write-Host ""
    Write-Host ("=" * 60)
    if ($Description) { Write-Host "Running: $Description" }
    Write-Host "Command: $($Command -join ' ')"
    Write-Host ("=" * 60)

    if ($WhatIfPreference) {
        Write-Host "What if: Would execute $Description"
        Write-Host "  Command: $($Command -join ' ')"
        return $true
    }

    # Guard actual SDK invocations (flutter test / dart analyze both ship with the Flutter SDK).
    if (-not (Get-Command $baseCmd -ErrorAction SilentlyContinue)) {
        Write-ProjectError -Message "$baseCmd not found in PATH. Install the Flutter SDK (https://flutter.dev) or update PATH." -ExitCode 1
    }
    if (-not (Test-Path (Join-Path $projectRoot "pubspec.yaml"))) {
        Write-ProjectError -Message "pubspec.yaml not found at project root — flutter test requires a Dart package. The app scaffold is created during 0.x foundation work." -ExitCode 1
    }

    Push-Location $projectRoot
    try {
        # Capture output locally so the caller's boolean assignment doesn't absorb
        # test output into the pipeline (same guard as the python runner).
        $output = & $Command[0] $Command[1..($Command.Length - 1)] 2>&1
        $exitCode = $LASTEXITCODE
        foreach ($line in $output) {
            Write-Host $line
            $script:capturedTestOutput += $line.ToString()
        }
        return $exitCode -eq 0
    }
    catch {
        Write-Host "Error running command: $_"
        return $false
    }
    finally {
        Pop-Location
    }
}

# --- Default to Quick if nothing specified ---
$anyFlag = ($Category -and $Category.Count -gt 0) -or $Quick -or $All -or $Coverage -or $Discover -or $Lint -or $Critical -or $Performance
if (-not $anyFlag) { $Quick = $true }

if ($UpdateTracking) {
    Write-Host "NOTE: -UpdateTracking is not yet implemented for dart — update test-tracking.md manually."
    Write-Host "      Extend Run-Tests.dart.ps1 (parse expanded-reporter output) once a Flutter scaffold exists."
}

$success = $true

# --- Discovery (filesystem scan — flutter test has no collect-only mode) ---
if ($Discover) {
    Write-Host ""
    Write-Host ("=" * 60)
    Write-Host "Running: Test Discovery (filesystem scan for *_test.dart)"
    Write-Host ("=" * 60)
    $testFiles = Get-ChildItem -Path $testPath -Recurse -Filter '*_test.dart' |
        Where-Object { $_.FullName -notmatch '\\(\.dart_tool|build)\\' }
    foreach ($f in $testFiles) {
        $rel = [System.IO.Path]::GetRelativePath($projectRoot, $f.FullName) -replace '\\', '/'
        Write-Host "  $rel"
    }
    Write-Host "$($testFiles.Count) test file(s) found."
}

# --- Lint ---
if ($Lint) {
    if ($testing.lintCommand) {
        $cmd = Split-Command (Expand-Placeholders $testing.lintCommand)
        $result = Invoke-TestCommand -Command $cmd -Description "Analyzing Tests (dart analyze)"
        $success = $success -and $result
    } else {
        Write-Host "No lintCommand defined in $language-config.json — skipping lint."
    }
}

# --- Category (dynamic, supports multiple) ---
if ($Category) {
    foreach ($cat in $Category) {
        if ($cat -notin $categories) {
            Write-ProjectError -Message "Unknown category '$cat'. Available: $($categories -join ', '). Use -ListCategories to see all." -ExitCode 1
        }
    }
    $cmd = Get-BaseCommand
    foreach ($cat in $Category) {
        $cmd += "$testDir/$cat/"
    }
    if ($VerboseOutput -and $testing.verboseFlag) { $cmd += $testing.verboseFlag }
    if ($Coverage -and $testing.coverageArgs) {
        $cmd += Split-Command (Expand-Placeholders $testing.coverageArgs)
    }
    $catNames = $Category -join " + "
    $result = Invoke-TestCommand -Command $cmd -Description "$catNames Tests"
    $success = $success -and $result
}

# --- Critical ---
if ($Critical) {
    if ($testing.markers -and $testing.markers.critical) {
        $cmd = Get-BaseCommand
        $cmd += "$testDir/"
        $cmd += Split-Command $testing.markers.critical
        if ($VerboseOutput -and $testing.verboseFlag) { $cmd += $testing.verboseFlag }
        $result = Invoke-TestCommand -Command $cmd -Description "Critical Tests"
        $success = $success -and $result
    } else {
        Write-Host "No critical marker defined in $language-config.json — skipping."
    }
}

# --- Performance ---
if ($Performance) {
    if ($testing.markers -and $testing.markers.slow) {
        $cmd = Get-BaseCommand
        $cmd += "$testDir/"
        $cmd += Split-Command $testing.markers.slow
        if ($VerboseOutput -and $testing.verboseFlag) { $cmd += $testing.verboseFlag }
        $result = Invoke-TestCommand -Command $cmd -Description "Performance Tests"
        $success = $success -and $result
    } else {
        Write-Host "No slow marker defined in $language-config.json — skipping."
    }
}

# --- Quick ---
if ($Quick) {
    $quickCats = $config.testing.quickCategories
    if (-not $quickCats -or $quickCats.Count -eq 0) {
        Write-Host "No quickCategories defined in project-config.json — running all with stop-on-first-failure."
        $quickCats = @()
    }

    $cmd = Get-BaseCommand
    if ($quickCats.Count -gt 0) {
        $presentCats = @()
        foreach ($cat in $quickCats) {
            if ($cat -in $categories) {
                # Only pass categories that contain test files — flutter test errors on
                # directories with nothing to run (empty scaffold dirs pre-0.x).
                $hasTests = Get-ChildItem -Path (Join-Path $testPath $cat) -Recurse -Filter '*_test.dart' -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($hasTests) {
                    $cmd += "$testDir/$cat/"
                    $presentCats += $cat
                } else {
                    Write-Host "Note: quickCategory '$cat' contains no *_test.dart files yet — skipping."
                }
            } else {
                Write-Host "Warning: quickCategory '$cat' not found in $testDir — skipping."
            }
        }
        if ($presentCats.Count -eq 0) {
            Write-Host "No quick categories with test files — nothing to run."
            $cmd = $null
        }
    } else {
        $cmd += "$testDir/"
    }
    if ($cmd) {
        if ($testing.stopOnFirstFailure) { $cmd += $testing.stopOnFirstFailure }
        if ($VerboseOutput -and $testing.verboseFlag) { $cmd += $testing.verboseFlag }
        $catNames = if ($quickCats.Count -gt 0) { $quickCats -join " + " } else { "all" }
        $result = Invoke-TestCommand -Command $cmd -Description "Quick Tests ($catNames)"
        $success = $success -and $result
    }
}

# --- All ---
if ($All) {
    $cmd = Get-BaseCommand
    $cmd += "$testDir/"
    if ($VerboseOutput -and $testing.verboseFlag) { $cmd += $testing.verboseFlag }
    if ($Coverage -and $testing.coverageArgs) {
        $cmd += Split-Command (Expand-Placeholders $testing.coverageArgs)
    }
    if ($testing.markers -and $testing.markers.notSlow) {
        $cmd += Split-Command $testing.markers.notSlow
    }
    $result = Invoke-TestCommand -Command $cmd -Description "All Tests (excluding slow)"
    $success = $success -and $result
}

# --- Coverage only (standalone) ---
if ($Coverage -and -not (($Category -and $Category.Count -gt 0) -or $All)) {
    $cmd = Get-BaseCommand
    $cmd += "$testDir/"
    if ($testing.coverageFullArgs) {
        $cmd += Split-Command (Expand-Placeholders $testing.coverageFullArgs)
    } elseif ($testing.coverageArgs) {
        $cmd += Split-Command (Expand-Placeholders $testing.coverageArgs)
    }
    $result = Invoke-TestCommand -Command $cmd -Description "Coverage Report Generation"
    $success = $success -and $result

    if ($result) {
        Write-Host ""
        Write-Host ("=" * 60)
        Write-Host "Coverage written to coverage/lcov.info (use genhtml or an lcov viewer for a report)."
        Write-Host ("=" * 60)
    }
}

# --- Summary ---
Write-Host ""
Write-Host ("=" * 60)

# Parse flutter compact-reporter tail lines, e.g. "00:04 +12: All tests passed!"
# or "00:04 +10 -2: Some tests failed." — best-effort counts across invocations.
$totalPassed = 0; $totalFailed = 0; $totalSkipped = 0
$summaryFound = $false
foreach ($line in $script:capturedTestOutput) {
    if ($line -match '\+(\d+)(?:\s+~(\d+))?(?:\s+-(\d+))?:\s+(All tests passed|Some tests failed)') {
        $summaryFound = $true
        $totalPassed = [int]$matches[1]
        if ($matches[2]) { $totalSkipped = [int]$matches[2] }
        if ($matches[3]) { $totalFailed = [int]$matches[3] }
    }
}

$countsSummary = ""
if ($summaryFound) {
    $parts = @("$totalPassed passed")
    if ($totalFailed -gt 0) { $parts += "$totalFailed failed" }
    if ($totalSkipped -gt 0) { $parts += "$totalSkipped skipped" }
    $countsSummary = " (" + ($parts -join ", ") + ")"
}

if ($success) {
    Write-ProjectSuccess -Message "All tests completed successfully!$countsSummary"
}
else {
    Write-ProjectError -Message "Some tests failed!$countsSummary"
}
Write-Host ("=" * 60)

exit $(if ($success) { 0 } else { 1 })
