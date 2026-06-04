# DesignArtifactCreation.psm1
# Shared orchestration core for the per-feature design artifact creation pipeline.
#
# Created 2026-05-08 for PF-PRO-002 / PF-IMP-028 Phase 2 (Feature Tracking
# Lightweight Index). Replaces ~70-100 lines of orchestration boilerplate
# duplicated across 7 design-creator scripts (New-FDD, New-TDD, New-SchemaDesign,
# New-APISpecification, New-APIDataModel, New-UIDesign, New-TestSpecification).
#
# What this module owns:
#   - Calling New-StandardProjectDocument (template processing + ID assignment + file creation)
#   - Appending an entry to PD-documentation-map.md
#   - Updating the master Status column on feature-tracking.md (no per-feature artifact column writes)
#   - Inserting/updating the per-feature state file's §4 ▸ Design Documentation table row
#   - Reporting structured results back to the caller for display
#
# What stays in each wrapper:
#   - Param parsing and validation (Tier for TDD, SchemaType for SchemaDesign, etc.)
#   - Filename composition (per-type pattern: fdd-1-1-3-foo.md vs tdd-1-1-3-foo-t2.md)
#   - Per-type next-master-Status computation (e.g. FDD → "📝 Needs TDD",
#     TDD → "🧪 Needs Test Spec"; DB/API gate routing now comes from
#     Get-NextStatusAfterDesignArtifact in AssessmentParsing.psm1 — PF-IMP-766)
#   - Per-type custom replacements / metadata fields
#   - Display formatting

# Configure UTF-8 encoding for consistent Unicode support
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'

# Import dependencies at top-level so they resolve in this module's session state
# (canonical sub-module dependency pattern — see guides/support/script-development-quick-reference.md).
$_moduleDir = $PSScriptRoot
foreach ($_dep in @('Core.psm1', 'OutputFormatting.psm1', 'DocumentManagement.psm1', 'FeatureTracking.psm1', 'StateFileInventory.psm1')) {
    $_path = Join-Path -Path $_moduleDir -ChildPath $_dep
    if (Test-Path $_path) { Import-Module $_path -Force }
    else { Write-Warning "DesignArtifactCreation: dependency '$_dep' not found next to module" }
}

function Invoke-DesignArtifactCreation {
    <#
    .SYNOPSIS
    Orchestration core for the 7 design-creator wrapper scripts.

    .DESCRIPTION
    Creates a new design document from a template, appends an entry to the
    documentation map, updates the master feature row Status (Status only — no
    per-feature artifact column writes per PF-PRO-002), and inserts/updates the
    feature state file's §4 ▸ Design Documentation row via Phase 1's
    Add-StateFileDocumentationInventoryRow helper.

    Splat-friendly: callers build a config hashtable and pass it via @config.

    -DryRun and -WhatIf are unified — either flag short-circuits the entire
    pipeline (doc creation, docmap append, master Status update, state-file
    §4 row). Prior split semantics (where -DryRun gated only tracking writes
    while doc + docmap proceeded) caused agent confusion: scoping invocations
    silently created files and bumped ID counters against caller expectations.
    Unified per PF-IMP-785 (2026-05-27).

    .PARAMETER ArtifactType
    Short label for the artifact, used for the §4 row Type cell and display
    (e.g. "FDD", "TDD", "Schema Design", "API Specification", "UI Design",
    "Test Specification"). Locked to the short-label convention per PF-PRO-002.

    .PARAMETER IdPrefix
    ID registry prefix for the new document (e.g. "PD-FDD", "PD-TDD", "PD-SCH").

    .PARAMETER IdDescription
    Annotation passed to the ID registry on assignment.

    .PARAMETER TemplatePath
    Absolute or project-root-relative path to the template .md file.

    .PARAMETER FileNamePattern
    Caller-composed filename for the new document (e.g.
    "fdd-1-1-3-invoice-generation.md"). Pattern varies per artifact type so
    the caller stays in control.

    .PARAMETER DocumentName
    Human-readable document name (used inside templates and downstream).
    Typically the FeatureName.

    .PARAMETER DirectoryType
    Directory-type key for ID-registry-based output dir resolution (preferred).
    Mutually exclusive with -OutputDirectory.

    .PARAMETER OutputDirectory
    Explicit output directory (project-root-relative or absolute). Used when
    -DirectoryType is not appropriate.

    .PARAMETER FeatureId
    Feature ID (e.g. "1.1.3"). May be empty — when empty, master Status update
    and state-file §4 row write are both skipped.

    .PARAMETER FeatureName
    Feature human-readable name. Used in the docmap entry.

    .PARAMETER Replacements
    Per-type custom template-string replacements (caller's hashtable).

    .PARAMETER AdditionalMetadataFields
    Per-type metadata frontmatter additions (caller's hashtable).

    .PARAMETER DocMapSectionHeader
    Exact docmap section header line under which to insert the new entry
    (e.g. "### `functional-design/fdds/`"). Matches the project's existing
    Add-DocumentationMapEntry contract.

    .PARAMETER DocMapEntryFormatter
    ScriptBlock invoked AFTER the document is created to compose the docmap
    entry line. Receives one positional argument: the assigned $documentId.
    Must return the complete markdown list entry as a string. Caller-supplied
    because the entry format varies per artifact type and depends on the new ID.

    Example:
        -DocMapEntryFormatter { param($id) "- [FDD: $FeatureName ($id)](functional-design/fdds/$customFileName) - $FeatureId description" }

    .PARAMETER NewMasterStatus
    The next master Status value (e.g. "📝 Needs TDD"). When empty (or when
    FeatureId is empty), the master Status update is skipped.

    .PARAMETER MasterStatusColumn
    Which master-row column to write -NewMasterStatus into. Defaults to "Status".
    `New-TestSpecification.ps1` overrides to "Test Status" because Test Spec
    creation transitions the test-tracking column rather than the main Status
    column.

    .PARAMETER DocMapPath
    Optional override for the documentation-map file. Defaults to the project's
    `doc/PD-documentation-map.md`. `New-TestSpecification.ps1` overrides to
    `test/TE-documentation-map.md` because test artifacts live in the TE map.

    .PARAMETER MasterStatusNotes
    Optional Notes-column append text for the master row update. Static string;
    use -MasterStatusNotesFormatter when the Notes need to reference the
    just-assigned document ID.

    .PARAMETER MasterStatusNotesFormatter
    Optional ScriptBlock invoked AFTER the document is created to compose the
    master Notes append. Receives one positional argument: the assigned
    $documentId. Must return a string. Mutually exclusive with -MasterStatusNotes.
    Use this when Notes need to reference the new document ID, e.g.
    `{ param($id) "FDD created: $id ($(Get-ProjectTimestamp -Format 'Date'))" }`.

    .PARAMETER StateFileArtifactStatus
    The Status cell value for the state file §4 row. Defaults to "✅ Created".

    .PARAMETER ArtifactRelativePath
    Project-root-relative path to the artifact, used for both the §4 Document
    cell link and the §4 Location cell. Required when FeatureId is non-empty.
    Caller composes (e.g. "doc/functional-design/fdds/$customFileName").

    .PARAMETER OpenInEditor
    Forwarded to New-StandardProjectDocument — open the created doc in editor.

    .PARAMETER DryRun
    Preview the entire pipeline without performing any writes. Equivalent to
    -WhatIf; either flag short-circuits doc creation, docmap append, master
    Status update, and state-file §4 row write.

    .PARAMETER CallerCmdlet
    The wrapper's $PSCmdlet, used for Add-DocumentationMapEntry's ShouldProcess
    contract. Required so -WhatIf flows from the wrapper through to the docmap
    update.

    .OUTPUTS
    Hashtable with keys:
      DocumentId          - assigned ID (or $null in -WhatIf)
      DocumentRelativePath- project-root-relative path of the created doc
      DocMapUpdated       - $true / $false
      MasterStatusResult  - $true / $false / $null (skipped)
      StateFileResult     - hashtable from Add-StateFileDocumentationInventoryRow, or $null
      Action              - 'Created' | 'WhatIfPreviewed'
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # ---- Required: artifact identity ----
        [Parameter(Mandatory=$true)] [string]$ArtifactType,
        [Parameter(Mandatory=$true)] [string]$IdPrefix,
        [Parameter(Mandatory=$true)] [string]$IdDescription,

        # ---- Required: template + filename ----
        [Parameter(Mandatory=$true)] [string]$TemplatePath,
        [Parameter(Mandatory=$true)] [string]$FileNamePattern,
        [Parameter(Mandatory=$true)] [string]$DocumentName,

        # ---- One of: DirectoryType OR OutputDirectory ----
        [string]$DirectoryType,
        [string]$OutputDirectory,

        # ---- Required: feature linkage ----
        [string]$FeatureId = "",
        [Parameter(Mandatory=$true)] [string]$FeatureName,

        # ---- Template/metadata customization ----
        [hashtable]$Replacements = @{},
        [hashtable]$AdditionalMetadataFields = @{},

        # ---- Documentation map append ----
        [Parameter(Mandatory=$true)] [string]$DocMapSectionHeader,
        [Parameter(Mandatory=$true)] [scriptblock]$DocMapEntryFormatter,

        # ---- Master Status transition ----
        [string]$NewMasterStatus = "",
        [string]$MasterStatusColumn = "Status",
        [string]$MasterStatusNotes = "",
        [scriptblock]$MasterStatusNotesFormatter,

        # ---- Documentation map override (defaults to PD map) ----
        [string]$DocMapPath = "",

        # ---- State file §4 Documentation Inventory write ----
        [string]$StateFileArtifactStatus = "✅ Created",
        [string]$ArtifactRelativePath = "",

        # ---- Behavior switches ----
        [switch]$OpenInEditor,
        [switch]$DryRun,

        # ---- ShouldProcess pass-through ----
        [Parameter(Mandatory=$true)] [System.Management.Automation.PSCmdlet]$CallerCmdlet
    )

    if ($DirectoryType -and $OutputDirectory) {
        throw "Invoke-DesignArtifactCreation: provide either -DirectoryType OR -OutputDirectory, not both."
    }
    if (-not $DirectoryType -and -not $OutputDirectory) {
        throw "Invoke-DesignArtifactCreation: provide either -DirectoryType OR -OutputDirectory."
    }
    if ($FeatureId -and -not $ArtifactRelativePath) {
        throw "Invoke-DesignArtifactCreation: -ArtifactRelativePath is required when -FeatureId is non-empty (used for §4 Document/Location cells)."
    }
    if ($MasterStatusNotes -and $MasterStatusNotesFormatter) {
        throw "Invoke-DesignArtifactCreation: -MasterStatusNotes and -MasterStatusNotesFormatter are mutually exclusive."
    }

    # PF-IMP-785 (2026-05-27): unified preview flag. Either -DryRun or -WhatIf
    # short-circuits the entire pipeline. Passed as -WhatIf:$isPreview to
    # child functions that gate on their own ShouldProcess; explicitly
    # branched around for Add-DocumentationMapEntry (which gates on the
    # wrapper's $CallerCmdlet.ShouldProcess, not its own).
    #
    # $WhatIfPreference may not cross module session-state boundaries even when
    # the wrapper script was called with -WhatIf, so Get-EffectiveWhatIf (PF-IMP-939,
    # shared with New-StandardProjectDocument) also walks the call stack for an explicit
    # -WhatIf in any caller frame. Without this, wrapper -WhatIf gets misread as "not
    # preview" and any -WhatIf:$false we then push to child cmdlets suppresses their own
    # walkers — regressing file-creation gating for the -WhatIf path.
    $isPreview = Get-EffectiveWhatIf -WhatIfPreference $WhatIfPreference -DryRun:$DryRun

    # Orchestration-layer ShouldProcess gate. Emits a single human-readable
    # message under -WhatIf describing the whole pipeline.
    $opTarget = if ($FeatureId) {
        "feature $FeatureId (doc + docmap + master Status + state file §4 row)"
    } else { "docmap entry" }
    [void]$PSCmdlet.ShouldProcess($opTarget, "Create $ArtifactType artifact ($IdPrefix)")

    $result = @{
        DocumentId           = $null
        DocumentRelativePath = $ArtifactRelativePath
        DocMapUpdated        = $false
        MasterStatusResult   = $null
        StateFileResult      = $null
        Action               = if ($isPreview) { 'Previewed' } else { 'Created' }
    }

    # ---- Step 1: Create the document via the standard pipeline ----
    $createSplat = @{
        TemplatePath             = $TemplatePath
        IdPrefix                 = $IdPrefix
        IdDescription            = $IdDescription
        DocumentName             = $DocumentName
        Replacements             = $Replacements
        AdditionalMetadataFields = $AdditionalMetadataFields
        FileNamePattern          = $FileNamePattern
        OpenInEditor             = $OpenInEditor
    }
    if ($DirectoryType)   { $createSplat['DirectoryType']   = $DirectoryType }
    if ($OutputDirectory) { $createSplat['OutputDirectory'] = $OutputDirectory }

    # Pass -WhatIf:$isPreview so the child sees a bound WhatIf parameter
    # (it walks the call stack for BoundParameters['WhatIf'] rather than
    # inheriting $WhatIfPreference across module session-state boundaries).
    $documentId = New-StandardProjectDocument @createSplat -WhatIf:$isPreview
    $result.DocumentId = $documentId

    # ---- Step 2: Append to PD-documentation-map.md ----
    # Composed via a caller-supplied script block so the entry line can
    # reference the just-assigned $documentId. Under -DryRun/-WhatIf we
    # emit a preview message and skip the call — Add-DocumentationMapEntry
    # gates on $CallerCmdlet.ShouldProcess (the wrapper's PSCmdlet), which
    # does not see -DryRun.
    if ($documentId -or $isPreview) {
        $idForFormatter = if ($documentId) { $documentId } else { "$IdPrefix-XXX (preview)" }
        $docMapEntryLine = & $DocMapEntryFormatter $idForFormatter

        if ($isPreview) {
            Write-Host "DRY RUN: Would append to documentation map under '$DocMapSectionHeader':" -ForegroundColor Yellow
            Write-Host "  $docMapEntryLine" -ForegroundColor Cyan
            $result.DocMapUpdated = $false
        }
        else {
            $resolvedDocMapPath = if ($DocMapPath) {
                if ([System.IO.Path]::IsPathRooted($DocMapPath)) { $DocMapPath }
                else { Join-Path -Path (Get-ProjectRoot) -ChildPath $DocMapPath }
            } else {
                Join-Path -Path (Get-ProjectRoot) -ChildPath "doc/PD-documentation-map.md"
            }
            $result.DocMapUpdated = Add-DocumentationMapEntry `
                -DocMapPath $resolvedDocMapPath `
                -SectionHeader $DocMapSectionHeader `
                -EntryLine $docMapEntryLine `
                -CallerCmdlet $CallerCmdlet
        }
    }

    # ---- Step 3: Master Status update + state-file §4 row write ----
    # Both are skipped when no FeatureId. Both honor $isPreview (preview only).
    if (-not $FeatureId) { return $result }
    if (-not $documentId -and -not $isPreview) { return $result }   # doc creation failed; don't touch tracking

    Write-Host ""
    Write-Host "🤖 Updating Feature Tracking..." -ForegroundColor Yellow

    # ---- 3a: Master Status (Status only — no per-feature artifact column writes) ----
    if ($NewMasterStatus) {
        # Resolve final Notes string: prefer formatter when supplied (so $documentId can be embedded).
        $resolvedNotes = if ($MasterStatusNotesFormatter) {
            $idForFormatter = if ($documentId) { $documentId } else { "$IdPrefix-XXX (preview)" }
            & $MasterStatusNotesFormatter $idForFormatter
        } else {
            $MasterStatusNotes
        }

        if ($isPreview) {
            Write-Host "DRY RUN: Would update master Status for $FeatureId → $NewMasterStatus" -ForegroundColor Yellow
            if ($resolvedNotes) {
                Write-Host "  Master Notes: $resolvedNotes" -ForegroundColor Cyan
            }
        }
        else {
            $masterArgs = @{
                FeatureId    = $FeatureId
                Status       = $NewMasterStatus
                StatusColumn = $MasterStatusColumn
            }
            if ($resolvedNotes) { $masterArgs['Notes'] = $resolvedNotes }
            $result.MasterStatusResult = Update-FeatureTrackingStatus @masterArgs
            Write-Host "  ✅ Master $MasterStatusColumn updated → $NewMasterStatus" -ForegroundColor Green
        }
    }

    # ---- 3b: State file §4 Documentation Inventory row insert/update ----
    # Use placeholder ArtifactId when $documentId is empty (i.e. -WhatIf created
    # no real ID) so the helper has a non-empty value to preview against.
    try {
        $idForInventory = if ($documentId) { $documentId } else { "$IdPrefix-XXX (preview)" }
        $invArgs = @{
            FeatureId    = $FeatureId
            ArtifactId   = $idForInventory
            ArtifactPath = $ArtifactRelativePath
            ArtifactType = $ArtifactType
            Status       = $StateFileArtifactStatus
        }
        $invResult = Add-StateFileDocumentationInventoryRow @invArgs -WhatIf:$isPreview
        $result.StateFileResult = $invResult
        $verb = if ($isPreview) { "would $($invResult.Action.ToLower())" } else { $invResult.Action.ToLower() }
        Write-Host ("  📂 State file §4 Documentation Inventory: {0} (line {1})" -f $verb, $invResult.LineNumber) -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to write $ArtifactType row to feature state file's §4 Documentation Inventory: $($_.Exception.Message)"
        $today = Get-ProjectTimestamp -Format 'Date'
        Write-Host "Manual update needed: insert row into the feature state file's §4 ▸ Design Documentation table:" -ForegroundColor Cyan
        Write-Host "  | [$documentId](/$ArtifactRelativePath) | $ArtifactType | $StateFileArtifactStatus | $ArtifactRelativePath | $today |" -ForegroundColor Cyan
    }

    return $result
}

Export-ModuleMember -Function @(
    'Invoke-DesignArtifactCreation'
)

Write-Verbose "DesignArtifactCreation module loaded with 1 function"
