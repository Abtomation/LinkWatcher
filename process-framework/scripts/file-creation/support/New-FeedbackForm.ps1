# New-FeedbackForm.ps1
# Creates a new feedback form with an automatically assigned ID
# Supports hybrid feedback approach: Single Tool, Multiple Tools, or Task-Level evaluation

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$DocumentId,

    [Parameter(Mandatory = $false)]
    [string]$TaskContext = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("SingleTool", "Single Tool", "MultipleTools", "Multiple Tools", "TaskLevel", "Task-Level")]
    [string]$FeedbackType = "MultipleTools",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "feedback-forms",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers - this replaces all the complex path resolution
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization


# Soak verification opt-in (PF-PRO-028 v2.0 Pattern B; helper-routed armoring via DocumentManagement.psm1).
# Caller-aware no-arg form: helper resolves this script's path via Get-PSCallStack.
# Idempotent — silently no-ops if already registered.
Register-SoakScript

try {
    # Generate timestamp for filename
    $formattedTimestamp = Get-ProjectTimestamp -Format "FileTimestamp"

    # Convert FeedbackType enum to display format
    $feedbackTypeDisplay = switch ($FeedbackType) {
        { $_ -in "SingleTool", "Single Tool" }       { "Single Tool" }
        { $_ -in "MultipleTools", "Multiple Tools" }  { "Multiple Tools" }
        { $_ -in "TaskLevel", "Task-Level" }          { "Task-Level" }
        default                                        { $FeedbackType }
    }

    # Prepare custom replacements
    $customReplacements = @{
        "| Task Evaluated | [Task Name (PF-TSK-XXX)] |"                   = "| Task Evaluated | [$DocumentId] |"
        "| Feedback Type | [Single Tool / Multiple Tools / Task-Level] |" = "| Feedback Type | $feedbackTypeDisplay |"
    }

    # Add task context if provided
    if ($TaskContext -ne "") {
        $customReplacements["| Task Context | [Brief description of what was accomplished] |"] = "| Task Context | $TaskContext |"
    }

    # Override frontmatter additional_fields with actual values (PF-IMP-534)
    $additionalMetadataFields = @{
        "feedback_type" = $feedbackTypeDisplay
        "task_context"  = $TaskContext
        "document_id"   = $DocumentId
    }

    # Create document using standardized process
    $templatePath = "process-framework/templates/support/feedback-form-template.md"
    $artifactId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-FEE" -IdDescription "Feedback form for ${DocumentId}" -DocumentName "$DocumentId-feedback" -OutputDirectory "process-framework-local/feedback/$OutputDir" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern "$formattedTimestamp-$DocumentId-feedback.md" -OpenInEditor:$OpenInEditor

    if ($artifactId) {
        $generatedFile = Join-Path (Get-ProjectRoot) "process-framework-local/feedback/$OutputDir/$formattedTimestamp-$DocumentId-feedback.md"

        # Prune Tool sections to match FeedbackType (PF-IMP-582):
        #   Single Tool    -> 1 section, Multiple Tools -> 2 sections, Task-Level -> 0 sections
        # Skip in -WhatIf since no file was written.
        if (-not $WhatIfPreference) {
            $toolsToKeep = switch ($feedbackTypeDisplay) {
                "Single Tool"    { 1 }
                "Multiple Tools" { 2 }
                "Task-Level"     { 0 }
                default          { 3 }
            }

            if ($toolsToKeep -lt 3) {
                if (Test-Path $generatedFile) {
                    $content = Get-Content $generatedFile -Raw

                    switch ($toolsToKeep) {
                        0 {
                            $content = $content -replace '(?ms)## Tool Evaluation\r?\n.*?---\r?\n\r?\n', ''
                        }
                        1 {
                            $content = $content -replace '(?ms)### Tool 2: \[Tool Name \(\[PREFIX\]-XXX-XXX\)\] \*\(Optional\)\*.*?(?=\*\[Add more tool sections as needed\]\*)', ''
                        }
                        2 {
                            $content = $content -replace '(?ms)### Tool 3: \[Tool Name \(\[PREFIX\]-XXX-XXX\)\] \*\(Optional\)\*.*?(?=\*\[Add more tool sections as needed\]\*)', ''
                        }
                    }

                    [System.IO.File]::WriteAllText($generatedFile, $content, [System.Text.UTF8Encoding]::new($false))
                }
            }
        }

        $details = @(
            "Feedback Type: $feedbackTypeDisplay",
            "Created at: $generatedFile"
        )

        if (-not $OpenInEditor) {
            $details += "Customization required — see process-framework/guides/framework/feedback-form-guide.md"
        }

        Write-ProjectSuccess -Message "Created feedback form with ID: $artifactId" -Details $details
    }
}
catch {
    Write-ProjectError -Message $_.Exception.Message -ExitCode 1
}
