#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Validates the ID registry against actual files in the repository
.DESCRIPTION
    This script checks for:
    - Files with wrong prefixes (e.g., TSK prefix in state-tracking directory)
    - Missing directory information in registry
    - Inconsistencies between registry and actual file locations
.EXAMPLE
    .\validate-id-registry.ps1
#>

param(
    [string]$RegistryPath = "../../../id-registry.json",
    [string]$RootPath = "doc"
)

# Load the registry
$registry = Get-Content $RegistryPath | ConvertFrom-Json

Write-Host "🔍 Validating ID Registry..." -ForegroundColor Cyan
Write-Host ""

# Check 1: Files with wrong prefixes based on their location
Write-Host "📁 Checking for files with wrong prefixes based on directory location..." -ForegroundColor Yellow

$wrongPrefixFiles = @()

# Define expected prefixes for each directory pattern
$directoryPrefixMap = @{
    "doc/process-framework/tasks/*" = "PF-TSK"
    "doc/process-framework/state-tracking/*" = "PF-STA"
    "doc/process-framework/guides/*" = "PF-GDE"
    "doc/process-framework/templates/*" = "PF-TEM"
    "doc/process-framework/methodologies/documentation-tiers/assessments/*" = "ART-ASS"
    "doc/process-framework/methodologies/*" = "PF-MTH"
    "doc/product-docs/technical/design/*" = "PD-TDD", "PD-DES"
    "doc/product-docs/technical/architecture/*" = "PD-ARC"
    "doc/product-docs/user/*" = "PD-USR", "PD-UGD", "PD-FAQ", "PD-FEA", "PD-GDE"
}

# Sort patterns by specificity (most specific first)
$sortedPatterns = $directoryPrefixMap.Keys | Sort-Object { $_.Split('*').Count } -Descending

foreach ($pattern in $sortedPatterns) {
    $expectedPrefixes = $directoryPrefixMap[$pattern]
    if ($expectedPrefixes -is [string]) {
        $expectedPrefixes = @($expectedPrefixes)
    }

    $files = Get-ChildItem -Path $pattern -Recurse -Filter "*.md" -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        # Skip if already processed by a more specific pattern
        $alreadyProcessed = $false
        foreach ($processedFile in $wrongPrefixFiles) {
            if ($processedFile.File -eq $file.FullName) {
                $alreadyProcessed = $true
                break
            }
        }
        if ($alreadyProcessed) { continue }

        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -match "^---\s*\nid:\s*([A-Z-]+\d+)") {
            $fileId = $matches[1]
            $filePrefix = ($fileId -split "-\d+")[0]

            if ($filePrefix -notin $expectedPrefixes) {
                $wrongPrefixFiles += [PSCustomObject]@{
                    File = $file.FullName
                    CurrentId = $fileId
                    CurrentPrefix = $filePrefix
                    ExpectedPrefixes = $expectedPrefixes -join " or "
                    Directory = $file.Directory.FullName
                }
            }
        }
    }
}

if ($wrongPrefixFiles.Count -gt 0) {
    Write-Host "❌ Found files with wrong prefixes:" -ForegroundColor Red
    $wrongPrefixFiles | Format-Table -AutoSize
} else {
    Write-Host "✅ No files found with wrong prefixes" -ForegroundColor Green
}

Write-Host ""

# Check 2: Registry prefixes missing directory information
Write-Host "📋 Checking for prefixes missing directory information..." -ForegroundColor Yellow

$missingDirectories = @()
foreach ($prefixName in $registry.prefixes.PSObject.Properties.Name) {
    $prefix = $registry.prefixes.$prefixName
    if (-not $prefix.directories) {
        $missingDirectories += $prefixName
    }
}

if ($missingDirectories.Count -gt 0) {
    Write-Host "❌ Prefixes missing directory information:" -ForegroundColor Red
    $missingDirectories | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
} else {
    Write-Host "✅ All prefixes have directory information" -ForegroundColor Green
}

Write-Host ""

# Check 3: Validate directory paths exist
Write-Host "🗂️  Validating directory paths in registry..." -ForegroundColor Yellow

$invalidDirectories = @()
foreach ($prefixName in $registry.prefixes.PSObject.Properties.Name) {
    $prefix = $registry.prefixes.$prefixName
    if ($prefix.directories) {
        foreach ($dir in $prefix.directories) {
            if (-not (Test-Path $dir)) {
                $invalidDirectories += [PSCustomObject]@{
                    Prefix = $prefixName
                    Directory = $dir
                }
            }
        }
    }
}

if ($invalidDirectories.Count -gt 0) {
    Write-Host "❌ Invalid directory paths found:" -ForegroundColor Red
    $invalidDirectories | Format-Table -AutoSize
} else {
    Write-Host "✅ All directory paths are valid" -ForegroundColor Green
}

Write-Host ""

# Summary
Write-Host "📊 Validation Summary:" -ForegroundColor Cyan
Write-Host "  Wrong prefix files: $($wrongPrefixFiles.Count)" -ForegroundColor $(if ($wrongPrefixFiles.Count -eq 0) { "Green" } else { "Red" })
Write-Host "  Missing directories: $($missingDirectories.Count)" -ForegroundColor $(if ($missingDirectories.Count -eq 0) { "Green" } else { "Red" })
Write-Host "  Invalid directories: $($invalidDirectories.Count)" -ForegroundColor $(if ($invalidDirectories.Count -eq 0) { "Green" } else { "Red" })

if ($wrongPrefixFiles.Count -eq 0 -and $missingDirectories.Count -eq 0 -and $invalidDirectories.Count -eq 0) {
    Write-Host ""
    Write-Host "🎉 Registry validation completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "⚠️  Registry validation found issues that need attention." -ForegroundColor Yellow
    exit 1
}
