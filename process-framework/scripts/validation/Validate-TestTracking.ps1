#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Validates test tracking consistency using pytest markers as single source of truth.
.DESCRIPTION
    SC-007: This script validates consistency between:
    - Pytest markers in test files (via test_query.py --dump) and actual files on disk
    - test-tracking.md entries and marker-bearing test files
    - Feature IDs in markers against known features from feature-tracking.md
    - Test counts from markers against pytest collection (counts are unique test
      functions — parametrized cases collapse to their owning function, PF-IMP-1074)
    - test_type marker vs directory convention (warning only — marker is authoritative)
    - test-tracking.md "Test Cases Count" column against pytest collection (catches stale tracking rows; see PF-IMP-672) — pass -Fix to sync drifted counts in place (PF-IMP-1047)

    E2E entries (TE-E2G-*, TE-E2E-*) are tracked in e2e-test-tracking.md (IMP-210).
    E2E cross-reference check against test-registry.yaml is retained for historical validation
    but skips gracefully when the registry is absent.
.PARAMETER ProjectRoot
    Path to the project root directory. Defaults to auto-detection.
.PARAMETER Fix
    Sync the test-tracking.md "Test Cases Count" column to the pytest collection counts for
    any drifted rows (Check 8), instead of only reporting the drift. Opt-in; rewrites only the
    count cell of each drifted row in place. No effect when pytest collection is unavailable
    (e.g. PowerShell-tested projects, where Check 8 is skipped). PF-IMP-1047.
.PARAMETER Path
    Comma-separated list of file paths (relative to the project root). When supplied, every
    per-file finding (Checks 1-6, 8) is scoped to these files so a post-edit "is my change
    clean" check is not buried under standing repo-wide drift. A scoped run's error/warning
    counts and exit code reflect the in-scope files ONLY — run unscoped for a full repo gate.
    PF-IMP-1176.
.PARAMETER ChangedOnly
    Scope per-file findings to the project's git-changed files (working-tree changes vs HEAD
    plus untracked files). Combine with -Path to widen the scope. Same scoped-verdict semantics
    as -Path. PF-IMP-1176.
.EXAMPLE
    Validate-TestTracking.ps1
.EXAMPLE
    Validate-TestTracking.ps1 -ChangedOnly
    Reports only findings for files changed in the working tree — the post-edit consistency check.
.EXAMPLE
    Validate-TestTracking.ps1 -Path "test/automated/unit/test_foo.py,test/automated/unit/test_bar.py"
    Scopes the report to the two named test files.
.EXAMPLE
    Validate-TestTracking.ps1 -ProjectRoot "C:\Projects\MyProject"
.EXAMPLE
    Validate-TestTracking.ps1 -Fix
    Runs all checks as usual, but for Check 8 syncs any drifted "Test Cases Count" cells to the
    pytest collection count rather than only warning.
#>

param(
    [string]$ProjectRoot = "",
    [switch]$Fix,
    [switch]$ChangedOnly,
    [string]$Path = ""
)

# --- Pure helpers (defined before the dot-source guard so Pester can load them) ---

function Get-CollectedFunctionCounts {
    <#
    .SYNOPSIS
        Counts unique test functions per file from test-discovery output.
    .DESCRIPTION
        Markers and tracking rows record AST-counted test FUNCTIONS, but discovery
        output (pytest --collect-only) lists one node per expanded parametrized case.
        Stripping the trailing [parameter] suffix and deduplicating node IDs collapses
        parametrized cases to their owning function, so counts compare like-for-like
        (PF-IMP-1074).
    #>
    param(
        [object[]]$CollectOutput,
        [string]$Pattern
    )

    $seen = @{}
    foreach ($line in $CollectOutput) {
        $lineStr = "$line".Trim()
        if ($lineStr -match $Pattern) {
            $filePath = $matches[1].Replace('\', '/')
            $nodeId = $lineStr -replace '\[.*\]$', ''
            if (-not $seen.ContainsKey($filePath)) {
                $seen[$filePath] = [System.Collections.Generic.HashSet[string]]::new()
            }
            [void]$seen[$filePath].Add($nodeId)
        }
    }

    $counts = @{}
    foreach ($filePath in $seen.Keys) {
        $counts[$filePath] = $seen[$filePath].Count
    }
    return $counts
}

function Get-TrackingCountFixes {
    <#
    .SYNOPSIS
        Computes "Test Cases Count" column corrections for test-tracking.md rows whose tracked count differs from the pytest collection count.
    .DESCRIPTION
        Pure transform shared by Validate-TestTracking.ps1 Check 8 detection and its -Fix mode
        (PF-IMP-1047). Given the tracking file's lines and a path→count map from pytest
        collection, returns one descriptor per drifted row: 0-based line index, the rewritten
        line (only the count cell's digits change; surrounding whitespace is preserved), the
        resolved file path, and the old/new counts. Rows that are not count-bearing table rows,
        lack a numeric count cell, or have no collection match are skipped — the same matching
        as the original Check 8 (suffix match; ../../ → test/ path resolution).
    #>
    param(
        [object[]]$TrackingContent,
        [hashtable]$ActualCounts
    )

    $fixes = @()
    for ($i = 0; $i -lt $TrackingContent.Count; $i++) {
        $line = $TrackingContent[$i]
        if ($line -notmatch '^\|') { continue }
        if ($line -match '^\|[\s\-:|]+\|\s*$') { continue }   # header separator row

        $cells = $line -split '\|'
        if ($cells.Count -lt 7) { continue }

        $fileCell = $cells[3].Trim()
        if ($fileCell -notmatch '\[([^\]]+)\]\(([^)]+)\)') { continue }
        $rawPath = $matches[2].Replace('\', '/')
        $resolvedPath = if ($rawPath -match '^\.\./\.\./(.+)$') { "test/$($matches[1])" } else { $rawPath }

        $countCell = $cells[5].Trim()
        if ($countCell -notmatch '^\d+$') { continue }
        $trackedCount = [int]$countCell

        # Suffix-match against pytest collection results (same convention as Check 6)
        $collectionCount = $null
        foreach ($actualPath in $ActualCounts.Keys) {
            if ($actualPath -eq $resolvedPath -or $actualPath.EndsWith($resolvedPath) -or $resolvedPath.EndsWith($actualPath)) {
                $collectionCount = $ActualCounts[$actualPath]
                break
            }
        }
        if ($null -eq $collectionCount) { continue }
        if ($trackedCount -eq $collectionCount) { continue }

        # Rewrite only the digits of the count cell, preserving its surrounding whitespace.
        $cells[5] = $cells[5] -replace '\d+', "$collectionCount"
        $fixes += [PSCustomObject]@{
            LineIndex       = $i
            OldLine         = $line
            NewLine         = ($cells -join '|')
            FilePath        = $resolvedPath
            TrackedCount    = $trackedCount
            CollectionCount = $collectionCount
        }
    }

    return $fixes
}

function ConvertTo-ScopePathList {
    <#
    .SYNOPSIS
        Splits a comma-separated -Path value into normalized forward-slash relative paths (PF-IMP-1176).
    #>
    param([string]$PathCsv)
    if ([string]::IsNullOrWhiteSpace($PathCsv)) { return @() }
    return @($PathCsv -split ',' | ForEach-Object { $_.Trim().Replace('\', '/') } | Where-Object { $_ })
}

function Test-FileInScope {
    <#
    .SYNOPSIS
        Returns whether a finding's file path falls within an active output scope set (PF-IMP-1176).
    .DESCRIPTION
        When $ScopeSet is $null, scoping is inactive and every path is in scope (the script's
        default repo-wide behavior). Otherwise a file is in scope when its normalized
        forward-slash path equals or suffix-matches any scope entry — the same suffix convention
        the count checks use, so a tracking-relative path and a project-relative path for the
        same file both match. An empty (non-null) scope set matches nothing.
    #>
    param(
        [string]$FilePath,
        $ScopeSet
    )
    if ($null -eq $ScopeSet) { return $true }
    if ([string]::IsNullOrWhiteSpace($FilePath)) { return $false }
    $p = $FilePath.Replace('\', '/')
    foreach ($s in $ScopeSet) {
        if ($p -eq $s -or $p.EndsWith($s) -or $s.EndsWith($p)) { return $true }
    }
    return $false
}

# Dot-source guard: `. <path>` loads the helpers above without running the validation.
if ($MyInvocation.InvocationName -eq '.') { return }

# --- Import Common-ScriptHelpers (always) ---
# Get-ProcessFrameworkPath / Get-ProjectRoot live here and are used on BOTH the -ProjectRoot
# and auto-detect paths below, so the import must run unconditionally — not only in the
# auto-detect branch, or a -ProjectRoot invocation in a fresh session crashes at the first
# Get-ProcessFrameworkPath call (PF-IMP-1149). The walk-up keys off $PSScriptRoot, independent
# of $ProjectRoot.
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# --- Resolve project root ---
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Get-ProjectRoot
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Tracking Validation (SC-007)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Project Root: $ProjectRoot" -ForegroundColor Gray
Write-Host ""

# --- Build output scope set (PF-IMP-1176) ---
# -Path (comma-separated) and/or -ChangedOnly restrict every per-file finding to the named /
# git-changed files, so a post-edit "is my change clean" check is not buried under standing
# repo-wide drift. $scopeSet stays $null when neither is given — full repo-wide behavior,
# byte-for-byte unchanged. A scoped run's error/warning counts and exit code reflect the
# in-scope files ONLY; CI/release gates should run unscoped.
$scopeSet = $null
if ($ChangedOnly -or -not [string]::IsNullOrWhiteSpace($Path)) {
    $scopePaths = [System.Collections.Generic.List[string]]::new()
    foreach ($p in (ConvertTo-ScopePathList -PathCsv $Path)) { $scopePaths.Add($p) }
    if ($ChangedOnly) {
        try {
            $gitChanged = @(& git -C $ProjectRoot diff --name-only HEAD 2>$null) +
                          @(& git -C $ProjectRoot ls-files --others --exclude-standard 2>$null)
            foreach ($c in $gitChanged) {
                if (-not [string]::IsNullOrWhiteSpace($c)) { $scopePaths.Add($c.Trim().Replace('\', '/')) }
            }
        } catch {
            Write-Host "WARNING: -ChangedOnly could not query git ($($_.Exception.Message)); using -Path scope only" -ForegroundColor Yellow
        }
    }
    $scopeSet = @($scopePaths | Sort-Object -Unique)
    Write-Host "Output scope: $($scopeSet.Count) file(s) (scoped run — verdict reflects these files only)" -ForegroundColor Gray
    Write-Host ""
}

$errorCount = 0
$warningCount = 0

# --- Load project config and language config ---
$configPath = Join-Path $ProjectRoot "doc/project-config.json"
$langConfig = $null
$testDirectory = $null

if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $testDirectory = if ($config.testing -and $config.testing.testDirectory) { $config.testing.testDirectory } elseif ($config.paths.tests) { $config.paths.tests } else { $null }

    if ($config.testing -and $config.testing.language) {
        $langConfigPath = Join-Path (Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot) "languages-config/$($config.testing.language)/$($config.testing.language)-config.json"
        if (Test-Path $langConfigPath) {
            $langConfig = Get-Content $langConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        }
    }
}

# Extract language-specific settings
$testFileExtension = if ($langConfig -and $langConfig.testing.testFileExtension) { $langConfig.testing.testFileExtension } else { $null }
$testFileExclusions = if ($langConfig -and $langConfig.testing.testFileExclusions) { @($langConfig.testing.testFileExclusions) } else { @() }
$discoveryOutputPattern = if ($langConfig -and $langConfig.testing.discoveryOutputPattern) { $langConfig.testing.discoveryOutputPattern } else { $null }
$testCountCommand = if ($langConfig -and $langConfig.testing.discoveryCommand) { $langConfig.testing.discoveryCommand } else { $null }

# --- Load marker data from test_query.py ---
Write-Host "Loading marker data from test_query.py..." -ForegroundColor Gray

$testQueryPath = Join-Path (Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot) "scripts/test/test_query.py"
if (-not (Test-Path $testQueryPath)) {
    Write-Host "FATAL: test_query.py not found at $testQueryPath" -ForegroundColor Red
    exit 1
}

try {
    $queryOutput = python $testQueryPath --dump --format json 2>&1
    $markerData = $queryOutput | ConvertFrom-Json
} catch {
    Write-Host "FATAL: Failed to run test_query.py --dump --format json: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$markerEntries = if ($markerData -is [array]) { $markerData } else { @($markerData) }
Write-Host "Loaded $($markerEntries.Count) entries from test_query.py" -ForegroundColor Gray
Write-Host ""

# --- Check 1: Marker entries with missing files on disk ---
Write-Host "1. Checking marker entries against disk..." -ForegroundColor Yellow

$missingFiles = @()
foreach ($entry in $markerEntries) {
    $filePath = $entry.file
    if ([string]::IsNullOrWhiteSpace($filePath)) { continue }

    $fullPath = Join-Path $ProjectRoot $filePath
    if (-not (Test-Path $fullPath)) {
        $missingFiles += [PSCustomObject]@{
            FilePath = $filePath
            Feature = $entry.feature
        }
    }
}

$missingFiles = @($missingFiles | Where-Object { Test-FileInScope -FilePath $_.FilePath -ScopeSet $scopeSet })

if ($missingFiles.Count -gt 0) {
    Write-Host "  ERROR: $($missingFiles.Count) marker entries have missing files:" -ForegroundColor Red
    foreach ($f in $missingFiles) {
        Write-Host "    - $($f.FilePath) (feature: $($f.Feature))" -ForegroundColor Red
    }
    $errorCount += $missingFiles.Count
} else {
    Write-Host "  OK: All $($markerEntries.Count) marker entries have matching files on disk" -ForegroundColor Green
}
Write-Host ""

# --- Check 2: Test files on disk not in marker data ---
Write-Host "2. Checking for unmarked test files..." -ForegroundColor Yellow

$testsDir = if ($testDirectory) { Join-Path $ProjectRoot $testDirectory } else { Join-Path $ProjectRoot "test" }
$markerPaths = $markerEntries | Where-Object { -not [string]::IsNullOrWhiteSpace($_.file) } | ForEach-Object { $_.file.Replace('\', '/') }

$unmarkedFiles = @()
if (-not $testFileExtension) {
    Write-Host "  SKIPPED: No testFileExtension in language config — cannot scan" -ForegroundColor Gray
} elseif (Test-Path $testsDir) {
    # Only scan the automated test directory
    $automatedDir = Join-Path $testsDir "automated"
    if (Test-Path $automatedDir) {
        $testFiles = Get-ChildItem -Path $automatedDir -Recurse -Include "*$testFileExtension" -File | Where-Object {
            $_.Name -notin $testFileExclusions -and $_.Directory.Name -notin $testFileExclusions
        }
        foreach ($file in $testFiles) {
            $relativePath = $file.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/')
            if ($relativePath -notin $markerPaths) {
                $unmarkedFiles += [PSCustomObject]@{
                    FileName = $file.Name
                    RelativePath = $relativePath
                }
            }
        }
    }
}

$unmarkedFiles = @($unmarkedFiles | Where-Object { Test-FileInScope -FilePath $_.RelativePath -ScopeSet $scopeSet })

if ($unmarkedFiles.Count -gt 0) {
    Write-Host "  WARNING: $($unmarkedFiles.Count) test files on disk have no pytestmark:" -ForegroundColor Yellow
    foreach ($f in $unmarkedFiles) {
        Write-Host "    - $($f.RelativePath)" -ForegroundColor Yellow
    }
    $warningCount += $unmarkedFiles.Count
} else {
    Write-Host "  OK: All test files on disk have pytest markers" -ForegroundColor Green
}
Write-Host ""

# --- Check 3: Cross-reference markers ↔ test-tracking.md ---
Write-Host "3. Checking marker entries against test-tracking.md..." -ForegroundColor Yellow

$testTrackingPath = Join-Path $ProjectRoot "test/state-tracking/permanent/test-tracking.md"
if (-not (Test-Path $testTrackingPath)) {
    Write-Host "  WARNING: test-tracking.md not found" -ForegroundColor Yellow
    $warningCount++
} else {
    $trackingContent = Get-Content $testTrackingPath -Encoding UTF8

    # Extract file references from tracking table rows
    $trackingFiles = @()
    foreach ($line in $trackingContent) {
        # Match markdown links in table rows: [filename](path)
        if ($line -match '^\|' -and $line -match '\[([^\]]+)\]\(([^)]+)\)') {
            $trackingFiles += $matches[2].Replace('\', '/')
        }
    }

    # Check: marker entries not in tracking
    $missingInTracking = @()
    foreach ($entry in $markerEntries) {
        $entryPath = $entry.file.Replace('\', '/')
        $entryFileName = Split-Path $entryPath -Leaf
        # Match by filename since tracking uses relative paths from its own location
        $found = $trackingFiles | Where-Object { $_ -match [regex]::Escape($entryFileName) }
        if (-not $found) {
            $missingInTracking += $entryPath
        }
    }

    $missingInTracking = @($missingInTracking | Where-Object { Test-FileInScope -FilePath $_ -ScopeSet $scopeSet })

    if ($missingInTracking.Count -gt 0) {
        Write-Host "  WARNING: $($missingInTracking.Count) marker entries not found in test-tracking.md:" -ForegroundColor Yellow
        foreach ($m in $missingInTracking) {
            Write-Host "    - $m" -ForegroundColor Yellow
        }
        $warningCount += $missingInTracking.Count
    } else {
        Write-Host "  OK: All marker entries have corresponding test-tracking.md rows" -ForegroundColor Green
    }
}
Write-Host ""

# --- Check 4: Feature ID validation ---
Write-Host "4. Checking feature IDs in markers..." -ForegroundColor Yellow

$featureTrackingPath = Join-Path $ProjectRoot "doc/state-tracking/permanent/feature-tracking.md"
$knownFeatureIds = @()
if (Test-Path $featureTrackingPath) {
    $ftContent = Get-Content $featureTrackingPath -Encoding UTF8
    foreach ($line in $ftContent) {
        if ($line -match '^\|\s*\[(\d+\.\d+\.\d+)\]') {
            $knownFeatureIds += $matches[1]
        }
    }
}

$invalidFeatureRefs = @()
foreach ($entry in $markerEntries) {
    $featureId = $entry.feature
    if ($featureId -and $featureId -notin $knownFeatureIds -and $knownFeatureIds.Count -gt 0) {
        $invalidFeatureRefs += [PSCustomObject]@{
            FilePath = $entry.file
            FeatureId = $featureId
            Type = "feature marker"
        }
    }

    # Check cross-cutting features
    if ($entry.cross_cutting) {
        foreach ($ccId in $entry.cross_cutting) {
            if ($ccId -notin $knownFeatureIds -and $knownFeatureIds.Count -gt 0) {
                $invalidFeatureRefs += [PSCustomObject]@{
                    FilePath = $entry.file
                    FeatureId = $ccId
                    Type = "cross_cutting marker"
                }
            }
        }
    }
}

$invalidFeatureRefs = @($invalidFeatureRefs | Where-Object { Test-FileInScope -FilePath $_.FilePath -ScopeSet $scopeSet })

if ($invalidFeatureRefs.Count -gt 0) {
    Write-Host "  WARNING: $($invalidFeatureRefs.Count) references to unknown feature IDs:" -ForegroundColor Yellow
    foreach ($r in $invalidFeatureRefs) {
        Write-Host "    - $($r.FilePath): feature $($r.FeatureId) ($($r.Type))" -ForegroundColor Yellow
    }
    $warningCount += $invalidFeatureRefs.Count
} else {
    Write-Host "  OK: All feature ID references are valid" -ForegroundColor Green
}
Write-Host ""

# --- Check 5: test_type marker vs directory convention ---
Write-Host "5. Checking test_type marker vs directory convention..." -ForegroundColor Yellow

$typeMismatches = @()
foreach ($entry in $markerEntries) {
    $filePath = $entry.file.Replace('\', '/')
    $testType = $entry.test_type

    if (-not $testType) { continue }

    # Infer expected type from directory path
    $expectedType = $null
    if ($filePath -match '/unit') { $expectedType = "unit" }
    elseif ($filePath -match '/integration') { $expectedType = "integration" }
    elseif ($filePath -match '/parsers?/') { $expectedType = "parser" }
    elseif ($filePath -match '/performance') { $expectedType = "performance" }
    elseif ($filePath -match '/e2e') { $expectedType = "e2e" }

    if ($expectedType -and $testType -ne $expectedType) {
        $typeMismatches += [PSCustomObject]@{
            FilePath = $filePath
            MarkerType = $testType
            DirectoryType = $expectedType
        }
    }
}

$typeMismatches = @($typeMismatches | Where-Object { Test-FileInScope -FilePath $_.FilePath -ScopeSet $scopeSet })

if ($typeMismatches.Count -gt 0) {
    Write-Host "  WARNING: $($typeMismatches.Count) test_type marker/directory mismatch(es) (marker is authoritative):" -ForegroundColor Yellow
    foreach ($m in $typeMismatches) {
        Write-Host "    - $($m.FilePath): marker='$($m.MarkerType)', directory='$($m.DirectoryType)'" -ForegroundColor Yellow
    }
    $warningCount += $typeMismatches.Count
} else {
    Write-Host "  OK: All test_type markers match directory convention" -ForegroundColor Green
}
Write-Host ""

# --- Check 6: testCasesCount validation via test runner ---
Write-Host "6. Checking test counts against pytest collection..." -ForegroundColor Yellow

# Hoisted to script scope so Check 8 can reuse the collection results
$actualCounts = @{}

if (-not $testCountCommand) {
    Write-Host "  SKIPPED: No discoveryCommand in language config" -ForegroundColor Gray
} else {
    $testDir = Join-Path $ProjectRoot $testDirectory
    if (-not (Test-Path $testDir)) {
        Write-Host "  SKIPPED: Test directory not found: $testDir" -ForegroundColor Gray
    } else {
        try {
            $originalLocation = Get-Location
            Set-Location $ProjectRoot
            $fullCommand = "$testCountCommand `"$testDirectory`""
            $collectOutput = Invoke-Expression $fullCommand 2>&1
            $collectExitCode = $LASTEXITCODE
            Set-Location $originalLocation

            if ($collectExitCode -ne 0 -and $collectExitCode -ne 5) {
                Write-Host "  WARNING: Test collection command failed (exit code $collectExitCode)" -ForegroundColor Yellow
                $warningCount++
            } elseif (-not $discoveryOutputPattern) {
                Write-Host "  SKIPPED: No discoveryOutputPattern in language config" -ForegroundColor Gray
            } else {
                # Parse discovery output into unique-test-function counts (script-scoped
                # $actualCounts, reused by Check 8). Parametrized cases collapse to their
                # owning function so counts compare like-for-like with the AST function
                # counts in markers and tracking rows (PF-IMP-1074).
                $actualCounts = Get-CollectedFunctionCounts -CollectOutput $collectOutput -Pattern $discoveryOutputPattern

                # Compare with marker test_count
                $countMismatches = @()
                foreach ($entry in $markerEntries) {
                    $markerPath = $entry.file.Replace('\', '/')
                    $markerCount = $entry.test_count
                    if (-not $markerCount) { continue }

                    $actualCount = $null
                    foreach ($actualPath in $actualCounts.Keys) {
                        if ($actualPath -eq $markerPath -or $actualPath.EndsWith($markerPath) -or $markerPath.EndsWith($actualPath)) {
                            $actualCount = $actualCounts[$actualPath]
                            break
                        }
                    }

                    if ($null -ne $actualCount -and $actualCount -ne [int]$markerCount) {
                        $countMismatches += [PSCustomObject]@{
                            FilePath = $markerPath
                            MarkerCount = $markerCount
                            ActualCount = $actualCount
                        }
                    }
                }

                $countMismatches = @($countMismatches | Where-Object { Test-FileInScope -FilePath $_.FilePath -ScopeSet $scopeSet })

                if ($countMismatches.Count -gt 0) {
                    Write-Host "  WARNING: $($countMismatches.Count) test count mismatch(es):" -ForegroundColor Yellow
                    foreach ($m in $countMismatches) {
                        Write-Host "    - $($m.FilePath): marker=$($m.MarkerCount), collected functions=$($m.ActualCount)" -ForegroundColor Yellow
                    }
                    $warningCount += $countMismatches.Count
                } else {
                    Write-Host "  OK: All test counts match ($($actualCounts.Count) files checked)" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "  WARNING: Failed to run test collection: $($_.Exception.Message)" -ForegroundColor Yellow
            $warningCount++
        }
    }
}
Write-Host ""

# --- Check 7: E2E entries cross-reference (registry ↔ e2e-test-tracking.md) ---
# E2E entries tracked in e2e-test-tracking.md (IMP-210 completed)
Write-Host "7. Checking E2E entries cross-reference..." -ForegroundColor Yellow

$registryPath = Join-Path $ProjectRoot "test/test-registry.yaml"
if ($null -ne $scopeSet) {
    Write-Host "  SKIPPED: scoped run (-Path/-ChangedOnly) — Check 7 (E2E ID cross-reference) is not file-scoped" -ForegroundColor Gray
} elseif (Test-Path $registryPath) {
    # Parse E2E entries from registry
    $e2eRegistryIds = @()
    $currentEntry = $null
    foreach ($line in (Get-Content $registryPath -Encoding UTF8)) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^-\s+id:\s*(.+)$') {
            if ($currentEntry -and $currentEntry['id'] -match '^TE-E2[EG]-') {
                $e2eRegistryIds += $currentEntry['id']
            }
            $idValue = $matches[1].Trim()
            $currentEntry = @{ id = $idValue }
        }
        elseif ($currentEntry -and $trimmed -match '^(\w+):\s*(.*)$') {
            $key = $matches[1]
            $val = $matches[2]
            if ($key -and $val) {
                $currentEntry[$key.Trim()] = $val.Trim().Trim('"')
            }
        }
    }
    if ($currentEntry -and $currentEntry['id'] -match '^TE-E2[EG]-') { $e2eRegistryIds += $currentEntry['id'] }

    if ($e2eRegistryIds.Count -eq 0) {
        Write-Host "  SKIPPED: No E2E entries found in test-registry.yaml" -ForegroundColor Gray
    } else {
        $e2eTrackingPath = Join-Path $ProjectRoot "test/state-tracking/permanent/e2e-test-tracking.md"
        if (-not (Test-Path $e2eTrackingPath)) {
            Write-Host "  WARNING: e2e-test-tracking.md not found" -ForegroundColor Yellow
            $warningCount++
        } else {
            $trackingE2eIds = @()
            $trackingContent = Get-Content $e2eTrackingPath -Encoding UTF8
            foreach ($tLine in $trackingContent) {
                if ($tLine -match '^\|\s*(TE-E2[EG]-\d+)') {
                    $trackingE2eIds += $matches[1]
                }
            }

            $missingInTracking = @($e2eRegistryIds | Where-Object { $_ -notin $trackingE2eIds })
            $missingInRegistry = @($trackingE2eIds | Where-Object { $_ -notin $e2eRegistryIds })

            if ($missingInTracking.Count -gt 0) {
                Write-Host "  WARNING: $($missingInTracking.Count) E2E entries in registry but not in tracking:" -ForegroundColor Yellow
                foreach ($m in $missingInTracking) { Write-Host "    - $m" -ForegroundColor Yellow }
                $warningCount += $missingInTracking.Count
            }
            if ($missingInRegistry.Count -gt 0) {
                Write-Host "  WARNING: $($missingInRegistry.Count) E2E entries in tracking but not in registry:" -ForegroundColor Yellow
                foreach ($m in $missingInRegistry) { Write-Host "    - $m" -ForegroundColor Yellow }
                $warningCount += $missingInRegistry.Count
            }
            if ($missingInTracking.Count -eq 0 -and $missingInRegistry.Count -eq 0) {
                Write-Host "  OK: All $($e2eRegistryIds.Count) E2E entries cross-reference correctly" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "  SKIPPED: test-registry.yaml not found (E2E entries tracked in e2e-test-tracking.md)" -ForegroundColor Gray
}
Write-Host ""

# --- Check 8: test-tracking.md "Test Cases Count" column vs pytest collection (PF-IMP-672) ---
# Catches stale tracking rows where tests were added/removed but the count column
# was not updated. Complements Check 6 (which checks marker counts). Last Executed
# column is intentionally not validated — its documented purpose is manual-test
# execution date, not a count to compare.
Write-Host "8. Checking test-tracking.md 'Test Cases Count' column against pytest collection..." -ForegroundColor Yellow

if ($actualCounts.Count -eq 0) {
    Write-Host "  SKIPPED: Pytest collection unavailable (Check 6 prerequisite)" -ForegroundColor Gray
} elseif (-not (Test-Path $testTrackingPath)) {
    Write-Host "  SKIPPED: test-tracking.md not found" -ForegroundColor Gray
} else {
    # Detection + fix share one pure transform (PF-IMP-1047). Each fix descriptor carries the
    # rewritten line; tracking-row cell layout is: [0]=empty, [1]=feature, [2]=type, [3]=file,
    # [4]=status, [5]=count, [6]=last_run, [7]=last_updated, [8]=notes, [9]=empty.
    $countFixes = @(Get-TrackingCountFixes -TrackingContent $trackingContent -ActualCounts $actualCounts)
    $countFixes = @($countFixes | Where-Object { Test-FileInScope -FilePath $_.FilePath -ScopeSet $scopeSet })

    if ($countFixes.Count -eq 0) {
        Write-Host "  OK: All test-tracking.md row counts match pytest collection" -ForegroundColor Green
    } elseif ($Fix) {
        # -Fix: sync the drifted count cells in place. Read raw to preserve formatting and line
        # endings, replace each drifted row line, write back once.
        $rawTracking = Get-Content $testTrackingPath -Raw -Encoding UTF8
        foreach ($f in $countFixes) {
            $rawTracking = $rawTracking.Replace($f.OldLine, $f.NewLine)
        }
        Set-Content -Path $testTrackingPath -Value $rawTracking -NoNewline -Encoding UTF8
        Write-Host "  FIXED: synced $($countFixes.Count) tracking-row count(s) to pytest collection:" -ForegroundColor Green
        foreach ($f in $countFixes) {
            Write-Host "    - $($f.FilePath): $($f.TrackedCount) -> $($f.CollectionCount)" -ForegroundColor Green
        }
    } else {
        Write-Host "  WARNING: $($countFixes.Count) tracking-row count mismatch(es) (re-run with -Fix to sync):" -ForegroundColor Yellow
        foreach ($f in $countFixes) {
            Write-Host "    - $($f.FilePath): tracked=$($f.TrackedCount), collected functions=$($f.CollectionCount)" -ForegroundColor Yellow
        }
        $warningCount += $countFixes.Count
    }
}
Write-Host ""

# --- Summary ---
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Validation Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Marker entries: $($markerEntries.Count)" -ForegroundColor Gray
if ($null -ne $scopeSet) {
    Write-Host "  Scope: $($scopeSet.Count) file(s) — counts/verdict reflect scoped files only" -ForegroundColor Gray
}
Write-Host "  Errors:   $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Red" })
Write-Host "  Warnings: $warningCount" -ForegroundColor $(if ($warningCount -eq 0) { "Green" } else { "Yellow" })

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
