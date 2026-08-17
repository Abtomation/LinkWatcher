# Language Configurations

This directory contains language-specific configuration files and templates used by framework scripts (e.g., `Run-Tests.ps1`).

## Directory Structure

Each supported language has its own subdirectory:

```
languages-config/
├── python/
│   └── python-config.json
├── powershell/
│   └── powershell-config.json
├── dart/
│   └── dart-config.json
├── README.md
```

## How It Works

1. `project-config.json` specifies `testing.language` (e.g., `"python"`, `"powershell"`)
2. Top-level `Run-Tests.ps1` reads `testing.language` and **dispatches** to `scripts/language-specific-scripts/<language>/Run-Tests.<language>.ps1` (Framework Self-Testing extension, PF-PRO-035, Phase 3a 2026-05-17)
3. The per-language runner loads `languages-config/{language}/{language}-config.json` for language-specific commands
4. Project-specific settings (test directory, module name, quick categories) stay in `project-config.json`

### Dispatcher + Per-Language-Runner Pattern

```
Run-Tests.ps1 (dispatcher, ~50 lines)
  ├─ Reads testing.language from doc/project-config.json
  └─ Dispatches via Resolve-TestLanguageRunner (TestRunner.psm1) to:
       ├─ scripts/language-specific-scripts/python/Run-Tests.python.ps1     (pytest)
       ├─ scripts/language-specific-scripts/powershell/Run-Tests.powershell.ps1  (Pester)
       └─ scripts/language-specific-scripts/dart/Run-Tests.dart.ps1         (flutter test)
```

This pattern lets each language own its parsing/output conventions (e.g., pytest's per-test result regex vs. Pester's PesterResult object) without leaking those into a "language-agnostic" core that's actually language-specific.

## Available Configurations

| Directory | Language | Test Runner | Per-Language Runner |
|-----------|----------|-------------|--------------------|
| `python/` | Python | pytest | `scripts/language-specific-scripts/python/Run-Tests.python.ps1` |
| `powershell/` | PowerShell | Pester 5+ | `scripts/language-specific-scripts/powershell/Run-Tests.powershell.ps1` |
| `dart/` | Dart (Flutter) | flutter test | `scripts/language-specific-scripts/dart/Run-Tests.dart.ps1` |

## Adding a New Language

When introducing a language new to the framework, **both** a language-config AND a per-language runner must be created — **in the appdev blueprint's `process-framework/` tree, not in a project's copy** (the rollout mirror deletes project-local additions under `process-framework/`; projects receive the pack via bootstrap/rollout):

1. **Language config**: create a subdirectory matching the language name (e.g., `javascript/`); copy the [language config template](../templates/support/language-config-template.json) to `{language}/{language}-config.json`; fill in the values (remove `_comment_*` fields when done). Include the optional `doc_extraction` block so the language's source files join the Source Code Documentation Map (`Build-DocumentationMap.ps1 -Tree SC`) — the declared markers drive the generic extractor, no framework-script edit needed; only a convention that doesn't fit the marker model needs a bespoke function in `DescriptionExtraction.psm1`.
2. **Per-language runner**: copy [`Run-Tests-runner-template.ps1`](../templates/support/Run-Tests-runner-template.ps1) to `scripts/language-specific-scripts/{language}/Run-Tests.{language}.ps1`; customize the marked sections (category discovery, framework availability check, test invocation).
3. **Set `testing.language`** in the adopting project's `project-config.json` to match the directory name.

> [Project Initiation (PF-TSK-059)](../tasks/00-setup/project-initiation-task.md)'s language-configuration step routes this blueprint-side authoring when a project's language is new to the framework.

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
- `{srcDir}` — source directory path (from `project-config.json` → `paths.source_code`)

### Optional Fields

- `testing.lintCommand` — lint command for **test files**, run by `Run-Tests.<language>.ps1 -Lint` (omit if language has no lint tool configured)
- `testing.staticAnalysisCommand` — static analyzer for **source code**, run by `Quick-ValidationCheck.ps1` CodeQuality checks (omit to skip that check instead of failing it)
- `testing.coverageFullArgs` — extended coverage flags (XML output, term-missing, etc.)
- `testing.markers` — test marker/tag syntax for filtering (e.g., pytest markers, go build tags)

### CLI vs Programmatic Runners

Test runners come in two invocation styles, which determines how the command-string fields are used:

- **CLI runners** (e.g. pytest, `dart test`, `go test`) — the per-language runner executes the `baseCommand` / coverage / discovery strings directly. Fill these fields with the real commands and flags.
- **Programmatic runners** (e.g. Pester via `Invoke-Pester`) — the per-language runner constructs the invocation in code (e.g. a Pester configuration object), not from a CLI string. The command-string fields (`baseCommand`, `coverageArgs`, `coverageFullArgs`, `discoveryCommand`, `stopOnFirstFailure`, `verboseFlag`) are **documentary-only**: fill them in for reference and parity with other configs, but the runner builds the actual call. See [`powershell/powershell-config.json`](powershell/powershell-config.json) for a worked example — each documentary field is annotated in its `_comment_`.
