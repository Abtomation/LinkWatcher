#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates state file updates when user documentation (handbooks) is created via PF-TSK-081

.DESCRIPTION
This script automates the manual finalization updates required by the User Documentation
Creation task (PF-TSK-081), addressing the bottleneck identified in PF-IMP-245.

Updates the following files:
- Feature implementation state file (doc/product-docs/state-tracking/features/<FeatureId>-*-implementation-state.md)
  Appends a User Handbook row to the Documentation Inventory table
- documentation-map.md (doc/process-framework/documentation-map.md)
  Appends a handbook entry under the "### User Handbooks" section

.PARAMETER FeatureId
The feature ID (e.g., "6.1.1") used to locate the feature state file

.PARAMETER HandbookName
Display name for the handbook (e.g., "Link Validation")

.PARAMETER HandbookPath
Relative path from repo root to the handbook file (e.g., "doc/product-docs/user/handbooks/link-validation.md")

.PARAMETER HandbookId
The PD-UGD ID assigned to the handbook (e.g., "PD-UGD-003")

.PARAMETER Description
One-line description for the documentation-map.md entry

.EXAMPLE
# Update state files after creating a user handbook
.\Update-UserDocumentationState.ps1 -FeatureId "6.1.1" -HandbookName "Link Validation" -HandbookPath "doc/product-docs/user/handbooks/link-validation.md" -HandbookId "PD-UGD-003" -Description "On-demand workspace scan for broken file references using --validate"

.EXAMPLE
# Preview changes without modifying files
.\Update-UserDocumentationState.ps1 -FeatureId "2.1.1" -HandbookName "Custom Parsers" -HandbookPath "doc/product-docs/user/handbooks/custom-parsers.md" -HandbookId "PD-UGD-004" -Description "How to add custom file parsers" -WhatIf

.NOTES
This script addresses Process Improvement item:
- PF-IMP-245: Create Update-UserDocumentationState.ps1 automation script for PF-TSK-081 finalization

Created: 2026-03-28
Version: 1.0
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$FeatureId,

    [Parameter(Mandatory = $true)]
    [ValidateLength(3, 100)]
    [string]$HandbookName,

    [Parameter(Mandatory = $true)]
    [ValidateLength(10, 300)]
    [string]$HandbookPath,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^PD-UGD-\d+$')]
    [string]$HandbookId,

    [Parameter(Mandatory = $true)]
    [ValidateLength(10, 500)]
    [string]$Description
)

# Import the common helpers for Get-ProjectRoot
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Configuration
$ProjectRoot = Get-ProjectRoot
$DocMapFile = Join-Path -Path $ProjectRoot -ChildPath "doc/process-framework/documentation-map.md"
$FeaturesDir = Join-Path -Path $ProjectRoot -ChildPath "doc/product-docs/state-tracking/features"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"
$ScriptName = "Update-UserDocumentationState.ps1"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."

    if (-not (Test-Path $DocMapFile)) {
        Write-Log "documentation-map.md not found: $DocMapFile" -Level "ERROR"
        return $false
    }

    if (-not (Test-Path $FeaturesDir)) {
        Write-Log "Features directory not found: $FeaturesDir" -Level "ERROR"
        return $false
    }

    # Validate handbook file exists
    $handbookFullPath = Join-Path -Path $ProjectRoot -ChildPath $HandbookPath
    if (-not (Test-Path $handbookFullPath)) {
        Write-Log "Handbook file not found: $handbookFullPath" -Level "ERROR"
        Write-Log "Create the handbook first using New-Handbook.ps1 before running this script." -Level "ERROR"
        return $false
    }

    return $true
}

function Find-FeatureStateFile {
    Write-Log "Locating feature state file for $FeatureId..."

    $pattern = "$FeatureId-*-implementation-state.md"
    $matches = Get-ChildItem -Path $FeaturesDir -Filter $pattern -File

    if ($matches.Count -eq 0) {
        Write-Log "No feature state file found matching pattern: $pattern" -Level "ERROR"
        return $null
    }

    if ($matches.Count -gt 1) {
        Write-Log "Multiple feature state files found matching pattern: $pattern" -Level "WARN"
        Write-Log "Using first match: $($matches[0].Name)" -Level "WARN"
    }

    Write-Log "Found: $($matches[0].Name)"
    return $matches[0].FullName
}

function Update-FeatureStateFile {
    param([string]$StateFilePath)

    Write-Log "Updating feature state file..."

    $content = Get-Content -Path $StateFilePath -Raw

    # Build the new row for the Documentation Inventory table
    # Format: | User Handbook (PD-UGD-XXX) | User Guide | Status | [filename](relative-path) | YYYY-MM-DD |
    $handbookFilename = Split-Path -Leaf $HandbookPath

    # Calculate relative path from state file to handbook
    $stateFileDir = Split-Path -Parent $StateFilePath
    $handbookFullPath = Join-Path -Path $ProjectRoot -ChildPath $HandbookPath
    $relativePath = [System.IO.Path]::GetRelativePath($stateFileDir, $handbookFullPath) -replace '\\', '/'

    $newRow = "| User Handbook ($HandbookId) | User Guide | `u{2705} Complete | [$handbookFilename]($relativePath) | $CurrentDate |"

    # Check if a User Handbook row already exists for this handbook
    if ($content -match [regex]::Escape($HandbookId)) {
        Write-Log "Handbook $HandbookId already referenced in state file — skipping" -Level "WARN"
        return $true
    }

    # Find the Design Documentation table and append after the last row
    # Pattern: look for the table under "### Design Documentation" and append after the last | ... | row
    $lines = Get-Content -Path $StateFilePath
    $insertIndex = -1
    $inDocInventory = $false
    $inDesignDocTable = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## 4\.\s*Documentation Inventory') {
            $inDocInventory = $true
            continue
        }
        if ($inDocInventory -and $lines[$i] -match '^### Design Documentation') {
            $inDesignDocTable = $true
            continue
        }
        if ($inDesignDocTable) {
            # Skip header and separator rows
            if ($lines[$i] -match '^\|.*\|$') {
                $insertIndex = $i
            }
            # Stop if we hit a blank line or new section after table rows
            elseif ($insertIndex -gt -1 -and ($lines[$i] -match '^\s*$' -or $lines[$i] -match '^#')) {
                break
            }
        }
    }

    if ($insertIndex -eq -1) {
        Write-Log "Could not find Design Documentation table in state file" -Level "ERROR"
        Write-Log "Expected section: ## 4. Documentation Inventory > ### Design Documentation" -Level "ERROR"
        return $false
    }

    if ($PSCmdlet.ShouldProcess($StateFilePath, "Append User Handbook row to Design Documentation table")) {
        $newLines = [System.Collections.ArrayList]::new($lines)
        $newLines.Insert($insertIndex + 1, $newRow)
        $newLines | Set-Content -Path $StateFilePath -Encoding utf8
        Write-Log "Appended handbook row after line $($insertIndex + 1)" -Level "SUCCESS"
    }

    return $true
}

function Update-DocumentationMap {
    Write-Log "Updating documentation-map.md..."

    $content = Get-Content -Path $DocMapFile -Raw

    # Build the new entry
    # Format: - [Product: Handbook Name](relative-path) - Description
    # Path is relative from documentation-map.md location
    $docMapDir = Split-Path -Parent $DocMapFile
    $handbookFullPath = Join-Path -Path $ProjectRoot -ChildPath $HandbookPath
    $relativePath = [System.IO.Path]::GetRelativePath($docMapDir, $handbookFullPath) -replace '\\', '/'

    $newEntry = "- [Product: $HandbookName]($relativePath) - $Description"

    # Check if this handbook is already listed
    if ($content -match [regex]::Escape($relativePath)) {
        Write-Log "Handbook already listed in documentation-map.md — skipping" -Level "WARN"
        return $true
    }

    # Find the "### User Handbooks" section and append after the last "- [Product: ..." line
    $lines = Get-Content -Path $DocMapFile
    $insertIndex = -1
    $inUserHandbooks = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^### User Handbooks') {
            $inUserHandbooks = $true
            continue
        }
        if ($inUserHandbooks) {
            if ($lines[$i] -match '^- \[Product:') {
                $insertIndex = $i
            }
            # Stop if we hit a blank line followed by a new section, or a new ### heading
            elseif ($insertIndex -gt -1 -and $lines[$i] -match '^###?\s') {
                break
            }
            elseif ($insertIndex -gt -1 -and $lines[$i] -match '^\s*$') {
                # Blank line after entries — this is the end of the section
                break
            }
        }
    }

    if ($insertIndex -eq -1) {
        Write-Log "Could not find User Handbooks section in documentation-map.md" -Level "ERROR"
        Write-Log "Expected section: ### User Handbooks" -Level "ERROR"
        return $false
    }

    if ($PSCmdlet.ShouldProcess($DocMapFile, "Append handbook entry to User Handbooks section")) {
        $newLines = [System.Collections.ArrayList]::new($lines)
        $newLines.Insert($insertIndex + 1, $newEntry)
        $newLines | Set-Content -Path $DocMapFile -Encoding utf8
        Write-Log "Appended handbook entry after line $($insertIndex + 1)" -Level "SUCCESS"
    }

    return $true
}

# --- Main Execution ---

Write-Log "=== $ScriptName ==="
Write-Log "Feature: $FeatureId"
Write-Log "Handbook: $HandbookName ($HandbookId)"
Write-Log "Path: $HandbookPath"

# Check prerequisites
if (-not (Test-Prerequisites)) {
    Write-Log "Prerequisites check failed — aborting" -Level "ERROR"
    exit 1
}

# Find feature state file
$stateFile = Find-FeatureStateFile
if (-not $stateFile) {
    Write-Log "Cannot proceed without a feature state file — aborting" -Level "ERROR"
    exit 1
}

# Perform updates
$success = $true

Write-Log ""
Write-Log "--- Step 1: Feature State File ---"
if (-not (Update-FeatureStateFile -StateFilePath $stateFile)) {
    Write-Log "Failed to update feature state file" -Level "ERROR"
    $success = $false
}

Write-Log ""
Write-Log "--- Step 2: Documentation Map ---"
if (-not (Update-DocumentationMap)) {
    Write-Log "Failed to update documentation-map.md" -Level "ERROR"
    $success = $false
}

Write-Log ""
if ($success) {
    Write-Log "=== All updates completed successfully ===" -Level "SUCCESS"
    Write-Log ""
    Write-Log "Updated files:"
    Write-Log "  1. $(Split-Path -Leaf $stateFile)"
    Write-Log "  2. documentation-map.md"
    Write-Log ""
    Write-Log "Remaining manual steps:"
    Write-Log "  - Update feature-tracking.md if a User Docs column exists"
    Write-Log "  - Update README.md documentation table if applicable"
} else {
    Write-Log "=== Some updates failed — review errors above ===" -Level "ERROR"
    exit 1
}
