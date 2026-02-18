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
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Prepare custom replacements
$customReplacements = @{
    "\[State File Name\]" = $StateName
    "\[what this file tracks\]" = $StateName.ToLower()
}

# Add description if provided
if ($Description -ne "") {
    $customReplacements["Brief state description"] = $Description
}

try {
    $projectRoot = Get-ProjectRoot
    $templatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/state-file-template.md"
    $permanentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PF-STA" -IdDescription "Permanent state tracking: ${StateName}" -DocumentName $StateName -OutputDirectory "doc/process-framework/state-tracking/permanent" -Replacements $customReplacements -OpenInEditor:$OpenInEditor

    $details = @(
        "",
        "Next steps:",
        "1. Edit the file to define the state tracking structure",
        "2. Add initial state entries",
        "3. Use this file for ongoing project monitoring"
    )

    # Add mandatory guide consultation if not opening in editor
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
            "   doc/process-framework/guides/guides/state-file-creation-guide.md",
            "🎯 FOCUS AREAS: 'Step-by-Step Instructions' and 'Quality Assurance' sections",
            "",
            "🚫 DO NOT use the generated file without proper customization!",
            "✅ The template provides structure - YOU provide the meaningful content."
        )
    }

    Write-ProjectSuccess -Message "Created permanent state file with ID: $permanentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create permanent state file: $($_.Exception.Message)" -ExitCode 1
}
