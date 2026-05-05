# Update-FeatureTrackingFromAssessment.ps1
# Updates feature tracking status based on completed assessment results
# Uses the central Common-ScriptHelpers for consistent functionality

<#
.SYNOPSIS
    Updates feature tracking status based on completed documentation tier assessment results.

.DESCRIPTION
    This script automates the update of feature tracking status after an assessment is completed by:
    - Reading the assessment file to determine the recommended documentation tier
    - Updating the feature tracking table with appropriate status and tier information
    - Adding assessment results and next steps to the tracking notes
    - Linking related documentation requirements based on tier assessment
    - Providing automation for the post-assessment workflow

.PARAMETER AssessmentId
    The assessment ID in format ART-ASS-XXX (e.g., ART-ASS-001)

.PARAMETER FeatureId
    The feature ID in format X.X.X (e.g., 1.2.3) - can be auto-detected from assessment file

.PARAMETER AssessmentFile
    Path to the assessment file (optional - will be auto-detected from AssessmentId if not provided)

.PARAMETER Status
    Override the status to set (optional - will be determined from assessment tier if not provided)

.PARAMETER DryRun
    If specified, shows what would be updated without making changes

.PARAMETER Force
    If specified, bypasses confirmation prompts

.EXAMPLE
    .\Update-FeatureTrackingFromAssessment.ps1 -AssessmentId "ART-ASS-001"

.EXAMPLE
    .\Update-FeatureTrackingFromAssessment.ps1 -AssessmentId "ART-ASS-002" -FeatureId "2.1.5" -DryRun

.EXAMPLE
    .\Update-FeatureTrackingFromAssessment.ps1 -AssessmentFile "doc/documentation-tiers/assessments/ART-ASS-003-1.4.1-payment-processing.md" -Force

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Uses Common-ScriptHelpers for consistent functionality
    - Automatically determines next steps based on assessment tier results
    - Updates feature tracking with appropriate status transitions
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$AssessmentId,

    [Parameter(Mandatory=$false)]
    [string]$FeatureId,

    [Parameter(Mandatory=$false)]
    [string]$AssessmentFile,

    [Parameter(Mandatory=$false)]
    [ValidateSet("⬜ Needs Assessment", "📋 Needs FDD", "🗄️ Needs DB Design", "🔌 Needs API Design", "📝 Needs TDD", "🧪 Needs Test Spec", "🔧 Needs Impl Plan", "🟡 In Progress", "👀 Needs Review", "🔄 Needs Enhancement", "🟢 Completed", "🔴 Blocked", "⏸️ On Hold")]
    [string]$Status,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

try {
    # Validate input parameters
    if (-not $AssessmentId -and -not $AssessmentFile) {
        throw "Either AssessmentId or AssessmentFile must be provided"
    }

    # Determine assessment file path
    if (-not $AssessmentFile) {
        $assessmentsDir = Join-Path -Path (Get-ProjectRoot) -ChildPath "doc/documentation-tiers/assessments"

        # Find assessment file by ID
        $assessmentFiles = Get-ChildItem -Path $assessmentsDir -Filter "$AssessmentId-*.md" -ErrorAction SilentlyContinue

        if ($assessmentFiles.Count -eq 0) {
            throw "No assessment file found for ID: $AssessmentId"
        } elseif ($assessmentFiles.Count -gt 1) {
            throw "Multiple assessment files found for ID: $AssessmentId. Please specify AssessmentFile parameter."
        }

        $AssessmentFile = $assessmentFiles[0].FullName
        Write-Verbose "Found assessment file: $($assessmentFiles[0].Name)"
    } else {
        # Convert relative path to absolute if needed
        if (-not [System.IO.Path]::IsPathRooted($AssessmentFile)) {
            $AssessmentFile = Join-Path -Path (Get-ProjectRoot) -ChildPath $AssessmentFile
        }
    }

    # Validate assessment file exists
    if (-not (Test-Path $AssessmentFile)) {
        throw "Assessment file not found: $AssessmentFile"
    }

    # Read and parse assessment file
    Write-Host "📖 Reading assessment file..." -ForegroundColor Yellow
    $assessmentContent = Get-Content $AssessmentFile -Raw

    # Extract feature ID from assessment content if not provided
    if (-not $FeatureId) {
        if ($assessmentContent -match 'feature_id:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
            $FeatureId = $matches[1]
            Write-Verbose "Extracted Feature ID from assessment: $FeatureId"
        } else {
            # Try to extract from filename
            $fileName = Split-Path $AssessmentFile -Leaf
            if ($fileName -match 'ART-ASS-\d+-([0-9]+\.[0-9]+\.[0-9]+)-') {
                $FeatureId = $matches[1]
                Write-Verbose "Extracted Feature ID from filename: $FeatureId"
            } else {
                throw "Could not determine Feature ID. Please provide -FeatureId parameter."
            }
        }
    }

    # Extract assessment ID from content or filename if not provided
    if (-not $AssessmentId) {
        if ($assessmentContent -match 'id:\s*(ART-ASS-\d+)') {
            $AssessmentId = $matches[1]
        } else {
            $fileName = Split-Path $AssessmentFile -Leaf
            if ($fileName -match '(ART-ASS-\d+)-') {
                $AssessmentId = $matches[1]
            }
        }
    }

    # Parse assessment results
    Write-Host "🔍 Analyzing assessment results..." -ForegroundColor Yellow

    # Extract recommended tier
    $recommendedTier = "Unknown"
    # Check for checked tier checkbox pattern: [x] Tier X (...)
    if ($assessmentContent -match '\[x\]\s+Tier\s+(\d+)') {
        $recommendedTier = "Tier $($matches[1])"
    }
    # Fallback to text-based patterns
    elseif ($assessmentContent -match '(?i)recommended\s+(?:documentation\s+)?tier[:\s]*(\d+)') {
        $recommendedTier = "Tier $($matches[1])"
    } elseif ($assessmentContent -match '(?i)tier\s+(\d+)\s+(?:is\s+)?recommended') {
        $recommendedTier = "Tier $($matches[1])"
    }

    # Extract complexity assessment
    $complexityLevel = "Unknown"
    if ($assessmentContent -match '(?i)complexity[:\s]*([a-zA-Z]+)') {
        $complexityLevel = $matches[1]
    }

    # Extract UI design requirement (check for [x] Yes checkbox or text patterns)
    $uiDesignRequired = $false
    if ($assessmentContent -match '###\s+UI\s+Design\s+Required[\s\S]{0,100}\[\s*[xX]\s*\]\s+Yes') {
        $uiDesignRequired = $true
    } elseif ($assessmentContent -match '(?i)ui\s+design[:\s]+(?:yes|true)') {
        # Only match if followed by a separator and then yes/true to avoid header matching
        $uiDesignRequired = $true
    }

    # Extract API design requirement (check for [x] Yes checkbox or text patterns)
    $apiDesignRequired = $false
    if ($assessmentContent -match '###\s+API\s+Design\s+Required[\s\S]{0,100}\[\s*[xX]\s*\]\s+Yes') {
        $apiDesignRequired = $true
    } elseif ($assessmentContent -match '(?i)api\s+design[:\s]+(?:yes|true)') {
        # Only match if followed by a separator and then yes/true to avoid header matching
        $apiDesignRequired = $true
    }

    # Extract database design requirement (check for [x] Yes checkbox or text patterns)
    $dbDesignRequired = $false
    if ($assessmentContent -match '###\s+Database\s+Design\s+Required[\s\S]{0,100}\[\s*[xX]\s*\]\s+Yes') {
        $dbDesignRequired = $true
    } elseif ($assessmentContent -match '(?i)database\s+(?:schema\s+)?design[:\s]+(?:yes|true)') {
        # Only match if followed by a separator and then yes/true to avoid header matching
        $dbDesignRequired = $true
    }

    # Add tier emoji to recommended tier
    $tierEmojis = @{
        "Tier 1" = "🔵 Tier 1"
        "Tier 2" = "🟡 Tier 2"
        "Tier 3" = "🔴 Tier 3"
    }
    if ($tierEmojis.ContainsKey($recommendedTier)) {
        $recommendedTier = $tierEmojis[$recommendedTier]
    }

    # Determine appropriate next-action status if not provided
    # Tier 2+ features need FDD next
    # Tier 1 features skip FDD — next status depends on DB/API Design columns:
    #   DB Design needed → 🗄️ Needs DB Design
    #   API Design needed (no DB) → 🔌 Needs API Design
    #   Neither → 📝 Needs TDD
    if (-not $Status) {
        if ($recommendedTier -match 'Tier 1|🔵') {
            if ($dbDesignRequired) {
                $Status = "🗄️ Needs DB Design"
            } elseif ($apiDesignRequired) {
                $Status = "🔌 Needs API Design"
            } else {
                $Status = "📝 Needs TDD"
            }
        } else {
            $Status = "📋 Needs FDD"
        }
    }

    # Prepare additional updates
    $additionalUpdates = @{}

    # Get relative path to assessment from feature-tracking.md location
    $assessmentFileName = Split-Path $AssessmentFile -Leaf
    $assessmentRelativePath = "doc/documentation-tiers/assessments/$assessmentFileName"

    # Put the assessment link in the Doc Tier column
    $additionalUpdates["Doc Tier"] = "[$recommendedTier]($assessmentRelativePath)"

    # For 0.x features (architecture/foundation), initialize ADR if needed
    if ($FeatureId -match '^0') {
        # Don't overwrite ADR if it already has a value other than TBD or N/A
        # This logic is handled by Update-FeatureTrackingStatus helper usually
        # but we can specify it here for clarity
        # $additionalUpdates["ADR"] = "TBD"
    }

    # Add UI design status
    if ($uiDesignRequired) {
        $additionalUpdates["UI Design"] = "Required"
    } else {
        $additionalUpdates["UI Design"] = "No"
    }

    # Add API design status
    if ($apiDesignRequired) {
        $additionalUpdates["API Design"] = "Required"
    } else {
        $additionalUpdates["API Design"] = "No"
    }

    # Add database design status
    if ($dbDesignRequired) {
        $additionalUpdates["DB Design"] = "Required"
    } else {
        $additionalUpdates["DB Design"] = "No"
    }

    # Prepare notes
    $assessmentNotes = @(
        "Assessment completed: $AssessmentId ($(Get-ProjectTimestamp -Format 'Date'))",
        "Recommended: $recommendedTier",
        "Complexity: $complexityLevel"
    )

    if ($uiDesignRequired) { $assessmentNotes += "UI Design: Required" }

    if ($apiDesignRequired) {
        $assessmentNotes += "API Design: Required"
    }

    if ($dbDesignRequired) {
        $assessmentNotes += "Database Design: Required"
    }

    $notesString = $assessmentNotes -join "; "

    # Make notes idempotent: check if this assessment is already recorded in feature-tracking.md
    $featureTrackingPath = Join-Path -Path (Get-ProjectRoot) -ChildPath "doc/state-tracking/permanent/feature-tracking.md"
    if (Test-Path $featureTrackingPath) {
        $ftContent = Get-Content $featureTrackingPath -Raw -Encoding UTF8
        if ($ftContent -match [regex]::Escape($AssessmentId)) {
            $notesString = ""
            Write-Verbose "Assessment $AssessmentId already recorded in notes — skipping note append"
        }
    }

    # Display what will be updated
    Write-Host ""
    Write-Host "📋 Assessment Analysis Results:" -ForegroundColor Cyan
    Write-Host "  Feature ID: $FeatureId" -ForegroundColor White
    Write-Host "  Assessment ID: $AssessmentId" -ForegroundColor White
    Write-Host "  Recommended Tier: $recommendedTier" -ForegroundColor White
    Write-Host "  Complexity: $complexityLevel" -ForegroundColor White
    Write-Host "  UI Design Required: $uiDesignRequired" -ForegroundColor White
    Write-Host "  API Design Required: $apiDesignRequired" -ForegroundColor White
    Write-Host "  Database Design Required: $dbDesignRequired" -ForegroundColor White
    Write-Host "  New Status: $Status" -ForegroundColor White
    Write-Host ""

    if ($DryRun) {
        Write-Host "DRY RUN: Would update feature tracking for $FeatureId" -ForegroundColor Yellow
        Write-Host "  Status: → $Status" -ForegroundColor Cyan
        Write-Host "  Tier: → $recommendedTier" -ForegroundColor Cyan
        Write-Host "  Complexity: → $complexityLevel" -ForegroundColor Cyan
        Write-Host "  Notes: $notesString" -ForegroundColor Cyan

        if ($additionalUpdates.Count -gt 3) {
            Write-Host "  Additional Updates:" -ForegroundColor Cyan
            foreach ($key in $additionalUpdates.Keys) {
                if ($key -notin @("Tier", "Complexity")) {
                    Write-Host "    $key`: $($additionalUpdates[$key])" -ForegroundColor Cyan
                }
            }
        }
        return
    }

    # Confirm update unless Force is specified
    if (-not $Force) {
        $confirmation = Read-Host "Update feature tracking for $FeatureId with assessment results? (Y/n)"
        if ($confirmation -and $confirmation -ne 'Y' -and $confirmation -ne 'y' -and $confirmation -ne '') {
            Write-Host "Update cancelled by user." -ForegroundColor Yellow
            return
        }
    }

    # Validate dependencies for automation
    Write-Host "🤖 Updating Feature Tracking..." -ForegroundColor Yellow

    $dependencyCheck = Test-ScriptDependencies -RequiredFunctions @(
        "Update-FeatureTrackingStatus"
    )

    if (-not $dependencyCheck.AllDependenciesMet) {
        Write-Warning "Automation dependencies not available. Feature tracking must be updated manually."
        Write-Host "Manual Update Required:" -ForegroundColor Yellow
        Write-Host "  - Feature ID: $FeatureId" -ForegroundColor Cyan
        Write-Host "  - Status: $Status" -ForegroundColor Cyan
        Write-Host "  - Tier: $recommendedTier" -ForegroundColor Cyan
        Write-Host "  - Complexity: $complexityLevel" -ForegroundColor Cyan
        Write-Host "  - Notes: $notesString" -ForegroundColor Cyan
        return
    }

    # Update feature tracking with assessment results
    $updateResult = Update-FeatureTrackingStatus -FeatureId $FeatureId -Status $Status -AdditionalUpdates $additionalUpdates -Notes $notesString

    Write-ProjectSuccess -Message "Feature tracking updated successfully" -Details @(
        "Feature: $FeatureId",
        "Status: $Status",
        "Tier: $recommendedTier",
        "Assessment: $AssessmentId"
    )

    # Provide next steps based on tier (verbose-only — restore with -Verbose)
    switch ($recommendedTier) {
        "Tier 1" {
            Write-Verbose "Next Steps: Create Technical Design Document (TDD)"
            Write-Verbose "Next Steps: Begin implementation planning"
        }
        "Tier 2" {
            Write-Verbose "Next Steps: Create Functional Design Document (FDD)"
            Write-Verbose "Next Steps: Create Technical Design Document (TDD) after FDD approval"
            if ($apiDesignRequired) {
                Write-Verbose "Next Steps: Complete API Design Task"
            }
            if ($dbDesignRequired) {
                Write-Verbose "Next Steps: Complete Database Schema Design Task"
            }
        }
        "Tier 3" {
            Write-Verbose "Next Steps: Create Functional Design Document (FDD)"
            Write-Verbose "Next Steps: Conduct Architecture Review"
            Write-Verbose "Next Steps: Create Technical Design Document (TDD)"
            if ($apiDesignRequired) {
                Write-Verbose "Next Steps: Complete API Design Task"
            }
            if ($dbDesignRequired) {
                Write-Verbose "Next Steps: Complete Database Schema Design Task"
            }
        }
        default {
            Write-Verbose "Next Steps: Review assessment results and determine next steps"
        }
    }
}
catch {
    Write-ProjectError -Message "Failed to update feature tracking from assessment: $($_.Exception.Message)" -ExitCode 1
}
