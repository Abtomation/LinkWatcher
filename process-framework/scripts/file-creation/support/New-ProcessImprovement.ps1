# New-ProcessImprovement.ps1
# Adds a new improvement opportunity to the Process Improvement Tracking state file
# Uses the central ID registry system for auto-assigned PF-IMP IDs

<#
.SYNOPSIS
    Adds a new improvement opportunity to process-improvement-tracking.md with an auto-assigned ID; -FastTrack logs a small already-applied framework fix directly to the archive Completed section.

.DESCRIPTION
    This PowerShell script creates new improvement entries by:
    - Generating a unique improvement ID (PF-IMP-###) via the central ID registry
    - Adding a row to the "Current Improvement Opportunities" table
    - Updating the frontmatter date

    On success the created PF-IMP-### is written to the output stream (the script's
    return value, in every mode) in addition to the console banner, so callers can
    capture it for chaining — e.g. IMP Triage's create-then-route flow (PF-IMP-1240).

    Field length constraints (validated at runtime): -Source 3-200 chars,
    -Description 10-500 chars. If a Description draft exceeds 500 chars, compress
    it for table-row brevity and move detail to -Notes, which is uncapped
    (PF-IMP-1824) — matching the uncapped -AppendNotes / -EditNotes on
    Update-ProcessImprovement.ps1, which can grow the same cell after creation.

.PARAMETER Source
    Display text for the source of this improvement (e.g., "Tools Review 2026-03-02", "User feedback")

.PARAMETER SourceLink
    Optional markdown link target for the source. When provided, the Source column renders as [Source](SourceLink).

.PARAMETER Description
    What needs to be improved (10-500 chars; for table-row brevity, compress longer drafts and move detailed context to -Notes).

.PARAMETER Notes
    Additional context or details (optional, uncapped — keep it proportionate; the Notes cell is the row's durable evidence record)

.PARAMETER BatchFile
    Path to a JSON file containing an array of improvement objects for bulk intake. Each object takes a required "Source" (3-200 chars) and "Description" (10-500 chars), plus optional "SourceLink" and "Notes" (uncapped) — the same length constraints as Single mode. The whole array is validated up front: if any item fails, every failure is reported together and no IDs are consumed (all-or-nothing). Selects the Batch parameter set; mutually exclusive with -Source/-Description. See the -BatchFile example below for the JSON shape.

.PARAMETER Supersedes
    Comma-separated list of PF-IMP IDs that this new IMP supersedes (cluster-consolidation case from PF-TSK-089 IMP Triage). After the new IMP row is created, each listed source IMP is moved to Section 7 — Rejected with `Status = "Superseded"` and `Rejection Reason = "Superseded by <new-IMP-ID>"` via subprocess invocation of Update-ProcessImprovement.ps1. Source IMPs must be in Intake / Improvements / Extensions / Structural Changes; pilots and already-rejected rows produce warnings and are skipped. Idempotent: re-running with the same list emits warnings on already-superseded sources but does not corrupt state. Example: -Supersedes "PF-IMP-810,PF-IMP-811,PF-IMP-812".

.PARAMETER AsPilot
    Switch that selects the Pilot parameter set. Registers a row in the Active Pilots section (Section 5) of process-improvement-tracking.md instead of the Intake section. Pilots track "try-on-one-instance-before-broaden" decisions and share the PF-IMP ID pool with regular improvements.

.PARAMETER SourceConcept
    ID of the originating concept this pilot trials. Accepts PF-PRO-NNN (Framework Extension proposal — the original intent) or PF-IMP-NNN (Process Improvement IMP — added PF-IMP-883 so IMP-shaped pilots have a lifecycle slot). Format: '^(PF-PRO|PF-IMP)-\d+$'. The pilot phase is logically prior to extension classification: a Process Improvement that turns out to broadly apply becomes extension-shaped only after the pilot proves it.

.PARAMETER OriginatingTask
    Task ID of the task that filed this pilot (e.g., PF-TSK-009, PF-TSK-026). Format: '^[A-Z]{2,4}-TSK-\d+$' — any framework's task family (PF-TSK, FB-TSK, ...; PF-PRO-068 P-12a).

.PARAMETER Adopters
    Free-form description of where the pilot is being trialed — files, scripts, task ecosystems. 3-500 chars.

.PARAMETER SuccessCriteria
    Observable criteria that, when met during the pilot, indicate the pattern is worth broadening. 10-500 chars. Examples: "All adopter soak counters reach 0", "Agent execution stays clean across N sessions on the new structure".

.PARAMETER DecisionTrigger
    Event phrase describing when the keep/abandon decision should be made. Always event-based, never calendar-based — pilots intentionally stay open until the triggering event fires. 3-200 chars. Examples: "After 3 Process Improvement sessions on the new doc structure", "When PF-IMP-685 closes", "When first user-doc rollout completes".

.PARAMETER PilotNotes
    Optional context for the pilot row (uncapped).

.PARAMETER FastTrack
    Switch that selects the FastTrack parameter set (PF-IMP-1127). For small framework fixes that qualify when ALL hold: (1) single artifact (plus its direct cross-references), (2) content/documentation only — no script behavior change, (3) no new mechanism/section/structure, (4) reversible by a single git revert. From appdev (PRJ-000) the entry is written directly into the archive's Section 6 — Completed with a [FAST-TRACK] origin marker (Resolved From = Fast-track); from a project cwd the same invocation files a one-liner to central Intake flagged fast-track-eligible instead. If a fix grows past the criteria mid-edit, stop and file a normal IMP.

.PARAMETER Artifact
    FastTrack only. The single file that was fixed (3-200 chars), e.g. "framework-rollout-task.md".

.PARAMETER Reason
    FastTrack only. Why the fix was needed (3-500 chars) — the "why" of the fast-track log line. Recorded in Notes behind the [FAST-TRACK] marker.

.PARAMETER TrackingFile
    Optional override for the tracking file path. Defaults to the central process-improvement-tracking.md (resolved via Get-CentralFrameworkPath), so the same script writes to the same central file whether invoked from cwd=appdev or cwd=project. Production callers should not pass it; it remains an escape hatch for tests and for one-off consolidation of legacy project-local files.

.PARAMETER ArchiveFile
    Optional override for the archive file path (FastTrack appdev path writes here). Defaults to the central archive resolved via Get-CentralFrameworkPath. Tests only.

.EXAMPLE
    New-ProcessImprovement.ps1 -Source "Tools Review 2026-03-02" -SourceLink "../../feedback/reviews/tools-review-20260302.md" -Description "Add validation to script X"

.EXAMPLE
    New-ProcessImprovement.ps1 -Source "User feedback" -Description "Simplify feedback form process" -Notes "Reported in session on 2026-03-02"

.EXAMPLE
    New-ProcessImprovement.ps1 -Source "Tools Review 2026-03-02" -SourceLink "../../feedback/reviews/tools-review-20260302.md" -Description "Fix broken path in script" -Notes "Clarity scored 3" -WhatIf

.EXAMPLE
    New-ProcessImprovement.ps1 -BatchFile "improvements.json"
    # Where improvements.json contains:
    # [
    #   { "Source": "Tools Review 2026-04-06", "SourceLink": "../../feedback/reviews/review.md", "Description": "Add batch mode" },
    #   { "Source": "User feedback", "Description": "Fix path issue", "Notes": "Urgent" }
    # ]

.EXAMPLE
    # Pilot mode (extension-origin): register a Framework Extension pilot in the Active Pilots section.
    New-ProcessImprovement.ps1 -AsPilot `
        -SourceConcept "PF-PRO-028" -OriginatingTask "PF-TSK-026" `
        -Adopters "New-IntegrationNarrative.ps1, New-Handbook.ps1" `
        -SuccessCriteria "All adopter soak counters reach 0" `
        -DecisionTrigger "When PF-IMP-685 closes" `
        -PilotNotes "Retroactive registration of script-self-verification pilot"

.EXAMPLE
    # Pilot mode (improvement-origin, PF-IMP-883): pilot a Process Improvement pattern before broadening.
    New-ProcessImprovement.ps1 -AsPilot `
        -SourceConcept "PF-IMP-880" -OriginatingTask "PF-TSK-009" `
        -Adopters "PF-TSK-009 documentation ecosystem (task / reference / implementation guide / context map)" `
        -SuccessCriteria "Agent execution stays clean across 3 PF-TSK-009 sessions on the new doc structure; reference companion is consulted at relevant steps; Document Set block proves discoverable" `
        -DecisionTrigger "After 3 PF-TSK-009 sessions on the new doc structure" `
        -PilotNotes "Diataxis-influenced 3-mode doc split piloted on PF-TSK-009 only"

.EXAMPLE
    # Cluster consolidation (PF-TSK-089 IMP Triage): create a new IMP in Intake that supersedes 3 source IMPs.
    # Each source IMP is moved to Section 7 — Rejected with Status="Superseded" and Rejection Reason="Superseded by <new-IMP-ID>".
    # Route the new IMP to its destination section in a follow-up call to Update-ProcessImprovement.ps1 -MoveToSection.
    New-ProcessImprovement.ps1 -Source "PF-TSK-089 cluster consolidation" `
        -Description "Add Add-AuditTrailPrefix helper; refactor PF-IMP-810/811/812 sites to use it" `
        -Supersedes "PF-IMP-810, PF-IMP-811, PF-IMP-812" `
        -TrackingFile "<central path>"

.EXAMPLE
    # Fast-track lane (PF-IMP-1127): log a small, already-applied framework fix directly to the
    # archive Completed section (appdev) or as a fast-track-eligible Intake one-liner (project cwd).
    New-ProcessImprovement.ps1 -FastTrack `
        -Artifact "framework-rollout-task.md" `
        -Description "Fixed stale anchor link to the usage guide pattern section" `
        -Reason "Link broke when the guide section was renamed"

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Adds entry to "Current Improvement Opportunities" table (Single/Batch) or "Active Pilots" table (-AsPilot)
    - Note: existing entries use IMP-### format; new entries use PF-IMP-### format
    - **Field length constraints** (both Single and Batch modes): Source 3-200 chars, Description 10-500 chars. Notes is uncapped (PF-IMP-1824) — the cap it used to carry gated only the first write, since Update-ProcessImprovement.ps1's -AppendNotes / -EditNotes grow the same cell without limit. If your draft Description exceeds 500 chars, compress it for table-row brevity and move detailed context to -Notes.
    - Batch mode: pass a JSON file with an array of improvement objects to register multiple items at once. Same length constraints apply; the whole batch is validated up front — every failing item is reported in one pass, and no IDs are consumed unless all items pass (PF-IMP-1247).
    - Pilot mode (-AsPilot): pilots use the same PF-IMP-NNN ID pool as regular improvements; the row goes to the "Active Pilots" section instead of "Current Improvement Opportunities". Initial status is always "Active". Use Update-ProcessImprovement.ps1 -NewStatus Resolved -Impact <HIGH|MEDIUM|LOW> to close a pilot (archives the linked concept doc and moves the pilot row to Completed Improvements — PF-IMP-729). -SourceConcept accepts PF-PRO-NNN (Framework Extension proposal — original intent) or PF-IMP-NNN (Process Improvement IMP — added PF-IMP-883 so improvement-shaped patterns get the same try-before-broaden lifecycle). -DecisionTrigger is always event-based, never calendar-based. See PF-PRO-030 for the pilot lifecycle design.

    - **Parameter sets — which parameters may be combined** (PF-IMP-1570 (C4)). Mixing parameters
      from two sets produces PowerShell's bare "Parameter set cannot be resolved using the specified
      named parameters", which names no offending parameter. That message comes from the parameter
      *binder*, before any line of this script runs, so the script cannot intercept it or improve it
      (see the Script Development Quick Reference, "Wrapper Detection of Parameter-Binding Failures").
      Use this table to find the mismatch:

        | Parameter          | Single | Batch | Pilot | FastTrack |
        |--------------------|:------:|:-----:|:-----:|:---------:|
        | -Source            |  REQ   |       |       |           |
        | -SourceLink        |  opt   |       |       |           |
        | -Description       |  REQ   |       |       |    REQ    |
        | -Notes             |  opt   |       |       |           |
        | -Supersedes        |  opt   |       |       |           |
        | -BatchFile         |        |  REQ  |       |           |
        | -AsPilot           |        |       |  REQ  |           |
        | -SourceConcept     |        |       |  REQ  |           |
        | -OriginatingTask   |        |       |  REQ  |    opt    |
        | -Adopters          |        |       |  REQ  |           |
        | -SuccessCriteria   |        |       |  REQ  |           |
        | -DecisionTrigger   |        |       |  REQ  |           |
        | -PilotNotes        |        |       |  opt  |           |
        | -FastTrack         |        |       |       |    REQ    |
        | -Artifact          |        |       |       |    REQ    |
        | -Reason            |        |       |       |    REQ    |

      Only -Description and -OriginatingTask belong to more than one set. The most common trip-up is
      passing -Reason or -Artifact (FastTrack) alongside -Source or -Notes (Single): a fast-track entry
      takes -FastTrack -Artifact -Description -Reason and nothing from the Single set.
#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "Single")]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [ValidateLength(3, 200)]
    [string]$Source,

    [Parameter(Mandatory = $false, ParameterSetName = "Single")]
    [string]$SourceLink = "",

    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [Parameter(Mandatory = $true, ParameterSetName = "FastTrack")]
    [ValidateScript({
        if ($_.Length -lt 10) {
            throw "Description is too short ($($_.Length) chars; minimum 10). Provide a more substantive description."
        }
        if ($_.Length -gt 500) {
            $over = $_.Length - 500
            throw "Description is too long ($($_.Length) chars; maximum 500, $over over). For table-row brevity, compress the description and move detailed context to -Notes."
        }
        $true
    })]
    [string]$Description,

    [Parameter(Mandatory = $false, ParameterSetName = "Single")]
    [string]$Notes = "",

    # Phase 7 (2026-05-11): -Priority, -Status, -RespTask removed from the Single path. New IMPs
    # always land in the Intake section, where the column schema is ID | Source | Description |
    # Project | Framework Version | Last Updated | Notes — no Priority/Status/Resp Task cells.
    # To prioritize or assign an IMP after triage, use Update-ProcessImprovement.ps1 -MoveToSection
    # Improvements -Priority HIGH -RespTask PF-TSK-009 (or the equivalent for Extensions/StructuralChanges).

    # --- Cluster consolidation (PF-TSK-089 IMP Triage; PF-IMP-850) ---
    # Comma-separated list of PF-IMP IDs that this new IMP supersedes. After
    # the new IMP row is created, each listed source IMP is moved to Section 7
    # — Rejected with Status="Superseded" and Rejection Reason="Superseded by
    # <new-IMP-ID>" via subprocess invocation of Update-ProcessImprovement.ps1.
    # Source IMPs must be in Intake / Improvements / Extensions / Structural
    # Changes (pilots and already-rejected rows produce warnings and are skipped).
    [Parameter(Mandatory = $false, ParameterSetName = "Single")]
    [ValidatePattern('^(PF-IMP-\d+(\s*,\s*PF-IMP-\d+)*)?$')]
    [string]$Supersedes = "",

    [Parameter(Mandatory = $true, ParameterSetName = "Batch")]
    [ValidateScript({ Test-Path $_ })]
    [string]$BatchFile,

    # --- Pilot mode (PF-PRO-030 — Pilot Tracking; widened by PF-IMP-883 to accept IMP origins) ---
    [Parameter(Mandatory = $true, ParameterSetName = "Pilot")]
    [switch]$AsPilot,

    [Parameter(Mandatory = $true, ParameterSetName = "Pilot")]
    [ValidatePattern('^(PF-PRO|PF-IMP)-\d+$')]
    [string]$SourceConcept,

    [Parameter(Mandatory = $true, ParameterSetName = "Pilot")]
    [Parameter(Mandatory = $false, ParameterSetName = "FastTrack")]
    [ValidatePattern('^[A-Z]{2,4}-TSK-\d+$')]
    [string]$OriginatingTask,

    [Parameter(Mandatory = $true, ParameterSetName = "Pilot")]
    [ValidateLength(3, 500)]
    [string]$Adopters,

    [Parameter(Mandatory = $true, ParameterSetName = "Pilot")]
    [ValidateLength(10, 500)]
    [string]$SuccessCriteria,

    [Parameter(Mandatory = $true, ParameterSetName = "Pilot")]
    [ValidateLength(3, 200)]
    [string]$DecisionTrigger,

    [Parameter(Mandatory = $false, ParameterSetName = "Pilot")]
    [string]$PilotNotes = "",

    # --- Fast-track mode (PF-IMP-1127 — F8 fast-track lane for small framework fixes) ---
    # Qualifies when ALL hold: single artifact (plus direct cross-references); content/doc-only
    # (no script behavior change); no new mechanism/section/structure; reversible by a single
    # git revert. From a producer-face workspace (declared role framework/framework-builder,
    # PF-PRO-067) the entry is written directly into the archive's Section 6 — Completed with
    # a [FAST-TRACK] origin marker; from a leaf-project cwd the same invocation files a
    # one-liner to central Intake flagged fast-track-eligible instead (Edit Target rule —
    # rolled-out framework copies are overwritten by the next Push).
    [Parameter(Mandatory = $true, ParameterSetName = "FastTrack")]
    [switch]$FastTrack,

    [Parameter(Mandatory = $true, ParameterSetName = "FastTrack")]
    [ValidateLength(3, 200)]
    [string]$Artifact,

    [Parameter(Mandatory = $true, ParameterSetName = "FastTrack")]
    [ValidateLength(3, 500)]
    [string]$Reason,

    # --- Common: optional override for tracking file path ---
    # Phase 7 (2026-05-11): default is now the central process-improvement-tracking.md at
    # appdev/process-framework-central/state-tracking/permanent/ — resolved via
    # Get-CentralFrameworkPath, so the same script binary writes to the same central file
    # whether invoked from cwd=appdev or cwd=project. -TrackingFile remains as an escape hatch
    # for tests / consolidation of legacy project-local files; production callers should not
    # pass it.
    [Parameter(Mandatory = $false)]
    [string]$TrackingFile,

    # Optional override for the archive file path (FastTrack appdev path writes here).
    # Same escape-hatch semantics as -TrackingFile: tests only.
    [Parameter(Mandatory = $false)]
    [string]$ArchiveFile
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
Invoke-StandardScriptInitialization

# MSYS path-mangling guard for user-provided -SourceLink (PF-IMP-767). Single-mode param only;
# Batch and Pilot parameter sets don't accept -SourceLink. Helper no-ops on empty input.
if (Test-MSYSPathMangled -Path $SourceLink -ParameterName 'SourceLink') {
    exit 1
}

# Soak verification (PF-PRO-028 — see process-framework-central/state-tracking/permanent/script-soak-tracking.md; v2.1 normalized ScriptId per PF-PRO-032)
$soakScriptId = "scripts/file-creation/support/New-ProcessImprovement.ps1"
$soakInSoak   = Test-ScriptInSoak -ScriptId $soakScriptId -ScriptPath $PSCommandPath

# Configuration

# Phase 7 (2026-05-11): default tracking file is the central one. Resolved via
# Get-CentralFrameworkPath so the script writes to the same file from cwd=appdev and
# cwd=project. -TrackingFile escape hatch retained for tests / one-off consolidation.
if (-not $TrackingFile) {
    $TrackingFile = Join-Path -Path (Get-CentralFrameworkPath) -ChildPath "state-tracking/permanent/process-improvement-tracking.md"
}
if (-not $ArchiveFile) {
    $ArchiveFile = Join-Path -Path (Get-CentralFrameworkPath) -ChildPath "state-tracking/permanent/archive/process-improvement-tracking-archive.md"
}
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

if (-not (Test-Path $TrackingFile)) {
    Write-ProjectError -Message "Tracking file not found: $TrackingFile" -ExitCode 1
}

# Phase 7: Project + Framework Version columns. Project format is "<id> (current-name)" per
# centralized-framework-management.md §3.7. project_id comes from doc/project-config.json;
# project_name comes from the PRODUCER's child registry (rename-safe lookup; file name and
# collection key are role-derived via Get-ChildRegistryInfo against the producer root, so the
# lookup also works from leaf-project cwds, where the workspace's own role would throw);
# a producer face holds no self-row there (PF-PRO-068 P-13), so its name falls back to the
# config's own project.name; framework_version comes from .framework-version in the rolled-out
# process-framework/ tree.
$ProjectIdValue = $null
try {
    $cfg = Get-ProjectConfig
    if ($cfg.project_id) { $ProjectIdValue = $cfg.project_id }
} catch {
    Write-Verbose "New-ProcessImprovement: could not read doc/project-config.json; Project column will be 'unknown'."
}

$ProjectDisplayName = $null
if ($ProjectIdValue) {
    try {
        $centralPath = Get-CentralFrameworkPath
        # P-10: derive the registry shape from the PRODUCER whose central this is (its root is
        # the central dir's parent) — never from the current workspace, whose leaf role throws.
        $producerReg = Get-ChildRegistryInfo -ProjectRoot (Split-Path -Parent $centralPath)
        $registryPath = Join-Path -Path $centralPath -ChildPath $producerReg.FileName
        if (Test-Path $registryPath) {
            $registry = Get-Content -Path $registryPath -Raw | ConvertFrom-Json
            $entry = $registry.$($producerReg.CollectionKey).$ProjectIdValue
            if ($entry -and $entry.name) { $ProjectDisplayName = $entry.name }
        }
    } catch {
        Write-Verbose "New-ProcessImprovement: could not resolve project name from the producer's child registry; using project_id alone."
    }
    if (-not $ProjectDisplayName) {
        # Producer face (P-13): no self-row in the child registry — own config carries the name
        try {
            if ($cfg.project -and $cfg.project.name) { $ProjectDisplayName = $cfg.project.name }
        } catch {
            Write-Verbose "New-ProcessImprovement: no config project.name fallback available."
        }
    }
}

$ProjectColumn = if ($ProjectIdValue -and $ProjectDisplayName) {
    "$ProjectIdValue ($ProjectDisplayName)"
} elseif ($ProjectIdValue) {
    $ProjectIdValue
} else {
    "unknown"
}

$FrameworkVersion = "null"
try {
    $fwVersionPath = Join-Path -Path (Get-ProcessFrameworkPath) -ChildPath ".framework-version"
    if (Test-Path $fwVersionPath) {
        $v = (Get-Content -Path $fwVersionPath -Raw).Trim()
        if ($v) { $FrameworkVersion = $v }
    }
} catch {
    Write-Verbose "New-ProcessImprovement: could not read .framework-version; Framework Version column will be 'null'."
}

# Normalize a user-supplied value for safe insertion into a single-line markdown table cell:
# collapse any run of whitespace containing a newline to one space (a raw newline would
# terminate the row and strand the rest of the value below the table — PF-IMP-1598), then
# escape unescaped pipes (PF-IMP-725). Applied to every cell value across all write paths.
function ConvertTo-SafeTableCell {
    param([string]$Value)
    if ($null -eq $Value) { return "" }
    $Value = $Value -replace '\s*[\r\n]+\s*', ' '   # newline runs (with adjacent whitespace) -> single space
    $Value = $Value -replace '(?<!\\)\|', '\|'       # unescaped | -> \|  (leaves existing \| and &#124; intact)
    return $Value.Trim()
}

# Truncate a free-text value for console echo (PF-IMP-1860): output volume must not scale
# with argument size — an unbounded -Notes echo has already pushed callers onto output
# filters that masked a real validation error. Values at or under the cap pass through;
# longer values echo a preview plus the total length. Full text stays available under
# -Verbose at each echo site; the authoritative copy is the tracking row itself.
function Format-EchoPreview {
    param(
        [string]$Text,
        [int]$MaxChars = 200
    )
    if ($null -eq $Text -or $Text.Length -le $MaxChars) { return $Text }
    return $Text.Substring(0, $MaxChars) + "… ($($Text.Length) chars total)"
}

# --- Core logic: add a single improvement to the Intake section (Phase 7 model) ---
function Add-SingleImprovement {
    param(
        [string]$ItemSource,
        [string]$ItemSourceLink,
        [string]$ItemDescription,
        [string]$ItemNotes
    )

    # Normalize newlines + escape pipes for markdown table cell safety (PF-IMP-1598 / PF-IMP-725).
    # Update-ProcessImprovement.ps1 enforces cell safety with a malformed-row error; normalizing
    # on intake avoids the fix-before-claim recovery detour.
    $ItemDescription = ConvertTo-SafeTableCell -Value $ItemDescription
    $ItemNotes = ConvertTo-SafeTableCell -Value $ItemNotes

    # Generate unique improvement ID using the central registry
    $ImprovementId = New-ProjectId -Prefix "PF-IMP" -Description "Improvement: $ItemDescription"

    Write-Host "Adding improvement opportunity: $ImprovementId" -ForegroundColor Yellow
    Write-Host "Description: $(Format-EchoPreview -Text $ItemDescription)" -ForegroundColor Cyan
    Write-Verbose "Description (full): $ItemDescription"

    # Build the Source column
    $SourceColumn = if ($ItemSourceLink -ne "") {
        "[$ItemSource]($ItemSourceLink)"
    } else {
        $ItemSource
    }

    # Read current content
    $Content = Get-Content -Path $TrackingFile -Raw -Encoding UTF8
    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # Heading pattern accepts both the canonical Phase 7 form "## Section 1 — Intake" and bare
    # "## Intake"; en-dash and hyphen variants are tolerated. Stop scanning at the next H2.
    $intakeHeadingPattern = '^##\s+(Section\s+1\s+[—–-]\s+)?Intake\b'
    $intakeHeading = $lines | Where-Object { $_ -match $intakeHeadingPattern } | Select-Object -First 1
    if (-not $intakeHeading) {
        Write-ProjectError -Message "Could not find Intake section heading in $TrackingFile. Expected a heading matching '$intakeHeadingPattern'. Verify the central tracking file structure."
        return $null
    }

    # Build the table row — header-driven (PF-IMP-1599): cells are ordered by the Intake table's
    # own header, so a schema change lands as "—" in the correct position instead of silently
    # shifting every following cell.
    $TableRow = New-HeaderDrivenTableRow -Content $Content -SectionHeading $intakeHeading -ValueMap @{
        'ID'                = $ImprovementId
        'Source'            = $SourceColumn
        'Description'       = $ItemDescription
        'Project'           = $ProjectColumn
        'Framework Version' = $FrameworkVersion
        'Last Updated'      = $CurrentDate
        'Notes'             = $ItemNotes
    }

    # Find insertion point: after the last data row in the Intake section.
    $insertAfterIndex = -1
    $inIntakeSection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $intakeHeadingPattern) { $inIntakeSection = $true; continue }
        if ($inIntakeSection) {
            if ($lines[$i] -match "^\|\s*(IMP|PF-IMP)-\d+") { $insertAfterIndex = $i }
            if ($lines[$i] -match "^##\s") { break }
        }
    }

    # If no data rows yet, insert immediately after the header separator (|---|...|)
    if ($insertAfterIndex -eq -1) {
        $inIntakeSection = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match $intakeHeadingPattern) { $inIntakeSection = $true; continue }
            if ($inIntakeSection -and $lines[$i] -match "^\|\s*-") {
                $insertAfterIndex = $i
                break
            }
            if ($inIntakeSection -and $lines[$i] -match "^##\s") { break }
        }
    }

    if ($insertAfterIndex -eq -1) {
        Write-ProjectError -Message "Could not find Intake section insertion point in $TrackingFile. Expected a heading matching '$intakeHeadingPattern' followed by a table header. Verify the central tracking file structure."
        return $null
    }

    $lines.Insert($insertAfterIndex + 1, $TableRow)
    Write-Verbose "Inserted $ImprovementId into Intake section"

    # Update frontmatter date
    $updatedContent = ($lines -join "`r`n")
    $updatedContent = Update-FrontmatterDate -Content $updatedContent -CurrentDate $CurrentDate

    # Retry-on-IOException absorbs LinkWatcher contention (PF-IMP-718)
    Invoke-FileWriteWithRetry -Context (Split-Path $TrackingFile -Leaf) -ScriptBlock {
        Set-Content -Path $TrackingFile -Value $updatedContent -NoNewline -Encoding UTF8
    }

    # Read-after-write verification: confirm the new IMP row landed in Intake
    if (-not $WhatIfPreference) {
        $rowPattern = "\|\s*" + [regex]::Escape($ImprovementId) + "\s*\|"
        Assert-TableRowInFile -Path $TrackingFile -Pattern $rowPattern -Context "tracking row for $ImprovementId in Intake"
    }

    return @{
        Id = $ImprovementId
        Source = $ItemSource
        Project = $ProjectColumn
        FrameworkVersion = $FrameworkVersion
        Notes = $ItemNotes
    }
}

# --- Core logic: add a pilot row to Active Pilots section (PF-PRO-030) ---
function Add-SinglePilot {
    param(
        [string]$ItemSourceConcept,
        [string]$ItemOriginatingTask,
        [string]$ItemAdopters,
        [string]$ItemSuccessCriteria,
        [string]$ItemDecisionTrigger,
        [string]$ItemNotes
    )

    # Generate unique pilot ID using the central registry — same PF-IMP pool as regular improvements
    $PilotId = New-ProjectId -Prefix "PF-IMP" -Description "Pilot: $ItemSourceConcept ($ItemOriginatingTask)"

    Write-Host "Adding pilot: $PilotId" -ForegroundColor Yellow
    Write-Host "Source concept: $ItemSourceConcept" -ForegroundColor Cyan
    Write-Host "Originating task: $ItemOriginatingTask" -ForegroundColor Cyan

    # Concept column: the source proposal ID; OriginatingTask is folded into Notes since the
    # central 7-col pilot schema has no separate "originating task" column.
    $ConceptColumn = $ItemSourceConcept
    $PilotDescription = "Pilot of $ItemSourceConcept (from $ItemOriginatingTask). Adopters: $ItemAdopters. Success: $ItemSuccessCriteria. Decision trigger: $ItemDecisionTrigger."
    $PilotDescription = ConvertTo-SafeTableCell -Value $PilotDescription
    $ItemNotes = ConvertTo-SafeTableCell -Value $ItemNotes

    # Read current content
    $Content = Get-Content -Path $TrackingFile -Raw -Encoding UTF8
    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # Heading pattern accepts both the canonical Phase 7 form "## Section 5 — Active Pilots"
    # and bare "## Active Pilots".
    $pilotsHeadingPattern = '^##\s+(Section\s+5\s+[—–-]\s+)?Active\s+Pilots\b'
    $pilotsHeading = $lines | Where-Object { $_ -match $pilotsHeadingPattern } | Select-Object -First 1
    if (-not $pilotsHeading) {
        Write-ProjectError -Message "Active Pilots section not found in $TrackingFile. Add the section before registering pilots (see PF-PRO-030)." -ExitCode 1
    }

    # Build the table row — header-driven (PF-IMP-1599): cells are ordered by the Active Pilots
    # table's own header, so a schema change lands as "—" in the correct position instead of
    # silently shifting every following cell.
    $TableRow = New-HeaderDrivenTableRow -Content $Content -SectionHeading $pilotsHeading -ValueMap @{
        'ID'                = $PilotId
        'Concept'           = $ConceptColumn
        'Pilot Description' = $PilotDescription
        'Project'           = $ProjectColumn
        'Framework Version' = $FrameworkVersion
        'Status'            = 'Active'
        'Notes'             = $ItemNotes
    }

    # Find insertion point in the Active Pilots section.
    $insertAfterIndex = -1
    $inActivePilotsSection = $false
    $sectionFound = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $pilotsHeadingPattern) {
            $inActivePilotsSection = $true
            $sectionFound = $true
            continue
        }
        if ($inActivePilotsSection) {
            if ($lines[$i] -match "^\|\s*(IMP|PF-IMP)-\d+") { $insertAfterIndex = $i }
            if ($lines[$i] -match "^##\s") { break }
        }
    }

    if (-not $sectionFound) {
        Write-ProjectError -Message "Active Pilots section not found in $TrackingFile. Add the section before registering pilots (see PF-PRO-030)." -ExitCode 1
    }

    # If no data rows yet, insert after the table header separator
    if ($insertAfterIndex -eq -1) {
        $inActivePilotsSection = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match $pilotsHeadingPattern) { $inActivePilotsSection = $true; continue }
            if ($inActivePilotsSection -and $lines[$i] -match "^\|\s*-") {
                $insertAfterIndex = $i
                break
            }
            if ($inActivePilotsSection -and $lines[$i] -match "^##\s") { break }
        }
    }

    if ($insertAfterIndex -eq -1) {
        Write-ProjectError -Message "Could not find insertion point in Active Pilots table (header separator missing)."
        return $null
    }

    $lines.Insert($insertAfterIndex + 1, $TableRow)
    Write-Verbose "Inserted $PilotId into Active Pilots table"

    # Update frontmatter date
    $updatedContent = ($lines -join "`r`n")
    $updatedContent = Update-FrontmatterDate -Content $updatedContent -CurrentDate $CurrentDate

    # Retry-on-IOException absorbs LinkWatcher contention (PF-IMP-718)
    Invoke-FileWriteWithRetry -Context (Split-Path $TrackingFile -Leaf) -ScriptBlock {
        Set-Content -Path $TrackingFile -Value $updatedContent -NoNewline -Encoding UTF8
    }

    # Read-after-write verification
    if (-not $WhatIfPreference) {
        $rowPattern = "\|\s*" + [regex]::Escape($PilotId) + "\s*\|"
        Assert-TableRowInFile -Path $TrackingFile -Pattern $rowPattern -Context "pilot row for $PilotId in Active Pilots"
    }

    return @{
        Id = $PilotId
        SourceConcept = $ItemSourceConcept
        OriginatingTask = $ItemOriginatingTask
        Status = "Active"
    }
}

# --- Core logic: add a fast-track entry directly to the archive Completed section (PF-IMP-1127) ---
function Add-FastTrackCompleted {
    param(
        [string]$ItemArtifact,
        [string]$ItemDescription,
        [string]$ItemReason,
        [string]$ItemOriginatingTask
    )

    # Newline-normalize + pipe-escape for markdown table cell safety (PF-IMP-1598 / PF-IMP-725, same as the intake path)
    $ItemArtifact = ConvertTo-SafeTableCell -Value $ItemArtifact
    $ItemDescription = ConvertTo-SafeTableCell -Value $ItemDescription
    $ItemReason = ConvertTo-SafeTableCell -Value $ItemReason

    $ImprovementId = New-ProjectId -Prefix "PF-IMP" -Description "Fast-track: $ItemDescription"

    Write-Host "Adding fast-track completed entry: $ImprovementId" -ForegroundColor Yellow
    Write-Host "Artifact: $ItemArtifact" -ForegroundColor Cyan

    $ImplementingTask = if ($ItemOriginatingTask) { $ItemOriginatingTask } else { "—" }

    $Content = Get-Content -Path $ArchiveFile -Raw -Encoding UTF8
    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # Heading pattern accepts both the canonical archive form "## Section 6 — Completed" and
    # bare "## Completed".
    $completedHeadingPattern = '^##\s+(Section\s+6\s+[—–-]\s+)?Completed\b'
    $completedHeading = $lines | Where-Object { $_ -match $completedHeadingPattern } | Select-Object -First 1
    if (-not $completedHeading) {
        Write-ProjectError -Message "Could not find the Section 6 — Completed table in $ArchiveFile. Expected a heading matching '$completedHeadingPattern'. Verify the archive file structure."
        return $null
    }

    # Build the table row — header-driven (PF-IMP-1599): cells are ordered by the Completed
    # table's own header, so a schema change lands as "—" in the correct position instead of
    # silently shifting every following cell. Resolved From = "Fast-track" and the [FAST-TRACK]
    # Notes prefix are the origin markers that Tools Review samples retrospectively.
    $TableRow = New-HeaderDrivenTableRow -Content $Content -SectionHeading $completedHeading -ValueMap @{
        'ID'                = $ImprovementId
        'Description'       = "${ItemArtifact}: $ItemDescription"
        'Project'           = $ProjectColumn
        'Framework Version' = $FrameworkVersion
        'Resolution Date'   = $CurrentDate
        'Implementing Task' = $ImplementingTask
        'Resolved From'     = 'Fast-track'
        'Notes'             = "[FAST-TRACK] $ItemReason"
    }

    # Insert after the Completed table's header separator (newest-first, matching
    # Update-ProcessImprovement.ps1's completion-move convention).
    $insertAfterIndex = -1
    $inCompletedSection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $completedHeadingPattern) { $inCompletedSection = $true; continue }
        if ($inCompletedSection) {
            if ($lines[$i] -match "^\|\s*-") { $insertAfterIndex = $i; break }
            if ($lines[$i] -match "^##\s") { break }
        }
    }

    if ($insertAfterIndex -eq -1) {
        Write-ProjectError -Message "Could not find the Section 6 — Completed table in $ArchiveFile. Expected a heading matching '$completedHeadingPattern' followed by a table header. Verify the archive file structure."
        return $null
    }

    $lines.Insert($insertAfterIndex + 1, $TableRow)
    Write-Verbose "Inserted $ImprovementId into archive Completed section"

    # Update frontmatter date
    $updatedContent = ($lines -join "`r`n")
    $updatedContent = Update-FrontmatterDate -Content $updatedContent -CurrentDate $CurrentDate

    # Retry-on-IOException absorbs LinkWatcher contention (PF-IMP-718)
    Invoke-FileWriteWithRetry -Context (Split-Path $ArchiveFile -Leaf) -ScriptBlock {
        Set-Content -Path $ArchiveFile -Value $updatedContent -NoNewline -Encoding UTF8
    }

    # Read-after-write verification
    if (-not $WhatIfPreference) {
        $rowPattern = "\|\s*" + [regex]::Escape($ImprovementId) + "\s*\|"
        Assert-TableRowInFile -Path $ArchiveFile -Pattern $rowPattern -Context "fast-track completed row for $ImprovementId"
    }

    return @{
        Id = $ImprovementId
        Artifact = $ItemArtifact
        Project = $ProjectColumn
    }
}

# --- Cluster consolidation helper (PF-TSK-089 IMP Triage; PF-PRO-029 Phase 4) ---

function Invoke-SupersedeSources {
    # For each ID in the comma-separated list, invoke Update-ProcessImprovement.ps1
    # as a subprocess to move the source IMP to Section 7 — Rejected with
    # Status="Superseded" and Rejection Reason="Superseded by <NewImpId>".
    #
    # Subprocess invocation keeps this script loosely coupled to
    # Update-ProcessImprovement.ps1's local Move-ToRejectedAsSuperseded function
    # (no shared module). Per-source failures (e.g., source in an unsupported
    # section like Active Pilots or Rejected, malformed row) emit warnings and
    # continue; the new consolidating IMP in Intake is created regardless.
    param(
        [string]$NewImpId,
        [string]$SupersedesCsv,
        [string]$TrackingFilePath
    )

    if (-not $SupersedesCsv -or $SupersedesCsv.Trim() -eq "") {
        return
    }

    $sourceIds = $SupersedesCsv -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    if ($sourceIds.Count -eq 0) {
        return
    }

    Write-Host "Superseding $($sourceIds.Count) source IMP(s) into ${NewImpId}: $($sourceIds -join ', ')" -ForegroundColor Cyan

    # Resolve path to Update-ProcessImprovement.ps1 relative to this script's directory.
    # This script: process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1
    # Target:      process-framework/scripts/update/Update-ProcessImprovement.ps1
    $updateScript = Join-Path -Path $PSScriptRoot -ChildPath "..\..\update\Update-ProcessImprovement.ps1"
    try {
        $updateScript = (Resolve-Path -Path $updateScript -ErrorAction Stop).Path
    } catch {
        Write-Warning "Could not resolve Update-ProcessImprovement.ps1 at $updateScript. Source IMPs were not superseded; the new consolidating IMP ($NewImpId) was created in Intake but the $($sourceIds.Count) source IMP(s) still need manual supersession."
        return
    }

    $supersededCount = 0
    $failedIds = @()

    foreach ($srcId in $sourceIds) {
        $output = & pwsh.exe -ExecutionPolicy Bypass -File $updateScript `
            -ImprovementId $srcId `
            -NewStatus "Superseded" `
            -SupersededBy $NewImpId `
            -ValidationNotes "Cluster consolidation: superseded into $NewImpId via PF-TSK-089 IMP Triage" `
            -TrackingFile $TrackingFilePath `
            -Confirm:$false 2>&1
        if ($LASTEXITCODE -eq 0) {
            $supersededCount++
        } else {
            $failedIds += $srcId
            Write-Warning "Failed to supersede ${srcId} (exit code $LASTEXITCODE). Subprocess output:`n$($output | Out-String)"
        }
    }

    if ($failedIds.Count -gt 0) {
        Write-Warning "Could not supersede the following source IMPs: $($failedIds -join ', '). The new consolidating IMP ($NewImpId) was created successfully; these source IMPs require manual investigation (likely already in Rejected/Pilots, or malformed rows)."
    }

    if ($supersededCount -gt 0) {
        Write-Host "Superseded $supersededCount source IMP(s) into $NewImpId" -ForegroundColor Green
    }
}

# --- Dispatch: FastTrack vs Pilot vs Batch vs Single mode ---
if ($PSCmdlet.ParameterSetName -eq "FastTrack") {
    # Fast-track lane (PF-IMP-1127): a producer-face workspace (declared role framework /
    # framework-builder — the "may I author blueprint/shipped material?" role question,
    # PF-PRO-067 Contract 4) writes the entry directly into the archive Completed section;
    # leaf-project cwds file a fast-track-eligible Intake one-liner instead (Edit Target
    # rule — a leaf's framework copy is overwritten by rollout).
    if ((Get-WorkspaceRole) -in @('framework', 'framework-builder')) {
        if (-not (Test-Path $ArchiveFile)) {
            Write-ProjectError -Message "Archive file not found: $ArchiveFile" -ExitCode 1
        }
        if (-not $PSCmdlet.ShouldProcess($ArchiveFile, "Add fast-track completed entry for '$Artifact'")) {
            return
        }

        try {
            $result = Add-FastTrackCompleted `
                -ItemArtifact $Artifact `
                -ItemDescription $Description `
                -ItemReason $Reason `
                -ItemOriginatingTask $OriginatingTask

            if ($result) {
                Write-ProjectSuccess -Message "Logged fast-track fix: $($result.Id)" -Details @(
                    "Artifact: $Artifact",
                    "Section: archive Section 6 — Completed (Resolved From: Fast-track)",
                    "Reason: $(Format-EchoPreview -Text $Reason)"
                )
                Write-Verbose "Reason (full): $Reason"
                Write-Verbose "Next Steps: none — fast-track entries are complete on creation. Tools Review samples [FAST-TRACK] entries retrospectively."

                if ($soakInSoak) {
                    Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
                }

                # PF-IMP-1240: emit the created ID to the output stream for capture/chaining.
                Write-Output $result.Id
            }
        }
        catch {
            if ($soakInSoak) {
                $soakErrMsg = $_.Exception.Message
                if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
                Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome failure -Notes $soakErrMsg
            }
            Write-ProjectError -Message "Failed to create fast-track entry: $($_.Exception.Message)" -ExitCode 1
        }
    } else {
        if (-not $PSCmdlet.ShouldProcess($TrackingFile, "File fast-track-eligible intake entry for '$Artifact'")) {
            return
        }

        try {
            $ftSource = if ($OriginatingTask) { "Fast-track ($OriginatingTask)" } else { "Fast-track" }
            $result = Add-SingleImprovement `
                -ItemSource $ftSource `
                -ItemSourceLink "" `
                -ItemDescription "${Artifact}: $Description" `
                -ItemNotes "fast-track-eligible. $Reason"

            if ($result) {
                Write-ProjectSuccess -Message "Filed fast-track-eligible intake entry: $($result.Id)" -Details @(
                    "Artifact: $Artifact",
                    "Section: Intake (flagged fast-track-eligible for a fast appdev apply)",
                    "Project: $($result.Project)"
                )
                Write-Verbose "Next Steps: an appdev session applies the fix and completes the entry via the fast-track lane."

                if ($soakInSoak) {
                    Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
                }

                # PF-IMP-1240: emit the created ID to the output stream for capture/chaining.
                Write-Output $result.Id
            }
        }
        catch {
            if ($soakInSoak) {
                $soakErrMsg = $_.Exception.Message
                if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
                Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome failure -Notes $soakErrMsg
            }
            Write-ProjectError -Message "Failed to file fast-track-eligible intake entry: $($_.Exception.Message)" -ExitCode 1
        }
    }

} elseif ($PSCmdlet.ParameterSetName -eq "Pilot") {
    if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Register pilot for $SourceConcept ($OriginatingTask) in Active Pilots")) {
        return
    }

    try {
        $result = Add-SinglePilot `
            -ItemSourceConcept $SourceConcept `
            -ItemOriginatingTask $OriginatingTask `
            -ItemAdopters $Adopters `
            -ItemSuccessCriteria $SuccessCriteria `
            -ItemDecisionTrigger $DecisionTrigger `
            -ItemNotes $PilotNotes

        if ($result) {
            $details = @(
                "ID: $($result.Id)",
                "Source: $SourceConcept / $OriginatingTask",
                "Adopters: $Adopters",
                "Decision Trigger: $DecisionTrigger",
                "Status: Active"
            )
            if ($PilotNotes -ne "") {
                $details += "Notes: $(Format-EchoPreview -Text $PilotNotes)"
                Write-Verbose "Notes (full): $PilotNotes"
            }

            Write-ProjectSuccess -Message "Registered pilot: $($result.Id)" -Details $details

            Write-Verbose "Next Steps: Pilot is in 'Active' status; resolve via Update-ProcessImprovement.ps1 -NewStatus Resolved when the decision trigger fires"
            Write-Verbose "Next Steps: Concept doc archive will be triggered automatically on Resolved"

            if ($soakInSoak) {
                Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
            }

            # PF-IMP-1240: emit the created pilot ID to the output stream for capture/chaining.
            Write-Output $result.Id
        }
    }
    catch {
        if ($soakInSoak) {
            $soakErrMsg = $_.Exception.Message
            if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
            Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome failure -Notes $soakErrMsg
        }
        Write-ProjectError -Message "Failed to register pilot: $($_.Exception.Message)" -ExitCode 1
    }

} elseif ($PSCmdlet.ParameterSetName -eq "Batch") {
    # Batch mode: read JSON array from file
    try {
        $jsonContent = Get-Content -Path $BatchFile -Raw -Encoding UTF8
        # @() normalizes the single-element case: ConvertFrom-Json enumerates a 1-element array
        # to a scalar, which would otherwise look like a non-array.
        $items = @($jsonContent | ConvertFrom-Json)
    }
    catch {
        Write-ProjectError -Message "Failed to parse batch file '$BatchFile': $($_.Exception.Message)" -ExitCode 1
    }

    # Array-ness is checked textually: @() above makes every parse result an array, so the
    # shape of $items can no longer distinguish a bare JSON object from a 1-element array.
    if (-not ($jsonContent.TrimStart().StartsWith('['))) {
        Write-ProjectError -Message "Batch file must contain a JSON array of improvement objects" -ExitCode 1
    }

    Write-Host "Batch mode: processing $($items.Count) improvements from $BatchFile" -ForegroundColor Magenta

    # Validate all items before consuming any IDs. Phase 7: Priority/Status/RespTask fields are
    # ignored on intake (Intake-section schema has no such columns); a warning is emitted instead
    # of an error so existing batch JSON files still process without re-authoring.
    $allErrors = @()
    for ($idx = 0; $idx -lt $items.Count; $idx++) {
        $item = $items[$idx]
        $errors = @()
        if (-not $item.Source) { $errors += "missing Source" }
        elseif ($item.Source.Length -lt 3) { $errors += "Source is too short ($($item.Source.Length) chars; minimum 3)" }
        elseif ($item.Source.Length -gt 200) {
            $over = $item.Source.Length - 200
            $errors += "Source is too long ($($item.Source.Length) chars; maximum 200, $over over) — shorten the source label"
        }
        if (-not $item.Description) { $errors += "missing Description" }
        elseif ($item.Description.Length -lt 10) { $errors += "Description is too short ($($item.Description.Length) chars; minimum 10) — provide a more substantive description" }
        elseif ($item.Description.Length -gt 500) {
            $over = $item.Description.Length - 500
            $errors += "Description is too long ($($item.Description.Length) chars; maximum 500, $over over) — for table-row brevity, compress the description and move detailed context to the Notes field"
        }
        if ($item.Priority -or $item.Status -or $item.RespTask) {
            Write-Warning "Item [$idx]: Priority/Status/RespTask fields are no longer applied during intake (Phase 7). Run Update-ProcessImprovement.ps1 -MoveToSection after creation to set them."
        }
        if ($errors.Count -gt 0) {
            $allErrors += "Item [$idx]: $($errors -join '; ')"
        }
    }

    # PF-IMP-1247: report EVERY invalid item in one pass (was: abort on the first failing
    # item, forcing a fix-one-rerun loop). Validation runs before any ID is consumed, so the
    # all-or-nothing contract holds — a fully-clean batch is required before creation begins.
    if ($allErrors.Count -gt 0) {
        $summary = "Batch validation failed for $($allErrors.Count) of $($items.Count) item(s); no IDs were consumed. Fix all and re-run:`n  - " + ($allErrors -join "`n  - ")
        Write-ProjectError -Message $summary -ExitCode 1
    }

    if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Add $($items.Count) improvement opportunities from batch file")) {
        return
    }

    $created = @()
    foreach ($item in $items) {
        $result = Add-SingleImprovement `
            -ItemSource $item.Source `
            -ItemSourceLink $(if ($item.SourceLink) { $item.SourceLink } else { "" }) `
            -ItemDescription $item.Description `
            -ItemNotes $(if ($item.Notes) { $item.Notes } else { "" })

        if ($result) {
            $created += $result
            Write-Host ""
        }
    }

    Write-Host "========================================" -ForegroundColor Magenta
    Write-ProjectSuccess -Message "Batch complete: $($created.Count)/$($items.Count) improvements created" -Details ($created | ForEach-Object { "$($_.Id) ($($_.Project))" })

    if ($soakInSoak) {
        Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
    }

    # PF-IMP-1240: emit each created ID to the output stream for capture/chaining.
    $created | ForEach-Object { Write-Output $_.Id }

} else {
    # Single mode: original behavior
    if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Add new improvement opportunity '$Description'")) {
        return
    }

    try {
        $result = Add-SingleImprovement `
            -ItemSource $Source `
            -ItemSourceLink $SourceLink `
            -ItemDescription $Description `
            -ItemNotes $Notes

        if ($result) {
            # Cluster consolidation: supersede source IMPs into this new one.
            # Runs only when -Supersedes is supplied; safely no-ops otherwise.
            if ($Supersedes -ne "") {
                Invoke-SupersedeSources `
                    -NewImpId $result.Id `
                    -SupersedesCsv $Supersedes `
                    -TrackingFilePath $TrackingFile
            }

            $details = @(
                "ID: $($result.Id)",
                "Source: $Source",
                "Section: Intake",
                "Project: $($result.Project)",
                "Framework Version: $($result.FrameworkVersion)"
            )
            if ($Notes -ne "") {
                $details += "Notes: $(Format-EchoPreview -Text $Notes)"
                Write-Verbose "Notes (full): $Notes"
            }
            if ($Supersedes -ne "") { $details += "Supersedes: $Supersedes" }

            Write-ProjectSuccess -Message "Created improvement opportunity: $($result.Id)" -Details $details

            Write-Verbose "Next Steps: Run the IMP Triage Task (PF-TSK-089) to route from Intake to Improvements / Extensions / Structural Changes / Rejected."
            Write-Verbose "Next Steps: Use Update-ProcessImprovement.ps1 -MoveToSection after triage to set Priority / Status / Resp Task."

            if ($soakInSoak) {
                Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
            }

            # PF-IMP-1240: emit the created ID to the output stream so callers (e.g. IMP Triage
            # create-then-route chaining) can capture it: $id = & New-ProcessImprovement.ps1 ...
            Write-Output $result.Id
        }
    }
    catch {
        if ($soakInSoak) {
            $soakErrMsg = $_.Exception.Message
            if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
            Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome failure -Notes $soakErrMsg
        }
        Write-ProjectError -Message "Failed to create improvement entry: $($_.Exception.Message)" -ExitCode 1
    }
}
