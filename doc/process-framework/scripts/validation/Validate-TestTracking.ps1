#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Validates test tracking consistency across registry, tracking files, and disk.
.DESCRIPTION
    This script checks for consistency between:
    - ../test-registry.yaml entries and actual test files on disk
    - test-tracking.md entries and test-registry.yaml
    - feature-tracking.md Test Status column and actual test coverage
    - id-registry.json PD-TST nextAvailable counter

    Checks performed:
    1. Registry entries with missing files on disk
    2. Test files on disk not in registry
    3. Duplicate IDs in registry
    4. PD-TST nextAvailable counter consistency
    5. Cross-cutting feature ID validation
    6. testCasesCount validation against actual test runner collection (requires testing.testCountCommand in project-config.json)
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
Write-Host "  Test Tracking Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Project Root: $ProjectRoot" -ForegroundColor Gray
Write-Host ""

$errorCount = 0
$warningCount = 0

# --- Load ../test-registry.yaml ---
$registryPath = Join-Path $ProjectRoot "test/test-registry.yaml"
if (-not (Test-Path $registryPath)) {
    Write-Host "FATAL: test/test-registry.yaml not found at $registryPath" -ForegroundColor Red
    exit 1
}

# Simple YAML parsing for our list-based registry format
$registryContent = Get-Content $registryPath -Raw -Encoding UTF8
$registryEntries = @()
$currentEntry = $null

foreach ($line in (Get-Content $registryPath -Encoding UTF8)) {
    $trimmed = $line.Trim()
    if ($trimmed -match '^- id:\s*(.+)$') {
        if ($currentEntry) { $registryEntries += $currentEntry }
        $currentEntry = @{ id = $matches[1].Trim() }
    }
    elseif ($currentEntry -and $trimmed -match '^(\w+):\s*(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim().Trim('"')
        $currentEntry[$key] = $value
    }
}
if ($currentEntry) { $registryEntries += $currentEntry }

Write-Host "Loaded $($registryEntries.Count) entries from test-registry.yaml" -ForegroundColor Gray
Write-Host ""

# --- Check 1: Registry entries with missing files on disk ---
Write-Host "1. Checking registry entries against disk..." -ForegroundColor Yellow

$missingFiles = @()
foreach ($entry in $registryEntries) {
    $filePath = $entry['filePath']
    if ([string]::IsNullOrWhiteSpace($filePath)) { continue }

    # filePath in registry is relative to test/ directory or project root
    $fullPath = Join-Path $ProjectRoot $filePath
    if (-not (Test-Path $fullPath)) {
        # Try relative to test/ directory
        $fullPath = Join-Path $ProjectRoot "test" $filePath
        if (-not (Test-Path $fullPath)) {
            $missingFiles += [PSCustomObject]@{
                ID = $entry['id']
                FilePath = $filePath
                FileName = $entry['fileName']
            }
        }
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "  ERROR: $($missingFiles.Count) registry entries have missing files:" -ForegroundColor Red
    foreach ($f in $missingFiles) {
        Write-Host "    - $($f.ID): $($f.FilePath)" -ForegroundColor Red
    }
    $errorCount += $missingFiles.Count
} else {
    Write-Host "  OK: All $($registryEntries.Count) registry entries have matching files on disk" -ForegroundColor Green
}
Write-Host ""

# --- Check 2: Test files on disk not in registry ---
Write-Host "2. Checking for unregistered test files..." -ForegroundColor Yellow

$testsDir = Join-Path $ProjectRoot "tests"
$registeredPaths = $registryEntries | ForEach-Object { $_['filePath'] }

$unregisteredFiles = @()
if (Test-Path $testsDir) {
    $testFiles = Get-ChildItem -Path $testsDir -Recurse -Include "*.py" -File | Where-Object {
        $_.Name -ne "__init__.py" -and $_.Name -ne "__pycache__"
    }
    foreach ($file in $testFiles) {
        $relativePath = $file.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/')
        $relativeFromTests = $file.FullName.Substring((Join-Path $ProjectRoot "test").Length + 1).Replace('\', '/')

        $found = $false
        foreach ($regPath in $registeredPaths) {
            $normalizedRegPath = $regPath.Replace('\', '/')
            if ($relativePath -eq $normalizedRegPath -or $relativeFromTests -eq $normalizedRegPath -or $file.Name -eq ($registryEntries | Where-Object { $_['filePath'] -eq $regPath } | Select-Object -First 1)['fileName']) {
                $found = $true
                break
            }
        }
        if (-not $found) {
            $unregisteredFiles += [PSCustomObject]@{
                FileName = $file.Name
                RelativePath = $relativePath
            }
        }
    }
}

if ($unregisteredFiles.Count -gt 0) {
    Write-Host "  WARNING: $($unregisteredFiles.Count) test files on disk not in registry:" -ForegroundColor Yellow
    foreach ($f in $unregisteredFiles) {
        Write-Host "    - $($f.RelativePath)" -ForegroundColor Yellow
    }
    $warningCount += $unregisteredFiles.Count
} else {
    Write-Host "  OK: All test files on disk are registered" -ForegroundColor Green
}
Write-Host ""

# --- Check 3: Duplicate IDs ---
Write-Host "3. Checking for duplicate IDs..." -ForegroundColor Yellow

$ids = $registryEntries | ForEach-Object { $_['id'] }
$duplicates = @($ids | Group-Object | Where-Object { $_.Count -gt 1 })

if ($duplicates.Count -gt 0) {
    Write-Host "  ERROR: $($duplicates.Count) duplicate ID(s) found:" -ForegroundColor Red
    foreach ($d in $duplicates) {
        Write-Host "    - $($d.Name) (appears $($d.Count) times)" -ForegroundColor Red
    }
    $errorCount += $duplicates.Count
} else {
    Write-Host "  OK: No duplicate IDs found" -ForegroundColor Green
}
Write-Host ""

# --- Check 4: PD-TST nextAvailable counter ---
Write-Host "4. Checking PD-TST nextAvailable counter..." -ForegroundColor Yellow

$idRegistryPath = Join-Path $ProjectRoot "doc/id-registry.json"
if (Test-Path $idRegistryPath) {
    $idRegistry = Get-Content $idRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $nextAvailable = $idRegistry.prefixes.'PD-TST'.nextAvailable

    # Find highest ID in registry
    $maxId = 0
    foreach ($entry in $registryEntries) {
        $id = $entry['id']
        if ($id -match '../PD-TST-(/d+)') {
            $num = [int]$matches[1]
            if ($num -gt $maxId) { $maxId = $num }
        }
    }

    $expectedNext = $maxId + 1
    if ($nextAvailable -ne $expectedNext) {
        Write-Host "  WARNING: PD-TST nextAvailable is $nextAvailable but highest ID is PD-TST-$('{0:D3}' -f $maxId) (expected nextAvailable: $expectedNext)" -ForegroundColor Yellow
        $warningCount++
    } else {
        Write-Host "  OK: PD-TST nextAvailable ($nextAvailable) is consistent with highest ID (PD-TST-$('{0:D3}' -f $maxId))" -ForegroundColor Green
    }
} else {
    Write-Host "  WARNING: doc/id-registry.json not found" -ForegroundColor Yellow
    $warningCount++
}
Write-Host ""

# --- Check 5: Cross-cutting feature ID validation ---
Write-Host "5. Checking cross-cutting feature IDs..." -ForegroundColor Yellow

$featureTrackingPath = Join-Path $ProjectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md"
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
foreach ($entry in $registryEntries) {
    $featureId = $entry['featureId']
    if ($featureId -and $featureId -notin $knownFeatureIds -and $knownFeatureIds.Count -gt 0) {
        $invalidFeatureRefs += [PSCustomObject]@{
            ID = $entry['id']
            FeatureId = $featureId
            Type = "Primary featureId"
        }
    }

    $crossCutting = $entry['crossCuttingFeatures']
    if ($crossCutting) {
        $ccIds = [regex]::Matches($crossCutting, '../[/d]+/.[/d]+/.[/d]+') | ForEach-Object { $_.Value }
        foreach ($ccId in $ccIds) {
            if ($ccId -notin $knownFeatureIds -and $knownFeatureIds.Count -gt 0) {
                $invalidFeatureRefs += [PSCustomObject]@{
                    ID = $entry['id']
                    FeatureId = $ccId
                    Type = "crossCuttingFeatures"
                }
            }
        }
    }
}

if ($invalidFeatureRefs.Count -gt 0) {
    Write-Host "  WARNING: $($invalidFeatureRefs.Count) references to unknown feature IDs:" -ForegroundColor Yellow
    foreach ($r in $invalidFeatureRefs) {
        Write-Host "    - $($r.ID): feature $($r.FeatureId) ($($r.Type))" -ForegroundColor Yellow
    }
    $warningCount += $invalidFeatureRefs.Count
} else {
    Write-Host "  OK: All feature ID references are valid" -ForegroundColor Green
}
Write-Host ""

# --- Check 6: testCasesCount validation via project test runner ---
Write-Host "6. Checking testCasesCount against actual test collection..." -ForegroundColor Yellow

$configPath = Join-Path $ProjectRoot "doc/process-framework/project-config.json"
$testCountCommand = $null
$testDirectory = $null

if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($config.testing -and $config.testing.testCountCommand) {
        $testCountCommand = $config.testing.testCountCommand
        $testDirectory = if ($config.testing.testDirectory) { $config.testing.testDirectory } else { $config.paths.tests }
    }
}

if (-not $testCountCommand) {
    Write-Host "  SKIPPED: No testing.testCountCommand configured in project-config.json" -ForegroundColor Gray
} else {
    $testDir = Join-Path $ProjectRoot $testDirectory
    if (-not (Test-Path $testDir)) {
        Write-Host "  SKIPPED: Test directory not found: $testDir" -ForegroundColor Gray
    } else {
        # Run test collection command and capture output
        try {
            $originalLocation = Get-Location
            Set-Location $ProjectRoot
            $fullCommand = "$testCountCommand `"$testDirectory`""
            $collectOutput = Invoke-Expression $fullCommand 2>&1
            $collectExitCode = $LASTEXITCODE
            Set-Location $originalLocation

            if ($collectExitCode -ne 0 -and $collectExitCode -ne 5) {
                # Exit code 5 = no tests collected (empty files), which is fine
                Write-Host "  WARNING: Test collection command failed (exit code $collectExitCode)" -ForegroundColor Yellow
                $warningCount++
            } else {
                # Parse pytest --collect-only -q output format: "path/to/file.py::TestClass::test_method"
                # Count items per file path
                $actualCounts = @{}
                foreach ($line in $collectOutput) {
                    $lineStr = "$line".Trim()
                    if ($lineStr -match '^(.+\.py)::') {
                        $filePath = $matches[1].Replace('\', '/')
                        if (-not $actualCounts.ContainsKey($filePath)) {
                            $actualCounts[$filePath] = 0
                        }
                        $actualCounts[$filePath]++
                    }
                }

                # Compare with registry testCasesCount
                $countMismatches = @()
                foreach ($entry in $registryEntries) {
                    $regPath = $entry['filePath']
                    $regCount = $entry['testCasesCount']
                    if (-not $regPath -or -not $regCount) { continue }
                    $regCountInt = [int]$regCount

                    # Normalize registry path for comparison
                    $normalizedRegPath = $regPath.Replace('\', '/')

                    # Find matching actual count
                    $actualCount = $null
                    foreach ($actualPath in $actualCounts.Keys) {
                        # Match by exact path or by file name within the path
                        if ($actualPath -eq $normalizedRegPath -or $actualPath.EndsWith($normalizedRegPath) -or $normalizedRegPath.EndsWith($actualPath)) {
                            $actualCount = $actualCounts[$actualPath]
                            break
                        }
                    }

                    if ($null -ne $actualCount -and $actualCount -ne $regCountInt) {
                        $countMismatches += [PSCustomObject]@{
                            ID = $entry['id']
                            FilePath = $regPath
                            RegistryCount = $regCountInt
                            ActualCount = $actualCount
                        }
                    }
                }

                if ($countMismatches.Count -gt 0) {
                    Write-Host "  WARNING: $($countMismatches.Count) testCasesCount mismatch(es):" -ForegroundColor Yellow
                    foreach ($m in $countMismatches) {
                        Write-Host "    - $($m.ID) ($($m.FilePath)): registry=$($m.RegistryCount), actual=$($m.ActualCount)" -ForegroundColor Yellow
                    }
                    $warningCount += $countMismatches.Count
                } else {
                    Write-Host "  OK: All testCasesCount values match actual test collection ($($actualCounts.Count) files checked)" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "  WARNING: Failed to run test collection command: $($_.Exception.Message)" -ForegroundColor Yellow
            $warningCount++
        }
    }
}
Write-Host ""

# --- Summary ---
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Validation Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Registry entries: $($registryEntries.Count)" -ForegroundColor Gray
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
