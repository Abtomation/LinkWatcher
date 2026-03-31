#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Validates test tracking consistency using pytest markers as single source of truth.
.DESCRIPTION
    SC-007: This script validates consistency between:
    - Pytest markers in test files (via test_query.py --dump) and actual files on disk
    - test-tracking.md entries and marker-bearing test files
    - Feature IDs in markers against known features from feature-tracking.md
    - Test counts from markers against pytest collection
    - test_type marker vs directory convention (warning only — marker is authoritative)

    E2E entries (TE-E2G-*, TE-E2E-*) are tracked in e2e-test-tracking.md (IMP-210).
    E2E cross-reference check against test-registry.yaml is retained for historical validation
    but skips gracefully when the registry is absent.
.PARAMETER ProjectRoot
    Path to the project root directory. Defaults to auto-detection.
.EXAMPLE
    Validate-TestTracking.ps1
.EXAMPLE
    Validate-TestTracking.ps1 -ProjectRoot "C:\Projects\MyProject"
#>

param(
    [string]$ProjectRoot = ""
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

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Tracking Validation (SC-007)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Project Root: $ProjectRoot" -ForegroundColor Gray
Write-Host ""

$errorCount = 0
$warningCount = 0

# --- Load project config and language config ---
$configPath = Join-Path $ProjectRoot "process-framework/project-config.json"
$langConfig = $null
$testDirectory = $null

if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $testDirectory = if ($config.testing -and $config.testing.testDirectory) { $config.testing.testDirectory } elseif ($config.paths.tests) { $config.paths.tests } else { $null }

    if ($config.testing -and $config.testing.language) {
        $langConfigPath = Join-Path $ProjectRoot "process-framework/languages-config/$($config.testing.language)/$($config.testing.language)-config.json"
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

$testQueryPath = Join-Path $ProjectRoot "process-framework/scripts/test/test_query.py"
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

$featureTrackingPath = Join-Path $ProjectRoot "doc/product-docs/state-tracking/permanent/feature-tracking.md"
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
    if ($filePath -match '/unit/') { $expectedType = "unit" }
    elseif ($filePath -match '/integration/') { $expectedType = "integration" }
    elseif ($filePath -match '/parsers?/') { $expectedType = "parser" }
    elseif ($filePath -match '/performance/') { $expectedType = "performance" }
    elseif ($filePath -match '/e2e/') { $expectedType = "e2e" }

    if ($expectedType -and $testType -ne $expectedType) {
        $typeMismatches += [PSCustomObject]@{
            FilePath = $filePath
            MarkerType = $testType
            DirectoryType = $expectedType
        }
    }
}

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
                # Parse discovery output
                $actualCounts = @{}
                foreach ($line in $collectOutput) {
                    $lineStr = "$line".Trim()
                    if ($lineStr -match $discoveryOutputPattern) {
                        $filePath = $matches[1].Replace('\', '/')
                        if (-not $actualCounts.ContainsKey($filePath)) {
                            $actualCounts[$filePath] = 0
                        }
                        $actualCounts[$filePath]++
                    }
                }

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

                if ($countMismatches.Count -gt 0) {
                    Write-Host "  WARNING: $($countMismatches.Count) test count mismatch(es):" -ForegroundColor Yellow
                    foreach ($m in $countMismatches) {
                        Write-Host "    - $($m.FilePath): marker=$($m.MarkerCount), actual=$($m.ActualCount)" -ForegroundColor Yellow
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
if (Test-Path $registryPath) {
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

# --- Summary ---
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Validation Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Marker entries: $($markerEntries.Count)" -ForegroundColor Gray
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
