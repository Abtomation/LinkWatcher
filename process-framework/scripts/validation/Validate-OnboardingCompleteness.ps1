#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Validates onboarding completeness after Codebase Feature Discovery (PF-TSK-064).
.DESCRIPTION
    Checks two aspects of onboarding completeness:
    1. Source file coverage — every source file in the project appears in at least one
       feature's Code Inventory (Section 4 → File Inventory table).
    2. Feature state files — every feature in feature-tracking.md has a corresponding
       state file in doc/state-tracking/features/.

    Designed to run after PF-TSK-064 (Codebase Feature Discovery) to verify 100% coverage
    before proceeding to PF-TSK-065 (Codebase Feature Analysis).
.PARAMETER ProjectRoot
    Path to the project root directory. Defaults to auto-detection from script location.
.PARAMETER Detailed
    Show every checked file, not just failures.
.PARAMETER SourceExclusions
    Additional directory names to exclude from source file scanning.
    Built-in exclusions: doc, docs, process-framework, process-framework-local, .git,
    __pycache__, node_modules, .venv, venv, env, LinkWatcher, languages-config, test.
.EXAMPLE
    ./Validate-OnboardingCompleteness.ps1
.EXAMPLE
    ./Validate-OnboardingCompleteness.ps1 -Detailed
.EXAMPLE
    ./Validate-OnboardingCompleteness.ps1 -SourceExclusions "vendor","third_party"
#>

param(
    [string]$ProjectRoot = "",
    [switch]$Detailed,
    [string[]]$SourceExclusions = @()
)

# --- Resolve project root ---
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $dir = $PSScriptRoot
    while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
        $dir = Split-Path -Parent $dir
    }
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
    $ProjectRoot = Get-ProjectRoot
}

# --- Globals ---
$totalChecks = 0
$errorCount = 0
$warningCount = 0
$passCount = 0

function Add-CheckResult {
    param(
        [ValidateSet("PASS", "WARN", "ERROR")]
        [string]$Level,
        [string]$Surface,
        [string]$Message
    )
    $script:totalChecks++
    switch ($Level) {
        "PASS"  { $script:passCount++;  if ($Detailed) { Write-Host "  $([char]0x2705) [$Surface] $Message" } }
        "WARN"  { $script:warningCount++; Write-Host "  $([char]0x26A0) [$Surface] $Message" -ForegroundColor Yellow }
        "ERROR" { $script:errorCount++;   Write-Host "  $([char]0x274C) [$Surface] $Message" -ForegroundColor Red }
    }
}

# --- Load project config ---
$projectConfigPath = Join-Path $ProjectRoot "doc/project-config.json"
if (!(Test-Path $projectConfigPath)) {
    Write-Host "$([char]0x274C) doc/project-config.json not found at $ProjectRoot — cannot validate." -ForegroundColor Red
    exit 1
}
$projCfg = Get-Content $projectConfigPath -Raw | ConvertFrom-Json
$primaryLang = $projCfg.project_metadata.primary_language.ToLower()

# Determine source file extension from language config
$sourceExtension = ".py"  # fallback
$langCfgPath = Join-Path $ProjectRoot "process-framework/languages-config/$primaryLang/$primaryLang-config.json"
if (Test-Path $langCfgPath) {
    $langCfg = Get-Content $langCfgPath -Raw | ConvertFrom-Json
    $ext = $langCfg.testing.testFileExtension
    if ($ext) { $sourceExtension = $ext }
}

# --- Directories to exclude from source scanning ---
$builtInExclusions = @(
    "doc", "docs", "process-framework", "process-framework-local",
    ".git", "__pycache__", "node_modules", ".venv", "venv", "env",
    "LinkWatcher", "languages-config", "test", ".claude"
)
$allExclusions = $builtInExclusions + $SourceExclusions

Write-Host ""
Write-Host "=== Onboarding Completeness Validation ===" -ForegroundColor Cyan
Write-Host "Project: $($projCfg.project.display_name)"
Write-Host "Language: $primaryLang (extension: $sourceExtension)"
Write-Host ""

# ============================================================
# Surface 1: Source File Coverage
# ============================================================
Write-Host "--- Surface 1: Source File Coverage ---" -ForegroundColor Cyan

# 1a. Collect all source files on disk
$allSourceFiles = @()
Get-ChildItem -Path $ProjectRoot -Recurse -File -Filter "*$sourceExtension" | ForEach-Object {
    $relativePath = $_.FullName.Substring($ProjectRoot.Length + 1).Replace("\", "/")

    # Check if file is in an excluded directory
    $excluded = $false
    foreach ($excl in $allExclusions) {
        if ($relativePath -like "$excl/*" -or $relativePath -like "*/$excl/*") {
            $excluded = $true
            break
        }
    }
    if (-not $excluded) {
        $allSourceFiles += $relativePath
    }
}

Write-Host "  Source files on disk: $($allSourceFiles.Count)"

# 1b. Collect all files referenced in feature state files' Code Inventory
$featuresDir = Join-Path $ProjectRoot "doc/state-tracking/features"
$assignedFiles = @{}  # path -> list of feature names

if (Test-Path $featuresDir) {
    $stateFiles = Get-ChildItem -Path $featuresDir -Filter "*-implementation-state.md"

    foreach ($stateFile in $stateFiles) {
        $content = Get-Content $stateFile.FullName -Raw
        $featureName = $stateFile.BaseName -replace '-implementation-state$', ''

        # Parse File Inventory table: look for lines starting with | that contain file paths
        # The table is under "### File Inventory" or "## 4. Code Inventory"
        $lines = $content -split "`n"
        $inInventory = $false

        foreach ($line in $lines) {
            # Detect start of File Inventory section
            if ($line -match '^\s*###?\s*(File Inventory|Code Inventory)') {
                $inInventory = $true
                continue
            }

            # Detect end of section (next heading)
            if ($inInventory -and $line -match '^\s*##') {
                if ($line -notmatch '^\s*###?\s*(File Inventory|Test Files|Database)') {
                    $inInventory = $false
                    continue
                }
            }

            # Parse table rows
            if ($inInventory -and $line -match '^\s*\|') {
                # Skip header and separator rows
                if ($line -match '^\s*\|\s*-' -or $line -match '^\s*\|\s*File Path\s*\|') {
                    continue
                }

                # Extract first cell (file path)
                $cells = $line -split '\|' | Where-Object { $_.Trim() -ne '' }
                if ($cells.Count -ge 1) {
                    $filePath = $cells[0].Trim()
                    # Normalize: remove leading slashes or ./ prefixes
                    $filePath = $filePath -replace '^\./', '' -replace '^/', ''

                    if ($filePath -match [regex]::Escape($sourceExtension) + '$') {
                        if (-not $assignedFiles.ContainsKey($filePath)) {
                            $assignedFiles[$filePath] = @()
                        }
                        $assignedFiles[$filePath] += $featureName
                    }
                }
            }
        }
    }
}

Write-Host "  Files assigned to features: $($assignedFiles.Count)"

# 1c. Compare: find unassigned files
$unassignedFiles = @()
foreach ($file in $allSourceFiles) {
    if ($assignedFiles.ContainsKey($file)) {
        Add-CheckResult -Level "PASS" -Surface "Coverage" -Message "$file → assigned"
    } else {
        $unassignedFiles += $file
        Add-CheckResult -Level "ERROR" -Surface "Coverage" -Message "$file — NOT assigned to any feature"
    }
}

$coveragePercent = if ($allSourceFiles.Count -gt 0) {
    [math]::Round(($allSourceFiles.Count - $unassignedFiles.Count) / $allSourceFiles.Count * 100, 1)
} else { 100.0 }

Write-Host ""
Write-Host "  Coverage: $coveragePercent% ($($allSourceFiles.Count - $unassignedFiles.Count)/$($allSourceFiles.Count) files assigned)"
if ($unassignedFiles.Count -gt 0) {
    Write-Host "  Unassigned files: $($unassignedFiles.Count)" -ForegroundColor Red
}

# ============================================================
# Surface 2: Feature State File Existence
# ============================================================
Write-Host ""
Write-Host "--- Surface 2: Feature State File Existence ---" -ForegroundColor Cyan

$featureTrackingPath = Join-Path $ProjectRoot "doc/state-tracking/permanent/feature-tracking.md"
if (!(Test-Path $featureTrackingPath)) {
    Add-CheckResult -Level "ERROR" -Surface "StateFiles" -Message "feature-tracking.md not found"
} else {
    $ftContent = Get-Content $featureTrackingPath -Raw
    $ftLines = $ftContent -split "`n"

    # Parse feature tracking table to extract feature IDs and names
    $features = @()
    $inTable = $false
    foreach ($line in $ftLines) {
        if ($line -match '^\s*\|\s*\*\*[\d.]+\*\*') {
            $inTable = $true
        } elseif ($line -match '^\s*\|\s*[\d.]+') {
            $inTable = $true
        }

        if ($inTable -and $line -match '^\s*\|') {
            # Skip separator rows
            if ($line -match '^\s*\|\s*-') { continue }

            $cells = $line -split '\|' | Where-Object { $_.Trim() -ne '' }
            if ($cells.Count -ge 2) {
                $featureId = $cells[0].Trim() -replace '\*\*', ''
                # Skip header rows
                if ($featureId -match '^(ID|Feature|---)') { continue }
                if ($featureId -match '^\d+\.\d+') {
                    $featureName = $cells[1].Trim()
                    # Check if the State File column has a link
                    $hasStateFileLink = $false
                    foreach ($cell in $cells) {
                        if ($cell -match '\[.*State.*\]\(') {
                            $hasStateFileLink = $true
                            # Extract the path from the link
                            if ($cell -match '\[.*\]\(([^)]+)\)') {
                                $stateFilePath = $matches[1].Trim()
                                # Resolve relative to feature-tracking.md location
                                $ftDir = Split-Path $featureTrackingPath -Parent
                                $resolvedPath = Join-Path $ftDir $stateFilePath
                                $resolvedPath = [System.IO.Path]::GetFullPath($resolvedPath)

                                if (Test-Path $resolvedPath) {
                                    Add-CheckResult -Level "PASS" -Surface "StateFiles" -Message "Feature $featureId ($featureName) — state file exists"
                                } else {
                                    Add-CheckResult -Level "ERROR" -Surface "StateFiles" -Message "Feature $featureId ($featureName) — state file link broken: $stateFilePath"
                                }
                            }
                            break
                        }
                    }
                    if (-not $hasStateFileLink) {
                        Add-CheckResult -Level "ERROR" -Surface "StateFiles" -Message "Feature $featureId ($featureName) — no state file link in feature-tracking.md"
                    }
                }
            }
        }
    }
}

# ============================================================
# Summary
# ============================================================
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Total checks: $totalChecks"
Write-Host "  Passed: $passCount" -ForegroundColor Green
if ($warningCount -gt 0) { Write-Host "  Warnings: $warningCount" -ForegroundColor Yellow }
if ($errorCount -gt 0) { Write-Host "  Errors: $errorCount" -ForegroundColor Red }

$overallStatus = if ($errorCount -eq 0) { "PASS" } else { "FAIL" }
$statusColor = if ($errorCount -eq 0) { "Green" } else { "Red" }
Write-Host ""
Write-Host "  Overall: $overallStatus (Coverage: $coveragePercent%)" -ForegroundColor $statusColor

exit $(if ($errorCount -eq 0) { 0 } else { 1 })
