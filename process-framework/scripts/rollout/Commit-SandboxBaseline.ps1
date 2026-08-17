<#
.SYNOPSIS
After a Push to this workspace's framework self-test sandbox (APP-T01 at appdev), refresh
the sandbox's baseline commit so the next E2E test reset cycle has the new rolled-out
state as its pristine target.

.DESCRIPTION
Derives the child-registry shape (filename, collection key, sandbox key pattern) from the
workspace's declared role via Get-ChildRegistryInfo (PF-PRO-068 P-10 — same resolver as
Push/Restore), then targets the registry's single sandbox row (rows matching the level's
sandbox key pattern: ^PRJ-T at appdev, ^FWK-T at FB); with more than one sandbox row, name
one with -Sandbox. In the sandbox's own git repo:
  1. Refuses to run if working tree is clean (nothing to baseline).
  2. `git add -A`
  3. `git commit -m "baseline: post-rollout v<framework-version>"`
where <framework-version> is read from `<sandbox>/.framework-version` if present
(falls back to "unstamped" otherwise — e.g., during first-time sandbox setup before
any Push).

See PF-TSK-088 §"Sandbox Baseline Maintenance (APP-T01 only)" for the SOP rationale.

.PARAMETER Sandbox
Optional explicit sandbox row ID. Required only when the registry carries more than one
sandbox row. The row must match the level's sandbox key pattern — this script runs
`git add -A` + commit in the target repo, which must never happen to a real child's tree.

.PARAMETER Check
Dry-run. Reports the count of files that would be committed and the commit message;
makes no changes.

.PARAMETER Force
Allow committing even when `git status --porcelain` reports zero changes (e.g., to
produce an empty commit marking a reset point). Off by default — usual behavior is
to refuse on clean working tree.

.EXAMPLE
# After a Push to APP-T01 lands:
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/rollout/Commit-SandboxBaseline.ps1 -Confirm:$false

.EXAMPLE
# Dry-run preview:
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/rollout/Commit-SandboxBaseline.ps1 -Check

.NOTES
Framework Self-Testing extension (PF-PRO-035) Phase 3.5. Authored Session 22 (2026-05-18).
Relocated to the shipped tree at scripts/rollout/ as SUPPORT class per the payload
manifest (ships to framework/framework-builder children only, never to project trees) —
PF-PRO-068 Session E2 (2026-08-10). It operates on the producer workspace's central
state (child registry, sandbox rows), so it only ever runs at a producer face.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Check,
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$Sandbox
)

$ErrorActionPreference = 'Stop'

# Resolve the producer root via an upward probe from $PSScriptRoot — robust against cwd AND
# against the script's own depth: the same file must work at a producer face
# (<workspace>/blueprint/process-framework/scripts/rollout/, depth 4) and as a received copy
# in a framework child's consumer face (<child>/process-framework/scripts/rollout/, depth 3).
# A fixed Split-Path count would mis-resolve one of the two — from a depth-3 consumer copy a
# 4-level walk lands on the CHILD'S PARENT directory, which can itself pass the probe pair.
# Authentication pair matches Push/Restore's Get-ProducerRoot: doc/project-config.json AND
# process-framework-central/ must both exist at the candidate root.
$producerRoot = $null
$probe = $PSScriptRoot
while ($probe) {
    if ((Test-Path (Join-Path $probe 'doc/project-config.json')) -and
        (Test-Path (Join-Path $probe 'process-framework-central'))) {
        $producerRoot = $probe
        break
    }
    $parent = Split-Path -Parent $probe
    if (-not $parent -or $parent -eq $probe) { break }
    $probe = $parent
}
if (-not $producerRoot) {
    Write-Error "Could not locate the producer root: no ancestor of '$PSScriptRoot' contains both doc/project-config.json and process-framework-central/. This script only runs at a producer face."
    exit 1
}

# P-10: derive the child-registry shape from this workspace's declared role. The resolver is
# the shipped Get-ChildRegistryInfo in the producer's OWN framework tree (same pattern as
# Push/Restore); the framework tree resolves paths.blueprint -> paths.process_framework
# (PF-PRO-068 Constraint 1, newest key first).
try {
    $configPath = Join-Path $producerRoot 'doc/project-config.json'
    if (-not (Test-Path $configPath)) {
        throw "doc/project-config.json not found at '$configPath'."
    }
    $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
    $sourceRel = $null
    if ($config.paths -and $config.paths.blueprint) { $sourceRel = $config.paths.blueprint }
    elseif ($config.paths -and $config.paths.process_framework) { $sourceRel = $config.paths.process_framework }
    if (-not $sourceRel) {
        throw "doc/project-config.json at '$configPath' declares neither paths.blueprint nor paths.process_framework."
    }
    $coreModule = Join-Path $producerRoot "$sourceRel/scripts/Common-ScriptHelpers/Core.psm1"
    Import-Module $coreModule -Force -ErrorAction Stop
    $regInfo = Get-ChildRegistryInfo -ProjectRoot $producerRoot
}
catch {
    Write-Error "Could not derive the child-registry shape for this workspace: $($_.Exception.Message)"
    exit 1
}

$registryPath = Join-Path $producerRoot "process-framework-central/$($regInfo.FileName)"
if (-not (Test-Path $registryPath)) {
    Write-Error "Child registry '$($regInfo.FileName)' (derived from role '$($regInfo.Role)') not found at $registryPath"
    exit 1
}

$registry = Get-Content $registryPath -Raw | ConvertFrom-Json -AsHashtable
$children = $registry[$regInfo.CollectionKey]
if ($null -eq $children) {
    Write-Error "Child registry '$($regInfo.FileName)' has no top-level '$($regInfo.CollectionKey)' collection (derived from role '$($regInfo.Role)'). The registry file and the workspace role disagree — repair one of them."
    exit 1
}

# Target the sandbox row — derived from the level's sandbox key pattern, never a hard-coded
# ID (P-10: at FB the pattern is ^FWK-T and a APP-T01 literal matches nothing). Every row
# this script touches gets `git add -A` + commit, so a non-sandbox row is always refused.
if ($Sandbox) {
    if (-not $children.ContainsKey($Sandbox)) {
        Write-Error "Sandbox row '$Sandbox' not found in $($regInfo.FileName). Known IDs: $($children.Keys -join ', ')"
        exit 1
    }
    if ($Sandbox -notmatch $regInfo.SandboxKeyPattern) {
        Write-Error "Registry row '$Sandbox' does not match this level's sandbox key pattern ('$($regInfo.SandboxKeyPattern)') — refusing to baseline a non-sandbox row: this script commits the target repo's ENTIRE working tree (git add -A), which must never happen to a real child."
        exit 1
    }
    $sandboxId = $Sandbox
}
else {
    $sandboxIds = @($children.Keys | Where-Object { $_ -match $regInfo.SandboxKeyPattern } | Sort-Object)
    if ($sandboxIds.Count -eq 0) {
        Write-Error "No sandbox row (pattern '$($regInfo.SandboxKeyPattern)') registered in $($regInfo.FileName) — nothing to baseline."
        exit 1
    }
    if ($sandboxIds.Count -gt 1) {
        Write-Error "Multiple sandbox rows in $($regInfo.FileName): $($sandboxIds -join ', '). Name one explicitly with -Sandbox."
        exit 1
    }
    $sandboxId = $sandboxIds[0]
}

$sandboxPath = $children[$sandboxId].path
if (-not (Test-Path $sandboxPath)) {
    Write-Error "Sandbox path does not exist: $sandboxPath"
    exit 1
}
if (-not (Test-Path (Join-Path $sandboxPath '.git'))) {
    Write-Error "Sandbox is not a git repo: $sandboxPath. Initialize with 'git init' first."
    exit 1
}

# Read framework version stamp (best-effort).
# Per PF-TSK-088 convention, .framework-version lives WITH the framework copy at
# <project>/process-framework/.framework-version (not at project root).
$versionFile = Join-Path $sandboxPath 'process-framework/.framework-version'
$version = if (Test-Path $versionFile) {
    (Get-Content $versionFile -Raw).Trim()
} else {
    'unstamped'
}

# Check working tree state
$statusOutput = & git -C $sandboxPath status --porcelain 2>&1
$changedLines = if ($statusOutput) { @($statusOutput -split "`r?`n" | Where-Object { $_ }) } else { @() }
$changedCount = $changedLines.Count

$message = "baseline: post-rollout v$version"

Write-Host "Sandbox       : $sandboxId ($sandboxPath)" -ForegroundColor Cyan
Write-Host "Framework ver : $version" -ForegroundColor Cyan
Write-Host "Changes       : $changedCount files" -ForegroundColor Cyan
Write-Host "Commit message: $message" -ForegroundColor Cyan
Write-Host ''

# Test-cycle contamination check: if any changed path overlaps a TE-E2E test's
# `mutates` or `creates` list in sandbox-reset-registry.json, the working tree
# is most likely captured mid-test, not in a post-rollout pristine state. See
# Session 28 §Third process gap (Framework Self-Testing extension).
$resetRegistryPath = Join-Path $sandboxPath 'process-framework/scripts/test/e2e-acceptance-testing/sandbox-reset-registry.json'

# Push fingerprint (PF-IMP-1334): a rollout bumps process-framework/.framework-version, a file no
# E2E test mutates. Its presence in the change set marks a legitimate post-rollout baseline — this
# script's primary use case — so the mid-test contamination heuristic below is skipped. A rollout's
# natural churn of registries and regenerated projections (PF-id-registry.json, ai-tasks.md,
# PF-documentation-map.md, the task registry, tasks/README.md) overlaps the test mutates lists by
# design — TE-E2E-003 exercises those very files — which made the guard false-positive on every real
# post-Push baseline and train reflexive -Force. A mid-test contamination leaves no version bump, so
# the guard still fires when .framework-version is unchanged. (Residual: running a test between the
# Push and the baseline — an SOP violation — would let the bump mask that pollution.)
$versionStampPath = 'process-framework/.framework-version'
$isPostPush = $false
foreach ($line in $changedLines) {
    if ($line.Length -lt 4) { continue }
    if ((($line.Substring(3) -replace '\\', '/').Trim('"')) -eq $versionStampPath) { $isPostPush = $true; break }
}
if ($isPostPush) {
    Write-Host "Post-rollout baseline ($versionStampPath changed) — mid-test contamination check skipped." -ForegroundColor Cyan
    Write-Host ''
}

$contaminations = @()
if ((Test-Path $resetRegistryPath) -and $changedCount -gt 0 -and -not $isPostPush) {
    try {
        $resetRegistry = Get-Content $resetRegistryPath -Raw | ConvertFrom-Json
        $testTouchedPaths = New-Object System.Collections.Generic.HashSet[string]
        foreach ($prop in $resetRegistry.tests.PSObject.Properties) {
            foreach ($m in @($prop.Value.mutates)) { if ($m) { [void]$testTouchedPaths.Add($m) } }
            foreach ($c in @($prop.Value.creates)) { if ($c) { [void]$testTouchedPaths.Add($c) } }
        }

        foreach ($line in $changedLines) {
            if ($line.Length -lt 4) { continue }
            $changedPath = ($line.Substring(3) -replace '\\', '/').Trim('"')
            foreach ($touched in $testTouchedPaths) {
                if ($changedPath -eq $touched -or $changedPath.StartsWith("$touched/")) {
                    $contaminations += [pscustomobject]@{ Changed = $changedPath; RegistryEntry = $touched }
                    break
                }
            }
        }
    } catch {
        Write-Host "WARN: failed to read sandbox-reset-registry.json — skipping contamination check ($($_.Exception.Message))" -ForegroundColor DarkYellow
    }
}

if ($contaminations.Count -gt 0) {
    Write-Host "WARNING: Working tree contains paths that overlap TE-E2E test mutates/creates entries:" -ForegroundColor Yellow
    foreach ($c in $contaminations | Select-Object -First 10) {
        Write-Host "  $($c.Changed)  <- reset-registry entry: $($c.RegistryEntry)" -ForegroundColor Yellow
    }
    if ($contaminations.Count -gt 10) {
        Write-Host "  ... ($($contaminations.Count - 10) more)" -ForegroundColor Yellow
    }
    Write-Host ''
    if (-not $Force) {
        Write-Host "Baseline commit refused: mid-test contamination is the most likely cause." -ForegroundColor Red
        Write-Host "Resolution:" -ForegroundColor Yellow
        Write-Host "  1. Reset the sandbox via Run-E2EAcceptanceTest -Clean to revert the mutations, then re-run the rollout that produced the legitimate baseline state." -ForegroundColor Yellow
        Write-Host "  2. If the changes are NOT test pollution and you want them in the baseline, re-run with -Force." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "Force override: contamination ignored." -ForegroundColor DarkYellow
    Write-Host ''
}

if ($changedCount -eq 0 -and -not $Force) {
    Write-Host 'Working tree is clean — nothing to baseline.' -ForegroundColor Yellow
    Write-Host "Did a Push to $sandboxId actually change anything? Use -Force to commit anyway (empty commit)." -ForegroundColor Yellow
    exit 0
}

if ($Check) {
    Write-Host '--- DRY-RUN — first 20 changed paths ---' -ForegroundColor Yellow
    $changedLines | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
    if ($changedCount -gt 20) { Write-Host "  ... ($($changedCount - 20) more)" }
    Write-Host ''
    Write-Host 'DRY-RUN — no commit made.' -ForegroundColor Yellow
    exit 0
}

if (-not $PSCmdlet.ShouldProcess($sandboxPath, "git add -A && git commit -m '$message'")) {
    Write-Host 'Skipped (ShouldProcess declined)' -ForegroundColor Yellow
    exit 0
}

# Stage + commit in the sandbox's own git repo (NOT appdev)
& git -C $sandboxPath add -A 2>&1 | Out-Null
$commitArgs = @('-C', $sandboxPath, 'commit', '-m', $message)
if ($Force -and $changedCount -eq 0) { $commitArgs += '--allow-empty' }
$commitOutput = & git @commitArgs 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host 'git commit failed:' -ForegroundColor Red
    $commitOutput | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host "[OK] Baseline commit created in sandbox" -ForegroundColor Green
$commitOutput | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" }
