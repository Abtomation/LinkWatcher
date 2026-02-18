# New-SchemaDesign.ps1
# Creates a new Database Schema Design document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Database Schema Design document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Database Schema Design documents by:
    - Generating a unique document ID (PD-SCH-XXX)
    - Creating a properly formatted schema design document file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for database schema design and planning
    - Automatically updating DB Design column in feature tracking from "Yes" to schema design link (when FeatureId provided)

.PARAMETER FeatureName
    The name of the feature requiring schema changes

.PARAMETER SchemaType
    The type of schema change (New, Modification, Optimization)

.PARAMETER Description
    Optional description of the schema changes needed

.PARAMETER FeatureId
    Optional feature ID to link this schema design to for automatic state updates

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.PARAMETER DryRun
    If specified, shows what would be updated without making changes

.EXAMPLE
    ../../../product-docs/technical/database/New-SchemaDesign.ps1 -FeatureName "User Authentication" -SchemaType "New"

.EXAMPLE
    ../../../product-docs/technical/database/New-SchemaDesign.ps1 -FeatureName "User Profile Enhancement" -SchemaType "Modification" -Description "Add new fields for user preferences" -OpenInEditor

.EXAMPLE
    ../../../product-docs/technical/database/New-SchemaDesign.ps1 -FeatureName "Booking Fee Calculation" -SchemaType "New" -Description "Schema for booking fee calculations" -FeatureId "5.1.1"

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - When FeatureId is provided, automatically updates DB Design column in feature tracking from "Yes" to schema design link
    - Integrates with Process Framework automation infrastructure

    Template Metadata:
    - Template ID: PF-TEM-020
    - Template Type: Document Creation Script
    - Created: 2025-07-08
    - For: Creating PowerShell scripts that generate documents from templates
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("New", "Modification", "Optimization")]
    [string]$SchemaType,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [string]$FeatureId = "",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Import the common helpers
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "..\Common-ScriptHelpers.psm1"
$resolvedPath = Resolve-Path $modulePath
Import-Module $resolvedPath -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields (customize as needed)
$additionalMetadataFields = @{
    "feature_name" = ConvertTo-KebabCase -InputString $FeatureName
    "schema_type"  = $SchemaType.ToLower()
}

# Add feature ID if provided
if ($FeatureId -ne "") {
    $additionalMetadataFields["feature_id"] = $FeatureId
}

# Prepare custom replacements (customize based on template needs)
$customReplacements = @{
    "[Feature Name]" = $FeatureName
    "[Schema Type]"  = $SchemaType
    "[Description]"  = if ($Description -ne "") { $Description } else { "Schema design for $FeatureName feature" }
}

# Create the document using standardized process
try {
    # Prepare document name with feature ID prefix if provided
    $documentName = if ($FeatureId -ne "") {
        "$FeatureId-$FeatureName"
    }
    else {
        $FeatureName
    }

    # Use DirectoryType for ID registry-based directory resolution (recommended)
    # Alternative: Use -OutputDirectory "[EXPLICIT_PATH]" for custom directory paths
    $documentId = New-StandardProjectDocument -TemplatePath "doc/process-framework/templates/templates/schema-design-template.md" -IdPrefix "PD-SCH" -IdDescription "Schema design for $SchemaType changes in ${FeatureName}" -DocumentName $documentName -DirectoryType "schemas" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Optional: Update related documentation (customize as needed)
    # Example: Update documentation maps, README files, etc.
    # [OPTIONAL_DOCUMENTATION_UPDATES]

    # Provide success details
    $details = @(
        "Feature: $FeatureName",
        "Schema Type: $SchemaType"
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
            "   doc/process-framework/guides/guides/schema-design-creation-guide.md",
            "🎯 FOCUS AREAS: 'Step-by-Step Instructions' and 'Quality Assurance' sections",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content.",
            "",
            "Next steps:",
            "1. Complete the schema design document with detailed data model specifications",
            "2. Create entity-relationship diagrams using the ER diagram template",
            "3. Design migration scripts for safe database changes",
            "4. Review schema design with the team before implementation"
        )
    }

    Write-ProjectSuccess -Message "Created Database Schema Design with ID: $documentId" -Details $details

    # Automation Integration: Update DB Design state if FeatureId provided
    if ($FeatureId -ne "") {
        Write-Host "`n🤖 Updating Feature Tracking..." -ForegroundColor Yellow

        try {
            # Validate dependencies for automation
            $dependencyCheck = Test-ScriptDependencies -RequiredFunctions @(
                "Update-FeatureTrackingStatus"
            )
            if (-not $dependencyCheck.AllDependenciesMet) {
                Write-Warning "Automation dependencies not available. Feature tracking must be updated manually."
                Write-Host "Manual Update Required:" -ForegroundColor Yellow

                Write-Host "  - Update DB Design column from 'Yes' to schema design link" -ForegroundColor Cyan
                Write-Host "  - Add schema design creation notes" -ForegroundColor Cyan
            }
            else {
                # Prepare schema design document link for feature tracking
                # Use the same filename pattern as New-StandardProjectDocument (kebab-case of feature name)
                $schemaFileName = "$($FeatureName.ToLower() -replace '\s+', '-').md"
                $relativePath = "../../../product-docs/technical/database/schemas/$schemaFileName"
                $dbDesignLink = "[$documentId]($relativePath)"

                # Prepare additional updates for feature tracking
                $additionalUpdates = @{
                    "DB Design" = $dbDesignLink
                }

                # Add notes about schema design creation
                $automationNotes = "Database schema design created: $documentId ($(Get-ProjectTimestamp -Format 'Date')) - $SchemaType schema for $FeatureName"

                if ($DryRun) {
                    Write-Host "DRY RUN: Would update feature tracking for $FeatureId" -ForegroundColor Yellow
                    Write-Host "  DB Design Column: Yes → [$documentId]($relativePath)" -ForegroundColor Cyan
                    Write-Host "  Schema Type: $SchemaType" -ForegroundColor Cyan
                    Write-Host "  Feature Name: $FeatureName" -ForegroundColor Cyan
                    Write-Host "  Notes: $automationNotes" -ForegroundColor Cyan
                }
                else {
                    # Validate prerequisites - ensure DB Design requirement exists
                    Write-Host "  🔍 Validating prerequisites..." -ForegroundColor Cyan

                    # Update feature tracking with DB Design completion (preserve current status, just update DB Design column)
                    # We need to provide the current status to preserve it since the function requires a status parameter
                    # For now, we'll use a dummy status column to avoid changing the main Status column
                    $updateResult = Update-FeatureTrackingStatus -FeatureId $FeatureId -AdditionalUpdates $additionalUpdates -Notes $automationNotes -Status "DB Design Completed" -StatusColumn "DB_Design_Status_Dummy"

                    Write-Host "  ✅ Feature tracking updated successfully" -ForegroundColor Green
                    Write-Host "  🔗 DB Design: Yes → [$documentId]($relativePath)" -ForegroundColor Green
                    Write-Host "  📋 Schema design linked in feature tracking" -ForegroundColor Green
                    Write-Host "  📝 Feature tracking updated with DB design completion" -ForegroundColor Green
                }
            }
        }
        catch {
            Write-ProjectError -Message "Failed to update feature tracking automatically: $($_.Exception.Message)"
            Write-Host "Manual Update Required:" -ForegroundColor Yellow
            Write-Host "  - Update feature $FeatureId DB Design column to '[$documentId]($relativePath)'" -ForegroundColor Cyan
            Write-Host "  - Replace 'Yes' with schema design link in feature-tracking.md" -ForegroundColor Cyan
            Write-Host "  - Add notes: $automationNotes" -ForegroundColor Cyan
        }
    }
}
catch {
    Write-ProjectError -Message "Failed to create Database Schema Design: $($_.Exception.Message)" -ExitCode 1
}
