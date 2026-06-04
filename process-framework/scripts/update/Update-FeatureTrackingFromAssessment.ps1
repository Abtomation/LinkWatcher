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
    The assessment ID in format PD-ASS-XXX (e.g., PD-ASS-001)

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
    .\Update-FeatureTrackingFromAssessment.ps1 -AssessmentId "PD-ASS-001"

.EXAMPLE
    .\Update-FeatureTrackingFromAssessment.ps1 -AssessmentId "PD-ASS-002" -FeatureId "2.1.5" -DryRun

.EXAMPLE
    .\Update-FeatureTrackingFromAssessment.ps1 -AssessmentFile "doc/documentation-tiers/assessments/PD-ASS-003-1.4.1-payment-processing.md" -Force

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
    [ValidateSet("⬜ Needs Assessment", "📋 Needs FDD", "🗄️ Needs DB Design", "🔌 Needs API Design", "📝 Needs TDD", "🧪 Needs Test Spec", "🔧 Needs Impl Plan", "🟡 In Progress", "👀 Needs Review", "🔎 Needs Test Scoping", "📖 Needs User Docs", "🔄 Needs Enhancement", "🟢 Completed", "🔴 Blocked", "⏸️ On Hold")]
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
            if ($fileName -match 'PD-ASS-\d+-([0-9]+\.[0-9]+\.[0-9]+)-') {
                $FeatureId = $matches[1]
                Write-Verbose "Extracted Feature ID from filename: $FeatureId"
            } else {
                throw "Could not determine Feature ID. Please provide -FeatureId parameter."
            }
        }
    }

    # Extract assessment ID from content or filename if not provided
    if (-not $AssessmentId) {
        if ($assessmentContent -match 'id:\s*(PD-ASS-\d+)') {
            $AssessmentId = $matches[1]
        } else {
            $fileName = Split-Path $AssessmentFile -Leaf
            if ($fileName -match '(PD-ASS-\d+)-') {
                $AssessmentId = $matches[1]
            }
        }
    }

    # Parse assessment results via the shared helper (PF-IMP-766).
    # Get-FeatureDesignRequirements returns Tier (int) + UI/API/DB Design Required flags
    # in one call, replacing the inline regex block that previously lived here.
    Write-Host "🔍 Analyzing assessment results..." -ForegroundColor Yellow

    $requirements = Get-FeatureDesignRequirements -AssessmentFilePath $AssessmentFile

    $uiDesignRequired  = $requirements.UIDesignRequired
    $apiDesignRequired = $requirements.APIDesignRequired
    $dbDesignRequired  = $requirements.DBDesignRequired

    # Map tier integer to the display string with emoji.
    $tierEmojis = @{
        1 = "🔵 Tier 1"
        2 = "🟡 Tier 2"
        3 = "🔴 Tier 3"
    }
    $recommendedTier = if ($tierEmojis.ContainsKey($requirements.Tier)) { $tierEmojis[$requirements.Tier] } else { "Tier $($requirements.Tier)" }

    # Determine appropriate next-action status if not provided
    # Tier 2+ features need FDD next
    # Tier 1 features skip FDD/TDD/Test Spec — next status depends on DB/API Design columns:
    #   DB Design needed → 🗄️ Needs DB Design
    #   API Design needed (no DB) → 🔌 Needs API Design
    #   Neither → 🔧 Needs Impl Plan (Tier 1 has no TDD; Impl Plan is the next workflow step)
    # Retrospective onboarding: pass -Status "🔎 Needs Test Scoping" to override
    # (code already exists, so Impl Plan is irrelevant)
    if (-not $Status) {
        if ($recommendedTier -match 'Tier 1|🔵') {
            if ($dbDesignRequired) {
                $Status = "🗄️ Needs DB Design"
            } elseif ($apiDesignRequired) {
                $Status = "🔌 Needs API Design"
            } else {
                $Status = "🔧 Needs Impl Plan"
            }
        } else {
            $Status = "📋 Needs FDD"
        }
    }

    # Prepare additional updates
    $additionalUpdates = @{}

    # Get relative path to assessment from feature-tracking.md location.
    # feature-tracking.md lives at doc/state-tracking/permanent/, so the link
    # target is two levels up + documentation-tiers/. PF-IMP-017 fixed the
    # previously-broken rooted form ("doc/documentation-tiers/...") which
    # resolved as doc/state-tracking/permanent/doc/documentation-tiers/...
    $assessmentFileName = Split-Path $AssessmentFile -Leaf
    $assessmentRelativePath = "../../documentation-tiers/assessments/$assessmentFileName"

    # Put the assessment link in the Doc Tier column
    $additionalUpdates["Doc Tier"] = "[$recommendedTier]($assessmentRelativePath)"

    # For 0.x features (architecture/foundation), initialize ADR if needed
    if ($FeatureId -match '^0') {
        # Don't overwrite ADR if it already has a value other than TBD or N/A
        # This logic is handled by Update-FeatureTrackingStatus helper usually
        # but we can specify it here for clarity
        # $additionalUpdates["ADR"] = "TBD"
    }

    # Design requirements ($uiDesignRequired / $apiDesignRequired / $dbDesignRequired)
    # drive the next-action Status above (Tier 1 branches to "🗄️ Needs DB Design" or
    # "🔌 Needs API Design") and are recorded in the assessment Notes below for
    # human visibility. The design-creator wrappers consume the same flags via
    # Get-FeatureDesignRequirements when computing their post-creation next-status.

    # Prepare notes. Recommended tier is already in the Doc Tier column, so
    # only the assessment-link line + design-required flags are appended below.
    $assessmentNotes = @(
        "Assessment completed: $AssessmentId ($(Get-ProjectTimestamp -Format 'Date'))"
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
    Write-Host "  UI Design Required: $uiDesignRequired" -ForegroundColor White
    Write-Host "  API Design Required: $apiDesignRequired" -ForegroundColor White
    Write-Host "  Database Design Required: $dbDesignRequired" -ForegroundColor White
    Write-Host "  New Status: $Status" -ForegroundColor White
    Write-Host ""

    if ($DryRun) {
        Write-Host "DRY RUN: Would update feature tracking for $FeatureId" -ForegroundColor Yellow
        Write-Host "  Status: → $Status" -ForegroundColor Cyan
        Write-Host "  Tier: → $recommendedTier" -ForegroundColor Cyan
        Write-Host "  Notes: $notesString" -ForegroundColor Cyan

        if ($additionalUpdates.Count -gt 3) {
            Write-Host "  Additional Updates:" -ForegroundColor Cyan
            foreach ($key in $additionalUpdates.Keys) {
                if ($key -ne "Tier") {
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
            Write-Verbose "Next Steps: Begin implementation planning (Tier 1 skips FDD/TDD/Test Spec)"
            if ($apiDesignRequired) {
                Write-Verbose "Next Steps: Complete API Design Task before implementation planning"
            }
            if ($dbDesignRequired) {
                Write-Verbose "Next Steps: Complete Database Schema Design Task before implementation planning"
            }
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
