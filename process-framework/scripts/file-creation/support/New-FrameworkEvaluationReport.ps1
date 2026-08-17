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
    Valid values: Completeness, Consistency, Redundancy, Accuracy, Effectiveness, Automation Coverage, Scalability
    (space-separated display names and the joined forms are both accepted). A comma-joined single
    string ("Completeness,Automation Coverage") is split in place, so the parameter survives
    pwsh -File invocation (PF-IMP-1428 pattern).

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    New-FrameworkEvaluationReport.ps1 -EvaluationScope "Full framework review"

.EXAMPLE
    New-FrameworkEvaluationReport.ps1 -EvaluationScope "03-testing tasks and scripts" -Dimensions Completeness,Consistency,Accuracy

.EXAMPLE
    pwsh.exe -ExecutionPolicy Bypass -File New-FrameworkEvaluationReport.ps1 -EvaluationScope "Support tasks" -Dimensions "Completeness,Automation Coverage"

.EXAMPLE
    New-FrameworkEvaluationReport.ps1 -EvaluationScope "03-testing tasks and scripts" -OpenInEditor

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

# Init, soak opt-in, the New-StandardProjectDocument call, and the create-failure error path are
# owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This Tier-3 script keeps
# its data, its bespoke post-creation dimension-filtering, and its own report — inline.

function ConvertTo-CanonicalDimensions {
    # Normalizes -Dimensions input to the canonical joined dimension names: accepts the
    # space-separated display names ("Automation Coverage") alongside the joined forms, and
    # splits comma-joined single-string input in place so the [string[]] parameter survives
    # pwsh -File invocation, which binds an array argument as one literal token
    # (PF-IMP-1428 / PF-IMP-1668). Validation lives here rather than in a ValidateSet
    # because ValidateSet fires per element before the body could split.
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Dimensions
    )

    $validDimensions = @("Completeness", "Consistency", "Redundancy", "Accuracy", "Effectiveness", "AutomationCoverage", "Scalability")
    $normalized = @($Dimensions -split ',' |
        ForEach-Object { $_ -replace '\s', '' } |
        Where-Object { $_ -ne '' } |
        ForEach-Object {
            $token = $_
            $canonical = @($validDimensions | Where-Object { $_ -ieq $token })[0]
            if (-not $canonical) {
                throw "Unknown dimension '$token'. Accepted values (space-separated display names also work): $($validDimensions -join ', ')"
            }
            $canonical
        })
    if ($normalized.Count -eq 0) {
        throw "-Dimensions was supplied but contained no dimension names. Accepted values: $($validDimensions -join ', ')"
    }
    return $normalized
}

function Remove-UnselectedDimensionContent {
    # Filters a freshly created evaluation report down to the selected dimensions: drops each
    # unselected dimension's summary-table row and detailed findings section, then renumbers
    # the survivors 1..N. Pure — takes and returns content, touches no files — so it unit-tests
    # in-process through the dot-source guard below (PF-IMP-1693).
    #
    # Every removal is anchored by BOTH the dimension number and its display name. Anchoring on
    # the number alone made the summary-row removal a document-wide match: excluding dimension 1
    # deleted every '| 1 |' row in the report, taking the Artifacts in Scope, Improvement
    # Recommendations, Findings Resolved In-Session and Withdrawn During Verification placeholder
    # rows with it (PF-IMP-1693; latent since -Dimensions landed in PF-IMP-514).
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string[]]$Dimensions
    )

    # Map dimension names to their template numbers and display names
    $dimMap = [ordered]@{
        "Completeness"      = @{ Number = 1; Display = "Completeness";        FindingPrefix = "C" }
        "Consistency"       = @{ Number = 2; Display = "Consistency";         FindingPrefix = "N" }
        "Redundancy"        = @{ Number = 3; Display = "Redundancy";          FindingPrefix = "R" }
        "Accuracy"          = @{ Number = 4; Display = "Accuracy";            FindingPrefix = "A" }
        "Effectiveness"     = @{ Number = 5; Display = "Effectiveness";       FindingPrefix = "E" }
        "AutomationCoverage"= @{ Number = 6; Display = "Automation Coverage"; FindingPrefix = "U" }
        "Scalability"       = @{ Number = 7; Display = "Scalability";         FindingPrefix = "S" }
    }

    $excluded = @($dimMap.Keys | Where-Object { $_ -notin $Dimensions })
    if ($excluded.Count -eq 0) { return $Content }

    foreach ($dim in $excluded) {
        $num = $dimMap[$dim].Number
        $display = [regex]::Escape($dimMap[$dim].Display)

        # Remove the summary-table row — anchored by number AND display name, so rows in other
        # tables that merely start with the same number are untouched.
        $Content = $Content -replace "(?m)^\| $num \| $display \|[^\r\n]*\r?\n", ""

        # Remove the detailed findings section: '### N. Name' through the next --- separator,
        # falling back to the next ## heading for the last dimension (no --- follows it).
        $pattern = "(?ms)### $num\. $display[^\r\n]*\r?\n.*?(?=\r?\n---\r?\n)\r?\n---\r?\n(\r?\n)*"
        if ($Content -match $pattern) {
            $Content = $Content -replace $pattern, ""
        } else {
            $Content = $Content -replace "(?ms)### $num\. $display[^\r\n]*\r?\n.*?(?=\r?\n## )", "`n"
        }
    }

    # Renumber remaining summary table rows and detailed sections
    $newNum = 1
    foreach ($dim in $dimMap.Keys) {
        if ($dim -in $Dimensions) {
            $oldNum = $dimMap[$dim].Number
            if ($oldNum -ne $newNum) {
                $displayName = $dimMap[$dim].Display
                $Content = $Content -replace "(?m)^\| $oldNum \| $displayName", "| $newNum | $displayName"
                $Content = $Content -replace "(?m)^### $oldNum\. $displayName", "### $newNum. $displayName"
            }
            $newNum++
        }
    }

    return $Content
}

# Dot-source guard: `. $script -EvaluationScope x` loads the helper for unit tests and
# returns before the document-creation body (New-ReviewSummary.ps1 pattern).
if ($MyInvocation.InvocationName -eq '.') { return }

try {
    if ($Dimensions) {
        $Dimensions = @(ConvertTo-CanonicalDimensions -Dimensions $Dimensions)
    }

    # Phase 7 (2026-05-11): template path resolved via configurable paths.process_framework;
    # output writes to appdev/process-framework-central/evaluation-reports/ regardless of cwd.
    $processFrameworkDir = Get-ProcessFrameworkPath
    $templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates/support/framework-evaluation-report-template.md"

    # Phase 7: project_id stamping in frontmatter
    $projectId = $null
    try {
        $cfg = Get-ProjectConfig
        if ($cfg.project_id) { $projectId = $cfg.project_id }
    } catch {
        Write-Verbose "New-FrameworkEvaluationReport: could not read doc/project-config.json; project_id will be null."
    }

    # Generate date for filename
    $dateStamp = Get-Date -Format "yyyyMMdd"

    # Create a slug from the scope for the filename via the canonical helper
    # from Common-ScriptHelpers/Naming.psm1 (PF-IMP-008), then cap at 50 chars.
    $cleanScope = ConvertTo-FeatureSlug -Name $EvaluationScope -Convention 'kebab-case'
    $scopeSlug = $cleanScope.Substring(0, [Math]::Min(50, $cleanScope.Length)).TrimEnd('-')

    # Prepare custom replacements
    $customReplacements = @{
        "[Evaluation Scope]" = $EvaluationScope
    }

    # Prepare additional metadata fields
    $additionalMetadataFields = @{
        "evaluation_scope" = $EvaluationScope
        "project_id"       = $(if ($projectId) { $projectId } else { "null" })
    }

    $outputDir = Join-Path -Path (Get-CentralFrameworkPath) -ChildPath "evaluation-reports"

    # Create document using standardized process
    $documentId = New-FrameworkDocument `
        -TemplatePath $templatePath `
        -IdPrefix "PF-EVR" `
        -IdDescription "Framework Evaluation: ${EvaluationScope}" `
        -DocumentName $EvaluationScope `
        -OutputDirectory $outputDir `
        -Replacements $customReplacements `
        -Metadata $additionalMetadataFields `
        -FileNamePattern "$dateStamp-framework-evaluation-$scopeSlug.md" `
        -Label "Framework Evaluation Report" `
        -OpenInEditor:$OpenInEditor

    # Post-process: remove unselected dimensions if -Dimensions was specified.
    # The filtering itself lives in Remove-UnselectedDimensionContent (above the dot-source
    # guard, so it is unit-testable); this block only resolves the file and writes the result.
    if ($documentId -and $Dimensions) {
        # Find the created file (Phase 7: central evaluation-reports)
        $createdFile = Get-ChildItem $outputDir -Filter "*$scopeSlug*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

        if ($createdFile) {
            $content = Get-Content $createdFile.FullName -Raw
            $filtered = Remove-UnselectedDimensionContent -Content $content -Dimensions $Dimensions

            if ($filtered -ne $content) {
                if ($PSCmdlet.ShouldProcess($createdFile.FullName, "Filter dimensions to: $($Dimensions -join ', ')")) {
                    Set-Content -Path $createdFile.FullName -Value $filtered -NoNewline
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
