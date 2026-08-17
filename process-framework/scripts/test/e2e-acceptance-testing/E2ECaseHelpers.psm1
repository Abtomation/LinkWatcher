<#
.SYNOPSIS
Shared prologue helpers for E2E acceptance-test case scripts — sandbox resolution through the
workspace's own child-registry shape.

.DESCRIPTION
Every sandbox-everywhere E2E case (`run.ps1`) opens by resolving the producer root and then the
sandbox it mutates. Measured at PF-PRO-068 S3 Session 30: that second half was a 16-line block
duplicated BYTE-IDENTICALLY across 8 of appdev's 9 remaining run scripts, and it hard-coded three
things a producer face may not assume — the registry filename (`project-registry.json`), its
top-level collection key (`projects`), and the central directory layout.

Hard-coding those is the failure P-14 already paid for once: re-keying the sandbox rows
(`PRJ-T01` -> `APP-T01`) hand-edited 27 files. `Get-ChildRegistryInfo` (P-10) exists precisely so a
level's registry differences travel as DATA; this module is how the E2E harness consumes it.

Deliberately NOT extracted: the producer-root walk that precedes this. It is the bootstrap that
LOCATES this module, so it cannot itself live here — and it is the inert half, being pure stdlib
with no literal that ever changes. The fragile half is extracted; the inert half stays inline.

SUBSTRATE CLASS: unlisted in payload-manifest.json support_exceptions.scripts, exactly like its
sibling Reset-SandboxFixtures.ps1, so it ships to every child. That is deliberate — the E2E harness
is substrate at every level. `Get-ChildRegistryInfo` throws at a leaf role by contract, which is
correct here: a leaf has no children and therefore no sandbox row to resolve.

.NOTES
Created at PF-PRO-068 Sub-concept 3, Session 30 (2026-08-13), unit E4/D2.
#>

$script:E2EHelperRoot = $PSScriptRoot

# Import Common-ScriptHelpers EXPLICITLY rather than relying on the caller having imported it.
# Measured (S30 probes D/E): the orchestrator invokes each run.ps1 with the call operator IN-SESSION,
# so a run.ps1 inherits the orchestrator's imported modules and a helper depending on that inheritance
# works orchestrated and breaks standalone — the identical defect class as the stale $LASTEXITCODE
# guard this same session fixed. An explicit import makes standalone and orchestrated runs identical.
$commonHelpers = Join-Path -Path $PSScriptRoot -ChildPath '../../../scripts/Common-ScriptHelpers.psm1'
try {
    $resolvedCommon = Resolve-Path $commonHelpers -ErrorAction Stop
    Import-Module $resolvedCommon -Force
} catch {
    throw "E2ECaseHelpers: failed to import Common-ScriptHelpers from '$commonHelpers' ($($_.Exception.Message)). Get-ChildRegistryInfo is required to resolve the child-registry shape."
}

function Get-E2ESandboxRoot {
    <#
    .SYNOPSIS
    Resolves an E2E sandbox child's on-disk root from the producer's child registry.

    .DESCRIPTION
    Replaces the hand-rolled registry block that opened 8 of appdev's E2E run scripts. Behaviour is
    that block's, with one generalization: the registry filename and collection key come from
    Get-ChildRegistryInfo (role-derived) instead of appdev's literals, so the same harness serves any
    producer face.

    Central is composed from -ProducerRoot rather than resolved through Get-CentralFrameworkPath.
    That is deliberate and behaviour-preserving: the block being replaced hard-composed the path, so
    it was immune to $env:FRAMEWORK_CENTRAL_OVERRIDE — and several cases (TE-E2E-011) set that
    override for their SUBJECT while still needing the real producer's registry to find the sandbox.
    Routing this lookup through the override would silently redirect it into the per-test fixture.

    Fails with a throw, never `exit`: a module function cannot exit its caller reliably, and every
    E2E run script sets $ErrorActionPreference='Stop'. Verified equivalent in both invocation modes —
    standalone (`pwsh -File`) a throw exits 1, and the orchestrator wraps its call-operator invocation
    in try/catch and counts the throw as a failure. No remaining case declares a non-zero expected
    exit code, so a throw and the former `exit 1` are indistinguishable to every caller.

    .PARAMETER ProducerRoot
    The producer workspace root (the directory holding doc/project-config.json), as resolved by the
    caller's bootstrap walk.

    .PARAMETER SandboxKey
    The child-registry row key for the sandbox (e.g. 'APP-T01').

    .OUTPUTS
    String — the sandbox's absolute root path, verified to exist on disk.

    .EXAMPLE
    $sandboxRoot = Get-E2ESandboxRoot -ProducerRoot $producerRoot -SandboxKey 'APP-T01'
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProducerRoot,

        [Parameter(Mandatory=$true)]
        [string]$SandboxKey
    )

    if (-not (Test-Path $ProducerRoot)) {
        throw "Get-E2ESandboxRoot: producer root does not exist: $ProducerRoot"
    }

    # Role-derived registry shape (P-10) — never appdev's literals.
    $registryInfo = Get-ChildRegistryInfo -ProjectRoot $ProducerRoot

    $registryPath = Join-Path $ProducerRoot (Join-Path 'process-framework-central' $registryInfo.FileName)
    if (-not (Test-Path $registryPath)) {
        throw "Get-E2ESandboxRoot: $($registryInfo.FileName) not found at: $registryPath"
    }

    $registry = Get-Content $registryPath -Raw | ConvertFrom-Json
    $collection = $registry.($registryInfo.CollectionKey)
    if (-not $collection) {
        throw "Get-E2ESandboxRoot: $registryPath has no '$($registryInfo.CollectionKey)' collection (role '$($registryInfo.Role)')."
    }

    $entry = $collection.$SandboxKey
    if (-not $entry -or -not $entry.path) {
        throw "Get-E2ESandboxRoot: '$SandboxKey' entry missing or has no 'path' field in $registryPath"
    }

    if (-not (Test-Path $entry.path)) {
        throw "Get-E2ESandboxRoot: '$SandboxKey' sandbox path does not exist on disk: $($entry.path)"
    }

    return $entry.path
}

Export-ModuleMember -Function Get-E2ESandboxRoot
