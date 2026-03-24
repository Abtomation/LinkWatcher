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
    ../validate-id-registry.ps1
#>

param(
    [string]$RegistryPath = "",
    [string]$RootPath = ""
)

# Import the common helpers for Get-ProjectRoot
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Resolve defaults using project root for reliability
$ProjectRoot = Get-ProjectRoot
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = Join-Path -Path $ProjectRoot -ChildPath "doc"
}

# Load all three registries and merge prefixes for validation
$registryFiles = @(
    (Join-Path -Path $ProjectRoot -ChildPath "doc/process-framework/PF-id-registry.json"),
    (Join-Path -Path $ProjectRoot -ChildPath "doc/product-docs/PD-id-registry.json"),
    (Join-Path -Path $ProjectRoot -ChildPath "test/TE-id-registry.json")
)
# Allow override with single registry path for backward compatibility
if (-not [string]::IsNullOrWhiteSpace($RegistryPath)) {
    $registryFiles = @($RegistryPath)
}

# Merge all prefixes into a single object for validation
$mergedPrefixes = [PSCustomObject]@{}
foreach ($regFile in $registryFiles) {
    if (Test-Path $regFile) {
        $reg = Get-Content $regFile | ConvertFrom-Json
        foreach ($p in $reg.prefixes.PSObject.Properties) {
            $mergedPrefixes | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force
        }
        Write-Host "  Loaded: $(Split-Path $regFile -Leaf) ($($reg.prefixes.PSObject.Properties.Name.Count) prefixes)" -ForegroundColor Gray
    } else {
        Write-Host "  WARNING: Registry not found: $regFile" -ForegroundColor Yellow
    }
}
$registry = [PSCustomObject]@{ prefixes = $mergedPrefixes }

Write-Host "🔍 Validating ID Registry..." -ForegroundColor Cyan
Write-Host ""

# Check 1: Files with wrong prefixes based on their location
Write-Host "📁 Checking for files with wrong prefixes based on directory location..." -ForegroundColor Yellow

$wrongPrefixFiles = @()

# Build prefix-to-directories map from the merged registry (auto-generated, never stale)
$prefixDirectories = @{}
foreach ($prefixName in $registry.prefixes.PSObject.Properties.Name) {
    $prefix = $registry.prefixes.$prefixName
    if ($prefix.directories) {
        $dirs = @()
        foreach ($dirProp in $prefix.directories.PSObject.Properties) {
            if ($dirProp.Name -eq "default") { continue }
            $absDir = (Join-Path -Path $ProjectRoot -ChildPath $dirProp.Value).Replace('\', '/')
            $dirs += $absDir
        }
        $prefixDirectories[$prefixName] = $dirs
    }
}

# Build reverse map: for each directory path, which prefixes claim it?
# This lets us find the most specific matching directory for any file
$dirToPrefixes = @{}
foreach ($prefixName in $prefixDirectories.Keys) {
    foreach ($dir in $prefixDirectories[$prefixName]) {
        if ($dirToPrefixes.ContainsKey($dir)) {
            if ($dirToPrefixes[$dir] -notcontains $prefixName) {
                $dirToPrefixes[$dir] = @($dirToPrefixes[$dir]) + $prefixName
            }
        } else {
            $dirToPrefixes[$dir] = @($prefixName)
        }
    }
}

# Scan all .md files under doc/ and test/ for ID frontmatter
$scanRoots = @(
    (Join-Path $ProjectRoot "doc"),
    (Join-Path $ProjectRoot "test")
)
foreach ($scanRoot in $scanRoots) {
    if (-not (Test-Path $scanRoot)) { continue }
    $files = Get-ChildItem -Path $scanRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content -or $content -notmatch "(?m)^---\s*\nid:\s*([A-Z]+-[A-Z]+-\d+)") { continue }

        $fileId = $matches[1]
        $filePrefix = ($fileId -replace '-\d+$', '')
        $fileDirNorm = $file.DirectoryName.Replace('\', '/')

        # Check if this file's prefix has a registered directory that is an ancestor
        # This handles cases like archived feedback forms that live in subdirectories
        # not explicitly registered but whose prefix maps to a parent directory
        $prefixIsValid = $false
        if ($prefixDirectories.ContainsKey($filePrefix)) {
            foreach ($prefixDir in $prefixDirectories[$filePrefix]) {
                if ($fileDirNorm -like "$prefixDir*") {
                    $prefixIsValid = $true
                    break
                }
            }
        }
        if ($prefixIsValid) { continue }

        # Find the most specific registered directory that is an ancestor of this file
        $bestMatch = $null
        $bestMatchLen = 0
        foreach ($registeredDir in $dirToPrefixes.Keys) {
            if ($fileDirNorm -like "$registeredDir*" -and $registeredDir.Length -gt $bestMatchLen) {
                $bestMatch = $registeredDir
                $bestMatchLen = $registeredDir.Length
            }
        }

        # If we found a matching registered directory, check if the prefix is expected
        if ($bestMatch) {
            $expectedPrefixes = @($dirToPrefixes[$bestMatch])
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
        # Files not under any registered directory are skipped (can't validate)
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
        foreach ($dirProp in $prefix.directories.PSObject.Properties) {
            if ($dirProp.Name -eq "default") { continue }
            $dirPath = Join-Path -Path $ProjectRoot -ChildPath $dirProp.Value
            if (-not (Test-Path $dirPath)) {
                $invalidDirectories += [PSCustomObject]@{
                    Prefix = $prefixName
                    DirectoryKey = $dirProp.Name
                    Directory = $dirProp.Value
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
