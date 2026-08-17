# IdRegistry.psm1
# Central ID management module for process framework projects
# Uses domain-specific ID registries (PF/PD/TE-id-registry.json) to manage document IDs

<#
.SYNOPSIS
Central ID management for process-framework projects — registry resolution, ID generation, and prefix/directory lookups.
#>

# The shared resolution leaf module — project root, declared role, the config read, the framework
# faces, the parent-pointer chain walk and central resolution, in ONE implementation (PF-PRO-068
# E4-g, closing PF-EVR-036 F4/F7/F8). Until E4-g this module carried its own inlined twin of each,
# because Common-ScriptHelpers/DocumentManagement.psm1 imports IdRegistry and so IdRegistry could
# never import Common-ScriptHelpers. WorkspaceResolution.psm1 imports nothing, so it closes no
# cycle and both sides can share it. Imported at the top of the file so it lands in THIS module's
# session state (Script Development Quick Reference, "Sub-Module Function Scoping").
$script:WorkspaceResolutionPath = Join-Path -Path $PSScriptRoot -ChildPath "WorkspaceResolution.psm1"
Import-Module $script:WorkspaceResolutionPath -Force

function Resolve-RegistryPath {
    <#
    .SYNOPSIS
    Resolves a registry-declared directory path against the project root, face-aware: Write-face
    callers resolve process-framework/ paths against the tree this workspace authors, Read-face
    callers against the operative/consumer tree (PF-PRO-068 face fix).

    .DESCRIPTION
    Registry entries often declare paths like "process-framework/tasks", which historically
    assumed process-framework/ lived at the project root. After the Phase 5.5 reorg of the
    Centralized Framework Management extension, appdev relocated the subtree to
    blueprint/process-framework/, and the paths.* keys in project-config.json tell callers where
    the trees live. WHICH key applies is the face of the call, dispatched by the shared
    Get-WorkspaceFaceDir in WorkspaceResolution.psm1 (see its help for the contract):

      -Face Write (default) — where framework artifacts and their registry are AUTHORED:
        paths.blueprint at a producer role (absent key throws — no-fallback contract),
        paths.process_framework at a leaf.
      -Face Read — the operative/consumer tree via paths.process_framework, always. Exists for
        the chain walk's parent-pointer probe: the pointer is deployed INTO the consumer face by
        the parent's rollout, so probing the producer face would silently self-terminate the walk.

    Write is the default deliberately: every directory-resolution caller except the chain walk
    decides where something is authored, and a future call site that does not pick gets the face
    whose failure mode is loud (a throw at an undeclared producer) rather than the one whose
    failure mode is a silent wrong-tree write.

    This helper inlines its config lookups so IdRegistry.psm1 doesn't have to depend on
    Common-ScriptHelpers/Core.psm1 (which would create a circular import — Core imports
    IdRegistry).

    Paths beginning with "process-framework/" get rerouted under the face-selected tree.
    Other relative paths are joined with the project root directly. Absolute paths pass through.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Write','Read')]
        [string]$Face = 'Write'
    )

    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }

    if ($Path -match '^process-framework(/|$)') {
        $fwAbs = Get-WorkspaceFaceDir -ProjectRoot $ProjectRoot -Face $Face
        $remainder = $Path -replace '^process-framework/?', ''
        if ($remainder) { return Join-Path -Path $fwAbs -ChildPath $remainder }
        return $fwAbs
    }

    return Join-Path -Path $ProjectRoot -ChildPath $Path
}

function Resolve-LocalRegistryPath {
    <#
    .SYNOPSIS
    Resolves the registry path that holds project-local prefixes (PF-STA, PF-TMP post-Phase-7),
    routing to process-framework-central/ for producer-face workspaces and doc/state-tracking/
    for leaf projects.

    .DESCRIPTION
    Private helper inlined here (rather than imported from Common-ScriptHelpers) to avoid a
    circular import: Common-ScriptHelpers/DocumentManagement.psm1 imports IdRegistry.psm1, so
    IdRegistry.psm1 cannot import Common-ScriptHelpers. The equivalent public function
    Get-StateTrackingContext lives in Common-ScriptHelpers/Core.psm1 for use by state-creating
    scripts; the two share the same declared-role contract (PF-PRO-067 Contract 4).

    A producer-face workspace (role 'framework' or 'framework-builder') keeps its own
    framework-management state — including its local PF-STA pool — in its own
    process-framework-central/, because such a workspace's own work IS framework development
    (two-faces model; this rationale replaced the stale "appdev/doc/ is the blueprint" one and
    the branch replaced the project_id == "PRJ-000" identity comparison).
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectRoot
    )

    # Role question: "am I the central hub?" — declared, never inferred from a workspace ID.
    if ((Get-WorkspaceRole -ProjectRoot $ProjectRoot) -in @('framework', 'framework-builder')) {
        return Join-Path -Path $ProjectRoot -ChildPath "process-framework-central/PF-id-registry-central.json"
    }
    return Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/PF-id-registry-local.json"
}

function Resolve-RootCentralRegistryPath {
    <#
    .SYNOPSIS
    Resolves the CHAIN ROOT's PF-id-registry-central.json — the single counter for the
    portfolio-global pools PF-IMP, PF-PRO, PF-FEE, PF-REV, PF-EVR (PF-PRO-068 P-3).

    .DESCRIPTION
    A filename adapter over Get-RootCentralFrameworkPath, which returns the DIRECTORY. Not a
    twin: the registry file is genuinely a different thing from the central directory, and this
    module is the only caller that wants the file. All resolution — both override axes, the
    chain walk, the missing-central throw — happens once, in the shared resolver.

    .PARAMETER ProjectRoot
    Workspace root to start the chain walk from.

    .OUTPUTS
    String — absolute path to the chain root's PF-id-registry-central.json.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectRoot
    )

    return Join-Path -Path (Get-RootCentralFrameworkPath -ProjectRoot $ProjectRoot) -ChildPath "PF-id-registry-central.json"
}

function Resolve-CentralRegistryPath {
    <#
    .SYNOPSIS
    Resolves the OWN central's PF-id-registry-central.json — the workspace's own cross-project
    pools (PRJ and the P-14 child pool).

    .DESCRIPTION
    A filename adapter over Get-CentralFrameworkPath, which returns the DIRECTORY. Not a twin,
    for the same reason as Resolve-RootCentralRegistryPath above: all resolution — the override
    axis, the producer-face branch, the leaf's parent-pointer read and its three distinct
    failure messages — happens once, in the shared resolver.

    .PARAMETER ProjectRoot
    Workspace root whose own central is wanted.

    .PARAMETER ProcessFrameworkDir
    The READ face of that workspace — where the parent pointer was deployed by the parent's
    rollout. Consumed only on the leaf branch.

    .OUTPUTS
    String — absolute path to the governing PF-id-registry-central.json.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory=$true)]
        [string]$ProcessFrameworkDir
    )

    return Join-Path -Path (Get-CentralFrameworkPath -ProjectRoot $ProjectRoot -FrameworkDir $ProcessFrameworkDir) -ChildPath "PF-id-registry-central.json"
}

function Get-IdRegistryPath {
    <#
    .SYNOPSIS
    Gets the path to the appropriate ID registry file based on prefix

    .PARAMETER Prefix
    The ID prefix (e.g., "PF-TSK", "PD-TDD", "TE-TSP"). Determines which registry file to use.
    If omitted, returns the process framework registry (PF-id-registry.json).

    .NOTES
    PF- prefixes are split across registries (location resolved at runtime by declared role and
    face — PF-PRO-067 Contract 4, PF-PRO-068 face fix):
    - <framework tree>/PF-id-registry.json — blueprint prefixes (PF-TSK, PF-GDE, PF-TEM, ...).
      Rolled out to projects; the canonical copy lives in the owning producer's blueprint tree.
      Resolved Write-face from config (paths.blueprint at a producer, paths.process_framework at
      a leaf), never from the module's own on-disk location.
    - process-framework-central/PF-id-registry-central.json — cross-project pools
      (PF-IMP, PF-PRO, PF-FEE, PF-REV, PF-EVR, PRJ). In a producer-face workspace (declared
      role 'framework'/'framework-builder') resolved locally; in a leaf workspace resolved via
      its parent pointer (Phase 7 cutover, 2026-05-11; role-based since PF-PRO-067).
      A producer-face workspace also gets its PF-STA from this registry — producer-face state,
      including the local state-file pool, lives in the workspace's own central because its own
      work IS framework development (two-faces model).
    - doc/state-tracking/PF-id-registry-local.json — project-local prefixes (PF-STA, PF-TMP)
      for leaf projects (role 'project', including the absent-field default). Co-located with
      the rest of doc/state-tracking/ content.
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$Prefix
    )

    # Resolve project root via two-pass doc/project-config.json walk (post-Phase-5.5 safe).
    # Naive Split-Path-Parent twice would return appdev/blueprint instead of appdev when the
    # script lives under blueprint/process-framework/, leading the local-registry routing to look
    # at the blueprint template config (project_id: null) and fall through to project-mode paths.
    #
    # The framework tree itself resolves from CONFIG, never from the module's own on-disk
    # location (PF-PRO-068 face fix): Split-Path -Parent $PSScriptRoot answered "which copy of
    # this module was imported?", so post-cutover the same mint could write the registry FILE
    # into one tree and the artifact into the other, purely by import path — proven in the
    # Session 8 sandbox (same prefix minted different IDs by module copy). Face-resolved below
    # at each use site: Write face for the registry file (where artifacts are authored), Read
    # face for the parent-pointer probe (the pointer lives in the consumer tree).
    $projectRoot = Get-ProjectRoot -StartPath $PSScriptRoot
    $docDir = Join-Path -Path $projectRoot -ChildPath "doc"

    # Pool-scoped dispatch (PF-PRO-068 P-3 / WI-5). Phase 7 routed every cross-project pool to
    # "the central", singular. The portfolio has two distinct central destinations, and the pools
    # divide by which one they must mint from:
    #
    #   PORTFOLIO pools  -> the CHAIN ROOT's central. One counter portfolio-wide, so a bare
    #                       PF-IMP-NNNN resolves to exactly one row anywhere. For a producer face
    #                       this REVERSES the own-central termination: the walk keeps going.
    #   OWN-CENTRAL pool -> the nearest producer face's central. The child pool numbers a
    #                       workspace's own children, so it belongs to the workspace that has
    #                       children, not to the portfolio root. Since P-14 the pool carries the
    #                       chain's mnemonic (FWK-APP children key APP-NNN); 'PRJ' stays listed
    #                       as the legacy pool name — history and the synthetic E2E worlds keep
    #                       PRJ-shaped keys. (PF-STA/PF-TMP stay project-local, below.)
    #
    # Dark until the cutover, provably: appdev carries no parent pointer today, so it IS the chain
    # root — both rules resolve appdev's central, exactly as the pre-dispatch reader did. Only
    # appdev gaining a pointer changes any resolution.
    $portfolioPrefixes = @('PF-IMP', 'PF-PRO', 'PF-FEE', 'PF-REV', 'PF-EVR')
    # Own-central set derives from this workspace's own declared identity (P-14): a producer
    # contributes the second segment of its FWK-<MNEM> id (FWK-APP -> APP), a renamed leaf the
    # first segment of its own <MNEM>-NNN id. Unreadable/null config adds nothing — dispatch
    # then keeps the legacy 'PRJ' name only, which is the pre-P-14 behavior.
    $ownCentralPrefixes = @('PRJ')
    $ownConfigPath = Join-Path -Path $docDir -ChildPath "project-config.json"
    if (Test-Path -Path $ownConfigPath) {
        try {
            $ownDeclaredId = (Get-Content -Raw -Path $ownConfigPath | ConvertFrom-Json).project_id
            if ($ownDeclaredId -cmatch '^FWK-([A-Z]{2,4})$') { $ownCentralPrefixes += $Matches[1] }
            elseif ($ownDeclaredId -cmatch '^([A-Z]{2,4})-') { $ownCentralPrefixes += $Matches[1] }
        } catch {
            Write-Verbose "Get-IdRegistryPath: could not read project_id from '$ownConfigPath' ($($_.Exception.Message)); own-central dispatch keeps the legacy 'PRJ' pool name only."
        }
    }
    $projectLocalPrefixes = @('PF-STA', 'PF-TMP')

    # Hardcoded prefix-to-registry mapping
    if ($Prefix) {
        # Portfolio-global pools resolve to the chain root's central (iterated pointer walk).
        if ($portfolioPrefixes -contains $Prefix) {
            return Resolve-RootCentralRegistryPath -ProjectRoot $projectRoot
        }

        # Child pool stays own-central: producer face -> its own; leaf -> its parent's via the
        # pointer. Register-Project.ps1 reads it directly today; listing it keeps the
        # classification complete for any future caller that goes through New-NextId.
        # Read face: -ProcessFrameworkDir is consumed only on the leaf branch, to probe for the
        # parent pointer — which the parent's rollout deploys into the CONSUMER tree.
        if ($ownCentralPrefixes -contains $Prefix) {
            return Resolve-CentralRegistryPath -ProjectRoot $projectRoot -ProcessFrameworkDir (Get-WorkspaceFaceDir -ProjectRoot $projectRoot -Face Read)
        }

        # Project-local prefixes route per declared role (producer faces → central; leaves → doc/state-tracking/)
        if ($projectLocalPrefixes -contains $Prefix) {
            return Resolve-LocalRegistryPath -ProjectRoot $projectRoot
        }

        # Performance test prefixes (BM, PH) live in the TE registry
        $testPrefixes = @('BM', 'PH')
        if ($testPrefixes -contains $Prefix) {
            return Join-Path -Path $projectRoot -ChildPath "test/TE-id-registry.json"
        }

        # User workflow prefix (WF) lives in the PD registry
        if ($Prefix -eq 'WF') {
            return Join-Path -Path $docDir -ChildPath "PD-id-registry.json"
        }

        $prefixKey = ($Prefix -split '-')[0] + '-'
        switch ($prefixKey) {
            'PD-' { return Join-Path -Path $docDir -ChildPath "PD-id-registry.json" }
            'TE-' { return Join-Path -Path $projectRoot -ChildPath "test/TE-id-registry.json" }
            default { return Join-Path -Path (Get-WorkspaceFaceDir -ProjectRoot $projectRoot -Face Write) -ChildPath "PF-id-registry.json" }
        }
    }

    # Default: process framework registry. Write face — the registry file lives WITH the tree
    # the mints write into, so the counter and the artifact can never split across faces.
    return Join-Path -Path (Get-WorkspaceFaceDir -ProjectRoot $projectRoot -Face Write) -ChildPath "PF-id-registry.json"
}

function Get-IdRegistry {
    <#
    .SYNOPSIS
    Loads the ID registry for a given prefix

    .PARAMETER Prefix
    Optional prefix to determine which registry to load. If omitted, loads the PF registry.
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$Prefix
    )

    $registryPath = Get-IdRegistryPath -Prefix $Prefix
    if (-not (Test-Path $registryPath)) {
        throw "ID registry not found at: $registryPath"
    }

    try {
        $registry = Get-Content -Path $registryPath | ConvertFrom-Json
        return $registry
    }
    catch {
        throw "Failed to load ID registry: $($_.Exception.Message)"
    }
}

function Update-NextAvailableCounter {
    <#
    .SYNOPSIS
    Updates only the nextAvailable counter for a specific prefix without reformatting the entire file

    .PARAMETER Prefix
    The prefix to update

    .PARAMETER NewValue
    The new nextAvailable value
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prefix,

        [Parameter(Mandatory=$true)]
        [int]$NewValue
    )

    $registryPath = Get-IdRegistryPath -Prefix $Prefix
    $content = Get-Content -Path $registryPath -Raw

    # Find the specific prefix section and update only the nextAvailable value
    # Use a more robust pattern that handles multiline JSON
    $pattern = "(`"$Prefix`":\s*\{[\s\S]*?`"nextAvailable`":\s*)(\d+)"
    $replacement = "`${1}$NewValue"

    $updatedContent = $content -replace $pattern, $replacement

    if ($updatedContent -eq $content) {
        throw "No 'nextAvailable' counter found for prefix '$Prefix' in registry '$registryPath'. The counter must exist before IDs can be assigned. Add a 'nextAvailable' field to the prefix entry, set to one greater than the highest existing ID for this prefix on disk."
    }

    $updatedContent | Set-Content -Path $registryPath -Encoding UTF8 -NoNewline
    Write-Verbose "Updated nextAvailable for $Prefix to $NewValue (formatting preserved)"
}

function Save-IdRegistry {
    <#
    .SYNOPSIS
    Saves the ID registry back to disk

    .PARAMETER Registry
    The registry object to save. Must have lastUpdatedPrefix set.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Registry
    )

    $registryPath = Get-IdRegistryPath -Prefix $Registry.lastUpdatedPrefix
    try {
        # Update the metadata
        $Registry.metadata.updated = Get-Date -Format "yyyy-MM-dd"

        # PRESERVE FORMATTING: Use surgical string replacement instead of ConvertTo-Json
        # This prevents the entire file from being reformatted
        Update-NextAvailableCounter -Prefix $Registry.lastUpdatedPrefix -NewValue $Registry.prefixes.($Registry.lastUpdatedPrefix).nextAvailable
        Write-Verbose "ID registry saved to: $registryPath"
    }
    catch {
        throw "Failed to save ID registry: $($_.Exception.Message)"
    }
}

function Get-NextAvailableId {
    <#
    .SYNOPSIS
    Gets the next available ID for a given prefix
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prefix
    )

    $registry = Get-IdRegistry -Prefix $Prefix

    if (-not $registry.prefixes.$Prefix) {
        throw "Prefix '$Prefix' not found in ID registry. Available prefixes: $($registry.prefixes.PSObject.Properties.Name -join ', ')"
    }

    $prefixData = $registry.prefixes.$Prefix
    $nextId = $prefixData.nextAvailable

    return "$Prefix-$('{0:D3}' -f $nextId)"
}

function New-NextId {
    <#
    .SYNOPSIS
    Reserves the next available ID for a given prefix and updates the registry
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prefix,

        [Parameter(Mandatory=$false)]
        [string]$Description = ""
    )

    $registry = Get-IdRegistry -Prefix $Prefix

    if (-not $registry.prefixes.$Prefix) {
        throw "Prefix '$Prefix' not found in ID registry. Available prefixes: $($registry.prefixes.PSObject.Properties.Name -join ', ')"
    }

    $prefixData = $registry.prefixes.$Prefix
    $currentId = $prefixData.nextAvailable
    $assignedId = "$Prefix-$('{0:D3}' -f $currentId)"

    # Update the registry using surgical approach to preserve formatting
    $newNextAvailable = $currentId + 1
    Update-NextAvailableCounter -Prefix $Prefix -NewValue $newNextAvailable

    Write-Verbose "Reserved ID: $assignedId for prefix: $Prefix"
    if ($Description) {
        Write-Verbose "Description: $Description"
    }

    return $assignedId
}

function Test-IdExists {
    <#
    .SYNOPSIS
    Checks if an ID already exists in the registry
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Id
    )

    # Parse the ID to get prefix and number
    if ($Id -match '^([A-Z]+-[A-Z]+)-(\d+)$') {
        $prefix = $matches[1]
        $number = [int]$matches[2]

        $registry = Get-IdRegistry -Prefix $prefix

        if ($registry.prefixes.$prefix) {
            # ID exists if it's less than nextAvailable
            return $number -lt $registry.prefixes.$prefix.nextAvailable
        }
    }

    return $false
}

function Get-PrefixInfo {
    <#
    .SYNOPSIS
    Gets information about a specific prefix
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prefix
    )

    $registry = Get-IdRegistry -Prefix $Prefix

    if (-not $registry.prefixes.$Prefix) {
        throw "Prefix '$Prefix' not found in ID registry"
    }

    return $registry.prefixes.$Prefix
}

function Get-PrefixDirectories {
    <#
    .SYNOPSIS
    Gets the valid directories for a specific prefix (enhanced version)

    .PARAMETER Prefix
    The prefix to get directories for

    .PARAMETER ProjectRoot
    Optional project root path to resolve relative paths

    .PARAMETER DirectoryType
    For semantic directories, specify the type (e.g., "discrete", "continuous", "permanent")

    .PARAMETER ListTypes
    Return available directory types instead of paths

    .EXAMPLE
    Get-PrefixDirectories -Prefix "PF-TSK"
    # Returns all directories as array (backward compatible)

    .EXAMPLE
    Get-PrefixDirectories -Prefix "PF-TSK" -DirectoryType "discrete"
    # Returns: "process-framework/tasks/discrete"

    .EXAMPLE
    Get-PrefixDirectories -Prefix "PF-TSK" -ListTypes
    # Returns: @("discrete", "continuous", "cyclical")
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prefix,

        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot,

        [Parameter(Mandatory=$false)]
        [string]$DirectoryType,

        [Parameter(Mandatory=$false)]
        [switch]$ListTypes
    )

    $prefixInfo = Get-PrefixInfo -Prefix $Prefix
    $directories = $prefixInfo.directories

    # Check if directories is an object (new semantic format) or array (old format)
    if ($directories -is [PSCustomObject]) {
        # New semantic format
        if ($ListTypes) {
            # Return available directory types (excluding 'default')
            return ($directories | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -ne "default" } | Select-Object -ExpandProperty Name)
        }

        if ($DirectoryType) {
            # Return specific directory type
            if ($directories.$DirectoryType) {
                $path = $directories.$DirectoryType
                if ($ProjectRoot) {
                    return Resolve-RegistryPath -Path $path -ProjectRoot $ProjectRoot
                }
                return $path
            } else {
                $availableTypes = ($directories | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -ne "default" } | Select-Object -ExpandProperty Name) -join ", "
                throw "Directory type '$DirectoryType' not found for prefix '$Prefix'. Available types: $availableTypes"
            }
        }

        # Return all directories as array (backward compatibility)
        $allDirectories = @()
        $directories | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -ne "default" } | ForEach-Object {
            $path = $directories.($_.Name)
            if ($ProjectRoot) {
                $allDirectories += Resolve-RegistryPath -Path $path -ProjectRoot $ProjectRoot
            } else {
                $allDirectories += $path
            }
        }
        return $allDirectories
    } else {
        # Old array format - backward compatibility
        if ($ListTypes) {
            Write-Warning "Directory types not available for prefix '$Prefix' (using legacy array format)"
            return @()
        }

        if ($DirectoryType) {
            Write-Warning "Directory type selection not available for prefix '$Prefix' (using legacy array format). Using default directory."
            $directories = @($directories[0])  # Use first directory as default
        }

        if ($ProjectRoot) {
            # Convert relative paths to absolute paths
            $directories = $directories | ForEach-Object {
                Resolve-RegistryPath -Path $_ -ProjectRoot $ProjectRoot
            }
        }

        return $directories
    }
}

function Get-DefaultDirectoryForPrefix {
    <#
    .SYNOPSIS
    Gets the default directory for a prefix (enhanced version)

    .PARAMETER Prefix
    The prefix to get the default directory for

    .PARAMETER ProjectRoot
    Optional project root path to resolve relative paths

    .EXAMPLE
    Get-DefaultDirectoryForPrefix -Prefix "PF-TSK"
    # For new format: Uses "default" key to determine which directory
    # For old format: Uses first directory in array
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prefix,

        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot
    )

    $prefixInfo = Get-PrefixInfo -Prefix $Prefix
    $directories = $prefixInfo.directories

    if ($directories -is [PSCustomObject]) {
        # New semantic format
        $defaultType = $directories.default
        if (-not $defaultType) {
            # If no default specified, use first available type
            $firstType = ($directories | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -ne "default" } | Select-Object -First 1).Name
            $defaultType = $firstType
        }

        return Get-PrefixDirectories -Prefix $Prefix -DirectoryType $defaultType -ProjectRoot $ProjectRoot
    } else {
        # Old array format
        if ($directories.Count -eq 0) {
            throw "No directories defined for prefix '$Prefix'"
        }

        $defaultPath = $directories[0]
        if ($ProjectRoot) {
            return Resolve-RegistryPath -Path $defaultPath -ProjectRoot $ProjectRoot
        }

        return $defaultPath
    }
}

function Get-DirectoryForPrefixType {
    <#
    .SYNOPSIS
    Gets a specific directory type for a prefix (new semantic function)

    .PARAMETER Prefix
    The prefix to get directory for

    .PARAMETER DirectoryType
    The semantic type (e.g., "discrete", "permanent", "forms")

    .PARAMETER ProjectRoot
    Optional project root path to resolve relative paths

    .PARAMETER CreateIfMissing
    Create the directory if it doesn't exist

    .EXAMPLE
    Get-DirectoryForPrefixType -Prefix "PF-TSK" -DirectoryType "discrete" -CreateIfMissing
    # Returns: "C:\Project\doc\process-framework\tasks\discrete"

    .EXAMPLE
    Get-DirectoryForPrefixType -Prefix "PF-FEE" -DirectoryType "forms"
    # Returns: "appdev/process-framework-central/feedback/feedback-forms"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prefix,

        [Parameter(Mandatory=$true)]
        [string]$DirectoryType,

        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot,

        [Parameter(Mandatory=$false)]
        [switch]$CreateIfMissing
    )

    try {
        $directory = Get-PrefixDirectories -Prefix $Prefix -DirectoryType $DirectoryType -ProjectRoot $ProjectRoot

        if ($CreateIfMissing -and -not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
            Write-Verbose "Created directory: $directory"
        }

        return $directory
    }
    catch {
        throw "Failed to get directory for prefix '$Prefix' type '$DirectoryType': $($_.Exception.Message)"
    }
}

function Show-PrefixDirectoryInfo {
    <#
    .SYNOPSIS
    Shows detailed directory information for a prefix

    .PARAMETER Prefix
    The prefix to show information for

    .EXAMPLE
    Show-PrefixDirectoryInfo -Prefix "PF-TSK"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prefix
    )

    $prefixInfo = Get-PrefixInfo -Prefix $Prefix
    $directories = $prefixInfo.directories

    Write-Host "Directory Information for $Prefix" -ForegroundColor Cyan
    Write-Host "Description: $($prefixInfo.description)" -ForegroundColor Gray
    Write-Host ""

    if ($directories -is [PSCustomObject]) {
        # New semantic format
        Write-Host "Directory Types (Semantic Format):" -ForegroundColor Green

        $defaultType = $directories.default
        $directories | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -ne "default" } | ForEach-Object {
            $type = $_.Name
            $path = $directories.$type
            $isDefault = ($type -eq $defaultType)
            $marker = if ($isDefault) { " (default)" } else { "" }

            Write-Host "  $type$marker" -ForegroundColor Yellow -NoNewline
            Write-Host "`: $path" -ForegroundColor White
        }
    } else {
        # Old array format
        Write-Host "Directories (Legacy Array Format):" -ForegroundColor Yellow
        for ($i = 0; $i -lt $directories.Count; $i++) {
            $marker = if ($i -eq 0) { " (default)" } else { "" }
            Write-Host "  [$i]$marker`: $($directories[$i])" -ForegroundColor White
        }
    }
}

function Test-ValidDirectoryForPrefix {
    <#
    .SYNOPSIS
    Tests if a directory is valid for a given prefix

    .PARAMETER Prefix
    The prefix to check

    .PARAMETER Directory
    The directory path to validate

    .PARAMETER ProjectRoot
    Optional project root path for resolving relative paths

    .EXAMPLE
    Test-ValidDirectoryForPrefix -Prefix "PF-FEE" -Directory "appdev/process-framework-central/feedback/feedback-forms"
    # Returns: $true
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prefix,

        [Parameter(Mandatory=$true)]
        [string]$Directory,

        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot
    )

    $validDirectories = Get-PrefixDirectories -Prefix $Prefix -ProjectRoot $ProjectRoot

    # Normalize paths for comparison
    $normalizedDirectory = $Directory.Replace('\', '/').TrimEnd('/')

    foreach ($validDir in $validDirectories) {
        $normalizedValidDir = $validDir.Replace('\', '/').TrimEnd('/')
        if ($normalizedDirectory -eq $normalizedValidDir -or $normalizedDirectory.EndsWith($normalizedValidDir)) {
            return $true
        }
    }

    return $false
}

function Get-AllPrefixes {
    <#
    .SYNOPSIS
    Gets all available prefixes and their information from all registries
    #>
    $prefixes = @()

    # Load all registries (blueprint PF, local PF, PD, TE)
    foreach ($samplePrefix in @('PF-TSK', 'PF-PRO', 'PD-DOC', 'TE-E2G')) {
        $registryPath = Get-IdRegistryPath -Prefix $samplePrefix
        if (Test-Path $registryPath) {
            $registry = Get-IdRegistry -Prefix $samplePrefix
            foreach ($prefix in $registry.prefixes.PSObject.Properties) {
                $prefixes += [PSCustomObject]@{
                    Prefix = $prefix.Name
                    Description = $prefix.Value.description
                    Category = $prefix.Value.category
                    Type = $prefix.Value.type
                    NextAvailable = $prefix.Value.nextAvailable
                    LastAssigned = $prefix.Value.nextAvailable - 1
                    Registry = (Split-Path $registryPath -Leaf)
                }
            }
        }
    }

    return $prefixes | Sort-Object Category, Type, Prefix
}



function Show-IdRegistryStatus {
    <#
    .SYNOPSIS
    Shows the current status of the ID registry
    #>
    $registry = Get-IdRegistry

    Write-Host "=== ID Registry Status ===" -ForegroundColor Cyan
    Write-Host "Version: $($registry.metadata.version)"
    Write-Host "Last Updated: $($registry.metadata.updated)"
    Write-Host ""

    # Show prefix summary
    Write-Host "PREFIX SUMMARY:" -ForegroundColor Green
    $prefixes = Get-AllPrefixes
    $prefixes | Format-Table -Property Prefix, Description, NextAvailable, LastAssigned -AutoSize
}

# Export functions
Export-ModuleMember -Function @(
    'Get-NextAvailableId',
    'New-NextId',
    'Test-IdExists',
    'Get-PrefixInfo',
    'Get-PrefixDirectories',
    'Get-DefaultDirectoryForPrefix',
    'Get-DirectoryForPrefixType',
    'Show-PrefixDirectoryInfo',
    'Test-ValidDirectoryForPrefix',
    'Get-AllPrefixes',
    'Show-IdRegistryStatus'
)
