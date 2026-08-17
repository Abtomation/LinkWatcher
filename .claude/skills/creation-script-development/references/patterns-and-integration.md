# Creation Script Patterns & Integration Details

Working-level detail for authoring document-creation scripts. The authoring model and
development flow live in [SKILL.md](../SKILL.md).

## Placeholder tables (document-creation-script-template.ps1)

### Basic

| Placeholder | Description | Example |
|---|---|---|
| `[SCRIPT_NAME]` | Script filename without .ps1 | `New-FeatureRequest` |
| `[DOCUMENT_TYPE]` | Type of document created | `Feature Request` |
| `[DOCUMENT_PURPOSE]` | Brief purpose description | `feature request tracking` |
| `[ID_PREFIX]` | ID prefix from registry | `PF-REQ` |
| `[TEMPLATE_PATH]` | Path to template file | `process-framework/templates/support/feature-request-template.md` |
| `[OUTPUT_DIRECTORY]` | Default output directory | `doc/requests` |

### Parameters

| Placeholder | Description | Example |
|---|---|---|
| `PRIMARY_PARAMETER` | Main parameter name | `RequestTitle` |
| `SECONDARY_PARAMETER` | Secondary parameter | `Priority` |
| `OPTIONAL_PARAMETER` | Optional parameter | `Description` |

### Template integration / metadata / output

| Placeholder | Description | Example |
|---|---|---|
| `[TEMPLATE_PLACEHOLDER_n]` | Template placeholder to replace | `[Request Title]` |
| `[DEFAULT_VALUE]` | Default for optional params | `Standard Priority` |
| `[METADATA_FIELD_n]` | Additional metadata field | `request_priority` |
| `[DESCRIPTION_PATTERN]` | ID description pattern | `Feature request: ${RequestTitle}` |
| `[DETAIL_n]` / `[OPTIONAL_DETAIL]` | Success-message details | `Priority` |
| `[NEXT_STEP_n]` | Next-step lines in the success report | `Review the request details` |

Replacement keys use **literal brackets** — `"[Feature Name]" = $FeatureName` — never
escaped brackets.

## Import-path forms (`[IMPORT_PATH_LOGIC]`)

```powershell
# Process-framework scripts (scripts/file-creation/<phase>/)
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "../../scripts/Common-ScriptHelpers.psm1") -Force

# Product documentation scripts (three levels below root)
$rootDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
Import-Module (Join-Path -Path $rootDir -ChildPath "process-framework/scripts/Common-ScriptHelpers.psm1") -Force
```

Deeper nesting adds one `Split-Path -Parent` per level. For fragile contexts use robust
resolution (`$PSScriptRoot` fallback to `Get-Location`, `Resolve-Path` before import) — see
the Quick Reference's Module Import Failures entry.

## Minimal plain-delegator example

```powershell
# New-SimpleDocument.ps1
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$DocumentTitle,

    [Parameter(Mandatory=$false)]
    [string]$Description = "",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "../../scripts/Common-ScriptHelpers.psm1") -Force

# Init, soak opt-in, the create call, try/catch, and the error report are owned by
# New-FrameworkDocument. This script keeps only its param block, data, and success report.

$customReplacements = @{
    "[Document Title]" = $DocumentTitle
    "[Document Description]" = if ($Description -ne "") { $Description } else { "Simple document" }
}

$documentId = New-FrameworkDocument -TemplatePath "process-framework/templates/simple-template.md" -IdPrefix "PF-DOC" -IdDescription "Simple document: ${DocumentTitle}" -DocumentName $DocumentTitle -OutputDirectory "doc/documents" -Replacements $customReplacements -Label "document" -OpenInEditor:$OpenInEditor

Write-ProjectSuccess -Message "Created document with ID: $documentId"
```

## Template contract

The consumed template needs:

1. **Standard metadata frontmatter** — the template's own identity (`id` / `type` / `category` /
   `version` / `created` / `updated` / `description`) — plus the **creation metadata** the writer
   reads to stamp the documents the template generates:

   ```yaml
   creates_document_type: "Product Documentation"           # the tree
   creates_document_category: "Functional Design Document"  # the artifact kind
   creates_document_prefix: "PD-FDD"
   ```

   `creates_document_type` carries the **tree** (`Process Framework` | `Product Documentation` |
   `Testing`) and `creates_document_category` the **kind** — the same pair the ID registry records
   for the prefix, transposed (registry `category` = tree, registry `type` = kind). Declare both:
   omit them and the writer warns and stamps the fallback `type: Document` /
   `category: General`.

2. **Body placeholders** matching the script's replacement keys exactly. 🚨 Keep replacement
   placeholders in the **body** — template frontmatter is stripped and rebuilt from
   `-Metadata`, so a frontmatter placeholder is never substituted.
3. **Naming**: `document-type-template.md`, stored in the matching `templates/` subfolder.

Template-design craft (principles, components, testing) is the
[`template-development`](../../template-development/SKILL.md) skill.

## ID registry integration

Check the appropriate registry (`PF/PD/TE-id-registry.json`) for the prefix; add a new one
when needed:

```json
"PF-REQ": {
  "description": "Process Framework - Requests",
  "category": "Process Framework",
  "type": "Request",
  "directories": {
    "main": "process-framework/requests",
    "default": "main"
  },
  "nextAvailable": 1
}
```

### Subdirectory schema (`-Subdirectory` approach)

Optional per-prefix validation — omit the fields for freeform passthrough:

```json
"PD-UGD": {
  "subdirectories": {
    "values": ["tutorials", "how-to", "reference", "explanation"],
    "default": "how-to"
  },
  "topics": { "values": [], "default": null }
}
```

`-Subdirectory $ContentType` appends an L1 directory at runtime; add `-Topic $TopicArea` for
an L2 facet (content type × topic). Fixed category sets instead declare multiple named
`directories` entries and select via `-DirectoryType`.

## Language-config integration

When a script needs language-specific commands (test runners, linters, coverage), load them
from `languages-config` instead of hardcoding:

```powershell
$config = Get-Content (Join-Path $projectRoot "doc/project-config.json") -Raw | ConvertFrom-Json
$language = $config.testing.language
$langConfigPath = Join-Path (Get-ProcessFrameworkPath) "languages-config/$language/$language-config.json"
if (-not (Test-Path $langConfigPath)) { Write-Error "Language config not found: $langConfigPath"; exit 1 }
$langConfig = Get-Content $langConfigPath -Raw | ConvertFrom-Json

# Placeholder substitution — configs use {module} and {testDir}
$command = ($langConfig.testing.baseCommand -replace '\{module\}', $moduleName) -replace '\{testDir\}', $testDir
```

| Scenario | Approach |
|---|---|
| Command varies by language (test runner, linter) | Read from language config |
| Command is framework-internal (module import, ID registry) | Hardcode — not language-dependent |
| Command is project-specific (custom build step) | Read from project-config.json |

Add missing fields consistently across all configs + the template with
`process-framework/scripts/update/Update-LanguageConfig.ps1` (`-List` audits drift). A new
language gets its config by copying
`process-framework/templates/support/language-config-template.json` during Project
Initiation. Reference implementation: `process-framework/scripts/test/Run-Tests.ps1`.

## Advanced patterns

```powershell
# Custom filename pattern (raw New-StandardProjectDocument returns {Id, Path, RelativePath} —
# go through the wrapper, which returns the bare ID, or the full object with -PassThru)
$customFileName = "$(Get-Date -Format 'yyyyMMdd')-$($Title.ToLower() -replace ' ', '-').md"
$documentId = New-FrameworkDocument -FileNamePattern $customFileName ...

# Template selection by type
$templatePath = switch ($Type) {
    "Task"     { "process-framework/templates/support/task-template.md" }
    "Guide"    { "process-framework/templates/support/guide-template.md" }
    "Feedback" { "process-framework/templates/support/feedback-form-template.md" }
}

# Conditional replacements
if ($Priority -eq "High") { $customReplacements["[Priority Badge]"] = "🔴 HIGH PRIORITY" }
else { $customReplacements["[Priority Badge]"] = "Priority: $Priority" }
```

## Debugging and common issues

- **Verbose / WhatIf first**: `.\New-YourScript.ps1 -Title "Test" -Verbose` and `-WhatIf`
  exercise the logic path safely.
- **Test components separately**: `New-ProjectId -Prefix "PF-TST" -Description "Test"`;
  `Get-TemplateMetadata -TemplatePath $TemplatePath`.
- **Placeholders not replaced** → replacement keys must use literal brackets and match the
  template exactly; verify the generated document, not just exit code.
- **ID registry errors** → registry exists and is valid JSON; prefix present; write
  permissions.
- **Directory errors** → directory type exists for the prefix; forward/backward slash
  formatting.
- **`| Out-Null` on `New-Item -ItemType Directory -Force` is by design** — without it the
  returned `DirectoryInfo` interferes with return values and `-WhatIf`.
- For module-import failures, `-File`/`-Command` invocation differences, exit-code
  propagation, and Pester patterns, use the
  [Script Development Quick Reference](../../../../process-framework/guides/support/script-development-quick-reference.md)
  — the standing troubleshooting companion.
