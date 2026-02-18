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
    Finds the project root by looking for key markers like .ai-entry-point.md
    Caches the result for performance
    #>

    if ($script:ProjectRoot) {
        return $script:ProjectRoot
    }

    $currentPath = $PSScriptRoot
    $maxDepth = 10
    $depth = 0

    while ($depth -lt $maxDepth) {
        # Look for project markers
        $markers = @(
            ".ai-entry-point.md",
            "ai-tasks.md",
            "pubspec.yaml",
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
        if ($parentPath -eq $currentPath) {
            break # Reached root
        }
        $currentPath = $parentPath
        $depth++
    }

    throw "Could not find project root from $PSScriptRoot"
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

    switch ($ModuleName) {
        "IdRegistry" {
            if (-not $script:IdRegistryPath) {
                $script:IdRegistryPath = Join-Path -Path $projectRoot -ChildPath "doc\process-framework\scripts\IdRegistry.psm1"
            }
            $modulePath = $script:IdRegistryPath
        }
        "DocumentManagement" {
            if (-not $script:DocumentManagementPath) {
                # Try multiple possible locations
                $possiblePaths = @(
                    "scripts\DocumentManagement.psm1",
                    "doc\process-framework\scripts\DocumentManagement.psm1",
                    "doc\process-framework\methodologies\documentation-tiers\scripts\DocumentManagement.psm1"
                )

                foreach ($relativePath in $possiblePaths) {
                    $testPath = Join-Path -Path $projectRoot -ChildPath $relativePath
                    if (Test-Path $testPath) {
                        $script:DocumentManagementPath = $testPath
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
    The ID prefix (e.g., "PF-TSK", "ART-FEE")

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
    The ID prefix (e.g., "PF-TSK", "ART-FEE")

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
    $outputDir = Get-ProjectIdDirectory -Prefix "ART-FEE" -CreateIfMissing
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
    Loads project-specific configuration from doc/process-framework/project-config.json
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
        $configPath = Join-Path -Path $projectRoot -ChildPath "doc\process-framework\project-config.json"

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
    Loads domain-specific configuration from doc/process-framework/domain-config.json
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
        $projectRoot = Get-ProjectRoot
        $configPath = Join-Path -Path $projectRoot -ChildPath "doc\process-framework\domain-config.json"

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

# Export functions
Export-ModuleMember -Function @(
    'Get-ProjectRoot',
    'Import-ProjectModule',
    'New-ProjectId',
    'Get-ProjectIdDirectory',
    'Get-ProjectConfig',
    'Get-DomainConfig'
)
