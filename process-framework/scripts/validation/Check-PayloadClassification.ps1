<#
.SYNOPSIS
    Warn-first gate that every file in a MIXED-CLASS payload directory carries a classification
    ruling — either a support_exceptions entry or a substrate_residents entry (PF-IMP-2027).

.DESCRIPTION
    payload-manifest.json classifies at FILE level wherever a directory mixes classes, and its
    default rule is "unlisted = substrate". That default is fail-safe in the leak direction (an
    over-shipped file is edit-refused clutter at a project, not data loss), but it is also SILENT:
    a file added beside a support exception is classified by omission, and nothing says whether
    that omission was a decision or an oversight. This gate makes the distinction checkable.

    WHAT IT ASKS, per file in a mixed-class directory: is this path named on either list? A file
    on neither is not necessarily misclassified — it is UNRULED, which is the finding. The remedy
    the finding names is a one-line manifest entry on whichever list is correct.

    SCOPE IS DERIVED, NEVER ENUMERATED. The mixed-class directories are computed as the parent of
    every FILE-level support_exceptions entry, plus the skills channel (whose units are folders).
    A support entry added in a NEW directory therefore pulls that directory under the check by
    itself — there is no second directory list to forget, which is the failure mode this gate
    exists to close rather than reproduce. Directory-level entries (tasks/support/, the agents
    channel) are deliberately NOT scanned: a prefix entry already covers every file beneath it, so
    a new file there is classified by construction (the agents channel states this fail-safety in
    its own manifest note).

    Scope and expectations by face — the same discriminator the sibling ownership gate uses,
    because the same problem arises: a framework face's producer blueprint legitimately holds its
    OWN domain files, which this producer's manifest never classifies and must not flag.
      - Self-hosted authoring root (FB — consumer and producer keys name one tree): every file in
        a derived mixed-class directory must be ruled on.
      - Framework face (faces split, post-cutover): only RECEIVED files (those present in the
        consumer tree) are checked; the workspace's own domain files carry no ruling obligation.
        Measured 2026-08-30: without this discriminator the check reports 40 findings at a child's
        blueprint, 23 of them the child's own domain scripts — i.e. it would be undeployable.
      - Leaf workspace, or no manifest at either face: dormant (exit 0, one loud line).

    NOT A RECLASSIFIER. This gate reads the manifest and reports; it never decides a class and
    never writes. substrate_residents adds no classification of its own — classification_rules
    .default still governs the whole tree — it records which unlisted paths were ruled on, so
    "ruled substrate" is distinguishable from "never classified".

.PARAMETER Blocking
    Exit 1 on findings instead of the warn-first exit 0.

.PARAMETER ProjectRoot
    Workspace root override for test fixtures (defaults to the resolved project root).

.EXAMPLE
    Check-PayloadClassification.ps1
    # Warn-first sweep (pre-push form)

.EXAMPLE
    Check-PayloadClassification.ps1 -Blocking
    # Gate form: exit 1 on any unruled file in a mixed-class directory

.NOTES
    PF-IMP-2027 (2026-08-30). Closes the tree->manifest direction that PayloadFilter.psm1 assigned
    to "the level-aware drift gate (E3)" and that neither E3 gate shipped: Sync-Substrate.ps1
    compares received-vs-blueprint CONTENT, Check-OwnershipLines.ps1 resolves OWNER IDs, and
    Build-PayloadStage computes only the opposite direction (manifest entries matching no file).
    Authored as a separate gate rather than folded into Check-OwnershipLines because the two ask
    different questions of the same tree — ownership vs. classification — and the ownership gate's
    allowlist is already the subject of an open consolidation row.
    Read-only validator - not soak-enrolled (validator class, fleet convention).
    Substrate class: unlisted in payload-manifest.json support_exceptions.scripts, like every
    sibling in scripts/validation/ - the directory holds no support entry and must stay class-pure.
OWNERSHIP: FWK-FB (FrameworkBuilder) - canonical at FrameworkBuilder; anywhere else a received copy. Edit only at the owning workspace. An agent may only modify files its workspace owns.
#>

[CmdletBinding()]
param(
    [switch]$Blocking,

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'

# Import the common helpers (Get-ProjectRoot / Get-BlueprintPath)
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

$root = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { Get-ProjectRoot } else { $ProjectRoot }
$configPath = Join-Path -Path $root -ChildPath "doc/project-config.json"
if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Check-PayloadClassification: no doc/project-config.json at '$root' — cannot resolve the workspace's faces."
}
try {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
} catch {
    throw "Check-PayloadClassification: doc/project-config.json at '$configPath' could not be parsed ($($_.Exception.Message))."
}

$role = if ($config.project_metadata -and $config.project_metadata.role) { $config.project_metadata.role } else { 'project' }
if ($role -eq 'project') {
    Write-Host "Check-PayloadClassification: leaf workspace (role 'project') — no producer face; a project ships nothing and classifies nothing. Exit 0."
    exit 0
}

$consumerRel = if ($config.paths -and $config.paths.process_framework) { $config.paths.process_framework } else { 'process-framework' }
$consumer = [System.IO.Path]::GetFullPath((Join-Path -Path $root -ChildPath $consumerRel)).TrimEnd('\', '/')
$producer = [System.IO.Path]::GetFullPath((Get-BlueprintPath -ProjectRoot $root)).TrimEnd('\', '/')
$selfHosted = ($consumer -ieq $producer)

$manifestPath = Join-Path -Path $producer -ChildPath "payload-manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath) -and -not $selfHosted) {
    $manifestPath = Join-Path -Path $consumer -ChildPath "payload-manifest.json"
}
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Write-Host "Check-PayloadClassification: no payload-manifest.json at either face — this workspace has not received a payload-classified rollout yet. Gate dormant. Exit 0."
    exit 0
}
try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
} catch {
    throw "Check-PayloadClassification: payload-manifest.json at '$manifestPath' could not be parsed ($($_.Exception.Message))."
}

function ConvertTo-RelPath {
    param([string]$Value)
    return ($Value -replace '\\', '/').TrimStart('/')
}

# ---- Collect the two rulings. File-level entries drive the scope; directory entries never do. ----
$supportFiles = @()
$supportDirs  = @()
foreach ($key in @('task_directories', 'scripts', 'templates', 'guides')) {
    foreach ($p in @($manifest.support_exceptions.$key)) {
        if (-not $p) { continue }
        $rel = ConvertTo-RelPath -Value $p
        if ($rel.EndsWith('/')) { $supportDirs += $rel } else { $supportFiles += $rel }
    }
}
$substrateFiles = @()
foreach ($key in @('scripts', 'templates', 'guides')) {
    foreach ($p in @($manifest.substrate_residents.$key)) {
        if ($p) { $substrateFiles += (ConvertTo-RelPath -Value $p) }
    }
}

# Skills are folder-unit rulings on both lists, relative to the BLUEPRINT root (the manifest's own
# description states the skills block uses that base), so they are compared as folder names.
$supportSkills   = @(@($manifest.support_exceptions.skills)   | Where-Object { $_ } | ForEach-Object { (ConvertTo-RelPath -Value $_).TrimEnd('/') })
$substrateSkills = @(@($manifest.substrate_residents.skills) | Where-Object { $_ } | ForEach-Object { (ConvertTo-RelPath -Value $_).TrimEnd('/') })

# ---- Derive the mixed-class directories: the parent of every FILE-level support entry. ----
$mixedDirs = @($supportFiles | ForEach-Object { $_ -replace '/[^/]+$', '' } | Where-Object { $_ } | Sort-Object -Unique)

$findings = @()
$checked = 0
$skipped = 0

foreach ($relDir in $mixedDirs) {
    $absDir = Join-Path -Path $producer -ChildPath ($relDir -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $absDir -PathType Container)) { continue }
    foreach ($file in Get-ChildItem -LiteralPath $absDir -File) {
        $rel = "$relDir/$($file.Name)"
        if ($file.Extension -eq '.pyc') { $skipped++; continue }

        if (-not $selfHosted) {
            # Framework face: only RECEIVED files carry a ruling obligation; the workspace's own
            # domain files are classified by ITS manifest, not this one.
            if (-not (Test-Path -LiteralPath (Join-Path -Path $consumer -ChildPath $rel) -PathType Leaf)) { $skipped++; continue }
        }

        $checked++
        if ($rel -in $supportFiles -or $rel -in $substrateFiles) { continue }
        # A directory-level support entry covering this path already classifies it by prefix.
        $coveredByDir = $false
        foreach ($d in $supportDirs) {
            if ($rel.StartsWith($d, [System.StringComparison]::OrdinalIgnoreCase)) { $coveredByDir = $true; break }
        }
        if ($coveredByDir) { continue }

        $findings += "{0} — UNRULED: sits in mixed-class directory '{1}' but is on neither support_exceptions nor substrate_residents. It ships as substrate by default; add it to whichever list states the intended class." -f $rel, $relDir
    }
}

# ---- The skills channel: folder units, blueprint-root relative. ----
$skillsDir = Join-Path -Path (Split-Path -Parent $producer) -ChildPath '.claude/skills'
if (Test-Path -LiteralPath $skillsDir -PathType Container) {
    foreach ($folder in Get-ChildItem -LiteralPath $skillsDir -Directory) {
        $rel = ".claude/skills/$($folder.Name)"
        if (-not $selfHosted) { $skipped++; continue }
        $checked++
        if ($rel -in $supportSkills -or $rel -in $substrateSkills) { continue }
        $findings += "{0}/ — UNRULED: a skill folder on neither support_exceptions.skills nor substrate_residents.skills. It ships to every project as substrate by default; add it to whichever list states the intended class." -f $rel
    }
}

Write-Host "Check-PayloadClassification: checked=$checked skipped=$skipped findings=$($findings.Count) (face: $(if ($selfHosted) { 'self-hosted authoring root' } else { 'framework face, received set' }), mixed-class dirs: $($mixedDirs.Count))"
if ($findings.Count -eq 0) {
    Write-Host "✅ Every file in a mixed-class payload directory carries a classification ruling."
    exit 0
}
foreach ($f in $findings) { Write-Warning $f }
if ($Blocking) {
    Write-Error "Check-PayloadClassification: $($findings.Count) file(s) in mixed-class directories carry no classification ruling (see warnings above). Add each to payload-manifest.json — support_exceptions if it is frameworks-only, substrate_residents if it is deliberately substrate."
    exit 1
}
exit 0
