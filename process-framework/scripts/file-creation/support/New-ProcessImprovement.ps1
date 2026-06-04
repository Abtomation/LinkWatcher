# New-ProcessImprovement.ps1
# Adds a new improvement opportunity to the Process Improvement Tracking state file
# Uses the central ID registry system for auto-assigned PF-IMP IDs

<#
.SYNOPSIS
    Adds a new improvement opportunity to process-improvement-tracking.md with an auto-assigned ID.

.DESCRIPTION
    This PowerShell script creates new improvement entries by:
    - Generating a unique improvement ID (PF-IMP-###) via the central ID registry
    - Adding a row to the "Current Improvement Opportunities" table
    - Updating the frontmatter date

    Field length constraints (validated at runtime): -Source 3-200 chars,
    -Description 10-500 chars, -Notes 0-2000 chars. If a Description draft
    exceeds 500 chars, compress it for table-row brevity and move detail to -Notes.

.PARAMETER Source
    Display text for the source of this improvement (e.g., "Tools Review 2026-03-02", "User feedback")

.PARAMETER SourceLink
    Optional markdown link target for the source. When provided, the Source column renders as [Source](SourceLink).

.PARAMETER Description
    What needs to be improved (10-500 chars; for table-row brevity, compress longer drafts and move detailed context to -Notes).

.PARAMETER Priority
    Priority level: HIGH, MEDIUM, or LOW

.PARAMETER Notes
    Additional context or details (optional, 0-2000 chars; for longer detail, link to a separate document)

.PARAMETER Status
    Initial status (default: "NeedsPrioritization"). Valid: NeedsPrioritization, NeedsImplementation

.PARAMETER RespTask
    Optional responsible task ID (e.g., "PF-TSK-014", "PF-TSK-026") indicating which task owns implementation when routing exceeds the default PF-TSK-009 (Process Improvement) scope. Leave blank when routing is the standard PF-TSK-009 path. Format: bare task ID matching '^PF-TSK-\d+$'.

.PARAMETER Supersedes
    Comma-separated list of PF-IMP IDs that this new IMP supersedes (cluster-consolidation case from PF-TSK-089 IMP Triage). After the new IMP row is created, each listed source IMP is moved to Section 7 — Rejected with `Status = "Superseded"` and `Rejection Reason = "Superseded by <new-IMP-ID>"` via subprocess invocation of Update-ProcessImprovement.ps1. Source IMPs must be in Intake / Improvements / Extensions / Structural Changes; pilots and already-rejected rows produce warnings and are skipped. Idempotent: re-running with the same list emits warnings on already-superseded sources but does not corrupt state. Example: -Supersedes "PF-IMP-810,PF-IMP-811,PF-IMP-812".

.PARAMETER AsPilot
    Switch that selects the Pilot parameter set. Registers a row in the Active Pilots section (Section 5) of process-improvement-tracking.md instead of the Intake section. Pilots track "try-on-one-instance-before-broaden" decisions and share the PF-IMP ID pool with regular improvements.

.PARAMETER SourceConcept
    ID of the originating concept this pilot trials. Accepts PF-PRO-NNN (Framework Extension proposal — the original intent) or PF-IMP-NNN (Process Improvement IMP — added PF-IMP-883 so IMP-shaped pilots have a lifecycle slot). Format: '^(PF-PRO|PF-IMP)-\d+$'. The pilot phase is logically prior to extension classification: a Process Improvement that turns out to broadly apply becomes extension-shaped only after the pilot proves it.

.PARAMETER OriginatingTask
    Task ID of the task that filed this pilot (e.g., PF-TSK-009, PF-TSK-026). Format: '^PF-TSK-\d+$'.

.PARAMETER Adopters
    Free-form description of where the pilot is being trialed — files, scripts, task ecosystems. 3-500 chars.

.PARAMETER SuccessCriteria
    Observable criteria that, when met during the pilot, indicate the pattern is worth broadening. 10-500 chars. Examples: "All adopter soak counters reach 0", "Agent execution stays clean across N sessions on the new structure".

.PARAMETER DecisionTrigger
    Event phrase describing when the keep/abandon decision should be made. Always event-based, never calendar-based — pilots intentionally stay open until the triggering event fires. 3-200 chars. Examples: "After 3 Process Improvement sessions on the new doc structure", "When PF-IMP-685 closes", "When first user-doc rollout completes".

.PARAMETER PilotNotes
    Optional context for the pilot row (0-2000 chars).

.PARAMETER TrackingFile
    Optional override for the tracking file path. Defaults to the project-local file. Until PF-PRO-029 Phase 7 cuts over the default, pass -TrackingFile <central-path> when targeting the centralized 7-section file (e.g., for cluster consolidation that needs to supersede central-file rows).

.EXAMPLE
    New-ProcessImprovement.ps1 -Source "Tools Review 2026-03-02" -SourceLink "../../feedback/reviews/tools-review-20260302.md" -Description "Add validation to script X" -Priority "MEDIUM"

.EXAMPLE
    New-ProcessImprovement.ps1 -Source "User feedback" -Description "Simplify feedback form process" -Priority "HIGH" -Notes "Reported in session on 2026-03-02"

.EXAMPLE
    New-ProcessImprovement.ps1 -Source "Tools Review 2026-03-02" -SourceLink "../../feedback/reviews/tools-review-20260302.md" -Description "Fix broken path in script" -Priority "LOW" -Notes "Clarity scored 3" -WhatIf

.EXAMPLE
    New-ProcessImprovement.ps1 -BatchFile "improvements.json"
    # Where improvements.json contains:
    # [
    #   { "Source": "Tools Review 2026-04-06", "SourceLink": "../../feedback/reviews/review.md", "Description": "Add batch mode", "Priority": "LOW" },
    #   { "Source": "User feedback", "Description": "Fix path issue", "Priority": "HIGH", "Notes": "Urgent" }
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

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Adds entry to "Current Improvement Opportunities" table (Single/Batch) or "Active Pilots" table (-AsPilot)
    - Note: existing entries use IMP-### format; new entries use PF-IMP-### format
    - **Field length constraints** (both Single and Batch modes): Source 3-200 chars, Description 10-500 chars, Notes 0-2000 chars. If your draft Description exceeds 500 chars, compress it for table-row brevity and move detailed context to -Notes; if Notes itself exceeds 2000 chars, link to a separate document instead of inlining.
    - Batch mode: pass a JSON file with an array of improvement objects to register multiple items at once. Same length constraints apply; the entire batch aborts on the first item with errors before any IDs are consumed.
    - Pilot mode (-AsPilot): pilots use the same PF-IMP-NNN ID pool as regular improvements; the row goes to the "Active Pilots" section instead of "Current Improvement Opportunities". Initial status is always "Active". Use Update-ProcessImprovement.ps1 -NewStatus Resolved -Impact <HIGH|MEDIUM|LOW> to close a pilot (archives the linked concept doc and moves the pilot row to Completed Improvements — PF-IMP-729). -SourceConcept accepts PF-PRO-NNN (Framework Extension proposal — original intent) or PF-IMP-NNN (Process Improvement IMP — added PF-IMP-883 so improvement-shaped patterns get the same try-before-broaden lifecycle). -DecisionTrigger is always event-based, never calendar-based. See PF-PRO-030 for the pilot lifecycle design.
#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "Single")]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
    [ValidateLength(3, 200)]
    [string]$Source,

    [Parameter(Mandatory = $false, ParameterSetName = "Single")]
    [string]$SourceLink = "",

    [Parameter(Mandatory = $true, ParameterSetName = "Single")]
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
    [ValidateScript({
            if ($_.Length -gt 2000) {
                $over = $_.Length - 2000
                throw "Notes is too long ($($_.Length) chars; maximum 2000, $over over). Trim the notes or link to a separate document for detailed context."
            }
            $true
        })]
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
    [ValidatePattern('^PF-TSK-\d+$')]
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
    [ValidateScript({
            if ($_.Length -gt 2000) {
                $over = $_.Length - 2000
                throw "Notes is too long ($($_.Length) chars; maximum 2000, $over over)."
            }
            $true
        })]
    [string]$PilotNotes = "",

    # --- Common: optional override for tracking file path ---
    # Phase 7 (2026-05-11): default is now the central process-improvement-tracking.md at
    # appdev/process-framework-central/state-tracking/permanent/ — resolved via
    # Get-CentralFrameworkPath, so the same script binary writes to the same central file
    # whether invoked from cwd=appdev or cwd=project. -TrackingFile remains as an escape hatch
    # for tests / consolidation of legacy project-local files; production callers should not
    # pass it.
    [Parameter(Mandatory = $false)]
    [string]$TrackingFile
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
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

if (-not (Test-Path $TrackingFile)) {
    Write-ProjectError -Message "Tracking file not found: $TrackingFile" -ExitCode 1
}

# Phase 7: Project + Framework Version columns. Project format is "PRJ-NNN (current-name)" per
# centralized-framework-management.md §3.7. project_id comes from doc/project-config.json;
# project_name comes from project-registry.json (rename-safe lookup); framework_version comes
# from .framework-version in the rolled-out process-framework/ tree.
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
        $registryPath = Join-Path -Path (Get-CentralFrameworkPath) -ChildPath "project-registry.json"
        if (Test-Path $registryPath) {
            $registry = Get-Content -Path $registryPath -Raw | ConvertFrom-Json
            $entry = $registry.projects.$ProjectIdValue
            if ($entry -and $entry.name) { $ProjectDisplayName = $entry.name }
        }
    } catch {
        Write-Verbose "New-ProcessImprovement: could not resolve project name from project-registry.json; using project_id alone."
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

# --- Core logic: add a single improvement to the Intake section (Phase 7 model) ---
function Add-SingleImprovement {
    param(
        [string]$ItemSource,
        [string]$ItemSourceLink,
        [string]$ItemDescription,
        [string]$ItemNotes
    )

    # Auto-escape unescaped pipes for markdown table cell safety (PF-IMP-725).
    # Update-ProcessImprovement.ps1 enforces this with a malformed-row error;
    # escaping on intake avoids the fix-before-claim recovery detour. Negative
    # lookbehind preserves any pipes already escaped as \|; HTML-entity escapes
    # (&#124;) are unaffected since they contain no literal |.
    $ItemDescription = $ItemDescription -replace '(?<!\\)\|', '\|'
    $ItemNotes = $ItemNotes -replace '(?<!\\)\|', '\|'

    # Generate unique improvement ID using the central registry
    $ImprovementId = New-ProjectId -Prefix "PF-IMP" -Description "Improvement: $ItemDescription"

    Write-Host "Adding improvement opportunity: $ImprovementId" -ForegroundColor Yellow
    Write-Host "Description: $ItemDescription" -ForegroundColor Cyan

    # Build the Source column
    $SourceColumn = if ($ItemSourceLink -ne "") {
        "[$ItemSource]($ItemSourceLink)"
    } else {
        $ItemSource
    }

    # Build the table row — Phase 7 Intake schema (7 cols):
    # | ID | Source | Description | Project | Framework Version | Last Updated | Notes |
    $TableRow = "| $ImprovementId | $SourceColumn | $ItemDescription | $ProjectColumn | $FrameworkVersion | $CurrentDate | $ItemNotes |"

    # Read current content
    $Content = Get-Content -Path $TrackingFile -Raw -Encoding UTF8
    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # Find insertion point: after the last data row in the Intake section.
    # Heading pattern accepts both the canonical Phase 7 form "## Section 1 — Intake" and bare
    # "## Intake"; en-dash and hyphen variants are tolerated. Stop scanning at the next H2.
    $intakeHeadingPattern = '^##\s+(Section\s+1\s+[—–-]\s+)?Intake\b'
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
    Write-Host "Inserted $ImprovementId into Intake section" -ForegroundColor Green

    # Update frontmatter date
    $updatedContent = ($lines -join "`r`n")
    $updatedContent = $updatedContent -replace '(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate

    # Retry-on-IOException absorbs LinkWatcher contention (PF-IMP-718)
    Invoke-FileWriteWithRetry -Context (Split-Path $TrackingFile -Leaf) -ScriptBlock {
        Set-Content -Path $TrackingFile -Value $updatedContent -NoNewline -Encoding UTF8
    }

    # Read-after-write verification: confirm the new IMP row landed in Intake
    if (-not $WhatIfPreference) {
        $rowPattern = "\|\s*" + [regex]::Escape($ImprovementId) + "\s*\|"
        Assert-LineInFile -Path $TrackingFile -Pattern $rowPattern -Context "tracking row for $ImprovementId in Intake"
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
    $PilotDescription = $PilotDescription -replace '(?<!\\)\|', '\|'
    $ItemNotes = $ItemNotes -replace '(?<!\\)\|', '\|'

    # Build the table row — Phase 7 Active Pilots schema (7 cols):
    # | ID | Concept | Pilot Description | Project | Framework Version | Status | Notes |
    $TableRow = "| $PilotId | $ConceptColumn | $PilotDescription | $ProjectColumn | $FrameworkVersion | Active | $ItemNotes |"

    # Read current content
    $Content = Get-Content -Path $TrackingFile -Raw -Encoding UTF8
    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # Find insertion point in the Active Pilots section. Heading pattern accepts both the
    # canonical Phase 7 form "## Section 5 — Active Pilots" and bare "## Active Pilots".
    $pilotsHeadingPattern = '^##\s+(Section\s+5\s+[—–-]\s+)?Active\s+Pilots\b'
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
    Write-Host "Inserted $PilotId into Active Pilots table" -ForegroundColor Green

    # Update frontmatter date
    $updatedContent = ($lines -join "`r`n")
    $updatedContent = $updatedContent -replace '(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate

    # Retry-on-IOException absorbs LinkWatcher contention (PF-IMP-718)
    Invoke-FileWriteWithRetry -Context (Split-Path $TrackingFile -Leaf) -ScriptBlock {
        Set-Content -Path $TrackingFile -Value $updatedContent -NoNewline -Encoding UTF8
    }

    # Read-after-write verification
    if (-not $WhatIfPreference) {
        $rowPattern = "\|\s*" + [regex]::Escape($PilotId) + "\s*\|"
        Assert-LineInFile -Path $TrackingFile -Pattern $rowPattern -Context "pilot row for $PilotId in Active Pilots"
    }

    return @{
        Id = $PilotId
        SourceConcept = $ItemSourceConcept
        OriginatingTask = $ItemOriginatingTask
        Status = "Active"
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

# --- Dispatch: Pilot vs Batch vs Single mode ---
if ($PSCmdlet.ParameterSetName -eq "Pilot") {
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
            if ($PilotNotes -ne "") { $details += "Notes: $PilotNotes" }

            Write-ProjectSuccess -Message "Registered pilot: $($result.Id)" -Details $details

            Write-Verbose "Next Steps: Pilot is in 'Active' status; resolve via Update-ProcessImprovement.ps1 -NewStatus Resolved when the decision trigger fires"
            Write-Verbose "Next Steps: Concept doc archive will be triggered automatically on Resolved"

            if ($soakInSoak) {
                Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
            }
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
        $items = $jsonContent | ConvertFrom-Json
    }
    catch {
        Write-ProjectError -Message "Failed to parse batch file '$BatchFile': $($_.Exception.Message)" -ExitCode 1
    }

    if ($items -isnot [System.Array]) {
        Write-ProjectError -Message "Batch file must contain a JSON array of improvement objects" -ExitCode 1
    }

    Write-Host "Batch mode: processing $($items.Count) improvements from $BatchFile" -ForegroundColor Magenta

    # Validate all items before consuming any IDs. Phase 7: Priority/Status/RespTask fields are
    # ignored on intake (Intake-section schema has no such columns); a warning is emitted instead
    # of an error so existing batch JSON files still process without re-authoring.
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
        if ($item.Notes -and $item.Notes.Length -gt 2000) {
            $over = $item.Notes.Length - 2000
            $errors += "Notes is too long ($($item.Notes.Length) chars; maximum 2000, $over over) — trim the notes or link to a separate document for detailed context"
        }
        if ($item.Priority -or $item.Status -or $item.RespTask) {
            Write-Warning "Item [$idx]: Priority/Status/RespTask fields are no longer applied during intake (Phase 7). Run Update-ProcessImprovement.ps1 -MoveToSection after creation to set them."
        }
        if ($errors.Count -gt 0) {
            Write-ProjectError -Message "Item [$idx]: $($errors -join '; ')" -ExitCode 1
        }
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
            if ($Notes -ne "") { $details += "Notes: $Notes" }
            if ($Supersedes -ne "") { $details += "Supersedes: $Supersedes" }

            Write-ProjectSuccess -Message "Created improvement opportunity: $($result.Id)" -Details $details

            Write-Verbose "Next Steps: Run the IMP Triage Task (PF-TSK-089) to route from Intake to Improvements / Extensions / Structural Changes / Rejected."
            Write-Verbose "Next Steps: Use Update-ProcessImprovement.ps1 -MoveToSection after triage to set Priority / Status / Resp Task."

            if ($soakInSoak) {
                Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
            }
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
