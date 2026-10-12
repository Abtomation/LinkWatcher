<#
.SYNOPSIS
    Validates a workspace's canonical directory shape and entry point against its declared
    role - the PF-PRO-065 Contract 3 conformance check (PF-PRO-068 S3 G5).

.DESCRIPTION
    Contract 3: "a canonical directory shape and entry point, so an agent entering ANY
    workspace orients identically. Conformance is checkable." This script is the checkable
    half. Every rule is keyed to a structural fact the shared machinery depends on (the
    resolution helpers, the rollout drivers, the payload filter) or to the entry-point
    orientation itself, and the rule set was measured against the three live conformant
    workspaces (FrameworkBuilder, appdev, APP-002) at authoring - it asserts the shape the
    fleet actually has, not an invented ideal.

    Rules by scope (rule IDs render in findings):

      Universal (every role - evaluated before the role dispatch)
        C3-U1  doc/project-config.json exists and parses   (Get-ProjectRoot pass-1 anchor)
        C3-U3  declared role valid                         (Get-WorkspaceRole contract)
        C3-U2  project_id non-empty                        (root-marker requirement)
               EXEMPT at role subject, where C3-S1 asserts the inverse - which is why U3 is
               evaluated BEFORE U2: the role decides which polarity of the identity rule
               applies (PF-PRO-069 WI-13).

      Universal (roles project / framework / framework-builder)
        C3-U4  Read face directory exists                  (paths.process_framework or default)
        C3-U5  Read face carries the 8 substrate spine dirs (guides, infrastructure,
               languages-config, scripts, tasks, templates, tools, visualization)
        C3-U6  root CLAUDE.md exists                       (workspace orientation)

      Catalog face - the face the level AUTHORS its catalogs at: a project's Read face, a
      producer role's producer face. A receiving framework's consumer face deliberately has
      NO catalogs (the manifest's framework_level_files PRESERVE semantics) - which is why
      these six are checked at the catalog face, not universally at the Read face.
        C3-C1  ai-tasks.md            C3-C2  PF-id-registry.json
        C3-C3  PF-documentation-map.md  C3-C4  README.md
        C3-C5  .ai-entry-point.md     C3-C6  domain-config.json

      Producer roles (framework, framework-builder)
        C3-E1  root .ai-entry-point.md                     (workspace entry point; a project's
               entry point is C3-C5 at its Read face instead)
        C3-P1  paths.blueprint declared and directory exists (Get-BlueprintPath no-fallback)
        C3-P2  producer face carries the 8 spine dirs
        C3-P3  process-framework-central/ spine: PF-id-registry-central.json,
               state-tracking/permanent + temporary, rollouts/, feedback/
        C3-P4  role-derived child registry + migrations ledger dir (Get-ChildRegistryInfo)
        C3-P8  payload-manifest.json at the Read face      (payload filter / sync gate input)

      framework only
        C3-P5  faces diverge (consumer != producer) - a framework receives one tree and
               authors another; equal keys are the pre-cutover degenerate state

      framework-builder only
        C3-P6  faces identical (self-hosted by design)
        C3-P7  a face parent pointer, if present, is a SELF-pointer (chain-root fixed point;
               absent is also legitimate - a producer face no one has pushed to)

      Operating layer (PF-PRO-071 WI-4/WI-6/WI-9 - ADVISORY severity, see below)
        C3-P10 [producers] blueprint-root operating-file seeds present: CLAUDE.md,
               .gitignore, .claude/settings.json (the child-standup seed set, WI-4)
        C3-P11 [producers] central spine additions: proposals/, evaluation-reports/
               (creator-script targets; kept out of the hard C3-P3 set until promoted)
        C3-R6  [framework] received manifest declares the agents class -> root
               .claude/agents/ exists (the agents-mirror target)
        C3-P9  [framework-builder] manifest declares the agents class -> blueprint
               .claude/agents/ exists (the agents-mirror source; a mid-level framework
               ships agents to nobody - its children are projects, which the channel-level
               role gate excludes - so no source dir is demanded there)
        C3-P12 [framework-builder] root .claude/agents/ is an identical projection of
               blueprint/.claude/agents/ (the Q5 contingency: the one workspace whose
               canonical and operative agent locations differ must not drift silently)

      Receiving roles (project, framework)
        C3-R1  parent pointer present at the Read face, both-name copies agreeing
               (Get-ParentPointerFile read-both transition)
        C3-R2  pointer target root exists and holds process-framework-central/
               (Get-CentralFrameworkPath leaf resolution)
        C3-R3  .framework-version at the Read face         (received-series stamp)
        C3-R4  .framework-version-previous at the Read face (rollback pin)

      project only
        C3-R5  doc/state-tracking/permanent + temporary    (project-local state routing)
        C3-N1  paths.blueprint NOT declared - a leaf claiming a producer face is the
               mis-declaration Get-BlueprintPath's own error text names

      subject only - the container-workspace marker (PF-PRO-069 WI-13, R-5(b))
        C3-S1  project_id is null                          (resolution-inert by design:
               Get-ProjectRoot anchors solely on non-null IDs, so the children resolve
               independently and a session at the outer dir fails loudly instead of
               silently routing state to the container)
        C3-S2  no framework faces                          (paths.blueprint undeclared AND no
               Read-face directory - a subject carries no framework tree of its own)
        C3-S3  attachments.children declared and non-empty, each entry {directory, parent}
        C3-S4  every attachment resolves                   (child directory exists and carries
               a parsable doc/project-config.json)
        C3-S5  every attachment agrees with the child's OWN parent pointer - the list is a
               CHECKED PROJECTION, never an authority, which is how it answers Contract 2's
               ban on duplicating a parent declaration in config (the N-5 projection pattern)

    Severity (PF-PRO-071 WI-6): every rule is Blocking (any finding -> exit 1) unless marked
    Advisory. An Advisory finding prints as [WARN], is tallied in a separate [ADVISORY]
    summary line, and never affects the exit code. New capability rules land Advisory and
    are promoted to Blocking only after a clean three-workspace pass - the ownership-lines
    warn-first arc (warn-first 2026-08-10 -> blocking 2026-08-16); the promotion record
    lives in git history and this header, not the rollout log.

    A subject root is deliberately unfindable by default resolution (null ID), so it must be
    validated with an explicit -ProjectRoot. Checking is on-demand only: the outer directory
    is typically not a repo, so no hook surface exists - the audit homes are the registration
    audit and the Framework Evaluation conformance reference.

    Missing-face cascades are suppressed: when a face directory is absent its content rules
    are skipped rather than reported N times.

.PARAMETER ProjectRoot
    Workspace root to validate. Defaults to the resolved project root. Pass another
    workspace's root to validate it cross-workspace - resolution is parameter-authoritative
    throughout (never cwd-bound), so one workspace can check FB, a framework, and a project
    in one sitting (the PF-PRO-068 section-8 verification form).

.PARAMETER Detailed
    Also print each passing rule, not only findings.

.EXAMPLE
    Validate-WorkspaceConformance.ps1
    # Validate the current workspace

.EXAMPLE
    Validate-WorkspaceConformance.ps1 -ProjectRoot "C:\path\to\some-workspace" -Detailed
    # Cross-workspace validation with per-rule output

.NOTES
    PF-PRO-068 S3 G5 - the Contract 3 conformance check named in PF-PRO-065's contract table
    and PF-PRO-068 section 8. Consumers: Framework Evaluation; Workspace Initiation
    (FB-TSK-001, PF-PRO-069 - the standup target state and the Phase B validation baseline).
    Read-only validator - not soak-enrolled (validator class, fleet convention).
OWNERSHIP: FWK-FB (FrameworkBuilder) - canonical at FrameworkBuilder; anywhere else a received copy. Edit only at the owning workspace. An agent may only modify files its workspace owns.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot,

    [switch]$Detailed
)

$ErrorActionPreference = 'Stop'

# Import the umbrella (Get-ProjectRoot / Get-WorkspaceRole / Get-ProcessFrameworkPath /
# Get-BlueprintPath / Get-ChildRegistryInfo / ConvertTo-CanonicalWorkspacePath) plus
# WorkspaceResolution.psm1 directly for Get-ParentPointerFile and Read-WorkspaceConfig,
# which the umbrella does not re-export - the read-both pointer transition must come from
# the one resolution point, never a re-implemented twin.
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
Import-Module (Join-Path $dir "WorkspaceResolution.psm1") -Force

$script:Findings = [System.Collections.Generic.List[string]]::new()
$script:Advisories = [System.Collections.Generic.List[string]]::new()
$script:RulesEvaluated = 0

function Test-Rule {
    # Records one rule outcome. -Requirement is the asserted fact (printed under -Detailed
    # on pass); -Failure is the finding text (defaults to the requirement). -Severity
    # (PF-PRO-071 WI-6): Blocking findings drive the exit code; an Advisory finding prints
    # as [WARN], is counted separately, and never affects the exit code — capability rules
    # land Advisory and are promoted to Blocking only after a clean three-workspace pass
    # (the ownership-lines warn-first arc; the promotion record lives in git history and
    # this header, not the rollout log).
    param(
        [Parameter(Mandatory)][string]$Rule,
        [Parameter(Mandatory)][bool]$Passed,
        [Parameter(Mandatory)][string]$Requirement,
        [string]$Failure,
        [ValidateSet('Blocking', 'Advisory')][string]$Severity = 'Blocking'
    )
    $script:RulesEvaluated++
    if ($Passed) {
        if ($Detailed) { Write-Host "  [PASS] [$Rule] $Requirement" }
    } else {
        $text = if ($Failure) { $Failure } else { $Requirement }
        if ($Severity -eq 'Advisory') {
            $script:Advisories.Add("[$Rule] $text")
            Write-Host "  [WARN] [$Rule] $text"
        } else {
            $script:Findings.Add("[$Rule] $text")
            Write-Host "  [FAIL] [$Rule] $text"
        }
    }
    return $Passed
}

function Test-MemberSet {
    # One rule over a member list: passes when every member exists under -BaseDir; the
    # finding names exactly the missing members so a single absent element is identifiable.
    param(
        [Parameter(Mandatory)][string]$Rule,
        [Parameter(Mandatory)][string]$BaseDir,
        [Parameter(Mandatory)][string[]]$Members,
        [Parameter(Mandatory)][string]$Label,
        [ValidateSet('Blocking', 'Advisory')][string]$Severity = 'Blocking'
    )
    $missing = @($Members | Where-Object { -not (Test-Path -LiteralPath (Join-Path $BaseDir $_)) })
    return Test-Rule -Rule $Rule -Passed ($missing.Count -eq 0) `
        -Requirement "$Label carries: $($Members -join ', ')" `
        -Failure "$Label is missing: $($missing -join ', ')" `
        -Severity $Severity
}

function Test-SubjectContract {
    # The role-subject rule set (C3-S1..C3-S5) - PF-PRO-069 WI-13 / R-5(b), replacing the
    # dormant branch this role carried from G5. A subject is a CONTAINER whose children attach
    # to different frameworks; it is deliberately not a workspace in the resolution sense, and
    # that is exactly what C3-S1 and C3-S2 assert. The attachments list is a CHECKED
    # PROJECTION: S4 resolves each entry, S5 requires it to agree with the child's own parent
    # pointer - so the list can never quietly become a second authority for a fact the pointer
    # already owns. When the two disagree the pointer wins and the list is the defect.
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][AllowNull()][object]$Config
    )

    # ---- C3-S1: the null-ID marker ----
    $declaredId = $Config.project_id
    $null = Test-Rule 'C3-S1' ([string]::IsNullOrWhiteSpace($declaredId)) `
        -Requirement 'project_id is null (resolution-inert container marker)' `
        -Failure "project_id is '$declaredId' at role 'subject' - a subject marker must carry a NULL id: any non-null value is un-minted, ungoverned by every uniqueness mechanism, and turns the outer directory into a resolution anchor that silently routes child state to the container"

    # ---- C3-S2: no framework faces ----
    $faceProblems = [System.Collections.Generic.List[string]]::new()
    if ($Config.paths -and -not [string]::IsNullOrWhiteSpace($Config.paths.blueprint)) {
        $faceProblems.Add("paths.blueprint is declared ('$($Config.paths.blueprint)')")
    }
    $subjectRead = Get-ProcessFrameworkPath -ProjectRoot $Root
    if (Test-Path -LiteralPath $subjectRead -PathType Container) {
        $faceProblems.Add("a framework tree exists at '$($subjectRead.Substring($Root.Length).TrimStart('\', '/'))'")
    }
    $null = Test-Rule 'C3-S2' ($faceProblems.Count -eq 0) `
        -Requirement 'no framework faces (the children carry the framework trees, not the container)' `
        -Failure "$($faceProblems -join '; ') at role 'subject' - a container workspace has no framework face of its own"

    # ---- C3-S3: the projection is declared and well-formed ----
    $entries = @()
    if ($Config.attachments -and $Config.attachments.children) { $entries = @($Config.attachments.children) }
    $malformed = @($entries | Where-Object {
        [string]::IsNullOrWhiteSpace($_.directory) -or [string]::IsNullOrWhiteSpace($_.parent) })
    $s3 = Test-Rule 'C3-S3' ($entries.Count -gt 0 -and $malformed.Count -eq 0) `
        -Requirement "attachments.children declared, $($entries.Count) well-formed entry/entries" `
        -Failure $(if ($entries.Count -eq 0) { "attachments.children is absent or empty - a subject declares the children it contains, each entry { directory, parent }" }
                   else { "$($malformed.Count) attachment entry/entries missing 'directory' or 'parent'" })
    if (-not $s3) { return }

    # ---- C3-S4 (resolve) / C3-S5 (agree) ----
    # Cascade suppression: an entry that fails to resolve is not also reported as disagreeing.
    $unresolved  = [System.Collections.Generic.List[string]]::new()
    $disagreeing = [System.Collections.Generic.List[string]]::new()
    $agreementChecked = 0
    foreach ($entry in $entries) {
        $childRoot = Join-Path $Root $entry.directory
        if (-not (Test-Path -LiteralPath $childRoot -PathType Container)) {
            $unresolved.Add("$($entry.directory) (no such directory under the container)"); continue
        }
        $childCfg = Read-WorkspaceConfig -ProjectRoot $childRoot
        if (-not $childCfg.Exists) {
            $unresolved.Add("$($entry.directory) (no doc/project-config.json - not a bootstrapped workspace)"); continue
        }
        if ($childCfg.ParseError) {
            $unresolved.Add("$($entry.directory) (doc/project-config.json unparsable: $($childCfg.ParseError))"); continue
        }

        $agreementChecked++
        $childFace = Get-ProcessFrameworkPath -ProjectRoot $childRoot
        $pointerPath = $null
        try { $pointerPath = Get-ParentPointerFile -FrameworkDir $childFace }
        catch { $disagreeing.Add("$($entry.directory) (parent-pointer conflict: $($_.Exception.Message))"); continue }
        if (-not $pointerPath) {
            $disagreeing.Add("$($entry.directory) (no parent pointer at its Read face - nothing for the list to agree with)"); continue
        }
        $rawPointer = Get-Content -LiteralPath $pointerPath -Raw
        $targetRoot = if ($null -ne $rawPointer) { $rawPointer.Trim() } else { '' }
        if (-not $targetRoot -or -not (Test-Path -LiteralPath $targetRoot -PathType Container)) {
            $disagreeing.Add("$($entry.directory) (its parent pointer targets '$targetRoot', which does not exist)"); continue
        }
        $parentCfg = Read-WorkspaceConfig -ProjectRoot $targetRoot
        $actualParent = if ($parentCfg.Exists -and -not $parentCfg.ParseError) { $parentCfg.Config.project_id } else { $null }
        if ([string]::IsNullOrWhiteSpace($actualParent)) {
            $disagreeing.Add("$($entry.directory) (its pointer target '$targetRoot' declares no project_id)"); continue
        }
        if ($actualParent -ine $entry.parent) {
            $disagreeing.Add("$($entry.directory) (the list says '$($entry.parent)'; its own pointer resolves to '$actualParent')")
        }
    }
    $null = Test-Rule 'C3-S4' ($unresolved.Count -eq 0) `
        -Requirement "every attachment resolves to a bootstrapped workspace ($($entries.Count) listed)" `
        -Failure "unresolved attachment(s): $($unresolved -join '; ')"
    $null = Test-Rule 'C3-S5' ($disagreeing.Count -eq 0) `
        -Requirement "every attachment agrees with the child's own parent pointer ($agreementChecked checked)" `
        -Failure "the attachments projection disagrees with the child's own pointer: $($disagreeing -join '; ') - the pointer is the authority, so the list is what must be corrected"
}

function Write-Summary {
    param([Parameter(Mandatory)][string]$RoleLabel, [Parameter(Mandatory)][string]$Root)
    Write-Host ""
    if ($script:Findings.Count -eq 0) {
        Write-Host "[OK] Validate-WorkspaceConformance: role '$RoleLabel' at '$Root' - $($script:RulesEvaluated) rules evaluated, 0 findings. Conformant."
    } else {
        Write-Host "[FAIL] Validate-WorkspaceConformance: role '$RoleLabel' at '$Root' - $($script:RulesEvaluated) rules evaluated, $($script:Findings.Count) finding(s)."
    }
    if ($script:Advisories.Count -gt 0) {
        Write-Host "[ADVISORY] $($script:Advisories.Count) advisory note(s) - observational only, exit code unaffected (Blocking promotion pends a clean three-workspace pass)."
    }
}

$SpineDirs = @('guides', 'infrastructure', 'languages-config', 'scripts', 'tasks', 'templates', 'tools', 'visualization')
$CatalogRules = [ordered]@{
    'C3-C1' = 'ai-tasks.md'
    'C3-C2' = 'PF-id-registry.json'
    'C3-C3' = 'PF-documentation-map.md'
    'C3-C4' = 'README.md'
    'C3-C5' = '.ai-entry-point.md'
    'C3-C6' = 'domain-config.json'
}
$CentralSpine = @('PF-id-registry-central.json', 'state-tracking/permanent', 'state-tracking/temporary', 'rollouts', 'feedback')

# ---- Root resolution (parameter-authoritative; never cwd-bound past this point) ----
$root = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    Get-ProjectRoot
} else {
    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
        throw "Validate-WorkspaceConformance: -ProjectRoot '$ProjectRoot' does not exist or is not a directory."
    }
    (Resolve-Path -LiteralPath $ProjectRoot).ProviderPath
}

Write-Host "Validate-WorkspaceConformance: checking '$root' (PF-PRO-065 Contract 3)"

# ---- C3-U1 / C3-U2: the config anchor ----
$cfg = Read-WorkspaceConfig -ProjectRoot $root
$u1 = Test-Rule 'C3-U1' ($cfg.Exists -and -not $cfg.ParseError) `
    -Requirement 'doc/project-config.json exists and parses' `
    -Failure $(if (-not $cfg.Exists) { "no doc/project-config.json at '$root' - not a bootstrapped workspace (Get-ProjectRoot pass-1 anchor)" }
               else { "doc/project-config.json exists but could not be parsed ($($cfg.ParseError))" })
if (-not $u1) {
    Write-Summary -RoleLabel 'unresolvable' -Root $root
    exit 1
}
# ---- C3-U3: declared role. Evaluated BEFORE C3-U2 because the role decides which polarity
#      of the identity rule applies - a subject's marker is null-ID by design (PF-PRO-069). ----
$role = $null
try {
    $role = Get-WorkspaceRole -ProjectRoot $root
    $null = Test-Rule 'C3-U3' $true -Requirement "declared role '$role' is valid"
} catch {
    $null = Test-Rule 'C3-U3' $false -Requirement 'declared role is valid' `
        -Failure "role declaration invalid: $($_.Exception.Message)"
    Write-Summary -RoleLabel 'invalid' -Root $root
    exit 1
}

# ---- C3-U2: the root marker - EXEMPT at role subject, where C3-S1 asserts the inverse ----
if ($role -ne 'subject') {
    $null = Test-Rule 'C3-U2' (-not [string]::IsNullOrWhiteSpace($cfg.Config.project_id)) `
        -Requirement "project_id is populated ('$($cfg.Config.project_id)')" `
        -Failure 'project_id is null or empty - the root marker requires a stamped identity (a blueprint TEMPLATE config is not a workspace)'
}

if ($role -eq 'subject') {
    Test-SubjectContract -Root $root -Config $cfg.Config
    Write-Summary -RoleLabel $role -Root $root
    if ($script:Findings.Count -gt 0) { exit 1 }
    exit 0
}

$isProducer = $role -in @('framework', 'framework-builder')
$isReceiver = $role -in @('project', 'framework')

# ---- C3-U4 / C3-U5: the Read face ----
$readFace = Get-ProcessFrameworkPath -ProjectRoot $root
$readFaceRel = $readFace.Substring($root.Length).TrimStart('\', '/')
$readFaceOk = Test-Rule 'C3-U4' (Test-Path -LiteralPath $readFace -PathType Container) `
    -Requirement "Read face exists ($readFaceRel)" `
    -Failure "Read face directory missing: $readFaceRel (paths.process_framework or the default) - every session reads and runs from this tree"
if ($readFaceOk) {
    $null = Test-MemberSet -Rule 'C3-U5' -BaseDir $readFace -Members $SpineDirs -Label "Read face ($readFaceRel)"
}

# ---- C3-U6: root orientation ----
$null = Test-Rule 'C3-U6' (Test-Path -LiteralPath (Join-Path $root 'CLAUDE.md') -PathType Leaf) `
    -Requirement 'root CLAUDE.md exists' `
    -Failure 'root CLAUDE.md missing - the workspace orientation document every session loads'

# ---- Producer face (C3-P1 / C3-P2) ----
$producerFace = $null
if ($isProducer) {
    try {
        $producerFace = Get-BlueprintPath -ProjectRoot $root
    } catch {
        $null = Test-Rule 'C3-P1' $false -Requirement 'paths.blueprint declared and directory exists' `
            -Failure "producer face unresolvable: $($_.Exception.Message)"
    }
    if ($producerFace) {
        $producerFaceRel = $producerFace.Substring($root.Length).TrimStart('\', '/')
        $p1 = Test-Rule 'C3-P1' (Test-Path -LiteralPath $producerFace -PathType Container) `
            -Requirement "producer face exists ($producerFaceRel)" `
            -Failure "paths.blueprint names '$producerFaceRel' but the directory does not exist"
        if (-not $p1) { $producerFace = $null }
    }
    if ($producerFace) {
        $null = Test-MemberSet -Rule 'C3-P2' -BaseDir $producerFace -Members $SpineDirs -Label "producer face ($producerFaceRel)"
    }
}

# ---- Catalog face (C3-C1..C6): where this level AUTHORS its catalogs ----
$catalogFace = if ($role -eq 'project') { if ($readFaceOk) { $readFace } else { $null } } else { $producerFace }
$catalogFaceLabel = if ($role -eq 'project') { "Read face ($readFaceRel)" } elseif ($producerFace) { "producer face ($($producerFace.Substring($root.Length).TrimStart('\', '/')))" } else { '' }
if ($catalogFace) {
    foreach ($rule in $CatalogRules.Keys) {
        $member = $CatalogRules[$rule]
        $null = Test-Rule $rule (Test-Path -LiteralPath (Join-Path $catalogFace $member) -PathType Leaf) `
            -Requirement "$member at the catalog face" `
            -Failure "$member missing at the catalog face ($catalogFaceLabel) - the level authors its catalogs here"
    }
}

# ---- C3-E1: producer root entry point ----
if ($isProducer) {
    $null = Test-Rule 'C3-E1' (Test-Path -LiteralPath (Join-Path $root '.ai-entry-point.md') -PathType Leaf) `
        -Requirement 'root .ai-entry-point.md exists' `
        -Failure 'root .ai-entry-point.md missing - the session entry point at a producer workspace root'
}

# ---- Receiving-role rules (C3-R1..R4) ----
if ($isReceiver -and $readFaceOk) {
    $pointerPath = $null
    $pointerOk = $false
    try {
        $pointerPath = Get-ParentPointerFile -FrameworkDir $readFace
        $pointerOk = ($null -ne $pointerPath)
        $null = Test-Rule 'C3-R1' $pointerOk `
            -Requirement "parent pointer present at the Read face ($(if ($pointerPath) { Split-Path -Leaf $pointerPath }))" `
            -Failure 'no parent pointer at the Read face (probed .framework-parent-pointer and .framework-central-pointer) - central resolution and the chain walk depend on it; deployed by the parent''s Push'
    } catch {
        $null = Test-Rule 'C3-R1' $false -Requirement 'parent pointer present and both-name copies agree' `
            -Failure "parent pointer conflict: $($_.Exception.Message)"
    }
    if ($pointerOk) {
        $rawPointer = Get-Content -LiteralPath $pointerPath -Raw
        $target = if ($null -ne $rawPointer) { $rawPointer.Trim() } else { '' }
        $targetCentral = if ($target) { Join-Path $target 'process-framework-central' } else { '' }
        $null = Test-Rule 'C3-R2' ([bool]($target -and (Test-Path -LiteralPath $target -PathType Container) -and (Test-Path -LiteralPath $targetCentral -PathType Container))) `
            -Requirement "pointer target exists and holds process-framework-central/ ('$target')" `
            -Failure $(if (-not $target) { "parent pointer at $(Split-Path -Leaf $pointerPath) is empty" }
                       elseif (-not (Test-Path -LiteralPath $target)) { "pointer target '$target' does not exist - stale pointer" }
                       else { "pointer target '$target' has no process-framework-central/ - not a producer workspace" })
    }
    $null = Test-Rule 'C3-R3' (Test-Path -LiteralPath (Join-Path $readFace '.framework-version') -PathType Leaf) `
        -Requirement '.framework-version at the Read face' `
        -Failure '.framework-version missing at the Read face - the received-series stamp the parent''s Push writes per child'
    $null = Test-Rule 'C3-R4' (Test-Path -LiteralPath (Join-Path $readFace '.framework-version-previous') -PathType Leaf) `
        -Requirement '.framework-version-previous at the Read face' `
        -Failure '.framework-version-previous missing at the Read face - the rollback pin Restore-FrameworkVersion reads'
}

# ---- Project-only rules (C3-R5 / C3-N1) ----
if ($role -eq 'project') {
    $null = Test-MemberSet -Rule 'C3-R5' -BaseDir (Join-Path $root 'doc') -Members @('state-tracking/permanent', 'state-tracking/temporary') -Label 'doc/'
    $bpDeclared = [bool]($cfg.Config.paths -and -not [string]::IsNullOrWhiteSpace($cfg.Config.paths.blueprint))
    $null = Test-Rule 'C3-N1' (-not $bpDeclared) `
        -Requirement 'paths.blueprint not declared (a leaf has no producer face)' `
        -Failure "paths.blueprint is declared ('$($cfg.Config.paths.blueprint)') at role 'project' - a leaf workspace has no producer face of its own; framework artifacts are authored at the owning framework workspace"
}

# ---- Producer central rules (C3-P3 / C3-P4 / C3-P8) ----
if ($isProducer) {
    $central = Join-Path $root 'process-framework-central'
    $centralOk = Test-Path -LiteralPath $central -PathType Container
    if ($centralOk) {
        $null = Test-MemberSet -Rule 'C3-P3' -BaseDir $central -Members $CentralSpine -Label 'process-framework-central/'
        $reg = Get-ChildRegistryInfo -ProjectRoot $root
        $null = Test-MemberSet -Rule 'C3-P4' -BaseDir $central -Members @($reg.FileName, $reg.LedgerDirName) -Label "central (role-derived, $($reg.Role))"
        # C3-P11 (Advisory, PF-PRO-071 WI-9): the spine additions the creator scripts target
        # (New-FrameworkExtensionConcept / New-FrameworkEvaluationReport write here) — kept
        # out of the hard C3-P3 set until the fleet passes clean.
        $null = Test-MemberSet -Rule 'C3-P11' -BaseDir $central -Members @('proposals', 'evaluation-reports') `
            -Label 'process-framework-central/ (spine additions)' -Severity 'Advisory'
    } else {
        $null = Test-Rule 'C3-P3' $false -Requirement 'process-framework-central/ exists' `
            -Failure 'process-framework-central/ missing - a producer face owns its own central state (registries, tracking, rollout log)'
    }
    if ($readFaceOk) {
        $null = Test-Rule 'C3-P8' (Test-Path -LiteralPath (Join-Path $readFace 'payload-manifest.json') -PathType Leaf) `
            -Requirement 'payload-manifest.json at the Read face' `
            -Failure 'payload-manifest.json missing at the Read face - the payload filter, Sync-Substrate, and the ownership gate all consume it'
    }
}

# ---- Operating-file seeds (C3-P10 - PF-PRO-071 WI-4, Advisory) ----
if ($isProducer -and $producerFace) {
    $blueprintRoot = Split-Path -Parent $producerFace
    $bpRel = if ($blueprintRoot.Length -gt $root.Length) { $blueprintRoot.Substring($root.Length).TrimStart('\', '/') } else { '.' }
    $null = Test-MemberSet -Rule 'C3-P10' -BaseDir $blueprintRoot -Members @('CLAUDE.md', '.gitignore', '.claude/settings.json') `
        -Label "blueprint root ($bpRel) operating-file seeds" -Severity 'Advisory'
}

# ---- Agents channel (C3-R6 / C3-P9 / C3-P12 - PF-PRO-071 WI-2/WI-6, all Advisory) ----
# The mirror's geometry decides the sites: the framework-builder AUTHORS agents at its
# blueprint root's .claude/agents/ (Push's Invoke-AgentsMirror source); a receiving
# FRAMEWORK gets them at its workspace root's .claude/agents/ (the mirror target). A
# framework's own children are projects, which the channel-level role gate excludes — so no
# agents source dir is demanded at a mid-level framework (that would mandate an empty dir;
# revisit at promotion if a framework level ever gains framework-role children).
$manifestShipsAgents = $false
if ($readFaceOk) {
    $manifestPath = Join-Path $readFace 'payload-manifest.json'
    if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        try {
            $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
            if ($manifest.support_exceptions -and $manifest.support_exceptions.PSObject.Properties['agents']) {
                $manifestShipsAgents = $true
            }
        } catch { }   # unparsable manifest: agents rules read it as not-declared (C3-P8 owns presence)
    }
}
if ($role -eq 'framework') {
    $null = Test-Rule 'C3-R6' ((-not $manifestShipsAgents) -or (Test-Path -LiteralPath (Join-Path $root '.claude/agents') -PathType Container)) `
        -Requirement $(if ($manifestShipsAgents) { 'root .claude/agents/ exists (the received manifest ships the agents class)' }
                       else { 'received manifest ships no agents class (nothing to receive yet)' }) `
        -Failure 'the received manifest declares the agents payload class but root .claude/agents/ is missing - the mirror target for shipped agent instruments (re-receive via rollout, or investigate a partial receive)' `
        -Severity 'Advisory'
}
if ($role -eq 'framework-builder' -and $producerFace) {
    $agentsSource = Join-Path (Split-Path -Parent $producerFace) '.claude/agents'
    $null = Test-Rule 'C3-P9' ((-not $manifestShipsAgents) -or (Test-Path -LiteralPath $agentsSource -PathType Container)) `
        -Requirement $(if ($manifestShipsAgents) { 'blueprint .claude/agents/ exists (the agents-mirror source)' }
                       else { 'manifest ships no agents class (no source dir demanded)' }) `
        -Failure 'payload-manifest.json declares the agents class but the blueprint .claude/agents/ source dir is missing - Invoke-AgentsMirror would mirror nothing while the manifest declares the channel' `
        -Severity 'Advisory'
    # C3-P12: the Q5 root-projection identity rule — at the one workspace whose canonical
    # (blueprint) and operative (root, agent-discovery walk-up) agent locations differ, the
    # two copies must not drift silently. The blueprint copy is canonical.
    if (Test-Path -LiteralPath $agentsSource -PathType Container) {
        $rootAgents = Join-Path $root '.claude/agents'
        $drift = [System.Collections.Generic.List[string]]::new()
        $srcFiles = @(Get-ChildItem -LiteralPath $agentsSource -Recurse -File)
        foreach ($f in $srcFiles) {
            $rel = $f.FullName.Substring($agentsSource.Length).TrimStart('\', '/')
            $twin = Join-Path $rootAgents $rel
            if (-not (Test-Path -LiteralPath $twin -PathType Leaf)) { $drift.Add("$rel (missing at root)") }
            elseif ((Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $twin -Algorithm SHA256).Hash) { $drift.Add("$rel (content differs)") }
        }
        if (Test-Path -LiteralPath $rootAgents -PathType Container) {
            foreach ($f in @(Get-ChildItem -LiteralPath $rootAgents -Recurse -File)) {
                $rel = $f.FullName.Substring($rootAgents.Length).TrimStart('\', '/')
                if (-not (Test-Path -LiteralPath (Join-Path $agentsSource $rel) -PathType Leaf)) { $drift.Add("$rel (root-only - absent from the canonical blueprint dir)") }
            }
        }
        $null = Test-Rule 'C3-P12' ($drift.Count -eq 0) `
            -Requirement "root .claude/agents/ is an identical projection of the blueprint agents dir ($($srcFiles.Count) file(s))" `
            -Failure "root .claude/agents/ has drifted from the canonical blueprint/.claude/agents/: $($drift -join '; ') - re-project (copy the blueprint dir over the root dir; the blueprint copy is canonical)" `
            -Severity 'Advisory'
    } else {
        $null = Test-Rule 'C3-P12' $true -Requirement 'no blueprint agents dir - no root projection required' -Severity 'Advisory'
    }
}

# ---- Face-relationship rules (C3-P5 / C3-P6 / C3-P7) ----
if ($readFaceOk -and $producerFace) {
    $readCanon = ConvertTo-CanonicalWorkspacePath -Path $readFace
    $prodCanon = ConvertTo-CanonicalWorkspacePath -Path $producerFace
    if ($role -eq 'framework') {
        $null = Test-Rule 'C3-P5' ($readCanon -ine $prodCanon) `
            -Requirement 'faces diverge (consumer face received, producer face authored)' `
            -Failure "both face keys name one tree ('$readFaceRel') at role 'framework' - the pre-cutover degenerate state; a framework receives its consumer face from its parent and authors its own producer face"
    }
    if ($role -eq 'framework-builder') {
        $null = Test-Rule 'C3-P6' ($readCanon -ieq $prodCanon) `
            -Requirement 'faces identical (self-hosted by design)' `
            -Failure "the consumer and producer keys name different trees at role 'framework-builder' - the framework-builder is self-hosted by design (its consumer face IS its producer face)"
    }
}
if ($role -eq 'framework-builder' -and $readFaceOk) {
    $fbPointer = $null
    try { $fbPointer = Get-ParentPointerFile -FrameworkDir $readFace } catch {
        $null = Test-Rule 'C3-P7' $false -Requirement 'face parent pointer, if present, is a self-pointer' `
            -Failure "parent pointer conflict at the face: $($_.Exception.Message)"
        $fbPointer = 'conflict'
    }
    if ($fbPointer -ne 'conflict') {
        if ($null -eq $fbPointer) {
            $null = Test-Rule 'C3-P7' $true -Requirement 'no parent pointer at the face (a never-pushed-to root is a legitimate chain termination)'
        } else {
            $rawSelf = Get-Content -LiteralPath $fbPointer -Raw
            $selfTarget = if ($null -ne $rawSelf) { $rawSelf.Trim() } else { '' }
            $selfCanon = ConvertTo-CanonicalWorkspacePath -Path $selfTarget
            $rootCanon = ConvertTo-CanonicalWorkspacePath -Path $root
            $null = Test-Rule 'C3-P7' ($selfCanon -ieq $rootCanon) `
                -Requirement "face parent pointer is a self-pointer ('$selfTarget')" `
                -Failure "the face parent pointer targets '$selfTarget', not this workspace - the chain root must carry a SELF-pointer (or none); a foreign target makes the chain walk resolve past the root"
        }
    }
}

Write-Summary -RoleLabel $role -Root $root
if ($script:Findings.Count -gt 0) { exit 1 }
exit 0
