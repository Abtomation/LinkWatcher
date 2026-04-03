# New-Guide.ps1
# Creates a new guide with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new guide document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates guide documents by:
    - Generating a unique document ID (PF-GDE-XXX)
    - Creating a properly formatted guide file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for comprehensive instructional guides

.PARAMETER GuideTitle
    The title of the guide (e.g., "User Authentication Setup", "Database Migration")

.PARAMETER GuideDescription
    Brief description of what the guide helps accomplish

.PARAMETER GuideCategory
    Optional category for the guide (e.g., "Development Process", "Technical", "Documentation")

.PARAMETER GuideStatus
    Status of the guide. Valid values: "Active" (default), "Draft", "Deprecated", "Under Review"

.PARAMETER RelatedScript
    Optional name of the script this guide relates to (e.g., "../../../../../../../../../../guides/New-DebtItem.ps1")

.PARAMETER RelatedTasks
    Optional comma-separated list of task IDs this guide relates to (e.g., "PF-TSK-023,PF-TSK-024")

.PARAMETER SubDirectory
    Subdirectory within process-framework/guides/ where the guide will be placed.
    Examples: "01-planning", "02-design", "03-testing", "04-implementation", "05-validation",
    "06-maintenance", "07-deployment", "cyclical", "framework", "support"

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-Guide.ps1 -GuideTitle "API Integration Setup" -SubDirectory "02-design" -GuideDescription "Step-by-step guide for integrating third-party APIs"

.EXAMPLE
    .\New-Guide.ps1 -GuideTitle "Testing Best Practices" -SubDirectory "03-testing" -GuideDescription "Comprehensive guide for writing effective tests" -GuideCategory "Development Process" -OpenInEditor

.EXAMPLE
    .\New-Guide.ps1 -GuideTitle "Debt Item Creation Guide" -SubDirectory "cyclical" -GuideDescription "Guide for customizing technical debt item templates" -RelatedScript "New-DebtItem.ps1" -RelatedTasks "PF-TSK-023"

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Template Metadata:
    - Template ID: PF-TEM-003
    - Template Type: Guide Template
    - Created: 2023-06-15
    - For: Creating comprehensive instructional guides
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$GuideTitle,

    [Parameter(Mandatory = $false)]
    [string]$GuideDescription = "",

    [Parameter(Mandatory = $false)]
    [string]$GuideCategory = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Active", "Draft", "Deprecated", "Under Review")]
    [string]$GuideStatus = "Active",

    [Parameter(Mandatory = $false)]
    [string]$RelatedScript = "",

    [Parameter(Mandatory = $false)]
    [string]$RelatedTasks = "",

    [Parameter(Mandatory = $true)]
    [string]$SubDirectory,

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

# Prepare additional metadata fields (IMP-376: removed redundant guide_* fields)
$additionalMetadataFields = @{}

# Add related script if provided
if ($RelatedScript -ne "") {
    $additionalMetadataFields["related_script"] = $RelatedScript
}

# Add related task if provided (singular, per metadata schema)
if ($RelatedTasks -ne "") {
    $additionalMetadataFields["related_task"] = $RelatedTasks
}

# Prepare custom replacements based on the guide template
$customReplacements = @{
    "[Guide Title]"                                                                                                                            = $GuideTitle
    "[Brief description of what this guide helps the user accomplish. Keep it to 2-3 sentences that clearly explain the purpose and outcome.]" = if ($GuideDescription -ne "") { $GuideDescription } else { "[Brief description of what this guide helps the user accomplish. Keep it to 2-3 sentences that clearly explain the purpose and outcome.]" }
    "[Optional: Script name this guide relates to]"                                                                                            = if ($RelatedScript -ne "") { $RelatedScript } else { "" }
    "[Optional: Comma-separated task IDs this guide relates to]"                                                                               = if ($RelatedTasks -ne "") { $RelatedTasks } else { "" }
    "[Date]"                                                                                                                                   = Get-Date -Format "yyyy-MM-dd"
    "[Author name or team]"                                                                                                                    = "AI Agent & Human Partner"
}

# Create the document using standardized process
try {
    $outputDir = "process-framework/guides/$SubDirectory"
    $documentId = New-StandardProjectDocument -TemplatePath "process-framework/templates/support/guide-template.md" -IdPrefix "PF-GDE" -IdDescription "Guide: $GuideTitle" -DocumentName $GuideTitle -OutputDirectory $outputDir -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Guide Title: $GuideTitle"
    )

    # Add conditional details
    if ($GuideDescription -ne "") {
        $details += "Description: $GuideDescription"
    }

    if ($GuideCategory -ne "") {
        $details += "Category: $GuideCategory"
    }

    if ($RelatedScript -ne "") {
        $details += "Related Script: $RelatedScript"
    }

    if ($RelatedTasks -ne "") {
        $details += "Related Tasks: $RelatedTasks"
    }

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
            "process-framework/guides/support/guide-creation-best-practices-guide.md",
            "🎯 FOCUS AREAS: 'Step-by-Step Instructions' and 'Quality Assurance' sections",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content."
        )
    }

    # Auto-append entry to PF-documentation-map.md under the correct Guides section
    if ($documentId -or $WhatIfPreference) {
        $projectRoot = Get-ProjectRoot
        $docMapPath = Join-Path -Path $projectRoot -ChildPath "process-framework/PF-documentation-map.md"

        # Derive section header from SubDirectory
        # "01-planning" → "#### 01 - Planning Guides", "support" → "#### Support Guides"
        if ($SubDirectory -match '^(\d{2})-(.+)$') {
            $num = $Matches[1]
            $name = (Get-Culture).TextInfo.ToTitleCase($Matches[2])
            $sectionHeader = "#### $num - $name Guides"
        }
        else {
            $name = (Get-Culture).TextInfo.ToTitleCase($SubDirectory)
            $sectionHeader = "#### $name Guides"
        }

        # Validate SubDirectory against domain-config.json workflow phases
        $domainConfigPath = Join-Path -Path $projectRoot -ChildPath "process-framework/domain-config.json"
        if (Test-Path $domainConfigPath) {
            $domainConfig = Get-Content -Path $domainConfigPath -Raw | ConvertFrom-Json
            $validPhases = @($domainConfig.workflow_phases.values)
            if ($SubDirectory -notin $validPhases -and $SubDirectory -ne "framework") {
                Write-Warning "SubDirectory '$SubDirectory' is not in domain-config.json workflow_phases. Documentation map update may fail."
            }
        }

        $kebabName = ConvertTo-KebabCase -InputString $GuideTitle
        $relativePath = "guides/$SubDirectory/$kebabName.md"
        $description = if ($GuideDescription -ne "") { $GuideDescription } else { "Guide for $GuideTitle" }
        $entryLine = "- [Guide: $GuideTitle]($relativePath) - $description"

        $updated = Add-DocumentationMapEntry -DocMapPath $docMapPath -SectionHeader $sectionHeader -EntryLine $entryLine -CallerCmdlet $PSCmdlet
        if ($updated) {
            $details += "Documentation Map: Updated (section: $sectionHeader)"
        }
    }

    Write-ProjectSuccess -Message "Created guide with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create guide: $($_.Exception.Message)" -ExitCode 1
}
