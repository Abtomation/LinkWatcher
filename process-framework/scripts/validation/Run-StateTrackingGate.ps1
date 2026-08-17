<#
.SYNOPSIS
    Warn-first (or blocking) pre-commit / CI gate wrapper around Validate-StateTracking.ps1 (PF-IMP-1211 / PF-PRO-049).
.DESCRIPTION
    Runs the state-tracking validator, surfaces its findings, then decides the gate's exit code:
      - Default (warn-first): always exits 0 — the validator's findings are shown but never block the
        commit / CI run. Use during soak, and in any project that still carries pre-existing error debt.
      - -Blocking: propagates the validator's exit code (non-zero on new/any errors) so the gate fails.

    The validator is invoked as a CHILD pwsh process so its own `exit N` does not terminate this wrapper
    (it would, if dot-sourced). The child's exit code is read from $LASTEXITCODE and applied per the mode.

    Baseline guidance: pass -Baseline to ratchet against a committed baseline — meaningful in a project
    that carries pre-existing *error* debt, where -Baseline lets the gate pass that debt and fail only on
    NEW errors. Omit -Baseline where the project has no error debt (e.g. appdev), where it adds nothing
    (the validator only fingerprints errors, so a 0-error baseline behaves identically to a plain run).
.PARAMETER Blocking
    Fail the gate (propagate the validator's non-zero exit) instead of warn-first non-blocking.
.PARAMETER Baseline
    Optional committed baseline file to delta against (passed through to Validate-StateTracking.ps1 -Baseline).
.PARAMETER ProjectRoot
    Optional project root passed through to the validator (defaults to the validator's own auto-detection).
.PARAMETER JsonPath
    Optional stable path for the validator's machine-readable -Json summary (for CI consumers).
.PARAMETER Surface
    Optional comma-separated surface list passed through to Validate-StateTracking.ps1 -Surface
    (the validator splits commas per element, so the single string survives the child -File
    invocation). Enables surface-scoped gate passes, e.g. appdev's scoped blueprint-tree pass
    (PF-IMP-1957).
.EXAMPLE
    Run-StateTrackingGate.ps1
    # warn-first, non-blocking — appdev / soak. Findings shown; commit never blocked.
.EXAMPLE
    Run-StateTrackingGate.ps1 -Blocking -Baseline .vst-baseline.json
    # blocking ratchet — a project carrying error debt; fails only on NEW errors vs the committed baseline.
#>
[CmdletBinding()]
param(
    [switch]$Blocking,
    [string]$Baseline = "",
    [string]$ProjectRoot = "",
    [string]$JsonPath = "",
    [string]$Surface = ""
)

$validator = Join-Path $PSScriptRoot "Validate-StateTracking.ps1"
if (-not (Test-Path $validator)) {
    Write-Host "Run-StateTrackingGate: validator not found at $validator" -ForegroundColor Red
    if ($Blocking) { exit 1 } else { exit 0 }
}

# Build the validator argument list (child pwsh -File invocation).
$valArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $validator)
if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) { $valArgs += @('-ProjectRoot', $ProjectRoot) }
if (-not [string]::IsNullOrWhiteSpace($Baseline))    { $valArgs += @('-Baseline', $Baseline) }
if (-not [string]::IsNullOrWhiteSpace($JsonPath))    { $valArgs += @('-JsonPath', $JsonPath) }
if (-not [string]::IsNullOrWhiteSpace($Surface))     { $valArgs += @('-Surface', $Surface) }

# Child process: the validator's `exit` ends the child, not this wrapper.
& pwsh.exe @valArgs
$valExit = $LASTEXITCODE

Write-Host ""
if ($Blocking) {
    if ($valExit -ne 0) {
        Write-Host "[state-tracking gate] BLOCKING: validator reported new/unaccepted errors (exit $valExit)." -ForegroundColor Red
    } else {
        Write-Host "[state-tracking gate] BLOCKING: clean (exit 0)." -ForegroundColor Green
    }
    exit $valExit
} else {
    Write-Host "[state-tracking gate] warn-first / non-blocking (PF-PRO-049 / PF-IMP-1211): the findings above do not block this commit. Promote with -Blocking once soaked." -ForegroundColor Yellow
    exit 0
}
