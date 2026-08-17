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

function Get-NormalizedFileHash {
    param([Parameter(Mandatory = $true)][string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes -contains 0) {
        # Binary: raw hash — CRLF bytes inside binary content are data, not line endings.
        $ms = [System.IO.MemoryStream]::new($bytes)
    } else {
        $text = [System.Text.Encoding]::UTF8.GetString($bytes).Replace("`r`n", "`n")
        $ms = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($text))
    }
    try {
        return (Get-FileHash -InputStream $ms -Algorithm SHA256).Hash
    } finally {
        $ms.Dispose()
    }
}

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

# Enumerate the received set: everything under the consumer face minus per-level files and
# mirror hygiene exclusions.
$received = @(Get-ChildItem -LiteralPath $consumerFull -Recurse -File | Where-Object {
        $rel = $_.FullName.Substring($consumerFull.Length).TrimStart('\', '/').Replace('\', '/')
        ($rel -notin $perLevel) -and
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
    Write-Error "Sync-Substrate -Check: the producer blueprint has diverged from the received payload ($($missing.Count) missing, $($drifted.Count) drifted). A drifted copy must not ship — run Sync-Substrate.ps1 to re-project, or investigate the edit (received files are parent-owned; an agent may only modify files its workspace owns)."
    exit 1
}

# Sync mode: additive projection consumer -> blueprint (byte-exact copies).
$synced = 0
foreach ($rel in ($missing + $drifted)) {
    $src = Join-Path -Path $consumerFull -ChildPath $rel
    $dst = Join-Path -Path $producerFull -ChildPath $rel
    if ($PSCmdlet.ShouldProcess($dst, "Project received file into blueprint (from $src)")) {
        $dstDir = Split-Path -Parent $dst
        if (-not (Test-Path -LiteralPath $dstDir)) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $src -Destination $dst -Force
        $synced++
    }
}
Write-Host "Sync-Substrate: received=$($received.Count) clean=$clean projected=$synced (missing $($missing.Count) + drifted $($drifted.Count))."
exit 0
