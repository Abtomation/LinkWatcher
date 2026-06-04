#!/usr/bin/env pwsh

<#
.SYNOPSIS
Atomic level-aware mutation of feature-tracking.md — creates a category, subgroup, or feature row
in one idempotent invocation, with optional chain to New-TestInfrastructure.ps1 -Update for
test/audit directory scaffolding.

.DESCRIPTION
The level is inferred from the dot-count in -Id:
  - "1"      → level 1: append a new `## Feature Categories` <details> block (category)
  - "1.2"    → level 2: append a new `### N.X Name` subgroup heading + empty table inside category N
  - "1.2.3"  → level 3: append a new feature row to the existing subgroup N.X table

Idempotency: if the target ID already exists, the script logs an informational message and exits
zero (no mutation). Safe to re-run.

Parent validation:
  - Level 2: parent category (first digit) must exist
  - Level 3: parent subgroup (first two digits) must exist

After successful mutation, attempts to chain to `New-TestInfrastructure.ps1 -Update` for
test/audit directory scaffolding. If the target script does not yet expose `-Update`
(pre-Phase-2b state of PF-IMP-871), the chain is logged as a stub and skipped — the script
still succeeds.

Project routing:
  - appdev (project_id "PRJ-000"): target is `<root>/blueprint/doc/state-tracking/permanent/feature-tracking.md`
  - project (other): target is `<root>/doc/state-tracking/permanent/feature-tracking.md`

Created 2026-05-14 (PF-IMP-871 / PF-PRO-034 — Test and Audit Infrastructure Reorganization Phase 2a).

.PARAMETER Id
The feature ID. Dot-separated, depths 1-3 accepted. Validated via regex `^\d+(\.\d+){0,2}$`.

.PARAMETER Name
The human-typed name. Used both in the feature-tracking content and as the basis for slug
derivation in the test-infrastructure chain.

.PARAMETER Description
(Optional) For level 2 (new subgroup): a paragraph of body text placed below the subgroup
heading and above the empty table. Ignored for levels 1 and 3.

.PARAMETER Status
(Optional, level 3 only) Initial Status column value. Default: "⬜ Needs Assessment".

.PARAMETER Priority
(Optional, level 3 only) Initial Priority column value. Default: "P3".

.PARAMETER DocTier
(Optional, level 3 only) Initial Doc Tier column value. Default: "" (blank — set by tier assessment).

.PARAMETER TestStatus
(Optional, level 3 only) Initial Test Status column value. Default: "⬜".

.PARAMETER Dependencies
(Optional, level 3 only) Initial Dependencies column value. Default: "".

.PARAMETER Notes
(Optional, level 3 only) Initial Notes column value. Default: "".

.PARAMETER FeatureTrackingFile
(Optional) Override the auto-detected feature-tracking.md path. Use for testing with synthetic fixtures.

.PARAMETER SkipTestInfraChain
(Optional) Skip the chain to New-TestInfrastructure.ps1 -Update. Used by synthetic-fixture tests
to keep them deterministic; also used when the caller wants to batch mutations and trigger
the test-infra update once at the end.

.EXAMPLE
# Add a new category
Update-FeatureCategory.ps1 -Id "1" -Name "Customer Management"

.EXAMPLE
# Add a new subgroup under category 1 with description
Update-FeatureCategory.ps1 -Id "1.2" -Name "Customer Read Operations" -Description "Read-side operations on customer records."

.EXAMPLE
# Add a new feature row under subgroup 1.2
Update-FeatureCategory.ps1 -Id "1.2.3" -Name "Read by ID" -Priority "P2" -Notes "Idempotent lookup"

.NOTES
Consumed by:
- PF-TSK-002 Feature Request Evaluation (Phase 2a path, after new-feature classification)
- PF-TSK-064 Codebase Feature Discovery (replaces manual feature-tracking edits in step 7)

Chain target: blueprint/process-framework/scripts/file-creation/00-setup/New-TestInfrastructure.ps1 -Update
(added in Phase 2b — until then, chain is a logged stub).
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+(\.\d+){0,2}$')]
    [string]$Id,

    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [string]$Status = "⬜ Needs Assessment",

    [Parameter(Mandatory = $false)]
    [string]$Priority = "P3",

    [Parameter(Mandatory = $false)]
    [string]$DocTier = "",

    [Parameter(Mandatory = $false)]
    [string]$TestStatus = "⬜",

    [Parameter(Mandatory = $false)]
    [string]$Dependencies = "",

    [Parameter(Mandatory = $false)]
    [string]$Notes = "",

    [Parameter(Mandatory = $false)]
    [string]$FeatureTrackingFile = "",

    [Parameter(Mandatory = $false)]
    [switch]$SkipTestInfraChain
)

# ----- Module imports -----
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
$prevVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
$VerbosePreference = $prevVerbosePreference

# Naming module (for chain target slug derivation)
$namingModule = Join-Path $dir "Common-ScriptHelpers/Naming.psm1"
if (Test-Path $namingModule) {
    Import-Module $namingModule -Force -Verbose:$false
}

# Soak verification (PF-PRO-028 v2.0 Pattern A; caller-aware no-arg form)
Register-SoakScript

# ----- Level inference -----
$dotCount = ($Id.ToCharArray() | Where-Object { $_ -eq '.' }).Count
$level = $dotCount + 1   # "1" → 1, "1.2" → 2, "1.2.3" → 3

# ----- Path resolution -----
# Routes via Resolve-DocPath (Common-ScriptHelpers/Core.psm1) — handles the appdev
# blueprint/doc vs project working-copy doc/ split via project_id detection.
if ([string]::IsNullOrEmpty($FeatureTrackingFile)) {
    $FeatureTrackingFile = Resolve-DocPath -Subpath "state-tracking/permanent/feature-tracking.md"
}

if (-not (Test-Path $FeatureTrackingFile)) {
    Write-Error "Feature tracking file not found: $FeatureTrackingFile"
    exit 1
}

Write-Verbose "Level $level mutation: Id='$Id', Name='$Name', file='$FeatureTrackingFile'"

# ----- Parse existing content -----
$content = Get-Content -Path $FeatureTrackingFile -Raw
$lines = $content -split "`r?`n"

# Find category boundaries: scan for `<details>\n<summary><strong>N. Name</strong>...` blocks
# inside the `## Feature Categories` section.
$categoriesStartIdx = -1
$archivedFeaturesStartIdx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^## Feature Categories\s*$') {
        $categoriesStartIdx = $i
    } elseif ($lines[$i] -match '^## Archived Features\s*$' -and $categoriesStartIdx -ge 0) {
        $archivedFeaturesStartIdx = $i
        break
    }
}
if ($categoriesStartIdx -lt 0) {
    Write-Error "Could not locate '## Feature Categories' section in $FeatureTrackingFile"
    exit 1
}
if ($archivedFeaturesStartIdx -lt 0) {
    Write-Error "Could not locate '## Archived Features' boundary after '## Feature Categories' in $FeatureTrackingFile"
    exit 1
}

# Extract category blocks. Each block starts with `<details>` and contains
# `<summary><strong>N. ...</strong>` then ends with `</details>`.
$categories = @()  # list of @{Number, Name, StartIdx, EndIdx, Subgroups}
$inCategory = $false
$currentCat = $null
for ($i = $categoriesStartIdx; $i -lt $archivedFeaturesStartIdx; $i++) {
    $line = $lines[$i]
    if (-not $inCategory) {
        if ($line -match '^<details>\s*$') {
            $nextLine = if ($i + 1 -lt $lines.Count) { $lines[$i + 1] } else { '' }
            if ($nextLine -match '^<summary><strong>(\d+)\.\s+(.+?)</strong></summary>\s*$') {
                $currentCat = @{
                    Number     = [int]$matches[1]
                    Name       = $matches[2]
                    StartIdx   = $i
                    EndIdx     = -1
                    Subgroups  = @()
                }
                $inCategory = $true
            }
        }
    } else {
        if ($line -match '^</details>\s*$') {
            $currentCat.EndIdx = $i
            $categories += [PSCustomObject]$currentCat
            $currentCat = $null
            $inCategory = $false
        } elseif ($line -match '^### (\d+)\.(\d+)\s+(.+?)\s*$') {
            $catNum = [int]$matches[1]
            $subNum = [int]$matches[2]
            $subName = $matches[3]
            $currentCat.Subgroups += @{
                CatNumber = $catNum
                SubNumber = $subNum
                Name      = $subName
                LineIdx   = $i
            }
        }
    }
}

# Extract existing feature IDs from table rows (anywhere in the categories section)
# Pattern: |  N.X.Y  |  ... |   (feature ID in the first cell)
$existingFeatureIds = New-Object System.Collections.Generic.HashSet[string]
for ($i = $categoriesStartIdx; $i -lt $archivedFeaturesStartIdx; $i++) {
    if ($lines[$i] -match '^\|\s+(\d+\.\d+\.\d+)\s+\|') {
        [void]$existingFeatureIds.Add($matches[1])
    }
}

# ----- Validate + dispatch by level -----
function Find-Category {
    param([int]$Number)
    return $categories | Where-Object { $_.Number -eq $Number } | Select-Object -First 1
}

function Find-Subgroup {
    param([int]$CatNumber, [int]$SubNumber)
    $cat = Find-Category -Number $CatNumber
    if ($null -eq $cat) { return $null }
    return $cat.Subgroups | Where-Object { $_.SubNumber -eq $SubNumber } | Select-Object -First 1
}

$mutated = $false
$summaryAction = ""

if ($level -eq 1) {
    # Level 1: new category
    $catNum = [int]$Id
    $existing = Find-Category -Number $catNum
    if ($null -ne $existing) {
        Write-Host "[INFO] Category $catNum already exists ('$($existing.Name)') — no mutation." -ForegroundColor Yellow
        $summaryAction = "noop (category $catNum exists)"
    } else {
        # Build new category block — bare <details> with summary, no default subgroup.
        # Callers add subgroups via subsequent level-2 calls.
        $block = @(
            "<details>"
            "<summary><strong>$catNum. $Name</strong></summary>"
            ""
            "</details>"
            ""
        )
        # Insert before `## Archived Features` heading
        $insertIdx = $archivedFeaturesStartIdx
        # If preceding line is blank, fold it
        $newLines = @()
        $newLines += $lines[0..($insertIdx - 1)]
        $newLines += $block
        $newLines += $lines[$insertIdx..($lines.Count - 1)]
        if ($PSCmdlet.ShouldProcess($FeatureTrackingFile, "Add category $catNum '$Name'")) {
            # PF-IMP-801: recompute Progress Summary so the Implementation Status Overview /
            # Documentation Tier Distribution counts stay in sync after row mutations.
            # Cheap no-op for level-1/level-2 (no feature rows added), essential for level-3.
            $joined = ($newLines -join "`n")
            $joined = Update-FeatureTrackingSummary -Content $joined
            $joined | Set-Content -Path $FeatureTrackingFile -NoNewline
            $mutated = $true
            $summaryAction = "added category $catNum '$Name'"
        } else {
            $summaryAction = "would add category $catNum '$Name' (WhatIf)"
        }
    }
} elseif ($level -eq 2) {
    # Level 2: new subgroup
    $idParts = $Id -split '\.'
    $catNum = [int]$idParts[0]
    $subNum = [int]$idParts[1]
    $cat = Find-Category -Number $catNum
    if ($null -eq $cat) {
        Write-Error "Parent category $catNum does not exist. Create it first: Update-FeatureCategory.ps1 -Id '$catNum' -Name '...'"
        exit 1
    }
    $existing = $cat.Subgroups | Where-Object { $_.SubNumber -eq $subNum } | Select-Object -First 1
    if ($null -ne $existing) {
        Write-Host "[INFO] Subgroup $catNum.$subNum already exists ('$($existing.Name)') — no mutation." -ForegroundColor Yellow
        $summaryAction = "noop (subgroup $catNum.$subNum exists)"
    } else {
        # Build subgroup block: heading + (description) + empty table
        $block = @(
            "### $catNum.$subNum $Name"
            ""
        )
        if ($Description.Trim() -ne "") {
            $block += $Description
            $block += ""
        }
        $block += "|  ID  |  Feature  |  Status  |  Priority  |  Doc Tier  |  Test Status  |  Dependencies  |  Notes  |"
        $block += "|  --  |  -------  |  ------  |  --------  |  --------  |  -----------  |  ------------  |  -----  |"
        $block += ""
        # Insert before the closing </details> of the parent category
        $insertIdx = $cat.EndIdx  # the </details> line
        $newLines = @()
        $newLines += $lines[0..($insertIdx - 1)]
        $newLines += $block
        $newLines += $lines[$insertIdx..($lines.Count - 1)]
        if ($PSCmdlet.ShouldProcess($FeatureTrackingFile, "Add subgroup $catNum.$subNum '$Name'")) {
            # PF-IMP-801: recompute Progress Summary (see level-1 site above).
            $joined = ($newLines -join "`n")
            $joined = Update-FeatureTrackingSummary -Content $joined
            $joined | Set-Content -Path $FeatureTrackingFile -NoNewline
            $mutated = $true
            $summaryAction = "added subgroup $catNum.$subNum '$Name'"
        } else {
            $summaryAction = "would add subgroup $catNum.$subNum '$Name' (WhatIf)"
        }
    }
} elseif ($level -eq 3) {
    # Level 3: new feature row
    $idParts = $Id -split '\.'
    $catNum = [int]$idParts[0]
    $subNum = [int]$idParts[1]
    $sub = Find-Subgroup -CatNumber $catNum -SubNumber $subNum
    if ($null -eq $sub) {
        Write-Error "Parent subgroup $catNum.$subNum does not exist. Create it first: Update-FeatureCategory.ps1 -Id '$catNum.$subNum' -Name '...'"
        exit 1
    }
    if ($existingFeatureIds.Contains($Id)) {
        Write-Host "[INFO] Feature $Id already exists — no mutation." -ForegroundColor Yellow
        $summaryAction = "noop (feature $Id exists)"
    } else {
        # Find the table within the subgroup. Scan from the subgroup heading forward until we hit
        # the next `### N.X` heading or the closing `</details>`. The table block is
        # a header row + separator row + zero-or-more data rows + trailing blank line.
        $catEnd = ($categories | Where-Object { $_.Number -eq $catNum }).EndIdx
        $tableEndIdx = -1
        for ($i = $sub.LineIdx + 1; $i -lt $catEnd; $i++) {
            $line = $lines[$i]
            # Stop at next subgroup heading
            if ($line -match '^### \d+\.\d+\s') { break }
            # Track table rows (lines starting with `|`)
            if ($line -match '^\|') {
                $tableEndIdx = $i
            }
        }
        if ($tableEndIdx -lt 0) {
            Write-Error "Could not locate table inside subgroup $catNum.$subNum"
            exit 1
        }
        # Build new row
        $row = "|  $Id  |  $Name  |  $Status  |  $Priority  |  $DocTier  |  $TestStatus  |  $Dependencies  |  $Notes  |"
        # Insert after $tableEndIdx (the last table line)
        $insertIdx = $tableEndIdx + 1
        $newLines = @()
        $newLines += $lines[0..($tableEndIdx)]
        $newLines += $row
        if ($insertIdx -lt $lines.Count) {
            $newLines += $lines[$insertIdx..($lines.Count - 1)]
        }
        if ($PSCmdlet.ShouldProcess($FeatureTrackingFile, "Add feature $Id '$Name' to subgroup $catNum.$subNum")) {
            # PF-IMP-801: recompute Progress Summary — essential here (new feature row
            # changes total count and the Status / Doc Tier breakdowns).
            $joined = ($newLines -join "`n")
            $joined = Update-FeatureTrackingSummary -Content $joined
            $joined | Set-Content -Path $FeatureTrackingFile -NoNewline
            $mutated = $true
            $summaryAction = "added feature $Id '$Name'"
        } else {
            $summaryAction = "would add feature $Id '$Name' (WhatIf)"
        }
    }
}

# ----- Chain to New-TestInfrastructure.ps1 -Update -----
if ($mutated -and -not $SkipTestInfraChain) {
    $testInfraScript = Join-Path (Get-ProcessFrameworkPath) "scripts/file-creation/00-setup/New-TestInfrastructure.ps1"
    if (Test-Path $testInfraScript) {
        # Check whether the script supports -Update (Phase 2b adds this; Phase 2a chain is stub)
        $scriptHelp = (Get-Command $testInfraScript).Parameters
        if ($scriptHelp.ContainsKey('Update')) {
            Write-Verbose "Chaining to New-TestInfrastructure.ps1 -Update"
            try {
                & $testInfraScript -Update -Confirm:$false
            } catch {
                Write-Host "[WARN] Chain to New-TestInfrastructure.ps1 -Update failed: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        } else {
            Write-Verbose "New-TestInfrastructure.ps1 does not yet support -Update (Phase 2b pending) — chain skipped."
        }
    }
}

# ----- Summary -----
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$color = if ($summaryAction.StartsWith("noop")) { "Yellow" } else { "Green" }
Write-Host "[$timestamp] [SUCCESS] Update-FeatureCategory: $summaryAction" -ForegroundColor $color

# Soak confirmation (PF-PRO-028 v2.0 Pattern A)
if ($mutated -or $summaryAction.StartsWith("noop")) {
    Confirm-SoakInvocation -Outcome success
}
