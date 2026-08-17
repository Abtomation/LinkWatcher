# Core.psm1
# Core infrastructure functions for PowerShell scripts
# Provides project root discovery, module loading, and ID generation

<#
.SYNOPSIS
Core infrastructure functions for PowerShell scripts across the project

.DESCRIPTION
This module provides essential infrastructure functionality:
- Project root discovery and caching
- Module loading with consistent error handling
- Project ID generation
- Directory resolution for project IDs

.NOTES
Version: 3.0 (Modularized from Common-ScriptHelpers v2.0)
Created: 2025-08-26
#>

# Configure UTF-8 encoding for consistent Unicode support
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# The shared resolution leaf module. Project root, declared role, the config read, the framework
# faces, the parent-pointer chain walk and central resolution have ONE implementation, there —
# Core re-exports them below, so this module's public surface is unchanged (PF-PRO-068 E4-g,
# closing PF-EVR-036 F4/F7/F8; before it, each of those existed twice, here and in IdRegistry).
# Imported at the top of the file so it lands in THIS module's session state and Core's own
# function bodies can call it (Script Development Quick Reference, "Sub-Module Function Scoping").
$script:WorkspaceResolutionPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "WorkspaceResolution.psm1"
Import-Module $script:WorkspaceResolutionPath -Force

# Global variables for cached paths. The project-root cache moved into WorkspaceResolution.psm1
# with Get-ProjectRoot itself.
$script:IdRegistryPath = $null
$script:DocumentManagementPath = $null
$script:ProjectConfig = $null
$script:DomainConfig = $null

function Get-ArtifactPrefix {
    <#
    .SYNOPSIS
    Returns this workspace's declared shipped-artifact ID family — the prefix its producer face mints framework-pool artifacts under (e.g. 'PF' at appdev, 'FB' at FrameworkBuilder) (PF-PRO-068 P-12a).

    .DESCRIPTION
    Reads artifact_prefix from doc/project-config.json — the workspace-local read; the allocation of
    record is the parent's framework-registry row (self-declared at the chain root, whose registry row
    carries parent: null). Introduced by the Substrate Hoist (PF-PRO-068 P-12a) as the variable-prefix
    resolver. Only the SHIPPED framework pools (TSK / GDE / TEM / FST, plus the hand-assigned
    MAI / VIS / INF) vary by workspace — a framework ships those into its children, so two minters
    genuinely collide. Portfolio-global central pools (PF-IMP/PRO/FEE/REV/EVR — one chain-root counter,
    P-3) and project-local pools (PF-STA / PF-TMP / PD-* / TE-*) are fixed and never resolve through
    here.

    Sibling of Get-BlueprintPath, sharing its no-fallback contract: a leaf role throws (a leaf authors
    no shipped framework artifacts — its local pools are received copies); a producer face without the
    key throws, naming the parent registry as the allocation of record. A silent default here would
    mint into another workspace's pool and surface only when the two trees meet at a rollout.

    The value is an explicitly configured allocation, conventionally the framework's mnemonic — never
    derived from it (FWK-APP's family is the grandfathered 'PF').

    .PARAMETER ProjectRoot
    Optional explicit project root override. When omitted, resolves via Get-ProjectRoot (cwd-based).
    Same test seam as Get-BlueprintPath: -ProjectRoot plus $env:FRAMEWORK_PROJECT_ROOT_OVERRIDE give
    fixtures full control; cross-workspace resolution is by composition, never implicit.

    .OUTPUTS
    String — the artifact family, shape ^[A-Z]{2,4}$ (e.g. 'PF', 'FB').

    .EXAMPLE
    $fam = Get-ArtifactPrefix   # 'PF' at appdev, 'FB' at FB
    $taskId = New-FrameworkDocument -IdPrefix "$fam-TSK" ...
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot
    )

    $projectRoot = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { Get-ProjectRoot } else { $ProjectRoot }
    $cfg = Read-WorkspaceConfig -ProjectRoot $projectRoot
    if ($cfg.ParseError) {
        throw "Get-ArtifactPrefix: doc/project-config.json at '$($cfg.Path)' could not be parsed ($($cfg.ParseError)). The artifact family cannot be resolved; repair the config."
    }
    $prefix = if ($cfg.Config) { $cfg.Config.artifact_prefix } else { $null }
    if (-not [string]::IsNullOrWhiteSpace($prefix)) {
        $prefix = $prefix.Trim()
        # Case-SENSITIVE shape check: default -match would admit 'fb'/'Pf' and mint a malformed family.
        if ($prefix -cnotmatch '^[A-Z]{2,4}$') {
            throw "Get-ArtifactPrefix: workspace '$projectRoot' declares artifact_prefix '$prefix', which is not a valid family (2-4 uppercase letters, e.g. 'PF', 'FB'). Fix the value in doc/project-config.json to match the parent registry's allocation (PF-PRO-068 P-12a)."
        }
        return $prefix
    }

    # Role decides which mistake this is — never a workspace-ID literal (convention gate, PF-PRO-067).
    $role = Get-WorkspaceRole -ProjectRoot $projectRoot
    if ($role -in @('framework', 'framework-builder')) {
        throw "Get-ArtifactPrefix: workspace '$projectRoot' declares role '$role' (a producer face) but its doc/project-config.json has no artifact_prefix. A producer face must declare the family it mints shipped framework artifacts under; the allocation of record is its parent's framework-registry row (self-declared at the chain root). Add artifact_prefix to the config to match that allocation (PF-PRO-068 P-12a)."
    }
    throw "Get-ArtifactPrefix: workspace '$projectRoot' has role '$role' — a leaf workspace authors no shipped framework artifacts, so there is no artifact family to resolve here. Shipped framework artifacts are minted at the owning framework workspace; to target it, pass -ProjectRoot with that workspace's root."
}

function Get-ChildRegistryInfo {
    <#
    .SYNOPSIS
    Returns the shape of this workspace's child registry — filename, top-level collection key,
    per-row version-pin field, accepted child roles, and sandbox key pattern — derived from the
    workspace's declared role (PF-PRO-068 P-10: one shared resolver, level differences are data).

    .DESCRIPTION
    The two live child registries differ in more than filename, so a filename-only resolver
    under-serves every consumer (measured, Sub-concept 3 Session 9):

      role 'framework'          -> project-registry.json,  key 'projects',   pin 'current_framework_version'
      role 'framework-builder'  -> framework-registry.json, key 'frameworks', pin 'current_substrate_version'

    Every rollout consumer (Push / Restore / Commit-SandboxBaseline / Register, plus the
    fan-out in New-PendingMigration) indexes the registry through this shape instead of
    hard-coding appdev's, so the same script operates from any producer face.

    Field semantics:
    - FileName / CollectionKey — where the child rows live and how they are indexed.
    - PinField — the per-row received-version field (Contract 5 per-edge pins). The names
      deliberately differ per level (framework vs substrate version) — that is recorded
      Session B design, so the difference is carried as data, never converged by code.
    - AcceptedChildRoles — which declared child roles this producer's fan-out serves; a row's
      ABSENT role reads as 'project' (the leaf default, PF-PRO-067 Contract 4). Push/Restore
      role guards compare against this instead of a hard-coded 'project', which at FB would
      exclude every child (the P-8 inversion, measured Session 9).
    - SandboxKeyPattern — rows matching it are sandboxes: excluded from FAN-OUT, always
      allowed as EXPLICIT targets (P-8; the fleet precedent is Resolve-EligibleProjects in
      New-PendingMigration.ps1). At a framework face the pattern DERIVES from the workspace's
      own declared identity (P-14: FWK-APP -> '^APP-T', FWK-LEG -> '^LEG-T'); a producer whose
      project_id is not FWK-shaped keeps the legacy '^PRJ-T' rung — the correct answer for the
      pre-P-13-shaped synthetic E2E worlds. The FWK-T shape is provisional — no FB sandbox row
      exists yet; it mirrors the mnemonic-T precedent the registry metadata cites.
    - LedgerDirName — the central migrations directory holding one per-child pending-migrations
      ledger (per-project-migrations at a framework face, per-framework-migrations at FB —
      Session B skeleton naming). Consumed by Register (ledger scaffold at registration) and,
      once FB-level fan-out is wired, by New-PendingMigration.

    A leaf role (project, subject) has no children and therefore no child registry — that
    throws, because every caller is a fan-out/rollout operation that is meaningless at a leaf.

    .PARAMETER ProjectRoot
    Optional explicit workspace root; defaults to Get-ProjectRoot (same contract as
    Get-WorkspaceRole, which this derives from).

    .OUTPUTS
    Hashtable — Role, FileName, CollectionKey, PinField, AcceptedChildRoles, SandboxKeyPattern,
    LedgerDirName.

    .EXAMPLE
    $reg = Get-ChildRegistryInfo
    $registry = Get-Content (Join-Path $centralRoot $reg.FileName) -Raw | ConvertFrom-Json -AsHashtable
    $children = $registry[$reg.CollectionKey]
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot
    )

    $role = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { Get-WorkspaceRole } else { Get-WorkspaceRole -ProjectRoot $ProjectRoot }

    switch ($role) {
        'framework-builder' {
            return @{
                Role               = $role
                FileName           = 'framework-registry.json'
                CollectionKey      = 'frameworks'
                PinField           = 'current_substrate_version'
                AcceptedChildRoles = @('framework')
                SandboxKeyPattern  = '^FWK-T'
                LedgerDirName      = 'per-framework-migrations'
            }
        }
        'framework' {
            # P-14: sandbox rows key <MNEMONIC>-T<NN>, so the pattern derives from the
            # framework's own declared identity (FWK-APP -> '^APP-T'), letting the same
            # substrate serve every framework. A producer whose project_id is not FWK-shaped
            # (the TE-E2E-012/013 synthetic seeds are deliberate pre-P-13-shaped worlds) keeps
            # the legacy '^PRJ-T' rung — quiet by design: the legacy shape IS that world's answer.
            $sandboxPattern = '^PRJ-T'
            $cfgRoot = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { Get-ProjectRoot } else { $ProjectRoot }
            $cfg = Read-WorkspaceConfig -ProjectRoot $cfgRoot
            if ($cfg.ParseError) {
                Write-Verbose "Get-ChildRegistryInfo: could not read project_id from '$($cfg.Path)' ($($cfg.ParseError)); SandboxKeyPattern keeps the legacy '^PRJ-T' shape."
            } elseif ($cfg.Config) {
                $ownDeclaredId = $cfg.Config.project_id
                if ($ownDeclaredId -cmatch '^FWK-([A-Z]{2,4})$') { $sandboxPattern = '^' + $Matches[1] + '-T' }
            }
            return @{
                Role               = $role
                FileName           = 'project-registry.json'
                CollectionKey      = 'projects'
                PinField           = 'current_framework_version'
                AcceptedChildRoles = @('project')
                SandboxKeyPattern  = $sandboxPattern
                LedgerDirName      = 'per-project-migrations'
            }
        }
        default {
            throw "Get-ChildRegistryInfo: workspace role '$role' declares no child registry — only producer-face roles (framework, framework-builder) fan out to children (PF-PRO-068 P-10). A leaf workspace is a rollout TARGET; run the rollout scripts from the owning producer's root."
        }
    }
}

function Get-ArtifactOwnerId {
    <#
    .SYNOPSIS
    Returns the workspace ID declared by a shipped artifact's N-5 ownership line, or $null when
    the file carries none (PF-PRO-067 N-5; PF-PRO-068 WI-5).

    .DESCRIPTION
    Every file the framework ships carries an ownership line naming the workspace that owns it —
    authored once at the owning workspace and shipped byte-identical, so a received copy states
    its own provenance. The per-language conventions are declared in payload-manifest.json
    (ownership_line_conventions) and read here:

      PowerShell  .NOTES line   'OWNERSHIP: FWK-FB (FrameworkBuilder) - ...'
      Python      header comment, same sentence
      Markdown    frontmatter   'owned_by: FWK-FB'
      JSON        'metadata.owned_by'

    Resolution is deliberately scoped to the file's LEADING header region — frontmatter, the
    opening comment/help block, and the blank lines between them — never the body. A guide that
    *documents* the convention, or a script whose prose quotes it, would otherwise report itself
    as owned by whatever ID that prose names. JSON has no comment syntax, so a .json file is
    parsed and read at metadata.owned_by instead.

    Returns $null — not an error — when no ownership line is present. An unmarked file is the
    pre-hoist state (appdev's blueprint carries no ownership lines until the cutover ships them),
    and every caller treats "unmarked" as "governed by this workspace", which is exactly the
    pre-hoist behavior. That is what keeps ownership-aware resolution DARK before the cutover.

    .PARAMETER Path
    Path to the artifact.

    .OUTPUTS
    String — the owning workspace ID (e.g. 'FWK-FB'), or $null when the file carries no
    ownership line or does not exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }

    if ([System.IO.Path]::GetExtension($Path) -ieq '.json') {
        try {
            $json = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
        } catch {
            Write-Verbose "Get-ArtifactOwnerId: '$Path' is not parseable JSON; treating as unmarked."
            return $null
        }
        if ($json.metadata -and $json.metadata.owned_by) { return "$($json.metadata.owned_by)".Trim() }
        return $null
    }

    # Header-region scan. The region ends at the first line that is neither blank, nor a line
    # comment, nor inside a block comment / frontmatter fence — i.e. at the first line of real
    # content. A shebang keeps the region open (it precedes the help block).
    $ownerPattern = '(?:OWNERSHIP:\s*|owned_by\s*:\s*"?)([A-Z][A-Z0-9]*-[A-Z0-9]+)'
    $inBlockComment = $false
    $inFrontmatter  = $false
    $lineNo = 0
    foreach ($line in (Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue)) {
        $lineNo++
        $trimmed = $line.Trim()

        if ($lineNo -eq 1 -and $trimmed -eq '---') { $inFrontmatter = $true; continue }
        if ($inFrontmatter) {
            if ($trimmed -eq '---') { $inFrontmatter = $false; continue }
        }
        elseif ($inBlockComment) {
            if ($trimmed -match '#>' -or $trimmed -match '^"""') { $inBlockComment = $false; continue }
        }
        else {
            if ($trimmed -match '^<#' -or $trimmed -match '^"""') {
                # A block comment that also CLOSES on its opening line ('<# banner #>',
                # '"""doc."""') must NOT flag the region open: its closer is consumed here, so
                # flagging would leave the scan open for the rest of the file and let body prose
                # satisfy the marker pattern — the exact false positive this scan exists to
                # prevent. Falling through instead keeps the line scannable, so a self-contained
                # '<# OWNERSHIP: FWK-XX ... #>' still reads.
                $opensAndCloses = ($trimmed -match '^<#.*#>') -or ($trimmed -match '^""".*"""')
                if (-not $opensAndCloses) { $inBlockComment = $true; continue }
            }
            # Outside every comment construct: blank lines, '#' comments and a shebang keep the
            # header region open; anything else is the first line of content — stop.
            elseif ($trimmed -ne '' -and $trimmed -notmatch '^#') { break }
        }

        if ($line -match $ownerPattern) { return $Matches[1] }
    }
    return $null
}

function Resolve-WorkspaceRootById {
    <#
    .SYNOPSIS
    Returns the workspace root of the chain member whose declared project_id equals $WorkspaceId
    (PF-PRO-068 WI-5).

    .DESCRIPTION
    Identity in this portfolio is the workspace's key in its parent's registry, declared as
    project_id in doc/project-config.json (PF-PRO-068 P-13's identity rule). This helper turns
    such an ID back into a filesystem root by walking the SAME parent-pointer chain
    Get-ChainRootPath walks — start workspace first, then each parent up to the chain root —
    and comparing each hop's declared project_id.

    Chain membership is the whole search space by design: a workspace can only resolve the
    workspaces it is federated with. An ID that names something off-chain is a configuration
    error, not a lookup miss, so it throws with the walked chain named (the no-silent-fallback
    invariant — a silent miss here would route state writes to the wrong workspace's central).

    .PARAMETER WorkspaceId
    The declared workspace ID to find (e.g. 'FWK-FB', 'FWK-APP').

    .PARAMETER StartRoot
    Optional workspace root to start the walk from. Defaults to Get-ProjectRoot.

    .OUTPUTS
    String — absolute, canonicalized workspace root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$WorkspaceId,

        [Parameter(Mandatory=$false)]
        [string]$StartRoot
    )

    $current = if ([string]::IsNullOrWhiteSpace($StartRoot)) { Get-ProjectRoot } else { $StartRoot }
    $current = ConvertTo-CanonicalWorkspacePath -Path $current
    $walked = [System.Collections.Generic.List[string]]::new()

    for ($hop = 0; $hop -lt (Get-ParentChainHopCap); $hop++) {
        $cfg = Read-WorkspaceConfig -ProjectRoot $current
        $declaredId = $null
        if ($cfg.ParseError) {
            Write-Warning "Resolve-WorkspaceRootById: doc/project-config.json at '$($cfg.Path)' could not be parsed ($($cfg.ParseError)); this hop cannot be matched by identity."
        } elseif ($cfg.Config) {
            $declaredId = $cfg.Config.project_id
        }
        $walked.Add("$current (project_id: $(if ($declaredId) { $declaredId } else { '<none>' }))")
        if ($declaredId -and $declaredId -eq $WorkspaceId) { return $current }

        # Same single-hop step as Get-ChainRootPath: no pointer, or a self-pointer, is the root.
        $fwDir = Get-ProcessFrameworkPath -ProjectRoot $current
        $pointerPath = Get-ParentPointerFile -FrameworkDir $fwDir
        if ($null -eq $pointerPath) { break }
        $rawPointer = Get-Content -Path $pointerPath -Raw
        $parentRaw = if ($null -ne $rawPointer) { $rawPointer.Trim() } else { '' }
        if (-not $parentRaw) {
            throw "Resolve-WorkspaceRootById: the parent pointer at $pointerPath is empty. Re-run the parent workspace's Push-FrameworkUpdate.ps1 to repair."
        }
        $parent = ConvertTo-CanonicalWorkspacePath -Path $parentRaw
        if ($parent -ieq $current) { break }
        if (-not (Test-Path $parent)) {
            throw "Resolve-WorkspaceRootById: the parent pointer at $pointerPath points to '$parentRaw', but that workspace root does not exist. The pointer target is stale — correct the pointer, or re-run the parent's Push-FrameworkUpdate.ps1."
        }
        $current = $parent
    }

    throw "Resolve-WorkspaceRootById: no workspace declaring project_id '$WorkspaceId' was found on the parent-pointer chain. Walked: $($walked -join ' -> '). Either the artifact's ownership line names a workspace this one is not federated with, or a chain member's doc/project-config.json declares the wrong project_id."
}

function Get-OwningWorkspaceCentralPath {
    <#
    .SYNOPSIS
    Returns the process-framework-central/ of the workspace that OWNS a given artifact — the home
    of that artifact's framework state, regardless of which workspace invoked it (PF-PRO-068 WI-5).

    .DESCRIPTION
    Some framework state is keyed to the ARTIFACT rather than to the caller: soak verification
    counts invocations of one canonical script, so its row must live in one place no matter how
    many workspaces run their received copies. Resolving such state through the caller's own
    central instead splits one counter across every consumer, and — worse — lets a received copy
    silently register a fresh row at each consumer, which reads as "never soaked" forever.

    Resolution:
      1. No ownership line (Get-ArtifactOwnerId returns $null) -> Get-CentralFrameworkPath, i.e.
         exactly the pre-hoist behavior. Unmarked is the pre-cutover state of every appdev
         blueprint file, which is what makes this helper dark before the cutover.
      2. Owner is this workspace          -> Get-CentralFrameworkPath  (honors FRAMEWORK_CENTRAL_OVERRIDE)
      3. Owner is the chain root          -> Get-RootCentralFrameworkPath (honors both override axes)
      4. Owner is an intermediate parent  -> <owner root>/process-framework-central

    Cases 2 and 3 delegate rather than re-deriving, so every existing single-axis test fixture
    keeps its exact current meaning and the two-axis seam works unchanged.

    A resolved owner whose declared role is not a producer face throws: only framework and
    framework-builder workspaces have a central of their own, so an ownership line naming a leaf
    is a classification error rather than something to fall back from.

    .PARAMETER ArtifactPath
    Path to the artifact whose owning workspace should be resolved.

    .OUTPUTS
    String — absolute path to the owning workspace's process-framework-central/.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ArtifactPath
    )

    $ownerId = Get-ArtifactOwnerId -Path $ArtifactPath
    if (-not $ownerId) { return (Get-CentralFrameworkPath) }

    $projectRoot = ConvertTo-CanonicalWorkspacePath -Path (Get-ProjectRoot)
    $ownerRoot = Resolve-WorkspaceRootById -WorkspaceId $ownerId -StartRoot $projectRoot

    if ($ownerRoot -ieq $projectRoot) { return (Get-CentralFrameworkPath) }
    if ($ownerRoot -ieq (Get-ChainRootPath -StartRoot $projectRoot)) { return (Get-RootCentralFrameworkPath) }

    $ownerRole = Get-WorkspaceRole -ProjectRoot $ownerRoot
    if ($ownerRole -notin @('framework', 'framework-builder')) {
        throw "Get-OwningWorkspaceCentralPath: '$ArtifactPath' declares owner '$ownerId', which resolves to '$ownerRoot' — a workspace with role '$ownerRole'. Only producer faces (framework / framework-builder) hold a central of their own, so this ownership line is a classification error."
    }
    $centralPath = Join-Path -Path $ownerRoot -ChildPath "process-framework-central"
    if (-not (Test-Path $centralPath)) {
        throw "Get-OwningWorkspaceCentralPath: '$ArtifactPath' is owned by '$ownerId' at '$ownerRoot', but that workspace has no process-framework-central directory: $centralPath. Create it at the owning workspace, or correct the artifact's ownership line."
    }
    return $centralPath
}

function Import-ProjectModule {
    <#
    .SYNOPSIS
    Imports a project module with standardized error handling

    .PARAMETER ModuleName
    The name of the module to import (IdRegistry, DocumentManagement)

    .PARAMETER Required
    Whether the module is required (throws error if not found)

    .EXAMPLE
    Import-ProjectModule -ModuleName "IdRegistry" -Required
    Import-ProjectModule -ModuleName "DocumentManagement"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("IdRegistry", "DocumentManagement")]
        [string]$ModuleName,

        [Parameter(Mandatory=$false)]
        [switch]$Required
    )

    $projectRoot = Get-ProjectRoot
    $fwDir = Get-ProcessFrameworkPath  # Phase 5.5: resolves via paths.process_framework (configurable)

    switch ($ModuleName) {
        "IdRegistry" {
            if (-not $script:IdRegistryPath) {
                $script:IdRegistryPath = Join-Path -Path $fwDir -ChildPath "scripts/IdRegistry.psm1"
            }
            $modulePath = $script:IdRegistryPath
        }
        "DocumentManagement" {
            if (-not $script:DocumentManagementPath) {
                # Try multiple possible locations (relative to project root and framework subtree)
                $candidates = @(
                    (Join-Path -Path $projectRoot -ChildPath "scripts/DocumentManagement.psm1"),
                    (Join-Path -Path $fwDir       -ChildPath "scripts/DocumentManagement.psm1"),
                    (Join-Path -Path $fwDir       -ChildPath "methodologies/documentation-tiers/scripts/DocumentManagement.psm1")
                )

                foreach ($candidate in $candidates) {
                    if (Test-Path $candidate) {
                        $script:DocumentManagementPath = $candidate
                        break
                    }
                }
            }
            $modulePath = $script:DocumentManagementPath
        }
    }

    if (-not $modulePath -or -not (Test-Path $modulePath)) {
        $message = "Module '$ModuleName' not found. Expected at: $modulePath"
        if ($Required) {
            throw $message
        } else {
            Write-Warning $message
            return $false
        }
    }

    try {
        Import-Module $modulePath -Force -ErrorAction Stop
        Write-Verbose "Successfully imported $ModuleName from $modulePath"
        return $true
    }
    catch {
        $message = "Failed to import module '$ModuleName': $($_.Exception.Message)"
        if ($Required) {
            throw $message
        } else {
            Write-Warning $message
            return $false
        }
    }
}

function New-ProjectId {
    <#
    .SYNOPSIS
    Creates a new project ID with standardized error handling

    .PARAMETER Prefix
    The ID prefix (e.g., "PF-TSK", "PF-FEE")

    .PARAMETER Description
    Description for the ID registry

    .EXAMPLE
    $taskId = New-ProjectId -Prefix "PF-TSK" -Description "Bug fixing task: Fix login issue"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prefix,

        [Parameter(Mandatory=$true)]
        [string]$Description
    )

    # Ensure IdRegistry is loaded
    Import-ProjectModule -ModuleName "IdRegistry" -Required | Out-Null

    try {
        $id = New-NextId -Prefix $Prefix -Description $Description
        Write-Verbose "Generated ID: $id"
        return $id
    }
    catch {
        throw "Failed to generate ID with prefix '$Prefix': $($_.Exception.Message)"
    }
}

function Get-ProjectIdDirectory {
    <#
    .SYNOPSIS
    Gets the appropriate directory for a document with a specific prefix

    .PARAMETER Prefix
    The ID prefix (e.g., "PF-TSK", "PF-FEE")

    .PARAMETER DirectoryType
    Semantic directory type (e.g., "discrete", "tier1", "active") - preferred over DirectoryIndex

    .PARAMETER DirectoryIndex
    Index of directory to use (0 = default/first directory) - legacy support

    .PARAMETER CreateIfMissing
    Create the directory if it doesn't exist

    .EXAMPLE
    $outputDir = Get-ProjectIdDirectory -Prefix "PF-TSK" -DirectoryType "discrete" -CreateIfMissing
    # Returns: "C:\Project\doc\process-framework\tasks\discrete"

    .EXAMPLE
    $outputDir = Get-ProjectIdDirectory -Prefix "PF-FEE" -CreateIfMissing
    # Returns: "C:\Project\doc\process-framework\feedback\feedback-forms" (default)
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prefix,

        [Parameter(Mandatory=$false)]
        [string]$DirectoryType,

        [Parameter(Mandatory=$false)]
        [int]$DirectoryIndex = 0,

        [Parameter(Mandatory=$false)]
        [switch]$CreateIfMissing
    )

    # Ensure IdRegistry is loaded
    Import-ProjectModule -ModuleName "IdRegistry" -Required | Out-Null

    try {
        $projectRoot = Get-ProjectRoot

        if ($DirectoryType) {
            # Use semantic directory type (preferred)
            $targetDirectory = Get-PrefixDirectories -Prefix $Prefix -DirectoryType $DirectoryType -ProjectRoot $projectRoot
        } else {
            # Fallback to index-based selection or default
            if ($DirectoryIndex -eq 0) {
                # Use default directory
                $targetDirectory = Get-DefaultDirectoryForPrefix -Prefix $Prefix -ProjectRoot $projectRoot
            } else {
                # Use specific index (legacy support)
                $directories = Get-PrefixDirectories -Prefix $Prefix -ProjectRoot $projectRoot

                if ($DirectoryIndex -ge $directories.Count) {
                    throw "Directory index $DirectoryIndex is out of range. Available directories: $($directories.Count)"
                }

                $targetDirectory = $directories[$DirectoryIndex]
            }
        }

        if ($CreateIfMissing) {
            # Import OutputFormatting module for Test-ProjectPath function
            $outputFormattingPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers/OutputFormatting.psm1"
            if (Test-Path $outputFormattingPath) {
                Import-Module $outputFormattingPath -Force
                Test-ProjectPath -Path $targetDirectory -CreateIfMissing -PathType Directory | Out-Null
            } else {
                # Fallback to basic directory creation
                if (-not (Test-Path $targetDirectory)) {
                    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
                }
            }
        }

        return $targetDirectory
    }
    catch {
        throw "Failed to get directory for prefix '$Prefix': $($_.Exception.Message)"
    }
}

function Get-ProjectConfig {
    <#
    .SYNOPSIS
    Loads and caches the project-config.json file

    .DESCRIPTION
    Loads project-specific configuration from doc/project-config.json
    Caches the result for performance

    .PARAMETER Reload
    Force reload of the configuration file

    .EXAMPLE
    $config = Get-ProjectConfig
    $projectName = $config.project.name
    $projectRoot = $config.project.root_directory
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Reload
    )

    if ($script:ProjectConfig -and -not $Reload) {
        return $script:ProjectConfig
    }

    try {
        $projectRoot = Get-ProjectRoot
        $configPath = Join-Path -Path $projectRoot -ChildPath "doc/project-config.json"

        if (-not (Test-Path $configPath)) {
            throw "Project configuration file not found at: $configPath"
        }

        $script:ProjectConfig = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        Write-Verbose "Loaded project configuration from $configPath"
        return $script:ProjectConfig
    }
    catch {
        throw "Failed to load project configuration: $($_.Exception.Message)"
    }
}

function Get-DomainConfig {
    <#
    .SYNOPSIS
    Loads and caches the domain-config.json file

    .DESCRIPTION
    Loads domain-specific configuration from process-framework/domain-config.json
    Caches the result for performance

    .PARAMETER Reload
    Force reload of the configuration file

    .EXAMPLE
    $config = Get-DomainConfig
    $domain = $config.domain
    $workflowPhases = $config.workflow_phases.values
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Reload
    )

    if ($script:DomainConfig -and -not $Reload) {
        return $script:DomainConfig
    }

    try {
        # Phase 5.5: resolves via paths.process_framework (configurable) so this works in both
        # the appdev blueprint layout (blueprint/process-framework/) and rolled-out projects.
        $fwDir = Get-ProcessFrameworkPath
        $configPath = Join-Path -Path $fwDir -ChildPath "domain-config.json"

        if (-not (Test-Path $configPath)) {
            throw "Domain configuration file not found at: $configPath"
        }

        $script:DomainConfig = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        Write-Verbose "Loaded domain configuration from $configPath"
        return $script:DomainConfig
    }
    catch {
        throw "Failed to load domain configuration: $($_.Exception.Message)"
    }
}

function Get-StateTrackingContext {
    <#
    .SYNOPSIS
    Returns the state-tracking routing context, routing to the workspace's own central for
    producer-face workspaces and to doc/state-tracking/ for leaf projects.

    .DESCRIPTION
    Reads the declared workspace role (Get-WorkspaceRole; PF-PRO-067 Contract 4). A
    producer-face workspace (role 'framework' or 'framework-builder') routes its own
    framework-management state (temp state files, PF-STA registry, permanent IMP tracking,
    etc.) to <root>/process-framework-central/ — producer-face state lives in the workspace's
    own central because such a workspace's own work IS framework development (two-faces model;
    this rationale replaced the stale pre-2026-05-17 "appdev/doc/ is the blueprint" one, and
    the branch replaced the project_id == "PRJ-000" identity comparison). Leaf projects
    (role 'project', including the absent-field default) write state to
    <project>/doc/state-tracking/.

    State-creating scripts should consume this helper for OutputDirectory and registry paths,
    so the same script binary works correctly whichever workspace it runs in.

    .OUTPUTS
    PSCustomObject with properties:
    - Mode: "central" (producer-face workspace) or "project" (leaf)
    - StateTrackingRoot: absolute path to the state-tracking directory
        appdev  → <projectRoot>/process-framework-central/state-tracking
        project → <projectRoot>/doc/state-tracking
    - StateTrackingRelative: relative path from project root (for OutputDirectory parameters
      that get joined with project root downstream)
        appdev  → "process-framework-central/state-tracking"
        project → "doc/state-tracking"
    - RegistryPath: absolute path to the registry file holding project-local PF-STA prefix
        appdev  → <projectRoot>/process-framework-central/PF-id-registry-central.json
        project → <projectRoot>/doc/state-tracking/PF-id-registry-local.json

    The equivalent private helper Resolve-LocalRegistryPath in IdRegistry.psm1 returns the
    same RegistryPath value via the same declared-role contract (inlined there to avoid a
    circular import: Common-ScriptHelpers/DocumentManagement.psm1 imports IdRegistry).

    .EXAMPLE
    $context = Get-StateTrackingContext
    $tempDir = "$($context.StateTrackingRelative)/temporary"
    # appdev  → "process-framework-central/state-tracking/temporary"
    # project → "doc/state-tracking/temporary"
    #>

    [CmdletBinding()]
    param()

    $projectRoot = Get-ProjectRoot

    # Role question: "am I the central hub?" — producer-face workspaces route own state to
    # their own central (PF-PRO-067 Contract 4; declared, never inferred from a workspace ID).
    $role = Get-WorkspaceRole -ProjectRoot $projectRoot

    if ($role -in @('framework', 'framework-builder')) {
        return [PSCustomObject]@{
            Mode = "central"
            StateTrackingRoot = Join-Path -Path $projectRoot -ChildPath "process-framework-central\state-tracking"
            StateTrackingRelative = "process-framework-central/state-tracking"
            RegistryPath = Join-Path -Path $projectRoot -ChildPath "process-framework-central\PF-id-registry-central.json"
        }
    }

    return [PSCustomObject]@{
        Mode = "project"
        StateTrackingRoot = Join-Path -Path $projectRoot -ChildPath "doc\state-tracking"
        StateTrackingRelative = "doc/state-tracking"
        RegistryPath = Join-Path -Path $projectRoot -ChildPath "doc\state-tracking\PF-id-registry-local.json"
    }
}

function Resolve-DocPath {
    <#
    .SYNOPSIS
    Resolves a path relative to the project's doc/ tree, driven by paths.documentation_root in project-config.json.

    .DESCRIPTION
    Reads paths.documentation_root from <projectRoot>/doc/project-config.json and joins Subpath under it.
    Defaults to "doc" when the field is absent (matches the historical project default).

    For appdev (FWK-APP), paths.documentation_root is "doc" — appdev's own workspace state lives at
    <projectRoot>/doc/ (post-Phase-5.5 layout: <projectRoot>/blueprint/doc/ is rolled-out template
    material, not appdev's own state). Scripts that explicitly need the blueprint template should
    hardcode "blueprint/doc/..." rather than going through this resolver.

    Created 2026-05-14 (PF-IMP-871 / PF-PRO-034 Session 3); refactored 2026-05-17 (Framework Self-
    Testing extension PF-PRO-035, Phase 3a-continuation) — replaced PRJ-000 → blueprint/doc/ hardcoding
    with config-driven lookup so appdev's framework-self-test workflow tracking at appdev/doc/ resolves
    correctly.

    .PARAMETER Subpath
    Path relative to the doc/ root, with forward or backward slashes.

    .EXAMPLE
    $featureTracking = Resolve-DocPath -Subpath "state-tracking/permanent/feature-tracking.md"
    # config-driven: <root>/$($cfg.paths.documentation_root)/state-tracking/permanent/feature-tracking.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Subpath
    )

    $projectRoot = Get-ProjectRoot
    $configPath = Join-Path -Path $projectRoot -ChildPath "doc/project-config.json"

    $docRoot = "doc"
    if (Test-Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            if ($config.paths -and $config.paths.documentation_root) {
                $docRoot = $config.paths.documentation_root
            }
        } catch {
            # Fall through to default
        }
    }

    return Join-Path -Path (Join-Path -Path $projectRoot -ChildPath $docRoot) -ChildPath $Subpath
}

function Resolve-TrackingFilePath {
    <#
    .SYNOPSIS
    Resolves the absolute path to one of the four parameterizable tracking files.

    .DESCRIPTION
    For the three test-tracking files, reads the matching paths.*_tracking_dir field from
    doc/project-config.json (defaults to "test/state-tracking/permanent" when the field is
    absent — matches historical hardcoded behavior in pre-extension projects).

    For user-workflow-tracking.md, delegates to Resolve-DocPath (which reads
    paths.documentation_root) since that file lives under the project's doc tree.

    Added 2026-05-17 by Framework Self-Testing extension Phase 3a-continuation #2 to replace
    scattered `Join-Path $projectRoot "test/state-tracking/permanent/<file>"` patterns across
    ~17 framework scripts. For appdev (FWK-APP), the configured paths resolve to appdev's own
    framework-self-test state files; for regular projects, the defaults match the historical
    hardcoded paths exactly.

    .PARAMETER File
    Which tracking file to resolve. One of:
    - "test-tracking.md"             → paths.test_tracking_dir (default: test/state-tracking/permanent)
    - "e2e-test-tracking.md"         → paths.e2e_test_tracking_dir (default: test/state-tracking/permanent)
    - "performance-test-tracking.md" → paths.performance_test_tracking_dir (default: test/state-tracking/permanent)
    - "user-workflow-tracking.md"    → Resolve-DocPath (paths.documentation_root, default: doc) + "state-tracking/permanent"

    .OUTPUTS
    String — absolute path to the tracking file (may not exist on disk; caller should Test-Path).

    .EXAMPLE
    $ttPath = Resolve-TrackingFilePath -File "test-tracking.md"
    if (-not (Test-Path $ttPath)) { Write-Warning "test-tracking.md missing at $ttPath" }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("test-tracking.md", "e2e-test-tracking.md", "performance-test-tracking.md", "user-workflow-tracking.md")]
        [string]$File
    )

    if ($File -eq "user-workflow-tracking.md") {
        return (Resolve-DocPath -Subpath "state-tracking/permanent/user-workflow-tracking.md")
    }

    $projectRoot = Get-ProjectRoot
    $configPath = Join-Path -Path $projectRoot -ChildPath "doc/project-config.json"

    $dir = "test/state-tracking/permanent"

    if (Test-Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            if ($config.paths) {
                $fieldName = switch ($File) {
                    "test-tracking.md"             { "test_tracking_dir" }
                    "e2e-test-tracking.md"         { "e2e_test_tracking_dir" }
                    "performance-test-tracking.md" { "performance_test_tracking_dir" }
                }
                $configuredDir = $config.paths.$fieldName
                if ($configuredDir) { $dir = $configuredDir }
            }
        } catch {
            # Fall through to default
        }
    }

    return (Join-Path -Path $projectRoot -ChildPath (Join-Path -Path $dir -ChildPath $File))
}

function Test-MSYSPathMangled {
    <#
    .SYNOPSIS
    Detects MSYS path-mangled values in user-supplied path parameters and emits a remediation error.

    .DESCRIPTION
    On Windows + Git Bash, paths starting with a leading slash (e.g. "/doc/x.md") are silently
    rewritten by MSYS to absolute Git-installation paths (e.g. "C:/Program Files/Git/doc/x.md")
    before PowerShell receives them — landing mangled values in tracking files or document
    metadata. This helper detects the mangled-prefix signature ("Program Files/Git") and emits a
    standardized Write-Error directing the user to drop the leading slash.

    Returns $true when the value IS mangled (caller should abort), $false otherwise. Empty / null
    inputs return $false silently so optional parameters can call this unconditionally.

    Added 2026-05-26 by PF-IMP-767 to hoist the detect-and-reject pattern previously inlined in
    Update-TechDebt.ps1 (-PlanLink) and New-TestSpecification.ps1 (-TddPath). 5 adopters at
    extraction time.

    .PARAMETER Path
    The path value as received from the caller. May be empty / null; both return $false.

    .PARAMETER ParameterName
    The name of the parameter being validated (e.g. "TddPath", "SourceLink"). Surfaced in the
    error message so the user can locate the offending argument in their command.

    .OUTPUTS
    Boolean — $true if the path is MSYS-mangled (caller should exit / return null), $false if safe.

    .EXAMPLE
    if (Test-MSYSPathMangled -Path $TddPath -ParameterName 'TddPath') { exit 1 }

    .EXAMPLE
    if ($SourceLink -and (Test-MSYSPathMangled -Path $SourceLink -ParameterName 'SourceLink')) {
        return $null
    }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ParameterName
    )

    if ([string]::IsNullOrEmpty($Path)) { return $false }

    if ($Path -match 'Program Files/Git') {
        Write-Error "$ParameterName appears MSYS-mangled (contains 'Program Files/Git'): '$Path'. On Windows + bash, leading-slash paths are rewritten by MSYS before PowerShell sees them. Use a relative path without leading slash (e.g. 'doc/path/to/file.md'), not '/doc/...'."
        return $true
    }

    return $false
}

function Get-EffectiveWhatIf {
    <#
    .SYNOPSIS
    Determines whether a module function is running under an effective -WhatIf (preview),
    including a -WhatIf bound on a caller across a module session-state boundary.

    .DESCRIPTION
    Module (.psm1) functions have their own session state and do NOT inherit the
    caller's $WhatIfPreference. A .ps1 invoked with -WhatIf therefore does not, on its
    own, put a downstream module function into preview mode. This helper centralizes the
    call-stack-walk idiom that detects an explicit -WhatIf:$true bound in ANY caller
    frame, together with the local short-circuits (the function's own $WhatIfPreference
    and an optional -DryRun flag).

    Extracted (PF-IMP-939) from two byte-for-byte-equivalent inline implementations in
    New-StandardProjectDocument (DocumentManagement.psm1) and Invoke-DesignArtifactCreation
    (DesignArtifactCreation.psm1) so the fragile module-boundary propagation lives in one
    canonical, tested place.

    .PARAMETER WhatIfPreference
    The calling function's own $WhatIfPreference. If $true the result is $true
    immediately (binding -WhatIf:$true on a SupportsShouldProcess function sets this).

    .PARAMETER DryRun
    Optional explicit preview switch, for pipelines that expose both -DryRun and -WhatIf.
    If present the result is $true.

    .PARAMETER WhatIfBound
    Pass $PSBoundParameters.ContainsKey('WhatIf') from the caller. When $true (and
    $WhatIfPreference is $false — i.e. an explicit -WhatIf:$false was bound to this call),
    the call-stack walk is SKIPPED so an ancestor's -WhatIf:$true cannot override the
    caller's explicit -WhatIf:$false. Omit (default $false) to always walk when not
    already in preview.

    .OUTPUTS
    Boolean — $true if the operation should be treated as a -WhatIf preview.

    .EXAMPLE
    # Respect an explicit -WhatIf:$false pushed in from a wrapper (New-StandardProjectDocument):
    $WhatIfPreference = Get-EffectiveWhatIf -WhatIfPreference $WhatIfPreference `
        -WhatIfBound:$PSBoundParameters.ContainsKey('WhatIf')

    .EXAMPLE
    # -DryRun OR -WhatIf, no explicit-bind guard needed (Invoke-DesignArtifactCreation):
    $isPreview = Get-EffectiveWhatIf -WhatIfPreference $WhatIfPreference -DryRun:$DryRun
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$WhatIfPreference = $false,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [bool]$WhatIfBound = $false
    )

    # Local short-circuits: already in preview via own preference or explicit -DryRun.
    if ($WhatIfPreference -or $DryRun) { return $true }

    # An explicit -WhatIf was bound to the caller and resolved to $false (otherwise
    # $WhatIfPreference would have been $true above). Respect it — do NOT let an
    # ancestor's -WhatIf:$true flip preview back on.
    if ($WhatIfBound) { return $false }

    # Walk the call stack for an explicit -WhatIf:$true in any caller frame.
    foreach ($frame in Get-PSCallStack) {
        $bound = $frame.InvocationInfo.BoundParameters
        if ($bound.ContainsKey('WhatIf') -and $bound['WhatIf'] -eq $true) {
            return $true
        }
    }

    return $false
}

function Get-NonFeatureTestDir {
    <#
    .SYNOPSIS
    Returns the canonical directory-name exclusion list for source/test-tree scans.

    .DESCRIPTION
    Single source of truth for "directory names that are NOT feature-organized
    source/test code." Consumed by Validate-StateTracking.ps1 (Surfaces 14/16/17)
    and New-TestInfrastructure.ps1 so a new validation surface or scaffolder cannot
    silently diverge — the recurring root cause of PF-IMP-956 / PF-IMP-979 / PF-IMP-1152.

    The categories are composed internally so future additions stay principled:
    - Runtime/cache artifacts: build / VCS / dependency / venv / test-cache dirs that
      are noise in every tree.
    - Data-only support dirs:  committed test data (fixtures/) and shared test helpers
      (helpers/, the language-pack testSetup dir) with no audit mirror (PF-IMP-1387).
    - Self-test trees:         the appdev framework self-test tree (framework/), which
      exercises framework scripts rather than product features and is therefore exempt
      from the audit-mirror (Surface 16) and category-alignment (Surface 17) invariants
      (PF-IMP-1190).

    Matching is by directory base name (a path segment equal to one of these names),
    consistent with how callers apply the list.

    .PARAMETER Scope
    RuntimeCache : runtime/cache artifacts only — for source-tree scans (Surface 14,
                   New-SourceStructure.ps1) and audit/auto dir-map computation, where
                   only build/VCS noise should be skipped.
    TestTree     : RuntimeCache + data-only support dirs + self-test trees — for the
                   audit-mirror (Surface 16) and category-alignment (Surface 17)
                   invariants. This is the default.

    .EXAMPLE
    $skip = Get-NonFeatureTestDir -Scope RuntimeCache
    Get-ChildItem $root -Directory | Where-Object { $skip -notcontains $_.Name }

    .OUTPUTS
    System.String[] — directory base names.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [ValidateSet('RuntimeCache', 'TestTree')]
        [string]$Scope = 'TestTree'
    )

    $runtimeCache = @('__pycache__', '.pytest_cache', '.git', 'node_modules', '.venv', 'venv')
    $dataOnly     = @('fixtures', 'helpers')
    $selfTestTree = @('framework')

    switch ($Scope) {
        'RuntimeCache' { , $runtimeCache }
        'TestTree'     { , ($runtimeCache + $dataOnly + $selfTestTree) }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-ProjectRoot',
    'Get-ProcessFrameworkPath',
    'Get-BlueprintPath',
    'Get-ArtifactPrefix',
    'Get-WorkspaceRole',
    'Get-ChildRegistryInfo',
    'Get-CentralFrameworkPath',
    'ConvertTo-CanonicalWorkspacePath',
    'Get-ChainRootPath',
    'Get-RootCentralFrameworkPath',
    'Get-ArtifactOwnerId',
    'Resolve-WorkspaceRootById',
    'Get-OwningWorkspaceCentralPath',
    'Import-ProjectModule',
    'New-ProjectId',
    'Get-ProjectIdDirectory',
    'Get-ProjectConfig',
    'Get-DomainConfig',
    'Get-StateTrackingContext',
    'Resolve-DocPath',
    'Resolve-TrackingFilePath',
    'Test-MSYSPathMangled',
    'Get-EffectiveWhatIf',
    'Get-NonFeatureTestDir'
)
