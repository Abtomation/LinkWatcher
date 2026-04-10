# New-ValidationTracking.ps1
# Creates a new validation tracking state file for a validation round
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new validation tracking state file for a validation round.

.DESCRIPTION
    This PowerShell script generates validation tracking state files by:
    - Generating a unique state ID (PF-STA-XXX) automatically
    - Creating the file in doc/state-tracking/validation/
    - Auto-populating the Feature Scope table from feature-tracking.md
    - Archiving the prior round's tracking file (optional)
    - Extracting prior round quality scores into a "Prior Round Score" column
    - Updating the ID tracker in the central ID registry

    Used by the Validation Preparation task (PF-TSK-077) to create the
    tracking file that coordinates all validation sessions in a round.

.PARAMETER RoundNumber
    The validation round number (e.g., 1, 2, 3). Used in the document title
    and filename.

.PARAMETER Description
    Optional description of the validation round's focus or scope.

.PARAMETER ArchivePriorRound
    If specified, moves the prior round's tracking file (RoundNumber - 1) to
    doc/state-tracking/validation/archive/. Skipped if prior round not found
    or already archived.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor.

.EXAMPLE
    New-ValidationTracking.ps1 -RoundNumber 5

    Creates validation-tracking-5.md with Feature Scope auto-populated from
    feature-tracking.md.

.EXAMPLE
    New-ValidationTracking.ps1 -RoundNumber 5 -ArchivePriorRound

    Archives validation-tracking-4.md to archive/, then creates round 5.

.EXAMPLE
    New-ValidationTracking.ps1 -RoundNumber 5 -Description "Post-refactoring re-validation"

.NOTES
    Script Type: Document Creation Script
    Created: 2026-04-02
    Updated: 2026-04-10
    For: Validation Preparation task (PF-TSK-077)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [int]$RoundNumber,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [switch]$ArchivePriorRound,

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

$today = Get-Date -Format "yyyy-MM-dd"
$projectRoot = Get-ProjectRoot
$validationDir = Join-Path $projectRoot "doc/state-tracking/validation"
$archiveDir = Join-Path $validationDir "archive"
$priorRoundNum = $RoundNumber - 1

# ============================================================
# 1. Archive prior round (if requested)
# ============================================================
$priorRoundArchived = $false
if ($ArchivePriorRound -and $RoundNumber -gt 1) {
    $priorFile = Join-Path $validationDir "validation-tracking-$priorRoundNum.md"

    if (Test-Path $priorFile) {
        if ($PSCmdlet.ShouldProcess("validation-tracking-$priorRoundNum.md", "Archive to validation/archive/")) {
            New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
            Move-Item -Path $priorFile -Destination (Join-Path $archiveDir "validation-tracking-$priorRoundNum.md") -Force
            $priorRoundArchived = $true
            Write-Host "📦 Archived validation-tracking-$priorRoundNum.md to archive/" -ForegroundColor Cyan
        }
    }
    else {
        Write-Warning "Prior round file validation-tracking-$priorRoundNum.md not found (may already be archived). Skipping archive."
    }
}

# ============================================================
# 2. Get active features from feature-tracking.md
# ============================================================
$features = Get-ActiveFeatures
$featureScopeRows = @()

foreach ($f in $features) {
    $featureId = $f['ID']
    $featureName = $f['Feature']
    $rawStatus = $f['Status']
    $priority = $f['Priority']

    # Strip markdown link from ID — Get-ActiveFeatures returns raw cell content like "[0.1.1](path)"
    if ($featureId -match '\[([^\]]+)\]') {
        $featureId = $Matches[1]
    }

    $featureScopeRows += "| $featureId | $featureName | $rawStatus | $priority | — |"
}

if ($featureScopeRows.Count -gt 0) {
    Write-Host "📋 Auto-populated $($featureScopeRows.Count) features from feature-tracking.md" -ForegroundColor Cyan
}
else {
    Write-Warning "No active features found in feature-tracking.md. Template will use placeholder rows."
}

# ============================================================
# 3. Extract prior round quality scores (if prior round exists)
# ============================================================
$priorScores = @{}  # key: dimension name, value: score string

$priorRoundFile = $null
if ($priorRoundNum -ge 1) {
    $candidates = @(
        (Join-Path $archiveDir "validation-tracking-$priorRoundNum.md"),
        (Join-Path $validationDir "validation-tracking-$priorRoundNum.md")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            $priorRoundFile = $candidate
            break
        }
    }
}

if ($priorRoundFile) {
    $priorContent = Get-Content $priorRoundFile -Raw -Encoding UTF8

    # Use ConvertFrom-MarkdownTable to parse the Overall Quality Scores table
    $scoreRows = ConvertFrom-MarkdownTable -Content $priorContent -Section "### Overall Quality Scores"

    foreach ($row in $scoreRows) {
        $dimName = $row.'Validation Type'
        if (-not $dimName) { continue }
        $dimName = $dimName.Trim()
        # Strip leading number prefix (e.g., "1. Architectural Consistency" → "Architectural Consistency")
        $dimName = $dimName -replace '^\d+\.\s*', ''

        # Find the score column — look for "R<N> Score" or "Average Score" column
        $scoreVal = $null
        foreach ($prop in $row.PSObject.Properties) {
            if ($prop.Name -match "R$priorRoundNum Score|Average Score") {
                $scoreVal = $prop.Value
                break
            }
        }

        if ($scoreVal -and $scoreVal -ne 'N/A') {
            $priorScores[$dimName] = $scoreVal.Trim()
        }
    }

    if ($priorScores.Count -gt 0) {
        Write-Host "📊 Extracted $($priorScores.Count) quality scores from Round $priorRoundNum" -ForegroundColor Cyan
    }
}

# ============================================================
# 4. Build replacement content
# ============================================================

# Build Feature Scope table replacement
$featureScopeTable = if ($featureScopeRows.Count -gt 0) {
    $header = "| Feature ID | Feature Name | Implementation Status | Priority | Workflow Cohort |"
    $separator = "|------------|-------------|----------------------|----------|-----------------|"
    @($header, $separator) + $featureScopeRows | Join-String -Separator "`n"
}
else {
    $null  # Keep template placeholder
}

# Build Overall Quality Scores table with prior round column
$qualityScoresTable = $null
$dimensions = @(
    "Architectural Consistency",
    "Code Quality & Standards",
    "Integration & Dependencies",
    "Documentation Alignment",
    "Extensibility & Maintainability",
    "AI Agent Continuity",
    "Security & Data Protection",
    "Performance & Scalability",
    "Observability",
    "Accessibility / UX Compliance",
    "Data Integrity"
)

if ($priorScores.Count -gt 0) {
    $qHeader = "| Validation Type                 | R$priorRoundNum Score | R$RoundNumber Score | Trend | Best Feature | Worst Feature |"
    $qSep    = "|---------------------------------|--------------|--------------|-------|--------------|---------------|"
    $qRows = @()
    foreach ($dim in $dimensions) {
        # Find matching score — try exact match first, then partial
        $score = "N/A"
        foreach ($key in $priorScores.Keys) {
            if ($key -eq $dim -or $key -like "*$dim*" -or $dim -like "*$key*") {
                $score = $priorScores[$key]
                break
            }
        }
        $qRows += "| $($dim.PadRight(31)) | $score | N/A | N/A | N/A          | N/A           |"
    }
    $qualityScoresTable = @($qHeader, $qSep) + $qRows | Join-String -Separator "`n"
}

# Prepare custom replacements
$customReplacements = @{
    "[Round N]" = "Round $RoundNumber"
    "[YYYY-MM-DD]" = $today
}

if ($Description -ne "") {
    $customReplacements["[Describe first validation session]"] = $Description
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "validation_round" = "$RoundNumber"
}

$customFileName = "validation-tracking-$RoundNumber.md"

try {
    $documentId = New-StandardProjectDocument `
        -TemplatePath "process-framework/templates/05-validation/validation-tracking-template.md" `
        -IdPrefix "PF-STA" `
        -IdDescription "Validation tracking state for Round $RoundNumber" `
        -DocumentName "Validation Tracking Round $RoundNumber" `
        -OutputDirectory "doc/state-tracking/validation" `
        -Replacements $customReplacements `
        -AdditionalMetadataFields $additionalMetadataFields `
        -FileNamePattern $customFileName `
        -OpenInEditor:$OpenInEditor

    # ============================================================
    # 5. Post-creation: replace template sections with generated content
    # ============================================================
    $outputFile = Join-Path $validationDir $customFileName

    # In -WhatIf mode the file won't exist — skip post-processing
    if (-not (Test-Path $outputFile)) {
        Write-ProjectSuccess -Message "Created validation tracking with ID: $documentId (WhatIf — post-processing skipped)"
        return
    }

    $fileContent = Get-Content $outputFile -Raw

    # Replace Feature Scope placeholder table
    if ($featureScopeTable) {
        $placeholderPattern = '(?m)\| Feature ID \| Feature Name \| Implementation Status \| Priority \| Workflow Cohort \|\s*\n\|[-| ]+\|\s*\n\| \[X\.Y\.Z\][^\n]*\n'
        if ($fileContent -match $placeholderPattern) {
            $fileContent = $fileContent -replace [regex]::Escape($Matches[0]), "$featureScopeTable`n"
        }
    }

    # Replace Overall Quality Scores placeholder table
    if ($qualityScoresTable) {
        # Match from the header row through all the N/A rows
        $scoresPlaceholderPattern = '(?ms)\| Validation Type\s+\| Average Score \| Trend \| Best Feature \| Worst Feature \|\s*\n\|[-| ]+\|\s*\n((\|[^\n]+N/A[^\n]*\n)+)'
        if ($fileContent -match $scoresPlaceholderPattern) {
            $fileContent = $fileContent -replace [regex]::Escape($Matches[0]), "$qualityScoresTable`n"
        }
    }

    # Add prior round reference if applicable
    if ($priorRoundNum -ge 1) {
        $priorRoundRef = if ($priorRoundArchived) {
            "**Prior Round**: [Round $priorRoundNum](archive/validation-tracking-$priorRoundNum.md)"
        }
        elseif (Test-Path (Join-Path $archiveDir "validation-tracking-$priorRoundNum.md")) {
            "**Prior Round**: [Round $priorRoundNum](archive/validation-tracking-$priorRoundNum.md)"
        }
        elseif (Test-Path (Join-Path $validationDir "validation-tracking-$priorRoundNum.md")) {
            "**Prior Round**: [Round $priorRoundNum](validation-tracking-$priorRoundNum.md)"
        }
        else {
            $null
        }

        if ($priorRoundRef) {
            # Insert after the Purpose & Context heading paragraph
            $fileContent = $fileContent -replace '(## Purpose & Context\s*\n\s*\n[^\n]+\n)', "`$1`n$priorRoundRef`n"
        }
    }

    # Write updated content
    if ($PSCmdlet.ShouldProcess($outputFile, "Apply auto-populated content")) {
        Set-Content -Path $outputFile -Value $fileContent -Encoding UTF8 -NoNewline
    }

    # ============================================================
    # 6. Success output
    # ============================================================
    $details = @(
        "Round: $RoundNumber",
        "Location: doc/state-tracking/validation/$customFileName"
    )

    if ($Description -ne "") {
        $details += "Description: $Description"
    }

    if ($priorRoundArchived) {
        $details += "Archived: validation-tracking-$priorRoundNum.md moved to archive/"
    }

    if ($featureScopeRows.Count -gt 0) {
        $details += "Features: $($featureScopeRows.Count) auto-populated from feature-tracking.md"
    }

    if ($priorScores.Count -gt 0) {
        $details += "Prior Scores: $($priorScores.Count) dimension scores from Round $priorRoundNum"
    }

    $details += @(
        "",
        "⚠️  Review the auto-populated Feature Scope table for accuracy.",
        "⚠️  Update the Validation Progress Matrix dimensions based on feature profiles.",
        "⚠️  Plan the validation session sequence.",
        "",
        "📖 REFERENCE:",
        "process-framework/guides/05-validation/feature-validation-guide.md",
        "🎯 FOCUS: Dimension Catalog and feature Dimension Profiles"
    )

    Write-ProjectSuccess -Message "Created validation tracking with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create validation tracking: $($_.Exception.Message)" -ExitCode 1
}
