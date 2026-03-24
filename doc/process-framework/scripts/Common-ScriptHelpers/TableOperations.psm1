# TableOperations.psm1
# Core markdown table manipulation functions
# Extracted from StateFileManagement.psm1 as part of module decomposition
#
# VERSION 1.0 - EXTRACTED MODULE
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

.NOTES
Version: 1.0 (Extracted Module)
Created: 2025-08-30
Extracted From: StateFileManagement.psm1
Dependencies: None (pure functions)
#>

# Configure UTF-8 encoding for consistent Unicode support
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'

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
    $updatedContent = Update-MarkdownTable -Content $content -FeatureId "0.1.1" -MatchColumn "Feature ID" -StatusColumn "Status" -Status "✅ Tests Approved"
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
    $headerLine = ""
    $separatorLine = ""
    $columnIndices = @{}

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Detect table start (header line with pipes)
        if ($line -match '^\|.*\|$' -and -not $inTable) {
            $inTable = $true
            $headerLine = $line

            # Parse column headers properly, preserving empty cells
            $rawHeaders = $headerLine -split '\|'
            # Remove first and last empty elements (before first | and after last |)
            if ($rawHeaders.Count -gt 2) {
                $rawHeaders = $rawHeaders[1..($rawHeaders.Count-2)]
            }
            # Trim whitespace but preserve structure
            $headers = $rawHeaders | ForEach-Object { $_.Trim() }

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
            $separatorLine = $line
            $updatedLines += $line
            continue
        }

        # Process table rows
        if ($inTable -and $line -match '^\|.*\|$') {
            # Parse columns properly, preserving empty cells
            $rawColumns = $line -split '\|'
            # Remove first and last empty elements (before first | and after last |)
            if ($rawColumns.Count -gt 2) {
                $rawColumns = $rawColumns[1..($rawColumns.Count-2)]
            }
            # Trim whitespace but preserve empty cells
            $columns = $rawColumns | ForEach-Object { $_.Trim() }

            # Check if this row contains our feature ID
            # Extract plain text from potential markdown link [text](url) format
            $cellValue = $columns[0]
            if ($cellValue -match '^\[([^\]]+)\]') {
                $cellValue = $matches[1]
            }
            if ($columns.Count -gt 0 -and $cellValue -eq $FeatureId) {
                # Ensure we have exactly the right number of columns to match the header
                $headerCount = $headers.Count
                while ($columns.Count -lt $headerCount) {
                    $columns += ""
                }
                # Trim excess columns if any
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
                    Write-Warning "Update-MarkdownTable: StatusColumn '$StatusColumn' not found in table headers. Available columns: $($columnIndices.Keys -join ', '). Status update for '$FeatureId' was skipped."
                }

                # Apply additional updates
                foreach ($columnName in $AdditionalUpdates.Keys) {
                    if ($columnIndices.ContainsKey($columnName)) {
                        $updateIndex = $columnIndices[$columnName]
                        if ($updateIndex -lt $columns.Count) {
                            $columns[$updateIndex] = $AdditionalUpdates[$columnName]
                        }
                    } else {
                        Write-Warning "Update-MarkdownTable: AdditionalUpdates column '$columnName' not found in table headers. Available columns: $($columnIndices.Keys -join ', '). Update for '$FeatureId' was skipped."
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

                # Reconstruct the line
                $updatedLine = "| " + ($columns -join " | ") + " |"
                $updatedLines += $updatedLine
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
    $appendUpdates = @{ "API Design" = "[PD-MDL-001](path/to/model.md)" }
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
    $headerLine = ""
    $separatorLine = ""
    $columnIndices = @{}

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Detect table start (header line with pipes)
        if ($line -match '^\|.*\|$' -and -not $inTable) {
            $inTable = $true
            $headerLine = $line

            # Parse column headers properly, preserving empty cells
            $rawHeaders = $headerLine -split '\|'
            # Remove first and last empty elements (before first | and after last |)
            if ($rawHeaders.Count -gt 2) {
                $rawHeaders = $rawHeaders[1..($rawHeaders.Count-2)]
            }
            # Trim whitespace but preserve structure
            $headers = $rawHeaders | ForEach-Object { $_.Trim() }

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
            $separatorLine = $line
            $updatedLines += $line
            continue
        }

        # Process table rows
        if ($inTable -and $line -match '^\|.*\|$') {
            # Parse columns properly, preserving empty cells
            $rawColumns = $line -split '\|'
            # Remove first and last empty elements (before first | and after last |)
            if ($rawColumns.Count -gt 2) {
                $rawColumns = $rawColumns[1..($rawColumns.Count-2)]
            }
            # Trim whitespace but preserve empty cells
            $columns = $rawColumns | ForEach-Object { $_.Trim() }

            # Check if this row contains our feature ID
            # Extract plain text from potential markdown link [text](url) format
            $cellValue = $columns[0]
            if ($cellValue -match '^\[([^\]]+)\]') {
                $cellValue = $matches[1]
            }
            if ($columns.Count -gt 0 -and $cellValue -eq $FeatureId) {
                # Ensure we have exactly the right number of columns to match the header
                $headerCount = $headers.Count
                while ($columns.Count -lt $headerCount) {
                    $columns += ""
                }
                # Trim excess columns if any
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
                    Write-Warning "Update-MarkdownTableWithAppend: StatusColumn '$StatusColumn' not found in table headers. Available columns: $($columnIndices.Keys -join ', '). Status update for '$FeatureId' was skipped."
                }

                # Apply additional updates (replace existing content)
                foreach ($columnName in $AdditionalUpdates.Keys) {
                    if ($columnIndices.ContainsKey($columnName)) {
                        $updateIndex = $columnIndices[$columnName]
                        if ($updateIndex -lt $columns.Count) {
                            $columns[$updateIndex] = $AdditionalUpdates[$columnName]
                        }
                    } else {
                        Write-Warning "Update-MarkdownTableWithAppend: AdditionalUpdates column '$columnName' not found in table headers. Available columns: $($columnIndices.Keys -join ', '). Update for '$FeatureId' was skipped."
                    }
                }

                # Apply append updates (append with bullet separator)
                foreach ($columnName in $AppendUpdates.Keys) {
                    if ($columnIndices.ContainsKey($columnName)) {
                        $appendIndex = $columnIndices[$columnName]
                        if ($appendIndex -lt $columns.Count) {
                            $existingContent = $columns[$appendIndex]
                            $newContent = $AppendUpdates[$columnName]

                            # Replace "Yes"/"No" or empty content, append to existing links/content
                            if ($existingContent -and $existingContent -ne "-" -and $existingContent -ne "" -and $existingContent -ne "Yes" -and $existingContent -ne "No") {
                                $columns[$appendIndex] = "$existingContent • $newContent"
                            } else {
                                $columns[$appendIndex] = $newContent
                            }
                        }
                    } else {
                        Write-Warning "Update-MarkdownTableWithAppend: AppendUpdates column '$columnName' not found in table headers. Available columns: $($columnIndices.Keys -join ', '). Update for '$FeatureId' was skipped."
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

                # Reconstruct the line
                $updatedLine = "| " + ($columns -join " | ") + " |"
                $updatedLines += $updatedLine
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
        [string]$SectionEndPattern = '^\s*</details>'
    )

    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # --- Step 1: Find the source section and parse its table ---
    $sourceStartIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match [regex]::Escape($SourceSection)) {
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
        if ($lines[$i] -match '^\|.*\|$' -and $lines[$i] -notmatch '^\|[-\s:]+\|$') {
            # First non-separator table row is the header
            $rawHeaders = $lines[$i] -split '\|'
            if ($rawHeaders.Count -gt 2) { $rawHeaders = $rawHeaders[1..($rawHeaders.Count-2)] }
            $sourceHeaders = $rawHeaders | ForEach-Object { $_.Trim() }
            $sourceHeaderIdx = $i
            break
        }
    }

    if ($sourceHeaderIdx -eq -1) {
        Write-Warning "Move-MarkdownTableRow: No table found in source section '$SourceSection'"
        return @{ Content = $null; SourceRow = $null; SourceColumns = $null; DestinationRow = $null }
    }

    # --- Step 2: Find and remove the matching row ---
    $rowIndex = -1
    $sourceRowText = $null
    for ($i = $sourceHeaderIdx + 1; $i -lt $lines.Count; $i++) {
        # Stop at section boundaries
        if ($lines[$i] -match '^## ' -or ($SectionEndPattern -and $lines[$i] -match $SectionEndPattern)) { break }
        if ($lines[$i] -match '^\|[-\s:]+\|$') { continue }  # skip separator
        if ($lines[$i] -match "^\|.*$RowIdPattern.*\|") {
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
    $rawCols = $sourceRowText -split '\|'
    if ($rawCols.Count -gt 2) { $rawCols = $rawCols[1..($rawCols.Count-2)] }
    $colValues = $rawCols | ForEach-Object { $_.Trim() }

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

    $destinationRow = "| " + ($destColValues -join " | ") + " |"

    # --- Step 4: Insert into destination section ---
    $destStartIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match [regex]::Escape($DestinationSection)) {
            $destStartIdx = $i
            break
        }
    }

    if ($destStartIdx -eq -1) {
        Write-Warning "Move-MarkdownTableRow: Destination section '$DestinationSection' not found"
        return @{ Content = $null; SourceRow = $sourceRowText; SourceColumns = $sourceColumns; DestinationRow = $destinationRow }
    }

    # Find insertion point: after the last data row in the destination table
    $insertAfterIdx = -1
    for ($i = $destStartIdx + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## ' -and $i -ne $destStartIdx) { break }
        if ($SectionEndPattern -and $lines[$i] -match $SectionEndPattern) { break }
        # Match data rows (not headers, not separators)
        if ($lines[$i] -match '^\|[^-]' -and $lines[$i] -notmatch '^\|\s*(ID|Feature|Date|Status)\s*\|') {
            $insertAfterIdx = $i
        }
    }

    # If no data rows, insert after the separator line
    if ($insertAfterIdx -eq -1) {
        for ($i = $destStartIdx + 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^## ' -and $i -ne $destStartIdx) { break }
            if ($SectionEndPattern -and $lines[$i] -match $SectionEndPattern) { break }
            if ($lines[$i] -match '^\|[-\s:]+\|$') {
                $insertAfterIdx = $i
                break
            }
        }
    }

    if ($insertAfterIdx -eq -1) {
        Write-Warning "Move-MarkdownTableRow: Could not find insertion point in destination section '$DestinationSection'"
        return @{ Content = $null; SourceRow = $sourceRowText; SourceColumns = $sourceColumns; DestinationRow = $destinationRow }
    }

    $lines.Insert($insertAfterIdx + 1, $destinationRow)

    return @{
        Content = ($lines -join "`r`n")
        SourceRow = $sourceRowText
        SourceColumns = $sourceColumns
        DestinationRow = $destinationRow
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Update-MarkdownTable',
    'Update-MarkdownTableWithAppend',
    'Move-MarkdownTableRow'
)

Write-Verbose "TableOperations module loaded with 3 functions"
