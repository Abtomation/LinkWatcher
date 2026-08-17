# ../New-Assessment.ps1
# Creates a new documentation tier assessment file for a feature
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new documentation tier assessment file for a feature.

.DESCRIPTION
    This script automates the creation of documentation tier assessment files by:
    - Generating a unique assessment ID (PD-ASS-XXX)
    - Creating a properly formatted assessment file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for complexity assessment

.PARAMETER FeatureId
    The feature ID in format X.X.X (e.g., 1.2.3)

.PARAMETER FeatureName
    The human-readable name of the feature

.PARAMETER FeatureDescription
    A brief description of what the feature does

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    ../New-Assessment.ps1 -FeatureId "2.1.5" -FeatureName "User Authentication" -FeatureDescription "Implement OAuth2 login system"

.EXAMPLE
    ../New-Assessment.ps1 -FeatureId "1.3.2" -FeatureName "Data Export" -FeatureDescription "Export user data to CSV" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the assessments subdirectory if it doesn't exist
    - Does not touch feature-tracking.md: status, tier emoji, and assessment link are
      written by Update-FeatureTrackingFromAssessment.ps1 after the assessment is filled in
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureId,

    [Parameter(Mandatory=$true)]
    [string]$FeatureName,

    [Parameter(Mandatory=$true)]
    [string]$FeatureDescription,

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Init, soak opt-in, the New-StandardProjectDocument call, and the create-failure error path
# are owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This Tier-3 script
# keeps its data, its bespoke post-creation write (ID-stamped file rename), and its own
# report — all inline under the outer try/catch.

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_id" = $FeatureId
    description  = "Documentation tier assessment for $FeatureName ($FeatureId)"
}

# Prepare custom replacements
$customReplacements = @{
    "# Documentation Tier Assessment: [Feature Name]" = "# Documentation Tier Assessment: $FeatureName"
    "[Brief description of the feature]" = $FeatureDescription
}

# Create the document using standardized process
try {
    $assessmentId = New-FrameworkDocument -TemplatePath (Join-Path (Get-ProcessFrameworkPath) "templates/01-planning/assessment-template.md") -IdPrefix "PD-ASS" -IdDescription "Assessment for feature ${FeatureId}: ${FeatureName}" -DocumentName $FeatureName -OutputDirectory "doc/documentation-tiers/assessments" -Replacements $customReplacements -Metadata $additionalMetadataFields -Label "assessment" -OpenInEditor:$OpenInEditor

    # Rename the file to include the ID and feature ID in the filename
    $assessmentsDir = Join-Path -Path (Get-ProjectRoot) -ChildPath "doc/documentation-tiers/assessments"
    $kebabFeatureName = ConvertTo-KebabCase -InputString $FeatureName
    $oldFileName = "$kebabFeatureName.md"
    $newFileName = "$assessmentId-$FeatureId-$kebabFeatureName.md"
    $oldPath = Join-Path -Path $assessmentsDir -ChildPath $oldFileName
    $newPath = Join-Path -Path $assessmentsDir -ChildPath $newFileName

    if (Test-Path $oldPath) {
        Move-Item -Path $oldPath -Destination $newPath
        Write-Host "✅ Renamed assessment file to include ID: $newFileName" -ForegroundColor Green
    }

    $details = @(
        "Feature: $FeatureName ($FeatureId)"
    )

    # Add next steps if not opening in editor
    if (-not $OpenInEditor) {
        $details += "Customization required — apply the feature-request-evaluation craft skill (.claude/skills/feature-request-evaluation/references/tier-assessment.md)"
    }

    # Feature tracking is deliberately untouched here: status, tier emoji, and the
    # assessment link are all written by Update-FeatureTrackingFromAssessment.ps1,
    # which the task flow runs after the assessment is filled in (PF-IMP-1392)
    $details += "Next: run Update-FeatureTrackingFromAssessment.ps1 after filling in the assessment to set status, tier, and assessment link"

    Write-ProjectSuccess -Message "Created assessment with ID: $assessmentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create assessment: $($_.Exception.Message)" -ExitCode 1
}
