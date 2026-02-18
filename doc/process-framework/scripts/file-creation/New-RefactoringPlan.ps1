# New-RefactoringPlan.ps1
# Creates a new Refactoring Plan document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Refactoring Plan document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Refactoring Plan documents by:
    - Generating a unique document ID (PF-REF-XXX)
    - Creating a properly formatted document file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for refactoring planning and tracking

.PARAMETER RefactoringScope
    Brief description of the refactoring scope (e.g., "User Authentication Module", "Database Layer Optimization")

.PARAMETER TargetArea
    Specific component, module, or code area being refactored

.PARAMETER Priority
    Priority level of the refactoring (High, Medium, Low). Defaults to "Medium"

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    ../../../../../../refactoring/New-RefactoringPlan.ps1 -RefactoringScope "User Authentication Module" -TargetArea "lib/services/auth/"

.EXAMPLE
    ../../../../../../refactoring/New-RefactoringPlan.ps1 -RefactoringScope "Database Layer Optimization" -TargetArea "lib/data/" -Priority "High" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Script Metadata:
    - Script Type: Document Creation Script
    - Created: 2025-07-21
    - For: Creating refactoring plan documents for the Code Refactoring Task
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$RefactoringScope,

    [Parameter(Mandatory = $true)]
    [string]$TargetArea,

    [Parameter(Mandatory = $false)]
    [ValidateSet("High", "Medium", "Low")]
    [string]$Priority = "Medium",

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
    Write-Error "Please ensure the script is run from the correct directory or the module path is correct."
    exit 1
}

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "refactoring_scope" = $RefactoringScope
    "target_area"       = $TargetArea
    "priority"          = $Priority
}

# Prepare custom replacements for the template
$customReplacements = @{
    "[Refactoring Scope]" = $RefactoringScope
    "[Target Area]"       = $TargetArea
    "[Priority Level]"    = $Priority
    "[Creation Date]"     = Get-Date -Format "yyyy-MM-dd"
    "[Author]"            = "AI Agent & Human Partner"
}

# Create the document using standardized process
try {
    # Use DirectoryType for ID registry-based directory resolution
    $documentId = New-StandardProjectDocument -TemplatePath "doc/process-framework/templates/templates/refactoring-plan-template.md" -IdPrefix "PF-REF" -IdDescription "Refactoring Plan: $RefactoringScope" -DocumentName $RefactoringScope -DirectoryType "plans" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Refactoring Scope: $RefactoringScope",
        "Target Area: $TargetArea",
        "Priority: $Priority"
    )

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
            "   doc/process-framework/guides/guides/code-refactoring-task-usage-guide.md",
            "🎯 FOCUS AREAS: 'Refactoring Plan Development' section",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content."
        )
    }

    Write-ProjectSuccess -Message "Created Refactoring Plan with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Refactoring Plan: $($_.Exception.Message)" -ExitCode 1
}
