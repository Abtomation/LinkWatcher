# New-SourceStructure.ps1
# Scaffolds and maintains the source code directory structure and source-code-layout.md
# Dual-mode: -Scaffold for initial creation, -Update for maintenance

<#
.SYNOPSIS
    Creates or updates the source code directory structure and source-code-layout.md.

.DESCRIPTION
    This script has two modes:

    -Scaffold (first-time use during PF-TSK-064):
      - Reads feature tracking to get confirmed feature list
      - Reads language config for naming conventions
      - Creates source root directory (e.g., src/)
      - Creates shared/ directory
      - Creates feature directories (one per tracked feature)
      - Fills Project Configuration section in source-code-layout.md
      - Generates initial Directory Tree section in source-code-layout.md
      - Creates package marker files (e.g., __init__.py) if language requires them
      - Skips directories that already exist (safe for re-runs)

    -Update (maintenance mode):
      - Scans actual source directory on disk
      - Regenerates only the Directory Tree section in source-code-layout.md
      - Preserves all manual sections (Dependency Flow, File Placement, Scale Transition Notes)
      - Never creates or deletes directories
      - Called by New-FeatureImplementationState.ps1, code-touching tasks, and during validation

    Safety: This script never deletes directories, files, or overwrites human-authored content.

.PARAMETER Scaffold
    First-time mode: creates directories and generates initial source-code-layout.md content.

.PARAMETER Update
    Maintenance mode: regenerates Directory Tree section from actual file system.

.PARAMETER FeatureName
    Single feature name to create a directory for (used by New-FeatureImplementationState.ps1).
    Only valid with -Update. Creates the feature directory if it doesn't exist, then refreshes
    the Directory Tree.

.PARAMETER WhatIf
    Shows what would be created/changed without making changes.

.PARAMETER Confirm
    Prompts for confirmation before each action.

.EXAMPLE
    .\New-SourceStructure.ps1 -Scaffold

.EXAMPLE
    .\New-SourceStructure.ps1 -Update

.EXAMPLE
    .\New-SourceStructure.ps1 -Update -FeatureName "invoicing"

.NOTES
    - Requires doc/project-config.json with paths.source_code set
    - Requires languages-config/{language}/{language}-config.json with directoryStructure
    - For -Scaffold: requires doc/state-tracking/permanent/feature-tracking.md with features
    - Never destructive: never deletes directories or files
    - See PF-PRO-002 for design decisions

    Script Type: Infrastructure Scaffolding Script
    Created: 2026-04-06
    For: Source Code Layout Framework Extension (PF-PRO-002)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Scaffold,

    [Parameter(Mandatory = $false)]
    [switch]$Update,

    [Parameter(Mandatory = $false)]
    [string]$FeatureName = ""
)

# --- Validate mode selection ---
if (-not $Scaffold -and -not $Update) {
    Write-Error "You must specify either -Scaffold or -Update mode."
    exit 1
}
if ($Scaffold -and $Update) {
    Write-Error "Cannot use -Scaffold and -Update at the same time."
    exit 1
}
if ($Scaffold -and $FeatureName -ne "") {
    Write-Error "-FeatureName is only valid with -Update mode."
    exit 1
}

# --- Module Import ---
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
if ($dir) {
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
} else {
    Write-Error "Could not find Common-ScriptHelpers.psm1"
    exit 1
}

# --- Standard Initialization ---
try {
    Invoke-StandardScriptInitialization
} catch {
    Write-Warning "Standard initialization not available, proceeding with basic setup"
    $ErrorActionPreference = "Stop"
}

# --- Get Project Root ---
$projectRoot = Get-ProjectRoot

# --- Load project-config.json ---
$projectConfigPath = Join-Path $projectRoot "doc/project-config.json"
if (-not (Test-Path $projectConfigPath)) {
    Write-ProjectError -Message "doc/project-config.json not found. Run Project Initiation (PF-TSK-059) first." -ExitCode 1
}
$projectConfig = Get-Content $projectConfigPath -Raw | ConvertFrom-Json

# --- Resolve source root ---
$sourceCodePath = $projectConfig.paths.source_code
if ([string]::IsNullOrWhiteSpace($sourceCodePath) -or $sourceCodePath -eq ".") {
    Write-ProjectError -Message "paths.source_code in project-config.json is not set (or is '.'). Set it to the source directory name (e.g., 'src') first." -ExitCode 1
}
$sourceRootAbsolute = Join-Path $projectRoot $sourceCodePath

# --- Load language config ---
$language = $projectConfig.testing.language.ToLower()
$langConfigPath = Join-Path $projectRoot "languages-config/$language/$language-config.json"
if (-not (Test-Path $langConfigPath)) {
    # Try primary_language from project_metadata as fallback
    $language = $projectConfig.project_metadata.primary_language.ToLower()
    $langConfigPath = Join-Path $projectRoot "languages-config/$language/$language-config.json"
}
if (-not (Test-Path $langConfigPath)) {
    Write-ProjectError -Message "Language config not found at languages-config/$language/$language-config.json" -ExitCode 1
}
$langConfig = Get-Content $langConfigPath -Raw | ConvertFrom-Json
$dirStructure = $langConfig.directoryStructure

if (-not $dirStructure) {
    Write-ProjectError -Message "Language config $langConfigPath is missing the 'directoryStructure' section." -ExitCode 1
}

# --- Source layout doc path ---
$layoutDocPath = Join-Path $projectRoot "doc/technical/architecture/source-code-layout.md"

# --- Helper: Convert feature name to directory name using language naming convention ---
function ConvertTo-DirectoryName {
    param([string]$Name, [string]$Convention)
    # Strip leading version number pattern (e.g., "0.1.1 " or "1.1.3 ")
    $cleanName = $Name -replace '^\d+\.\d+\.\d+\s*[-–]?\s*', ''
    $cleanName = $cleanName.Trim()

    switch ($Convention) {
        "snake_case" {
            # Replace spaces, hyphens, special chars with underscore, lowercase
            $result = $cleanName -replace '[^a-zA-Z0-9]', '_'
            $result = $result -replace '_+', '_'
            $result = $result.Trim('_').ToLower()
            return $result
        }
        "kebab-case" {
            $result = $cleanName -replace '[^a-zA-Z0-9]', '-'
            $result = $result -replace '-+', '-'
            $result = $result.Trim('-').ToLower()
            return $result
        }
        "PascalCase" {
            $words = $cleanName -split '[^a-zA-Z0-9]+'
            $result = ($words | ForEach-Object {
                if ($_.Length -gt 0) { $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() }
            }) -join ''
            return $result
        }
        default {
            # Default to snake_case
            $result = $cleanName -replace '[^a-zA-Z0-9]', '_'
            $result = $result -replace '_+', '_'
            return $result.Trim('_').ToLower()
        }
    }
}

# --- Helper: Parse feature names from feature-tracking.md ---
function Get-FeatureNames {
    param([string]$FeatureTrackingPath)

    if (-not (Test-Path $FeatureTrackingPath)) {
        Write-ProjectError -Message "Feature tracking file not found: $FeatureTrackingPath" -ExitCode 1
    }

    $content = Get-Content $FeatureTrackingPath
    $features = @()

    foreach ($line in $content) {
        # Match table rows with feature IDs like "| [0.1.1](...) | Feature Name |" or "| 0.1.1 | Feature Name |"
        if ($line -match '^\|\s*(\[[\d.]+\]\([^)]+\)|[\d.]+)\s*\|\s*([^|]+?)\s*\|') {
            $featureName = $Matches[2].Trim()
            # Skip header rows and separator rows
            if ($featureName -ne "Feature" -and $featureName -ne "-------" -and $featureName -ne "--" -and $featureName -ne "") {
                $features += $featureName
            }
        }
    }

    return $features
}

# --- Helper: Generate directory tree string from actual file system ---
function Get-DirectoryTreeString {
    param([string]$RootPath, [string]$SourceRoot, [int]$Indent = 0)

    $prefix = "  " * $Indent
    $output = @()

    if (-not (Test-Path $RootPath)) {
        return $output
    }

    $dirs = Get-ChildItem -Path $RootPath -Directory | Sort-Object Name
    $files = Get-ChildItem -Path $RootPath -File | Sort-Object Name

    foreach ($d in $dirs) {
        # Skip __pycache__ and other common generated dirs
        if ($d.Name -eq "__pycache__" -or $d.Name -eq ".git" -or $d.Name -eq "node_modules" -or $d.Name -eq ".venv" -or $d.Name -eq "venv") {
            continue
        }
        $output += "$prefix$($d.Name)/"
        $output += Get-DirectoryTreeString -RootPath $d.FullName -SourceRoot $SourceRoot -Indent ($Indent + 1)
    }

    foreach ($f in $files) {
        $output += "${prefix}$($f.Name)"
    }

    return $output
}

# --- Helper: Generate the full directory tree block for the layout doc ---
function New-DirectoryTreeBlock {
    param([string]$SourceRootAbsolute, [string]$SourceCodePath)

    $treeLines = @()
    $treeLines += '```'
    $treeLines += "$SourceCodePath/"

    $childLines = Get-DirectoryTreeString -RootPath $SourceRootAbsolute -SourceRoot $SourceCodePath -Indent 1
    $treeLines += $childLines
    $treeLines += '```'

    return ($treeLines -join "`n")
}

# =========================================================================
# SCAFFOLD MODE
# =========================================================================
if ($Scaffold) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Source Structure Scaffold" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Source root: $sourceCodePath" -ForegroundColor Gray
    Write-Host "  Language: $language" -ForegroundColor Gray
    Write-Host "  Naming: $($dirStructure.directoryNaming)" -ForegroundColor Gray
    Write-Host ""

    $changesCount = 0

    # --- Step 1: Create source root directory ---
    if (-not (Test-Path $sourceRootAbsolute)) {
        if ($PSCmdlet.ShouldProcess($sourceRootAbsolute, "Create source root directory")) {
            New-Item -ItemType Directory -Path $sourceRootAbsolute -Force | Out-Null
            Write-Host "  Created: $sourceCodePath/" -ForegroundColor Green
            $changesCount++
        }
    } else {
        Write-Host "  Exists: $sourceCodePath/" -ForegroundColor Gray
    }

    # --- Step 2: Create shared directory ---
    $sharedDirName = $dirStructure.sharedDirectory
    $sharedDirPath = Join-Path $sourceRootAbsolute $sharedDirName
    if (-not (Test-Path $sharedDirPath)) {
        if ($PSCmdlet.ShouldProcess($sharedDirPath, "Create shared directory")) {
            New-Item -ItemType Directory -Path $sharedDirPath -Force | Out-Null
            Write-Host "  Created: $sourceCodePath/$sharedDirName/" -ForegroundColor Green
            $changesCount++
        }
    } else {
        Write-Host "  Exists: $sourceCodePath/$sharedDirName/" -ForegroundColor Gray
    }

    # --- Step 3: Create package markers in shared dir ---
    if ($dirStructure.packageMarkers) {
        foreach ($marker in $dirStructure.packageMarkers) {
            $markerPath = Join-Path $sharedDirPath $marker
            if (-not (Test-Path $markerPath)) {
                if ($PSCmdlet.ShouldProcess($markerPath, "Create package marker")) {
                    New-Item -ItemType File -Path $markerPath -Force | Out-Null
                    Write-Host "  Created: $sourceCodePath/$sharedDirName/$marker" -ForegroundColor Green
                    $changesCount++
                }
            }
        }
    }

    # --- Step 4: Create feature directories ---
    $featureTrackingPath = Join-Path $projectRoot "doc/state-tracking/permanent/feature-tracking.md"
    $featureNames = Get-FeatureNames -FeatureTrackingPath $featureTrackingPath

    if ($featureNames.Count -eq 0) {
        Write-Host "  No features found in feature-tracking.md — skipping feature directories" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "  Feature directories ($($featureNames.Count) features):" -ForegroundColor Cyan

        foreach ($name in $featureNames) {
            $dirName = ConvertTo-DirectoryName -Name $name -Convention $dirStructure.directoryNaming
            $featureDirPath = Join-Path $sourceRootAbsolute $dirName

            if (-not (Test-Path $featureDirPath)) {
                if ($PSCmdlet.ShouldProcess($featureDirPath, "Create feature directory for '$name'")) {
                    New-Item -ItemType Directory -Path $featureDirPath -Force | Out-Null
                    Write-Host "    Created: $sourceCodePath/$dirName/ ($name)" -ForegroundColor Green
                    $changesCount++
                }
            } else {
                Write-Host "    Exists: $sourceCodePath/$dirName/ ($name)" -ForegroundColor Gray
            }

            # Create package markers in feature dir
            if ($dirStructure.packageMarkers) {
                foreach ($marker in $dirStructure.packageMarkers) {
                    $markerPath = Join-Path $featureDirPath $marker
                    if (-not (Test-Path $markerPath)) {
                        if ($PSCmdlet.ShouldProcess($markerPath, "Create package marker")) {
                            New-Item -ItemType File -Path $markerPath -Force | Out-Null
                            $changesCount++
                        }
                    }
                }
            }
        }
    }

    # --- Step 5: Create package markers at source root ---
    if ($dirStructure.packageMarkers) {
        foreach ($marker in $dirStructure.packageMarkers) {
            $markerPath = Join-Path $sourceRootAbsolute $marker
            if (-not (Test-Path $markerPath)) {
                if ($PSCmdlet.ShouldProcess($markerPath, "Create package marker at source root")) {
                    New-Item -ItemType File -Path $markerPath -Force | Out-Null
                    Write-Host "  Created: $sourceCodePath/$marker" -ForegroundColor Green
                    $changesCount++
                }
            }
        }
    }

    # --- Step 6: Update source-code-layout.md ---
    if (Test-Path $layoutDocPath) {
        Write-Host ""
        Write-Host "  Updating source-code-layout.md..." -ForegroundColor Cyan

        $layoutContent = Get-Content $layoutDocPath -Raw

        # Fill Project Configuration table
        $configTable = @"
| Setting | Value |
|---------|-------|
| Source root | $sourceCodePath |
| Language | $language |
| Directory naming | $($dirStructure.directoryNaming) |
| File naming | $($dirStructure.fileNaming) |
| Shared directory | $($dirStructure.sharedDirectory) |
"@

        # Replace the placeholder Project Configuration table
        # Matches template placeholder: | Shared directory | [Shared Directory Name] |
        $configPattern = '(?s)\| Setting \| Value \|.*?\| Shared directory \| \[Shared Directory Name\] \|'
        if ($layoutContent -match $configPattern) {
            $layoutContent = $layoutContent -replace $configPattern, $configTable
            Write-Host "    Updated: Project Configuration section" -ForegroundColor Green
        } else {
            Write-Host "    Skipped: Project Configuration section (already filled or pattern not found)" -ForegroundColor Yellow
        }

        # Generate and replace Directory Tree section
        $treeBlock = New-DirectoryTreeBlock -SourceRootAbsolute $sourceRootAbsolute -SourceCodePath $sourceCodePath
        # Matches template placeholder tree: ```\n[Source Root]/\n...\n```
        $treePattern = '(?s)```\r?\n\[Source Root\]/.*?```'
        if ($layoutContent -match $treePattern) {
            $layoutContent = $layoutContent -replace $treePattern, $treeBlock
            Write-Host "    Updated: Directory Tree section (initial generation)" -ForegroundColor Green
        } else {
            # Also try replacing an existing tree block (re-run safety)
            $existingTreePattern = '(?s)(> \*\*Auto-generated\*\*[^\n]*\n> Do not edit manually\.[^\n]*\n\n)```[\s\S]*?```'
            if ($layoutContent -match $existingTreePattern) {
                $layoutContent = $layoutContent -replace '(?s)(> \*\*Auto-generated\*\*[^\n]*\n> Do not edit manually\.[^\n]*\n\n)```[\s\S]*?```', "`$1$treeBlock"
                Write-Host "    Updated: Directory Tree section (regenerated)" -ForegroundColor Green
            } else {
                Write-Host "    Skipped: Directory Tree section (pattern not found)" -ForegroundColor Yellow
            }
        }

        if ($PSCmdlet.ShouldProcess($layoutDocPath, "Write updated source-code-layout.md")) {
            Set-Content $layoutDocPath $layoutContent -Encoding UTF8
            $changesCount++
        }
    } else {
        Write-Host ""
        Write-Host "  Warning: source-code-layout.md not found at $layoutDocPath" -ForegroundColor Yellow
        Write-Host "  The layout document should exist at doc/technical/architecture/source-code-layout.md" -ForegroundColor Yellow
    }

    # --- Summary ---
    Write-Host ""
    $details = @(
        "Mode: Scaffold",
        "Source root: $sourceCodePath/",
        "Features: $($featureNames.Count) directories created/verified",
        "Changes: $changesCount"
    )
    if ($changesCount -eq 0) {
        $details += "", "All directories already exist - no changes needed (safe re-run)"
    } else {
        $details += @(
            "",
            "NEXT STEPS:",
            "1. Complete the Dependency Flow section in source-code-layout.md",
            "2. Complete the File Placement Decision Tree section",
            "3. Validate no application source files exist at repository root",
            "4. See process-framework/guides/00-setup/source-code-layout-guide.md for guidance"
        )
    }
    Write-ProjectSuccess -Message "Source structure scaffold complete" -Details $details
}

# =========================================================================
# UPDATE MODE
# =========================================================================
if ($Update) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Source Structure Update" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Source root: $sourceCodePath" -ForegroundColor Gray
    Write-Host ""

    $changesCount = 0

    # --- Step 1: Optionally create a single feature directory ---
    if ($FeatureName -ne "") {
        $dirName = ConvertTo-DirectoryName -Name $FeatureName -Convention $dirStructure.directoryNaming
        $featureDirPath = Join-Path $sourceRootAbsolute $dirName

        if (Test-Path $sourceRootAbsolute) {
            if (-not (Test-Path $featureDirPath)) {
                if ($PSCmdlet.ShouldProcess($featureDirPath, "Create feature directory for '$FeatureName'")) {
                    New-Item -ItemType Directory -Path $featureDirPath -Force | Out-Null
                    Write-Host "  Created: $sourceCodePath/$dirName/ ($FeatureName)" -ForegroundColor Green
                    $changesCount++

                    # Create package markers
                    if ($dirStructure.packageMarkers) {
                        foreach ($marker in $dirStructure.packageMarkers) {
                            $markerPath = Join-Path $featureDirPath $marker
                            if (-not (Test-Path $markerPath)) {
                                New-Item -ItemType File -Path $markerPath -Force | Out-Null
                                $changesCount++
                            }
                        }
                    }
                }
            } else {
                Write-Host "  Exists: $sourceCodePath/$dirName/ ($FeatureName)" -ForegroundColor Gray
            }
        } else {
            Write-Host "  Source root $sourceCodePath/ does not exist yet - skipping feature directory creation" -ForegroundColor Yellow
        }
    }

    # --- Step 2: Regenerate Directory Tree in source-code-layout.md ---
    if (-not (Test-Path $layoutDocPath)) {
        Write-Host "  source-code-layout.md not found - nothing to update" -ForegroundColor Yellow
        exit 0
    }

    if (-not (Test-Path $sourceRootAbsolute)) {
        Write-Host "  Source root $sourceCodePath/ does not exist - nothing to scan" -ForegroundColor Yellow
        exit 0
    }

    $layoutContent = Get-Content $layoutDocPath -Raw
    $treeBlock = New-DirectoryTreeBlock -SourceRootAbsolute $sourceRootAbsolute -SourceCodePath $sourceCodePath

    # Replace existing tree block (between the auto-generated note and the next section)
    # The tree block is between the "Do not edit manually." line and the next "##" heading
    $existingTreePattern = '(?s)(> \*\*Auto-generated\*\*[^\n]*\n> Do not edit manually\.[^\n]*\n\n)```[\s\S]*?```'
    $placeholderPattern = '(?s)(> \*\*Auto-generated\*\*[^\n]*\n> Do not edit manually\.[^\n]*\n\n)\[Generated by New-SourceStructure\.ps1\]'

    if ($layoutContent -match $existingTreePattern) {
        $newContent = $layoutContent -replace $existingTreePattern, "`$1$treeBlock"
        if ($newContent -ne $layoutContent) {
            if ($PSCmdlet.ShouldProcess($layoutDocPath, "Regenerate Directory Tree section")) {
                Set-Content $layoutDocPath $newContent -Encoding UTF8
                Write-Host "  Updated: Directory Tree section in source-code-layout.md" -ForegroundColor Green
                $changesCount++
            }
        } else {
            Write-Host "  No changes: Directory Tree is already up to date" -ForegroundColor Gray
        }
    } elseif ($layoutContent -match $placeholderPattern) {
        $newContent = $layoutContent -replace '\[Generated by New-SourceStructure\.ps1\]', $treeBlock
        if ($PSCmdlet.ShouldProcess($layoutDocPath, "Generate initial Directory Tree section")) {
            Set-Content $layoutDocPath $newContent -Encoding UTF8
            Write-Host "  Updated: Directory Tree section (initial generation)" -ForegroundColor Green
            $changesCount++
        }
    } else {
        Write-Host "  Warning: Could not find Directory Tree section pattern in source-code-layout.md" -ForegroundColor Yellow
    }

    # --- Summary ---
    Write-Host ""
    $details = @(
        "Mode: Update",
        "Source root: $sourceCodePath/"
    )
    if ($FeatureName -ne "") {
        $details += "Feature: $FeatureName"
    }
    $details += "Changes: $changesCount"
    Write-ProjectSuccess -Message "Source structure update complete" -Details $details
}

<#
.NOTES
TESTING CHECKLIST:
Before considering this script complete, test the following:

1. SCAFFOLD MODE TEST:
   - Run with -Scaffold on a project with features in feature-tracking.md
   - Verify source root, shared dir, and feature dirs are created
   - Verify package markers are created (e.g., __init__.py for Python)
   - Verify source-code-layout.md Project Configuration is filled
   - Verify source-code-layout.md Directory Tree is generated
   - Re-run -Scaffold and verify idempotent (no duplicate creation)

2. UPDATE MODE TEST:
   - Add a file to a feature directory manually
   - Run with -Update
   - Verify Directory Tree section is regenerated with the new file
   - Verify manual sections (Dependency Flow, File Placement, etc.) are preserved

3. UPDATE WITH -FeatureName TEST:
   - Run with -Update -FeatureName "new-feature"
   - Verify feature directory is created under source root
   - Verify Directory Tree is refreshed to include new directory

4. ERROR HANDLING TEST:
   - Test without -Scaffold or -Update (should error)
   - Test with both -Scaffold and -Update (should error)
   - Test without project-config.json (should error)
   - Test with paths.source_code = "." (should error)
   - Test without language config (should error)

5. SAFETY TEST:
   - Verify no directories are ever deleted
   - Verify manual sections in source-code-layout.md are never overwritten
   - Verify -WhatIf shows actions without executing

EXAMPLE TEST COMMANDS:
# Scaffold test
.\New-SourceStructure.ps1 -Scaffold -WhatIf

# Update test
.\New-SourceStructure.ps1 -Update

# Feature directory creation test
.\New-SourceStructure.ps1 -Update -FeatureName "test-feature"
#>
