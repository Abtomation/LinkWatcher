# New-FeatureImplementationState.ps1
# Creates a new Feature Implementation State tracking file with an automatically assigned feature ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Feature Implementation State tracking file for a feature.

.DESCRIPTION
    This PowerShell script generates Feature Implementation State tracking files by:
    - Generating a unique feature ID (PD-FIS-XXX) automatically
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

.PARAMETER Lightweight
    When specified, uses the lightweight template variant (7 sections instead of 10).
    Recommended for Tier 1 features and retrospective analysis of simple features.
    The lightweight template omits Implementation Progress, Dimension Profile, and
    merges Issues/Next Steps into a compact Notes section.

.PARAMETER ImplementationMode
    The implementation mode to set in metadata. Defaults to "PLANNING".
    Use "Retrospective Analysis" when creating state files for pre-existing features
    during onboarding (PF-TSK-064).

.PARAMETER Dims
    Optional hashtable mapping dimension abbreviations to "Importance|Considerations" strings.
    Valid abbreviations: AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI.
    Importance must be: Critical, Relevant, or N/A.
    Example: @{ "SE" = "Critical|Validate path traversal, sanitize inputs"; "UX" = "N/A|No UI components" }
    Dimensions marked N/A go to the "Not Applicable" table; others go to "Applicable Dimensions".
    Core dimensions (AC, CQ, ID, DA) default to Relevant if not specified.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    New-FeatureImplementationState.ps1 -FeatureName "user-authentication" -Description "User authentication and authorization system"

.EXAMPLE
    New-FeatureImplementationState.ps1 -FeatureName "booking-system" -OpenInEditor

.EXAMPLE
    New-FeatureImplementationState.ps1 -FeatureName "core-architecture" -FeatureId "0.1.1" -ImplementationMode "Retrospective Analysis" -Description "Modular architecture"

.EXAMPLE
    New-FeatureImplementationState.ps1 -FeatureName "simple-feature" -FeatureId "1.1.0" -Lightweight -Description "Simple Tier 1 feature"

.EXAMPLE
    New-FeatureImplementationState.ps1 -FeatureName "file-processor" -FeatureId "2.1.1" -Dims @{ "SE" = "Critical|Validate user paths"; "PE" = "Critical|Batch I/O"; "UX" = "N/A|CLI tool" }

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Feature state files are PERMANENT and should never be archived
    - Files are placed in doc/state-tracking/features/
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
    [switch]$Lightweight,

    [Parameter(Mandatory = $false)]
    [string]$ImplementationMode = "PLANNING",

    [Parameter(Mandatory = $false)]
    [hashtable]$Dims = @{},

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers with walk-up path resolution
$dir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
try {
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers module. Searched up from: $PSScriptRoot"
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
    $templateFileName = if ($Lightweight) { "feature-implementation-state-lightweight-template.md" } else { "feature-implementation-state-template.md" }
    $templatePath = Join-Path $projectRoot "process-framework/templates/04-implementation/$templateFileName"

    if (-not (Test-Path $templatePath)) {
        Write-ProjectError -Message "Feature implementation state template not found at: $templatePath - Template file required: $templateFileName" -ExitCode 1
    }

    if ($Lightweight) {
        Write-Host "  Using lightweight template (Tier 1 / retrospective)" -ForegroundColor Cyan
    }

    # Build document name — include FeatureId prefix when provided
    # Replace spaces with hyphens to prevent broken markdown links in VS Code and other renderers
    $sanitizedName = $FeatureName -replace '\s+', '-'
    $docName = if ($FeatureId -ne "") { "$FeatureId-$sanitizedName-implementation-state" } else { "$sanitizedName-implementation-state" }

    # Use FileNamePattern to preserve dots in feature ID (ConvertTo-KebabCase would replace dots with hyphens)
    $documentId = New-StandardProjectDocument `
        -TemplatePath $templatePath `
        -IdPrefix "PD-FIS" `
        -IdDescription "$FeatureName feature implementation state" `
        -DocumentName $docName `
        -DirectoryType "features" `
        -FileNamePattern "$docName.md" `
        -Replacements $customReplacements `
        -AdditionalMetadataFields $additionalMetadataFields `
        -OpenInEditor:$OpenInEditor

    # Link in Feature Tracking if FeatureId was provided
    if ($FeatureId -ne "") {
        $featureTrackingPath = Join-Path $projectRoot "doc/state-tracking/permanent/feature-tracking.md"

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

    # Populate Dimension Profile section if -Dims was provided (full template only)
    if ($Dims.Count -gt 0 -and -not $Lightweight) {
        $createdFilePath = Join-Path $projectRoot "doc/state-tracking/features/$docName.md"
        if (Test-Path $createdFilePath) {
            $dimensionNames = @{
                "AC" = "Architectural Consistency"
                "CQ" = "Code Quality & Standards"
                "ID" = "Integration & Dependencies"
                "DA" = "Documentation Alignment"
                "EM" = "Extensibility & Maintainability"
                "SE" = "Security & Data Protection"
                "PE" = "Performance & Scalability"
                "OB" = "Observability"
                "UX" = "Accessibility / UX Compliance"
                "DI" = "Data Integrity"
            }

            $applicableRows = @()
            $naRows = @()

            foreach ($abbr in $Dims.Keys) {
                $abbrUpper = $abbr.ToUpper()
                if (-not $dimensionNames.ContainsKey($abbrUpper)) {
                    Write-Host "  Warning: Unknown dimension abbreviation '$abbr' — skipping" -ForegroundColor Yellow
                    continue
                }
                $fullName = $dimensionNames[$abbrUpper]
                $parts = $Dims[$abbr] -split '\|', 2
                $importance = $parts[0].Trim()
                $considerations = if ($parts.Length -gt 1) { $parts[1].Trim() } else { "" }

                if ($importance -eq "N/A") {
                    $naRows += "| $fullName ($abbrUpper) | $considerations |"
                } else {
                    $applicableRows += "| $fullName ($abbrUpper) | $importance | $considerations |"
                }
            }

            $fileContent = Get-Content $createdFilePath -Raw

            # Replace the placeholder applicable row
            $applicableTable = if ($applicableRows.Count -gt 0) {
                $applicableRows -join "`n"
            } else {
                "| *(none evaluated)* | | |"
            }
            $fileContent = $fileContent -replace '\| \[Dimension Name \(ABBR\)\] \| \[Critical / Relevant\] \| \[1-line: what to watch for in this feature\] \|', $applicableTable

            # Replace the placeholder N/A row
            $naTable = if ($naRows.Count -gt 0) {
                $naRows -join "`n"
            } else {
                "| *(none)* | |"
            }
            $fileContent = $fileContent -replace '\| \[Dimension Name \(ABBR\)\] \| \[Why this dimension does not apply\] \|', $naTable

            # Replace the "Last reviewed" date
            $fileContent = $fileContent -replace '\*\*Last reviewed\*\*: \[YYYY-MM-DD\]', "**Last reviewed**: $(Get-Date -Format 'yyyy-MM-dd')"

            if ($PSCmdlet.ShouldProcess($createdFilePath, "Populate Dimension Profile")) {
                Set-Content $createdFilePath $fileContent -Encoding UTF8
                Write-Host "  Populated Dimension Profile ($($Dims.Count) dimensions)" -ForegroundColor Green
            }
        }
    }

    # --- Post-action: Update source structure if source-code-layout.md exists ---
    $layoutDocPath = Join-Path $projectRoot "doc/technical/architecture/source-code-layout.md"
    if ((Test-Path $layoutDocPath) -and $FeatureName -ne "") {
        $sourceStructureScript = Join-Path $projectRoot "process-framework/scripts/file-creation/00-setup/New-SourceStructure.ps1"
        if (Test-Path $sourceStructureScript) {
            try {
                Write-Host "  Updating source structure for feature '$FeatureName'..." -ForegroundColor Cyan
                & $sourceStructureScript -Update -FeatureName $FeatureName -Confirm:$false
            } catch {
                Write-Host "  Warning: Source structure update failed: $($_.Exception.Message)" -ForegroundColor Yellow
                Write-Host "  Run manually: New-SourceStructure.ps1 -Update -FeatureName `"$FeatureName`"" -ForegroundColor Yellow
            }
        }
    }

    # Provide success details
    $details = @(
        "Feature: $FeatureName",
        "Location: doc/state-tracking/features/$docName.md"
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
            "process-framework/guides/04-implementation/feature-implementation-state-tracking-guide.md",
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
   - Check that the appropriate ID registry was updated with nextAvailable incremented
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
New-FeatureImplementationState.ps1 -FeatureName "test-feature" -Description "Test creation"

# Retrospective onboarding test (with feature tracking link)
New-FeatureImplementationState.ps1 -FeatureName "test-feature" -FeatureId "9.9.9" -ImplementationMode "Retrospective Analysis" -Description "Test retrospective creation"

# Verify created document (check the actual ID assigned)
Get-ChildItem "doc/state-tracking/features/*test-feature*.md" | Get-Content | Select-Object -First 20

# Cleanup (adjust ID as needed based on what was assigned)
Remove-Item "doc/state-tracking/features/*test-feature*.md" -Force
#>
