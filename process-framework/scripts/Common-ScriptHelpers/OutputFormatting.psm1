# OutputFormatting.psm1
# Output formatting and utility functions for PowerShell scripts
# Provides standardized messaging, path operations, and string utilities

<#
.SYNOPSIS
Output formatting and utility functions for PowerShell scripts

.DESCRIPTION
This module provides standardized functionality for:
- Success, info, warning, and error message formatting
- Path validation and creation
- Timestamp generation in various formats
- String conversion utilities
- File conflict handling

.NOTES
Version: 3.0 (Modularized from Common-ScriptHelpers v2.0)
Created: 2025-08-26
#>

function Write-ProjectSuccess {
    <#
    .SYNOPSIS
    Writes a standardized success message

    .PARAMETER Message
    The success message to display

    .PARAMETER Details
    Optional array of detail lines to display
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string[]]$Details = @()
    )

    Write-Host "✅ $Message" -ForegroundColor Green

    foreach ($detail in $Details) {
        Write-Host "   $detail" -ForegroundColor Gray
    }
}

function Write-ProjectInfo {
    <#
    .SYNOPSIS
    Writes a standardized informational message

    .PARAMETER Message
    The informational message to display

    .PARAMETER Details
    Optional array of detail lines to display
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string[]]$Details = @()
    )

    Write-Host "ℹ️ $Message" -ForegroundColor Cyan

    foreach ($detail in $Details) {
        Write-Host "   $detail" -ForegroundColor Gray
    }
}

function Write-ProjectWarning {
    <#
    .SYNOPSIS
    Writes a standardized warning message

    .PARAMETER Message
    The warning message to display

    .PARAMETER Details
    Optional array of detail lines to display
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string[]]$Details = @()
    )

    Write-Host "⚠️ $Message" -ForegroundColor Yellow

    foreach ($detail in $Details) {
        Write-Host "   $detail" -ForegroundColor Gray
    }
}

function Write-ProjectError {
    <#
    .SYNOPSIS
    Writes a standardized error message and optionally exits

    .PARAMETER Message
    The error message to display

    .PARAMETER ExitCode
    Exit code (if provided, script will exit)
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [int]$ExitCode
    )

    Write-Host "❌ $Message" -ForegroundColor Red

    if ($ExitCode) {
        exit $ExitCode
    }
}

function Write-ProjectLog {
    <#
    .SYNOPSIS
    Writes a default-quiet, timestamped, leveled log line.

    .DESCRIPTION
    Shared default-quiet logger for the update-script fleet (promoted from the per-script
    Write-Log copies, PF-IMP-1327). INFO/SUCCESS lines route to Write-Verbose (visible only
    under -Verbose); WARN and ERROR are always written to the host. The single per-invocation
    visible outcome line is emitted separately via Write-ProjectSummary, which bypasses this gate.
    [CmdletBinding] is required so the Write-Verbose call inherits the calling script's -Verbose
    preference across the module boundary.

    .PARAMETER Message
    The log message text.

    .PARAMETER Level
    Severity level: INFO (default), SUCCESS, WARN, or ERROR. Unknown levels are treated as INFO
    (routed to Write-Verbose).
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    switch ($Level) {
        "ERROR"   { Write-Host $line -ForegroundColor Red }
        "WARN"    { Write-Host $line -ForegroundColor Yellow }
        default   {
            # Honor the calling script's -Verbose across the module boundary. PowerShell's implicit
            # advanced-function -Verbose inheritance does NOT reach a module function when the script
            # is launched via the & call operator (pwsh -Command "& script -Verbose") — only via
            # -File. Resolving the caller's VerbosePreference explicitly makes the INFO/SUCCESS line
            # surface under both invocation styles, matching the pre-consolidation per-script logger
            # (PF-IMP-1327). The guard preserves an explicit -Verbose / -Verbose:$false on the call.
            if (-not $PSBoundParameters.ContainsKey('Verbose')) {
                $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
            }
            Write-Verbose $line
        }
    }
}

function Write-ProjectSummary {
    <#
    .SYNOPSIS
    Writes the single always-visible per-invocation outcome line.

    .DESCRIPTION
    Companion to Write-ProjectLog (PF-IMP-1327). Always writes one timestamped, leveled line to
    the host (green for SUCCESS, yellow for WARN, red for ERROR), bypassing Write-ProjectLog's
    default-quiet gate so an update script's final outcome stays visible without -Verbose.

    .PARAMETER Message
    The outcome message text.

    .PARAMETER Level
    Severity level: SUCCESS (default), WARN, or ERROR.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Level = "SUCCESS"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR"   { "Red" }
        "WARN"    { "Yellow" }
        default   { "Green" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-ProjectPath {
    <#
    .SYNOPSIS
    Tests if a path exists, with option to create it

    .PARAMETER Path
    Path to test

    .PARAMETER CreateIfMissing
    Create the path if it doesn't exist

    .PARAMETER PathType
    Type of path (File or Directory)
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [switch]$CreateIfMissing,

        [Parameter(Mandatory=$false)]
        [ValidateSet("File", "Directory")]
        [string]$PathType = "Directory"
    )

    if (Test-Path $Path) {
        return $true
    }

    if ($CreateIfMissing) {
        try {
            if ($PathType -eq "Directory") {
                New-Item -ItemType Directory -Path $Path -Force | Out-Null
                Write-Verbose "Created directory: $Path"
            } else {
                $parentDir = Split-Path -Parent $Path
                if ($parentDir -and -not (Test-Path $parentDir)) {
                    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                }
                New-Item -ItemType File -Path $Path -Force | Out-Null
                Write-Verbose "Created file: $Path"
            }
            return $true
        }
        catch {
            Write-Warning "Failed to create $PathType at $Path`: $($_.Exception.Message)"
            return $false
        }
    }

    return $false
}

function Get-ProjectTimestamp {
    <#
    .SYNOPSIS
    Gets standardized timestamps in various formats

    .PARAMETER Format
    The timestamp format to return

    .EXAMPLE
    Get-ProjectTimestamp -Format "Date"
    # Returns: "2025-07-08"

    .EXAMPLE
    Get-ProjectTimestamp -Format "FileTimestamp"
    # Returns: "20250708-134136"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("Date", "Time", "FileTimestamp", "DateTime")]
        [string]$Format = "Date"
    )

    switch ($Format) {
        "Date" { return Get-Date -Format "yyyy-MM-dd" }
        "Time" { return Get-Date -Format "HHmmss" }
        "FileTimestamp" { return Get-Date -Format "yyyyMMdd-HHmmss" }
        "DateTime" { return Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
    }
}

function ConvertTo-KebabCase {
    <#
    .SYNOPSIS
    Converts a string to kebab-case for use in filenames

    .PARAMETER InputString
    The string to convert

    .EXAMPLE
    ConvertTo-KebabCase -InputString "User Authentication System"
    # Returns: "user-authentication-system"

    .EXAMPLE
    ConvertTo-KebabCase -InputString "My Feature Name!!!"
    # Returns: "my-feature-name"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputString
    )

    return $InputString.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''
}

function ConvertTo-YamlDoubleQuotedScalar {
    <#
    .SYNOPSIS
    Wraps a string as a YAML double-quoted scalar, escaping backslashes and double quotes.

    .DESCRIPTION
    Produces a frontmatter-safe value (e.g. for a `description:` field whose text may contain
    a colon or other YAML-significant characters). Shared so creation scripts emit instance
    descriptions consistently (PF-IMP-1193 established the pattern in New-Guide.ps1; promoted
    here for the PD/TE creation scripts per PF-PRO-050 / PF-IMP-1173 Phase 3b).

    .PARAMETER Value
    The raw string to quote.

    .EXAMPLE
    ConvertTo-YamlDoubleQuotedScalar 'Functional Design Document for Login: SSO'
    # Returns: "Functional Design Document for Login: SSO"
    #>
    param([string]$Value)
    $escaped = ($Value -replace '\\', '\\') -replace '"', '\"'
    return '"' + $escaped + '"'
}

function Test-YamlDoubleQuotedScalar {
    <#
    .SYNOPSIS
    Tests whether a string is already a well-formed YAML double-quoted scalar.

    .DESCRIPTION
    True only when the value opens and closes with a double quote AND every interior quote is
    backslash-escaped — i.e. exactly what ConvertTo-YamlDoubleQuotedScalar produces. Raw text
    that merely happens to start and end with a quote (`"Hello" she said "hi"`) is NOT a
    well-formed scalar and returns false, so ConvertTo-YamlSafeScalar still quotes it.

    .PARAMETER Value
    The string to test.
    #>
    param([string]$Value)

    if ($Value.Length -lt 2 -or -not $Value.StartsWith('"') -or -not $Value.EndsWith('"')) { return $false }

    # Strip escape sequences (\\ , \" , \n …); a bare quote surviving means the value is not
    # a single well-formed double-quoted scalar.
    $inner = $Value.Substring(1, $Value.Length - 2)
    return (($inner -replace '\\.', '') -notmatch '"')
}

function ConvertTo-YamlSafeScalar {
    <#
    .SYNOPSIS
    Returns a frontmatter-safe YAML scalar — quoting the value only when a plain scalar would
    mis-parse, and leaving an already-quoted scalar untouched.

    .DESCRIPTION
    The idempotent form of ConvertTo-YamlDoubleQuotedScalar, applied by the shared frontmatter
    writer (New-ProjectDocumentMetadata) to every string metadata value so a free-text value
    containing a colon-space can no longer emit invalid YAML (PF-IMP-1413; the trap recurred
    after the caller-side convention was merely documented in PF-IMP-1291).

    Values that are already plain-safe pass through byte-identically, so a caller that
    pre-quotes with ConvertTo-YamlDoubleQuotedScalar and one that passes raw text both produce
    correct frontmatter.

    .PARAMETER Value
    The raw metadata value.

    .EXAMPLE
    ConvertTo-YamlSafeScalar 'Template for feature requests'
    # Returns: Template for feature requests   (plain-safe — unchanged)

    .EXAMPLE
    ConvertTo-YamlSafeScalar 'Template for X (Y): Z'
    # Returns: "Template for X (Y): Z"         (colon-space — quoted)
    #>
    param([string]$Value)

    if ([string]::IsNullOrEmpty($Value)) { return $Value }
    if (Test-YamlDoubleQuotedScalar -Value $Value) { return $Value }

    # Plain scalars mis-parse (or lose meaning) on: a colon-space or trailing colon; a comment
    # marker; a leading YAML indicator character; a line break; leading/trailing whitespace.
    $needsQuoting = ($Value -match ':(\s|$)') -or
                    ($Value -match '(^|\s)#') -or
                    ($Value -match '^[-?:,\[\]{}&*!|>''"%@`]') -or
                    ($Value -match '[\r\n]') -or
                    ($Value -match '^\s|\s$')

    if ($needsQuoting) { return ConvertTo-YamlDoubleQuotedScalar $Value }
    return $Value
}

function ConvertTo-MarkdownTableCellValue {
    <#
    .SYNOPSIS
    Escapes a string for safe inclusion inside a Markdown table cell.

    .DESCRIPTION
    Escapes the pipe character ('|' -> '\|') so a value containing a literal pipe does not
    introduce phantom columns and break the table render. The escaped form also renders as a
    literal '|' in non-table prose/headings, so the result is safe to substitute into a body
    placeholder that appears in both table and prose contexts. Shared so creation scripts that
    inject user-supplied values into Document Metadata tables stay render-safe (PF-IMP-1284).

    .PARAMETER Value
    The raw string to make table-cell-safe.

    .EXAMPLE
    ConvertTo-MarkdownTableCellValue 'PF|PD|TE'
    # Returns: PF\|PD\|TE
    #>
    param([string]$Value)
    return $Value -replace '\|', '\|'
}

function Test-ProjectFileConflict {
    <#
    .SYNOPSIS
    Tests if a file already exists and handles conflicts appropriately

    .PARAMETER FilePath
    The file path to check

    .PARAMETER ConflictAction
    Action to take if file exists: Error, Overwrite, or Skip

    .PARAMETER ErrorMessage
    Custom error message if file exists (used with Error action)

    .EXAMPLE
    Test-ProjectFileConflict -FilePath "output.md" -ConflictAction "Error" -ErrorMessage "Task already exists"

    .EXAMPLE
    $canProceed = Test-ProjectFileConflict -FilePath "output.md" -ConflictAction "Skip"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Error", "Overwrite", "Skip")]
        [string]$ConflictAction = "Error",

        [Parameter(Mandatory=$false)]
        [string]$ErrorMessage = "File already exists"
    )

    if (-not (Test-Path $FilePath)) {
        return $true  # No conflict, can proceed
    }

    switch ($ConflictAction) {
        "Error" {
            throw "$ErrorMessage at $FilePath"
        }
        "Overwrite" {
            Write-Warning "Overwriting existing file: $FilePath"
            return $true
        }
        "Skip" {
            Write-Warning "Skipping existing file: $FilePath"
            return $false
        }
    }
}

function Invoke-StandardScriptInitialization {
    <#
    .SYNOPSIS
    Performs standard initialization for PowerShell scripts

    .DESCRIPTION
    Sets up standard error handling, encoding, and initializes the script environment.
    This function should be called at the start of each script that uses Common-ScriptHelpers.
    #>

    [CmdletBinding()]
    param()

    # Configure error handling
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($VerbosePreference -eq "Continue") { "Continue" } else { "SilentlyContinue" }

    # Configure UTF-8 encoding
    $PSDefaultParameterValues['*:Encoding'] = 'UTF8'
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8

    Write-Verbose "Standard script initialization completed"
}

# Export functions
Export-ModuleMember -Function @(
    'Write-ProjectSuccess',
    'Write-ProjectInfo',
    'Write-ProjectWarning',
    'Write-ProjectError',
    'Write-ProjectLog',
    'Write-ProjectSummary',
    'Test-ProjectPath',
    'Get-ProjectTimestamp',
    'ConvertTo-KebabCase',
    'ConvertTo-YamlDoubleQuotedScalar',
    'ConvertTo-YamlSafeScalar',
    'Test-YamlDoubleQuotedScalar',
    'ConvertTo-MarkdownTableCellValue',
    'Test-ProjectFileConflict',
    'Invoke-StandardScriptInitialization'
)
