# New-ArchitectureDecision.ps1
# Creates a new architecture decision record with an automatically assigned ID
# Uses the central ID registry system

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$Title,

    [Parameter(Mandatory=$false)]
    [string]$Description = "",

    [Parameter(Mandatory=$false)]
    [ValidateSet("Proposed", "Accepted", "Rejected", "Deprecated", "Superseded")]
    [string]$Status = "Proposed",

    [Parameter(Mandatory=$false)]
    [string]$RelatedFeatureId = "",

    [Parameter(Mandatory=$false)]
    [ValidateSet("Low", "Medium", "High", "Critical")]
    [string]$ImpactLevel = "High",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare custom replacements
$customReplacements = @{
    "[Title]" = $Title
    "[Brief description of the decision]" = if ($Description -ne "") { $Description } else { "Architecture decision regarding $Title" }
    "[Proposed, Accepted, Deprecated, Superseded]" = $Status
}

try {
    $projectRoot = Get-ProjectRoot
    $templatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/adr-template.md"
    $arcId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PD-ADR" -IdDescription "Architecture Decision: ${Title}" -DocumentName $Title -OutputDirectory "doc/product-docs/technical/architecture/design-docs/adr/adr" -Replacements $customReplacements -OpenInEditor:$OpenInEditor

    # Update tracking files automatically
    try {
        $kebabTitle = ConvertTo-KebabCase -InputString $Title
        $documentPath = Join-Path (Get-ProjectRoot) "doc/product-docs/technical/architecture/design-docs/adr/adr/$kebabTitle.md"
        Write-Verbose "Constructed document path: $documentPath"
        $trackingMetadata = @{
            "title" = $Title
            "status" = $Status
            "description" = $Description
            "related_feature_id" = $RelatedFeatureId
            "impact_level" = $ImpactLevel
        }

        Write-Host "📊 Updating tracking files..." -ForegroundColor Cyan
        Update-DocumentTrackingFiles -DocumentId $arcId -DocumentType "ADR" -DocumentPath $documentPath -Metadata $trackingMetadata
    }
    catch {
        Write-Warning "Failed to update tracking files: $($_.Exception.Message)"
        Write-Host "📋 Manual tracking file updates may be required" -ForegroundColor Yellow
    }

    # Note: ADR documentation is managed through the central documentation map
    # Individual ADRs are referenced through the architecture documentation structure
    Write-Verbose "ADR created and will be discoverable through the architecture documentation structure"

    $details = @(
        "Status: $Status",
        "",
        "Next steps:",
        "1. Edit the file to complete the architecture decision documentation",
        "2. Update the status as the decision progresses through the approval process"
    )

    # Add mandatory guide consultation if not opening in editor
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
            "   doc/process-framework/guides/guides/architecture-decision-creation-guide.md",
            "🎯 FOCUS AREAS: 'Step-by-Step Instructions' and 'Quality Assurance' sections",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content."
        )
    }

    Write-ProjectSuccess -Message "Created architecture decision with ID: $arcId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create architecture decision: $($_.Exception.Message)" -ExitCode 1
}
