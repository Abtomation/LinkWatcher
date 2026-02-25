# New-DesignDocument.ps1
# This script creates appropriate design documentation based on feature complexity tier
# All documents are created with the 'tdd' prefix and stored in the 'tdd' subdirectory
# Uses the central ID registry system

<#
.SYNOPSIS
    Creates appropriate design documentation based on feature complexity tier.

.DESCRIPTION
    This PowerShell script generates the appropriate design document template based on
    the feature's complexity tier. It creates the file with the correct structure,
    naming convention, and initial content based on the tier-specific requirements.
    Additionally, it automatically updates feature tracking with TDD completion status
    and links the TDD document in the feature tracking table.

.PARAMETER FeatureId
    The ID of the feature (e.g., "1.2.3")

.PARAMETER FeatureName
    The name of the feature

.PARAMETER Tier
    The complexity tier (1, 2, or 3)

.PARAMETER OpenInEditor
    Switch to open the created document in the default editor

.PARAMETER DryRun
    If specified, shows what would be updated in feature tracking without making changes

.EXAMPLE
    ./New-DesignDocument.ps1 -FeatureId "1.2.3" -FeatureName "User Authentication" -Tier 2
    # Creates tdd-1.2.3-user-authentication-t2.md in the tdd subdirectory

.EXAMPLE
    ./New-DesignDocument.ps1 -FeatureId "1.2.3" -FeatureName "User Authentication" -Tier 3 -OpenInEditor
    # Creates ../../../product-docs/technical/product-docs/technical/architecture/design-docs/tdd-1.2.3-user-authentication-t3.md and opens it in the editor

.EXAMPLE
    ./New-DesignDocument.ps1 -FeatureId "1.4.1" -FeatureName "Payment Processing" -Tier 2 -DryRun
    # Shows what would be updated in feature tracking without making changes

.NOTES
    This script creates documents with the tier-appropriate template:
    - Tier 1: Lightweight planning document (Feature Planning Document)
    - Tier 2: Standard TDD with essential sections (Lightweight Technical Design Document)
    - Tier 3: Comprehensive TDD with all sections (Comprehensive Technical Design Document)

    The script processes templates with dual metadata structure:
    - Template metadata (PD-TEM-007/008/009) for the template files themselves
    - Document metadata (PD-TDD-XXX) for the created documents

    It ensures the AI Agent Session Handoff Notes section is included in all templates.

    All documents use the naming convention: tdd-[FeatureID]-[feature-name]-t[Tier].md
    and are stored in the /tdd subdirectory.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$true)]
    [string]$FeatureId,

    [Parameter(Mandatory=$true)]
    [string]$FeatureName,

    [Parameter(Mandatory=$true)]
    [ValidateSet("1", "2", "3")]
    [string]$Tier,

    [switch]$OpenInEditor,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Get project root and define template paths for each tier
$projectRoot = Get-ProjectRoot
$templatePaths = @{
    "1" = Join-Path $projectRoot "doc/product-docs/templates/templates/tdd-t1-template.md"
    "2" = Join-Path $projectRoot "doc/product-docs/templates/templates/tdd-t2-template.md"
    "3" = Join-Path $projectRoot "doc/product-docs/templates/templates/tdd-t3-template.md"
}

# Ensure template exists
if (-not (Test-Path $templatePaths[$Tier])) {
    Write-ProjectError -Message "Template for Tier $Tier not found at $($templatePaths[$Tier])" -ExitCode 1
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_id" = $FeatureId
    "tier" = $Tier
}

# Prepare custom replacements
$customReplacements = @{
    '[Feature Name]' = $FeatureName
    '[FEATURE_ID]' = $FeatureId
}

# Create custom filename pattern
$safeFeatureName = ConvertTo-KebabCase -InputString $FeatureName
$safeFeatureId = $FeatureId -replace '\.', '-'
$customFileName = "tdd-$safeFeatureId-$safeFeatureName-t$Tier.md"

try {
    $tddId = New-StandardProjectDocument -TemplatePath $templatePaths[$Tier] -IdPrefix "PD-TDD" -IdDescription "TDD Tier $Tier for feature ${FeatureId}: ${FeatureName}" -DocumentName $FeatureName -OutputDirectory "doc/product-docs/technical/architecture/design-docs/tdd" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $customFileName -OpenInEditor:$OpenInEditor

    # Display success message
    $tierNames = @{
        "1" = "Tier 1 (Planning Document)"
        "2" = "Tier 2 (Lightweight TDD)"
        "3" = "Tier 3 (Full TDD)"
    }

    $details = @(
        "Feature: $FeatureId - $FeatureName",
        "Tier: $($tierNames[$Tier])",
        "",
        "The document includes an AI Agent Session Handoff Notes section for maintaining context between development sessions."
    )

    # Add mandatory guide consultation if not opening in editor
    if (-not $OpenInEditor) {
        $details += @(
            "",
            "🚨 MANDATORY NEXT STEP: TDD Creation Guide Review Required",
            "   You MUST consult the TDD Creation Guide before proceeding.",
            "",
            "📖 REQUIRED READING:",
            "   doc/process-framework/guides/guides/tdd-creation-guide.md",
            "   Focus on: 'Step-by-Step Instructions' and 'Quality Assurance' sections",
            "",
            "⚠️  The created file is only a structural framework - it requires extensive",
            "   customization following the guide's instructions to become functional."
        )
    }

    Write-ProjectSuccess -Message "Created $($tierNames[$Tier])" -Details $details

    # 🚀 AUTOMATION ENHANCEMENT: Update feature tracking with TDD completion
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
            Write-Host "  - Update Status: 📋 FDD Created (Tier 2+) or 📊 Assessment Created (Tier 1) → 📝 TDD Created" -ForegroundColor Cyan
            Write-Host "  - Add TDD link to Tech Design column" -ForegroundColor Cyan
            Write-Host "  - Add TDD creation date to Notes column" -ForegroundColor Cyan
        } else {
            # Prepare TDD document link
            $tddLink = "[$tddId](../../../../product-docs/technical/architecture/design-docs/tdd/$customFileName)"

            # Prepare additional updates for feature tracking
            $additionalUpdates = @{
                "Tech Design" = $tddLink
            }

            # Determine expected previous status based on tier
            $expectedPreviousStatus = if ($Tier -eq "1") { "📊 Assessment Created" } else { "📋 FDD Created" }

            # Add notes about TDD creation with creation date
            $creationDate = Get-ProjectTimestamp -Format 'Date'
            $automationNotes = "TDD created: $tddId ($creationDate) - $($tierNames[$Tier])"

            if ($DryRun) {
                Write-Host "DRY RUN: Would update feature tracking for $FeatureId" -ForegroundColor Yellow
                Write-Host "  Status: $expectedPreviousStatus → 📝 TDD Created" -ForegroundColor Cyan
                Write-Host "  Tech Design Link: $tddLink" -ForegroundColor Cyan
                Write-Host "  Notes: $automationNotes" -ForegroundColor Cyan
            } else {
                # Validate prerequisites based on tier
                Write-Host "  🔍 Validating prerequisites for Tier $Tier..." -ForegroundColor Cyan

                # Update feature tracking with TDD completion
                $updateResult = Update-FeatureTrackingStatus -FeatureId $FeatureId -Status "📝 TDD Created" -AdditionalUpdates $additionalUpdates -Notes $automationNotes

                Write-Host "  ✅ Feature tracking updated successfully" -ForegroundColor Green
                Write-Host "  📝 Status: $expectedPreviousStatus → 📝 TDD Created" -ForegroundColor Green
                Write-Host "  🔗 TDD linked in Tech Design column" -ForegroundColor Green
                Write-Host "  📅 Creation date added to Notes: $creationDate" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Warning "Failed to update feature tracking automatically: $($_.Exception.Message)"
        Write-Host "Manual Update Required:" -ForegroundColor Yellow
        Write-Host "  - Update feature $FeatureId status to '📝 TDD Created'" -ForegroundColor Cyan
        Write-Host "  - Add TDD link: [$tddId](../../../../product-docs/technical/architecture/design-docs/tdd/$customFileName)" -ForegroundColor Cyan
        Write-Host "  - Add creation date to Notes: $(Get-ProjectTimestamp -Format 'Date')" -ForegroundColor Cyan
    }
}
catch {
    Write-ProjectError -Message "Failed to create TDD: $($_.Exception.Message)" -ExitCode 1
}
