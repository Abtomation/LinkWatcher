<#
.SYNOPSIS
    File-side action for TE-E2E-037: generates continuous churn so the sandbox daemon never
    reaches quiescence, forcing the panel to hit grace expiry and force-terminate it.

.DESCRIPTION
    The panel considers a daemon drained when its newest log file has been silent for >= 3 s
    (D-T2), and gives up at grace_period_seconds (default 20 s). This script starts a detached
    churn writer that touches a file under sandbox-a/churn/ every 400 ms, keeping the daemon
    logging continuously so quiescence is never observed. AC-9 requires the panel to
    force-terminate the daemon at grace expiry, still exit without hanging, and leave no file
    corrupted.

    Churn files are written into a dedicated churn/ subdirectory and are NOT part of expected/,
    so they cannot affect the file comparison. The reference in docs/guide.md is deliberately
    left untouched by the churn — it is the "no corruption" witness.

    The script REFUSES to report success until it has seen churn on disk: it waits up to 5 s for
    the first churn file and errors out (non-zero, writer stderr echoed, no PID file left behind)
    if none appears. Without that check a dead writer is indistinguishable from a working one, the
    daemon goes quiet, the drain completes normally and the case passes having tested nothing —
    which is exactly what PD-BUG-138 was. It also writes churn-writer.ps1 and (only on failure)
    churn-writer.err.log into the workspace root — outside project/, so the daemon never sees them
    and expected/ is unaffected. Those two are what to read if this ever fails again.

    Deliberately NOT named run.ps1 — see the note in TE-E2E-036/action.ps1.

.PARAMETER WorkspacePath
    The per-case workspace directory.

.PARAMETER DurationSeconds
    How long the churn writer runs before stopping on its own. Default 90 s — comfortably longer
    than the 20 s grace period plus the time a human needs to trigger the close.

.PARAMETER Stop
    Stop a churn writer started by an earlier invocation and remove its PID file.

.EXAMPLE
    ./action.ps1 -WorkspacePath "C:\...\workspace\TE-E2E-037-forced-terminate-on-grace-expiry"

.EXAMPLE
    ./action.ps1 -WorkspacePath "C:\...\workspace\TE-E2E-037-forced-terminate-on-grace-expiry" -Stop

.NOTES
    Created: 2026-08-25
    Updated: 2026-08-25 — PD-BUG-138: launch the writer via -File (not inline -Command) and
             verify churn exists before claiming success. Regression:
             test/automated/unit/7-operations-control/7-1-control-panel/test_pd_bug_138_e2e037_churn_writer.py
    Task: E2E Acceptance Test Case Creation (PF-TSK-069), WF-010 milestone
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,

    [Parameter(Mandatory = $false)]
    [int]$DurationSeconds = 90,

    [Parameter(Mandatory = $false)]
    [switch]$Stop
)

$ErrorActionPreference = 'Stop'

$project = Join-Path $WorkspacePath "project/sandbox-a"
$churnDir = Join-Path $project "churn"
$pidFile = Join-Path $WorkspacePath "churn.pid"

if ($Stop) {
    if (-not (Test-Path -LiteralPath $pidFile)) {
        Write-Host "No churn writer recorded at $pidFile — nothing to stop." -ForegroundColor Yellow
        return
    }
    $churnPid = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    $proc = Get-Process -Id $churnPid -ErrorAction SilentlyContinue
    if ($proc) {
        Stop-Process -Id $churnPid -Force
        Write-Host "Stopped churn writer (PID $churnPid)." -ForegroundColor Green
    } else {
        Write-Host "Churn writer (PID $churnPid) already exited." -ForegroundColor Gray
    }
    Remove-Item -LiteralPath $pidFile -Force
    return
}

if (-not (Test-Path -LiteralPath $project)) {
    Write-Error "Fixture missing: $project. Re-run Setup-TestEnvironment.ps1 -Clean."
}
if (Test-Path -LiteralPath $pidFile) {
    Write-Error "A churn writer is already recorded at $pidFile. Run with -Stop first."
}

New-Item -ItemType Directory -Path $churnDir -Force | Out-Null

# The payload goes to a script FILE launched with -File — never inline via -Command
# (PD-BUG-138). Start-Process space-joins -ArgumentList elements WITHOUT quoting, so an
# inline payload's own quotes are consumed as argument delimiters and the child re-parses
# the remains: the markdown link below became a type literal ("Missing ] at end of
# attribute or type literal"), the writer died before its first write, and
# -WindowStyle Hidden made that silent. The script path is quoted inside the element for
# the same no-quoting reason.
# These files live in the workspace root, not under project/, so the sandbox daemon never
# sees them and expected/ is unaffected.
$writerScript = Join-Path $WorkspacePath "churn-writer.ps1"
$writerErr = Join-Path $WorkspacePath "churn-writer.err.log"

# Detached writer: touches a rotating file every 400 ms for DurationSeconds.
# The body is wrapped so a RUNTIME failure leaves evidence instead of vanishing — the
# writer owns its own error log because the parent cannot redirect its streams: passing
# -RedirectStandard* switches Start-Process to UseShellExecute=$false, and the writer then
# dies with this script instead of outliving it (measured 2026-08-25 — it wrote ~5 files
# and stopped). The human needs it running for the whole panel-close sequence, so
# ShellExecute detachment is a hard requirement here.
$inner = @"
`$ErrorActionPreference = 'Stop'
try {
`$deadline = (Get-Date).AddSeconds($DurationSeconds)
`$i = 0
while ((Get-Date) -lt `$deadline) {
    `$i++
    # The link line makes each write produce a file_links_scanned entry on top of the
    # events every modify emits: measured 2026-08-25, a link-bearing rewrite logs about
    # twice what a link-free one does (~2.0 KB vs ~0.9 KB per write on the reference
    # fixture). Link-free churn does still keep the daemon logging, so this is margin
    # rather than a hard requirement — it just makes non-quiescence robust on a slower
    # machine, and makes the churn resemble real work instead of empty touches.
    Set-Content -LiteralPath (Join-Path '$churnDir' ('churn-' + (`$i % 5) + '.md')) -Value (
        "# churn " + `$i + " " + (Get-Date -Format 'HH:mm:ss.fff') + "`n`n[Setup Notes](../notes/setup.md)"
    ) -Encoding UTF8
    Start-Sleep -Milliseconds 400
}
} catch {
    `$_ | Out-File -LiteralPath '$writerErr' -Encoding UTF8
    exit 1
}
"@

Remove-Item -LiteralPath $writerErr -Force -ErrorAction SilentlyContinue
Set-Content -LiteralPath $writerScript -Value $inner -Encoding UTF8

# A PARSE error precedes the try/catch above and would leave no trace, so check the
# payload here — that is the exact class of failure PD-BUG-138 was.
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile($writerScript, [ref]$null, [ref]$parseErrors) | Out-Null
if ($parseErrors) {
    $parseErrors | ForEach-Object { Write-Host "  $($_.Message)" -ForegroundColor Red }
    Write-Error "Churn payload does not parse — see $writerScript. The case cannot exercise AC-9."
}

$proc = Start-Process pwsh.exe `
    -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$writerScript`"") `
    -WindowStyle Hidden -PassThru

# Never report success on unverified evidence (PD-BUG-138). A writer that produces
# nothing lets the daemon go quiet, so the panel drains normally and the case
# PASSES having tested nothing — the failure this fixture must never repeat.
$verifyDeadline = (Get-Date).AddSeconds(5)
$observed = 0
while ((Get-Date) -lt $verifyDeadline) {
    $observed = @(Get-ChildItem -LiteralPath $churnDir -Filter 'churn-*.md' -ErrorAction SilentlyContinue).Count
    if ($observed -gt 0) { break }
    Start-Sleep -Milliseconds 200
}

if ($observed -eq 0) {
    if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
    $writerStderr = if (Test-Path -LiteralPath $writerErr) { (Get-Content -LiteralPath $writerErr -Raw).Trim() } else { '' }
    Write-Host "Churn writer produced no files in 5 s — writer error log follows:" -ForegroundColor Red
    Write-Host $(if ($writerStderr) { $writerStderr } else { "(empty — the writer exited without reaching its loop)" }) -ForegroundColor Red
    Write-Error "No churn produced. The case cannot exercise AC-9 — do NOT record a verdict. Writer script: $writerScript, error log: $writerErr"
}

# Only now is there a live writer worth recording.
Set-Content -LiteralPath $pidFile -Value $proc.Id -Encoding UTF8

Write-Host "Churn writer started (PID $($proc.Id)), running for $DurationSeconds s — $observed churn file(s) written already." -ForegroundColor Green
Write-Host "Writing to: $churnDir" -ForegroundColor Gray
Write-Host "CLOSE THE CONTROL PANEL WINDOW NOW while churn is active." -ForegroundColor Yellow
Write-Host "Afterwards, stop the writer with: ./action.ps1 -WorkspacePath '$WorkspacePath' -Stop" -ForegroundColor Gray
