param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $true)]
    [string]$ColumnName,

    [Parameter(Mandatory = $false)]
    [string]$AfterColumn = "",

    [Parameter(Mandatory = $false)]
    [string]$DefaultValue = "",

    [Parameter(Mandatory = $false)]
    [bool]$BackupFile = $true,

    [Parameter(Mandatory = $false)]
    [bool]$DryRun = $false,

    [Parameter(Mandatory = $false)]
    [bool]$SkipIfExists = $true
)

# Ensure the file exists
if (-not (Test-Path $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}

# Create backup if requested
if ($BackupFile -and -not $DryRun) {
    $backupPath = $FilePath + ".backup." + (Get-Date -Format "yyyyMMdd-HHmmss")
    Copy-Item $FilePath $backupPath
    Write-Host "✅ Backup created: $backupPath" -ForegroundColor Green
}

# Read the file content
$content = Get-Content -Path $FilePath -Raw
$lines = $content -split "`r?`n"

# Function to detect if a line is a table separator (| ---- | ---- |)
function Test-TableSeparator {
    param([string]$line)
    return $line -match '^\s*\|[\s\-:]+\|[\s\-:]+.*\|[\s\-:]*\s*$'
}

# Function to count columns in a separator line
function Get-ColumnCount {
    param([string]$separatorLine)
    # Count the number of | characters and subtract 1 (since | are separators)
    $pipeCount = ($separatorLine.ToCharArray() | Where-Object { $_ -eq '|' }).Count
    return $pipeCount - 1
}

# Function to parse table columns from a header line
function Get-TableColumns {
    param([string]$headerLine)

    # Remove leading/trailing whitespace and split by |
    $parts = $headerLine.Trim() -split '\|'

    # Remove empty parts and trim whitespace
    $columns = @()
    foreach ($part in $parts) {
        $trimmed = $part.Trim()
        if ($trimmed -ne "") {
            $columns += $trimmed
        }
    }
    return $columns
}

# Function to check if this is a feature table based on column names
function Test-FeatureTable {
    param([array]$columns)

    # Check if it has the key columns that identify a feature table
    $hasID = $columns -contains "ID"
    $hasFeature = $columns | Where-Object { $_ -match "Feature" }
    $hasStatus = $columns | Where-Object { $_ -match "Status" }
    $hasPriority = $columns | Where-Object { $_ -match "Priority" }
    $hasDocTier = $columns | Where-Object { $_ -match "Doc Tier" }

    return $hasID -and $hasFeature -and $hasStatus -and $hasPriority -and $hasDocTier
}

# Function to add column to a table row
function Add-ColumnToRow {
    param(
        [string]$row,
        [int]$insertPosition,
        [string]$value,
        [int]$totalColumns
    )

    # Split the row by | and clean up
    $parts = $row -split '\|'
    $cleanParts = @()

    # Process each part, keeping track of actual content vs empty boundary parts
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $part = $parts[$i]
        if ($i -eq 0 -and $part.Trim() -eq "") {
            # Leading empty part (before first |)
            continue
        }
        elseif ($i -eq ($parts.Count - 1) -and $part.Trim() -eq "") {
            # Trailing empty part (after last |)
            continue
        }
        else {
            $cleanParts += $part
        }
    }

    # Insert the new column value at the specified position
    $newParts = @()
    for ($i = 0; $i -lt $cleanParts.Count; $i++) {
        if ($i -eq $insertPosition) {
            $newParts += $value
        }
        $newParts += $cleanParts[$i]
    }

    # If insert position is at the end, add it there
    if ($insertPosition -eq $cleanParts.Count) {
        $newParts += $value
    }

    # Reconstruct the row
    return "| " + ($newParts -join " | ") + " |"
}

# Main processing
$modifiedLines = @()
$tablesModified = 0
$i = 0

Write-Host "🔍 Scanning for markdown tables..." -ForegroundColor Cyan

while ($i -lt $lines.Count) {
    $line = $lines[$i]

    # Check if this line is a table separator
    if (Test-TableSeparator $line) {
        Write-Host "📊 Found table separator at line $($i + 1)" -ForegroundColor Yellow

        # Count columns in this table
        $columnCount = Get-ColumnCount $line
        Write-Host "   Columns detected: $columnCount" -ForegroundColor Gray

        # Look for the header line (should be the previous line)
        if ($i -gt 0) {
            $headerLine = $lines[$i - 1]
            $columns = Get-TableColumns $headerLine

            Write-Host "   Header columns: $($columns -join ', ')" -ForegroundColor Gray

            # Check if this is a feature table
            if (Test-FeatureTable $columns) {
                Write-Host "✅ Feature table identified!" -ForegroundColor Green

                # Check if column already exists
                if ($SkipIfExists -and ($columns -contains $ColumnName)) {
                    Write-Host "⏭️  Table already has '$ColumnName' column - skipping" -ForegroundColor Gray
                    $modifiedLines += $line
                    $i++
                    continue
                }

                # Determine insert position
                $insertPosition = $columns.Count  # Default to end
                if ($AfterColumn -ne "") {
                    $afterIndex = -1
                    for ($j = 0; $j -lt $columns.Count; $j++) {
                        if ($columns[$j] -eq $AfterColumn) {
                            $afterIndex = $j
                            break
                        }
                    }
                    if ($afterIndex -ge 0) {
                        $insertPosition = $afterIndex + 1
                        Write-Host "   Inserting after '$AfterColumn' at position $insertPosition" -ForegroundColor Gray
                    }
                    else {
                        Write-Host "   Column '$AfterColumn' not found, inserting at end" -ForegroundColor Yellow
                    }
                }

                # Modify the header line (go back and update it)
                $modifiedHeader = Add-ColumnToRow $headerLine $insertPosition $ColumnName $columnCount
                $modifiedLines[$modifiedLines.Count - 1] = $modifiedHeader

                # Modify the separator line
                $separatorValue = "-------"
                $modifiedSeparator = Add-ColumnToRow $line $insertPosition $separatorValue $columnCount
                $modifiedLines += $modifiedSeparator

                # Process all data rows in this table
                $j = $i + 1
                while ($j -lt $lines.Count) {
                    $dataLine = $lines[$j]

                    # Check if this is still a table row
                    if ($dataLine -match '^\s*\|.*\|.*\s*$' -and $dataLine.Trim() -ne "") {
                        # This is a data row, modify it
                        $modifiedDataRow = Add-ColumnToRow $dataLine $insertPosition $DefaultValue $columnCount
                        $modifiedLines += $modifiedDataRow
                        Write-Host "   Modified data row: $($j + 1)" -ForegroundColor Gray
                    }
                    else {
                        # End of table
                        break
                    }
                    $j++
                }

                $tablesModified++
                Write-Host "✅ Table modified successfully!" -ForegroundColor Green
                $i = $j - 1  # Continue from where we left off
            }
            else {
                Write-Host "⏭️  Not a feature table - skipping" -ForegroundColor Gray
                $modifiedLines += $line
            }
        }
        else {
            # No header line found
            $modifiedLines += $line
        }
    }
    else {
        # Regular line, just add it
        $modifiedLines += $line
    }

    $i++
}

# Output results
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   Tables modified: $tablesModified" -ForegroundColor White
Write-Host "   Column added: '$ColumnName'" -ForegroundColor White
if ($AfterColumn -ne "") {
    Write-Host "   Insert position: After '$AfterColumn'" -ForegroundColor White
}
else {
    Write-Host "   Insert position: At end" -ForegroundColor White
}
Write-Host "   Default value: '$DefaultValue'" -ForegroundColor White

if ($DryRun) {
    Write-Host "🔍 DRY RUN - No changes made to file" -ForegroundColor Yellow
    Write-Host "   To apply changes, run without -DryRun parameter" -ForegroundColor Yellow
}
else {
    # Write the modified content back to the file
    $modifiedContent = $modifiedLines -join "`r`n"
    Set-Content -Path $FilePath -Value $modifiedContent -NoNewline
    Write-Host "✅ File updated successfully!" -ForegroundColor Green
}
