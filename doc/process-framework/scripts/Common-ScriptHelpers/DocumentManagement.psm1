# DocumentManagement.psm1
# Document creation and template management functions
# Provides document metadata, template processing, and file creation utilities

<#
.SYNOPSIS
Document creation and template management functions for PowerShell scripts

.DESCRIPTION
This module provides functionality for:
- Document metadata creation and management
- Template processing and content extraction
- Document creation with metadata
- File editor integration
- Standard document creation workflows

.NOTES
Version: 3.0 (Modularized from Common-ScriptHelpers v2.0)
Created: 2025-08-26
#>

# Import dependencies
$scriptPath = Split-Path -Parent $PSScriptRoot
$coreModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers\Core.psm1"
$outputModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers\OutputFormatting.psm1"

if (Test-Path $coreModule) { Import-Module $coreModule -Force }
if (Test-Path $outputModule) { Import-Module $outputModule -Force }

function New-ProjectDocumentMetadata {
    <#
    .SYNOPSIS
    Creates standardized document metadata blocks

    .PARAMETER DocumentId
    The document ID (e.g., "PF-TSK-001")

    .PARAMETER DocumentType
    The type of document (e.g., "Task Definition", "Technical Design Document")

    .PARAMETER Category
    The document category (e.g., "Discrete", "TDD Tier 1")

    .PARAMETER Version
    Document version (default: "1.0")

    .PARAMETER AdditionalFields
    Hashtable of additional metadata fields

    .EXAMPLE
    $metadata = New-ProjectDocumentMetadata -DocumentId "PF-TSK-001" -DocumentType "Task Definition" -Category "Discrete"

    .EXAMPLE
    $additionalFields = @{ "feature_id" = "1.2.3"; "tier" = "2" }
    $metadata = New-ProjectDocumentMetadata -DocumentId "PD-TDD-001" -DocumentType "Technical Design Document" -Category "TDD Tier 2" -AdditionalFields $additionalFields
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DocumentId,

        [Parameter(Mandatory=$true)]
        [string]$DocumentType,

        [Parameter(Mandatory=$true)]
        [string]$Category,

        [Parameter(Mandatory=$false)]
        [string]$Version = "1.0",

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalFields = @{}
    )

    $date = Get-ProjectTimestamp -Format "Date"

    $metadata = @"
---
id: $DocumentId
type: $DocumentType
category: $Category
version: $Version
created: $date
updated: $date
"@

    # Add additional fields
    foreach ($key in $AdditionalFields.Keys) {
        $metadata += "`n$key`: $($AdditionalFields[$key])"
    }

    $metadata += "`n---`n"

    return $metadata
}

function Open-ProjectFileInEditor {
    <#
    .SYNOPSIS
    Opens a file in the appropriate editor with fallback options

    .PARAMETER FilePath
    Path to the file to open

    .PARAMETER PreferredEditor
    Preferred editor command (default: auto-detect)

    .EXAMPLE
    Open-ProjectFileInEditor -FilePath "document.md"

    .EXAMPLE
    Open-ProjectFileInEditor -FilePath "document.md" -PreferredEditor "notepad"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$false)]
        [string]$PreferredEditor
    )

    if (-not (Test-Path $FilePath)) {
        Write-Warning "File not found: $FilePath"
        return $false
    }

    try {
        if ($PreferredEditor) {
            # Use specified editor
            & $PreferredEditor $FilePath
            Write-Verbose "Opened file with $PreferredEditor"
            return $true
        }

        # Try VS Code first if available
        if (Get-Command "code" -ErrorAction SilentlyContinue) {
            & code $FilePath
            Write-Verbose "Opened file with VS Code"
            return $true
        }

        # Fallback to default system editor
        Start-Process $FilePath
        Write-Verbose "Opened file with default system editor"
        return $true
    }
    catch {
        Write-Warning "Could not open file in editor: $($_.Exception.Message)"
        Write-Host "You can manually open: $FilePath" -ForegroundColor Yellow
        return $false
    }
}

function Get-TemplateMetadata {
    <#
    .SYNOPSIS
    Extracts metadata from a template file

    .PARAMETER TemplatePath
    Path to the template file

    .EXAMPLE
    $metadata = Get-TemplateMetadata -TemplatePath "template.md"
    $documentType = $metadata.creates_document_type
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplatePath
    )

    if (-not (Test-Path $TemplatePath)) {
        throw "Template not found: $TemplatePath"
    }

    $templateContent = Get-Content -Path $TemplatePath -Raw -Encoding UTF8

    # Extract the YAML metadata block
    if ($templateContent -match '(?s)^---\r?\n(.*?)\r?\n---') {
        $yamlContent = $matches[1]

        # Parse YAML manually (basic parsing for our structure)
        $metadata = @{}
        $lines = $yamlContent -split '\r?\n'

        foreach ($line in $lines) {
            $line = $line.Trim()

            # Skip empty lines and comments
            if (-not $line -or $line.StartsWith('#')) {
                continue
            }

            # Parse key-value pairs
            if ($line -match '^([^:]+):\s*(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()

                # Remove quotes if present
                if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
                    $value = $matches[1]
                }

                $metadata[$key] = $value
            }
        }

        return $metadata
    } else {
        throw "No metadata block found in template: $TemplatePath"
    }
}

function Get-TemplateContentWithoutMetadata {
    <#
    .SYNOPSIS
    Gets template content without the metadata block

    .PARAMETER TemplatePath
    Path to the template file

    .EXAMPLE
    $content = Get-TemplateContentWithoutMetadata -TemplatePath "template.md"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplatePath
    )

    if (-not (Test-Path $TemplatePath)) {
        throw "Template not found: $TemplatePath"
    }

    $templateContent = Get-Content -Path $TemplatePath -Raw -Encoding UTF8

    # Remove the YAML metadata block
    if ($templateContent -match '(?s)^---\r?\n.*?\r?\n---\r?\n(.*)$') {
        return $matches[1]
    } else {
        # No metadata block, return entire content
        return $templateContent
    }
}

function Invoke-StandardScriptInitialization {
    <#
    .SYNOPSIS
    Performs standard initialization for document creation scripts

    .DESCRIPTION
    Handles common initialization tasks:
    - Module loading
    - Error action preference setting
    - Verbose output setup

    .PARAMETER RequiredModules
    Array of required module names (default: @("IdRegistry"))

    .PARAMETER OptionalModules
    Array of optional module names (default: @("DocumentManagement"))

    .EXAMPLE
    Invoke-StandardScriptInitialization

    .EXAMPLE
    Invoke-StandardScriptInitialization -RequiredModules @("IdRegistry", "CustomModule") -OptionalModules @()
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string[]]$RequiredModules = @("IdRegistry"),

        [Parameter(Mandatory=$false)]
        [string[]]$OptionalModules = @("DocumentManagement")
    )

    # Set error action preference
    $ErrorActionPreference = "Stop"

    # Load required modules
    foreach ($module in $RequiredModules) {
        Import-ProjectModule -ModuleName $module -Required | Out-Null
        Write-Verbose "Loaded required module: $module"
    }

    # Load optional modules
    foreach ($module in $OptionalModules) {
        $loaded = Import-ProjectModule -ModuleName $module
        if ($loaded) {
            Write-Verbose "Loaded optional module: $module"
        } else {
            Write-Verbose "Optional module not available: $module"
        }
    }
}

function New-ProjectDocumentWithMetadata {
    <#
    .SYNOPSIS
    Creates a new document from template with proper metadata handling

    .PARAMETER TemplatePath
    Path to the template file

    .PARAMETER OutputPath
    Path where the document should be created

    .PARAMETER DocumentId
    The document ID (e.g., "PF-TSK-001")

    .PARAMETER Replacements
    Hashtable of string replacements to apply to content

    .PARAMETER AdditionalMetadataFields
    Hashtable of additional metadata fields (will override template defaults)

    .PARAMETER OpenInEditor
    Whether to open the created document in editor

    .EXAMPLE
    $replacements = @{ "[Task Name]" = "User Authentication" }
    $additionalFields = @{ "task_type" = "Discrete" }
    New-ProjectDocumentWithMetadata -TemplatePath "task-template.md" -OutputPath "output.md" -DocumentId "PF-TSK-001" -Replacements $replacements -AdditionalMetadataFields $additionalFields
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplatePath,

        [Parameter(Mandatory=$true)]
        [string]$OutputPath,

        [Parameter(Mandatory=$true)]
        [string]$DocumentId,

        [Parameter(Mandatory=$false)]
        [hashtable]$Replacements = @{},

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalMetadataFields = @{},

        [Parameter(Mandatory=$false)]
        [switch]$OpenInEditor
    )

    try {
        # Get template metadata to determine document structure
        $templateMetadata = Get-TemplateMetadata -TemplatePath $TemplatePath

        # Get template content without template metadata
        $documentContent = Get-TemplateContentWithoutMetadata -TemplatePath $TemplatePath

        # Apply replacements to the content
        foreach ($key in $Replacements.Keys) {
            $documentContent = $documentContent -replace [regex]::Escape($key), $Replacements[$key]
        }

        # Build metadata fields from template metadata
        $metadataFields = @{}

        # Add template-defined additional fields if they exist
        if ($templateMetadata.ContainsKey('additional_fields') -and $templateMetadata['additional_fields'] -is [hashtable]) {
            foreach ($key in $templateMetadata['additional_fields'].Keys) {
                $metadataFields[$key] = $templateMetadata['additional_fields'][$key]
            }
        }

        # Add user-provided additional fields (these override template defaults)
        foreach ($key in $AdditionalMetadataFields.Keys) {
            $metadataFields[$key] = $AdditionalMetadataFields[$key]
        }

        # Create proper document metadata using template information
        $documentType = if ($templateMetadata.ContainsKey('creates_document_type')) { $templateMetadata['creates_document_type'] } else { "Document" }
        $category = if ($templateMetadata.ContainsKey('creates_document_category')) { $templateMetadata['creates_document_category'] } else { "General" }

        $metadata = New-ProjectDocumentMetadata -DocumentId $DocumentId -DocumentType $documentType -Category $category -AdditionalFields $metadataFields

        # Combine metadata with content
        $finalContent = $metadata + $documentContent

        # Ensure output directory exists
        $outputDir = Split-Path -Parent $OutputPath
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        $finalContent | Set-Content -Path $OutputPath -Encoding UTF8 -ErrorAction Stop

        if ($OpenInEditor) {
            Open-ProjectFileInEditor -FilePath $OutputPath
        }

        Write-Verbose "Created document with metadata: $OutputPath"
        return $true
    }
    catch {
        Write-Error "Failed to create document: $($_.Exception.Message)"
        return $false
    }
}

function New-ProjectDocumentWithCodeMetadata {
    <#
    .SYNOPSIS
    Creates a new code document from template with metadata in comments

    .DESCRIPTION
    Similar to New-ProjectDocumentWithMetadata but designed for code files.
    Stores metadata in structured comments instead of YAML frontmatter.

    .PARAMETER TemplatePath
    Path to the template file

    .PARAMETER OutputPath
    Path where the document should be created

    .PARAMETER DocumentId
    The document ID (e.g., "PF-TST-001")

    .PARAMETER Replacements
    Hashtable of string replacements to apply to content

    .PARAMETER AdditionalMetadataFields
    Hashtable of additional metadata fields

    .PARAMETER OpenInEditor
    Whether to open the created document in editor

    .EXAMPLE
    $replacements = @{ "[TEST_NAME]" = "UserAuthentication" }
    $additionalFields = @{ "test_type" = "Unit" }
    New-ProjectDocumentWithCodeMetadata -TemplatePath "test-template.dart" -OutputPath "output.dart" -DocumentId "PF-TST-001" -Replacements $replacements -AdditionalMetadataFields $additionalFields
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplatePath,

        [Parameter(Mandatory=$true)]
        [string]$OutputPath,

        [Parameter(Mandatory=$true)]
        [string]$DocumentId,

        [Parameter(Mandatory=$false)]
        [hashtable]$Replacements = @{},

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalMetadataFields = @{},

        [Parameter(Mandatory=$false)]
        [switch]$OpenInEditor
    )

    try {
        # Get template metadata to determine document structure
        $templateMetadata = Get-TemplateMetadata -TemplatePath $TemplatePath

        # Get template content without template metadata
        $documentContent = Get-TemplateContentWithoutMetadata -TemplatePath $TemplatePath

        # Apply replacements to the content
        foreach ($key in $Replacements.Keys) {
            $documentContent = $documentContent -replace [regex]::Escape($key), $Replacements[$key]
        }

        # Build metadata fields from template metadata
        $metadataFields = @{}

        # Add template-defined additional fields if they exist
        if ($templateMetadata.ContainsKey('additional_fields') -and $templateMetadata['additional_fields'] -is [hashtable]) {
            foreach ($key in $templateMetadata['additional_fields'].Keys) {
                $metadataFields[$key] = $templateMetadata['additional_fields'][$key]
            }
        }

        # Add user-provided additional fields (these override template defaults)
        foreach ($key in $AdditionalMetadataFields.Keys) {
            $metadataFields[$key] = $AdditionalMetadataFields[$key]
        }

        # Create code metadata comment block
        $documentType = if ($templateMetadata.ContainsKey('creates_document_type')) { $templateMetadata['creates_document_type'] } else { "Code File" }
        $category = if ($templateMetadata.ContainsKey('creates_document_category')) { $templateMetadata['creates_document_category'] } else { "General" }

        $metadataComment = New-ProjectCodeMetadata -DocumentId $DocumentId -DocumentType $documentType -Category $category -AdditionalFields $metadataFields

        # Combine metadata comment with content
        $finalContent = $metadataComment + $documentContent

        # Ensure output directory exists
        $outputDir = Split-Path -Parent $OutputPath
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        $finalContent | Set-Content -Path $OutputPath -Encoding UTF8 -ErrorAction Stop

        if ($OpenInEditor) {
            Open-ProjectFileInEditor -FilePath $OutputPath
        }

        Write-Verbose "Created code document with metadata: $OutputPath"
        return $true
    }
    catch {
        Write-ProjectError -Message "Failed to create code document: $($_.Exception.Message)"
        return $false
    }
}

function New-ProjectCodeMetadata {
    <#
    .SYNOPSIS
    Creates metadata comment block for code files

    .DESCRIPTION
    Generates structured comment block containing document metadata
    for code files that cannot use YAML frontmatter

    .PARAMETER DocumentId
    The document ID (e.g., "PF-TST-001")

    .PARAMETER DocumentType
    Type of document (e.g., "Test File", "Component")

    .PARAMETER Category
    Document category (e.g., "Unit", "Integration")

    .PARAMETER AdditionalFields
    Hashtable of additional metadata fields

    .EXAMPLE
    New-ProjectCodeMetadata -DocumentId "PF-TST-001" -DocumentType "Test File" -Category "Unit" -AdditionalFields @{"test_name"="UserAuth"}
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DocumentId,

        [Parameter(Mandatory=$true)]
        [string]$DocumentType,

        [Parameter(Mandatory=$true)]
        [string]$Category,

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalFields = @{}
    )

    $timestamp = Get-ProjectTimestamp -Format "Date"

    $metadataLines = @(
        "/*",
        " * Document Metadata:",
        " * ID: $DocumentId",
        " * Type: $DocumentType",
        " * Category: $Category",
        " * Version: 1.0",
        " * Created: $timestamp",
        " * Updated: $timestamp"
    )

    # Add additional fields
    foreach ($key in $AdditionalFields.Keys) {
        $value = $AdditionalFields[$key]
        $formattedKey = ($key -split '_' | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) }) -join ' '
        $metadataLines += " * $formattedKey`: $value"
    }

    $metadataLines += @(
        " */",
        ""
    )

    return ($metadataLines -join "`n")
}

function New-StandardProjectDocument {
    <#
    .SYNOPSIS
    Creates a new project document using fully standardized process

    .DESCRIPTION
    This is the primary function for creating new documents from templates.
    It handles all aspects of document creation including:
    - ID generation and validation
    - Template processing with metadata
    - File path generation and conflict handling
    - Directory creation
    - Success/error reporting
    - Editor opening

    .PARAMETER TemplatePath
    Path to the template file (relative to project root or absolute)

    .PARAMETER IdPrefix
    The ID prefix for the document (e.g., "PF-TSK", "ART-FEE")

    .PARAMETER IdDescription
    Description for the ID registry

    .PARAMETER DocumentName
    Human-readable name for the document (used in filename and replacements)

    .PARAMETER OutputDirectory
    Directory where the document should be created (can be relative or absolute)

    .PARAMETER DirectoryType
    Semantic directory type for ID-based directory resolution (optional)

    .PARAMETER Replacements
    Hashtable of additional string replacements to apply

    .PARAMETER AdditionalMetadataFields
    Hashtable of additional metadata fields

    .PARAMETER ConflictAction
    Action to take if file exists: Error, Overwrite, or Skip

    .PARAMETER OpenInEditor
    Whether to open the created document in editor

    .PARAMETER FileNamePattern
    Custom filename pattern (default: uses kebab-case of DocumentName)

    .EXAMPLE
    New-StandardProjectDocument -TemplatePath "templates/task-template.md" -IdPrefix "PF-TSK" -IdDescription "Bug fixing task" -DocumentName "Fix Login Issue" -OutputDirectory "tasks/discrete"

    .EXAMPLE
    $additionalFields = @{ "task_type" = "Discrete" }
    $replacements = @{ "[PRIORITY]" = "High" }
    New-StandardProjectDocument -TemplatePath "templates/task-template.md" -IdPrefix "PF-TSK" -IdDescription "Critical bug fix" -DocumentName "Fix Authentication" -DirectoryType "discrete" -AdditionalMetadataFields $additionalFields -Replacements $replacements -OpenInEditor
    #>

    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplatePath,

        [Parameter(Mandatory=$true)]
        [string]$IdPrefix,

        [Parameter(Mandatory=$true)]
        [string]$IdDescription,

        [Parameter(Mandatory=$true)]
        [string]$DocumentName,

        [Parameter(Mandatory=$false)]
        [string]$OutputDirectory,

        [Parameter(Mandatory=$false)]
        [string]$DirectoryType,

        [Parameter(Mandatory=$false)]
        [hashtable]$Replacements = @{},

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalMetadataFields = @{},

        [Parameter(Mandatory=$false)]
        [ValidateSet("Error", "Overwrite", "Skip")]
        [string]$ConflictAction = "Error",

        [Parameter(Mandatory=$false)]
        [switch]$OpenInEditor,

        [Parameter(Mandatory=$false)]
        [string]$FileNamePattern
    )

    try {
        # Generate document ID
        $documentId = New-ProjectId -Prefix $IdPrefix -Description $IdDescription
        Write-Verbose "Generated document ID: $documentId"

        # Resolve output directory
        if ($DirectoryType) {
            $resolvedOutputDir = Get-ProjectIdDirectory -Prefix $IdPrefix -DirectoryType $DirectoryType -CreateIfMissing
        } elseif ($OutputDirectory) {
            if (-not [System.IO.Path]::IsPathRooted($OutputDirectory)) {
                $projectRoot = Get-ProjectRoot
                $resolvedOutputDir = Join-Path -Path $projectRoot -ChildPath $OutputDirectory
            } else {
                $resolvedOutputDir = $OutputDirectory
            }
            Test-ProjectPath -Path $resolvedOutputDir -CreateIfMissing -PathType Directory | Out-Null
        } else {
            # Use default directory for prefix
            $resolvedOutputDir = Get-ProjectIdDirectory -Prefix $IdPrefix -CreateIfMissing
        }

        # Determine file extension based on template
        $templateExtension = [System.IO.Path]::GetExtension($TemplatePath)

        # Generate filename
        if ($FileNamePattern) {
            $fileName = $FileNamePattern
        } else {
            $kebabName = ConvertTo-KebabCase -InputString $DocumentName
            if ($templateExtension -eq ".dart") {
                $fileName = "${kebabName}_test.dart"
            } elseif ($templateExtension -ne ".md") {
                $fileName = "$kebabName$templateExtension"
            } else {
                $fileName = "$kebabName.md"
            }
        }

        $outputPath = Join-Path -Path $resolvedOutputDir -ChildPath $fileName

        # Check for file conflicts
        $canProceed = Test-ProjectFileConflict -FilePath $outputPath -ConflictAction $ConflictAction -ErrorMessage "Document already exists"

        if (-not $canProceed) {
            Write-ProjectSuccess -Message "Skipped existing document" -Details @("Path: $outputPath")
            return $false
        }

        # Resolve template path
        if (-not [System.IO.Path]::IsPathRooted($TemplatePath)) {
            $projectRoot = Get-ProjectRoot
            $resolvedTemplatePath = Join-Path -Path $projectRoot -ChildPath $TemplatePath
        } else {
            $resolvedTemplatePath = $TemplatePath
        }

        # Add standard replacements
        $standardReplacements = @{
            "[DOCUMENT_NAME]" = $DocumentName
            "[Document Name]" = $DocumentName
            "[DOCUMENT_ID]" = $documentId
            "[DATE]" = Get-ProjectTimestamp -Format "Date"
            "[TIMESTAMP]" = Get-ProjectTimestamp -Format "DateTime"
        }

        # Merge with user-provided replacements (user replacements take precedence)
        $finalReplacements = $standardReplacements.Clone()
        foreach ($key in $Replacements.Keys) {
            $finalReplacements[$key] = $Replacements[$key]
        }

        # Create the document using appropriate handler based on template type
        if ($PSCmdlet.ShouldProcess("Create document at $outputPath")) {
            if ($templateExtension -eq ".md") {
                # Use existing markdown handler
                $result = New-ProjectDocumentWithMetadata -TemplatePath $resolvedTemplatePath -OutputPath $outputPath -DocumentId $documentId -Replacements $finalReplacements -AdditionalMetadataFields $AdditionalMetadataFields -OpenInEditor:$OpenInEditor
            } else {
                # Use new code file handler for non-markdown files
                $result = New-ProjectDocumentWithCodeMetadata -TemplatePath $resolvedTemplatePath -OutputPath $outputPath -DocumentId $documentId -Replacements $finalReplacements -AdditionalMetadataFields $AdditionalMetadataFields -OpenInEditor:$OpenInEditor
            }

            if ($result) {
                $details = @(
                    "ID: $documentId",
                    "Path: $outputPath"
                )

                if ($AdditionalMetadataFields.Count -gt 0) {
                    $details += "Metadata: $($AdditionalMetadataFields.Keys -join ', ')"
                }

                Write-ProjectSuccess -Message "Created document: $DocumentName" -Details $details
                return $documentId
            } else {
                throw "Document creation failed"
            }
        }
    }
    catch {
        Write-ProjectError -Message "Failed to create document '$DocumentName': $($_.Exception.Message)" -ExitCode 1
    }
}
# For now, focusing on the core functions to establish the modular structure.

# Export functions
Export-ModuleMember -Function @(
    'New-ProjectDocumentMetadata',
    'Open-ProjectFileInEditor',
    'Get-TemplateMetadata',
    'Get-TemplateContentWithoutMetadata',
    'Invoke-StandardScriptInitialization',
    'New-ProjectDocumentWithMetadata',
    'New-ProjectDocumentWithCodeMetadata',
    'New-ProjectCodeMetadata',
    'New-StandardProjectDocument'
)
