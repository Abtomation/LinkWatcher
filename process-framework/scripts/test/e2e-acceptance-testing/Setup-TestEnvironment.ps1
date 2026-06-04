#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Sets up the E2E acceptance test execution environment by copying pristine fixtures into workspace.

.DESCRIPTION
    Copies test case fixtures from test/e2e-acceptance-testing/<workflow>/templates/ into
    test/e2e-acceptance-testing/<workflow>/workspace/ for a clean test execution environment.
    Each execution should start from pristine fixtures. Test cases live directly under
    <workflow>/templates/ (no intermediate group layer — PF-IMP-871 Phase 3c2).

.PARAMETER Workflow
    Optional: Only set up a specific workflow (e.g., "user-login"). Matches the workflow
    directory name under test/e2e-acceptance-testing/. If omitted, sets up all workflows.

.PARAMETER Clean
    Optional: Remove existing workspace contents before copying. Recommended for re-execution.

.PARAMETER ProjectRoot
    Optional: Project root path. Auto-detected if not specified.

.EXAMPLE
    Setup-TestEnvironment.ps1 -Workflow "user-login" -Clean

.EXAMPLE
    Setup-TestEnvironment.ps1 -Clean

.NOTES
    Created: 2026-03-15
    Version: 1.1
    Updated: 2026-05-14 (PF-IMP-871 Phase 3c2 — per-workflow paths: `-Group` renamed to `-Workflow`;
                        templates/workspace live under `<workflow>/`)
    Task: E2E Acceptance Test Execution (PF-TSK-070), PF-IMP-871
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$Workflow = "",

    [Parameter(Mandatory=$false)]
    [switch]$Clean,

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

function Invoke-RemoveItemWithRetry {
    # Retries Remove-Item on transient file-lock errors. The previous test case's
    # workspace-scoped LinkWatcher is Stop-Process -Force'd by Run-E2EAcceptanceTest.ps1,
    # but Windows releases file handles asynchronously after process exit (PF-IMP-676).
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [int]$MaxAttempts = 3,
        [int[]]$DelayMs = @(500, 1000, 2000)
    )

    if (-not (Test-Path $Path)) { return }

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            Remove-Item $Path -Recurse -Force -ErrorAction Stop
            return
        } catch [System.IO.IOException], [System.UnauthorizedAccessException] {
            if ($attempt -ge $MaxAttempts) { throw }
            $delay = $DelayMs[[Math]::Min($attempt - 1, $DelayMs.Count - 1)]
            Write-Verbose "Remove-Item retry $attempt/$MaxAttempts on $Path (waiting ${delay}ms)"
            Start-Sleep -Milliseconds $delay
        }
    }
}

# Resolve project root
if (-not $ProjectRoot) {
    $ProjectRoot = Get-ProjectRoot
    if (-not $ProjectRoot) {
        Write-ProjectError -Message "Could not auto-detect project root. Use -ProjectRoot parameter." -ExitCode 1
    }
}

$baseE2EDir = Join-Path $ProjectRoot "test/e2e-acceptance-testing"

# Validate e2e-acceptance-testing root exists
if (-not (Test-Path $baseE2EDir)) {
    Write-ProjectError -Message "E2E acceptance testing root not found: $baseE2EDir" -ExitCode 1
}

# Determine which workflows to set up
$workflows = @()
if ($Workflow) {
    $workflowTemplatesPath = Join-Path $baseE2EDir "$Workflow/templates"
    if (-not (Test-Path $workflowTemplatesPath)) {
        Write-ProjectError -Message "Workflow templates dir not found: $workflowTemplatesPath" -ExitCode 1
    }
    $workflows += $Workflow
} else {
    # Discover workflows: top-level dirs under baseE2EDir that contain a templates/ subdir
    $candidates = Get-ChildItem $baseE2EDir -Directory
    foreach ($cand in $candidates) {
        if (Test-Path (Join-Path $cand.FullName "templates")) {
            $workflows += $cand.Name
        }
    }
    if ($workflows.Count -eq 0) {
        Write-Warning "No workflows found under $baseE2EDir (expected <workflow>/templates/ subdirs)"
        exit 0
    }
}

# Copy fixtures for each workflow
$totalCases = 0
foreach ($wf in $workflows) {
    $srcTemplates = Join-Path $baseE2EDir "$wf/templates"
    $dstWorkspace = Join-Path $baseE2EDir "$wf/workspace"

    # Clean per-workflow workspace if requested
    if ($Clean -and (Test-Path $dstWorkspace)) {
        if ($PSCmdlet.ShouldProcess($dstWorkspace, "Remove workspace for workflow $wf")) {
            Invoke-RemoveItemWithRetry -Path $dstWorkspace
            Write-Host "  Cleaned workspace for workflow: $wf" -ForegroundColor Yellow
        }
    }

    if (-not (Test-Path $dstWorkspace)) {
        New-Item -ItemType Directory -Path $dstWorkspace -Force | Out-Null
    }

    # Find all test case directories (TE-E2E-NNN-*) directly under <workflow>/templates/
    $testCases = Get-ChildItem $srcTemplates -Directory | Where-Object { $_.Name -match '^TE-E2E-\d+' }

    foreach ($tc in $testCases) {
        $srcProject = Join-Path $tc.FullName "project"
        $dstCase = Join-Path $dstWorkspace $tc.Name
        $dstProject = Join-Path $dstCase "project"

        if (Test-Path $srcProject) {
            if ($PSCmdlet.ShouldProcess($dstProject, "Copy fixtures for $($tc.Name)")) {
                if (-not (Test-Path $dstCase)) {
                    New-Item -ItemType Directory -Path $dstCase -Force | Out-Null
                }
                Invoke-RemoveItemWithRetry -Path $dstProject
                Copy-Item $srcProject $dstProject -Recurse -Force
                $totalCases++
            }
        }
    }

    Write-ProjectSuccess -Message "Set up workflow: $wf ($($testCases.Count) test cases)"
}

Write-Host ""
Write-Host "Test environment ready:" -ForegroundColor Cyan
Write-Host "  Workflows: $($workflows.Count)" -ForegroundColor Cyan
Write-Host "  Test cases: $totalCases" -ForegroundColor Cyan
Write-Host "  E2E root: $baseE2EDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next: Execute test cases following the master test or individual test-case.md files." -ForegroundColor Yellow
