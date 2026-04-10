# New-ContextMap.ps1
# Creates a new context map visualization with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new context map visualization document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates context map visualization documents by:
    - Generating a unique document ID (PF-VIS-XXX)
    - Creating a properly formatted context map file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for task context visualization

.PARAMETER TaskName
    The name of the task this context map is for (e.g., "Feature Implementation", "Bug Fixing")

.PARAMETER WorkflowPhase
    The workflow phase directory where the context map belongs. Valid values:
    - "01-planning", "02-design", "03-testing", "04-implementation", "05-validation", "06-maintenance", "07-deployment"
    - "cyclical" (for recurring tasks)
    - "support" (for supporting/infrastructure tasks)

.PARAMETER MapDescription
    Brief description of what the context map visualizes

.PARAMETER RelatedTask
    The PF-TSK-### ID of the task this context map belongs to (e.g., "PF-TSK-028")

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    ../../../../visualization/New-ContextMap.ps1 -TaskName "User Authentication" -WorkflowPhase "02-design" -MapDescription "Context map for user authentication task"

.EXAMPLE
    ../../../../visualization/New-ContextMap.ps1 -TaskName "UI Design" -WorkflowPhase "02-design" -MapDescription "Context map for UI/UX design task"

.EXAMPLE
    ../../../../visualization/New-ContextMap.ps1 -TaskName "Documentation Review" -WorkflowPhase "cyclical" -MapDescription "Context map for recurring documentation reviews" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Template Metadata:
    - Template ID: PF-TEM-XXX
    - Template Type: Context Map Creation Script
    - Created: 2025-07-11
    - For: Creating context map visualizations for tasks
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("01-planning", "02-design", "03-testing", "04-implementation", "05-validation", "06-maintenance", "07-deployment", "cyclical", "support")]
    [string]$WorkflowPhase,

    [Parameter(Mandatory = $false)]
    [string]$MapDescription = "",

    [Parameter(Mandatory = $false)]
    [string]$RelatedTask = "",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers with walk-up path resolution
$dir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
try {
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers module. Searched up from: $PSScriptRoot"
    exit 1
}

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields (IMP-376: removed redundant task_name, map_type, visualization_type)
$additionalMetadataFields = @{
    "workflow_phase" = $WorkflowPhase
}

# Add related task if provided
if ($RelatedTask -ne "") {
    $additionalMetadataFields["related_task"] = $RelatedTask
}

# Prepare custom replacements based on the context map template
$customReplacements = @{
    "[Task Name]"                                                                                            = $TaskName
    "[Task Type]"                                                                                            = $WorkflowPhase
    "[Brief description of what this context map visualizes and its purpose in the task execution process.]" = if ($MapDescription -ne "") { $MapDescription } else { "Context map for $TaskName task showing component relationships and dependencies." }
    "[Date]"                                                                                                 = Get-Date -Format "yyyy-MM-dd"
}

# Set output directory based on workflow phase
$outputDirectory = "process-framework/visualization/context-maps/$WorkflowPhase"

# Create the document using standardized process
try {
    # IMP-407: Auto-append "-map" suffix with double-suffix guard
    $mapDocName = $TaskName.ToLower().Replace(' ', '-')
    if ($mapDocName -notmatch '-map$') { $mapDocName = "$mapDocName-map" }
    $mapId = New-StandardProjectDocument -TemplatePath "process-framework/templates/support/context-map-template.md" -IdPrefix "PF-VIS" -IdDescription "Context map for ${WorkflowPhase}: ${TaskName}" -DocumentName $mapDocName -OutputDirectory $outputDirectory -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Task Name: $TaskName",
        "Workflow Phase: $WorkflowPhase"
    )

    $details += "Output Directory: $outputDirectory"

    # Add conditional details
    if ($MapDescription -ne "") {
        $details += "Description: $MapDescription"
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
            "process-framework/guides/support/visualization-creation-guide.md",
            "process-framework/guides/support/visual-notation-guide.md",
            "🎯 FOCUS AREAS: 'Context Map Development' section",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content."
        )
    }

    # Auto-append entry to PF-documentation-map.md under the correct Context Maps section
    if ($mapId -or $WhatIfPreference) {
        $projectRoot = Get-ProjectRoot
        $docMapPath = Join-Path -Path $projectRoot -ChildPath "process-framework/PF-documentation-map.md"

        # Derive section header from WorkflowPhase
        if ($WorkflowPhase -match '^(\d{2})-(.+)$') {
            $num = $Matches[1]
            $phaseName = (Get-Culture).TextInfo.ToTitleCase($Matches[2])
            $sectionHeader = "#### $num - $phaseName Context Maps"
        }
        else {
            $phaseName = (Get-Culture).TextInfo.ToTitleCase($WorkflowPhase)
            $sectionHeader = "#### $phaseName Context Maps"
        }

        # IMP-407: Reuse guarded name from above
        $mapFileName = "$mapDocName.md"
        $relativePath = "visualization/context-maps/$WorkflowPhase/$mapFileName"
        $description = if ($MapDescription -ne "") { $MapDescription } else { "Components for $TaskName task" }
        $entryLine = "- [$TaskName Map]($relativePath) - $description"

        $updated = Add-DocumentationMapEntry -DocMapPath $docMapPath -SectionHeader $sectionHeader -EntryLine $entryLine -CallerCmdlet $PSCmdlet
        if ($updated) {
            $details += "Documentation Map: Updated (section: $sectionHeader)"
        }
    }

    Write-ProjectSuccess -Message "Created context map with ID: $mapId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create context map: $($_.Exception.Message)" -ExitCode 1
}
