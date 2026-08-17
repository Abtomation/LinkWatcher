#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates state file updates when user documentation (handbooks) is created via PF-TSK-081

.DESCRIPTION
This script automates the manual finalization updates required by the User Documentation
Creation task (PF-TSK-081), addressing the bottleneck identified in PF-IMP-245.

Updates the following file:
- Feature implementation state file (doc/state-tracking/features/<FeatureId>-*-implementation-state.md)
  Appends a User Handbook row to the Documentation Inventory table

Note: PD-documentation-map.md is NOT updated by this script — it is generated
(Build-DocumentationMap.ps1 -Tree PD) from the handbook's own description: frontmatter
(PF-PRO-037 / PF-PRO-050); regenerate it after creating the handbook.

.PARAMETER FeatureId
The feature ID (e.g., "6.1.1") used to locate the feature state file

.PARAMETER HandbookName
Display name for the handbook (e.g., "Link Validation")

.PARAMETER HandbookPath
Relative path from repo root to the handbook file (e.g., "doc/user/handbooks/link-validation.md")

.PARAMETER HandbookId
The PD-UGD ID assigned to the handbook (e.g., "PD-UGD-003")

.PARAMETER Description
One-line description for the PD-documentation-map.md entry (10-500 chars; this is the
Documentation Inventory row description — compress longer drafts; the full content
lives in the handbook itself).

.PARAMETER ContentType
Diátaxis content type for the handbook. Valid values are declared in
doc/PD-id-registry.json under PD-UGD.subdirectories.values. Framework default:
tutorials, how-to, reference, explanation. Defaults to "how-to".

.EXAMPLE
# Update state files after creating a user handbook
Update-UserDocumentationState.ps1 -FeatureId "6.1.1" -HandbookName "Link Validation" -HandbookPath "doc/user/handbooks/how-to/link-validation.md" -HandbookId "PD-UGD-003" -ContentType "how-to" -Description "On-demand workspace scan for broken file references using --validate"

.EXAMPLE
# Preview changes without modifying files
Update-UserDocumentationState.ps1 -FeatureId "2.1.1" -HandbookName "Custom Parsers" -HandbookPath "doc/user/handbooks/how-to/custom-parsers.md" -HandbookId "PD-UGD-004" -ContentType "how-to" -Description "How to add custom file parsers" -WhatIf

.NOTES
This script addresses Process Improvement item:
- PF-IMP-245: Create Update-UserDocumentationState.ps1 automation script for PF-TSK-081 finalization

Created: 2026-03-28
Version: 1.0

Output behavior: Default output is one summary line per invocation (the outcome,
e.g. "Feature 2.1.1 → Documentation Inventory updated"). WARN and ERROR messages
always pass through. Pass -Verbose to restore the full play-by-play log.
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
    [ValidateScript({
        if ($_.Length -lt 10) {
            throw "Description is too short ($($_.Length) chars; minimum 10). Provide a more substantive description."
        }
        if ($_.Length -gt 500) {
            $over = $_.Length - 500
            throw "Description is too long ($($_.Length) chars; maximum 500, $over over). This is the Documentation Inventory row description — compress the description; the full content lives in the handbook itself."
        }
        $true
    })]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [string]$ContentType = "how-to"
)

# Import the common helpers for Get-ProjectRoot
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
# Temporarily silence $VerbosePreference around the import so -Verbose callers see
# only this script's own Write-Verbose output, not the helper module's internal chatter.
$prevVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
$VerbosePreference = $prevVerbosePreference

# Soak verification (PF-PRO-028 v2.0 Pattern A; caller-aware no-arg form)
Register-SoakScript
$soakInSoak = Test-ScriptInSoak

# Soak-verification wrapper begins (PF-PRO-028 v2.0)
try {

# Configuration
$ProjectRoot = Get-ProjectRoot
$FeaturesDir = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/features"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"
$ScriptName = "Update-UserDocumentationState.ps1"

function Test-Prerequisites {
    Write-ProjectLog "Checking prerequisites..."

    if (-not (Test-Path $FeaturesDir)) {
        Write-ProjectLog "Features directory not found: $FeaturesDir" -Level "ERROR"
        return $false
    }

    # Validate handbook file exists
    $handbookFullPath = Join-Path -Path $ProjectRoot -ChildPath $HandbookPath
    if (-not (Test-Path $handbookFullPath)) {
        Write-ProjectLog "Handbook file not found: $handbookFullPath" -Level "ERROR"
        Write-ProjectLog "Create the handbook first using New-Handbook.ps1 before running this script." -Level "ERROR"
        return $false
    }

    return $true
}

function Find-FeatureStateFile {
    Write-ProjectLog "Locating feature state file for $FeatureId..."

    $pattern = "$FeatureId-*-implementation-state.md"
    $matches = Get-ChildItem -Path $FeaturesDir -Filter $pattern -File

    if ($matches.Count -eq 0) {
        Write-ProjectLog "No feature state file found matching pattern: $pattern" -Level "ERROR"
        return $null
    }

    if ($matches.Count -gt 1) {
        Write-ProjectLog "Multiple feature state files found matching pattern: $pattern" -Level "WARN"
        Write-ProjectLog "Using first match: $($matches[0].Name)" -Level "WARN"
    }

    Write-ProjectLog "Found: $($matches[0].Name)"
    return $matches[0].FullName
}

function Update-FeatureStateFile {
    param([string]$StateFilePath)

    Write-ProjectLog "Updating feature state file..."

    $content = Get-Content -Path $StateFilePath -Raw

    # Build the new row for the Documentation Inventory table
    # Format: | User Handbook (PD-UGD-XXX) | User Guide | Status | [filename](relative-path) | YYYY-MM-DD |
    $handbookFilename = Split-Path -Leaf $HandbookPath

    # Calculate relative path from state file to handbook
    $stateFileDir = Split-Path -Parent $StateFilePath
    $handbookFullPath = Join-Path -Path $ProjectRoot -ChildPath $HandbookPath
    $relativePath = [System.IO.Path]::GetRelativePath($stateFileDir, $handbookFullPath) -replace '\\', '/'

    $newRow = "| User Handbook ($HandbookId) | $ContentType | `u{2705} Complete | [$handbookFilename]($relativePath) | $CurrentDate |"

    # Check if a User Handbook row already exists for this handbook
    if ($content -match [regex]::Escape($HandbookId)) {
        Write-ProjectLog "Handbook $HandbookId already referenced in state file — skipping" -Level "WARN"
        return $true
    }

    # Find the User Documentation table and append/replace rows
    # Pattern: look for the table under "### User Documentation" within Documentation Inventory
    $lines = Get-Content -Path $StateFilePath
    $insertIndex = -1
    $placeholderIndex = -1
    $inDocInventory = $false
    $inUserDocTable = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        # Match both "## 4." and "## 3." (lightweight template uses Section 3 for Doc Inventory)
        if ($lines[$i] -match '^## \d+\.\s*Documentation Inventory') {
            $inDocInventory = $true
            continue
        }
        if ($inDocInventory -and $lines[$i] -match '^### User Documentation') {
            $inUserDocTable = $true
            continue
        }
        if ($inUserDocTable) {
            # Track table rows (skip header and separator)
            if ($lines[$i] -match '^\|.*\|$') {
                $insertIndex = $i
                # Check for placeholder or ❌ Needed rows that should be replaced
                if ($lines[$i] -match '\[Doc name\]|\[STATUS\]|❌ Needed|❌') {
                    $placeholderIndex = $i
                }
            }
            # Stop if we hit a blank line or new section after table rows
            elseif ($insertIndex -gt -1 -and ($lines[$i] -match '^\s*$' -or $lines[$i] -match '^#')) {
                break
            }
        }
    }

    if ($insertIndex -eq -1) {
        Write-ProjectLog "Could not find User Documentation table in state file" -Level "ERROR"
        Write-ProjectLog "Expected section: ## N. Documentation Inventory > ### User Documentation" -Level "ERROR"
        Write-ProjectLog "Ensure the feature state file has a ### User Documentation subsection." -Level "ERROR"
        return $false
    }

    if ($PSCmdlet.ShouldProcess($StateFilePath, "Update User Documentation table with handbook row")) {
        $newLines = [System.Collections.ArrayList]::new($lines)
        if ($placeholderIndex -gt -1) {
            # Replace the placeholder or ❌ Needed row
            $newLines[$placeholderIndex] = $newRow
            Write-ProjectLog "Replaced placeholder/needed row at line $($placeholderIndex + 1)" -Level "SUCCESS"
        } else {
            # Append after the last table row
            $newLines.Insert($insertIndex + 1, $newRow)
            Write-ProjectLog "Appended handbook row after line $($insertIndex + 1)" -Level "SUCCESS"
        }
        $newLines | Set-Content -Path $StateFilePath -Encoding utf8
    }

    return $true
}

# --- Main Execution ---

Write-ProjectLog "=== $ScriptName ==="
Write-ProjectLog "Feature: $FeatureId"
Write-ProjectLog "Handbook: $HandbookName ($HandbookId)"
Write-ProjectLog "Path: $HandbookPath"

# Check prerequisites
if (-not (Test-Prerequisites)) {
    Write-ProjectLog "Prerequisites check failed — aborting" -Level "ERROR"
    exit 1
}

# Find feature state file
$stateFile = Find-FeatureStateFile
if (-not $stateFile) {
    Write-ProjectLog "Cannot proceed without a feature state file — aborting" -Level "ERROR"
    exit 1
}

# Perform updates
$success = $true

Write-ProjectLog ""
Write-ProjectLog "--- Feature State File ---"
if (-not (Update-FeatureStateFile -StateFilePath $stateFile)) {
    Write-ProjectLog "Failed to update feature state file" -Level "ERROR"
    $success = $false
}

Write-ProjectLog ""
if ($success) {
    Write-ProjectSummary "Feature $FeatureId → Documentation Inventory updated ($HandbookId)"
    Write-ProjectLog "Remaining manual steps:"
    Write-ProjectLog "  - Set feature status to 🟢 Completed via Update-BatchFeatureStatus.ps1"
    Write-ProjectLog "  - Update README.md documentation table if applicable"
    Write-ProjectLog "  - Regenerate PD-documentation-map.md: Build-DocumentationMap.ps1 -Tree PD (reflects the new handbook's description: frontmatter)"
} else {
    Write-ProjectLog "=== Update failed — review errors above ===" -Level "ERROR"
    exit 1
}


    # Soak: success outcome (PF-PRO-028 v2.0)
    if ($soakInSoak) { Confirm-SoakInvocation -Outcome success }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -Outcome failure -Notes $soakErrMsg
    }
    Write-Error "User documentation state update failed: $($_.Exception.Message)"
    exit 1
}
