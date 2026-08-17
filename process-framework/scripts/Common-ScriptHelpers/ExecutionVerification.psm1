# ExecutionVerification.psm1
# Soak-verification helpers for newly created or recently modified PowerShell scripts.

<#
.SYNOPSIS
Soak-verification helpers for newly created or recently modified PowerShell scripts.
#>
#
# VERSION 2.3 - PF-PRO-068 WI-5 ownership-aware soak resolution (PF-TSK-026)
# Implements PF-PRO-028 v2.0 (Script Self-Verification) — see
# appdev/process-framework-central/proposals/old/script-self-verification.md.
#
# v2.3 changes (2026-08-07, PF-PRO-068 WI-5):
#   - Soak state resolves to the central of the workspace that OWNS the script,
#     not the one that invoked it: _Get-SoakStateFilePath / _Read-SoakStateRaw /
#     _Write-SoakStateRaw take -ScriptPath and route through
#     Get-OwningWorkspaceCentralPath (Core.psm1), which reads the script's N-5
#     ownership line. A soak counter verifies one canonical script; keying its row
#     to the caller splits that counter per consumer AND lets a received copy
#     register a fresh row at each consumer — so a fleet-wide script reads as
#     "never soaked" everywhere but its owner, silently.
#   - An UNMARKED script (no ownership line) resolves to the caller's own central,
#     which is byte-for-byte the pre-v2.3 behavior. appdev's blueprint carries no
#     ownership lines until the cutover ships them, so this change is DARK on both
#     live trees today.
#   - Get-SoakStatus -ScriptId is ownership-aware; the unfiltered dump stays
#     own-registry (documented in its .NOTES).
#
# v2.2 changes (2026-05-29, PF-IMP-904):
#   - Synthetic-test bypass: when $env:PF_SOAK_DISABLE is truthy ('1'/'true'/'yes';
#     '0'/'false'/'no'/unset = off), Register-SoakScript / Test-ScriptInSoak /
#     Confirm-SoakInvocation short-circuit before any state read/write — mirroring
#     the existing -WhatIf bypass. Stops test-harness invocations (e.g. running a
#     soak-armored script against a -TestRoot sandbox) from advancing the real soak
#     counter, so soak validates real consumer usage. Set automatically for the
#     duration of a Pester run by Run-Tests.powershell.ps1; set explicitly by agents
#     doing ad-hoc synthetic-fixture testing. Independent of FRAMEWORK_CENTRAL_OVERRIDE
#     (which redirects soak state to a sandbox file rather than suppressing counting).
#
# v2.1 changes (2026-05-12, PF-PRO-032):
#   - State file moved from blueprint/process-framework/state-tracking/permanent/ to
#     process-framework-central/state-tracking/permanent/. Soak state is now genuinely
#     cross-project rather than per-project.
#   - _Get-SoakStateFilePath resolves via Get-CentralFrameworkPath instead of
#     Get-ProcessFrameworkPath.
#   - _Resolve-CallingScript strips the framework-path prefix from the resolved Script
#     ID so the same script bytes resolve to the same row regardless of cwd
#     (blueprint/process-framework/scripts/X.ps1 from appdev and
#     process-framework/scripts/X.ps1 from a rolled-out project both → scripts/X.ps1).
#     Scripts living outside the framework path (e.g. process-framework-central/scripts/...)
#     keep their full relative path.
#
# v2.0 changes (PF-IMP-728):
#   - $DefaultSoakCounter parameterized (default 3, was hardcoded 5).
#   - Caller-aware mode: Register-SoakScript / Test-ScriptInSoak / Confirm-SoakInvocation
#     now accept zero positional args. When called without -ScriptId/-ScriptPath, the
#     helper resolves the calling .ps1 from Get-PSCallStack — enabling helper-routed
#     armoring (one edit to a shared helper module covers many calling scripts, each
#     getting its own per-script soak entry).
#   - Backward compatible: existing callers passing -ScriptId/-ScriptPath explicitly are unchanged.
#
# Concept: every newly registered or hash-changed script must be confirmed by
# the agent over $DefaultSoakCounter consecutive successful invocations before it is
# considered soak-complete. Failures or script-body changes reset the counter to
# $DefaultSoakCounter. WhatIf invocations — and invocations where
# $env:PF_SOAK_DISABLE is truthy (synthetic-fixture / test-harness runs, PF-IMP-904)
# — bypass the soak entirely (no decrement, no state write).
#
# Public functions (4):
#   Register-SoakScript      - add a script to the soak registry
#   Test-ScriptInSoak        - is the caller still in soak? (auto-resets on hash change)
#   Confirm-SoakInvocation   - record success/failure outcome of a soak invocation
#   Get-SoakStatus           - inspect the registry (all rows or one row)
#
# State file: process-framework-central/state-tracking/permanent/script-soak-tracking.md
#             (v2.1; was process-framework/state-tracking/... pre-2026-05-12)
# Dependencies (imported at module top below — PF-IMP-1165 — so this module also works when
# imported directly, not only via the Common-ScriptHelpers facade load order):
#   - Get-ProjectRoot           (Core.psm1)
#   - Get-CentralFrameworkPath  (Core.psm1) — v2.1: replaces Get-ProcessFrameworkPath for soak state file
#   - Get-OwningWorkspaceCentralPath (Core.psm1) — v2.3: ownership-aware soak state resolution
#   - Get-ProcessFrameworkPath  (Core.psm1) — v2.1: still used by _Resolve-CallingScript for prefix stripping
#   - Get-ProjectConfig         (Core.psm1) — v2.1: read paths.process_framework for prefix stripping
#   - Assert-LineInFile         (FileOperations.psm1) — used internally for read-after-write verification

$PSDefaultParameterValues['*:Encoding'] = 'UTF8'

# Import dependencies at module top — consistent with the other Common-ScriptHelpers
# sub-modules (e.g. DocumentManagement.psm1) and the quick-reference sub-module-scoping
# pattern — so Core / FileOperations resolve whether this module is imported directly or
# via the Common-ScriptHelpers facade (PF-IMP-1165). Idempotent under the facade load
# (-Force re-import), matching the established pattern.
$scriptPath    = Split-Path -Parent $PSScriptRoot
$coreModule    = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers/Core.psm1"
$fileOpsModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers/FileOperations.psm1"
$tableOpsModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers/TableOperations.psm1"
if (Test-Path $coreModule)     { Import-Module $coreModule -Force }
if (Test-Path $fileOpsModule)  { Import-Module $fileOpsModule -Force }
if (Test-Path $tableOpsModule) { Import-Module $tableOpsModule -Force }

# Module-level default soak counter. Lowered from 5 to 3 in v2.0 (PF-IMP-728)
# based on observed behavior: deterministic defects in state-mutating scripts
# dominate intermittent ones, so 3 successful invocations is sufficient sample.
# See PF-PRO-028 v2.0 Lessons Learned section for full rationale.
$script:DefaultSoakCounter = 3

# ============================================================================
# Module-private helpers (not exported)
# ============================================================================

function _Get-SoakStateFilePath {
    # v2.1 (PF-PRO-032): soak state file lives in central — one canonical copy rather than a
    # per-project one. Resolved via Get-CentralFrameworkPath:
    #   - From cwd=appdev: <appdev>/process-framework-central/state-tracking/permanent/...
    #   - From cwd=project: reads <project>/process-framework/.framework-central-pointer
    #                       and returns <appdev>/process-framework-central/state-tracking/permanent/...
    # Pre-v2.1 location was <fw-path>/state-tracking/permanent/... (per-project copy).
    #
    # v2.3 (PF-PRO-068 WI-5) — OWNERSHIP-AWARE. A soak counter verifies one canonical SCRIPT,
    # so its row belongs to the workspace that OWNS that script, not to whichever workspace
    # happened to invoke a received copy. Caller-keyed resolution splits one counter across
    # every consumer and — the failure this closes — lets a received copy register a FRESH row
    # at each consumer, so a fleet-wide script reads as "never soaked" in every workspace but
    # its owner's, silently.
    #
    # When -ScriptPath is supplied, resolution goes through Get-OwningWorkspaceCentralPath,
    # which reads the script's N-5 ownership line. An UNMARKED script resolves to the caller's
    # own central — identical to pre-v2.3 behavior — which is why this is dark until the
    # cutover ships ownership lines into consumer trees. Callers with no path in hand (the
    # unfiltered Get-SoakStatus dump) keep own-central resolution.
    param([string]$ScriptPath)

    $central = if ($ScriptPath) {
        Get-OwningWorkspaceCentralPath -ArtifactPath $ScriptPath
    } else {
        Get-CentralFrameworkPath
    }
    return (Join-Path -Path $central -ChildPath "state-tracking/permanent/script-soak-tracking.md")
}

function _Get-SoakScriptHash {
    param([Parameter(Mandatory=$true)][string]$ScriptPath)
    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        throw "ExecutionVerification: script file not found at '$ScriptPath'"
    }
    return (Get-FileHash -LiteralPath $ScriptPath -Algorithm SHA256).Hash
}

function _Read-SoakStateRaw {
    # -ScriptPath threads through to ownership-aware resolution (v2.3); omitted = own central.
    param([string]$ScriptPath)
    $path = _Get-SoakStateFilePath -ScriptPath $ScriptPath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "ExecutionVerification: soak tracking file not found at '$path'. The file is created by Phase 3 of PF-TSK-026 (Script Self-Verification)."
    }
    return [System.IO.File]::ReadAllText($path, [System.Text.UTF8Encoding]::new($false))
}

function _Write-SoakStateRaw {
    # The read and the write of one operation MUST resolve the same file — pass the same
    # -ScriptPath to both, or the update lands in a different workspace's registry (v2.3).
    param(
        [Parameter(Mandatory=$true)][string]$Content,
        [string]$ScriptPath
    )
    $path = _Get-SoakStateFilePath -ScriptPath $ScriptPath
    [System.IO.File]::WriteAllText($path, $Content, [System.Text.UTF8Encoding]::new($false))
    # Read-after-write verification using the Phase 2 helper. Catches truncated /
    # garbled writes at the moment of the bad write.
    Assert-LineInFile -Path $path -Pattern '## Registered Scripts' -Context 'soak state file write'
    Assert-LineInFile -Path $path -Pattern '## Update History'     -Context 'soak state file write'
}

function _Get-LineEnding {
    param([Parameter(Mandatory=$true)][string]$Content)
    if ($Content -match "`r`n") { return "`r`n" } else { return "`n" }
}

function _Test-CallerWhatIf {
    # Module functions have isolated SessionState — the module-local $WhatIfPreference
    # does NOT inherit from a caller script that was invoked with -WhatIf. Read the
    # caller's $WhatIfPreference explicitly via $PSCmdlet.SessionState (which references
    # the CALLER's session state when this helper is invoked from a public function).
    param([Parameter(Mandatory=$true)]$Cmdlet)
    if ($null -eq $Cmdlet) { return $false }
    try {
        return [bool]$Cmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
    } catch {
        return $false
    }
}

function _Test-SoakDisabled {
    # Synthetic-test bypass (PF-IMP-904). Returns $true when $env:PF_SOAK_DISABLE
    # is set to a truthy value, signalling that the current invocation is a
    # synthetic-fixture / test-harness run that must NOT advance the soak counter.
    # Truthy = non-empty and not one of '0' / 'false' / 'no' (case-insensitive);
    # unset or falsy = off (production behaviour unchanged). Wired into the same
    # early-return guards as the -WhatIf bypass in the three mutating / gating
    # public functions. Independent of FRAMEWORK_CENTRAL_OVERRIDE, which redirects
    # soak state to a sandbox file rather than suppressing counting.
    $val = $env:PF_SOAK_DISABLE
    if ([string]::IsNullOrWhiteSpace($val)) { return $false }
    return ($val.Trim() -notin @('0', 'false', 'no'))
}

function _Resolve-CallingScript {
    # v2.0 — caller-aware mode support.
    # Walks up Get-PSCallStack and returns the first frame whose ScriptName ends in .ps1
    # (i.e. the calling SCRIPT, not a .psm1 helper module on the call path).
    # Returns @{ ScriptId = '<rel/path/from/project/root>.ps1'; ScriptPath = '<absolute>' }
    # or $null if no .ps1 frame is found (e.g. called from interactive REPL or pwsh -Command).
    #
    # Why this works for helper-routed armoring (Pattern B):
    #   ScriptA.ps1 → DocumentManagement.psm1::New-StandardProjectDocument → ExecutionVerification.psm1::Test-ScriptInSoak
    # The .psm1 frames are skipped; ScriptA.ps1 is identified as the calling script,
    # so the soak entry/counter is keyed on ScriptA, not on the helper module.
    #
    # v2.1 (PF-PRO-032) — Script-ID prefix stripping for cross-project consistency:
    # After computing the relative path, if it starts with the framework-path prefix
    # from doc/project-config.json (`paths.process_framework`, typically
    # 'blueprint/process-framework' in appdev or 'process-framework' in rolled-out
    # projects), strip that prefix. This means the same script bytes resolve to the
    # same ScriptId regardless of whether the script ran from cwd=appdev or
    # cwd=PRJ-NNN — soak state is genuinely cross-project. Scripts living OUTSIDE
    # the framework path (e.g. process-framework-central/scripts/...) keep their
    # full relative path because the prefix check is anchored.
    $stack = Get-PSCallStack
    foreach ($frame in $stack) {
        if ($frame.ScriptName -and $frame.ScriptName -like '*.ps1') {
            $absolute = $frame.ScriptName
            $projectRoot = Get-ProjectRoot
            try {
                $rel = [System.IO.Path]::GetRelativePath($projectRoot, $absolute)
                # Normalize to forward slashes for cross-platform stability and to match
                # the convention used by existing soak entries.
                $relForward = $rel -replace '\\', '/'
            } catch {
                $relForward = $absolute -replace '\\', '/'
            }

            # v2.1 — strip framework-path prefix if present.
            try {
                $config = Get-ProjectConfig
                $fwRelative = $config.paths.process_framework
                if ($fwRelative) {
                    # Normalize the configured prefix to forward slashes for comparison.
                    $fwForward = ($fwRelative -replace '\\', '/').TrimEnd('/')
                    $prefix = "$fwForward/"
                    if ($relForward.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                        $relForward = $relForward.Substring($prefix.Length)
                    }
                }
            } catch {
                # If project-config.json is missing or unparseable, fall back to no stripping.
                # Soak still works; the ScriptId just retains the framework-path prefix.
                Write-Verbose "_Resolve-CallingScript: could not read paths.process_framework from project-config; skipping prefix stripping."
            }

            return @{ ScriptId = $relForward; ScriptPath = $absolute }
        }
    }
    return $null
}

function _Format-RegisteredRow {
    param([Parameter(Mandatory=$true)][pscustomobject]$Entry)
    return "| $($Entry.ScriptId) | $($Entry.ContentHash) | $($Entry.Counter) | $($Entry.Status) | $($Entry.LastInvocation) | $($Entry.LastOutcome) | $($Entry.Notes) |"
}

function _Get-AllRegisteredEntries {
    param([Parameter(Mandatory=$true)][string]$RawContent)

    $headerMarker = '## Registered Scripts'
    $endMarker    = '<!-- New rows are appended above this comment by Register-SoakScript. -->'

    $headerIdx = $RawContent.IndexOf($headerMarker)
    if ($headerIdx -lt 0) { throw "ExecutionVerification: '$headerMarker' header not found in soak tracking file." }
    $endIdx = $RawContent.IndexOf($endMarker, $headerIdx)
    if ($endIdx -lt 0)    { throw "ExecutionVerification: end-marker for Registered Scripts table not found." }

    $tableBlock = $RawContent.Substring($headerIdx, $endIdx - $headerIdx)

    $entries = @()
    foreach ($line in ($tableBlock -split "`r?`n")) {
        if ($line -notmatch '^\|')                  { continue }
        if ($line -match    '^\|\s*Script ID\s*\|') { continue }
        if ($line -match    '^\|\s*-')              { continue }

        $cells = $line -split '\|' | ForEach-Object { $_.Trim() }
        if ($cells.Count -lt 9) { continue }

        $counter = if ($cells[3] -match '^\d+$') { [int]$cells[3] } else { 0 }
        $entries += [pscustomobject]@{
            ScriptId       = $cells[1]
            ContentHash    = $cells[2]
            Counter        = $counter
            Status         = $cells[4]
            LastInvocation = $cells[5]
            LastOutcome    = $cells[6]
            Notes          = $cells[7]
        }
    }
    return ,$entries
}

function _Find-RegisteredEntry {
    param(
        [Parameter(Mandatory=$true)][string]$RawContent,
        [Parameter(Mandatory=$true)][string]$ScriptId
    )
    $entries = _Get-AllRegisteredEntries -RawContent $RawContent
    return ($entries | Where-Object { $_.ScriptId -eq $ScriptId } | Select-Object -First 1)
}

function _Insert-RegisteredEntry {
    # Inserts a brand-new row immediately above the end-marker comment.
    param(
        [Parameter(Mandatory=$true)][string]$RawContent,
        [Parameter(Mandatory=$true)][pscustomobject]$Entry
    )
    $marker = '<!-- New rows are appended above this comment by Register-SoakScript. -->'
    $idx = $RawContent.IndexOf($marker)
    if ($idx -lt 0) { throw "ExecutionVerification: Registered Scripts end-marker not found for insert." }

    $newRow = _Format-RegisteredRow $Entry
    $nl = _Get-LineEnding -Content $RawContent
    return $RawContent.Substring(0, $idx) + $newRow + $nl + $RawContent.Substring($idx)
}

function _Update-RegisteredEntry {
    # Replaces the row whose ScriptId matches $Entry.ScriptId with $Entry.
    param(
        [Parameter(Mandatory=$true)][string]$RawContent,
        [Parameter(Mandatory=$true)][pscustomobject]$Entry
    )
    $newRow    = _Format-RegisteredRow $Entry
    $rowPrefix = "| $($Entry.ScriptId) |"
    $nl        = _Get-LineEnding -Content $RawContent
    $lines     = $RawContent -split "`r?`n"

    $foundIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].StartsWith($rowPrefix)) {
            $lines[$i] = $newRow
            $foundIdx = $i
            break
        }
    }
    if ($foundIdx -lt 0) {
        throw "ExecutionVerification: cannot update row — ScriptId '$($Entry.ScriptId)' not found in registered scripts table."
    }
    return ($lines -join $nl)
}

function _Append-UpdateHistoryRow {
    param(
        [Parameter(Mandatory=$true)][string]$RawContent,
        [Parameter(Mandatory=$true)][string]$Action,
        [Parameter(Mandatory=$true)][string]$Actor
    )
    $marker = '<!-- New rows are appended above this comment by Register-SoakScript / Confirm-SoakInvocation. -->'
    $idx = $RawContent.IndexOf($marker)
    if ($idx -lt 0) { throw "ExecutionVerification: Update History end-marker not found." }

    $date = (Get-Date -Format "yyyy-MM-dd")
    $newRow = "| $date | $Action | $Actor |"
    $nl = _Get-LineEnding -Content $RawContent
    return $RawContent.Substring(0, $idx) + $newRow + $nl + $RawContent.Substring($idx)
}

# ============================================================================
# Public functions
# ============================================================================

function Register-SoakScript {
    <#
    .SYNOPSIS
    Registers a script for soak verification.

    .DESCRIPTION
    Adds the script to script-soak-tracking.md with counter=$DefaultSoakCounter
    (default 3, configurable at module top), the current SHA256 content hash,
    and status "Active Soak". Subsequent invocations of the script must call
    Test-ScriptInSoak / Confirm-SoakInvocation; once $DefaultSoakCounter
    successes are confirmed (without intervening failure or hash change),
    status flips to "Soak Complete".

    Idempotency: silently no-ops if the ScriptId is already registered (returns
    without error). Re-registration after a code change is automatic via
    Test-ScriptInSoak's hash-detection — no manual ceremony needed.

    -WhatIf: no-op (no state file write).

    Synthetic-test bypass (v2.2, PF-IMP-904): also no-ops when $env:PF_SOAK_DISABLE
    is truthy ('1'/'true'/'yes'), so test-harness runs do not register scripts.

    Caller-aware mode (v2.0): when called with no -ScriptId / -ScriptPath, the
    function resolves the calling script via Get-PSCallStack (skipping any
    .psm1 frames). Use this from the top of any script that wants to opt into
    soak verification — single line, no ScriptId/ScriptPath bookkeeping.

    .PARAMETER ScriptId
    Optional. Stable identifier for the script. Convention (v2.1): relative path from project
    root with the framework-path prefix stripped, e.g. "scripts/file-creation/02-design/New-IntegrationNarrative.ps1"
    (NOT "blueprint/process-framework/scripts/..." or "process-framework/scripts/..."). Scripts outside
    the framework path keep their full relative path (e.g. a hypothetical "tools/some-helper/Some-Helper.ps1";
    since the PF-PRO-068 S3 E2 rollout-trio relocation no enrolled .ps1 lives outside the framework path).
    If omitted, auto-resolved from the calling script's path via _Resolve-CallingScript (which performs the
    prefix-stripping automatically). Must be passed together with -ScriptPath or omitted entirely.

    .PARAMETER ScriptPath
    Optional. Absolute or relative on-disk path to the script file (used to compute the
    initial SHA256 hash). If omitted, auto-resolved from the calling script.
    Must be passed together with -ScriptId or omitted entirely.

    .PARAMETER Notes
    Optional free-text note recorded in the registry's Notes column. Avoid
    pipe characters (would break the markdown row).
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]$ScriptId,
        [string]$ScriptPath,
        [string]$Notes = ""
    )

    if ((_Test-CallerWhatIf -Cmdlet $PSCmdlet) -or $WhatIfPreference -or (_Test-SoakDisabled)) {
        Write-Verbose "Register-SoakScript: -WhatIf or PF_SOAK_DISABLE active, skipping registration."
        return
    }

    # v2.0 — caller-aware mode: auto-detect ScriptId / ScriptPath from callstack
    # when neither is provided. Both-or-neither rule prevents partial-arg ambiguity.
    if (-not $ScriptId -and -not $ScriptPath) {
        $resolved = _Resolve-CallingScript
        if (-not $resolved) {
            throw "Register-SoakScript: caller-aware mode failed — no .ps1 frame in callstack. Either invoke from a .ps1 script or pass -ScriptId / -ScriptPath explicitly."
        }
        $ScriptId   = $resolved.ScriptId
        $ScriptPath = $resolved.ScriptPath
    } elseif (-not $ScriptId -or -not $ScriptPath) {
        throw "Register-SoakScript: pass both -ScriptId and -ScriptPath, or pass neither (for caller-aware auto-detection)."
    }

    $raw = _Read-SoakStateRaw -ScriptPath $ScriptPath

    $existing = _Find-RegisteredEntry -RawContent $raw -ScriptId $ScriptId
    if ($existing) {
        # v2.0 — silently no-op rather than throw. Pattern B opt-in puts
        # Register-SoakScript at the top of every armored script, which runs
        # on every invocation; throwing on already-registered would break
        # all subsequent invocations.
        Write-Verbose "Register-SoakScript: '$ScriptId' is already registered (counter=$($existing.Counter), status=$($existing.Status)) — no-op."
        return
    }

    $hash = _Get-SoakScriptHash -ScriptPath $ScriptPath

    $newEntry = [pscustomobject]@{
        ScriptId       = $ScriptId
        ContentHash    = $hash
        Counter        = $script:DefaultSoakCounter
        Status         = "Active Soak"
        LastInvocation = "—"
        LastOutcome    = "—"
        Notes          = $Notes
    }

    $updated = _Insert-RegisteredEntry -RawContent $raw -Entry $newEntry
    $updated = _Append-UpdateHistoryRow -RawContent $updated -Action "Registered $ScriptId (counter=$script:DefaultSoakCounter)" -Actor "Register-SoakScript"

    _Write-SoakStateRaw -Content $updated -ScriptPath $ScriptPath

    # Read-after-write: confirm the new row landed and matches the table's column count.
    $stateFile = _Get-SoakStateFilePath -ScriptPath $ScriptPath
    Assert-TableRowInFile -Path $stateFile -Pattern ([regex]::Escape("| $ScriptId |")) -Context "Register-SoakScript($ScriptId)"

    Write-Verbose "Register-SoakScript: '$ScriptId' registered ($script:DefaultSoakCounter successful invocations required for Soak Complete)."
}

function Test-ScriptInSoak {
    <#
    .SYNOPSIS
    Returns $true if the script is in active soak (and counter > 0); $false otherwise.

    .DESCRIPTION
    Side effect: if the script's current SHA256 differs from the registered
    hash, automatically resets the counter to $DefaultSoakCounter and updates
    the registered hash before returning $true. (No manual reset required when
    scripts are refactored / patched.)

    -WhatIf: returns $false immediately (bypass — WhatIf runs do not count
    toward soak progress).

    Synthetic-test bypass (v2.2, PF-IMP-904): returns $false immediately when
    $env:PF_SOAK_DISABLE is truthy ('1'/'true'/'yes'), so test-harness runs are
    never "in soak".

    Unregistered scripts: returns $false (not an error). Callers can treat
    "not in soak" identically whether the script was never registered or has
    completed soak.

    Caller-aware mode (v2.0): when called with no -ScriptId / -ScriptPath, the
    function resolves the calling script via Get-PSCallStack (skipping any
    .psm1 frames). Use this from inside helper modules (Pattern B) — the
    helper resolves the actual calling .ps1 and consults its soak state.

    .PARAMETER ScriptId
    Optional. Stable identifier (must match what was passed to Register-SoakScript).
    If omitted, auto-resolved from the calling script. Must be passed together with -ScriptPath or omitted entirely.

    .PARAMETER ScriptPath
    Optional. On-disk path to the script (re-hashed to detect body changes).
    If omitted, auto-resolved from the calling script. Must be passed together with -ScriptId or omitted entirely.
    #>
    [CmdletBinding()]
    param(
        [string]$ScriptId,
        [string]$ScriptPath
    )

    if ((_Test-CallerWhatIf -Cmdlet $PSCmdlet) -or $WhatIfPreference -or (_Test-SoakDisabled)) { return $false }

    # v2.0 — caller-aware mode: auto-detect ScriptId / ScriptPath from callstack
    # when neither is provided. Both-or-neither rule prevents partial-arg ambiguity.
    if (-not $ScriptId -and -not $ScriptPath) {
        $resolved = _Resolve-CallingScript
        if (-not $resolved) {
            # No .ps1 caller — treat as not-in-soak rather than throw. This is the
            # right behavior for helper modules invoked from non-.ps1 contexts (REPL,
            # pwsh -Command), where there's no script to soak-verify.
            return $false
        }
        $ScriptId   = $resolved.ScriptId
        $ScriptPath = $resolved.ScriptPath
    } elseif (-not $ScriptId -or -not $ScriptPath) {
        throw "Test-ScriptInSoak: pass both -ScriptId and -ScriptPath, or pass neither (for caller-aware auto-detection)."
    }

    $raw   = _Read-SoakStateRaw -ScriptPath $ScriptPath
    $entry = _Find-RegisteredEntry -RawContent $raw -ScriptId $ScriptId
    if (-not $entry) { return $false }

    $currentHash = _Get-SoakScriptHash -ScriptPath $ScriptPath
    if ($currentHash -ne $entry.ContentHash) {
        # Script body changed — auto-reset counter and update hash.
        $resetEntry = [pscustomobject]@{
            ScriptId       = $entry.ScriptId
            ContentHash    = $currentHash
            Counter        = $script:DefaultSoakCounter
            Status         = "Active Soak"
            LastInvocation = $entry.LastInvocation
            LastOutcome    = $entry.LastOutcome
            Notes          = $entry.Notes
        }
        $updated = _Update-RegisteredEntry -RawContent $raw       -Entry $resetEntry
        $updated = _Append-UpdateHistoryRow -RawContent $updated  -Action "Hash mismatch for $ScriptId; auto-reset counter to $script:DefaultSoakCounter" -Actor "Test-ScriptInSoak (auto)"
        _Write-SoakStateRaw -Content $updated -ScriptPath $ScriptPath

        Write-Verbose "Test-ScriptInSoak: hash mismatch for '$ScriptId' — counter auto-reset to $script:DefaultSoakCounter."
        return $true
    }

    return ($entry.Counter -gt 0)
}

function Confirm-SoakInvocation {
    <#
    .SYNOPSIS
    Records the outcome of a soak invocation — success decrements the counter, failure resets it to $DefaultSoakCounter.

    .DESCRIPTION
    Call this near the end of a script (after the agent has verified the run's
    actual on-disk effects).

    success: counter -= 1; status flips to "Soak Complete" when counter hits 0.
    failure: counter = $DefaultSoakCounter; status remains "Active Soak";
             -Notes recorded in Update History to aid root-cause diagnosis.

    -WhatIf: no-op (WhatIf runs do not count toward soak progress).

    Synthetic-test bypass (v2.2, PF-IMP-904): also a no-op when $env:PF_SOAK_DISABLE
    is truthy ('1'/'true'/'yes'), so test-harness runs do not advance the counter.

    No-ops silently if ScriptId is not registered (was: throw in v1.x). This
    accommodates helper-routed callers (Pattern B) where the helper invokes
    Confirm-SoakInvocation unconditionally and the calling script may or may
    not be registered.

    Caller-aware mode (v2.0): when called with no -ScriptId, the function
    resolves the calling script via Get-PSCallStack (skipping any .psm1 frames).

    .PARAMETER ScriptId
    Optional. Stable identifier (must match what was passed to Register-SoakScript).
    If omitted, auto-resolved from the calling script.

    .PARAMETER Outcome
    'success' or 'failure'.

    .PARAMETER Notes
    Optional free-text note appended to the Update History action description
    when Outcome is 'failure'. Useful for capturing what went wrong.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]$ScriptId,
        [Parameter(Mandatory=$true)][ValidateSet('success','failure')][string]$Outcome,
        [string]$Notes = ""
    )

    if ((_Test-CallerWhatIf -Cmdlet $PSCmdlet) -or $WhatIfPreference -or (_Test-SoakDisabled)) {
        Write-Verbose "Confirm-SoakInvocation: -WhatIf or PF_SOAK_DISABLE active, skipping write."
        return
    }

    # v2.0 — caller-aware mode: auto-detect ScriptId from callstack when not provided.
    # v2.3 (PF-PRO-068 WI-5) — the script's PATH is captured alongside its ID, because
    # ownership-aware state resolution needs the file to read its ownership line from. In
    # caller-aware mode the callstack supplies it; for an explicit -ScriptId it is resolved
    # back from the ID. A ScriptId naming no file on disk leaves it $null, which resolves to
    # own central — the pre-v2.3 behavior, and the only sane answer for a stale row.
    $soakScriptPath = $null
    if (-not $ScriptId) {
        $resolved = _Resolve-CallingScript
        if (-not $resolved) {
            # No .ps1 caller — silently no-op rather than throw.
            Write-Verbose "Confirm-SoakInvocation: caller-aware mode found no .ps1 frame — no-op."
            return
        }
        $ScriptId = $resolved.ScriptId
        $soakScriptPath = $resolved.ScriptPath
    } else {
        $soakScriptPath = _Resolve-SoakScriptPath -ScriptId $ScriptId
    }

    $raw   = _Read-SoakStateRaw -ScriptPath $soakScriptPath
    $entry = _Find-RegisteredEntry -RawContent $raw -ScriptId $ScriptId
    if (-not $entry) {
        # v2.0 — silently no-op rather than throw. Helper-routed callers (Pattern B)
        # invoke Confirm-SoakInvocation unconditionally; the calling script may or
        # may not be registered. Throwing would break every helper invocation from
        # an unregistered script.
        Write-Verbose "Confirm-SoakInvocation: ScriptId '$ScriptId' is not registered — no-op (use Register-SoakScript to opt in)."
        return
    }

    $today = (Get-Date -Format "yyyy-MM-dd")

    if ($Outcome -eq 'success') {
        $newCounter = [Math]::Max(0, $entry.Counter - 1)
        $newStatus  = if ($newCounter -eq 0) { "Soak Complete" } else { "Active Soak" }
        $action     = "Confirmed success for $ScriptId; counter $($entry.Counter) -> $newCounter"
    } else {
        $newCounter = $script:DefaultSoakCounter
        $newStatus  = "Active Soak"
        $action     = "Confirmed FAILURE for $ScriptId; counter reset to $script:DefaultSoakCounter"
        if ($Notes) { $action += " (notes: $Notes)" }
    }

    $updatedEntry = [pscustomobject]@{
        ScriptId       = $entry.ScriptId
        ContentHash    = $entry.ContentHash
        Counter        = $newCounter
        Status         = $newStatus
        LastInvocation = $today
        LastOutcome    = $Outcome
        Notes          = $entry.Notes
    }

    $updated = _Update-RegisteredEntry -RawContent $raw       -Entry $updatedEntry
    $updated = _Append-UpdateHistoryRow -RawContent $updated  -Action $action -Actor "Confirm-SoakInvocation"
    _Write-SoakStateRaw -Content $updated -ScriptPath $soakScriptPath

    Write-Verbose "Confirm-SoakInvocation: '$ScriptId' -> counter=$newCounter, status=$newStatus."
}

function _Resolve-SoakScriptPath {
    # A ScriptId is project-root-relative with the framework-path prefix stripped
    # when the script lives under it (see _Resolve-CallingScript v2.1). Invert
    # that: look under the framework root first, then under the project root for
    # scripts that live outside it (e.g. process-framework-central/scripts/...).
    # Returns $null when the ScriptId names no file on disk — a retired or
    # relocated script must resolve to 'unknown', never be guessed at.
    param([Parameter(Mandatory=$true)][string]$ScriptId)

    try { $projectRoot = Get-ProjectRoot } catch { return $null }
    if (-not $projectRoot) { return $null }

    $candidates = @()
    try {
        $cfgPath = Join-Path $projectRoot 'doc/project-config.json'
        if (Test-Path -LiteralPath $cfgPath) {
            $fw = (Get-Content -LiteralPath $cfgPath -Raw | ConvertFrom-Json).paths.process_framework
            if ($fw) { $candidates += (Join-Path $projectRoot (Join-Path $fw $ScriptId)) }
        }
    } catch {
        # An unreadable or malformed project-config is not fatal here — fall
        # through to the project-root-relative candidate below.
        Write-Verbose "_Resolve-SoakScriptPath: project-config read failed ($($_.Exception.Message)); using project-root-relative candidate only."
    }
    $candidates += (Join-Path $projectRoot $ScriptId)

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    return $null
}

function _Test-ScriptIsSelfArmed {
    # Pure inspection of one script file: does it arm its own soak counter?
    # Kept path-based and side-effect-free so the AST logic is unit-testable
    # against fixtures without a resolvable ScriptId or a live registry.
    #
    # Matching is done over the AST, not the source text: a script that merely
    # MENTIONS a soak helper in a comment or a .DESCRIPTION must not read as
    # instrumented (the AST-vs-text-match rule, PF-IMP-1736).
    #
    # Two ways to be armed:
    #   direct   — the script calls the soak helpers itself
    #   indirect — it routes through a creation wrapper that arms on its behalf
    #              via DocumentManagement.psm1
    #
    # Returns $true / $false, or $null when the file cannot be parsed at all.
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }

    try {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
    } catch { return $null }
    if (-not $ast) { return $null }

    $armingCommands = @(
        'Register-SoakScript', 'Test-ScriptInSoak', 'Confirm-SoakInvocation',
        'New-FrameworkDocument', 'Invoke-DesignArtifactCreation'
    )
    $calls = $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true)
    foreach ($call in $calls) {
        if ($armingCommands -contains $call.GetCommandName()) { return $true }
    }
    return $false
}

function _Get-SoakArmingMode {
    # Derives whether a registered script arms its own soak counter, rather than
    # trusting a hand-maintained annotation that silently drifts (PF-IMP-1880).
    param([Parameter(Mandatory=$true)][string]$ScriptId)

    $path = _Resolve-SoakScriptPath -ScriptId $ScriptId
    if (-not $path) { return 'unknown' }

    $armed = _Test-ScriptIsSelfArmed -Path $path
    if ($null -eq $armed) { return 'unknown' }
    if ($armed) { return 'self-armored' }
    return 'agent-maintained'
}

function _Test-SoakHashCurrent {
    # Pure comparison of one script's current content hash against the hash a
    # soak row recorded. Path-based and side-effect-free so the logic is
    # unit-testable against fixtures. Returns $true / $false, or $null when the
    # file is missing or the stored hash is absent — never a guess.
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$StoredHash
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    if ([string]::IsNullOrWhiteSpace($StoredHash))          { return $null }

    try   { $current = _Get-SoakScriptHash -ScriptPath $Path }
    catch { return $null }

    return ($current -eq $StoredHash)
}

function _Get-SoakHashState {
    # Resolving sibling of _Test-SoakHashCurrent, keyed by ScriptId.
    param(
        [Parameter(Mandatory=$true)][string]$ScriptId,
        [string]$StoredHash
    )

    $path = _Resolve-SoakScriptPath -ScriptId $ScriptId
    if (-not $path) { return $null }
    return (_Test-SoakHashCurrent -Path $path -StoredHash $StoredHash)
}

function Get-SoakStatus {
    <#
    .SYNOPSIS
    Returns the soak registry as objects (one per registered script), each
    carrying its derived Arming mode.

    .DESCRIPTION
    Use during periodic Tools Review sessions to spot stale soaks (counter not
    decrementing because agents are forgetting to call Confirm-SoakInvocation,
    or soaks never completing because the script keeps failing).

    Each entry carries three derived properties, computed at call time from the
    script on disk rather than read out of the row:

      Arming       'self-armored' (it calls the soak helpers itself, or routes
                   through a creation wrapper that arms on its behalf),
                   'agent-maintained' (it does not, so an edit needs the manual
                   re-sync sequence), or 'unknown' (the ScriptId resolves to no
                   file). Derived from the script's AST. This is the
                   authoritative answer: the `[agent-maintained]` text some
                   Notes cells carry is human annotation that cannot be trusted
                   to keep pace with the script (PF-IMP-1880).

      HashCurrent  $true/$false — does the row's recorded hash still match the
                   file? $null when the file is missing or no hash is recorded.
                   A $false on a self-armored script is benign: it re-arms on
                   its next real invocation.

      NeedsResync  $true only when Arming is 'agent-maintained' AND HashCurrent
                   is $false — i.e. the row asserts soak progress against
                   content that no longer exists and nothing will reconcile it
                   automatically. This encodes the rule in code so it does not
                   have to be remembered (PF-IMP-1755).

    Deriving happens here rather than in the shared row parser because the
    parser sits on the hot path of every soak operation. Cost is one AST parse
    plus one hash per row — measured ~3.3s for the full unfiltered registry at
    73 rows; filtering by -ScriptId costs one of each and is effectively free.

    .PARAMETER ScriptId
    Optional: filter to a single registered script. A filtered lookup is ownership-aware
    (v2.3, PF-PRO-068 WI-5) — the ID is resolved to its file, and the row is read from the
    registry of the workspace that OWNS that file, so a script owned elsewhere is found rather
    than reported missing.

    .NOTES
    The UNFILTERED dump reads only the caller's own registry — one workspace's registry is one
    file, and this function does not merge across the chain. Post-federation the fleet-wide
    sweep (`Get-SoakStatus | Where-Object NeedsResync`) therefore covers the rows this workspace
    homes; run it at each producer face to cover the portfolio.
    #>
    [CmdletBinding()]
    param(
        [string]$ScriptId
    )
    $soakScriptPath = if ($ScriptId) { _Resolve-SoakScriptPath -ScriptId $ScriptId } else { $null }
    $raw = _Read-SoakStateRaw -ScriptPath $soakScriptPath
    $entries = _Get-AllRegisteredEntries -RawContent $raw

    if ($ScriptId) {
        $entries = @($entries | Where-Object { $_.ScriptId -eq $ScriptId })
    }

    foreach ($entry in $entries) {
        $arming      = _Get-SoakArmingMode -ScriptId $entry.ScriptId
        $hashCurrent = _Get-SoakHashState  -ScriptId $entry.ScriptId -StoredHash $entry.ContentHash

        $entry | Add-Member -NotePropertyName 'Arming'      -NotePropertyValue $arming      -Force
        $entry | Add-Member -NotePropertyName 'HashCurrent' -NotePropertyValue $hashCurrent -Force
        $entry | Add-Member -NotePropertyName 'NeedsResync' `
            -NotePropertyValue (($arming -eq 'agent-maintained') -and ($hashCurrent -eq $false)) -Force
    }
    return $entries
}

# ============================================================================
# Export
# ============================================================================

$ExportedFunctions = @(
    'Register-SoakScript',
    'Test-ScriptInSoak',
    'Confirm-SoakInvocation',
    'Get-SoakStatus'
)
Export-ModuleMember -Function $ExportedFunctions

Write-Verbose "ExecutionVerification module loaded with $($ExportedFunctions.Count) functions"
