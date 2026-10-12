<#
.SYNOPSIS
    Projects the received framework payload from a framework face's consumer tree into its
    producer blueprint (N-4 substrate sync), with -Check as the EOL-normalized hash drift gate
    that blocks a Push shipping a drifted copy (PF-PRO-068 Session E3).

.DESCRIPTION
    A framework face (declared role 'framework') receives the substrate + support payload from
    its parent into its CONSUMER tree (paths.process_framework) and re-ships those same bytes
    to its own children from its PRODUCER blueprint (paths.blueprint). This script owns the
    projection between the two faces:

      Default (sync)  Copy each received file whose blueprint copy is missing or differs into
                      the blueprint, byte-exact, under ShouldProcess. Additive only: it never
                      deletes a blueprint file (blueprint-only files are indistinguishable from
                      the framework's own domain class by path alone; retired-file reconciliation
                      is the cutover session's prune discipline, PF-PRO-068 Constraint 4).
                      TWO SAFETY GATES precede the overwrite (PF-IMP-2027):
                        (C) the blueprint must be COMMITTED — an overwrite of uncommitted work is
                            unrecoverable, and recovery here is git-anchored by design. Refuses.
                        (A) each DRIFTED file's blueprint content must match a version this
                            workspace previously RECEIVED (read from its own git history of the
                            consumer path, never the producer's repo — a child has neither). A
                            file matching no received version was authored HERE: it is left
                            untouched and reported, because overwriting it destroys the only copy.
                            This is the E4-i class — a level-authored file on no per-level list
                            presents as ordinary drift. Exits 1 when any file is refused.
      -Check          The drift gate: report every received file whose blueprint copy is missing
                      or differs (EOL-normalized comparison), write nothing, exit 1 on drift.
                      Push-FrameworkUpdate.ps1 runs this in preflight — a drifted producer copy
                      cannot ship (PF-PRO-068 N-4; the designed division of verification labor:
                      the canonical copy is tested at its owner, the received copy is hash-guarded).

    The RECEIVED SET is every file under the consumer framework tree except the manifest's
    per_level_files (authored per level, never shipped) and mirror hygiene exclusions
    (*.pyc, __pycache__, .git). The payload manifest is read from the CONSUMER face — it
    arrived with the payload and defines what the parent ships.

    Dormant states (exit 0, one loud line each — the no-silent-fallback invariant is satisfied
    by saying so, not by guessing):
      - Leaf workspace (role 'project'/absent): no producer face exists; nothing to sync.
      - Self-hosted (both keys name one tree — FB always; appdev until the Session F cutover):
        the faces are the same bytes by identity.
      - No payload manifest at the consumer face: this workspace has not yet received a
        payload-classified rollout (pre-first-rollout state).

    Comparison detail: text files are hashed after CRLF -> LF normalization (8 of ~165 twinned
    files legitimately disagree on line endings across repos with core.autocrlf=true and no
    .gitattributes — PF-PRO-068 Session 6 Issue 3; a naive byte hash would report 100% drift
    on them). A file containing a NUL byte is treated as binary and hashed raw.

.PARAMETER Check
    Drift-gate mode: report, never write. Exit 1 when any received file's blueprint copy is
    missing or drifted; exit 0 clean/dormant.

.PARAMETER ProjectRoot
    Workspace root override for test fixtures (defaults to the resolved project root).

.EXAMPLE
    Sync-Substrate.ps1 -Check
    # Drift gate (Push preflight / pre-commit form)

.EXAMPLE
    Sync-Substrate.ps1 -Confirm:$false
    # Project the received payload into the blueprint after receiving a rollout

.NOTES
    PF-PRO-068 S3 E3 (Session 16). Deliberately NOT soak-enrolled at creation: the sync mode is
    structurally dormant until the Session F cutover splits the faces — enrollment rides the
    cutover session, when real invocations exist to verify (same disposition as
    Commit-SandboxBaseline, Session 10).
OWNERSHIP: FWK-FB (FrameworkBuilder) - canonical at FrameworkBuilder; anywhere else a received copy. Edit only at the owning workspace. An agent may only modify files its workspace owns.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Check,

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

# Get-NormalizedFileHash comes from Core.psm1 via the Common-ScriptHelpers facade above — the
# drift gate and the rollout preview must answer "same content?" the same way, so the policy
# lives in one place (PF-IMP-2039). Do NOT restore a private copy here: PowerShell resolves a
# script-scope function ahead of a module export silently, so a local re-definition would shadow
# the shared one with no error and the two comparators would drift apart again unnoticed.

$root = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { Get-ProjectRoot } else { $ProjectRoot }
$configPath = Join-Path -Path $root -ChildPath "doc/project-config.json"
if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Sync-Substrate: no doc/project-config.json at '$root' — cannot resolve the workspace's faces."
}
try {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
} catch {
    throw "Sync-Substrate: doc/project-config.json at '$configPath' could not be parsed ($($_.Exception.Message))."
}

$role = if ($config.project_metadata -and $config.project_metadata.role) { $config.project_metadata.role } else { 'project' }
if ($role -eq 'project') {
    Write-Host "Sync-Substrate: leaf workspace (role 'project') — no producer face exists; nothing to sync. Exit 0."
    exit 0
}

$consumerRel = if ($config.paths -and $config.paths.process_framework) { $config.paths.process_framework } else { 'process-framework' }
$consumer = Join-Path -Path $root -ChildPath $consumerRel
$producer = Get-BlueprintPath -ProjectRoot $root   # throws on a producer face without the key (no-fallback contract)

$consumerFull = [System.IO.Path]::GetFullPath($consumer).TrimEnd('\', '/')
$producerFull = [System.IO.Path]::GetFullPath($producer).TrimEnd('\', '/')
if ($consumerFull -ieq $producerFull) {
    Write-Host "Sync-Substrate: self-hosted — paths.process_framework and paths.blueprint name the same tree ($consumerFull). The faces are identical by identity; nothing to sync. Exit 0."
    exit 0
}

if (-not (Test-Path -LiteralPath $consumerFull)) {
    throw "Sync-Substrate: the consumer face '$consumerFull' does not exist — the faces are split in config but no received tree is present. A rollout should have materialized it; investigate before syncing."
}

$manifestPath = Join-Path -Path $consumerFull -ChildPath "payload-manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Write-Host "Sync-Substrate: no payload-manifest.json at the consumer face ($manifestPath) — this workspace has not received a payload-classified rollout yet. Gate dormant. Exit 0."
    exit 0
}
try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
} catch {
    throw "Sync-Substrate: payload-manifest.json at '$manifestPath' could not be parsed ($($_.Exception.Message)). A corrupt manifest cannot be told apart from a wrong one — repair it; guessing the received set could sync the wrong class."
}

# BOTH per-level blocks are excluded from the sync: per_level_files (all target roles) and
# framework_level_files (the catalogs and registry a framework face generates from its OWN tree —
# split out of the flat list at PF-PRO-068 S3 E4-b). Reading only the first would project the
# producer's ai-tasks.md, ID registry and catalogs over the consumer's own, which is precisely the
# overwrite the per-level classification exists to prevent.
$perLevel = @()
if ($manifest.per_level_files -and $manifest.per_level_files.paths) {
    $perLevel += @($manifest.per_level_files.paths)
}
if ($manifest.framework_level_files -and $manifest.framework_level_files.paths) {
    $perLevel += @($manifest.framework_level_files.paths)
}

# THE SUPPORT CLASS IS EXCLUDED TOO (PF-IMP-1998, PF-PRO-068 Session F).
# This projection targets a PRODUCER BLUEPRINT — the tree its workspace SHIPS — and the two sets
# are not the same. A framework face RECEIVES substrate + support; it SHIPS substrate + its own
# domain content, because support is the frameworks-only payload and its children are projects.
# Projecting the received set wholesale therefore restores exactly the support-class members the
# cutover pruned from the blueprint (Constraint 4) and re-ships framework-development tooling to
# every project at the next rollout. Measured at the cutover: 58 of 163 received files were the
# pruned support set, and the "obvious" fix for a red gate — run the sync — was the one action
# that silently undid the cutover.
#
# Scope note for a deeper portfolio: this is right while a framework's children are all projects.
# A framework that ever parents another FRAMEWORK must pass support along, and this exclusion
# would need to key off the child roles in its registry rather than being unconditional.
$supportPaths = @()
if ($manifest.support_exceptions) {
    foreach ($key in @('task_directories', 'scripts', 'templates', 'guides')) {
        if ($manifest.support_exceptions.$key) { $supportPaths += @($manifest.support_exceptions.$key) }
    }
}
$supportPaths = @($supportPaths | ForEach-Object { $_.TrimEnd('/') } | Where-Object { $_ })

function Test-IsSupportPath {
    param([string]$Rel)
    foreach ($s in $supportPaths) {
        if ($Rel -eq $s) { return $true }                       # exact file entry
        if ($Rel.StartsWith($s + '/', [System.StringComparison]::OrdinalIgnoreCase)) { return $true }  # directory entry
    }
    return $false
}

# Enumerate the received set: everything under the consumer face minus per-level files, the
# support class, and mirror hygiene exclusions.
$received = @(Get-ChildItem -LiteralPath $consumerFull -Recurse -File | Where-Object {
        $rel = $_.FullName.Substring($consumerFull.Length).TrimStart('\', '/').Replace('\', '/')
        ($rel -notin $perLevel) -and
        (-not (Test-IsSupportPath -Rel $rel)) -and
        ($rel -notmatch '(^|/)__pycache__/') -and
        ($rel -notmatch '(^|/)\.git/') -and
        ($_.Extension -ne '.pyc')
    })

$missing = @()
$drifted = @()
$clean = 0
foreach ($file in $received) {
    $rel = $file.FullName.Substring($consumerFull.Length).TrimStart('\', '/').Replace('\', '/')
    $blueprintCopy = Join-Path -Path $producerFull -ChildPath $rel
    if (-not (Test-Path -LiteralPath $blueprintCopy)) {
        $missing += $rel
    } elseif ((Get-NormalizedFileHash -Path $file.FullName) -ne (Get-NormalizedFileHash -Path $blueprintCopy)) {
        $drifted += $rel
    } else {
        $clean++
    }
}

if ($Check) {
    Write-Host "Sync-Substrate -Check: received=$($received.Count) clean=$clean missing=$($missing.Count) drifted=$($drifted.Count)"
    if ($missing.Count -eq 0 -and $drifted.Count -eq 0) {
        Write-Host "✅ Producer blueprint matches the received payload (EOL-normalized)."
        exit 0
    }
    foreach ($rel in $missing) { Write-Warning "MISSING from blueprint: $rel" }
    foreach ($rel in $drifted) { Write-Warning "DRIFTED in blueprint: $rel" }
    Write-Error "Sync-Substrate -Check: the producer blueprint has diverged from the received payload ($($missing.Count) missing, $($drifted.Count) drifted). A drifted copy must not ship — run Sync-Substrate.ps1 to re-project. Since PF-IMP-2027 that is safe by construction: sync refuses to run against an uncommitted blueprint, and leaves untouched any file whose content matches no version this workspace has received (a level-authored file on no per-level list looks exactly like drift). Anything it declines to project is named, and needs a classification decision or a revert — received files are parent-owned; an agent may only modify files its workspace owns."
    exit 1
}

# ---------------------------------------------------------------------------------------------
# Sync mode: additive projection consumer -> blueprint (byte-exact copies).
#
# TWO SAFETY GATES STAND IN FRONT OF THE OVERWRITE (PF-IMP-2027 direction 2). Before them, sync
# projected every drifted file with Copy-Item -Force. That is correct for the COMMON case (the
# blueprint is stale after a rollout and must adopt the received bytes) and destructive for the
# rare one: a file that is LEVEL-AUTHORED in fact but classified as substrate — because it is on
# no per-level list — presents as ordinary drift and is silently replaced. That is the E4-i
# incident class; it was caught by hand twice, and the -Check error text actively prescribes the
# destructive action ("run Sync-Substrate.ps1 to re-project").
#
# The manifest's documented "a forgotten file fails safe" guarantee holds on the SUPPORT axis
# (an over-shipped file is edit-refused clutter) but NOT on the per-level axis, where the same
# omission costs data. These gates close that asymmetry by fixing the default rather than by
# adding an opt-out.
# ---------------------------------------------------------------------------------------------

function Invoke-GitHere {
    # Run git in the workspace root; return @{ Ok; Out }. Never throws — a workspace without git
    # is a legitimate state the caller degrades on explicitly (no silent fallback).
    param([string[]]$GitArgs)
    try {
        $out = & git -C $root @GitArgs 2>&1
        return @{ Ok = ($LASTEXITCODE -eq 0); Out = @($out) }
    } catch {
        return @{ Ok = $false; Out = @($_.Exception.Message) }
    }
}

$inGitRepo = (Invoke-GitHere -GitArgs @('rev-parse', '--is-inside-work-tree')).Ok

# ---- GATE C: the destination must be committed, so every overwrite is git-recoverable. --------
# Recovery in this portfolio is git-anchored by design (PF-PRO-067 Question D). An overwrite of an
# UNCOMMITTED blueprint file is unrecoverable by any means, so it is refused rather than warned
# about. A dirty CONSUMER face is a different problem — it means the provenance history Gate A
# reads may be incomplete (a receive that was never committed leaves no version to match) — so it
# degrades Gate A to "cannot verify" rather than blocking the run. Measured 2026-08-30: appdev
# commits its receives (8 versions in history), the legal face does not (28 files dirty, 1 commit),
# so both states are live in the portfolio today.
if (-not $inGitRepo) {
    throw "Sync-Substrate: '$root' is not a git working tree, so an overwrite here could not be undone and a file's received-version history cannot be read. Sync refuses rather than projecting unrecoverably. Use -Check to inspect the drift."
}
$dirtyBlueprint = @((Invoke-GitHere -GitArgs @('status', '--porcelain', '--', $producerFull)).Out | Where-Object { $_ })
if ($dirtyBlueprint.Count -gt 0) {
    foreach ($line in ($dirtyBlueprint | Select-Object -First 20)) { Write-Warning "UNCOMMITTED in blueprint: $line" }
    throw "Sync-Substrate: the producer blueprint has $($dirtyBlueprint.Count) uncommitted change(s) (listed above, first 20). Projecting now would overwrite work that git could not restore. Commit or review the blueprint first, then re-run."
}
$dirtyConsumer = @((Invoke-GitHere -GitArgs @('status', '--porcelain', '--', $consumerFull)).Out | Where-Object { $_ })
if ($dirtyConsumer.Count -gt 0) {
    Write-Warning "The consumer face has $($dirtyConsumer.Count) uncommitted change(s) — an uncommitted receive leaves no committed version for the provenance check to match, so some files below may report UNVERIFIED purely for that reason. Committing the received payload first makes the check exact."
}

function Test-BlueprintIsPriorReceive {
    # GATE A, per file: is the blueprint's CURRENT content a version this workspace has previously
    # RECEIVED at the consumer path? If yes, the blueprint is merely stale and adopting the new
    # bytes loses nothing. If it matches no received version, the content was authored HERE — the
    # level-authorship candidate — and overwriting it destroys the only copy.
    #
    # Provenance is read from THIS workspace's own git history of the consumer path. It must NOT
    # depend on the producer's repository: a child generally does not have FB's tags, or FB's repo
    # at all. (Verified 2026-08-30 at the legal face: its own history identified its blueprint copy
    # as the first-receive version.)
    #
    # Compared through Get-NormalizedFileHash on a temp file rather than on piped text: routing a
    # git blob through a PowerShell text pipeline (Out-String) normalizes trailing newlines and
    # silently reports two IDENTICAL files as different — measured during this change, where it
    # produced 2 false level-authorship candidates out of 16.
    param([string]$Rel, [string]$BlueprintPath)

    $bpHash = Get-NormalizedFileHash -Path $BlueprintPath
    $consumerRelForGit = (Join-Path -Path $consumerRel -ChildPath $Rel) -replace '\\', '/'

    $log = Invoke-GitHere -GitArgs @('log', '--all', '--format=%H', '--', $consumerRelForGit)
    if (-not $log.Ok) { return @{ Verdict = 'Unverified'; Reason = 'git log failed for the consumer path' } }
    $commits = @($log.Out | Where-Object { $_ -match '^[0-9a-f]{40}$' })
    if ($commits.Count -eq 0) {
        return @{ Verdict = 'Unverified'; Reason = 'the consumer path has no committed history, so no received version exists to compare against' }
    }

    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        foreach ($sha in $commits) {
            $show = Invoke-GitHere -GitArgs @('show', "${sha}:$consumerRelForGit")
            if (-not $show.Ok) { continue }
            [System.IO.File]::WriteAllLines($tmp, @($show.Out))
            if ((Get-NormalizedFileHash -Path $tmp) -eq $bpHash) {
                return @{ Verdict = 'PriorReceive'; Reason = "matches the version received at $($sha.Substring(0,8))" }
            }
        }
    }
    finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
    return @{ Verdict = 'NoMatch'; Reason = "content matches none of the $($commits.Count) received version(s) of this path" }
}

$synced = 0
$refused = @()
foreach ($rel in ($missing + $drifted)) {
    $src = Join-Path -Path $consumerFull -ChildPath $rel
    $dst = Join-Path -Path $producerFull -ChildPath $rel

    # MISSING files have no blueprint copy, so there is nothing to destroy — they skip Gate A.
    if ($rel -in $drifted) {
        $prov = Test-BlueprintIsPriorReceive -Rel $rel -BlueprintPath $dst
        if ($prov.Verdict -ne 'PriorReceive') {
            $refused += "{0} — {1} ({2})" -f $rel, $(if ($prov.Verdict -eq 'NoMatch') { 'LEVEL-AUTHORED?' } else { 'UNVERIFIED' }), $prov.Reason
            continue
        }
    }

    if ($PSCmdlet.ShouldProcess($dst, "Project received file into blueprint (from $src)")) {
        $dstDir = Split-Path -Parent $dst
        if (-not (Test-Path -LiteralPath $dstDir)) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $src -Destination $dst -Force
        $synced++
    }
}

if ($refused.Count -gt 0) {
    foreach ($r in $refused) { Write-Warning "NOT PROJECTED: $r" }
    Write-Warning @"
$($refused.Count) file(s) were left untouched because their blueprint content matches no version this workspace has received. Each is one of two things, and they need opposite actions:
  (a) LEVEL-AUTHORED here — this workspace owns the content. Classify the path in payload-manifest.json (per_level_files, or framework_level_files for a catalog a producer face generates) so no rollout or sync ever overwrites it. Escalate to the manifest's owning workspace; a child cannot classify its own received tree.
  (b) An edit to a received file — received files are parent-owned. Revert it here and re-file the change as an IMP upstream.
Until each is dispositioned the drift gate stays red for these paths, which is the intended state: the blocked rollout is the symptom of an unmade classification decision, not of this script.
"@
}
Write-Host "Sync-Substrate: received=$($received.Count) clean=$clean projected=$synced refused=$($refused.Count) (missing $($missing.Count) + drifted $($drifted.Count))."
if ($refused.Count -gt 0) {
    # Non-zero exit: the run did NOT reach the state the caller asked for, and a preflight that
    # read this as success would ship a blueprint still diverged from the received payload.
    exit 1
}
exit 0
