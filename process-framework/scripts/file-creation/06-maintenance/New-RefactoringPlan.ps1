# New-RefactoringPlan.ps1
# Creates a new Refactoring Plan document with an automatically assigned ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Refactoring Plan document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Refactoring Plan documents by:
    - Generating a unique document ID (PF-REF-XXX)
    - Creating a properly formatted document file
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for refactoring planning and tracking

.PARAMETER RefactoringScope
    Brief description of the refactoring scope (e.g., "User Authentication Module", "Database Layer Optimization")

.PARAMETER TargetArea
    Specific component, module, or code area being refactored

.PARAMETER Priority
    Priority level of the refactoring (High, Medium, Low). Defaults to "Medium"

.PARAMETER DebtItemId
    Optional. The tech debt item ID that triggered this refactoring (e.g., "TD007", "PF-TDI-003").
    When provided, auto-populates the debt_item frontmatter field, a "Debt Item" line in the plan body,
    and (for the Lightweight template) the [Debt Item ID] placeholder in the Item 1 header.
    In batch mode (-ItemCount > 1), only Item 1's header is filled; Items 2..N keep the [Debt Item ID]
    placeholder so each can be hand-filled with its own tech debt ID.

.PARAMETER FeatureId
    Optional. The feature ID that owns the code being refactored (e.g., "1.1.1", "2.2.1").
    When provided, auto-populates the feature_id frontmatter field and the documentation
    checklist references in the lightweight template so they point to the correct feature's docs.

    Auto-detection: when -TargetArea points to a test file and the project's language config
    defines testing.featureMarkerPattern (a regex with capture group 1 = feature_id), the
    value is auto-detected from the file's marker. If -FeatureId is omitted, it is filled
    from the marker (info log). If -FeatureId is provided and disagrees with the marker,
    a warning is emitted and the explicitly-passed -FeatureId is kept.

.PARAMETER IncludeDependencies
    If specified (with -Lightweight), includes a Dependencies and Impact section in the lightweight plan.
    By default, lightweight plans omit this section since most lightweight refactorings are single-file
    with no cross-component impact. Use this flag for multi-file lightweight refactorings where
    dependency awareness matters.

.PARAMETER Lightweight
    If specified, creates a lightweight refactoring plan using the compact template (PF-TEM-050).
    Use for changes with no architectural impact (any file count, any effort level).
    Only use Standard for refactorings that redesign interfaces, decompose classes, or change architectural patterns.
    Supports batch mode — use -ItemCount N to pre-generate N Item sections, or copy the "Item N" section manually.
    Mutually exclusive with -DocumentationOnly.

.PARAMETER ItemCount
    Number of Item sections to pre-generate in the lightweight refactoring plan. Defaults to 1.
    Use values > 1 for batch refactoring sessions covering multiple debt items in one plan
    (e.g., -ItemCount 4 for a 4-item batch). Each Item section is a copy of the Item 1 block
    with the header number incremented; the Results Summary table is expanded to N rows.
    Requires -Lightweight; rejected with other modes (Standard, DocumentationOnly, Performance)
    since only the lightweight template supports the Item N section pattern.

.PARAMETER DocumentationOnly
    If specified, creates a documentation-only refactoring plan using the documentation template (PF-TEM-052).
    Use for refactoring that involves only documentation changes (no code changes, no test impact).
    Removes code metrics, performance benchmarks, and test coverage sections.
    Mutually exclusive with -Lightweight and -Performance.

.PARAMETER Performance
    If specified, creates a performance-focused refactoring plan using the performance template (PF-TEM-066).
    Replaces code quality metrics with user-defined performance baselines (e.g., I/O counts, timing, throughput, memory, or algorithmic complexity).
    Use for refactorings that target measurable performance improvement rather than code quality.
    Mutually exclusive with -Lightweight and -DocumentationOnly.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    New-RefactoringPlan.ps1 -RefactoringScope "User Authentication Module" -TargetArea "lib/services/auth/"

.EXAMPLE
    New-RefactoringPlan.ps1 -RefactoringScope "Database Layer Optimization" -TargetArea "lib/data/" -Priority "High" -OpenInEditor

.EXAMPLE
    New-RefactoringPlan.ps1 -RefactoringScope "Replace bare excepts in handler.py (TD011)" -TargetArea "src/linkwatcher/handler.py" -Lightweight

.EXAMPLE
    New-RefactoringPlan.ps1 -RefactoringScope "Extract reference lookup (TD022)" -TargetArea "src/linkwatcher/handler.py" -Lightweight -FeatureId "1.1.1" -DebtItemId "TD022"

.EXAMPLE
    New-RefactoringPlan.ps1 -RefactoringScope "Consolidate path utils (TD015)" -TargetArea "linkwatcher/" -Lightweight -IncludeDependencies -DebtItemId "TD015"

.EXAMPLE
    New-RefactoringPlan.ps1 -RefactoringScope "Fix TDD pseudocode drift (TD046)" -TargetArea "doc/technical" -DocumentationOnly -DebtItemId "TD046"

.EXAMPLE
    New-RefactoringPlan.ps1 -RefactoringScope "Reduce file I/O in scan cycle (TD030)" -TargetArea "src/linkwatcher/service.py" -Performance -DebtItemId "TD030"

.EXAMPLE
    New-RefactoringPlan.ps1 -RefactoringScope "Decompose God Class (TD005)" -TargetArea "src/linkwatcher/handler.py" -Priority "High" -DebtItemId "TD005 (PF-TDI-001)"

.EXAMPLE
    New-RefactoringPlan.ps1 -RefactoringScope "Tighten parser test (TD230)" -TargetArea "test/automated/parsers/test_dart.py" -Lightweight -DebtItemId "TD230"
    # FeatureId auto-detected from pytest.mark.feature("2.1.1") marker — no -FeatureId arg needed for test files in languages with featureMarkerPattern configured.

.EXAMPLE
    New-RefactoringPlan.ps1 -RefactoringScope "Tighten BM-002 / BM-006 tolerances + warmups (TD215-TD218)" -TargetArea "test/automated/performance" -Lightweight -ItemCount 5
    # Pre-generates 5 Item sections (Item 1 through Item 5) and 5 rows in the Results Summary table for a batch refactoring session.

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process

    Script Metadata:
    - Script Type: Document Creation Script
    - Created: 2025-07-21
    - For: Creating refactoring plan documents for the Code Refactoring Task
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$RefactoringScope,

    [Parameter(Mandatory = $true)]
    [string]$TargetArea,

    [Parameter(Mandatory = $false)]
    [ValidateSet("High", "Medium", "Low")]
    [string]$Priority = "Medium",

    [Parameter(Mandatory = $false)]
    [string]$DebtItemId,

    [Parameter(Mandatory = $false)]
    [string]$FeatureId,

    [Parameter(Mandatory = $false)]
    [switch]$Lightweight,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeDependencies,

    [Parameter(Mandatory = $false)]
    [switch]$DocumentationOnly,

    [Parameter(Mandatory = $false)]
    [switch]$Performance,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 99)]
    [int]$ItemCount = 1,

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers with walk-up path resolution
$dir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
try {
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
} catch {
    Write-Error "Failed to import Common-ScriptHelpers module. Searched up from: $PSScriptRoot"
    exit 1
}

# Perform standard initialization
Invoke-StandardScriptInitialization


# Soak verification opt-in (PF-PRO-028 v2.0 Pattern B; helper-routed armoring via DocumentManagement.psm1).
# Caller-aware no-arg form: helper resolves this script's path via Get-PSCallStack.
# Idempotent — silently no-ops if already registered.
Register-SoakScript

# Validate mutually exclusive switches
$modeCount = @($Lightweight, $DocumentationOnly, $Performance).Where({ $_ }).Count
if ($modeCount -gt 1) {
    Write-Error @"
-Lightweight, -DocumentationOnly, and -Performance are mutually exclusive. Use at most one:
  -DocumentationOnly  for doc-only refactors (no code changes)
  -Performance        for perf-focused work (I/O, timing, throughput, complexity)
  -Lightweight        for everything else with no architectural impact
  (omit all three)    for Standard mode (architectural redesign, interface changes)
"@
    exit 1
}

# -ItemCount > 1 requires -Lightweight (only the lightweight template has the Item N section pattern)
if ($ItemCount -gt 1 -and -not $Lightweight) {
    Write-Error "-ItemCount $ItemCount requires -Lightweight. The Item N section pattern only exists in the lightweight refactoring plan template."
    exit 1
}

# Auto-detect FeatureId from a language-defined feature-marker pattern.
# Reads project-config.json -> language config to get the marker regex; only
# active when -TargetArea is a leaf file matching the language's testFileExtension.
# Any failure (config missing, file unreadable, etc.) silently falls back to
# the explicitly-passed -FeatureId (or no auto-fill).
try {
    $autoDetectProjectRoot = Get-ProjectRoot
    $projectConfigPath = Join-Path $autoDetectProjectRoot "doc/project-config.json"
    if (Test-Path $projectConfigPath) {
        $projectConfig = Get-Content $projectConfigPath -Raw | ConvertFrom-Json
        $autoDetectLanguage = $projectConfig.testing.language
        if ($autoDetectLanguage) {
            $langConfigPath = Join-Path $autoDetectProjectRoot "process-framework/languages-config/$autoDetectLanguage/$autoDetectLanguage-config.json"
            if (Test-Path $langConfigPath) {
                $langConfig = Get-Content $langConfigPath -Raw | ConvertFrom-Json
                $markerPattern = $langConfig.testing.featureMarkerPattern
                $testExt = $langConfig.testing.testFileExtension
                if ($markerPattern -and $testExt -and (Test-Path $TargetArea -PathType Leaf) -and ($TargetArea -like "*$testExt")) {
                    $fileContent = Get-Content -Path $TargetArea -Raw -ErrorAction SilentlyContinue
                    if ($fileContent -and ($fileContent -match $markerPattern)) {
                        $detectedFeatureId = $Matches[1]
                        if (-not $FeatureId) {
                            Write-Host "Auto-detected FeatureId '$detectedFeatureId' from feature marker in $TargetArea" -ForegroundColor Cyan
                            $FeatureId = $detectedFeatureId
                        } elseif ($FeatureId -ne $detectedFeatureId) {
                            Write-Warning "-FeatureId '$FeatureId' does not match feature marker '$detectedFeatureId' in $TargetArea. Using -FeatureId as provided. Verify this is intentional."
                        }
                    }
                }
            }
        }
    }
} catch {
    Write-Verbose "FeatureId auto-detect skipped: $($_.Exception.Message)"
}

# Select template based on mode switches
if ($Lightweight) {
    $templatePath = "process-framework/templates/06-maintenance/lightweight-refactoring-plan-template.md"
    $modeLabel = "Lightweight"
} elseif ($DocumentationOnly) {
    $templatePath = "process-framework/templates/06-maintenance/documentation-refactoring-plan-template.md"
    $modeLabel = "Documentation-only"
} elseif ($Performance) {
    $templatePath = "process-framework/templates/06-maintenance/performance-refactoring-plan-template.md"
    $modeLabel = "Performance"
} else {
    $templatePath = "process-framework/templates/06-maintenance/refactoring-plan-template.md"
    $modeLabel = "Standard"
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "refactoring_scope" = $RefactoringScope
    "target_area"       = $TargetArea
    "priority"          = $Priority
}
if ($Lightweight) {
    $additionalMetadataFields["mode"] = "lightweight"
}
if ($DocumentationOnly) {
    $additionalMetadataFields["mode"] = "documentation-only"
}
if ($Performance) {
    $additionalMetadataFields["mode"] = "performance"
}
if ($DebtItemId) {
    $additionalMetadataFields["debt_item"] = $DebtItemId
}
if ($FeatureId) {
    $additionalMetadataFields["feature_id"] = $FeatureId
}

# Prepare custom replacements for the template
$debtItemLine = if ($DebtItemId) { "- **Debt Item**: $DebtItemId`n" } else { "" }
$customReplacements = @{
    "[Refactoring Scope]" = $RefactoringScope
    "[Target Area]"       = $TargetArea
    "[Priority Level]"    = $Priority
    "[Creation Date]"     = Get-Date -Format "yyyy-MM-dd"
    "[Author]"            = "AI Agent & Human Partner"
    "[Debt Item Line]"    = $debtItemLine
    "[Debt Item ID]"      = if ($DebtItemId) { $DebtItemId } else { "[Debt Item ID]" }
    "[Feature ID]"        = if ($FeatureId) { $FeatureId } else { "[Feature ID]" }
    "[Dependencies Section]" = if ($Lightweight -and -not $IncludeDependencies) {
        ""
    } elseif ($Lightweight -and $IncludeDependencies) {
        "## Dependencies and Impact`n- **Affected Components**: [List files/modules that will be modified]`n- **Internal Dependencies**: [Components that depend on the changed code]`n- **Risk Assessment**: [Low/Medium] — [Brief risk description]`n`n"
    } else {
        "[Dependencies Section]"
    }
}

# Truncate document name for filename (max 60 chars after kebab-case conversion)
$maxFileNameLength = 60
$kebabScope = ($RefactoringScope.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', '')
if ($kebabScope.Length -gt $maxFileNameLength) {
    # Cut at last hyphen within limit to avoid chopped words
    $truncated = $kebabScope.Substring(0, $maxFileNameLength)
    $lastHyphen = $truncated.LastIndexOf('-')
    if ($lastHyphen -gt 20) {
        $truncated = $truncated.Substring(0, $lastHyphen)
    }
    $documentNameForFile = $truncated
} else {
    $documentNameForFile = $RefactoringScope
}

# Create the document using standardized process
try {
    # When -ItemCount > 1, defer opening the editor until after we've expanded
    # the Item sections — otherwise the user briefly sees the un-expanded file.
    $deferOpenInEditor = ($ItemCount -gt 1) -and $OpenInEditor
    $passOpenInEditor = if ($deferOpenInEditor) { $false } else { [bool]$OpenInEditor }

    # Use DirectoryType for ID registry-based directory resolution
    $documentId = New-StandardProjectDocument -TemplatePath $templatePath -IdPrefix "PD-REF" -IdDescription "Refactoring Plan: $RefactoringScope" -DocumentName $documentNameForFile -DirectoryType "plans" -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$passOpenInEditor

    # Post-process to expand Item sections for batch mode (-ItemCount > 1).
    # Locates "## Item 1:" through (but not including) "<!-- BATCH MODE:", duplicates the
    # block N-1 times with item numbers incremented, and expands the Results Summary table.
    $expandedItems = $false
    if ($ItemCount -gt 1) {
        $plansDir = Get-ProjectIdDirectory -Prefix "PD-REF" -DirectoryType "plans"
        $kebabFileName = ConvertTo-KebabCase -InputString $documentNameForFile
        $createdFilePath = Join-Path -Path $plansDir -ChildPath "$kebabFileName.md"

        if (Test-Path $createdFilePath) {
            $content = Get-Content -Path $createdFilePath -Raw

            $item1Idx = $content.IndexOf("## Item 1:")
            $batchModeIdx = $content.IndexOf("<!-- BATCH MODE:")

            if ($item1Idx -ge 0 -and $batchModeIdx -gt $item1Idx) {
                $itemBlock = $content.Substring($item1Idx, $batchModeIdx - $item1Idx)
                $repeatedBlocks = ''
                for ($n = 2; $n -le $ItemCount; $n++) {
                    $copy = $itemBlock.Replace("## Item 1:", "## Item ${n}:")
                    # Item 1's header had [Debt Item ID] substituted with the passed -DebtItemId; restore the placeholder
                    # for Items 2..N so each can be hand-filled with its own debt ID in batch sessions.
                    if ($DebtItemId) {
                        $copy = $copy.Replace("## Item ${n}: $DebtItemId", "## Item ${n}: [Debt Item ID]")
                    }
                    $repeatedBlocks += $copy
                }
                $content = $content.Substring(0, $batchModeIdx) + $repeatedBlocks + $content.Substring($batchModeIdx)

                # Expand Results Summary table — duplicate the "| 1 | ..." row for items 2..N
                $row1Marker = "| 1 | [TD###]"
                $row1Idx = $content.IndexOf($row1Marker)
                if ($row1Idx -ge 0) {
                    $row1EndIdx = $content.IndexOf("`n", $row1Idx)
                    if ($row1EndIdx -lt 0) { $row1EndIdx = $content.Length }
                    $row1Line = $content.Substring($row1Idx, $row1EndIdx - $row1Idx)
                    $additionalRows = ''
                    for ($n = 2; $n -le $ItemCount; $n++) {
                        $additionalRows += "`n" + $row1Line.Replace("| 1 |", "| $n |")
                    }
                    $content = $content.Substring(0, $row1EndIdx) + $additionalRows + $content.Substring($row1EndIdx)
                } else {
                    Write-Warning "Could not locate Results Summary row '| 1 | [TD###]' in $createdFilePath. Item sections expanded; table not expanded — add rows manually."
                }

                Set-Content -Path $createdFilePath -Value $content -NoNewline
                $expandedItems = $true

                if ($deferOpenInEditor) {
                    Open-ProjectFileInEditor -FilePath $createdFilePath | Out-Null
                }
            } else {
                Write-Warning "Could not locate '## Item 1:' / '<!-- BATCH MODE:' markers in $createdFilePath. -ItemCount expansion skipped — copy the Item N section manually."
            }
        } else {
            Write-Warning "Created file not found at expected path '$createdFilePath' for -ItemCount expansion. The plan was created but Item sections were not expanded."
        }
    }

    # Provide success details
    $details = @(
        "Mode: $modeLabel",
        "Refactoring Scope: $RefactoringScope",
        "Target Area: $TargetArea",
        "Priority: $Priority"
    )
    if ($DebtItemId) {
        $details += "Debt Item: $DebtItemId"
    }
    if ($FeatureId) {
        $details += "Feature: $FeatureId"
    }
    if ($expandedItems) {
        $details += "Item Count: $ItemCount (Item sections + Results Summary rows pre-generated)"
    }

    # Add next steps if not opening in editor
    if (-not $OpenInEditor) {
        if ($Lightweight) {
            $details += @(
                "",
                "📝 Lightweight plan created. Fill in Item sections, then update Documentation & State Updates checklist for each item.",
                "   For multi-file changes with cross-component impact, re-create with -IncludeDependencies to add a Dependencies and Impact section."
            )
        } elseif ($DocumentationOnly) {
            $details += @(
                "",
                "📝 Documentation-only plan created. Code metrics, test coverage, and performance sections have been removed.",
                "   Fill in documentation quality baseline, affected documents, and verification approach."
            )
        } elseif ($Performance) {
            $details += @(
                "",
                "📝 Performance plan created. Code quality metrics replaced with user-defined performance baselines.",
                "   Define 2-4 metrics relevant to your refactoring (I/O, timing, complexity class, etc.) and fill in baselines and targets."
            )
        } else {
            $details += "Customization required — see process-framework/guides/06-maintenance/code-refactoring-task-usage-guide.md"
        }
    }

    Write-ProjectSuccess -Message "Created $modeLabel Refactoring Plan with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Refactoring Plan: $($_.Exception.Message)" -ExitCode 1
}
