# New-APIDataModel.ps1
# Creates a new API Data Model document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new API Data Model document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates API Data Model documents by:
    - Generating a unique document ID (PD-API-XXX)
    - Creating a properly formatted document file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for API data structure definitions
    - Automatically updating API Design state in feature tracking with intelligent replacement/append logic (when FeatureId provided)

.PARAMETER ModelName
    The name of the API data model (e.g., "User Profile", "Authentication Request")

.PARAMETER ModelDescription
    A brief description of what this data model represents

.PARAMETER ApiVersion
    The API version this model applies to (e.g., "v1", "v2.1")

.PARAMETER RelatedEndpoints
    Comma-separated list of API endpoints that use this model

.PARAMETER FeatureId
    Optional feature ID to link this API data model to for automatic state updates

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.PARAMETER DryRun
    If specified, shows what would be updated without making changes

.EXAMPLE
    ../../../product-docs/product-docs/product-docs/technical/api/models/New-APIDataModel.ps1 -ModelName "User Profile" -ModelDescription "User account profile information" -ApiVersion "v1"

.EXAMPLE
    ../../../product-docs/product-docs/product-docs/technical/api/models/New-APIDataModel.ps1 -ModelName "Authentication Request" -ModelDescription "Login request data structure" -ApiVersion "v1" -RelatedEndpoints "/auth/login,/auth/refresh" -OpenInEditor

.EXAMPLE
    ../../../product-docs/product-docs/product-docs/technical/api/models/New-APIDataModel.ps1 -ModelName "Booking Fee Model" -ModelDescription "Data structure for booking fee calculations" -ApiVersion "v1" -FeatureId "5.1.1"

.NOTES
    This script requires:
    - Access to the central ID registry (doc/id-registry.json)
    - The API Data Model template (doc/process-framework/templates/templates/api-data-model-template-template.md)
    - PowerShell 5.1 or later
    - When FeatureId is provided, automatically updates API Design column in feature tracking:
    - First data model: Replaces "Yes" with clickable link
    - Additional data models: Appends with " • " separator to existing links
    - Integrates with Process Framework automation infrastructure
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ModelName,

    [Parameter(Mandatory=$true)]
    [string]$ModelDescription,

    [Parameter(Mandatory=$false)]
    [string]$ApiVersion = "v1",

    [Parameter(Mandatory=$false)]
    [string]$RelatedEndpoints = "",

    [Parameter(Mandatory=$false)]
    [string]$FeatureId = "",

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
    "api_version" = $ApiVersion
    "related_endpoints" = $RelatedEndpoints
}

# Add feature ID if provided
if ($FeatureId -ne "") {
    $additionalMetadataFields["feature_id"] = $FeatureId
}

# Prepare custom replacements for template
$customReplacements = @{
    "[Data Model Name]" = $ModelName
    "[Brief description of what this data model represents]" = $ModelDescription
    "[When and where this data model is used]" = if ($RelatedEndpoints -ne "") { "Used in API endpoints: $RelatedEndpoints" } else { "Data model for $ModelName" }
    "[API version this model applies to]" = $ApiVersion
    "[List of related API endpoints]" = $RelatedEndpoints
    "[CREATION_DATE]" = Get-Date -Format "yyyy-MM-dd"
}

# Create the document using standardized process
try {
    $projectRoot = Get-ProjectRoot
    $templatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/api-data-model-template-template.md"

    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PD-API" -IdDescription "API Data Model for $ModelName" -DocumentName $ModelName -DirectoryType "models" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Model Name: $ModelName",
        "API Version: $ApiVersion"
    )

    # Add conditional details
    if ($ModelDescription -ne "") {
        $details += "Description: $ModelDescription"
    }

    if ($RelatedEndpoints -ne "") {
        $details += "Related Endpoints: $RelatedEndpoints"
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
            "   doc/process-framework/guides/guides/api-data-model-creation-guide.md",
            "🎯 FOCUS AREAS: 'Step-by-Step Instructions' and 'Quality Assurance' sections",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content.",
            "",
            "Next steps:",
            "1. Define the core data structure and field definitions",
            "2. Specify validation rules and data constraints",
            "3. Add realistic examples for request/response data",
            "4. Document relationships with other data models",
            "5. Link to related API specification documents"
        )
    }

    Write-ProjectSuccess -Message "Created API Data Model with ID: $documentId" -Details $details

    # Automation Integration: Update API Design state if FeatureId provided
    if ($FeatureId -ne "") {
        try {
            # Check if automation functions are available
            $automationFunctions = @(
                "Update-FeatureTrackingStatus"
            )

            $missingFunctions = $automationFunctions | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }

            # Check if the new append function is available
            $appendFunctions = @(
                "Update-FeatureTrackingStatusWithAppend"
            )

            $missingAppendFunctions = $appendFunctions | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }

            if ($missingFunctions.Count -eq 0 -and $missingAppendFunctions.Count -eq 0) {
                Write-Host "`n🔄 Updating API Design state with intelligent replacement/append logic..." -ForegroundColor Cyan

                # Calculate correct relative path from ../../../product-docs/product-docs/product-docs/technical/api/models/feature-tracking.md to API data model
                # ../../../product-docs/product-docs/product-docs/technical/api/models/feature-tracking.md is at: doc/process-framework/state-tracking/permanent/
                # API data model is at: doc/product-docs/technical/api/models/
                # Need to go up 3 levels (../../..) then down to the API model
                $sanitizedModelName = $ModelName.ToLower() -replace '[^a-z0-9\s]', '' -replace '\s+', '-'
                $actualFilename = "$sanitizedModelName-data-model.md"
                $relativePath = "../../../product-docs/technical/api/models/$actualFilename"

                # Use descriptive name following 1.1.1 convention (e.g., "Request Model", "Response Model")
                $linkDisplayName = if ($ModelName -match "Request") { "Request Model" }
                                  elseif ($ModelName -match "Response") { "Response Model" }
                                  elseif ($ModelName -match "Error") { "Error Model" }
                                  elseif ($ModelName -match "Validation") { "Validation Model" }
                                  elseif ($ModelName -match "Model$") { $ModelName }  # Already ends with "Model"
                                  else { "$ModelName Model" }
                $apiDesignLink = "[$linkDisplayName]($relativePath)"

                # Prepare append updates for feature tracking (intelligent replacement/append logic:
                # - Replaces "Yes" with first data model link
                # - Appends additional data models with " • " separator)
                $appendUpdates = @{
                    "API Design" = $apiDesignLink
                }

                # Add notes about API data model creation
                $automationNotes = "API data model created: $documentId ($(Get-ProjectTimestamp -Format 'Date')) - $ApiVersion data model for $ModelName"

                if ($DryRun) {
                    Write-Host "DRY RUN: Would append to API Design state for $FeatureId" -ForegroundColor Yellow
                    Write-Host "  API Design Column (append): [$linkDisplayName]($relativePath)" -ForegroundColor Cyan
                    Write-Host "  API Version: $ApiVersion" -ForegroundColor Cyan
                    Write-Host "  Model Name: $ModelName" -ForegroundColor Cyan
                    Write-Host "  Notes: $automationNotes" -ForegroundColor Cyan
                } else {
                    # Update feature tracking with API Design data model appended
                    $updateResult = Update-FeatureTrackingStatusWithAppend -FeatureId $FeatureId -Status "📋 API Design Created" -AppendUpdates $appendUpdates -Notes $automationNotes -DryRun:$DryRun

                    Write-Host "  ✅ API Design state updated successfully with intelligent replacement/append" -ForegroundColor Green
                    Write-Host "  🔗 API Design: Added [$linkDisplayName]($relativePath)" -ForegroundColor Green
                    Write-Host "  📋 API data model linked in feature tracking (replaces 'Yes' or appends with • separator)" -ForegroundColor Green
                    Write-Host "  📝 Feature tracking updated with API data model completion" -ForegroundColor Green
                }
            } elseif ($missingFunctions.Count -eq 0) {
                Write-Host "`n🔄 Updating API Design state (fallback to replace mode)..." -ForegroundColor Cyan
                Write-Host "⚠️  Append functionality not available - using replace mode" -ForegroundColor Yellow

                # Fallback to original replace behavior
                $relativePath = "doc/product-docs/technical/api/models/$($ModelName.ToLower() -replace '\s+', '-')-data-model.md"
                $apiDesignLink = "[$documentId]($relativePath)"

                # Prepare additional updates for feature tracking
                $additionalUpdates = @{
                    "API Design" = $apiDesignLink
                }

                # Add notes about API data model creation
                $automationNotes = "API data model created: $documentId ($(Get-ProjectTimestamp -Format 'Date')) - $ApiVersion data model for $ModelName"

                if ($DryRun) {
                    Write-Host "DRY RUN: Would update API Design state for $FeatureId" -ForegroundColor Yellow
                    Write-Host "  API Design Column: Replace with [$documentId]($relativePath)" -ForegroundColor Cyan
                    Write-Host "  API Version: $ApiVersion" -ForegroundColor Cyan
                    Write-Host "  Model Name: $ModelName" -ForegroundColor Cyan
                    Write-Host "  Notes: $automationNotes" -ForegroundColor Cyan
                } else {
                    # Update feature tracking with API Design completion (replace mode)
                    $updateResult = Update-FeatureTrackingStatus -FeatureId $FeatureId -AdditionalUpdates $additionalUpdates -Notes $automationNotes -DryRun:$DryRun

                    Write-Host "  ✅ API Design state updated successfully (replace mode)" -ForegroundColor Green
                    Write-Host "  🔗 API Design: Replaced with [$documentId]($relativePath)" -ForegroundColor Green
                    Write-Host "  📋 API data model linked in feature tracking" -ForegroundColor Green
                    Write-Host "  📝 Feature tracking updated with API design completion" -ForegroundColor Green
                }
            } else {
                Write-Host "`n⚠️  Automation functions not available:" -ForegroundColor Yellow
                Write-Host "Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Yellow
                if ($missingAppendFunctions.Count -gt 0) {
                    Write-Host "Missing append functions: $($missingAppendFunctions -join ', ')" -ForegroundColor Yellow
                }
                Write-Host "Manual Update Required:" -ForegroundColor Yellow
                $sanitizedModelName = $ModelName.ToLower() -replace '[^a-z0-9\s]', '' -replace '\s+', '-'
                $actualFilename = "$sanitizedModelName-data-model.md"
                $relativePath = "../../../product-docs/technical/api/models/$actualFilename"
                Write-Host "  - Add to feature $FeatureId API Design column: ' • [$documentId]($relativePath)'" -ForegroundColor Cyan
                Write-Host "  - Uses intelligent logic: replaces 'Yes' or appends with ' • ' separator in ../../../product-docs/product-docs/product-docs/technical/api/models/feature-tracking.md" -ForegroundColor Cyan
            }
        }
        catch {
            Write-Warning "Failed to update API Design state automatically: $($_.Exception.Message)"
            Write-Host "Manual Update Required:" -ForegroundColor Yellow
            $sanitizedModelName = $ModelName.ToLower() -replace '[^a-z0-9\s]', '' -replace '\s+', '-'
            $actualFilename = "$sanitizedModelName-data-model.md"
            $relativePath = "../../../product-docs/technical/api/models/$actualFilename"
            Write-Host "  - Add to feature $FeatureId API Design column: ' • [$documentId]($relativePath)'" -ForegroundColor Cyan
            Write-Host "  - Uses intelligent logic: replaces 'Yes' or appends with ' • ' separator in ../../../product-docs/product-docs/product-docs/technical/api/models/feature-tracking.md" -ForegroundColor Cyan
        }
    }

} catch {
    Write-ProjectError -Message "Failed to create API Data Model: $($_.Exception.Message)" -ExitCode 1
}
