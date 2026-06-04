# New-FeedbackForm.ps1
# Creates a new feedback form with an automatically assigned ID.
# Supports hybrid feedback approach: Single Tool, Multiple Tools, or Task-Level evaluation.
# Phase 7 (2026-05-11): writes to appdev/process-framework-central/feedback/feedback-forms/
# regardless of cwd, stamps project_id/project_name/framework_version in frontmatter, and
# emits the underscore-separated filename format YYYYMMDD-HHMMSS_<PRJ-ID>_PF-TSK-XXX_feedback.md.
# Framework Self-Testing extension (PF-PRO-035, Phase 3d.7b, 2026-05-18): added -OutputDir
# override so E2E test fixtures (and future tooling) can redirect feedback-form output to a
# sandbox dir without modifying central-path resolution. Default behavior unchanged when
# -OutputDir is omitted.

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
    [string]$OutputDir = "",

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

    # Resolve project identity + framework version for frontmatter stamping (Phase 7).
    # project_id comes from doc/project-config.json (set by Register-Project.ps1).
    # framework_version comes from the rolled-out .framework-version file at Get-ProcessFrameworkPath.
    # Both fields tolerate missing inputs so the form still gets created in edge cases
    # (e.g., a project that hasn't yet been registered or pushed to); the resulting frontmatter
    # records what was knowable at write time.
    $projectId = $null
    $projectName = $null
    try {
        $cfg = Get-ProjectConfig
        if ($cfg.project_id)   { $projectId   = $cfg.project_id }
        if ($cfg.project.name) { $projectName = $cfg.project.name }
    } catch {
        Write-Verbose "New-FeedbackForm: could not read doc/project-config.json; project_id/project_name will be null."
    }

    $frameworkVersion = $null
    try {
        $fwVersionPath = Join-Path -Path (Get-ProcessFrameworkPath) -ChildPath ".framework-version"
        if (Test-Path $fwVersionPath) { $frameworkVersion = (Get-Content -Path $fwVersionPath -Raw).Trim() }
    } catch {
        Write-Verbose "New-FeedbackForm: could not read .framework-version; framework_version will be null."
    }

    # Override frontmatter additional_fields with actual values (PF-IMP-534)
    $additionalMetadataFields = @{
        "feedback_type"     = $feedbackTypeDisplay
        "task_context"      = $TaskContext
        "document_id"       = $DocumentId
        "project_id"        = $(if ($projectId) { $projectId } else { "null" })
        "project_name"      = $(if ($projectName) { $projectName } else { "null" })
        "framework_version" = $(if ($frameworkVersion) { $frameworkVersion } else { "null" })
    }

    # Build PRJ-ID-tagged filename per Phase 7 convention. When project_id is unknown we omit
    # the segment rather than emit "null" — keeps the filename grep-friendly and matches the
    # historical-migration convention for pre-registration content.
    $projectIdSegment = if ($projectId) { "_${projectId}" } else { "" }
    $fileNamePattern  = "${formattedTimestamp}${projectIdSegment}_${DocumentId}_feedback.md"

    # Create document using standardized process. Phase 7: writes to appdev/process-framework-central/
    # via Get-CentralFrameworkPath regardless of cwd. New-StandardProjectDocument treats an absolute
    # OutputDirectory verbatim, so the path is identical from cwd=appdev and cwd=project.
    # PF-PRO-035 Phase 3d.7b: -OutputDir overrides the central-path default for E2E test fixtures.
    $processFrameworkDir = Get-ProcessFrameworkPath
    $templatePath = Join-Path $processFrameworkDir "templates/support/feedback-form-template.md"
    $outputDir = if ($OutputDir) {
        # Fixture-setup dir creation — override -WhatIf so Resolve-Path can succeed
        # even when the script is being inspected via -WhatIf. Creating an empty
        # caller-specified directory is not the "real work" the user wants to preview.
        if (-not (Test-Path $OutputDir)) {
            New-Item -ItemType Directory -Path $OutputDir -Force -WhatIf:$false | Out-Null
        }
        (Resolve-Path $OutputDir).Path
    } else {
        Join-Path (Get-CentralFrameworkPath) "feedback/feedback-forms"
    }
    $artifactId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-FEE" -IdDescription "Feedback form for ${DocumentId}" -DocumentName "$DocumentId-feedback" -OutputDirectory $outputDir -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $fileNamePattern -OpenInEditor:$OpenInEditor

    if ($artifactId) {
        $generatedFile = Join-Path $outputDir $fileNamePattern

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
