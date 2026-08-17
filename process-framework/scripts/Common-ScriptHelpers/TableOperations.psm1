# TableOperations.psm1
# Core markdown table manipulation functions
# Extracted from StateFileManagement.psm1 as part of module decomposition
#
# VERSION 2.0 - WITH LOW-LEVEL HELPERS (PF-IMP-366)
# This module contains pure table manipulation functions with no external dependencies

<#
.SYNOPSIS
Core markdown table manipulation functions for PowerShell scripts

.DESCRIPTION
This module provides specialized functionality for manipulating markdown tables:
- Parsing and updating table content
- Column-based updates with feature ID targeting
- Note appending with proper formatting
- Robust table structure preservation

This is a focused module extracted from StateFileManagement.psm1 to improve
maintainability and reduce complexity.

Low-level helpers (v2.0):
- Split-MarkdownTableRow: Parse a single table row into trimmed cell values
- ConvertFrom-MarkdownTable: Parse table(s) into PSObjects with named properties
- Get-MarkdownLinkText: Extract display text from [text](url) links
- ConvertTo-MarkdownTableRow: Format cell values as a markdown table row

High-level operations (v1.0):
- Update-MarkdownTable: Feature-centric single-row updates
- Update-MarkdownTableWithAppend: Row updates with append semantics
- Move-MarkdownTableRow: Row migration between table sections

Post-condition verification (v2.3):
- Assert-TableRowInFile: Verify a written row exists AND matches its table header's column count

Header-driven row construction (v2.4):
- Get-MarkdownTableHeaders: Read a section's table header names
- New-HeaderDrivenTableRow: Build a row ordered by the live table's headers (drift-proof)

.NOTES
Version: 2.4
Created: 2025-08-30
Updated: 2026-07-17
Extracted From: StateFileManagement.psm1
Dependencies: None (pure functions)
#>

# Configure UTF-8 encoding for consistent Unicode support
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'

#region Low-Level Helpers (v2.0 — PF-IMP-366)

function Split-MarkdownTableRow {
    <#
    .SYNOPSIS
    Parses a single markdown table row into an array of trimmed cell values.

    .DESCRIPTION
    Handles the boilerplate of splitting by '|', removing the leading/trailing empty
    elements, and trimming whitespace. Returns $null if the line is not a table row.

    .PARAMETER Line
    A single line of text (e.g., "| col1 | col2 | col3 |").

    .OUTPUTS
    [string[]] Array of trimmed cell values, or $null if not a table row.

    .EXAMPLE
    Split-MarkdownTableRow "| Feature 1.0 | ✅ Done | [link](path) |"
    # Returns: @("Feature 1.0", "✅ Done", "[link](path)")
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Line
    )

    if (-not $Line -or $Line -notmatch '^\|.*\|$') { return $null }

    # Split on '|' only when not preceded by '\' so cells can embed escaped pipes
    # (markdown's \| escape). Cells are returned in raw form — backslash-escapes are
    # preserved so the row round-trips through ConvertTo-MarkdownTableRow without
    # corrupting subsequent parses.
    $raw = $Line -split '(?<!\\)\|'
    if ($raw.Count -le 2) { return @() }
    $raw = $raw[1..($raw.Count-2)]
    return @($raw | ForEach-Object { $_.Trim() })
}

function Get-MarkdownLinkText {
    <#
    .SYNOPSIS
    Extracts display text from a markdown link, or returns the value unchanged.

    .DESCRIPTION
    Given a cell value like "[Some Text](path/to/file.md)", returns "Some Text".
    If the value is not a markdown link, returns the original string unchanged.

    .PARAMETER Value
    A string that may contain a markdown link.

    .OUTPUTS
    [string] The display text if a link, or the original value.

    .EXAMPLE
    Get-MarkdownLinkText "[Feature 1.2.3](doc/features/1.2.3.md)"
    # Returns: "Feature 1.2.3"

    .EXAMPLE
    Get-MarkdownLinkText "plain text"
    # Returns: "plain text"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Value
    )

    if ($Value -match '^\[([^\]]+)\]') {
        return $matches[1]
    }
    return $Value
}

function ConvertTo-MarkdownTableRow {
    <#
    .SYNOPSIS
    Formats an array of cell values as a markdown table row.

    .DESCRIPTION
    Takes an array of strings and returns "| val1 | val2 | val3 |".
    Also supports creating separator rows.

    Literal pipes inside a cell value are escaped as '\|' (PF-IMP-1875), the write half of
    the round-trip contract Split-MarkdownTableRow already reads. Escaping is idempotent, so
    a cell that already contains '\|' is left alone.

    .PARAMETER Cells
    Array of cell values to format.

    .PARAMETER Separator
    If set, produces a separator row (| --- | --- | --- |) with the given count of columns.

    .OUTPUTS
    [string] A formatted markdown table row.

    .EXAMPLE
    ConvertTo-MarkdownTableRow -Cells @("Feature 1.0", "✅ Done", "Notes here")
    # Returns: "| Feature 1.0 | ✅ Done | Notes here |"

    .EXAMPLE
    ConvertTo-MarkdownTableRow -Separator 3
    # Returns: "| --- | --- | --- |"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Cells')]
        [AllowEmptyString()]
        [string[]]$Cells,

        [Parameter(Mandatory=$true, ParameterSetName='Separator')]
        [int]$Separator
    )

    if ($PSCmdlet.ParameterSetName -eq 'Separator') {
        $dashes = @("---") * $Separator
        return "| " + ($dashes -join " | ") + " |"
    }

    # PF-IMP-1875: escape literal pipes in cell values. Split-MarkdownTableRow splits on
    # '(?<!\\)\|' and returns cells raw so escapes survive a round-trip — that is the read
    # half of markdown's \| contract (PF-IMP-603); this is the write half, which was never
    # implemented. Without it a cell carrying prose like a regex or a path alternation emits
    # extra delimiters, and every later cell silently lands under the wrong header.
    # Idempotent: the negative lookbehind leaves an already-escaped '\|' alone, so a
    # read-modify-write cycle does not accumulate backslashes.
    $escaped = @($Cells | ForEach-Object { $_ -replace '(?<!\\)\|', '\|' })

    return "| " + ($escaped -join " | ") + " |"
}

function ConvertFrom-MarkdownTable {
    <#
    .SYNOPSIS
    Parses a markdown table into an array of PSObjects with named properties.

    .DESCRIPTION
    Given file content (as a string) and an optional section heading, parses tables
    into structured objects. Each row becomes a PSObject with properties named after
    the column headers.

    By default, parses only the first table found. Use -AllTables to parse every table
    in the file (or section) that shares the same column schema — useful for files like
    test-tracking.md where multiple sections each have their own table with identical columns.

    This eliminates hardcoded column indices — callers access $row.'Column Name' instead
    of $cells[N].

    .PARAMETER Content
    The full file content as a string.

    .PARAMETER Section
    Optional heading text to scope the search (e.g., "## E2E Test Cases").
    If specified, only parses the first table found after this heading and before
    the next heading of equal or higher level.

    .PARAMETER IncludeLineNumber
    If set, each returned object includes a '_LineNumber' property with the
    1-based line number of the row in the original content. Useful for scripts
    that need to update rows in-place.

    .PARAMETER IncludeRawLine
    If set, each returned object includes a '_RawLine' property with the original
    line text. Useful for debugging or pass-through operations.

    .PARAMETER AllTables
    If set, continues parsing after a table ends and collects rows from all subsequent
    tables in the search range. Tables with different headers are skipped (only tables
    matching the first table's column schema are included). Useful for files with
    multiple sections that each have their own identically-structured table.

    .PARAMETER ResolveLinkColumn
    Array of column names whose values should be passed through Get-MarkdownLinkText
    to extract display text from markdown links. The original link is preserved in
    a property named '<ColumnName>_Link'.

    .OUTPUTS
    [PSObject[]] Array of objects, one per data row. Returns empty array if no table found.

    .EXAMPLE
    $rows = ConvertFrom-MarkdownTable -Content (Get-Content "test-tracking.md" -Raw) -Section "## Automated Tests"
    $rows | Where-Object { $_.'Status' -eq '✅ Passing' }

    .EXAMPLE
    $rows = ConvertFrom-MarkdownTable -Content $content -Section "## E2E Test Cases" -IncludeLineNumber -ResolveLinkColumn @("Test File/Case")
    foreach ($row in $rows) {
        Write-Host "$($row.'Test ID') at line $($row._LineNumber): $($row.'Test File/Case')"
    }
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$false)]
        [string]$Section,

        [Parameter(Mandatory=$false)]
        [switch]$IncludeLineNumber,

        [Parameter(Mandatory=$false)]
        [switch]$IncludeRawLine,

        [Parameter(Mandatory=$false)]
        [switch]$AllTables,

        [Parameter(Mandatory=$false)]
        [string[]]$ResolveLinkColumn = @()
    )

    $lines = $Content -split '\r?\n'
    $results = @()

    # Determine search range
    $startIdx = 0
    $endIdx = $lines.Count - 1

    if ($Section) {
        # Find the section heading
        $sectionFound = $false
        # Determine the heading level from the section pattern
        $sectionLevel = 0
        if ($Section -match '^(#{1,6})\s') {
            $sectionLevel = $matches[1].Length
        }

        # Anchor heading match to start-of-line to avoid false-positive matches on
        # rows whose cell content quotes the heading text (e.g., an Intake row
        # describing a bug in the script that hardcodes '## Section 2 — Improvements'
        # would otherwise be picked up as the section start before the real heading
        # at column 0).
        $sectionPattern = '^' + [regex]::Escape($Section) + '\s*$'
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match $sectionPattern) {
                $startIdx = $i + 1
                $sectionFound = $true
                break
            }
        }

        if (-not $sectionFound) {
            Write-Warning "ConvertFrom-MarkdownTable: Section '$Section' not found"
            return @()
        }

        # Find the end of this section (next heading of equal or higher level)
        # When AllTables is set, don't limit the range — scan the entire file from the section start
        if (-not $AllTables) {
            if ($sectionLevel -gt 0) {
                $endPattern = "^#{1,$sectionLevel}\s"
            } else {
                $endPattern = "^##\s"
            }

            for ($i = $startIdx; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match $endPattern) {
                    $endIdx = $i - 1
                    break
                }
            }
        }
    }

    # Find the table within the search range
    $headers = @()
    $tableFound = $false

    $inTable = $false

    for ($i = $startIdx; $i -le $endIdx; $i++) {
        # Empty/whitespace lines end the current table
        if ([string]::IsNullOrWhiteSpace($lines[$i])) {
            if ($inTable) {
                $inTable = $false
                if (-not $AllTables) { break }
            }
            continue
        }

        $cells = Split-MarkdownTableRow $lines[$i]
        if ($null -eq $cells) {
            # A '|'-started line that fails row-parse inside a table is damaged data
            # (e.g. a row missing its closing pipe), not the end of the table. Skip it
            # with a warning instead of silently dropping every row after it — one
            # malformed row previously blinded callers to the whole table tail
            # (PF-IMP-1393 (a)). Prose, headings, and blank lines still end the table.
            if ($inTable -and $lines[$i] -match '^\s*\|') {
                $preview = $lines[$i].Substring(0, [Math]::Min(80, $lines[$i].Length))
                Write-Warning "ConvertFrom-MarkdownTable: malformed table row at line $($i + 1) skipped (missing closing '|'?): $preview"
                continue
            }
            if ($inTable) {
                $inTable = $false
                if (-not $AllTables) { break }
            }
            continue
        }

        # Skip separator rows
        if ($lines[$i] -match '^\|[\s\-:|]+\|$') { continue }

        if (-not $inTable) {
            # This is a header row for a new table
            if (-not $tableFound) {
                # First table — adopt its headers
                $headers = $cells
                $tableFound = $true
                $inTable = $true
            } elseif ($AllTables) {
                # Subsequent table — check if schema matches the first table
                $headersMatch = ($cells.Count -eq $headers.Count)
                if ($headersMatch) {
                    for ($h = 0; $h -lt $cells.Count; $h++) {
                        if ($cells[$h] -ne $headers[$h]) { $headersMatch = $false; break }
                    }
                }
                $inTable = $headersMatch  # only parse rows if headers match
            }
            continue
        }

        # Data row — build PSObject using the established headers
        $obj = [ordered]@{}
        for ($j = 0; $j -lt $headers.Count; $j++) {
            $headerName = $headers[$j]
            if ($headerName -eq '') { continue }
            $cellValue = if ($j -lt $cells.Count) { $cells[$j] } else { '' }

            # Resolve link columns
            if ($ResolveLinkColumn -contains $headerName) {
                $obj["${headerName}_Link"] = $cellValue
                $obj[$headerName] = Get-MarkdownLinkText $cellValue
            } else {
                $obj[$headerName] = $cellValue
            }
        }

        if ($IncludeLineNumber) {
            $obj['_LineNumber'] = $i
        }
        if ($IncludeRawLine) {
            $obj['_RawLine'] = $lines[$i]
        }

        $results += [PSCustomObject]$obj
    }

    return $results
}

#endregion Low-Level Helpers

#region High-Level Operations (v1.0)

function Update-MarkdownTable {
    <#
    .SYNOPSIS
    Updates a markdown table with new values for a specific feature ID

    .PARAMETER Content
    The full content of the markdown file

    .PARAMETER FeatureId
    The value to match in the target column (default: first column). Despite the name,
    this can match any value — use MatchColumn to specify which column to search.

    .PARAMETER MatchColumn
    The column name to match FeatureId against. Defaults to the first column (index 0).
    Use this when the match value isn't in the first column (e.g., "Feature ID" in test-tracking.md).

    .PARAMETER StatusColumn
    The column name to update with the status

    .PARAMETER Status
    The new status value

    .PARAMETER AdditionalUpdates
    Hashtable of additional column updates (column name -> value)

    .PARAMETER Notes
    Additional notes to append to the Notes column

    .EXAMPLE
    $updatedContent = Update-MarkdownTable -Content $content -FeatureId "1.2.3" -StatusColumn "Status" -Status "🟢 Completed"

    .EXAMPLE
    # Match on Feature ID column (not first column)
    $updatedContent = Update-MarkdownTable -Content $content -FeatureId "0.1.1" -MatchColumn "Feature ID" -StatusColumn "Status" -Status "✅ Audit Approved"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$false)]
        [string]$MatchColumn,

        [Parameter(Mandatory=$true)]
        [string]$StatusColumn,

        [Parameter(Mandatory=$true)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalUpdates = @{},

        [Parameter(Mandatory=$false)]
        [string]$Notes
    )

    $lines = $Content -split '\r?\n'
    $updatedLines = @()
    $inTable = $false
    $headers = @()
    $columnIndices = @{}

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Detect table start (header line with pipes)
        if ($line -match '^\|.*\|$' -and -not $inTable) {
            $inTable = $true
            $headers = Split-MarkdownTableRow $line

            for ($j = 0; $j -lt $headers.Count; $j++) {
                if ($headers[$j] -ne '') {
                    $columnIndices[$headers[$j]] = $j
                }
            }

            $updatedLines += $line
            continue
        }

        # Skip separator line
        if ($inTable -and $line -match '^\|[-\s:]+\|$') {
            $updatedLines += $line
            continue
        }

        # Process table rows
        if ($inTable -and $line -match '^\|.*\|$') {
            $columns = Split-MarkdownTableRow $line

            # Check if this row contains our feature ID
            $cellValue = Get-MarkdownLinkText $columns[0]
            if ($columns.Count -gt 0 -and $cellValue -eq $FeatureId) {
                # Ensure we have exactly the right number of columns to match the header
                $headerCount = $headers.Count
                while ($columns.Count -lt $headerCount) {
                    $columns += ""
                }
                if ($columns.Count -gt $headerCount) {
                    $columns = $columns[0..($headerCount-1)]
                }

                # Update the specified columns
                if ($columnIndices.ContainsKey($StatusColumn)) {
                    $statusIndex = $columnIndices[$StatusColumn]
                    if ($statusIndex -lt $columns.Count) {
                        $columns[$statusIndex] = $Status
                    }
                } else {
                    throw "Update-MarkdownTable: StatusColumn '$StatusColumn' not found in table headers. Available columns: $($columnIndices.Keys -join ', '). Status update for '$FeatureId' cannot be applied."
                }

                # Apply additional updates
                foreach ($columnName in $AdditionalUpdates.Keys) {
                    if ($columnIndices.ContainsKey($columnName)) {
                        $updateIndex = $columnIndices[$columnName]
                        if ($updateIndex -lt $columns.Count) {
                            $columns[$updateIndex] = $AdditionalUpdates[$columnName]
                        }
                    } else {
                        throw "Update-MarkdownTable: AdditionalUpdates column '$columnName' not found in table headers. Available columns: $($columnIndices.Keys -join ', '). Update for '$FeatureId' cannot be applied."
                    }
                }

                # Add notes if specified and Notes column exists
                if ($Notes -and $columnIndices.ContainsKey("Notes")) {
                    $notesIndex = $columnIndices["Notes"]
                    if ($notesIndex -lt $columns.Count) {
                        $existingNotes = $columns[$notesIndex]
                        if ($existingNotes -and $existingNotes -ne "-" -and $existingNotes -ne "") {
                            $columns[$notesIndex] = "$existingNotes; $Notes"
                        } else {
                            $columns[$notesIndex] = $Notes
                        }
                    }
                }

                $updatedLines += ConvertTo-MarkdownTableRow -Cells $columns
            } else {
                $updatedLines += $line
            }
        }
        # End of table detection
        elseif ($inTable -and $line -notmatch '^\|.*\|$') {
            $inTable = $false
            $updatedLines += $line
        }
        else {
            $updatedLines += $line
        }
    }

    return $updatedLines -join "`n"
}

function Update-MarkdownTableWithAppend {
    <#
    .SYNOPSIS
    Updates a markdown table with new values for a specific feature ID, with support for appending to existing content

    .PARAMETER Content
    The full content of the markdown file

    .PARAMETER FeatureId
    The feature ID to locate and update

    .PARAMETER StatusColumn
    The column name to update with the status

    .PARAMETER Status
    The new status value

    .PARAMETER AdditionalUpdates
    Hashtable of additional column updates (column name -> value) - replaces existing content

    .PARAMETER AppendUpdates
    Hashtable of column updates that should be appended with " • " separator (column name -> value)

    .PARAMETER Notes
    Additional notes to append to the Notes column

    .EXAMPLE
    $appendUpdates = @{ "Notes" = "Additional context" }
    $updatedContent = Update-MarkdownTableWithAppend -Content $content -FeatureId "1.2.3" -StatusColumn "Status" -Status "🟢 Completed" -AppendUpdates $appendUpdates
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$false)]
        [string]$StatusColumn,

        [Parameter(Mandatory=$false)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalUpdates = @{},

        [Parameter(Mandatory=$false)]
        [hashtable]$AppendUpdates = @{},

        [Parameter(Mandatory=$false)]
        [string]$Notes
    )

    $lines = $Content -split '\r?\n'
    $updatedLines = @()
    $inTable = $false
    $headers = @()
    $columnIndices = @{}

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Detect table start (header line with pipes)
        if ($line -match '^\|.*\|$' -and -not $inTable) {
            $inTable = $true
            $headers = Split-MarkdownTableRow $line

            for ($j = 0; $j -lt $headers.Count; $j++) {
                if ($headers[$j] -ne '') {
                    $columnIndices[$headers[$j]] = $j
                }
            }

            $updatedLines += $line
            continue
        }

        # Skip separator line
        if ($inTable -and $line -match '^\|[-\s:]+\|$') {
            $updatedLines += $line
            continue
        }

        # Process table rows
        if ($inTable -and $line -match '^\|.*\|$') {
            $columns = Split-MarkdownTableRow $line

            # Check if this row contains our feature ID
            $cellValue = Get-MarkdownLinkText $columns[0]
            if ($columns.Count -gt 0 -and $cellValue -eq $FeatureId) {
                # Ensure we have exactly the right number of columns to match the header
                $headerCount = $headers.Count
                while ($columns.Count -lt $headerCount) {
                    $columns += ""
                }
                if ($columns.Count -gt $headerCount) {
                    $columns = $columns[0..($headerCount-1)]
                }

                # Update the status column if specified
                if ($StatusColumn -and $Status -and $columnIndices.ContainsKey($StatusColumn)) {
                    $statusIndex = $columnIndices[$StatusColumn]
                    if ($statusIndex -lt $columns.Count) {
                        $columns[$statusIndex] = $Status
                    }
                } elseif ($StatusColumn -and $Status) {
                    throw "Update-MarkdownTableWithAppend: StatusColumn '$StatusColumn' not found in table headers. Available columns: $($columnIndices.Keys -join ', '). Status update for '$FeatureId' cannot be applied."
                }

                # Apply additional updates (replace existing content)
                foreach ($columnName in $AdditionalUpdates.Keys) {
                    if ($columnIndices.ContainsKey($columnName)) {
                        $updateIndex = $columnIndices[$columnName]
                        if ($updateIndex -lt $columns.Count) {
                            $columns[$updateIndex] = $AdditionalUpdates[$columnName]
                        }
                    } else {
                        throw "Update-MarkdownTableWithAppend: AdditionalUpdates column '$columnName' not found in table headers. Available columns: $($columnIndices.Keys -join ', '). Update for '$FeatureId' cannot be applied."
                    }
                }

                # Apply append updates (append with bullet separator)
                foreach ($columnName in $AppendUpdates.Keys) {
                    if ($columnIndices.ContainsKey($columnName)) {
                        $appendIndex = $columnIndices[$columnName]
                        if ($appendIndex -lt $columns.Count) {
                            $existingContent = $columns[$appendIndex]
                            $newContent = $AppendUpdates[$columnName]

                            if ($existingContent -and $existingContent -ne "-" -and $existingContent -ne "" -and $existingContent -ne "Yes" -and $existingContent -ne "No") {
                                $columns[$appendIndex] = "$existingContent • $newContent"
                            } else {
                                $columns[$appendIndex] = $newContent
                            }
                        }
                    } else {
                        throw "Update-MarkdownTableWithAppend: AppendUpdates column '$columnName' not found in table headers. Available columns: $($columnIndices.Keys -join ', '). Update for '$FeatureId' cannot be applied."
                    }
                }

                # Add notes if specified and Notes column exists
                if ($Notes -and $columnIndices.ContainsKey("Notes")) {
                    $notesIndex = $columnIndices["Notes"]
                    if ($notesIndex -lt $columns.Count) {
                        $existingNotes = $columns[$notesIndex]
                        if ($existingNotes -and $existingNotes -ne "-" -and $existingNotes -ne "") {
                            $columns[$notesIndex] = "$existingNotes; $Notes"
                        } else {
                            $columns[$notesIndex] = $Notes
                        }
                    }
                }

                $updatedLines += ConvertTo-MarkdownTableRow -Cells $columns
            } else {
                $updatedLines += $line
            }
        }
        # End of table detection
        elseif ($inTable -and $line -notmatch '^\|.*\|$') {
            $inTable = $false
            $updatedLines += $line
        }
        else {
            $updatedLines += $line
        }
    }

    return $updatedLines -join "`n"
}

function Move-MarkdownTableRow {
    <#
    .SYNOPSIS
    Removes a row from a source markdown table section and inserts a reformatted row into a destination section.

    .DESCRIPTION
    Generic helper for moving rows between markdown table sections. Used by scripts that need to
    move items between "active" and "completed/archived" tables (e.g., process improvements, feature archiving).

    The function:
    1. Finds the row matching RowIdPattern in the source section
    2. Parses its columns using the source table headers
    3. Removes the row from the source section
    4. Builds a new row using ColumnMapping and AdditionalColumns
    5. Inserts the new row into the destination section

    .PARAMETER Content
    The full markdown file content as a string.

    .PARAMETER RowIdPattern
    Regex pattern to match the target row (e.g., "PF-IMP-173", "4\.1\.1").
    Matched against the full row text.

    .PARAMETER SourceSection
    Heading text that marks the start of the source section (e.g., "## Current Improvement Opportunities").
    The row is searched for only within this section.

    .PARAMETER DestinationSection
    Heading text that marks the start of the destination section (e.g., "## Completed Improvements").
    The new row is inserted after the last data row in the first table found in this section.

    .PARAMETER ColumnMapping
    Ordered hashtable mapping destination column names to source column names.
    Example: [ordered]@{ "ID" = "ID"; "Feature" = "Feature" }
    The destination row columns are built in the order of this hashtable's keys.

    .PARAMETER AdditionalColumns
    Ordered hashtable of destination column names to literal values (not sourced from the original row).
    Example: [ordered]@{ "Archive Date" = "2026-03-24"; "Rationale" = "Generalized into framework" }
    These are merged with ColumnMapping — if a key exists in both, AdditionalColumns wins.

    .PARAMETER SectionEndPattern
    Regex pattern that marks the end of a section search. Defaults to "^\s*</details>" for
    sections inside <details> blocks. Set to "^## " for sections delimited by headings.

    .OUTPUTS
    Hashtable with keys:
    - Content: the modified markdown content (or $null on failure)
    - SourceRow: the original row text that was removed
    - SourceColumns: hashtable of parsed column name → value from the source row
    - DestinationRow: the new row text that was inserted

    .EXAMPLE
    $result = Move-MarkdownTableRow -Content $content `
        -RowIdPattern "PF-IMP-173" `
        -SourceSection "## Current Improvement Opportunities" `
        -DestinationSection "## Completed Improvements" `
        -ColumnMapping ([ordered]@{ "ID" = "ID"; "Description" = "Description" }) `
        -AdditionalColumns ([ordered]@{ "Completed Date" = "2026-03-24"; "Impact" = "MEDIUM" })
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$RowIdPattern,

        [Parameter(Mandatory=$true)]
        [string]$SourceSection,

        [Parameter(Mandatory=$true)]
        [string]$DestinationSection,

        [Parameter(Mandatory=$true)]
        [System.Collections.Specialized.OrderedDictionary]$ColumnMapping,

        [Parameter(Mandatory=$false)]
        [System.Collections.Specialized.OrderedDictionary]$AdditionalColumns,

        [Parameter(Mandatory=$false)]
        [string]$SectionEndPattern = '^\s*</details>',

        # Two-file mode: when provided, the destination section is searched
        # in $DestinationContent (a separate file's content) instead of in
        # $Content. Source removal still operates on $Content; destination
        # insert operates on $DestinationContent. Result hashtable adds a
        # DestinationContent key carrying the modified destination string.
        # Use this for archive-split layouts where the source section and
        # destination section live in different files.
        [Parameter(Mandatory=$false)]
        [AllowNull()]
        [string]$DestinationContent
    )

    $twoFile = $PSBoundParameters.ContainsKey('DestinationContent')
    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")
    if ($twoFile) {
        $destLines = [System.Collections.ArrayList]@($DestinationContent -split "\r?\n")
    } else {
        $destLines = $lines
    }

    # --- Step 1: Find the source section and parse its table ---
    # Anchor section match to start-of-line (see ConvertFrom-MarkdownTable rationale).
    $sourceHeadingPattern = '^' + [regex]::Escape($SourceSection) + '\s*$'
    $sourceStartIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $sourceHeadingPattern) {
            $sourceStartIdx = $i
            break
        }
    }

    if ($sourceStartIdx -eq -1) {
        Write-Warning "Move-MarkdownTableRow: Source section '$SourceSection' not found"
        return @{ Content = $null; SourceRow = $null; SourceColumns = $null; DestinationRow = $null }
    }

    # Find the table header within the source section
    $sourceHeaders = @()
    $sourceHeaderIdx = -1
    for ($i = $sourceStartIdx + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## ' -and $i -ne $sourceStartIdx) { break }  # next section
        $headerCells = Split-MarkdownTableRow $lines[$i]
        if ($null -ne $headerCells -and $lines[$i] -notmatch '^\|[-\s:]+\|$') {
            # First non-separator table row is the header
            $sourceHeaders = $headerCells
            $sourceHeaderIdx = $i
            break
        }
    }

    if ($sourceHeaderIdx -eq -1) {
        Write-Warning "Move-MarkdownTableRow: No table found in source section '$SourceSection'"
        return @{ Content = $null; SourceRow = $null; SourceColumns = $null; DestinationRow = $null }
    }

    # --- Step 2: Find and remove the matching row ---
    # Match $RowIdPattern only against the trimmed first cell (anchored with ^...$).
    # Closes the defect class shared with PF-IMP-693/PF-IMP-694: an unanchored
    # regex would match the row id anywhere in any column, picking up rows that
    # merely reference the id in their Description/Notes.
    $rowIndex = -1
    $sourceRowText = $null
    for ($i = $sourceHeaderIdx + 1; $i -lt $lines.Count; $i++) {
        # Stop at section boundaries
        if ($lines[$i] -match '^## ' -or ($SectionEndPattern -and $lines[$i] -match $SectionEndPattern)) { break }
        if ($lines[$i] -match '^\|[-\s:|]+$') { continue }  # skip separator
        $candidateCells = Split-MarkdownTableRow $lines[$i]
        if ($null -eq $candidateCells -or $candidateCells.Count -eq 0) { continue }  # not a table row
        if ($candidateCells[0].Trim() -match "^$RowIdPattern$") {
            $rowIndex = $i
            $sourceRowText = $lines[$i]
            break
        }
    }

    if ($rowIndex -eq -1) {
        Write-Warning "Move-MarkdownTableRow: Row matching '$RowIdPattern' not found in source section"
        return @{ Content = $null; SourceRow = $null; SourceColumns = $null; DestinationRow = $null }
    }

    # Parse source row columns
    $colValues = Split-MarkdownTableRow $sourceRowText

    $sourceColumns = @{}
    for ($j = 0; $j -lt [Math]::Min($sourceHeaders.Count, $colValues.Count); $j++) {
        if ($sourceHeaders[$j] -ne '') {
            $sourceColumns[$sourceHeaders[$j]] = $colValues[$j]
        }
    }

    # Remove the row
    $lines.RemoveAt($rowIndex)

    # --- Step 3: Build the destination row ---
    $destColValues = @()
    foreach ($destCol in $ColumnMapping.Keys) {
        $sourceCol = $ColumnMapping[$destCol]
        if ($AdditionalColumns -and $AdditionalColumns.Contains($destCol)) {
            $destColValues += $AdditionalColumns[$destCol]
        } elseif ($sourceColumns.ContainsKey($sourceCol)) {
            $destColValues += $sourceColumns[$sourceCol]
        } else {
            $destColValues += "—"
        }
    }

    # Add any AdditionalColumns not already in ColumnMapping
    if ($AdditionalColumns) {
        foreach ($extraCol in $AdditionalColumns.Keys) {
            if (-not $ColumnMapping.Contains($extraCol)) {
                $destColValues += $AdditionalColumns[$extraCol]
            }
        }
    }

    $destinationRow = ConvertTo-MarkdownTableRow -Cells $destColValues

    # --- Step 4: Insert into destination section ---
    # When -DestinationContent was supplied, the destination section lives in
    # a separate file's content ($destLines); otherwise $destLines aliases
    # $lines and behavior matches the single-file case.
    # Anchor section match to start-of-line (same rationale as source search).
    $destHeadingPattern = '^' + [regex]::Escape($DestinationSection) + '\s*$'
    $destStartIdx = -1
    for ($i = 0; $i -lt $destLines.Count; $i++) {
        if ($destLines[$i] -match $destHeadingPattern) {
            $destStartIdx = $i
            break
        }
    }

    if ($destStartIdx -eq -1) {
        Write-Warning "Move-MarkdownTableRow: Destination section '$DestinationSection' not found"
        return @{ Content = $null; DestinationContent = $null; SourceRow = $sourceRowText; SourceColumns = $sourceColumns; DestinationRow = $destinationRow }
    }

    # Find insertion point: after the last data row in the destination table
    $insertAfterIdx = -1
    for ($i = $destStartIdx + 1; $i -lt $destLines.Count; $i++) {
        if ($destLines[$i] -match '^## ' -and $i -ne $destStartIdx) { break }
        if ($SectionEndPattern -and $destLines[$i] -match $SectionEndPattern) { break }
        # Match data rows (not headers, not separators)
        if ($destLines[$i] -match '^\|[^-]' -and $destLines[$i] -notmatch '^\|\s*(ID|Feature|Date|Status)\s*\|') {
            $insertAfterIdx = $i
        }
    }

    # If no data rows, insert after the separator line
    if ($insertAfterIdx -eq -1) {
        for ($i = $destStartIdx + 1; $i -lt $destLines.Count; $i++) {
            if ($destLines[$i] -match '^## ' -and $i -ne $destStartIdx) { break }
            if ($SectionEndPattern -and $destLines[$i] -match $SectionEndPattern) { break }
            if ($destLines[$i] -match '^\|[-\s:|]+$') {
                $insertAfterIdx = $i
                break
            }
        }
    }

    if ($insertAfterIdx -eq -1) {
        Write-Warning "Move-MarkdownTableRow: Could not find insertion point in destination section '$DestinationSection'"
        return @{ Content = $null; DestinationContent = $null; SourceRow = $sourceRowText; SourceColumns = $sourceColumns; DestinationRow = $destinationRow }
    }

    $destLines.Insert($insertAfterIdx + 1, $destinationRow)

    if ($twoFile) {
        return @{
            Content = ($lines -join "`r`n")
            DestinationContent = ($destLines -join "`r`n")
            SourceRow = $sourceRowText
            SourceColumns = $sourceColumns
            DestinationRow = $destinationRow
        }
    }

    return @{
        Content = ($lines -join "`r`n")
        SourceRow = $sourceRowText
        SourceColumns = $sourceColumns
        DestinationRow = $destinationRow
    }
}

function Add-MarkdownTableRow {
    <#
    .SYNOPSIS
    Idempotently inserts or updates a row in a markdown table scoped to a heading.

    .DESCRIPTION
    Anchors on a heading (e.g. "### Design Documentation"), finds the first table
    inside that section, and either appends a new data row or updates the existing
    row whose key column matches $KeyValue. The section ends at the next heading of
    equal or higher level. Idempotency: re-invoking with the same inputs replaces
    the matching row (or no-ops if every cell already matches), never duplicates it.

    Pure markdown manipulation — no knowledge of state files or repo paths. State-
    file-aware callers (e.g. Add-StateFileDocumentationInventoryRow) should wrap this.

    .PARAMETER Content
    The full file content as a single string. Line endings preserved on output.

    .PARAMETER SectionHeading
    Exact heading line that anchors the table (e.g. "### Design Documentation").
    Compared trimmed-end against each line. The section's end is the next heading
    line whose hash count is <= the anchor's hash count.

    .PARAMETER KeyColumn
    Header name of the column used to identify rows for the upsert (e.g. "Document").
    Must be present in the table headers.

    .PARAMETER KeyValue
    Value to match against the KeyColumn cell. Compared after stripping markdown link
    wrappers from the cell value (so "[PD-FDD-005](path)" matches "PD-FDD-005").
    With -MatchKeyByPrefix, matches when the cell's link-stripped value STARTS WITH
    "$KeyValue" followed by end-of-string or a non-word boundary — handles cells like
    "PD-ASS-003 Tier Assessment" matching key "PD-ASS-003".

    .PARAMETER Row
    Hashtable of column name -> cell value. Keys must match table headers; unknown
    keys are skipped with a warning. Missing columns default to empty string on
    insert; on update, existing cell values are preserved for columns not in $Row.

    .PARAMETER MatchKeyByPrefix
    If set, key matching is prefix-based (with word-boundary anchoring). Without it,
    matching is exact (after link-text extraction).

    .OUTPUTS
    Hashtable with keys:
      Content    - updated file content (or original if Action was a no-op or failure)
      Action     - 'Inserted' | 'Updated' | 'NoOp' | 'SectionNotFound' | 'TableNotFound' | 'KeyColumnNotFound'
      LineNumber - 1-based line of the affected row (0 on failure)
      Message    - human-readable detail
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$SectionHeading,

        [Parameter(Mandatory=$true)]
        [string]$KeyColumn,

        [Parameter(Mandatory=$true)]
        [string]$KeyValue,

        [Parameter(Mandatory=$true)]
        [hashtable]$Row,

        [Parameter(Mandatory=$false)]
        [switch]$MatchKeyByPrefix
    )

    # Detect line ending so output preserves the file's existing convention
    $newline = if ($Content -match "`r`n") { "`r`n" } else { "`n" }
    $lines = $Content -split "`r?`n"

    # Determine anchor heading level (number of leading #s)
    $anchorLevel = 0
    if ($SectionHeading -match '^(#{1,6})\s') { $anchorLevel = $matches[1].Length }
    if ($anchorLevel -eq 0) {
        Write-Warning "Add-MarkdownTableRow: SectionHeading '$SectionHeading' is not a markdown heading (must start with 1-6 # characters)."
        return @{ Content = $Content; Action = 'SectionNotFound'; LineNumber = 0; Message = "Invalid SectionHeading" }
    }

    # Find anchor heading line (trimmed-end exact match)
    $anchorTrim = $SectionHeading.TrimEnd()
    $anchorIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimEnd() -eq $anchorTrim) { $anchorIdx = $i; break }
    }
    if ($anchorIdx -lt 0) {
        Write-Warning "Add-MarkdownTableRow: Section heading '$SectionHeading' not found."
        return @{ Content = $Content; Action = 'SectionNotFound'; LineNumber = 0; Message = "Heading '$SectionHeading' not found" }
    }

    # Compute section end (next heading of equal or higher level, or EOF)
    $endIdx = $lines.Count - 1
    $endPattern = "^#{1,$anchorLevel}\s"
    for ($i = $anchorIdx + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $endPattern) { $endIdx = $i - 1; break }
    }

    # Find the table within (anchorIdx, endIdx]: first non-separator pipe row is header
    $headerIdx = -1
    $separatorIdx = -1
    for ($i = $anchorIdx + 1; $i -le $endIdx; $i++) {
        if ($lines[$i] -match '^\|[-\s:|]+\|\s*$') { continue }   # not header (it's a separator alone)
        if ($lines[$i] -match '^\|.*\|\s*$') {
            $headerIdx = $i
            # Verify next non-blank line is a separator
            for ($j = $i + 1; $j -le $endIdx; $j++) {
                if ([string]::IsNullOrWhiteSpace($lines[$j])) { continue }
                if ($lines[$j] -match '^\|[-\s:|]+\|\s*$') { $separatorIdx = $j }
                break
            }
            break
        }
    }
    if ($headerIdx -lt 0 -or $separatorIdx -lt 0) {
        Write-Warning "Add-MarkdownTableRow: No table found under heading '$SectionHeading'."
        return @{ Content = $Content; Action = 'TableNotFound'; LineNumber = 0; Message = "No table found in section" }
    }

    $headers = Split-MarkdownTableRow $lines[$headerIdx]
    if (-not $headers -or $headers.Count -eq 0) {
        Write-Warning "Add-MarkdownTableRow: Could not parse headers in table under '$SectionHeading'."
        return @{ Content = $Content; Action = 'TableNotFound'; LineNumber = 0; Message = "Empty headers" }
    }

    # Verify KeyColumn exists
    $keyColIdx = -1
    for ($k = 0; $k -lt $headers.Count; $k++) {
        if ($headers[$k] -eq $KeyColumn) { $keyColIdx = $k; break }
    }
    if ($keyColIdx -lt 0) {
        Write-Warning "Add-MarkdownTableRow: KeyColumn '$KeyColumn' not found in table headers ($($headers -join ', '))."
        return @{ Content = $Content; Action = 'KeyColumnNotFound'; LineNumber = 0; Message = "KeyColumn '$KeyColumn' missing" }
    }

    # Warn on unknown $Row keys (continue with known keys only)
    foreach ($rowKey in @($Row.Keys)) {
        if ($headers -notcontains $rowKey) {
            Write-Warning "Add-MarkdownTableRow: Row key '$rowKey' not in table headers; ignored. Available: $($headers -join ', ')"
        }
    }

    # Walk data rows (separatorIdx+1 to first non-pipe-or-end)
    $dataStartIdx = $separatorIdx + 1
    $lastDataIdx = $separatorIdx   # if table is empty, append after separator
    $matchIdx = -1
    for ($i = $dataStartIdx; $i -le $endIdx; $i++) {
        if ([string]::IsNullOrWhiteSpace($lines[$i])) { break }
        if ($lines[$i] -notmatch '^\|.*\|\s*$') { break }
        if ($lines[$i] -match '^\|[-\s:|]+\|\s*$') { break }   # stray separator ends table
        $lastDataIdx = $i

        $cells = Split-MarkdownTableRow $lines[$i]
        if ($null -eq $cells -or $cells.Count -le $keyColIdx) { continue }
        $cellLinkText = Get-MarkdownLinkText $cells[$keyColIdx]
        $isMatch = $false
        if ($MatchKeyByPrefix) {
            # Prefix match anchored at start, with word-boundary or end-of-string trailing
            if ($cellLinkText -match ("^" + [regex]::Escape($KeyValue) + "(\b|$)")) { $isMatch = $true }
        } else {
            if ($cellLinkText -eq $KeyValue) { $isMatch = $true }
        }
        if ($isMatch) { $matchIdx = $i; break }
    }

    # Build a cells array from $Row (used for both insert and update)
    $newCells = New-Object string[] $headers.Count
    for ($h = 0; $h -lt $headers.Count; $h++) { $newCells[$h] = '' }

    if ($matchIdx -ge 0) {
        # UPDATE: start from existing cells, then override columns from $Row
        $existing = Split-MarkdownTableRow $lines[$matchIdx]
        for ($h = 0; $h -lt $headers.Count; $h++) {
            $newCells[$h] = if ($h -lt $existing.Count) { $existing[$h] } else { '' }
        }
        for ($h = 0; $h -lt $headers.Count; $h++) {
            if ($Row.ContainsKey($headers[$h])) { $newCells[$h] = [string]$Row[$headers[$h]] }
        }
        $newRow = ConvertTo-MarkdownTableRow -Cells $newCells
        if ($newRow -eq $lines[$matchIdx].TrimEnd()) {
            return @{ Content = $Content; Action = 'NoOp'; LineNumber = ($matchIdx + 1); Message = "Row already matches; no change" }
        }
        $lines[$matchIdx] = $newRow
        return @{
            Content    = ($lines -join $newline)
            Action     = 'Updated'
            LineNumber = ($matchIdx + 1)
            Message    = "Row updated in section '$SectionHeading'"
        }
    }

    # INSERT: build new row from $Row only
    for ($h = 0; $h -lt $headers.Count; $h++) {
        if ($Row.ContainsKey($headers[$h])) { $newCells[$h] = [string]$Row[$headers[$h]] }
    }
    $newRow = ConvertTo-MarkdownTableRow -Cells $newCells

    # Insert immediately after the last data row (or after separator if table is empty)
    $insertAt = $lastDataIdx + 1
    $newLineList = New-Object System.Collections.ArrayList
    [void]$newLineList.AddRange($lines)
    [void]$newLineList.Insert($insertAt, $newRow)

    return @{
        Content    = ($newLineList -join $newline)
        Action     = 'Inserted'
        LineNumber = ($insertAt + 1)
        Message    = "Row inserted into section '$SectionHeading'"
    }
}

function Remove-MarkdownSection {
    <#
    .SYNOPSIS
    Removes a heading-anchored section (the heading and everything under it up to the
    next heading of equal or higher level) from markdown content.

    .DESCRIPTION
    Pure markdown manipulation — no knowledge of state files or repo paths. Locates the
    heading line (exact trimmed-end match), reads its level from the leading '#' count,
    and deletes from that heading through the line immediately before the next heading
    whose level is equal or higher (or end-of-content if none follows). The blank line
    preceding the removed heading is left in place as the separator before the following
    heading. Line endings are preserved. No-ops (returns content unchanged, Action
    'NotFound') when the heading is absent, so callers can strip an optional subsection
    unconditionally.

    Used to drop a conditional subsection from a freshly created document — e.g.
    New-FeatureImplementationState.ps1 omits the onboarding-only "Existing Project
    Documentation" subsection from greenfield state files.

    .PARAMETER Content
    The full document content as a single string. Line endings preserved on output.

    .PARAMETER SectionHeading
    Exact heading line that anchors the section (e.g. "### Existing Project Documentation").
    Compared trimmed-end against each line. The section ends at the next heading line whose
    hash count is <= the anchor's hash count.

    .OUTPUTS
    Hashtable with keys:
      Content    - updated content (or original when Action is 'NotFound')
      Action     - 'Removed' | 'NotFound'
      LineNumber - 1-based line of the removed heading (0 when not found)
      Message    - human-readable detail
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$SectionHeading
    )

    $newline = if ($Content -match "`r`n") { "`r`n" } else { "`n" }
    $lines = $Content -split "`r?`n"

    # Determine anchor heading level (number of leading #s)
    $anchorLevel = 0
    if ($SectionHeading -match '^(#{1,6})\s') { $anchorLevel = $matches[1].Length }
    if ($anchorLevel -eq 0) {
        Write-Warning "Remove-MarkdownSection: SectionHeading '$SectionHeading' is not a markdown heading (must start with 1-6 # characters)."
        return @{ Content = $Content; Action = 'NotFound'; LineNumber = 0; Message = "Invalid SectionHeading" }
    }

    # Find anchor heading line (trimmed-end exact match)
    $anchorTrim = $SectionHeading.TrimEnd()
    $anchorIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimEnd() -eq $anchorTrim) { $anchorIdx = $i; break }
    }
    if ($anchorIdx -lt 0) {
        return @{ Content = $Content; Action = 'NotFound'; LineNumber = 0; Message = "Heading '$SectionHeading' not found" }
    }

    # Section end: next heading of equal or higher level (<= anchor level), else EOF
    $nextHeadingIdx = $lines.Count
    $endPattern = "^#{1,$anchorLevel}\s"
    for ($i = $anchorIdx + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $endPattern) { $nextHeadingIdx = $i; break }
    }

    # Keep everything except [anchorIdx, nextHeadingIdx) — the blank line before the
    # anchor (kept) becomes the separator before the following heading.
    $kept = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($i -ge $anchorIdx -and $i -lt $nextHeadingIdx) { continue }
        $kept.Add($lines[$i])
    }

    return @{
        Content    = ($kept -join $newline)
        Action     = 'Removed'
        LineNumber = ($anchorIdx + 1)
        Message    = "Removed section '$SectionHeading' (lines $($anchorIdx + 1)-$nextHeadingIdx)"
    }
}

function Remove-BlockquoteBlock {
    <#
    .SYNOPSIS
    Removes one blockquote block — an anchor line and the blockquote lines continuing it —
    from markdown content.

    .DESCRIPTION
    Pure markdown manipulation — no knowledge of state files or repo paths. Sibling of
    Remove-MarkdownSection for content that lives inside a blockquote rather than under a
    heading, where no heading anchors the span. Locates the anchor line by literal
    starts-with match, then deletes it plus every following line that is still part of the
    blockquote, stopping at the first line that is not a blockquote line ('>') and at the
    first blank-blockquote separator ('>' alone), so only the anchored paragraph goes and
    sibling notes in the same blockquote survive. A '>' separator line immediately preceding
    the anchor is removed too, leaving no dangling separator. Line endings are preserved.
    No-ops (returns content unchanged, Action 'NotFound') when the anchor is absent, so
    callers can strip an optional note unconditionally.

    Used to drop a mode-conditional note from a freshly created document — e.g.
    New-FeatureImplementationState.ps1 omits the onboarding-only "Retrospective Analysis
    mode" note from greenfield state files.

    .PARAMETER Content
    The full document content as a single string. Line endings preserved on output.

    .PARAMETER AnchorPrefix
    Literal text the anchor line starts with, compared after trimming the line's end
    (e.g. "> **Retrospective Analysis mode**"). Matched literally, not as a regex.

    .OUTPUTS
    Hashtable with keys:
      Content    - updated content (or original when Action is 'NotFound')
      Action     - 'Removed' | 'NotFound'
      LineNumber - 1-based line of the removed anchor (0 when not found)
      Message    - human-readable detail
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$AnchorPrefix
    )

    $newline = if ($Content -match "`r`n") { "`r`n" } else { "`n" }
    $lines = $Content -split "`r?`n"

    # Find the anchor line (literal starts-with, trimmed-end)
    $anchorIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimEnd().StartsWith($AnchorPrefix)) { $anchorIdx = $i; break }
    }
    if ($anchorIdx -lt 0) {
        return @{ Content = $Content; Action = 'NotFound'; LineNumber = 0; Message = "Anchor '$AnchorPrefix' not found" }
    }

    # Block end: first line that is not a blockquote continuation line, or a '>' separator
    $endIdx = $lines.Count
    for ($i = $anchorIdx + 1; $i -lt $lines.Count; $i++) {
        $t = $lines[$i].TrimEnd()
        if ($t -eq '>' -or -not $t.StartsWith('>')) { $endIdx = $i; break }
    }

    # Also drop a '>' separator immediately preceding the anchor
    $startIdx = $anchorIdx
    if ($startIdx -gt 0 -and $lines[$startIdx - 1].TrimEnd() -eq '>') { $startIdx-- }

    $kept = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($i -ge $startIdx -and $i -lt $endIdx) { continue }
        $kept.Add($lines[$i])
    }

    return @{
        Content    = ($kept -join $newline)
        Action     = 'Removed'
        LineNumber = ($anchorIdx + 1)
        Message    = "Removed blockquote block '$AnchorPrefix' (lines $($startIdx + 1)-$endIdx)"
    }
}

function Get-MarkdownTableHeaders {
    <#
    .SYNOPSIS
    Returns the column header names of the first markdown table inside a named section.

    .DESCRIPTION
    Locates the heading line, then returns the cells of the first non-separator table row
    below it — the table's header. The section ends at the next heading of equal or higher
    level (so a "## Summary" anchor does not run into "## Registry", and a "### Level 1"
    anchor stops at "### Level 2" as well as at "## Sections").

    Returns an empty array when the section or its table is not found; callers decide
    whether that is fatal.

    .PARAMETER Content
    Full file content as a single string.

    .PARAMETER SectionHeading
    Exact heading line anchoring the table (e.g. "### Component Benchmarks (Level 1)"
    or "## Technical Debt Registry").

    .OUTPUTS
    [string[]] Header cell values, or an empty array.

    .EXAMPLE
    Get-MarkdownTableHeaders -Content $c -SectionHeading '## Technical Debt Registry'
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$SectionHeading
    )

    $anchorLevel = 0
    if ($SectionHeading -match '^(#{1,6})\s') { $anchorLevel = $matches[1].Length }

    $lines = $Content -split "\r?\n"
    $inSection = $false
    foreach ($line in $lines) {
        if (-not $inSection) {
            if ($line.TrimEnd() -eq $SectionHeading.TrimEnd()) { $inSection = $true }
            continue
        }
        # Leave at the next heading of equal-or-higher level (fewer/equal '#')
        if ($anchorLevel -gt 0 -and $line -match '^(#{1,6})\s' -and $matches[1].Length -le $anchorLevel) { break }
        # First non-separator table row inside the section is its header
        if ($line -match '^\s*\|.*\|\s*$' -and $line -notmatch '^\s*\|[\s\-:|]+\|\s*$') {
            return Split-MarkdownTableRow -Line $line.Trim()
        }
    }
    return @()
}

function New-HeaderDrivenTableRow {
    <#
    .SYNOPSIS
    Builds a markdown table row ordered by the target table's own header names.

    .DESCRIPTION
    The structural fix for hardcoded row templates (PF-IMP-1599; pattern established by
    Update-TechDebt.ps1's Add-NewDebtItemContent, PF-IMP-006). Instead of emitting cells in a
    literal order the script assumes, this reads the live table's header and places each value
    under the header it belongs to. A column added to the table lands as $DefaultCell in the
    correct position rather than shifting every following cell one place left — the silent
    corruption that Assert-TableRowInFile detects and this prevents.

    Throws when the section's table header cannot be found — a script cannot safely insert a
    row into a table whose schema it cannot read.

    .PARAMETER Content
    Full file content as a single string.

    .PARAMETER SectionHeading
    Exact heading line anchoring the target table.

    .PARAMETER ValueMap
    Hashtable of header name -> cell value. Keys are matched against the table's header cells.
    Headers absent from the map receive $DefaultCell.

    .PARAMETER DefaultCell
    Placeholder for headers the map does not supply. Defaults to an em-dash ("—"), the
    convention in most trackers; pass "-" for tables that use a plain hyphen (e.g. the
    technical-debt registry). Match the table's existing rows.

    .OUTPUTS
    [string] A formatted markdown table row.

    .EXAMPLE
    $row = New-HeaderDrivenTableRow -Content $c -SectionHeading '### Component Benchmarks (Level 1)' -ValueMap @{
        'Test ID' = $testId; 'Operation' = $Operation; 'Status' = '⬜ Needs Creation'
    }
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$SectionHeading,

        [Parameter(Mandatory=$true)]
        [hashtable]$ValueMap,

        [Parameter(Mandatory=$false)]
        [string]$DefaultCell = "—"
    )

    $headers = @(Get-MarkdownTableHeaders -Content $Content -SectionHeading $SectionHeading)
    if ($headers.Count -eq 0) {
        throw ("New-HeaderDrivenTableRow: could not read the table header under section " +
               "'$SectionHeading' — cannot build a row for a table whose schema is unreadable.")
    }

    # Surface value-map keys that match no header: usually a renamed column, which would
    # otherwise drop the value silently and leave the cell as the placeholder.
    $unmatched = @($ValueMap.Keys | Where-Object { $headers -notcontains $_ })
    if ($unmatched.Count -gt 0) {
        Write-Warning ("New-HeaderDrivenTableRow: value(s) supplied for column(s) not present in " +
                       "'$SectionHeading': '$($unmatched -join "', '")'. Table headers are: " +
                       "'$($headers -join "', '")'. Those values were not written.")
    }

    $cells = @($headers | ForEach-Object { if ($ValueMap.ContainsKey($_)) { [string]$ValueMap[$_] } else { $DefaultCell } })
    return ConvertTo-MarkdownTableRow -Cells $cells
}

function Assert-TableRowInFile {
    <#
    .SYNOPSIS
    Asserts that a file contains a markdown table row matching a pattern, and that the row's
    cell count matches its table header; throws on mismatch.

    .DESCRIPTION
    Read-after-write verification helper for scripts that insert a row into a markdown
    tracking table. Where Assert-LineInFile proves only that a pattern is present somewhere
    in the file, this proves the written row is structurally consistent with the table it
    landed in: it locates the matching row line, walks up to that row's governing header
    (the header row above the nearest preceding separator line), and compares cell counts.

    Catches the silent failure mode where a script's hardcoded row template drifts from a
    table whose header has since gained or lost a column: the row parses as markdown, the
    ID is present, but every cell after the added column is shifted and lands under the
    wrong header. Also catches a row that is not a well-formed table row at all (e.g. a
    missing trailing pipe), which markdown table parsers skip silently.

    .PARAMETER Path
    Absolute or relative path to the file to inspect.

    .PARAMETER Pattern
    Regex pattern (default) or literal substring (with -Literal) identifying the row.
    Matched per-line; the first matching table row is verified.

    .PARAMETER Literal
    When specified, Pattern is treated as a literal substring instead of a regex.

    .PARAMETER Context
    Optional caller-supplied context appended to the error message to aid diagnosis.

    .EXAMPLE
    Assert-TableRowInFile -Path $TrackingFile -Pattern "\| $testId \|" -Context "performance test row for $testId"

    .NOTES
    Introduced by PF-IMP-1563. Detects header/row drift at the moment of the bad write;
    it does not prevent drift — header-driven row construction is the structural fix.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$Pattern,

        [switch]$Literal,

        [string]$Context
    )

    $contextSuffix = if ($Context) { " (context: $Context)" } else { "" }

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Assert-TableRowInFile: file not found: '$Path'$contextSuffix"
    }

    $lines = @(Get-Content -LiteralPath $Path -Encoding UTF8)

    # Locate the first line matching the pattern
    $rowIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $hit = if ($Literal) { $lines[$i].Contains($Pattern) } else {
            try { $lines[$i] -match $Pattern } catch {
                throw "Assert-TableRowInFile: invalid regex pattern '$Pattern' for '$Path'$contextSuffix : $($_.Exception.Message)"
            }
        }
        if ($hit) { $rowIdx = $i; break }
    }

    if ($rowIdx -lt 0) {
        $patternKind = if ($Literal) { "literal" } else { "regex" }
        throw "Assert-TableRowInFile: $patternKind pattern '$Pattern' not found in '$Path'$contextSuffix"
    }

    $rowCells = Split-MarkdownTableRow -Line $lines[$rowIdx]
    if ($null -eq $rowCells) {
        throw ("Assert-TableRowInFile: the line matching '$Pattern' in '$Path' is not a well-formed " +
               "markdown table row (expected it to start and end with '|')$contextSuffix. Line: $($lines[$rowIdx])")
    }

    # Walk up to the separator line (| --- | --- |) that follows this table's header row
    $sepIdx = -1
    for ($i = $rowIdx - 1; $i -ge 0; $i--) {
        if ($lines[$i] -match '^\s*\|[\s:\-\|]+\|\s*$') { $sepIdx = $i; break }
        if ($lines[$i] -notmatch '^\s*\|') { break }   # left the table without finding one
    }

    if ($sepIdx -lt 1) {
        throw ("Assert-TableRowInFile: could not locate the table header governing the row matching " +
               "'$Pattern' in '$Path' (no separator row found above it)$contextSuffix")
    }

    $headerCells = Split-MarkdownTableRow -Line $lines[$sepIdx - 1]
    if ($null -eq $headerCells) {
        throw ("Assert-TableRowInFile: the header line above the separator at line $($sepIdx + 1) in " +
               "'$Path' is not a well-formed markdown table row$contextSuffix")
    }

    if ($rowCells.Count -ne $headerCells.Count) {
        throw ("Assert-TableRowInFile: row/header column-count mismatch in '$Path'$contextSuffix. " +
               "The row written at line $($rowIdx + 1) has $($rowCells.Count) cell(s); its header at line " +
               "$sepIdx has $($headerCells.Count) ('$($headerCells -join "', '")'). The row's cells are " +
               "shifted and land under the wrong headers — the row template has drifted from the table schema.")
    }
}

#endregion High-Level Operations

# Export functions
Export-ModuleMember -Function @(
    # Low-level helpers (v2.0)
    'Split-MarkdownTableRow',
    'Get-MarkdownLinkText',
    'ConvertTo-MarkdownTableRow',
    'ConvertFrom-MarkdownTable',
    # High-level operations (v1.0)
    'Update-MarkdownTable',
    'Update-MarkdownTableWithAppend',
    'Move-MarkdownTableRow',
    # Section-scoped upsert (v2.1 — PF-IMP-028 / PF-PRO-002 Phase 1)
    'Add-MarkdownTableRow',
    # Section removal (v2.2 — PF-IMP-1359)
    'Remove-MarkdownSection',
    # Blockquote-block removal (v2.3 — PF-IMP-1562)
    'Remove-BlockquoteBlock',
    # Row-shape post-condition (v2.3 — PF-IMP-1563)
    'Assert-TableRowInFile',
    # Header-driven row construction (v2.4 — PF-IMP-1599)
    'Get-MarkdownTableHeaders',
    'New-HeaderDrivenTableRow'
)

Write-Verbose "TableOperations module loaded with 12 functions"
