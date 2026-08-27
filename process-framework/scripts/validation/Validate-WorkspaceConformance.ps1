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

      Universal (roles project / framework / framework-builder)
        C3-U1  doc/project-config.json exists and parses   (Get-ProjectRoot pass-1 anchor)
        C3-U2  project_id non-empty                        (root-marker requirement)
        C3-U3  declared role valid                         (Get-WorkspaceRole contract)
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

    Role 'subject' has no shape contract defined yet - reported loudly, exit 0 (dormant),
    per the fleet's dormant-state convention. Missing-face cascades are suppressed: when a
    face directory is absent its content rules are skipped rather than reported N times.

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
$script:RulesEvaluated = 0

function Test-Rule {
    # Records one rule outcome. -Requirement is the asserted fact (printed under -Detailed
    # on pass); -Failure is the finding text (defaults to the requirement).
    param(
        [Parameter(Mandatory)][string]$Rule,
        [Parameter(Mandatory)][bool]$Passed,
        [Parameter(Mandatory)][string]$Requirement,
        [string]$Failure
    )
    $script:RulesEvaluated++
    if ($Passed) {
        if ($Detailed) { Write-Host "  [PASS] [$Rule] $Requirement" }
    } else {
        $text = if ($Failure) { $Failure } else { $Requirement }
        $script:Findings.Add("[$Rule] $text")
        Write-Host "  [FAIL] [$Rule] $text"
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
        [Parameter(Mandatory)][string]$Label
    )
    $missing = @($Members | Where-Object { -not (Test-Path -LiteralPath (Join-Path $BaseDir $_)) })
    return Test-Rule -Rule $Rule -Passed ($missing.Count -eq 0) `
        -Requirement "$Label carries: $($Members -join ', ')" `
        -Failure "$Label is missing: $($missing -join ', ')"
}

function Write-Summary {
    param([Parameter(Mandatory)][string]$RoleLabel, [Parameter(Mandatory)][string]$Root)
    Write-Host ""
    if ($script:Findings.Count -eq 0) {
        Write-Host "[OK] Validate-WorkspaceConformance: role '$RoleLabel' at '$Root' - $($script:RulesEvaluated) rules evaluated, 0 findings. Conformant."
    } else {
        Write-Host "[FAIL] Validate-WorkspaceConformance: role '$RoleLabel' at '$Root' - $($script:RulesEvaluated) rules evaluated, $($script:Findings.Count) finding(s)."
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
$null = Test-Rule 'C3-U2' (-not [string]::IsNullOrWhiteSpace($cfg.Config.project_id)) `
    -Requirement "project_id is populated ('$($cfg.Config.project_id)')" `
    -Failure 'project_id is null or empty - the root marker requires a stamped identity (a blueprint TEMPLATE config is not a workspace)'

# ---- C3-U3: declared role ----
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

if ($role -eq 'subject') {
    Write-Host "Validate-WorkspaceConformance: role 'subject' has no shape contract defined yet - nothing to check (dormant). Exit 0."
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
