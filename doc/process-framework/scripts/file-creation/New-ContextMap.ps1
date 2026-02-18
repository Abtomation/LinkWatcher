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
    [switch]$OpenInEditor
)

# Import the common helpers with robust path resolution
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "../Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
}
catch {
    Write-Error "Failed to import Common-ScriptHelpers module from: $modulePath"
    Write-Error "Resolved script directory: $scriptDir"
    Write-Error "Error: $_"
    exit 1
}

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "task_name"          = ConvertTo-KebabCase -InputString $TaskName
    "workflow_phase"     = $WorkflowPhase
    "map_type"           = "Context Map"
    "visualization_type" = "Task Context"
}

# Prepare custom replacements based on the context map template
$customReplacements = @{
    "[Task Name]"                                                                                            = $TaskName
    "[Task Type]"                                                                                            = $WorkflowPhase
    "[Brief description of what this context map visualizes and its purpose in the task execution process.]" = if ($MapDescription -ne "") { $MapDescription } else { "Context map for $TaskName task showing component relationships and dependencies." }
    "[Date]"                                                                                                 = Get-Date -Format "yyyy-MM-dd"
}

# Set output directory based on workflow phase
$outputDirectory = "doc/process-framework/visualization/context-maps/$WorkflowPhase"

# Create the document using standardized process
try {
    $mapId = New-StandardProjectDocument -TemplatePath "doc/process-framework/templates/templates/context-map-template.md" -IdPrefix "PF-VIS" -IdDescription "Context map for ${WorkflowPhase}: ${TaskName}" -DocumentName "$($TaskName.ToLower().Replace(' ', '-'))-map" -OutputDirectory $outputDirectory -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

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
            "   doc/process-framework/guides/guides/visualization-creation-guide.md",
            "   doc/process-framework/guides/guides/visual-notation-guide.md",
            "🎯 FOCUS AREAS: 'Context Map Development' section",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content."
        )
    }

    Write-ProjectSuccess -Message "Created context map with ID: $mapId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create context map: $($_.Exception.Message)" -ExitCode 1
}
