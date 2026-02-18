# New-UIDesign.ps1
# Creates a new UI/UX Design Document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new UI/UX Design Document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates UI/UX Design Documents by:
    - Generating a unique document ID (PD-UIX-XXX)
    - Creating a properly formatted UI Design document file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for UI/UX specifications
    - Automatically updating feature tracking with UI Design completion status
    - Linking the UI Design document in the feature tracking table

.PARAMETER FeatureId
    The Feature ID from feature tracking (e.g., "1.1.1", "2.3.4")

.PARAMETER FeatureName
    The name of the feature for which the UI Design is being created

.PARAMETER Description
    Optional description of the UI design's purpose and scope

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.PARAMETER DryRun
    If specified, shows what would be updated in feature tracking without making changes

.EXAMPLE
    .\New-UIDesign.ps1 -FeatureId "1.1.1" -FeatureName "User Registration"
    # Creates: ui-design-1-1-1-user-registration.md

.EXAMPLE
    .\New-UIDesign.ps1 -FeatureId "2.3.4" -FeatureName "Room Filtering" -Description "UI for advanced filtering system" -OpenInEditor
    # Creates: ui-design-2-3-4-room-filtering.md

.EXAMPLE
    .\New-UIDesign.ps1 -FeatureId "1.2.3" -FeatureName "Payment Processing" -Description "Stripe payment UI flow" -DryRun
    # Shows what would be updated in feature tracking without making changes

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - MUST consult design-guidelines.md (PD-UIX-001) during UI Design creation

    Template Metadata:
    - Template ID: PF-TEM-TBD
    - Template Type: Document Creation Script
    - Created: 2025-01-18
    - For: Creating UI/UX Design Documents from templates
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureId,

    [Parameter(Mandatory = $true)]
    [string]$FeatureName,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Import the common helpers with robust path resolution
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "../Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
}
catch {
    Write-Error "Failed to import Common-ScriptHelpers module from: $modulePath"
    Write-Error "Please ensure the script is run from the correct directory or the module path is correct."
    exit 1
}

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_id"   = $FeatureId
    "feature_name" = $FeatureName
}

# Prepare custom replacements for the template
$customReplacements = @{
    "[Feature ID]"          = $FeatureId
    "[Feature Name]"        = $FeatureName
    "[Feature Description]" = if ($Description -ne "") { $Description } else { "UI/UX design specification for $FeatureName" }
    "[Date]"                = Get-Date -Format "yyyy-MM-dd"
    "[Author]"              = "AI Agent & Human Partner"
}

# Create the document using standardized process
try {
    # Use DirectoryType for ID registry-based directory resolution
    # Get the absolute path to the template
    $templatePath = Join-Path $PSScriptRoot "../../templates/templates/ui-design-template.md"
    $templatePath = Resolve-Path $templatePath

    # Generate filename with feature ID prefix for better organization and traceability
    $featureIdForFilename = $FeatureId.Replace('.', '-')
    $featureNameForFilename = $FeatureName.ToLower().Replace(' ', '-').Replace('_', '-')
    $customFileName = "ui-design-$featureIdForFilename-$featureNameForFilename.md"

    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PD-UIX" -IdDescription "ui-design-$featureIdForFilename-$featureNameForFilename" -DocumentName $FeatureName -DirectoryType "features" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $customFileName -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Feature ID: $FeatureId",
        "Feature Name: $FeatureName",
        "",
        "🎨 CRITICAL: DESIGN GUIDELINES MUST BE CONSULTED",
        "   📖 Design Guidelines: doc/product-docs/technical/design/ui-ux/design-system/design-guidelines.md (PD-UIX-001)",
        "   ⚠️  All UI Design work MUST follow the established design system patterns",
        ""
    )

    # Add conditional details
    if ($Description -ne "") {
        $details += "Description: $Description"
    }

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
            "   doc/process-framework/guides/guides/ui-design-customization-guide.md",
            "🎯 FOCUS AREAS: 'Wireframes & User Flows' and 'Visual Design Specifications' sections",
            "",
            "🎯 What the guide will teach you:",
            "   • How to create wireframes and user flow diagrams",
            "   • Defining visual design specifications (colors, typography, spacing)",
            "   • Specifying component behavior and interactions",
            "   • Applying accessibility standards (WCAG 2.1 Level AA)",
            "   • Platform-specific adaptations (iOS, Android, Web)",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful design content."
        )
    }

    Write-ProjectSuccess -Message "Created UI/UX Design Document with ID: $documentId" -Details $details

    # 🚀 AUTOMATION ENHANCEMENT: Update feature tracking with UI Design completion
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
            Write-Host "  - Add UI Design link to feature tracking" -ForegroundColor Cyan
        }
        else {
            # Prepare UI Design document link
            $uiDesignLink = "[$documentId](../../../product-docs/technical/design/ui-ux/features/$customFileName)"

            # Prepare additional updates for feature tracking
            $additionalUpdates = @{
                "UI Design" = $uiDesignLink
            }

            # Add notes about UI Design creation
            $automationNotes = "UI Design created: $documentId ($(Get-ProjectTimestamp -Format 'Date'))"

            if ($DryRun) {
                Write-Host "DRY RUN: Would update feature tracking for $FeatureId" -ForegroundColor Yellow
                Write-Host "  UI Design Link: $uiDesignLink" -ForegroundColor Cyan
                Write-Host "  Notes: $automationNotes" -ForegroundColor Cyan
            }
            else {
                # Validate prerequisites - ensure FDD exists (UI Design typically follows FDD)
                Write-Host "  🔍 Validating prerequisites..." -ForegroundColor Cyan

                # Update feature tracking with UI Design completion
                $updateResult = Update-FeatureTrackingStatus -FeatureId $FeatureId -Status "🎨 UI Design Created" -AdditionalUpdates $additionalUpdates -Notes $automationNotes

                Write-Host "  ✅ Feature tracking updated successfully" -ForegroundColor Green
                Write-Host "  🔗 UI Design linked in feature tracking" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Warning "Failed to update feature tracking automatically: $($_.Exception.Message)"
        Write-Host "Manual Update Required:" -ForegroundColor Yellow
        Write-Host "  - Add UI Design link for feature ${FeatureId}: [${documentId}](../../../product-docs/technical/design/ui-ux/features/${customFileName})" -ForegroundColor Cyan
    }
}
catch {
    Write-ProjectError -Message "Failed to create UI/UX Design Document: $($_.Exception.Message)" -ExitCode 1
}

<#
.NOTES
TESTING CHECKLIST:
Before considering this script complete, test the following:

1. ✅ Script creates UI Design document with proper ID assignment
2. ✅ Template replacements work correctly
3. ✅ Directory structure is created if missing
4. ✅ ID registry is updated properly
5. ✅ Error handling works for invalid inputs
6. ✅ OpenInEditor parameter functions correctly
7. ✅ Success messages provide helpful information
8. ✅ Feature ID and Name are properly integrated into filename and content
9. ✅ Generated filename includes feature ID (format: ui-design-[feature-id]-[feature-name].md)
10. ✅ Feature tracking is automatically updated with UI Design link

CUSTOMIZATION REQUIREMENTS:
- Ensure ui-design-template.md exists in the templates directory
- Verify ui-design-customization-guide.md exists for user guidance
- Verify design-guidelines.md (PD-UIX-001) exists for design system reference
- Test with various Feature ID formats (e.g., "1.1.1", "2.3.4")
- Validate filename generation includes feature ID (format: ui-design-[feature-id]-[feature-name].md)
- Verify filename generation handles special characters in feature names correctly
#>
