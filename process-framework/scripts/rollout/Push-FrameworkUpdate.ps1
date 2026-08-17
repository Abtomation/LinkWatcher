<#
.SYNOPSIS
Phase 1 of Framework Rollout (PF-TSK-088 Mode B): mirror a producer face's framework source tree to one or more registered children.

.DESCRIPTION
Operates from cwd = the producer workspace root (any producer face — PF-PRO-068 P-10 generalization;
historically appdev-only). The child-registry shape (filename, collection key, per-row version-pin
field) is derived from the workspace's declared role via Get-ChildRegistryInfo: role 'framework'
reads project-registry.json / projects; role 'framework-builder' reads framework-registry.json /
frameworks. The framework source path is read from doc/project-config.json — paths.blueprint (the
producer-face key, Constraint 1) with a dark-window fallback to paths.process_framework. Performs:

1. Pre-flight checks: cwd is a producer root, working tree clean (unless -Force), origin remote
   exists (compared against the config's repository_url when declared),
   and a non-blocking flag for untracked temp-debris in the framework source path.
2. Version computation: next rollout version YYYY-MM-DD-NNN (NNN = same-day counter).
3. (Real run only) Update <source>/.framework-version + .framework-version-previous;
   commit; tag `rollout-<version>`; push commit + tag to origin.
4. For each target child (filtered from the role-derived child registry):
   - Save the child's current .framework-version content (becomes its .framework-version-previous).
   - Mirror <source>/ → <child>/process-framework/ (excluding .framework-version-previous
     and both parent-pointer names — .framework-parent-pointer and the legacy
     .framework-central-pointer — so they aren't clobbered).
   - Mirror framework-owned skills <blueprint>/.claude/skills/ → <child>/.claude/skills/,
     per-skill-folder (each shipped skill /MIR'd individually; project-local skills the framework
     does NOT ship are left untouched). No per-project migration — framework owns its skills.
   - Write per-child .framework-version-previous and the parent pointer — BOTH names with
     identical content during the pointer rename transition (PF-PRO-068 §6): a child restored
     to a pre-rename framework version reads only the legacy name.
   - Update the child registry row: version pin (current_framework_version /
     current_substrate_version per level), last_rollout.
5. Append entry to <producer>/process-framework-central/rollouts/rollout-log.md.
6. (Real run only) Commit the central rollout-state changes (child registry + rollout-log.md)
   as a second 'rollout-meta: <version>' commit and push to origin (warn-only on failure), so the
   audit trail lands in version control at rollout time rather than riding in a later commit.

Two parameter sets via -Check vs real run:
- `-Check` (dry-run): pre-flight + version preview + per-project file-diff summary. No git ops, no file writes.
- Real run: full sequence above.

.PARAMETER Project
Optional. One or more PRJ-NNN IDs to limit the rollout, comma-separated: -Project PRJ-001,PRJ-002.
The script splits each element itself, so the multi-project form works under `pwsh -File` (which
passes tokens as literal strings and never builds an array) as well as in-session (PF-IMP-1428).
When omitted, rolls out to all eligible children (excludes this workspace's own registry row —
own-config project_id comparison, P-13-proof; rows with version_freeze: true; sandbox rows,
which are fan-out-excluded but explicitly targetable per P-8; and any row whose role is not
among the child roles this producer serves — PF-PRO-067 role guard: such children receive
updates from their own parent's rollout, never this one).

.PARAMETER Check
Switch flag. Dry-run mode. Reports what would change without writing anything.

.PARAMETER Force
Switch flag. Proceed even if the framework source tree has uncommitted changes (default refuses).
Also tolerates GitHub remote push failure (logs warning, keeps local commit + tag).

.EXAMPLE
# Dry-run all eligible projects:
Push-FrameworkUpdate.ps1 -Check

.EXAMPLE
# Canary rollout to one project:
Push-FrameworkUpdate.ps1 -Project PRJ-002

.EXAMPLE
# Rollout to multiple specific projects (comma-separated; works under `pwsh -File` too):
Push-FrameworkUpdate.ps1 -Project PRJ-001,PRJ-002

.NOTES
Per Centralized Framework Management proposal §3.3-3.4 and PF-TSK-088 Mode B. Created during
Phase 3 of the centralized-framework-management Framework Extension (2026-05-10).

Authored directly in appdev (not bootstrapped from TimeTrackingV2) — per Phase 4.5 manifest.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$Project = @(),

    [Parameter(Mandatory = $false)]
    [switch]$Check,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Split -Project into the ID list every downstream step uses. The element-wise split is what makes
# the multi-project form work under `pwsh -File`, which passes tokens as literal strings and never
# builds an array: -Project PRJ-001,PRJ-002 arrives as ONE element "PRJ-001,PRJ-002" and is split
# here. An in-session/-Command call binds a real 2-element array, and -split applies per element,
# so both invocation forms yield the same ID list (PF-IMP-1428).
$projectIds = @($Project -split '[,\s]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })

# The payload-classification helpers (manifest read, exclusion sets, filtered staging) live in a
# sibling leaf module so BOTH rollout directions read one implementation (PF-PRO-068 S3 E4-c).
# Mode D rollback consumes the same exclusion sets this fan-out does, so a rollback can no longer
# silently un-do what a rollout filtered — measured before the fix at the E4-d edge-2 drill.
# Imported from $PSScriptRoot rather than resolved through config: the module ships in THIS
# directory by construction (both are support class), so there is nothing to resolve. A failed
# import throws — an absent filter would ship the support set to every project, and degrading to
# that silently is the outcome the whole payload-manifest mechanism exists to prevent.
$rolloutScriptDir    = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$payloadFilterModule = Join-Path -Path $rolloutScriptDir -ChildPath 'PayloadFilter.psm1'
try {
    Import-Module (Resolve-Path -Path $payloadFilterModule -ErrorAction Stop) -Force -ErrorAction Stop
}
catch {
    throw "Could not import the payload filter module expected beside this script at '$payloadFilterModule': $($_.Exception.Message). Refusing to roll out — without it there is no payload classification, and an unfiltered push delivers the support class to every project."
}

#---------------------------------------------------------------------------------------
# Helpers
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
        throw "cwd '$cwd' is not a producer workspace root (missing doc/project-config.json). Run this script from the root of the producer workspace whose children you are rolling out to."
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
    # $env:FRAMEWORK_CENTRAL_OVERRIDE is set, central reads/writes (project-registry,
    # rollout-log) go to the override path instead of <producer>/process-framework-central.
    # cwd validation in Get-ProducerRoot still requires a real cwd central dir — the
    # override only affects where this script reads/writes central state.
    param([string]$ProducerRoot)
    if ($env:FRAMEWORK_CENTRAL_OVERRIDE) {
        return $env:FRAMEWORK_CENTRAL_OVERRIDE
    }
    return (Join-Path -Path $ProducerRoot -ChildPath "process-framework-central")
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

function Get-FrameworkSourcePath {
    # Resolve the tree this rollout SHIPS — the producer face. Two rungs, newest key first
    # (PF-PRO-068 Constraint 1 key split, Session E2; same authored pattern as Restore's
    # tag-side three-rung chain, minus the pre-config literal rung a live workspace never needs):
    #   1. paths.blueprint         — the producer-face key. Post-cutover the two keys DIVERGE
    #                                (process_framework flips to the received consumer face),
    #                                and shipping rung 2 there would roll the consumer face out
    #                                to every child.
    #   2. paths.process_framework — dark-window / legacy fallback, where the single key named
    #                                the producer face because both faces were the same tree.
    # Both live producer configs already carry paths.blueprint equal to paths.process_framework,
    # so rung 1 resolves identically today — the change is dark by construction.
    # Returns @{ Absolute; Relative; Rung }. Relative form is used for git operations
    # (working-tree paths); Absolute for filesystem ops.
    param([string]$ProducerRoot)
    $configPath = Join-Path -Path $ProducerRoot -ChildPath "doc/project-config.json"
    if (-not (Test-Path -Path $configPath)) {
        throw "doc/project-config.json not found at '$configPath'. Cannot resolve the framework source path."
    }
    $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
    $relative = $null
    $rung = $null
    if ($config.paths -and $config.paths.blueprint) {
        $relative = $config.paths.blueprint
        $rung = 'paths.blueprint (producer face)'
    }
    elseif ($config.paths -and $config.paths.process_framework) {
        $relative = $config.paths.process_framework
        $rung = 'paths.process_framework (pre-key-split fallback)'
    }
    if (-not $relative) {
        throw "doc/project-config.json at '$configPath' declares neither paths.blueprint nor paths.process_framework. Set paths.blueprint to the producer-face tree this rollout ships (e.g., 'blueprint/process-framework')."
    }
    Write-Verbose "Framework source resolved to '$relative/' via $rung."
    return @{
        Absolute = Join-Path -Path $ProducerRoot -ChildPath $relative
        Relative = $relative
        Rung     = $rung
    }
}

function Get-CurrentFrameworkVersion {
    param([string]$ProducerRoot)
    $src = Get-FrameworkSourcePath -ProducerRoot $ProducerRoot
    $verPath = Join-Path -Path $src.Absolute -ChildPath ".framework-version"
    if (Test-Path -Path $verPath) {
        return (Get-Content -Raw -Path $verPath).Trim()
    }
    return $null
}

function Compute-NextVersion {
    param([string]$ProducerRoot)
    $today = Get-Date -Format "yyyy-MM-dd"
    # Find max NNN among today's existing tags `rollout-YYYY-MM-DD-NNN`.
    Push-Location $ProducerRoot
    try {
        $tags = git tag -l "rollout-$today-*" 2>$null
    }
    finally {
        Pop-Location
    }
    $maxN = 0
    foreach ($t in $tags) {
        if ($t -match "rollout-$today-(\d{3})") {
            $n = [int]$Matches[1]
            if ($n -gt $maxN) { $maxN = $n }
        }
    }
    $nextN = $maxN + 1
    return ('{0}-{1:D3}' -f $today, $nextN)
}

function Test-WorkingTreeClean {
    param([string]$ProducerRoot)
    $src = Get-FrameworkSourcePath -ProducerRoot $ProducerRoot
    Push-Location $ProducerRoot
    try {
        $output = git status --porcelain "$($src.Relative)/" 2>&1
    }
    finally {
        Pop-Location
    }
    if ($output) {
        return @{ Clean = $false; Output = $output }
    }
    return @{ Clean = $true; Output = $null }
}

function Test-OriginRemote {
    # The expected remote comes from the producer's OWN config (repository_url), not a literal —
    # each producer face has its own repo (appdev: framework-appdev; FB: framework-builder), so a
    # hard-coded expectation would warn on every run at any other face (PF-PRO-068 P-10 residual).
    # A config without repository_url degrades to a presence-only check, reported as expected.
    param([string]$ProducerRoot)
    Push-Location $ProducerRoot
    try {
        $remote = git remote get-url origin 2>$null
    }
    finally {
        Pop-Location
    }
    if (-not $remote) {
        return @{ Present = $false; URL = $null; IsExpected = $false; ExpectedURL = $null }
    }
    $expectedUrl = $null
    $configPath = Join-Path -Path $ProducerRoot -ChildPath "doc/project-config.json"
    if (Test-Path -Path $configPath) {
        try { $expectedUrl = (Get-Content -Raw -Path $configPath | ConvertFrom-Json).repository_url }
        catch { Write-Verbose "Could not read repository_url from '$configPath' ($($_.Exception.Message)); origin check degrades to presence-only." }
    }
    $expected = if ($expectedUrl) {
        # Compare host+path, tolerating ssh vs https forms and a trailing .git.
        $normRemote   = ($remote.Trim()   -replace '^git@github\.com:', 'github.com/' -replace '^https?://', '' -replace '\.git$', '')
        $normExpected = ($expectedUrl.Trim() -replace '^git@github\.com:', 'github.com/' -replace '^https?://', '' -replace '\.git$', '')
        $normRemote -eq $normExpected
    } else {
        $true   # no declared expectation — presence is all we can check
    }
    return @{ Present = $true; URL = $remote.Trim(); IsExpected = $expected; ExpectedURL = $expectedUrl }
}

function Get-EligibleProjects {
    # Unified eligibility semantics (PF-PRO-068 P-8), level-relative via the P-10 registry shape.
    # Exclusion classes, in order:
    #   self    — the row keyed by this workspace's OWN project_id (own-config comparison, never a
    #             PRJ-000 literal, so it survives the P-13 identity switch; pattern from Restore's
    #             Constraint-6 self-guard and New-PendingMigration's Resolve-EligibleProjects).
    #             Warns on explicit request instead of falling through to the generic error.
    #   role    — rows whose declared role (absent = 'project', the leaf default) is not among the
    #             child roles THIS producer serves. Hard-coding 'project' here was the P-8
    #             inversion: at FB it excluded every child the fan-out exists to serve.
    #   sandbox — rows matching the level's sandbox key pattern are excluded from FAN-OUT but
    #             always honored as EXPLICIT targets (fleet precedent: New-PendingMigration).
    #   freeze  — version_freeze pins the row; skipped, with a warning on explicit request.
    param(
        [hashtable]$Children,
        [string[]]$Filter,
        [hashtable]$RegInfo,
        [string]$OwnProjectId
    )
    $eligible = @{}
    foreach ($id in $Children.Keys) {
        $entry = $Children[$id]
        if ($OwnProjectId -and $id -eq $OwnProjectId) {
            if ($Filter -and ($Filter -contains $id)) {
                Write-Warning "Registry row $id is this workspace's own row (project_id in doc/project-config.json) — a producer never rolls out to itself; a producer face is updated by ITS parent's rollout. Skipping despite explicit -Project request."
            }
            continue
        }
        $rowRole = if ($entry.role) { [string]$entry.role } else { 'project' }
        if ($RegInfo.AcceptedChildRoles -notcontains $rowRole) {
            # PF-PRO-067 role guard, level-relative: this producer's rollout serves only the child
            # roles its own level fans out to. Rows of any other role receive updates from THEIR
            # parent's rollout, with a role-filtered payload — never from this one. Covers both
            # enumeration and explicit -Project requests, which flow through this filter.
            if ($Filter -and ($Filter -contains $id)) {
                Write-Warning "Registry row $id has role '$rowRole' — not a row this producer's rollout serves (accepted: $($RegInfo.AcceptedChildRoles -join ', ')); such children receive updates from their parent's rollout (PF-PRO-067 role guard). Skipping despite explicit -Project request."
            }
            continue
        }
        if ($id -match $RegInfo.SandboxKeyPattern -and -not ($Filter -and ($Filter -contains $id))) {
            # Sandboxes never receive fan-out rollouts (P-8; a bare Push previously shipped to
            # them). Explicit targeting stays allowed — that is how sandbox E2E rollouts work.
            Write-Verbose "Sandbox row $id excluded from fan-out (explicitly targetable)."
            continue
        }
        if ($entry.version_freeze -eq $true) {
            if ($Filter -and ($Filter -contains $id)) {
                Write-Warning "Project $id is frozen (version_freeze: true). Skipping despite explicit -Project request."
            }
            continue
        }
        if ($Filter -and -not ($Filter -contains $id)) { continue }
        $eligible[$id] = $entry
    }
    return $eligible
}

function Get-ProjectFrameworkDiff {
    # Enumerate file differences between appdev/process-framework/ and <project>/process-framework/.
    # Returns @{ Added = N; Modified = N; Deleted = N; Samples = @{Added=...; Modified=...; Deleted=...} }
    #
    # -PreserveRelativePaths is the same per-level set Invoke-Mirror passes to /XF. Without it the
    # dry run reports every preserved file as "deleted" — a -Check that contradicts what the real
    # mirror does, which is the exact disagreement Get-PayloadExclusionSet exists to prevent.
    param(
        [string]$SourceDir,
        [string]$DestDir,
        [string[]]$PreserveRelativePaths = @()
    )

    $diff = @{
        Added    = 0
        Modified = 0
        Deleted  = 0
        Samples  = @{ Added = @(); Modified = @(); Deleted = @() }
    }

    # Keep this filter aligned with the robocopy /XD /XF list in Invoke-Mirror so dry-run
    # diff matches what the real mirror would transfer.
    $skipFile = { param($f) ($f.FullName -match '[\\/]__pycache__[\\/]') -or ($f.Name -like '*.pyc') }

    if (-not (Test-Path -Path $DestDir)) {
        # First-ever rollout — every source file is "Added".
        $sourceFiles = Get-ChildItem -Path $SourceDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { -not (& $skipFile $_) }
        $diff.Added = $sourceFiles.Count
        $diff.Samples.Added = $sourceFiles | Select-Object -First 5 | ForEach-Object { $_.FullName.Substring($SourceDir.Length).TrimStart('\','/') }
        return $diff
    }

    $sourceFiles = @{}
    foreach ($f in (Get-ChildItem -Path $SourceDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { -not (& $skipFile $_) })) {
        $rel = $f.FullName.Substring($SourceDir.Length).TrimStart('\','/')
        $sourceFiles[$rel] = $f
    }
    $destFiles = @{}
    foreach ($f in (Get-ChildItem -Path $DestDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { -not (& $skipFile $_) })) {
        $rel = $f.FullName.Substring($DestDir.Length).TrimStart('\','/')
        $destFiles[$rel] = $f
    }

    # The three legacy per-child names, matched by leaf (each occurs only at the framework root),
    # plus the manifest's per-level set, matched by RELATIVE PATH — leaf matching would over-match
    # 'README.md' across tasks/ and templates/ and wrongly report them as surviving.
    $excludedPerProject = @('.framework-version-previous', '.framework-parent-pointer', '.framework-central-pointer')
    $preserveRel = @{}
    foreach ($p in $PreserveRelativePaths) {
        if ($p) { $preserveRel[(($p -replace '\\', '/').TrimStart('/'))] = $true }
    }

    foreach ($rel in $sourceFiles.Keys) {
        if ($destFiles.ContainsKey($rel)) {
            # Compare hash for modified detection.
            $srcHash = (Get-FileHash -Path $sourceFiles[$rel].FullName -Algorithm SHA1).Hash
            $dstHash = (Get-FileHash -Path $destFiles[$rel].FullName -Algorithm SHA1).Hash
            if ($srcHash -ne $dstHash) {
                $diff.Modified++
                if ($diff.Samples.Modified.Count -lt 5) { $diff.Samples.Modified += $rel }
            }
        }
        else {
            $diff.Added++
            if ($diff.Samples.Added.Count -lt 5) { $diff.Samples.Added += $rel }
        }
    }
    foreach ($rel in $destFiles.Keys) {
        if (-not $sourceFiles.ContainsKey($rel)) {
            # Files in dest but not in source — would be deleted by mirror.
            # Exclude per-project files that we explicitly preserve.
            $leaf = Split-Path -Leaf $rel
            if ($excludedPerProject -contains $leaf) { continue }
            if ($preserveRel.ContainsKey((($rel -replace '\\', '/').TrimStart('/')))) { continue }
            $diff.Deleted++
            if ($diff.Samples.Deleted.Count -lt 5) { $diff.Samples.Deleted += $rel }
        }
    }

    return $diff
}

function Invoke-Mirror {
    # Use robocopy with /MIR. Preserves orphan-removal semantics.
    #
    # -PreserveRelativePaths carries the payload filter's PER-LEVEL set (framework-root-relative).
    # These must survive at the destination, so they go to /XF: under /MIR an excluded file is
    # neither copied nor orphan-deleted, which is precisely "leave the child's own copy alone".
    #
    # They are passed as FULL DESTINATION PATHS, and that is load-bearing — robocopy's /XF matching
    # was measured (PF-PRO-068 S3 E4-b), not assumed:
    #   bare name  ('README.md')      -> matches EVERY README.md at every depth (over-match: the
    #                                    framework tree has one at the root, in tasks/ and in
    #                                    templates/, and only the root one is per-level)
    #   relative   ('tasks/README.md')-> matches NOTHING. Silent no-op, the worst of the three.
    #   full DEST path               -> matches exactly that one file. Correct.
    #   full SOURCE path             -> matches nothing (the orphan lives at the destination).
    # The three legacy bare names below stay bare: each occurs only at the framework root, and
    # keeping them unchanged keeps the no-manifest path byte-identical to pre-filter behaviour.
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

    # /MIR mirror; /XF excludes per-project files (so prior values aren't deleted between
    # robocopy and our explicit per-project writes that follow) and Python bytecode caches;
    # /XD excludes .git and __pycache__ directories; /NJH /NJS /NDL /NP quiet output.
    $rcArgs = @(
        $SourceDir,
        $DestDir,
        '/MIR',
        '/XF', '.framework-version-previous', '.framework-parent-pointer', '.framework-central-pointer', '*.pyc'
    ) + $preserveArgs + @(
        '/XD', '.git', '__pycache__',
        '/NJH', '/NJS', '/NDL', '/NP', '/NFL'
    )
    $output = & robocopy @rcArgs 2>&1
    $exitCode = $LASTEXITCODE

    # Robocopy exit codes: 0-7 OK, 8+ error.
    if ($exitCode -ge 8) {
        throw "robocopy failed (exit code $exitCode) when mirroring $SourceDir → $DestDir. Output:`n$($output -join `"`n`")"
    }
    return $exitCode
}

function Get-FrameworkSkillsSourcePath {
    # Framework-owned skills (Craft-as-Skill, PF-PRO-051) live in <blueprint>/.claude/skills — a
    # SIBLING of the framework source tree (<blueprint>/process-framework), not under it. Derive it
    # from the framework source's parent so it tracks paths.process_framework instead of hardcoding
    # "blueprint". Returns the path whether or not it exists; callers Test-Path before use.
    param([string]$SourceDir)
    $blueprintRoot = Split-Path -Parent $SourceDir
    return (Join-Path -Path $blueprintRoot -ChildPath ".claude/skills")
}

function Invoke-SkillsMirror {
    # Distribute framework-owned skills to a project's .claude/skills/, mirroring each framework skill
    # folder INDIVIDUALLY (robocopy /MIR per skill) rather than /MIR-ing the whole .claude/skills/
    # root. A whole-root /MIR would delete any project-local skill a project author added alongside
    # the framework's; per-folder /MIR keeps each shipped skill exactly in sync while leaving
    # un-shipped sibling skills untouched. Framework owns each skill folder it ships, so overwrite is
    # safe and no per-project migration is needed. Returns the count of skill folders mirrored.
    # -ExcludeFolders carries the payload filter's support-class skill entries (blueprint-root-
    # relative, e.g. '.claude/skills/task-creation/'); only the leaf folder name is matched, since
    # that is what identifies a skill on both sides. An excluded skill is simply not mirrored —
    # removing one a project already has is a Mode C migration, not this script's job.
    param(
        [string]$SkillsSource,
        [string]$SkillsDestRoot,
        [string[]]$ExcludeFolders = @()
    )
    if (-not (Test-Path -Path $SkillsSource)) { return 0 }
    $skillDirs = @(Get-ChildItem -Path $SkillsSource -Directory -ErrorAction SilentlyContinue)
    if ($skillDirs.Count -eq 0) { return 0 }
    $excludedNames = @($ExcludeFolders | ForEach-Object { $_.TrimEnd('/').Split('/')[-1] } | Where-Object { $_ })
    if (-not (Test-Path -Path $SkillsDestRoot)) {
        New-Item -ItemType Directory -Path $SkillsDestRoot -Force | Out-Null
    }
    $mirrored = 0
    foreach ($skill in $skillDirs) {
        if ($excludedNames -contains $skill.Name) { continue }
        $dest = Join-Path -Path $SkillsDestRoot -ChildPath $skill.Name
        $rcArgs = @(
            $skill.FullName, $dest, '/MIR',
            '/XD', '.git', '__pycache__',
            '/XF', '*.pyc',
            '/NJH', '/NJS', '/NDL', '/NP', '/NFL'
        )
        $null = & robocopy @rcArgs 2>&1
        if ($LASTEXITCODE -ge 8) {
            throw "robocopy failed (exit code $LASTEXITCODE) when mirroring skill '$($skill.Name)' → $dest"
        }
        $mirrored++
    }
    return $mirrored
}

function Append-RolloutLog {
    param(
        [string]$LogPath,
        [string]$Version,
        [string[]]$TargetProjectIds,
        [hashtable]$Children,
        [string]$Note
    )

    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $kind = "ROLLOUT"
    # $Children is the derived collection ($registry[$regInfo.CollectionKey]) — indexing the raw
    # registry through a 'projects' literal here was the last P-10 residual: at FB (collection
    # 'frameworks') it null-indexed and broke the fan-out summary mid-rollout.
    $targetSummary = if ($TargetProjectIds.Count -eq 0) { "(none)" } else {
        ($TargetProjectIds | ForEach-Object { "$_ ($($Children[$_].name))" }) -join ", "
    }

    $entry = @"

## $timestamp — $kind — $Version

- **Targets**: $targetSummary
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
$source       = Get-FrameworkSourcePath -ProducerRoot $producerRoot
$sourceDir    = $source.Absolute
$sourceRel    = $source.Relative

# Step 1b: derive the child-registry shape from this workspace's declared role (PF-PRO-068 P-10).
# The resolver is the shipped Get-ChildRegistryInfo in the producer's OWN framework tree — each
# face imports its own copy, so the mapping travels with the substrate. It also reads the
# workspace's own project_id, the self-exclusion identity (own-config comparison, no PRJ-000
# literal — survives the P-13 identity switch; loud-fail on an unreadable id per the
# New-PendingMigration precedent, rather than silently relying on the freeze belt).
try {
    $coreModule = Join-Path -Path $sourceDir -ChildPath "scripts/Common-ScriptHelpers/Core.psm1"
    Import-Module $coreModule -Force -ErrorAction Stop
    $regInfo = Get-ChildRegistryInfo -ProjectRoot $producerRoot
}
catch {
    Write-Error "Could not derive the child-registry shape for this workspace: $($_.Exception.Message)"
    exit 1
}
$ownProjectId = $null
try {
    $ownProjectId = (Get-Content -Raw -Path (Join-Path -Path $producerRoot -ChildPath "doc/project-config.json") | ConvertFrom-Json).project_id
} catch {
    Write-Verbose "project_id read failed: $($_.Exception.Message)"
}
if (-not $ownProjectId) {
    Write-Error "doc/project-config.json at '$producerRoot' has no readable project_id — the self-exclusion identity cannot be established, and a rollout without it could target this workspace's own row. Repair the config."
    exit 1
}

$registryPath = Join-Path -Path $centralRoot -ChildPath $regInfo.FileName
if (-not (Test-Path -Path $registryPath)) {
    Write-Error "Child registry '$($regInfo.FileName)' (derived from role '$($regInfo.Role)') not found at '$registryPath'. Nothing to roll out to."
    exit 1
}
$registry     = Read-Json -Path $registryPath
$children     = $registry[$regInfo.CollectionKey]
if ($null -eq $children) {
    Write-Error "Child registry '$($regInfo.FileName)' has no top-level '$($regInfo.CollectionKey)' collection (derived from role '$($regInfo.Role)'). The registry file and the workspace role disagree — repair one of them."
    exit 1
}
$rolloutLog   = Join-Path -Path $centralRoot -ChildPath "rollouts/rollout-log.md"
$skillsSource = Get-FrameworkSkillsSourcePath -SourceDir $sourceDir
$skillNames   = if (Test-Path -Path $skillsSource) { @(Get-ChildItem -Path $skillsSource -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name | Sort-Object) } else { @() }
$skillCount   = $skillNames.Count

# Step 1c: Payload filter (PF-PRO-068 Contract 4). The manifest is authored at FrameworkBuilder and
# travels WITH the framework tree, so appdev has none until the FB->appdev cutover — until then the
# filter is inert and every rollout ships the full tree exactly as before. That is darkness by
# construction rather than by flag: there is no switch to leave in the wrong position.
# The notice is LOUD because after the cutover an absent manifest means projects silently start
# receiving the support set again — the same reasoning as the rollout-meta gate's skip notice.
$payloadManifest = Get-PayloadManifest -SourceDir $sourceDir
if ($null -eq $payloadManifest) {
    Write-Warning "No payload-manifest.json in $sourceRel/ — shipping the FULL framework tree to every target, unfiltered. Expected before the FB→appdev cutover; after it, this means the support set is reaching project trees."
} else {
    # Substrate drift gate (PF-PRO-068 N-4, Session E3): a producer whose blueprint has diverged
    # from the payload it RECEIVED must not ship — the received classes are parent-owned and the
    # canonical copies are tested at their owner, so a drifted copy is unverified by construction.
    # Runs only when a manifest exists (same darkness condition as the payload filter: appdev has
    # no manifest until the cutover, so today's no-manifest path above is byte-identical to before).
    # Self-hosted faces (FB; both keys one tree) report identical-by-identity and pass.
    $driftGate = Join-Path -Path $sourceDir -ChildPath "scripts/validation/Sync-Substrate.ps1"
    if (Test-Path -LiteralPath $driftGate) {
        & pwsh.exe -NoProfile -ExecutionPolicy Bypass -File $driftGate -Check
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Push preflight: the substrate drift gate failed (Sync-Substrate.ps1 -Check exit $LASTEXITCODE). The producer blueprint has diverged from the received payload — re-project with Sync-Substrate.ps1 or investigate the edit before shipping."
            exit 1
        }
    } else {
        Write-Warning "Push preflight: payload-manifest.json exists but the drift gate is missing at $driftGate — the blueprint's parity with the received payload is UNVERIFIED this rollout."
    }
}

# Step 2: Validate -Project IDs (if provided)
if ($projectIds.Count -gt 0) {
    $unknown = @($projectIds | Where-Object { -not $children.ContainsKey($_) })
    if ($unknown.Count -gt 0) {
        Write-Error "Unknown project IDs: $($unknown -join ', '). Known IDs: $($children.Keys -join ', ')"
        exit 1
    }
}

# Step 3: Determine eligible target projects
$eligible = Get-EligibleProjects -Children $children -Filter $projectIds -RegInfo $regInfo -OwnProjectId $ownProjectId
if ($eligible.Count -eq 0) {
    if ($projectIds.Count -gt 0) {
        Write-Error "No eligible projects after filtering. Specified: $($projectIds -join ', '). All specified are either this workspace's own row, frozen, or rows whose role this producer's rollout does not serve (PF-PRO-067). Nothing to do."
    } else {
        Write-Warning "No eligible projects in registry (other than this workspace's own row, frozen, sandbox, or role-excluded rows). Nothing to do."
    }
    exit 0
}
# Sandbox rows silently missing from a fan-out would read as registry drift — say why they are
# absent (they stay reachable via explicit -Project targeting, P-8).
$sandboxSkipped = @($children.Keys | Where-Object { $_ -match $regInfo.SandboxKeyPattern -and -not ($eligible.ContainsKey($_)) })
if ($projectIds.Count -eq 0 -and $sandboxSkipped.Count -gt 0) {
    Write-Host "  (sandbox rows excluded from fan-out: $($sandboxSkipped -join ', ') — target explicitly with -Project to include)"
}

# Step 4: Pre-flight git checks
$wt = Test-WorkingTreeClean -ProducerRoot $producerRoot
if (-not $wt.Clean -and -not $Force -and -not $Check) {
    Write-Error "$sourceRel/ (producer working tree) has uncommitted changes:`n$($wt.Output -join "`n")`n`nCommit or stash before rollout, or use -Force."
    exit 1
}

$remote = Test-OriginRemote -ProducerRoot $producerRoot
if (-not $remote.Present) {
    Write-Warning "No origin remote configured. Local commit + tag will still apply, but rollout durability is reduced (no off-machine backup)."
}
elseif (-not $remote.IsExpected) {
    Write-Warning "origin remote is '$($remote.URL)' — the config's repository_url declares '$($remote.ExpectedURL)'. Proceeding anyway."
}

# Step 5: Compute next version
$currentVersion = Get-CurrentFrameworkVersion -ProducerRoot $producerRoot
$nextVersion    = Compute-NextVersion -ProducerRoot $producerRoot

Write-Host ""
Write-Host "═══ Framework Rollout — Pre-flight ═══"
Write-Host "  Mode             : $(if ($Check) { 'DRY-RUN (-Check)' } else { 'REAL ROLLOUT' })"
Write-Host "  Producer root    : $producerRoot ($($regInfo.Role); own id $ownProjectId)"
Write-Host "  Working tree     : $(if ($wt.Clean) { 'clean' } else { 'dirty (proceeding due to -Force or -Check)' })"
Write-Host "  Origin remote    : $(if ($remote.Present) { $remote.URL } else { '(none)' })"
Write-Host "  Current version  : $(if ($currentVersion) { $currentVersion } else { '(none — first rollout)' })"
Write-Host "  Next version     : $nextVersion"
Write-Host "  Target projects  : $($eligible.Keys -join ', ')"
# Name the skills, don't just count them — the reviewer approving a rollout needs to see WHICH
# framework skills ship with it. Listed once here (a source-side fact); the per-project line below
# keeps the count plus each project's destination path (PF-IMP-1434).
Write-Host "  Framework skills : $(if ($skillCount -gt 0) { "$skillCount — $($skillNames -join ', ')" } else { '(none)' })"
Write-Host ""

# Pre-flight: flag (do not block) untracked temp-debris in the framework source path so a
# robocopy /MIR mirror does not silently ship atomic-write leftovers like Foo.ps1.tmp.<pid>.<hash>
# (PF-IMP-1237 / PF-FEE-1305). Runs in both -Check and real modes; read-only.
Push-Location $producerRoot
try {
    $untrackedSource = git ls-files --others --exclude-standard -- "$sourceRel/" 2>$null
}
finally {
    Pop-Location
}
$tempDebris = @($untrackedSource | Where-Object { $_ -match '\.tmp(\.|$)|\.bak$|\.orig$|~$' })
if ($tempDebris.Count -gt 0) {
    Write-Warning "Untracked temp-debris in $sourceRel/ — robocopy /MIR will SHIP these unless removed:`n  $($tempDebris -join "`n  ")"
    Write-Host ""
}

# Step 6: Per-project diff enumeration (for both -Check and real)
Write-Host "═══ Per-Project Diff ═══"
foreach ($prjId in $eligible.Keys) {
    $entry   = $eligible[$prjId]
    $destDir = Join-Path -Path $entry.path -ChildPath "process-framework"

    # Diff against the SAME filtered payload the real mirror ships, so -Check can never report a
    # different file set than a rollout actually transfers.
    $diffStage = $null
    try {
        $diffSource   = $sourceDir
        $diffPreserve = @()
        if ($null -ne $payloadManifest) {
            $targetProfile = Get-TargetPayloadProfile -Entry $entry
            $excl          = Get-PayloadExclusionSet -Manifest $payloadManifest -TargetRole $targetProfile.Role -DeclinedParts $targetProfile.DeclinedParts
            # Both classes leave the stage; only the remove class may be deleted at the destination.
            $diffStage     = Build-PayloadStage -SourceDir $sourceDir -ExclusionPaths (@($excl.RemovePaths) + @($excl.PreservePaths))
            $diffSource    = $diffStage.Path
            $diffPreserve  = @($excl.PreservePaths)
        }
        $diff = Get-ProjectFrameworkDiff -SourceDir $diffSource -DestDir $destDir -PreserveRelativePaths $diffPreserve
    }
    finally {
        if ($diffStage -and (Test-Path -LiteralPath $diffStage.Path)) {
            Remove-Item -LiteralPath $diffStage.Path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "  $prjId ($($entry.name)): added=$($diff.Added) modified=$($diff.Modified) deleted=$($diff.Deleted)"
    if ($diff.Samples.Added.Count -gt 0) {
        Write-Host "    Sample added   : $($diff.Samples.Added -join ', ')"
    }
    if ($diff.Samples.Modified.Count -gt 0) {
        Write-Host "    Sample modified: $($diff.Samples.Modified -join ', ')"
    }
    if ($diff.Samples.Deleted.Count -gt 0) {
        Write-Host "    Sample deleted : $($diff.Samples.Deleted -join ', ')"
    }
    if ($skillCount -gt 0) {
        $projectSkillsRoot = Join-Path -Path $entry.path -ChildPath ".claude/skills"
        Write-Host "    skills         : $skillCount framework skill(s) → $projectSkillsRoot (per-skill mirror)"
    }
}
Write-Host ""

# Step 7: Branch on -Check vs real run
if ($Check) {
    Write-Host "═══ DRY-RUN COMPLETE — no files were modified ═══"
    Write-Host ""
    Write-Host "To execute the rollout for real, run without -Check:"
    if ($projectIds.Count -gt 0) {
        Write-Host "  Push-FrameworkUpdate.ps1 -Project $($projectIds -join ',')"
    } else {
        Write-Host "  Push-FrameworkUpdate.ps1"
    }
    # -Check is a preview: it changes nothing on any project and is not a rollout event,
    # so it deliberately writes NO files — including no entry to rollout-log.md, which stays
    # a clean append-only history of real rollouts + rollbacks (PF-IMP-1109 / PF-EVR-025 R-3).
    exit 0
}

# Real run — guarded by ShouldProcess.
$projectsListForLog = ($eligible.Keys | Sort-Object) -join ', '
if (-not $PSCmdlet.ShouldProcess(
    "producer git (commit+tag+push) and children [$projectsListForLog] (mirror $sourceRel/ → <child>/process-framework/)",
    "Roll out framework version $nextVersion"
)) {
    exit 0
}

# Step 8: Update appdev's .framework-version (and previous)
$appdevVerPath  = Join-Path -Path $sourceDir -ChildPath ".framework-version"
$appdevPrevPath = Join-Path -Path $sourceDir -ChildPath ".framework-version-previous"
if ($currentVersion) {
    [System.IO.File]::WriteAllText($appdevPrevPath, $currentVersion + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}
[System.IO.File]::WriteAllText($appdevVerPath, $nextVersion + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))

# Step 9: Git commit + tag in appdev
Push-Location $producerRoot
try {
    git add $sourceRel 2>&1 | Out-Null
    git commit -m "rollout: $nextVersion to projects [$projectsListForLog]" 2>&1 | Out-Null
    # Outcome of every git call below is read from $LASTEXITCODE, NOT from try/catch.
    # git is a NATIVE command: a non-zero exit does not raise a terminating error, even under
    # the $ErrorActionPreference = 'Stop' set at the top of this script — that preference governs
    # PowerShell errors, and $PSNativeCommandUseErrorActionPreference is $false by default
    # (measured on PS 7.6.3). The catch blocks that used to wrap these calls therefore never
    # fired: a rejected push left $pushOk = $true and printed the success line below.
    # Reachable on every rollout since the gates moved to pre-push (PF-IMP-1985) — any gate
    # failure rejects the push. Command output is captured and echoed on failure instead of
    # being discarded to Out-Null: it carries the pre-push hook's own findings, which are the
    # reason the push was refused.
    $tagOut = git tag "rollout-$nextVersion" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "git tag rollout-$nextVersion FAILED (exit $LASTEXITCODE) — this rollout's version is NOT durably marked, so the re-roll recovery path below does not apply. Resolve before re-running."
        $tagOut | ForEach-Object { Write-Host "    $_" }
    }
    else {
        Write-Host "✅ Tagged producer repo: rollout-$nextVersion"
    }

    # Push to origin (warn-only on failure).
    if ($remote.Present) {
        $pushOk = $true
        $pushOut = git push origin main 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "git push origin main FAILED (exit $LASTEXITCODE). Local commit applied; remote push can be retried manually."
            $pushOut | ForEach-Object { Write-Host "    $_" }
            $pushOk = $false
        }
        $tagPushOut = git push origin "rollout-$nextVersion" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "git push of tag rollout-$nextVersion FAILED (exit $LASTEXITCODE). Local tag applied; remote tag push can be retried manually."
            $tagPushOut | ForEach-Object { Write-Host "    $_" }
            $pushOk = $false
        }
        if ($pushOk) { Write-Host "✅ Pushed to origin (commit + tag)" }
    }
}
finally {
    Pop-Location
}

# Step 10: Per-project mirror + per-project file writes + registry updates
$succeeded = @()
$failed    = @()
foreach ($prjId in ($eligible.Keys | Sort-Object)) {
    $entry   = $eligible[$prjId]
    $destDir = Join-Path -Path $entry.path -ChildPath "process-framework"

    Write-Host "→ Rolling out to $prjId ($($entry.name)) at $($entry.path)"

    # Capture project's current framework version (for .framework-version-previous).
    $projectPrevVersion = $null
    $projectVerFile = Join-Path -Path $destDir -ChildPath ".framework-version"
    if (Test-Path -Path $projectVerFile) {
        $projectPrevVersion = (Get-Content -Raw -Path $projectVerFile).Trim()
    }

    $mirrorStage = $null
    try {
        # Mirror — from the filtered payload when a manifest exists, from the tree itself when not.
        $mirrorSource    = $sourceDir
        $skillExclusions = @()
        $mirrorPreserve  = @()
        if ($null -ne $payloadManifest) {
            $targetProfile   = Get-TargetPayloadProfile -Entry $entry
            $excl            = Get-PayloadExclusionSet -Manifest $payloadManifest -TargetRole $targetProfile.Role -DeclinedParts $targetProfile.DeclinedParts
            # Both classes leave the stage so neither is copied over the child; only the preserve
            # class additionally reaches /XF, which is what stops /MIR orphan-deleting it.
            $mirrorStage     = Build-PayloadStage -SourceDir $sourceDir -ExclusionPaths (@($excl.RemovePaths) + @($excl.PreservePaths))
            $mirrorSource    = $mirrorStage.Path
            $skillExclusions = @($excl.SkillFolders)
            $mirrorPreserve  = @($excl.PreservePaths)
            Write-Verbose "   payload filter [$prjId]: role=$($targetProfile.Role) removed=$($excl.RemovePaths.Count) preserved=$($mirrorPreserve.Count) absent-at-this-level=$($mirrorStage.Missing.Count) skills-withheld=$($skillExclusions.Count)"
        }
        Invoke-Mirror -SourceDir $mirrorSource -DestDir $destDir -PreserveRelativePaths $mirrorPreserve | Out-Null

        # Mirror framework-owned skills (Craft-as-Skill, PF-PRO-051) per-skill into
        # <project>/.claude/skills/ — overwrite each shipped skill, leave project-local siblings alone.
        $projectSkillsRoot = Join-Path -Path $entry.path -ChildPath ".claude/skills"
        $mirroredSkills = Invoke-SkillsMirror -SkillsSource $skillsSource -SkillsDestRoot $projectSkillsRoot -ExcludeFolders $skillExclusions
        if ($mirroredSkills -gt 0) {
            Write-Host "   ✅ Mirrored $mirroredSkills framework skill(s) → .claude/skills/"
        }

        # Write per-project .framework-version-previous.
        $projectPrevFile = Join-Path -Path $destDir -ChildPath ".framework-version-previous"
        if ($projectPrevVersion) {
            [System.IO.File]::WriteAllText($projectPrevFile, $projectPrevVersion + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
        }
        # If no prior, leave the file absent (preserves "no rollback target" semantics).

        # Write per-project .framework-version. Historically this reached the child by riding the
        # UNFILTERED mirror (the producer's own stamp, updated at Step 8, was simply copied). Under
        # a filtered payload the file is per-level and held out of the stage, so nothing delivered
        # it and the child was left with a rollback pointer but no record of what it runs — Restore
        # then reported "Current version : (none recorded)" and the rollout log read "rolled back
        # from (unrecorded)" (finding F2, measured at the E4 drill). Writing it explicitly here, next
        # to -previous, makes the version chain correct by construction rather than by side effect.
        $projectVerOut = Join-Path -Path $destDir -ChildPath ".framework-version"
        [System.IO.File]::WriteAllText($projectVerOut, $nextVersion + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))

        # Write the per-project parent pointer — BOTH names with identical content during the
        # .framework-central-pointer → .framework-parent-pointer rename transition (PF-PRO-068 §6).
        # A child restored to a pre-rename framework version reads only the legacy name, so the
        # legacy file keeps being refreshed until the Phase G rename sweep retires it; the readers
        # (read-both since E1) throw if the two names ever disagree, which this identical-content
        # write makes impossible for rollout-written pointers.
        foreach ($pointerName in @('.framework-parent-pointer', '.framework-central-pointer')) {
            $pointerFile = Join-Path -Path $destDir -ChildPath $pointerName
            [System.IO.File]::WriteAllText($pointerFile, $producerRoot + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
        }

        # Update registry entry (in-memory; saved at end).
        $children[$prjId][$regInfo.PinField] = $nextVersion
        $children[$prjId].last_rollout = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")

        $succeeded += $prjId
        Write-Host "   ✅ Mirrored, version stamped, registry updated"
    }
    catch {
        $failed += @{ Id = $prjId; Error = $_.Exception.Message }
        Write-Error "   ❌ Failed: $($_.Exception.Message)"
        # Continue to next project rather than abort — partial-rollout state is recoverable.
    }
    finally {
        # The staged payload is a throwaway temp tree; drop it whether the rollout succeeded or not.
        if ($mirrorStage -and (Test-Path -LiteralPath $mirrorStage.Path)) {
            Remove-Item -LiteralPath $mirrorStage.Path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Step 11: Save updated registry
$registry.metadata.updated = (Get-Date -Format "yyyy-MM-dd")
Save-Json -Path $registryPath -Object $registry

# Step 12: Append rollout-log entry
$logNote = if ($failed.Count -eq 0) {
    "Succeeded for: $($succeeded -join ', ')"
} else {
    "Succeeded: $($succeeded -join ', '); FAILED: $(($failed | ForEach-Object { "$($_.Id) ($($_.Error))" }) -join '; ')"
}
Append-RolloutLog -LogPath $rolloutLog -Version $nextVersion -TargetProjectIds @($eligible.Keys) -Children $children -Note $logNote

# Step 13: Commit central rollout state (registry + rollout-log.md) as a second 'rollout-meta'
# commit, so the audit trail lands in version control at rollout time instead of riding in a
# later unrelated commit (PF-IMP-1086 / PF-EVR-025 X-2). Best-effort: a commit/push hiccup here
# must not turn a successful rollout into a failure. Skipped when central state is redirected
# (FRAMEWORK_CENTRAL_OVERRIDE in tests/sandboxes) — detected EXPLICITLY from the override
# variable, not inferred from path prefixes: a prefix test silently takes the commit path for an
# override pointing inside the workspace tree, and silently flips if central ever relocates
# (PF-PRO-068 E2 residual: explicit override detection with a loud skip notice).
if (-not $env:FRAMEWORK_CENTRAL_OVERRIDE) {
    Push-Location $producerRoot
    try {
        $registryRel   = ([System.IO.Path]::GetRelativePath($producerRoot, $registryPath)) -replace '\\', '/'
        $rolloutLogRel = ([System.IO.Path]::GetRelativePath($producerRoot, $rolloutLog)) -replace '\\', '/'
        $centralChanges = git status --porcelain -- $registryRel $rolloutLogRel 2>$null
        if ($centralChanges) {
            try {
                # Pathspec form commits ONLY these two files — central holds many other dirty files.
                # $LASTEXITCODE, not try/catch — see the note at the Step 9 tag/push block.
                $metaCommitOut = git commit -m "rollout-meta: $nextVersion" -- $registryRel $rolloutLogRel 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Central rollout-state commit FAILED (exit $LASTEXITCODE). The rollout itself succeeded; commit $($regInfo.FileName) + rollout-log.md manually."
                    $metaCommitOut | ForEach-Object { Write-Host "    $_" }
                }
                else {
                    Write-Host "✅ Committed central rollout state (rollout-meta: $nextVersion)"
                    if ($remote.Present) {
                        $metaPushOut = git push origin main 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            Write-Warning "Push of rollout-meta commit FAILED (exit $LASTEXITCODE). The rollout itself succeeded; retry the push manually."
                            $metaPushOut | ForEach-Object { Write-Host "    $_" }
                        }
                        else {
                            Write-Host "✅ Pushed rollout-meta commit to origin"
                        }
                    }
                }
            }
            catch {
                Write-Warning "Central rollout-state commit/push did not complete: $($_.Exception.Message). The rollout itself succeeded; commit $($regInfo.FileName) + rollout-log.md manually."
            }
        }
        else {
            Write-Verbose "No central rollout-state changes to commit."
        }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Warning "Central state is redirected (FRAMEWORK_CENTRAL_OVERRIDE active); skipping rollout-meta commit. If this is a REAL rollout, the registry + rollout-log changes at the override location are NOT under version control here — commit them where they live."
}

Write-Host ""
Write-Host "═══ Rollout Complete ═══"
Write-Host "  Version       : $nextVersion"
Write-Host "  Succeeded     : $($succeeded.Count) project(s) — $($succeeded -join ', ')"
if ($failed.Count -gt 0) {
    Write-Host "  Failed        : $($failed.Count) project(s) — $(($failed | ForEach-Object { $_.Id }) -join ', ')"
    Write-Host "  Recovery      : the git tag rollout-$nextVersion is durable; failed projects can be re-rolled by re-running with -Project <id>."
    exit 2
}
exit 0
