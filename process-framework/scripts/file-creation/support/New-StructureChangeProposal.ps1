# New-StructureChangeProposal.ps1
# Creates a new structure change proposal document
# Uses the central ID registry system and standardized document creation

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ChangeName,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [string]$TargetDate = "",

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


# Soak verification opt-in (PF-PRO-028 v2.0 Pattern B; helper-routed armoring via DocumentManagement.psm1).
# Caller-aware no-arg form: helper resolves this script's path via Get-PSCallStack.
# Idempotent — silently no-ops if already registered.
Register-SoakScript

# Calculate target date (default: 30 days from now)
if ($TargetDate -eq "") {
    $TargetDate = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")
}

$currentDate = (Get-Date).ToString("yyyy-MM-dd")

# Phase 7 (2026-05-11): write to central proposals/; stamp project_id in frontmatter.
$projectId = $null
try {
    $cfg = Get-ProjectConfig
    if ($cfg.project_id) { $projectId = $cfg.project_id }
} catch {
    Write-Verbose "New-StructureChangeProposal: could not read doc/project-config.json; project_id will be null."
}

# Prepare custom replacements
$customReplacements = @{
    "SC-XXX"    = "SC-PENDING"
    "[Name]"    = "AI Agent & Human Partner"
    "YYYY-MM-DD" = $currentDate
}

# Handle the Target Implementation Date separately (second YYYY-MM-DD in template)
# The template has two YYYY-MM-DD instances - the first is Date Proposed, second is Target Implementation Date
# Since replace_all would hit both, we handle this via post-processing

# Add description to overview if provided
if ($Description -ne "") {
    $customReplacements["<!-- Provide a brief overview of the proposed structure change -->"] = $Description
}

# Phase 7: template path resolved via configurable paths.process_framework
$processFrameworkDir = Get-ProcessFrameworkPath
$templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates/support/structure-change-proposal-template.md"

# Phase 7: write to appdev/process-framework-central/proposals/ regardless of cwd.
$outputDir = Join-Path -Path (Get-CentralFrameworkPath) -ChildPath "proposals"

# Create the document using standardized process
$kebabName = ConvertTo-KebabCase -InputString $ChangeName
# Filename includes PRJ-ID prefix per the Phase 7.5 Open-content convention (project-tagged).
$prjPrefix = if ($projectId) { "${projectId}_" } else { "" }
$customFileName = "${prjPrefix}structure-change-$kebabName-proposal.md"

$additionalMetadataFields = @{
    "project_id" = $(if ($projectId) { $projectId } else { "null" })
}

try {
    $proposalId = New-StandardProjectDocument `
        -TemplatePath $templatePath `
        -IdPrefix "PF-PRO" `
        -IdDescription "Structure change proposal for: ${ChangeName}" `
        -DocumentName $ChangeName `
        -OutputDirectory $outputDir `
        -Replacements $customReplacements `
        -AdditionalMetadataFields $additionalMetadataFields `
        -FileNamePattern $customFileName `
        -OpenInEditor:$OpenInEditor

    # Post-process: replace Target Implementation Date (the remaining YYYY-MM-DD after first replacement)
    $outputPath = Join-Path -Path $outputDir -ChildPath $customFileName
    if (Test-Path $outputPath) {
        $content = Get-Content $outputPath -Raw
        # Replace the remaining YYYY-MM-DD (Target Implementation Date) with the target date
        $content = $content -replace 'YYYY-MM-DD', $TargetDate
        Set-Content -Path $outputPath -Value $content -NoNewline
    }

    $details = @(
        "",
        "📋 Structure Change Proposal Created",
        "",
        "📖 NEXT STEPS:",
        "   1. Fill in Current Structure and Proposed Structure sections",
        "   2. Document Rationale (benefits and challenges)",
        "   3. List all Affected Files",
        "   4. Define Migration Strategy phases",
        "   5. Add Task Modifications / New Tasks / Handover Interfaces if applicable",
        "   6. Present proposal to human partner for approval",
        "",
        "🔗 Related: Create state tracking file after approval:",
        "   New-StructureChangeState.ps1 -ChangeName `"$ChangeName`""
    )

    Write-ProjectSuccess -Message "Created structure change proposal with ID: $proposalId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create structure change proposal: $($_.Exception.Message)" -ExitCode 1
}
