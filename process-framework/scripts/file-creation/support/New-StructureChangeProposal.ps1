<#
.SYNOPSIS
Creates a new Structure Change Proposal document with an automatically assigned ID.

.DESCRIPTION
Uses the central ID registry system and standardized document creation.

.PARAMETER ChangeName
Name of the proposed structure change. Drives the document title and the kebab-case filename.

.PARAMETER Description
Brief overview of the proposed change. Replaces the template's overview placeholder when
supplied.

.PARAMETER TargetDate
Target implementation date, yyyy-MM-dd. Defaults to 30 days from creation.

.PARAMETER OpenInEditor
Opens the created proposal in the configured editor after creation.
#>

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

# Init, soak opt-in, the New-StandardProjectDocument call, and the create-failure error path are
# owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This Tier-3 script keeps
# its data, its bespoke post-creation target-date rewrite, and its own report — inline.

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
    $proposalId = New-FrameworkDocument `
        -TemplatePath $templatePath `
        -IdPrefix "PF-PRO" `
        -IdDescription "Structure change proposal for: ${ChangeName}" `
        -DocumentName $ChangeName `
        -OutputDirectory $outputDir `
        -Replacements $customReplacements `
        -Metadata $additionalMetadataFields `
        -FileNamePattern $customFileName `
        -Label "structure change proposal" `
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
