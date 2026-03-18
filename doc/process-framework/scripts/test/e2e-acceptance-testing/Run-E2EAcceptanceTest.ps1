#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Orchestrates scripted E2E acceptance test execution: Setup → run.ps1 → wait → Verify.

.DESCRIPTION
    Runs the full pipeline for scripted E2E acceptance test cases that have a run.ps1 file:
    1. Setup-TestEnvironment.ps1 — copies pristine fixtures to workspace
    2. run.ps1 — executes the scripted test action
    3. Wait — configurable delay for system propagation (e.g., LinkWatcher file events)
    4. Verify-TestResult.ps1 — compares workspace against expected state

    Test cases without a run.ps1 are skipped with a message suggesting direct execution.

.PARAMETER TestCase
    Optional: Run a single test case by ID (e.g., "E2E-001").
    Requires -Group to be specified.

.PARAMETER Group
    Optional: Run all scripted test cases in a group (e.g., "powershell-regex-preservation").
    If neither -TestCase nor -Group is specified, runs all scripted test cases in all groups.

.PARAMETER WaitSeconds
    Seconds to wait between action execution and verification (default: 5).
    Allows the system under test to process events before checking results.

.PARAMETER Detailed
    Show line-by-line diff for mismatched files (passed to Verify-TestResult.ps1).

.PARAMETER Clean
    Remove existing workspace before setup (passed to Setup-TestEnvironment.ps1).

.PARAMETER ProjectRoot
    Optional: Project root path. Auto-detected if not specified.

.EXAMPLE
    .\Run-E2EAcceptanceTest.ps1 -TestCase "E2E-001" -Group "powershell-regex-preservation"

.EXAMPLE
    .\Run-E2EAcceptanceTest.ps1 -Group "powershell-regex-preservation" -Clean -Detailed

.EXAMPLE
    .\Run-E2EAcceptanceTest.ps1 -WaitSeconds 10

.NOTES
    Test cases must have a run.ps1 file (created via New-E2EAcceptanceTestCase.ps1 -Scripted).
    Test cases without run.ps1 are skipped — execute them directly following test-case.md.

    Created: 2026-03-18
    Version: 1.0
    Task: Process Improvement (PF-TSK-009), PF-IMP-134
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$TestCase = "",

    [Parameter(Mandatory=$false)]
    [string]$Group = "",

    [Parameter(Mandatory=$false)]
    [int]$WaitSeconds = 5,

    [Parameter(Mandatory=$false)]
    [switch]$Detailed,

    [Parameter(Mandatory=$false)]
    [switch]$Clean,

    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = ""
)

# --- Resolve project root ---
if (-not $ProjectRoot) {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir ".git"))) {
        $searchDir = Split-Path $searchDir -Parent
    }
    if (-not $searchDir) {
        Write-Error "Could not auto-detect project root. Use -ProjectRoot parameter."
        exit 1
    }
    $ProjectRoot = $searchDir
}

$templatesDir = Join-Path $ProjectRoot "test/e2e-acceptance-testing/templates"
$workspaceDir = Join-Path $ProjectRoot "test/e2e-acceptance-testing/workspace"
# Validate sibling scripts exist
$setupScript = Join-Path $PSScriptRoot "Setup-TestEnvironment.ps1"
$verifyScript = Join-Path $PSScriptRoot "Verify-TestResult.ps1"

if (-not (Test-Path $setupScript)) {
    Write-Error "Setup-TestEnvironment.ps1 not found at: $setupScript"
    exit 1
}
if (-not (Test-Path $verifyScript)) {
    Write-Error "Verify-TestResult.ps1 not found at: $verifyScript"
    exit 1
}

# --- Collect test cases ---
$testCases = @()

if ($TestCase -and $Group) {
    # Single test case
    $groupDir = Join-Path $templatesDir $Group
    $tcDir = Get-ChildItem $groupDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^$TestCase-" }
    if (-not $tcDir) {
        Write-Error "Test case $TestCase not found in group $Group"
        exit 1
    }
    $testCases += @{ Group = $Group; CaseDir = $tcDir.Name; CaseId = $TestCase; Path = $tcDir.FullName }
} elseif ($Group) {
    # All test cases in a group
    $groupDir = Join-Path $templatesDir $Group
    if (-not (Test-Path $groupDir)) {
        Write-Error "Group not found: $Group"
        exit 1
    }
    $tcDirs = Get-ChildItem $groupDir -Directory | Where-Object { $_.Name -match '^E2E-\d+' }
    foreach ($tc in $tcDirs) {
        $id = ($tc.Name -split '-', 3)[0..1] -join '-'
        $testCases += @{ Group = $Group; CaseDir = $tc.Name; CaseId = $id; Path = $tc.FullName }
    }
} else {
    # All groups, all test cases
    if (-not (Test-Path $templatesDir)) {
        Write-Error "Templates directory not found: $templatesDir"
        exit 1
    }
    $allGroups = Get-ChildItem $templatesDir -Directory
    foreach ($grp in $allGroups) {
        $tcDirs = Get-ChildItem $grp.FullName -Directory | Where-Object { $_.Name -match '^E2E-\d+' }
        foreach ($tc in $tcDirs) {
            $id = ($tc.Name -split '-', 3)[0..1] -join '-'
            $testCases += @{ Group = $grp.Name; CaseDir = $tc.Name; CaseId = $id; Path = $tc.FullName }
        }
    }
}

if ($testCases.Count -eq 0) {
    Write-Warning "No test cases found."
    exit 0
}

# --- Filter to scripted test cases (those with run.ps1) ---
$scriptedCases = @()
$manualCases = @()

foreach ($tc in $testCases) {
    $runScript = Join-Path $tc.Path "run.ps1"
    if (Test-Path $runScript) {
        $scriptedCases += $tc
    } else {
        $manualCases += $tc
    }
}

if ($manualCases.Count -gt 0) {
    Write-Host ""
    Write-Host "Skipping $($manualCases.Count) non-scripted test case(s) (no run.ps1):" -ForegroundColor Yellow
    foreach ($mc in $manualCases) {
        Write-Host "  ⏭️  $($mc.CaseId) ($($mc.Group)) — execute directly via test-case.md" -ForegroundColor Yellow
    }
}

if ($scriptedCases.Count -eq 0) {
    Write-Warning "No scripted test cases found. All test cases require direct execution."
    exit 0
}

Write-Host ""
Write-Host "Running $($scriptedCases.Count) scripted test case(s)..." -ForegroundColor Cyan
Write-Host ""

# --- Execute pipeline for each scripted test case ---
$passed = 0
$failed = 0
$errors = 0

foreach ($tc in $scriptedCases) {
    $runScriptPath = Join-Path $tc.Path "run.ps1"
    $workspaceCasePath = Join-Path $workspaceDir "$($tc.Group)/$($tc.CaseDir)"

    Write-Host "━━━ $($tc.CaseId) ($($tc.Group)/$($tc.CaseDir)) ━━━" -ForegroundColor White

    # Step 1: Setup
    Write-Host "  1️⃣  Setting up test environment..." -ForegroundColor DarkGray
    $setupArgs = @{
        ProjectRoot = $ProjectRoot
    }
    if ($Group) { $setupArgs.Group = $tc.Group }
    if ($Clean) { $setupArgs.Clean = $true }

    try {
        & $setupScript -Group $tc.Group -ProjectRoot $ProjectRoot -Clean:$Clean
    } catch {
        Write-Host "  ❌ Setup failed: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
        continue
    }

    # Verify workspace was created
    $workspaceProjectPath = Join-Path $workspaceCasePath "project"
    if (-not (Test-Path $workspaceProjectPath)) {
        Write-Host "  ❌ Workspace project/ not created after setup" -ForegroundColor Red
        $errors++
        continue
    }

    # Step 2: Execute run.ps1
    Write-Host "  2️⃣  Executing run.ps1..." -ForegroundColor DarkGray
    try {
        & $runScriptPath -WorkspacePath $workspaceCasePath
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            Write-Host "  ❌ run.ps1 exited with code $LASTEXITCODE" -ForegroundColor Red
            $errors++
            continue
        }
    } catch {
        Write-Host "  ❌ run.ps1 failed: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
        continue
    }

    # Step 3: Wait for system propagation
    if ($WaitSeconds -gt 0) {
        Write-Host "  3️⃣  Waiting ${WaitSeconds}s for system propagation..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $WaitSeconds
    }

    # Step 4: Verify
    Write-Host "  4️⃣  Verifying results..." -ForegroundColor DarkGray
    & $verifyScript -TestCase $tc.CaseId -Group $tc.Group -ProjectRoot $ProjectRoot -Detailed:$Detailed

    if ($LASTEXITCODE -eq 0) {
        $passed++
    } else {
        $failed++
    }

    Write-Host ""
}

# --- Summary ---
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Run-E2EAcceptanceTest Summary:" -ForegroundColor Cyan
Write-Host "  ✅ Passed:  $passed" -ForegroundColor Green
Write-Host "  🔴 Failed:  $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "  ❌ Errors:  $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Host "  ⏭️  Skipped: $($manualCases.Count) (non-scripted)" -ForegroundColor Yellow
Write-Host "  Total:     $($testCases.Count)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if ($failed -gt 0 -or $errors -gt 0) {
    exit 1
}
