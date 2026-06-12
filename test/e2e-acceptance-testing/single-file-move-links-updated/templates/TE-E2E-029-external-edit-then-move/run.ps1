# run.ps1 — Scripted action for TE-E2E-029 (external edit then move)
# Regression guard for PD-BUG-102: a link written into an EXISTING monitored file by an
# external tool must be indexed via the on_modified rescan, so a later move of the link's
# target rewrites it (pre-fix: file_moved ran with references_count=0 / no_references_found).
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-029" -Workflow "single-file-move-links-updated"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# LinkWatcher lifecycle is owned by this run.ps1 (Run-E2EAcceptanceTest.ps1 v2.0 is project-agnostic).
. (Join-Path $PSScriptRoot "../../../_lib/lw-e2e-helpers.ps1")

$lw = Start-WorkspaceLinkWatcher -WorkspacePath $WorkspacePath
try {
    $projectPath = Join-Path $WorkspacePath "project"

    # Step 1: Wait for the initial scan to COMPLETE (not just start). Edits during the
    # startup scan are deferred and replayed — a different code path than the live
    # on_modified rescan this test exercises.
    $elapsed = 0
    while ($elapsed -lt 20) {
        if ((Test-Path $lw.LogFile) -and
            ((Get-Content $lw.LogFile -Raw -ErrorAction SilentlyContinue) -match 'initial_scan_complete')) {
            break
        }
        Start-Sleep -Seconds 1; $elapsed++
    }

    # Step 2: Simulate an external tool writing a link into the EXISTING monitored file.
    Add-Content -Path (Join-Path $projectPath "notes.md") `
        -Value "`nSee the [Target](docs/target.md) document." -Encoding UTF8

    # Step 3: Wait for the modify event to be delivered and the link indexed (on_modified
    # rescan). Watchdog dispatches serially, so once indexed the later move sees the link.
    Start-Sleep -Seconds 5

    # Step 4: Move the target file to archive/.
    $archiveDir = Join-Path $projectPath "archive"
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    Move-Item -Path (Join-Path $projectPath "docs/target.md") -Destination (Join-Path $archiveDir "target.md")

    # Allow LinkWatcher to detect the move (delete+create correlation window is 10s) and
    # update the freshly indexed reference before verification.
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
