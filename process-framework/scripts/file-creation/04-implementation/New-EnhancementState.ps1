<#
.SYNOPSIS
Creates a new Enhancement State Tracking file for enhancement work on an existing feature.

.DESCRIPTION
Uses the central ID registry system and standardized document creation.
Produced by Feature Request Evaluation (PF-TSK-067), consumed by Feature Enhancement (PF-TSK-068).

.PARAMETER TargetFeature
Feature ID of the feature being enhanced (e.g. "1.2.3"). Stamped into frontmatter and the
Overview; the feature's name is resolved from feature-tracking.md so the Overview row is not
left as a placeholder.

.PARAMETER EnhancementName
Name of the enhancement. Drives the document title, the kebab-case filename, and the
enhancement_name frontmatter field.

.PARAMETER Description
Brief description of the enhancement's scope. Omitted leaves the template's placeholder.

.PARAMETER Dims
Development dimension abbreviations inherited from the target feature, with importance
(e.g. "SE Critical, UX Relevant"). Valid abbreviations: AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI —
see the Development Dimensions Guide. Written to the inherited_dimensions frontmatter field.

.PARAMETER OpenInEditor
Opens the created state file in the configured editor after creation.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetFeature,

    [Parameter(Mandatory = $true)]
    [string]$EnhancementName,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [string]$Dims = "",

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
# owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This script keeps only
# its param block (above), the enhancement-specific data, and the success report.

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "target_feature"    = $TargetFeature
    "enhancement_name"  = ConvertTo-KebabCase -InputString $EnhancementName
}

# Prepare custom replacements
$customReplacements = @{
    "[Enhancement Name]"    = $EnhancementName
    "[Feature ID]"          = $TargetFeature
}

# Resolve the target feature's name from feature-tracking.md so the Overview row
# isn't left with a "[Feature Name]" placeholder when the ID is already known (PF-IMP-1319).
$resolvedFeatureName = $null
try {
    $resolvedFeatureName = Get-FeatureNameById -FeatureId $TargetFeature
} catch {
    Write-Warning "Could not resolve feature name for ${TargetFeature}: $($_.Exception.Message)"
}
if ($resolvedFeatureName) {
    $customReplacements["[Feature Name]"] = $resolvedFeatureName
} else {
    Write-Warning "Feature '${TargetFeature}' not found in feature-tracking.md; '[Feature Name]' left as a placeholder for manual fill."
}

# Add description if provided
if ($Description -ne "") {
    $customReplacements["[Brief description of what is being enhanced]"] = $Description
}

# Add inherited dimensions if provided
if ($Dims -ne "") {
    $customReplacements["[List inherited dimension abbreviations with importance]"] = $Dims
    $additionalMetadataFields["inherited_dimensions"] = $Dims
}

# Create the document using standardized process with custom filename pattern
$kebabName = ConvertTo-KebabCase -InputString $EnhancementName
$customFileName = "enhancement-$kebabName.md"

# Build absolute template path (Phase 5.5: configurable via paths.process_framework)
$processFrameworkDir = Get-ProcessFrameworkPath
$templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates/04-implementation/enhancement-state-tracking-template.md"

$idDesc = "Enhancement state tracking for ${TargetFeature}: ${EnhancementName}"
$stContext = Get-StateTrackingContext
$outputDir = "$($stContext.StateTrackingRelative)/temporary"
$stateId = New-FrameworkDocument -TemplatePath $templatePath -IdPrefix "PF-STA" -IdDescription $idDesc -DocumentName $EnhancementName -OutputDirectory $outputDir -Replacements $customReplacements -Metadata $additionalMetadataFields -FileNamePattern $customFileName -Label "enhancement state tracking file" -OpenInEditor:$OpenInEditor

$details = @(
    "Target Feature: $TargetFeature",
    "Enhancement: $EnhancementName",
    "Customization required — apply the feature-request-evaluation craft skill (.claude/skills/feature-request-evaluation/references/enhancement-scoping.md)"
)

Write-ProjectSuccess -Message "Created enhancement state tracking file with ID: $stateId" -Details $details
