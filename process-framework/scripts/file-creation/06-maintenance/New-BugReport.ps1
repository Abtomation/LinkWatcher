# New-BugReport.ps1
# Creates a new bug report with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new bug report with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates bug reports by:
    - Generating a unique bug ID (BUG-XXX)
    - Adding the bug to the appropriate priority table in bug-tracking.md
    - Updating bug statistics automatically
    - Providing a complete template for bug tracking

.PARAMETER Title
    The title/summary of the bug (5-100 chars; this is the table-row summary —
    keep it concise and put detail in -Description, -ReproductionSteps, or -Evidence).

.PARAMETER Description
    Detailed description of the bug (10-500 chars; this is the table-row summary —
    compress longer drafts and put reproduction detail in -ReproductionSteps,
    -ExpectedBehavior, -ActualBehavior, or -Evidence).

.PARAMETER DiscoveredBy
    How the bug was discovered. Mirrors the bug-tracking.md Source Types table:
    TestAudit, Testing, TestDevelopment, E2ETesting, CodeReview, BugTriage, UserReport,
    FeatureImplementation, FoundationDevelopment, Refactoring, Deployment, Monitoring, Development.
    The two are kept aligned by a check in the framework self-tests; adding a value here without
    its table row (or the reverse) fails that check.

.PARAMETER Severity
    Bug severity level (Critical, High, Medium, Low)

.PARAMETER Component
    The component/area where the bug was found (3-50 chars; concise area name —
    put detail in -Description).

.PARAMETER ReproductionSteps
    Steps to reproduce the bug (optional)

.PARAMETER ExpectedBehavior
    What should happen (optional)

.PARAMETER ActualBehavior
    What actually happens (optional)

.PARAMETER Environment
    Environment where bug was found (Development, Testing, Staging, Production)

.PARAMETER Evidence
    Evidence or logs related to the bug (optional)

.PARAMETER RelatedFeature
    Related feature ID if applicable (optional)

.PARAMETER PreTriaged
    When set, creates the bug directly in 🔍 Needs Fix status instead of 🆕 Needs Triage.
    Use when the reporter already has complete root cause analysis and scope.
    Requires -Scope to be specified.

.PARAMETER Scope
    Bug scope description (e.g., "Single file", "Multi-module"). Required when -PreTriaged is set.

.PARAMETER TrackingFile
    Overrides the project-root-relative bug-tracking.md this script writes to. Mirrors
    Update-BugStatus.ps1's parameter of the same name; intended for tests exercising the real
    write path against a fixture. Defaults to doc/state-tracking/permanent/bug-tracking.md.

.PARAMETER Dims
    Development dimension abbreviations relevant to the bug, space- or comma-separated
    (e.g. "SE DI" or "SE,DI"). Validated against the 10 documented codes:
    AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI - see the Development Dimensions Guide. Written to the
    report's Dims field; left empty when omitted.

.PARAMETER Workflows
    User workflow IDs the bug affects (e.g. "WF-001, WF-003"). Written to the report's Workflows
    field; left empty when omitted.

.PARAMETER OriginBug
    The single bug whose cycle produced this one (e.g. "PD-BUG-127") — the bug being fixed when a
    Code Review found this defect, the bug whose similar-issues sweep turned it up, or the closed
    bug this one continues when the Reopen Workflow routes a recurrence to a new bug. Walking
    Origin backwards yields the defect chain (PF-PRO-078). Validated to exist as a row in the live
    tracker or its archive: a mistyped origin fails loudly rather than creating a dangling link.
    Written to the row's Origin cell and as an Origin bullet in the bug's Bug Details block; a
    tracker whose header predates the column keeps the block bullet and warns once.

.EXAMPLE
    New-BugReport.ps1 -Title "Login fails with special characters" -Description "Users cannot login when password contains special characters" -DiscoveredBy "TestAudit" -Severity "High" -Component "Authentication"

.EXAMPLE
    New-BugReport.ps1 -Title "Memory leak in user service" -Description "Memory usage increases over time" -DiscoveredBy "CodeReview" -Severity "Critical" -Component "Performance" -Environment "Production"

.EXAMPLE
    New-BugReport.ps1 -Title "Parser skips backtick paths" -Description "Markdown parser ignores backtick-delimited paths" -DiscoveredBy "CodeReview" -Severity "Medium" -Component "Parsers" -PreTriaged -Scope "Single parser module" -RelatedFeature "2.1.1"

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Adds bugs to appropriate priority tables based on severity
    - Updates statistics automatically
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if ($_.Length -lt 5) {
            throw "Title is too short ($($_.Length) chars; minimum 5). Provide a more descriptive title."
        }
        if ($_.Length -gt 100) {
            $over = $_.Length - 100
            throw "Title is too long ($($_.Length) chars; maximum 100, $over over). This is the table-row summary — shorten the title and put detail in -Description, -ReproductionSteps, or -Evidence."
        }
        $true
    })]
    [Alias("BugTitle")]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if ($_.Length -lt 10) {
            throw "Description is too short ($($_.Length) chars; minimum 10). Provide a more substantive description."
        }
        if ($_.Length -gt 500) {
            $over = $_.Length - 500
            throw "Description is too long ($($_.Length) chars; maximum 500, $over over). This is the table-row summary — compress the description and put reproduction detail in -ReproductionSteps, -ExpectedBehavior, -ActualBehavior, or -Evidence."
        }
        $true
    })]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [ValidateSet("TestAudit", "Testing", "TestDevelopment", "E2ETesting", "CodeReview", "BugTriage", "UserReport", "FeatureImplementation", "FoundationDevelopment", "Refactoring", "Deployment", "Monitoring", "Development")]
    [string]$DiscoveredBy,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Critical", "High", "Medium", "Low")]
    [Alias("Priority")]
    [string]$Severity,

    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if ($_.Length -lt 3) {
            throw "Component is too short ($($_.Length) chars; minimum 3). Name the component/area where the bug was found."
        }
        if ($_.Length -gt 50) {
            $over = $_.Length - 50
            throw "Component is too long ($($_.Length) chars; maximum 50, $over over). Use a concise component/area name and put detail in -Description."
        }
        $true
    })]
    [string]$Component,

    [Parameter(Mandatory = $false)]
    [string]$ReproductionSteps = "",

    [Parameter(Mandatory = $false)]
    [string]$ExpectedBehavior = "",

    [Parameter(Mandatory = $false)]
    [string]$ActualBehavior = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Development", "Testing", "Staging", "Production")]
    [string]$Environment = "Development",

    [Parameter(Mandatory = $false)]
    [string]$Evidence = "",

    [Parameter(Mandatory = $false)]
    [Alias("AffectedFeature")]
    [string]$RelatedFeature = "",

    # Same contract in both bug-tracker writers (Update-BugStatus.ps1 carries the identical
    # block), pinned by a cross-script drift guard in New-BugReport.Tests.ps1. Deliberately
    # the 10 documented dimension codes, not the tech-debt validator's 12 - TST and AIC are
    # tech-debt taxonomy (PF-IMP-2130). Blank stays valid: the parameter is optional.
    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if ([string]::IsNullOrWhiteSpace($_)) { return $true }
        $validDims = @('AC', 'CQ', 'ID', 'DA', 'EM', 'SE', 'PE', 'OB', 'UX', 'DI')
        $invalid = @($_ -split '[\s,]+' | Where-Object { $_ -ne '' -and $_ -notin $validDims })
        if ($invalid) {
            throw "Invalid -Dims code(s): $($invalid -join ', '). Valid codes: $($validDims -join ', '). Use space or comma to separate multiple. See the Development Dimensions Guide."
        }
        return $true
    })]
    [string]$Dims = "",

    [Parameter(Mandatory = $false)]
    [string]$Workflows = "",

    # Defect-chain origin (PF-PRO-078). Same contract in both bug-tracker writers; the shape is
    # validated here and the referenced row's existence below, once the tracker has been read.
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^(PD-BUG|BUG)-\d+$')]
    [string]$OriginBug = "",

    [Parameter(Mandatory = $false)]
    [switch]$PreTriaged,

    [Parameter(Mandatory = $false)]
    [string]$Scope = "",

    # Mirrors Update-BugStatus.ps1's -TrackingFile: overrides the project-root-relative
    # default so a caller (notably this script's Pester suite) can exercise the real write
    # path against a fixture. Added with PF-IMP-2324 — until then this script had no
    # write-path coverage of any kind, which is why two statistics defects survived in it.
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

# Soak verification (PF-PRO-028 v2.0 Pattern A; caller-aware no-arg form)
Register-SoakScript
$soakInSoak = Test-ScriptInSoak

# Soak-verification wrapper begins (PF-PRO-028 v2.0)
try {

# Validate -PreTriaged requires -Scope
if ($PreTriaged -and -not $Scope) {
    Write-ProjectError -Message "-PreTriaged requires -Scope to be specified." -ExitCode 1
}

# Get current date in YYYY-MM-DD format
$currentDate = Get-Date -Format "yyyy-MM-dd"

# Path to bug tracking file - use project root for reliable path resolution
$ProjectRoot = Get-ProjectRoot
if (-not $TrackingFile) {
    $TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/bug-tracking.md"
}
$BugTrackingFile = $TrackingFile

if (-not (Test-Path $BugTrackingFile)) {
    Write-ProjectError -Message "Bug tracking file not found: $BugTrackingFile" -ExitCode 1
}

# Read current content
$Content = Get-Content -Path $BugTrackingFile -Raw -Encoding UTF8

# Defect-chain origin (PF-PRO-078): the referenced bug must exist as a row, live or archived.
# Checked BEFORE the ShouldProcess gate so a typo costs neither an ID nor a dangling link — a
# chain is only navigable if every link resolves. The archive path mirrors Update-BugStatus.ps1's
# default derivation (sibling archive/ directory), and its absence is not an error: a young
# project has no archive yet, and the live file alone then decides.
if ($OriginBug -ne "") {
    $originPattern = "\|\s*" + [regex]::Escape($OriginBug) + "\s*\|"
    $originFound = $Content -match $originPattern
    if (-not $originFound) {
        $originArchive = Join-Path -Path (Split-Path -Parent $BugTrackingFile) -ChildPath "archive/bug-tracking-archive.md"
        if (Test-Path $originArchive) {
            $originFound = (Get-Content -Path $originArchive -Raw -Encoding UTF8) -match $originPattern
        }
    }
    if (-not $originFound) {
        Write-ProjectError -Message "-OriginBug '$OriginBug' matches no bug row in $BugTrackingFile or its archive. Check the ID: an origin that resolves to nothing breaks the chain walk it exists to enable." -ExitCode 1
    }
}

# Early WhatIf check — exit before consuming an ID from the registry
if (-not $PSCmdlet.ShouldProcess($BugTrackingFile, "Add new bug report '$Title'")) {
    return
}

# Generate unique bug ID using the central registry
$BugId = New-ProjectId -Prefix "PD-BUG" -Description "Bug report: $Title"

Write-Host "🐛 Creating bug report: $BugId" -ForegroundColor Yellow
Write-Host "📝 Title: $Title" -ForegroundColor Cyan

# Determine which table to add the bug to based on severity
$TableSection = switch ($Severity) {
    "Critical" { "### Critical Bugs" }
    "High" { "### High Priority Bugs" }
    "Medium" { "### Medium Priority Bugs" }
    "Low" { "### Low Priority Bugs" }
}

# Priority uses text format (Critical/High/Medium/Low) — same as technical-debt-tracking
$PriorityText = $Severity

# Report metadata seeds the bug's '## Bug Details' block (PF-IMP-2184 / PF-PRO-073); the Notes
# cell keeps only a capped summary plus the pointer to that block. Previously all of this went
# into the cell, where it became the first layer of an unbounded accretion — a table row cannot
# be line-broken, so a cell has no upper bound (measured at 51,854 characters in APP-001).
#
# NOTE — deliberate duplication of Get-BugAnchor / Format-BugNotesCell / $BugNotesCellCap from
# Update-BugStatus.ps1. The shared home would be Common-ScriptHelpers, which is FWK-FB-owned
# substrate this workspace may not edit, so extraction is an FB change (filed as an IMP).
# Until then the drift risk is guarded by a cross-script constant assertion in
# New-BugReport.Tests.ps1 — a drifted anchor form would silently break every pointer.
$BugNotesCellCap = 200

function Get-BugAnchor {
    param([string]$BugId)
    return "#$($BugId.ToLower())"
}

function Format-BugNotesCell {
    param([string]$BugId, [string]$Summary)
    $pointer = "[details]($(Get-BugAnchor -BugId $BugId))"
    $budget = $BugNotesCellCap - $pointer.Length - 1
    $clean = ($Summary -replace '\s+', ' ').Trim()
    if ($clean.Length -gt $budget) {
        $clean = $clean.Substring(0, [Math]::Max(0, $budget - 1)).TrimEnd() + '…'
    }
    if ([string]::IsNullOrWhiteSpace($clean)) { return $pointer }
    return "$clean $pointer"
}

# Defect chains, derived (PF-PRO-078) — never hand-maintained, so the line cannot go stale the way
# the retired All-Triaged line did (PF-IMP-2137). Reads the Origin cells of the ACTIVE rows only:
# the statistics block is computed from the live file, and the archive is not loaded on a filing.
# A chain is therefore reported as its root plus its active descendants; the full depth (closed
# members included) is what Bug Triage walks when it takes the chain decision.
#
# NOTE — deliberate duplication with Update-BugStatus.ps1, same reason as Get-BugAnchor above:
# the shared home is Common-ScriptHelpers, FWK-FB substrate this workspace may not edit. Both
# copies are pinned identical by a cross-script drift guard in New-BugReport.Tests.ps1.
function Format-OpenChainsValue {
    param([string]$ActiveSection)

    $lines = $ActiveSection -split "\r?\n"

    # Locate ID and Origin by header, never by index: the column position differs between a
    # migrated tracker and one still on the 11-column schema.
    $idIdx = -1
    $originIdx = -1
    foreach ($line in $lines) {
        if ($line -notmatch '(?i)^\|\s*ID\s*\|') { continue }
        $hdr = @(Split-MarkdownTableRow -Line $line.Trim())
        for ($i = 0; $i -lt $hdr.Count; $i++) {
            switch ($hdr[$i].Trim()) {
                'ID'     { $idIdx = $i }
                'Origin' { $originIdx = $i }
            }
        }
        if ($originIdx -ge 0) { break }
    }
    if ($idIdx -lt 0 -or $originIdx -lt 0) { return 'none' }   # tracker predates the column

    $origins = [ordered]@{}
    foreach ($line in $lines) {
        if ($line -notmatch '^\|\s*(PD-BUG-\d+|BUG-\d+)\s*\|') { continue }
        $cells = @(Split-MarkdownTableRow -Line $line.Trim())
        if ($cells.Count -le $originIdx -or $cells.Count -le $idIdx) { continue }
        # A decorative placeholder is not an origin. A column migration fills empty cells with
        # whatever default it was given, and a table-row builder uses an em dash by default, so
        # a run of placeholders would otherwise read as one chain rooted at the placeholder
        # itself (measured while mutation-verifying this function, 2026-09-04).
        $originCell = "$($cells[$originIdx])".Trim()
        if ($originCell -in @('-', [char]0x2014, [char]0x2013, 'N/A', 'n/a')) { $originCell = '' }
        $origins[$cells[$idIdx].Trim()] = $originCell
    }

    $chains = [ordered]@{}
    foreach ($id in @($origins.Keys)) {
        if ([string]::IsNullOrWhiteSpace($origins[$id])) { continue }
        # Walk to the chain root. The walk stops at a bug that is not itself an active row (its
        # origin is unknown here — it is closed or archived), and a $seen guard keeps a corrupt
        # cycle from spinning forever rather than trusting the data to be acyclic.
        $root = $origins[$id]
        $seen = @{ $id = $true }
        while ($origins.Contains($root) -and -not [string]::IsNullOrWhiteSpace($origins[$root]) -and -not $seen.ContainsKey($root)) {
            $seen[$root] = $true
            $root = $origins[$root]
        }
        if (-not $chains.Contains($root)) { $chains[$root] = [System.Collections.ArrayList]::new() }
        [void]$chains[$root].Add($id)
    }
    if ($chains.Count -eq 0) { return 'none' }

    $parts = @()
    foreach ($root in @($chains.Keys)) {
        # The root joins its own member list when it is itself an active row, so the count and
        # the list always agree; a root that is closed or archived is named but not listed.
        $members = @($chains[$root])
        if ($origins.Contains($root)) { $members += $root }
        $members = @($members | Sort-Object { [int]($_ -replace '\D', '') })
        $parts += "$root chain - $($members.Count) active ($($members -join ', '))"
    }
    return ($parts -join '; ')
}

$DetailBullets = @("- **Source**: $DiscoveredBy · **Environment**: $Environment · **Component**: $Component")
if ($OriginBug -ne "")         { $DetailBullets += "- **Origin**: $OriginBug" }
if ($ReproductionSteps -ne "") { $DetailBullets += "- **Repro**: $ReproductionSteps" }
if ($ExpectedBehavior -ne "")  { $DetailBullets += "- **Expected**: $ExpectedBehavior" }
if ($ActualBehavior -ne "")    { $DetailBullets += "- **Actual**: $ActualBehavior" }
if ($Evidence -ne "")          { $DetailBullets += "- **Evidence**: $Evidence" }

$NotesField = Format-BugNotesCell -BugId $BugId -Summary "Reported $currentDate ($DiscoveredBy)"

# Escape pipe characters in user-supplied text to prevent markdown table corruption
$Title = $Title -replace '\|', '\|'
$Description = $Description -replace '\|', '\|'
$NotesField = $NotesField -replace '\|', '\|'

# Related feature field
$RelatedFeatureField = if ($RelatedFeature -ne "") { $RelatedFeature } else { "N/A" }

# Workflows field
$WorkflowsField = if ($Workflows -ne "") { $Workflows } else { "" }

# Dims field
$DimsField = if ($Dims -ne "") { $Dims } else { "" }

# Origin field (PF-PRO-078). A tracker whose header predates the column drops this cell silently
# through New-HeaderDrivenTableRow — warn once so the origin's absence from the row is visible,
# and note that the Bug Details bullet above still carries it until the column migration lands.
$OriginField = $OriginBug
$HasOriginColumn = $Content -match '(?m)^\|\s*ID\s*\|.*\|\s*Origin\s*\|'
if ($OriginBug -ne "" -and -not $HasOriginColumn) {
    Write-ProjectLog "Tracker has no Origin column yet — $OriginBug recorded in the Bug Details block only (apply the Origin column migration to surface it in the row)" -Level "WARN"
}

# Determine status and scope based on -PreTriaged
$BugStatus = if ($PreTriaged) { "🔍 Needs Fix" } else { "🆕 Needs Triage" }
$ScopeField = if ($Scope -ne "") { $Scope -replace '\|', '\|' } else { "" }

# Create table row — header-driven (PF-IMP-1599): cells are ordered by the severity section's
# own table header, so a column added to bug-tracking.md lands as "—" in the correct position
# instead of silently shifting every following cell.
$RowValueMap = @{
    'ID'              = $BugId
    'Title'           = $Title
    'Status'          = $BugStatus
    'Priority'        = $PriorityText
    'Scope'           = $ScopeField
    'Reported'        = $currentDate
    'Description'     = $Description
    'Related Feature' = $RelatedFeatureField
    'Workflows'       = $WorkflowsField
    'Dims'            = $DimsField
    'Notes'           = $NotesField
}
# Origin (PF-PRO-078) is added only when the tracker's header carries the column: a map key with
# no header makes the helper warn on EVERY filing against an unmigrated project tracker, which
# would train readers to ignore the warning that actually matters (the one raised above, once,
# when an origin was supplied and cannot reach the row).
if ($HasOriginColumn) { $RowValueMap['Origin'] = $OriginField }

$TableRow = New-HeaderDrivenTableRow -Content $Content -SectionHeading $TableSection -ValueMap $RowValueMap

# Find the appropriate table and replace the "No bugs" message
$NobugsPattern = switch ($Severity) {
    "Critical" { "\| _No critical bugs currently active_ \|" }
    "High" { "\| _No high priority bugs currently active_ \|" }
    "Medium" { "\| _No medium priority bugs currently active_ \|" }
    "Low" { "\| _No low priority bugs currently active_ \|" }
}

# Replace the "no bugs" message with the new bug entry
$UpdatedContent = $Content -replace $NobugsPattern, $TableRow

# If the pattern wasn't found (table already has bugs), add to the end of the table
if ($UpdatedContent -eq $Content) {
    # Find the specific section and add the bug after the last existing bug row
    $SectionPattern = "($TableSection.*?)(?=^#{2,3}\s|\z)"
    $SectionMatch = [regex]::Match($UpdatedContent, $SectionPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)

    if ($SectionMatch.Success) {
        $SectionContent = $SectionMatch.Groups[1].Value

        # Find the last table row in this section (line that starts with | and contains bug data)
        $TableRowPattern = "(\| PD-BUG-\d+.*\|)(?=\s*$)"
        $TableRowMatches = [regex]::Matches($SectionContent, $TableRowPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)

        if ($TableRowMatches.Count -gt 0) {
            # Get the last table row
            $LastRowMatch = $TableRowMatches[$TableRowMatches.Count - 1]
            $InsertPosition = $SectionMatch.Index + $LastRowMatch.Index + $LastRowMatch.Length
            $UpdatedContent = $UpdatedContent.Substring(0, $InsertPosition) + "`n$TableRow" + $UpdatedContent.Substring($InsertPosition)
        }
        else {
            # No PD-BUG rows found — insert after the table header separator (| --- | ... |)
            $HeaderSepPattern = "(\| -+\s*(?:\| -+\s*)+\|)"
            $HeaderSepMatches = [regex]::Matches($SectionContent, $HeaderSepPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
            if ($HeaderSepMatches.Count -gt 0) {
                $SepMatch = $HeaderSepMatches[0]
                $InsertPosition = $SectionMatch.Index + $SepMatch.Index + $SepMatch.Length
                $UpdatedContent = $UpdatedContent.Substring(0, $InsertPosition) + "`n$TableRow" + $UpdatedContent.Substring($InsertPosition)
            }
        }
    }
}

# Update statistics - count all active bug rows (everything before "## Closed Bugs" section)
# Active statuses: 🆕 Needs Triage, 🔍 Needs Fix, 🟡 In Progress, 👀 Needs Review, 🔄 Reopened
$ClosedSectionIndex = $UpdatedContent.IndexOf("## Closed Bugs")
$ActiveSection = if ($ClosedSectionIndex -gt 0) { $UpdatedContent.Substring(0, $ClosedSectionIndex) } else { $UpdatedContent }

# Anchored to line start so this counts ROWS, not PD-BUG mentions (PF-PRO-078). The unanchored
# form counted a row once per bug id appearing anywhere in it, so the Origin column made every
# linked bug add one phantom to the total — measured on a two-bug fixture reporting 3 active.
# Update-BugStatus.ps1's own statistics pass was already row-anchored and never had the defect.
$ActiveCount = ([regex]::Matches($ActiveSection, '(?m)^\|\s*PD-BUG-\d+\s*\|')).Count
$UpdatedContent = [regex]::Replace($UpdatedContent, '(?m)^(- \*\*Total Active Bugs\*\*:)[^\r\n]*', "`${1} $ActiveCount")

# Update the priority-specific lines. The label is carried through from the file by the capture
# group, so both live label forms — "- **Critical**:" and the shipped "- **Critical (P1)**:" —
# are written without either being rewritten into the other. The WHOLE value is rewritten (count
# and ID list together), so a count can no longer contradict the IDs beside it (PF-IMP-2215),
# and a bullet present in an unrecognized form aborts rather than no-opping silently
# (PF-IMP-2324) — matching Update-BugStatus.ps1's Update-BugStatisticsContent.
$prioritySuffix = @{ Critical = "P1"; High = "P2"; Medium = "P3"; Low = "P4" }
$unmatchedStats = @()

foreach ($priority in @("Critical", "High", "Medium", "Low")) {
    $ids = @([regex]::Matches($ActiveSection, "\| (PD-BUG-\d+).*\| $priority \|") | ForEach-Object { $_.Groups[1].Value })
    $tail = if ($ids.Count -eq 0) { "0" } else { "$($ids.Count) ($($ids -join ', '))" }

    $statPattern = "(?m)^(- \*\*$priority(?: \($($prioritySuffix[$priority])\))?\*\*:)[^\r\n]*"
    if ([regex]::IsMatch($UpdatedContent, $statPattern)) {
        $UpdatedContent = [regex]::Replace($UpdatedContent, $statPattern, "`${1} $tail")
    }
    elseif ([regex]::IsMatch($UpdatedContent, "(?m)^- \*\*$priority")) {
        $unmatchedStats += $priority
    }
}

if ($unmatchedStats.Count -gt 0) {
    Write-ProjectError -Message "Bug statistics not written: the $($unmatchedStats -join ', ') bullet(s) are present but in an unrecognized label form. Expected '- **<Priority>**:' or '- **<Priority> (P#)**:'." -ExitCode 1
}

# Open chains (PF-PRO-078). Written only where the bullet exists: a tracker that predates the
# line is not retrofitted here — that is the Origin column migration's job — and the absence is
# silent rather than a warning, because the derivation has nothing to say without the column.
$openChainsPattern = '(?m)^(- \*\*Open chains\*\*:)[^\r\n]*'
if ([regex]::IsMatch($UpdatedContent, $openChainsPattern)) {
    $ActiveSectionAfter = if ($ClosedSectionIndex -gt 0) { $UpdatedContent.Substring(0, $UpdatedContent.IndexOf("## Closed Bugs")) } else { $UpdatedContent }
    $UpdatedContent = [regex]::Replace($UpdatedContent, $openChainsPattern, "`${1} $(Format-OpenChainsValue -ActiveSection $ActiveSectionAfter)")
}

# Seed the bug's Bug Details block (PF-IMP-2184). The section is created when the file predates
# the convention — a project receives this script at a Framework Rollout but only gains the
# section when its Mode C migration is applied, and refusing in that window would fail every
# filing. Placement mirrors the shipped template: after '## Bug Statistics', which keeps detail
# prose below the region this script scans for active-bug counts.
$blockLines = [System.Collections.ArrayList]@($UpdatedContent -split "\r?\n")
$sectionIdx = -1
for ($i = 0; $i -lt $blockLines.Count; $i++) {
    if ($blockLines[$i].Trim() -eq '## Bug Details') { $sectionIdx = $i; break }
}
if ($sectionIdx -lt 0) {
    $statsIdx = -1
    for ($i = 0; $i -lt $blockLines.Count; $i++) {
        if ($blockLines[$i] -match '^##\s+Bug Statistics\s*$') { $statsIdx = $i; break }
    }
    $createAt = $blockLines.Count
    if ($statsIdx -ge 0) {
        for ($j = $statsIdx + 1; $j -lt $blockLines.Count; $j++) {
            if ($blockLines[$j] -match '^##\s' -or $blockLines[$j].Trim() -match '^(-{3,}|\*{3,}|_{3,})$') { $createAt = $j; break }
        }
        while ($createAt -gt $statsIdx + 1 -and [string]::IsNullOrWhiteSpace($blockLines[$createAt - 1])) { $createAt-- }
    }
    $blockLines.InsertRange($createAt, [string[]]@('', '## Bug Details'))
    $sectionIdx = $createAt + 1
    Write-ProjectLog "Created '## Bug Details' section (file predated PF-IMP-2184)" -Level "WARN"
}

# Append at the end of the section (before the next '## ' heading or horizontal rule).
$insertAt = $blockLines.Count
for ($j = $sectionIdx + 1; $j -lt $blockLines.Count; $j++) {
    if ($blockLines[$j] -match '^##\s' -or $blockLines[$j].Trim() -match '^(-{3,}|\*{3,}|_{3,})$') { $insertAt = $j; break }
}
while ($insertAt -gt $sectionIdx + 1 -and [string]::IsNullOrWhiteSpace($blockLines[$insertAt - 1])) { $insertAt-- }
$blockLines.InsertRange($insertAt, [string[]](@('', "### $BugId", '') + $DetailBullets))

# Drop the decorative empty-section placeholder — otherwise the file asserts "no active bugs"
# directly above the bug just filed (same treatment the priority tables' placeholder rows get).
for ($i = $sectionIdx; $i -lt $blockLines.Count; $i++) {
    if ($blockLines[$i].Trim() -eq '_No active bugs currently._') { $blockLines.RemoveAt($i); break }
}
$UpdatedContent = ($blockLines -join "`r`n")

try {
    # Write updated content
    Set-Content -Path $BugTrackingFile -Value $UpdatedContent -NoNewline -Encoding UTF8

    # The row's pointer must resolve to exactly one block. Nothing validates '#anchor' links
    # (Validate-StateTracking skips them; LinkWatcher does not check anchors against headings),
    # so the invariant is asserted here at the write site or nowhere (PF-IMP-2184).
    $writtenBack = Get-Content -Path $BugTrackingFile -Raw
    $blockCount = ([regex]::Matches($writtenBack, "(?m)^###\s+$([regex]::Escape($BugId))\s*$")).Count
    if ($blockCount -ne 1) {
        Write-ProjectError -Message "Bug Details block for $BugId written $blockCount times (expected exactly 1)" -ExitCode 1
    }

    # Verify deterministic post-condition: row was inserted (PF-PRO-028 v2.0)
    Assert-TableRowInFile -Path $BugTrackingFile -Pattern "\| $BugId \|" -Context "bug row for $BugId in $BugTrackingFile"

    $details = @(
        "Severity: $Severity",
        "Component: $Component",
        "Discovered By: $DiscoveredBy",
        "Environment: $Environment"
    )

    if ($RelatedFeature -ne "") {
        $details += "Related Feature: $RelatedFeature"
    }

    Write-ProjectSuccess -Message "Created bug report with ID: $BugId" -Details $details

    if ($PreTriaged) {
        Write-Verbose "Next Steps: Bug created in Triaged status — skip triage, proceed to Bug Fixing task"
        Write-Verbose "Next Steps: Use Update-BugStatus.ps1 to transition to In Progress when work begins"
        Write-Verbose "Tip: Use 'Bug Fixing' task (PF-TSK-007) to fix this bug"
    } else {
        Write-Verbose "Next Steps: Run Bug Triage task to evaluate and prioritize this bug"
        Write-Verbose "Next Steps: Bug will be assigned priority and severity during triage"
        Write-Verbose "Next Steps: After triage, bug can be assigned for fixing"
        Write-Verbose "Tip: Use 'Bug Triage' task to process all reported bugs"
    }
}
catch {
    Write-ProjectError -Message "Failed to create bug report: $($_.Exception.Message)" -ExitCode 1
}

    # Soak: success outcome (PF-PRO-028 v2.0)
    if ($soakInSoak) { Confirm-SoakInvocation -Outcome success }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -Outcome failure -Notes $soakErrMsg
    }
    Write-ProjectError -Message "Bug report creation failed: $($_.Exception.Message)" -ExitCode 1
}
