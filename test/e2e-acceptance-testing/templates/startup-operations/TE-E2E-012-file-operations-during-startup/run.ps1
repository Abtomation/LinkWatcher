# run.ps1 — Scripted action for TE-E2E-012 (file operations during startup)
# Stops LinkWatcher, creates a new file with references, restarts LinkWatcher,
# then immediately moves a referenced file to test startup race condition handling.
#
# Usage (standalone):
#   pwsh.exe -ExecutionPolicy Bypass -File run.ps1 -WorkspacePath <path>
#
# Usage (orchestrated):
#   Run-E2EAcceptanceTest.ps1 -TestCase "TE-E2E-012" -Group "startup-operations"

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspacePath
)

$projectPath = Join-Path $WorkspacePath "project"

# Step 1: Find the project root by navigating up to .git
# Uses .git instead of .linkwatcher.lock because the orchestrator creates
# a workspace-scoped .linkwatcher.lock that would be found first (PD-BUG-047).
$searchDir = (Resolve-Path $WorkspacePath).Path
while ($searchDir -and -not (Test-Path (Join-Path $searchDir ".git"))) {
    $searchDir = Split-Path -Parent $searchDir
}
if (-not $searchDir) {
    throw "Could not find project root (.git) from $WorkspacePath"
}
$projectRoot = $searchDir

# Step 2: Stop any running LinkWatcher (workspace-scoped or project-scoped)
$lockFiles = @(
    (Join-Path $WorkspacePath ".linkwatcher.lock"),
    (Join-Path $projectRoot ".linkwatcher.lock")
)
foreach ($lockFile in $lockFiles) {
    if (Test-Path $lockFile) {
        try {
            $lwPid = [int](Get-Content $lockFile -Raw).Trim()
            $lwProc = Get-Process -Id $lwPid -ErrorAction SilentlyContinue
            if ($lwProc) {
                Stop-Process -Id $lwPid -Force
                Start-Sleep -Milliseconds 500
                Write-Host "Stopped LinkWatcher (PID: $lwPid)"
            }
        } catch {
            Write-Host "Warning: Could not read lock file $lockFile" -ForegroundColor Yellow
        }
        Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
    }
}

# Step 3: Create a new markdown file that references the existing settings/config.yaml
$docsDir = Join-Path $projectPath "docs"
New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
$guideContent = "# Guide`n`nSee [Config](../settings/config.yaml) for settings.`n"
Set-Content (Join-Path $docsDir "guide.md") $guideContent -Encoding UTF8

# Step 4: Restart LinkWatcher scoped to workspace
$startScript = Join-Path $projectRoot "LinkWatcher_run/start_linkwatcher_background.ps1"
& $startScript -ProjectRoot $WorkspacePath

# Step 5: Wait briefly (LW is starting up but not fully scanned yet)
Start-Sleep -Seconds 2

# Step 6: Move the target file while LW is still starting/scanning
$sourceFile = Join-Path $projectPath "settings/config.yaml"
$destDir = Join-Path $projectPath "config"
New-Item -ItemType Directory -Path $destDir -Force | Out-Null
Move-Item -Path $sourceFile -Destination (Join-Path $destDir "config.yaml")
