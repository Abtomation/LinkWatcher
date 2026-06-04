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

# Global variables for cached paths
$script:ProjectRoot = $null
$script:IdRegistryPath = $null
$script:DocumentManagementPath = $null
$script:ProjectConfig = $null
$script:DomainConfig = $null

function Get-ProjectRoot {
    <#
    .SYNOPSIS
    Gets the project root directory from any script location

    .DESCRIPTION
    Finds the project root by looking for key markers like process-framework/.ai-entry-point.md
    Caches the result for performance
    #>

    if ($script:ProjectRoot) {
        return $script:ProjectRoot
    }

    $startPath = $PSScriptRoot
    $maxDepth = 10

    # Pass 1 — Primary anchor: doc/project-config.json WITH project_id set.
    # This is the canonical project-root marker, present at the same relative path
    # in both regular projects AND in appdev (Phase 5.5+ blueprint layout).
    # Walking the FULL ancestor chain for this marker first is critical: in the
    # appdev post-Phase-5.5 layout, a script at
    # appdev/blueprint/process-framework/scripts/.../X.ps1 would otherwise find
    # the secondary marker `process-framework/.ai-entry-point.md` at
    # appdev/blueprint/ and falsely return that as project root, BEFORE the
    # walk reaches the real root at appdev/. Two-pass design prevents that.
    #
    # The project_id != null requirement skips the blueprint TEMPLATE config at
    # appdev/blueprint/doc/project-config.json (template has project_id: null
    # until PF-TSK-059 stamps it during bootstrap). Without this filter, the
    # template would mask appdev's real PRJ-000 root when scripts run from
    # inside appdev/blueprint/.
    $currentPath = $startPath
    $depth = 0
    while ($depth -lt $maxDepth) {
        $docConfigPath = Join-Path -Path $currentPath -ChildPath "doc/project-config.json"
        if (Test-Path $docConfigPath) {
            $hasProjectId = $false
            try {
                $configCheck = Get-Content -Path $docConfigPath -Raw | ConvertFrom-Json
                if ($configCheck.project_id) { $hasProjectId = $true }
            } catch {
                # Unparseable — treat as no project_id; keep walking.
            }
            if ($hasProjectId) {
                $script:ProjectRoot = $currentPath
                return $script:ProjectRoot
            }
        }
        $parentPath = Split-Path -Parent $currentPath
        if ($parentPath -eq $currentPath) { break }
        $currentPath = $parentPath
        $depth++
    }

    # Pass 2 — Fallback markers. Only reached if no doc/project-config.json was
    # found anywhere on the ancestor chain (e.g., pre-Project-Initiation trees,
    # or pre-PD-BUG-022 layouts with project-config.json at root level).
    $currentPath = $startPath
    $depth = 0
    while ($depth -lt $maxDepth) {
        # Legacy root-level project-config.json (pre-PD-BUG-022 layout).
        $configPath = Join-Path -Path $currentPath -ChildPath "project-config.json"
        if (Test-Path $configPath) {
            try {
                $config = Get-Content $configPath -Raw | ConvertFrom-Json
                if ($config.project.root_directory -and (Test-Path $config.project.root_directory)) {
                    $script:ProjectRoot = $config.project.root_directory
                    return $script:ProjectRoot
                }
            } catch {
                # If config is unreadable, fall through to markers
            }
        }

        # Last-resort markers (rolled-out projects' top-level layout).
        $markers = @(
            "process-framework/.ai-entry-point.md",
            "process-framework/ai-tasks.md",
            ".git"
        )
        foreach ($marker in $markers) {
            $markerPath = Join-Path -Path $currentPath -ChildPath $marker
            if (Test-Path $markerPath) {
                $script:ProjectRoot = $currentPath
                return $script:ProjectRoot
            }
        }

        $parentPath = Split-Path -Parent $currentPath
        if ($parentPath -eq $currentPath) { break }
        $currentPath = $parentPath
        $depth++
    }

    throw "Could not find project root from $PSScriptRoot"
}

function Get-ProcessFrameworkPath {
    <#
    .SYNOPSIS
    Returns the absolute path to the process-framework subtree, configurable via project-config.json.

    .DESCRIPTION
    Reads paths.process_framework from doc/project-config.json and joins with the project root.
    Added by Phase 5.5 of the Centralized Framework Management extension (2026-05-11) so that
    appdev — where process-framework/ moved into blueprint/process-framework/ — works alongside
    rolled-out projects where process-framework/ is still at the top level.

    Falls back to "process-framework" if the config field is unset (legacy projects, defensive default).

    .PARAMETER ProjectRoot
    Optional explicit project root override. When omitted, resolves via Get-ProjectRoot (cwd-based).
    Use this when a caller is validating a project other than the cwd (e.g., Validate-StateTracking.ps1
    accepts -ProjectRoot to point at an external project).

    .OUTPUTS
    String — absolute path to the framework subtree.

    .EXAMPLE
    $fwDir = Get-ProcessFrameworkPath
    $templatesDir = Join-Path -Path $fwDir -ChildPath "templates"

    .EXAMPLE
    $fwDir = Get-ProcessFrameworkPath -ProjectRoot $ExternalProjectPath
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot
    )

    $projectRoot = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { Get-ProjectRoot } else { $ProjectRoot }
    $configPath = Join-Path -Path $projectRoot -ChildPath "doc/project-config.json"
    $relative = "process-framework"
    if (Test-Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            if ($config.paths -and $config.paths.process_framework) {
                $relative = $config.paths.process_framework
            }
        } catch {
            # Defensive fallback to default; log via verbose only.
            Write-Verbose "Get-ProcessFrameworkPath: could not parse doc/project-config.json; falling back to 'process-framework'."
        }
    }
    return (Join-Path -Path $projectRoot -ChildPath $relative)
}

function Get-CentralFrameworkPath {
    <#
    .SYNOPSIS
    Returns the absolute path to appdev's process-framework-central/ directory, resolving via
    project_id and (for non-appdev projects) the .framework-central-pointer file.

    .DESCRIPTION
    Phase 7 of the Centralized Framework Management extension cut writers over from per-project
    process-framework-local/ paths (legacy, pre-migration) to a single central location under appdev. This helper hides
    the cwd-dependent resolution from script callers:

    - If $env:FRAMEWORK_CENTRAL_OVERRIDE is set and non-empty: returns it directly (after
      verifying the path exists). This is the test-injection hook used by TE-E2E cases that
      exercise central-writing scripts (WF-007 imp-lifecycle, WF-019 soak-verification, etc.)
      against a per-test sandbox-central dir, so the real appdev central is never written to
      mid-test. The override is the FULL central path, not the appdev root — tests construct
      exactly the dir they want, including any required state-file skeletons.
    - From cwd=appdev (project_id == "PRJ-000"): returns <projectRoot>/process-framework-central.
    - From cwd=project (project_id != "PRJ-000"): reads .framework-central-pointer (single-line
      file containing the absolute path to appdev, written by Push-FrameworkUpdate.ps1) from
      <Get-ProcessFrameworkPath>/.framework-central-pointer, then returns
      <appdev-root>/process-framework-central.

    Throws if, in a non-appdev project, the pointer file is missing, empty, or resolves to a
    non-existent central directory — each case gets a distinct, actionable message. A missing
    pointer means the project was never reached by a Push; an empty pointer is a corrupt write;
    a broken target means the pointer is stale (appdev was moved or deleted). All three are
    setup errors rather than something to silently fall back from.

    .OUTPUTS
    String — absolute path to appdev/process-framework-central/ (or the override target).

    .EXAMPLE
    $central = Get-CentralFrameworkPath
    $feedbackDir = Join-Path -Path $central -ChildPath "feedback/feedback-forms"
    #>

    [CmdletBinding()]
    param()

    # Test-injection override (PF-PRO-035 Session 29 / OP-1). Lets per-test fixtures redirect
    # central writes to a sandbox-central dir so mid-test mutations don't leak into the real
    # appdev central tracking files. Set by TE-E2E run.ps1 fixtures before invoking the
    # framework script under test; unset in production.
    if ($env:FRAMEWORK_CENTRAL_OVERRIDE) {
        $override = $env:FRAMEWORK_CENTRAL_OVERRIDE.Trim()
        if (-not (Test-Path $override)) {
            throw "Get-CentralFrameworkPath: `$env:FRAMEWORK_CENTRAL_OVERRIDE points at non-existent path: $override. The test fixture must create the sandbox-central dir before invoking the framework script."
        }
        return $override
    }

    $projectRoot = Get-ProjectRoot
    $configPath = Join-Path -Path $projectRoot -ChildPath "doc/project-config.json"

    $isAppdev = $false
    if (Test-Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            if ($config.project_id -eq "PRJ-000") { $isAppdev = $true }
        } catch {
            # Fall through to non-appdev branch; pointer-file path will fail loudly if absent.
        }
    }

    if ($isAppdev) {
        return (Join-Path -Path $projectRoot -ChildPath "process-framework-central")
    }

    $fwDir = Get-ProcessFrameworkPath
    $pointerPath = Join-Path -Path $fwDir -ChildPath ".framework-central-pointer"
    if (-not (Test-Path $pointerPath)) {
        throw "Get-CentralFrameworkPath: .framework-central-pointer not found at $pointerPath. This project has not received a Push from appdev yet — central writes cannot be resolved. Run Push-FrameworkUpdate.ps1 from appdev to deploy the pointer."
    }

    # Get-Content -Raw returns $null for a 0-byte file (and a whitespace-only file trims to '').
    # Guard the null so both render the intended "is empty" message rather than a generic
    # "cannot call a method on a null-valued expression".
    $rawPointer = Get-Content -Path $pointerPath -Raw
    $appdevRoot = if ($null -ne $rawPointer) { $rawPointer.Trim() } else { '' }
    if (-not $appdevRoot) {
        throw "Get-CentralFrameworkPath: .framework-central-pointer at $pointerPath is empty. Re-run Push-FrameworkUpdate.ps1 to repair."
    }

    $centralPath = Join-Path -Path $appdevRoot -ChildPath "process-framework-central"
    if (-not (Test-Path $centralPath)) {
        throw "Get-CentralFrameworkPath: .framework-central-pointer at $pointerPath points to '$appdevRoot', but the resolved central directory does not exist: $centralPath. The pointer target is stale (appdev was moved or deleted) — correct the path in the pointer file, or re-run Push-FrameworkUpdate.ps1 from appdev to repair it."
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
    Returns the state-tracking routing context, routing to central for appdev (PRJ-000) and to
    doc/state-tracking/ for regular projects.

    .DESCRIPTION
    Reads project_id from doc/project-config.json. Per centralized-framework-management.md
    (§3.1, §3.2), appdev/doc/ is the blueprint for new projects, so appdev's own framework-
    management state (temp state files, PF-STA registry, permanent IMP tracking, etc.) lives
    in appdev/process-framework-central/ instead. Regular projects (PRJ-001+) write state to
    <project>/doc/state-tracking/.

    State-creating scripts should consume this helper for OutputDirectory and registry paths,
    so the same script binary works correctly whether invoked from cwd=appdev or cwd=project.

    .OUTPUTS
    PSCustomObject with properties:
    - Mode: "central" (appdev/PRJ-000) or "project" (regular projects)
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
    same RegistryPath value via the same project_id == "PRJ-000" contract (inlined there to
    avoid a circular import: Common-ScriptHelpers/DocumentManagement.psm1 imports IdRegistry).

    .EXAMPLE
    $context = Get-StateTrackingContext
    $tempDir = "$($context.StateTrackingRelative)/temporary"
    # appdev  → "process-framework-central/state-tracking/temporary"
    # project → "doc/state-tracking/temporary"
    #>

    [CmdletBinding()]
    param()

    $projectRoot = Get-ProjectRoot
    $configPath = Join-Path -Path $projectRoot -ChildPath "doc/project-config.json"

    $isAppdev = $false
    if (Test-Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            if ($config.project_id -eq "PRJ-000") {
                $isAppdev = $true
            }
        } catch {
            # Fall through to project mode if config unreadable
        }
    }

    if ($isAppdev) {
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

    For appdev (PRJ-000), paths.documentation_root is "doc" — appdev's own workspace state lives at
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
    ~17 framework scripts. For appdev (PRJ-000), the configured paths resolve to appdev's own
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

# Export functions
Export-ModuleMember -Function @(
    'Get-ProjectRoot',
    'Get-ProcessFrameworkPath',
    'Get-CentralFrameworkPath',
    'Import-ProjectModule',
    'New-ProjectId',
    'Get-ProjectIdDirectory',
    'Get-ProjectConfig',
    'Get-DomainConfig',
    'Get-StateTrackingContext',
    'Resolve-DocPath',
    'Resolve-TrackingFilePath',
    'Test-MSYSPathMangled',
    'Get-EffectiveWhatIf'
)
