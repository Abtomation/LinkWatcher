#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Master state validation script — validates that state tracking entries match actual files on disk.
.DESCRIPTION
    Checks consistency across 19 validation surfaces:
    1. ../feature-tracking.md — all document links (FDD, TDD, Test Spec, Assessment, State File)
    2. Feature implementation state files — link checks in the Documentation Inventory, Code Inventory, and Dependencies sections (matched by title, so both the full and lightweight/Tier 1 templates' section numbering work)
    3. ../test-tracking.md — test file path references
    4. Cross-reference consistency — feature IDs in test-registry.yaml vs feature-tracking.md
    5. ID counter health — nextAvailable counters vs actual max IDs
    6. Feature Dependencies — regenerate feature-dependencies.md if stale
    7. Dimension Consistency — dimension profile presence and valid abbreviations (Tier 1 lightweight files skipped — they have no Dimension Profile by design)
    8. Workflow Tracking — workflow-feature mapping consistency and status accuracy
    9. Task Registry — all PF-TSK IDs present in process-framework-task-registry.md
    10. Metadata Schema — YAML frontmatter conformance against domain-config.json schemas
    11. Context Map Orphans — cross-reference context map related_task metadata against actual task files
    12. AI Tasks Consistency — detect task files in tasks/ directories but missing from ai-tasks.md
    13. Master State Consistency — phase checkboxes, progress counters, and doc summary vs Feature Inventory
    14. Source Layout — compare source-code-layout.md directory tree against actual source directories
    15. Test Status Aggregation — cross-check feature-tracking Test Status against aggregated test-tracking statuses (PF-IMP-573)
    16. Audit Mirror Invariant — every test dir has a corresponding audit dir under the Phase 3a path-transform rule (PF-IMP-871 Phase 4a)
    17. Category Alignment — feature-tracking.md categories/subgroups vs `test/automated/unit/<N>-<slug>/` dirs (PF-IMP-871 Phase 4a)
    18. Workflow Alignment — user-workflow-tracking.md WF-NNN rows vs `test/e2e-acceptance-testing/<slug>/templates/` dirs (PF-IMP-871 Phase 4a)
    19. Variant Pair Consistency — per-file frontmatter variant_group/variant_siblings symmetry and sibling existence (PF-IMP-837)

    Created as IMP-028 from Tools Review 2026-02-21.
.PARAMETER ProjectRoot
    Path to the project root directory. Defaults to auto-detection from script location.
.PARAMETER Surface
    Which validation surfaces to run. Accepts one or more of:
    "FeatureTracking", "StateFiles", "TestTracking", "CrossRef", "IdCounters", "FeatureDeps", "DimensionConsistency", "WorkflowTracking", "TaskRegistry", "MetadataSchema", "ContextMapOrphans", "AiTasksConsistency", "MasterStateConsistency", "SourceLayout", "TestStatusAggregation", "AuditMirror", "CategoryAlignment", "WorkflowAlignment", "VariantPairConsistency", "All"
    Default: "All"
.PARAMETER Detailed
    Show every checked link, not just failures. Also reveals schema-detail-only warnings
    (e.g., "Unknown field" findings in Surface 10) that are suppressed by default because
    they reflect schema-template drift rather than actionable issues.
    See process-framework/guides/support/schema-audit-procedure-guide.md for the
    reconciliation workflow that consumes -Detailed Surface 10 output.
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

# --- Locate + import Common-ScriptHelpers umbrella ---
# Imported unconditionally because surfaces 16/17/18 (PF-IMP-871 Phase 4a) consume
# Naming module functions (New-FeatureDirSlug, ConvertTo-FeatureSlug). Prior to
# Phase 4a, the import was conditional on $ProjectRoot being blank — callers passing
# -ProjectRoot explicitly silently skipped module load and got empty results from
# the new surfaces (no error, just zero expected entries → spurious orphan warnings).
$helperDir = $PSScriptRoot
while ($helperDir -and !(Test-Path (Join-Path $helperDir "Common-ScriptHelpers.psm1"))) {
    $helperDir = Split-Path -Parent $helperDir
}
if ($helperDir) {
    Import-Module (Join-Path $helperDir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
}

# --- Resolve project root (auto-detect when not supplied) ---
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Get-ProjectRoot
}

# --- Globals ---
$totalChecks = 0
$errorCount = 0
$warningCount = 0
$passCount = 0
$detailOnlyHiddenCount = 0  # Warnings counted but display-suppressed unless -Detailed

# Normalize -Surface: split any comma-joined elements into separate items, trim, drop empties.
# Handles `pwsh.exe -File -Surface a,b,c` invocation where PowerShell passes the comma-joined
# value as a single string rather than an array — without this, $Surface -contains "X" returns
# false for every X, total checks = 0, and the script silently exits 0 with "All checks passed!"
# (a CI false positive). The "no surfaces matched" guard below also catches typos / unknown names.
$Surface = @($Surface | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })

$runAll = $Surface -contains "All"

# --- Load language config for test file extension ---
$projectConfigPath = Join-Path $ProjectRoot "doc/project-config.json"
$testFileExtRegex = '\.py$'  # fallback
if (Test-Path $projectConfigPath) {
    try {
        $projCfg = Get-Content $projectConfigPath -Raw | ConvertFrom-Json
        $lang = $projCfg.project_metadata.primary_language.ToLower()
        $langCfgPath = Join-Path (Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot) "languages-config/$lang/$lang-config.json"
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

    # Project-root-relative paths use a single leading '/' or '\' (not UNC '//' or '\\').
    # Convention is used in feature-tracking.md, state files, README.md, CLAUDE.md, and
    # is honored by LinkWatcher + VS Code. On Windows, Join-Path treats '/foo' as
    # drive-rooted (C:\foo), so anchor to $script:ProjectRoot explicitly. (PF-IMP-764)
    if ($cleanPath -match '^[/\\][^/\\]') {
        $combined = Join-Path $script:ProjectRoot ($cleanPath.Substring(1))
    } else {
        $combined = Join-Path $SourceFileDir $cleanPath
    }
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
        # CommonMark allows <URL> wrapping for URLs containing spaces; strip the brackets.
        $path = $m.Groups[2].Value
        if ($path.StartsWith('<') -and $path.EndsWith('>')) {
            $path = $path.Substring(1, $path.Length - 2)
        }
        $links += [PSCustomObject]@{
            Text = $m.Groups[1].Value
            Path = $path
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
# -DetailOnly: For WARNING level, count toward warningCount but suppress display unless -Detailed is set.
# Used for warning classes that reflect schema/data drift rather than actionable issues, where the
# default-mode display-noise drowns real signal. The summary still reports the count and notes how
# many were hidden, so the noise is acknowledged rather than silently discarded.
function Add-CheckResult {
    param(
        [string]$Level,  # "ERROR", "WARNING", "OK"
        [string]$Surface,
        [string]$Context,
        [string]$Message,
        [switch]$DetailOnly
    )

    $script:totalChecks++
    switch ($Level) {
        "ERROR"   { $script:errorCount++; Write-Host "    $([char]0x274C) $Context : $Message" -ForegroundColor Red }
        "WARNING" {
            $script:warningCount++
            if ($DetailOnly -and -not $Detailed) {
                $script:detailOnlyHiddenCount++
            } else {
                Write-Host "    $([char]0x26A0)  $Context : $Message" -ForegroundColor Yellow
            }
        }
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
                # Track which section we're in. Match by section TITLE, not number, so the
                # lightweight (Tier 1) template's shifted numbering — Documentation Inventory §3,
                # Code Inventory §4, Dependencies §5 — is handled identically to the full
                # template's §4/§5/§6. Keying on numbers made Tier 1 files match no section and
                # emit a false "No links found" warning (PF-IMP-954).
                if ($line -match '^## \d+\. Documentation Inventory') { $inSection = "DocInventory" }
                elseif ($line -match '^## \d+\. Code Inventory') { $inSection = "CodeInventory" }
                elseif ($line -match '^## \d+\. Dependencies') { $inSection = "Dependencies" }
                elseif ($line -match '^## \d') { $inSection = "" }

                # Only validate links in the three link-bearing inventory sections
                if ($inSection -notin @("DocInventory", "CodeInventory", "Dependencies")) { continue }

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
                Write-Host "    $([char]0x26A0)  $sfName : No links found in the Documentation/Code/Dependencies inventory sections" -ForegroundColor Yellow
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
        'PF' = @{ Path = (Join-Path (Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot) "PF-id-registry.json"); Registry = $null; Fixed = 0 }
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
            @{ Prefix = "PD-ADR";  Dir = "doc/technical/adr";                                          Pattern = "*.md"; Domain = "PD" }
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
    $updateScript = Join-Path (Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot) "scripts/update/Update-FeatureDependencies.ps1"

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
        $filesSkippedLightweight = 0

        foreach ($file in $stateFiles) {
            $content = Get-Content $file.FullName -Raw

            # Tier 1 (lightweight) state files have no Dimension Profile section by design —
            # their §7 is Quality Assessment. Skip them; flagging would be a false positive
            # (PF-IMP-954). The lightweight header marker is the discriminator, so a genuinely
            # incomplete full file (missing its profile) is still caught below.
            if ($content -match '\*\*Lightweight variant\*\*') {
                $filesSkippedLightweight++
                continue
            }

            # Check if Dimension Profile section exists
            if ($content -match "## \d+\. Dimension Profile") {
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

        Write-Host "  Feature state files: $($stateFiles.Count) total, $filesWithProfile with profiles, $filesWithoutProfile without, $filesSkippedLightweight Tier 1 (skipped)" -ForegroundColor Gray
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

    $fwDir = Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot
    $registryPath = Join-Path $fwDir "infrastructure/process-framework-task-registry.md"
    $pfIdRegistryPath = Join-Path $fwDir "PF-id-registry.json"

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
        $idMatches = [regex]::Matches($registryContent, 'PF-TSK-\d+')
        foreach ($m in $idMatches) {
            if ($registryTaskIds -notcontains $m.Value) {
                $registryTaskIds += $m.Value
            }
        }

        # Also get task IDs that actually have files on disk (to avoid flagging deleted tasks)
        $taskDir = Join-Path $fwDir "tasks"
        $taskFiles = Get-ChildItem -Path $taskDir -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue
        $taskFileIds = @()
        foreach ($tf in $taskFiles) {
            $firstLines = Get-Content $tf.FullName -TotalCount 10 -Encoding UTF8 -ErrorAction SilentlyContinue
            foreach ($line in $firstLines) {
                if ($line -match '^id:\s*(PF-TSK-\d+)') {
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

    $domainCfgPath = Join-Path (Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot) "domain-config.json"
    if (-not (Test-Path $domainCfgPath)) {
        Add-CheckResult "WARNING" "MetadataSchema" "domain-config.json" "File not found — metadata schema validation skipped"
    } else {
        $domainCfg = Get-Content $domainCfgPath -Raw | ConvertFrom-Json
        $schemas = $domainCfg.artifact_metadata_schemas

        if (-not $schemas) {
            Add-CheckResult "WARNING" "MetadataSchema" "domain-config.json" "No artifact_metadata_schemas section found"
        } else {
            # Map artifact types to directory globs (relative to the process-framework root)
            $artifactDirs = @{
                "task"        = @{ dir = "tasks"; recurse = $true }
                "template"    = @{ dir = "templates"; recurse = $true }
                "guide"       = @{ dir = "guides"; recurse = $true }
                "context_map" = @{ dir = "visualization/context-maps"; recurse = $true }
            }

            $totalFiles = 0
            $conformingFiles = 0
            $violationFiles = 0
            $fwDirMS = Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot

            foreach ($artifactType in $artifactDirs.Keys) {
                $schema = $schemas.$artifactType
                if (-not $schema) {
                    Add-CheckResult "WARNING" "MetadataSchema" $artifactType "No schema defined in domain-config.json"
                    continue
                }

                $searchDir = Join-Path $fwDirMS $artifactDirs[$artifactType].dir
                if (-not (Test-Path $searchDir)) { continue }

                $mdFiles = Get-ChildItem -Path $searchDir -Filter "*.md" -Recurse -File | Where-Object {
                    # Exclude README files — they are not artifacts with standard metadata.
                    # Exclude *-path.md sub-path elaboration docs — they are subordinate to a
                    # parent task (e.g., code-refactoring-{lightweight,standard}-path.md under
                    # PF-TSK-022) and inherit its frontmatter; giving them their own id: would
                    # falsely catalogue them as standalone tasks. See PF-IMP-005.
                    $_.Name -ne "README.md" -and $_.Name -notlike "*-path.md"
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

                    # Check for unknown fields (not in required or optional).
                    # Marked -DetailOnly: in default mode this class is dominated by legitimate
                    # template-subtype fields (schema-template drift) rather than typos. Surfaced
                    # via -Detailed for targeted schema audits. See PF-IMP-646.
                    # Reconciliation procedure: process-framework/guides/support/schema-audit-procedure-guide.md (PF-IMP-690).
                    $knownFields = @($schema.required) + @($schema.optional)
                    foreach ($fieldName in $fields.Keys) {
                        if ($fieldName -notin $knownFields) {
                            Add-CheckResult "WARNING" "MetadataSchema" $relPath "Unknown field: $fieldName (not in schema for $artifactType)" -DetailOnly
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

    $fwDirCM = Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot
    $cmDir = Join-Path $fwDirCM "visualization/context-maps"
    if (-not (Test-Path $cmDir)) {
        Add-CheckResult "WARNING" "ContextMapOrphans" "context-maps/" "Directory not found — skipped"
    } else {
        # Build a lookup of all task IDs from task files
        $taskDir = Join-Path $fwDirCM "tasks"
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

    $fwDirAT = Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot
    $aiTasksPath = Join-Path $fwDirAT "ai-tasks.md"
    $taskDir = Join-Path $fwDirAT "tasks"

    if (-not (Test-Path $aiTasksPath)) {
        Add-CheckResult "WARNING" "AiTasksConsistency" "ai-tasks.md" "File not found — skipped"
    } elseif (-not (Test-Path $taskDir)) {
        Add-CheckResult "WARNING" "AiTasksConsistency" "tasks/" "Directory not found — skipped"
    } else {
        $aiTasksContent = Get-Content $aiTasksPath -Raw -Encoding UTF8

        # Collect all task IDs from task files on disk.
        # For each file, scan the YAML frontmatter for `id:` AND `status:` so we can
        # later distinguish active tasks from deprecated ones (`status: deprecated`).
        # Deprecated task files are EXPECTED to be absent from ai-tasks.md selection
        # trees — without this carve-out, every formally deprecated task would
        # permanently surface as a Surface 12 error.
        $taskFiles = Get-ChildItem -Path $taskDir -Filter "*.md" -Recurse -File | Where-Object { $_.Name -ne "README.md" }
        $diskTasks = @{}
        foreach ($tf in $taskFiles) {
            $firstLines = Get-Content $tf.FullName -TotalCount 20 -Encoding UTF8 -ErrorAction SilentlyContinue
            $taskId = $null
            $taskStatus = $null
            foreach ($line in $firstLines) {
                if ($line -match '^id:\s*(PF-TSK-\d+)') {
                    $taskId = $matches[1]
                } elseif ($line -match '^status:\s*(\S+)') {
                    $taskStatus = $matches[1].ToLower()
                } elseif ($line -match '^---\s*$' -and $taskId) {
                    # Closing frontmatter delimiter — id has been seen, stop scanning.
                    break
                }
            }
            if ($taskId) {
                $relPath = $tf.FullName.Substring($ProjectRoot.Length + 1) -replace '\\', '/'
                $diskTasks[$taskId] = [PSCustomObject]@{
                    Path   = $relPath
                    Status = $taskStatus
                }
            }
        }

        # Check which task files are referenced in ai-tasks.md
        $missingCount = 0
        $deprecatedCount = 0
        foreach ($entry in $diskTasks.GetEnumerator() | Sort-Object Key) {
            $taskId = $entry.Key
            $taskInfo = $entry.Value
            $taskFile = $taskInfo.Path
            $taskStatus = $taskInfo.Status
            # Extract just the filename to check for references (ai-tasks.md uses relative links to task files)
            $fileName = [System.IO.Path]::GetFileName($taskFile)
            $isReferenced = ($aiTasksContent -match [regex]::Escape($fileName)) -or ($aiTasksContent -match [regex]::Escape($taskId))

            if ($taskStatus -eq 'deprecated') {
                # Deprecated tasks should be absent from ai-tasks.md selection. Presence is
                # allowed (with strikethrough/deprecation marker), but absence is the
                # canonical state — record as OK either way.
                if ($isReferenced) {
                    Add-CheckResult "OK" "AiTasksConsistency" $taskId "Deprecated — still referenced in ai-tasks.md ($fileName); consider removing"
                } else {
                    Add-CheckResult "OK" "AiTasksConsistency" $taskId "Deprecated — correctly absent from ai-tasks.md ($fileName)"
                }
                $deprecatedCount++
            } elseif ($isReferenced) {
                Add-CheckResult "OK" "AiTasksConsistency" $taskId "Referenced in ai-tasks.md ($fileName)"
            } else {
                Add-CheckResult "ERROR" "AiTasksConsistency" $taskId "Task file exists ($taskFile) but not referenced in ai-tasks.md"
                $missingCount++
            }
        }

        $activeCount = $diskTasks.Count - $deprecatedCount
        Write-Host "  Task files on disk: $($diskTasks.Count) ($activeCount active, $deprecatedCount deprecated), Missing from ai-tasks.md: $missingCount" -ForegroundColor Gray
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
                        $lcPath = Join-Path (Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot) "languages-config/$lang/$lang-config.json"
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
# Mirrors aggregation logic from Update-TestFileAuditState.ps1 (~lines 595-612).
# 🔴 Needs Fix rows in test-tracking (emitted by Run-Tests.python.ps1 when pytest
# reports failures/errors — distinct from this aggregator's own "🔴 Audit Failed"
# rows) also aggregate to "🔴 Some Failing"; PF-IMP-765 aligned the updater to
# treat both as failing too.
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

        # Extract the leading symbol token (everything up to first whitespace).
        # Cells often contain just the emoji (e.g. '⬜') rather than the full
        # canonical form ('⬜ No Tests') because the legend table renders symbol
        # and status name in separate columns. PF-IMP-038.
        function Get-StatusSymbol {
            param([string]$Status)
            $norm = Get-NormalizedStatus $Status
            if ($norm -match '^(\S+)') { return $Matches[1] }
            return $norm
        }

        # Status equality that tolerates bare-symbol cells. Full-text on both
        # sides → strict comparison (preserves PF-IMP-037-style detection of
        # 🟡 In Progress vs 🟡 Tests Partially Approved). If either side is a
        # bare symbol → compare on symbol only.
        function Test-StatusMatch {
            param([string]$Actual, [string]$Expected)
            $a = Get-NormalizedStatus $Actual
            $e = Get-NormalizedStatus $Expected
            if ($a -eq $e) { return $true }
            $aSym = Get-StatusSymbol $a
            $eSym = Get-StatusSymbol $e
            if ($a -eq $aSym -or $e -eq $eSym) { return $aSym -eq $eSym }
            return $false
        }

        $validSymbols = @($validStatuses | ForEach-Object { Get-StatusSymbol $_ } | Select-Object -Unique)

        # Aggregate test-tracking statuses for one feature into a single
        # feature-tracking legend value (emits SC-027 vocabulary). Mirrors
        # Update-TestFileAuditState.ps1 with the 🔴 Needs Fix extension noted above.
        function Get-AggregatedTestStatus {
            param([string[]]$Statuses)
            if ($null -eq $Statuses -or $Statuses.Count -eq 0) { return "⬜ No Tests" }
            if (@($Statuses | Where-Object { $_ -match '🔴\s*(Audit\s*Failed|Needs\s*Fix)' }).Count -gt 0) { return "🔴 Some Failing" }
            if (@($Statuses | Where-Object { $_ -match '🔄\s*Needs\s*Update' }).Count -gt 0)               { return "🔄 Re-testing Needed" }
            if (@($Statuses | Where-Object { $_ -match '🔍\s*Audit\s*In\s*Progress' }).Count -gt 0)        { return "🔍 Audit In Progress" }
            # All entries are 📝 Needs Implementation (specs created, no impl started) → 📋 Specs Created.
            # PF-IMP-037: test-tracking 📝 Needs Implementation == feature-tracking 📋 Specs Created semantically.
            $needsImpl = @($Statuses | Where-Object { $_ -match '📝\s*Needs\s*Implementation' })
            if ($needsImpl.Count -eq $Statuses.Count) { return "📋 Specs Created" }
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
        # Test Status column index is resolved by HEADER NAME, not hardcoded
        # position — schema-resilient against PF-PRO-002 column drops (the
        # post-Phase-3 schema is 8 cols; pre-Phase-3 was 11). The most recent
        # header row above each data row defines the column map for that row.
        $ftLines = Get-Content $ftPath -Encoding UTF8
        $checked = 0
        $testStatusIdx = -1
        foreach ($line in $ftLines) {
            # Update the Test Status column index whenever we hit a category-table
            # header row. Header pattern: "| ID | Feature | Status | ... |"
            if ($line -match '^\|\s*ID\s*\|') {
                $headerCols = $line -split '\|' | ForEach-Object { $_.Trim() }
                $testStatusIdx = -1
                for ($k = 0; $k -lt $headerCols.Count; $k++) {
                    if ($headerCols[$k] -eq 'Test Status') { $testStatusIdx = $k; break }
                }
                continue
            }
            # Feature rows: | [X.X.X](path) | Feature | Status | Priority | Doc Tier | Test Status | Dependencies | Notes |
            # (post-Phase-3 schema; was 11 cols pre-Phase-3 with FDD/TDD/Test Spec inserted)
            if ($line -notmatch '^\|\s*\[\d+\.\d+\.\d+\]') { continue }
            $cols = $line -split '\|' | ForEach-Object { $_.Trim() }
            # Skip rows where we haven't yet seen a header (defensive)
            if ($testStatusIdx -lt 0) { continue }
            if ($cols.Count -le $testStatusIdx) { continue }
            if ($cols[1] -notmatch '\[(\d+\.\d+\.\d+)\]') { continue }
            $featureId = $Matches[1]
            $actualStatus = $cols[$testStatusIdx]
            # Skip archived rows (empty Test Status)
            if ([string]::IsNullOrWhiteSpace($actualStatus) -or $actualStatus -eq '—') { continue }

            $actualNorm = Get-NormalizedStatus $actualStatus
            $actualSymbol = Get-StatusSymbol $actualNorm

            # Skip manually-designated 🚫 No Test Required (exempt from aggregation check)
            if (Test-StatusMatch $actualNorm '🚫 No Test Required') {
                Add-CheckResult "OK" "TestStatusAggregation" $featureId "Manually marked 🚫 No Test Required (skipped)"
                continue
            }

            $featureStatuses = if ($testStatusByFeature.ContainsKey($featureId)) { $testStatusByFeature[$featureId] } else { @() }
            $expectedStatus = Get-AggregatedTestStatus -Statuses $featureStatuses
            $expectedNorm = Get-NormalizedStatus $expectedStatus

            $checked++

            # Unknown actual status is a warning (hand-typed value not in legend).
            # Accept either the canonical full form ('⬜ No Tests') or the bare
            # symbol ('⬜') since cells in feature-tracking.md commonly use either.
            if ($actualNorm -notin $validStatuses -and $actualSymbol -notin $validSymbols) {
                Add-CheckResult "WARNING" "TestStatusAggregation" $featureId "Test Status '$actualStatus' not in legend — review for typo or update SC-027 legend"
                continue
            }

            # 🔧 Automated Only actual is consistent with ✅ All Passing expected (manual flag intent)
            if ((Test-StatusMatch $actualNorm '🔧 Automated Only') -and (Test-StatusMatch $expectedNorm '✅ All Passing')) {
                Add-CheckResult "OK" "TestStatusAggregation" $featureId "🔧 Automated Only consistent with all-passing aggregate"
                continue
            }

            # Orphan claim: feature claims ✅ All Passing but no test-tracking rows exist
            if ((Test-StatusMatch $actualNorm '✅ All Passing') -and $featureStatuses.Count -eq 0) {
                Add-CheckResult "ERROR" "TestStatusAggregation" $featureId "Feature claims '$actualStatus' but test-tracking.md has no entries for this feature"
                continue
            }

            if (-not (Test-StatusMatch $actualNorm $expectedNorm)) {
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
# Surfaces 16/17/18 — Test & Audit Infrastructure Invariants (PF-IMP-871 Phase 4a)
# =========================================================================
# Three related surfaces that enforce the test/audit tree's structural contract:
#
#   - Surface 16 (AuditMirror)       : every test dir has a corresponding audit dir
#                                      (and vice versa) under the path-transform rule
#                                      established in PF-IMP-871 Phase 3a.
#   - Surface 17 (CategoryAlignment) : every level-1 category and level-2 subgroup in
#                                      feature-tracking.md has a matching unit-test
#                                      dir under `test/automated/unit/`.
#   - Surface 18 (WorkflowAlignment) : every WF-NNN row in user-workflow-tracking.md
#                                      has a matching e2e dir under
#                                      `test/e2e-acceptance-testing/`.
#
# All three share the same project_id-aware test-root resolution (PRJ-000 → blueprint/
# test/; otherwise → test/) and the same feature-tracking / workflow-tracking parsers
# (defined inline below; logic adapted from New-TestInfrastructure.ps1 Phase 3a/3c1).
# =========================================================================

# --- Shared helper: resolve test_root and tracking-file paths from project-config.json ---
function Get-TestAuditContext {
    param([string]$ProjectRoot)

    $projectConfigPath = Join-Path $ProjectRoot "doc/project-config.json"
    $projectId = ""
    $testsRel  = "test"
    $docRel    = "doc"
    if (Test-Path $projectConfigPath) {
        try {
            $cfg = Get-Content $projectConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json
            if ($cfg.PSObject.Properties.Name -contains 'project_id') {
                $projectId = $cfg.project_id
            }
            if ($cfg.paths) {
                if ($cfg.paths.tests)              { $testsRel = $cfg.paths.tests }
                if ($cfg.paths.documentation_root) { $docRel   = $cfg.paths.documentation_root }
            }
        } catch {
            Write-Verbose "Could not parse project-config.json: $($_.Exception.Message)"
        }
    }

    # Refactored 2026-05-17 (Framework Self-Testing PF-PRO-035, Phase 3a-continuation) — replaced
    # PRJ-000 → blueprint/* hardcoding with config-driven lookup (paths.tests + paths.documentation_root).
    # See Resolve-DocPath in Common-ScriptHelpers/Core.psm1 for the parallel refactor.
    $testRoot = Join-Path $ProjectRoot $testsRel
    $ftPath   = Join-Path $ProjectRoot (Join-Path $docRel "state-tracking/permanent/feature-tracking.md")
    $wfPath   = Join-Path $ProjectRoot (Join-Path $docRel "state-tracking/permanent/user-workflow-tracking.md")

    return [PSCustomObject]@{
        ProjectId            = $projectId
        TestRoot             = $testRoot
        FeatureTrackingPath  = $ftPath
        WorkflowTrackingPath = $wfPath
    }
}

# --- Shared parser: feature-tracking.md categories (adapted from New-TestInfrastructure.ps1 Phase 3a) ---
function Get-ParsedFeatureCategories {
    param([string]$Path)
    if ([string]::IsNullOrEmpty($Path) -or -not (Test-Path $Path)) { return @() }
    $content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content)) { return @() }
    $lines = $content -split "`r?`n"

    $startIdx = -1; $endIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## Feature Categories\s*$') { $startIdx = $i }
        elseif ($lines[$i] -match '^## Archived Features\s*$' -and $startIdx -ge 0) { $endIdx = $i; break }
    }
    if ($startIdx -lt 0) { return @() }
    if ($endIdx -lt 0) { $endIdx = $lines.Count }

    $results = @(); $inCategory = $false; $currentCatId = $null
    for ($i = $startIdx; $i -lt $endIdx; $i++) {
        $line = $lines[$i]
        if (-not $inCategory) {
            if ($line -match '^<details>\s*$') {
                $nextLine = if ($i + 1 -lt $lines.Count) { $lines[$i + 1] } else { '' }
                if ($nextLine -match '^<summary><strong>(\d+)\.\s+(.+?)</strong></summary>\s*$') {
                    $currentCatId = $matches[1]
                    $results += [PSCustomObject]@{ Id = $currentCatId; Name = $matches[2]; Level = 1; ParentId = "" }
                    $inCategory = $true
                }
            }
        } else {
            if ($line -match '^</details>\s*$') {
                $inCategory = $false; $currentCatId = $null
            } elseif ($line -match '^### (\d+)\.(\d+)\s+(.+?)\s*$') {
                if ($matches[1] -eq $currentCatId) {
                    $results += [PSCustomObject]@{
                        Id = "$($matches[1]).$($matches[2])"; Name = $matches[3]; Level = 2; ParentId = $currentCatId
                    }
                }
            }
        }
    }
    return $results
}

# --- Shared parser: user-workflow-tracking.md WF-NNN rows (adapted from New-TestInfrastructure.ps1 Phase 3c1) ---
function Get-ParsedWorkflows {
    param([string]$Path)
    if ([string]::IsNullOrEmpty($Path) -or -not (Test-Path $Path)) { return @() }
    $content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content)) { return @() }
    $lines = $content -split "`r?`n"

    $startIdx = -1; $endIdx = $lines.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## Workflows\s*$') { $startIdx = $i }
        elseif ($startIdx -ge 0 -and $lines[$i] -match '^## ' -and $lines[$i] -notmatch '^## Workflows\s*$') {
            $endIdx = $i; break
        }
    }
    if ($startIdx -lt 0) { return @() }

    $results = @()
    for ($i = $startIdx; $i -lt $endIdx; $i++) {
        if ($lines[$i] -match '^\|\s*(WF-\d+)\s*\|\s*(.+?)\s*\|') {
            $results += [PSCustomObject]@{ Id = $matches[1]; Name = $matches[2] }
        }
    }
    return $results
}

# =========================================================================
# Surface 16: Audit Mirror Invariant
# =========================================================================
# Enforces the path-transform rule from PF-IMP-871 Phase 3a:
#   - test/automated/<path>/                            ↔ test/audits/<path>/
#   - test/e2e-acceptance-testing/<workflow>/templates/ ↔ test/audits/e2e/<workflow>/
# `bug-validation/` is explicitly exempt (no audit mirror by design — manual
# reproduction harnesses, not part of the auditable test suite).
# =========================================================================
if ($runAll -or $Surface -contains "AuditMirror") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 16: Audit Mirror Invariant" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $ctx = Get-TestAuditContext -ProjectRoot $ProjectRoot
    $testRoot = $ctx.TestRoot
    $automatedRoot = Join-Path $testRoot "automated"
    $auditsRoot    = Join-Path $testRoot "audits"
    $e2eRoot       = Join-Path $testRoot "e2e-acceptance-testing"

    if (-not (Test-Path $testRoot)) {
        Add-CheckResult "WARNING" "AuditMirror" "TestRoot" "Test root not found at $testRoot — skipping"
    } else {
        $checked = 0; $issues = 0

        # Runtime/cache artifact dirs (pytest __pycache__, VCS/dependency/venv dirs) are not
        # part of the auditable test tree — skip them in the recursive walks below so they
        # don't read as "missing audit mirror" (16a) or orphan/unknown-subtree dirs (16c).
        # Mirrors the Surface 14 source-dir filter (PF-IMP-956).
        $runtimeCacheDirs = @('__pycache__', '.git', 'node_modules', '.venv', 'venv')

        # --- 16a: automated/ ↔ audits/ subtree (every automated dir has an audit mirror) ---
        if (Test-Path $automatedRoot) {
            $autoSubdirs = Get-ChildItem -Path $automatedRoot -Directory -Recurse -ErrorAction SilentlyContinue
            foreach ($d in $autoSubdirs) {
                $rel = $d.FullName.Substring($automatedRoot.Length).TrimStart('\','/')
                # Skip runtime/cache artifact dirs anywhere in the path (PF-IMP-956)
                if (($rel -split '[\\/]').Where({ $runtimeCacheDirs -contains $_ }).Count -gt 0) { continue }
                # Skip bug-validation tree if it accidentally still exists under automated/
                # (Phase 3d moved it to test/ top-level; presence here would be stale)
                if ($rel -match '^bug-validation([\\/]|$)') { continue }
                $expectedAuditDir = Join-Path (Join-Path $auditsRoot "") $rel
                $checked++
                if (-not (Test-Path $expectedAuditDir)) {
                    $issues++
                    Add-CheckResult "ERROR" "AuditMirror" "automated/$rel" "Missing audit mirror at audits/$rel"
                } else {
                    Add-CheckResult "OK" "AuditMirror" "automated/$rel" "Audit mirror present"
                }
            }
        }

        # --- 16b: e2e-acceptance-testing/<wf>/templates/ ↔ audits/e2e/<wf>/ ---
        if (Test-Path $e2eRoot) {
            $wfDirs = Get-ChildItem -Path $e2eRoot -Directory -ErrorAction SilentlyContinue
            foreach ($wf in $wfDirs) {
                $tmpl = Join-Path $wf.FullName "templates"
                if (-not (Test-Path $tmpl)) { continue }
                $expectedAuditDir = Join-Path (Join-Path $auditsRoot "e2e") $wf.Name
                $checked++
                if (-not (Test-Path $expectedAuditDir)) {
                    $issues++
                    Add-CheckResult "ERROR" "AuditMirror" "e2e-acceptance-testing/$($wf.Name)" "Missing audit mirror at audits/e2e/$($wf.Name)"
                } else {
                    Add-CheckResult "OK" "AuditMirror" "e2e-acceptance-testing/$($wf.Name)" "Audit mirror present"
                }
            }
        }

        # --- 16c: reverse — every audits/ subtree dir traces back to a source dir ---
        # Catches orphan audit dirs left behind after a feature/workflow is renamed/removed.
        if (Test-Path $auditsRoot) {
            $auditSubdirs = Get-ChildItem -Path $auditsRoot -Directory -Recurse -ErrorAction SilentlyContinue
            foreach ($d in $auditSubdirs) {
                $rel = $d.FullName.Substring($auditsRoot.Length).TrimStart('\','/')
                # Skip runtime/cache artifact dirs anywhere in the path (PF-IMP-956)
                if (($rel -split '[\\/]').Where({ $runtimeCacheDirs -contains $_ }).Count -gt 0) { continue }

                # Determine expected source location based on top-level audit subtree
                $topSegment = ($rel -split '[\\/]', 2)[0]
                $rest = if ($rel -match '[\\/]') { ($rel -split '[\\/]', 2)[1] } else { "" }

                $expectedSource = $null
                switch ($topSegment) {
                    'unit'        { $expectedSource = Join-Path (Join-Path $automatedRoot "unit") $rest }
                    'performance' { $expectedSource = Join-Path (Join-Path $automatedRoot "performance") $rest }
                    'e2e' {
                        # audits/e2e/<wf>/ traces back to e2e-acceptance-testing/<wf>/templates/
                        # Only check at depth 1; deeper levels (audit reports per test case) are fine.
                        if ($rest -and -not ($rest -match '[\\/]')) {
                            $expectedSource = Join-Path (Join-Path $e2eRoot $rest) "templates"
                        }
                    }
                    default {
                        # Unknown top-level audit subtree (e.g., legacy foundation/authentication/core-features)
                        # → warn, don't error: useful early-warning for stale leftovers.
                        $checked++
                        Add-CheckResult "WARNING" "AuditMirror" "audits/$rel" "Audit dir under unknown top-level subtree '$topSegment' (expected: unit/performance/e2e)"
                        continue
                    }
                }

                if ($null -ne $expectedSource) {
                    $checked++
                    if (-not (Test-Path $expectedSource)) {
                        $issues++
                        $expectedRel = $expectedSource.Substring($testRoot.Length).TrimStart('\','/')
                        Add-CheckResult "ERROR" "AuditMirror" "audits/$rel" "Orphan audit dir — no source at $expectedRel"
                    } else {
                        Add-CheckResult "OK" "AuditMirror" "audits/$rel" "Source dir present"
                    }
                }
            }
        }

        Write-Host "  Checked $checked mirror pair(s), $issues issue(s)" -ForegroundColor Gray
    }
    Write-Host ""
}

# =========================================================================
# Surface 17: Category Alignment
# =========================================================================
# Enforces alignment between feature-tracking.md feature-category structure
# and the on-disk `test/automated/unit/<N>-<slug>/[<N.X>-<slug>/]` layout
# scaffolded by New-TestInfrastructure.ps1 -Update Section A (Phase 3a).
# =========================================================================
if ($runAll -or $Surface -contains "CategoryAlignment") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 17: Category Alignment" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $ctx = Get-TestAuditContext -ProjectRoot $ProjectRoot
    $unitRoot = Join-Path $ctx.TestRoot "automated/unit"

    if (-not (Test-Path $ctx.FeatureTrackingPath)) {
        Add-CheckResult "WARNING" "CategoryAlignment" "FeatureTracking" "feature-tracking.md not found at $($ctx.FeatureTrackingPath) — skipping"
    } elseif (-not (Test-Path $unitRoot)) {
        Add-CheckResult "WARNING" "CategoryAlignment" "UnitRoot" "Unit test root not found at $unitRoot — skipping"
    } else {
        $cats = Get-ParsedFeatureCategories -Path $ctx.FeatureTrackingPath

        # Build expected dir name per category/subgroup using New-FeatureDirSlug from Naming module
        $expectedTopByName = @{}    # "<N>-<slug>" → category Id
        $expectedSubByParent = @{}  # parentId → @("<N.X>-<slug>", ...)

        foreach ($c in $cats) {
            $slug = $null
            try { $slug = New-FeatureDirSlug -Id $c.Id -Name $c.Name } catch { $slug = $null }
            if ([string]::IsNullOrEmpty($slug)) { continue }

            if ($c.Level -eq 1) {
                $expectedTopByName[$slug] = $c.Id
            } elseif ($c.Level -eq 2) {
                if (-not $expectedSubByParent.ContainsKey($c.ParentId)) {
                    $expectedSubByParent[$c.ParentId] = @()
                }
                $expectedSubByParent[$c.ParentId] += $slug
            }
        }

        # 17a: each expected level-1 dir exists
        foreach ($slug in $expectedTopByName.Keys) {
            $expectedPath = Join-Path $unitRoot $slug
            if (-not (Test-Path $expectedPath)) {
                Add-CheckResult "ERROR" "CategoryAlignment" "unit/$slug" "Expected category dir missing (category $($expectedTopByName[$slug]))"
            } else {
                Add-CheckResult "OK" "CategoryAlignment" "unit/$slug" "Category dir present"
            }
        }

        # 17b: each expected level-2 subgroup dir exists under its parent
        # Need to re-map parent Id → parent slug to build the expected path
        $parentIdToSlug = @{}
        foreach ($slug in $expectedTopByName.Keys) { $parentIdToSlug[$expectedTopByName[$slug]] = $slug }

        foreach ($parentId in $expectedSubByParent.Keys) {
            if (-not $parentIdToSlug.ContainsKey($parentId)) { continue }
            $parentSlug = $parentIdToSlug[$parentId]
            foreach ($subSlug in $expectedSubByParent[$parentId]) {
                $expectedPath = Join-Path (Join-Path $unitRoot $parentSlug) $subSlug
                if (-not (Test-Path $expectedPath)) {
                    Add-CheckResult "ERROR" "CategoryAlignment" "unit/$parentSlug/$subSlug" "Expected subgroup dir missing"
                } else {
                    Add-CheckResult "OK" "CategoryAlignment" "unit/$parentSlug/$subSlug" "Subgroup dir present"
                }
            }
        }

        # 17c: reverse — every dir under unit/ traces back to a category/subgroup
        $topDirs = Get-ChildItem -Path $unitRoot -Directory -ErrorAction SilentlyContinue
        foreach ($t in $topDirs) {
            if (-not $expectedTopByName.ContainsKey($t.Name)) {
                Add-CheckResult "WARNING" "CategoryAlignment" "unit/$($t.Name)" "Orphan unit dir — no matching category in feature-tracking.md (rename/remove?)"
            } else {
                $parentSlug = $t.Name
                $parentId = $expectedTopByName[$parentSlug]
                $subDirs = Get-ChildItem -Path $t.FullName -Directory -ErrorAction SilentlyContinue
                $expectedSubs = if ($expectedSubByParent.ContainsKey($parentId)) { $expectedSubByParent[$parentId] } else { @() }
                foreach ($s in $subDirs) {
                    if ($s.Name -notin $expectedSubs) {
                        Add-CheckResult "WARNING" "CategoryAlignment" "unit/$parentSlug/$($s.Name)" "Orphan subgroup dir — no matching subgroup under category $parentId"
                    }
                }
            }
        }

        Write-Host "  Checked $($cats.Count) tracked category/subgroup entries" -ForegroundColor Gray
    }
    Write-Host ""
}

# =========================================================================
# Surface 18: Workflow Alignment
# =========================================================================
# Enforces alignment between user-workflow-tracking.md WF-NNN rows and the
# on-disk `test/e2e-acceptance-testing/<workflow-slug>/templates/` layout
# scaffolded by New-TestInfrastructure.ps1 -Update Section C (Phase 3c1).
# =========================================================================
if ($runAll -or $Surface -contains "WorkflowAlignment") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 18: Workflow Alignment" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $ctx = Get-TestAuditContext -ProjectRoot $ProjectRoot
    $e2eRoot = Join-Path $ctx.TestRoot "e2e-acceptance-testing"

    if (-not (Test-Path $ctx.WorkflowTrackingPath)) {
        Add-CheckResult "WARNING" "WorkflowAlignment" "WorkflowTracking" "user-workflow-tracking.md not found at $($ctx.WorkflowTrackingPath) — skipping"
    } elseif (-not (Test-Path $e2eRoot)) {
        Add-CheckResult "WARNING" "WorkflowAlignment" "E2ERoot" "E2E root not found at $e2eRoot — skipping"
    } else {
        $workflows = Get-ParsedWorkflows -Path $ctx.WorkflowTrackingPath

        # Build expected slug set
        $expectedSlugs = @{}
        foreach ($w in $workflows) {
            $slug = $null
            try { $slug = ConvertTo-FeatureSlug -Name $w.Name -Convention 'kebab-case' } catch { $slug = $null }
            if (-not [string]::IsNullOrEmpty($slug)) { $expectedSlugs[$slug] = $w.Id }
        }

        # 18a: each expected workflow dir exists with a templates/ subdir
        foreach ($slug in $expectedSlugs.Keys) {
            $expectedPath = Join-Path (Join-Path $e2eRoot $slug) "templates"
            if (-not (Test-Path $expectedPath)) {
                Add-CheckResult "ERROR" "WorkflowAlignment" "e2e-acceptance-testing/$slug" "Expected workflow dir missing templates/ (workflow $($expectedSlugs[$slug]))"
            } else {
                Add-CheckResult "OK" "WorkflowAlignment" "e2e-acceptance-testing/$slug" "Workflow dir present"
            }
        }

        # 18b: reverse — every top-level dir under e2e-acceptance-testing/ traces to a WF entry.
        # Skip files (e.g., .gitignore) and dirs without a templates/ subdir (likely stale leftovers).
        $topDirs = Get-ChildItem -Path $e2eRoot -Directory -ErrorAction SilentlyContinue
        foreach ($t in $topDirs) {
            $hasTemplates = Test-Path (Join-Path $t.FullName "templates")
            if (-not $hasTemplates) { continue }  # Not a workflow dir; skip
            if (-not $expectedSlugs.ContainsKey($t.Name)) {
                Add-CheckResult "WARNING" "WorkflowAlignment" "e2e-acceptance-testing/$($t.Name)" "Orphan workflow dir — no matching WF-NNN in user-workflow-tracking.md"
            }
        }

        Write-Host "  Checked $($workflows.Count) tracked workflow(s)" -ForegroundColor Gray
    }
    Write-Host ""
}

# =========================================================================
# Surface 19: Variant Pair Consistency
# =========================================================================
# Scans process-framework .md files for variant_group / variant_siblings
# frontmatter and enforces sibling existence + symmetry (PF-IMP-837).
# =========================================================================
if ($runAll -or $Surface -contains "VariantPairConsistency") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Surface 19: Variant Pair Consistency" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $pfDir = Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot

    # Phase 1: scan all .md files under process-framework/ for variant frontmatter
    $variantFiles = @{}  # relPath → @{ Group; Siblings (list of filenames); FullPath; Dir }
    $mdFiles = Get-ChildItem -Path $pfDir -Filter "*.md" -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/](scripts|tools|visualization|infrastructure)[\\/]' }

    foreach ($f in $mdFiles) {
        $raw = Get-Content $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not $raw) { continue }
        if ($raw -notmatch '^---\s*\r?\n([\s\S]*?)\r?\n---') { continue }
        $fm = $Matches[1]
        if ($fm -notmatch 'variant_group:') { continue }

        $group = $null
        $siblings = @()
        $inSiblings = $false
        foreach ($line in ($fm -split '\r?\n')) {
            if ($line -match '^\s*variant_group:\s*(.+)$') {
                $group = $Matches[1].Trim().Trim('"').Trim("'")
                $inSiblings = $false
            } elseif ($line -match '^\s*variant_siblings:\s*$') {
                $inSiblings = $true
            } elseif ($line -match '^\s*variant_siblings:\s*\[(.+)\]') {
                $siblings = $Matches[1] -split '\s*,\s*' | ForEach-Object { $_.Trim().Trim('"').Trim("'") }
                $inSiblings = $false
            } elseif ($inSiblings -and $line -match '^\s+-\s+(.+)$') {
                $siblings += $Matches[1].Trim().Trim('"').Trim("'")
            } elseif ($inSiblings -and $line -notmatch '^\s+-') {
                $inSiblings = $false
            }
        }

        if ($group) {
            $relPath = $f.FullName.Substring($ProjectRoot.Length + 1) -replace '\\', '/'
            $variantFiles[$relPath] = @{
                Group    = $group
                Siblings = $siblings
                FullPath = $f.FullName
                Dir      = $f.DirectoryName
            }
        }
    }

    if ($variantFiles.Count -eq 0) {
        Add-CheckResult "WARNING" "VariantPairConsistency" "scan" "No files with variant_group frontmatter found under $(Split-Path $pfDir -Leaf)/"
    } else {
        # Build reverse lookup: fullPath → relPath for symmetry checks
        $fullToRel = @{}
        foreach ($rp in $variantFiles.Keys) { $fullToRel[$variantFiles[$rp].FullPath] = $rp }

        foreach ($relPath in $variantFiles.Keys) {
            $entry = $variantFiles[$relPath]

            # 19a: each declared sibling exists
            foreach ($sib in $entry.Siblings) {
                $sibFull = Join-Path $entry.Dir $sib
                if (-not (Test-Path $sibFull)) {
                    Add-CheckResult "ERROR" "VariantPairConsistency" $relPath "Sibling not found: $sib"
                    continue
                }

                # 19b: sibling lists this file back (symmetry)
                $sibFullResolved = (Resolve-Path $sibFull -ErrorAction SilentlyContinue).Path
                $sibRel = if ($sibFullResolved) { $fullToRel[$sibFullResolved] } else { $null }
                if (-not $sibRel -or -not $variantFiles.ContainsKey($sibRel)) {
                    Add-CheckResult "ERROR" "VariantPairConsistency" $relPath "Sibling $sib exists but has no variant_group frontmatter"
                    continue
                }

                $sibEntry = $variantFiles[$sibRel]
                $myFilename = Split-Path $relPath -Leaf
                if ($sibEntry.Siblings -notcontains $myFilename) {
                    Add-CheckResult "ERROR" "VariantPairConsistency" $relPath "Asymmetric: lists $sib as sibling but $sib does not list $myFilename back"
                } else {
                    Add-CheckResult "OK" "VariantPairConsistency" $relPath "Sibling ${sib}: exists + symmetric"
                }

                # 19c: sibling agrees on variant_group
                if ($sibEntry.Group -ne $entry.Group) {
                    Add-CheckResult "ERROR" "VariantPairConsistency" $relPath "Group mismatch: this=$($entry.Group), $sib=$($sibEntry.Group)"
                }
            }
        }

        # Count distinct groups
        $groups = $variantFiles.Values | ForEach-Object { $_.Group } | Select-Object -Unique
        Write-Host "  Checked $($variantFiles.Count) variant files across $($groups.Count) group(s)" -ForegroundColor Gray
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
$warningsLabel = if ($detailOnlyHiddenCount -gt 0) { "$warningCount ($detailOnlyHiddenCount hidden — use -Detailed to view)" } else { "$warningCount" }
Write-Host "  Warnings:     $warningsLabel" -ForegroundColor $(if ($warningCount -eq 0) { "Green" } else { "Yellow" })

# Guard: -Surface was set but matched no surface (typo / unknown name / comma-quoting issue).
# Without this, totalChecks=0 falls through to "All checks passed!" → CI false positive.
if ($totalChecks -eq 0 -and -not $runAll) {
    Write-Host ""
    Write-Host "  No surfaces matched -Surface argument(s): $($Surface -join ', ')" -ForegroundColor Red
    Write-Host "  Check spelling, or use -Surface All. Valid surface names are listed in the script's .DESCRIPTION." -ForegroundColor Red
    exit 1
}

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
