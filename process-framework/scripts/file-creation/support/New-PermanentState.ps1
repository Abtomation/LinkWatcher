# New-PermanentState.ps1
# Creates a new permanent state tracking file
# Uses the central ID registry system and standardized document creation

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$StateName,

    [Parameter(Mandatory=$false)]
    [string]$Description = "",

    [Parameter(Mandatory=$false)]
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

# Prepare custom replacements
$customReplacements = @{
    "[State File Name]" = $StateName
    "[what this file tracks]" = $StateName.ToLower()
}

# Add description if provided
if ($Description -ne "") {
    $customReplacements["Brief state description"] = $Description
}

try {
    $projectRoot = Get-ProjectRoot
    $templatePath = Join-Path $projectRoot "process-framework/templates/support/state-file-template.md"
    $permanentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-STA" -IdDescription "Permanent state tracking: ${StateName}" -DocumentName $StateName -OutputDirectory "process-framework-local/state-tracking/permanent" -Replacements $customReplacements -OpenInEditor:$OpenInEditor

    $details = @(
        "",
        "Next steps:",
        "1. Edit the file to define the state tracking structure",
        "2. Add initial state entries",
        "3. Use this file for ongoing project monitoring"
    )

    # Add mandatory guide consultation if not opening in editor
    if (-not $OpenInEditor) {
        $details += "Customization required — see process-framework/guides/support/state-file-creation-guide.md"
    }

    Write-ProjectSuccess -Message "Created permanent state file with ID: $permanentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create permanent state file: $($_.Exception.Message)" -ExitCode 1
}
