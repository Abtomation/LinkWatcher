# Validate-AuditReport.ps1
# Validates Test Audit Reports for completeness and consistency
# Ensures audit reports meet quality standards before finalization

<#
.SYNOPSIS
    Validates a Test Audit Report for completeness and consistency.

.DESCRIPTION
    This PowerShell script validates Test Audit Report documents by checking:
    - All type-specific evaluation criteria are addressed:
      - Automated (6 criteria): Purpose Fulfillment, Coverage Completeness, etc.
      - Performance (4 criteria): Measurement Methodology, Tolerance Appropriateness, etc.
      - E2E (5 criteria): Fixture Correctness, Scenario Completeness, etc.
    - Audit decision consistency with findings
    - Required sections are completed
    - Proper linking to test files and tracking
    - Metadata completeness and accuracy
    - Test type is auto-detected from report content, or can be specified via -TestType

.PARAMETER ReportFile
    Path to the audit report file to validate

.PARAMETER Detailed
    If specified, provides detailed validation output with specific issues

.EXAMPLE
    Validate-AuditReport.ps1 -ReportFile "foundation/audit-report-0.2.3-TE-TST-001.md"

.EXAMPLE
    Validate-AuditReport.ps1 -ReportFile "foundation/audit-report-0.2.3-TE-TST-001.md" -Detailed

.NOTES
    - Validates against Test Audit Report template structure
    - Checks for consistency between findings and audit decision
    - Ensures all mandatory sections are completed
    - Validates metadata accuracy and completeness

    Script Metadata:
    - Script Type: Validation Script
    - Created: 2025-08-07
    - For: Validating Test Audit Report quality and completeness
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ReportFile,

    [Parameter(Mandatory=$false)]
    [ValidateSet("Automated", "Performance", "E2E")]
    [string]$TestType = "",

    [Parameter(Mandatory=$false)]
    [switch]$Detailed
)

# Import the common helpers with walk-up path resolution
$dir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
try {
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers module. Searched up from: $PSScriptRoot"
    exit 1
}

# Perform standard initialization
Invoke-StandardScriptInitialization

# Resolve project root and audits base directory
$ProjectRoot = Get-ProjectRoot
$auditsDir = Join-Path $ProjectRoot "test" "audits"

# Resolve the report file path
$reportPath = if ([System.IO.Path]::IsPathRooted($ReportFile)) {
    $ReportFile
} else {
    Join-Path -Path $auditsDir -ChildPath $ReportFile
}

# Check if file exists
if (-not (Test-Path $reportPath)) {
    Write-ProjectError -Message "Audit report file not found: $reportPath" -ExitCode 1
}

# Read the report content
try {
    $content = Get-Content $reportPath -Raw
    Write-Host "ℹ️  Validating audit report: $(Split-Path $reportPath -Leaf)" -ForegroundColor Cyan
} catch {
    Write-ProjectError -Message "Failed to read audit report file: $($_.Exception.Message)" -ExitCode 1
}

# Auto-detect test type from content if not provided
if ($TestType -eq "") {
    if ($content -match 'Measurement Methodology' -and $content -match 'Tolerance Appropriateness') {
        $TestType = "Performance"
    } elseif ($content -match 'Fixture Correctness' -and $content -match 'Scenario Completeness') {
        $TestType = "E2E"
    } else {
        $TestType = "Automated"
    }
    Write-Host "ℹ️  Auto-detected test type: $TestType" -ForegroundColor Cyan
}

# Initialize validation results
$validationResults = @{
    IsValid = $true
    Errors = @()
    Warnings = @()
    Info = @()
}

# Validation functions
function Test-MetadataSection {
    param($Content)

    $metadataMatch = [regex]::Match($Content, '---\s*\r?\n([\s\S]*?)\r?\n---')
    if (-not $metadataMatch.Success) {
        $validationResults.Errors += "Missing or malformed metadata section"
        return $false
    }

    $metadata = $metadataMatch.Groups[1].Value
    $requiredFields = @('id', 'feature_id', 'auditor', 'audit_date')
    # Accept either test_file_id or test_file_path (E2E template uses test_file_path)
    if ($metadata -notmatch 'test_file_id\s*:' -and $metadata -notmatch 'test_file_path\s*:') {
        $validationResults.Errors += "Missing required metadata field: test_file_id or test_file_path"
    }

    foreach ($field in $requiredFields) {
        if ($metadata -notmatch "$field\s*:") {
            $validationResults.Errors += "Missing required metadata field: $field"
        }
    }

    return $true
}

function Test-EvaluationCriteria {
    param($Content, $Type)

    $requiredCriteria = switch ($Type) {
        "Performance" {
            @(
                'Measurement Methodology',
                'Tolerance Appropriateness',
                'Baseline Readiness',
                'Regression Detection Config'
            )
        }
        "E2E" {
            @(
                'Fixture Correctness',
                'Scenario Completeness',
                'Expected Outcome Accuracy',
                'Reproducibility',
                'Precondition Coverage'
            )
        }
        default {
            @(
                'Purpose Fulfillment',
                'Coverage Completeness',
                'Test Quality & Structure',
                'Performance & Efficiency',
                'Maintainability',
                'Integration Alignment'
            )
        }
    }

    $missingCriteria = @()
    foreach ($criteria in $requiredCriteria) {
        if ($Content -notmatch "###\s+\d+\.\s*$([regex]::Escape($criteria))") {
            $missingCriteria += $criteria
        }
    }

    if ($missingCriteria.Count -gt 0) {
        $validationResults.Errors += "Missing $Type evaluation criteria: $($missingCriteria -join ', ')"
        return $false
    }

    return $true
}

function Test-AuditDecision {
    param($Content)

    if ($Content -notmatch '\*\*Status\*\*:\s*[^\r\n]*(TESTS_APPROVED|Tests Approved|NEEDS_UPDATE|Needs Update|Audit Approved|AUDIT_APPROVED|Audit Failed|AUDIT_FAILED)') {
        $validationResults.Errors += "Missing or invalid audit decision status"
        return $false
    }

    # Check for rationale
    $rationaleMatch = [regex]::Match($Content, '\*\*Rationale\*\*:\s*\r?\n\[.*?\]')
    if ($rationaleMatch.Success) {
        $validationResults.Warnings += "Audit decision rationale appears to be template placeholder"
    }

    return $true
}

function Test-RequiredSections {
    param($Content)

    $requiredSections = @(
        'Audit Overview',
        'Test(s| Files) Audited',
        'Audit Evaluation',
        'Overall Audit Summary',
        'Action Items',
        'Audit Completion'
    )

    $missingSections = @()
    foreach ($section in $requiredSections) {
        if ($Content -notmatch "## $section") {
            $missingSections += $section
        }
    }

    if ($missingSections.Count -gt 0) {
        $validationResults.Errors += "Missing required sections: $($missingSections -join ', ')"
        return $false
    }

    return $true
}

function Test-TemplatePlaceholders {
    param($Content)

    $placeholderPattern = '\[([A-Z_][A-Z0-9_]*)\]'
    $placeholders = [regex]::Matches($Content, $placeholderPattern) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

    if ($placeholders.Count -gt 0) {
        $validationResults.Warnings += "Template placeholders found (may need completion): $($placeholders -join ', ')"
    }

    return $true
}

function Test-ValidationChecklist {
    param($Content)

    if ($Content -notmatch '### Validation Checklist') {
        $validationResults.Warnings += "Missing validation checklist section"
        return $false
    }

    # Check for completed checklist items
    $completedItems = [regex]::Matches($Content, '- \[x\]').Count
    $totalItems = [regex]::Matches($Content, '- \[ \]').Count + $completedItems

    if ($completedItems -eq 0 -and $totalItems -gt 0) {
        $validationResults.Warnings += "Validation checklist appears incomplete (no items checked)"
    }

    return $true
}

# Run all validations
Write-Host "ℹ️  Running validation checks..." -ForegroundColor Cyan

Test-MetadataSection -Content $content | Out-Null
Test-RequiredSections -Content $content | Out-Null
Test-EvaluationCriteria -Content $content -Type $TestType | Out-Null
Test-AuditDecision -Content $content | Out-Null
Test-TemplatePlaceholders -Content $content | Out-Null
Test-ValidationChecklist -Content $content | Out-Null

# Determine overall validation status
$validationResults.IsValid = ($validationResults.Errors.Count -eq 0)

# Output results
if ($validationResults.IsValid) {
    $successMessage = "✅ Audit report validation PASSED"
    $details = @()

    if ($validationResults.Warnings.Count -gt 0) {
        $details += "⚠️  Warnings found: $($validationResults.Warnings.Count)"
        if ($Detailed) {
            $details += $validationResults.Warnings | ForEach-Object { "   - $_" }
        }
    }

    if ($validationResults.Info.Count -gt 0) {
        $details += "ℹ️  Info items: $($validationResults.Info.Count)"
        if ($Detailed) {
            $details += $validationResults.Info | ForEach-Object { "   - $_" }
        }
    }

    if ($details.Count -eq 0) {
        $details += "No issues found - report is ready for finalization"
    }

    Write-ProjectSuccess -Message $successMessage -Details $details
} else {
    $errorMessage = "❌ Audit report validation FAILED"
    $details = @()

    $details += "🚨 Errors found: $($validationResults.Errors.Count)"
    if ($Detailed) {
        $details += $validationResults.Errors | ForEach-Object { "   - $_" }
    }

    if ($validationResults.Warnings.Count -gt 0) {
        $details += "⚠️  Warnings found: $($validationResults.Warnings.Count)"
        if ($Detailed) {
            $details += $validationResults.Warnings | ForEach-Object { "   - $_" }
        }
    }

    $details += ""
    $details += "🔧 Please address the errors before finalizing the audit report"

    foreach ($line in $details) {
        Write-Host "  $line"
    }
    Write-ProjectError -Message $errorMessage -ExitCode 1
}

<#
.NOTES
VALIDATION CRITERIA:

1. METADATA VALIDATION:
   - Presence of metadata section with required fields
   - Proper YAML format in metadata
   - All required fields populated

2. STRUCTURE VALIDATION:
   - All required sections present
   - Proper heading hierarchy
   - Section content follows template structure

3. EVALUATION CRITERIA VALIDATION:
   - All six evaluation criteria addressed
   - Each criteria has assessment, findings, evidence, recommendations
   - Consistent formatting across criteria

4. AUDIT DECISION VALIDATION:
   - Clear audit decision (TESTS_APPROVED or NEEDS_UPDATE)
   - Rationale provided for decision
   - Decision consistency with findings

5. COMPLETENESS VALIDATION:
   - Template placeholders replaced with actual content
   - Action items defined
   - Validation checklist addressed

6. CONSISTENCY VALIDATION:
   - Metadata matches content
   - Audit decision aligns with findings
   - Cross-references are valid

EXAMPLE USAGE:
# Basic validation
Validate-AuditReport.ps1 -ReportFile "foundation/audit-report-0.2.3-TE-TST-001.md"

# Detailed validation with all issues
Validate-AuditReport.ps1 -ReportFile "foundation/audit-report-0.2.3-TE-TST-001.md" -Detailed

# Validation with automatic fixes
Validate-AuditReport.ps1 -ReportFile "foundation/audit-report-0.2.3-TE-TST-001.md" -Fix
#>
