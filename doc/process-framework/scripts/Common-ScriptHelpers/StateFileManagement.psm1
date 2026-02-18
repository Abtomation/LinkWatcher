# StateFileManagement.psm1
# State file operations and tracking file management
# VERSION 4.0 - REFACTORED MODULAR ARCHITECTURE
# This module now imports specialized sub-modules while maintaining full backward compatibility

<#
.SYNOPSIS
State file operations and tracking file management for PowerShell scripts

.DESCRIPTION
This module provides functionality for:
- Markdown table updates and manipulation (via TableOperations.psm1)
- File operations and backups (via FileOperations.psm1)
- Feature tracking operations (via FeatureTracking.psm1)
- Document tracking operations (via DocumentTracking.psm1)
- Test tracking operations (via TestTracking.psm1)

VERSION 4.0 uses a modular architecture where functionality is split across
focused sub-modules, but maintains complete backward compatibility.

.NOTES
Version: 4.0 (Refactored Modular Architecture)
Created: 2025-08-26
Refactored: 2025-08-30
Architecture: Modular with backward compatibility
Refactoring Plan: PF-REF-014
#>

# Configure UTF-8 encoding for consistent Unicode support
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Get the directory where this module is located
$ModuleDirectory = $PSScriptRoot

# Import core dependencies first
$coreModule = Join-Path -Path $ModuleDirectory -ChildPath "Core.psm1"
$outputModule = Join-Path -Path $ModuleDirectory -ChildPath "OutputFormatting.psm1"

if (Test-Path $coreModule) {
    Import-Module $coreModule -Force -Global
    Write-Verbose "Loaded Core module: $coreModule"
} else {
    Write-Warning "Core module not found: $coreModule"
}

if (Test-Path $outputModule) {
    Import-Module $outputModule -Force -Global
    Write-Verbose "Loaded OutputFormatting module: $outputModule"
} else {
    Write-Warning "OutputFormatting module not found: $outputModule"
}

# Import extracted sub-modules
$SubModules = @(
    "TableOperations.psm1",
    "FileOperations.psm1",
    "FeatureTracking.psm1",
    "DocumentTracking.psm1",
    "TestTracking.psm1"
)

Write-Verbose "Loading StateFileManagement v4.0 (Refactored Modular Architecture)"

$LoadedFunctions = @()

foreach ($subModule in $SubModules) {
    $subModulePath = Join-Path -Path $ModuleDirectory -ChildPath $subModule

    if (Test-Path $subModulePath) {
        try {
            # Import the module and get its exported functions
            $moduleInfo = Import-Module $subModulePath -Force -PassThru -ErrorAction Stop
            $exportedFunctions = $moduleInfo.ExportedFunctions.Keys
            $LoadedFunctions += $exportedFunctions
            Write-Verbose "Loaded sub-module: $subModule with $($exportedFunctions.Count) functions"
        }
        catch {
            Write-Warning "Failed to load sub-module $subModule`: $($_.Exception.Message)"
            Write-Verbose "Error details: $($_.Exception.ToString())"
            # Continue loading other modules even if one fails
        }
    } else {
        Write-Warning "Sub-module not found: $subModulePath"
    }
}

# All functions are now provided by the extracted sub-modules
# No temporary implementations needed
# Collect all functions for export (all from loaded sub-modules)
$AllExportedFunctions = $LoadedFunctions

# Export all functions to maintain backward compatibility
Write-Verbose "Exporting functions: $($AllExportedFunctions -join ', ')"
Export-ModuleMember -Function $AllExportedFunctions

Write-Verbose "StateFileManagement v4.0 loaded successfully with $($AllExportedFunctions.Count) functions from $($SubModules.Count) sub-modules"

# Display architecture information if verbose
if ($VerbosePreference -eq 'Continue') {
    Write-Host "`n=== StateFileManagement v4.0 Refactored Architecture ===" -ForegroundColor Cyan
    Write-Host "Sub-modules loaded: $($SubModules.Count)" -ForegroundColor Green
    Write-Host "Functions from sub-modules: $($LoadedFunctions.Count)" -ForegroundColor Yellow
    Write-Host "Total Functions: $($AllExportedFunctions.Count)" -ForegroundColor Green
    Write-Host "Architecture: Modular with backward compatibility" -ForegroundColor Green
    Write-Host "Refactoring Status: Phase 3 Complete (All modules extracted)" -ForegroundColor Green
    Write-Host "========================================================`n" -ForegroundColor Cyan
}
