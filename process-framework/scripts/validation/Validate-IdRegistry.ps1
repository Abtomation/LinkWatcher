#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Validates the ID registry against actual files in the repository, including a duplicate-ID scan
.DESCRIPTION
    This script checks for:
    - Files with wrong prefixes (e.g., TSK prefix in state-tracking directory)
    - Missing directory information in registry
    - Inconsistencies between registry and actual file locations
    - Duplicate IDs (PF-IMP-2011): two artifacts claiming one ID, across every pool's declared
      directories — the three shipped registries plus this workspace's own central/local registry —
      and the PF-IMP row pool (tracker + archive). Byte-identical claimants are reported separately
      as "identical copies" (a leftover copy, not an identity collision) and do not fail the run;
      distinct artifacts do.
.PARAMETER RegistryPath
    Validates against this single registry file instead of the default three (PF-id-registry.json,
    doc/PD-id-registry.json, test/TE-id-registry.json), whose prefixes are otherwise merged.
    Retained for backward compatibility. The duplicate scan then covers only that registry's pools.
.PARAMETER RootPath
    Root directory scanned for files to check against the registry. Defaults to the project's
    doc/ directory.
.PARAMETER Portfolio
    Chain root only (role framework-builder): extends the duplicate scan to the PORTFOLIO pools
    (Get-PortfolioPrefixes — PF-IMP, PF-PRO, PF-FEE, PF-REV, PF-EVR) across every active registered
    framework's process-framework-central/, tagging each claimant with its workspace. A race
    duplicate of a portfolio pool lands in two different centrals and is invisible to any
    single-workspace scan. Elsewhere the switch warns and is ignored.
.EXAMPLE
    ../Validate-IdRegistry.ps1
.EXAMPLE
    ../Validate-IdRegistry.ps1 -Portfolio
.NOTES
    OWNERSHIP: FWK-FB (FrameworkBuilder) - canonical at FrameworkBuilder; anywhere else a received copy. Edit only at the owning workspace. An agent may only modify files its workspace owns.
#>

param(
    [string]$RegistryPath = "",
    [string]$RootPath = "",
    [switch]$Portfolio
)

# Import the common helpers for Get-ProjectRoot
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
# IdRegistry.psm1 sits beside the umbrella; imported for Get-PortfolioPrefixes so the portfolio pool
# set is read from the minter, never re-listed here (PF-IMP-2011).
Import-Module (Join-Path $dir "IdRegistry.psm1") -Force

function Invoke-FileReadWithRetry {
    <#
    .SYNOPSIS
    Runs a file read, retrying a share violation for up to 5 s (100 ms steps); a missing file throws at once.
    #>
    param([Parameter(Mandatory)][scriptblock]$Read)
    $deadline = (Get-Date).AddSeconds(5)
    while ($true) {
        try { return (& $Read) }
        catch [System.IO.FileNotFoundException] { throw }
        catch [System.IO.DirectoryNotFoundException] { throw }
        catch [System.IO.IOException] {
            if ((Get-Date) -gt $deadline) { throw }
            Start-Sleep -Milliseconds 100
        }
    }
}

function Read-RegistryJson {
    <#
    .SYNOPSIS
    Loads a registry JSON file LOUDLY: a share violation is retried, then thrown — never swallowed.
    .DESCRIPTION
    The former bare `Get-Content | ConvertFrom-Json` turned a registry held by a parallel mint
    (IdRegistry.psm1 opens it FileShare.None for a few milliseconds) into a silent null: zero
    prefixes loaded, every check green over nothing (PF-IMP-2011 panel finding). Read through a
    retrying .NET call so contention waits and any other failure surfaces.
    #>
    param([Parameter(Mandatory)][string]$Path)
    $raw = Invoke-FileReadWithRetry -Read { [System.IO.File]::ReadAllText($Path) }
    return ($raw | ConvertFrom-Json -ErrorAction Stop)
}

function Test-FixturePath {
    <#
    .SYNOPSIS
    True for E2E fixture trees whose frontmatter IDs deliberately mirror real artifacts.
    .DESCRIPTION
    workspace/, sandbox-central-seed/, sandbox-central/, synthetic-appdev/, synthetic-appdev-seed/
    and .rollback-worktree-* are runtime artifacts or deliberate copies of real central files for
    test consumption — their IDs (e.g. PF-SST-001 in script-soak-tracking.md) mirror the real
    artifact's ID at the test-case path and would otherwise read as wrong-prefix or duplicate.
    #>
    param([Parameter(Mandatory)][string]$Path)
    foreach ($seg in $Path.Replace('\', '/').Split('/')) {
        if ($seg -in @('workspace', 'sandbox-central-seed', 'sandbox-central', 'synthetic-appdev', 'synthetic-appdev-seed') -or $seg -like '.rollback-worktree-*') {
            return $true
        }
    }
    return $false
}

function Get-FrontmatterId {
    <#
    .SYNOPSIS
    The `id:` declared in a markdown file's frontmatter block, or $null (body text never counts).
    #>
    param([AllowNull()][AllowEmptyString()][string]$Content)
    if ([string]::IsNullOrEmpty($Content)) { return $null }
    $c = $Content.TrimStart([char]0xFEFF)
    if (-not $c.StartsWith('---')) { return $null }
    $end = $c.IndexOf("`n---", 3)
    $block = if ($end -gt 0) { $c.Substring(0, $end) } else { $c.Substring(0, [Math]::Min($c.Length, 4000)) }
    if ($block -match '(?m)^id:\s*([A-Z]{2,4}-[A-Z0-9]{2,4}-\d+)\s*$') { return $matches[1] }
    return $null
}

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
$workspaceRole = Get-WorkspaceRole -ProjectRoot $ProjectRoot
$frameworkWritePath = if ($workspaceRole -in @('framework', 'framework-builder')) {
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
        $reg = Read-RegistryJson -Path $regFile
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
        # Exclude E2E fixture directories (see Test-FixturePath) — deliberate copies of real
        # artifacts whose IDs would otherwise be flagged as wrong-prefix.
        if (Test-FixturePath -Path $file.FullName) { continue }

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

# =========================================================================
# Check 4: Duplicate IDs (PF-IMP-2011)
# =========================================================================
# Two artifacts claiming one ID is the silent failure the transactional mint in IdRegistry.psm1
# now prevents at the counter; this check is the backstop for what the counter cannot see — a
# historical manual assignment, a mint racing a pool move, a copy left behind by a relocation.
# Three scan surfaces:
#   1. File identities — every pool's declared directories: the three shipped registries PLUS this
#      workspace's own central/local registry (which Checks 1-3 never load), `id:` frontmatter
#      grouped by ID. Nested declared directories are visited once.
#   2. The PF-IMP row pool — IMP rows live as `| PF-IMP-NNNN |` cells in the central tracker and
#      its archive, not as files; escalation MOVES a row between centrals, so any ID seen twice
#      is a genuine duplicate.
#   3. -Portfolio (chain root only) — the portfolio pools scanned across every active registered
#      framework's central as well, claimants tagged by workspace.
# Byte-identical claimants are a separate "identical copy" class (a leftover copy — drift, not an
# identity collision) and do not fail the run; distinct artifacts do.
Write-Host "🔁 Checking for duplicate IDs$(if ($Portfolio) { ' (portfolio-wide)' })..." -ForegroundColor Yellow

$idClaims = @{}   # ID -> List of claimants @{ Id; Location (workspace-relative display); FullPath; Workspace; Kind ('file' | 'row') }

function Add-IdClaim {
    param([string]$Id, [string]$Location, [string]$FullPath, [string]$Workspace, [string]$Kind)
    if (-not $idClaims.ContainsKey($Id)) { $idClaims[$Id] = [System.Collections.Generic.List[object]]::new() }
    if ($Kind -eq 'file' -and ($idClaims[$Id] | Where-Object { $_.Kind -eq 'file' -and $_.FullPath -eq $FullPath })) { return }
    $idClaims[$Id].Add([pscustomobject]@{ Id = $Id; Location = $Location; FullPath = $FullPath; Workspace = $Workspace; Kind = $Kind })
}

function ConvertTo-WorkspaceRelative {
    param([string]$FullPath, [string]$WorkspaceRoot)
    $root = $WorkspaceRoot.Replace('\', '/').TrimEnd('/')
    $full = $FullPath.Replace('\', '/')
    if ($full.StartsWith("$root/", [System.StringComparison]::OrdinalIgnoreCase)) { return $full.Substring($root.Length + 1) }
    return $full
}

function Invoke-DuplicateFileScan {
    # Every *.md under the given directories (nested ones collapsed so a file is visited once),
    # fixture trees skipped; -OnlyPrefixes narrows the recorded claims to the named pools.
    param([string[]]$Directories, [string]$Workspace, [string]$WorkspaceRoot, [string[]]$OnlyPrefixes = @())
    $tops = @()
    foreach ($d in (@($Directories | ForEach-Object { $_.Replace('\', '/').TrimEnd('/') } | Sort-Object -Unique) | Sort-Object { $_.Length })) {
        if (-not ($tops | Where-Object { $d.StartsWith("$_/", [System.StringComparison]::OrdinalIgnoreCase) })) { $tops += $d }
    }
    foreach ($top in $tops) {
        if (-not (Test-Path -LiteralPath $top -PathType Container)) { continue }
        foreach ($file in (Get-ChildItem -LiteralPath $top -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue)) {
            if (Test-FixturePath -Path $file.FullName) { continue }
            $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
            $id = Get-FrontmatterId -Content $content
            if (-not $id) { continue }
            if ($OnlyPrefixes.Count -gt 0 -and (($id -replace '-\d+$', '') -notin $OnlyPrefixes)) { continue }
            Add-IdClaim -Id $id -Location (ConvertTo-WorkspaceRelative -FullPath $file.FullName -WorkspaceRoot $WorkspaceRoot) -FullPath $file.FullName -Workspace $Workspace -Kind 'file'
        }
    }
}

function Invoke-DuplicateRowScan {
    # The PF-IMP row pool: tracker + archive under a central's state-tracking/permanent/.
    param([string]$CentralRoot, [string]$Workspace, [string]$WorkspaceRoot)
    foreach ($rel in @('state-tracking/permanent/process-improvement-tracking.md', 'state-tracking/permanent/archive/process-improvement-tracking-archive.md')) {
        $path = Join-Path $CentralRoot $rel
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $lines = Invoke-FileReadWithRetry -Read { [System.IO.File]::ReadAllLines($path) }
        $display = ConvertTo-WorkspaceRelative -FullPath $path -WorkspaceRoot $WorkspaceRoot
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\|\s*(PF-IMP-\d+)\s*\|') {
                Add-IdClaim -Id $matches[1] -Location "$display`:$($i + 1)" -FullPath $path -Workspace $Workspace -Kind 'row'
            }
        }
    }
}

# This workspace's label, for the report.
$ownLabel = 'this-workspace'
try {
    $ownCfg = Get-Content -LiteralPath (Join-Path $ProjectRoot 'doc/project-config.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($ownCfg.project_id) { $ownLabel = [string]$ownCfg.project_id }
} catch { }

# Pools for the local scan: the merged shipped registries plus the own central/local registry
# (role-routed exactly as IdRegistry.psm1 Resolve-LocalRegistryPath routes the mints).
$dupPools = @{}
foreach ($p in $registry.prefixes.PSObject.Properties) { $dupPools[$p.Name] = $p.Value }
$ownRegistry = $null
$ownRegistryPath = if ($workspaceRole -in @('framework', 'framework-builder')) {
    Join-Path $ProjectRoot 'process-framework-central/PF-id-registry-central.json'
} else {
    Join-Path $ProjectRoot 'doc/state-tracking/PF-id-registry-local.json'
}
if ([string]::IsNullOrWhiteSpace($RegistryPath) -and (Test-Path -LiteralPath $ownRegistryPath)) {
    $ownRegistry = Read-RegistryJson -Path $ownRegistryPath
    foreach ($p in $ownRegistry.prefixes.PSObject.Properties) { $dupPools[$p.Name] = $p.Value }
    Write-Host "  Loaded: $(Split-Path $ownRegistryPath -Leaf) ($(@($ownRegistry.prefixes.PSObject.Properties).Count) pools, duplicate scan)" -ForegroundColor Gray
}

$localScanDirs = @()
foreach ($poolName in $dupPools.Keys) {
    $pool = $dupPools[$poolName]
    if (-not $pool.directories) { continue }
    foreach ($dirProp in $pool.directories.PSObject.Properties) {
        if ($dirProp.Name -eq 'default') { continue }
        $localScanDirs += (Join-Path -Path $ProjectRoot -ChildPath (Resolve-PrefixDirectoryPath -PrefixName $poolName -RawPath $dirProp.Value))
    }
}
Invoke-DuplicateFileScan -Directories $localScanDirs -Workspace $ownLabel -WorkspaceRoot $ProjectRoot
Invoke-DuplicateRowScan -CentralRoot (Join-Path $ProjectRoot 'process-framework-central') -Workspace $ownLabel -WorkspaceRoot $ProjectRoot

if ($Portfolio) {
    if ($workspaceRole -ne 'framework-builder') {
        Write-Host "  WARNING: -Portfolio scans registered frameworks from the chain root (role framework-builder); this workspace declares role '$workspaceRole' — portfolio scan skipped" -ForegroundColor Yellow
    } elseif (-not $ownRegistry) {
        Write-Host "  WARNING: -Portfolio needs this workspace's PF-id-registry-central.json for the portfolio pools' declared directories — portfolio scan skipped" -ForegroundColor Yellow
    } else {
        $childInfo = Get-ChildRegistryInfo -ProjectRoot $ProjectRoot
        $childRegistry = Read-RegistryJson -Path (Join-Path $ProjectRoot "process-framework-central/$($childInfo.FileName)")
        $portfolioPools = @(Get-PortfolioPrefixes)
        # Central-relative declared directories of the portfolio pools, as this (root) central declares them.
        $poolDirs = @()
        foreach ($poolName in $portfolioPools) {
            $pool = $ownRegistry.prefixes.$poolName
            if (-not $pool -or -not $pool.directories) { continue }
            foreach ($dirProp in $pool.directories.PSObject.Properties) { if ($dirProp.Name -ne 'default') { $poolDirs += $dirProp.Value } }
        }
        foreach ($row in $childRegistry.($childInfo.CollectionKey).PSObject.Properties) {
            $childKey = $row.Name
            $child = $row.Value
            $childRole = if ($child.PSObject.Properties.Name -contains 'role' -and $child.role) { [string]$child.role } else { 'project' }
            if ($childRole -notin $childInfo.AcceptedChildRoles) { continue }
            if ($childKey -match $childInfo.SandboxKeyPattern) { continue }
            if ($child.PSObject.Properties.Name -contains 'status' -and $child.status -and $child.status -ne 'active') { continue }
            $childRoot = [string]$child.path
            if (-not $childRoot -or -not (Test-Path -LiteralPath $childRoot -PathType Container)) {
                Write-Host "  WARNING: $childKey path not found ($childRoot) — skipped" -ForegroundColor Yellow
                continue
            }
            $childCentral = Join-Path $childRoot 'process-framework-central'
            if (-not (Test-Path -LiteralPath $childCentral -PathType Container)) {
                Write-Host "  WARNING: $childKey has no process-framework-central/ — skipped" -ForegroundColor Yellow
                continue
            }
            Write-Host "  Portfolio: scanning $childKey ($childRoot)" -ForegroundColor Gray
            Invoke-DuplicateFileScan -Directories @($poolDirs | ForEach-Object { Join-Path $childRoot $_ }) -Workspace $childKey -WorkspaceRoot $childRoot -OnlyPrefixes $portfolioPools
            Invoke-DuplicateRowScan -CentralRoot $childCentral -Workspace $childKey -WorkspaceRoot $childRoot
        }
    }
}

# Classify: every ID with two or more claimants; byte-identical files are the "identical copy" class.
$duplicateDistinct  = @()
$duplicateIdentical = @()
foreach ($id in ($idClaims.Keys | Sort-Object)) {
    $claims = $idClaims[$id]
    if ($claims.Count -lt 2) { continue }
    $identical = $false
    if (@($claims | Where-Object { $_.Kind -ne 'file' }).Count -eq 0) {
        $hashes = @($claims | ForEach-Object { (Get-FileHash -LiteralPath $_.FullPath -Algorithm SHA256).Hash } | Sort-Object -Unique)
        $identical = ($hashes.Count -eq 1)
    }
    $finding = [PSCustomObject]@{ Id = $id; Claimants = @($claims); Identical = $identical }
    if ($identical) { $duplicateIdentical += $finding } else { $duplicateDistinct += $finding }
}

if ($duplicateDistinct.Count -gt 0) {
    Write-Host "❌ Found duplicate IDs (distinct artifacts claiming one ID):" -ForegroundColor Red
    foreach ($f in $duplicateDistinct) {
        Write-Host "  $($f.Id) ($($f.Claimants.Count) claimants)" -ForegroundColor Red
        foreach ($c in $f.Claimants) { Write-Host "      [$($c.Workspace)] $($c.Location)" -ForegroundColor Red }
    }
} else {
    Write-Host "✅ No duplicate IDs among distinct artifacts" -ForegroundColor Green
}
if ($duplicateIdentical.Count -gt 0) {
    Write-Host "⚠️  Identical copies sharing one ID (leftover copies — drift, not an identity collision):" -ForegroundColor Yellow
    foreach ($f in $duplicateIdentical) {
        Write-Host "  $($f.Id) ($($f.Claimants.Count) copies)" -ForegroundColor Yellow
        foreach ($c in $f.Claimants) { Write-Host "      [$($c.Workspace)] $($c.Location)" -ForegroundColor Yellow }
    }
}

Write-Host ""

# Summary
Write-Host "📊 Validation Summary:" -ForegroundColor Cyan
Write-Host "  Wrong prefix files: $($wrongPrefixFiles.Count)" -ForegroundColor $(if ($wrongPrefixFiles.Count -eq 0) { "Green" } else { "Red" })
Write-Host "  Missing directories: $($missingDirectories.Count)" -ForegroundColor $(if ($missingDirectories.Count -eq 0) { "Green" } else { "Red" })
Write-Host "  Invalid directories: $($invalidDirectories.Count)" -ForegroundColor $(if ($invalidDirectories.Count -eq 0) { "Green" } else { "Red" })
Write-Host "  Duplicate IDs (distinct artifacts): $($duplicateDistinct.Count)" -ForegroundColor $(if ($duplicateDistinct.Count -eq 0) { "Green" } else { "Red" })
Write-Host "  Duplicate IDs (identical copies): $($duplicateIdentical.Count)" -ForegroundColor $(if ($duplicateIdentical.Count -eq 0) { "Green" } else { "Yellow" })

if ($wrongPrefixFiles.Count -eq 0 -and $missingDirectories.Count -eq 0 -and $invalidDirectories.Count -eq 0 -and $duplicateDistinct.Count -eq 0) {
    Write-Host ""
    Write-Host "🎉 Registry validation completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "⚠️  Registry validation found issues that need attention." -ForegroundColor Yellow
    exit 1
}
