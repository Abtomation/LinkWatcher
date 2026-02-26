# Generate-ValidationSummary.ps1
# Generates consolidated validation summaries from multiple validation reports
# Creates strategic overview for decision-making and progress tracking

<#
.SYNOPSIS
    Generates consolidated validation summaries from multiple validation reports.

.DESCRIPTION
    This PowerShell script creates consolidated validation summaries by:
    - Aggregating data from all validation reports across validation types
    - Calculating overall foundational codebase health scores
    - Identifying critical issues and improvement priorities
    - Creating actionable improvement roadmaps
    - Generating executive summaries for stakeholder communication

.PARAMETER OutputPath
    Path where the consolidated summary report will be created

.PARAMETER IncludeDetails
    Include detailed findings and recommendations in the summary

.PARAMETER ValidationTypes
    Comma-separated list of validation types to include (default: all types)

.PARAMETER FeatureFilter
    Comma-separated list of specific features to include (default: all features)

.PARAMETER SummaryType
    Type of summary to generate: Executive, Detailed, or Technical

.PARAMETER OpenInEditor
    If specified, opens the created summary in the default editor

.EXAMPLE
    .\Generate-ValidationSummary.ps1 -OutputPath "consolidated-validation-report.md" -IncludeDetails

.EXAMPLE
    .\Generate-ValidationSummary.ps1 -OutputPath "executive-summary.md" -SummaryType "Executive" -ValidationTypes "Architectural,CodeQuality"

.EXAMPLE
    .\Generate-ValidationSummary.ps1 -OutputPath "feature-summary.md" -FeatureFilter "0.2.1,0.2.2,0.2.3" -IncludeDetails -OpenInEditor

.NOTES
    - Requires read access to validation reports and tracking files
    - Analyzes all available validation reports to generate comprehensive summaries
    - Supports filtering by validation type and feature for focused summaries
    - Creates actionable improvement roadmaps based on validation findings
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeDetails,

    [Parameter(Mandatory = $false)]
    [string]$ValidationTypes = "Architectural,CodeQuality,Integration,Documentation,Extensibility,AIContinuity",

    [Parameter(Mandatory = $false)]
    [string]$FeatureFilter = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Executive", "Detailed", "Technical")]
    [string]$SummaryType = "Detailed",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers for Get-ProjectRoot
$helpersPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "scripts/Common-ScriptHelpers.psm1"
if (Test-Path $helpersPath) {
    Import-Module $helpersPath -Force
} else {
    Write-Error "Common-ScriptHelpers.psm1 not found at: $helpersPath"
    exit 1
}

# Configuration - use project-root-relative paths for reliability
$ProjectRoot = Get-ProjectRoot
$TrackingFilePath = Join-Path -Path $ProjectRoot -ChildPath "doc/process-framework/state-tracking/temporary/foundational-validation-tracking.md"
$ReportsBasePath = Join-Path -Path $ProjectRoot -ChildPath "doc/process-framework/validation/reports"
$ValidationTypeMap = @{
    "Architectural" = "architectural-consistency"
    "CodeQuality"   = "code-quality"
    "Integration"   = "integration-dependencies"
    "Documentation" = "documentation-alignment"
    "Extensibility" = "extensibility-maintainability"
    "AIContinuity"  = "ai-agent-continuity"
}

# Parse parameters
$SelectedValidationTypes = $ValidationTypes -split "," | ForEach-Object { $_.Trim() }
$SelectedFeatures = if ($FeatureFilter) { $FeatureFilter -split "," | ForEach-Object { $_.Trim() } } else { @() }

Write-Host "🔄 Generating validation summary..." -ForegroundColor Cyan
Write-Host "   Output Path: $OutputPath" -ForegroundColor Gray
Write-Host "   Summary Type: $SummaryType" -ForegroundColor Gray
Write-Host "   Validation Types: $($SelectedValidationTypes -join ', ')" -ForegroundColor Gray
if ($SelectedFeatures.Count -gt 0) {
    Write-Host "   Feature Filter: $($SelectedFeatures -join ', ')" -ForegroundColor Gray
}

try {
    # Initialize summary data structure
    $SummaryData = @{
        GenerationDate  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ValidationTypes = @{}
        Features        = @{}
        OverallStats    = @{
            TotalReports         = 0
            CompletedValidations = 0
            CriticalIssues       = 0
            AverageScore         = 0.0
        }
        CriticalIssues  = @()
        Recommendations = @()
    }

    # Read tracking file to get overview
    if (Test-Path $TrackingFilePath) {
        $TrackingContent = Get-Content $TrackingFilePath -Raw
        Write-Host "   Reading validation tracking data..." -ForegroundColor Gray
    }
    else {
        Write-Warning "Validation tracking file not found: $TrackingFilePath"
    }

    # Collect data from validation reports
    $TotalScore = 0.0
    $ReportCount = 0

    foreach ($ValidationType in $SelectedValidationTypes) {
        if ($ValidationTypeMap.ContainsKey($ValidationType)) {
            $ReportsDir = Join-Path $ReportsBasePath $ValidationTypeMap[$ValidationType]

            if (Test-Path $ReportsDir) {
                $Reports = Get-ChildItem $ReportsDir -Filter "*.md" | Where-Object { $_.Name -match "^PF-VAL-\d+" }

                Write-Host "   Processing $($Reports.Count) reports for $ValidationType validation..." -ForegroundColor Gray

                $SummaryData.ValidationTypes[$ValidationType] = @{
                    ReportCount    = $Reports.Count
                    Reports        = @()
                    AverageScore   = 0.0
                    CriticalIssues = 0
                }

                foreach ($Report in $Reports) {
                    $ReportContent = Get-Content $Report.FullName -Raw

                    # Extract report metadata and scores (simplified parsing)
                    $ReportInfo = @{
                        FileName       = $Report.Name
                        Path           = $Report.FullName
                        Features       = @()
                        Score          = 0.0
                        CriticalIssues = 0
                    }

                    # Parse features from filename (PF-VAL-XXX-type-features-X.X.X-X.X.X.md)
                    if ($Report.Name -match "features-(.+)\.md$") {
                        $FeatureString = $Matches[1]
                        $ReportInfo.Features = $FeatureString -split "-" | Where-Object { $_ -match "^\d+\.\d+\.\d+$" }
                    }

                    # Extract overall score (simplified - would need more sophisticated parsing in real implementation)
                    if ($ReportContent -match "Overall Score:\s*(\d+\.?\d*)/4\.0") {
                        $ReportInfo.Score = [decimal]$Matches[1]
                        $TotalScore += $ReportInfo.Score
                        $ReportCount++
                    }

                    # Count critical issues (simplified parsing)
                    $CriticalMatches = [regex]::Matches($ReportContent, "Score:\s*1/4|Critical|Poor")
                    $ReportInfo.CriticalIssues = $CriticalMatches.Count
                    $SummaryData.ValidationTypes[$ValidationType].CriticalIssues += $ReportInfo.CriticalIssues

                    $SummaryData.ValidationTypes[$ValidationType].Reports += $ReportInfo
                }

                # Calculate average score for this validation type
                if ($SummaryData.ValidationTypes[$ValidationType].Reports.Count -gt 0) {
                    $TypeScores = $SummaryData.ValidationTypes[$ValidationType].Reports | Where-Object { $_.Score -gt 0 } | ForEach-Object { $_.Score }
                    if ($TypeScores.Count -gt 0) {
                        $SummaryData.ValidationTypes[$ValidationType].AverageScore = ($TypeScores | Measure-Object -Average).Average
                    }
                }
            }
        }
    }

    # Calculate overall statistics
    $SummaryData.OverallStats.TotalReports = $ReportCount
    $SummaryData.OverallStats.AverageScore = if ($ReportCount -gt 0) { $TotalScore / $ReportCount } else { 0.0 }
    $SummaryData.OverallStats.CriticalIssues = ($SummaryData.ValidationTypes.Values | ForEach-Object { $_.CriticalIssues } | Measure-Object -Sum).Sum

    # Generate summary content based on type
    $SummaryContent = @"
---
id: PF-VAL-SUMMARY-$(Get-Date -Format "yyyyMMdd")
type: Process Framework
category: Validation Summary
version: 1.0
created: $(Get-Date -Format "yyyy-MM-dd")
summary_type: $SummaryType
validation_types: $($SelectedValidationTypes -join ',')
---
# Foundational Codebase Validation Summary

## Executive Summary

**Generated**: $($SummaryData.GenerationDate)
**Summary Type**: $SummaryType
**Validation Scope**: $($SelectedValidationTypes -join ', ')

### Key Metrics
- **Total Validation Reports**: $($SummaryData.OverallStats.TotalReports)
- **Overall Foundation Score**: $($SummaryData.OverallStats.AverageScore.ToString("F2"))/4.0
- **Critical Issues**: $($SummaryData.OverallStats.CriticalIssues)
- **Foundation Status**: $(if ($SummaryData.OverallStats.AverageScore -ge 3.0) { "Production Ready" } elseif ($SummaryData.OverallStats.AverageScore -ge 2.5) { "Needs Targeted Improvements" } else { "Requires Significant Refactoring" })

### Quality Gate Assessment
$(if ($SummaryData.OverallStats.AverageScore -ge 3.0) {
"✅ **PASSED**: Foundation meets production readiness criteria"
} elseif ($SummaryData.OverallStats.AverageScore -ge 2.5) {
"⚠️ **CONDITIONAL**: Foundation functional but needs targeted improvements"
} else {
"❌ **FAILED**: Foundation requires significant refactoring before production use"
})

## Validation Type Breakdown

"@

    foreach ($ValidationType in $SelectedValidationTypes) {
        if ($SummaryData.ValidationTypes.ContainsKey($ValidationType)) {
            $TypeData = $SummaryData.ValidationTypes[$ValidationType]
            $SummaryContent += @"

### $ValidationType Validation
- **Reports Generated**: $($TypeData.ReportCount)
- **Average Score**: $($TypeData.AverageScore.ToString("F2"))/4.0
- **Critical Issues**: $($TypeData.CriticalIssues)
- **Status**: $(if ($TypeData.AverageScore -ge 3.0) { "Excellent" } elseif ($TypeData.AverageScore -ge 2.5) { "Good" } elseif ($TypeData.AverageScore -ge 2.0) { "Adequate" } else { "Needs Improvement" })

"@
        }
    }

    if ($IncludeDetails) {
        $SummaryContent += @"

## Detailed Findings

### Critical Issues Summary
$(if ($SummaryData.OverallStats.CriticalIssues -gt 0) {
"⚠️ **$($SummaryData.OverallStats.CriticalIssues) critical issues** require immediate attention across the foundational codebase."
} else {
"✅ **No critical issues** identified in the validated foundational features."
})

### Improvement Recommendations

#### High Priority Actions
1. **Address Critical Issues**: Focus on any features with scores of 1/4 (Poor)
2. **Standardize Patterns**: Ensure consistency across similar foundational features
3. **Documentation Updates**: Align implementation with design documentation

#### Medium Priority Actions
1. **Performance Optimization**: Review features scoring 2/4 (Adequate) for optimization opportunities
2. **Code Quality Enhancement**: Apply best practices to improve maintainability
3. **Testing Coverage**: Ensure comprehensive test coverage for all foundational features

#### Long-term Strategic Actions
1. **Architecture Evolution**: Plan for scalability and extensibility improvements
2. **AI Agent Optimization**: Enhance code structure for better AI agent workflow support
3. **Continuous Validation**: Establish regular validation cycles for ongoing quality assurance

"@
    }

    $SummaryContent += @"

## Next Steps

### Immediate Actions (Next 1-2 Sessions)
- Address any critical issues (score = 1) identified in validation reports
- Complete remaining validation types for comprehensive coverage
- Update foundational features with highest impact on system reliability

### Short-term Goals (Next 2-4 Weeks)
- Achieve overall foundation score ≥ 3.0 across all validation types
- Resolve all critical issues and reduce medium-priority issues by 50%
- Establish baseline validation metrics for future development

### Long-term Objectives (Next 1-3 Months)
- Maintain foundation score ≥ 3.5 through continuous improvement
- Implement automated validation checks in development workflow
- Create validation framework for new foundational features

## Related Resources

- [Foundational Validation Tracking](../state-tracking/temporary/foundational-validation-tracking.md) - Detailed validation progress
- [Foundational Validation Guide](../guides/guides/foundational-validation-guide.md) - Complete validation process guide
- [Validation Reports](reports/) - Individual validation reports by type

---

*This summary was automatically generated by Generate-ValidationSummary.ps1 on $($SummaryData.GenerationDate)*
"@

    # Write summary to file
    $SummaryContent | Set-Content $OutputPath -Encoding UTF8

    Write-Host "✅ Validation summary generated successfully!" -ForegroundColor Green
    Write-Host "   Summary file: $OutputPath" -ForegroundColor Gray
    Write-Host "   Reports analyzed: $($SummaryData.OverallStats.TotalReports)" -ForegroundColor Gray
    Write-Host "   Overall score: $($SummaryData.OverallStats.AverageScore.ToString("F2"))/4.0" -ForegroundColor Gray

    if ($SummaryData.OverallStats.CriticalIssues -gt 0) {
        Write-Host "   ⚠️ Critical issues: $($SummaryData.OverallStats.CriticalIssues)" -ForegroundColor Yellow
    }

    if ($OpenInEditor) {
        Write-Host "📝 Opening summary in editor..." -ForegroundColor Cyan
        Start-Process $OutputPath
    }

}
catch {
    Write-Error "Failed to generate validation summary: $($_.Exception.Message)"
    exit 1
}
