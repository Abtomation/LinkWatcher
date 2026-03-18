<#
.SYNOPSIS
    Language-agnostic test runner that uses project and language configuration for command execution.

.DESCRIPTION
    Reads project-config.json for project-specific settings (test directory, module name, quick categories)
    and languages-config/{language}-config.json for language-specific commands (test runner, coverage, lint).

    Test categories are discovered dynamically by scanning subdirectories of the test directory.
    Use -ListCategories to see available categories.

.PARAMETER Category
    Run tests in a specific subdirectory category (e.g., -Category unit, -Category integration).
    Categories are discovered from subdirectories of the test directory.

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

.EXAMPLE
    .\Run-Tests.ps1 -Category unit
    .\Run-Tests.ps1 -All -Coverage
    .\Run-Tests.ps1 -Quick
    .\Run-Tests.ps1 -ListCategories

.NOTES
    Config: project-config.json (project settings) + languages-config/{language}-config.json (commands).
    Categories are auto-discovered from test directory subdirectories.
#>

[CmdletBinding()]
param(
    [string]$Category,
    [switch]$Quick,
    [switch]$All,
    [switch]$Coverage,
    [switch]$Discover,
    [switch]$Lint,
    [switch]$Critical,
    [switch]$Performance,
    [switch]$ListCategories,
    [switch]$VerboseOutput
)

# --- Resolve project root and configs ---
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$projectRoot = (Resolve-Path (Join-Path $scriptDir "../../../..")).Path
$configPath = Join-Path $projectRoot "doc/process-framework/project-config.json"

if (-not (Test-Path $configPath)) {
    Write-Error "project-config.json not found at: $configPath"
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$testDir = $config.testing.testDirectory
if (-not $testDir) { $testDir = $config.paths.tests }
$moduleName = $config.project.name.ToLower()
$language = $config.testing.language

if (-not $language) {
    Write-Error "testing.language not set in project-config.json"
    exit 1
}

# --- Load language config ---
$langConfigPath = Join-Path $projectRoot "doc/process-framework/languages-config/$language-config.json"
if (-not (Test-Path $langConfigPath)) {
    Write-Error "Language config not found: $langConfigPath. Create it or check testing.language in project-config.json."
    exit 1
}

$langConfig = Get-Content $langConfigPath -Raw | ConvertFrom-Json
$testing = $langConfig.testing

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
    Write-Error "Test directory not found: $testPath"
    exit 1
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
        & $Command[0] $Command[1..($Command.Length - 1)]
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
$anyFlag = $Category -or $Quick -or $All -or $Coverage -or $Discover -or $Lint -or $Critical -or $Performance
if (-not $anyFlag) { $Quick = $true }

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

# --- Category (dynamic) ---
if ($Category) {
    if ($Category -notin $categories) {
        Write-Error "Unknown category '$Category'. Available: $($categories -join ', '). Use -ListCategories to see all."
        exit 1
    }
    $cmd = Get-BaseCommand
    $cmd += "$testDir/$Category/"
    if ($VerboseOutput -and $testing.verboseFlag) { $cmd += $testing.verboseFlag }
    if ($Coverage -and $testing.coverageArgs) {
        $covArgs = Split-Command (Expand-Placeholders $testing.coverageArgs)
        $cmd += $covArgs
    }
    $result = Invoke-TestCommand -Command $cmd -Description "$Category Tests"
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
if ($Coverage -and -not ($Category -or $All)) {
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

# --- Summary ---
Write-Host ""
Write-Host ("=" * 60)
if ($success) {
    Write-Host "All tests completed successfully!"
}
else {
    Write-Host "Some tests failed!"
}
Write-Host ("=" * 60)

exit $(if ($success) { 0 } else { 1 })
