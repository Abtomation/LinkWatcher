---
id: PF-GDE-013
type: Process Framework
category: Guide
version: 1.0
created: 2025-07-13
updated: 2025-07-13
---

# Hybrid Document Creation System Guide

## Overview

The Hybrid Document Creation System extends the existing document creation framework to support both markdown documents and code files while maintaining unified ID tracking and template processing.

## Supported File Types

### Markdown Files (.md)

- **Metadata Format**: YAML frontmatter
- **Use Case**: Documentation, guides, specifications, task definitions
- **Handler**: `New-ProjectDocumentWithMetadata`

### Code Files (.dart, .js, .ts, .py, etc.)

- **Metadata Format**: Structured comment blocks
- **Use Case**: Test files, source code, configuration files
- **Handler**: `New-ProjectDocumentWithCodeMetadata`

## How It Works

### 1. Automatic File Type Detection

The system detects file type based on template extension:

```powershell
$templateExtension = [System.IO.Path]::GetExtension($TemplatePath)

if ($templateExtension -eq ".md") {
    # Use markdown handler with YAML frontmatter
    New-ProjectDocumentWithMetadata @params
} else {
    # Use code handler with comment metadata
    New-ProjectDocumentWithCodeMetadata @params
}
```

### 2. Metadata Formats

#### Markdown Files (YAML Frontmatter)

```yaml
---
id: PF-TSK-001
type: Process Framework
category: Task Definition
version: 1.0
created: 2025-07-13
updated: 2025-07-13
task_type: Discrete
---
# Document Content
```

#### Code Files (Comment Metadata)

```dart
/*
 * Document Metadata:
 * ID: PF-TST-001
 * Type: Test File
 * Category: Unit
 * Version: 1.0
 * Created: 2025-07-13
 * Updated: 2025-07-13
 * Test Name: UserAuthentication
 * Test Type: Unit
 * Component Name: AuthService
 */

// Actual code content
import 'package:flutter_test/flutter_test.dart';
```

### 3. Template Structure

#### For Code Templates

Templates for code files use YAML frontmatter for template metadata but generate comment metadata in output:

```dart
---
id: [DOCUMENT_ID]
type: Template
creates_document_type: Test File
creates_document_category: Test
additional_fields:
  test_name: [TEST_NAME]
  test_type: [TEST_TYPE]
  component_name: [COMPONENT_NAME]
---

// [TEST_NAME] [TEST_TYPE] Test
import 'package:flutter_test/flutter_test.dart';
// ... rest of template
```

## ID Registry Integration

### Enhanced Registry Format

```json
{
  "PF-TST": {
    "description": "Process Framework - Test Files",
    "category": "Process Framework",
    "type": "Test File",
    "fileType": "dart",
    "metadataFormat": "comment",
    "directories": {
      "unit": "test/unit",
      "integration": "test/integration",
      "widget": "test/widget",
      "e2e": "integration_test",
      "default": "unit"
    },
    "nextAvailable": 5
  }
}
```

### New Fields

- **fileType**: Expected file extension (dart, js, ts, py, etc.)
- **metadataFormat**: How metadata is stored (comment, frontmatter)

## Usage Examples

### Creating Test Files

```powershell
# Creates test/unit/userauth_test.dart with comment metadata
../../scripts/file-creation/New-TestFile.ps1 -TestName "UserAuth" -TestType "Unit" -ComponentName "AuthService"

# Creates test/widget/loginscreen_test.dart with comment metadata
../../scripts/file-creation/New-TestFile.ps1 -TestName "LoginScreen" -TestType "Widget" -ComponentName "LoginScreen"
```

### Creating Markdown Documents

```powershell
# Creates markdown file with YAML frontmatter (existing functionality)
./New-Task.ps1 -TaskName "New Feature" -TaskType "Discrete" -Description "Implement new feature"
```

## Benefits

### ✅ Unified System

- Single ID registry for all document types
- Consistent creation process
- Unified tracking and management

### ✅ Language Flexibility

- Supports any programming language
- Proper syntax for each file type
- No compilation errors from metadata

### ✅ Backward Compatibility

- All existing markdown workflows unchanged
- No breaking changes to existing scripts
- Seamless migration

### ✅ Extensibility

- Easy to add new file types
- Template-driven approach
- Configurable metadata formats

## Adding New File Types

### 1. Create Template

Create a template file with appropriate extension:

```
doc/process-framework/templates/templates/component-template.js
```

### 2. Update ID Registry

Add file type information:

```json
{
  "PF-CMP": {
    "description": "Process Framework - Components",
    "fileType": "js",
    "metadataFormat": "comment",
    "directories": {
      "components": "src/components",
      "default": "components"
    }
  }
}
```

### 3. Create Creation Script

Use the document creation script template:

```powershell
./New-ComponentFile.ps1 -ComponentName "UserProfile" -ComponentType "React"
```

## Best Practices

### Template Design

- Use YAML frontmatter for template metadata
- Include all necessary replacement placeholders
- Follow language-specific conventions

### Metadata Comments

- Use block comments for multi-line metadata
- Include all essential tracking information
- Keep format consistent across file types

### File Naming

- Use kebab-case for consistency
- Include appropriate suffixes (\_test.dart, \_component.js)
- Follow project conventions

## Troubleshooting

### Common Issues

#### Template Not Found

```
Error: Cannot find template at: templates/test-template.dart
```

**Solution**: Ensure template exists in correct location

#### Metadata Not Replaced

```
Category: [TEST_TYPE]  // Should be: Category: Unit
```

**Solution**: Check replacement hashtable includes all placeholders

#### Wrong File Extension

```
Created: userauth_test.md  // Should be: userauth_test.dart
```

**Solution**: Verify template has correct extension

## Related Documentation

- [Document Creation Script Development Guide](document-creation-script-development-guide.md)
- [Template Development Guide](template-development-guide.md)
- [Task Creation Guide](task-creation-guide.md)
