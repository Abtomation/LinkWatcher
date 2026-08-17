<#
.SYNOPSIS
Validates feedback forms for completeness and flags forms still containing template placeholders.

.DESCRIPTION
Helps prevent incomplete forms from wasting tools review analysis time.

.PARAMETER FeedbackFormsPath
Directory of feedback forms to validate. Omitted reads the central feedback/feedback-forms
directory (resolved via Get-CentralFrameworkPath), so the default works from any cwd.

.PARAMETER ShowComplete
Also lists the forms that passed, instead of reporting only the incomplete ones.

.PARAMETER FixIncomplete
Moves incomplete forms into feedback/archive/incomplete/, creating that directory if needed.
Without this switch the script only reports. Subject to the -GraceMinutes recency guard.

.PARAMETER GraceMinutes
Recency guard for -FixIncomplete: forms modified within this many minutes are left in place,
because a freshly created blank form may be mid-fill in another session. Defaults to 120; set to
0 for a deliberate full sweep when nothing is known to be in flight.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$FeedbackFormsPath = "",

    [Parameter(Mandatory=$false)]
    [switch]$ShowComplete,

    [Parameter(Mandatory=$false)]
    [switch]$FixIncomplete,

    # PF-IMP-1305: recency guard for -FixIncomplete. Forms modified within this many minutes are
    # left in place — a freshly created blank form may be mid-fill in another session, and sweeping
    # it triggers a confusing "missing form" investigation (PF-FEE-1414). Set to 0 for a deliberate
    # full sweep when nothing is known to be in flight.
    [Parameter(Mandatory=$false)]
    [int]$GraceMinutes = 120
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

Write-Host "🔍 Validating Feedback Forms..." -ForegroundColor Cyan
Write-Host ""

# Get all feedback form files. Phase 7 (2026-05-11): default reads from the central
# feedback-forms directory under appdev (resolved via Get-CentralFrameworkPath, so the
# script works the same from cwd=appdev and cwd=project).
if ([string]::IsNullOrEmpty($FeedbackFormsPath)) {
    $feedbackFormsDir = Join-Path -Path (Get-CentralFrameworkPath) -ChildPath "feedback/feedback-forms"
} elseif ([System.IO.Path]::IsPathRooted($FeedbackFormsPath)) {
    $feedbackFormsDir = $FeedbackFormsPath
} else {
    $feedbackFormsDir = Join-Path (Get-Location) $FeedbackFormsPath
}
$feedbackFiles = Get-ChildItem -Path $feedbackFormsDir -Filter "*.md" | Sort-Object Name

if ($feedbackFiles.Count -eq 0) {
    Write-Host "❌ No feedback forms found in $feedbackFormsDir" -ForegroundColor Red
    exit 1
}

Write-Host "📊 Found $($feedbackFiles.Count) feedback forms to validate" -ForegroundColor Green
Write-Host ""

# Define template placeholders that indicate incomplete forms
$templatePlaceholders = @(
    "[Rating]",
    "[Tool display name]",
    "[How this tool was used in the task]",
    "[Detailed comments about",
    "[Brief comments]",
    "[Overall assessment of",
    "[Assessment of process",
    "[FEEDBACK_TYPE]",
    "[DOCUMENT_ID]",
    "[TASK_CONTEXT]"
)

$incompleteFiles = @()
$completeFiles = @()
$validationResults = @()

foreach ($file in $feedbackFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $placeholdersFound = @()

    # Remove instruction sections that contain example placeholders
    # Remove content between > ** markers (instruction blocks)
    $contentToCheck = $content -replace '(?s)> \*\*.*?\*\*.*?(?=\n[^>]|\n$)', ''

    # Remove the quick start instruction block
    $contentToCheck = $contentToCheck -replace '(?s)> \*\*🚀 Quick Start\*\*.*?(?=\n[^>]|\n$)', ''

    # Remove content in blockquotes that contain instruction text
    $contentToCheck = $contentToCheck -replace '(?s)> \*\*CRITICAL\*\*.*?(?=\n[^>]|\n$)', ''

    # Remove fenced code blocks, then inline code spans (PF-IMP-1607): a code-quoted MENTION
    # of a placeholder token (e.g. a suggestion about `[DOCUMENT_ID]`) is not an unfilled
    # placeholder. The template's real placeholders never sit inside code, so a genuinely
    # unfilled form still matches after the strip.
    $contentToCheck = $contentToCheck -replace '(?s)```.*?```', ''
    $contentToCheck = $contentToCheck -replace '`[^`\r\n]+`', ''

    # Check for template placeholders in the cleaned content
    foreach ($placeholder in $templatePlaceholders) {
        if ($contentToCheck -match [regex]::Escape($placeholder)) {
            $placeholdersFound += $placeholder
        }
    }

    $result = [PSCustomObject]@{
        FileName = $file.Name
        FilePath = $file.FullName
        LastWriteTime = $file.LastWriteTime
        IsComplete = $placeholdersFound.Count -eq 0
        PlaceholdersFound = $placeholdersFound
        PlaceholderCount = $placeholdersFound.Count
    }

    $validationResults += $result

    if ($result.IsComplete) {
        $completeFiles += $result
    } else {
        $incompleteFiles += $result
    }
}

# Display results
Write-Host "📈 VALIDATION RESULTS" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow
Write-Host ""

if ($incompleteFiles.Count -gt 0) {
    Write-Host "❌ INCOMPLETE FORMS ($($incompleteFiles.Count)):" -ForegroundColor Red
    Write-Host ""

    foreach ($incomplete in $incompleteFiles) {
        Write-Host "  📄 $($incomplete.FileName)" -ForegroundColor Red
        Write-Host "     Placeholders found: $($incomplete.PlaceholderCount)" -ForegroundColor Yellow

        if ($incomplete.PlaceholdersFound.Count -le 5) {
            foreach ($placeholder in $incomplete.PlaceholdersFound) {
                Write-Host "     - $placeholder" -ForegroundColor Gray
            }
        } else {
            Write-Host "     - $($incomplete.PlaceholdersFound[0])" -ForegroundColor Gray
            Write-Host "     - $($incomplete.PlaceholdersFound[1])" -ForegroundColor Gray
            Write-Host "     - ... and $($incomplete.PlaceholdersFound.Count - 2) more" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

if ($ShowComplete -and $completeFiles.Count -gt 0) {
    Write-Host "✅ COMPLETE FORMS ($($completeFiles.Count)):" -ForegroundColor Green
    Write-Host ""

    foreach ($complete in $completeFiles) {
        Write-Host "  📄 $($complete.FileName)" -ForegroundColor Green
    }
    Write-Host ""
}

# Summary
Write-Host "📊 SUMMARY" -ForegroundColor Cyan
Write-Host "==========" -ForegroundColor Cyan
Write-Host "Total forms: $($feedbackFiles.Count)" -ForegroundColor White
Write-Host "Complete: $($completeFiles.Count)" -ForegroundColor Green
Write-Host "Incomplete: $($incompleteFiles.Count)" -ForegroundColor Red
Write-Host "Completion rate: $([math]::Round(($completeFiles.Count / $feedbackFiles.Count) * 100, 1))%" -ForegroundColor Yellow
Write-Host ""

# Recommendations
if ($incompleteFiles.Count -gt 0) {
    Write-Host "🚨 RECOMMENDATIONS" -ForegroundColor Yellow
    Write-Host "==================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Archive incomplete forms to prevent wasting analysis time:" -ForegroundColor White
    Write-Host "   Move incomplete forms to archive/incomplete/ folder" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Add completion validation to task definitions:" -ForegroundColor White
    Write-Host "   Require validation check before considering feedback complete" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Enhance feedback form template with completion reminders:" -ForegroundColor White
    Write-Host "   Add prominent warnings about completing all sections" -ForegroundColor Gray
    Write-Host ""

    if ($FixIncomplete) {
        Write-Host "🔧 FIXING INCOMPLETE FORMS" -ForegroundColor Yellow
        Write-Host "==========================" -ForegroundColor Yellow
        Write-Host ""

        # Create incomplete archive directory
        $incompleteArchiveDir = Join-Path $feedbackFormsDir "../archive/incomplete"
        if (-not (Test-Path $incompleteArchiveDir)) {
            New-Item -ItemType Directory -Path $incompleteArchiveDir -Force | Out-Null
            Write-Host "📁 Created incomplete archive directory: $incompleteArchiveDir" -ForegroundColor Green
        }

        # Move incomplete forms to archive, but never sweep one modified within the grace window
        # (PF-IMP-1305): a freshly created blank form may still be mid-fill in another session.
        $cutoff = (Get-Date).AddMinutes(-$GraceMinutes)
        $movedCount = 0
        $skippedRecent = @()
        foreach ($incomplete in $incompleteFiles) {
            if ($GraceMinutes -gt 0 -and $incomplete.LastWriteTime -gt $cutoff) {
                $skippedRecent += $incomplete
                continue
            }
            $destinationPath = Join-Path $incompleteArchiveDir $incomplete.FileName
            Move-Item -Path $incomplete.FilePath -Destination $destinationPath -Force
            Write-Host "📦 Moved $($incomplete.FileName) to incomplete archive" -ForegroundColor Yellow
            $movedCount++
        }

        Write-Host ""
        Write-Host "✅ Moved $movedCount incomplete form(s) to archive" -ForegroundColor Green
        if ($skippedRecent.Count -gt 0) {
            Write-Host "⏳ Skipped $($skippedRecent.Count) recently-modified form(s) (within the ${GraceMinutes}-min grace window) — may still be in flight:" -ForegroundColor Yellow
            foreach ($s in $skippedRecent) {
                Write-Host "   - $($s.FileName)" -ForegroundColor Gray
            }
        }
    }
}

# Exit with appropriate code
if ($incompleteFiles.Count -gt 0) {
    exit 1
} else {
    Write-Host "✅ All feedback forms are complete!" -ForegroundColor Green
    exit 0
}
