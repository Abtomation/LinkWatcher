---
id: PF-VIS-065
type: Process Framework
category: Context Map
version: 1.0
created: 2026-04-07
updated: 2026-04-07
workflow_phase: 07-deployment
---

# Git Commit and Push Context Map

This context map provides a visual guide to the components and relationships relevant to the Git Commit and Push task.

## Visual Component Diagram

```mermaid
graph TD
    classDef critical fill:#f9d0d0,stroke:#d83a3a
    classDef important fill:#d0e8f9,stroke:#3a7bd8
    classDef reference fill:#d0f9d5,stroke:#3ad83f

    WorkingDir([Working Directory]) --> GitAdd{{git add .}}
    GitAdd --> SafetyCheck{{Safety Check}}
    SafetyCheck --> GitCommit{{git commit}}
    GitCommit --> GitPush{{git push}}
    GitPush --> Remote>Remote Repository]

    CLAUDE[/CLAUDE.md/] -.-> GitAdd
    CLAUDE -.-> GitCommit

    class WorkingDir,GitAdd critical
    class SafetyCheck,GitCommit,GitPush important
    class Remote,CLAUDE reference
```

## Essential Components

### Critical Components (Must Understand)
- **Working Directory**: The current project directory — defines the scope of what gets staged
- **git add .**: Stages only files within the working directory — never parent or sibling paths

### Important Components (Should Understand)
- **Safety Check**: Scans staged files for sensitive content (.env, keys, credentials)
- **git commit**: Creates a descriptive commit message summarizing the changes
- **git push**: Pushes the commit to the remote — never force-pushes without permission

### Reference Components (Access When Needed)
- **Remote Repository**: The GitHub remote (origin)
- **CLAUDE.md**: Project-level git constraints (prohibited commands like `git stash`, `git reset --hard`)

## Key Relationships

1. **Working Directory → git add .**: Only the current directory is staged — the repo root may be broader
2. **Safety Check → git commit**: Commit only proceeds if no sensitive files are detected
3. **CLAUDE.md -.-> git add / git commit**: Project rules constrain which git operations are allowed

---
