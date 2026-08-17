<#
.SYNOPSIS
    Warn-first gate that every file the workspace ships carries its N-5 ownership line,
    resolved through Get-ArtifactOwnerId against the payload manifest's per-language
    conventions (PF-PRO-068 Session E3; banner half of the N-4/N-5 gate pair).

.DESCRIPTION
    The manifest's ownership_line_conventions block declares one ownership line per language
    (PowerShell .NOTES line, Python header comment, markdown owned_by frontmatter, JSON
    metadata.owned_by). This gate walks the producer blueprint — the tree the workspace ships —
    and asserts each shippable file resolves to the expected owner via Get-ArtifactOwnerId
    (Core.psm1), which reads only the file's LEADING header region, so a guide that documents
    the convention never reports itself as owned by the ID its example names (the reason this
    gate consumes the helper rather than a pattern count — PF-PRO-068 Session 5 Issue 5).

    Scope and expectations by face:
      - Self-hosted authoring root (FB — consumer and producer keys name one tree): every file
        under the blueprint framework tree and the shipped skills, minus the manifest's
        per_level_files and the allowlist below, must carry the workspace's OWN project_id.
      - Framework face (faces split, post-cutover): only RECEIVED files (those present in the
        consumer tree) are checked in the blueprint — they must carry an ownership line naming
        an ID other than this workspace's own (received copies state their upstream owner);
        the framework's own domain files carry no N-5 obligation.
      - Leaf workspace, or no manifest at either face: dormant (exit 0, one loud line).

    ALLOWLIST (recorded at PF-PRO-068 Session B when the lines were authored; each entry is an
    instantiation template whose content leaks verbatim into workspace-owned instances, or a
    JSON with no metadata carrier — the manifest's json convention: "otherwise exempt (noted
    per file in the gate's allowlist)"):
      - templates/support/document-creation-script-template.ps1   (instantiated into project scripts)
      - templates/support/update-script-template.ps1              (instantiated into project scripts)
      - templates/support/Run-Tests-runner-template.ps1           (instantiated into project runners)
      - templates/support/language-config-template.json           (copied per language)
      - templates/support/feedback-db-input-template.json         (copied per filing)
      - templates/03-testing/test-file-template.py.template       (instantiated into project tests)
      - tools/linkWatcher/.linkwatcher-ignore.template            (copied per project)
      - payload-manifest.json                                     (self-describing manifest)
      - languages-config/*/-config.json                           (no metadata carrier)
      - scripts/test/e2e-acceptance-testing/sandbox-reset-registry.json (no metadata carrier)
    Markdown templates are NOT exempt: template frontmatter is stripped at instantiation
    (Get-TemplateContentWithoutMetadata), so their owned_by cannot leak.

    File types with no ownership convention (.gitkeep, .gitignore, plain .txt/.yaml/.yml
    configs, .csv, .xml, images) are skipped — only .ps1/.psm1/.psd1/.py/.md/.json carry lines.

.PARAMETER Blocking
    Exit 1 on findings instead of the warn-first exit 0.

.PARAMETER ProjectRoot
    Workspace root override for test fixtures (defaults to the resolved project root).

.EXAMPLE
    Check-OwnershipLines.ps1
    # Warn-first sweep (pre-commit form)

.EXAMPLE
    Check-OwnershipLines.ps1 -Blocking
    # Gate form: exit 1 on any missing/disagreeing ownership line

.NOTES
    PF-PRO-068 S3 E3 (Session 16). Read-only validator — not soak-enrolled (validator class,
    fleet convention). The hash half of the N-4 pair is Sync-Substrate.ps1 -Check.
#>

[CmdletBinding()]
param(
    [switch]$Blocking,

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'

# Import the common helpers (Get-ProjectRoot / Get-BlueprintPath / Get-ArtifactOwnerId)
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

$AllowlistExact = @(
    'templates/support/document-creation-script-template.ps1',
    'templates/support/update-script-template.ps1',
    'templates/support/Run-Tests-runner-template.ps1',
    'templates/support/language-config-template.json',
    'templates/support/feedback-db-input-template.json',
    'templates/03-testing/test-file-template.py.template',
    'tools/linkWatcher/.linkwatcher-ignore.template',
    'payload-manifest.json',
    'scripts/test/e2e-acceptance-testing/sandbox-reset-registry.json'
)
$AllowlistPatterns = @(
    '^languages-config/[^/]+/[^/]+-config\.json$'
)
$CarrierExtensions = @('.ps1', '.psm1', '.psd1', '.py', '.md', '.json')

$root = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { Get-ProjectRoot } else { $ProjectRoot }
$configPath = Join-Path -Path $root -ChildPath "doc/project-config.json"
if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Check-OwnershipLines: no doc/project-config.json at '$root' — cannot resolve the workspace's faces."
}
try {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
} catch {
    throw "Check-OwnershipLines: doc/project-config.json at '$configPath' could not be parsed ($($_.Exception.Message))."
}

$role = if ($config.project_metadata -and $config.project_metadata.role) { $config.project_metadata.role } else { 'project' }
if ($role -eq 'project') {
    Write-Host "Check-OwnershipLines: leaf workspace (role 'project') — no producer face; nothing to check. Exit 0."
    exit 0
}
$ownId = $config.project_id

$consumerRel = if ($config.paths -and $config.paths.process_framework) { $config.paths.process_framework } else { 'process-framework' }
$consumer = [System.IO.Path]::GetFullPath((Join-Path -Path $root -ChildPath $consumerRel)).TrimEnd('\', '/')
$producer = [System.IO.Path]::GetFullPath((Get-BlueprintPath -ProjectRoot $root)).TrimEnd('\', '/')
$selfHosted = ($consumer -ieq $producer)

$manifestPath = Join-Path -Path $producer -ChildPath "payload-manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath) -and -not $selfHosted) {
    $manifestPath = Join-Path -Path $consumer -ChildPath "payload-manifest.json"
}
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Write-Host "Check-OwnershipLines: no payload-manifest.json at either face — no ownership conventions are declared for this workspace yet (pre-first-rollout, or the manifest has not been authored). Gate dormant. Exit 0."
    exit 0
}
try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
} catch {
    throw "Check-OwnershipLines: payload-manifest.json at '$manifestPath' could not be parsed ($($_.Exception.Message))."
}
# Per-level files are authored at EVERY level, so they never carry the producer's ownership line.
# BOTH manifest blocks count: per_level_files (all target roles) and framework_level_files (the
# catalogs and registry a framework face authors for itself — split out of the flat list at
# PF-PRO-068 S3 E4-b). Reading only the first re-flags every file the split moved, which is exactly
# what this gate caught when the split landed.
$perLevel = @()
if ($manifest.per_level_files -and $manifest.per_level_files.paths) {
    $perLevel += @($manifest.per_level_files.paths)
}
if ($manifest.framework_level_files -and $manifest.framework_level_files.paths) {
    $perLevel += @($manifest.framework_level_files.paths)
}

function Test-Allowlisted {
    param([string]$Rel)
    if ($Rel -in $AllowlistExact) { return $true }
    foreach ($p in $AllowlistPatterns) {
        if ($Rel -match $p) { return $true }
    }
    return $false
}

# Scan set: the producer blueprint framework tree, plus the shipped skills folder beside it.
$scanRoots = @($producer)
$skillsDir = Join-Path -Path (Split-Path -Parent $producer) -ChildPath ".claude/skills"
if (Test-Path -LiteralPath $skillsDir) { $scanRoots += [System.IO.Path]::GetFullPath($skillsDir).TrimEnd('\', '/') }

$findings = @()
$checked = 0
$skipped = 0
foreach ($scanRoot in $scanRoots) {
    $isSkills = ($scanRoot -ne $producer)
    foreach ($file in (Get-ChildItem -LiteralPath $scanRoot -Recurse -File)) {
        $rel = $file.FullName.Substring($scanRoot.Length).TrimStart('\', '/').Replace('\', '/')
        if ($isSkills) { $rel = ".claude/skills/$rel" }
        if ($file.Extension -eq '.pyc' -or $rel -match '(^|/)__pycache__/' -or $rel -match '(^|/)\.git/') { continue }
        if (-not $isSkills -and ($rel -in $perLevel)) { $skipped++; continue }
        if (Test-Allowlisted -Rel $rel) { $skipped++; continue }
        # Carrier check on the real payload extension (.py.template ends .template — allowlisted above).
        if ($file.Extension -notin $CarrierExtensions) { $skipped++; continue }

        if (-not $selfHosted -and -not $isSkills) {
            # Framework face: only RECEIVED files (present in the consumer tree) carry the
            # N-5 obligation; the workspace's own domain files do not.
            $consumerTwin = Join-Path -Path $consumer -ChildPath $rel
            if (-not (Test-Path -LiteralPath $consumerTwin)) { $skipped++; continue }
        }

        $owner = Get-ArtifactOwnerId -Path $file.FullName
        $checked++
        if ($selfHosted) {
            if ($owner -ne $ownId) {
                $findings += "{0} — expected owner '{1}', found {2}" -f $rel, $ownId, $(if ($null -eq $owner) { 'NO ownership line' } else { "'$owner'" })
            }
        } else {
            if ($null -eq $owner) {
                $findings += "{0} — received file carries NO ownership line (upstream authoring gap)" -f $rel
            } elseif ($owner -eq $ownId) {
                $findings += "{0} — received file claims THIS workspace ('{1}') as owner; received copies state their upstream owner" -f $rel, $ownId
            }
        }
    }
}

Write-Host "Check-OwnershipLines: checked=$checked skipped=$skipped findings=$($findings.Count) (face: $(if ($selfHosted) { 'self-hosted authoring root' } else { 'framework face, received set' }), expected owner: $(if ($selfHosted) { $ownId } else { 'upstream (non-' + $ownId + ')' }))"
if ($findings.Count -eq 0) {
    Write-Host "✅ Every shippable file carries its N-5 ownership line."
    exit 0
}
foreach ($f in $findings) { Write-Warning $f }
if ($Blocking) {
    Write-Error "Check-OwnershipLines: $($findings.Count) file(s) violate the N-5 ownership-line convention (see warnings above). Author the line per payload-manifest.json ownership_line_conventions, or record a genuine instantiation-template exemption in this gate's allowlist."
    exit 1
}
Write-Host "⚠️  Warn-first mode: findings reported, exit 0. Use -Blocking to gate."
exit 0
