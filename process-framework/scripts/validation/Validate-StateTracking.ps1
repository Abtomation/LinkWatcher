#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Master state validation script — validates that state tracking entries match actual files on disk.
.DESCRIPTION
    Checks consistency across 15 validation surfaces:
    1. ../feature-tracking.md — all document links (FDD, TDD, Test Spec, Assessment, State File)
    2. Feature implementation state files — Section 4 (doc inventory), Section 5 (code inventory), Section 6 (dependencies)
    3. ../test-tracking.md — test file path references
    4. Cross-reference consistency — feature IDs in test-registry.yaml vs feature-tracking.md
    5. ID counter health — nextAvailable counters vs actual max IDs
    6. Feature Dependencies — regenerate feature-dependencies.md if stale
    7. Dimension Consistency — dimension profile presence and valid abbreviations
    8. Workflow Tracking — workflow-feature mapping consistency and status accuracy
    9. Task Registry — all PF-TSK IDs present in process-framework-task-registry.md
    10. Metadata Schema — YAML frontmatter conformance against domain-config.json schemas
    11. Context Map Orphans — cross-reference context map related_task metadata against actual task files
    12. AI Tasks Consistency — detect task files in tasks/ directories but missing from ai-tasks.md
    13. Master State Consistency — phase checkboxes, progress counters, and doc summary vs Feature Inventory
    14. Source Layout — compare source-code-layout.md directory tree against actual source directories
    15. Test Status Aggregation — cross-check feature-tracking Test Status against aggregated test-tracking statuses (PF-IMP-573)

    Created as IMP-028 from Tools Review 2026-02-21.
.PARAMETER ProjectRoot
    Path to the project root directory. Defaults to auto-detection from script location.
.PARAMETER Surface
    Which validation surfaces to run. Accepts one or more of:
    "FeatureTracking", "StateFiles", "TestTracking", "CrossRef", "IdCounters", "FeatureDeps", "DimensionConsistency", "WorkflowTracking", "TaskRegistry", "MetadataSchema", "ContextMapOrphans", "AiTasksConsistency", "MasterStateConsistency", "SourceLayout", "TestStatusAggregation", "All"
    Default: "All"
.PARAMETER Detailed
    Show every checked link, not just failures.
.PARAMETER FixCounters
    Auto-fix nextAvailable counters in ID registries (Surface 5 only).
.EXAMPLE
    ../Validate-StateTracking.ps1
.EXAMPLE
    ../Validate-StateTracking.ps1 -Surface FeatureTracking,StateFiles
.EXAMPLE
    ../Validate-StateTracking.ps1 -Detailed
.EXAMPLE
    ../Validate-StateTracking.ps1 -Surface IdCounters -FixCounters
#>

param(
    [string]$ProjectRoot = "",
    [string[]]$Surface = @("All"),
    [switch]$Detailed,
    [switch]$FixCounters
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

$runAll = $Surface -contains "All"

# --- Load language config for test file extension ---
$projectConfigPath = Join-Path $ProjectRoot "doc/project-config.json"
$testFileExtRegex = '\.py$'  # fallback
if (Test-Path $projectConfigPath) {
    try {
        $projCfg = Get-Content $projectConfigPath -Raw | ConvertFrom-Json
        $lang = $projCfg.project_metadata.primary_language.ToLower()
        $langCfgPath = Join-Path $ProjectRoot "process-framework/languages-config/$lang/$lang-config.json"
        if (Test-Path $langCfgPath) {
            $langCfg = Get-Content $langCfgPath -Raw | ConvertFrom-Json
            $ext = $langCfg.testing.testFileExtension
            if ($ext) {
                $testFileExtRegex = [regex]::Escape($ext) + '$'
            }
        }
    } catch {
        Write-Warning "Could not load language config, using .py fallback for test file matching"
    }
}

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

    $ftPath = Join-Path $ProjectRoot "doc/state-tracking/permanent/feature-tracking.md"
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

    $stateDir = Join-Path $ProjectRoot "doc/state-tracking/features"
    if (-not (Test-Path $stateDir)) {
        Add-CheckResult "ERROR" "StateFiles" "features" "Directory not found: $stateDir"
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
# SURFACE 3: Test Tracking
# =========================================================================
if ($runAll -or $Surface -contains "TestTracking") {
    Write-Host "[3/5] Test Tracking" -ForegroundColor Cyan

    $titPath = Join-Path $ProjectRoot "test/state-tracking/permanent/test-tracking.md"
    if (-not (Test-Path $titPath)) {
        Add-CheckResult "ERROR" "TestTracking" "test-tracking.md" "File not found: $titPath"
    } else {
        $titDir = [System.IO.Path]::GetDirectoryName($titPath)
        $titLines = Get-Content $titPath -Encoding UTF8
        $testFileCount = 0
        $brokenTestFiles = 0

        foreach ($line in $titLines) {
            # Match table rows with test file IDs: | PD-TST-### | ... or | TE-TST-### | ...
            if ($line -match '^\|\s*(?:PD|TE)-TST-\d+\s*\|') {
                $links = Get-MarkdownLinks -Line $line

                # The test file link is typically the 1st link in the row
                foreach ($link in $links) {
                    # Only check links that look like test file paths (not task links)
                    if ($link.Path -match '\.\./.*tests/' -or $link.Path -match $testFileExtRegex) {
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
    $ftPath = Join-Path $ProjectRoot "doc/state-tracking/permanent/feature-tracking.md"
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
                    Add-CheckResult "WARNING" "CrossRef" "test-registry.yaml" "Feature ID '$fid'../ not in feature-tracking.md"
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
                    Add-CheckResult "WARNING" "CrossRef" "test-registry.yaml" "Cross-cutting feature ID '$ccId'../ not in feature-tracking.md"
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

    # Load all three ID registries
    $registryMap = @{
        'PF' = @{ Path = (Join-Path $ProjectRoot "process-framework/PF-id-registry.json"); Registry = $null; Fixed = 0 }
        'PD' = @{ Path = (Join-Path $ProjectRoot "doc/PD-id-registry.json"); Registry = $null; Fixed = 0 }
        'TE' = @{ Path = (Join-Path $ProjectRoot "test/TE-id-registry.json"); Registry = $null; Fixed = 0 }
    }
    $allLoaded = $true
    foreach ($key in $registryMap.Keys) {
        $regPath = $registryMap[$key].Path
        if (Test-Path $regPath) {
            $registryMap[$key].Registry = Get-Content $regPath -Raw -Encoding UTF8 | ConvertFrom-Json
        } else {
            Add-CheckResult "ERROR" "IdCounters" "$key-id-registry.json" "File not found: $regPath"
            $allLoaded = $false
        }
    }

    if ($allLoaded) {
        # Prefixes to validate with their file patterns
        $prefixChecks = @(
            @{ Prefix = "PD-FIS";  Dir = "doc/state-tracking/features";                              Pattern = "*.md"; Domain = "PD" }
            @{ Prefix = "PD-FDD";  Dir = "doc/functional-design/fdds";                                Pattern = "*.md"; Domain = "PD" }
            @{ Prefix = "PD-TDD";  Dir = "doc/technical/architecture/design-docs/tdd";                Pattern = "*.md"; Domain = "PD" }
            @{ Prefix = "PD-ADR";  Dir = "doc/technical/architecture/design-docs/adr/adr";            Pattern = "*.md"; Domain = "PD" }
            @{ Prefix = "PD-ASS";  Dir = "doc/documentation-tiers/assessments";                       Pattern = "*.md"; Domain = "PD" }
            @{ Prefix = "TE-TSP";  Dir = "test/specifications/feature-specs";                                       Pattern = "*.md"; Domain = "TE" }
        )

        foreach ($check in $prefixChecks) {
            $prefix = $check.Prefix
            $domain = $check.Domain
            $dirPath = Join-Path $ProjectRoot $check.Dir

            # Get nextAvailable from the correct registry
            $idRegistry = $registryMap[$domain].Registry
            $registryEntry = $idRegistry.prefixes.$prefix
            if (-not $registryEntry) {
                Add-CheckResult "WARNING" "IdCounters" $prefix "Prefix not found in $domain-id-registry.json"
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
                    $idRegistry.prefixes.$prefix.nextAvailable = $expectedNext
                    $registryMap[$domain].Fixed++
                    Write-Host "      Fixed: nextAvailable set to $expectedNext" -ForegroundColor Magenta
                }
            } else {
                # nextAvailable > expectedNext — gap exists, just a warning
                Add-CheckResult "WARNING" "IdCounters" $prefix "nextAvailable=$nextAvailable but max ID is $prefix-$maxId (gap of $($nextAvailable - $expectedNext))"
            }
        }

        if ($FixCounters) {
            foreach ($key in $registryMap.Keys) {
                if ($registryMap[$key].Fixed -gt 0) {
                    $registryMap[$key].Registry | ConvertTo-Json -Depth 10 | Set-Content $registryMap[$key].Path -Encoding UTF8
                    Write-Host "  Fixed $($registryMap[$key].Fixed) counter(s) in $key-id-registry.json" -ForegroundColor Magenta
                }
            }
        }
    }
    Write-Host ""
}

# =========================================================================
# Surface 6: Feature Dependencies freshness
# =========================================================================
if ($runAll -or $Surface -contains "FeatureDeps") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 6: Feature Dependencies" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $depsFile = Join-Path $ProjectRoot "doc/technical/architecture/feature-dependencies.md"
    $updateScript = Join-Path $ProjectRoot "process-framework/scripts/update/Update-FeatureDependencies.ps1"

    if (-not (Test-Path $updateScript)) {
        Add-CheckResult "WARNING" "FeatureDeps" "Script" "Update-FeatureDependencies.ps1 not found"
    } else {
        # Check if any state file is newer than the generated dependencies file
        $needsRegeneration = $false
        if (-not (Test-Path $depsFile)) {
            $needsRegeneration = $true
        } else {
            $depsLastWrite = (Get-Item $depsFile).LastWriteTime
            $stateDir = Join-Path $ProjectRoot "doc/state-tracking/features"
            $newerFiles = Get-ChildItem -Path $stateDir -Filter "*-implementation-state.md" |
                Where-Object { $_.LastWriteTime -gt $depsLastWrite }
            if ($newerFiles.Count -gt 0) {
                $needsRegeneration = $true
            }
        }

        if ($needsRegeneration) {
            Write-Host "  Feature state files are newer than feature-dependencies.md — regenerating..." -ForegroundColor Yellow
            & $updateScript -Confirm:$false
            Add-CheckResult "OK" "FeatureDeps" "Regenerated" "feature-dependencies.md updated from state files"
        } else {
            Add-CheckResult "OK" "FeatureDeps" "UpToDate" "feature-dependencies.md is current"
        }
    }
    Write-Host ""
}

# =========================================================================
# Surface 7: Dimension Consistency
# =========================================================================
if ($runAll -or $Surface -contains "DimensionConsistency") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 7: Dimension Consistency" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $validDimensions = @("AC", "CQ", "ID", "DA", "EM", "SE", "PE", "OB", "UX", "DI")
    $stateDir = Join-Path $ProjectRoot "doc/state-tracking/features"

    if (Test-Path $stateDir) {
        $stateFiles = Get-ChildItem -Path $stateDir -Filter "*-implementation-state.md" -File
        $filesWithProfile = 0
        $filesWithoutProfile = 0

        foreach ($file in $stateFiles) {
            $content = Get-Content $file.FullName -Raw

            # Check if Dimension Profile section exists
            if ($content -match "## 7\. Dimension Profile") {
                $filesWithProfile++

                # Extract dimension abbreviations used and validate them
                $dimMatches = [regex]::Matches($content, '\(([A-Z]{2})\)')
                $usedDims = @()
                foreach ($m in $dimMatches) {
                    $abbr = $m.Groups[1].Value
                    if ($usedDims -notcontains $abbr) { $usedDims += $abbr }
                }

                foreach ($abbr in $usedDims) {
                    if ($validDimensions -notcontains $abbr) {
                        Add-CheckResult "ERROR" "DimensionConsistency" $file.Name "Invalid dimension abbreviation: $abbr"
                    }
                }

                # Check that importance values are valid
                $importanceMatches = [regex]::Matches($content, '(?<=\| [^|]+ \| )(Critical|Relevant|N/A)(?= \|)')
                if ($importanceMatches.Count -eq 0 -and $content -notmatch 'none evaluated') {
                    Add-CheckResult "WARNING" "DimensionConsistency" $file.Name "Dimension Profile section exists but no importance values found"
                }

                Add-CheckResult "OK" "DimensionConsistency" $file.Name "Dimension Profile present with $($usedDims.Count) dimensions"
            } else {
                $filesWithoutProfile++
                Add-CheckResult "WARNING" "DimensionConsistency" $file.Name "Missing Dimension Profile section (Section 7)"
            }
        }

        Write-Host "  Feature state files: $($stateFiles.Count) total, $filesWithProfile with profiles, $filesWithoutProfile without" -ForegroundColor Gray
    } else {
        Add-CheckResult "WARNING" "DimensionConsistency" "Directory" "Feature state directory not found: $stateDir"
    }
    Write-Host ""
}

# =========================================================================
# Surface 8: Workflow Tracking Consistency
# =========================================================================
if ($runAll -or $Surface -contains "WorkflowTracking") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 8: Workflow Tracking" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $wfPath = Join-Path $ProjectRoot "doc/state-tracking/permanent/user-workflow-tracking.md"

    if (-not (Test-Path $wfPath)) {
        Add-CheckResult "WARNING" "WorkflowTracking" "user-workflow-tracking.md" "File not found — workflow tracking not set up"
    } else {
        # Parse workflow tracking file for WF-IDs and Required Features
        $wfContent = Get-Content $wfPath -Encoding UTF8
        $workflowIds = @()
        $workflowFeatures = @{}  # WF-ID → list of feature IDs

        foreach ($line in $wfContent) {
            if ($line -match '^\|\s*(WF-\d+)') {
                $wfId = $matches[1]
                $workflowIds += $wfId
                $cells = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                # Required Features is typically the 4th column (index 3)
                if ($cells.Count -ge 4) {
                    $reqFeatures = $cells[3] -split ',\s*' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                    $workflowFeatures[$wfId] = $reqFeatures
                }
            }
        }

        Write-Host "  Found $($workflowIds.Count) workflows" -ForegroundColor Gray

        # Load known feature IDs from feature-tracking.md
        $ftPath2 = Join-Path $ProjectRoot "doc/state-tracking/permanent/feature-tracking.md"
        $knownFeatures2 = @()
        if (Test-Path $ftPath2) {
            $ftContent2 = Get-Content $ftPath2 -Encoding UTF8
            foreach ($line in $ftContent2) {
                if ($line -match '^\|\s*\[(\d+\.\d+\.\d+)\]') {
                    $knownFeatures2 += $matches[1]
                }
            }
        }

        # Check 1: All Required Features reference valid feature IDs
        foreach ($wfId in $workflowIds) {
            if ($workflowFeatures.ContainsKey($wfId)) {
                foreach ($fId in $workflowFeatures[$wfId]) {
                    if ($fId -match '^\d+\.\d+\.\d+$') {
                        if ($knownFeatures2 -contains $fId) {
                            Add-CheckResult "OK" "WorkflowTracking" "$wfId/$fId" "Required feature exists in feature tracking"
                        } else {
                            Add-CheckResult "ERROR" "WorkflowTracking" "$wfId/$fId" "Required feature '$fId' not found in feature-tracking.md"
                        }
                    }
                }
            }
        }

        # Check 2: Feature state files' workflows: metadata references valid WF-IDs
        $stateDir2 = Join-Path $ProjectRoot "doc/state-tracking/features"
        if (Test-Path $stateDir2) {
            $stateFiles2 = Get-ChildItem -Path $stateDir2 -Filter "*-implementation-state.md" -File
            foreach ($sf in $stateFiles2) {
                $sfContent = Get-Content $sf.FullName -Raw -Encoding UTF8
                # Extract feature ID from filename (e.g., 0.1.1-core-architecture-implementation-state.md)
                $featureIdFromName = ""
                if ($sf.Name -match '^(\d+\.\d+\.\d+)') {
                    $featureIdFromName = $matches[1]
                }

                # Find workflows: metadata — supports both YAML list format and inline format
                # YAML list: "workflows:\n  - WF-001\n  - WF-002"
                # Inline: "workflows: [WF-001, WF-002]"
                $wfList = @()
                if ($sfContent -match 'workflows:\s*\[([^\]]*)\]') {
                    # Inline format
                    $wfList = $matches[1] -split ',\s*' | ForEach-Object { $_.Trim().Trim('"').Trim("'") } | Where-Object { $_ -ne '' }
                } elseif ($sfContent -match 'workflows:') {
                    # YAML list format — extract all "  - WF-XXX" lines after "workflows:"
                    $wfMatches = [regex]::Matches($sfContent, '(?<=workflows:[\s\S]*?)- (WF-\d+)')
                    foreach ($m in $wfMatches) {
                        $wfList += $m.Groups[1].Value
                    }
                }

                if ($wfList.Count -gt 0) {
                    foreach ($wf in $wfList) {
                        if ($workflowIds -contains $wf) {
                            Add-CheckResult "OK" "WorkflowTracking" "$($sf.Name)/$wf" "Workflow reference valid"
                        } else {
                            Add-CheckResult "ERROR" "WorkflowTracking" "$($sf.Name)/$wf" "Workflow '$wf' not found in user-workflow-tracking.md"
                        }
                    }

                    # Check 3: Cross-reference — if feature lists WF-ID, does that workflow list this feature?
                    foreach ($wf in $wfList) {
                        if ($workflowFeatures.ContainsKey($wf) -and $featureIdFromName) {
                            if ($workflowFeatures[$wf] -contains $featureIdFromName) {
                                Add-CheckResult "OK" "WorkflowTracking" "$($sf.Name)/$wf" "Cross-reference valid (feature listed in workflow)"
                            } else {
                                Add-CheckResult "WARNING" "WorkflowTracking" "$($sf.Name)/$wf" "Feature $featureIdFromName claims workflow $wf but is not listed in that workflow's Required Features"
                            }
                        }
                    }
                }
                # Note: missing workflows: field is not an error — it may be an older state file
            }
        }
    }
    Write-Host ""
}

# =========================================================================
# Surface 9: Task Registry Completeness
# =========================================================================
if ($runAll -or $Surface -contains "TaskRegistry") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 9: Task Registry" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $registryPath = Join-Path $ProjectRoot "process-framework/infrastructure/process-framework-task-registry.md"
    $pfIdRegistryPath = Join-Path $ProjectRoot "process-framework/PF-id-registry.json"

    if (-not (Test-Path $registryPath)) {
        Add-CheckResult "WARNING" "TaskRegistry" "process-framework-task-registry.md" "File not found — task registry not set up"
    } elseif (-not (Test-Path $pfIdRegistryPath)) {
        Add-CheckResult "WARNING" "TaskRegistry" "PF-id-registry.json" "File not found — cannot determine expected task IDs"
    } else {
        # Get all PF-TSK IDs that have been assigned (from nextAvailable counter)
        $pfRegistry = Get-Content $pfIdRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $nextAvailable = $pfRegistry.prefixes.'PF-TSK'.nextAvailable
        $allTaskIds = @()
        for ($i = 1; $i -lt $nextAvailable; $i++) {
            $allTaskIds += "PF-TSK-{0:D3}" -f $i
        }

        # Get all PF-TSK IDs mentioned in the task registry
        $registryContent = Get-Content $registryPath -Raw -Encoding UTF8
        $registryTaskIds = @()
        $idMatches = [regex]::Matches($registryContent, 'PF-TSK-\d{3}')
        foreach ($m in $idMatches) {
            if ($registryTaskIds -notcontains $m.Value) {
                $registryTaskIds += $m.Value
            }
        }

        # Also get task IDs that actually have files on disk (to avoid flagging deleted tasks)
        $taskDir = Join-Path $ProjectRoot "process-framework/tasks"
        $taskFiles = Get-ChildItem -Path $taskDir -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue
        $taskFileIds = @()
        foreach ($tf in $taskFiles) {
            $firstLines = Get-Content $tf.FullName -TotalCount 10 -Encoding UTF8 -ErrorAction SilentlyContinue
            foreach ($line in $firstLines) {
                if ($line -match '^id:\s*(PF-TSK-\d{3})') {
                    $taskFileIds += $matches[1]
                    break
                }
            }
        }

        Write-Host "  Task IDs assigned: $($allTaskIds.Count), In registry: $($registryTaskIds.Count), With files: $($taskFileIds.Count)" -ForegroundColor Gray

        # Check: every task ID with an actual file on disk should be in the registry
        # Exclude PF-TSK-000 (tasks/README.md index file, not an actual task)
        $taskFileIds = $taskFileIds | Where-Object { $_ -ne "PF-TSK-000" }
        $missingCount = 0
        foreach ($tid in $taskFileIds) {
            if ($registryTaskIds -contains $tid) {
                Add-CheckResult "OK" "TaskRegistry" $tid "Present in task registry"
            } else {
                Add-CheckResult "ERROR" "TaskRegistry" $tid "Has task file on disk but missing from task registry"
                $missingCount++
            }
        }

        if ($missingCount -gt 0) {
            Write-Host "    $([char]0x2139) $missingCount task(s) missing from registry — run New-Task.ps1 or add manually" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# =========================================================================
# Surface 10: Metadata Schema Conformance
# =========================================================================
if ($runAll -or $Surface -contains "MetadataSchema") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 10: Metadata Schema" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $domainCfgPath = Join-Path $ProjectRoot "process-framework/domain-config.json"
    if (-not (Test-Path $domainCfgPath)) {
        Add-CheckResult "WARNING" "MetadataSchema" "domain-config.json" "File not found — metadata schema validation skipped"
    } else {
        $domainCfg = Get-Content $domainCfgPath -Raw | ConvertFrom-Json
        $schemas = $domainCfg.artifact_metadata_schemas

        if (-not $schemas) {
            Add-CheckResult "WARNING" "MetadataSchema" "domain-config.json" "No artifact_metadata_schemas section found"
        } else {
            # Map artifact types to directory globs
            $artifactDirs = @{
                "task"        = @{ dir = "process-framework/tasks"; recurse = $true }
                "template"    = @{ dir = "process-framework/templates"; recurse = $true }
                "guide"       = @{ dir = "process-framework/guides"; recurse = $true }
                "context_map" = @{ dir = "process-framework/visualization/context-maps"; recurse = $true }
            }

            $totalFiles = 0
            $conformingFiles = 0
            $violationFiles = 0

            foreach ($artifactType in $artifactDirs.Keys) {
                $schema = $schemas.$artifactType
                if (-not $schema) {
                    Add-CheckResult "WARNING" "MetadataSchema" $artifactType "No schema defined in domain-config.json"
                    continue
                }

                $searchDir = Join-Path $ProjectRoot $artifactDirs[$artifactType].dir
                if (-not (Test-Path $searchDir)) { continue }

                $mdFiles = Get-ChildItem -Path $searchDir -Filter "*.md" -Recurse -File | Where-Object {
                    # Exclude README files — they are not artifacts with standard metadata
                    $_.Name -ne "README.md"
                }

                foreach ($file in $mdFiles) {
                    $totalFiles++
                    $content = Get-Content $file.FullName -Raw -Encoding UTF8
                    $relPath = $file.FullName.Substring($ProjectRoot.Length + 1) -replace '\\', '/'

                    # Extract YAML frontmatter
                    if ($content -notmatch '^---\s*\r?\n([\s\S]*?)\r?\n---') {
                        Add-CheckResult "WARNING" "MetadataSchema" $relPath "No YAML frontmatter found"
                        $violationFiles++
                        continue
                    }

                    $frontmatter = $Matches[1]
                    # Parse frontmatter into hashtable (simple key: value parsing)
                    $fields = @{}
                    foreach ($line in ($frontmatter -split '\r?\n')) {
                        if ($line -match '^(\w[\w_]*):\s*(.*)$') {
                            $fields[$Matches[1]] = $Matches[2].Trim()
                        }
                    }

                    $fileHasViolation = $false

                    # Check required fields
                    foreach ($reqField in $schema.required) {
                        if (-not $fields.ContainsKey($reqField)) {
                            Add-CheckResult "ERROR" "MetadataSchema" $relPath "Missing required field: $reqField"
                            $fileHasViolation = $true
                        }
                    }

                    # Check field values (only for fields that exist)
                    if ($schema.field_values) {
                        # Check id pattern
                        if ($schema.field_values.id_pattern -and $fields.ContainsKey("id")) {
                            $idVal = $fields["id"]
                            # Skip template placeholder IDs (contain [ or X)
                            if ($idVal -notmatch '\[' -and $idVal -notmatch 'XXX') {
                                if ($idVal -notmatch $schema.field_values.id_pattern) {
                                    Add-CheckResult "ERROR" "MetadataSchema" $relPath "ID '$idVal' does not match pattern $($schema.field_values.id_pattern)"
                                    $fileHasViolation = $true
                                }
                            }
                        }

                        # Check type value
                        if ($schema.field_values.type -and $fields.ContainsKey("type")) {
                            $typeVal = $fields["type"]
                            $allowedTypes = @($schema.field_values.type)
                            if ($typeVal -notin $allowedTypes) {
                                Add-CheckResult "ERROR" "MetadataSchema" $relPath "type '$typeVal' not in allowed values: $($allowedTypes -join ', ')"
                                $fileHasViolation = $true
                            }
                        }

                        # Check category value
                        if ($schema.field_values.category -and $fields.ContainsKey("category")) {
                            $catVal = $fields["category"]
                            $allowedCats = @($schema.field_values.category)
                            if ($catVal -notin $allowedCats) {
                                Add-CheckResult "ERROR" "MetadataSchema" $relPath "category '$catVal' not in allowed values: $($allowedCats -join ', ')"
                                $fileHasViolation = $true
                            }
                        }
                    }

                    # Check for unknown fields (not in required or optional)
                    $knownFields = @($schema.required) + @($schema.optional)
                    foreach ($fieldName in $fields.Keys) {
                        if ($fieldName -notin $knownFields) {
                            Add-CheckResult "WARNING" "MetadataSchema" $relPath "Unknown field: $fieldName (not in schema for $artifactType)"
                            $fileHasViolation = $true
                        }
                    }

                    if ($fileHasViolation) {
                        $violationFiles++
                    } else {
                        $conformingFiles++
                        Add-CheckResult "OK" "MetadataSchema" $relPath "Conforms to $artifactType schema"
                    }
                }
            }

            Write-Host "  Scanned $totalFiles files: $conformingFiles conforming, $violationFiles with violations" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

# =========================================================================
# Surface 11: Context Map Orphan Detection
# =========================================================================
if ($runAll -or $Surface -contains "ContextMapOrphans") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 11: Context Map Orphans" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $cmDir = Join-Path $ProjectRoot "process-framework/visualization/context-maps"
    if (-not (Test-Path $cmDir)) {
        Add-CheckResult "WARNING" "ContextMapOrphans" "context-maps/" "Directory not found — skipped"
    } else {
        # Build a lookup of all task IDs from task files
        $taskDir = Join-Path $ProjectRoot "process-framework/tasks"
        $taskIds = @{}
        if (Test-Path $taskDir) {
            $taskFiles = Get-ChildItem -Path $taskDir -Filter "*.md" -Recurse -File | Where-Object { $_.Name -ne "README.md" }
            foreach ($tf in $taskFiles) {
                $tfContent = Get-Content $tf.FullName -Raw -Encoding UTF8
                if ($tfContent -match '(?m)^id:\s*(PF-TSK-\d+)') {
                    $taskIds[$Matches[1]] = $tf.FullName.Substring($ProjectRoot.Length + 1) -replace '\\', '/'
                }
            }
        }

        # Scan context maps for related_task references
        $cmFiles = Get-ChildItem -Path $cmDir -Filter "*.md" -Recurse -File | Where-Object { $_.Name -ne "README.md" }
        $orphanCount = 0
        $checkedCount = 0

        foreach ($cm in $cmFiles) {
            $cmContent = Get-Content $cm.FullName -Raw -Encoding UTF8
            $cmRelPath = $cm.FullName.Substring($ProjectRoot.Length + 1) -replace '\\', '/'

            # Extract related_task from frontmatter
            if ($cmContent -match '(?m)^related_task:\s*(PF-TSK-\d+)') {
                $relatedTask = $Matches[1]
                $checkedCount++

                if ($taskIds.ContainsKey($relatedTask)) {
                    Add-CheckResult "OK" "ContextMapOrphans" $cmRelPath "related_task $relatedTask exists at $($taskIds[$relatedTask])"
                } else {
                    Add-CheckResult "ERROR" "ContextMapOrphans" $cmRelPath "Orphaned — related_task $relatedTask not found in any task file"
                    $orphanCount++
                }
            } elseif ($cmContent -match '^---\s*\r?\n[\s\S]*?\r?\n---') {
                # Has frontmatter but no related_task
                $checkedCount++
                Add-CheckResult "WARNING" "ContextMapOrphans" $cmRelPath "No related_task field in frontmatter"
            }
        }

        Write-Host "  Checked $checkedCount context maps: $orphanCount orphaned" -ForegroundColor Gray
    }
    Write-Host ""
}

# =========================================================================
# Surface 12: AI Tasks Consistency
# =========================================================================
if ($runAll -or $Surface -contains "AiTasksConsistency") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 12: AI Tasks Consistency" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $aiTasksPath = Join-Path $ProjectRoot "process-framework/ai-tasks.md"
    $taskDir = Join-Path $ProjectRoot "process-framework/tasks"

    if (-not (Test-Path $aiTasksPath)) {
        Add-CheckResult "WARNING" "AiTasksConsistency" "ai-tasks.md" "File not found — skipped"
    } elseif (-not (Test-Path $taskDir)) {
        Add-CheckResult "WARNING" "AiTasksConsistency" "tasks/" "Directory not found — skipped"
    } else {
        $aiTasksContent = Get-Content $aiTasksPath -Raw -Encoding UTF8

        # Collect all task IDs from task files on disk
        $taskFiles = Get-ChildItem -Path $taskDir -Filter "*.md" -Recurse -File | Where-Object { $_.Name -ne "README.md" }
        $diskTasks = @{}
        foreach ($tf in $taskFiles) {
            $firstLines = Get-Content $tf.FullName -TotalCount 10 -Encoding UTF8 -ErrorAction SilentlyContinue
            foreach ($line in $firstLines) {
                if ($line -match '^id:\s*(PF-TSK-\d{3})') {
                    $relPath = $tf.FullName.Substring($ProjectRoot.Length + 1) -replace '\\', '/'
                    $diskTasks[$matches[1]] = $relPath
                    break
                }
            }
        }

        # Check which task files are referenced in ai-tasks.md
        $missingCount = 0
        foreach ($entry in $diskTasks.GetEnumerator() | Sort-Object Key) {
            $taskId = $entry.Key
            $taskFile = $entry.Value
            # Extract just the filename to check for references (ai-tasks.md uses relative links to task files)
            $fileName = [System.IO.Path]::GetFileName($taskFile)

            if ($aiTasksContent -match [regex]::Escape($fileName) -or $aiTasksContent -match [regex]::Escape($taskId)) {
                Add-CheckResult "OK" "AiTasksConsistency" $taskId "Referenced in ai-tasks.md ($fileName)"
            } else {
                Add-CheckResult "ERROR" "AiTasksConsistency" $taskId "Task file exists ($taskFile) but not referenced in ai-tasks.md"
                $missingCount++
            }
        }

        Write-Host "  Task files on disk: $($diskTasks.Count), Missing from ai-tasks.md: $missingCount" -ForegroundColor Gray
        if ($missingCount -gt 0) {
            Write-Host "    $([char]0x2139) $missingCount task(s) on disk not referenced in ai-tasks.md — add entries or remove stale files" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# =========================================================================
# Surface 13: Master State Consistency (IMP-004)
# =========================================================================
if ($runAll -or $Surface -contains "MasterStateConsistency") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 13: Master State Consistency" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # Find retrospective master state files in temporary and archived directories
    $masterStateFiles = @()
    $tempDir = Join-Path $ProjectRoot "doc/state-tracking/temporary"
    $archivedDir = Join-Path $ProjectRoot "doc/state-tracking/temporary/archived"
    foreach ($dir in @($tempDir, $archivedDir)) {
        if (Test-Path $dir) {
            $found = Get-ChildItem -Path $dir -Filter "retrospective-master-state*.md" -File -ErrorAction SilentlyContinue
            if ($found) { $masterStateFiles += $found }
        }
    }

    if ($masterStateFiles.Count -eq 0) {
        Add-CheckResult "OK" "MasterStateConsistency" "Search" "No retrospective master state files found — nothing to validate"
    } else {
        foreach ($msFile in $masterStateFiles) {
            $msName = $msFile.Name
            $msLines = Get-Content $msFile.FullName -Encoding UTF8
            Write-Host "  Validating: $msName" -ForegroundColor Gray

            # --- Parse Feature Inventory tables ---
            # Collect status per column across all category tables
            $inInventory = $false
            $inventoryHeaders = @()
            $featureRows = @()

            for ($i = 0; $i -lt $msLines.Count; $i++) {
                $line = $msLines[$i]

                # Detect Feature Inventory section
                if ($line -match '^## Feature Inventory') {
                    $inInventory = $true
                    continue
                }
                # Stop at next top-level section
                if ($inInventory -and $line -match '^## [^F]') {
                    $inInventory = $false
                    continue
                }
                if (-not $inInventory) { continue }

                # Detect category table headers
                if ($line -match '^\|\s*Feature ID\s*\|') {
                    # Parse header columns
                    $inventoryHeaders = ($line -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                    continue
                }
                # Skip separator rows
                if ($line -match '^\|\s*[-:]+\s*\|') { continue }
                # Skip non-table lines
                if ($line -notmatch '^\|') { continue }

                # Parse data row
                $cells = ($line -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                if ($cells.Count -ge 2 -and $cells[0] -match '^\d+\.\d+\.\d+') {
                    $row = @{}
                    for ($c = 0; $c -lt [Math]::Min($cells.Count, $inventoryHeaders.Count); $c++) {
                        $row[$inventoryHeaders[$c]] = $cells[$c]
                    }
                    $featureRows += $row
                }
            }

            if ($featureRows.Count -eq 0) {
                Add-CheckResult "WARNING" "MasterStateConsistency" $msName "No feature rows found in Feature Inventory"
                continue
            }

            $totalFeatures = $featureRows.Count
            Write-Host "  Found $totalFeatures features in inventory" -ForegroundColor Gray

            # --- Helper: count statuses in a column ---
            function Get-StatusCounts {
                param([string]$ColumnName)
                $complete = 0; $inProgress = 0; $notStarted = 0; $na = 0
                foreach ($row in $featureRows) {
                    $val = $row[$ColumnName]
                    if ($null -eq $val -or $val -eq '') { $notStarted++; continue }
                    if ($val -match 'N/A') { $na++; continue }
                    if ($val -match ([char]0x2705) -or $val -match '✅') { $complete++ }
                    elseif ($val -match ([char]0x1F7E1) -or $val -match '🟡') { $inProgress++ }
                    elseif ($val -match ([char]0x2B1C) -or $val -match '⬜') { $notStarted++ }
                    else { $complete++ }  # Assume non-emoji non-NA content means done (e.g. tier text)
                }
                return @{ Complete = $complete; InProgress = $inProgress; NotStarted = $notStarted; NA = $na }
            }

            # --- Validate Phase Completion Checkboxes ---
            # Phase 1 = Impl State column all ✅
            # Phase 2 = Analyzed column all ✅
            # Phase 3 = Assessed column all ✅
            $phaseColumnMap = @{
                1 = "Impl State"
                2 = "Analyzed"
                3 = "Assessed"
            }

            foreach ($phase in 1..3) {
                $colName = $phaseColumnMap[$phase]
                $counts = Get-StatusCounts -ColumnName $colName

                $allComplete = ($counts.Complete -eq ($totalFeatures - $counts.NA)) -and $counts.NotStarted -eq 0 -and $counts.InProgress -eq 0

                # Find the checkbox line for this phase
                $checkboxLine = $msLines | Where-Object { $_ -match "Phase $phase" -and $_ -match '^\s*-\s*\[' } | Select-Object -First 1
                if ($null -eq $checkboxLine) { continue }

                $isChecked = $checkboxLine -match '^\s*-\s*\[x\]'

                if ($allComplete -and -not $isChecked) {
                    Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/Phase $phase checkbox" "All $($counts.Complete) features complete in '$colName' but checkbox is unchecked"
                } elseif (-not $allComplete -and $isChecked) {
                    Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/Phase $phase checkbox" "Checkbox is checked but inventory shows $($counts.NotStarted) not started, $($counts.InProgress) in progress"
                } else {
                    Add-CheckResult "OK" "MasterStateConsistency" "$msName/Phase $phase checkbox" "Checkbox matches inventory ($($counts.Complete) complete)"
                }
            }

            # Phase 4 — check if status header says COMPLETE
            $phase4Line = $msLines | Where-Object { $_ -match 'Phase 4' -and $_ -match '^\s*-\s*\[' } | Select-Object -First 1
            if ($null -ne $phase4Line) {
                $p4Checked = $phase4Line -match '^\s*-\s*\[x\]'
                $statusLine = $msLines | Where-Object { $_ -match '^\*\*Status\*\*:' } | Select-Object -First 1
                $isComplete = $statusLine -match 'COMPLETE'
                if ($p4Checked -and -not $isComplete) {
                    Add-CheckResult "WARNING" "MasterStateConsistency" "$msName/Phase 4 checkbox" "Checked but Status header does not say COMPLETE"
                } elseif (-not $p4Checked -and $isComplete) {
                    Add-CheckResult "WARNING" "MasterStateConsistency" "$msName/Phase 4 checkbox" "Status says COMPLETE but Phase 4 checkbox unchecked"
                } else {
                    Add-CheckResult "OK" "MasterStateConsistency" "$msName/Phase 4 checkbox" "Consistent with Status header"
                }
            }

            # --- Validate Feature Progress Overview counters ---
            $progressTableLines = @()
            $inProgressTable = $false
            foreach ($line in $msLines) {
                if ($line -match '^\|\s*Phase\s*\|.*Not Started') { $inProgressTable = $true }
                if ($inProgressTable) {
                    if ($line -match '^\|') {
                        $progressTableLines += $line
                    } elseif ($progressTableLines.Count -gt 0) {
                        break
                    }
                }
            }

            $phaseProgressMap = @{
                "Phase 1" = "Impl State"
                "Phase 2" = "Analyzed"
                "Phase 3" = "Assessed"
            }

            foreach ($pLine in $progressTableLines) {
                # Skip header and separator
                if ($pLine -match 'Not Started' -or $pLine -match '^\|\s*[-:]+') { continue }

                $pCells = ($pLine -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                if ($pCells.Count -lt 4) { continue }

                $phaseName = $pCells[0] -replace '^\s*Phase\s+\d+:\s*', '' -replace '\s*$', ''
                $statedNotStarted = [int]($pCells[1] -replace '[^\d]', '')
                $statedInProgress = [int]($pCells[2] -replace '[^\d]', '')
                $statedComplete = [int]($pCells[3] -replace '[^\d]', '')

                # Determine which phase this is
                $matchedCol = $null
                foreach ($key in $phaseProgressMap.Keys) {
                    if ($pCells[0] -match $key.Replace("Phase ", "Phase\s+")) {
                        $matchedCol = $phaseProgressMap[$key]
                        break
                    }
                }
                if ($null -eq $matchedCol) { continue }

                $actual = Get-StatusCounts -ColumnName $matchedCol
                $actualApplicable = $totalFeatures - $actual.NA

                $mismatch = $false
                $details = @()
                if ($statedNotStarted -ne $actual.NotStarted) {
                    $mismatch = $true
                    $details += "NotStarted: stated=$statedNotStarted actual=$($actual.NotStarted)"
                }
                if ($statedInProgress -ne $actual.InProgress) {
                    $mismatch = $true
                    $details += "InProgress: stated=$statedInProgress actual=$($actual.InProgress)"
                }
                if ($statedComplete -ne $actual.Complete) {
                    $mismatch = $true
                    $details += "Complete: stated=$statedComplete actual=$($actual.Complete)"
                }

                if ($mismatch) {
                    Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/Progress/$matchedCol" "Counter mismatch: $($details -join ', ')"
                } else {
                    Add-CheckResult "OK" "MasterStateConsistency" "$msName/Progress/$matchedCol" "Counters match ($statedComplete complete, $statedNotStarted not started, $statedInProgress in progress)"
                }
            }

            # --- Validate Documentation Requirements Summary ---
            # Validates feature count and per-column "features needing" counts.
            # Note: ADR counts in the summary may exceed inventory ✅ count because
            # a single feature can have multiple ADRs (e.g., ✅ with "3/3" in summary).
            # We validate the "needed" denominator (features requiring that doc type)
            # against the inventory's non-N/A count for FDD, TDD, Test Spec.
            $docSummaryLines = @()
            $inDocSummary = $false
            foreach ($line in $msLines) {
                if ($line -match '^\|\s*Tier\s*\|.*Feature Count') { $inDocSummary = $true }
                if ($inDocSummary) {
                    if ($line -match '^\|') {
                        $docSummaryLines += $line
                    } elseif ($docSummaryLines.Count -gt 0) {
                        break
                    }
                }
            }

            # Count features needing each doc type from inventory (non-N/A entries)
            $docColumns = @("FDD", "TDD", "Test Spec")
            $actualDocCounts = @{}
            foreach ($col in $docColumns) {
                $counts = Get-StatusCounts -ColumnName $col
                $actualDocCounts[$col] = @{
                    Created = $counts.Complete
                    Needed = $counts.Complete + $counts.InProgress + $counts.NotStarted
                }
            }

            # Parse the Total row from Documentation Requirements Summary
            $totalRow = $docSummaryLines | Where-Object { $_ -match '\*\*Total\*\*' } | Select-Object -First 1
            if ($null -ne $totalRow) {
                $totalCells = ($totalRow -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                # Header: Tier | Feature Count | Impl State | FDD Needed | TDD Needed | Test Spec | ADR | Total Docs Needed | Docs Created

                # Check feature count
                $statedFeatureCount = $totalCells[1] -replace '[^\d]', ''
                if ($statedFeatureCount -and [int]$statedFeatureCount -ne $totalFeatures) {
                    Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/DocSummary/FeatureCount" "Stated $statedFeatureCount features but inventory has $totalFeatures"
                } else {
                    Add-CheckResult "OK" "MasterStateConsistency" "$msName/DocSummary/FeatureCount" "Feature count matches ($totalFeatures)"
                }

                # Per-column validation: FDD (index 3), TDD (index 4), Test Spec (index 5)
                # These columns use "x/y" format where y = features needing, x = features with docs created
                $colIndexMap = @{ "FDD" = 3; "TDD" = 4; "Test Spec" = 5 }
                foreach ($col in $docColumns) {
                    $idx = $colIndexMap[$col]
                    if ($totalCells.Count -le $idx) { continue }
                    $cellVal = $totalCells[$idx]

                    # Parse "x/y" or "**x/y**" format
                    if ($cellVal -match '(\d+)\s*/\s*(\d+)') {
                        $statedCreated = [int]$matches[1]
                        $statedNeeded = [int]$matches[2]
                        $actualNeeded = $actualDocCounts[$col].Needed
                        $actualCreated = $actualDocCounts[$col].Created

                        $mismatch = $false
                        $details = @()
                        if ($statedNeeded -ne $actualNeeded) {
                            $mismatch = $true
                            $details += "needed: stated=$statedNeeded actual=$actualNeeded"
                        }
                        if ($statedCreated -ne $actualCreated) {
                            $mismatch = $true
                            $details += "created: stated=$statedCreated actual=$actualCreated"
                        }

                        if ($mismatch) {
                            Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/DocSummary/$col" "Mismatch: $($details -join ', ')"
                        } else {
                            Add-CheckResult "OK" "MasterStateConsistency" "$msName/DocSummary/$col" "$col counts match ($statedCreated/$statedNeeded)"
                        }
                    }
                }

                # Impl State column (index 2) — validate "x/y" against inventory
                if ($totalCells.Count -gt 2) {
                    $implCell = $totalCells[2]
                    if ($implCell -match '(\d+)\s*/\s*(\d+)') {
                        $statedImplCreated = [int]$matches[1]
                        $statedImplNeeded = [int]$matches[2]
                        $implCounts = Get-StatusCounts -ColumnName "Impl State"
                        if ($statedImplNeeded -ne $totalFeatures) {
                            Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/DocSummary/ImplState" "Stated $statedImplNeeded needed but inventory has $totalFeatures features"
                        } elseif ($statedImplCreated -ne $implCounts.Complete) {
                            Add-CheckResult "ERROR" "MasterStateConsistency" "$msName/DocSummary/ImplState" "Stated $statedImplCreated created but inventory shows $($implCounts.Complete) complete"
                        } else {
                            Add-CheckResult "OK" "MasterStateConsistency" "$msName/DocSummary/ImplState" "Impl State counts match ($statedImplCreated/$statedImplNeeded)"
                        }
                    }
                }
            } elseif ($docSummaryLines.Count -gt 0) {
                Add-CheckResult "WARNING" "MasterStateConsistency" "$msName/DocSummary" "Documentation Requirements Summary found but no Total row"
            }
        }
    }
    Write-Host ""
}

# =========================================================================
# Surface 14: Source Layout — compare layout doc directory tree vs actual source dirs
# =========================================================================
if ($runAll -or $Surface -contains "SourceLayout") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 14: Source Layout" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $layoutDocPath = Join-Path $ProjectRoot "doc/technical/architecture/source-code-layout.md"

    if (-not (Test-Path $layoutDocPath)) {
        Add-CheckResult "OK" "SourceLayout" "Search" "No source-code-layout.md found — nothing to validate"
    } else {
        # Read project-config.json for source root
        $sourceCodePath = $null
        if (Test-Path $projectConfigPath) {
            try {
                $pcfg = Get-Content $projectConfigPath -Raw | ConvertFrom-Json
                $sourceCodePath = $pcfg.paths.source_code
            } catch {}
        }

        if ([string]::IsNullOrWhiteSpace($sourceCodePath) -or $sourceCodePath -eq ".") {
            Add-CheckResult "WARNING" "SourceLayout" "project-config.json" "paths.source_code is not set or is '.'"
        } else {
            $sourceRootAbs = Join-Path $ProjectRoot $sourceCodePath

            if (-not (Test-Path $sourceRootAbs)) {
                Add-CheckResult "ERROR" "SourceLayout" "SourceRoot" "Source root '$sourceCodePath' does not exist on disk but source-code-layout.md exists"
            } else {
                # Parse directory tree from layout doc — extract directory names from the code block
                $layoutContent = Get-Content $layoutDocPath -Raw
                $docDirs = @()

                if ($layoutContent -match '(?s)## Directory Tree.*?```\s*\n[^\n]+/\n([\s\S]*?)```') {
                    $treeBlock = $Matches[1]
                    # Extract top-level directories (2 spaces indent = direct child of source root)
                    foreach ($line in ($treeBlock -split "`n")) {
                        if ($line -match '^  ([a-zA-Z0-9_\-]+)/$') {
                            $docDirs += $Matches[1]
                        }
                    }
                }

                # Get actual directories on disk
                $actualDirs = @()
                if (Test-Path $sourceRootAbs) {
                    $actualDirs = Get-ChildItem -Path $sourceRootAbs -Directory |
                        Where-Object { $_.Name -ne "__pycache__" -and $_.Name -ne ".git" -and $_.Name -ne "node_modules" -and $_.Name -ne ".venv" -and $_.Name -ne "venv" } |
                        ForEach-Object { $_.Name }
                }

                if ($docDirs.Count -eq 0 -and $actualDirs.Count -eq 0) {
                    Add-CheckResult "OK" "SourceLayout" "DirTree" "Both layout doc and disk are empty"
                } elseif ($docDirs.Count -eq 0) {
                    Add-CheckResult "WARNING" "SourceLayout" "DirTree" "No directory tree found in layout doc but $($actualDirs.Count) directories exist on disk — run New-SourceStructure.ps1 -Update"
                } else {
                    # Compare: directories in doc but not on disk
                    $missingOnDisk = $docDirs | Where-Object { $_ -notin $actualDirs }
                    foreach ($d in $missingOnDisk) {
                        Add-CheckResult "ERROR" "SourceLayout" "DirTree/$d" "Listed in layout doc but missing from disk"
                    }

                    # Compare: directories on disk but not in doc
                    $missingInDoc = $actualDirs | Where-Object { $_ -notin $docDirs }
                    foreach ($d in $missingInDoc) {
                        Add-CheckResult "ERROR" "SourceLayout" "DirTree/$d" "Exists on disk but not in layout doc — run New-SourceStructure.ps1 -Update"
                    }

                    # All matching
                    $matching = $docDirs | Where-Object { $_ -in $actualDirs }
                    foreach ($d in $matching) {
                        Add-CheckResult "OK" "SourceLayout" "DirTree/$d" "Consistent between doc and disk"
                    }
                }

                # Check naming convention compliance
                if (Test-Path $projectConfigPath) {
                    try {
                        $lang = $pcfg.testing.language.ToLower()
                        $lcPath = Join-Path $ProjectRoot "languages-config/$lang/$lang-config.json"
                        if (Test-Path $lcPath) {
                            $lc = Get-Content $lcPath -Raw | ConvertFrom-Json
                            $namingConvention = $lc.directoryStructure.directoryNaming
                            if ($namingConvention) {
                                foreach ($d in $actualDirs) {
                                    $valid = switch ($namingConvention) {
                                        "snake_case" { $d -cmatch '^[a-z][a-z0-9_]*$' }
                                        "kebab-case" { $d -cmatch '^[a-z][a-z0-9\-]*$' }
                                        "PascalCase" { $d -cmatch '^[A-Z][a-zA-Z0-9]*$' }
                                        default { $true }
                                    }
                                    if (-not $valid) {
                                        Add-CheckResult "WARNING" "SourceLayout" "Naming/$d" "Directory '$d' does not match $namingConvention convention"
                                    } else {
                                        Add-CheckResult "OK" "SourceLayout" "Naming/$d" "Matches $namingConvention convention"
                                    }
                                }
                            }
                        }
                    } catch {
                        # Naming check is best-effort
                    }
                }
            }
        }
    }
    Write-Host ""
}

# =========================================================================
# Surface 15: Test Status Aggregation Consistency
# =========================================================================
# Cross-checks per-feature aggregated test statuses from test-tracking.md
# against the Test Status column in feature-tracking.md. Catches split-brain
# states (e.g. 0.1.2 on 2026-04-17 had test-tracking ✅ Audit Approved but
# feature-tracking 🔄 Tests Need Update for ~2 weeks).
#
# Mirrors aggregation logic from Update-TestFileAuditState.ps1 (~lines 595-612)
# with one deliberate extension: 🔴 Needs Fix in test-tracking aggregates to
# "🔴 Some Failing" (the writer only emits this when invoked explicitly with
# -AuditStatus "Audit Failed"), so without the extension a feature with only
# 🔴 Needs Fix rows would falsely aggregate to "in progress".
#
# Post-SC-027: both writers and legend use the unified feature-tracking.md
# legend vocabulary, so comparison is direct string equality (no canonical-
# group mapping needed).
# =========================================================================
if ($runAll -or $Surface -contains "TestStatusAggregation") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 15: Test Status Aggregation Consistency" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $ttPath = Join-Path $ProjectRoot "test/state-tracking/permanent/test-tracking.md"
    $ftPath = Join-Path $ProjectRoot "doc/state-tracking/permanent/feature-tracking.md"

    if (-not (Test-Path $ttPath)) {
        Add-CheckResult "ERROR" "TestStatusAggregation" "test-tracking.md" "File not found: $ttPath"
    } elseif (-not (Test-Path $ftPath)) {
        Add-CheckResult "ERROR" "TestStatusAggregation" "feature-tracking.md" "File not found: $ftPath"
    } else {
        # Valid feature-tracking.md Test Status legend values (SC-027 unified legend)
        $validStatuses = @(
            '⬜ No Tests',
            '🚫 No Test Required',
            '📋 Specs Created',
            '🟡 In Progress',
            '🔍 Audit In Progress',
            '🟡 Tests Partially Approved',
            '✅ All Passing',
            '🔴 Some Failing',
            '🔧 Automated Only',
            '🔄 Re-testing Needed'
        )

        # Normalize a status string by collapsing whitespace, for robust comparison
        function Get-NormalizedStatus {
            param([string]$Status)
            return ($Status -replace '\s+', ' ').Trim()
        }

        # Aggregate test-tracking statuses for one feature into a single
        # feature-tracking legend value (emits SC-027 vocabulary). Mirrors
        # Update-TestFileAuditState.ps1 with the 🔴 Needs Fix extension noted above.
        function Get-AggregatedTestStatus {
            param([string[]]$Statuses)
            if ($null -eq $Statuses -or $Statuses.Count -eq 0) { return "⬜ No Tests" }
            if (@($Statuses | Where-Object { $_ -match '🔴\s*(Audit\s*Failed|Needs\s*Fix)' }).Count -gt 0) { return "🔴 Some Failing" }
            if (@($Statuses | Where-Object { $_ -match '🔄\s*Needs\s*Update' }).Count -gt 0)               { return "🔄 Re-testing Needed" }
            if (@($Statuses | Where-Object { $_ -match '🔍\s*Audit\s*In\s*Progress' }).Count -gt 0)        { return "🔍 Audit In Progress" }
            $approved = @($Statuses | Where-Object { $_ -match '^✅\s*Audit\s*Approved' })
            if ($approved.Count -eq 0)                  { return "🟡 In Progress" }
            if ($approved.Count -eq $Statuses.Count)    { return "✅ All Passing" }
            return "🟡 Tests Partially Approved"
        }

        # --- Step 1: Build per-feature test-status map from test-tracking.md ---
        $testStatusByFeature = @{}
        $ttLines = Get-Content $ttPath -Encoding UTF8
        foreach ($line in $ttLines) {
            if ($line -notmatch '^\|') { continue }
            $cols = $line -split '\|' | ForEach-Object { $_.Trim() }
            # 8-col format: | "" | Feature ID | Test Type | Test File/Case | Status | Test Cases Count | Last Executed | Last Updated | Notes |
            if ($cols.Count -lt 6) { continue }
            $featureId = $cols[1]
            # Skip header, separator, and infrastructure rows (Feature ID = "—" or "Feature ID")
            if ($featureId -notmatch '^\d+\.\d+\.\d+$') { continue }
            $status = $cols[4]
            if (-not $testStatusByFeature.ContainsKey($featureId)) {
                $testStatusByFeature[$featureId] = @()
            }
            $testStatusByFeature[$featureId] += $status
        }

        # --- Step 2: Walk feature-tracking.md feature rows and compare ---
        $ftLines = Get-Content $ftPath -Encoding UTF8
        $checked = 0
        foreach ($line in $ftLines) {
            # Feature rows: | [X.X.X](path) | Feature | Status | Priority | Doc Tier | FDD | TDD | Test Status | Test Spec | Dependencies | Notes |
            if ($line -notmatch '^\|\s*\[\d+\.\d+\.\d+\]') { continue }
            $cols = $line -split '\|' | ForEach-Object { $_.Trim() }
            if ($cols.Count -lt 9) { continue }
            if ($cols[1] -notmatch '\[(\d+\.\d+\.\d+)\]') { continue }
            $featureId = $Matches[1]
            $actualStatus = $cols[8]
            # Skip archived rows (empty Test Status)
            if ([string]::IsNullOrWhiteSpace($actualStatus) -or $actualStatus -eq '—') { continue }

            $actualNorm = Get-NormalizedStatus $actualStatus

            # Skip manually-designated 🚫 No Test Required (exempt from aggregation check)
            if ($actualNorm -eq '🚫 No Test Required') {
                Add-CheckResult "OK" "TestStatusAggregation" $featureId "Manually marked 🚫 No Test Required (skipped)"
                continue
            }

            $featureStatuses = if ($testStatusByFeature.ContainsKey($featureId)) { $testStatusByFeature[$featureId] } else { @() }
            $expectedStatus = Get-AggregatedTestStatus -Statuses $featureStatuses
            $expectedNorm = Get-NormalizedStatus $expectedStatus

            $checked++

            # Unknown actual status is a warning (hand-typed value not in legend)
            if ($actualNorm -notin $validStatuses) {
                Add-CheckResult "WARNING" "TestStatusAggregation" $featureId "Test Status '$actualStatus' not in legend — review for typo or update SC-027 legend"
                continue
            }

            # 🔧 Automated Only actual is consistent with ✅ All Passing expected (manual flag intent)
            if ($actualNorm -eq '🔧 Automated Only' -and $expectedNorm -eq '✅ All Passing') {
                Add-CheckResult "OK" "TestStatusAggregation" $featureId "🔧 Automated Only consistent with all-passing aggregate"
                continue
            }

            # Orphan claim: feature claims ✅ All Passing but no test-tracking rows exist
            if ($actualNorm -eq '✅ All Passing' -and $featureStatuses.Count -eq 0) {
                Add-CheckResult "ERROR" "TestStatusAggregation" $featureId "Feature claims '$actualStatus' but test-tracking.md has no entries for this feature"
                continue
            }

            if ($actualNorm -ne $expectedNorm) {
                $statusSummary = if ($featureStatuses.Count -gt 0) {
                    ($featureStatuses | Group-Object | ForEach-Object { "$($_.Name) (x$($_.Count))" }) -join ", "
                } else { "no test entries" }
                Add-CheckResult "ERROR" "TestStatusAggregation" $featureId "Mismatch — feature-tracking shows '$actualStatus' but test-tracking aggregates to '$expectedStatus'. Underlying: $statusSummary"
            } else {
                Add-CheckResult "OK" "TestStatusAggregation" $featureId "Test status consistent ($actualNorm)"
            }
        }

        Write-Host "  Checked $checked feature(s)" -ForegroundColor Gray
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
