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

.PARAMETER Dimensions
    Optional list of dimensions to include in the report. When omitted, all 7 dimensions are included.
    Valid values: Completeness, Consistency, Redundancy, Accuracy, Effectiveness, AutomationCoverage, Scalability

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-FrameworkEvaluationReport.ps1 -EvaluationScope "Full framework review"

.EXAMPLE
    .\New-FrameworkEvaluationReport.ps1 -EvaluationScope "03-testing tasks and scripts" -Dimensions Completeness,Consistency,Accuracy

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
    [ValidateSet("Completeness", "Consistency", "Redundancy", "Accuracy", "Effectiveness", "AutomationCoverage", "Scalability")]
    [string[]]$Dimensions,

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
    $templatePath = Join-Path $projectRoot "process-framework/templates/support/framework-evaluation-report-template.md"

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

    # Post-process: remove unselected dimensions if -Dimensions was specified
    if ($documentId -and $Dimensions) {
        # Map dimension names to their template numbers and display names
        $dimMap = [ordered]@{
            "Completeness"      = @{ Number = 1; Display = "Completeness";      FindingPrefix = "C" }
            "Consistency"       = @{ Number = 2; Display = "Consistency";        FindingPrefix = "N" }
            "Redundancy"        = @{ Number = 3; Display = "Redundancy";         FindingPrefix = "R" }
            "Accuracy"          = @{ Number = 4; Display = "Accuracy";           FindingPrefix = "A" }
            "Effectiveness"     = @{ Number = 5; Display = "Effectiveness";      FindingPrefix = "E" }
            "AutomationCoverage"= @{ Number = 6; Display = "Automation Coverage"; FindingPrefix = "U" }
            "Scalability"       = @{ Number = 7; Display = "Scalability";        FindingPrefix = "S" }
        }

        $excludeNumbers = @()
        foreach ($dim in $dimMap.Keys) {
            if ($dim -notin $Dimensions) {
                $excludeNumbers += $dimMap[$dim].Number
            }
        }

        if ($excludeNumbers.Count -gt 0) {
            # Find the created file
            $outputDir = Join-Path $projectRoot "process-framework-local/evaluation-reports"
            $createdFile = Get-ChildItem $outputDir -Filter "*$scopeSlug*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

            if ($createdFile) {
                $content = Get-Content $createdFile.FullName -Raw

                # Remove rows from the summary table for excluded dimensions
                foreach ($num in $excludeNumbers) {
                    $content = $content -replace "(?m)^\| $num \|[^\r\n]*\r?\n", ""
                }

                # Remove detailed finding sections for excluded dimensions
                foreach ($num in $excludeNumbers) {
                    # Match ### N. Name through the next --- separator and trailing blank lines
                    $content = $content -replace "(?ms)### $num\. [^\r\n]+\r?\n.*?(?=\r?\n---\r?\n)\r?\n---\r?\n(\r?\n)*", ""
                }

                # Renumber remaining summary table rows and detailed sections
                $newNum = 1
                foreach ($dim in $dimMap.Keys) {
                    if ($dim -in $Dimensions) {
                        $oldNum = $dimMap[$dim].Number
                        if ($oldNum -ne $newNum) {
                            $displayName = $dimMap[$dim].Display
                            # Renumber summary table row
                            $content = $content -replace "(?m)^\| $oldNum \| $displayName", "| $newNum | $displayName"
                            # Renumber detailed section header
                            $content = $content -replace "(?m)^### $oldNum\. $displayName", "### $newNum. $displayName"
                        }
                        $newNum++
                    }
                }

                if ($PSCmdlet.ShouldProcess($createdFile.FullName, "Filter dimensions to: $($Dimensions -join ', ')")) {
                    Set-Content -Path $createdFile.FullName -Value $content -NoNewline
                }
            }
        }
    }

    if ($documentId) {
        $details = @(
            "Evaluation Scope: $EvaluationScope"
        )
        if ($Dimensions) {
            $details += "Dimensions: $($Dimensions -join ', ')"
        }

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
