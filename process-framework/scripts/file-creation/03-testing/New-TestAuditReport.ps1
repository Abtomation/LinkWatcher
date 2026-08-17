# New-TestAuditReport.ps1
# Creates a new Test Audit Report with an automatically assigned ID
# Uses the central ID registry system and standardized document creation
# Supports three test types: Automated (default), Performance, E2E
# Updates the appropriate tracking file with audit report link
# SC-007: Uses file path as test file identifier (not TE-TST/PD-TST IDs)

<#
.SYNOPSIS
    Creates a new Test Audit Report document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Test Audit Report documents by:
    - Generating a unique document ID (TE-TAR-XXX)
    - Creating a properly formatted audit report file using the type-specific template
    - Updating the ID tracker in the central ID registry
    - Updating the appropriate tracking file:
      - Automated: test-tracking.md (Notes column)
      - Performance: performance-test-tracking.md (Audit Status + Audit Report columns)
      - E2E: e2e-test-tracking.md (Audit Status + Audit Report columns)
    - Providing a complete template for test quality assessment

.PARAMETER FeatureId
    The feature ID being audited (e.g., "0.2.3", "1.1.2")

.PARAMETER TestFilePath
    Relative path to the test file being audited (e.g., "test/automated/unit/test_service.py")

.PARAMETER AuditorName
    Name of the auditor conducting the assessment (default: "AI Agent")

.PARAMETER TestType
    The type of test being audited. Determines template and tracking file routing.
    - "Automated" (default): Unit/integration tests → test-tracking.md, 6 criteria
    - "Performance": Performance benchmarks/scale tests → performance-test-tracking.md, 4 criteria
    - "E2E": E2E acceptance tests → e2e-test-tracking.md, 5 criteria

.PARAMETER Lightweight
    If specified, uses the lightweight template for Audit Approved outcomes.
    Only applies to Automated test type (Performance and E2E have no lightweight variant).
    Only use when ALL evaluation criteria pass with no findings to report.

.PARAMETER Force
    If specified, overwrites an existing audit report file instead of blocking.
    Use this for re-audits where the previous report should be replaced.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    New-TestAuditReport.ps1 -FeatureId "0.2.3" -TestFilePath "test/automated/unit/test_service.py" -AuditorName "AI Agent"

.EXAMPLE
    New-TestAuditReport.ps1 -TestType Performance -FeatureId "2.1.1" -TestFilePath "test/automated/performance/level1-component/test_parser_throughput.py" -AuditorName "AI Agent"

.EXAMPLE
    New-TestAuditReport.ps1 -TestType E2E -FeatureId "1.1.1" -TestFilePath "test/e2e-acceptance-testing/templates/powershell-regex-preservation/TE-E2E-001-regex-preserved-on-file-move/test-case.md"

.EXAMPLE
    New-TestAuditReport.ps1 -FeatureId "0.1.1" -TestFilePath "test/automated/unit/test_service.py" -Lightweight

.EXAMPLE
    New-TestAuditReport.ps1 -FeatureId "0.2.3" -TestFilePath "test/automated/unit/test_service.py" -Force
    # Re-audit: overwrites the existing report for this feature/test file combination

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates the output directory if it doesn't exist
    - Uses standardized document creation process
    - Determines feature category automatically based on feature ID
    - SC-007: Uses file path as identifier (not PD-TST/TE-TST IDs)

    Script Metadata:
    - Script Type: Document Creation Script
    - Created: 2025-08-07
    - Updated: 2026-04-28 (IMP-587: pre-populate Test File Path/Name, Audit Status, and TE-E2E-XXX placeholders; harmonize template placeholder names to Title Case)
    - Updated: 2026-06-24 (PF-IMP-1222: E2E report filename uses the unique TE-E2E-NNN id, not the shared 'test-case' basename, so cases sharing a feature id no longer collide; Get-AuditReportDocName helper)
    - For: Creating Test Audit Report documents from templates
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Automated", "Performance", "E2E")]
    [string]$TestType = "Automated",

    [Parameter(Mandatory = $true)]
    [string]$FeatureId,

    [Parameter(Mandatory = $true)]
    [string]$TestFilePath,

    [Parameter(Mandatory = $false)]
    [string]$AuditorName = "AI Agent",

    [Parameter(Mandatory = $false)]
    [switch]$Lightweight,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# --- Script-local helper (defined before the dot-source guard so Pester can load it) ---
function Get-AuditMirrorDir {
    <#
    .SYNOPSIS
        Returns the test/audits/ mirror of a test file's containing directory, or $null.
    .DESCRIPTION
        Audit location = subject location: the report lives in the audit-side mirror of the test
        file's containing dir, produced by replacing the first `/automated/` (or `\automated\`)
        path segment with `/audits/`. Used for Automated and Performance test types. E2E test
        files live under test/e2e-acceptance-testing/ (not /automated/), so this returns $null
        for them and they keep legacy registry-resolved routing.
        Examples (path mirror — level / feature subdirs preserved):
          test/automated/unit/<N>-<slug>/[<N.X>-<slug>/]<file>.py  ->  test/audits/unit/<N>-<slug>/[<N.X>-<slug>/]
          test/automated/performance/level{N}-{name}/<file>.py     ->  test/audits/performance/level{N}-{name}/
    #>
    param([Parameter(Mandatory = $true)][string]$TestFilePath)

    $absTestFile = if ([System.IO.Path]::IsPathRooted($TestFilePath)) {
        $TestFilePath
    } else {
        Join-Path (Get-ProjectRoot) $TestFilePath
    }
    $absTestFileDir = Split-Path -Parent $absTestFile

    # Replace `/automated/` (or `\automated\`) with `/audits/` (or `\audits\`) — only the first
    # occurrence of that exact directory boundary, to avoid false matches on files whose names
    # contain "automated".
    $normalizedDir = $absTestFileDir -replace '(?i)([\\/])automated([\\/])', '$1audits$2'

    if ($normalizedDir -ne $absTestFileDir) { return $normalizedDir }
    return $null
}

function Get-AuditReportDocName {
    <#
    .SYNOPSIS
        Builds the audit-report document name, using the unique TE-E2E-NNN id for E2E reports.
    .DESCRIPTION
        Automated/Performance reports name from the feature id + test-file basename. Every E2E
        test file is basename 'test-case', so when an E2E test-case id (TE-E2E-NNN) is supplied
        the name uses it instead — otherwise every E2E case sharing a feature id collides on
        'audit-report-<feature>-test-case' (PF-IMP-1222). Falls back to the basename when no id
        is available (Automated/Performance, or an E2E path with no resolvable TE-E2E-NNN).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$FeatureId,
        [Parameter(Mandatory = $true)][string]$TestFileBaseName,
        [string]$E2ETestCaseId
    )
    $kebabFeatureId = ($FeatureId -replace '\.', '-')
    $namePart = if ($E2ETestCaseId) { $E2ETestCaseId.ToLower() } else { $TestFileBaseName }
    return "audit-report-$kebabFeatureId-$namePart"
}

# Dot-source guard (PF-IMP-1042): when this script is dot-sourced (e.g. by Pester to unit-test
# the helper above), stop before running the executable body so loading has no side effects.
if ($MyInvocation.InvocationName -eq '.') { return }

# Init, soak opt-in, the New-StandardProjectDocument call, and the create-failure error path
# are owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This Tier-3 script
# keeps its data, its bespoke post-creation tracking writes (test/perf/e2e tracking updates),
# and its own report — all inline under the outer try/catch.

# MSYS path-mangling guard for user-provided -TestFilePath (PF-IMP-767). On Windows + bash,
# leading-slash paths are silently rewritten to "C:/Program Files/Git/..." before PowerShell
# sees them — landing mangled values in audit metadata. -TestFilePath is mandatory so the
# helper's empty-input no-op is defensive belt-and-suspenders here.
if (Test-MSYSPathMangled -Path $TestFilePath -ParameterName 'TestFilePath') {
    exit 1
}

# Validate -Lightweight is only used with Automated test type
if ($Lightweight -and $TestType -ne "Automated") {
    Write-ProjectError -Message "-Lightweight is only supported for Automated test type (not $TestType)" -ExitCode 1
}

# Determine output directory and feature category based on TestType.
# PF-IMP-871 / PF-PRO-034 Phase 3a (2026-05-14): Automated audit reports route by pure path
# transformation (audit location = subject location) — the report lives in the audit-side
# mirror of the test file's containing dir — rather than a hardcoded feature-ID prefix switch.
# PF-IMP-1042 (Phase 3b): Performance reports now use the same transform via Get-AuditMirrorDir,
# landing in test/audits/performance/level{N}-{name}/ (Performance Testing Guide audit-mirror
# convention). E2E test files live under test/e2e-acceptance-testing/, not /automated/, so the
# helper returns $null for them and they keep legacy registry-resolved -DirectoryType routing.
# Failure to resolve the transformed path falls through to a registry default for safety.
$useAuditPathTransform = $false
$auditPathTransformDir = ""
$featureCategory = switch ($TestType) {
    "E2E" { "e2e" }
    "Performance" {
        try {
            $mirrorDir = Get-AuditMirrorDir -TestFilePath $TestFilePath
            if ($mirrorDir) {
                $useAuditPathTransform = $true
                $auditPathTransformDir = $mirrorDir
            }
        } catch {
            Write-Host "  Warning: audit path transform failed ($($_.Exception.Message)) — using default audit dir" -ForegroundColor Yellow
        }
        "performance"  # [Feature Category] value; registry fallback when not transformed
    }
    default {
        # Automated
        try {
            $mirrorDir = Get-AuditMirrorDir -TestFilePath $TestFilePath
            if ($mirrorDir) {
                $useAuditPathTransform = $true
                $auditPathTransformDir = $mirrorDir
                "main"  # registry value unused when $useAuditPathTransform is true
            } else {
                # Path transform produced no change — test file is not under automated/ →
                # fall through to `default` registry-resolved dir for safety.
                "default"
            }
        } catch {
            Write-Host "  Warning: audit path transform failed ($($_.Exception.Message)) — using default audit dir" -ForegroundColor Yellow
            "default"
        }
    }
}

# Derive a short name from the test file path for document naming
$testFileName = Split-Path $TestFilePath -Leaf
$testFileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($testFileName)

# Extract TE-E2E-XXX ID from parent directory for E2E tests
# (used both for placeholder replacement and for row-matching in tracking files)
$e2eTestCaseId = $null
if ($TestType -eq "E2E") {
    $parentDir = Split-Path (Split-Path $TestFilePath -Parent) -Leaf
    if ($parentDir -match '(TE-E2E-\d+)') {
        $e2eTestCaseId = $Matches[1]
    }
}

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "feature_id"     = $FeatureId
    "test_file_path" = $TestFilePath
    "auditor"        = $AuditorName
    "audit_date"     = Get-Date -Format "yyyy-MM-dd"
    description      = "Test audit report for feature $FeatureId ($TestType)"
}

# Prepare custom replacements for template
$customReplacements = @{
    "[Feature ID]"       = $FeatureId
    "[Test File ID]"     = $testFileName
    "[Test File Name]"   = $testFileName
    "[Test File Path]"   = $TestFilePath
    "[Audit Status]"     = "🔍 Audit In Progress"
    "[Auditor Name]"     = $AuditorName
    "[Audit Date]"       = Get-Date -Format "yyyy-MM-dd"
    "[Feature Category]" = $featureCategory.ToUpper()
}
if ($e2eTestCaseId) {
    $customReplacements["[TE-E2E-XXX]"] = $e2eTestCaseId
}

# Create the document using standardized process
try {
    $docName = Get-AuditReportDocName -FeatureId $FeatureId -TestFileBaseName $testFileBaseName -E2ETestCaseId $e2eTestCaseId

    if (-not $PSCmdlet.ShouldProcess($docName, "Create test audit report")) {
        return
    }

    $templateFile = switch ($TestType) {
        "Performance" { "performance-test-audit-report-template.md" }
        "E2E" { "e2e-test-audit-report-template.md" }
        default { if ($Lightweight) { "test-audit-report-lightweight-template.md" } else { "test-audit-report-template.md" } }
    }
    $conflictAction = if ($Force) { "Overwrite" } else { "Error" }
    if ($useAuditPathTransform) {
        # PF-IMP-871 Phase 3a: route Automated audit reports via path transformation
        # rather than registry-resolved -DirectoryType.
        $creation = New-FrameworkDocument -TemplatePath (Join-Path (Get-ProcessFrameworkPath) "templates/03-testing/$templateFile") -IdPrefix "TE-TAR" -IdDescription "Test Audit Report for Feature $FeatureId" -DocumentName $docName -OutputDirectory $auditPathTransformDir -Replacements $customReplacements -Metadata $additionalMetadataFields -ConflictAction $conflictAction -Label "Test Audit Report" -OpenInEditor:$OpenInEditor -PassThru
    } else {
        $creation = New-FrameworkDocument -TemplatePath (Join-Path (Get-ProcessFrameworkPath) "templates/03-testing/$templateFile") -IdPrefix "TE-TAR" -IdDescription "Test Audit Report for Feature $FeatureId" -DocumentName $docName -DirectoryType $featureCategory -Replacements $customReplacements -Metadata $additionalMetadataFields -ConflictAction $conflictAction -Label "Test Audit Report" -OpenInEditor:$OpenInEditor -PassThru
    }
    $documentId = $creation.Id

    # --- State file updates ---
    $projectRoot = Get-ProjectRoot
    $stateUpdates = @()

    # Build the audit report link (relative from tracking file to audit report) from the
    # writer's own filename (-PassThru, PF-IMP-1678). $creation is $null under -WhatIf,
    # where nothing is written — derive a preview-only name there.
    $auditFileName = if ($creation) { Split-Path -Leaf $creation.Path } else { "$(ConvertTo-KebabCase -InputString $docName).md" }

    # Route state file updates based on TestType
    if ($TestType -eq "Automated") {
        # --- Automated: Update test-tracking.md Notes column (SC-007: match by file path, not ID) ---
        $testTrackingPath = Resolve-TrackingFilePath -File "test-tracking.md"
        if ($useAuditPathTransform) {
            # PF-IMP-871 Phase 3a: relative link from test-tracking.md to audit report uses the
            # transformed audit dir (e.g. ../../audits/unit/<N>-<slug>/[<N.X>-<slug>/]<file>.md)
            # rather than the legacy hardcoded ../../audits/$featureCategory/<file>.md.
            $testRoot = Join-Path $projectRoot "test"
            $auditDirRelToTest = $auditPathTransformDir.Substring($testRoot.Length).TrimStart('\','/') -replace '\\', '/'
            $auditRelativePath = "../../$auditDirRelToTest/$auditFileName"
        } else {
            $auditRelativePath = "../../audits/$featureCategory/$auditFileName"
        }
        $auditLink = "[$documentId]($auditRelativePath)"

        if (Test-Path $testTrackingPath) {
            $trackingContent = Get-Content $testTrackingPath -Raw -Encoding UTF8

            # Find the row matching the test file name and append audit link to Notes column
            # Uses header-based column lookup (same pattern as Update-MarkdownTable) for safety
            $lines = $trackingContent -split '\r?\n'
            $updatedLines = @()
            $rowUpdated = $false
            $columnIndices = @{}

            foreach ($line in $lines) {
                # Parse table headers to find column indices by name
                if (-not $rowUpdated -and $line -match '^\|.*\|$' -and $columnIndices.Count -eq 0 -and $line -notmatch '^\|[-\s:]+\|$') {
                    $rawHeaders = $line -split '\|'
                    if ($rawHeaders.Count -gt 2) { $rawHeaders = $rawHeaders[1..($rawHeaders.Count-2)] }
                    $headers = $rawHeaders | ForEach-Object { $_.Trim() }
                    for ($j = 0; $j -lt $headers.Count; $j++) {
                        if ($headers[$j] -ne '') { $columnIndices[$headers[$j]] = $j }
                    }
                    # Reset on each new table header (test-tracking has multiple tables)
                    if (-not $columnIndices.ContainsKey("Test File/Case") -or -not $columnIndices.ContainsKey("Notes")) {
                        $columnIndices = @{}
                    }
                }
                # Reset column indices when leaving a table (new section)
                elseif ($line -match '^#' -and $columnIndices.Count -gt 0) {
                    $columnIndices = @{}
                }

                if (-not $rowUpdated -and $columnIndices.Count -gt 0 -and $line -match "^\|.*$([regex]::Escape($testFileName)).*\|") {
                    $rawCols = $line -split '\|'
                    if ($rawCols.Count -gt 2) { $rawCols = $rawCols[1..($rawCols.Count-2)] }
                    $cols = $rawCols | ForEach-Object { $_.Trim() }

                    # Validate column exists and append audit link to Notes
                    $notesIdx = $columnIndices["Notes"]
                    if ($notesIdx -lt $cols.Count) {
                        $existingNotes = $cols[$notesIdx]
                        if ($existingNotes -and $existingNotes -ne "-" -and $existingNotes -ne "") {
                            $cols[$notesIdx] = "$existingNotes; Audit: $auditLink"
                        } else {
                            $cols[$notesIdx] = "Audit: $auditLink"
                        }
                        $line = "| " + ($cols -join " | ") + " |"
                        $rowUpdated = $true
                    }
                }
                $updatedLines += $line
            }

            if ($rowUpdated) {
                $updatedContent = $updatedLines -join "`n"
                if ($PSCmdlet.ShouldProcess($testTrackingPath, "Update test-tracking.md: append audit report link in Notes for $testFileName")) {
                    Set-Content $testTrackingPath $updatedContent -Encoding UTF8
                    $stateUpdates += "test-tracking.md: $testFileName Notes ← $documentId"
                }
            } else {
                Write-Warning "Could not find $testFileName in test-tracking.md (or table missing Test File/Case / Notes columns) — manual update needed"
            }
        } else {
            Write-Warning "Test tracking file not found: $testTrackingPath"
        }
    }
    else {
        # --- Performance / E2E: Update Audit Status and Audit Report columns in dedicated tracking file ---
        $trackingFilePath = switch ($TestType) {
            "Performance" { Resolve-TrackingFilePath -File "performance-test-tracking.md" }
            "E2E"         { Resolve-TrackingFilePath -File "e2e-test-tracking.md" }
        }
        if ($useAuditPathTransform) {
            # PF-IMP-1042: relative link from performance-test-tracking.md to the audit report uses
            # the transformed audit dir (e.g. ../../audits/performance/level{N}-{name}/<file>.md)
            # rather than the legacy flat ../../audits/performance/<file>.md. E2E never transforms
            # (its files are not under /automated/), so it keeps the flat form below.
            $testRoot = Join-Path $projectRoot "test"
            $auditDirRelToTest = $auditPathTransformDir.Substring($testRoot.Length).TrimStart('\','/') -replace '\\', '/'
            $auditRelativePath = "../../$auditDirRelToTest/$auditFileName"
        } else {
            $auditRelativePath = "../../audits/$featureCategory/$auditFileName"
        }
        $auditLink = "[$documentId]($auditRelativePath)"

        if (Test-Path $trackingFilePath) {
            $trackingContent = Get-Content $trackingFilePath -Raw -Encoding UTF8

            # For E2E tests, match by TE-E2E-xxx Test ID (extracted earlier from parent directory)
            # instead of basename — all E2E cases share "test-case.md", causing first-row collision.
            # Performance tests keep basename matching (unique filenames).
            if ($TestType -eq "E2E") {
                if ($e2eTestCaseId) {
                    $rowMatchPattern = [regex]::Escape($e2eTestCaseId)
                } else {
                    Write-Warning "Could not extract TE-E2E-xxx ID from path '$TestFilePath' — falling back to basename match"
                    $rowMatchPattern = [regex]::Escape($testFileName)
                }
            } else {
                $rowMatchPattern = [regex]::Escape($testFileName)
            }

            # Find the row(s) matching the test identifier and update Audit Status + Audit Report columns.
            # Performance tests permit multi-row updates (one test file produces N tracking rows — e.g., BM-001..008
            # all share test_parser_throughput.py); E2E uses unique TE-E2E-xxx IDs so only one row matches in practice.
            # Performance also uses column-aware matching on the "Test File" column (extracting link text via
            # Get-MarkdownLinkText) to avoid false-positive substring matches if a basename appears in another
            # column. E2E keeps line-wide matching since TE-E2E-xxx IDs are unique enough that collisions are
            # implausible.
            $multiMatch = ($TestType -eq "Performance")
            $useColumnMatch = ($TestType -eq "Performance")
            $lines = $trackingContent -split '\r?\n'
            $updatedLines = @()
            $rowsUpdated = 0
            $columnIndices = @{}

            foreach ($line in $lines) {
                # Parse table headers to find column indices by name
                if ($line -match '^\|.*\|$' -and $columnIndices.Count -eq 0 -and $line -notmatch '^\|[-\s:]+\|$') {
                    $rawHeaders = $line -split '\|'
                    if ($rawHeaders.Count -gt 2) { $rawHeaders = $rawHeaders[1..($rawHeaders.Count-2)] }
                    $headers = $rawHeaders | ForEach-Object { $_.Trim() }
                    for ($j = 0; $j -lt $headers.Count; $j++) {
                        if ($headers[$j] -ne '') { $columnIndices[$headers[$j]] = $j }
                    }
                    # Require both audit columns exist in this table
                    if (-not $columnIndices.ContainsKey("Audit Status") -or -not $columnIndices.ContainsKey("Audit Report")) {
                        $columnIndices = @{}
                    }
                }
                # Reset column indices when leaving a table (new section)
                elseif ($line -match '^#' -and $columnIndices.Count -gt 0) {
                    $columnIndices = @{}
                }

                if (($multiMatch -or $rowsUpdated -eq 0) -and $columnIndices.Count -gt 0 -and $line -match '^\|.*\|$' -and $line -notmatch '^\|[-\s:]+\|$') {
                    $rawCols = $line -split '\|'
                    if ($rawCols.Count -gt 2) { $rawCols = $rawCols[1..($rawCols.Count-2)] }
                    $cols = $rawCols | ForEach-Object { $_.Trim() }

                    # Determine match: column-aware for Performance, line-wide for E2E (and Performance fallback if Test File column missing)
                    $isMatch = $false
                    if ($useColumnMatch -and $columnIndices.ContainsKey("Test File")) {
                        $tfIdx = $columnIndices["Test File"]
                        if ($tfIdx -lt $cols.Count) {
                            $cellText = Get-MarkdownLinkText $cols[$tfIdx]
                            $isMatch = ($cellText -eq $testFileName)
                        }
                    } else {
                        $isMatch = ($line -match $rowMatchPattern)
                    }

                    if ($isMatch) {
                        # Update Audit Status to "🔍 Audit In Progress" and Audit Report to the link
                        $auditStatusIdx = $columnIndices["Audit Status"]
                        $auditReportIdx = $columnIndices["Audit Report"]
                        if ($auditStatusIdx -lt $cols.Count -and $auditReportIdx -lt $cols.Count) {
                            $cols[$auditStatusIdx] = "🔍 Audit In Progress"
                            $cols[$auditReportIdx] = $auditLink
                            $line = "| " + ($cols -join " | ") + " |"
                            $rowsUpdated++
                        }
                    }
                }
                $updatedLines += $line
            }

            if ($rowsUpdated -gt 0) {
                $updatedContent = $updatedLines -join "`n"
                $trackingFileName = Split-Path $trackingFilePath -Leaf
                if ($PSCmdlet.ShouldProcess($trackingFilePath, "Update ${trackingFileName}: set Audit Status/Report for ${testFileName} ($rowsUpdated row(s))")) {
                    Set-Content $trackingFilePath $updatedContent -Encoding UTF8
                    $stateUpdates += "$trackingFileName`: $testFileName Audit ← $documentId ($rowsUpdated row(s))"
                }
            } else {
                $trackingFileName = Split-Path $trackingFilePath -Leaf
                Write-Warning "Could not find $testFileName in $trackingFileName (or table missing Audit Status / Audit Report columns) — manual update needed"
            }
        } else {
            Write-Warning "Tracking file not found: $trackingFilePath"
        }
    }

    # Provide success details
    $variantLabel = switch ($TestType) {
        "Performance" { "Performance (4 criteria)" }
        "E2E" { "E2E (5 criteria)" }
        default { if ($Lightweight) { "Automated Lightweight" } else { "Automated Standard (6 criteria)" } }
    }
    # F-1 (PF-IMP-871 follow-up, 2026-05-15): derive docs-map category from the path-transform
    # output dir (`$auditPathTransformDir`) rather than the legacy `$featureCategory` fallback
    # to `main`. The category is the first path segment after `test/audits/`.
    $docMapCategory = if ($useAuditPathTransform) {
        $segs = $auditPathTransformDir -split '[\\/]'
        $auditsIdx = [Array]::IndexOf($segs, 'audits')
        if ($auditsIdx -ge 0 -and $segs.Length -gt $auditsIdx + 1) {
            $segs[$auditsIdx + 1]
        } else {
            $featureCategory
        }
    } else {
        $featureCategory
    }

    $details = @(
        "Test Type: $TestType",
        "Feature ID: $FeatureId",
        "Test File: $TestFilePath",
        "Auditor: $AuditorName",
        "Category: $docMapCategory",
        "Template: $variantLabel"
    )
    if ($stateUpdates.Count -gt 0) {
        $details += ""
        $details += "📊 State file updates:"
        foreach ($update in $stateUpdates) {
            $details += "  - $update"
        }
    }

    # Add next steps if not opening in editor
    if (-not $OpenInEditor) {
        $details += "Customization required — see process-framework/tasks/03-testing/test-audit-task.md (six evaluation criteria + audit decision)"
    }

    # TE documentation map is generated from each report's frontmatter `description:`
    # (PF-PRO-050, Build-DocumentationMap.ps1 -Tree TE) — no per-creation append.

    Write-ProjectSuccess -Message "Created Test Audit Report with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Test Audit Report: $($_.Exception.Message)" -ExitCode 1
}

<#
.NOTES
TESTING CHECKLIST:
Before considering this script complete, test the following:

1. MODULE IMPORT TEST:
   - Run the script from its intended directory
   - Verify Common-ScriptHelpers module loads without errors
   - Test with both PowerShell ISE and PowerShell terminal

2. BASIC FUNCTIONALITY TEST:
   - Create a test audit report with minimal parameters
   - Verify the document is created in the correct feature category directory
   - Check that the ID is assigned correctly and incremented

3. TEMPLATE REPLACEMENT TEST:
   - Open the created document
   - Verify all [Placeholder] values are replaced correctly
   - Check that no template placeholders remain unreplaced

4. FEATURE CATEGORY TEST:
   - Test with feature ID "0.2.3" (should go to foundation/)
   - Test with feature ID "1.1.2" (should go to authentication/)
   - Test with feature ID "2.1.1" (should go to core-features/)

5. METADATA TEST:
   - Verify the document metadata section is populated correctly
   - Check that custom metadata fields are included
   - Ensure metadata format matches expected structure

6. ERROR HANDLING TEST:
   - Test with invalid parameters
   - Test when template file doesn't exist
   - Test when output directory doesn't exist
   - Verify error messages are helpful

EXAMPLE TEST COMMANDS:
# Basic test (SC-007: uses file path)
New-TestAuditReport.ps1 -FeatureId "0.2.3" -TestFilePath "test/automated/unit/test_service.py" -AuditorName "Test Auditor"

# Cleanup
Remove-Item "../../audits/foundation/audit-report-0-2-3-test_service.md" -Force
#>
