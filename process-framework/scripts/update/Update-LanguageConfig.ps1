#!/usr/bin/env pwsh

# Update-LanguageConfig.ps1
# Adds or updates a field across all language config files and the template to prevent drift

<#
.SYNOPSIS
    Adds or updates a field in all language config files and the language config template.

.DESCRIPTION
    Ensures consistency between all language config files in languages-config/ and the
    language-config-template.json template. When adding a new field, it is inserted into
    every existing language config file and the template simultaneously.

    Updates the following files:
    - process-framework/languages-config/{language}/{language}-config.json (all language configs)
    - process-framework/templates/support/language-config-template.json (template)

.PARAMETER Section
    The top-level section to add the field to (e.g., "testing").

.PARAMETER FieldName
    The name of the new field (e.g., "formatCommand").

.PARAMETER DefaultValue
    The default/placeholder value for existing language configs that don't have a specific value.
    For the template, this is used as the placeholder text.

.PARAMETER TemplateComment
    Description of the field, added as a _comment_ field in the template.

.PARAMETER LanguageValues
    Optional hashtable of language-specific values. Keys are language names (matching config file prefixes),
    values are the field values. Languages not in this hashtable get the DefaultValue.

.PARAMETER List
    List all fields across all language configs and the template, showing drift.

.EXAMPLE
    .\Update-LanguageConfig.ps1 -Section "testing" -FieldName "formatCommand" -DefaultValue "[format command]" -TemplateComment "OPTIONAL. Command to format/auto-fix test files."

.EXAMPLE
    .\Update-LanguageConfig.ps1 -Section "testing" -FieldName "formatCommand" -DefaultValue "[format command]" -TemplateComment "OPTIONAL. Command to format test files." -LanguageValues @{ "python" = "python -m black {testDir}" }

.EXAMPLE
    .\Update-LanguageConfig.ps1 -List

.NOTES
    Used by Process Improvement (PF-TSK-009) when adding new language-specific capabilities,
    and by Framework Extension (PF-TSK-063) when extending the framework.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "Add")]
    [string]$Section,

    [Parameter(Mandatory = $true, ParameterSetName = "Add")]
    [string]$FieldName,

    [Parameter(Mandatory = $true, ParameterSetName = "Add")]
    [string]$DefaultValue,

    [Parameter(Mandatory = $true, ParameterSetName = "Add")]
    [string]$TemplateComment,

    [Parameter(Mandatory = $false, ParameterSetName = "Add")]
    [hashtable]$LanguageValues = @{},

    [Parameter(Mandatory = $true, ParameterSetName = "List")]
    [switch]$List
)

# --- Resolve paths ---
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
# Try PSScriptRoot-based resolution first, fall back to searching upward for project-config.json
$projectRoot = $null
if ($PSScriptRoot) {
    $projectRoot = (Resolve-Path (Join-Path $scriptDir "../../..")).Path
}
if (-not $projectRoot -or -not (Test-Path (Join-Path $projectRoot "process-framework/project-config.json"))) {
    # Search upward from CWD for project-config.json
    $searchDir = (Get-Location).Path
    while ($searchDir -and $searchDir.Length -gt 3) {
        if (Test-Path (Join-Path $searchDir "process-framework/project-config.json")) {
            $projectRoot = $searchDir
            break
        }
        $searchDir = Split-Path $searchDir -Parent
    }
}
if (-not $projectRoot) {
    Write-Error "Could not find project root (no process-framework/project-config.json found)"
    exit 1
}
$langConfigDir = Join-Path $projectRoot "process-framework/languages-config"
$templatePath = Join-Path $projectRoot "process-framework/templates/support/language-config-template.json"

# --- Validate paths ---
if (-not (Test-Path $langConfigDir)) {
    Write-Error "Language config directory not found: $langConfigDir"
    exit 1
}
if (-not (Test-Path $templatePath)) {
    Write-Error "Language config template not found: $templatePath"
    exit 1
}

# --- Get all language config files ---
$configFiles = Get-ChildItem -Path $langConfigDir -Filter "*-config.json" -Recurse

# --- List mode ---
if ($List) {
    Write-Host ""
    Write-Host "Language Config Field Inventory" -ForegroundColor Cyan
    Write-Host ("=" * 60)

    # Collect all fields from all configs + template
    $allFields = @{}

    # Collect fields from all language configs
    foreach ($file in $configFiles) {
        $config = Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $lang = $config.language
        if ($config.testing) {
            $config.testing.PSObject.Properties | ForEach-Object {
                $fieldName = $_.Name
                $key = "testing.$fieldName"
                if (-not $allFields.ContainsKey($key)) { $allFields[$key] = @() }
                $allFields[$key] += $lang
            }
        }
    }

    # Collect template fields
    $template = Get-Content $templatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $templateFieldNames = @()
    if ($template.testing) {
        $template.testing.PSObject.Properties | ForEach-Object {
            $templateFieldNames += $_.Name
        }
    }

    # Display language config fields
    $sortedKeys = $allFields.Keys | Sort-Object
    foreach ($key in $sortedKeys) {
        if ($key -match '_comment_') { continue }
        $fieldName = $key.Split('.')[1]
        $inTemplate = ($templateFieldNames -contains $fieldName) -or ($templateFieldNames -contains "_comment_$fieldName")
        $langs = ($allFields[$key] | Sort-Object) -join ", "
        $marker = if ($inTemplate) { "" } else { " [NOT IN TEMPLATE]" }
        Write-Host "  $key — present in: $langs$marker"
    }

    # Check for template-only fields (not in any language config)
    foreach ($tField in ($templateFieldNames | Sort-Object)) {
        if ($tField -match '^_comment_') { continue }
        $key = "testing.$tField"
        if (-not $allFields.ContainsKey($key)) {
            Write-Host "  $key — TEMPLATE ONLY (no language configs have this)" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "Config files: $($configFiles.Count)" -ForegroundColor Gray
    Write-Host "Template: $templatePath" -ForegroundColor Gray
    exit 0
}

# --- Add mode ---
Write-Host ""
Write-Host "Adding field '$Section.$FieldName' to all language configs and template" -ForegroundColor Cyan
Write-Host ("=" * 60)

$updatedCount = 0

# --- Update each language config file ---
foreach ($file in $configFiles) {
    $config = Get-Content $file.FullName -Raw | ConvertFrom-Json
    $lang = $config.language

    # Check if section exists
    if (-not ($config.PSObject.Properties.Name -contains $Section)) {
        Write-Host "  WARNING: Section '$Section' not found in $($file.Name) — skipping" -ForegroundColor Yellow
        continue
    }

    $sectionObj = $config.$Section

    # Check if field already exists
    if ($sectionObj.PSObject.Properties.Name -contains $FieldName) {
        Write-Host "  $($file.Name): field '$FieldName' already exists — skipping" -ForegroundColor Gray
        continue
    }

    # Determine value: language-specific override or default
    $value = if ($LanguageValues.ContainsKey($lang)) { $LanguageValues[$lang] } else { $DefaultValue }

    if ($PSCmdlet.ShouldProcess("$($file.Name)", "Add field '$Section.$FieldName' = '$value'")) {
        $sectionObj | Add-Member -NotePropertyName $FieldName -NotePropertyValue $value
        $json = $config | ConvertTo-Json -Depth 10
        Set-Content -Path $file.FullName -Value $json -Encoding UTF8
        Write-Host "  $($file.Name): added '$FieldName' = '$value'" -ForegroundColor Green
        $updatedCount++
    }
}

# --- Update template ---
$template = Get-Content $templatePath -Raw | ConvertFrom-Json

if ($template.PSObject.Properties.Name -contains $Section) {
    $templateSection = $template.$Section

    # Add comment field
    $commentField = "_comment_$FieldName"
    if (-not ($templateSection.PSObject.Properties.Name -contains $commentField)) {
        if ($PSCmdlet.ShouldProcess("language-config-template.json", "Add comment field '$Section.$commentField'")) {
            $templateSection | Add-Member -NotePropertyName $commentField -NotePropertyValue $TemplateComment
        }
    }

    # Add value field
    if (-not ($templateSection.PSObject.Properties.Name -contains $FieldName)) {
        if ($PSCmdlet.ShouldProcess("language-config-template.json", "Add field '$Section.$FieldName'")) {
            $templateSection | Add-Member -NotePropertyName $FieldName -NotePropertyValue $DefaultValue
            $json = $template | ConvertTo-Json -Depth 10
            Set-Content -Path $templatePath -Value $json -Encoding UTF8
            Write-Host "  language-config-template.json: added '$FieldName' with comment" -ForegroundColor Green
            $updatedCount++
        }
    } else {
        Write-Host "  language-config-template.json: field '$FieldName' already exists — skipping" -ForegroundColor Gray
    }
} else {
    Write-Host "  WARNING: Section '$Section' not found in template — skipping" -ForegroundColor Yellow
}

# --- Summary ---
Write-Host ""
Write-Host ("=" * 60)
if ($updatedCount -gt 0) {
    Write-Host "Updated $updatedCount file(s) successfully." -ForegroundColor Green
} else {
    Write-Host "No files needed updating." -ForegroundColor Gray
}
Write-Host ("=" * 60)
