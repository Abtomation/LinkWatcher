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
    [ValidateSet("SingleTool", "MultipleTools", "TaskLevel")]
    [string]$FeedbackType = "MultipleTools",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "feedback-forms",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers - this replaces all the complex path resolution
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

try {
    # Generate timestamp for filename
    $formattedTimestamp = Get-ProjectTimestamp -Format "FileTimestamp"

    # Convert FeedbackType enum to display format
    $feedbackTypeDisplay = switch ($FeedbackType) {
        "SingleTool"    { "Single Tool" }
        "MultipleTools" { "Multiple Tools" }
        "TaskLevel"     { "Task-Level" }
        default         { $FeedbackType }
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

    # Create document using standardized process
    $templatePath = "doc/process-framework/templates/templates/feedback-form-template.md"
    $artifactId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "ART-FEE" -IdDescription "Feedback form for ${DocumentId}" -DocumentName "$DocumentId-feedback" -OutputDirectory "doc/process-framework/feedback/$OutputDir" -Replacements $customReplacements -FileNamePattern "$formattedTimestamp-$DocumentId-feedback.md" -OpenInEditor:$OpenInEditor

    if ($artifactId) {
        $details = @(
            "Feedback Type: $feedbackTypeDisplay"
        )

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
                "   doc/process-framework/guides/guides/feedback-form-guide.md",
                "🎯 FOCUS AREAS: 'Feedback Form Completion Instructions' section",
                "",
                "🚫 DO NOT use the generated file without proper customization!",
                "✅ The template provides structure - YOU provide the meaningful content."
            )
        }

        Write-ProjectSuccess -Message "Created feedback form with ID: $artifactId" -Details $details
    }
}
catch {
    Write-ProjectError -Message $_.Exception.Message -ExitCode 1
}
