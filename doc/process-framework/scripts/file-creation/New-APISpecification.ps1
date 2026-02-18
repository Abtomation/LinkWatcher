# New-APISpecification.ps1
# Creates a new API Specification document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new API Specification document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates API Specification documents by:
    - Generating a unique document ID (PD-API-XXX)
    - Creating a properly formatted API specification file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for API contract definition
    - Automatically updating API Design state in feature tracking (when FeatureId provided)
    - Appending API specification link to existing API Design content in ../../../product-docs/product-docs/product-docs/product-docs/technical/api/specifications/feature-tracking.md

.PARAMETER APIName
    The name of the API being specified (e.g., "User Authentication API", "Booking Management API")

.PARAMETER APIDescription
    Brief description of the API's purpose and functionality

.PARAMETER APIType
    Type of API (e.g., "REST", "GraphQL", "gRPC", "Service Interface")

.PARAMETER FeatureId
    Optional feature ID to link this API specification to for automatic state updates.
    When provided, the filename will be formatted as: api-{feature-id}-{api-name}.md
    Example: api-1.2.1-basic-profile-data.md

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.PARAMETER DryRun
    If specified, shows what would be updated without making changes

.EXAMPLE
    ../../../product-docs/product-docs/product-docs/technical/api/specifications/New-APISpecification.ps1 -APIName "User Authentication API" -APIDescription "Handles user login, registration, and session management"

.EXAMPLE
    ../../../product-docs/product-docs/product-docs/technical/api/specifications/New-APISpecification.ps1 -APIName "Booking Management API" -APIDescription "Manages escape room bookings and reservations" -APIType "REST" -OpenInEditor

.EXAMPLE
    ../../../product-docs/product-docs/product-docs/technical/api/specifications/New-APISpecification.ps1 -APIName "Booking Fee API" -APIDescription "Handles booking fee calculations and processing" -APIType "REST" -FeatureId "5.1.1"
    Creates file: api-5.1.1-booking-fee-api.md

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - When FeatureId is provided, automatically appends to API Design column in feature tracking
    - Fully automated state file updates via Update-FeatureTrackingStatusWithAppend function
    - Integrates with Process Framework automation infrastructure

    Script Metadata:
    - Created for: API Design Task (PF-TSK-020)
    - Purpose: Generate API specification documents
    - ID Prefix: PD-API
    - Output Directory: doc/product-docs/technical/api/specifications
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$APIName,

    [Parameter(Mandatory = $false)]
    [string]$APIDescription = "",

    [Parameter(Mandatory = $false)]
    [string]$APIType = "REST",

    [Parameter(Mandatory = $false)]
    [string]$FeatureId = "",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "api_name" = $APIName
    "api_type" = $APIType
}

# Add feature ID if provided
if ($FeatureId -ne "") {
    $additionalMetadataFields["feature_id"] = $FeatureId
}

# Prepare custom replacements for template
$customReplacements = @{
    "[API_NAME]"        = $APIName
    "[API_DESCRIPTION]" = if ($APIDescription -ne "") { $APIDescription } else { "API specification for $APIName" }
    "[API_TYPE]"        = $APIType
    "[CREATION_DATE]"   = Get-Date -Format "yyyy-MM-dd"
}

# Generate custom filename with feature ID and "api-" prefix
$fileNamePattern = $null
if ($FeatureId -ne "") {
    # Sanitize API name to kebab-case
    $sanitizedAPIName = $APIName.ToLower() -replace '[^a-z0-9\s]', '' -replace '\s+', '-'
    # Create filename: api-{feature-id}-{api-name}.md
    $fileNamePattern = "api-$FeatureId-$sanitizedAPIName.md"
}

# Create the document using standardized process
try {
    $projectRoot = Get-ProjectRoot
    $templatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/api-specification-template-template.md"

    $createParams = @{
        TemplatePath             = $templatePath
        IdPrefix                 = "PD-API"
        IdDescription            = "API Specification for $APIName"
        DocumentName             = $APIName
        DirectoryType            = "specifications"
        Replacements             = $customReplacements
        AdditionalMetadataFields = $additionalMetadataFields
        OpenInEditor             = $OpenInEditor
    }

    # Add custom filename pattern if feature ID is provided
    if ($fileNamePattern) {
        $createParams["FileNamePattern"] = $fileNamePattern
    }

    $documentId = New-StandardProjectDocument @createParams

    # Provide success details
    $details = @(
        "API Name: $APIName",
        "API Type: $APIType"
    )

    # Add conditional details
    if ($APIDescription -ne "") {
        $details += "Description: $APIDescription"
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
            "   doc/process-framework/guides/guides/api-specification-creation-guide.md",
            "🎯 FOCUS AREAS: 'Step-by-Step Instructions' and 'Quality Assurance' sections",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content.",
            "",
            "Next steps:",
            "1. Complete the API specification with endpoint definitions",
            "2. Define request/response schemas and data models",
            "3. Specify error handling patterns and status codes",
            "4. Document authentication and authorization requirements",
            "5. Create API documentation for consumers"
        )
    }

    Write-ProjectSuccess -Message "Created API Specification with ID: $documentId" -Details $details

    # Automation Integration: Update API Design state if FeatureId provided
    if ($FeatureId -ne "") {
        try {
            # Check if automation functions are available
            $automationFunctions = @(
                "Update-FeatureTrackingStatusWithAppend"
            )

            $missingFunctions = $automationFunctions | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }

            if ($missingFunctions.Count -eq 0) {
                Write-Host "`n🔄 Updating API Design state..." -ForegroundColor Cyan

                # Generate the actual filename that was created by New-StandardProjectDocument
                # Use the same logic as above to determine the filename
                if ($fileNamePattern) {
                    $actualFilename = $fileNamePattern
                }
                else {
                    $sanitizedAPIName = $APIName.ToLower() -replace '[^a-z0-9\s]', '' -replace '\s+', '-'
                    $actualFilename = "$sanitizedAPIName.md"
                }
                # Calculate correct relative path from ../../../product-docs/product-docs/product-docs/product-docs/technical/api/specifications/feature-tracking.md to API specification
                # ../../../product-docs/product-docs/product-docs/product-docs/technical/api/specifications/feature-tracking.md is at: doc/process-framework/state-tracking/permanent/
                # API spec is at: doc/product-docs/technical/api/specifications/specifications/
                # Need to go up 3 levels (../../..) then down to the API spec
                $relativePath = "../../../product-docs/technical/api/specifications/specifications/$actualFilename"

                # Use descriptive name following 1.1.1 convention (e.g., "API Spec")
                $linkDisplayName = "API Spec"
                $apiDesignLink = "[$linkDisplayName]($relativePath)"

                # Add notes about API specification creation
                $automationNotes = "API specification created: $documentId ($(Get-ProjectTimestamp -Format 'Date')) - $APIType API for $APIName"

                if ($DryRun) {
                    Write-Host "DRY RUN: Would append to API Design state for feature $FeatureId" -ForegroundColor Yellow
                    Write-Host "  API Design Column (append): [$linkDisplayName]($relativePath)" -ForegroundColor Cyan
                    Write-Host "  API Type: $APIType" -ForegroundColor Cyan
                    Write-Host "  API Name: $APIName" -ForegroundColor Cyan
                    Write-Host "  Notes: $automationNotes" -ForegroundColor Cyan
                }
                else {
                    # Update feature tracking with API Design completion using append functionality
                    $appendUpdates = @{
                        "API Design" = $apiDesignLink
                    }
                    $updateResult = Update-FeatureTrackingStatusWithAppend -FeatureId $FeatureId -Status "📋 API Design Created" -AppendUpdates $appendUpdates -Notes $automationNotes -DryRun:$DryRun

                    if ($updateResult) {
                        Write-Host "  ✅ API Design state updated successfully with append" -ForegroundColor Green
                        Write-Host "  🔗 API Design: Appended [$linkDisplayName]($relativePath)" -ForegroundColor Green
                        Write-Host "  📋 API specification linked in feature tracking with • separator" -ForegroundColor Green
                        Write-Host "  📝 Feature tracking updated with API specification completion" -ForegroundColor Green
                    }
                    else {
                        Write-Warning "API Design state update returned no result - check feature tracking manually"
                    }
                }
            }
            else {
                Write-Host "`n⚠️  Automation functions not available:" -ForegroundColor Yellow
                Write-Host "Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Yellow
                Write-Host "Manual Update Required:" -ForegroundColor Yellow
                Write-Host "  - Append '[$linkDisplayName]($relativePath)' to feature $FeatureId API Design column" -ForegroundColor Cyan
                Write-Host "  - Use ' • ' separator if existing content present in ../../../product-docs/product-docs/product-docs/product-docs/technical/api/specifications/feature-tracking.md" -ForegroundColor Cyan
            }
        }
        catch {
            Write-Warning "Failed to update API Design state automatically: $($_.Exception.Message)"
            # Use the same logic as above to determine the filename
            if ($fileNamePattern) {
                $actualFilename = $fileNamePattern
            }
            else {
                $sanitizedAPIName = $APIName.ToLower() -replace '[^a-z0-9\s]', '' -replace '\s+', '-'
                $actualFilename = "$sanitizedAPIName.md"
            }
            # Calculate correct relative path from ../../../product-docs/product-docs/product-docs/product-docs/technical/api/specifications/feature-tracking.md to API specification
            $relativePath = "../../../product-docs/technical/api/specifications/specifications/$actualFilename"
            $linkDisplayName = "API Spec"
            Write-Host "Manual Update Required:" -ForegroundColor Yellow
            Write-Host "  - Append '[$linkDisplayName]($relativePath)' to feature $FeatureId API Design column" -ForegroundColor Cyan
            Write-Host "  - Use ' • ' separator if existing content present in ../../../product-docs/product-docs/product-docs/product-docs/technical/api/specifications/feature-tracking.md" -ForegroundColor Cyan
        }
    }
}
catch {
    Write-ProjectError -Message "Failed to create API Specification: $($_.Exception.Message)" -ExitCode 1
}
