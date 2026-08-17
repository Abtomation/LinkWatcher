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
    - Using a timestamped filename pattern (tools-review-YYYYMMDD-HHMMSS.md)

.PARAMETER ReviewDate
    The date of the review in YYYY-MM-DD format. Defaults to today's date.

.PARAMETER FormsAnalyzed
    The number of feedback forms analyzed in this review cycle.

.PARAMETER DateRangeStart
    Start date of the feedback forms date range (YYYY-MM-DD).

.PARAMETER DateRangeEnd
    End date of the feedback forms date range (YYYY-MM-DD).

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor.

.PARAMETER FormsList
    Optional array of analyzed feedback-form filenames. When supplied, the Archived Forms
    table is auto-populated: the Form column gets each filename and the Task column is
    derived from the PF-TSK-NNN token in the name (Context is left as a placeholder to fill
    during finalization). When omitted, the template's placeholder row is left untouched.

.EXAMPLE
    New-ReviewSummary.ps1 -FormsAnalyzed 11 -DateRangeStart '2026-02-21' -DateRangeEnd '2026-02-26'

.EXAMPLE
    New-ReviewSummary.ps1 -ReviewDate '2026-02-26' -FormsAnalyzed 11 -DateRangeStart '2026-02-21' -DateRangeEnd '2026-02-26' -OpenInEditor

.EXAMPLE
    New-ReviewSummary.ps1 -FormsAnalyzed 2 -DateRangeStart '2026-06-01' -DateRangeEnd '2026-06-08' -FormsList '20260608-100000_PRJ-000_PF-TSK-010_feedback.md','20260608-110000_PRJ-000_PF-TSK-009_feedback.md'

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - Filename format: tools-review-YYYYMMDD-HHMMSS.md
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$ReviewDate = (Get-Date -Format 'yyyy-MM-dd'),

    [Parameter(Mandatory=$true)]
    [int]$FormsAnalyzed,

    [Parameter(Mandatory=$true)]
    [string]$DateRangeStart,

    [Parameter(Mandatory=$true)]
    [string]$DateRangeEnd,

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor,

    [Parameter(Mandatory=$false)]
    [string[]]$FormsList = @()
)

# --- Pure helper (defined before the dot-source guard so Pester can load it) ---
function ConvertTo-ArchivedFormsRows {
    <#
    .SYNOPSIS
        Builds the Archived Forms table body — one markdown row per analyzed feedback-form
        filename. The Task column is derived from the PF-TSK-NNN token in the filename
        (current underscore-form and legacy dash-form both match); Context is left as a
        placeholder to fill during review finalization.
    #>
    [CmdletBinding()]
    param([string[]]$Forms)

    $rows = foreach ($form in $Forms) {
        $name = Split-Path -Leaf $form
        # P-12a: extraction widened to any framework's task family; the no-match placeholder
        # stays '[PF-TSK-XXX]' deliberately — it is display text pinned by the FB-side suite.
        $task = if ($name -match '[A-Z]{2,4}-TSK-\d+') { $Matches[0] } else { '[PF-TSK-XXX]' }
        "| $name | $task | [Brief context] |"
    }
    return ($rows -join "`n")
}

# Dot-source guard: when dot-sourced (e.g. by Pester) define the helper above and return
# before the document-creation body runs.
if ($MyInvocation.InvocationName -eq '.') { return }

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Init, soak opt-in, the New-StandardProjectDocument call, try/catch, and the error report are
# owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This script keeps only
# its param block (above), the review-summary-specific data, and the success report.

# Build filename from review date + timestamp (tools-review-YYYYMMDD-HHMMSS.md).
# Computed before $customReplacements because the title replacement interpolates $timestamp.
$dateForFilename = $ReviewDate -replace '-', ''
$timestamp = Get-Date -Format 'HHmmss'
$fileNamePattern = "tools-review-$dateForFilename-$timestamp.md"

# Prepare custom replacements
$customReplacements = @{
    "# Tools Review Summary — [YYYY-MM-DD]" = "# Tools Review Summary — $ReviewDate-$timestamp"
    "| Forms Analyzed | [N] feedback forms |" = "| Forms Analyzed | $FormsAnalyzed feedback forms |"
    "| Date Range | [start date] to [end date] |" = "| Date Range | $DateRangeStart to $DateRangeEnd |"
    "| Tools Evaluated | [N]+ unique tools |" = "| Tools Evaluated | [N]+ unique tools |"
}

# When a forms list is supplied, auto-populate the Archived Forms table (PF-IMP-995):
# replace the template's placeholder data row with one generated row per analyzed form.
if ($FormsList.Count -gt 0) {
    $customReplacements["| [filename.md] | [PF-TSK-XXX] | [Brief context] |"] = ConvertTo-ArchivedFormsRows -Forms $FormsList
}

# Phase 7 (2026-05-11): template path resolved via Get-ProcessFrameworkPath; review summary
# writes to appdev/process-framework-central/feedback/reviews/ regardless of cwd.
$processFrameworkDir = Get-ProcessFrameworkPath
$templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates/support/tools-review-summary-template.md"
$outputDir = Join-Path -Path (Get-CentralFrameworkPath) -ChildPath "feedback/reviews"

# Create the document using standardized process
$documentId = New-FrameworkDocument `
    -TemplatePath $templatePath `
    -IdPrefix "PF-REV" `
    -IdDescription "Tools Review Summary $ReviewDate" `
    -DocumentName "tools-review-$dateForFilename-$timestamp" `
    -OutputDirectory $outputDir `
    -FileNamePattern $fileNamePattern `
    -Replacements $customReplacements `
    -Label "review summary" `
    -OpenInEditor:$OpenInEditor

$details = @(
    "Review Date: $ReviewDate",
    "Forms Analyzed: $FormsAnalyzed",
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
