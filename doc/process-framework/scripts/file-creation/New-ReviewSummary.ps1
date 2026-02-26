# New-ReviewSummary.ps1
# Creates a new Tools Review Summary document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Tools Review Summary document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Tools Review Summary documents by:
    - Generating a unique document ID (ART-REV-XXX)
    - Creating a properly formatted review summary from the standardized template
    - Updating the ID tracker in the central ID registry
    - Using a date-based filename pattern (tools-review-YYYYMMDD.md)

.PARAMETER ReviewDate
    The date of the review in YYYY-MM-DD format. Defaults to today's date.

.PARAMETER FormsAnalyzed
    The number of feedback forms analyzed in this review cycle.

.PARAMETER TaskTypesCovered
    The number of task types covered in this review cycle.

.PARAMETER DateRangeStart
    Start date of the feedback forms date range (YYYY-MM-DD).

.PARAMETER DateRangeEnd
    End date of the feedback forms date range (YYYY-MM-DD).

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor.

.EXAMPLE
    .\New-ReviewSummary.ps1 -FormsAnalyzed 11 -TaskTypesCovered 7 -DateRangeStart '2026-02-21' -DateRangeEnd '2026-02-26'

.EXAMPLE
    .\New-ReviewSummary.ps1 -ReviewDate '2026-02-26' -FormsAnalyzed 11 -TaskTypesCovered 7 -DateRangeStart '2026-02-21' -DateRangeEnd '2026-02-26' -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - Filename format: tools-review-YYYYMMDD.md
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$ReviewDate = (Get-Date -Format 'yyyy-MM-dd'),

    [Parameter(Mandatory=$true)]
    [int]$FormsAnalyzed,

    [Parameter(Mandatory=$true)]
    [int]$TaskTypesCovered,

    [Parameter(Mandatory=$true)]
    [string]$DateRangeStart,

    [Parameter(Mandatory=$true)]
    [string]$DateRangeEnd,

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare custom replacements
$customReplacements = @{
    "# Tools Review Summary — [YYYY-MM-DD]" = "# Tools Review Summary — $ReviewDate"
    "| Forms Analyzed | [N] feedback forms |" = "| Forms Analyzed | $FormsAnalyzed feedback forms |"
    "| Date Range | [start date] to [end date] |" = "| Date Range | $DateRangeStart to $DateRangeEnd |"
    "| Task Types Covered | [N] ([list task IDs]) |" = "| Task Types Covered | $TaskTypesCovered ([list task IDs]) |"
    "| Tools Evaluated | [N]+ unique tools |" = "| Tools Evaluated | [N]+ unique tools |"
}

# Build filename from review date (tools-review-YYYYMMDD.md)
$dateForFilename = $ReviewDate -replace '-', ''
$fileNamePattern = "tools-review-$dateForFilename.md"

# Create the document using standardized process
try {
    $documentId = New-StandardProjectDocument `
        -TemplatePath "doc/process-framework/templates/templates/tools-review-summary-template.md" `
        -IdPrefix "ART-REV" `
        -IdDescription "Tools Review Summary $ReviewDate" `
        -DocumentName "tools-review-$dateForFilename" `
        -OutputDirectory "doc/process-framework/feedback/reviews" `
        -FileNamePattern $fileNamePattern `
        -Replacements $customReplacements `
        -OpenInEditor:$OpenInEditor

    $details = @(
        "Review Date: $ReviewDate",
        "Forms Analyzed: $FormsAnalyzed",
        "Task Types Covered: $TaskTypesCovered",
        "Date Range: $DateRangeStart to $DateRangeEnd"
    )

    if (-not $OpenInEditor) {
        $details += @(
            "",
            "Next steps:",
            "1. Fill in task group analysis sections (one per task type)",
            "2. Add cross-group themes with frequency data",
            "3. Complete improvement opportunities summary table",
            "4. Collect and document human user feedback",
            "5. List archived feedback forms"
        )
    }

    Write-ProjectSuccess -Message "Created review summary with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create review summary: $($_.Exception.Message)" -ExitCode 1
}
