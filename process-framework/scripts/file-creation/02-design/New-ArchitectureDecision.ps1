<#
.SYNOPSIS
Creates a new Architecture Decision Record (ADR) with an automatically assigned ID.

.DESCRIPTION
Uses the central ID registry system. Besides creating the ADR, it appends a row to the ADR Index
table in doc/state-tracking/permanent/architecture-tracking.md (skipped if the ID is already
listed).

.PARAMETER Title
Title of the architecture decision. Drives the document title, the kebab-case filename, the
generated documentation-map description, and the ADR Index row.

.PARAMETER Description
Brief description of the decision. Defaults to "Architecture decision regarding <Title>".

.PARAMETER Status
Decision status. Valid values: "Proposed" (default), "Accepted", "Rejected", "Deprecated",
"Superseded". Written to the document body and the ADR Index row.

.PARAMETER RelatedFeatureId
Feature ID the decision relates to (e.g. "1.2.3"). Written to the related_feature_id frontmatter
field; an empty value or "TBD" renders as "-" in the ADR Index row.

.PARAMETER ImpactLevel
Breadth of the decision's architectural impact. Valid values: "Low", "Medium", "High" (default),
"Critical". Written to frontmatter and the ADR Index row.

.PARAMETER OpenInEditor
Opens the created ADR in the configured editor after creation. When omitted, the success report
points at the architecture-decision craft skill for customization.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$Title,

    [Parameter(Mandatory=$false)]
    [string]$Description = "",

    [Parameter(Mandatory=$false)]
    [ValidateSet("Proposed", "Accepted", "Rejected", "Deprecated", "Superseded")]
    [string]$Status = "Proposed",

    [Parameter(Mandatory=$false)]
    [string]$RelatedFeatureId = "",

    [Parameter(Mandatory=$false)]
    [ValidateSet("Low", "Medium", "High", "Critical")]
    [string]$ImpactLevel = "High",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Init, soak opt-in, the New-StandardProjectDocument call, and the create-failure error path
# are owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This Tier-3 script
# keeps its data, its bespoke post-creation tracking writes (Update-DocumentTrackingFiles,
# docmap append, architecture-tracking ADR-Index surgery), and its own report — all inline.

# Prepare custom replacements
$customReplacements = @{
    "[Title]" = $Title
    "[Brief description of the decision]" = if ($Description -ne "") { $Description } else { "Architecture decision regarding $Title" }
    "[Proposed, Accepted, Deprecated, Superseded]" = $Status
}

# Instance description for the generated documentation map (PF-IMP-1173 Phase 3b)
$additionalMetadataFields = @{
    description = "Architecture decision: $Title"
}

try {
    $templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/02-design/adr-template.md"
    $creation = New-FrameworkDocument -TemplatePath $templatePath -IdPrefix "PD-ADR" -IdDescription "Architecture Decision: ${Title}" -DocumentName $Title -OutputDirectory "doc/technical/adr" -Replacements $customReplacements -Metadata $additionalMetadataFields -Label "architecture decision" -OpenInEditor:$OpenInEditor -PassThru

    # The writer's own ID + path (-PassThru, PF-IMP-1678) — no filename re-derivation.
    $arcId = $creation.Id

    # Update tracking files automatically — skipped in preview, where no ID was assigned
    if ($arcId) {
        try {
            $documentPath = $creation.Path
            Write-Verbose "Created document path: $documentPath"
            $trackingMetadata = @{
                "title" = $Title
                "status" = $Status
                "description" = $Description
                "related_feature_id" = $RelatedFeatureId
                "impact_level" = $ImpactLevel
            }

            Write-Host "📊 Updating tracking files..." -ForegroundColor Cyan
            Update-DocumentTrackingFiles -DocumentId $arcId -DocumentType "ADR" -DocumentPath $documentPath -Metadata $trackingMetadata
        }
        catch {
            Write-Warning "Failed to update tracking files: $($_.Exception.Message)"
            Write-Host "📋 Manual tracking file updates may be required" -ForegroundColor Yellow
        }
    }

    # Note: ADR documentation is managed through the central documentation map
    # ADR tracking is consolidated in architecture-tracking.md (ADR Index), not per-feature columns
    # Individual ADRs are referenced through the architecture documentation structure
    Write-Verbose "ADR created and will be discoverable through the architecture documentation structure"

    $details = @(
        "Status: $Status",
        "",
        "Next steps:",
        "1. Edit the file to complete the architecture decision documentation",
        "2. Update the status as the decision progresses through the approval process"
    )

    # Pointer to the customization craft skill
    if (-not $OpenInEditor) {
        $details += "Customization required — apply the architecture-decision craft skill (.claude/skills/architecture-decision/), the ADR customization craft home"
    }

    # PD documentation map is generated from each ADR's frontmatter `description:`
    # (PF-PRO-050, Build-DocumentationMap.ps1 -Tree PD) — no per-creation append.

    # Auto-append entry to architecture-tracking.md ADR Index table
    if ($arcId -or $WhatIfPreference) {
        $projectRoot = Get-ProjectRoot
        $archTrackingPath = Join-Path -Path $projectRoot -ChildPath "doc/state-tracking/permanent/architecture-tracking.md"

        if (Test-Path $archTrackingPath) {
            $relatedFeature = if ($RelatedFeatureId -and $RelatedFeatureId -ne "" -and $RelatedFeatureId -ne "TBD") { $RelatedFeatureId } else { "-" }
            $dateStamp = Get-ProjectTimestamp -Format "Date"
            $adrLink = "[$arcId](/$($creation.RelativePath))"
            $newRow = "| $adrLink | $Title | $Status | $ImpactLevel | $relatedFeature | $dateStamp |"

            if ($PSCmdlet.ShouldProcess("architecture-tracking.md", "Append ADR to ADR Index table")) {
                try {
                    $archContent = Get-Content -Path $archTrackingPath
                    # Check for duplicate
                    $alreadyExists = $archContent | Where-Object { $_ -match [regex]::Escape($arcId) }
                    if ($alreadyExists) {
                        Write-Verbose "ADR $arcId already listed in architecture-tracking.md — skipping"
                    } else {
                        # Find the ADR Index table: locate "## ADR Index" header, then find the last table row
                        $adrIndexLine = -1
                        for ($i = 0; $i -lt $archContent.Count; $i++) {
                            if ($archContent[$i] -match '^## ADR Index') {
                                $adrIndexLine = $i
                                break
                            }
                        }

                        if ($adrIndexLine -ge 0) {
                            # Find the last table row after the header (skip header + separator = +2 lines)
                            $insertAfter = $adrIndexLine + 2  # after separator line
                            for ($i = $adrIndexLine + 3; $i -lt $archContent.Count; $i++) {
                                if ($archContent[$i] -match '^\|') {
                                    $insertAfter = $i
                                } else {
                                    break
                                }
                            }

                            # Insert the new row
                            $before = $archContent[0..$insertAfter]
                            $after = if ($insertAfter + 1 -lt $archContent.Count) { $archContent[($insertAfter + 1)..($archContent.Count - 1)] } else { @() }
                            $updatedContent = $before + $newRow + $after
                            Set-Content -Path $archTrackingPath -Value $updatedContent
                            $details += "Architecture Tracking: Updated (ADR Index)"
                            Write-Host "  ✅ Architecture tracking updated (ADR Index)" -ForegroundColor Green
                        } else {
                            Write-Warning "Could not find '## ADR Index' section in architecture-tracking.md. Manual update required."
                        }
                    }
                }
                catch {
                    Write-Warning "Failed to update architecture-tracking.md: $($_.Exception.Message)"
                }
            }
        } else {
            Write-Verbose "architecture-tracking.md not found — skipping ADR Index update"
        }
    }

    if ($arcId) {
        Write-ProjectSuccess -Message "Created architecture decision with ID: $arcId" -Details $details
    } else {
        Write-ProjectSuccess -Message "What if: would create architecture decision '$Title'"
    }
}
catch {
    Write-ProjectError -Message "Failed to create architecture decision: $($_.Exception.Message)" -ExitCode 1
}
