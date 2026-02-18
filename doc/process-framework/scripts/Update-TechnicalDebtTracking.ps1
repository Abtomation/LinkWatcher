#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates technical debt tracking updates in the Technical Debt Tracking state file

.DESCRIPTION
This script automates technical debt item management in the technical-debt-tracking.md state file,
supporting the complete technical debt lifecycle from identification to resolution.

Updates the following file:
- doc/process-framework/state-tracking/permanent/technical-debt-tracking.md

Supports all technical debt operations:
- Adding new debt items from assessments
- Updating existing debt item status and details
- Moving resolved items to the "Recently Resolved" section
- Maintaining bidirectional links between assessments and registry

.PARAMETER DebtId
The debt ID to update (e.g., "TD001") - required for updates, auto-generated for new items

.PARAMETER Operation
The operation to perform. Valid values:
- "Add" - Add a new debt item
- "Update" - Update an existing debt item
- "Resolve" - Mark a debt item as resolved and move to resolved section

.PARAMETER Description
Description of the technical debt item (required for Add operation)

.PARAMETER Category
Category of the debt item. Valid values:
- "Architectural"
- "Code Quality"
- "Testing"
- "Documentation"
- "Performance"
- "Security"
- "Accessibility"
- "UX"

.PARAMETER Location
Location/path where the debt exists (e.g., "lib/services/", "lib/screens/auth/")

.PARAMETER Priority
Priority level. Valid values:
- "Critical"
- "High"
- "Medium"
- "Low"

.PARAMETER EstimatedEffort
Estimated effort to resolve the debt (e.g., "2 hours", "1 week", "3-5 days")

.PARAMETER Status
Current status of the debt item. Valid values:
- "Open"
- "In Progress"
- "Resolved"

.PARAMETER AssessmentId
ID of the assessment that identified this debt item (e.g., "PF-TDA-001")

.PARAMETER DebtItemId
ID of the individual debt item document (e.g., "PF-TDI-001")

.PARAMETER Notes
Additional notes about the debt item

.PARAMETER ResolutionDate
Date when the debt was resolved (for Resolve operation)

.PARAMETER ResolutionNotes
Notes about how the debt was resolved (for Resolve operation)

.EXAMPLE
# Add a new debt item from an assessment
.\Update-TechnicalDebtTracking.ps1 -Operation "Add" -Description "Missing Repository Pattern Implementation" -Category "Architectural" -Location "lib/services/" -Priority "Critical" -EstimatedEffort "1-2 weeks" -AssessmentId "PF-TDA-001" -DebtItemId "PF-TDI-001"

.EXAMPLE
# Update an existing debt item status
.\Update-TechnicalDebtTracking.ps1 -Operation "Update" -DebtId "TD002" -Status "In Progress" -Notes "Refactoring plan created: PF-REF-009"

.EXAMPLE
# Resolve a debt item
.\Update-TechnicalDebtTracking.ps1 -Operation "Resolve" -DebtId "TD003" -ResolutionDate "2025-08-31" -ResolutionNotes "Implemented proper service layer separation"

.NOTES
This script is part of the Technical Debt Assessment automation system and integrates with:
- Technical Debt Assessment Task (PF-TSK-023)
- Code Refactoring Task
- New-TechnicalDebtAssessment.ps1
- New-DebtItem.ps1
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$DebtId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Add", "Update", "Resolve")]
    [string]$Operation,

    [Parameter(Mandatory = $false)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Architectural", "Code Quality", "Testing", "Documentation", "Performance", "Security", "Accessibility", "UX")]
    [string]$Category,

    [Parameter(Mandatory = $false)]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Critical", "High", "Medium", "Low")]
    [string]$Priority,

    [Parameter(Mandatory = $false)]
    [string]$EstimatedEffort,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Open", "In Progress", "Resolved")]
    [string]$Status = "Open",

    [Parameter(Mandatory = $false)]
    [string]$AssessmentId,

    [Parameter(Mandatory = $false)]
    [string]$DebtItemId,

    [Parameter(Mandatory = $false)]
    [string]$Notes,

    [Parameter(Mandatory = $false)]
    [string]$ResolutionDate,

    [Parameter(Mandatory = $false)]
    [string]$ResolutionNotes
)

# Configuration
$TechnicalDebtTrackingFile = "doc/process-framework/state-tracking/permanent/technical-debt-tracking.md"
$ScriptName = "Update-TechnicalDebtTracking.ps1"

# Import the common helpers with robust path resolution
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
}
catch {
    Write-Error "Failed to import Common-ScriptHelpers module from: $modulePath"
    Write-Error "Please ensure the script is run from the correct directory or the module path is correct."
    exit 1
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."

    if (-not (Test-Path $TechnicalDebtTrackingFile)) {
        Write-Log "Technical debt tracking file not found: $TechnicalDebtTrackingFile" -Level "ERROR"
        return $false
    }

    Write-Log "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

function Get-NextDebtId {
    <#
    .SYNOPSIS
    Gets the next available TD### ID from the technical debt tracking file
    #>

    $content = Get-Content $TechnicalDebtTrackingFile -Raw

    # Find all existing TD IDs in the main registry table
    $tdPattern = '\|\s*(TD\d{3})\s*\|'
    $matches = [regex]::Matches($content, $tdPattern)

    $existingIds = @()
    foreach ($match in $matches) {
        $id = $match.Groups[1].Value
        if ($id -match 'TD(\d{3})') {
            $existingIds += [int]$matches.Groups[1].Value
        }
    }

    # Find the highest number and increment
    if ($existingIds.Count -gt 0) {
        $maxId = ($existingIds | Measure-Object -Maximum).Maximum
        $nextId = $maxId + 1
    }
    else {
        $nextId = 1
    }

    return "TD{0:D3}" -f $nextId
}

function Find-DebtEntry {
    param([string]$DebtId)

    $content = Get-Content $TechnicalDebtTrackingFile -Raw

    # Look for debt entry in table format: | DebtId | Description | Category | ...
    $debtPattern = "\|\s*$DebtId\s*\|[^\r\n]*"
    $match = [regex]::Match($content, $debtPattern)

    if ($match.Success) {
        return @{
            Found      = $true
            StartIndex = $match.Index
            Length     = $match.Length
            Content    = $match.Value
        }
    }

    return @{ Found = $false }
}

function Add-NewDebtItem {
    param(
        [string]$Description,
        [string]$Category,
        [string]$Location,
        [string]$Priority,
        [string]$EstimatedEffort,
        [string]$Status,
        [string]$AssessmentId,
        [string]$DebtItemId,
        [string]$Notes
    )

    # Generate next TD ID
    $newDebtId = Get-NextDebtId
    Write-Log "Generated new debt ID: $newDebtId"

    # Read current content
    $content = Get-Content $TechnicalDebtTrackingFile -Raw

    # Find the registry table and add new row
    # Table format: | ID | Description | Category | Location | Created Date | Priority | Estimated Effort | Status | Resolution Date | Assessment ID | Notes |

    $currentDate = Get-Date -Format "yyyy-MM-dd"
    $assessmentIdValue = if ($AssessmentId) { $AssessmentId } else { "-" }
    $notesValue = if ($Notes) { $Notes } else { "-" }

    # Create new table row
    $newRow = "| $newDebtId | $Description | $Category | $Location | $currentDate | $Priority | $EstimatedEffort | $Status | - | $assessmentIdValue | $notesValue |"

    # Find the end of the registry table (look for the line after the last table row)
    $lines = $content -split '\r?\n'
    $registryTableEnd = -1
    $inRegistryTable = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Detect registry table start
        if ($line -match '## Technical Debt Registry') {
            $inRegistryTable = $true
            continue
        }

        # If we're in the registry table and find a non-table line, we've found the end
        if ($inRegistryTable -and $line -notmatch '^\|.*\|$' -and $line -notmatch '^[-\s:]+$') {
            $registryTableEnd = $i
            break
        }
    }

    if ($registryTableEnd -eq -1) {
        Write-Log "Could not find end of Technical Debt Registry table" -Level "ERROR"
        return $false
    }

    # Insert the new row before the table end
    $lines = $lines[0..($registryTableEnd - 1)] + $newRow + $lines[$registryTableEnd..($lines.Count - 1)]

    # Write back to file
    $newContent = $lines -join "`n"
    Set-Content -Path $TechnicalDebtTrackingFile -Value $newContent -NoNewline

    Write-Log "Successfully added new debt item $newDebtId: $Description" -Level "SUCCESS"

    # Update the debt item file with the assigned registry ID if DebtItemId is provided
    if ($DebtItemId) {
        Update-DebtItemFile -DebtItemId $DebtItemId -RegistryId $newDebtId
    }

    return $newDebtId
}

function Update-DebtItemFile {
    param(
        [string]$DebtItemId,
        [string]$RegistryId
    )

    # Find the debt item file
    $debtItemPattern = "*$DebtItemId*.md"
    $debtItemFiles = Get-ChildItem -Path "doc/process-framework/assessments/technical-debt/debt-items" -Filter $debtItemPattern -ErrorAction SilentlyContinue

    if ($debtItemFiles.Count -eq 0) {
        Write-Log "Debt item file not found for ID: $DebtItemId" -Level "WARN"
        return
    }

    $debtItemFile = $debtItemFiles[0].FullName
    $content = Get-Content $debtItemFile -Raw

    # Update the Registry Integration section
    $updatedContent = $content -replace 'Registry Status: Not Added', 'Registry Status: Added'
    $updatedContent = $updatedContent -replace 'Registry ID: TBD', "Registry ID: $RegistryId"

    Set-Content -Path $debtItemFile -Value $updatedContent -NoNewline
    Write-Log "Updated debt item file $DebtItemId with registry ID $RegistryId" -Level "SUCCESS"
}

function Update-ExistingDebtItem {
    param(
        [string]$DebtId,
        [hashtable]$Updates
    )

    $debtEntry = Find-DebtEntry -DebtId $DebtId
    if (-not $debtEntry.Found) {
        Write-Log "Debt entry not found: $DebtId" -Level "ERROR"
        return $false
    }

    Write-Log "Found debt entry for $DebtId"

    # Read current content
    $content = Get-Content $TechnicalDebtTrackingFile -Raw

    # Extract current debt entry (table row)
    $currentEntry = $debtEntry.Content

    # Parse the table row - format: | ID | Description | Category | Location | Created Date | Priority | Estimated Effort | Status | Resolution Date | Assessment ID | Notes |
    $columns = $currentEntry -split '\|' | ForEach-Object { $_.Trim() }

    # Skip empty first element (before first |)
    if ($columns[0] -eq '') {
        $columns = $columns[1..($columns.Length - 1)]
    }

    # Update columns based on provided updates
    # Column indices: 0=ID, 1=Description, 2=Category, 3=Location, 4=Created Date, 5=Priority, 6=Estimated Effort, 7=Status, 8=Resolution Date, 9=Assessment ID, 10=Notes

    if ($Updates.ContainsKey('Description')) { $columns[1] = $Updates.Description }
    if ($Updates.ContainsKey('Category')) { $columns[2] = $Updates.Category }
    if ($Updates.ContainsKey('Location')) { $columns[3] = $Updates.Location }
    if ($Updates.ContainsKey('Priority')) { $columns[5] = $Updates.Priority }
    if ($Updates.ContainsKey('EstimatedEffort')) { $columns[6] = $Updates.EstimatedEffort }
    if ($Updates.ContainsKey('Status')) { $columns[7] = $Updates.Status }
    if ($Updates.ContainsKey('ResolutionDate')) { $columns[8] = $Updates.ResolutionDate }
    if ($Updates.ContainsKey('AssessmentId')) { $columns[9] = $Updates.AssessmentId }

    # Handle notes - append if specified
    if ($Updates.ContainsKey('Notes')) {
        $existingNotes = $columns[10]
        if ($existingNotes -and $existingNotes -ne "-" -and $existingNotes -ne "") {
            $columns[10] = "$existingNotes; $($Updates.Notes)"
        }
        else {
            $columns[10] = $Updates.Notes
        }
    }

    # Add update timestamp to notes
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    if ($columns[10] -notmatch "Updated: $currentDate") {
        if ($columns[10] -and $columns[10] -ne "-") {
            $columns[10] += "; Updated: $currentDate"
        }
        else {
            $columns[10] = "Updated: $currentDate"
        }
    }

    # Reconstruct the table row
    $updatedEntry = "| " + ($columns -join " | ") + " |"

    # Replace the old entry with the updated one
    $newContent = $content.Replace($currentEntry, $updatedEntry)

    # Write back to file
    Set-Content -Path $TechnicalDebtTrackingFile -Value $newContent -NoNewline

    Write-Log "Successfully updated debt item $DebtId" -Level "SUCCESS"
    return $true
}

function Resolve-DebtItem {
    param(
        [string]$DebtId,
        [string]$ResolutionDate,
        [string]$ResolutionNotes
    )

    # First, update the item status to Resolved
    $updates = @{
        'Status'         = 'Resolved'
        'ResolutionDate' = $ResolutionDate
        'Notes'          = $ResolutionNotes
    }

    if (-not (Update-ExistingDebtItem -DebtId $DebtId -Updates $updates)) {
        return $false
    }

    # Now move the item to the "Recently Resolved" section
    $content = Get-Content $TechnicalDebtTrackingFile -Raw

    # Find and extract the resolved item
    $debtEntry = Find-DebtEntry -DebtId $DebtId
    $resolvedRow = $debtEntry.Content

    # Remove from main registry
    $contentWithoutResolved = $content.Replace($resolvedRow + "`n", "")

    # Find the "Recently Resolved Technical Debt" table and add the item
    $lines = $contentWithoutResolved -split '\r?\n'
    $resolvedTableStart = -1

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '## Recently Resolved Technical Debt') {
            # Find the table header (skip the section header and find the table)
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j] -match '^\|.*\|$' -and $lines[$j] -match 'ID.*Description') {
                    # Found the header, add after the separator line
                    $resolvedTableStart = $j + 2  # Skip header and separator
                    break
                }
            }
            break
        }
    }

    if ($resolvedTableStart -ne -1) {
        # Insert the resolved item into the resolved table
        $lines = $lines[0..($resolvedTableStart - 1)] + $resolvedRow + $lines[$resolvedTableStart..($lines.Count - 1)]

        # Write back to file
        $newContent = $lines -join "`n"
        Set-Content -Path $TechnicalDebtTrackingFile -Value $newContent -NoNewline

        Write-Log "Successfully moved debt item $DebtId to Recently Resolved section" -Level "SUCCESS"
        return $true
    }
    else {
        Write-Log "Could not find Recently Resolved Technical Debt table" -Level "ERROR"
        return $false
    }
}

function Main {
    Write-Log "Starting Technical Debt Tracking Update - $ScriptName"
    Write-Log "Operation: $Operation"

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    switch ($Operation) {
        "Add" {
            # Validate required parameters for Add operation
            if (-not $Description -or -not $Category -or -not $Location -or -not $Priority -or -not $EstimatedEffort) {
                Write-Log "Description, Category, Location, Priority, and EstimatedEffort are required for Add operation" -Level "ERROR"
                exit 1
            }

            $newDebtId = Add-NewDebtItem -Description $Description -Category $Category -Location $Location -Priority $Priority -EstimatedEffort $EstimatedEffort -Status $Status -AssessmentId $AssessmentId -DebtItemId $DebtItemId -Notes $Notes

            if ($newDebtId) {
                Write-Log "Technical debt item added successfully with ID: $newDebtId" -Level "SUCCESS"
                Write-Log "Updated file: $TechnicalDebtTrackingFile"
                exit 0
            }
            else {
                Write-Log "Failed to add technical debt item" -Level "ERROR"
                exit 1
            }
        }

        "Update" {
            # Validate required parameters for Update operation
            if (-not $DebtId) {
                Write-Log "DebtId is required for Update operation" -Level "ERROR"
                exit 1
            }

            # Prepare update data
            $updates = @{}
            if ($Description) { $updates.Description = $Description }
            if ($Category) { $updates.Category = $Category }
            if ($Location) { $updates.Location = $Location }
            if ($Priority) { $updates.Priority = $Priority }
            if ($EstimatedEffort) { $updates.EstimatedEffort = $EstimatedEffort }
            if ($Status) { $updates.Status = $Status }
            if ($AssessmentId) { $updates.AssessmentId = $AssessmentId }
            if ($Notes) { $updates.Notes = $Notes }

            if (Update-ExistingDebtItem -DebtId $DebtId -Updates $updates) {
                Write-Log "Technical debt item updated successfully" -Level "SUCCESS"
                Write-Log "Updated file: $TechnicalDebtTrackingFile"
                exit 0
            }
            else {
                Write-Log "Failed to update technical debt item" -Level "ERROR"
                exit 1
            }
        }

        "Resolve" {
            # Validate required parameters for Resolve operation
            if (-not $DebtId -or -not $ResolutionDate) {
                Write-Log "DebtId and ResolutionDate are required for Resolve operation" -Level "ERROR"
                exit 1
            }

            if (Resolve-DebtItem -DebtId $DebtId -ResolutionDate $ResolutionDate -ResolutionNotes $ResolutionNotes) {
                Write-Log "Technical debt item resolved successfully" -Level "SUCCESS"
                Write-Log "Updated file: $TechnicalDebtTrackingFile"
                exit 0
            }
            else {
                Write-Log "Failed to resolve technical debt item" -Level "ERROR"
                exit 1
            }
        }
    }
}

# Execute main function
Main
