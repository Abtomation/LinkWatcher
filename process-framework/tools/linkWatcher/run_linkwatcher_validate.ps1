<#
.SYNOPSIS
Runs LinkWatcher's broken-link scan (--validate) for the current project with the
correct interpreter and the project's per-project config, so path_resolution_overrides
are honored without manual flags.

.DESCRIPTION
Validate sibling of start_linkwatcher_background.ps1. Resolves the project root (from
doc/project-config.json, walking up from the script location) and the global LinkWatcher
install + its dedicated venv python — the same resolution the daemon script uses,
deliberately duplicated here so each tool script stays standalone and portable. It then
invokes `main.py --validate` against the project, passing
`--config <project-root>/tools/linkwatcher/linkwatcher-config.yaml` when that file exists.

The live daemon never reads the config — path_resolution_overrides is validation-only —
so only this --validate path needs it. The config's lifecycle is owned by Project
Initiation (new projects) and per-project migrations (existing projects): this launcher
does NOT create the config. When it is absent, the scan runs without --config, behaving
exactly as before (backward-compatible).

The scan only checks for broken links in the project; the config is an input that tunes
how absolute-from-host ("/...") links resolve, not a thing being validated. main.py writes
the broken-link report and prints its path to stdout (the report location is owned by the
LinkWatcher build, not this launcher).

Exit code: passes through main.py's exit code (1 on invalid project root / missing install).
#>

param()

# Resolve project root from project-config.json by walking up from the script location.
# Duplicated from start_linkwatcher_background.ps1 (standalone-portability convention;
# the daemon script's own copy notes it mirrors IdRegistry.psm1::Resolve-ProjectRootForRegistry).
function Find-ProjectConfigPath {
    param([string]$StartPath)
    $current = $StartPath
    $maxDepth = 10
    for ($i = 0; $i -lt $maxDepth; $i++) {
        $candidate = Join-Path $current "doc\project-config.json"
        if (Test-Path $candidate) {
            try {
                $check = Get-Content $candidate -Raw | ConvertFrom-Json
                if ($check.project_id) { return $candidate }
            } catch {
                # Unparseable — keep walking (treat as no project_id)
            }
        }
        $parent = Split-Path -Parent $current
        if ($parent -eq $current) { break }
        $current = $parent
    }
    return $null
}

# Resolve LinkWatcher installation directory and dedicated venv Python.
# Duplicated from start_linkwatcher_background.ps1 (PD-BUG-077: never use bare 'python').
function Resolve-LinkWatcherInstall {
    $venvRel = ".linkwatcher-venv\Scripts\python.exe"
    $candidates = @()
    if ($env:LINKWATCHER_INSTALL_DIR) { $candidates += $env:LINKWATCHER_INSTALL_DIR }
    $candidates += @(
        (Join-Path $HOME "bin"),
        (Join-Path $HOME "tools"),
        (Join-Path $HOME "scripts"),
        (Join-Path $HOME ".local\bin"),
        (Join-Path $HOME "LinkWatcher")
    )
    foreach ($dir in $candidates) {
        if ((Test-Path (Join-Path $dir "main.py")) -and (Test-Path (Join-Path $dir $venvRel))) {
            return $dir
        }
    }
    return $null
}

# Build the `main.py --validate` argument list. Pure (no filesystem access) so it is unit
# testable; the caller decides whether the config exists and passes its path or $null.
function Get-ValidateArguments {
    param(
        [Parameter(Mandatory)][string]$MainPy,
        [Parameter(Mandatory)][string]$ProjectRoot,
        [string]$ConfigPath  # when non-empty, append --config <path>
    )
    $a = @($MainPy, "--project-root", $ProjectRoot, "--validate")
    if ($ConfigPath) { $a += @("--config", $ConfigPath) }
    return ,$a
}

# When dot-sourced (e.g. by Pester), define functions only and skip the body so tests can
# exercise the helpers without running a scan. Mirrors the daemon script's guard.
if ($MyInvocation.InvocationName -eq '.') { return }

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$configPath = Find-ProjectConfigPath -StartPath $scriptDir

if (-not $configPath) {
    Write-Host "Error: project-config.json (with non-null project_id) not found walking up from: $scriptDir" -ForegroundColor Red
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$projectRoot = $config.project.root_directory

if (-not $projectRoot -or -not (Test-Path $projectRoot)) {
    Write-Host "Error: Invalid project root in project-config.json: $projectRoot" -ForegroundColor Red
    exit 1
}

$lwInstallDir = Resolve-LinkWatcherInstall
if (-not $lwInstallDir) {
    Write-Host "Error: LinkWatcher installation not found." -ForegroundColor Red
    Write-Host "Searched: `$env:LINKWATCHER_INSTALL_DIR, ~/bin, ~/tools, ~/scripts, ~/.local/bin, ~/LinkWatcher" -ForegroundColor Red
    Write-Host "Each location must contain main.py and .linkwatcher-venv\Scripts\python.exe" -ForegroundColor Red
    Write-Host "Run the global installer first: python deployment/install_global.py" -ForegroundColor Yellow
    exit 1
}

$lwMainPy = Join-Path $lwInstallDir "main.py"
$lwVenvPython = Join-Path $lwInstallDir ".linkwatcher-venv\Scripts\python.exe"

# Per-project active validation config — NOT created here (owned by Project Initiation /
# per-project migrations). Absent → scan runs without overrides (backward-compatible).
$lwConfig = Join-Path $projectRoot "tools\linkwatcher\linkwatcher-config.yaml"
$cfgArg = if (Test-Path $lwConfig) { $lwConfig } else { $null }
if ($cfgArg) {
    Write-Host "Using per-project validation config: $lwConfig" -ForegroundColor Cyan
} else {
    Write-Host "No per-project config at $lwConfig — running broken-link scan without overrides." -ForegroundColor DarkYellow
}

$pyArgs = Get-ValidateArguments -MainPy $lwMainPy -ProjectRoot $projectRoot -ConfigPath $cfgArg

Write-Host "Running LinkWatcher broken-link scan for $projectRoot..." -ForegroundColor Cyan
& $lwVenvPython @pyArgs
$exitCode = $LASTEXITCODE

# main.py prints the report path itself ("Report written to ...") — the report location is
# owned by the LinkWatcher build, so don't restate a (possibly stale) path here.
exit $exitCode
