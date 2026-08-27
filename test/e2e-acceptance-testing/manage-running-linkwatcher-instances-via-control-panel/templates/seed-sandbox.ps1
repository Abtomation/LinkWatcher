<#
.SYNOPSIS
    Seeds the sandbox project registry for a WF-010 Control Panel E2E acceptance test case.

.DESCRIPTION
    Every WF-010 test case points the Control Panel at a synthetic project registry inside the
    test workspace, so the panel supervises sandbox projects instead of the operator's real
    machine. The registry must carry ABSOLUTE project roots (discovery.py resolves a relative
    path against the panel process CWD, which is not predictable), so it cannot be a static
    fixture — this script writes it at test time from the workspace path it is given.

    It also enforces the load-bearing precondition that makes the sandbox safe: every
    sandbox project MUST contain its own doc/project-config.json. The launcher
    (start_linkwatcher_background.ps1) resolves the project root by walking UP from its own
    location looking for doc/project-config.json, up to 10 levels. The workspace lives inside
    the real LinkWatcher repository, which is within that radius — so a sandbox project missing
    its config would silently resolve to the REAL repository root and start a daemon against
    the whole repo. This script fails loudly rather than let that happen.

.PARAMETER WorkspacePath
    The per-case workspace directory created by Setup-TestEnvironment.ps1, i.e.
    test/e2e-acceptance-testing/manage-running-linkwatcher-instances-via-control-panel/workspace/TE-E2E-NNN-<name>

.PARAMETER RegistryFileName
    Name of the registry file to write inside the workspace. Default: sandbox-registry.json

.EXAMPLE
    ./seed-sandbox.ps1 -WorkspacePath "C:\...\workspace\TE-E2E-034-panel-lists-running-daemons"

.NOTES
    Created: 2026-08-25
    Task: E2E Acceptance Test Case Creation (PF-TSK-069), WF-010 milestone
    Not named run.ps1 deliberately: Run-E2EAcceptanceTest.ps1 classifies a case as fully
    scripted by the PRESENCE of run.ps1 and would then execute these cases unattended, with
    no human driving the panel window, producing a false verdict. WF-010 cases are manual;
    this script only performs their file-side setup.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,

    [Parameter(Mandatory = $false)]
    [string]$RegistryFileName = "sandbox-registry.json"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $WorkspacePath)) {
    Write-Error "Workspace not found: $WorkspacePath. Run Setup-TestEnvironment.ps1 -Workflow manage-running-linkwatcher-instances-via-control-panel -Clean first."
}

$workspace = (Resolve-Path -LiteralPath $WorkspacePath).Path
$projectDir = Join-Path $workspace "project"

if (-not (Test-Path -LiteralPath $projectDir)) {
    Write-Error "No project/ directory inside the workspace: $projectDir"
}

$sandboxes = @(Get-ChildItem -LiteralPath $projectDir -Directory | Where-Object { $_.Name -like 'sandbox-*' } | Sort-Object Name)

if ($sandboxes.Count -eq 0) {
    Write-Error "No sandbox-* project directories found under $projectDir"
}

# Guard: every sandbox needs its own doc/project-config.json (see .DESCRIPTION).
$missing = @()
foreach ($sb in $sandboxes) {
    $cfg = Join-Path $sb.FullName "doc/project-config.json"
    if (-not (Test-Path -LiteralPath $cfg)) { $missing += $sb.Name }
}
if ($missing.Count -gt 0) {
    Write-Error ("Sandbox project(s) missing doc/project-config.json: {0}. Refusing to seed — the launcher would walk up and resolve the REAL repository root instead." -f ($missing -join ', '))
}

# Stamp each sandbox's own doc/project-config.json with its absolute root.
# The launcher reads project.root_directory and validates it with Test-Path, so this
# value is machine- and workspace-specific and cannot be a static fixture — same reason
# the registry below is generated rather than shipped.
foreach ($sb in $sandboxes) {
    $cfgPath = Join-Path $sb.FullName "doc/project-config.json"
    $cfg = Get-Content -LiteralPath $cfgPath -Raw | ConvertFrom-Json
    if (-not $cfg.project) {
        Write-Error "Sandbox $($sb.Name) doc/project-config.json has no 'project' object to stamp — fixture is malformed."
    }
    $cfg.project.root_directory = $sb.FullName
    $cfg | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $cfgPath -Encoding UTF8
}

$projects = [ordered]@{}
$index = 0
foreach ($sb in $sandboxes) {
    $index++
    $id = "SBX-{0:D3}" -f $index
    $projects[$id] = [ordered]@{
        name                     = $sb.Name
        path                     = $sb.FullName
        added                    = "2026-08-25"
        current_framework_version = "sandbox"
        last_rollout             = $null
        version_freeze           = $false
        frozen_at_version        = $null
        notes                    = "WF-010 E2E sandbox project — not a real registered project"
    }
}

$registry = [ordered]@{
    metadata = [ordered]@{
        description = "Synthetic project registry for WF-010 Control Panel E2E acceptance tests"
        generated   = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        workspace   = $workspace
    }
    projects = $projects
}

$registryPath = Join-Path $workspace $RegistryFileName
$registry | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $registryPath -Encoding UTF8

Write-Host ""
Write-Host "Stamped project.root_directory in $($sandboxes.Count) sandbox config(s)." -ForegroundColor Green
Write-Host "Sandbox registry seeded: $registryPath" -ForegroundColor Green
foreach ($id in $projects.Keys) {
    Write-Host ("  {0}  {1}  ->  {2}" -f $id, $projects[$id].name, $projects[$id].path)
}
Write-Host ""
Write-Host "Launch the panel against this sandbox with:" -ForegroundColor Cyan
Write-Host "  python control_panel.py --registry `"$registryPath`" --debug"
Write-Host ""
