# New-PendingMigration.ps1
# Scaffolds a Pending Migration Entry in one or more projects' per-project ledgers
# (<producer>/process-framework-central/<ledger dir>/<PROJECT-ID>/pending-migrations.md; the ledger
# dir name is role-derived via Get-ChildRegistryInfo).
# Allocates the per-project MIG-NNN counter, inserts the Summary-table row AND the per-entry
# section skeleton (PF-TEM-079 full / PF-TEM-080 cleanup) in one write.

<#
.SYNOPSIS
    Scaffolds Pending Migration Entries (Summary row + entry skeleton) across one or more project ledgers, allocating each per-project MIG-NNN automatically.

.DESCRIPTION
    Written for the Structure Change task (PF-TSK-014)'s pending-migration-entry step, where one structural change in
    appdev/blueprint/ that affects project working docs must be recorded as a migration entry in
    EVERY affected registered project's ledger — previously a manual, error-prone copy-paste
    (PF-IMP-931). For each target project this script:

    - Resolves the ledger at <central>/<ledger dir>/<PROJECT-ID>/pending-migrations.md
      (central root via Get-CentralFrameworkPath, so it works from cwd=appdev or cwd=project).
    - Allocates the next per-project MIG-NNN (highest existing in that ledger + 1; per-project
      counters are independent).
    - Inserts a Summary-table row and a per-entry section skeleton in a single write.
    - Picks the Full (PF-TEM-079) or Cleanup (PF-TEM-080) entry shape via -Variant.

    In Direct mode the script scaffolds STRUCTURE only — the substantive prose (Description,
    Migration Steps, Rollback-Implications reasoning, Validation) is left as `<!-- TODO -->`
    placeholders for the author to fill. The win there is correct MIG-NNN sequencing, a consistent
    skeleton, and one-call fan-out across projects.

    Batch mode additionally accepts the prose up-front, so a fully-specified migration files in one
    shot instead of needing a per-entry editing pass in every project ledger (PF-IMP-1417). Each
    supplied field replaces its section's TODO placeholder; omitted fields keep the placeholder.
    The prose fields live in batch mode only: MigrationSteps and ReversalSteps are arrays, and
    `pwsh -File` cannot parse array parameters (the same footgun -TargetFiles warns about), while
    JSON carries multi-line markdown prose cleanly.

    Project targeting (Direct mode): pass -Project <PROJECT-ID> (one or comma-separated many), or
    -AllProjects to fan out to every eligible registered project (excludes the producer
    workspace itself, sandbox rows per the derived key pattern, and version-frozen projects;
    the skipped set is logged).

    Batch mode (-BatchFile): a JSON array of migration objects, each with its own fields and a
    "Projects" array or "AllProjects": true. All items are validated before any write.

.PARAMETER Project
    One or more target project IDs (e.g., PRJ-001 or PRJ-001,PRJ-002). Mutually exclusive with
    -AllProjects. Direct mode.

.PARAMETER AllProjects
    Fan out to every eligible registered project (from the level's child registry), excluding the
    producer workspace itself (own-config id), sandbox rows (derived key pattern), and
    version-frozen projects.
    Mutually exclusive with -Project.

.PARAMETER Title
    Verb-first one-line entry title (5-200 chars), e.g. "Add 'priority' column to feature-tracking.md".

.PARAMETER Source
    Display text for the Source field, e.g. "PF-IMP-931" or "PF-STA-005 (Phase 3d Session 9)".

.PARAMETER SourceLink
    Optional relative path for the Source link. When provided, the Source cell renders as
    [Source](SourceLink).

.PARAMETER SourceFrameworkVersion
    The appdev framework version this migration was authored against (the "source" version, distinct
    from any later version that revises it). Defaults to the current framework version read from
    <framework-root>/.framework-version, so the field is populated at creation with no manual edit.
    Pass explicitly only to override (e.g. back-dating, or authoring against a non-current version).

.PARAMETER TargetFiles
    One or more project-relative target descriptions, each rendered as a Target Files bullet.
    Provide each as "`path` — one-line summary of what changes there".
    Multiple values require -Command or -BatchFile: `pwsh -File` does not parse arrays, so
    -TargetFiles 'a','b' collapses to a single "a,b" element (the script warns when it detects this).

    Also the input to the overlap advisory: for each target project the script warns when an Open
    entry in that ledger already lists one of these paths, so an entry whose change is already
    carried elsewhere is caught at filing time instead of by hand-reading the ledger.

.PARAMETER BackwardCompatible
    yes | no — the load-bearing Rollback-Implications value consumed by Framework Rollout Mode D.
    Drives which Rollback-Implications scaffold is emitted.

.PARAMETER Variant
    Full (PF-TEM-079, default) or Cleanup (PF-TEM-080, for no-data-motion empty-dir/placeholder/
    single-config/text-substitution/additive-section-append cleanups). The Cleanup skeleton's
    canonical pre-check ASSERTS the target holds nothing needing migration (empty/.gitkeep-only
    dir, obsolete key only, old string present / target heading absent) and stops if real content
    is found — a target holding real content, including an already-copied drain, takes the Full
    form (verify completeness, then delete).

.PARAMETER Description
    Optional Description prose. When omitted, a TODO placeholder is inserted.

.PARAMETER Notes
    Optional free-form notes (Full variant only; adds a #### Notes section when provided).

.PARAMETER BatchFile
    Path to a JSON array of migration objects. Each object: Title, Source, [SourceLink],
    [SourceFrameworkVersion], TargetFiles (array), BackwardCompatible, [Variant], [Description],
    [Notes], and either "Projects": ["PRJ-001", ...] or "AllProjects": true.

    Optional prose fields (each replaces its section's TODO placeholder; omit to keep the TODO):
    - MigrationSteps        (array)  — numbered steps. Cleanup entries keep their canonical
                                       pre-check as step 1; supplied steps are numbered from 2.
    - ExpectedOutcome       (string) — the verifiable post-condition.
    - RollbackImplications  (string) — the reasoning under the **Backward-compatible** line.
    - ReversalSteps         (array)  — Full variant with BackwardCompatible "no" only.
    - Validation            (string) — Full variant only (Cleanup folds validation into
                                       Expected Outcome).
    A field with no section in the chosen shape is reported as a warning, never silently dropped.

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
    # migrations.json — fully specified, no post-creation editing pass:
    # [
    #   { "Title": "...", "Source": "PF-IMP-931", "TargetFiles": ["`doc/x.md` — ..."],
    #     "BackwardCompatible": "yes", "AllProjects": true,
    #     "Description": "What this migration does, for the operator who applies it.",
    #     "MigrationSteps": ["Open `doc/x.md` and ...", "Save and verify ..."],
    #     "ExpectedOutcome": "`Select-String 'foo' doc/x.md` returns the new row.",
    #     "RollbackImplications": "Only an optional column is added, so the prior version still parses.",
    #     "Validation": "Run Validate-StateTracking.ps1 — no new findings." }
    # ]

.NOTES
    - Direct mode scaffolds structure only; author fills the TODO prose. Batch mode accepts the
      prose up-front (MigrationSteps / ExpectedOutcome / RollbackImplications / ReversalSteps /
      Validation) so an entry files complete in one shot.
    - MIG-NNN counters are per-project and independent.
    - Overlap advisory (PF-IMP-1711): a warning — never a block — when an Open entry in the target
      ledger already lists one of the -TargetFiles paths. The same target file is not the same
      change, so the entry is still created; the operator confirms and, if redundant, resolves it.
    - Filing-time TODO report (PF-IMP-1943, absorbing PF-IMP-1801): every created entry that still
      carries `<!-- TODO -->` placeholders is named in a warning with its unfilled sections, so an
      omitted prose field is visible at filing time rather than at Framework Rollout Mode C apply
      time — an unfilled Expected Outcome removes the entry's only objective completion criterion.
    - Errors (skips, in batch/multi-project) are reported, not silently swallowed.
    - Soak-verified (PF-PRO-028): newly created/hash-changed; accrues soak over real invocations.
#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "Direct")]
param(
    [Parameter(Mandatory = $false, ParameterSetName = "Direct")]
    [ValidatePattern('^([A-Z]{2,4}-[A-Z]*\d+|FWK-[A-Z]{2,4})$')]  # mnemonic-generic since P-14 (APP-NNN live, PRJ-NNN history/synthetic)
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

function Get-AuthoringFrameworkVersion {
    # The appdev framework version this migration is authored against — the "source" version stamped
    # into each entry's Source Framework Version field. Read from <framework-root>/.framework-version;
    # the script lives at <framework-root>/scripts/file-creation/support/, so the framework root is
    # three levels up. Falls back to a marked 'unknown' rather than failing entry creation if the
    # stamp file is absent.
    $frameworkRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    $versionFile = Join-Path -Path $frameworkRoot -ChildPath ".framework-version"
    if (Test-Path $versionFile) {
        $v = (Get-Content -Path $versionFile -Raw -Encoding UTF8).Trim()
        if ($v) { return $v }
    }
    return "unknown (.framework-version unreadable)"
}

function Resolve-EligibleProjects {
    # Eligible = registered projects that aren't this workspace itself (self-row — the author
    # cannot be its own migration target), aren't sandbox rows (derived key pattern), aren't version-frozen, and
    # aren't framework-role children (PF-PRO-067 role guard: a framework child registered before
    # the Sub-concept 3 generalization must never be treated as a project migration target).
    # Logs both included and skipped sets (no silent caps). The self check is an IDENTITY
    # comparison read from own config — not a role inference, and never an inline ID literal.
    # P-10: registry file name, collection key, accepted child roles, sandbox key pattern and
    # ledger dir name all derive from this workspace's declared role (Get-ChildRegistryInfo) —
    # 'project-registry.json'/'projects' at a framework face, 'framework-registry.json'/'frameworks'
    # at a framework-builder face. One resolver call serves the whole fan-out.
    $reg = Get-ChildRegistryInfo
    $registryPath = Join-Path -Path $CentralRoot -ChildPath $reg.FileName
    if (-not (Test-Path $registryPath)) {
        Write-ProjectError -Message "$($reg.FileName) not found at $registryPath" -ExitCode 1
    }
    $registry = Get-Content -Path $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $selfId = $null
    try { $selfId = (Get-ProjectConfig).project_id } catch { }
    if (-not $selfId) {
        # Self-exclusion is safety-critical: without a resolvable own id, the author's own row
        # would silently become a fan-out target. Fail loudly instead of guessing.
        Write-ProjectError -Message "Resolve-EligibleProjects: could not read this workspace's own project_id from doc/project-config.json — cannot safely exclude the self-row from the fan-out. Repair the config and re-run." -ExitCode 1
    }
    # P-8/P-14: sandbox exclusion uses the level's derived key pattern ('^APP-T' at FWK-APP;
    # the legacy '^PRJ-T' rung at a non-FWK-shaped face) — the same source Push/Restore/CSB read.
    $sandboxKeyPattern = $reg.SandboxKeyPattern
    $eligible = @()
    $skipped = @()
    foreach ($prop in $registry.$($reg.CollectionKey).PSObject.Properties) {
        $id = $prop.Name
        $entry = $prop.Value
        if ($selfId -and $id -eq $selfId) { $skipped += "$id (self)"; continue }
        if ($id -match $sandboxKeyPattern) { $skipped += "$id (sandbox)"; continue }
        if ($entry.role -and $entry.role -notin $reg.AcceptedChildRoles) { $skipped += "$id (role: $($entry.role))"; continue }
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

function ConvertTo-TargetFilePathToken {
    # Reduces a Target Files bullet — or a -TargetFiles value — to its comparable path token:
    # the text before the first dash separator, minus the list marker and backticks, with
    # separators and case normalized. "- `doc/x.md` — add a column" and "doc\X.MD" both yield
    # "doc/x.md". Only a dash with surrounding whitespace separates path from summary, so a
    # hyphen inside a filename (pre-commit-config.yaml) survives.
    param([string]$Text)
    $t = $Text -replace '^\s*[-*]\s+', ''
    $t = ($t -split '\s+(?:—|–|-)\s+', 2)[0]
    $t = $t -replace '`', ''
    return $t.Trim().TrimEnd(',', '.', ';').Replace('\', '/').ToLowerInvariant()
}

function Find-OverlappingOpenEntries {
    # Warn-first overlap advisory (PF-IMP-1711). An Open entry in this ledger may already carry
    # the change being filed — most often one whose Migration Steps copy the target file's wording
    # from blueprint at drain time, which picks up later blueprint edits automatically. The filer
    # otherwise has no trigger to check, and hand-reading a deep ledger is the only alternative.
    # Advisory only: the same target file is NOT the same change, so the caller warns and proceeds.
    # Returns one "MIG-NNN (path, path)" string per overlapping Open entry.
    param([string]$Content, [string[]]$TargetFiles)

    $wanted = @($TargetFiles | ForEach-Object { ConvertTo-TargetFilePathToken $_ } | Where-Object { $_ })
    if ($wanted.Count -eq 0) { return @() }

    $hits = [System.Collections.Generic.List[string]]::new()
    $curId = ''; $curOpen = $false; $inTargets = $false
    $matched = [System.Collections.Generic.List[string]]::new()

    # Local so the flush at each entry boundary and at EOF stay identical.
    $flush = {
        if ($curId -and $curOpen -and $matched.Count -gt 0) {
            $hits.Add("$curId ($($matched -join ', '))")
        }
    }

    foreach ($line in ($Content -split "\r?\n")) {
        # '###\s' cannot match a '####' heading — the 4th character must be whitespace.
        if ($line -match '^###\s+(MIG-\d+)\s*:') {
            & $flush
            $curId = $Matches[1]; $curOpen = $false; $inTargets = $false; $matched.Clear()
            continue
        }
        if (-not $curId) { continue }
        # Resolved/skipped detail blocks relocate to the per-project archive (PF-IMP-983), so a
        # section still in the ledger is normally Open — read the Status field anyway, so a stale
        # un-relocated block can't produce a false advisory.
        if ($line -match '^\|\s*\*\*Status\*\*\s*\|\s*Open\s*\|') { $curOpen = $true; continue }
        if ($line -match '^####\s') { $inTargets = ($line -match '^####\s+Target Files\b'); continue }
        if ($inTargets -and $line -match '^\s*[-*]\s+\S') {
            $tok = ConvertTo-TargetFilePathToken $line
            if ($tok -and ($wanted -contains $tok) -and (-not $matched.Contains($tok))) { $matched.Add($tok) }
        }
    }
    & $flush

    # Emit the hits enumerated — the caller wraps in @() to normalize the 0/1/many cases. A unary
    # comma here would survive that @(), yielding Count 1 (the inner array) even with zero hits.
    return $hits.ToArray()
}

function New-SummaryRow {
    param([string]$Content, [string]$MigId, [string]$Title, [string]$Sfv, [string]$BackwardCompatible)
    $t = $Title -replace '(?<!\\)\|', '\|'
    $s = $Sfv -replace '(?<!\\)\|', '\|'
    # Header-driven (PF-IMP-1599): cells are ordered by the ledger Summary table's own header, so
    # a schema change lands as "—" in the correct position instead of silently shifting cells.
    # Returns $null when the ledger has no Summary heading — the caller's insertion scan reports
    # that with its own error.
    $summaryHeading = ($Content -split "\r?\n") | Where-Object { $_ -match '^##\s+Summary\b' } | Select-Object -First 1
    if (-not $summaryHeading) { return $null }
    return New-HeaderDrivenTableRow -Content $Content -SectionHeading $summaryHeading -ValueMap @{
        'ID'                  = $MigId
        'Title'               = $t
        'Status'              = 'Open'
        'Source FW Version'   = $s
        'Backward-compatible' = $BackwardCompatible.ToLower()
    }
}

function New-EntrySection {
    # Returns the entry section as a string[] of lines (ending with one blank line).
    # Every prose field is optional: supplied text replaces the section's TODO placeholder,
    # so a fully-specified batch item files in one shot (PF-IMP-1417). Cleanup entries keep
    # their canonical pre-check as step 1 — supplied MigrationSteps are numbered from 2.
    param(
        [string]$Variant, [string]$MigId, [string]$Title, [string]$Source, [string]$SourceLink,
        [string]$Sfv, [string]$Created, [string[]]$TargetFiles, [string]$BackwardCompatible,
        [string]$Description, [string]$Notes,
        [string[]]$MigrationSteps, [string]$ExpectedOutcome, [string]$RollbackImplications,
        [string[]]$ReversalSteps, [string]$Validation
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
        $L.Add('<!-- TODO: 1-2 sentences — which empty-dir / placeholder / key is removed, which in-place text is substituted (link/path repoint, single-line fix), or which section is appended (name its canonical blueprint source), and the appdev structural change that motivates it. State explicitly that there is no data motion. -->')
    } else {
        $L.Add('<!-- TODO: 2-5 sentences explaining what the migration does, framed for the operator who applies it; reference the appdev structural change that motivates it. -->')
    }
    $L.Add('')
    $hasSteps = (@($MigrationSteps).Where({ $_ -and $_.Trim() -ne '' }).Count -gt 0)

    $L.Add('#### Migration Steps')
    $L.Add('')
    if ($isCleanup) {
        # The pre-check is the Cleanup variant's safety contract — it stays step 1 either way.
        $L.Add('1. **Pre-check** the target holds nothing that needs migrating — an empty/placeholder directory (e.g., `Get-ChildItem <path> -Force` returns nothing or `.gitkeep` only), a config/registry key whose only value is the obsolete one being removed, for an in-place text substitution that the exact old string is still present (e.g., `Select-String ''<old>'' <file>`) so the replace no-ops if already applied, or — for an additive append — that the target heading/string is **absent** (e.g., `Select-String ''<new-heading>'' <file>` returns nothing) so the append no-ops if already applied. If real content needing migration is found, **stop and reconcile** — switch to the full PF-TEM-079 form.')
        if ($hasSteps) {
            $n = 2
            foreach ($s in $MigrationSteps) { $L.Add("$n. $s"); $n++ }
        } else {
            $L.Add('2. <!-- TODO: the `Remove-Item` / `New-Item`, single config/registry edit, string-replace (e.g. `(Get-Content <file> -Raw) -replace ''<old>'',''<new>'' | Set-Content <file>`), or insert-the-section step (copy the section verbatim from its canonical blueprint source and insert it after the named anchor heading). -->')
        }
    } elseif ($hasSteps) {
        $n = 1
        foreach ($s in $MigrationSteps) { $L.Add("$n. $s"); $n++ }
    } else {
        $L.Add('1. <!-- TODO: concrete edit step (path + exact change; phrase preconditions/no-op conditions as apply-time checks the operator runs, with specifics re-derived from the live tree). -->')
        $L.Add('2. <!-- TODO: step 2 -->')
    }
    $L.Add('')
    if ($isCleanup) {
        $L.Add('#### Expected Outcome (doubles as validation)')
        $L.Add('')
        if ($ExpectedOutcome -and $ExpectedOutcome.Trim() -ne '') {
            $L.Add($ExpectedOutcome)
        } else {
            $L.Add('<!-- TODO: verifiable post-condition — e.g., "`Test-Path <old>` returns `False`; `<new>` exists with `.gitkeep`", "`Select-String ''<old>'' <file>` returns nothing and the new string is present", or — for an additive append — "`Select-String ''<new-heading>'' <file>` returns the appended heading". -->')
        }
        $L.Add('')
    } else {
        $L.Add('#### Expected Outcome')
        $L.Add('')
        if ($ExpectedOutcome -and $ExpectedOutcome.Trim() -ne '') {
            $L.Add($ExpectedOutcome)
        } else {
            $L.Add('<!-- TODO: verifiable post-condition the operator can confirm. -->')
        }
        $L.Add('')
    }
    $hasRollback = ($RollbackImplications -and $RollbackImplications.Trim() -ne '')

    $L.Add('#### Rollback Implications')
    $L.Add('')
    $L.Add('**Backward-compatible**: `' + $bc + '`')
    $L.Add('')
    if ($isCleanup) {
        if ($hasRollback) {
            $L.Add($RollbackImplications)
        } elseif ($bc -eq 'yes') {
            $L.Add('<!-- TODO: one line — why the prior framework version still parses the project cleanly. -->')
        } else {
            $L.Add('<!-- TODO: one line — the single trivial reversal step (e.g., recreate `<old-path>` as an empty placeholder, or re-run the inverse string-replace, before Mode D rollback). -->')
        }
        $L.Add('')
    } else {
        if ($hasRollback) {
            $L.Add($RollbackImplications)
        } elseif ($bc -eq 'yes') {
            $L.Add('<!-- TODO: one sentence — why the prior framework version still parses post-migration working docs cleanly (e.g., only optional fields/sections/rows added). -->')
        } else {
            $L.Add('<!-- TODO: one sentence — what breaks under the prior framework version (renamed column, required field, restructured section). -->')
        }
        $L.Add('')
        if ($bc -ne 'yes') {
            $L.Add('**Required reversal steps before Mode D rollback**:')
            $L.Add('')
            if (@($ReversalSteps).Where({ $_ -and $_.Trim() -ne '' }).Count -gt 0) {
                $n = 1
                foreach ($r in $ReversalSteps) { $L.Add("$n. $r"); $n++ }
            } else {
                $L.Add('1. <!-- TODO: reversal step -->')
                $L.Add('2. <!-- TODO: verification step -->')
            }
            $L.Add('')
        }
        $L.Add('#### Validation')
        $L.Add('')
        if ($Validation -and $Validation.Trim() -ne '') {
            $L.Add($Validation)
        } else {
            $L.Add('<!-- TODO: how to verify this entry is fully and correctly applied. -->')
        }
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

function Get-TodoSectionName {
    # Names of the '####' sections in a just-built entry block that still carry a TODO
    # placeholder — derived from the emitted lines themselves, so any variant/shape change is
    # covered automatically. Returns the section names in entry order; callers wrap in @().
    param([string[]]$SectionLines)
    $names = [System.Collections.Generic.List[string]]::new()
    $cur = ''
    foreach ($line in $SectionLines) {
        if ($line -match '^####\s+(.+?)\s*$') { $cur = $Matches[1]; continue }
        if ($cur -and $line -match '<!--\s*TODO' -and -not $names.Contains($cur)) { $names.Add($cur) }
    }
    return $names.ToArray()
}

function Write-TodoRemainderWarning {
    # Filing-time TODO report (PF-IMP-1943, absorbing PF-IMP-1801): name each created entry's
    # still-unfilled prose sections at the moment of filing. Left silent, the omission surfaces
    # only at Framework Rollout Mode C apply time — in another project's cwd, where the applying
    # session must infer the acceptance criteria the Expected Outcome field was meant to state.
    param($Results)
    foreach ($r in @($Results)) {
        if (@($r.TodoSections).Count -gt 0) {
            Write-Warning ("$($r.Project) $($r.MigId): TODO placeholders remain in " +
                "$($r.TodoSections -join ', ') — fill them before the entry ships; " +
                "Framework Rollout Mode C applies the entry as written.")
        }
    }
}

function Add-MigrationEntry {
    # Core: resolve one project's ledger, allocate MIG-NNN, insert Summary row + entry section,
    # write. Returns a result hashtable, or $null if the ledger is missing / unparseable.
    param(
        [string]$ProjectId, [string]$Title, [string]$Source, [string]$SourceLink,
        [string]$Sfv, [string[]]$TargetFiles, [string]$BackwardCompatible, [string]$Variant,
        [string]$Description, [string]$Notes,
        [string[]]$MigrationSteps, [string]$ExpectedOutcome, [string]$RollbackImplications,
        [string[]]$ReversalSteps, [string]$Validation
    )

    # P-10: ledger dir name is role-derived ('per-project-migrations' at a framework face,
    # 'per-framework-migrations' at FB) — NPM is the second LedgerDirName consumer after Register.
    $ledgerPath = Join-Path -Path $CentralRoot -ChildPath "$((Get-ChildRegistryInfo).LedgerDirName)/$ProjectId/pending-migrations.md"
    if (-not (Test-Path $ledgerPath)) {
        Write-Warning "Ledger not found for ${ProjectId}: $ledgerPath — skipping. Register the project (Register-Project.ps1) or create its pending-migrations.md first."
        return $null
    }

    $migId = Get-NextMigId -LedgerPath $ledgerPath
    $sectionLines = New-EntrySection -Variant $Variant -MigId $migId -Title $Title -Source $Source `
        -SourceLink $SourceLink -Sfv $Sfv -Created $CurrentDate -TargetFiles $TargetFiles `
        -BackwardCompatible $BackwardCompatible -Description $Description -Notes $Notes `
        -MigrationSteps $MigrationSteps -ExpectedOutcome $ExpectedOutcome `
        -RollbackImplications $RollbackImplications -ReversalSteps $ReversalSteps -Validation $Validation

    $content = Get-Content -Path $ledgerPath -Raw -Encoding UTF8

    # Overlap advisory (PF-IMP-1711) — warn, never block; the operator decides.
    $overlaps = @(Find-OverlappingOpenEntries -Content $content -TargetFiles $TargetFiles)
    if ($overlaps.Count -gt 0) {
        Write-Warning ("${ProjectId}: Open entries already target the same file(s) — $($overlaps -join '; '). " +
            "Check whether they already carry this change before filling in this entry: a migration whose steps " +
            "copy the file's wording from blueprint at drain time picks up later blueprint edits automatically. " +
            "If it is already covered, resolve this entry as redundant or fold the change into the existing one.")
    }

    $lines = [System.Collections.ArrayList]@($content -split "\r?\n")
    $summaryRow = New-SummaryRow -Content $content -MigId $migId -Title $Title -Sfv $Sfv -BackwardCompatible $BackwardCompatible

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
    $updatedContent = Update-FrontmatterDate -Content $updatedContent -CurrentDate $CurrentDate

    # Retry-on-IOException absorbs LinkWatcher contention (PF-IMP-718)
    Invoke-FileWriteWithRetry -Context (Split-Path $ledgerPath -Leaf) -ScriptBlock {
        Set-Content -Path $ledgerPath -Value $updatedContent -NoNewline -Encoding UTF8
    }

    if (-not $WhatIfPreference) {
        # Non-anchored match (the pattern is matched per-line) — verify the Summary row landed
        # and carries the Summary table's column count.
        $rowPattern = "\|\s*" + [regex]::Escape($migId) + "\s*\|"
        Assert-TableRowInFile -Path $ledgerPath -Pattern $rowPattern -Context "summary row for $migId in $ProjectId ledger"
    }

    Write-Host "  $ProjectId -> $migId ($Variant)" -ForegroundColor Green
    return @{ Project = $ProjectId; MigId = $migId; Ledger = $ledgerPath; Variant = $Variant
              TodoSections = @(Get-TodoSectionName -SectionLines $sectionLines) }
}

function Invoke-MigrationFanOut {
    # Resolve targets, ShouldProcess-gate the whole fan-out, then write one entry per project.
    param(
        [string[]]$Targets, [string]$Title, [string]$Source, [string]$SourceLink, [string]$Sfv,
        [string[]]$TargetFiles, [string]$BackwardCompatible, [string]$Variant,
        [string]$Description, [string]$Notes,
        [string[]]$MigrationSteps, [string]$ExpectedOutcome, [string]$RollbackImplications,
        [string[]]$ReversalSteps, [string]$Validation
    )
    if (-not $PSCmdlet.ShouldProcess(($Targets -join ', '), "Add migration entry '$Title' ($Variant)")) {
        return @()
    }
    $results = @()
    foreach ($p in $Targets) {
        $r = Add-MigrationEntry -ProjectId $p -Title $Title -Source $Source -SourceLink $SourceLink `
            -Sfv $Sfv -TargetFiles $TargetFiles -BackwardCompatible $BackwardCompatible `
            -Variant $Variant -Description $Description -Notes $Notes `
            -MigrationSteps $MigrationSteps -ExpectedOutcome $ExpectedOutcome `
            -RollbackImplications $RollbackImplications -ReversalSteps $ReversalSteps -Validation $Validation
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

            # Optional prose fields (PF-IMP-1417): warn — don't silently drop — when a supplied
            # field has no section in the chosen entry shape.
            $itVariant = if ($it.Variant) { $it.Variant } else { "Full" }
            if ($itVariant -eq 'Cleanup' -and $it.Validation) {
                Write-Warning "Batch item [$idx]: Validation ignored — the Cleanup variant folds validation into Expected Outcome."
            }
            if ($it.ReversalSteps) {
                if ($itVariant -eq 'Cleanup') {
                    Write-Warning "Batch item [$idx]: ReversalSteps ignored — the Cleanup variant states its single reversal inline in Rollback Implications."
                } elseif ($it.BackwardCompatible -eq 'yes') {
                    Write-Warning "Batch item [$idx]: ReversalSteps ignored — backward-compatible entries have no reversal-steps section."
                }
            }
            if ($itVariant -eq 'Cleanup' -and $it.Notes) {
                Write-Warning "Batch item [$idx]: Notes ignored — the Cleanup variant has no Notes section; fold the content into Description."
            }
        }

        Write-Host "Batch mode: $($items.Count) migration(s) from $BatchFile" -ForegroundColor Magenta
        $allResults = @()
        foreach ($it in $items) {
            $targets = if ($it.AllProjects) { Resolve-EligibleProjects } else { [string[]]$it.Projects }
            $variant = if ($it.Variant) { $it.Variant } else { "Full" }
            $sfv = if ($it.SourceFrameworkVersion) { $it.SourceFrameworkVersion } else { Get-AuthoringFrameworkVersion }
            Write-Host "Migration '$($it.Title)' -> $($targets -join ', ')" -ForegroundColor Magenta
            $allResults += Invoke-MigrationFanOut -Targets $targets -Title $it.Title -Source $it.Source `
                -SourceLink $(if ($it.SourceLink) { $it.SourceLink } else { "" }) -Sfv $sfv `
                -TargetFiles ([string[]]$it.TargetFiles) -BackwardCompatible $it.BackwardCompatible `
                -Variant $variant -Description $(if ($it.Description) { $it.Description } else { "" }) `
                -Notes $(if ($it.Notes) { $it.Notes } else { "" }) `
                -MigrationSteps $(if ($it.MigrationSteps) { [string[]]$it.MigrationSteps } else { @() }) `
                -ExpectedOutcome $(if ($it.ExpectedOutcome) { $it.ExpectedOutcome } else { "" }) `
                -RollbackImplications $(if ($it.RollbackImplications) { $it.RollbackImplications } else { "" }) `
                -ReversalSteps $(if ($it.ReversalSteps) { [string[]]$it.ReversalSteps } else { @() }) `
                -Validation $(if ($it.Validation) { $it.Validation } else { "" })
        }

        if ($allResults.Count -gt 0) {
            Write-ProjectSuccess -Message "Batch complete: $($allResults.Count) entries created" `
                -Details ($allResults | ForEach-Object { "$($_.Project) $($_.MigId) ($($_.Variant))" })
            Write-TodoRemainderWarning -Results $allResults
            if ($soakInSoak) { Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success }
        } else {
            Write-Warning "Batch produced no entries (all targets skipped or -WhatIf)."
        }
    }
    else {
        # Collapsed-array guard (PF-IMP-1169): `pwsh -File` can't parse arrays, so
        # -TargetFiles 'a','b' arrives as a single "a,b" element and would emit one garbled
        # bullet. A comma with no following space is the collapse signature (prose commas are
        # followed by a space). Warn, don't block — a legitimate single bullet may carry such a
        # comma, and the author reviews/fills the entry prose anyway.
        if ($TargetFiles.Count -eq 1 -and $TargetFiles[0] -match ',\S') {
            Write-Warning ("Single -TargetFiles value contains a comma with no following space: '$($TargetFiles[0])'. " +
                "If you meant to pass MULTIPLE target files, note that 'pwsh -File' collapses -TargetFiles 'a','b' " +
                "into one element — use -Command '& <script> ...' or -BatchFile for multiple values. " +
                "If this is a single bullet whose text legitimately contains a comma, ignore this warning.")
        }

        # Direct mode — validate target selection (exactly one of -Project / -AllProjects)
        if ($AllProjects -and $Project) {
            Write-ProjectError -Message "Specify either -Project or -AllProjects, not both." -ExitCode 1
        }
        if (-not $AllProjects -and -not $Project) {
            Write-ProjectError -Message "Specify -Project <PRJ-NNN[,...]> or -AllProjects." -ExitCode 1
        }
        $targets = if ($AllProjects) { Resolve-EligibleProjects } else { $Project }
        $sfv = if ($SourceFrameworkVersion) { $SourceFrameworkVersion } else { Get-AuthoringFrameworkVersion }

        if (@($targets).Count -eq 0) {
            Write-Warning "No eligible target projects resolved; nothing to do."
            return
        }

        $results = Invoke-MigrationFanOut -Targets $targets -Title $Title -Source $Source `
            -SourceLink $SourceLink -Sfv $sfv -TargetFiles $TargetFiles `
            -BackwardCompatible $BackwardCompatible -Variant $Variant -Description $Description -Notes $Notes

        # @() forces array semantics: a single returned entry unwraps to a bare hashtable whose
        # .Count is its key-count, not 1 — the single-match-scalar footgun (PF-IMP-1148).
        $resultCount = @($results).Count
        if ($resultCount -gt 0) {
            Write-ProjectSuccess -Message "Created $resultCount migration entry/entries" `
                -Details ($results | ForEach-Object { "$($_.Project) $($_.MigId) ($($_.Variant))" })
            Write-TodoRemainderWarning -Results $results
            Write-Verbose "Next Steps: fill the <!-- TODO --> prose in each entry (Description, Migration Steps, Rollback Implications, Validation)."
            Write-Verbose "Next Steps: to skip that pass, author the prose up-front via -BatchFile (MigrationSteps / ExpectedOutcome / RollbackImplications / ReversalSteps / Validation) — see Get-Help -Full."
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
