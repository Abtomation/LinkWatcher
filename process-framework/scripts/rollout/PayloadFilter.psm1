<#
.SYNOPSIS
Shared payload-classification helpers for the rollout scripts — manifest read, per-edge exclusion
sets, and the filtered staging tree.

.DESCRIPTION
The single implementation of "what does NOT ship on this edge", consumed by BOTH rollout
directions: Push-FrameworkUpdate.ps1 (Mode B fan-out) and Restore-FrameworkVersion.ps1 (Mode D
rollback). Extracted here at PF-PRO-068 S3 E4-c, applying the E4-g rule (PF-EVR-036 F8): where two
scripts need the same logic, extract to a leaf module rather than copy — a copy made *knowing* both
halves must stay in lockstep is exactly the divergence E4-b measured (three hard-coded copies of one
exclusion list, disagreeing).

Restore was manifest-blind until E4-c: its /MIR restored the tag's whole tree, re-injecting the
support class into project children and overwriting their level-owned files (both measured at the
E4-d edge-2 drill, with a not-rolled-back child as the control). Both scripts now compute their
exclusion sets here, so a rollback cannot silently un-do what a rollout filtered.

LEAF MODULE BY CONTRACT: this file imports nothing. It is dot-sourced by sibling scripts in
scripts/rollout/ only, and its functions are pure but for the filesystem reads they name. Adding an
import here would couple the rollout machinery to the resolution stack it deliberately sits beside;
if one is ever needed, the caller passes the value in.

SUPPORT CLASS: listed in payload-manifest.json support_exceptions.scripts, so this module reaches
framework-role children only. That listing is load-bearing — the scripts list is file-level, so an
unlisted file under scripts/rollout/ would ship to every project as substrate.

.NOTES
Created at PF-PRO-068 Sub-concept 3, Session E4-c (2026-08-12), by moving five functions out of
Push-FrameworkUpdate.ps1 unchanged. The behaviour is Push's, verbatim; only the home is new.
#>

function Get-PayloadManifest {
    # Read the payload manifest from the framework tree being shipped (PF-PRO-068 Contract 4).
    # ABSENT returns $null — the pre-cutover state at appdev, where the manifest is authored at FB
    # and arrives only with the first FB->appdev rollout. Callers must render $null as "ship the
    # whole tree, LOUDLY", never as "ship nothing".
    # CORRUPT throws: an unparsable manifest is indistinguishable from an absent one to a silent
    # reader, and guessing ships the support set to a project.
    param([Parameter(Mandatory = $true)][string]$SourceDir)

    $manifestPath = Join-Path -Path $SourceDir -ChildPath 'payload-manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) { return $null }
    try {
        return (Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json)
    }
    catch {
        throw "payload-manifest.json at '$manifestPath' exists but could not be parsed ($($_.Exception.Message)). Refusing to roll out — an unreadable manifest must not degrade to an unfiltered payload."
    }
}

function Get-PayloadExclusionSet {
    # THE single source of truth for "what does NOT ship on this edge". The dry-run diff, the real
    # mirror and the Mode D rollback all consume this one function, so -Check cannot disagree with
    # what a rollout does, and a rollback cannot disagree with either.
    #
    # TWO SETS WITH OPPOSITE MIRROR SEMANTICS (PF-PRO-068 S3 E4-b). Both are held out of the staged
    # payload, but what must happen to the CHILD'S existing copy differs, and conflating them was
    # the E4-b defect:
    #   RemovePaths   — support class + declined parts. The child must LOSE these. Stripping them
    #                   from the stage is sufficient: /MIR then orphan-deletes them at the
    #                   destination, which is exactly the concept's "a post-cutover rollout removes
    #                   the support task files" criterion.
    #   PreservePaths — per-level files. The child must KEEP its own copy. Stripping alone DELETES
    #                   it (measured at the E4 drill: a child's own PF-id-registry.json,
    #                   domain-config.json and ai-tasks.md, seeded with content existing nowhere in
    #                   the producer, were destroyed by a second rollout). These must ALSO reach the
    #                   mirror's /XF so /MIR leaves them alone.
    # Which per-level paths apply depends on the TARGET'S ROLE: a framework face authors its own
    # catalogs and registry, a project authors none of it and must keep receiving them
    # (manifest framework_level_files.applies_to_target_roles; owner decision 2026-08-12).
    #
    # SkillFolders is relative to the BLUEPRINT root — the manifest's own description states the
    # skills block uses a different base, and skills are mirrored by Invoke-SkillsMirror, not by the
    # framework mirror. Entries ending in '/' are directory prefixes; everything else is an exact
    # file path.
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Manifest,
        [Parameter(Mandatory = $true)]
        [ValidateSet('framework-builder', 'framework', 'project', 'subject')]
        [string]$TargetRole,
        [string[]]$DeclinedParts = @()
    )

    if ($null -eq $Manifest) {
        return [pscustomobject]@{
            Filtering = $false; RemovePaths = @(); PreservePaths = @(); SkillFolders = @(); Reasons = @{}
        }
    }

    $removeReasons   = @{}
    $preserveReasons = @{}
    $skillReasons    = @{}

    # (1a) Per-level files that apply at EVERY target role — written per child by the rollout, or
    # genuinely authored at the consumer (domain-config).
    foreach ($p in @($Manifest.per_level_files.paths)) {
        if ($p) { $preserveReasons[(($p -replace '\\', '/').TrimStart('/'))] = 'per-level' }
    }

    # (1b) Per-level files that apply ONLY where the target authors them itself. Absent block or
    # absent role list reads as "applies to no role" — a project must keep receiving these, so the
    # safe degradation is to ship them, never to delete a catalog on a guess.
    $fwLevelRoles = @($Manifest.framework_level_files.applies_to_target_roles)
    if ($fwLevelRoles -contains $TargetRole) {
        foreach ($p in @($Manifest.framework_level_files.paths)) {
            if ($p) { $preserveReasons[(($p -replace '\\', '/').TrimStart('/'))] = 'per-level:framework' }
        }
    }

    # (2) Support class — role-filtered: reaches only children whose declared role is framework or
    # framework-builder; a project tree never receives these paths.
    if ($TargetRole -notin @('framework', 'framework-builder')) {
        foreach ($key in @('task_directories', 'scripts', 'templates', 'guides')) {
            foreach ($p in @($Manifest.support_exceptions.$key)) {
                if ($p) { $removeReasons[(($p -replace '\\', '/').TrimStart('/'))] = "support:$key" }
            }
        }
        foreach ($p in @($Manifest.support_exceptions.skills)) {
            if ($p) { $skillReasons[(($p -replace '\\', '/').TrimStart('/'))] = 'support:skills' }
        }
    }

    # (3) Optional parts this consumer declined (consumption_profile.declined_parts). A typo here
    # would otherwise silently ship a part the consumer declined, so an unknown name throws.
    foreach ($part in @($DeclinedParts)) {
        if (-not $part) { continue }
        $def = $Manifest.optional_parts.$part
        if (-not $def) {
            $known = @($Manifest.optional_parts.PSObject.Properties |
                       Where-Object { $_.Name -ne 'description' } | ForEach-Object { $_.Name })
            throw "consumption_profile.declined_parts names '$part', which is not an optional part in the payload manifest. Known parts: $($known -join ', ')."
        }
        foreach ($p in @($def.paths)) {
            if ($p) { $removeReasons[(($p -replace '\\', '/').TrimStart('/'))] = "declined:$part" }
        }
    }

    # A path declared in both classes would be ambiguous at the mirror (delete or keep?). Refuse
    # rather than pick: the manifest is the contract and a contradiction in it is an authoring bug.
    $conflict = @($removeReasons.Keys | Where-Object { $preserveReasons.ContainsKey($_) })
    if ($conflict.Count -gt 0) {
        throw "payload-manifest.json declares these paths BOTH as remove-class and per-level: $($conflict -join ', '). One says delete the child's copy, the other says keep it. Fix the manifest."
    }

    $allReasons = @{}
    foreach ($k in $removeReasons.Keys)   { $allReasons[$k] = $removeReasons[$k] }
    foreach ($k in $preserveReasons.Keys) { $allReasons[$k] = $preserveReasons[$k] }
    foreach ($k in $skillReasons.Keys)    { $allReasons[$k] = $skillReasons[$k] }

    return [pscustomobject]@{
        Filtering     = $true
        RemovePaths   = @($removeReasons.Keys   | Sort-Object)
        PreservePaths = @($preserveReasons.Keys | Sort-Object)
        SkillFolders  = @($skillReasons.Keys    | Sort-Object)
        Reasons       = $allReasons
    }
}

function Test-PayloadPathExcluded {
    # Is a '/'-normalized, framework-root-relative path excluded? Exact match, or contained by a
    # directory entry (trailing '/'). Case-insensitive: the payload targets Windows filesystems.
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [string[]]$ExclusionPaths = @()
    )
    $rel = ($RelativePath -replace '\\', '/').TrimStart('/')
    foreach ($ex in $ExclusionPaths) {
        if ($ex.EndsWith('/')) {
            if ($rel.StartsWith($ex, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
        }
        elseif ($rel.Equals($ex, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function Build-PayloadStage {
    # Materialize the filtered payload in a temp tree, so the caller can /MIR from it.
    #
    # Why staging rather than robocopy /XF on the real mirror: /XF PRESERVES an existing copy at the
    # destination (that is exactly why the per-project files in Invoke-Mirror use it). The support
    # set is already on disk at every registered project, so an /XF-based filter would stop
    # refreshing those files and leave each project holding a frozen, unmaintained copy forever —
    # while looking like it worked. /MIR from a filtered source deletes them instead, which is what
    # the concept's "post-cutover rollout removes support task files" criterion requires, using
    # orphan-removal machinery that is already trusted rather than hand-rolled deletion.
    #
    # Returns @{ Path = <staging dir>; Removed = @(...); Missing = @(...) }.
    #
    # Missing = manifest entries that matched nothing in THIS tree. Do NOT wire this to a warning:
    # a manifest entry legitimately absent at a given level is normal — e.g. the per-level
    # `.framework-version(+previous)` files Session B deliberately did not seed at FB (its version
    # series starts at its first rollout). A warning here would fire on every run and train the
    # reader to ignore it. Surface
    # it under -Verbose; genuine manifest/tree drift is the job of the level-aware drift gate (E3),
    # which can tell "not here yet" from "moved and nobody updated the manifest".
    #
    # On the Mode D rollback path the SourceDir is a tag worktree, so Missing is routinely larger:
    # a manifest entry naming a file that did not exist at that tag matches nothing. That is the
    # designed degradation (under-filter, never over-delete), and the reason Missing stays quiet.
    param(
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [string[]]$ExclusionPaths = @()
    )

    $stage = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("pf-payload-" + [System.Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage -Force | Out-Null

    $rcArgs = @($SourceDir, $stage, '/E', '/XF', '*.pyc', '/XD', '.git', '__pycache__',
                '/NJH', '/NJS', '/NDL', '/NP', '/NFL')
    $output = & robocopy @rcArgs 2>&1
    if ($LASTEXITCODE -ge 8) {
        Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
        throw "robocopy failed (exit code $LASTEXITCODE) staging the payload from $SourceDir. Output:`n$($output -join "`n")"
    }

    $removed = @()
    $missing = @()
    foreach ($ex in $ExclusionPaths) {
        $relNative = $ex.TrimEnd('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        $target = Join-Path -Path $stage -ChildPath $relNative
        if (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Recurse -Force
            $removed += $ex
        }
        else {
            $missing += $ex
        }
    }

    return @{ Path = $stage; Removed = $removed; Missing = $missing }
}

function Get-TargetPayloadProfile {
    # A rollout target's payload profile: its declared role (ABSENT => 'project', the leaf default
    # per PF-PRO-067 Contract 4) and the optional parts its consumption_profile declines.
    #
    # Only ever called when a manifest exists, which is what keeps the added config read dark for
    # today's project-edge rollouts: appdev carries no manifest until the FB->appdev cutover, so
    # this never runs and no target's config is opened.
    param([Parameter(Mandatory = $true)]$Entry)

    $role = if ($Entry.role) { [string]$Entry.role } else { 'project' }

    $declined = @()
    $cfgPath = Join-Path -Path $Entry.path -ChildPath 'doc/project-config.json'
    if (Test-Path -LiteralPath $cfgPath) {
        try { $cfg = Get-Content -LiteralPath $cfgPath -Raw | ConvertFrom-Json }
        catch {
            throw "Target at '$($Entry.path)' has a doc/project-config.json that cannot be parsed ($($_.Exception.Message)). Refusing to roll out to it: its consumption_profile decides which optional parts ship, and guessing would deliver a payload the consumer declined."
        }
        if ($cfg.consumption_profile -and $cfg.consumption_profile.declined_parts) {
            $declined = @($cfg.consumption_profile.declined_parts)
        }
    }
    return @{ Role = $role; DeclinedParts = $declined }
}

Export-ModuleMember -Function Get-PayloadManifest, Get-PayloadExclusionSet, Test-PayloadPathExcluded,
                              Build-PayloadStage, Get-TargetPayloadProfile
