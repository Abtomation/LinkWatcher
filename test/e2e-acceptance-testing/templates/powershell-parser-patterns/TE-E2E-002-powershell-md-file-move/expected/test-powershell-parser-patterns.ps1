# =============================================================================
# MANUAL TEST: PowerShell Parser Path Detection
# =============================================================================
#
# PURPOSE:
#   Verify that LinkWatcher's PowerShell parser detects and updates file paths
#   in all PowerShell-specific patterns when referenced files are moved/renamed.
#
# IMPORTANT:
#   These files are in manual-tests/ (not tests/) because the default config
#   ignores the tests/ directory to prevent self-corruption. Files under tests/
#   are never scanned during initial scan, so references would not be tracked.
#
# PREREQUISITES:
#   - LinkWatcher must be running in background
#   - All three files in this directory must exist:
#     1. test-powershell-parser-patterns.ps1  (this file)
#     2. moved/move-target.md                       (target for move test 1)
#     3. move-target-2.ps1                    (target for move test 2)
#
# HOW TO TEST:
#
#   TEST 1 — Move a markdown file referenced in comments
#   -------------------------------------------------------
#   1. Ensure LinkWatcher is running
#   2. Move (or rename) "moved/move-target.md" to "move-target-renamed.md"
#      (in the same directory, or move to a different directory)
#   3. Wait 10-15 seconds for LinkWatcher to process (move detection uses
#      a 10-second delay to correlate delete+create events)
#   4. Open this file and verify ALL paths below that referenced
#      "moved/move-target.md" have been updated to the new location
#
#   EXPECTED RESULT for Test 1:
#   - Every occurrence of "moved/move-target.md" in this file should be updated
#     to "move-target-renamed.md" (or the new relative path if moved elsewhere)
#   - This includes paths in: line comments, block comments, string literals,
#     Join-Path arguments, and unquoted references
#
#   TEST 2 — Move a script file referenced via Import-Module
#   -------------------------------------------------------
#   1. Move (or rename) "move-target-2.ps1" to "move-target-2-renamed.ps1"
#   2. Wait 10-15 seconds for LinkWatcher to process
#   3. Open this file and verify ALL paths referencing "move-target-2.ps1"
#      have been updated
#
#   EXPECTED RESULT for Test 2:
#   - Every occurrence of "move-target-2.ps1" should be updated
#   - Import-Module paths and Join-Path references should all reflect the new name
#
#   CLEANUP:
#   - After testing, move/rename the files back to their original names
#   - Verify LinkWatcher updates all paths back to the originals
#
# =============================================================================

<#
.SYNOPSIS
    Test script for PowerShell parser path detection patterns.

.DESCRIPTION
    This script contains every type of file path reference pattern found in
    PowerShell scripts. It references two test target files:
    - moved/move-target.md (a markdown file)
    - move-target-2.ps1 (a PowerShell script)

    All patterns below should be detected by the PowerShell parser and
    updated when the target files are moved or renamed.

.EXAMPLE
    .\test-powershell-parser-patterns.ps1
    Runs all pattern demonstrations (does not modify any files).

.EXAMPLE
    moved/move-target.md
    This path in a .EXAMPLE section should be detected and updated.

.NOTES
    Test target locations:
    - Markdown target: moved/move-target.md
    - Script target: move-target-2.ps1

    Script Metadata:
    - Purpose: Manual testing of PowerShell parser enhancement
    - Related: Feature 2.1.1 (Link Parsing System), PF-STA-052
    - Output Directory: .
#>

# =============================================================================
# PATTERN 1: Line comments with file paths (# comment)
# =============================================================================

# Reference to the markdown target: moved/move-target.md
# Reference to the script target: move-target-2.ps1
# See also: moved/move-target.md for details
# The configuration is documented in moved/move-target.md

# =============================================================================
# PATTERN 2: Quoted string literals (double-quoted)
# =============================================================================

$markdownTarget = "moved/move-target.md"
$scriptTarget = "move-target-2.ps1"
Write-Host "Reading from: moved/move-target.md"

# =============================================================================
# PATTERN 3: Quoted string literals (single-quoted)
# =============================================================================

$markdownTargetSingle = 'moved/move-target.md'
$scriptTargetSingle = 'move-target-2.ps1'

# =============================================================================
# PATTERN 4: Join-Path operations
# =============================================================================

$targetPath1 = Join-Path -Path $PSScriptRoot -ChildPath "moved/move-target.md"
$targetPath2 = Join-Path $PSScriptRoot "move-target-2.ps1"
$targetPath3 = Join-Path -Path "." -ChildPath "moved/move-target.md"

# =============================================================================
# PATTERN 5: Import-Module statements
# =============================================================================

# Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "move-target-2.ps1") -Force
# Import-Module "move-target-2.ps1" -Force

# =============================================================================
# PATTERN 6: Test-Path and file operations
# =============================================================================

if (Test-Path "moved/move-target.md") {
    Write-Host "Markdown target exists"
}

$content = Get-Content -Path "moved/move-target.md" -Raw

# =============================================================================
# PATTERN 7: -Path and -LiteralPath parameters
# =============================================================================

Copy-Item -Path "moved/move-target.md" -Destination "backup.md"
Remove-Item -LiteralPath "moved/move-target.md" -WhatIf

# =============================================================================
# PATTERN 8: Here-string with paths
# =============================================================================

$helpText = @"
Available test files:
  - moved/move-target.md
  - move-target-2.ps1
"@

# =============================================================================
# PATTERN 9: Array of paths
# =============================================================================

$testFiles = @(
    "moved/move-target.md",
    "move-target-2.ps1"
)

# =============================================================================
# PATTERN 10: Write-Host / Write-Output with embedded paths
# =============================================================================

Write-Host "Processing file: moved/move-target.md" -ForegroundColor Green
Write-Output "Script location: move-target-2.ps1"
Write-Warning "Check moved/move-target.md for configuration"

# =============================================================================
# VERIFICATION CHECKLIST
# =============================================================================
# After moving moved/move-target.md, count occurrences of the NEW path in this file.
# Expected updated references for moved/move-target.md: 20 occurrences
# Expected updated references for move-target-2.ps1: 11 occurrences
#
# To count (PowerShell):
#   (Get-Content "test-powershell-parser-patterns.ps1" | Select-String "moved/move-target.md").Count
#   (Get-Content "test-powershell-parser-patterns.ps1" | Select-String "move-target-2.ps1").Count
# =============================================================================
