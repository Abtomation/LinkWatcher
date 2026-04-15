# run.ps1 — Scripted action for TE-E2E-028 (validate ignore rules suppress)
# Runs LinkWatcher validation mode with a config file pointing to .linkwatcher-ignore.
# Validation is read-only — no files are modified.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-028" -Group "link-validation-audit"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"
$configFile = Join-Path $projectPath "linkwatcher-config.yaml"
$logFile = Join-Path $WorkspacePath "validate.log"

# Run validation with config — expects exit code 1 (one non-suppressed broken link)
python main.py --validate --project-root $projectPath --config $configFile --log-file $logFile

# Capture and propagate exit code
$exitCode = $LASTEXITCODE
Write-Host "Validation exit code: $exitCode"
exit $exitCode
