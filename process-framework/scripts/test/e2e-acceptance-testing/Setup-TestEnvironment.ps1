#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Sets up the E2E acceptance test execution environment by copying pristine fixtures into workspace.

.DESCRIPTION
    Copies test case fixtures from test/e2e-acceptance-testing/templates/ into test/e2e-acceptance-testing/workspace/
    for a clean test execution environment. Each execution should start from pristine fixtures.

.PARAMETER Group
    Optional: Only set up a specific test group (e.g., "basic-file-operations").
    If omitted, sets up all groups.

.PARAMETER Clean
    Optional: Remove existing workspace contents before copying. Recommended for re-execution.

.PARAMETER ProjectRoot
    Optional: Project root path. Auto-detected if not specified.

.EXAMPLE
    Setup-TestEnvironment.ps1 -Group "basic-file-operations" -Clean

.EXAMPLE
    Setup-TestEnvironment.ps1 -Clean

.NOTES
    Created: 2026-03-15
    Version: 1.0
    Task: E2E Acceptance Test Execution (PF-TSK-070)
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$Group = "",

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

# Resolve project root
if (-not $ProjectRoot) {
    $ProjectRoot = Get-ProjectRoot
    if (-not $ProjectRoot) {
        Write-ProjectError -Message "Could not auto-detect project root. Use -ProjectRoot parameter." -ExitCode 1
    }
}

$templatesDir = Join-Path $ProjectRoot "test/e2e-acceptance-testing/templates"
$workspaceDir = Join-Path $ProjectRoot "test/e2e-acceptance-testing/workspace"

# Validate templates directory exists
if (-not (Test-Path $templatesDir)) {
    Write-ProjectError -Message "Templates directory not found: $templatesDir" -ExitCode 1
}

# Determine which groups to set up
$groups = @()
if ($Group) {
    $groupPath = Join-Path $templatesDir $Group
    if (-not (Test-Path $groupPath)) {
        Write-ProjectError -Message "Group not found: $groupPath" -ExitCode 1
    }
    $groups += $Group
} else {
    $groups = Get-ChildItem $templatesDir -Directory | Select-Object -ExpandProperty Name
    if ($groups.Count -eq 0) {
        Write-Warning "No test groups found in $templatesDir"
        exit 0
    }
}

# Clean workspace if requested
if ($Clean -and (Test-Path $workspaceDir)) {
    if ($Group) {
        $targetDir = Join-Path $workspaceDir $Group
        if (Test-Path $targetDir) {
            if ($PSCmdlet.ShouldProcess($targetDir, "Remove workspace group")) {
                Remove-Item $targetDir -Recurse -Force
                Write-Host "  Cleaned workspace for group: $Group" -ForegroundColor Yellow
            }
        }
    } else {
        if ($PSCmdlet.ShouldProcess($workspaceDir, "Remove entire workspace")) {
            Remove-Item $workspaceDir -Recurse -Force
            Write-Host "  Cleaned entire workspace" -ForegroundColor Yellow
        }
    }
}

# Create workspace directory
if (-not (Test-Path $workspaceDir)) {
    New-Item -ItemType Directory -Path $workspaceDir -Force | Out-Null
}

# Copy fixtures for each group
$totalCases = 0
foreach ($grp in $groups) {
    $srcGroup = Join-Path $templatesDir $grp
    $dstGroup = Join-Path $workspaceDir $grp

    if (-not (Test-Path $dstGroup)) {
        New-Item -ItemType Directory -Path $dstGroup -Force | Out-Null
    }

    # Find all test case directories (E2E-NNN-*)
    $testCases = Get-ChildItem $srcGroup -Directory | Where-Object { $_.Name -match '^TE-E2E-\d+' }

    foreach ($tc in $testCases) {
        $srcProject = Join-Path $tc.FullName "project"
        $dstCase = Join-Path $dstGroup $tc.Name
        $dstProject = Join-Path $dstCase "project"

        if (Test-Path $srcProject) {
            if ($PSCmdlet.ShouldProcess($dstProject, "Copy fixtures for $($tc.Name)")) {
                # Create test case directory in workspace
                if (-not (Test-Path $dstCase)) {
                    New-Item -ItemType Directory -Path $dstCase -Force | Out-Null
                }

                # Copy project fixtures
                if (Test-Path $dstProject) {
                    Remove-Item $dstProject -Recurse -Force
                }
                Copy-Item $srcProject $dstProject -Recurse -Force
                $totalCases++
            }
        }
    }

    Write-ProjectSuccess -Message "Set up group: $grp ($($testCases.Count) test cases)"
}

Write-Host ""
Write-Host "Test environment ready:" -ForegroundColor Cyan
Write-Host "  Groups: $($groups.Count)" -ForegroundColor Cyan
Write-Host "  Test cases: $totalCases" -ForegroundColor Cyan
Write-Host "  Workspace: $workspaceDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next: Execute test cases following the master test or individual test-case.md files." -ForegroundColor Yellow
