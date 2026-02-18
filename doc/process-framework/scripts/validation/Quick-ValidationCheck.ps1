#!/usr/bin/env pwsh

<#
.SYNOPSIS
Quick validation check for foundational features and codebase health

.DESCRIPTION
This script performs rapid validation checks on foundational features to provide
immediate feedback on code quality, architectural consistency, and implementation status.
It's designed for quick health checks during development and CI/CD processes.

Key Features:
- Fast execution (< 30 seconds for most checks)
- Multiple output formats (Console, JSON, CSV)
- Configurable check types and severity levels
- Integration with existing validation framework
- Support for specific feature targeting

.PARAMETER FeatureIds
Comma-separated list of feature IDs to validate (e.g., "0.2.1,0.2.2,0.2.3")
If not specified, validates all foundational features (0.2.1-0.2.11)

.PARAMETER CheckType
Type of validation checks to perform:
- "All" (default) - All available checks
- "CodeQuality" - Code style, complexity, documentation
- "Architecture" - Component structure, patterns, interfaces
- "Integration" - Dependencies, state management, navigation
- "Documentation" - TDD alignment, API docs, comments
- "UI" - UI components, styling, accessibility
- "Testing" - Test coverage, test quality, mocking

.PARAMETER OutputFormat
Output format for results:
- "Console" (default) - Colored console output
- "JSON" - JSON format for programmatic use
- "CSV" - CSV format for reporting
- "Summary" - Brief summary only

.PARAMETER Severity
Minimum severity level to report:
- "All" (default) - All findings
- "Warning" - Warnings and errors only
- "Error" - Errors only
- "Critical" - Critical issues only

.PARAMETER OutputPath
Path to save output file (for JSON/CSV formats)
If not specified, outputs to console

.PARAMETER Detailed
Include detailed findings and recommendations in output

.PARAMETER FailOnError
Exit with non-zero code if critical issues are found (useful for CI/CD)

.PARAMETER Quiet
Suppress progress messages, show only results

.EXAMPLE
.\Quick-ValidationCheck.ps1
Runs all checks on all foundational features with console output

.EXAMPLE
.\Quick-ValidationCheck.ps1 -FeatureIds "0.2.1,0.2.2" -CheckType "CodeQuality" -OutputFormat "JSON" -OutputPath "validation-results.json"
Validates specific features for code quality and saves results as JSON

.EXAMPLE
.\Quick-ValidationCheck.ps1 -CheckType "UI" -Severity "Warning" -FailOnError
Validates UI components, shows warnings and errors, fails on critical issues

.NOTES
This script is part of the Foundational Codebase Validation Framework.
It provides rapid feedback complementing the comprehensive validation reports.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$FeatureIds = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "CodeQuality", "Architecture", "Integration", "Documentation", "UI", "Testing")]
    [string]$CheckType = "All",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "JSON", "CSV", "Summary")]
    [string]$OutputFormat = "Console",

    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Warning", "Error", "Critical")]
    [string]$Severity = "All",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",

    [Parameter(Mandatory = $false)]
    [switch]$Detailed,

    [Parameter(Mandatory = $false)]
    [switch]$FailOnError,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

# Configuration
$ErrorActionPreference = "Stop"

# Import Common-ScriptHelpers first to get access to Get-ProjectRoot
try {
    $scriptsDir = Split-Path -Parent $PSScriptRoot
    $commonHelpersPath = Join-Path $scriptsDir "Common-ScriptHelpers.psm1"
    if (Test-Path $commonHelpersPath) {
        Import-Module $commonHelpersPath -Force
    } else {
        throw "Common-ScriptHelpers.psm1 not found at: $commonHelpersPath"
    }
}
catch {
    Write-Error "Could not load Common-ScriptHelpers: $($_.Exception.Message)"
    exit 1
}

# Now use Get-ProjectRoot
$ProjectRoot = Get-ProjectRoot
$LibPath = Join-Path $ProjectRoot "lib"
$TestPath = Join-Path $ProjectRoot "test"
$DocPath = Join-Path $ProjectRoot "doc"

# Validation check definitions
$ValidationChecks = @{
    "CodeQuality"   = @{
        "DartAnalysis"          = @{
            Description = "Run dart analyze on lib/ directory"
            Command     = "flutter analyze"
            Severity    = "Warning"
            Timeout     = 30
        }
        "CodeComplexity"        = @{
            Description   = "Check for overly complex functions and classes"
            Pattern       = "class.*\{[\s\S]*?\}"
            Severity      = "Warning"
            MaxComplexity = 10
        }
        "DocumentationCoverage" = @{
            Description      = "Check for missing documentation comments"
            Pattern          = "^\s*(class|enum|mixin|extension)\s+\w+"
            Severity         = "Warning"
            RequiredCoverage = 80
        }
    }
    "Architecture"  = @{
        "LayerSeparation"      = @{
            Description = "Verify proper layer separation (UI, Service, Repository)"
            Directories = @("lib/presentation", "lib/domain", "lib/data")
            Severity    = "Error"
        }
        "DependencyDirection"  = @{
            Description = "Check dependency direction follows clean architecture"
            Pattern     = "import.*\.\./\.\."
            Severity    = "Warning"
        }
        "SingleResponsibility" = @{
            Description        = "Check for classes with too many responsibilities"
            MaxMethodsPerClass = 15
            Severity           = "Warning"
        }
    }
    "Integration"   = @{
        "StateManagement" = @{
            Description = "Verify Riverpod provider setup and usage"
            Pattern     = "Provider|StateNotifier|Consumer"
            Severity    = "Error"
        }
        "Navigation"      = @{
            Description = "Check GoRouter configuration and route definitions"
            Pattern     = "GoRoute|GoRouter"
            Severity    = "Error"
        }
        "APIIntegration"  = @{
            Description = "Verify Supabase client configuration"
            Pattern     = "SupabaseClient|supabase\."
            Severity    = "Error"
        }
    }
    "Documentation" = @{
        "TDDAlignment"     = @{
            Description = "Check if implementation matches TDD specifications"
            TDDPath     = "doc/product-docs/technical/design"
            Severity    = "Warning"
        }
        "APIDocumentation" = @{
            Description = "Verify API documentation is current"
            Pattern     = "/// .*API"
            Severity    = "Warning"
        }
        "ReadmeUpdated"    = @{
            Description = "Check if README files are current"
            Files       = @("README.md", "lib/README.md")
            Severity    = "Info"
        }
    }
    "UI"            = @{
        "WidgetStructure"  = @{
            Description = "Check widget composition and structure"
            Pattern     = "class.*Widget.*extends.*StatelessWidget|StatefulWidget"
            Severity    = "Warning"
        }
        "ThemeConsistency" = @{
            Description = "Verify consistent theme usage"
            Pattern     = "Theme\.of\(context\)|context\.theme"
            Severity    = "Warning"
        }
        "Accessibility"    = @{
            Description = "Check for accessibility features"
            Pattern     = "Semantics|semanticsLabel|Tooltip"
            Severity    = "Info"
        }
    }
    "Testing"       = @{
        "TestCoverage" = @{
            Description   = "Check test file coverage"
            TestDirectory = "test"
            MinCoverage   = 70
            Severity      = "Warning"
        }
        "TestQuality"  = @{
            Description = "Verify test structure and assertions"
            Pattern     = "expect\(|test\(|group\("
            Severity    = "Warning"
        }
        "MockUsage"    = @{
            Description = "Check proper mock usage in tests"
            Pattern     = "Mock|when\(|verify\("
            Severity    = "Info"
        }
    }
}

# Feature mapping for foundational features
$FoundationalFeatures = @{
    "0.2.1"  = @{ Name = "Repository Pattern Implementation"; Path = "lib/data/repositories" }
    "0.2.2"  = @{ Name = "Service Layer Architecture"; Path = "lib/domain/services" }
    "0.2.3"  = @{ Name = "Data Models & DTOs"; Path = "lib/data/models" }
    "0.2.4"  = @{ Name = "Error Handling Framework"; Path = "lib/core/error" }
    "0.2.5"  = @{ Name = "Logging & Monitoring Setup"; Path = "lib/core/logging" }
    "0.2.6"  = @{ Name = "Navigation & Routing Framework"; Path = "lib/core/routing" }
    "0.2.7"  = @{ Name = "State Management Architecture"; Path = "lib/presentation/providers" }
    "0.2.8"  = @{ Name = "API Client & Network Layer"; Path = "lib/data/datasources" }
    "0.2.9"  = @{ Name = "Caching & Offline Support"; Path = "lib/core/cache" }
    "0.2.10" = @{ Name = "Security & Authentication"; Path = "lib/core/auth" }
    "0.2.11" = @{ Name = "Performance Optimization"; Path = "lib/core/performance" }
}

function Write-Progress-Safe {
    param([string]$Message, [string]$Color = "White")
    if (-not $Quiet -and $OutputFormat -ne "JSON") {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Get-FeaturesToValidate {
    if ([string]::IsNullOrEmpty($FeatureIds)) {
        return $FoundationalFeatures.Keys
    }
    return $FeatureIds -split "," | ForEach-Object { $_.Trim() }
}

function Get-ChecksToRun {
    if ($CheckType -eq "All") {
        return $ValidationChecks.Keys
    }
    return @($CheckType)
}

function Invoke-DartAnalyze {
    try {
        $result = & flutter analyze --no-pub 2>&1
        $exitCode = $LASTEXITCODE

        $issues = @()
        if ($exitCode -ne 0) {
            $result | ForEach-Object {
                if ($_ -match "^\s*(info|warning|error)\s+•\s+(.+)\s+•\s+(.+):(\d+):(\d+)") {
                    $issues += @{
                        Severity = $matches[1]
                        Message  = $matches[2]
                        File     = $matches[3]
                        Line     = $matches[4]
                        Column   = $matches[5]
                    }
                }
            }
        }

        return @{
            Success   = ($exitCode -eq 0)
            Issues    = $issues
            RawOutput = $result -join "`n"
        }
    }
    catch {
        return @{
            Success   = $false
            Issues    = @(@{ Severity = "error"; Message = "Failed to run dart analyze: $($_.Exception.Message)"; File = ""; Line = 0; Column = 0 })
            RawOutput = $_.Exception.Message
        }
    }
}

function Test-FilePattern {
    param(
        [string]$Path,
        [string]$Pattern,
        [string]$Description
    )

    $findings = @()
    if (Test-Path $Path) {
        Get-ChildItem -Path $Path -Recurse -Filter "*.dart" | ForEach-Object {
            $content = Get-Content $_.FullName -Raw
            if ($content -match $Pattern) {
                $findings += @{
                    File        = $_.FullName.Replace($ProjectRoot, "").Replace("\", "/")
                    Description = $Description
                    Match       = $matches[0]
                }
            }
        }
    }
    return $findings
}

function Get-ValidationResults {
    $results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Features  = @{}
        Summary   = @{
            TotalChecks  = 0
            PassedChecks = 0
            Warnings     = 0
            Errors       = 0
            Critical     = 0
        }
        Details   = @()
    }

    $featuresToValidate = Get-FeaturesToValidate
    $checksToRun = Get-ChecksToRun

    Write-Progress-Safe "🔍 Starting Quick Validation Check..." "Cyan"
    Write-Progress-Safe "   Features: $($featuresToValidate -join ', ')" "Gray"
    Write-Progress-Safe "   Check Types: $($checksToRun -join ', ')" "Gray"
    Write-Progress-Safe "   Output Format: $OutputFormat" "Gray"
    Write-Progress-Safe ""

    foreach ($feature in $featuresToValidate) {
        if (-not $FoundationalFeatures.ContainsKey($feature)) {
            Write-Warning "Unknown feature: $feature"
            continue
        }

        $featureInfo = $FoundationalFeatures[$feature]
        $featurePath = Join-Path $LibPath $featureInfo.Path.Replace("lib/", "")

        Write-Progress-Safe "📋 Validating Feature $feature - $($featureInfo.Name)..." "Yellow"

        $featureResults = @{
            Name   = $featureInfo.Name
            Path   = $featureInfo.Path
            Checks = @{}
            Issues = @()
            Status = "PASS"
        }

        foreach ($checkCategory in $checksToRun) {
            if (-not $ValidationChecks.ContainsKey($checkCategory)) {
                continue
            }

            Write-Progress-Safe "   Running $checkCategory checks..." "Gray"

            $categoryChecks = $ValidationChecks[$checkCategory]
            foreach ($checkName in $categoryChecks.Keys) {
                $check = $categoryChecks[$checkName]
                $results.Summary.TotalChecks++

                $checkResult = @{
                    Description = $check.Description
                    Status      = "PASS"
                    Issues      = @()
                    Severity    = $check.Severity
                }

                try {
                    # Perform specific check based on type
                    switch ($checkName) {
                        "DartAnalysis" {
                            if ($checkCategory -eq "CodeQuality") {
                                $analyzeResult = Invoke-DartAnalyze
                                if (-not $analyzeResult.Success) {
                                    $checkResult.Status = "FAIL"
                                    $checkResult.Issues = $analyzeResult.Issues
                                    $featureResults.Status = "FAIL"
                                }
                            }
                        }
                        "LayerSeparation" {
                            if ($checkCategory -eq "Architecture") {
                                $missingDirs = @()
                                foreach ($dir in $check.Directories) {
                                    $fullPath = Join-Path $ProjectRoot $dir
                                    if (-not (Test-Path $fullPath)) {
                                        $missingDirs += $dir
                                    }
                                }
                                if ($missingDirs.Count -gt 0) {
                                    $checkResult.Status = "FAIL"
                                    $checkResult.Issues = @(@{
                                            Severity = $check.Severity.ToLower()
                                            Message  = "Missing directories: $($missingDirs -join ', ')"
                                            File     = ""
                                            Line     = 0
                                        })
                                    $featureResults.Status = "FAIL"
                                }
                            }
                        }
                        "TestCoverage" {
                            if ($checkCategory -eq "Testing") {
                                $libFiles = Get-ChildItem -Path $LibPath -Recurse -Filter "*.dart" | Measure-Object
                                $testFiles = Get-ChildItem -Path $TestPath -Recurse -Filter "*_test.dart" -ErrorAction SilentlyContinue | Measure-Object

                                $coverage = if ($libFiles.Count -gt 0) { ($testFiles.Count / $libFiles.Count) * 100 } else { 0 }

                                if ($coverage -lt $check.MinCoverage) {
                                    $checkResult.Status = "FAIL"
                                    $checkResult.Issues = @(@{
                                            Severity = $check.Severity.ToLower()
                                            Message  = "Test coverage is $([math]::Round($coverage, 1))%, minimum required is $($check.MinCoverage)%"
                                            File     = ""
                                            Line     = 0
                                        })
                                    if ($check.Severity -eq "Error") {
                                        $featureResults.Status = "FAIL"
                                    }
                                }
                            }
                        }
                        default {
                            # Pattern-based checks
                            if ($check.ContainsKey("Pattern")) {
                                $findings = Test-FilePattern -Path $featurePath -Pattern $check.Pattern -Description $check.Description
                                if ($findings.Count -eq 0 -and $check.Severity -eq "Error") {
                                    $checkResult.Status = "FAIL"
                                    $checkResult.Issues = @(@{
                                            Severity = $check.Severity.ToLower()
                                            Message  = "No matches found for required pattern: $($check.Pattern)"
                                            File     = $featureInfo.Path
                                            Line     = 0
                                        })
                                    $featureResults.Status = "FAIL"
                                }
                            }
                        }
                    }

                    # Update summary counters
                    if ($checkResult.Status -eq "PASS") {
                        $results.Summary.PassedChecks++
                    }
                    else {
                        foreach ($issue in $checkResult.Issues) {
                            switch ($issue.Severity) {
                                "warning" { $results.Summary.Warnings++ }
                                "error" { $results.Summary.Errors++ }
                                "critical" { $results.Summary.Critical++ }
                            }
                        }
                    }

                    $featureResults.Checks[$checkName] = $checkResult
                    $featureResults.Issues += $checkResult.Issues

                }
                catch {
                    $checkResult.Status = "ERROR"
                    $checkResult.Issues = @(@{
                            Severity = "error"
                            Message  = "Check failed: $($_.Exception.Message)"
                            File     = ""
                            Line     = 0
                        })
                    $featureResults.Status = "ERROR"
                    $results.Summary.Errors++
                }
            }
        }

        $results.Features[$feature] = $featureResults

        # Show feature summary
        $statusColor = switch ($featureResults.Status) {
            "PASS" { "Green" }
            "FAIL" { "Red" }
            "ERROR" { "Magenta" }
            default { "Yellow" }
        }
        Write-Progress-Safe "   Status: $($featureResults.Status) ($($featureResults.Issues.Count) issues)" $statusColor
    }

    return $results
}

function Format-ConsoleOutput {
    param($Results)

    Write-Host ""
    Write-Host "🎯 Quick Validation Check Results" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host "Timestamp: $($Results.Timestamp)" -ForegroundColor Gray
    Write-Host ""

    # Summary
    Write-Host "📊 Summary:" -ForegroundColor Yellow
    Write-Host "   Total Checks: $($Results.Summary.TotalChecks)" -ForegroundColor White
    Write-Host "   Passed: $($Results.Summary.PassedChecks)" -ForegroundColor Green
    Write-Host "   Warnings: $($Results.Summary.Warnings)" -ForegroundColor Yellow
    Write-Host "   Errors: $($Results.Summary.Errors)" -ForegroundColor Red
    Write-Host "   Critical: $($Results.Summary.Critical)" -ForegroundColor Magenta
    Write-Host ""

    # Feature results
    foreach ($featureId in $Results.Features.Keys) {
        $feature = $Results.Features[$featureId]
        $statusColor = switch ($feature.Status) {
            "PASS" { "Green" }
            "FAIL" { "Red" }
            "ERROR" { "Magenta" }
            default { "Yellow" }
        }

        Write-Host "📋 Feature $featureId - $($feature.Name)" -ForegroundColor White
        Write-Host "   Status: $($feature.Status)" -ForegroundColor $statusColor
        Write-Host "   Path: $($feature.Path)" -ForegroundColor Gray

        if ($feature.Issues.Count -gt 0 -and ($Detailed -or $feature.Status -ne "PASS")) {
            Write-Host "   Issues:" -ForegroundColor Yellow
            foreach ($issue in $feature.Issues) {
                $issueColor = switch ($issue.Severity) {
                    "warning" { "Yellow" }
                    "error" { "Red" }
                    "critical" { "Magenta" }
                    default { "White" }
                }
                Write-Host "     [$($issue.Severity.ToUpper())] $($issue.Message)" -ForegroundColor $issueColor
                if ($issue.File -and $issue.Line -gt 0) {
                    Write-Host "       at $($issue.File):$($issue.Line)" -ForegroundColor Gray
                }
            }
        }
        Write-Host ""
    }

    # Overall status
    $overallStatus = if ($Results.Summary.Critical -gt 0) { "CRITICAL" }
    elseif ($Results.Summary.Errors -gt 0) { "FAILED" }
    elseif ($Results.Summary.Warnings -gt 0) { "WARNING" }
    else { "PASSED" }

    $overallColor = switch ($overallStatus) {
        "PASSED" { "Green" }
        "WARNING" { "Yellow" }
        "FAILED" { "Red" }
        "CRITICAL" { "Magenta" }
    }

    Write-Host "🎉 Overall Status: $overallStatus" -ForegroundColor $overallColor

    return $overallStatus
}

function Format-JsonOutput {
    param($Results, $OutputPath)

    $jsonOutput = $Results | ConvertTo-Json -Depth 10

    if ($OutputPath) {
        $jsonOutput | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Progress-Safe "📄 Results saved to: $OutputPath" "Green"
    }
    else {
        # For JSON output, only output the JSON data
        Write-Output $jsonOutput
    }
}

function Format-CsvOutput {
    param($Results, $OutputPath)

    $csvData = @()
    foreach ($featureId in $Results.Features.Keys) {
        $feature = $Results.Features[$featureId]
        foreach ($issue in $feature.Issues) {
            $csvData += [PSCustomObject]@{
                Timestamp   = $Results.Timestamp
                Feature     = $featureId
                FeatureName = $feature.Name
                Severity    = $issue.Severity
                Message     = $issue.Message
                File        = $issue.File
                Line        = $issue.Line
                Status      = $feature.Status
            }
        }
    }

    if ($OutputPath) {
        $csvData | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-Progress-Safe "📄 Results saved to: $OutputPath" "Green"
    }
    else {
        $csvData | ConvertTo-Csv -NoTypeInformation | Write-Output
    }
}

function Format-SummaryOutput {
    param($Results)

    $overallStatus = if ($Results.Summary.Critical -gt 0) { "CRITICAL" }
    elseif ($Results.Summary.Errors -gt 0) { "FAILED" }
    elseif ($Results.Summary.Warnings -gt 0) { "WARNING" }
    else { "PASSED" }

    Write-Host "Quick Validation Summary: $overallStatus" -ForegroundColor $(
        switch ($overallStatus) {
            "PASSED" { "Green" }
            "WARNING" { "Yellow" }
            "FAILED" { "Red" }
            "CRITICAL" { "Magenta" }
        }
    )
    Write-Host "Checks: $($Results.Summary.PassedChecks)/$($Results.Summary.TotalChecks) passed, $($Results.Summary.Warnings) warnings, $($Results.Summary.Errors) errors, $($Results.Summary.Critical) critical"

    return $overallStatus
}

# Main execution
try {
    $validationResults = Get-ValidationResults

    $overallStatus = switch ($OutputFormat) {
        "Console" { Format-ConsoleOutput -Results $validationResults }
        "JSON" { Format-JsonOutput -Results $validationResults -OutputPath $OutputPath; "COMPLETED" }
        "CSV" { Format-CsvOutput -Results $validationResults -OutputPath $OutputPath; "COMPLETED" }
        "Summary" { Format-SummaryOutput -Results $validationResults }
    }

    # Exit with appropriate code
    if ($FailOnError) {
        $exitCode = switch ($overallStatus) {
            "PASSED" { 0 }
            "WARNING" { 0 }
            "FAILED" { 1 }
            "CRITICAL" { 2 }
            default { 0 }
        }
        exit $exitCode
    }

}
catch {
    Write-Error "❌ Quick validation check failed: $($_.Exception.Message)"
    if ($FailOnError) {
        exit 3
    }
}
