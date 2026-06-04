<#
.SYNOPSIS
Registers a project with appdev's central registry, assigning it a stable PRJ-NNN ID.

.DESCRIPTION
Two parameter sets:

1. **Retrofit** (existing project gains framework awareness): provide -Path, -Name, -AppdevPath.
   - Assigns next PRJ-NNN from <AppdevPath>/process-framework-central/PF-id-registry-central.json (PRJ pool).
   - Adds a registry entry to <AppdevPath>/process-framework-central/project-registry.json.
   - Writes "project_id": "PRJ-NNN" into <Path>/doc/project-config.json (file must already exist).
   - Creates <AppdevPath>/process-framework-central/per-project-migrations/PRJ-NNN/ with an empty
     pending-migrations.md skeleton.

2. **Appdev self-registration** (one-time, reserves PRJ-000): provide -IsAppdev. cwd must be appdev.
   - Assigns PRJ-000 (refuses if already registered — idempotent exit 0).
   - Writes registry entry with version_freeze=true.
   - Writes "project_id": "PRJ-000" into <appdev>/doc/project-config.json (creates the file if missing).
   - Does NOT create a per-project-migrations directory (appdev never receives migrations from itself).

Owned by [Framework Rollout Task (PF-TSK-088)](../../../tasks/support/framework-rollout-task.md) Mode A
(retrofit + PRJ-000 self-registration). Also invoked from PF-TSK-059 (Project Initiation) as the final
step of new-project setup.

.PARAMETER Path
Absolute or relative path to the project being registered. Required for retrofit.

.PARAMETER Name
Display name for the project (becomes the registry's `name` field). Required for retrofit.
The PRJ-NNN ID is the stable reference; this name can change later via direct registry edit.

.PARAMETER AppdevPath
Absolute or relative path to the appdev root (which must contain process-framework-central/
project-registry.json). Required for retrofit.

.PARAMETER IsAppdev
Switch flag. When set, registers PRJ-000 for appdev itself. cwd must be the appdev root.
All other parameters are ignored. Idempotent — re-running when PRJ-000 already exists exits 0
with an informational message.

.PARAMETER Notes
Optional registry-entry `notes` field. Free-form text.

.EXAMPLE
Register-Project.ps1 -Path "C:\path\to\my-project" -Name "MyProject" -AppdevPath "C:\path\to\appdev" -Notes "Optional registry note."

.EXAMPLE
# From cwd=appdev:
Register-Project.ps1 -IsAppdev

.NOTES
Per Centralized Framework Management proposal §3.10 and PF-TSK-088 Mode A. Created during
Phase 3 of the centralized-framework-management Framework Extension.
#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Retrofit')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Retrofit')]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [Parameter(Mandatory = $true, ParameterSetName = 'Retrofit')]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1, 100)]
    [string]$Name,

    [Parameter(Mandatory = $true, ParameterSetName = 'Retrofit')]
    [ValidateNotNullOrEmpty()]
    [string]$AppdevPath,

    [Parameter(Mandatory = $true, ParameterSetName = 'AppdevSelf')]
    [switch]$IsAppdev,

    [Parameter(Mandatory = $false)]
    [string]$Notes = ""
)

$ErrorActionPreference = 'Stop'

# Resolve module path (Common-ScriptHelpers) — only used for output formatting helpers
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "../../Common-ScriptHelpers.psm1"
try {
    $resolvedModulePath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedModulePath -Force
}
catch {
    Write-Error "Failed to import Common-ScriptHelpers: $($_.Exception.Message)"
    exit 1
}

#---------------------------------------------------------------------------------------
# Helpers
#---------------------------------------------------------------------------------------

function Resolve-AppdevRoot {
    param([string]$Candidate)

    $abs = [System.IO.Path]::GetFullPath($Candidate)
    $registry = Join-Path -Path $abs -ChildPath "process-framework-central/project-registry.json"
    $idReg    = Join-Path -Path $abs -ChildPath "process-framework-central/PF-id-registry-central.json"

    if (-not (Test-Path -Path $registry)) {
        throw "AppdevPath '$abs' is invalid: missing 'process-framework-central/project-registry.json'."
    }
    if (-not (Test-Path -Path $idReg)) {
        throw "AppdevPath '$abs' is invalid: missing 'process-framework-central/PF-id-registry-central.json'."
    }

    return $abs
}

function Read-CentralRegistry {
    param([string]$AppdevRoot)
    $regPath = Join-Path -Path $AppdevRoot -ChildPath "process-framework-central/project-registry.json"
    return ,(Get-Content -Raw -Path $regPath | ConvertFrom-Json -AsHashtable)
}

function Read-CentralIdRegistry {
    param([string]$AppdevRoot)
    $regPath = Join-Path -Path $AppdevRoot -ChildPath "process-framework-central/PF-id-registry-central.json"
    return ,(Get-Content -Raw -Path $regPath | ConvertFrom-Json -AsHashtable)
}

function Save-Json {
    param([string]$Path, [object]$Object)
    # Use depth 100 to handle nested registry structures; ConvertTo-Json default is 2.
    $json = $Object | ConvertTo-Json -Depth 100
    # ConvertTo-Json outputs without trailing newline; add one for POSIX-friendly files.
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}

function Format-PrjId {
    param([int]$N)
    return ('PRJ-{0:D3}' -f $N)
}

function Get-ProjectConfigPath {
    param([string]$ProjectRoot)
    return (Join-Path -Path $ProjectRoot -ChildPath "doc/project-config.json")
}

function Initialize-ProjectLocalRegistry {
    <#
    Provisions doc/state-tracking/PF-id-registry-local.json with default project-local prefixes
    (PF-STA, PF-TMP) if the file does not already exist. Idempotent — silently no-ops when present
    to preserve existing counter state.

    Project-local prefixes are the ones consumed by scripts running in cwd=project (PRJ-001+):
    PF-STA for state-tracking documents, PF-TMP for transient state. Cross-project prefixes
    (PF-IMP, PF-PRO, PF-FEE, PF-REV, PF-EVR, PRJ, PF-SST) live in appdev's central registry
    and are not duplicated here per the Centralized Framework Management proposal §3.1.
    #>
    param([string]$ProjectRoot)

    $localRegPath = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/PF-id-registry-local.json"
    if (Test-Path -Path $localRegPath) {
        return $false  # already provisioned; no-op
    }

    $regDir = Split-Path -Parent $localRegPath
    if (-not (Test-Path -Path $regDir)) {
        New-Item -ItemType Directory -Path $regDir -Force | Out-Null
    }

    $today = (Get-Date -Format "yyyy-MM-dd")
    $defaultRegistry = [ordered]@{
        metadata = [ordered]@{
            name        = "PF-id-registry-local"
            version     = "1.0"
            created     = $today
            updated     = $today
            description = "Project-local ID Registry — prefixes consumed by scripts running in cwd=project (PRJ-001+). Per Centralized Framework Management proposal §3.1: cross-project prefixes (PF-IMP, PF-PRO, PF-FEE, PF-REV, PF-EVR, PRJ, PF-SST) live in appdev's central registry and are NOT duplicated here. Provisioned by Register-Project.ps1 on initial registration."
            format      = "semantic"
            id_gaps_policy = "Gaps in ID sequences are expected. IDs are consumed by scripts at creation time; if the script fails or the output is discarded, the ID is not reclaimed. Do not manually reassign or fill gaps."
        }
        prefixes = [ordered]@{
            'PF-STA' = [ordered]@{
                description = "Process Framework - Project-Local State Tracking"
                category    = "Process Framework"
                type        = "State"
                directories = [ordered]@{
                    permanent = "doc/state-tracking/permanent"
                    temporary = "doc/state-tracking/temporary"
                    default   = "permanent"
                }
                nextAvailable = 1
            }
            'PF-TMP' = [ordered]@{
                description = "Process Framework - Temporary State Tracking"
                category    = "Process Framework"
                type        = "Temporary State"
                directories = [ordered]@{
                    temporary = "doc/state-tracking/temporary"
                    default   = "temporary"
                }
                nextAvailable = 1
            }
        }
    }

    Save-Json -Path $localRegPath -Object $defaultRegistry
    return $true  # provisioned new file
}

#---------------------------------------------------------------------------------------
# Mode dispatch
#---------------------------------------------------------------------------------------

if ($PSCmdlet.ParameterSetName -eq 'AppdevSelf') {

    # ----- AppdevSelf flow -----
    $cwd = (Get-Location).Path
    Write-Host "Mode: AppdevSelf (registering PRJ-000 for appdev at cwd: $cwd)"

    try {
        $appdevRoot = Resolve-AppdevRoot -Candidate $cwd
    }
    catch {
        Write-Error "cwd is not appdev: $($_.Exception.Message)"
        exit 1
    }

    $registry = Read-CentralRegistry -AppdevRoot $appdevRoot
    $idReg    = Read-CentralIdRegistry -AppdevRoot $appdevRoot

    if ($registry.projects.ContainsKey('PRJ-000')) {
        Write-Host "PRJ-000 is already registered (path: $($registry.projects['PRJ-000'].path)). Nothing to do."
        exit 0
    }

    if ($idReg.prefixes.PRJ.nextAvailable -ne 0) {
        Write-Error "Central PF-id-registry-central.json shows PRJ.nextAvailable=$($idReg.prefixes.PRJ.nextAvailable) but PRJ-000 is not yet in project-registry.json. The two are inconsistent — investigate before re-running."
        exit 1
    }

    $newEntry = [ordered]@{
        name                       = "appdev"
        path                       = $appdevRoot
        added                      = (Get-Date -Format "yyyy-MM-dd")
        current_framework_version  = $null
        last_rollout               = $null
        version_freeze             = $true
        frozen_at_version          = $null
        notes                      = if ($Notes) { $Notes } else { "Reserved ID for appdev itself — feedback/IMPs originating from framework-management work in cwd=appdev. Always frozen (the framework lives here; not a rollout target)." }
    }

    if ($PSCmdlet.ShouldProcess("project-registry.json + PF-id-registry-central.json + doc/project-config.json", "Register PRJ-000 (appdev self)")) {
        $registry.projects['PRJ-000'] = $newEntry
        $registry.metadata.updated = (Get-Date -Format "yyyy-MM-dd")
        Save-Json -Path (Join-Path -Path $appdevRoot -ChildPath "process-framework-central/project-registry.json") -Object $registry

        $idReg.prefixes.PRJ.nextAvailable = 1
        $idReg.metadata.updated = (Get-Date -Format "yyyy-MM-dd")
        Save-Json -Path (Join-Path -Path $appdevRoot -ChildPath "process-framework-central/PF-id-registry-central.json") -Object $idReg

        $configPath = Get-ProjectConfigPath -ProjectRoot $appdevRoot
        if (Test-Path -Path $configPath) {
            $cfg = Get-Content -Raw -Path $configPath | ConvertFrom-Json -AsHashtable
            $cfg['project_id'] = 'PRJ-000'
            Save-Json -Path $configPath -Object $cfg
            Write-Host "  Updated $configPath with project_id: PRJ-000"
        }
        else {
            $cfg = @{ project_id = 'PRJ-000' }
            $configDir = Split-Path -Parent $configPath
            if (-not (Test-Path -Path $configDir)) {
                New-Item -ItemType Directory -Path $configDir -Force | Out-Null
            }
            Save-Json -Path $configPath -Object $cfg
            Write-Host "  Created $configPath with project_id: PRJ-000"
        }

        Write-Host ""
        Write-Host "✅ Registered PRJ-000 (appdev) at: $appdevRoot"
        Write-Host "   version_freeze: true"
        Write-Host "   Central registry next-available PRJ: 1 (PRJ-001 reserved for first product project)"
    }
}
else {

    # ----- Retrofit flow -----
    Write-Host "Mode: Retrofit (registering existing project)"

    # Validate -Path
    if (-not (Test-Path -Path $Path -PathType Container)) {
        Write-Error "Path '$Path' does not exist or is not a directory."
        exit 1
    }
    $projectRoot = [System.IO.Path]::GetFullPath($Path)

    # Validate -AppdevPath
    try {
        $appdevRoot = Resolve-AppdevRoot -Candidate $AppdevPath
    }
    catch {
        Write-Error $_.Exception.Message
        exit 1
    }

    # Refuse self-registration through retrofit (caller probably meant -IsAppdev)
    if ($projectRoot -eq $appdevRoot) {
        Write-Error "Path equals AppdevPath — for appdev self-registration, use -IsAppdev instead."
        exit 1
    }

    # Validate doc/project-config.json exists (project must be initialized first)
    $configPath = Get-ProjectConfigPath -ProjectRoot $projectRoot
    if (-not (Test-Path -Path $configPath)) {
        Write-Error "Project at '$projectRoot' has no doc/project-config.json. Project Initiation (PF-TSK-059) must complete before registration. (For first-time scaffolding of a new project, use PF-TSK-059, which invokes this script as its final step.)"
        exit 1
    }

    # Refuse if project_id already set (idempotency check)
    $cfg = Get-Content -Raw -Path $configPath | ConvertFrom-Json -AsHashtable
    if ($cfg.ContainsKey('project_id') -and $cfg['project_id']) {
        Write-Error "Project at '$projectRoot' already has project_id '$($cfg['project_id'])'. Re-registration is not supported via this script. To rename, edit project-registry.json directly. To rotate IDs, archive and re-register manually."
        exit 1
    }

    # Read central registries
    $registry = Read-CentralRegistry -AppdevRoot $appdevRoot
    $idReg    = Read-CentralIdRegistry -AppdevRoot $appdevRoot

    # Refuse if path already in registry under a different ID
    foreach ($existingId in $registry.projects.Keys) {
        $existing = $registry.projects[$existingId]
        if ($existing.path -eq $projectRoot) {
            Write-Error "Path '$projectRoot' is already registered as $existingId (name: '$($existing.name)'). Refusing duplicate registration."
            exit 1
        }
        if ($existing.name -eq $Name) {
            Write-Warning "Name '$Name' already used by $existingId (path: '$($existing.path)'). Names should be unique for human readability — consider differentiating."
        }
    }

    # Verify PRJ-000 is registered first (PRJ-000 must precede PRJ-001+)
    if (-not $registry.projects.ContainsKey('PRJ-000')) {
        Write-Error "PRJ-000 (appdev self-registration) is not yet in the central registry. Run 'Register-Project.ps1 -IsAppdev' from the appdev cwd first, then re-run this command."
        exit 1
    }

    # Consume next PRJ-NNN
    $nextN = [int]$idReg.prefixes.PRJ.nextAvailable
    $prjId = Format-PrjId -N $nextN

    # Construct entry
    $newEntry = [ordered]@{
        name                       = $Name
        path                       = $projectRoot
        added                      = (Get-Date -Format "yyyy-MM-dd")
        current_framework_version  = $null
        last_rollout               = $null
        version_freeze             = $false
        frozen_at_version          = $null
        notes                      = $Notes
    }

    if ($PSCmdlet.ShouldProcess("$prjId — registry.json + PF-id-registry-central.json + $configPath + per-project-migrations/$prjId/", "Register $prjId ($Name) at $projectRoot")) {

        # Write registry
        $registry.projects[$prjId] = $newEntry
        $registry.metadata.updated = (Get-Date -Format "yyyy-MM-dd")
        Save-Json -Path (Join-Path -Path $appdevRoot -ChildPath "process-framework-central/project-registry.json") -Object $registry

        # Increment central PRJ counter
        $idReg.prefixes.PRJ.nextAvailable = $nextN + 1
        $idReg.metadata.updated = (Get-Date -Format "yyyy-MM-dd")
        Save-Json -Path (Join-Path -Path $appdevRoot -ChildPath "process-framework-central/PF-id-registry-central.json") -Object $idReg

        # Write project_id to project-config.json
        $cfg['project_id'] = $prjId
        Save-Json -Path $configPath -Object $cfg

        # Provision project-local ID registry (PF-STA, PF-TMP prefixes)
        $localRegProvisioned = Initialize-ProjectLocalRegistry -ProjectRoot $projectRoot
        if ($localRegProvisioned) {
            Write-Host "  Provisioned doc/state-tracking/PF-id-registry-local.json (PF-STA, PF-TMP prefixes)"
        }

        # Create per-project-migrations directory + empty ledger skeleton
        $migDir = Join-Path -Path $appdevRoot -ChildPath "process-framework-central/per-project-migrations/$prjId"
        if (-not (Test-Path -Path $migDir)) {
            New-Item -ItemType Directory -Path $migDir -Force | Out-Null
        }
        $ledgerPath = Join-Path -Path $migDir -ChildPath "pending-migrations.md"
        if (-not (Test-Path -Path $ledgerPath)) {
            $ledgerSkeleton = @"
# Pending Migrations — $prjId ($Name)

> Per-project ledger of working-document migrations awaiting application by Framework Rollout Mode C (PF-TSK-088).
> Entries are written by Structure Change (PF-TSK-014) when a structural change in appdev requires corresponding edits to this project's working documents (doc/, test/, etc.).
> Apply entries via Mode C in cwd=Project sessions. See [pending-migration-entry-template](../../../../process-framework/templates/support/pending-migration-entry-template.md) for entry structure.

## Summary

| ID | Title | Status | Source FW Version | Backward-compatible | Resolved |
|----|-------|--------|-------------------|---------------------|----------|
| _(no entries yet)_ | | | | | |

## Entries

_(no entries yet — Structure Change task appends entries here when project working-doc migrations are needed)_
"@
            [System.IO.File]::WriteAllText($ledgerPath, $ledgerSkeleton + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  Created per-project-migrations ledger: $ledgerPath"
        }

        Write-Host ""
        Write-Host "✅ Registered $prjId at: $projectRoot"
        Write-Host "   Name: $Name"
        Write-Host "   Notes: $(if ($Notes) { $Notes } else { '(none)' })"
        Write-Host "   Central registry now contains $($registry.projects.Count) project(s) — next-available PRJ: $($nextN + 1)"
        Write-Host ""
        Write-Host "Next step: roll out the framework to $prjId via:"
        Write-Host "  pwsh.exe -ExecutionPolicy Bypass -File appdev/process-framework-central/scripts/Push-FrameworkUpdate.ps1 -Project $prjId"
    }
}
