<#
.SYNOPSIS
Creates a new Structure Change state tracking file with an automatically assigned ID.

.DESCRIPTION
Uses the central ID registry system and standardized document creation.

.PARAMETER ChangeName
Name of the structure change. Drives the document title, the kebab-case filename, and the
change_name frontmatter field.

.PARAMETER Description
Brief description of the change's scope. Omitted leaves the template's placeholder.

.PARAMETER ChangeType
Selects the state-file template. Valid values: "Template Update" (default), "Directory
Reorganization", "Metadata Structure", "Documentation Architecture", "Rename", "Content Update",
"Framework Extension". Rename / Content Update / Framework Extension each have a dedicated
lightweight template; the rest use the standard one. Under -FromProposal this value is a label
only — template selection ignores it.

.PARAMETER FromProposal
Uses the execution-tracking-only template for a change whose content is owned by a Structure
Change Proposal. Rejected in combination with -ChangeType "Content Update" or "Framework
Extension", whose templates carry type-specific content/artifact tables.

.PARAMETER OpenInEditor
Opens the created state file in the configured editor after creation.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ChangeName,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Template Update", "Directory Reorganization", "Metadata Structure", "Documentation Architecture", "Rename", "Content Update", "Framework Extension")]
    [string]$ChangeType = "Template Update",

    [Parameter(Mandatory = $false)]
    [switch]$FromProposal,

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Init, soak opt-in, the New-StandardProjectDocument call, try/catch, and the error report are
# owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This script keeps only its
# param block, validation, the template selection + data, and the success report.

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "change_name" = ConvertTo-KebabCase -InputString $ChangeName
}

# Validate -FromProposal is not used with ChangeTypes whose templates have type-specific
# content/artifact tables (Content Update: Affected Files; Framework Extension: New/Modified
# Artifacts). Rename is allowed: the proposal owns the file mapping, so the from-proposal
# template's execution-only structure is appropriate.
if ($FromProposal -and ($ChangeType -eq "Content Update" -or $ChangeType -eq "Framework Extension")) {
    Write-ProjectError -Message "-FromProposal cannot be used with ChangeType '$ChangeType' because the $ChangeType template contains type-specific content/artifact tables (Affected Files / New Artifacts) that don't belong in a generic execution-tracking-only state file. Use -ChangeType '$ChangeType' alone — its dedicated template is already lightweight." -ExitCode 1
}

# Select template (Phase 5.5: framework subtree path resolved via configurable paths.process_framework)
#   -FromProposal: always use from-proposal template (execution tracking only; proposal owns the content)
#   Otherwise: select by ChangeType
$processFrameworkDir = Get-ProcessFrameworkPath
if ($FromProposal) {
    $templatePath = Join-Path $processFrameworkDir "templates/support/structure-change-state-from-proposal-template.md"
} elseif ($ChangeType -eq "Rename") {
    $templatePath = Join-Path $processFrameworkDir "templates/support/structure-change-state-rename-template.md"
} elseif ($ChangeType -eq "Content Update") {
    $templatePath = Join-Path $processFrameworkDir "templates/support/structure-change-state-content-update-template.md"
} elseif ($ChangeType -eq "Framework Extension") {
    $templatePath = Join-Path $processFrameworkDir "templates/support/structure-change-state-framework-extension-template.md"
} else {
    $templatePath = Join-Path $processFrameworkDir "templates/support/structure-change-state-template.md"
}

# Under -FromProposal the ChangeType is a label only (template selection ignores it) —
# stamp an explicitly passed value, else point at the proposal-of-record instead of
# asserting the 'Template Update' default (PF-IMP-1416)
$changeTypeStamp = if ($FromProposal -and -not $PSBoundParameters.ContainsKey('ChangeType')) { "(see proposal)" } else { $ChangeType }

# Prepare custom replacements
$customReplacements = @{
    "[Change Name]"                                                                            = $ChangeName
    "[Template Update/Directory Reorganization/Metadata Structure/Documentation Architecture/Content Update]" = $changeTypeStamp
}

# Add description if provided
if ($Description -ne "") {
    $customReplacements["[Brief description of what's being changed]"] = $Description
}

# Create the document using standardized process with custom filename pattern
$kebabName = ConvertTo-KebabCase -InputString $ChangeName
$customFileName = "structure-change-$kebabName.md"

$stContext = Get-StateTrackingContext
$outputDir = "$($stContext.StateTrackingRelative)/temporary"
$stateId = New-FrameworkDocument -TemplatePath $templatePath -IdPrefix "PF-STA" -IdDescription "Structure change state for: ${ChangeName}" -DocumentName $ChangeName -OutputDirectory $outputDir -Replacements $customReplacements -Metadata $additionalMetadataFields -FileNamePattern $customFileName -Label "structure change state file" -OpenInEditor:$OpenInEditor

if ($FromProposal) {
        $details = @(
            "",
            "📋 LIGHTWEIGHT STATE FILE (from proposal)",
            "",
            "✅ This state file tracks execution progress only.",
            "✅ See the linked proposal document for rationale, affected files, and migration strategy.",
            "",
            "⚠️  COPY your proposal's phases into the Implementation Roadmap section.",
            "⚠️  CROSS-CHECK: Verify every file in the proposal's affected files table",
            "   appears in at least one phase checklist.",
            "",
            "📖 TASK GUIDE: process-framework/tasks/support/structure-change-task.md"
        )
    } elseif ($ChangeType -eq "Framework Extension") {
        $details = @(
            "",
            "📋 LIGHTWEIGHT STATE FILE (framework extension)",
            "",
            "✅ Tracks new and modified artifacts for a framework extension.",
            "✅ No pilot/rollback/metrics sections — framework doc changes are low-risk.",
            "",
            "⚠️  FILL IN the New Artifacts and Modified Artifacts tables.",
            "⚠️  CUSTOMIZE the phase checklists to match your extension scope.",
            "",
            "📖 TASK GUIDE: process-framework/tasks/support/structure-change-task.md"
        )
    } else {
        $details = @(
            "Customization required — see process-framework/tasks/support/structure-change-task.md",
            "Create structure-change proposal first — see process-framework/templates/support/structure-change-proposal-template.md"
        )
    }

    Write-ProjectSuccess -Message "Created structure change state file with ID: $stateId" -Details $details
