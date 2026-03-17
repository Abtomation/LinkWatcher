#!/usr/bin/env pwsh

# [SCRIPT_NAME].ps1
# Automates [TARGET_DESCRIPTION] updates in [TARGET_FILE_NAME]
# Uses the content-transformer pattern for single read-modify-write cycle

<#
.SYNOPSIS
    Automates [TARGET_DESCRIPTION] updates in [TARGET_FILE_NAME]

.DESCRIPTION
    This script automates [LIFECYCLE_DESCRIPTION] in [TARGET_FILE_NAME].

    Updates the following file:
    - [TARGET_FILE_RELATIVE_PATH]

    [ADDITIONAL_DESCRIPTION]

.PARAMETER [PRIMARY_ID_PARAMETER]
    The [entity] ID to update (e.g., "[ID_EXAMPLE]")

.PARAMETER NewStatus
    The new status. Valid values: [STATUS_VALUES]

.PARAMETER [ADDITIONAL_PARAMETER]
    [Parameter description]

.EXAMPLE
    .\[SCRIPT_NAME].ps1 -[PRIMARY_ID_PARAMETER] "[ID_EXAMPLE]" -NewStatus "[STATUS_EXAMPLE]"

.NOTES
    This script is part of the [SYSTEM_NAME] and integrates with:
    - [RELATED_TASK] ([TASK_ID])

    Template Metadata:
    - Template ID: PF-TEM-047
    - Template Type: Update Script (Content-Transformer Pattern)
    - Created: 2026-02-28
    - For: Creating PowerShell scripts that update markdown state files via content transformation
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('[VALIDATION_PATTERN]')]
    [string]$[PRIMARY_ID_PARAMETER],

    [Parameter(Mandatory = $true)]
    [ValidateSet([STATUS_VALUES_LIST])]
    [string]$NewStatus

    # [ADD_ADDITIONAL_PARAMETERS_HERE]
    # Example:
    # ,
    # [Parameter(Mandatory = $false)]
    # [string]$Notes,
    #
    # [Parameter(Mandatory = $false)]
    # [string]$UpdatedBy = "AI Agent (PF-TSK-XXX)"
)

# --- Configuration ---

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "[RELATIVE_PATH_TO_HELPERS]/Common-ScriptHelpers.psm1") -Force

$ProjectRoot = Get-ProjectRoot
$TargetFile = Join-Path -Path $ProjectRoot -ChildPath "[TARGET_FILE_RELATIVE_PATH]"
$ScriptName = "[SCRIPT_NAME].ps1"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

# --- Shared utilities ---

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

    if (-not (Test-Path $TargetFile)) {
        Write-Log "Target file not found: $TargetFile" -Level "ERROR"
        return $false
    }

    # [ADD_ADDITIONAL_PREREQUISITE_CHECKS_HERE]
    # Example: Validate required parameters for specific status transitions
    # if ($NewStatus -eq "Completed" -and -not $Notes) {
    #     Write-Log "Notes are required when transitioning to Completed" -Level "ERROR"
    #     return $false
    # }

    Write-Log "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

# --- Content-transformer functions ---
# Each takes a $Content string and returns modified $Content string.
# This enables a single read-modify-write cycle in Main.
# Return $null to signal an error.

# [REPLACE_WITH_CONTENT_TRANSFORMER_FUNCTIONS]
#
# Example — update a status column in a markdown table row:
#
# function Update-StatusInPlace {
#     param(
#         [string]$Content,
#         [string]$EntityId,
#         [string]$NewStatus
#     )
#
#     # Find the entity row in the table
#     $pattern = "\|\s*$EntityId\s*\|[^\r\n]*"
#     $match = [regex]::Match($Content, $pattern)
#
#     if (-not $match.Success) {
#         Write-Log "Entry not found: $EntityId" -Level "ERROR"
#         return $null
#     }
#
#     $currentEntry = $match.Value
#     Write-Log "Found entry for $EntityId"
#
#     # Parse columns: | Col1 | Col2 | Status | ... |
#     $columns = $currentEntry -split '\|' | ForEach-Object { $_.Trim() }
#     if ($columns[0] -eq '') { $columns = $columns[1..($columns.Length - 1)] }
#     if ($columns[-1] -eq '') { $columns = $columns[0..($columns.Length - 2)] }
#
#     # Update the relevant column (adjust index for your table structure)
#     $columns[2] = $NewStatus
#
#     $updatedEntry = "| " + ($columns -join " | ") + " |"
#     $result = $Content.Replace($currentEntry, $updatedEntry)
#
#     Write-Log "Updated $EntityId status to: $NewStatus" -Level "SUCCESS"
#     return $result
# }
#
# Example — move a row from one section to another:
#
# function Move-ToCompletedSection {
#     param(
#         [string]$Content,
#         [string]$EntityId
#     )
#
#     $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")
#
#     # Find and remove the row from the active table
#     $rowIndex = -1
#     for ($i = 0; $i -lt $lines.Count; $i++) {
#         if ($lines[$i] -match "^\|\s*$EntityId\s*\|") {
#             $rowIndex = $i
#             break
#         }
#     }
#     if ($rowIndex -eq -1) {
#         Write-Log "Could not find $EntityId" -Level "ERROR"
#         return $null
#     }
#
#     $row = $lines[$rowIndex]
#     $lines.RemoveAt($rowIndex)
#
#     # Find insertion point in completed section
#     # ... (find the last data row or separator in the target section)
#
#     # $lines.Insert($insertAfterIndex + 1, $row)
#     # return ($lines -join "`r`n")
# }
#
# Example — update frontmatter date:
#
# function Update-FrontmatterDate {
#     param([string]$Content)
#     $result = $Content -replace '(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate
#     Write-Log "Updated frontmatter date to $CurrentDate" -Level "SUCCESS"
#     return $result
# }

# --- Main ---

function Main {
    Write-Log "Starting update - $ScriptName"
    Write-Log "[PRIMARY_ID_PARAMETER]: $[PRIMARY_ID_PARAMETER]"
    Write-Log "New Status: $NewStatus"

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    if (-not $PSCmdlet.ShouldProcess($TargetFile, "Update $[PRIMARY_ID_PARAMETER] to $NewStatus")) {
        return
    }

    # Single read-modify-write cycle
    $content = Get-Content $TargetFile -Raw

    # [REPLACE_WITH_TRANSFORMATION_PIPELINE]
    #
    # Chain content-transformer calls. Each takes $content and returns modified $content.
    # Check for $null after each call to detect errors.
    #
    # Example:
    #
    # # Step 1: Update status in place
    # $content = Update-StatusInPlace -Content $content -EntityId $[PRIMARY_ID_PARAMETER] -NewStatus $NewStatus
    # if ($null -eq $content) {
    #     Write-Log "Failed to update status" -Level "ERROR"
    #     exit 1
    # }
    #
    # # Step 2 (conditional): Move to completed section
    # if ($NewStatus -eq "Completed") {
    #     $content = Move-ToCompletedSection -Content $content -EntityId $[PRIMARY_ID_PARAMETER]
    #     if ($null -eq $content) {
    #         Write-Log "Failed to move entry" -Level "ERROR"
    #         exit 1
    #     }
    # }
    #
    # # Step 3: Update frontmatter date
    # $content = Update-FrontmatterDate -Content $content

    # Single write
    Set-Content -Path $TargetFile -Value $content -NoNewline

    Write-Log "Update completed successfully" -Level "SUCCESS"
    Write-Log "Updated file: $TargetFile"
}

# Execute main function
Main

<#
TESTING CHECKLIST:
Before considering this script complete, test the following:

1. MODULE IMPORT TEST:
   - Run the script from its intended directory
   - Verify Common-ScriptHelpers module loads without errors

2. BASIC STATUS UPDATE TEST:
   - Run with a valid entity ID and a simple status change
   - Verify the target file is modified correctly
   - Check that only the intended row/section changed

3. PREREQUISITE VALIDATION TEST:
   - Test with a non-existent target file
   - Test with missing required parameters for specific status transitions
   - Verify error messages are clear and helpful

4. CONTENT-TRANSFORMER TEST:
   - Verify each transformer function works independently
   - Test with edge cases (first row, last row, only row in table)
   - Confirm $null is returned on error conditions

5. WHATIF / SHOULDPROCESS TEST:
   - Run with -WhatIf flag
   - Verify no file changes are made
   - Confirm the WhatIf message describes the intended action

6. COMPLETION / MOVE TEST (if applicable):
   - Test moving rows between sections (active -> completed)
   - Verify source section row is removed
   - Verify target section row is added correctly
   - Check that summary counts are updated if applicable

7. IDEMPOTENCY TEST:
   - Run the same update twice
   - Verify the script handles already-updated entries gracefully

8. CLEANUP TEST:
   - Restore any test files to their original state after verification
   - Ensure no temporary files are left behind

EXAMPLE TEST COMMANDS:
# Basic status update
.\[SCRIPT_NAME].ps1 -[PRIMARY_ID_PARAMETER] "[ID_EXAMPLE]" -NewStatus "[STATUS_EXAMPLE]" -WhatIf

# Actual update
.\[SCRIPT_NAME].ps1 -[PRIMARY_ID_PARAMETER] "[ID_EXAMPLE]" -NewStatus "[STATUS_EXAMPLE]"

# Verify changes
git diff [TARGET_FILE_RELATIVE_PATH]

# Revert test changes
git checkout [TARGET_FILE_RELATIVE_PATH]
#>
