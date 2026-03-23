---
id: PF-TSK-059
type: Process Framework
category: Task Definition
version: 1.1
created: 2026-02-16
updated: 2026-03-22
task_type: Support
---

# Project Initiation

## Purpose & Context

Establishes foundational project configuration and metadata when initializing a new project or adapting the process framework for a different domain. Creates the `project-config.json` file that serves as the central source of truth for project-specific settings, paths, and metadata used by automation scripts and documentation generators.

## AI Agent Role

**Role**: Project Setup Specialist
**Mindset**: Methodical, detail-oriented, focused on establishing clear foundations
**Focus Areas**: Configuration accuracy, path structure consistency, metadata completeness
**Communication Style**: Ask clarifying questions about project details, confirm critical decisions, explain configuration choices

## When to Use

- When starting a new project that will use the process framework
- When adapting the process framework to a different business domain or technology stack
- When project structure or naming conventions have fundamentally changed and need re-initialization
- Before running any automation scripts that depend on project-config.json

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/support/project-initiation-map.md)

- **Critical (Must Read):**

  - [Example project-config.json](../../project-config.json) - Reference template showing required structure and fields
  - **Project Information** - Human-provided: project name, description, repository URL, root directory path

- **Important (Load If Space):**

  - [Process Framework README](../../README.md) - Understanding framework structure and directory organization
  - [ID Registry](../../../id-registry.json) - Understanding ID prefixes and directory mappings for path configuration

- **Reference Only (Access When Needed):**
  - [Documentation Structure Guide](../../guides/framework/documentation-structure-guide.md) - For understanding recommended directory structure
  - [Framework Domain Adaptation](framework-domain-adaptation.md) - For comprehensive framework customization beyond config file

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Gather Project Information**: Collect the following details from human partner:
   - Project name (technical name, e.g., "LinkWatcher")
   - Display name (user-friendly name, e.g., "LinkWatcher 2.0")
   - Project description (1-2 sentences)
   - Absolute path to project root directory
   - Repository URL (if applicable)

2. **Review Example Configuration**: Read the [example project-config.json](../../project-config.json) to understand the required structure

3. **Identify Project Paths**: Determine the project's directory structure:
   - Documentation root directory
   - Process framework location
   - Source code directory
   - Tests directory
   - Scripts directory
4. **🚨 CHECKPOINT**: Present gathered project information and identified paths to human partner for confirmation before creating configuration file

### Execution

5. **Create project-config.json File**: At the project root directory, create `project-config.json` with the following structure:

   ```json
   {
     "$schema": "https://json-schema.org/draft/2020-12/schema",
     "description": "Project-specific configuration for this instance of the process framework",
     "version": "1.0",

     "project": {
       "name": "[TechnicalProjectName]",
       "display_name": "[User-Friendly Display Name]",
       "description": "[Brief project description]",
       "root_directory": "[Absolute path to project root]",
       "repository_url": "[Repository URL or null]"
     },

     "paths": {
       "description": "Project-specific directory paths relative to root",
       "documentation_root": "doc",
       "process_framework": "doc/product-docs",
       "source_code": "[src directory name]",
       "tests": "[test directory name]",
       "scripts": "scripts"
     },

     "testing": {
       "description": "Test runner configuration — language-specific commands are in languages-config/{language}-config.json",
       "language": "[Language name matching a file in languages-config/, e.g. 'python' or 'dart']",
       "testDirectory": "[Test directory relative to root, e.g. 'test/automated']",
       "quickCategories": ["[subdirectory names for -Quick flag, e.g. 'unit', 'widget']"]
     },

     "project_metadata": {
       "primary_language": "[Primary programming language]",
       "framework": "[Framework name or N/A]",
       "platform": "[Target platform]",
       "development_approach": "Task-based development with AI-assisted workflow",
       "documentation_style": "Markdown with frontmatter metadata"
     },

     "team": {
       "description": "Team composition and roles",
       "primary_developer": "[Developer name]",
       "ai_assistant": "[AI assistant name]",
       "collaboration_model": "Human-AI pair programming"
     },

     "integration": {
       "description": "Integration with project-specific tools and systems",
       "issue_tracker": "[Issue tracker URL or null]",
       "ci_cd_platform": "[CI/CD platform name or null]",
       "code_hosting": "[Code hosting platform]",
       "documentation_hosting": "[Documentation hosting location]"
     }
   }
   ```

6. **Customize Field Values**: Replace all placeholders `[...]` with actual project-specific values:
   - Use Windows path format with double backslashes (`\\`) for paths on Windows
   - Use forward slashes (`/`) for relative paths in the `paths` section
   - Set values to `null` for optional fields that don't apply

7. **Validate JSON Syntax**: Ensure the file is valid JSON (check for missing commas, brackets, quotes)
8. **Set Up Language Configuration**: Check if `languages-config/{language}-config.json` exists for the project's language. If not, copy the [language config template](/doc/process-framework/templates/support/language-config-template.json) to `languages-config/{language}-config.json` and fill in language-specific values (test runner, coverage, lint commands). See [languages-config README](/doc/process-framework/languages-config/README.md).

9. **Set Up Testing Infrastructure**: Follow the [Testing Setup Guide](/doc/process-framework/guides/03-testing/testing-setup-guide.md) to scaffold the test environment:
   - Create test directory structure matching `project-config.json` categories
   - Create test runner config (e.g., `pytest.ini` for Python)
   - Create shared fixtures/setup file (e.g., `conftest.py` for Python)
   - Update `testSetup` section in language config
   - Initialize empty `test-registry.yaml` and `test-tracking.md`

10. **Set Up CI/CD Infrastructure** (optional): Follow the [CI/CD Setup Guide](/doc/process-framework/guides/07-deployment/ci-cd-setup-guide.md) to scaffold development tooling:
    - Create pre-commit hooks config (`.pre-commit-config.yaml`)
    - Create dev script (`dev.bat` / `dev.sh`)
    - Create CI pipeline (if using a Git hosting platform)

11. **🚨 CHECKPOINT**: Present completed project-config.json, language config, test infrastructure, and CI/CD setup to human partner for review before finalization

### Finalization

12. **Verify File Location**: Confirm `project-config.json` is in the project root directory and language config is in `languages-config/`

13. **Test Configuration**: Verify the full setup works:
    - `Run-Tests.ps1 -ListCategories` shows test categories
    - `Run-Tests.ps1 -Quick` runs successfully (if test files exist)
    - `pre-commit run --all-files` passes (if pre-commit was set up)
    - `dev test` works (if dev script was created)

14. **Document Project-Specific Notes**: If there are any non-standard configurations or important context, add comments to this task or create a project README

15. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **project-config.json** - JSON configuration file created at project root directory containing:
  - Project identification (name, display name, description, repository URL)
  - Directory path mappings (documentation, source code, tests, scripts)
  - Testing configuration (language, test directory, quick categories)
  - Project metadata (language, framework, platform, development approach)
  - Team composition and collaboration model
  - Integration configurations (issue tracker, CI/CD, code hosting)
- **Language config** (if new) - `languages-config/{language}-config.json` with language-specific test runner commands
- **Test infrastructure** - Test directory structure, test runner config, shared fixtures, empty `test-registry.yaml` and `test-tracking.md`
- **CI/CD infrastructure** (optional) - Pre-commit hooks, dev script, CI pipeline

## State Tracking

No state files require updates for this task. The `project-config.json` itself serves as the persistent configuration state.

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] `project-config.json` file exists at project root directory
  - [ ] All required fields are populated with project-specific values (no `[...]` placeholders remain)
  - [ ] JSON syntax is valid (file can be parsed without errors)
  - [ ] Paths use correct format (double backslashes for absolute Windows paths, forward slashes for relative paths)
  - [ ] Project metadata accurately reflects the technology stack and setup

- [ ] **Validation**: Ensure configuration is functional
  - [ ] File is readable by automation scripts (if applicable)
  - [ ] Path mappings correspond to actual directory structure
  - [ ] Repository URL is accessible (if provided)
  - [ ] `Run-Tests.ps1 -ListCategories` discovers test categories
  - [ ] Test runner config exists (e.g., `pytest.ini`)
  - [ ] Shared fixtures/setup file exists (e.g., `conftest.py`)
  - [ ] Pre-commit hooks work (if configured): `pre-commit run --all-files`

- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for task ID "PF-TSK-059" and context "Project Initiation"

## Next Tasks

- [**Framework Domain Adaptation**](framework-domain-adaptation.md) - For comprehensive framework customization beyond configuration file (adapting task categories, document types, ID prefixes)
- **Begin Development Workflow** - Use appropriate task from [AI Tasks Registry](../../../ai-tasks.md) based on your next activity (feature planning, implementation, etc.)

## Related Resources

- [Example project-config.json](../../project-config.json) - Reference implementation from LinkWatcher project
- [Process Framework README](../../README.md) - Overview of framework structure and components
- [Framework Domain Adaptation](framework-domain-adaptation.md) - Comprehensive framework customization for new domains
- [Documentation Structure Guide](../../guides/framework/documentation-structure-guide.md) - Recommended directory organization patterns
- [ID Registry](../../../id-registry.json) - Document ID prefixes and directory mappings
- [Testing Setup Guide](../../guides/03-testing/testing-setup-guide.md) - Language-specific test infrastructure scaffolding
- [CI/CD Setup Guide](../../guides/07-deployment/ci-cd-setup-guide.md) - CI pipeline, pre-commit hooks, dev scripts
