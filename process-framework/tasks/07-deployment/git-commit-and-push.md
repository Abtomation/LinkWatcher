---
id: PF-TSK-082
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.6
created: 2026-04-07
updated: 2026-07-29
description: "Commit work in the current working directory and push it — a session's own paths (Mode A) or the uncommitted remainder (Mode B)"
complexity: simple
use_when: >-
  Committing and pushing from the current working directory, on the human's request, in one of two modes. **Mode A — Session Commit**: stage the explicit paths a body of work touched. **Mode B — Remainder Sweep**: commit whatever uncommitted work is left in the tree. Triggers: 'commit my changes', 'commit and push', 'commit the rest', 'sweep the uncommitted work'.
automation: manual
trigger_status:
  - raw: "_(user request)_"
output_status:
  - raw: "_(git only — no state file update)_"
---

# Git Commit and Push

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Commit work in the current working directory and push it to the remote repository, staging only the active project directory — never parent directories or sibling projects — and producing a descriptive commit message.

The task runs in one of **two modes**, chosen before Step 2 because they stage differently:

- **Mode A — Session Commit**: commit a specific body of work on the human's request, staging the **explicit paths it touched**. (The former per-session Phase C close-out offer was removed — PF-IMP-1876: where artifact locking runs, guarded edits are already committed at lock release, so there is no per-session commit ritual.)
- **Mode B — Remainder Sweep**: commit whatever uncommitted work is **left** in the tree. Because the remainder is by definition not one session's work, staging the whole working directory is correct here and the commit message describes a sweep rather than a single change.

## AI Agent Role

**Role**: Release Engineer
**Mindset**: Precise, safety-conscious, scope-aware
**Focus Areas**: Correct staging scope, meaningful commit messages, preventing accidental inclusion of sensitive or unrelated files
**Communication Style**: Confirm scope before acting, report what was committed and pushed

## Context Requirements

- **Critical (Must Read):**

  - **Human partner's request** — What to commit and any specific commit message instructions

- **Reference Only (Access When Needed):**
  - [CLAUDE.md](/CLAUDE.md) — Project-level git constraints (prohibited commands)

## Process

### Step 1: Gather State

Run these commands in parallel to understand the current state:

```bash
git status
git diff --stat
git log --oneline -5
```

### Step 2: Stage — by Mode

Stage only within the current working directory — never parent or sibling directories.

**Mode A — Session Commit**: stage the explicit paths the requested work touched (a session's Phase B per-step checklist is the natural record of them). Do **not** use `git add .` here — on a shared tree it sweeps in work that is not yours:

```bash
git add <path> [<path> ...]
```

**Mode B — Remainder Sweep**: stage the whole working directory, which is what "the remainder" means:

```bash
git add .
```

No pre-staging confirmation is required in Mode B (PF-IMP-1876 — the ask itself already came from the human): where artifact locking runs, live sessions' guarded edits are committed at lock release, and the sweepable remainder is script-written bookkeeping that is safe to commit mid-task. Make scope visible **after the fact** instead — report the swept file list in the Step 9 confirmation.

**🚨 CRITICAL** (both modes): The git repository root may be broader than the project directory. Always stage from within the working directory. Never use `git add` with paths that reach outside it (e.g., `../`, parent folder names).

> **Over-staged?** `git restore --staged <path>` unstages without touching the working tree — it is not among the workspace's prohibited git commands. A pre-existing **staged rename** splits if you unstage one side only: unstage both the source deletion and the destination add.

### Step 3: Gitignore Check

Review staged files for items that should typically be gitignored. Present any matches to the human partner before proceeding:

```bash
git diff --cached --name-only | grep -iE '(__pycache__|\.pyc$|\.pyo$|\.db$|\.sqlite3?$|\.sqbpro$|node_modules|\.coverage$|\.egg-info|dist/|build/|\.o$|\.so$|\.dll$|\.exe$|\.class$|\.jar$|\.log$|\.lock$|\.tmp($|\.)|\.swp$|\.bak$|\.pdf$|\.DS_Store|Thumbs\.db)'
```

If matches are found:
- Present the list to the human partner
- Ask whether to proceed, unstage specific files, or add them to `.gitignore`
- Do **not** silently skip or unstage files — the human partner decides

### Step 4: Safety Check

Before committing, verify no sensitive files are staged:

```bash
git diff --cached --name-only | grep -iE '\.(env|key|pem|secret|credential|password)'
```

If sensitive files are found, unstage them and warn the human partner.

### Step 5: Stop LinkWatcher

LinkWatcher must be stopped before committing — it modifies files in the background (updating cross-references), which can dirty the working tree between staging and pushing.

Stop it with the dedicated stop script. It targets **only this project's** daemon(s) — detected by process command line + project root rather than the lock file, whose PID can be stale — verifies that no instance survives, and cleans up the lock file:

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/tools/linkWatcher/stop_linkwatcher.ps1
```

A non-zero exit means the stop is incomplete (the script reports the surviving PIDs) — resolve that before committing.

### Step 6: Commit

Analyze the staged changes and create a descriptive commit message:

- Summarize the nature of the changes (new feature, enhancement, bug fix, refactoring, docs, etc.)
- Keep the first line concise (under 72 characters)
- Add detail in the body if the changes span multiple concerns
- End with the Co-Authored-By trailer your environment provides (use the current model identity it supplies, rather than a fixed version)

```bash
git commit -m "$(cat <<'EOF'
<concise summary of changes>

<optional body with details>

Co-Authored-By: <model identity from your environment> <noreply@anthropic.com>
EOF
)"
```

**If pre-commit hooks fail**, recovery depends on the failure shape:

- **Auto-fixers** (`trailing-whitespace`, `end-of-file-fixer`, `black`, `isort`) modify files instead of failing cleanly — the commit aborts with a "files were modified by this hook" message. Re-stage the same way you staged in Step 2 and retry the same commit; usually one retry suffices.
- **Non-fixing rejections** must be resolved before retrying, and the cause dictates the fix. If it is content (e.g. a `flake8` lint error, failing `pytest-quick`, malformed `check-yaml`), fix the file. If it is configuration — a relocated runtime file tripping `check-added-large-files`, a legitimate file flagged by a content/corruption guard, or a linter newly scanning files moved into its scope (common on a large reorg snapshot) — fix the config (`.gitignore`, the guard's allowlist, or lint scope), never bypass with `--no-verify`. Then re-stage and retry.

### Step 7: Push

```bash
git push
```

If the push is rejected (e.g., remote has new commits), inform the human partner and ask how to proceed rather than force-pushing.

### Step 8: Restart LinkWatcher

```bash
pwsh.exe -ExecutionPolicy Bypass -File process-framework/tools/linkWatcher/start_linkwatcher_background.ps1
```

### Step 9: Confirm

Report the commit hash and summary to the human partner.

## Tools and Scripts

- **[stop_linkwatcher.ps1](../../tools/linkWatcher/stop_linkwatcher.ps1)** — Stop this project's LinkWatcher with a verified post-condition (Step 5)
- **[start_linkwatcher_background.ps1](../../tools/linkWatcher/start_linkwatcher_background.ps1)** — Start LinkWatcher in background (Step 8: restart after push)
- **[New-FeedbackForm.ps1](../../scripts/file-creation/support/New-FeedbackForm.ps1)** — Create feedback forms for task completion

## Outputs

- **Git commit** — A new commit on the current branch containing only working directory changes
- **Remote update** — The commit pushed to the remote repository

## State Tracking

This task does not update any process framework state files. It operates on the git repository only.

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Process**: Confirm all steps were followed
  - [ ] Staging scope verified: everything staged is within the current working directory **and** matches the mode — Mode A only the requested work's own paths, Mode B the remainder (swept file list reported at Step 9)
  - [ ] Gitignore check completed: Files matching common gitignore patterns reviewed with human partner
  - [ ] No sensitive files committed: Safety check passed (no .env, keys, credentials)
  - [ ] LinkWatcher stopped and verified stopped (stop script exit 0) before committing
  - [ ] Commit created with descriptive message and co-authored-by trailer
  - [ ] Push successful: Changes pushed to remote repository
  - [ ] LinkWatcher restarted after push
  - [ ] Confirmation given: Commit hash and summary reported to human partner
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-082`, context "Git Commit and Push".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| Stage | Working directory files | Mode A: `git add <paths>` · Mode B: `git add .` | Mode A stages this session's own paths; Mode B stages the confirmed remainder. Both stay within the working directory |
| Commit | Git repository | `git commit` | Creates commit with descriptive message |
| Push | Remote repository | `git push` | Pushes to origin |

## Next Tasks

- No mandatory follow-up tasks — this is a terminal workflow step

<!-- merged from transition-registry entry: Git Commit and Push (PF-TSK-082) -->
### Prerequisites for Transition

- [ ] All working directory changes staged and committed
- [ ] Commit pushed successfully to remote repository
- [ ] No sensitive files included in commit

### Next Task Selection

```
Push completed successfully
├─ Continuing current work → Return to active task
├─ Session ending → No follow-up needed
└─ Starting new work → Select appropriate task from ai-tasks.md
```

### Preparation for Next Task

1. Verify the push was successful (commit hash confirmed on remote)
2. Continue with the next task or end the session

## Related Resources

- [Release & Deployment Task](release-deployment-task.md) — For formal release preparation (broader scope than a simple push)
