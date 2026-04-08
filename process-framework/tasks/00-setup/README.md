# 00 - Setup Tasks

Setup tasks handle project initialization and framework adoption into existing codebases.

## Task Overview

| Task | ID | Purpose |
|------|----|---------|
| [Project Initiation](project-initiation-task.md) | PF-TSK-059 | Create `project-config.json` and foundational project configuration |
| [Codebase Feature Discovery](codebase-feature-discovery.md) | PF-TSK-064 | Discover all features, assign every source file, create feature state files |
| [Codebase Feature Analysis](codebase-feature-analysis.md) | PF-TSK-065 | Analyze patterns, dependencies, and design decisions per feature |
| [Retrospective Documentation Creation](retrospective-documentation-creation.md) | PF-TSK-066 | Validate tier assessments and create design docs (FDD, TDD, ADRs) for Tier 2+ |

## Sequential Pipeline

The three onboarding tasks must run in strict order — each builds on the previous task's output:

```
PF-TSK-064              PF-TSK-065                PF-TSK-066
Feature Discovery  ───>  Feature Analysis  ───>  Documentation Creation
(code inventory)         (enrich state files)     (FDD/TDD/ADR for Tier 2+)
```

- **Discovery** produces feature state files with complete code inventories
- **Analysis** enriches those state files with patterns, dependencies, and design decisions
- **Documentation Creation** uses the enriched state files to create formal design documentation

## When Is Project Initiation Needed?

**Project Initiation (PF-TSK-059)** creates `doc/project-config.json`, which automation scripts and LinkWatcher depend on.

| Scenario | Project Initiation needed? |
|----------|---------------------------|
| Brand-new project, no code yet | **Yes** — start here, then build features via the normal planning workflow |
| Existing project, adopting the framework | **Yes, if** `doc/project-config.json` does not exist yet |
| Existing project, `project-config.json` already exists | **Skip** — go directly to Codebase Feature Discovery (PF-TSK-064) |

> **Note**: LinkWatcher requires `project-config.json` to resolve the project root. If it doesn't exist, start LinkWatcher after Project Initiation completes.
