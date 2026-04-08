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

.PARAMETER AverageScore
    Average quality score across all dimensions (0.0 - 3.0)

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-QualityAssessmentReport.ps1 -FeatureName "Customer-Management" -FeatureId "1.1.0" -Tier 2 -AverageScore 1.4

.EXAMPLE
    .\New-QualityAssessmentReport.ps1 -FeatureName "Invoice-Generator" -FeatureId "1.3.0" -Tier 3 -AverageScore 0.8 -OpenInEditor

.NOTES
    - Output directory: doc/pre-framework/quality-assessments/
    - ID prefix: PD-QAR (from PD-id-registry.json)
    - Only create for features classified as Target-State (average score < 2.0)

    Script Metadata:
    - Script Type: Document Creation Script
    - Created: 2026-04-05
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
    [double]$AverageScore,

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

# Warn if score >= 2.0 (should be Target-State only)
if ($AverageScore -ge 2.0) {
    Write-Host ""
    Write-Host "⚠️  Average score ($AverageScore) is >= 2.0 — this feature would normally be classified As-Built." -ForegroundColor Yellow
    Write-Host "    Quality Assessment Reports are typically only created for Target-State features (< 2.0)." -ForegroundColor Yellow
    Write-Host ""
}

# Resolve paths
$projectRoot = Get-ProjectRoot
$templatePath = Join-Path $projectRoot "process-framework/templates/00-setup/quality-assessment-report-template.md"

# Validate template exists
if (-not (Test-Path $templatePath)) {
    Write-ProjectError -Message "Quality Assessment Report template not found at: $templatePath" -ExitCode 1
}

# Sanitize feature name for filename (replace spaces with hyphens)
$sanitizedName = $FeatureName -replace '\s+', '-'
$fileNamePattern = "$FeatureId-$sanitizedName-quality-assessment.md"

# Prepare custom replacements
$today = Get-Date -Format "yyyy-MM-dd"
$customReplacements = @{
    "[Feature Name]"  = $FeatureName
    "[Feature ID]"    = $FeatureId
    "[Tier 1 / Tier 2 / Tier 3]" = "Tier $Tier"
    "[X.X]"           = $AverageScore.ToString("F1")
    "[YYYY-MM-DD]"    = $today
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_id"     = $FeatureId
    "feature_name"   = $FeatureName
    "tier"           = $Tier
    "average_score"  = $AverageScore.ToString("F1")
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
        "Average Score: $($AverageScore.ToString('F1')) / 3.0",
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
