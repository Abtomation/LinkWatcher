# AdvancedUtilities.psm1
# Advanced utility functions and dependency management
# Provides script dependency validation, enhanced utilities, and specialized operations

<#
.SYNOPSIS
Advanced utility functions and dependency management for PowerShell scripts

.DESCRIPTION
This module provides functionality for:
- Script dependency validation and fixing
- Enhanced utility functions
- Specialized operations for complex scenarios
- System integration utilities
- Advanced error handling and recovery

.NOTES
Version: 3.0 (Modularized from Common-ScriptHelpers v2.0)
Created: 2025-08-26
#>

# Import dependencies
$scriptPath = Split-Path -Parent $PSScriptRoot
$coreModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers\Core.psm1"
$outputModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers\OutputFormatting.psm1"

if (Test-Path $coreModule) { Import-Module $coreModule -Force }
if (Test-Path $outputModule) { Import-Module $outputModule -Force }

function Test-ScriptDependencies {
    <#
    .SYNOPSIS
    Validates that all required script dependencies are available

    .PARAMETER ScriptPath
    Path to the script to validate dependencies for

    .PARAMETER RequiredModules
    Array of required PowerShell modules

    .PARAMETER RequiredFunctions
    Array of required functions that should be available

    .PARAMETER FixMissingDependencies
    Attempt to automatically fix missing dependencies

    .EXAMPLE
    Test-ScriptDependencies -ScriptPath "New-TestSpecification.ps1" -RequiredModules @("Common-ScriptHelpers")

    .EXAMPLE
    Test-ScriptDependencies -RequiredFunctions @("Get-ProjectRoot", "New-ProjectId") -FixMissingDependencies
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ScriptPath,

        [Parameter(Mandatory=$false)]
        [string[]]$RequiredModules = @(),

        [Parameter(Mandatory=$false)]
        [string[]]$RequiredFunctions = @(),

        [Parameter(Mandatory=$false)]
        [switch]$FixMissingDependencies
    )

    try {
        $dependencyResults = @{
            ScriptPath = $ScriptPath
            MissingModules = @()
            MissingFunctions = @()
            AvailableModules = @()
            AvailableFunctions = @()
            AllDependenciesMet = $true
        }

        Write-Verbose "Validating script dependencies"

        # Check required modules
        foreach ($module in $RequiredModules) {
            try {
                # Check already-loaded modules first (catches project-local modules
                # imported by path), then fall back to ListAvailable for installed modules
                $moduleInfo = Get-Module -Name $module -ErrorAction SilentlyContinue
                if (-not $moduleInfo) {
                    $moduleInfo = Get-Module -Name $module -ListAvailable -ErrorAction SilentlyContinue
                }
                if ($moduleInfo) {
                    $dependencyResults.AvailableModules += $module
                    Write-Verbose "Module available: $module"
                } else {
                    $dependencyResults.MissingModules += $module
                    $dependencyResults.AllDependenciesMet = $false
                    Write-Warning "Module not found: $module"
                }
            }
            catch {
                $dependencyResults.MissingModules += $module
                $dependencyResults.AllDependenciesMet = $false
                Write-Warning "Module not available: $module"

                if ($FixMissingDependencies) {
                    try {
                        # Attempt to import the module
                        if ($module -eq "Common-ScriptHelpers") {
                            $projectRoot = Get-ProjectRoot
                            $modulePath = Join-Path $projectRoot "process-framework/scripts/Common-ScriptHelpers.psm1"
                            if (Test-Path $modulePath) {
                                Import-Module $modulePath -Force
                                Write-Host "Successfully imported: $module" -ForegroundColor Green
                                $dependencyResults.AvailableModules += $module
                                $dependencyResults.MissingModules = $dependencyResults.MissingModules | Where-Object { $_ -ne $module }
                            }
                        }
                    }
                    catch {
                        Write-Warning "Could not fix missing module: $module"
                    }
                }
            }
        }

        # Check required functions
        foreach ($function in $RequiredFunctions) {
            try {
                $functionInfo = Get-Command -Name $function -ErrorAction Stop
                if ($functionInfo) {
                    $dependencyResults.AvailableFunctions += $function
                    Write-Verbose "Function available: $function"
                } else {
                    $dependencyResults.MissingFunctions += $function
                    $dependencyResults.AllDependenciesMet = $false
                    Write-Warning "Function not found: $function"
                }
            }
            catch {
                $dependencyResults.MissingFunctions += $function
                $dependencyResults.AllDependenciesMet = $false
                Write-Warning "Function not available: $function"

                if ($FixMissingDependencies) {
                    try {
                        # Attempt to load Common-ScriptHelpers if function is missing
                        $projectRoot = Get-ProjectRoot
                        $modulePath = Join-Path $projectRoot "process-framework/scripts/Common-ScriptHelpers.psm1"
                        if (Test-Path $modulePath) {
                            Import-Module $modulePath -Force

                            # Check if function is now available
                            $functionInfo = Get-Command -Name $function -ErrorAction SilentlyContinue
                            if ($functionInfo) {
                                Write-Host "Successfully loaded function: $function" -ForegroundColor Green
                                $dependencyResults.AvailableFunctions += $function
                                $dependencyResults.MissingFunctions = $dependencyResults.MissingFunctions | Where-Object { $_ -ne $function }
                            }
                        }
                    }
                    catch {
                        Write-Warning "Could not fix missing function: $function"
                    }
                }
            }
        }

        # Update overall status
        $dependencyResults.AllDependenciesMet = ($dependencyResults.MissingModules.Count -eq 0) -and ($dependencyResults.MissingFunctions.Count -eq 0)

        return $dependencyResults
    }
    catch {
        throw "Error validating script dependencies: $($_.Exception.Message)"
    }
}

function Invoke-SafeScriptExecution {
    <#
    .SYNOPSIS
    Executes a script block with enhanced error handling and recovery

    .PARAMETER ScriptBlock
    The script block to execute

    .PARAMETER MaxRetries
    Maximum number of retry attempts (default: 3)

    .PARAMETER RetryDelay
    Delay between retries in seconds (default: 1)

    .PARAMETER OnError
    Action to take on error: Stop, Continue, or Retry

    .EXAMPLE
    Invoke-SafeScriptExecution -ScriptBlock { Get-Content "file.txt" } -MaxRetries 2
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory=$false)]
        [int]$RetryDelay = 1,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Stop", "Continue", "Retry")]
        [string]$OnError = "Retry"
    )

    $attempt = 0
    $lastError = $null

    while ($attempt -lt $MaxRetries) {
        $attempt++

        try {
            Write-Verbose "Executing script block (attempt $attempt of $MaxRetries)"
            $result = & $ScriptBlock
            return @{
                Success = $true
                Result = $result
                Attempts = $attempt
                Error = $null
            }
        }
        catch {
            $lastError = $_.Exception
            Write-Warning "Attempt $attempt failed: $($lastError.Message)"

            if ($OnError -eq "Stop") {
                throw $lastError
            }
            elseif ($OnError -eq "Continue") {
                return @{
                    Success = $false
                    Result = $null
                    Attempts = $attempt
                    Error = $lastError
                }
            }
            elseif ($OnError -eq "Retry" -and $attempt -lt $MaxRetries) {
                Write-Verbose "Retrying in $RetryDelay seconds..."
                Start-Sleep -Seconds $RetryDelay
            }
        }
    }

    # All retries exhausted
    return @{
        Success = $false
        Result = $null
        Attempts = $attempt
        Error = $lastError
    }
}

function Invoke-FileWriteWithRetry {
    <#
    .SYNOPSIS
    Executes a file-write script block, retrying briefly on IOException to absorb LinkWatcher contention.

    .DESCRIPTION
    Runs the supplied $ScriptBlock and catches [System.IO.IOException] only. Other exceptions
    (parsing errors, malformed-row writes, permission errors) are re-thrown immediately so they
    surface as real bugs rather than being masked by retries. Backoff is exponential.

    Use at Set-Content / Add-Content / Out-File call sites that target tracked files which
    LinkWatcher monitors (e.g., process-improvement-tracking.md). PowerShell's Set-Content
    opens with FileShare.None and fails with IOException when LinkWatcher briefly holds the
    file open while computing diffs. Three retries at 200ms / 400ms / 800ms (~1.4s worst case)
    cover the typical contention window.

    .PARAMETER ScriptBlock
    The file-write script block to execute.

    .PARAMETER MaxRetries
    Maximum number of retry attempts after the initial try (default: 3 → up to 4 total attempts).

    .PARAMETER InitialDelayMs
    Initial backoff delay in milliseconds; doubles after each failure (default: 200).

    .PARAMETER Context
    Short label used in the warning message on retry (e.g., "process-improvement-tracking.md").

    .EXAMPLE
    Invoke-FileWriteWithRetry -ScriptBlock {
        Set-Content -Path $TrackingFile -Value $content -NoNewline -Encoding UTF8
    } -Context $TrackingFile

    .NOTES
    Filed under PF-IMP-718 (LinkWatcher mid-batch file-lock contention).
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5000)]
        [int]$InitialDelayMs = 200,

        [Parameter(Mandatory = $false)]
        [string]$Context = ""
    )

    $delay = $InitialDelayMs
    for ($attempt = 0; $attempt -le $MaxRetries; $attempt++) {
        try {
            return & $ScriptBlock
        }
        catch [System.IO.IOException] {
            if ($attempt -ge $MaxRetries) {
                throw
            }
            $label = if ($Context) { " ($Context)" } else { "" }
            Write-Warning "File-write contention$label, retry $($attempt + 1)/$MaxRetries in ${delay}ms: $($_.Exception.Message)"
            Start-Sleep -Milliseconds $delay
            $delay *= 2
        }
    }
}

function Get-SystemEnvironmentInfo {
    <#
    .SYNOPSIS
    Gets comprehensive system environment information for debugging

    .EXAMPLE
    $envInfo = Get-SystemEnvironmentInfo
    #>

    [CmdletBinding()]
    param()

    try {
        $envInfo = @{
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            PowerShellEdition = $PSVersionTable.PSEdition
            OperatingSystem = $PSVersionTable.OS
            Platform = $PSVersionTable.Platform
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            CurrentDirectory = Get-Location
            ScriptRoot = $PSScriptRoot
            ExecutionPolicy = Get-ExecutionPolicy
            Modules = @()
            EnvironmentVariables = @{}
        }

        # Get loaded modules
        $loadedModules = Get-Module | Select-Object Name, Version, Path
        $envInfo.Modules = $loadedModules

        # Get relevant environment variables
        $relevantVars = @("PATH", "TEMP", "TMP", "USERPROFILE", "PROGRAMFILES", "PROGRAMFILES(X86)")
        foreach ($var in $relevantVars) {
            $value = [Environment]::GetEnvironmentVariable($var)
            if ($value) {
                $envInfo.EnvironmentVariables[$var] = $value
            }
        }

        return $envInfo
    }
    catch {
        Write-Warning "Could not gather complete environment information: $($_.Exception.Message)"
        return @{
            Error = $_.Exception.Message
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            CurrentDirectory = Get-Location
        }
    }
}

function Test-ModuleCompatibility {
    <#
    .SYNOPSIS
    Tests compatibility between different modules and PowerShell versions

    .PARAMETER ModuleName
    Name of the module to test

    .PARAMETER RequiredVersion
    Required version of the module

    .EXAMPLE
    Test-ModuleCompatibility -ModuleName "Common-ScriptHelpers" -RequiredVersion "2.0"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleName,

        [Parameter(Mandatory=$false)]
        [string]$RequiredVersion
    )

    try {
        $compatibilityResult = @{
            ModuleName = $ModuleName
            RequiredVersion = $RequiredVersion
            AvailableVersions = @()
            IsCompatible = $false
            LoadedSuccessfully = $false
            Issues = @()
        }

        # Check if module is available
        $availableModules = Get-Module -Name $ModuleName -ListAvailable
        if ($availableModules) {
            $compatibilityResult.AvailableVersions = $availableModules | ForEach-Object { $_.Version.ToString() }
            $compatibilityResult.IsCompatible = $true

            # Check version compatibility if required version specified
            if ($RequiredVersion) {
                $requiredVersionObj = [Version]$RequiredVersion
                $compatibleVersions = $availableModules | Where-Object { $_.Version -ge $requiredVersionObj }

                if (-not $compatibleVersions) {
                    $compatibilityResult.IsCompatible = $false
                    $compatibilityResult.Issues += "No compatible version found. Required: $RequiredVersion, Available: $($compatibilityResult.AvailableVersions -join ', ')"
                }
            }

            # Test loading the module
            try {
                Import-Module -Name $ModuleName -Force -ErrorAction Stop
                $compatibilityResult.LoadedSuccessfully = $true
            }
            catch {
                $compatibilityResult.LoadedSuccessfully = $false
                $compatibilityResult.Issues += "Failed to load module: $($_.Exception.Message)"
            }
        } else {
            $compatibilityResult.Issues += "Module not found: $ModuleName"
        }

        return $compatibilityResult
    }
    catch {
        return @{
            ModuleName = $ModuleName
            RequiredVersion = $RequiredVersion
            IsCompatible = $false
            LoadedSuccessfully = $false
            Issues = @("Error testing compatibility: $($_.Exception.Message)")
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Test-ScriptDependencies',
    'Invoke-SafeScriptExecution',
    'Invoke-FileWriteWithRetry',
    'Get-SystemEnvironmentInfo',
    'Test-ModuleCompatibility'
)
