# New-PendingMigration.ps1
# Scaffolds a Pending Migration Entry in one or more projects' per-project ledgers
# (appdev/process-framework-central/per-project-migrations/<PRJ-NNN>/pending-migrations.md).
# Allocates the per-project MIG-NNN counter, inserts the Summary-table row AND the per-entry
# section skeleton (PF-TEM-079 full / PF-TEM-080 cleanup) in one write.

<#
.SYNOPSIS
    Scaffolds Pending Migration Entries (Summary row + entry skeleton) across one or more project ledgers, allocating each per-project MIG-NNN automatically.

.DESCRIPTION
    Written for the Structure Change task (PF-TSK-014) Step 14.5, where one structural change in
    appdev/blueprint/ that affects project working docs must be recorded as a migration entry in
    EVERY affected registered project's ledger — previously a manual, error-prone copy-paste
    (PF-IMP-931). For each target project this script:

    - Resolves the ledger at <central>/per-project-migrations/<PRJ-NNN>/pending-migrations.md
      (central root via Get-CentralFrameworkPath, so it works from cwd=appdev or cwd=project).
    - Allocates the next per-project MIG-NNN (highest existing in that ledger + 1; per-project
      counters are independent).
    - Inserts a Summary-table row and a per-entry section skeleton in a single write.
    - Picks the Full (PF-TEM-079) or Cleanup (PF-TEM-080) entry shape via -Variant.

    The script scaffolds STRUCTURE only — the substantive prose (Description, Migration Steps,
    Rollback-Implications reasoning, Validation) is left as `<!-- TODO -->` placeholders for the
    author to fill, exactly as the other New-*.ps1 scaffolders do. The win is correct MIG-NNN
    sequencing, a consistent skeleton, and one-call fan-out across projects — not content
    generation.

    Project targeting (Direct mode): pass -Project PRJ-NNN (one or comma-separated many), or
    -AllProjects to fan out to every eligible registered project (excludes appdev PRJ-000,
    PRJ-T* sandboxes, and version-frozen projects; the skipped set is logged).

    Batch mode (-BatchFile): a JSON array of migration objects, each with its own fields and a
    "Projects" array or "AllProjects": true. All items are validated before any write.

.PARAMETER Project
    One or more target project IDs (e.g., PRJ-001 or PRJ-001,PRJ-002). Mutually exclusive with
    -AllProjects. Direct mode.

.PARAMETER AllProjects
    Fan out to every eligible registered project (from project-registry.json), excluding appdev
    (PRJ-000), PRJ-T* sandboxes, and version-frozen projects. Mutually exclusive with -Project.

.PARAMETER Title
    Verb-first one-line entry title (5-200 chars), e.g. "Add 'priority' column to feature-tracking.md".

.PARAMETER Source
    Display text for the Source field, e.g. "PF-IMP-931" or "PF-STA-005 (Phase 3d Session 9)".

.PARAMETER SourceLink
    Optional relative path for the Source link. When provided, the Source cell renders as
    [Source](SourceLink).

.PARAMETER SourceFrameworkVersion
    The framework version containing this migration. Defaults to "<today>-NNN (assigned at next
    Push)" — the entry is authored before the Push that assigns the real version, matching the
    existing ledger convention.

.PARAMETER TargetFiles
    One or more project-relative target descriptions, each rendered as a Target Files bullet.
    Provide each as "`path` — one-line summary of what changes there".

.PARAMETER BackwardCompatible
    yes | no — the load-bearing Rollback-Implications value consumed by Framework Rollout Mode D.
    Drives which Rollback-Implications scaffold is emitted.

.PARAMETER Variant
    Full (PF-TEM-079, default) or Cleanup (PF-TEM-080, for no-data-motion empty-dir/placeholder/
    single-config cleanups).

.PARAMETER Description
    Optional Description prose. When omitted, a TODO placeholder is inserted.

.PARAMETER Notes
    Optional free-form notes (Full variant only; adds a #### Notes section when provided).

.PARAMETER BatchFile
    Path to a JSON array of migration objects. Each object: Title, Source, [SourceLink],
    [SourceFrameworkVersion], TargetFiles (array), BackwardCompatible, [Variant], [Description],
    [Notes], and either "Projects": ["PRJ-001", ...] or "AllProjects": true.

.EXAMPLE
    # One migration, two named projects:
    New-PendingMigration.ps1 -Project PRJ-001,PRJ-002 `
        -Title "Add 'priority' column to feature-tracking.md" `
        -Source "PF-IMP-931" -SourceLink "../../state-tracking/permanent/process-improvement-tracking.md" `
        -TargetFiles "`doc/state-tracking/permanent/feature-tracking.md` — add 'priority' column" `
        -BackwardCompatible yes

.EXAMPLE
    # Fan out a no-data-motion cleanup to all eligible projects:
    New-PendingMigration.ps1 -AllProjects -Variant Cleanup `
        -Title "Remove empty `test/legacy/` placeholder dir" `
        -Source "PF-STA-009" -TargetFiles "`test/legacy/` — remove empty dir" `
        -BackwardCompatible no

.EXAMPLE
    New-PendingMigration.ps1 -BatchFile migrations.json
    # migrations.json:
    # [
    #   { "Title": "...", "Source": "PF-IMP-931", "TargetFiles": ["`doc/x.md` — ..."],
    #     "BackwardCompatible": "yes", "AllProjects": true }
    # ]

.NOTES
    - Scaffolds structure only; author fills the TODO prose.
    - MIG-NNN counters are per-project and independent.
    - Errors (skips, in batch/multi-project) are reported, not silently swallowed.
    - Soak-verified (PF-PRO-028): newly created/hash-changed; accrues soak over real invocations.
#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "Direct")]
param(
    [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
    [ValidatePattern('^PRJ-[A-Z]*\d+$')]
    [string[]]$Project,

    [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
    [switch]$AllProjects,

    [Parameter(Mandatory = $true, ParameterSetName = "Direct")]
    [ValidateLength(5, 200)]
    [string]$Title,

    [Parameter(Mandatory = $true, ParameterSetName = "Direct")]
    [ValidateLength(2, 200)]
    [string]$Source,

    [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
    [string]$SourceLink = "",

    [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
    [string]$SourceFrameworkVersion = "",

    [Parameter(Mandatory = $true, ParameterSetName = "Direct")]
    [ValidateCount(1, 50)]
    [string[]]$TargetFiles,

    [Parameter(Mandatory = $true, ParameterSetName = "Direct")]
    [ValidateSet("yes", "no")]
    [string]$BackwardCompatible,

    [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
    [ValidateSet("Full", "Cleanup")]
    [string]$Variant = "Full",

    [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
    [string]$Description = "",

    [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
    [string]$Notes = "",

    [Parameter(Mandatory = $true, ParameterSetName = "Batch")]
    [ValidateScript({ Test-Path $_ })]
    [string]$BatchFile
)

# --- Import common helpers (walk up to Common-ScriptHelpers.psm1) ---
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
Invoke-StandardScriptInitialization

# MSYS path-mangling guard for user-provided -SourceLink (PF-IMP-767). No-ops on empty input.
if ($PSCmdlet.ParameterSetName -eq "Direct" -and (Test-MSYSPathMangled -Path $SourceLink -ParameterName 'SourceLink')) {
    exit 1
}

# Soak verification (PF-PRO-028; normalized ScriptId per PF-PRO-032)
$soakScriptId = "scripts/file-creation/support/New-PendingMigration.ps1"
$soakInSoak   = Test-ScriptInSoak -ScriptId $soakScriptId -ScriptPath $PSCommandPath

$CentralRoot = Get-CentralFrameworkPath
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Resolve-EligibleProjects {
    # Eligible = registered projects that aren't appdev (PRJ-000), aren't PRJ-T* sandboxes,
    # and aren't version-frozen. Logs both included and skipped sets (no silent caps).
    $registryPath = Join-Path -Path $CentralRoot -ChildPath "project-registry.json"
    if (-not (Test-Path $registryPath)) {
        Write-ProjectError -Message "project-registry.json not found at $registryPath" -ExitCode 1
    }
    $registry = Get-Content -Path $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $eligible = @()
    $skipped = @()
    foreach ($prop in $registry.projects.PSObject.Properties) {
        $id = $prop.Name
        $entry = $prop.Value
        if ($id -eq 'PRJ-000') { $skipped += "$id (appdev)"; continue }
        if ($id -match '^PRJ-T') { $skipped += "$id (sandbox)"; continue }
        if ($entry.version_freeze -eq $true) { $skipped += "$id (frozen)"; continue }
        $eligible += $id
    }
    Write-Host "Eligible projects ($($eligible.Count)): $($eligible -join ', ')" -ForegroundColor Cyan
    if ($skipped.Count -gt 0) {
        Write-Host "Skipped ($($skipped.Count)): $($skipped -join ', ')" -ForegroundColor DarkGray
    }
    return $eligible
}

function Get-NextMigId {
    param([string]$LedgerPath)
    $content = Get-Content -Path $LedgerPath -Raw -Encoding UTF8
    # Match entry headings (### MIG-NNN:) and summary rows (| MIG-NNN ) only — not prose references.
    $nums = [regex]::Matches($content, '(?m)^(?:###\s+MIG-|\|\s*MIG-)(\d+)') |
        ForEach-Object { [int]$_.Groups[1].Value }
    # Measure-Object .Maximum returns a Double; cast to int so the 'D3' format specifier is valid.
    $max = if ($nums) { [int]($nums | Measure-Object -Maximum).Maximum } else { 0 }
    return ('MIG-{0:D3}' -f ($max + 1))
}

function New-SummaryRow {
    param([string]$MigId, [string]$Title, [string]$Sfv, [string]$BackwardCompatible)
    $t = $Title -replace '(?<!\\)\|', '\|'
    $s = $Sfv -replace '(?<!\\)\|', '\|'
    return "| $MigId | $t | Open | $s | $($BackwardCompatible.ToLower()) | — |"
}

function New-EntrySection {
    # Returns the entry section as a string[] of lines (ending with one blank line).
    param(
        [string]$Variant, [string]$MigId, [string]$Title, [string]$Source, [string]$SourceLink,
        [string]$Sfv, [string]$Created, [string[]]$TargetFiles, [string]$BackwardCompatible,
        [string]$Description, [string]$Notes
    )
    $sourceCell = if ($SourceLink -and $SourceLink.Trim() -ne '') { "[$Source]($SourceLink)" } else { $Source }
    $bc = $BackwardCompatible.ToLower()
    $isCleanup = ($Variant -eq 'Cleanup')

    $L = [System.Collections.Generic.List[string]]::new()
    $L.Add("### ${MigId}: $Title")
    $L.Add('')
    $L.Add('| Field | Value |')
    $L.Add('|---|---|')
    $L.Add('| **Status** | Open |')
    $L.Add("| **Source** | $sourceCell |")
    $L.Add("| **Source Framework Version** | $Sfv |")
    $L.Add("| **Created** | $Created |")
    $L.Add('')
    $L.Add('#### Target Files')
    $L.Add('')
    foreach ($tf in $TargetFiles) { $L.Add("- $tf") }
    $L.Add('')
    $L.Add('#### Description')
    $L.Add('')
    if ($Description -and $Description.Trim() -ne '') {
        $L.Add($Description)
    } elseif ($isCleanup) {
        $L.Add('<!-- TODO: 1-2 sentences — which empty-dir / placeholder / key is cleaned up, and the appdev structural change that motivates it. State explicitly that there is no data motion. -->')
    } else {
        $L.Add('<!-- TODO: 2-5 sentences explaining what the migration does, framed for the operator who applies it; reference the appdev structural change that motivates it. -->')
    }
    $L.Add('')
    $L.Add('#### Migration Steps')
    $L.Add('')
    if ($isCleanup) {
        $L.Add('1. **Pre-check** the target is empty / placeholder-only (e.g., `Get-ChildItem <path> -Force` returns nothing or `.gitkeep` only). If real content is found, **stop and reconcile** — switch to the full PF-TEM-079 form.')
        $L.Add('2. <!-- TODO: the `Remove-Item` / `New-Item` (or single config/registry edit) step. -->')
    } else {
        $L.Add('1. <!-- TODO: concrete edit step (path + exact change). -->')
        $L.Add('2. <!-- TODO: step 2 -->')
    }
    $L.Add('')
    if ($isCleanup) {
        $L.Add('#### Expected Outcome (doubles as validation)')
        $L.Add('')
        $L.Add('<!-- TODO: verifiable post-condition — e.g., "`Test-Path <old>` returns `False`; `<new>` exists with `.gitkeep`." -->')
        $L.Add('')
    } else {
        $L.Add('#### Expected Outcome')
        $L.Add('')
        $L.Add('<!-- TODO: verifiable post-condition the operator can confirm. -->')
        $L.Add('')
    }
    $L.Add('#### Rollback Implications')
    $L.Add('')
    $L.Add('**Backward-compatible**: `' + $bc + '`')
    $L.Add('')
    if ($isCleanup) {
        if ($bc -eq 'yes') {
            $L.Add('<!-- TODO: one line — why the prior framework version still parses the project cleanly. -->')
        } else {
            $L.Add('<!-- TODO: one line — the single trivial reversal step (e.g., recreate `<old-path>` as an empty placeholder before Mode D rollback). -->')
        }
        $L.Add('')
    } else {
        if ($bc -eq 'yes') {
            $L.Add('<!-- TODO: one sentence — why the prior framework version still parses post-migration working docs cleanly (e.g., only optional fields/sections/rows added). -->')
            $L.Add('')
        } else {
            $L.Add('<!-- TODO: one sentence — what breaks under the prior framework version (renamed column, required field, restructured section). -->')
            $L.Add('')
            $L.Add('**Required reversal steps before Mode D rollback**:')
            $L.Add('')
            $L.Add('1. <!-- TODO: reversal step -->')
            $L.Add('2. <!-- TODO: verification step -->')
            $L.Add('')
        }
        $L.Add('#### Validation')
        $L.Add('')
        $L.Add('<!-- TODO: how to verify this entry is fully and correctly applied. -->')
        $L.Add('')
        if ($Notes -and $Notes.Trim() -ne '') {
            $L.Add('#### Notes')
            $L.Add('')
            $L.Add($Notes)
            $L.Add('')
        }
    }
    return $L.ToArray()
}

function Add-MigrationEntry {
    # Core: resolve one project's ledger, allocate MIG-NNN, insert Summary row + entry section,
    # write. Returns a result hashtable, or $null if the ledger is missing / unparseable.
    param(
        [string]$ProjectId, [string]$Title, [string]$Source, [string]$SourceLink,
        [string]$Sfv, [string[]]$TargetFiles, [string]$BackwardCompatible, [string]$Variant,
        [string]$Description, [string]$Notes
    )

    $ledgerPath = Join-Path -Path $CentralRoot -ChildPath "per-project-migrations/$ProjectId/pending-migrations.md"
    if (-not (Test-Path $ledgerPath)) {
        Write-Warning "Ledger not found for ${ProjectId}: $ledgerPath — skipping. Register the project (Register-Project.ps1) or create its pending-migrations.md first."
        return $null
    }

    $migId = Get-NextMigId -LedgerPath $ledgerPath
    $summaryRow = New-SummaryRow -MigId $migId -Title $Title -Sfv $Sfv -BackwardCompatible $BackwardCompatible
    $sectionLines = New-EntrySection -Variant $Variant -MigId $migId -Title $Title -Source $Source `
        -SourceLink $SourceLink -Sfv $Sfv -Created $CurrentDate -TargetFiles $TargetFiles `
        -BackwardCompatible $BackwardCompatible -Description $Description -Notes $Notes

    $content = Get-Content -Path $ledgerPath -Raw -Encoding UTF8
    $lines = [System.Collections.ArrayList]@($content -split "\r?\n")

    # --- Summary table insertion: after the last MIG-NNN data row, else after the separator ---
    $inSummary = $false; $summaryRowIdx = -1; $summarySepIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s+Summary\b') { $inSummary = $true; continue }
        if ($inSummary) {
            if ($lines[$i] -match '^\|\s*-') { $summarySepIdx = $i }
            if ($lines[$i] -match '^\|\s*MIG-\d+') { $summaryRowIdx = $i }
            if ($lines[$i] -match '^##\s') { break }
        }
    }
    $summaryInsertIdx = if ($summaryRowIdx -ne -1) { $summaryRowIdx } else { $summarySepIdx }
    if ($summaryInsertIdx -eq -1) {
        Write-ProjectError -Message "Could not locate the Summary table in $ledgerPath (expected '## Summary' + a table)."
        return $null
    }

    # --- Pending-entries insertion: end of '## Pending entries' (before next '## ' or EOF) ---
    $pendingIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s+Pending entries\b') { $pendingIdx = $i; break }
    }
    if ($pendingIdx -eq -1) {
        Write-ProjectError -Message "Could not locate the '## Pending entries' section in $ledgerPath."
        return $null
    }
    $entryInsertIdx = $lines.Count
    for ($i = $pendingIdx + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s') { $entryInsertIdx = $i; break }
    }

    # Build the block; prepend a blank separator only if the preceding line isn't already blank.
    $block = [System.Collections.Generic.List[string]]::new()
    if ($entryInsertIdx -gt 0 -and $lines[$entryInsertIdx - 1].Trim() -ne '') { $block.Add('') }
    foreach ($l in $sectionLines) { $block.Add($l) }

    # Insert the entry block FIRST (higher index), then the summary row (lower index) — so the
    # entry-block index isn't shifted by the summary insertion.
    $lines.InsertRange($entryInsertIdx, $block)
    $lines.Insert($summaryInsertIdx + 1, $summaryRow)

    $updatedContent = ($lines -join "`r`n")
    $updatedContent = $updatedContent -replace '(?m)(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate

    # Retry-on-IOException absorbs LinkWatcher contention (PF-IMP-718)
    Invoke-FileWriteWithRetry -Context (Split-Path $ledgerPath -Leaf) -ScriptBlock {
        Set-Content -Path $ledgerPath -Value $updatedContent -NoNewline -Encoding UTF8
    }

    if (-not $WhatIfPreference) {
        # Non-anchored match (Assert-LineInFile is not multiline-^ aware) — verify the Summary row landed.
        $rowPattern = "\|\s*" + [regex]::Escape($migId) + "\s*\|"
        Assert-LineInFile -Path $ledgerPath -Pattern $rowPattern -Context "summary row for $migId in $ProjectId ledger"
    }

    Write-Host "  $ProjectId -> $migId ($Variant)" -ForegroundColor Green
    return @{ Project = $ProjectId; MigId = $migId; Ledger = $ledgerPath; Variant = $Variant }
}

function Invoke-MigrationFanOut {
    # Resolve targets, ShouldProcess-gate the whole fan-out, then write one entry per project.
    param(
        [string[]]$Targets, [string]$Title, [string]$Source, [string]$SourceLink, [string]$Sfv,
        [string[]]$TargetFiles, [string]$BackwardCompatible, [string]$Variant,
        [string]$Description, [string]$Notes
    )
    if (-not $PSCmdlet.ShouldProcess(($Targets -join ', '), "Add migration entry '$Title' ($Variant)")) {
        return @()
    }
    $results = @()
    foreach ($p in $Targets) {
        $r = Add-MigrationEntry -ProjectId $p -Title $Title -Source $Source -SourceLink $SourceLink `
            -Sfv $Sfv -TargetFiles $TargetFiles -BackwardCompatible $BackwardCompatible `
            -Variant $Variant -Description $Description -Notes $Notes
        if ($r) { $results += $r }
    }
    return $results
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

try {
    if ($PSCmdlet.ParameterSetName -eq "Batch") {
        $rawJson = Get-Content -Path $BatchFile -Raw -Encoding UTF8
        if (-not ($rawJson.TrimStart().StartsWith('['))) {
            Write-ProjectError -Message "Batch file must contain a JSON array of migration objects." -ExitCode 1
        }
        # @() normalizes the single-element case: ConvertFrom-Json enumerates a 1-element array
        # to a scalar, which would otherwise look like a non-array.
        $items = @($rawJson | ConvertFrom-Json)

        # Validate ALL items before any write.
        for ($idx = 0; $idx -lt $items.Count; $idx++) {
            $it = $items[$idx]
            $errs = @()
            if (-not $it.Title) { $errs += "missing Title" }
            elseif ($it.Title.Length -lt 5 -or $it.Title.Length -gt 200) { $errs += "Title length must be 5-200 ($($it.Title.Length))" }
            if (-not $it.Source) { $errs += "missing Source" }
            if (-not $it.TargetFiles -or @($it.TargetFiles).Count -lt 1) { $errs += "missing TargetFiles (non-empty array required)" }
            if ($it.BackwardCompatible -notin @('yes', 'no')) { $errs += "BackwardCompatible must be 'yes' or 'no'" }
            if ($it.Variant -and $it.Variant -notin @('Full', 'Cleanup')) { $errs += "Variant must be 'Full' or 'Cleanup'" }
            if (-not $it.AllProjects -and (-not $it.Projects -or @($it.Projects).Count -lt 1)) {
                $errs += "specify either Projects (non-empty array) or AllProjects:true"
            }
            if ($errs.Count -gt 0) {
                Write-ProjectError -Message "Batch item [$idx]: $($errs -join '; ')" -ExitCode 1
            }
        }

        Write-Host "Batch mode: $($items.Count) migration(s) from $BatchFile" -ForegroundColor Magenta
        $allResults = @()
        foreach ($it in $items) {
            $targets = if ($it.AllProjects) { Resolve-EligibleProjects } else { [string[]]$it.Projects }
            $variant = if ($it.Variant) { $it.Variant } else { "Full" }
            $sfv = if ($it.SourceFrameworkVersion) { $it.SourceFrameworkVersion } else { "$CurrentDate-NNN (assigned at next Push)" }
            Write-Host "Migration '$($it.Title)' -> $($targets -join ', ')" -ForegroundColor Magenta
            $allResults += Invoke-MigrationFanOut -Targets $targets -Title $it.Title -Source $it.Source `
                -SourceLink $(if ($it.SourceLink) { $it.SourceLink } else { "" }) -Sfv $sfv `
                -TargetFiles ([string[]]$it.TargetFiles) -BackwardCompatible $it.BackwardCompatible `
                -Variant $variant -Description $(if ($it.Description) { $it.Description } else { "" }) `
                -Notes $(if ($it.Notes) { $it.Notes } else { "" })
        }

        if ($allResults.Count -gt 0) {
            Write-ProjectSuccess -Message "Batch complete: $($allResults.Count) entries created" `
                -Details ($allResults | ForEach-Object { "$($_.Project) $($_.MigId) ($($_.Variant))" })
            if ($soakInSoak) { Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success }
        } else {
            Write-Warning "Batch produced no entries (all targets skipped or -WhatIf)."
        }
    }
    else {
        # Direct mode — validate target selection (exactly one of -Project / -AllProjects)
        if ($AllProjects -and $Project) {
            Write-ProjectError -Message "Specify either -Project or -AllProjects, not both." -ExitCode 1
        }
        if (-not $AllProjects -and -not $Project) {
            Write-ProjectError -Message "Specify -Project <PRJ-NNN[,...]> or -AllProjects." -ExitCode 1
        }
        $targets = if ($AllProjects) { Resolve-EligibleProjects } else { $Project }
        $sfv = if ($SourceFrameworkVersion) { $SourceFrameworkVersion } else { "$CurrentDate-NNN (assigned at next Push)" }

        if (@($targets).Count -eq 0) {
            Write-Warning "No eligible target projects resolved; nothing to do."
            return
        }

        $results = Invoke-MigrationFanOut -Targets $targets -Title $Title -Source $Source `
            -SourceLink $SourceLink -Sfv $sfv -TargetFiles $TargetFiles `
            -BackwardCompatible $BackwardCompatible -Variant $Variant -Description $Description -Notes $Notes

        if ($results.Count -gt 0) {
            Write-ProjectSuccess -Message "Created $($results.Count) migration entry/entries" `
                -Details ($results | ForEach-Object { "$($_.Project) $($_.MigId) ($($_.Variant))" })
            Write-Verbose "Next Steps: fill the <!-- TODO --> prose in each entry (Description, Migration Steps, Rollback Implications, Validation)."
            Write-Verbose "Next Steps: entries are applied per project by Framework Rollout Mode C (PF-TSK-088)."
            if ($soakInSoak) { Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success }
        } else {
            Write-Warning "No entries created (all targets skipped or -WhatIf)."
        }
    }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome failure -Notes $soakErrMsg
    }
    Write-ProjectError -Message "Failed to create migration entry: $($_.Exception.Message)" -ExitCode 1
}
