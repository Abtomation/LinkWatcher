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

# Init, soak opt-in, the New-StandardProjectDocument call, and the create-failure error path
# are owned by New-FrameworkDocument (PF-IMP-1135 / PF-PRO-043 Option 2). This Tier-3 script
# keeps its data and its own report — all inline under the outer try/catch. (The PD-documentation-map
# is generated from frontmatter per PF-PRO-037, so this script no longer appends to it — PF-IMP-1151.)

# Prepare additional metadata fields for frontmatter
$additionalMetadataFields = @{
    "handbook_name"         = $HandbookName
    "handbook_content_type" = $ContentType
    description             = $Description
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
    $templatePath = Join-Path (Get-ProcessFrameworkPath) "templates/07-deployment/handbook-template.md"

    $newDocParams = @{
        TemplatePath  = $templatePath
        IdPrefix      = "PD-UGD"
        IdDescription = "User Handbook: $HandbookName"
        DocumentName  = $HandbookName
        DirectoryType = "handbooks"
        Subdirectory  = $ContentType
        Replacements  = $customReplacements
        Metadata      = $additionalMetadataFields
        Label         = "user handbook"
        OpenInEditor  = $OpenInEditor
    }
    if ($Topic) { $newDocParams["Topic"] = $Topic }
    $documentId = New-FrameworkDocument @newDocParams

    # Provide success details
    $details = @(
        "Handbook: $HandbookName",
        "Content Type: $ContentType",
        "Description: $Description"
    )
    if ($Topic) { $details += "Topic: $Topic" }

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
}
catch {
    Write-ProjectError -Message "Failed to create user handbook: $($_.Exception.Message)" -ExitCode 1
}
