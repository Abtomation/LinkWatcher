---
id: PF-PRO-029
type: Document
category: General
version: 1.0
created: 2026-04-29
updated: 2026-04-29
---

# Structure Change Proposal: Relocate LinkWatcher_run with Agnostic Startup Script

## Overview

Move `process-framework-local/tools/linkWatcher/` (currently at the project root) into the framework directories with a clean separation between shareable scaffolding and project-specific runtime artifacts. Refactor `start_linkwatcher_background.ps1` to remove user-machine-specific hardcoding so it can live as a framework asset reusable across projects. Delete `setup_project.py` (its responsibilities collapse once the script is agnostic).

**Structure Change ID:** SC-029
**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-04-29
**Target Implementation Date:** 2026-04-29

## Current Structure

`process-framework-local/tools/linkWatcher/` lives at the project root and mixes two unrelated concerns: shareable scaffolding (the startup script and the setup helper) and project-specific runtime artifacts (logs, broken-links report, ignore rules). The startup script hardcodes `C:\Users\ronny\bin` as the global LinkWatcher install path, which makes it user-machine-specific and not portable.

### Example of Current Structure
```
LinkWatcher/                                  # project root
├── process-framework-local/tools/linkWatcher/
│   ├── start_linkwatcher_background.ps1      # hardcoded C:\Users\ronny\bin
│   ├── setup_project.py                      # bootstrap that generates per-project copies
│   ├── .linkwatcher-ignore                   # project-specific suppression rules
│   ├── process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt            # generated output
│   ├── LinkWatcherError.txt                  # log
│   └── logs/                                 # log directory
└── ...
```

## Proposed Structure

Split the directory by ownership. The agnostic startup script becomes a shared framework asset; runtime artifacts live in the local-only sibling directory; `setup_project.py` is deleted.

### Example of Proposed Structure
```
LinkWatcher/                                  # project root
├── process-framework/                        # shareable across projects
│   └── tools/
│       └── linkWatcher/
│           └── start_linkwatcher_background.ps1  # agnostic: env-var + auto-detect resolver
├── process-framework-local/                  # project-specific
│   └── tools/
│       └── linkWatcher/
│           ├── .linkwatcher-ignore
│           ├── process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt
│           ├── LinkWatcherError.txt
│           └── logs/
└── ...
```

## Rationale

### Benefits
- **Framework reuse**: An agnostic startup script can be copied into other projects (alongside the rest of `process-framework/`) and run as-is — no per-project regeneration step needed.
- **Clean separation**: Runtime artifacts (logs, broken-links report, project-specific ignore rules) stop polluting the shareable framework directory; they live next to the rest of the project's local state in `process-framework-local/`.
- **Removes redundant scaffolding**: `setup_project.py` exists only to generate a per-project copy of the startup script. Once the script is agnostic, that work disappears.
- **Eliminates user-machine hardcoding**: The script's hardcoded `C:\Users\ronny\bin` is replaced with an env-var-or-auto-detect resolver that works on any developer's machine.

### Challenges
- **Breaking path changes**: ~50 files reference `process-framework/tools/linkWatcher/start_linkwatcher_background.ps1`, including session-startup instructions in CLAUDE.md, `process-framework/.ai-entry-point.md`, and `process-framework/ai-tasks.md`. Most are doc text that LinkWatcher will sweep automatically, but five files contain load-bearing code references that must be updated by hand.
- **Settings.py defaults**: Two ignore-list defaults reference the directory name `"LinkWatcher_run"`. Users with custom configs that override those defaults with the old name would silently lose the ignore behavior; we must update the defaults and document the rename.
- **VS Code task generation deleted**: `setup_project.py` writes `.vscode/tasks.json` entries. Removing it means anyone who relied on those tasks loses them. Mitigation: not a runtime dependency — the README and CLAUDE.md emphasize the PS1 script directly. Users who want VS Code tasks can recreate them in a few minutes.

## Affected Files

### Load-bearing code (manual edits required)

| File | Change |
|---|---|
| [src/linkwatcher/config/settings.py](/src/linkwatcher/config/settings.py) | Replace `"LinkWatcher_run"` in `ignored_directories` (line 95) and `validation_extra_ignored_dirs` (line 140); add `process-framework-local/tools/linkWatcher` |
| [deployment/install_global.py](/deployment/install_global.py) | Update `project_root / "LinkWatcher_run"` (line 323), docstring (line 7), error/help messages (lines 318, 325, 522) |
| [test/automated/bug-validation/test_pd-bug-077_startup_venv_validation.py](/test/automated/bug-validation/test_pd-bug-077_startup_venv_validation.py) | Update startup-script path (line 30) |
| [.gitignore](/.gitignore) | Repoint log-file ignore globs (lines 142-143) |
| [.claude/settings.local.json](/.claude/settings.local.json) | Update permission allow-list entries (lines 44, 54) |
| [process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1](/process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1) | Update post-E2E LinkWatcher restart path (line 437) |

### Files moved / refactored / deleted

| Action | File | Notes |
|---|---|---|
| Refactor + move | `process-framework/tools/linkWatcher/start_linkwatcher_background.ps1` → `process-framework/tools/linkWatcher/start_linkwatcher_background.ps1` | Add env-var-or-auto-detect resolver replacing hardcoded `C:\Users\ronny\bin`; adjust `..\doc\project-config.json` walk for new depth |
| Delete | `(deleted: replaced by agnostic startup script)` | Responsibilities collapse; VS Code task generation dropped |
| Move | `process-framework-local/tools/linkWatcher/.linkwatcher-ignore` → `process-framework-local/tools/linkWatcher/.linkwatcher-ignore` | Project-specific suppression rules |
| Move | `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` → `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` | Generated output |
| Move | `process-framework-local/tools/linkWatcher/logs/LinkWatcherError.txt` → `process-framework-local/tools/linkWatcher/LinkWatcherError.txt` | Log |
| Move | `process-framework-local/tools/linkWatcher/logs/` → `process-framework-local/tools/linkWatcher/logs/` | Log directory |
| Delete | `process-framework-local/tools/linkWatcher/` (now empty) | Final cleanup |

### Doc/text references (LinkWatcher sweeps automatically)

- **Process framework docs**: `process-framework/.ai-entry-point.md`, `process-framework/ai-tasks.md`, `process-framework/tasks/03-testing/e2e-acceptance-test-execution-task.md`, `process-framework/tasks/07-deployment/git-commit-and-push.md`, `process-framework/tasks/support/structure-change-task.md`, `process-framework/guides/04-implementation/enhancement-state-tracking-customization-guide.md`
- **Project root docs**: `CLAUDE.md`, `README.md`
- **Product docs**: ~25 files under `doc/` (state files, FDDs, TDDs, integration narratives, validation reports, user handbooks)
- **Test artifacts**: ~10 files under `test/` (e2e test cases, master tests, audit reports, bug-validation test docstrings)
- **Local state**: ~12 files under `process-framework-local/` (feedback archive, old proposals, archived state)
- **Misc**: `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt`, `config-examples/logging-config.yaml`

### Pre-existing inconsistencies fixed in this pass

- A few doc files reference `process-framework/tools/linkWatcher/start_linkwatcher_background.ps1` (no `_run`) — already broken (no such directory). These get fixed alongside the main path rewrite.

## Migration Strategy

### Phase 1: Refactor startup script to be agnostic
- Edit `process-framework/tools/linkWatcher/start_linkwatcher_background.ps1` in place:
  - Replace hardcoded `$lwInstallDir = "C:\\Users\\ronny\\bin"` with env-var-or-auto-detect logic mirroring the resolver in `setup_project.py:14-34` (check `$env:LINKWATCHER_INSTALL_DIR` → `$HOME/bin` → `$HOME/tools` → `$HOME/scripts` → `$HOME/.local/bin` → `$HOME/LinkWatcher`)
  - Adjust the `..\doc\project-config.json` relative path to `..\..\..\doc\project-config.json` (target location is three levels deep)
  - Add auto-create of `.linkwatcher-ignore` skeleton if missing (replaces that part of `setup_project.py`)
- Verify it still starts LinkWatcher correctly from the **current** location before moving (depth check is the only thing that breaks; we revert that one line for the in-place test).

### Phase 2: Create destination directories and move files
- Create `process-framework/tools/linkWatcher/` and `process-framework-local/tools/linkWatcher/`
- Move runtime artifacts to `process-framework-local/tools/linkWatcher/`
- Move the refactored startup script to `process-framework/tools/linkWatcher/`
- Wait for LinkWatcher to sweep textual references after each move (per the task's File and Directory Move Procedure)

### Phase 3: Update load-bearing code
- Update the six load-bearing code files listed above
- Update `.gitignore`, `.claude/settings.local.json`
- Delete `setup_project.py`
- Delete the now-empty `process-framework-local/tools/linkWatcher/`

### Phase 4: Verify and finalize
- Grep for `LinkWatcher_run` and `LinkWatcher/start_linkwatcher_background` — should return only `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` and historical archive entries that LinkWatcher has correctly chosen not to rewrite
- Run `Validate-StateTracking.ps1` — 0 errors
- Restart LinkWatcher from new location and confirm it works
- Update `process-framework/PF-documentation-map.md` to add the new `tools/` subdirectory
- Update `process-framework-local/state-tracking/permanent/process-improvement-tracking.md`

## Task Modifications

### [PF-TSK-014 Structure Change](process-framework/tasks/support/structure-change-task.md)

**Changes needed:**
- Update line 125 reference from `process-framework-local/tools/linkWatcher/logs/LinkWatcherLog*.txt` to `process-framework-local/tools/linkWatcher/logs/LinkWatcherLog*.txt`

**Rationale:** Self-reference — the task uses the old path in its own File and Directory Move Procedure.

### [PF-TSK-070 E2E Acceptance Test Execution](process-framework/tasks/03-testing/e2e-acceptance-test-execution-task.md)

**Changes needed:**
- Update line 93 restart instruction

### [PF-TSK-072 Git Commit and Push](process-framework/tasks/07-deployment/git-commit-and-push.md)

**Changes needed:**
- Update lines 127 and 136 — also normalize the inconsistency where one path uses `LinkWatcher/` and the other uses `process-framework-local/tools/linkWatcher/`

## New Tasks

None.

## Handover Interfaces

None — no task-to-task handover artifacts change. State files retain their current shapes.

## Testing Approach

### Test Cases
- After Phase 1: refactored script starts LinkWatcher correctly with auto-detection (kill running, restart from current location with `..\doc\project-config.json` temporarily)
- After Phase 2: refactored script starts LinkWatcher correctly from new location with `..\..\..\doc\project-config.json`
- After Phase 3: `pytest test/automated/bug-validation/test_pd-bug-077_startup_venv_validation.py` passes
- After Phase 4: `Validate-StateTracking.ps1` reports 0 errors across all surfaces; `python main.py --validate` does not regress (broken-links count not worse than baseline)

### Success Criteria
- LinkWatcher starts and runs successfully from the new script location with no per-machine configuration
- All load-bearing code references resolve correctly
- No new broken links introduced (validation diff vs baseline)
- `Validate-StateTracking.ps1` shows 0 errors

## Rollback Plan

### Trigger Conditions
- LinkWatcher fails to start from the new location and the cause cannot be diagnosed within the session
- `Validate-StateTracking.ps1` reports errors that cannot be resolved within the session
- A load-bearing test failure (e.g., `test_pd-bug-077`) is irrecoverable

### Rollback Steps
1. Move `process-framework/tools/linkWatcher/start_linkwatcher_background.ps1` back to `process-framework/tools/linkWatcher/start_linkwatcher_background.ps1`
2. Revert the script's path-depth and resolver edits via `git diff` review and Edit
3. Move runtime artifacts back from `process-framework-local/tools/linkWatcher/` to `process-framework-local/tools/linkWatcher/`
4. Restore `setup_project.py` from `git show HEAD:(deleted: replaced by agnostic startup script)`
5. Revert load-bearing code edits via `git diff` review and Edit (do NOT use `git checkout --`)
6. Restart LinkWatcher and validate

> **Constraint**: Do NOT use `git stash`, `git checkout -- <path>`, `git reset --hard`, or `git clean -f` (forbidden by project rules — see CLAUDE.md).

## Resources Required

### Personnel
- AI Agent — execute changes, ~1-2 hours
- Human Partner — checkpoints and approval

### Tools
- LinkWatcher (running in background to sweep textual references)
- `Validate-StateTracking.ps1`
- `pytest` (for `test_pd-bug-077_startup_venv_validation.py`)
- `Edit`, `Bash`, `Grep`, `Glob` tools

## Metrics

### Implementation Metrics
- Files moved: 5 (script + 4 runtime artifact files/dirs)
- Files deleted: 1 (`setup_project.py`)
- Load-bearing code edits: 6 files
- Doc references rewritten: ~50 (mostly automatic via LinkWatcher)

### User Experience Metrics
- Hardcoded user-machine paths removed: 1 (`C:\Users\ronny\bin`)
- Per-project setup steps eliminated: ~5 (everything `setup_project.py` did)
- Startup script reusability: from 0 (per-project copies) to 1 (single shareable script)

## Approval

**Approved By:** _________________
**Date:** 2026-04-29

**Comments:**
