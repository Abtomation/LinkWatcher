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

.PARAMETER DebtItemId
    Optional. The tech debt item ID that triggered this refactoring (e.g., "TD007", "PF-TDI-003").
    When provided, auto-populates the debt_item frontmatter field and a "Debt Item" line in the plan body.

.PARAMETER Lightweight
    If specified, creates a lightweight refactoring plan using the compact template (PF-TEM-050).
    Use for low-effort items: ≤15 min effort, single file, no architectural impact.
    Supports batch mode — copy the "Item N" section for multiple quick fixes.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-RefactoringPlan.ps1 -RefactoringScope "User Authentication Module" -TargetArea "lib/services/auth/"

.EXAMPLE
    .\New-RefactoringPlan.ps1 -RefactoringScope "Database Layer Optimization" -TargetArea "lib/data/" -Priority "High" -OpenInEditor

.EXAMPLE
    .\New-RefactoringPlan.ps1 -RefactoringScope "Replace bare excepts in handler.py (TD011)" -TargetArea "linkwatcher/handler.py" -Lightweight

.EXAMPLE
    .\New-RefactoringPlan.ps1 -RefactoringScope "Decompose God Class (TD005)" -TargetArea "linkwatcher/handler.py" -Priority "High" -DebtItemId "TD005 (PF-TDI-001)"

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
    [string]$DebtItemId,

    [Parameter(Mandatory = $false)]
    [switch]$Lightweight,

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

# Select template based on -Lightweight switch
if ($Lightweight) {
    $templatePath = "doc/process-framework/templates/templates/lightweight-refactoring-plan-template.md"
    $modeLabel = "Lightweight"
} else {
    $templatePath = "doc/process-framework/templates/templates/refactoring-plan-template.md"
    $modeLabel = "Standard"
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "refactoring_scope" = $RefactoringScope
    "target_area"       = $TargetArea
    "priority"          = $Priority
}
if ($Lightweight) {
    $additionalMetadataFields["mode"] = "lightweight"
}
if ($DebtItemId) {
    $additionalMetadataFields["debt_item"] = $DebtItemId
}

# Prepare custom replacements for the template
$debtItemLine = if ($DebtItemId) { "- **Debt Item**: $DebtItemId`n" } else { "" }
$customReplacements = @{
    "[Refactoring Scope]" = $RefactoringScope
    "[Target Area]"       = $TargetArea
    "[Priority Level]"    = $Priority
    "[Creation Date]"     = Get-Date -Format "yyyy-MM-dd"
    "[Author]"            = "AI Agent & Human Partner"
    "[Debt Item Line]"    = $debtItemLine
}

# Create the document using standardized process
try {
    # Use DirectoryType for ID registry-based directory resolution
    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-REF" -IdDescription "Refactoring Plan: $RefactoringScope" -DocumentName $RefactoringScope -DirectoryType "plans" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Mode: $modeLabel",
        "Refactoring Scope: $RefactoringScope",
        "Target Area: $TargetArea",
        "Priority: $Priority"
    )
    if ($DebtItemId) {
        $details += "Debt Item: $DebtItemId"
    }

    # Add next steps if not opening in editor
    if (-not $OpenInEditor) {
        if ($Lightweight) {
            $details += @(
                "",
                "📝 Lightweight plan created. Fill in Item sections, then update Documentation & State Updates checklist for each item."
            )
        } else {
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
    }

    Write-ProjectSuccess -Message "Created $modeLabel Refactoring Plan with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Refactoring Plan: $($_.Exception.Message)" -ExitCode 1
}
