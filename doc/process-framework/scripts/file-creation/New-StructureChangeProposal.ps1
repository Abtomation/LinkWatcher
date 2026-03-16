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
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Calculate target date (default: 30 days from now)
if ($TargetDate -eq "") {
    $TargetDate = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")
}

$currentDate = (Get-Date).ToString("yyyy-MM-dd")

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

# Create the document using standardized process
$kebabName = ConvertTo-KebabCase -InputString $ChangeName
$customFileName = "structure-change-$kebabName-proposal.md"

try {
    $proposalId = New-StandardProjectDocument `
        -TemplatePath "doc/process-framework/templates/templates/structure-change-proposal-template.md" `
        -IdPrefix "PF-PRO" `
        -IdDescription "Structure change proposal for: ${ChangeName}" `
        -DocumentName $ChangeName `
        -OutputDirectory "doc/process-framework/proposals/proposals" `
        -Replacements $customReplacements `
        -FileNamePattern $customFileName `
        -OpenInEditor:$OpenInEditor

    # Post-process: replace Target Implementation Date (the remaining YYYY-MM-DD after first replacement)
    $projectRoot = Get-ProjectRoot
    $outputPath = Join-Path $projectRoot "doc/process-framework/proposals/proposals/$customFileName"
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
