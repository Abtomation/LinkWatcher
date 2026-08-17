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
$coreModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers/Core.psm1"
$outputModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers/OutputFormatting.psm1"
$idRegistryModule = Join-Path -Path $scriptPath -ChildPath "IdRegistry.psm1"
$fileOpsModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers/FileOperations.psm1"
$execVerifyModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers/ExecutionVerification.psm1"

if (Test-Path $coreModule) { Import-Module $coreModule -Force }
if (Test-Path $outputModule) { Import-Module $outputModule -Force }
if (Test-Path $idRegistryModule) { Import-Module $idRegistryModule -Force }
if (Test-Path $fileOpsModule) { Import-Module $fileOpsModule -Force }
if (Test-Path $execVerifyModule) { Import-Module $execVerifyModule -Force }

# Template-link-depth rewrite (PF-PRO-066 / PF-IMP-1942) — PILOT SCOPE.
# A template's relative links are authored to resolve from the template's own
# directory. When an instance is materialized at a different depth the link text
# travels verbatim and stops resolving. Convert-TemplateLinkDepth fixes that at
# write time; this list limits it to the pilot's adopter templates.
#
# ROLL-FORWARD: when the pilot resolves successfully, delete this list and the
# two `if ($script:LinkDepthPilotTemplates -contains ...)` guards at the call
# sites — the helper then applies to every materialized document. No other
# change is needed, and no creation script is affected either way.
$script:LinkDepthPilotTemplates = @(
    'feature-implementation-state-template.md',              # New-FeatureImplementationState.ps1 — the confirmed-broken path
    'feature-implementation-state-lightweight-template.md',  #   "  (Tier 1 variant of the same creator)
    'tdd-t1-template.md',                                    # New-TDD.ps1 — proves the design-artifact pipeline entry point
    'tdd-t2-template.md',
    'tdd-t3-template.md',
    'task-template.md'                                       # New-Task.ps1 — same-depth case, proves the rewrite is a no-op
)

function New-ProjectDocumentMetadata {
    <#
    .SYNOPSIS
    Creates standardized document metadata blocks

    .PARAMETER DocumentId
    The document ID (e.g., "PF-TSK-001")

    .PARAMETER DocumentType
    The type of document (e.g., "Task Definition", "Technical Design Document")

    .PARAMETER Category
    The document category (e.g., "TDD Tier 1", "Task Definition")

    .PARAMETER Version
    Document version (default: "1.0")

    .PARAMETER AdditionalFields
    Hashtable of additional metadata fields

    .EXAMPLE
    $metadata = New-ProjectDocumentMetadata -DocumentId "PF-TSK-001" -DocumentType "Task Definition" -Category "Task Definition"

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

    # Add additional fields (sorted for deterministic frontmatter ordering — .NET randomizes
    # string hashing per process, so unsorted Hashtable enumeration emitted fields in a
    # non-deterministic order across runs; sorting makes created documents reproducible.
    # BD-001 / PF-IMP-1135.)
    #
    # String values pass through ConvertTo-YamlSafeScalar, which quotes only what a plain
    # scalar would mis-parse (colon-space, leading indicator, embedded newline …) and leaves
    # an already-quoted scalar untouched — so free text a caller passes raw can no longer emit
    # invalid YAML, and callers that pre-quote stay byte-identical (PF-IMP-1413). Non-string
    # values are emitted as before.
    foreach ($key in ($AdditionalFields.Keys | Sort-Object)) {
        $value = $AdditionalFields[$key]
        if ($value -is [string]) { $value = ConvertTo-YamlSafeScalar -Value $value }
        $metadata += "`n$key`: $value"
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
    Extracts YAML frontmatter metadata from a template file.

    .DESCRIPTION
    Parses the YAML block between --- delimiters at the top of a template file.
    Uses the powershell-yaml module (ConvertFrom-Yaml) for full YAML support
    including nested structures, arrays, and quoted values.

    Requires: powershell-yaml module (Install-Module powershell-yaml -Scope CurrentUser)

    .PARAMETER TemplatePath
    Path to the template file

    .EXAMPLE
    $metadata = Get-TemplateMetadata -TemplatePath "template.md"
    $documentType = $metadata.creates_document_type
    $additionalFields = $metadata.additional_fields  # returns hashtable
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplatePath
    )

    # Ensure powershell-yaml is available
    if (-not (Get-Module -ListAvailable powershell-yaml)) {
        throw "Required module 'powershell-yaml' is not installed. Run: Install-Module powershell-yaml -Scope CurrentUser"
    }
    Import-Module powershell-yaml -ErrorAction Stop

    if (-not (Test-Path $TemplatePath)) {
        throw "Template not found: $TemplatePath"
    }

    $templateContent = Get-Content -Path $TemplatePath -Raw -Encoding UTF8

    # Extract the YAML metadata block
    if ($templateContent -match '(?s)^---\r?\n(.*?)\r?\n---') {
        $yamlContent = $matches[1]
        $metadata = $yamlContent | ConvertFrom-Yaml
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

function Convert-TemplateLinkDepth {
    <#
    .SYNOPSIS
    Rewrites a materialized document's template-inherited relative links so they resolve from the document's own directory.

    .DESCRIPTION
    A framework template lives at a fixed depth (process-framework/templates/<category>/) and its
    relative markdown links are authored to resolve from there. A creation script materializes the
    instance somewhere else, so the link text travels verbatim while the depth changes and every
    inherited link stops resolving (PF-PRO-066 / PF-IMP-1942).

    This function recomputes each such link against the OUTPUT directory. It is deliberately
    conservative — the failure mode it must never produce is a confidently-wrong link, which is
    harder to notice than a broken one:

    - EXISTENCE-GATED. A link is rewritten only when its template-relative target actually resolves
      to something on disk. A target that resolves nowhere (placeholder tokens such as [feature-id]
      or X.Y.Z, or a stale authoring defect) is left exactly as authored. A shape-based variant that
      rewrote anything under a known tree root was prototyped and rejected: it mangled three real
      links into paths under process-framework/templates/specifications/, which does not exist.
    - FENCE-AWARE. Links inside ``` code fences are example syntax, not navigation, and are skipped.
    - SCOPE-GATED. If the template or the output path falls outside the project root — the
      central-materialization case, where resolution runs through .framework-central-pointer rather
      than relative arithmetic — the content is returned unchanged.
    - NO-OP BY CONSTRUCTION for depth-preserving materialization: when the output directory sits at
      the same depth as the template, the recomputed path equals the original text.

    Only '](../...)' links are considered. Root-absolute and bare same-directory links are untouched.

    .PARAMETER Content
    The fully-assembled document content (metadata block plus body), immediately before it is written.

    .PARAMETER TemplatePath
    Path to the source template — the frame the existing links were authored against.

    .PARAMETER OutputPath
    Path the document is being written to. Its directory is the new resolution frame.

    .PARAMETER ProjectRoot
    Optional explicit project root. Defaults to Get-ProjectRoot. Supplying it keeps the function
    pure for unit tests.

    .OUTPUTS
    The content with inherited link depths corrected. On any resolution failure the input content is
    returned unchanged — a link rewrite must never be able to fail a document creation.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$TemplatePath,

        [Parameter(Mandatory=$true)]
        [string]$OutputPath,

        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot
    )

    if ([string]::IsNullOrEmpty($Content)) { return $Content }

    try {
        if (-not $ProjectRoot) { $ProjectRoot = Get-ProjectRoot }
        if (-not $ProjectRoot) {
            Write-Verbose "Convert-TemplateLinkDepth: project root unresolved — leaving links unchanged."
            return $Content
        }

        # Callers mix both forms: the creation core passes ABSOLUTE paths, while task
        # documentation and tests use project-root-relative ones. Joining an already-rooted
        # path onto the root yields garbage, so branch on IsPathRooted rather than assuming.
        $rootFull = [System.IO.Path]::GetFullPath($ProjectRoot)
        $toFull = {
            param([string]$p)
            if ([System.IO.Path]::IsPathRooted($p)) { [System.IO.Path]::GetFullPath($p) }
            else { [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $p)) }
        }
        $templateFull = & $toFull $TemplatePath
        $outputFull   = & $toFull $OutputPath
        $templateDir  = Split-Path -Parent $templateFull
        $outputDir    = Split-Path -Parent $outputFull

        # Scope gate: both frames must sit inside the project root, else relative
        # arithmetic is not the right resolution model (central materialization).
        foreach ($dir in @($templateDir, $outputDir)) {
            if (-not $dir.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
                Write-Verbose "Convert-TemplateLinkDepth: '$dir' is outside the project root — leaving links unchanged."
                return $Content
            }
        }

        $stats    = @{ Rewritten = 0; Left = 0 }
        $pattern  = '(\]\()(\.\./[^)\s]*?)(\))'
        $inFence  = $false
        $outLines = [System.Collections.Generic.List[string]]::new()

        # Preserve the input's line-ending style. Splitting on `r?`n and re-joining with a
        # bare `n would silently convert a CRLF document to LF — an invisible whole-file
        # diff on every pilot-created document, which is exactly the kind of unintended
        # mutation this helper is supposed to avoid.
        $newline = if ($Content -match "`r`n") { "`r`n" } else { "`n" }

        foreach ($line in ($Content -split "`r?`n")) {
            if ($line.TrimStart().StartsWith('```')) {
                $inFence = -not $inFence
                $outLines.Add($line)
                continue
            }
            if ($inFence -or $line -notmatch '\]\(\.\./') {
                $outLines.Add($line)
                continue
            }

            $evaluator = {
                param($m)
                $target = $m.Groups[2].Value
                $split  = $target.IndexOf('#')
                $path   = if ($split -ge 0) { $target.Substring(0, $split) } else { $target }
                $anchor = if ($split -ge 0) { $target.Substring($split) }    else { '' }
                if ([string]::IsNullOrWhiteSpace($path)) { return $m.Value }

                $resolved = [System.IO.Path]::GetFullPath((Join-Path $templateDir $path))
                if (-not (Test-Path -LiteralPath $resolved)) {
                    $stats.Left++
                    return $m.Value          # unresolvable at the template — never guess
                }

                $rebased = [System.IO.Path]::GetRelativePath($outputDir, $resolved) -replace '\\', '/'
                if ($rebased -eq $path) { return $m.Value }
                $stats.Rewritten++
                return $m.Groups[1].Value + $rebased + $anchor + $m.Groups[3].Value
            }

            $outLines.Add([regex]::Replace($line, $pattern, [System.Text.RegularExpressions.MatchEvaluator]$evaluator))
        }

        if ($stats.Rewritten -gt 0 -or $stats.Left -gt 0) {
            Write-Verbose ("Convert-TemplateLinkDepth: rewrote {0} inherited link(s), left {1} unresolvable link(s) unchanged ({2})." -f `
                $stats.Rewritten, $stats.Left, (Split-Path $OutputPath -Leaf))
        }

        return ($outLines -join $newline)
    }
    catch {
        # A link rewrite is a convenience, never a gate on document creation.
        Write-Warning "Convert-TemplateLinkDepth: link rewrite skipped ($($_.Exception.Message)). Document written with template-relative links."
        return $Content
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
    New-ProjectDocumentWithMetadata -TemplatePath "task-template.md" -OutputPath "output.md" -DocumentId "PF-TSK-001" -Replacements $replacements
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
        # WhatIf short-circuit: caller is in preview mode — skip write + assert, return $true
        # to match pre-armoring behavior (silent success rather than loud Assert failure when
        # Set-Content honors WhatIf and writes nothing). Caller-aware via $PSCmdlet.SessionState.
        if ([bool]$PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')) {
            Write-Verbose "New-ProjectDocumentWithMetadata: WhatIf mode — skipping document creation."
            return $true
        }

        # Get template metadata to determine document structure
        $templateMetadata = Get-TemplateMetadata -TemplatePath $TemplatePath

        # Get template content without template metadata
        $documentContent = Get-TemplateContentWithoutMetadata -TemplatePath $TemplatePath

        # Apply replacements to the content
        # IMPORTANT: Keys are auto-escaped via [regex]::Escape() before being used in -replace.
        # This means replacement keys must use LITERAL brackets, e.g.:
        #   CORRECT: "[Feature Name]" = $FeatureName
        #   WRONG:   "/[Feature Name/]" = $FeatureName  (double-escaping, will silently fail)
        foreach ($key in $Replacements.Keys) {
            if ($key -match '\\\[|\\\]') {
                Write-Warning "Replacement key '$key' contains escaped brackets. Keys are auto-escaped — use literal brackets (e.g., '[Feature Name]' not '/[Feature Name/]')."
            }
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
        $templateName = Split-Path $TemplatePath -Leaf
        $documentType = if ($templateMetadata.ContainsKey('creates_document_type')) { $templateMetadata['creates_document_type'] } else {
            Write-Warning "Template '$templateName' declares no creates_document_type — falling back to type 'Document'. Declare creates_document_type in the template frontmatter."
            "Document"
        }
        $category = if ($templateMetadata.ContainsKey('creates_document_category')) { $templateMetadata['creates_document_category'] } else {
            Write-Warning "Template '$templateName' declares no creates_document_category — falling back to category 'General'. Declare creates_document_category in the template frontmatter."
            "General"
        }

        $metadata = New-ProjectDocumentMetadata -DocumentId $DocumentId -DocumentType $documentType -Category $category -AdditionalFields $metadataFields

        # Combine metadata with content
        $finalContent = $metadata + $documentContent

        # Correct template-inherited link depth for the instance's own location
        # (PF-PRO-066 / PF-IMP-1942). Pilot-gated — see $script:LinkDepthPilotTemplates.
        if ($script:LinkDepthPilotTemplates -contains $templateName) {
            $finalContent = Convert-TemplateLinkDepth -Content $finalContent -TemplatePath $TemplatePath -OutputPath $OutputPath
        }

        # Ensure output directory exists
        $outputDir = Split-Path -Parent $OutputPath
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        # Soak: hash-detection auto-reset side effect (PF-PRO-028 v2.0 Pattern B caller-aware mode).
        # Defensively wrapped so soak-side errors never mask the helper's actual outcome.
        try { $null = Test-ScriptInSoak } catch { Write-Verbose "Test-ScriptInSoak soft-fail: $($_.Exception.Message)" }

        $finalContent | Set-Content -Path $OutputPath -Encoding UTF8 -ErrorAction Stop

        # Read-after-write: verify the document metadata actually landed.
        Assert-LineInFile -Path $OutputPath -Pattern ([regex]::Escape("id: $DocumentId")) -Context "New-ProjectDocumentWithMetadata($OutputPath)"

        if ($OpenInEditor) {
            Open-ProjectFileInEditor -FilePath $OutputPath
        }

        # Soak: success outcome (caller-aware — no-op if caller not registered).
        try { Confirm-SoakInvocation -Outcome success } catch { Write-Verbose "Confirm-SoakInvocation success soft-fail: $($_.Exception.Message)" }

        Write-Verbose "Created document with metadata: $OutputPath"
        return $true
    }
    catch {
        $errMsg = $_.Exception.Message
        try {
            $truncated = if ($errMsg.Length -gt 200) { $errMsg.Substring(0, 200) + "..." } else { $errMsg }
            Confirm-SoakInvocation -Outcome failure -Notes "New-ProjectDocumentWithMetadata: $truncated"
        } catch { Write-Verbose "Confirm-SoakInvocation failure soft-fail: $($_.Exception.Message)" }
        Write-Error "Failed to create document: $errMsg"
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

    .PARAMETER HeaderComment
    Optional comment-style hashtable forwarded to New-ProjectCodeMetadata
    (keys: open, close, linePrefix). Source: language config's headerComment field.

    .EXAMPLE
    $replacements = @{ "[TEST_NAME]" = "UserAuthentication" }
    $additionalFields = @{ "test_type" = "Unit" }
    New-ProjectDocumentWithCodeMetadata -TemplatePath "test-template.py" -OutputPath "output.py" -DocumentId "PF-TST-001" -Replacements $replacements -AdditionalMetadataFields $additionalFields
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
        [switch]$OpenInEditor,

        [Parameter(Mandatory=$false)]
        [hashtable]$HeaderComment
    )

    try {
        # WhatIf short-circuit: caller is in preview mode — skip write + assert, return $true
        # to match pre-armoring behavior (silent success rather than loud Assert failure when
        # Set-Content honors WhatIf and writes nothing). Caller-aware via $PSCmdlet.SessionState.
        if ([bool]$PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')) {
            Write-Verbose "New-ProjectDocumentWithCodeMetadata: WhatIf mode — skipping document creation."
            return $true
        }

        # Get template metadata to determine document structure
        $templateMetadata = Get-TemplateMetadata -TemplatePath $TemplatePath

        # Get template content without template metadata
        $documentContent = Get-TemplateContentWithoutMetadata -TemplatePath $TemplatePath

        # Apply replacements to the content
        # IMPORTANT: Keys are auto-escaped via [regex]::Escape() before being used in -replace.
        # This means replacement keys must use LITERAL brackets, e.g.:
        #   CORRECT: "[Feature Name]" = $FeatureName
        #   WRONG:   "/[Feature Name/]" = $FeatureName  (double-escaping, will silently fail)
        foreach ($key in $Replacements.Keys) {
            if ($key -match '\\\[|\\\]') {
                Write-Warning "Replacement key '$key' contains escaped brackets. Keys are auto-escaped — use literal brackets (e.g., '[Feature Name]' not '/[Feature Name/]')."
            }
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
        $templateName = Split-Path $TemplatePath -Leaf
        $documentType = if ($templateMetadata.ContainsKey('creates_document_type')) { $templateMetadata['creates_document_type'] } else {
            Write-Warning "Template '$templateName' declares no creates_document_type — falling back to type 'Code File'. Declare creates_document_type in the template frontmatter."
            "Code File"
        }
        $category = if ($templateMetadata.ContainsKey('creates_document_category')) { $templateMetadata['creates_document_category'] } else {
            Write-Warning "Template '$templateName' declares no creates_document_category — falling back to category 'General'. Declare creates_document_category in the template frontmatter."
            "General"
        }

        $metadataComment = New-ProjectCodeMetadata -DocumentId $DocumentId -DocumentType $documentType -Category $category -AdditionalFields $metadataFields -HeaderComment $HeaderComment

        # Combine metadata comment with content
        $finalContent = $metadataComment + $documentContent

        # Correct template-inherited link depth for the instance's own location
        # (PF-PRO-066 / PF-IMP-1942). Pilot-gated — see $script:LinkDepthPilotTemplates.
        # Code templates carry links in comment blocks; the same arithmetic applies.
        if ($script:LinkDepthPilotTemplates -contains $templateName) {
            $finalContent = Convert-TemplateLinkDepth -Content $finalContent -TemplatePath $TemplatePath -OutputPath $OutputPath
        }

        # Ensure output directory exists
        $outputDir = Split-Path -Parent $OutputPath
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        # Soak: hash-detection auto-reset side effect (PF-PRO-028 v2.0 Pattern B caller-aware mode).
        try { $null = Test-ScriptInSoak } catch { Write-Verbose "Test-ScriptInSoak soft-fail: $($_.Exception.Message)" }

        $finalContent | Set-Content -Path $OutputPath -Encoding UTF8 -ErrorAction Stop

        # Read-after-write: verify the document ID actually landed in the metadata comment block.
        Assert-LineInFile -Path $OutputPath -Pattern ([regex]::Escape($DocumentId)) -Context "New-ProjectDocumentWithCodeMetadata($OutputPath)"

        if ($OpenInEditor) {
            Open-ProjectFileInEditor -FilePath $OutputPath
        }

        # Soak: success outcome (caller-aware — no-op if caller not registered).
        try { Confirm-SoakInvocation -Outcome success } catch { Write-Verbose "Confirm-SoakInvocation success soft-fail: $($_.Exception.Message)" }

        Write-Verbose "Created code document with metadata: $OutputPath"
        return $true
    }
    catch {
        $errMsg = $_.Exception.Message
        try {
            $truncated = if ($errMsg.Length -gt 200) { $errMsg.Substring(0, 200) + "..." } else { $errMsg }
            Confirm-SoakInvocation -Outcome failure -Notes "New-ProjectDocumentWithCodeMetadata: $truncated"
        } catch { Write-Verbose "Confirm-SoakInvocation failure soft-fail: $($_.Exception.Message)" }
        Write-ProjectError -Message "Failed to create code document: $errMsg"
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

    .PARAMETER HeaderComment
    Optional hashtable describing the comment style for the target language. Keys:
    'open' (block-comment opener), 'close' (block-comment closer), 'linePrefix'
    (prepended to each metadata line). When omitted, defaults to C-family
    /* ... */ block comment with " * " line prefix (backward compatible).
    Source: process-framework/languages-config/{language}/{language}-config.json -> headerComment.

    .EXAMPLE
    New-ProjectCodeMetadata -DocumentId "PF-TST-001" -DocumentType "Test File" -Category "Unit" -AdditionalFields @{"test_name"="UserAuth"}

    .EXAMPLE
    # Python docstring header
    $py = @{ open = '"""'; close = '"""'; linePrefix = '' }
    New-ProjectCodeMetadata -DocumentId "TE-TST-001" -DocumentType "Test File" -Category "Test" -AdditionalFields @{"test_name"="UserAuth"} -HeaderComment $py
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
        [hashtable]$AdditionalFields = @{},

        [Parameter(Mandatory=$false)]
        [hashtable]$HeaderComment
    )

    $timestamp = Get-ProjectTimestamp -Format "Date"

    # Resolve comment style: caller-provided HeaderComment, or fall back to C-family
    if ($HeaderComment) {
        $open = $HeaderComment['open']
        $close = $HeaderComment['close']
        $prefix = if ($HeaderComment.ContainsKey('linePrefix')) { $HeaderComment['linePrefix'] } else { '' }
    } else {
        $open = '/*'
        $close = ' */'
        $prefix = ' * '
    }

    $metadataLines = @(
        $open,
        "${prefix}Document Metadata:",
        "${prefix}ID: $DocumentId",
        "${prefix}Type: $DocumentType",
        "${prefix}Category: $Category",
        "${prefix}Version: 1.0",
        "${prefix}Created: $timestamp",
        "${prefix}Updated: $timestamp"
    )

    # Add additional fields (sorted for deterministic ordering across processes — see the
    # matching note in New-ProjectDocumentMetadata; BD-001 / PF-IMP-1135).
    foreach ($key in ($AdditionalFields.Keys | Sort-Object)) {
        $value = $AdditionalFields[$key]
        $formattedKey = ($key -split '_' | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) }) -join ' '
        $metadataLines += "${prefix}${formattedKey}: $value"
    }

    $metadataLines += @(
        $close,
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
    The ID prefix for the document (e.g., "PF-TSK", "PF-FEE")

    .PARAMETER IdDescription
    Description for the ID registry

    .PARAMETER DocumentName
    Human-readable name for the document (used in filename and replacements)

    .PARAMETER OutputDirectory
    Directory where the document should be created (can be relative or absolute)

    .PARAMETER DirectoryType
    Semantic directory type for ID-based directory resolution (optional)

    .PARAMETER Subdirectory
    Optional Layer 1 (L1) subdirectory to append to the resolved output directory.
    Represents content type in the faceted documentation taxonomy (e.g., Diataxis
    content types: tutorials, how-to, reference, explanation).

    When the registry entry for -IdPrefix declares a `subdirectories.values` array,
    the value is validated against that array. When the field is absent or empty,
    any value is accepted (backward compatible with IMP-568 behavior).

    Works with both -DirectoryType (appended to registry-resolved path) and
    -OutputDirectory (appended to explicit path). The subdirectory is created
    automatically if it does not exist.

    .PARAMETER Topic
    Optional Layer 2 (L2) subdirectory appended after -Subdirectory. Represents
    the project-specific topic/domain area in the faceted documentation taxonomy.

    When the registry entry for -IdPrefix declares a non-empty `topics.values` array,
    the value is validated against that array. When the field is absent or empty,
    any value is accepted (projects that haven't declared L2 can skip this parameter).

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
    $replacements = @{ "[PRIORITY]" = "High" }
    New-StandardProjectDocument -TemplatePath "templates/task-template.md" -IdPrefix "PF-TSK" -IdDescription "Critical bug fix" -DocumentName "Fix Authentication" -DirectoryType "discrete" -Replacements $replacements -OpenInEditor

    .EXAMPLE
    New-StandardProjectDocument -TemplatePath "templates/handbook-template.md" -IdPrefix "PD-UGD" -IdDescription "How-to guide" -DocumentName "Configure Logging" -DirectoryType "handbooks" -Subdirectory "how-to"
    # Creates file in doc/user/handbooks/how-to/configure-logging.md
    # Subdirectory validated against PD-UGD.subdirectories.values (Diataxis content types)

    .EXAMPLE
    New-StandardProjectDocument -TemplatePath "templates/handbook-template.md" -IdPrefix "PD-UGD" -IdDescription "Reference" -DocumentName "Networking API" -DirectoryType "handbooks" -Subdirectory "reference" -Topic "networking"
    # Creates file in doc/user/handbooks/reference/networking/networking-api.md
    # Topic validated against PD-UGD.topics.values (project-declared)

    .OUTPUTS
    On success, a [pscustomobject] with Id (assigned document ID), Path (absolute path of the
    created file), and RelativePath (project-root-relative, forward slashes) — so callers never
    re-derive the filename from the writer's internal logic (PF-IMP-1678). Returns $false when
    -ConflictAction Skip skips an existing file; returns nothing under -WhatIf.
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
        [string]$Subdirectory,

        [Parameter(Mandatory=$false)]
        [string]$Topic,

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
        [string]$FileNamePattern,

        [Parameter(Mandatory=$false)]
        [hashtable]$HeaderComment
    )

    # Propagate WhatIf preference across module boundaries (PF-IMP-939: shared helper).
    # Module functions have their own session state and don't inherit the caller's
    # $WhatIfPreference, so Get-EffectiveWhatIf walks the call stack for an explicit
    # -WhatIf in any caller. -WhatIfBound preserves an explicit -WhatIf:$false bound on
    # this call (e.g. from Invoke-DesignArtifactCreation) against an ancestor's -WhatIf:$true.
    $WhatIfPreference = Get-EffectiveWhatIf -WhatIfPreference $WhatIfPreference `
        -WhatIfBound:$PSBoundParameters.ContainsKey('WhatIf')

    # Creating the output directory is a REAL side effect on disk, and directory
    # resolution below runs BEFORE the ShouldProcess gate (it has to — the gate's own
    # message names the resolved output path). So the -CreateIfMissing switches are
    # bound to this flag rather than being always-on: under -WhatIf the resolvers still
    # return the path, and nothing is created. Without this, a preview run leaves a
    # stray empty directory behind — which is how an untracked instruction-design
    # directory appeared in appdev during PF-TSK-026 Session 3.
    $createDirs = -not $WhatIfPreference

    try {
        # Resolve output directory (does not require document ID)
        if ($DirectoryType) {
            $resolvedOutputDir = Get-ProjectIdDirectory -Prefix $IdPrefix -DirectoryType $DirectoryType -CreateIfMissing:$createDirs
        } elseif ($OutputDirectory) {
            if (-not [System.IO.Path]::IsPathRooted($OutputDirectory)) {
                $projectRoot = Get-ProjectRoot
                $resolvedOutputDir = Join-Path -Path $projectRoot -ChildPath $OutputDirectory
            } else {
                $resolvedOutputDir = $OutputDirectory
            }
            Test-ProjectPath -Path $resolvedOutputDir -CreateIfMissing:$createDirs -PathType Directory | Out-Null
        } else {
            # Use default directory for prefix
            $resolvedOutputDir = Get-ProjectIdDirectory -Prefix $IdPrefix -CreateIfMissing:$createDirs
        }

        # Append optional subdirectory (IMP-568: generic subdirectory support)
        # IMP-571: Faceted documentation taxonomy validation
        # - L1 (Subdirectory): Diataxis content type, validated against registry `subdirectories.values`
        # - L2 (Topic): Project-specific topic, validated against registry `topics.values`
        # Validation only applies when the registry declares the values; otherwise backward-compatible passthrough.
        if ($Subdirectory -or $Topic) {
            $prefixInfo = $null
            try { $prefixInfo = Get-PrefixInfo -Prefix $IdPrefix } catch { $prefixInfo = $null }

            if ($Subdirectory) {
                if ($prefixInfo -and $prefixInfo.subdirectories -and $prefixInfo.subdirectories.values) {
                    $validValues = @($prefixInfo.subdirectories.values)
                    if ($validValues.Count -gt 0 -and $validValues -notcontains $Subdirectory) {
                        throw "Invalid -Subdirectory '$Subdirectory' for prefix '$IdPrefix'. Valid values: $($validValues -join ', ')"
                    }
                }
                $resolvedOutputDir = Join-Path -Path $resolvedOutputDir -ChildPath $Subdirectory
                Test-ProjectPath -Path $resolvedOutputDir -CreateIfMissing:$createDirs -PathType Directory | Out-Null
            }

            if ($Topic) {
                if ($prefixInfo -and $prefixInfo.topics -and $prefixInfo.topics.values) {
                    $validTopics = @($prefixInfo.topics.values)
                    if ($validTopics.Count -gt 0 -and $validTopics -notcontains $Topic) {
                        throw "Invalid -Topic '$Topic' for prefix '$IdPrefix'. Valid values: $($validTopics -join ', ')"
                    }
                }
                $resolvedOutputDir = Join-Path -Path $resolvedOutputDir -ChildPath $Topic
                Test-ProjectPath -Path $resolvedOutputDir -CreateIfMissing:$createDirs -PathType Directory | Out-Null
            }
        }

        # Determine file extension based on template
        $templateExtension = [System.IO.Path]::GetExtension($TemplatePath)

        # Generate filename (does not require document ID)
        if ($FileNamePattern) {
            $fileName = $FileNamePattern
        } else {
            $kebabName = ConvertTo-KebabCase -InputString $DocumentName
            if ($templateExtension -eq ".py") {
                $fileName = "test_${kebabName}.py"
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

        # Validate template exists before proceeding
        if (-not (Test-Path $resolvedTemplatePath)) {
            Write-ProjectError -Message "Template not found: $resolvedTemplatePath" -ExitCode 1
        }

        # Create the document using appropriate handler based on template type
        # ID generation, replacements, and file creation are all inside ShouldProcess
        # to prevent consuming IDs in -WhatIf mode
        if ($PSCmdlet.ShouldProcess("Create document at $outputPath")) {
            # Generate document ID only when actually creating the document
            $documentId = New-ProjectId -Prefix $IdPrefix -Description $IdDescription
            Write-Verbose "Generated document ID: $documentId"

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

            if ($templateExtension -eq ".md") {
                # Use existing markdown handler
                $result = New-ProjectDocumentWithMetadata -TemplatePath $resolvedTemplatePath -OutputPath $outputPath -DocumentId $documentId -Replacements $finalReplacements -AdditionalMetadataFields $AdditionalMetadataFields -OpenInEditor:$OpenInEditor
            } else {
                # Use new code file handler for non-markdown files
                $result = New-ProjectDocumentWithCodeMetadata -TemplatePath $resolvedTemplatePath -OutputPath $outputPath -DocumentId $documentId -Replacements $finalReplacements -AdditionalMetadataFields $AdditionalMetadataFields -OpenInEditor:$OpenInEditor -HeaderComment $HeaderComment
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

                # Return identity AND location — $outputPath is absolute in every
                # directory-resolution branch above (PF-IMP-1678).
                $rootForReturn = Get-ProjectRoot
                $relativePath = $outputPath
                if ($relativePath.StartsWith($rootForReturn, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $relativePath = $relativePath.Substring($rootForReturn.Length).TrimStart('\', '/')
                }
                $relativePath = $relativePath -replace '\\', '/'
                return [pscustomobject]@{
                    Id           = $documentId
                    Path         = $outputPath
                    RelativePath = $relativePath
                }
            } else {
                throw "Document creation failed"
            }
        }
    }
    catch {
        Write-ProjectError -Message "Failed to create document '$DocumentName': $($_.Exception.Message)" -ExitCode 1
    }
}

function New-FrameworkDocument {
    <#
    .SYNOPSIS
    Shared creation wrapper that absorbs the boilerplate every config-as-code creation
    script repeats — standard init, soak opt-in, the New-StandardProjectDocument call,
    try/catch, and (optionally) the success report — so a per-type creation script is
    reduced to its param block + data-building + one call. (PF-IMP-1135 / PF-PRO-043 Option 2.)

    .DESCRIPTION
    Generalizes the Invoke-DesignArtifactCreation pattern to ALL delegator scripts. The helper:
      1. runs Invoke-StandardScriptInitialization (preferences + console encoding);
      2. opts the CALLING .ps1 into soak verification via Register-SoakScript — caller-aware
         mode walks the call stack past .psm1 frames, so the soak row is keyed on the calling
         script, not this module (ExecutionVerification v2.0 Pattern B);
      3. resolves the effective -WhatIf across the module boundary (Get-EffectiveWhatIf), so a
         caller invoked with -WhatIf is honored by both the soak opt-in and the creation;
      4. calls New-StandardProjectDocument (the unchanged inner core) with the supplied
         template / id / directory / replacements / metadata;
      5. on failure, writes a standard error and exits 1 (matching every legacy script's catch).

    What STAYS in the per-type script: the param() block (so native ValidateSet / ValidateScript /
    ValidateLength / -? help / tab-completion are preserved), the replacements/metadata
    data-building (including conditional fields), its OWN Write-ProjectSuccess report (the
    message + detail lines are per-type content), and any bespoke post-creation tracking writes
    — done inline after this returns (see New-ArchitectureDecision for the Tier-3 pattern).

    Returns the assigned document ID (or $null under -WhatIf) — capture it for the success
    report and for any post-creation writes. A post-creating script that also needs the
    created file's PATH passes -PassThru and reads Id/Path/RelativePath off the returned
    object — never re-derive the filename by mirroring the writer's internal kebab logic
    (PF-IMP-1678).

    .PARAMETER TemplatePath
    Path to the template (forwarded to New-StandardProjectDocument).

    .PARAMETER IdPrefix
    ID-registry prefix for the new document (e.g. "PF-GDE", "PD-ADR").

    .PARAMETER IdDescription
    Annotation passed to the ID registry on assignment.

    .PARAMETER DocumentName
    Human-readable document name (drives the default kebab filename + template replacements).

    .PARAMETER DirectoryType / .PARAMETER OutputDirectory / .PARAMETER Subdirectory / .PARAMETER Topic / .PARAMETER FileNamePattern / .PARAMETER HeaderComment / .PARAMETER ConflictAction / .PARAMETER OpenInEditor
    Forwarded to New-StandardProjectDocument when supplied (directory resolution, filename, etc.).

    .PARAMETER Replacements
    Template placeholder replacements (caller's hashtable).

    .PARAMETER Metadata
    Additional frontmatter fields (forwarded as -AdditionalMetadataFields). Build it
    conditionally in the caller to omit empty optional fields (byte-identical frontmatter).

    .PARAMETER Label
    Human-readable noun for the failure message ("Failed to create <Label>: ..."). Defaults to
    -IdPrefix. The caller owns the SUCCESS report via its own Write-ProjectSuccess, so there is
    no success-label parameter.

    .PARAMETER PassThru
    Return the full creation result object — Id (assigned document ID), Path (absolute),
    RelativePath (project-root-relative, forward slashes) — instead of the bare ID. Use in
    post-creating scripts that write the created file's path into tracking tables or state
    files (PF-IMP-1678). Still $null under -WhatIf.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)] [string]$TemplatePath,
        [Parameter(Mandatory = $true)] [string]$IdPrefix,
        [Parameter(Mandatory = $true)] [string]$IdDescription,
        [Parameter(Mandatory = $true)] [string]$DocumentName,
        [string]$DirectoryType,
        [string]$OutputDirectory,
        [string]$Subdirectory,
        [string]$Topic,
        [string]$FileNamePattern,
        [hashtable]$Replacements = @{},
        [hashtable]$Metadata = @{},
        [hashtable]$HeaderComment,
        [ValidateSet("Error", "Overwrite", "Skip")] [string]$ConflictAction = "Error",
        [switch]$OpenInEditor,
        [string]$Label,
        [switch]$PassThru
    )

    Invoke-StandardScriptInitialization

    # Effective -WhatIf across the module boundary (PF-IMP-939) — same approach as
    # New-StandardProjectDocument / Invoke-DesignArtifactCreation. Walks the call stack
    # for an explicit -WhatIf in any caller frame (the module-local $WhatIfPreference does
    # not inherit it).
    $preview = Get-EffectiveWhatIf -WhatIfPreference $WhatIfPreference `
        -WhatIfBound:$PSBoundParameters.ContainsKey('WhatIf')

    # Soak opt-in for the CALLING script (no-op under -WhatIf / $env:PF_SOAK_DISABLE).
    Register-SoakScript -WhatIf:$preview

    try {
        $createArgs = @{
            TemplatePath             = $TemplatePath
            IdPrefix                 = $IdPrefix
            IdDescription            = $IdDescription
            DocumentName             = $DocumentName
            Replacements             = $Replacements
            AdditionalMetadataFields = $Metadata
            ConflictAction           = $ConflictAction
        }
        if ($DirectoryType)   { $createArgs.DirectoryType   = $DirectoryType }
        if ($OutputDirectory) { $createArgs.OutputDirectory = $OutputDirectory }
        if ($Subdirectory)    { $createArgs.Subdirectory    = $Subdirectory }
        if ($Topic)           { $createArgs.Topic           = $Topic }
        if ($FileNamePattern) { $createArgs.FileNamePattern = $FileNamePattern }
        if ($HeaderComment)   { $createArgs.HeaderComment   = $HeaderComment }
        if ($OpenInEditor)    { $createArgs.OpenInEditor    = $true }

        $result = New-StandardProjectDocument @createArgs -WhatIf:$preview
        # Inner core returns {Id, Path, RelativePath} on success (PF-IMP-1678). Default
        # contract stays the bare ID; -PassThru surfaces the full object. $null (-WhatIf)
        # and $false (-ConflictAction Skip) pass through unchanged either way.
        if (-not $PassThru -and $result -and $result.PSObject.Properties['Id']) {
            return $result.Id
        }
        return $result
    }
    catch {
        $noun = if ($Label) { $Label } else { $IdPrefix }
        Write-ProjectError -Message "Failed to create ${noun}: $($_.Exception.Message)" -ExitCode 1
    }
}

function Update-FrontmatterDate {
    <#
    .SYNOPSIS
    Replaces the `updated:` YYYY-MM-DD value in a document's YAML frontmatter.

    .DESCRIPTION
    Replaces the date value on the `updated:` line at any position in the content's frontmatter.
    Uses the `(?m)` multiline modifier so `^` matches start-of-line rather than start-of-string —
    `updated:` is virtually never the first line of a document. If no matching `updated:` line is
    present, returns the content unchanged.

    .PARAMETER Content
    The full document content as a single string.

    .PARAMETER CurrentDate
    The new date in YYYY-MM-DD format. Defaults to today's date.

    .EXAMPLE
    $content = Get-Content $file -Raw
    $content = Update-FrontmatterDate -Content $content
    Set-Content -Path $file -Value $content
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Content,

        [Parameter(Mandatory=$false)]
        [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
        [string]$CurrentDate = (Get-Date -Format 'yyyy-MM-dd')
    )

    return $Content -replace '(?m)(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate
}

function Step-FrontmatterRevision {
    <#
    .SYNOPSIS
    Advances a document's frontmatter revision stamp — sets `updated:` to the given date and
    increments the last segment of `version:` — operating only inside the leading YAML
    frontmatter block, so `version:`/`updated:` lines in the document body (code fences,
    examples) are never touched.

    .DESCRIPTION
    Companion to Update-FrontmatterDate (which it delegates the date write to): where that
    helper serves scripts stamping `updated:` on files they mutate, this one serves the
    lock-release path that maintains both stamps on agent-edited markdown (PF-IMP-1900).
    Content without a leading frontmatter block is returned unchanged. A `version:` value
    that is not dot-separated integers (or is absent) leaves the version untouched while the
    date still advances.

    .PARAMETER Content
    The full document content as a single string.

    .PARAMETER CurrentDate
    The new `updated:` date in YYYY-MM-DD format. Defaults to today.

    .OUTPUTS
    PSCustomObject with Content (the possibly-rewritten document), Changed (bool),
    OldVersion and NewVersion (strings; $null when no version was bumped).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
        [string]$CurrentDate = (Get-Date -Format 'yyyy-MM-dd')
    )

    $result = [pscustomobject]@{ Content = $Content; Changed = $false; OldVersion = $null; NewVersion = $null }

    # Leading frontmatter block only: '---' as the very first line, closed by a later '---' line.
    $block = [regex]::Match($Content, '(?s)\A---\r?\n(.*?)\r?\n---(\r?\n|\z)')
    if (-not $block.Success) { return $result }

    $inner = $block.Groups[1].Value
    $newInner = Update-FrontmatterDate -Content $inner -CurrentDate $CurrentDate

    $vm = [regex]::Match($newInner, '(?m)^(version:\s*"?)(\d+(?:\.\d+)*)\.(\d+)("?\s*)$')
    if ($vm.Success) {
        $result.OldVersion = "$($vm.Groups[2].Value).$($vm.Groups[3].Value)"
        $result.NewVersion = "$($vm.Groups[2].Value)." + ([int]$vm.Groups[3].Value + 1)
        $newLine = $vm.Groups[1].Value + $result.NewVersion + $vm.Groups[4].Value
        $newInner = $newInner.Remove($vm.Index, $vm.Length).Insert($vm.Index, $newLine)
    }

    if ($newInner -ne $inner) {
        $result.Content = $Content.Substring(0, $block.Groups[1].Index) + $newInner +
            $Content.Substring($block.Groups[1].Index + $block.Groups[1].Length)
        $result.Changed = $true
    }
    return $result
}

# Export functions
Export-ModuleMember -Function @(
    'New-ProjectDocumentMetadata',
    'Open-ProjectFileInEditor',
    'Get-TemplateMetadata',
    'Get-TemplateContentWithoutMetadata',
    'Convert-TemplateLinkDepth',
    'New-ProjectDocumentWithMetadata',
    'New-ProjectDocumentWithCodeMetadata',
    'New-ProjectCodeMetadata',
    'New-StandardProjectDocument',
    'New-FrameworkDocument',
    'Update-FrontmatterDate',
    'Step-FrontmatterRevision'
)
