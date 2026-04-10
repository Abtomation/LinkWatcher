#Requires -Version 5.1

<#
.SYNOPSIS
    Creates a new validation report from template.

.DESCRIPTION
    This script generates a new validation report for selected features using the
    standardized validation report template. It automatically assigns IDs, creates the
    report in the appropriate subdirectory, and updates the validation tracking file.

.PARAMETER ValidationType
    The type of validation being performed. Must be one of:
    - ArchitecturalConsistency
    - CodeQuality
    - IntegrationDependencies
    - DocumentationAlignment
    - ExtensibilityMaintainability
    - AIAgentContinuity
    - SecurityDataProtection
    - PerformanceScalability
    - Observability
    - AccessibilityUX
    - DataIntegrity

.PARAMETER FeatureIds
    Comma-separated list of feature IDs to validate (e.g., "0.2.1,0.2.2,0.2.3")

.PARAMETER BatchNumber
    Optional batch number for organizing reports (default: 1)

.PARAMETER SessionNumber
    Optional session number for this validation type (default: 1)

.PARAMETER PriorRoundReport
    Optional path to a prior round's validation report file. When provided, the script
    parses the prior report's scores and injects pre-populated trend comparison sections
    (criterion-level and per-feature) into the generated report. Accepts absolute paths
    or paths relative to the project root.

.EXAMPLE
    ../../../../../../validation/New-ValidationReport.ps1 -ValidationType "ArchitecturalConsistency" -FeatureIds "0.2.1,0.2.2,0.2.3"

    Creates an architectural consistency validation report for features 0.2.1-0.2.3

.EXAMPLE
    ../../../../../../validation/New-ValidationReport.ps1 -ValidationType "CodeQuality" -FeatureIds "0.2.4,0.2.5" -BatchNumber 2 -SessionNumber 2

    Creates a code quality validation report for features 0.2.4-0.2.5 in batch 2, session 2

.EXAMPLE
    ../../../../../../validation/New-ValidationReport.ps1 -ValidationType "AIAgentContinuity" -FeatureIds "0.1.1,0.1.2,0.1.3,1.1.1" -SessionNumber 11 -PriorRoundReport "doc/validation/reports/ai-agent-continuity/PD-VAL-052-ai-agent-continuity-features-0.1.1-0.1.2-0.1.3-1.1.1.md"

    Creates an AI agent continuity report with R2→R3 trend comparison sections pre-populated from the R2 report

.NOTES
    Author: AI Framework Extension
    Version: 1.0
    Created: 2025-08-15

    This script is part of the Feature Validation Framework.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("ArchitecturalConsistency", "CodeQuality", "IntegrationDependencies",
        "DocumentationAlignment", "ExtensibilityMaintainability", "AIAgentContinuity",
        "SecurityDataProtection", "PerformanceScalability", "Observability",
        "AccessibilityUX", "DataIntegrity")]
    [string]$ValidationType,

    [Parameter(Mandatory = $true)]
    [string]$FeatureIds,

    [Parameter(Mandatory = $false)]
    [int]$BatchNumber = 1,

    [Parameter(Mandatory = $false)]
    [int]$SessionNumber = 1,

    [Parameter(Mandatory = $false)]
    [string]$PriorRoundReport = ""
)

# Configuration
$ErrorActionPreference = "Stop"

# Get script directory for relative path resolution
$ScriptDirectory = if ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
else {
    $PSScriptRoot
}

# Import Common-ScriptHelpers for enhanced tracking functionality and Get-ProjectRoot
try {
    $dir = if ($MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $PWD.Path
    }
    while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
        $dir = Split-Path -Parent $dir
    }

    $helpersPath = Join-Path $dir "Common-ScriptHelpers.psm1"

    if (Test-Path $helpersPath) {
        Import-Module $helpersPath -Force
        $useEnhancedTracking = $true
        Write-Verbose "Enhanced tracking functionality available"
    }
    else {
        $useEnhancedTracking = $false
        Write-Verbose "Enhanced tracking not available, using legacy method"
    }
}
catch {
    $useEnhancedTracking = $false
    Write-Verbose "Failed to load enhanced tracking: $($_.Exception.Message)"
}

# Resolve paths using project root for reliability
$ProjectRoot = if ($useEnhancedTracking) { Get-ProjectRoot } else { (Get-Item (Join-Path $ScriptDirectory "../../../..")).FullName }
$TemplateFile = Join-Path $ProjectRoot "process-framework/templates/05-validation/validation-report-template.md"
# Discover active validation tracking file (highest -N suffix in state-tracking/validation/)
$trackingDir = Join-Path $ProjectRoot "doc/state-tracking/validation"
$trackingFiles = Get-ChildItem -Path $trackingDir -Filter "validation-tracking-*.md" -File |
    Where-Object { $_.Name -match '^validation-tracking-(\d+)\.md$' } |
    Sort-Object { [int]($_.Name -replace '^validation-tracking-(\d+)\.md$', '$1') } -Descending
if ($trackingFiles.Count -gt 0) {
    $TrackingFile = $trackingFiles[0].FullName
} else {
    Write-Warning "No validation-tracking-N.md found in $trackingDir. Tracking update will be skipped."
    $TrackingFile = $null
}
$IdRegistryFile = Join-Path $ProjectRoot "doc/PD-id-registry.json"

# Validation type mappings
$ValidationTypeMap = @{
    "ArchitecturalConsistency"     = @{
        "Directory"     = "architectural-consistency"
        "DisplayName"   = "Architectural Consistency"
        "ShortName"     = "architectural-consistency"
        "SectionNumber" = "1"
        "ProgressLabel" = "1. Architectural Consistency"
    }
    "CodeQuality"                  = @{
        "Directory"     = "code-quality"
        "DisplayName"   = "Code Quality & Standards"
        "ShortName"     = "code-quality"
        "SectionNumber" = "2"
        "ProgressLabel" = "2. Code Quality & Standards"
    }
    "IntegrationDependencies"      = @{
        "Directory"     = "integration-dependencies"
        "DisplayName"   = "Integration & Dependencies"
        "ShortName"     = "integration-dependencies"
        "SectionNumber" = "3"
        "ProgressLabel" = "3. Integration & Dependencies"
    }
    "DocumentationAlignment"       = @{
        "Directory"     = "documentation-alignment"
        "DisplayName"   = "Documentation Alignment"
        "ShortName"     = "documentation-alignment"
        "SectionNumber" = "4"
        "ProgressLabel" = "4. Documentation Alignment"
    }
    "ExtensibilityMaintainability" = @{
        "Directory"     = "extensibility-maintainability"
        "DisplayName"   = "Extensibility & Maintainability"
        "ShortName"     = "extensibility-maintainability"
        "SectionNumber" = "5"
        "ProgressLabel" = "5. Extensibility & Maintainability"
    }
    "AIAgentContinuity"            = @{
        "Directory"     = "ai-agent-continuity"
        "DisplayName"   = "AI Agent Continuity"
        "ShortName"     = "ai-agent-continuity"
        "SectionNumber" = "6"
        "ProgressLabel" = "6. AI Agent Continuity"
    }
    "SecurityDataProtection"       = @{
        "Directory"     = "security-data-protection"
        "DisplayName"   = "Security & Data Protection"
        "ShortName"     = "security-data-protection"
        "SectionNumber" = "7"
        "ProgressLabel" = "7. Security & Data Protection"
    }
    "PerformanceScalability"       = @{
        "Directory"     = "performance-scalability"
        "DisplayName"   = "Performance & Scalability"
        "ShortName"     = "performance-scalability"
        "SectionNumber" = "8"
        "ProgressLabel" = "8. Performance & Scalability"
    }
    "Observability"                = @{
        "Directory"     = "observability"
        "DisplayName"   = "Observability"
        "ShortName"     = "observability"
        "SectionNumber" = "9"
        "ProgressLabel" = "9. Observability"
    }
    "AccessibilityUX"              = @{
        "Directory"     = "accessibility-ux"
        "DisplayName"   = "Accessibility / UX Compliance"
        "ShortName"     = "accessibility-ux"
        "SectionNumber" = "10"
        "ProgressLabel" = "10. Accessibility / UX"
    }
    "DataIntegrity"                = @{
        "Directory"     = "data-integrity"
        "DisplayName"   = "Data Integrity"
        "ShortName"     = "data-integrity"
        "SectionNumber" = "11"
        "ProgressLabel" = "11. Data Integrity"
    }
}

function Get-NextValidationId {
    <#
    .SYNOPSIS
        Gets the next available PF-VAL ID from the registry
    #>
    try {
        # Use the script-level $IdRegistryFile variable (computed from $ProjectRoot)
        $absoluteIdRegistryPath = $IdRegistryFile

        if (-not (Test-Path $absoluteIdRegistryPath)) {
            throw "ID registry not found at: $absoluteIdRegistryPath"
        }

        $idRegistry = Get-Content $absoluteIdRegistryPath -Raw | ConvertFrom-Json
        $currentId = $idRegistry.prefixes."PD-VAL".nextAvailable

        # Update the registry
        $idRegistry.prefixes."PD-VAL".nextAvailable = $currentId + 1
        $idRegistry | ConvertTo-Json -Depth 10 | Set-Content $absoluteIdRegistryPath

        return "PD-VAL-{0:D3}" -f $currentId
    }
    catch {
        Write-Error "Failed to get next validation ID: $_"
        throw
    }
}

function Get-PriorRoundData {
    <#
    .SYNOPSIS
        Parses a prior validation report for score data used in trend comparison sections.
    .OUTPUTS
        Hashtable with keys: RoundNumber, OverallScore, CriterionScores (array of {Name, Score}),
        FeatureScores (array of {Id, Name, Score}), ReportId
    #>
    param([string]$ReportPath)

    if (-not (Test-Path $ReportPath)) {
        throw "Prior round report not found: $ReportPath"
    }

    $content = Get-Content $ReportPath -Raw
    $result = @{
        RoundNumber     = 0
        OverallScore    = ""
        CriterionScores = @()
        FeatureScores   = @()
        ReportId        = ""
    }

    # Extract report ID from frontmatter
    if ($content -match '(?m)^id:\s*(PD-VAL-\d+)') {
        $result.ReportId = $Matches[1]
    }

    # Extract round number from "**Validation Round**: Round N" metadata line
    if ($content -match '(?m)^\*\*Validation Round\*\*:\s*Round\s+(\d+)') {
        $result.RoundNumber = [int]$Matches[1]
    }

    # Extract overall score from "**Overall Score**: X.X/3.0" or TOTAL row
    if ($content -match '\*\*Overall Score\*\*:\s*([\d.]+/[\d.]+)') {
        $result.OverallScore = $Matches[1]
    }

    # Extract criterion scores from Overall Scoring table
    # Pattern: | Criterion Name | X.XX/3 | weight | weighted | notes |
    $scoringSection = $false
    $lines = $content -split "`n"
    foreach ($line in $lines) {
        if ($line -match '###\s+Overall Scoring') {
            $scoringSection = $true
            continue
        }
        if ($scoringSection -and $line -match '^\s*#{2,3}\s') {
            $scoringSection = $false
            continue
        }
        if ($scoringSection -and $line -match '^\|\s*([^|*]+?)\s*\|\s*([\d.]+/[\d.]+)\s*\|') {
            $criterionName = $Matches[1].Trim()
            $score = $Matches[2].Trim()
            # Skip header/separator rows and TOTAL row
            if ($criterionName -notmatch '^(Criterion|---|\*\*TOTAL)') {
                $result.CriterionScores += @{ Name = $criterionName; Score = $score }
            }
        }
    }

    # Extract per-feature scores from Per-Feature Scores table
    # Reports use a pivot table: features as columns, criteria as rows, with a "Feature Average" row
    $featureSection = $false
    $featureIds = @()
    foreach ($line in $lines) {
        if ($line -match '###\s+Per-Feature Scores') {
            $featureSection = $true
            continue
        }
        if ($featureSection -and $line -match '^\s*#{2,3}\s') {
            $featureSection = $false
            continue
        }
        if ($featureSection) {
            # Parse header row to extract feature IDs (columns)
            if ($featureIds.Count -eq 0 -and $line -match '^\|.*\d+\.\d+\.\d+') {
                $cells = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                # Skip first cell (Criterion label), rest are feature IDs
                for ($i = 1; $i -lt $cells.Count; $i++) {
                    if ($cells[$i] -match '(\d+\.\d+\.\d+)') {
                        $featureIds += $Matches[1]
                    }
                }
            }
            # Parse Feature Average row to extract scores
            if ($featureIds.Count -gt 0 -and $line -match 'Feature Average') {
                $cells = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                # Skip first cell (label), rest are scores matching featureIds order
                for ($i = 1; $i -lt $cells.Count -and ($i - 1) -lt $featureIds.Count; $i++) {
                    $scoreText = $cells[$i] -replace '\*', ''
                    $result.FeatureScores += @{ Id = $featureIds[$i - 1]; Score = $scoreText }
                }
            }
        }
    }

    return $result
}

function Build-TrendComparisonSection {
    <#
    .SYNOPSIS
        Builds trend comparison markdown sections from prior round data.
    #>
    param([hashtable]$PriorData, [int]$CurrentRound)

    $priorRound = "R$($PriorData.RoundNumber)"
    $currentRound = "R$CurrentRound"
    $sb = [System.Text.StringBuilder]::new()

    # Criterion-level comparison
    [void]$sb.AppendLine("### ${priorRound}→${currentRound} Score Comparison")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Criterion | $priorRound Score | $currentRound Score | Delta |")
    [void]$sb.AppendLine("|---|---|---|---|")
    foreach ($criterion in $PriorData.CriterionScores) {
        [void]$sb.AppendLine("| $($criterion.Name) | $($criterion.Score) | —/3 | |")
    }
    [void]$sb.AppendLine("| **Overall** | **$($PriorData.OverallScore)** | **—/3.0** | **** |")
    [void]$sb.AppendLine("")

    # Per-feature comparison
    if ($PriorData.FeatureScores.Count -gt 0) {
        [void]$sb.AppendLine("### Per-Feature ${priorRound}→${currentRound} Comparison")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| Feature | $priorRound Score | $currentRound Score | Delta | Key Change |")
        [void]$sb.AppendLine("|---|---|---|---|---|")
        foreach ($feature in $PriorData.FeatureScores) {
            [void]$sb.AppendLine("| $($feature.Id) | $($feature.Score) | —/3 | | |")
        }
        [void]$sb.AppendLine("")
    }

    # Prior report reference
    [void]$sb.AppendLine("> Prior round report: $($PriorData.ReportId)")
    [void]$sb.AppendLine("")

    return $sb.ToString()
}

function Get-FeatureInfo {
    <#
    .SYNOPSIS
        Parses feature-tracking.md to extract feature ID → name and status mappings.
    .OUTPUTS
        Hashtable mapping feature IDs (e.g., "0.1.1") to @{ Name = "..."; Status = "..." }
    #>
    param([string[]]$FeatureIds)

    $featureTrackingPath = Join-Path $ProjectRoot "doc/state-tracking/permanent/feature-tracking.md"
    $result = @{}

    if (-not (Test-Path $featureTrackingPath)) {
        Write-Warning "Feature tracking file not found: $featureTrackingPath. Feature names will use placeholders."
        foreach ($id in $FeatureIds) {
            $result[$id] = @{ Name = "[Feature Name]"; Status = "[Status]" }
        }
        return $result
    }

    $content = Get-Content $featureTrackingPath -Raw
    $lines = $content -split "`n"

    # Parse table rows matching feature IDs: | [X.Y.Z](link) | Feature Name | Status | ...
    # Also handle: | [X.Y.Z](<link with spaces>) | Feature Name | Status | ...
    foreach ($line in $lines) {
        foreach ($id in $FeatureIds) {
            $escapedId = [regex]::Escape($id)
            if ($line -match "^\|\s*\[$escapedId\]\([^)]+\)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|") {
                $name = $Matches[1].Trim()
                $rawStatus = $Matches[2].Trim()
                # Strip emoji prefixes for clean status text
                $cleanStatus = $rawStatus -replace '^[^\w]*\s*', ''
                if ($cleanStatus -eq '') { $cleanStatus = $rawStatus }
                $result[$id] = @{ Name = $name; Status = $cleanStatus }
            }
        }
    }

    # Fill in any missing features with placeholders
    foreach ($id in $FeatureIds) {
        if (-not $result.ContainsKey($id)) {
            Write-Warning "Feature $id not found in feature-tracking.md. Using placeholder."
            $result[$id] = @{ Name = "[Feature Name]"; Status = "[Status]" }
        }
    }

    return $result
}

function New-ValidationReportFromTemplate {
    <#
    .SYNOPSIS
        Creates a new validation report from the template
    #>
    param(
        [string]$ValidationId,
        [string]$OutputPath,
        [hashtable]$ValidationConfig,
        [string[]]$Features
    )

    try {
        # Read template
        if (-not (Test-Path $TemplateFile)) {
            throw "Template file not found: $TemplateFile"
        }

        $templateContent = Get-Content $TemplateFile -Raw

        # Extract the document template section
        $documentTemplateStart = $templateContent.IndexOf("```markdown")
        $documentTemplateEnd = $templateContent.IndexOf("``", $documentTemplateStart + 11)

        if ($documentTemplateStart -eq -1 -or $documentTemplateEnd -eq -1) {
            throw 'Could not find document template section in template file'
        }

        $documentTemplate = $templateContent.Substring($documentTemplateStart + 11, $documentTemplateEnd - $documentTemplateStart - 11).Trim()

        # Derive round number from the active tracking file name
        $roundNumber = 1
        if ($TrackingFile -and $TrackingFile -match 'validation-tracking-(\d+)\.md$') {
            $roundNumber = [int]$Matches[1]
        }

        # Replace placeholders
        $currentDate = Get-Date -Format 'yyyy-MM-dd'
        $featureRange = ($Features | Sort-Object) -join '-'
        $featureList = $Features -join ', '

        $reportContent = $documentTemplate
        $reportContent = $reportContent -replace '\[PF-VAL-XXX - will be assigned from ID registry\]', $ValidationId
        $reportContent = $reportContent -replace '\[YYYY-MM-DD\]', $currentDate
        $reportContent = $reportContent -replace '\[validation-type\]', $ValidationConfig.ShortName
        $reportContent = $reportContent -replace '\[Validation Type\]', $ValidationConfig.DisplayName
        $reportContent = $reportContent -replace '\[Validation Type Name\]', $ValidationConfig.DisplayName
        $reportContent = $reportContent -replace '\[Feature Range\]', $featureRange
        $reportContent = $reportContent -replace '\[List of features, e\.g\., 0\.2\.1, 0\.2\.2, 0\.2\.3\]', $featureList
        $reportContent = $reportContent -replace '\[e\.g\., "0\.2\.1, 0\.2\.2, 0\.2\.3"\]', ('"' + $featureList + '"')
        $reportContent = $reportContent -replace '\[Session number for this validation type\]', $SessionNumber.ToString()
        $reportContent = $reportContent -replace '\[Date\]', $currentDate
        $reportContent = $reportContent -replace '\[RoundNumber\]', $roundNumber.ToString()

        # Pre-populate Features Included table from feature-tracking.md
        $featureInfo = Get-FeatureInfo -FeatureIds $Features
        if ($featureInfo.Count -gt 0) {
            # Build replacement rows for the Features Included table
            $featureRows = ($Features | Sort-Object | ForEach-Object {
                $info = $featureInfo[$_]
                "| $_ | $($info.Name) | $($info.Status) | Full feature |"
            }) -join "`n"

            # Replace the two placeholder rows in the Features Included table
            $placeholderPattern = '(?m)\| \[0\.2\.X\].*\n\| \[0\.2\.Y\].*'
            if ($reportContent -match $placeholderPattern) {
                $reportContent = $reportContent -replace $placeholderPattern, $featureRows
                Write-Host "   ✅ Pre-populated Features Included table ($($Features.Count) features)" -ForegroundColor Green
            }

            # Build replacement Detailed Findings sections
            $detailedSections = ($Features | Sort-Object | ForEach-Object {
                $info = $featureInfo[$_]
                @"
### Feature $_ - $($info.Name)

#### Strengths

- [Positive finding 1]
- [Positive finding 2]

#### Issues Identified

| Severity          | Issue               | Impact               | Recommendation       |
| ----------------- | ------------------- | -------------------- | -------------------- |
| [High/Medium/Low] | [Issue description] | [Impact description] | [Recommended action] |

#### Validation Details

[Detailed analysis specific to this feature]
"@
            }) -join "`n`n"

            # Replace the two placeholder Detailed Findings sections
            $detailedPattern = '(?ms)### \[Feature 0\.2\.X\].*?### \[Feature 0\.2\.Y\].*?\[Detailed analysis specific to this feature\]'
            if ($reportContent -match $detailedPattern) {
                $reportContent = $reportContent -replace $detailedPattern, $detailedSections
                Write-Host "   ✅ Pre-populated Detailed Findings sections ($($Features.Count) features)" -ForegroundColor Green
            }
        }

        # Inject trend comparison sections if prior round report was provided
        if ($script:PriorRoundData) {
            $currentRound = $script:PriorRoundData.RoundNumber + 1
            $trendSection = Build-TrendComparisonSection -PriorData $script:PriorRoundData -CurrentRound $currentRound

            # Insert before "## Validation Scope"
            $insertPoint = $reportContent.IndexOf("## Validation Scope")
            if ($insertPoint -ge 0) {
                $reportContent = $reportContent.Substring(0, $insertPoint) + $trendSection + $reportContent.Substring($insertPoint)
                Write-Host "   ✅ Injected trend comparison sections (R$($script:PriorRoundData.RoundNumber)→R$currentRound)" -ForegroundColor Green
            }
            else {
                Write-Warning "Could not find '## Validation Scope' insertion point. Trend sections not injected."
            }
        }

        # Write the report
        Set-Content -Path $OutputPath -Value $reportContent -Encoding UTF8

        Write-Host "✅ Created validation report: $OutputPath" -ForegroundColor Green
        Write-Host "   ID: $ValidationId" -ForegroundColor Gray
        Write-Host "   Type: $($ValidationConfig.DisplayName)" -ForegroundColor Gray
        Write-Host "   Features: $featureList" -ForegroundColor Gray

    }
    catch {
        Write-Error "Failed to create validation report: $_"
        throw
    }
}

function Update-ValidationTracking {
    <#
    .SYNOPSIS
        Updates the validation tracking file with the new report.
        Adds a reports registry row and increments the Overall Progress reports count.
    #>
    param(
        [string]$ValidationId,
        [string]$ValidationType,
        [hashtable]$ValidationConfig,
        [string[]]$Features,
        [string]$ReportPath
    )

    try {
        if (-not $TrackingFile -or -not (Test-Path $TrackingFile)) {
            Write-Warning "No active validation tracking file found. Manual update required."
            return
        }

        $content = Get-Content -Path $TrackingFile -Raw -Encoding UTF8
        $updated = $false

        # --- 1. Add row to Reports Registry table ---
        $sectionNum = $ValidationConfig.SectionNumber
        $sectionHeader = "### $sectionNum. $($ValidationConfig.DisplayName) Validation Reports"
        $currentDate = Get-Date -Format 'yyyy-MM-dd'
        $featureList = $Features -join ', '

        # Build the report link path (absolute from project root, matching existing entries)
        $reportRelPath = "/doc/validation/reports/$($ValidationConfig.Directory)/$(Split-Path $ReportPath -Leaf)"
        $newRow = "| [$ValidationId]($reportRelPath) | $featureList | $currentDate | —/3.0 | IN PROGRESS | — | — |"

        $sectionIdx = $content.IndexOf($sectionHeader)
        if ($sectionIdx -ge 0) {
            # Find the end of the table under this section header.
            # Strategy: find the last table row (line starting with |) before the next ### or ## header or end of content.
            $afterSection = $content.Substring($sectionIdx + $sectionHeader.Length)
            $lines = $afterSection -split "`n"
            $insertAfterLine = -1
            $lineOffset = 0
            foreach ($line in $lines) {
                $trimmed = $line.Trim()
                if ($trimmed -match '^\|.*\|$') {
                    $insertAfterLine = $lineOffset
                }
                elseif ($trimmed -match '^#{2,3}\s' -and $lineOffset -gt 0) {
                    break
                }
                $lineOffset++
            }

            if ($insertAfterLine -ge 0) {
                # Reconstruct: everything up to and including the last table row, then our new row, then the rest
                $beforeLines = $lines[0..$insertAfterLine]
                $afterLines = if ($insertAfterLine + 1 -lt $lines.Count) { $lines[($insertAfterLine + 1)..($lines.Count - 1)] } else { @() }
                $afterSection = ($beforeLines -join "`n") + "`n" + $newRow + "`n" + ($afterLines -join "`n")
                $content = $content.Substring(0, $sectionIdx + $sectionHeader.Length) + $afterSection
                $updated = $true
                Write-Host "   ✅ Added reports registry row under '$sectionHeader'" -ForegroundColor Green
            }
            else {
                Write-Warning "Could not find table rows under '$sectionHeader'. Manual update required."
            }
        }
        else {
            Write-Warning "Section '$sectionHeader' not found in tracking file. Manual update required."
        }

        # --- 2. Increment Reports Generated in Overall Progress table ---
        $progressLabel = [regex]::Escape($ValidationConfig.ProgressLabel)
        # Match the row: | <label with optional trailing spaces> | <items> | <reports count> | <status> | <next session> |
        $progressPattern = "(\|\s*$progressLabel\s*\|[^|]+\|\s*)(\d+)(\s*\|[^|]+\|[^|]+\|)"
        if ($content -match $progressPattern) {
            $currentReports = [int]$Matches[2]
            $newReports = $currentReports + 1
            $content = $content -replace $progressPattern, "`${1}$newReports`${3}"
            $updated = $true
            Write-Host "   ✅ Incremented Reports Generated: $currentReports → $newReports" -ForegroundColor Green
        }
        else {
            Write-Warning "Could not find Overall Progress row for '$($ValidationConfig.ProgressLabel)'. Manual update required."
        }

        # --- Write back ---
        if ($updated) {
            Set-Content -Path $TrackingFile -Value $content -NoNewline -Encoding UTF8
            Write-Host "   📄 Updated: $TrackingFile" -ForegroundColor Gray
        }
    }
    catch {
        Write-Warning "Could not update validation tracking: $($_.Exception.Message)"
        Write-Warning "Manual update required for: $TrackingFile"
    }
}

# Main execution
try {
    Write-Host "🔍 Creating Feature Validation Report..." -ForegroundColor Cyan
    Write-Host ""

    # Validate inputs
    $validationConfig = $ValidationTypeMap[$ValidationType]
    $features = $FeatureIds -split ',' | ForEach-Object { $_.Trim() }

    Write-Host "📋 Validation Configuration:" -ForegroundColor White
    Write-Host "   Type: $($validationConfig.DisplayName)" -ForegroundColor Gray
    Write-Host "   Features: $($features -join ', ')" -ForegroundColor Gray
    Write-Host "   Batch: $BatchNumber" -ForegroundColor Gray
    Write-Host "   Session: $SessionNumber" -ForegroundColor Gray
    Write-Host "   Tracking File: $(if ($TrackingFile) { $TrackingFile } else { '(none found)' })" -ForegroundColor Gray
    if ($PriorRoundReport) {
        Write-Host "   Prior Round: $PriorRoundReport" -ForegroundColor Gray
    }
    Write-Host ""

    # Parse prior round report if provided
    $script:PriorRoundData = $null
    if ($PriorRoundReport -ne "") {
        $priorPath = if ([System.IO.Path]::IsPathRooted($PriorRoundReport)) {
            $PriorRoundReport
        } else {
            Join-Path $ProjectRoot $PriorRoundReport
        }
        Write-Host "📊 Parsing prior round report..." -ForegroundColor White
        $script:PriorRoundData = Get-PriorRoundData -ReportPath $priorPath
        Write-Host "   Report: $($script:PriorRoundData.ReportId)" -ForegroundColor Gray
        Write-Host "   Round: $($script:PriorRoundData.RoundNumber)" -ForegroundColor Gray
        Write-Host "   Overall Score: $($script:PriorRoundData.OverallScore)" -ForegroundColor Gray
        Write-Host "   Criteria: $($script:PriorRoundData.CriterionScores.Count)" -ForegroundColor Gray
        Write-Host "   Features: $($script:PriorRoundData.FeatureScores.Count)" -ForegroundColor Gray
        Write-Host ""
    }

    # Compute output path for ShouldProcess message
    $featureRange = ($features | Sort-Object) -join "-"
    $outputDir = Join-Path $ProjectRoot "doc/validation/reports/$($validationConfig.Directory)"

    if ($PSCmdlet.ShouldProcess("$outputDir", "Create $($validationConfig.DisplayName) validation report for features $($features -join ', ')")) {
        # Get next validation ID
        Write-Host "🆔 Assigning validation ID..." -ForegroundColor White
        $validationId = Get-NextValidationId
        Write-Host "   Assigned ID: $validationId" -ForegroundColor Green
        Write-Host ""

        # Create output path
        $fileName = "$validationId-$($validationConfig.ShortName)-features-$featureRange.md"
        $outputPath = Join-Path $outputDir $fileName

        # Ensure output directory exists
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        Write-Host "📁 Output Configuration:" -ForegroundColor White
        Write-Host "   Directory: $outputDir" -ForegroundColor Gray
        Write-Host "   Filename: $fileName" -ForegroundColor Gray
        Write-Host "   Full Path: $outputPath" -ForegroundColor Gray
        Write-Host ""

        # Create the validation report
        Write-Host "📝 Generating validation report..." -ForegroundColor White
        New-ValidationReportFromTemplate -ValidationId $validationId -OutputPath $outputPath -ValidationConfig $validationConfig -Features $features
        Write-Host ""

        # Update tracking — directly update reports registry and overall progress
        Write-Host "📊 Updating validation tracking..." -ForegroundColor White
        Update-ValidationTracking -ValidationId $validationId -ValidationType $ValidationType -ValidationConfig $validationConfig -Features $features -ReportPath $outputPath
        Write-Host ""

        # Auto-append entry to PD-documentation-map.md under the correct Round section
        $pdDocMapPath = Join-Path $ProjectRoot "doc/PD-documentation-map.md"
        if (Test-Path $pdDocMapPath) {
            $sectionHeader = "### Round $roundNumber Validation Reports"
            $featureList = ($features | Sort-Object) -join ', '
            $relPath = "validation/reports/$($validationConfig.Directory)/$fileName"
            $entryLine = "- [Validation: $($validationConfig.DisplayName) — $featureList ($validationId)]($relPath) - Session $SessionNumber"

            $updated = Add-DocumentationMapEntry -DocMapPath $pdDocMapPath -SectionHeader $sectionHeader -EntryLine $entryLine -CallerCmdlet $PSCmdlet
            if ($updated) {
                Write-Host "   📄 Updated: PD-documentation-map.md (section: $sectionHeader)" -ForegroundColor Gray
            }
        }

        Write-Host "🎉 Validation report created successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Next Steps:" -ForegroundColor Yellow
        Write-Host "   1. Open the report file: $outputPath" -ForegroundColor Gray
        Write-Host "   2. Customize validation criteria based on validation type" -ForegroundColor Gray
        Write-Host "   3. Conduct the validation and fill in findings" -ForegroundColor Gray
        Write-Host "   4. Update the registry row (Score, Status, Issues, Actions) after validation completes" -ForegroundColor Gray
        Write-Host ""
        Write-Host "📖 Reference:" -ForegroundColor Yellow
        Write-Host "   Template: $TemplateFile" -ForegroundColor Gray
        Write-Host "   Tracking: $TrackingFile" -ForegroundColor Gray
    }

}
catch {
    Write-Error "❌ Failed to create validation report: $_"
    exit 1
}
