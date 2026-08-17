<#
.SYNOPSIS
    Warn-first static cross-check that every design dimension (Database / API / UI / Instruction) is declared consistently at each site the design chain reads (PF-IMP-1948 / PF-PRO-064).

.DESCRIPTION
    A design dimension is not declared in one place. Adding one means touching an
    assessment-template section, a parse regex, a return key, a router branch, a
    ValidateSet member, a status-legend row, two update scripts' accepted-status
    lists, and the terminal TDD templates' cross-reference blocks. Nothing binds
    those sites together, so they drift silently: a dimension present at some sites
    and absent at others produces a feature routed to a status its own tracker
    cannot explain, or a design gate that never fires.

    That drift was measured at N=3 dimensions before a fourth was added
    (PF-IMP-1948) — which is why the fourth dimension ships with this validator
    rather than inheriting the broken surface.

    Built on the Validate-IMPSectionRouting.ps1 precedent: one file, static
    assertions over a multi-site contract, no state mutation.

    Checks, per dimension:
      A. Assessment template carries a '### <Name> Design Required' section
      B. AssessmentParsing.psm1 carries the section regex, the return key, a router
         branch on that key, and the CurrentArtifact ValidateSet member
      C. The feature-tracking status legend carries the dimension's status row
      D. Both status-writing update scripts accept the dimension's status
      E. Each TDD template (t1/t2/t3) references the dimension's document prefix
      I. Each downstream enumerator (conditional-document menus, planning inputs, cross-reference
         sections, ownership tables) names the dimension's owning design task

    Status matching deliberately compares the STATUS TEXT ('Needs UI Design'), never
    the leading emoji: emoji comparison in this fleet is sensitive to console-encoding
    round-trips that vary with run composition, which would make this validator flaky
    for reasons unrelated to the contract it checks.

.PARAMETER Blocking
    Exit non-zero when drift is found. Default is warn-first: findings are reported
    and the exit code stays 0, per the framework's new-detector convention. Promote
    to blocking once the surface is clean.

.PARAMETER FrameworkRoot
    Path to the process-framework tree. Defaults to the tree containing this script,
    so the same relative layout resolves in appdev (blueprint/process-framework) and
    in a rolled-out project (process-framework).

.NOTES
    Exit codes:
        0 = no drift, or drift found in warn-first mode (default)
        1 = drift found and -Blocking was supplied
        2 = a site file could not be located (malformed layout)
#>

[CmdletBinding()]
param(
    [switch]$Blocking,
    [string]$FrameworkRoot
)

$ErrorActionPreference = 'Stop'

if (-not $FrameworkRoot) {
    $FrameworkRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

# doc/ is a sibling of the framework tree in both layouts:
#   appdev  : blueprint/process-framework + blueprint/doc
#   project : process-framework           + doc
$docRoot = (Join-Path (Split-Path $FrameworkRoot -Parent) 'doc')

# --- The contract: one row per design dimension -----------------------------
# Adding a fifth dimension means adding a row here AND at every site below; this
# table is what makes the omission visible instead of silent.
$dimensions = @(
    @{ Name = 'Database';    Section = 'Database Design Required';    Key = 'DBDesignRequired';          Artifact = 'SchemaDesign';      StatusText = 'Needs DB Design';          Prefix = 'PD-SCH'; ChainName = 'Database Schema Design'; CreationScript = 'New-SchemaDesign.ps1' }
    @{ Name = 'API';         Section = 'API Design Required';         Key = 'APIDesignRequired';         Artifact = 'APISpecification';  StatusText = 'Needs API Design';         Prefix = 'PD-API'; ChainName = 'API Design';              CreationScript = 'New-APISpecification.ps1' }
    @{ Name = 'UI';          Section = 'UI Design Required';          Key = 'UIDesignRequired';          Artifact = 'UIDesign';          StatusText = 'Needs UI Design';          Prefix = 'PD-UIX'; ChainName = 'UI Design';               CreationScript = 'New-UIDesign.ps1' }
    @{ Name = 'Instruction'; Section = 'Instruction Design Required'; Key = 'InstructionDesignRequired'; Artifact = 'InstructionDesign'; StatusText = 'Needs Instruction Design'; Prefix = 'PD-IND'; ChainName = 'Instruction Design';      CreationScript = 'New-InstructionDesign.ps1' }
)

# --- The sites -------------------------------------------------------------
$sites = [ordered]@{
    AssessmentTemplate = Join-Path $FrameworkRoot 'templates/01-planning/assessment-template.md'
    AssessmentParsing  = Join-Path $FrameworkRoot 'scripts/Common-ScriptHelpers/AssessmentParsing.psm1'
    FeatureTracking    = Join-Path $docRoot       'state-tracking/permanent/feature-tracking.md'
    UpdateFromAssess   = Join-Path $FrameworkRoot 'scripts/update/Update-FeatureTrackingFromAssessment.ps1'
    UpdateBatchStatus  = Join-Path $FrameworkRoot 'scripts/update/Update-BatchFeatureStatus.ps1'
    TddT1              = Join-Path $FrameworkRoot 'templates/02-design/tdd-t1-template.md'
    TddT2              = Join-Path $FrameworkRoot 'templates/02-design/tdd-t2-template.md'
    TddT3              = Join-Path $FrameworkRoot 'templates/02-design/tdd-t3-template.md'
    AiTasks            = Join-Path $FrameworkRoot 'ai-tasks.md'
    MutationGuide      = Join-Path $FrameworkRoot 'guides/support/feature-tracking-mutation-guide.md'
    TaskFdd            = Join-Path $FrameworkRoot 'tasks/02-design/fdd-creation-task.md'
    TaskSchema         = Join-Path $FrameworkRoot 'tasks/02-design/database-schema-design-task.md'
    TaskApi            = Join-Path $FrameworkRoot 'tasks/02-design/api-design-task.md'
    TaskUi             = Join-Path $FrameworkRoot 'tasks/02-design/ui-design-task.md'
    # I. Downstream enumerators — artifacts that list the design dimensions without being
    # design-chain gates themselves. They were invisible to this validator until WI-7, which is
    # exactly how a fifth dimension would ship half-declared: a PASS over the sites one work item
    # happened to name certifies nothing about the sites it did not.
    TaskRetroDoc       = Join-Path $FrameworkRoot 'tasks/00-setup/retrospective-documentation-creation.md'
    TaskArchReview     = Join-Path $FrameworkRoot 'tasks/01-planning/system-architecture-review.md'
    TaskImplPlanning   = Join-Path $FrameworkRoot 'tasks/04-implementation/feature-implementation-planning-task.md'
    TaskFeatureReqEval = Join-Path $FrameworkRoot 'tasks/01-planning/feature-request-evaluation.md'
    TestSpecTemplate   = Join-Path $FrameworkRoot 'templates/03-testing/test-specification-template.md'
    RetroStateTemplate = Join-Path $FrameworkRoot 'templates/support/temp-retrospective-documentation-state-template.md'
    InfoFlowGuide      = Join-Path $FrameworkRoot 'guides/framework/information-flow-guide.md'
}

# I's inputs: each downstream enumerator must name every dimension's owning design task. Matching
# is on the task's ChainName ('UI Design', 'Instruction Design', …) rather than a status emoji,
# because these artifacts reference the tasks, not the tracker statuses.
$enumeratorSites = @(
    'TaskRetroDoc', 'TaskArchReview', 'TaskImplPlanning', 'TaskFeatureReqEval',
    'TestSpecTemplate', 'RetroStateTemplate', 'InfoFlowGuide'
)

# H's inputs: each design-chain task can route a feature to any gate ORDERED AFTER it, so its
# own next-status prose must name those gates. ChainIndex is the task's position in the gate
# order (-1 = precedes every gate); a task must mention every dimension with a higher index.
$chainTasks = @(
    @{ Site = 'TaskFdd';    ChainIndex = -1 }
    @{ Site = 'TaskSchema'; ChainIndex = 0 }
    @{ Site = 'TaskApi';    ChainIndex = 1 }
    @{ Site = 'TaskUi';     ChainIndex = 2 }
)

$content = [ordered]@{}
$missingSites = @()
foreach ($name in $sites.Keys) {
    $path = $sites[$name]
    if (-not (Test-Path $path)) { $missingSites += "$name -> $path"; continue }
    $content[$name] = Get-Content -Path $path -Raw -Encoding UTF8
}

if ($missingSites.Count -gt 0) {
    Write-Host "[ERROR] Could not locate design-dimension site file(s):" -ForegroundColor Red
    $missingSites | ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
    exit 2
}

# --- Reconcile -------------------------------------------------------------
$findings = @()

function Add-Finding {
    param([string]$Dimension, [string]$Site, [string]$What)
    $script:findings += [pscustomobject]@{ Dimension = $Dimension; Site = $Site; Missing = $What }
}

foreach ($d in $dimensions) {
    # A. Assessment template section
    if (-not $content.AssessmentTemplate.Contains("### $($d.Section)")) {
        Add-Finding $d.Name 'assessment-template.md' "section '### $($d.Section)'"
    }

    # B. AssessmentParsing: regex literal, return key, router branch, ValidateSet member
    $parsing = $content.AssessmentParsing
    # The parse regexes are built as '###\s+<Words>\s+Design\s+Required' — match on the
    # whitespace-tokenised form rather than the plain section text.
    $regexForm = '###\s+' + (($d.Section -replace ' Design Required$', '') -replace ' ', '\s+') + '\s+Design\s+Required'
    if (-not $parsing.Contains($regexForm)) {
        Add-Finding $d.Name 'AssessmentParsing.psm1' "parse regex '$regexForm'"
    }
    # Match the ASSIGNMENT, not the bare token: the key also appears in this module's
    # .OUTPUTS block and header comment, so a whole-file Contains would stay green after the
    # key was dropped from the returned hashtable — a vacuous check.
    if ($parsing -notmatch ("(?m)^\s*" + [regex]::Escape($d.Key) + "\s*=")) {
        Add-Finding $d.Name 'AssessmentParsing.psm1' "return-hashtable assignment '$($d.Key) ='"
    }
    if (-not $parsing.Contains("`$req.$($d.Key)")) {
        Add-Finding $d.Name 'AssessmentParsing.psm1' "router branch on `$req.$($d.Key)"
    }
    if (-not $parsing.Contains("'$($d.Artifact)'")) {
        Add-Finding $d.Name 'AssessmentParsing.psm1' "CurrentArtifact ValidateSet member '$($d.Artifact)'"
    }

    # C. Status legend ROW — a markdown table row, not merely the phrase somewhere in the file.
    #    The branching note under the legend also names the dimensions, so a whole-file
    #    Contains would survive deletion of the row it is supposed to guard.
    $legendRow = @($content.FeatureTracking -split "\r?\n" | Where-Object {
        $_.TrimStart().StartsWith('|') -and $_.Contains($d.StatusText)
    })
    if ($legendRow.Count -eq 0) {
        Add-Finding $d.Name 'feature-tracking.md' "status legend table row for '$($d.StatusText)'"
    }

    # D. Status-writing update scripts must ACCEPT the status — i.e. carry it inside a
    #    [ValidateSet(...)]. Both scripts also mention the statuses in comments and in
    #    .PARAMETER help, so a whole-file Contains stays green after the ValidateSet member
    #    is removed and the script starts rejecting the status at the binder.
    foreach ($s in @('UpdateFromAssess', 'UpdateBatchStatus')) {
        $validateSetMembers = [regex]::Matches($content[$s], '(?s)\[ValidateSet\((.*?)\)\]') |
            ForEach-Object { [regex]::Matches($_.Groups[1].Value, '"([^"]*)"') } |
            ForEach-Object { $_.Groups[1].Value }
        if ($validateSetMembers -notcontains $d.StatusText -and
            -not ($validateSetMembers | Where-Object { $_.EndsWith($d.StatusText) })) {
            Add-Finding $d.Name (Split-Path $sites[$s] -Leaf) "ValidateSet member accepting '$($d.StatusText)'"
        }
    }

    # E. TDD templates reference the dimension's document prefix.
    #    Only the three CODE TDD templates (t1/t2/t3) are checked. tdd-instruction-template.md
    #    is deliberately OUT of this set: it is the medium fork, the terminal for a
    #    pure-instruction feature, and it references PD-IND / PD-FDD / TE-TSP but has no reason
    #    to reference PD-UIX / PD-API / PD-SCH. Including it would manufacture false findings
    #    for three of the four dimensions. Its own contract is checked by the New-TDD suite.
    foreach ($t in @('TddT1', 'TddT2', 'TddT3')) {
        if (-not $content[$t].Contains($d.Prefix)) {
            Add-Finding $d.Name (Split-Path $sites[$t] -Leaf) "cross-reference to $($d.Prefix)"
        }
    }

    # G. The feature-tracking mutation guide routes this dimension's creation
    if (-not $content.MutationGuide.Contains($d.CreationScript)) {
        Add-Finding $d.Name 'feature-tracking-mutation-guide.md' "mutation row for $($d.CreationScript)"
    }
}

# F. ai-tasks.md hand-written workflow chains name every design dimension, in
#    design-chain order. These chains are authored prose (the task TABLES are
#    generated), so nothing else keeps them aligned with the runtime order the
#    router actually applies.
$chainLines = @($content.AiTasks -split "\r?\n" | Where-Object {
    $_ -match 'FDD Creation\s*→' -and $_ -match 'TDD Creation'
})
if ($chainLines.Count -eq 0) {
    Add-Finding 'all' 'ai-tasks.md' 'a recognizable design-chain workflow line (FDD Creation -> ... -> TDD Creation)'
}
foreach ($line in $chainLines) {
    $positions = @()
    foreach ($d in $dimensions) {
        $idx = $line.IndexOf($d.ChainName)
        if ($idx -lt 0) {
            Add-Finding $d.Name 'ai-tasks.md' "'$($d.ChainName)' in the design-chain workflow"
        } else {
            $positions += [pscustomobject]@{ Name = $d.Name; Index = $idx }
        }
    }
    # Order check runs only over the dimensions actually present, so a missing
    # dimension is reported once (above) rather than also as a phantom mis-order.
    $ordered = @($positions | Sort-Object Index | ForEach-Object { $_.Name })
    $expected = @($dimensions | Where-Object { $ordered -contains $_.Name } | ForEach-Object { $_.Name })
    if (($ordered -join '>') -ne ($expected -join '>')) {
        Add-Finding 'all' 'ai-tasks.md' ("design-chain order — found $($ordered -join ' -> '), expected $($expected -join ' -> ')")
    }
}

# H. Each design-chain task definition names every gate ordered AFTER it. These tasks are live
#    PRODUCERS of the downstream statuses (the router hands them out), so a task whose own
#    next-status prose stops short of a gate tells the agent a status it can actually reach
#    cannot occur. This is authored task-file content that Build-TaskMetadata.ps1 projects
#    FROM, so regenerating the projections cannot repair it — it must be fixed at source.
foreach ($ct in $chainTasks) {
    $taskName = Split-Path $sites[$ct.Site] -Leaf
    for ($i = $ct.ChainIndex + 1; $i -lt $dimensions.Count; $i++) {
        $dim = $dimensions[$i]
        if (-not $content[$ct.Site].Contains($dim.StatusText)) {
            Add-Finding $dim.Name $taskName "next-status mention of '$($dim.StatusText)' (this task can route there)"
        }
    }
}

# I. Downstream enumerators name every dimension's owning design task. These artifacts are not
#    gates — they are the places that *list* the dimensions (conditional-document menus, planning
#    inputs, cross-reference sections, ownership tables). A dimension missing here does not
#    mis-route a feature; it makes the dimension invisible to whoever is reading that artifact,
#    which is how three dimensions drifted to N=3 before a fourth was added (PF-IMP-1948).
foreach ($site in $enumeratorSites) {
    $siteName = Split-Path $sites[$site] -Leaf
    foreach ($d in $dimensions) {
        if (-not $content[$site].Contains($d.ChainName)) {
            Add-Finding $d.Name $siteName "mention of '$($d.ChainName)' (this artifact enumerates the design dimensions)"
        }
    }
}

# --- Report ----------------------------------------------------------------
$dimensionList = ($dimensions | ForEach-Object { $_.Name }) -join ', '

if ($findings.Count -eq 0) {
    Write-Host "[PASS] Design-dimension consistency — all $($dimensions.Count) dimensions ($dimensionList) are declared at every checked site." -ForegroundColor Green
    exit 0
}

$label = if ($Blocking) { '[FAIL]' } else { '[WARN]' }
$colour = if ($Blocking) { 'Red' } else { 'Yellow' }

Write-Host "$label Design-dimension consistency drift — $($findings.Count) finding(s) across $(($findings | Select-Object -ExpandProperty Dimension -Unique).Count) dimension(s)." -ForegroundColor $colour
Write-Host ""
foreach ($group in ($findings | Group-Object Dimension)) {
    Write-Host "  $($group.Name) dimension:" -ForegroundColor $colour
    foreach ($f in $group.Group) {
        Write-Host "    - $($f.Site): missing $($f.Missing)"
    }
}
Write-Host ""
Write-Host "  Each dimension must be declared at every site above. A dimension present at"
Write-Host "  some sites and absent at others routes features to statuses their own tracker"
Write-Host "  cannot explain, or leaves a design gate that never fires (PF-IMP-1948)."

if ($Blocking) { exit 1 }

Write-Host ""
Write-Host "  Warn-first: exiting 0. Re-run with -Blocking once the surface is clean." -ForegroundColor DarkGray
exit 0
