# New-Handbook.ps1
# Creates a new user handbook with an automatically assigned PD-UGD ID
# Uses the central ID registry system and standardized document creation

<#
.SYNOPSIS
    Creates a new user handbook document with an automatically assigned ID.

.DESCRIPTION
    This PowerShell script generates user handbook documents by:
    - Generating a unique document ID (PD-UGD-XXX)
    - Creating a properly formatted handbook file in doc/user/handbooks/
    - Updating the ID tracker in the central ID registry
    - Providing a complete template for user-facing documentation

.PARAMETER HandbookName
    The display name for the handbook (e.g., "Multi-Project Setup", "File Type Quick Fix")

.PARAMETER Description
    A brief description of what the handbook covers (10-500 chars; this is a one-line
    summary for the documentation map and handbook frontmatter — the full content lives
    in the handbook body, so compress longer drafts).

.PARAMETER ContentType
    Diataxis content type (L1) for the handbook. Valid values are declared in
    doc/PD-id-registry.json under PD-UGD.subdirectories.values. Framework default:
    tutorials, how-to, reference, explanation. Defaults to "how-to".

    Decision guide:
      - tutorials: learning-oriented guided lesson for newcomers
      - how-to: task-oriented practical steps for competent users
      - reference: information-oriented technical facts for lookup
      - explanation: understanding-oriented conceptual discussion

.PARAMETER Topic
    Optional project-specific topic/domain area (L2). Valid values are declared in
    doc/PD-id-registry.json under PD-UGD.topics.values. When the project hasn't
    declared topics, this parameter is accepted freeform (for forward compatibility).

.PARAMETER Category
    DEPRECATED: Use -ContentType. Retained as parameter alias for backward compatibility.

.PARAMETER OpenInEditor
    If specified, opens the created file in the default editor

.EXAMPLE
    New-Handbook.ps1 -HandbookName "Multi-Project Setup" -Description "Guide for using LinkWatcher across multiple projects" -ContentType "how-to"

.EXAMPLE
    New-Handbook.ps1 -HandbookName "CLI Options Reference" -Description "Complete CLI reference" -ContentType "reference"

.EXAMPLE
    New-Handbook.ps1 -HandbookName "Configure Logging" -Description "How to configure logging" -ContentType "how-to" -Topic "logging"

.NOTES
    - Requires PowerShell execution policy to allow script execution
    - Automatically updates the central ID registry with new ID assignments
    - Creates files in doc/user/handbooks/
    - Uses PD-UGD prefix from PD-id-registry.json
    - Template: process-framework/templates/07-deployment/handbook-template.md (PF-TEM-065)
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [ValidateLength(3, 100)]
    [string]$HandbookName,

    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if ($_.Length -lt 10) {
            throw "Description is too short ($($_.Length) chars; minimum 10). Provide a more substantive description."
        }
        if ($_.Length -gt 500) {
            $over = $_.Length - 500
            throw "Description is too long ($($_.Length) chars; maximum 500, $over over). This is a one-line summary for the documentation map and handbook frontmatter — compress the description; the full content lives in the handbook body."
        }
        $true
    })]
    [string]$Description,

    [Parameter(Mandatory=$false)]
    [Alias("Category")]
    [string]$ContentType = "how-to",

    [Parameter(Mandatory=$false)]
    [string]$Topic,

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Perform standard initialization
Invoke-StandardScriptInitialization

# Soak verification (PF-PRO-028 — see process-framework/state-tracking/permanent/script-soak-tracking.md)
$soakScriptId = "process-framework/scripts/file-creation/07-deployment/New-Handbook.ps1"
$soakInSoak   = Test-ScriptInSoak -ScriptId $soakScriptId -ScriptPath $PSCommandPath

# Prepare additional metadata fields for frontmatter
$additionalMetadataFields = @{
    "handbook_name"         = $HandbookName
    "handbook_content_type" = $ContentType
}
if ($Topic) {
    $additionalMetadataFields["handbook_topic"] = $Topic
}

# Prepare custom replacements matching template placeholders
$customReplacements = @{
    "[Handbook Name]" = $HandbookName
    "[Category]"      = $ContentType
    "[ContentType]"   = $ContentType
    "[Topic]"         = if ($Topic) { $Topic } else { "" }
}

# Create the document using standardized process
try {
    $projectRoot = Get-ProjectRoot
    $templatePath = Join-Path $projectRoot "process-framework/templates/07-deployment/handbook-template.md"

    $newDocParams = @{
        TemplatePath             = $templatePath
        IdPrefix                 = "PD-UGD"
        IdDescription            = "User Handbook: $HandbookName"
        DocumentName             = $HandbookName
        DirectoryType            = "handbooks"
        Subdirectory             = $ContentType
        Replacements             = $customReplacements
        AdditionalMetadataFields = $additionalMetadataFields
        OpenInEditor             = $OpenInEditor
    }
    if ($Topic) { $newDocParams["Topic"] = $Topic }
    $documentId = New-StandardProjectDocument @newDocParams

    # Provide success details
    $details = @(
        "Handbook: $HandbookName",
        "Content Type: $ContentType",
        "Description: $Description"
    )
    if ($Topic) { $details += "Topic: $Topic" }

    # Auto-append entry to PD-documentation-map.md under User Handbooks section
    if ($documentId -or $WhatIfPreference) {
        $docMapPath = Join-Path -Path $projectRoot -ChildPath "doc/PD-documentation-map.md"
        $sectionHeader = "### ``user/handbooks/``"
        $kebabName = ConvertTo-KebabCase -InputString $HandbookName
        $relativePath = if ($Topic) {
            "user/handbooks/$ContentType/$Topic/$kebabName.md"
        } else {
            "user/handbooks/$ContentType/$kebabName.md"
        }
        $entryLine = "- [Product: $HandbookName ($documentId)]($relativePath) - $Description"

        # Read-after-write verification: confirm the handbook file landed with the expected ID.
        if ($documentId -and -not $WhatIfPreference) {
            $createdHandbookPath = Join-Path -Path $projectRoot -ChildPath "doc/$relativePath"
            Assert-LineInFile -Path $createdHandbookPath -Pattern ("id:\s*" + [regex]::Escape($documentId)) -Context "Handbook frontmatter id"
        }

        $updated = Add-DocumentationMapEntry -DocMapPath $docMapPath -SectionHeader $sectionHeader -EntryLine $entryLine -CallerCmdlet $PSCmdlet
        if ($updated) {
            # Read-after-write verification: catch silent-success failures (the original IMP-586 trigger).
            if (-not $WhatIfPreference) {
                Assert-LineInFile -Path $docMapPath -Pattern $entryLine -Literal -Context "doc-map entry for $documentId under '$sectionHeader'"
            }
            $details += "Documentation Map: Updated (PD-documentation-map.md)"
        }
    }

    if (-not $OpenInEditor) {
        $details += @(
            "",
            "Next steps:",
            "1. Open the generated file and customize all placeholder sections",
            "2. Remove any sections not applicable to this handbook",
            "3. Add code examples, configuration snippets, and troubleshooting entries",
            "4. Update README.md documentation table if this handbook should be listed there"
        )
    }

    Write-ProjectSuccess -Message "Created user handbook with ID: $documentId" -Details $details

    if ($soakInSoak) {
        Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
    }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome failure -Notes $soakErrMsg
    }
    Write-ProjectError -Message "Failed to create user handbook: $($_.Exception.Message)" -ExitCode 1
}
