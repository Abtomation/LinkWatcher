---
id: PF-TSK-059
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.2
created: 2026-02-16
updated: 2026-04-14
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

[View Context Map for this task](../../visualization/context-maps/00-setup/project-initiation-map.md)

- **Critical (Must Read):**

  - [Example project-config.json](../../../doc/project-config.json) - Reference template showing required structure and fields
  - **Project Information** - Human-provided: project name, description, repository URL, root directory path

- **Important (Load If Space):**

  - [Process Framework README](../../README.md) - Understanding framework structure and directory organization
  - [PF ID Registry](../../PF-id-registry.json) - Understanding ID prefixes and directory mappings for path configuration

- **Reference Only (Access When Needed):**
  - [Documentation Structure Guide](../../guides/framework/documentation-structure-guide.md) - For understanding recommended directory structure
  - [Framework Domain Adaptation](../support/framework-domain-adaptation.md) - For comprehensive framework customization beyond config file

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

2. **Review Example Configuration**: Read the [example project-config.json](../../../doc/project-config.json) to understand the required structure

3. **Identify Project Paths**: Determine the project's directory structure:
   - Documentation root directory
   - Process framework location
   - Source code directory
   - Tests directory
   - Scripts directory
4. **🚨 CHECKPOINT**: Present gathered project information and identified paths to human partner for confirmation before creating configuration file

5. **Decide on Foundation Category (0.x)**: Ask the human partner whether this project needs architectural foundation features before business features. Foundation features (0.x category) are appropriate when the project requires custom frameworks, core infrastructure patterns, or shared architectural enablers that business features will build on. This is an **opt-in decision** — not all projects need a foundation layer.
   > If yes: after Project Initiation completes, follow the [Architecture-First workflow](/process-framework/ai-tasks.md#for-greenfield-projects-architecture-first) to implement 0.x features before business features.
   >
   > If no: proceed directly to business feature workflows after Project Initiation.

### Execution

6. **Set Up Git Repository**: Discuss and agree with human partner on git configuration:
   - Where the git root should be (project root directory)
   - Confirm the project directory has its own `.git` (not inherited from a parent directory)
   - If a parent `.git` exists: warn the human partner — a repo rooted above the project tracks unrelated files and should be split
   - Initialize `git init` in the project root if no repo exists
   - Create an initial `.gitignore` appropriate for the project's language/framework (virtual environments, compiled files, databases, IDE files, OS files, backup files)
   - Set up remote repository if applicable (`git remote add origin <url>`)
   - **🚨 CHECKPOINT**: Confirm git setup with human partner before proceeding

7. **Create project-config.json File**: In the `doc/` directory, create `project-config.json` with the following structure:

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
       "process_framework": "doc",
       "source_code": "[src directory name]",
       "tests": "[test directory name]",
       "scripts": "scripts"
     },

     "testing": {
       "description": "Test runner configuration — language-specific commands are in languages-config/{language}/{language}-config.json",
       "language": "[Language name matching a subdirectory in languages-config/, e.g. 'python' or 'dart']",
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

8. **Customize Field Values**: Replace all placeholders `[...]` with actual project-specific values:
   - Use Windows path format with double backslashes (`\\`) for paths on Windows
   - Use forward slashes (`/`) for relative paths in the `paths` section
   - Set values to `null` for optional fields that don't apply
   - **`paths.source_code`**: Set to the actual source directory name (e.g., `src`, `lib`, `app`). Do **not** leave as `"."` — this value drives the [Source Code Layout](/doc/technical/architecture/source-code-layout.md) scaffold script and validation. The `source-code-layout.md` file should already exist at `doc/technical/architecture/` (created from the blueprint template). No directories are created at this point — that is deferred to Codebase Feature Discovery (PF-TSK-064) after features are known.

9. **Validate JSON Syntax**: Ensure the file is valid JSON (check for missing commas, brackets, quotes)
10. **Set Up Language Configuration**: Check if `languages-config/{language}/{language}-config.json` exists for the project's language. If not, copy the [language config template](/process-framework/templates/support/language-config-template.json) to `languages-config/{language}/{language}-config.json` and fill in language-specific values (test runner, coverage, lint commands). See [languages-config README](/process-framework/languages-config/README.md).

11. **Set Up Testing Infrastructure**: Run the bootstrapping script to scaffold the test environment:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/00-setup/New-TestInfrastructure.ps1 -Language "<language>"
   ```
   This creates: test directory structure, tracking files (`test-tracking.md`, `e2e-test-tracking.md`), `TE-id-registry.json`, shared fixtures, and package markers. See the [Test Infrastructure Guide](/process-framework/guides/03-testing/test-infrastructure-guide.md) for details.
   - After running: create native test runner config (e.g., `pytest.ini` for Python)
   - After running: install test dependencies (e.g., `pip install pytest pytest-cov`)

12. **Declare User Documentation Taxonomy** (in `doc/PD-id-registry.json`): Confirm or customize the documentation taxonomy for the project. The framework default follows the Diátaxis standard (tutorials / how-to / reference / explanation); you can accept these as-is or customize.

    Open [PD-id-registry.json](../../../doc/PD-id-registry.json) (created during framework adoption) and verify the `PD-UGD` prefix has the `subdirectories` (L1) and `topics` (L2) fields:

    ```json
    "PD-UGD": {
      "description": "Product Documentation - User Guides",
      "directories": { "handbooks": "doc/user/handbooks", "default": "handbooks" },
      "subdirectories": {
        "description": "L1: Diátaxis content type — the reader's cognitive mode",
        "values": ["tutorials", "how-to", "reference", "explanation"],
        "default": "how-to"
      },
      "topics": {
        "description": "L2: Project-specific topic/domain area — which part of the system the doc covers",
        "values": [],
        "default": null
      },
      "nextAvailable": 1
    }
    ```

    **Decisions to make**:
    - **L1 (content types)**: Accept Diátaxis defaults unless you have a strong reason to rename (e.g., `guides` instead of `how-to`). Keeping the standard aids onboarding.
    - **L2 (topics)**: Leave `values: []` for new projects — L2 becomes useful once any L1 directory exceeds ~15-20 docs. When you're ready, populate with the project's primary domain areas (e.g., `["networking", "storage", "security"]` for an infrastructure platform, `["auth", "payments", "users"]` for an API service). L2 represents **topic/domain area**, not audience segments or document formats.
    - Framework default is appropriate for 95% of projects; skip customization unless your domain strongly suggests otherwise.

13. **Set Up CI/CD Infrastructure** (optional): Follow the [CI/CD Setup Guide](/process-framework/guides/07-deployment/ci-cd-setup-guide.md) to scaffold development tooling:
    - Create pre-commit hooks config (`.pre-commit-config.yaml`)
    - Create dev script (`dev.bat` / `dev.sh`)
    - Create CI pipeline (if using a Git hosting platform)

14. **🚨 CHECKPOINT**: Present completed project-config.json, language config, test infrastructure, documentation taxonomy, and CI/CD setup to human partner for review before finalization

### Finalization

15. **Verify File Location**: Confirm `project-config.json` is in `doc/` and language config is in `languages-config`

16. **Test Configuration**: Verify the full setup works:
    - `Run-Tests.ps1 -ListCategories` shows test categories
    - `Run-Tests.ps1 -Quick` runs successfully (if test files exist)
    - `pre-commit run --all-files` passes (if pre-commit was set up)
    - `dev test` works (if dev script was created)

17. **Document Project-Specific Notes**: If there are any non-standard configurations or important context, add comments to this task or create a project README

18. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Git repository** - Initialized git repo at project root with `.gitignore` and optional remote
- **project-config.json** - JSON configuration file created at `doc/project-config.json` containing:
  - Project identification (name, display name, description, repository URL)
  - Directory path mappings (documentation, source code, tests, scripts)
  - Testing configuration (language, test directory, quick categories)
  - Project metadata (language, framework, platform, development approach)
  - Team composition and collaboration model
  - Integration configurations (issue tracker, CI/CD, code hosting)
- **Language config** (if new) - `languages-config/{language}/{language}-config.json` with language-specific test runner commands
- **Test infrastructure** - Test directory structure, test runner config, shared fixtures, empty `test-tracking.md`
- **CI/CD infrastructure** (optional) - Pre-commit hooks, dev script, CI pipeline

## State Tracking

### New State Files Created

- **project-config.json** (PERMANENT):
  - Location: `doc/project-config.json`
  - Purpose: Central source of truth for project-specific settings, paths, and metadata used by automation scripts
  - Lifecycle: Permanent (never archived)

- **Language config** (PERMANENT, conditional — only if not already present):
  - Location: `languages-config/{language}/{language}-config.json`
  - Purpose: Language-specific command configurations for test runner, coverage, and lint tools
  - Lifecycle: Permanent (never archived)

### Existing State Files Updated

None — this task creates foundational configuration before any state tracking files exist.

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Git repository initialized at project root (`.git` directory exists)
  - [ ] `.gitignore` exists with language-appropriate exclusions
  - [ ] No parent directory has a `.git` that would shadow this repo
  - [ ] Remote configured (if applicable)
  - [ ] `project-config.json` file exists at `doc/project-config.json`
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

- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for task ID "PF-TSK-059" and context "Project Initiation"

## Next Tasks

- [**Framework Domain Adaptation**](../support/framework-domain-adaptation.md) - For comprehensive framework customization beyond configuration file (adapting task categories, document types, ID prefixes)
- **Begin Development Workflow** - Use appropriate task from [AI Tasks Registry](../../ai-tasks.md) based on your next activity (feature planning, implementation, etc.)

## Related Resources

- [Example project-config.json](../../../doc/project-config.json) - Reference implementation from LinkWatcher project
- [Process Framework README](../../README.md) - Overview of framework structure and components
- [Framework Domain Adaptation](../support/framework-domain-adaptation.md) - Comprehensive framework customization for new domains
- [Documentation Structure Guide](../../guides/framework/documentation-structure-guide.md) - Recommended directory organization patterns
- [PF ID Registry](../../PF-id-registry.json) - Document ID prefixes and directory mappings
- [Test Infrastructure Guide](../../guides/03-testing/test-infrastructure-guide.md) - Test directory structure, tracking, and scaffolding
- [CI/CD Setup Guide](../../guides/07-deployment/ci-cd-setup-guide.md) - CI pipeline, pre-commit hooks, dev scripts
