#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Orchestrates scripted E2E acceptance test execution: Setup -> run.ps1 -> wait -> Verify.

.DESCRIPTION
    Runs the full pipeline for scripted E2E acceptance test cases that have a run.ps1 file:
    1. Setup-TestEnvironment.ps1 — copies pristine fixtures to workspace
    2. run.ps1 — executes the scripted test action
    3. Wait — configurable post-action delay (default: 0s, no wait)
    4. Verify-TestResult.ps1 — compares workspace against expected state

    Test cases without a run.ps1 are skipped with a message suggesting direct execution.

.PARAMETER TestCase
    Optional: Run a single test case by ID (e.g., "E2E-001").
    Requires -Workflow to be specified.

.PARAMETER Workflow
    Optional: Run all scripted test cases in a workflow (e.g., "user-login").
    Matches the workflow directory name under test/e2e-acceptance-testing/.
    If neither -TestCase nor -Workflow is specified, runs all scripted test cases in all workflows.

.PARAMETER WaitSeconds
    Seconds to wait between action execution and verification (default: 0).
    Use when run.ps1 triggers asynchronous effects that need time to settle
    before verification. Pass a positive value (e.g., 12) for test cases
    whose actions produce async side-effects.

.PARAMETER Detailed
    Show line-by-line diff for mismatched files (passed to Verify-TestResult.ps1).

.PARAMETER Clean
    Remove existing workspace before setup (passed to Setup-TestEnvironment.ps1).

.PARAMETER SkipTracking
    Skip automatic tracking updates (Update-TestExecutionStatus.ps1) after each test case.
    By default, tracking is updated automatically with pass/fail results.

.PARAMETER ProjectRoot
    Optional: Project root path. Auto-detected if not specified.

.EXAMPLE
    Run-E2EAcceptanceTest.ps1 -TestCase "E2E-001" -Workflow "user-login"

.EXAMPLE
    Run-E2EAcceptanceTest.ps1 -Workflow "user-login" -Clean -Detailed

.EXAMPLE
    Run-E2EAcceptanceTest.ps1 -WaitSeconds 12

.NOTES
    Test cases must have a run.ps1 file (created via New-E2EAcceptanceTestCase.ps1 -Scripted).
    Test cases without run.ps1 are skipped — execute them directly following test-case.md.

    Created: 2026-03-18
    Version: 2.0
    Updated: 2026-05-28 (PF-IMP-878 — stripped LinkWatcher-specific lifecycle code to make
                        the runner project-agnostic. Stop/Start/restart-LinkWatcher functions,
                        lw_flags/skip_lw_start frontmatter parsing, SettleSeconds parameter,
                        and end-of-run LW restart removed. WaitSeconds default changed from 12
                        to 0. Projects that need tool-specific lifecycle management should
                        handle it in their test cases' run.ps1 scripts.)
    Task: Process Improvement (PF-TSK-009), PF-IMP-134, PF-IMP-154, PF-IMP-169, PF-IMP-395, PF-IMP-472, PF-IMP-720, PF-IMP-724, PF-IMP-871, PF-IMP-878
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [string]$TestCase = "",

    [Parameter(Mandatory=$false)]
    [string]$Workflow = "",

    [Parameter(Mandatory=$false)]
    [int]$WaitSeconds = 0,

    [Parameter(Mandatory=$false)]
    [switch]$Detailed,

    [Parameter(Mandatory=$false)]
    [switch]$Clean,

    [Parameter(Mandatory=$false)]
    [switch]$SkipTracking,

    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = ""
)

# --- Import Common-ScriptHelpers for standardized utilities ---
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "../../../scripts/Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers: $($_.Exception.Message)"
    exit 1
}

# --- Resolve project root ---
if (-not $ProjectRoot) {
    $ProjectRoot = Get-ProjectRoot
    if (-not $ProjectRoot) {
        Write-ProjectError -Message "Could not auto-detect project root. Use -ProjectRoot parameter." -ExitCode 1
    }
}

$baseE2EDir = Join-Path $ProjectRoot "test/e2e-acceptance-testing"
# Per-workflow paths (PF-IMP-871 Phase 3c2): templates/workspace/results live under <workflow>/.
# Test cases live directly under <workflow>/templates/ (no intermediate group layer).

# Validate sibling scripts exist
$setupScript = Join-Path $PSScriptRoot "Setup-TestEnvironment.ps1"
$verifyScript = Join-Path $PSScriptRoot "Verify-TestResult.ps1"
$trackingScript = Join-Path $PSScriptRoot "Update-TestExecutionStatus.ps1"

if (-not (Test-Path $setupScript)) {
    Write-ProjectError -Message "Setup-TestEnvironment.ps1 not found at: $setupScript" -ExitCode 1
}
if (-not (Test-Path $verifyScript)) {
    Write-ProjectError -Message "Verify-TestResult.ps1 not found at: $verifyScript" -ExitCode 1
}

# --- Collect test cases ---
$testCases = @()

if ($TestCase -and $Workflow) {
    # Single test case within a workflow
    $workflowTemplatesDir = Join-Path $baseE2EDir "$Workflow/templates"
    $tcDir = Get-ChildItem $workflowTemplatesDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^$TestCase-" }
    if (-not $tcDir) {
        Write-ProjectError -Message "Test case $TestCase not found in workflow $Workflow" -ExitCode 1
    }
    $testCases += @{ Workflow = $Workflow; CaseDir = $tcDir.Name; CaseId = $TestCase; Path = $tcDir.FullName }
} elseif ($Workflow) {
    # All test cases in a workflow
    $workflowTemplatesDir = Join-Path $baseE2EDir "$Workflow/templates"
    if (-not (Test-Path $workflowTemplatesDir)) {
        Write-ProjectError -Message "Workflow not found: $Workflow (expected templates dir at $workflowTemplatesDir)" -ExitCode 1
    }
    $tcDirs = Get-ChildItem $workflowTemplatesDir -Directory | Where-Object { $_.Name -match '^TE-E2E-\d+' }
    foreach ($tc in $tcDirs) {
        $id = ($tc.Name -split '-', 4)[0..2] -join '-'
        $testCases += @{ Workflow = $Workflow; CaseDir = $tc.Name; CaseId = $id; Path = $tc.FullName }
    }
} else {
    # All workflows, all test cases
    if (-not (Test-Path $baseE2EDir)) {
        Write-ProjectError -Message "E2E acceptance testing root not found: $baseE2EDir" -ExitCode 1
    }
    $allWorkflowDirs = Get-ChildItem $baseE2EDir -Directory
    foreach ($wf in $allWorkflowDirs) {
        $wfTemplatesDir = Join-Path $wf.FullName "templates"
        if (-not (Test-Path $wfTemplatesDir)) { continue }
        $tcDirs = Get-ChildItem $wfTemplatesDir -Directory | Where-Object { $_.Name -match '^TE-E2E-\d+' }
        foreach ($tc in $tcDirs) {
            $id = ($tc.Name -split '-', 4)[0..2] -join '-'
            $testCases += @{ Workflow = $wf.Name; CaseDir = $tc.Name; CaseId = $id; Path = $tc.FullName }
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
        Write-Host "  ⏭️  $($mc.CaseId) ($($mc.Workflow)) — execute directly via test-case.md" -ForegroundColor Yellow
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
    $workspaceCasePath = Join-Path $baseE2EDir "$($tc.Workflow)/workspace/$($tc.CaseDir)"

    Write-Host "━━━ $($tc.CaseId) ($($tc.Workflow)/$($tc.CaseDir)) ━━━" -ForegroundColor White

    # Parse test-case.md frontmatter for expected_exit_code
    $testCaseMd = Join-Path $tc.Path "test-case.md"
    $expectedExitCode = 0
    if (Test-Path $testCaseMd) {
        $tcContent = Get-Content $testCaseMd -Raw -ErrorAction SilentlyContinue
        if ($tcContent -match '(?m)^expected_exit_code:\s*(\d+)') {
            $expectedExitCode = [int]$Matches[1]
        }
    }

    if ($WhatIfPreference) {
        Write-Host "  What if: Would execute E2E pipeline for $($tc.CaseId):" -ForegroundColor Cyan
        Write-Host "    1. Setup-TestEnvironment.ps1 -Workflow $($tc.Workflow) -ProjectRoot $ProjectRoot -Clean:$Clean" -ForegroundColor DarkGray
        $exitCodeMsg = if ($expectedExitCode -ne 0) { " (expected exit code: $expectedExitCode)" } else { "" }
        Write-Host "    2. Execute: $runScriptPath -WorkspacePath $workspaceCasePath${exitCodeMsg}" -ForegroundColor DarkGray
        if ($WaitSeconds -gt 0) {
            Write-Host "    3. Wait ${WaitSeconds}s for propagation" -ForegroundColor DarkGray
        } else {
            Write-Host "    3. No post-action wait" -ForegroundColor DarkGray
        }
        Write-Host "    4. Verify-TestResult.ps1 -TestCase $($tc.CaseId) -Workflow $($tc.Workflow)" -ForegroundColor DarkGray
        if (-not $SkipTracking) {
            Write-Host "    5. Update-TestExecutionStatus.ps1 -TestCase $($tc.CaseId)" -ForegroundColor DarkGray
        }
        $passed++
        Write-Host ""
        continue
    }

    # Step 1: Setup test environment
    Write-Host "  1️⃣  Setting up test environment..." -ForegroundColor DarkGray
    try {
        & $setupScript -Workflow $tc.Workflow -ProjectRoot $ProjectRoot -Clean:$Clean
    } catch {
        Write-ProjectError -Message "Setup failed: $($_.Exception.Message)"
        $errors++
        continue
    }

    # Verify workspace was created
    $workspaceProjectPath = Join-Path $workspaceCasePath "project"
    if (-not (Test-Path $workspaceProjectPath)) {
        Write-ProjectError -Message "Workspace project/ not created after setup"
        $errors++
        continue
    }

    # Step 2: Execute run.ps1
    Write-Host "  2️⃣  Executing run.ps1..." -ForegroundColor DarkGray
    $runFailed = $false
    try {
        $global:LASTEXITCODE = 0
        & $runScriptPath -WorkspacePath $workspaceCasePath
        if ($LASTEXITCODE -ne $expectedExitCode) {
            Write-ProjectError -Message "run.ps1 exited with code $LASTEXITCODE (expected $expectedExitCode)"
            $errors++
            $runFailed = $true
        }
    } catch {
        Write-ProjectError -Message "run.ps1 failed: $($_.Exception.Message)"
        $errors++
        $runFailed = $true
    }
    if ($runFailed) {
        continue
    }

    # Step 3: Wait for post-action propagation (if configured)
    if ($WaitSeconds -gt 0) {
        Write-Host "  3️⃣  Waiting ${WaitSeconds}s for propagation..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $WaitSeconds
    }

    # Step 4: Verify
    Write-Host "  4️⃣  Verifying results..." -ForegroundColor DarkGray
    & $verifyScript -TestCase $tc.CaseId -Workflow $tc.Workflow -ProjectRoot $ProjectRoot -Detailed:$Detailed

    if ($LASTEXITCODE -eq 0) {
        $passed++
        $tcStatus = "Passed"
    } else {
        $failed++
        $tcStatus = "Failed"
    }

    # Step 5: Update tracking files
    if (-not $SkipTracking -and (Test-Path $trackingScript)) {
        Write-Host "  5️⃣  Updating tracking ($tcStatus)..." -ForegroundColor DarkGray
        try {
            & $trackingScript -TestCase $tc.CaseId -Status $tcStatus -ProjectRoot $ProjectRoot
        } catch {
            Write-Host "  ⚠️  Tracking update failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
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
