# Common-ScriptHelpers.psm1
# Unified helper functions for all PowerShell scripts in the project
# Provides standardized module loading, path resolution, and common operations
#
# VERSION 3.0 - MODULARIZED ARCHITECTURE
# This is now a facade module that imports all specialized sub-modules
# while maintaining full backward compatibility with existing scripts.

<#
.SYNOPSIS
Common helper functions for PowerShell scripts across the project

.DESCRIPTION
This module provides standardized functionality that all PowerShell scripts need:
- Module loading with consistent error handling
- Path resolution from any script location
- Common validation and utility functions
- Standardized output formatting
- Document creation and management
- State file operations
- Batch processing capabilities
- Advanced utilities and dependency management

This version (3.0) uses a modular architecture where functionality is split across
focused sub-modules, but maintains complete backward compatibility.

.NOTES
Version: 3.0 (Modularized Architecture)
Created: 2025-07-08
Updated: 2025-08-26
Architecture: Facade pattern with specialized sub-modules
#>

# Configure UTF-8 encoding for consistent Unicode support
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Get the directory where this module is located
$ModuleDirectory = $PSScriptRoot
$SubModulesDirectory = Join-Path -Path $ModuleDirectory -ChildPath "Common-ScriptHelpers"

# Import all sub-modules and collect their functions
$SubModules = @(
    "Core.psm1",
    "OutputFormatting.psm1",
    "DocumentManagement.psm1",
    "StateFileManagement.psm1",
    "BatchProcessing.psm1",
    "AdvancedUtilities.psm1"
)

Write-Verbose "Loading Common-ScriptHelpers v3.0 (Modularized Architecture)"

$LoadedFunctions = @()

foreach ($subModule in $SubModules) {
    $subModulePath = Join-Path -Path $SubModulesDirectory -ChildPath $subModule

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
            # Continue loading other modules even if one fails
        }
    } else {
        Write-Warning "Sub-module not found: $subModulePath"
    }
}

# Export all functions from sub-modules to maintain backward compatibility
# This ensures that scripts importing Common-ScriptHelpers continue to work exactly as before

# Use the functions we collected during loading, or fall back to static list
if ($LoadedFunctions.Count -gt 0) {
    $AllExportedFunctions = $LoadedFunctions
    Write-Verbose "Exporting $($LoadedFunctions.Count) functions from loaded sub-modules"
} else {
    Write-Verbose "Using static function list for export"

    # Core functions
    $CoreFunctions = @(
        'Get-ProjectRoot',
        'Import-ProjectModule',
        'New-ProjectId',
        'Get-ProjectIdDirectory',
        'Get-ProjectConfig',
        'Get-DomainConfig'
    )

    # Output formatting functions
    $OutputFunctions = @(
        'Write-ProjectSuccess',
        'Write-ProjectError',
        'Test-ProjectPath',
        'Get-ProjectTimestamp',
        'ConvertTo-KebabCase',
        'Test-ProjectFileConflict',
        'Invoke-StandardScriptInitialization'
    )

    # Document management functions
    $DocumentFunctions = @(
        'New-ProjectDocumentMetadata',
        'Open-ProjectFileInEditor',
        'Get-TemplateMetadata',
        'Get-TemplateContentWithoutMetadata',
        'Invoke-StandardScriptInitialization',
        'New-ProjectDocumentWithMetadata',
        'New-ProjectDocumentWithCodeMetadata',
        'New-ProjectCodeMetadata',
        'New-StandardProjectDocument'
    )

    # State file management functions
    $StateFunctions = @(
        'Update-MarkdownTable',
        'Update-MultipleTrackingFiles',
        'Get-RelevantTrackingFiles',
        'Get-StateFileBackup',
        'Update-FeatureTrackingStatus'
    )

    # Batch processing functions
    $BatchFunctions = @(
        'Invoke-BatchFileOperation',
        'Invoke-ParallelFileOperation',
        'New-BatchOperationReport'
    )

    # Advanced utility functions
    $AdvancedFunctions = @(
        'Test-ScriptDependencies',
        'Invoke-SafeScriptExecution',
        'Get-SystemEnvironmentInfo',
        'Test-ModuleCompatibility'
    )

    # Combine all functions for export
    $AllExportedFunctions = $CoreFunctions + $OutputFunctions + $DocumentFunctions + $StateFunctions + $BatchFunctions + $AdvancedFunctions
}

# Export all functions to maintain backward compatibility
Export-ModuleMember -Function $AllExportedFunctions

Write-Verbose "Common-ScriptHelpers v3.0 loaded successfully with $($AllExportedFunctions.Count) functions from $($SubModules.Count) sub-modules"

# Display architecture information if verbose
if ($VerbosePreference -eq 'Continue') {
    Write-Host "`n=== Common-ScriptHelpers v3.0 Architecture ===" -ForegroundColor Cyan
    Write-Host "Sub-modules loaded: $($SubModules.Count)" -ForegroundColor Green
    Write-Host "Total Functions: $($AllExportedFunctions.Count)" -ForegroundColor Yellow
    Write-Host "Architecture: Modular facade pattern" -ForegroundColor Green
    Write-Host "Backward Compatibility: Full" -ForegroundColor Green
    Write-Host "============================================`n" -ForegroundColor Cyan
}
