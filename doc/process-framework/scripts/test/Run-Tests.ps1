<#
.SYNOPSIS
    Project-agnostic test runner that wraps pytest with category-based execution.

.DESCRIPTION
    Reads project-config.json to determine the test directory and project module name,
    then executes pytest with the appropriate flags for the selected test category.

    Supports: Unit, Integration, Parser, Performance, Critical, Quick, All, Coverage, Discovery.

.PARAMETER Unit
    Run unit tests only.

.PARAMETER Integration
    Run integration tests only.

.PARAMETER Parsers
    Run parser-specific tests only.

.PARAMETER Performance
    Run performance/slow tests only.

.PARAMETER Critical
    Run only critical priority tests (pytest marker: critical).

.PARAMETER Quick
    Run a quick subset (unit + parsers, stop on first failure). Default if no flag given.

.PARAMETER All
    Run all tests (excluding slow by default).

.PARAMETER Coverage
    Generate coverage report. Can combine with -Unit or -All.

.PARAMETER Discover
    Run test discovery to check for collection issues.

.PARAMETER Lint
    Run flake8 linting on test files.

.PARAMETER Verbose
    Enable verbose pytest output.

.EXAMPLE
    .\Run-Tests.ps1 -Unit
    .\Run-Tests.ps1 -All -Coverage
    .\Run-Tests.ps1 -Parsers -Verbose

.NOTES
    Requires: Python with pytest installed.
    Config: Reads doc/process-framework/project-config.json for paths.
#>

[CmdletBinding()]
param(
    [switch]$Unit,
    [switch]$Integration,
    [switch]$Parsers,
    [switch]$Performance,
    [switch]$Critical,
    [switch]$Quick,
    [switch]$All,
    [switch]$Coverage,
    [switch]$Discover,
    [switch]$Lint,
    [switch]$VerboseOutput
)

# --- Resolve project root and config ---
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$projectRoot = (Resolve-Path (Join-Path $scriptDir "../../../..")).Path
$configPath = Join-Path $projectRoot "doc/process-framework/project-config.json"

if (-not (Test-Path $configPath)) {
    Write-Error "project-config.json not found at: $configPath"
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$testDir = $config.paths.tests
$moduleName = $config.project.name.ToLower()

# Resolve test directory relative to project root
$testPath = Join-Path $projectRoot $testDir
if (-not (Test-Path $testPath)) {
    Write-Error "Test directory not found: $testPath"
    exit 1
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
$anyFlag = $Unit -or $Integration -or $Parsers -or $Performance -or $Critical -or $Quick -or $All -or $Coverage -or $Discover -or $Lint
if (-not $anyFlag) { $Quick = $true }

$success = $true

# --- Discovery ---
if ($Discover) {
    $cmd = @("python", "-m", "pytest", "--collect-only", "-q")
    $result = Invoke-TestCommand -Command $cmd -Description "Test Discovery"
    $success = $success -and $result
}

# --- Lint ---
if ($Lint) {
    $cmd = @("python", "-m", "flake8", $testDir, "--max-line-length=100")
    $result = Invoke-TestCommand -Command $cmd -Description "Linting Tests"
    $success = $success -and $result
}

# --- Unit ---
if ($Unit) {
    $cmd = @("python", "-m", "pytest", "$testDir/unit/")
    if ($VerboseOutput) { $cmd += "-v" }
    if ($Coverage) { $cmd += "--cov=$moduleName"; $cmd += "--cov-report=html"; $cmd += "--cov-report=term" }
    $result = Invoke-TestCommand -Command $cmd -Description "Unit Tests"
    $success = $success -and $result
}

# --- Integration ---
if ($Integration) {
    $cmd = @("python", "-m", "pytest", "$testDir/integration/")
    if ($VerboseOutput) { $cmd += "-v" }
    $result = Invoke-TestCommand -Command $cmd -Description "Integration Tests"
    $success = $success -and $result
}

# --- Parsers ---
if ($Parsers) {
    $cmd = @("python", "-m", "pytest", "$testDir/parsers/")
    if ($VerboseOutput) { $cmd += "-v" }
    $result = Invoke-TestCommand -Command $cmd -Description "Parser Tests"
    $success = $success -and $result
}

# --- Performance ---
if ($Performance) {
    $cmd = @("python", "-m", "pytest", "$testDir/performance/", "-m", "slow")
    if ($VerboseOutput) { $cmd += "-v" }
    $result = Invoke-TestCommand -Command $cmd -Description "Performance Tests"
    $success = $success -and $result
}

# --- Critical ---
if ($Critical) {
    $cmd = @("python", "-m", "pytest", "-m", "critical")
    if ($VerboseOutput) { $cmd += "-v" }
    $result = Invoke-TestCommand -Command $cmd -Description "Critical Tests"
    $success = $success -and $result
}

# --- Quick ---
if ($Quick) {
    $cmd = @("python", "-m", "pytest", "$testDir/unit/", "$testDir/parsers/", "-x")
    if ($VerboseOutput) { $cmd += "-v" }
    $result = Invoke-TestCommand -Command $cmd -Description "Quick Tests (unit + parsers)"
    $success = $success -and $result
}

# --- All ---
if ($All) {
    $cmd = @("python", "-m", "pytest", "$testDir/")
    if ($VerboseOutput) { $cmd += "-v" }
    if ($Coverage) { $cmd += "--cov=$moduleName"; $cmd += "--cov-report=html"; $cmd += "--cov-report=term" }
    $cmd += "-m"
    $cmd += "not slow"
    $result = Invoke-TestCommand -Command $cmd -Description "All Tests (excluding slow)"
    $success = $success -and $result
}

# --- Coverage only ---
if ($Coverage -and -not ($Unit -or $All)) {
    $cmd = @("python", "-m", "pytest", "$testDir/", "--cov=$moduleName", "--cov-report=html", "--cov-report=term-missing", "--cov-report=xml")
    $result = Invoke-TestCommand -Command $cmd -Description "Coverage Report Generation"
    $success = $success -and $result

    if ($result) {
        Write-Host ""
        Write-Host ("=" * 60)
        Write-Host "Coverage reports generated:"
        Write-Host "- HTML report: htmlcov/index.html"
        Write-Host "- XML report: coverage.xml"
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
