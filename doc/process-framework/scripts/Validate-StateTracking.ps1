#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Master state validation script — validates that state tracking entries match actual files on disk.
.DESCRIPTION
    Checks consistency across 5 validation surfaces:
    1. feature-tracking.md — all document links (FDD, TDD, ADR, Test Spec, Assessment, State File)
    2. Feature implementation state files — Section 4 (doc inventory), Section 5 (code inventory), Section 6 (dependencies)
    3. test-implementation-tracking.md — test file path references
    4. Cross-reference consistency — feature IDs in test-registry.yaml vs feature-tracking.md
    5. ID counter health — nextAvailable counters vs actual max IDs

    Created as IMP-028 from Tools Review 2026-02-21.
.PARAMETER ProjectRoot
    Path to the project root directory. Defaults to auto-detection from script location.
.PARAMETER Surface
    Which validation surfaces to run. Accepts one or more of:
    "FeatureTracking", "StateFiles", "TestTracking", "CrossRef", "IdCounters", "All"
    Default: "All"
.PARAMETER Detailed
    Show every checked link, not just failures.
.PARAMETER FixCounters
    Auto-fix nextAvailable counters in id-registry.json (Surface 5 only).
.EXAMPLE
    .\Validate-StateTracking.ps1
.EXAMPLE
    .\Validate-StateTracking.ps1 -Surface FeatureTracking,StateFiles
.EXAMPLE
    .\Validate-StateTracking.ps1 -Detailed
.EXAMPLE
    .\Validate-StateTracking.ps1 -Surface IdCounters -FixCounters
#>

param(
    [string]$ProjectRoot = "",
    [string[]]$Surface = @("All"),
    [switch]$Detailed,
    [switch]$FixCounters
)

# --- Resolve project root ---
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Common-ScriptHelpers.psm1") -Force
    $ProjectRoot = Get-ProjectRoot
}

# --- Globals ---
$totalChecks = 0
$errorCount = 0
$warningCount = 0
$passCount = 0

$runAll = $Surface -contains "All"

# --- Helper: Resolve a markdown-relative path to an absolute path ---
function Resolve-MarkdownLink {
    param(
        [string]$LinkPath,
        [string]$SourceFileDir
    )

    # Skip anchors-only links, external URLs, and empty
    if ([string]::IsNullOrWhiteSpace($LinkPath)) { return $null }
    if ($LinkPath -match '^https?://') { return $null }
    if ($LinkPath -match '^#') { return $null }
    if ($LinkPath -match '^mailto:') { return $null }

    # Skip obviously non-file links (no slash/backslash and no file extension)
    if ($LinkPath -notmatch '[/\\]' -and $LinkPath -notmatch '\.\w{1,5}$') { return $null }

    # Strip anchor fragment
    $cleanPath = ($LinkPath -split '#')[0]
    if ([string]::IsNullOrWhiteSpace($cleanPath)) { return $null }

    # Resolve relative to source file directory
    $combined = Join-Path $SourceFileDir $cleanPath
    try {
        $resolved = [System.IO.Path]::GetFullPath($combined)
        return $resolved
    } catch {
        return $null
    }
}

# --- Helper: Extract all markdown links from a line ---
function Get-MarkdownLinks {
    param([string]$Line)

    $links = @()
    $regex = [regex]'\[([^\]]*)\]\(([^)]+)\)'
    $matchCollection = $regex.Matches($Line)
    foreach ($m in $matchCollection) {
        $links += [PSCustomObject]@{
            Text = $m.Groups[1].Value
            Path = $m.Groups[2].Value
        }
    }
    return $links
}

# --- Helper: Find similar filenames for suggestions ---
function Find-SimilarFile {
    param(
        [string]$ExpectedPath
    )

    $dir = [System.IO.Path]::GetDirectoryName($ExpectedPath)
    $name = [System.IO.Path]::GetFileName($ExpectedPath)
    if (-not (Test-Path $dir)) { return $null }

    # Look for files with similar names in the same directory
    $candidates = Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -ne $name
    }

    # Simple similarity: share a common prefix of 5+ chars
    $prefix = if ($name.Length -ge 5) { $name.Substring(0, 5) } else { $name }
    $match = $candidates | Where-Object { $_.Name.StartsWith($prefix) } | Select-Object -First 1
    if ($match -and $match.Name) {
        return $match.Name
    }
    return ""
}

# --- Helper: Record check result ---
function Add-CheckResult {
    param(
        [string]$Level,  # "ERROR", "WARNING", "OK"
        [string]$Surface,
        [string]$Context,
        [string]$Message
    )

    $script:totalChecks++
    switch ($Level) {
        "ERROR"   { $script:errorCount++; Write-Host "    $([char]0x274C) $Context : $Message" -ForegroundColor Red }
        "WARNING" { $script:warningCount++; Write-Host "    $([char]0x26A0)  $Context : $Message" -ForegroundColor Yellow }
        "OK"      { $script:passCount++; if ($Detailed) { Write-Host "    $([char]0x2705) $Context : $Message" -ForegroundColor Green } }
    }
}

# =========================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  State Tracking Validation Report" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Project Root: $ProjectRoot" -ForegroundColor Gray
Write-Host ""

# =========================================================================
# SURFACE 1: Feature Tracking
# =========================================================================
if ($runAll -or $Surface -contains "FeatureTracking") {
    Write-Host "[1/5] Feature Tracking (feature-tracking.md)" -ForegroundColor Cyan

    $ftPath = Join-Path $ProjectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md"
    if (-not (Test-Path $ftPath)) {
        Add-CheckResult "ERROR" "FeatureTracking" "feature-tracking.md" "File not found: $ftPath"
    } else {
        $ftDir = [System.IO.Path]::GetDirectoryName($ftPath)
        $ftLines = Get-Content $ftPath -Encoding UTF8
        $featureCount = 0
        $linkCount = 0

        foreach ($line in $ftLines) {
            # Match feature table rows: start with | [X.X.X]( or | [text](
            # Feature rows have the pattern: | [0.1.1](path) | Name | Status | ...
            if ($line -match '^\|\s*\[(\d+\.\d+\.\d+)\]\(') {
                $featureId = $matches[1]
                $featureCount++

                # Extract all markdown links from this row
                $links = Get-MarkdownLinks -Line $line
                $validLinks = 0
                $brokenLinks = 0

                foreach ($link in $links) {
                    $resolved = Resolve-MarkdownLink -LinkPath $link.Path -SourceFileDir $ftDir
                    if ($null -eq $resolved) { continue }

                    $linkCount++
                    if (Test-Path $resolved) {
                        $validLinks++
                        Add-CheckResult "OK" "FeatureTracking" "$featureId/$($link.Text)" "Link valid"
                    } else {
                        $brokenLinks++
                        $suggestion = Find-SimilarFile -ExpectedPath $resolved
                        $msg = "Link broken: $($link.Path)"
                        if ($suggestion -and $suggestion.Length -gt 0) {
                            $msg += " (did you mean: " + $suggestion + "?)"
                        }
                        Add-CheckResult "ERROR" "FeatureTracking" "$featureId/$($link.Text)" $msg
                    }
                }

                # In non-detailed mode, show per-feature summary for clean features
                if (-not $Detailed -and $brokenLinks -eq 0 -and $validLinks -gt 0) {
                    Write-Host "    $([char]0x2705) Feature $featureId : $validLinks/$validLinks links valid" -ForegroundColor Green
                }
            }
        }

        Write-Host "  Checked $featureCount features, $linkCount links total" -ForegroundColor Gray
    }
    Write-Host ""
}

# =========================================================================
# SURFACE 2: Feature State Files
# =========================================================================
if ($runAll -or $Surface -contains "StateFiles") {
    Write-Host "[2/5] Feature State Files" -ForegroundColor Cyan

    $stateDir = Join-Path $ProjectRoot "doc/process-framework/state-tracking/features"
    if (-not (Test-Path $stateDir)) {
        Add-CheckResult "ERROR" "StateFiles" "features/" "Directory not found: $stateDir"
    } else {
        $stateFiles = Get-ChildItem -Path $stateDir -Filter "*-implementation-state.md" -File
        Write-Host "  Found $($stateFiles.Count) state files" -ForegroundColor Gray

        foreach ($sf in $stateFiles) {
            $sfDir = $sf.DirectoryName
            $sfContent = Get-Content $sf.FullName -Encoding UTF8
            $sfName = $sf.Name
            $brokenInFile = 0
            $validInFile = 0
            $inSection = ""

            foreach ($line in $sfContent) {
                # Track which section we're in
                if ($line -match '^## 4\. Documentation Inventory') { $inSection = "Section4" }
                elseif ($line -match '^## 5\. Code Inventory') { $inSection = "Section5" }
                elseif ($line -match '^## 6\. Dependencies') { $inSection = "Section6" }
                elseif ($line -match '^## [789]') { $inSection = "" }
                elseif ($line -match '^## 1[0-2]') { $inSection = "" }

                # Only validate links in sections 4, 5, 6
                if ($inSection -notin @("Section4", "Section5", "Section6")) { continue }

                # Skip non-table rows
                if ($line -notmatch '^\|') { continue }
                # Skip header separator rows
                if ($line -match '^\|\s*-') { continue }

                $links = Get-MarkdownLinks -Line $line
                foreach ($link in $links) {
                    $resolved = Resolve-MarkdownLink -LinkPath $link.Path -SourceFileDir $sfDir
                    if ($null -eq $resolved) { continue }

                    if (Test-Path $resolved) {
                        $validInFile++
                        Add-CheckResult "OK" "StateFiles" "$sfName/$inSection/$($link.Text)" "Link valid"
                    } else {
                        $brokenInFile++
                        $suggestion = Find-SimilarFile -ExpectedPath $resolved
                        $msg = "Link broken: $($link.Path)"
                        if ($suggestion -and $suggestion.Length -gt 0) {
                            $msg += " (did you mean: " + $suggestion + "?)"
                        }
                        Add-CheckResult "ERROR" "StateFiles" "$sfName/$inSection/$($link.Text)" $msg
                    }
                }
            }

            $total = $validInFile + $brokenInFile
            if ($total -gt 0 -and $brokenInFile -eq 0 -and -not $Detailed) {
                Write-Host "    $([char]0x2705) $sfName : $validInFile/$total links valid" -ForegroundColor Green
            } elseif ($total -eq 0) {
                Write-Host "    $([char]0x26A0)  $sfName : No links found in sections 4-6" -ForegroundColor Yellow
                $script:warningCount++
                $script:totalChecks++
            }
        }
    }
    Write-Host ""
}

# =========================================================================
# SURFACE 3: Test Implementation Tracking
# =========================================================================
if ($runAll -or $Surface -contains "TestTracking") {
    Write-Host "[3/5] Test Implementation Tracking" -ForegroundColor Cyan

    $titPath = Join-Path $ProjectRoot "doc/process-framework/state-tracking/permanent/test-implementation-tracking.md"
    if (-not (Test-Path $titPath)) {
        Add-CheckResult "ERROR" "TestTracking" "test-implementation-tracking.md" "File not found: $titPath"
    } else {
        $titDir = [System.IO.Path]::GetDirectoryName($titPath)
        $titLines = Get-Content $titPath -Encoding UTF8
        $testFileCount = 0
        $brokenTestFiles = 0

        foreach ($line in $titLines) {
            # Match table rows with test file IDs: | PD-TST-### | ...
            if ($line -match '^\|\s*PD-TST-\d+\s*\|') {
                $links = Get-MarkdownLinks -Line $line

                # The test file link is typically the 1st link in the row
                foreach ($link in $links) {
                    # Only check links that look like test file paths (not task links)
                    if ($link.Path -match '\.\./.*tests/' -or $link.Path -match '\.py$') {
                        $testFileCount++
                        $resolved = Resolve-MarkdownLink -LinkPath $link.Path -SourceFileDir $titDir
                        if ($null -eq $resolved) { continue }

                        if (Test-Path $resolved) {
                            Add-CheckResult "OK" "TestTracking" "$($link.Text)" "File exists"
                        } else {
                            $brokenTestFiles++
                            Add-CheckResult "ERROR" "TestTracking" "$($link.Text)" "File not found: $($link.Path)"
                        }
                    }
                }
            }
        }

        if (-not $Detailed -and $brokenTestFiles -eq 0 -and $testFileCount -gt 0) {
            Write-Host "    $([char]0x2705) $testFileCount/$testFileCount test file references valid" -ForegroundColor Green
        }
        Write-Host "  Checked $testFileCount test file references" -ForegroundColor Gray
    }
    Write-Host ""
}

# =========================================================================
# SURFACE 4: Cross-Reference Consistency
# =========================================================================
if ($runAll -or $Surface -contains "CrossRef") {
    Write-Host "[4/5] Cross-Reference Consistency" -ForegroundColor Cyan

    # Load known feature IDs from feature-tracking.md
    $ftPath = Join-Path $ProjectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md"
    $knownFeatureIds = @()
    if (Test-Path $ftPath) {
        $ftContent = Get-Content $ftPath -Encoding UTF8
        foreach ($line in $ftContent) {
            if ($line -match '^\|\s*\[(\d+\.\d+\.\d+)\]') {
                $knownFeatureIds += $matches[1]
            }
        }
    }

    if ($knownFeatureIds.Count -eq 0) {
        Add-CheckResult "WARNING" "CrossRef" "feature-tracking.md" "No feature IDs found — cannot cross-reference"
    } else {
        Write-Host "  Known features: $($knownFeatureIds -join ', ')" -ForegroundColor Gray

        # Check test-registry.yaml feature IDs
        $registryPath = Join-Path $ProjectRoot "test/test-registry.yaml"
        if (Test-Path $registryPath) {
            $registryLines = Get-Content $registryPath -Encoding UTF8
            $registryFeatureIds = @()
            $crossCuttingIds = @()

            foreach ($line in $registryLines) {
                $trimmed = $line.Trim()
                if ($trimmed -match 'featureId:\s*"([^"]+)"') {
                    $fid = $matches[1]
                    if ($fid -notin $registryFeatureIds) {
                        $registryFeatureIds += $fid
                    }
                }
                if ($trimmed -match 'crossCuttingFeatures:') {
                    $ccMatches = [regex]::Matches($trimmed, '[\d]+\.[\d]+\.[\d]+')
                    foreach ($ccm in $ccMatches) {
                        if ($ccm.Value -notin $crossCuttingIds) {
                            $crossCuttingIds += $ccm.Value
                        }
                    }
                }
            }

            # Check primary feature IDs
            $invalidPrimary = @()
            foreach ($fid in $registryFeatureIds) {
                if ($fid -notin $knownFeatureIds) {
                    $invalidPrimary += $fid
                    Add-CheckResult "WARNING" "CrossRef" "test-registry.yaml" "Feature ID '$fid' not in feature-tracking.md"
                }
            }
            if ($invalidPrimary.Count -eq 0) {
                Add-CheckResult "OK" "CrossRef" "Primary feature IDs" "All $($registryFeatureIds.Count) feature IDs match"
            }

            # Check cross-cutting feature IDs
            $invalidCC = @()
            foreach ($ccId in $crossCuttingIds) {
                if ($ccId -notin $knownFeatureIds) {
                    $invalidCC += $ccId
                    Add-CheckResult "WARNING" "CrossRef" "test-registry.yaml" "Cross-cutting feature ID '$ccId' not in feature-tracking.md"
                }
            }
            if ($invalidCC.Count -eq 0 -and $crossCuttingIds.Count -gt 0) {
                Add-CheckResult "OK" "CrossRef" "Cross-cutting IDs" "All $($crossCuttingIds.Count) cross-cutting feature IDs match"
            }
        } else {
            Add-CheckResult "WARNING" "CrossRef" "test-registry.yaml" "File not found — skipping cross-reference checks"
        }
    }
    Write-Host ""
}

# =========================================================================
# SURFACE 5: ID Counter Health
# =========================================================================
if ($runAll -or $Surface -contains "IdCounters") {
    Write-Host "[5/5] ID Counter Health" -ForegroundColor Cyan

    $idRegistryPath = Join-Path $ProjectRoot "../../id-registry.json"
    if (-not (Test-Path $idRegistryPath)) {
        Add-CheckResult "ERROR" "IdCounters" "id-registry.json" "File not found: $idRegistryPath"
    } else {
        $idRegistry = Get-Content $idRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json

        # Prefixes to validate with their file patterns
        $prefixChecks = @(
            @{ Prefix = "PF-FEA";  Dir = "doc/process-framework/state-tracking/features";                         Pattern = "*.md" }
            @{ Prefix = "PD-FDD";  Dir = "doc/product-docs/functional-design/fdds";                                Pattern = "*.md" }
            @{ Prefix = "PD-TDD";  Dir = "doc/product-docs/technical/architecture/design-docs/tdd";                Pattern = "*.md" }
            @{ Prefix = "PD-ADR";  Dir = "doc/product-docs/technical/architecture/design-docs/adr/adr";            Pattern = "*.md" }
            @{ Prefix = "ART-ASS"; Dir = "doc/process-framework/methodologies/documentation-tiers/assessments";    Pattern = "*.md" }
            @{ Prefix = "PF-TSP";  Dir = "test/specifications/feature-specs";                                       Pattern = "*.md" }
        )

        $countersFixed = 0
        foreach ($check in $prefixChecks) {
            $prefix = $check.Prefix
            $dirPath = Join-Path $ProjectRoot $check.Dir

            # Get nextAvailable from registry
            $prefixKey = $prefix
            $registryEntry = $idRegistry.prefixes.$prefixKey
            if (-not $registryEntry) {
                Add-CheckResult "WARNING" "IdCounters" $prefix "Prefix not found in id-registry.json"
                continue
            }
            $nextAvailable = $registryEntry.nextAvailable

            # Scan files for max ID
            $maxId = 0
            if (Test-Path $dirPath) {
                $files = Get-ChildItem -Path $dirPath -Filter $check.Pattern -File -ErrorAction SilentlyContinue
                foreach ($file in $files) {
                    $content = Get-Content $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                    if ($content -and $content -match "id:\s*$([regex]::Escape($prefix))-(\d+)") {
                        $num = [int]$matches[1]
                        if ($num -gt $maxId) { $maxId = $num }
                    }
                }
            }

            $expectedNext = if ($maxId -gt 0) { $maxId + 1 } else { $nextAvailable }

            if ($maxId -eq 0) {
                Add-CheckResult "OK" "IdCounters" $prefix "nextAvailable=$nextAvailable (no files found with IDs to validate)"
            } elseif ($nextAvailable -eq $expectedNext) {
                Add-CheckResult "OK" "IdCounters" $prefix "nextAvailable=$nextAvailable, maxUsed=$prefix-$maxId"
            } elseif ($nextAvailable -lt $expectedNext) {
                Add-CheckResult "ERROR" "IdCounters" $prefix "nextAvailable=$nextAvailable but max ID is $prefix-$maxId (would cause collision! expected: $expectedNext)"
                if ($FixCounters) {
                    $idRegistry.prefixes.$prefixKey.nextAvailable = $expectedNext
                    $countersFixed++
                    Write-Host "      Fixed: nextAvailable set to $expectedNext" -ForegroundColor Magenta
                }
            } else {
                # nextAvailable > expectedNext — gap exists, just a warning
                Add-CheckResult "WARNING" "IdCounters" $prefix "nextAvailable=$nextAvailable but max ID is $prefix-$maxId (gap of $($nextAvailable - $expectedNext))"
            }
        }

        if ($FixCounters -and $countersFixed -gt 0) {
            $idRegistry | ConvertTo-Json -Depth 10 | Set-Content $idRegistryPath -Encoding UTF8
            Write-Host "  Fixed $countersFixed counter(s) in id-registry.json" -ForegroundColor Magenta
        }
    }
    Write-Host ""
}

# =========================================================================
# Summary
# =========================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Total checks: $totalChecks" -ForegroundColor Gray
Write-Host "  Passed:       $passCount" -ForegroundColor $(if ($passCount -gt 0) { "Green" } else { "Gray" })
Write-Host "  Errors:       $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Red" })
Write-Host "  Warnings:     $warningCount" -ForegroundColor $(if ($warningCount -eq 0) { "Green" } else { "Yellow" })

if ($errorCount -eq 0 -and $warningCount -eq 0) {
    Write-Host ""
    Write-Host "  All checks passed!" -ForegroundColor Green
    exit 0
} elseif ($errorCount -eq 0) {
    Write-Host ""
    Write-Host "  Passed with warnings." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host ""
    Write-Host "  Validation failed." -ForegroundColor Red
    exit 1
}
