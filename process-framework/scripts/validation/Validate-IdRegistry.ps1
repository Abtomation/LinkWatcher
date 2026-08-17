#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Validates the ID registry against actual files in the repository
.DESCRIPTION
    This script checks for:
    - Files with wrong prefixes (e.g., TSK prefix in state-tracking directory)
    - Missing directory information in registry
    - Inconsistencies between registry and actual file locations
.PARAMETER RegistryPath
    Validates against this single registry file instead of the default three (PF-id-registry.json,
    doc/PD-id-registry.json, test/TE-id-registry.json), whose prefixes are otherwise merged.
    Retained for backward compatibility.
.PARAMETER RootPath
    Root directory scanned for files to check against the registry. Defaults to the project's
    doc/ directory.
.EXAMPLE
    ../Validate-IdRegistry.ps1
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

# Face fix (PF-PRO-068, owner-decided 2026-08-09): validation follows the WRITE face — the
# registry it validates is the canonical authored file, and mints land in the authored tree.
# At a producer role that is paths.blueprint (Get-BlueprintPath, no-fallback contract); at a
# leaf, the operative tree. Left on the consumer key, a post-cutover producer would validate
# the dead received projection: fresh mints read as missing while producer-face drift goes green.
$frameworkWritePath = if ((Get-WorkspaceRole -ProjectRoot $ProjectRoot) -in @('framework', 'framework-builder')) {
    Get-BlueprintPath -ProjectRoot $ProjectRoot
} else {
    Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot
}

# Load all three registries and merge prefixes for validation
$registryFiles = @(
    (Join-Path -Path $frameworkWritePath -ChildPath "PF-id-registry.json"),
    (Join-Path -Path $ProjectRoot -ChildPath "doc/PD-id-registry.json"),
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

# Compute the relative framework path under $ProjectRoot for PF-* prefix path rewriting
# (Phase 5.5 + Framework Self-Testing Phase 4 OP-NEW-A fix, 2026-05-20).
# In appdev: paths.process_framework = "blueprint/process-framework" → PF-* prefix
# directories like "process-framework/tasks/..." need to resolve under blueprint/.
# In rolled-out projects: paths.process_framework = "process-framework" (no rewrite needed,
# but the rewrite is idempotent so it's safe to apply). Same write face as the registry file
# above — the declared directories and the registry that declares them must never split faces.
$frameworkAbsolute = $frameworkWritePath.Replace('\', '/')
$projectRootForward = ((Resolve-Path $ProjectRoot).Path).Replace('\', '/')
$frameworkRelative = $frameworkAbsolute.Substring($projectRootForward.Length).TrimStart('/')

function Resolve-PrefixDirectoryPath {
    param([string]$PrefixName, [string]$RawPath)
    # Framework-tree registries are rolled out alongside the framework, so their
    # `directories.*` fields are written as "process-framework/..." (the canonical
    # rolled-out layout). Where the framework tree lives elsewhere (e.g. a producer
    # face at "blueprint/process-framework"), that prefix needs to be rewritten to
    # the configured framework path. Keyed on the PATH SHAPE, not the prefix name:
    # any pool whose directories declare the rolled layout gets the rewrite (PF-*
    # and per-framework families like FB-* alike, PF-PRO-068 P-12); PD/TE-style
    # project-root-relative values ("doc/...", "test/...") pass through untouched.
    if ($RawPath -match '^process-framework[/\\]') {
        return ($RawPath -replace '^process-framework[/\\]', "$frameworkRelative/")
    }
    if ($RawPath -eq 'process-framework') {
        return $frameworkRelative
    }
    return $RawPath
}

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
            $resolvedRel = Resolve-PrefixDirectoryPath -PrefixName $prefixName -RawPath $dirProp.Value
            $absDir = (Join-Path -Path $ProjectRoot -ChildPath $resolvedRel).Replace('\', '/')
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
        # Exclude E2E fixture directories: workspace/, sandbox-central-seed/, sandbox-central/,
        # synthetic-appdev/, synthetic-appdev-seed/, .rollback-worktree-*/. These are runtime
        # artifacts or deliberate copies of real central files for test consumption — their
        # frontmatter IDs (e.g. PF-SST-001 in script-soak-tracking.md) mirror the real artifact's
        # ID but live at the test-case path, which would otherwise be flagged as wrong-prefix.
        $pathSegments = $file.FullName.Replace('\', '/').Split('/')
        $isFixtureDir = $false
        foreach ($seg in $pathSegments) {
            if ($seg -in @('workspace', 'sandbox-central-seed', 'sandbox-central', 'synthetic-appdev', 'synthetic-appdev-seed') -or $seg -like '.rollback-worktree-*') {
                $isFixtureDir = $true
                break
            }
        }
        if ($isFixtureDir) { continue }

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
            $resolvedRel = Resolve-PrefixDirectoryPath -PrefixName $prefixName -RawPath $dirProp.Value
            $dirPath = Join-Path -Path $ProjectRoot -ChildPath $resolvedRel
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
