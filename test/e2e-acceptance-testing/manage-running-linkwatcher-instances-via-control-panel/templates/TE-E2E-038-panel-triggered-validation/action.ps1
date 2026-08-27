<#
.SYNOPSIS
    Daemon-liveness witness for TE-E2E-038: records the sandbox daemon PIDs before a
    panel-triggered validation run and re-checks them afterwards.

.DESCRIPTION
    AC-6 has two halves. The first — validation reports the broken-link count and the report
    path — is observed in the panel window by the human. The second — the project's running
    daemon is NOT stopped by the validation run — is a process-liveness fact that neither the
    window nor Verify-TestResult.ps1 (which only compares files) can assert. This script is
    that assertion.

    Run with -Before immediately before triggering validation from the panel, and with -After
    immediately after the panel reports a result. -After fails loudly if any PID recorded by
    -Before is gone.

    Deliberately NOT named run.ps1 — see the note in TE-E2E-036/action.ps1.

.PARAMETER WorkspacePath
    The per-case workspace directory.

.PARAMETER Before
    Record the current daemon PIDs for sandbox-a.

.PARAMETER After
    Re-check the recorded PIDs and report whether the daemon survived.

.EXAMPLE
    ./action.ps1 -WorkspacePath "C:\...\workspace\TE-E2E-038-panel-triggered-validation" -Before

.EXAMPLE
    ./action.ps1 -WorkspacePath "C:\...\workspace\TE-E2E-038-panel-triggered-validation" -After

.NOTES
    Created: 2026-08-25
    Task: E2E Acceptance Test Case Creation (PF-TSK-069), WF-010 milestone
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,

    [Parameter(Mandatory = $false)]
    [switch]$Before,

    [Parameter(Mandatory = $false)]
    [switch]$After
)

$ErrorActionPreference = 'Stop'

if ($Before -eq $After) {
    Write-Error "Specify exactly one of -Before or -After."
}

$project = (Join-Path $WorkspacePath "project/sandbox-a")
if (-not (Test-Path -LiteralPath $project)) {
    Write-Error "Fixture missing: $project. Re-run Setup-TestEnvironment.ps1 -Clean."
}
$projectRoot = (Resolve-Path -LiteralPath $project).Path
$witnessFile = Join-Path $WorkspacePath "daemon-pids.before.txt"

function Get-SandboxDaemonPids {
    param([string]$Root)
    # Same identification the launcher and the panel use: a python process running
    # main.py bound to THIS project root. Never matches the repository's own daemon.
    try {
        $procs = Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
            $_.Name -like 'python*' -and $_.CommandLine -and $_.CommandLine -like '*main.py*' -and $_.CommandLine.Contains($Root)
        }
        return @($procs | ForEach-Object { $_.ProcessId })
    } catch {
        Write-Error "Process enumeration failed: $($_.Exception.Message)"
    }
}

if ($Before) {
    $found = Get-SandboxDaemonPids -Root $projectRoot
    if ($found.Count -eq 0) {
        Write-Error "No sandbox-a daemon is running. Start it from the panel before recording the witness."
    }
    Set-Content -LiteralPath $witnessFile -Value ($found -join "`n") -Encoding UTF8
    Write-Host "Recorded $($found.Count) daemon PID(s) for sandbox-a: $($found -join ', ')" -ForegroundColor Green
    Write-Host "Now trigger validation from the Control Panel." -ForegroundColor Cyan
    return
}

if (-not (Test-Path -LiteralPath $witnessFile)) {
    Write-Error "No witness file at $witnessFile. Run with -Before first."
}

$expected = @(Get-Content -LiteralPath $witnessFile | Where-Object { $_ -match '\S' } | ForEach-Object { [int]$_.Trim() })
$still = Get-SandboxDaemonPids -Root $projectRoot
$gone = @($expected | Where-Object { $_ -notin $still })

Write-Host ""
Write-Host "Recorded before validation : $($expected -join ', ')" -ForegroundColor Gray
Write-Host "Alive after validation     : $($still -join ', ')" -ForegroundColor Gray
Write-Host ""

if ($gone.Count -gt 0) {
    Write-Error "AC-6 VIOLATED: daemon PID(s) $($gone -join ', ') disappeared across the validation run — validation must not stop the running daemon."
}

Write-Host "PASS: the sandbox-a daemon survived the panel-triggered validation run." -ForegroundColor Green
