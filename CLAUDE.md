# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**LinkWatcher** is a real-time link maintenance system that automatically detects file movements and updates all references across your project. Built with Python, it uses file system watching to maintain link integrity in markdown files, YAML configs, JSON files, Python imports, and more.

**Key Features**: File watching, multi-format support, safe atomic updates, dry-run mode, comprehensive testing (247+ test methods)

> **What this product is**: [`doc/founding/product-concept.md`](doc/founding/product-concept.md) (`PD-DOC-001`) is the authoritative statement of what is being built and why — vision, target users, value proposition, capability areas, open questions. The summary above is a convenience; the concept is the source of truth. Its raw source material sits in [`doc/founding/inputs/`](doc/founding/inputs/README.md), and [`doc/founding/feature-landscape.md`](doc/founding/feature-landscape.md) records why the feature set is shaped as it is. Until the project's founding material is synthesized (Project Initiation Step 22), the concept reads as an unfilled stub.

## Mandatory Workflow

**CRITICAL**: This project uses a strict task-based approach. Working without a task selection violates the project methodology — no exceptions. Before ANY work:

1. **Open the [Task Execution Protocol](process-framework/guides/framework/task-execution-protocol-guide.md)** — the operative procedure for every task. Its **Phase A** selects a task: match the user's request against the **Use When** column in the [task catalog](process-framework/ai-tasks.md) (selection happens before any other exploration or work; if nothing matches, ask the user). **Phases B–C** govern execution, completion, and feedback.
2. **Read the COMPLETE task definition** including its completion checklist before starting work.
3. **If no task fits**: Ask the user before proceeding.

## Following Linked Documents

The framework is a **graph of linked documents you are expected to traverse**, not a single file. When an `@`-referenced file, a task definition, the [Task Execution Protocol](process-framework/guides/framework/task-execution-protocol-guide.md), or a step-referenced lookup table points you somewhere, that content is **load-bearing and mandatory** — read and follow it as if it were inlined here. Tasks are deliberately lean: the universal execution contract lives once in the Task Execution Protocol, and each task plugs its task-specific steps into it. Skipping a linked document because the pointer "looked optional" is a process violation.

## Framework Craft Skills

The framework ships **craft skills** under `.claude/skills/` (e.g. `ui-design`, `tdd-creation`, `api-design`). Each holds the *craft* half of one framework task - the judgment its steps delegate to - while the task definition keeps the process (steps, checkpoints, completion checklist).

- **Activation**: a craft skill activates only from its task's *Check Recommended Skills* step, resolved through the `recommended_skills` binding in `doc/project-config.json` (or a language config) - bindings with `kind: "craft"` are these framework-owned skills. When that step names a skill, invoke it via the Skill tool and apply its guidance through the rest of the task. Craft skills carry `user-invocable: false` - they are task-activated, not slash commands.
- **Graceful degradation**: if a bound skill is not listed in the session, read its `.claude/skills/<name>/SKILL.md` directly and apply it - that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. Only if the skill file itself is absent does the task proceed without the craft for that run.
- **Framework-owned content**: skill files are deployed and kept current by Framework Rollout's `.claude/skills/` mirror, so treat the local copies as read-only. An improvement or defect in skill content is a framework finding - file it as an IMP (see the [Issue Classification and Routing Guide](process-framework/guides/framework/issue-classification-and-routing-guide.md)) so the fix lands in the canonical tree and reaches every project at the next rollout.

## Session Startup Requirements

LinkWatcher background startup and session-start timestamp are emitted automatically by the `SessionStart` hooks in `.claude/settings.json` (set up during [Project Initiation (PF-TSK-059)](process-framework/tasks/00-setup/project-initiation-task.md) Step 14) — no agent action required.

## Prohibited Git Commands

**CRITICAL**: The following git commands are **NEVER** allowed in this project. The working tree frequently contains hundreds of uncommitted changes from LinkWatcher link updates and parallel sessions. These commands will destroy that work.

- `git stash` — captures the entire dirty working tree; pop/apply causes merge conflicts and data loss
- `git checkout -- <path>` — silently reverts ALL uncommitted changes in the target path
- `git reset --hard` — destroys all uncommitted changes project-wide
- `git clean -f` — deletes untracked files permanently

**If you need to test whether a change is pre-existing**: use `git diff HEAD -- <file>` or `git show HEAD:<file>` to inspect the committed version without modifying the working tree.

**No exceptions.** If you believe one of these commands is necessary, ask the user first and explain exactly what will be lost.

## PowerShell Script Execution

Check a script's parameters before invoking it, then prefer `-File` with a direct path:

```bash
pwsh.exe -ExecutionPolicy Bypass -Command 'Get-Help path/to/Script.ps1 -Parameter *'          # inspect params (`-?` never shows them; ValidateSet values need the metadata one-liner — see the reference)
pwsh.exe -ExecutionPolicy Bypass -File path/to/Script.ps1 -Param "value" -Confirm:\$false     # run (escape $ as \$)
```

`-File` needs no `cd` or quoting wrapper. For the `-Command` fallback, human-terminal usage, and Bash-tool troubleshooting, see the single source of truth: @process-framework/guides/support/script-development-quick-reference.md (§ PowerShell Script Execution (AI Agents)).

## Cross-Project Issue Filing

If you discover a **product bug or feature request that belongs to a different registered project** (e.g. a defect in another in-house tool spotted while working here), file it directly into that project rather than losing the finding. See [Cross-Project Issue Filing Guide](process-framework/guides/support/cross-project-issue-filing-guide.md): resolve the target's path from the central `project-registry.json`, then run **that project's own** `New-BugReport.ps1` / `New-FeatureRequest.ps1` and file it raw for the target's own triage. (Framework defects still go to the central IMP tracking, not here.)

## Architecture Overview

### Documentation Separation

The project maintains clear separation between two concerns:

- **Process Framework** (`doc`): HOW to develop the project (tasks, templates, workflows)
- **Product Documentation** (`docs/`): Project-specific documentation (testing, CI/CD, configuration, troubleshooting)

### Process Framework Structure

```
process-framework/
├── tasks/                    # Task definitions by phase
│   ├── 01-planning/          # Feature planning and assessment
│   ├── 02-design/            # Technical and functional design
│   ├── 03-testing/           # Test planning and implementation
│   ├── 04-implementation/    # Feature development and coding
│   ├── 05-validation/        # Quality validation and compliance
│   ├── 06-maintenance/       # Code maintenance and bug management
│   ├── 07-deployment/        # Release preparation and deployment
│   ├── cyclical/             # Recurring activities (documentation adjustment, tech debt)
│   └── support/              # Meta-framework tasks (creating tasks, adapting framework)
├── templates/                # Framework document templates (task-template.md, etc.)
├── scripts/file-creation/    # PowerShell automation for creating framework documents
├── state-tracking/
│   ├── permanent/            # Long-term tracking (feature-tracking.md, bug-tracking.md, etc.)
│   └── temporary/            # Session-specific state files
├── guides/                   # Best practices and reference guides
└── feedback/                 # Task completion feedback forms
```

### Key State Files

- **Feature Tracking**: Feature development status and progress
- **Bug Tracking**: Bug reports and fix status
- **Release Status**: Release preparation and deployment tracking
- **Task-specific temporary state**: Created per multi-session task in `state-tracking/temporary/`

### Document ID System

All framework documents use structured IDs:
- `PF-XXX-###` format (e.g., `PF-TSK-001` for tasks)
- Tracked in @process-framework/PF-id-registry.json, @doc/PD-id-registry.json, and @test/TE-id-registry.json

## Common Commands

### Creating Framework Documents

All scripts live under `process-framework/scripts/file-creation/`, in phase-keyed subdirectories:

```powershell
# Create a feature request
New-FeatureRequest.ps1

# Create a Functional Design Document
New-FDD.ps1

# Create a Technical Design Document
New-TDD.ps1

# Create a test specification
New-TestSpecification.ps1

# Create a bug report
New-BugReport.ps1

# Create feedback form
New-FeedbackForm.ps1

# Create temporary state file
New-TempTaskState.ps1

# Create permanent state file
New-PermanentState.ps1
```

### Validation Scripts

```powershell
# Validate feedback forms
process-framework/scripts/validation/Validate-FeedbackForms.ps1

# Validate ID registry
process-framework/scripts/validation/Validate-IdRegistry.ps1

# Validate state tracking (feature states, cross-references, ID counters)
process-framework/scripts/validation/Validate-StateTracking.ps1
```

## Task Completion Requirements

**CRITICAL**: Tasks are NOT complete until:
1. All deliverables are created
2. Feedback form is completed using templates in process-framework/templates/support/feedback-form-template.md
3. State files are updated

Each task definition includes a mandatory completion checklist.

## Key References

- **Task Registry**: @process-framework/ai-tasks.md
- **Documentation Map**: @process-framework/PF-documentation-map.md (index of all framework documents)
- **Process Framework README**: @process-framework/README.md
- **Project README**: @README.md

## Visual Notation

Framework uses standardized diagram formats. See @process-framework/guides/support/visual-notation-guide.md for interpretation.

## LinkWatcher Capabilities

> **Full reference**: @doc/user/handbooks/linkwatcher-capabilities-reference.md — consult before making assumptions.

LinkWatcher runs in background and automatically maintains all cross-references. You can move/rename files using VS Code, File Explorer, or git — LinkWatcher handles all updates automatically. Check `logs/linkwatcher/LinkWatcherLog.txt` for activity logs.

**Check broken links**: run the validate launcher — `pwsh.exe -ExecutionPolicy Bypass -File process-framework/tools/linkWatcher/run_linkwatcher_validate.ps1` — which scans with the project's per-project config (`tools/linkwatcher/linkwatcher-config.yaml`); the report path is printed at the end of the run.

### What LinkWatcher Updates (DO NOT assume limitations)

**LinkWatcher updates ALL monitored file types, not just markdown.** It updates:
- **Markdown** (.md): standard links, reference definitions, HTML anchors, quoted/backtick/bare/@-prefixed paths
- **Python** (.py): quoted file paths, directory paths, `import` statements (dot-to-path), docstring paths, comment paths
- **YAML** (.yaml, .yml): full-string values, embedded paths in compound strings, directory values
- **JSON** (.json): full-string values, embedded paths in compound strings, directory values
- **PowerShell** (.ps1, .psm1): quoted paths, embedded markdown links, block comments, here-strings, line comments
- **Dart** (.dart): import/part statements, quoted paths, standalone paths
- **All other monitored types**: generic quoted/unquoted path detection

**33 monitored extensions** by default including `.md`, `.yaml`, `.yml`, `.json`, `.py`, `.ps1`, `.psm1`, `.dart`, `.html`, `.js`, `.ts`, `.tsx`, `.bat`, `.toml`, `.xml`, `.csv`, `.txt`, and more.

### What LinkWatcher Does NOT Do

- Does not update external URLs (http/https/mailto)
- Does not validate `#anchor` links against heading IDs
- Does not do AST-based refactoring (textual match updates)
- Does not interact with git history
