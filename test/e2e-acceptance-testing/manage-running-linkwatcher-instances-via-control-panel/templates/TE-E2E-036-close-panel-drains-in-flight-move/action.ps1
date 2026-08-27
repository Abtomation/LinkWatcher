<#
.SYNOPSIS
    File-side action for TE-E2E-036: puts a reference update genuinely in flight immediately
    before the Control Panel is closed.

.DESCRIPTION
    Removes sandbox-a/notes/setup.md and re-creates it at sandbox-a/archive/setup.md a few
    seconds later. The daemon buffers the delete and waits up to move_detect_delay (10 s in this
    sandbox) for a matching create before deciding what happened; the create lands inside that
    window, so the correlation resolves into a move and the reference in docs/guide.md is
    rewritten. The human closes the panel window in the gap between the two halves, while the
    correlation is still buffered. AC-8 requires the drain to let that update complete.

    WHY NOT Move-Item (PD-BUG-136, 2026-08-25): a rename inside one volume reaches the daemon as
    a NATIVE move event, handled end to end in ~200 ms — measured at 75 ms and 191 ms on two
    independent reproductions. It never enters the delete-buffer, so it can never be "in flight"
    by the time a human reaches the close control, and the case silently degraded into TE-E2E-035's
    clean stop while appearing to pass. A delete whose matching create arrives later is the only
    shape that leaves the daemon holding pending work — and, critically, the daemon writes NOTHING
    to its log while it waits, which is exactly the blind spot the drain used to mistake for
    quiescence.

    Deliberately NOT named run.ps1: Run-E2EAcceptanceTest.ps1 treats the presence of run.ps1 as
    "fully scripted" and would execute this case unattended, with no panel open — the drain
    behaviour under test would never happen and the verdict would be false. This case is manual;
    the script only performs the file operations a human cannot time accurately by hand.

.PARAMETER WorkspacePath
    The per-case workspace directory, i.e.
    .../manage-running-linkwatcher-instances-via-control-panel/workspace/TE-E2E-036-close-panel-drains-in-flight-move

.PARAMETER CreateDelaySeconds
    Gap between the delete and the create. Must stay below the sandbox move_detect_delay (10 s) so
    the correlation still resolves, and above the panel log-idle threshold (3 s) so the drain is
    genuinely tested. The 6 s default leaves margin on both sides.

.EXAMPLE
    ./action.ps1 -WorkspacePath "C:\...\workspace\TE-E2E-036-close-panel-drains-in-flight-move"

.NOTES
    Created: 2026-08-25
    Updated: 2026-08-25 — delete+create replaces Move-Item (PD-BUG-136)
    Task: E2E Acceptance Test Case Creation (PF-TSK-069), WF-010 milestone
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,

    [Parameter(Mandatory = $false)]
    [ValidateRange(4, 9)]
    [double]$CreateDelaySeconds = 6
)

$ErrorActionPreference = 'Stop'

$project = Join-Path $WorkspacePath "project/sandbox-a"
$source = Join-Path $project "notes/setup.md"
$archive = Join-Path $project "archive"
$target = Join-Path $archive "setup.md"

if (-not (Test-Path -LiteralPath $source)) {
    Write-Error "Fixture missing: $source. Re-run Setup-TestEnvironment.ps1 -Clean."
}
if (Test-Path -LiteralPath $target) {
    Write-Error "Target already exists: $target. The workspace is not pristine — re-run Setup-TestEnvironment.ps1 -Clean."
}

# Capture the exact bytes so the re-created file is byte-identical to the fixture —
# Verify-TestResult.ps1 compares archive/setup.md against expected/ and any drift here
# would read as a corruption failure rather than the drain behaviour under test.
$content = Get-Content -LiteralPath $source -Raw

New-Item -ItemType Directory -Path $archive -Force | Out-Null

$stamp = (Get-Date -Format "HH:mm:ss.fff")
Remove-Item -LiteralPath $source
Write-Host "[$stamp] Deleted notes/setup.md — the daemon has buffered this and is now silently waiting" -ForegroundColor Green
Write-Host "CLOSE THE CONTROL PANEL WINDOW NOW — within the next 1-3 seconds." -ForegroundColor Yellow
Write-Host "  (archive/setup.md will be created in $CreateDelaySeconds s, during the drain)" -ForegroundColor DarkGray

Start-Sleep -Seconds $CreateDelaySeconds

Set-Content -LiteralPath $target -Value $content -NoNewline
$stamp = (Get-Date -Format "HH:mm:ss.fff")
Write-Host "[$stamp] Created archive/setup.md — the correlation should now resolve into a move" -ForegroundColor Green
Write-Host "Watch the panel: the drain must still be running, and guide.md must end up rewritten." -ForegroundColor Cyan
