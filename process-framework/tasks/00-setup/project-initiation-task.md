---
id: PF-TSK-059
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.4
created: 2026-02-16
updated: 2026-06-03
description: "Initial project setup including ../doc/project-config.json creation"
---

# Project Initiation

## Purpose & Context

Establishes foundational project configuration and metadata when initializing a new project or adapting the process framework for a different domain. Creates the `project-config.json` file that serves as the central source of truth for project-specific settings, paths, and metadata used by automation scripts and documentation generators.

## AI Agent Role

**Role**: Project Setup Specialist
**Mindset**: Methodical, detail-oriented, focused on establishing clear foundations
**Focus Areas**: Configuration accuracy, path structure consistency, metadata completeness
**Communication Style**: Ask clarifying questions about project details, confirm critical decisions, explain configuration choices

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

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
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
   > If yes: after Project Initiation completes, follow the [Architecture-First workflow](../../ai-tasks.md#for-greenfield-projects-architecture-first) to implement 0.x features before business features.
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
       "process_framework": "process-framework",
       "product_docs": "doc",
       "source_code": "[src directory name]",
       "tests": "[test directory name]",
       "test_tracking_dir": "test/state-tracking/permanent",
       "e2e_test_tracking_dir": "test/state-tracking/permanent",
       "performance_test_tracking_dir": "test/state-tracking/permanent",
       "scripts": "scripts",
       "examples": "examples"
     },

     "testing": {
       "description": "Test runner configuration — language-specific commands are in process-framework/languages-config/{language}/{language}-config.json",
       "language": "[Language name matching a subdirectory in process-framework/languages-config/, e.g. 'python' or 'dart']",
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
     },

     "recommended_skills": {
       "description": "Claude Code skills recommended for specific tasks. Each key under 'tasks' is a task slug (task filename without .md); value is an array of {skill, note} objects. Language-bound skills go in languages-config instead. Populated during Step 10a — leave 'tasks' empty here.",
       "tasks": {}
     },

     "layering_rules": {
       "description": "Per-project layer dependency rules — source of truth for layer-boundary checks at Code Quality Standards Validation (PF-TSK-032). Empty 'layers' = no enforcement (the default). Populate during onboarding (PF-TSK-064/066) or after ADRs codify layer boundaries; see source-code-layout-guide.md.",
       "layers": [],
       "cross_feature_isolation": { "enabled": false }
     },

     "project_id": null
   }
   ```

8. **Customize Field Values**: Replace all placeholders `[...]` with actual project-specific values:
   - Use Windows path format with double backslashes (`\\`) for paths on Windows
   - Use forward slashes (`/`) for relative paths in the `paths` section
   - Set values to `null` for optional fields that don't apply
   - **Leave at their defaults** (do not hand-fill here): `project_id` stays `null` — `Register-Project.ps1` writes it at Step 19; `recommended_skills.tasks` stays `{}` — populated at Step 10a; `layering_rules.layers` stays `[]` — populated during onboarding or once ADRs codify layer boundaries
   - **`paths.source_code`**: Set to the actual source directory name (e.g., `src`, `lib`, `app`). Do **not** leave as `"."` — this value drives the [Source Code Layout](../../../doc/technical/architecture/source-code-layout.md) scaffold script and validation. The `source-code-layout.md` file should already exist at `doc/technical/architecture/` (created from the blueprint template). No directories are created at this point — that is deferred to Codebase Feature Discovery (PF-TSK-064) after features are known.
   - **`paths.test_tracking_dir` / `paths.e2e_test_tracking_dir` / `paths.performance_test_tracking_dir`**: Parameterize where each tracking file lives. Defaults match historical hardcoded behavior (`test/state-tracking/permanent`) and should be left as-is for new projects. Used by framework scripts that read/write the three tracking files (e.g., `Run-Tests.ps1`, `Update-WorkflowTracking.ps1`, `Validate-StateTracking.ps1`). Introduced by the Framework Self-Testing extension (PF-PRO-035) so appdev (PRJ-000) can host its own framework-self-test workspace state outside the default location.

9. **Validate the configuration**: Run the validator to confirm valid JSON syntax, populated load-bearing fields, and no unreplaced `[...]` placeholders:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Validate-ProjectConfig.ps1
   ```
   Fix any reported errors and re-run until it prints `✅ project-config.json is valid`. The `project_id is null` informational note is expected at this point — `Register-Project.ps1` sets it at Step 19.
10. **Set Up Language Configuration**: Check if `process-framework/languages-config/{language}/{language}-config.json` exists for the project's language. If not, copy the [language config template](../../templates/support/language-config-template.json) to `process-framework/languages-config/{language}/{language}-config.json` and fill in language-specific values (test runner, coverage, lint commands). See [languages-config README](../../languages-config/README.md).

    > **New-to-framework language?** If neither the language config nor a per-language test runner exists for this project's language, create both before continuing:
    >
    > 1. Copy [`templates/support/language-config-template.json`](../../templates/support/language-config-template.json) to `process-framework/languages-config/{language}/{language}-config.json` and fill in test runner / coverage / lint commands.
    > 2. Copy [`templates/support/Run-Tests-runner-template.ps1`](../../templates/support/Run-Tests-runner-template.ps1) to `process-framework/scripts/language-specific-scripts/{language}/Run-Tests.{language}.ps1` and adapt it to the language's test framework (the top-level `Run-Tests.ps1` dispatcher reads `testing.language` from `project-config.json` and routes to this per-language runner via `Resolve-TestLanguageRunner` from `TestRunner.psm1`).
    > 3. Add the new language as a row in [`languages-config/README.md`](../../languages-config/README.md)'s Available Configurations table.
    >
    > Languages already shipped: `python` (pytest) and `powershell` (Pester). Skip this expansion when the project's language is one of those.

10a. **Populate Recommended Skills**: Check which Claude Code skills are available in the current session (listed in the system context). Match them against the project's technology stack (`project_metadata.primary_language`, `project_metadata.framework`, `project_metadata.platform`) and populate:
    - **Language-config** `recommended_skills` — for skills tied to the project's language/UI technology (e.g., `frontend-design` for JS/TS web projects → `ui-implementation`, `foundation-feature-implementation`)
    - **Project-config** `recommended_skills.tasks` — for project-level skills not tied to a language (e.g., `playwright` for web projects → `e2e-acceptance-test-execution`; `claude-api` for Claude-consuming projects → `foundation-feature-implementation`, `core-logic-implementation`)

    Each entry is an object with `skill` (skill name) and `note` (one-line purpose). Task slugs are task definition filenames without `.md`. Use the seed mapping table below as a starting point — adapt to the project's actual needs:

    | Skill | Config Location | Applicable Tasks | Note |
    |---|---|---|---|
    | `frontend-design` | Language-config (JS/TS) | `ui-implementation`, `foundation-feature-implementation` | Aesthetic design guardrails for web UI code generation |
    | `webapp-testing` | Language-config (JS/TS) | `integration-and-testing` | Web app test automation |
    | `playwright` | Project-config (web projects) | `e2e-acceptance-test-execution` | Browser automation for E2E testing |
    | `claude-api` | Project-config (Claude-consuming) | `foundation-feature-implementation`, `core-logic-implementation` | Claude API integration patterns |

    > Skip if no available skills match the project's technology stack. The `recommended_skills` fields remain empty arrays / empty objects — consuming tasks handle absence silently.

11. **Apply Language Customizations to Test Tree**: The blueprint copy already provides the test directory structure — including the fixed bones `test/automated/unit/`, `test/automated/performance/level{1-4}-*/`, `test/audits/{unit,performance/level{1-4}-*,e2e}/`, `test/e2e-acceptance-testing/`, and `test/bug-validation/` (top-level since PF-IMP-871 Phase 2b — formerly under `test/automated/`) — along with tracking files (`test-tracking.md`, `e2e-test-tracking.md`, `performance-test-tracking.md`) and `TE-id-registry.json`. Run `New-TestInfrastructure.ps1 -Scaffold` to layer the language-specific customizations on top:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/00-setup/New-TestInfrastructure.ps1 -Language "<language>"
   ```
   This applies: shared fixture file (e.g., `conftest.py` for Python), package marker files (e.g., `__init__.py`), `.gitignore` for E2E workspace/results, and idempotent verification of the tracking files inherited from the blueprint copy. It also creates `test/bug-validation/` if missing (defensive for projects bootstrapped without a current blueprint copy). See the [Test Infrastructure Guide](../../guides/03-testing/test-infrastructure-guide.md) for details.
   - **Scaffold vs Update mode**: `-Scaffold` (the default, used here) layers language customizations + defensively creates fixed bones. The companion `-Update` mode (auto-invoked later by `New-FeatureImplementationState.ps1` and `New-WorkflowEntry.ps1`) scaffolds the *variable* parts of the tree — per-feature-category subdirs under `automated/unit/` and per-workflow subdirs under `e2e-acceptance-testing/` — driven by feature-tracking.md + user-workflow-tracking.md. Both modes are idempotent and mutually exclusive (`ParameterSetName`).
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

13. **Set Up CI/CD Infrastructure** (optional): Follow the [CI/CD Setup Guide](../../guides/07-deployment/ci-cd-setup-guide.md) to scaffold development tooling:
    - Create pre-commit hooks config (`.pre-commit-config.yaml`)
    - Create dev script (`dev.bat` / `dev.sh`)
    - Create CI pipeline (if using a Git hosting platform)

13a. **Note the Release Process Guide stub** (passive reference — no action now): The blueprint ships a structured Release Process Guide stub at [`doc/ci-cd/release-process.md`](../../../doc/ci-cd/release-process.md) (the project's `PD-CIC` instance, generated from the [Release Process Guide template](../../templates/07-deployment/release-process-guide-template.md)). It is intentionally **unfilled** — its **Freshness Stamp** reads `unverified` — so that [Release & Deployment (PF-TSK-008)](../07-deployment/release-deployment-task.md)'s Critical Must-Read reference resolves from day one. Fill in its deploy / version / distribute mechanics and re-set the Freshness Stamp when the project's first release approaches; an onboarded project instead captures its existing release process into this stub during [Retrospective Documentation Creation](retrospective-documentation-creation.md) Phase 4. This mirrors the `source-code-layout.md` treatment in Step 8 — a blueprint-shipped stub plus a passive reference, populated later when the information is known.

14. **Set Up SessionStart Hooks**: Add a `SessionStart` hook block to `.claude/settings.json` that automates startup-procedure steps as deterministic side effects rather than agent-honored CLAUDE.md instructions. Anthropic's Opus 4.7 (April 2026) regressed on CLAUDE.md instruction adherence; agents began silently skipping startup steps that the doc instructed but the harness did not enforce ([PF-IMP-854](#)). Moving startup mechanics into hooks sidesteps the regression — the side effects happen whether the agent obeys text instructions or not.

    Three hooks are included by default:

    ```json
    {
      "$schema": "https://json.schemastore.org/claude-code-settings.json",
      "hooks": {
        "SessionStart": [
          {
            "hooks": [
              {
                "type": "command",
                "command": "pwsh.exe -ExecutionPolicy Bypass -File process-framework/tools/linkWatcher/start_linkwatcher_hook_wrapper.ps1"
              },
              {
                "type": "command",
                "command": "pwsh.exe -Command \"Write-Output ('Session start: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))\""
              },
              {
                "type": "command",
                "command": "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"Before any tool call, select a task from process-framework/ai-tasks.md. For purely conversational questions (e.g. what time is it), name *no task — conversational* and proceed. Acknowledge the chosen task in your first reply, even for analytical or meta questions about the framework.\"}}'"
              }
            ]
          }
        ]
      }
    }
    ```

    What each hook does:

    - **Hook 1 — LinkWatcher startup**: Invokes [start_linkwatcher_hook_wrapper.ps1](../../tools/linkWatcher/start_linkwatcher_hook_wrapper.ps1), which calls the sibling [start_linkwatcher_background.ps1](../../tools/linkWatcher/start_linkwatcher_background.ps1) inside a `Start-Process` + `WaitForExit(8000)` isolation envelope. The wrapper is required because the LinkWatcher daemon inherits stdout handles — invoking the startup script directly from a stdout-capturing hook hangs the session ([documented in the startup script's header](../../tools/linkWatcher/start_linkwatcher_background.ps1)). Idempotent — the startup script detects an already-running instance via lock file and no-ops.
    - **Hook 2 — Session start timestamp**: Emits a single line `Session start: YYYY-MM-DD HH:mm:ss` into initial context. The agent uses this when calculating session duration for feedback forms (PF-TSK-XXX completion checklists).
    - **Hook 3 — Task-selection reminder**: Reinforces the framework's task-discipline gate. Edit the `additionalContext` string to add project-specific routing hints if a particular task category is frequently misrouted.

    Settings:

    - **File location**: `.claude/settings.json` (committed to git, team-wide). `.claude/settings.local.json` is gitignored and won't propagate to collaborators.
    - **Take effect**: only at the *next* session start (the hook config is loaded at session-start time). After saving the file, run `/hooks` in Claude Code or start a new session to activate.
    - **Verify**: at the next session start, initial context should contain (a) a LinkWatcher startup line, (b) the timestamp line, and (c) the task-selection reminder being applied (the agent acknowledges a task in its first reply).
    - **If LinkWatcher is not installed for this project**: omit Hook 1. Hooks 2 and 3 still apply.

    **Per-project broken-link validation config**: If LinkWatcher is installed, create the project's validation config so the broken-link scan ([run_linkwatcher_validate.ps1](../../tools/linkWatcher/run_linkwatcher_validate.ps1)) honors any per-folder path overrides. Copy the framework template into the project:

    ```bash
    New-Item -ItemType Directory -Force tools/linkwatcher | Out-Null
    Copy-Item process-framework/tools/linkWatcher/linkwatcher-config.template.yaml tools/linkwatcher/linkwatcher-config.yaml
    ```

    Then make a conscious per-project decision: leave `path_resolution_overrides: {}` empty (the default — a no-op) **unless** this project has a folder that ships to other projects as a root (e.g. a `blueprint/` or `example/` template tree whose `/...` links are authored from the rollout target's perspective), in which case map that folder to itself (e.g. `blueprint: blueprint`). The launcher auto-passes this config to `--validate`.

15. **🚨 CHECKPOINT**: Present completed project-config.json, language config, test infrastructure, documentation taxonomy, and CI/CD setup to human partner for review before finalization

### Finalization

16. **Verify File Location**: Confirm `project-config.json` is in `doc/` and language config is in `languages-config`

17. **Test Configuration**: Verify the full setup works:
    - `Run-Tests.ps1 -ListCategories` shows test categories
    - `Run-Tests.ps1 -Quick` runs successfully (if test files exist)
    - `pre-commit run --all-files` passes (if pre-commit was set up)
    - `dev test` works (if dev script was created)

18. **Document Project-Specific Notes**: If there are any non-standard configurations or important context, add comments to this task or create a project README

19. **Register Project in Appdev Central Registry**: This step assigns the project a stable `PRJ-NNN` ID and adds it to appdev's `project-registry.json`. The script also writes the assigned `project_id` back into the project's own `doc/project-config.json`, which downstream framework scripts (state-creating, ID-assigning) read to route appropriately.

    > **⚙️ This step runs from `cwd=appdev`**, NOT from the new project's cwd. Temporarily switch contexts, run the command, then return to the project cwd for the remaining task completion items.

    From `cwd=appdev`:
    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File blueprint/process-framework/scripts/file-creation/support/Register-Project.ps1 -Path "<absolute-path-to-new-project>" -Name "<project-name>" -AppdevPath "<absolute-path-to-appdev>" -Confirm:\$false
    ```

    The script:
    - Assigns the next `PRJ-NNN` from `<appdev>/process-framework-central/PF-id-registry-central.json` (PRJ pool).
    - Adds an entry to `<appdev>/process-framework-central/project-registry.json`.
    - Writes `"project_id": "PRJ-NNN"` into `<new-project>/doc/project-config.json`.
    - Creates `<appdev>/process-framework-central/per-project-migrations/PRJ-NNN/` with a `pending-migrations.md` skeleton.

    **🚨 CHECKPOINT**: After the script completes, return to `cwd=Project` and confirm `project_id: "PRJ-NNN"` appears in the new project's `doc/project-config.json`.

20. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Git repository** - Initialized git repo at project root with `.gitignore` and optional remote
- **project-config.json** - JSON configuration file created at `doc/project-config.json` containing:
  - Project identification (name, display name, description, repository URL)
  - Directory path mappings (documentation, source code, tests, scripts)
  - Testing configuration (language, test directory, quick categories)
  - Project metadata (language, framework, platform, development approach)
  - Team composition and collaboration model
  - Integration configurations (issue tracker, CI/CD, code hosting)
- **Language config** (if new) - `process-framework/languages-config/{language}/{language}-config.json` with language-specific test runner commands
- **Test infrastructure** - Test directory structure, test runner config, shared fixtures, empty `test-tracking.md`
- **CI/CD infrastructure** (optional) - Pre-commit hooks, dev script, CI pipeline
- **SessionStart hooks** - `.claude/settings.json` `SessionStart` hook block with three commands: LinkWatcher background startup (via wrapper), session start timestamp, and task-selection reminder (PF-IMP-854)
- **LinkWatcher validation config** (if LinkWatcher installed) - `tools/linkwatcher/linkwatcher-config.yaml`, copied from the framework template and configured (empty `{}` by default; per-folder `path_resolution_overrides` only if the project has a shippable-root folder)
- **Release Process Guide stub** (noted, not created) - The blueprint-shipped Release Process Guide stub at `doc/ci-cd/release-process.md` (`PD-CIC`) is present and acknowledged via the passive reference (Step 13a); filled in later when the project's release mechanics are known
- **Project registration** - `PRJ-NNN` ID assigned in appdev's `project-registry.json`; `project_id` field written into the project's `doc/project-config.json`; per-project migration ledger created at `<appdev>/process-framework-central/per-project-migrations/PRJ-NNN/`

## State Tracking

### New State Files Created

- **project-config.json** (PERMANENT):
  - Location: `doc/project-config.json`
  - Purpose: Central source of truth for project-specific settings, paths, and metadata used by automation scripts
  - Lifecycle: Permanent (never archived)

- **Language config** (PERMANENT, conditional — only if not already present):
  - Location: `process-framework/languages-config/{language}/{language}-config.json`
  - Purpose: Language-specific command configurations for test runner, coverage, and lint tools
  - Lifecycle: Permanent (never archived)

- **Per-project migration ledger** (PERMANENT, in appdev):
  - Location: `<appdev>/process-framework-central/per-project-migrations/PRJ-NNN/pending-migrations.md`
  - Purpose: Tracks per-project working-doc migrations queued by Structure Change task; applied by Framework Rollout Mode C
  - Lifecycle: Permanent; entries added/resolved over time by Structure Change + Framework Rollout work

### Existing State Files Updated

- **appdev's `process-framework-central/project-registry.json`**: a new entry is appended for the registered project (keyed by `PRJ-NNN`).
- **appdev's `process-framework-central/PF-id-registry-central.json`**: the `PRJ` prefix's `nextAvailable` counter is incremented.

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Git repository initialized at project root (`.git` directory exists)
  - [ ] `.gitignore` exists with language-appropriate exclusions
  - [ ] No parent directory has a `.git` that would shadow this repo
  - [ ] Remote configured (if applicable)
  - [ ] `project-config.json` file exists at `doc/project-config.json`
  - [ ] All required fields are populated with project-specific values (no `[...]` placeholders remain)
  - [ ] `Validate-ProjectConfig.ps1` reports `✅ project-config.json is valid` (valid JSON, load-bearing fields populated, no leftover placeholders)
  - [ ] Paths use correct format (double backslashes for absolute Windows paths, forward slashes for relative paths)
  - [ ] Project metadata accurately reflects the technology stack and setup

- [ ] **Validation**: Ensure configuration is functional
  - [ ] File is readable by automation scripts (if applicable)
  - [ ] Path mappings correspond to actual directory structure
  - [ ] Repository URL is accessible (if provided)
  - [ ] `Run-Tests.ps1 -ListCategories` discovers test categories
  - [ ] Test runner config exists (e.g., `pytest.ini`)
  - [ ] Shared fixtures/setup file exists (e.g., `conftest.py`)
  - [ ] LinkWatcher validation config exists at `tools/linkwatcher/linkwatcher-config.yaml` and was consciously configured (N/A if LinkWatcher is not installed)
  - [ ] Release Process Guide stub at `doc/ci-cd/release-process.md` is present (blueprint-shipped) and was noted for later fill-in (Step 13a — no action required now)
  - [ ] Pre-commit hooks work (if configured): `pre-commit run --all-files`

- [ ] **Project Registration**: Confirm the project is registered in appdev's central registry
  - [ ] `project_id: "PRJ-NNN"` field is present in `doc/project-config.json`
  - [ ] Appdev's `process-framework-central/project-registry.json` contains an entry for the new `PRJ-NNN`
  - [ ] Per-project migration ledger directory exists at `<appdev>/process-framework-central/per-project-migrations/PRJ-NNN/`

- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for task ID "PF-TSK-059" and context "Project Initiation"

## Next Tasks

- [**Codebase Feature Discovery (PF-TSK-064)**](codebase-feature-discovery.md) - When adopting the framework into an **existing codebase**: Discovery's source-structure step (Step 7.f) consumes the `project-config.json` and `source-code-layout.md` produced here.
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
