# OutputFormatting.psm1
# Output formatting and utility functions for PowerShell scripts
# Provides standardized messaging, path operations, and string utilities

<#
.SYNOPSIS
Output formatting and utility functions for PowerShell scripts

.DESCRIPTION
This module provides standardized functionality for:
- Success and error message formatting
- Path validation and creation
- Timestamp generation in various formats
- String conversion utilities
- File conflict handling

.NOTES
Version: 3.0 (Modularized from Common-ScriptHelpers v2.0)
Created: 2025-08-26
#>

function Write-ProjectSuccess {
    <#
    .SYNOPSIS
    Writes a standardized success message

    .PARAMETER Message
    The success message to display

    .PARAMETER Details
    Optional array of detail lines to display
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string[]]$Details = @()
    )

    Write-Host "✅ $Message" -ForegroundColor Green

    foreach ($detail in $Details) {
        Write-Host "   $detail" -ForegroundColor Gray
    }
}

function Write-ProjectError {
    <#
    .SYNOPSIS
    Writes a standardized error message and optionally exits

    .PARAMETER Message
    The error message to display

    .PARAMETER ExitCode
    Exit code (if provided, script will exit)
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [int]$ExitCode
    )

    Write-Host "❌ $Message" -ForegroundColor Red

    if ($ExitCode) {
        exit $ExitCode
    }
}

function Test-ProjectPath {
    <#
    .SYNOPSIS
    Tests if a path exists, with option to create it

    .PARAMETER Path
    Path to test

    .PARAMETER CreateIfMissing
    Create the path if it doesn't exist

    .PARAMETER PathType
    Type of path (File or Directory)
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [switch]$CreateIfMissing,

        [Parameter(Mandatory=$false)]
        [ValidateSet("File", "Directory")]
        [string]$PathType = "Directory"
    )

    if (Test-Path $Path) {
        return $true
    }

    if ($CreateIfMissing) {
        try {
            if ($PathType -eq "Directory") {
                New-Item -ItemType Directory -Path $Path -Force | Out-Null
                Write-Verbose "Created directory: $Path"
            } else {
                $parentDir = Split-Path -Parent $Path
                if ($parentDir -and -not (Test-Path $parentDir)) {
                    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                }
                New-Item -ItemType File -Path $Path -Force | Out-Null
                Write-Verbose "Created file: $Path"
            }
            return $true
        }
        catch {
            Write-Warning "Failed to create $PathType at $Path`: $($_.Exception.Message)"
            return $false
        }
    }

    return $false
}

function Get-ProjectTimestamp {
    <#
    .SYNOPSIS
    Gets standardized timestamps in various formats

    .PARAMETER Format
    The timestamp format to return

    .EXAMPLE
    Get-ProjectTimestamp -Format "Date"
    # Returns: "2025-07-08"

    .EXAMPLE
    Get-ProjectTimestamp -Format "FileTimestamp"
    # Returns: "20250708-134136"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("Date", "Time", "FileTimestamp", "DateTime")]
        [string]$Format = "Date"
    )

    switch ($Format) {
        "Date" { return Get-Date -Format "yyyy-MM-dd" }
        "Time" { return Get-Date -Format "HHmmss" }
        "FileTimestamp" { return Get-Date -Format "yyyyMMdd-HHmmss" }
        "DateTime" { return Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
    }
}

function ConvertTo-KebabCase {
    <#
    .SYNOPSIS
    Converts a string to kebab-case for use in filenames

    .PARAMETER InputString
    The string to convert

    .EXAMPLE
    ConvertTo-KebabCase -InputString "User Authentication System"
    # Returns: "user-authentication-system"

    .EXAMPLE
    ConvertTo-KebabCase -InputString "My Feature Name!!!"
    # Returns: "my-feature-name"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputString
    )

    return $InputString.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''
}

function Test-ProjectFileConflict {
    <#
    .SYNOPSIS
    Tests if a file already exists and handles conflicts appropriately

    .PARAMETER FilePath
    The file path to check

    .PARAMETER ConflictAction
    Action to take if file exists: Error, Overwrite, or Skip

    .PARAMETER ErrorMessage
    Custom error message if file exists (used with Error action)

    .EXAMPLE
    Test-ProjectFileConflict -FilePath "output.md" -ConflictAction "Error" -ErrorMessage "Task already exists"

    .EXAMPLE
    $canProceed = Test-ProjectFileConflict -FilePath "output.md" -ConflictAction "Skip"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Error", "Overwrite", "Skip")]
        [string]$ConflictAction = "Error",

        [Parameter(Mandatory=$false)]
        [string]$ErrorMessage = "File already exists"
    )

    if (-not (Test-Path $FilePath)) {
        return $true  # No conflict, can proceed
    }

    switch ($ConflictAction) {
        "Error" {
            throw "$ErrorMessage at $FilePath"
        }
        "Overwrite" {
            Write-Warning "Overwriting existing file: $FilePath"
            return $true
        }
        "Skip" {
            Write-Warning "Skipping existing file: $FilePath"
            return $false
        }
    }
}

function Invoke-StandardScriptInitialization {
    <#
    .SYNOPSIS
    Performs standard initialization for PowerShell scripts

    .DESCRIPTION
    Sets up standard error handling, encoding, and initializes the script environment.
    This function should be called at the start of each script that uses Common-ScriptHelpers.
    #>

    [CmdletBinding()]
    param()

    # Configure error handling
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($VerbosePreference -eq "Continue") { "Continue" } else { "SilentlyContinue" }

    # Configure UTF-8 encoding
    $PSDefaultParameterValues['*:Encoding'] = 'UTF8'
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8

    Write-Verbose "Standard script initialization completed"
}

# Export functions
Export-ModuleMember -Function @(
    'Write-ProjectSuccess',
    'Write-ProjectError',
    'Test-ProjectPath',
    'Get-ProjectTimestamp',
    'ConvertTo-KebabCase',
    'Test-ProjectFileConflict',
    'Invoke-StandardScriptInitialization'
)
