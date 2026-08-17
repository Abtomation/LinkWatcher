# run.ps1 — Scripted action for TE-E2E-032 (file rename virtual root links)
# This script performs ONLY the test action (e.g., Move-Item, Set-Content).
# Setup is handled by Setup-TestEnvironment.ps1.
# Verification is handled by Verify-TestResult.ps1.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-032" -Workflow "override-folder-move-virtual-root-links-updated"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

# LinkWatcher lifecycle is owned by this run.ps1 (Run-E2EAcceptanceTest.ps1 v2.0 is project-agnostic).
. (Join-Path $PSScriptRoot "../../../_lib/lw-e2e-helpers.ps1")

$lw = Start-WorkspaceLinkWatcher -WorkspacePath $WorkspacePath -ExtraArgs @('--config', (Join-Path $WorkspacePath 'project/config.yaml'))
try {
    # Rename the target inside the override folder (the "-task suffix" case).
    # blueprint/index.md's virtual-root link /tasks/example.md should be rewritten
    # to /tasks/example-task.md; outside-note.md must stay untouched.
    Move-Item "$WorkspacePath/project/blueprint/tasks/example.md" "$WorkspacePath/project/blueprint/tasks/example-task.md"

    # Allow LinkWatcher to detect the rename and update references before verification.
    Wait-LinkWatcherSettle -Handle $lw
}
finally {
    Stop-WorkspaceLinkWatcher -Handle $lw
}
