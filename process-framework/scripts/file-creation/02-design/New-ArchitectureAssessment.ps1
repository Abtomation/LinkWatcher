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
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization


# Soak verification opt-in (PF-PRO-028 v2.0 Pattern B; helper-routed armoring via DocumentManagement.psm1).
# Caller-aware no-arg form: helper resolves this script's path via Get-PSCallStack.
# Idempotent — silently no-ops if already registered.
Register-SoakScript

# Function to update per-feature state file §4 Documentation Inventory with architecture assessment
function Update-FeatureStateWithArchReview {
    param(
        [string]$FeatureId,
        [string]$DocumentId,
        [string]$DocumentPath
    )

    try {
        $projectRoot = Get-ProjectRoot
        $relativePath = "doc/technical/architecture/assessments/$(Split-Path -Leaf $DocumentPath)"

        $invResult = Add-StateFileDocumentationInventoryRow `
            -FeatureId $FeatureId `
            -ArtifactId $DocumentId `
            -ArtifactPath $relativePath `
            -ArtifactType "Architecture Impact Assessment" `
            -Status "✅ Created" `
            -ProjectRoot $projectRoot

        $verb = $invResult.Action.ToLower()
        Write-Host ("✅ State file §4 Documentation Inventory: {0} (line {1})" -f $verb, $invResult.LineNumber) -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Failed to update feature state file: $($_.Exception.Message)" -ForegroundColor Yellow
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
        $archTrackingPath = Join-Path -Path $projectRoot -ChildPath "doc/state-tracking/permanent/architecture-tracking.md"

        if (-not (Test-Path $archTrackingPath)) {
            Write-Host "⚠️ Architecture tracking file not found at: $archTrackingPath" -ForegroundColor Yellow
            return
        }

        $content = Get-Content -Path $archTrackingPath -Raw
        $currentDate = Get-Date -Format "yyyy-MM-dd"

        # Repo-relative path to the assessment document (used as the markdown link target in architecture-tracking.md)
        $relativePath = "doc/technical/architecture/assessments/$(Split-Path -Leaf $DocumentPath)"

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
    $templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/02-design/architecture-impact-assessment-template.md"
    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PD-AIA" -IdDescription "Architecture Impact Assessment: ${FeatureName}" -DocumentName $FeatureName -OutputDirectory "doc/technical/architecture/assessments" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Get the created document path for state updates (use the actual filename created by New-StandardProjectDocument).
    # Slug via the canonical helper from Common-ScriptHelpers/Naming.psm1 (PF-IMP-008).
    $documentPath = Join-Path -Path $projectRoot -ChildPath "doc/technical/architecture/assessments/$(ConvertTo-FeatureSlug -Name $FeatureName -Convention 'kebab-case').md"

    # Update state tracking files
    Write-Host "🔄 Updating state tracking files..." -ForegroundColor Cyan
    Update-FeatureStateWithArchReview -FeatureId $FeatureId -DocumentId $documentId -DocumentPath $documentPath
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
            "Customization required — see process-framework/guides/02-design/architecture-assessment-creation-guide.md",
            "",
            "✅ AUTOMATED STATE UPDATES COMPLETED:",
            "   • Feature state file §4 Documentation Inventory updated with assessment row",
            "   • Architecture tracking updated with new assessment entry",
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
