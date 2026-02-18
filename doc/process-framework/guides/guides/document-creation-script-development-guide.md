---
id: PF-GDE-013
type: Process Framework
category: Guide
version: 1.0
created: 2025-07-08
updated: 2025-07-08
---

# Document Creation Script Development Guide

This guide provides comprehensive instructions for creating PowerShell scripts that generate documents from templates using the BreakoutBuddies project's standardized document creation system.

## Overview

The BreakoutBuddies project uses a standardized approach for creating documents from templates through PowerShell scripts. This system provides:

- **Consistent ID Management**: Automatic ID generation using the central ID registry
- **Standardized Error Handling**: Unified error reporting and logging
- **Template Integration**: Seamless integration with the template system
- **Metadata Management**: Automatic metadata generation and management
- **Directory Management**: Automatic directory creation and organization

## When to Use This Guide

Use this guide when you need to create a new PowerShell script that:

- Generates documents from templates
- Requires automatic ID assignment
- Needs to integrate with the project's document management system
- Should follow the project's standardized patterns

## Prerequisites

Before using this guide, ensure you have:

1. **Updated id-registry.json**: Ensure the ID registry contains necessary entries.
2. **Project Structure**: Familiarity with the BreakoutBuddies documentation structure
3. **Template System**: Understanding of the project's template system

### Required Files

Ensure these files exist in your project:

- `doc/process-framework/scripts/Common-ScriptHelpers.psm1`
- `doc/process-framework/scripts/IdRegistry.psm1`
- `doc/id-registry.json`
- `../doc/process-framework/templates/templates/document-creation-script-template.ps1`

## Step-by-Step Development Process

### Step 1: Analyze Requirements

Before creating a script, determine:

1. **Document Type**: What type of document will be created?
2. **Template Location**: Where is the template file located?
3. **ID Prefix**: What ID prefix should be used? (Update `doc/id-registry.json` if new directory is used)
4. **Parameters**: What parameters does the script need?
5. **Output Location**: Where should the created documents be stored?
6. **Special Requirements**: Any unique requirements or integrations?

### Step 2: Copy and Customize the Template

1. **Copy the Template**:

   ```powershell
   Copy-Item "../doc/process-framework/templates/templates/document-creation-script-template.ps1" "../doc/process-framework/templates/New-YourScript.ps1"
   ```

2. **Script Location**: All document creation scripts should be placed in the `doc/process-framework/templates` directory to maintain consistency and make them easier to find.

3. **The template is now a proper .ps1 file**: No need to change file extensions.

### Step 3: Replace Placeholders

Replace all `[PLACEHOLDER]` values in the template:

#### Basic Placeholders

| Placeholder          | Description                  | Example                                     |
| -------------------- | ---------------------------- | ------------------------------------------- |
| `[SCRIPT_NAME]`      | Script filename without .ps1 | `New-FeatureRequest`                        |
| `[DOCUMENT_TYPE]`    | Type of document created     | `Feature Request`                           |
| `[DOCUMENT_PURPOSE]` | Brief purpose description    | `feature request tracking`                  |
| `[ID_PREFIX]`        | ID prefix from registry      | `PF-REQ`                                    |
| `[TEMPLATE_PATH]`    | Path to template file        | `doc/templates/feature-request-template.md` |
| `[OUTPUT_DIRECTORY]` | Default output directory     | `doc/requests`                              |

#### Parameter Placeholders

| Placeholder           | Description         | Example        |
| --------------------- | ------------------- | -------------- |
| `PRIMARY_PARAMETER`   | Main parameter name | `RequestTitle` |
| `SECONDARY_PARAMETER` | Secondary parameter | `Priority`     |
| `OPTIONAL_PARAMETER`  | Optional parameter  | `Description`  |

#### Template Integration Placeholders

| Placeholder                | Description                       | Example             |
| -------------------------- | --------------------------------- | ------------------- |
| `[TEMPLATE_PLACEHOLDER_1]` | Template placeholder to replace   | `[Request Title]`   |
| `[TEMPLATE_PLACEHOLDER_2]` | Template placeholder to replace   | `[Priority Level]`  |
| `[TEMPLATE_PLACEHOLDER_3]` | Template placeholder to replace   | `[Description]`     |
| `[DEFAULT_VALUE]`          | Default value for optional params | `Standard Priority` |

#### Metadata Placeholders

| Placeholder             | Description               | Example                            |
| ----------------------- | ------------------------- | ---------------------------------- |
| `[METADATA_FIELD_1]`    | Additional metadata field | `request_priority`                 |
| `[METADATA_FIELD_2]`    | Additional metadata field | `request_type`                     |
| `[DESCRIPTION_PATTERN]` | ID description pattern    | `Feature request: ${RequestTitle}` |

#### Output Placeholders

| Placeholder         | Description            | Example                      |
| ------------------- | ---------------------- | ---------------------------- |
| `[DETAIL_1]`        | Success message detail | `Priority`                   |
| `[DETAIL_2]`        | Success message detail | `Type`                       |
| `[OPTIONAL_DETAIL]` | Optional detail        | `Description`                |
| `[NEXT_STEP_1]`     | First next step        | `Review the request details` |
| `[NEXT_STEP_2]`     | Second next step       | `Assign to appropriate team` |
| `[NEXT_STEP_3]`     | Third next step        | `Update project tracking`    |

### Step 4: Configure Import Path Logic

Replace `[IMPORT_PATH_LOGIC]` based on your script's location:

#### For Process Framework Scripts

```powershell
Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "../../../scripts/Common-ScriptHelpers.psm1") -Force
```

#### For Product Documentation Scripts

```powershell
$rootDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
Import-Module (Join-Path -Path $rootDir -ChildPath "doc/process-framework/../../../scripts/Common-ScriptHelpers.psm1") -Force
```

#### For Deep Nested Scripts

```powershell
# Navigate from current location to project root, then to scripts
$rootDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
Import-Module (Join-Path -Path $rootDir -ChildPath "doc/process-framework/../../../scripts/Common-ScriptHelpers.psm1") -Force
```

### Step 5: Add Parameter Validation

Enhance parameter validation as needed:

```powershell
[Parameter(Mandatory=$true)]
[ValidateSet("High", "Medium", "Low")]
[string]$Priority,

[Parameter(Mandatory=$true)]
[ValidateLength(5, 100)]
[string]$Title,

[Parameter(Mandatory=$false)]
[ValidateScript({Test-Path $_})]
[string]$AttachmentPath
```

### Step 6: Customize Metadata and Replacements

#### Metadata Fields Example

```powershell
$additionalMetadataFields = @{
    "priority" = $Priority
    "request_type" = $RequestType
    "created_by" = $env:USERNAME
    "status" = "New"
}
```

#### Custom Replacements Example

```powershell
$customReplacements = @{
    "[Request Title]" = $Title
    "[Priority Level]" = $Priority
    "[Request Description]" = if ($Description -ne "") { $Description } else { "No description provided" }
    "[Created Date]" = Get-Date -Format "yyyy-MM-dd"
    "[Created By]" = $env:USERNAME
}
```

### Step 7: Add Optional Documentation Updates

Replace the commented `# [OPTIONAL_DOCUMENTATION_UPDATES]` with any required updates:

```powershell
# Update documentation map
$docMapPath = Join-Path -Path $PSScriptRoot -ChildPath "../documentation-map.md"
if (Test-Path $docMapPath) {
    if ($PSCmdlet.ShouldProcess("Update documentation map")) {
        # Add logic to update documentation map
        Write-Verbose "Updated documentation map with new request"
    }
}

# Update README file
$readmePath = Join-Path -Path $PSScriptRoot -ChildPath "../README.md"
if (Test-Path $readmePath) {
    if ($PSCmdlet.ShouldProcess("Update README")) {
        # Add logic to update README
        Write-Verbose "Updated README with new request"
    }
}
```

### Step 8: Test the Script

1. **Syntax Check**:

   ```powershell
   Get-Command .\../New-YourScript.ps1 -Syntax
   ```

2. **Test Run**:

   ```powershell
   .\../New-YourScript.ps1 -WhatIf -Verbose
   ```

3. **Actual Test**:
   ```powershell
   .\../New-YourScript.ps1 -Title "Test Request" -Priority "Medium"
   ```

## Common Patterns and Examples

### Example 1: Template Creation Script

The `New-Template.ps1` script in the templates directory is a real-world example of a document creation script that creates new templates:

```powershell
# New-Template.ps1
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$TemplateName,

    [Parameter(Mandatory=$true)]
    [string]$TemplateDescription,

    [Parameter(Mandatory=$true)]
    [string]$DocumentPrefix,

    [Parameter(Mandatory=$true)]
    [string]$DocumentCategory,

    [Parameter(Mandatory=$false)]
    [string]$OutputDirectory = "doc/process-framework/templates/templates",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

# Import the common helpers
Import-Module (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "../../../scripts/Common-ScriptHelpers.psm1") -Force
Invoke-StandardScriptInitialization

# Get current date in YYYY-MM-DD format
$currentDate = Get-Date -Format "yyyy-MM-dd"

# Prepare additional metadata fields
$additionalMetadataFields = @{
    "template_for" = $DocumentCategory
    "creates_document_type" = "Process Framework"
    "creates_document_category" = $DocumentCategory
    "creates_document_prefix" = $DocumentPrefix
    "creates_document_version" = "1.0"
    "usage_context" = "Process Framework - $DocumentCategory Creation"
    "description" = $TemplateDescription
}

# Create the template using standardized process
try {
    $templateId = New-StandardProjectDocument -TemplatePath "doc/process-framework/templates/templates/template-base-template.md" -IdPrefix "PF-TEM" -IdDescription "$TemplateName template" -DocumentName "$($TemplateName.ToLower().Replace(' ', '-'))-template" -OutputDirectory $OutputDirectory -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    Write-ProjectSuccess -Message "Created template with ID: $templateId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create template: $($_.Exception.Message)" -ExitCode 1
}
```

This script demonstrates:

- Using a base template to create new templates
- Proper metadata handling for templates
- Standardized error handling and success reporting
- Dynamic path resolution for different script locations

### Example 2: Simple Document Creation Script

```powershell
# ../New-SimpleDocument.ps1
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$DocumentTitle,

    [Parameter(Mandatory=$false)]
    [string]$Description = "",

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "../../../scripts/Common-ScriptHelpers.psm1") -Force
Invoke-StandardScriptInitialization

$customReplacements = @{
    "[Document Title]" = $DocumentTitle
    "[Document Description]" = if ($Description -ne "") { $Description } else { "Simple document" }
}

try {
    $documentId = New-StandardProjectDocument -TemplatePath "../doc/templates/simple-template.md" -IdPrefix "PF-DOC" -IdDescription "Simple document: ${DocumentTitle}" -DocumentName $DocumentTitle -OutputDirectory "doc/documents" -Replacements $customReplacements -OpenInEditor:$OpenInEditor

    Write-ProjectSuccess -Message "Created document with ID: $documentId"
}
catch {
    Write-ProjectError -Message "Failed to create document: $($_.Exception.Message)" -ExitCode 1
}
```

### Example 2: Complex Script with Validation

```powershell
# ../New-ComplexDocument.ps1
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [ValidateLength(5, 50)]
    [string]$Title,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Feature", "Bug", "Enhancement")]
    [string]$Type,

    [Parameter(Mandatory=$false)]
    [ValidateSet("High", "Medium", "Low")]
    [string]$Priority = "Medium",

    [Parameter(Mandatory=$false)]
    [string]$DirectoryType,

    [Parameter(Mandatory=$false)]
    [switch]$OpenInEditor
)

Import-Module (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "../../../scripts/Common-ScriptHelpers.psm1") -Force
Invoke-StandardScriptInitialization

$additionalMetadataFields = @{
    "document_type" = $Type
    "priority" = $Priority
    "created_by" = $env:USERNAME
}

$customReplacements = @{
    "[Document Title]" = $Title
    "[Document Type]" = $Type
    "[Priority Level]" = $Priority
    "[Creation Date]" = Get-Date -Format "yyyy-MM-dd"
}

try {
    $documentId = New-StandardProjectDocument -TemplatePath "../doc/templates/complex-template.md" -IdPrefix "PF-CMP" -IdDescription "$Type document: ${Title}" -DocumentName $Title -DirectoryType $DirectoryType -Replacements $customReplacements -AdditionalMetadataFields $additionalMetadataFields -OpenInEditor:$OpenInEditor

    $details = @(
        "Type: $Type",
        "Priority: $Priority"
    )

    Write-ProjectSuccess -Message "Created $Type document with ID: $documentId" -Details $details
}
catch {
    Write-ProjectError -Message "Failed to create document: $($_.Exception.Message)" -ExitCode 1
}
```

## ID Registry Integration

### Understanding ID Prefixes

Check `doc/id-registry.json` for available prefixes:

```json
{
  "prefixes": {
    "PF-TSK": {
      "description": "Process Framework - Tasks",
      "directories": {
        "01-planning": "doc/process-framework/tasks/01-planning",
        "02-design": "doc/process-framework/tasks/02-design",
        "03-testing": "doc/process-framework/tasks/03-testing",
        "04-implementation": "doc/process-framework/tasks/04-implementation",
        "05-validation": "doc/process-framework/tasks/05-validation",
        "06-maintenance": "doc/process-framework/tasks/06-maintenance",
        "07-deployment": "doc/process-framework/tasks/07-deployment",
        "continuous": "doc/process-framework/tasks/continuous",
        "default": "04-implementation"
      }
    }
  }
}
```

### Adding New Prefixes

If you need a new prefix:

1. **Add to Registry**:

   ```json
   "PF-REQ": {
     "description": "Process Framework - Requests",
     "category": "Process Framework",
     "type": "Request",
     "directories": {
       "main": "doc/process-framework/requests",
       "default": "main"
     },
     "nextAvailable": 1
   }
   ```

2. **Use in Script**:
   ```powershell
   $documentId = New-StandardProjectDocument -IdPrefix "PF-REQ" ...
   ```

## Template Integration

### Template Requirements

Your document template should:

1. **Include Metadata**:

   ```yaml
   ---
   id: [DOCUMENT_ID]
   type: [DOCUMENT_TYPE]
   category: [CATEGORY]
   version: 1.0
   created: [DATE]
   updated: [DATE]
   ---
   ```

2. **Use Placeholders**:

   ```markdown
   # [Document Title]

   ## Description

   [Document Description]

   ## Priority

   [Priority Level]
   ```

3. **Follow Naming Convention**:
   - Template files: `document-type-template.md`
   - Store in appropriate templates directory

### Template Metadata

Templates should include creation metadata:

```yaml
---
# Template Metadata
id: PF-TEM-XXX
type: Process Framework
category: Template

# Document Creation Metadata
creates_document_type: "Request"
creates_document_category: "Feature Request"
creates_document_prefix: "PF-REQ"
---
```

## Directory Management

### Directory Types

The system supports semantic directory types that are resolved through the ID registry:

```powershell
# Use specific directory type (recommended)
$documentId = New-StandardProjectDocument -DirectoryType "04-implementation" ...

# Use explicit directory path (for custom locations)
$documentId = New-StandardProjectDocument -OutputDirectory "doc/custom/path" ...
```

### Subdirectory Handling

When your task creates files that should be organized in subdirectories, configure the ID registry to map directory types to subdirectories:

```json
"PD-API": {
  "directories": {
    "specifications": "doc/product-docs/technical/api/specifications/specifications",
    "models": "doc/product-docs/technical/api/models",
    "default": "specifications"
  }
}
```

Then use `DirectoryType` in your script:

```powershell
# This will create files in the subdirectory defined in ID registry
$documentId = New-StandardProjectDocument -DirectoryType "specifications" -IdPrefix "PD-API" ...
```

**Benefits of DirectoryType over OutputDirectory:**

- Automatic subdirectory resolution through ID registry
- Consistent directory structure across all scripts
- Easy to change directory structure by updating ID registry only
- Supports complex directory hierarchies

### Directory Creation

Directories are created automatically:

```powershell
# This will create the directory if it doesn't exist
$documentId = New-StandardProjectDocument -OutputDirectory "doc/new/directory" ...
```

## Error Handling Best Practices

### Standard Error Handling

```powershell
try {
    $documentId = New-StandardProjectDocument ...
    Write-ProjectSuccess -Message "Success message"
}
catch {
    Write-ProjectError -Message "Failed to create document: $($_.Exception.Message)" -ExitCode 1
}
```

### Parameter Validation Errors

```powershell
[Parameter(Mandatory=$true)]
[ValidateScript({
    if (Test-Path $_) { return $true }
    throw "Path '$_' does not exist"
})]
[string]$TemplatePath
```

### Custom Validation

```powershell
# Validate before processing
if (-not (Test-Path $TemplatePath)) {
    Write-ProjectError -Message "Template not found: $TemplatePath" -ExitCode 1
}

# Validate ID prefix exists
try {
    $prefixInfo = Get-PrefixInfo -Prefix $IdPrefix
}
catch {
    Write-ProjectError -Message "Invalid ID prefix: $IdPrefix" -ExitCode 1
}
```

## Testing and Validation

### Unit Testing

Create test scripts for your document creation scripts:

```powershell
# ../Test-NewYourScript.ps1
Describe "New-YourScript" {
    It "Should create document with valid parameters" {
        $result = .\../New-YourScript.ps1 -Title "Test" -Type "Feature" -WhatIf
        $result | Should -Not -BeNullOrEmpty
    }

    It "Should validate required parameters" {
        { .\../New-YourScript.ps1 -Type "Feature" } | Should -Throw
    }
}
```

### Integration Testing

Test the complete workflow:

```powershell
# Create test document
$documentId = .\../New-YourScript.ps1 -Title "Integration Test" -Type "Feature"

# Verify document was created
$documentPath = "../doc/documents/integration-test.md"
Test-Path $documentPath | Should -Be $true

# Verify ID was registered
Test-IdExists -Id $documentId | Should -Be $true

# Clean up
Remove-Item $documentPath -Force
```

## Troubleshooting

### Common Issues

1. **Import Module Errors**:

   - **Issue**: "The specified module was not loaded because no valid module file was found"
   - **Cause**: PowerShell path resolution differs between execution contexts
   - **Solution**: Use robust path resolution:
     ```powershell
     $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
     $modulePath = Join-Path -Path $scriptDir -ChildPath "relative/path/to/module"
     $resolvedPath = Resolve-Path $modulePath
     Import-Module $resolvedPath -Force
     ```
   - **Prevention**: Always test scripts from different directories and execution contexts

2. **ID Registry Errors**:

   - Verify `doc/id-registry.json` exists and is valid JSON
   - Check that the ID prefix exists in the registry
   - Ensure proper permissions for file updates

3. **Template Replacement Errors**:

   - **Issue**: Template placeholders not being replaced in generated documents
   - **Cause**: Incorrect replacement key format (escaped vs. literal brackets)
   - **Solution**: Use exact bracket notation without escaping:

     ```powershell
     # ✅ CORRECT - Use literal brackets
     $customReplacements = @{
         "[Feature Name]" = $FeatureName
         "[Description]" = $Description
     }

     # ❌ INCORRECT - Don't escape brackets
     $customReplacements = @{
         "\[Feature Name\]" = $FeatureName  # This won't work!
     }
     ```

   - **Testing**: Always verify replacements worked by checking the generated document
   - **Prevention**: Use the testing checklist in the script template

4. **Template File Errors**:

   - Verify template file exists at specified path
   - Check template metadata format
   - Ensure placeholders in template match replacement keys exactly

5. **Directory Errors**:
   - Check directory permissions
   - Verify directory type exists for the prefix
   - Ensure proper path formatting (forward vs. backward slashes)

### Debugging Tips

1. **Use Verbose Output**:

   ```powershell
   .\../New-YourScript.ps1 -Title "Test" -Verbose
   ```

2. **Use WhatIf**:

   ```powershell
   .\../New-YourScript.ps1 -Title "Test" -WhatIf
   ```

3. **Check Variables**:

   ```powershell
   Write-Host "Template Path: $TemplatePath"
   Write-Host "Output Directory: $OutputDirectory"
   Write-Host "Replacements: $($customReplacements | ConvertTo-Json)"
   ```

4. **Test Components Separately**:

   ```powershell
   # Test ID generation
   $testId = New-ProjectId -Prefix "PF-TST" -Description "Test"

   # Test template processing
   $metadata = Get-TemplateMetadata -TemplatePath $TemplatePath
   ```

## Script Testing Methodology

### Systematic Testing Approach

Before considering any document creation script complete, follow this comprehensive testing methodology:

#### 1. **Pre-Testing Setup**

```powershell
# Verify prerequisites
Test-Path "doc/process-framework/scripts/Common-ScriptHelpers.psm1"
Test-Path "doc/id-registry.json"
Test-Path "path/to/your/template.md"

# Check current working directory
Get-Location
```

#### 2. **Module Import Testing**

```powershell
# Test module import in isolation
$scriptDir = (Get-Location).Path
$modulePath = Join-Path -Path $scriptDir -ChildPath "relative/path/to/Common-ScriptHelpers.psm1"
try {
    $resolvedPath = Resolve-Path $modulePath -ErrorAction Stop
    Import-Module $resolvedPath -Force
    Write-Host "✅ Module import successful"
} catch {
    Write-Host "❌ Module import failed: $($_.Exception.Message)"
}
```

#### 3. **Basic Functionality Testing**

```powershell
# Test with minimal parameters
./New-YourScript.ps1 -PrimaryParam "Test Document" -SecondaryParam "Test"

# Verify document creation
$expectedPath = "expected/output/path/test-document.md"
if (Test-Path $expectedPath) {
    Write-Host "✅ Document created successfully"
    Get-Content $expectedPath | Select-Object -First 10
} else {
    Write-Host "❌ Document not created at expected path: $expectedPath"
}
```

#### 4. **Template Replacement Verification**

```powershell
# Check for unreplaced placeholders
$content = Get-Content $expectedPath -Raw
$unreplacedPlaceholders = [regex]::Matches($content, '\[([^\]]+)\]') | ForEach-Object { $_.Value }

if ($unreplacedPlaceholders.Count -eq 0) {
    Write-Host "✅ All template placeholders replaced"
} else {
    Write-Host "❌ Unreplaced placeholders found:"
    $unreplacedPlaceholders | ForEach-Object { Write-Host "  - $_" }
}
```

#### 5. **Metadata Validation**

```powershell
# Extract and validate metadata
$metadataLines = Get-Content $expectedPath | Select-Object -First 15
$metadataSection = ($metadataLines -join "`n") -split "---"
if ($metadataSection.Count -ge 2) {
    Write-Host "✅ Metadata section found"
    Write-Host $metadataSection[1]
} else {
    Write-Host "❌ Metadata section missing or malformed"
}
```

#### 6. **Error Handling Testing**

```powershell
# Test with invalid parameters
./New-YourScript.ps1 -PrimaryParam "" -SecondaryParam "Test"  # Empty required param
./New-YourScript.ps1 -PrimaryParam "Test" -NonExistentParam "Invalid"  # Invalid param

# Test with missing dependencies
Rename-Item "doc/process-framework/scripts/Common-ScriptHelpers.psm1" "Common-ScriptHelpers.psm1.bak"
./New-YourScript.ps1 -PrimaryParam "Test" -SecondaryParam "Test"  # Should fail gracefully
Rename-Item "Common-ScriptHelpers.psm1.bak" "doc/process-framework/scripts/Common-ScriptHelpers.psm1"
```

#### 7. **Cleanup and ID Verification**

```powershell
# Check ID registry was updated
$registryContent = Get-Content "doc/id-registry.json" | ConvertFrom-Json
$prefix = "YOUR-PREFIX"  # Replace with actual prefix
$nextAvailable = $registryContent.prefixes.$prefix.nextAvailable
Write-Host "Next available ID for $prefix: $nextAvailable"

# Clean up test files
Remove-Item $expectedPath -Force -ErrorAction SilentlyContinue
Write-Host "✅ Test cleanup completed"
```

### Testing Checklist

Use this checklist for every script:

- [ ] **Module Import**: Script loads Common-ScriptHelpers without errors
- [ ] **Basic Creation**: Document is created in correct location with correct name
- [ ] **ID Assignment**: Document receives proper ID and registry is updated
- [ ] **Template Replacement**: All placeholders are replaced with actual values
- [ ] **Metadata**: Document metadata is complete and properly formatted
- [ ] **Error Handling**: Script fails gracefully with helpful error messages
- [ ] **Parameter Validation**: Invalid parameters are caught and reported
- [ ] **Directory Creation**: Output directories are created if they don't exist
- [ ] **File Permissions**: Script works with various file permission scenarios
- [ ] **Cross-Platform**: Script works in different PowerShell environments

### Automated Testing Script Template

Create a test script alongside your document creation script:

```powershell
# Test-YourScript.ps1
param(
    [switch]$Cleanup
)

$testName = "Test Document $(Get-Date -Format 'HHmmss')"
$scriptPath = "./New-YourScript.ps1"

try {
    Write-Host "🧪 Testing $scriptPath..."

    # Run the script
    & $scriptPath -PrimaryParam $testName -SecondaryParam "Test"

    # Verify results
    $expectedFile = "path/to/expected/output.md"
    if (Test-Path $expectedFile) {
        Write-Host "✅ Test passed: Document created"

        # Check content
        $content = Get-Content $expectedFile -Raw
        if ($content -match $testName) {
            Write-Host "✅ Test passed: Content replacement worked"
        } else {
            Write-Host "❌ Test failed: Content replacement failed"
        }
    } else {
        Write-Host "❌ Test failed: Document not created"
    }

} finally {
    if ($Cleanup -and (Test-Path $expectedFile)) {
        Remove-Item $expectedFile -Force
        Write-Host "🧹 Cleanup completed"
    }
}
```

## Best Practices

### Script Organization

1. **Consistent Naming**: Use `New-[DocumentType].ps1` pattern
2. **Parameter Order**: Mandatory parameters first, optional parameters last
3. **Documentation**: Include comprehensive help documentation
4. **Error Handling**: Use standardized error handling patterns

### Code Quality

1. **Parameter Validation**: Use appropriate validation attributes
2. **Error Messages**: Provide clear, actionable error messages
3. **Success Messages**: Include relevant details in success messages
4. **Logging**: Use Write-Verbose for debugging information

### Maintenance

1. **Version Control**: Track script changes in version control
2. **Documentation**: Keep this guide updated with new patterns
3. **Testing**: Maintain test scripts for all document creation scripts
4. **Review**: Regular code reviews for new scripts

## Advanced Topics

### Custom File Naming

```powershell
# Custom filename pattern
$customFileName = "$(Get-Date -Format 'yyyyMMdd')-$($Title.ToLower() -replace ' ', '-').md"
$documentId = New-StandardProjectDocument -FileNamePattern $customFileName ...
```

### Multiple Template Support

```powershell
# Select template based on type
$templatePath = switch ($Type) {
    "Feature" { "../doc/templates/feature-template.md" }
    "Bug" { "../doc/templates/bug-template.md" }
    "Enhancement" { "../doc/templates/enhancement-template.md" }
}
```

### Conditional Processing

```powershell
# Conditional replacements
$customReplacements = @{
    "[Title]" = $Title
}

if ($Priority -eq "High") {
    $customReplacements["[Priority Badge]"] = "🔴 HIGH PRIORITY"
} else {
    $customReplacements["[Priority Badge]"] = "Priority: $Priority"
}
```

## Real-World Examples

The project includes several document creation scripts that follow these guidelines:

1. **Template Creation Script** - [New-Template.ps1](/doc/process-framework/scripts/file-creation/New-Template.ps1)
   - Creates new templates with proper metadata
   - Located in the templates directory as per best practices
   - Uses the template base template as its source

## Conclusion

This guide provides a comprehensive framework for creating document creation scripts in the BreakoutBuddies project. By following these patterns and best practices, you can create consistent, maintainable scripts that integrate seamlessly with the project's document management system.

Remember to:

- Test your scripts thoroughly
- Follow the established patterns
- Update documentation when adding new features
- Use the standardized error handling and success reporting
- Place all document creation scripts in the templates directory

For additional support or questions, refer to the project's documentation or contact the human user.

## Related Resources

- [Template Development Guide](template-development-guide.md)
- [Template Base Template](/doc/process-framework/templates/templates/template-base-template.md)
- [New-Template.ps1 Script](/doc/process-framework/scripts/file-creation/New-Template.ps1)
