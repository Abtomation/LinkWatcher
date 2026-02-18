# New-ArchitectureAssessment.ps1
# Creates a new Architecture Impact Assessment with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Architecture Impact Assessment document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Architecture Impact Assessment documents by:
    - Generating a unique document ID (PD-AIA-XXX)
    - Creating a properly formatted assessment document
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for architectural impact analysis

.PARAMETER FeatureName
    The name of the feature being assessed for architectural impact

.PARAMETER FeatureId
    The feature ID (e.g., "1.1.1") for tracking and state updates

.PARAMETER AssessmentType
    The type of assessment being performed (Impact, Integration, Risk, etc.)

.PARAMETER Description
    Optional description of the assessment scope and purpose

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-ArchitectureAssessment.ps1 -FeatureName "User Authentication" -FeatureId "1.1.1" -AssessmentType "Impact"

.EXAMPLE
    .\New-ArchitectureAssessment.ps1 -FeatureName "Payment Integration" -FeatureId "4.2.1" -AssessmentType "Integration" -Description "Assessment of payment gateway integration impact" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Script Metadata:
    - Script Type: Document Creation Script
    - Created: 2025-07-18
    - For: Creating Architecture Impact Assessment documents
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureName,

    [Parameter(Mandatory = $true)]
    [string]$FeatureId,

    [Parameter(Mandatory = $false)]
    [string]$AssessmentType = "Impact",

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Function to update feature tracking with architecture review completion
function Update-FeatureTrackingWithArchReview {
    param(
        [string]$FeatureId,
        [string]$DocumentId,
        [string]$DocumentPath
    )

    try {
        $projectRoot = Get-ProjectRoot
        $featureTrackingPath = Join-Path -Path $projectRoot -ChildPath "doc/process-framework/state-tracking/permanent/feature-tracking.md"

        if (-not (Test-Path $featureTrackingPath)) {
            Write-Host "⚠️ Feature tracking file not found at: $featureTrackingPath" -ForegroundColor Yellow
            return
        }

        $content = Get-Content -Path $featureTrackingPath -Raw
        $currentDate = Get-Date -Format "yyyy-MM-dd"

        # Create relative path from ../../../product-docs/technical/architecture/assessments/../../../product-docs/product-docs/technical/architecture/assessments/feature-tracking.md to the assessment document
        $relativePath = "../../../product-docs/technical/architecture/assessments/assessments/$(Split-Path -Leaf $DocumentPath)"

        # Pattern to match the feature row - look for the feature ID at the start of a table row
        $pattern = "(\| $FeatureId \|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|)([^|]*\|)"

        if ($content -match $pattern) {
            # Replace the status from "📋 FDD Created" to "🏗️ Architecture Reviewed" and add arch review link
            $updatedContent = $content -replace $pattern, "`$1 [$DocumentId]($relativePath) |"

            # Update the status to "🏗️ Architecture Reviewed" regardless of current status
            $statusPattern = "(\| $FeatureId \|[^|]*\|)\s*[^|]*\s*(\|)"
            $updatedContent = $updatedContent -replace $statusPattern, "`$1 🏗️ Architecture Reviewed `$2"

            # Add architecture review completion note to the Notes column (14th column)
            $notesPattern = "(\| $FeatureId \|(?:[^|]*\|){12}[^|]*?)(\s*\|)"
            $updatedContent = $updatedContent -replace $notesPattern, "`$1 - Architecture review completed ($currentDate)`$2"

            Set-Content -Path $featureTrackingPath -Value $updatedContent -NoNewline
            Write-Host "✅ Updated feature tracking for $FeatureId with architecture review completion" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️ Could not find feature $FeatureId in feature tracking file for status update" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "⚠️ Failed to update feature tracking: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Function to update architecture tracking
function Update-ArchitectureTracking {
    param(
        [string]$FeatureId,
        [string]$FeatureName,
        [string]$DocumentId,
        [string]$DocumentPath
    )

    try {
        $projectRoot = Get-ProjectRoot
        $archTrackingPath = Join-Path -Path $projectRoot -ChildPath "doc/process-framework/state-tracking/permanent/architecture-tracking.md"

        if (-not (Test-Path $archTrackingPath)) {
            Write-Host "⚠️ Architecture tracking file not found at: $archTrackingPath" -ForegroundColor Yellow
            return
        }

        $content = Get-Content -Path $archTrackingPath -Raw
        $currentDate = Get-Date -Format "yyyy-MM-dd"

        # Create relative path from ../../../product-docs/technical/architecture/assessments/../../../product-docs/product-docs/technical/architecture/assessments/architecture-tracking.md to the assessment document
        $relativePath = "../../product-docs/technical/architecture/assessments/assessments/$(Split-Path -Leaf $DocumentPath)"

        # Find the end of the table (look for the last table row)
        $tableEndPattern = "(\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|)\s*\n\s*\n"

        if ($content -match $tableEndPattern) {
            $newRow = "| $DocumentId | $FeatureName Architecture Impact | Feature Impact Assessment | $FeatureId | [$DocumentId]($relativePath) | $currentDate | Active | System integration analysis for $FeatureName | Cross-cutting | Medium | Feature-specific architectural impact assessment |"
            $updatedContent = $content -replace $tableEndPattern, "`$1`n$newRow`n`n"

            Set-Content -Path $archTrackingPath -Value $updatedContent -NoNewline
            Write-Host "✅ Updated architecture tracking with new assessment entry for $FeatureId" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️ Could not find table end pattern in architecture tracking file" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "⚠️ Failed to update architecture tracking: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_name"    = $FeatureName
    "feature_id"      = $FeatureId
    "assessment_type" = $AssessmentType
}

# Prepare custom replacements
$customReplacements = @{
    "[FEATURE_NAME]"           = $FeatureName
    "[FEATURE_ID]"             = $FeatureId
    "[ASSESSMENT_TYPE]"        = $AssessmentType
    "[ASSESSMENT_DESCRIPTION]" = if ($Description -ne "") { $Description } else { "Architecture impact assessment for $FeatureName feature" }
}

# Create the document using standardized process
try {
    $projectRoot = Get-ProjectRoot
    $templatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/architecture-impact-assessment-template.md"
    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PD-AIA" -IdDescription "Architecture Impact Assessment: ${FeatureName}" -DocumentName $FeatureName -OutputDirectory "doc/product-docs/technical/architecture/assessments/assessments" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Get the created document path for state updates (use the actual filename created by New-StandardProjectDocument)
    $documentPath = Join-Path -Path $projectRoot -ChildPath "doc/product-docs/technical/architecture/assessments/assessments/$(($FeatureName -replace '[^a-zA-Z0-9]', '-').ToLower()).md"

    # Update state tracking files
    Write-Host "🔄 Updating state tracking files..." -ForegroundColor Cyan
    Update-FeatureTrackingWithArchReview -FeatureId $FeatureId -DocumentId $documentId -DocumentPath $documentPath
    Update-ArchitectureTracking -FeatureId $FeatureId -FeatureName $FeatureName -DocumentId $documentId -DocumentPath $documentPath

    # Provide success details
    $details = @(
        "Feature: $FeatureName ($FeatureId)",
        "Assessment Type: $AssessmentType",
        "Document ID: $documentId"
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
            "   doc/process-framework/guides/guides/architecture-assessment-creation-guide.md",
            "🎯 FOCUS AREAS: 'Step-by-Step Instructions' and 'Quality Assurance' sections",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content.",
            "",
            "✅ AUTOMATED STATE UPDATES COMPLETED:",
            "   • Feature tracking updated: $FeatureId status → 🏗️ Architecture Reviewed",
            "   • Architecture tracking updated with new assessment entry",
            "   • Arch Review column populated with assessment link",
            "",
            "Next steps:",
            "1. Complete the architectural impact analysis in the created document",
            "2. Review existing ADRs and system architecture documentation",
            "3. Document integration points and component relationships",
            "4. Identify architectural risks and mitigation strategies",
            "5. Proceed to Test Specification Creation when assessment is complete"
        )
    }

    Write-ProjectSuccess -Message "Created Architecture Impact Assessment with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Architecture Impact Assessment: $($_.Exception.Message)" -ExitCode 1
}
