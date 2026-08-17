---
id: PF-TSK-059
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.15
created: 2026-02-16
updated: 2026-08-12
change_notes: "v1.8 - PF-IMP-1770: Step 18 + completion-checklist gate list extended with the two corruption guards (no-git-objects-literal, no-nul-bytes), matching the completed CI/CD Setup Guide framework-gate set. v1.7 - PF-IMP-1435 corridor restructure: two-phase structure with a single context switch - Phase A (appdev session: gather/confirm, blueprint bootstrap, registration, first framework push) then Phase B (project session: everything project-local). Full renumber; external step references converted to descriptive names. Fixes the v1.6 bootstrap-before-path-gathering ordering defect; restores the Design Guidelines opt-in step dropped by v1.6; first push folded in from PF-TSK-088 Mode B (delegation note there); LinkWatcher validation config now bootstrap-seeded from blueprint/tools/linkwatcher"
description: "Initial project setup including ../doc/project-config.json creation"
complexity: medium
use_when: >-
  Starting a new project or adapting the process framework to a new domain
automation: semi
scripts:
  - ../../scripts/file-creation/00-setup/New-TestInfrastructure.ps1
  - ../../scripts/validation/Validate-ProjectConfig.ps1
  - ../../scripts/file-creation/support/Register-Project.ps1
  - ../../scripts/rollout/Push-FrameworkUpdate.ps1
trigger_status:
  - raw: "_(user request)_"
output_status:
  - raw: "Creates `project-config.json`, test infra; registers the project and delivers its first framework push (version stamps + central pointer); synthesizes the **Product Concept** (`doc/founding/product-concept.md`, `PD-DOC-001`) from the founding inputs in `doc/founding/inputs/`; notes the blueprint-shipped **Release Process Guide stub** (`doc/ci-cd/release-process.md`, `PD-CIC` — passive reference) for later fill-in _(no tracking status)_"
next_tasks:
  - task: codebase-feature-discovery.md
    condition: "When adopting the framework into an **existing codebase**: Discovery's source-structure step (Step 7.f) consumes the `project-config.json` and `source-code-layout.md` produced here."
  - task: ../support/framework-domain-adaptation.md
    condition: "For comprehensive framework customization beyond configuration file (adapting task categories, document types, ID prefixes)"
---

# Project Initiation

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Establishes foundational project configuration and metadata when initializing a new project or adapting the process framework for a different domain. Creates the `project-config.json` file that serves as the central source of truth for project-specific settings, paths, and metadata used by automation scripts and documentation generators.

## AI Agent Role

**Role**: Project Setup Specialist
**Mindset**: Methodical, detail-oriented, focused on establishing clear foundations
**Focus Areas**: Configuration accuracy, path structure consistency, metadata completeness
**Communication Style**: Ask clarifying questions about project details, confirm critical decisions, explain configuration choices

## Context Requirements

- **Critical (Must Read):**

  - [Example project-config.json](../../../doc/project-config.json) - Reference template showing required structure and fields
  - **Project Information** - Human-provided: project name, description, repository URL, root directory path

- **Important (Load If Space):**

  - [Process Framework README](../../README.md) - Understanding framework structure and directory organization
  - [PF ID Registry](../../PF-id-registry.json) - Understanding ID prefixes and directory mappings for path configuration
  - [`source-layout` craft skill](../../../.claude/skills/source-layout/SKILL.md) — the source-organization craft (feature-first principle, layer dependency rules, placement decision tree), activated in Step 0 (Check Recommended Skills). Replaces the retired Source Code Layout Guide.

- **Reference Only (Access When Needed):**
  - [Documentation Structure Guide](../../guides/framework/documentation-structure-guide.md) - For understanding recommended directory structure
  - [Framework Domain Adaptation](../support/framework-domain-adaptation.md) - For comprehensive framework customization beyond config file

## Process

> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

> **Two phases, one context switch.** **Phase A (Steps 1–9)** runs in an **appdev session** — it gathers and confirms the project's identity, bootstraps the blueprint copy, registers the project, and delivers the first framework push: everything that reads appdev's material or writes central state. **Phase B (Steps 10–28)** runs in a **project session** — everything project-local (git, configuration, test infrastructure, hooks, the Product Concept, validation baseline). Step 9 is the single, explicit switch point; no other context change occurs in this task.

> **Step 0 — Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `project-initiation-task`. If the `source-layout` craft skill is available in the session, activate it — it owns the **source-organization craft** this task's path-configuration step delegates to (feature-first principle, layer dependency rules, what `paths.source_code` implies for later scaffolding). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/source-layout/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The craft is unavailable for this run only if the skill file itself is absent (the retired procedural guide has no successor).

### Phase A — appdev session (create, register, version-stamp)

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

4. **🚨 CHECKPOINT**: Present gathered project information and identified paths to human partner for confirmation before any file is created

5. **Decide on Foundation Category (0.x)**: Ask the human partner whether this project needs architectural foundation features before business features. Foundation features (0.x category) are appropriate when the project requires custom frameworks, core infrastructure patterns, or shared architectural enablers that business features will build on. This is an **opt-in decision** — not all projects need a foundation layer.
   > If yes: after Project Initiation completes, follow the [Architecture-First workflow](../../ai-tasks.md#for-greenfield-projects-architecture-first) to implement 0.x features before business features.
   >
   > If no: proceed directly to business feature workflows after Project Initiation.

6. **Bootstrap the blueprint copy** *(first physical action — the confirmed root path from Step 4 is its target)*: Create the project root directory if absent, then copy appdev's `blueprint/*` into it (e.g. `robocopy <appdev>\blueprint <project-root> /E /XD .git __pycache__ /XF *.pyc` — copy-only, no deletes, idempotent). This establishes everything later steps describe as already provided by the blueprint copy: the `process-framework/` tree, the `doc/` skeleton including the blank `project-config.json` template (Step 11), the test-tree bones (Step 16), the Release Process Guide stub (Step 19), `.claude/` with the framework craft skills and SessionStart hooks (Step 21), the `tools/linkwatcher/` validation-config seeds (Step 21), and the `doc/founding/` tree — the empty `inputs/` directory plus the Product Concept and Feature Landscape stubs (Step 22). No script performs this copy — `Register-Project.ps1` (Step 7) registers the project but does not bootstrap it. For an already-bootstrapped project, verify those markers are present and continue.

7. **Register Project in Appdev Central Registry**: This step assigns the project a stable child ID minted from the producer's mnemonic (`APP-NNN` under FWK-APP — P-14) and adds it to appdev's `project-registry.json`. The script also writes the assigned `project_id` into the bootstrapped `doc/project-config.json` (which is why the Step 6 bootstrap must precede it), which downstream framework scripts (state-creating, ID-assigning) read to route appropriately.

    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File blueprint/process-framework/scripts/file-creation/support/Register-Project.ps1 -Path "<absolute-path-to-new-project>" -Name "<project-name>" -ProducerPath "<absolute-path-to-appdev>" -Confirm:\$false
    ```

    The script:
    - Assigns the next child ID from `<appdev>/process-framework-central/PF-id-registry-central.json` (mnemonic-named pool, e.g. `APP`).
    - Adds an entry to `<appdev>/process-framework-central/project-registry.json`.
    - Writes the assigned `"project_id"` into `<new-project>/doc/project-config.json`.
    - Creates `<appdev>/process-framework-central/per-project-migrations/<project-id>/` with a `pending-migrations.md` skeleton.

    **🚨 CHECKPOINT**: Confirm the assigned child ID with the human partner and verify the matching `project_id` appears in the new project's `doc/project-config.json`.

8. **First Framework Push (version-stamp the new project)**: The bootstrap copied the framework content, but the project is not yet version-stamped or connected to central state. Push scoped to the new project — still from the appdev session:

   > For a freshly bootstrapped project this push is **mechanical**: the content diff is expected to be `added=0 / modified=0 / deleted=0` (the bootstrap already delivered the current blueprint), and the payload is everything else the push writes — the `.framework-version` / `.framework-version-previous` stamps, `.framework-central-pointer` (which enables central writes — feedback forms, IMP filing — from the very first project session), the `rollout-<version>` tag + rollout-log entry, and the registry's `current_framework_version`. A 0/0/0 diff is the correct result, not a no-op signal. The Mode B pre-push self-test trigger ("framework scripts changed since the previous rollout version") does not fire here — the bootstrap just delivered exactly the content this push snapshots.

   Dry-run first:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/rollout/Push-FrameworkUpdate.ps1 -Project <PROJECT-ID> -Check -Confirm:\$false
   ```

   > Pre-flight requires a clean `blueprint/process-framework/` git subtree in appdev (the push commits + tags appdev). If unrelated framework edits are in flight, resolve with the human partner before pushing — ship them via a normal rollout first, or postpone this push — rather than reaching for `-Force`.

   **🚨 CHECKPOINT**: Review the dry-run with the human partner (expected: the 0/0/0 content diff, this project as the only target), then run the real push (same command without `-Check`). Verify afterwards: `<project>/process-framework/.framework-version` matches the new rollout tag, and `.framework-central-pointer` points at appdev.

   > All *subsequent* pushes to this project are normal [Framework Rollout (PF-TSK-088)](../support/framework-rollout-task.md) Mode B sessions. This delegated first push is a Project Initiation special case — the same fold-in pattern as registration (formerly Rollout Mode A for new projects).

9. **Switch to the project — the single context switch**: Everything appdev-side is done: the project is bootstrapped, registered, version-stamped, and central-connected. Open the project workspace and continue with Phase B there — the bootstrapped `CLAUDE.md` and `.claude/settings.json` SessionStart hooks activate when the project session starts. If Phase B runs as a fresh session, re-select this task and resume at Step 10.

### Phase B — project session (configure, scaffold, validate)

10. **Set Up Git Repository**: Discuss and agree with human partner on git configuration:
   - Where the git root should be (project root directory)
   - Confirm the project directory has its own `.git` (not inherited from a parent directory)
   - If a parent `.git` exists: warn the human partner — a repo rooted above the project tracks unrelated files and should be split
   - Initialize `git init` in the project root if no repo exists
   - Create an initial `.gitignore` appropriate for the project's language/framework (virtual environments, compiled files, databases, IDE files, OS files, backup files)
   - Set up remote repository if applicable (`git remote add origin <url>`)
   - **🚨 CHECKPOINT**: Confirm git setup with human partner before proceeding

11. **Open the bootstrapped project-config.json**: The Step 6 bootstrap delivered the blank configuration template to `doc/project-config.json` (single source of truth for its structure: the blueprint's `doc/project-config.json` — this task deliberately no longer inlines it, so the two cannot drift), and Step 7 registration wrote `project_id` into it. Open the file and review its sections: `project`, `paths`, `testing`, `project_metadata`, `team`, `integration`, `recommended_skills` (arrives **pre-seeded with the framework craft-skill bindings**), `layering_rules`, and `project_id`.

12. **Customize Field Values**: Fill the template's empty (`""`) fields with actual project-specific values:
   - Use Windows path format with double backslashes (`\\`) for paths on Windows
   - Use forward slashes (`/`) for relative paths in the `paths` section
   - Set values to `null` for optional fields that don't apply
   - **Leave at their existing values** (do not hand-edit here): `project_id` was **already written by Step 7 registration — keep it intact**; `recommended_skills.tasks` **keeps its pre-seeded craft bindings intact** — Step 15 adds implementation-skill entries alongside them; `layering_rules.layers` stays `[]` — populated during onboarding or once ADRs codify layer boundaries
   - **`paths.source_code`**: Set to the actual source directory name (e.g., `src`, `lib`, `app`). Do **not** leave as `"."` — this value drives the [Source Code Layout](../../../doc/technical/architecture/source-code-layout.md) scaffold script and validation. The `source-code-layout.md` file should already exist at `doc/technical/architecture/` (created from the blueprint template). No directories are created at this point — that is deferred to Codebase Feature Discovery (PF-TSK-064) after features are known.
   - **`project_metadata.medium`**: Declare what this project's deliverables are **made of** — `code` (the default: everything an interpreter or compiler runs) or `mixed` (the project also ships instruction artifacts an *agent* executes, e.g. markdown procedures or task definitions). Leave `code` unless instruction artifacts are a real part of the product; a feature may only declare an instruction dimension in a `mixed` workspace, so under-declaring here silently blocks the Instruction Design gate for every feature. Absent parses as `code`.
   - **`paths.test_tracking_dir` / `paths.e2e_test_tracking_dir` / `paths.performance_test_tracking_dir`**: Parameterize where each tracking file lives. Defaults match historical hardcoded behavior (`test/state-tracking/permanent`) and should be left as-is for new projects. Used by framework scripts that read/write the three tracking files (e.g., `Run-Tests.ps1`, `Update-WorkflowTracking.ps1`, `Validate-StateTracking.ps1`). Introduced by the Framework Self-Testing extension (PF-PRO-035) so appdev (FWK-APP) can host its own framework-self-test workspace state outside the default location.

13. **Validate the configuration**: Run the validator to confirm valid JSON syntax, populated load-bearing fields, and no leftover placeholders:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Validate-ProjectConfig.ps1
   ```
   Fix any reported errors and re-run until it prints `✅ project-config.json is valid`. All fields should pass — including `project_id`, which Phase A registration already populated; a null `project_id` here means Step 7 was skipped.

14. **Verify Language Configuration**: Confirm `process-framework/languages-config/{language}/{language}-config.json` exists for the project's language. Shipped languages (see the Available Configurations table in the [languages-config README](../../languages-config/README.md) — currently `python`, `powershell`, `dart`) arrive with the Step 6 bootstrap; nothing to create.

    > **New-to-framework language?** Create the language pack **in the owning framework's producer face, not in this project's `process-framework/` tree** — the next Framework Rollout's `/MIR` mirror deletes project-local additions under `process-framework/`. (The dart pack was created producer-side exactly this way, PF-IMP-1382.) Work in that workspace, as logged framework work (Fast-Track qualifies).
    >
    > **Resolve `<PRODUCER_BLUEPRINT>` first** — the two values below are per-workspace, never literals (PF-PRO-068 Constraint 1; a hard-named workspace here would be wrong for every framework but one):
    > - `<PRODUCER_ROOT>` — this project's owning framework, read from its `.framework-parent-pointer` (legacy name `.framework-central-pointer` during the rename transition; both are written with identical content, so either resolves).
    > - `<PRODUCER_BLUEPRINT>` = `<PRODUCER_ROOT>` + that workspace's **`paths.blueprint`** from its `doc/project-config.json` — the producer-face key. Fall back to `paths.process_framework` only where `paths.blueprint` is absent (pre-key-split configs). `Get-BlueprintPath` in `Common-ScriptHelpers/Core.psm1` performs exactly this resolution if you are scripting it.
    >
    > 1. Copy the [language config template](../../templates/support/language-config-template.json) to `<PRODUCER_BLUEPRINT>/languages-config/{language}/{language}-config.json` and fill in test runner / coverage / lint commands.
    > 2. Copy the [runner template](../../templates/support/Run-Tests-runner-template.ps1) to `<PRODUCER_BLUEPRINT>/scripts/language-specific-scripts/{language}/Run-Tests.{language}.ps1` and adapt it to the language's test framework (the top-level `Run-Tests.ps1` dispatcher reads `testing.language` from `project-config.json` and routes to this per-language runner via `Resolve-TestLanguageRunner` from `TestRunner.psm1`).
    > 3. Add the new language as a row in [`languages-config/README.md`](../../languages-config/README.md)'s Available Configurations table.
    >
    > Then deliver the pack to this project: re-run the Step 6 bootstrap copy (copy-only, no deletes — safe to repeat) or copy the two new paths directly; other registered projects receive it at their next rollout.

15. **Populate Recommended Skills**: Check which Claude Code skills are available in the current session (listed in the system context). Match them against the project's technology stack (`project_metadata.primary_language`, `project_metadata.framework`, `project_metadata.platform`) and populate:
    - **Language-config** `recommended_skills` — for skills tied to the project's language/UI technology (e.g., `frontend-design` for JS/TS web projects → `ui-implementation`, `foundation-feature-implementation`)
    - **Project-config** `recommended_skills.tasks` — for project-level skills not tied to a language (e.g., `playwright` for web projects → `e2e-acceptance-test-execution`; `claude-api` for Claude-consuming projects → `foundation-feature-implementation`, `core-logic-implementation`)

    Each entry is an object with `skill` (skill name), `kind` (`"craft"` or `"implementation"`), and `note` (one-line purpose). Task slugs are task definition filenames without `.md`. The `kind` discriminator separates the two skill families:
    - `"craft"` — a **framework-owned craft skill** (lives under `.claude/skills/`, distributed by the framework, bound to its owning task; authored per the [Craft Skill Authoring guide](../../guides/support/craft-skill-authoring-guide.md)). Craft bindings arrive **pre-seeded from the blueprint template** — verify they are present rather than re-adding them, and keep them intact during customization.
    - `"implementation"` — a general technology/tooling skill matched to the project's stack (the rows you add in this step).

    Use the seed mapping table below as a starting point — adapt to the project's actual needs:

    | Skill | Kind | Config Location | Applicable Tasks | Note |
    |---|---|---|---|---|
    | `ui-design` | craft | Project-config (pre-seeded from template) | `ui-design-task` | Framework-owned UI design craft — verify present, do not re-add |
    | `frontend-design` | implementation | Language-config (JS/TS) | `ui-implementation`, `foundation-feature-implementation` | Aesthetic design guardrails for web UI code generation |
    | `webapp-testing` | implementation | Language-config (JS/TS) | `integration-and-testing` | Web app test automation |
    | `playwright` | implementation | Project-config (web projects) | `e2e-acceptance-test-execution` | Browser automation for E2E testing |
    | `claude-api` | implementation | Project-config (Claude-consuming) | `foundation-feature-implementation`, `core-logic-implementation` | Claude API integration patterns |

    > Skip if no available skills match the project's technology stack. The `recommended_skills` fields remain empty arrays / empty objects (apart from pre-seeded craft bindings) — consuming tasks handle absence silently.

16. **Apply Language Customizations to Test Tree**: The blueprint copy already provides the test directory structure — including the fixed bones `test/automated/unit/`, `test/automated/performance/level{1-4}-*/`, `test/audits/{unit,performance/level{1-4}-*,e2e}/`, `test/e2e-acceptance-testing/`, and `test/bug-validation/` (top-level since PF-IMP-871 Phase 2b — formerly under `test/automated/`) — along with tracking files (`test-tracking.md`, `e2e-test-tracking.md`, `performance-test-tracking.md`) and `TE-id-registry.json`. Run `New-TestInfrastructure.ps1 -Scaffold` to layer the language-specific customizations on top:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/00-setup/New-TestInfrastructure.ps1 -Language "<language>"
   ```
   This applies: shared fixture file (e.g., `conftest.py` for Python), package marker files (e.g., `__init__.py`), `.gitignore` for E2E workspace/results, and idempotent verification of the tracking files inherited from the blueprint copy. It also creates `test/bug-validation/` if missing (defensive for projects bootstrapped without a current blueprint copy). See the [Test Infrastructure Guide](../../guides/03-testing/test-infrastructure-guide.md) for details.
   - **Scaffold vs Update mode**: `-Scaffold` (the default, used here) layers language customizations + defensively creates fixed bones. The companion `-Update` mode (auto-invoked later by `New-FeatureImplementationState.ps1` and `New-WorkflowEntry.ps1`) scaffolds the *variable* parts of the tree — per-feature-category subdirs under `automated/unit/` and per-workflow subdirs under `e2e-acceptance-testing/` — driven by feature-tracking.md + user-workflow-tracking.md. Both modes are idempotent and mutually exclusive (`ParameterSetName`).
   - After running: create native test runner config (e.g., `pytest.ini` for Python)
   - After running: install test dependencies (e.g., `pip install pytest pytest-cov`)

17. **Declare User Documentation Taxonomy** (in `doc/PD-id-registry.json`): Confirm or customize the documentation taxonomy for the project. The framework default follows the Diátaxis standard (tutorials / how-to / reference / explanation); you can accept these as-is or customize.

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

18. **Set Up CI/CD Infrastructure**: Follow the [CI/CD Setup Guide](../../guides/07-deployment/ci-cd-setup-guide.md) to scaffold development tooling:
    - Create pre-commit hooks config (`.pre-commit-config.yaml`) carrying the framework gates the guide documents (state-tracking gate, PD/TE documentation-map drift gates, and the two corruption guards `no-git-objects-literal` / `no-nul-bytes`). They guard framework artifacts every project has, so they are the expected default — omitting them is an explicit decision to present at the Step 23 checkpoint, not a side effect of skipping this step.
    - Create dev script (`dev.bat` / `dev.sh`) *(optional)*
    - Create CI pipeline *(optional — if using a Git hosting platform)*

19. **Note the Release Process Guide stub** (passive reference — no action now): The blueprint ships a structured Release Process Guide stub at [`doc/ci-cd/release-process.md`](../../../doc/ci-cd/release-process.md) (the project's `PD-CIC` instance, generated from the [Release Process Guide template](../../templates/07-deployment/release-process-guide-template.md)). It is intentionally **unfilled** — its **Freshness Stamp** reads `unverified` — so that [Release & Deployment (PF-TSK-008)](../07-deployment/release-deployment-task.md)'s Critical Must-Read reference resolves from day one. Fill in its deploy / version / distribute mechanics and re-set the Freshness Stamp when the project's first release approaches; an onboarded project instead captures its existing release process into this stub during [Retrospective Documentation Creation](retrospective-documentation-creation.md) Phase 4. This mirrors the `source-code-layout.md` treatment in Step 12 — a blueprint-shipped stub plus a passive reference, populated later when the information is known.

20. **Design Guidelines (opt-in, UI projects)**: If this project has — or will have — a user interface, it needs a project-level Design Guidelines document (PD-UIX-001) — the design-system reference every UI Design consults. Scaffold it now with [New-DesignGuidelines.ps1](../../scripts/file-creation/02-design/New-DesignGuidelines.ps1) (which pins the reserved PD-UIX-001 from the design-guidelines template), or defer — the [UI Design task (PF-TSK-090)](../02-design/ui-design-task.md) creates it on demand (opt-in) when the first UI feature reaches design. **Non-UI projects skip this entirely** (the majority — they pay nothing). For deciding when shared app-shell UI belongs in a shared doc vs. a feature's own UI Design, see the [App-Shell vs Feature-Views Convention](../../guides/02-design/app-shell-vs-feature-views-convention-guide.md).

21. **Verify SessionStart Hooks**: The Step 6 bootstrap delivered [`.claude/settings.json`](../../../.claude/settings.json) with the framework's default `SessionStart` hook block (single source of truth: the blueprint's `.claude/settings.json` — this task no longer inlines the JSON). The hooks turn startup-procedure steps into deterministic side effects rather than agent-honored CLAUDE.md instructions, which agents have been observed to silently skip (PF-IMP-854). Verify the file is present and customize its three hooks for this project:

    - **Hook 1 — LinkWatcher startup**: Invokes [start_linkwatcher_hook_wrapper.ps1](../../tools/linkWatcher/start_linkwatcher_hook_wrapper.ps1), which calls the sibling [start_linkwatcher_background.ps1](../../tools/linkWatcher/start_linkwatcher_background.ps1) inside a `Start-Process` + `WaitForExit(8000)` isolation envelope. The wrapper is required because the LinkWatcher daemon inherits stdout handles — invoking the startup script directly from a stdout-capturing hook hangs the session ([documented in the startup script's header](../../tools/linkWatcher/start_linkwatcher_background.ps1)). Idempotent — the startup script detects an already-running instance via lock file and no-ops. **If LinkWatcher is not installed for this project, remove this hook** (the others still apply); to set LinkWatcher up (install once, use across all projects), follow the multi-project-setup handbook in the LinkWatcher **source repository** (`doc/user/handbooks/multi-project-setup.md` there) — the installed-copy path (`<LinkWatcher install>/doc/user/handbooks/...`) only resolves once an install exists.
    - **Hook 2 — Session start timestamp**: Emits a single line `Session start: YYYY-MM-DD HH:mm:ss` into initial context. The agent uses this when calculating session duration for feedback forms (PF-TSK-XXX completion checklists).
    - **Hook 3 — Task-selection reminder**: Reinforces the framework's task-discipline gate. Edit the `additionalContext` string to add project-specific routing hints if a particular task category is frequently misrouted.

    Settings:

    - **File location**: `.claude/settings.json` (committed to git, team-wide). `.claude/settings.local.json` is gitignored and won't propagate to collaborators.
    - **Take effect**: only at the *next* session start (the hook config is loaded at session-start time). After changing the file, run `/hooks` in Claude Code or start a new session to activate.
    - **Verify**: at the next session start, initial context should contain (a) a LinkWatcher startup line, (b) the timestamp line, and (c) the task-selection reminder being applied (the agent acknowledges a task in its first reply).

    **Per-project broken-link validation config**: The Step 6 bootstrap also delivered the active validation config — `tools/linkwatcher/linkwatcher-config.yaml` and `tools/linkwatcher/.linkwatcher-ignore` (seeded from `blueprint/tools/linkwatcher/`; the broken-link scan [run_linkwatcher_validate.ps1](../../tools/linkWatcher/run_linkwatcher_validate.ps1) auto-passes the config to `--validate`). Make the conscious per-project decision: leave `path_resolution_overrides: {}` empty (the default — a no-op) **unless** this project has a folder that ships to other projects as a root (e.g. a `blueprint/` or `example/` template tree whose `/...` links are authored from the rollout target's perspective), in which case map that folder to itself (e.g. `blueprint: blueprint`).

    > For a project bootstrapped before the blueprint carried these seeds, copy them from the framework templates instead:
    > ```bash
    > New-Item -ItemType Directory -Force tools/linkwatcher | Out-Null
    > Copy-Item process-framework/tools/linkWatcher/linkwatcher-config.template.yaml tools/linkwatcher/linkwatcher-config.yaml
    > Copy-Item process-framework/tools/linkWatcher/.linkwatcher-ignore.template tools/linkwatcher/.linkwatcher-ignore
    > ```

22. **Synthesize the Product Concept**: The blueprint ships a structured Product Concept stub at [`doc/founding/product-concept.md`](../../../doc/founding/product-concept.md) (the reserved singleton `PD-DOC-001`, instantiated from the [Product Concept template](../../templates/00-setup/product-concept-template.md)). It is the project's authoritative statement of **what is being built and why**, and the artifact [Feature Discovery (PF-TSK-013)](../01-planning/feature-discovery-task.md) reads as the greenfield stand-in for "existing features".

    - **Ask the human partner for the project's founding material** — whatever already exists that describes the product's intent: a written brief, a business-model document, a slide or PDF export, a conversation transcript. Have it placed in [`doc/founding/inputs/`](../../../doc/founding/inputs/README.md). Inputs stay raw: any format, **no IDs, no frontmatter** — the framework does not own them, and that directory is deliberately excluded from the product documentation map. Where an input is binary or non-English, an agent may add a readable working transcription beside it; the transcription is still an input.
    - **If there is no pre-existing material**, the founding input is the conversation itself — record the human partner's own words verbatim as an input file, then synthesize from that.
    - **Synthesize the concept** from those inputs into the stub: vision, target users, core value proposition, capability areas, business-model notes (if any), and open questions. Index every input in the concept's **Sources** table — inputs carry no IDs, so that table is the only thing preserving traceability.
    - **Mark provenance**: agent-developed interpretation is marked inline with *(elaboration)*; anything unmarked reads as a commitment traceable to an input. This distinction is load-bearing for every downstream reader.
    - **Keep capability areas coarse** — they are areas, not features. Feature Discovery derives features from them; pre-empting it here produces a feature list nothing owns.
    - **An open question about product intent** ("what should this do?") belongs in the concept's Open Questions. A question about feasibility or technology choice is a *technical exploration* — file it via [`New-Exploration.ps1`](../../scripts/file-creation/01-planning/New-Exploration.ps1) instead, where [Technical Exploration (PF-TSK-093)](../01-planning/technical-exploration-task.md) resolves it.

    > **A project with no founding material leaves the stub unfilled** — its `status` stays `Stub — no founding material synthesized yet`. That is a valid outcome, not a defect; the same treatment as the Release Process Guide stub in Step 19. An **onboarded** project (existing codebase) also leaves it for [Retrospective Documentation Creation](retrospective-documentation-creation.md), which captures its existing origin documents into this same stub.

23. **🚨 CHECKPOINT**: Present completed project-config.json, language config, test infrastructure, documentation taxonomy, CI/CD setup, and the **synthesized Product Concept** to human partner for review before finalization. The concept is the one item here that downstream *design* work depends on — review its vision, capability areas, and elaboration marks specifically, rather than approving it alongside the configuration in one pass.

### Finalization

24. **Verify File Location**: Confirm `project-config.json` is in `doc/` and language config is in `languages-config`

25. **Test Configuration**: Verify the full setup works:
    - `Run-Tests.ps1 -ListCategories` shows test categories
    - `Run-Tests.ps1 -Quick` runs successfully (if test files exist)
    - `pre-commit run --all-files` passes (if pre-commit was set up)
    - `dev test` works (if dev script was created)

26. **Document Project-Specific Notes**: If there are any non-standard configurations or important context, add comments to this task or create a project README

27. **Establish the Validation Baseline**: Run the validators against the finished setup — [`Validate-ProjectConfig.ps1`](../../scripts/validation/Validate-ProjectConfig.ps1), [`Validate-StateTracking.ps1`](../../scripts/validation/Validate-StateTracking.ps1), and the LinkWatcher broken-link scan ([`run_linkwatcher_validate.ps1`](../../tools/linkWatcher/run_linkwatcher_validate.ps1)) — and triage each finding: **expected-by-design** (note why), **project-local** (fix now), or **framework defect** (file an IMP centrally — a fresh project's first full validation run is exactly where blueprint-shipped defects surface; the Phase A push already planted the `.framework-central-pointer`, so central filing works from this session). Record the accepted baseline (remaining findings + their classifications) when presenting task completion.

28. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Bootstrapped framework copy** - appdev's `blueprint/*` copied into the project root (Phase A, Step 6): `process-framework/` tree, `doc/` skeleton (incl. the blank `project-config.json` template), test-tree bones, `.claude/` (framework craft skills + SessionStart hooks), `tools/linkwatcher/` validation-config seeds, project `CLAUDE.md`
- **Project registration** - child ID (`APP-NNN`) assigned in appdev's `project-registry.json`; `project_id` field written into the project's `doc/project-config.json`; per-project migration ledger created at `<appdev>/process-framework-central/per-project-migrations/<project-id>/` (Phase A, Step 7)
- **First framework push** - `.framework-version` / `.framework-version-previous` stamps and `.framework-central-pointer` in the project; `rollout-<version>` tag + rollout-log entry in appdev; registry `current_framework_version` / `last_rollout` set (Phase A, Step 8)
- **Git repository** - Initialized git repo at project root with `.gitignore` and optional remote
- **project-config.json** - the bootstrapped template at `doc/project-config.json`, customized to contain:
  - Project identification (name, display name, description, repository URL)
  - Directory path mappings (documentation, source code, tests, scripts)
  - Testing configuration (language, test directory, quick categories)
  - Project metadata (language, framework, platform, development approach)
  - Team composition and collaboration model
  - Integration configurations (issue tracker, CI/CD, code hosting)
- **Language config** (if new) - `process-framework/languages-config/{language}/{language}-config.json` with language-specific test runner commands
- **Test infrastructure** - Test directory structure, test runner config, shared fixtures, empty `test-tracking.md`
- **CI/CD infrastructure** - Pre-commit hooks with the framework gates (expected default; omission is an explicit Step 23 decision), plus optional dev script and CI pipeline
- **Design Guidelines (PD-UIX-001)** (optional, UI projects) - scaffolded via `New-DesignGuidelines.ps1` at Step 20, or deferred to the first UI Design run
- **SessionStart hooks** - `.claude/settings.json` (bootstrap-seeded from the blueprint) verified and customized at Step 21: LinkWatcher background startup (via wrapper; removed if LinkWatcher not installed), session start timestamp, and task-selection reminder (PF-IMP-854)
- **LinkWatcher validation config** (if LinkWatcher installed) - `tools/linkwatcher/linkwatcher-config.yaml` + `.linkwatcher-ignore`, bootstrap-seeded and consciously configured at Step 21 (empty `{}` by default; per-folder `path_resolution_overrides` only if the project has a shippable-root folder)
- **Release Process Guide stub** (noted, not created) - The blueprint-shipped Release Process Guide stub at `doc/ci-cd/release-process.md` (`PD-CIC`) is present and acknowledged via the passive reference (Step 19); filled in later when the project's release mechanics are known
- **Product Concept (PD-DOC-001)** - `doc/founding/product-concept.md` synthesized at Step 22 from the founding inputs in `doc/founding/inputs/`, with every input indexed in its Sources table and agent interpretation marked *(elaboration)*; left as an unfilled stub when the project has no founding material (or when an onboarded project defers it to Retrospective Documentation Creation)
- **Validation baseline** - the Step 27 accepted baseline: `Validate-ProjectConfig` + `Validate-StateTracking` + LinkWatcher validate findings triaged (expected-by-design / project-local fixed / framework defects filed as IMPs)

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
  - Location: `<appdev>/process-framework-central/per-project-migrations/<project-id>/pending-migrations.md`
  - Purpose: Tracks per-project working-doc migrations queued by Structure Change task; applied by Framework Rollout Mode C
  - Lifecycle: Permanent; entries added/resolved over time by Structure Change + Framework Rollout work

### Existing State Files Updated

- **appdev's `process-framework-central/project-registry.json`**: a new entry is appended for the registered project (keyed by the child ID) at Step 7; its `current_framework_version` / `last_rollout` fields are set by the Step 8 first push.
- **appdev's `process-framework-central/PF-id-registry-central.json`**: the mnemonic-named child pool's (`APP`) `nextAvailable` counter is incremented.
- **appdev's `process-framework-central/rollouts/rollout-log.md`**: the Step 8 first push appends its rollout entry.

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

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
  - [ ] LinkWatcher validation config exists at `tools/linkwatcher/linkwatcher-config.yaml` (bootstrap-seeded) and was consciously configured (N/A if LinkWatcher is not installed)
  - [ ] Release Process Guide stub at `doc/ci-cd/release-process.md` is present (blueprint-shipped) and was noted for later fill-in (Step 19 — no action required now)
  - [ ] **Product Concept (Step 22)**: founding material gathered into `doc/founding/inputs/` and `doc/founding/product-concept.md` synthesized from it — every input indexed in the Sources table, agent interpretation marked *(elaboration)*, `status` updated off `Stub`. **N/A** if the project has no founding material (stub left unfilled) or is an onboarded project deferring capture to Retrospective Documentation Creation
  - [ ] Framework pre-commit gates (state-tracking, PD/TE doc-map, corruption guards) present in `.pre-commit-config.yaml`, or their omission explicitly decided at the Step 23 checkpoint (Step 18)
  - [ ] Pre-commit hooks work (if configured): `pre-commit run --all-files`
  - [ ] Validation baseline established (Step 27): `Validate-ProjectConfig`, `Validate-StateTracking`, and LinkWatcher validate run; findings triaged; accepted baseline recorded

- [ ] **Registration & First Push (Phase A)**: Confirm the project is registered and version-stamped
  - [ ] The assigned `project_id` field is present in `doc/project-config.json`
  - [ ] Appdev's `process-framework-central/project-registry.json` contains an entry for the new child ID with `current_framework_version` set by the first push
  - [ ] Per-project migration ledger directory exists at `<appdev>/process-framework-central/per-project-migrations/<project-id>/`
  - [ ] `<project>/process-framework/.framework-version` matches the first push's `rollout-<version>` tag
  - [ ] `<project>/process-framework/.framework-central-pointer` points at appdev
  - [ ] Appdev's `rollout-log.md` has the first-push entry

- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-059`, context "Project Initiation".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `<project-root>/*` (bootstrapped framework copy) | Step 6 robocopy of appdev's `blueprint/*` | `process-framework/` tree, `doc/` skeleton, test bones, `.claude/`, `tools/linkwatcher/` seeds, project `CLAUDE.md` |
| **Creates** | `doc/project-config.json` | Step 6 bootstrap + manual customization (validated by `Validate-ProjectConfig.ps1`) | Blueprint-delivered template; `project_id` written by Step 7 registration; customized with name, language, paths; Step 13 validates JSON syntax, populated load-bearing fields, and absence of leftover placeholders |
| **Updates** | appdev central registry + rollout log | `Register-Project.ps1` (Step 7) + `Push-FrameworkUpdate.ps1` (Step 8) | Registry entry + child-pool counter; first-push version stamps, central pointer, rollout tag + log entry |
| **Creates** | `process-framework/languages-config/{language}/{language}-config.json` | Step 6 bootstrap (shipped languages) / appdev blueprint authoring (new-to-framework languages, Step 14) | Language-specific command configurations for testing, linting, coverage |
| **Creates** | `test/` directory structure | `New-TestInfrastructure.ps1` (Step 16) | Test directories, tracking files, TE-id-registry.json |
| **Creates** | [`user-workflow-tracking.md`](../../../doc/state-tracking/permanent/user-workflow-tracking.md) | Manual | User workflow to feature mapping |
| **Creates** | CI/CD infrastructure | Manual (Step 18) | Pre-commit hooks with framework gates (expected default); optional dev scripts, pipeline configs |
| **Creates** | `.claude/settings.json` | Step 6 bootstrap + manual customization (Step 21) | `SessionStart` hooks (LinkWatcher startup, session timestamp, task-selection reminder); Hook 1 removed when LinkWatcher is not installed |

## Next Tasks

- [**Codebase Feature Discovery (PF-TSK-064)**](codebase-feature-discovery.md) - When adopting the framework into an **existing codebase**: Discovery's source-structure step (Step 7.f) consumes the `project-config.json` and `source-code-layout.md` produced here.
- [**Framework Domain Adaptation**](../support/framework-domain-adaptation.md) - For comprehensive framework customization beyond configuration file (adapting task categories, document types, ID prefixes)
- **Begin Development Workflow** - Use appropriate task from [AI Tasks Registry](../../ai-tasks.md) based on your next activity (feature planning, implementation, etc.)

<!-- merged from transition-registry entry: Project Initiation (PF-TSK-059) -->
### Prerequisites for Transition

- [ ] `project-config.json` created at `doc/project-config.json` with project identification, directory mappings, and testing configuration
- [ ] Language config file created in `process-framework/languages-config/{language}/`
- [ ] Test infrastructure scaffolded (directory structure, tracker, registry, fixtures)
- [ ] CI/CD infrastructure set up (framework pre-commit gates present or explicitly omitted; dev script / pipeline if applicable)
- [ ] Release Process Guide stub (`doc/ci-cd/release-process.md`) noted for later fill-in (Step 19 passive reference; blueprint-shipped, left `unverified`)
- [ ] User Workflow Tracking file created at `doc/state-tracking/permanent/user-workflow-tracking.md`

### Next Task Selection

```
What is needed next?
├─ Framework customization needed → Framework Domain Adaptation
├─ Features already known → Feature Request Evaluation or Feature Discovery
├─ Adopting framework into existing codebase → Codebase Feature Discovery
└─ Greenfield project → Begin normal development workflow (Feature Discovery)
```

### Preparation for Next Task

1. Verify `project-config.json` is complete and test runner works (`Run-Tests.ps1 -ListCategories`)
2. Confirm test infrastructure directories match project language and conventions
3. Review User Workflow Tracking for initial workflow stubs to guide feature planning

## Related Resources

- [Example project-config.json](../../../doc/project-config.json) - Reference implementation from LinkWatcher project
- [Process Framework README](../../README.md) - Overview of framework structure and components
- [Framework Domain Adaptation](../support/framework-domain-adaptation.md) - Comprehensive framework customization for new domains
- [Documentation Structure Guide](../../guides/framework/documentation-structure-guide.md) - Recommended directory organization patterns
- [PF ID Registry](../../PF-id-registry.json) - Document ID prefixes and directory mappings
- [Test Infrastructure Guide](../../guides/03-testing/test-infrastructure-guide.md) - Test directory structure, tracking, and scaffolding
- [CI/CD Setup Guide](../../guides/07-deployment/ci-cd-setup-guide.md) - CI pipeline, pre-commit hooks, dev scripts
- [Framework Rollout (PF-TSK-088)](../support/framework-rollout-task.md) - Owns all pushes after the delegated first push (Mode B), retrofit registration (Mode A), migrations (Mode C), and rollback (Mode D)
