<#
.SYNOPSIS
    Language-agnostic test runner that uses project and language configuration for command execution.

.DESCRIPTION
    Reads project-config.json for project-specific settings (test directory, module name, quick categories)
    and languages-config/{language}/{language}-config.json for language-specific commands (test runner, coverage, lint).

    Test categories are discovered dynamically by scanning subdirectories of the test directory.
    Use -ListCategories to see available categories.

.PARAMETER Category
    Run tests in one or more subdirectory categories (e.g., -Category unit, -Category unit,integration).
    Multiple categories can be comma-separated. Categories are discovered from subdirectories of the test directory.

.PARAMETER Quick
    Run quick subset: categories defined in project-config.json quickCategories, stop on first failure.
    Default if no flag given.

.PARAMETER All
    Run all tests (excluding slow by default).

.PARAMETER Coverage
    Generate coverage report. Can combine with -Category or -All.

.PARAMETER Discover
    Run test discovery to check for collection issues.

.PARAMETER Lint
    Run language-specific linting on test files.

.PARAMETER Critical
    Run only critical priority tests (uses language marker syntax).

.PARAMETER Performance
    Run performance/slow tests (uses language marker syntax).

.PARAMETER ListCategories
    List available test categories (subdirectories) and exit.

.PARAMETER VerboseOutput
    Enable verbose test output.

.PARAMETER UpdateTracking
    After running tests, parse per-file pass/fail results and update test-tracking.md.
    Requires verbose pytest output to parse individual test results.
    Matches test-tracking.md rows by file name (SC-007: no registry lookup needed).

.EXAMPLE
    .\Run-Tests.ps1 -Category unit
    .\Run-Tests.ps1 -Category unit,integration
    .\Run-Tests.ps1 -All -Coverage
    .\Run-Tests.ps1 -Quick
    .\Run-Tests.ps1 -ListCategories
    .\Run-Tests.ps1 -Category unit -UpdateTracking

.NOTES
    Config: project-config.json (project settings) + languages-config/{language}/{language}-config.json (commands).
    Categories are auto-discovered from test directory subdirectories.
#>

[CmdletBinding()]
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
$modulePath = Join-Path -Path $scriptDir -ChildPath "../../scripts/Common-ScriptHelpers.psm1"
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
$moduleName = $config.project.name.ToLower()
$language = $config.testing.language

if (-not $language) {
    Write-ProjectError -Message "testing.language not set in project-config.json" -ExitCode 1
}

# --- Load language config ---
$langConfigPath = Join-Path $projectRoot "process-framework/languages-config/$language/$language-config.json"
if (-not (Test-Path $langConfigPath)) {
    Write-ProjectError -Message "Language config not found: $langConfigPath. Create it or check testing.language in project-config.json." -ExitCode 1
}

$langConfig = Get-Content $langConfigPath -Raw | ConvertFrom-Json
$testing = $langConfig.testing

# --- Resolve python executable (handles PATH inherited from bash in Unix format) ---
$baseCmd = ($testing.baseCommand -split '\s+')[0]
if (-not (Get-Command $baseCmd -ErrorAction SilentlyContinue)) {
    # Try common Windows Python locations
    $pythonCandidates = @(
        "$env:LOCALAPPDATA\Microsoft\WindowsApps\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python39\python.exe"
    )
    $resolvedPython = $pythonCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($resolvedPython) {
        $testing.baseCommand = $testing.baseCommand -replace [regex]::Escape($baseCmd), "`"$resolvedPython`""
        Write-Host "Resolved $baseCmd to: $resolvedPython"
    } else {
        Write-ProjectError -Message "$baseCmd not found in PATH or common locations. Install Python or update PATH." -ExitCode 1
    }
}

# --- Helper: substitute placeholders in a string ---
function Expand-Placeholders {
    param([string]$Template)
    $Template = $Template -replace '\{module\}', $moduleName
    $Template = $Template -replace '\{testDir\}', $testDir
    return $Template
}

# --- Helper: split a command string into an array ---
function Split-Command {
    param([string]$CommandString)
    # Handle quoted segments (e.g., -m "not slow")
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
# Exclude common non-test directories (caches, fixtures, helpers)
$excludedDirs = @('__pycache__', '.pytest_cache', 'fixtures', 'helpers', 'utils', 'conftest', 'node_modules', '.dart_tool', 'build')
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

# --- Collected test output for tracking (populated when -UpdateTracking is active) ---
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

    Push-Location $projectRoot
    try {
        if ($script:UpdateTracking) {
            # Capture output line-by-line while still displaying it
            $output = & $Command[0] $Command[1..($Command.Length - 1)] 2>&1
            foreach ($line in $output) {
                Write-Host $line
                $script:capturedTestOutput += $line.ToString()
            }
        } else {
            & $Command[0] $Command[1..($Command.Length - 1)]
        }
        return $LASTEXITCODE -eq 0
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

# --- UpdateTracking requires verbose output for per-test parsing ---
if ($UpdateTracking) {
    $VerboseOutput = $true
    $script:UpdateTracking = $true
}

$success = $true

# --- Discovery ---
if ($Discover) {
    if ($testing.discoveryCommand) {
        $cmd = Split-Command (Expand-Placeholders $testing.discoveryCommand)
    } else {
        $cmd = Get-BaseCommand
        $cmd += "--collect-only"
        $cmd += "-q"
    }
    $result = Invoke-TestCommand -Command $cmd -Description "Test Discovery"
    $success = $success -and $result
}

# --- Lint ---
if ($Lint) {
    if ($testing.lintCommand) {
        $cmd = Split-Command (Expand-Placeholders $testing.lintCommand)
        $result = Invoke-TestCommand -Command $cmd -Description "Linting Tests"
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
        $covArgs = Split-Command (Expand-Placeholders $testing.coverageArgs)
        $cmd += $covArgs
    }
    $catNames = $Category -join " + "
    $result = Invoke-TestCommand -Command $cmd -Description "$catNames Tests"
    $success = $success -and $result
}

# --- Critical ---
if ($Critical) {
    if ($testing.markers -and $testing.markers.critical) {
        $cmd = Get-BaseCommand
        $markerArgs = Split-Command $testing.markers.critical
        $cmd += $markerArgs
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
        $markerArgs = Split-Command $testing.markers.slow
        $cmd += $markerArgs
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
        foreach ($cat in $quickCats) {
            if ($cat -in $categories) {
                $cmd += "$testDir/$cat/"
            } else {
                Write-Host "Warning: quickCategory '$cat' not found in $testDir — skipping."
            }
        }
    } else {
        $cmd += "$testDir/"
    }
    if ($testing.stopOnFirstFailure) { $cmd += $testing.stopOnFirstFailure }
    if ($VerboseOutput -and $testing.verboseFlag) { $cmd += $testing.verboseFlag }
    $catNames = if ($quickCats.Count -gt 0) { $quickCats -join " + " } else { "all" }
    $result = Invoke-TestCommand -Command $cmd -Description "Quick Tests ($catNames)"
    $success = $success -and $result
}

# --- All ---
if ($All) {
    $cmd = Get-BaseCommand
    $cmd += "$testDir/"
    if ($VerboseOutput -and $testing.verboseFlag) { $cmd += $testing.verboseFlag }
    if ($Coverage -and $testing.coverageArgs) {
        $covArgs = Split-Command (Expand-Placeholders $testing.coverageArgs)
        $cmd += $covArgs
    }
    if ($testing.markers -and $testing.markers.notSlow) {
        $markerArgs = Split-Command $testing.markers.notSlow
        $cmd += $markerArgs
    }
    $result = Invoke-TestCommand -Command $cmd -Description "All Tests (excluding slow)"
    $success = $success -and $result
}

# --- Coverage only (standalone) ---
if ($Coverage -and -not (($Category -and $Category.Count -gt 0) -or $All)) {
    $cmd = Get-BaseCommand
    $cmd += "$testDir/"
    if ($testing.coverageFullArgs) {
        $covArgs = Split-Command (Expand-Placeholders $testing.coverageFullArgs)
        $cmd += $covArgs
    } elseif ($testing.coverageArgs) {
        $covArgs = Split-Command (Expand-Placeholders $testing.coverageArgs)
        $cmd += $covArgs
    }
    $result = Invoke-TestCommand -Command $cmd -Description "Coverage Report Generation"
    $success = $success -and $result

    if ($result) {
        Write-Host ""
        Write-Host ("=" * 60)
        Write-Host "Coverage report generated."
        Write-Host ("=" * 60)
    }
}

# --- Update tracking if requested ---
if ($UpdateTracking -and $script:capturedTestOutput.Count -gt 0) {
    Write-Host ""
    Write-Host ("=" * 60)
    Write-Host "Updating test-tracking.md with execution results..."
    Write-Host ("=" * 60)

    # Parse verbose pytest output: lines like "test/automated/unit/test_config.py::TestClass::test_method PASSED"
    $fileResults = @{}
    foreach ($line in $script:capturedTestOutput) {
        if ($line -match '^(test/.+?\.py)::.+\s+(PASSED|FAILED|SKIPPED|ERROR)') {
            $filePath = $matches[1]
            $result = $matches[2]
            if (-not $fileResults.ContainsKey($filePath)) {
                $fileResults[$filePath] = @{ Passed = 0; Failed = 0; Skipped = 0; Error = 0 }
            }
            switch ($result) {
                'PASSED'  { $fileResults[$filePath].Passed++ }
                'FAILED'  { $fileResults[$filePath].Failed++ }
                'SKIPPED' { $fileResults[$filePath].Skipped++ }
                'ERROR'   { $fileResults[$filePath].Error++ }
            }
        }
    }

    if ($fileResults.Count -eq 0) {
        Write-Host "No per-test results found in output — skipping tracking update."
    } else {
        # SC-007: Match test-tracking.md rows by file name (no registry needed)
        # Build per-file update list from test results
        $timestamp = Get-Date -Format "yyyy-MM-dd"
        $updatesByFileName = @{}
        $skippedCount = 0

        foreach ($filePath in $fileResults.Keys) {
            $stats = $fileResults[$filePath]
            $total = $stats.Passed + $stats.Failed + $stats.Skipped + $stats.Error
            $fileName = Split-Path $filePath -Leaf

            $runNote = "Run $timestamp`: $($stats.Passed) passed"
            if ($stats.Failed -gt 0) { $runNote += ", $($stats.Failed) failed" }
            if ($stats.Skipped -gt 0) { $runNote += ", $($stats.Skipped) skipped" }

            $updatesByFileName[$fileName] = @{
                Status = if ($stats.Failed -gt 0 -or $stats.Error -gt 0) { "🔴 Tests Failing" } else { "✅ Tests Implemented" }
                TestCasesCount = "$total"
                RunNote = $runNote
                FilePath = $filePath
                Passed = $stats.Passed
                Failed = $stats.Failed
            }
        }

        if ($updatesByFileName.Count -eq 0) {
            Write-Host "No test files to update — skipping tracking update."
        } else {
            # Update test-tracking.md directly — match rows by file name in Test File/Case column
            # 8-column format (SC-007): Feature ID(0) | Test Type(1) | Test File/Case(2) | Status(3) | Test Cases Count(4) | Last Executed(5) | Last Updated(6) | Notes(7)
            $trackingPath = Join-Path $projectRoot "test/state-tracking/permanent/test-tracking.md"
            $trackingContent = Get-Content $trackingPath -Raw -Encoding UTF8
            $trackingLines = $trackingContent -split '\r?\n'

            $updatedCount = 0
            $updatedLines = @()
            foreach ($line in $trackingLines) {
                $matched = $false
                if ($line -match '^\|') {
                    foreach ($fileName in $updatesByFileName.Keys) {
                        $escapedName = [regex]::Escape($fileName)
                        if ($line -match $escapedName) {
                            $u = $updatesByFileName[$fileName]
                            # Parse columns: split on | and remove first/last empty elements
                            $rawCols = $line -split '\|'
                            if ($rawCols.Count -gt 2) {
                                $rawCols = $rawCols[1..($rawCols.Count-2)]
                            }
                            $cols = $rawCols | ForEach-Object { $_.Trim() }

                            if ($cols.Count -ge 8) {
                                $cols[3] = $u.Status                    # Status
                                $cols[4] = $u.TestCasesCount            # Test Cases Count
                                $cols[5] = $u.RunNote                   # Last Executed
                                $cols[6] = $timestamp                   # Last Updated
                                # Preserve existing Notes (col 7)
                            }

                            $updatedLines += "| " + ($cols -join " | ") + " |"
                            Write-Host "  OK: $fileName ($($u.FilePath)) — $($u.Passed)p/$($u.Failed)f"
                            $updatedCount++
                            $matched = $true
                            break
                        }
                    }
                }
                if (-not $matched) {
                    $updatedLines += $line
                }
            }

            # Write back
            $updatedContent = $updatedLines -join "`n"
            $updatedContent = $updatedContent -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $timestamp"
            Set-Content $trackingPath $updatedContent -Encoding UTF8

            Write-Host ""
            Write-Host "Tracking update: $updatedCount updated, $skippedCount skipped (of $($fileResults.Count) test files)"
        }
    }
}

# --- Update coverage summary if -Coverage -UpdateTracking ---
if ($UpdateTracking -and $Coverage -and $script:capturedTestOutput.Count -gt 0) {
    Write-Host ""
    Write-Host ("=" * 60)
    Write-Host "Updating coverage summary in test-tracking.md..."
    Write-Host ("=" * 60)

    # Parse TOTAL line: "TOTAL                                 2710    392    86%"
    $totalCoverage = $null
    foreach ($line in $script:capturedTestOutput) {
        if ($line -match '^TOTAL\s+\d+\s+\d+\s+(\d+)%') {
            $totalCoverage = "$($matches[1])%"
        }
    }

    # Parse pytest summary line: "477 passed, 5 skipped, 3 deselected, 7 xfailed"
    $testsPassed = "—"
    $testsSkipped = "—"
    $testsFailed = "—"
    foreach ($line in $script:capturedTestOutput) {
        if ($line -match '(\d+) passed') { $testsPassed = $matches[1] }
        if ($line -match '(\d+) failed') { $testsFailed = $matches[1] }
        if ($line -match '(\d+) skipped') { $testsSkipped = $matches[1] }
    }
    if ($testsFailed -eq "—") { $testsFailed = "0" }
    if ($testsSkipped -eq "—") { $testsSkipped = "0" }

    if ($totalCoverage) {
        $timestamp = Get-Date -Format "yyyy-MM-dd"
        $runType = if ($All) { "All (excl. slow)" } elseif ($Category -and $Category.Count -gt 0) { "Category: $($Category -join ', ')" } else { "Full" }
        $newRow = "| $timestamp | $totalCoverage | $testsPassed | $testsSkipped | $testsFailed | $runType |"

        $trackingPath = Join-Path $projectRoot "test/state-tracking/permanent/test-tracking.md"
        $trackingContent = Get-Content $trackingPath -Raw -Encoding UTF8
        $trackingLines = $trackingContent -split '\r?\n'

        # Insert after the Coverage Summary header row (|------|...)
        $updatedLines = @()
        $inserted = $false
        foreach ($tline in $trackingLines) {
            $updatedLines += $tline
            if (-not $inserted -and $tline -match '^\|[-\s|]+\|$' -and $updatedLines[-2] -match 'Date.*Total Coverage') {
                $updatedLines += $newRow
                $inserted = $true
            }
        }

        if ($inserted) {
            $updatedContent = $updatedLines -join "`n"
            Set-Content $trackingPath $updatedContent -Encoding UTF8
            Write-Host "  Coverage: $totalCoverage ($testsPassed passed, $testsFailed failed, $testsSkipped skipped) — $runType"
        } else {
            Write-Host "  Could not find Coverage Summary table in test-tracking.md — skipping."
        }
    } else {
        Write-Host "  No TOTAL coverage line found in output — skipping coverage tracking."
    }
}

# --- Summary ---
Write-Host ""
Write-Host ("=" * 60)
if ($success) {
    Write-ProjectSuccess -Message "All tests completed successfully!"
}
else {
    Write-ProjectError -Message "Some tests failed!"
}
Write-Host ("=" * 60)

exit $(if ($success) { 0 } else { 1 })
