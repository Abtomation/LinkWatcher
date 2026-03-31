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

.PARAMETER FeatureId
    Optional. The feature ID that owns the code being refactored (e.g., "1.1.1", "2.2.1").
    When provided, auto-populates the feature_id frontmatter field and the documentation
    checklist references in the lightweight template so they point to the correct feature's docs.

.PARAMETER Lightweight
    If specified, creates a lightweight refactoring plan using the compact template (PF-TEM-050).
    Use for changes with no architectural impact (any file count, any effort level).
    Only use Standard for refactorings that redesign interfaces, decompose classes, or change architectural patterns.
    Supports batch mode — copy the "Item N" section for multiple quick fixes.
    Mutually exclusive with -DocumentationOnly.

.PARAMETER DocumentationOnly
    If specified, creates a documentation-only refactoring plan using the documentation template (PF-TEM-052).
    Use for refactoring that involves only documentation changes (no code changes, no test impact).
    Removes code metrics, performance benchmarks, and test coverage sections.
    Mutually exclusive with -Lightweight and -Performance.

.PARAMETER Performance
    If specified, creates a performance-focused refactoring plan using the performance template (PF-TEM-066).
    Replaces code quality metrics with performance baselines (I/O counts, timing, throughput, memory).
    Use for refactorings that target measurable performance improvement rather than code quality.
    Mutually exclusive with -Lightweight and -DocumentationOnly.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-RefactoringPlan.ps1 -RefactoringScope "User Authentication Module" -TargetArea "lib/services/auth/"

.EXAMPLE
    .\New-RefactoringPlan.ps1 -RefactoringScope "Database Layer Optimization" -TargetArea "lib/data/" -Priority "High" -OpenInEditor

.EXAMPLE
    .\New-RefactoringPlan.ps1 -RefactoringScope "Replace bare excepts in handler.py (TD011)" -TargetArea "linkwatcher/handler.py" -Lightweight

.EXAMPLE
    .\New-RefactoringPlan.ps1 -RefactoringScope "Extract reference lookup (TD022)" -TargetArea "linkwatcher/handler.py" -Lightweight -FeatureId "1.1.1" -DebtItemId "TD022"

.EXAMPLE
    .\New-RefactoringPlan.ps1 -RefactoringScope "Fix TDD pseudocode drift (TD046)" -TargetArea "doc/product-docs/technical/" -DocumentationOnly -DebtItemId "TD046"

.EXAMPLE
    .\New-RefactoringPlan.ps1 -RefactoringScope "Reduce file I/O in scan cycle (TD030)" -TargetArea "linkwatcher/service.py" -Performance -DebtItemId "TD030"

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
    [string]$FeatureId,

    [Parameter(Mandatory = $false)]
    [switch]$Lightweight,

    [Parameter(Mandatory = $false)]
    [switch]$DocumentationOnly,

    [Parameter(Mandatory = $false)]
    [switch]$Performance,

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

# Validate mutually exclusive switches
$modeCount = @($Lightweight, $DocumentationOnly, $Performance).Where({ $_ }).Count
if ($modeCount -gt 1) {
    Write-Error "-Lightweight, -DocumentationOnly, and -Performance are mutually exclusive. Use at most one."
    exit 1
}

# Select template based on mode switches
if ($Lightweight) {
    $templatePath = "process-framework/templates/06-maintenance/lightweight-refactoring-plan-template.md"
    $modeLabel = "Lightweight"
} elseif ($DocumentationOnly) {
    $templatePath = "process-framework/templates/06-maintenance/documentation-refactoring-plan-template.md"
    $modeLabel = "Documentation-only"
} elseif ($Performance) {
    $templatePath = "process-framework/templates/06-maintenance/performance-refactoring-plan-template.md"
    $modeLabel = "Performance"
} else {
    $templatePath = "process-framework/templates/06-maintenance/refactoring-plan-template.md"
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
if ($DocumentationOnly) {
    $additionalMetadataFields["mode"] = "documentation-only"
}
if ($Performance) {
    $additionalMetadataFields["mode"] = "performance"
}
if ($DebtItemId) {
    $additionalMetadataFields["debt_item"] = $DebtItemId
}
if ($FeatureId) {
    $additionalMetadataFields["feature_id"] = $FeatureId
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
    "[Feature ID]"        = if ($FeatureId) { $FeatureId } else { "[Feature ID]" }
}

# Create the document using standardized process
try {
    # Use DirectoryType for ID registry-based directory resolution
    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PD-REF" -IdDescription "Refactoring Plan: $RefactoringScope" -DocumentName $RefactoringScope -DirectoryType "plans" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

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
    if ($FeatureId) {
        $details += "Feature: $FeatureId"
    }

    # Add next steps if not opening in editor
    if (-not $OpenInEditor) {
        if ($Lightweight) {
            $details += @(
                "",
                "📝 Lightweight plan created. Fill in Item sections (and optional Dependencies section for multi-file changes), then update Documentation & State Updates checklist for each item."
            )
        } elseif ($DocumentationOnly) {
            $details += @(
                "",
                "📝 Documentation-only plan created. Code metrics, test coverage, and performance sections have been removed.",
                "   Fill in documentation quality baseline, affected documents, and verification approach."
            )
        } elseif ($Performance) {
            $details += @(
                "",
                "📝 Performance plan created. Code quality metrics replaced with performance baselines (I/O, timing, throughput, memory).",
                "   Fill in performance baseline measurements, targets, and optimization techniques."
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
                "process-framework/guides/06-maintenance/code-refactoring-task-usage-guide.md",
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
