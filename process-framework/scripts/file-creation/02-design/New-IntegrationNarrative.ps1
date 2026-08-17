# New-IntegrationNarrative.ps1
# Creates a new Integration Narrative with an automatically assigned PD-INT ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new Integration Narrative document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates Integration Narrative documents by:
    - Generating a unique document ID (PD-INT-XXX)
    - Creating a properly formatted Integration Narrative document file
    - Updating the ID tracker in the central ID registry
    - Auto-updating user-workflow-tracking.md "Integration Doc" column for the specified workflow

.PARAMETER WorkflowName
    The name of the workflow being documented (e.g., "Directory Move Detection")

.PARAMETER WorkflowId
    The workflow ID from user-workflow-tracking.md (e.g., "WF-002")

.PARAMETER Description
    Optional description of the workflow's purpose

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    New-IntegrationNarrative.ps1 -WorkflowName "Directory Move Detection" -WorkflowId "WF-002" -Description "How filesystem events flow through detection, database, and link updating"

.EXAMPLE
    New-IntegrationNarrative.ps1 -WorkflowName "Link Parsing Pipeline" -WorkflowId "WF-005" -OpenInEditor

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Auto-updates user-workflow-tracking.md
    - Creates the output directory if it doesn't exist

    Template Metadata:
    - Template ID: PF-TEM-020
    - Template Type: Document Creation Script
    - Created: 2026-04-08
    - For: Creating Integration Narrative documents from templates
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$WorkflowName,

    [Parameter(Mandatory=$true)]
    [string]$WorkflowId,

    [Parameter(Mandatory=$false)]
    [string]$Description = "",

    [Parameter(Mandatory=$false)]
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

# Init, soak opt-in, the New-StandardProjectDocument call, and the create-failure error path
# are owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This Tier-3 script
# keeps its data, its bespoke post-creation write (the user-workflow-tracking "Integration Doc"
# update), and its own report — all inline under the outer try/catch. (The PD-documentation-map
# is generated from frontmatter per PF-PRO-037, so this script no longer appends to it — PF-IMP-1151.)

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "workflow_id" = $WorkflowId
    "workflow_name" = $WorkflowName
    description = "Integration narrative for the $WorkflowName workflow"
}

# Prepare custom replacements for the template
$customReplacements = @{
    "[Workflow Name]" = $WorkflowName
    "[Workflow ID]" = $WorkflowId
    "[Description]" = if ($Description -ne "") { $Description } else { "Integration narrative for $WorkflowName workflow" }
    "[Date]" = Get-Date -Format "yyyy-MM-dd"
    "[Author]" = "AI Agent & Human Partner"
}

# Create the document using standardized process
try {
    $templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/02-design/integration-narrative-template.md"

    # Generate filename from workflow name via the canonical helper from
    # Common-ScriptHelpers/Naming.psm1 (PF-IMP-008).
    $workflowNameForFilename = ConvertTo-FeatureSlug -Name $WorkflowName -Convention 'kebab-case'
    $customFileName = "$workflowNameForFilename-integration-narrative.md"

    $documentId = New-FrameworkDocument `
        -TemplatePath $templatePath `
        -IdPrefix "PD-INT" `
        -IdDescription "$workflowNameForFilename-integration-narrative" `
        -DocumentName $WorkflowName `
        -DirectoryType "main" `
        -Replacements $customReplacements `
        -Metadata $additionalMetadataFields `
        -FileNamePattern $customFileName `
        -Label "Integration Narrative" `
        -OpenInEditor:$OpenInEditor

    # Provide success details
    $details = @(
        "Workflow: $WorkflowName",
        "Workflow ID: $WorkflowId"
    )

    if ($Description -ne "") {
        $details += "Description: $Description"
    }

    # Pointer to the customization craft skill
    if (-not $OpenInEditor) {
        $details += "Customization required — apply the integration-narrative craft skill (.claude/skills/integration-narrative/), activated by the Integration Narrative Creation task's Check Recommended Skills step"
    }

    # Auto-update user-workflow-tracking.md "Integration Doc" column
    if ($documentId -or $WhatIfPreference) {
        $workflowTrackingPath = Resolve-TrackingFilePath -File "user-workflow-tracking.md"

        if (Test-Path $workflowTrackingPath) {
            $trackingLines = Get-Content $workflowTrackingPath -Encoding UTF8

            # Find the header row to determine column positions
            $headerIndex = -1
            for ($i = 0; $i -lt $trackingLines.Count; $i++) {
                if ($trackingLines[$i] -match '^\|\s*ID\s*\|') {
                    $headerIndex = $i
                    break
                }
            }

            if ($headerIndex -ge 0) {
                # Find the row matching the WorkflowId
                $targetIndex = -1
                for ($i = $headerIndex + 2; $i -lt $trackingLines.Count; $i++) {
                    if ($trackingLines[$i] -match "^\|\s*$([regex]::Escape($WorkflowId))\s*\|") {
                        $targetIndex = $i
                        break
                    }
                }

                if ($targetIndex -ge 0) {
                    $row = $trackingLines[$targetIndex]

                    # Check if "Integration Doc" column exists in header
                    $headerRow = $trackingLines[$headerIndex]
                    if ($headerRow -match 'Integration Doc') {
                        # Column exists — find its position and update the value
                        $headerCols = $headerRow -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                        $integrationDocIndex = -1
                        for ($c = 0; $c -lt $headerCols.Count; $c++) {
                            if ($headerCols[$c] -match 'Integration Doc') {
                                $integrationDocIndex = $c
                                break
                            }
                        }

                        if ($integrationDocIndex -ge 0) {
                            $rowCols = $row -split '\|'
                            # $rowCols[0] is empty (before first pipe), actual columns start at index 1
                            $colIndex = $integrationDocIndex + 1
                            if ($colIndex -lt $rowCols.Count) {
                                $docLink = " [$documentId](/doc/technical/integration/$customFileName) "
                                if ($PSCmdlet.ShouldProcess("user-workflow-tracking.md row $WorkflowId", "Set Integration Doc to $documentId")) {
                                    $rowCols[$colIndex] = $docLink
                                    $trackingLines[$targetIndex] = $rowCols -join '|'
                                    Set-Content -Path $workflowTrackingPath -Value $trackingLines -Encoding UTF8 -NoNewline:$false
                                    # Read-after-write verification: confirm the workflow row actually carries the new doc link.
                                    Assert-LineInFile -Path $workflowTrackingPath -Pattern $docLink -Literal -Context "workflow-tracking row $WorkflowId Integration Doc"
                                    $details += "Workflow Tracking: Updated $WorkflowId Integration Doc → $documentId"
                                }
                            }
                        }
                    } else {
                        $details += "Workflow Tracking: 'Integration Doc' column not found in header — add column first (Phase 4)"
                    }
                } else {
                    Write-Warning "Workflow ID '$WorkflowId' not found in user-workflow-tracking.md"
                    $details += "Workflow Tracking: $WorkflowId not found — update manually"
                }
            } else {
                Write-Warning "Could not find workflow table header in user-workflow-tracking.md"
                $details += "Workflow Tracking: Table header not found — update manually"
            }
        } else {
            Write-Warning "user-workflow-tracking.md not found at expected path"
            $details += "Workflow Tracking: File not found — update manually"
        }
    }

    Write-ProjectSuccess -Message "Created Integration Narrative with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create Integration Narrative: $($_.Exception.Message)" -ExitCode 1
}

<#
.NOTES
TESTING CHECKLIST:
Before considering this script complete, test the following:

1. ✅ Script creates Integration Narrative with proper PD-INT ID assignment
2. ✅ Template replacements work correctly (WorkflowName, WorkflowId, Description)
3. ✅ Directory structure is created if missing
4. ✅ ID registry is updated properly (PD-INT counter incremented)
5. ✅ user-workflow-tracking.md auto-updated with Integration Doc column value
6. ✅ Error handling works for invalid inputs
7. ✅ Graceful fallback when Integration Doc column doesn't exist yet
8. ✅ OpenInEditor parameter functions correctly
9. ✅ Generated filename format: [workflow-name]-integration-narrative.md

CUSTOMIZATION REQUIREMENTS:
- Ensure integration-narrative-template.md exists in process-framework/templates/02-design/
- Ensure "Integration Doc" column exists in user-workflow-tracking.md (added in Phase 4)
- Customization craft lives in the integration-narrative craft skill (.claude/skills/integration-narrative/)
#>
