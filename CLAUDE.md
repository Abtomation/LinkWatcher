# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**LinkWatcher** is a real-time link maintenance system that automatically detects file movements and updates all references across your project. Built with Python, it uses file system watching to maintain link integrity in markdown files, YAML configs, JSON files, Python imports, and more.

**Key Features**: File watching, multi-format support, safe atomic updates, dry-run mode, comprehensive testing (247+ test methods)

## Mandatory Workflow

**CRITICAL**: This project uses a strict task-based approach. Before ANY work:

1. **Read the entry point**: @doc/process-framework/.ai-entry-point.md
2. **Select a task**: @doc/process-framework/ai-tasks.md - All work MUST be done within a task framework
3. **If no task fits**: Ask the user before proceeding

**No exceptions** - working without a task selection violates the project methodology.

## Session Startup Requirements

At the start of EVERY session, you must:

1. **Start LinkWatcher** (maintains cross-references automatically):
   ```powershell
   LinkWatcher/start_linkwatcher_background.ps1
   ```

2. **Get current time** (for time tracking - use MCP server if available)

## Prohibited Git Commands

**CRITICAL**: The following git commands are **NEVER** allowed in this project. The working tree frequently contains hundreds of uncommitted changes from LinkWatcher link updates and parallel sessions. These commands will destroy that work.

- `git stash` — captures the entire dirty working tree; pop/apply causes merge conflicts and data loss
- `git checkout -- <path>` — silently reverts ALL uncommitted changes in the target path
- `git reset --hard` — destroys all uncommitted changes project-wide
- `git clean -f` — deletes untracked files permanently

**If you need to test whether a change is pre-existing**: use `git diff HEAD -- <file>` or `git show HEAD:<file>` to inspect the committed version without modifying the working tree.

**No exceptions.** If you believe one of these commands is necessary, ask the user first and explain exactly what will be lost.

## PowerShell Script Execution

**Preferred pattern** — use `pwsh.exe -Command` with the entire argument wrapped in **bash single quotes**:

```bash
cd /c/path/to/script/directory && pwsh.exe -ExecutionPolicy Bypass -Command '& .\Script.ps1 -Param1 "value1" -Param2 "value2" -Confirm:$false'
```

> **Key rule**: Wrap the entire `-Command` argument in bash single quotes (`'...'`). Inside, use double quotes for PowerShell string parameters. Bash single quotes prevent interpretation of `$`, `&`, and other special characters.

**Fallback pattern** — for complex cases where nested quoting is problematic, write a temp `.ps1` file:

```bash
cat > /c/path/to/project/temp.ps1 << 'ENDOFSCRIPT'
Set-Location 'c:\path\to\script\directory'
& .\Script.ps1 -Params -Confirm:$false
ENDOFSCRIPT
pwsh.exe -ExecutionPolicy Bypass -File /c/path/to/project/temp.ps1 && rm /c/path/to/project/temp.ps1
```

See @doc/process-framework/guides/support/script-development-quick-reference.md for details and examples.

## Architecture Overview

### Documentation Separation

The project maintains clear separation between two concerns:

- **Process Framework** (`doc/product-docs`): HOW to develop the project (tasks, templates, workflows)
- **Product Documentation** (`docs/`): Project-specific documentation (testing, CI/CD, configuration, troubleshooting)

### Process Framework Structure

```
doc/process-framework/
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
├── templates/templates/      # Framework document templates (task-template.md, etc.)
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
- Tracked in @doc/process-framework/PF-id-registry.json, @doc/product-docs/PD-id-registry.json, and @test/TE-id-registry.json

## Common Commands

### Creating Framework Documents

All scripts are in `doc/process-framework/scripts/file-creation`:

```powershell
# Create new task definition
.\New-Task.ps1

# Create new template
.\New-Template.ps1

# Create new guide
.\New-Guide.ps1

# Create feedback form
.\New-FeedbackForm.ps1

# Create context map (task relationships)
.\New-ContextMap.ps1

# Create temporary state file
.\New-TempTaskState.ps1

# Create permanent state file
.\New-PermanentState.ps1

# Create framework extension concept
.\New-FrameworkExtensionConcept.ps1
```

### Validation Scripts

```powershell
# Validate feedback forms
doc/process-framework/scripts/validation/Validate-FeedbackForms.ps1

# Validate ID registry
doc/process-framework/scripts/validation/validate-id-registry.ps1

# Validate state tracking (feature states, cross-references, ID counters)
doc/process-framework/scripts/validation/Validate-StateTracking.ps1
```

## Task Completion Requirements

**CRITICAL**: Tasks are NOT complete until:
1. All deliverables are created
2. Feedback form is completed using templates in doc/process-framework/templates/00-onboarding/feedback-form-template.md
3. Session duration is manually calculated and entered in feedback form
4. State files are updated

Each task definition includes a mandatory completion checklist.

## Key References

- **Task Registry**: @doc/process-framework/ai-tasks.md
- **Documentation Map**: @doc/process-framework/documentation-map.md (index of all framework documents)
- **Process Framework README**: @doc/process-framework/README.md
- **Project README**: @README.md

## Visual Notation

Framework uses standardized diagram formats. See @doc/process-framework/guides/support/visual-notation-guide.md for interpretation.

## LinkWatcher Workflow

LinkWatcher runs in background and automatically maintains all cross-references. You can:
- Move/rename files using VS Code, File Explorer, or git
- LinkWatcher updates all markdown links in real-time
- Check `LinkWatcher/LinkWatcherLog.txt` for activity logs
