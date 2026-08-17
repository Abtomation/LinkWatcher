<#
.SYNOPSIS
    Shared store/config helpers for Artifact Checkout Locking (PF-PRO-061) — locking-config
    resolution, repo-relative path normalization, guarded-path matching, and exclusive-open
    transactional access to the locks-only store at doc/state-tracking/artifact-locks.json.

.DESCRIPTION
    Deliberately self-contained (no Common-ScriptHelpers umbrella import): the PreToolUse
    enforcement hook (Test-EditAllowed.ps1) loads this module on every Edit/Write tool call,
    so import cost must stay minimal.

    Store shape (JSON): { "locks": [ { path, holder, sessionId, created, lastActivity } ] }
    - path:         repo-root-relative, forward slashes (compared case-insensitively)
    - holder:       free-text task/context label supplied at checkout
    - sessionId:    CLAUDE_CODE_SESSION_ID of the checking-out session ($null outside Claude Code)
    - created/lastActivity: ISO-8601 UTC ("o" round-trip format)

    Concurrency: all mutations go through Invoke-LockStoreTransaction, which opens the store
    file with FileShare.None (exclusive) and retries briefly on contention — two simultaneous
    checkouts from parallel sessions serialize on the file handle, so no lock row is ever lost.

    Config: the "locking" block of doc/project-config.json. An ABSENT block means disabled by
    design — projects that never adopted locking need no migration.
#>

Set-StrictMode -Version Latest

function Resolve-LockingProjectRoot {
    <#
    .SYNOPSIS
        Walks up from a start directory (default: cwd) to the nearest directory containing
        doc/project-config.json — the workspace root in both appdev and project layouts.
    #>
    param([string]$StartDir = (Get-Location).Path)

    $dir = (Resolve-Path $StartDir).Path
    while ($dir) {
        if (Test-Path (Join-Path $dir 'doc/project-config.json')) { return $dir }
        $parent = Split-Path -Parent $dir
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    throw "No doc/project-config.json found walking up from '$StartDir' — cannot resolve the workspace root for artifact locking."
}

function Get-LockingConfig {
    <#
    .SYNOPSIS
        Reads the locking block of doc/project-config.json. Absent block => disabled defaults.
    #>
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $configPath = Join-Path $ProjectRoot 'doc/project-config.json'
    $result = [pscustomobject]@{
        Enabled      = $false
        TtlMinutes   = 15
        GuardedPaths = @()
        StorePath    = Join-Path $ProjectRoot 'doc/state-tracking/artifact-locks.json'
        ProjectRoot  = $ProjectRoot
    }
    if (-not (Test-Path $configPath)) { return $result }
    try {
        $config = Get-Content -Path $configPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    } catch {
        return $result   # unparseable config => treat as disabled rather than blocking every edit
    }
    if (-not ($config.PSObject.Properties.Name -contains 'locking')) { return $result }
    $block = $config.locking
    if ($block.PSObject.Properties.Name -contains 'enabled')      { $result.Enabled = [bool]$block.enabled }
    if ($block.PSObject.Properties.Name -contains 'ttl_minutes')  { $result.TtlMinutes = [int]$block.ttl_minutes }
    if ($block.PSObject.Properties.Name -contains 'guarded_paths') { $result.GuardedPaths = @($block.guarded_paths) }
    return $result
}

function ConvertTo-RepoRelativePath {
    <#
    .SYNOPSIS
        Normalizes a path (absolute or cwd-relative; existence not required) to
        repo-root-relative forward-slash form. Throws if the path lies outside the root.
    #>
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Path
    )

    $rootFull = [System.IO.Path]::GetFullPath($ProjectRoot)
    $candidate = if ([System.IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path (Get-Location).Path $Path }
    $full = [System.IO.Path]::GetFullPath($candidate)
    if (-not $full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        # A bare repo-relative path given from a cwd outside the root still deserves a chance:
        $fallback = [System.IO.Path]::GetFullPath((Join-Path $rootFull $Path))
        if ($fallback.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            $full = $fallback
        } else {
            throw "Path '$Path' resolves outside the workspace root '$rootFull'."
        }
    }
    $rel = $full.Substring($rootFull.Length).TrimStart('\', '/')
    return ($rel -replace '\\', '/')
}

function Test-GuardedPath {
    <#
    .SYNOPSIS
        True when a repo-relative path falls under the guarded set: entries ending '/' are
        directory prefixes; other entries are exact file paths. Case-insensitive.
    #>
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [AllowEmptyCollection()][string[]]$GuardedPaths = @()
    )

    $probe = $RelativePath.ToLowerInvariant()
    foreach ($entry in @($GuardedPaths)) {
        if ([string]::IsNullOrWhiteSpace($entry)) { continue }
        $g = ($entry -replace '\\', '/').ToLowerInvariant()
        if ($g.EndsWith('/')) {
            if ($probe.StartsWith($g)) { return $true }
        } elseif ($probe -eq $g) {
            return $true
        }
    }
    return $false
}

function Get-LockAgeMinutes {
    <#
    .SYNOPSIS
        Minutes since a lock's last activity (falls back to created if lastActivity missing).
    #>
    param([Parameter(Mandatory)]$Lock)

    $stamp = if ($Lock.PSObject.Properties.Name -contains 'lastActivity' -and $Lock.lastActivity) { $Lock.lastActivity } else { $Lock.created }
    # ConvertFrom-Json (PS7) auto-converts ISO-8601 strings to [datetime] (Kind preserved).
    # Coercing that back through a string would strip the Kind and double-convert the offset
    # (a fresh lock then reads as hours old) — so branch on the actual type.
    $when = if ($stamp -is [datetime]) {
        $stamp.ToUniversalTime()
    } else {
        [datetime]::Parse([string]$stamp, [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()
    }
    return [math]::Round(((Get-Date).ToUniversalTime() - $when).TotalMinutes, 1)
}

function New-LockRecord {
    <#
    .SYNOPSIS
        Builds a fresh lock record for a repo-relative path.
    #>
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Holder,
        [string]$SessionId
    )

    $now = (Get-Date).ToUniversalTime().ToString('o')
    return [pscustomobject]@{
        path         = $RelativePath
        holder       = $Holder
        sessionId    = $SessionId
        created      = $now
        lastActivity = $now
    }
}

function Invoke-LockStoreTransaction {
    <#
    .SYNOPSIS
        Runs a read-modify-write against the lock store under an exclusive file handle.

    .DESCRIPTION
        $Body receives the current locks as an array parameter and returns a hashtable:
          @{ Locks = <new full lock array or $null for read-only>; Result = <any> }
        The store file is opened OpenOrCreate/ReadWrite/Share-None; contention from a parallel
        session's transaction is retried for up to ~5 seconds before failing loudly.
    #>
    param(
        [Parameter(Mandatory)][string]$StorePath,
        [Parameter(Mandatory)][scriptblock]$Body
    )

    $storeDir = Split-Path -Parent $StorePath
    if (-not (Test-Path $storeDir)) { New-Item -ItemType Directory -Path $storeDir -Force | Out-Null }

    $stream = $null
    $deadline = (Get-Date).AddSeconds(5)
    while ($true) {
        try {
            $stream = [System.IO.File]::Open($StorePath,
                [System.IO.FileMode]::OpenOrCreate,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None)
            break
        } catch [System.IO.IOException] {
            if ((Get-Date) -gt $deadline) {
                throw "Lock store '$StorePath' is held by another process (exclusive-open timed out after 5s)."
            }
            Start-Sleep -Milliseconds 100
        }
    }

    try {
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8, $true, 4096, $true)
        $raw = $reader.ReadToEnd()
        $reader.Dispose()

        $locks = @()
        if (-not [string]::IsNullOrWhiteSpace($raw)) {
            try {
                $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
                if ($parsed.PSObject.Properties.Name -contains 'locks') { $locks = @($parsed.locks) }
            } catch {
                throw "Lock store '$StorePath' contains unparseable JSON — refusing to overwrite it blindly. Inspect the file (its content is machine-written; a hand-edit or crash mid-write is the likely cause)."
            }
        }

        $outcome = & $Body $locks
        if ($null -eq $outcome) { $outcome = @{} }

        if ($outcome.ContainsKey('Locks') -and $null -ne $outcome['Locks']) {
            $payload = [pscustomobject]@{ locks = @($outcome['Locks']) }
            $json = $payload | ConvertTo-Json -Depth 5
            $stream.SetLength(0)
            $stream.Position = 0
            $writer = New-Object System.IO.StreamWriter($stream, (New-Object System.Text.UTF8Encoding($false)), 4096, $true)
            $writer.Write($json)
            $writer.Flush()
            $writer.Dispose()
        }

        if ($outcome.ContainsKey('Result')) { return $outcome['Result'] }
        return $null
    } finally {
        if ($stream) { $stream.Dispose() }
    }
}

Export-ModuleMember -Function Resolve-LockingProjectRoot, Get-LockingConfig, ConvertTo-RepoRelativePath,
    Test-GuardedPath, Get-LockAgeMinutes, New-LockRecord, Invoke-LockStoreTransaction
