# Finalize-Enhancement.ps1
# Automates the mechanical finalization steps of the Feature Enhancement task (PF-TSK-068):
# 1. Restores the target feature's status in feature-tracking.md
# 2. Archives the Enhancement State Tracking File to process-framework-local/state-tracking/temporary/old/

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureId,

    [Parameter(Mandatory = $false)]
    [string]$RestoredStatus = "✅ Complete",

    [Parameter(Mandatory = $false)]
    [string]$StateFilePath
)

# Import the common helpers for Get-ProjectRoot
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Configuration
$ProjectRoot = Get-ProjectRoot
$FeatureTrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/feature-tracking.md"
$ArchiveDir = Join-Path -Path $ProjectRoot -ChildPath "process-framework-local/state-tracking/temporary/old"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )
}

# Validate prerequisites
if (-not (Test-Path $FeatureTrackingFile)) {
    Write-Log "Feature tracking file not found: $FeatureTrackingFile" -Level "ERROR"
    exit 1
}

# Auto-detect state file if not provided
if (-not $StateFilePath) {
    $tempDir = Join-Path -Path $ProjectRoot -ChildPath "process-framework-local/state-tracking/temporary"
    $candidates = Get-ChildItem -Path $tempDir -Filter "enhancement-*.md" -File -ErrorAction SilentlyContinue
    if ($candidates.Count -eq 0) {
        Write-Log "No enhancement state files found in $tempDir. Provide -StateFilePath explicitly." -Level "ERROR"
        exit 1
    }

    # Filter to files whose frontmatter target_feature matches
    $matched = @()
    foreach ($candidate in $candidates) {
        $content = Get-Content $candidate.FullName -Raw
        if ($content -match "target_feature:\s*$([regex]::Escape($FeatureId))") {
            $matched += $candidate
        }
    }

    if ($matched.Count -eq 0) {
        Write-Log "No enhancement state file found for feature $FeatureId in $tempDir. Provide -StateFilePath explicitly." -Level "ERROR"
        exit 1
    }
    if ($matched.Count -gt 1) {
        Write-Log "Multiple enhancement state files found for feature $FeatureId. Provide -StateFilePath explicitly:" -Level "ERROR"
        foreach ($m in $matched) { Write-Log "  $($m.FullName)" -Level "ERROR" }
        exit 1
    }

    $StateFilePath = $matched[0].FullName
    Write-Log "Auto-detected state file: $StateFilePath"
}

if (-not (Test-Path $StateFilePath)) {
    Write-Log "State file not found: $StateFilePath" -Level "ERROR"
    exit 1
}

Write-Log "Starting Enhancement Finalization"
Write-Log "Feature ID: $FeatureId"
Write-Log "Restored Status: $RestoredStatus"
Write-Log "State File: $StateFilePath"

# Step 1: Update feature-tracking.md — replace "🔄 Needs Enhancement (...)" with restored status
$content = Get-Content $FeatureTrackingFile -Raw

# Pattern: match the feature row (| ID | Feature | Status |) and replace the Needs Enhancement status
# The feature ID is in a markdown link like [1.1.1](path) in the ID column
# The status contains nested parens from markdown link: ([PF-STA-XXX](path))
$escapedId = [regex]::Escape($FeatureId)
$pattern = "(?m)(^\|[^\|]*$escapedId[^\|]*\|[^\|]*\|)\s*🔄 Needs Enhancement\s*\(.*?\)\)\s*(\|)"
$match = [regex]::Match($content, $pattern)

if (-not $match.Success) {
    # Try without parenthetical link
    $pattern2 = "(?m)(^\|[^\|]*$escapedId[^\|]*\|[^\|]*\|)\s*🔄 Needs Enhancement\s*(\|)"
    $match = [regex]::Match($content, $pattern2)
}

if (-not $match.Success) {
    Write-Log "Could not find feature $FeatureId with '🔄 Needs Enhancement' status in feature tracking" -Level "ERROR"
    exit 1
}

Write-Log "Found feature $FeatureId with Needs Enhancement status"

if ($PSCmdlet.ShouldProcess($FeatureTrackingFile, "Restore feature $FeatureId status to '$RestoredStatus'")) {
    $updatedContent = [regex]::Replace($content, $pattern, "`${1} $RestoredStatus `${2}")
    if ($updatedContent -eq $content) {
        # Try pattern2
        $updatedContent = [regex]::Replace($content, $pattern2, "`${1} $RestoredStatus `${2}")
    }
    Set-Content -Path $FeatureTrackingFile -Value $updatedContent -NoNewline
    Write-Log "Restored feature $FeatureId status to '$RestoredStatus'" -Level "SUCCESS"
}

# Step 2: Archive the enhancement state file
$stateFileName = Split-Path -Leaf $StateFilePath

if (-not (Test-Path $ArchiveDir)) {
    if ($PSCmdlet.ShouldProcess($ArchiveDir, "Create archive directory")) {
        New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null
    }
}

$archivePath = Join-Path $ArchiveDir $stateFileName

if ($PSCmdlet.ShouldProcess($StateFilePath, "Archive to $archivePath")) {
    Move-Item -Path $StateFilePath -Destination $archivePath -Force
    Write-Log "Archived state file to: $archivePath" -Level "SUCCESS"
}

Write-Log "Enhancement finalization completed successfully" -Level "SUCCESS"
Write-Log "Updated file: $FeatureTrackingFile"
Write-Log "Archived file: $archivePath"
