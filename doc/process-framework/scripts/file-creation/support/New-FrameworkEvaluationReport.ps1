# New-FrameworkEvaluationReport.ps1
# Creates a new Framework Evaluation Report with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Framework Evaluation Report document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Framework Evaluation Report documents by:
    - Generating a unique document ID (PF-EVR-XXX)
    - Creating a properly formatted document file from the evaluation report template
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for structured framework evaluation

.PARAMETER EvaluationScope
    Description of what is being evaluated (e.g., "Full framework", "03-testing tasks", "All templates")

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-FrameworkEvaluationReport.ps1 -EvaluationScope "Full framework review"

.EXAMPLE
    .\New-FrameworkEvaluationReport.ps1 -EvaluationScope "03-testing tasks and scripts" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$EvaluationScope,

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

try {
    # Get project root for dynamic path resolution
    $projectRoot = Get-ProjectRoot
    $templatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/framework-evaluation-report-template.md"

    # Generate date for filename
    $dateStamp = Get-Date -Format "yyyyMMdd"

    # Create a slug from the scope for the filename
    $cleanScope = $EvaluationScope.ToLower() -replace '[^a-z0-9\s]', '' -replace '\s+', '-'
    $scopeSlug = $cleanScope.Substring(0, [Math]::Min(50, $cleanScope.Length))

    # Prepare custom replacements
    $customReplacements = @{
        "[Evaluation Scope]" = $EvaluationScope
    }

    # Prepare additional metadata fields
    $additionalMetadataFields = @{
        "evaluation_scope" = $EvaluationScope
    }

    # Create document using standardized process
    $documentId = New-StandardProjectDocument `
        -TemplatePath $templatePath `
        -IdPrefix "PF-EVR" `
        -IdDescription "Framework Evaluation: ${EvaluationScope}" `
        -DocumentName $EvaluationScope `
        -DirectoryType "main" `
        -Replacements $customReplacements `
        -AdditionalMetadataFields $additionalMetadataFields `
        -FileNamePattern "$dateStamp-framework-evaluation-$scopeSlug.md" `
        -OpenInEditor:$OpenInEditor

    if ($documentId) {
        $details = @(
            "Evaluation Scope: $EvaluationScope"
        )

        if (-not $OpenInEditor) {
            $details += @(
                "",
                "Next steps:",
                "1. Customize the report with evaluation findings for each dimension",
                "2. Fill in dimension scores and supporting evidence",
                "3. Add improvement recommendations and register IMP entries"
            )
        }

        Write-ProjectSuccess -Message "Created Framework Evaluation Report with ID: $documentId" -Details $details
    }
}
catch {
    Write-ProjectError -Message "Failed to create Framework Evaluation Report: $($_.Exception.Message)" -ExitCode 1
}
