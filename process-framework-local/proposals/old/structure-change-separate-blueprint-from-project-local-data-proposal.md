---
id: PF-PRO-015
type: Document
category: General
version: 1.0
created: 2026-04-03
updated: 2026-04-03
---

# Structure Change Proposal: Separate Blueprint from Project-Local Data

## Overview

Move project-specific directories (feedback, evaluation-reports, proposals, state-tracking) out of `process-framework/` into a new `process-framework-local/` directory to enable risk-free framework deployment across projects.

**Structure Change ID:** SC-012
**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-04-03
**Target Implementation Date:** 2026-04-03

## Current Structure

The `process-framework/` directory mixes reusable blueprint content with project-specific data:

```
process-framework/
├── tasks/                    # BLUEPRINT — reusable task definitions
├── templates/                # BLUEPRINT — document templates
├── guides/                   # BLUEPRINT — how-to guides
├── scripts/                  # BLUEPRINT — automation scripts
├── visualization/            # BLUEPRINT — context maps
├── infrastructure/           # BLUEPRINT — task registry
├── languages-config/         # BLUEPRINT — language configs
├── feedback/                 # LOCAL — 39 feedback forms, 26 reviews, ratings DB
│   ├── feedback-forms/       #   timestamped session feedback
│   ├── reviews/              #   tools review summaries
│   ├── archive/              #   processed feedback
│   └── ratings.db            #   accumulated ratings data
├── evaluation-reports/       # LOCAL — 8 framework evaluation reports
├── proposals/                # LOCAL — 17 proposals from this project's evolution
│   └── old/                  #   archived proposals
├── state-tracking/           # LOCAL — project-specific state
│   ├── permanent/            #   process-improvement-tracking.md
│   └── temporary/            #   active/archived session state files
├── PF-id-registry.json       # MIXED — schema is blueprint, counters are local
├── PF-documentation-map.md   # MIXED — mostly blueprint, some local references
├── ai-tasks.md               # BLUEPRINT
├── .ai-entry-point.md        # BLUEPRINT
├── domain-config.json        # BLUEPRINT
└── README.md                 # BLUEPRINT
```

**Problem**: Copying `process-framework/` from one project to another overwrites all project-specific feedback, proposals, improvement tracking, and state files.

## Proposed Structure

```
process-framework/              # ENTIRE directory = blueprint (safe to overwrite)
├── tasks/
├── templates/
├── guides/
├── scripts/
├── visualization/
├── infrastructure/
├── languages-config/
├── PF-id-registry.json         # Split: schema only (counters move to local)
├── PF-documentation-map.md     # Blueprint entries only
├── ai-tasks.md
├── .ai-entry-point.md
├── domain-config.json
└── README.md

process-framework-local/        # NEW — project-specific, never overwritten
├── feedback/
│   ├── feedback-forms/
│   ├── reviews/
│   ├── archive/
│   └── ratings.db
├── evaluation-reports/
│   └── archive/
├── proposals/
│   └── old/
├── state-tracking/
│   ├── permanent/
│   │   └── process-improvement-tracking.md
│   └── temporary/
│       └── old/
└── PF-id-registry-state.json   # NEW — project-specific counters only
```

### PF-id-registry Split Strategy

**Blueprint** (`process-framework/PF-id-registry.json`): Contains prefix definitions, descriptions, categories, types, and directory mappings. Updated `directories` entries point to `process-framework-local/` for local prefixes.

**Local** (`process-framework-local/PF-id-registry-state.json`): Contains only `nextAvailable` counters per prefix. Scripts read both files, using the blueprint for schema and local for counters.

## Rationale

### Benefits
- **Risk-free deployment**: Copy `process-framework/` to any project without destroying project-specific data
- **Clear boundary**: Directory name alone tells you what's portable vs. project-specific
- **No sync script needed** for the basic case — just copy the directory
- **Git-friendly**: Can `.gitignore` parts of `process-framework-local/` (e.g., ratings.db) without affecting the blueprint

### Challenges
- **One-time migration**: ~17 scripts need path updates, ~6 templates need instruction updates
- **PF-id-registry split**: Scripts that read the registry need to be updated to merge both files
- **Relative path depth change**: Files inside `process-framework-local/` referencing `process-framework/` tasks/guides need adjusted relative paths (LinkWatcher handles markdown links automatically)

## Impact Matrix

### Automation Scripts (17 scripts, 22 critical path changes)

| Script | Directory | Operation | Changes |
|--------|-----------|-----------|---------|
| New-FeedbackForm.ps1 | feedback | WRITE | 1 output directory path |
| New-ReviewSummary.ps1 | feedback | WRITE | 1 output directory path |
| New-FrameworkExtensionConcept.ps1 | proposals | READ | 2 test code paths |
| New-StructureChangeProposal.ps1 | proposals | WRITE | 2 output paths |
| New-PermanentState.ps1 | state-tracking | WRITE | 1 output directory path |
| New-TempTaskState.ps1 | state-tracking | WRITE | 1 output directory path |
| New-StructureChangeState.ps1 | state-tracking | WRITE | 1 output directory path |
| New-ProcessImprovement.ps1 | state-tracking | WRITE | 1 file path |
| New-RetrospectiveMasterState.ps1 | state-tracking | WRITE | 1 directory + 2 messages |
| Finalize-Enhancement.ps1 | state-tracking | WRITE | 2 directory paths |
| Update-ProcessImprovement.ps1 | state-tracking | WRITE | 1 file path + 1 comment |
| Update-BatchFeatureStatus.ps1 | state-tracking | WRITE | 2 results file paths |
| Update-CodeReviewState.ps1 | state-tracking | READ | 1 output message |
| Update-FeatureImplementationState.ps1 | state-tracking | READ | 1 output message |
| Update-ScriptReferences.ps1 | feedback | READ | 1 script mapping |
| New-APIDataModel.ps1 | state-tracking | READ | 1 comment |
| New-APISpecification.ps1 | state-tracking | READ | 1 comment |

### Configuration Files (manual update required)

| File | Changes | Impact |
|------|---------|--------|
| PF-id-registry.json | 9 directory paths → split into blueprint + local state file | CRITICAL |
| infrastructure/process-framework-task-registry.md | 5 output directory specs | HIGH |
| .linkwatcher-ignore | 10 path patterns | MEDIUM |

### Templates (6 templates, manual update required)

| Template | References | Type |
|----------|------------|------|
| structure-change-state-template.md | 4 state-tracking paths | Inline instructions |
| structure-change-state-rename-template.md | 1 state-tracking path | Inline instructions |
| structure-change-state-content-update-template.md | 1 state-tracking path | Inline instructions |
| temp-process-improvement-state-template.md | 2 state-tracking paths | Inline instructions |
| temp-task-creation-state-template.md | 2 state-tracking paths | Inline instructions |
| task-completion-template.md | 1 feedback path | Inline instruction |

### Task Definitions & Guides (auto-fixable + manual)

| Category | Files | Auto-fixable (LinkWatcher) | Manual (code blocks) |
|----------|-------|---------------------------|---------------------|
| Task definitions | ~15 | ~10 markdown links | ~8 inline code paths |
| Guides | ~10 | ~8 markdown links | ~5 inline code paths |
| Visualization | ~5 | ~5 markdown links | 0 |

### Files Outside process-framework/ (mostly auto-fixable)

| File | References | Auto-fixable |
|------|------------|-------------|
| doc/state-tracking/features/*.md | ~8 links to state-tracking | YES |
| doc/state-tracking/permanent/feature-tracking.md | 2 links | YES |
| doc/state-tracking/permanent/feature-request-tracking.md | 4 links | YES |

### deployment/install_global.py

No direct references to the 4 moving directories. Only copies `src/linkwatcher` and `config-examples/`. **Relevance**: Pattern for a future `Sync-ProcessFramework.ps1` script that deploys the blueprint to other projects.

## Migration Strategy

### Phase 1: Pre-Move Preparation
1. Create `process-framework-local/` directory structure
2. Split `PF-id-registry.json` into blueprint (schema) + local (counters)
3. Update Common-ScriptHelpers to read merged registry (blueprint + local state)

### Phase 2: Script & Template Updates (before move)
1. Update all 17 automation scripts with new output paths
2. Update 6 templates with new inline instructions
3. Update infrastructure/process-framework-task-registry.md
4. Update .linkwatcher-ignore patterns

### Phase 3: Directory Move
1. Move `feedback/` → `process-framework-local/feedback/`
2. Move `evaluation-reports/` → `process-framework-local/evaluation-reports/`
3. Move `proposals/` → `process-framework-local/proposals/`
4. Move `state-tracking/` → `process-framework-local/state-tracking/`
5. LinkWatcher auto-fixes all markdown links in .md files

### Phase 4: Manual Link Fixes
1. Fix inline code paths in task definitions and guides that LinkWatcher can't auto-fix
2. Update PF-documentation-map.md (remove local entries or adjust paths)
3. Update CLAUDE.md references if needed

### Phase 5: Validation
1. Run `Validate-StateTracking.ps1` — 0 errors
2. Run `Validate-IdRegistry.ps1` — 0 errors
3. Test key scripts: `New-FeedbackForm.ps1`, `New-TempTaskState.ps1`, `New-ProcessImprovement.ps1`
4. Verify LinkWatcher link validation finds no broken references

## Testing Approach

### Test Cases
- Create a feedback form with `New-FeedbackForm.ps1` → lands in `process-framework-local/feedback/feedback-forms/`
- Create a temp state file with `New-TempTaskState.ps1` → lands in `process-framework-local/state-tracking/temporary/`
- Add a process improvement with `New-ProcessImprovement.ps1` → updates `process-framework-local/state-tracking/permanent/process-improvement-tracking.md`
- Create a structure change proposal with `New-StructureChangeProposal.ps1` → lands in `process-framework-local/proposals/`
- Run `python main.py --validate` → no broken links

### Success Criteria
- All automation scripts produce output in `process-framework-local/`
- `Validate-StateTracking.ps1` reports 0 errors
- `python main.py --validate` reports 0 broken links
- Copying `process-framework/` to a fresh directory does NOT include any project-specific data

## Rollback Plan

### Trigger Conditions
- Scripts fail to find `process-framework-local/` directory
- Validation scripts report errors that can't be resolved
- LinkWatcher fails to update links correctly

### Rollback Steps
1. Move directories back: `process-framework-local/feedback/` → `process-framework/feedback/` (etc.)
2. Revert script changes via git
3. LinkWatcher auto-fixes links back

## Approval

**Approved By:** _________________
**Date:** 2026-04-03

**Comments:**
