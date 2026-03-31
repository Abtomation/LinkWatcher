# Language Configurations

This directory contains language-specific configuration files and templates used by framework scripts (e.g., `Run-Tests.ps1`).

## Directory Structure

Each supported language has its own subdirectory:

```
languages-config/
├── python/
│   └── python-config.json
├── README.md
```

## How It Works

1. `project-config.json` specifies `testing.language` (e.g., `"python"`)
2. Framework scripts load `languages-config/{language}/{language}-config.json` for language-specific commands
3. Project-specific settings (test directory, module name, quick categories) stay in `project-config.json`

## Available Configurations

| Directory | Language | Test Runner |
|-----------|----------|-------------|
| `python/` | Python | pytest |

## Adding a New Language

1. Create a subdirectory matching the language name (e.g., `javascript/`)
2. Copy the [language config template](/process-framework/templates/support/language-config-template.json) to `{language}/{language}-config.json`
3. Fill in the values (remove `_comment_*` fields when done)
4. Set `testing.language` in the adopting project's `project-config.json` to match the directory name

### Required Fields

```json
{
  "language": "your-language",
  "version": "1.0",
  "testing": {
    "baseCommand": "your-test-runner command",
    "coverageArgs": "coverage flags with {module} and {testDir} placeholders",
    "discoveryCommand": "test discovery command",
    "stopOnFirstFailure": "flag to stop on first failure",
    "verboseFlag": "flag for verbose output"
  }
}
```

### Placeholder Substitution

Scripts replace these tokens at runtime:
- `{module}` — project module name (from `project-config.json` → `project.name`)
- `{testDir}` — test directory path (from `project-config.json` → `testing.testDirectory`)

### Optional Fields

- `testing.lintCommand` — linting command (omit if language has no lint tool configured)
- `testing.coverageFullArgs` — extended coverage flags (XML output, term-missing, etc.)
- `testing.markers` — test marker/tag syntax for filtering (e.g., pytest markers, go build tags)
