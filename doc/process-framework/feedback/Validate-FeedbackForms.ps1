# Validate-FeedbackForms.ps1
# Validates feedback forms for completeness and identifies forms with template placeholders
# Helps prevent incomplete forms from wasting tools review analysis time

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$FeedbackFormsPath = "feedback-forms",

    [Parameter(Mandatory=$false)]
    [switch]$ShowComplete,

    [Parameter(Mandatory=$false)]
    [switch]$FixIncomplete
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "scripts/Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

Write-Host "🔍 Validating Feedback Forms..." -ForegroundColor Cyan
Write-Host ""

# Get all feedback form files
if ([System.IO.Path]::IsPathRooted($FeedbackFormsPath)) {
    $feedbackFormsDir = $FeedbackFormsPath
} else {
    $feedbackFormsDir = Join-Path (Get-Location) "$FeedbackFormsPath"
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
    "[Tool Name ([PREFIX]-XXX-XXX)]",
    "[How this tool was used in the task]",
    "[Detailed comments about",
    "[Brief comments]",
    "[Overall assessment of",
    "[Assessment of process",
    "[FEEDBACK_TYPE]",
    "[DOCUMENT_ID]",
    "[TASK_CONTEXT]",
    "[REQUIRED: Start: HH:MM, End: HH:MM, Total: X minutes]"
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

    # Check for template placeholders in the cleaned content
    foreach ($placeholder in $templatePlaceholders) {
        if ($contentToCheck -match [regex]::Escape($placeholder)) {
            $placeholdersFound += $placeholder
        }
    }

    $result = [PSCustomObject]@{
        FileName = $file.Name
        FilePath = $file.FullName
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

        # Move incomplete forms to archive
        foreach ($incomplete in $incompleteFiles) {
            $destinationPath = Join-Path $incompleteArchiveDir $incomplete.FileName
            Move-Item -Path $incomplete.FilePath -Destination $destinationPath -Force
            Write-Host "📦 Moved $($incomplete.FileName) to incomplete archive" -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "✅ Moved $($incompleteFiles.Count) incomplete forms to archive" -ForegroundColor Green
    }
}

# Exit with appropriate code
if ($incompleteFiles.Count -gt 0) {
    exit 1
} else {
    Write-Host "✅ All feedback forms are complete!" -ForegroundColor Green
    exit 0
}
