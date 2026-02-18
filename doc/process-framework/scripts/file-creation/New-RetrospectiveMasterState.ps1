# New-RetrospectiveMasterState.ps1
# Creates a new Retrospective Master State file for onboarding an existing project into the process framework
# Used in step 2 of Codebase Feature Discovery (PF-TSK-064)

<#
.SYNOPSIS
    Creates a new Retrospective Master State tracking file for framework onboarding.

.DESCRIPTION
    This PowerShell script generates the Retrospective Master State file by:
    - Generating a unique state tracking ID (PF-STA-XXX) automatically
    - Filling in the project name, start date, and initial status (DISCOVERY)
    - Placing the file at the standard location in state-tracking/temporary/
    - Updating the ID tracker in the central ID registry

    This file is shared across all three onboarding tasks (PF-TSK-064, PF-TSK-065, PF-TSK-066)
    and is archived upon completion of the full onboarding process.

.PARAMETER ProjectName
    Name of the project being onboarded into the process framework

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-RetrospectiveMasterState.ps1 -ProjectName "LinkWatcher"

.EXAMPLE
    .\New-RetrospectiveMasterState.ps1 -ProjectName "MyProject" -OpenInEditor

.NOTES
    - The output file is placed in doc/process-framework/state-tracking/temporary/
    - The file is TEMPORARY and will be archived when onboarding is complete
    - Only one retrospective master state file should exist per project at a time
    - Assigns a PF-STA-XXX ID from the central ID registry

    Script Metadata:
    - Script Type: Document Creation Script
    - Created: 2026-02-17
    - For: Creating retrospective master state files during onboarding (PF-TSK-064)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers with robust path resolution
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$modulePath = Join-Path -Path $scriptDir -ChildPath "..\Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
}
catch {
    Write-Error "Failed to import Common-ScriptHelpers module from: $modulePath"
    Write-Error "Please ensure the script is run from the correct directory or the module path is correct."
    exit 1
}

# Perform standard initialization
Invoke-StandardScriptInitialization

# Resolve paths
$projectRoot = Get-ProjectRoot
$templatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/retrospective-state-template.md"
$outputDir = Join-Path $projectRoot "doc/process-framework/state-tracking/temporary"
$outputFile = Join-Path $outputDir "retrospective-master-state.md"

# Validate template exists
if (-not (Test-Path $templatePath)) {
    Write-ProjectError -Message "Retrospective state template not found at: $templatePath" -ExitCode 1
}

# Check if file already exists
if (Test-Path $outputFile) {
    Write-Host ""
    Write-Host "⚠️  A retrospective master state file already exists at:" -ForegroundColor Yellow
    Write-Host "    $outputFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This likely means an onboarding process is already in progress." -ForegroundColor Yellow
    Write-Host "Read the existing file to understand current progress before creating a new one." -ForegroundColor Yellow
    Write-Host ""

    if (-not $PSCmdlet.ShouldProcess($outputFile, "Overwrite existing retrospective master state file")) {
        Write-Host "Operation cancelled. Use the existing file or delete it first." -ForegroundColor Cyan
        return
    }

    # Remove existing file so New-StandardProjectDocument doesn't conflict
    Remove-Item $outputFile -Force
}

# Prepare custom replacements
$today = Get-Date -Format "yyyy-MM-dd"
$customReplacements = @{
    "[Project Name]"    = $ProjectName
    "[YYYY-MM-DD]"      = $today
    "[DISCOVERY | ANALYSIS | ASSESSMENT_AND_DOCUMENTATION | FINALIZATION | COMPLETE]" = "DISCOVERY"
    "[N]"               = "0"
    "[M]"               = "0"
    "[N-M]"             = "0"
    "[M/N * 100]"       = "0"
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "project_name" = $ProjectName
    "status"       = "DISCOVERY"
    "lifecycle"    = "temporary"
}

# Create the document using standardized process
try {
    $documentId = New-StandardProjectDocument `
        -TemplatePath $templatePath `
        -IdPrefix "PF-STA" `
        -IdDescription "Retrospective master state for $ProjectName onboarding" `
        -DocumentName "retrospective-master-state" `
        -DirectoryType "temporary" `
        -FileNamePattern "retrospective-master-state.md" `
        -Replacements $customReplacements `
        -AdditionalMetadataFields $additionalMetadataFields `
        -OpenInEditor:$OpenInEditor

    $details = @(
        "Project: $ProjectName",
        "Location: doc/process-framework/state-tracking/temporary/retrospective-master-state.md",
        "Status: DISCOVERY",
        "Started: $today",
        "",
        "📋 NEXT STEPS:",
        "1. Survey the project structure (Step 3 of PF-TSK-064)",
        "2. List ALL source files in the Unassigned Files section",
        "3. Record total file count in Coverage Metrics",
        "4. Begin feature discovery and code assignment",
        "",
        "📖 TASK DEFINITION:",
        "   doc/process-framework/tasks/00-onboarding/codebase-feature-discovery.md",
        "",
        "⚠️  This is a TEMPORARY file - archive it when onboarding is complete.",
        "✅ Update this file at the END of every onboarding session."
    )

    Write-ProjectSuccess -Message "Created Retrospective Master State file with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Retrospective Master State file: $($_.Exception.Message)" -ExitCode 1
}
