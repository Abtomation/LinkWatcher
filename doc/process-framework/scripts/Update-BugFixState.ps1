#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates state file updates for Bug Fixing Task (PF-TSK-007)

.DESCRIPTION
This script automates the manual state file updates required by the Bug Fixing Task,
addressing the critical bottleneck identified in the Process Improvement Tracking.

Updates the following files:
- doc/process-framework/state-tracking/permanent/feature-tracking.md

.PARAMETER FeatureId
The feature ID where the bug was reported (e.g., "1.2.3")

.PARAMETER BugDescription
Brief description of the bug that was fixed

.PARAMETER RootCause
Description of the root cause of the bug

.PARAMETER Solution
Description of the solution implemented

.PARAMETER FixDate
Bug fix completion date (optional - uses current date if not specified)

.PARAMETER PullRequestUrl
URL to the pull request or commit containing the fix (optional)

.PARAMETER TestsUpdated
Whether tests were updated/added to prevent regression (Yes/No)

.PARAMETER LessonsLearned
Lessons learned for future development (optional)

.PARAMETER PreventionMeasures
Measures taken to prevent similar bugs (optional)

.PARAMETER DryRun
If specified, shows what would be updated without making changes

.EXAMPLE
.\Update-BugFixState.ps1 -FeatureId "1.2.3" -BugDescription "Login form validation error" -RootCause "Missing null check" -Solution "Added proper validation"

.EXAMPLE
.\Update-BugFixState.ps1 -FeatureId "1.2.3" -BugDescription "Performance issue in search" -RootCause "Inefficient database query" -Solution "Optimized query with indexes" -PullRequestUrl "https://github.com/repo/pull/456" -TestsUpdated "Yes"

.EXAMPLE
.\Update-BugFixState.ps1 -FeatureId "1.2.3" -BugDescription "UI layout bug" -RootCause "CSS specificity issue" -Solution "Fixed CSS selectors" -LessonsLearned "Need better CSS organization" -DryRun

.NOTES
This script requires:
- Access to the Process Framework automation infrastructure
- Update-FeatureTrackingStatus function from Common-ScriptHelpers.psm1
- PowerShell 5.1 or later

Created for: Bug Fixing Task (PF-TSK-007)
Purpose: Automate bug fix state updates in feature tracking
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureId,

    [Parameter(Mandatory=$true)]
    [string]$BugDescription,

    [Parameter(Mandatory=$true)]
    [string]$RootCause,

    [Parameter(Mandatory=$true)]
    [string]$Solution,

    [Parameter(Mandatory=$false)]
    [string]$FixDate = "",

    [Parameter(Mandatory=$false)]
    [string]$PullRequestUrl = "",

    [Parameter(Mandatory=$false)]
    [ValidateSet("Yes", "No", "")]
    [string]$TestsUpdated = "",

    [Parameter(Mandatory=$false)]
    [string]$LessonsLearned = "",

    [Parameter(Mandatory=$false)]
    [string]$PreventionMeasures = "",

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Import the common helpers
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$helpersPath = Join-Path $scriptDir "Common-ScriptHelpers.psm1"

if (Test-Path $helpersPath) {
    Import-Module $helpersPath -Force
} else {
    Write-Error "Cannot find common helpers at: $helpersPath"
    exit 1
}

# Perform standard initialization
Invoke-StandardScriptInitialization

# Set default fix date if not provided
if ($FixDate -eq "") {
    $FixDate = Get-Date -Format "yyyy-MM-dd"
}

Write-Host "🐛 Bug Fix State Update" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host "Feature ID: $FeatureId" -ForegroundColor White
Write-Host "Bug: $BugDescription" -ForegroundColor White
Write-Host "Root Cause: $RootCause" -ForegroundColor White
Write-Host "Solution: $Solution" -ForegroundColor White
Write-Host "Fix Date: $FixDate" -ForegroundColor White

if ($PullRequestUrl -ne "") {
    Write-Host "Pull Request: $PullRequestUrl" -ForegroundColor White
}

if ($TestsUpdated -ne "") {
    Write-Host "Tests Updated: $TestsUpdated" -ForegroundColor White
}

Write-Host ""

try {
    # Check if automation functions are available
    $automationFunctions = @(
        "Update-FeatureTrackingStatus"
    )

    $missingFunctions = $automationFunctions | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }

    if ($missingFunctions.Count -eq 0) {
        Write-Host "🔄 Updating bug fix state..." -ForegroundColor Cyan

        # Prepare bug fix documentation
        $bugFixNotes = @()
        $bugFixNotes += "🐛 Bug Fixed: $BugDescription"
        $bugFixNotes += "🔍 Root Cause: $RootCause"
        $bugFixNotes += "✅ Solution: $Solution"
        $bugFixNotes += "📅 Fix Date: $FixDate"

        if ($PullRequestUrl -ne "") {
            $bugFixNotes += "🔗 PR/Commit: $PullRequestUrl"
        }

        if ($TestsUpdated -ne "") {
            $bugFixNotes += "🧪 Tests Updated: $TestsUpdated"
        }

        if ($LessonsLearned -ne "") {
            $bugFixNotes += "📚 Lessons Learned: $LessonsLearned"
        }

        if ($PreventionMeasures -ne "") {
            $bugFixNotes += "🛡️ Prevention: $PreventionMeasures"
        }

        # Combine notes into a single string
        $automationNotes = $bugFixNotes -join " | "

        # Prepare additional updates for feature tracking
        $additionalUpdates = @{}

        # Add bug status update to Notes column
        $bugStatusUpdate = "Bug Fixed ($FixDate): $BugDescription - $Solution"
        if ($PullRequestUrl -ne "") {
            $bugStatusUpdate += " [PR]($PullRequestUrl)"
        }

        if ($DryRun) {
            Write-Host "DRY RUN: Would update bug fix state for $FeatureId" -ForegroundColor Yellow
            Write-Host "  Bug Description: $BugDescription" -ForegroundColor Cyan
            Write-Host "  Root Cause: $RootCause" -ForegroundColor Cyan
            Write-Host "  Solution: $Solution" -ForegroundColor Cyan
            Write-Host "  Fix Date: $FixDate" -ForegroundColor Cyan
            if ($PullRequestUrl -ne "") {
                Write-Host "  Pull Request: $PullRequestUrl" -ForegroundColor Cyan
            }
            if ($TestsUpdated -ne "") {
                Write-Host "  Tests Updated: $TestsUpdated" -ForegroundColor Cyan
            }
            if ($LessonsLearned -ne "") {
                Write-Host "  Lessons Learned: $LessonsLearned" -ForegroundColor Cyan
            }
            if ($PreventionMeasures -ne "") {
                Write-Host "  Prevention Measures: $PreventionMeasures" -ForegroundColor Cyan
            }
            Write-Host "  Notes Update: $automationNotes" -ForegroundColor Cyan
        } else {
            # Update feature tracking with bug fix completion
            $updateResult = Update-FeatureTrackingStatus -FeatureId $FeatureId -AdditionalUpdates $additionalUpdates -Notes $automationNotes -DryRun:$DryRun

            Write-Host "  ✅ Bug fix state updated successfully" -ForegroundColor Green
            Write-Host "  🐛 Bug: $BugDescription" -ForegroundColor Green
            Write-Host "  🔍 Root Cause: $RootCause" -ForegroundColor Green
            Write-Host "  ✅ Solution: $Solution" -ForegroundColor Green
            Write-Host "  📅 Fix Date: $FixDate" -ForegroundColor Green

            if ($PullRequestUrl -ne "") {
                Write-Host "  🔗 Pull Request linked: $PullRequestUrl" -ForegroundColor Green
            }

            if ($TestsUpdated -ne "") {
                Write-Host "  🧪 Tests Updated: $TestsUpdated" -ForegroundColor Green
            }

            Write-Host "  📝 Feature tracking updated with bug fix details" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️  Automation functions not available:" -ForegroundColor Yellow
        Write-Host "Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Yellow
        Write-Host "Manual Update Required:" -ForegroundColor Yellow
        Write-Host "  - Update feature $FeatureId in feature-tracking.md" -ForegroundColor Cyan
        Write-Host "  - Add bug fix details to Notes column:" -ForegroundColor Cyan
        Write-Host "    Bug Fixed ($FixDate): $BugDescription - $Solution" -ForegroundColor Cyan
        if ($PullRequestUrl -ne "") {
            Write-Host "    PR/Commit: $PullRequestUrl" -ForegroundColor Cyan
        }
        if ($LessonsLearned -ne "") {
            Write-Host "    Lessons Learned: $LessonsLearned" -ForegroundColor Cyan
        }
    }

    # Provide success summary
    Write-Host ""
    Write-Host "🎉 Bug Fix State Update Complete!" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green

    $summaryDetails = @(
        "Feature ID: $FeatureId",
        "Bug: $BugDescription",
        "Root Cause: $RootCause",
        "Solution: $Solution",
        "Fix Date: $FixDate"
    )

    if ($PullRequestUrl -ne "") {
        $summaryDetails += "Pull Request: $PullRequestUrl"
    }

    if ($TestsUpdated -ne "") {
        $summaryDetails += "Tests Updated: $TestsUpdated"
    }

    if ($LessonsLearned -ne "") {
        $summaryDetails += "Lessons Learned: $LessonsLearned"
    }

    if ($PreventionMeasures -ne "") {
        $summaryDetails += "Prevention Measures: $PreventionMeasures"
    }

    Write-ProjectSuccess -Message "Bug fix state updated for feature $FeatureId" -Details $summaryDetails

} catch {
    Write-ProjectError -Message "Failed to update bug fix state: $($_.Exception.Message)" -ExitCode 1
}
