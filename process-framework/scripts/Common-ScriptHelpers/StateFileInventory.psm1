# StateFileInventory.psm1
# Per-feature state file ▸ §4 Documentation Inventory operations.
#
# Created 2026-05-07 for PF-PRO-002 / PF-IMP-028 (Feature Tracking Lightweight Index).
# Phase 1 deliverable: a single high-level helper that design writer scripts
# (New-FDD, New-TDD, New-SchemaDesign, New-APISpecification, New-APIDataModel,
# New-UIDesign, New-TestSpecification, Update-FeatureTrackingFromAssessment)
# will call to insert artifact rows into per-feature state files instead of
# writing to (often nonexistent) feature-tracking.md columns.
#
# Architecture: this module is the state-file-aware wrapper around the pure
# markdown primitive Add-MarkdownTableRow (TableOperations.psm1). It owns:
#   - state file path resolution (FeatureId -> doc/state-tracking/features/<id>-*-implementation-state.md)
#   - link composition and project-root-relative path computation
#   - the §4 ▸ Design Documentation table schema (5 columns, anchored on the
#     "### Design Documentation" heading regardless of section number — Tier 1
#     state files use ## 3., Tier 2/3 use ## 4.)

# Configure UTF-8 encoding for consistent Unicode support
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'

# Import dependencies at top-level so they resolve in this module's session
# state. This is the canonical sub-module dependency pattern documented in
# guides/support/script-development-quick-reference.md ("Sub-Module Function
# Scoping (Common-ScriptHelpers)") — a function-scoped Import-ProjectModule
# would land the imports in Core's session state and not be visible here.
$_moduleDir = $PSScriptRoot
foreach ($_dep in @('Core.psm1', 'OutputFormatting.psm1', 'TableOperations.psm1')) {
    $_path = Join-Path -Path $_moduleDir -ChildPath $_dep
    if (Test-Path $_path) { Import-Module $_path -Force }
    else { Write-Warning "StateFileInventory: dependency '$_dep' not found next to module" }
}

function Resolve-FeatureStateFilePath {
    <#
    .SYNOPSIS
    Resolves a feature ID to its state file path.

    .DESCRIPTION
    Globs doc/state-tracking/features/<FeatureId>-*-implementation-state.md
    relative to project root. Errors if 0 or 2+ matches.

    .PARAMETER FeatureId
    Feature ID, e.g. "1.1.5".

    .PARAMETER ProjectRoot
    Optional explicit project root override. Defaults to Get-ProjectRoot.

    .OUTPUTS
    [string] Absolute path to the state file. Throws on ambiguity or absence.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string]$FeatureId,
        [Parameter(Mandatory=$false)] [string]$ProjectRoot
    )

    if (-not $ProjectRoot) { $ProjectRoot = Get-ProjectRoot }
    $featuresDir = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/features"
    if (-not (Test-Path $featuresDir)) {
        throw "Resolve-FeatureStateFilePath: features directory not found: $featuresDir"
    }
    $matches = @(Get-ChildItem -Path $featuresDir -Filter "$FeatureId-*-implementation-state.md" -File -ErrorAction SilentlyContinue)
    if ($matches.Count -eq 0) {
        throw "Resolve-FeatureStateFilePath: no state file found for feature '$FeatureId' under $featuresDir"
    }
    if ($matches.Count -gt 1) {
        $names = ($matches | ForEach-Object { $_.Name }) -join ', '
        throw "Resolve-FeatureStateFilePath: feature '$FeatureId' is ambiguous — matches: $names"
    }
    return $matches[0].FullName
}

function Add-StateFileDocumentationInventoryRow {
    <#
    .SYNOPSIS
    Idempotently inserts or updates a row in a feature state file's §4 ▸ Design
    Documentation table.

    .DESCRIPTION
    Phase 1 helper for PF-PRO-002 (Feature Tracking Lightweight Index). Replaces
    the pattern of writing per-feature design artifacts to feature-tracking.md
    master columns. Anchors on the "### Design Documentation" heading inside the
    feature's state file and upserts a 5-column row keyed on $ArtifactId.

    Idempotency: re-invoking with the same inputs replaces the existing row in
    place (so re-running New-FDD against an already-recorded artifact does not
    duplicate it). Cell-level NoOp when every value already matches.

    .PARAMETER FeatureId
    Feature ID, e.g. "1.1.5". Used to discover the state file unless
    -StateFilePath is given.

    .PARAMETER ArtifactId
    The document ID for the artifact row (e.g. "PD-FDD-005"). This is the
    upsert key: the row whose Document cell starts with $ArtifactId is updated
    in place; otherwise a new row is appended.

    .PARAMETER ArtifactPath
    Project-root-relative path to the artifact (e.g.
    "doc/functional-design/fdds/fdd-1-1-5-foo.md"). Leading slash optional.

    .PARAMETER ArtifactType
    Free-form artifact type label (e.g. "FDD", "TDD T2", "Schema Design",
    "API Specification", "UI/UX Design", "Test Specification").

    .PARAMETER Status
    Status cell value (e.g. "✅ Created", "📋 In Progress", "⬜ Needs Creation").

    .PARAMETER LastUpdated
    Optional date for the Last Updated column. Defaults to today (Get-ProjectTimestamp Date).

    .PARAMETER StateFilePath
    Optional explicit state file path override. Skips feature-id-based discovery.

    .PARAMETER ProjectRoot
    Optional explicit project root. Defaults to Get-ProjectRoot. Used to
    interpret a project-root-relative ArtifactPath.

    .PARAMETER WhatIf
    Standard ShouldProcess switch — print what would change without writing.

    .OUTPUTS
    Hashtable with keys:
      StateFilePath - absolute path to the state file
      Action        - 'Inserted' | 'Updated' | 'NoOp' | 'SectionNotFound' | 'TableNotFound' | 'KeyColumnNotFound'
      LineNumber    - 1-based line of the affected row in the state file
      Message       - human-readable detail
      Row           - hashtable of the cell values that were written
      Written       - $true if the file was modified on disk; $false for WhatIf or NoOp
    #>

    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)] [string]$FeatureId,
        [Parameter(Mandatory=$true)] [string]$ArtifactId,
        [Parameter(Mandatory=$true)] [string]$ArtifactPath,
        [Parameter(Mandatory=$true)] [string]$ArtifactType,
        [Parameter(Mandatory=$true)] [string]$Status,
        [Parameter(Mandatory=$false)] [string]$LastUpdated,
        [Parameter(Mandatory=$false)] [string]$StateFilePath,
        [Parameter(Mandatory=$false)] [string]$ProjectRoot
    )

    if (-not $ProjectRoot) { $ProjectRoot = Get-ProjectRoot }
    if (-not $LastUpdated) { $LastUpdated = Get-ProjectTimestamp -Format "Date" }

    if (-not $StateFilePath) {
        $StateFilePath = Resolve-FeatureStateFilePath -FeatureId $FeatureId -ProjectRoot $ProjectRoot
    }
    if (-not (Test-Path $StateFilePath)) {
        throw "Add-StateFileDocumentationInventoryRow: state file not found: $StateFilePath"
    }

    # Normalize ArtifactPath: strip any leading / and convert backslashes
    $artifactPathNorm = ($ArtifactPath -replace '\\', '/').TrimStart('/')

    # Compose cells per project convention (see 2.1.1 Field Manager state file):
    #   Document   = "[ArtifactId](/relative/path)"   — leading slash for repo-root markdown link
    #   Type       = ArtifactType
    #   Status     = Status
    #   Location   = "relative/path"                  — bare project-root-relative path
    #   Last Updated = LastUpdated
    $documentCell = "[$ArtifactId](/$artifactPathNorm)"
    $row = @{
        'Document'     = $documentCell
        'Type'         = $ArtifactType
        'Status'       = $Status
        'Location'     = $artifactPathNorm
        'Last Updated' = $LastUpdated
    }

    $content = Get-Content -Path $StateFilePath -Raw
    $result = Add-MarkdownTableRow `
        -Content $content `
        -SectionHeading "### Design Documentation" `
        -KeyColumn "Document" `
        -KeyValue $ArtifactId `
        -MatchKeyByPrefix `
        -Row $row

    $written = $false
    $modifying = $result.Action -in @('Inserted', 'Updated')
    if ($modifying) {
        if ($PSCmdlet.ShouldProcess($StateFilePath, "$($result.Action) Documentation Inventory row for $ArtifactId")) {
            Set-Content -Path $StateFilePath -Value $result.Content -NoNewline
            $written = $true
        }
    }

    return @{
        StateFilePath = $StateFilePath
        Action        = $result.Action
        LineNumber    = $result.LineNumber
        Message       = $result.Message
        Row           = $row
        Written       = $written
    }
}

Export-ModuleMember -Function @(
    'Resolve-FeatureStateFilePath',
    'Add-StateFileDocumentationInventoryRow'
)

Write-Verbose "StateFileInventory module loaded with 2 functions"
