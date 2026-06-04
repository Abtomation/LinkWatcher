# New-QualityAssessmentReport.ps1
# Creates a new Quality Assessment Report for a Target-State feature during onboarding
# Used in PF-TSK-066 (Retrospective Documentation Creation) for features classified as Target-State

<#
.SYNOPSIS
    Creates a new Quality Assessment Report for a Target-State feature.

.DESCRIPTION
    This PowerShell script generates a Quality Assessment Report by:
    - Generating a unique document ID (PD-QAR-XXX) automatically
    - Filling in the feature name, ID, and assessment date
    - Placing the file at doc/pre-framework/quality-assessments/
    - Updating the ID tracker in the PD ID registry

    Quality Assessment Reports are created for features classified as Target-State
    during the onboarding quality evaluation (PF-TSK-065). They provide the big-picture
    view linking dimension scores to tech debt items with a remediation sequence.

.PARAMETER FeatureName
    Name of the feature being assessed

.PARAMETER FeatureId
    Feature ID (e.g., "1.2.3" or "0.1.1")

.PARAMETER Tier
    Feature tier (1, 2, or 3)

.PARAMETER CodeMaturity
    Code maturity score (0.0 - 3.0) — average of Structural clarity, Error handling, Data integrity, Maintainability.
    Drives the Target-State classification (< 2.0 = Target-State).

.PARAMETER TestMaturity
    Test maturity score (0 - 3) — test coverage alone. Reported separately; does not affect classification.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-QualityAssessmentReport.ps1 -FeatureName "Customer-Management" -FeatureId "1.1.0" -Tier 2 -CodeMaturity 1.4 -TestMaturity 1

.EXAMPLE
    .\New-QualityAssessmentReport.ps1 -FeatureName "Invoice-Generator" -FeatureId "1.3.0" -Tier 3 -CodeMaturity 0.8 -TestMaturity 0 -OpenInEditor

.NOTES
    - Output directory: doc/pre-framework/quality-assessments/
    - ID prefix: PD-QAR (from PD-id-registry.json)
    - Only create for features classified as Target-State (Code Maturity < 2.0)
    - Dual-score model (PF-IMP-019/032, 2026-05-08): Code Maturity drives the
      classification; Test Maturity is reported separately and does not affect
      it.

    Script Metadata:
    - Script Type: Document Creation Script
    - Created: 2026-04-05
    - Updated: 2026-05-08 (dual-score: -CodeMaturity / -TestMaturity replace -AverageScore)
    - For: Creating Quality Assessment Reports during onboarding (PF-TSK-066)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureName,

    [Parameter(Mandatory = $true)]
    [string]$FeatureId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("1", "2", "3")]
    [string]$Tier,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0.0, 3.0)]
    [double]$CodeMaturity,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 3)]
    [int]$TestMaturity,

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
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


# Soak verification opt-in (PF-PRO-028 v2.0 Pattern B; helper-routed armoring via DocumentManagement.psm1).
# Caller-aware no-arg form: helper resolves this script's path via Get-PSCallStack.
# Idempotent — silently no-ops if already registered.
Register-SoakScript

# Warn if Code Maturity >= 2.0 (Target-State QARs are only for Code Maturity < 2.0; Test Maturity does not gate this)
if ($CodeMaturity -ge 2.0) {
    Write-Host ""
    Write-Host "⚠️  Code Maturity ($CodeMaturity) is >= 2.0 — this feature would normally be classified As-Built." -ForegroundColor Yellow
    Write-Host "    Quality Assessment Reports are only created for Target-State features (Code Maturity < 2.0)." -ForegroundColor Yellow
    Write-Host "    A low Test Maturity score alone does not warrant a QAR — that's a test-plan concern handled separately." -ForegroundColor Yellow
    Write-Host ""
}

# Resolve paths
$templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/00-setup/quality-assessment-report-template.md"

# Validate template exists
if (-not (Test-Path $templatePath)) {
    Write-ProjectError -Message "Quality Assessment Report template not found at: $templatePath" -ExitCode 1
}

# Sanitize feature name via the canonical helper (PF-IMP-008). PreserveCase
# keeps the Title-Case convention of existing 0.X-Feature-Name-quality-assessment.md
# files; FeatureId is concatenated separately so its dots are preserved.
$sanitizedName = ConvertTo-FeatureSlug -Name $FeatureName -Convention 'kebab-case' -PreserveCase
$fileNamePattern = "$FeatureId-$sanitizedName-quality-assessment.md"

# Build Tier 1 disclaimer paragraph (PF-IMP-831, PF-IMP-799).
# Tier 1 features have no FDD/TDD/Test Spec/ADR — design intent lives in the
# Feature Implementation State file (PD-FIS) §6 "Design Decisions". Pre-filling
# this disclaimer avoids the manual paragraph that PF-TSK-066 sessions added to
# every Tier 1 QAR.
if ($Tier -eq "1") {
    $tier1Disclaimer = "> **Tier 1 feature**: No FDD, TDD, Test Specification, or ADR exists for this feature. Design intent is documented in the Feature Implementation State file (PD-FIS) §6 ""Design Decisions"". Gap analysis below references the state file rather than external design documents."
} else {
    $tier1Disclaimer = ""
}

# Prepare custom replacements
$today = Get-Date -Format "yyyy-MM-dd"
$customReplacements = @{
    "[Feature Name]"     = $FeatureName
    "[Feature ID]"       = $FeatureId
    "[Tier 1 / Tier 2 / Tier 3]" = "Tier $Tier"
    "[CODE_MATURITY]"    = $CodeMaturity.ToString("F1")
    "[TEST_MATURITY]"    = $TestMaturity.ToString()
    "[TIER_1_DISCLAIMER]" = $tier1Disclaimer
    "[YYYY-MM-DD]"       = $today
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_id"     = $FeatureId
    "feature_name"   = $FeatureName
    "tier"           = $Tier
    "code_maturity"  = $CodeMaturity.ToString("F1")
    "test_maturity"  = $TestMaturity.ToString()
    "classification" = "Target-State"
}

# Create the document using standardized process
try {
    $documentId = New-StandardProjectDocument `
        -TemplatePath $templatePath `
        -IdPrefix "PD-QAR" `
        -IdDescription "Quality Assessment Report for $FeatureName ($FeatureId)" `
        -DocumentName $sanitizedName `
        -DirectoryType "quality-assessments" `
        -FileNamePattern $fileNamePattern `
        -Replacements $customReplacements `
        -AdditionalMetadataFields $additionalMetadataFields `
        -OpenInEditor:$OpenInEditor

    $details = @(
        "Feature: $FeatureName ($FeatureId)",
        "Tier: $Tier",
        "Code Maturity: $($CodeMaturity.ToString('F1')) / 3.0",
        "Test Maturity: $TestMaturity / 3.0",
        "Classification: Target-State",
        "",
        "📋 NEXT STEPS:",
        "1. Fill in dimension scores with specific evidence (Section 2)",
        "2. Write overall quality assessment narrative (Section 3)",
        "3. Complete gap analysis linking to tech debt items (Section 4)",
        "4. Define remediation sequence by priority (Section 5)",
        "5. Add links to FDD/TDD and tech debt items (Section 6)",
        "",
        "📖 RELATED TASK:",
        "process-framework/tasks/00-setup/retrospective-documentation-creation.md"
    )

    Write-ProjectSuccess -Message "Created Quality Assessment Report with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Quality Assessment Report: $($_.Exception.Message)" -ExitCode 1
}
