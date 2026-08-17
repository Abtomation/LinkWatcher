<#
.SYNOPSIS
Registers a project with a producer face's central registry, assigning it a stable child ID minted from the producer's own mnemonic (FWK-APP children key APP-NNN, FWK-LEG children LEG-NNN — PF-PRO-068 P-14).

.DESCRIPTION
Two parameter sets:

1. **Retrofit** (existing project gains framework awareness): provide -Path, -Name, -ProducerPath.
   - The producer face is resolved via Get-ChildRegistryInfo (PF-PRO-068 P-10): its declared role
     supplies the registry filename, collection key, per-row version-pin field, and migration-ledger
     directory — the same script therefore operates from any project-registering producer face
     (a 'framework'-role workspace such as appdev or legal), never from appdev-specific literals.
   - Derives the child-ID prefix from the producer's own declared identity (project_id
     FWK-<MNEMONIC> -> <MNEMONIC>-NNN children; PF-PRO-068 P-14) and assigns the next ID from
     the mnemonic-named pool in <ProducerPath>/process-framework-central/PF-id-registry-central.json.
     A missing pool refuses loudly — it is never auto-created (the pool is renamed/created
     deliberately; P-14 rekeyed appdev's legacy 'PRJ' pool to 'APP').
   - Adds a role-carrying registry row ('role': 'project') to the producer's child registry.
   - Writes "project_id": "<MNEMONIC>-NNN" into <Path>/doc/project-config.json (file must already exist).
   - Creates <ProducerPath>/process-framework-central/<ledger-dir>/<MNEMONIC>-NNN/ with an empty
     pending-migrations.md skeleton (ledger directory name from the registry shape).
   - A 'framework-builder' face is refused: frameworks are registered by Framework Initiation
     (Sub-concept 4); rows are hand-written, review-held, until that task exists.

2. **Self** (generic workspace self-identification): provide -Self -SelfId FWK-XXXX. cwd must be
   the workspace root of a producer face (declared role 'framework' or 'framework-builder').
   - Writes "project_id": "<SelfId>" into the workspace's own doc/project-config.json
     (idempotent — exits 0 when the config already carries that id; an identity ROTATION is
     performed loudly, naming old and new, and leaves registry alignment to the caller).
   - Writes NO registry row: a producer face's identity row lives in its PARENT's registry
     (e.g. appdev's FWK-APP row in FrameworkBuilder's framework-registry.json); only the
     portfolio root self-declares, and that row is hand-written (PF-PRO-068 P-13).
   - Replaces the retired -IsAppdev bootstrap, which created appdev's PRJ-000 self-row —
     removed by the P-13 identity switch (project_id PRJ-000 → FWK-APP, self-row deleted).

Owned by [Framework Rollout Task (PF-TSK-088)](../../../tasks/support/framework-rollout-task.md) Mode A
(retrofit registration). Also invoked from PF-TSK-059 (Project Initiation) as the final
step of new-project setup.

.PARAMETER Path
Absolute or relative path to the project being registered. Required for retrofit.

.PARAMETER Name
Display name for the project (becomes the registry's `name` field). Required for retrofit.
The child ID is the stable reference; this name can change later via direct registry edit.

.PARAMETER ProducerPath
Absolute or relative path to the producer-face root (which must contain doc/project-config.json
and process-framework-central/ with the role-derived child registry). Required for retrofit.
Alias: -AppdevPath (pre-P-13 name, kept for invocation compatibility).

.PARAMETER Self
Switch flag selecting the Self parameter set. Writes -SelfId into the current workspace's own
doc/project-config.json. cwd must be the workspace root; the workspace must declare a
producer-face role (a leaf's identity is written by its parent's registration, not by itself).

.PARAMETER SelfId
The workspace identity to declare, FWK-<MNEMONIC> shape (2–4 letters, e.g. FWK-APP).
The allocation of record is the parent registry's row key (framework-registry.json).

.PARAMETER Notes
Optional registry-entry `notes` field. Free-form text.

.EXAMPLE
Register-Project.ps1 -Path "C:\path\to\my-project" -Name "MyProject" -ProducerPath "C:\path\to\appdev" -Notes "Optional registry note."

.EXAMPLE
# From cwd=<workspace root>, declare the workspace's own identity (P-13 form):
Register-Project.ps1 -Self -SelfId FWK-APP

.NOTES
Per Centralized Framework Management proposal §3.10 and PF-TSK-088 Mode A. Created during
Phase 3 of the centralized-framework-management Framework Extension. Generalized to the
producer-face model (P-10 registry resolution, role-carrying rows, -Self identity mode)
by the Substrate Hoist (PF-PRO-068 Session E, P-13); child-ID prefix derived from the
producer mnemonic at P-14 (the 'PRJ' literal era ended 2026-08-10 — history keeps PRJ IDs).
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
    [Alias('AppdevPath')]
    [string]$ProducerPath,

    [Parameter(Mandatory = $true, ParameterSetName = 'Self')]
    [switch]$Self,

    [Parameter(Mandatory = $true, ParameterSetName = 'Self')]
    [ValidatePattern('^FWK-[A-Z]{2,4}$', Options = 'None')]  # Options None = case-SENSITIVE (default IgnoreCase would admit 'FWK-app')
    [string]$SelfId,

    [Parameter(Mandatory = $false)]
    [string]$Notes = ""
)

$ErrorActionPreference = 'Stop'

# Resolve module path (Common-ScriptHelpers) — output formatting plus the P-10 registry-shape
# resolver (Get-ChildRegistryInfo) and role reads (Get-WorkspaceRole).
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

function Resolve-ProducerRoot {
    <#
    Validates the candidate as a project-registering producer face and returns
    @{ Root = <absolute path>; Info = <Get-ChildRegistryInfo shape>; Mnemonic = <child-ID prefix> }.
    The mnemonic is derived from the producer's own declared project_id (FWK-APP -> APP,
    PF-PRO-068 P-14) — a project-registering face without an FWK-shaped identity is
    config-incoherent and refused rather than guessed at.
    #>
    param([string]$Candidate)

    $abs = [System.IO.Path]::GetFullPath($Candidate)

    $configPath = Join-Path -Path $abs -ChildPath "doc/project-config.json"
    if (-not (Test-Path -Path $configPath)) {
        throw "ProducerPath '$abs' is invalid: missing 'doc/project-config.json' (not a workspace root)."
    }

    # Role-derived registry shape (throws for leaf roles — a leaf has no child registry).
    $info = Get-ChildRegistryInfo -ProjectRoot $abs

    if ($info.AcceptedChildRoles -notcontains 'project') {
        throw "ProducerPath '$abs' (role '$($info.Role)') does not register projects — framework registration is Framework Initiation's job (PF-PRO-065 Sub-concept 4); its rows are hand-written, review-held, until then."
    }

    # P-14: the child-ID prefix is the producer's own mnemonic, read from its declared identity.
    $producerCfg = Get-Content -Raw -Path $configPath | ConvertFrom-Json
    if ($producerCfg.project_id -cnotmatch '^FWK-([A-Z]{2,4})$') {
        throw "ProducerPath '$abs' declares project_id '$($producerCfg.project_id)', not FWK-<MNEMONIC> shape — the child-ID prefix cannot be derived (PF-PRO-068 P-14). Declare the producer identity first: Register-Project.ps1 -Self -SelfId FWK-XXXX."
    }
    $mnemonic = $Matches[1]

    $registry = Join-Path -Path $abs -ChildPath "process-framework-central/$($info.FileName)"
    $idReg    = Join-Path -Path $abs -ChildPath "process-framework-central/PF-id-registry-central.json"

    if (-not (Test-Path -Path $registry)) {
        throw "ProducerPath '$abs' is invalid: missing 'process-framework-central/$($info.FileName)'."
    }
    if (-not (Test-Path -Path $idReg)) {
        throw "ProducerPath '$abs' is invalid: missing 'process-framework-central/PF-id-registry-central.json'."
    }

    return @{ Root = $abs; Info = $info; Mnemonic = $mnemonic }
}

function Read-CentralRegistry {
    param([string]$ProducerRoot, [string]$FileName)
    $regPath = Join-Path -Path $ProducerRoot -ChildPath "process-framework-central/$FileName"
    return ,(Get-Content -Raw -Path $regPath | ConvertFrom-Json -AsHashtable)
}

function Read-CentralIdRegistry {
    param([string]$ProducerRoot)
    $regPath = Join-Path -Path $ProducerRoot -ChildPath "process-framework-central/PF-id-registry-central.json"
    return ,(Get-Content -Raw -Path $regPath | ConvertFrom-Json -AsHashtable)
}

function Save-Json {
    param([string]$Path, [object]$Object)
    # Use depth 100 to handle nested registry structures; ConvertTo-Json default is 2.
    $json = $Object | ConvertTo-Json -Depth 100
    # ConvertTo-Json outputs without trailing newline; add one for POSIX-friendly files.
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}

function Format-ChildId {
    param([string]$Prefix, [int]$N)
    return ('{0}-{1:D3}' -f $Prefix, $N)
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

    Project-local prefixes are the ones consumed by scripts running in cwd=project children:
    PF-STA for state-tracking documents, PF-TMP for transient state. Cross-project prefixes
    (PF-IMP, PF-PRO, PF-FEE, PF-REV, PF-EVR, the mnemonic-named child pool (e.g. APP), PF-SST)
    live in the producer's central registry and are not duplicated here per the Centralized
    Framework Management proposal §3.1.
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
            description = "Project-local ID Registry — prefixes consumed by scripts running in cwd=project children. Per Centralized Framework Management proposal §3.1: cross-project prefixes (PF-IMP, PF-PRO, PF-FEE, PF-REV, PF-EVR, the mnemonic-named child pool (e.g. APP), PF-SST) live in the producer's central registry and are NOT duplicated here. Provisioned by Register-Project.ps1 on initial registration."
            format      = "semantic"
            id_gaps_policy = "Gaps in ID sequences are expected and never backfilled: an ID stays with its artifact for life — never reassign, renumber, or reuse a deleted artifact's ID (archives and history may still reference it). This constrains IDs, not the pool's nextAvailable counter, which must stay above every ID issued in this tree and never drops just because artifacts were deleted — EXCEPT reset it to 1 when the pool holds zero artifacts and none of its IDs are still referenced here (population migrated, retired, or blueprint seed only), or the vacated range is burned here and, for blueprint copies, in every project bootstrapped later. Projects that already grew their counter keep it."
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

if ($PSCmdlet.ParameterSetName -eq 'Self') {

    # ----- Self flow (generic workspace self-identification) -----
    $cwd = (Get-Location).Path
    Write-Host "Mode: Self (declaring workspace identity '$SelfId' at cwd: $cwd)"

    $configPath = Get-ProjectConfigPath -ProjectRoot $cwd
    if (-not (Test-Path -Path $configPath)) {
        Write-Error "cwd is not a workspace root: missing 'doc/project-config.json'. The Self mode declares an EXISTING workspace's identity; it does not scaffold one."
        exit 1
    }

    $role = Get-WorkspaceRole -ProjectRoot $cwd
    if ($role -notin @('framework', 'framework-builder')) {
        Write-Error "Workspace at '$cwd' declares role '$role' — a leaf workspace's identity is written by its parent's registration (retrofit mode from the producer face), never self-declared."
        exit 1
    }

    $cfg = Get-Content -Raw -Path $configPath | ConvertFrom-Json -AsHashtable
    $currentId = if ($cfg.ContainsKey('project_id')) { $cfg['project_id'] } else { $null }

    if ($currentId -eq $SelfId) {
        Write-Host "Workspace already declares project_id '$SelfId'. Nothing to do."
        exit 0
    }

    if ($currentId) {
        Write-Warning "Identity ROTATION: '$currentId' → '$SelfId'. Registry rows keyed or attributed to '$currentId' (parent registry, trackers) are NOT rewritten by this script — align them in the same change."
    }

    if ($PSCmdlet.ShouldProcess($configPath, "Set workspace identity project_id = '$SelfId'")) {
        $cfg['project_id'] = $SelfId
        Save-Json -Path $configPath -Object $cfg
        Write-Host ""
        Write-Host "✅ Declared workspace identity '$SelfId' in $configPath"
        Write-Host "   The allocation of record is the parent registry's row key (portfolio root self-declares, hand-written)."
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

    # Validate -ProducerPath (role-derived registry shape; refuses leaf and framework-builder faces)
    try {
        $producer = Resolve-ProducerRoot -Candidate $ProducerPath
    }
    catch {
        Write-Error $_.Exception.Message
        exit 1
    }
    $producerRoot = $producer.Root
    $regInfo      = $producer.Info
    $mnemonic     = $producer.Mnemonic

    # Refuse self-registration through retrofit (caller probably meant -Self)
    if ($projectRoot -eq $producerRoot) {
        Write-Error "Path equals ProducerPath — a workspace's own identity is declared with -Self -SelfId FWK-XXXX, not by registering itself as its own child."
        exit 1
    }

    # Validate doc/project-config.json exists (project must be initialized first)
    $configPath = Get-ProjectConfigPath -ProjectRoot $projectRoot
    if (-not (Test-Path -Path $configPath)) {
        Write-Error "Project at '$projectRoot' has no doc/project-config.json. The PF-TSK-059 blueprint bootstrap must precede registration. (For first-time scaffolding of a new project, use PF-TSK-059, which bootstraps the blueprint copy and then invokes this script in its Phase A.)"
        exit 1
    }

    # Refuse if project_id already set (idempotency check)
    $cfg = Get-Content -Raw -Path $configPath | ConvertFrom-Json -AsHashtable
    if ($cfg.ContainsKey('project_id') -and $cfg['project_id']) {
        Write-Error "Project at '$projectRoot' already has project_id '$($cfg['project_id'])'. Re-registration is not supported via this script. To rename, edit $($regInfo.FileName) directly. To rotate IDs, archive and re-register manually."
        exit 1
    }

    # Read central registries
    $registry = Read-CentralRegistry -ProducerRoot $producerRoot -FileName $regInfo.FileName
    $idReg    = Read-CentralIdRegistry -ProducerRoot $producerRoot
    $children = $registry[$regInfo.CollectionKey]

    # Refuse if path already in registry under a different ID
    foreach ($existingId in $children.Keys) {
        $existing = $children[$existingId]
        if ($existing.path -eq $projectRoot) {
            Write-Error "Path '$projectRoot' is already registered as $existingId (name: '$($existing.name)'). Refusing duplicate registration."
            exit 1
        }
        if ($existing.name -eq $Name) {
            Write-Warning "Name '$Name' already used by $existingId (path: '$($existing.path)'). Names should be unique for human readability — consider differentiating."
        }
    }

    # Consume the next child ID from the mnemonic-named pool (PF-PRO-068 P-14: FWK-APP -> APP).
    # A missing pool refuses loudly and is NEVER auto-created: silently minting from a $null
    # pool would coerce nextAvailable to 0 and issue the burned <MNEM>-000 slot.
    $pool = $idReg.prefixes[$mnemonic]
    if (-not $pool) {
        Write-Error "PF-id-registry-central.json has no '$mnemonic' pool — the child-ID pool carries the producer's mnemonic (project_id FWK-$mnemonic) and is created/rekeyed deliberately (P-14 rekeyed appdev's legacy 'PRJ' pool to 'APP'), never auto-created here. Investigate before re-running."
        exit 1
    }
    $nextN = [int]$pool.nextAvailable
    $childId = Format-ChildId -Prefix $mnemonic -N $nextN

    # Counter/registry consistency guard: the allocated key must be free
    if ($children.ContainsKey($childId)) {
        Write-Error "'$mnemonic' pool nextAvailable=$nextN allocates '$childId', but that key already exists in $($regInfo.FileName). The counter and the registry are inconsistent — investigate before re-running."
        exit 1
    }

    # Construct role-carrying entry (key/role congruence: mnemonic-NNN child keys carry role
    # 'project'; the version-pin field name is level data from the registry shape, PF-PRO-068 P-10)
    $newEntry = [ordered]@{
        name  = $Name
        role  = 'project'
        path  = $projectRoot
        added = (Get-Date -Format "yyyy-MM-dd")
    }
    $newEntry[$regInfo.PinField] = $null
    $newEntry['last_rollout']      = $null
    $newEntry['version_freeze']    = $false
    $newEntry['frozen_at_version'] = $null
    $newEntry['notes']             = $Notes

    if ($PSCmdlet.ShouldProcess("$childId — $($regInfo.FileName) + PF-id-registry-central.json + $configPath + $($regInfo.LedgerDirName)/$childId/", "Register $childId ($Name) at $projectRoot")) {

        # Write registry
        $children[$childId] = $newEntry
        $registry.metadata.updated = (Get-Date -Format "yyyy-MM-dd")
        Save-Json -Path (Join-Path -Path $producerRoot -ChildPath "process-framework-central/$($regInfo.FileName)") -Object $registry

        # Increment the central child-pool counter
        $idReg.prefixes[$mnemonic].nextAvailable = $nextN + 1
        $idReg.metadata.updated = (Get-Date -Format "yyyy-MM-dd")
        Save-Json -Path (Join-Path -Path $producerRoot -ChildPath "process-framework-central/PF-id-registry-central.json") -Object $idReg

        # Write project_id to project-config.json
        $cfg['project_id'] = $childId
        Save-Json -Path $configPath -Object $cfg

        # Provision project-local ID registry (PF-STA, PF-TMP prefixes)
        $localRegProvisioned = Initialize-ProjectLocalRegistry -ProjectRoot $projectRoot
        if ($localRegProvisioned) {
            Write-Host "  Provisioned doc/state-tracking/PF-id-registry-local.json (PF-STA, PF-TMP prefixes)"
        }

        # Create per-child migrations directory + empty ledger skeleton
        $migDir = Join-Path -Path $producerRoot -ChildPath "process-framework-central/$($regInfo.LedgerDirName)/$childId"
        if (-not (Test-Path -Path $migDir)) {
            New-Item -ItemType Directory -Path $migDir -Force | Out-Null
        }
        $ledgerPath = Join-Path -Path $migDir -ChildPath "pending-migrations.md"
        if (-not (Test-Path -Path $ledgerPath)) {
            $ledgerSkeleton = @"
# Pending Migrations — $childId ($Name)

> Per-project ledger of working-document migrations awaiting application by Framework Rollout Mode C (PF-TSK-088).
> Entries are written by Structure Change (PF-TSK-014) when a structural change in the framework requires corresponding edits to this project's working documents (doc/, test/, etc.).
> Apply entries via Mode C in cwd=Project sessions. See [pending-migration-entry-template](../../../../process-framework/templates/support/pending-migration-entry-template.md) for entry structure.

## Summary

| ID | Title | Status | Source FW Version | Backward-compatible | Resolved |
|----|-------|--------|-------------------|---------------------|----------|

## Pending entries
"@
            [System.IO.File]::WriteAllText($ledgerPath, $ledgerSkeleton + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  Created migrations ledger: $ledgerPath"
        }

        Write-Host ""
        Write-Host "✅ Registered $childId at: $projectRoot"
        Write-Host "   Name: $Name"
        Write-Host "   Notes: $(if ($Notes) { $Notes } else { '(none)' })"
        Write-Host "   Registry now contains $($children.Count) child row(s) — next-available ${mnemonic}: $($nextN + 1)"
        Write-Host ""
        Write-Host "Next step: roll out the framework to $childId via:"
        Write-Host "  pwsh.exe -ExecutionPolicy Bypass -File $producerRoot/blueprint/process-framework/scripts/rollout/Push-FrameworkUpdate.ps1 -Project $childId"
    }
}
