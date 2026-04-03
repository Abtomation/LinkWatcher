#!/usr/bin/env pwsh

<#
.SYNOPSIS
    One-time bulk fix script for YAML frontmatter metadata schema conformance (IMP-376).
.DESCRIPTION
    Applies standard metadata schemas from domain-config.json to all process framework
    markdown artifacts. Only modifies YAML frontmatter (between first two --- markers).
    Body content is never touched.

    Fixes applied:
    1. type field: Document/Product Documentation/Documentation -> Process Framework
    2. category field: General -> Guide (guides), General -> Context Map (context maps)
    3. Removes redundant fields from frontmatter only:
       - Guides: guide_title, guide_status, guide_description, guide_category
       - Context maps: task_name, map_type, visualization_type
    4. Renames related_tasks -> related_task (in frontmatter only)
.PARAMETER ProjectRoot
    Path to the project root directory. Defaults to auto-detection.
.PARAMETER WhatIf
    Preview changes without writing files.
.EXAMPLE
    .\Fix-MetadataSchema.ps1 -WhatIf
.EXAMPLE
    .\Fix-MetadataSchema.ps1
#>

param(
    [string]$ProjectRoot = "",
    [switch]$WhatIf
)

# --- Resolve project root ---
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $dir = $PSScriptRoot
    while ($dir -and !(Test-Path (Join-Path $dir "CLAUDE.md"))) {
        $dir = Split-Path -Parent $dir
    }
    if (-not $dir) {
        Write-Error "Could not auto-detect project root"
        exit 1
    }
    $ProjectRoot = $dir
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Metadata Schema Fix (IMP-376)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Project Root: $ProjectRoot" -ForegroundColor Gray
if ($WhatIf) { Write-Host "MODE: DRY RUN (no files will be modified)" -ForegroundColor Yellow }
Write-Host ""

# --- Define artifact type -> directory mapping ---
$artifactTypes = @{
    "guide" = @{
        dir = "process-framework/guides"
        fixCategory = "Guide"
        removeFields = @("guide_title", "guide_status", "guide_description", "guide_category")
    }
    "context_map" = @{
        dir = "process-framework/visualization/context-maps"
        fixCategory = "Context Map"
        removeFields = @("task_name", "map_type", "visualization_type")
    }
    "task" = @{
        dir = "process-framework/tasks"
        fixCategory = $null  # Tasks already use correct category
        removeFields = @()
    }
    "template" = @{
        dir = "process-framework/templates"
        fixCategory = $null  # Templates already use correct category
        removeFields = @()
    }
}

$totalFiles = 0
$modifiedFiles = 0
$skippedFiles = 0
$changeLog = @()

foreach ($artifactType in $artifactTypes.Keys) {
    $config = $artifactTypes[$artifactType]
    $searchDir = Join-Path $ProjectRoot $config.dir
    if (-not (Test-Path $searchDir)) { continue }

    $mdFiles = Get-ChildItem -Path $searchDir -Filter "*.md" -Recurse -File | Where-Object {
        $_.Name -ne "README.md"
    }

    foreach ($file in $mdFiles) {
        $totalFiles++
        $relPath = $file.FullName.Substring($ProjectRoot.Length + 1) -replace '\\', '/'
        $rawContent = Get-Content $file.FullName -Raw -Encoding UTF8

        # --- Extract frontmatter boundaries ---
        # Match the first --- block. Use byte-accurate positions.
        if ($rawContent -notmatch '^---\s*\r?\n') {
            continue  # No frontmatter
        }

        # Find the second --- marker
        $firstDashEnd = $rawContent.IndexOf("`n") + 1
        $secondDashPos = $rawContent.IndexOf("`n---", $firstDashEnd)
        if ($secondDashPos -lt 0) { continue }

        # Include the closing --- line
        $closingLineEnd = $rawContent.IndexOf("`n", $secondDashPos + 1)
        if ($closingLineEnd -lt 0) { $closingLineEnd = $rawContent.Length }

        $frontmatter = $rawContent.Substring($firstDashEnd, $secondDashPos - $firstDashEnd)
        $bodyContent = $rawContent.Substring($closingLineEnd)

        $originalFrontmatter = $frontmatter
        $changes = @()

        # --- Fix 1: type field ---
        if ($frontmatter -match '(?m)^type:\s*(Document|Product Documentation|Documentation)\s*$') {
            $oldType = $Matches[1]
            $frontmatter = $frontmatter -replace "(?m)^type:\s*$([regex]::Escape($oldType))\s*$", "type: Process Framework"
            $changes += "type: '$oldType' -> 'Process Framework'"
        }

        # --- Fix 2: category field (only for types with fixCategory) ---
        if ($config.fixCategory) {
            if ($frontmatter -match '(?m)^category:\s*General\s*$') {
                $frontmatter = $frontmatter -replace '(?m)^category:\s*General\s*$', "category: $($config.fixCategory)"
                $changes += "category: 'General' -> '$($config.fixCategory)'"
            }
        }

        # --- Fix 3: Remove redundant fields ---
        foreach ($field in $config.removeFields) {
            if ($frontmatter -match "(?m)^$([regex]::Escape($field)):\s*.*$") {
                $oldLine = $Matches[0]
                # Remove the line and any trailing newline
                $frontmatter = $frontmatter -replace "(?m)^$([regex]::Escape($field)):.*\r?\n", ""
                $changes += "removed: $field"
            }
        }

        # --- Fix 4: Rename related_tasks -> related_task ---
        if ($frontmatter -match '(?m)^related_tasks:\s*(.*)$') {
            $value = $Matches[1]
            $frontmatter = $frontmatter -replace '(?m)^related_tasks:\s*', "related_task: "
            $changes += "renamed: related_tasks -> related_task"
        }

        # --- Apply if changed ---
        if ($changes.Count -gt 0) {
            $modifiedFiles++
            $changeLog += [PSCustomObject]@{
                File = $relPath
                Changes = $changes -join "; "
            }

            if ($WhatIf) {
                Write-Host "  [WOULD FIX] $relPath" -ForegroundColor Yellow
                foreach ($c in $changes) {
                    Write-Host "    - $c" -ForegroundColor Gray
                }
            } else {
                $newContent = $rawContent.Substring(0, $firstDashEnd) + $frontmatter + $rawContent.Substring($secondDashPos)
                Set-Content -Path $file.FullName -Value $newContent -NoNewline -Encoding UTF8
                Write-Host "  [FIXED] $relPath" -ForegroundColor Green
                foreach ($c in $changes) {
                    Write-Host "    - $c" -ForegroundColor Gray
                }
            }
        } else {
            $skippedFiles++
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Total files scanned: $totalFiles" -ForegroundColor Gray
Write-Host "  Files modified:      $modifiedFiles" -ForegroundColor $(if ($modifiedFiles -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Files skipped:       $skippedFiles" -ForegroundColor Gray

if ($WhatIf -and $modifiedFiles -gt 0) {
    Write-Host ""
    Write-Host "  Run without -WhatIf to apply changes." -ForegroundColor Yellow
}
