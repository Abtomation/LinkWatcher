<#
.SYNOPSIS
Finalizes a Feature Enhancement (PF-TSK-068): restores the target feature's status and archives the Enhancement State Tracking File.

.DESCRIPTION
Mechanical finalization steps of the Feature Enhancement task (PF-TSK-068):
1. Restores the target feature's status in feature-tracking.md
2. Archives the Enhancement State Tracking File to <state-tracking>/temporary/old/
   (state-tracking root resolved via Get-StateTrackingContext: doc/state-tracking/ in
   projects, process-framework-central/state-tracking/ in appdev)

Output behavior: Default output is one summary line per invocation (the outcome,
e.g. "Feature 6.1.1 → Enhancement finalized"). WARN and ERROR messages always
pass through. Pass -Verbose to restore the full play-by-play log.

.PARAMETER FeatureId
Feature ID whose enhancement is being finalized (e.g. "6.1.1"). Selects the row to restore in
feature-tracking.md and identifies the Enhancement State Tracking File to archive.

.PARAMETER RestoredStatus
Implementation Status value written back to the feature's row. Defaults to "🟢 Completed" — pass
a different value only if it exists in the tracker's Implementation Status legend, since the
Progress Summary recompute counts by legend value.

.PARAMETER StateFilePath
Explicit path to the Enhancement State Tracking File. Omitted resolves it from the feature ID
under the state-tracking root.

.PARAMETER FeatureTrackingFile
Overrides the path to feature-tracking.md. Omitted resolves it from the project root.

.PARAMETER ArchiveDir
Overrides the archive destination. Omitted uses <state-tracking>/temporary/old/, with the
state-tracking root resolved by Get-StateTrackingContext.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureId,

    [Parameter(Mandatory = $false)]
    # PF-IMP-1056: "🟢 Completed" is the canonical Implementation Status legend value; the prior
    # default "✅ Complete" matched no legend entry (✅ is a Test-Status symbol) and would be
    # miscounted by the Progress Summary recompute.
    [string]$RestoredStatus = "🟢 Completed",

    [Parameter(Mandatory = $false)]
    [string]$StateFilePath,

    [Parameter(Mandatory = $false)]
    [string]$FeatureTrackingFile = "",

    [Parameter(Mandatory = $false)]
    [string]$ArchiveDir = ""
)

# Import the common helpers for Get-ProjectRoot
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
# Temporarily silence $VerbosePreference around the import so -Verbose callers see
# only this script's own Write-Verbose output, not the helper module's internal chatter.
$prevVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
$VerbosePreference = $prevVerbosePreference

# Soak verification (PF-PRO-028 v2.0 Pattern A; caller-aware no-arg form)
Register-SoakScript
$soakInSoak = Test-ScriptInSoak

# Soak-verification wrapper begins (PF-PRO-028 v2.0)
try {

# Configuration
# Caller-supplied -FeatureTrackingFile / -ArchiveDir override the resolved defaults
# (sandbox test entry point).
$ProjectRoot = Get-ProjectRoot
$StContext = Get-StateTrackingContext
if (-not $FeatureTrackingFile) {
    $FeatureTrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/feature-tracking.md"
}
if (-not $ArchiveDir) {
    $ArchiveDir = Join-Path -Path $StContext.StateTrackingRoot -ChildPath "temporary/old"
}

# PF-IMP-1023: date stamp for the Update History row appended on finalization
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

function Add-UpdateHistoryEntry {
    # PF-IMP-1023: append one row to feature-tracking.md's "## Update History" table recording
    # the finalized enhancement transition (🔄 Needs Enhancement → restored status). Mirrors the
    # same-file sibling Archive-Feature.ps1. Best-effort: returns $null when the table is absent
    # so the caller can WARN and continue — the status restore has already succeeded, and a missing
    # history table must not abort finalization.
    param([string]$Content, [string]$FeatureId, [string]$ToStatus)

    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # Find the Update History table — insert after the last data row
    $insertAfterIndex = -1
    $inHistorySection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Update History") { $inHistorySection = $true }
        if ($inHistorySection -and $lines[$i] -match "^\|[^-]" -and $lines[$i] -notmatch "^\|\s*Date") {
            $insertAfterIndex = $i
        }
    }

    # Fall back to the header separator row if the table has no data rows yet
    if ($insertAfterIndex -eq -1) {
        $inHistorySection = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^## Update History") { $inHistorySection = $true }
            if ($inHistorySection -and $lines[$i] -match "^\|\s*-") {
                $insertAfterIndex = $i
                break
            }
        }
    }

    if ($insertAfterIndex -eq -1) { return $null }  # table absent — caller WARNs and continues

    $historyRow = "| $CurrentDate | Feature ${FeatureId}: 🔄 Needs Enhancement → ${ToStatus} (enhancement finalized) | [Finalize-Enhancement.ps1](../../../process-framework/scripts/update/Finalize-Enhancement.ps1) |"
    $lines.Insert($insertAfterIndex + 1, $historyRow)

    return ($lines -join "`r`n")
}

function Remove-EnhancementStateNote {
    # PF-IMP-1056: strip the transient "Enhancement State File: [PF-STA-NNN](...)" pointer that
    # Feature Request Evaluation places in this feature's Notes column. The enhancement is now
    # finalized and its state file archived, so the pointer is stale. Scoped to this feature's
    # row (ID anchored in the first column) so concurrent enhancements on other features are
    # untouched. Best-effort: returns the content unchanged when no such pointer is present.
    param([string]$Content, [string]$FeatureId)

    $escId = [regex]::Escape($FeatureId)
    $lines = $Content -split "\r?\n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^\|[^\|]*$escId[^\|]*\|" -and $lines[$i] -match 'Enhancement State File:') {
            # Remove the pointer plus an immediately preceding "." / ";" / "," separator if present.
            $lines[$i] = [regex]::Replace($lines[$i], '\s*(?:[;.,]\s*)?Enhancement State File:\s*\[PF-STA-\d+\]\([^)]*\)', '')
            return ($lines -join "`r`n")
        }
    }
    return $Content
}

# Validate prerequisites
if (-not (Test-Path $FeatureTrackingFile)) {
    Write-ProjectLog "Feature tracking file not found: $FeatureTrackingFile" -Level "ERROR"
    exit 1
}

# Auto-detect state file if not provided
if (-not $StateFilePath) {
    $tempDir = Join-Path -Path $StContext.StateTrackingRoot -ChildPath "temporary"
    $candidates = Get-ChildItem -Path $tempDir -Filter "enhancement-*.md" -File -ErrorAction SilentlyContinue
    if ($candidates.Count -eq 0) {
        Write-ProjectLog "No enhancement state files found in $tempDir. Provide -StateFilePath explicitly." -Level "ERROR"
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
        Write-ProjectLog "No enhancement state file found for feature $FeatureId in $tempDir. Provide -StateFilePath explicitly." -Level "ERROR"
        exit 1
    }
    if ($matched.Count -gt 1) {
        Write-ProjectLog "Multiple enhancement state files found for feature $FeatureId. Provide -StateFilePath explicitly:" -Level "ERROR"
        foreach ($m in $matched) { Write-ProjectLog "  $($m.FullName)" -Level "ERROR" }
        exit 1
    }

    $StateFilePath = $matched[0].FullName
    Write-ProjectLog "Auto-detected state file: $StateFilePath"
}

if (-not (Test-Path $StateFilePath)) {
    Write-ProjectLog "State file not found: $StateFilePath" -Level "ERROR"
    exit 1
}

Write-ProjectLog "Starting Enhancement Finalization"
Write-ProjectLog "Feature ID: $FeatureId"
Write-ProjectLog "Restored Status: $RestoredStatus"
Write-ProjectLog "State File: $StateFilePath"

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
    Write-ProjectLog "Could not find feature $FeatureId with '🔄 Needs Enhancement' status in feature tracking" -Level "ERROR"
    exit 1
}

Write-ProjectLog "Found feature $FeatureId with Needs Enhancement status"

if ($PSCmdlet.ShouldProcess($FeatureTrackingFile, "Restore feature $FeatureId status to '$RestoredStatus'")) {
    $updatedContent = [regex]::Replace($content, $pattern, "`${1} $RestoredStatus `${2}")
    if ($updatedContent -eq $content) {
        # Try pattern2
        $updatedContent = [regex]::Replace($content, $pattern2, "`${1} $RestoredStatus `${2}")
    }

    # PF-IMP-1056: remove the now-stale "Enhancement State File: [PF-STA-NNN](...)" pointer from
    # this feature's Notes column — the enhancement is finalized and its state file archived.
    $updatedContent = Remove-EnhancementStateNote -Content $updatedContent -FeatureId $FeatureId

    # PF-IMP-801: recompute Progress Summary — status restoration shifts the
    # Implementation Status Overview breakdown.
    $updatedContent = Update-FeatureTrackingSummary -Content $updatedContent

    # PF-IMP-1023: log the finalized transition in the Update History table. Best-effort —
    # a missing table WARNs but does not abort (the status restore above already succeeded).
    $withHistory = Add-UpdateHistoryEntry -Content $updatedContent -FeatureId $FeatureId -ToStatus $RestoredStatus
    if ($null -ne $withHistory) {
        $updatedContent = $withHistory
        Write-ProjectLog "Added Update History entry for feature $FeatureId" -Level "SUCCESS"
    } else {
        Write-ProjectLog "Update History table not found in $FeatureTrackingFile; skipped history row" -Level "WARN"
    }

    Set-Content -Path $FeatureTrackingFile -Value $updatedContent -NoNewline
    Write-ProjectLog "Restored feature $FeatureId status to '$RestoredStatus'" -Level "SUCCESS"
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
    Write-ProjectLog "Archived state file to: $archivePath" -Level "SUCCESS"
}

Write-ProjectSummary "Feature $FeatureId → Enhancement finalized (status: $RestoredStatus)"


    # Soak: success outcome (PF-PRO-028 v2.0)
    if ($soakInSoak) { Confirm-SoakInvocation -Outcome success }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -Outcome failure -Notes $soakErrMsg
    }
    Write-Error "Enhancement finalization failed: $($_.Exception.Message)"
    exit 1
}
