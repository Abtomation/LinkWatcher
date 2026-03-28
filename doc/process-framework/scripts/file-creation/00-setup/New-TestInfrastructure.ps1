# New-TestInfrastructure.ps1
# Bootstraps the test directory structure, tracking files, and TE-id-registry
# for a new project adopting the process framework.
# Language-agnostic: reads languages-config/{language}/{language}-config.json for
# fixture files, package markers, and test runner configuration.

<#
.SYNOPSIS
    Bootstraps test infrastructure for a new project adopting the process framework.

.DESCRIPTION
    Creates the complete test directory structure, tracking files, and ID registry
    needed by the process framework's testing infrastructure. This script replaces
    the manual 6-step scaffolding process in the Test Infrastructure Guide.

    What it creates:
    - test/automated/{categories}/ directories (from project-config.json quickCategories + defaults)
    - test/specifications/feature-specs/ and cross-cutting-specs/
    - test/e2e-acceptance-testing/templates/, workspace/, results/
    - test/audits/
    - test/state-tracking/permanent/
    - test/state-tracking/permanent/test-tracking.md (from template)
    - test/state-tracking/permanent/e2e-test-tracking.md (from template)
    - test/TE-id-registry.json (from template)
    - Shared fixture file (e.g., conftest.py for Python) from language config
    - Package marker files (e.g., __init__.py for Python) where needed
    - .gitignore entries for workspace/ and results/ directories

.PARAMETER Language
    The project language, matching a subdirectory in languages-config/.
    Examples: "python", "javascript", "dart"

.PARAMETER TestCategories
    Override default test categories. If omitted, uses quickCategories from
    project-config.json plus "integration" as defaults.

.PARAMETER ProjectName
    Override project name for template placeholders. If omitted, reads from
    project-config.json.

.PARAMETER WhatIf
    Shows what would be created without making changes.

.PARAMETER Confirm
    Prompts for confirmation before creating each item.

.EXAMPLE
    .\New-TestInfrastructure.ps1 -Language "python"

.EXAMPLE
    .\New-TestInfrastructure.ps1 -Language "python" -TestCategories @("unit", "integration", "api")

.EXAMPLE
    .\New-TestInfrastructure.ps1 -Language "javascript" -WhatIf

.NOTES
    - Requires project-config.json to exist (run Project Initiation first)
    - Requires languages-config/{language}/{language}-config.json to exist
    - Safe to re-run: skips existing files and directories
    - Used during Project Initiation (PF-TSK-059) Step 9

    Script Type: Infrastructure Bootstrapping Script
    Created: 2026-03-26
    For: Setting up test infrastructure for new framework-adopting projects
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$Language,

    [Parameter(Mandatory=$false)]
    [string[]]$TestCategories,

    [Parameter(Mandatory=$false)]
    [string]$ProjectName
)

# --- Module Import ---
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
if ($dir) {
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
} else {
    Write-Error "Could not find Common-ScriptHelpers.psm1"
    exit 1
}

# --- Standard Initialization ---
try {
    Invoke-StandardScriptInitialization
} catch {
    Write-Warning "Standard initialization not available, proceeding with basic setup"
    $ErrorActionPreference = "Stop"
}

# --- Get Project Root ---
$projectRoot = Get-ProjectRoot

# --- Load project-config.json ---
$projectConfigPath = Join-Path $projectRoot "doc/process-framework/project-config.json"
if (-not (Test-Path $projectConfigPath)) {
    Write-Error "project-config.json not found at $projectConfigPath. Run Project Initiation (PF-TSK-059) first."
    exit 1
}

$projectConfig = Get-Content $projectConfigPath -Raw | ConvertFrom-Json
$resolvedProjectName = if ($ProjectName) { $ProjectName } else { $projectConfig.project.name }
$testDir = if ($projectConfig.testing -and $projectConfig.testing.testDirectory) {
    $projectConfig.testing.testDirectory
} else {
    "test/automated"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  New-TestInfrastructure.ps1" -ForegroundColor Cyan
Write-Host "  Project: $resolvedProjectName" -ForegroundColor Cyan
Write-Host "  Language: $Language" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Load language config ---
$langConfigPath = Join-Path $projectRoot "doc/process-framework/languages-config/$($Language.ToLower())/$($Language.ToLower())-config.json"
if (-not (Test-Path $langConfigPath)) {
    Write-Error "Language config not found: $langConfigPath. Create it from the language config template first."
    exit 1
}

$langConfig = Get-Content $langConfigPath -Raw | ConvertFrom-Json
Write-Host "Loaded language config: $langConfigPath" -ForegroundColor Cyan

# --- Determine test categories ---
if (-not $TestCategories) {
    $TestCategories = @()
    if ($projectConfig.testing -and $projectConfig.testing.quickCategories) {
        $TestCategories = @($projectConfig.testing.quickCategories)
    }
    # Ensure "integration" is always included
    if ($TestCategories -notcontains "integration") {
        $TestCategories += "integration"
    }
    # Ensure "unit" is always included
    if ($TestCategories -notcontains "unit") {
        $TestCategories = @("unit") + $TestCategories
    }
}

Write-Host "Test categories: $($TestCategories -join ', ')" -ForegroundColor Cyan
Write-Host ""

# --- Helper: Create directory if it doesn't exist ---
function New-DirectoryIfNeeded {
    param([string]$Path, [string]$Description)
    $fullPath = Join-Path $projectRoot $Path
    if (Test-Path $fullPath) {
        Write-Host "  [EXISTS] $Path" -ForegroundColor DarkGray
    } elseif ($PSCmdlet.ShouldProcess($Path, "Create directory: $Description")) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  [CREATED] $Path" -ForegroundColor Green
    }
}

# --- Helper: Create file from template if it doesn't exist ---
function New-FileFromTemplate {
    param(
        [string]$TargetPath,
        [string]$TemplatePath,
        [string]$Description,
        [hashtable]$Replacements = @{}
    )
    $fullTarget = Join-Path $projectRoot $TargetPath
    if (Test-Path $fullTarget) {
        Write-Host "  [EXISTS] $TargetPath" -ForegroundColor DarkGray
        return
    }

    if ($PSCmdlet.ShouldProcess($TargetPath, "Create file: $Description")) {
        $fullTemplate = Join-Path $projectRoot $TemplatePath
        if (-not (Test-Path $fullTemplate)) {
            Write-Warning "Template not found: $TemplatePath — creating minimal placeholder"
            $content = "# $Description`n`nCreated by New-TestInfrastructure.ps1"
        } else {
            $content = Get-Content $fullTemplate -Raw -Encoding UTF8
        }

        foreach ($key in $Replacements.Keys) {
            $content = $content.Replace($key, $Replacements[$key])
        }

        # Ensure parent directory exists
        $parentDir = Split-Path $fullTarget -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        Set-Content -Path $fullTarget -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  [CREATED] $TargetPath" -ForegroundColor Green
    }
}

# --- Helper: Create empty file if it doesn't exist ---
function New-EmptyFileIfNeeded {
    param([string]$Path, [string]$Description, [string]$Content = "")
    $fullPath = Join-Path $projectRoot $Path
    if (Test-Path $fullPath) {
        Write-Host "  [EXISTS] $Path" -ForegroundColor DarkGray
    } elseif ($PSCmdlet.ShouldProcess($Path, "Create file: $Description")) {
        $parentDir = Split-Path $fullPath -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        Set-Content -Path $fullPath -Value $Content -Encoding UTF8 -NoNewline
        Write-Host "  [CREATED] $Path" -ForegroundColor Green
    }
}

$date = Get-Date -Format "yyyy-MM-dd"
$templateReplacements = @{
    "[DATE]" = $date
    "[PROJECT_NAME]" = $resolvedProjectName
}

# ============================================================
# Step 1: Create test directory structure
# ============================================================
Write-Host "Step 1: Creating test directory structure..." -ForegroundColor Yellow

# Core test directories
New-DirectoryIfNeeded -Path "$testDir" -Description "Automated test root"
foreach ($category in $TestCategories) {
    New-DirectoryIfNeeded -Path "$testDir/$category" -Description "Test category: $category"
}
New-DirectoryIfNeeded -Path "$testDir/fixtures" -Description "Static test data files"

# Specification directories
New-DirectoryIfNeeded -Path "test/specifications/feature-specs" -Description "Feature test specifications"
New-DirectoryIfNeeded -Path "test/specifications/cross-cutting-specs" -Description "Cross-cutting test specifications"

# E2E acceptance testing directories
New-DirectoryIfNeeded -Path "test/e2e-acceptance-testing/templates" -Description "E2E test case templates"
New-DirectoryIfNeeded -Path "test/e2e-acceptance-testing/workspace" -Description "E2E working copies (gitignored)"
New-DirectoryIfNeeded -Path "test/e2e-acceptance-testing/results" -Description "E2E execution logs (gitignored)"

# Audit directory
New-DirectoryIfNeeded -Path "test/audits" -Description "Test audit reports"

# State tracking directory
New-DirectoryIfNeeded -Path "test/state-tracking/permanent" -Description "Test state tracking"

Write-Host ""

# ============================================================
# Step 2: Create tracking files from templates
# ============================================================
Write-Host "Step 2: Creating tracking files from templates..." -ForegroundColor Yellow

$templateBase = "doc/process-framework/templates/03-testing"

New-FileFromTemplate `
    -TargetPath "test/state-tracking/permanent/test-tracking.md" `
    -TemplatePath "$templateBase/test-tracking-template.md" `
    -Description "Test tracking state file" `
    -Replacements $templateReplacements

New-FileFromTemplate `
    -TargetPath "test/state-tracking/permanent/e2e-test-tracking.md" `
    -TemplatePath "$templateBase/e2e-test-tracking-template.md" `
    -Description "E2E test tracking state file" `
    -Replacements $templateReplacements

New-FileFromTemplate `
    -TargetPath "test/TE-id-registry.json" `
    -TemplatePath "$templateBase/TE-id-registry-template.json" `
    -Description "Test artifacts ID registry" `
    -Replacements $templateReplacements

Write-Host ""

# ============================================================
# Step 3: Create language-specific files
# ============================================================
Write-Host "Step 3: Creating language-specific files..." -ForegroundColor Yellow

# Create shared fixture/setup files from language config
if ($langConfig.testing.testSetup -and $langConfig.testing.testSetup.configFiles) {
    foreach ($configFile in $langConfig.testing.testSetup.configFiles) {
        # Check if a template exists in the language config directory
        $fileName = Split-Path $configFile -Leaf
        $templateInLangDir = Join-Path $projectRoot "doc/process-framework/languages-config/$($Language.ToLower())/$fileName.template"

        if (Test-Path $templateInLangDir) {
            New-FileFromTemplate `
                -TargetPath $configFile `
                -TemplatePath "doc/process-framework/languages-config/$($Language.ToLower())/$fileName.template" `
                -Description "Shared test fixture: $fileName" `
                -Replacements $templateReplacements
        } else {
            # Create a minimal placeholder
            $comment = switch ($Language.ToLower()) {
                "python" { "# Shared test fixtures for $resolvedProjectName`n# Add pytest fixtures here`n" }
                "javascript" { "// Shared test setup for $resolvedProjectName`n// Add Jest setup here`n" }
                "dart" { "// Shared test helpers for $resolvedProjectName`n" }
                default { "# Shared test setup for $resolvedProjectName`n" }
            }
            New-EmptyFileIfNeeded -Path $configFile -Description "Shared test fixture: $fileName" -Content $comment
        }
    }
}

# Create package marker files where needed (e.g., __init__.py for Python)
if ($langConfig.testing.testFileExclusions -and $langConfig.testing.testFileExclusions -contains "__init__.py") {
    # Python needs __init__.py in test directories
    $initContent = "# Test package marker`n"
    New-EmptyFileIfNeeded -Path "$testDir/__init__.py" -Description "Package marker (test root)" -Content $initContent
    foreach ($category in $TestCategories) {
        New-EmptyFileIfNeeded -Path "$testDir/$category/__init__.py" -Description "Package marker ($category)" -Content $initContent
    }
}

Write-Host ""

# ============================================================
# Step 4: Create .gitignore for E2E directories
# ============================================================
Write-Host "Step 4: Creating .gitignore for E2E directories..." -ForegroundColor Yellow

$gitignoreContent = @"
# E2E acceptance testing - generated at runtime
workspace/
results/
"@

New-EmptyFileIfNeeded -Path "test/e2e-acceptance-testing/.gitignore" -Description "E2E gitignore" -Content $gitignoreContent

Write-Host ""

# ============================================================
# Summary
# ============================================================
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Test Infrastructure Setup Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Create/verify native test runner config (e.g., pytest.ini for Python)" -ForegroundColor White
Write-Host "  2. Install test dependencies (e.g., pip install pytest pytest-cov)" -ForegroundColor White
Write-Host "  3. Verify: Run-Tests.ps1 -ListCategories" -ForegroundColor White
Write-Host "  4. Verify: Run-Tests.ps1 -Quick" -ForegroundColor White
Write-Host ""
