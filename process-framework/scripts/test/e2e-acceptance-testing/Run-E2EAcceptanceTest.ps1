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
    Seconds to wait between action execution and verification (default: 12).
    Must exceed move_detect_delay (10s) plus processing buffer to avoid
    premature verification. Allows the system under test to process events
    before checking results.

.PARAMETER SettleSeconds
    Seconds to wait after LinkWatcher initial scan completes before executing
    the test action (default: 3). Allows LinkWatcher to finish indexing all
    links after file discovery.

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
    Run-E2EAcceptanceTest.ps1 -TestCase "E2E-001" -Group "powershell-regex-preservation"

.EXAMPLE
    Run-E2EAcceptanceTest.ps1 -Group "powershell-regex-preservation" -Clean -Detailed

.EXAMPLE
    Run-E2EAcceptanceTest.ps1 -WaitSeconds 10

.NOTES
    Test cases must have a run.ps1 file (created via New-E2EAcceptanceTestCase.ps1 -Scripted).
    Test cases without run.ps1 are skipped — execute them directly following test-case.md.

    Created: 2026-03-18
    Version: 1.6
    Task: Process Improvement (PF-TSK-009), PF-IMP-134, PF-IMP-154, PF-IMP-169, PF-IMP-395, PF-IMP-472, PF-IMP-720, PF-IMP-724
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [string]$TestCase = "",

    [Parameter(Mandatory=$false)]
    [string]$Group = "",

    [Parameter(Mandatory=$false)]
    [int]$WaitSeconds = 12,

    [Parameter(Mandatory=$false)]
    [int]$SettleSeconds = 3,

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

$templatesDir = Join-Path $ProjectRoot "test/e2e-acceptance-testing/templates"
$workspaceDir = Join-Path $ProjectRoot "test/e2e-acceptance-testing/workspace"
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

if ($TestCase -and $Group) {
    # Single test case
    $groupDir = Join-Path $templatesDir $Group
    $tcDir = Get-ChildItem $groupDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^$TestCase-" }
    if (-not $tcDir) {
        Write-ProjectError -Message "Test case $TestCase not found in group $Group" -ExitCode 1
    }
    $testCases += @{ Group = $Group; CaseDir = $tcDir.Name; CaseId = $TestCase; Path = $tcDir.FullName }
} elseif ($Group) {
    # All test cases in a group
    $groupDir = Join-Path $templatesDir $Group
    if (-not (Test-Path $groupDir)) {
        Write-ProjectError -Message "Group not found: $Group" -ExitCode 1
    }
    $tcDirs = Get-ChildItem $groupDir -Directory | Where-Object { $_.Name -match '^TE-E2E-\d+' }
    foreach ($tc in $tcDirs) {
        $id = ($tc.Name -split '-', 4)[0..2] -join '-'
        $testCases += @{ Group = $Group; CaseDir = $tc.Name; CaseId = $id; Path = $tc.FullName }
    }
} else {
    # All groups, all test cases
    if (-not (Test-Path $templatesDir)) {
        Write-ProjectError -Message "Templates directory not found: $templatesDir" -ExitCode 1
    }
    $allGroups = Get-ChildItem $templatesDir -Directory
    foreach ($grp in $allGroups) {
        $tcDirs = Get-ChildItem $grp.FullName -Directory | Where-Object { $_.Name -match '^TE-E2E-\d+' }
        foreach ($tc in $tcDirs) {
            $id = ($tc.Name -split '-', 4)[0..2] -join '-'
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

# --- Helper: Stop LinkWatcher ---
$projectLockFile = Join-Path $ProjectRoot ".linkwatcher.lock"

function Stop-LinkWatcher {
    param(
        [Parameter(Mandatory=$false)]
        [string]$LockPath = $projectLockFile
    )
    if (Test-Path $LockPath) {
        try {
            $lwPid = [int](Get-Content $LockPath -Raw).Trim()
            $lwProc = Get-Process -Id $lwPid -ErrorAction SilentlyContinue
            if ($lwProc) {
                Stop-Process -Id $lwPid -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 500
                Write-Host "  🛑 Stopped LinkWatcher (PID: $lwPid)" -ForegroundColor DarkYellow
            }
        } catch {
            Write-Host "  ⚠️  Could not stop LinkWatcher: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        Remove-Item $LockPath -Force -ErrorAction SilentlyContinue
    }
}

function Stop-WorkspaceLinkWatchers {
    # Sweep stray LinkWatcher processes left running under the workspace by prior test
    # cases — particularly skip_lw_start cases whose run.ps1 starts LW scoped to a
    # subdirectory (e.g., workspace/<group>/<case>/project/), placing the lock file
    # outside the two paths that Stop-LinkWatcher checks. Without this sweep, the
    # next case's Setup-TestEnvironment.ps1 fails to clean the prior workspace
    # because the stray LW still holds it (PF-IMP-720, real failure: TE-E2E-015
    # setup blocked by TE-E2E-012's stray LW per PF-FEE-1088).
    param(
        [Parameter(Mandatory=$true)]
        [string]$Root
    )
    if (-not (Test-Path $Root)) { return }
    $locks = Get-ChildItem -Path $Root -Recurse -Force -Filter ".linkwatcher.lock" -File -ErrorAction SilentlyContinue
    foreach ($lock in $locks) {
        Stop-LinkWatcher -LockPath $lock.FullName
    }
}

function Start-LinkWatcher {
    param(
        [Parameter(Mandatory=$true)]
        [string]$WatchPath,
        [int]$MaxWaitSeconds = 30,
        [int]$SettleDelay = 3,
        [string]$LwFlags = ""
    )

    # Start LinkWatcher scoped to the workspace directory (not full project)
    $mainPy = Join-Path $ProjectRoot "main.py"
    $logFile = Join-Path $WatchPath "linkwatcher-e2e.log"
    $arguments = "`"$mainPy`" --project-root `"$WatchPath`" --log-file `"$logFile`" --debug"

    # Resolve <workspace> placeholder and append any extra flags from test-case.md
    if ($LwFlags -ne "") {
        $resolvedFlags = $LwFlags -replace '<workspace>', $WatchPath
        $arguments += " $resolvedFlags"
    }

    $lwProcess = Start-Process -FilePath "python" -ArgumentList $arguments -WorkingDirectory $WatchPath -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $WatchPath "lw-stdout.txt") -RedirectStandardError (Join-Path $WatchPath "lw-stderr.txt")

    if (-not $lwProcess) {
        Write-ProjectError -Message "Failed to start LinkWatcher"
        return
    }
    $flagsLabel = if ($LwFlags -ne "") { ", flags: $LwFlags" } else { "" }
    Write-Host "  ▶️  LinkWatcher started scoped to workspace (PID: $($lwProcess.Id)${flagsLabel})" -ForegroundColor DarkGray

    # Wait for initial scan to complete by polling the log file
    $startTime = Get-Date
    $scanComplete = $false

    Write-Host "  ⏳ Waiting for initial scan to complete (max ${MaxWaitSeconds}s)..." -ForegroundColor DarkGray
    while (-not $scanComplete -and ((Get-Date) - $startTime).TotalSeconds -lt $MaxWaitSeconds) {
        Start-Sleep -Seconds 1
        if (Test-Path $logFile) {
            $recentLines = Get-Content $logFile -Tail 20 -ErrorAction SilentlyContinue
            if ($recentLines -match 'initial_scan_complete') {
                $scanComplete = $true
            }
        }
    }

    if ($scanComplete) {
        $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
        Write-Host "  ✅ Initial scan completed in ${elapsed}s" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Scan wait timed out after ${MaxWaitSeconds}s — proceeding anyway" -ForegroundColor Yellow
    }

    # Settling delay: let LinkWatcher finish indexing links after file discovery
    if ($SettleDelay -gt 0) {
        Write-Host "  ⏳ Settling ${SettleDelay}s for link indexing..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $SettleDelay
    }
}

foreach ($tc in $scriptedCases) {
    $runScriptPath = Join-Path $tc.Path "run.ps1"
    $workspaceCasePath = Join-Path $workspaceDir "$($tc.Group)/$($tc.CaseDir)"

    Write-Host "━━━ $($tc.CaseId) ($($tc.Group)/$($tc.CaseDir)) ━━━" -ForegroundColor White

    # Parse test-case.md frontmatter for lw_flags, skip_lw_start, expected_exit_code
    $testCaseMd = Join-Path $tc.Path "test-case.md"
    $lwFlags = ""
    $skipLwStart = $false
    $expectedExitCode = 0
    if (Test-Path $testCaseMd) {
        $tcContent = Get-Content $testCaseMd -Raw -ErrorAction SilentlyContinue
        if ($tcContent -match '(?m)^lw_flags:\s*"([^"]*)"') {
            $lwFlags = $Matches[1]
        }
        if ($tcContent -match '(?m)^skip_lw_start:\s*true') {
            $skipLwStart = $true
        }
        if ($tcContent -match '(?m)^expected_exit_code:\s*(\d+)') {
            $expectedExitCode = [int]$Matches[1]
        }
    }

    if ($WhatIfPreference) {
        Write-Host "  What if: Would execute E2E pipeline for $($tc.CaseId):" -ForegroundColor Cyan
        Write-Host "    1. Stop LinkWatcher (project lock, current case lock, and recursive workspace sweep)" -ForegroundColor DarkGray
        Write-Host "    2. Setup-TestEnvironment.ps1 -Group $($tc.Group) -ProjectRoot $ProjectRoot -Clean:$Clean" -ForegroundColor DarkGray
        if ($skipLwStart) {
            Write-Host "    3. Skip LinkWatcher start (skip_lw_start)" -ForegroundColor DarkYellow
        } else {
            $flagsMsg = if ($lwFlags -ne "") { " with flags: $lwFlags" } else { "" }
            Write-Host "    3. Start LinkWatcher (workspace-scoped${flagsMsg})" -ForegroundColor DarkGray
        }
        $exitCodeMsg = if ($expectedExitCode -ne 0) { " (expected exit code: $expectedExitCode)" } else { "" }
        Write-Host "    4. Execute: $runScriptPath -WorkspacePath $workspaceCasePath${exitCodeMsg}" -ForegroundColor DarkGray
        Write-Host "    5. Wait ${WaitSeconds}s for propagation" -ForegroundColor DarkGray
        Write-Host "    6. Verify-TestResult.ps1 -TestCase $($tc.CaseId) -Group $($tc.Group)" -ForegroundColor DarkGray
        if (-not $SkipTracking) {
            Write-Host "    7. Update-TestExecutionStatus.ps1 -TestCase $($tc.CaseId)" -ForegroundColor DarkGray
        }
        Write-Host "    8. Stop LinkWatcher + cleanup" -ForegroundColor DarkGray
        $passed++
        Write-Host ""
        continue
    }

    # Step 1: Stop any running LinkWatcher (project-level or previous workspace-scoped)
    Write-Host "  1️⃣  Stopping LinkWatcher for clean setup..." -ForegroundColor DarkGray
    Stop-LinkWatcher -LockPath $projectLockFile
    $workspaceLockFile = Join-Path $workspaceCasePath ".linkwatcher.lock"
    Stop-LinkWatcher -LockPath $workspaceLockFile
    # Sweep stray LWs left under the workspace by prior cases — covers skip_lw_start
    # cases whose lock lands in an arbitrary subdirectory (PF-IMP-720)
    Stop-WorkspaceLinkWatchers -Root $workspaceDir

    # Step 2: Setup test environment (no LW running = no false move events)
    Write-Host "  2️⃣  Setting up test environment..." -ForegroundColor DarkGray
    try {
        & $setupScript -Group $tc.Group -ProjectRoot $ProjectRoot -Clean:$Clean
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

    # Step 3: Start LinkWatcher scoped to workspace (not full project)
    # Skipped when test-case.md sets skip_lw_start: true (test manages its own LW lifecycle)
    if ($skipLwStart) {
        Write-Host "  3️⃣  Skipping LinkWatcher start (skip_lw_start — test manages own LW)" -ForegroundColor DarkYellow
    } else {
        $flagsMsg = if ($lwFlags -ne "") { " with flags: $lwFlags" } else { "" }
        Write-Host "  3️⃣  Starting LinkWatcher (workspace-scoped${flagsMsg})..." -ForegroundColor DarkGray
        Start-LinkWatcher -WatchPath $workspaceCasePath -SettleDelay $SettleSeconds -LwFlags $lwFlags
    }

    # Step 4: Execute run.ps1
    Write-Host "  4️⃣  Executing run.ps1..." -ForegroundColor DarkGray
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
        Stop-LinkWatcher -LockPath $workspaceLockFile
        continue
    }

    # Step 5: Wait for system propagation
    if ($WaitSeconds -gt 0) {
        Write-Host "  5️⃣  Waiting ${WaitSeconds}s for system propagation..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $WaitSeconds
    }

    # Step 6: Verify
    Write-Host "  6️⃣  Verifying results..." -ForegroundColor DarkGray
    & $verifyScript -TestCase $tc.CaseId -Group $tc.Group -ProjectRoot $ProjectRoot -Detailed:$Detailed

    if ($LASTEXITCODE -eq 0) {
        $passed++
        $tcStatus = "Passed"
    } else {
        $failed++
        $tcStatus = "Failed"
    }

    # Step 7: Update tracking files
    if (-not $SkipTracking -and (Test-Path $trackingScript)) {
        Write-Host "  7️⃣  Updating tracking ($tcStatus)..." -ForegroundColor DarkGray
        try {
            & $trackingScript -TestCase $tc.CaseId -Status $tcStatus -ProjectRoot $ProjectRoot
        } catch {
            Write-Host "  ⚠️  Tracking update failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # Step 8: Stop LinkWatcher (workspace-scoped or project-level if run.ps1 restarted it)
    # Always stop — even when skip_lw_start, run.ps1 may have started its own LW instance
    Stop-LinkWatcher -LockPath $workspaceLockFile
    Stop-LinkWatcher -LockPath $projectLockFile
    Remove-Item (Join-Path $workspaceCasePath "linkwatcher-e2e.log") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $workspaceCasePath "lw-stdout.txt") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $workspaceCasePath "lw-stderr.txt") -Force -ErrorAction SilentlyContinue

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

# Restart project-level LinkWatcher (was stopped for E2E testing)
$startLwScript = Join-Path $ProjectRoot "process-framework/tools/linkWatcher/start_linkwatcher_background.ps1"
if (Test-Path $startLwScript) {
    Write-Host "Restarting project-level LinkWatcher..." -ForegroundColor Cyan
    & $startLwScript
}

if ($failed -gt 0 -or $errors -gt 0) {
    exit 1
}
