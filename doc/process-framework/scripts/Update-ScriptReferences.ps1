# Update-ScriptReferences.ps1
# Updates all references to moved New-*.ps1 scripts to point to the centralized location

param(
    [switch]$DryRun = $false
)

# Import Common-ScriptHelpers to get project root
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Common-ScriptHelpers.psm1") -Force

$rootPath = Join-Path -Path (Get-ProjectRoot) -ChildPath "doc"
$newScriptPath = "scripts/file-creation"

# Define all the script mappings (old path patterns -> new path)
$scriptMappings = @{
    # Product docs scripts that were moved
    "product-docs/functional-design/New-FDD.ps1"                                                                                                                                                                                                                                                   = "$newScriptPath/New-FDD.ps1"
    "product-docs/technical/database/New-SchemaDesign.ps1"                                                                                                                                                                                                                                         = "$newScriptPath/New-SchemaDesign.ps1"
    "product-docs/technical/architecture/assessments/New-ArchitectureAssessment.ps1"                                                                                                                                                                                                               = "$newScriptPath/New-ArchitectureAssessment.ps1"
    "product-docs/technical/architecture/design-docs/adr/New-ArchitectureDecision.ps1"                                                                                                                                                                                                             = "$newScriptPath/New-ArchitectureDecision.ps1"
    "product-docs/technical/architecture/design-docs/tdd/New-tdd.ps1"                                                                                                                                                                                                                              = "$newScriptPath/New-tdd.ps1"
    "product-docs/technical/api/models/New-APIDataModel.ps1"                                                                                                                                                                                                                                       = "$newScriptPath/New-APIDataModel.ps1"
    "product-docs/technical/api/specifications/New-APISpecification.ps1"                                                                                                                                                                                                                           = "$newScriptPath/New-APISpecification.ps1"

    # Test scripts that were moved
    "test/New-TestFile.ps1"                                                                                                                                                                                                                                                                        = "$newScriptPath/New-TestFile.ps1"
    "test/specifications/New-TestSpecification.ps1"                                                                                                                                                                                                                                                = "$newScriptPath/New-TestSpecification.ps1"

    # Relative path patterns that need updating
    "./New-FDD.ps1"                                                                                                                                                                                                                                                                                = "../../$newScriptPath/New-FDD.ps1"
    "./New-tdd.ps1"                                                                                                                                                                                                                                                                                = "../../$newScriptPath/New-tdd.ps1"
    "./New-ArchitectureDecision.ps1"                                                                                                                                                                                                                                                               = "../../$newScriptPath/New-ArchitectureDecision.ps1"
    "./New-TestFile.ps1"                                                                                                                                                                                                                                                                           = "../../$newScriptPath/New-TestFile.ps1"

    # Various relative patterns found in files
    "../../../../New-APIDataModel.ps1"                                                                                                                                                                                                                                                             = "../../$newScriptPath/New-APIDataModel.ps1"
    "../../../../New-APISpecification.ps1"                                                                                                                                                                                                                                                         = "../../$newScriptPath/New-APISpecification.ps1"
    "../../../../New-ArchitectureAssessment.ps1"                                                                                                                                                                                                                                                   = "../../$newScriptPath/New-ArchitectureAssessment.ps1"
    "../../../../New-ArchitectureDecision.ps1"                                                                                                                                                                                                                                                     = "../../$newScriptPath/New-ArchitectureDecision.ps1"
    "../../../../../New-SchemaDesign.ps1"                                                                                                                                                                                                                                                          = "../../$newScriptPath/New-SchemaDesign.ps1"
    "../../New-FDD.ps1"                                                                                                                                                                                                                                                                            = "../../$newScriptPath/New-FDD.ps1"
    "../discrete/../discrete/New-FDD.ps1"                                                                                                                                                                                                                                                          = "../../$newScriptPath/New-FDD.ps1"
    "../New-APIDataModel.ps1"                                                                                                                                                                                                                                                                      = "../../$newScriptPath/New-APIDataModel.ps1"
    "../New-APISpecification.ps1"                                                                                                                                                                                                                                                                  = "../../$newScriptPath/New-APISpecification.ps1"

    # Corrupted paths that need fixing
    "../../../../feedback-forms/../../../../feedback-forms/New-TestAuditReport.ps1"                                                                                                                                                                                                                = "$newScriptPath/New-TestAuditReport.ps1"
    "../../process-framework/feedback/../../process-framework/feedback/../../process-framework/feedback/../../process-framework/feedback/../../process-framework/feedback/../../process-framework/feedback/../../process-framework/feedback/../../process-framework/feedback/New-FeedbackForm.ps1" = "$newScriptPath/New-FeedbackForm.ps1"
    "New-FeedbackForm.ps1t"                                                                                                                                                                                                                                                                        = "$newScriptPath/New-FeedbackForm.ps1"
    "./doc/process-framework/feedback/New-FeedbackForm.ps1"                                                                                                                                                                                                                                        = "$newScriptPath/New-FeedbackForm.ps1"
}

Write-Host "🔍 Scanning for script references to update..." -ForegroundColor Cyan

$totalUpdates = 0
$filesProcessed = 0

# Get all markdown files in the doc directory
$markdownFiles = Get-ChildItem -Path $rootPath -Filter "*.md" -Recurse

foreach ($file in $markdownFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content
    $fileUpdates = 0

    foreach ($oldPath in $scriptMappings.Keys) {
        $newPath = $scriptMappings[$oldPath]

        if ($content -match [regex]::Escape($oldPath)) {
            $content = $content -replace [regex]::Escape($oldPath), $newPath
            $fileUpdates++
            $totalUpdates++

            Write-Host "  📝 $($file.Name): $oldPath -> $newPath" -ForegroundColor Yellow
        }
    }

    if ($fileUpdates -gt 0) {
        $filesProcessed++

        if (-not $DryRun) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            Write-Host "  ✅ Updated $($file.Name) ($fileUpdates changes)" -ForegroundColor Green
        }
        else {
            Write-Host "  🔍 Would update $($file.Name) ($fileUpdates changes)" -ForegroundColor Cyan
        }
    }
}

Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "  Files processed: $filesProcessed" -ForegroundColor White
Write-Host "  Total updates: $totalUpdates" -ForegroundColor White

if ($DryRun) {
    Write-Host "`n🔍 This was a dry run. Use -DryRun:`$false to apply changes." -ForegroundColor Yellow
}
else {
    Write-Host "`n✅ All script references have been updated!" -ForegroundColor Green
}
