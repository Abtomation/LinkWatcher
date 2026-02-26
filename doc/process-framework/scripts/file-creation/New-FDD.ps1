# New-FDD.ps1
# Creates a new Functional Design Document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Functional Design Document (FDD) with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Functional Design Documents by:
    - Generating a unique document ID (PD-FDD-XXX)
    - Creating a properly formatted FDD document file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for functional specification
    - Automatically updating feature tracking with FDD completion status
    - Linking the FDD document in the feature tracking table

.PARAMETER FeatureId
    The Feature ID from feature tracking (e.g., "1.1.1", "2.3.4")

.PARAMETER FeatureName
    The name of the feature for which the FDD is being created

.PARAMETER Description
    Optional description of the feature's purpose and scope

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.PARAMETER DryRun
    If specified, shows what would be updated in feature tracking without making changes

.EXAMPLE
    .\New-FDD.ps1 -FeatureId "1.1.1" -FeatureName "User Registration"
    # Creates: fdd-1-1-1-user-registration.md

.EXAMPLE
    .\New-FDD.ps1 -FeatureId "2.3.4" -FeatureName "Room Filtering" -Description "Advanced filtering system for escape rooms" -OpenInEditor
    # Creates: fdd-2-3-4-room-filtering.md

.EXAMPLE
    .\New-FDD.ps1 -FeatureId "1.2.3" -FeatureName "Payment Processing" -Description "Stripe integration" -DryRun
    # Shows what would be updated in feature tracking without making changes

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Template Metadata:
    - Template ID: PF-TEM-020
    - Template Type: Document Creation Script
    - Created: 2025-08-01
    - For: Creating Functional Design Documents from templates
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureId,

    [Parameter(Mandatory=$true)]
    [string]$FeatureName,

    [Parameter(Mandatory=$false)]
    [string]$Description = "",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Import the common helpers with robust path resolution
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "../Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers module from: $modulePath"
    Write-Error "Please ensure the script is run from the correct directory or the module path is correct."
    exit 1
}

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_id" = $FeatureId
    "feature_name" = $FeatureName
}

# Prepare custom replacements for the template
$customReplacements = @{
    "[Feature ID]" = $FeatureId
    "[Feature Name]" = $FeatureName
    "[Feature Description]" = if ($Description -ne "") { $Description } else { "Functional specification for $FeatureName" }
    "[Date]" = Get-Date -Format "yyyy-MM-dd"
    "[Author]" = "AI Agent & Human Partner"
}

# Create the document using standardized process
try {
    # Use DirectoryType for ID registry-based directory resolution
    # Get the absolute path to the template using project root for reliability
    $templatePath = Join-Path (Get-ProjectRoot) "doc/process-framework/templates/templates/fdd-template.md"

    # Generate filename with feature ID prefix for better organization and traceability
    $featureIdForFilename = $FeatureId.Replace('.', '-')
    $featureNameForFilename = $FeatureName.ToLower().Replace(' ', '-').Replace('_', '-')
    $customFileName = "fdd-$featureIdForFilename-$featureNameForFilename.md"

    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PD-FDD" -IdDescription "fdd-$featureIdForFilename-$featureNameForFilename" -DocumentName $FeatureName -DirectoryType "fdds" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $customFileName -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Feature ID: $FeatureId",
        "Feature Name: $FeatureName"
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
            "   doc/process-framework/guides/guides/fdd-customization-guide.md",
            "🎯 FOCUS AREAS: 'Functional Requirements' and 'User Experience Flow' sections",
            "",
            "🎯 What the guide will teach you:",
            "   • How to define functional requirements with proper ID prefixes",
            "   • Creating user interaction flows and business rules",
            "   • Writing testable acceptance criteria",
            "   • Identifying edge cases and error handling scenarios",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content."
        )
    }

    Write-ProjectSuccess -Message "Created Functional Design Document with ID: $documentId" -Details $details

    # 🚀 AUTOMATION ENHANCEMENT: Update feature tracking with FDD completion
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
            Write-Host "  - Update Status: 📊 Assessment Created → 📋 FDD Created" -ForegroundColor Cyan
            Write-Host "  - Add FDD link to feature tracking" -ForegroundColor Cyan
        } else {
            # Prepare FDD document link
            $fddLink = "[$documentId](../../../product-docs/functional-design/fdds/$customFileName)"

            # Prepare additional updates for feature tracking
            $additionalUpdates = @{
                "FDD" = $fddLink
            }

            # Add notes about FDD creation
            $automationNotes = "FDD created: $documentId ($(Get-ProjectTimestamp -Format 'Date'))"

            if ($DryRun) {
                Write-Host "DRY RUN: Would update feature tracking for $FeatureId" -ForegroundColor Yellow
                Write-Host "  Status: 📊 Assessment Created → 📋 FDD Created" -ForegroundColor Cyan
                Write-Host "  FDD Link: $fddLink" -ForegroundColor Cyan
                Write-Host "  Notes: $automationNotes" -ForegroundColor Cyan
            } else {
                # Validate prerequisites - ensure assessment exists
                Write-Host "  🔍 Validating prerequisites..." -ForegroundColor Cyan

                # Update feature tracking with FDD completion
                $updateResult = Update-FeatureTrackingStatus -FeatureId $FeatureId -Status "📋 FDD Created" -AdditionalUpdates $additionalUpdates -Notes $automationNotes

                Write-Host "  ✅ Feature tracking updated successfully" -ForegroundColor Green
                Write-Host "  📋 Status: 📊 Assessment Created → 📋 FDD Created" -ForegroundColor Green
                Write-Host "  🔗 FDD linked in feature tracking" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Warning "Failed to update feature tracking automatically: $($_.Exception.Message)"
        Write-Host "Manual Update Required:" -ForegroundColor Yellow
        Write-Host "  - Update feature $FeatureId status to '📋 FDD Created'" -ForegroundColor Cyan
        Write-Host "  - Add FDD link: [$documentId](../../../product-docs/functional-design/fdds/$customFileName)" -ForegroundColor Cyan
    }
}
catch {
    Write-ProjectError -Message "Failed to create Functional Design Document: $($_.Exception.Message)" -ExitCode 1
}

<#
.NOTES
TESTING CHECKLIST:
Before considering this script complete, test the following:

1. ✅ Script creates FDD with proper ID assignment
2. ✅ Template replacements work correctly
3. ✅ Directory structure is created if missing
4. ✅ ID registry is updated properly
5. ✅ Error handling works for invalid inputs
6. ✅ OpenInEditor parameter functions correctly
7. ✅ Success messages provide helpful information
8. ✅ Feature ID and Name are properly integrated into filename and content
9. ✅ Generated filename includes feature ID (format: fdd-[feature-id]-[feature-name].md)

CUSTOMIZATION REQUIREMENTS:
- Ensure fdd-template.md exists in the templates directory
- Verify fdd-customization-guide.md exists for user guidance
- Test with various Feature ID formats (e.g., "1.1.1", "2.3.4")
- Validate filename generation includes feature ID (format: fdd-[feature-id]-[feature-name].md)
- Verify filename generation handles special characters in feature names correctly
#>
