<#
.SYNOPSIS
Reset per-test sandbox state for a framework-self-test E2E case (PRJ-T01 sandbox only).

.DESCRIPTION
For the given -TestId (TE-E2E-NNN), reads the per-test reset path lists from
`sandbox-reset-registry.json` (sibling file) and applies them in the sandbox's own
git repository:

- `mutates`: each path reverted to HEAD via `git -C <sandbox> checkout HEAD -- <path>`
  (the sandbox baseline established by Commit-SandboxBaseline.ps1).
- `creates`: each path deleted via `Remove-Item -Force -ErrorAction SilentlyContinue`
  (no-op if the path doesn't exist — test may not have created it yet).

This script intentionally invokes `git checkout HEAD -- <path>`, which is forbidden by
the global "Prohibited Git Commands" rule in CLAUDE.md. The exception is scoped to
PRJ-T01 sandbox only, per PF-TSK-070 §"Sandbox Execution (PRJ-T01 only)" — sandbox state
is rollout-pipeline-owned with no uncommitted ad-hoc work to lose, and the reset is
bound to an explicit per-test path list (not blanket).

.PARAMETER TestId
Required. TE-E2E-NNN. Must have an entry in sandbox-reset-registry.json under the
`tests` object.

.PARAMETER SandboxRoot
Optional. Path to the sandbox root. Defaults to walking up 4 directories from
$PSScriptRoot (which lands on the project root when this script is rolled out to
<sandbox>/process-framework/scripts/test/e2e-acceptance-testing/).

.PARAMETER Check
Dry-run. Reports what would be reset without making changes.

.EXAMPLE
# Reset TE-E2E-003 before invoking its test run.ps1:
Reset-SandboxFixtures.ps1 -TestId TE-E2E-003

.EXAMPLE
# Dry-run:
Reset-SandboxFixtures.ps1 -TestId TE-E2E-003 -Check

.NOTES
Framework Self-Testing extension (PF-PRO-035) Phase 3.5. Authored Session 22 (2026-05-18).
Invoked by Run-E2EAcceptanceTest.ps1 before each framework-self-test case's pre-test setup.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^TE-E2E-\d+$')]
    [string]$TestId,

    [string]$SandboxRoot = '',

    [switch]$Check
)

$ErrorActionPreference = 'Stop'

# Resolve sandbox root.
if (-not $SandboxRoot) {
    # Default: this script lives at <sandbox>/process-framework/scripts/test/e2e-acceptance-testing/Reset-SandboxFixtures.ps1
    # Walk up 4 dirs: e2e-acceptance-testing → test → scripts → process-framework → <sandbox>
    $SandboxRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
}
if (-not (Test-Path $SandboxRoot)) {
    Write-Error "Sandbox root not found: $SandboxRoot"
    exit 1
}
if (-not (Test-Path (Join-Path $SandboxRoot '.git'))) {
    Write-Error "Sandbox is not a git repo: $SandboxRoot"
    exit 1
}

# Load reset registry (sibling file).
$registryPath = Join-Path $PSScriptRoot 'sandbox-reset-registry.json'
if (-not (Test-Path $registryPath)) {
    Write-Error "Reset registry not found: $registryPath"
    exit 1
}

$registry = Get-Content $registryPath -Raw | ConvertFrom-Json
$testEntry = $registry.tests.$TestId
if (-not $testEntry) {
    Write-Error "No entry for $TestId in $registryPath. Add an entry to sandbox-reset-registry.json under the 'tests' object."
    exit 1
}

$mutates = @($testEntry.mutates)
$creates = @($testEntry.creates)

Write-Host "Reset sandbox for $TestId" -ForegroundColor Cyan
Write-Host "  Sandbox  : $SandboxRoot" -ForegroundColor Cyan
Write-Host "  Mutates  : $($mutates.Count) path(s)" -ForegroundColor Cyan
Write-Host "  Creates  : $($creates.Count) path(s)" -ForegroundColor Cyan

if ($Check) {
    Write-Host ''
    Write-Host '--- DRY-RUN ---' -ForegroundColor Yellow
    foreach ($p in $mutates) { Write-Host "  [mutate] git checkout HEAD -- $p" }
    foreach ($p in $creates) { Write-Host "  [create] Remove-Item $p" }
    exit 0
}

$failures = @()

# Revert mutated files via git checkout HEAD -- (scoped, per-path).
foreach ($p in $mutates) {
    $target = "Mutate: $p"
    if (-not $PSCmdlet.ShouldProcess($target, "git -C $SandboxRoot checkout HEAD -- $p")) { continue }

    $checkoutOutput = & git -C $SandboxRoot checkout HEAD -- $p 2>&1
    if ($LASTEXITCODE -ne 0) {
        $failures += "git checkout failed for $p`: $checkoutOutput"
    }
}

# Delete test-created files (no-op if not present).
foreach ($p in $creates) {
    $fullPath = Join-Path $SandboxRoot $p
    $target = "Create: $p"
    if (-not $PSCmdlet.ShouldProcess($target, "Remove-Item $fullPath")) { continue }

    if (Test-Path $fullPath) {
        try {
            Remove-Item -Path $fullPath -Force -Recurse -ErrorAction Stop
        } catch {
            $failures += "Remove-Item failed for $p`: $($_.Exception.Message)"
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host ''
    Write-Host '[FAIL] Reset incomplete:' -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Host '[OK] Sandbox reset complete.' -ForegroundColor Green
