# IdRegistry.psm1
# Central ID management module for process framework projects
# Uses domain-specific ID registries (PF/PD/TE-id-registry.json) to manage document IDs

function Resolve-ProjectRootForRegistry {
    <#
    .SYNOPSIS
    Inlined two-pass walk that mirrors Common-ScriptHelpers/Core.psm1's Get-ProjectRoot, returning
    the project root path. Inlined here to avoid the circular import that prevents IdRegistry.psm1
    from depending on Common-ScriptHelpers (the latter imports IdRegistry).

    .DESCRIPTION
    Walks up from $PSScriptRoot looking for doc/project-config.json with a non-null project_id.
    Skips the blueprint template config at appdev/blueprint/doc/project-config.json (project_id: null)
    so appdev's real root at appdev/ wins over the nested template.

    Falls back to two levels above $PSScriptRoot (the pre-Phase-5.5 assumption) if no anchored
    config is found — preserves backward compat with project layouts that haven't yet rolled out
    a populated doc/project-config.json.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$StartPath
    )

    $currentPath = $StartPath
    $maxDepth = 10
    $depth = 0
    while ($depth -lt $maxDepth) {
        $docConfigPath = Join-Path -Path $currentPath -ChildPath "doc/project-config.json"
        if (Test-Path $docConfigPath) {
            try {
                $configCheck = Get-Content -Path $docConfigPath -Raw | ConvertFrom-Json
                if ($configCheck.project_id) {
                    return $currentPath
                }
            } catch {
                # Unparseable — keep walking (treat as no project_id)
            }
        }
        $parentPath = Split-Path -Parent $currentPath
        if ($parentPath -eq $currentPath) { break }
        $currentPath = $parentPath
        $depth++
    }

    # Legacy fallback: assume process-framework/scripts/X.ps1 with project root two levels up.
    $processFrameworkDir = Split-Path -Parent $StartPath
    return Split-Path -Parent $processFrameworkDir
}

function Resolve-RegistryPath {
    <#
    .SYNOPSIS
    Resolves a registry-declared directory path against the project root, accounting for the
    process-framework subtree being configurable via paths.process_framework in project-config.json.

    .DESCRIPTION
    Registry entries often declare paths like "process-framework/tasks", which historically
    assumed process-framework/ lived at the project root. After the Phase 5.5 reorg of the
    Centralized Framework Management extension, appdev relocated the subtree to
    blueprint/process-framework/, and paths.process_framework in project-config.json tells
    callers where to find it (default "process-framework" preserves legacy projects).

    This helper inlines that lookup so IdRegistry.psm1 doesn't have to depend on
    Common-ScriptHelpers/Core.psm1 (which would create a circular import — Core imports
    IdRegistry).

    Paths beginning with "process-framework/" get rerouted under paths.process_framework.
    Other relative paths are joined with the project root directly. Absolute paths pass through.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$ProjectRoot
    )

    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }

    if ($Path -match '^process-framework(/|$)') {
        $configPath = Join-Path -Path $ProjectRoot -ChildPath "doc/project-config.json"
        $fwRel = "process-framework"
        if (Test-Path $configPath) {
            try {
                $cfg = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                if ($cfg.paths -and $cfg.paths.process_framework) {
                    $fwRel = $cfg.paths.process_framework
                }
            } catch {
                # Defensive: stay with default
            }
        }
        $remainder = $Path -replace '^process-framework/?', ''
        $fwAbs = Join-Path -Path $ProjectRoot -ChildPath $fwRel
        if ($remainder) { return Join-Path -Path $fwAbs -ChildPath $remainder }
        return $fwAbs
    }

    return Join-Path -Path $ProjectRoot -ChildPath $Path
}

function Resolve-LocalRegistryPath {
    <#
    .SYNOPSIS
    Resolves the registry path that holds project-local prefixes (PF-STA, PF-TMP post-Phase-7),
    routing to process-framework-central/ for appdev (PRJ-000) and doc/state-tracking/ for projects.

    .DESCRIPTION
    Private helper inlined here (rather than imported from Common-ScriptHelpers) to avoid a
    circular import: Common-ScriptHelpers/DocumentManagement.psm1 imports IdRegistry.psm1, so
    IdRegistry.psm1 cannot import Common-ScriptHelpers. The equivalent public function
    Get-StateTrackingContext lives in Common-ScriptHelpers/Core.psm1 for use by state-creating
    scripts; the two share the same project_id == "PRJ-000" contract.

    Per centralized-framework-management.md (§3.1, §3.2): appdev/doc/ is the blueprint for new
    projects, so appdev's own framework-management state must live in process-framework-central/
    instead of appdev/doc/state-tracking/.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectRoot
    )

    $configPath = Join-Path -Path $ProjectRoot -ChildPath "doc/project-config.json"
    if (Test-Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            if ($config.project_id -eq "PRJ-000") {
                return Join-Path -Path $ProjectRoot -ChildPath "process-framework-central/PF-id-registry-central.json"
            }
        } catch {
            # Fall through to project mode if config unreadable
        }
    }
    return Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/PF-id-registry-local.json"
}

function Resolve-CentralRegistryPath {
    <#
    .SYNOPSIS
    Resolves the central PF-id-registry-central.json path for cross-project ID pools
    (PF-IMP, PF-PRO, PF-FEE, PF-REV, PF-EVR, PRJ).

    .DESCRIPTION
    Phase 7 of the Centralized Framework Management extension cuts the cross-project prefixes
    over to a single source of truth in appdev's process-framework-central/. From cwd=appdev
    (project_id == "PRJ-000") the registry is local; from cwd=project the registry is found by
    reading .framework-central-pointer (a single-line file containing the absolute path to appdev,
    written by Push-FrameworkUpdate.ps1).

    Inlined here to avoid a circular Common-ScriptHelpers import (same pattern as
    Resolve-LocalRegistryPath). The public equivalent lives at Common-ScriptHelpers/Core.psm1
    as Get-CentralFrameworkPath.

    Honors the $env:FRAMEWORK_CENTRAL_OVERRIDE test-injection hook (PF-PRO-035 OP-1) — when set
    and pointing at an existing dir, returns "<override>/PF-id-registry-central.json". The
    override mechanism must cover this resolver as well as Get-CentralFrameworkPath, otherwise
    PF-IMP / PF-PRO / etc. allocations bypass the override and leak counter increments into the
    real appdev central registry. Override-must-cover-IdRegistry gap closed in Session 30.

    Throws when invoked from a non-appdev project that has no central pointer — that condition
    indicates a setup error (Push has never reached the project) rather than something to fall
    back from.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory=$true)]
        [string]$ProcessFrameworkDir
    )

    # Test-injection override (PF-PRO-035 Session 29 OP-1, extended in Session 30 to cover the
    # central PF-id-registry. Mirrors the inline check in Common-ScriptHelpers/Core.psm1's
    # Get-CentralFrameworkPath — the circular-import constraint forces the duplication.
    if ($env:FRAMEWORK_CENTRAL_OVERRIDE) {
        $override = $env:FRAMEWORK_CENTRAL_OVERRIDE.Trim()
        if (-not (Test-Path $override)) {
            throw "Resolve-CentralRegistryPath: `$env:FRAMEWORK_CENTRAL_OVERRIDE points at non-existent path: $override. The test fixture must create the sandbox-central dir before invoking the framework script."
        }
        return Join-Path -Path $override -ChildPath "PF-id-registry-central.json"
    }

    $configPath = Join-Path -Path $ProjectRoot -ChildPath "doc/project-config.json"
    $isAppdev = $false
    if (Test-Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            if ($config.project_id -eq "PRJ-000") { $isAppdev = $true }
        } catch {
            # Fall through; pointer-file resolution will fail loudly if absent
        }
    }

    if ($isAppdev) {
        return Join-Path -Path $ProjectRoot -ChildPath "process-framework-central/PF-id-registry-central.json"
    }

    $pointerPath = Join-Path -Path $ProcessFrameworkDir -ChildPath ".framework-central-pointer"
    if (-not (Test-Path $pointerPath)) {
        throw "Resolve-CentralRegistryPath: .framework-central-pointer not found at $pointerPath. This project has not received a Push from appdev yet — cross-project ID pools cannot be resolved. Run Push-FrameworkUpdate.ps1 from appdev to deploy the pointer."
    }
    $appdevRoot = (Get-Content -Path $pointerPath -Raw).Trim()
    if (-not $appdevRoot) {
        throw "Resolve-CentralRegistryPath: .framework-central-pointer at $pointerPath is empty. Re-run Push-FrameworkUpdate.ps1 to repair."
    }
    return Join-Path -Path $appdevRoot -ChildPath "process-framework-central/PF-id-registry-central.json"
}

function Get-IdRegistryPath {
    <#
    .SYNOPSIS
    Gets the path to the appropriate ID registry file based on prefix

    .PARAMETER Prefix
    The ID prefix (e.g., "PF-TSK", "PD-TDD", "TE-TSP"). Determines which registry file to use.
    If omitted, returns the process framework registry (PF-id-registry.json).

    .NOTES
    PF- prefixes are split across registries (location resolved at runtime per project_id):
    - process-framework/PF-id-registry.json — blueprint prefixes (PF-TSK, PF-GDE, PF-TEM, ...).
      Rolled out to projects; one canonical copy lives in appdev.
    - process-framework-central/PF-id-registry-central.json — cross-project pools
      (PF-IMP, PF-PRO, PF-FEE, PF-REV, PF-EVR, PRJ). From cwd=appdev resolved locally;
      from cwd=project resolved via .framework-central-pointer (Phase 7 cutover, 2026-05-11).
      PRJ-000 (appdev) also gets its PF-STA from this registry because appdev/doc/ is the
      blueprint and cannot host appdev's own state.
    - doc/state-tracking/PF-id-registry-local.json — project-local prefixes (PF-STA, PF-TMP)
      for projects (project_id != "PRJ-000"). Co-located with the rest of doc/state-tracking/
      content.
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$Prefix
    )

    # Resolve project root via two-pass doc/project-config.json walk (post-Phase-5.5 safe).
    # Naive Split-Path-Parent twice would return appdev/blueprint instead of appdev when the
    # script lives under blueprint/process-framework/, leading the local-registry routing to look
    # at the blueprint template config (project_id: null) and fall through to project-mode paths.
    $projectRoot = Resolve-ProjectRootForRegistry -StartPath $PSScriptRoot
    $processFrameworkDir = Split-Path -Parent $PSScriptRoot
    $docDir = Join-Path -Path $projectRoot -ChildPath "doc"

    # Phase 7 split: cross-project pools live in central; PF-STA/PF-TMP stay project-local.
    # PRJ is in central too; Register-Project.ps1 currently reads it directly, but listing here
    # keeps the prefix classification complete for any future caller that goes through New-NextId.
    $centralPrefixes = @('PF-IMP', 'PF-PRO', 'PF-FEE', 'PF-REV', 'PF-EVR', 'PRJ')
    $projectLocalPrefixes = @('PF-STA', 'PF-TMP')

    # Hardcoded prefix-to-registry mapping
    if ($Prefix) {
        # Cross-project pools always resolve to central (via .framework-central-pointer for projects)
        if ($centralPrefixes -contains $Prefix) {
            return Resolve-CentralRegistryPath -ProjectRoot $projectRoot -ProcessFrameworkDir $processFrameworkDir
        }

        # Project-local prefixes route per project_id (PRJ-000 → central; otherwise → doc/state-tracking/)
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
            default { return Join-Path -Path $processFrameworkDir -ChildPath "PF-id-registry.json" }
        }
    }

    # Default: process framework registry
    return Join-Path -Path $processFrameworkDir -ChildPath "PF-id-registry.json"
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
