# ExecutionVerification.psm1
# Soak-verification helpers for newly created or recently modified PowerShell scripts.
#
# VERSION 1.0 - NEW SUB-MODULE (PF-TSK-026 Phase 3)
# Implements PF-PRO-028 (Script Self-Verification) — see
# process-framework-local/proposals/old/script-self-verification.md.
#
# Concept: every newly registered or hash-changed script must be confirmed by
# the agent over 5 consecutive successful invocations before it is considered
# soak-complete. Failures or script-body changes reset the counter to 5.
# WhatIf invocations bypass the soak entirely (no decrement, no state write).
#
# Public functions (4):
#   Register-SoakScript      - add a script to the soak registry
#   Test-ScriptInSoak        - is the caller still in soak? (auto-resets on hash change)
#   Confirm-SoakInvocation   - record success/failure outcome of a soak invocation
#   Get-SoakStatus           - inspect the registry (all rows or one row)
#
# State file: process-framework/state-tracking/permanent/script-soak-tracking.md
# Dependencies (resolved via Common-ScriptHelpers facade load order):
#   - Get-ProjectRoot       (Core.psm1)
#   - Assert-LineInFile     (FileOperations.psm1) — used internally for read-after-write verification

$PSDefaultParameterValues['*:Encoding'] = 'UTF8'

# ============================================================================
# Module-private helpers (not exported)
# ============================================================================

function _Get-SoakStateFilePath {
    $projectRoot = Get-ProjectRoot
    return (Join-Path -Path $projectRoot -ChildPath "process-framework/state-tracking/permanent/script-soak-tracking.md")
}

function _Get-SoakScriptHash {
    param([Parameter(Mandatory=$true)][string]$ScriptPath)
    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        throw "ExecutionVerification: script file not found at '$ScriptPath'"
    }
    return (Get-FileHash -LiteralPath $ScriptPath -Algorithm SHA256).Hash
}

function _Read-SoakStateRaw {
    $path = _Get-SoakStateFilePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "ExecutionVerification: soak tracking file not found at '$path'. The file is created by Phase 3 of PF-TSK-026 (Script Self-Verification)."
    }
    return [System.IO.File]::ReadAllText($path, [System.Text.UTF8Encoding]::new($false))
}

function _Write-SoakStateRaw {
    param([Parameter(Mandatory=$true)][string]$Content)
    $path = _Get-SoakStateFilePath
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
    Adds the script to script-soak-tracking.md with counter=5, the current
    SHA256 content hash, and status "Active Soak". Subsequent invocations of
    the script must call Test-ScriptInSoak / Confirm-SoakInvocation; once 5
    successes are confirmed (without intervening failure or hash change),
    status flips to "Soak Complete".

    Idempotency: throws if the ScriptId is already registered. Re-registration
    is intentionally not supported — to re-soak after a code change, just edit
    the script body; the next Test-ScriptInSoak call detects the hash change
    and auto-resets the counter.

    -WhatIf: no-op (no state file write).

    .PARAMETER ScriptId
    Stable identifier for the script. Convention: relative path from project
    root, e.g. "process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1".

    .PARAMETER ScriptPath
    Absolute or relative on-disk path to the script file (used to compute the
    initial SHA256 hash).

    .PARAMETER Notes
    Optional free-text note recorded in the registry's Notes column. Avoid
    pipe characters (would break the markdown row).
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)][string]$ScriptId,
        [Parameter(Mandatory=$true)][string]$ScriptPath,
        [string]$Notes = ""
    )

    if ((_Test-CallerWhatIf -Cmdlet $PSCmdlet) -or $WhatIfPreference) {
        Write-Verbose "Register-SoakScript: -WhatIf mode, skipping registration of '$ScriptId'."
        return
    }

    $raw = _Read-SoakStateRaw

    $existing = _Find-RegisteredEntry -RawContent $raw -ScriptId $ScriptId
    if ($existing) {
        throw "Register-SoakScript: ScriptId '$ScriptId' is already registered (counter=$($existing.Counter), status=$($existing.Status)). To re-soak after a code change, just modify the script body — Test-ScriptInSoak will detect the hash change and auto-reset on the next invocation."
    }

    $hash = _Get-SoakScriptHash -ScriptPath $ScriptPath

    $newEntry = [pscustomobject]@{
        ScriptId       = $ScriptId
        ContentHash    = $hash
        Counter        = 5
        Status         = "Active Soak"
        LastInvocation = "—"
        LastOutcome    = "—"
        Notes          = $Notes
    }

    $updated = _Insert-RegisteredEntry -RawContent $raw -Entry $newEntry
    $updated = _Append-UpdateHistoryRow -RawContent $updated -Action "Registered $ScriptId (counter=5)" -Actor "Register-SoakScript"

    _Write-SoakStateRaw -Content $updated

    # Read-after-write: confirm the new row actually landed.
    $stateFile = _Get-SoakStateFilePath
    Assert-LineInFile -Path $stateFile -Pattern ([regex]::Escape("| $ScriptId |")) -Context "Register-SoakScript($ScriptId)"

    Write-Verbose "Register-SoakScript: '$ScriptId' registered (5 successful invocations required for Soak Complete)."
}

function Test-ScriptInSoak {
    <#
    .SYNOPSIS
    Returns $true if the script is in active soak (and counter > 0); $false otherwise.

    .DESCRIPTION
    Side effect: if the script's current SHA256 differs from the registered
    hash, automatically resets the counter to 5 and updates the registered
    hash before returning $true. (No manual reset required when scripts are
    refactored / patched.)

    -WhatIf: returns $false immediately (bypass — WhatIf runs do not count
    toward soak progress).

    Unregistered scripts: returns $false (not an error). Callers can treat
    "not in soak" identically whether the script was never registered or has
    completed soak.

    .PARAMETER ScriptId
    Stable identifier (must match what was passed to Register-SoakScript).

    .PARAMETER ScriptPath
    On-disk path to the script (re-hashed to detect body changes).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ScriptId,
        [Parameter(Mandatory=$true)][string]$ScriptPath
    )

    if ((_Test-CallerWhatIf -Cmdlet $PSCmdlet) -or $WhatIfPreference) { return $false }

    $raw   = _Read-SoakStateRaw
    $entry = _Find-RegisteredEntry -RawContent $raw -ScriptId $ScriptId
    if (-not $entry) { return $false }

    $currentHash = _Get-SoakScriptHash -ScriptPath $ScriptPath
    if ($currentHash -ne $entry.ContentHash) {
        # Script body changed — auto-reset counter and update hash.
        $resetEntry = [pscustomobject]@{
            ScriptId       = $entry.ScriptId
            ContentHash    = $currentHash
            Counter        = 5
            Status         = "Active Soak"
            LastInvocation = $entry.LastInvocation
            LastOutcome    = $entry.LastOutcome
            Notes          = $entry.Notes
        }
        $updated = _Update-RegisteredEntry -RawContent $raw       -Entry $resetEntry
        $updated = _Append-UpdateHistoryRow -RawContent $updated  -Action "Hash mismatch for $ScriptId; auto-reset counter to 5" -Actor "Test-ScriptInSoak (auto)"
        _Write-SoakStateRaw -Content $updated

        Write-Verbose "Test-ScriptInSoak: hash mismatch for '$ScriptId' — counter auto-reset to 5."
        return $true
    }

    return ($entry.Counter -gt 0)
}

function Confirm-SoakInvocation {
    <#
    .SYNOPSIS
    Records the outcome of a soak invocation — success decrements the counter, failure resets it to 5.

    .DESCRIPTION
    Call this near the end of a script (after the agent has verified the run's
    actual on-disk effects).

    success: counter -= 1; status flips to "Soak Complete" when counter hits 0.
    failure: counter = 5; status remains "Active Soak"; -Notes recorded in
             Update History to aid root-cause diagnosis.

    -WhatIf: no-op (WhatIf runs do not count toward soak progress).

    Throws if ScriptId is not registered.

    .PARAMETER ScriptId
    Stable identifier (must match what was passed to Register-SoakScript).

    .PARAMETER Outcome
    'success' or 'failure'.

    .PARAMETER Notes
    Optional free-text note appended to the Update History action description
    when Outcome is 'failure'. Useful for capturing what went wrong.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)][string]$ScriptId,
        [Parameter(Mandatory=$true)][ValidateSet('success','failure')][string]$Outcome,
        [string]$Notes = ""
    )

    if ((_Test-CallerWhatIf -Cmdlet $PSCmdlet) -or $WhatIfPreference) {
        Write-Verbose "Confirm-SoakInvocation: -WhatIf mode, skipping write for '$ScriptId'."
        return
    }

    $raw   = _Read-SoakStateRaw
    $entry = _Find-RegisteredEntry -RawContent $raw -ScriptId $ScriptId
    if (-not $entry) {
        throw "Confirm-SoakInvocation: ScriptId '$ScriptId' is not registered. Run Register-SoakScript first (typically during PF-TSK-026 / PF-TSK-001 finalization)."
    }

    $today = (Get-Date -Format "yyyy-MM-dd")

    if ($Outcome -eq 'success') {
        $newCounter = [Math]::Max(0, $entry.Counter - 1)
        $newStatus  = if ($newCounter -eq 0) { "Soak Complete" } else { "Active Soak" }
        $action     = "Confirmed success for $ScriptId; counter $($entry.Counter) -> $newCounter"
    } else {
        $newCounter = 5
        $newStatus  = "Active Soak"
        $action     = "Confirmed FAILURE for $ScriptId; counter reset to 5"
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
    _Write-SoakStateRaw -Content $updated

    Write-Verbose "Confirm-SoakInvocation: '$ScriptId' -> counter=$newCounter, status=$newStatus."
}

function Get-SoakStatus {
    <#
    .SYNOPSIS
    Returns the soak registry as objects (one per registered script).

    .DESCRIPTION
    Use during periodic Tools Review sessions to spot stale soaks (counter not
    decrementing because agents are forgetting to call Confirm-SoakInvocation,
    or soaks never completing because the script keeps failing).

    .PARAMETER ScriptId
    Optional: filter to a single registered script.
    #>
    [CmdletBinding()]
    param(
        [string]$ScriptId
    )
    $raw = _Read-SoakStateRaw
    $entries = _Get-AllRegisteredEntries -RawContent $raw

    if ($ScriptId) {
        return ($entries | Where-Object { $_.ScriptId -eq $ScriptId })
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
