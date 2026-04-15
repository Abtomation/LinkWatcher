# run.ps1 — Scripted action for TE-E2E-027 (validate broken links detected)
# Runs LinkWatcher validation mode against a workspace with intentional broken links.
# Validation is read-only — no files are modified.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-027" -Group "link-validation-audit"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"
$logFile = Join-Path $WorkspacePath "validate.log"

# Run validation — expects exit code 1 (broken links found)
python main.py --validate --project-root $projectPath --log-file $logFile

# Capture and propagate exit code
$exitCode = $LASTEXITCODE
Write-Host "Validation exit code: $exitCode"
exit $exitCode
