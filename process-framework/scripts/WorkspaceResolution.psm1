# WorkspaceResolution.psm1
# The single implementation of workspace, face, and central resolution.
#
# THIS MODULE IMPORTS NOTHING, BY CONTRACT.
# That is the whole reason it exists. Common-ScriptHelpers/DocumentManagement.psm1 imports
# IdRegistry.psm1, and Core.psm1 imports IdRegistry.psm1 — so IdRegistry can never import
# Common-ScriptHelpers, and for a year the two modules carried eleven twinned copies of this
# logic instead. A module with no outgoing imports cannot close a cycle, so both can import
# this one. Adding an import here re-creates the cycle and the twins: do not.

<#
.SYNOPSIS
Workspace resolution primitives shared by Common-ScriptHelpers/Core.psm1 and IdRegistry.psm1 — project root, declared role, config read, framework faces, the parent-pointer chain walk, and central resolution.

.DESCRIPTION
Extracted by PF-PRO-068 Sub-concept 3 (E4-g) from the eleven Core/IdRegistry twin pairs, on the
owner's F4+F7+F8 decision. What the twins cost, and what the extraction removes:

- F4 — the parity guard covered 3 of the 6 pairs its own header listed, and never saw the five
  that were added later. With one implementation there are no pairs, so the guard retires
  instead of being extended.
- F7 — the twins had already drifted at the corrupt-config edge: Core threw, the IdRegistry twin
  returned the consumer tree, where a post-cutover write is deleted by the next rollout's mirror.
  One implementation means one policy per function, stated once (see Get-WorkspaceFaceDir).
- F8 — fourteen independent config read+parse sites in Core alone. Read-WorkspaceConfig is the
  one reader; it applies no policy of its own, so each caller's documented behaviour on a
  missing or unparsable config survives verbatim.

Function names are Core's existing public names, deliberately: they are called from several
hundred sites across the portfolio, and this is a refactor, not a migration. Core.psm1 re-exports
them (so the Common-ScriptHelpers facade's surface is byte-identical to before) and IdRegistry.psm1
imports them directly, retaining only the thin adapters that append a registry filename.
#>

# Loop backstop for the parent-pointer chain walk (Get-ChainRootPath; PF-PRO-067 Contract 2).
# Portfolio depth is 3 (framework-builder -> framework -> project), so the cap is never reached
# in normal operation. It exists because canonicalization cannot reconcile every alias spelling
# of one root; without it such a case is an infinite loop instead of a loud error. This is a
# backstop, not a depth limit — raise it if the portfolio ever nests deeper.
$script:ParentChainHopCap = 16

# Parent-pointer filenames, most-current first (PF-PRO-068 P-5 rename, read-both transition).
# The file is being renamed .framework-central-pointer -> .framework-parent-pointer ("central" was
# always a misnomer: the file names the PARENT workspace, and central is derived from it). Both
# names are accepted for the whole transition because a rolled-out project can be several rollouts
# behind, and Restore can take any project BACK to a pre-rename tag at any time. Retiring the old
# name is a separate, later, deliberate step — not a side effect of this one.
# ORDER IS LOAD-BEARING: it decides which file wins when both names exist, and the chain root
# selects the portfolio-global ID pools.
$script:ParentPointerNames = @('.framework-parent-pointer', '.framework-central-pointer')

# Cached default-start project root. Only the no -StartPath form reads or writes it — see
# Get-ProjectRoot's .NOTES for why an explicit start must never be served from the cache.
$script:ProjectRootCache = $null

function Read-WorkspaceConfig {
    <#
    .SYNOPSIS
    Reads and parses a workspace's doc/project-config.json — the single read+parse site for every
    resolver in this module (PF-EVR-036 F8).

    .DESCRIPTION
    Applies NO policy. It reports what it found and leaves "missing" and "unparsable" to the
    caller, because the callers legitimately disagree about both: an absent config is the
    legitimate pre-bootstrap state for Get-WorkspaceRole (-> 'project') and a hard error for
    Get-BlueprintPath; an unparsable config warns-and-defaults for the role and throws for the
    producer face. Collapsing those into one policy here would silently change four contracts.

    What it removes is the fourteen hand-rolled Get-Content | ConvertFrom-Json sites that each
    re-decided how to spell the path and what to do with a parse exception.

    .PARAMETER ProjectRoot
    Workspace root to read the config from.

    .OUTPUTS
    PSCustomObject:
      Path       — absolute path to doc/project-config.json (whether or not it exists)
      Exists     — [bool] the file is present
      Config     — the parsed object, or $null when absent or unparsable
      ParseError — the parse exception's message, or $null (always $null when Exists is false)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectRoot
    )

    $configPath = Join-Path -Path $ProjectRoot -ChildPath "doc/project-config.json"
    if (-not (Test-Path $configPath)) {
        return [PSCustomObject]@{ Path = $configPath; Exists = $false; Config = $null; ParseError = $null }
    }

    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        return [PSCustomObject]@{ Path = $configPath; Exists = $true; Config = $config; ParseError = $null }
    } catch {
        return [PSCustomObject]@{ Path = $configPath; Exists = $true; Config = $null; ParseError = $_.Exception.Message }
    }
}

function Get-ProjectRoot {
    <#
    .SYNOPSIS
    Gets the workspace root directory from any script location.

    .DESCRIPTION
    Two-pass ancestor walk. Pass 1 looks for doc/project-config.json WITH a non-null project_id —
    the canonical marker, present at the same relative path in a rolled-out project and in a
    producer face. Walking the FULL chain for that marker before trying anything else is what
    keeps a producer face resolving to its real root: at appdev, a script under
    blueprint/process-framework/scripts/ would otherwise hit the secondary marker
    process-framework/.ai-entry-point.md at appdev/blueprint/ and stop one level short. The
    project_id != null test is what skips the blueprint TEMPLATE config (project_id: null until
    bootstrap stamps it).

    Pass 2 runs only when no doc/project-config.json exists anywhere on the chain (pre-initiation
    trees, pre-PD-BUG-022 layouts): legacy root-level project-config.json, then the markers
    process-framework/.ai-entry-point.md, process-framework/ai-tasks.md, .git. Exhausting both
    passes throws — there is no guess to fall back to.

    Honors $env:FRAMEWORK_PROJECT_ROOT_OVERRIDE (PF-IMP-1573), checked before the cache and never
    cached, so per-test env changes always win and nothing leaks between tests in one session.

    .PARAMETER StartPath
    Optional directory to start the walk from. Defaults to this module's own location.

    .NOTES
    CACHING IS SCOPED TO THE DEFAULT FORM, deliberately (PF-PRO-068 E4-g Fork C). Before the
    extraction, Core's Get-ProjectRoot cached and IdRegistry's twin (which always passed an
    explicit start) did not. Caching an explicit -StartPath would hand the second caller the
    first caller's answer — wrong whenever two workspaces are resolved in one session, which is
    exactly what the drill and golden harnesses do. So: no -StartPath reads and writes the cache;
    an explicit -StartPath never touches it. Both prior behaviours are preserved exactly.

    .OUTPUTS
    String — absolute workspace root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$StartPath
    )

    # Checked before the cache and never cached, so per-test env changes always win.
    if ($env:FRAMEWORK_PROJECT_ROOT_OVERRIDE) {
        $override = $env:FRAMEWORK_PROJECT_ROOT_OVERRIDE.Trim()
        if (-not (Test-Path $override)) {
            throw "Get-ProjectRoot: `$env:FRAMEWORK_PROJECT_ROOT_OVERRIDE points at non-existent path: $override. The test fixture must create the sandbox root before invoking the framework script."
        }
        return $override
    }

    $usingDefaultStart = [string]::IsNullOrWhiteSpace($StartPath)
    if ($usingDefaultStart -and $script:ProjectRootCache) {
        return $script:ProjectRootCache
    }

    $startPath = if ($usingDefaultStart) { $PSScriptRoot } else { $StartPath }
    $maxDepth = 10

    # Pass 1 — primary anchor: doc/project-config.json with project_id set.
    $currentPath = $startPath
    $depth = 0
    while ($depth -lt $maxDepth) {
        $cfg = Read-WorkspaceConfig -ProjectRoot $currentPath
        # An unparsable config is treated as "no project_id" and the walk continues — the root
        # marker must not be decided by a file this function cannot read.
        if ($cfg.Exists -and $cfg.Config -and $cfg.Config.project_id) {
            if ($usingDefaultStart) { $script:ProjectRootCache = $currentPath }
            return $currentPath
        }
        $parentPath = Split-Path -Parent $currentPath
        # Split-Path -Parent returns '' at the drive root ("C:\"), not the input path.
        if ([string]::IsNullOrEmpty($parentPath) -or $parentPath -eq $currentPath) { break }
        $currentPath = $parentPath
        $depth++
    }

    # Pass 2 — fallback markers, reached only when pass 1 found no anchored config anywhere.
    $currentPath = $startPath
    $depth = 0
    while ($depth -lt $maxDepth) {
        # Legacy root-level project-config.json (pre-PD-BUG-022 layout).
        $legacyConfigPath = Join-Path -Path $currentPath -ChildPath "project-config.json"
        if (Test-Path $legacyConfigPath) {
            try {
                $legacy = Get-Content $legacyConfigPath -Raw | ConvertFrom-Json
                if ($legacy.project.root_directory -and (Test-Path $legacy.project.root_directory)) {
                    if ($usingDefaultStart) { $script:ProjectRootCache = $legacy.project.root_directory }
                    return $legacy.project.root_directory
                }
            } catch {
                # If config is unreadable, fall through to markers
            }
        }

        # Last-resort markers (rolled-out projects' top-level layout).
        $markers = @(
            "process-framework/.ai-entry-point.md",
            "process-framework/ai-tasks.md",
            ".git"
        )
        foreach ($marker in $markers) {
            $markerPath = Join-Path -Path $currentPath -ChildPath $marker
            if (Test-Path $markerPath) {
                if ($usingDefaultStart) { $script:ProjectRootCache = $currentPath }
                return $currentPath
            }
        }

        $parentPath = Split-Path -Parent $currentPath
        if ([string]::IsNullOrEmpty($parentPath) -or $parentPath -eq $currentPath) { break }
        $currentPath = $parentPath
        $depth++
    }

    throw "Could not find project root from $startPath"
}

function ConvertTo-CanonicalWorkspacePath {
    <#
    .SYNOPSIS
    Canonicalizes a workspace root path for fixed-point comparison during the parent-pointer
    chain walk (PF-PRO-067 Contract 2).

    .DESCRIPTION
    The chain walk terminates when a pointer target equals the workspace holding it. Comparing
    the two raw strings is not enough: one root has many spellings (relative segments, trailing
    separators, a junction or substituted drive, differing case on NTFS), and an unreconciled
    spelling turns termination into an infinite loop. This helper reduces a path to the form the
    comparison is defined on: full path, on-disk casing where resolvable, no trailing separator.

    A path that does not exist is returned in syntactic form rather than throwing — a stale
    pointer target must produce the caller's actionable "pointer is stale" error, not a generic
    resolution failure from here.

    .OUTPUTS
    String — the canonical form, or '' for null/whitespace input.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
    $candidate = $Path.Trim()

    $full = $candidate
    try { $full = [System.IO.Path]::GetFullPath($candidate) } catch { $full = $candidate }

    # Resolve-Path resolves junctions/symlinks and the real on-disk casing, but only for paths
    # that exist. SilentlyContinue (not Stop) is deliberate — see the stale-target note above.
    $resolved = Resolve-Path -LiteralPath $full -ErrorAction SilentlyContinue
    if ($resolved) { $full = $resolved.ProviderPath }

    return $full.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Get-WorkspaceRole {
    <#
    .SYNOPSIS
    Returns this workspace's declared role from project_metadata.role in doc/project-config.json
    (Uniform Workspace Model, PF-PRO-067 Contract 4).

    .DESCRIPTION
    Role values: framework-builder | framework | project | subject. An ABSENT field — or a
    missing config file — defaults to 'project' (the leaf default: every product project is
    correct without declaring anything). A PRESENT but unknown value THROWS: a wrong
    per-workspace declaration must fail loudly and immediately rather than silently mis-route
    (PF-PRO-065 Finding 5's granularity argument). A config file that exists but cannot be
    parsed WARNS loudly and falls back to 'project' — in a producer-face workspace that
    fallback would mis-route state writes, so the defect is surfaced instead of swallowed
    (PF-PRO-067 hardening rider; the missing-file case stays quiet because absence is the
    legitimate pre-bootstrap state).

    The role answers three distinct questions for the resolution helpers, and only these
    (PF-PRO-067 Contract 4): "am I the central hub?" (state/central routing), "may I author
    blueprint/shipped material?" (authoring gates), "do I have a product?" (validation
    severity). Identity questions ("is this registry row me?") are NOT role questions — they
    stay identity comparisons read from config, and must not route through this function.

    .PARAMETER ProjectRoot
    Optional explicit workspace root; defaults to Get-ProjectRoot.

    .OUTPUTS
    String — one of: framework-builder, framework, project, subject.

    .EXAMPLE
    $role = Get-WorkspaceRole
    $isProducerFace = $role -in @('framework', 'framework-builder')   # producer face: own central
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot
    )

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = Get-ProjectRoot }
    $cfg = Read-WorkspaceConfig -ProjectRoot $ProjectRoot

    if (-not $cfg.Exists) { return 'project' }
    if ($cfg.ParseError) {
        Write-Warning "Get-WorkspaceRole: doc/project-config.json exists at '$($cfg.Path)' but could not be parsed ($($cfg.ParseError)). Falling back to role 'project' — in a producer-face workspace this mis-routes state writes; repair the config."
        return 'project'
    }

    $role = $null
    if ($cfg.Config.project_metadata) { $role = $cfg.Config.project_metadata.role }
    if ($null -eq $role -or $role -eq '') { return 'project' }

    $validRoles = @('framework-builder', 'framework', 'project', 'subject')
    if ($validRoles -notcontains $role) {
        throw "Get-WorkspaceRole: unknown role '$role' declared in $($cfg.Path). Valid values: $($validRoles -join ', '). A wrong per-workspace declaration fails loudly by design (PF-PRO-067 Contract 4)."
    }
    return $role
}

function Get-ProcessFrameworkPath {
    <#
    .SYNOPSIS
    Returns the absolute path to the process-framework subtree — the OPERATIVE / CONSUMER tree
    this session reads and runs from, configurable via paths.process_framework.

    .DESCRIPTION
    Reads paths.process_framework from doc/project-config.json and joins with the workspace root.
    Added by Phase 5.5 of the Centralized Framework Management extension (2026-05-11) so that
    appdev — where process-framework/ moved into blueprint/process-framework/ — works alongside
    rolled-out projects where process-framework/ is still at the top level.

    Falls back to "process-framework" when the key is unset OR the config is unparsable. That
    default is deliberate and is NOT the corrupt-config policy Get-WorkspaceFaceDir applies to
    the Write face: a read resolution decides where to LOOK, and a wrong look fails loudly at
    the next step, whereas a wrong write lands in a tree the next rollout deletes. The chain
    walk also depends on this not throwing while probing ancestors it knows nothing about.

    .PARAMETER ProjectRoot
    Optional explicit workspace root. When omitted, resolves via Get-ProjectRoot (cwd-based).
    Use this when a caller is validating a workspace other than the cwd.

    .OUTPUTS
    String — absolute path to the framework subtree.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot
    )

    $root = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { Get-ProjectRoot } else { $ProjectRoot }
    $cfg = Read-WorkspaceConfig -ProjectRoot $root

    $relative = "process-framework"
    if ($cfg.ParseError) {
        Write-Verbose "Get-ProcessFrameworkPath: could not parse '$($cfg.Path)'; falling back to 'process-framework'."
    } elseif ($cfg.Config -and $cfg.Config.paths -and $cfg.Config.paths.process_framework) {
        $relative = $cfg.Config.paths.process_framework
    }
    return (Join-Path -Path $root -ChildPath $relative)
}

function Get-BlueprintPath {
    <#
    .SYNOPSIS
    Returns the absolute path to this workspace's producer-face framework tree — the rollout source and the write target for support tasks that author framework artifacts.

    .DESCRIPTION
    Reads paths.blueprint from doc/project-config.json and joins with the workspace root.
    Introduced by the Substrate Hoist (PF-PRO-068 Constraint 1, Session E) as the producer-face
    sibling of Get-ProcessFrameworkPath:

      paths.process_framework — the OPERATIVE / CONSUMER key: the tree this session reads and runs from.
      paths.blueprint         — the PRODUCER-FACE key: the tree this workspace authors and ships.

    At a self-hosted workspace both keys name the same tree, so the split is inert until the trees
    actually diverge (appdev at the Session F cutover; FB never — it is self-hosted by design).

    SCOPE OF THE RETURNED PATH: this is the producer-face *framework tree* (the rollout source,
    e.g. "blueprint/process-framework"), NOT the blueprint root that also holds doc/, test/ and
    .claude/. Callers needing that root must not derive it here — the two workspaces disagree about
    whether it even exists (FB's blueprint holds only .claude/ and process-framework/), so the root's
    semantics are a separate, undecided contract.

    .PARAMETER ProjectRoot
    Optional explicit workspace root. When omitted, resolves via Get-ProjectRoot (cwd-based).
    This is also the test seam: no dedicated environment axis exists, because -ProjectRoot plus
    $env:FRAMEWORK_PROJECT_ROOT_OVERRIDE (honored inside Get-ProjectRoot) already give fixtures full
    control. Cross-workspace resolution is by composition, never implicit — to target another
    workspace's producer face, pass its root (e.g. from Resolve-WorkspaceRootById).

    .NOTES
    NO DEFAULTING FALLBACK — deliberate, and the one place this diverges from Get-ProcessFrameworkPath
    (which defaults to "process-framework"). There is no universally-correct blueprint value, and the
    obvious fallback ("use paths.process_framework when paths.blueprint is absent") is a time bomb:
    it is correct today only because appdev is still self-hosted, and its meaning INVERTS at the
    Session F cutover, when paths.process_framework starts naming the received consumer tree. A
    framework artifact authored into that tree is deleted by the next rollout's /MIR mirror, silently
    and one rollout later. So a producer face that has not declared its key is a misconfiguration and
    is reported as one (the framework's no-silent-fallback invariant, PF-PRO-068).

    An unparsable config throws here rather than warning-and-defaulting, for the same reason: there is
    nothing safe to fall back to.

    .OUTPUTS
    String — absolute path to the producer-face framework tree.

    .EXAMPLE
    $bp = Get-BlueprintPath
    $templatesDir = Join-Path -Path $bp -ChildPath "templates"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot
    )

    $root = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { Get-ProjectRoot } else { $ProjectRoot }
    $cfg = Read-WorkspaceConfig -ProjectRoot $root

    if ($cfg.ParseError) {
        throw "Get-BlueprintPath: doc/project-config.json at '$($cfg.Path)' could not be parsed ($($cfg.ParseError)). The producer-face tree cannot be resolved; repair the config."
    }

    $relative = $null
    if ($cfg.Config -and $cfg.Config.paths) { $relative = $cfg.Config.paths.blueprint }
    if (-not [string]::IsNullOrWhiteSpace($relative)) {
        return (Join-Path -Path $root -ChildPath $relative.Trim())
    }

    # Role decides which mistake this is — never a workspace-ID literal (convention gate, PF-PRO-067).
    $role = Get-WorkspaceRole -ProjectRoot $root
    if ($role -in @('framework', 'framework-builder')) {
        throw "Get-BlueprintPath: workspace '$root' declares role '$role' (a producer face) but its doc/project-config.json has no paths.blueprint. A producer face must declare the tree it authors and ships (PF-PRO-068 Constraint 1). Add paths.blueprint — at a self-hosted workspace it equals paths.process_framework."
    }
    throw "Get-BlueprintPath: workspace '$root' has role '$role' — a leaf workspace has no producer face of its own, so there is no blueprint to resolve here. Framework artifacts are authored at the owning framework workspace; to target its tree, pass -ProjectRoot with that workspace's root."
}

function Get-WorkspaceFaceDir {
    <#
    .SYNOPSIS
    Returns the absolute framework-tree directory for one face of a workspace — Write (the tree
    this workspace authors framework artifacts into) or Read (the operative/consumer tree).

    .DESCRIPTION
    The face selector under registry-path resolution (PF-PRO-068 face fix, owner-decided
    2026-08-09). It composes, rather than re-implements, the two face resolvers:

      Write face — role-dispatched. A producer role ('framework', 'framework-builder') resolves
        Get-BlueprintPath, inheriting its no-fallback contract. A leaf role resolves exactly as
        the Read face: a leaf has one tree, and its write target IS its operative tree.
      Read face — Get-ProcessFrameworkPath, always. Exists for the chain walk's parent-pointer
        probe: the pointer is deployed INTO the consumer face by the parent's rollout, so probing
        the producer face would silently self-terminate the walk at the wrong root.

    .NOTES
    CORRUPT-CONFIG POLICY, and the one place this function decides rather than delegates
    (PF-EVR-036 F7, closed at E4-g). An unparsable config THROWS on the Write face, before the
    role is consulted.

    That is a deliberate behaviour change, not a preserved one. Previously the role read warned
    and returned 'project', which routed a producer face down the leaf arm and returned the
    CONSUMER tree — so a corrupt config silently redirected framework authoring into the tree
    the next rollout's /MIR deletes, one rollout later. The role warning even said so and the
    operation proceeded anyway. Throwing here is what makes "one implementation" mean "one
    policy": every Write-face resolution now refuses a config it cannot read, at every role.

    The Read face keeps Get-ProcessFrameworkPath's defensive default. A read decides where to
    LOOK — a wrong look fails loudly at the next step — and the chain walk must be able to probe
    ancestor workspaces it knows nothing about without throwing.

    .PARAMETER ProjectRoot
    Workspace root whose face is being resolved.

    .PARAMETER Face
    Write (where framework artifacts are authored) or Read (the operative/consumer tree).

    .OUTPUTS
    String — absolute path to the selected framework tree.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory=$true)]
        [ValidateSet('Write','Read')]
        [string]$Face
    )

    if ($Face -eq 'Write') {
        $cfg = Read-WorkspaceConfig -ProjectRoot $ProjectRoot
        if ($cfg.ParseError) {
            throw "Get-WorkspaceFaceDir: doc/project-config.json at '$($cfg.Path)' could not be parsed ($($cfg.ParseError)). The write face cannot be resolved, and it is not guessed: before PF-EVR-036 F7 this fell through to the consumer tree, where a framework artifact is deleted by the next rollout's mirror. Repair the config."
        }
        if ((Get-WorkspaceRole -ProjectRoot $ProjectRoot) -in @('framework', 'framework-builder')) {
            return Get-BlueprintPath -ProjectRoot $ProjectRoot
        }
    }

    # Read face — and the Write face at a leaf role, whose one tree is both.
    return Get-ProcessFrameworkPath -ProjectRoot $ProjectRoot
}

function Get-ParentPointerFile {
    <#
    .SYNOPSIS
    Returns the parent-pointer file present in a framework directory, accepting either the current or the legacy name, or $null when neither exists.

    .DESCRIPTION
    Single resolution point for the parent-pointer filename, so the read-both transition is
    implemented once rather than at each read site.

    Absent is NOT decided here — the callers disagree about what it means, legitimately: for the
    single-hop reader it is a hard error (a leaf that never received a Push), while for the chain
    walkers it is the fixed point that terminates the walk (a producer face that no one pushed to).
    So this returns $null and each caller keeps its own verbatim handling.

    Both names present is the one case that IS decided here: if their targets disagree the function
    throws rather than picking one. During the transition the rollout writes both with identical
    content, so a disagreement means a hand edit — and silently preferring either name would give
    two readers in one session different chain roots, which is the no-silent-fallback invariant's
    exact failure mode (PF-PRO-068).

    .PARAMETER FrameworkDir
    The framework directory to probe (the pointer lives beside the received framework tree).

    .OUTPUTS
    String — absolute path to the pointer file actually present, or $null when neither name exists.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FrameworkDir
    )

    $found = @(
        $script:ParentPointerNames |
            ForEach-Object { Join-Path -Path $FrameworkDir -ChildPath $_ } |
            Where-Object { Test-Path -LiteralPath $_ }
    )
    if ($found.Count -eq 0) { return $null }
    if ($found.Count -ge 2) {
        $values = @($found | ForEach-Object {
            $raw = Get-Content -LiteralPath $_ -Raw
            if ($null -ne $raw) { $raw.Trim() } else { '' }
        })
        $canonical = @($values | ForEach-Object { ConvertTo-CanonicalWorkspacePath -Path $_ })
        if ($canonical[0] -ne $canonical[1]) {
            throw "Get-ParentPointerFile: both parent-pointer names are present in '$FrameworkDir' and they disagree — '$($script:ParentPointerNames[0])' points to '$($values[0])' but '$($script:ParentPointerNames[1])' points to '$($values[1])'. During the rename transition the rollout writes both with identical content, so a disagreement means one was hand-edited. Reconcile or delete the stale one; this is not guessed."
        }
    }
    return $found[0]
}

function Get-ParentChainHopCap {
    <#
    .SYNOPSIS
    Returns the loop backstop for any walk over the parent-pointer chain.

    .DESCRIPTION
    Exists so a chain walk implemented OUTSIDE this module (Core.psm1's Resolve-WorkspaceRootById
    walks the same chain looking for a declared project_id rather than for the fixed point) shares
    this module's cap instead of declaring a second one. A second constant is a twin, and two caps
    would make one walker give up while the other kept going — a divergence that surfaces as an
    intermittent, topology-dependent failure.

    .OUTPUTS
    Int — the hop cap.
    #>
    [CmdletBinding()]
    param()
    return $script:ParentChainHopCap
}

function Get-ChainRootPath {
    <#
    .SYNOPSIS
    Walks the parent-pointer chain from a workspace to its root and returns the root's workspace
    root path (PF-PRO-067 Contract 2; PF-PRO-068 WI-5).

    .DESCRIPTION
    Every workspace records its parent in its parent-pointer file, written by the parent's
    rollout at <framework tree>/<parent-pointer>. Resolution to the chain root is iterated
    single-hop resolution, terminating at the fixed point "pointer target == the workspace
    holding it" — the chain root carries a SELF-pointer, so no script needs hardcoded root
    detection.

    Two terminations, both legitimate roots — neither is a silent fallback:
    - Self-pointer fixed point: the canonical post-federation root (FrameworkBuilder).
    - No pointer at all: a producer face that has never received a Push. This is how appdev
      terminates before the S3 cutover, and it is why this walk is behavior-identical to the
      pre-walk single-hop readers at every currently live edge.

    Each ancestor's framework subtree is resolved through the READ face, which reads that root's
    own paths.process_framework — so an ancestor whose framework tree sits at a different
    relative path (a producer's blueprint/process-framework vs. a project's top-level
    process-framework) is handled without a second mechanism. Read face is load-bearing: the
    parent pointer is deployed INTO the consumer face by the parent's rollout, so probing the
    producer face would find no pointer at a post-cutover consumer and silently self-terminate
    the walk at the wrong root — and the chain root selects the portfolio-global ID pools.

    Every failure is loud (the no-silent-fallback invariant): an empty pointer, a stale target,
    and a chain that will not converge each throw with a distinct actionable message.

    .PARAMETER StartRoot
    Optional workspace root to start from. Defaults to Get-ProjectRoot (cwd-based).

    .OUTPUTS
    String — absolute, canonicalized workspace root of the chain root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$StartRoot
    )

    $current = if ([string]::IsNullOrWhiteSpace($StartRoot)) { Get-ProjectRoot } else { $StartRoot }
    $current = ConvertTo-CanonicalWorkspacePath -Path $current

    for ($hop = 0; $hop -lt $script:ParentChainHopCap; $hop++) {
        $fwDir = Get-WorkspaceFaceDir -ProjectRoot $current -Face Read
        $pointerPath = Get-ParentPointerFile -FrameworkDir $fwDir

        if ($null -eq $pointerPath) { return $current }

        # Get-Content -Raw returns $null for a 0-byte file; guard it so an empty pointer renders
        # the intended message rather than a null-method error.
        $rawPointer = Get-Content -Path $pointerPath -Raw
        $parentRaw = if ($null -ne $rawPointer) { $rawPointer.Trim() } else { '' }
        if (-not $parentRaw) {
            throw "Get-ChainRootPath: the parent pointer at $pointerPath is empty. Re-run the parent workspace's Push-FrameworkUpdate.ps1 to repair."
        }

        $parent = ConvertTo-CanonicalWorkspacePath -Path $parentRaw
        if ($parent -ieq $current) { return $current }

        if (-not (Test-Path $parent)) {
            throw "Get-ChainRootPath: the parent pointer at $pointerPath points to '$parentRaw', but that workspace root does not exist. The pointer target is stale (the parent was moved or deleted) — correct the path in the pointer file, or re-run the parent's Push-FrameworkUpdate.ps1 to repair it."
        }

        $current = $parent
    }

    throw "Get-ChainRootPath: the parent-pointer chain did not reach a fixed point within $($script:ParentChainHopCap) hops starting at '$current'. This means a pointer cycle, or two spellings of one root that canonicalization did not reconcile (junction, substituted drive, UNC vs. drive-letter form). Inspect the parent-pointer files along the chain."
}

function Get-CentralFrameworkPath {
    <#
    .SYNOPSIS
    Returns the absolute path to the governing process-framework-central/ directory, resolving
    via the declared workspace role and (for leaf workspaces) the parent-pointer file.

    .DESCRIPTION
    This is the OWN central — the workspace's own producer-face state (child registry,
    migrations, intake, proposals, PRJ / PF-STA / PF-TMP pools, tracker, feedback, soak
    instruments). The portfolio-global pools resolve through Get-RootCentralFrameworkPath
    instead; see its help for why the two are distinct destinations.

    - If $env:FRAMEWORK_CENTRAL_OVERRIDE is set and non-empty: returns it directly (after
      verifying the path exists). This is the test-injection hook used by TE-E2E cases that
      exercise central-writing scripts against a per-test sandbox-central dir, so the real
      central is never written to mid-test. The override is the FULL central path.
    - In a producer-face workspace (declared role 'framework' or 'framework-builder'): returns
      <projectRoot>/process-framework-central — the workspace's OWN central, because such a
      workspace's own work IS framework development (PF-PRO-067, two-faces model).
    - In a leaf workspace (role 'project', including the absent-field default): reads the parent
      pointer from the READ face and returns <parent-root>/process-framework-central.

    Throws if, in a leaf workspace, the pointer file is missing, empty, or resolves to a
    non-existent central directory — each case gets a distinct, actionable message. A missing
    pointer means the workspace was never reached by a Push; an empty pointer is a corrupt write;
    a broken target means the pointer is stale. All three are setup errors rather than something
    to silently fall back from.

    .PARAMETER ProjectRoot
    Optional explicit workspace root; defaults to Get-ProjectRoot.

    .PARAMETER FrameworkDir
    Optional explicit framework directory to probe for the parent pointer; defaults to the
    workspace's READ face. Callers that have already resolved the face pass it to avoid a second
    resolution — the value must be the Read face, never the producer face.

    .OUTPUTS
    String — absolute path to the governing process-framework-central/ (or the override target).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot,
        [Parameter(Mandatory=$false)]
        [string]$FrameworkDir
    )

    # Test-injection override (PF-PRO-035 Session 29 OP-1).
    if ($env:FRAMEWORK_CENTRAL_OVERRIDE) {
        $override = $env:FRAMEWORK_CENTRAL_OVERRIDE.Trim()
        if (-not (Test-Path $override)) {
            throw "Get-CentralFrameworkPath: `$env:FRAMEWORK_CENTRAL_OVERRIDE points at non-existent path: $override. The test fixture must create the sandbox-central dir before invoking the framework script."
        }
        return $override
    }

    $root = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { Get-ProjectRoot } else { $ProjectRoot }

    # Role question: "am I the central hub?" (PF-PRO-067 Contract 4 — declared, never inferred
    # from a workspace ID).
    if ((Get-WorkspaceRole -ProjectRoot $root) -in @('framework', 'framework-builder')) {
        return (Join-Path -Path $root -ChildPath "process-framework-central")
    }

    $fwDir = if ([string]::IsNullOrWhiteSpace($FrameworkDir)) { Get-WorkspaceFaceDir -ProjectRoot $root -Face Read } else { $FrameworkDir }
    $pointerPath = Get-ParentPointerFile -FrameworkDir $fwDir
    if ($null -eq $pointerPath) {
        throw "Get-CentralFrameworkPath: no parent pointer found in $fwDir (probed $($script:ParentPointerNames -join ' and ')). This workspace has not received a Push from its parent yet — central writes cannot be resolved. Run Push-FrameworkUpdate.ps1 from the parent workspace to deploy the pointer."
    }

    # Get-Content -Raw returns $null for a 0-byte file (and a whitespace-only file trims to '').
    # Guard the null so both render the intended "is empty" message rather than the generic
    # "cannot call a method on a null-valued expression".
    $rawPointer = Get-Content -Path $pointerPath -Raw
    $parentRoot = if ($null -ne $rawPointer) { $rawPointer.Trim() } else { '' }
    if (-not $parentRoot) {
        throw "Get-CentralFrameworkPath: the parent pointer at $pointerPath is empty. Re-run Push-FrameworkUpdate.ps1 to repair."
    }

    $centralPath = Join-Path -Path $parentRoot -ChildPath "process-framework-central"
    if (-not (Test-Path $centralPath)) {
        throw "Get-CentralFrameworkPath: the parent pointer at $pointerPath points to '$parentRoot', but the resolved central directory does not exist: $centralPath. The pointer target is stale (the parent was moved or deleted) — correct the path in the pointer file, or re-run Push-FrameworkUpdate.ps1 from the parent to repair it."
    }
    return $centralPath
}

function Get-RootCentralFrameworkPath {
    <#
    .SYNOPSIS
    Returns the absolute path to the CHAIN ROOT's process-framework-central/ — the home of the
    portfolio-global ID pools (PF-IMP, PF-PRO, PF-FEE, PF-REV, PF-EVR) under PF-PRO-068 P-3.

    .DESCRIPTION
    Pool-scoped dispatch (PF-PRO-068 WI-5) splits central resolution in two:
    - OWN central (Get-CentralFrameworkPath) — the workspace's own producer-face state: PRJ,
      PF-STA, PF-TMP, its own tracker/feedback/soak instruments.
    - ROOT central (this function) — the five portfolio-global pools, which must mint from ONE
      counter portfolio-wide so a bare PF-IMP-NNNN reference resolves to exactly one row
      anywhere. Per-level pools were rejected for precisely that reason.

    Test seam — TWO axes, so a fixture can drive the two destinations apart:
    - $env:FRAMEWORK_ROOT_CENTRAL_OVERRIDE targets the root central specifically.
    - $env:FRAMEWORK_CENTRAL_OVERRIDE (the pre-existing single axis) is honored as the fallback
      when the root axis is unset, which collapses both destinations onto one directory. That
      collapse IS today's semantics, so every existing single-axis fixture keeps its exact
      current meaning and needs no edit.

    .PARAMETER ProjectRoot
    Optional workspace root to start the chain walk from; defaults to Get-ProjectRoot (cwd-based).

    .OUTPUTS
    String — absolute path to the chain root's process-framework-central/ (or the override target).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot
    )

    if ($env:FRAMEWORK_ROOT_CENTRAL_OVERRIDE) {
        $rootOverride = $env:FRAMEWORK_ROOT_CENTRAL_OVERRIDE.Trim()
        if (-not (Test-Path $rootOverride)) {
            throw "Get-RootCentralFrameworkPath: `$env:FRAMEWORK_ROOT_CENTRAL_OVERRIDE points at non-existent path: $rootOverride. The test fixture must create the root-central dir before invoking the framework script."
        }
        return $rootOverride
    }

    if ($env:FRAMEWORK_CENTRAL_OVERRIDE) {
        $override = $env:FRAMEWORK_CENTRAL_OVERRIDE.Trim()
        if (-not (Test-Path $override)) {
            throw "Get-RootCentralFrameworkPath: `$env:FRAMEWORK_CENTRAL_OVERRIDE points at non-existent path: $override. The test fixture must create the sandbox-central dir before invoking the framework script."
        }
        return $override
    }

    $rootWorkspace = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { Get-ChainRootPath } else { Get-ChainRootPath -StartRoot $ProjectRoot }
    $centralPath = Join-Path -Path $rootWorkspace -ChildPath "process-framework-central"
    if (-not (Test-Path $centralPath)) {
        throw "Get-RootCentralFrameworkPath: the parent-pointer chain resolved to root workspace '$rootWorkspace', but its central directory does not exist: $centralPath. The portfolio-global ID pools live there — every workspace in the chain hard-depends on it. Create it at the root workspace, or correct the parent-pointer chain."
    }
    return $centralPath
}

Export-ModuleMember -Function @(
    'Read-WorkspaceConfig',
    'Get-ProjectRoot',
    'ConvertTo-CanonicalWorkspacePath',
    'Get-WorkspaceRole',
    'Get-ProcessFrameworkPath',
    'Get-BlueprintPath',
    'Get-WorkspaceFaceDir',
    'Get-ParentPointerFile',
    'Get-ParentChainHopCap',
    'Get-ChainRootPath',
    'Get-CentralFrameworkPath',
    'Get-RootCentralFrameworkPath'
)
