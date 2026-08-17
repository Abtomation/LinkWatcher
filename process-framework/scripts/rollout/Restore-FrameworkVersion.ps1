<#
.SYNOPSIS
Mode D rollback (PF-TSK-088): revert a project's process-framework/ to a previous rollout version.

.DESCRIPTION
Operates from cwd = the producer workspace root (any producer face — PF-PRO-068 P-10
generalization; historically appdev-only). The child-registry shape (filename, collection key,
per-row version-pin field, accepted child roles) is derived from the workspace's declared role
via Get-ChildRegistryInfo: role 'framework' reads project-registry.json / projects; role
'framework-builder' reads framework-registry.json / frameworks. Performs:

1. Pre-flight: cwd is a producer workspace root; -Project exists in the child registry; the row
   is an eligible rollback target (not this workspace's own identity, not a row whose role this
   producer's restore does not serve, not version-frozen); target version determined and tag
   exists.
2. Captures the project's current .framework-version (becomes new .framework-version-previous).
3. Materializes the target version via `git worktree add` to a temporary directory at the corresponding
   rollout-<version> tag (does NOT touch the producer's main working tree).
4. Mirrors the temp worktree's framework source → <project>/process-framework/ using robocopy /MIR,
   through the SAME payload filter a rollout applies (PF-PRO-068 S3 E4-c, shared via
   PayloadFilter.psm1): the support class is staged out so it is not re-injected into a project
   tree, and per-level files the child authors reach /XF so the rollback leaves them alone.
   /XF also carries .framework-version-previous and both parent-pointer names
   (.framework-parent-pointer + legacy .framework-central-pointer). The source path is
   resolved from the TAG's own config through a three-rung fallback (paths.blueprint →
   paths.process_framework → literal process-framework), so tags cut on either side of the
   PF-PRO-068 Constraint 1 key split restore correctly. The MANIFEST is resolved separately, two
   rungs: the tag's own payload-manifest.json first, else the producer's live one (no tag cut
   before the cutover carries a manifest, so a tag-only read would leave every rollback that
   exists today unfiltered — the defect this step fixes, merely relocated in time).
5. Writes per-project .framework-version (target), .framework-version-previous (was-current), and
   refreshes the parent pointer — BOTH names with identical content during the pointer rename
   transition (PF-PRO-068 §6): the restored (older) framework code reads only the legacy name.
6. Removes the temporary worktree.
7. Updates the central child registry: the row's version pin (per-level field name via the
   P-10 shape — current_framework_version at appdev, current_substrate_version at FB) → target;
   last_rollout → now.
8. Appends a ROLLBACK entry to rollout-log.md.
9. Commits the central state changes (child registry + rollout-log.md) as a 'rollout-meta'
   commit and pushes to origin (warn-only on failure), so the rollback lands in version control
   when it happens rather than riding in a later commit.

> **🚨 Mode D scope is process-framework/ ONLY.** This script does NOT touch <project>/doc/ or
> <project>/test/. If recent Mode C migrations need to be reverted to keep working docs in sync
> with the rolled-back framework, the operator MUST do that manually via the project's own git
> history BEFORE running this script. See the pre-flight scan in PF-TSK-088 Mode D process steps.

.PARAMETER Project
Child ID of the registry row to roll back (PRJ-NNN at appdev; FWK-<MNEMONIC> at
FrameworkBuilder). Required. Three classes of row are refused:
- this workspace's own project_id (PF-PRO-068 Constraint 6 self-guard — a producer face is
  restored by its parent one level up, never by its own child-level rollback);
- rows whose role (absent = 'project', the leaf default) is not among the child roles this
  producer serves (PF-PRO-067 role guard, level-relative via the P-10 registry shape — such
  children are restored by THEIR parent's restore);
- rows with version_freeze: true (P-8 eligibility parity with Push — a freeze pins the
  version, and a rollback moves it).

.PARAMETER ToVersion
Optional explicit target version (YYYY-MM-DD-NNN). When omitted, uses the project's
.framework-version-previous as the rollback target.

.EXAMPLE
# Roll back to .framework-version-previous:
Restore-FrameworkVersion.ps1 -Project PRJ-002

.EXAMPLE
# Roll back to a specific older version:
Restore-FrameworkVersion.ps1 -Project PRJ-002 -ToVersion 2026-05-08-001

.NOTES
Per Centralized Framework Management proposal §3.4 (Rollback) and PF-TSK-088 Mode D. Created during
Phase 3 of the centralized-framework-management Framework Extension (2026-05-10).

Authored directly in appdev (not bootstrapped from TimeTrackingV2) — per Phase 4.5 manifest.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Project,

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}-\d{3}$')]
    [string]$ToVersion
)

$ErrorActionPreference = 'Stop'

# Payload classification comes from the sibling leaf module both rollout directions share
# (PF-PRO-068 S3 E4-c). Rollback used to be manifest-blind — it /MIR'd the tag's whole tree, which
# re-injected the support class into project children and overwrote their level-owned files (both
# measured at the E4-d edge-2 drill, against a not-rolled-back child as control). Importing the
# same module Push uses is what makes "a rollback cannot silently un-do what a rollout filtered"
# structural rather than a rule two scripts must remember separately.
#
# The CODE is always this producer's current module (like Core below); only the MANIFEST is
# resolved against the tag. Restoring old filter code would mean debugging whichever version the
# tag happened to carry.
$rolloutScriptDir    = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$payloadFilterModule = Join-Path -Path $rolloutScriptDir -ChildPath 'PayloadFilter.psm1'
try {
    Import-Module (Resolve-Path -Path $payloadFilterModule -ErrorAction Stop) -Force -ErrorAction Stop
}
catch {
    throw "Could not import the payload filter module expected beside this script at '$payloadFilterModule': $($_.Exception.Message). Refusing to roll back — without it the mirror is unfiltered, which re-injects the support class into the child."
}

#---------------------------------------------------------------------------------------
# Helpers (subset — same conventions as Push-FrameworkUpdate.ps1)
#---------------------------------------------------------------------------------------

function Get-ProducerRoot {
    # cwd-based detection, generalized for any producer face (PF-PRO-068 P-10). The old probe
    # authenticated the workspace by appdev's child-registry FILENAME, which made appdev the only
    # recognizable producer; the filename is now role-derived, so the probe anchors on what every
    # producer face has: its own config and its own central directory. The registry file itself is
    # checked later, by derived name, once the role is known.
    $cwd = (Get-Location).Path
    $configPath  = Join-Path -Path $cwd -ChildPath "doc/project-config.json"
    $centralPath = Join-Path -Path $cwd -ChildPath "process-framework-central"
    if (-not (Test-Path -Path $configPath)) {
        throw "cwd '$cwd' is not a producer workspace root (missing doc/project-config.json). Run this script from the root of the producer workspace whose child you are rolling back."
    }
    if (-not (Test-Path -Path $centralPath -PathType Container)) {
        throw "cwd '$cwd' has no process-framework-central/ directory — not a producer workspace root. Run this script from the producer workspace root."
    }
    return $cwd
}

function Get-CentralRoot {
    # Defense-in-depth override hook (Framework Self-Testing Phase 4 OP-NEW-E, 2026-05-20).
    # Mirrors the override pattern in Common-ScriptHelpers/Core.psm1::Get-CentralFrameworkPath
    # and IdRegistry.psm1::Resolve-CentralRegistryPath (Sessions 29/30). When
    # $env:FRAMEWORK_CENTRAL_OVERRIDE is set, central reads/writes (child registry,
    # rollout-log) go to the override path instead of <producer>/process-framework-central.
    # cwd validation in Get-ProducerRoot still requires a real cwd central dir — the
    # override only affects where this script reads/writes central state.
    param([string]$ProducerRoot)
    if ($env:FRAMEWORK_CENTRAL_OVERRIDE) {
        return $env:FRAMEWORK_CENTRAL_OVERRIDE
    }
    return (Join-Path -Path $ProducerRoot -ChildPath "process-framework-central")
}

function Get-FrameworkSourcePath {
    # Resolve the producer's OWN live framework tree — needed here only to import the shipped
    # Get-ChildRegistryInfo resolver (P-10), so each face reads its own copy and the registry
    # mapping travels with the substrate. Two rungs, newest key first (PF-PRO-068 Constraint 1;
    # same shape as Push's helper — the tag-side THREE-rung chain below is a separate resolution
    # against the tag's own config snapshot):
    #   1. paths.blueprint         — the producer-face key.
    #   2. paths.process_framework — dark-window / legacy fallback.
    param([string]$ProducerRoot)
    $configPath = Join-Path -Path $ProducerRoot -ChildPath "doc/project-config.json"
    if (-not (Test-Path -Path $configPath)) {
        throw "doc/project-config.json not found at '$configPath'. Cannot resolve the framework source path."
    }
    $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
    $relative = $null
    if ($config.paths -and $config.paths.blueprint) {
        $relative = $config.paths.blueprint
    }
    elseif ($config.paths -and $config.paths.process_framework) {
        $relative = $config.paths.process_framework
    }
    if (-not $relative) {
        throw "doc/project-config.json at '$configPath' declares neither paths.blueprint nor paths.process_framework. Set paths.blueprint to the producer-face tree (e.g., 'blueprint/process-framework')."
    }
    return @{
        Absolute = Join-Path -Path $ProducerRoot -ChildPath $relative
        Relative = $relative
    }
}

function Read-Json {
    param([string]$Path)
    return ,(Get-Content -Raw -Path $Path | ConvertFrom-Json -AsHashtable)
}

function Save-Json {
    param([string]$Path, [object]$Object)
    $json = $Object | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}

function Test-TagExists {
    param([string]$ProducerRoot, [string]$Tag)
    Push-Location $ProducerRoot
    try {
        $tags = git tag -l $Tag 2>$null
    }
    finally {
        Pop-Location
    }
    return ($tags -and ($tags -contains $Tag))
}

function Invoke-Mirror {
    # -PreserveRelativePaths carries the payload filter's PER-LEVEL set (framework-root-relative),
    # same contract as Push's mirror: under /MIR an excluded file is neither copied nor
    # orphan-deleted, which is exactly "leave the child's own copy alone".
    #
    # They are passed as FULL DESTINATION PATHS — robocopy's /XF matching was measured, not assumed
    # (PF-PRO-068 S3 E4-b): a bare name matches that name at EVERY depth (over-match), a relative
    # path matches NOTHING (silent no-op), and only a full destination path matches exactly one
    # file. The three legacy bare names below stay bare: each occurs only at the framework root.
    param(
        [string]$SourceDir,
        [string]$DestDir,
        [string[]]$PreserveRelativePaths = @()
    )
    if (-not (Test-Path -Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }

    $preserveArgs = @()
    foreach ($rel in $PreserveRelativePaths) {
        if (-not $rel) { continue }
        $native = $rel.TrimEnd('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        $preserveArgs += (Join-Path -Path $DestDir -ChildPath $native)
    }

    $rcArgs = @(
        $SourceDir,
        $DestDir,
        '/MIR',
        '/XF', '.framework-version-previous', '.framework-parent-pointer', '.framework-central-pointer'
    ) + $preserveArgs + @(
        '/XD', '.git',
        '/NJH', '/NJS', '/NDL', '/NP', '/NFL'
    )
    $output = & robocopy @rcArgs 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ge 8) {
        throw "robocopy failed (exit code $exitCode) when mirroring $SourceDir → $DestDir. Output:`n$($output -join `"`n`")"
    }
    return $exitCode
}

function Append-RolloutLog {
    param(
        [string]$LogPath,
        [string]$Version,
        [string]$ProjectId,
        [string]$ProjectName,
        [string]$FromVersion,
        [string]$Note
    )
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $entry = @"

## $timestamp — ROLLBACK — $ProjectId → $Version

- **Project**: $ProjectId ($ProjectName)
- **From version**: $(if ($FromVersion) { $FromVersion } else { '(none recorded)' })
- **To version**: $Version
- **Note**: $Note

"@
    [System.IO.File]::AppendAllText($LogPath, $entry, [System.Text.UTF8Encoding]::new($false))
}

#---------------------------------------------------------------------------------------
# Main
#---------------------------------------------------------------------------------------

# Step 1: producer-root detection
try {
    $producerRoot = Get-ProducerRoot
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}

$centralRoot  = Get-CentralRoot -ProducerRoot $producerRoot

# Step 1b: derive the child-registry shape from this workspace's declared role (PF-PRO-068 P-10).
# The resolver is the shipped Get-ChildRegistryInfo in the producer's OWN framework tree — each
# face imports its own copy, so the mapping travels with the substrate (same pattern as Push).
try {
    $source     = Get-FrameworkSourcePath -ProducerRoot $producerRoot
    $coreModule = Join-Path -Path $source.Absolute -ChildPath "scripts/Common-ScriptHelpers/Core.psm1"
    Import-Module $coreModule -Force -ErrorAction Stop
    $regInfo = Get-ChildRegistryInfo -ProjectRoot $producerRoot
}
catch {
    Write-Error "Could not derive the child-registry shape for this workspace: $($_.Exception.Message)"
    exit 1
}

$registryPath = Join-Path -Path $centralRoot -ChildPath $regInfo.FileName
if (-not (Test-Path -Path $registryPath)) {
    Write-Error "Child registry '$($regInfo.FileName)' (derived from role '$($regInfo.Role)') not found at '$registryPath'. Nothing to roll back."
    exit 1
}
$rolloutLog   = Join-Path -Path $centralRoot -ChildPath "rollouts/rollout-log.md"
$registry     = Read-Json -Path $registryPath
$children     = $registry[$regInfo.CollectionKey]
if ($null -eq $children) {
    Write-Error "Child registry '$($regInfo.FileName)' has no top-level '$($regInfo.CollectionKey)' collection (derived from role '$($regInfo.Role)'). The registry file and the workspace role disagree — repair one of them."
    exit 1
}

# Step 2: Validate -Project exists
if (-not $children.ContainsKey($Project)) {
    Write-Error "Project '$Project' not found in registry. Known IDs: $($children.Keys -join ', ')"
    exit 1
}
$projectEntry = $children[$Project]

# PF-PRO-068 Constraint 6 self-guard: never roll back the producer's own workspace.
# Today this is prevented only ACCIDENTALLY — appdev's framework lives at
# blueprint/process-framework, so the literal <root>/process-framework probe below finds
# nothing and the run dies with a misleading "not rolled out yet". The Session F cutover
# materializes exactly that directory, which silently converts the accident into a live
# hazard: Restore would mirror a tag's tree over the producer's own consumer face.
# The producer is restored one level up, by its parent's generalized restore
# (PF-PRO-067 Question D) — never by its own project-level rollback.
#
# P-13 closes this structurally too (the registry self-row is removed, so ContainsKey
# above refuses first), but the row still exists today and any future producer row would
# reopen the hole; this is the belt over that structural closure. It compares against the
# workspace's OWN declared project_id rather than a 'PRJ-000' literal, so it survives the
# P-13 identity switch (project_id -> FWK-APP) with no edit here.
$ownConfigPath = Join-Path -Path $producerRoot -ChildPath "doc/project-config.json"
$ownProjectId  = $null
if (Test-Path -Path $ownConfigPath) {
    try {
        $ownProjectId = (Get-Content -Raw -Path $ownConfigPath | ConvertFrom-Json).project_id
    } catch {
        # Warn rather than throw: an unreadable own-config is a broken workspace, but failing
        # hard here would also block legitimate rollbacks of unrelated projects. The refusal
        # this guard provides is a backstop, not the only one (ContainsKey + the role guard
        # below both still apply), so degrade loudly instead of taking the script down.
        Write-Warning "Could not read project_id from '$ownConfigPath' — the Constraint 6 self-guard could not be evaluated for this run."
    }
}
if ($ownProjectId -and $Project -eq $ownProjectId) {
    Write-Error "Refusing to roll back '$Project': it is this workspace's own identity (project_id in doc/project-config.json), and a producer face is never a target of its own project-level rollback. A producer is restored by its parent's generalized restore one level up (PF-PRO-068 Constraint 6 / PF-PRO-067 Question D); for a git-anchored local recovery, check out the desired rollout-<version> tag directly."
    exit 1
}

# PF-PRO-067 role guard, level-relative via the P-10 shape: this producer's restore serves
# only the child roles its own level fans out to (AcceptedChildRoles — 'project' at appdev,
# 'framework' at FB). A row of any other role is restored by ITS parent's restore one level
# up (PF-PRO-067 Question D). Hard-coding 'project' here was the P-8 inversion: at FB it
# would have refused every child the restore exists to serve. A row's absent role reads as
# 'project' (the leaf default, PF-PRO-067 Contract 4).
$rowRole = if ($projectEntry.role) { [string]$projectEntry.role } else { 'project' }
if ($regInfo.AcceptedChildRoles -notcontains $rowRole) {
    Write-Error "Registry row '$Project' has role '$rowRole' — not a row this producer's restore serves (accepted: $($regInfo.AcceptedChildRoles -join ', ')), so it is not a target of this rollback; such children are restored by their parent's generalized restore (Sub-concept 3, PF-PRO-067 role guard)."
    exit 1
}

# P-8 eligibility parity: a frozen project is pinned to its current framework version, and a
# rollback changes that version just as a push does — so freeze must refuse both. Push has
# honoured version_freeze since it shipped; Restore never checked it at all, which left the
# pin enforced on one side of the rollout pair only. The semantics differ by mode, not by
# intent: Push fans out and SKIPS frozen rows (warning when they were named explicitly),
# while Restore is always an explicit single target, so the only faithful rendering of "skip"
# is a refusal. Unfreeze the row deliberately if the pin is meant to be lifted.
if ($projectEntry.version_freeze -eq $true) {
    Write-Error "Refusing to roll back '$Project': the registry row is frozen (version_freeze: true), which pins it to its current framework version — a rollback would move it. Clear version_freeze in $($regInfo.FileName) first if the pin is genuinely meant to be lifted (PF-PRO-068 P-8 eligibility parity with Push)."
    exit 1
}

$projectRoot  = $projectEntry.path
$projectFw    = Join-Path -Path $projectRoot -ChildPath "process-framework"

if (-not (Test-Path -Path $projectFw -PathType Container)) {
    Write-Error "Project's process-framework/ directory does not exist at '$projectFw'. The project may not have been rolled out yet — nothing to roll back from."
    exit 1
}

# Step 3: Determine target version
$projectCurrentVerFile  = Join-Path -Path $projectFw -ChildPath ".framework-version"
$projectPreviousVerFile = Join-Path -Path $projectFw -ChildPath ".framework-version-previous"

$projectCurrentVersion = $null
if (Test-Path -Path $projectCurrentVerFile) {
    $projectCurrentVersion = (Get-Content -Raw -Path $projectCurrentVerFile).Trim()
}

if ($ToVersion) {
    $targetVersion = $ToVersion
}
else {
    if (-not (Test-Path -Path $projectPreviousVerFile)) {
        Write-Error "No -ToVersion specified and project has no .framework-version-previous (likely never rolled out, or only rolled out once). Specify -ToVersion explicitly."
        exit 1
    }
    $targetVersion = (Get-Content -Raw -Path $projectPreviousVerFile).Trim()
    if (-not $targetVersion) {
        Write-Error "Project's .framework-version-previous is empty. Specify -ToVersion explicitly."
        exit 1
    }
}

# Validate target version is well-formed
if ($targetVersion -notmatch '^\d{4}-\d{2}-\d{2}-\d{3}$') {
    Write-Error "Target version '$targetVersion' does not match YYYY-MM-DD-NNN format."
    exit 1
}

# Idempotency check
if ($projectCurrentVersion -and $projectCurrentVersion -eq $targetVersion) {
    Write-Host "Project $Project is already at version $targetVersion. Nothing to do."
    exit 0
}

# Step 4: Validate target tag exists in this producer's repo
$targetTag = "rollout-$targetVersion"
if (-not (Test-TagExists -ProducerRoot $producerRoot -Tag $targetTag)) {
    Write-Error "Tag '$targetTag' does not exist in this producer workspace's repo. Cannot roll back. Run 'git fetch --tags' if the tag may have been pushed by another machine, or check rollout-log.md for the correct version."
    exit 1
}

Write-Host ""
Write-Host "═══ Rollback — Pre-flight ═══"
Write-Host "  Project          : $Project ($($projectEntry.name))"
Write-Host "  Project root     : $projectRoot"
Write-Host "  Current version  : $(if ($projectCurrentVersion) { $projectCurrentVersion } else { '(none recorded)' })"
Write-Host "  Target version   : $targetVersion (tag: $targetTag)"
Write-Host "  Mode             : ROLLBACK (Mode D)"
Write-Host ""
Write-Warning "Mode D restores process-framework/ ONLY. If recent Mode C migrations modified <project>/doc/ or <project>/test/ AND were marked Backward-compatible: no, REVERT THOSE MANUALLY in the project's git BEFORE this rollback completes — otherwise the rolled-back framework will read schema-mismatched working docs."
Write-Host ""

if (-not $PSCmdlet.ShouldProcess(
    "$Project's process-framework/ (mirror) and central registry (current_framework_version, last_rollout)",
    "Roll back $Project to $targetVersion"
)) {
    exit 0
}

# Pre-flight: reclaim any .rollback-worktree-* left by a prior interrupted run (hard kill /
# closed terminal / crash) that the Step 8 finally never reached (PF-IMP-1147). A healthy run
# always removes its own worktree, so anything present here is an orphan from a crashed run.
# Runs after the ShouldProcess gate so -WhatIf performs no deletion; long-path-safe per PF-IMP-1277.
Push-Location $producerRoot
try {
    git worktree prune 2>&1 | Out-Null
    Get-ChildItem -Path $producerRoot -Directory -Force -Filter '.rollback-worktree-*' -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Warning "Pre-flight: reclaiming orphaned rollback worktree '$($_.Name)' from a prior interrupted run."
        git -c core.longpaths=true worktree remove --force $_.FullName 2>&1 | Out-Null
        if (Test-Path -Path $_.FullName) { Remove-Item -Recurse -Force -Path $_.FullName -ErrorAction SilentlyContinue }
    }
}
finally {
    Pop-Location
}

# Step 5: Materialize target version via temporary worktree
$worktreeDir = Join-Path -Path $producerRoot -ChildPath ".rollback-worktree-$([Guid]::NewGuid().ToString('N').Substring(0,8))"

Push-Location $producerRoot
try {
    # -c core.longpaths=true: the tag's full tree includes deep E2E synthetic-fixture paths that
    # exceed the Windows 260-char limit; without it `git worktree add` aborts with "Filename too
    # long" ("Could not reset index file to revision 'HEAD'") and Mode D rollback fails on Windows
    # (PF-IMP-1277). git defaults core.longpaths=false; this enables it for the checkout only.
    $output = git -c core.longpaths=true worktree add --detach $worktreeDir $targetTag 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git worktree add failed: $output"
    }
}
finally {
    Pop-Location
}

$mirrorStage = $null
try {
    # Resolve the framework source path AS IT EXISTED AT THE TARGET TAG. The
    # doc/project-config.json snapshot inside the worktree is the authoritative source for
    # which layout applied then — which is why this reads the tag's config, not today's.
    #
    # THREE rungs, newest layout first (PF-PRO-068 Constraint 1 key split, Session E2). What
    # a rollout shipped is always the PRODUCER face, so paths.blueprint wins where present:
    #   1. paths.blueprint        — tags cut after the Constraint 1 key split. Post-cutover
    #                               these two keys DIVERGE (process_framework flips to the
    #                               received consumer face while blueprint keeps naming what
    #                               was authored and shipped), so reading rung 2 there would
    #                               mirror the wrong tree back over the project.
    #   2. paths.process_framework — Phase-5.5-and-later tags, where the single key named the
    #                               producer face because the two faces were the same tree.
    #   3. literal 'process-framework' — pre-Phase-5.5 tags with no such config field.
    #
    # This is deliberately a fallback CHAIN and not a key swap: every rollout-* tag that
    # exists today predates paths.blueprint, so a swap would send all of them to rung 3 and
    # throw on the post-Phase-5.5 majority, breaking rollback for the entire live tag series.
    # Rung 1 therefore fires for no existing tag — the change is dark until the first tag cut
    # after the key split.
    $worktreeConfigPath = Join-Path -Path $worktreeDir -ChildPath "doc/project-config.json"
    $worktreeSourceRel  = "process-framework"  # rung 3
    $worktreeSourceRung = "legacy literal (no config field at this tag)"
    if (Test-Path -Path $worktreeConfigPath) {
        try {
            $worktreeConfig = Get-Content -Raw -Path $worktreeConfigPath | ConvertFrom-Json
            if ($worktreeConfig.paths -and $worktreeConfig.paths.blueprint) {
                $worktreeSourceRel  = $worktreeConfig.paths.blueprint          # rung 1
                $worktreeSourceRung = "paths.blueprint (producer face)"
            }
            elseif ($worktreeConfig.paths -and $worktreeConfig.paths.process_framework) {
                $worktreeSourceRel  = $worktreeConfig.paths.process_framework  # rung 2
                $worktreeSourceRung = "paths.process_framework (pre-key-split)"
            }
        } catch {
            Write-Warning "Could not parse worktree doc/project-config.json; falling back to legacy 'process-framework/' source path."
        }
    }
    Write-Verbose "Tag $targetTag framework source resolved to '$worktreeSourceRel/' via $worktreeSourceRung."
    $worktreeFw = Join-Path -Path $worktreeDir -ChildPath $worktreeSourceRel
    if (-not (Test-Path -Path $worktreeFw)) {
        throw "Tag $targetTag does not contain a framework source directory at '$worktreeSourceRel/' (resolved via $worktreeSourceRung). The tag may pre-date the framework structure, or paths.blueprint / paths.process_framework is misconfigured at the tag."
    }

    Write-Host "✅ Target version materialized at temporary worktree: $worktreeDir"

    # Step 5b: Resolve the payload manifest for this rollback (PF-PRO-068 S3 E4-c). TWO rungs,
    # and the order is deliberate:
    #   1. the TAG's own manifest — the classification as it stood when that version shipped,
    #      the same principle as resolving the source path from the tag's config above;
    #   2. the PRODUCER's live manifest — because no tag cut before the cutover carries a
    #      manifest at all (measured: 0 of appdev's 16 rollout-* tags), so a tag-only read would
    #      leave every rollback that exists today unfiltered. That is the defect this step exists
    #      to fix, merely moved from "always" to "for every current tag".
    # Neither present => unfiltered, LOUDLY (same rendering as Push's absent-manifest warning).
    # A live manifest against an old tree can only UNDER-filter: entries naming paths the tag did
    # not have match nothing and are recorded as Missing by the stage builder. Where it does
    # remove something the tag classified as substrate, that is today's classification being
    # enforced — which is the state the child is supposed to end in.
    $restoreManifest = Get-PayloadManifest -SourceDir $worktreeFw
    $manifestRung    = "tag $targetTag"
    if ($null -eq $restoreManifest) {
        $restoreManifest = Get-PayloadManifest -SourceDir $source.Absolute
        $manifestRung    = "producer live tree ($($source.Relative)) — the tag carries no manifest"
    }

    $mirrorSource   = $worktreeFw
    $mirrorPreserve = @()
    if ($null -eq $restoreManifest) {
        Write-Warning "No payload-manifest.json at tag $targetTag or in the producer's live framework tree — restoring the FULL framework tree to $Project, unfiltered. Expected before the FB→appdev cutover; after it, this means the support set is being re-injected into a child tree."
    }
    else {
        $targetProfile = Get-TargetPayloadProfile -Entry $projectEntry
        $excl          = Get-PayloadExclusionSet -Manifest $restoreManifest `
                                                 -TargetRole $targetProfile.Role `
                                                 -DeclinedParts $targetProfile.DeclinedParts
        # Both classes leave the staged tree; only the per-level class additionally reaches /XF so
        # /MIR preserves the child's own copy instead of orphan-deleting it.
        $mirrorStage    = Build-PayloadStage -SourceDir $worktreeFw `
                                             -ExclusionPaths (@($excl.RemovePaths) + @($excl.PreservePaths))
        $mirrorSource   = $mirrorStage.Path
        $mirrorPreserve = @($excl.PreservePaths)
        Write-Host "   payload filter: role=$($targetProfile.Role) removed=$($excl.RemovePaths.Count) preserved=$($mirrorPreserve.Count) absent-at-this-tag=$($mirrorStage.Missing.Count) [manifest: $manifestRung]"
    }

    # Step 6: Mirror worktree → project (filtered payload; per-level files preserved via /XF)
    Invoke-Mirror -SourceDir $mirrorSource -DestDir $projectFw -PreserveRelativePaths $mirrorPreserve | Out-Null
    Write-Host "✅ Mirrored $worktreeSourceRel/ from tag $targetTag → $projectFw"

    # Step 7: Per-project file writes
    [System.IO.File]::WriteAllText($projectCurrentVerFile, $targetVersion + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
    if ($projectCurrentVersion) {
        [System.IO.File]::WriteAllText($projectPreviousVerFile, $projectCurrentVersion + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
    }
    # Refresh the parent pointer — BOTH names with identical content during the
    # .framework-central-pointer → .framework-parent-pointer rename transition (PF-PRO-068 §6).
    # The restored (older) framework code reads only the legacy name; current readers read both
    # and throw on disagreement, which the identical-content write rules out.
    foreach ($pointerName in @('.framework-parent-pointer', '.framework-central-pointer')) {
        $pointerFile = Join-Path -Path $projectFw -ChildPath $pointerName
        [System.IO.File]::WriteAllText($pointerFile, $producerRoot + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
    }
    Write-Host "✅ Project version stamps updated: .framework-version=$targetVersion, .framework-version-previous=$projectCurrentVersion"
}
finally {
    # Step 8: Always remove the filtered payload stage and the temporary worktree
    if ($mirrorStage -and (Test-Path -LiteralPath $mirrorStage.Path)) {
        Remove-Item -LiteralPath $mirrorStage.Path -Recurse -Force -ErrorAction SilentlyContinue
    }
    Push-Location $producerRoot
    try {
        # -c core.longpaths=true so the long-path files materialized above can also be removed (PF-IMP-1277).
        git -c core.longpaths=true worktree remove --force $worktreeDir 2>&1 | Out-Null
        if (Test-Path -Path $worktreeDir) {
            # Fallback: manual cleanup
            Remove-Item -Recurse -Force -Path $worktreeDir -ErrorAction SilentlyContinue
        }
    }
    finally {
        Pop-Location
    }
}

# Step 9: Update central registry — the row's version pin, by its per-level field name
# (P-10: current_framework_version at appdev, current_substrate_version at FB; the names
# deliberately differ per level and are carried as data, never converged by code).
$children[$Project][$regInfo.PinField] = $targetVersion
$children[$Project].last_rollout = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
$registry.metadata.updated = (Get-Date -Format "yyyy-MM-dd")
Save-Json -Path $registryPath -Object $registry
Write-Host "✅ Central registry updated"

# Step 10: Append ROLLBACK entry to rollout-log.md
Append-RolloutLog -LogPath $rolloutLog -Version $targetVersion -ProjectId $Project -ProjectName $projectEntry.name -FromVersion $projectCurrentVersion -Note "Rollback executed via Restore-FrameworkVersion.ps1. Forward-fix path is the operator's responsibility."

# Step 11: Commit central rollback state (child registry + rollout-log.md) as a 'rollout-meta'
# commit so the rollback lands in version control when it happens (PF-IMP-1086 / PF-EVR-025 X-2).
# Best-effort: a commit/push hiccup must not turn a successful rollback into a failure. Skipped when
# central state is redirected (FRAMEWORK_CENTRAL_OVERRIDE in tests/sandboxes) — detected EXPLICITLY
# from the override variable, not inferred from path prefixes: a prefix test silently takes the
# commit path for an override pointing inside the workspace tree, and silently flips if central
# ever relocates (same defect Push's gate fixed at Session 9; parity applied here).
if (-not $env:FRAMEWORK_CENTRAL_OVERRIDE) {
    Push-Location $producerRoot
    try {
        $registryRel   = ([System.IO.Path]::GetRelativePath($producerRoot, $registryPath)) -replace '\\', '/'
        $rolloutLogRel = ([System.IO.Path]::GetRelativePath($producerRoot, $rolloutLog)) -replace '\\', '/'
        $centralChanges = git status --porcelain -- $registryRel $rolloutLogRel 2>$null
        if ($centralChanges) {
            try {
                # Pathspec form commits ONLY these two files — central holds many other dirty files.
                git commit -m "rollout-meta: rollback $Project to $targetVersion" -- $registryRel $rolloutLogRel 2>&1 | Out-Null
                Write-Host "✅ Committed central rollback state (rollout-meta: rollback $Project to $targetVersion)"
                $originUrl = git remote get-url origin 2>$null
                if ($originUrl) {
                    git push origin main 2>&1 | Out-Null
                    Write-Host "✅ Pushed rollout-meta commit to origin"
                }
            }
            catch {
                Write-Warning "Central rollback-state commit/push did not complete: $($_.Exception.Message). The rollback itself succeeded; commit $($regInfo.FileName) + rollout-log.md manually."
            }
        }
        else {
            Write-Verbose "No central rollback-state changes to commit."
        }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Warning "Central state is redirected (FRAMEWORK_CENTRAL_OVERRIDE active); skipping rollout-meta commit. If this is a REAL rollback, the registry + rollout-log changes at the override location are NOT under version control here — commit them where they live."
}

Write-Host ""
Write-Host "═══ Rollback Complete ═══"
Write-Host "  $Project rolled back from $(if ($projectCurrentVersion) { $projectCurrentVersion } else { '(unrecorded)' }) → $targetVersion"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Verify the original failure mode is no longer reproduced in $Project."
Write-Host "  2. Identify and apply the forward-fix in this producer's framework source (doc/project-config.json paths.blueprint, falling back to paths.process_framework)."
Write-Host "  3. Run Push-FrameworkUpdate.ps1 -Project $Project to re-deploy the fixed version."
exit 0
