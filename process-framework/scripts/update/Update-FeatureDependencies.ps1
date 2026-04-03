<#
.SYNOPSIS
    Auto-generates the Feature Dependencies Map (feature-dependencies.md) from feature state files.

.DESCRIPTION
    Reads all *-implementation-state.md files in doc/state-tracking/features/, parses their
    "## 6. Dependencies" sections to extract dependency edges, reads feature-tracking.md
    for status/tier/priority metadata, and generates:
    - A Mermaid dependency graph (color-coded by phase)
    - A feature priority matrix table
    Writes the result to doc/technical/feature-dependencies.md.

.PARAMETER WhatIf
    Shows what would be generated without writing the file.

.PARAMETER Force
    Overwrites the output file even if it appears up to date.

.EXAMPLE
    .\Update-FeatureDependencies.ps1
    .\Update-FeatureDependencies.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# --- Resolve paths ---
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$featuresDir = Join-Path $projectRoot 'doc/state-tracking/features'
$trackingFile = Join-Path $projectRoot 'doc/state-tracking/permanent/feature-tracking.md'
$outputFile = Join-Path $projectRoot 'doc/technical/feature-dependencies.md'

# --- Parse feature state files ---
$stateFiles = Get-ChildItem -Path $featuresDir -Filter '*-implementation-state.md' | Sort-Object Name

$features = @{}       # key = feature ID (e.g. "0.1.1"), value = hashtable
$dependsOn = @{}      # key = feature ID, value = list of feature IDs it depends on

foreach ($file in $stateFiles) {
    # Extract feature ID from filename (e.g., "0.1.1" from "0.1.1-core-architecture-implementation-state.md")
    if ($file.Name -match '^(\d+\.\d+\.\d+)-(.+)-implementation-state\.md$') {
        $featureId = $Matches[1]
        $featureName = ($Matches[2] -replace '-', ' ')
        # Title-case the feature name
        $featureName = (Get-Culture).TextInfo.ToTitleCase($featureName)
    } else {
        # Handle filenames with spaces (e.g., "6.1.1-Link Validation-implementation-state.md")
        if ($file.Name -match '^(\d+\.\d+\.\d+)-(.+)-implementation-state\.md$') {
            $featureId = $Matches[1]
            $featureName = $Matches[2]
        } else {
            Write-Warning "Skipping unrecognized file: $($file.Name)"
            continue
        }
    }

    $features[$featureId] = @{
        Name = $featureName
        File = $file.Name
    }

    # Read file content and extract dependency section
    $content = Get-Content -Path $file.FullName -Raw

    # Find "This Feature Depends On" section
    $deps = @()
    if ($content -match '(?s)\*\*This Feature Depends On\*\*:\s*\n(.*?)(?=\n\*\*Other Features Depend On This\*\*:|\n### System Dependencies)') {
        $depsBlock = $Matches[1]

        # Extract feature IDs from dependency links like:
        # - **[PF-FEA-046: Core Architecture](./0.1.1-core-architecture-implementation-state.md)**
        $linkPattern = '\(\.?/?(\d+\.\d+\.\d+)-[^)]+implementation-state\.md\)'
        $linkMatches = [regex]::Matches($depsBlock, $linkPattern)
        foreach ($m in $linkMatches) {
            $deps += $m.Groups[1].Value
        }

        # Handle special case: "All features 0.x.x through 3.x.x"
        if ($depsBlock -match 'All features') {
            # This is a broad dependency (e.g., test suite depends on everything)
            # We'll mark it specially
            $features[$featureId]['DependsOnAll'] = $true
        }
    }

    $dependsOn[$featureId] = $deps
}

# --- Parse feature-tracking.md for metadata ---
$trackingContent = Get-Content -Path $trackingFile -Raw

# Extract metadata per feature from tracking tables
foreach ($fId in @($features.Keys)) {
    # Match table rows containing the feature ID
    # Pattern: |  [0.1.1](...) | Feature Name | Status | Priority | Tier | ...
    $escapedId = [regex]::Escape($fId)
    if ($trackingContent -match "(?m)\|\s*\[$escapedId\].*?\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*(P\d)\s*\|\s*\[([^\]]+)\]") {
        $features[$fId]['TrackingName'] = $Matches[1].Trim()
        $features[$fId]['Status'] = $Matches[2].Trim()
        $features[$fId]['Priority'] = $Matches[3].Trim()
        $features[$fId]['Tier'] = $Matches[4].Trim()
    }
}

# --- Determine phase grouping ---
function Get-Phase([string]$featureId) {
    $major = [int]($featureId.Split('.')[0])
    switch ($major) {
        0 { return 'Foundation' }
        1 { return 'File Watching' }
        2 { return 'Link Processing' }
        3 { return 'Monitoring' }
        4 { return 'Testing' }
        5 { return 'CI/CD' }
        6 { return 'Validation' }
        default { return 'Other' }
    }
}

# --- Build Mermaid graph ---
$mermaidLines = @()
$mermaidLines += 'graph TD'
$mermaidLines += ''

# Define node styles per phase
$mermaidLines += '    classDef foundation fill:#e8d5e8,stroke:#9b59b6,color:#2c0735'
$mermaidLines += '    classDef filewatching fill:#d5e8f9,stroke:#2980b9,color:#0a3d62'
$mermaidLines += '    classDef linkprocessing fill:#d5f5e3,stroke:#27ae60,color:#0b3d17'
$mermaidLines += '    classDef monitoring fill:#fdebd0,stroke:#e67e22,color:#5d2c06'
$mermaidLines += '    classDef testing fill:#fadbd8,stroke:#e74c3c,color:#5a0a0a'
$mermaidLines += '    classDef cicd fill:#d6eaf8,stroke:#3498db,color:#1a3c5e'
$mermaidLines += '    classDef validation fill:#f9e79f,stroke:#f39c12,color:#5d4e00'
$mermaidLines += ''

# Create nodes
$sortedIds = $features.Keys | Sort-Object { [version]$_ }
foreach ($fId in $sortedIds) {
    $f = $features[$fId]
    $displayName = if ($f['TrackingName']) { $f['TrackingName'] } else { $f['Name'] }
    $nodeId = 'F' + ($fId -replace '\.', '_')
    $mermaidLines += "    $nodeId[`"$fId $displayName`"]"
}
$mermaidLines += ''

# Create edges
foreach ($fId in $sortedIds) {
    $nodeId = 'F' + ($fId -replace '\.', '_')
    foreach ($depId in ($dependsOn[$fId] | Sort-Object { [version]$_ })) {
        if ($features.ContainsKey($depId)) {
            $depNodeId = 'F' + ($depId -replace '\.', '_')
            $mermaidLines += "    $nodeId --> $depNodeId"
        }
    }
    # Handle "depends on all" (e.g., 4.1.1 Test Suite)
    if ($features[$fId]['DependsOnAll']) {
        foreach ($targetId in ($features.Keys | Where-Object { $_ -ne $fId -and [int]($_.Split('.')[0]) -le 3 } | Sort-Object { [version]$_ })) {
            $targetNodeId = 'F' + ($targetId -replace '\.', '_')
            $mermaidLines += "    $nodeId -.-> $targetNodeId"
        }
    }
}
$mermaidLines += ''

# Apply classes
foreach ($fId in $sortedIds) {
    $nodeId = 'F' + ($fId -replace '\.', '_')
    $phase = Get-Phase $fId
    $className = $phase.ToLower() -replace '[/ ]', ''
    $mermaidLines += "    class $nodeId $className"
}

$mermaidDiagram = $mermaidLines -join "`n"

# --- Build priority matrix ---
$matrixLines = @()
$matrixLines += '| Feature ID | Feature Name | Phase | Dependencies | Priority | Tier | Status |'
$matrixLines += '|------------|-------------|-------|-------------|----------|------|--------|'

foreach ($fId in $sortedIds) {
    $f = $features[$fId]
    $displayName = if ($f['TrackingName']) { $f['TrackingName'] } else { $f['Name'] }
    $phase = Get-Phase $fId
    $deps = if ($dependsOn[$fId].Count -gt 0) {
        ($dependsOn[$fId] | Sort-Object { [version]$_ }) -join ', '
    } elseif ($f['DependsOnAll']) {
        'All 0.x.x-3.x.x'
    } else {
        '—'
    }
    $priority = if ($f['Priority']) { $f['Priority'] } else { '—' }
    $tier = if ($f['Tier']) { $f['Tier'] } else { '—' }
    $status = if ($f['Status']) { $f['Status'] } else { '—' }

    $matrixLines += "| $fId | $displayName | $phase | $deps | $priority | $tier | $status |"
}

$matrixTable = $matrixLines -join "`n"

# --- Compose output ---
$generatedDate = Get-Date -Format 'yyyy-MM-dd'
$featureCount = $features.Count
$edgeCount = ($dependsOn.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum

$output = @"
---
id: PD-DES-001
type: Product Documentation
category: Technical Design
version: 2.0
created: 2023-06-15
updated: $generatedDate
generated: true
---

# Feature Dependencies Map

> **Auto-generated** by `Update-FeatureDependencies.ps1` on $generatedDate.
> Source: feature state files in `doc/state-tracking/features/`.
> Do not edit manually — changes will be overwritten on next generation.

This document maps the dependencies between features ($featureCount features, $edgeCount dependency edges).

## Dependency Visualization

``````mermaid
$mermaidDiagram
``````

**Legend**: Solid arrows (``-->``) = direct dependency. Dashed arrows (``-.->```) = broad dependency (e.g., test suite exercises all components).

**Color coding by phase**:
- 🟣 Foundation (0.x.x) — Core architecture, database, configuration
- 🔵 File Watching (1.x.x) — File system monitoring
- 🟢 Link Processing (2.x.x) — Parsing and updating
- 🟠 Monitoring (3.x.x) — Logging system
- 🔴 Testing (4.x.x) — Test infrastructure
- 💠 CI/CD (5.x.x) — Build and deployment
- 🟡 Validation (6.x.x) — Link validation

## Feature Priority Matrix

$matrixTable

## Dependency Summary

### Most Depended-On Features (highest fan-in)

"@

# Calculate fan-in (how many features depend on each)
$fanIn = @{}
foreach ($fId in $features.Keys) { $fanIn[$fId] = 0 }
foreach ($fId in $dependsOn.Keys) {
    foreach ($depId in $dependsOn[$fId]) {
        if ($fanIn.ContainsKey($depId)) {
            $fanIn[$depId]++
        }
    }
}

$fanInSorted = $fanIn.GetEnumerator() | Sort-Object Value -Descending | Where-Object { $_.Value -gt 0 }
foreach ($entry in $fanInSorted) {
    $fId = $entry.Key
    $count = $entry.Value
    $displayName = if ($features[$fId]['TrackingName']) { $features[$fId]['TrackingName'] } else { $features[$fId]['Name'] }
    $output += "`n- **$fId $displayName**: $count features depend on this"
}

$output += @"


### Features With No Dependencies (root nodes)

"@

$rootNodes = $dependsOn.GetEnumerator() | Where-Object { $_.Value.Count -eq 0 -and -not $features[$_.Key]['DependsOnAll'] } | Sort-Object { [version]$_.Key }
foreach ($entry in $rootNodes) {
    $fId = $entry.Key
    $displayName = if ($features[$fId]['TrackingName']) { $features[$fId]['TrackingName'] } else { $features[$fId]['Name'] }
    $output += "`n- **$fId $displayName**"
}

# --- Write output ---
if ($PSCmdlet.ShouldProcess($outputFile, 'Generate feature dependencies map')) {
    # Ensure output directory exists
    $outputDir = Split-Path $outputFile
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    Set-Content -Path $outputFile -Value $output -Encoding UTF8
    Write-Host "Generated feature dependencies map:" -ForegroundColor Green
    Write-Host "  Features: $featureCount" -ForegroundColor Cyan
    Write-Host "  Dependency edges: $edgeCount" -ForegroundColor Cyan
    Write-Host "  Output: $outputFile" -ForegroundColor Cyan
} else {
    Write-Host "Would generate feature dependencies map:" -ForegroundColor Yellow
    Write-Host "  Features: $featureCount" -ForegroundColor Cyan
    Write-Host "  Dependency edges: $edgeCount" -ForegroundColor Cyan
    Write-Host "  Output: $outputFile" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $output
}
