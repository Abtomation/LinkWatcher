#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Compares workspace state against expected state after E2E acceptance test execution.

.DESCRIPTION
    For each test case, compares files in <workflow>/workspace/<test-case>/project/
    against <workflow>/templates/<test-case>/expected/. Reports per-file match/mismatch
    with optional detailed diff output. Test cases live directly under <workflow>/templates/
    (no intermediate group layer — PF-IMP-871 Phase 3c2).

.PARAMETER TestCase
    Optional: Verify a single test case by ID (e.g., "E2E-001").

.PARAMETER Workflow
    Optional: Verify all test cases in a workflow (e.g., "user-login").
    Matches the workflow directory name under test/e2e-acceptance-testing/.
    If neither -TestCase nor -Workflow is specified, verifies all workflows.

.PARAMETER Detailed
    Optional: Show line-by-line diff for mismatched files.

.PARAMETER ProjectRoot
    Optional: Project root path. Auto-detected if not specified.

.EXAMPLE
    Verify-TestResult.ps1 -Workflow "user-login"

.EXAMPLE
    Verify-TestResult.ps1 -TestCase "E2E-001" -Workflow "user-login" -Detailed

.NOTES
    Created: 2026-03-15
    Version: 1.1
    Updated: 2026-05-14 (PF-IMP-871 Phase 3c2 — per-workflow paths: `-Group` renamed to `-Workflow`;
                        templates/workspace live under `<workflow>/`)
    Task: E2E Acceptance Test Execution (PF-TSK-070), PF-IMP-871
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$TestCase = "",

    [Parameter(Mandatory=$false)]
    [string]$Workflow = "",

    [Parameter(Mandatory=$false)]
    [switch]$Detailed,

    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = ""
)

# Import Common-ScriptHelpers for standardized utilities
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "../../../scripts/Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers: $($_.Exception.Message)"
    exit 1
}

# Resolve project root
if (-not $ProjectRoot) {
    $ProjectRoot = Get-ProjectRoot
    if (-not $ProjectRoot) {
        Write-ProjectError -Message "Could not auto-detect project root. Use -ProjectRoot parameter." -ExitCode 1
    }
}

$baseE2EDir = Join-Path $ProjectRoot "test/e2e-acceptance-testing"

if (-not (Test-Path $baseE2EDir)) {
    Write-ProjectError -Message "E2E acceptance testing root not found: $baseE2EDir. Run Setup-TestEnvironment.ps1 first." -ExitCode 1
}

# Collect test cases to verify
$testCasesToVerify = @()

if ($TestCase -and $Workflow) {
    # Single test case in a specific workflow
    $workflowTemplates = Join-Path $baseE2EDir "$Workflow/templates"
    $tcDir = Get-ChildItem $workflowTemplates -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^$TestCase-" }
    if ($tcDir) {
        $testCasesToVerify += @{ Workflow = $Workflow; CaseDir = $tcDir.Name; CaseId = $TestCase }
    } else {
        Write-ProjectError -Message "Test case $TestCase not found in workflow $Workflow" -ExitCode 1
    }
} elseif ($Workflow) {
    # All test cases in a workflow
    $workflowTemplates = Join-Path $baseE2EDir "$Workflow/templates"
    if (-not (Test-Path $workflowTemplates)) {
        Write-ProjectError -Message "Workflow not found: $Workflow (expected templates dir at $workflowTemplates)" -ExitCode 1
    }
    $tcDirs = Get-ChildItem $workflowTemplates -Directory | Where-Object { $_.Name -match '^TE-E2E-\d+' }
    foreach ($tc in $tcDirs) {
        $id = ($tc.Name -split '-', 4)[0..2] -join '-'
        $testCasesToVerify += @{ Workflow = $Workflow; CaseDir = $tc.Name; CaseId = $id }
    }
} else {
    # All workflows, all test cases
    $allWorkflowDirs = Get-ChildItem $baseE2EDir -Directory
    foreach ($wf in $allWorkflowDirs) {
        $wfTemplates = Join-Path $wf.FullName "templates"
        if (-not (Test-Path $wfTemplates)) { continue }
        $tcDirs = Get-ChildItem $wfTemplates -Directory | Where-Object { $_.Name -match '^TE-E2E-\d+' }
        foreach ($tc in $tcDirs) {
            $id = ($tc.Name -split '-', 4)[0..2] -join '-'
            $testCasesToVerify += @{ Workflow = $wf.Name; CaseDir = $tc.Name; CaseId = $id }
        }
    }
}

if ($testCasesToVerify.Count -eq 0) {
    Write-Warning "No test cases found to verify."
    exit 0
}

# Verify each test case
$passed = 0
$failed = 0
$skipped = 0

foreach ($tc in $testCasesToVerify) {
    $expectedDir = Join-Path $baseE2EDir "$($tc.Workflow)/templates/$($tc.CaseDir)/expected"
    $workspaceProjDir = Join-Path $baseE2EDir "$($tc.Workflow)/workspace/$($tc.CaseDir)/project"

    if (-not (Test-Path $expectedDir)) {
        Write-Host "  ⬜ $($tc.CaseId): No expected/ directory — skipped" -ForegroundColor Gray
        $skipped++
        continue
    }

    if (-not (Test-Path $workspaceProjDir)) {
        Write-ProjectError -Message "$($tc.CaseId): Workspace project/ not found — not set up?"
        $failed++
        continue
    }

    # Compare all files in expected/ against workspace/project/
    $expectedFiles = Get-ChildItem $expectedDir -Recurse -File
    $casePassed = $true

    foreach ($expFile in $expectedFiles) {
        $relativePath = $expFile.FullName.Substring($expectedDir.Length + 1)
        $workspaceFile = Join-Path $workspaceProjDir $relativePath

        if (-not (Test-Path -LiteralPath $workspaceFile)) {
            Write-Host "  🔴 $($tc.CaseId): Missing file: $relativePath" -ForegroundColor Red
            $casePassed = $false
            continue
        }

        $expContent = [string](Get-Content -LiteralPath $expFile.FullName -Raw -Encoding UTF8) -replace '\r\n', "`n"
        $wsContent = [string](Get-Content -LiteralPath $workspaceFile -Raw -Encoding UTF8) -replace '\r\n', "`n"

        # Normalize trailing whitespace (PowerShell Set-Content may add extra newline)
        $expContent = $expContent.TrimEnd()
        $wsContent = $wsContent.TrimEnd()

        if ($expContent -ne $wsContent) {
            Write-Host "  🔴 $($tc.CaseId): Mismatch: $relativePath" -ForegroundColor Red
            $casePassed = $false

            if ($Detailed) {
                # Show simple diff
                $expLines = $expContent -split '\r?\n'
                $wsLines = $wsContent -split '\r?\n'
                $maxLines = [Math]::Max($expLines.Count, $wsLines.Count)

                for ($i = 0; $i -lt $maxLines; $i++) {
                    $expLine = if ($i -lt $expLines.Count) { $expLines[$i] } else { "<EOF>" }
                    $wsLine = if ($i -lt $wsLines.Count) { $wsLines[$i] } else { "<EOF>" }

                    if ($expLine -ne $wsLine) {
                        Write-Host "    Line $($i + 1):" -ForegroundColor DarkGray
                        Write-Host "      Expected: $expLine" -ForegroundColor Green
                        Write-Host "      Actual:   $wsLine" -ForegroundColor Red
                    }
                }
            }
        }
    }

    if ($casePassed) {
        Write-ProjectSuccess -Message "$($tc.CaseId): All files match expected state"
        $passed++
    } else {
        $failed++
    }
}

# Summary
Write-Host ""
Write-Host "Verification Summary:" -ForegroundColor Cyan
Write-Host "  ✅ Passed:  $passed" -ForegroundColor Green
Write-Host "  🔴 Failed:  $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "  ⬜ Skipped: $skipped" -ForegroundColor Gray
Write-Host "  Total:     $($testCasesToVerify.Count)" -ForegroundColor Cyan

if ($failed -gt 0) {
    exit 1
}

exit 0
