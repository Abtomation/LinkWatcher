# New-Assessment.ps1
# Creates a new documentation tier assessment file for a feature
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new documentation tier assessment file for a feature.

.DESCRIPTION
    This script automates the creation of documentation tier assessment files by:
    - Generating a unique assessment ID (ART-ASS-XXX)
    - Creating a properly formatted assessment file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for complexity assessment
    - Automatically updating feature tracking with assessment completion status
    - Linking the assessment document in the feature tracking table

.PARAMETER FeatureId
    The feature ID in format X.X.X (e.g., 1.2.3)

.PARAMETER FeatureName
    The human-readable name of the feature

.PARAMETER FeatureDescription
    A brief description of what the feature does

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.PARAMETER DryRun
    If specified, shows what would be updated in feature tracking without making changes

.EXAMPLE
    .\New-Assessment.ps1 -FeatureId "2.1.5" -FeatureName "User Authentication" -FeatureDescription "Implement OAuth2 login system"

.EXAMPLE
    .\New-Assessment.ps1 -FeatureId "1.3.2" -FeatureName "Data Export" -FeatureDescription "Export user data to CSV" -OpenInEditor

.EXAMPLE
    .\New-Assessment.ps1 -FeatureId "1.4.1" -FeatureName "Payment Processing" -FeatureDescription "Stripe integration for payments" -DryRun

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the assessments subdirectory if it doesn't exist
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
    [switch]$OpenInEditor,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_id" = $FeatureId
}

# Prepare custom replacements
$customReplacements = @{
    "# Documentation Tier Assessment: [Feature Name]" = "# Documentation Tier Assessment: $FeatureName"
    "[Brief description of the feature]" = $FeatureDescription
}

# Create the document using standardized process
try {
    $assessmentId = New-StandardProjectDocument -TemplatePath "doc/process-framework/templates/templates/assessment-template.md" -IdPrefix "ART-ASS" -IdDescription "Assessment for feature ${FeatureId}: ${FeatureName}" -DocumentName $FeatureName -OutputDirectory "doc/process-framework/methodologies/documentation-tiers/assessments" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Rename the file to include the ID and feature ID in the filename
    $assessmentsDir = Join-Path -Path (Get-ProjectRoot) -ChildPath "doc/process-framework/methodologies/documentation-tiers/assessments"
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
        $details += @(
            "",
            "🚨🚨🚨 CRITICAL: TEMPLATE CREATED - EXTENSIVE CUSTOMIZATION REQUIRED 🚨🚨🚨",
            "",
            "⚠️  IMPORTANT: This script creates ONLY a structural template/framework.",
            "⚠️  The generated file is NOT a functional document until extensively customized.",
            "⚠️  AI agents MUST follow the referenced guide to properly customize the content.",
            "",
            "📖 MANDATORY CUSTOMIZATION GUIDE:",
            "   doc/process-framework/guides/guides/assessment-guide.md",
            "🎯 FOCUS AREAS: 'Documentation Tier Assessment Process' section",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content."
        )
    }

    Write-ProjectSuccess -Message "Created assessment with ID: $assessmentId" -Details $details

    # 🚀 AUTOMATION ENHANCEMENT: Update feature tracking with assessment completion
    Write-Host ""
    Write-Host "🤖 Updating Feature Tracking..." -ForegroundColor Yellow

    try {
        # Validate dependencies for automation
        $dependencyCheck = Test-ScriptDependencies -RequiredFunctions @(
            "Update-FeatureTrackingStatus"
        )

        if (-not $dependencyCheck.AllDependenciesMet) {
            Write-Warning "Automation dependencies not available. Feature tracking must be updated manually."
            Write-Host "Manual Update Required:" -ForegroundColor Yellow
            Write-Host "  - Update Status: ⬜ Not Started → 📊 Assessment Created" -ForegroundColor Cyan
            Write-Host "  - Add assessment link to feature tracking" -ForegroundColor Cyan
        } else {
            # Prepare assessment document link
            $assessmentLink = "[$assessmentId](../../../process-framework/methodologies/documentation-tiers/assessments/$newFileName)"

            # Prepare additional updates for feature tracking
            $additionalUpdates = @{
                "Assessment" = $assessmentLink
            }

            # Add notes about assessment creation
            $automationNotes = "Assessment created: $assessmentId ($(Get-ProjectTimestamp -Format 'Date'))"

            if ($DryRun) {
                Write-Host "DRY RUN: Would update feature tracking for $FeatureId" -ForegroundColor Yellow
                Write-Host "  Status: ⬜ Not Started → 📊 Assessment Created" -ForegroundColor Cyan
                Write-Host "  Assessment Link: $assessmentLink" -ForegroundColor Cyan
                Write-Host "  Notes: $automationNotes" -ForegroundColor Cyan
            } else {
                # Update feature tracking with assessment completion
                $updateResult = Update-FeatureTrackingStatus -FeatureId $FeatureId -Status "📊 Assessment Created" -AdditionalUpdates $additionalUpdates -Notes $automationNotes

                Write-Host "  ✅ Feature tracking updated successfully" -ForegroundColor Green
                Write-Host "  📊 Status: ⬜ Not Started → 📊 Assessment Created" -ForegroundColor Green
                Write-Host "  🔗 Assessment linked in feature tracking" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Warning "Failed to update feature tracking automatically: $($_.Exception.Message)"
        Write-Host "Manual Update Required:" -ForegroundColor Yellow
        Write-Host "  - Update feature $FeatureId status to '📊 Assessment Created'" -ForegroundColor Cyan
        Write-Host "  - Add assessment link: [$assessmentId](../../../process-framework/methodologies/documentation-tiers/assessments/$newFileName)" -ForegroundColor Cyan
    }
}
catch {
    Write-ProjectError -Message "Failed to create assessment: $($_.Exception.Message)" -ExitCode 1
}
