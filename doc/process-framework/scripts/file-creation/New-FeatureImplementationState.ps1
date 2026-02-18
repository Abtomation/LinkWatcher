# New-FeatureImplementationState.ps1
# Creates a new Feature Implementation State tracking file with an automatically assigned feature ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Feature Implementation State tracking file for a feature.

.DESCRIPTION
    This PowerShell script generates Feature Implementation State tracking files by:
    - Generating a unique feature ID (PF-FEA-XXX) automatically
    - Creating a permanent living document for tracking feature implementation
    - Automatically populating metadata (feature ID, name, status)
    - Updating the ID tracker in the central ID registry
    - Placing the file in the correct directory with proper naming convention
    - Providing a complete template initialized with planning-phase sections

    The feature state file is a permanent living document that tracks the feature
    throughout its entire lifecycle and is never archived.

.PARAMETER FeatureName
    Name of the feature (used for document title and context)

.PARAMETER Description
    Brief description of the feature (optional, used in overview section)

.PARAMETER FeatureId
    The feature's tracking ID (e.g., "0.1.1", "1.2.3"). When provided, the script
    automatically links the created implementation state file in the Feature Tracking
    document's ID column, turning the bare ID into a markdown link.

.PARAMETER ImplementationMode
    The implementation mode to set in metadata. Defaults to "PLANNING".
    Use "Retrospective Analysis" when creating state files for pre-existing features
    during onboarding (PF-TSK-064).

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    .\New-FeatureImplementationState.ps1 -FeatureName "user-authentication" -Description "User authentication and authorization system"

.EXAMPLE
    .\New-FeatureImplementationState.ps1 -FeatureName "booking-system" -OpenInEditor

.EXAMPLE
    .\New-FeatureImplementationState.ps1 -FeatureName "core-architecture" -FeatureId "0.1.1" -ImplementationMode "Retrospective Analysis" -Description "Modular architecture"

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Feature state files are PERMANENT and should never be archived
    - Files are placed in doc/process-framework/state-tracking/features/
    - When -FeatureId is provided, automatically links the file in Feature Tracking's ID column
    - When -ImplementationMode "Retrospective Analysis" is used, adds implementation_mode to metadata

    Script Metadata:
    - Script Type: Document Creation Script
    - Created: 2025-10-30
    - Updated: 2026-02-17
    - For: Creating feature implementation state tracking files
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureName,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [string]$FeatureId = "",

    [Parameter(Mandatory = $false)]
    [string]$ImplementationMode = "PLANNING",

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

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_name" = $FeatureName
    "status"       = $ImplementationMode
}

# Add implementation_mode if Retrospective Analysis
if ($ImplementationMode -eq "Retrospective Analysis") {
    $additionalMetadataFields["implementation_mode"] = "Retrospective Analysis"
}

# Add feature_id if provided
if ($FeatureId -ne "") {
    $additionalMetadataFields["feature_id"] = $FeatureId
}

# Prepare custom replacements
$customReplacements = @{
    "[Feature Name]"        = $FeatureName
    "[Feature Description]" = if ($Description -ne "") { $Description } else { "Brief description of the feature" }
    "[Date]"                = Get-Date -Format "yyyy-MM-dd"
    "[Current Status]"      = $ImplementationMode
}

# Create the document using standardized process
try {
    # Build absolute template path using project root
    $projectRoot = Get-ProjectRoot
    $templatePath = Join-Path $projectRoot "doc/process-framework/templates/templates/feature-implementation-state-template.md"

    if (-not (Test-Path $templatePath)) {
        Write-ProjectError -Message "Feature implementation state template not found at: $templatePath - Template file required: feature-implementation-state-template.md" -ExitCode 1
    }

    # Build document name — include FeatureId prefix when provided
    $docName = if ($FeatureId -ne "") { "$FeatureId-$FeatureName-implementation-state" } else { "$FeatureName-implementation-state" }

    # Use FileNamePattern to preserve dots in feature ID (ConvertTo-KebabCase would replace dots with hyphens)
    $documentId = New-StandardProjectDocument `
        -TemplatePath $templatePath `
        -IdPrefix "PF-FEA" `
        -IdDescription "$FeatureName feature implementation state" `
        -DocumentName $docName `
        -DirectoryType "features" `
        -FileNamePattern "$docName.md" `
        -Replacements $customReplacements `
        -AdditionalMetadataFields $additionalMetadataFields `
        -OpenInEditor:$OpenInEditor

    # Link in Feature Tracking if FeatureId was provided
    if ($FeatureId -ne "") {
        $featureTrackingPath = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md"

        if (Test-Path $featureTrackingPath) {
            $ftContent = Get-Content $featureTrackingPath -Raw
            $implStateRelPath = "../features/$docName.md"

            # Escape dots in FeatureId for regex
            $escapedId = [regex]::Escape($FeatureId)

            # Replace bare FeatureId ONLY in the first column of table rows
            # Pattern: start of line "| 0.1.1 |" — avoids matching dependency columns
            $pattern = "(?m)(^\|\s*)$escapedId(\s*\|)"
            $replacement = "`$1[$FeatureId]($implStateRelPath)`$2"
            $updatedFtContent = $ftContent -replace $pattern, $replacement

            if ($updatedFtContent -ne $ftContent) {
                if ($PSCmdlet.ShouldProcess($featureTrackingPath, "Link feature ID $FeatureId to implementation state file")) {
                    Set-Content $featureTrackingPath $updatedFtContent -Encoding UTF8
                    Write-Host "  Linked feature $FeatureId in Feature Tracking" -ForegroundColor Green
                }
            } else {
                Write-Host "  Feature ID $FeatureId not found as bare ID in Feature Tracking (may already be linked)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Feature Tracking file not found - skipping link creation" -ForegroundColor Yellow
        }
    }

    # Provide success details
    $details = @(
        "Feature: $FeatureName",
        "Location: doc/process-framework/state-tracking/features/$docName.md"
    )

    if ($FeatureId -ne "") {
        $details += "Feature ID: $FeatureId (linked in Feature Tracking)"
    }

    if ($Description -ne "") {
        $details += "Description: $Description"
    }

    # Add next steps if not opening in editor
    if (-not $OpenInEditor) {
        $details += @(
            "",
            "📋 NEXT STEPS:",
            "1. Complete the Feature Overview section with business value and scope",
            "2. Copy implementation phases from the implementation plan document",
            "3. Document all design documents with direct links",
            "4. Map specific files in /lib/ and /test/ to implementation phases",
            "5. Document dependencies and integration points",
            "6. Specify next steps (which task definition to use for implementation)",
            "",
            "📖 COMPREHENSIVE GUIDE:",
            "   doc/process-framework/guides/guides/feature-implementation-state-tracking-guide.md",
            "🎯 KEY SECTIONS: Creating and Initializing State Files, Maintenance During Implementation",
            "",
            "⚠️  This is a PERMANENT living document - maintain it throughout the feature lifecycle!",
            "✅ The file provides structure - YOU provide the contextual information."
        )
    }

    Write-ProjectSuccess -Message "Created Feature Implementation State file with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Feature Implementation State file: $($_.Exception.Message)" -ExitCode 1
}

<#
.NOTES
TESTING CHECKLIST:
Before considering this script complete, test the following:

1. MODULE IMPORT TEST:
   - Run the script from its intended directory
   - Verify Common-ScriptHelpers module loads without errors
   - Test with both PowerShell ISE and PowerShell terminal

2. BASIC FUNCTIONALITY TEST:
   - Create a test document with minimal parameters
   - Verify the document is created in the correct location
   - Check that the filename format is correct (feature-name-implementation-state.md)

3. TEMPLATE REPLACEMENT TEST:
   - Open the created document
   - Verify all [Placeholder] values are replaced correctly
   - Check that no template placeholders remain unreplaced
   - Verify the feature ID was assigned automatically

4. ID REGISTRY TEST:
   - Create a test document
   - Check that id-registry.json was updated with nextAvailable incremented
   - Verify the assigned ID appears in the document frontmatter

5. ERROR HANDLING TEST:
   - Test when template file doesn't exist
   - Test when output directory doesn't exist (should create it)
   - Test when file already exists (should prompt for overwrite)
   - Verify error messages are helpful

6. NEXT STEPS OUTPUT TEST:
   - Run script without -OpenInEditor flag
   - Verify next steps display correctly
   - Check that guide references appear as expected
   - Test with -OpenInEditor flag

7. CLEANUP TEST:
   - Remove test documents after verification
   - Ensure no temporary files are left behind

EXAMPLE TEST COMMANDS:
# Basic test
.\New-FeatureImplementationState.ps1 -FeatureName "test-feature" -Description "Test creation"

# Retrospective onboarding test (with feature tracking link)
.\New-FeatureImplementationState.ps1 -FeatureName "test-feature" -FeatureId "9.9.9" -ImplementationMode "Retrospective Analysis" -Description "Test retrospective creation"

# Verify created document (check the actual ID assigned)
Get-ChildItem "doc/process-framework/state-tracking/features/*test-feature*.md" | Get-Content | Select-Object -First 20

# Cleanup (adjust ID as needed based on what was assigned)
Remove-Item "doc/process-framework/state-tracking/features/*test-feature*.md" -Force
#>
