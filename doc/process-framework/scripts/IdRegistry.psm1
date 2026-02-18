# IdRegistry.psm1
# Central ID management module for process framework projects
# Uses the central ID registry (id-registry.json) to manage document IDs

function Get-IdRegistryPath {
    <#
    .SYNOPSIS
    Gets the path to the central ID registry file
    #>
    # Navigate from scripts -> process-framework -> doc to reach the registry file
    $processFrameworkDir = Split-Path -Parent $PSScriptRoot
    $docDir = Split-Path -Parent $processFrameworkDir
    return Join-Path -Path $docDir -ChildPath "id-registry.json"
}

function Get-IdRegistry {
    <#
    .SYNOPSIS
    Loads the central ID registry
    #>
    $registryPath = Get-IdRegistryPath
    if (-not (Test-Path $registryPath)) {
        throw "Central ID registry not found at: $registryPath"
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

    $registryPath = Get-IdRegistryPath
    try {
        $content = Get-Content -Path $registryPath -Raw

        # Find the specific prefix section and update only the nextAvailable value
        # Use a more robust pattern that handles multiline JSON
        $pattern = "(`"$Prefix`":\s*\{[\s\S]*?`"nextAvailable`":\s*)(\d+)"
        $replacement = "`${1}$NewValue"

        $updatedContent = $content -replace $pattern, $replacement

        if ($updatedContent -eq $content) {
            Write-Warning "No nextAvailable counter found for prefix '$Prefix' - update skipped"
        } else {
            $updatedContent | Set-Content -Path $registryPath -Encoding UTF8 -NoNewline
            Write-Verbose "Updated nextAvailable for $Prefix to $NewValue (formatting preserved)"
        }
    }
    catch {
        Write-Warning "Failed to update nextAvailable counter: $($_.Exception.Message)"
    }
}

function Save-IdRegistry {
    <#
    .SYNOPSIS
    Saves the ID registry back to disk
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Registry
    )

    $registryPath = Get-IdRegistryPath
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

    $registry = Get-IdRegistry

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

    $registry = Get-IdRegistry

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

    $registry = Get-IdRegistry

    # Parse the ID to get prefix and number
    if ($Id -match '^([A-Z]+-[A-Z]+)-(\d+)$') {
        $prefix = $matches[1]
        $number = [int]$matches[2]

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

    $registry = Get-IdRegistry

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
    # Returns: "doc/process-framework/tasks/discrete"

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
                if ($ProjectRoot -and -not [System.IO.Path]::IsPathRooted($path)) {
                    return Join-Path -Path $ProjectRoot -ChildPath $path
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
            if ($ProjectRoot -and -not [System.IO.Path]::IsPathRooted($path)) {
                $allDirectories += Join-Path -Path $ProjectRoot -ChildPath $path
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
                if ([System.IO.Path]::IsPathRooted($_)) {
                    $_
                } else {
                    Join-Path -Path $ProjectRoot -ChildPath $_
                }
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
        if ($ProjectRoot -and -not [System.IO.Path]::IsPathRooted($defaultPath)) {
            return Join-Path -Path $ProjectRoot -ChildPath $defaultPath
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
    Get-DirectoryForPrefixType -Prefix "ART-FEE" -DirectoryType "forms"
    # Returns: "doc/process-framework/feedback/feedback-forms"
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
    Test-ValidDirectoryForPrefix -Prefix "ART-FEE" -Directory "doc/process-framework/feedback/feedback-forms"
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
    Gets all available prefixes and their information
    #>
    $registry = Get-IdRegistry

    $prefixes = @()
    foreach ($prefix in $registry.prefixes.PSObject.Properties) {
        $prefixes += [PSCustomObject]@{
            Prefix = $prefix.Name
            Description = $prefix.Value.description
            Category = $prefix.Value.category
            Type = $prefix.Value.type
            NextAvailable = $prefix.Value.nextAvailable
            LastAssigned = $prefix.Value.nextAvailable - 1
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
