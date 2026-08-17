<#
.SYNOPSIS
Creates a new Technical Exploration findings document (PD-TEC) in doc/technical/explorations.

.DESCRIPTION
Creates the findings document that a Technical Exploration spike (PF-TSK-093) produces: research
summary, options compared against stated criteria, recommendation, and residual-items table. The
document is the artifact of record for the exploration, and the running research log for a spike
that spans sessions.

With -FeatureId, the findings document is additionally linked into that feature's per-feature
state file §4 Documentation Inventory — the canonical per-feature artifact home (PF-PRO-002 /
PF-IMP-760). The master feature-tracking.md deliberately gets no findings link.

Closes the script-maintained PD-TEC creation gap (PF-IMP-1442, absorbed into PF-IMP-1390):
before this script, findings docs were hand-authored and the PD-TEC counter hand-bumped.

.PARAMETER Title
Title of the findings document — state the exploration's question, not its answer
(e.g. "Which booking engine meets our reservation requirements?").

.PARAMETER ExplorationId
The exploration row this document answers (e.g. "PD-EXP-001"). Recorded in the document's
header table so the findings and the tracker row are cross-linked.

.PARAMETER FeatureId
Feature ID this exploration blocks (e.g. "3.2.1"). When supplied, the findings document is
inserted into that feature's state file §4 Documentation Inventory. Omit for a pre-feature or
cross-cutting exploration — there is no feature state file to link into.

.PARAMETER RelatedFeatureName
Optional feature name for the document header table. Cosmetic; -FeatureId drives the §4 link.

.PARAMETER OpenInEditor
Open the created document in the editor.

.EXAMPLE
# Pre-feature exploration (no feature state file to link into)
New-TechnicalDoc.ps1 -Title "Which booking engine meets our reservation requirements?" -ExplorationId "PD-EXP-001"

.EXAMPLE
# Feature-blocking exploration — also inserts the §4 Documentation Inventory row
New-TechnicalDoc.ps1 -Title "Does Mollie support split payments for marketplace flows?" -ExplorationId "PD-EXP-004" -FeatureId "3.2.1"

.NOTES
- Assigns PD-TEC-### from the PD ID registry and writes to the registry's PD-TEC
  'explorations' directory type (doc/technical/explorations)
- Consumed by the Technical Exploration task (PF-TSK-093); the resulting PD-TEC ID is passed to
  Update-Exploration.ps1 -FindingsDoc to link the tracker row
- Post-creating delegator: the create is owned by New-FrameworkDocument; the outer try/catch
  guards the §4 inventory write only
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateLength(10, 200)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^PD-EXP-\d+$')]
    [string]$ExplorationId,

    [Parameter(Mandatory = $false)]
    [string]$FeatureId = "",

    [Parameter(Mandatory = $false)]
    [string]$RelatedFeatureName = "",

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Init, soak opt-in, the New-StandardProjectDocument call, the create try/catch, and the error
# report are owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This script
# keeps its param block, the data-building, the success report, and the §4 inventory write.

$CurrentDate = Get-Date -Format "yyyy-MM-dd"

$processFrameworkDir = Get-ProcessFrameworkPath
$templatePath = Join-Path $processFrameworkDir "templates/01-planning/technical-findings-template.md"

$relatedFeatureCell = if ($FeatureId -ne "") {
    if ($RelatedFeatureName -ne "") { "$FeatureId — $RelatedFeatureName" } else { $FeatureId }
} else {
    "— (pre-feature exploration)"
}

# Replacements apply to the document BODY only — template frontmatter is stripped and rebuilt
# from -Metadata plus the template's creates_* fields (creation-script craft).
# [DOCUMENT_ID] and [DATE] are substituted by the writer's own standard replacement set.
$customReplacements = @{
    "[Exploration title — the question, not the answer]" = $Title
    "[PD-EXP-NNN] — [link to the Technical Exploration Tracking row]" = $ExplorationId
    "[Feature ID + name, or `"— (pre-feature exploration)`"]" = $relatedFeatureCell
    "[🔬 In Progress / ✅ Resolved — mirrors the tracker row]" = "🔬 In Progress"
}

$additionalMetadataFields = @{
    exploration_id = $ExplorationId
    description    = "Technical exploration findings: $Title"
}
if ($FeatureId -ne "") {
    $additionalMetadataFields["feature_id"] = $FeatureId
}

# Outer try/catch guards the POST-creation §4 write; New-FrameworkDocument owns the create path.
try {
    $creation = New-FrameworkDocument `
        -TemplatePath $templatePath `
        -IdPrefix "PD-TEC" `
        -IdDescription "Technical Exploration findings: $Title" `
        -DocumentName $Title `
        -DirectoryType "explorations" `
        -Replacements $customReplacements `
        -Metadata $additionalMetadataFields `
        -Label "technical findings document" `
        -OpenInEditor:$OpenInEditor `
        -PassThru

    # $null under -WhatIf — nothing was created, so there is nothing to link.
    if ($null -eq $creation) { return }
    $documentId = $creation.Id

    $details = @(
        "ID: $documentId",
        "Exploration: $ExplorationId",
        "Location: doc/technical/explorations"
    )

    # §4 Documentation Inventory linkage (PF-PRO-002 / PF-IMP-760): the per-feature state file is
    # the canonical home for a feature's artifact links. Pre-feature explorations have no state
    # file to link into, and the master feature-tracking.md is deliberately never linked.
    if ($FeatureId -ne "") {
        # The document already exists by this point, so a linkage failure must DEGRADE (warn +
        # tell the agent to add the row) rather than exit 1 — an unresolvable -FeatureId would
        # otherwise report failure for a findings doc that was created successfully. Same
        # treatment as New-ArchitectureAssessment.ps1's inventory write.
        try {
            # The writer's own path (-PassThru, PF-IMP-1678) — no filename re-derivation.
            $artifactPath = $creation.RelativePath
            $inventory = Add-StateFileDocumentationInventoryRow `
                -FeatureId $FeatureId `
                -ArtifactId $documentId `
                -ArtifactPath $artifactPath `
                -ArtifactType "Exploration Findings" `
                -Status "🔬 In Progress" `
                -LastUpdated $CurrentDate

            if ($inventory.Action -in @('Inserted', 'Updated')) {
                $details += "§4 Documentation Inventory: $($inventory.Action.ToLower()) row in $(Split-Path $inventory.StateFilePath -Leaf)"
            } else {
                Write-ProjectLog "Findings doc created, but the §4 Documentation Inventory row for feature $FeatureId was not written ($($inventory.Action)): $($inventory.Message). Add the row manually." -Level "WARN"
            }
        }
        catch {
            Write-ProjectLog "Findings doc created, but linking it into feature $FeatureId's §4 Documentation Inventory failed: $($_.Exception.Message). Add the row manually." -Level "WARN"
        }
    }

    Write-ProjectSuccess -Message "Created technical findings document: $documentId" -Details $details

    Write-Verbose "Next Steps: record the research, options, recommendation, and residual items"
    Write-Verbose "Next Steps: on approval, link it via Update-Exploration.ps1 -ExplorationId $ExplorationId -NewStatus Resolved -FindingsDoc $documentId"
}
catch {
    # Safety net for the post-creation block. The create path reports its own failures
    # (New-FrameworkDocument), and the §4 linkage degrades to a WARN above, so reaching here
    # means something unanticipated after the document was written.
    Write-ProjectError -Message "Technical findings document post-creation step failed: $($_.Exception.Message)" -ExitCode 1
}
