---
id: PF-TSK-082
type: Process Framework
category: Task Definition
version: 1.0
created: 2026-04-07
updated: 2026-04-07
---

# Git Commit and Push

## Purpose & Context

Commit all changes in the current working directory and push them to the remote repository. This task ensures only the active project directory is staged — never parent directories or sibling projects — and produces a descriptive commit message summarizing the changes.

## AI Agent Role

**Role**: Release Engineer
**Mindset**: Precise, safety-conscious, scope-aware
**Focus Areas**: Correct staging scope, meaningful commit messages, preventing accidental inclusion of sensitive or unrelated files
**Communication Style**: Confirm scope before acting, report what was committed and pushed

## When to Use

- When the human partner asks to commit and/or push changes to GitHub
- When a task has been completed and the results should be persisted to the remote repository
- After any session where code or documentation changes should be saved

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/07-deployment/git-commit-and-push-map.md)

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

### Step 2: Stage Working Directory Only

Stage only the current working directory — never parent or sibling directories:

```bash
git add .
```

**🚨 CRITICAL**: The git repository root may be broader than the project directory. Always use `git add .` from within the working directory. Never use `git add` with paths that reach outside the working directory (e.g., `../`, parent folder names).

### Step 3: Gitignore Check

Review staged files for items that should typically be gitignored. Present any matches to the human partner before proceeding:

```bash
git diff --cached --name-only | grep -iE '(__pycache__|\.pyc$|\.pyo$|\.db$|\.sqlite3?$|node_modules|\.coverage$|\.egg-info|dist/|build/|\.o$|\.so$|\.dll$|\.exe$|\.class$|\.jar$|\.log$|\.lock$|\.tmp$|\.swp$|\.DS_Store|Thumbs\.db)'
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

LinkWatcher must be stopped before committing. It modifies files in the background (updating cross-references), which can dirty the working tree between staging and pushing.

```bash
pwsh.exe -ExecutionPolicy Bypass -Command 'Get-Process python* | Stop-Process -Force'
```

### Step 6: Commit

Analyze the staged changes and create a descriptive commit message:

- Summarize the nature of the changes (new feature, enhancement, bug fix, refactoring, docs, etc.)
- Keep the first line concise (under 72 characters)
- Add detail in the body if the changes span multiple concerns
- End with the co-authored-by trailer

```bash
git commit -m "$(cat <<'EOF'
<concise summary of changes>

<optional body with details>

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Step 7: Push

```bash
git push
```

If the push is rejected (e.g., remote has new commits), inform the human partner and ask how to proceed rather than force-pushing.

### Step 8: Restart LinkWatcher

```bash
pwsh.exe -ExecutionPolicy Bypass -File LinkWatcher/start_linkwatcher_background.ps1
```

### Step 9: Confirm

Report the commit hash and summary to the human partner.

## Outputs

- **Git commit** — A new commit on the current branch containing only working directory changes
- **Remote update** — The commit pushed to the remote repository

## State Tracking

This task does not update any process framework state files. It operates on the git repository only.

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

- [ ] **Staging scope verified**: Only files within the current working directory were staged
- [ ] **Gitignore check completed**: Files matching common gitignore patterns reviewed with human partner
- [ ] **No sensitive files committed**: Safety check passed (no .env, keys, credentials)
- [ ] **LinkWatcher stopped**: LinkWatcher process stopped before committing
- [ ] **Commit created**: Descriptive commit message with co-authored-by trailer
- [ ] **Push successful**: Changes pushed to remote repository
- [ ] **LinkWatcher restarted**: LinkWatcher running again after push
- [ ] **Confirmation given**: Commit hash and summary reported to human partner

## Next Tasks

- No mandatory follow-up tasks — this is a terminal workflow step

## Related Resources

- [Release & Deployment Task](/process-framework/tasks/07-deployment/release-deployment-task.md) — For formal release preparation (broader scope than a simple push)
