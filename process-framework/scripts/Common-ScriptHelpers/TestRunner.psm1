# TestRunner.psm1
# Shared helpers for per-language test runners (Run-Tests.<language>.ps1).
#
# Created: 2026-05-17 by Framework Self-Testing extension (PF-PRO-035) Phase 3a.
#
# Surface (intentionally minimal in Phase 3a — Phase 3c reassessment may grow this):
#   - Resolve-TestLanguageRunner: dispatcher helper; returns path to Run-Tests.<lang>.ps1
#   - Get-TestRunnerLanguageConfig: load and parse languages-config/<lang>/<lang>-config.json
#
# Sub-module of Common-ScriptHelpers. Imports Core.psm1 at module load time
# (per sub-module-scoping pattern in script-development-quick-reference.md).

$coreModule = Join-Path -Path $PSScriptRoot -ChildPath "Core.psm1"
if (Test-Path $coreModule) { Import-Module $coreModule -Force }

function Resolve-TestLanguageRunner {
    <#
    .SYNOPSIS
    Resolve the path to the per-language test runner script (Run-Tests.<language>.ps1).

    .DESCRIPTION
    Given a language name and a project root, locates Run-Tests.<language>.ps1
    under <ProjectRoot>/<process-framework-relative-path>/scripts/language-specific-scripts/<language>/.
    Used by the top-level Run-Tests.ps1 dispatcher.

    .PARAMETER Language
    Language name from project-config.json testing.language field (lower-case).

    .PARAMETER ProjectRoot
    Absolute path to the project root.

    .OUTPUTS
    [string] Absolute path to the per-language runner script. Throws if not found.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Language,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $config = Get-ProjectConfig
    $processFrameworkRel = if ($config.paths.process_framework) { $config.paths.process_framework } else { "process-framework" }

    $candidate = Join-Path $ProjectRoot (Join-Path $processFrameworkRel "scripts/language-specific-scripts/$Language/Run-Tests.$Language.ps1")
    if (-not (Test-Path $candidate)) {
        throw "Per-language test runner not found: $candidate. Expected file Run-Tests.$Language.ps1 under scripts/language-specific-scripts/$Language/. Create it from templates/support/Run-Tests-runner-template.ps1."
    }
    return (Resolve-Path $candidate).Path
}

function Get-TestRunnerLanguageConfig {
    <#
    .SYNOPSIS
    Load and parse a language-config.json file for the given language.

    .DESCRIPTION
    Reads <ProjectRoot>/<process-framework-relative-path>/languages-config/<Language>/<Language>-config.json
    and returns the parsed object. Throws with an actionable message if absent or unparseable.

    .PARAMETER Language
    Language name (e.g., 'python', 'powershell').

    .PARAMETER ProjectRoot
    Absolute path to the project root.

    .OUTPUTS
    [pscustomobject] The parsed language-config object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Language,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $config = Get-ProjectConfig
    $processFrameworkRel = if ($config.paths.process_framework) { $config.paths.process_framework } else { "process-framework" }

    $langConfigPath = Join-Path $ProjectRoot (Join-Path $processFrameworkRel "languages-config/$Language/$Language-config.json")
    if (-not (Test-Path $langConfigPath)) {
        throw "Language config not found: $langConfigPath. Either create it from templates/support/language-config-template.json, or correct testing.language in project-config.json."
    }
    try {
        return Get-Content $langConfigPath -Raw | ConvertFrom-Json
    } catch {
        throw "Failed to parse language config at $langConfigPath`: $($_.Exception.Message)"
    }
}

function Resolve-TestCategoryPath {
    <#
    .SYNOPSIS
    Resolve a -Category value to an absolute test directory, allowing nested categories.

    .DESCRIPTION
    The per-language runners discover only the top-level subdirectories of the test
    'automated/' tree as categories (e.g. 'unit', 'performance'). But the framework's
    own prescriptions (e.g. PF-TSK-009 Step 10: "run Run-Tests.ps1 -Category <area>")
    refer to test *areas* that live deeper — e.g. test/automated/unit/framework/helpers.
    This helper bridges that gap by resolving a category in three steps:

      1. Known top-level category — return automated/<cat> (or testPath/<cat> for
         non-'automated' layouts). Preserves prior behavior exactly.
      2. Relative subpath under the search root — e.g. -Category 'unit/framework/helpers'.
      3. Unique subdirectory leaf-name anywhere under the search root — e.g. -Category
         'helpers' resolves to automated/unit/framework/helpers when that name is unique.

    Throws an actionable message when the name is unknown or ambiguous (matches more than
    one directory), naming the relative paths so the caller can disambiguate. Pure (no
    side effects, no exit) so it is unit-testable; the runner translates a throw into a
    Write-ProjectError.

    .PARAMETER Category
    The category token the user passed (a top-level name, a unique nested name, or a
    relative path under the 'automated/' tree).

    .PARAMETER TestPath
    Absolute path to the project's test directory (project-config.json testing.testDirectory).

    .PARAMETER TopLevelCategories
    The top-level category names the runner already discovered (used to preserve existing
    top-level resolution semantics).

    .OUTPUTS
    [string] Absolute path to the resolved category directory. Throws on unknown/ambiguous.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$TestPath,
        [string[]]$TopLevelCategories = @()
    )

    $automatedRoot = Join-Path $TestPath 'automated'
    $searchRoot = if (Test-Path $automatedRoot) { $automatedRoot } else { $TestPath }

    # 1. Known top-level category — preserve prior behavior exactly.
    if ($Category -in $TopLevelCategories) {
        $topPath = Join-Path $automatedRoot $Category
        if (Test-Path $topPath) { return $topPath }
        return (Join-Path $TestPath $Category)
    }

    # 2. Relative subpath under the search root (e.g. 'unit/framework/helpers').
    $relPath = Join-Path $searchRoot $Category
    if (Test-Path $relPath -PathType Container) { return $relPath }

    # 3. Unique subdirectory leaf-name anywhere under the search root.
    #    NB: do not name this $matches — that is the reserved $Matches automatic variable.
    $hits = @(Get-ChildItem -Path $searchRoot -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq $Category })
    if ($hits.Count -eq 1) { return $hits[0].FullName }
    if ($hits.Count -gt 1) {
        $rels = $hits | ForEach-Object { ($_.FullName.Substring($searchRoot.Length)).TrimStart('\', '/') -replace '\\', '/' }
        throw "Category '$Category' is ambiguous — matches multiple directories: $($rels -join ', '). Pass a relative path (e.g. -Category '$($rels[0])')."
    }
    throw "Unknown category '$Category'. Top-level: $($TopLevelCategories -join ', '). Or pass a unique subdirectory name (e.g. a framework area like 'helpers') or a relative path under the test 'automated/' tree. Use -ListCategories to see top-level categories."
}

Export-ModuleMember -Function Resolve-TestLanguageRunner, Get-TestRunnerLanguageConfig, Resolve-TestCategoryPath
