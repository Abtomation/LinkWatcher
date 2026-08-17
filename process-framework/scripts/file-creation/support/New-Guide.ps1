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
    Brief description of what the guide helps accomplish. Stamped into the `description:`
    frontmatter (which drives PF-documentation-map.md) and the body Overview. When omitted,
    the frontmatter still carries an empty `description: ""` so every guide shares one structure.

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
    Constrained by ValidateSet to the known guide subdirectories: "00-setup", "01-planning",
    "02-design", "03-testing", "04-implementation", "05-validation", "06-maintenance",
    "07-deployment", "cyclical", "framework", "support". (Mirrors New-Task.ps1 -WorkflowPhase
    and New-Template.ps1 -OutputDirectory.)

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    New-Guide.ps1 -GuideTitle "API Integration Setup" -SubDirectory "02-design" -GuideDescription "Step-by-step guide for integrating third-party APIs"

.EXAMPLE
    New-Guide.ps1 -GuideTitle "Testing Best Practices" -SubDirectory "03-testing" -GuideDescription "Comprehensive guide for writing effective tests" -GuideCategory "Development Process" -OpenInEditor

.EXAMPLE
    New-Guide.ps1 -GuideTitle "Debt Item Creation Guide" -SubDirectory "cyclical" -GuideDescription "Guide for customizing technical debt item templates" -RelatedScript "New-DebtItem.ps1" -RelatedTasks "PF-TSK-023"

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
    [ValidateSet('00-setup','01-planning','02-design','03-testing','04-implementation','05-validation','06-maintenance','07-deployment','cyclical','framework','support')]
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

# Init, soak opt-in, the New-StandardProjectDocument call, try/catch, and the success/error
# report are all owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This
# script keeps only its param block (above), the guide-specific data, and the report hint.

# Prepare additional metadata fields (IMP-376: removed redundant guide_* fields).
# Values are passed raw — the shared frontmatter writer makes every string metadata value
# YAML-safe itself (ConvertTo-YamlSafeScalar, PF-IMP-1413; caller-side pre-quoting removed
# per PF-IMP-1524).
# `description` is always emitted — the supplied text, or "" when none was given — so every
# guide's frontmatter carries the same structure and Build-DocumentationMap.ps1 indexes the
# guide with its real one-line description (PF-IMP-1193). An empty value still registers as
# "missing" in the doc map's -ReportMissing gate. The related_* fields stay optional/omitted.
$additionalMetadataFields = @{
    description = $GuideDescription
}
if ($RelatedScript -ne "") { $additionalMetadataFields["related_script"] = $RelatedScript }
if ($RelatedTasks -ne "")  { $additionalMetadataFields["related_task"]  = $RelatedTasks }

# Prepare custom replacements based on the guide template
$customReplacements = @{
    "[Guide Title]"                                                                                                                            = $GuideTitle
    "[Brief description of what this guide helps the user accomplish. Keep it to 2-3 sentences that clearly explain the purpose and outcome.]" = if ($GuideDescription -ne "") { $GuideDescription } else { "[Brief description of what this guide helps the user accomplish. Keep it to 2-3 sentences that clearly explain the purpose and outcome.]" }
    "[Optional: Script name this guide relates to]"                                                                                            = if ($RelatedScript -ne "") { $RelatedScript } else { "" }
    "[Optional: Comma-separated task IDs this guide relates to]"                                                                               = if ($RelatedTasks -ne "") { $RelatedTasks } else { "" }
    "[Date]"                                                                                                                                   = Get-Date -Format "yyyy-MM-dd"
    "[Author name or team]"                                                                                                                    = "AI Agent & Human Partner"
}

# IMP-407: Auto-append "-guide" suffix with double-suffix guard
$guideDocName = $GuideTitle
if ($guideDocName -notmatch '(?i)[-\s]guide$') {
    $guideDocName = "$guideDocName-guide"
}

# Success-report detail lines (preserves the legacy reporting verbatim)
$details = @("Guide Title: $GuideTitle")
if ($GuideDescription -ne "") { $details += "Description: $GuideDescription" }
if ($GuideCategory -ne "")    { $details += "Category: $GuideCategory" }
if ($RelatedScript -ne "")    { $details += "Related Script: $RelatedScript" }
if ($RelatedTasks -ne "")     { $details += "Related Tasks: $RelatedTasks" }
# Add mandatory guide consultation if not opening in editor
if (-not $OpenInEditor) {
    $details += "Customization required — see process-framework/guides/support/guide-creation-best-practices-guide.md"
}

# PF-documentation-map.md is generated from each artifact's `description:` frontmatter
# by Build-DocumentationMap.ps1 (PF-PRO-037) — no per-creation append needed.

# IMP-568: -DirectoryType "main" + -Subdirectory (not a hand-built -OutputDirectory)
# P-12a (PF-PRO-068): the shipped-pool family comes from the workspace's declared
# artifact_prefix ('PF' at appdev, 'FB' at FB); a leaf role throws by contract.
$artifactFamily = Get-ArtifactPrefix
$documentId = New-FrameworkDocument `
    -TemplatePath (Join-Path (Get-ProcessFrameworkPath) "templates/support/guide-template.md") `
    -IdPrefix "$artifactFamily-GDE" -IdDescription "Guide: $GuideTitle" -DocumentName $guideDocName `
    -DirectoryType "main" -Subdirectory $SubDirectory `
    -Replacements $customReplacements -Metadata $additionalMetadataFields `
    -Label "guide" -OpenInEditor:$OpenInEditor

Write-ProjectSuccess -Message "Created guide with ID: $documentId" -Details $details
