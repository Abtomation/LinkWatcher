#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Compares workspace state against expected state after manual test execution.

.DESCRIPTION
    For each test case, compares files in workspace/<group>/<test-case>/project/
    against templates/<group>/<test-case>/expected/. Reports per-file match/mismatch
    with optional detailed diff output.

.PARAMETER TestCase
    Optional: Verify a single test case by ID (e.g., "MT-001").

.PARAMETER Group
    Optional: Verify all test cases in a group (e.g., "basic-file-operations").
    If neither -TestCase nor -Group is specified, verifies all groups.

.PARAMETER Detailed
    Optional: Show line-by-line diff for mismatched files.

.PARAMETER ProjectRoot
    Optional: Project root path. Auto-detected if not specified.

.EXAMPLE
    .\Verify-TestResult.ps1 -Group "basic-file-operations"

.EXAMPLE
    .\Verify-TestResult.ps1 -TestCase "MT-001" -Group "basic-file-operations" -Detailed

.NOTES
    Created: 2026-03-15
    Version: 1.0
    Task: Manual Test Execution (PF-TSK-070)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$TestCase = "",

    [Parameter(Mandatory=$false)]
    [string]$Group = "",

    [Parameter(Mandatory=$false)]
    [switch]$Detailed,

    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = ""
)

# Resolve project root
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

$templatesDir = Join-Path $ProjectRoot "test/manual-testing/templates"
$workspaceDir = Join-Path $ProjectRoot "test/manual-testing/workspace"

if (-not (Test-Path $workspaceDir)) {
    Write-Error "Workspace directory not found: $workspaceDir. Run Setup-TestEnvironment.ps1 first."
    exit 1
}

# Collect test cases to verify
$testCasesToVerify = @()

if ($TestCase -and $Group) {
    # Single test case in a specific group
    $tcDir = Get-ChildItem (Join-Path $templatesDir $Group) -Directory | Where-Object { $_.Name -match "^$TestCase-" }
    if ($tcDir) {
        $testCasesToVerify += @{ Group = $Group; CaseDir = $tcDir.Name; CaseId = $TestCase }
    } else {
        Write-Error "Test case $TestCase not found in group $Group"
        exit 1
    }
} elseif ($Group) {
    # All test cases in a group
    $tcDirs = Get-ChildItem (Join-Path $templatesDir $Group) -Directory | Where-Object { $_.Name -match '^MT-\d+' }
    foreach ($tc in $tcDirs) {
        $id = ($tc.Name -split '-', 3)[0..1] -join '-'
        $testCasesToVerify += @{ Group = $Group; CaseDir = $tc.Name; CaseId = $id }
    }
} else {
    # All groups, all test cases
    $allGroups = Get-ChildItem $templatesDir -Directory
    foreach ($grp in $allGroups) {
        $tcDirs = Get-ChildItem $grp.FullName -Directory | Where-Object { $_.Name -match '^MT-\d+' }
        foreach ($tc in $tcDirs) {
            $id = ($tc.Name -split '-', 3)[0..1] -join '-'
            $testCasesToVerify += @{ Group = $grp.Name; CaseDir = $tc.Name; CaseId = $id }
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
    $expectedDir = Join-Path $templatesDir "$($tc.Group)/$($tc.CaseDir)/expected"
    $workspaceProjDir = Join-Path $workspaceDir "$($tc.Group)/$($tc.CaseDir)/project"

    if (-not (Test-Path $expectedDir)) {
        Write-Host "  ⬜ $($tc.CaseId): No expected/ directory — skipped" -ForegroundColor Gray
        $skipped++
        continue
    }

    if (-not (Test-Path $workspaceProjDir)) {
        Write-Host "  ❌ $($tc.CaseId): Workspace project/ not found — not set up?" -ForegroundColor Red
        $failed++
        continue
    }

    # Compare all files in expected/ against workspace/project/
    $expectedFiles = Get-ChildItem $expectedDir -Recurse -File
    $casePassed = $true

    foreach ($expFile in $expectedFiles) {
        $relativePath = $expFile.FullName.Substring($expectedDir.Length + 1)
        $workspaceFile = Join-Path $workspaceProjDir $relativePath

        if (-not (Test-Path $workspaceFile)) {
            Write-Host "  🔴 $($tc.CaseId): Missing file: $relativePath" -ForegroundColor Red
            $casePassed = $false
            continue
        }

        $expContent = Get-Content $expFile.FullName -Raw -Encoding UTF8
        $wsContent = Get-Content $workspaceFile -Raw -Encoding UTF8

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
        Write-Host "  ✅ $($tc.CaseId): All files match expected state" -ForegroundColor Green
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
