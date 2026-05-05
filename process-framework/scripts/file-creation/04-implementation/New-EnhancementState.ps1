# New-EnhancementState.ps1
# Creates a new Enhancement State Tracking file for tracking enhancement work on existing features
# Uses the central ID registry system and standardized document creation
# Produced by Feature Request Evaluation (PF-TSK-067), consumed by Feature Enhancement (PF-TSK-068)

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

# Perform standard initialization
Invoke-StandardScriptInitialization


# Soak verification opt-in (PF-PRO-028 v2.0 Pattern B; helper-routed armoring via DocumentManagement.psm1).
# Caller-aware no-arg form: helper resolves this script's path via Get-PSCallStack.
# Idempotent — silently no-ops if already registered.
Register-SoakScript

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

# Build absolute template path
$projectRoot = Get-ProjectRoot
$processFrameworkDir = Join-Path $projectRoot "process-framework"
$templatePath = Join-Path -Path $processFrameworkDir -ChildPath "templates/04-implementation/enhancement-state-tracking-template.md"

try {
    $idDesc = "Enhancement state tracking for ${TargetFeature}: ${EnhancementName}"
    $stateId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-STA" -IdDescription $idDesc -DocumentName $EnhancementName -OutputDirectory "doc/state-tracking/temporary" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -FileNamePattern $customFileName -OpenInEditor:$OpenInEditor

    $details = @(
        "Target Feature: $TargetFeature",
        "Enhancement: $EnhancementName",
        "Customization required — see process-framework/guides/04-implementation/enhancement-state-tracking-customization-guide.md"
    )

    Write-ProjectSuccess -Message "Created enhancement state tracking file with ID: $stateId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create enhancement state tracking file: $($_.Exception.Message)" -ExitCode 1
}
