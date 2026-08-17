# New-DesignGuidelines.ps1
# Creates the project's Design Guidelines document — the design-system reference — at the
# reserved singleton ID PD-UIX-001.
#
# Created 2026-06-30 for the UI Capability Completion extension (PF-PRO-052 / PF-IMP-1349, A-2).

<#
.SYNOPSIS
    Creates the project's Design Guidelines document (PD-UIX-001), the per-project design-system reference.

.DESCRIPTION
    Scaffolds the single Design Guidelines document from design-guidelines-template.md into
    doc/technical/design/ui-ux/design-system/design-guidelines.md.

    Unlike New-UIDesign.ps1 (which creates per-feature PD-UIX-NNN documents), this is a project-level
    singleton: it pins the reserved PD-UIX-001 ID directly — the PD-UIX registry's nextAvailable already
    starts at 2 to reserve that slot — by calling New-ProjectDocumentWithMetadata, so no registry counter
    is consumed and Invoke-DesignArtifactCreation's per-feature Status / state-file writes (which would
    self-skip with no FeatureId anyway) are bypassed. It refuses to overwrite an existing Design Guidelines
    document. The craft of filling it well comes from the UI design craft skill / customization guide.

.PARAMETER ProjectName
    Optional project name used to fill the document title. When omitted, the [Project Name] placeholder
    is left for customization.

.PARAMETER Description
    Optional one-line scope/description used for the document's frontmatter `description:` (rendered in the
    generated PD documentation map) and the Scope line.

.PARAMETER OpenInEditor
    Open the created document in the editor.

.PARAMETER DryRun
    Preview without writing (equivalent to -WhatIf).
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)] [string]$ProjectName = "",
    [Parameter(Mandatory = $false)] [string]$Description = "",
    [Parameter(Mandatory = $false)] [switch]$OpenInEditor,
    [Parameter(Mandatory = $false)] [switch]$DryRun
)

# Walk-up Common-ScriptHelpers import
$dir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

Invoke-StandardScriptInitialization

# Unify -DryRun with -WhatIf so one preview flag gates everything (mirrors Invoke-DesignArtifactCreation).
if ($DryRun) { $WhatIfPreference = $true }
$preview = [bool]$WhatIfPreference

# Soak opt-in for THIS script (caller-aware; no-op under preview / PF_SOAK_DISABLE). The soak counter
# auto-resets + auto-confirms inside New-ProjectDocumentWithMetadata on a real run, so this script is
# self-armored like the other creation scripts.
Register-SoakScript -WhatIf:$preview

# ---- Reserved singleton identity ----
$documentId   = "PD-UIX-001"
$templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/02-design/design-guidelines-template.md"
$outputDir    = Get-ProjectIdDirectory -Prefix "PD-UIX" -DirectoryType "design-system"
$outputPath   = Join-Path $outputDir "design-guidelines.md"
$relativePath = "doc/technical/design/ui-ux/design-system/design-guidelines.md"

# ---- Singleton guard: never overwrite an existing Design Guidelines document ----
if (Test-Path $outputPath) {
    Write-ProjectError -Message "Design Guidelines already exists at $relativePath ($documentId). It is a per-project singleton — edit it directly, or remove it first if you intend to recreate it." -ExitCode 1
}

# ---- Template / metadata customization ----
$resolvedDescription = if ($Description -ne "") { $Description } else { "Project Design Guidelines (design-system reference)" }

$customReplacements = @{
    "[Project Name]" = if ($ProjectName -ne "") { $ProjectName } else { "[Project Name]" }
    "[Description]"   = $resolvedDescription
    "[Date]"          = Get-Date -Format "yyyy-MM-dd"
    "[Author]"        = "AI Agent & Human Partner"
}
$additionalMetadataFields = @{
    description = $resolvedDescription
}

# ---- Create (reserved-ID singleton; bypasses ID allocation; self-arms soak) ----
try {
    if ($PSCmdlet.ShouldProcess($outputPath, "Create Design Guidelines ($documentId)")) {
        $created = New-ProjectDocumentWithMetadata `
            -TemplatePath $templatePath `
            -OutputPath $outputPath `
            -DocumentId $documentId `
            -Replacements $customReplacements `
            -AdditionalMetadataFields $additionalMetadataFields `
            -OpenInEditor:$OpenInEditor

        if (-not $created) { throw "Document creation returned failure" }

        $details = @(
            "ID: $documentId (reserved project-level singleton)",
            "Path: $relativePath",
            "",
            "Next: customize the Design Guidelines — fill the Required sections, delete unused Optional sections.",
            "      The UI design craft (how to fill it well) comes from the ui-design craft skill.",
            "      Then regenerate the PD documentation map: Build-DocumentationMap.ps1 -Tree PD",
            "      (a UI Design task run does this at its map step; a standalone creation does not)."
        )
        Write-ProjectSuccess -Message "Created Design Guidelines with ID: $documentId" -Details $details
    }
    else {
        Write-Host "DRY RUN: Would create Design Guidelines ($documentId) at $relativePath" -ForegroundColor Yellow
    }
}
catch {
    Write-ProjectError -Message "Failed to create Design Guidelines: $($_.Exception.Message)" -ExitCode 1
}
